// Wali Profile tab — own identity + settings. Deliberately much
// smaller than the Seeker's ProfileScreen: per WALI ARCHITECTURE,
// "Wali accounts carry identity only" — there's no Browse-visible
// profile, no connections list, no compatibility data to show here.

import 'package:flutter/material.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../welcome_screen.dart';
import 'link_wali_screen.dart';

class WaliProfileScreen extends StatefulWidget {
  const WaliProfileScreen({super.key});

  @override
  State<WaliProfileScreen> createState() => _WaliProfileScreenState();
}

class _WaliProfileScreenState extends State<WaliProfileScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    ZyraWaliLinkService.fetchLinkedPeople(asWali: true).then((people) {
      if (mounted) AppState.instance.setWaliRealLinkedSeekers(people);
    });
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _signOut(BuildContext context) async {
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
    return Container(
      // 2026-07-25: was hardcoded to brandGradientMale regardless of the
      // signed-in Wali's actual gender (DR-ZYRA-094/OA-ZYRA-123 gap) —
      // now reads the Wali's own gender like every other profile-context
      // screen. Every current test Wali persona is male, so this is a
      // no-op today but is correct once a female Wali persona exists.
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(state.gender)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: ZyraColors.iconButtonBg),
                  child: const Icon(Icons.shield_outlined, color: Colors.white38, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.waliName ?? 'Your Profile', style: ZyraText.heading(size: 20)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: ZyraColors.accentBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ZyraColors.accentBorder, width: 0.5),
                        ),
                        child: Text(
                          state.waliHasExtendedWali ? 'Extended Wali' : 'Standard Wali',
                          style: ZyraText.subtext(size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('ABOUT YOU', style: ZyraText.chapterLabel(color: Colors.white54)),
            const SizedBox(height: 10),
            _InfoRow(label: 'Relationship', value: state.waliRelationship ?? '—'),
            _InfoRow(label: 'Linked Seekers', value: '${state.waliRealLinkedSeekers.length}'),
            const SizedBox(height: 24),
            Text('SETTINGS', style: ZyraText.chapterLabel(color: Colors.white54)),
            const SizedBox(height: 10),
            const _SettingsRow(label: 'Notifications'),
            const _SettingsRow(label: 'Privacy'),
            _SettingsRow(
              label: 'Link a Seeker',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LinkWaliScreen(asWali: true))),
            ),
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
