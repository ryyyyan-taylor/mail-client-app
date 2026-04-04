import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import 'data/local/settings_prefs.dart';
import 'providers/providers.dart';
import 'router.dart';
import 'ui/theme/app_theme.dart';
import 'worker/sync_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge: let Flutter draw behind system bars.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Transparent status bar + nav bar, light icons — applied globally so it
  // holds in landscape where no AppBar is present to set it per-screen.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Allow portrait + landscape but never upside-down.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Load SettingsPrefs before runApp so the provider is immediately available.
  final settingsPrefs = await SettingsPrefs.load();

  // ── Notifications ─────────────────────────────────────────────────────────
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  await notificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification_email'),
    ),
    onDidReceiveNotificationResponse: _onNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: onNotificationActionBackground,
  );
  // Create the notification channel once at startup (idempotent).
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        kNotificationChannelId,
        'New Mail',
        description: 'Notifications for new emails',
        importance: Importance.defaultImportance,
      ));

  // Request POST_NOTIFICATIONS permission (Android 13+; no-op on older).
  await Permission.notification.request();

  // ── Workmanager ───────────────────────────────────────────────────────────
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    kSyncTaskName,
    kSyncTaskName,
    frequency: Duration(minutes: settingsPrefs.syncIntervalMinutes),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 1),
  );

  runApp(
    ProviderScope(
      overrides: [
        // Override the placeholder with the real loaded instance.
        settingsPrefsProvider.overrideWithValue(settingsPrefs),
      ],
      child: const MailClientApp(),
    ),
  );
}

/// Called when a notification is tapped or an action button is pressed while
/// the app is in the foreground.
void _onNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null) return;

  if (response.notificationResponseType ==
          NotificationResponseType.selectedNotificationAction &&
      response.actionId == 'trash') {
    // Fire-and-forget: trash without opening the app.
    trashThreadStandalone(payload);
    return;
  }

  // Notification body tapped — deep-link into the thread.
  appRouter.go(Routes.thread(payload));
}

class MailClientApp extends StatelessWidget {
  const MailClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mail',
      // Always dark — never follows system theme.
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
