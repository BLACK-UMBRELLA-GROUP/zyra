import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _amira = 'draft-amira';
const _sara = 'draft-sara';
const _aisha = 'draft-aisha';

void main() {
  test(
    'initial arrival has a positive token without acknowledging its item',
    () {
      final model = ViewRequestDraftModel();
      expect(model.receivedActivityRevision, greaterThan(0));
      expect(
        model.receivedRequestRevision(_amira),
        model.receivedActivityRevision,
      );
      expect(model.receivedRequestRevision(_sara), isNull);
      expect(model.receivedRequestRevision('not-a-fixture'), isNull);
      expect(model.hasUnseenReceivedRequest(_amira), isTrue);
      expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
    },
  );

  test(
    'each new arrival advances the sequence without changing current items',
    () {
      final model = ViewRequestDraftModel();
      final initial = model.receivedRequestRevision(_amira)!;
      expect(model.acknowledgeReceivedRequests([_amira]), isTrue);
      expect(model.seedReceived(_sara), isTrue);
      final sara = model.receivedRequestRevision(_sara)!;
      expect(sara, greaterThan(initial));
      expect(model.seedReceived(_aisha), isTrue);
      expect(model.receivedRequestRevision(_aisha), greaterThan(sara));
      expect(
        model.receivedActivityRevision,
        model.receivedRequestRevision(_aisha),
      );
      expect(model.receivedRequestRevision(_amira), initial);
      expect(model.hasUnseenReceivedRequest(_amira), isFalse);
      expect(model.hasUnseenReceivedRequest(_sara), isTrue);
      expect(model.snapshot().acknowledgedReceivedRequestIds, {_amira});
      expect(model.occupiedCount, 0);
    },
  );

  test(
    'invalid and duplicate arrivals cannot overwrite requests or Journeys',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.request(_sara), isTrue);
      expect(model.simulateRecipientAccept(_sara), isTrue);
      expect(model.stateFor(_sara), DraftJourneyState.preparing);
      final before = model.snapshot();
      for (final id in ['not-a-fixture', '', _amira, _sara]) {
        expect(model.seedReceived(id), isFalse);
      }
      expect(model.receivedActivityRevision, before.receivedActivityRevision);
      expect(
        model.snapshot().receivedRequestRevisions,
        before.receivedRequestRevisions,
      );
      expect(model.states, before.states);
      expect(model.stateFor(_sara), DraftJourneyState.preparing);
      expect(model.snapshot().progress[_sara], before.progress[_sara]);
      expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
    },
  );

  test('item acknowledgements and visibility never manufacture an arrival', () {
    final model = ViewRequestDraftModel();
    final revision = model.receivedActivityRevision;
    expect(model.acknowledgeReceivedRequests([_amira]), isTrue);
    expect(model.acknowledgeReceivedRequests([_amira]), isFalse);
    expect(model.hide(_amira), isTrue);
    expect(model.block(_amira), isTrue);
    expect(model.receivedActivityRevision, revision);
    expect(model.receivedRequestRevision(_amira), revision);
    expect(model.snapshot().acknowledgedReceivedRequestIds, {_amira});
  });

  test(
    'a later request from a declined peer gets a newer unacknowledged token',
    () {
      final model = ViewRequestDraftModel();
      final old = model.receivedRequestRevision(_amira)!;
      expect(model.acknowledgeReceivedRequests([_amira]), isTrue);
      expect(model.declineReceived(_amira), isTrue);
      expect(model.receivedRequestRevision(_amira), isNull);
      expect(model.receivedActivityRevision, old);
      expect(model.seedReceived(_amira), isTrue);
      expect(model.receivedRequestRevision(_amira), greaterThan(old));
      expect(model.hasUnseenReceivedRequest(_amira), isTrue);
      expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
      final current = model.receivedActivityRevision;
      expect(model.seedReceived(_amira), isFalse);
      expect(model.receivedActivityRevision, current);
    },
  );

  test(
    'outgoing request and cancellation do not advance received activity',
    () {
      final model = ViewRequestDraftModel();
      final before = model.receivedActivityRevision;
      expect(model.request(_sara), isTrue);
      expect(model.receivedRequestRevision(_sara), isNull);
      expect(model.seedReceived(_sara), isFalse);
      expect(model.cancel(_sara), isTrue);
      expect(model.receivedActivityRevision, before);
      expect(model.seedReceived(_sara), isTrue);
      expect(model.receivedRequestRevision(_sara), greaterThan(before));
      expect(model.hasUnseenReceivedRequest(_sara), isTrue);
    },
  );

  test(
    'reset and Journey scenario reseeding stay newer than the old marker',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.seedReceived(_aisha), isTrue);
      var marker = model.receivedActivityRevision;
      expect(model.acknowledgeReceivedRequests([_amira, _aisha]), isTrue);
      model.reset();
      expect(model.receivedActivityRevision, greaterThan(marker));
      expect(
        model.receivedRequestRevision(_amira),
        model.receivedActivityRevision,
      );
      expect(model.hasUnseenReceivedRequest(_amira), isTrue);
      expect(model.receivedRequestRevision(_aisha), isNull);
      expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
      marker = model.receivedActivityRevision;
      expect(model.seedJourneys(3), isTrue);
      expect(model.receivedActivityRevision, greaterThan(marker));
      expect(
        model.receivedRequestRevision(_amira),
        model.receivedActivityRevision,
      );
      expect(model.occupiedCount, 3);
      final beforeInvalid = model.receivedActivityRevision;
      expect(model.seedJourneys(4), isFalse);
      expect(model.receivedActivityRevision, beforeInvalid);
    },
  );

  test(
    'accepting or replacing removes the current token without a new arrival',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      final first = model.receivedActivityRevision;
      expect(model.acceptReceived(_amira), isTrue);
      expect(model.receivedRequestRevision(_amira), isNull);
      expect(model.receivedActivityRevision, first);
      expect(model.seedReceived(_amira), isFalse);
      model.fillCapacity();
      final replacement = model.receivedActivityRevision;
      expect(
        model.replaceJourneyForRequest(_amira, _sara, incoming: true),
        isTrue,
      );
      expect(model.receivedRequestRevision(_amira), isNull);
      expect(model.receivedActivityRevision, replacement);
      expect(model.occupiedCount, 3);
    },
  );

  test(
    'snapshot preserves tokens and acknowledgements without implicit arrival',
    () {
      final original = ViewRequestDraftModel(capacity: 3);
      expect(original.seedReceived(_sara), isTrue);
      expect(original.acknowledgeReceivedRequests([_amira]), isTrue);
      final snapshot = original.snapshot();
      expect(
        () => snapshot.receivedRequestRevisions.clear(),
        throwsUnsupportedError,
      );
      final restored = ViewRequestDraftModel.fromSnapshot(snapshot);
      expect(
        restored.receivedActivityRevision,
        snapshot.receivedActivityRevision,
      );
      expect(
        restored.snapshot().receivedRequestRevisions,
        snapshot.receivedRequestRevisions,
      );
      expect(restored.snapshot().acknowledgedReceivedRequestIds, {_amira});
      expect(restored.hasUnseenReceivedRequest(_amira), isFalse);
      expect(restored.hasUnseenReceivedRequest(_sara), isTrue);
      expect(restored.declineReceived(_sara), isTrue);
      expect(restored.seedReceived(_sara), isTrue);
      expect(
        restored.receivedRequestRevision(_sara),
        greaterThan(snapshot.receivedActivityRevision),
      );
      expect(
        original.receivedRequestRevision(_sara),
        snapshot.receivedRequestRevisions[_sara],
      );
      expect(original.snapshot().acknowledgedReceivedRequestIds, {_amira});
      original.reset();
      expect(
        snapshot.receivedActivityRevision,
        lessThan(original.receivedActivityRevision),
      );
      expect(snapshot.receivedRequestRevisions[_amira], isNotNull);
      expect(snapshot.acknowledgedReceivedRequestIds, {_amira});
    },
  );
}
