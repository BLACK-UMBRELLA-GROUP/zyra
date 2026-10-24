/// Authoritative client representation of the shared Pause decision flow.
///
/// The database owns transitions. The client owns only presentation and the
/// developer preview. A pending request keeps the Journey in the Active slot
/// while locking its content; mutual Pause and its pending resume decision
/// remain outside Active capacity.
enum ZyraPausePhase {
  active('none'),
  pauseDecisionPending('pause_requested'),
  continuationDecisionPending('continue_requested'),
  paused('paused'),
  resumeDecisionPending('resume_requested');

  final String storageValue;
  const ZyraPausePhase(this.storageValue);

  static ZyraPausePhase fromStorage(String? value) => values.firstWhere(
    (phase) => phase.storageValue == value,
    orElse: () => ZyraPausePhase.active,
  );
}

enum ZyraPausePerspective {
  active,
  pauseRequesterWaiting,
  pauseResponderDecision,
  continuationRequesterWaiting,
  continuationResponderDecision,
  mutuallyPaused,
  resumeRequesterWaiting,
  resumeResponderDecision,
}

enum ZyraPauseAction {
  requestPause('request_pause'),
  agreePause('agree_pause'),
  requestContinue('request_continue'),
  continueJourney('continue_journey'),
  confirmPause('confirm_pause'),
  requestResume('request_resume'),
  agreeResume('agree_resume'),
  keepPaused('keep_paused');

  final String storageValue;
  const ZyraPauseAction(this.storageValue);
}

/// The developer control's complete Pause-flow matrix. Basic/ZYRA One is an
/// independent account-plan axis in Developer Access, so every scenario can
/// be reviewed under both entitlements without duplicating fake states.
enum ZyraPauseDevScenario {
  active('Active'),
  pauseRequesterWaiting('Pause · requester waiting'),
  pauseResponderDecision('Pause · decision'),
  continuationRequesterWaiting('Continue · requester waiting'),
  continuationResponderDecision('Continue · decision'),
  mutuallyPaused('Mutually paused'),
  resumeRequesterWaiting('Resume · requester waiting'),
  resumeResponderDecision('Resume · decision'),
  resumedActive('Resumed / active'),
  endedFromPause('Ended from Pause'),
  deadlineApproaching('Deadline approaching'),
  deadlineExpired('Deadline expired'),
  pausedCapacityConflict('Paused-cap conflict');

  final String label;
  const ZyraPauseDevScenario(this.label);

  bool get isEnded => this == endedFromPause;

  static ZyraPauseDevScenario fromState(
    ZyraJourneyPauseState state,
    String viewerId,
  ) => _fromPerspective(state.perspectiveFor(viewerId));

  static ZyraPauseDevScenario _fromPerspective(
    ZyraPausePerspective perspective,
  ) => switch (perspective) {
    ZyraPausePerspective.active => ZyraPauseDevScenario.resumedActive,
    ZyraPausePerspective.pauseRequesterWaiting =>
      ZyraPauseDevScenario.pauseRequesterWaiting,
    ZyraPausePerspective.pauseResponderDecision =>
      ZyraPauseDevScenario.pauseResponderDecision,
    ZyraPausePerspective.continuationRequesterWaiting =>
      ZyraPauseDevScenario.continuationRequesterWaiting,
    ZyraPausePerspective.continuationResponderDecision =>
      ZyraPauseDevScenario.continuationResponderDecision,
    ZyraPausePerspective.mutuallyPaused => ZyraPauseDevScenario.mutuallyPaused,
    ZyraPausePerspective.resumeRequesterWaiting =>
      ZyraPauseDevScenario.resumeRequesterWaiting,
    ZyraPausePerspective.resumeResponderDecision =>
      ZyraPauseDevScenario.resumeResponderDecision,
  };

