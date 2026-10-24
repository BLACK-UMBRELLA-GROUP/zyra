// Detached, fictional Timeline review values. No member data, admission,
// service, pending server operation or Journey mutation belongs here.
import '../data/journey_questions.dart';
import '../data/zyra_journey_stages.dart';
import '../data/zyra_timeline_milestones.dart';
import 'zyra_view_request_draft_model.dart'
    show DraftJourneyState, DraftEndedJourneyAttempt;

enum ZyraDraftTimelineScenario {
  current('Current Journey'),
  allEvents('All events'),
  event('One event'),
  stage('Journey position'),
  empty('Empty'),
  loading('Loading'),
  unavailable('Unavailable'),
  answersLocked('Answers private'),
  answersRevealed('Answers revealed'),
  meetingWaiting('Meeting · waiting'),
  meetingToConfirm('Meeting · confirm'),
  meetingConfirming('Meeting · confirming'),
  meetingConfirmed('Meeting · recorded'),
  nikahWaiting('Nikah · waiting'),
  nikahToConfirm('Nikah · confirm'),
  nikahConfirming('Nikah · confirming'),
  nikahConfirmed('Nikah · recorded');

  const ZyraDraftTimelineScenario(this.label);
  final String label;
}

enum ZyraDraftTimelineStatus { ready, loading, unavailable }

enum ZyraDraftTimelinePendingState {
  waitingForPeer,
  needsConfirmation,
  confirming,
}

class ZyraDraftTimelineAnswer {
  const ZyraDraftTimelineAnswer({
    required this.questionId,
    required this.question,
    required this.mine,
    required this.theirs,
  });
  final String questionId, question, mine, theirs;
}

class ZyraDraftTimelineEntry {
  ZyraDraftTimelineEntry({
    required this.type,
    this.occurredOn,
    this.showAnswers = false,
    this.answersRevealed = false,
    this.forceAnswersOpen = false,
    this.invitationAccepted = false,
    this.attemptId,
    this.attemptNumber,
    Iterable<ZyraDraftTimelineAnswer> answers = const [],
  }) : answers = List.unmodifiable(answers) {
    if (!ZyraTimelineMilestones.isSupported(type)) {
      throw ArgumentError.value(type, 'type', 'Unsupported shared milestone');
    }
    if (invitationAccepted && type != 'match_created') {
      throw ArgumentError('Invitation acceptance must project a mutual match.');
    }
  }
  final String type;
  // Explicit calendar date only. Null means the draft has no dated fact;
  // callers must not manufacture a real-history date from the current clock.
  final DateTime? occurredOn;
  final bool showAnswers, answersRevealed, forceAnswersOpen;
  final bool invitationAccepted;
  final String? attemptId;
  final int? attemptNumber;
  final List<ZyraDraftTimelineAnswer> answers;
}

class ZyraDraftTimelinePending {
  ZyraDraftTimelinePending({
    required this.type,
    required this.occurredOn,
    required this.state,
  }) {
    if (type != 'meeting' && type != 'nikah') {
      throw ArgumentError.value(type, 'type', 'Unsupported mutual milestone');
    }
  }
  final String type;
  final DateTime occurredOn;
  final ZyraDraftTimelinePendingState state;
}

class ZyraDraftTimelineView {
  ZyraDraftTimelineView({
    Iterable<ZyraDraftTimelineEntry> entries = const [],
    this.status = ZyraDraftTimelineStatus.ready,
    String? currentStageValue,
    this.frozen = false,
    this.pending,
    this.canPropose = false,
    this.compatibilityRevealed = false,
  }) : entries = List.unmodifiable(entries),
       currentStageValue = ZyraJourneyStages.of(currentStageValue)?.value;

  final List<ZyraDraftTimelineEntry> entries;
  final ZyraDraftTimelineStatus status;
  final String? currentStageValue;
  final bool frozen, canPropose, compatibilityRevealed;
  final ZyraDraftTimelinePending? pending;
}

class ZyraDraftTimelinePreview {
  ZyraDraftTimelinePreview(
    this.subjectId, {
    required this.firstName,
    this.journeyState,
    String? stageValue,
    this.compatibilityRevealed = false,
    Iterable<DraftEndedJourneyAttempt> endedAttempts = const [],
  }) : endedAttempts = List.unmodifiable(endedAttempts),
       _stageValue = ZyraJourneyStages.of(stageValue)?.value,
       _selectedStage = ZyraJourneyStages.of(stageValue)?.value ?? 'phase_2';

  final String subjectId, firstName;
  final DraftJourneyState? journeyState;
  final String? _stageValue;
  final bool compatibilityRevealed;
  final List<DraftEndedJourneyAttempt> endedAttempts;
  ZyraDraftTimelineScenario _scenario = ZyraDraftTimelineScenario.current;
  String _selectedEvent = 'journey_started';
  String _selectedStage;
  bool _pendingDismissed = false;

  ZyraDraftTimelineScenario get scenario => _scenario;
  String get selectedEvent => _selectedEvent;
  String get selectedStage => _selectedStage;

