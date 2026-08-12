// Pre-Journey Ritual host screen — APP/Journey/PRE-JOURNEY RITUAL/
// Summary.md. Routes an Active Journey through its real stages
// (matches.journey_stage): Compatibility Reveal -> Salam Exchange ->
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
//   states poll every 3 seconds via Timer.periodic rather than a
//   Supabase Realtime channel subscription.
// - Compatibility category breakdown mirrors the overall score for
//   every category (score_candidates() doesn't expose per-category
//   detail yet) — a real breakdown is future work.

import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../data/journey_questions.dart';
import '../../data/zyra_entitlements.dart';
import '../../data/zyra_journey_intelligence.dart';
import '../../data/zyra_journey_stages.dart';
import '../../models/journey_match.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_journey_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../chat/chat_screen.dart';
import '../profile/seeker_profile_screen.dart';
import '../subscription/upgrade_screen.dart';
import '../wali/link_wali_screen.dart';
import '../../widgets/anchored_card_overlay.dart';
import '../../widgets/zyra_glass_dialog.dart';
import '../../widgets/zyra_intelligence_card.dart';
import '../../widgets/zyra_loading.dart';

class JourneyFlowScreen extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  const JourneyFlowScreen({super.key, required this.matchId, required this.profile});

  @override
  State<JourneyFlowScreen> createState() => _JourneyFlowScreenState();
}

