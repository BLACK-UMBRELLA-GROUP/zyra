import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/screens/journey/journey_flow_screen.dart';

void main() {
  const a = 'person-a';
  const b = 'person-b';
  final now = DateTime.utc(2026, 8, 25, 12);

  group('shared Pause decision state machine', () {
    test('a request locks the Journey but keeps its Active slot', () {
      final state = ZyraJourneyPausePolicy.apply(
        state: ZyraJourneyPauseState.active,
        action: ZyraPauseAction.requestPause,
        actorId: a,
        otherId: b,
        now: now,
      );

      expect(state.phase, ZyraPausePhase.pauseDecisionPending);
      expect(state.isLocked, isTrue);
      expect(state.isPending, isTrue);
      expect(state.countsAsActiveSlot, isTrue);
      expect(
        state.perspectiveFor(a),
        ZyraPausePerspective.pauseRequesterWaiting,
      );
      expect(
        state.perspectiveFor(b),
        ZyraPausePerspective.pauseResponderDecision,
      );
    });

    test(
      'agreeing settles a neutral mutual Pause and frees Active capacity',
      () {
        final requested = ZyraJourneyPausePolicy.apply(
          state: ZyraJourneyPauseState.active,
          action: ZyraPauseAction.requestPause,
          actorId: a,
          otherId: b,
          now: now,
        );
        final paused = ZyraJourneyPausePolicy.apply(
          state: requested,
          action: ZyraPauseAction.agreePause,
          actorId: b,
          otherId: a,
          now: now,
        );

        expect(paused.phase, ZyraPausePhase.paused);
        expect(paused.isPaused, isTrue);
        expect(paused.countsAsActiveSlot, isFalse);
        expect(paused.requestedBy, isNull);
        expect(paused.perspectiveFor(a), ZyraPausePerspective.mutuallyPaused);
        expect(paused.perspectiveFor(b), ZyraPausePerspective.mutuallyPaused);
      },
    );

    test('continuation request keeps both sides locked until A decides', () {
      final requested = ZyraJourneyPausePolicy.apply(
        state: ZyraJourneyPausePolicy.apply(
          state: ZyraJourneyPauseState.active,
          action: ZyraPauseAction.requestPause,
          actorId: a,
          otherId: b,
          now: now,
        ),
        action: ZyraPauseAction.requestContinue,
        actorId: b,
        otherId: a,
        now: now,
      );

      expect(requested.phase, ZyraPausePhase.continuationDecisionPending);
      expect(requested.isLocked, isTrue);
      expect(requested.countsAsActiveSlot, isTrue);
      expect(
        requested.perspectiveFor(b),
        ZyraPausePerspective.continuationRequesterWaiting,
      );
      expect(
        requested.perspectiveFor(a),
        ZyraPausePerspective.continuationResponderDecision,
      );

      final continued = ZyraJourneyPausePolicy.apply(
        state: requested,
        action: ZyraPauseAction.continueJourney,
        actorId: a,
        otherId: b,
        now: now,
      );
      expect(continued.phase, ZyraPausePhase.active);
      expect(continued.isLocked, isFalse);
    });

    test('resuming is also mutual', () {
      const paused = ZyraJourneyPauseState(
        phase: ZyraPausePhase.paused,
        initiatedBy: a,
        version: 2,
      );
      final requested = ZyraJourneyPausePolicy.apply(
        state: paused,
        action: ZyraPauseAction.requestResume,
        actorId: b,
        otherId: a,
        now: now,
      );
      expect(
        requested.perspectiveFor(a),
        ZyraPausePerspective.resumeResponderDecision,
      );

      final keptPaused = ZyraJourneyPausePolicy.apply(
        state: requested,
        action: ZyraPauseAction.keepPaused,
        actorId: a,
        otherId: b,
        now: now,
      );
      expect(keptPaused.phase, ZyraPausePhase.paused);
    });

    test('the requester cannot answer their own request', () {
      final requested = ZyraJourneyPausePolicy.apply(
        state: ZyraJourneyPauseState.active,
        action: ZyraPauseAction.requestPause,
        actorId: a,
        otherId: b,
        now: now,
      );

      expect(
        () => ZyraJourneyPausePolicy.apply(
          state: requested,
          action: ZyraPauseAction.agreePause,
          actorId: a,
          otherId: b,
          now: now,
        ),
        throwsStateError,
      );
    });

    test('a stale second action is rejected by the phase rule', () {
      final requested = ZyraJourneyPausePolicy.apply(
        state: ZyraJourneyPauseState.active,
        action: ZyraPauseAction.requestPause,
        actorId: a,
        otherId: b,
        now: now,
      );
      final paused = ZyraJourneyPausePolicy.apply(
        state: requested,
        action: ZyraPauseAction.agreePause,
        actorId: b,
        otherId: a,
        now: now,
      );

      expect(
        () => ZyraJourneyPausePolicy.apply(
          state: paused,
          action: ZyraPauseAction.requestContinue,
          actorId: b,
          otherId: a,
          now: now,
        ),
        throwsStateError,
      );
    });
  });

  group('developer matrix', () {
    test(
      'every listed scenario resolves without inventing production data',
      () {
        for (final scenario in ZyraPauseDevScenario.values) {
          final state = scenario.stateFor(viewerId: a, otherId: b, now: now);
          expect(
            state.version,
            greaterThanOrEqualTo(0),
            reason: scenario.label,
          );
        }
      },
    );

    test('deadline and capacity edge states remain locked', () {
      final expired = ZyraPauseDevScenario.deadlineExpired.stateFor(
        viewerId: a,
        otherId: b,
        now: now,
      );
      final capacity = ZyraPauseDevScenario.pausedCapacityConflict.stateFor(
        viewerId: a,
        otherId: b,
        now: now,
      );

      expect(expired.deadlineAt!.isBefore(now), isTrue);
      expect(expired.isLocked, isTrue);
      expect(capacity.capacityBlocked, isTrue);
      expect(capacity.isLocked, isTrue);
    });
  });

  group('shared Pause decision surface', () {
    testWidgets('requester waits while responder receives equal choices', (
      tester,
    ) async {
      final requested = ZyraPauseDevScenario.pauseRequesterWaiting.stateFor(
        viewerId: a,
        otherId: b,
        now: now,
      );
      await tester.pumpWidget(
        buildZyraPauseDecisionTestSurface(state: requested, viewerId: a),
      );
      expect(find.text('Pause requested'), findsOneWidget);
      expect(find.text('Agree to Pause'), findsNothing);
      expect(find.text('End Journey'), findsOneWidget);

      await tester.pumpWidget(
        buildZyraPauseDecisionTestSurface(state: requested, viewerId: b),
      );
      expect(find.text('Adam has asked to pause this Journey'), findsOneWidget);
      expect(find.text('Agree to Pause'), findsOneWidget);
      expect(find.text('Request to Continue'), findsOneWidget);
      expect(find.text('End Journey'), findsOneWidget);
    });

    testWidgets('paused-cap conflict blocks Pause but not Continue', (
      tester,
    ) async {
      final actions = <ZyraPauseAction>[];
      final requested = ZyraPauseDevScenario.pausedCapacityConflict.stateFor(
        viewerId: a,
        otherId: b,
        now: now,
      );
      await tester.pumpWidget(
        buildZyraPauseDecisionTestSurface(
          state: requested,
          viewerId: a,
          capacityAvailable: false,
          onAction: actions.add,
        ),
      );

      await tester.tap(find.text('Agree to Pause'));
      await tester.pump();
      expect(actions, isEmpty);
      await tester.tap(find.text('Request to Continue'));
      await tester.pump();
      expect(actions, [ZyraPauseAction.requestContinue]);
    });

    testWidgets('mutual Pause and resume decision remain visibly distinct', (
      tester,
    ) async {
      final paused = ZyraPauseDevScenario.mutuallyPaused.stateFor(
        viewerId: a,
        otherId: b,
        now: now,
      );
      await tester.pumpWidget(
        buildZyraPauseDecisionTestSurface(state: paused, viewerId: a),
      );
      expect(find.text('Journey paused'), findsOneWidget);
      expect(find.text('Request Resume'), findsOneWidget);

      final resume = ZyraPauseDevScenario.resumeResponderDecision.stateFor(
        viewerId: a,
        otherId: b,
        now: now,
      );
      await tester.pumpWidget(
        buildZyraPauseDecisionTestSurface(state: resume, viewerId: a),
      );
      expect(find.text('Adam would like to resume'), findsOneWidget);
      expect(find.text('Agree to Resume'), findsOneWidget);
      expect(find.text('Keep Paused'), findsOneWidget);
      expect(find.text('End Journey'), findsOneWidget);
    });

    testWidgets('expired deadline states no automatic outcome', (tester) async {
      final expired = ZyraPauseDevScenario.deadlineExpired.stateFor(
        viewerId: a,
        otherId: b,
        now: now,
      );
      await tester.pumpWidget(
        buildZyraPauseDecisionTestSurface(state: expired, viewerId: a),
      );
      expect(
        find.textContaining('No automatic outcome is configured'),
        findsOneWidget,
      );
    });

    testWidgets('male and female Seekers receive the same decision contract', (
      tester,
    ) async {
      final requested = ZyraPauseDevScenario.pauseResponderDecision.stateFor(
        viewerId: a,
        otherId: b,
        now: now,
      );

      for (final profile in <(String, String)>[
        ('Adam', 'male'),
        ('Fatima', 'female'),
      ]) {
        await tester.pumpWidget(
          buildZyraPauseDecisionTestSurface(
            state: requested,
            viewerId: a,
            profileName: profile.$1,
            profileGender: profile.$2,
          ),
        );
        expect(
          find.text('${profile.$1} has asked to pause this Journey'),
          findsOneWidget,
        );
        expect(find.text('Agree to Pause'), findsOneWidget);
        expect(find.text('Request to Continue'), findsOneWidget);
        expect(find.text('End Journey'), findsOneWidget);
      }
    });
  });
}
