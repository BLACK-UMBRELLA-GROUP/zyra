import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _sara = 'draft-sara';
const _maryam = 'draft-maryam';
const _amira = 'draft-amira';
const _noor = 'draft-noor';
const _aisha = 'draft-aisha';
const _zainab = 'draft-zainab';
const _yusuf = 'draft-guardian-yusuf';
final _now = DateTime.utc(2026, 11, 19, 12);

Map<String, Object?> _values(ViewRequestDraftModel model) {
  final value = model.snapshot();
  return {
    'capacity': value.capacity,
    'states': value.states,
    'attempts': value.attemptRevisions,
    'attemptSequence': value.attemptSequence,
    'progress': value.progress,
    'preparing': value.preparingRequests,
    'requestedAt': value.pendingRequestedAt,
    'waiting': value.waitingAcceptances,
    'waitingSequence': value.acceptanceIntentSequence,
    'receivedRevisions': value.receivedRequestRevisions,
    'receivedSequence': value.receivedActivityRevision,
    'acknowledged': value.acknowledgedReceivedRequestIds,
    'outgoingAcceptedAt': value.outgoingRequestAcceptedAt,
    'outgoingAcceptedRevisions': value.outgoingRequestAcceptedRevisions,
    'outgoingAcceptedSequence': value.outgoingAcceptedActivityRevision,
    'started': value.journeyStartedAt,
    'activity': value.journeyLastActivityAt,
    'past': value.pastRequests,
    'pastSequence': value.pastRequestSequence,
    'ended': value.endedAttempts,
    'endedCurrent': value.currentEndedAttemptIds,
    'restart': value.restartRequestedAt,
    'removedEnded': value.removedEndedAttemptIds,
    'guardianAccess': value.guardianAccess,
    'guardianViewAttempts': value.guardianViewAttempts,
    'paidAccess': value.requiredPaidGuardianAccess,
    'guardianMembership': value.guardianMemberships,
    'familyConsent': value.familyGuardianChatConsent,
    'peerMainOverrides': value.peerMainGuardianOverrides,
    'busy': value.busyPeers,
    'hidden': value.hiddenPeers,
    'blocked': value.blockedPeers,
    'peerBlocks': value.peerBlocks,
    'departed': value.departedPeers,
    'safetyRevision': model.personSafetyRevision,
  };
}

