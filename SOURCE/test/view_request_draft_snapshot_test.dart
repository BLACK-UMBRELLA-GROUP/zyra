import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _maryam = 'draft-maryam';
const _hassan = 'draft-guardian-hassan';
const _yusuf = 'draft-guardian-yusuf';

void _start(ViewRequestDraftModel model, String id) {
  expect(model.request(id), isTrue);
  expect(model.simulateRecipientAccept(id), isTrue);
  expect(
    model.completePreparation(
      id,
      agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
    ),
    isTrue,
  );
}

void _advance(ViewRequestDraftModel model, String id) {
  switch (model.stageFor(id)!.value) {
    case 'salam_exchange':
      expect(model.sendSalam(id), isTrue);
      expect(model.simulatePeerSalam(id), isTrue);
    case 'compatibility_reveal':
      expect(model.chooseCompatibilityReveal(id), isTrue);
      expect(model.simulatePeerCompatibilityReveal(id), isTrue);
  }
  expect(model.chooseStageContinue(id), isTrue);
  expect(model.simulatePeerStageContinue(id), isTrue);
  expect(model.advanceStage(id), isTrue);
}

void _sameValues(ViewRequestDraftSnapshot a, ViewRequestDraftSnapshot b) {
  expect(a.capacity, b.capacity);
  expect(a.states, b.states);
  expect(a.busyPeers, b.busyPeers);
  expect(a.hiddenPeers, b.hiddenPeers);
  expect(a.blockedPeers, b.blockedPeers);
  expect(a.acknowledgedReceivedRequestIds, b.acknowledgedReceivedRequestIds);
  expect(a.journeyStartedAt, b.journeyStartedAt);
  expect(a.endedAttempts, b.endedAttempts);
  expect(a.currentEndedAttemptIds, b.currentEndedAttemptIds);
  expect(a.progress, b.progress);
  expect(a.peerMainGuardianOverrides, b.peerMainGuardianOverrides);
  expect(a.guardianMemberships, b.guardianMemberships);
  expect(a.guardianAccess, b.guardianAccess);
  expect(a.requiredPaidGuardianAccess, b.requiredPaidGuardianAccess);
  expect(a.ownMainGuardianPresent, b.ownMainGuardianPresent);
  expect(a.peerMainGuardianPresent, b.peerMainGuardianPresent);
}

