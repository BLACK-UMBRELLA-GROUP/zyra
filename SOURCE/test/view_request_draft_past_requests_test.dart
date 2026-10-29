import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _amira = 'draft-amira';
const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _maryam = 'draft-maryam';
const _hana = 'draft-hana';

void main() {
  late DateTime now;
  late ViewRequestDraftModel model;

  setUp(() {
    now = DateTime.utc(2026, 10, 1, 12);
    model = ViewRequestDraftModel(capacity: 3, clock: () => now);
  });

  test(
    'fresh Past is empty and the existing received fixture keeps its date',
    () {
      expect(model.pastRequests, isEmpty);
      expect(model.stateFor(_amira), DraftJourneyState.received);
      expect(model.snapshot().pendingRequestedAt, {_amira: now});
      expect(model.receivedActivityRevision, 1);
      expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
    },
  );

  test(
    'cancellation records original Sent date without a new arrival or ack',
    () {
      final sent = now;
      expect(model.acknowledgeReceivedRequests([_amira]), isTrue);
      expect(model.request(_sara), isTrue);
      final arrival = model.receivedActivityRevision;
      now = now.add(const Duration(days: 2));
      expect(model.cancel(_sara), isTrue);
      final entry = model.pastRequests.single;
      expect(entry.profileId, _sara);
      expect(entry.outcome, DraftPastRequestOutcome.cancelled);
      expect(entry.incoming, isFalse);
      expect(entry.requestedAt, sent);
      expect(entry.movedAt, now);
      expect(entry.sequence, 1);
      expect(model.stateFor(_sara), isNull);
      expect(model.snapshot().pendingRequestedAt.containsKey(_sara), isFalse);
      expect(model.receivedActivityRevision, arrival);
      expect(model.snapshot().acknowledgedReceivedRequestIds, {_amira});
      expect(model.canRequest(_sara), isTrue);
      expect(model.request(_sara), isTrue);
    },
  );

  test('decline records original Received date without Journey history', () {
    final received = now;
    final arrival = model.receivedActivityRevision;
    now = now.add(const Duration(days: 4));
    expect(model.declineReceived(_amira), isTrue);
    final entry = model.pastRequests.single;
    expect(entry.outcome, DraftPastRequestOutcome.youDeclined);
    expect(entry.incoming, isTrue);
    expect(entry.requestedAt, received);
    expect(entry.movedAt, now);
    expect(model.stateFor(_amira), isNull);
    expect(model.receivedRequestRevision(_amira), isNull);
    expect(model.receivedActivityRevision, arrival);
    expect(model.snapshot().endedAttempts, isEmpty);
    expect(model.snapshot().progress, isEmpty);
    expect(model.occupiedCount, 0);
    expect(model.canRequest(_amira), isTrue);
  });

  test('invalid or repeated transitions do not create passive records', () {
    expect(model.cancel(_amira), isFalse);
    expect(model.cancel('unknown'), isFalse);
    expect(model.declineReceived('unknown'), isFalse);
    expect(model.request(_sara), isTrue);
    expect(model.declineReceived(_sara), isFalse);
    expect(model.pastRequests, isEmpty);
    expect(model.cancel(_sara), isTrue);
    expect(model.cancel(_sara), isFalse);
    expect(model.declineReceived(_sara), isFalse);
    expect(model.pastRequests.length, 1);
    expect(model.declineReceived(_amira), isTrue);
    expect(model.declineReceived(_amira), isFalse);
    expect(model.pastRequests.length, 2);
    expect(model.receivedActivityRevision, 1);
  });

  test('received and sent acceptance remove dates without creating Past', () {
    final arrival = model.receivedActivityRevision;
    expect(model.acceptReceived(_amira), isTrue);
    expect(model.request(_sara), isTrue);
    expect(model.simulateRecipientAccept(_sara), isTrue);
    expect(model.pastRequests, isEmpty);
    expect(model.snapshot().pendingRequestedAt, isEmpty);
    expect(model.receivedActivityRevision, arrival);
    expect(model.receivedRequestRevision(_amira), isNull);
    expect(model.occupiedCount, 2);
    expect(model.snapshot().progress.keys, containsAll([_amira, _sara]));
    expect(
      ViewRequestDraftModel.fromSnapshot(model.snapshot()).occupiedCount,
      2,
    );
  });

  test(
    'replacement archives only its Journey and never the accepted request',
    () {
      model.fillCapacity();
      final arrival = model.receivedActivityRevision;
      expect(
        model.replaceJourneyForRequest(_amira, _sara, incoming: true),
        isTrue,
      );
      expect(model.pastRequests, isEmpty);
      expect(model.snapshot().pendingRequestedAt, isEmpty);
      expect(model.snapshot().endedAttempts.single.profileId, _sara);
      expect(model.stateFor(_amira), DraftJourneyState.preparing);
      expect(model.occupiedCount, 3);
      expect(model.receivedActivityRevision, arrival);
      expect(
        ViewRequestDraftModel.fromSnapshot(model.snapshot()).occupiedCount,
        3,
      );
    },
  );

  test(
    'Past orders by transition date with stable newest equal-date sequence',
    () {
      final first = DateTime.utc(2026, 9, 1);
      final newer = DateTime.utc(2026, 9, 20);
      expect(
        model.seedPastRequest(
          profileId: _aisha,
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: first,
          movedAt: first,
        ),
        isTrue,
      );
      expect(
        model.seedPastRequest(
          profileId: _maryam,
          outcome: DraftPastRequestOutcome.youDeclined,
          requestedAt: first,
          movedAt: newer,
        ),
        isTrue,
      );
      expect(
        model.seedPastRequest(
          profileId: _hana,
          outcome: DraftPastRequestOutcome.cancelled,
          requestedAt: first,
          movedAt: newer,
        ),
        isTrue,
      );
      final ordered = model.pastRequests;
      expect(ordered.map((entry) => entry.profileId), [_hana, _maryam, _aisha]);
      expect(
        model.pastRequests.map((entry) => entry.id),
        ordered.map((entry) => entry.id),
      );
      expect(() => ordered.clear(), throwsUnsupportedError);
      expect(ordered.map((entry) => entry.id).toSet().length, 3);
      expect(model.stateFor(_aisha), isNull);
    },
  );

  test(
    'repeated same-peer cycles retain separate immutable equal-date records',
    () {
      expect(model.request(_sara), isTrue);
      expect(model.cancel(_sara), isTrue);
      final first = model.pastRequests.single;
      final detached = model.pastRequests;
      expect(model.request(_sara), isTrue);
      expect(model.cancel(_sara), isTrue);
      expect(model.pastRequests.length, 2);
      expect(model.pastRequests.first.sequence, greaterThan(first.sequence));
      expect(model.pastRequests.first.id, isNot(first.id));
      expect(model.pastRequests.last, same(first));
      expect(detached, [first]);
      expect(first.requestedAt, now);
      expect(first.movedAt, now);
    },
  );

  test(
    'explicit seeding is bounded idempotent and does not replace live state',
    () {
      bool seed(String id, DateTime requested, DateTime moved) =>
          model.seedPastRequest(
            profileId: id,
            outcome: DraftPastRequestOutcome.notTakenUp,
            requestedAt: requested,
            movedAt: moved,
          );
      final arrival = model.receivedActivityRevision;
      expect(seed('unknown', now, now), isFalse);
      expect(seed(_amira, now, now), isFalse);
      expect(model.request(_sara), isTrue);
      expect(seed(_sara, now, now), isFalse);
      expect(model.simulateRecipientAccept(_sara), isTrue);
      final preparation = model.snapshot().progress[_sara];
      expect(seed(_sara, now, now), isFalse);
      expect(seed(_aisha, now.add(const Duration(days: 1)), now), isFalse);
      expect(model.pastRequests, isEmpty);
      expect(seed(_aisha, now, now), isTrue);
      expect(seed(_aisha, now, now), isFalse);
      expect(model.pastRequests.length, 1);
      expect(model.stateFor(_sara), DraftJourneyState.preparing);
      expect(model.snapshot().progress[_sara], preparation);
      expect(model.receivedActivityRevision, arrival);
      expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
    },
  );

  test(
    'items remain indefinitely after the resend waiting period finishes',
    () {
      expect(
        model.seedPastRequest(
          profileId: _aisha,
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: now,
          movedAt: now,
        ),
        isTrue,
      );
      final entry = model.pastRequests.single;
      now = DateTime.utc(2040, 1, 1);
      expect(model.pastRequests, [entry]);
      expect(model.canRequest(_aisha), isTrue);
      expect(model.request(_aisha), isTrue);
      expect(model.pastRequests, [entry]);
    },
  );

  test(
    'Not taken up waits exactly 30 days and preserves other request guards',
    () {
      final moved = now;
      expect(
        model.seedPastRequest(
          profileId: _aisha,
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: now.subtract(const Duration(days: 4)),
          movedAt: moved,
        ),
        isTrue,
      );
      now = moved
          .add(const Duration(days: 30))
          .subtract(const Duration(microseconds: 1));
      expect(model.canRequest(_aisha), isFalse);
      expect(model.request(_aisha), isFalse);
      now = moved.add(const Duration(days: 30));
      expect(model.canRequest(_aisha), isTrue);
      expect(model.hide(_aisha), isTrue);
      expect(model.canRequest(_aisha), isFalse);
      expect(model.unhide(_aisha), isTrue);
      expect(model.setPeerOccupied(_aisha, true), isTrue);
      expect(model.canRequest(_aisha), isFalse);
      expect(model.setPeerOccupied(_aisha, false), isTrue);
      expect(model.canRequest(_aisha), isTrue);
      expect(model.block(_aisha), isTrue);
      expect(model.canRequest(_aisha), isFalse);
      expect(model.pastRequests.length, 1);
    },
  );

  for (final outcome in [
    DraftPastRequestOutcome.cancelled,
    DraftPastRequestOutcome.youDeclined,
  ]) {
    test('$outcome does not add a sender resend cooldown', () {
      expect(
        model.seedPastRequest(
          profileId: _sara,
          outcome: outcome,
          requestedAt: now,
          movedAt: now,
        ),
        isTrue,
      );
      expect(model.canRequest(_sara), isTrue);
      expect(model.request(_sara), isTrue);
      expect(model.pastRequests.single.outcome, outcome);
    });
  }

  test('snapshot collections are immutable and owners remain isolated', () {
    expect(
      model.seedPastRequest(
        profileId: _aisha,
        outcome: DraftPastRequestOutcome.notTakenUp,
        requestedAt: now,
        movedAt: now,
      ),
      isTrue,
    );
    expect(
      model.seedReceived(
        _sara,
        requestedAt: now.subtract(const Duration(days: 1)),
      ),
      isTrue,
    );
    expect(model.acknowledgeReceivedRequests([_amira]), isTrue);
    final snapshot = model.snapshot();
    expect(() => snapshot.pendingRequestedAt.clear(), throwsUnsupportedError);
    expect(() => snapshot.pastRequests.clear(), throwsUnsupportedError);
    final restored = ViewRequestDraftModel.fromSnapshot(
      snapshot,
      clock: () => now,
    );
    expect(restored.snapshot().pendingRequestedAt, snapshot.pendingRequestedAt);
    expect(restored.pastRequests, snapshot.pastRequests);
    expect(
      restored.receivedActivityRevision,
      snapshot.receivedActivityRevision,
    );
    expect(restored.snapshot().acknowledgedReceivedRequestIds, {_amira});
    now = now.add(const Duration(days: 2));
    expect(model.declineReceived(_sara), isTrue);
    expect(restored.stateFor(_sara), DraftJourneyState.received);
    expect(restored.pastRequests.length, 1);
    expect(restored.request(_maryam), isTrue);
    expect(restored.cancel(_maryam), isTrue);
    expect(
      restored.pastRequests.first.sequence,
      greaterThan(snapshot.pastRequestSequence),
    );
    expect(model.stateFor(_maryam), isNull);
    expect(snapshot.pastRequests.length, 1);
    expect(snapshot.pendingRequestedAt[_sara], DateTime.utc(2026, 9, 30, 12));
  });

  test(
    'reset clears request history but a received arrival stays monotonic',
    () {
      expect(model.acknowledgeReceivedRequests([_amira]), isTrue);
      expect(model.request(_sara), isTrue);
      expect(model.cancel(_sara), isTrue);
      final before = model.snapshot();
      now = now.add(const Duration(days: 5));
      model.reset();
      expect(model.pastRequests, isEmpty);
      expect(model.snapshot().pastRequestSequence, 0);
      expect(model.snapshot().pendingRequestedAt, {_amira: now});
      expect(
        model.receivedRequestRevision(_amira),
        greaterThan(before.receivedActivityRevision),
      );
      expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
      expect(before.pastRequests.length, 1);
    },
  );

  test(
    'Journey scenario reset clears Past without resetting arrival revision',
    () {
      expect(model.request(_sara), isTrue);
      expect(model.cancel(_sara), isTrue);
      final arrival = model.receivedActivityRevision;
      expect(model.seedJourneys(3), isTrue);
      expect(model.pastRequests, isEmpty);
      expect(model.receivedActivityRevision, greaterThan(arrival));
      expect(model.snapshot().pendingRequestedAt, {_amira: now});
      expect(model.occupiedCount, 3);
      expect(
        ViewRequestDraftModel.fromSnapshot(model.snapshot()).occupiedCount,
        3,
      );
    },
  );

  test(
    'same-peer new arrival preserves Past and unrelated acknowledgement',
    () {
      expect(model.seedReceived(_sara), isTrue);
      expect(model.acknowledgeReceivedRequests([_amira, _sara]), isTrue);
      final arrival = model.receivedActivityRevision;
      expect(model.declineReceived(_amira), isTrue);
      final past = model.pastRequests.single;
      now = now.add(const Duration(days: 1));
      expect(model.seedReceived(_amira), isTrue);
      expect(model.receivedRequestRevision(_amira), greaterThan(arrival));
      expect(model.snapshot().acknowledgedReceivedRequestIds, {_sara});
      expect(model.pastRequests, [past]);
      expect(model.snapshot().pendingRequestedAt[_amira], now);
      expect(model.hasUnseenReceivedRequest(_sara), isFalse);
      expect(model.hasUnseenReceivedRequest(_amira), isTrue);
    },
  );

  test(
    'UTC normalization preserves original instants and cooldown on restore',
    () {
      final original = DateTime(2026, 9, 10, 12);
      final moved = DateTime(2026, 9, 12, 12);
      expect(
        model.seedPastRequest(
          profileId: _aisha,
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: original,
          movedAt: moved,
        ),
        isTrue,
      );
      final snapshot = model.snapshot();
      final entry = snapshot.pastRequests.single;
      expect(entry.requestedAt.isUtc, isTrue);
      expect(entry.movedAt.isUtc, isTrue);
      expect(entry.requestedAt, original.toUtc());
      final restored = ViewRequestDraftModel.fromSnapshot(
        snapshot,
        clock: () => now,
      );
      now = moved
          .toUtc()
          .add(const Duration(days: 30))
          .subtract(const Duration(microseconds: 1));
      expect(restored.canRequest(_aisha), isFalse);
      now = moved.toUtc().add(const Duration(days: 30));
      expect(restored.canRequest(_aisha), isTrue);
      expect(
        restored.receivedActivityRevision,
        snapshot.receivedActivityRevision,
      );
      expect(restored.pastRequests, [entry]);
    },
  );

  test(
    'backward transition date refuses atomically without losing a request',
    () {
      expect(model.request(_sara), isTrue);
      final sent = now;
      now = now.subtract(const Duration(days: 1));
      expect(model.cancel(_sara), isFalse);
      expect(model.declineReceived(_amira), isFalse);
      expect(model.pastRequests, isEmpty);
      expect(model.stateFor(_sara), DraftJourneyState.sent);
      expect(model.stateFor(_amira), DraftJourneyState.received);
      expect(model.snapshot().pendingRequestedAt, {_amira: sent, _sara: sent});
      now = sent;
      expect(model.cancel(_sara), isTrue);
      expect(model.declineReceived(_amira), isTrue);
      expect(
        ViewRequestDraftModel.fromSnapshot(
          model.snapshot(),
        ).pastRequests.length,
        2,
      );
    },
  );
}
