// Wali Dashboard — per WALI SCREEN FLOW, this is where a Wali lands
// after onboarding and where a linked Seeker's Journey milestones
// surface (Family Stage, Timeline). Linking is real (see
// ZyraWaliLinkService).
//
// 2026-07-26: real Journey visibility wired up (ZyraWaliJourneyService,
// backed by 20260726130000_wali_journey_visibility.sql) — builds the
// "Standard Guardian capabilities" ratified in APP/Standards/
// WALI_ARCHITECTURE_CURRENT_VERSION_V5.md since 2026-07-04 (View
// Journey progress / Timeline / messages), previously unbuilt. A
// linked Seeker with no real Journey yet (still at Browse/Potential
// Journey stage) still shows as "linked, no Journey yet" — Browse-
// stage activity itself stays out of scope, per that migration's own
// scope note.

import 'package:flutter/material.dart';
import '../../data/zyra_journey_stages.dart';
import '../../services/zyra_journey_service.dart';
import '../../services/zyra_wali_journey_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'wali_invite_seeker_screen.dart';
import 'wali_journey_detail_screen.dart';
import '../../widgets/zyra_loading.dart';

class WaliDashboardScreen extends StatefulWidget {
  const WaliDashboardScreen({super.key});

  @override
  State<WaliDashboardScreen> createState() => _WaliDashboardScreenState();
}

class _WaliDashboardScreenState extends State<WaliDashboardScreen> {
  bool _loading = true;
  List<WaliJourneyView> _journeys = [];

  /// Journeys with a Family Review open. On this screen that is not a
  /// nicety — a Family Review is the one thing on a Guardian's dashboard
  /// that is waiting on THEM, and the row previously read 'Phase 2' with
  /// nothing to say a decision was outstanding.
  ///
  /// One batched query for every linked Seeker; see
  /// ZyraJourneyService.fetchOpenReviewMatchIds. Note that RLS grants
  /// this to a MAIN Guardian only, so an additional Guardian sees the
  /// plain stage — the same limit the detail screen has always had.
  Set<String> _openReviews = const {};

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    _load();
  }

  Future<void> _load() async {
    final journeys = await ZyraWaliJourneyService.fetchLinkedJourneys();
    if (!mounted) return;
    setState(() {
      _journeys = journeys;
      _loading = false;
    });

    // Second pass, deliberately not awaited before the list renders. The
    // stage label is already correct without it; the override only makes
    // it more specific, and holding the whole dashboard behind a second
    // round-trip to add a word is the wrong trade.
    //
    // Ended and paused Journeys are excluded because _statusLabel returns
    // before it ever reaches the stage for those two.
    final open = await ZyraJourneyService.fetchOpenReviewMatchIds(
      _journeys
          .where((j) => j.status != 'ended' && !j.isSuspended)
          .map((j) => j.matchId)
          .toList(),
    );
    if (!mounted || open.isEmpty) return;
    setState(() => _openReviews = open);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  /// Status FIRST, then stage. Ended and Paused are not stages and must
  /// not be reported as one — a paused Journey still holds a
  /// journey_stage, and printing it would say the Journey is moving.
  ///
  /// The stage itself comes from the one map (data/zyra_journey_stages
  /// .dart, Founder-approved 2026-08-09). This method used to carry its
  /// own copy of the switch, which had drifted from the Journey Detail
  /// screen it links to: this one said 'Phase 1', that one said 'Phase 1
  /// — Foundations'. Both are now Faith & Values, and 'Phase N' is back
  /// to being an internal name that no user sees.
  ///
  /// No longer static — it reads [_openReviews].
  String _statusLabel(WaliJourneyView j) {
    if (j.status == 'ended') return 'Journey ended';
    if (j.isSuspended) return 'Journey paused';
    return ZyraJourneyStages.labelFor(
      j.journeyStage,
      reviewOpen: _openReviews.contains(j.matchId),
    );
  }

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
                  : _loading
                      ? const ZyraLoading()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            Text('LINKED SEEKERS', style: ZyraText.chapterLabel(color: Colors.white54)),
                            const SizedBox(height: 10),
                            for (final person in linked)
                              if (!_journeys.any((j) => j.linkedSeekerId == person.id))
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline, color: Colors.white54, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(person.firstName, style: ZyraText.body(size: 14, color: Colors.white))),
                                      Text('No Journey yet', style: ZyraText.subtext(size: 11.5, color: Colors.white38)),
                                    ],
                                  ),
                                ),
                            if (_journeys.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text('JOURNEYS', style: ZyraText.chapterLabel(color: Colors.white54)),
                              const SizedBox(height: 10),
                              for (final j in _journeys)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: ZyraColors.iconButtonBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => WaliJourneyDetailScreen(journey: j)),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${j.linkedSeekerName} & ${j.partner.firstName}',
                                                        style: ZyraText.body(size: 14, color: Colors.white)),
                                                    const SizedBox(height: 3),
                                                    Text(_statusLabel(j), style: ZyraText.subtext(size: 11.5)),
                                                  ],
                                                ),
                                              ),
                                              if (j.journeyStage == 'family_stage')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: ZyraColors.accentBg,
                                                    border: Border.all(color: ZyraColors.accentBorder, width: 1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text('Answer questions', style: ZyraText.subtext(size: 10.5, color: Colors.white)),
                                                )
                                              else
                                                const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