void main() {
  for (final stage in ZyraJourneyStages.previewAll) {
    test('panel Journey fixture restores ${stage.value} without advancing', () {
      final model = ViewRequestDraftModel(capacity: 3, clock: () => _now);
      expect(
        model.replacePreviewJourneys([(profileId: _sara, stage: stage.value)]),
        isTrue,
      );
      final saved = model.snapshot();
      final restored = ViewRequestDraftModel.fromSnapshot(
        saved,
        clock: () => _now,
      );
      expect(restored.stateFor(_sara), DraftJourneyState.active);
      expect(restored.occupiedCount, 1);
      expect(restored.isReady(_sara), isTrue);
      expect(restored.peerIsReady(_sara), isTrue);
      expect(restored.snapshot().progress, saved.progress);
      expect(restored.snapshot().attemptRevisions, saved.attemptRevisions);
      expect(restored.snapshot().journeyStartedAt[_sara], _now);
      expect(restored.lastActivityFor(_sara), _now);
      expect(restored.snapshot().preparingRequests, isEmpty);

      if (stage.value == 'life_snapshot_preview') {
        expect(restored.stageFor(_sara)?.value, 'compatibility_reveal');
        expect(restored.isBioStepOpen(_sara), isTrue);
        expect(restored.hasCompletedCompatibilityStep(_sara), isTrue);
        expect(restored.hasCompletedBioStep(_sara), isFalse);
        expect(restored.bioRevealed(_sara), isFalse);
        expect(restored.canCompleteBioStep(_sara), isFalse);
        expect(restored.advanceStage(_sara), isFalse);
        expect(restored.chooseBioReveal(_sara), isTrue);
        expect(restored.simulatePeerBioReveal(_sara), isTrue);
        expect(restored.chooseBioContinue(_sara), isTrue);
        expect(restored.simulatePeerBioContinue(_sara), isTrue);
        expect(restored.completeBioStep(_sara), isTrue);
        expect(restored.stageFor(_sara)?.value, 'wali_gate');
        ViewRequestDraftModel.fromSnapshot(restored.snapshot());
      } else {
        expect(restored.stageFor(_sara)?.value, stage.value);
        expect(restored.isBioStepOpen(_sara), isFalse);
        expect(restored.hasChosenStageContinue(_sara), isFalse);
        expect(restored.peerHasChosenStageContinue(_sara), isFalse);
        if (stage.value == 'salam_exchange') {
          expect(restored.salamComplete(_sara), isFalse);
          expect(restored.canViewJourneyCompatibility(_sara), isFalse);
          expect(restored.advanceStage(_sara), isFalse);
        } else if (stage.value == 'compatibility_reveal') {
          expect(restored.salamComplete(_sara), isTrue);
          expect(restored.compatibilityRevealed(_sara), isFalse);
          expect(restored.canViewJourneyBio(_sara), isFalse);
          expect(restored.advanceStage(_sara), isFalse);
        } else {
          expect(restored.canViewJourneyCompatibility(_sara), isTrue);
          expect(restored.canViewJourneyBio(_sara), isTrue);
          expect(restored.hasCompletedBioStep(_sara), isTrue);
        }
      }
      // Restoring and walking the detached fixture never edits its source.
      expect(model.snapshot().progress, saved.progress);
    });
  }

  test(
    'invalid Journey replacements are atomic, including state collisions',
    () {
      final model = ViewRequestDraftModel(capacity: 2, clock: () => _now);
      expect(model.seedReceived(_amira), isTrue);
      expect(model.request(_noor), isTrue);
      expect(
        model.replacePreviewJourneys([
          (profileId: _sara, stage: 'salam_exchange'),
        ]),
        isTrue,
      );
      final before = _values(model);
      final invalid = <List<({String profileId, String? stage})>>[
        [(profileId: 'ordinary-member', stage: 'salam_exchange')],
        [(profileId: _maryam, stage: 'unknown_stage')],
        [
          (profileId: _sara, stage: 'salam_exchange'),
          (profileId: _sara, stage: 'phase_1'),
        ],
        [
          (profileId: _sara, stage: 'salam_exchange'),
          (profileId: _maryam, stage: 'phase_1'),
          (profileId: _zainab, stage: 'phase_2'),
        ],
        [(profileId: _amira, stage: null)],
        [(profileId: _noor, stage: 'salam_exchange')],
      ];
      for (final rows in invalid) {
        expect(model.replacePreviewJourneys(rows), isFalse);
        expect(_values(model), before);
      }
      expect(model.setPreviewJourneyStage(_sara, 'unknown_stage'), isFalse);
      expect(model.setPreviewJourneyStage(_amira, 'phase_1'), isFalse);
      expect(
        model.setPreviewJourneyStage('ordinary-member', 'phase_1'),
        isFalse,
      );
      expect(_values(model), before);
      ViewRequestDraftModel.fromSnapshot(model.snapshot());
    },
  );

  test('preparing fixture keeps real readiness and preparation metadata', () {
    final model = ViewRequestDraftModel(capacity: 1, clock: () => _now);
    expect(
      model.replacePreviewJourneys([(profileId: _sara, stage: null)]),
      isTrue,
    );
    final restored = ViewRequestDraftModel.fromSnapshot(
      model.snapshot(),
      clock: () => _now,
    );
    expect(restored.stateFor(_sara), DraftJourneyState.preparing);
    expect(restored.occupiedCount, 1);
    expect(restored.activeCount, 0);
    expect(restored.isReady(_sara), isFalse);
    expect(restored.peerIsReady(_sara), isFalse);
    expect(restored.snapshot().journeyStartedAt.containsKey(_sara), isFalse);
    expect(restored.snapshot().preparingRequests[_sara]?.requestedAt, _now);
    expect(restored.snapshot().preparingRequests[_sara]?.acceptedAt, _now);
    expect(restored.beginPreparedJourney(_sara), isFalse);
    expect(restored.markReady(_sara), isTrue);
    expect(restored.simulatePeerReady(_sara), isTrue);
    expect(
      restored.beginPreparedJourney(
        _sara,
        agreedPaidAdditionalGuardianIds: {_yusuf},
      ),
      isTrue,
    );
    expect(restored.stageFor(_sara)?.value, 'salam_exchange');
    ViewRequestDraftModel.fromSnapshot(restored.snapshot());
  });

  test(
    'replacement and zero clear preserve requests and immutable history',
    () {
      final model = ViewRequestDraftModel(capacity: 3, clock: () => _now);
      expect(model.seedReceived(_amira), isTrue);
      expect(model.request(_noor), isTrue);
      expect(
        model.seedPastRequest(
          profileId: _aisha,
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: _now.subtract(const Duration(days: 25)),
          movedAt: _now.subtract(const Duration(days: 20)),
        ),
        isTrue,
      );
      expect(
        model.replacePreviewJourneys([(profileId: _zainab, stage: 'phase_1')]),
        isTrue,
      );
      expect(model.end(_zainab), isTrue);
      final saved = model.snapshot();
      expect(
        model.replacePreviewJourneys([
          (profileId: _sara, stage: 'salam_exchange'),
          (profileId: _maryam, stage: null),
        ]),
        isTrue,
      );
      final other = model.snapshot();
      expect(model.setPreviewJourneyStage(_sara, 'phase_2'), isTrue);
      expect(model.snapshot().progress[_maryam], other.progress[_maryam]);
      expect(
        model.attemptRevisionFor(_maryam),
        other.attemptRevisions[_maryam],
      );
      expect(model.replacePreviewJourneys(const []), isTrue);
      final cleared = model.snapshot();
      expect(model.occupiedCount, 0);
      expect(model.stateFor(_sara), isNull);
      expect(model.stateFor(_maryam), isNull);
      expect(model.stateFor(_amira), DraftJourneyState.received);
      expect(model.stateFor(_noor), DraftJourneyState.sent);
      expect(model.stateFor(_zainab), DraftJourneyState.ended);
      expect(cleared.pendingRequestedAt, saved.pendingRequestedAt);
      expect(cleared.receivedRequestRevisions, saved.receivedRequestRevisions);
      expect(cleared.pastRequests, saved.pastRequests);
      expect(cleared.endedAttempts, saved.endedAttempts);
      expect(cleared.currentEndedAttemptIds, saved.currentEndedAttemptIds);
      expect(
        model.replacePreviewJourneys([(profileId: _zainab, stage: 'phase_1')]),
        isFalse,
      );
      ViewRequestDraftModel.fromSnapshot(cleared);
    },
  );

  test('stage replacement retires old Guardian View and Chat grants', () {
    final model = ViewRequestDraftModel(capacity: 1, clock: () => _now);
    expect(
      model.replacePreviewJourneys([(profileId: _sara, stage: 'phase_1')]),
      isTrue,
    );
    final oldAttempt = model.attemptRevisionFor(_sara);
    final oldCircle = model.circleChatIdFor(_sara);
    expect(
      model.setSampleGuardianJourneyAccess(
        _yusuf,
        _sara,
        viewEnabled: true,
        chatEnabled: true,
      ),
      isTrue,
    );
    expect(
      model.hasGuardianViewForAttempt(_yusuf, _sara, oldAttempt, isMain: false),
      isTrue,
    );
    expect(model.setPreviewJourneyStage(_sara, 'phase_2'), isTrue);
    expect(model.attemptRevisionFor(_sara), isNot(oldAttempt));
    expect(model.circleChatIdFor(_sara), isNot(oldCircle));
    expect(
      model.hasGuardianViewForAttempt(_yusuf, _sara, oldAttempt, isMain: false),
      isFalse,
    );
    expect(
      model.hasGuardianViewForAttempt(
        _yusuf,
        _sara,
        model.attemptRevisionFor(_sara),
        isMain: false,
      ),
      isFalse,
    );
    expect(model.sampleGuardianAccessFor(_yusuf, _sara), (
      view: false,
      chat: false,
    ));
    expect(model.hasRequiredPaidGuardianAccess(_yusuf, _sara), isFalse);
    ViewRequestDraftModel.fromSnapshot(model.snapshot());
  });

  test('fresh attempt invalidates an accepted request held ending choice', () {
    final model = ViewRequestDraftModel(capacity: 1, clock: () => _now);
    expect(model.seedReceived(_amira), isTrue);
    expect(
      model.replacePreviewJourneys([(profileId: _sara, stage: 'phase_1')]),
      isTrue,
    );
    expect(model.setPeerOccupied(_amira, true), isTrue);
    expect(
      model.replaceJourneyForRequest(_amira, _sara, incoming: true),
      isTrue,
    );
    final oldIntent = model.acceptanceIntentRevision(_amira);
    final oldAttempt = model.attemptRevisionFor(_sara);
    final requestAttempt = model.attemptRevisionFor(_amira);
    expect(model.heldEndingId(_amira), _sara);
    expect(model.setPreviewJourneyStage(_sara, 'phase_2'), isTrue);
    expect(model.attemptRevisionFor(_sara), isNot(oldAttempt));
    expect(model.stateFor(_amira), DraftJourneyState.acceptedWaiting);
    expect(model.attemptRevisionFor(_amira), requestAttempt);
    expect(model.acceptanceIntentRevision(_amira), isNot(oldIntent));
    expect(model.heldEndingId(_amira), isNull);
    expect(model.confirmWaitingRequest(_amira), isFalse);
    expect(model.stateFor(_sara), DraftJourneyState.active);
    expect(model.snapshot().endedAttempts, isEmpty);
    ViewRequestDraftModel.fromSnapshot(model.snapshot());
  });
}
