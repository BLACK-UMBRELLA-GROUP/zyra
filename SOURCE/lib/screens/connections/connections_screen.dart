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
import '../../data/zyra_entitlements.dart';
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
import '../../widgets/zyra_glass_dialog.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../journey/journey_flow_screen.dart';
import '../matches/journey_timeline_screen.dart';
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

  /// Ended matches on which this user may ask to begin again — OA-ZYRA-159.
  ///
  /// A match's ABSENCE carries no reason. A 6-month cooldown, a permanent
  /// "don't ask again", a block, a Tier-1 exclusion, an Active Journey
  /// elsewhere and an already-pending request are all identical from here.
  /// That indistinguishability is the design, not a gap: DR-ZYRA-121 item 8
  /// says "the requester is never told which". Do not enrich this into a
  /// map of reasons, however helpful that would feel.
  ///
  /// Empty until the query returns, and empty forever if it fails — so the
  /// button is hidden rather than offered and refused.
  Set<String> _mayRequest = const {};

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
    //
    // ── CHANGED 2026-08-11. The real rows are now ALWAYS fetched, even when
    // the panel is driving the page, because the Active toggle SURFACES a
    // real Journey instead of inventing one (see fakeJourneys' realActive).
    // In a release build journeysOverridden is permanently false and
    // holdsRealActiveJourneys permanently false, so this is the same single
    // fetch and the same list it has always been.
    final dev = ZyraDevScenario.instance;
    final real = await ZyraJourneyService.fetchJourneyMatches(
        statuses: const ['potential', 'active', 'ended']);
    // Running and not paused — the set the Active row governs. Written once
    // and used twice, so "surface it" and "hold it back" cannot come to
    // disagree about which Journeys they mean.
    bool isRunning(JourneyMatch j) => j.status == 'active' && !j.isSuspended;
    final realActive = real.where(isRunning).toList();

    final all = dev.journeysOverridden
        ? ZyraDevScenario.fakeJourneys(
            viewerGender: AppState.instance.gender,
            pool: await ZyraDiscoveryService.fetchCandidates(),
            // 2026-08-09: the generator clamps its counts to the plan's
            // Journey limits, so it has to be told which plan.
            viewerPlan: AppState.instance.plan,
            realActive: realActive,
          )
        // Active row at 0 means NO Active Journeys, including the genuine
        // one — dev builds only. Paused rows are status 'active' too and are
        // deliberately left alone: they answer to their own row.
        : (dev.holdsRealActiveJourneys
            ? real.where((j) => !isRunning(j)).toList()
            : real);
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
    //
    // FILTERED BY ROW, NOT BY FLAG, 2026-08-11. This used to skip the query
    // whenever ANY Journey toggle was on, which was a proxy for "everything
    // here is fake" — true until the Active toggle began surfacing the real
    // Journey. isMock is the property the comment above was always really
    // describing, so it is now the property being tested.
    final realActiveIds =
        active.where((j) => !j.isMock).map((j) => j.matchId).toList();
    final openReviews = realActiveIds.isEmpty
        ? const <String>{}
        : await ZyraJourneyService.fetchOpenReviewMatchIds(realActiveIds);

    // OA-ZYRA-159 stage 5. Expire lapsed requests BEFORE asking which
    // Journeys may be asked on, or a request that ran out its fourteen days
    // yesterday would still read as pending and suppress the button.
    //
    // Lazy rather than scheduled — there is no cron in this database, and
    // this is the same shape as resolveFamilyReviewIfDue.
    // Same rule as openReviews above: asked when there is a real ended row to
    // ask about, not when a flag says the panel is involved.
    Set<String> mayRequest = const {};
    if (ended.any((j) => !j.isMock)) {
      await ZyraJourneyService.expireDueJourneyRequests();
      // BATCHED — one call for every ended Journey. A per-row lookup here is
      // the N+1 this file already has a rule against.
      mayRequest = await ZyraJourneyService.fetchMayRequestNewJourneyIds();
    }
    if (!mounted) return;

    setState(() {
      _suspended = suspended;
      _ended = ended;
      _openReviews = openReviews;
      _mayRequest = mayRequest;
    });
  }

  /// OA-ZYRA-159. Asks the other Seeker to begin again.
  ///
  /// CONFIRMED FIRST, because the tap is easy to misread. "Request New
  /// Journey" is honest about being a request, but someone who ended a
  /// Journey months ago and taps it on a quiet evening should be told plainly
  /// that the other person will be notified and may say no — before it
  /// happens, not after.
  Future<void> _requestNewJourney(JourneyMatch j) async {
    // RESTYLED 2026-08-11 (Frost UI full-app pass): the unratified
    // near-black AlertDialog becomes the ratified glass modal. Copy
    // unchanged.
    final confirmed = await showZyraGlassChoice(
      context: context,
      icon: Icons.restart_alt_outlined,
      title: 'Ask ${j.profile.firstName} to begin again?',
      body: "They'll be told you asked, and can accept or decline. Nothing "
          'starts unless they agree.\n\nIf they accept, this is a fresh '
          'Journey — a new conversation, from the beginning. Everything from '
          'before is kept, and stays where it is.',
      primaryLabel: 'Send request',
      secondaryLabel: 'Not now',
    );
    if (confirmed != true) return;

    final error = await ZyraJourneyService.requestNewJourney(j.matchId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Asked ${j.profile.firstName}. You\'ll hear when they answer.'),
      ));
    }
    // Re-read either way: on success the button must disappear (one pending
    // request per pair), and on failure the server may have refused for a
    // reason that also changes what this list should show.
    await _refresh();
  }

  // THE START MOMENT, REWRITTEN 2026-08-11 (Founder: the start flow
  // "gotta show it will end current journey if thats the case"). Until
  // now the one-Active-Journey rule surfaced AFTER the confirm — the
  // server refused promoteToActive and a snackbar told the person to go
  // end something, so they learned the cost of the choice only once it
  // had already bounced. Now the dialog itself carries the cost: when an
  // Active Journey exists, confirming HERE ends it and starts the new
  // one, and the copy says exactly that before the tap.
  //
  // End-then-start, not start-then-end: promoteToActive refuses while
  // any Active Journey exists, so the order is forced. If the promote
  // then fails anyway, nothing is silently lost — the ended Journey
  // sits in Ended Journeys with its Timeline kept, and _promote's own
  // error handling says the start itself failed.
  //
  // DISCLOSURE PRESERVED from 2026-08-01 (Founder decision, via ChatGPT:
  // Guardian conversation visibility is deliberate and must be stated
  // consistently everywhere). THIS IS THE MOMENT IT MATTERS —
  // messages_select's RLS grants a linked Wali read access from the
  // instant matches.status leaves 'potential', which is exactly what
  // this button does. It names BOTH Guardians because the policy grants
  // access to a Wali linked to EITHER Seeker; saying only "your
  // Guardian" would be a second, subtler untruth.
  void _startJourney(JourneyMatch j) async {
    final blocking = AppState.instance.activeJourneys
        .where((a) => !a.isMock && a.matchId != j.matchId && !a.isSuspended)
        .toList();

    final guardianLine =
        'From this point your linked Guardian — and ${j.profile.firstName}\'s — '
        'can read the conversation between you. That is deliberate: ZYRA is '
        'built for a marriage process with family present, not for private '
        'one-to-one messaging.';

    if (blocking.isEmpty) {
      final confirmed = await showZyraGlassChoice(
        context: context,
        icon: Icons.flag_outlined,
        title: 'Start Journey with ${j.profile.firstName}?',
        body: 'This starts your Active Journey. It will use your Journey slot '
            'and begin the Pre-Journey Ritual with Compatibility Reveal.\n\n'
            '$guardianLine\n\n'
            'You may only have one Active Journey at a time.',
        primaryLabel: 'Start Journey',
        secondaryLabel: 'Not yet',
      );
      if (confirmed == true) await _promote(j);
      return;
    }

    // One Active Journey exists — the tap is really a choice BETWEEN two
    // people, and the dialog must say so. The pause escape route is
    // offered in copy only when the plan actually has it (Pause is a
    // ZYRA One capability — Founder amendment on DR-ZYRA-121).
    final other = blocking.first;
    final pauseLine = AppState.instance.plan == ZyraPlan.one
        ? '\n\nIf you want to keep it instead, pause it from inside the '
            'Journey first, then start this one.'
        : '';
    final confirmed = await showZyraGlassChoice(
      context: context,
      icon: Icons.swap_horiz,
      title: 'End your Journey with ${other.profile.firstName}?',
      body: 'You may only have one Active Journey at a time, and you are in '
          'one with ${other.profile.firstName} now.\n\n'
          'Starting with ${j.profile.firstName} will permanently END your '
          'Journey with ${other.profile.firstName}. Its Timeline is kept '
          'under Ended Journeys, but beginning again later would need a New '
          'Journey request that ${other.profile.firstName} accepts.'
          '$pauseLine\n\n'
          '$guardianLine',
      primaryLabel: 'End it & start new Journey',
      secondaryLabel: 'Keep my Journey',
    );
    if (confirmed != true) return;

    await ZyraJourneyService.endJourney(other.matchId);
    await _refresh();
    if (!mounted) return;
    await _promote(j);
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

  /// How many Ended Journeys this plan lists, and how many are held back.
  /// Display only — see the note at the ENDED JOURNEYS section below.
  int get _endedShown => ZyraEntitlements.of(AppState.instance.plan).ended;
  int get _endedHidden =>
      _ended.length <= _endedShown ? 0 : _ended.length - _endedShown;

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
        ...active.map((j) {
          // TRAILING ACTION — Founder, 2026-08-10: "active journey should be
          // enter", styled like POTENTIAL's "Start Journey", so every Journey
          // row states its action on the right instead of leaving three of the
          // four sections with a bare chevron.
          //
          // THE WHOLE-CARD TAP WAS REMOVED LATER THE SAME DAY, at Founder
          // instruction: "wherever I click goes into enter journey but that
          // ruins the enter journey button anyway, so make sure the profile
          // card clicked does nothing so only the 2 buttons are action
          // buttons."
          //
          // The comment that stood here argued the opposite — that a card
          // tappable everywhere is better than one with a button that is the
          // only route. It was wrong for this card. Two labelled pills sit on
          // it; a card-wide tap makes the primary one decorative, and makes
          // the secondary one a trap, because everything around "Timeline"
          // silently does something else.
          void enter() => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
              ));
          return _ActiveJourneyCard(
              profile: j.profile,
              onEnter: enter,
              onTimeline: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => JourneyTimelineScreen(withProfile: j.profile),
                  )),
              // Same sheet and same source as every other card on this page,
              // so a report raised from an Active Journey is indistinguishable
              // from one raised anywhere else — which is what the person
              // reporting should be able to assume.
              onReport: () async {
                await showReportProfileSheet(
                  context,
                  profileId: j.profile.id,
                  firstName: j.profile.firstName,
                  source: ZyraReportSource.connections,
                );
                if (mounted) await _refresh();
              },
              // NOT the stage label — that came out on Founder instruction,
              // 2026-08-10. This is the one Journey state that is waiting on
              // the member's FAMILY rather than on them, and it holds the
              // Journey for 48 hours.
              //
              // Removing the stage line took it with it, and left
              // _openReviews written by a batched query and read by nothing —
              // the shape of the `profile_complete` defect in the 2026-07-26
              // audit, inverted. Restored as a chip that appears only while a
              // review is open, so the ordinary card stays as asked.
              reviewOpen: _openReviews.contains(j.matchId),
              // BEGIN vs CONTINUE, Founder 2026-08-10: "either begin journey
              // if user started or continue journey if user is continuing".
              //
              // No new state was added for this. A Journey that is still on
              // its opening stage has not moved yet, whatever the member has
              // looked at — so "Begin" is true right up until the Journey
              // itself advances, and "Continue" from then on. Reading it off
              // the stage keeps one source of truth instead of a
              // has-been-opened flag that would need maintaining and could
              // drift.
              hasBegun: j.journeyStage != ZyraJourneyStages.all.first.value,
            );
        }),

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
            // Founder, 2026-08-10: every Journey row carries text on the right.
            //
            // The rows THEY paused say "Waiting", not "Resume". Journey
            // Suspension §12.1 gives the lift only to the person who paused,
            // so a Resume button here would fail every time it was pressed —
            // and the blank that was here before was the rule showing through,
            // not an omission. "Waiting" states the same rule in a word.
            //
            // Rendered as plain text rather than a disabled button; see the
            // trailing block in _JourneyTile.
            trailingLabel: iInitiated ? 'Resume' : 'Waiting',
            onTrailingTap: iInitiated ? () => _resumeSuspended(j) : null,
            // RESTYLED 2026-08-11 (Frost UI full-app pass): near-black
            // AlertDialog -> the ratified glass chrome. Three actions, so
            // it uses showZyraGlassDialog directly rather than the
            // two-action showZyraGlassChoice; layout mirrors that
            // helper's own (icon, title, body, full-width primary,
            // quiet declines under it). Copy unchanged.
            onTap: () => showZyraGlassDialog<void>(
              context: context,
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pause_circle_outline, color: Colors.white, size: 30),
                  const SizedBox(height: 14),
                  Text('Paused with ${j.profile.firstName}',
                      style: ZyraText.heading(size: 18), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    iInitiated
                        ? 'This Journey is currently paused. Resume to continue where you left off, or End it permanently.'
                        : "${j.profile.firstName} paused this Journey. You can wait for them to resume, or End it permanently — you can't resume it yourself.",
                    style: ZyraText.subtext(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (iInitiated)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _resumeSuspended(j);
                        },
                        child: Text('Resume', style: ZyraText.button(size: 13)),
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _endSuspended(j);
                    },
                    child: Text('End Journey',
                        style: ZyraText.button(size: 13, color: ZyraColors.destructive)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Close', style: ZyraText.subtext(size: 13)),
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
      else ...[
        // ── A DISPLAY CAP, AND ONLY A DISPLAY CAP. Founder, 2026-08-09:
        // "The cap is purely a UI cap, not a data-retention cap. I never
        // want Journey history deleted automatically."
        //
        // 5 on Basic, 10 on ZYRA One — most recent first, since _refresh()
        // already sorts descending by endedAt. `_ended` keeps every row, so
        // nothing here loses data and a Journey History screen can read the
        // full list whenever it is built.
        //
        // This is the ONLY one of the four Journey limits the client
        // enforces, precisely because it is not really a limit. Active,
        // Potential and Paused are entitlements and belong to the database
        // — see data/zyra_entitlements.dart.
        ..._ended.take(_endedShown).map((j) {
          final mayAsk = _mayRequest.contains(j.matchId);
          return _JourneyTile(
              profile: j.profile,
              // THE OLD SUBTITLE PROMISED SOMETHING THAT DID NOT EXIST.
              // It read "Ended — Restart available", and Restart has refused
              // since 2026-08-06 (OA-ZYRA-154). Contradiction-audit finding
              // 4.2 called that the highest-consequence tap in the product.
              //
              // Now it says only what is true. During the 24-hour cooling
              // period it says so; after it, the ROW says "Ended" and the
              // BUTTON — present only when the server says you may ask —
              // carries the offer. A subtitle should not make a promise a
              // button has to keep.
              subtitle: j.canRestart ? 'Ended' : 'Ended — ${j.restartAvailableIn.toLowerCase()}',
              dimmed: true,
              // OA-ZYRA-159, Founder-approved wording 2026-08-10. NOT
              // "Restart": the tap sends a request the other person can
              // decline, and "Restart" says it is already happening.
              //
              // Absent when the server says no — and it never says why. See
              // _mayRequest.
              trailingLabel: mayAsk ? 'Request New Journey' : null,
              onTrailingTap: mayAsk ? () => _requestNewJourney(j) : null,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
              )),
            );
        }),
        // Said out loud, rather than letting older Journeys vanish — the
        // disappearing-Journey problem this whole section exists to solve.
        if (_endedHidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Showing your $_endedShown most recent. '
              '$_endedHidden older ${_endedHidden == 1 ? "Journey is" : "Journeys are"} '
              'kept, just not listed here.',
              style: ZyraText.subtext(size: 11.5),
            ),
          ),
      ],
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

