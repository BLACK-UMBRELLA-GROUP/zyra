// Pre-Journey Ritual host screen — APP/Journey/PRE-JOURNEY RITUAL/
// Summary.md. Routes an Active Journey through its real stages
// (matches.journey_stage): Compatibility Reveal -> Salam Exchange ->
// Wali Gate -> Phase 1/2/3 -> Family Stage -> Conversation. Reached
// from the Connections tab (screens/connections/connections_screen.dart,
// formerly MatchesScreen — renamed 2026-07-26 nav bar fix) after
// ZyraJourneyService.promoteToActive().
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
// - Family Compatibility Stage covers Seeker<->Wali directions only —
//   Wali<->Wali is explicitly marked TBC in the source spec. There is
//   no Wali-side screen to answer "seeker_to_wali" questions yet
//   (Wali app has no Journey visibility built at all — see
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
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_journey_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../chat/chat_screen.dart';
import '../subscription/upgrade_screen.dart';
import '../wali/link_wali_screen.dart';

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
  bool _loading = true;
  Timer? _poll;

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
    final fresh = await ZyraJourneyService.refetchOne(widget.matchId, widget.profile.id);
    if (!mounted) return;
    if (fresh != null) {
      setState(() {
        _status = fresh.status;
        _stage = fresh.journeyStage;
        _suspendedBy = fresh.suspendedBy;
        _loading = false;
      });
    } else if (showSpinner) {
      setState(() => _loading = false);
    }
  }

  Future<void> _advance(String nextStage) async {
    await ZyraJourneyService.advanceStage(widget.matchId, nextStage);
    await _refresh();
  }

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

  Future<void> _pauseJourney() async {
    if (AppState.instance.plan != ZyraPlan.one) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Pause needs ZYRA One', style: ZyraText.heading(size: 16)),
          content: Text('Journey Suspension is a ZYRA One feature.', style: ZyraText.subtext()),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Not now', style: ZyraText.subtext(size: 13))),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
              },
              child: Text('See ZYRA One', style: ZyraText.button(size: 13)),
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
              ? const Center(child: CircularProgressIndicator(color: Colors.white54))
              : _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_status == 'ended') return _EndedView(profile: widget.profile);

    if (_suspendedBy != null) {
      return _SuspendedView(
        profile: widget.profile,
        iInitiated: _suspendedBy == ZyraAuth.currentUser?.id,
        onResume: () async {
          try {
            await ZyraJourneyService.resumeJourney(widget.matchId);
            await _refresh();
          } on JourneyAutoEndedException {
            await _refresh();
          }
        },
        onEnd: _endJourney,
      );
    }

    return Column(
      children: [
        _JourneyAppBar(profile: widget.profile, onPause: _pauseJourney, onEnd: _endJourney),
        Expanded(child: _buildStage(context)),
      ],
    );
  }

  Widget _buildStage(BuildContext context) {
    switch (_stage) {
      case 'compatibility_reveal':
        return _CompatibilityRevealView(
          matchId: widget.matchId,
          profile: widget.profile,
          onContinue: () => _advance('salam_exchange'),
          onEnd: _endJourney,
        );
      case 'salam_exchange':
        return _SalamExchangeView(
          matchId: widget.matchId,
          profile: widget.profile,
          onContinue: () => _advance('wali_gate'),
        );
      case 'wali_gate':
        return _WaliGateView(
          onContinue: () => _advance('phase_1'),
        );
      case 'phase_1':
        return _PhaseView(matchId: widget.matchId, profile: widget.profile, phase: 1, onAdvance: () => _advance('phase_2'), onEnd: _endJourney);
      case 'phase_2':
        return _PhaseView(matchId: widget.matchId, profile: widget.profile, phase: 2, onAdvance: () => _advance('phase_3'), onEnd: _endJourney);
      case 'phase_3':
        return _PhaseView(matchId: widget.matchId, profile: widget.profile, phase: 3, onAdvance: () => _advance('family_stage'), onEnd: _endJourney);
      case 'family_stage':
        return _FamilyStageView(matchId: widget.matchId, profile: widget.profile, onContinue: () => _advance('conversation'));
      case 'conversation':
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen(withProfile: widget.profile)));
        });
        return const Center(child: CircularProgressIndicator(color: Colors.white54));
      default:
        return const Center(child: CircularProgressIndicator(color: Colors.white54));
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