  ZyraJourneyPauseState stateFor({
    required String viewerId,
    required String otherId,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return switch (this) {
      active || resumedActive || endedFromPause => ZyraJourneyPauseState.active,
      pauseRequesterWaiting => ZyraJourneyPauseState(
        phase: ZyraPausePhase.pauseDecisionPending,
        initiatedBy: viewerId,
        requestedBy: viewerId,
        requestedAt: at,
        version: 1,
      ),
      pauseResponderDecision => ZyraJourneyPauseState(
        phase: ZyraPausePhase.pauseDecisionPending,
        initiatedBy: otherId,
        requestedBy: otherId,
        requestedAt: at,
        version: 1,
      ),
      continuationRequesterWaiting => ZyraJourneyPauseState(
        phase: ZyraPausePhase.continuationDecisionPending,
        initiatedBy: otherId,
        requestedBy: viewerId,
        requestedAt: at,
        version: 2,
      ),
      continuationResponderDecision => ZyraJourneyPauseState(
        phase: ZyraPausePhase.continuationDecisionPending,
        initiatedBy: viewerId,
        requestedBy: otherId,
        requestedAt: at,
        version: 2,
      ),
      mutuallyPaused => ZyraJourneyPauseState(
        phase: ZyraPausePhase.paused,
        initiatedBy: viewerId,
        version: 2,
      ),
      resumeRequesterWaiting => ZyraJourneyPauseState(
        phase: ZyraPausePhase.resumeDecisionPending,
        initiatedBy: viewerId,
        requestedBy: viewerId,
        requestedAt: at,
        version: 3,
      ),
      resumeResponderDecision => ZyraJourneyPauseState(
        phase: ZyraPausePhase.resumeDecisionPending,
        initiatedBy: otherId,
        requestedBy: otherId,
        requestedAt: at,
        version: 3,
      ),
      deadlineApproaching => ZyraJourneyPauseState(
        phase: ZyraPausePhase.pauseDecisionPending,
        initiatedBy: otherId,
        requestedBy: otherId,
        requestedAt: at.subtract(const Duration(hours: 12)),
        deadlineAt: at.add(const Duration(minutes: 45)),
        version: 1,
      ),
      deadlineExpired => ZyraJourneyPauseState(
        phase: ZyraPausePhase.pauseDecisionPending,
        initiatedBy: otherId,
        requestedBy: otherId,
        requestedAt: at.subtract(const Duration(days: 2)),
        deadlineAt: at.subtract(const Duration(minutes: 5)),
        version: 1,
      ),
      pausedCapacityConflict => ZyraJourneyPauseState(
        phase: ZyraPausePhase.pauseDecisionPending,
        initiatedBy: otherId,
        requestedBy: otherId,
        requestedAt: at,
        version: 1,
        capacityBlocked: true,
      ),
    };
  }
}

class ZyraJourneyPauseState {
  final ZyraPausePhase phase;

  /// The person who opened the current pause episode.
  final String? initiatedBy;

  /// The person who made the request currently awaiting an answer.
  final String? requestedBy;
  final DateTime? requestedAt;
  final DateTime? deadlineAt;
  final int version;

  /// Preview/transient refusal only. Capacity failures do not mutate the
  /// database state, so this flag is never persisted as a second truth.
  final bool capacityBlocked;

  const ZyraJourneyPauseState({
    this.phase = ZyraPausePhase.active,
    this.initiatedBy,
    this.requestedBy,
    this.requestedAt,
    this.deadlineAt,
    this.version = 0,
    this.capacityBlocked = false,
  });

  static const active = ZyraJourneyPauseState();

  factory ZyraJourneyPauseState.fromStorage({
    required String? phase,
    required String? initiatedBy,
    required String? requestedBy,
    required Object? requestedAt,
    required Object? deadlineAt,
    required Object? version,
  }) => ZyraJourneyPauseState(
    phase: ZyraPausePhase.fromStorage(phase),
    initiatedBy: initiatedBy,
    requestedBy: requestedBy,
    requestedAt: _date(requestedAt),
    deadlineAt: _date(deadlineAt),
    version: (version as num?)?.toInt() ?? 0,
  );

