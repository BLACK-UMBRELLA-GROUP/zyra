import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

// LOCK 13 sorting uses actual local actions, never Timeline example dates.
// These tests instantiate no account, service, timer or member data adapter.
void main() {
  const sara = 'draft-sara';
  const aisha = 'draft-aisha';
  const maryam = 'draft-maryam';
  late DateTime now;
  late ViewRequestDraftModel model;

  DateTime tick() => now = now.add(const Duration(minutes: 1));

  void changed(String id, bool Function() action) {
    final at = tick();
    expect(action(), isTrue);
    expect(model.lastActivityFor(id), at);
  }

  void refused(String id, bool Function() action) {
    final before = model.lastActivityFor(id);
    tick();
    expect(action(), isFalse);
    expect(model.lastActivityFor(id), before);
  }

  setUp(() {
    now = DateTime.utc(2026, 10, 30, 10);
    model = ViewRequestDraftModel(capacity: 3, clock: () => now);
  });

  test(
    'seeded Journeys share the actual scenario instant without fake dates',
    () {
      expect(model.snapshot().journeyLastActivityAt, isEmpty);
      expect(model.seedJourneys(3), isTrue);
      expect(model.snapshot().journeyLastActivityAt, {
        sara: now,
        aisha: now,
        maryam: now,
      });
      expect(model.lastActivityFor(draftProfiles.first.id), isNull);
      expect(model.lastActivityFor('unknown'), isNull);
      expect(
        model.snapshot().journeyLastActivityAt.values.every((at) => at.isUtc),
        isTrue,
      );
      tick();
      model.stageFor(sara);
      model.canParticipateInJourney(sara);
      expect(
        model.lastActivityFor(sara),
        now.subtract(const Duration(minutes: 1)),
      );
    },
  );

  test(
    'acceptance, both readiness actions and deliberate begin record activity',
    () {
      final received = draftProfiles.first.id;
      changed(received, () => model.acceptReceived(received));
      expect(model.stateFor(received), DraftJourneyState.preparing);
      refused(received, () => model.acceptReceived(received));
      changed(received, () => model.markReady(received));
      refused(received, () => model.markReady(received));
      changed(received, () => model.simulatePeerReady(received));
      refused(received, () => model.simulatePeerReady(received));
      changed(
        received,
        () => model.beginPreparedJourney(
          received,
          linkedGuardianIds: const {'draft-guardian-hassan'},
        ),
      );
      expect(model.stateFor(received), DraftJourneyState.active);
      expect(model.stageFor(received)?.value, 'salam_exchange');
      expect(model.snapshot().journeyStartedAt[received], now);
      refused(
        received,
        () => model.beginPreparedJourney(
          received,
          linkedGuardianIds: const {'draft-guardian-hassan'},
        ),
      );
    },
  );

  test(
    'real stage choices update only their Journey and refused choices do not',
    () {
      model.seedJourneys(3);
      final otherActivity = model.lastActivityFor(aisha);
      refused(sara, () => model.chooseStageContinue(sara));
      changed(sara, () => model.sendSalam(sara));
      refused(sara, () => model.sendSalam(sara));
      changed(sara, () => model.simulatePeerSalam(sara));
      changed(sara, () => model.chooseStageContinue(sara));
      changed(sara, () => model.simulatePeerStageContinue(sara));
      changed(sara, () => model.advanceStage(sara));
      expect(model.stageFor(sara)?.value, 'compatibility_reveal');
      changed(sara, () => model.chooseCompatibilityReveal(sara));
      refused(sara, () => model.chooseCompatibilityReveal(sara));
      changed(sara, () => model.simulatePeerCompatibilityReveal(sara));
      changed(sara, () => model.chooseStageContinue(sara));
      changed(sara, () => model.simulatePeerStageContinue(sara));
      changed(sara, () => model.beginBioStep(sara));
      changed(sara, () => model.chooseBioReveal(sara));
      changed(sara, () => model.simulatePeerBioReveal(sara));
      changed(sara, () => model.chooseBioContinue(sara));
      changed(sara, () => model.simulatePeerBioContinue(sara));
      changed(sara, () => model.completeBioStep(sara));
      expect(model.stageFor(sara)?.value, 'wali_gate');
      expect(model.canViewJourneyBio(sara), isTrue);
      expect(model.lastActivityFor(aisha), otherActivity);
      expect(model.lastActivityFor(maryam), otherActivity);
      changed(sara, () => model.end(sara));
      expect(model.stateFor(sara), DraftJourneyState.ended);
      refused(sara, () => model.end(sara));
      refused(sara, () => model.sendSalam(sara));
    },
  );

  test('snapshots detach immutable activity and restore its exact dates', () {
    model.seedJourneys(2);
    changed(aisha, () => model.sendSalam(aisha));
    final snapshot = model.snapshot();
    final oldDate = snapshot.journeyLastActivityAt[aisha];
    expect(
      () => snapshot.journeyLastActivityAt[sara] = now,
      throwsUnsupportedError,
    );
    final restored = ViewRequestDraftModel.fromSnapshot(
      snapshot,
      clock: () => now,
    );
    expect(
      restored.snapshot().journeyLastActivityAt,
      snapshot.journeyLastActivityAt,
    );
    tick();
    expect(restored.simulatePeerSalam(aisha), isTrue);
    expect(restored.lastActivityFor(aisha), now);
    expect(model.lastActivityFor(aisha), oldDate);
    expect(snapshot.journeyLastActivityAt[aisha], oldDate);
    expect(restored.stateFor(aisha), model.stateFor(aisha));
    expect(restored.stageFor(aisha), model.stageFor(aisha));
  });

  test(
    'invalid seeds preserve activity and a new scenario clears old dates',
    () {
      model.seedJourneys(3);
      changed(maryam, () => model.sendSalam(maryam));
      final before = model.snapshot();
      tick();
      expect(model.seedJourneys(0), isFalse);
      expect(model.seedJourneys(4), isFalse);
      expect(
        model.snapshot().journeyLastActivityAt,
        before.journeyLastActivityAt,
      );
      expect(model.snapshot().states, before.states);
      expect(model.seedJourneys(1), isTrue);
      expect(model.snapshot().journeyLastActivityAt, {sara: now});
      model.reset();
      expect(model.snapshot().journeyLastActivityAt, isEmpty);
      expect(model.lastActivityFor(sara), isNull);
      expect(model.lastActivityFor(maryam), isNull);
    },
  );

  test(
    'shell activity is limited to a current active unblocked participant',
    () {
      final received = draftProfiles.first.id;
      refused(received, () => model.markJourneyActivity(received));
      refused('unknown', () => model.markJourneyActivity('unknown'));
      expect(model.acceptReceived(received), isTrue);
      refused(received, () => model.markJourneyActivity(received));
      model.seedJourneys(3);
      final before = model.snapshot();
      changed(sara, () => model.markJourneyActivity(sara));
      expect(model.snapshot().states, before.states);
      expect(model.snapshot().progress, before.progress);
      model.setOwnMainGuardianPresent(false);
      refused(sara, () => model.markJourneyActivity(sara));
      model.setOwnMainGuardianPresent(true);
      expect(model.block(aisha), isTrue);
      refused(aisha, () => model.markJourneyActivity(aisha));
      expect(model.end(maryam), isTrue);
      refused(maryam, () => model.markJourneyActivity(maryam));
    },
  );

  test(
    'replacement records both addressed transitions and preserves other dates',
    () {
      model.seedJourneys(3);
      final received = draftProfiles.first.id;
      final otherActivity = model.lastActivityFor(aisha);
      tick();
      expect(
        model.replaceJourneyForRequest(received, sara, incoming: true),
        isTrue,
      );
      expect(model.lastActivityFor(received), now);
      expect(model.lastActivityFor(sara), now);
      expect(model.lastActivityFor(aisha), otherActivity);
      expect(model.lastActivityFor(maryam), otherActivity);
      expect(model.stateFor(sara), DraftJourneyState.ended);
      expect(model.stateFor(received), DraftJourneyState.preparing);
      expect(model.isReady(received), isFalse);
      final before = model.snapshot().journeyLastActivityAt;
      tick();
      expect(
        model.replaceJourneyForRequest(received, aisha, incoming: true),
        isFalse,
      );
      expect(model.snapshot().journeyLastActivityAt, before);
    },
  );
}
