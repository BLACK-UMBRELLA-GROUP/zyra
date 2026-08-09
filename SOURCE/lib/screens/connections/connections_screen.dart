// Connections tab — per APP/Navigation/SEEKER NAVIGATION/Summary.md's
// CONNECTIONS section: "Relationship Journey = Save → Consider → Match
// → Conversation → Family Stage." Matches is NOT a conversation inbox
// (MATCH_UX_SPEC_CURRENT_VERSION_V1.md) — it houses Potential Journeys,
// with Active/Paused Journeys below leading into the Pre-Journey Ritual
// (JourneyFlowScreen) rather than straight to Chat.
//
// 2026-07-29 (Founder review — Connections-page redesign, Option 1 of 5
// presented in chat, chosen as-is): replaced the old flat
// MATCHES-then-everything layout with a two-panel "Journeys / Activity"
// segmented toggle (_SegmentedToggle, below).
//
// REVISED 2026-08-01 (Founder, screenshot review). Current layout:
//
//   Journeys   Active → Potential → Paused → Ended
//   Activity   Family Introductions → Considered → Saved → Passed
//
// Three changes and the reasoning, since the previous order was itself a
// deliberate decision and the comment describing it is now wrong:
//
//   1. POTENTIAL now precedes PAUSED. Potential Journeys are waiting on
//      you and are the most likely next action; Paused ones are, by
//      definition, not moving. Ordering by how live something is beats
//      ordering by lifecycle position.
//   2. ACTIVE JOURNEY is emphasised — full-white label, brighter card,
//      larger photo. Every header used to be identical white54, so the
//      one Journey you are actually in looked like everything else.
//   3. FAMILY INTRODUCTIONS moved to the top of Activity. It was placed
//      in Journeys on 2026-07-29 on the reasoning that a Family Stage is
//      part of a Journey's lifecycle. The Founder's read is better: the
//      Journeys tab answers "where are my Journeys up to" and every
//      other row there opens a Journey. An introduction between two
//      families is something that happened and wants attention — which
//      is Activity's job — and it outranks a bookmark, so it goes first.
//
// Activity rows are now _ActivityCard (expand on tap, with Unlock and
// Report). Journeys rows remain _JourneyTile.
// See _journeysChildren()/_activityChildren() for the two panels.
//
// 2026-07-26 (DR-ZYRA-101 audit, nav bar fix — see SEEKER NAVIGATION
// Summary.md's own flagged inconsistency: live Seeker nav had only 3
// tabs, Browse/Matches/Profile, with no Connections or Guardian tab at
// all). This screen used to be MatchesScreen (screens/matches/
// matches_screen.dart) and only covered the Matches section. Renamed
// and expanded to also surface Passed/Saved/Considered — reusing
// AppState.declined/saved/outgoingLikes exactly as profile_screen.dart
// already did for its own (now-superseded) connections counters — and
// a placeholder Family Introductions section, since the Guardian-side
// Family Stage answering UI is a known, deliberately unbuilt gap (see
// the Founder handover's "Immediate Next Steps" item 1) rather than
// something to fake here.
//
// 2026-07-25 (DR-ZYRA-101 audit): Matches section rewritten against
// real matches.status ('potential'/'active'/'ended') instead
// of the old client-only stand-in. "Start Journey" now calls
// ZyraJourneyService.promoteToActive (a real RPC enforcing
// one-Active-Journey-at-a-time), and both journey lists are re-fetched
// from the backend rather than mutated locally. A PAUSED JOURNEYS
// section surfaces paused journeys (Journey Suspension,
// JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md) with Resume/End actions.

import 'dart:ui';
import '../../widgets/zyra_profile_image.dart';