class _JourneyFlowScreenState extends State<JourneyFlowScreen> {
  String _status = 'active';
  String? _stage = 'compatibility_reveal';
  String? _suspendedBy;
  DateTime? _endedAt; // #17 — drives the 24h cooling period / Restart gate
  bool _loading = true;
  Timer? _poll;

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
    _refresh();
    _loadCounterpartReveal();
    _loadPlusUnlock();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh(showSpinner: false));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool showSpinner = true}) async {
    if (showSpinner && mounted) setState(() => _loading = true);
    // #31 — lazy-resolve a due review (48h elapsed, no Pause) before
    // reading the match's current stage, so a Journey whose review
    // timed out while nobody had this screen open still advances the
    // moment either party next opens it, exactly like every other
    // poll-driven state in this screen.
    await ZyraJourneyService.resolveFamilyReviewIfDue(widget.matchId);
    var fresh = await ZyraJourneyService.refetchOne(widget.matchId, widget.profile.id);

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
    // ── WHY compatibility_reveal IS CONDITIONAL AND wali_gate IS NOT.
    //
    // zyra_advance_stage() INSERTS the caller's own stage checkpoint before it
    // checks anything, so an unconditional retry here would quietly record
    // "they chose to continue" for someone who has not pressed anything. The
    // Continue is a deliberate act and the server treats it as one.
    //
    // _advanceReason is non-null only after an explicit attempt, so gating on
    // it means: you pressed it, the server said "waiting for them", and we
    // keep asking on your behalf. wali_gate has no user action to consent to
    // — it opens on a fact about both accounts — so it stays unconditional.
    fresh = await _retryStalledAdvance(fresh);

    final review = await ZyraJourneyService.fetchFamilyReview(widget.matchId);
    if (!mounted) return;
    if (fresh != null) {
      final m = fresh;
      setState(() {
        _status = m.status;
        _stage = m.journeyStage;
        _suspendedBy = m.suspendedBy;
        _endedAt = m.endedAt;
        _review = review;
        _loading = false;
      });
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
    if (fresh == null || fresh.status != 'active' || fresh.isSuspended) return fresh;
    final stage = fresh.journeyStage;
    if (stage == null) return fresh;

    final retry = stage == 'wali_gate' ||
        (_advanceReason != null &&
            (stage == 'compatibility_reveal' || stage == 'salam_exchange'));
    if (!retry) return fresh;

    final r = await ZyraJourneyService.advanceStage(widget.matchId, stage);
    _advanceReason = r.advanced ? null : r.reason;
    if (!r.advanced) return fresh;
    return await ZyraJourneyService.refetchOne(widget.matchId, widget.profile.id);
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
    await _refresh();
  }

  /// #31 — the 4 "both Seekers complete a stage" transitions open a
  /// Family Review Period instead of advancing journey_stage directly.
  /// Safe to call from whichever Seeker's client reaches this point
  /// first (openFamilyReview is idempotent).
  Future<void> _advanceGated(String fromStage, String toStage) async {
    final r = await ZyraJourneyService.openFamilyReview(widget.matchId, fromStage, toStage);
    if (!mounted) return;
    // SURFACE IT. Since 2026-08-09 the server validates this call (audit
    // 2.2), so it can refuse — and the return value used to be discarded
    // entirely, which meant a refusal looked exactly like a success: a
    // tap, a refresh, and nothing moving. That is the 2026-08-07 release
    // blocker's signature, and it would have been reintroduced by the
    // very fix that hardened the server.
    if (!r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_reviewRefusedMessage(r.reason))),
      );
    }
    await _refresh();
  }

  /// The server's vocabulary turned into something a person can act on.
  /// 'stage_moved' is the one a real user will actually hit — the other
  /// Seeker's client opened the same review a moment earlier — and it is
  /// not an error from their point of view, so it does not read like one.
  static String _reviewRefusedMessage(String reason) => switch (reason) {
        'stage_moved' => 'This Journey has already moved on — bringing you up to date.',
        'journey_paused' => 'This Journey is paused. Resume it to continue.',
        'journey_not_active' => 'This Journey is no longer active.',
        'not_a_gated_transition' || 'invalid_transition' =>
          "That step isn't available from here.",
        _ => "That didn't go through. Please try again.",
      };

  // RESTYLED 2026-08-11 (Frost UI pass — Founder: black surfaces "dont
  // feel like the app culture"). Was an AlertDialog with the unratified
  // near-black 0xFF1A1220 hardcoded (the same literal zyra_colors.dart's
  // 2026-08-01 block calls out); now the ratified glass modal every other
  // centred surface uses. Copy unchanged.
  Future<void> _endJourney() async {
    final confirmed = await showZyraGlassChoice(
      context: context,
      icon: Icons.circle_outlined,
      title: 'End this Journey?',
      body: "This is a deliberate, final choice. If you want to hold without ending, "
          "use Pause instead. Restarting later means going through the full process again.",
      primaryLabel: 'End Journey',
      secondaryLabel: 'Cancel',
    );
    if (confirmed != true) return;
    await ZyraJourneyService.endJourney(widget.matchId);
    if (mounted) Navigator.of(context).pop();
  }

  // REWRITTEN 2026-08-11 (Founder, on the "Pause needs ZYRA One" dialog:
  // "in zyra basic you can also pause a journey its just how much you
  // pause is different with zyra basic and zyra one" — and, asked to
  // pick the canon explicitly: both plans pause, caps 5/10).
  //
  // This SUPERSEDES the 2026-07-28 "Pause & Premium Differentiation"
  // gate and the DR-ZYRA-121 Founder amendment ("Pause stays a ZYRA One
  // capability"), which had come into conflict with the newer
  // Founder-approved entitlements matrix (2026-08-09,
  // data/zyra_entitlements.dart): Basic holds 5 paused Journeys, ZYRA
  // One holds 10. The differentiator is the CAP, not the capability.
  //
  // No plan gate fronts the tap any more. suspend_journey (migration
  // 20260811232500) enforces the cap server-side — counted over pauses
  // the caller initiated — and this method just renders the refusal, so
  // there is no pre-fetch and no race with the server's own count. The
  // upgrade offer appears only where upgrading would actually raise the
  // number (Basic at 5); ZYRA One at 10 gets the honest ceiling instead.
  Future<void> _pauseJourney() async {
    try {
      await ZyraJourneyService.suspendJourney(widget.matchId);
      if (mounted) Navigator.of(context).pop();
    } on PausedLimitReachedException {
      if (!mounted) return;
      final limits = ZyraEntitlements.of(AppState.instance.plan);
      if (AppState.instance.plan == ZyraPlan.one) {
        await showZyraGlassDialog<void>(
          context: context,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_outline, color: Colors.white, size: 30),
              const SizedBox(height: 14),
              Text('Paused Journeys are full',
                  style: ZyraText.heading(size: 18), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'ZYRA One holds up to ${limits.paused} paused Journeys, and '
                "you're at the limit. Resume or end one of them to pause "
                'this one.',
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('OK', style: ZyraText.button(size: 13)),
                ),
              ),
            ],
          ),
        );
      } else {
        final upgrade = await showZyraGlassChoice(
          context: context,
          icon: Icons.pause_circle_outline,
          title: 'Paused Journeys are full',
          body: 'ZYRA Basic holds up to ${limits.paused} paused Journeys, '
              "and you're at the limit. Resume or end one first — or ZYRA "
              'One holds ${ZyraEntitlements.one.paused}.',
          primaryLabel: 'Upgrade to ZYRA One',
          secondaryLabel: 'Not now',
        );
        if (upgrade == true && mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
        }
      }
    } on SuspensionRequiresOneException {
      // Only reachable against a database that predates migration
      // 20260811232500 — degrade to the old refusal rather than crash.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journey Suspension requires ZYRA One.')));
    }
  }

  /// Whether to DRAW the developer stage jumper. Not a permission check —
  /// `zyra_dev_set_journey_stage` refuses server-side by reading
  /// `auth.users.email`, and would refuse this account even if this getter
  /// were changed to `true`. Contradiction-audit §3.1 is a full section on
  /// this project shipping client-side gates and believing them.
  bool get _isDevAccount =>
      (ZyraAuth.currentUser?.email ?? '').endsWith('@zyra.test');

  bool _jumping = false;

  /// The OTHER party's reveal flag, READ FROM THE SERVER rather than held as
  /// whatever the toggle last set. The two diverge the moment the other
  /// account reveals for real, and a debug toggle showing its own last write
  /// is a debug toggle that lies.
  bool _counterpartRevealed = false;

  /// DR-ZYRA-135. Whether this account holds a simulated Compatibility
  /// Unlock+ on the other Seeker. Read from the server, not held locally —
  /// the same reason as _counterpartRevealed: a switch that shows its own
  /// last write is a switch that lies.
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

  Future<void> _loadCounterpartReveal() async {
    if (!_isDevAccount) return;
    final v = await ZyraJourneyService.fetchCounterpartRevealed(widget.matchId);
    if (mounted) setState(() => _counterpartRevealed = v);
  }

  Future<void> _setCounterpartRevealed(bool value) async {
    if (_jumping) return;
    setState(() => _jumping = true);
    try {
      await ZyraJourneyService.devSetCounterpartReveal(widget.matchId, value);
      await _loadCounterpartReveal();
      await _refresh(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _jumping = false);
    }
  }

  /// DEV ONLY. Forces the reveal result so the mutual screen can be seen at
  /// both ends. Sets both flags, so it lands on the mutual state rather than
  /// the Plus-early one.
  Future<void> _forceCompatibility(double score) async {
    if (_jumping) return;
    setState(() => _jumping = true);
    try {
      await ZyraJourneyService.devSetCompatibility(widget.matchId, score);
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
    setState(() => _jumping = true);
    try {
      final ids = switch (_stage) {
        'phase_1' => JourneyQuestions.phase1.map((q) => q.id).toList(),
        'phase_2' => JourneyQuestions.phase2.map((q) => q.id).toList(),
        'phase_3' => JourneyQuestions.phase3.map((q) => q.id).toList(),
        'family_stage' => JourneyQuestions.seekerToWali.map((q) => q.id).toList(),
        _ => const <String>[],
      };
      final said = await ZyraJourneyService.devCounterpartComplete(
          widget.matchId, questionIds: ids);
      await _refresh(showSpinner: false);
      await _loadCounterpartReveal();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$said (dev)')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
      body: 'Puts you back at Compatibility Reveal and clears everything you '
          'both did — answers, ratings, Salams, the reveal, family answers, '
          'messages and Timeline milestones.\n\nThe match itself stays, and so '
          'does your Guardian link.',
      primaryLabel: 'Start again',
      secondaryLabel: 'Cancel',
    );
    if (ok != true || !mounted) return;

    setState(() => _jumping = true);
    try {
      final said = await ZyraJourneyService.devRewindJourney(matchId: widget.matchId);
      await _refresh(showSpinner: false);
      await _loadCounterpartReveal();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$said (dev)')));
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
      await ZyraJourneyService.devSetStage(widget.matchId, stage);
      // The server is the source of truth for where the Journey now is, so
      // re-read rather than assuming the jump landed where it was asked to.
      // A local setState here would show the requested stage even if the
      // server had quietly done something else — the exact shape of the
      // 2026-08-07 release blocker, where a no-op looked like a success.
      await _refresh(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _jumping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: Stack(
          children: [
            SafeArea(
              child: _loading
                  ? const ZyraLoading()
                  : _buildBody(context),
            ),
            // DEV ONLY — the right-edge pull-out, matching dev_scenario_panel.
            //
            // In the Stack rather than the Column so it floats over the stage
            // content the way the app's other developer panel floats over
            // HomeShell. Only on a live Journey: an ended or paused one has no
            // stages to move between, and the server would refuse anyway.
            //
            // The email test here decides only whether to DRAW it. The refusal
            // that matters is inside zyra_dev_set_journey_stage, which reads
            // auth.users and raises `dev_only`.
            if (_isDevAccount && _status == 'active' && _suspendedBy == null)
              _DevStageJumper(
                current: _stage,
                busy: _jumping,
                onJump: _jumpToStage,
                counterpartRevealed: _counterpartRevealed,
                onCounterpartRevealChanged: _setCounterpartRevealed,
                hasPlus: _hasPlus,
                onHasPlusChanged: _setPlusUnlock,
                onForceCompatibility: _forceCompatibility,
                onCounterpartComplete: _counterpartComplete,
                onRewind: _rewindJourney,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_status == 'ended') {
      return _EndedView(
        matchId: widget.matchId,
        profile: widget.profile,
        endedAt: _endedAt,
      );
    }

    if (_suspendedBy != null) {
      return _SuspendedView(
        profile: widget.profile,
        iInitiated: _suspendedBy == ZyraAuth.currentUser?.id,
        onResume: () async {
          try {
            await ZyraJourneyService.resumeJourney(widget.matchId);
            await _refresh();
          } on OtherPartyInActiveJourneyException {
            // OA-ZYRA-164. This used to be JourneyAutoEndedException and a
            // silent _refresh() — the Journey had already been ended by the
            // server, so the screen just quietly redrew as "ended" with no
            // explanation. Nothing is ended now, so there is something to
            // say and a state worth keeping.
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                "They're in another Journey right now, so this one stays "
                'paused. You can try again later.',
              ),
            ));
          }
        },
        onEnd: _endJourney,
      );
    }

    return Column(
      children: [
        _JourneyAppBar(profile: widget.profile, onPause: _pauseJourney, onEnd: _endJourney),
        Expanded(
          // #31 — a live Family Review Period takes over the stage area
          // regardless of which stage is "current", since journey_stage
          // deliberately hasn't moved yet while one is pending/paused.
          child: _review != null
              ? _FamilyReviewView(review: _review!, onEnd: _endJourney)
              : _buildStage(context),
        ),
      ],
    );
  }

  Widget _buildStage(BuildContext context) {
    switch (_stage) {
      case 'compatibility_reveal':
        return _CompatibilityRevealView(
          matchId: widget.matchId,
          profile: widget.profile,
          onContinue: () => _advance('compatibility_reveal'),
          onPause: _pauseJourney,
          onEnd: _endJourney,
          waitingReason: _advanceReason,
        );
      case 'salam_exchange':
        return _SalamExchangeView(
          matchId: widget.matchId,
          profile: widget.profile,
          onContinue: () => _advance('salam_exchange'),
        );
      case 'wali_gate':
        return _WaliGateView(
          otherFirstName: widget.profile.firstName,
          reason: _advanceReason,
          onChanged: () => _refresh(),
        );
      case 'phase_1':
        return _PhaseView(matchId: widget.matchId, profile: widget.profile, phase: 1, onAdvance: () => _advanceGated('phase_1', 'phase_2'), onEnd: _endJourney);
      case 'phase_2':
        return _PhaseView(matchId: widget.matchId, profile: widget.profile, phase: 2, onAdvance: () => _advanceGated('phase_2', 'phase_3'), onEnd: _endJourney);
      case 'phase_3':
        return _PhaseView(matchId: widget.matchId, profile: widget.profile, phase: 3, onAdvance: () => _advanceGated('phase_3', 'family_stage'), onEnd: _endJourney);
      case 'family_stage':
        return _FamilyStageView(matchId: widget.matchId, profile: widget.profile, onContinue: () => _advanceGated('family_stage', 'conversation'));
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
        return _OpenConversationView(matchId: widget.matchId, profile: widget.profile);
      default:
        return const ZyraLoading();
    }
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
/// 2026-08-01 — a 22pt tab, `0xF20E0B12`, chevron when open and a tune glyph
/// when closed, vertically centred. Two debug conventions in one app is one
/// too many, and the newer one is always the one that looks like a bug.
///
/// IT IS A SEPARATE TAB, NOT THE SAME ONE. JourneyFlowScreen is pushed above
/// HomeShell, so HomeShell's panel is covered by this route and cannot be
/// reached from here. They never appear together, so they cannot collide.
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
  final bool counterpartRevealed;
  final ValueChanged<bool> onCounterpartRevealChanged;
  final bool hasPlus;
  final ValueChanged<bool> onHasPlusChanged;
  final ValueChanged<double> onForceCompatibility;
  final VoidCallback onCounterpartComplete;
  final VoidCallback onRewind;

  const _DevStageJumper({
    required this.current,
    required this.busy,
    required this.onJump,
    required this.counterpartRevealed,
    required this.onCounterpartRevealChanged,
    required this.hasPlus,
    required this.onHasPlusChanged,
    required this.onForceCompatibility,
    required this.onCounterpartComplete,
    required this.onRewind,
  });

  @override
  State<_DevStageJumper> createState() => _DevStageJumperState();
}

class _DevStageJumperState extends State<_DevStageJumper> {
  bool _open = false;

  static const double _tabWidth = 22;
  static const double _panelWidth = 232;

  // The order the Journey actually runs in. `phase_1/2/3` are stored values
  // only — the member reads Faith & Values, Building a Life, Navigating Life,
  // and those words come from the map, not from here.
  static const _stages = <String>[
    'compatibility_reveal',
    'salam_exchange',
    'wali_gate',
    'phase_1',
    'phase_2',
    'phase_3',
    'family_stage',
    'conversation',
  ];

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return const SizedBox.shrink();

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
                  color: const Color(0xF20E0B12),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(8)),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16), width: 0.5),
                ),
                child: Center(
                  child: Icon(
                    _open ? Icons.chevron_right : Icons.tune,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: const Color(0xF20E0B12),
              child: SafeArea(
                left: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    // FIRST, because it is the control you reach for at every
                    // stage — and because it is the honest one. Everything
                    // below skips something; this waits for nothing.
                    Text('THE OTHER PERSON',
                        style: ZyraText.chapterLabel(color: Colors.white70)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            widget.busy ? null : widget.onCounterpartComplete,
                        child: Text('Do their half of this stage',
                            style: ZyraText.button(size: 12.5)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Their Salam, their answers, their Continue, their '
                      "Guardian's replies — whichever this stage is waiting on. "
                      'The Journey does not move; you still press your own '
                      'buttons.',
                      style: ZyraText.subtext(size: 10.5),
                    ),

                    const SizedBox(height: 14),
                    Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Text('SKIP TO STAGE',
                            style: ZyraText.chapterLabel(color: Colors.white70)),
                        const Spacer(),
                        if (widget.busy)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.6, color: Colors.white70),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._stages.map((s) {
                      final isCurrent = s == widget.current;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: isCurrent
                              ? Colors.white.withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: widget.busy || isCurrent
                                ? null
                                : () => widget.onJump(s),
                            child: Container(
                              height: 34,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                // THE CANONICAL MAP. Never a literal.
                                ZyraJourneyStages.labelFor(s),
                                style: ZyraText.subtext(
                                  size: 12,
                                  color: isCurrent
                                      ? Colors.white
                                      : const Color(0xB3FFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 18),
                    Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                    const SizedBox(height: 14),

                    // THE OTHER SIDE OF A TWO-SIDED GATE.
                    //
                    // Founder, 2026-08-10. Compatibility Reveal needs BOTH
                    // Seekers, so one person testing alone can only ever see
                    // the waiting half of it. This sets the counterpart's flag
                    // server-side and leaves the caller's own alone.
                    //
                    // It does NOT compute the score. That runs on the real
                    // reveal path — set this on, then press Reveal, and the
                    // real code executes. A dev control that also scored would
                    // be testing itself.
                    Text('OTHER SEEKER',
                        style: ZyraText.chapterLabel(color: Colors.white70)),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: widget.counterpartRevealed,
                      onChanged:
                          widget.busy ? null : widget.onCounterpartRevealChanged,
                      title: Text('Has revealed compatibility',
                          style: ZyraText.subtext(size: 12, color: Colors.white)),
                      subtitle: Text(
                        widget.counterpartRevealed
                            ? 'They have revealed. Your Reveal completes the gate.'
                            : "They haven't revealed. You will be left waiting.",
                        style: ZyraText.subtext(size: 10.5),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                    const SizedBox(height: 14),

                    // DR-ZYRA-135 / OA-ZYRA-152. Simulates having bought
                    // Compatibility Unlock+, which lets you see the score
                    // before the other Seeker reveals.
                    //
                    // Combined with the switch above, this reaches the state
                    // that could not exist before today: you see the number,
                    // she has not revealed, and she has not been told.
                    Text('THIS ACCOUNT',
                        style: ZyraText.chapterLabel(color: Colors.white70)),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: widget.hasPlus,
                      onChanged: widget.busy ? null : widget.onHasPlusChanged,
                      title: Text('Has paid for Compatibility Unlock+',
                          style: ZyraText.subtext(size: 12, color: Colors.white)),
                      subtitle: Text(
                        widget.hasPlus
                            ? 'You see the score early. They are told nothing.'
                            : 'Mutual reveal applies — neither sees it first.',
                        style: ZyraText.subtext(size: 10.5),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                    const SizedBox(height: 14),

                    // FORCE A RESULT. Founder, 2026-08-10: "you have good
                    // reveal and bad reveal — one is 21% and one is 92%."
                    //
                    // Not reachable by playing properly: every seeded profile
                    // scores 77-100 against every other, so the low end of
                    // this screen has never been seen. How a BAD result reads
                    // matters as much as a good one — arguably more.
                    //
                    // Sets both reveal flags, so it lands on the mutual screen
                    // rather than the Plus-early one. Press Reveal yourself if
                    // you want the real engine instead; it still works.
                    Text('FORCE A RESULT',
                        style: ZyraText.chapterLabel(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.busy ? null : () => widget.onForceCompatibility(21),
                            child: Text('Low · 21%',
                                style: ZyraText.subtext(size: 12, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.busy ? null : () => widget.onForceCompatibility(92),
                            child: Text('High · 92%',
                                style: ZyraText.subtext(size: 12, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                    const SizedBox(height: 14),

                    // LAST, and the only red thing here. Everything above is
                    // recoverable by carrying on; this is not. Tinted rather
                    // than hidden — the same treatment the account reset gets
                    // in dev_scenario_panel, so the two destructive controls
                    // in this app look alike.
                    Text('START OVER',
                        style: ZyraText.chapterLabel(color: Colors.white70)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.busy ? null : widget.onRewind,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: ZyraColors.destructiveBorder, width: 0.7),
                        ),
                        child: Text('Start this Journey again',
                            style: ZyraText.subtext(
                                size: 12, color: ZyraColors.destructive)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Back to Compatibility Reveal, with everything you both '
                      'did inside it cleared. The match and your Guardian link '
                      'stay. Asks first.',
                      style: ZyraText.subtext(size: 10.5),
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

// RESTYLED 2026-08-11 (Frost UI pass — Founder, screenshot review of this
// exact menu: "picture 3 isnt really matching the apps image with black
// text is it"). The PopupMenuButton painted Material's stock dark menu
// surface (plus the unratified 0xFF1A1220 override) — an opaque black box
// sitting on the gradient. Replaced with the app's own anchored-card
// idiom (anchored_card_overlay.dart — the Founder-ratified interaction
// already used by the notification bell and HomeShell's Help/Report
// card: same-screen, no route, dismissed by tapping anywhere else, no
// dim) wearing the ratified glass recipe (zyra_glass_dialog.dart values:
// blur σ30, white 14% fill, white 22% border).
//
// Stateful only for the GlobalKey — the overlay reads the icon's
// RenderBox through it at tap time, so it must survive rebuilds.
class _JourneyAppBar extends StatefulWidget {
  final SeekerProfile profile;
  final VoidCallback onPause;
  final VoidCallback onEnd;
  const _JourneyAppBar({required this.profile, required this.onPause, required this.onEnd});

  @override
  State<_JourneyAppBar> createState() => _JourneyAppBarState();
}

class _JourneyAppBarState extends State<_JourneyAppBar> {
  final GlobalKey _menuKey = GlobalKey();

  // VIEW PROFILE lives here, Founder decision 2026-08-10
  // (OA-ZYRA-194). Until now the full profile had exactly one
  // entry point — the bubble at the top of the Timeline — so
  // someone inside a Journey had to leave it to look at the person
  // the Journey is about. The menu was the Founder's pick over an
  // app-bar control: the Journey is a staged ritual and the stage
  // area should stay the only thing competing for attention.
  //
  // First in the list, and deliberately: it is the one harmless
  // item. Pause and End follow, End last because it is the only
  // one that cannot be undone. (Order preserved through the
  // 2026-08-11 restyle — only the surface changed.)
  void _openMenu() {
    showAnchoredCard(
      context: context,
      anchorKey: _menuKey,
      cardWidth: 200,
      // menuSurface, NOT glassFill — corrected same day it shipped
      // (Founder: "the top right isnt clear"). White glass needs the
      // dialog barrier's dimming behind it; an anchored menu has none and
      // sits over the gradient's palest region. See the menuSurface note
      // in zyra_colors.dart.
      cardBuilder: (ctx, close) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: ZyraColors.menuSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuRow('View profile', () {
                    close();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SeekerProfileScreen(profile: widget.profile),
                    ));
                  }),
                  _menuDivider(),
                  _menuRow('Pause Journey', () {
                    close();
                    widget.onPause();
                  }),
                  _menuDivider(),
                  _menuRow('End Journey', () {
                    close();
                    widget.onEnd();
                  }, color: ZyraColors.destructive),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuRow(String label, VoidCallback onTap, {Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: ZyraText.body(size: 14, color: color)),
        ),
      ),
    );
  }

  Widget _menuDivider() =>
      Divider(color: Colors.white.withValues(alpha: 0.12), height: 1, indent: 16, endIndent: 16);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
          ),
          Expanded(
            child: Text('Journey with ${widget.profile.firstName}', style: ZyraText.heading(size: 16), textAlign: TextAlign.center),
          ),
          IconButton(
            key: _menuKey,
            onPressed: _openMenu,
            icon: const Icon(Icons.more_vert, color: Colors.white70),
          ),
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
  final String matchId;
  final SeekerProfile profile;
  final DateTime? endedAt;
  const _EndedView({required this.matchId, required this.profile, required this.endedAt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle_outlined, color: Colors.white38, size: 32),
            const SizedBox(height: 14),
            Text('This Journey has ended', style: ZyraText.heading(size: 18), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your Timeline with ${profile.firstName} is preserved as historical record.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // RESTART RETIRED 2026-08-06 — OA-ZYRA-154, DR-ZYRA-121.
            //
            // This button called restart_journey(), which reopened an ended
            // Journey on ONE person's tap. It deleted six tables of history
            // first and cleared `ended_at`, so someone who ended a Journey
            // because they felt unsafe could be returned to it without
            // consent and without record. The server now refuses; leaving a
            // button that calls a refusing function would be worse than no
            // button, so the countdown and the action both go.
            //
            // Replaced by Request New Journey (V3 §9, OA-ZYRA-159): one
            // person asks, the other decides, with Accept / Decline /
            // Decline-and-don't-ask-again. Not built here because that flow
            // carries cooldowns, a 14-day expiry and a decline type the
            // requester must never see — an interim handshake would be
            // thrown away days later.
            //
            // The copy says starting again needs both people, which is now
            // true, rather than promising a feature that does not exist.
            Text(
              'Starting again is something you would both need to agree to. '
              "We'll add a way to ask ${profile.firstName} soon.",
              style: ZyraText.subtext(size: 12, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text('Back to Matches', style: ZyraText.button(size: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuspendedView extends StatelessWidget {
  final SeekerProfile profile;
  final bool iInitiated;
  final VoidCallback onResume;
  final VoidCallback onEnd;
  const _SuspendedView({required this.profile, required this.iInitiated, required this.onResume, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_outline, color: Colors.white54, size: 32),
            const SizedBox(height: 14),
            Text('Journey paused', style: ZyraText.heading(size: 18)),
            const SizedBox(height: 8),
            Text(
              iInitiated
                  ? 'You paused this Journey. Resume any time to pick up exactly where you left off.'
                  : '${profile.firstName} paused this Journey. You can wait for them to resume, or End it.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (iInitiated)
              FilledButton(onPressed: onResume, child: Text('Resume', style: ZyraText.button(size: 13))),
            const SizedBox(height: 8),
            TextButton(onPressed: onEnd, child: Text('End Journey', style: ZyraText.subtext(size: 13, color: ZyraColors.destructive))),
          ],
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
// permission gate" the Seekers themselves operate. End Journey remains
// available throughout, same as every other stage.
class _FamilyReviewView extends StatefulWidget {
  final ({String id, String status, String toStage, DateTime deadlineAt}) review;
  final VoidCallback onEnd;
  const _FamilyReviewView({required this.review, required this.onEnd});

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
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => mounted ? setState(() {}) : null);
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(paused ? Icons.pause_circle_outline : Icons.hourglass_top, color: Colors.white54, size: 32),
            const SizedBox(height: 14),
            Text(
              paused ? 'Paused for family review' : 'Family Review Period',
              style: ZyraText.heading(size: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              paused
                  ? "A Guardian has asked for more time before this Journey continues. This isn't a rejection — it means the family needs a little longer. ZYRA support is available to help if needed."
                  : "Both families have this stage to review. Unless a Guardian raises a concern, your Journey continues automatically in ${_formatRemaining(remaining)}.",
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: widget.onEnd, child: Text('End Journey', style: ZyraText.subtext(size: 12, color: ZyraColors.destructive))),
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
  final VoidCallback onContinue;
  final VoidCallback onPause;
  final VoidCallback onEnd;

  /// Server's reason the pair has not moved on yet. 'waiting_for_continue'
  /// means this user has pressed Continue and the other has not — the
  /// checkpoint is recorded, so it is safe to show a wait rather than the
  /// button. See PRE-JOURNEY RITUAL: "Every checkpoint is a shared decision."
  final String? waitingReason;

  const _CompatibilityRevealView({required this.matchId, required this.profile, required this.onContinue, required this.onPause, required this.onEnd, required this.waitingReason});

  @override
  State<_CompatibilityRevealView> createState() => _CompatibilityRevealViewState();
}

class _CompatibilityRevealViewState extends State<_CompatibilityRevealView> {
  bool _mine = false;
  bool _theirs = false;
  double? _score;
  Map<String, dynamic>? _categories;
  bool _loading = true;
  Timer? _poll;

  /// The score a Compatibility Unlock+ holder may see before the other Seeker
  /// reveals — DR-ZYRA-135, closing OA-ZYRA-152.
  ///
  /// Null for everyone without Plus, which is nearly everyone, and null is the
  /// ordinary case rather than a failure. The server refuses with
  /// `plus_required` and the service turns that into null quietly.
  double? _plusScore;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    var r = await ZyraJourneyService.fetchCompatibility(widget.matchId);

    // LAZY SCORING, the same pattern as resolveFamilyReviewIfDue().
    //
    // REASON RESTATED 2026-08-11 (OA-ZYRA-193 a2). The original was: whoever
    // revealed second computed the pair's single score, so if they revealed
    // from a path that did not score, both flags ended up true with no number.
    // That sequencing is gone — each side computes its own on its own reveal.
    //
    // The retry is still needed, for a narrower reason: MY reveal can set my
    // flag and still fail to produce a figure (a transient RPC failure). The
    // screen would then find mine && theirs && score == null, match none of
    // its branches, and fall through to the "Reveal" prompt — offering to
    // reveal something already revealed.
    //
    // FOUND WHILE BUILDING THE DEV COUNTERPART TOGGLE, which produces exactly
    // that state on purpose. But it is NOT a dev-only bug: the same hole is
    // reachable in production the moment the second reveal happens anywhere
    // the client is not watching. Fixed here rather than in the dev function,
    // because a dev tool that quietly patched over a real gap would have
    // hidden it.
    //
    // Calling revealCompatibility again is safe and is the point: it sets an
    // already-true flag, then runs the REAL scoring path. No second code path
    // computes a score.
    if (r.mine && r.theirs && r.overallScore == null) {
      await ZyraJourneyService.revealCompatibility(widget.matchId, widget.profile.id);
      r = await ZyraJourneyService.fetchCompatibility(widget.matchId);
    }

    // DR-ZYRA-135. Only asked in the one state where it changes anything:
    // this Seeker has revealed and the other has not. Asking earlier would
    // show the number before they chose to look at it, which is the opposite
    // of what a Reveal is; asking later is pointless, since both revealing
    // shows it anyway.
    //
    // Returns null for everyone without Plus — the ordinary case, refused
    // server-side, not inferred here.
    double? plus;
    if (r.mine && !r.theirs) {
      plus = await ZyraJourneyService.fetchCompatibilityForPlus(widget.matchId);
    }

    if (!mounted) return;
    setState(() {
      _plusScore = plus;
      _mine = r.mine;
      _theirs = r.theirs;
      _score = r.overallScore;
      _categories = r.categoryScores;
      _loading = false;
    });
  }

  Future<void> _reveal() async {
    setState(() => _loading = true);
    await ZyraJourneyService.revealCompatibility(widget.matchId, widget.profile.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ZyraLoading();

    // REVEALED, BUT NOT SCOREABLE. Distinct from the retry above, which
    // covers a figure that failed to compute: this is a figure that cannot
    // exist yet, because there is not enough between the two of them to score.
    // Reachable until the onboarding completeness gate (OA-ZYRA-193c) is
    // built, and worth keeping afterwards — the alternative is inventing a
    // number the moment the honest branch is deleted.
    if (_mine && _theirs && _score == null && !_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You both chose to reveal.', style: ZyraText.subtext()),
              const SizedBox(height: 10),
              Text('—', style: ZyraText.heading(size: 44, color: Colors.white38)),
              const SizedBox(height: 10),
              Text(
                'There is not enough between you yet to work out a figure. '
                'It appears here once you have both covered more ground.',
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (widget.waitingReason != 'waiting_for_continue')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: widget.onContinue,
                      child: Text('Continue Journey', style: ZyraText.button(size: 14))),
                ),
              _JourneyStageActions(onPause: widget.onPause, onEnd: widget.onEnd),
            ],
          ),
        ),
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
        categories: _categories,
        otherName: widget.profile.firstName,
      );
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You both chose to reveal.', style: ZyraText.subtext()),
            const SizedBox(height: 8),
            Text('${_score!.round()}%', style: ZyraText.heading(size: 44)),
            Text('Overall Compatibility', style: ZyraText.subtext()),
            const SizedBox(height: 20),
            if (_categories != null)
              ..._categories!.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: ZyraText.body(size: 13)),
                        Text('${(e.value as num).round()}%', style: ZyraText.body(size: 13)),
                      ],
                    ),
                  )),
            // ZYRA One reads the number back; ZYRA Basic sees the number and
            // an invitation, and the screen is complete either way.
            if (intelligence != null)
              ZyraIntelligenceCard(intelligence: intelligence)
            else
              const ZyraIntelligenceInvitation(kind: ZyraIntelligenceKind.insight),
            const SizedBox(height: 20),
            if (widget.waitingReason == 'waiting_for_continue') ...[
              const ZyraLoading(),
              const SizedBox(height: 12),
              Text(
                "You've chosen to continue. Waiting for ${widget.profile.firstName}.",
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: widget.onContinue, child: Text('Continue Journey', style: ZyraText.button(size: 14))),
              ),
            _JourneyStageActions(onPause: widget.onPause, onEnd: widget.onEnd),
          ],
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
              Text('${_plusScore!.round()}%', style: ZyraText.heading(size: 44)),
              Text('Overall Compatibility', style: ZyraText.subtext()),
              const SizedBox(height: 20),
              // Said plainly, because it is the thing they paid for and the
              // thing that could otherwise feel like a glitch: you can see it,
              // they cannot.
              Text('You unlocked this early.',
                  style: ZyraText.body(size: 13), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                "${widget.profile.firstName} hasn't revealed yet, and hasn't "
                'been told you have. The Journey moves when she does.',
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Pause and End only. Continue stays absent by design — see the
              // note above: buying the number does not buy the stage.
              _JourneyStageActions(onPause: widget.onPause, onEnd: widget.onEnd),
            ],
          ),
        ),
      );
    }

    if (_mine && !_theirs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZyraLoading(),
              const SizedBox(height: 16),
              Text('Waiting for ${widget.profile.firstName}', style: ZyraText.heading(size: 16)),
              const SizedBox(height: 6),
              Text('Neither of you sees the result until you both choose to reveal.', style: ZyraText.subtext(), textAlign: TextAlign.center),
              // No Continue — there is nothing yet to continue to. Pause and
              // End are Journey-level and stay available at every stage.
              _JourneyStageActions(onPause: widget.onPause, onEnd: widget.onEnd),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Every stage heading on this screen now reads from the one
            // map (data/zyra_journey_stages.dart) rather than carrying its
            // own literal. These four happened to agree with it already;
            // the phase heading below did not, and that is exactly why
            // agreement should not be left to whoever edits next.
            Text(ZyraJourneyStages.labelFor('compatibility_reveal'), style: ZyraText.heading(size: 20)),
            const SizedBox(height: 8),
            Text(
              "Neither of you sees the result until you both choose to reveal.",
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _reveal, child: Text('Reveal Compatibility', style: ZyraText.button(size: 14))),
            _JourneyStageActions(onPause: widget.onPause, onEnd: widget.onEnd),
          ],
        ),
      ),
    );
  }
}

/// Pause and End, at the foot of a stage.
///
/// Founder, 2026-08-10: "it's like a journey so it's gotta be at bottom
/// continue or end or pause journey."
///
/// CONTINUE IS NOT HERE, deliberately. Continue is a STAGE action — it means
/// something different on every stage and is only offered where the Journey
/// can actually advance, so each state renders its own. Pause and End are
/// JOURNEY actions: true at every stage, identical everywhere, and until now
/// reachable only from the 3-dot menu. A member deciding to stop should not
/// have to find a menu to do it.
// RESTYLE ONLY 2026-08-11 (Frost UI pass): the Founder's screenshot note
// on these ("just sitting there in small text") read as discomfort with
// the presentation, and the Frost brief's mockup went further and moved
// them into the 3-dot menu alone. DELIBERATELY NOT DONE HERE: the
// 2026-08-10 decision above ("gotta be at bottom… a member deciding to
// stop should not have to find a menu to do it") is one day old and is
// about reachability, not looks — and easy exit is worth protecting in
// this app. So they stay, quieter: more air above them so they stop
// crowding the stage's own button, slightly dimmer, End in the
// tokenised coral. If the Founder confirms menu-only, delete the
// _JourneyStageActions call sites — one line each.
class _JourneyStageActions extends StatelessWidget {
  final VoidCallback onPause;
  final VoidCallback onEnd;
  const _JourneyStageActions({required this.onPause, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onPause,
            child: Text('Pause Journey',
                style: ZyraText.subtext(size: 12, color: Colors.white60)),
          ),
          Text('·', style: ZyraText.subtext(size: 12, color: Colors.white38)),
          TextButton(
            onPressed: onEnd,
            child: Text('End Journey',
                style: ZyraText.subtext(size: 12, color: ZyraColors.destructive)),
          ),
        ],
      ),
    );
  }
}

