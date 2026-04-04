import 'dart:convert';
import '../data/remote/gmail_dtos.dart';

/// Mirrors EmailParser.kt — base64url decoding, MIME body extraction, header
/// lookup, and sender display name formatting.
class EmailParser {
  EmailParser._();

  /// Decodes a base64url-encoded string (as returned by the Gmail API).
  static String decodeBase64Url(String data) {
    try {
      // base64url uses - and _ instead of + and /; Dart's base64Url handles this.
      final bytes = base64Url.decode(base64Url.normalize(data));
      return utf8.decode(bytes);
    } catch (_) {
      return '';
    }
  }

  /// Finds a header by name (case-insensitive). Returns '' if not found.
  static String extractHeader(List<HeaderDto>? headers, String name) =>
      headers
          ?.firstWhere(
            (h) => h.name.toLowerCase() == name.toLowerCase(),
            orElse: () => const HeaderDto(name: '', value: ''),
          )
          .value ??
      '';

  /// Recursively extracts the best body from a message payload.
  /// Prefers text/html over text/plain for rich rendering.
  static String extractBody(PayloadDto? payload) {
    if (payload == null) return '';

    // Simple single-part message with inline data.
    final directData = payload.body?.data;
    if (directData != null && directData.isNotEmpty) {
      return decodeBase64Url(directData);
    }

    final parts = payload.parts;
    if (parts == null || parts.isEmpty) return '';

    // Prefer HTML, fall back to plain text.
    final html = parts.where((p) => p.mimeType == 'text/html').firstOrNull;
    final plain = parts.where((p) => p.mimeType == 'text/plain').firstOrNull;
    final best = html ?? plain;

    final bestData = best?.body?.data;
    if (bestData != null && bestData.isNotEmpty) {
      return decodeBase64Url(bestData);
    }

    // Nested multipart — recurse into each part.
    for (final part in parts) {
      final body = extractBody(part);
      if (body.isNotEmpty) return body;
    }
    return '';
  }

  /// Extracts a display name from a "Name [email]" formatted string.
  /// Falls back to the local part of the email address.
  static String displayName(String from) {
    final match = RegExp(r'''^"?(.+?)"?\s*<''').firstMatch(from);
    if (match != null) return match.group(1)!.trim();
    return from.split('@').first.trim();
  }
}
