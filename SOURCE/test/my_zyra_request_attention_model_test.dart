import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _received = 'draft-amira';
const _notReceived = 'draft-sara';

void main() {
  test('only a current known received request has unseen attention', () {
    final model = ViewRequestDraftModel(capacity: 3);
    final before = model.snapshot();

    expect(model.hasUnseenReceivedRequest(_received), isTrue);
    expect(model.hasUnseenReceivedRequest(_notReceived), isFalse);
    expect(model.hasUnseenReceivedRequest('not-a-fixture'), isFalse);
    expect(
      model.acknowledgeReceivedRequests([
        'not-a-fixture',
        _notReceived,
        _received,
        _received,
      ]),
      isTrue,
    );
    expect(model.hasUnseenReceivedRequest(_received), isFalse);
    expect(model.acknowledgeReceivedRequests([_received]), isFalse);
    expect(model.acknowledgeReceivedRequests(const <String>[]), isFalse);

    final after = model.snapshot();
    expect(after.acknowledgedReceivedRequestIds, {_received});
    expect(after.capacity, before.capacity);
    expect(after.states, before.states);
    expect(after.busyPeers, before.busyPeers);
    expect(after.hiddenPeers, before.hiddenPeers);
    expect(after.blockedPeers, before.blockedPeers);
    expect(after.progress, before.progress);
    expect(after.guardianMemberships, before.guardianMemberships);
    expect(after.guardianAccess, before.guardianAccess);
    expect(model.occupiedCount, 0);
    expect(model.stateFor(_received), DraftJourneyState.received);
  });

  test('Browse hiding does not suppress received-request attention', () {
    final model = ViewRequestDraftModel();
    expect(model.hide(_received), isTrue);
    expect(model.hasUnseenReceivedRequest(_received), isTrue);
    expect(model.acknowledgeReceivedRequests([_received]), isTrue);
    expect(model.hasUnseenReceivedRequest(_received), isFalse);
    expect(model.isHidden(_received), isTrue);
    expect(model.stateFor(_received), DraftJourneyState.received);
  });

  test('blocked requests cannot be acknowledged or shown as unseen', () {
    final model = ViewRequestDraftModel();
    expect(model.block(_received), isTrue);
    expect(model.hasUnseenReceivedRequest(_received), isFalse);
    expect(model.acknowledgeReceivedRequests([_received]), isFalse);
    expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
    expect(model.stateFor(_received), DraftJourneyState.received);
  });

  test('snapshot owns immutable detached attention and restores it', () {
    final model = ViewRequestDraftModel();
    final before = model.snapshot();
    expect(before.acknowledgedReceivedRequestIds, isEmpty);
    expect(model.acknowledgeReceivedRequests([_received]), isTrue);
    expect(before.acknowledgedReceivedRequestIds, isEmpty);

    final acknowledged = model.snapshot();
    expect(acknowledged.acknowledgedReceivedRequestIds, {_received});
    expect(
      () => acknowledged.acknowledgedReceivedRequestIds.add(_notReceived),
      throwsUnsupportedError,
    );
    final restored = ViewRequestDraftModel.fromSnapshot(acknowledged);
    expect(restored.hasUnseenReceivedRequest(_received), isFalse);
    expect(restored.snapshot().acknowledgedReceivedRequestIds, {_received});

    model.reset();
    expect(model.hasUnseenReceivedRequest(_received), isTrue);
    expect(acknowledged.acknowledgedReceivedRequestIds, {_received});
    expect(restored.hasUnseenReceivedRequest(_received), isFalse);
  });

  test('reset and valid reseed make the new sample request unseen again', () {
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.acknowledgeReceivedRequests([_received]), isTrue);
    expect(model.seedJourneys(4), isFalse);
    expect(model.hasUnseenReceivedRequest(_received), isFalse);

    expect(model.seedJourneys(2), isTrue);
    expect(model.hasUnseenReceivedRequest(_received), isTrue);
    expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
    expect(model.acknowledgeReceivedRequests([_received]), isTrue);
    model.reset();
    expect(model.hasUnseenReceivedRequest(_received), isTrue);
    expect(model.snapshot().acknowledgedReceivedRequestIds, isEmpty);
  });

  test('a terminal request is not falsely reintroduced by old attention', () {
    final model = ViewRequestDraftModel();
    expect(model.acknowledgeReceivedRequests([_received]), isTrue);
    expect(model.declineReceived(_received), isTrue);
    expect(model.hasUnseenReceivedRequest(_received), isFalse);
    expect(model.acknowledgeReceivedRequests([_received]), isFalse);

    final restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
    expect(restored.hasUnseenReceivedRequest(_received), isFalse);
    expect(restored.stateFor(_received), isNull);
  });
}
