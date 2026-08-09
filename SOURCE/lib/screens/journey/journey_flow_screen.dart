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
import 'package:flutter/material.dart';
import '../../data/journey_questions.dart';
import '../../data/zyra_journey_stages.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_journey_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../chat/chat_screen.dart';
import '../subscription/upgrade_screen.dart';
import '../wali/link_wali_screen.dart';
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

    // wali_gate is the one stage with no remaining user action on this
    // screen: it opens the moment BOTH Seekers hold an active Main
    // Guardian (Founder-decided 2026-08-08 — previously the client
    // checked only the acting Seeker's own Guardian and advanced the
    // SHARED stage, so one party dragged the pair through a gate the
    // other never saw). Retried here on the poll for the same reason
    // resolveFamilyReviewIfDue is above it: whoever linked first would
    // otherwise sit on the gate screen indefinitely after the other
    // party linked theirs.
    if (fresh != null && fresh.status == 'active' && fresh.journeyStage == 'wali_gate') {
      final r = await ZyraJourneyService.advanceStage(widget.matchId, 'wali_gate');
      _advanceReason = r.advanced ? null : r.reason;
      if (r.advanced) {
        fresh = await ZyraJourneyService.refetchOne(widget.matchId, widget.profile.id);
      }
    }

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

  Future<void> _endJourney() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('End this Journey?', style: ZyraText.heading(size: 16)),
        content: Text(
          "This is a deliberate, final choice. If you want to hold without ending, "
          "use Pause instead. Restarting later means going through the full process again.",
          style: ZyraText.subtext(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: ZyraText.subtext(size: 13))),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('End Journey', style: ZyraText.button(size: 13)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ZyraJourneyService.endJourney(widget.matchId);
    if (mounted) Navigator.of(context).pop();
  }

  // UPDATED 2026-07-28 (Founder, "Journey Pause & Premium
  // Differentiation" discussion): the menu item itself was already
  // visible to every plan (see _JourneyAppBar below — no plan check
  // around its PopupMenuButton items) and this gate already existed —
  // only the explanation was thin ("Journey Suspension is a ZYRA One
  // feature.", one dismiss button, one "See ZYRA One" button). Founder
  // asked specifically for the dialog to explain what Pause actually
  // does (pause without ending permanently, resumable later), not just
  // that it's gated, plus named button copy ("Upgrade to ZYRA One" /
  // "Maybe Later"). Body text reuses _SuspendedView's own established
  // phrase ("pick up exactly where you left off") below for wording
  // consistency within this same file rather than inventing new copy
  // for the same idea.
  Future<void> _pauseJourney() async {
    if (AppState.instance.plan != ZyraPlan.one) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Pause needs ZYRA One', style: ZyraText.heading(size: 16)),
          content: Text(
            'ZYRA One lets you pause a Journey without ending it permanently, '
            'and resume any time — picking up exactly where you left off.',
            style: ZyraText.subtext(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Maybe Later', style: ZyraText.subtext(size: 13))),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
              },
              child: Text('Upgrade to ZYRA One', style: ZyraText.button(size: 13)),
            ),
          ],
        ),
      );
      return;
    }
    try {
      await ZyraJourneyService.suspendJourney(widget.matchId);
      if (mounted) Navigator.of(context).pop();
    } on SuspensionRequiresOneException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journey Suspension requires ZYRA One.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: _loading
              ? const ZyraLoading()
              : _buildBody(context),
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen(withProfile: widget.profile)));
        });
        return const ZyraLoading();
      default:
        return const ZyraLoading();
    }
  }
}

class _JourneyAppBar extends StatelessWidget {
  final SeekerProfile profile;
  final VoidCallback onPause;
  final VoidCallback onEnd;
  const _JourneyAppBar({required this.profile, required this.onPause, required this.onEnd});

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
            child: Text('Journey with ${profile.firstName}', style: ZyraText.heading(size: 16), textAlign: TextAlign.center),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF1A1220),
            onSelected: (v) => v == 'pause' ? onPause() : onEnd(),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'pause', child: Text('Pause Journey', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'end', child: Text('End Journey', style: TextStyle(color: Color(0xFFE08080)))),
            ],
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
            TextButton(onPressed: onEnd, child: Text('End Journey', style: ZyraText.subtext(size: 13, color: const Color(0xFFE08080)))),
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
            TextButton(onPressed: widget.onEnd, child: Text('End Journey', style: ZyraText.subtext(size: 12, color: const Color(0xFFE08080)))),
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
  final VoidCallback onEnd;

  /// Server's reason the pair has not moved on yet. 'waiting_for_continue'
  /// means this user has pressed Continue and the other has not — the
  /// checkpoint is recorded, so it is safe to show a wait rather than the
  /// button. See PRE-JOURNEY RITUAL: "Every checkpoint is a shared decision."
  final String? waitingReason;

  const _CompatibilityRevealView({required this.matchId, required this.profile, required this.onContinue, required this.onEnd, required this.waitingReason});

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
    final r = await ZyraJourneyService.fetchCompatibility(widget.matchId);
    if (!mounted) return;
    setState(() {
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

    if (_mine && _theirs && _score != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
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
            const SizedBox(height: 28),
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
            const SizedBox(height: 10),
            TextButton(onPressed: widget.onEnd, child: Text('End Journey', style: ZyraText.subtext(size: 12, color: const Color(0xFFE08080)))),
          ],
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
          ],
        ),
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
    if (!mounted) return;
    final myId = ZyraAuth.currentUser?.id;
    setState(() {
      _allAnswers = answers;
      _checkpoints = checkpoints;
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

  Future<void> _submitAll() async {
    for (final q in _questions) {
      final text = _controllers[q.id]!.text.trim();
      if (text.isNotEmpty) {
        await ZyraJourneyService.submitPhaseAnswer(widget.matchId, widget.phase, q.id, text);
      }
    }
    await _load();
  }

  Future<void> _rate(String questionId, String rating) => ZyraJourneyService.submitRating(widget.matchId, widget.phase, questionId, rating);

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
                children: [
                  _RatingChip(label: 'Reassured me', onTap: () => _rate(q.id, 'reassured')),
                  _RatingChip(label: "I'd like to discuss further", onTap: () => _rate(q.id, 'discuss_further')),
                  _RatingChip(label: 'This concerns me', onTap: () => _rate(q.id, 'concerns')),
                ],
              ),
              const SizedBox(height: 18),
            ],
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
                      child: Text('End Journey', style: ZyraText.button(size: 13, color: const Color(0xFFE08080))),
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
  const _RatingChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      onPressed: onTap,
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
    if (!mounted) return;
    final submitted = myAnswers.length >= JourneyQuestions.waliToSeeker.length;
    final waliAnswered = waliAnswers.length >= JourneyQuestions.seekerToWali.length;
    setState(() {
      _submitted = submitted;
      _waliAnswered = waliAnswered;
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
