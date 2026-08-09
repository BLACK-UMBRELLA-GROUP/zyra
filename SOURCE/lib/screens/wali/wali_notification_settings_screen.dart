// Wali-side notification settings — new 2026-07-26 (OA-ZYRA-124
// per-account-type UX review, #27). Previously WaliProfileScreen's
// "Notifications" row had no onTap at all (dead tap, no screen behind
// it) — this fixes that honestly rather than by reusing the Seeker's
// NotificationSettingsScreen verbatim, since that screen's copy is
// Seeker-specific ("When someone you've Considered matches back") and
// includes a "New Matches" toggle that doesn't apply to a Guardian account
// at all (a Guardian doesn't Browse or match).
//
// Reuses the same underlying AppState preference fields
// (notifyNewMessages, notifyWaliRequests) as the Seeker screen — per
// zyra_notification_service.dart, the in-app Bell already delivers
// 'new_message' and 'wali_request' rows to both Seeker and Guardian
// accounts alike, so these are the two toggles that are genuinely
// relevant here. 'new_match' is deliberately omitted.
//
// Same honest gap as the Seeker screen: push notifications aren't
// built yet (needs FCM/APNs credentials), and these toggles are
// session-only preferences that don't yet filter what the Bell shows.

import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class WaliNotificationSettingsScreen extends StatefulWidget {
  const WaliNotificationSettingsScreen({super.key});

  @override
  State<WaliNotificationSettingsScreen> createState() => _WaliNotificationSettingsScreenState();
}

class _WaliNotificationSettingsScreenState extends State<WaliNotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      // FIXED 2026-08-01 (Founder: "there should be no purple at top, it
      // should blend the pink/purple colour... that should be across all
      // things"). Same fix notifications_screen.dart got on 2026-07-27:
      // without this the transparent AppBar shows the Scaffold's own flat
      // background through, cutting the gender gradient off with a hard
      // purple strip. Body content compensates with SafeArea, which still
      // clears the status bar.
      extendBodyBehindAppBar: true,
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
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white12, width: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "You'll see Journey messages and link activity involving the "
                  "Seekers you supervise in the Bell icon in-app. Push "
                  "notifications to your device aren't built yet in this preview. "
                  "The toggles below are saved as your preference but don't "
                  "filter what appears in the Bell icon yet.",
                  style: ZyraText.subtext(size: 12, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 20),
              _PreferenceRow(
                label: 'Messages',
                subtitle: 'Conversation activity in a Journey you supervise',
                value: state.notifyNewMessages,
                onChanged: (v) => setState(() => state.setNotificationPreference(newMessages: v)),
              ),
              _PreferenceRow(
                label: 'Seeker Link Activity',
                subtitle: 'A Seeker links you, or asks for your action as their Guardian',
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
          Switch(value: value, onChanged: onChanged, activeThumbColor: ZyraColors.accentBorder),
        ],
      ),
    );
  }
}
