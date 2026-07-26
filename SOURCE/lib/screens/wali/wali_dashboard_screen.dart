// Wali Dashboard — per WALI SCREEN FLOW, this is where a Wali lands
// after onboarding and where a linked Seeker's Journey milestones would
// surface (Family Stage, Timeline). Linking is real (see
// ZyraWaliLinkService) — a linked Seeker now genuinely shows up here —
// but Journey/Timeline visibility for a Wali isn't built yet, so a
// linked Seeker just shows a name, not milestones.

import 'package:flutter/material.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'wali_invite_seeker_screen.dart';

class WaliDashboardScreen extends StatefulWidget {
  const WaliDashboardScreen({super.key});

  @override
  State<WaliDashboardScreen> createState() => _WaliDashboardScreenState();
}

class _WaliDashboardScreenState extends State<WaliDashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    final linked = AppState.instance.waliRealLinkedSeekers;
    return Container(
      // 2026-07-25: gender-matched gradient, was hardcoded Male — see
      // ZyraColors.genderGradient() doc comment / DR-ZYRA-094.
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Dashboard', style: ZyraText.heading(size: 22)),
            ),
            Expanded(
              child: linked.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ZyraEmptyState(
                        icon: Icons.family_restroom_outlined,
                        message: 'Once your Seeker joins and their journey begins, milestones will appear here.',
                        ctaLabel: 'Invite your Seeker',
                        onCta: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WaliInviteSeekerScreen()),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        Text('LINKED SEEKERS', style: ZyraText.chapterLabel(color: Colors.white54)),
                        const SizedBox(height: 10),
                        for (final person in linked)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, color: Colors.white54, size: 18),
                                const SizedBox(width: 10),
                                Text(person.firstName, style: ZyraText.body(size: 14, color: Colors.white)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Journey milestones for your linked Seeker aren\'t wired up yet — this only confirms the link itself.',
                          style: ZyraText.subtext(size: 11.5, color: Colors.white38),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