  static DateTime? _date(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool get isLocked => phase != ZyraPausePhase.active;
  bool get isPaused =>
      phase == ZyraPausePhase.paused ||
      phase == ZyraPausePhase.resumeDecisionPending;
  bool get isPending => switch (phase) {
    ZyraPausePhase.pauseDecisionPending ||
    ZyraPausePhase.continuationDecisionPending ||
    ZyraPausePhase.resumeDecisionPending => true,
    _ => false,
  };

  /// Pending decisions still occupy Active capacity. Mutual Pause does not.
  bool get countsAsActiveSlot => !isPaused;

  bool get deadlineExpired =>
      deadlineAt != null && !DateTime.now().isBefore(deadlineAt!);

  bool deadlineApproaching({Duration threshold = const Duration(hours: 6)}) {
    if (deadlineAt == null || deadlineExpired) return false;
    return deadlineAt!.difference(DateTime.now()) <= threshold;
  }

  ZyraPausePerspective perspectiveFor(String? currentUserId) {
    final mine = currentUserId != null && requestedBy == currentUserId;
    return switch (phase) {
      ZyraPausePhase.active => ZyraPausePerspective.active,
      ZyraPausePhase.pauseDecisionPending =>
        mine
            ? ZyraPausePerspective.pauseRequesterWaiting
            : ZyraPausePerspective.pauseResponderDecision,
      ZyraPausePhase.continuationDecisionPending =>
        mine
            ? ZyraPausePerspective.continuationRequesterWaiting
            : ZyraPausePerspective.continuationResponderDecision,
      ZyraPausePhase.paused => ZyraPausePerspective.mutuallyPaused,
      ZyraPausePhase.resumeDecisionPending =>
        mine
            ? ZyraPausePerspective.resumeRequesterWaiting
            : ZyraPausePerspective.resumeResponderDecision,
    };
  }

  ZyraJourneyPauseState copyWith({
    ZyraPausePhase? phase,
    String? initiatedBy,
    String? requestedBy,
    DateTime? requestedAt,
    DateTime? deadlineAt,
    int? version,
    bool? capacityBlocked,
    bool clearRequestedBy = false,
    bool clearTiming = false,
  }) => ZyraJourneyPauseState(
    phase: phase ?? this.phase,
    initiatedBy: initiatedBy ?? this.initiatedBy,
    requestedBy: clearRequestedBy ? null : requestedBy ?? this.requestedBy,
    requestedAt: clearTiming ? null : requestedAt ?? this.requestedAt,
    deadlineAt: clearTiming ? null : deadlineAt ?? this.deadlineAt,
    version: version ?? this.version,
    capacityBlocked: capacityBlocked ?? this.capacityBlocked,
  );
}

/// Pure transition rules used by tests and the developer scenario.
/// Production writes always go through the atomic database RPC.
abstract final class ZyraJourneyPausePolicy {
  static bool canApply({
    required ZyraJourneyPauseState state,
    required ZyraPauseAction action,
    required String actorId,
    required String otherId,
  }) => switch ((state.phase, action)) {
    (ZyraPausePhase.active, ZyraPauseAction.requestPause) => true,
    (ZyraPausePhase.pauseDecisionPending, ZyraPauseAction.agreePause) ||
    (
      ZyraPausePhase.pauseDecisionPending,
      ZyraPauseAction.requestContinue,
    ) => state.requestedBy == otherId,
    (
      ZyraPausePhase.continuationDecisionPending,
      ZyraPauseAction.continueJourney,
    ) ||
    (
      ZyraPausePhase.continuationDecisionPending,
      ZyraPauseAction.confirmPause,
    ) => state.requestedBy == otherId,
    (ZyraPausePhase.paused, ZyraPauseAction.requestResume) => true,
    (ZyraPausePhase.resumeDecisionPending, ZyraPauseAction.agreeResume) ||
    (
      ZyraPausePhase.resumeDecisionPending,
      ZyraPauseAction.keepPaused,
    ) => state.requestedBy == otherId,
    _ => false,
  };

  static ZyraJourneyPauseState apply({
    required ZyraJourneyPauseState state,
    required ZyraPauseAction action,
    required String actorId,
    required String otherId,
    DateTime? now,
    DateTime? deadlineAt,
  }) {
    if (!canApply(
      state: state,
      action: action,
      actorId: actorId,
      otherId: otherId,
    )) {
      throw StateError('pause_transition_not_allowed');
    }
    final at = now ?? DateTime.now();
    final nextVersion = state.version + 1;
    return switch (action) {
      ZyraPauseAction.requestPause => ZyraJourneyPauseState(
        phase: ZyraPausePhase.pauseDecisionPending,
        initiatedBy: actorId,
        requestedBy: actorId,
        requestedAt: at,
        deadlineAt: deadlineAt,
        version: nextVersion,
      ),
      ZyraPauseAction.agreePause ||
      ZyraPauseAction.confirmPause => ZyraJourneyPauseState(
        phase: ZyraPausePhase.paused,
        initiatedBy: state.initiatedBy,
        version: nextVersion,
      ),
      ZyraPauseAction.requestContinue => ZyraJourneyPauseState(
        phase: ZyraPausePhase.continuationDecisionPending,
        initiatedBy: state.initiatedBy,
        requestedBy: actorId,
        requestedAt: at,
        deadlineAt: deadlineAt,
        version: nextVersion,
      ),
      ZyraPauseAction.continueJourney || ZyraPauseAction.agreeResume =>
        ZyraJourneyPauseState(version: nextVersion),
      ZyraPauseAction.requestResume => ZyraJourneyPauseState(
        phase: ZyraPausePhase.resumeDecisionPending,
        initiatedBy: state.initiatedBy,
        requestedBy: actorId,
        requestedAt: at,
        deadlineAt: deadlineAt,
        version: nextVersion,
      ),
      ZyraPauseAction.keepPaused => ZyraJourneyPauseState(
        phase: ZyraPausePhase.paused,
        initiatedBy: state.initiatedBy,
        version: nextVersion,
      ),
    };
  }
}