// --- Salam Exchange ------------------------------------------------------

class _SalamExchangeView extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  final VoidCallback onContinue;
  const _SalamExchangeView({required this.matchId, required this.profile, required this.onContinue});

  @override
  State<_SalamExchangeView> createState() => _SalamExchangeViewState();
}

class _SalamExchangeViewState extends State<_SalamExchangeView> {
  bool _mine = false;
  bool _theirs = false;
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await ZyraJourneyService.fetchSalamStatus(widget.matchId, widget.profile.id);
    if (!mounted) return;
    setState(() {
      _mine = r.mine;
      _theirs = r.theirs;
      _loading = false;
    });
    if (_mine && _theirs) widget.onContinue();
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    await ZyraJourneyService.sendSalam(widget.matchId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ZyraLoading();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ZyraJourneyStages.labelFor('salam_exchange'), style: ZyraText.heading(size: 20)),
            const SizedBox(height: 10),
            Text(
              _mine
                  ? "You've sent your Salam. Waiting for ${widget.profile.firstName}."
                  : "Send your Salam to ${widget.profile.firstName} to begin your journey.",
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_mine)
              const ZyraLoading()
            else
              FilledButton(onPressed: _send, child: Text('Send Salam', style: ZyraText.button(size: 14))),
          ],
        ),
      ),
    );
  }
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
/// only renders which of the two is outstanding. It performs no reads and
/// holds no state — the parent's poll drives it.
class _WaliGateView extends StatelessWidget {
  final String otherFirstName;

