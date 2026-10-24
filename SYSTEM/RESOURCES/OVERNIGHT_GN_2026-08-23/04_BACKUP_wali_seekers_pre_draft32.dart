// Wali "Seekers" tab — list of linked Seekers per WALI NAVIGATION.
// Real linking (ZyraWaliLinkService) — populated from wali_links.
//
// 2026-08-13, DR-ZYRA-152: in DEBUG AND PROFILE BUILDS the Guardian dev
// panel composes this list — real links first, stand-ins topping up, and
// 0 meaning zero. That mirrors the Seeker side's Connections list exactly
// (Founder, 2026-08-12: "zero means zero, every time"), and it is what
// makes the panel's Reset mean reset here. A release build never calls
// composeWaliWards at all and shows the fetched links untouched.

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_ward_card.dart';
import 'wali_invite_seeker_screen.dart';

class WaliSeekersScreen extends StatefulWidget {
  const WaliSeekersScreen({super.key});

  @override
  State<WaliSeekersScreen> createState() => _WaliSeekersScreenState();
}

class _WaliSeekersScreenState extends State<WaliSeekersScreen> {
  /// False until the link fetch returns — 2026-08-14 (DR-ZYRA-166).
  ///
  /// This screen rendered "No Seekers linked yet" plus an invite CTA
  /// while the fetch was still in flight. A Guardian with two wards was
  /// told, briefly, that they had none and offered a button to fix it.
  /// It also made a slow request indistinguishable from an empty account.
  bool _loaded = false;

  /// Ward id → signed photo URL — DR-ZYRA-171, the card family upgrade.
  /// A Guardian can view their own ward (guard-suite clause 2); a ward
  /// with no viewable photo renders the standard quiet block.
  Map<String, String> _photos = const {};

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    if (!kReleaseMode) ZyraDevScenario.instance.addListener(_onChange);
    ZyraWaliLinkService.fetchLinkedPeople(asWali: true).then((people) async {
      if (!mounted) return;
      AppState.instance.setWaliRealLinkedSeekers(people);
      setState(() => _loaded = true);
      if (people.isEmpty) return;
      final profiles =
          await ZyraDiscoveryService.profilesByIds(people.map((p) => p.id).toList());
      if (!mounted || profiles.isEmpty) return;
      setState(() => _photos = {
            for (final p in profiles)
              if (p.photos.isNotEmpty) p.id: p.photos.first,
          });
    });
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    if (!kReleaseMode) ZyraDevScenario.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  /// The Seekers this screen draws. See the header: the panel owns this
  /// list in debug and profile builds, and nothing else does in release.
  List<WaliLinkedPerson> get _wards {
    final real = AppState.instance.waliRealLinkedSeekers;
    if (kReleaseMode) return real;
    return ZyraDevScenario.composeWaliWards(real: real);
  }

  @override
  Widget build(BuildContext context) {
    final linked = _wards;
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
              child: Text('Seekers', style: ZyraText.heading(size: 26)),
            ),
            Expanded(
              child: !_loaded
                  ? const ZyraLoading()
                  : linked.isEmpty
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
                        // CARD FAMILY, not icon rows — DR-ZYRA-171
                        // (Founder: "Guardian profile card should feel
                        // like the same component family"). Same
                        // ZyraCardMetrics numbers as every person row
                        // in the app.
                        for (final person in linked)
                          ZyraWardCard(
                            name: person.firstName,
                            photoUrl: _photos[person.id] ?? '',
                            statusLine:
                                person.relationshipLabel ?? 'Linked Seeker',
                            detailLine: person.isMain
                                ? 'You are their Main Guardian'
                                : 'Additional Guardian',
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
