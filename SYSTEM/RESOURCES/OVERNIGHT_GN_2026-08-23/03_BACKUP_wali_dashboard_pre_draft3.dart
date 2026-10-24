// Wali Dashboard — REBUILT AS A HUB 2026-08-15 (DR-ZYRA-171, the full
// Guardian first-draft build; Founder: "This is a Dashboard/Hub, not a
// page dedicated to one message type").
//
// The five questions this screen answers, in order, top to bottom:
//   1. Does anything need me?      → NEEDS YOUR ATTENTION (or the honest
//                                    all-clear line — absence is stated,
//                                    never implied)
//   2. Which Seekers am I          → YOUR SEEKERS: one ZyraWardCard per
//      responsible for?              ward, the Connections card family
//   3. Where is each Journey?      → chapter name + the 8-stage rail on
//                                    each card (canonical stage map;
//                                    raw statuses never shown)
//   4. Is anything happening?      → per-ward pipeline chips (Active /
//                                    Paused / Ended — real rows), plus
//                                    staged Browse-activity chips in dev
//                                    builds only (see the honesty note)
//   5. What changed recently?      → RECENTLY: latest Timeline milestone
//                                    per live Journey
//
// HONESTY NOTE ON ACTIVITY (brief §7): a ward's Browse decisions
// (Saved / Considered / Declined) have NO Guardian read path in RLS
// today — saves/likes/passes are owner-only tables. Those chips render
// exclusively from the dev panel's staged counts in debug/profile
// builds, so the design is reviewable without pretending a server
// capability exists. The real read is a privacy decision + RPC of its
// own, raised in the register with this build.
//
// 2026-08-13, DR-ZYRA-152: the Guardian dev panel composes wards,
// journeys and the staged review in DEBUG AND PROFILE BUILDS — real
// rows first, stand-ins topping up, 0 meaning zero. Release calls none
// of it. 2026-08-14 (DR-ZYRA-166): loading is checked before empty.
// 2026-08-15: the journeys fetch distinguishes FAILURE from empty
// (DR-ZYRA-167's rule) — a failed load shows an error with Try again,
// never an empty state with an invite button.
//
// AN ADDITIONAL GUARDIAN still sees no Journey rows (the counterpart
// card returns null to non-Main Guardians). DR-ZYRA-168 ruled the
// target state — full visibility, same as Main — and ruled it ships as
// its own coordinated batch (RLS + card RPC + guard-suite rewrite), so
// this screen deliberately does not preempt it. The panel's role
// segment stages exactly today's behaviour.

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../data/zyra_journey_stages.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_journey_service.dart';
import '../../services/zyra_wali_journey_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_ward_card.dart';
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

  /// True when the LAST journeys fetch failed (null from the service).
  /// Rows already on screen stay (stale beats blank); with nothing to
  /// show, the error state owns the body. DR-ZYRA-167's pattern.
  bool _loadFailed = false;
  List<WaliJourneyView> _journeys = [];

  /// Journeys with a Family Review open — the one thing on this screen
  /// that is waiting on THE GUARDIAN. One batched query; Main-only under
  /// RLS, exactly like the detail screen.
  Set<String> _openReviews = const {};

  /// Ward id → signed photo URL. A Guardian can view their own ward
  /// (guard-suite clause 2), so this is a legitimate read; stand-ins have
  /// no row and fall back to the quiet block.
  Map<String, String> _wardPhotos = const {};

  /// The latest Timeline milestone per live Journey — the RECENTLY
  /// section. Loaded after first paint, like [_openReviews]: recency is
  /// a nicety and must never hold the dashboard hostage.
  List<({WaliJourneyView j, String type, DateTime at})> _recent = const [];

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    if (!kReleaseMode) ZyraDevScenario.instance.addListener(_onChange);
    _load();
  }

  /// The Seekers this screen draws — panel-composed in debug and profile
  /// builds, the fetched links untouched in release. Shared with the
  /// Journey composition below so a Journey can never belong to a ward
  /// the list above it does not show.
  List<WaliLinkedPerson> get _wards {
    final real = AppState.instance.waliRealLinkedSeekers;
    if (kReleaseMode) return real;
    return ZyraDevScenario.composeWaliWards(real: real);
  }

  /// The Journeys this screen draws.
  List<WaliJourneyView> get _visibleJourneys {
    if (kReleaseMode) return _journeys;
    return ZyraDevScenario.composeWaliJourneys(
      wards: _wards,
      real: _journeys,
    );
  }

  Future<void> _load() async {
    final journeys = await ZyraWaliJourneyService.fetchLinkedJourneys();
    if (!mounted) return;
    setState(() {
      if (journeys == null) {
        _loadFailed = true; // keep whatever we already had
      } else {
        _loadFailed = false;
        _journeys = journeys;
      }
      _loading = false;
    });
    if (journeys == null) return;

    // Second pass, deliberately not awaited before the list renders —
    // each of these makes the dashboard MORE specific, none is needed
    // for it to be correct.
    final live = journeys
        .where((j) => j.status != 'ended' && !j.isSuspended)
        .map((j) => j.matchId)
        .toList();
    final open = await ZyraJourneyService.fetchOpenReviewMatchIds(live);
    if (mounted && open.isNotEmpty) setState(() => _openReviews = open);

    // Ward photos — real wards only.
    final wardIds = AppState.instance.waliRealLinkedSeekers
        .map((p) => p.id)
        .toList();
    if (wardIds.isNotEmpty) {
      final profiles = await ZyraDiscoveryService.profilesByIds(wardIds);
      if (mounted && profiles.isNotEmpty) {
        setState(() => _wardPhotos = {
              for (final p in profiles)
                if (p.photos.isNotEmpty) p.id: p.photos.first,
            });
      }
    }

    // RECENTLY — the newest milestone of each live Journey (bounded: a
    // Guardian's Journey count is small by the product's own model).
    final recent = <({WaliJourneyView j, String type, DateTime at})>[];
    for (final j in journeys.where((j) => j.status != 'ended').take(4)) {
      final tl = await ZyraWaliJourneyService.fetchTimeline(j.matchId);
      if (tl.isNotEmpty) {
        final last = tl.last;
        recent.add((j: j, type: last.type, at: last.occurredAt));
      }
    }
    recent.sort((a, b) => b.at.compareTo(a.at));
    if (mounted && recent.isNotEmpty) {
      setState(() => _recent = recent.take(4).toList());
    }
  }

  void _retry() {
    setState(() => _loading = true);
    _load();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    if (!kReleaseMode) ZyraDevScenario.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  /// Status FIRST, then stage — Ended and Paused are not stages and must
  /// not be reported as one. Chapter names come from the one map
  /// (data/zyra_journey_stages.dart); 'Phase N' is internal vocabulary
  /// no Guardian sees.
  String _statusLabel(WaliJourneyView j, Set<String> reviewIds) {
    if (j.status == 'ended') return 'Journey ended';
    if (j.isSuspended) return 'Journey paused';
    return ZyraJourneyStages.labelFor(
      j.journeyStage,
      reviewOpen: reviewIds.contains(j.matchId),
    );
  }

  /// Real open reviews plus the panel's staged one in debug/profile.
  Set<String> _reviewIds(List<WaliJourneyView> journeys) {
    if (kReleaseMode) return _openReviews;
    return {..._openReviews, ...ZyraDevScenario.waliOpenReviewIds(journeys)};
  }

  /// The friendly words for a milestone type — RECENTLY speaks the
  /// Timeline's language, never the column's.
  static String _milestoneLabel(String type) => switch (type) {
        'match_created' => 'Matched',
        'journey_started' => 'Journey began',
        'compatibility_revealed' => 'Compatibility revealed',
        'salam_exchanged' => 'Salam exchanged',
        'guardian_linked' => 'Guardian step complete',
        'phase_1_complete' => 'Faith & Values complete',
        'phase_2_complete' => 'Building a Life complete',
        'phase_3_complete' => 'Navigating Life complete',
        'family_stage' => 'Family Compatibility reached',
        'conversation_started' => 'Open Conversation began',
        'journey_paused' => 'Journey paused',
        'journey_continued' => 'Journey continued',
        'journey_ended' => 'Journey ended',
        'meeting_confirmed' => 'Meeting confirmed',
        'nikah_confirmed' => 'Nikah confirmed',
        _ => 'Progress made',
      };

  static String _ago(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 60) return 'just now';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    return '${(d.inDays / 30).floor()}mo ago';
  }

  void _openJourney(WaliJourneyView j) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WaliJourneyDetailScreen(journey: j)),
    );
  }

  /// Everything waiting on the Guardian, as cards: open Family Reviews
  /// first (a decision), then Journeys parked at the Guardian Gate (a
  /// step only a Guardian can complete).
  List<Widget> _attentionCards(
      List<WaliJourneyView> journeys, Set<String> reviewIds) {
    final cards = <Widget>[];
    for (final j in journeys) {
      if (j.status == 'ended') continue;
      if (reviewIds.contains(j.matchId)) {
        cards.add(_AttentionCard(
          title: 'Family Review — ${j.linkedSeekerName} & ${j.partner.firstName}',
          body: 'Both families decide whether this Journey continues. '
              'Your decision is waiting.',
          cta: 'Review',
          onTap: () => _openJourney(j),
        ));
      } else if (!j.isSuspended && j.journeyStage == 'wali_gate') {
        cards.add(_AttentionCard(
          title: '${j.linkedSeekerName}’s Journey — Guardian step',
          body: 'The Journey is waiting at the Guardian Gate. '
              'Only a Guardian can complete this step.',
          cta: 'Open',
          onTap: () => _openJourney(j),
        ));
      }
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    // Composed ONCE per build — these walk the ward list, and calling
    // them per row would recompose for every card drawn.
    final linked = _wards;
    final journeys = _visibleJourneys;
    final reviewIds = _reviewIds(journeys);
    final attention = _attentionCards(journeys, reviewIds);
    final dev = kReleaseMode ? null : ZyraDevScenario.instance;

    return Container(
      decoration: BoxDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Dashboard', style: ZyraText.heading(size: 26)),
            ),
            Expanded(
              // LOADING FIRST (DR-ZYRA-166), then the honest error, then
              // empty, then the hub.
              child: _loading
                  ? const ZyraLoading()
                  : _loadFailed && linked.isEmpty && journeys.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ZyraEmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: "Couldn't load your dashboard",
                            message: 'Check your connection.',
                            ctaLabel: 'Try again',
                            onCta: _retry,
                          ),
                        )
                      : linked.isEmpty
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: ZyraEmptyState(
                                icon: Icons.family_restroom_outlined,
                                message:
                                    'Once your Seeker joins and their journey begins, milestones will appear here.',
                                ctaLabel: 'Invite your Seeker',
                                onCta: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const WaliInviteSeekerScreen()),
                                ),
                              ),
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              children: [
                                if (_loadFailed)
                                  _ErrorBanner(onRetry: _retry),

                                // ── 1 · what needs the Guardian ──
                                Text('NEEDS YOUR ATTENTION',
                                    style: ZyraText.chapterLabel(
                                        color: Colors.white54)),
                                const SizedBox(height: 10),
                                if (attention.isEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                        'Nothing needs you right now.',
                                        style: ZyraText.subtext(
                                            size: 12.5,
                                            color: Colors.white
                                                .withValues(alpha: 0.5))),
                                  )
                                else
                                  ...attention,

                                // ── 2-4 · the Seekers, their Journeys,
                                //          their activity ──
                                const SizedBox(height: 18),
                                Text('YOUR SEEKERS',
                                    style: ZyraText.chapterLabel(
                                        color: Colors.white54)),
                                const SizedBox(height: 10),
                                for (final person in linked)
                                  _wardCard(person, journeys, reviewIds, dev),

                                // ── 5 · what changed recently ──
                                if (_recent.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  Text('RECENTLY',
                                      style: ZyraText.chapterLabel(
                                          color: Colors.white54)),
                                  const SizedBox(height: 10),
                                  for (final r in _recent)
                                    _RecentRow(
                                      title:
                                          '${r.j.linkedSeekerName} & ${r.j.partner.firstName}',
                                      label: _milestoneLabel(r.type),
                                      when: _ago(r.at),
                                      onTap: () => _openJourney(r.j),
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

  Widget _wardCard(WaliLinkedPerson person, List<WaliJourneyView> journeys,
      Set<String> reviewIds, ZyraDevScenario? dev) {
    final wardJourneys =
        journeys.where((j) => j.linkedSeekerId == person.id).toList();
    // The card leads with the LIVE Journey when one exists; ended ones
    // stay in the chips.
    final live = wardJourneys
        .where((j) => j.status != 'ended')
        .toList();
    final j = live.isEmpty ? null : live.first;

    final String statusLine;
    int? stageOrder;
    if (j == null) {
      statusLine = 'No Journey yet';
    } else {
      statusLine =
          'Journey with ${j.partner.firstName} — ${_statusLabel(j, reviewIds)}';
      if (!j.isSuspended && j.status == 'active') {
        stageOrder = ZyraJourneyStages.of(j.journeyStage)?.order;
      }
    }

    final active =
        wardJourneys.where((x) => x.status == 'active' && !x.isSuspended).length;
    final paused = wardJourneys.where((x) => x.isSuspended).length;
    final ended = wardJourneys.where((x) => x.status == 'ended').length;

    final chips = <Widget>[
      if (active > 0) ZyraWardChip(label: 'Active', count: active),
      if (paused > 0) ZyraWardChip(label: 'Paused', count: paused),
      if (ended > 0) ZyraWardChip(label: 'Ended', count: ended),
      // Browse-activity chips: STAGED ONLY (see the header's honesty
      // note) — the panel's counts, never a real-account claim.
      if (dev != null && dev.wardSaved > 0)
        ZyraWardChip(label: 'Saved', count: dev.wardSaved),
      if (dev != null && dev.wardConsidered > 0)
        ZyraWardChip(label: 'Considering', count: dev.wardConsidered),
      if (dev != null && dev.wardDeclined > 0)
        ZyraWardChip(label: 'Declined', count: dev.wardDeclined),
    ];

    final needsAttention = wardJourneys.any((x) =>
        reviewIds.contains(x.matchId) ||
        (!x.isSuspended &&
            x.status == 'active' &&
            x.journeyStage == 'wali_gate'));

    return ZyraWardCard(
      name: person.firstName,
      photoUrl: _wardPhotos[person.id] ?? '',
      statusLine: statusLine,
      detailLine: person.isMain
          ? 'You are their Main Guardian'
          : 'Additional Guardian',
      stageOrder: stageOrder,
      stageCount: ZyraJourneyStages.count,
      needsAttention: needsAttention,
      chips: chips,
      onTap: j == null ? null : () => _openJourney(j),
    );
  }
}

/// One thing waiting on the Guardian — the accent surface the Family
/// Review badge already used, grown into a card with a verb.
class _AttentionCard extends StatelessWidget {
  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;
  const _AttentionCard(
      {required this.title,
      required this.body,
      required this.cta,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ZyraColors.accentBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ZyraColors.accentBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: ZyraText.body(size: 13.5, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(body, style: ZyraText.subtext(size: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(cta,
                    style:
                        ZyraText.body(size: 12.5, color: Colors.white)),
                const Icon(Icons.chevron_right,
                    color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet recency row — fact, then when. Taps through to the Journey.
class _RecentRow extends StatelessWidget {
  final String title;
  final String label;
  final String when;
  final VoidCallback onTap;
  const _RecentRow(
      {required this.title,
      required this.label,
      required this.when,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(Icons.circle,
                size: 5, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('$title — $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.subtext(size: 12.5, color: Colors.white70)),
            ),
            Text(when,
                style: ZyraText.subtext(
                    size: 11, color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

/// The stale-but-shown state: rows render, the truth about the refresh
/// failing is said out loud. DR-ZYRA-167's rule on this screen.
class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 15, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text("Couldn't refresh — showing what was loaded.",
                  style: ZyraText.subtext(size: 11.5)),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text('Try again',
                  style: ZyraText.body(size: 12, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
