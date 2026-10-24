import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';

void _reachCompatibility(ViewRequestDraftModel model, [String id = _sara]) {
  expect(model.sendSalam(id), isTrue);
  expect(model.simulatePeerSalam(id), isTrue);
  expect(model.chooseStageContinue(id), isTrue);
  expect(model.simulatePeerStageContinue(id), isTrue);
  expect(model.advanceStage(id), isTrue);
  expect(model.stageFor(id)?.value, 'compatibility_reveal');
}

void _completeCompatibility(ViewRequestDraftModel model, [String id = _sara]) {
  expect(model.chooseCompatibilityReveal(id), isTrue);
  expect(model.simulatePeerCompatibilityReveal(id), isTrue);
  expect(model.chooseStageContinue(id), isTrue);
  expect(model.simulatePeerStageContinue(id), isTrue);
}

void _openBio(ViewRequestDraftModel model, [String id = _sara]) {
  _reachCompatibility(model, id);
  _completeCompatibility(model, id);
  expect(model.beginBioStep(id), isTrue);
}

void _readyBio(ViewRequestDraftModel model, [String id = _sara]) {
  expect(model.chooseBioReveal(id), isTrue);
  expect(model.simulatePeerBioReveal(id), isTrue);
  expect(model.chooseBioContinue(id), isTrue);
  expect(model.simulatePeerBioContinue(id), isTrue);
}

ViewRequestDraftModel _active() =>
    ViewRequestDraftModel(capacity: 3)..seedJourneys(3);

void _expectNoDisclosure(ViewRequestDraftModel model, String id) {
  expect(model.canViewJourneyCompatibility(id), isFalse);
  expect(model.canViewJourneyBio(id), isFalse);
}