import 'package:flutter/material.dart';
import '../../data/zyra_journey_stages.dart';
import '../../models/journey_match.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_guardian_suggestion_service.dart';
import '../../services/zyra_journey_service.dart';
import '../../services/zyra_report_service.dart';
import '../../services/zyra_unlock_service.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/report_profile_sheet.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../journey/journey_flow_screen.dart';
import '../subscription/profile_unlock_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  /// Switches the shell to the Browse tab. Used by "View profile" on a
  /// Guardian Suggestion — this screen can't change tabs itself.
  final VoidCallback? onNavigateToBrowse;

  const ConnectionsScreen({super.key, this.onNavigateToBrowse});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  // Suspended journeys (JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md): these
  // are NOT a separate matches.status — per that spec's own §1.1
  // "Architectural Framing", suspension is a behavioural sub-state of
  // Active Journey, not a lifecycle transition. So a suspended journey
  // still has status='active'; it's identified by suspended_by being
  // non-null. Split out of `active` here for display purposes only.
  List<JourneyMatch> _suspended = [];
  // #17 — "Match remains visible in Matched list (greyed, at bottom)"
  // after End Journey (APP/Journey/JOURNEY AVAILABILITY/Summary.md).
  // Wasn't fetched/displayed at all before this pass — without this,
  // the Restart button built in journey_flow_screen.dart's _EndedView
  // would be unreachable once a user navigated away.
  List<JourneyMatch> _ended = [];

  /// Match IDs among the Active list that have a Family Review open.
  ///
  /// Drives the one override in the stage map — see
  /// ZyraJourneyStages.familyReviewOverride. Fetched as a SET in one
  /// batched query in [_refresh]; a per-card fetchFamilyReview would be
  /// N+1, which is why ZyraJourneyService.fetchOpenReviewMatchIds exists.
  ///
  /// Empty until that query returns, and empty forever if it fails. Both
  /// show the underlying stage, which is honest — the Journey really is
  /// in phase_2; the override only adds why it isn't moving.
  Set<String> _openReviews = const {};

  bool _startingJourney = false;
  String? _startingMatchId;
  /// Drives the Journeys/Activity pager. The toggle animates it; swiping
  /// moves it directly.
  ///
  /// REPLACED `bool _showActivity` on 2026-08-03. That flag recorded which
  /// panel had SETTLED, which was enough while the toggle only had two
  /// states — but the pill now follows the swipe continuously, so the
  /// question stopped being "which page" and became "how far between
  /// them". `_pagerPos` answers both: 0, 1, or anything in between.
  ///
  /// Leaving the bool in place would have been a second, coarser source of
  /// truth for the same thing. The analyzer caught it as write-only.
  final PageController _pager = PageController();

  /// The pager's live position, 0.0 (Journeys) to 1.0 (Activity), updated
  /// on every frame of a drag so the toggle pill can track it.
  ///
  /// Read from the controller rather than kept in sync by hand — a second
  /// source of truth for "where is the pager" is exactly how the pill and
  /// the page would end up disagreeing.
  double _pagerPos = 0;

  /// Introductions. Named rather than a bare `2` because the arrival hook
  /// below depends on it and a fourth segment would silently break it.
  static const int _kIntroductionsIndex = 2;

  /// Guards the mark-seen write so it fires once per arrival, not once per
  /// frame — `_onPagerScroll` runs on every tick of the animation.
  bool _markingSeen = false;

  /// A dev toggle moved. Re-fetch, because the fakes are substituted at the
  /// fetch and a rebuild alone would show the same stale list.
  void _onScenarioChange() {
    if (mounted) _refresh();
  }

  void _onPagerScroll() {
    if (!_pager.hasClients || _pager.page == null) return;
    // Upper bound was 1.0 — three segments now.
    final p = _pager.page!.clamp(0.0, (_kSegmentLabels.length - 1).toDouble());
    if ((p - _pagerPos).abs() < 0.001) return;
    setState(() => _pagerPos = p);
    // Settled on Introductions — the arrival that discharges the alert.
    if (p == _kIntroductionsIndex.toDouble()) _markIntroductionsSeen();
  }

  /// Stamps the unseen introductions as seen, then rebuilds so the dot goes.
  ///
  /// Deliberately does NOT re-fetch. The list must not reorder or reload
  /// under someone who has just arrived to read it; only the badge changes.
  Future<void> _markIntroductionsSeen() async {
    if (_markingSeen) return;
    if (!_undecidedSuggestions.any((s) => s.unseen)) return;
    _markingSeen = true;
    final changed = await ZyraGuardianSuggestionService.markSeen();
    if (!mounted) {
      _markingSeen = false;
      return;
    }
    if (changed) {
      setState(() {
        _suggestions = [
          for (final s in _suggestions)
            GuardianSuggestion(
              profile: s.profile,
              suggestedBy: s.suggestedBy,
              unseen: false,
            ),
        ];
      });
    }
    _markingSeen = false;
  }

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    // ADDED 2026-08-06. The Journey toggles wrote to ZyraDevScenario and
    // nothing on this screen was listening, so `_refresh()` never re-ran and
    // no fake Journeys ever appeared — the toggles moved and did nothing,
    // which is the exact failure the panel's own header warns about.
    //
    // A full `_refresh()` rather than a `setState`, because the fakes are
    // substituted where the fetch happens; rebuilding alone would redraw the
    // same stale list.
    ZyraDevScenario.instance.addListener(_onScenarioChange);
    _pager.addListener(_onPagerScroll);
    _refresh();
    _loadSuggestions();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    ZyraDevScenario.instance.removeListener(_onScenarioChange);
    _pager.removeListener(_onPagerScroll);
    _pager.dispose();
    super.dispose();
  }

  /// Guardian Suggestions for this Seeker. Loaded alongside the Journeys
  /// refresh and re-loaded whenever AppState.suggestionsVersion moves.
  List<GuardianSuggestion> _suggestions = const [];
  int _suggestionsVersion = AppState.instance.suggestionsVersion;

  void _onChange() {
    final v = AppState.instance.suggestionsVersion;
    if (v != _suggestionsVersion) {
      _suggestionsVersion = v;
      _loadSuggestions();
    }
    setState(() {});
  }

  Future<void> _loadSuggestions() async {
    final s = await ZyraGuardianSuggestionService.fetchPending();
    if (!mounted) return;
    setState(() => _suggestions = s);
    // Publish app-wide so Browse can mark a suggested profile in the deck,
    // and so the mark survives into Considered/Saved/Passed after a
    // decision (Founder, 2026-08-05).
    AppState.instance.setGuardianSuggestedBy({
      for (final x in s) x.profile.id: x.suggestedBy,
    });
    // A suggestion can arrive while the Seeker is already sitting on
    // Introductions. They have arrived; the alert has nothing left to tell
    // them, so it is discharged here too rather than waiting for them to
    // navigate away and back to earn it.
    if (_pagerPos == _kIntroductionsIndex.toDouble()) _markIntroductionsSeen();
  }

  /// Suggestions still awaiting a look. Once you Consider, Save or Pass
  /// someone they leave this section and appear in that list instead —
  /// still marked as suggested, so the Guardian's involvement isn't lost,
  /// but not listed twice as though nothing had happened.
  /// Outstanding user action per segment, in page order.
  ///
  /// `APP/Standards/BADGE_STANDARD_CURRENT_VERSION_V1.md`, Founder 2026-08-06:
  ///
  ///   "A badge represents outstanding user action. It does not simply
  ///    indicate that something happened."
  ///
  /// Every entry below answers one question: **is the user expected to do
  /// something?**
  ///
  /// THE REASON THIS IS A GETTER AND NOT A STORED COUNT. Outstanding action
  /// is STATE, not history. The earlier framing — "what changed since you
  /// last looked" — would have needed a `last_seen_at` per user per
  /// surface, because history needs a bookmark. Derived from current state
  /// it needs no schema at all, and it cannot drift out of sync with the
  /// thing it counts, because it IS the thing it counts.
  List<int> get _segmentBadges => [
        // JOURNEYS — only where the Journey is waiting on the user.
        //
        // A Potential Journey is a mutual like nobody has opened yet: it
        // sits there until this user promotes or declines it. That is
        // outstanding action by definition.
        //
        // NOT badged, per the standard: automatic stage progression (the
        // platform moved it, not you), the user's own actions (they were
        // there), informational milestones.
        //
        // NOT YET COUNTED, and each needs work rather than a decision:
        //   Family Review awaiting YOUR decision — needs the review's
        //     pending state surfaced on this screen; it currently lives in
        //     journey_flow_screen.
        //   The other party ended the Journey — needs an `acknowledged`
        //     boolean on the attempt. NOT an exception to "outstanding
        //     action is state": the badge represents "you have an unread
        //     Journey outcome", which is a standing condition, structurally
        //     the same as an unresolved introduction. A per-item flag, not
        //     a last_seen_at bookmark.
        //   The other party requested a new Journey — OA-ZYRA-159, unbuilt.
        AppState.instance.potentialJourneys.length,

        // ACTIVITY — permanently zero, and correct.
        //
        // Considered, Saved and Passed are records of the user's OWN
        // decisions. Not an inbox; nothing arrives unbidden. Founder
        // 2026-08-06: "If Activity never has a badge, that's perfectly
        // fine. Not every surface needs one."
        //
        // The one candidate — a saved profile becoming unavailable — is a
        // loss the user can do nothing about, so it fails the rule.
        0,

        // INTRODUCTIONS — a Guardian has put someone forward and the
        // Seeker has a decision to make.
        //
        // FIXED 2026-08-06 (Founder: "when I went off the page it was still
        // there. It only left after I made a choice with each user on the
        // page, but it should go once the user lands on the page").
        //
        // This counted `_undecidedSuggestions.length` — the UNRESOLVED
        // count — and the comment here confidently explained why that was
        // right. It was right against the ORIGINAL rule. The Founder amended
        // the Badge Standard the same day and this code was never brought
        // along, so the dot nagged for days about a list already read.
        //
        //   badge      = UNSEEN     clears on arrival   <- this
        //   list count = UNRESOLVED clears on resolution <- the heading
        //
        // The badge is the alert; the list is the work. Arriving discharges
        // the alert, and the heading goes on saying the work is there.
        _undecidedSuggestions.where((s) => s.unseen).length,
      ];

  // NAV BAR AGGREGATION IS NOT WIRED HERE, deliberately.
  //
  // The standard requires the Connections tab to show the SUM of these and
  // to land on the highest-priority segment with unresolved work. Both
  // numbers would have to travel UP to HomeShell, which owns the nav bar —
  // and reaching into this State from there (a GlobalKey, or lifting the
  // whole screen's state) would couple the nav bar to whether this screen
  // happens to be built.
  //
  // The right home is AppState, which already holds potentialJourneys and
  // drives suggestionsVersion. Both counts derive from it, so HomeShell can
  // read them whether or not Connections has ever been opened — which it
  // must, since the badge's whole job is to make you open it.
  //
  // Left as a stated next step rather than a stub: an unused getter here
  // would be dead code pointing at the wrong architecture.

  List<GuardianSuggestion> get _undecidedSuggestions {
    final app = AppState.instance;
    final decided = <String>{
      ...app.declined.map((p) => p.id),
      ...app.saved.map((p) => p.id),
      ...app.outgoingLikes.map((p) => p.id),
    };
    return _suggestions.where((s) => !decided.contains(s.profile.id)).toList();
  }

  Future<void> _refresh() async {
    // Dev panel overrides the whole set when any Journey toggle is on.
    // ADDED 2026-08-06. Substituted at the SOURCE rather than merged in
    // further down, so every derived list below — potential, active,
    // suspended, ended — comes from one place and cannot disagree about
    // which Journey is which.
    // Dev Journeys wrap REAL profiles, so the cards render real photos.
    // Synthesised people had empty photo lists, which drew as a white tile.
    final all = ZyraDevScenario.instance.journeysOverridden
        ? ZyraDevScenario.fakeJourneys(
            viewerGender: AppState.instance.gender,
            pool: await ZyraDiscoveryService.fetchCandidates(),
          )
        : await ZyraJourneyService.fetchJourneyMatches(
            statuses: const ['potential', 'active', 'ended']);
    if (!mounted) return;
    final potential = all.where((j) => j.status == 'potential').toList();
    final activeAll = all.where((j) => j.status == 'active').toList();
    final active = activeAll.where((j) => !j.isSuspended).toList();
    final suspended = activeAll.where((j) => j.isSuspended).toList();
    final ended = all.where((j) => j.status == 'ended').toList()
      ..sort((a, b) => (b.endedAt ?? DateTime(0)).compareTo(a.endedAt ?? DateTime(0)));
    AppState.instance.setJourneyMatches(potential: potential, active: active);

    // ONE query for the whole Active list, and only the Active list:
    // a Potential Journey has no stage to override, and an Ended one has
    // no live review by definition.
    //
    // Placed AFTER setJourneyMatches so the extra round-trip delays only
    // this screen's own setState, not the app-wide Journey state that the
    // rest of the shell reads.
    //
    // Dev fakes are skipped rather than queried: their match IDs are not
    // real rows, and Postgres would reject them against a uuid column
    // (22P02) to tell us something we already know.
    final openReviews = ZyraDevScenario.instance.journeysOverridden
        ? const <String>{}
        : await ZyraJourneyService.fetchOpenReviewMatchIds(
            active.map((j) => j.matchId).toList());
    if (!mounted) return;

    setState(() {
      _suspended = suspended;
      _ended = ended;
      _openReviews = openReviews;
    });
  }

  void _startJourney(JourneyMatch j) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Start Journey with ${j.profile.firstName}?', style: ZyraText.heading(size: 16)),
        // DISCLOSURE ADDED 2026-08-01 (Founder decision, via ChatGPT:
        // Guardian conversation visibility is deliberate and must be stated
        // consistently everywhere).
        //
        // THIS IS THE MOMENT IT MATTERS. messages_select's RLS grants a
        // linked Wali read access from the instant matches.status leaves
        // 'potential' — which is exactly what this button does. Before
        // today the user tapped it with no idea, and the app elsewhere
        // actively told them the opposite. This dialog is the last point
        // at which the choice is still theirs, so the disclosure belongs
        // here rather than only in the FAQ.
        //
        // "and ${firstName}'s" is not a courtesy — the policy grants
        // access to a Wali linked to EITHER seeker, so the other party's
        // Guardian reads this conversation too. Saying only "your Guardian" would
        // be a second, subtler untruth.
        content: Text(
          'This starts your Active Journey. It will use your Journey slot and '
          'begin the Pre-Journey Ritual with Compatibility Reveal.\n\n'
          'From this point your linked Guardian — and ${j.profile.firstName}\'s — '
          'can read the conversation between you. That is deliberate: ZYRA is '
          'built for a marriage process with family present, not for private '
          'one-to-one messaging.\n\n'
          'You may only have one Active Journey at a time.',
          style: ZyraText.subtext(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Not yet', style: ZyraText.subtext(size: 13))),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _promote(j);
            },
            child: Text('Start Journey', style: ZyraText.button(size: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _promote(JourneyMatch j) async {
    setState(() {
      _startingJourney = true;
      _startingMatchId = j.matchId;
    });
    try {
      final ok = await ZyraJourneyService.promoteToActive(j.matchId);
      await _refresh();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
        ));
      }
    } on OneActiveJourneyLimitException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You already have an Active Journey. End or pause it before starting another.'),
      ));
    } finally {
      if (mounted) setState(() => _startingJourney = false);
    }
  }

  Future<void> _resumeSuspended(JourneyMatch j) async {
    try {
      await ZyraJourneyService.resumeJourney(j.matchId);
      await _refresh();
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
      ));
    } on OtherPartyInActiveJourneyException {
      // OA-ZYRA-164, DR-ZYRA-121 item 12. The old copy — "it has now
      // ended" — was accurate at the time: the server really did end the
      // Journey underneath the person pressing Resume. It no longer does,
      // so the message must not imply a loss that has not happened.
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "They're in another Journey right now, so this one stays paused. "
          "Nothing has been lost. You can resume when they're ready.",
        ),
      ));
    }
  }

  Future<void> _endSuspended(JourneyMatch j) async {
    await ZyraJourneyService.endJourney(j.matchId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final potential = AppState.instance.potentialJourneys;
    final active = AppState.instance.activeJourneys;
    final passed = AppState.instance.declined;
    final saved = AppState.instance.saved;
    final considered = AppState.instance.outgoingLikes;

    return Container(
      // 2026-07-25: gender-matched gradient (DR-ZYRA-094), widened from
      // Profile-only to all in-app post-onboarding screens per Founder
      // instruction — see ZyraColors.genderGradient() doc comment.
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Connections', style: ZyraText.heading(size: 22)),
            ),
            // 2026-07-29 (Founder review — Connections-page redesign,
            // Option 1 of 5 presented): Journeys/Activity segmented
            // toggle replaces the old flat MATCHES-then-everything
            // layout, and the old "Incoming Potentials — ZYRA One" tease
            // that used to sit here stays removed (DR-ZYRA-119).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              // 2026-08-03 (Founder: "as I swipe left to right you can
              // see the app moving in motion — can you make the top tab
              // move in motion with it also").
              //
              // `_pagerPos` is the pager's live fractional offset, not the
              // settled page. At 0.4 through a swipe the pill sits 40% of
              // the way across, so the control follows the finger instead
              // of snapping once the gesture ends.
              child: _SegmentedToggle(
                position: _pagerPos,
                badges: _segmentBadges,
                onChanged: (i) => _pager.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
            // SWIPEABLE 2026-08-01 (Founder: "allow the UI when I swipe
            // left and right to move between Journeys and Activity").
            //
            // Was a plain ListView swapping its children when the toggle
            // changed — the toggle was the only way across. A two-page
            // PageView keeps the toggle working AND makes the horizontal
            // swipe do the obvious thing, with the pill tracking whichever
            // one you used.
            //
            // Both pages stay built, so scroll position in each survives
            // switching between them. That matters here: Activity can be
            // long, and losing your place every time you glanced at
            // Journeys would be worse than the missing gesture.
            Expanded(
              child: PageView(
                controller: _pager,
                // No onPageChanged — _onPagerScroll already tracks
                // position on every frame, including the settle at the
                // end of a swipe. A second callback writing a second
                // field is what created the unused one.
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: _journeysChildren(active: active, potential: potential),
                  ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: _activityChildren(considered: considered, saved: saved, passed: passed),
                  ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: _introductionsChildren(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _journeysChildren({required List<JourneyMatch> active, required List<JourneyMatch> potential}) {
    return [
      // ACTIVE JOURNEY — 2026-08-01 (Founder: "active journey should be
      // more stand out then the rest").
      //
      // Every section header on this page was identical white54 chapter
      // label, so the one Journey a Seeker is actually IN looked exactly
      // like the list of people who haven't replied. ZYRA allows one
      // Active Journey at a time — it is the single most important thing
      // on the screen and should not have to be searched for.
      //
      // Emphasis is carried by the label (full white, not white54) and by
      // the card itself (`emphasised: true` below — brighter fill, real
      // border, larger photo), NOT by a new accent colour. Introducing
      // one here would collide with the gender gradient behind it.
      Text('ACTIVE JOURNEY', style: ZyraText.chapterLabel(color: Colors.white)),
      const SizedBox(height: 8),
      if (active.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraEmptyState(
            icon: Icons.forum_outlined,
            message: 'Your Active Journey will appear here.',
          ),
        )
      else
        ...active.map((j) => _JourneyTile(
              profile: j.profile,
              // THE CANONICAL STAGE MAP — data/zyra_journey_stages.dart,
              // Founder-approved 2026-08-09. No stage label is written
              // here or on any other screen; there is one map.
              //
              // REPLACED: `journeyStage == 'conversation' ? 'Conversation
              // open' : 'In the Pre-Journey Ritual'`. That was wrong for
              // seven of the eight stages, and not vaguely wrong —
              // the Pre-Journey Ritual is what turns a POTENTIAL Journey
              // into this one. Every stage in this list runs after it.
              // A Seeker in Family Compatibility was being told they were
              // still in the ritual they finished weeks earlier.
              //
              // No "Current Focus:" prefix here, per the Founder: on a
              // card the label is obviously the state. The prefix is for
              // Journey Detail, where it has to compete with the content.
              subtitle: ZyraJourneyStages.labelFor(
                j.journeyStage,
                reviewOpen: _openReviews.contains(j.matchId),
              ),
              emphasised: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
              )),
            )),

      const SizedBox(height: 20),
      // RENAMED 2026-08-03, Founder approved: "Potential Journeys"
      // suggested uncertainty, when these are confirmed mutual likes
      // waiting for the user to begin. "Queue" also carries the
      // one-Active-Journey-at-a-time rule without stating it — things in
      // a queue are waiting their turn by definition.
      Text('POTENTIAL JOURNEYS', style: ZyraText.chapterLabel(color: Colors.white54)),
      const SizedBox(height: 8),
      if (potential.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          // 2026-07-26: check_circle_outline replaced favorite_border
          // (Founder: app-wide heart-icon removal).
          //
          // CHANGED AGAIN 2026-08-01 (Founder: "the Considered icon
          // should be a tick, which means the Potential Journey icon
          // needs to change"). Correct — Considered has the stronger
          // claim on a tick, and two ticks on one screen meaning
          // different things is worse than either choice alone.
          //
          // compare_arrows reads as two people having moved toward each
          // other, which is precisely what a mutual Consider is. Not a
          // heart, per the app-wide rule.
          child: ZyraEmptyState(
            icon: Icons.compare_arrows,
            message: 'People you and another Seeker have both liked will '
                'appear here, ready for you to start a Journey.',
          ),
        )
      else
        ...potential.map((j) => _JourneyTile(
              profile: j.profile,
              subtitle: 'Ready to start',
              trailingLabel: _startingJourney && _startingMatchId == j.matchId ? 'Starting…' : 'Start Journey',
              onTrailingTap: _startingJourney ? null : () => _startJourney(j),
            )),

      // PAUSED JOURNEYS — 2026-07-29: renamed from "Suspended" (matches
      // the Journey Pause naming used everywhere else, DR-ZYRA-119) and
      // now ALWAYS rendered with its own empty state instead of only
      // appearing once non-empty, so the section is actually
      // discoverable (Founder, Connections review). Basic Seekers can
      // still land here as the non-initiating party of a Journey a ZYRA
      // One partner paused (JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md) —
      // this isn't ZYRA-One-only data, so no tier gate on the section.
      const SizedBox(height: 20),
      Text('PAUSED JOURNEYS', style: ZyraText.chapterLabel(color: Colors.white54)),
      const SizedBox(height: 8),
      if (_suspended.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraEmptyState(
            icon: Icons.pause_circle_outlined,
            message: 'Journeys that have been paused appear here.',
          ),
        )
      else
        ..._suspended.map((j) {
          // Only the Seeker who initiated suspension may resume
          // (JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md §12.1). If the
          // OTHER party suspended it, this Seeker is in the
          // Peer-Suspended state and can only wait or End.
          final iInitiated = j.suspendedBy == ZyraAuth.currentUser?.id;
          return _JourneyTile(
            profile: j.profile,
            subtitle: iInitiated ? 'Paused by you' : 'Paused by them — waiting',
            trailingLabel: iInitiated ? 'Resume' : null,
            onTrailingTap: iInitiated ? () => _resumeSuspended(j) : null,
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1A1220),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text('Paused with ${j.profile.firstName}', style: ZyraText.heading(size: 16)),
                content: Text(
                  iInitiated
                      ? 'This Journey is currently paused. Resume to continue where you left off, or End it permanently.'
                      : "${j.profile.firstName} paused this Journey. You can wait for them to resume, or End it permanently — you can't resume it yourself.",
                  style: ZyraText.subtext(),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Close', style: ZyraText.subtext(size: 13))),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _endSuspended(j);
                    },
                    child: Text('End Journey', style: ZyraText.button(size: 13, color: const Color(0xFFE08080))),
                  ),
                  if (iInitiated)
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _resumeSuspended(j);
                      },
                      child: Text('Resume', style: ZyraText.button(size: 13)),
                    ),
                ],
              ),
            ),
          );
        }),

      // ENDED JOURNEYS — 2026-08-03, Founder approved.
      //
      // Was a conditional block that only appeared once something had
      // ended, which meant the section did not exist for anyone who had
      // not yet ended a Journey — so nobody could learn it was there.
      // Now always rendered with its own empty state, matching how Paused
      // Journeys was fixed on 2026-07-29 for the same reason.
      //
      // Founder's stated purpose: "gives users closure instead of a
      // Journey disappearing". A Journey that vanishes on ending is the
      // app quietly deciding something is over; a Journey that moves to a
      // section named Ended is the app acknowledging it.
      //
      // Greyed (#17, JOURNEY AVAILABILITY/Summary.md). Tapping opens
      // JourneyFlowScreen, which shows the 24h cooling countdown or the
      // Restart button once elapsed.
      const SizedBox(height: 20),
      Text('ENDED JOURNEYS', style: ZyraText.chapterLabel(color: Colors.white54)),
      const SizedBox(height: 8),
      if (_ended.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraEmptyState(
            icon: Icons.history,
            message: 'Journeys that have ended appear here.',
          ),
        )
      else
        ..._ended.map((j) => _JourneyTile(
              profile: j.profile,
              subtitle: j.canRestart ? 'Ended — Restart available' : 'Ended — ${j.restartAvailableIn.toLowerCase()}',
              dimmed: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
              )),
            )),
    ];
  }

  /// INTRODUCTIONS — its own page, 2026-08-06.
  ///
  /// Founder chose this over moving it to the Guardian tab. The deciding
  /// question was whose task it is: an introduction is an INBOUND item
  /// waiting on the Seeker. Filing it under Guardian would sort it by who
  /// sent it rather than by what you need to do — and the Guardian tab is
  /// somewhere you visit a handful of times ever, where Connections is
  /// daily.
  ///
  /// ============ A NAMING COLLISION, REINSTATED DELIBERATELY ============
  ///
  /// "Introductions" was REJECTED for this feature on 2026-08-05, because
  /// "Family Introductions" already names the Family Stage of an ACTIVE
  /// Journey — two families being introduced to each other. Sitting above
  /// Considered and Saved, it read as though a match had already happened
  /// and progressed that far.
  ///
  /// The Founder has now chosen it anyway (2026-08-06), and the collision
  /// is real but smaller than it was: this is no longer inside Activity
  /// pretending to be a decision you made, it is its own segment. The word
  /// is also the right one culturally — a Guardian putting someone forward
  /// IS an introduction in the sense this community means it.
  ///
  /// RAISED, NOT WORKED AROUND. If the two ever need separating, rename
  /// the Family Stage rather than this — it has the qualifier available
  /// ("Family Introductions") and this does not.
  List<Widget> _introductionsChildren() {
    final pending = _undecidedSuggestions;
    return [
      Text(
        pending.isEmpty ? 'INTRODUCTIONS' : 'INTRODUCTIONS (${pending.length})',
        style: ZyraText.chapterLabel(color: Colors.white54),
      ),
      const SizedBox(height: 4),
      Text(
        'People your Guardian has introduced to you.',
        style: ZyraText.subtext(size: 11.5, color: Colors.white38),
      ),
      const SizedBox(height: 14),
      if (pending.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: ZyraEmptyState(
            icon: Icons.groups_outlined,
            // Honest. There is still no Guardian-side UI to create one, so
            // this list is empty in practice, not just in a new account.
            message: "When a Guardian suggests someone, they'll appear here.",
          ),
        )
      else
        // Pass/Save/Consider are deliberately NOT offered. You have not
        // seen this person yet, and deciding from a thumbnail is exactly
        // what ZYRA is not.
        ...pending.map((s) => _SuggestionCard(
              suggestion: s,
              onViewProfile: () {
                AppState.instance.requestBrowseProfile(s.profile);
                widget.onNavigateToBrowse?.call();
              },
            )),
    ];
  }

  List<Widget> _activityChildren({
    required List<SeekerProfile> considered,
    required List<SeekerProfile> saved,
    required List<SeekerProfile> passed,
  }) {
    return [
      // CONSIDERED — outgoing Likes (renamed per DR-ZYRA-099 /
      // OA-ZYRA-138; underlying AppState field name unchanged).
      const SizedBox(height: 28),
      Text('CONSIDERED (${considered.length})', style: ZyraText.chapterLabel(color: Colors.white54)),
      const SizedBox(height: 10),
      if (considered.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          // CHANGED 2026-08-01 (Founder: "the Considered icon should be a
          // tick"). Was pending_outlined (a "…" circle). The tick had to
          // be freed up first — Potential Journeys was using it, and now
          // uses converging arrows instead.
          child: ZyraEmptyState(
            icon: Icons.check_circle_outline,
            message: "Profiles you've Considered will appear here until they respond.",
          ),
        )
      else
        ...considered.map((p) => _ActivityCard(profile: p, kind: _ActivityKind.considered)),

      // SAVED.
      const SizedBox(height: 28),
      Text('SAVED (${saved.length})', style: ZyraText.chapterLabel(color: Colors.white54)),
      const SizedBox(height: 10),
      if (saved.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraEmptyState(
            icon: Icons.bookmark_border,
            message: "Profiles you've Saved appear here.",
          ),
        )
      else
        ...saved.map((p) => _ActivityCard(profile: p, kind: _ActivityKind.saved)),

      // PASSED — per PROFILE DECISION SYSTEM/Summary.md ("no record, no
      // notification"), this is a purely local, session-scoped list —
      // nothing is written to the backend for a Pass, so this list
      // resets on sign-out/account switch.
      //
      // CAPPED 2026-07-27 (Founder: "the decline button with shows in
      // connections tab shows a maximum of 10 people. the last 10 they
      // declined") — display-only cap, not tier-gated (applies the same
      // to Basic and ZYRA One). `declined` is append-only (AppState.
      // decline() only ever adds), so the last 10 by list position ARE
      // the 10 most recently Passed.
      const SizedBox(height: 28),
      Builder(builder: (context) {
        final recentPassed = passed.length > 10 ? passed.sublist(passed.length - 10) : passed;
        final label = passed.length > 10
            ? 'PASSED (${passed.length} — showing last 10)'
            : 'PASSED (${passed.length})';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: ZyraText.chapterLabel(color: Colors.white54)),
            const SizedBox(height: 10),
            if (recentPassed.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: ZyraEmptyState(
                  icon: Icons.close,
                  message: "Profiles you've Passed appear here during this session.",
                ),
              )
            else
              // Passed cards expand too, but get no Unlock buttons —
              // Profile Unlocks/Summary.md, Usage Rules: "Cannot be used
              // on passed profiles." Report stays available on all three.
              ...recentPassed.map((p) => _ActivityCard(profile: p, kind: _ActivityKind.passed)),
          ],
        );
      }),
    ];
  }
}