  /// From zyra_advance_stage(): 'guardian_required_self' — you must link
  /// one; 'guardian_required_other' — they must. Null while the parent's
  /// first attempt is in flight.
  final String? reason;

  /// Ask the parent to re-poll after the user has linked someone, rather
  /// than waiting up to three seconds for the timer.
  final VoidCallback onChanged;

  const _WaliGateView({required this.otherFirstName, required this.reason, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (reason == 'guardian_required_other') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZyraLoading(),
              const SizedBox(height: 16),
              Text(ZyraJourneyStages.labelFor('wali_gate'), style: ZyraText.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'Your Guardian is linked. Waiting for $otherFirstName to link theirs.',
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (reason != 'guardian_required_self') {
      // Null (first attempt in flight) or a reason this screen does not
      // own. A spinner is the honest render — never a Continue button
      // whose gate state is unknown.
      return const ZyraLoading();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ZyraJourneyStages.labelFor('wali_gate'), style: ZyraText.heading(size: 20)),
            const SizedBox(height: 10),
            Text('To begin your journey, you need to link a Guardian.', style: ZyraText.subtext(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LinkWaliScreen(asWali: false)));
                onChanged();
              },
              child: Text('Link a Guardian', style: ZyraText.button(size: 14)),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onChanged, child: Text("I've linked my Guardian — check again", style: ZyraText.subtext(size: 12))),
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
  final VoidCallback onAdvance;
  final VoidCallback onEnd;
  const _PhaseView({required this.matchId, required this.profile, required this.phase, required this.onAdvance, required this.onEnd});

  @override
  State<_PhaseView> createState() => _PhaseViewState();
}

class _PhaseViewState extends State<_PhaseView> {
  late final List<JourneyQuestion> _questions = JourneyQuestions.forPhase(widget.phase);
  final Map<String, TextEditingController> _controllers = {};
  Map<String, Map<String, String>> _allAnswers = {};
  Map<String, String> _checkpoints = {};

