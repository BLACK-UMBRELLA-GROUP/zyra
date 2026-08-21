// Wali-facing Journey detail — Journey stage, read-only Timeline,
// read-only Conversation, and (at the Family Stage) the seeker_to_wali
// answering form. Builds the ratified-but-unbuilt "Standard Guardian
// capabilities" (View Journey progress / View Timeline / View
// messages) from APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V5.md,
// backed by 20260726130000_wali_journey_visibility.sql.
//
// Family Stage answering: journey_family_answers already had a
// working Wali-write RLS policy before this file existed (2026-07-25,
// see that migration's own journey_family_answers_write policy —
// `WITH CHECK (answerer_id = auth.uid())`, no seeker-only restriction)
// — the only missing piece was ever the UI. Submits via the same
// ZyraJourneyService.submitFamilyAnswer/fetchFamilyAnswers the Seeker
// side already uses, just with direction 'seeker_to_wali' and the
// Guardian as answerer_id.
//
// 2026-07-26 (#31): Family Review Period Continue/Pause banner added —
// the actual "Choose Continue or Pause during the Family Review
// Period" Standard Guardian capability from WALI_ARCHITECTURE_CURRENT_
// VERSION_V6.md, previously ratified but never built (same gap
// pattern as the Family Stage answering UI above). Shown whenever
// ZyraJourneyService.fetchFamilyReview() finds a live (pending or
// paused) review for this Journey.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/journey_questions.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import '../../data/zyra_journey_stages.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_journey_service.dart';
// ZyraMilestone/ZyraChatMessage are defined in zyra_match_service.dart,
// not zyra_wali_journey_service.dart (which only imports them to shape
// its own fetchTimeline()/fetchMessages() return types) — this file
// declares fields of those types directly (`List<ZyraMilestone>
// _milestones`, `List<ZyraChatMessage> _messages` below), so it needs
// its own import of the defining library. Missing until now (2026-07-26
// pre-existing gap, caught on a real device build during #31 testing,
// not something #31 introduced) — Dart only makes a type's NAME usable
// via re-export or a direct import, not transitively through another
// file's method signatures.
import '../../services/zyra_match_service.dart';
import '../../services/zyra_wali_journey_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

class WaliJourneyDetailScreen extends StatefulWidget {
  final WaliJourneyView journey;
  const WaliJourneyDetailScreen({super.key, required this.journey});

  @override
  State<WaliJourneyDetailScreen> createState() => _WaliJourneyDetailScreenState();
}

class _WaliJourneyDetailScreenState extends State<WaliJourneyDetailScreen> {
  bool _loading = true;
  List<ZyraMilestone> _milestones = [];
  List<ZyraChatMessage> _messages = [];
  Map<String, String> _myAnswers = {}; // seeker_to_wali, answered by this Guardian
  final Map<String, TextEditingController> _controllers = {};
  Timer? _poll;

  // #31 — Family Review Period.
  ({String id, String status, String toStage, DateTime deadlineAt})? _review;
  String? _myDecision; // this Guardian's own Continue/Pause on _review, if any
  bool _reviewActionBusy = false;