void main() {
  test('canonical stages and legacy direct advancement remain unchanged', () {
    expect(ZyraJourneyStages.all, hasLength(8));
    expect(
      ZyraJourneyStages.all.map((stage) => stage.value),
      isNot(contains('life_snapshot_preview')),
    );
    final model = _active();
    _reachCompatibility(model);
    _completeCompatibility(model);
    expect(model.advanceStage(_sara), isTrue);
    expect(model.stageFor(_sara)?.value, 'wali_gate');
    expect(model.hasCompletedCompatibilityStep(_sara), isTrue);
    expect(model.canViewJourneyCompatibility(_sara), isTrue);
    expect(model.isBioStepOpen(_sara), isFalse);
    expect(model.bioRevealed(_sara), isFalse);
    expect(model.canViewJourneyBio(_sara), isFalse);
    expect(model.beginBioStep(_sara), isFalse);
    expect(model.chooseBioReveal(_sara), isFalse);
    expect(model.chooseStageContinue(_sara), isTrue);
    expect(model.simulatePeerStageContinue(_sara), isTrue);
    expect(model.advanceStage(_sara), isTrue);
    expect(model.stageFor(_sara)?.value, 'phase_1');
    expect(model.canViewJourneyBio(_sara), isFalse);
  });

  test(
    'request, preparation, unknown and Salam states cannot disclose or open Bio',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.request(_sara), isTrue);
      for (final id in ['unknown', 'draft-amira', _sara, _aisha]) {
        _expectNoDisclosure(model, id);
        expect(model.hasCompletedCompatibilityStep(id), isFalse);
        expect(model.beginBioStep(id), isFalse);
        expect(model.chooseBioReveal(id), isFalse);
        expect(model.simulatePeerBioReveal(id), isFalse);
        expect(model.chooseBioContinue(id), isFalse);
        expect(model.simulatePeerBioContinue(id), isFalse);
        expect(model.completeBioStep(id), isFalse);
      }
      expect(model.simulateRecipientAccept(_sara), isTrue);
      _expectNoDisclosure(model, _sara);
      expect(model.beginBioStep(_sara), isFalse);
      expect(
        model.completePreparation(
          _sara,
          agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
        ),
        isTrue,
      );
      _expectNoDisclosure(model, _sara);
      expect(model.beginBioStep(_sara), isFalse);
    },
  );

  test(
    'Compatibility completion requires both reveals and both Continue decisions',
    () {
      final model = _active();
      _reachCompatibility(model);
      _expectNoDisclosure(model, _sara);
      expect(model.beginBioStep(_sara), isFalse);
      expect(model.chooseCompatibilityReveal(_sara), isTrue);
      expect(model.hasCompletedCompatibilityStep(_sara), isFalse);
      expect(model.beginBioStep(_sara), isFalse);
      expect(model.simulatePeerCompatibilityReveal(_sara), isTrue);
      expect(model.compatibilityRevealed(_sara), isTrue);
      expect(model.hasCompletedCompatibilityStep(_sara), isFalse);
      _expectNoDisclosure(model, _sara);
      expect(model.beginBioStep(_sara), isFalse);
      expect(model.chooseStageContinue(_sara), isTrue);
      expect(model.beginBioStep(_sara), isFalse);
      expect(model.simulatePeerStageContinue(_sara), isTrue);
      expect(model.hasCompletedCompatibilityStep(_sara), isFalse);
      expect(model.beginBioStep(_sara), isTrue);
      expect(model.hasCompletedCompatibilityStep(_sara), isTrue);
      expect(model.canViewJourneyCompatibility(_sara), isTrue);
      expect(model.canViewJourneyBio(_sara), isFalse);
      expect(model.stageFor(_sara)?.value, 'compatibility_reveal');
    },
  );

  test(
    'Bio has independent mutual consent and an explicit two-person completion',
    () {
      final model = _active();
      _openBio(model);
      expect(model.compatibilityRevealed(_sara), isTrue);
      expect(model.hasChosenBioReveal(_sara), isFalse);
      expect(model.peerHasChosenBioReveal(_sara), isFalse);
      expect(model.bioRevealed(_sara), isFalse);
      expect(model.canChooseBioContinue(_sara), isFalse);
      expect(model.canPeerChooseBioContinue(_sara), isFalse);
      expect(model.chooseBioContinue(_sara), isFalse);
      expect(model.completeBioStep(_sara), isFalse);
      expect(model.chooseBioReveal(_sara), isTrue);
      expect(model.chooseBioReveal(_sara), isFalse);
      expect(model.bioRevealed(_sara), isFalse);
      expect(model.chooseBioContinue(_sara), isFalse);
      expect(model.simulatePeerBioReveal(_sara), isTrue);
      expect(model.simulatePeerBioReveal(_sara), isFalse);
      expect(model.bioRevealed(_sara), isTrue);
      // Mutual disclosure is available inside the substep; the menu reader is
      // still locked until the separate completion decisions are finished.
      expect(model.canViewJourneyBio(_sara), isFalse);
      expect(model.canChooseBioContinue(_sara), isTrue);
      expect(model.canPeerChooseBioContinue(_sara), isTrue);
      expect(model.chooseBioContinue(_sara), isTrue);
      expect(model.hasChosenBioContinue(_sara), isTrue);
      expect(model.peerHasChosenBioContinue(_sara), isFalse);
      expect(model.chooseBioContinue(_sara), isFalse);
      expect(model.completeBioStep(_sara), isFalse);
      expect(model.simulatePeerBioContinue(_sara), isTrue);
      expect(model.simulatePeerBioContinue(_sara), isFalse);
      expect(model.canCompleteBioStep(_sara), isTrue);
      expect(model.completeBioStep(_sara), isTrue);
      expect(model.stageFor(_sara)?.value, 'wali_gate');
      expect(model.isBioStepOpen(_sara), isFalse);
      expect(model.canViewJourneyBio(_sara), isTrue);
      expect(model.canViewJourneyCompatibility(_sara), isTrue);
      expect(model.hasChosenStageContinue(_sara), isFalse);
      expect(model.peerHasChosenStageContinue(_sara), isFalse);
      expect(model.completeBioStep(_sara), isFalse);
      expect(model.beginBioStep(_sara), isFalse);
    },
  );

  test('peer-first Bio consent remains distinct from own consent', () {
    final model = _active();
    _openBio(model);
    expect(model.simulatePeerBioReveal(_sara), isTrue);
    expect(model.hasChosenBioReveal(_sara), isFalse);
    expect(model.peerHasChosenBioReveal(_sara), isTrue);
    expect(model.bioRevealed(_sara), isFalse);
    expect(model.simulatePeerBioContinue(_sara), isFalse);
    expect(model.chooseBioReveal(_sara), isTrue);
    expect(model.bioRevealed(_sara), isTrue);
  });

  test(
    'an opened Bio substep cannot be bypassed by canonical advanceStage',
    () {
      final model = _active();
      _openBio(model);
      final opened = model.snapshot();
      expect(model.canAdvanceStage(_sara), isFalse);
      expect(model.advanceStage(_sara), isFalse);
      expect(model.beginBioStep(_sara), isFalse);
      expect(model.snapshot().progress, opened.progress);
      _readyBio(model);
      expect(model.canCompleteBioStep(_sara), isTrue);
      expect(model.canAdvanceStage(_sara), isFalse);
      expect(model.advanceStage(_sara), isFalse);
      expect(model.stageFor(_sara)?.value, 'compatibility_reveal');
      expect(model.completeBioStep(_sara), isTrue);
      expect(model.stageFor(_sara)?.value, 'wali_gate');
    },
  );

  for (final restriction in [
    'blocked',
    'pause requested',
    'paused',
    'ended',
    'own Main',
    'peer Main',
  ]) {
    for (final completed in [false, true]) {
      test(
        '$restriction prevents ${completed ? 'completed' : 'open'} Bio disclosure and writes',
        () {
          final model = _active();
          _openBio(model);
          _readyBio(model);
          if (completed) expect(model.completeBioStep(_sara), isTrue);
          switch (restriction) {
            case 'blocked':
              expect(model.block(_sara), isTrue);
            case 'pause requested':
              expect(model.requestPause(_sara), isTrue);
            case 'paused':
              expect(model.requestPause(_sara), isTrue);
              expect(model.agreePause(_sara), isTrue);
            case 'ended':
              expect(model.end(_sara), isTrue);
            case 'own Main':
              model.setOwnMainGuardianPresent(false);
            case 'peer Main':
              expect(
                model.setPeerMainGuardianPresent(false, id: _sara),
                isTrue,
              );
          }
          final before = model.snapshot();
          expect(model.hasCompletedCompatibilityStep(_sara), isTrue);
          expect(model.bioRevealed(_sara), isTrue);
          _expectNoDisclosure(model, _sara);
          expect(model.chooseBioReveal(_sara), isFalse);
          expect(model.simulatePeerBioReveal(_sara), isFalse);
          expect(model.chooseBioContinue(_sara), isFalse);
          expect(model.simulatePeerBioContinue(_sara), isFalse);
          expect(model.completeBioStep(_sara), isFalse);
          expect(model.advanceStage(_sara), isFalse);
          expect(model.snapshot().progress, before.progress);
          final restored = ViewRequestDraftModel.fromSnapshot(before);
          _expectNoDisclosure(restored, _sara);
          expect(restored.snapshot().progress, before.progress);
        },
      );
    }
  }

  test(
    'restoring Main leadership preserves choices without silently completing Bio',
    () {
      final model = _active();
      _openBio(model);
      _readyBio(model);
      model.setOwnMainGuardianPresent(false);
      expect(model.completeBioStep(_sara), isFalse);
      model.setOwnMainGuardianPresent(true);
      expect(model.canViewJourneyBio(_sara), isFalse);
      expect(model.canCompleteBioStep(_sara), isTrue);
      expect(model.completeBioStep(_sara), isTrue);
      expect(model.canViewJourneyBio(_sara), isTrue);
    },
  );

  test(
    'separate Journey profiles never inherit reveal or completion flags',
    () {
      final model = _active();
      _openBio(model);
      _reachCompatibility(model, _aisha);
      _completeCompatibility(model, _aisha);
      expect(model.advanceStage(_aisha), isTrue);
      _readyBio(model);
      expect(model.completeBioStep(_sara), isTrue);
      expect(model.canViewJourneyBio(_sara), isTrue);
      expect(model.canViewJourneyCompatibility(_aisha), isTrue);
      expect(model.canViewJourneyBio(_aisha), isFalse);
      expect(model.hasChosenBioReveal(_aisha), isFalse);
      expect(model.peerHasChosenBioReveal(_aisha), isFalse);
      expect(model.isBioStepOpen(_aisha), isFalse);
      expect(model.setPeerMainGuardianPresent(false, id: _sara), isTrue);
      _expectNoDisclosure(model, _sara);
      expect(model.canViewJourneyCompatibility(_aisha), isTrue);
    },
  );

  test(
    'all Bio substates round-trip as detached immutable scalar progress',
    () {
      final model = _active();
      _openBio(model);
      final steps = <void Function()>[
        () {},
        () => expect(model.chooseBioReveal(_sara), isTrue),
        () => expect(model.simulatePeerBioReveal(_sara), isTrue),
        () => expect(model.chooseBioContinue(_sara), isTrue),
        () => expect(model.simulatePeerBioContinue(_sara), isTrue),
        () => expect(model.completeBioStep(_sara), isTrue),
      ];
      for (final step in steps) {
        step();
        final saved = model.snapshot();
        final restored = ViewRequestDraftModel.fromSnapshot(saved);
        expect(restored.snapshot().progress, saved.progress);
        expect(restored.isBioStepOpen(_sara), model.isBioStepOpen(_sara));
        expect(restored.bioRevealed(_sara), model.bioRevealed(_sara));
        expect(
          restored.canViewJourneyBio(_sara),
          model.canViewJourneyBio(_sara),
        );
        expect(
          restored.canCompleteBioStep(_sara),
          model.canCompleteBioStep(_sara),
        );
        expect(() => saved.progress.clear(), throwsUnsupportedError);
        restored.end(_sara);
        expect(model.stateFor(_sara), DraftJourneyState.active);
        expect(saved.states[_sara], DraftJourneyState.active);
      }
    },
  );

  test('mutating a restored Bio choice never changes its source snapshot', () {
    final model = _active();
    _openBio(model);
    expect(model.chooseBioReveal(_sara), isTrue);
    final saved = model.snapshot();
    final restored = ViewRequestDraftModel.fromSnapshot(saved);
    expect(restored.simulatePeerBioReveal(_sara), isTrue);
    expect(restored.bioRevealed(_sara), isTrue);
    expect(model.bioRevealed(_sara), isFalse);
    expect(saved.progress[_sara]!.peerBioConsent, isFalse);
    model.reset();
    expect(saved.progress[_sara]!.bioStepOpen, isTrue);
    expect(saved.progress[_sara]!.bioConsent, isTrue);
    expect(restored.isBioStepOpen(_sara), isTrue);
    expect(restored.bioRevealed(_sara), isTrue);
  });

  test('reset and fresh scenario seeding clear every Bio grant', () {
    final model = _active();
    _openBio(model);
    _readyBio(model);
    expect(model.completeBioStep(_sara), isTrue);
    model.reset();
    _expectNoDisclosure(model, _sara);
    expect(model.hasCompletedCompatibilityStep(_sara), isFalse);
    expect(model.isBioStepOpen(_sara), isFalse);
    expect(model.bioRevealed(_sara), isFalse);
    expect(model.seedJourneys(3), isTrue);
    expect(model.stageFor(_sara)?.value, 'salam_exchange');
    expect(model.hasChosenBioReveal(_sara), isFalse);
    expect(model.peerHasChosenBioReveal(_sara), isFalse);
    expect(model.hasChosenBioContinue(_sara), isFalse);
    expect(model.peerHasChosenBioContinue(_sara), isFalse);
    _expectNoDisclosure(model, _sara);
  });
}
