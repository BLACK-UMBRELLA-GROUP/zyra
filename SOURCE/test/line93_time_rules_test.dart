import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';

const _peer = 'draft-sara';
const _tick = Duration(microseconds: 1);

void main() {
  late DateTime now;
  late ViewRequestDraftModel model;

  setUp(() {
    now = DateTime.utc(2026, 11, 12, 15);
    model = ViewRequestDraftModel(clock: () => now);
  });

  for (final incoming in [false, true]) {
    test('ready reminder and close apply to a request incoming=$incoming', () {
      if (incoming) {
        expect(model.seedReceived(_peer), isTrue);
        expect(model.acceptReceived(_peer), isTrue);
      } else {
        expect(model.request(_peer), isTrue);
        expect(model.simulateRecipientAccept(_peer), isTrue);
      }
      final acceptedAt = now;
      final reminderAt = acceptedAt.add(const Duration(hours: 48));
      final closesAt = acceptedAt.add(const Duration(hours: 72));
      expect(model.occupiedCount, 1);
      expect(model.peerOccupied(_peer), isTrue);
      now = reminderAt.subtract(_tick);
      expect(model.readyReminderAt(_peer), isNull);
      expect(model.readyReminderAt(_peer, forPeer: true), isNull);

      now = reminderAt;
      model.advanceTimeRules();
      expect(model.readyReminderAt(_peer), reminderAt);
      expect(model.readyReminderAt(_peer, forPeer: true), reminderAt);
      expect(model.markReady(_peer), isTrue);
      expect(model.readyReminderAt(_peer), isNull);
      expect(model.readyReminderAt(_peer, forPeer: true), reminderAt);

      now = closesAt.subtract(_tick);
      model = ViewRequestDraftModel.fromSnapshot(
        model.snapshot(),
        clock: () => now,
      );
      model.advanceTimeRules();
      expect(model.stateFor(_peer), DraftJourneyState.preparing);
      expect(model.readyReminderAt(_peer, forPeer: true), reminderAt);

      now = closesAt;
      expect(model.simulatePeerReady(_peer), isFalse);
      model.advanceTimeRules();
      expect(model.occupiedCount, 0);
      expect(model.peerOccupied(_peer), isFalse);
      expect(model.stateFor(_peer), isNull);
      expect(
        model.pastRequests.single.outcome,
        DraftPastRequestOutcome.notTakenUp,
      );
      expect(model.pastRequests.single.movedAt, closesAt);
      expect(model.pastRequests.single.incoming, incoming);
      expect(model.snapshot().endedAttempts, isEmpty);

      now = closesAt.add(const Duration(days: 7)).subtract(_tick);
      expect(model.canRequest(_peer), isFalse);
      now = now.add(_tick);
      expect(model.canRequest(_peer), isTrue);
    });
  }

  test(
    'two ready taps before the deadline preserve the deliberate Begin step',
    () {
      expect(model.request(_peer), isTrue);
      expect(model.simulateRecipientAccept(_peer), isTrue);
      now = now.add(const Duration(hours: 71));
      expect(model.markReady(_peer), isTrue);
      expect(model.simulatePeerReady(_peer), isTrue);
      now = now.add(const Duration(hours: 1));
      model.advanceTimeRules();
      expect(model.readyReminderAt(_peer), isNull);
      expect(model.pastRequests, isEmpty);
      expect(
        model.beginPreparedJourney(
          _peer,
          linkedGuardianIds: const {'draft-guardian-hassan'},
        ),
        isTrue,
      );
    },
  );

  test(
    'a restored request keeps chronological dates if the clock moved back',
    () {
      final sentAt = now;
      expect(model.request(_peer), isTrue);
      now = now.subtract(const Duration(days: 8));
      expect(model.simulateRecipientAccept(_peer), isTrue);
      final snapshot = model.snapshot();
      expect(snapshot.preparingRequests[_peer]?.requestedAt, sentAt);
      expect(snapshot.preparingRequests[_peer]?.acceptedAt, sentAt);
      model = ViewRequestDraftModel.fromSnapshot(snapshot, clock: () => now);
      now = sentAt.add(const Duration(hours: 72));
      expect(model.advanceTimeRules(), isTrue);
      expect(model.pastRequests.single.movedAt, now);
    },
  );

  test('restart opens after 24 hours and the new request lasts 30 days', () {
    expect(model.request(_peer), isTrue);
    expect(model.simulateRecipientAccept(_peer), isTrue);
    expect(model.end(_peer), isTrue);
    final attempt = model.currentEndedAttemptFor(_peer)!;
    now = now.add(const Duration(hours: 24)).subtract(_tick);
    expect(model.requestEndedJourney(_peer), isFalse);
    now = now.add(_tick);
    expect(model.requestEndedJourney(_peer), isTrue);
    final expiry = now.add(const Duration(days: 30));
    expect(model.restartExpiresAt(_peer), expiry);
    now = expiry.subtract(_tick);
    expect(model.requestEndedJourney(_peer), isFalse);
    model = ViewRequestDraftModel.fromSnapshot(
      model.snapshot(),
      clock: () => now,
    );
    expect(model.restartExpiresAt(_peer), expiry);
    now = expiry;
    model.advanceTimeRules();
    expect(model.restartExpiresAt(_peer), isNull);
    expect(model.requestEndedJourney(_peer), isTrue);
    expect(model.currentEndedAttemptFor(_peer), same(attempt));
    expect(model.stateFor(_peer), DraftJourneyState.ended);
  });

  test(
    'an ended attempt keeps its history through blocks from either side',
    () {
      expect(model.request(_peer), isTrue);
      expect(model.simulateRecipientAccept(_peer), isTrue);
      expect(model.end(_peer), isTrue);
      final attempt = model.currentEndedAttemptFor(_peer)!;
      now = now.add(const Duration(days: 365));
      expect(attempt.hasRecordedEnd(now), isTrue);
      expect(model.hasVisibleEndedJourney(_peer), isTrue);

      expect(model.block(_peer), isTrue);
      expect(model.setPeerBlock(_peer, true), isTrue);
      expect(model.hasVisibleEndedJourney(_peer), isFalse);
      expect(model.requestEndedJourney(_peer), isFalse);
      expect(model.unblock(_peer), isTrue);
      expect(model.hasVisibleEndedJourney(_peer), isFalse);
      expect(model.setPeerBlock(_peer, false), isTrue);
      expect(model.hasVisibleEndedJourney(_peer), isTrue);
      expect(model.currentEndedAttemptFor(_peer), same(attempt));
    },
  );

  for (final state in [DraftJourneyState.active, DraftJourneyState.ended]) {
    test(
      'account deletion purges all attempts and frees the place: $state',
      () {
        const kept = 'draft-aisha';
        model = ViewRequestDraftModel(capacity: 2, clock: () => now);
        expect(
          model.seedPastRequest(
            profileId: _peer,
            outcome: DraftPastRequestOutcome.youDeclined,
            requestedAt: now,
            movedAt: now,
          ),
          isTrue,
        );
        expect(model.request(_peer), isTrue);
        expect(model.simulateRecipientAccept(_peer), isTrue);
        expect(
          model.completePreparation(
            _peer,
            linkedGuardianIds: const {'draft-guardian-hassan'},
            mainGuardianId: 'draft-guardian-hassan',
          ),
          isTrue,
        );
        expect(model.seedReceived(kept), isTrue);
        DraftEndedJourneyAttempt? previousAttempt;
        if (state == DraftJourneyState.ended) {
          expect(model.end(_peer), isTrue);
          previousAttempt = model.currentEndedAttemptFor(_peer)!;
          now = now.add(const Duration(hours: 24));
          expect(model.requestEndedJourney(_peer), isTrue);
        }
        expect(model.markPeerDeparted(_peer), isTrue);
        expect(model.markPeerDeparted(_peer), isFalse);
        final restored = ViewRequestDraftModel.fromSnapshot(
          model.snapshot(),
          clock: () => now,
          earlierAttempts: [?previousAttempt],
        );
        expect(restored.departureNotices, {1: now});
        expect(restored.hasDeparted(_peer), isTrue);
        expect(restored.stateFor(_peer), isNull);
        expect(restored.occupiedCount, 0);
        expect(restored.peerOccupied(_peer), isFalse);
        expect(restored.attemptRevisionFor(_peer), isNull);
        expect(restored.pastRequests, isEmpty);
        expect(restored.currentEndedAttemptFor(_peer), isNull);
        expect(restored.endedAttemptsFor(_peer), isEmpty);
        expect(restored.restartExpiresAt(_peer), isNull);
        expect(restored.outgoingRequestAcceptedAt(_peer), isNull);
        expect(restored.canRequest(_peer), isFalse);
        expect(restored.seedReceived(_peer), isFalse);
        expect(
          restored.discoverableProfiles.map((p) => p.id),
          isNot(contains(_peer)),
        );
        expect(restored.stateFor(kept), DraftJourneyState.received);
      },
    );
  }

  test('a request-only deletion clears the request and its Past items', () {
    expect(
      model.seedPastRequest(
        profileId: _peer,
        outcome: DraftPastRequestOutcome.youDeclined,
        requestedAt: now,
        movedAt: now,
      ),
      isTrue,
    );
    expect(model.seedReceived(_peer), isTrue);
    expect(model.markPeerDeparted(_peer), isTrue);
    final restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
    expect(restored.stateFor(_peer), isNull);
    expect(restored.pastRequests, isEmpty);
    expect(restored.departureNotices, isEmpty);
  });

  test('deletion retires the held ending while the other request waits', () {
    const incoming = 'draft-aisha';
    expect(model.seedJourneys(1), isTrue);
    expect(model.seedReceived(incoming), isTrue);
    expect(model.setPeerOccupied(incoming, true), isTrue);
    expect(
      model.replaceJourneyForRequest(incoming, _peer, incoming: true),
      isTrue,
    );
    expect(model.heldEndingId(incoming), _peer);
    final priorIntent = model.acceptanceIntentRevision(incoming);
    expect(model.markPeerDeparted(_peer), isTrue);

    expect(model.occupiedCount, 0);
    expect(model.heldEndingId(incoming), isNull);
    expect(model.acceptanceIntentRevision(incoming), isNot(priorIntent));
    expect(model.stateFor(incoming), DraftJourneyState.acceptedWaiting);
    expect(model.confirmWaitingRequest(incoming), isTrue);
    expect(model.occupiedCount, 1);
    expect(model.stateFor(incoming), DraftJourneyState.preparing);
  });

  test('Circle preview excludes departed messages and read receipts', () {
    ZyraFamilyMessage message(String senderId) => ZyraFamilyMessage(
      id: senderId,
      senderId: senderId,
      senderFirstName: 'Preview',
      senderRoleLabel: 'Guardian',
      body: 'Sample message',
      createdAt: now,
      readBy: [
        ZyraFamilyMessageReader(
          userId: 'departed',
          firstName: 'Preview',
          roleLabel: 'Guardian',
          readAt: now,
        ),
      ],
    );
    final circle = ZyraGuardianCirclePreviewData(
      seekerId: 'seeker',
      senderId: 'seeker',
      canSend: false,
      participants: const [],
      messages: [message('kept'), message('departed')],
      departedMemberIds: const {'departed'},
    );
    expect(circle.messages.map((message) => message.id), ['kept']);
    expect(circle.messages.single.readBy, isEmpty);
  });
}
