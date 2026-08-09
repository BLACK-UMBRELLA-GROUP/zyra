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
                        // THE MISSING ENTRY POINT — added 2026-08-07.
                        //
                        // "Invite your Seeker" existed ONLY inside
                        // `linked.isEmpty`, on this screen and the
                        // Dashboard. So the control vanished the moment it
                        // succeeded once: a Guardian with one Seeker had no
                        // way to invite a second, and the Founder could not
                        // find the flow at all because his test accounts
                        // already had Seekers linked.
                        //
                        // The functionality was complete the whole time —
                        // accept_wali_invite has always handled both
                        // directions. Only the door was missing.
                        //
                        // Same + pattern the Seeker's Guardian tab uses:
                        // sitting where the next entry would go, so the
                        // list reads Seeker → Seeker → +.
                        const SizedBox(height: 18),
                        Center(
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const WaliInviteSeekerScreen()),
                              ),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.28),
                                      width: 1),
                                ),
                                child: const Icon(Icons.add, size: 26, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text('Invite another Seeker',
                              style: ZyraText.subtext(
                                  size: 12.5,
                                  color: Colors.white.withValues(alpha: 0.55))),
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
