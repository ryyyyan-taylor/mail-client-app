import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../data/local/mail_database.dart';
import '../data/local/settings_prefs.dart';
import '../data/local/token_storage.dart';
import '../data/remote/dio_provider.dart';
import '../data/repository/auth_repository.dart';
import '../data/repository/mail_repository.dart';
import '../util/email_parser.dart';

const kSyncTaskName = 'mail_sync';
const kNotificationChannelId = 'new_mail';

// ── Background callback ───────────────────────────────────────────────────────

/// Top-level function required by Workmanager — runs in a separate Dart isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    if (taskName != kSyncTaskName) return true;
    try {
      await _doSync();
      return true;
    } catch (_) {
      return false; // triggers exponential backoff retry
    }
  });
}

// ── Sync logic ────────────────────────────────────────────────────────────────

/// Mirrors SyncWorker.kt — checks auth, syncs inbox, fires notifications for
/// new threads. Called from the Workmanager isolate and (for testing) directly.
Future<void> _doSync() async {
  final tokenStorage = TokenStorage();
  final authRepository = AuthRepository(tokenStorage);
  if (!await authRepository.isSignedIn()) return;

  final settingsPrefs = await SettingsPrefs.load();
  final db = MailDatabase();
  try {
    final apiService = createGmailApiService(
      getToken: authRepository.getAccessToken,
      invalidateToken: authRepository.invalidateToken,
    );
    final mailRepository = MailRepository(
      api: apiService,
      threadDao: db.threadDao,
      messageDao: db.messageDao,
      labelDao: db.labelDao,
    );

    final knownIds = (await mailRepository.getInboxIds()).toSet();
    await mailRepository.syncInbox();

    // Skip notifications on first sync (no baseline) or if disabled by user.
    if (knownIds.isEmpty || !settingsPrefs.notificationsEnabled) return;

    final newIds =
        (await mailRepository.getInboxIds()).toSet().difference(knownIds);
    if (newIds.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    // Ensure the channel exists in this isolate (no-op if already created).
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          kNotificationChannelId,
          'New Mail',
          description: 'Notifications for new emails',
          importance: Importance.defaultImportance,
        ));

    for (final id in newIds) {
      final thread = await mailRepository.getThreadById(id);
      if (thread == null) continue;
      final sender = EmailParser.displayName(thread.fromAddress).isNotEmpty
          ? EmailParser.displayName(thread.fromAddress)
          : thread.fromAddress;
      await plugin.show(
        id.hashCode,
        sender,
        thread.subject,
        NotificationDetails(
          android: AndroidNotificationDetails(
            kNotificationChannelId,
            'New Mail',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
            actions: [
              const AndroidNotificationAction(
                'trash',
                'Delete',
                cancelNotification: true,
              ),
            ],
          ),
        ),
        payload: id, // thread ID — used in action handlers
      );
    }
  } finally {
    await db.close();
  }
}

// ── Notification action handlers ──────────────────────────────────────────────

/// Called when the "Delete" action button is tapped while the app is
/// in the background or terminated. Must be a top-level function.
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) async {
  if (response.actionId != 'trash') return;
  final threadId = response.payload;
  if (threadId == null) return;

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await trashThreadStandalone(threadId);
}

/// Trashes a thread using a freshly created repository — used in both the
/// foreground notification handler (main isolate) and the background handler.
Future<void> trashThreadStandalone(String threadId) async {
  final tokenStorage = TokenStorage();
  final authRepository = AuthRepository(tokenStorage);
  final db = MailDatabase();
  try {
    final apiService = createGmailApiService(
      getToken: authRepository.getAccessToken,
      invalidateToken: authRepository.invalidateToken,
    );
    final mailRepository = MailRepository(
      api: apiService,
      threadDao: db.threadDao,
      messageDao: db.messageDao,
      labelDao: db.labelDao,
    );
    await mailRepository.trashThread(threadId);
  } finally {
    await db.close();
  }
}
