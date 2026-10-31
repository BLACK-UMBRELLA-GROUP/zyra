import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _amira = 'draft-amira';
const _sara = 'draft-sara';
const _noor = 'draft-noor';

void main() {
  test('only accepting our sent request records outgoing provenance', () {
    final now = DateTime.utc(2026, 10, 31, 9);
    final model = ViewRequestDraftModel(capacity: 3, clock: () => now);
    expect(model.acceptReceived(_amira), isTrue);
    expect(model.stateFor(_amira), DraftJourneyState.preparing);
    expect(model.outgoingRequestAcceptedAt(_amira), isNull);
    expect(model.outgoingRequestAcceptedRevision(_amira), isNull);
    expect(model.outgoingAcceptedActivityRevision, 0);

    expect(model.request(_sara), isTrue);
    expect(model.outgoingRequestAcceptedAt(_sara), isNull);
    expect(model.simulateRecipientAccept(_sara), isTrue);
    expect(model.stateFor(_sara), DraftJourneyState.preparing);
    expect(model.outgoingRequestAcceptedAt(_sara), now);
    expect(model.outgoingRequestAcceptedRevision(_sara), 1);
    expect(model.outgoingAcceptedActivityRevision, 1);
  });

  test('refused acceptance does not record or refresh an event', () {
    var now = DateTime.utc(2026, 10, 31, 9);
    final model = ViewRequestDraftModel(clock: () => now);
    expect(model.simulateRecipientAccept(_amira), isFalse);
    expect(model.simulateRecipientAccept('not-a-fixture'), isFalse);
    expect(model.outgoingAcceptedActivityRevision, 0);
    expect(model.request(_sara), isTrue);
    expect(model.simulateRecipientAccept(_sara), isTrue);
    final accepted = model.outgoingRequestAcceptedAt(_sara);
    now = now.add(const Duration(hours: 1));
    expect(model.simulateRecipientAccept(_sara), isFalse);
    expect(model.outgoingRequestAcceptedAt(_sara), accepted);
    expect(model.outgoingAcceptedActivityRevision, 1);
  });

  test('later readiness and ending retain the immutable acceptance time', () {
    var now = DateTime.utc(2026, 10, 31, 9);
    final model = ViewRequestDraftModel(clock: () => now);
    expect(model.request(_sara), isTrue);
    expect(model.simulateRecipientAccept(_sara), isTrue);
    final accepted = model.outgoingRequestAcceptedAt(_sara);
    final revision = model.outgoingRequestAcceptedRevision(_sara);
    now = now.add(const Duration(minutes: 10));
    expect(model.markReady(_sara), isTrue);
    expect(model.lastActivityFor(_sara), now);
    expect(model.outgoingRequestAcceptedAt(_sara), accepted);
    now = now.add(const Duration(minutes: 10));
    expect(model.simulatePeerReady(_sara), isTrue);
    expect(model.end(_sara), isTrue);
    expect(model.lastActivityFor(_sara), now);
    expect(model.outgoingRequestAcceptedAt(_sara), accepted);
    expect(model.outgoingRequestAcceptedRevision(_sara), revision);
  });

  test('same-time accepted requests retain distinct stable event ordering', () {
    final now = DateTime.utc(2026, 10, 31, 9);
    final model = ViewRequestDraftModel(capacity: 3, clock: () => now);
    for (final id in [_sara, _noor]) {
      expect(model.request(id), isTrue);
      expect(model.simulateRecipientAccept(id), isTrue);
      expect(model.outgoingRequestAcceptedAt(id), now);
    }
    expect(
      model.outgoingRequestAcceptedRevision(_noor),
      greaterThan(model.outgoingRequestAcceptedRevision(_sara)!),
    );
    expect(model.outgoingAcceptedActivityRevision, 2);
  });

  test(
    'outgoing acceptance precedes capacity replacement; incoming has no event',
    () {
      final now = DateTime.utc(2026, 10, 31, 9);
      final outgoing = ViewRequestDraftModel(capacity: 3, clock: () => now)
        ..fillCapacity();
      expect(outgoing.request(_noor), isTrue);
      expect(outgoing.simulateRecipientAccept(_noor), isTrue);
      expect(outgoing.stateFor(_noor), DraftJourneyState.acceptedWaiting);
      expect(outgoing.outgoingRequestAcceptedAt(_noor), now);
      expect(
        outgoing.replaceJourneyForRequest(_noor, _sara, incoming: false),
        isTrue,
      );
      expect(outgoing.outgoingRequestAcceptedAt(_noor), now);
      expect(outgoing.outgoingRequestAcceptedRevision(_noor), 1);

      final incoming = ViewRequestDraftModel(capacity: 3, clock: () => now)
        ..fillCapacity();
      expect(
        incoming.replaceJourneyForRequest(_amira, _sara, incoming: true),
        isTrue,
      );
      expect(incoming.outgoingRequestAcceptedAt(_amira), isNull);
      expect(incoming.outgoingAcceptedActivityRevision, 0);
    },
  );

  test('snapshot restores detached UTC event times and owner sequence', () {
    final localTime = DateTime(2026, 10, 31, 9);
    final original = ViewRequestDraftModel(capacity: 3, clock: () => localTime);
    expect(original.request(_sara), isTrue);
    expect(original.simulateRecipientAccept(_sara), isTrue);
    final snapshot = original.snapshot();
    expect(snapshot.outgoingRequestAcceptedAt[_sara]!.isUtc, isTrue);
    expect(
      () => snapshot.outgoingRequestAcceptedAt.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.outgoingRequestAcceptedRevisions.clear(),
      throwsUnsupportedError,
    );
    final restored = ViewRequestDraftModel.fromSnapshot(
      snapshot,
      clock: () => localTime,
    );
    expect(restored.outgoingRequestAcceptedAt(_sara), localTime.toUtc());
    expect(restored.outgoingRequestAcceptedRevision(_sara), 1);
    expect(restored.outgoingAcceptedActivityRevision, 1);
    expect(restored.request(_noor), isTrue);
    expect(restored.simulateRecipientAccept(_noor), isTrue);
    expect(restored.outgoingRequestAcceptedRevision(_noor), 2);
    expect(original.outgoingRequestAcceptedAt(_noor), isNull);
    original.reset();
    expect(snapshot.outgoingRequestAcceptedAt[_sara], localTime.toUtc());
    expect(snapshot.outgoingRequestAcceptedRevisions[_sara], 1);
    expect(snapshot.outgoingAcceptedActivityRevision, 1);
  });

  test(
    'reset and seeded Journeys clear provenance without inferring events',
    () {
      final now = DateTime.utc(2026, 10, 31, 9);
      final model = ViewRequestDraftModel(capacity: 3, clock: () => now);
      expect(model.request(_sara), isTrue);
      expect(model.simulateRecipientAccept(_sara), isTrue);
      model.reset();
      expect(model.snapshot().outgoingRequestAcceptedAt, isEmpty);
      expect(model.snapshot().outgoingRequestAcceptedRevisions, isEmpty);
      expect(model.outgoingAcceptedActivityRevision, 1);
      expect(model.request(_sara), isTrue);
      expect(model.simulateRecipientAccept(_sara), isTrue);
      expect(model.outgoingRequestAcceptedRevision(_sara), 2);
      expect(model.seedJourneys(3), isTrue);
      expect(model.activeCount, 3);
      expect(model.snapshot().outgoingRequestAcceptedAt, isEmpty);
      expect(model.snapshot().outgoingRequestAcceptedRevisions, isEmpty);
      expect(model.outgoingAcceptedActivityRevision, 2);
      final restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
      expect(restored.snapshot().outgoingRequestAcceptedAt, isEmpty);
      expect(restored.outgoingAcceptedActivityRevision, 2);
    },
  );
}
