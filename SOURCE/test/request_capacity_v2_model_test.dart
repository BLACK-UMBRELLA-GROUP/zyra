import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _received = 'draft-amira';
const _ending = 'draft-sara';
const _other = 'draft-aisha';
const _third = 'draft-maryam';
const _sent = 'draft-noor';
const _spare = 'draft-hana';
const _paid = 'draft-guardian-yusuf';

// Fictional state only. Waiting is deliberately separate from Journey progress,
// paid Guardian grants, server authority and the three reserved places.
void main() {
  late ViewRequestDraftModel model;
  var now = DateTime.utc(2026, 10, 31, 14);

  Map<String, Object?> values(ViewRequestDraftModel value) {
    final snapshot = value.snapshot();
    return {
      'states': snapshot.states,
      'busy': snapshot.busyPeers,
      'attempts': snapshot.attemptRevisions,
      'attemptSequence': snapshot.attemptSequence,
      'waiting': snapshot.waitingAcceptances,
      'waitingSequence': snapshot.acceptanceIntentSequence,
      'requested': snapshot.pendingRequestedAt,
      'progress': snapshot.progress,
      'ended': snapshot.endedAttempts,
      'endedIds': snapshot.currentEndedAttemptIds,
      'past': snapshot.pastRequests,
      'accepted': snapshot.outgoingRequestAcceptedAt,
      'acceptedRevision': snapshot.outgoingRequestAcceptedRevisions,
      'acceptedSequence': snapshot.outgoingAcceptedActivityRevision,
      'guardian': snapshot.guardianAccess,
      'paid': snapshot.requiredPaidGuardianAccess,
    };
  }

  void start(String id) {
    expect(model.request(id), isTrue);
    expect(model.simulateRecipientAccept(id), isTrue);
    expect(
      model.completePreparation(id, agreedPaidAdditionalGuardianIds: {_paid}),
      isTrue,
    );
  }

  void full({bool paidEnding = false}) {
    if (paidEnding) {
      start(_ending);
      start(_other);
      start(_third);
    } else {
      model.fillCapacity();
    }
    expect(model.occupiedCount, 3);
  }

  void hold() {
    full(paidEnding: true);
    expect(model.setPeerOccupied(_received, true), isTrue);
    expect(
      model.replaceJourneyForRequest(_received, _ending, incoming: true),
      isTrue,
    );
  }

  setUp(() {
    now = DateTime.utc(2026, 10, 31, 14);
    model = ViewRequestDraftModel(capacity: 3, clock: () => now);
  });

  test('V2 both free accept prepares with no readiness or private access', () {
    expect(model.acceptReceived(_received), isTrue);
    expect(model.stateFor(_received), DraftJourneyState.preparing);
    expect(model.occupiedCount, 1);
    expect(model.isAcceptedWaiting(_received), isFalse);
    expect(model.isReady(_received), isFalse);
    expect(model.peerIsReady(_received), isFalse);
    expect(model.conversationOpen(_received), isFalse);
    expect(model.compatibilityRevealed(_received), isFalse);
    expect(model.outgoingRequestAcceptedAt(_received), isNull);
  });

  test(
    'V2 only you full ends one chosen attempt and Begin still gates Salam',
    () {
      full();
      expect(model.acceptReceived(_received), isFalse);
      expect(model.canAttemptAccept(_received), isTrue);
      expect(
        model.replaceJourneyForRequest(_received, _ending, incoming: true),
        isTrue,
      );
      expect(model.stateFor(_ending), DraftJourneyState.ended);
      expect(model.stateFor(_received), DraftJourneyState.preparing);
      expect(model.occupiedCount, 3);
      expect(model.beginPreparedJourney(_received), isFalse);
      expect(model.markReady(_received), isTrue);
      expect(model.beginPreparedJourney(_received), isFalse);
      expect(model.simulatePeerReady(_received), isTrue);
      expect(model.beginPreparedJourney(_received), isFalse);
      expect(
        model.beginPreparedJourney(
          _received,
          agreedPaidAdditionalGuardianIds: {_paid},
        ),
        isTrue,
      );
      expect(model.stageFor(_received)?.value, 'salam_exchange');
      expect(model.occupiedCount, 3);
    },
  );

  test('V2 only peer full waits without reserving a local place', () {
    expect(model.setPeerOccupied(_received, true), isTrue);
    expect(model.canAttemptAccept(_received), isTrue);
    expect(model.acceptReceived(_received), isTrue);
    expect(model.stateFor(_received), DraftJourneyState.acceptedWaiting);
    expect(model.waitingIsIncoming(_received), isTrue);
    expect(model.heldEndingId(_received), isNull);
    expect(model.occupiedCount, 0);
    expect(model.snapshot().progress.containsKey(_received), isFalse);
    expect(model.markReady(_received), isFalse);
    expect(model.simulatePeerReady(_received), isFalse);
    expect(model.end(_received), isFalse);
    expect(model.conversationOpen(_received), isFalse);
    expect(model.compatibilityRevealed(_received), isFalse);
    expect(model.outgoingRequestAcceptedAt(_received), isNull);
    expect(model.confirmWaitingRequest(_received), isTrue);
    expect(model.stateFor(_received), DraftJourneyState.preparing);
    expect(model.isAcceptedWaiting(_received), isFalse);
    expect(model.occupiedCount, 1);
    expect(model.isReady(_received), isFalse);
    expect(model.peerIsReady(_received), isFalse);
  });

  test(
    'V2 both full holds occupied attempt and paid grant until confirmation',
    () {
      hold();
      final chosen = model.snapshot().progress[_ending];
      final acceptance = model.acceptanceIntentRevision(_received);
      expect(model.stateFor(_ending), DraftJourneyState.active);
      expect(model.stateFor(_received), DraftJourneyState.acceptedWaiting);
      expect(model.heldEndingId(_received), _ending);
      expect(model.occupiedCount, 3);
      expect(model.snapshot().endedAttempts, isEmpty);
      expect(
        model.snapshot().requiredPaidGuardianAccess,
        contains('$_paid|$_ending'),
      );
      expect(model.confirmWaitingRequest(_received), isTrue);
      expect(model.stateFor(_ending), DraftJourneyState.ended);
      expect(model.snapshot().progress[_ending], chosen);
      expect(model.currentEndedAttemptFor(_ending)?.progress, chosen);
      expect(
        model.snapshot().requiredPaidGuardianAccess,
        isNot(contains('$_paid|$_ending')),
      );
      expect(model.stateFor(_received), DraftJourneyState.preparing);
      expect(model.occupiedCount, 3);
      expect(model.acceptanceIntentRevision(_received), isNull);
      expect(acceptance, isNotNull);
      final after = values(model);
      expect(model.confirmWaitingRequest(_received), isFalse);
      expect(model.letAcceptedRequestGo(_received), isFalse);
      expect(values(model), after);
    },
  );

  test('V2 held preparing attempt preserves its readiness until confirmed', () {
    expect(model.request(_ending), isTrue);
    expect(model.simulateRecipientAccept(_ending), isTrue);
    expect(model.markReady(_ending), isTrue);
    start(_other);
    start(_third);
    expect(model.setPeerOccupied(_received, true), isTrue);
    expect(
      model.replaceJourneyForRequest(_received, _ending, incoming: true),
      isTrue,
    );
    expect(model.stateFor(_ending), DraftJourneyState.preparing);
    expect(model.isReady(_ending), isTrue);
    expect(model.peerIsReady(_ending), isFalse);
    expect(model.confirmWaitingRequest(_received), isTrue);
    expect(model.currentEndedAttemptFor(_ending)?.progress.ready, isTrue);
    expect(model.currentEndedAttemptFor(_ending)?.progress.peerReady, isFalse);
    expect(model.isReady(_received), isFalse);
    expect(model.peerIsReady(_received), isFalse);
  });

  for (final held in [false, true]) {
    test(
      'V2 ${held ? 'held' : 'unheld'} peer does not go ahead changes no Journey',
      () {
        if (held) {
          hold();
        } else {
          expect(model.setPeerOccupied(_received, true), isTrue);
          expect(model.acceptReceived(_received), isTrue);
        }
        final before = model.snapshot();
        now = now.add(const Duration(hours: 1));
        expect(model.letAcceptedRequestGo(_received), isTrue);
        expect(model.stateFor(_received), isNull);
        expect(model.snapshot().progress, before.progress);
        expect(model.snapshot().endedAttempts, before.endedAttempts);
        expect(
          model.snapshot().requiredPaidGuardianAccess,
          before.requiredPaidGuardianAccess,
        );
        expect(
          model.pastRequests.single.outcome,
          DraftPastRequestOutcome.notTakenUp,
        );
        expect(model.pastRequests.single.incoming, isTrue);
        expect(
          model.pastRequests.single.requestedAt,
          before.pendingRequestedAt[_received],
        );
        expect(model.pastRequests.single.movedAt, now);
        expect(model.confirmWaitingRequest(_received), isFalse);
        expect(model.letAcceptedRequestGo(_received), isFalse);
        expect(model.setPeerOccupied(_received, false), isTrue);
        // This was received; only our own sent Not-taken-up requests carry
        // the existing sender cooldown.
        expect(model.canRequest(_received), isTrue);
        now = now.add(const Duration(days: 30));
        expect(model.canRequest(_received), isTrue);
        ViewRequestDraftModel.fromSnapshot(model.snapshot());
      },
    );
  }

  test('V2 waiting does not reserve a place needed by a different request', () {
    expect(model.setPeerOccupied(_received, true), isTrue);
    expect(model.acceptReceived(_received), isTrue);
    start(_ending);
    start(_other);
    start(_third);
    final before = values(model);
    expect(model.confirmWaitingRequest(_received), isFalse);
    expect(values(model), before);
    expect(model.end(_third), isTrue);
    expect(model.confirmWaitingRequest(_received), isTrue);
    expect(model.occupiedCount, 3);
  });

  test(
    'V2 stale held chosen ending refuses without consuming another place',
    () {
      hold();
      expect(model.end(_ending), isTrue);
      final before = values(model);
      expect(model.confirmWaitingRequest(_received), isFalse);
      expect(values(model), before);
      final restored = ViewRequestDraftModel.fromSnapshot(model.snapshot());
      final detached = values(restored);
      expect(restored.confirmWaitingRequest(_received), isFalse);
      expect(values(restored), detached);
      expect(restored.stateFor(_other), DraftJourneyState.active);
      expect(restored.stateFor(_third), DraftJourneyState.active);
    },
  );

  test(
    'V2 competing held requests cannot consume the same occupied attempt twice',
    () {
      hold();
      expect(model.seedReceived(_sent), isTrue);
      expect(model.setPeerOccupied(_sent, true), isTrue);
      expect(
        model.replaceJourneyForRequest(_sent, _ending, incoming: true),
        isTrue,
      );
      expect(model.confirmWaitingRequest(_received), isTrue);
      final before = values(model);
      expect(model.confirmWaitingRequest(_sent), isFalse);
      expect(values(model), before);
      expect(model.occupiedCount, 3);
      expect(model.stateFor(_sent), DraftJourneyState.acceptedWaiting);
      ViewRequestDraftModel.fromSnapshot(model.snapshot());
    },
  );

  test('V2 blocked waiting target cannot confirm or decline a held ending', () {
    hold();
    expect(model.block(_received), isTrue);
    final before = values(model);
    expect(model.confirmWaitingRequest(_received), isFalse);
    expect(model.letAcceptedRequestGo(_received), isFalse);
    expect(values(model), before);
    expect(model.stateFor(_ending), DraftJourneyState.active);
  });

  test('V2 a blocked occupied chosen Journey can still end deliberately', () {
    hold();
    expect(model.block(_ending), isTrue);
    expect(model.confirmWaitingRequest(_received), isTrue);
    expect(model.isBlocked(_ending), isTrue);
    expect(model.stateFor(_ending), DraftJourneyState.ended);
    expect(model.occupiedCount, 3);
  });

  test(
    'V2 held waiting round trips as detached unmodifiable value records',
    () {
      hold();
      final snapshot = model.snapshot();
      expect(() => snapshot.waitingAcceptances.clear(), throwsUnsupportedError);
      expect(() => snapshot.attemptRevisions.clear(), throwsUnsupportedError);
      final restored = ViewRequestDraftModel.fromSnapshot(
        snapshot,
        clock: () => now,
      );
      final second = ViewRequestDraftModel.fromSnapshot(
        snapshot,
        clock: () => now,
      );
      expect(values(restored), values(model));
      expect(restored.confirmWaitingRequest(_received), isTrue);
      expect(second.stateFor(_ending), DraftJourneyState.active);
      expect(second.isAcceptedWaiting(_received), isTrue);
      expect(model.stateFor(_ending), DraftJourneyState.active);
      model.reset();
      expect(snapshot.waitingAcceptances[_received]?.heldEndingId, _ending);
      expect(second.confirmWaitingRequest(_received), isTrue);
      expect(snapshot.states[_ending], DraftJourneyState.active);
    },
  );

  test(
    'V2 reset clears held state and never reuses its intent or attempt revisions',
    () {
      hold();
      final waiting = model.acceptanceIntentRevision(_received)!;
      final attempt = model.snapshot().attemptRevisions[_ending]!;
      model.reset();
      expect(model.isAcceptedWaiting(_received), isFalse);
      expect(model.confirmWaitingRequest(_received), isFalse);
      hold();
      expect(model.acceptanceIntentRevision(_received), greaterThan(waiting));
      expect(model.snapshot().attemptRevisions[_ending], greaterThan(attempt));
    },
  );

  test('V2 sent acceptance at full capacity records event before choosing', () {
    full();
    expect(model.request(_sent), isTrue);
    final before = model.snapshot();
    expect(
      model.replaceJourneyForRequest(_sent, _ending, incoming: false),
      isFalse,
    );
    expect(model.simulateRecipientAccept(_sent), isTrue);
    expect(model.stateFor(_sent), DraftJourneyState.acceptedWaiting);
    expect(model.waitingIsIncoming(_sent), isFalse);
    expect(model.snapshot().progress, before.progress);
    expect(model.snapshot().endedAttempts, before.endedAttempts);
    expect(model.occupiedCount, 3);
    final accepted = model.outgoingRequestAcceptedAt(_sent);
    final revision = model.outgoingRequestAcceptedRevision(_sent);
    now = now.add(const Duration(hours: 1));
    expect(model.simulateRecipientAccept(_sent), isFalse);
    expect(
      model.replaceJourneyForRequest(_sent, _ending, incoming: false),
      isTrue,
    );
    expect(model.stateFor(_sent), DraftJourneyState.preparing);
    expect(model.stateFor(_ending), DraftJourneyState.ended);
    expect(model.outgoingRequestAcceptedAt(_sent), accepted);
    expect(model.outgoingRequestAcceptedRevision(_sent), revision);
    expect(model.occupiedCount, 3);
  });

  test(
    'V2 sent mirror confirmation commits peer held ending without details',
    () {
      full();
      expect(model.request(_sent), isTrue);
      expect(model.setPeerOccupied(_sent, true), isTrue);
      expect(model.simulateRecipientAccept(_sent), isTrue);
      expect(model.peerOccupied(_sent), isTrue);
      expect(
        model.replaceJourneyForRequest(_sent, _ending, incoming: false),
        isTrue,
      );
      expect(model.snapshot().busyPeers, isNot(contains(_sent)));
      expect(model.stateFor(_sent), DraftJourneyState.preparing);
      expect(model.occupiedCount, 3);
    },
  );

  test(
    'V2 sent let it go is passive history and keeps immutable acceptance',
    () {
      full();
      expect(model.request(_sent), isTrue);
      expect(model.simulateRecipientAccept(_sent), isTrue);
      final before = model.snapshot();
      expect(model.letAcceptedRequestGo(_sent), isTrue);
      expect(model.stateFor(_sent), isNull);
      expect(
        model.pastRequests.single.outcome,
        DraftPastRequestOutcome.youLetItGo,
      );
      expect(model.pastRequests.single.incoming, isFalse);
      expect(model.snapshot().progress, before.progress);
      expect(model.snapshot().endedAttempts, before.endedAttempts);
      expect(
        model.outgoingRequestAcceptedAt(_sent),
        before.outgoingRequestAcceptedAt[_sent],
      );
      final restored = ViewRequestDraftModel.fromSnapshot(
        model.snapshot(),
        clock: () => now,
      );
      expect(
        restored.outgoingRequestAcceptedRevision(_sent),
        before.outgoingRequestAcceptedRevisions[_sent],
      );
      expect(restored.request(_sent), isTrue);
      expect(restored.outgoingRequestAcceptedAt(_sent), isNull);
      expect(restored.simulateRecipientAccept(_sent), isTrue);
      expect(
        restored.outgoingRequestAcceptedRevision(_sent),
        greaterThan(before.outgoingRequestAcceptedRevisions[_sent]!),
      );
    },
  );

  for (final capacity in [1, 2, 3]) {
    for (final localFull in [false, true]) {
      for (final peerFull in [false, true]) {
        test(
          'V2 capacity $capacity localFull=$localFull peerFull=$peerFull obeys four cases',
          () {
            model = ViewRequestDraftModel(capacity: capacity, clock: () => now);
            if (localFull) model.fillCapacity();
            expect(model.setPeerOccupied(_received, peerFull), isTrue);
            final occupied = model.occupiedCount;
            expect(model.canAttemptAccept(_received), isTrue);
            if (localFull) {
              expect(model.canBrowse, capacity == 3);
              expect(model.acceptReceived(_received), isFalse);
              expect(
                model.replaceJourneyForRequest(
                  _received,
                  _ending,
                  incoming: true,
                ),
                isTrue,
              );
            } else {
              expect(model.acceptReceived(_received), isTrue);
            }
            if (peerFull) {
              expect(model.isAcceptedWaiting(_received), isTrue);
              expect(model.occupiedCount, occupied);
              expect(model.heldEndingId(_received), localFull ? _ending : null);
              if (localFull) {
                expect(model.stateFor(_ending), DraftJourneyState.active);
              }
              final snapshot = model.snapshot();
              final restored = ViewRequestDraftModel.fromSnapshot(
                snapshot,
                clock: () => now,
              );
              expect(restored.confirmWaitingRequest(_received), isTrue);
              expect(model.isAcceptedWaiting(_received), isTrue);
              expect(model.confirmWaitingRequest(_received), isTrue);
            }
            expect(model.stateFor(_received), DraftJourneyState.preparing);
            expect(model.occupiedCount, localFull ? capacity : 1);
            expect(model.isReady(_received), isFalse);
            expect(model.peerIsReady(_received), isFalse);
            expect(model.conversationOpen(_received), isFalse);
            expect(model.compatibilityRevealed(_received), isFalse);
            if (localFull) {
              expect(model.stateFor(_ending), DraftJourneyState.ended);
            }
            ViewRequestDraftModel.fromSnapshot(model.snapshot());
          },
        );
      }
    }

    test(
      'V2 capacity $capacity outgoing waiting snapshot preserves event before choice',
      () {
        model = ViewRequestDraftModel(capacity: capacity, clock: () => now);
        expect(model.request(_sent), isTrue);
        for (final id in [_ending, _other, _third].take(capacity)) {
          start(id);
        }
        expect(model.simulateRecipientAccept(_sent), isTrue);
        final accepted = model.outgoingRequestAcceptedAt(_sent);
        final revision = model.outgoingRequestAcceptedRevision(_sent);
        final snapshot = model.snapshot();
        final restored = ViewRequestDraftModel.fromSnapshot(
          snapshot,
          clock: () => now,
        );
        expect(restored.waitingIsIncoming(_sent), isFalse);
        expect(restored.occupiedCount, capacity);
        expect(
          restored.replaceJourneyForRequest(_sent, _ending, incoming: false),
          isTrue,
        );
        expect(restored.occupiedCount, capacity);
        expect(restored.stateFor(_sent), DraftJourneyState.preparing);
        expect(restored.outgoingRequestAcceptedAt(_sent), accepted);
        expect(restored.outgoingRequestAcceptedRevision(_sent), revision);
        expect(model.isAcceptedWaiting(_sent), isTrue);
        expect(snapshot.states[_ending], DraftJourneyState.active);
      },
    );
  }

  for (final capacity in [1, 2, 3]) {
    test(
      'V2 capacity $capacity outgoing waiting uses an independently freed place',
      () {
        model = ViewRequestDraftModel(capacity: capacity, clock: () => now);
        expect(model.request(_sent), isTrue);
        for (final id in [_ending, _other, _third].take(capacity)) {
          start(id);
        }
        expect(model.setPeerOccupied(_sent, true), isTrue);
        expect(model.simulateRecipientAccept(_sent), isTrue);
        final accepted = model.outgoingRequestAcceptedAt(_sent);
        final revision = model.outgoingRequestAcceptedRevision(_sent);
        final fullWaiting = values(model);
        expect(model.confirmWaitingRequest(_sent), isFalse);
        expect(values(model), fullWaiting);
        expect(model.end(_ending), isTrue);
        final ended = model.snapshot().endedAttempts;
        now = now.add(const Duration(minutes: 10));
        expect(model.confirmWaitingRequest(_sent), isTrue);
        expect(model.occupiedCount, capacity);
        expect(model.stateFor(_sent), DraftJourneyState.preparing);
        expect(model.snapshot().endedAttempts, ended);
        expect(model.snapshot().busyPeers, isNot(contains(_sent)));
        expect(model.outgoingRequestAcceptedAt(_sent), accepted);
        expect(model.outgoingRequestAcceptedRevision(_sent), revision);
        expect(model.isReady(_sent), isFalse);
        expect(model.peerIsReady(_sent), isFalse);
        final prepared = values(model);
        expect(model.confirmWaitingRequest(_sent), isFalse);
        expect(values(model), prepared);
      },
    );
  }

  for (final operation in ['confirm', 'let go', 'replace']) {
    test('V2 wrong or replayed waiting $operation has no side effects', () {
      full();
      final before = values(model);
      for (final id in ['', 'unknown', _received, _ending, _spare]) {
        expect(switch (operation) {
          'confirm' => model.confirmWaitingRequest(id),
          'let go' => model.letAcceptedRequestGo(id),
          _ => model.replaceJourneyForRequest(id, _other, incoming: false),
        }, isFalse);
      }
      expect(values(model), before);
    });
  }
}
