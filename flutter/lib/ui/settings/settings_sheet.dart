import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../theme/colors.dart';
import 'settings_notifier.dart';

const _syncOptions = [
  (15, '15 minutes'),
  (30, '30 minutes'),
  (60, '1 hour'),
];

/// Settings bottom sheet.
/// Returns `true` via [Navigator.pop] when the user signs out,
/// signalling the caller to navigate to the sign-in screen.
class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'Settings',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Divider(height: 0.5, thickness: 0.5, color: kDivider),
          _SectionLabel('Account'),

          // Account row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Signed in as',
                        style: TextStyle(
                            color: kTextSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.email.isEmpty ? '—' : state.email,
                        style: const TextStyle(
                            color: kTextPrimary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _signingOut ? null : _handleSignOut,
                  style: TextButton.styleFrom(foregroundColor: kDanger),
                  child: _signingOut
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: kDanger, strokeWidth: 2),
                        )
                      : const Text('Sign out', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),

          const Divider(height: 0.5, thickness: 0.5, color: kDivider),
          _SectionLabel('Background sync interval'),

          // Sync interval options
          ..._syncOptions.map(
            (option) => InkWell(
              onTap: () => notifier.setSyncInterval(option.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Radio<int>(
                      value: option.$1,
                      groupValue: state.syncIntervalMinutes,
                      onChanged: (v) {
                        if (v != null) notifier.setSyncInterval(v);
                      },
                      activeColor: kAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      option.$2,
                      style: const TextStyle(
                          color: kTextPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 0.5, thickness: 0.5, color: kDivider),
          _SectionLabel('Notifications'),

          // Notifications toggle
          InkWell(
            onTap: () => notifier
                .setNotificationsEnabled(!state.notificationsEnabled),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    state.notificationsEnabled
                        ? Icons.notifications
                        : Icons.notifications_off,
                    size: 20,
                    color: state.notificationsEnabled
                        ? kAccent
                        : kTextSecondary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'New mail notifications',
                      style:
                          TextStyle(color: kTextPrimary, fontSize: 14),
                    ),
                  ),
                  Switch(
                    value: state.notificationsEnabled,
                    onChanged: notifier.setNotificationsEnabled,
                    activeColor: kAccent,
                    activeTrackColor: kAccent.withAlpha(76),
                    inactiveThumbColor: kTextSecondary,
                    inactiveTrackColor:
                        kTextSecondary.withAlpha(51),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(settingsNotifierProvider.notifier).signOut();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _signingOut = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: kTextSecondary,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
