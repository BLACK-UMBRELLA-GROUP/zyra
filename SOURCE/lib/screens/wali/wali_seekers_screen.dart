// Wali "Seekers" tab — list of linked Seekers per WALI NAVIGATION.
// Real linking (ZyraWaliLinkService) — populated from wali_links.

import 'package:flutter/material.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'wali_invite_seeker_screen.dart';

class WaliSeekersScreen extends StatefulWidget {
  const WaliSeekersScreen({super.key});

  @override
  State<WaliSeekersScreen> createState() => _WaliSeekersScreenState();
}

class _WaliSeekersScreenState extends State<WaliSeekersScreen> {
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
              child: Text('Seekers', style: ZyraText.heading(size: 22)),
            ),
            Expanded(
              child: linked.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ZyraEmptyState(
                        icon: Icons.person_search_outlined,
                        message: 'No Seekers linked yet.',
                        ctaLabel: 'Invite your Seeker',
                        onCta: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WaliInviteSeekerScreen()),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
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
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
