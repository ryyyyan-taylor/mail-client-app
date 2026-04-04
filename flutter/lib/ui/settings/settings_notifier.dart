import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/local/settings_prefs.dart';
import '../../providers/providers.dart';
import '../../worker/sync_worker.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsUiState {
  const SettingsUiState({
    this.email = '',
    this.syncIntervalMinutes = SettingsPrefs.defaultSyncInterval,
    this.notificationsEnabled = true,
  });

  final String email;
  final int syncIntervalMinutes;
  final bool notificationsEnabled;

  SettingsUiState copyWith({
    String? email,
    int? syncIntervalMinutes,
    bool? notificationsEnabled,
  }) {
    return SettingsUiState(
      email: email ?? this.email,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<SettingsUiState> {
  @override
  SettingsUiState build() {
    final prefs = ref.read(settingsPrefsProvider);
    Future.microtask(_loadEmail);
    return SettingsUiState(
      syncIntervalMinutes: prefs.syncIntervalMinutes,
      notificationsEnabled: prefs.notificationsEnabled,
    );
  }

  Future<void> _loadEmail() async {
    final email = await ref.read(authRepositoryProvider).getSignedInEmail();
    state = state.copyWith(email: email ?? '');
  }

  void setSyncInterval(int minutes) {
    ref.read(settingsPrefsProvider).syncIntervalMinutes = minutes;
    state = state.copyWith(syncIntervalMinutes: minutes);
    // Reschedule with the new interval; UPDATE policy applies at the next run.
    Workmanager().registerPeriodicTask(
      kSyncTaskName,
      kSyncTaskName,
      frequency: Duration(minutes: minutes),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }

  void setNotificationsEnabled(bool enabled) {
    ref.read(settingsPrefsProvider).notificationsEnabled = enabled;
    state = state.copyWith(notificationsEnabled: enabled);
  }

  /// Signs out and clears local credentials.
  /// Caller is responsible for post-navigation.
  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}