  /// This Seeker's OWN private ratings, questionId -> rating. Read from the
  /// server on load and kept in step locally as they tap, because from
  /// 2026-08-11 they are no longer write-only: they select the chip, they
  /// drive the ZYRA Recommendation under it, and on ZYRA One they decide
  /// which follow-ups are offered. A rating that vanished on rebuild used to
  /// be invisible; now it would look broken.
  Map<String, String> _ratings = {};
  bool _submitted = false;
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    for (final q in _questions) {
      _controllers[q.id] = TextEditingController();
    }
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load(showSpinner: false));
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
    if (showSpinner && mounted) setState(() => _loading = true);
    final answers = await ZyraJourneyService.fetchPhaseAnswers(widget.matchId, widget.phase);
    final checkpoints = await ZyraJourneyService.fetchCheckpoints(widget.matchId, widget.phase);
    final ratings = await ZyraJourneyService.fetchMyRatings(widget.matchId, widget.phase);
    if (!mounted) return;
    final myId = ZyraAuth.currentUser?.id;
    setState(() {
      _allAnswers = answers;
      _checkpoints = checkpoints;
      _ratings = ratings;
      _submitted = myId != null && (answers[myId]?.length ?? 0) >= _questions.length;
      _loading = false;
    });

    if (_bothSubmitted && myId != null && checkpoints[myId] != null && checkpoints.length >= 2) {
      widget.onAdvance();
    }
  }

  bool get _bothSubmitted {
    if (_questions.isEmpty) return false;
    return _allAnswers.values.where((a) => a.length >= _questions.length).length >= 2;
  }

  // ── THE ZYRA LAYER. Null on ZYRA Basic, always — see
  // data/zyra_journey_intelligence.dart. Getters rather than fields so they
  // recompute the moment a rating chip is tapped, which is the whole point:
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
    for (final q in _questions) {
      final text = _controllers[q.id]!.text.trim();
      if (text.isNotEmpty) {
        await ZyraJourneyService.submitPhaseAnswer(widget.matchId, widget.phase, q.id, text);
      }
    }
    await _load();
  }

  Future<void> _rate(String questionId, String rating) async {
    // Optimistic, then written. The chip has to select instantly — this is a
    // private note to yourself, and waiting on a round-trip to see it land
    // reads as the tap having missed.
    setState(() => _ratings[questionId] = rating);
    await ZyraJourneyService.submitRating(widget.matchId, widget.phase, questionId, rating);
  }

  Future<void> _checkpoint(String decision) async {
    await ZyraJourneyService.submitCheckpoint(widget.matchId, widget.phase, decision);
    if (decision == 'end') {
      widget.onEnd();
    } else {
      await _load();
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
    final myAnswers = myId == null ? const <String, String>{} : (_allAnswers[myId] ?? const {});
    final theirAnswers = _allAnswers[otherId] ?? const {};

    if (_bothSubmitted) {
      final myCheckpoint = myId == null ? null : _checkpoints[myId];
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A sixth stage-label site, missed in this morning's sweep and
            // found on 2026-08-09 while reading _checkpoint. Same rule:
            // the label comes from the map, never from a literal here.
            Text(
              '${ZyraJourneyStages.phase(widget.phase)?.label ?? 'Phase ${widget.phase}'} — Revealed',
              style: ZyraText.heading(size: 18),
            ),
            const SizedBox(height: 16),
            for (final q in _questions) ...[
              Text(q.text, style: ZyraText.body(size: 13, color: Colors.white70)),
              const SizedBox(height: 6),
              Text('You: ${myAnswers[q.id] ?? '—'}', style: ZyraText.body(size: 14)),
              const SizedBox(height: 4),
              Text('${widget.profile.firstName}: ${theirAnswers[q.id] ?? '—'}', style: ZyraText.body(size: 14)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RatingChip(
                      label: 'Reassured me',
                      selected: _ratings[q.id] == 'reassured',
                      onTap: () => _rate(q.id, 'reassured')),
                  _RatingChip(
                      label: "I'd like to discuss further",
                      selected: _ratings[q.id] == 'discuss_further',
                      onTap: () => _rate(q.id, 'discuss_further')),
                  _RatingChip(
                      label: 'This concerns me',
                      selected: _ratings[q.id] == 'concerns',
                      onTap: () => _rate(q.id, 'concerns')),
                ],
              ),
              const SizedBox(height: 18),
            ],
            // The privacy line the spec asks for on every phase. It sits
            // directly under the ratings it is about, not in a footer.
            Text(
              'Your answers are shared with ${widget.profile.firstName} and '
              'your Guardian. Your ratings are private and used only to guide '
              'your journey.',
              style: ZyraText.privacyText(),
            ),
            const SizedBox(height: 8),
            if (_summary != null) ZyraIntelligenceCard(intelligence: _summary!),
            if (_followUps != null) ZyraIntelligenceCard(intelligence: _followUps!),
            if (_checkpointAdvice != null)
              ZyraIntelligenceCard(intelligence: _checkpointAdvice!)
            else if (AppState.instance.plan != ZyraPlan.one)
              const ZyraIntelligenceInvitation(
                  kind: ZyraIntelligenceKind.recommendation),
            if (myCheckpoint == null) ...[
              Text('Ready to continue?', style: ZyraText.heading(size: 15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: FilledButton(onPressed: () => _checkpoint('continue'), child: Text('Continue', style: ZyraText.button(size: 13)))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _checkpoint('end'),
                      child: Text('End Journey', style: ZyraText.button(size: 13, color: ZyraColors.destructive)),
                    ),
                  ),
                ],
              ),
            ] else
              Center(child: Text('Waiting for ${widget.profile.firstName} to continue…', style: ZyraText.subtext())),
          ],
        ),
      );
    }

    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZyraLoading(),
              const SizedBox(height: 16),
              Text('Waiting for ${widget.profile.firstName}\'s answers', style: ZyraText.heading(size: 16), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('${widget.profile.firstName} will see your answers once they share theirs.', style: ZyraText.subtext(), textAlign: TextAlign.center),
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
          // WAS 'Phase 1' / 'Phase 2' / 'Phase 3'. Those are internal
          // engineering names and should never have been on screen
          // (Founder, 2026-08-09) — the Seeker now reads Faith & Values,
          // Building a Life, Navigating Life, which is what the Guardian
          // side reads too. `phase_N` remains the stored value and the
          // widget's own parameter; only the label changed.
          Text(
            ZyraJourneyStages.phase(widget.phase)?.label ?? 'Phase ${widget.phase}',
            style: ZyraText.heading(size: 18),
          ),
          const SizedBox(height: 4),
          Text(ZyraJourneyStages.phase(widget.phase)?.guidingQuestion ?? '', style: ZyraText.subtext()),
          const SizedBox(height: 18),
          for (final q in _questions) ...[
            Text(q.text, style: ZyraText.body(size: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _controllers[q.id],
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                hintText: 'Your answer…',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submitAll, child: Text('Submit Answers', style: ZyraText.button(size: 14))),
          ),
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  /// ADDED 2026-08-11. The chips were fire-and-forget: three identical
  /// buttons, no state, nothing to show which one you picked or that the tap
  /// registered at all. They are now the input to the ZYRA Recommendation
  /// below them, so they have to look like a choice that was made.
  final bool selected;

  const _RatingChip({required this.label, required this.onTap, this.selected = false});

  // RESTYLED 2026-08-11 (Frost UI pass — Founder, screenshot review of
  // this exact row: "the black doesnt match the app again"). ActionChip
  // rendered Material 3's stock dark chip surface underneath the white-8%
  // tint, which is why these sat on the gradient as black pills. Now a
  // plain frost pill in the Connections segmented control's own sampled
  // values, with the selected state filling in the brand lavender —
  // "look like a choice that was made" (the reason `selected` exists,
  // above) now reads at a glance instead of as a faint border.
  //
  // All three ratings stay visually equal when unselected — deliberately
  // no coral on "This concerns me": it is honesty, not danger, and
  // colouring it as destructive would tax choosing it.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? ZyraColors.primaryAction : ZyraColors.frostFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : ZyraColors.frostBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: selected
              ? ZyraText.button(size: 11.5, color: ZyraColors.onPrimaryAction)
              : ZyraText.option(size: 11.5, color: Colors.white.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}

// --- Family Compatibility Stage ---------------------------------------

class _FamilyStageView extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  final VoidCallback onContinue;
  const _FamilyStageView({required this.matchId, required this.profile, required this.onContinue});

  @override
  State<_FamilyStageView> createState() => _FamilyStageViewState();
}

class _FamilyStageViewState extends State<_FamilyStageView> {
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _submitted = false;
  bool _waliAnswered = false;
  Timer? _poll;

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
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(showSpinner: false));
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
    if (showSpinner && mounted) setState(() => _loading = true);
    final myAnswers = await ZyraJourneyService.fetchFamilyAnswers(widget.matchId, 'wali_to_seeker');
    final waliAnswers = await ZyraJourneyService.fetchFamilyAnswers(widget.matchId, 'seeker_to_wali');
    final ratings = await ZyraJourneyService.fetchAllMyRatings(widget.matchId);
    if (!mounted) return;
    final submitted = myAnswers.length >= JourneyQuestions.waliToSeeker.length;
    final waliAnswered = waliAnswers.length >= JourneyQuestions.seekerToWali.length;
    setState(() {
      _submitted = submitted;
      _waliAnswered = waliAnswered;
      _ratings = ratings;
      _loading = false;
    });
    // FIXED 2026-07-26 (Founder decision): Family Stage now requires
    // BOTH the Seeker's waliToSeeker answers AND the linked Guardian's
    // seekerToWali answers (see screens/wali/wali_journey_detail_
    // screen.dart) before advancing to Conversation — mirrors Phase
    // 1/2/3's both-sides pattern, making the Guardian's participation real
    // rather than cosmetic. Previously advanced as soon as the Seeker
    // submitted, regardless of the Guardian.
    if (submitted && waliAnswered) widget.onContinue();
  }

  Future<void> _submit() async {
    for (final q in JourneyQuestions.waliToSeeker) {
      final text = _controllers[q.id]!.text.trim();
      if (text.isNotEmpty) {
        await ZyraJourneyService.submitFamilyAnswer(widget.matchId, 'wali_to_seeker', q.id, text);
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ZyraLoading();

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
              const ZyraLoading(),
              const SizedBox(height: 16),
              Text(
                _waliAnswered ? 'Families have been introduced.' : "Waiting on your Guardian",
                style: ZyraText.heading(size: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _waliAnswered
                    ? 'Both sides have answered — continuing to Conversation.'
                    : "You've answered your Guardian's questions. Your Journey continues once your linked Guardian has answered theirs.",
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              if (guardianSummary != null)
                ZyraIntelligenceCard(intelligence: guardianSummary)
              else
                const ZyraIntelligenceInvitation(kind: ZyraIntelligenceKind.summary),
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
          Text(ZyraJourneyStages.labelFor('family_stage'), style: ZyraText.heading(size: 18)),
          const SizedBox(height: 6),
          Text('Involve guardians and families.', style: ZyraText.subtext()),
          const SizedBox(height: 18),
          Text('Questions your Guardian might ask you:', style: ZyraText.body(size: 13, color: Colors.white70)),
          const SizedBox(height: 10),
          for (final q in JourneyQuestions.waliToSeeker) ...[
            Text(q.text, style: ZyraText.body(size: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _controllers[q.id],
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                hintText: 'Your answer…',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: Text('Submit', style: ZyraText.button(size: 14))),
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ZyraJourneyStages.labelFor('conversation'),
              style: ZyraText.heading(size: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'You have been through every stage together. From here you can '
              'speak freely — the structure lifts, it does not end. Your '
              'Timeline keeps going, and your Guardian stays part of it.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            if (_topics != null)
              ZyraIntelligenceCard(intelligence: _topics!)
            else if (AppState.instance.plan != ZyraPlan.one)
              const ZyraIntelligenceInvitation(
                  kind: ZyraIntelligenceKind.recommendation),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatScreen(withProfile: widget.profile))),
              child: Text('Open your conversation with $name',
                  style: ZyraText.button(size: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
