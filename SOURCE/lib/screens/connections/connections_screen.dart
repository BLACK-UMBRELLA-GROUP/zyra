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
// Report). Journey rows use the same expanding model (_JourneyExpandingCard).
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
// JOURNEY_SUSPENSION (CURRENT_VERSION)) with Resume/End actions.

// 'dart:ui' import removed 2026-08-13: ImageFilter.blur was used only by
// the private _SegmentedToggle, which moved to
// widgets/zyra_segmented_toggle.dart in the same pass. Nothing in this
// file reaches into dart:ui any more.
import 'dart:async';

import '../../widgets/zyra_profile_image.dart';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../data/zyra_entitlements.dart';
import '../../data/zyra_journey_stages.dart';
import '../../models/journey_match.dart';
import '../../models/seeker_profile.dart';
import '../../models/zyra_gender.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_guardian_suggestion_service.dart';
import '../../services/zyra_journey_service.dart';
import '../../services/zyra_report_service.dart';
import '../../theme/zyra_card_metrics.dart';
import '../../services/zyra_unlock_service.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/report_profile_sheet.dart';
// zyra_glass_dialog import retired 2026-08-13, round four: confirmation
// choices remain inline card extensions. Founder-selected Connections
// Option 4 (2026-08-20) adds one grouped Journey-options bottom sheet,
// but Pause/End still require their existing inline confirmation before
// anything is written. Report and rare server-refusal routes are unchanged.
import '../../widgets/zyra_moment.dart';
import '../../widgets/zyra_paused_limit_refusal.dart';
import '../../widgets/zyra_segmented_toggle.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_profile_name_block.dart';
import '../journey/journey_flow_screen.dart';
import '../matches/journey_timeline_screen.dart';
import '../profile/seeker_profile_screen.dart';
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
  // Suspended journeys (JOURNEY_SUSPENSION (CURRENT_VERSION)): these
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

  /// True only while THIS screen is pushing the settled segment into the
  /// scenario. That push notifies, the notify lands back here in
  /// [_onScenarioChange], and without the flag every swipe between segments
  /// would re-fetch the very list being swiped — a reload flicker caused by
  /// the panel merely following you.
  bool _pushingSection = false;

  /// A dev toggle moved. Re-fetch, because the fakes are substituted at the
  /// fetch and a rebuild alone would show the same stale list.
  void _onScenarioChange() {
    if (_pushingSection) return; // our own section push looping back
    if (mounted) _refresh();
  }

  void _onPagerScroll() {
    if (!_pager.hasClients || _pager.page == null) return;
    // Upper bound was 1.0 — three segments now.
    final p = _pager.page!.clamp(0.0, (_kSegmentLabels.length - 1).toDouble());
    if ((p - _pagerPos).abs() < 0.001) return;
    setState(() => _pagerPos = p);
    // Settled on a segment — tell the dev panel where we are, so it can
    // narrow its Connections card to the section on screen (2026-08-12,
    // Founder: "i gotta be on indroduction to see the introduction optins
    // in toggle"). notifyListeners is synchronous, so the flag brackets
    // the loopback completely.
    if (!kReleaseMode && p == p.roundToDouble()) {
      _pushingSection = true;
      ZyraDevScenario.instance.setConnectionsSection(p.round());
      _pushingSection = false;
    }
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
    // A fresh build starts the pager on Journeys, but the scenario may
    // still hold the segment from a previous visit — realign it, or the
    // panel would show Introductions controls over a Journeys screen.
    // Post-frame because notifying listeners mid-build is not allowed.
    if (!kReleaseMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pushingSection = true;
        ZyraDevScenario.instance.setConnectionsSection(0);
        _pushingSection = false;
      });
    }
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
  ZyraPlan _planSeen = AppState.instance.plan;

  void _onChange() {
    final v = AppState.instance.suggestionsVersion;
    if (v != _suggestionsVersion) {
      _suggestionsVersion = v;
      _loadSuggestions();
    }
    // ADDED 2026-08-12. A plan switch re-runs the full refresh, because the
    // dev fakes are CLAMPED to the plan's Journey limits where the fetch
    // happens (fakeJourneys' devClamp) — a bare setState would redraw the
    // same over-cap list. Without this, ZYRA One with Paused at 8 switched
    // to Basic showed 5 in the panel and 8 on screen until some other
    // refresh happened to run: the panel and the page disagreeing about the
    // state the panel claims to own.
    if (AppState.instance.plan != _planSeen) {
      _planSeen = AppState.instance.plan;
      _refresh();
    }
    setState(() {});
  }

  /// False until the first fetch resolves — see [_suggestionsLoaded].
  Future<void> _loadSuggestions() async {
    final s = await ZyraGuardianSuggestionService.fetchPending();
    if (!mounted) return;
    setState(() {
      _suggestions = s;
      _suggestionsLoaded = true;
    });
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

  /// Whether the Introductions fetch has come back yet.
  ///
  /// ADDED 2026-08-13 (DR-ZYRA-165). This screen had no loading state at
  /// all — the busiest tab in the app, and its lists start empty — so
  /// during the first fetch Introductions rendered its EMPTY STATE:
  /// "No introductions yet. People your Guardian puts forward will appear
  /// here." Told to someone who may well have one waiting.
  ///
  /// Every comparable list screen guards this (Notifications, the
  /// Guardian tab, Blocked users, the Timeline). Scoped here to
  /// Introductions rather than the whole screen, because the other two
  /// segments read AppState, which is hydrated before this tab can be
  /// reached — Introductions is the only section that waits on a query.
  bool _suggestionsLoaded = false;

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
    // The clean dev panel is additive: real Journey rows are always shown,
    // and its counts add labelled preview cards for layout/state testing.
    // Zero removes previews only. This prevents a toggle from hiding a live
    // server Journey or replacing it with an Active-looking fake that cannot
    // enter the flow. Release builds use the real list directly.
    final dev = ZyraDevScenario.instance;
    final realOrNull = await ZyraJourneyService.fetchJourneyMatches(
      statuses: const ['potential', 'active', 'ended'],
    );
    // DR-ZYRA-179. Null means the fetch FAILED — not "no Journeys".
    // The old [] return here let a 403 (a missing column grant) read
    // as an empty list for three days, and in dev builds the panel's
    // stand-ins then topped up over the hole, so a real, live Journey
    // was invisible everywhere while every card LOOKED fine. Hold what
    // is already on screen, say so, and let the next pull retry.
    if (realOrNull == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't refresh Journeys — showing what was "
            'already loaded.',
          ),
        ),
      );
      return;
    }
    final real = realOrNull;
    bool isRunning(JourneyMatch j) => j.status == 'active' && !j.isSuspended;

    final all = kReleaseMode
        ? real
        : ZyraDevScenario.composeJourneys(
            viewerGender: AppState.instance.gender,
            // The candidate pool exists only to give FAKES real photos —
            // skip the fetch when every row is 0 and no fake will be drawn.
            pool: dev.anyJourneysStaged
                ? await ZyraDiscoveryService.fetchCandidates()
                : const [],
            // 2026-08-09: the generator clamps its counts to the plan's
            // Journey limits, so it has to be told which plan.
            viewerPlan: AppState.instance.plan,
            realActive: real.where(isRunning).toList(),
            realPotential: real.where((j) => j.status == 'potential').toList(),
            realPaused: real
                .where((j) => j.status == 'active' && j.isSuspended)
                .toList(),
            realEnded: real.where((j) => j.status == 'ended').toList(),
          );
    if (!mounted) return;
    final potential = all.where((j) => j.status == 'potential').toList();
    final activeAll = all.where((j) => j.status == 'active').toList();
    final active = activeAll.where((j) => !j.isSuspended).toList();
    final suspended = activeAll.where((j) => j.isSuspended).toList();
    final ended = all.where((j) => j.status == 'ended').toList()
      ..sort(
        (a, b) =>
            (b.endedAt ?? DateTime(0)).compareTo(a.endedAt ?? DateTime(0)),
      );
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
    final realActiveIds = active
        .where((j) => !j.isMock)
        .map((j) => j.matchId)
        .toList();
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
  /// The restart ask — INLINE since 2026-08-13 (Founder: "when i press
  /// restart the pop up shows but we changed the ui to give notification
  /// like we did for potential"). Was a glass dialog (restyled 2026-08-11,
  /// Frost UI pass); now the tap sets [_restartMatchId] and the ended
  /// card itself extends with the SAME words the dialog carried — see
  /// _InlineRestartAsk at the bottom of this file. _sendRestartRequest
  /// finishes the job.
  Future<void> _requestNewJourney(JourneyMatch j) async {
    setState(() => _restartMatchId = j.matchId);
  }

  /// The ended row whose card is currently extended with the restart ask.
  /// Null when nobody is mid-ask; a stale id matches nothing, exactly
  /// like [_takeoverMatchId].
  String? _restartMatchId;

  /// Builds the inline restart ask for [j], or null when its card isn't
  /// the one asking.
  Widget? _inlineRestartFor(JourneyMatch j) {
    if (_restartMatchId != j.matchId) return null;
    return _InlineRestartAsk(
      next: j,
      onDismiss: () => setState(() => _restartMatchId = null),
      onSend: () => _sendRestartRequest(j),
    );
  }

  Future<void> _sendRestartRequest(JourneyMatch j) async {
    setState(() => _restartMatchId = null);

    // A stand-in's request succeeds in words alone — there is no server
    // row to ask through, and no request state the list would show anyway.
    if (j.isMock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Asked ${j.profile.firstName}. You\'ll hear when they answer.',
          ),
        ),
      );
      return;
    }

    final error = await ZyraJourneyService.requestNewJourney(j.matchId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Asked ${j.profile.firstName}. You\'ll hear when they answer.',
          ),
        ),
      );
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
  // had already bounced. Now the moment itself carries the cost BEFORE
  // the tap — and since 2026-08-12 it carries the choice too: pause the
  // current Journey (its place kept) or end it, either followed by the
  // start. Since the same evening the choice is no longer a popup at
  // all — the person's own card extends with it (B3; see the banner
  // over _InlineTakeover at the bottom of this file).
  //
  // Settle-then-start, not start-then-settle: promoteToActive refuses
  // while any unsuspended Active Journey exists, so the order is forced.
  // If the promote then fails anyway, nothing is silently lost — a
  // paused Journey sits in Paused with its place kept, an ended one in
  // Ended with its Timeline kept, and _promote's own error handling says
  // the start itself failed.
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
    // MOCKS COUNT since 2026-08-12, evening (Founder: "the pop up we just
    // made isnt showing on app" — his Active Journey was a staged
    // stand-in, and `!a.isMock` here quietly excused it, so the takeover
    // never fired in exactly the solo-testing state it was built to be
    // rehearsed in). AppState holds the COMPOSED list, so in a dev build
    // staged rows block like real ones; in release no mock exists to
    // count. What differs is the ACTION: a stand-in pauses and ends in
    // the scenario's numbers (see the switch below), never the database.
    final blocking = AppState.instance.activeJourneys
        .where((a) => a.matchId != j.matchId && !a.isSuspended)
        .toList();
    // The plan's cap, mirroring the server's zyra_active_journey_cap()
    // (Basic 1 / ZYRA One 3 — plan_aware_active_journey_limit,
    // 2026-08-12). Below the cap a start needs no takeover at all: One
    // with a single Active Journey simply begins its second.
    final cap = ZyraEntitlements.of(AppState.instance.plan).active;

    if (blocking.length < cap) {
      // THE LAST POPUP IN THE BEGIN FLOW, GONE — 2026-08-13 (Founder:
      // "I still get a popup. We agreed we were moving away from
      // popups"). What he was hitting was exactly this branch: on ZYRA
      // One a single Active Journey sits UNDER the cap of 3, so the
      // takeover rightly never fired — and this confirm, a glass dialog
      // since its 2026-08-12 restyle, did. Now the confirm extends the
      // person's card inline like everything else in this flow: same
      // person-as-photo, same one-line body ("one person at a time" —
      // the seriousness principle, never a quota), same Guardian
      // disclosure at the exact moment RLS opens to both Guardians.
      // See _InlineBeginConfirm at the bottom of this file.
      setState(() => _beginMatchId = j.matchId);
      return;
    }

    // The cap is full — the tap is really a choice BETWEEN people, and
    // the moment must show them.
    //
    // NO LONGER A POPUP. Founder, 2026-08-12, evening (interactive
    // round, section 4): shown three presentations side by side — B1
    // the transparent glass dialog he'd picked that morning, B2 the
    // same dialog solid pink/purple, B3 the person's card extending
    // with the choice inline — he chose B3: "point 4 do b3". So the
    // tap sets [_takeoverMatchId] and the card itself grows the choice:
    // same parts, same words, same hierarchy as the dialogs it
    // replaces, just rendered where the person already is. Everything
    // else about the moment (which shape shows, what the choices do)
    // lives in _inlineTakeoverFor and _settleTakeover below.
    setState(() => _takeoverMatchId = j.matchId);
  }

  /// The potential row whose card is currently extended with the inline
  /// takeover choice (B3). Null when nobody is mid-decision. Cleared by
  /// Continue / Not now, by settling, and implicitly whenever the row
  /// itself leaves the list — a stale id simply matches nothing.
  String? _takeoverMatchId;

  /// The potential row whose card is currently extended with the inline
  /// BEGIN confirm (below the cap — 2026-08-13, the flow's last popup
  /// retired). Same lifecycle as [_takeoverMatchId]; the two are never
  /// set together, because one tap picks exactly one branch.
  String? _beginMatchId;

  /// The one extension a potential card can carry: the begin confirm if
  /// this row is mid-confirm, else the takeover if it is mid-takeover,
  /// else nothing.
  Widget? _inlinePotentialFor(JourneyMatch j) {
    if (_beginMatchId == j.matchId) {
      return _InlineBeginConfirm(
        next: j,
        onDismiss: () => setState(() => _beginMatchId = null),
        onBegin: () => _confirmBegin(j),
      );
    }
    return _inlineTakeoverFor(j);
  }

  /// The begin, confirmed inline. Mirrors what the dialog's "Begin with
  /// X" did — a staged potential "begins" in the scenario's numbers (no
  /// row exists for the real promote to act on); a real one promotes.
  Future<void> _confirmBegin(JourneyMatch j) async {
    setState(() => _beginMatchId = null);
    if (j.isMock) {
      final dev = ZyraDevScenario.instance;
      dev.setQueuedJourneys((dev.queuedJourneys - 1).clamp(0, 99));
      dev.setActiveJourneys(dev.activeJourneys + 1);
      return;
    }
    await _promote(j);
  }

  /// Builds the inline takeover for [j], or null when its card isn't the
  /// one deciding. Blocking is re-read at build time so the extension
  /// always reflects the CURRENT actives — if they resolved meanwhile
  /// (ended elsewhere, scenario recomposed), the extension disappears
  /// and the next Begin tap walks the plain path.
  ///
  /// ONE blocking Journey gets B1's shape exactly; SEVERAL (a full ZYRA
  /// One) get the C1 chooser's, resolving to the same decision plus the
  /// person it applies to — both inline since "point 4 do b3".
  Widget? _inlineTakeoverFor(JourneyMatch j) {
    if (_takeoverMatchId != j.matchId) return null;
    final blocking = AppState.instance.activeJourneys
        .where((a) => a.matchId != j.matchId && !a.isSuspended)
        .toList();
    if (blocking.isEmpty) return null;
    void dismiss() => setState(() => _takeoverMatchId = null);
    if (blocking.length == 1) {
      final other = blocking.first;
      return _InlineTakeover(
        active: other,
        next: j,
        onDismiss: dismiss,
        onChoice: (choice) => _settleTakeover(j, choice, other),
      );
    }
    return _InlineTakeoverChooser(
      actives: blocking,
      next: j,
      onDismiss: dismiss,
      onChoice: (choice, other) => _settleTakeover(j, choice, other),
    );
  }

  /// Settle the chosen active Journey (pause or end), then begin with
  /// [j] — settle-then-start, the same order the dialogs enforced,
  /// because promoteToActive refuses while any unsuspended Active
  /// Journey holds the slot.
  ///
  /// PAUSE IS REAL HERE, not advice: the pause_frees_active_slot
  /// migrations (20260812144437 + 144851) made a paused Journey release
  /// its slot, and journey suite section J (checks 68-71) holds it —
  /// pause with one person, begin with another, resume refused by name
  /// while the second runs, resume clean after it ends.
  ///
  /// A STAND-IN settles in the scenario's numbers, not the database: the
  /// staged Active count drops by one and the Paused/Ended count rises,
  /// so the list re-composes showing exactly what the choice meant. One
  /// honest limitation, accepted 2026-08-12: fakes are positional (the
  /// generator re-deals names by index), so with SEVERAL staged actives
  /// the row that disappears may not carry the name that was tapped —
  /// with one staged active, the common solo case, it is exact.
  Future<void> _settleTakeover(
    JourneyMatch j,
    _TakeoverChoice choice,
    JourneyMatch other,
  ) async {
    setState(() => _takeoverMatchId = null);
    final dev = ZyraDevScenario.instance;
    switch (choice) {
      case _TakeoverChoice.continueCurrent:
        return; // the inline widgets never emit this; enum exhaustiveness
      case _TakeoverChoice.pauseAndBegin:
        if (other.isMock) {
          dev.setActiveJourneys((dev.activeJourneys - 1).clamp(0, 99));
          dev.setPausedJourneys(dev.pausedJourneys + 1);
        } else {
          try {
            await ZyraJourneyService.suspendJourney(other.matchId);
          } on PausedLimitReachedException {
            if (!mounted) return;
            await showZyraPausedLimitRefusal(context);
            return;
          } on SuspensionRequiresOneException {
            // Only against an un-migrated database — degrade, don't crash.
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Journey Suspension requires ZYRA One.'),
              ),
            );
            return;
          } catch (_) {
            // BUG-04 (OA-ZYRA-225, 2026-08-15): an unexpected failure no
            // longer sails on into _promote — the settle didn't happen,
            // so beginning would be refused server-side anyway. Say so
            // and stop; nothing has changed.
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Pause didn't go through — check your connection and try again.",
                ),
              ),
            );
            return;
          }
        }
      case _TakeoverChoice.endAndBegin:
        if (other.isMock) {
          dev.setActiveJourneys((dev.activeJourneys - 1).clamp(0, 99));
          dev.setEndedJourneys(dev.endedJourneys + 1);
        } else {
          // Truthful-end rule (2026-08-15, OA-ZYRA-225): a failed end
          // stops the takeover here rather than letting _promote be
          // refused for a slot that was never freed.
          final ok = await ZyraJourneyService.endJourney(other.matchId);
          if (!ok) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "End didn't go through — check your connection and try again.",
                ),
              ),
            );
            return;
          }
        }
    }
    if (!mounted) return;
    if (j.isMock) {
      // The new Journey is itself a stand-in: "promote" it in the staged
      // numbers and stop — there is no row for JourneyFlowScreen to read.
      dev.setQueuedJourneys((dev.queuedJourneys - 1).clamp(0, 99));
      dev.setActiveJourneys(dev.activeJourneys + 1);
      return;
    }
    await _refresh();
    if (!mounted) return;
    await _promote(j);
  }

  Future<void> _promote(JourneyMatch j) async {
    try {
      final ok = await ZyraJourneyService.promoteToActive(j.matchId);
      await _refresh();
      if (!mounted) return;
      if (ok) {
        // E2 — Journey Begins (DR-ZYRA-147): the threshold from choice
        // to commitment, and the honest moment to restate that both
        // Guardians can now read the conversation. Plays before the
        // flow opens; tapping through lands in Compatibility Reveal.
        await showZyraMoment(
          context,
          pairWith: j.profile,
          lines: [
            ZyraMomentLine.heading(
              'Your Journey with ${j.profile.firstName} begins.',
            ),
            const ZyraMomentLine.body(
              'One person. Both families present. Step by step.',
            ),
            ZyraMomentLine.quiet(
              'From the first message, your linked Guardian — and '
              "${j.profile.firstName}'s — can read the conversation.",
            ),
            const ZyraMomentLine.body('It opens with Compatibility Reveal.'),
          ],
          ctaLabel: 'Begin',
        );
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
          ),
        );
      }
    } on OneActiveJourneyLimitException {
      if (!mounted) return;
      // Plan-aware since 2026-08-12: "already have AN Active Journey"
      // stopped being the whole truth the day ZYRA One's cap became 3.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You're at your plan's Active Journey limit. End or pause one before starting another.",
          ),
        ),
      );
    } finally {
      // The 'Starting…' in-flight label died with the trailing pills
      // (2026-08-12, Activity-model rewire): the verb now lives inside
      // the expansion and the card collapses on tap, so there is no
      // button left to disable. promote itself refuses a double-fire —
      // the second call finds the match no longer 'potential'.
    }
  }

  /// The one-shot nudge (DR-ZYRA-142). One per pause episode; the row's
  /// button greys via pause_nudged_at on the refetch, so there is no
  /// local state to hold. A stand-in nudges in the scenario (Founder,
  /// 2026-08-12: the dev snackbar that used to sit here was the panel
  /// refusing to rehearse the experience it exists to rehearse) — the
  /// marked id survives recompose and the button greys identically.
  Future<void> _nudge(JourneyMatch j) async {
    if (j.isMock) {
      ZyraDevScenario.instance.markFakeNudged(j.matchId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Continue requested. Waiting for ${j.profile.firstName}.',
          ),
        ),
      );
      return;
    }
    final ok = await ZyraJourneyService.nudgePausedJourney(j.matchId);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Continue requested. Waiting for ${j.profile.firstName}.'
              : "That didn't go through. Pull down to refresh and try again.",
        ),
      ),
    );
  }

  /// DR-ZYRA-170: the non-holder rests too. Same server verb — the
  /// server mirrors when the other side already holds — so the plan-cap
  /// refusals arrive through the same doors as any pause.
  Future<void> _alsoPause(JourneyMatch j) async {
    if (j.isMock) {
      // A staged mirror flips the first paused-by-them stand-in to
      // paused-by-both — positional, the same accepted limitation as
      // the takeover's settle; exact in the common solo case.
      final dev = ZyraDevScenario.instance;
      dev.setMirroredPaused(dev.mirroredPaused + 1);
      return;
    }
    try {
      await ZyraJourneyService.suspendJourney(j.matchId);
    } on PausedLimitReachedException {
      // A mirror is YOUR hold and counts toward your plan's 5/10 —
      // ratified with the shared-holds design; the refusal is the
      // honest one every pause gets.
      if (!mounted) return;
      await showZyraPausedLimitRefusal(context);
      return;
    } on SuspensionRequiresOneException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journey Suspension requires ZYRA One.')),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Pause didn't go through — check your connection and try again.",
          ),
        ),
      );
      return;
    }
    await _refresh();
  }

  /// DR-ZYRA-170: this LIFTS THE CALLER'S OWN HOLD — nothing more. Only
  /// when it was the last hold does the Journey go active, so the flow
  /// screen opens only if the refreshed row is genuinely running again.
  /// A non-final lift stays right here: the card re-reads "Paused by
  /// X — she knows you're ready", which is the whole message.
  Future<void> _resumeSuspended(JourneyMatch j) async {
    if (j.isMock) {
      // Stand-ins settle in the scenario's numbers. A both-held fake
      // drops back to paused-by-them (my hand lifted, theirs stands); a
      // sole-hold fake resumes into the Active count. Also fixes a
      // latent pre-170 crash: this method had no mock branch at all, so
      // Resume on a stand-in reached the real RPC.
      final dev = ZyraDevScenario.instance;
      if (j.pausedByBoth) {
        dev.setMirroredPaused((dev.mirroredPaused - 1).clamp(0, 99));
      } else {
        dev.setPausedJourneys((dev.pausedJourneys - 1).clamp(0, 99));
        dev.setActiveJourneys(dev.activeJourneys + 1);
      }
      return;
    }
    try {
      await ZyraJourneyService.resumeJourney(j.matchId);
    } on SelfInActiveJourneyException {
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You're at your plan's Active Journey limit, so this one stays "
            "paused. Pause or end an Active Journey first — nothing here is lost.",
          ),
        ),
      );
      return;
    } on OtherPartyInActiveJourneyException {
      // OA-ZYRA-164, DR-ZYRA-121 item 12. The old copy — "it has now
      // ended" — was accurate at the time: the server really did end the
      // Journey underneath the person pressing Resume. It no longer does,
      // so the message must not imply a loss that has not happened.
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "They're in another Journey right now, so this one stays paused. "
            "Nothing has been lost. You can resume when they're ready.",
          ),
        ),
      );
      return;
    } on NotEligibleToContinueException {
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This Journey can't continue right now.")),
      );
      return;
    } catch (_) {
      // DR-ZYRA-167's rule: an unknown failure says so and changes
      // nothing — the hold it failed to lift is still shown held.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "That didn't go through — check your connection and try again.",
          ),
        ),
      );
      return;
    }
    await _refresh();
    if (!mounted) return;
    final fresh = await ZyraJourneyService.refetchOne(j.matchId, j.profile.id);
    if (!mounted) return;
    if (fresh != null && fresh.status == 'active' && !fresh.isSuspended) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
        ),
      );
    }
  }

  /// Ends a paused Journey — CONFIRMED FIRST since 2026-08-12, because
  /// its only entry point is now the "End Journey" pill on the person's
  /// card (the old three-button paused dialog, which WAS the
  /// confirmation, died with the Option A row-tap model). Short and
  /// in the takeover popups' language: what it costs, what is kept.
  /// INLINE since 2026-08-13, round four (Founder: "we are agreeing
  /// popups now in connections page no longer exist and is all
  /// expanded") — the tap swaps the paused card's rows for the confirm,
  /// under the ✕ header. _doEndSuspended finishes the job.
  Future<void> _endSuspended(JourneyMatch j) async {
    setState(() => _endConfirmMatchId = j.matchId);
  }

  /// The paused row whose card currently shows the inline End confirm.
  String? _endConfirmMatchId;

  Widget? _inlineEndConfirmFor(JourneyMatch j) {
    if (_endConfirmMatchId != j.matchId) return null;
    return _InlineConfirmBlock(
      title: 'End with ${j.profile.firstName}?',
      body: 'Permanent. Your Timeline together is kept.',
      actionLabel: 'End Journey',
      danger: true,
      onConfirm: () => _doEndSuspended(j),
      dismissLabel: 'Keep it',
      onDismiss: _clearInlineDecisions,
    );
  }

  Future<void> _doEndSuspended(JourneyMatch j) async {
    _clearInlineDecisions();
    if (j.isMock) {
      // A stand-in ends in the scenario's numbers, like every other
      // stand-in action on this screen — AND plays the closure moment,
      // because solo testing must rehearse the real experience.
      final dev = ZyraDevScenario.instance;
      dev.setPausedJourneys((dev.pausedJourneys - 1).clamp(0, 99));
      dev.setEndedJourneys(dev.endedJourneys + 1);
      await _endedMoment(j);
      return;
    }
    // Same truthful-end rule as _doEndActive: no closure moment for an
    // end that didn't happen (2026-08-15, OA-ZYRA-225).
    final ok = await ZyraJourneyService.endJourney(j.matchId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "End didn't go through — check your connection and try again.",
          ),
        ),
      );
      return;
    }
    await _endedMoment(j);
    await _refresh();
  }

  /// E4 — the closure moment (DR-ZYRA-147), shared by every End on this
  /// page. The keepsake promise said at the exact second loss is felt.
  /// NOT shown on the takeover's End-and-begin path: there the new
  /// beginning is the story, and stacking closure onto it would break
  /// the no-stacked-moments rule.
  Future<void> _endedMoment(JourneyMatch j) async {
    if (!mounted) return;
    await showZyraMoment(
      context,
      closure: true,
      lines: [
        const ZyraMomentLine.heading('This chapter closes.'),
        const ZyraMomentLine.body(
          'Ended by choice, with dignity — the way these things '
          'should end.',
        ),
        ZyraMomentLine.body(
          'Everything you and ${j.profile.firstName} built is kept. '
          'Your Timeline, your words, your story.',
        ),
        const ZyraMomentLine.quiet('Take your time.'),
      ],
      ctaLabel: 'Return to Journeys',
    );
  }

  /// Every inline decision, cleared at once. Only one is ever open —
  /// one tap opens one moment — so this is exact, and it lets a single
  /// ✕ handler serve every card.
  void _clearInlineDecisions() => setState(() {
    _beginMatchId = null;
    _takeoverMatchId = null;
    _restartMatchId = null;
    _endConfirmMatchId = null;
    _activeConfirm = null;
  });

  /// Which Active Journey card is mid-confirm, and which confirm.
  /// The record beats two string fields: one card, one open moment.
  ({String matchId, bool end})? _activeConfirm;

  /// Founder-selected Connections Option 4 — 2026-08-20.
  ///
  /// The Active card keeps one clear primary action and one compact rail:
  /// View Profile · Timeline · Options. Options groups the two management
  /// actions without weakening their safeguards: choosing Pause or End here
  /// only closes the sheet and opens the existing inline confirmation. No
  /// service write happens from this sheet.
  Future<void> _showActiveJourneyOptions(JourneyMatch j) async {
    final choice = await showModalBottomSheet<_ActiveJourneyOption>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (sheetContext) =>
          _ActiveJourneyOptionsSheet(firstName: j.profile.firstName),
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case _ActiveJourneyOption.pause:
        await _pauseActive(j);
        break;
      case _ActiveJourneyOption.end:
        await _endActive(j);
        break;
    }
  }

  /// Pause the ACTIVE Journey — the Journey screen's ⋮ verb, relocated
  /// 2026-08-13, and INLINE the same day, round four (Founder: "now
  /// pause journey for active journey is a popup… popups now in
  /// connections page no longer exist"): the tap extends the card with
  /// the confirm; _doPauseActive finishes.
  Future<void> _pauseActive(JourneyMatch j) async {
    setState(() => _activeConfirm = (matchId: j.matchId, end: false));
  }

  /// End the ACTIVE Journey — same relocation, same inline round.
  Future<void> _endActive(JourneyMatch j) async {
    setState(() => _activeConfirm = (matchId: j.matchId, end: true));
  }

  /// The Active card's inline confirm, or null when this card isn't
  /// mid-confirm. Same words the glass dialogs carried.
  Widget? _activeInlineConfirmFor(JourneyMatch j) {
    final c = _activeConfirm;
    if (c == null || c.matchId != j.matchId) return null;
    if (c.end) {
      return _InlineConfirmBlock(
        title: 'End with ${j.profile.firstName}?',
        body: 'Permanent. Your Timeline together is kept.',
        actionLabel: 'End Journey',
        danger: true,
        onConfirm: () => _doEndActive(j),
        dismissLabel: 'Keep it',
        onDismiss: _clearInlineDecisions,
      );
    }
    return _InlineConfirmBlock(
      title: 'Pause with ${j.profile.firstName}?',
      body:
          '${_keepsPlaceLine(j.profile)} '
          "${ZyraGender.subject(j.profile.gender, capitalized: true)}'ll see the "
          'Journey is paused.',
      actionLabel: 'Pause Journey',
      danger: false,
      onConfirm: () => _doPauseActive(j),
      dismissLabel: 'Not now',
      onDismiss: _clearInlineDecisions,
    );
  }

  Future<void> _doPauseActive(JourneyMatch j) async {
    if (j.isMock) {
      _clearInlineDecisions();
      // A staged Active pauses in the scenario's numbers, like every
      // other stand-in action on this screen.
      final dev = ZyraDevScenario.instance;
      dev.setActiveJourneys((dev.activeJourneys - 1).clamp(0, 99));
      dev.setPausedJourneys(dev.pausedJourneys + 1);
      return;
    }
    // BUG-04 (2026-08-14 audit, OA-ZYRA-225 — fixed 2026-08-15): the
    // confirm is no longer cleared BEFORE the outcome is known. The two
    // recognised refusals below still clear it — the server answered,
    // just with no. An UNEXPECTED failure keeps the confirm open and
    // says so: the tap didn't happen, so the card shouldn't pretend the
    // question was answered.
    try {
      await ZyraJourneyService.suspendJourney(j.matchId);
    } on PausedLimitReachedException {
      // The plan-cap REFUSAL stays a dialog, deliberately — it is the
      // server saying no after the choice, not a choice; flagged in the
      // round-four mock and accepted.
      if (!mounted) return;
      _clearInlineDecisions();
      await showZyraPausedLimitRefusal(context);
      return;
    } on SuspensionRequiresOneException {
      // Only against an un-migrated database — degrade, don't crash.
      if (!mounted) return;
      _clearInlineDecisions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journey Suspension requires ZYRA One.')),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Pause didn't go through — check your connection and try again.",
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    _clearInlineDecisions();
    await _refresh();
  }

  Future<void> _doEndActive(JourneyMatch j) async {
    _clearInlineDecisions();
    if (j.isMock) {
      final dev = ZyraDevScenario.instance;
      dev.setActiveJourneys((dev.activeJourneys - 1).clamp(0, 99));
      dev.setEndedJourneys(dev.endedJourneys + 1);
      await _endedMoment(j);
      return;
    }
    // BUG-04 companion (2026-08-15): endJourney reports failure now.
    // The E4 closure moment only plays for an end that actually
    // happened — "This chapter closes" over a still-running Journey
    // was the worst sentence this bug could produce.
    final ok = await ZyraJourneyService.endJourney(j.matchId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "End didn't go through — check your connection and try again.",
          ),
        ),
      );
      return;
    }
    await _endedMoment(j);
    await _refresh();
  }

  // ── THE PERSON ROWS — the Activity model, everywhere ────────────────
  //
  // Founder, 2026-08-12 (third round of the person-surface work): "i
  // admit for activity i like the rows design but in the journey section
  // its not quite there yet so remove the sheet option and do rows where
  // it expands… take the activity section how it expands and copy that
  // model." So: ONE pattern for every person on this page. The sheet
  // (concept 1) and the chips panel are gone; _JourneyExpandingCard below
  // is _ActivityCard's ratified expansion — collapsed thumbnail row with
  // a chevron, tap → the mini profile (photo pager, dots, scrim, name)
  // with the state's verbs beneath — carrying Journey actions instead of
  // moves. No trailing pills on headers anymore; the arrow is the whole
  // invitation, exactly like Activity.

  void _pushTimeline(JourneyMatch j) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JourneyTimelineScreen(
          withProfile: j.profile,
          isMock: j.isMock,
          // The road needs a position (2026-08-13 — the Map lives
          // in the Timeline's rail now). Null for potential rows,
          // which is right: no Journey, no road position yet.
          journeyStage: j.journeyStage,
        ),
      ),
    );
  }

  Future<void> _reportPerson(JourneyMatch j) async {
    await showReportProfileSheet(
      context,
      profileId: j.profile.id,
      firstName: j.profile.firstName,
      source: ZyraReportSource.connections,
    );
    if (mounted) await _refresh();
  }

  // _barPill REMOVED 2026-08-13 (DR-ZYRA-160). Its only caller was the
  // introduction profile's action bar, which left the same day — the
  // three decisions now sit on the card, drawn by _CardAction like every
  // other action in this file. A second pill style for the same three
  // choices was part of why they read as two features.

  /// The primary verb for a Journey person, or null when the state offers
  /// none (busy elsewhere, or the one nudge already spent).
  ({String label, String? caption, Future<void> Function() run})? _personHero(
    JourneyMatch j,
  ) {
    if (j.status == 'potential') {
      if (j.inAnotherJourney) return null;
      // NO CAPTION — 2026-08-13 (ChatGPT card review, Founder
      // approved): "one person at a time, with both families present"
      // explained the system rather than the person. A Potential card
      // is already a choice about whether to begin; the verb says the
      // rest. The seriousness of beginning is still stated, once, at
      // the moment it matters — the begin confirm.
      // 'Begin Journey', not 'Begin with Amina' — 2026-08-15 (Founder,
      // DR-ZYRA-172: "WHEN THEY FIRST MATCH MAKE SURE ITS BEGIN JOURNEY
      // AND ONCE BEGUN THE PILL SHOWS CONTINUE JOURNEY"). This
      // supersedes the 2026-08-13 named-verb wording and completes the
      // pair: Begin Journey → Continue Journey, the same noun both
      // times. The person's name still leads the card and the begin
      // confirm ("Begin with Yusuf?") keeps naming them at the moment
      // of commitment.
      return (
        label: 'Begin Journey',
        caption: null,
        run: () async => _startJourney(j),
      );
    }
    if (j.status == 'ended') {
      final mayAsk =
          !j.inAnotherJourney &&
          j.isWithinNewJourneyRequestWindow &&
          (j.isMock ? j.canRestart : _mayRequest.contains(j.matchId));
      if (!mayAsk) return null;
      // 2026-08-13 (Founder): the verb names what the tap actually
      // does — it ASKS. "Restart" promised a restart the presser cannot
      // give. The caption that carried that meaning is gone with it;
      // the ask itself still says both must agree, in the extension
      // this opens.
      return (
        label: 'Request New Journey',
        caption: null,
        run: () => _requestNewJourney(j),
      );
    }
    // SHARED PAUSE HOLDS — DR-ZYRA-170 (2026-08-15), SUPERSEDING the
    // 2026-08-13 one-label ruling ("Request Resume" on both sides).
    // That fix made the BUTTONS equal while the machinery stayed
    // unequal — one resumed instantly, the other sent a one-shot note
    // whose spent state read "— she decides". Under shared holds the
    // verb names what the tap does and nobody requests anything: a
    // HOLDER lifts their own pause here; a NON-HOLDER answers through
    // the neutral pair (pairHero at the call site), so this returns
    // null for them.
    final me = ZyraAuth.currentUser?.id;
    final iHold = j.heldBy(me);
    // Busy elsewhere: with BOTH hands holding, my lift is never the
    // final one (theirs stands), so it is always safe. A SOLE hold's
    // lift would try to activate and be refused by name (suite section
    // J) — no verb, the fact says why.
    if (j.inAnotherJourney && !(iHold && j.pausedByBoth)) return null;
    if (!iHold) return null;
    return (
      label: 'Resume Journey',
      caption: null,
      run: () => _resumeSuspended(j),
    );
  }

  /// The state's standing fact when there is no hero: busy elsewhere, the
  /// spent nudge, or the cooling period.
  String? _personHeroFact(JourneyMatch j) {
    // Paused rows keep status 'active' (suspended_by is what parks
    // them), so `status != 'active'` alone silently excluded exactly
    // the paused-but-busy case the Founder asked to see (2026-08-13).
    if (j.inAnotherJourney && (j.status != 'active' || j.isSuspended)) {
      return '${j.profile.firstName} is in a Journey with someone else '
          'right now.';
    }
    if (j.status == 'ended' && j.isInCoolingPeriod) {
      return j.restartAvailableIn;
    }
    if (j.status == 'ended' && !j.isWithinNewJourneyRequestWindow) {
      return 'The 60-day request window has ended.';
    }
    // SHARED PAUSE HOLDS — DR-ZYRA-170. The line this replaces read
    // "Restart requested — Amina decides." — the sentence that proved
    // the Founder's whole point (wrong word AND named the power
    // imbalance out loud). The facts below say only what is true, in
    // nobody's favour.
    if (j.isSuspended && !j.inAnotherJourney) {
      final name = j.profile.firstName;
      final subject = ZyraGender.subject(j.profile.gender, capitalized: true);
      if (j.pausedByBoth) {
        return 'Paused by both of you — continues when you’ve both resumed.';
      }
      if (j.heldBy(ZyraAuth.currentUser?.id)) {
        return j.pauseNudgedAt != null
            ? '$name is ready when you are.'
            : 'Your pause is yours — resuming continues for you both.';
      }
      return j.pauseNudgedAt != null
          ? '$subject knows you’re ready — or rest too, or simply wait.'
          : 'How you answer — or whether you answer — is yours.';
    }
    return null;
  }

  /// A Guardian Suggestion's profile: the read-only screen with the three
  /// decisions as its bar (ascending commitment, Consider furthest right —
  /// the same order the Activity cards ratified on 2026-08-03).
  /// Opens the introduced person's profile, read-only.
  ///
  /// NO CHIP, NO ACTION BAR — 2026-08-13 (DR-ZYRA-160, Founder). Both
  /// left in the same change and for one reason: the decisions moved to
  /// the CARD, where Pass, Save and Consider now sit under View Profile.
  /// Having them in both places meant the same three choices rendered
  /// two different ways, one screen apart.
  ///
  /// The "Introduced by X" chip in the top right became a "Suggested by
  /// X" line under the name — same fact, said where the person is
  /// rather than in the corner of their photo, and with the same shield
  /// glyph the Connections card uses for it.
  void _openSuggestionProfile(GuardianSuggestion s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SeekerProfileScreen(profile: s.profile, suggestedBy: s.suggestedBy),
      ),
    );
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
      decoration: BoxDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Connections', style: ZyraText.heading(size: 26)),
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
              // Shared with the Guardian's Network tab since 2026-08-13
              // — same widget, same behaviour, different labels.
              child: ZyraSegmentedToggle(
                labels: _kSegmentLabels,
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
                    children: _journeysChildren(
                      active: active,
                      potential: potential,
                    ),
                  ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: _activityChildren(
                      considered: considered,
                      saved: saved,
                      passed: passed,
                    ),
                  ),
                  // CENTRED WHEN EMPTY — 2026-08-13 (Founder: "the
                  // Introductions empty state icon and text placement do
                  // not match other empty states... the Notifications
                  // empty state is centred").
                  //
                  // ZyraEmptyState was always centred; it had nothing to
                  // centre IN. Inside a ListView it takes only the height
                  // of its own content and sits wherever the previous
                  // child left off, so it read as pinned under the
                  // header. Notifications puts it in an Expanded, which
                  // is what makes Center mean anything — same here now.
                  !_suggestionsLoaded
                      ? const ZyraLoading()
                      : _undecidedSuggestions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Same header the populated state draws, so
                              // the section does not appear to lose its
                              // name when it empties.
                              Text(
                                'INTRODUCTIONS',
                                style: ZyraText.chapterLabel(
                                  color: Colors.white54,
                                ),
                              ),
                              const Expanded(
                                child: ZyraEmptyState(
                                  icon: Icons.groups_outlined,
                                  // The Notifications pattern: state
                                  // first, then the fact.
                                  title: 'No introductions yet',
                                  // Honest. There is still no
                                  // Guardian-side UI to create one, so
                                  // this list is empty in practice, not
                                  // only in a new account.
                                  message:
                                      'People your Guardian puts forward will appear here.',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
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

  /// Developer Active previews used to look fully interactive and then stop
  /// at the door with a bottom snackbar because their fake match id had no
  /// server row. A developer tool must never create that trap. If an old
  /// preview card survives a hot reload, entering it now finds or seeds a
  /// real walkable Journey and opens that instead.
  Future<void> _enterJourney(JourneyMatch selected) async {
    var target = selected;
    String? seedResult;
    if (selected.isMock) {
      try {
        var rows = await ZyraJourneyService.fetchJourneyMatches(
          statuses: const ['active'],
        );
        var live = rows
            ?.where((journey) => !journey.isMock && !journey.isSuspended)
            .toList();
        if (live == null || live.isEmpty) {
          seedResult = await ZyraJourneyService.devSeedJourney();
          rows = await ZyraJourneyService.fetchJourneyMatches(
            statuses: const ['active'],
          );
          live = rows
              ?.where((journey) => !journey.isMock && !journey.isSuspended)
              .toList();
        }
        if (live == null || live.isEmpty) {
          if (!mounted) return;
          await showZyraMoment(
            context,
            mark: Icons.cloud_off_outlined,
            lines: [
              const ZyraMomentLine.heading('Journey unavailable'),
              ZyraMomentLine.body(
                seedResult ??
                    'A live test Journey could not be created for this account.',
              ),
              const ZyraMomentLine.quiet(
                'Open the developer panel and choose Open live Journey to try again.',
              ),
            ],
            ctaLabel: 'Back to Connections',
          );
          return;
        }
        target = live.first;
        ZyraDevScenario.instance.refreshJourneys();
      } catch (error) {
        debugPrint('ZYRA dev Journey entry failed — $error');
        if (!mounted) return;
        await showZyraMoment(
          context,
          mark: Icons.cloud_off_outlined,
          lines: const [
            ZyraMomentLine.heading('Journey unavailable'),
            ZyraMomentLine.body(
              'The live test Journey could not be opened. Check the connection and try again.',
            ),
          ],
          ctaLabel: 'Back to Connections',
        );
        return;
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            JourneyFlowScreen(matchId: target.matchId, profile: target.profile),
      ),
    );
  }

  List<Widget> _journeysChildren({
    required List<JourneyMatch> active,
    required List<JourneyMatch> potential,
  }) {
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
      // the card itself (_ActiveJourneyCard — brighter fill, real
      // border, larger photo), NOT by a new accent colour. Introducing
      // one here would collide with the gender gradient behind it.
      Text('ACTIVE JOURNEY', style: ZyraText.chapterLabel(color: Colors.white)),
      const SizedBox(height: 8),
      if (active.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraEmptyState(
            icon: Icons.forum_outlined,
            message: 'Start a Journey to see it here.',
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
          return _ActiveJourneyCard(
            profile: j.profile,
            onEnter: () => unawaited(_enterJourney(j)),
            onTimeline: () => Navigator.of(context).push(
              MaterialPageRoute(
                // isMock: a dev stand-in has no match row; the screen
                // says so instead of showing an empty story that reads
                // as a bug (Founder, 2026-08-12). journeyStage feeds
                // the Timeline's road (2026-08-13).
                builder: (_) => JourneyTimelineScreen(
                  withProfile: j.profile,
                  isMock: j.isMock,
                  journeyStage: j.journeyStage,
                ),
              ),
            ),
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
            // THE ⋮'S VERBS, RELOCATED HERE — 2026-08-13 (Founder:
            // "remove it.. put it in main page section"). View Profile
            // was the Timeline bubble's job until today; the bubble
            // stays, but the person is one tap from the card now too.
            onViewProfile: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SeekerProfileScreen(profile: j.profile),
              ),
            ),
            onOptions: () => _showActiveJourneyOptions(j),
            // Round four: the confirms extend this card in place —
            // no popups on this page.
            inlineConfirm: _activeInlineConfirmFor(j),
            onDismissConfirm: _clearInlineDecisions,
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
            // hasBegun REINSTATED 2026-08-15 (DR-ZYRA-174, superseding
            // 173 same day). The Founder's screenshot settled the rule:
            // an Active Journey STILL AT ITS FIRST STAGE reads "Begin
            // Journey" — Begin holds right up until the Journey itself
            // moves, and "Continue Journey" from then on. Read off the
            // stage: one source of truth, no opened-flag to maintain.
            hasBegun: j.journeyStage != ZyraJourneyStages.all.first.value,
          );
        }),

      const SizedBox(height: 20),
      // RENAMED 2026-08-03, Founder approved: "Potential Journeys"
      // suggested uncertainty, when these are confirmed mutual likes
      // waiting for the user to begin. "Queue" also carries the
      // one-Active-Journey-at-a-time rule without stating it — things in
      // a queue are waiting their turn by definition.
      Text(
        'POTENTIAL JOURNEYS',
        style: ZyraText.chapterLabel(color: Colors.white54),
      ),
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
            message:
                "Your matches will appear here when you're ready to begin.",
          ),
        )
      else
        ...potential.map(
          (j) => _JourneyExpandingCard(
            j: j,
            // "In another Journey": beginning would be refused (the
            // server's other-party cap guard), so the card states it and
            // offers no verb — a fact, never a disabled button.
            subtitle: j.inAnotherJourney
                ? 'In another Journey right now'
                : 'Ready to start',
            hero: _personHero(j),
            heroFact: _personHeroFact(j),
            // The person and the actions, nothing else. When there IS
            // no verb (busy elsewhere) _personHeroFact still speaks —
            // that line is the reason, not an explanation.
            showStateLine: _personHeroFact(j) != null,
            showTimeline: false,
            onTimeline: null,
            canEnd: false,
            onEnd: null,
            onReport: () => _reportPerson(j),
            // B3: when this row is the one mid-decision — begin
            // confirm below the cap, takeover at it — its card
            // extends with that moment (null for everyone else).
            inlineExtension: _inlinePotentialFor(j),
            onDismissExtension: _clearInlineDecisions,
          ),
        ),

      // PAUSED JOURNEYS — 2026-07-29: renamed from "Suspended" (matches
      // the Journey Pause naming used everywhere else, DR-ZYRA-119) and
      // now ALWAYS rendered with its own empty state instead of only
      // appearing once non-empty, so the section is actually
      // discoverable (Founder, Connections review). Basic Seekers can
      // still land here as the non-initiating party of a Journey a ZYRA
      // One partner paused (JOURNEY_SUSPENSION (CURRENT_VERSION)) —
      // this isn't ZYRA-One-only data, so no tier gate on the section.
      const SizedBox(height: 20),
      Text(
        'PAUSED JOURNEYS',
        style: ZyraText.chapterLabel(color: Colors.white54),
      ),
      const SizedBox(height: 8),
      if (_suspended.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraEmptyState(
            icon: Icons.pause_circle_outlined,
            message: 'Paused Journeys will appear here.',
          ),
        )
      else
        ..._suspended.map((j) {
          // SHARED PAUSE HOLDS — DR-ZYRA-170 (2026-08-15): a pause is a
          // personal hold; either party may hold; each lifts only their
          // own. A HOLDER gets the Resume hero; a NON-HOLDER gets the
          // neutral pair (Pause too | Request Continue) — and waiting, which
          // needs no button, stays a legitimate answer.
          final me = ZyraAuth.currentUser?.id;
          final iHold = j.heldBy(me);
          // DR-ZYRA-142 time-honesty: after 30 days the row says how long,
          // on both sides. A mirror, not a deadline — the system never
          // ends what people haven't (DR-ZYRA-121 item 12).
          final pausedFor = j.pausedFor;
          return _JourneyExpandingCard(
            j: j,
            subtitle:
                (j.pausedByBoth
                    ? 'Paused by both of you'
                    : iHold
                    ? 'Paused by you'
                    : 'Paused by ${j.profile.firstName}') +
                (pausedFor.isEmpty ? '' : ' · $pausedFor') +
                (j.inAnotherJourney ? ' · in another Journey' : ''),
            // The non-holder's answer surface. Busy elsewhere hides the
            // ready-note (asking for what cannot happen yet — the same
            // reasoning that hid the old nudge) but keeps Pause too:
            // adding your own hold is always legal.
            pairHero: iHold
                ? null
                : (
                    left: 'Pause too',
                    onLeft: () => _alsoPause(j),
                    right: (j.pauseNudgedAt == null && !j.inAnotherJourney)
                        ? 'Request Continue'
                        : null,
                    onRight: (j.pauseNudgedAt == null && !j.inAnotherJourney)
                        ? () => _nudge(j)
                        : null,
                    rightDone: j.pauseNudgedAt != null
                        ? 'Continue requested'
                        : null,
                  ),
            // The verbs live in the expansion now (Founder: "no text
            // anymore, it's got an arrow like in activity"). Paused-by-
            // them wording per the interactive round: "Request restart",
            // used once, becomes the fact "Restart requested" (nudged is
            // read inside _personHero/_personHeroFact).
            hero: _personHero(j),
            heroFact: _personHeroFact(j),
            // Speaks only when there is something the verb cannot say —
            // the spent ask, or busy elsewhere. Never the subtitle again.
            showStateLine: _personHeroFact(j) != null,
            showTimeline: true,
            onTimeline: () => _pushTimeline(j),
            canEnd: true,
            onEnd: () => _endSuspended(j),
            onReport: () => _reportPerson(j),
            // Their Journey began — the reveal already happened
            // (2026-08-13: "View Compatibility", never "Unlock", here).
            compatibilityRevealed: true,
            // Round four: End confirms inline in this card.
            inlineExtension: _inlineEndConfirmFor(j),
            onDismissExtension: _clearInlineDecisions,
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
      Text(
        'ENDED JOURNEYS',
        style: ZyraText.chapterLabel(color: Colors.white54),
      ),
      const SizedBox(height: 8),
      if (_ended.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraEmptyState(
            icon: Icons.history,
            message: 'Ended Journeys will appear here.',
          ),
        )
      else ...[
        // ── A DISPLAY CAP, AND ONLY A DISPLAY CAP. Founder, 2026-08-09:
        // "The cap is purely a UI cap, not a data-retention cap. I never
        // want Journey history deleted automatically."
        //
        // 1 on Basic, 5 on ZYRA One — most recent first, since _refresh()
        // already sorts descending by endedAt. `_ended` keeps every row, so
        // nothing here loses data and a Journey History screen can read the
        // full list whenever it is built.
        //
        // This is the ONLY one of the four Journey limits the client
        // enforces, precisely because it is not really a limit. Active,
        // Potential and Paused are entitlements and belong to the database
        // — see data/zyra_entitlements.dart.
        ..._ended.take(_endedShown).map((j) {
          // Whether New Journey may be requested is computed in _personHero:
          // stand-ins from their own canRestart (fake ids were never sent
          // to the server, so _mayRequest cannot hold them), real rows
          // from the server's list, busy people never.
          return _JourneyExpandingCard(
            j: j,
            subtitle: j.inAnotherJourney
                ? 'Ended · in another Journey now'
                : j.canRestart
                ? 'Ended'
                : 'Ended — ${j.restartAvailableIn.toLowerCase()}',
            hero: _personHero(j),
            heroFact: _personHeroFact(j),
            // Speaks only for the cooling period or busy elsewhere.
            showStateLine: _personHeroFact(j) != null,
            showTimeline: true,
            onTimeline: () => _pushTimeline(j),
            canEnd: false,
            onEnd: null,
            onReport: () => _reportPerson(j),
            dimmed: true,
            // Ended Journeys began once too — the reveal is theirs
            // for good (2026-08-13).
            compatibilityRevealed: true,
            // The restart ask extends THIS card inline (2026-08-13,
            // "like we did for potential") — null for every row but
            // the one mid-ask.
            inlineExtension: _inlineRestartFor(j),
            onDismissExtension: _clearInlineDecisions,
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
  /// THE SUBTITLE IS GONE — 2026-08-13 (DR-ZYRA-157, Founder: "remove
  /// this subtitle completely. The section should not explain what
  /// introductions are"). No other section on this page explains itself;
  /// CONSIDERED, SAVED and PASSED carry a header and nothing else, and a
  /// line of instruction under one of four headers is the thing that
  /// looked out of place.
  ///
  /// The empty case is NOT here — see the Introductions page below. It
  /// needs the full height to centre in, which a list of children cannot
  /// give it.
  List<Widget> _introductionsChildren() {
    final pending = _undecidedSuggestions;
    return [
      Text(
        'INTRODUCTIONS (${pending.length})',
        style: ZyraText.chapterLabel(color: Colors.white54),
      ),
      const SizedBox(height: 10),
      // ONE CARD, ALL FOUR SECTIONS — 2026-08-13 (Founder: "a user cannot
      // tell that Introductions cards were built separately from the
      // newer profile cards"). _SuggestionCard is gone; this is the same
      // _ActivityCard that Considered, Saved and Passed use, with the
      // introduction kind.
      //
      // Pass/Save/Consider still do not appear on it — see _moveRow. You
      // have not seen this person yet, and deciding from a thumbnail is
      // exactly what ZYRA is not. The three decisions live on the profile
      // this opens (2026-08-12 rerouting), which is where there is
      // something to decide from.
      ...pending.map(
        (s) => _ActivityCard(
          profile: s.profile,
          kind: _ActivityKind.introduction,
          onViewProfile: () => _openSuggestionProfile(s),
        ),
      ),
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
      Text(
        'CONSIDERED (${considered.length})',
        style: ZyraText.chapterLabel(color: Colors.white54),
      ),
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
            message: "Profiles you've considered will appear here.",
          ),
        )
      else
        ...considered.map(
          (p) => _ActivityCard(profile: p, kind: _ActivityKind.considered),
        ),

      // SAVED.
      const SizedBox(height: 28),
      Text(
        'SAVED (${saved.length})',
        style: ZyraText.chapterLabel(color: Colors.white54),
      ),
      const SizedBox(height: 10),
      if (saved.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraEmptyState(
            icon: Icons.bookmark_border,
            message: "Profiles you've saved will appear here.",
          ),
        )
      else
        ...saved.map(
          (p) => _ActivityCard(profile: p, kind: _ActivityKind.saved),
        ),

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
      Builder(
        builder: (context) {
          final recentPassed = passed.length > 10
              ? passed.sublist(passed.length - 10)
              : passed;
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
                    message: "Profiles you've passed will appear here.",
                  ),
                )
              else
                // Passed cards use the same expanded compatibility action as
                // Considered and Saved. See APP/Premium/Profile Unlocks/
                // Summary.md; the older prohibition was reversed.
                ...recentPassed.map(
                  (p) => _ActivityCard(profile: p, kind: _ActivityKind.passed),
                ),
            ],
          );
        },
      ),
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

// _SegmentedToggle and _UnseenDot MOVED 2026-08-13 to
// widgets/zyra_segmented_toggle.dart as ZyraSegmentedToggle. The Guardian's
// Network tab needed the same control and could not reach a private class,
// so it had grown its own pair of plain rounded buttons — one job, two
// looks. Every design note that used to sit here moved with the code.

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
// ZyraCardMetrics MOVED to theme/zyra_card_metrics.dart — 2026-08-15
// (DR-ZYRA-171, audit UI-03). Four screens were importing THIS 4,000-line
// file to reach three constants; a design token lives in the theme. The
// doc comment travelled with it, values unchanged, and every former
// `show ZyraCardMetrics` importer now imports the theme file directly.

/// A profile thumbnail that survives a profile with no photos.
///
/// ADDED 2026-08-13 (DR-ZYRA-157) and it is the precondition for
/// everything else in that decision. `SeekerProfile.photoUrl` is
/// `photos.first` and THROWS on an empty list, and _ActivityCard called
/// it unguarded — collapsed thumb and expanded hero both. That is the
/// reason the Introductions card was built as its own widget on
/// 2026-08-05 rather than reusing this one: "_ActivityCard's photo fills
/// the row, so a profile without photos became a full-height grey
/// rectangle (the Founder's screenshot)".
///
/// Fixing the cause is what lets the two cards become one. It also
/// closes a latent crash that was only ever hidden by real profiles
/// happening to carry photos — the dev panel's no-pool stand-ins are
/// built with `photos: const []`, and so is every counterpart card.
Widget _cardThumb(SeekerProfile p, {required double size, double radius = 0}) {
  final child = p.photos.isEmpty
      ? ColoredBox(
          color: Colors.white.withValues(alpha: 0.08),
          child: Icon(
            Icons.person_outline,
            color: Colors.white.withValues(alpha: 0.35),
            size: size * 0.4,
          ),
        )
      : ZyraProfileImage(p.photoUrl, width: size, height: size);
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox(width: size, height: size, child: child),
  );
}

/// INTRODUCTION JOINED 2026-08-13 (DR-ZYRA-157, Founder: "a user cannot
/// tell that Introductions cards were built separately from the newer
/// profile cards"). It is a full member — same card, same expansion,
/// same photo handling — and differs only in which actions it offers,
/// which is a rule rather than a style: you have not seen this person
/// yet, so the card cannot ask you to decide about them.
enum _ActivityKind { considered, saved, passed, introduction }

// _SuggestionCard REMOVED 2026-08-13 (DR-ZYRA-157, Founder: "a user
// cannot tell that Introductions cards were built separately from the
// newer profile cards"). Introductions now use _ActivityCard with the
// introduction kind.
//
// ITS TWO REASONS FOR EXISTING, AND WHAT HAPPENED TO THEM. The class
// header argued both, on 2026-08-05:
//
//   VISUAL — "_ActivityCard's photo fills the row, so a profile without
//   photos became a full-height grey rectangle (the Founder's
//   screenshot)". TRUE AT THE TIME AND STILL TRUE THIS MORNING:
//   _ActivityCard called photoUrl (= photos.first) unguarded on the
//   thumb, and indexed photos[clamp(0, -1)] on the hero — the first
//   throws on an empty list, the second fails on the clamp. Both are
//   fixed now (_cardThumb, and the hero's own guard), which is what made
//   the merge safe rather than a re-run of that screenshot. The fix also
//   closes a latent crash that only ever stayed hidden because real
//   profiles happen to carry photos.
//
//   BEHAVIOURAL — "the others show things you have already decided on
//   and can move between lists; this is someone you have never seen".
//   STILL TRUE, AND STILL HONOURED. It is a rule about ACTIONS, not
//   about style: _moveRow gives the introduction kind one button, View
//   Profile, and no decisions. The card looks like its neighbours and
//   behaves like itself.
//
// Deleted rather than left unused — an unreferenced widget is one
// somebody re-adds a call to six weeks later without reading why it
// stopped being used.

/// What a move button does. Consider and pass are decisions; save and
/// unsave are bookmark operations. See _ActivityCardState._move.
enum _Move { consider, pass, save, unsave }

class _ActivityCard extends StatefulWidget {
  final SeekerProfile profile;
  final _ActivityKind kind;

  // NO `suggestedBy` PARAMETER. The card already draws "Suggested by X"
  // from AppState.suggestedBy(), populated for pending introductions by
  // _loadSuggestions() — the line was added on 2026-08-05 so a Guardian's
  // involvement survives into whichever list the person ends up in, and
  // it works here unchanged. Passing the name in again would be a second
  // source for one fact.

  /// Opens the read-only profile — introductions only.
  final VoidCallback? onViewProfile;

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
    this.onViewProfile,
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
    // BUG-02 (2026-08-14 audit, OA-ZYRA-225 — fixed 2026-08-15): the
    // record calls report failure now instead of swallowing it. The
    // AppState change stays — same optimistic-with-honesty ruling as
    // Browse — and a retry is just the same move again (all three
    // writes are idempotent upserts). Stand-ins have no row to write;
    // the guard keeps them off the persistence path, so a staged move
    // keeps behaving exactly as before.
    final persistable = ZyraReportService.isPersistableId(p.id);
    var ok = true;
    switch (move) {
      case _Move.consider:
        app.like(p);
        if (persistable) ok = await ZyraDiscoveryService.recordLike(p.id);
      case _Move.pass:
        app.decline(p);
        if (persistable) ok = await ZyraDiscoveryService.recordPass(p.id);
      case _Move.save:
        app.save(p);
        if (persistable) ok = await ZyraDiscoveryService.recordSave(p.id);
      case _Move.unsave:
        app.unsave(p);
        if (persistable) await ZyraDiscoveryService.removeSave(p.id);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "That move didn't save — check your connection and try it again.",
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
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
    // AN INTRODUCTION OFFERS ONE ACTION, AND THAT IS A RULE RATHER THAN
    // A STYLE. The card now looks exactly like its neighbours — same
    // shell, same expansion, same photos — but Pass/Save/Consider stay
    // off it, because this is someone you have NOT SEEN. Deciding from
    // a thumbnail is precisely what ZYRA is not, and the three
    // decisions live on the profile screen this button opens, where
    // there is something to decide from (2026-08-12 rerouting).
    //
    // So the visual separation the Founder objected to is gone and the
    // behavioural separation, which he did not, is kept.
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

    final row = Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: actions[i]),
        ],
      ],
    );

    // AN INTRODUCTION GETS ALL THREE, UNDER VIEW PROFILE — 2026-08-13
    // (DR-ZYRA-160, Founder: "below view profile add 3 new widgets, pass
    // save consider").
    //
    // THIS REVERSES A RULE, and the reversal is the Founder's: since
    // 2026-08-05 the card deliberately offered no decisions, because
    // "you have not seen this person yet, and deciding from a thumbnail
    // is exactly what ZYRA is not". The decisions lived on the profile
    // screen instead. They have now moved BACK here, and off that screen
    // in the same change — so there is still exactly one place to decide
    // from, it is just this one.
    //
    // The three come from the list above rather than being written out
    // again: an introduction is in none of the three lists, so all three
    // conditions pass and it gets Pass, Save and Consider. They cannot
    // drift from the versions Considered, Saved and Passed draw, because
    // they ARE those versions.
    //
    // _move() needs no special case either. It writes through AppState,
    // _undecidedSuggestions filters on exactly those three lists, and
    // this screen listens to AppState — so deciding on an introduction
    // removes it from Introductions on the next frame, with nothing to
    // refresh by hand.
    if (widget.kind == _ActivityKind.introduction) {
      return Column(
        children: [
          _CardAction(
            icon: Icons.arrow_forward,
            label: 'View Profile',
            onTap: widget.onViewProfile,
          ),
          const SizedBox(height: 8),
          row,
        ],
      );
    }

    return row;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: _cardKey,
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _open
              ? Colors.white.withValues(alpha: 0.13)
              : ZyraColors.iconButtonBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _open
                ? Colors.white.withValues(alpha: 0.24)
                : ZyraColors.iconButtonBorder,
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
                        _cardThumb(
                          widget.profile,
                          size: ZyraCardMetrics.thumb,
                          radius: ZyraCardMetrics.thumbRadius,
                        ),
                        const SizedBox(width: ZyraCardMetrics.gap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      // An introduction may arrive without
                                      // an age; ", 0" is worse than the
                                      // name alone.
                                      widget.profile.age > 0
                                          ? '${widget.profile.firstName}, ${widget.profile.age}'
                                          : widget.profile.firstName,
                                      style: ZyraText.body(
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // (see the Guardian line below the Row)
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
                              if (AppState.instance.suggestedBy(
                                    widget.profile.id,
                                  ) !=
                                  null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
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
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white38,
                          size: 20,
                        ),
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
                crossFadeState: _open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
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
                                  // GUARDED 2026-08-13: on an empty photo
                                  // list this read `photos[clamp(0, -1)]`,
                                  // which fails on the clamp before it
                                  // ever reaches the index. Same honest
                                  // placeholder the thumb uses, at hero
                                  // scale.
                                  child: widget.profile.photos.isEmpty
                                      ? ColoredBox(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          child: Icon(
                                            Icons.person_outline,
                                            color: Colors.white.withValues(
                                              alpha: 0.35,
                                            ),
                                            size: 56,
                                          ),
                                        )
                                      : ZyraProfileImage(
                                          widget.profile.photos[_photoIndex
                                              .clamp(
                                                0,
                                                widget.profile.photos.length -
                                                    1,
                                              )],
                                        ),
                                ),
                              ),
                              // Bottom scrim so the name stays legible on
                              // a pale photo — same problem the sheets
                              // have, same solution.
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
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
                                      children: List.generate(
                                        widget.profile.photos.length,
                                        (i) {
                                          final active = i == _photoIndex;
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 3,
                                            ),
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                                width: 0.5,
                                              ),
                                              color: active
                                                  ? Colors.white
                                                  : Colors.white.withValues(
                                                      alpha: 0.32,
                                                    ),
                                            ),
                                          );
                                        },
                                      ),
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
                                    // THE SHARED BLOCK — DR-ZYRA-163.
                                    // Was "Arif, 36" over a pin icon and
                                    // a city; now the same widget Browse
                                    // draws, at card scale. The comma
                                    // and the pin were this card's own
                                    // invention, not a decision.
                                    ZyraProfileNameBlock(
                                      profile: widget.profile,
                                      nameSize: 20,
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
                              icon: _viewable
                                  ? Icons.visibility_outlined
                                  : Icons.insights_outlined,
                              label: _viewable
                                  ? 'View Compatibility'
                                  : 'Compatibility Unlock',
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProfileUnlockScreen(
                                      profile: widget.profile,
                                    ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 6,
                            ),
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

/// THE JOURNEY PERSON CARD — _ActivityCard's expansion model carrying
/// Journey verbs (Founder, 2026-08-12, third person-surface round: "take
/// the activity section how it expands and copy that model").
///
/// The thumbnail, name, state and chevron remain the card's single identity
/// header while closed and open. Expansion adds only the state's verb — with
/// the small flag Report beside it at the same 85/15 split — followed by the
/// full-width Profile, Compatibility and optional Timeline/End rows. States
/// with no verb (busy elsewhere, the spent nudge, the cooling period) show the
/// honest fact in the verb's place instead of a disabled button.
///
/// The scroll-into-view mechanics, durations and layout constants are
/// _ActivityCard's, copied to the value — two expanding cards on one page
/// must move identically or the copy reads as a knock-off.
class _JourneyExpandingCard extends StatefulWidget {
  final JourneyMatch j;
  final String subtitle;
  final ({String label, String? caption, Future<void> Function() run})? hero;
  final String? heroFact;
  final bool showTimeline;
  final VoidCallback? onTimeline;
  final bool canEnd;
  final VoidCallback? onEnd;
  final VoidCallback onReport;
  final bool dimmed;

  /// When non-null this card is mid-decision and extends inline (B3,
  /// Founder pick 2026-08-12: "point 4 do b3"; widened 2026-08-13 to the
  /// restart ask — "we changed the ui to give notification like we did
  /// for potential"): the action rows step aside and this widget renders
  /// beneath the persistent identity header. Potential rows receive the
  /// takeover (_inlineTakeoverFor); Ended rows receive the restart ask
  /// (_inlineRestartFor). Never both, never elsewhere.
  final Widget? inlineExtension;

  /// True for Paused and Ended rows — pairs whose Journey BEGAN, which
  /// opens with Compatibility Reveal. Their button always reads "View
  /// Compatibility" (Founder, 2026-08-13: "its not compatibility unlock.
  /// because they already unlocked") and the report opens without a
  /// purchase, via ProfileUnlockScreen's journeyRevealed door.
  final bool compatibilityRevealed;

  /// The ✕ in the extension header (2026-08-13 round four). Every site
  /// passes the parent's clear-everything dismiss — only one decision is
  /// ever open, so clearing all of them is exact, not sloppy.
  final VoidCallback? onDismissExtension;

  /// False on Potential rows only (2026-08-13): the expanded card drops
  /// the small state line above the verb. Everywhere else it carries a
  /// fact the verb cannot say by itself — why Restart is offered, what
  /// Resume will do, why there is no verb at all — so it stays. Nothing
  /// replaces it here; the freed height goes to the photo/verb gap.
  final bool showStateLine;

  /// THE NEUTRAL PAIR — DR-ZYRA-170 (2026-08-15, shared pause holds).
  /// On a Journey paused by the OTHER person, the verb seat holds two
  /// equal half-pills instead of one hero: "Pause too" and
  /// "Request Continue"
  /// — the two ways to answer a pause, at the same visual weight,
  /// because neither is the expected one (waiting, which needs no
  /// button, is an answer too). [right] null with [rightDone] set shows
  /// the spent ready-note as a quiet fact; both null (busy elsewhere)
  /// leaves Pause too standing alone. Exclusive with [hero].
  final ({
    String left,
    Future<void> Function() onLeft,
    String? right,
    Future<void> Function()? onRight,
    String? rightDone,
  })?
  pairHero;

  const _JourneyExpandingCard({
    required this.j,
    required this.subtitle,
    required this.hero,
    required this.heroFact,
    required this.showTimeline,
    required this.onTimeline,
    required this.canEnd,
    required this.onEnd,
    required this.onReport,
    this.dimmed = false,
    this.inlineExtension,
    this.compatibilityRevealed = false,
    this.onDismissExtension,
    this.showStateLine = true,
    this.pairHero,
  });

  @override
  State<_JourneyExpandingCard> createState() => _JourneyExpandingCardState();
}

class _JourneyExpandingCardState extends State<_JourneyExpandingCard> {
  bool _open = false;
  final GlobalKey _cardKey = GlobalKey();

  static const Duration _kExpandAnim = Duration(milliseconds: 200);

  SeekerProfile get _p => widget.j.profile;

  /// Activity's rule, verbatim: unlocked at EITHER tier and the button
  /// reads "View Compatibility" for good (2026-08-03 Founder ruling —
  /// returning never consumes another unlock).
  bool get _viewable =>
      ZyraUnlockService.isUnlocked(_p.id, UnlockTier.standard) ||
      ZyraUnlockService.isUnlocked(_p.id, UnlockTier.plus);

  @override
  void didUpdateWidget(covariant _JourneyExpandingCard old) {
    super.didUpdateWidget(old);
    // The extension lands right after the hero tap collapsed the card
    // (the hero's onTap closes before running the verb) — reopen so the
    // choice is actually visible, and bring it into view. Both setStates
    // happen in the same frame, so no collapse is ever painted.
    if (widget.inlineExtension != null && old.inlineExtension == null) {
      _open = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollIntoView());
      Future.delayed(_kExpandAnim + const Duration(milliseconds: 40), () {
        if (mounted) _scrollIntoView();
      });
    }
  }

  void _scrollIntoView() {
    final ctx = _cardKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.0,
    );
  }

  void _expand() {
    setState(() => _open = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollIntoView());
    Future.delayed(_kExpandAnim + const Duration(milliseconds: 40), () {
      if (mounted) _scrollIntoView();
    });
  }

  void _toggleOpen() {
    if (_open) {
      setState(() => _open = false);
      return;
    }
    _expand();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.dimmed && !_open ? 0.65 : 1,
      child: Padding(
        key: _cardKey,
        padding: const EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _open
                ? Colors.white.withValues(alpha: 0.13)
                : ZyraColors.iconButtonBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _open
                  ? Colors.white.withValues(alpha: 0.24)
                  : ZyraColors.iconButtonBorder,
              width: _open ? 1 : 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                // The identity row remains the single person header in both
                // states. Expanding reveals only Journey controls below it,
                // so the photo, name and state are never repeated.
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _toggleOpen,
                  child: Padding(
                    padding: const EdgeInsets.all(ZyraCardMetrics.padding),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            ZyraCardMetrics.thumbRadius,
                          ),
                          child: _p.photos.isEmpty
                              ? Container(
                                  width: ZyraCardMetrics.thumb,
                                  height: ZyraCardMetrics.thumb,
                                  color: Colors.white.withValues(alpha: 0.22),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _p.firstName.isEmpty
                                        ? '?'
                                        : _p.firstName[0],
                                    style: ZyraText.heading(size: 16),
                                  ),
                                )
                              : ZyraProfileImage(
                                  _p.photoUrl,
                                  width: ZyraCardMetrics.thumb,
                                  height: ZyraCardMetrics.thumb,
                                ),
                        ),
                        const SizedBox(width: ZyraCardMetrics.gap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_p.firstName}, ${_p.age}',
                                style: ZyraText.body(
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.subtitle,
                                style: ZyraText.subtext(size: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          duration: _kExpandAnim,
                          turns: _open ? 0.5 : 0,
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: _kExpandAnim,
                  crossFadeState: _open
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mid-decision keeps one reflex exit before the inline
                        // confirmation. Identity remains in the persistent
                        // card header above, so it is not repeated here.
                        if (widget.inlineExtension != null) ...[
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: widget.onDismissExtension,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          const SizedBox(height: 12),
                          widget.inlineExtension!,
                        ],
                        // MID-DECISION the card IS the dialog: the rows
                        // step aside while the extension (rendered with
                        // the ✕ header above) holds the moment.
                        if (widget.inlineExtension == null) ...[
                          // Extra state context appears only when the verb
                          // cannot say the full truth by itself. Potential
                          // rows suppress it; their persistent header already
                          // says they are ready to start.
                          if (widget.showStateLine) ...[
                            const SizedBox(height: 10),
                            Text(
                              widget.heroFact ??
                                  widget.hero?.caption ??
                                  widget.subtitle,
                              style: ZyraText.subtext(
                                size: 10.5,
                                color: const Color(0x8CFFFFFF),
                              ),
                            ),
                          ],
                          // THE VERB ROW — Activity's 85/15 split, with
                          // the Journey verb in the big seat. A FILLED
                          // LAVENDER PILL since 2026-08-13 (Founder: "its
                          // a more meaningful button so pill should be
                          // different") — the one control on the card
                          // that moves the Journey, visually above the
                          // flat look-at rows and apart from coral End.
                          SizedBox(height: widget.showStateLine ? 8 : 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 85,
                                // DR-ZYRA-170: paused-by-them rows carry
                                // the neutral pair in this seat; the card
                                // stays OPEN through both taps so the
                                // state change is watched, not implied.
                                child: widget.pairHero != null
                                    ? _PairHero(pair: widget.pairHero!)
                                    : widget.hero != null
                                    ? _HeroPill(
                                        label: widget.hero!.label,
                                        onTap: () {
                                          setState(() => _open = false);
                                          widget.hero!.run();
                                        },
                                      )
                                    : Material(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 8,
                                          ),
                                          child: Center(
                                            child: Text(
                                              widget.heroFact ??
                                                  'Nothing to do right now',
                                              textAlign: TextAlign.center,
                                              style: ZyraText.subtext(size: 11),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 15,
                                child: _FlagAction(onTap: widget.onReport),
                              ),
                            ],
                          ),
                          // VIEW PROFILE, ON EVERY STATE — 2026-08-13
                          // (Founder: "Potential, Paused and Ended
                          // Journeys should all have a View Profile
                          // action… available consistently"). First of
                          // the look-at rows, deliberately: the person,
                          // then the fit (Compatibility), then the story
                          // (Timeline). Same full screen the Active
                          // card's pill opens.
                          const SizedBox(height: 8),
                          _JourneyCardAction(
                            label: 'View Profile',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SeekerProfileScreen(profile: _p),
                              ),
                            ),
                          ),
                          // COMPATIBILITY, ON EVERY JOURNEY CARD — Founder,
                          // 2026-08-12: "what if its ended or paused but
                          // they paid for profile unlock where can they
                          // view" / "if its potential and they wanna now
                          // pay for profile unlock then what".
                          //
                          // AMENDED 2026-08-13: on Paused and Ended it is
                          // ALWAYS "View Compatibility" ("its not
                          // compatibility unlock. because they already
                          // unlocked") — a Journey opens with
                          // Compatibility Reveal, so the overall figure
                          // is already theirs and the screen opens
                          // through its journeyRevealed door, no
                          // purchase. Potential is the only state that
                          // can still read "Compatibility Unlock", and
                          // only until unlocked at either tier.
                          const SizedBox(height: 8),
                          _JourneyCardAction(
                            label: widget.compatibilityRevealed || _viewable
                                ? 'View Compatibility'
                                : 'Compatibility Unlock',
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfileUnlockScreen(
                                    profile: _p,
                                    journeyRevealed:
                                        widget.compatibilityRevealed,
                                  ),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                          if (widget.showTimeline &&
                              widget.onTimeline != null) ...[
                            const SizedBox(height: 8),
                            _JourneyCardAction(
                              label: 'Timeline',
                              onTap: widget.onTimeline,
                            ),
                          ],
                          if (widget.canEnd && widget.onEnd != null) ...[
                            const SizedBox(height: 8),
                            // A PILL, NOT SMALL PRINT — Founder,
                            // 2026-08-12: "for paused i dont like end
                            // journey being so small, maybe give it a
                            // pill also". Full width per his A1 pick.
                            //
                            // 2026-08-13 twice more: the label is "End
                            // Journey" EVERYWHERE (naming-consistency
                            // ruling — "End this Journey" retired), and
                            // the contrast fix — a dark under-fill in
                            // the app's dark-chip tone, outline and text
                            // lifted — so the pill holds its own on the
                            // gradient's pink stop. Still an OUTLINE
                            // destructive; never a solid coral fill.
                            SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: const Color(0x48140C1A),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: _takeoverCoral.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                                child: InkWell(
                                  customBorder: const StadiumBorder(),
                                  onTap: () {
                                    setState(() => _open = false);
                                    widget.onEnd!();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 11,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'End Journey',
                                          style: ZyraText.body(
                                            size: 12.5,
                                            color: const Color(0xFFF0A2A0),
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                          color: _takeoverCoral.withValues(
                                            alpha: 0.78,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Center(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => setState(() => _open = false),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 26,
                                  vertical: 6,
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 22,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The former expanded portrait/photo pager was retired on 2026-08-20. The
// compact identity header now remains visible while open, and the expansion is
// reserved for Journey controls only.

/// The Journey verb — Begin / Resume / Restart / Request restart — as the
/// FROST PRIMARY: Continue Journey's exact recipe (white 22% fill, white
/// 42% border), because the Founder named that pill his favourite and
/// asked every primary Journey action to follow it (2026-08-13,
/// primary-button-consistency ruling — this RETIRES the same-day lavender
/// fill after one day; his call, both days). The hierarchy still reads:
/// frost pill acts on the Journey, flat rows look at things
/// (View Profile, Compatibility, Timeline), coral outline ends things.
class _HeroPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HeroPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.42), width: 1),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.button(size: 12.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two half-pills at equal weight — DR-ZYRA-170's answer surface for a
/// pause you didn't place. Same frost as _HeroPill, deliberately: both
/// responses act on the Journey, and neither outranks the other. The
/// spent ready-note renders as the same quiet box the no-verb states
/// use, so "they already know" reads as a fact, not a disabled button.
class _PairHero extends StatelessWidget {
  final ({
    String left,
    Future<void> Function() onLeft,
    String? right,
    Future<void> Function()? onRight,
    String? rightDone,
  })
  pair;
  const _PairHero({required this.pair});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeroPill(label: pair.left, onTap: () => pair.onLeft()),
        ),
        if (pair.right != null || pair.rightDone != null)
          const SizedBox(width: 6),
        if (pair.right != null)
          Expanded(
            child: _HeroPill(
              label: pair.right!,
              onTap: () => pair.onRight?.call(),
            ),
          )
        else if (pair.rightDone != null)
          Expanded(
            child: Material(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Center(
                  child: Text(
                    '✓ ${pair.rightDone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZyraText.subtext(size: 11),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The compact open row used only inside Potential, Paused and Ended Journey
/// expansions. It keeps the action name left-aligned and the direction cue at
/// the far edge, matching the approved Connections treatment without changing
/// the shared action component used by Activity or Introductions.
class _JourneyCardAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _JourneyCardAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tint = Colors.white.withValues(alpha: onTap == null ? 0.35 : 0.82);
    return Material(
      color: Colors.white.withValues(alpha: 0.035),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.17)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 11),
          child: Row(
            children: [
              Text(label, style: ZyraText.body(size: 11.5, color: tint)),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: tint.withValues(alpha: 0.55),
              ),
            ],
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

  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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

  /// ACTIVE CARD ACTIONS — revised by the Founder on 2026-08-20 with
  /// Connections Option 4. Continue remains the primary action; View Profile,
  /// Timeline and Options form one compact open rail. Options groups Pause and
  /// End, while the existing inline confirmations still own the consequential
  /// decision. Report remains the always-visible flag on the person.
  final VoidCallback onViewProfile;
  final VoidCallback onOptions;
  final bool reviewOpen;

  /// INLINE CONFIRMS — 2026-08-13, round four ("popups now in
  /// connections page no longer exist and is all expanded"). When
  /// non-null the pill bands step aside and this confirm takes their
  /// place; a ✕ appears by the photo (which shrinks to 56pt — this
  /// card's portrait is small and part of who the card is, so it stays,
  /// unlike the expanding cards').
  final Widget? inlineConfirm;
  final VoidCallback? onDismissConfirm;

  /// The current Journey stage, from the canonical map. Rendered on the Enter
  /// pill, not as a status line — Timeline spec §12 option C, Founder
  /// 2026-08-10.
  /// True once the Journey has moved past its opening stage. Drives the
  /// primary pill's wording — Begin vs Continue — and nothing else
  /// (DR-ZYRA-174).
  final bool hasBegun;

  const _ActiveJourneyCard({
    required this.profile,
    required this.onEnter,
    required this.onTimeline,
    required this.onReport,
    required this.onViewProfile,
    required this.onOptions,
    required this.reviewOpen,
    required this.hasBegun,
    this.inlineConfirm,
    this.onDismissConfirm,
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
                    // Mid-confirm: the ✕ leads, the photo makes room.
                    if (inlineConfirm != null) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onDismissConfirm,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    // PLAIN PHOTO. The expand glyph that briefly sat in this
                    // corner was rejected by the Founder on 2026-08-10 — a
                    // small icon on someone's face, doing something the icon
                    // does not name.
                    //
                    // The photo is NOT tappable either. An invisible tap
                    // target is worse than the glyph was: it is a feature
                    // only the person who built it knows about. Full profile
                    // entry is labelled: the View Profile pill below (the
                    // Timeline bubble it replaced retired 2026-08-13).
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ZyraProfileImage(
                        profile.photoUrl,
                        width: inlineConfirm != null ? 56 : 96,
                        height: inlineConfirm != null ? 56 : 96,
                      ),
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
                          Text(
                            profile.firstName,
                            style: ZyraText.heading(size: 19),
                          ),
                          // surnameLine is a display string, not a lastName —
                          // it may already carry "middle name + surname"
                          // together (models/seeker_profile.dart). Rendered
                          // whole, never split.
                          if ((profile.surnameLine ?? '').trim().isNotEmpty)
                            Text(
                              profile.surnameLine!.trim(),
                              style: ZyraText.heading(
                                size: 15,
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            '${profile.age} · ${profile.city}',
                            style: ZyraText.subtext(
                              size: 12.5,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                          if (reviewOpen) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.34),
                                  width: 0.6,
                                ),
                              ),
                              // THE ONE MAP, still. familyReviewOverride is
                              // the same string the Journey itself shows —
                              // no second wording was invented here
                              // (DR-ZYRA-129).
                              child: Text(
                                ZyraJourneyStages.familyReviewOverride,
                                style: ZyraText.subtext(
                                  size: 11,
                                  color: Colors.white,
                                ),
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
                // MID-CONFIRM the bands step aside and the confirm
                // holds the card (round four — no popups on this page).
                if (inlineConfirm != null) ...[
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  const SizedBox(height: 12),
                  inlineConfirm!,
                ] else ...[
                  // CONNECTIONS OPTION 4 — Founder, 2026-08-20. One primary
                  // Journey action, then a compact open rail for the three
                  // secondary destinations. Report remains the flag above;
                  // Pause and End sit behind Options and still open their
                  // existing inline confirmation before any write.
                  _CardPill(
                    label: hasBegun ? 'Continue Journey' : 'Begin Journey',
                    onTap: onEnter,
                    primary: true,
                  ),
                  const SizedBox(height: 10),
                  _ActiveJourneyActionRail(
                    onViewProfile: onViewProfile,
                    onTimeline: onTimeline,
                    onOptions: onOptions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveJourneyActionRail extends StatelessWidget {
  final VoidCallback onViewProfile;
  final VoidCallback onTimeline;
  final VoidCallback onOptions;

  const _ActiveJourneyActionRail({
    required this.onViewProfile,
    required this.onTimeline,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: Colors.white.withValues(alpha: 0.14),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActiveJourneyRailAction(
              label: 'View Profile',
              onTap: onViewProfile,
            ),
          ),
          const _ActiveJourneyRailDivider(),
          Expanded(
            child: _ActiveJourneyRailAction(
              label: 'Timeline',
              onTap: onTimeline,
            ),
          ),
          const _ActiveJourneyRailDivider(),
          Expanded(
            child: _ActiveJourneyRailAction(label: 'Options', onTap: onOptions),
          ),
        ],
      ),
    );
  }
}

class _ActiveJourneyRailAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActiveJourneyRailAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZyraText.button(
                size: 11.5,
              ).copyWith(color: Colors.white.withValues(alpha: 0.78)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveJourneyRailDivider extends StatelessWidget {
  const _ActiveJourneyRailDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.6,
      height: 22,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}

enum _ActiveJourneyOption { pause, end }

class _ActiveJourneyOptionsSheet extends StatelessWidget {
  final String firstName;

  const _ActiveJourneyOptionsSheet({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: ZyraColors.sheetGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Journey options', style: ZyraText.heading(size: 22)),
              const SizedBox(height: 5),
              Text(
                'Manage your Journey with $firstName.',
                style: ZyraText.subtext(size: 12),
              ),
              const SizedBox(height: 14),
              _ActiveJourneyOptionRow(
                icon: Icons.pause_rounded,
                label: 'Pause Journey',
                detail: 'Hold your place and continue when you are ready.',
                onTap: () =>
                    Navigator.of(context).pop(_ActiveJourneyOption.pause),
              ),
              _ActiveJourneyOptionRow(
                icon: Icons.close_rounded,
                label: 'End Journey',
                detail: 'Close this Journey permanently. Your Timeline stays.',
                danger: true,
                onTap: () =>
                    Navigator.of(context).pop(_ActiveJourneyOption.end),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: ZyraText.button(
                      size: 12,
                    ).copyWith(color: Colors.white.withValues(alpha: 0.70)),
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

class _ActiveJourneyOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool danger;

  const _ActiveJourneyOptionRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? _takeoverCoral : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: foreground.withValues(alpha: 0.09),
                ),
                child: Icon(icon, size: 18, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ZyraText.body(
                        size: 13,
                      ).copyWith(color: foreground),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: danger
                            ? _takeoverCoral.withValues(alpha: 0.70)
                            : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: foreground.withValues(alpha: 0.72),
              ),
            ],
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

// _JourneyTile DELETED 2026-08-12 — every Journey row now uses
// _JourneyExpandingCard (the Activity model, Founder: "copy that model").
// The header comment at the top of this file still names the old tile in
// its history; the widget itself is in git.
// ═══════════════════════════════════════════════════════════════════════
// The takeover, INLINE — what a tap on "Begin" becomes when the plan's
// Active Journey cap is already full.
//
// A POPUP UNTIL 2026-08-12, EVENING. Founder picked B1 (one blocks) and
// C1 (several block) as glass dialogs earlier that same day, then — shown
// three presentations side by side in the interactive round (B1 the
// glass dialog, B2 the same dialog solid pink/purple, B3 the card itself
// extending) — chose the card: "point 4 do b3". Same parts, same words,
// same hierarchy as the dialogs; only the surface changed. Two knock-ons,
// both deliberate: the dialogs' tap-outside dismissal became a written
// "Not now" (a card extension has no outside), and the person's portrait
// shortens to a strip while the choice is open — the accepted cost of
// fitting the choice where the person already is.
//
// TWO shapes, one set of parts:
//
//   _InlineTakeover (B1's shape, of eleven mockups across three rounds)
//   — ONE Journey blocks. Both people at the top as circular photos
//   ("you're deciding about a person, not a slot"), a one-line body,
//   Continue as the hero out of respect to the active Journey — his
//   word: 'continue', never 'stay' — then Pause and End as square cards.
//
//   _InlineTakeoverChooser (C1's shape, over the two-step C2) — SEVERAL
//   block, which exists since plan_aware_active_journey_limit made ZYRA
//   One's cap of 3 real. The new person waits at the top; the active
//   people are tappable chips; the same square cards re-aim at whoever
//   is chosen and stay dim and inert until someone is.
//
// The avatar and the cards are top-level functions shared by both, so the
// two shapes cannot drift apart. The below-cap Begin confirm is STILL a
// dialog — it was never part of the B1/B2/B3 round.
//
// Three ways out, every one of them honest:
//   Continue / Not now  dismiss — nothing changes, and the caption says so
//   Pause     suspendJourney, then the promote; real since the
//             pause_frees_active_slot migrations (same day)
//   End       endJourney, then the promote; permanent, Timeline kept
// ═══════════════════════════════════════════════════════════════════════

enum _TakeoverChoice { continueCurrent, pauseAndBegin, endAndBegin }

const Color _takeoverCoral = Color(0xFFE08080);

/// One person: circular photo over a "Name · State" caption. photoUrl is
/// photos.first and throws on an empty list — real profiles always carry
/// one, but the dev panel's no-pool stand-ins are built with
/// photos: const [], so an initial in a circle keeps the dialog whole.
Widget _takeoverPerson(SeekerProfile p, String label, {required bool waiting}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Opacity(opacity: waiting ? 0.65 : 1, child: _takeoverAvatar(p, 46)),
      const SizedBox(height: 4),
      Text(
        '${p.firstName} · $label',
        style: ZyraText.subtext(size: 10, color: const Color(0x8CFFFFFF)),
      ),
    ],
  );
}

Widget _takeoverAvatar(SeekerProfile p, double size) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
    ),
    child: ClipOval(
      child: p.photos.isEmpty
          ? Container(
              width: size,
              height: size,
              color: Colors.white.withValues(alpha: 0.22),
              alignment: Alignment.center,
              child: Text(
                p.firstName.isEmpty ? '?' : p.firstName[0],
                style: ZyraText.heading(size: 16),
              ),
            )
          : ZyraProfileImage(p.photoUrl, width: size, height: size),
    ),
  );
}

/// A square Pause/End choice card (B1's body). A null [onTap] renders it
/// dim and inert — the C1 chooser shows the cards before a person is
/// picked, and a card with nobody's name on it must not be pressable.
Widget _takeoverChoiceCard({
  required String title,
  required String sub,
  required bool danger,
  required VoidCallback? onTap,
}) {
  return Opacity(
    opacity: onTap == null ? 0.45 : 1,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: danger
                ? _takeoverCoral.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: ZyraText.button(
                size: 12.5,
              ).copyWith(color: danger ? _takeoverCoral : Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: ZyraText.subtext(size: 10, color: const Color(0x80FFFFFF)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// "He keeps his place" / "She keeps her place" — gender is
/// server-segregated (H1), so the counterpart's is always set; the pronoun
/// keeps the card personal the way the approved mock was.
String _keepsPlaceLine(SeekerProfile p) => ZyraGender.keepsPlaceLine(p.gender);

/// COMPRESSED, NOT DROPPED. The Guardian-visibility disclosure is a
/// 2026-08-01 Founder decision ("stated consistently everywhere"), and
/// every start-shaped popup leads straight to the promote that opens RLS
/// to both Guardians — there is no second confirm behind any of them.
/// One quiet line, identical in the plain start, B1 and C1 dialogs,
/// keeps the disclosure at the moment it matters (the long paragraph
/// retired with the dialog restyle, Founder-directed, 2026-08-12).
Widget _takeoverDisclosure(String nextName) {
  return Text(
    "From the first message, your linked Guardian — and $nextName's — "
    'can read the conversation.',
    textAlign: TextAlign.center,
    style: ZyraText.subtext(size: 10, color: const Color(0x6BFFFFFF)),
  );
}

class _InlineTakeover extends StatelessWidget {
  final JourneyMatch active;
  final JourneyMatch next;
  final VoidCallback onDismiss;
  final void Function(_TakeoverChoice choice) onChoice;
  const _InlineTakeover({
    required this.active,
    required this.next,
    required this.onDismiss,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final activeName = active.profile.firstName;
    final nextName = next.profile.firstName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The leading divider left 2026-08-13 (round four): the card's
        // ✕ header carries the one divider now — extensions start with
        // their content.
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _takeoverPerson(active.profile, 'Active', waiting: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
              child: Icon(
                Icons.swap_horiz,
                size: 18,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            _takeoverPerson(next.profile, 'Waiting', waiting: true),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Begin with $nextName?',
          style: ZyraText.heading(size: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'One Journey at a time — choose what happens with $activeName.',
          style: ZyraText.subtext(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          // Frost primary since 2026-08-13 (the consistency ruling) —
          // Continue = dismiss, exactly as the dialog treated it: the
          // caption below says nothing changes, and nothing does.
          child: _CardPill(
            label: 'Continue with $activeName',
            onTap: onDismiss,
            primary: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nothing changes — carry on where you left off.',
          style: ZyraText.subtext(size: 10, color: const Color(0x6BFFFFFF)),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _takeoverChoiceCard(
                  title: 'Pause with $activeName',
                  sub: _keepsPlaceLine(active.profile),
                  danger: false,
                  onTap: () => onChoice(_TakeoverChoice.pauseAndBegin),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _takeoverChoiceCard(
                  title: 'End with $activeName',
                  sub: 'Permanent. Your Timeline is kept.',
                  danger: true,
                  onTap: () => onChoice(_TakeoverChoice.endAndBegin),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _takeoverDisclosure(nextName),
        // The dialogs could be dismissed by tapping outside; a card
        // extension has no outside, so the way out is written down.
        TextButton(
          onPressed: onDismiss,
          child: Text('Not now', style: ZyraText.subtext()),
        ),
      ],
    );
  }
}

class _InlineTakeoverChooser extends StatefulWidget {
  final List<JourneyMatch> actives;
  final JourneyMatch next;
  final VoidCallback onDismiss;
  final void Function(_TakeoverChoice choice, JourneyMatch other) onChoice;
  const _InlineTakeoverChooser({
    required this.actives,
    required this.next,
    required this.onDismiss,
    required this.onChoice,
  });

  @override
  State<_InlineTakeoverChooser> createState() => _InlineTakeoverChooserState();
}

class _InlineTakeoverChooserState extends State<_InlineTakeoverChooser> {
  /// Nobody is pre-selected, deliberately: pre-picking a person would
  /// nudge toward pausing or ending THEM, and the whole hierarchy of this
  /// dialog is respect for the Journeys already under way. The cards wake
  /// up only once a choice is made.
  JourneyMatch? _selected;

  String get _countWord => switch (widget.actives.length) {
    2 => 'two',
    3 => 'three',
    final n => '$n',
  };

  @override
  Widget build(BuildContext context) {
    final nextName = widget.next.profile.firstName;
    final sel = _selected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The leading divider left 2026-08-13 (round four): the card's
        // ✕ header carries the one divider now — extensions start with
        // their content.
        _takeoverPerson(widget.next.profile, 'Waiting', waiting: true),
        const SizedBox(height: 10),
        Text(
          'Begin with $nextName?',
          style: ZyraText.heading(size: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your $_countWord Journeys are all active — choose who makes '
          'room.',
          style: ZyraText.subtext(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final a in widget.actives)
              InkWell(
                onTap: () => setState(() => _selected = a),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 72,
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: identical(a, sel)
                        ? const Color(0x29CEA2D1)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: identical(a, sel)
                          ? const Color(0xFFCEA2D1)
                          : Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _takeoverAvatar(a.profile, 40),
                      const SizedBox(height: 5),
                      Text(
                        a.profile.firstName,
                        overflow: TextOverflow.ellipsis,
                        style: ZyraText.subtext(
                          size: 10,
                          color: const Color(0x8CFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          // Frost primary since 2026-08-13 (the consistency ruling) —
          // Continue = dismiss: nothing changes, and the caption below
          // says so — exactly how the dialog treated its null.
          child: _CardPill(
            label: 'Continue as things are',
            onTap: widget.onDismiss,
            primary: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.actives.length == 2
              ? 'Both Journeys stay exactly as they are.'
              : 'All $_countWord Journeys stay exactly as they are.',
          style: ZyraText.subtext(size: 10, color: const Color(0x6BFFFFFF)),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _takeoverChoiceCard(
                  title: sel == null
                      ? 'Pause'
                      : 'Pause with ${sel.profile.firstName}',
                  sub: sel == null
                      ? 'Choose someone above first.'
                      : _keepsPlaceLine(sel.profile),
                  danger: false,
                  onTap: sel == null
                      ? null
                      : () =>
                            widget.onChoice(_TakeoverChoice.pauseAndBegin, sel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _takeoverChoiceCard(
                  title: sel == null
                      ? 'End'
                      : 'End with ${sel.profile.firstName}',
                  sub: sel == null
                      ? 'Choose someone above first.'
                      : 'Permanent. Your Timeline is kept.',
                  danger: true,
                  onTap: sel == null
                      ? null
                      : () => widget.onChoice(_TakeoverChoice.endAndBegin, sel),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _takeoverDisclosure(nextName),
        // Same written way out as _InlineTakeover — no outside to tap.
        TextButton(
          onPressed: widget.onDismiss,
          child: Text('Not now', style: ZyraText.subtext()),
        ),
      ],
    );
  }
}

/// The restart ask, inline — the ended card's extension (2026-08-13,
/// Founder: "we changed the ui to give notification like we did for
/// potential"). The COPY IS THE DIALOG'S, unchanged since 2026-08-11:
/// same title, same both-must-agree body, same Send request / Not now
/// pair. Only the surface moved — the ask now happens where the person
/// is, exactly like the takeover, with the same divider-topped extension
/// language. No Guardian disclosure here on purpose: sending a request
/// opens nothing — RLS widens only if they accept and a Journey actually
/// begins, and THAT moment carries the disclosure.
class _InlineRestartAsk extends StatelessWidget {
  final JourneyMatch next;
  final VoidCallback onDismiss;
  final Future<void> Function() onSend;
  const _InlineRestartAsk({
    required this.next,
    required this.onDismiss,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final name = next.profile.firstName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The leading divider left 2026-08-13 (round four): the card's
        // ✕ header carries the one divider now — extensions start with
        // their content.
        const Icon(Icons.restart_alt_outlined, size: 26, color: Colors.white70),
        const SizedBox(height: 10),
        Text(
          'Ask $name to begin a new Journey?',
          style: ZyraText.heading(size: 17),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "They'll be told you asked, and can accept or decline. Nothing "
          'starts unless they agree.\n\nIf they accept, this is a fresh '
          'Journey — a new conversation, from the beginning. Everything '
          'from before is kept, and stays where it is.',
          style: ZyraText.subtext(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          // Frost primary since 2026-08-13 (the consistency ruling).
          child: _CardPill(
            label: 'Send request',
            onTap: () => onSend(),
            primary: true,
          ),
        ),
        // The dialog's dismissal, written down — no outside to tap.
        TextButton(
          onPressed: onDismiss,
          child: Text('Not now', style: ZyraText.subtext()),
        ),
      ],
    );
  }
}

/// The begin confirm, inline — the flow's LAST popup, retired 2026-08-13
/// (Founder: "we agreed we were moving away from popups"). The dialog's
/// exact parts in the card's extension language: the person as a circular
/// photo over 'Ready', the one-line seriousness body, Begin as the frost
/// primary, 'Not yet', and the Guardian disclosure — stated, as always,
/// at the exact moment a Begin would open RLS to both Guardians.
class _InlineBeginConfirm extends StatelessWidget {
  final JourneyMatch next;
  final VoidCallback onDismiss;
  final Future<void> Function() onBegin;
  const _InlineBeginConfirm({
    required this.next,
    required this.onDismiss,
    required this.onBegin,
  });

  @override
  Widget build(BuildContext context) {
    final name = next.profile.firstName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _takeoverPerson(next.profile, 'Ready', waiting: false),
        const SizedBox(height: 12),
        Text(
          'Begin with $name?',
          style: ZyraText.heading(size: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'One person at a time, with both families present — it '
          'begins with Compatibility Reveal.',
          style: ZyraText.subtext(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _CardPill(
            label: 'Begin with $name',
            onTap: () => onBegin(),
            primary: true,
          ),
        ),
        TextButton(
          onPressed: onDismiss,
          child: Text('Not yet', style: ZyraText.subtext()),
        ),
        const SizedBox(height: 2),
        _takeoverDisclosure(name),
      ],
    );
  }
}

/// One confirm, inline — the shape every stay-or-go confirm on this page
/// now takes (round four, 2026-08-13: Pause and End on the Active card,
/// End on a paused card). Title, one honest body line, the action as the
/// app's pill (frost for reversible, the dark-coral End pill for
/// permanent), and the written dismissal underneath. The ✕ in the card's
/// header is the other way out; both do the same nothing.
class _InlineConfirmBlock extends StatelessWidget {
  final String title;
  final String body;
  final String actionLabel;
  final bool danger;
  final Future<void> Function() onConfirm;
  final String dismissLabel;
  final VoidCallback onDismiss;
  const _InlineConfirmBlock({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.danger,
    required this.onConfirm,
    required this.dismissLabel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: ZyraText.heading(size: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(body, style: ZyraText.subtext(), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: danger
              ? Material(
                  color: const Color(0x48140C1A),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _takeoverCoral.withValues(alpha: 0.75),
                    ),
                  ),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onConfirm(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          actionLabel,
                          style: ZyraText.button(
                            size: 13,
                          ).copyWith(color: const Color(0xFFF0A2A0)),
                        ),
                      ),
                    ),
                  ),
                )
              : _CardPill(
                  label: actionLabel,
                  onTap: () => onConfirm(),
                  primary: true,
                ),
        ),
        TextButton(
          onPressed: onDismiss,
          child: Text(dismissLabel, style: ZyraText.subtext()),
        ),
      ],
    );
  }
}
