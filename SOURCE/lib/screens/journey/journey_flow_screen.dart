// Pre-Journey Ritual host screen — APP/Journey/PRE-JOURNEY RITUAL/
// Summary.md. Routes an Active Journey through its real stages
// (matches.journey_stage): Salam Exchange -> Compatibility Reveal ->
// Wali Gate -> Phase 1/2/3 -> Family Stage -> Conversation. Reached
// from the Connections tab (screens/connections/connections_screen.dart,
// formerly MatchesScreen — renamed 2026-07-26 nav bar fix) after
// ZyraJourneyService.promoteToActive().
//
// 2026-07-26 (#31, DR-ZYRA-110): the 4 "both Seekers complete a stage"
// transitions (phase_1->2, phase_2->3, phase_3->family_stage,
// family_stage->conversation) no longer advance journey_stage
// directly — each opens a 48-hour Family Review Period first (WALI_
// ARCHITECTURE_CURRENT_VERSION_V6.md §FAMILY REVIEW PERIOD), during
// which either Seeker's main Guardian may Continue or Pause from wali_
// journey_detail_screen.dart. See _advanceGated()/_FamilyReviewView
// below, and 20260726190000_family_review_period.sql.
//
// REDUCED V1 SCOPE (Founder decision, 2026-07-25, DR-ZYRA-101 audit):
// - Fixed-order questions stand in for "AI-adaptive question
//   selection" — no LLM integration exists in this codebase (see
//   journey_questions.dart).
// - Part B (searchable personal question library) is not built —
//   Part A (fixed questions) only.
// - "Ask More" is not offered as a checkpoint choice this pass — only
//   Continue / End Journey. The `ask_more` decision value still exists
//   in the database for future use.
// - Family Compatibility Stage covers Seeker<->Guardian directions only —
//   Guardian<->Guardian is explicitly marked TBC in the source spec. There is
//   no Guardian-side screen to answer "seeker_to_wali" questions yet
//   (Guardian app has no Journey visibility built at all — see
//   WALI_ARCHITECTURE_CURRENT_VERSION_V5.md's "future dedicated
//   session" note), so this stage completes once the signed-in Seeker
//   has answered their own "wali_to_seeker" questions.
// - No Realtime — simultaneous-reveal / "waiting for the other party"
//   states use bounded foreground polling rather than a Supabase Realtime
//   channel. Requests are coalesced, stop in the background and run every
//   5–8 seconds depending on the stage.
// - Compatibility category breakdown mirrors the overall score for
//   every category (score_candidates() doesn't expose per-category
//   detail yet) — a real breakdown is future work.

import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../theme/zyra_interaction_style.dart';
import '../../dev/zyra_app_gold_preview.dart';
import 'package:flutter/services.dart';
import '../../data/journey_questions.dart';
import '../../data/zyra_journey_guardian_selection.dart';
import '../../data/zyra_journey_life_snapshot.dart';
import '../../data/zyra_journey_advance_policy.dart';
import '../../data/zyra_journey_intelligence.dart';
import '../../data/zyra_journey_pause_state.dart';
import '../../data/zyra_journey_scroll.dart';
import '../../data/zyra_journey_stages.dart';
import '../../data/zyra_reference_data.dart';
import '../../data/zyra_release_gates.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../dev/zyra_dev_tool_section.dart';
import '../../models/journey_match.dart';
import '../../models/seeker_profile.dart';
import '../../models/zyra_gender.dart';
import '../../models/zyra_identity_verification.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_guardian_info_service.dart';
import '../../services/zyra_image_cache.dart';
import '../../services/zyra_journey_service.dart';
import '../../services/zyra_identity_verification_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../chat/chat_screen.dart';
import '../matches/journey_timeline_screen.dart';
import '../onboarding/identity_verification_screen.dart';
// seeker_profile_screen / journey_map_screen imports left with the
// header pill row (2026-08-13) — Profile lives on the Connections card,
// the Map inside the Timeline.
// THE EXPERIENCE LAB RETIRED HERE — DR-ZYRA-185. Three rounds of
// on-device walks and three rounds of mocks ended at QUIET, which is
// now simply how the Journey looks; journey_experience_lab.dart is
// unreferenced and awaits git deletion.
import '../wali/link_wali_screen.dart';
// zyra_report_service / anchored_card_overlay / report_profile_sheet
// imports left with the ⋮ menu (2026-08-13) — reporting from a Journey
// now happens at the person: the Active card's flag on Connections.
import '../../widgets/zyra_glass_dialog.dart';
import '../../widgets/zyra_intelligence_card.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_write_feedback.dart';

/// Network polling must stop when iOS has put ZYRA in the background. Timers
/// otherwise keep waking the process until the OS suspends it, wasting radio
/// and CPU for state that cannot be seen.
bool get _journeyAppIsForeground {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == null || state == AppLifecycleState.resumed;
}

/// A Journey left underneath Timeline, Chat or a confirmation route is not
/// visible work. Foreground-only was not enough: iOS remains resumed while a
/// second route covers this one, so every stage timer kept waking and reading.
bool _journeyViewCanPoll(BuildContext context) =>
    _journeyAppIsForeground && (ModalRoute.of(context)?.isCurrent ?? true);

class JourneyFlowScreen extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  final VoidCallback? onOpenGuardian;

  /// Injectable transport for deterministic widget tests; ordinary routes
  /// always use the caller-bound Guardian service. This is not server authority.
  final Future<ZyraJourneyGuardianGate> Function(String matchId)?
  guardianGateLoader;
  const JourneyFlowScreen({
    super.key,
    required this.matchId,
    required this.profile,
    this.onOpenGuardian,
    this.guardianGateLoader,
  });

  @override
  State<JourneyFlowScreen> createState() => _JourneyFlowScreenState();
}

class _JourneyFlowScreenState extends State<JourneyFlowScreen> {
  late final DevPage _previousDevPage;
  String _status = 'active';
  String? _stage = 'salam_exchange'; // first stage — Salam first, DR-ZYRA-183
  ZyraJourneyPauseState _pauseState = ZyraJourneyPauseState.active;
  bool? _pauseCapacityAvailable;
  bool _loading = true;
  bool _stageLoaded = false;
  Timer? _poll;
  bool _pollRefreshBusy = false;
  Future<void>? _refreshFlight;
  bool _identityGateLoading =
      ZyraIdentityVerificationService.enforceExistingAccountGate;
  bool _journeyExperienceStarted = false;
  bool _guardianGateLoading = true;
  ZyraJourneyGuardianGate _guardianGate = ZyraJourneyGuardianGate.unavailable;
  int _guardianGateGeneration = 0;
  ({ZyraCompatibilityReadScope scope, Object context, bool admitted})?
  _compatibilitySurfaceContext;
  int _compatibilitySurfaceGeneration = 0;
  ZyraIdentityVerificationState? _identityVerification;
  Object? _identityGateError;

  ({
    ZyraJourneyStage stage,
    String nextLabel,
    Future<void> Function() continueAction,
    bool completionConfirmed,
  })?
  _stageDecision;
  bool _stageDecisionBusy = false;
  bool _stageContinueSelected = false;
  bool _stageActionVisible = false;
  String? _viewedRibbonStage;
  bool _pauseActionBusy = false;
  ZyraJourneyPauseState? _devPausePreview;
  ZyraPauseDevScenario _devPauseScenario = ZyraPauseDevScenario.active;
  bool _devPauseEnded = false;
  Set<int> _devGuardianSelections = const <int>{};
  bool _lifeSnapshotOpen = false;
  bool _lifeSnapshotOpenedFromDevJump = false;
  bool _lifeSnapshotMineRevealed = false;
  bool _lifeSnapshotTheirsRevealed = false;
  bool _guardianProfilesMineRevealed = false;
  bool _guardianProfilesTheirsRevealed = false;
  Set<int> _guardianSalamIndices = const <int>{};
  List<_JourneyGuardianPortrait>? _guardianHistoryPortraits;
  bool _devLifeSnapshotHasBio = true;
  Set<String> _devLifeSnapshotFieldIds =
      ZyraJourneyLifeSnapshotMock.defaultVisibleFieldIds;
  final Map<String, GlobalKey<_JourneyStageScrollShellState>> _stageScrollKeys =
      {};

  // #31 — Family Review Period. Non-null (pending or paused) means a
  // gated stage transition (phase_1->2, phase_2->3, phase_3->family_
  // stage, family_stage->conversation) is currently held, and
  // _buildStage below shows _FamilyReviewView instead of the next
  // stage's normal UI. See openFamilyReview()'s own doc comment.
  ({String id, String status, String toStage, DateTime deadlineAt})? _review;

  // Why the last advance attempt did not move the Journey on, in the
  // server's own vocabulary (see ZyraStageAdvance). Null means either
  // "nothing attempted yet" or "it advanced". Rendered by the stage
  // views so the user is told what is actually being waited on, rather
  // than pressing Continue into silence — which is exactly what the
  // 2026-08-07 release blocker looked like from the outside.
  String? _advanceReason;

  @override
  void initState() {
    super.initState();
    final dev = ZyraDevScenario.instance;
    _previousDevPage = dev.currentPage;
    dev.setCurrentPage(DevPage.activeJourney);
    final devScenario = dev.pauseScenario;
    if (ZyraDeveloperAccess.canUseDeveloperTools &&
        devScenario != ZyraPauseDevScenario.active) {
      final me = ZyraAuth.currentUser?.id ?? 'dev-me';
      _devPauseScenario = devScenario;
      _devPausePreview = devScenario.stateFor(
        viewerId: me,
        otherId: widget.profile.id,
      );
      _devPauseEnded = devScenario.isEnded;
    }
    dev.addListener(_onDevScenarioChanged);
    ZyraDeveloperAccess.authorizationChanges.addListener(
      _onGuardianAuthorityChanged,
    );
    ZyraWaliLinkService.linkRevision.addListener(_onGuardianLinksChanged);
    _resolveMainGuardianGate();
    if (ZyraIdentityVerificationService.enforceExistingAccountGate) {
      _resolveIdentityGate();
    } else {
      _startJourneyExperience();
    }
  }