/// THE ACTIVE JOURNEY CARD. Founder, 2026-08-10: "make that profile card much
/// larger with the bottom have 2 text, enter and view timeline in bubbles."
///
/// Replaces `_JourneyTile(emphasised: true)` for this one section. The
/// emphasised tile was carrying two jobs badly — it existed to answer the
/// 2026-08-01 note that "active journey should be more stand out then the
/// rest" by being a slightly brighter version of a list row, and a slightly
/// brighter list row is still a list row.
///
/// ZYRA allows ONE Active Journey at a time. It is not the first item in a
/// list; it is the thing the app is for, and the other three sections are
/// where the rest waits. So it gets its own shape: a 96px portrait, the name
/// at heading size, the stage underneath, and the two things you actually do
/// from here as pills across the bottom.
///
/// NO NEW ACCENT COLOUR, for the same reason the emphasised tile avoided one:
/// the gender gradient is already behind this card, and a third colour would
/// fight it. Emphasis is size, weight and white alpha only.
///
/// The pills use circular(20) and ZyraColors.iconButtonBg/Border — the app's
/// existing pill, unchanged, so this reads as the same product rather than a
/// new screen. The whole card stays tappable and goes where Enter goes; the
/// pill names the action rather than owning it.
class _ActiveJourneyCard extends StatelessWidget {
  final SeekerProfile profile;
  final VoidCallback onEnter;
  final VoidCallback onTimeline;
  final VoidCallback onReport;
  final bool reviewOpen;