class _EndedView extends StatelessWidget {
  final SeekerProfile profile;
  const _EndedView({required this.profile});

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

// --- Compatibility Reveal ---------------------------------------------

class _CompatibilityRevealView extends StatefulWidget {
  final String matchId;
  final SeekerProfile profile;
  final VoidCallback onContinue;
  final VoidCallback onEnd;
  const _CompatibilityRevealView({required this.matchId, required this.profile, required this.onContinue, required this.onEnd});

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
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.white54));

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
              const CircularProgressIndicator(color: Colors.white54),
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
            Text('Compatibility Reveal', style: ZyraText.heading(size: 20)),
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
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.white54));
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Salam Exchange', style: ZyraText.heading(size: 20)),
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
              const CircularProgressIndicator(color: Colors.white54)
            else
              FilledButton(onPressed: _send, child: Text('Send Salam', style: ZyraText.button(size: 14))),
          ],
        ),
      ),
    );
  }
}

// --- Wali Gate -------------------------------------------------------

class _WaliGateView extends StatefulWidget {
  final VoidCallback onContinue;
  const _WaliGateView({required this.onContinue});

  @override
  State<_WaliGateView> createState() => _WaliGateViewState();
}

class _WaliGateViewState extends State<_WaliGateView> {
  bool _loading = true;
  bool _hasWali = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final userId = ZyraAuth.currentUser?.id;
    final hasWali = userId != null && await ZyraJourneyService.hasActiveMainWali(userId);
    if (!mounted) return;
    setState(() {
      _hasWali = hasWali;
      _loading = false;
    });
    if (hasWali) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.white54));
    if (_hasWali) return const Center(child: CircularProgressIndicator(color: Colors.white54));
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Wali Gate', style: ZyraText.heading(size: 20)),
            const SizedBox(height: 10),
            Text('To begin your journey, you need to link a Wali.', style: ZyraText.subtext(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LinkWaliScreen(asWali: false)));
                if (mounted) _check();
              },
              child: Text('Link a Wali', style: ZyraText.button(size: 14)),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _check, child: Text("I've linked my Wali — check again", style: ZyraText.subtext(size: 12))),
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

  static const _phaseGuidingQuestion = {
    1: 'Are we fundamentally compatible?',
    2: 'Could we realistically build a life together?',
    3: 'Can we navigate life together?',
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.white54));

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
            Text('Phase ${widget.phase} — Revealed', style: ZyraText.heading(size: 18)),
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
              const CircularProgressIndicator(color: Colors.white54),
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
          Text('Phase ${widget.phase}', style: ZyraText.heading(size: 18)),
          const SizedBox(height: 4),
          Text(_phaseGuidingQuestion[widget.phase] ?? '', style: ZyraText.subtext()),
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
                fillColor: Colors.white.withOpacity(0.06),
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
      backgroundColor: Colors.white.withOpacity(0.08),
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

  @override
  void initState() {
    super.initState();
    for (final q in JourneyQuestions.waliToSeeker) {
      _controllers[q.id] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final answers = await ZyraJourneyService.fetchFamilyAnswers(widget.matchId, 'wali_to_seeker');
    if (!mounted) return;
    setState(() {
      _submitted = answers.length >= JourneyQuestions.waliToSeeker.length;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    for (final q in JourneyQuestions.waliToSeeker) {
      final text = _controllers[q.id]!.text.trim();
      if (text.isNotEmpty) {
        await ZyraJourneyService.submitFamilyAnswer(widget.matchId, 'wali_to_seeker', q.id, text);
      }
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.white54));

    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Families have been introduced.', style: ZyraText.heading(size: 18), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                "This is where a Wali's own questions and engagement would normally continue — "
                "full Wali-side participation in this stage is a future build.",
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: widget.onContinue, child: Text('Continue to Conversation', style: ZyraText.button(size: 14))),
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
          Text('Family Compatibility Stage', style: ZyraText.heading(size: 18)),
          const SizedBox(height: 6),
          Text('Involve guardians and families.', style: ZyraText.subtext()),
          const SizedBox(height: 18),
          Text('Questions your Wali might ask you:', style: ZyraText.body(size: 13, color: Colors.white70)),
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
                fillColor: Colors.white.withOpacity(0.06),
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