  bool selectScenario(ZyraDraftTimelineScenario value) {
    if (_scenario == value && !_pendingDismissed) return false;
    _scenario = value;
    _pendingDismissed = false;
    return true;
  }

  bool selectEvent(String type) {
    if (!ZyraTimelineMilestones.isSupported(type)) return false;
    _selectedEvent = type;
    _scenario = ZyraDraftTimelineScenario.event;
    _pendingDismissed = false;
    return true;
  }

  bool selectStage(String value) {
    if (ZyraJourneyStages.of(value) == null) return false;
    _selectedStage = value;
    _scenario = ZyraDraftTimelineScenario.stage;
    _pendingDismissed = false;
    return true;
  }

  bool retry() =>
      _scenario == ZyraDraftTimelineScenario.unavailable &&
      selectScenario(ZyraDraftTimelineScenario.current);

  bool propose(String type) {
    if (!view.canPropose || (type != 'meeting' && type != 'nikah')) {
      return false;
    }
    return selectScenario(
      type == 'meeting'
          ? ZyraDraftTimelineScenario.meetingWaiting
          : ZyraDraftTimelineScenario.nikahWaiting,
    );
  }

  bool confirm() {
    final pending = view.pending;
    if (pending?.state != ZyraDraftTimelinePendingState.needsConfirmation) {
      return false;
    }
    return selectScenario(
      pending!.type == 'meeting'
          ? ZyraDraftTimelineScenario.meetingConfirmed
          : ZyraDraftTimelineScenario.nikahConfirmed,
    );
  }

  bool notYet() {
    if (view.pending?.state !=
        ZyraDraftTimelinePendingState.needsConfirmation) {
      return false;
    }
    _pendingDismissed = true;
    return true;
  }

  static DateTime _fixtureDate(int index) => DateTime(2026, 9, 1 + index * 2);

  static int? _phaseOf(String type) => switch (type) {
    'phase_1_complete' => 1,
    'phase_2_complete' => 2,
    'phase_3_complete' => 3,
    _ => null,
  };

  static ZyraDraftTimelineEntry _reviewEntry(
    String type,
    int index, {
    bool revealed = false,
    bool forceOpen = false,
  }) {
    final phase = _phaseOf(type);
    final bank = phase == null
        ? const <JourneyQuestion>[]
        : JourneyQuestions.forPhase(phase);
    return ZyraDraftTimelineEntry(
      type: type,
      occurredOn: _fixtureDate(index),
      showAnswers: phase != null,
      answersRevealed: revealed,
      forceAnswersOpen: forceOpen,
      answers: !revealed || bank.isEmpty
          ? const []
          : [
              ZyraDraftTimelineAnswer(
                questionId: bank.first.id,
                question: bank.first.text,
                mine:
                    'I value a thoughtful, honest approach and making decisions together.',
                theirs:
                    'I hope we can listen with care and support one another as we grow.',
              ),
            ],
    );
  }

  List<ZyraDraftTimelineEntry> _facts() {
    final state = journeyState;
    if (state == null ||
        state == DraftJourneyState.received ||
        state == DraftJourneyState.sent) {
      return const [];
    }
    final entries = <ZyraDraftTimelineEntry>[
      ZyraDraftTimelineEntry(type: 'match_created', invitationAccepted: true),
    ];
    if (state == DraftJourneyState.preparing) return entries;
    entries.addAll([
      ZyraDraftTimelineEntry(type: 'journey_started'),
      for (final stage in ZyraJourneyStages.completedBefore(_stageValue))
        if (stage.value != 'compatibility_reveal' || compatibilityRevealed)
          ZyraDraftTimelineEntry(type: stage.timelineMilestoneType),
    ]);
    if (_stageValue == 'compatibility_reveal' && compatibilityRevealed) {
      entries.add(ZyraDraftTimelineEntry(type: 'compatibility_revealed'));
    }
    if (_stageValue == 'conversation') {
      entries.add(ZyraDraftTimelineEntry(type: 'conversation_started'));
    }
    if (state == DraftJourneyState.paused) {
      entries.add(ZyraDraftTimelineEntry(type: 'journey_paused'));
    }
    if (state == DraftJourneyState.ended) {
      entries.add(ZyraDraftTimelineEntry(type: 'journey_ended'));
    }
    return entries;
  }

