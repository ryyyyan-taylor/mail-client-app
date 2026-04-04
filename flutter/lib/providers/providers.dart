import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/mail_database.dart';
import '../data/local/settings_prefs.dart';
import '../data/local/token_storage.dart';
import '../data/remote/dio_provider.dart';
import '../data/remote/gmail_api_service.dart';
import '../data/repository/auth_repository.dart';
import '../data/repository/mail_repository.dart';
import '../ui/auth/sign_in_notifier.dart';
import '../ui/inbox/inbox_notifier.dart';
import '../ui/settings/settings_notifier.dart';
import '../ui/thread/thread_detail_notifier.dart';

// ── Storage ───────────────────────────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>(
  (_) => TokenStorage(),
);

/// Loaded once at app startup via ProviderScope overrides in main().
/// See main.dart for the initialisation pattern.
final settingsPrefsProvider = Provider<SettingsPrefs>(
  (_) => throw UnimplementedError('settingsPrefsProvider not initialised'),
);

// ── Database ──────────────────────────────────────────────────────────────────

final mailDatabaseProvider = Provider<MailDatabase>(
  (_) => MailDatabase(),
);

final threadDaoProvider = Provider<ThreadDao>(
  (ref) => ref.watch(mailDatabaseProvider).threadDao,
);

final messageDaoProvider = Provider<MessageDao>(
  (ref) => ref.watch(mailDatabaseProvider).messageDao,
);

final labelDaoProvider = Provider<LabelDao>(
  (ref) => ref.watch(mailDatabaseProvider).labelDao,
);

// ── Auth ──────────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(tokenStorageProvider)),
);

// ── Network ───────────────────────────────────────────────────────────────────

/// GmailApiService wired to AuthRepository's token callbacks.
/// Using a callback (not a direct ref) breaks the circular dependency:
///   authRepo needs nothing from the network layer;
///   the API service needs tokens from authRepo.
final gmailApiServiceProvider = Provider<GmailApiService>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return createGmailApiService(
    getToken: auth.getAccessToken,
    invalidateToken: auth.invalidateToken,
  );
});

// ── Repository ────────────────────────────────────────────────────────────────

final mailRepositoryProvider = Provider<MailRepository>(
  (ref) => MailRepository(
    api: ref.watch(gmailApiServiceProvider),
    threadDao: ref.watch(threadDaoProvider),
    messageDao: ref.watch(messageDaoProvider),
    labelDao: ref.watch(labelDaoProvider),
  ),
);

// ── UI Notifiers ──────────────────────────────────────────────────────────────

final signInNotifierProvider =
    AsyncNotifierProvider<SignInNotifier, void>(SignInNotifier.new);

final inboxNotifierProvider =
    NotifierProvider<InboxNotifier, InboxUiState>(InboxNotifier.new);

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsUiState>(SettingsNotifier.new);

final threadDetailNotifierProvider = NotifierProvider.family<
    ThreadDetailNotifier, ThreadDetailUiState, String>(
  ThreadDetailNotifier.new,
);