  /// The current Journey stage, from the canonical map. Rendered on the Enter
  /// pill, not as a status line — Timeline spec §12 option C, Founder
  /// 2026-08-10.
  /// True once the Journey has moved past its opening stage. Drives the
  /// primary pill's wording — Begin vs Continue — and nothing else.
  final bool hasBegun;

  const _ActiveJourneyCard({
    required this.profile,
    required this.onEnter,
    required this.onTimeline,
    required this.onReport,
    required this.reviewOpen,
    required this.hasBegun,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        // NOT tappable as a card — see the note at the call site. The two
        // pills below are the only actions, so there is no invisible third
        // one behind them.
        // The Material is kept though its InkWell has gone: descendants may
        // still want a Material ancestor, and a transparent one costs nothing
        // where guessing wrong costs a runtime "No Material widget found".
        child: Material(
          color: Colors.transparent,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PLAIN PHOTO. The expand glyph that briefly sat in this
                      // corner was rejected by the Founder on 2026-08-10 — a
                      // small icon on someone's face, doing something the icon
                      // does not name.
                      //
                      // The photo is NOT tappable either. An invisible tap
                      // target is worse than the glyph was: it is a feature
                      // only the person who built it knows about. Full profile
                      // has exactly one entry point now, and it is labelled —
                      // the bubble at the top of the Timeline.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ZyraProfileImage(profile.photoUrl, width: 96, height: 96),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NAME, SURNAME, AGE, LOCATION — Founder,
                            // 2026-08-10. This replaced the Journey stage
                            // label ("Open Conversation" and the seven others
                            // from the canonical map).
                            //
                            // WHAT THAT COSTS, recorded so it is a decision and
                            // not an accident: the Connections page no longer
                            // tells you WHERE your Journey is without entering
                            // it. The stage is still on the Journey itself and
                            // still comes from the one map (DR-ZYRA-129) — no
                            // second label was written here to replace it.
                            Text(profile.firstName, style: ZyraText.heading(size: 19)),
                            // surnameLine is a display string, not a lastName —
                            // it may already carry "middle name + surname"
                            // together (models/seeker_profile.dart). Rendered
                            // whole, never split.
                            if ((profile.surnameLine ?? '').trim().isNotEmpty)
                              Text(profile.surnameLine!.trim(),
                                  style: ZyraText.heading(
                                    size: 15,
                                    color: Colors.white.withValues(alpha: 0.86),
                                  )),
                            const SizedBox(height: 6),
                            Text('${profile.age} · ${profile.city}',
                                style: ZyraText.subtext(
                                  size: 12.5,
                                  color: Colors.white.withValues(alpha: 0.78),
                                )),
                            if (reviewOpen) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.34),
                                      width: 0.6),
                                ),
                                // THE ONE MAP, still. familyReviewOverride is
                                // the same string the Journey itself shows —
                                // no second wording was invented here
                                // (DR-ZYRA-129).
                                child: Text(
                                  ZyraJourneyStages.familyReviewOverride,
                                  style: ZyraText.subtext(
                                      size: 11, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // REPORT, TOP RIGHT. Founder, 2026-08-10: the flag must
                      // exist at every stage, and on this card it belongs here.
                      //
                      // NOT repeated inside Enter or View timeline — the
                      // Founder's call, and the right one: the flag is about
                      // the PERSON, and this card is where the person is. A
                      // flag on every screen of a Journey would read as the app
                      // expecting something to go wrong.
                      //
                      // Same icon, size and alpha as the flag on every other
                      // card in this file. It opens the same sheet, with
                      // ZyraReportSource.connections, so reports from here land
                      // where reports from the other cards land.
                      GestureDetector(
                        onTap: onReport,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          // Generous padding, small glyph — the tap target
                          // needs to clear 44pt without the icon shouting.
                          padding: const EdgeInsets.only(left: 10, bottom: 10),
                          child: Icon(
                            Icons.flag_outlined,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // 2 : 1. The Journey is the action; the Timeline is a
                      // reference. Equal widths said they were equal choices.
                      Expanded(
                        flex: 2,
                        child: _CardPill(
                          label: hasBegun ? 'Continue Journey' : 'Begin Journey',
                          onTap: onEnter,
                          primary: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _CardPill(label: 'Timeline', onTap: onTimeline)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

/// The app's existing pill — circular(20), iconButtonBg/iconButtonBorder —
/// with one variant. `primary` fills it so the Journey action reads as the
/// main one without introducing a colour.
///
/// The pills are NO LONGER the same width. Founder, 2026-08-10: the Timeline
/// pill is smaller than the Journey pill, 1 : 2 — the Journey is the action
/// and the Timeline is a reference, and equal widths claimed they were equal
/// choices. Heights stay equal so they still sit level.
class _CardPill extends StatelessWidget {
  final String label;

  // SUBLABEL RETIRED 2026-08-10. It carried the Journey stage under the
  // label — "Enter · Compatibility Reveal" — from an earlier Founder ruling
  // (Timeline spec §12, option C) that put the stage on the control leading
  // to it. Reversed the same day: "I don't want enter open conversation in
  // smaller text." The pill now says one thing.
  //
  // Removed rather than left unused, and `stageLabel` came off
  // _ActiveJourneyCard with it. A parameter written by a caller and read by
  // nothing is the shape of the `profile_complete` defect in the 2026-07-26
  // audit — the stage is still shown where it belongs, inside the Journey.

  final VoidCallback onTap;
  final bool primary;

  const _CardPill({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary
          ? Colors.white.withValues(alpha: 0.22)
          : ZyraColors.iconButtonBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          // 44, down from 46. The taller box existed to fit a second line —
          // the stage sublabel — which came off on 2026-08-10. Kept fixed and
          // equal on both pills so the narrow Timeline one still sits level
          // with the wide Journey one.
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary
                  ? Colors.white.withValues(alpha: 0.42)
                  : ZyraColors.iconButtonBorder,
              width: primary ? 1 : 0.5,
            ),
          ),
          // A Column with one child, left over from the two-line version.
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZyraText.button(size: 13.5),
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
                  // A LABEL WITH NO ACTION IS STATUS, NOT A DISABLED CONTROL.
                  // "Waiting" on a Journey the other person paused, and
                  // "Starting…" while a request is in flight, are both facts
                  // about the row rather than things you may do to it. A greyed
                  // TextButton would still announce itself to VoiceOver as a
                  // button — inviting a press that was never on offer.
                  if (trailingLabel != null && onTrailingTap == null)
                    Text(trailingLabel!,
                        style: ZyraText.subtext(size: 12.5, color: const Color(0x8AFFFFFF)))
                  else if (trailingLabel != null)
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
