import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

// Pure fictional-model evidence only. No UI, account, entitlement, storage or
// relationship service is instantiated by these tests.
void main() {
  late ViewRequestDraftModel model;
  final received = draftProfiles.first.id;
  final first = draftProfiles[1].id;
  final second = draftProfiles[2].id;
  final third = draftProfiles[3].id;
  final outgoing = draftProfiles[4].id;
  final spare = draftProfiles[5].id;

  Map<String, Object?> progress(String id) => {
    'stage': model.stageFor(id)?.value,
    'ready': model.isReady(id),
    'peerReady': model.peerIsReady(id),
    'salam': model.hasSentSalam(id),
    'peerSalam': model.peerHasSentSalam(id),
    'reveal': model.hasChosenCompatibilityReveal(id),
    'peerReveal': model.peerHasChosenCompatibilityReveal(id),
    'continue': model.hasChosenStageContinue(id),
    'peerContinue': model.peerHasChosenStageContinue(id),
  };

  Map<String, Object?> personSnapshot(String id) => {
    'state': model.stateFor(id),
    'progress': progress(id),
    'occupiedPeer': model.peerOccupied(id),
    'peerMain': model.peerMainGuardianPresentFor(id),
    'canRequest': model.canRequest(id),
    'canAccept': model.canAccept(id),
    'canAttemptAccept': model.canAttemptAccept(id),
    'canParticipate': model.canParticipateInJourney(id),
    'conversation': model.conversationOpen(id),
    'compatibilityRevealed': model.compatibilityRevealed(id),
    'guardianAccess': {
      for (final guardian in draftGuardians)
        guardian.id: [
          model.sampleGuardianAccessFor(guardian.id, id),
          model.sampleGuardianAccessFor(guardian.id, id, isMain: true),
        ],
    },
  };

  Map<String, Object?> snapshot() => {
    'capacity': model.capacity,
    'states': Map<String, DraftJourneyState>.of(model.states),
    'hidden': Set<String>.of(model.hiddenPeers),
    'blocked': Set<String>.of(model.blockedPeers),
    'active': model.activeCount,
    'preparing': model.preparingCount,
    'occupied': model.occupiedCount,
    'hasCapacity': model.hasCapacity,
    'canBrowse': model.canBrowse,
    'discoverable': model.discoverable,
    'profiles': model.discoverableProfiles.map((person) => person.id).toList(),
    'ownMain': model.ownMainGuardianPresent,
    'peerMain': model.peerMainGuardianPresent,
    'guardians': {
      for (final guardian in draftGuardians)
        guardian.id: model.sampleGuardianMembershipFor(guardian.id),
    },
    'people': {
      for (final person in draftProfiles) person.id: personSnapshot(person.id),
    },
  };

  void prepare(String id) {
    expect(model.request(id), isTrue);
    expect(model.simulateRecipientAccept(id), isTrue);
  }

  void start(String id) {
    prepare(id);
    expect(
      model.completePreparation(
        id,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isTrue,
    );
  }

  void full({DraftJourneyState endingState = DraftJourneyState.active}) {
    model = ViewRequestDraftModel(capacity: 3);
    prepare(first);
    if (endingState != DraftJourneyState.preparing) {
      expect(
        model.completePreparation(
          first,
          agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
        ),
        isTrue,
      );
      // Preserve a meaningful old checkpoint with one-sided reveal, not just
      // an empty stage object. Replacement must never copy it to a new peer.
      expect(model.sendSalam(first), isTrue);
      expect(model.simulatePeerSalam(first), isTrue);
      expect(model.chooseStageContinue(first), isTrue);
      expect(model.simulatePeerStageContinue(first), isTrue);
      expect(model.advanceStage(first), isTrue);
      expect(model.chooseCompatibilityReveal(first), isTrue);
    }
    start(second);
    start(third);
    expect(model.occupiedCount, 3);
    expect(model.stateFor(first), endingState);
  }

  String pending(bool incoming) {
    if (incoming) return received;
    expect(model.request(outgoing), isTrue);
    return outgoing;
  }

  void refuse(String requestId, String endingId, {required bool incoming}) {
    final before = snapshot();
    expect(
      model.canReplaceJourneyForRequest(
        requestId,
        endingId,
        incoming: incoming,
      ),
      isFalse,
    );
    expect(snapshot(), before, reason: 'Validation is read-only.');
    expect(
      model.replaceJourneyForRequest(requestId, endingId, incoming: incoming),
      isFalse,
    );
    expect(
      snapshot(),
      before,
      reason: 'A refused replacement is all-or-nothing.',
    );
  }

  setUp(() => model = ViewRequestDraftModel(capacity: 3));

  test(
    'full monthly browsing and request cancellation do not reserve a fourth place',
    () {
      full();
      final original = snapshot();
      expect(model.hasCapacity, isFalse);
      expect(model.canBrowse, isTrue);
      expect(model.discoverable, isFalse);
      expect(
        model.discoverableProfiles.map((person) => person.id),
        contains(outgoing),
      );
      expect(model.request(outgoing), isTrue);
      expect(model.stateFor(outgoing), DraftJourneyState.sent);
      expect(model.occupiedCount, 3);
      expect(model.preparingCount, 0);
      expect(model.canAccept(outgoing), isFalse);
      expect(model.canAttemptAccept(outgoing), isTrue);
      expect(model.simulateRecipientAccept(outgoing), isFalse);
      expect(model.acceptReceived(received), isFalse);
      expect(model.occupiedCount, 3);
      expect(model.cancel(outgoing), isTrue);
      expect(snapshot(), original);
    },
  );

  for (final capacity in [1, 2]) {
    test(
      'full capacity $capacity retains its previous Browse and acceptance hold',
      () {
        model = ViewRequestDraftModel(capacity: capacity);
        model.fillCapacity();
        expect(model.canBrowse, isFalse);
        expect(model.discoverable, isFalse);
        expect(model.canRequest(outgoing), isFalse);
        expect(model.request(outgoing), isFalse);
        expect(model.canAccept(received), isFalse);
        expect(model.canAttemptAccept(received), isFalse);
        expect(model.acceptReceived(received), isFalse);
        refuse(received, first, incoming: true);
        expect(model.occupiedCount, capacity);
      },
    );
  }

  test('ordinary acceptance still works only with a free reserved place', () {
    full();
    expect(model.canAttemptAccept(received), isTrue);
    expect(model.canAccept(received), isFalse);
    expect(model.end(first), isTrue);
    expect(model.canBrowse, isTrue);
    expect(model.discoverable, isTrue);
    expect(model.canAccept(received), isTrue);
    expect(model.canAttemptAccept(received), isTrue);
    refuse(received, second, incoming: true);
    expect(model.acceptReceived(received), isTrue);
    expect(model.occupiedCount, 3);
    expect(model.isReady(received), isFalse);
    expect(model.peerIsReady(received), isFalse);
  });

  for (final incoming in [true, false]) {
    for (final endingState in [
      DraftJourneyState.preparing,
      DraftJourneyState.active,
    ]) {
      test(
        'atomic ${incoming ? 'received' : 'sent'} replacement of ${endingState.name} preserves history',
        () {
          full(endingState: endingState);
          final target = pending(incoming);
          final oldProgress = progress(first);
          final otherPeople = {
            for (final person in draftProfiles)
              if (person.id != first && person.id != target)
                person.id: personSnapshot(person.id),
          };
          final beforeValidation = snapshot();
          expect(
            model.canReplaceJourneyForRequest(
              target,
              first,
              incoming: incoming,
            ),
            isTrue,
          );
          expect(snapshot(), beforeValidation);
          expect(
            model.replaceJourneyForRequest(target, first, incoming: incoming),
            isTrue,
          );
          expect(model.stateFor(first), DraftJourneyState.ended);
          expect(progress(first), oldProgress);
          expect(model.stateFor(target), DraftJourneyState.preparing);
          expect(model.stageFor(target), same(ZyraJourneyStages.all.first));
          expect(model.isReady(target), isFalse);
          expect(model.peerIsReady(target), isFalse);
          expect(model.hasSentSalam(target), isFalse);
          expect(model.peerHasSentSalam(target), isFalse);
          expect(model.hasChosenCompatibilityReveal(target), isFalse);
          expect(model.peerHasChosenCompatibilityReveal(target), isFalse);
          expect(model.hasChosenStageContinue(target), isFalse);
          expect(model.peerHasChosenStageContinue(target), isFalse);
          expect(model.canParticipateInJourney(target), isFalse);
          expect(model.conversationOpen(target), isFalse);
          expect(model.compatibilityRevealed(target), isFalse);
          expect(model.occupiedCount, 3);
          expect(model.activeCount + model.preparingCount, 3);
          expect(model.hasCapacity, isFalse);
          expect(model.discoverable, isFalse);
          for (final person in otherPeople.entries) {
            expect(personSnapshot(person.key), person.value);
          }
          expect(
            model.request(first),
            isFalse,
            reason:
                'Ending preserves the old attempt rather than reopening it.',
          );
          expect(
            model.beginPreparedJourney(
              target,
              agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
            ),
            isFalse,
          );
          expect(model.markReady(target), isTrue);
          expect(
            model.beginPreparedJourney(
              target,
              agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
            ),
            isFalse,
          );
          expect(model.simulatePeerReady(target), isTrue);
          expect(
            model.beginPreparedJourney(
              target,
              agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
            ),
            isTrue,
          );
          expect(model.occupiedCount, 3);
          expect(progress(first), oldProgress);
          refuse(target, second, incoming: incoming);
        },
      );
    }

    for (final invalid in [
      'unknown target',
      'blank target',
      'unknown ending',
      'blank ending',
      'same peer',
      'wrong direction',
      'blocked target',
      'busy target',
      'unrequested target',
      'active target',
      'pending ending',
      'ended ending',
      'not full',
    ]) {
      test(
        '${incoming ? 'received' : 'sent'} replacement refuses $invalid with an unchanged snapshot',
        () {
          full();
          var target = pending(incoming);
          var ending = first;
          var direction = incoming;
          switch (invalid) {
            case 'unknown target':
              target = 'real-member-id';
            case 'blank target':
              target = '';
            case 'unknown ending':
              ending = 'real-member-id';
            case 'blank ending':
              ending = '';
            case 'same peer':
              ending = target;
            case 'wrong direction':
              direction = !incoming;
            case 'blocked target':
              expect(model.block(target), isTrue);
            case 'busy target':
              expect(model.setPeerOccupied(target, true), isTrue);
            case 'unrequested target':
              target = spare;
            case 'active target':
              target = first;
              ending = second;
            case 'pending ending':
              expect(model.request(spare), isTrue);
              ending = spare;
            case 'ended ending':
              expect(model.end(first), isTrue);
              start(spare);
            case 'not full':
              expect(model.end(third), isTrue);
          }
          refuse(target, ending, incoming: direction);
        },
      );
    }

    test(
      '${incoming ? 'received' : 'sent'} replacement can end a blocked occupied old Journey',
      () {
        full();
        final target = pending(incoming);
        final history = progress(first);
        expect(model.block(first), isTrue);
        expect(
          model.canReplaceJourneyForRequest(target, first, incoming: incoming),
          isTrue,
        );
        expect(
          model.replaceJourneyForRequest(target, first, incoming: incoming),
          isTrue,
        );
        expect(model.isBlocked(first), isTrue);
        expect(model.stateFor(first), DraftJourneyState.ended);
        expect(progress(first), history);
        expect(model.stateFor(target), DraftJourneyState.preparing);
        expect(model.occupiedCount, 3);
      },
    );

    test(
      '${incoming ? 'received' : 'sent'} pending hide remains Browse-only and is not an acceptance prohibition',
      () {
        full();
        final target = pending(incoming);
        expect(model.hide(target), isTrue);
        expect(
          model.discoverableProfiles.map((person) => person.id),
          isNot(contains(target)),
        );
        expect(model.canAttemptAccept(target), isTrue);
        expect(
          model.replaceJourneyForRequest(target, first, incoming: incoming),
          isTrue,
        );
        expect(model.isHidden(target), isTrue);
        expect(model.stateFor(target), DraftJourneyState.preparing);
        expect(model.occupiedCount, 3);
      },
    );

    test(
      '${incoming ? 'received' : 'sent'} replay cannot end another Journey after replacement',
      () {
        full();
        final target = pending(incoming);
        expect(
          model.replaceJourneyForRequest(target, first, incoming: incoming),
          isTrue,
        );
        refuse(target, first, incoming: incoming);
        refuse(target, second, incoming: incoming);
        refuse(target, third, incoming: !incoming);
      },
    );

    for (final targetState in [
      DraftJourneyState.preparing,
      DraftJourneyState.active,
      DraftJourneyState.ended,
    ]) {
      test(
        '${incoming ? 'received' : 'sent'} replacement cannot reinterpret ${targetState.name} as a request',
        () {
          if (targetState == DraftJourneyState.preparing) {
            full(endingState: targetState);
          } else {
            full();
            if (targetState == DraftJourneyState.ended) {
              expect(model.end(first), isTrue);
              start(spare);
            }
          }
          expect(model.stateFor(first), targetState);
          expect(model.occupiedCount, 3);
          expect(model.canAttemptAccept(first), isFalse);
          refuse(first, second, incoming: incoming);
        },
      );
    }
  }

  test(
    'full Browse does not bypass target eligibility or terminal history',
    () {
      full();
      expect(model.canBrowse, isTrue);
      expect(model.block(outgoing), isTrue);
      expect(model.hide(spare), isTrue);
      final before = snapshot();
      for (final id in [
        outgoing,
        spare,
        first,
        '',
        'real-member-id',
        draftProfiles.last.id,
      ]) {
        expect(model.canRequest(id), isFalse);
        expect(model.request(id), isFalse);
        expect(snapshot(), before);
      }
      model.seedHistory();
      expect(model.stateFor(spare), DraftJourneyState.ended);
      expect(model.canRequest(spare), isFalse);
      expect(model.canAttemptAccept(spare), isFalse);
      expect(model.occupiedCount, 3);
    },
  );

  test(
    'blocked busy nonpending and unknown attempts remain held at full monthly capacity',
    () {
      full();
      final target = pending(false);
      expect(model.canAttemptAccept(target), isTrue);
      expect(model.setPeerOccupied(target, true), isTrue);
      expect(model.canAttemptAccept(target), isFalse);
      expect(model.setPeerOccupied(target, false), isTrue);
      expect(model.block(target), isTrue);
      expect(model.canAttemptAccept(target), isFalse);
      for (final id in [first, second, third, spare, '', 'real-member-id']) {
        expect(model.canAttemptAccept(id), isFalse);
      }
      expect(model.occupiedCount, 3);
    },
  );

  test(
    'successive confirmed replacements never exceed the three reserved places',
    () {
      full();
      expect(model.request(outgoing), isTrue);
      expect(model.request(spare), isTrue);
      expect(model.occupiedCount, 3);
      expect(
        model.replaceJourneyForRequest(outgoing, first, incoming: false),
        isTrue,
      );
      expect(model.occupiedCount, 3);
      expect(
        model.replaceJourneyForRequest(spare, second, incoming: false),
        isTrue,
      );
      expect(model.occupiedCount, 3);
      expect(model.activeCount, 1);
      expect(model.preparingCount, 2);
      expect(model.acceptReceived(received), isFalse);
      expect(
        model.replaceJourneyForRequest(received, third, incoming: true),
        isTrue,
      );
      expect(model.occupiedCount, 3);
      expect(model.activeCount, 0);
      expect(model.preparingCount, 3);
      for (final id in [first, second, third]) {
        expect(model.stateFor(id), DraftJourneyState.ended);
        expect(model.stageFor(id), isNotNull);
      }
    },
  );
}