  Future<void> _resolveIdentityGate() async {
    if (mounted) {
      setState(() {
        _identityGateLoading = true;
        _identityGateError = null;
      });
    }
    try {
      final state = await ZyraIdentityVerificationService.fetchMyState();
      if (!mounted) return;
      setState(() {
        _identityVerification = state;
        _identityGateLoading = false;
      });
      if (state?.allowsActiveJourney == true) _startJourneyExperience();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _identityGateLoading = false;
        _identityGateError = error;
      });
    }
  }

  void _startJourneyExperience() {
    if (_journeyExperienceStarted) return;
    _journeyExperienceStarted = true;
    _refresh();
    _loadPlusUnlock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _warmJourneyPortraits();
    });
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _pollRefresh());
  }

  Future<void> _pollRefresh() async {
    if (_pollRefreshBusy || !_journeyViewCanPoll(context)) return;
    _pollRefreshBusy = true;
    try {
      await _refresh(showSpinner: false);
    } finally {
      _pollRefreshBusy = false;
    }
  }

  /// Warm only the two portraits this Journey actually needs. The shared
  /// cache writes the bytes to the OS cache directory with the same stable,
  /// tokenless key used everywhere else, so returning to the stage is instant
  /// without persisting Journey state or another person's profile record.
  void _warmJourneyPortraits() {
    final urls = <String>{};
    final ownPhotos = AppState.instance.photos;
    if (ownPhotos.isNotEmpty && ownPhotos.first.isNotEmpty) {
      urls.add(ownPhotos.first);
    }
    if (widget.profile.photos.isNotEmpty &&
        widget.profile.photos.first.isNotEmpty) {
      urls.add(widget.profile.photos.first);
    }
    for (final url in urls) {
      unawaited(_precacheJourneyPortrait(url));
    }
  }

  Future<void> _precacheJourneyPortrait(String url) async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(
          url,
          cacheKey: ZyraImageCache.keyFor(url),
          cacheManager: ZyraImageCache.manager,
        ),
        context,
      );
    } catch (_) {
      // A cache miss is answered by ZyraProfileImage when the portrait is
      // actually needed. Prefetch is polish and must never block the Journey.
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    final dev = ZyraDevScenario.instance;
    dev.removeListener(_onDevScenarioChanged);
    ZyraDeveloperAccess.authorizationChanges.removeListener(
      _onGuardianAuthorityChanged,
    );
    ZyraWaliLinkService.linkRevision.removeListener(_onGuardianLinksChanged);
    // A developer destination may have changed while this route was open.
    // Only restore the underlying page if this Journey still owns context.
    if (dev.currentPage == DevPage.activeJourney) {
      dev.setCurrentPage(_previousDevPage);
    }
    super.dispose();
  }

  /// Keeps the visible Journey in sync with the app-wide page-aware control.
  /// The previous local-only jumper updated these fields directly; the shared
  /// control writes the same scenario store, so this listener is now the one
  /// rendering boundary for either developer action or an in-preview choice.
  void _onDevScenarioChanged() {
    if (!mounted) return;
    unawaited(_resolveMainGuardianGate());
    final scenario = ZyraDeveloperAccess.canUseDeveloperTools
        ? ZyraDevScenario.instance.pauseScenario
        : ZyraPauseDevScenario.active;
    if (scenario == _devPauseScenario) return;
    final me = ZyraAuth.currentUser?.id ?? 'dev-me';
    setState(() {
      _devPauseScenario = scenario;
      _devPausePreview = scenario == ZyraPauseDevScenario.active
          ? null
          : scenario.stateFor(viewerId: me, otherId: widget.profile.id);
      _devPauseEnded = scenario.isEnded;
      _stageActionVisible = false;
    });
  }

  void _onGuardianLinksChanged() {
    unawaited(_resolveMainGuardianGate());
  }

  void _onGuardianAuthorityChanged() {
    if (!mounted) return;
    setState(() {
      _guardianGateLoading = true;
      _guardianGate = ZyraJourneyGuardianGate.unavailable;
      if (!ZyraDeveloperAccess.canUseDeveloperTools) {
        _devPauseScenario = ZyraPauseDevScenario.active;
        _devPausePreview = null;
        _devPauseEnded = false;
      }
    });
    unawaited(_resolveMainGuardianGate());
  }

  Future<void> _resolveMainGuardianGate() async {
    final request = ++_guardianGateGeneration;
    final accountGeneration = ZyraAccountState.generation;
    final accountId = ZyraAccountState.userId;
    final dev = ZyraDevScenario.instance;
    if (dev.guardianOverride) {
      if (!mounted) return;
      setState(() {
        _guardianGateLoading = false;
        _guardianGate = dev.mainGuardian && dev.guardianCount > 0
            ? ZyraJourneyGuardianGate.ready
            : ZyraJourneyGuardianGate.selfMissing;
      });
      return;
    }

    // A live refresh is not permission to keep a previously simulated or
    // revoked ready gate visible while the server answer is pending.
    if (!mounted) return;
    setState(() {
      _guardianGateLoading = true;
      _guardianGate = ZyraJourneyGuardianGate.unavailable;
    });
    final result =
        await (widget.guardianGateLoader?.call(widget.matchId) ??
            ZyraWaliLinkService.fetchJourneyGuardianGate(widget.matchId));
    if (!mounted ||
        request != _guardianGateGeneration ||
        ZyraAccountState.isSigningOut ||
        accountGeneration != ZyraAccountState.generation ||
        accountId != ZyraAccountState.userId ||
        ZyraDevScenario.instance.guardianOverride) {
      return;
    }
    setState(() {
      _guardianGateLoading = false;
      _guardianGate = result;
    });
  }

  Future<void> _refresh({bool showSpinner = true}) async {
    final active = _refreshFlight;
    if (active != null) return active;
    final next = _refreshOnce(showSpinner: showSpinner);
    _refreshFlight = next;
    try {
      await next;
    } finally {
      if (identical(_refreshFlight, next)) _refreshFlight = null;
    }
  }

  Future<void> _refreshOnce({required bool showSpinner}) async {
    if (showSpinner && mounted) setState(() => _loading = true);
    // #31 — lazy-resolve a due review (48h elapsed, no Pause) before
    // reading the match's current stage, so a Journey whose review
    // timed out while nobody had this screen open still advances the
    // moment either party next opens it, exactly like every other
    // poll-driven state in this screen.
    await ZyraJourneyService.resolveFamilyReviewIfDue(widget.matchId);
    var fresh = await ZyraJourneyService.refetchOne(
      widget.matchId,
      widget.profile.id,
    );

    // ── THE STALLED-TRANSITION RETRY.
    //
    // WAS wali_gate ONLY, with a comment giving the exact reason it was
    // needed: "whoever linked first would otherwise sit on the gate screen
    // indefinitely after the other party linked theirs." That reasoning was
    // right and was never applied to the other two two-sided thresholds.
    //
    // ── THE BUG, found 2026-08-11. Founder: "on compatibility reveal I'm
    // stuck on 'you've chosen to continue, waiting for other'."
    //
    // He was. Both Seekers had revealed, both had recorded their Continue,
    // the score was computed — every condition zyra_advance_stage() tests was
    // satisfied — and the Journey sat at compatibility_reveal because NOTHING
    // ASKED IT AGAIN. _advance() runs on a button press; the poll re-read the
    // stage but never re-attempted the move. The screen was waiting on a
    // question it had stopped asking.
    //
    // It is not a dev-tool gap. In production, the second person to press
    // Continue is what moves the pair on — so if their client dies between
    // recording the Continue and calling advance, or their half arrives by
    // any other route, the first person waits for ever, and reopening the app
    // does not help because the retry never ran for this stage either.
    //
    // ── WHY EVERY RETRY IS CONDITIONAL.
    //
    // zyra_advance_stage() INSERTS the caller's own stage checkpoint before it
    // checks anything, so an unconditional retry here would quietly record
    // "they chose to continue" for someone who has not pressed anything. The
    // Continue is a deliberate act and the server treats it as one.
    //
    // _advanceReason is non-null only after an explicit attempt, so gating on
    // it means: you pressed it, the server said "waiting for them", and we
    // keep asking on your behalf. Guardian Gate used to retry unconditionally;
    // if both Guardians were already linked, observing Stage 3 immediately
    // advanced it and the member saw Stage 2 jump straight to Stage 4. Stage 3
    // now waits for its own deliberate transition choice instead.
    fresh = await _retryStalledAdvance(fresh);

    final review = await ZyraJourneyService.fetchFamilyReview(widget.matchId);
    if (!mounted) return;
    if (fresh != null) {
      final m = fresh;
      setState(() {
        final stageChanged = _stageLoaded && _stage != m.journeyStage;
        final journeySurfaceChanged =
            stageChanged ||
            _status != m.status ||
            _pauseState.phase != m.pause.phase ||
            _pauseState.version != m.pause.version ||
            (_review == null) != (review == null);
        _stageLoaded = true;
        _status = m.status;
        _stage = m.journeyStage;
        _pauseState = m.pause;
        _review = review;
        if (journeySurfaceChanged) {
          _stageActionVisible = false;
          _viewedRibbonStage = null;
        }
        if (stageChanged) {
          _advanceReason = null;
          _lifeSnapshotOpen = false;
          _lifeSnapshotOpenedFromDevJump = false;
          _lifeSnapshotMineRevealed = false;
          _lifeSnapshotTheirsRevealed = false;
          _stageDecision = null;
          _stageDecisionBusy = false;
          _stageContinueSelected = false;
        }
        _observeCompatibilitySurface();
        _loading = false;
      });
      if (m.pause.isLocked) {
        final capacity = await ZyraJourneyService.fetchPauseCapacity(
          widget.matchId,
        );
        if (mounted) setState(() => _pauseCapacityAvailable = capacity);
      } else if (_pauseCapacityAvailable != null && mounted) {
        setState(() => _pauseCapacityAvailable = null);
      }
    } else if (showSpinner) {
      setState(() => _loading = false);
    }
  }

  /// Re-asks the server to move a two-sided transition that is waiting on the
  /// other party. Returns the match, re-fetched if it moved.
  ///
  /// Threshold stages only. The four gated ones go through a Family Review
  /// and resolveFamilyReviewIfDue() above already retries those.
  Future<JourneyMatch?> _retryStalledAdvance(JourneyMatch? fresh) async {
    if (fresh == null || fresh.status != 'active' || fresh.isJourneyLocked) {
      return fresh;
    }
    final stage = fresh.journeyStage;
    if (stage == null) return fresh;

    final retry = ZyraJourneyAdvancePolicy.shouldRetryStalled(
      stage: stage,
      reason: _advanceReason,
    );
    if (!retry) return fresh;

    final r = await ZyraJourneyService.advanceStage(widget.matchId, stage);
    _advanceReason = r.advanced ? null : r.reason;
    if (!r.advanced) return fresh;
    return await ZyraJourneyService.refetchOne(
      widget.matchId,
      widget.profile.id,
    );
  }

  /// [fromStage] is the stage just COMPLETED, not the one wanted next —
  /// the server owns the map. See ZyraJourneyService.advanceStage.
  ///
  /// A false result is normal, not an error: it usually means the other
  /// party has not acted yet. The reason is held so the stage view can
  /// say which.
  Future<void> _advance(String fromStage) async {
    final r = await ZyraJourneyService.advanceStage(widget.matchId, fromStage);
    if (!mounted) return;
    setState(() => _advanceReason = r.advanced ? null : r.reason);
    // Keep the completed page painted while the confirmed server state is
    // read back. Showing the global loader here made every stage boundary
    // flash like a new route instead of one continuous Journey.
    await _refresh(showSpinner: false);
  }

  /// #31 — the 4 "both Seekers complete a stage" transitions open a
  /// Family Review Period instead of advancing journey_stage directly.
  /// Safe to call from whichever Seeker's client reaches this point
  /// first (openFamilyReview is idempotent).
  Future<void> _advanceGated(String fromStage, String toStage) async {
    final r = await ZyraJourneyService.openFamilyReview(
      widget.matchId,
      fromStage,
      toStage,
    );
    if (!mounted) return;
    // SURFACE IT. Since 2026-08-09 the server validates this call (audit
    // 2.2), so it can refuse — and the return value used to be discarded
    // entirely, which meant a refusal looked exactly like a success: a
    // tap, a refresh, and nothing moving. That is the 2026-08-07 release
    // blocker's signature, and it would have been reintroduced by the
    // very fix that hardened the server.
    if (!r.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_reviewRefusedMessage(r.reason))));
    }
    await _refresh(showSpinner: false);
  }

  GlobalKey<_JourneyStageScrollShellState> _scrollKeyFor(String? stage) {
    final value = stage ?? ZyraJourneyStages.all.first.value;
    return _stageScrollKeys.putIfAbsent(
      value,
      () => GlobalKey<_JourneyStageScrollShellState>(),
    );
  }

  void _setStageActionVisible(bool visible) {
    if (!mounted || _stageActionVisible == visible) return;
    setState(() => _stageActionVisible = visible);
  }

  void _setViewedRibbonStage(ZyraJourneyStage stage) {
    if (!mounted || _viewedRibbonStage == stage.value) return;
    setState(() => _viewedRibbonStage = stage.value);
  }

  void _navigateToCompletedStage(int order) {
    void scroll() {
      _scrollKeyFor(
        _displayStage.value,
      ).currentState?.scrollToCompletedStage(order);
    }

    if (_stageDecision != null) {
      setState(() {
        _stageDecision = null;
        _stageDecisionBusy = false;
        _stageContinueSelected = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
      return;
    }
    scroll();
  }

  Future<void> _openStageDecision({
    required String fromStage,
    required Future<void> Function() continueAction,
    bool completionConfirmed = true,
    ZyraJourneyStage? stageOverride,
    String? nextLabelOverride,
  }) async {
    final stage = stageOverride ?? ZyraJourneyStages.of(fromStage);
    if (!mounted || stage == null) {
      return;
    }
    final nextLabel =
        nextLabelOverride ??
        (stage.order < ZyraJourneyStages.count
            ? ZyraJourneyStages.all[stage.order].label
            : null);
    if (nextLabel == null) return;
    setState(() {
      _stageDecision = (
        stage: stage,
        nextLabel: nextLabel,
        continueAction: continueAction,
        completionConfirmed: completionConfirmed,
      );
      _stageDecisionBusy = false;
      _stageContinueSelected = false;
    });
  }

  void _selectStageContinue() {
    if (_stageDecision == null || _stageDecisionBusy) return;
    ZyraInteractionStyle.emitSelectionHaptic();
    setState(() => _stageContinueSelected = !_stageContinueSelected);
  }

  Future<void> _continueStageDecision() async {
    final decision = _stageDecision;
    if (decision == null || _stageDecisionBusy) return;
    setState(() => _stageDecisionBusy = true);
    await decision.continueAction();
    if (!mounted) return;
    setState(() {
      _stageDecision = null;
      _stageDecisionBusy = false;
      _stageContinueSelected = false;
    });
  }

  Future<void> _pauseStageDecision() async {
    if (_stageDecision == null || _stageDecisionBusy) return;
    setState(() => _stageDecisionBusy = true);
    final requested = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _JourneyLifecycleConfirmScreen(
          action: _JourneyLifecycleAction.pause,
          profile: widget.profile,
          onConfirm: () async {
            try {
              await ZyraJourneyService.transitionPause(
                matchId: widget.matchId,
                action: ZyraPauseAction.requestPause,
                expectedVersion: _pauseState.version,
              );
              return null;
            } catch (_) {
              return _JourneyLifecycleFailure.failed;
            }
          },
        ),
      ),
    );
    if (!mounted) return;
    if (requested != true) {
      setState(() => _stageDecisionBusy = false);
      return;
    }

    setState(() {
      _stageDecision = null;
      _stageDecisionBusy = false;
      _stageContinueSelected = false;
    });
    await _refresh(showSpinner: false);
  }

  Future<void> _pauseForMissingMainGuardian() async {
    if (_pauseActionBusy || _pauseState.isLocked) return;
    setState(() => _pauseActionBusy = true);
    final requested = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _JourneyLifecycleConfirmScreen(
          action: _JourneyLifecycleAction.pause,
          profile: widget.profile,
          onConfirm: () async {
            try {
              await ZyraJourneyService.transitionPause(
                matchId: widget.matchId,
                action: ZyraPauseAction.requestPause,
                expectedVersion: _pauseState.version,
              );
              return null;
            } catch (_) {
              return _JourneyLifecycleFailure.failed;
            }
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _pauseActionBusy = false);
    if (requested == true) await _refresh(showSpinner: false);
  }

  void _openGuardianFromJourneyHold() {
    Navigator.of(context).pop();
    widget.onOpenGuardian?.call();
  }

  Future<void> _applyPauseAction(ZyraPauseAction action) async {
    if (_pauseActionBusy) return;
    final preview = _devPausePreview;
    if (preview != null) {
      final me = ZyraAuth.currentUser?.id ?? 'dev-me';
      try {
        final next = ZyraJourneyPausePolicy.apply(
          state: preview,
          action: action,
          actorId: me,
          otherId: widget.profile.id,
        );
        if (mounted) {
          final scenario = ZyraPauseDevScenario.fromState(next, me);
          ZyraDevScenario.instance.setPauseScenario(scenario);
          setState(() {
            _devPauseScenario = scenario;
            _devPausePreview = next.phase == ZyraPausePhase.active
                ? null
                : next;
            _stageActionVisible = false;
          });
        }
      } on StateError {
        // A preview action can only be reached from a compatible decision
        // surface. If a hot-reload leaves a stale callback, ignore it.
      }
      return;
    }
    setState(() => _pauseActionBusy = true);
    try {
      final next = await ZyraJourneyService.transitionPause(
        matchId: widget.matchId,
        action: action,
        expectedVersion: _pauseState.version,
      );
      if (mounted) {
        setState(() {
          _pauseState = next;
          _pauseCapacityAvailable = null;
        });
      }
      await _refresh(showSpinner: false);
    } on PauseCapacityConflictException {
      if (!mounted) return;
      setState(() => _pauseCapacityAvailable = false);
    } on PauseTransitionStaleException {
      await _refresh(showSpinner: false);
    } on PauseTransitionNotAllowedException {
      await _refresh(showSpinner: false);
    } on SelfInActiveJourneyException {
      await _refresh(showSpinner: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You're at your plan's Active Journey limit, so this one stays "
            'paused. Pause or end an Active Journey first — nothing here is lost.',
          ),
        ),
      );
    } on OtherPartyInActiveJourneyException {
      await _refresh(showSpinner: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "They're in another Journey right now, so this one stays paused. "
            'Nothing has been lost. You can request again when there is capacity.',
          ),
        ),
      );
    } on NotEligibleToContinueException {
      await _refresh(showSpinner: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This Journey can't continue right now.")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "That didn't go through — check your connection and try again.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _pauseActionBusy = false);
    }
  }

  void _endPauseFlow() {
    if (_devPausePreview != null) {
      ZyraDevScenario.instance.setPauseScenario(
        ZyraPauseDevScenario.endedFromPause,
      );
      setState(() {
        _devPauseScenario = ZyraPauseDevScenario.endedFromPause;
        _devPausePreview = null;
        _devPauseEnded = true;
      });
      return;
    }
    unawaited(_endJourney());
  }

  void _resetGuardianGate() {
    if (!mounted) return;
    setState(() => _advanceReason = null);
    unawaited(_refresh(showSpinner: false));
  }

  /// The server's vocabulary turned into something a person can act on.
  /// 'stage_moved' is the one a real user will actually hit — the other
  /// Seeker's client opened the same review a moment earlier — and it is
  /// not an error from their point of view, so it does not read like one.
  static String _reviewRefusedMessage(String reason) => switch (reason) {
    'stage_moved' =>
      'This Journey has already moved on — bringing you up to date.',
    'journey_paused' => 'This Journey is paused. Resume it to continue.',
    'journey_not_active' => 'This Journey is no longer active.',
    'not_a_gated_transition' ||
    'invalid_transition' => "That step isn't available from here.",
    _ => "That didn't go through. Please try again.",
  };

  /// End is confirmed on its own full screen. The write happens while that
  /// confirmation remains visible, so a failure leaves the member on the
  /// decision they were making instead of dismissing it into a snackbar.
  Future<void> _endJourney() async {
    final ended = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _JourneyLifecycleConfirmScreen(
          action: _JourneyLifecycleAction.end,
          profile: widget.profile,
          onConfirm: () async {
            final ok = await ZyraJourneyService.endJourney(widget.matchId);
            return ok ? null : _JourneyLifecycleFailure.failed;
          },
        ),
      ),
    );
    if (ended != true || !mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            _JourneyLifecycleCompleteScreen(profile: widget.profile),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  /// Legacy live-account Journey controls stay disabled in the one-app model.
  // Legacy server-backed Journey jump controls are not part of local previews.
  // Keep disabled; the shared local scenario panel owns preview controls.
  bool get _isDevAccount => false;

  bool _jumping = false;

  /// DR-ZYRA-135. Whether this account holds a simulated Compatibility
  /// Unlock+ on the other Seeker. Read from the server, not held
  /// locally — a switch that shows its own last write is a switch that
  /// lies.
  bool _hasPlus = false;

  Future<void> _loadPlusUnlock() async {
    if (!_isDevAccount) return;
    final v = await ZyraJourneyService.fetchHasPlusUnlock(widget.profile.id);
    if (mounted) setState(() => _hasPlus = v);
  }

  Future<void> _setPlusUnlock(bool value) async {
    if (_jumping) return;
    setState(() => _jumping = true);
    try {
      await ZyraJourneyService.devSetPlusUnlock(widget.profile.id, value);
      await _loadPlusUnlock();
      await _refresh(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _jumping = false);
    }
  }

  /// DEV ONLY. Does the OTHER party's half of the stage the Journey is
  /// standing on — their Salam, their answers, their Continue, their
  /// Guardian's answers — and nothing else.
  ///
  /// Founder, 2026-08-11: "make the whole journey process until the message
  /// stage." It could not be walked at all before this. Every stage from the
  /// Salam onwards is mutual BY DESIGN, so one person testing alone reaches
  /// "Waiting for their answers" at stage two and stops; six of the eight
  /// stages had therefore never been seen running.
  ///
  /// This is not a skip. It does not move the Journey on — the tester still
  /// presses their own buttons, still sees their own waiting states, and the
  /// real gates still decide. What ends is the wait for a person who is never
  /// going to open the app.
  ///
  /// The question ids travel from here because the bank lives in
  /// data/journey_questions.dart and the database has never been told about
  /// it. Sending the wrong set would write answers to questions that are not
  /// on screen, so it is read from the same [JourneyQuestions] the stage view
  /// itself renders rather than a second list.
  Future<void> _counterpartComplete() async {
    if (_jumping) return;
    if (_lifeSnapshotOpen && _stage == 'compatibility_reveal') {
      if (_lifeSnapshotTheirsRevealed) {
        return;
      }
      setState(() => _lifeSnapshotTheirsRevealed = true);
      return;
    }
    if (_stage == 'wali_gate') {
      if (_guardianProfilesTheirsRevealed) {
        return;
      }
      setState(() => _guardianProfilesTheirsRevealed = true);
      return;
    }
    setState(() => _jumping = true);
    try {
      final ids = switch (_stage) {
        'phase_1' => JourneyQuestions.phase1.map((q) => q.id).toList(),
        'phase_2' => JourneyQuestions.phase2.map((q) => q.id).toList(),
        'phase_3' => JourneyQuestions.phase3.map((q) => q.id).toList(),
        'family_stage' =>
          JourneyQuestions.seekerToWali.map((q) => q.id).toList(),
        _ => const <String>[],
      };
      await ZyraJourneyService.devCounterpartComplete(
        widget.matchId,
        questionIds: ids,
      );
      await _refresh(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _jumping = false);
    }
  }

  void _toggleDevGuardian(int index) {
    if (_jumping || _pauseActionBusy) return;
    setState(() {
      _devGuardianSelections = ZyraJourneyGuardianSelection.toggle(
        _devGuardianSelections,
        index,
      );
    });
  }

  void _setDevLifeSnapshotBio(bool value) {
    if (_jumping || _pauseActionBusy) return;
    setState(() => _devLifeSnapshotHasBio = value);
  }

  void _toggleDevLifeSnapshotField(String id) {
    if (_jumping || _pauseActionBusy) return;
    setState(() {
      _devLifeSnapshotFieldIds = ZyraJourneyLifeSnapshotMock.toggle(
        _devLifeSnapshotFieldIds,
        id,
      );
    });
  }

  void _setAllDevLifeSnapshotFields(bool visible) {
    if (_jumping || _pauseActionBusy) return;
    setState(() {
      _devLifeSnapshotFieldIds = visible
          ? ZyraJourneyLifeSnapshotMock.defaultVisibleFieldIds
          : const <String>{};
    });
  }

  Future<void> _openLifeSnapshot({bool fromDevJump = false}) async {
    if (!mounted) return;
    setState(() {
      _lifeSnapshotOpen = true;
      _lifeSnapshotOpenedFromDevJump = fromDevJump;
      _lifeSnapshotMineRevealed = false;
      _lifeSnapshotTheirsRevealed = false;
      _viewedRibbonStage = null;
      _advanceReason = null;
      _stageActionVisible = false;
    });
  }

  void _revealLifeSnapshot() {
    if (!mounted || _lifeSnapshotMineRevealed) return;
    ZyraInteractionStyle.emitSelectionHaptic();
    setState(() => _lifeSnapshotMineRevealed = true);
  }

  void _revealGuardianProfiles() {
    if (!mounted || _guardianProfilesMineRevealed) return;
    ZyraInteractionStyle.emitSelectionHaptic();
    setState(() => _guardianProfilesMineRevealed = true);
  }

  void _recordGuardianSalam(int guardianIndex) {
    if (!mounted || _guardianSalamIndices.contains(guardianIndex)) return;
    ZyraInteractionStyle.emitSelectionHaptic();
    setState(() {
      _guardianSalamIndices = Set<int>.unmodifiable({
        ..._guardianSalamIndices,
        guardianIndex,
      });
    });
  }

  List<_JourneyGuardianPortrait> get _guardianPortraitsForHistory {
    final remembered = _guardianHistoryPortraits;
    if (remembered != null && remembered.isNotEmpty) return remembered;
    if (_isDevAccount) {
      return [
        for (final guardian
            in ZyraJourneyGuardianSelection.otherGuardianPreview)
          _JourneyGuardianPortrait(
            firstName: guardian.firstName,
            relationship:
                zyraRelationshipLabel(guardian.relationship) ??
                guardian.relationship,
            isMain: guardian.isMain,
          ),
      ];
    }
    return const [_JourneyGuardianPortrait(firstName: null, isMain: true)];
  }

  void _rememberGuardianPortraits(List<_JourneyGuardianPortrait> guardians) {
    if (!mounted || guardians.isEmpty) return;
    setState(() {
      _guardianHistoryPortraits = List<_JourneyGuardianPortrait>.unmodifiable(
        guardians,
      );
    });
  }

  Future<void> _continueLifeSnapshot() async {
    if (_isDevAccount && _lifeSnapshotOpenedFromDevJump) {
      await _jumpToStage('wali_gate');
      return;
    }
    await _advance('compatibility_reveal');
  }

  /// The Guardian stage's six named Guardians are a visual developer mock,
  /// but its Main
  /// Guardian also needs to satisfy the real server gate before the tester can
  /// move on. The existing dev RPC creates one active Main for each Seeker;
  /// the five Additional selections remain display-only because production
  /// has no artificial Guardian count cap and this panel must not invent one.
  Future<bool> _prepareDevGuardianGate() async {
    if (!_isDevAccount ||
        !_devGuardianSelections.contains(
          ZyraJourneyGuardianSelection.mainIndex,
        ) ||
        _jumping) {
      return false;
    }
    setState(() => _jumping = true);
    try {
      await ZyraJourneyService.devCounterpartComplete(widget.matchId);
      await _refresh(showSpinner: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return false;
    } finally {
      if (mounted) setState(() => _jumping = false);
    }
  }

  /// DEV ONLY, DESTRUCTIVE. Puts this Journey back to its first stage and
  /// throws away everything done inside it, so it can be walked again.
  ///
  /// CONFIRMED FIRST. It is the only control in this panel that destroys
  /// anything — the rest move a stage or fill in the other person's half, and
  /// both are recoverable by carrying on. This is not, and after a long
  /// walk-through there is real work behind that tap.
  Future<void> _rewindJourney() async {
    if (_jumping) return;
    final ok = await showZyraGlassChoice(
      context: context,
      icon: Icons.restart_alt,
      title: 'Start this Journey again?',
      body:
          'Puts you back at Compatibility Reveal and clears everything you '
          'both did — answers, ratings, Salams, the reveal, family answers, '
          'messages and Timeline milestones.\n\nThe match itself stays, and so '
          'does your Guardian link.',
      primaryLabel: 'Start again',
      secondaryLabel: 'Cancel',
    );
    if (ok != true || !mounted) return;

    setState(() => _jumping = true);
    try {
      await ZyraJourneyService.devRewindJourney(matchId: widget.matchId);
      if (mounted) {
        setState(() {
          _guardianProfilesMineRevealed = false;
          _guardianProfilesTheirsRevealed = false;
          _guardianSalamIndices = const <int>{};
          _guardianHistoryPortraits = null;
        });
      }
      await _refresh(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _jumping = false);
    }
  }

  /// DEV ONLY. Skips the Pre-Journey Ritual, the Guardian Gate and the
  /// 48-hour Family Review Period in one tap.
  Future<void> _jumpToStage(String stage) async {
    if (_jumping) return;
    setState(() => _jumping = true);
    try {
      final serverStage = stage == ZyraJourneyStages.lifeSnapshotPreview.value
          ? 'compatibility_reveal'
          : stage;
      await ZyraJourneyService.devSetStage(widget.matchId, serverStage);
      final targetOrder = ZyraJourneyStages.previewOf(stage)?.order;
      if (mounted &&
          targetOrder != null &&
          targetOrder <= ZyraJourneyStages.previewOf('wali_gate')!.order) {
        setState(() {
          _guardianProfilesMineRevealed = false;
          _guardianProfilesTheirsRevealed = false;
          _guardianSalamIndices = const <int>{};
          _guardianHistoryPortraits = null;
        });
      }
      // The server is the source of truth for where the Journey now is, so
      // re-read rather than assuming the jump landed where it was asked to.
      // A local setState here would show the requested stage even if the
      // server had quietly done something else — the exact shape of the
      // 2026-08-07 release blocker, where a no-op looked like a success.
      await _refresh(showSpinner: false);
      if (stage == ZyraJourneyStages.lifeSnapshotPreview.value && mounted) {
        await _openLifeSnapshot(fromDevJump: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _jumping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _observeCompatibilitySurface();
    if (ZyraIdentityVerificationService.enforceExistingAccountGate) {
      if (_identityGateLoading) {
        return const Scaffold(body: SafeArea(child: ZyraLoading.fullScreen()));
      }
      if (_identityGateError != null) {
        return Scaffold(
          body: Container(
            constraints: const BoxConstraints.expand(),
            decoration: ZyraAppGoldDecoration(
              gradient: ZyraColors.brandGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "We couldn't check Journey access.",
                        style: ZyraText.heading(size: 22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Nothing has changed. Check your connection and try again.',
                        style: ZyraText.subtext(size: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _resolveIdentityGate,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      if (_identityVerification?.allowsActiveJourney != true) {
        return InitialIdentityCheckScreen(
          initialState: _identityVerification,
          requireDuplicateResolution: true,
          onContinue: (_) => _resolveIdentityGate(),
        );
      }
    }
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        // JOURNEY MODE IS NEUTRAL GROUND — Founder, 2026-08-15
        // (DR-ZYRA-177): "regardless of male or female the colour for
        // both is the default purple." Inside a Journey two accounts
        // share one place, so neither side's tint paints it; the
        // neutral brand gradient does. Gender tints stay everywhere
        // else (DR-ZYRA-094 unchanged outside Journey mode).
        decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
        child: Stack(
          children: [
            // One shared living background for the whole Journey. The
            // motion belongs to the relationship, not to any individual
            // chapter, so every stage inherits it from here instead of
            // maintaining eight decorative implementations that can drift.
            Positioned.fill(child: _JourneyAtmosphere(stage: _stage)),
            SafeArea(
              child: _loading ? const ZyraLoading() : _buildBody(context),
            ),
            // DEV ONLY — the right-edge pull-out, matching dev_scenario_panel.
            //
            // In the Stack rather than the Column so it floats over the stage
            // content the way the app's other developer panel floats over
            // HomeShell. It remains reachable on a paused Journey because its
            // display-only pause selector is how every ownership state is
            // reviewed; stage-changing controls disable while the live row is
            // paused.
            //
            // Client capability decides whether this is drawn; the staging
            // RPC boundary independently repeats the exact protected-persona
            // check before changing server state.
            if (_isDevAccount && _stageLoaded && _status == 'active')
              _DevStageJumper(
                current: _displayStage.value,
                busy: _jumping || _pauseActionBusy,
                onJump: _jumpToStage,
                lifeSnapshotHasBio: _devLifeSnapshotHasBio,
                lifeSnapshotFieldIds: _devLifeSnapshotFieldIds,
                onLifeSnapshotBioChanged: _setDevLifeSnapshotBio,
                onLifeSnapshotFieldToggle: _toggleDevLifeSnapshotField,
                onLifeSnapshotShowAll: _setAllDevLifeSnapshotFields,
                selectedGuardians: _devGuardianSelections,
                onGuardianToggle: _toggleDevGuardian,
                hasPlus: _hasPlus,
                onHasPlusChanged: _setPlusUnlock,
                onRewind: _rewindJourney,
                livePaused: _pauseState.isLocked,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // DR-ZYRA-178. Until the first fetch has ANSWERED, there is nothing
    // to render as a Journey — and this screen used to render its field
    // defaults ('active', first stage) instead, which is how a dev
    // stand-in with no server row behind it walked into a Compatibility
    // Reveal that could never advance (the 2026-08-15 "toggle isn't
    // working" report). Truthful-failure rule, extended: a cached value
    // may paint, never decide — and an INVENTED value may not even
    // paint.
    if (!_stageLoaded) {
      return ZyraEmptyState(
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load this Journey",
        message: _isDevAccount
            ? 'Nothing arrived from the server for it. A dev stand-in '
                  'has no real Journey behind it and never loads here; a '
                  'real one appears when the connection returns. (dev)'
            : 'Nothing arrived from the server. Check your connection, '
                  'then try again.',
        ctaLabel: 'Try again',
        onCta: () => _refresh(),
      );
    }

    if (_status == 'ended' || _devPauseEnded) {
      return _EndedView(profile: widget.profile);
    }

    if (_guardianGateLoading) {
      return const ZyraLoading();
    }
    if (_guardianGate == ZyraJourneyGuardianGate.unavailable) {
      return ZyraEmptyState(
        icon: Icons.cloud_off_outlined,
        title: "Couldn't check your Main Guardian",
        message:
            'Journey access stays protected until this check succeeds. '
            'Nothing has changed.',
        ctaLabel: 'Try again',
        onCta: _resolveMainGuardianGate,
      );
    }
    if (_guardianGate != ZyraJourneyGuardianGate.ready) {
      final selfMissing =
          _guardianGate == ZyraJourneyGuardianGate.selfMissing ||
          _guardianGate == ZyraJourneyGuardianGate.bothMissing;
      return _MainGuardianRequiredJourneyView(
        profile: widget.profile,
        paused: _pauseState.isLocked,
        busy: _pauseActionBusy,
        waitingOnOther: !selfMissing,
        onChooseGuardian: selfMissing ? _openGuardianFromJourneyHold : null,
        onPause: _pauseState.isLocked ? null : _pauseForMissingMainGuardian,
        onEnd: _endJourney,
      );
    }

    final pauseState = _devPausePreview ?? _pauseState;
    if (pauseState.isLocked) {
      final preview = _devPausePreview != null;
      return _PauseDecisionView(
        profile: widget.profile,
        state: pauseState,
        busy: preview ? false : _pauseActionBusy,
        preview: preview,
        capacityAvailable: preview
            ? !pauseState.capacityBlocked
            : _pauseCapacityAvailable,
        onAction: _applyPauseAction,
        onEnd: _endPauseFlow,
        onReturn: () => Navigator.of(context).maybePop(),
      );
    }

    final displayStage = _displayStage;
    final surfaceKey = _review != null ? 'family_review' : displayStage.value;

    return Column(
      children: [
        // Persistent Journey management lives on the Connections Active
        // Journey card. Live chapter content contains only its own action;
        // Pause/End appear once, on the dedicated between-stage choice page.
        _JourneyAppBar(profile: widget.profile),
        // THE RIBBON — DR-ZYRA-185 (chosen as "Quiet" after three
        // mock rounds): eight quiet marks, one named pill. Walked
        // chapters fill soft gold, the road ahead sits faint, and the
        // chapter you are standing in says its own name. During a
        // Family Review the pill says that instead — the one moment
        // the Journey is held for a reason the Seeker cannot act on.
        //
        _JourneyRibbon(
          stage: _viewedRibbonStage ?? displayStage.value,
          stages: ZyraJourneyStages.previewAll,
          reviewOpen: _review != null,
          onCompletedStageTap: _navigateToCompletedStage,
        ),
        Expanded(
          // A confirmed stage change continues the exact movement used by
          // the vertical PageView: the completed surface rises out while the
          // next arrival rises from below. There is no fade, scale, loader or
          // route transition, so one gesture reads as one continuous scroll.
          // Family Review remains an override rather than a ninth stage.
          child: _JourneyVerticalStageSwap(
            surfaceKey: surfaceKey,
            child: KeyedSubtree(
              key: ValueKey(surfaceKey),
              child: _review != null
                  ? _FamilyReviewView(review: _review!, profile: widget.profile)
                  : _JourneyStageScrollShell(
                      key: _scrollKeyFor(displayStage.value),
                      stage: displayStage,
                      stages: ZyraJourneyStages.previewAll,
                      compatibilityHistoryChild: _CompatibilityRevealView(
                        matchId: widget.matchId,
                        profile: widget.profile,
                        isActionVisible: false,
                        readOnly: true,
                        isCurrentSurface: _captureCompatibilitySurfaceOwner(
                          readOnly: true,
                        ),
                        onContinue: () async {},
                        waitingReason: null,
                      ),
                      salamHistoryChild: _SalamExchangeHistoryView(
                        profile: widget.profile,
                      ),
                      lifeSnapshotHistoryChild: _LifeSnapshotView(
                        profile: widget.profile,
                        showBio: _devLifeSnapshotHasBio,
                        visibleFieldIds: _devLifeSnapshotFieldIds,
                        mineRevealed: true,
                        theirsRevealed: true,
                        onReveal: () {},
                        waitingForOther: false,
                        onContinue: () async {},
                        readOnly: true,
                      ),
                      guardianHistoryChild: _JourneyGuardianHistoryView(
                        otherFirstName: widget.profile.firstName,
                        guardians: _guardianPortraitsForHistory,
                        guardianSalamIndices: _guardianSalamIndices,
                      ),
                      decisionChild: _stageDecision == null
                          ? null
                          : _JourneyStageDecisionPage(
                              stage: _stageDecision!.stage,
                              nextLabel: _stageDecision!.nextLabel,
                              completionConfirmed:
                                  _stageDecision!.completionConfirmed,
                              busy: _stageDecisionBusy,
                              continueSelected: _stageContinueSelected,
                              onBack: () => _scrollKeyFor(
                                displayStage.value,
                              ).currentState?.showActionPage(),
                              onSelectContinue: _selectStageContinue,
                              onCommitContinue: _continueStageDecision,
                              onPause: _pauseStageDecision,
                              onEnd: _endJourney,
                            ),
                      onOpenTimeline: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JourneyTimelineScreen(
                            withProfile: widget.profile,
                          ),
                        ),
                      ),
                      onActionVisibilityChanged: _setStageActionVisible,
                      onViewedStageChanged: _setViewedRibbonStage,
                      child: _buildStage(context),
                    ),
            ),
          ),
        ),
        // THE WAITING LINES — DR-ZYRA-185. When the server has said the
        // Journey is waiting on the other side, the app's own comet
        // rule says so in the app's own voice, with the reason in
        // words. Absent otherwise: a page that is yours to act on
        // never shows a spinner. NOT ON STAGE 1 (DR-ZYRA-192): nothing
        // is loading while another human decides when to open ZYRA, so
        // nothing animates — the Salam page says the wait in words.
        if (_advanceReason != null &&
            _review == null &&
            !_lifeSnapshotOpen &&
            _stage != 'salam_exchange' &&
            _stage != 'wali_gate')
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: ZyraLoading(label: _waitingLine),
          ),
        // DEV ONLY — the on-page "User" action (DR-ZYRA-181). Does the
        // OTHER person's half of the current step, on press — it
        // REPLACED the auto toggle so the waiting states are seen
        // first: complete your side, see the wait, press User, watch
        // the Journey move. It stays during a Family Review (its RPC's
        // closing block is the only fast exit from one). Subtle and
        // apart from the Journey's own controls; never in release.
        if (ZyraDeveloperAccess.canUseDeveloperTools &&
            _isDevAccount &&
            _status == 'active' &&
            !_pauseState.isLocked)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _jumping ? null : _counterpartComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ZyraColors.foreground.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: ZyraColors.foreground.withValues(alpha: 0.14),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'User',
                    style: ZyraText.subtext(
                      size: 11.5,
                      color: ZyraColors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The server's waiting reason, in the Journey's own words —
  /// rendered under the stage by the standard loading lines
  /// (DR-ZYRA-185).
  String get _waitingLine {
    final name = widget.profile.firstName;
    return switch (_advanceReason) {
      'waiting_for_salam' => "Waiting for $name's Salam",
      'waiting_for_reveal' => 'Waiting for $name to reveal',
      'waiting_for_continue' => 'Waiting for $name to continue',
      _ => 'Waiting for $name',
    };
  }

  ZyraJourneyStage get _displayStage {
    if (_lifeSnapshotOpen && _stage == 'compatibility_reveal') {
      return ZyraJourneyStages.lifeSnapshotPreview;
    }
    return ZyraJourneyStages.previewOf(_stage) ??
        ZyraJourneyStages.previewAll.first;
  }

  String get _currentJourneySurfaceKey =>
      _review != null ? 'family_review' : _displayStage.value;

  bool get _compatibilityParentAdmitted =>
      _stageLoaded &&
      _status == 'active' &&
      !_devPauseEnded &&
      _review == null &&
      !_guardianGateLoading &&
      _guardianGate == ZyraJourneyGuardianGate.ready &&
      !(_devPausePreview ?? _pauseState).isLocked &&
      !_identityGateLoading &&
      (!ZyraIdentityVerificationService.enforceExistingAccountGate ||
          (_identityGateError == null &&
              _identityVerification?.allowsActiveJourney == true));

  int _observeCompatibilitySurface() {
    final pause = _devPausePreview ?? _pauseState;
    final next = (
      scope: ZyraCompatibilityReadScope(
        actorId: ZyraAuth.currentUser?.id,
        accountGeneration: ZyraAccountState.generation,
        matchId: widget.matchId,
      ),
      context: (
        widget.profile.id,
        _currentJourneySurfaceKey,
        _stageLoaded,
        _status,
        _devPauseEnded,
        _review?.id,
        _review?.status,
        _guardianGateLoading,
        _guardianGate,
        pause.phase,
        pause.version,
        pause.isLocked,
        _identityGateLoading,
        _identityGateError != null,
        ZyraIdentityVerificationService.enforceExistingAccountGate,
        _identityVerification?.allowsActiveJourney,
        _lifeSnapshotOpen,
      ),
      admitted: _compatibilityParentAdmitted,
    );
    final previous = _compatibilitySurfaceContext;
    if (previous != next) {
      // Initial loading is not a retirement of a usable parent context.
      // Preserve an unchanged-context revisit's last confirmed cache.
      if (previous?.admitted == true) {
        _CompatibilityRevealViewState.invalidateParentContext(previous!.scope);
      }
      _compatibilitySurfaceContext = next;
      _compatibilitySurfaceGeneration++;
    }
    return _compatibilitySurfaceGeneration;
  }

  bool Function() _captureCompatibilitySurfaceOwner({required bool readOnly}) {
    final matchId = widget.matchId;
    final profileId = widget.profile.id;
    final surfaceKey = _currentJourneySurfaceKey;
    final generation = _observeCompatibilitySurface();
    var retired = false;
    return () {
      if (retired) return false;
      final current =
          mounted &&
          _observeCompatibilitySurface() == generation &&
          widget.matchId == matchId &&
          widget.profile.id == profileId &&
          _currentJourneySurfaceKey == surfaceKey &&
          _compatibilityParentAdmitted &&
          (readOnly ||
              (_stage == 'compatibility_reveal' && !_lifeSnapshotOpen));
      // Once this captured surface loses admission it cannot revive an old
      // awaited read merely because the same surface key comes back later.
      if (!current) retired = true;
      return current;
    };
  }

  Widget _buildStage(BuildContext context) {
    if (_lifeSnapshotOpen && _stage == 'compatibility_reveal') {
      return _LifeSnapshotView(
        profile: widget.profile,
        showBio: _devLifeSnapshotHasBio,
        visibleFieldIds: _devLifeSnapshotFieldIds,
        mineRevealed: _lifeSnapshotMineRevealed,
        theirsRevealed: _lifeSnapshotTheirsRevealed,
        onReveal: _revealLifeSnapshot,
        waitingForOther:
            _advanceReason == 'waiting_for_continue' ||
            _advanceReason == 'waiting_for_reveal',
        onContinue: () => _openStageDecision(
          fromStage: 'compatibility_reveal',
          stageOverride: ZyraJourneyStages.lifeSnapshotPreview,
          nextLabelOverride: ZyraJourneyStages.previewLabelFor('wali_gate'),
          continueAction: _continueLifeSnapshot,
        ),
      );
    }
    switch (_stage) {
      case 'compatibility_reveal':
        return _CompatibilityRevealView(
          matchId: widget.matchId,
          profile: widget.profile,
          isActionVisible: _stageActionVisible,
          isCurrentSurface: _captureCompatibilitySurfaceOwner(readOnly: false),
          onContinue: () => _openStageDecision(
            fromStage: 'compatibility_reveal',
            nextLabelOverride: ZyraJourneyStages.lifeSnapshotPreview.label,
            continueAction: _openLifeSnapshot,
          ),
          waitingReason: _advanceReason,
        );
      case 'salam_exchange':
        return _SalamExchangeView(
          matchId: widget.matchId,
          profile: widget.profile,
          isActionVisible: _stageActionVisible,
          onContinue: () => _openStageDecision(
            fromStage: 'salam_exchange',
            continueAction: () => _advance('salam_exchange'),
          ),
        );
      case 'wali_gate':
        return _WaliGateView(
          profile: widget.profile,
          otherFirstName: widget.profile.firstName,
          reason: _advanceReason,
          onChanged: _resetGuardianGate,
          devMode: _isDevAccount,
          selectedGuardianIndices: _devGuardianSelections,
          onPrepareDevGuardians: _prepareDevGuardianGate,
          mineRevealed: _guardianProfilesMineRevealed,
          theirsRevealed: _guardianProfilesTheirsRevealed,
          onReveal: _revealGuardianProfiles,
          guardianSalamIndices: _guardianSalamIndices,
          onGuardianSalam: _recordGuardianSalam,
          onPortraitsResolved: _rememberGuardianPortraits,
          // Mutual reveal completes this chapter. Individual Guardian Salams
          // remain optional and never become another progression gate.
          onContinue: () => _advance('wali_gate'),
        );
      case 'phase_1':
        return _PhaseView(
          matchId: widget.matchId,
          profile: widget.profile,
          phase: 1,
          isActionVisible: _stageActionVisible,
          onAdvance: () => _advanceGated('phase_1', 'phase_2'),
          onRequestDecision: (continueAction) => _openStageDecision(
            fromStage: 'phase_1',
            continueAction: continueAction,
          ),
        );
      case 'phase_2':
        return _PhaseView(
          matchId: widget.matchId,
          profile: widget.profile,
          phase: 2,
          isActionVisible: _stageActionVisible,
          onAdvance: () => _advanceGated('phase_2', 'phase_3'),
          onRequestDecision: (continueAction) => _openStageDecision(
            fromStage: 'phase_2',
            continueAction: continueAction,
          ),
        );
      case 'phase_3':
        return _PhaseView(
          matchId: widget.matchId,
          profile: widget.profile,
          phase: 3,
          isActionVisible: _stageActionVisible,
          onAdvance: () => _advanceGated('phase_3', 'family_stage'),
          onRequestDecision: (continueAction) => _openStageDecision(
            fromStage: 'phase_3',
            continueAction: continueAction,
          ),
        );
      case 'family_stage':
        return _FamilyStageView(
          matchId: widget.matchId,
          profile: widget.profile,
          isActionVisible: _stageActionVisible,
          onAdvance: () => _advanceGated('family_stage', 'conversation'),
          onRequestDecision: (continueAction) => _openStageDecision(
            fromStage: 'family_stage',
            continueAction: continueAction,
          ),
        );
      case 'conversation':
        // WAS an immediate pushReplacement into ChatScreen. The eighth stage
        // therefore had no screen at all: you arrived at the end of a Journey
        // and were dropped into a message list with no acknowledgement that
        // anything had been reached.
        //
        // It also made the stage impossible to look at — every visit bounced
        // straight past it — which is how it went this long without anyone
        // noticing the conversation row it needs was never created for a
        // seeded match.
        //
        // JOURNEY PHILOSOPHY §2: "structure does not disappear... the
        // experience does not suddenly become a standard chat app." A door,
        // then, rather than a trapdoor.
        return _OpenConversationView(
          matchId: widget.matchId,
          profile: widget.profile,
        );
      default:
        return const ZyraLoading();
    }
  }
}

class _MainGuardianRequiredJourneyView extends StatelessWidget {
  final SeekerProfile profile;
  final bool paused;
  final bool busy;
  final bool waitingOnOther;
  final VoidCallback? onChooseGuardian;
  final Future<void> Function()? onPause;
  final Future<void> Function() onEnd;

  const _MainGuardianRequiredJourneyView({
    required this.profile,
    required this.paused,
    required this.busy,
    required this.waitingOnOther,
    required this.onChooseGuardian,
    required this.onPause,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
    child: Column(
      children: [
        _JourneyAppBar(profile: profile),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 34,
                    color: ZyraColors.journeyGold,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    waitingOnOther
                        ? 'This Journey is waiting'
                        : 'Choose a Main Guardian',
                    style: ZyraText.heading(size: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    waitingOnOther
                        ? '${profile.firstName} needs to choose a Main Guardian before this Journey can continue.'
                        : paused
                        ? 'This Journey stays paused until you choose the Guardian who leads.'
                        : 'This Journey is held until you choose the Guardian who leads.',
                    style: ZyraText.subtext(size: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (onChooseGuardian != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : onChooseGuardian,
                        child: const Text('Go to Guardian'),
                      ),
                    ),
                  if (onPause != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: busy ? null : onPause,
                        child: const Text('Pause Journey'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: busy ? null : onEnd,
                    child: const Text('End Journey'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The Journey's shared visual atmosphere.
///
/// Founder direction, 2026-08-17: the neutral purple was correct but felt
/// flat. This adds restrained layered light behind every stage. The first
/// implementation moved those full-screen layers continuously; they are now
/// deliberately static because repainting them at display refresh rate was a
/// measurable thermal cost with no functional value. People are
/// always rendered as real profile photos in the foreground; decoration must
/// never sit behind and collide with readable content. Reduced-motion users
/// get the same layered colour without animation.
class _JourneyAtmosphere extends StatefulWidget {
  final String? stage;

  const _JourneyAtmosphere({required this.stage});

  @override
  State<_JourneyAtmosphere> createState() => _JourneyAtmosphereState();
}

class _JourneyAtmosphereState extends State<_JourneyAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
      value: 0.5,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final stage = ZyraJourneyStages.of(widget.stage);
    final step = stage?.order ?? 1;
    final stageShift = ((step - 1) / (ZyraJourneyStages.all.length - 1)) * 28;

    Widget scene(double t) {
      final eased = Curves.easeInOut.transform(t);
      return IgnorePointer(
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                top: -80 + (28 * eased),
                right: -95 + stageShift,
                child: Transform.scale(
                  scale: 0.96 + (0.08 * eased),
                  child: _JourneyGlow(
                    size: 300,
                    colour: ZyraColors.actionFill,
                    opacity: 0.24,
                  ),
                ),
              ),
              Positioned(
                bottom: -110 + (22 * (1 - eased)),
                left: -105 + (28 - stageShift),
                child: Transform.scale(
                  scale: 1.04 - (0.07 * eased),
                  child: const _JourneyGlow(
                    size: 330,
                    colour: Color(0xFF73579A),
                    opacity: 0.26,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (reduceMotion) return scene(0.5);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => scene(_controller.value),
    );
  }
}

class _JourneyGlow extends StatelessWidget {
  final double size;
  final Color colour;
  final double opacity;

  const _JourneyGlow({
    required this.size,
    required this.colour,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colour.withValues(alpha: opacity),
            colour.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// A human version of the Journey's connection mark. The completed person is
/// bright; the person whose action is still needed is deliberately softened.
/// The quiet orbit is a waiting signal, not a loading spinner.
class _JourneyPairStatus extends StatefulWidget {
  final SeekerProfile profile;
  final bool youComplete;
  final bool otherComplete;
  final bool emphasizeWaiting;
  final bool salamGoldWake;
  final bool motionEnabled;
  final String youCompleteLabel;
  final String youWaitingLabel;
  final String otherCompleteLabel;
  final String otherWaitingLabel;

  const _JourneyPairStatus({
    required this.profile,
    required this.youComplete,
    required this.otherComplete,
    this.emphasizeWaiting = false,
    this.salamGoldWake = false,
    this.motionEnabled = true,
    this.youCompleteLabel = 'Done',
    this.youWaitingLabel = 'Waiting',
    this.otherCompleteLabel = 'Done',
    this.otherWaitingLabel = 'Waiting',
  });

  @override
  State<_JourneyPairStatus> createState() => _JourneyPairStatusState();
}

class _JourneyPairStatusState extends State<_JourneyPairStatus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3100),
    value: 0.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _JourneyPairStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.salamGoldWake != widget.salamGoldWake ||
        oldWidget.motionEnabled != widget.motionEnabled ||
        oldWidget.youComplete != widget.youComplete ||
        oldWidget.otherComplete != widget.otherComplete) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    final connection = ZyraSalamConnectionPolicy.resolve(
      mine: widget.youComplete,
      theirs: widget.otherComplete,
    );
    final travelling =
        connection == ZyraSalamConnectionMotion.outbound ||
        connection == ZyraSalamConnectionMotion.inbound;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate =
        widget.salamGoldWake &&
        widget.motionEnabled &&
        travelling &&
        !reduceMotion &&
        TickerMode.valuesOf(context).enabled;
    if (shouldAnimate) {
      if (!_pulse.isAnimating) _pulse.repeat();
      return;
    }
    _pulse.stop();
    if (_pulse.value != 0.5) _pulse.value = 0.5;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget portrait({
      required bool you,
      required bool complete,
      required double t,
    }) {
      final photos = you ? AppState.instance.photos : widget.profile.photos;
      final name = you
          ? (AppState.instance.name ?? 'You')
          : widget.profile.firstName;
      final waiting = !complete;
      final highlightedWaiting =
          !widget.salamGoldWake && widget.emphasizeWaiting && !you && !complete;
      final statusLabel = complete
          ? (you ? widget.youCompleteLabel : widget.otherCompleteLabel)
          : (you ? widget.youWaitingLabel : widget.otherWaitingLabel);
      return Semantics(
        label: '$name, $statusLabel',
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 420),
          opacity: complete || highlightedWaiting ? 1 : 0.38,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (highlightedWaiting) ...[
                      Transform.scale(
                        scale: 1.05 + (0.18 * t),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFFCEA2D1,
                              ).withValues(alpha: 0.12 + (0.24 * (1 - t))),
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 1 + (0.09 * t),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 1.2,
                              color: const Color(
                                0xFFE8C98A,
                              ).withValues(alpha: 0.2 + (0.26 * t)),
                            ),
                          ),
                        ),
                      ),
                    ],
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: widget.salamGoldWake
                              ? 2
                              : waiting
                              ? 1.5 + t
                              : 2,
                          color: widget.salamGoldWake
                              ? (complete
                                    ? const Color(
                                        0xFFE8C98A,
                                      ).withValues(alpha: 0.9)
                                    : Colors.transparent)
                              : (complete
                                        ? ZyraColors.journeyGold
                                        : Colors.white)
                                    .withValues(
                                      alpha: complete
                                          ? 0.8
                                          : highlightedWaiting
                                          ? 0.68
                                          : 0.32,
                                    ),
                        ),
                        boxShadow: widget.salamGoldWake
                            ? complete
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE8C98A,
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : const []
                            : [
                                BoxShadow(
                                  color: ZyraColors.actionFill.withValues(
                                    alpha: complete
                                        ? 0.24
                                        : highlightedWaiting
                                        ? 0.18 + (0.16 * t)
                                        : 0.08 + (0.08 * t),
                                  ),
                                  blurRadius: complete
                                      ? 24
                                      : highlightedWaiting
                                      ? 20 + (12 * t)
                                      : 14 + (8 * t),
                                  spreadRadius: complete
                                      ? 1
                                      : highlightedWaiting
                                      ? 1 + (2 * t)
                                      : t,
                                ),
                              ],
                      ),
                      child: ClipOval(
                        child: photos.isEmpty
                            ? ColoredBox(
                                color: ZyraColors.foreground.withValues(
                                  alpha: 0.1,
                                ),
                                child: Center(
                                  child: Text(
                                    you
                                        ? 'You'
                                        : (name.isEmpty ? '?' : name[0]),
                                    style: ZyraText.subtext(
                                      size: you ? 11 : 19,
                                    ),
                                  ),
                                ),
                              )
                            : ZyraProfileImage(
                                photos.first,
                                width: 60,
                                height: 60,
                              ),
                      ),
                    ),
                    if (!widget.salamGoldWake)
                      AnimatedScale(
                        scale: complete ? 1 : 0,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ZyraColors.journeyGold,
                              border: Border.all(
                                color: ZyraColors.luxuryDarkPurple,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE8C98A,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: ZyraColors.luxuryDarkPurple,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 7),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  key: ValueKey(statusLabel),
                  width: 92,
                  height: 26,
                  child: Text(
                    statusLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: ZyraText.subtext(
                      size: 10.5,
                      color: ZyraColors.foreground.withValues(
                        alpha: complete ? 0.8 : 0.5,
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

    Widget scene(double t) {
      final connection = ZyraSalamConnectionPolicy.resolve(
        mine: widget.youComplete,
        theirs: widget.otherComplete,
      );
      final travelling =
          connection == ZyraSalamConnectionMotion.outbound ||
          connection == ZyraSalamConnectionMotion.inbound;
      const lineLeft = 68.0;
      const lineWidth = 94.0;
      final travel = ((t - 0.12) / 0.76).clamp(0.0, 1.0).toDouble();
      final travelOpacity = t < 0.12
          ? (t / 0.12).clamp(0.0, 1.0).toDouble()
          : t > 0.88
          ? ((1 - t) / 0.12).clamp(0.0, 1.0).toDouble()
          : 1.0;
      final outbound = connection == ZyraSalamConnectionMotion.outbound;
      final dotProgress = outbound ? travel : 1 - travel;
      final wakeWidth = lineWidth * travel;
      final wakeLeft = outbound ? lineLeft : lineLeft + lineWidth - wakeWidth;

      return SizedBox(
        width: 230,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 33,
              left: lineLeft,
              width: lineWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                height: widget.salamGoldWake ? 1 : 1.5,
                decoration: widget.salamGoldWake
                    ? BoxDecoration(
                        color: connection == ZyraSalamConnectionMotion.settled
                            ? ZyraColors.journeyGold.withValues(alpha: 0.74)
                            : ZyraColors.foreground.withValues(alpha: 0.28),
                      )
                    : BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            ZyraColors.journeyGold.withValues(
                              alpha: widget.youComplete ? 0.7 : 0.16,
                            ),
                            ZyraColors.foreground.withValues(
                              alpha: 0.2 + (0.18 * t),
                            ),
                            ZyraColors.journeyGold.withValues(
                              alpha: widget.otherComplete ? 0.7 : 0.16,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            if (widget.salamGoldWake && travelling) ...[
              Positioned(
                top: 32,
                left: wakeLeft,
                width: wakeWidth,
                child: Opacity(
                  opacity: 0.72 * travelOpacity,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: outbound
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        end: outbound
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        colors: [
                          ZyraColors.journeyGold,
                          ZyraColors.journeyGold.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                left: lineLeft - 3 + (lineWidth * dotProgress),
                child: Opacity(
                  opacity: travelOpacity,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ZyraColors.journeyGold,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFE8C98A,
                          ).withValues(alpha: 0.88),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                portrait(you: true, complete: widget.youComplete, t: t),
                portrait(you: false, complete: widget.otherComplete, t: t),
              ],
            ),
          ],
        ),
      );
    }

    if (reduceMotion) return scene(0.5);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => scene(Curves.easeInOut.transform(_pulse.value)),
    );
  }
}

/// THE RIBBON — DR-ZYRA-185, the Journey's header. One mark per displayed
/// chapter: walked ones filled in quiet gold, the road ahead
/// faint, and the chapter underfoot opened into a pill that says its
/// number and name. Labels come from the canonical map (DR-ZYRA-129);
/// during a Family Review the pill carries the override label instead.
/// Gold completed dots navigate; faint future dots and the current pill do not.
class _JourneyRibbon extends StatelessWidget {
  final String? stage;
  final List<ZyraJourneyStage> stages;
  final bool reviewOpen;
  final ValueChanged<int> onCompletedStageTap;
  const _JourneyRibbon({
    required this.stage,
    required this.stages,
    required this.reviewOpen,
    required this.onCompletedStageTap,
  });

  static const _gold = ZyraColors.journeyGold;

  @override
  Widget build(BuildContext context) {
    ZyraJourneyStage? selected;
    for (final candidate in stages) {
      if (candidate.value == stage) {
        selected = candidate;
        break;
      }
    }
    if (selected == null) return SizedBox.shrink();
    final current = selected;
    final children = <Widget>[];
    for (final st in stages) {
      if (children.isNotEmpty) children.add(SizedBox(width: 3));
      if (st.order == current.order) {
        children.add(
          Flexible(
            fit: FlexFit.loose,
            child: IntrinsicWidth(
              child: Container(
                constraints: const BoxConstraints(minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: _gold.withValues(alpha: 0.10),
                  border: Border.all(color: _gold, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.30),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  '${current.order} · ${reviewOpen ? ZyraJourneyStages.familyReviewOverride : current.label}',
                  style: ZyraText.subtext(size: 11.5, color: _gold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      } else {
        final walked = st.order < current.order;
        children.add(
          Semantics(
            button: walked,
            enabled: walked,
            label: walked
                ? 'View completed Stage ${st.order}: ${st.label}'
                : 'Stage ${st.order}: ${st.label}',
            child: InkResponse(
              onTap: walked ? () => onCompletedStageTap(st.order) : null,
              radius: 15,
              child: SizedBox(
                width: 20,
                height: 24,
                child: Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: walked
                          ? _gold.withValues(alpha: 0.68)
                          : ZyraColors.luxuryDarkPurple.withValues(alpha: 0.4),
                      border: walked
                          ? null
                          : Border.all(
                              color: ZyraColors.foreground.withValues(
                                alpha: 0.2,
                              ),
                              width: 1,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

/// A calm boundary between chapters. Reaching this page has not silently
/// advanced anything: the member chooses whether to keep moving, rest the
/// Journey, or close it. End retains its separate final confirmation.
class _JourneyStageDecisionPage extends StatelessWidget {
  final ZyraJourneyStage stage;
  final String nextLabel;
  final bool completionConfirmed;
  final bool busy;
  final bool continueSelected;
  final VoidCallback onBack;
  final VoidCallback onSelectContinue;
  final Future<void> Function() onCommitContinue;
  final VoidCallback onPause;
  final VoidCallback onEnd;

  const _JourneyStageDecisionPage({
    required this.stage,
    required this.nextLabel,
    required this.completionConfirmed,
    required this.busy,
    required this.continueSelected,
    required this.onBack,
    required this.onSelectContinue,
    required this.onCommitContinue,
    required this.onPause,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const verticalPadding = 50.0;
        final centredHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - verticalPadding)
                  .clamp(0.0, double.infinity)
                  .toDouble()
            : 0.0;
        return SingleChildScrollView(
          // This page fits in the Journey viewport. Disabling its own vertical
          // drag recogniser lets the surrounding PageView receive the gesture,
          // so dragging back up reliably returns to the exact completed stage.
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: centredHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Return to the completed stage',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: busy ? null : onBack,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 24,
                                color: ZyraColors.foreground.withValues(
                                  alpha: 0.52,
                                ),
                              ),
                              Text(
                                'Stage ${stage.order} completion above',
                                style: ZyraText.subtext(
                                  size: 10.5,
                                  color: ZyraColors.foreground.withValues(
                                    alpha: 0.52,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _JourneyDecisionBeat(
                      nodeColor: const Color(0xFFE0C678),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completionConfirmed
                                ? 'STAGE ${stage.order} COMPLETE'
                                : 'STAGE ${stage.order} CHECKPOINT',
                            style: ZyraText.chapterLabel(
                              color: ZyraColors.ink(0.54),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            completionConfirmed
                                ? stage.completionHeading
                                : 'Ready to move forward?',
                            style: ZyraText.heading(size: 23),
                          ),
                          SizedBox(height: 7),
                          Text(
                            completionConfirmed
                                ? stage.completionLine
                                : 'ZYRA will first confirm that both Main Guardians are present.',
                            style: ZyraText.subtext(size: 13.5),
                          ),
                        ],
                      ),
                    ),
                    _JourneyDecisionBeat(
                      nodeColor: const Color(0xFF9D86AD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STAGE ${stage.order + 1} AHEAD',
                            style: ZyraText.chapterLabel(
                              color: ZyraColors.ink(0.54),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(nextLabel, style: ZyraText.heading(size: 20)),
                          SizedBox(height: 6),
                          Text(
                            'The next chapter waits below.',
                            style: ZyraText.subtext(size: 13),
                          ),
                        ],
                      ),
                    ),
                    _JourneyDecisionBeat(
                      nodeColor: ZyraColors.journeyDotGreen,
                      last: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR DECISION',
                            style: ZyraText.chapterLabel(
                              color: ZyraColors.ink(0.54),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'How will you continue?',
                            style: ZyraText.heading(size: 20),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Continue, pause, or end your Journey.',
                            style: ZyraText.subtext(size: 13),
                          ),
                          SizedBox(height: 15),
                          _JourneyOpenDecisionRail(
                            busy: busy,
                            continueSelected: continueSelected,
                            onContinue: onSelectContinue,
                            onPause: onPause,
                            onEnd: onEnd,
                          ),
                          if (continueSelected) ...[
                            SizedBox(height: 8),
                            _JourneyScrollToContinue(
                              onContinue: onCommitContinue,
                              idleLabel: 'Continue',
                              openingLabel: 'Continuing…',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _JourneyDecisionBeat extends StatelessWidget {
  final Color nodeColor;
  final bool last;
  final Widget child;

  const _JourneyDecisionBeat({
    required this.nodeColor,
    required this.child,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                SizedBox(height: 3),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nodeColor,
                    border: Border.all(
                      color: ZyraColors.luxuryDarkPurple,
                      width: 3,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: ZyraColors.foreground.withValues(alpha: 0.28),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 28),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyOpenDecisionRail extends StatelessWidget {
  final bool busy;
  final bool continueSelected;
  final VoidCallback onContinue;
  final VoidCallback onPause;
  final VoidCallback onEnd;

  const _JourneyOpenDecisionRail({
    required this.busy,
    required this.continueSelected,
    required this.onContinue,
    required this.onPause,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          height: 1,
          color: ZyraColors.foreground.withValues(alpha: 0.24),
        ),
        _JourneyOpenDecisionAction(
          label: continueSelected ? 'Continue selected' : 'Continue',
          dotColor: ZyraColors.journeyDotGreen,
          selected: continueSelected,
          onTap: busy ? null : onContinue,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: continueSelected
              ? SizedBox.shrink(key: ValueKey('continue-selected'))
              : Column(
                  key: const ValueKey('all-decisions'),
                  children: [
                    _JourneyOpenDecisionAction(
                      label: 'Request Pause',
                      dotColor: const Color(0xFFDFBD62),
                      onTap: busy ? null : onPause,
                    ),
                    _JourneyOpenDecisionAction(
                      label: 'End Journey',
                      dotColor: const Color(0xFFDF7D82),
                      destructive: true,
                      onTap: busy ? null : onEnd,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _JourneyOpenDecisionAction extends StatelessWidget {
  final String label;
  final Color dotColor;
  final bool destructive;
  final bool selected;
  final VoidCallback? onTap;

  const _JourneyOpenDecisionAction({
    required this.label,
    required this.dotColor,
    required this.onTap,
    this.destructive = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.42 : 1,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: selected
                  ? ZyraColors.journeyGold.withValues(alpha: 0.09)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? ZyraColors.journeyGold.withValues(alpha: 0.52)
                      : ZyraColors.foreground.withValues(alpha: 0.24),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: ZyraText.body(
                      size: 13,
                      color: destructive
                          ? ZyraColors.destructive
                          : Colors.white,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_rounded : Icons.chevron_right_rounded,
                  size: 20,
                  color: selected
                      ? ZyraColors.journeyGold
                      : ZyraColors.foreground.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _JourneyLifecycleAction { pause, end }

enum _JourneyLifecycleFailure { failed }

/// Exact production Pause-confirm surface with an injectable write, used to
/// force the unknown-failure branch without a live backend outage.
@visibleForTesting
Widget buildZyraPauseFailureTestSurface({
  required Future<void> Function() write,
}) {
  return _JourneyLifecycleConfirmScreen(
    action: _JourneyLifecycleAction.pause,
    profile: const SeekerProfile(
      id: 'truthful-failure-test-profile',
      firstName: 'Adam',
      age: 30,
      city: 'London',
      photos: <String>[],
      gender: 'male',
    ),
    onConfirm: () async {
      await write();
      return null;
    },
  );
}

const _requestNewJourneyHoldTestProfile = SeekerProfile(
  id: 'request-new-journey-hold-test-profile',
  firstName: 'Maryam',
  age: 30,
  city: 'London',
  photos: <String>[],
  gender: 'female',
);

@visibleForTesting
Widget buildZyraEndConfirmationTestSurface() => _JourneyLifecycleConfirmScreen(
  action: _JourneyLifecycleAction.end,
  profile: _requestNewJourneyHoldTestProfile,
  onConfirm: () async => null,
);

@visibleForTesting
Widget buildZyraJourneyEndedCompleteTestSurface() =>
    const _JourneyLifecycleCompleteScreen(
      profile: _requestNewJourneyHoldTestProfile,
    );

@visibleForTesting
Widget buildZyraEndedJourneyTestSurface() =>
    const _EndedView(profile: _requestNewJourneyHoldTestProfile);

class _JourneyLifecycleConfirmScreen extends StatefulWidget {
  final _JourneyLifecycleAction action;
  final SeekerProfile profile;
  final Future<_JourneyLifecycleFailure?> Function() onConfirm;

  const _JourneyLifecycleConfirmScreen({
    required this.action,
    required this.profile,
    required this.onConfirm,
  });

  @override
  State<_JourneyLifecycleConfirmScreen> createState() =>
      _JourneyLifecycleConfirmScreenState();
}

class _JourneyLifecycleConfirmScreenState
    extends State<_JourneyLifecycleConfirmScreen> {
  bool _busy = false;
  String? _error;

  bool get _pausing => widget.action == _JourneyLifecycleAction.pause;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    _JourneyLifecycleFailure? failure;
    try {
      failure = await widget.onConfirm();
    } catch (_) {
      failure = _JourneyLifecycleFailure.failed;
    }
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _busy = false;
      _error = switch (failure) {
        _JourneyLifecycleFailure.failed =>
          _pausing
              ? "Pause request didn't go through. Check your connection and try again."
              : "End didn't go through. Check your connection and try again.",
        null => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = _pausing ? const Color(0xFFDFBD62) : const Color(0xFFDF7D82);
    final actionTitle = _pausing ? 'Request Pause' : 'End Journey';
    final body = _pausing
        ? 'This asks for space without deciding the Journey for either of '
              'you. Nothing in your Journey is lost.'
        : 'Ending closes this Journey for both of you. It cannot resume from '
              'this point.';
    final detail = _pausing
        ? '${widget.profile.firstName} can agree to pause, request to '
              'continue, or end the Journey. Until then, it stays Active but '
              'locked for both of you.'
        : ZyraReleaseGates.requestNewJourneyEnabled
        ? 'For 60 days after ending, one of you may request a new Journey '
              'and the other must accept. After that, you would need to find '
              'each other again in Profiles. Your Timeline is kept.'
        : '${ZyraReleaseGates.requestNewJourneyUnavailable} '
              'Your Timeline is kept.';

    return Scaffold(
      body: Container(
        decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: ZyraColors.ink(0.70),
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        actionTitle,
                        style: ZyraText.subtext(
                          size: 13,
                          color: ZyraColors.ink(0.70),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 44, 32, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: Column(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                            ),
                          ),
                          SizedBox(height: 22),
                          Text(
                            _pausing ? 'Request a pause?' : 'End this Journey?',
                            style: ZyraText.heading(size: 25),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            body,
                            style: ZyraText.body(size: 14),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          Container(width: 54, height: 1, color: accent),
                          SizedBox(height: 20),
                          Text(
                            detail,
                            style: ZyraText.subtext(size: 13),
                            textAlign: TextAlign.center,
                          ),
                          if (_error != null) ...[
                            SizedBox(height: 18),
                            Text(
                              _error!,
                              style: ZyraText.subtext(
                                size: 12.5,
                                color: ZyraColors.destructive,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          SizedBox(height: 30),
                          _JourneySolidAction(
                            label: _busy
                                ? (_pausing ? 'Requesting…' : 'Ending…')
                                : (_pausing ? 'Request Pause' : 'End Journey'),
                            accent: accent,
                            destructive: !_pausing,
                            onTap: _busy ? null : _confirm,
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: Text(
                              _pausing ? 'Keep Journey active' : 'Keep Journey',
                              style: ZyraText.subtext(
                                size: 12.5,
                                color: ZyraColors.ink(0.70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _JourneyLifecycleCompleteScreen extends StatelessWidget {
  final SeekerProfile profile;

  const _JourneyLifecycleCompleteScreen({required this.profile});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFDF7D82);

    return Scaffold(
      body: Container(
        decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    SizedBox(height: 22),
                    Text(
                      'JOURNEY ENDED',
                      style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'This chapter has closed.',
                      style: ZyraText.heading(size: 25),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '${profile.firstName} has been notified. Your Timeline '
                      'is kept, but continuing together would mean '
                      'beginning a new Journey.',
                      style: ZyraText.body(size: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Container(width: 54, height: 1, color: accent),
                    SizedBox(height: 20),
                    Text(
                      ZyraReleaseGates.requestNewJourneyEnabled
                          ? 'Starting again requires a new request and agreement '
                                'from both of you. The direct request is available '
                                'for 60 days; after that, you would need to meet '
                                'again in Profiles.'
                          : ZyraReleaseGates.requestNewJourneyUnavailable,
                      style: ZyraText.subtext(size: 13),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 34),
                    _JourneySolidAction(
                      label: 'Return to Connections',
                      accent: accent,
                      onTap: () => Navigator.of(context).pop(),
                    ),
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

class _JourneySolidAction extends StatelessWidget {
  final String label;
  final Color accent;
  final bool destructive;
  final VoidCallback? onTap;

  const _JourneySolidAction({
    required this.label,
    required this.accent,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Material(
          color: destructive
              ? const Color(0xFF56313B)
              : ZyraColors.sheetSurface,
          shape: StadiumBorder(side: BorderSide(color: accent, width: 1)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: ZyraText.button(
                  size: 13.5,
                  color: destructive ? accent : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// THE JOURNEY'S ONE BUTTON LANGUAGE — DR-ZYRA-186 (Founder: "i want
/// the ui to be same and i want it to copy the part-the-veil design").
/// The frosted stadium the veil introduced, now shared by every
/// threshold the Journey itself presents — the opening beats and each
/// chapter's entry — so the same gesture always looks the same.
class _FrostPill extends StatelessWidget {
  final String label;

  /// Null renders the pill dimmed and inert — the frost language's own
  /// disabled state (DR-ZYRA-189 made it the Journey's ONLY button, so
  /// it had to learn the states FilledButton carried).
  final VoidCallback? onTap;
  const _FrostPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Opacity(opacity: 0.45, child: _pill(context));
    }
    return _pill(context);
  }

  Widget _pill(BuildContext context) {
    return Material(
      color: ZyraColors.surfaceEmphasisFill,
      shape: StadiumBorder(
        side: BorderSide(color: ZyraColors.surfaceEmphasisBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          child: Text(label, style: ZyraText.button(size: 13.5)),
        ),
      ),
    );
  }
}

/// The Journey's primary human action. A calm icon and soft halo separate
/// a meaningful threshold action from compact navigation/checkpoint pills,
/// while preserving ordinary button semantics and a generous tap target.
class _JourneyRoundAction extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final bool showLabel;

  const _JourneyRoundAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.waving_hand_outlined,
    this.showLabel = true,
  });

  @override
  State<_JourneyRoundAction> createState() => _JourneyRoundActionState();
}

class _JourneyRoundActionState extends State<_JourneyRoundAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      value: 0.5,
    );
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Widget action(double t) => Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 0.94 + (0.1 * t),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFE8C98A,
                            ).withValues(alpha: 0.18 + (0.2 * t)),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ZyraColors.foreground.withValues(alpha: 0.1),
                        border: Border.all(
                          color: ZyraColors.foreground.withValues(alpha: 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFCEA2D1,
                            ).withValues(alpha: 0.1 + (0.08 * t)),
                            blurRadius: 18 + (6 * t),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: ZyraColors.journeyGold,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showLabel) ...[
                SizedBox(height: 7),
                Text(widget.label, style: ZyraText.button(size: 13.5)),
              ],
            ],
          ),
        ),
      ),
    );

    final content = reduceMotion
        ? action(0.5)
        : AnimatedBuilder(
            animation: _breath,
            builder: (context, _) =>
                action(Curves.easeInOut.transform(_breath.value)),
          );
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.label,
      onTap: widget.onTap,
      child: Opacity(opacity: widget.onTap == null ? 0.45 : 1, child: content),
    );
  }
}

/// The shared visual invitation at the end of every completed Journey stage.
/// Actions remain explicit buttons; leaving a completed chapter is always a
/// deliberate upward scroll through this invitation.
class _JourneyScrollInvitation extends StatefulWidget {
  final VoidCallback onContinue;
  final double progress;
  final bool continuing;
  final String idleLabel;
  final String openingLabel;

  const _JourneyScrollInvitation({
    required this.onContinue,
    required this.progress,
    required this.continuing,
    this.idleLabel = 'Scroll to continue',
    required this.openingLabel,
  });

  @override
  State<_JourneyScrollInvitation> createState() =>
      _JourneyScrollInvitationState();
}

class _JourneyScrollInvitationState extends State<_JourneyScrollInvitation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _invitation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
    value: 0.5,
  );

  @override
  void dispose() {
    _invitation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.0, 1.0).toDouble();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: 'Scroll to continue the Journey',
      onTap: widget.continuing ? null : widget.onContinue,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.continuing ? null : widget.onContinue,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _invitation,
                    builder: (context, child) {
                      final idleDrop = reduceMotion || progress > 0
                          ? 0.0
                          : 4 * Curves.easeInOut.transform(_invitation.value);
                      return Transform.translate(
                        offset: Offset(0, idleDrop + (8 * progress)),
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 30,
                      color: const Color(
                        0xFFE8C98A,
                      ).withValues(alpha: 0.58 + (0.36 * progress)),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.continuing ? widget.openingLabel : widget.idleLabel,
                    style: ZyraText.subtext(
                      size: 13,
                      color: ZyraColors.foreground.withValues(
                        alpha: 0.58 + (0.3 * progress),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Self-contained completion gesture used by Stages 2–7. The gesture begins
/// on the invitation at the end of the completed content, so reading or
/// scrolling through a long result cannot accidentally advance the Journey.
class _JourneyScrollToContinue extends StatefulWidget {
  final Future<void> Function() onContinue;
  final String idleLabel;
  final String openingLabel;
  final Widget? child;
  final bool expand;

  const _JourneyScrollToContinue({
    required this.onContinue,
    this.idleLabel = 'Scroll to continue',
    this.openingLabel = 'Opening your choices…',
    this.child,
    this.expand = false,
  });

  @override
  State<_JourneyScrollToContinue> createState() =>
      _JourneyScrollToContinueState();
}

class _JourneyScrollToContinueState extends State<_JourneyScrollToContinue> {
  static const _threshold = 22.0;
  double _distance = 0;
  bool _committed = false;
  Timer? _signalReset;

  @override
  void dispose() {
    _signalReset?.cancel();
    super.dispose();
  }

  void _start(PointerDownEvent event) {
    if (_committed) return;
    _signalReset?.cancel();
    setState(() => _distance = 0);
  }

  void _track(PointerMoveEvent event) {
    _applyDelta(-event.delta.dy);
  }

  void _trackSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _applyDelta(event.scrollDelta.dy);
    _signalReset?.cancel();
    _signalReset = Timer(const Duration(milliseconds: 450), () {
      if (mounted && !_committed && _distance != 0) {
        setState(() => _distance = 0);
      }
    });
  }

  void _applyDelta(double delta) {
    if (_committed) return;
    final distance = ZyraJourneyScroll.completionDistanceAfterInput(
      currentDistance: _distance,
      forwardDelta: delta,
      threshold: _threshold,
    );
    if (distance >= _threshold) {
      _signalReset?.cancel();
      setState(() => _distance = _threshold);
      unawaited(_continue());
      return;
    }
    setState(() => _distance = distance);
  }

  void _finish(PointerEvent event) {
    if (_committed || _distance == 0) return;
    setState(() => _distance = 0);
  }

  Future<void> _continue() async {
    if (_committed) return;
    setState(() => _committed = true);
    await widget.onContinue();
    // A successful transition disposes this invitation. If the server holds
    // the stage, reset it so the member can try again honestly.
    if (!mounted) return;
    setState(() {
      _committed = false;
      _distance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final invitation = _JourneyScrollInvitation(
      onContinue: () => unawaited(_continue()),
      progress: _distance / _threshold,
      continuing: _committed,
      idleLabel: widget.idleLabel,
      openingLabel: widget.openingLabel,
    );
    final contents = widget.child == null
        ? invitation
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [widget.child!, invitation],
          );
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _start,
      onPointerMove: _track,
      onPointerSignal: _trackSignal,
      onPointerUp: _finish,
      onPointerCancel: _finish,
      child: widget.expand
          ? SizedBox.expand(child: Center(child: contents))
          : contents,
    );
  }
}

/// Carries a confirmed stage boundary through the same vertical movement as
/// the Journey's section PageView. Holding the outgoing child explicitly is
/// intentional: AnimatedSwitcher reverses a single slide tween, which would
/// send the old page back down. A Journey moves forward with the old page
/// leaving above and the new one arriving from below.
class _JourneyVerticalStageSwap extends StatefulWidget {
  final String surfaceKey;
  final Widget child;

  const _JourneyVerticalStageSwap({
    required this.surfaceKey,
    required this.child,
  });

  @override
  State<_JourneyVerticalStageSwap> createState() =>
      _JourneyVerticalStageSwapState();
}

class _JourneyVerticalStageSwapState extends State<_JourneyVerticalStageSwap>
    with SingleTickerProviderStateMixin {
  late Widget _current;
  Widget? _previous;
  late final AnimationController _controller;

  late final Animation<Offset> _incoming = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<Offset> _outgoing = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -1),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      value: 1,
    );
    _current = widget.child;
  }

  @override
  void didUpdateWidget(covariant _JourneyVerticalStageSwap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surfaceKey == widget.surfaceKey) {
      _current = widget.child;
      return;
    }

    _previous = _current;
    _current = widget.child;
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _previous = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion || _previous == null) {
      return SizedBox.expand(child: _current);
    }

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: SlideTransition(position: _outgoing, child: _previous),
          ),
          SlideTransition(position: _incoming, child: _current),
        ],
      ),
    );
  }
}

/// One continuous arrival-to-action surface for every real Journey stage.
/// Completed chapters remain physically above the current arrival as compact,
/// read-only endings. The screen opens at the current stage; scrolling up
/// revisits what was completed, while scrolling down reaches the live action.
class _JourneyStageScrollShell extends StatefulWidget {
  final ZyraJourneyStage stage;
  final List<ZyraJourneyStage> stages;
  final Widget child;
  final Widget compatibilityHistoryChild;
  final Widget salamHistoryChild;
  final Widget lifeSnapshotHistoryChild;
  final Widget guardianHistoryChild;
  final Widget? decisionChild;
  final VoidCallback onOpenTimeline;
  final ValueChanged<bool> onActionVisibilityChanged;
  final ValueChanged<ZyraJourneyStage> onViewedStageChanged;

  const _JourneyStageScrollShell({
    super.key,
    required this.stage,
    required this.stages,
    required this.child,
    required this.compatibilityHistoryChild,
    required this.salamHistoryChild,
    required this.lifeSnapshotHistoryChild,
    required this.guardianHistoryChild,
    this.decisionChild,
    required this.onOpenTimeline,
    required this.onActionVisibilityChanged,
    required this.onViewedStageChanged,
  });

  @override
  State<_JourneyStageScrollShell> createState() =>
      _JourneyStageScrollShellState();
}

class _JourneyStageScrollShellState extends State<_JourneyStageScrollShell> {
  late final PageController _pageController;
  static const double _innerPullThreshold = 34;
  static const double _historyForwardThreshold = 36;
  double _innerPullDistance = 0;
  bool _innerPullCommitted = false;
  int? _innerPullTargetPage;
  int? _historyPointerStartPage;
  double _historyForwardDistance = 0;

  List<ZyraJourneyStage> get _history =>
      List.unmodifiable(widget.stages.take(widget.stage.order - 1));

  @override
  void initState() {
    super.initState();
    // Completed endings sit above the current arrival. Open on that arrival,
    // never at the start of the whole history.
    _pageController = PageController(
      initialPage: ZyraJourneyScroll.arrivalPage(_history.length),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _JourneyStageScrollShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decisionChild == null && widget.decisionChild != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        final page = ZyraJourneyScroll.decisionPage(_history.length);
        if (reduceMotion) {
          _pageController.jumpToPage(page);
        } else {
          _pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void scrollToCompletedStage(int order) {
    if (order < 1 ||
        order >= widget.stage.order ||
        !_pageController.hasClients) {
      return;
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _pageController.jumpToPage(order - 1);
      return;
    }
    _pageController.animateToPage(
      order - 1,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  void showActionPage() {
    if (!_pageController.hasClients) return;
    final page = ZyraJourneyScroll.actionPage(_history.length);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _pageController.jumpToPage(page);
      return;
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  void _showPage(int page) {
    if (!_pageController.hasClients) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _pageController.jumpToPage(page);
      return;
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _settleInnerScrollableAt(int targetPage) async {
    if (_innerPullCommitted || !_pageController.hasClients) return;
    _innerPullCommitted = true;
    try {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _pageController.jumpToPage(targetPage);
      } else {
        await _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      _innerPullDistance = 0;
      _innerPullCommitted = false;
      _innerPullTargetPage = null;
    }
  }

  void _accumulateInnerPull({required int targetPage, required double delta}) {
    if (_innerPullCommitted || delta <= 0) return;
    if (_innerPullTargetPage != targetPage) {
      _innerPullTargetPage = targetPage;
      _innerPullDistance = 0;
    }
    _innerPullDistance = (_innerPullDistance + delta)
        .clamp(0, _innerPullThreshold)
        .toDouble();
    if (_innerPullDistance >= _innerPullThreshold) {
      unawaited(_settleInnerScrollableAt(targetPage));
    }
  }

  void _handlePageChanged(int page) {
    // A completed programmatic move or a fresh user drag always starts with a
    // clean inner-pull accumulator. This is what makes Action -> Arrival ->
    // Action repeatable instead of leaving a stale committed latch behind.
    _innerPullDistance = 0;
    _innerPullCommitted = false;
    _innerPullTargetPage = null;
    widget.onActionVisibilityChanged(
      ZyraJourneyScroll.isActionPage(
        page: page,
        completedStageCount: _history.length,
      ),
    );
    final viewedIndex = ZyraJourneyScroll.viewedStageIndex(
      page: page,
      completedStageCount: _history.length,
    );
    widget.onViewedStageChanged(
      viewedIndex < _history.length ? _history[viewedIndex] : widget.stage,
    );
  }

  void _startHistoryForwardSwipe(PointerDownEvent event) {
    _historyPointerStartPage = null;
    _historyForwardDistance = 0;
    if (!_pageController.hasClients) return;
    final page =
        (_pageController.page ?? _pageController.initialPage.toDouble())
            .round();
    final arrivalPage = ZyraJourneyScroll.arrivalPage(_history.length);
    if (page >= 0 && page < arrivalPage) {
      // Compatibility history owns a real inner scroll view so its result can
      // be read again. Its boundary handler decides when a pull has gone past
      // the content; the raw fallback is only for non-scrollable history.
      if (_history[page].value == 'compatibility_reveal' ||
          _history[page].value == ZyraJourneyStages.lifeSnapshotPreview.value) {
        return;
      }
      _historyPointerStartPage = page;
    }
  }

  void _trackHistoryForwardSwipe(PointerMoveEvent event) {
    if (_historyPointerStartPage == null) return;
    _historyForwardDistance = ZyraJourneyScroll.completionDistanceAfterInput(
      currentDistance: _historyForwardDistance,
      forwardDelta: -event.delta.dy,
      threshold: _historyForwardThreshold,
    );
  }

  void _finishHistoryForwardSwipe(PointerEvent event) {
    final startPage = _historyPointerStartPage;
    final forwardDistance = _historyForwardDistance;
    _historyPointerStartPage = null;
    _historyForwardDistance = 0;
    if (startPage == null || forwardDistance < _historyForwardThreshold) {
      return;
    }

    // Let PageView process the same pointer-up first. If it already settles
    // forward this becomes a no-op; otherwise finish the missed chapter move.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final target = ZyraJourneyScroll.missedHistoryForwardTarget(
        startPage: startPage,
        currentPage: _pageController.page ?? startPage.toDouble(),
        arrivalPage: ZyraJourneyScroll.arrivalPage(_history.length),
        forwardDistance: forwardDistance,
        activationDistance: _historyForwardThreshold,
      );
      if (target == null) return;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _pageController.jumpToPage(target);
      } else {
        _pageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _cancelHistoryForwardSwipe(PointerEvent event) {
    _historyPointerStartPage = null;
    _historyForwardDistance = 0;
  }

  /// A tall action (notably the revealed Compatibility result) owns a small
  /// inner scroll view. Once that content is already at its top, one further
  /// downward pull must return to the arrival above instead of being trapped
  /// by the inner scrollable.
  bool _handleInnerActionScroll(ScrollNotification notification) {
    final delta = _pullPastStart(notification);
    if (delta != null) {
      _accumulateInnerPull(
        targetPage: ZyraJourneyScroll.arrivalPage(_history.length),
        delta: delta,
      );
    } else if (notification is ScrollEndNotification && !_innerPullCommitted) {
      _innerPullDistance = 0;
      _innerPullTargetPage = null;
    }
    return false;
  }

  bool _handleInnerHistoryScroll(
    ScrollNotification notification,
    int historyPage,
  ) {
    final pastStart = _pullPastStart(notification);
    if (pastStart != null && historyPage > 0) {
      _accumulateInnerPull(targetPage: historyPage - 1, delta: pastStart);
      return false;
    }
    final pastEnd = _pullPastEnd(notification);
    if (pastEnd != null) {
      _accumulateInnerPull(targetPage: historyPage + 1, delta: pastEnd);
      return false;
    }
    if (notification is ScrollEndNotification && !_innerPullCommitted) {
      _innerPullDistance = 0;
      _innerPullTargetPage = null;
    }
    return false;
  }

  double? _pullPastStart(ScrollNotification notification) {
    if (notification is OverscrollNotification && notification.overscroll < 0) {
      return -notification.overscroll;
    }
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent &&
        (notification.scrollDelta ?? 0) < 0) {
      return -(notification.scrollDelta ?? 0);
    }
    return null;
  }

  double? _pullPastEnd(ScrollNotification notification) {
    if (notification is OverscrollNotification && notification.overscroll > 0) {
      return notification.overscroll;
    }
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >= notification.metrics.maxScrollExtent &&
        (notification.scrollDelta ?? 0) > 0) {
      return notification.scrollDelta;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    final secondary = stage.guidingQuestion ?? stage.supportingLine;
    final questionCount = JourneyQuestions.forStageValue(stage.value)?.length;
    final history = _history;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final arrivalPage = ZyraJourneyScroll.arrivalPage(history.length);
        final actionPage = ZyraJourneyScroll.actionPage(history.length);
        final decisionPage = ZyraJourneyScroll.decisionPage(history.length);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _startHistoryForwardSwipe,
          onPointerMove: _trackHistoryForwardSwipe,
          onPointerUp: _finishHistoryForwardSwipe,
          onPointerCancel: _cancelHistoryForwardSwipe,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            scrollDirection: Axis.vertical,
            pageSnapping: true,
            // Cache the action page one viewport below the arrival. With the
            // default zero cache, Flutter did not mount a stage's StatefulWidget
            // until the drag had already begun; its first network read and
            // loader therefore appeared during the movement and made each
            // section feel like a newly opened route. One viewport is enough to
            // start that read while the arrival is being read, without mounting
            // future stages or changing the page-by-page gesture.
            allowImplicitScrolling: true,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount:
                history.length + 2 + (widget.decisionChild == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (index < history.length) {
                final completedStage = history[index];
                final completedChild = switch (completedStage.value) {
                  'compatibility_reveal' => widget.compatibilityHistoryChild,
                  'salam_exchange' => widget.salamHistoryChild,
                  'life_snapshot_preview' => widget.lifeSnapshotHistoryChild,
                  'wali_gate' => widget.guardianHistoryChild,
                  _ => _JourneyCompletedStage(
                    stage: completedStage,
                    height: pageHeight,
                    onOpenTimeline: widget.onOpenTimeline,
                  ),
                };
                final nextOrder = index + 1 < history.length
                    ? history[index + 1].order
                    : stage.order;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) =>
                          _handleInnerHistoryScroll(notification, index),
                      child: completedChild,
                    ),
                    if (index > 0)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _JourneyUpCue(
                            label: 'Stage ${history[index - 1].order} above',
                            onTap: () => _showPage(index - 1),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _JourneyDownCue(
                          label: 'Stage $nextOrder below',
                          onTap: () => _showPage(index + 1),
                        ),
                      ),
                    ),
                  ],
                );
              }
              if (index == arrivalPage) {
                return SizedBox(
                  height: pageHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Stack(
                      children: [
                        if (history.isNotEmpty)
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _JourneyUpCue(
                                    label: 'Stage ${history.last.order} above',
                                    onTap: () => _showPage(arrivalPage - 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Align(
                          // The stage body starts below the app bar and ribbon.
                          // A small upward optical correction places the words
                          // at the centre of the physical display, consistently
                          // for all eight arrivals.
                          alignment: const Alignment(0, -0.12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'STAGE ${stage.order} OF ${widget.stages.length}',
                                style: ZyraText.chapterLabel(
                                  color: ZyraColors.ink(0.54),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                stage.arrivalTitle ?? stage.label,
                                style: ZyraText.heading(size: 25),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              Text(
                                stage.introduction,
                                style: ZyraText.body(
                                  size: 15,
                                  color: ZyraColors.foreground.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (secondary != null) ...[
                                SizedBox(height: 10),
                                Text(
                                  secondary,
                                  style: ZyraText.subtext(size: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (questionCount != null) ...[
                                SizedBox(height: 22),
                                _JourneyQuestionChapterBriefing(
                                  questionCount: questionCount,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: _JourneyDownCue(
                              label: questionCount == null
                                  ? history.isEmpty
                                        ? 'Scroll to begin'
                                        : 'Continue'
                                  : 'Begin Question 1 of $questionCount',
                              onTap: showActionPage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (index == actionPage) {
                return Column(
                  children: [
                    SizedBox(
                      height: 58,
                      child: Center(
                        child: _JourneyUpCue(
                          label: 'Stage ${stage.order} arrival above',
                          onTap: () => _showPage(arrivalPage),
                        ),
                      ),
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _handleInnerActionScroll,
                        child: SizedBox.expand(child: widget.child),
                      ),
                    ),
                  ],
                );
              }
              assert(index == decisionPage && widget.decisionChild != null);
              return NotificationListener<ScrollNotification>(
                onNotification: _handleInnerActionScroll,
                child: SizedBox.expand(child: widget.decisionChild),
              );
            },
          ),
        );
      },
    );
  }
}

/// The three sustained question chapters begin differently from action-only
/// stages: members need to understand the private envelope before Question 1
/// appears. Counts come from the real question bank, never presentation copy.
class _JourneyQuestionChapterBriefing extends StatelessWidget {
  final int questionCount;

  const _JourneyQuestionChapterBriefing({required this.questionCount});

  @override
  Widget build(BuildContext context) {
    const gold = ZyraColors.journeyGold;
    return Semantics(
      label:
          '$questionCount questions, one at a time. Answer privately, review and seal, then open together.',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: _JourneyQuestionBriefingStep(
                    number: 1,
                    label: 'Answer\nprivately',
                  ),
                ),
                _JourneyQuestionBriefingConnector(color: gold),
                const Expanded(
                  child: _JourneyQuestionBriefingStep(
                    number: 2,
                    label: 'Review\n& seal',
                  ),
                ),
                _JourneyQuestionBriefingConnector(color: gold),
                const Expanded(
                  child: _JourneyQuestionBriefingStep(
                    number: 3,
                    label: 'Open\ntogether',
                  ),
                ),
              ],
            ),
            SizedBox(height: 13),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 13, color: gold),
                SizedBox(width: 6),
                Text(
                  '$questionCount questions · one at a time',
                  style: ZyraText.subtext(
                    size: 10.5,
                    color: ZyraColors.foreground.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyQuestionBriefingStep extends StatelessWidget {
  final int number;
  final String label;

  const _JourneyQuestionBriefingStep({
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 27,
          height: 27,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ZyraColors.journeyGold.withValues(alpha: 0.76),
            ),
          ),
          child: Text(
            '$number',
            style: ZyraText.subtext(size: 9.5, color: ZyraColors.journeyGold),
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: ZyraText.subtext(
            size: 9.5,
            color: ZyraColors.foreground.withValues(alpha: 0.78),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _JourneyQuestionBriefingConnector extends StatelessWidget {
  final Color color;

  const _JourneyQuestionBriefingConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Padding(
        padding: const EdgeInsets.only(top: 13),
        child: Container(height: 1, color: color.withValues(alpha: 0.34)),
      ),
    );
  }
}

/// Every live or revisited Journey section exposes the same upward return.
/// The gesture remains available; the cue makes the route explicit and gives
/// nested scrollables such as Compatibility a reliable tap target as well.
class _JourneyUpCue extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _JourneyUpCue({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 24,
                  color: ZyraColors.foreground.withValues(alpha: 0.58),
                ),
                Text(
                  label,
                  style: ZyraText.subtext(
                    size: 10.5,
                    color: ZyraColors.foreground.withValues(alpha: 0.58),
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

/// The next chapter's invitation appears with the arrival instead of asking
/// the member to guess whether the successful Continue tap did anything.
class _JourneyDownCue extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _JourneyDownCue({required this.label, required this.onTap});

  @override
  State<_JourneyDownCue> createState() => _JourneyDownCueState();
}

class _JourneyDownCueState extends State<_JourneyDownCue> {
  bool _reducedMotionLatched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _reducedMotionLatched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final visibleValue = _reducedMotionLatched ? 1.0 : value;
        return Opacity(
          opacity: visibleValue,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - visibleValue)),
            child: child,
          ),
        );
      },
      child: Semantics(
        button: true,
        label: widget.label,
        onTap: widget.onTap,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 30,
                    color: ZyraColors.foreground.withValues(alpha: 0.58),
                  ),
                  Text(
                    widget.label,
                    style: ZyraText.subtext(
                      size: 12,
                      color: ZyraColors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ending of a completed stage, not a recreation of its live screen.
/// Threshold actions cannot be repeated here. Deeper chapters offer their
/// durable Timeline record instead of rebuilding old answer/reveal controls.
class _JourneyCompletedStage extends StatelessWidget {
  final ZyraJourneyStage stage;
  final double height;
  final VoidCallback onOpenTimeline;

  const _JourneyCompletedStage({
    required this.stage,
    required this.height,
    required this.onOpenTimeline,
  });

  bool get _hasTimelineRecord =>
      stage.value == 'compatibility_reveal' ||
      stage.kind == ZyraStageKind.sustained;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        child: Column(
          children: [
            const Spacer(),
            Icon(
              Icons.check_circle_outline_rounded,
              size: 25,
              color: ZyraColors.journeyGold.withValues(alpha: 0.72),
            ),
            SizedBox(height: 11),
            Text(
              'STAGE ${stage.order} · ${stage.label.toUpperCase()}',
              style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              stage.completionHeading,
              style: ZyraText.heading(size: 21),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 7),
            Text(
              stage.completionLine,
              style: ZyraText.subtext(size: 13.5),
              textAlign: TextAlign.center,
            ),
            if (stage.guidingQuestion != null) ...[
              SizedBox(height: 10),
              Text(
                stage.guidingQuestion!,
                style: ZyraText.body(
                  size: 12.5,
                  color: ZyraColors.foreground.withValues(alpha: 0.62),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_hasTimelineRecord) ...[
              SizedBox(height: 8),
              TextButton(
                onPressed: onOpenTimeline,
                child: Text(
                  'Read this stage in your Timeline',
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: ZyraColors.ink(0.70),
                  ),
                ),
              ),
            ],
            const Spacer(),
            Container(
              width: 54,
              height: 1,
              color: ZyraColors.foreground.withValues(alpha: 0.13),
            ),
          ],
        ),
      ),
    );
  }
}

/// DEV ONLY — a pull-out tab on the right edge, matching the app's own
/// developer panel rather than inventing a second convention.
///
/// Founder, 2026-08-10: "the toggle in Enter should be the same as it is as
/// the rest of the app, a little black button on right middle side."
///
/// The first version was an amber strip under the app bar. It was legible and
/// it was wrong: `dev_scenario_panel.dart` already established the pattern on
/// 2026-08-01 — a 22pt tab, dark-plum glass, chevron when open and a tune glyph
/// when closed, vertically centred. Two debug conventions in one app is one
/// too many, and the newer one is always the one that looks like a bug.
///
/// This remains the Journey's specialist stage-control tab. The global
/// developer rail stays available above pushed routes and owns the page-aware
/// Pause Decision State control; keeping pause state out of this tab avoids
/// two controls for the same scenario.
///
/// ⚠️ IT SKIPS THE THREE THINGS THAT MAKE ZYRA WHAT IT IS: the Pre-Journey
/// Ritual, the Guardian Gate, and the 48-hour Family Review Period.
///
/// RELEASE SAFETY — double-guarded, copying dev_scenario_panel exactly, after
/// the 2026-07-26 audit found Developer Access shipping in a release build:
///   1. the caller only builds it for an @zyra.test account
///   2. build() returns SizedBox.shrink() in a release build regardless
///
/// LABELS COME FROM THE CANONICAL MAP (DR-ZYRA-129). No stage name is written
/// here. Three screens once each kept their own switch over the same eight
/// strings and all three drifted; a debug tool showing different names from
/// the product would be a debug tool that lies about what it is debugging.
class _DevStageJumper extends StatefulWidget {
  final String? current;
  final bool busy;
  final ValueChanged<String> onJump;
  final bool lifeSnapshotHasBio;
  final Set<String> lifeSnapshotFieldIds;
  final ValueChanged<bool> onLifeSnapshotBioChanged;
  final ValueChanged<String> onLifeSnapshotFieldToggle;
  final ValueChanged<bool> onLifeSnapshotShowAll;
  final Set<int> selectedGuardians;
  final ValueChanged<int> onGuardianToggle;
  final bool hasPlus;
  final ValueChanged<bool> onHasPlusChanged;
  final VoidCallback onRewind;
  final bool livePaused;

  const _DevStageJumper({
    required this.current,
    required this.busy,
    required this.onJump,
    required this.lifeSnapshotHasBio,
    required this.lifeSnapshotFieldIds,
    required this.onLifeSnapshotBioChanged,
    required this.onLifeSnapshotFieldToggle,
    required this.onLifeSnapshotShowAll,
    required this.selectedGuardians,
    required this.onGuardianToggle,
    required this.hasPlus,
    required this.onHasPlusChanged,
    required this.onRewind,
    required this.livePaused,
  });

  @override
  State<_DevStageJumper> createState() => _DevStageJumperState();
}

class _DevStageJumperState extends State<_DevStageJumper> {
  bool _open = false;

  static const double _tabWidth = 22;
  static const double _panelWidth = 232;

  // The display order includes the Journey-only Bio mock inserted between
  // Compatibility Reveal and Guardian Gate. Stored values still come from
  // the canonical model; the preview never reaches the stage RPC.
  static final _stages = ZyraJourneyStages.previewAll
      .map((stage) => stage.value)
      .toList(growable: false);

  Widget _guardianChip(int index) {
    final guardian = ZyraDevScenario.fakeGuardians[index];
    final selected = widget.selectedGuardians.contains(index);
    final role = index == ZyraJourneyGuardianSelection.mainIndex
        ? 'Main'
        : 'Additional';
    return GestureDetector(
      onTap: widget.busy || widget.livePaused
          ? null
          : () => widget.onGuardianToggle(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? ZyraColors.journeyGold.withValues(alpha: 0.2)
              : ZyraColors.foreground.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? ZyraColors.journeyGold.withValues(alpha: 0.72)
                : ZyraColors.foreground.withValues(alpha: 0.12),
            width: 0.7,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 13,
              color: selected ? ZyraColors.journeyGold : ZyraColors.ink(0.54),
            ),
            SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guardian.name,
                  style: ZyraText.subtext(size: 10.5, color: Colors.white),
                ),
                Text(
                  role,
                  style: ZyraText.subtext(
                    size: 8.5,
                    color: ZyraColors.foreground.withValues(alpha: 0.52),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lifeSnapshotFieldChip(ZyraJourneyLifeSnapshotField field) {
    final selected = widget.lifeSnapshotFieldIds.contains(field.id);
    return GestureDetector(
      onTap: widget.busy || widget.livePaused
          ? null
          : () => widget.onLifeSnapshotFieldToggle(field.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? ZyraColors.journeyGold.withValues(alpha: 0.2)
              : ZyraColors.foreground.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? ZyraColors.journeyGold.withValues(alpha: 0.72)
                : ZyraColors.foreground.withValues(alpha: 0.12),
            width: 0.7,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : Icons.add_rounded,
              size: 12,
              color: selected ? ZyraColors.journeyGold : ZyraColors.ink(0.54),
            ),
            SizedBox(width: 4),
            Text(
              field.label,
              style: ZyraText.subtext(
                size: 10,
                color: selected ? Colors.white : ZyraColors.ink(0.70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) {
      return SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      bottom: 0,
      right: _open ? 0 : -_panelWidth,
      width: _panelWidth + _tabWidth,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Center(
              child: Container(
                width: _tabWidth,
                height: 92,
                decoration: BoxDecoration(
                  color: ZyraColors.modalSheetSurface.withValues(
                    alpha: 242 / 255,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  border: Border.all(
                    color: ZyraColors.foreground.withValues(alpha: 0.16),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _open ? Icons.chevron_right : Icons.tune,
                    size: 15,
                    color: ZyraColors.foreground.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: ZyraColors.modalSheetSurface.withValues(alpha: 242 / 255),
              child: SafeArea(
                left: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    // START OVER — TOP, at the Founder's word (DR-ZYRA-176:
                    // "PUT START OVER AT THE TOP"): every full walk of the
                    // six experiences begins here, so the reset earns the
                    // first reach, not a scroll. Still the only destructive
                    // thing in the panel, still tinted like the account
                    // reset in dev_scenario_panel, still asks first.
                    ZyraDevToolSection(
                      key: const ValueKey('dev_journey_section_start'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'START OVER',
                            style: ZyraText.chapterLabel(
                              color: ZyraColors.ink(0.70),
                            ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: widget.busy || widget.livePaused
                                  ? null
                                  : widget.onRewind,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: ZyraColors.destructiveBorder,
                                  width: 0.7,
                                ),
                              ),
                              child: Text(
                                'Start this Journey again',
                                style: ZyraText.subtext(
                                  size: 12,
                                  color: ZyraColors.destructive,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Back to Compatibility Reveal, with everything you both '
                            'did inside it cleared. The match and your Guardian link '
                            'stay. Asks first.',
                            style: ZyraText.subtext(size: 10.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ZyraDevToolSection(
                      key: const ValueKey('dev_journey_section_stages'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'SKIP TO STAGE',
                                style: ZyraText.chapterLabel(
                                  color: ZyraColors.ink(0.70),
                                ),
                              ),
                              const Spacer(),
                              if (widget.busy)
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.6,
                                    color: ZyraColors.ink(0.70),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // CHIPS, not a tower — 2026-08-12 (premium-tool pass).
                          // Full-width rows pushed the panel past one screen;
                          // wrapped chips keep the whole sequence visible.
                          // Labels still come from the canonical map, never a
                          // literal here.
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final s in _stages)
                                Builder(
                                  builder: (_) {
                                    final isCurrent = s == widget.current;
                                    return GestureDetector(
                                      onTap:
                                          widget.busy ||
                                              widget.livePaused ||
                                              isCurrent
                                          ? null
                                          : () => widget.onJump(s),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? ZyraColors.foreground
                                                    .withValues(alpha: 0.22)
                                              : ZyraColors.foreground
                                                    .withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: ZyraColors.foreground
                                                .withValues(
                                                  alpha: isCurrent
                                                      ? 0.35
                                                      : 0.12,
                                                ),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          ZyraJourneyStages.previewLabelFor(s),
                                          style: ZyraText.subtext(
                                            size: 11,
                                            color: isCurrent
                                                ? Colors.white
                                                : ZyraColors.ink(0.70),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (widget.current ==
                        ZyraJourneyStages.lifeSnapshotPreview.value) ...[
                      const SizedBox(height: 16),
                      ZyraDevToolSection(
                        key: const ValueKey('dev_journey_section_bio'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'STAGE 3 BIO',
                              style: ZyraText.chapterLabel(
                                color: ZyraColors.ink(0.70),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Preview only what the other person chose to share '
                              'for this Journey.',
                              style: ZyraText.subtext(size: 10.5),
                            ),
                            SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                'Journey bio added',
                                style: ZyraText.subtext(
                                  size: 11.5,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                widget.lifeSnapshotHasBio
                                    ? '${ZyraJourneyLifeSnapshotMock.bio.length} / '
                                          '${ZyraJourneyLifeSnapshotMock.bioCharacterLimit} characters'
                                    : 'No biography will appear',
                                style: ZyraText.subtext(size: 9.5),
                              ),
                              value: widget.lifeSnapshotHasBio,
                              onChanged: widget.busy || widget.livePaused
                                  ? null
                                  : widget.onLifeSnapshotBioChanged,
                              activeTrackColor: const Color(
                                0xFFE8C98A,
                              ).withValues(alpha: 0.65),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: widget.busy || widget.livePaused
                                      ? null
                                      : () =>
                                            widget.onLifeSnapshotShowAll(true),
                                  child: const Text('Show all'),
                                ),
                                TextButton(
                                  onPressed: widget.busy || widget.livePaused
                                      ? null
                                      : () =>
                                            widget.onLifeSnapshotShowAll(false),
                                  child: const Text('Show none'),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final field
                                    in ZyraJourneyLifeSnapshotMock.fields)
                                  _lifeSnapshotFieldChip(field),
                              ],
                            ),
                            SizedBox(height: 7),
                            Text(
                              '${widget.lifeSnapshotFieldIds.length} of '
                              '${ZyraJourneyLifeSnapshotMock.fields.length} details shared',
                              style: ZyraText.subtext(
                                size: 10,
                                color: ZyraColors.journeyGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (widget.current == 'wali_gate') ...[
                      const SizedBox(height: 16),
                      ZyraDevToolSection(
                        key: const ValueKey('dev_journey_section_guardians'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'STAGE 4 GUARDIANS',
                              style: ZyraText.chapterLabel(
                                color: ZyraColors.ink(0.70),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Choose the one Main and any of the five Additional '
                              'mock Guardians, then send Salam on the stage.',
                              style: ZyraText.subtext(size: 10.5),
                            ),
                            SizedBox(height: 9),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (
                                  var index = 0;
                                  index < ZyraDevScenario.fakeGuardians.length;
                                  index++
                                )
                                  _guardianChip(index),
                              ],
                            ),
                            SizedBox(height: 7),
                            Text(
                              widget.selectedGuardians.isEmpty
                                  ? 'None selected'
                                  : '${widget.selectedGuardians.length} selected',
                              style: ZyraText.subtext(
                                size: 10,
                                color: ZyraColors.journeyGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    ZyraDevToolSection(
                      key: const ValueKey('dev_journey_section_account'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // DR-ZYRA-135 / OA-ZYRA-152. Simulates having bought
                          // Compatibility Unlock+, which lets you see the score
                          // before the other Seeker reveals.
                          //
                          // With THE OTHER PERSON's auto half left OFF, this
                          // reaches the state that could not exist before today:
                          // you see the number, she has not revealed, and she has
                          // not been told.
                          Text(
                            'THIS ACCOUNT',
                            style: ZyraText.chapterLabel(
                              color: ZyraColors.ink(0.70),
                            ),
                          ),
                          SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: widget.hasPlus,
                            onChanged: widget.busy || widget.livePaused
                                ? null
                                : widget.onHasPlusChanged,
                            title: Text(
                              'Has paid for Compatibility Unlock',
                              style: ZyraText.subtext(
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              widget.hasPlus
                                  ? 'You see the score early. They are told nothing.'
                                  : 'Mutual reveal applies — neither sees it first.',
                              style: ZyraText.subtext(size: 10.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// BACK AND A NAME — that is the whole header now.
//
// THE ⋮ WENT FIRST (2026-08-13, morning — Founder: "those 3 dots of top
// right for active journey. remove it.. put it in main page section"):
// its Pause / End / Report moved to the Active Journey card on
// Connections. THE PILL ROW WENT THE SAME DAY (Founder: "Map Timeline
// Profile at the top… I don't think they're needed anymore"): Timeline
// and Profile live on that same card, and Map — the one action the card
// doesn't carry — DISSOLVED INTO the Timeline ("map is not needed cos
// it should live in timeline"): the rail now runs past a YOU ARE HERE
// into the road ahead, and JourneyMapScreen is retired outright. The
// Journey screen holds only the Journey.
//
// Stateless: the GlobalKey existed only so the menu overlay could find
// its anchor, and went with the menu. `stage` stayed a parameter for one
// build after the Map pill left and was removed with the pill row —
// nothing here reads it now.
class _JourneyAppBar extends StatelessWidget {
  final SeekerProfile profile;
  const _JourneyAppBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: ZyraColors.ink(0.70),
              size: 18,
            ),
          ),
          Expanded(
            child: Text(
              'Journey with ${profile.firstName}',
              style: ZyraText.heading(size: 16),
              textAlign: TextAlign.center,
            ),
          ),
          // The old trailing controls' footprint, kept as space so the
          // title stays centred — an IconButton is 48pt wide.
          SizedBox(width: 48),
        ],
      ),
    );
  }
}

// The Ended Journey view.
//
// REWRITTEN 2026-08-06 — OA-ZYRA-154, DR-ZYRA-121.
//
// Was stateful purely to drive a one-second countdown to a "Restart
// Journey" button. Both are gone: restart_journey() reopened an ended
// Journey on one person's tap, deleting six tables of history and clearing
// `ended_at` first, and the server now refuses it.
//
// The 24-hour cooling period it counted down to came from APP/Journey/
// JOURNEY AVAILABILITY/Summary.md "ENDED JOURNEY — RULES". That rule is
// superseded: under V3 §9 an ended Journey is permanent, and starting again
// is a new attempt requiring the other person's consent — not a timer
// expiring. Counting down to a button that no longer exists would be worse
// than saying nothing.
//
// Stateless again, and one Timer.periodic fewer running per ended Journey.
class _EndedView extends StatelessWidget {
  final SeekerProfile profile;
  const _EndedView({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDF7D82),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'JOURNEY ENDED',
                style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'This chapter has closed.',
                style: ZyraText.heading(size: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 11),
              Text(
                'Your Journey with ${profile.firstName} is no longer active. '
                'Your Timeline and everything you shared are kept.',
                style: ZyraText.body(size: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 54,
                child: Divider(height: 1, color: Color(0xFFDF7D82)),
              ),
              SizedBox(height: 20),
              Text(
                ZyraReleaseGates.requestNewJourneyEnabled
                    ? 'Beginning together again means starting a new Journey. One '
                          'person requests it and the other decides. That direct option '
                          'lasts 60 days; after it closes, you would need to meet again '
                          'through Profiles.'
                    : ZyraReleaseGates.requestNewJourneyUnavailable,
                style: ZyraText.subtext(size: 13),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              _JourneySolidAction(
                label: 'Return to Connections',
                accent: const Color(0xFFDF7D82),
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
Widget buildZyraPauseDecisionTestSurface({
  required ZyraJourneyPauseState state,
  required String viewerId,
  bool capacityAvailable = true,
  String profileName = 'Adam',
  String profileGender = 'male',
  ValueChanged<ZyraPauseAction>? onAction,
}) => MaterialApp(
  home: Scaffold(
    body: _PauseDecisionView(
      profile: SeekerProfile(
        id: 'pause-test-other',
        firstName: profileName,
        age: 30,
        city: 'London',
        photos: const <String>[],
        gender: profileGender,
      ),
      state: state,
      busy: false,
      preview: false,
      capacityAvailable: capacityAvailable,
      viewerId: viewerId,
      onAction: onAction ?? (_) {},
      onEnd: () {},
      onReturn: () {},
    ),
  ),
);

class _PauseDecisionView extends StatelessWidget {
  final SeekerProfile profile;
  final ZyraJourneyPauseState state;
  final bool busy;
  final bool preview;
  final bool? capacityAvailable;
  final ValueChanged<ZyraPauseAction> onAction;
  final VoidCallback onEnd;
  final VoidCallback onReturn;
  final String? viewerId;

  const _PauseDecisionView({
    required this.profile,
    required this.state,
    required this.busy,
    required this.preview,
    required this.capacityAvailable,
    required this.onAction,
    required this.onEnd,
    required this.onReturn,
    this.viewerId,
  });

  String? _deadlineLine() {
    final deadline = state.deadlineAt;
    if (deadline == null) return null;
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return 'The response window has ended. No automatic outcome is '
          'configured, so this Journey remains safely locked.';
    }
    if (remaining.inHours >= 24) {
      final days = (remaining.inHours / 24).ceil();
      return 'Response due in $days day${days == 1 ? '' : 's'}.';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return 'Response due in ${hours}h ${minutes}m.';
  }

  @override
  Widget build(BuildContext context) {
    final perspective = state.perspectiveFor(
      viewerId ?? ZyraAuth.currentUser?.id,
    );
    final title = switch (perspective) {
      ZyraPausePerspective.pauseRequesterWaiting => 'Pause requested',
      ZyraPausePerspective.pauseResponderDecision =>
        '${profile.firstName} has asked to pause this Journey',
      ZyraPausePerspective.continuationRequesterWaiting =>
        'Continuation requested',
      ZyraPausePerspective.continuationResponderDecision =>
        '${profile.firstName} would like to continue',
      ZyraPausePerspective.mutuallyPaused => 'Journey paused',
      ZyraPausePerspective.resumeRequesterWaiting => 'Resume requested',
      ZyraPausePerspective.resumeResponderDecision =>
        '${profile.firstName} would like to resume',
      ZyraPausePerspective.active => 'Journey active',
    };
    final body = switch (perspective) {
      ZyraPausePerspective.pauseRequesterWaiting =>
        'You asked to pause this Journey. Waiting for '
            '${profile.firstName} to decide.',
      ZyraPausePerspective.pauseResponderDecision =>
        'Choose what feels right. The Journey stays active but locked until '
            'this decision is settled.',
      ZyraPausePerspective.continuationRequesterWaiting =>
        'You asked to continue this Journey. Waiting for '
            '${profile.firstName} to decide.',
      ZyraPausePerspective.continuationResponderDecision =>
        'You can continue from the exact place you both reached, confirm the '
            'pause, or end the Journey.',
      ZyraPausePerspective.mutuallyPaused =>
        'You both agreed to take some space. Nothing has been lost. Either '
            'person can ask to resume when ready.',
      ZyraPausePerspective.resumeRequesterWaiting =>
        'You asked to resume. This Journey remains paused while '
            '${profile.firstName} decides.',
      ZyraPausePerspective.resumeResponderDecision =>
        'Choose whether this Journey resumes, remains paused, or ends.',
      ZyraPausePerspective.active => 'Your Journey is ready to continue.',
    };
    final deadline = _deadlineLine();
    final capacityBlocked = capacityAvailable == false;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preview) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34283F),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF5B4867),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'DEVELOPMENT PREVIEW',
                    style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
                  ),
                ),
                SizedBox(height: 16),
              ],
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ZyraColors.journeyGold.withValues(alpha: 0.14),
                  border: Border.all(
                    color: ZyraColors.journeyGold.withValues(alpha: 0.72),
                  ),
                ),
                child: Icon(
                  state.isPaused
                      ? Icons.pause_rounded
                      : Icons.hourglass_top_rounded,
                  color: ZyraColors.journeyGold,
                  size: 18,
                ),
              ),
              SizedBox(height: 20),
              Text(
                state.isPaused ? 'SHARED PAUSE' : 'DECISION PENDING',
                style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: ZyraText.heading(size: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 11),
              Text(
                body,
                style: ZyraText.body(size: 14),
                textAlign: TextAlign.center,
              ),
              if (deadline != null) ...[
                SizedBox(height: 12),
                Text(
                  deadline,
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: state.deadlineExpired
                        ? const Color(0xFFDFBD62)
                        : ZyraColors.ink(0.58),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (capacityBlocked &&
                  (perspective == ZyraPausePerspective.pauseResponderDecision ||
                      perspective ==
                          ZyraPausePerspective
                              .continuationResponderDecision)) ...[
                SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ZyraColors.journeyGold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ZyraColors.journeyGold.withValues(alpha: 0.35),
                      width: 0.7,
                    ),
                  ),
                  child: Text(
                    'Paused Journey capacity is full for one account. '
                    'Manage a Paused Journey, continue this one, or end it.',
                    style: ZyraText.subtext(size: 12.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              SizedBox(height: 26),
              if (perspective ==
                  ZyraPausePerspective.pauseResponderDecision) ...[
                Divider(
                  height: 1,
                  color: ZyraColors.foreground.withValues(alpha: 0.24),
                ),
                _JourneyOpenDecisionAction(
                  label: 'Agree to Pause',
                  dotColor: const Color(0xFFDFBD62),
                  onTap: busy || capacityBlocked
                      ? null
                      : () => onAction(ZyraPauseAction.agreePause),
                ),
                _JourneyOpenDecisionAction(
                  label: 'Request to Continue',
                  dotColor: ZyraColors.journeyDotGreen,
                  onTap: busy
                      ? null
                      : () => onAction(ZyraPauseAction.requestContinue),
                ),
                _JourneyOpenDecisionAction(
                  label: 'End Journey',
                  dotColor: const Color(0xFFDF7D82),
                  destructive: true,
                  onTap: busy ? null : onEnd,
                ),
              ] else if (perspective ==
                  ZyraPausePerspective.continuationResponderDecision) ...[
                Divider(
                  height: 1,
                  color: ZyraColors.foreground.withValues(alpha: 0.24),
                ),
                _JourneyOpenDecisionAction(
                  label: 'Continue Journey',
                  dotColor: ZyraColors.journeyDotGreen,
                  onTap: busy
                      ? null
                      : () => onAction(ZyraPauseAction.continueJourney),
                ),
                _JourneyOpenDecisionAction(
                  label: 'Confirm Pause',
                  dotColor: const Color(0xFFDFBD62),
                  onTap: busy || capacityBlocked
                      ? null
                      : () => onAction(ZyraPauseAction.confirmPause),
                ),
                _JourneyOpenDecisionAction(
                  label: 'End Journey',
                  dotColor: const Color(0xFFDF7D82),
                  destructive: true,
                  onTap: busy ? null : onEnd,
                ),
              ] else if (perspective ==
                  ZyraPausePerspective.mutuallyPaused) ...[
                Divider(
                  height: 1,
                  color: ZyraColors.foreground.withValues(alpha: 0.24),
                ),
                _JourneyOpenDecisionAction(
                  label: 'Request Resume',
                  dotColor: ZyraColors.journeyDotGreen,
                  onTap: busy
                      ? null
                      : () => onAction(ZyraPauseAction.requestResume),
                ),
                _JourneyOpenDecisionAction(
                  label: 'End Journey',
                  dotColor: const Color(0xFFDF7D82),
                  destructive: true,
                  onTap: busy ? null : onEnd,
                ),
              ] else if (perspective ==
                  ZyraPausePerspective.resumeResponderDecision) ...[
                Divider(
                  height: 1,
                  color: ZyraColors.foreground.withValues(alpha: 0.24),
                ),
                _JourneyOpenDecisionAction(
                  label: 'Agree to Resume',
                  dotColor: ZyraColors.journeyDotGreen,
                  onTap: busy
                      ? null
                      : () => onAction(ZyraPauseAction.agreeResume),
                ),
                _JourneyOpenDecisionAction(
                  label: 'Keep Paused',
                  dotColor: const Color(0xFFDFBD62),
                  onTap: busy
                      ? null
                      : () => onAction(ZyraPauseAction.keepPaused),
                ),
                _JourneyOpenDecisionAction(
                  label: 'End Journey',
                  dotColor: const Color(0xFFDF7D82),
                  destructive: true,
                  onTap: busy ? null : onEnd,
                ),
              ] else ...[
                Divider(
                  height: 1,
                  color: ZyraColors.foreground.withValues(alpha: 0.24),
                ),
                _JourneyOpenDecisionAction(
                  label: 'End Journey',
                  dotColor: const Color(0xFFDF7D82),
                  destructive: true,
                  onTap: busy ? null : onEnd,
                ),
              ],
              if (busy) ...[
                SizedBox(height: 12),
                const ZyraLoading(label: 'Updating your Journey'),
              ],
              SizedBox(height: 24),
              _JourneySolidAction(
                label: 'Return to Connections',
                accent: const Color(0xFFDFBD62),
                onTap: busy ? null : onReturn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Family Review Period (#31) ---------------------------------------
//
// Seeker-facing view only — per WALI_ARCHITECTURE_CURRENT_VERSION_V6.md,
// Continue/Pause is a Wali capability, not a Seeker one ("Each WALI
// may Continue or Pause"). This view is deliberately read-only for the
// Seeker: no button re-approves their own stage, matching the spec's
// framing that this gives "Guardians meaningful involvement... not a
// permission gate" the Seekers themselves operate.
class _FamilyReviewView extends StatefulWidget {
  final ({String id, String status, String toStage, DateTime deadlineAt})
  review;
  final SeekerProfile profile;
  const _FamilyReviewView({required this.review, required this.profile});

  @override
  State<_FamilyReviewView> createState() => _FamilyReviewViewState();
}

class _FamilyReviewViewState extends State<_FamilyReviewView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Redraws the countdown every minute — cheap, no network, purely
    // cosmetic (the real resolution is server-side via the poll in
    // _refresh()'s resolveFamilyReviewIfDue call).
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static String _formatRemaining(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'less than a minute';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final paused = widget.review.status == 'paused';
    final remaining = widget.review.deadlineAt.difference(DateTime.now());

    // THE SEAL — 2026-08-12 (experience redesign). A review only ever opens
    // because the couple just closed a chapter together, so this screen is
    // two beats in one: what was sealed, then whose time this is. The
    // sealed chapter is the stage BEFORE the review's destination.
    final toIdx = ZyraJourneyStages.all.indexWhere(
      (s) => s.value == widget.review.toStage,
    );
    final sealedStage = toIdx > 0 ? ZyraJourneyStages.all[toIdx - 1] : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              paused ? Icons.pause_circle_outline : Icons.hourglass_top,
              color: ZyraColors.ink(0.54),
              size: 32,
            ),
            SizedBox(height: 14),
            if (!paused && sealedStage != null) ...[
              Text(
                sealedStage.completionHeading,
                style: ZyraText.heading(size: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                sealedStage.completionLine,
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
            ] else
              Text(
                paused ? 'Paused for family review' : 'Family Review Period',
                style: ZyraText.heading(size: 18),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 8),
            Text(
              paused
                  ? "A Guardian has asked for more time before this Journey continues. This isn't a rejection — it means the family needs a little longer. ZYRA support is available to help if needed."
                  : 'This pause is deliberate — it is your families\' time. '
                        'Both families have this stage to review, and unless a '
                        'Guardian raises a concern you continue together in '
                        '${_formatRemaining(remaining)}.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      JourneyTimelineScreen(withProfile: widget.profile),
                ),
              ),
              child: Text(
                'Read your story so far',
                style: ZyraText.subtext(
                  size: 12.5,
                  color: ZyraColors.ink(0.70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Compatibility Reveal ---------------------------------------------

class _CompatibilityRevealView extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  final bool isActionVisible;
  final Future<void> Function() onContinue;
  final bool readOnly;

  /// Parent-owned admission/lifetime, not a transport or developer bypass.
  final bool Function() isCurrentSurface;

  /// Server's reason the pair has not moved on yet. 'waiting_for_continue'
  /// means this user has pressed Continue and the other has not — the
  /// checkpoint is recorded, so it is safe to show a wait rather than the
  /// button. See PRE-JOURNEY RITUAL: "Every checkpoint is a shared decision."
  final String? waitingReason;

  const _CompatibilityRevealView({
    required this.matchId,
    required this.profile,
    required this.isActionVisible,
    required this.onContinue,
    required this.waitingReason,
    required this.isCurrentSurface,
    this.readOnly = false,
  });

  @override
  State<_CompatibilityRevealView> createState() =>
      _CompatibilityRevealViewState();
}

class _CompatibilityRevealViewState extends State<_CompatibilityRevealView> {
  bool _mine = false;
  bool _theirs = false;
  double? _score;
  bool _loading = true;
  bool _animateReveal = false;
  bool _hasConfirmedSnapshot = false;
  bool _accountRetryRequired = false;
  ZyraCompatibilityReadStatus _readStatus =
      ZyraCompatibilityReadStatus.unavailable;
  ZyraCompatibilityReadFailure? _readFailure;
  late ZyraCompatibilityReadScope _scope;
  int _readGeneration = 0;
  Timer? _poll;
  StreamSubscription<dynamic>? _authSubscription;
  bool _pollLoadBusy = false;
  Future<void>? _loadFlight;

  static final Map<
    ZyraCompatibilityReadScope,
    ({bool mine, bool theirs, double? score, double? plusScore})
  >
  _settledSnapshots = {};

  /// DR-ZYRA-135: the server alone decides whether an early Plus read exists.
  double? _plusScore;

  /// A reveal celebration belongs to this member lifetime, not just a match.
  static final Set<ZyraCompatibilityReadScope> _celebratedMatches = {};

  static void invalidateParentContext(ZyraCompatibilityReadScope scope) {
    _settledSnapshots.remove(scope);
    _celebratedMatches.remove(scope);
  }

  ZyraCompatibilityReadScope _currentScope() => ZyraCompatibilityReadScope(
    actorId: ZyraAuth.currentUser?.id,
    accountGeneration: ZyraAccountState.generation,
    matchId: widget.matchId,
  );

  bool _scopeIsCurrent(ZyraCompatibilityReadScope scope) {
    final actor = scope.actorId;
    return actor != null &&
        scope == _currentScope() &&
        ZyraAccountState.isCurrent(actor, scope.accountGeneration);
  }

  bool _canPublish(
    ZyraCompatibilityReadScope scope,
    int generation, {
    bool Function()? surfaceOwner,
  }) =>
      mounted &&
      generation == _readGeneration &&
      scope == _scope &&
      widget.isCurrentSurface() &&
      (surfaceOwner?.call() ?? true) &&
      _scopeIsCurrent(scope);

  void _clearConfirmed() {
    _mine = false;
    _theirs = false;
    _score = null;
    _plusScore = null;
    _hasConfirmedSnapshot = false;
    _animateReveal = false;
  }

  void _resetReadScope({bool restoreCache = false}) {
    _readGeneration++;
    _loadFlight = null;
    _pollLoadBusy = false;
    _scope = _currentScope();
    // Eagerly discard another member's or a previous session's protected data.
    _settledSnapshots.removeWhere(
      (scope, _) =>
          scope.actorId != _scope.actorId ||
          scope.accountGeneration != _scope.accountGeneration,
    );
    _celebratedMatches.removeWhere(
      (scope) =>
          scope.actorId != _scope.actorId ||
          scope.accountGeneration != _scope.accountGeneration,
    );
    _clearConfirmed();
    _readStatus = ZyraCompatibilityReadStatus.unavailable;
    _readFailure = _scope.actorId == null
        ? ZyraCompatibilityReadFailure.signedOut
        : ZyraCompatibilityReadFailure.staleOwner;
    _loading = restoreCache && _scopeIsCurrent(_scope);
    final cached = restoreCache && _scopeIsCurrent(_scope)
        ? _settledSnapshots[_scope]
        : null;
    if (cached != null) {
      _mine = cached.mine;
      _theirs = cached.theirs;
      _score = cached.score;
      _plusScore = cached.plusScore;
      _hasConfirmedSnapshot = true;
      _readFailure = ZyraCompatibilityReadFailure.transient;
      // Cache is not a failed refresh or renewed authority. Keep the loader
      // until this visit's read confirms it or actually returns transient.
      _loading = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _resetReadScope(restoreCache: true);
    AppState.instance.addListener(_onAccountChanged);
    _authSubscription = ZyraAuth.authStateChanges.listen(
      (_) => _onAccountChanged(),
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        if (_scope != _currentScope() || !_scopeIsCurrent(_scope)) {
          _onAccountChanged();
          return;
        }
        // Retire the pending read and its captured actions without inventing
        // a logout. Keep same-owner confirmed data display-only after the error.
        _readGeneration++;
        _loadFlight = null;
        _pollLoadBusy = false;
        _publishReadFailure(
          ZyraCompatibilityReadResult.unavailable(
            scope: _scope,
            failure: ZyraCompatibilityReadFailure.transient,
          ),
        );
      },
    );
    _load();
    _configurePolling();
  }

  void _onAccountChanged() {
    if (!mounted || (_scope == _currentScope() && _scopeIsCurrent(_scope))) {
      return;
    }
    // AccountState changes its owner/generation before AppState's reset signal.
    // Do not wait for a timer or an outstanding HTTP response to hide old data.
    setState(() {
      _resetReadScope();
      _accountRetryRequired = true;
    });
  }

  void _configurePolling() {
    _poll?.cancel();
    _poll = widget.readOnly
        ? null
        : Timer.periodic(const Duration(seconds: 5), (_) => _pollLoad());
  }

  @override
  void didUpdateWidget(covariant _CompatibilityRevealView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId ||
        oldWidget.profile.id != widget.profile.id ||
        !oldWidget.isCurrentSurface() ||
        _scope != _currentScope()) {
      final requestedDifferentJourney =
          oldWidget.matchId != widget.matchId ||
          oldWidget.profile.id != widget.profile.id;
      if (requestedDifferentJourney) _accountRetryRequired = false;
      if (oldWidget.profile.id != widget.profile.id) {
        _settledSnapshots.remove(_scope);
        _celebratedMatches.remove(_scope);
      }
      _resetReadScope();
      _loading = !_accountRetryRequired && _scopeIsCurrent(_scope);
      if (!_accountRetryRequired) _load();
    }
    if (oldWidget.readOnly != widget.readOnly) _configurePolling();
    if (!oldWidget.isActionVisible && widget.isActionVisible) {
      _armRevealIfReady();
    }
  }

  bool get _readIsAvailable =>
      _readStatus == ZyraCompatibilityReadStatus.available &&
      _hasConfirmedSnapshot &&
      widget.isCurrentSurface() &&
      _scopeIsCurrent(_scope);

  bool get _revealIsReady =>
      _readIsAvailable && _mine && _theirs && _score != null;

  void _armRevealIfReady() {
    if (!_readIsAvailable) return;
    final shouldAnimate = ZyraCompatibilityRevealPolicy.shouldAnimate(
      isActionVisible: widget.isActionVisible,
      mineRevealed: _mine,
      theirsRevealed: _theirs,
      hasScore: _score != null,
      alreadyCelebrated: _animateReveal || _celebratedMatches.contains(_scope),
    );
    if (!shouldAnimate) return;
    _celebratedMatches.add(_scope);
    _animateReveal = true;
  }

  Future<void> _pollLoad() async {
    if (_pollLoadBusy ||
        !widget.isCurrentSurface() ||
        !_scopeIsCurrent(_scope) ||
        !_journeyViewCanPoll(context) ||
        !widget.isActionVisible) {
      return;
    }
    _pollLoadBusy = true;
    try {
      await _load();
    } finally {
      _pollLoadBusy = false;
    }
  }

  @override
  void dispose() {
    _readGeneration++;
    _poll?.cancel();
    _authSubscription?.cancel();
    AppState.instance.removeListener(_onAccountChanged);
    super.dispose();
  }

  Future<void> _load({bool allowScoreRecovery = true}) async {
    final active = _loadFlight;
    if (active != null) return active;
    final next = _loadOnce(allowScoreRecovery: allowScoreRecovery);
    _loadFlight = next;
    try {
      await next;
    } finally {
      if (identical(_loadFlight, next)) _loadFlight = null;
    }
  }

  void _publishReadFailure(ZyraCompatibilityReadResult result) {
    final keepConfirmed =
        result.status == ZyraCompatibilityReadStatus.unavailable &&
        result.failure == ZyraCompatibilityReadFailure.transient &&
        _hasConfirmedSnapshot;
    setState(() {
      if (!keepConfirmed) {
        _settledSnapshots.remove(_scope);
        _celebratedMatches.remove(_scope);
        _clearConfirmed();
      }
      _readStatus = result.status;
      _readFailure = result.failure;
      _loading = false;
    });
  }

  Future<void> _loadOnce({required bool allowScoreRecovery}) async {
    final scope = _scope;
    final generation = _readGeneration;
    final otherId = widget.profile.id;
    final surfaceOwner = widget.isCurrentSurface;
    if (!surfaceOwner()) return;
    if (!_scopeIsCurrent(scope)) {
      if (mounted && generation == _readGeneration) {
        _publishReadFailure(
          ZyraCompatibilityReadResult.unavailable(
            scope: scope,
            failure: scope.actorId == null
                ? ZyraCompatibilityReadFailure.signedOut
                : ZyraCompatibilityReadFailure.staleOwner,
          ),
        );
      }
      return;
    }
    var result = await ZyraJourneyService.fetchCompatibility(scope.matchId);
    if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
    if (result.scope != scope ||
        result.status != ZyraCompatibilityReadStatus.available) {
      _publishReadFailure(
        result.scope == scope
            ? result
            : ZyraCompatibilityReadResult.unavailable(
                scope: scope,
                failure: ZyraCompatibilityReadFailure.staleOwner,
              ),
      );
      return;
    }
    var snapshot = result.snapshot!;

    // Keep the existing valid mutual/null-score first-score recovery.
    // DR250D5's future-held change is not implemented here. An unavailable or
    // empty read never enters this mutation. Explicit Retry skips this legacy
    // recovery; validated one-sided Plus retains its existing server policy.
    if (allowScoreRecovery &&
        !widget.readOnly &&
        snapshot.mine &&
        snapshot.theirs &&
        snapshot.overallScore == null) {
      if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
      await ZyraJourneyService.revealCompatibility(scope.matchId, otherId);
      if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
      result = await ZyraJourneyService.fetchCompatibility(scope.matchId);
      if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
      if (result.scope != scope ||
          result.status != ZyraCompatibilityReadStatus.available) {
        _publishReadFailure(
          result.scope == scope
              ? result
              : ZyraCompatibilityReadResult.unavailable(
                  scope: scope,
                  failure: ZyraCompatibilityReadFailure.staleOwner,
                ),
        );
        return;
      }
      snapshot = result.snapshot!;
    }

    double? plus;
    if (!widget.readOnly && snapshot.mine && !snapshot.theirs) {
      if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
      plus = await ZyraJourneyService.fetchCompatibilityForPlus(scope.matchId);
      if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
    }

    if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
    if (snapshot.mine && snapshot.theirs) {
      _settledSnapshots[scope] = (
        mine: snapshot.mine,
        theirs: snapshot.theirs,
        score: snapshot.overallScore,
        plusScore: plus,
      );
    } else {
      _settledSnapshots.remove(scope);
    }
    final animateNow = ZyraCompatibilityRevealPolicy.shouldAnimate(
      isActionVisible: widget.isActionVisible,
      mineRevealed: snapshot.mine,
      theirsRevealed: snapshot.theirs,
      hasScore: snapshot.overallScore != null,
      alreadyCelebrated: _animateReveal || _celebratedMatches.contains(scope),
    );
    if (animateNow) _celebratedMatches.add(scope);
    setState(() {
      _plusScore = plus;
      _mine = snapshot.mine;
      _theirs = snapshot.theirs;
      _score = snapshot.overallScore;
      _hasConfirmedSnapshot = true;
      _readStatus = ZyraCompatibilityReadStatus.available;
      _readFailure = null;
      _accountRetryRequired = false;
      _loading = false;
      if (animateNow) _animateReveal = true;
    });
  }

  Future<void> _retryRead() {
    _accountRetryRequired = false;
    return _load(allowScoreRecovery: false);
  }

  Future<void> _reveal(
    ZyraCompatibilityReadScope scope,
    int generation,
    bool Function() surfaceOwner,
  ) async {
    if (widget.readOnly ||
        !_readIsAvailable ||
        _loading ||
        _loadFlight != null) {
      return;
    }
    final otherId = widget.profile.id;
    if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
    setState(() => _loading = true);
    await ZyraJourneyService.revealCompatibility(scope.matchId, otherId);
    if (!_canPublish(scope, generation, surfaceOwner: surfaceOwner)) return;
    await _load();
  }

  String get _readFailureMessage => switch (_readFailure) {
    ZyraCompatibilityReadFailure.signedOut =>
      'Sign in again to check your compatibility.',
    ZyraCompatibilityReadFailure.forbidden ||
    ZyraCompatibilityReadFailure.unavailableJourney =>
      'Compatibility is not available for this Journey.',
    ZyraCompatibilityReadFailure.staleOwner =>
      'Your account changed. Check this Journey again to continue.',
    _ =>
      _hasConfirmedSnapshot
          ? 'Showing your last confirmed result. Could not refresh compatibility.'
          : 'Could not load compatibility. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    // A retired outgoing surface may remain mounted for the 480 ms page
    // handover. It is no longer a place to display protected cached content.
    if (!widget.isCurrentSurface() && !_accountRetryRequired) {
      return const SizedBox.shrink();
    }
    if (_loading) return const ZyraLoading();
    if (!_readIsAvailable) {
      final retryScope = _scope;
      final retryGeneration = _readGeneration;
      final retrySurfaceOwner = widget.isCurrentSurface;
      void retryIfCurrent() {
        if (!_canPublish(
          retryScope,
          retryGeneration,
          surfaceOwner: retrySurfaceOwner,
        )) {
          return;
        }
        unawaited(_retryRead());
      }

      final banner = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: ZyraErrorBanner(
          message: !_scopeIsCurrent(_scope)
              ? (ZyraAuth.currentUser == null
                    ? 'Sign in again to check your compatibility.'
                    : 'Your account changed. Check this Journey again to continue.')
              : _readStatus == ZyraCompatibilityReadStatus.empty
              ? 'Compatibility is not available yet for this Journey.'
              : _readFailureMessage,
          onRetry: retryIfCurrent,
        ),
      );
      final keepConfirmed =
          _scopeIsCurrent(_scope) &&
          _readStatus == ZyraCompatibilityReadStatus.unavailable &&
          _readFailure == ZyraCompatibilityReadFailure.transient &&
          _hasConfirmedSnapshot;
      if (!keepConfirmed) return Center(child: banner);
      // Only a same-owner transient refresh can retain confirmed content.
      // It is display-only until a current read confirms the protected action.
      return Column(
        children: [
          banner,
          Expanded(child: IgnorePointer(child: _buildConfirmed(context))),
        ],
      );
    }
    return _buildConfirmed(context);
  }

  Widget _buildConfirmed(BuildContext context) {
    final stage = ZyraJourneyStages.of('compatibility_reveal')!;
    final scope = _scope;
    final generation = _readGeneration;
    final surfaceOwner = widget.isCurrentSurface;
    Future<void> continueIfCurrent() async {
      if (!_readIsAvailable ||
          _loading ||
          !_canPublish(scope, generation, surfaceOwner: surfaceOwner)) {
        return;
      }
      await widget.onContinue();
    }

    // REVEALED, BUT NOT SCOREABLE. Distinct from the retry above, which
    // covers a figure that failed to compute: this is a figure that cannot
    // exist yet, because there is not enough between the two of them to score.
    // Reachable until the onboarding completeness gate (OA-ZYRA-193c) is
    // built, and worth keeping afterwards — the alternative is inventing a
    // number the moment the honest branch is deleted.
    if (_mine && _theirs && _score == null && !_loading) {
      final content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _JourneyPairStatus(
              profile: widget.profile,
              youComplete: _mine,
              otherComplete: _theirs,
            ),
            SizedBox(height: 18),
            Text(
              stage.completionHeading,
              style: ZyraText.heading(size: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'You both chose to reveal.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              '—',
              style: ZyraText.heading(size: 44, color: ZyraColors.ink(0.38)),
            ),
            SizedBox(height: 10),
            Text(
              'There is not enough between you yet to work out a figure. '
              'It appears here once you have both covered more ground.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
          ],
        ),
      );
      if (widget.readOnly || widget.waitingReason == 'waiting_for_continue') {
        return Center(child: content);
      }
      return _JourneyScrollToContinue(
        onContinue: continueIfCurrent,
        openingLabel: 'Opening your choices…',
        expand: true,
        child: content,
      );
    }

    if (_mine && _theirs && _score != null) {
      // SCROLLABLE AS OF 2026-08-11. It was a centred Column, which was fine
      // for a number and five rows and overflows the moment a ZYRA Insight is
      // added under it on a small phone. Center + SingleChildScrollView keeps
      // the old centred look whenever it still fits.
      final intelligence = ZyraJourneyIntelligence.compatibility(
        plan: AppState.instance.plan,
        score: _score!,
      );
      // THE MOMENT — the June spec's STATE 2, built 2026-08-12. First
      // sight of a mutual result: a held beat on "You both chose to
      // reveal", then the genuine caller-owned number counting up.
      // Once, ever — and only once this preloaded page is actually visible.
      // Later visits render the settled screen instantly.
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final animate = _animateReveal && !reduceMotion && _revealIsReady;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: TweenAnimationBuilder<double>(
            key: ValueKey('compatibility-${_scope.hashCode}-$animate'),
            tween: Tween(begin: animate ? 0.0 : 1.0, end: 1.0),
            duration: animate
                ? const Duration(milliseconds: 2600)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              // The overall ring is the one truthful focal point. Category
              // detail stays withheld until the server owns a real,
              // provenance-safe category contract (OA-ZYRA-193d).
              final countT = ((t - 0.18) / 0.40).clamp(0.0, 1.0);
              final shown = (_score! * countT).round();
              final tailT = ((t - 0.85) * 6.7).clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _JourneyPairStatus(
                    profile: widget.profile,
                    youComplete: _mine,
                    otherComplete: _theirs,
                  ),
                  SizedBox(height: 18),
                  Text(
                    stage.completionHeading,
                    style: ZyraText.heading(size: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    stage.completionLine,
                    style: ZyraText.subtext(),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 14),
                  _CompatibilityScoreRing(
                    score: countT == 0 ? null : shown,
                    progress: (_score! / 100 * countT).clamp(0.0, 1.0),
                  ),
                  // Everything below the result fades in after it — the
                  // moment first, the machinery second.
                  Opacity(
                    opacity: tailT,
                    child: IgnorePointer(
                      ignoring: tailT < 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 16),
                          Text(
                            'Detailed compatibility isn’t available yet.',
                            style: ZyraText.subtext(),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          // ZYRA One reads the number back; ZYRA Basic sees
                          // the number and an invitation, and the screen is
                          // complete either way.
                          if (intelligence != null)
                            ZyraIntelligenceCard(intelligence: intelligence)
                          else
                            const ZyraIntelligenceInvitation(
                              kind: ZyraIntelligenceKind.insight,
                            ),
                          SizedBox(height: 20),
                          if (widget.readOnly)
                            SizedBox.shrink()
                          else if (widget.waitingReason ==
                              'waiting_for_continue') ...[
                            Text(
                              "You've chosen to continue. Waiting for ${widget.profile.firstName} — every step here is taken together.",
                              style: ZyraText.subtext(),
                              textAlign: TextAlign.center,
                            ),
                          ] else
                            _JourneyScrollToContinue(
                              onContinue: continueIfCurrent,
                              openingLabel: 'Opening your choices…',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // ── THE THIRD STATE — DR-ZYRA-135, closing OA-ZYRA-152 ────────────────
    //
    // A Plus holder can see the score while the other Seeker has not revealed.
    // They are NEITHER waiting-to-see NOR mutually revealed, and the existing
    // two states are both wrong for them:
    //
    //   "Waiting for Aisha"  — they are not waiting to SEE anything.
    //   "You both chose to reveal." — untrue, and the untrue half is the
    //                                 half about the other person.
    //
    // What they are actually waiting for is her to CONTINUE. So the screen
    // says that, and nothing else.
    //
    // No Continue button here on purpose. The Journey advances when both have
    // revealed — buying the number does not buy the stage (DR-135: "the
    // result is bought, the relationship is not"). Offering Continue would
    // make the purchase look like it moved the Journey, which is the exact
    // misreading the decision was careful to avoid.
    if (_mine && !_theirs && _plusScore != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _JourneyPairStatus(
                profile: widget.profile,
                youComplete: _mine,
                otherComplete: _theirs,
                emphasizeWaiting: true,
              ),
              SizedBox(height: 18),
              Text(
                '${_plusScore!.round()}%',
                style: ZyraText.heading(size: 44),
              ),
              Text('Overall Compatibility', style: ZyraText.subtext()),
              SizedBox(height: 20),
              // Said plainly, because it is the thing they paid for and the
              // thing that could otherwise feel like a glitch: you can see it,
              // they cannot.
              Text(
                'You unlocked this early.',
                style: ZyraText.body(size: 13),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "${widget.profile.firstName} hasn't revealed yet, and hasn't "
                'been told you have. The Journey moves when '
                '${ZyraGender.subject(widget.profile.gender)} does.',
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_mine && !_theirs) {
      return _CompatibilityCompactState(
        profile: widget.profile,
        mine: _mine,
        theirs: _theirs,
        emphasizeWaiting: true,
        headline: 'Reveal chosen',
        body:
            'Waiting for ${widget.profile.firstName}. You open the result together.',
      );
    }

    return _CompatibilityCompactState(
      profile: widget.profile,
      mine: _mine,
      theirs: _theirs,
      headline: ZyraJourneyStages.labelFor('compatibility_reveal'),
      body: 'Neither of you sees the result until you both choose to reveal.',
      action: widget.readOnly
          ? null
          : _JourneyRoundAction(
              label: 'Reveal Compatibility',
              icon: Icons.visibility_outlined,
              onTap: () => _reveal(scope, generation, surfaceOwner),
            ),
    );
  }
}

/// The first focal point of the mutual Compatibility Reveal. The label lives
/// inside a deliberately bounded column rather than being painted around the
/// circumference, so it stays centred and readable on narrow iPhones and at
/// larger accessibility text scales.
class _CompatibilityScoreRing extends StatelessWidget {
  final int? score;
  final double progress;

  const _CompatibilityScoreRing({required this.score, required this.progress});

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: score == null
          ? 'Compatibility score being revealed'
          : '$score percent overall compatibility',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: 176,
            child: CustomPaint(
              painter: _CompatibilityScoreRingPainter(progress: value),
              child: Center(
                child: SizedBox(
                  width: 116,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 50,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            score == null ? '—' : '$score%',
                            maxLines: 1,
                            style: ZyraText.heading(
                              size: 43,
                              color: score == null
                                  ? ZyraColors.ink(0.38)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 3),
                      SizedBox(
                        height: 28,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Overall\nCompatibility',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: ZyraText.subtext(
                              size: 10.5,
                              color: ZyraColors.foreground.withValues(
                                alpha: 0.66,
                              ),
                            ).copyWith(height: 1.15, letterSpacing: 0.15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompatibilityScoreRingPainter extends CustomPainter {
  final double progress;

  const _CompatibilityScoreRingPainter({required this.progress});

  static const _gold = ZyraColors.journeyGold;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(8);
    final track = Paint()
      ..color = ZyraColors.foreground.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawOval(arcRect, track);

    if (progress <= 0) return;
    final sweep = math.pi * 2 * progress;
    final glow = Paint()
      ..color = _gold.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, glow);

    final trace = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, trace);
  }

  @override
  bool shouldRepaint(covariant _CompatibilityScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CompatibilityCompactState extends StatelessWidget {
  final SeekerProfile profile;
  final bool mine;
  final bool theirs;
  final bool emphasizeWaiting;
  final String headline;
  final String body;
  final Widget? action;

  const _CompatibilityCompactState({
    required this.profile,
    required this.mine,
    required this.theirs,
    required this.headline,
    required this.body,
    this.emphasizeWaiting = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _JourneyPairStatus(
              profile: profile,
              youComplete: mine,
              otherComplete: theirs,
              emphasizeWaiting: emphasizeWaiting,
            ),
            SizedBox(height: 14),
            SizedBox(
              height: 64,
              child: Center(
                child: Text(
                  headline,
                  maxLines: 2,
                  style: ZyraText.heading(size: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  body,
                  maxLines: 2,
                  style: ZyraText.subtext(size: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 48),
            SizedBox(height: 130, child: Center(child: action)),
          ],
        ),
      ),
    );
  }
}

// --- Salam Exchange ------------------------------------------------------

/// Stage 1, rebuilt to say almost nothing — DR-ZYRA-192 (Lead Architect
/// brief, 2026-08-17, from the Founder's own finding: even he was pressing
/// the buttons without reading the page). The user already knows what
/// Salam is; the page's whole job is to let two people begin respectfully
/// in seconds. Four states, one line each, at most one action; no opening
/// beats, no veil, no gold rule, no ceremony copy, and no loading
/// animation while the only thing happening is another human taking
/// their time.
///
/// Once both Salams are exchanged, the completed state holds until the
/// member scrolls to continue. This is the Journey's shared transition
/// language: actions are buttons; moving on from a completed chapter is a
/// scroll gesture.
class _SalamExchangeView extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  final bool isActionVisible;
  final Future<void> Function() onContinue;
  const _SalamExchangeView({
    required this.matchId,
    required this.profile,
    required this.isActionVisible,
    required this.onContinue,
  });

  @override
  State<_SalamExchangeView> createState() => _SalamExchangeViewState();
}

class _SalamExchangeViewState extends State<_SalamExchangeView> {
  bool _mine = false;
  bool _theirs = false;

  /// True once a REAL server answer has landed. Until then the page
  /// renders nothing rather than guessing — returning to this page must
  /// show the server's state, not a default.
  bool _known = false;

  bool _sending = false;
  bool _sendFailed = false;
  static const _completionScrollThreshold = 22.0;
  double _completionScrollDistance = 0;
  bool _completionCommitted = false;
  Timer? _completionSignalReset;
  Timer? _poll;
  bool _pollLoadBusy = false;
  Future<void>? _loadFlight;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _pollLoad());
  }

  @override
  void didUpdateWidget(covariant _SalamExchangeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActionVisible && widget.isActionVisible) {
      unawaited(_load());
    }
  }

  Future<void> _pollLoad() async {
    if (_pollLoadBusy ||
        !_journeyViewCanPoll(context) ||
        !widget.isActionVisible) {
      return;
    }
    _pollLoadBusy = true;
    try {
      await _load();
    } finally {
      _pollLoadBusy = false;
    }
  }

  @override
  void dispose() {
    _completionSignalReset?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final active = _loadFlight;
    if (active != null) return active;
    final next = _loadOnce();
    _loadFlight = next;
    try {
      await next;
    } finally {
      if (identical(_loadFlight, next)) _loadFlight = null;
    }
  }

  Future<void> _loadOnce() async {
    final r = await ZyraJourneyService.fetchSalamStatus(
      widget.matchId,
      widget.profile.id,
    );
    if (!mounted || _sending) return;
    // A failed read HOLDS the last known state — flickering a waiting
    // page back to "send" on a bad connection would tell a lie twice.
    if (r == null) return;
    if (_known && r.mine == _mine && r.theirs == _theirs) return;
    setState(() {
      _mine = r.mine;
      _theirs = r.theirs;
      _known = true;
    });
  }

  Future<void> _send() async {
    if (_sending) return; // a double-tap's second tap: no second submission
    setState(() {
      _sending = true;
      _sendFailed = false;
    });
    final ok = await ZyraJourneyService.sendSalam(widget.matchId);
    if (!mounted) return;
    if (!ok) {
      // Same state, same button label, one added line of truth.
      setState(() {
        _sending = false;
        _sendFailed = true;
      });
      return;
    }
    final r = await ZyraJourneyService.fetchSalamStatus(
      widget.matchId,
      widget.profile.id,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (r != null) {
        _mine = r.mine;
        _theirs = r.theirs;
      } else {
        // The send succeeded; the read after it did not. Our own half
        // is a fact we hold locally.
        _mine = true;
      }
      _known = true;
    });
  }

  void _startCompletionScroll(PointerDownEvent event) {
    if (_completionCommitted) return;
    _completionSignalReset?.cancel();
    setState(() => _completionScrollDistance = 0);
  }

  void _trackCompletionScroll(PointerMoveEvent event) {
    _applyCompletionScrollDelta(-event.delta.dy);
  }

  void _trackCompletionScrollSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _applyCompletionScrollDelta(event.scrollDelta.dy);
    _completionSignalReset?.cancel();
    _completionSignalReset = Timer(const Duration(milliseconds: 450), () {
      if (mounted && !_completionCommitted && _completionScrollDistance != 0) {
        setState(() => _completionScrollDistance = 0);
      }
    });
  }

  void _applyCompletionScrollDelta(double delta) {
    if (_completionCommitted) return;
    final distance = ZyraJourneyScroll.completionDistanceAfterInput(
      currentDistance: _completionScrollDistance,
      forwardDelta: delta,
      threshold: _completionScrollThreshold,
    );
    if (distance >= _completionScrollThreshold) {
      _completionSignalReset?.cancel();
      setState(() => _completionScrollDistance = _completionScrollThreshold);
      unawaited(_continueAfterScroll());
      return;
    }
    setState(() => _completionScrollDistance = distance);
  }

  void _finishCompletionScroll(PointerEvent event) {
    if (_completionCommitted || _completionScrollDistance == 0) return;
    setState(() => _completionScrollDistance = 0);
  }

  Future<void> _continueAfterScroll() async {
    if (_completionCommitted) return;
    setState(() => _completionCommitted = true);
    await widget.onContinue();
    // If the server moved the Journey, this widget has been disposed. If it
    // did not, allow one honest retry rather than trapping the completed page.
    if (!mounted) return;
    setState(() {
      _completionCommitted = false;
      _completionScrollDistance = 0;
    });
  }

  void _continueFromSemantics() {
    unawaited(_continueAfterScroll());
  }

  @override
  Widget build(BuildContext context) {
    if (!_known) return SizedBox.shrink();
    final name = widget.profile.firstName;
    final stage = ZyraJourneyStages.of('salam_exchange')!;

    // Founder-directed copy pass: let the greeting itself lead. The page
    // should sound like two people beginning, not software explaining a
    // ceremonial workflow. No gendered pronouns: the person's name is
    // clearer.
    final String stateKey;
    final String headline;
    final String body;
    if (_mine && _theirs) {
      stateKey = 'complete';
      headline = stage.completionHeading;
      body = stage.completionLine;
    } else if (_theirs) {
      stateKey = 'return';
      headline = '$name sent Salam';
      body = 'Wa alaikum assalam.';
    } else if (_mine) {
      stateKey = 'waiting';
      headline = 'Salam sent';
      body = "We'll let you know when $name returns it.";
    } else {
      stateKey = 'send';
      headline = 'Assalamu alaikum';
      body = 'Send Salam to $name to begin.';
    }
    final bool actionable = stateKey == 'send' || stateKey == 'return';
    final Widget stageAction;
    if (actionable) {
      stageAction = _JourneyRoundAction(
        label: stateKey == 'return' ? 'Return Salam' : 'Send Salam',
        onTap: _sending ? null : _send,
      );
    } else if (stateKey == 'complete') {
      stageAction = _JourneyScrollInvitation(
        onContinue: _continueFromSemantics,
        progress: _completionScrollDistance / _completionScrollThreshold,
        continuing: _completionCommitted,
        openingLabel: 'Opening your choices…',
      );
    } else {
      stageAction = SizedBox.shrink();
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: stateKey == 'complete' ? _startCompletionScroll : null,
      onPointerMove: stateKey == 'complete' ? _trackCompletionScroll : null,
      onPointerSignal: stateKey == 'complete'
          ? _trackCompletionScrollSignal
          : null,
      onPointerUp: stateKey == 'complete' ? _finishCompletionScroll : null,
      onPointerCancel: stateKey == 'complete' ? _finishCompletionScroll : null,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 480),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.018),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(stateKey),
              mainAxisSize: MainAxisSize.min,
              children: [
                _JourneyPairStatus(
                  profile: widget.profile,
                  youComplete: _mine,
                  otherComplete: _theirs,
                  salamGoldWake: true,
                  motionEnabled: widget.isActionVisible,
                  // A waiting portrait stays dim until THAT person sends a
                  // Salam. The old emphasizeWaiting treatment brightened the
                  // other person as soon as this user sent, making the one-
                  // sided and completed states look almost identical.
                  youCompleteLabel: 'Salam sent',
                  youWaitingLabel: _theirs ? 'Return Salam' : 'Not sent',
                  otherCompleteLabel: 'Salam received',
                  otherWaitingLabel: 'Awaiting Salam',
                ),
                SizedBox(height: 14),
                SizedBox(
                  height: 64,
                  child: Center(
                    child: Text(
                      headline,
                      maxLines: 2,
                      style: ZyraText.heading(size: 29),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(
                      body,
                      maxLines: 2,
                      style: ZyraText.subtext(size: 14.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: Center(
                    child: _sendFailed && actionable
                        ? Text(
                            "Salam wasn't sent. Check your connection and try again.",
                            style: ZyraText.subtext(
                              size: 12.5,
                              color: ZyraColors.destructive,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : SizedBox.shrink(),
                  ),
                ),
                SizedBox(height: 130, child: Center(child: stageAction)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stage 1's durable history keeps the completed exchange visible instead of
/// reducing two people to a generic tick. It is read-only: neither Salam can
/// be sent again from history.
class _SalamExchangeHistoryView extends StatelessWidget {
  final SeekerProfile profile;

  const _SalamExchangeHistoryView({required this.profile});

  @override
  Widget build(BuildContext context) {
    final stage = ZyraJourneyStages.of('salam_exchange')!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _JourneyPairStatus(
              profile: profile,
              youComplete: true,
              otherComplete: true,
              salamGoldWake: true,
              motionEnabled: false,
              youCompleteLabel: 'Salam sent',
              otherCompleteLabel: 'Salam received',
            ),
            SizedBox(height: 20),
            Text(
              stage.completionHeading,
              style: ZyraText.heading(size: 27),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              stage.completionLine,
              style: ZyraText.subtext(size: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Journey Bio / Life Snapshot mock -------------------------------

/// Display-only Stage 3 inserted after Compatibility Reveal while the
/// Journey Bio experience is tested. It never reads private matching answers:
/// every fact below is explicit mock data controlled by the developer panel.
class _LifeSnapshotView extends StatelessWidget {
  final SeekerProfile profile;
  final bool showBio;
  final Set<String> visibleFieldIds;
  final bool mineRevealed;
  final bool theirsRevealed;
  final VoidCallback onReveal;
  final bool waitingForOther;
  final Future<void> Function() onContinue;
  final bool readOnly;

  const _LifeSnapshotView({
    required this.profile,
    required this.showBio,
    required this.visibleFieldIds,
    required this.mineRevealed,
    required this.theirsRevealed,
    required this.onReveal,
    required this.waitingForOther,
    required this.onContinue,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final revealState = ZyraJourneyLifeSnapshotRevealPolicy.resolve(
      mine: mineRevealed,
      theirs: theirsRevealed,
    );
    if (revealState != ZyraJourneyLifeSnapshotRevealState.revealed) {
      final copy = switch (revealState) {
        ZyraJourneyLifeSnapshotRevealState.neither => (
          'Reveal your profiles together',
          'Neither Journey profile opens until you both choose to reveal.',
        ),
        ZyraJourneyLifeSnapshotRevealState.mineWaiting => (
          'Your profile is ready',
          'Waiting for ${profile.firstName}. You open each other’s profiles together.',
        ),
        ZyraJourneyLifeSnapshotRevealState.theirsWaiting => (
          '${profile.firstName} is ready',
          'Reveal yours to open both Journey profiles.',
        ),
        ZyraJourneyLifeSnapshotRevealState.revealed => throw StateError(
          'Handled above',
        ),
      };
      final headline = copy.$1;
      final body = copy.$2;
      final canReveal = ZyraJourneyLifeSnapshotRevealPolicy.canRevealMine(
        mine: mineRevealed,
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _JourneyPairStatus(
                profile: profile,
                youComplete: mineRevealed,
                otherComplete: theirsRevealed,
                youCompleteLabel: 'Profile revealed',
                youWaitingLabel: 'Not revealed',
                otherCompleteLabel: 'Profile revealed',
                otherWaitingLabel: 'Awaiting reveal',
              ),
              SizedBox(height: 20),
              Icon(
                Icons.visibility_outlined,
                size: 27,
                color: ZyraColors.journeyGold.withValues(alpha: 0.84),
              ),
              SizedBox(height: 12),
              Text(
                headline,
                style: ZyraText.heading(size: 23),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                body,
                style: ZyraText.subtext(size: 13.5),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 34),
              if (canReveal)
                _JourneyRoundAction(
                  label: 'Reveal Profile',
                  icon: Icons.visibility_outlined,
                  onTap: onReveal,
                )
              else
                Text(
                  'Profile revealed · waiting together',
                  style: ZyraText.subtext(
                    size: 12,
                    color: ZyraColors.journeyGold.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final visibleFields = ZyraJourneyLifeSnapshotMock.fields
        .where((field) => visibleFieldIds.contains(field.id))
        .toList(growable: false);
    final sections = <String, List<ZyraJourneyLifeSnapshotField>>{};
    for (final field in visibleFields) {
      sections.putIfAbsent(field.section, () => []).add(field);
    }
    final hasAnything = showBio || visibleFields.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 24,
            color: ZyraColors.journeyGold.withValues(alpha: 0.8),
          ),
          SizedBox(height: 7),
          Text(
            'Profiles revealed',
            style: ZyraText.heading(size: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'You both chose to open this part of the Journey.',
            style: ZyraText.subtext(size: 12.5),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 22),
          Center(
            child: Container(
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ZyraColors.journeyGold, width: 1.5),
              ),
              child: ClipOval(
                child: profile.photoUrl.isEmpty
                    ? ColoredBox(
                        color: ZyraColors.luxuryDarkPurple,
                        child: Center(
                          child: Text(
                            profile.firstName.isEmpty
                                ? '·'
                                : profile.firstName[0].toUpperCase(),
                            style: ZyraText.heading(size: 28),
                          ),
                        ),
                      )
                    : ZyraProfileImage(profile.photoUrl, width: 86, height: 86),
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            profile.firstName,
            style: ZyraText.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5),
          Text(
            'SHARED FOR THIS JOURNEY',
            style: ZyraText.chapterLabel(
              color: ZyraColors.journeyGold.withValues(alpha: 0.82),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),
          if (showBio) ...[
            _LifeSnapshotSectionHeading(label: 'BIO'),
            SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _lifeSnapshotCardDecoration(),
              child: Text(
                ZyraJourneyLifeSnapshotMock.bio,
                style: ZyraText.body(
                  size: 14.5,
                  color: ZyraColors.foreground.withValues(alpha: 0.9),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
          for (final entry in sections.entries) ...[
            _LifeSnapshotSectionHeading(label: entry.key.toUpperCase()),
            SizedBox(height: 9),
            Container(
              decoration: _lifeSnapshotCardDecoration(),
              child: Column(
                children: [
                  for (var index = 0; index < entry.value.length; index++) ...[
                    _LifeSnapshotFactRow(field: entry.value[index]),
                    if (index < entry.value.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: ZyraColors.foreground.withValues(alpha: 0.1),
                      ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
          if (!hasAnything)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              decoration: _lifeSnapshotCardDecoration(),
              child: Column(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 30,
                    color: ZyraColors.foreground.withValues(alpha: 0.52),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Journey bio added',
                    style: ZyraText.heading(size: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 7),
                  Text(
                    'A biography and these life details are optional. '
                    '${profile.firstName} chose not to add them.',
                    style: ZyraText.subtext(size: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: ZyraColors.foreground.withValues(alpha: 0.48),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only what ${profile.firstName} chose to share for this '
                    'Active Journey appears here. Private matching answers '
                    'stay private.',
                    style: ZyraText.subtext(
                      size: 11.5,
                      color: ZyraColors.foreground.withValues(alpha: 0.54),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          if (readOnly)
            SizedBox(height: 12)
          else if (waitingForOther)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'You chose to continue. Waiting for ${profile.firstName}.',
                style: ZyraText.subtext(size: 13.5),
                textAlign: TextAlign.center,
              ),
            )
          else
            _JourneyScrollToContinue(
              onContinue: onContinue,
              idleLabel: 'Continue',
              openingLabel: 'Opening your choices…',
            ),
        ],
      ),
    );
  }
}

BoxDecoration _lifeSnapshotCardDecoration() => BoxDecoration(
  color: ZyraColors.foreground.withValues(alpha: 0.065),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: ZyraColors.foreground.withValues(alpha: 0.13),
    width: 0.7,
  ),
);

class _LifeSnapshotSectionHeading extends StatelessWidget {
  final String label;

  const _LifeSnapshotSectionHeading({required this.label});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)));
}

class _LifeSnapshotFactRow extends StatelessWidget {
  final ZyraJourneyLifeSnapshotField field;

  const _LifeSnapshotFactRow({required this.field});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            field.label,
            style: ZyraText.subtext(
              size: 12,
              color: ZyraColors.foreground.withValues(alpha: 0.58),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            field.value,
            style: ZyraText.body(
              size: 12.5,
              color: ZyraColors.foreground.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

// --- Wali Gate -------------------------------------------------------

/// Guardian Gate.
///
/// REWRITTEN 2026-08-08. It used to read only the ACTING Seeker's own
/// Guardian and, on finding one, silently advance the SHARED journey_stage
/// — so a Seeker who had a Guardian pulled the pair past the gate while the
/// other party had none and never saw this screen. (In practice it advanced
/// nothing at all, because the write underneath it was being discarded by
/// RLS; the two defects hid each other.)
///
/// Founder-decided 2026-08-08: BOTH Seekers must hold an active Main
/// Guardian. That check now lives in zyra_advance_stage(), and this widget
/// only renders which of the two is outstanding after an explicit server
/// check. Polling never advances this gate: the Guardian stage must be seen
/// and chosen.
class _WaliGateView extends StatefulWidget {
  final SeekerProfile profile;
  final String otherFirstName;

  /// From zyra_advance_stage(): 'guardian_required_self' — you must link
  /// one; 'guardian_required_other' — they must. Null while the parent's
  /// first attempt is in flight.
  final String? reason;

  /// Ask the parent to re-poll after the user has linked someone, rather
  /// than waiting up to three seconds for the timer.
  final VoidCallback onChanged;
  final Future<void> Function() onContinue;
  final bool devMode;
  final Set<int> selectedGuardianIndices;
  final Future<bool> Function() onPrepareDevGuardians;
  final bool mineRevealed;
  final bool theirsRevealed;
  final VoidCallback onReveal;
  final Set<int> guardianSalamIndices;
  final ValueChanged<int> onGuardianSalam;
  final ValueChanged<List<_JourneyGuardianPortrait>> onPortraitsResolved;

  const _WaliGateView({
    required this.profile,
    required this.otherFirstName,
    required this.reason,
    required this.onChanged,
    required this.onContinue,
    required this.devMode,
    required this.selectedGuardianIndices,
    required this.onPrepareDevGuardians,
    required this.mineRevealed,
    required this.theirsRevealed,
    required this.onReveal,
    required this.guardianSalamIndices,
    required this.onGuardianSalam,
    required this.onPortraitsResolved,
  });

  @override
  State<_WaliGateView> createState() => _WaliGateViewState();
}

class _WaliGateViewState extends State<_WaliGateView> {
  late final PageController _guardianPager = PageController(
    viewportFraction: 0.72,
  );
  bool _revealing = false;
  int? _sendingGuardianIndex;
  int _guardianPage = 0;
  List<GuardianInfo>? _otherGuardians;
  Future<void>? _otherGuardianLookup;

  @override
  void initState() {
    super.initState();
    // Guardian identities load quietly behind the protected portrait. Mutual
    // consent can therefore reveal settled content without a second loader.
    if (!widget.devMode) {
      _otherGuardianLookup = _loadOtherGuardians();
    }
  }

  Future<void> _loadOtherGuardians() async {
    final guardians = await ZyraGuardianInfoService.fetchUnlocked(
      widget.profile.id,
    );
    guardians?.sort((a, b) {
      if (a.isMain == b.isMain) return 0;
      return a.isMain ? -1 : 1;
    });
    if (!mounted) return;
    setState(() => _otherGuardians = guardians);
    if (guardians != null && guardians.isNotEmpty) {
      widget.onPortraitsResolved(_portraitGuardians);
    }
  }

  @override
  void dispose() {
    _guardianPager.dispose();
    super.dispose();
  }

  Future<void> _revealProfiles() async {
    if (_revealing || widget.mineRevealed) return;
    if (widget.devMode &&
        !widget.selectedGuardianIndices.contains(
          ZyraJourneyGuardianSelection.mainIndex,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select the Main Guardian in the Stage 4 toggle.'),
        ),
      );
      return;
    }

    setState(() => _revealing = true);
    final ready = !widget.devMode || await widget.onPrepareDevGuardians();
    final guardianLookup = _otherGuardianLookup;
    if (guardianLookup != null) {
      try {
        await guardianLookup.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        // Reveal is never held hostage by a slow optional identity lookup.
        // The protected fallback remains honest until it completes.
      }
    }
    if (!mounted) return;
    setState(() => _revealing = false);
    if (ready) widget.onReveal();
  }

  Future<void> _sendGuardianSalam(int guardianIndex) async {
    if (_sendingGuardianIndex != null ||
        widget.guardianSalamIndices.contains(guardianIndex)) {
      return;
    }
    setState(() => _sendingGuardianIndex = guardianIndex);
    widget.onGuardianSalam(guardianIndex);

    // Let the gold Salam confirmation land on this portrait before offering
    // the next ungreeted Guardian. The member can still swipe anywhere and
    // can continue the stage without greeting everybody.
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    final greeted = {...widget.guardianSalamIndices, guardianIndex};
    final next = ZyraJourneyGuardianSalamPolicy.nextUngreeted(
      currentIndex: guardianIndex,
      greetedIndices: greeted,
      guardianCount: _portraitGuardians.length,
    );
    if (next != null && _guardianPager.hasClients) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _guardianPager.jumpToPage(next);
      } else {
        await _guardianPager.animateToPage(
          next,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    }
    if (mounted) setState(() => _sendingGuardianIndex = null);
  }

  List<_JourneyGuardianPortrait> get _portraitGuardians {
    if (widget.devMode) {
      return [
        for (final guardian
            in ZyraJourneyGuardianSelection.otherGuardianPreview)
          _JourneyGuardianPortrait(
            firstName: guardian.firstName,
            relationship:
                zyraRelationshipLabel(guardian.relationship) ??
                guardian.relationship,
            isMain: guardian.isMain,
          ),
      ];
    }

    final guardians = _otherGuardians;
    if (guardians != null && guardians.isNotEmpty) {
      return [
        for (final guardian in guardians)
          _JourneyGuardianPortrait(
            firstName: guardian.firstName,
            relationship: guardian.relationshipLabel,
            city: guardian.city,
            isMain: guardian.isMain,
          ),
      ];
    }

    // The gate proves a Guardian exists, but an older/standard unlock may
    // not grant this client the identity RPC. Keep that truth protected
    // instead of inventing a person or misusing the Seeker's own portrait.
    return const [_JourneyGuardianPortrait(firstName: null, isMain: true)];
  }

  Widget _guardianPortraitFocus({required bool revealed}) {
    final guardians = _portraitGuardians;
    final currentPage = _guardianPage.clamp(0, guardians.length - 1);
    final revealState = ZyraJourneyGuardianRevealPolicy.resolve(
      mine: widget.mineRevealed,
      theirs: widget.theirsRevealed,
    );
    final preRevealCopy = switch (revealState) {
      ZyraJourneyGuardianRevealState.neither => (
        'Meet ${widget.otherFirstName}’s Guardians',
        'You both choose when the Guardian profiles are revealed.',
      ),
      ZyraJourneyGuardianRevealState.mineWaiting => (
        'Your reveal is ready',
        'Waiting for ${widget.otherFirstName}. The profiles open together.',
      ),
      ZyraJourneyGuardianRevealState.theirsWaiting => (
        '${widget.otherFirstName} is ready',
        'Reveal yours to open the Guardian profiles together.',
      ),
      ZyraJourneyGuardianRevealState.revealed => (
        '${widget.otherFirstName}’s Guardians',
        'Their Guardian profiles are now open for this Journey.',
      ),
    };
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 420);

    Widget changingText(String value, TextStyle style) => AnimatedSwitcher(
      duration: duration,
      child: Text(
        value,
        key: ValueKey(value),
        style: style,
        textAlign: TextAlign.center,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!revealed) ...[
            _JourneyPairStatus(
              profile: widget.profile,
              youComplete: widget.mineRevealed,
              otherComplete: widget.theirsRevealed,
              youCompleteLabel: 'Reveal chosen',
              youWaitingLabel: 'Not revealed',
              otherCompleteLabel: 'Reveal chosen',
              otherWaitingLabel: 'Not revealed',
            ),
            SizedBox(height: 14),
          ],
          changingText(
            revealed
                ? '${widget.otherFirstName}’s Guardians'
                : preRevealCopy.$1,
            ZyraText.heading(size: 23),
          ),
          SizedBox(height: 8),
          changingText(
            revealed
                ? 'Profiles revealed. Salam to each Guardian is optional.'
                : preRevealCopy.$2,
            ZyraText.subtext(size: 13.5),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 218,
            child: PageView.builder(
              controller: _guardianPager,
              physics: guardians.length > 1
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: guardians.length,
              onPageChanged: (page) {
                if (mounted) setState(() => _guardianPage = page);
              },
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: _JourneyGuardianPortraitCard(
                  guardian: guardians[index],
                  otherFirstName: widget.otherFirstName,
                  revealed: revealed,
                  salamSent: widget.guardianSalamIndices.contains(index),
                ),
              ),
            ),
          ),
          SizedBox(height: 13),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < guardians.length; index++) ...[
                AnimatedContainer(
                  duration: duration,
                  width: index == currentPage ? 17 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: index == currentPage
                        ? ZyraColors.journeyGold
                        : ZyraColors.foreground.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (index != guardians.length - 1) SizedBox(width: 7),
              ],
            ],
          ),
          if (revealed) ...[
            SizedBox(height: 4),
            SizedBox(
              height: 96,
              child: Center(
                child: AnimatedSwitcher(
                  duration: duration,
                  child: widget.guardianSalamIndices.contains(currentPage)
                      ? Column(
                          key: ValueKey('guardian-salam-sent-$currentPage'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.waving_hand_rounded,
                              size: 22,
                              color: ZyraColors.journeyGold,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Salam sent',
                              style: ZyraText.subtext(
                                size: 11,
                                color: ZyraColors.journeyGold,
                              ),
                            ),
                          ],
                        )
                      : _JourneyRoundAction(
                          key: ValueKey('guardian-salam-$currentPage'),
                          label:
                              'Send Salam to '
                              '${guardians[currentPage].firstName ?? 'this Guardian'}',
                          showLabel: false,
                          icon: _sendingGuardianIndex == currentPage
                              ? Icons.hourglass_top_rounded
                              : Icons.waving_hand_outlined,
                          onTap: _sendingGuardianIndex == null
                              ? () => unawaited(_sendGuardianSalam(currentPage))
                              : null,
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revealState = ZyraJourneyGuardianRevealPolicy.resolve(
      mine: widget.mineRevealed,
      theirs: widget.theirsRevealed,
    );
    if (widget.reason == 'guardian_required_other') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _JourneyPairStatus(
                profile: widget.profile,
                youComplete: true,
                otherComplete: false,
              ),
              SizedBox(height: 18),
              Text(
                ZyraJourneyStages.labelFor('wali_gate'),
                style: ZyraText.heading(size: 20),
              ),
              SizedBox(height: 6),
              Text(
                'Your Guardian is with you. Waiting for '
                '${widget.otherFirstName} to '
                'bring theirs — a Journey in ZYRA is walked with both '
                'families present.',
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 14),
              TextButton(
                onPressed: widget.onChanged,
                child: Text(
                  'Check again',
                  style: ZyraText.subtext(
                    size: 12,
                    color: ZyraColors.ink(0.70),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.reason == null &&
        revealState == ZyraJourneyGuardianRevealState.revealed) {
      // Mutual reveal completes the Guardian introduction. Salams inside the
      // gallery remain optional; the same completion gesture can move forward
      // before, between or after them.
      return _JourneyScrollToContinue(
        onContinue: widget.onContinue,
        idleLabel: 'Continue',
        openingLabel: 'Opening Faith & Values…',
        expand: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: _guardianPortraitFocus(revealed: true),
        ),
      );
    }

    if (widget.reason == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: _guardianPortraitFocus(revealed: false),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 96,
              child: Center(
                child:
                    ZyraJourneyGuardianRevealPolicy.canRevealMine(
                      mine: widget.mineRevealed,
                    )
                    ? _JourneyRoundAction(
                        label:
                            'Reveal Guardian profiles with '
                            '${widget.otherFirstName}',
                        showLabel: false,
                        icon: _revealing
                            ? Icons.hourglass_top_rounded
                            : Icons.visibility_outlined,
                        onTap: _revealing
                            ? null
                            : () => unawaited(_revealProfiles()),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 22,
                            color: ZyraColors.journeyGold,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Reveal chosen · waiting together',
                            style: ZyraText.subtext(
                              size: 11,
                              color: const Color(
                                0xFFE8C98A,
                              ).withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.reason != 'guardian_required_self') {
      return ZyraEmptyState(
        icon: Icons.refresh_rounded,
        title: "Couldn't check the Guardian step",
        message: 'Please try again before moving forward.',
        ctaLabel: 'Try again',
        onCta: widget.onChanged,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ZyraJourneyStages.labelFor('wali_gate'),
              style: ZyraText.heading(size: 20),
            ),
            SizedBox(height: 10),
            Text(
              'This is where your families join you. From here, nothing in '
              'this Journey happens without a Guardian beside each of you — '
              'link yours to continue.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            _JourneyRoundAction(
              label: 'Link a Guardian',
              icon: Icons.shield_outlined,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LinkWaliScreen(asWali: false),
                  ),
                );
                widget.onChanged();
              },
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: widget.onChanged,
              child: Text(
                "I've linked my Guardian — check again",
                style: ZyraText.subtext(size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyGuardianPortrait {
  final String? firstName;
  final String? relationship;
  final String? city;
  final bool isMain;

  const _JourneyGuardianPortrait({
    required this.firstName,
    this.relationship,
    this.city,
    required this.isMain,
  });

  String get initials {
    final words = firstName?.trim().split(RegExp(r'\s+')) ?? const <String>[];
    if (words.isEmpty || words.first.isEmpty) return 'G';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class _JourneyGuardianPortraitCard extends StatelessWidget {
  final _JourneyGuardianPortrait guardian;
  final String otherFirstName;
  final bool revealed;
  final bool salamSent;

  const _JourneyGuardianPortraitCard({
    required this.guardian,
    required this.otherFirstName,
    required this.revealed,
    this.salamSent = false,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 420);
    const gold = ZyraColors.journeyGold;
    final role = guardian.isMain ? 'Main Guardian' : 'Additional Guardian';

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      decoration: BoxDecoration(
        color: ZyraColors.foreground.withValues(
          alpha: revealed ? 0.085 : 0.065,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: guardian.isMain && revealed
              ? gold.withValues(alpha: 0.5)
              : ZyraColors.foreground.withValues(alpha: 0.14),
          width: guardian.isMain && revealed ? 1.2 : 0.8,
        ),
        boxShadow: guardian.isMain && revealed
            ? [BoxShadow(color: gold.withValues(alpha: 0.1), blurRadius: 22)]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: revealed
            ? _RevealedGuardianPortrait(
                key: ValueKey('revealed-${guardian.firstName}'),
                guardian: guardian,
                otherFirstName: otherFirstName,
                role: role,
                salamSent: salamSent,
              )
            : _ProtectedGuardianPortrait(
                key: ValueKey('protected-${guardian.isMain}'),
                otherFirstName: otherFirstName,
                role: role,
              ),
      ),
    );
  }
}

class _ProtectedGuardianPortrait extends StatelessWidget {
  final String otherFirstName;
  final String role;

  const _ProtectedGuardianPortrait({
    super.key,
    required this.otherFirstName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$otherFirstName’s $role, protected until both reveal',
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ZyraColors.foreground.withValues(alpha: 0.055),
                    border: Border.all(
                      color: ZyraColors.foreground.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 52,
                    color: ZyraColors.foreground.withValues(alpha: 0.11),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: 86,
              height: 12,
              decoration: BoxDecoration(
                color: ZyraColors.foreground.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: ZyraColors.foreground.withValues(alpha: 0.1),
                    blurRadius: 9,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            SizedBox(height: 11),
            Text(
              '$otherFirstName’s $role',
              style: ZyraText.subtext(size: 11.5, color: ZyraColors.ink(0.60)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: ZyraColors.journeyGold,
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Protected until both reveal',
                    style: ZyraText.subtext(
                      size: 10,
                      color: ZyraColors.ink(0.54),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealedGuardianPortrait extends StatelessWidget {
  final _JourneyGuardianPortrait guardian;
  final String otherFirstName;
  final String role;
  final bool salamSent;

  const _RevealedGuardianPortrait({
    super.key,
    required this.guardian,
    required this.otherFirstName,
    required this.role,
    required this.salamSent,
  });

  @override
  Widget build(BuildContext context) {
    final name = guardian.firstName?.trim();
    final hasName = name != null && name.isNotEmpty;
    final details = <String>[
      if (guardian.relationship != null && guardian.relationship!.isNotEmpty)
        '$otherFirstName’s ${guardian.relationship!.toLowerCase()}',
      role,
      if (guardian.city != null && guardian.city!.isNotEmpty) guardian.city!,
    ];

    return Semantics(
      label: hasName ? '$name, ${details.join(', ')}' : role,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ZyraColors.foreground.withValues(alpha: 0.2),
                  ZyraColors.luxuryDarkPurple.withValues(alpha: 0.72),
                ],
              ),
              border: Border.all(
                color: guardian.isMain
                    ? ZyraColors.journeyGold
                    : ZyraColors.foreground.withValues(alpha: 0.22),
                width: guardian.isMain ? 2 : 1,
              ),
              boxShadow: guardian.isMain
                  ? [
                      BoxShadow(
                        color: ZyraColors.journeyGold.withValues(alpha: 0.2),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: hasName
                ? Text(guardian.initials, style: ZyraText.heading(size: 20))
                : Icon(
                    Icons.person_outline_rounded,
                    color: ZyraColors.ink(0.70),
                    size: 32,
                  ),
          ),
          SizedBox(height: 14),
          Text(
            hasName ? name : role,
            style: ZyraText.heading(size: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            details.join(' · '),
            style: ZyraText.subtext(size: 10.5, color: ZyraColors.ink(0.60)),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 7),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 320),
            opacity: salamSent ? 1 : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.waving_hand_rounded,
                  size: 11,
                  color: ZyraColors.journeyGold,
                ),
                SizedBox(width: 4),
                Text(
                  'SALAM SENT',
                  style: ZyraText.chapterLabel(color: ZyraColors.journeyGold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only Stage 4 history. The mutually revealed Guardian portraits and
/// any optional Salams remain visible when the member scrolls back from a
/// later stage, matching the durable Compatibility result above it.
class _JourneyGuardianHistoryView extends StatefulWidget {
  final String otherFirstName;
  final List<_JourneyGuardianPortrait> guardians;
  final Set<int> guardianSalamIndices;

  const _JourneyGuardianHistoryView({
    required this.otherFirstName,
    required this.guardians,
    required this.guardianSalamIndices,
  });

  @override
  State<_JourneyGuardianHistoryView> createState() =>
      _JourneyGuardianHistoryViewState();
}

class _JourneyGuardianHistoryViewState
    extends State<_JourneyGuardianHistoryView> {
  late final PageController _pager;
  late int _page;

  @override
  void initState() {
    super.initState();
    final count = widget.guardians.length;
    final greeted =
        widget.guardianSalamIndices
            .where((index) => index >= 0 && index < count)
            .toList()
          ..sort();
    _page = greeted.isEmpty ? 0 : greeted.first;
    _pager = PageController(viewportFraction: 0.72, initialPage: _page);
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guardians = widget.guardians.isEmpty
        ? const [_JourneyGuardianPortrait(firstName: null, isMain: true)]
        : widget.guardians;
    final currentPage = _page.clamp(0, guardians.length - 1);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 320);
    final greetedNames = widget.guardianSalamIndices
        .where((index) => index >= 0 && index < guardians.length)
        .map(
          (index) =>
              guardians[index].firstName ??
              (guardians[index].isMain ? 'the Main Guardian' : 'a Guardian'),
        )
        .toList(growable: false);
    final salamSummary = greetedNames.isEmpty
        ? null
        : greetedNames.length == 1
        ? greetedNames.first
        : greetedNames.length == 2
        ? '${greetedNames.first} and ${greetedNames.last}'
        : '${greetedNames.take(2).join(', ')} and '
              '${greetedNames.length - 2} more';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.otherFirstName}’s Guardians',
              style: ZyraText.heading(size: 23),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 7),
            Text(
              'Profiles revealed for this Journey.',
              style: ZyraText.subtext(size: 13),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 17),
            SizedBox(
              height: 218,
              child: PageView.builder(
                controller: _pager,
                physics: guardians.length > 1
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: guardians.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: _JourneyGuardianPortraitCard(
                    guardian: guardians[index],
                    otherFirstName: widget.otherFirstName,
                    revealed: true,
                    salamSent: widget.guardianSalamIndices.contains(index),
                  ),
                ),
              ),
            ),
            SizedBox(height: 13),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < guardians.length; index++) ...[
                  AnimatedContainer(
                    duration: duration,
                    width: index == currentPage ? 17 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: index == currentPage
                          ? ZyraColors.journeyGold
                          : ZyraColors.foreground.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  if (index != guardians.length - 1) SizedBox(width: 7),
                ],
              ],
            ),
            SizedBox(height: 14),
            AnimatedSwitcher(
              duration: duration,
              child: salamSummary == null
                  ? SizedBox(height: 24)
                  : Semantics(
                      key: ValueKey(salamSummary),
                      label: 'Salam was sent to $salamSummary',
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.waving_hand_rounded,
                              size: 17,
                              color: ZyraColors.journeyGold,
                            ),
                            SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'Salam sent to $salamSummary',
                                style: ZyraText.subtext(
                                  size: 12,
                                  color: ZyraColors.journeyGold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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

// --- Phase 1/2/3 -------------------------------------------------------

class _PhaseView extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  final int phase;
  final bool isActionVisible;
  final VoidCallback onAdvance;
  final Future<void> Function(Future<void> Function()) onRequestDecision;
  const _PhaseView({
    required this.matchId,
    required this.profile,
    required this.phase,
    required this.isActionVisible,
    required this.onAdvance,
    required this.onRequestDecision,
  });

  @override
  State<_PhaseView> createState() => _PhaseViewState();
}

class _PhaseViewState extends State<_PhaseView> {
  late final List<JourneyQuestion> _questions = JourneyQuestions.forPhase(
    widget.phase,
  );
  final Map<String, TextEditingController> _controllers = {};
  Map<String, Map<String, String>> _allAnswers = {};
  Map<String, String> _checkpoints = {};

  /// This Seeker's OWN private ratings, questionId -> rating. Read from the
  /// server on load and kept in step locally as they tap, because from
  /// 2026-08-11 they are no longer write-only: they select the reflection,
  /// drive the ZYRA Recommendation under it, and on ZYRA One they decide
  /// which follow-ups are offered. A rating that vanished on rebuild used to
  /// be invisible; now it would look broken.
  Map<String, String> _ratings = {};
  bool _submitted = false;
  bool _loading = true;
  Timer? _poll;
  bool _pollLoadBusy = false;
  Future<void>? _loadFlight;

  // ── Authoring flow state: one question per screen, then review-and-seal.
  // The shared stage scroll shell now owns the introduction, so this view
  // starts directly at the first real question. Drafts remain local until
  // 'Seal my answers'.
  int _qIndex = 0;
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    for (final q in _questions) {
      _controllers[q.id] = TextEditingController();
    }
    _load();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _pollLoad());
  }

  @override
  void didUpdateWidget(covariant _PhaseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActionVisible && widget.isActionVisible) {
      unawaited(_load(showSpinner: false));
    }
  }

  Future<void> _pollLoad() async {
    if (_pollLoadBusy ||
        !_journeyViewCanPoll(context) ||
        !widget.isActionVisible) {
      return;
    }
    _pollLoadBusy = true;
    try {
      await _load(showSpinner: false);
    } finally {
      _pollLoadBusy = false;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    final active = _loadFlight;
    if (active != null) return active;
    final next = _loadOnce(showSpinner: showSpinner);
    _loadFlight = next;
    try {
      await next;
    } finally {
      if (identical(_loadFlight, next)) _loadFlight = null;
    }
  }

  Future<void> _loadOnce({required bool showSpinner}) async {
    if (showSpinner && mounted) setState(() => _loading = true);
    final answers = await ZyraJourneyService.fetchPhaseAnswers(
      widget.matchId,
      widget.phase,
    );
    final checkpoints = await ZyraJourneyService.fetchCheckpoints(
      widget.matchId,
      widget.phase,
    );
    final ratings = await ZyraJourneyService.fetchMyRatings(
      widget.matchId,
      widget.phase,
    );
    if (!mounted) return;
    final myId = ZyraAuth.currentUser?.id;
    setState(() {
      _allAnswers = answers;
      _checkpoints = checkpoints;
      _ratings = ratings;
      _submitted =
          myId != null && (answers[myId]?.length ?? 0) >= _questions.length;
      _loading = false;
    });

    if (_bothSubmitted &&
        myId != null &&
        checkpoints[myId] != null &&
        checkpoints.length >= 2) {
      widget.onAdvance();
    }
  }

  bool get _bothSubmitted {
    if (_questions.isEmpty) return false;
    return _allAnswers.values
            .where((a) => a.length >= _questions.length)
            .length >=
        2;
  }

  // ── THE ZYRA LAYER. Null on ZYRA Basic, always — see
  // data/zyra_journey_intelligence.dart. Getters rather than fields so they
  // recompute the moment a reflection choice is tapped, which is the point:
  // the recommendation under the answers should change as you mark them.
  ZyraIntelligence? get _followUps => ZyraJourneyIntelligence.phaseFollowUps(
    plan: AppState.instance.plan,
    questions: _questions,
    ratings: _ratings,
    otherName: widget.profile.firstName,
  );

  ZyraIntelligence? get _checkpointAdvice =>
      ZyraJourneyIntelligence.phaseCheckpoint(
        plan: AppState.instance.plan,
        questions: _questions,
        ratings: _ratings,
      );

  ZyraIntelligence? get _summary => ZyraJourneyIntelligence.phaseSummary(
    plan: AppState.instance.plan,
    phaseLabel: ZyraJourneyStages.phase(widget.phase)?.label ?? 'this phase',
    questions: _questions,
    ratings: _ratings,
    otherName: widget.profile.firstName,
  );

  Future<void> _submitAll() async {
    final userId = ZyraAuth.currentUser?.id;
    if (userId == null) return;
    final generation = ZyraAccountState.generation;
    bool isCurrentSubmission() =>
        mounted &&
        ZyraAuth.currentUser?.id == userId &&
        ZyraAccountState.isCurrent(userId, generation);

    var allSaved = true;
    for (var index = 0; index < _questions.length; index++) {
      if (!isCurrentSubmission()) return;
      final q = _questions[index];
      final text = _controllers[q.id]!.text.trim();
      if (!JourneyQuestions.answerFitsCharacterLimit(widget.phase, text)) {
        if (!mounted) return;
        setState(() {
          _reviewing = false;
          _qIndex = index;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Each Faith & Values answer can be up to 400 characters.',
            ),
          ),
        );
        return;
      }
      if (text.isNotEmpty) {
        final saved = await ZyraJourneyService.submitPhaseAnswer(
          widget.matchId,
          widget.phase,
          q.id,
          text,
        );
        if (!isCurrentSubmission()) return;
        if (!saved) allSaved = false;
      }
    }
    if (!isCurrentSubmission()) return;
    if (!allSaved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Some answers didn't save — check your connection and submit again.",
          ),
        ),
      );
    }
    await _load();
  }

  Future<void> _rate(String questionId, String rating) async {
    // Optimistic, then written. The signal has to select instantly — this is a
    // private note to yourself, and waiting on a round-trip to see it land
    // reads as the tap having missed.
    final previous = _ratings[questionId];
    setState(() => _ratings[questionId] = rating);
    final saved = await ZyraJourneyService.submitRating(
      widget.matchId,
      widget.phase,
      questionId,
      rating,
    );
    if (!saved && mounted) {
      setState(() {
        if (previous == null) {
          _ratings.remove(questionId);
        } else {
          _ratings[questionId] = previous;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("That reflection didn't save — please try again."),
        ),
      );
    }
  }

  Future<void> _checkpoint(String decision) async {
    final saved = await ZyraJourneyService.submitCheckpoint(
      widget.matchId,
      widget.phase,
      decision,
    );
    await _load();
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your choice didn't save — please try again."),
        ),
      );
    }
  }

  // _phaseGuidingQuestion REMOVED 2026-08-09 — the three questions now
  // live on ZyraJourneyStage.guidingQuestion in
  // data/zyra_journey_stages.dart, beside the labels that were derived
  // from them. Keeping them apart meant the heading and the question
  // under it could be edited independently and end up describing
  // different things.
  //
  // Same copy, moved — not rewritten.

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ZyraLoading();

    final myId = ZyraAuth.currentUser?.id;
    final otherId = widget.profile.id;
    final myAnswers = myId == null
        ? const <String, String>{}
        : (_allAnswers[myId] ?? const {});
    final theirAnswers = _allAnswers[otherId] ?? const {};

    if (_bothSubmitted) {
      final myCheckpoint = myId == null ? null : _checkpoints[myId];
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The label still comes from the map, never a literal here.
            Text(
              (ZyraJourneyStages.phase(widget.phase)?.label ??
                      'Phase ${widget.phase}')
                  .toUpperCase(),
              style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
            ),
            SizedBox(height: 4),
            Text(
              'Your answers, opened together',
              style: ZyraText.heading(size: 18),
            ),
            SizedBox(height: 4),
            Text(
              'Read slowly — there is no clock on this stage.',
              style: ZyraText.subtext(),
            ),
            SizedBox(height: 20),
            for (var index = 0; index < _questions.length; index++)
              _JourneyRevealedQuestion(
                question: _questions[index],
                questionNumber: index + 1,
                questionCount: _questions.length,
                myAnswer: myAnswers[_questions[index].id] ?? '—',
                theirAnswer: theirAnswers[_questions[index].id] ?? '—',
                otherName: widget.profile.firstName,
                rating: _ratings[_questions[index].id],
                onRate: (rating) => _rate(_questions[index].id, rating),
              ),
            // The privacy line the spec asks for on every phase. It sits
            // directly under the ratings it is about, not in a footer.
            SizedBox(height: 4),
            Text(
              'Your answers are shared with ${widget.profile.firstName} and '
              'your Guardian. Your ratings are private and used only to guide '
              'your journey.',
              style: ZyraText.privacyText(),
            ),
            SizedBox(height: 8),
            if (_summary != null) ZyraIntelligenceCard(intelligence: _summary!),
            if (_followUps != null)
              ZyraIntelligenceCard(intelligence: _followUps!),
            if (_checkpointAdvice != null)
              ZyraIntelligenceCard(intelligence: _checkpointAdvice!)
            else if (AppState.instance.plan != ZyraPlan.one)
              const ZyraIntelligenceInvitation(
                kind: ZyraIntelligenceKind.recommendation,
              ),
            if (myCheckpoint == null) ...[
              Text(
                'Close this chapter together?',
                style: ZyraText.heading(size: 15),
              ),
              SizedBox(height: 4),
              Text(
                'What you shared here stays on your Timeline. '
                '${_nextChapterLabel != null ? '${_nextChapterLabel!} is next.' : ''}',
                style: ZyraText.subtext(),
              ),
              SizedBox(height: 10),
              _JourneyScrollToContinue(
                onContinue: () =>
                    widget.onRequestDecision(() => _checkpoint('continue')),
                openingLabel: 'Opening your choices…',
              ),
            ] else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ZyraJourneyStages.phase(widget.phase)!.completionHeading,
                      style: ZyraText.heading(size: 17),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      ZyraJourneyStages.phase(widget.phase)!.completionLine,
                      style: ZyraText.subtext(),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Waiting for ${widget.profile.firstName} to close it too.',
                      style: ZyraText.subtext(
                        size: 12.5,
                        color: ZyraColors.ink(0.60),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    if (_submitted) {
      // THE ENVELOPE, NAMED — 2026-08-12. The mechanic was always this
      // (neither sees anything until both have finished); the old copy
      // narrated it as a queue. No spinner: the system is not loading, a
      // person is writing. The wait offers something worthy of the time —
      // your own answers, to read once more.
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.profile.firstName} is still writing',
              style: ZyraText.heading(size: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Your answers are sealed until ${widget.profile.firstName} '
              'finishes — you open them together. There is no clock on this.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            _SealedAnswers(questions: _questions, answers: myAnswers),
          ],
        ),
      );
    }

    // One question per screen, then review-and-seal. The shared scroll shell
    // above this view has already provided the chapter's arrival and meaning.
    final chapterLabel =
        ZyraJourneyStages.phase(widget.phase)?.label ?? 'Phase ${widget.phase}';

    if (_reviewing) {
      final missing = _questions
          .where((q) => _controllers[q.id]!.text.trim().isEmpty)
          .length;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Read yours once more', style: ZyraText.heading(size: 18)),
            SizedBox(height: 4),
            Text(
              'Sealed answers wait for ${widget.profile.firstName}. Tap one '
              'to change it.',
              style: ZyraText.subtext(),
            ),
            SizedBox(height: 16),
            for (var i = 0; i < _questions.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _reviewing = false;
                  _qIndex = i;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ZyraColors.foreground.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ZyraColors.foreground.withValues(alpha: 0.10),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _questions[i].text,
                        style: ZyraText.subtext(size: 11.5),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _controllers[_questions[i].id]!.text.trim().isEmpty
                            ? 'Not answered yet'
                            : _controllers[_questions[i].id]!.text.trim(),
                        style: ZyraText.body(
                          size: 13.5,
                          color:
                              _controllers[_questions[i].id]!.text
                                  .trim()
                                  .isEmpty
                              ? ZyraColors.ink(0.38)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
            SizedBox(height: 8),
            Center(
              child: _JourneyRoundAction(
                label: missing == 0
                    ? 'Seal my answers'
                    : '$missing still to answer',
                icon: Icons.lock_outline,
                onTap: missing == 0 ? _submitAll : null,
              ),
            ),
          ],
        ),
      );
    }

    final q = _questions[_qIndex];
    final answerCharacterLimit = JourneyQuestions.answerCharacterLimitForPhase(
      widget.phase,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  chapterLabel.toUpperCase(),
                  style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
                ),
              ),
              Text(
                'Question ${_qIndex + 1} of ${_questions.length}',
                style: ZyraText.subtext(size: 11, color: ZyraColors.ink(0.38)),
              ),
            ],
          ),
          if (_qIndex == 0) ...[
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: ZyraColors.foreground.withValues(alpha: 0.045),
                border: const Border(
                  left: BorderSide(color: ZyraColors.journeyGold, width: 2),
                ),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'You are answering privately. ',
                      style: ZyraText.subtext(
                        size: 11.5,
                        color: ZyraColors.journeyGold,
                      ),
                    ),
                    TextSpan(
                      text:
                          'After all ${_questions.length}, you can review every answer before sealing. When you both seal, the answers open to both of you and your Guardians.',
                      style: ZyraText.subtext(
                        size: 11.5,
                        color: ZyraColors.foreground.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 18),
          Text(q.text, style: ZyraText.heading(size: 17)),
          SizedBox(height: 14),
          TextField(
            controller: _controllers[q.id],
            maxLines: 5,
            maxLength: answerCharacterLimit,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: answerCharacterLimit == null
                ? null
                : (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => Text(
                    '$currentLength / $maxLength',
                    style: ZyraText.subtext(
                      size: 11,
                      color:
                          currentLength >= (answerCharacterLimit * 0.9).round()
                          ? ZyraColors.journeyGold
                          : ZyraColors.ink(0.38),
                    ),
                  ),
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: ZyraColors.foreground.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintText: 'In your own words…',
              hintStyle: TextStyle(color: ZyraColors.ink(0.38)),
              counterStyle: ZyraText.subtext(
                size: 11,
                color: ZyraColors.ink(0.38),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              if (_qIndex > 0) ...[
                OutlinedButton(
                  onPressed: () => setState(() => _qIndex -= 1),
                  child: Text('Back', style: ZyraText.button(size: 13)),
                ),
                SizedBox(width: 10),
              ],
              Expanded(
                child: Center(
                  child: _FrostPill(
                    label: _qIndex < _questions.length - 1
                        ? 'Next · Question ${_qIndex + 2} of ${_questions.length}'
                        : 'Review my answers',
                    onTap: () => setState(() {
                      if (_qIndex < _questions.length - 1) {
                        _qIndex += 1;
                      } else {
                        _reviewing = true;
                      }
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The chapter after this one, for the seal copy. Null past the map's end.
  String? get _nextChapterLabel {
    final me = ZyraJourneyStages.phase(widget.phase);
    if (me == null || me.order >= ZyraJourneyStages.all.length) return null;
    return ZyraJourneyStages.all[me.order].label;
  }
}

/// Your own sealed answers, rereadable while the other person writes.
class _SealedAnswers extends StatefulWidget {
  final List<JourneyQuestion> questions;
  final Map<String, String> answers;
  const _SealedAnswers({required this.questions, required this.answers});

  @override
  State<_SealedAnswers> createState() => _SealedAnswersState();
}

class _SealedAnswersState extends State<_SealedAnswers> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => setState(() => _open = !_open),
          child: Text(
            _open ? 'Hide your answers' : 'Read your answers again',
            style: ZyraText.button(size: 13),
          ),
        ),
        if (_open) ...[
          SizedBox(height: 14),
          for (final q in widget.questions) ...[
            Text(q.text, style: ZyraText.subtext(size: 11.5)),
            SizedBox(height: 4),
            Text(widget.answers[q.id] ?? '—', style: ZyraText.body(size: 13.5)),
            SizedBox(height: 14),
          ],
        ],
      ],
    );
  }
}

class _JourneyRevealedQuestion extends StatelessWidget {
  final JourneyQuestion question;
  final int questionNumber;
  final int questionCount;
  final String myAnswer;
  final String theirAnswer;
  final String otherName;
  final String? rating;
  final ValueChanged<String> onRate;

  const _JourneyRevealedQuestion({
    required this.question,
    required this.questionNumber,
    required this.questionCount,
    required this.myAnswer,
    required this.theirAnswer,
    required this.otherName,
    required this.rating,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ZyraColors.foreground.withValues(alpha: 0.12)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUESTION $questionNumber OF $questionCount',
            style: ZyraText.chapterLabel(
              color: ZyraColors.journeyGold.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 9),
          Text(question.text, style: ZyraText.heading(size: 16)),
          SizedBox(height: 16),
          _JourneyRevealedAnswerRow(label: 'YOU', answer: myAnswer),
          SizedBox(height: 11),
          _JourneyRevealedAnswerRow(
            label: otherName.toUpperCase(),
            answer: theirAnswer,
          ),
          SizedBox(height: 19),
          Text(
            'YOUR PRIVATE REFLECTION',
            style: ZyraText.chapterLabel(
              color: ZyraColors.foreground.withValues(alpha: 0.44),
            ),
          ),
          SizedBox(height: 10),
          _TrafficLightRatingScale(selected: rating, onSelected: onRate),
        ],
      ),
    );
  }
}

class _JourneyRevealedAnswerRow extends StatelessWidget {
  final String label;
  final String answer;

  const _JourneyRevealedAnswerRow({required this.label, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZyraText.chapterLabel(
                color: ZyraColors.foreground.withValues(alpha: 0.46),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            answer,
            style: ZyraText.body(
              size: 13.5,
              color: ZyraColors.foreground.withValues(alpha: 0.86),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrafficLightRatingOption {
  final String value;
  final String label;
  final Color color;

  const _TrafficLightRatingOption({
    required this.value,
    required this.label,
    required this.color,
  });
}

class _TrafficLightRatingScale extends StatelessWidget {
  static const _options = [
    _TrafficLightRatingOption(
      value: 'reassured',
      label: 'Reassured me',
      color: ZyraColors.positiveGreen,
    ),
    _TrafficLightRatingOption(
      value: 'discuss_further',
      label: 'Discuss further',
      color: ZyraColors.journeyGold,
    ),
    _TrafficLightRatingOption(
      value: 'concerns',
      label: 'Concerns me',
      color: ZyraColors.negativeRed,
    ),
  ];

  final String? selected;
  final ValueChanged<String> onSelected;

  const _TrafficLightRatingScale({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            top: 13.5,
            left: 0,
            right: 0,
            child: Row(
              children: [
                const Spacer(),
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 1,
                    color: ZyraColors.foreground.withValues(alpha: 0.2),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final option in _options)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected == option.value,
                    label: option.label,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelected(option.value),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: option.color.withValues(
                                    alpha: selected == option.value ? 1 : 0.6,
                                  ),
                                  border: selected == option.value
                                      ? Border.all(
                                          color: ZyraColors.foreground
                                              .withValues(alpha: 0.88),
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: ZyraColors.luxuryDarkPurple,
                                          width: 4,
                                        ),
                                  boxShadow: selected == option.value
                                      ? [
                                          BoxShadow(
                                            color: option.color.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 10,
                                            spreadRadius: 3,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                option.label,
                                style: ZyraText.subtext(
                                  size: 10.5,
                                  color: selected == option.value
                                      ? Colors.white
                                      : ZyraColors.foreground.withValues(
                                          alpha: 0.68,
                                        ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Family Compatibility Stage ---------------------------------------

class _FamilyStageView extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  final bool isActionVisible;
  final Future<void> Function() onAdvance;
  final Future<void> Function(Future<void> Function()) onRequestDecision;
  const _FamilyStageView({
    required this.matchId,
    required this.profile,
    required this.isActionVisible,
    required this.onAdvance,
    required this.onRequestDecision,
  });

  @override
  State<_FamilyStageView> createState() => _FamilyStageViewState();
}

class _FamilyStageViewState extends State<_FamilyStageView> {
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _submitted = false;
  bool _waliAnswered = false;
  Timer? _poll;
  bool _pollLoadBusy = false;
  Future<void>? _loadFlight;

  /// Ratings from ALL THREE phases, because the summary the Guardian is given
  /// is about the Journey, not about this stage.
  Map<String, String> _ratings = {};

  @override
  void initState() {
    super.initState();
    for (final q in JourneyQuestions.waliToSeeker) {
      _controllers[q.id] = TextEditingController();
    }
    _load();
    // Polls for the Wali's answers so this screen advances the moment
    // both sides are done, without the Seeker needing to reopen it.
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _pollLoad());
  }

  @override
  void didUpdateWidget(covariant _FamilyStageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActionVisible && widget.isActionVisible) {
      unawaited(_load(showSpinner: false));
    }
  }

  Future<void> _pollLoad() async {
    if (_pollLoadBusy ||
        !_journeyViewCanPoll(context) ||
        !widget.isActionVisible) {
      return;
    }
    _pollLoadBusy = true;
    try {
      await _load(showSpinner: false);
    } finally {
      _pollLoadBusy = false;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    final active = _loadFlight;
    if (active != null) return active;
    final next = _loadOnce(showSpinner: showSpinner);
    _loadFlight = next;
    try {
      await next;
    } finally {
      if (identical(_loadFlight, next)) _loadFlight = null;
    }
  }

  Future<void> _loadOnce({required bool showSpinner}) async {
    final userId = ZyraAuth.currentUser?.id;
    if (userId == null) return;
    final generation = ZyraAccountState.generation;
    bool isCurrentLoad() =>
        mounted &&
        ZyraAuth.currentUser?.id == userId &&
        ZyraAccountState.isCurrent(userId, generation);

    if (!isCurrentLoad()) return;
    if (showSpinner && mounted) setState(() => _loading = true);
    final myAnswers = await ZyraJourneyService.fetchFamilyAnswers(
      widget.matchId,
      'wali_to_seeker',
    );
    if (!isCurrentLoad()) return;
    final waliAnswers = await ZyraJourneyService.fetchFamilyAnswers(
      widget.matchId,
      'seeker_to_wali',
    );
    if (!isCurrentLoad()) return;
    final ratings = await ZyraJourneyService.fetchAllMyRatings(widget.matchId);
    if (!isCurrentLoad()) return;
    final submitted = myAnswers.length >= JourneyQuestions.waliToSeeker.length;
    final waliAnswered =
        waliAnswers.length >= JourneyQuestions.seekerToWali.length;
    setState(() {
      _submitted = submitted;
      _waliAnswered = waliAnswered;
      _ratings = ratings;
      _loading = false;
    });
    // BOTH sides must answer before Conversation (Founder, 2026-07-26) —
    // the Guardian's participation is real, not cosmetic. The AUTO-advance
    // that used to fire here is GONE (2026-08-12, experience redesign):
    // "Both families have spoken with you both" is plausibly the most
    // reassuring sentence this app ever shows, and it replaced itself in
    // under a second. The build now HOLDS that state until the couple
    // continues by choice.
  }

  Future<void> _submit() async {
    final userId = ZyraAuth.currentUser?.id;
    if (userId == null) return;
    final generation = ZyraAccountState.generation;
    bool isCurrentSubmission() =>
        mounted &&
        ZyraAuth.currentUser?.id == userId &&
        ZyraAccountState.isCurrent(userId, generation);

    // BUG-03 (2026-08-14 audit, OA-ZYRA-225 — fixed 2026-08-15):
    // submitFamilyAnswer reports failure now, and this surfaces it. The
    // text stays in the controllers either way, and _load() keeps
    // deriving _submitted from what the SERVER holds — so a failed
    // write can no longer masquerade as a submitted state, and pressing
    // Submit again re-sends safely (duplicate rows are tolerated by
    // fetchFamilyAnswers' later-insert-wins ordering).
    var allSaved = true;
    for (final q in JourneyQuestions.waliToSeeker) {
      if (!isCurrentSubmission()) return;
      final text = _controllers[q.id]!.text.trim();
      if (text.isNotEmpty) {
        final ok = await ZyraJourneyService.submitFamilyAnswer(
          widget.matchId,
          'wali_to_seeker',
          q.id,
          text,
        );
        if (!isCurrentSubmission()) return;
        if (!ok) allSaved = false;
      }
    }
    if (!isCurrentSubmission()) return;
    if (!allSaved && mounted) {
      showZyraFamilyAnswersWriteFailure(context);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ZyraLoading();
    final stage = ZyraJourneyStages.of('family_stage')!;

    if (_submitted) {
      final guardianSummary = ZyraJourneyIntelligence.guardianSummary(
        plan: AppState.instance.plan,
        otherName: widget.profile.firstName,
        ratings: _ratings,
        questions: [
          ...JourneyQuestions.phase1,
          ...JourneyQuestions.phase2,
          ...JourneyQuestions.phase3,
        ],
      );
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _waliAnswered
                    ? stage.completionHeading
                    : 'Your Guardian is answering',
                style: ZyraText.heading(size: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _waliAnswered
                    ? stage.completionLine
                    : "You've answered ${widget.profile.firstName}'s family. "
                          'Your Journey continues once your own Guardian has '
                          'answered theirs — families are not hurried here.',
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              if (guardianSummary != null)
                ZyraIntelligenceCard(intelligence: guardianSummary)
              else
                const ZyraIntelligenceInvitation(
                  kind: ZyraIntelligenceKind.summary,
                ),
              if (_waliAnswered) ...[
                SizedBox(height: 20),
                _JourneyScrollToContinue(
                  onContinue: () => widget.onRequestDecision(widget.onAdvance),
                  openingLabel: 'Opening your choices…',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ZyraJourneyStages.labelFor('family_stage'),
            style: ZyraText.heading(size: 18),
          ),
          SizedBox(height: 6),
          Text(
            'Your families meet your Journey here. '
            "${widget.profile.firstName}'s Guardian asks you their questions; "
            'yours asks theirs. Answer as if they were sitting across from '
            'you — they are.',
            style: ZyraText.subtext(),
          ),
          SizedBox(height: 18),
          Text(
            "${widget.profile.firstName}'s family asks:",
            style: ZyraText.body(size: 13, color: ZyraColors.ink(0.70)),
          ),
          SizedBox(height: 10),
          for (final q in JourneyQuestions.waliToSeeker) ...[
            Text(q.text, style: ZyraText.body(size: 14)),
            SizedBox(height: 6),
            TextField(
              controller: _controllers[q.id],
              maxLines: 3,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: ZyraColors.foreground.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Your answer…',
                hintStyle: TextStyle(color: ZyraColors.ink(0.38)),
              ),
            ),
            SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: Center(
              child: _JourneyRoundAction(
                label: 'Share my answers',
                icon: Icons.send_outlined,
                onTap: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Open Conversation ------------------------------------------------
//
// The eighth and final stage. Added 2026-08-11; before this the case simply
// pushed ChatScreen and the stage had no screen of its own.
//
// It is a threshold, not a reward. "This is NOT the reward at the end of a
// checklist. The structured journey continues — it simply becomes less rigid
// and more open" (PRE-JOURNEY RITUAL/Summary.md), and JOURNEY PHILOSOPHY §2
// says the same in stronger words. So this screen marks the change, hands
// over what was left open along the way, and then gets out of the road.
class _OpenConversationView extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  const _OpenConversationView({required this.matchId, required this.profile});

  @override
  State<_OpenConversationView> createState() => _OpenConversationViewState();
}

class _OpenConversationViewState extends State<_OpenConversationView> {
  ZyraIntelligence? _topics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ratings = await ZyraJourneyService.fetchAllMyRatings(widget.matchId);
    if (!mounted) return;
    setState(() {
      _topics = ZyraJourneyIntelligence.conversationTopics(
        plan: AppState.instance.plan,
        ratings: ratings,
        otherName: widget.profile.firstName,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ZyraLoading();
    final name = widget.profile.firstName;
    final stage = ZyraJourneyStages.of('conversation')!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              stage.completionHeading,
              style: ZyraText.heading(size: 22),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              '${stage.completionLine} Your Timeline keeps going, and your '
              'Guardians remain part of it.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 14),
            // THE EARNED ARRIVAL — 2026-08-12 (experience redesign §7).
            // Not a badge and not a number: the accurate list of what they
            // actually did to be standing here.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ZyraColors.foreground.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ZyraColors.foreground.withValues(alpha: 0.14),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in const [
                    'Three chapters, written and sealed together.',
                    'Both families, present and heard.',
                    'Every step, chosen twice.',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 14,
                            color: ZyraColors.foreground.withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(line, style: ZyraText.body(size: 13)),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    'You have earned this conversation.',
                    style: ZyraText.subtext(size: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
            if (_topics != null)
              ZyraIntelligenceCard(intelligence: _topics!)
            else if (AppState.instance.plan != ZyraPlan.one)
              const ZyraIntelligenceInvitation(
                kind: ZyraIntelligenceKind.recommendation,
              ),
            SizedBox(height: 14),
            Center(
              child: _JourneyRoundAction(
                label: 'Open your conversation with $name',
                icon: Icons.forum_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(withProfile: widget.profile),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      JourneyTimelineScreen(withProfile: widget.profile),
                ),
              ),
              child: Text(
                'Read your story so far',
                style: ZyraText.subtext(
                  size: 12.5,
                  color: ZyraColors.ink(0.70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
