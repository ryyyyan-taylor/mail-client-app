import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for user-configurable settings.
/// Mirrors SettingsPrefs.kt 1:1.
///
/// Call [SettingsPrefs.load()] once at startup (inside ProviderScope) and
/// pass the instance to providers via Riverpod.
class SettingsPrefs {
  SettingsPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const defaultSyncInterval = 15;
  static const _keySyncInterval = 'sync_interval_minutes';
  static const _keyNotifications = 'notifications_enabled';

  static Future<SettingsPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsPrefs(prefs);
  }

  int get syncIntervalMinutes =>
      _prefs.getInt(_keySyncInterval) ?? defaultSyncInterval;

  set syncIntervalMinutes(int value) =>
      _prefs.setInt(_keySyncInterval, value);

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotifications) ?? true;

  set notificationsEnabled(bool value) =>
      _prefs.setBool(_keyNotifications, value);
}
