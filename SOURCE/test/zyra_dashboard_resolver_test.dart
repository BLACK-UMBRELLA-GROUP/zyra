import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';

void main() {
  const resolver = DashboardResolver();
  const failure = DashboardFailure(code: 'network');
  const searching = DashboardJourneySummary(
    id: 'searching',
    kind: DashboardJourneyKind.searching,
    title: 'Ready for introductions',
  );
  const stable = DashboardStableState(
    orientationItems: DashboardSource.available([]),
    family: DashboardSource.available(
      DashboardFamilyStatus(
        kind: DashboardFamilyKind.notConnected,
        title: 'No Guardian connected',
      ),
    ),
  );

  DashboardSignal signal(
    String id,
    DashboardSignalKind kind, {
    DateTime? dueAt,
    DateTime? eventAt,
    ZyraDashboardTarget target = ZyraDashboardTarget.connectionsJourneys,
  }) => DashboardSignal(
    id: id,
    kind: kind,
    title: 'Title $id',
    detail: 'Detail $id',
    actionLabel: 'Open',
    target: target,
    dueAt: dueAt,
    eventAt: eventAt,
  );

  DashboardSnapshot snapshot({
    DashboardRole role = DashboardRole.seeker,
    DashboardSource<List<DashboardSignal>> onboarding =
        const DashboardSource.available([]),
    DashboardSource<DashboardJourneyState> journeys =
        const DashboardSource.available(
          DashboardJourneyState(summary: searching),
        ),
    DashboardSource<List<DashboardSignal>> updates =
        const DashboardSource.available([]),
    DashboardSource<List<DashboardSignal>> guardianInvitations =
        const DashboardSource.available([]),
    DashboardSource<List<DashboardSignal>> insights =
        const DashboardSource.available([]),
    DashboardSource<List<DashboardAdvisory>> advisories =
        const DashboardSource.available([]),
    DashboardStableState stableState = stable,
  }) => DashboardSnapshot(
    role: role,
    onboarding: onboarding,
    journeys: journeys,
    updates: updates,
    guardianInvitations: guardianInvitations,
    insights: insights,
    advisories: advisories,
    stableState: stableState,
  );

  group('DashboardSource', () {
    test('preserves loading, successful empty and unavailable', () {
      const loading = DashboardSource<List<int>>.loading();
      const empty = DashboardSource<List<int>>.available([]);
      const unavailable = DashboardSource<List<int>>.unavailable(failure);

      expect(loading.state, DashboardSourceState.loading);
      expect(loading.valueOrNull, isNull);
      expect(empty.state, DashboardSourceState.available);
      expect(empty.valueOrNull, isEmpty);
      expect(unavailable.state, DashboardSourceState.unavailable);
      expect(unavailable.failureOrNull?.code, 'network');
    });
  });

  group('priority and retention', () {
    test('one hero retains every simultaneous obligation in order', () {
      final deadline = signal(
        'deadline',
        DashboardSignalKind.deadlineDecision,
        dueAt: DateTime.utc(2026, 8, 29),
      );
      final gate = signal('gate', DashboardSignalKind.blockingGate);
      final decision = signal(
        'decision',
        DashboardSignalKind.addressedDecision,
      );
      final ownMove = signal('own-move', DashboardSignalKind.ownJourneyMove);
      final result = resolver.resolve(
        snapshot(
          onboarding: DashboardSource.available([gate]),
          journeys: DashboardSource.available(
            DashboardJourneyState(summary: searching, signals: [ownMove]),
          ),
          updates: DashboardSource.available([decision]),
          guardianInvitations: DashboardSource.available([deadline]),
        ),
      );

      expect(result.answer.kind, DashboardAnswerKind.signal);
      expect(result.answer.item?.signal.id, 'deadline');
      expect(result.otherActions.map((item) => item.signal.id), [
        'gate',
        'decision',
        'own-move',
      ]);
      expect(result.tone, DashboardTone.needsYou);
      expect(result.sourceHealth, DashboardSourceHealth.complete);
      expect(result.updatesState, DashboardSectionState.available);
      expect(result.insightsState, DashboardSectionState.available);
    });

    test('earliest real expiry wins within deadline decisions', () {
      final later = signal(
        'later',
        DashboardSignalKind.deadlineDecision,
        dueAt: DateTime.utc(2026, 9, 2),
      );
      final sooner = signal(
        'sooner',
        DashboardSignalKind.deadlineDecision,
        dueAt: DateTime.utc(2026, 8, 30),
      );

      final result = resolver.resolve(
        snapshot(
          guardianInvitations: DashboardSource.available([later, sooner]),
        ),
      );

      expect(result.answer.item?.signal.id, 'sooner');
      expect(result.otherActions.single.signal.id, 'later');
    });

    test('blocking gate beats decision, own move and movement', () {
      final result = resolver.resolve(
        snapshot(
          onboarding: DashboardSource.available([
            signal('gate', DashboardSignalKind.blockingGate),
          ]),
          journeys: DashboardSource.available(
            DashboardJourneyState(
              summary: searching,
              signals: [signal('own', DashboardSignalKind.ownJourneyMove)],
            ),
          ),
          updates: DashboardSource.available([
            signal('decision', DashboardSignalKind.addressedDecision),
            signal('movement', DashboardSignalKind.meaningfulMovement),
          ]),
        ),
      );

      expect(result.answer.item?.signal.id, 'gate');
      expect(result.otherActions.map((item) => item.signal.id), [
        'decision',
        'own',
      ]);
      expect(result.worthKnowing.single.signal.id, 'movement');
    });

    test('own Active Journey move beats unread meaningful movement', () {
      final result = resolver.resolve(
        snapshot(
          journeys: DashboardSource.available(
            DashboardJourneyState(
              summary: searching,
              signals: [signal('own', DashboardSignalKind.ownJourneyMove)],
            ),
          ),
          updates: DashboardSource.available([
            signal('movement', DashboardSignalKind.meaningfulMovement),
          ]),
        ),
      );

      expect(result.answer.item?.signal.id, 'own');
      expect(result.worthKnowing.single.signal.id, 'movement');
    });

    test(
      'a Today headline remains in its canonical Updates or Insights tab',
      () {
        final movement = signal(
          'movement',
          DashboardSignalKind.meaningfulMovement,
        );
        final movementResult = resolver.resolve(
          snapshot(updates: DashboardSource.available([movement])),
        );

        expect(movementResult.answer.item?.signal.id, 'movement');
        expect(movementResult.recently.single.signal.id, 'movement');

        final insight = signal('insight', DashboardSignalKind.governedInsight);
        final insightResult = resolver.resolve(
          snapshot(insights: DashboardSource.available([insight])),
        );

        expect(insightResult.answer.item?.signal.id, 'insight');
        expect(insightResult.intelligence.single.signal.id, 'insight');
      },
    );

    test('ties are class, due, event then stable id', () {
      final time = DateTime.utc(2026, 8, 28, 12);
      final older = signal(
        'z-older',
        DashboardSignalKind.addressedDecision,
        eventAt: time.subtract(const Duration(hours: 1)),
      );
      final alpha = signal(
        'a-same',
        DashboardSignalKind.addressedDecision,
        eventAt: time,
      );
      final beta = signal(
        'b-same',
        DashboardSignalKind.addressedDecision,
        eventAt: time,
      );

      final result = resolver.resolve(
        snapshot(updates: DashboardSource.available([beta, alpha, older])),
      );

      expect(result.answer.item?.signal.id, 'z-older');
      expect(result.otherActions.map((item) => item.signal.id), [
        'a-same',
        'b-same',
      ]);
    });

    test('repeated passive resolution never demotes the hero', () {
      final input = snapshot(
        updates: DashboardSource.available([
          signal('first', DashboardSignalKind.addressedDecision),
          signal('second', DashboardSignalKind.addressedDecision),
        ]),
      );

      final firstRead = resolver.resolve(input);
      final tenthPassiveRead = List.generate(
        9,
        (_) => resolver.resolve(input),
      ).last;

      expect(firstRead.answer.item?.signal.id, 'first');
      expect(tenthPassiveRead.answer.item?.signal.id, 'first');
      expect(tenthPassiveRead.otherActions.map((item) => item.signal.id), [
        'second',
      ]);
    });

    test('same object from two sources is resolved once at highest rank', () {
      final result = resolver.resolve(
        snapshot(
          journeys: DashboardSource.available(
            DashboardJourneyState(
              summary: searching,
              signals: [signal('match-1', DashboardSignalKind.ownJourneyMove)],
            ),
          ),
          updates: DashboardSource.available([
            signal('match-1', DashboardSignalKind.meaningfulMovement),
          ]),
        ),
      );

      expect(result.answer.item?.signal.id, 'match-1');
      expect(
        result.answer.item?.signal.kind,
        DashboardSignalKind.ownJourneyMove,
      );
      expect(result.otherActions, isEmpty);
      expect(result.worthKnowing, isEmpty);
    });
  });

  group('advisory and calm output', () {
    test('governed insight can lead and intelligence is capped at three', () {
      final insights = [
        for (var i = 0; i < 5; i++)
          signal(
            'insight-$i',
            DashboardSignalKind.governedInsight,
            eventAt: DateTime.utc(2026, 8, 20 + i),
            target: ZyraDashboardTarget.preferences,
          ),
      ];

      final result = resolver.resolve(
        snapshot(insights: DashboardSource.available(insights)),
      );

      expect(result.answer.item?.signal.id, 'insight-0');
      expect(result.answer.item?.signal.actionLabel, 'Open');
      expect(
        result.answer.item?.signal.target,
        ZyraDashboardTarget.preferences,
      );
      expect(result.intelligence.map((item) => item.signal.id), [
        'insight-4',
        'insight-3',
        'insight-2',
      ]);
      expect(result.tone, DashboardTone.moving);
    });

    test('calm advisory is used only when no ranked signal remains', () {
      const advisory = DashboardAdvisory(
        id: 'review-preferences',
        title: 'Review your preferences',
        why: 'There are no Potential Journeys to review right now.',
        actionLabel: 'Review preferences',
        target: ZyraDashboardTarget.preferences,
      );
      final calm = resolver.resolve(
        snapshot(advisories: const DashboardSource.available([advisory])),
      );
      final moving = resolver.resolve(
        snapshot(
          updates: DashboardSource.available([
            signal('movement', DashboardSignalKind.meaningfulMovement),
          ]),
          advisories: const DashboardSource.available([advisory]),
        ),
      );

      expect(calm.answer.kind, DashboardAnswerKind.calmAdvisory);
      expect(calm.answer.advisory, same(advisory));
      expect(calm.answer.advisory?.why, isNotEmpty);
      expect(moving.answer.kind, DashboardAnswerKind.signal);
      expect(moving.answer.item?.signal.id, 'movement');
      expect(moving.answer.advisory, isNull);
    });

    test('selected movement is not duplicated in Recently', () {
      final result = resolver.resolve(
        snapshot(
          updates: DashboardSource.available([
            signal(
              'oldest',
              DashboardSignalKind.meaningfulMovement,
              eventAt: DateTime.utc(2026, 8, 20),
            ),
            for (var i = 1; i <= 4; i++)
              signal(
                'new-$i',
                DashboardSignalKind.meaningfulMovement,
                eventAt: DateTime.utc(2026, 8, 20 + i),
              ),
          ]),
        ),
      );

      expect(result.answer.item?.signal.id, 'oldest');
      expect(result.recently.map((item) => item.signal.id), [
        'new-4',
        'new-3',
        'new-2',
      ]);
      expect(
        result.recently.any(
          (item) => item.signal.id == result.answer.item?.signal.id,
        ),
        isFalse,
      );
    });

    test('all successful empty sources produce an honest calm answer', () {
      final result = resolver.resolve(snapshot());

      expect(result.answer.kind, DashboardAnswerKind.calm);
      expect(result.answer.item, isNull);
      expect(result.otherActions, isEmpty);
      expect(result.worthKnowing, isEmpty);
      expect(result.tone, DashboardTone.calm);
      expect(result.sourceHealth, DashboardSourceHealth.complete);
    });

    test(
      'insight-only failure does not falsely imply an action-source gap',
      () {
        final result = resolver.resolve(
          snapshot(insights: const DashboardSource.unavailable(failure)),
        );

        expect(result.answer.kind, DashboardAnswerKind.calm);
        expect(result.tone, DashboardTone.calm);
        expect(result.sourceHealth, DashboardSourceHealth.partial);
        expect(result.insightsState, DashboardSectionState.unavailable);
      },
    );

    test(
      'the one Updates source is either available or unavailable, never partial',
      () {
        final result = resolver.resolve(
          snapshot(updates: const DashboardSource.unavailable(failure)),
        );

        expect(result.recently, isEmpty);
        expect(result.updatesState, DashboardSectionState.unavailable);
        expect(result.insightsState, DashboardSectionState.available);
      },
    );

    test('a failed Updates projection resolves as unavailable', () {
      final result = resolver.resolve(
        snapshot(updates: const DashboardSource.unavailable(failure)),
      );

      expect(result.recently, isEmpty);
      expect(result.updatesState, DashboardSectionState.unavailable);
    });
  });

  group('truthful source health', () {
    test('all sources unavailable is failed and requires refresh', () {
      final result = resolver.resolve(
        snapshot(
          onboarding: const DashboardSource.unavailable(failure),
          journeys: const DashboardSource.unavailable(failure),
          updates: const DashboardSource.unavailable(failure),
          guardianInvitations: const DashboardSource.unavailable(failure),
          insights: const DashboardSource.unavailable(failure),
          advisories: const DashboardSource.unavailable(failure),
          stableState: const DashboardStableState(
            orientationItems: DashboardSource.unavailable(failure),
            family: DashboardSource.unavailable(failure),
          ),
        ),
      );

      expect(result.answer.kind, DashboardAnswerKind.refreshRequired);
      expect(result.tone, DashboardTone.needsYou);
      expect(result.sourceHealth, DashboardSourceHealth.failed);
      expect(result.journey.state, DashboardJourneyResolutionState.unavailable);
    });

    test('one action-bearing failure prohibits calm under partial health', () {
      final result = resolver.resolve(
        snapshot(updates: const DashboardSource.unavailable(failure)),
      );

      expect(result.answer.kind, DashboardAnswerKind.refreshRequired);
      expect(result.tone, DashboardTone.needsYou);
      expect(result.sourceHealth, DashboardSourceHealth.partial);
    });

    test('one action-bearing load prohibits calm and remains partial', () {
      final result = resolver.resolve(
        snapshot(guardianInvitations: const DashboardSource.loading()),
      );

      expect(result.answer.kind, DashboardAnswerKind.loading);
      expect(result.tone, DashboardTone.needsYou);
      expect(result.sourceHealth, DashboardSourceHealth.partial);
    });

    test(
      'known obligation remains the answer during another source failure',
      () {
        final result = resolver.resolve(
          snapshot(
            onboarding: DashboardSource.available([
              signal('gate', DashboardSignalKind.blockingGate),
            ]),
            updates: const DashboardSource.unavailable(failure),
          ),
        );

        expect(result.answer.kind, DashboardAnswerKind.signal);
        expect(result.answer.item?.signal.id, 'gate');
        expect(result.tone, DashboardTone.needsYou);
        expect(result.sourceHealth, DashboardSourceHealth.partial);
      },
    );

    test('all action-bearing successful empty reads permit calm', () {
      final result = resolver.resolve(snapshot());

      expect(result.answer.kind, DashboardAnswerKind.calm);
      expect(result.sourceHealth, DashboardSourceHealth.complete);
    });
  });

  group('Journey summary', () {
    test(
      'available summary remains stable beside a higher-priority answer',
      () {
        const active = DashboardJourneySummary(
          id: 'match-1',
          kind: DashboardJourneyKind.active,
          title: 'Faith & Values',
          detail: 'Stage 5 of 8',
          progress: 0.625,
        );
        final result = resolver.resolve(
          snapshot(
            onboarding: DashboardSource.available([
              signal('gate', DashboardSignalKind.blockingGate),
            ]),
            journeys: const DashboardSource.available(
              DashboardJourneyState(summary: active),
            ),
          ),
        );

        expect(result.answer.item?.signal.id, 'gate');
        expect(result.journey.state, DashboardJourneyResolutionState.available);
        expect(result.journey.summary, same(active));
      },
    );

    test('loading and unavailable Journey states remain distinct', () {
      final loading = resolver.resolve(
        snapshot(journeys: const DashboardSource.loading()),
      );
      final unavailable = resolver.resolve(
        snapshot(journeys: const DashboardSource.unavailable(failure)),
      );

      expect(loading.journey.state, DashboardJourneyResolutionState.loading);
      expect(loading.answer.kind, DashboardAnswerKind.loading);
      expect(
        unavailable.journey.state,
        DashboardJourneyResolutionState.unavailable,
      );
      expect(unavailable.answer.kind, DashboardAnswerKind.refreshRequired);
    });

    test('truthful Journey lines remain attached to the stable summary', () {
      const active = DashboardJourneySummary(
        id: 'match-lines',
        kind: DashboardJourneyKind.active,
        title: 'You & Adam',
        latestCompletedStage: 'Latest completed · Salam Exchange',
        nextMilestone: 'Next · Guardian Gate',
        momentum: 'Your Journey moved forward this week.',
      );
      final result = resolver.resolve(
        snapshot(
          journeys: const DashboardSource.available(
            DashboardJourneyState(summary: active),
          ),
        ),
      );

      expect(
        result.journey.summary?.latestCompletedStage,
        'Latest completed · Salam Exchange',
      );
      expect(result.journey.summary?.nextMilestone, 'Next · Guardian Gate');
      expect(result.journey.summary?.momentum, isNotNull);
    });

    test('stable-state source health is preserved independently', () {
      final result = resolver.resolve(
        snapshot(
          stableState: const DashboardStableState(
            orientationItems: DashboardSource.unavailable(failure),
            family: DashboardSource.available(
              DashboardFamilyStatus(
                kind: DashboardFamilyKind.connected,
                title: 'Father · Guardian connected',
                linkedCount: 1,
              ),
            ),
          ),
        ),
      );

      expect(result.answer.kind, DashboardAnswerKind.calm);
      expect(
        result.stableState.orientationItems.state,
        DashboardSourceState.unavailable,
      );
      expect(
        result.stableState.family.valueOrNull?.kind,
        DashboardFamilyKind.connected,
      );
      expect(result.sourceHealth, DashboardSourceHealth.partial);
    });
  });
}
