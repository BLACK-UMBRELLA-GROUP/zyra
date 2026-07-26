// Profile tab — APP/Profiles/Script/Script_V1.md: no white content
// containers, info sits directly on the page background, white section
// headings, plan badge (ZYRA Basic / ZYRA One) replaces generic
// "Member" label. Includes the Passed/Saved/Considered review lists
// (DR-ZYRA-099 labels, 2026-07-25) per the same spec's Connection
// Profile Expansion section (kept as a simple list here rather than
// the full reused-Browse-viewer expansion, which is a larger follow-up).

import 'package:flutter/material.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../subscription/upgrade_screen.dart';
import '../welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _signOut(BuildContext context) async {
    // Real sign-out (OA-102) — only meaningful once Supabase is
    // configured; no-ops harmlessly via ZyraAuth otherwise since
    // there's no session to end.
    await ZyraAuth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    int? age;
    if (state.dob != null) {
      final now = DateTime.now();
      final dob = state.dob!;
      age = now.year - dob.year;
      final hadBirthdayThisYear = now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
      if (!hadBirthdayThisYear) age -= 1;
    }

    return Container(
      // 2026-07-25: gender-matched gradient (DR-ZYRA-094/OA-ZYRA-123)
      // instead of the neutral brand gradient — Blue for male, Pink for
      // female. Was previously hardcoded to the neutral gradient here;
      // see ZyraColors.genderGradient() doc comment.
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(state.gender)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          children: [
            Row(
              children: [
                ClipOval(
                  child: state.photos.isNotEmpty
                      ? Image.network(state.photos.first, width: 64, height: 64, fit: BoxFit.cover)
                      : Container(
                          width: 64,
                          height: 64,
                          color: ZyraColors.iconButtonBg,
                          child: const Icon(Icons.person, color: Colors.white38, size: 30),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.name ?? 'Your Profile', style: ZyraText.heading(size: 20)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: ZyraColors.accentBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: ZyraColors.accentBorder, width: 0.5),
                          ),
                          child: Text(
                            state.plan == ZyraPlan.one ? 'ZYRA One' : 'ZYRA Basic',
                            style: ZyraText.subtext(size: 11, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('ABOUT ME', style: ZyraText.chapterLabel(color: Colors.white54)),
            const SizedBox(height: 10),
            _InfoRow(label: 'Age', value: age?.toString() ?? '—'),
            _InfoRow(label: 'Gender', value: state.gender == null ? '—' : (state.gender == 'male' ? 'Brother' : 'Sister')),
            _InfoRow(label: 'Location', value: state.location ?? '—'),
            const SizedBox(height: 24),
            Text('PUBLIC INFORMATION', style: ZyraText.chapterLabel(color: Colors.white54)),
            const SizedBox(height: 10),
            _InfoRow(label: 'Sect', value: state.sect ?? '—'),
            _InfoRow(label: 'Photos', value: '${state.photos.length} added'),
            const SizedBox(height: 24),
            Text('YOUR CONNECTIONS', style: ZyraText.chapterLabel(color: Colors.white54)),
            const SizedBox(height: 10),
            // 2026-07-25, DR-ZYRA-099: labels renamed Declined→Passed,
            // Likes→Considered (UI-layer only — state.declined/
            // state.outgoingLikes field names unchanged, see
            // browse_screen.dart header comment and OA-ZYRA-138).
            _ConnectionRow(label: 'Passed', count: state.declined.length),
            _ConnectionRow(label: 'Saved', count: state.saved.length),
            _ConnectionRow(label: 'Considered (Outgoing)', count: state.outgoingLikes.length),
            const SizedBox(height: 24),
            Text('SETTINGS', style: ZyraText.chapterLabel(color: Colors.white54)),
            const SizedBox(height: 10),
            _SettingsRow(
              label: 'Notifications',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
            ),
            _SettingsRow(
              label: 'Privacy',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacySettingsScreen())),
            ),
            _SettingsRow(
              label: 'Manage Subscription',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen())),
            ),
            // "Link a Wali" removed 2026-07-26 — now its own bottom-nav
            // tab (screens/wali/seeker_wali_tab.dart) per the ratified
            // SEEKER NAVIGATION spec, so this row would have been a
            // second path to the same flow.
            const _SettingsRow(label: 'Help & Support'),
            _SettingsRow(label: 'Sign Out', onTap: () => _signOut(context)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ZyraText.subtext(size: 13))),
          Text(value, style: ZyraText.body(size: 13, color: Colors.white)),
        ],
      ),
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  final String label;
  final int count;
  const _ConnectionRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ZyraText.body(size: 13.5, color: Colors.white))),
          Text('$count', style: ZyraText.subtext(size: 13)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SettingsRow({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: ZyraText.body(size: 13.5, color: Colors.white))),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
