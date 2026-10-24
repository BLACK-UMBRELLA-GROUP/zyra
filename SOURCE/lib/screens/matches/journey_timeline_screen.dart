// Journey Timeline — per ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md's
// timelines/timeline_milestones tables ("Journey timeline per match" /
// "Events recorded on the timeline"). Reads real milestones for the
// signed-in user's match with withProfile. 'match_created' is added
// automatically the instant a mutual Like creates the match;
// 'conversation_started' and each completed Journey stage are written
// automatically by the stage-transition trigger. Meeting/Nikah have no
// automatic signal, so either Seeker proposes them here and the other
// confirms before they join the shared record.
//
// Falls back to a plain empty state for mock Active Journeys with no
// real backing match (nothing to show, not an error).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Supabase;
import '../../dev/zyra_app_gold_preview.dart';
import '../../data/journey_questions.dart';
import '../../data/zyra_journey_stages.dart';
import '../../data/zyra_timeline_milestones.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_journey_service.dart';
import '../../services/zyra_match_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../widgets/zyra_glass_dialog.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';
import '../subscription/profile_unlock_screen.dart';
import '../../widgets/zyra_moment.dart';

/// One question, both answers — the unit the enriched Timeline renders
/// under a finished phase (2026-08-13, "more than just bullet points").
typedef _QaPair = ({String question, String mine, String theirs});

// ── The rail's entry types. Until 2026-08-13 the list held only
// milestones and chapter labels; then the Journey Map dissolved into
// this screen (Founder: "make it all live in timeline anyway meaning
// the pill journey map has to be removed from the system") and the rail
// learned three tenses: what happened (milestones, dated), where you
// stand (_TlHere, glowing), and what's still to come (_TlAhead, hollow
// and dimmed). The stages come from the ONE canonical map
// (ZyraJourneyStages) — never re-listed here.

class _TlChapter {
  final String label;

  /// True for "The road ahead" — the future's header whispers.
  final bool dim;
  const _TlChapter(this.label, {this.dim = false});
}

class _TlHere {
  final ZyraJourneyStage stage;

  /// False at the final stage — nothing follows, so no rail line.
  final bool hasNext;
  const _TlHere(this.stage, {required this.hasNext});
}

class _TlAhead {
  final ZyraJourneyStage stage;
  final bool isLast;
  const _TlAhead(this.stage, {required this.isLast});
}

class JourneyTimelineScreen extends StatefulWidget {
  final SeekerProfile withProfile;
  final Future<ZyraSourceResult<List<ZyraMilestone>>> Function(String)?
  loadTimeline;
  final Future<ZyraTimelineContext> Function(String)? loadContext;
  final Future<String?> Function(String, String, DateTime)? proposeMilestone;
  final Future<String?> Function(String)? confirmMilestone;

  /// True when opened from a dev stand-in Journey (ZyraDevScenario fakes).
  /// A fake pair has no match row, so the fetch would come back empty and
  /// LOOK broken — the exact inconsistency the Founder hit on 2026-08-12
  /// ("when I press the Timeline button itself, there is no Timeline
  /// data… the other way, I get a different experience"). One screen, one
  /// experience: mock entries skip the network and say plainly what they
  /// are. Release builds never construct fakes, so this is dev-only.
  final bool isMock;

  /// The pair's current journey_stage, when the caller knows it — the
  /// rail's YOU ARE HERE and road-ahead entries need a position to draw
  /// (2026-08-13, the Map dissolved into this screen; its bubble lived
  /// here for part of one day before the Founder folded the road into
  /// the rail itself). Callers that don't know the stage may leave it
  /// null — the screen falls back to the composed Active Journeys
  /// before omitting the road.
  final String? journeyStage;
  const JourneyTimelineScreen({
    super.key,
    required this.withProfile,
    this.isMock = false,
    this.journeyStage,
    this.loadTimeline,
    this.loadContext,
    this.proposeMilestone,
    this.confirmMilestone,
  });

  @override
  State<JourneyTimelineScreen> createState() => _JourneyTimelineScreenState();
}

class _JourneyTimelineScreenState extends State<JourneyTimelineScreen> {
  final _accountGeneration = ZyraAccountState.generation;
  final _accountOwner = ZyraAccountState.userId;
  late final (bool, String?) _sdkOwner;
  String? _initialAccessToken;
  StreamSubscription<AuthState>? _authSubscription;
  bool _revoked = false;
  ModalRoute<dynamic>? _ownerRoute;
  bool _routeWasCurrent = true;
  int _actionRevision = 0;
  bool _ownedChildShowing = false;
  Route<dynamic>? _ownedChildRoute;
  bool get _accountCurrent =>
      mounted &&
      !_revoked &&
      _sdkOwner == _readSdkOwner() &&
      (!_sdkOwner.$1 || _sdkOwner.$2 == _accountOwner) &&
      !ZyraAccountState.isSigningOut &&
      _accountGeneration == ZyraAccountState.generation &&
      _accountOwner == ZyraAccountState.userId;
  bool get _routeCurrent => _ownerRoute?.isCurrent ?? true;
  bool get _canRecord =>
      _accountCurrent &&
      _routeCurrent &&
      _sdkOwner.$1 &&
      _sdkOwner.$2 != null &&
      _sdkOwner.$2 == _accountOwner &&
      !_loading &&
      !_loadFailed &&
      !_busy &&
      _context.active &&
      !_context.paused &&
      _context.matchId != null;

