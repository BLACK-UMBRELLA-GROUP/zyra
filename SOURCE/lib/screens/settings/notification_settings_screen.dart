// Notification settings — real scope defined 2026-07-26 (DR-ZYRA-101
// audit, Settings/Search/Notifications build-out). APP/Notifications/
// Summary.md was, until this pass, literally "Placeholder — Approved
// Application Structure" with no feature definition at all.
//
// Honest current state: there is no push notification system in this
// build — no delivery mechanism, no backend table, and (per an
// Evidence-First sweep of this codebase) no Bell icon anywhere yet
// either, despite APP/Navigation/SEEKER NAVIGATION/Summary.md's own
// ratified rule ("Notifications use the Bell Icon... not a navigation
// tab") assuming one exists. Rather than build a toggle screen that
// implies working notifications, this screen says so plainly and
// captures preference toggles (AppState.notifyNewMatches/
// notifyNewMessages/notifyWaliRequests) that are ready to wire up the
// moment real push infrastructure is built — they don't do anything
// yet, and the screen says that too.

import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(state.gender)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(color: Colors.white12, width: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Push notifications aren't built yet in this preview — nothing "
                  "will be sent to your device. The toggles below are saved as your "
                  "preference now, ready for when notifications are switched on.",
                  style: ZyraText.subtext(size: 12, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 20),
              _PreferenceRow(
                label: 'New Matches',
                subtitle: "When someone you've Considered matches back",
                value: state.notifyNewMatches,
                onChanged: (v) => setState(() => state.setNotificationPreference(newMatches: v)),
              ),
              _PreferenceRow(
                label: 'New Messages',
                subtitle: 'Conversation activity in an Active Journey',
                value: state.notifyNewMessages,
                onChanged: (v) => setState(() => state.setNotificationPreference(newMessages: v)),
              ),
              _PreferenceRow(
                label: 'Wali Requests',
                subtitle: 'Invite/link activity involving your Wali',
                value: state.notifyWaliRequests,
                onChanged: (v) => setState(() => state.setNotificationPreference(waliRequests: v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ZyraText.body(size: 14, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: ZyraText.subtext(size: 11.5)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: ZyraColors.accentBorder),
        ],
      ),
    );
  }
}
