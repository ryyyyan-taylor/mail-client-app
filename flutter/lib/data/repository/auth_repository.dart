import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../local/token_storage.dart';

/// Mirrors AuthRepository.kt — wraps google_sign_in and TokenStorage.
///
/// Key differences from Android:
/// - `google_sign_in` package handles token caching and refresh transparently
///   via `currentUser.authHeaders` (no `GoogleAuthUtil` needed).
/// - `invalidateToken()` calls `clearAuthCache()` to force a refresh on next call.
/// - `isSignedIn()` checks TokenStorage AND attempts a silent sign-in to restore
///   the GoogleSignIn session across app restarts.
class AuthRepository {
  AuthRepository(this._tokenStorage)
      : _googleSignIn = GoogleSignIn(scopes: _gmailScopes);

  final TokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;

  static const _gmailScopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/gmail.labels',
  ];

  // ── Auth state ────────────────────────────────────────────────────────────

  /// True when both TokenStorage has an email and GoogleSignIn has a user
  /// that can produce a valid access token.
  /// On first call after a restart the GoogleSignIn session is restored via
  /// signInSilently. If the restored session can't produce a token (e.g. scopes
  /// were revoked), returns false so the caller routes to sign-in.
  Future<bool> isSignedIn() async {
    if (await _tokenStorage.isSignedIn() == false) return false;
    // Verify we can actually obtain an access token (also restores currentUser
    // via signInSilently if needed). Returns false → routes to sign-in.
    final token = await getAccessToken();
    debugPrint('isSignedIn: result=${token != null ? "signed-in" : "no-token"}');
    return token != null;
  }

  Future<String?> getSignedInEmail() => _tokenStorage.getAccountEmail();

  // ── Sign-in ───────────────────────────────────────────────────────────────

  /// Starts the interactive Google Sign-In flow.
  /// Throws if the user cancels or scopes are denied.
  Future<void> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Sign-in cancelled');
    // Eagerly fetch headers to verify scopes are granted.
    try {
      final headers = await account.authHeaders;
      debugPrint('signIn: authHeaders=$headers');
    } catch (e) {
      debugPrint('signIn: authHeaders error=$e');
      // Don't throw — the sign-in itself succeeded; token fetch will be
      // retried on first API call via the interceptor.
    }
    await _tokenStorage.saveAccountEmail(account.email);
  }

  Future<void> signOut() async {
    await _tokenStorage.clear();
    await _googleSignIn.signOut();
  }

  // ── Token access (used by AuthInterceptor) ────────────────────────────────

  /// Returns the current OAuth2 Bearer token, or null if not signed in.
  /// If [currentUser] is null (e.g. app restart, background isolate), attempts
  /// a silent sign-in first — mirrors the Kotlin app's always-fresh account
  /// lookup via GoogleSignIn.getLastSignedInAccount().
  Future<String?> getAccessToken() async {
    try {
      var user = _googleSignIn.currentUser;
      if (user == null) {
        debugPrint('getAccessToken: currentUser null, attempting signInSilently');
        user = await _googleSignIn.signInSilently();
      }
      debugPrint('getAccessToken: user=${user?.email ?? "NULL"}');
      if (user == null) return null;
      final headers = await user.authHeaders;
      debugPrint('getAccessToken: headers=$headers');
      final auth = headers['Authorization'];
      if (auth == null) return null;
      // Header format: "Bearer ya29.xxx"
      return auth.startsWith('Bearer ') ? auth.substring(7) : auth;
    } catch (e) {
      debugPrint('getAccessToken error: $e');
      return null;
    }
  }

  /// Clears the cached token so the next [getAccessToken] call fetches a fresh one.
  /// Called by AuthInterceptor after a 401 response.
  Future<void> invalidateToken() async {
    try {
      await _googleSignIn.currentUser?.clearAuthCache();
    } catch (_) {
      // best-effort
    }
  }
}