  (bool, String?) _readSdkOwner() {
    try {
      return (true, ZyraAuth.currentUser?.id);
    } catch (_) {
      return (false, null);
    }
  }

  void _watchSdkOwner() {
    _sdkOwner = _readSdkOwner();
    if (!_sdkOwner.$1) return;
    _initialAccessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    _authSubscription = ZyraAuth.authStateChanges.listen((state) {
      if (!mounted || _revoked) return;
      if (_sdkOwner != _readSdkOwner() ||
          (state.session != null && state.session!.user.id != _sdkOwner.$2) ||
          state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.signedOut ||
          state.event == AuthChangeEvent.passwordRecovery ||
          (state.event == AuthChangeEvent.initialSession &&
              state.session?.accessToken != _initialAccessToken)) {
        _withdrawAccount();
      }
    }, onError: (Object _, StackTrace _) => _withdrawAccount());
  }

  void _invalidateIntent() {
    ++_actionRevision;
    _busy = false;
    final child = _ownedChildRoute;
    if (child != null && child.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (child.isActive) child.navigator?.removeRoute(child);
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  bool Function() _intentGuard(String matchId) {
    final revision = _actionRevision;
    return () =>
        _accountCurrent &&
        revision == _actionRevision &&
        _context.matchId == matchId &&
        _context.active &&
        !_context.paused;
  }

  Widget _guardChild(Widget child, bool Function() current) =>
      _TimelineOwnedChild(
        current: current,
        onRoute: (route) {
          // The outgoing type dialog can report another dependency change
          // after the date picker has opened. It must not replace the live
          // owned route with its inactive, already-popped predecessor.
          if (route != null && route.isActive && route.isCurrent) {
            _ownedChildRoute = route;
          }
        },
        onCovered: _invalidateIntent,
        child: child,
      );
  bool _loading = true;
  bool _loadFailed = false;
  int _loadGeneration = 0;
  List<ZyraMilestone> _milestones = [];
  bool _reviewEverything = false;

  /// Phase → the questions BOTH Seekers answered, paired. Empty until
  /// loaded, empty forever for a Journey that never sealed a phase.
  Map<int, List<_QaPair>> _qa = {};

  // Meeting/Nikah attestation (Founder 2026-08-12: both Seekers confirm).
  ZyraTimelineContext _context = const ZyraTimelineContext();
  bool _pendingDismissed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _watchSdkOwner();
    AppState.instance.addListener(_onAccountChanged);
    _load();
  }

  @override
  void dispose() {
    _revoked = true;
    _invalidateIntent();
    _authSubscription?.cancel();
    AppState.instance.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onAccountChanged() {
    if (!mounted || _accountCurrent) return;
    _withdrawAccount();
  }

  void _withdrawAccount() {
    if (!mounted || _revoked) return;
    _revoked = true;
    ++_loadGeneration;
    _invalidateIntent();
    _authSubscription?.cancel();
    _milestones = [];
    _qa = {};
    _context = const ZyraTimelineContext();
    _loading = false;
    _loadFailed = true;
    _reviewEverything = false;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    } else {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownerRoute = ModalRoute.of(context);
    final current = _routeCurrent;
    if (_routeWasCurrent && !current && !_ownedChildShowing) {
      _invalidateIntent();
    }
    _routeWasCurrent = current;
    if (!_accountCurrent) _withdrawAccount();
  }

  @override
  void didUpdateWidget(covariant JourneyTimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.withProfile.id == widget.withProfile.id &&
        oldWidget.isMock == widget.isMock &&
        oldWidget.journeyStage == widget.journeyStage) {
      return;
    }
    ++_loadGeneration;
    _invalidateIntent();
    _context = const ZyraTimelineContext();
    _milestones = [];
    _qa = {};
    _loading = true;
    _pendingDismissed = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_accountCurrent && _routeCurrent) unawaited(_load());
    });
  }

  Future<void> _load() async {
    if (!_accountCurrent || !_routeCurrent) return;
    final generation = ++_loadGeneration;
    _invalidateIntent();
    setState(() {
      _loading = true;
      _loadFailed = false;
      _context = const ZyraTimelineContext();
      _milestones = [];
      _qa = {};
    });
    // Dev stand-ins have no match row — asking the server for their story
    // would return an empty list that reads as a bug. Say what it is
    // instead (see the isMock doc above).
    if (widget.isMock) {
      setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        (widget.loadTimeline ?? ZyraMatchService.fetchTimelineResult)(
          widget.withProfile.id,
        ),
        (widget.loadContext ?? ZyraMatchService.fetchTimelineContext)(
          widget.withProfile.id,
        ),
      ]);
      if (!mounted || !_accountCurrent || generation != _loadGeneration) return;
      final milestones = results[0] as ZyraSourceResult<List<ZyraMilestone>>;
      if (milestones.isUnavailable) throw StateError('Timeline unavailable');
      final tlContext = results[1] as ZyraTimelineContext;
      // The Journey's own words need the matchId, which arrives with the
      // context — so this fetch waits for it rather than racing it.
      final qa = await _loadQa(tlContext.matchId);
      if (!mounted || !_accountCurrent || generation != _loadGeneration) return;
      setState(() {
        _milestones = milestones.valueOr(const []);
        _context = tlContext;
        _qa = qa;
        _loading = false;
      });
    } catch (error) {
      debugPrint('ZYRA: timeline load failed (${error.runtimeType}).');
      if (!mounted || !_accountCurrent || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _context = const ZyraTimelineContext();
      });
    }
  }

  /// THE JOURNEY'S OWN WORDS — 2026-08-13 (Founder: "they gotta find a
  /// way to see the journey they already had like questions they asked
  /// and answered maybe all that can live in timeline even for active
  /// journey. so timeline is more than just bullet points").
  ///
  /// Reads journey_phase_answers for the three sustained phases and
  /// pairs both people's answers under each question. THE REVEAL RULE
  /// TRAVELS: a phase's answers appear here only once BOTH Seekers have
  /// sealed that phase — the same both-sealed test the phase view uses
  /// before opening answers side by side. Nothing shows here that the
  /// Journey itself has not already shown, on any of the three states
  /// this screen serves (Active, Paused, Ended — identical, which is the
  /// point: the story is kept).
  ///
  /// Best-effort by design: a failed fetch leaves the milestones
  /// standing alone rather than replacing the story with an error.
  Future<Map<int, List<_QaPair>>> _loadQa(String? matchId) async {
    if (matchId == null) return {};
    final myId = ZyraAuth.currentUser?.id;
    if (myId == null) return {};
    try {
      final fetched = await Future.wait(
        [1, 2, 3].map((p) => ZyraJourneyService.fetchPhaseAnswers(matchId, p)),
      );
      final qa = <int, List<_QaPair>>{};
      for (var i = 0; i < fetched.length; i++) {
        final phase = i + 1;
        final all = fetched[i];
        final bank = JourneyQuestions.forPhase(phase);
        if (bank.isEmpty) continue;
        final sealed =
            all.values.where((a) => a.length >= bank.length).length >= 2;
        if (!sealed) continue;
        final mine = all[myId] ?? const <String, String>{};
        final otherId = all.keys.firstWhere((k) => k != myId, orElse: () => '');
        final theirs = all[otherId] ?? const <String, String>{};
        final pairs = <_QaPair>[
          for (final q in bank)
            if ((mine[q.id] ?? '').trim().isNotEmpty &&
                (theirs[q.id] ?? '').trim().isNotEmpty)
              (question: q.text, mine: mine[q.id]!, theirs: theirs[q.id]!),
        ];
        if (pairs.isNotEmpty) qa[phase] = pairs;
      }
      return qa;
    } catch (_) {
      return {};
    }
  }

  /// Which phase's answers a milestone carries, or null. The completion
  /// milestone is where the phase's questions live on the rail — the
  /// moment they were sealed and opened together.
  static int? _phaseOf(String type) => switch (type) {
    'phase_1_complete' => 1,
    'phase_2_complete' => 2,
    'phase_3_complete' => 3,
    _ => null,
  };

  /// A development-only component review, never relationship history.
  /// It exercises every milestone type accepted by the current Timeline
  /// contract without changing or fabricating server data.
  List<ZyraMilestone> _reviewMilestones() {
    const types = ZyraTimelineMilestones.supportedTypes;
    final first = DateTime.now().subtract(const Duration(days: 48));
    return [
      for (var i = 0; i < types.length; i++)
        ZyraMilestone(
          type: types[i],
          occurredAt: first.add(Duration(days: i * 3)),
        ),
    ];
  }

  List<_QaPair>? _pairsForDisplay(int? phase) {
    if (phase == null) return null;
    final real = _qa[phase];
    if (!_reviewEverything || (real != null && real.isNotEmpty)) return real;
    final bank = JourneyQuestions.forPhase(phase);
    if (bank.isEmpty) return null;
    return [
      (
        question: bank.first.text,
        mine: 'Your saved answer appears here.',
        theirs: "${widget.withProfile.firstName}'s saved answer appears here.",
      ),
    ];
  }

  /// Which chapter a milestone OPENS, using the canonical stage labels
  /// (ZyraJourneyStages — one map, never duplicated here). Null means
  /// the entry belongs to whatever chapter is already open — pauses,
  /// continues, endings and restarts are the flow of a chapter, not the
  /// start of one.
  static String? _chapterFor(String type) {
    final journeyStage = ZyraJourneyStages.ofTimelineMilestone(type);
    if (journeyStage != null) return journeyStage.label;
    return switch (type) {
      'liked' || 'match_created' => 'The match',
      'journey_started' => ZyraJourneyStages.of('salam_exchange')?.label,
      'meeting' || 'nikah' => 'Family & beyond',
      _ => null,
    };
  }

  /// The stage the rail's road draws from: the caller's word first, else
  /// the composed Active Journeys (covers the in-Journey "Read your
  /// story so far" links, which know the profile but not the stage —
  /// an active Journey with this person is by definition in that list).
  /// Null omits the road: a rail with no position on it must not guess.
  /// A Paused or Ended Journey keeps its stage on the match row, so its
  /// road renders frozen exactly where things stopped.
  String? get _currentStage {
    final given = widget.journeyStage;
    if (given != null && given.isNotEmpty) return given;
    for (final a in AppState.instance.activeJourneys) {
      if (a.profile.id == widget.withProfile.id) return a.journeyStage;
    }
    return null;
  }

  /// The two attestable types not yet on this Timeline.
  List<String> get _attestableTypes {
    final recorded = _milestones.map((m) => m.type).toSet();
    return ['meeting', 'nikah'].where((t) => !recorded.contains(t)).toList();
  }

  static String _attestLabel(String type) =>
      type == 'meeting' ? 'Meeting' : 'Nikah';

  Future<void> _openPropose() async {
    if (!_canRecord || _context.pending != null) return;
    final types = _attestableTypes;
    if (types.isEmpty || _context.matchId == null) return;
    final matchId = _context.matchId!;
    ++_actionRevision;
    final current = _intentGuard(matchId);
    setState(() => _busy = true);
    try {
      _ownedChildShowing = true;
      final picked = await showZyraGlassDialog<String>(
        context: context,
        builder: (ctx) => _guardChild(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 30),
              SizedBox(height: 14),
              Text(
                'Record a milestone',
                style: ZyraText.heading(size: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'It joins the Timeline once ${widget.withProfile.firstName} confirms it too.',
                style: ZyraText.subtext(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              for (final t in types) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (current() &&
                          ctx.mounted &&
                          ModalRoute.of(ctx)?.isCurrent == true) {
                        Navigator.of(ctx).pop(t);
                      }
                    },
                    child: Text(
                      _attestLabel(t),
                      style: ZyraText.button(size: 13),
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
              TextButton(
                onPressed: () {
                  if (current() &&
                      ctx.mounted &&
                      ModalRoute.of(ctx)?.isCurrent == true) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: Text('Cancel', style: ZyraText.subtext(size: 13)),
              ),
            ],
          ),
          current,
        ),
      );
      _ownedChildShowing = false;
      _ownedChildRoute = null;
      if (!mounted ||
          picked == null ||
          !current() ||
          !_routeCurrent ||
          !types.contains(picked)) {
        return;
      }
      final now = DateTime.now();
      _ownedChildShowing = true;
      final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(2024),
        lastDate: now,
        helpText: 'When was your ${_attestLabel(picked).toLowerCase()}?',
        builder: (_, child) => _guardChild(child!, current),
      );
      _ownedChildShowing = false;
      _ownedChildRoute = null;
      if (!mounted || date == null || !current() || !_routeCurrent) return;
      final error =
          await (widget.proposeMilestone ?? ZyraMatchService.proposeMilestone)(
            matchId,
            picked,
            date,
          );
      if (!mounted || !current() || !_routeCurrent) return;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      await _load();
    } catch (_) {
      if (mounted && current() && _routeCurrent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("That didn't go through. Please try again."),
          ),
        );
      }
    } finally {
      _ownedChildShowing = false;
      _ownedChildRoute = null;
      if (mounted && current()) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPending() async {
    if (!_canRecord) return;
    final pending = _context.pending;
    if (pending == null || pending.proposedBy == _sdkOwner.$2) return;
    final matchId = _context.matchId!;
    ++_actionRevision;
    final current = _intentGuard(matchId);
    setState(() => _busy = true);
    try {
      final error =
          await (widget.confirmMilestone ?? ZyraMatchService.confirmMilestone)(
            pending.id,
          );
      if (!mounted ||
          !current() ||
          !_routeCurrent ||
          _context.pending?.id != pending.id) {
        return;
      }
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      } else {
        // E5 / R7 (DR-ZYRA-147): both Seekers have now confirmed a
        // real-world milestone. Meeting gets one breath; the Nikah gets
        // the crown — the one screen a couple keeps. Plays on the
        // CONFIRMING side here; the proposer sees it on their next visit
        // via the Timeline itself (their moment is OA-listed).
        final name = widget.withProfile.firstName;
        if (pending.type == 'nikah') {
          await _showOwnedMoment(
            current,
            glow: true,
            pairWith: widget.withProfile,
            dateChip: 'NIKAH · ${_dateFor(pending.occurredOn).toUpperCase()}',
            lines: [
              const ZyraMomentLine.whisper('Alhamdulillah.'),
              ZyraMomentLine.heading('You & $name'),
              const ZyraMomentLine.body('From a match to a marriage.'),
              const ZyraMomentLine.quiet(
                'Your whole story is kept — the road, the words, the '
                'milestones. ZYRA was honoured to walk it with you.',
              ),
            ],
            ctaLabel: 'View your Timeline',
          );
        } else if (pending.type == 'meeting') {
          await _showOwnedMoment(
            current,
            mark: Icons.people_outline,
            lines: [
              const ZyraMomentLine.heading('You met.'),
              ZyraMomentLine.body(
                'Recorded, agreed by you both — '
                '${_dateFor(pending.occurredOn)} joins your Timeline.',
              ),
            ],
            ctaLabel: 'Continue',
          );
        }
        if (!mounted || !current() || !_routeCurrent) return;
      }
      await _load();
    } catch (_) {
      if (mounted && current() && _routeCurrent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("That didn't go through. Please try again."),
          ),
        );
      }
    } finally {
      if (mounted && current()) setState(() => _busy = false);
    }
  }

  Future<void> _showOwnedMoment(
    bool Function() current, {
    IconData? mark,
    SeekerProfile? pairWith,
    String? dateChip,
    bool glow = false,
    required List<ZyraMomentLine> lines,
    required String ctaLabel,
  }) async {
    if (!current() || !_routeCurrent) return;
    _ownedChildShowing = true;
    try {
      await Navigator.of(context).push<bool>(
        PageRouteBuilder<bool>(
          opaque: true,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, _, _) => _guardChild(
            ZyraMomentScreen(
              mark: mark,
              pairWith: pairWith,
              dateChip: dateChip,
              glow: glow,
              lines: lines,
              ctaLabel: ctaLabel,
              onPrimary: () {
                final route = _ownedChildRoute;
                if (current() && route?.isCurrent == true) {
                  route!.navigator?.pop(true);
                }
              },
            ),
            current,
          ),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } finally {
      _ownedChildShowing = false;
      _ownedChildRoute = null;
    }
  }

  // ── EXTENDED 2026-08-11 with the Journey's own milestones. Until today
  // the Timeline could draw exactly one thing — 'match_created' — because
  // that was the only milestone anything wrote. Eight stages ran past it
  // leaving no mark, so a couple at Open Conversation and a couple who had
  // just matched had identical Timelines.
  //
  // WRITTEN AS A MOMENT, NOT AS A STAGE NAME. 'Faith & Values' is where you
  // ARE; 'You finished Faith & Values' is what HAPPENED, and a timeline is a
  // list of things that happened. The stage labels themselves still come from
  // the canonical map and are not duplicated here — these are event names.
  static String _labelFor(String type) => ZyraTimelineMilestones.labelFor(type);

  /// Pauses and resumes are true history but small history — they render
  /// dimmed and tighter than real milestones, so five pauses read as a
  /// season of a relationship rather than a rap sheet (DR-ZYRA-142).
  static bool _isQuiet(String type) => ZyraTimelineMilestones.isQuiet(type);

  // 2026-07-26: check_circle_outline replaces favorite here (Founder:
  // "for the whole app I'm tryna avoid any heart icons") — outline
  // variant matches this switch's other three entries.
  static IconData _iconFor(String type) => ZyraTimelineMilestones.iconFor(type);

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "08 August 2026" — Founder's spec, 2026-08-11: the Timeline is the
  /// permanent history of the relationship, so every entry carries the
  /// ACTUAL calendar date, written out, never a relative "2 days ago"
  /// (relative dates rot; a record does not). Zero-padded day and full
  /// month name exactly as the spec's own example. Hand-rolled rather
  /// than adding the intl package for one format.
  static String _dateFor(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${_months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_accountCurrent) return const SizedBox.shrink();
    final actionRevision = _actionRevision;
    bool actionCurrent() =>
        _accountCurrent && _routeCurrent && actionRevision == _actionRevision;
    final displayMilestones = _reviewEverything
        ? _reviewMilestones()
        : _milestones;
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
        title: Text(
          'Timeline with ${widget.withProfile.firstName}',
          style: ZyraText.heading(size: 17),
        ),
        iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
      ),
      body: Container(
        // WAS gender-matched (DR-ZYRA-094, 2026-07-25). Journey mode is
        // neutral ground since DR-ZYRA-177 — the flow screen's header
        // note has the ruling; the Timeline is the same place.
        decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Column(
            children: [
              // THE BUBBLE ROW — down to one occasional bubble.
              // "View full profile" lived here 2026-08-10 → 2026-08-13
              // (removed when every Journey card gained View Profile);
              // a "Journey Map" bubble lived here for PART OF ONE DAY
              // before the Founder folded the road into the rail itself
              // ("make it all live in timeline… the pill journey map
              // has to be removed from the system") — see the road
              // entries at the rail's foot. What remains is Record a
              // milestone, which is genuinely Timeline work.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Meeting/Nikah are real-world events with no automatic
                      // signal in the data — either Seeker proposes, the other
                      // confirms (Founder 2026-08-12). Only on a running
                      // Journey, only while something is left to record, and
                      // never while a proposal is already pending.
                      if (_canRecord &&
                          !_context.paused &&
                          _context.matchId != null &&
                          _context.pending == null &&
                          _attestableTypes.isNotEmpty)
                        _TimelineBubble(
                          label: 'Record a milestone',
                          onTap: () {
                            if (actionCurrent()) unawaited(_openPropose());
                          },
                        ),
                      if (ZyraDeveloperAccess.canUseDeveloperTools)
                        _TimelineBubble(
                          label: _reviewEverything
                              ? 'Close full review'
                              : 'Review everything',
                          onTap: () {
                            if (actionCurrent() &&
                                ZyraDeveloperAccess.canUseDeveloperTools) {
                              setState(
                                () => _reviewEverything = !_reviewEverything,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
              if (_reviewEverything)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x24CEA2D1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x66CEA2D1)),
                    ),
                    child: Text(
                      'DEVELOPMENT REVIEW · Every supported Timeline event, '
                      'answer-card state and road state is shown below. No '
                      'relationship data is changed.',
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: ZyraColors.ink(0.85),
                      ).copyWith(letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              // A proposal from the other Seeker: confirm it here, or leave
              // it — "Not yet" only hides it for this visit, deliberately.
              if (!_loading &&
                  !_loadFailed &&
                  _context.active &&
                  !_context.paused &&
                  _context.pending != null &&
                  _context.pending!.proposedBy != ZyraAuth.currentUser?.id &&
                  !_pendingDismissed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    decoration: BoxDecoration(
                      color: ZyraColors.frostFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ZyraColors.frostBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.withProfile.firstName} says your '
                          '${_attestLabel(_context.pending!.type).toLowerCase()} was on '
                          '${_dateFor(_context.pending!.occurredOn)}.',
                          style: ZyraText.body(size: 13.5),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                if (actionCurrent() && !_busy) {
                                  setState(() => _pendingDismissed = true);
                                }
                              },
                              child: Text(
                                'Not yet',
                                style: ZyraText.subtext(size: 12.5),
                              ),
                            ),
                            SizedBox(width: 4),
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      if (actionCurrent()) {
                                        unawaited(_confirmPending());
                                      }
                                    },
                              child: Text(
                                _busy ? 'Confirming…' : 'Confirm',
                                style: ZyraText.button(size: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              // Your own proposal, still waiting on them.
              if (_context.pending != null &&
                  _context.pending!.proposedBy == ZyraAuth.currentUser?.id)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    'Waiting for ${widget.withProfile.firstName} to confirm — '
                    '${_attestLabel(_context.pending!.type)}, '
                    '${_dateFor(_context.pending!.occurredOn)}.',
                    style: ZyraText.subtext(size: 12),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const ZyraLoading()
                    : (!_accountCurrent || _loadFailed) && !_reviewEverything
                    ? ZyraEmptyState(
                        icon: Icons.timeline_outlined,
                        title: 'Couldn’t load your timeline',
                        message:
                            'Your Journey history is unavailable right now. Please try again.',
                        ctaLabel: 'Try again',
                        onCta: _load,
                      )
                    : displayMilestones.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: ZyraEmptyState(
                            icon: Icons.timeline_outlined,
                            // 2026-08-13 (ChatGPT review): the stand-in's
                            // empty state is now written for a person, not
                            // for whoever is debugging. Title names the
                            // screen, subtitle says what fills it.
                            title: widget.isMock
                                ? 'Your Journey timeline'
                                : null,
                            message: widget.isMock
                                ? 'Milestones and memories from your Journey '
                                      'will appear here.'
                                : 'No story yet. It begins with your first '
                                      'shared step — your match is usually the '
                                      'first line.',
                          ),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          // CHAPTERS + CONTENT — 2026-08-13 ("timeline is
                          // more than just bullet points"). The flat
                          // milestone rail gains chapter headers named by
                          // the canonical stage map, the questions both
                          // people answered under each finished phase, and
                          // a live door into the Compatibility report on
                          // the reveal entry. The rail, nodes, dates and
                          // quiet-entry treatment are all unchanged.
                          final entries = <Object>[];
                          String? chapter;
                          for (final m in displayMilestones) {
                            final c = _chapterFor(m.type);
                            if (c != null && c != chapter) {
                              chapter = c;
                              entries.add(_TlChapter(c));
                            }
                            entries.add(m);
                          }
                          // THE ROAD — the Journey Map, dissolved into this
                          // rail (2026-08-13). The story runs into a glowing
                          // YOU ARE HERE at the pair's current stage, then
                          // the remaining stages hollow and dimmed. All from
                          // the ONE canonical map; a Paused or Ended Journey
                          // shows the same road frozen where it stopped.
                          final stage = _reviewEverything
                              ? ZyraJourneyStages.of('phase_2')
                              : ZyraJourneyStages.of(_currentStage);
                          final roadShown = stage != null;
                          if (stage != null) {
                            if (_reviewEverything) {
                              entries.add(const _TlChapter('Position preview'));
                            } else if (chapter != stage.label) {
                              entries.add(_TlChapter(stage.label));
                            }
                            final ahead = ZyraJourneyStages.all
                                .where((s) => s.order > stage.order)
                                .toList();
                            entries.add(
                              _TlHere(stage, hasNext: ahead.isNotEmpty),
                            );
                            if (ahead.isNotEmpty) {
                              entries.add(
                                const _TlChapter('The road ahead', dim: true),
                              );
                              for (var i = 0; i < ahead.length; i++) {
                                entries.add(
                                  _TlAhead(
                                    ahead[i],
                                    isLast: i == ahead.length - 1,
                                  ),
                                );
                              }
                            }
                          }
                          final lastMilestone = displayMilestones.isEmpty
                              ? null
                              : displayMilestones.last;
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final e = entries[index];
                              if (e is _TlChapter) {
                                // A chapter header breaks the rail on
                                // purpose — a new part of the story. The
                                // road-ahead header whispers.
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    10,
                                    0,
                                    12,
                                  ),
                                  child: Text(
                                    e.label.toUpperCase(),
                                    style: ZyraText.subtext(
                                      size: 10.5,
                                      color: e.dim
                                          ? ZyraColors.ink(0.35)
                                          : const Color(0xD9CEA2D1),
                                    ).copyWith(letterSpacing: 1.6),
                                  ),
                                );
                              }
                              if (e is _TlHere) {
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: ZyraColors.actionFill,
                                                width: 2,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x40CEA2D1),
                                                  spreadRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (e.hasNext)
                                            Expanded(
                                              child: Container(
                                                width: 1.5,
                                                color: ZyraColors.ink(0.24),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 26,
                                            top: 6,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.stage.label,
                                                style: ZyraText.body(
                                                  size: 14.5,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'In progress',
                                                style: ZyraText.subtext(
                                                  size: 12,
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 9,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: ZyraColors.surfaceFill,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  border: Border.all(
                                                    color: ZyraColors
                                                        .surfaceEmphasisBorder,
                                                  ),
                                                ),
                                                child: Text(
                                                  'YOU ARE HERE · '
                                                  '${e.stage.order} OF '
                                                  '${ZyraJourneyStages.count}',
                                                  style:
                                                      ZyraText.subtext(
                                                        size: 9.5,
                                                        color: const Color(
                                                          0xFFEBD8EE,
                                                        ),
                                                      ).copyWith(
                                                        letterSpacing: 1.1,
                                                      ),
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
                              if (e is _TlAhead) {
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: ZyraColors.foreground
                                                    .withValues(alpha: 0.35),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          if (!e.isLast)
                                            Expanded(
                                              child: Container(
                                                width: 1.5,
                                                color: ZyraColors.foreground
                                                    .withValues(alpha: 0.10),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            bottom: e.isLast ? 8 : 22,
                                            top: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.stage.label,
                                                style: ZyraText.subtext(
                                                  size: 12.5,
                                                  color: const Color(
                                                    0x73FFFFFF,
                                                  ),
                                                ),
                                              ),
                                              // True fact from the canonical
                                              // map's design: free messaging
                                              // genuinely begins at the
                                              // destination stage and
                                              // nowhere earlier.
                                              if (e.stage.value ==
                                                  'conversation') ...[
                                                SizedBox(height: 2),
                                                Text(
                                                  'free messaging begins here',
                                                  style: ZyraText.subtext(
                                                    size: 10,
                                                    color: const Color(
                                                      0x66FFFFFF,
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
                                );
                              }
                              final m = e as ZyraMilestone;
                              final isLast =
                                  identical(m, lastMilestone) && !roadShown;
                              // Quiet entries (pause/continue) shrink and dim:
                              // smaller node, muted label, tighter spacing.
                              final quiet = _isQuiet(m.type);
                              final phase = _phaseOf(m.type);
                              final pairs = _pairsForDisplay(phase);
                              // IntrinsicHeight + an Expanded rail line, so
                              // the rail stretches with tall rows (a phase
                              // carrying its questions) instead of stopping
                              // at a fixed 44pt.
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Column(
                                      children: [
                                        if (quiet) SizedBox(height: 4),
                                        Container(
                                          width: quiet ? 26 : 34,
                                          height: quiet ? 26 : 34,
                                          // Centres the smaller node on the rail.
                                          margin: EdgeInsets.symmetric(
                                            horizontal: quiet ? 4 : 0,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: quiet
                                                ? ZyraColors.foreground
                                                      .withValues(alpha: 0.06)
                                                : ZyraColors.accentBg,
                                            border: Border.all(
                                              color: quiet
                                                  ? ZyraColors.ink(0.24)
                                                  : ZyraColors.accentBorder,
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            _iconFor(m.type),
                                            color: quiet
                                                ? ZyraColors.ink(0.54)
                                                : Colors.white,
                                            size: quiet ? 13 : 16,
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 1.5,
                                              color: ZyraColors.ink(0.24),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          bottom: quiet ? 18 : 26,
                                          top: quiet ? 6 : 6,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _labelFor(m.type),
                                              style: quiet
                                                  ? ZyraText.subtext(
                                                      size: 12.5,
                                                      color: const Color(
                                                        0x99FFFFFF,
                                                      ),
                                                    )
                                                  : ZyraText.body(
                                                      size: 14.5,
                                                      color: Colors.white,
                                                    ),
                                            ),
                                            SizedBox(height: 2),
                                            // "08 August 2026", not
                                            // "8/8/2026" — see _dateFor.
                                            Text(
                                              _dateFor(m.occurredAt),
                                              style: ZyraText.subtext(
                                                size: quiet ? 10.5 : 12,
                                              ),
                                            ),
                                            // THE REVEAL IS A DOOR, not a
                                            // bullet: the same report the
                                            // cards' View Compatibility
                                            // opens, through the
                                            // journeyRevealed path — this
                                            // pair's Journey plainly began.
                                            if (m.type ==
                                                'compatibility_revealed')
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                onTap: () =>
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ProfileUnlockScreen(
                                                              profile: widget
                                                                  .withProfile,
                                                              journeyRevealed:
                                                                  true,
                                                            ),
                                                      ),
                                                    ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                      ),
                                                  child: Text(
                                                    'View the report ›',
                                                    style: ZyraText.subtext(
                                                      size: 12,
                                                      color: const Color(
                                                        0xD9CEA2D1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            // The phase's own words, where
                                            // the phase finished.
                                            if (pairs != null)
                                              for (final p in pairs)
                                                _TimelineQa(
                                                  pair: p,
                                                  theirName: widget
                                                      .withProfile
                                                      .firstName,
                                                  forceOpen: _reviewEverything,
                                                ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app's pill — circular(20), iconButtonBg/iconButtonBorder — as a text
/// bubble.
///
/// DUPLICATED from `_CardPill` in connections_screen.dart, knowingly. Two
/// copies is not yet a shared widget; three is. Noted here so the third
/// person to need one lifts all three into `widgets/` rather than adding a
/// fourth quietly.
// An owned picker/confirmation is allowed to cover its Timeline. Covering
// that child with another route terminally withdraws this particular intent,
// even if the child is later uncovered. Popping the child normally is not a
// cover and preserves the healthy continuation.
class _TimelineOwnedChild extends StatefulWidget {
  const _TimelineOwnedChild({
    required this.current,
    required this.onRoute,
    required this.onCovered,
    required this.child,
  });
  final bool Function() current;
  final ValueChanged<Route<dynamic>?> onRoute;
  final VoidCallback onCovered;
  final Widget child;

  @override
  State<_TimelineOwnedChild> createState() => _TimelineOwnedChildState();
}

class _TimelineOwnedChildState extends State<_TimelineOwnedChild> {
  bool _withdrawn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    widget.onRoute(route);
    if (!_withdrawn &&
        (!widget.current() ||
            (route != null && route.isActive && !route.isCurrent))) {
      _withdrawn = true;
      widget.onCovered();
    }
  }

  @override
  Widget build(BuildContext context) =>
      !_withdrawn && widget.current() ? widget.child : const SizedBox.shrink();
}

class _TimelineBubble extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimelineBubble({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZyraColors.iconButtonBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
          ),
          child: Text(label, style: ZyraText.button(size: 13)),
        ),
      ),
    );
  }
}

/// One question, both answers, folded — the enriched Timeline's content
/// card (2026-08-13). Collapsed it is one line of question; open it shows
/// both answers word for word, YOU first (you know your own words — the
/// reason you tapped is theirs). Rendered only for phases both Seekers
/// sealed, so nothing here outruns what the Journey already opened.
class _TimelineQa extends StatefulWidget {
  final _QaPair pair;
  final String theirName;
  final bool forceOpen;
  const _TimelineQa({
    required this.pair,
    required this.theirName,
    this.forceOpen = false,
  });

  @override
  State<_TimelineQa> createState() => _TimelineQaState();
}

class _TimelineQaState extends State<_TimelineQa> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final open = widget.forceOpen || _open;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: ZyraColors.foreground.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.forceOpen ? null : () => setState(() => _open = !_open),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ZyraColors.foreground.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.pair.question,
                        style: ZyraText.body(size: 12.5, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: ZyraColors.ink(0.54),
                    ),
                  ],
                ),
                if (!open) ...[
                  SizedBox(height: 3),
                  Text(
                    'Both answers — tap to read',
                    style: ZyraText.subtext(
                      size: 10,
                      color: ZyraColors.ink(0.45),
                    ),
                  ),
                ],
                if (open) ...[
                  SizedBox(height: 10),
                  Text(
                    'YOU',
                    style: ZyraText.subtext(
                      size: 9.5,
                      color: const Color(0xD9CEA2D1),
                    ).copyWith(letterSpacing: 1.2),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.pair.mine,
                    style: ZyraText.subtext(
                      size: 12,
                      color: ZyraColors.ink(0.78),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.theirName.toUpperCase(),
                    style: ZyraText.subtext(
                      size: 9.5,
                      color: const Color(0xD9CEA2D1),
                    ).copyWith(letterSpacing: 1.2),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.pair.theirs,
                    style: ZyraText.subtext(
                      size: 12,
                      color: ZyraColors.ink(0.78),
                    ),
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