// 2026-07-29 (Founder review — Connections-page redesign, Option 1 of 5
// presented in chat): two-segment "Journeys / Activity" pill toggle.
//
// CHANGED 2026-08-01 (Founder: "when we choose Journey or Activity it's
// white but make it be the same as navigation bar please, transparent").
//
// Was a solid white fill with dark text — the only opaque surface on the
// screen, so it read as a different app's control sitting on ZYRA's
// gradient, and it fought the floating nav bar directly below it for
// attention.
//
// The values below are lifted from floating_nav_bar.dart rather than
// invented, so the two controls are literally the same material:
//
//   track     white 0.10, border white 0.18, blur 22   (the bar)
//   selected  white 0.28, border white 0.12            (the blob)
//
// If the nav bar's glass is ever retuned, retune this with it.
/// The three labels, in page order. Founder 2026-08-06.
///
/// "Introductions", NOT "Suggestions" — Founder's word. See the naming
/// conflict recorded at _IntroductionsPage: this label was previously
/// rejected for colliding with the Family Stage, and has been reinstated
/// deliberately.
const List<String> _kSegmentLabels = ['Journeys', 'Activity', 'Introductions'];

class _SegmentedToggle extends StatelessWidget {
  /// 0.0 = Journeys, 1.0 = Activity, 2.0 = Introductions, anything between
  /// = mid-swipe.
  final double position;