  List<ZyraDraftTimelineEntry> _historyFacts() {
    final entries = <ZyraDraftTimelineEntry>[];
    for (var index = 0; index < endedAttempts.length; index++) {
      final attempt = endedAttempts[index];
      if (attempt.profileId != subjectId) continue;
      final progress = attempt.progress;
      final projection = ZyraDraftTimelinePreview(
        subjectId,
        firstName: firstName,
        journeyState: DraftJourneyState.ended,
        stageValue: ZyraJourneyStages.all[progress.stageIndex].value,
        compatibilityRevealed:
            progress.compatibilityConsent && progress.peerCompatibilityConsent,
      );
      for (final fact in projection._facts()) {
        entries.add(
          ZyraDraftTimelineEntry(
            type: fact.type,
            occurredOn: fact.type == 'journey_ended'
                ? attempt.endedAt
                : fact.type == 'journey_started'
                ? attempt.startedAt
                : null,
            invitationAccepted: fact.invitationAccepted,
            attemptId: attempt.id,
            attemptNumber: index + 1,
          ),
        );
      }
    }
    // An active fresh attempt keeps its own fresh progress, never an older
    // attempt's consent. No private answer retention policy is changed here.
    if (journeyState != DraftJourneyState.ended) entries.addAll(_facts());
    return entries;
  }

  ZyraDraftTimelineView get view {
    final scenario = _scenario;
    if (scenario == ZyraDraftTimelineScenario.current) {
      final frozen =
          journeyState == DraftJourneyState.ended ||
          journeyState == DraftJourneyState.paused;
      final entries = endedAttempts.isEmpty ? _facts() : _historyFacts();
      return ZyraDraftTimelineView(
        entries: entries,
        currentStageValue:
            entries.isEmpty || journeyState == DraftJourneyState.preparing
            ? null
            : _stageValue,
        frozen: frozen,
        canPropose: journeyState == DraftJourneyState.active,
        compatibilityRevealed: compatibilityRevealed,
      );
    }
    if (scenario == ZyraDraftTimelineScenario.empty) {
      return ZyraDraftTimelineView();
    }
    if (scenario == ZyraDraftTimelineScenario.loading) {
      return ZyraDraftTimelineView(status: ZyraDraftTimelineStatus.loading);
    }
    if (scenario == ZyraDraftTimelineScenario.unavailable) {
      return ZyraDraftTimelineView(status: ZyraDraftTimelineStatus.unavailable);
    }
    if (scenario == ZyraDraftTimelineScenario.allEvents) {
      return ZyraDraftTimelineView(
        entries: [
          for (var i = 0; i < ZyraTimelineMilestones.supportedTypes.length; i++)
            _reviewEntry(
              ZyraTimelineMilestones.supportedTypes[i],
              i,
              revealed: true,
              forceOpen: true,
            ),
        ],
        currentStageValue: _selectedStage,
        compatibilityRevealed: true,
      );
    }
    if (scenario == ZyraDraftTimelineScenario.event) {
      return ZyraDraftTimelineView(
        entries: [_reviewEntry(_selectedEvent, 3)],
        compatibilityRevealed: _selectedEvent == 'compatibility_revealed',
      );
    }
    if (scenario == ZyraDraftTimelineScenario.stage) {
      final stage = ZyraJourneyStages.of(_selectedStage)!;
      return ZyraDraftTimelineView(
        entries: [
          _reviewEntry('journey_started', 0),
          for (final previous in ZyraJourneyStages.completedBefore(stage.value))
            _reviewEntry(previous.timelineMilestoneType, previous.order),
        ],
        currentStageValue: stage.value,
        compatibilityRevealed: stage.order > 2,
      );
    }
    if (scenario == ZyraDraftTimelineScenario.answersLocked ||
        scenario == ZyraDraftTimelineScenario.answersRevealed) {
      return ZyraDraftTimelineView(
        entries: [
          _reviewEntry(
            'phase_1_complete',
            5,
            revealed: scenario == ZyraDraftTimelineScenario.answersRevealed,
          ),
        ],
        currentStageValue: 'phase_2',
      );
    }
    final nikah = {
      ZyraDraftTimelineScenario.nikahWaiting,
      ZyraDraftTimelineScenario.nikahToConfirm,
      ZyraDraftTimelineScenario.nikahConfirming,
      ZyraDraftTimelineScenario.nikahConfirmed,
    }.contains(scenario);
    final type = nikah ? 'nikah' : 'meeting';
    final confirmed =
        scenario == ZyraDraftTimelineScenario.meetingConfirmed ||
        scenario == ZyraDraftTimelineScenario.nikahConfirmed;
    final waiting =
        scenario == ZyraDraftTimelineScenario.meetingWaiting ||
        scenario == ZyraDraftTimelineScenario.nikahWaiting;
    final confirming =
        scenario == ZyraDraftTimelineScenario.meetingConfirming ||
        scenario == ZyraDraftTimelineScenario.nikahConfirming;
    return ZyraDraftTimelineView(
      entries: [
        _reviewEntry('journey_started', 0),
        _reviewEntry('conversation_started', 9),
        if (confirmed) _reviewEntry(type, 12),
      ],
      currentStageValue: 'conversation',
      pending: confirmed || _pendingDismissed
          ? null
          : ZyraDraftTimelinePending(
              type: type,
              occurredOn: _fixtureDate(12),
              state: waiting
                  ? ZyraDraftTimelinePendingState.waitingForPeer
                  : confirming
                  ? ZyraDraftTimelinePendingState.confirming
                  : ZyraDraftTimelinePendingState.needsConfirmation,
            ),
    );
  }
}