  @override
  void initState() {
    super.initState();
    for (final q in JourneyQuestions.seekerToWali) {
      _controllers[q.id] = TextEditingController();
    }
    _load();
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

  bool get _atFamilyStage => widget.journey.journeyStage == 'family_stage';

  /// A dev-panel stand-in. BRANCHED ON BEFORE ANY SERVER CALL, not after:
  /// its matchId is `dev-wj0`, not a uuid, so fetchTimeline,
  /// fetchMessages, fetchFamilyReview and wali_review_decision would each
  /// be handed something that is not an id — and every one of them
  /// swallows its failure and returns null or empty. The screen would
  /// have looked like a Journey with nothing in it rather than like a
  /// mistake, which is precisely how the Seeker side's Reveal button
  /// silently did nothing for a day (composeJourneys, 2026-08-11).
  bool get _isMock => !kReleaseMode && widget.journey.isMock;

  /// The staged Timeline for a stand-in Journey.
  ///
  /// Derived from the staged STAGE rather than listed as its own toggle:
  /// a Journey at Open Conversation has necessarily started a
  /// conversation, and one that has not reached Family Compatibility
  /// cannot have a family_stage milestone. Two controls that could
  /// disagree with each other would let the panel draw a Journey that
  /// cannot exist.
  ///
  /// Milestone types are the ones _milestoneLabel already knows — this
  /// invents no new vocabulary.
  List<ZyraMilestone> get _stagedMilestones {
    final order = ZyraJourneyStages.of(widget.journey.journeyStage)?.order ?? 1;
    final now = DateTime.now();
    return [
      ZyraMilestone(
          type: 'match_created', occurredAt: now.subtract(const Duration(days: 34))),
      if (order >= 7)
        ZyraMilestone(
            type: 'family_stage', occurredAt: now.subtract(const Duration(days: 6))),
      if (order >= 8)
        ZyraMilestone(
            type: 'conversation_started',
            occurredAt: now.subtract(const Duration(days: 2))),
    ];
  }

  Future<void> _load({bool showSpinner = true}) async {
    // STAND-IN: no server call is made at all, and the staged review is
    // read straight back so a Continue tapped a moment ago is still
    // recorded when the 5s poll comes round.
    if (_isMock) {
      if (!mounted) return;
      setState(() {
        _milestones = _stagedMilestones;
        // Messages stay EMPTY on a stand-in, deliberately. A Guardian's
        // message view is a real privacy surface (per-attempt since
        // 2026-08-10, so a new Journey inherits nothing), and inventing a
        // conversation would preview a disclosure rather than a layout.
        _messages = const [];
        _myAnswers = const {};
        _review = ZyraDevScenario.waliStagedReview();
        _myDecision = ZyraDevScenario.instance.waliReviewDecision;
        _loading = false;
      });
      return;
    }
    if (showSpinner && mounted) setState(() => _loading = true);
    final milestones = await ZyraWaliJourneyService.fetchTimeline(widget.journey.matchId);
    final messages = await ZyraWaliJourneyService.fetchMessages(widget.journey.matchId);
    final myAnswers = _atFamilyStage
        ? await ZyraJourneyService.fetchFamilyAnswers(widget.journey.matchId, 'seeker_to_wali')
        : <String, String>{};
    // #31 — best-effort timeout resolution, same lazy-poll pattern as
    // journey_flow_screen.dart, so a review nobody has this screen
    // open for still resolves the moment a Wali next checks in.
    await ZyraJourneyService.resolveFamilyReviewIfDue(widget.journey.matchId);
    final review = await ZyraJourneyService.fetchFamilyReview(widget.journey.matchId);
    final myDecision = review == null ? null : await ZyraWaliJourneyService.myReviewDecision(review.id);
    if (!mounted) return;
    setState(() {
      _milestones = milestones;
      _messages = messages;
      _myAnswers = myAnswers;
      _review = review;
      _myDecision = myDecision;
      _loading = false;
    });
  }

  Future<void> _submitFamilyAnswers() async {
    // A stand-in has no journey_family_answers row to write to. Answers
    // are kept in the controllers and simply not submitted — the panel
    // does not claim to stage this half.
    if (_isMock) {
      await _load();
      return;
    }
    // BUG-03 (2026-08-14 audit, OA-ZYRA-225 — fixed 2026-08-15): same
    // truthful-submit rule as the Seeker side. A Guardian's family
    // answers are a Journey safeguard; a failed write now says so, the
    // text stays in the controllers, and pressing Submit again re-sends
    // safely (dup rows are tolerated by later-insert-wins ordering).
    var allSaved = true;
    for (final q in JourneyQuestions.seekerToWali) {
      final text = _controllers[q.id]!.text.trim();
      if (text.isNotEmpty) {
        final ok = await ZyraJourneyService.submitFamilyAnswer(widget.journey.matchId, 'seeker_to_wali', q.id, text);
        if (!ok) allSaved = false;
      }
    }
    if (!allSaved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Some answers didn't save — check your connection and press Submit again.")));
    }
    await _load();
  }

  Future<void> _reviewDecision(String decision) async {
    final review = _review;
    if (review == null || _reviewActionBusy) return;
    // THE STAND-IN ACTUALLY DECIDES. Writing the choice into the scenario
    // and re-reading it is what makes this rehearsable: the buttons grey,
    // the card switches to "You chose … — waiting on the other family",
    // and it survives the 5s poll. A snackbar here would be the panel
    // announcing an outcome instead of producing one.
    if (_isMock) {
      ZyraDevScenario.instance.setWaliReviewDecision(decision);
      await _load(showSpinner: false);
      return;
    }
    setState(() => _reviewActionBusy = true);
    await ZyraWaliJourneyService.waliReviewDecision(review.id, decision);
    if (!mounted) return;
    setState(() => _reviewActionBusy = false);
    await _load(showSpinner: false);
  }

  Future<void> _reopenReview() async {
    final review = _review;
    if (review == null || _reviewActionBusy) return;
    if (_isMock) {
      // Reopening clears the decision and starts the window again —
      // the same shape reopen_family_review() produces.
      ZyraDevScenario.instance.setWaliReviewDecision(null);
      await _load(showSpinner: false);
      return;
    }
    setState(() => _reviewActionBusy = true);
    await ZyraWaliJourneyService.reopenFamilyReview(review.id);
    if (!mounted) return;
    setState(() => _reviewActionBusy = false);
    await _load(showSpinner: false);
  }

  static String _formatReviewRemaining(DateTime deadlineAt) {
    final d = deadlineAt.difference(DateTime.now());
    if (d.isNegative || d == Duration.zero) return 'less than a minute';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  // _stageLabel REMOVED 2026-08-09 — see data/zyra_journey_stages.dart.
  //
  // It was one of three copies of the same switch over the same eight
  // strings, and the three had drifted: this one said 'Phase 1 —
  // Foundations', the Guardian Dashboard said 'Phase 1', and Connections
  // said 'In the Pre-Journey Ritual' for seven of the eight. A Guardian
  // could read two different names for one Journey by tapping into it.
  //
  // The labels also changed with the move: 'Phase 1/2/3' were internal
  // engineering names that had leaked to the surface (Founder,
  // 2026-08-09). They are now Faith & Values, Building a Life and
  // Navigating Life.

  /// Milestone types from `journey_milestones` — NOT Journey stages, and
  /// deliberately not folded into ZyraJourneyStages even though
  /// 'family_stage' appears in both. One is a stage of the Journey; the
  /// other is a real-world event a Guardian records after it happened.
  /// Merging them on a matching string would be a false economy.
  static String _milestoneLabel(String type) => switch (type) {
        'match_created' => 'Match',
        'conversation_started' => 'Conversation Started',
        'family_stage' => 'Family Stage',
        'meeting' => 'Meeting',
        'nikah' => 'Nikah',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    final j = widget.journey;
    final answered = _myAnswers.length >= JourneyQuestions.seekerToWali.length;

    return Scaffold(
      // FIXED 2026-08-01 (Founder: "there should be no purple at top, it
      // should blend the pink/purple colour... that should be across all
      // things"). Same fix notifications_screen.dart got on 2026-07-27:
      // without this the transparent AppBar shows the Scaffold's own flat
      // background through, cutting the gender gradient off with a hard
      // purple strip. Body content compensates with SafeArea, which still
      // clears the status bar.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${j.linkedSeekerName} & ${j.partner.firstName}', style: ZyraText.heading(size: 16)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: _loading
              ? const ZyraLoading()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ZyraColors.iconButtonBg,
                        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          // 2026-07-26: check_circle_outline replaces
                          // favorite_border (Founder: app-wide heart-icon
                          // removal) — pairs cleanly with its sibling
                          // pause_circle_outline, same icon family.
                          Icon(
                            j.isSuspended ? Icons.pause_circle_outline : Icons.check_circle_outline,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  j.isSuspended
                                      ? 'Paused'
                                      : (j.status == 'ended'
                                          ? 'Ended'
                                          // The override is real here, not
                                          // a hardcoded false: this screen
                                          // already loads the review in
                                          // _load(). When one is open the
                                          // chip says Family Review and the
                                          // card below it carries the
                                          // countdown and this Guardian's
                                          // own Continue/Pause.
                                          : ZyraJourneyStages.labelFor(
                                              j.journeyStage,
                                              reviewOpen: _review != null,
                                            )),
                                  style: ZyraText.body(size: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text('${j.linkedSeekerName}\'s Journey with ${j.partner.firstName}', style: ZyraText.subtext(size: 11.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── The other family ──────────────────────────
                    // 2026-08-08. Everything a Guardian may learn about
                    // the counterpart family now arrives here and nowhere
                    // else. Until today this screen read the counterpart's
                    // full profile — photos, city, and by extension their
                    // Guardians and this Guardian's own co-Guardians —
                    // because clause 3 of zyra_can_view_profile treated
                    // every attempt participant as visible to every other.
                    //
                    // The disclosure line is required, not decorative:
                    // people are entitled to know what the other family
                    // can see of them. Same fields for everyone — a card
                    // a user could trim would make a sparse card a signal.
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border.all(color: Colors.white24, width: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('The other family', style: ZyraText.heading(size: 14)),
                          const SizedBox(height: 10),
                          _CardRow(label: 'Seeker', value: '${j.partner.firstName}${j.partner.age > 0 ? ', ${j.partner.age}' : ''}'),
                          const SizedBox(height: 6),
                          _CardRow(
                            label: 'Main Guardian',
                            value: j.counterpartGuardianName == null
                                ? 'No Main Guardian linked'
                                : [j.counterpartGuardianName, j.counterpartGuardianSurname]
                                    .where((x) => x != null && x.isNotEmpty).join(' '),
                            muted: j.counterpartGuardianName == null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This is everything you can see of the other family — '
                            'and they see the same of yours.',
                            style: ZyraText.subtext(size: 11),
                          ),
                        ],
                      ),
                    ),

                    // #31 — Family Review Period banner. Shown whenever
                    // a review is live for this Journey, regardless of
                    // which stage it's holding at.
                    if (_review != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ZyraColors.accentBg,
                          border: Border.all(color: ZyraColors.accentBorder, width: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _review!.status == 'paused' ? Icons.pause_circle_outline : Icons.hourglass_top,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _review!.status == 'paused' ? 'Family Review — Paused' : 'Family Review Period',
                                  style: ZyraText.body(size: 14, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _review!.status == 'paused'
                                  ? "You paused this stage. ${j.linkedSeekerName}'s Journey holds here until you (or ${j.linkedSeekerName}'s other Guardian) reopen the review."
                                  : "Review this stage. Unless you or ${j.linkedSeekerName}'s other Guardian raises a concern, the Journey continues automatically in ${_formatReviewRemaining(_review!.deadlineAt)}.",
                              style: ZyraText.subtext(size: 12.5),
                            ),
                            const SizedBox(height: 12),
                            if (_review!.status == 'paused')
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _reviewActionBusy ? null : _reopenReview,
                                  child: _reviewActionBusy
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text('Reopen Review', style: ZyraText.button(size: 13)),
                                ),
                              )
                            else if (_myDecision != null)
                              Text(
                                _myDecision == 'pause' ? "You chose Pause." : "You chose Continue — waiting on the review window.",
                                style: ZyraText.subtext(size: 12, color: Colors.white70),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _reviewActionBusy ? null : () => _reviewDecision('continue'),
                                      child: Text('Continue', style: ZyraText.button(size: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _reviewActionBusy ? null : () => _reviewDecision('pause'),
                                      child: Text('Pause', style: ZyraText.button(size: 13)),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],

                    if (_atFamilyStage) ...[
                      const SizedBox(height: 24),
                      Text('FAMILY COMPATIBILITY STAGE', style: ZyraText.chapterLabel(color: Colors.white54)),
                      const SizedBox(height: 10),
                      if (answered)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ZyraColors.iconButtonBg,
                            border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "You've answered ${j.partner.firstName}'s questions. "
                            "${j.linkedSeekerName}'s Journey continues once both sides have answered.",
                            style: ZyraText.subtext(size: 12.5),
                          ),
                        )
                      else ...[
                        Text(
                          "${j.partner.firstName}'s side has questions for you, as ${j.linkedSeekerName}'s Guardian:",
                          style: ZyraText.body(size: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        for (final q in JourneyQuestions.seekerToWali) ...[
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
                          const SizedBox(height: 14),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(onPressed: _submitFamilyAnswers, child: Text('Submit', style: ZyraText.button(size: 14))),
                        ),
                      ],
                    ],

                    const SizedBox(height: 28),
                    Text('TIMELINE', style: ZyraText.chapterLabel(color: Colors.white54)),
                    const SizedBox(height: 10),
                    if (_milestones.isEmpty)
                      const ZyraEmptyState(icon: Icons.timeline_outlined, message: 'Nothing recorded here yet.')
                    else
                      ..._milestones.map((m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.white38, size: 8),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_milestoneLabel(m.type), style: ZyraText.body(size: 13, color: Colors.white))),
                                Text('${m.occurredAt.day}/${m.occurredAt.month}/${m.occurredAt.year}', style: ZyraText.subtext(size: 11)),
                              ],
                            ),
                          )),

                    const SizedBox(height: 28),
                    Text('CONVERSATION', style: ZyraText.chapterLabel(color: Colors.white54)),
                    const SizedBox(height: 10),
                    if (_messages.isEmpty)
                      const ZyraEmptyState(icon: Icons.forum_outlined, message: 'No messages yet.')
                    else
                      ..._messages.map((m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 280),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: ZyraColors.iconButtonBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(m.text, style: ZyraText.body(size: 13, color: Colors.white)),
                              ),
                            ),
                          )),
                  ],
                ),
        ),
      ),
    );
  }
}


/// One label/value line of the counterpart card. Kept private to this
/// screen — the card is the only place it renders.
class _CardRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  const _CardRow({required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 108, child: Text(label, style: ZyraText.subtext(size: 12))),
        Expanded(
          child: Text(
            value,
            style: muted
                ? ZyraText.subtext(size: 12.5)
                : ZyraText.body(size: 12.5, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