  /// Page index to move to.
  final ValueChanged<int> onChanged;

  /// Unseen count per segment, same order as [_kSegmentLabels]. 0 = no dot.
  final List<int> badges;

  const _SegmentedToggle({
    required this.position,
    required this.onChanged,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            // A SLIDING FILL, not two independently-tinted halves.
            //
            // The old version coloured whichever segment was selected,
            // which can only ever be one or the other — there is no way to
            // render "60% of the way across" with that approach. The
            // highlight is now one box positioned by `position`, which is
            // what lets it travel with the swipe.
            child: LayoutBuilder(
              builder: (context, c) {
                // Was `c.maxWidth / 2`. Three segments now, so the fill is
                // a third of the width and travels 0..2 rather than 0..1.
                final seg = c.maxWidth / _kSegmentLabels.length;
                return SizedBox(
                  height: 34,
                  child: Stack(
                    children: [
                      Positioned(
                        left: position * seg,
                        top: 0,
                        bottom: 0,
                        width: seg,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < _kSegmentLabels.length; i++)
                            Expanded(
                              child: _label(
                                _kSegmentLabels[i],
                                // Distance from this segment, clamped —
                                // so the label is fully lit at its own
                                // index and dims as the fill leaves it,
                                // in either direction. The old
                                // `1 - position` only worked for two.
                                (1 - (position - i).abs()).clamp(0.0, 1.0),
                                () => onChanged(i),
                                badges.length > i ? badges[i] : 0,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// `weight` runs 0..1 with the fill, so the labels brighten and dim
  /// continuously rather than swapping at the end of the gesture.
  ///
  /// Size dropped 13 -> 11.5 with the third segment. At 13pt "Introductions"
  /// does not fit a third of a 352pt screen minus padding and ellipsises,
  /// and a truncated label on a control this small reads as a bug.
  Widget _label(String text, double weight, VoidCallback onTap, int badge) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        // INLINE, not overlaid — 2026-08-06. The first version stacked a
        // numbered badge on top of the label at `right: -9`, and the
        // Founder's screenshot showed it sitting across the end of
        // "Introductions".
        //
        // It was not a positioning mistake so much as a space one: the word
        // nearly fills a third of the screen, so there is nowhere OUTSIDE
        // the text for a badge to go. Anything absolutely positioned lands
        // on the word.
        //
        // A dot laid out in the row instead of over it cannot collide with
        // anything, because the layout gives it its own space.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZyraText.button(
                  size: 11.5,
                  color: Colors.white.withValues(alpha: 0.45 + (0.55 * weight)),
                ),
              ),
            ),
            if (badge > 0) _UnseenDot(count: badge),
          ],
        ),
      ),
    );
  }
}

/// The unseen-work dot.
///
/// Founder chose this over a numbered badge, 2026-08-06.
///
/// NO NUMBER, deliberately — and it loses nothing. The page heading already
/// reads "INTRODUCTIONS (5)", so a count on the toggle was repeating what
/// you see the moment you arrive. The dot answers "is there anything here";
/// the heading answers "how much". Dropping the number is also what makes
/// it fit beside a thirteen-character label.
///
/// WHITE, not the lavender it started as. Founder: the blue "doesn't suit
/// the app". Correct — #CFC2EE is a cool lavender sitting on a warm rose
/// gradient, so it read as imported from somewhere else. White belongs to
/// both gender themes equally, which matters because this control appears
/// on the rose gradient and the royal-blue one.
///
/// Gold (#E8C978) was the alternative and was rejected on meaning, not
/// looks: ZYRA already uses gold for PREMIUM. If gold also meant
/// "notification" it would soon mean neither.
class _UnseenDot extends StatelessWidget {
  /// Not rendered. Carried for the screen reader, which cannot see a dot.
  final int count;
  const _UnseenDot({required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // A bare dot is invisible to VoiceOver, and the independent review
      // (2026-08-04) already found 2 Semantics widgets in 23,000 lines.
      // Not adding a third silent control.
      label: count == 1 ? '1 unseen' : '$count unseen',
      child: Padding(
        // Left gap separates it from the word; the bottom padding lifts it
        // to sit against the cap height like a superscript rather than
        // floating on the baseline.
        padding: const EdgeInsets.only(left: 4, bottom: 7),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

//  added 2026-08-05 with Guardian Suggestions. It behaves like
//  for actions (you can still Unlock or Report), but is its own
// kind so the card can never be mistaken for something you decided on
// yourself — you didn't; your Guardian did.
/// ONE CARD METRIC FOR THE WHOLE APP — 2026-08-05 (Founder: "look at how
/// the cards are different sizes. I kinda want all cards to be the same for
/// a cleaner UI, this includes the Wali cards on the Wali tab").
///
/// Every list row that shows a person — Guardian Suggestions, Considered,
/// Saved, Passed, and the Guardian cards on the Wali tab — now uses these
/// three numbers. They were previously chosen per-widget: 52pt thumbnails
/// here, 56×64 on suggestions, 44 and 36 on the Wali tab, with padding of
/// 12, 13 and 16. Nothing was wrong individually; together they read as
/// four different design systems on four screens.
class ZyraCardMetrics {
  ZyraCardMetrics._();

  /// Square. A square thumbnail is the only shape that stays consistent
  /// whether the row carries one line of text or three — the 56×64
  /// portrait used on suggestions is what made those cards taller than
  /// everything around them.
  static const double thumb = 52;
  static const double thumbRadius = 10;
  static const double padding = 12;
  static const double cardRadius = 14;
  static const double gap = 14;

  /// Vertical space between consecutive cards in a list.
  static const double spacing = 10;
}

enum _ActivityKind { considered, saved, passed }

/// A Guardian Suggestion — deliberately its own card, not an _ActivityCard.
///
/// Two reasons. Visually, _ActivityCard's photo fills the row, so a profile
/// without photos became a full-height grey rectangle (the Founder's
/// screenshot, 2026-08-05). Behaviourally, the others show things you have
/// already decided on and can move between lists; this is someone you have
/// never seen. The only honest action is to go and look — so there is
/// exactly one button, and it puts you in Browse on their profile.
class _SuggestionCard extends StatelessWidget {
  final GuardianSuggestion suggestion;
  final VoidCallback onViewProfile;

  const _SuggestionCard({required this.suggestion, required this.onViewProfile});

  @override
  Widget build(BuildContext context) {
    final p = suggestion.profile;
    final photo = p.photos.isEmpty ? null : p.photos.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: ZyraCardMetrics.spacing),
      child: Container(
        padding: const EdgeInsets.all(ZyraCardMetrics.padding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
          borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ZyraCardMetrics.thumbRadius),
              child: SizedBox(
                width: ZyraCardMetrics.thumb,
                height: ZyraCardMetrics.thumb,
                child: photo == null
                    // Never a bare grey block again — if there is no photo,
                    // say so with an icon rather than an empty rectangle.
                    ? ColoredBox(
                        color: Colors.white.withValues(alpha: 0.08),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white.withValues(alpha: 0.35),
                          size: 26,
                        ),
                      )
                    : ZyraProfileImage(photo,
                        width: ZyraCardMetrics.thumb, height: ZyraCardMetrics.thumb),
              ),
            ),
            const SizedBox(width: ZyraCardMetrics.gap),
            // RELAID OUT 2026-08-05 (Founder: "it should say name, age
            // underneath suggested by and on right view profile button").
            // Matches the Considered/Saved/Passed rows: photo, then a short
            // text block, then the action on the right — so the whole
            // Activity panel scans as one list rather than two designs.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.age > 0 ? '${p.firstName}, ${p.age}' : p.firstName,
                    style: ZyraText.body(size: 15.5, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  // The Guardian's name, not "a suggestion was received" —
                  // "Ibrahim put this person forward" is the whole weight of
                  // the feature (UX Writing standard: people before
                  // software).
                  Text(
                    'Suggested by ${suggestion.suggestedBy}',
                    style: ZyraText.subtext(size: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ZyraColors.accentBg,
                  border: Border.all(color: ZyraColors.accentBorder, width: 1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: onViewProfile,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Profile', style: ZyraText.button(size: 12.5)),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_forward, size: 13, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a move button does. Consider and pass are decisions; save and
/// unsave are bookmark operations. See _ActivityCardState._move.
enum _Move { consider, pass, save, unsave }

class _ActivityCard extends StatefulWidget {
  final SeekerProfile profile;
  final _ActivityKind kind;

  /// `subtitle` was removed 2026-08-01 (Founder: "I feel we should remove
  /// the words 'waiting to hear back' completely").
  ///
  /// Taken further than asked, deliberately. The other two values it ever
  /// held were "Saved" and "Passed" — sitting directly under headers
  /// reading SAVED and PASSED. Removing one redundant label and keeping
  /// two identical ones would have been arbitrary. Say if the other two
  /// should come back.
  const _ActivityCard({
    required this.profile,
    required this.kind,
  });

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _open = false;

  /// Anchor for Scrollable.ensureVisible when the card expands.
  final GlobalKey _cardKey = GlobalKey();
  int _photoIndex = 0;
  bool _busy = false;

  /// CHANGED 2026-08-01 (Founder: "make it match the Browse button, where
  /// if tapped it moves, and the dot to show photo number... copy the
  /// Browse page and be on left centre side").
  ///
  /// Was a PageView with a horizontal dot row on top. Two problems with
  /// that here, and the second is the real one:
  ///
  ///   1. It did not match Browse, which cycles on TAP.
  ///   2. A horizontally-swipeable PageView inside a horizontally-
  ///      swipeable Connections pager fights it. Whichever wins, one of
  ///      the two gestures becomes unreliable — and Connections only just
  ///      gained its swipe.
  ///
  /// Tapping has no such conflict. Same tap-left/tap-right split as
  /// browse_screen's _tapPhoto.
  void _tapPhoto(TapUpDetails d, double width) {
    final photos = widget.profile.photos;
    if (photos.length <= 1) return;
    setState(() {
      if (d.localPosition.dx > width / 2) {
        _photoIndex = _photoIndex >= photos.length - 1 ? 0 : _photoIndex + 1;
      } else {
        _photoIndex = _photoIndex <= 0 ? 0 : _photoIndex - 1;
      }
    });
  }

  /// Move this profile to a different state.
  ///
  /// ADDED 2026-08-01 (Founder: "there's no way to open the profile card
  /// and move a user to save or decline... if I considered a profile but
  /// changed my mind then I need a button").
  ///
  /// Honours the two-axis model rather than flattening it:
  ///
  ///   CONSIDER / PASS  are DECISIONS. Mutually exclusive, most recent
  ///                    wins. Setting one clears the other, in AppState
  ///                    and via the database's own trigger.
  ///   SAVE / UNSAVE    is a BOOKMARK. It never touches the decision, and
  ///                    the decision never touches it.
  ///
  /// So "move to Save" from Considered adds a bookmark and leaves them
  /// Considering — it is not a downgrade, because there is no such thing.
  /// Only Pass can undo a Consider.
  Future<void> _move(_Move move) async {
    if (_busy) return;
    setState(() => _busy = true);
    final app = AppState.instance;
    final p = widget.profile;
    switch (move) {
      case _Move.consider:
        app.like(p);
        await ZyraDiscoveryService.recordLike(p.id);
      case _Move.pass:
        app.decline(p);
        await ZyraDiscoveryService.recordPass(p.id);
      case _Move.save:
        app.save(p);
        await ZyraDiscoveryService.recordSave(p.id);
      case _Move.unsave:
        app.unsave(p);
        await ZyraDiscoveryService.removeSave(p.id);
    }
    if (mounted) setState(() => _busy = false);
  }

  // `_canUnlock` removed 2026-08-03. It gated Compatibility Unlock off
  // Passed cards, per the 2026-07-12 rule "cannot be used on passed
  // profiles" — a rule the Founder has now reversed. Deleted rather than
  // left as a constant returning true.

  /// True once this profile has been unlocked at EITHER tier — the button
  /// then reads "View Compatibility" for good.
  bool get _viewable =>
      ZyraUnlockService.isUnlocked(widget.profile.id, UnlockTier.standard) ||
      ZyraUnlockService.isUnlocked(widget.profile.id, UnlockTier.plus);

  /// Opens the card AND scrolls it fully into view.
  ///
  /// ADDED 2026-08-03 (Founder: "right now I gotta swipe down to see the
  /// full thing — once they press expand, the page shows the full expand
  /// so the user doesn't have to swipe").
  ///
  /// The card grows from ~76pt to roughly 500pt, all of it below the tap,
  /// so expanding always pushes most of itself off-screen.
  ///
  /// FIXED 2026-08-04 (Founder: "that's no longer working"). It was a race
  /// all along and had simply been getting away with it.
  ///
  /// The body is an AnimatedCrossFade over [_kExpandAnim]. A single
  /// `addPostFrameCallback` fires after the FIRST frame of that animation —
  /// when the card has barely started growing — so `ensureVisible`
  /// measured a nearly-collapsed card and scrolled to where it used to be,
  /// not where it was heading. Whether it looked right depended on how far
  /// down the list the card already was.
  ///
  /// Now it scrolls TWICE, deliberately:
  ///   • post-frame, so the movement starts immediately and feels attached
  ///     to the tap rather than lagging behind it
  ///   • again once the crossfade has finished and the real height exists
  ///
  /// The second call is the correct one; the first is there so the scroll
  /// does not visibly wait 200ms before starting. Both are cheap no-ops if
  /// the card is already in view.
  static const Duration _kExpandAnim = Duration(milliseconds: 200);

  void _scrollIntoView() {
    final ctx = _cardKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      // 0.0 puts the card's top at the viewport's top, which is what
      // "show the whole thing" means for something taller than a
      // thumbnail. Centring would leave the head cropped.
      alignment: 0.0,
    );
  }

  void _expand() {
    setState(() => _open = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollIntoView());
    // +40ms past the crossfade so the final layout has certainly been
    // laid out, not merely scheduled.
    Future.delayed(_kExpandAnim + const Duration(milliseconds: 40), () {
      if (mounted) _scrollIntoView();
    });
  }

  Future<void> _report() async {
    final handled = await showReportProfileSheet(
      context,
      profileId: widget.profile.id,
      firstName: widget.profile.firstName,
      source: ZyraReportSource.connections,
    );
    if (handled == true && mounted) setState(() => _open = false);
  }

  /// The two move buttons, ordered by ascending commitment.
  ///
  ///   Considered   Pass · Save
  ///   Saved        Pass · Consider
  ///   Passed       Save · Consider
  ///
  /// FIXED 2026-08-04 (Founder: "the flag for Considered isn't in line with
  /// the others — make it the same as Saved").
  ///
  /// It was not the flag. The flag row was always full width; the row ABOVE
  /// it was 8pt short, but only on a Considered card, so the flag looked
  /// like the thing sticking out.
  ///
  /// The old code put each button and a trailing 8pt gap inside the same
  /// `if`, so the gap survived whenever its button was the last one
  /// rendered. That only happens for Considered — it is the one kind whose
  /// two buttons are the FIRST two in the list:
  ///
  ///   Considered   [Pass][8][Save][8]        <- 8pt of nothing on the end
  ///   Saved        [Pass][8][Consider]
  ///   Passed       [Save][8][Consider]
  ///
  /// The Expandeds then divided the remaining width, so both buttons ended
  /// 8pt shy of the card edge.
  ///
  /// Rebuilt as a list joined by separators rather than three independent
  /// `if`s each carrying its own spacing. A separator can now only exist
  /// BETWEEN two buttons, so this cannot reappear if a fourth action is
  /// added or the order changes again.
  Widget _moveRow() {
    final actions = <Widget>[
      if (widget.kind != _ActivityKind.passed)
        _CardAction(
          icon: Icons.close,
          label: 'Pass',
          onTap: _busy ? null : () => _move(_Move.pass),
        ),
      if (widget.kind != _ActivityKind.saved)
        _CardAction(
          icon: Icons.bookmark_border,
          label: 'Save',
          onTap: _busy ? null : () => _move(_Move.save),
        ),
      // Consider is the only action the other person ever learns about, so
      // it sits furthest from the thumb and is never the accidental tap.
      if (widget.kind != _ActivityKind.considered)
        _CardAction(
          icon: Icons.check_circle_outline,
          label: 'Consider',
          onTap: _busy ? null : () => _move(_Move.consider),
        ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: _cardKey,
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _open ? Colors.white.withValues(alpha: 0.13) : ZyraColors.iconButtonBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _open ? Colors.white.withValues(alpha: 0.24) : ZyraColors.iconButtonBorder,
            width: _open ? 1 : 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              // COLLAPSED HEADER ONLY, 2026-08-01 (Founder: "when I
              // expand I can now see the photo twice, big and small, and
              // Hassan 29 twice big and small... when you expand, the
              // large overtakes the small so the small isn't shown").
              //
              // It was rendering in both states: a 52px thumbnail and a
              // name directly above the full-size photo and the same name
              // again. The header exists to identify a row you cannot see
              // into. Once you can see into it, it is duplication.
              if (!_open)
                InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _expand,
                child: Padding(
                  padding: const EdgeInsets.all(ZyraCardMetrics.padding),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(ZyraCardMetrics.thumbRadius),
                        child: ZyraProfileImage(widget.profile.photoUrl,
                            width: ZyraCardMetrics.thumb, height: ZyraCardMetrics.thumb),
                      ),
                      const SizedBox(width: ZyraCardMetrics.gap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text('${widget.profile.firstName}, ${widget.profile.age}',
                                      style: ZyraText.body(size: 14, color: Colors.white)),
                                ),
                                // ADDED 2026-08-01 (Founder: "when I swiped
                                // on one user and it had Saved and I moved
                                // it to Considered I still see it on
                                // Saved").
                                //
                                // That is the model working, not a bug —
                                // Saved is a bookmark and Considering is a
                                // decision, so one profile legitimately
                                // holds both. But "correct" is no defence
                                // if it LOOKS like the duplicate we just
                                // spent a session fixing. The chip says
                                // out loud why the person is in two
                                // places, on the row where the question
                                // actually occurs to you.
                              ],
                            ),
                            // ADDED 2026-08-05 (Founder: "if they decline,
                            // consider etc it moves to decline/consider/save
                            // but still with the word guardian suggested
                            // somewhere").
                            //
                            // The Guardian's involvement is the most
                            // meaningful thing about how this person got
                            // here, and it shouldn't evaporate the moment a
                            // decision is made — a month later, "Ibrahim
                            // suggested her" is exactly the context you want
                            // when scanning a list of people you passed on.
                            if (AppState.instance.suggestedBy(widget.profile.id) != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.shield_outlined,
                                      size: 11, color: Colors.white.withValues(alpha: 0.45)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Suggested by ${AppState.instance.suggestedBy(widget.profile.id)}',
                                      style: ZyraText.subtext(size: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Plain, not AnimatedRotation. It used to flip
                      // between down and up on `_open` — but this whole
                      // row is now inside `if (!_open)`, so it only ever
                      // exists in the collapsed state and the rotation
                      // could never fire. Expanding is signalled by the
                      // card opening; collapsing is the centred chevron
                      // at the bottom.
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 20),
                    ],
                  ),
                ),
              ),
              // REDESIGNED 2026-08-01 (Founder: "the expansion should be
              // just Unlock and Unlock+ because what if they wanna see
              // full photo of person again... it's kinda gotta be a mini
              // profile view. And the report button is too exposed and
              // wide so it needs to be more hidden").
              //
              // Both notes are right and they are the same note. The first
              // version was an ACTION MENU — three stacked buttons, one of
              // them a full-width salmon bar — attached to a 52px
              // thumbnail. Nobody opens a saved profile to file a report;
              // they open it to look at the person again.
              //
              // So: photos first and large, swipeable, with the details
              // under them. Unlock and Unlock+ are the only buttons.
              // Report moves to a small flag in the corner of the photo —
              // reachable in one tap, but no longer the loudest thing in
              // the card. A report is rare and deliberate; it does not
              // need to shout.
              AnimatedCrossFade(
                // Shared with _expand()'s second scroll pass — if these two
                // durations drift apart, the auto-scroll silently starts
                // measuring mid-animation again.
                duration: _kExpandAnim,
                crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  // Top inset raised from 0 to 12 — with the collapsed
                  // header gone, the photo is now the top of the card and
                  // needs the same breathing room as its other edges.
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              LayoutBuilder(
                                builder: (context, c) => GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (d) => _tapPhoto(d, c.maxWidth),
                                  child: ZyraProfileImage(
                                    widget.profile.photos[
                                        _photoIndex.clamp(0, widget.profile.photos.length - 1)],
                                  ),
                                ),
                              ),
                              // Bottom scrim so the name stays legible on
                              // a pale photo — same problem the sheets
                              // have, same solution.
                              Positioned(
                                left: 0, right: 0, bottom: 0,
                                child: Container(
                                  height: 96,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.65),
                                        Colors.black.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Left-side vertical rail, copied from
                              // browse_screen (left: 16, vertically
                              // centred, 7px dots, white active / white
                              // 0.32 inactive, 0.5px white 0.3 border).
                              // Same values, not an approximation — two
                              // photo viewers in one app should not have
                              // two dot styles.
                              if (widget.profile.photos.length > 1)
                                Positioned(
                                  left: 12,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(widget.profile.photos.length, (i) {
                                        final active = i == _photoIndex;
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 3),
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.3), width: 0.5),
                                            color: active
                                                ? Colors.white
                                                : Colors.white.withValues(alpha: 0.32),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              // Report — deliberately small and quiet.
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${widget.profile.firstName}, ${widget.profile.age}',
                                        style: ZyraText.heading(size: 20)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.place_outlined,
                                            size: 13, color: Colors.white.withValues(alpha: 0.75)),
                                        const SizedBox(width: 5),
                                        Text(widget.profile.city,
                                            style: ZyraText.subtext(
                                                size: 12.5,
                                                color: Colors.white.withValues(alpha: 0.85))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // MOVE ACTIONS — 2026-08-01 (Founder: "there's no
                      // way to open the profile card and move a user to
                      // save or decline").
                      //
                      // Which actions appear depends on where the card
                      // already is, and follows the two-axis model:
                      //
                      //   Considered  Pass (changes the decision)
                      //               Save / Saved (bookmark, independent)
                      //   Saved       Consider, Pass (set the decision)
                      //               Remove save (drops the bookmark)
                      //   Passed      Consider (changes the decision)
                      //               Save (bookmark)
                      //
                      // Note what is deliberately absent: there is no
                      // "un-Consider". Considering can only be replaced by
                      // Passing, because the other person may already have
                      // been told. Quietly withdrawing would be a lie by
                      // omission, and the database enforces the same rule
                      // through the likes/passes triggers.
                      // ORDER: Pass, Save, Consider — 2026-08-03
                      // (Founder: "in decline you have Consider, Save but
                      // it should be Save, Consider; likewise for Save
                      // it's Consider, Pass but it should be Pass,
                      // Consider").
                      //
                      // Both corrections point at one principle, so the
                      // row is now ordered by ASCENDING COMMITMENT rather
                      // than by a fixed list with gaps:
                      //
                      //   Pass      let them go
                      //   Save      keep them, tell them nothing
                      //   Consider  tell them you are interested
                      //
                      // Consider is the only action the other person ever
                      // learns about, so it sits furthest from the thumb
                      // and is never the accidental tap. Each card shows
                      // the two it is not already in:
                      //
                      //   Considered   Pass · Save
                      //   Saved        Pass · Consider
                      //   Passed       Save · Consider
                      const SizedBox(height: 10),
                      _moveRow(),
                      // SHOWN ON EVERY CARD, INCLUDING PASSED — Founder,
                      // 2026-08-03: "we said on decline there isn't an
                      // option for Profile Unlock, but I feel we should
                      // change that so the option is there."
                      //
                      // Reverses the 2026-07-12 rule "cannot be used on
                      // passed profiles". That rule read as tidiness —
                      // why check compatibility with someone you rejected.
                      // But the person having second thoughts about a Pass
                      // is exactly who a compatibility score helps, and
                      // this card already offers Consider and Save from
                      // that state. Offering the reconsideration while
                      // withholding the one thing that would INFORM it was
                      // backwards.
                      //
                      // APP/Premium/Profile Unlocks/Summary.md updated to
                      // match rather than left contradicting the app.
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              flex: 85,
                              // LABEL 2026-08-03, Founder approved: the
                              // button becomes "View Compatibility"
                              // permanently once this profile has been
                              // unlocked at either tier, and returning
                              // never consumes another unlock.
                              //
                              // Either tier flips it, because both lead to
                              // the same screen and the same idea. Holding
                              // Unlock but not Plus still means there is
                              // compatibility to view.
                              child: _CardAction(
                                icon: _viewable ? Icons.visibility_outlined : Icons.insights_outlined,
                                label: _viewable ? 'View Compatibility' : 'Compatibility Unlock',
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProfileUnlockScreen(profile: widget.profile),
                                    ),
                                  );
                                  // An unlock may have happened on that
                                  // screen; the label has to catch up.
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 15,
                            child: _FlagAction(onTap: _report),
                          ),
                        ],
                      ),
                      // COLLAPSE — 2026-08-01 (Founder: "the arrow on the
                      // top right of the card is still needed... the flag
                      // button can go up and the arrow can move to middle,
                      // so the flag is in top right of card and arrow is
                      // in middle").
                      //
                      // The flag already sits top-right of the photo,
                      // which IS the top right of the card now that the
                      // header is hidden — so it moved by deletion rather
                      // than by being repositioned.
                      //
                      // The chevron went with the header, so the only way
                      // out was tapping the photo, which now cycles
                      // photos instead. Without this the card could be
                      // opened and not closed. Centred, full width, and a
                      // comfortable tap target.
                      const SizedBox(height: 4),
                      Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _open = false),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
                            child: Icon(
                              Icons.keyboard_arrow_up,
                              size: 22,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2026-08-01: the `danger` variant was dropped with the Report button
/// that used it. Report is now a small flag on the photo, not a
/// full-width salmon bar (Founder: "too exposed and wide"). Unlock and
/// Unlock+ are the only things using this now.
/// Report. Same height, radius and fill as _CardAction so the two sit
/// level in the row — icon only, because at 15% width a label would not
/// fit and an abbreviation would be worse than a glyph.
class _FlagAction extends StatelessWidget {
  final VoidCallback onTap;
  const _FlagAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          // Matches _CardAction's vertical 10 + 15px icon, so both
          // buttons are the same height without hardcoding one.
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Icon(
              Icons.flag_outlined,
              size: 15,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Nullable so a move in flight can disable every button at once —
  /// double-tapping Pass while its write is still going would fire two
  /// decisions for one intent.
  final VoidCallback? onTap;

  const _CardAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tint = Colors.white.withValues(alpha: onTap == null ? 0.35 : 1);
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: tint.withValues(alpha: 0.8)),
              const SizedBox(width: 7),
              Text(label, style: ZyraText.button(size: 12.5, color: tint)),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  final SeekerProfile profile;
  final String subtitle;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;
  final bool dimmed; // #17 — Ended matches show greyed, per spec

  /// The Active Journey only (Founder, 2026-08-01: "active journey should
  /// be more stand out then the rest"). Brighter fill, a border that is
  /// actually visible, and a larger photo. Deliberately no new colour —
  /// see the ACTIVE JOURNEY note in _journeysChildren.
  final bool emphasised;

  const _JourneyTile({
    required this.profile,
    required this.subtitle,
    this.trailingLabel,
    this.onTap,
    this.onTrailingTap,
    this.dimmed = false,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final photoSize = emphasised ? 64.0 : 52.0;
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Padding(
      padding: EdgeInsets.only(bottom: emphasised ? 14 : 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: emphasised ? Colors.white.withValues(alpha: 0.16) : ZyraColors.iconButtonBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: emphasised ? Colors.white.withValues(alpha: 0.30) : ZyraColors.iconButtonBorder,
            width: emphasised ? 1 : 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(emphasised ? 14 : 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ZyraProfileImage(profile.photoUrl, width: photoSize, height: photoSize),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${profile.firstName}, ${profile.age}',
                            style: ZyraText.body(size: emphasised ? 16 : 14, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: ZyraText.subtext(
                              size: 11.5,
                              // ZyraText.subtext's `color` is non-nullable
                              // with a default, so the unemphasised branch
                              // restates that default rather than passing
                              // null.
                              color: emphasised
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : const Color(0xB3FFFFFF),
                            )),
                      ],
                    ),
                  ),
                  if (trailingLabel != null)
                    TextButton(
                      onPressed: onTrailingTap,
                      child: Text(trailingLabel!, style: ZyraText.button(size: 12.5)),
                    )
                  else if (onTap != null)
                    Icon(Icons.chevron_right,
                        color: emphasised ? Colors.white70 : Colors.white38,
                        size: emphasised ? 20 : 18),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