void main() {
  test('default seed round-trips as a distinct mutable fictional model', () {
    final original = ViewRequestDraftModel(capacity: 3);
    final snapshot = original.snapshot();
    final restored = ViewRequestDraftModel.fromSnapshot(snapshot);
    expect(identical(original, restored), isFalse);
    _sameValues(snapshot, restored.snapshot());
    expect(restored.request(_sara), isTrue);
    expect(original.stateFor(_sara), isNull);
    expect(snapshot.states[_sara], isNull);
  });

  test('every collection is copied and unmodifiable', () {
    final original = ViewRequestDraftModel(capacity: 3)..fillCapacity();
    original.hide(_aisha);
    original.block(_maryam);
    original.setPeerMainGuardianPresent(false, id: _sara);
    original.setSampleGuardianMembership(_yusuf, DraftGuardianMembership.basic);
    final snapshot = original.snapshot();
    expect(() => snapshot.states.clear(), throwsUnsupportedError);
    expect(() => snapshot.busyPeers.clear(), throwsUnsupportedError);
    expect(() => snapshot.hiddenPeers.clear(), throwsUnsupportedError);
    expect(() => snapshot.blockedPeers.clear(), throwsUnsupportedError);
    expect(() => snapshot.progress.clear(), throwsUnsupportedError);
    expect(() => snapshot.journeyStartedAt.clear(), throwsUnsupportedError);
    expect(() => snapshot.endedAttempts.clear(), throwsUnsupportedError);
    expect(
      () => snapshot.currentEndedAttemptIds.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.peerMainGuardianOverrides.clear(),
      throwsUnsupportedError,
    );
    expect(() => snapshot.guardianMemberships.clear(), throwsUnsupportedError);
    expect(() => snapshot.guardianAccess.clear(), throwsUnsupportedError);
    expect(
      () => snapshot.requiredPaidGuardianAccess.clear(),
      throwsUnsupportedError,
    );
    original.reset();
    expect(snapshot.states[_sara], DraftJourneyState.active);
    expect(snapshot.hiddenPeers, {_aisha});
    expect(snapshot.blockedPeers, {_maryam});
    expect(snapshot.peerMainGuardianOverrides, {_sara: false});
    expect(snapshot.guardianMemberships[_yusuf], DraftGuardianMembership.basic);
    expect(snapshot.guardianAccess, isNotEmpty);
  });

  test('full three-Journey capacity survives without a fourth-place grant', () {
    final model = ViewRequestDraftModel(capacity: 3)..fillCapacity();
    final restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
    expect(restored.capacity, 3);
    expect(restored.activeCount, 3);
    expect(restored.occupiedCount, 3);
    expect(restored.canBrowse, isTrue);
    expect(restored.hasCapacity, isFalse);
    expect(restored.canAccept('draft-amira'), isFalse);
    expect(restored.canAttemptAccept('draft-amira'), isTrue);
    expect(restored.acceptReceived('draft-amira'), isFalse);
    expect(restored.occupiedCount, 3);
    expect(restored.setCapacity(1), isFalse);
    expect(restored.end(_sara), isTrue);
    expect(model.stateFor(_sara), DraftJourneyState.active);
    expect(model.occupiedCount, 3);
  });

  test('one-sided preparation readiness is not upgraded by restoration', () {
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.request(_sara), isTrue);
    expect(model.simulateRecipientAccept(_sara), isTrue);
    expect(model.markReady(_sara), isTrue);
    final snapshot = model.snapshot();
    final restored = ViewRequestDraftModel.fromSnapshot(snapshot);
    expect(restored.stateFor(_sara), DraftJourneyState.preparing);
    expect(restored.isReady(_sara), isTrue);
    expect(restored.peerIsReady(_sara), isFalse);
    expect(
      restored.beginPreparedJourney(
        _sara,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isFalse,
    );
    expect(restored.simulatePeerReady(_sara), isTrue);
    expect(
      restored.beginPreparedJourney(
        _sara,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isTrue,
    );
    expect(model.peerIsReady(_sara), isFalse);
    expect(snapshot.progress[_sara]!.peerReady, isFalse);
  });

  test(
    'progress, one-sided reveal and continuation remain detached values',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      _start(model, _sara);
      _advance(model, _sara);
      expect(model.stageFor(_sara)!.value, 'compatibility_reveal');
      expect(model.chooseCompatibilityReveal(_sara), isTrue);
      final snapshot = model.snapshot();
      final restored = ViewRequestDraftModel.fromSnapshot(snapshot);
      expect(restored.hasChosenCompatibilityReveal(_sara), isTrue);
      expect(restored.peerHasChosenCompatibilityReveal(_sara), isFalse);
      expect(restored.compatibilityRevealed(_sara), isFalse);
      expect(restored.advanceStage(_sara), isFalse);
      expect(restored.simulatePeerCompatibilityReveal(_sara), isTrue);
      expect(restored.chooseStageContinue(_sara), isTrue);
      final second = restored.snapshot();
      final resumed = ViewRequestDraftModel.fromSnapshot(second);
      expect(resumed.hasChosenStageContinue(_sara), isTrue);
      expect(resumed.peerHasChosenStageContinue(_sara), isFalse);
      expect(resumed.advanceStage(_sara), isFalse);
      expect(resumed.simulatePeerStageContinue(_sara), isTrue);
      expect(resumed.advanceStage(_sara), isTrue);
      expect(model.stageFor(_sara)!.value, 'compatibility_reveal');
      expect(model.compatibilityRevealed(_sara), isFalse);
      expect(snapshot.progress[_sara]!.peerCompatibilityConsent, isFalse);
    },
  );

  test(
    'every valid stage including destination survives without advancing',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      _start(model, _sara);
      for (var index = 0; index < ZyraJourneyStages.all.length; index++) {
        final restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
        expect(
          restored.stageFor(_sara)!.value,
          ZyraJourneyStages.all[index].value,
        );
        _sameValues(model.snapshot(), restored.snapshot());
        if (index < ZyraJourneyStages.all.length - 1) _advance(model, _sara);
      }
    },
  );

  test(
    'blocked, hidden, busy and ended fixtures retain their restrictions',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      _start(model, _sara);
      expect(model.end(_sara), isTrue);
      expect(model.hide(_aisha), isTrue);
      expect(model.block(_sara), isTrue);
      expect(model.setPeerOccupied(_maryam, true), isTrue);
      final restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
      expect(restored.stateFor(_sara), DraftJourneyState.ended);
      expect(restored.isBlocked(_sara), isTrue);
      expect(restored.isHidden(_aisha), isTrue);
      expect(restored.peerOccupied(_maryam), isTrue);
      expect(restored.canRequest(_sara), isFalse);
      expect(restored.canRequest(_aisha), isFalse);
      expect(restored.canRequest(_maryam), isFalse);
      expect(
        restored.discoverableProfiles.map((p) => p.id),
        isNot(contains(_sara)),
      );
      expect(
        restored.discoverableProfiles.map((p) => p.id),
        isNot(contains(_aisha)),
      );
      expect(restored.conversationOpen(_sara), isFalse);
    },
  );

  test('missing own or addressed peer Main is never silently repaired', () {
    final model = ViewRequestDraftModel(capacity: 3)..fillCapacity();
    expect(model.setPeerMainGuardianPresent(false, id: _sara), isTrue);
    var restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
    expect(restored.peerMainGuardianPresentFor(_sara), isFalse);
    expect(restored.canParticipateInJourney(_sara), isFalse);
    expect(restored.canParticipateInJourney(_aisha), isTrue);
    expect(restored.sendSalam(_sara), isFalse);
    model.setOwnMainGuardianPresent(false);
    restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
    expect(restored.ownMainGuardianPresent, isFalse);
    expect(restored.canParticipateInJourney(_sara), isFalse);
    expect(restored.canParticipateInJourney(_aisha), isFalse);
    expect(restored.end(_sara), isTrue);
    expect(model.stateFor(_sara), DraftJourneyState.active);
  });

  test(
    'Basic Guardian chat denial and revoked grants survive independently',
    () {
      final model = ViewRequestDraftModel(capacity: 3)..fillCapacity();
      expect(
        model.setSampleGuardianMembership(
          _hassan,
          DraftGuardianMembership.basic,
        ),
        isTrue,
      );
      expect(
        model.setSampleGuardianJourneyAccess(_yusuf, _sara, viewEnabled: false),
        isTrue,
      );
      final snapshot = model.snapshot();
      final restored = ViewRequestDraftModel.fromSnapshot(snapshot);
      expect(restored.canUseSampleGuardianChat(_hassan), isFalse);
      expect(restored.sampleGuardianAccessFor(_hassan, _sara, isMain: true), (
        view: true,
        chat: false,
      ));
      expect(
        restored.setSampleGuardianJourneyAccess(
          _hassan,
          _sara,
          chatEnabled: true,
        ),
        isFalse,
      );
      expect(restored.sampleGuardianAccessFor(_yusuf, _sara), (
        view: false,
        chat: false,
      ));
      expect(
        restored.setSampleGuardianMembership(
          _hassan,
          DraftGuardianMembership.one,
        ),
        isTrue,
      );
      expect(restored.sampleGuardianAccessFor(_hassan, _sara).chat, isFalse);
      expect(model.canUseSampleGuardianChat(_hassan), isFalse);
      expect(
        snapshot.guardianMemberships[_hassan],
        DraftGuardianMembership.basic,
      );
    },
  );

  test('two restores do not share progress, sets or Guardian grants', () {
    final model = ViewRequestDraftModel(capacity: 3)..fillCapacity();
    final snapshot = model.snapshot();
    final first = ViewRequestDraftModel.fromSnapshot(snapshot);
    final second = ViewRequestDraftModel.fromSnapshot(snapshot);
    expect(first.sendSalam(_sara), isTrue);
    expect(first.block(_aisha), isTrue);
    expect(
      first.setSampleGuardianJourneyAccess(_yusuf, _sara, viewEnabled: false),
      isTrue,
    );
    expect(second.hasSentSalam(_sara), isFalse);
    expect(second.isBlocked(_aisha), isFalse);
    expect(second.sampleGuardianAccessFor(_yusuf, _sara).view, isTrue);
    expect(snapshot.progress[_sara]!.salam, isFalse);
    expect(snapshot.blockedPeers, isEmpty);
    second.reset();
    expect(first.stateFor(_sara), DraftJourneyState.active);
    expect(first.hasSentSalam(_sara), isTrue);
  });

  test(
    'dated attempt metadata round-trips without replacing time with now',
    () {
      var clock = DateTime.utc(2026, 1, 31, 10);
      final model = ViewRequestDraftModel(capacity: 3, clock: () => clock);
      _start(model, _sara);
      final startedAt = clock;
      _advance(model, _sara);
      expect(model.chooseCompatibilityReveal(_sara), isTrue);
      clock = DateTime.utc(2026, 2, 28, 11);
      expect(model.end(_sara), isTrue);
      final snapshot = model.snapshot();
      final attempt = model.currentEndedAttemptFor(_sara)!;
      final restored = ViewRequestDraftModel.fromSnapshot(
        snapshot,
        clock: () => DateTime.utc(2031, 12, 31),
      );
      _sameValues(snapshot, restored.snapshot());
      expect(restored.currentEndedAttemptFor(_sara), same(attempt));
      expect(attempt.startedAt, startedAt);
      expect(attempt.endedAt, clock);
      expect(attempt.progress.compatibilityConsent, isTrue);
      expect(attempt.progress.peerCompatibilityConsent, isFalse);
      expect(attempt.hasReadWindow(DateTime.utc(2031, 12, 31)), isFalse);
      expect(restored.canRequest(_sara), isFalse);
      expect(restored.compatibilityRevealed(_sara), isFalse);
      model.reset();
      expect(snapshot.endedAttempts.single, same(attempt));
      expect(snapshot.currentEndedAttemptIds[_sara], attempt.id);
      expect(restored.currentEndedAttemptFor(_sara), same(attempt));
    },
  );

  test(
    'three prior attempts remain ordered and never grant fresh-attempt consent',
    () {
      DraftEndedJourneyAttempt ended(DateTime date, {bool shared = false}) {
        final previous = ViewRequestDraftModel(capacity: 3, clock: () => date)
          ..seedJourneys(1);
        if (shared) {
          _advance(previous, _sara);
          expect(previous.chooseCompatibilityReveal(_sara), isTrue);
          expect(previous.simulatePeerCompatibilityReveal(_sara), isTrue);
        }
        expect(previous.end(_sara), isTrue);
        return previous.currentEndedAttemptFor(_sara)!;
      }

      final first = ended(DateTime.utc(2026, 1, 31), shared: true);
      final second = ended(DateTime.utc(2026, 4, 30));
      final third = ended(DateTime.utc(2026, 8, 31));
      final fresh = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
      final model = ViewRequestDraftModel.fromSnapshot(
        fresh.snapshot(),
        earlierAttempts: [third, first, second],
      );
      expect(model.endedAttemptsFor(_sara), [first, second, third]);
      expect(model.endedAttemptsFor(_aisha), isEmpty);
      expect(model.currentEndedAttemptFor(_sara), isNull);
      expect(model.stateFor(_sara), DraftJourneyState.active);
      expect(model.stageFor(_sara)!.value, 'salam_exchange');
      expect(model.hasSentSalam(_sara), isFalse);
      expect(model.hasChosenCompatibilityReveal(_sara), isFalse);
      expect(model.peerHasChosenCompatibilityReveal(_sara), isFalse);
      expect(model.bioRevealed(_sara), isFalse);
      expect(first.progress.compatibilityConsent, isTrue);
      expect(first.progress.peerCompatibilityConsent, isTrue);
      final restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
      _sameValues(model.snapshot(), restored.snapshot());
      expect(restored.endedAttemptsFor(_sara), [first, second, third]);
      expect(
        () => ViewRequestDraftModel.fromSnapshot(
          model.snapshot(),
          earlierAttempts: [first],
        ),
        throwsArgumentError,
      );

      final terminal = ViewRequestDraftModel(
        capacity: 3,
        clock: () => DateTime.utc(2026, 10, 22),
      )..seedJourneys(1);
      expect(terminal.end(_sara), isTrue);
      final current = terminal.currentEndedAttemptFor(_sara)!;
      final combined = ViewRequestDraftModel.fromSnapshot(
        terminal.snapshot(),
        earlierAttempts: [third, first, second],
      );
      expect(combined.currentEndedAttemptFor(_sara), same(current));
      expect(combined.endedAttemptsFor(_sara), [first, second, third, current]);
      expect(combined.snapshot().progress[_sara], current.progress);
      expect(combined.compatibilityRevealed(_sara), isFalse);
    },
  );

  test('undated legacy attempt remains unknown after snapshot restoration', () {
    final model = ViewRequestDraftModel()..seedHistory();
    final id = draftProfiles[5].id;
    final attempt = model.currentEndedAttemptFor(id)!;
    final restored = ViewRequestDraftModel.fromSnapshot(
      model.snapshot(),
      clock: () => DateTime.utc(2036, 1, 1),
    );
    expect(restored.currentEndedAttemptFor(id), same(attempt));
    expect(attempt.endedAt, isNull);
    expect(attempt.startedAt, isNull);
    expect(attempt.hasReadWindow(DateTime.utc(2036, 1, 1)), isFalse);
    expect(restored.end(id), isFalse);
    expect(restored.endedAttemptsFor(id), [attempt]);
  });
}
