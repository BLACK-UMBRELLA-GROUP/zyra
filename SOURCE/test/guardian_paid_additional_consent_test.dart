import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

const _main = 'draft-guardian-hassan';
const _additional = 'draft-guardian-yusuf';
const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _agreement = {_additional};

void _prepare(ViewRequestDraftModel model, [String id = _sara]) {
  expect(model.request(id), isTrue);
  expect(model.simulateRecipientAccept(id), isTrue);
}

void _ready(ViewRequestDraftModel model, [String id = _sara]) {
  _prepare(model, id);
  expect(model.markReady(id), isTrue);
  expect(model.simulatePeerReady(id), isTrue);
}

void _begin(ViewRequestDraftModel model, [String id = _sara]) {
  _ready(model, id);
  expect(
    model.beginPreparedJourney(id, agreedPaidAdditionalGuardianIds: _agreement),
    isTrue,
  );
}

void _unchanged(ViewRequestDraftSnapshot before, ViewRequestDraftModel model) {
  final after = model.snapshot();
  expect(after.states, before.states);
  expect(after.progress, before.progress);
  expect(after.guardianAccess, before.guardianAccess);
  expect(after.requiredPaidGuardianAccess, before.requiredPaidGuardianAccess);
  expect(after.guardianMemberships, before.guardianMemberships);
}

void main() {
  test(
    'no agreement means no Begin, grant or readiness convenience mutation',
    () {
      final model = ViewRequestDraftModel();
      _prepare(model);
      final before = model.snapshot();
      expect(model.completePreparation(_sara), isFalse);
      _unchanged(before, model);
      expect(model.isReady(_sara), isFalse);
      expect(model.peerIsReady(_sara), isFalse);
      expect(model.sampleGuardianAccessFor(_additional, _sara), (
        view: false,
        chat: false,
      ));
      expect(
        model.sampleGuardianAccessFor(_main, _sara, isMain: true).view,
        isTrue,
      );
      expect(model.markReady(_sara), isTrue);
      expect(model.simulatePeerReady(_sara), isTrue);
      final ready = model.snapshot();
      expect(model.beginPreparedJourney(_sara), isFalse);
      _unchanged(ready, model);
    },
  );

  test(
    'exact agreement atomically begins only that pair with fixed access',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      _ready(model);
      _ready(model, _aisha);
      final callerAgreement = {_additional};
      expect(
        model.beginPreparedJourney(
          _sara,
          agreedPaidAdditionalGuardianIds: callerAgreement,
        ),
        isTrue,
      );
      callerAgreement.clear();
      expect(model.stateFor(_sara), DraftJourneyState.active);
      expect(model.hasRequiredPaidGuardianAccess(_additional, _sara), isTrue);
      expect(model.hasRequiredPaidGuardianAccess(_additional, _aisha), isFalse);
      expect(model.hasRequiredPaidGuardianAccess(_main, _sara), isFalse);
      expect(model.sampleGuardianAccessFor(_additional, _sara), (
        view: true,
        chat: true,
      ));
      final before = model.snapshot();
      for (final change in [
        (view: false, chat: null),
        (view: null, chat: false),
        (view: true, chat: true),
      ]) {
        expect(
          model.setSampleGuardianJourneyAccess(
            _additional,
            _sara,
            viewEnabled: change.view,
            chatEnabled: change.chat,
          ),
          isFalse,
        );
        _unchanged(before, model);
      }
    },
  );

  test(
    'unknown, extra, Main, missing-link and stale-plan consent fail closed',
    () {
      final model = ViewRequestDraftModel();
      _ready(model);
      final before = model.snapshot();
      for (final consent in [
        <String>{},
        {_main},
        {_main, _additional},
        {'unknown'},
      ]) {
        expect(
          model.beginPreparedJourney(
            _sara,
            agreedPaidAdditionalGuardianIds: consent,
          ),
          isFalse,
        );
        _unchanged(before, model);
      }
      for (final linked in [
        {_additional},
        {_main, 'unknown'},
      ]) {
        expect(
          model.beginPreparedJourney(
            _sara,
            linkedGuardianIds: linked,
            agreedPaidAdditionalGuardianIds: _agreement,
          ),
          isFalse,
        );
        _unchanged(before, model);
      }
      for (final main in [null, 'unknown', _additional]) {
        expect(
          model.beginPreparedJourney(
            _sara,
            mainGuardianId: main,
            agreedPaidAdditionalGuardianIds: _agreement,
          ),
          isFalse,
        );
        _unchanged(before, model);
      }
      model.setSampleGuardianMembership(
        _additional,
        DraftGuardianMembership.basic,
      );
      final downgraded = model.snapshot();
      expect(
        model.beginPreparedJourney(
          _sara,
          agreedPaidAdditionalGuardianIds: _agreement,
        ),
        isFalse,
      );
      _unchanged(downgraded, model);
      expect(model.beginPreparedJourney(_sara), isTrue);
      expect(model.hasRequiredPaidGuardianAccess(_additional, _sara), isFalse);
      expect(model.sampleGuardianAccessFor(_additional, _sara).chat, isFalse);
      expect(
        model.setSampleGuardianJourneyAccess(
          _additional,
          _sara,
          viewEnabled: true,
        ),
        isTrue,
      );
      expect(
        model.setSampleGuardianJourneyAccess(
          _additional,
          _sara,
          chatEnabled: true,
        ),
        isFalse,
      );
    },
  );

  test(
    'current role rather than fixture Main label defines agreed Additional',
    () {
      final model = ViewRequestDraftModel();
      _ready(model);
      expect(
        model.beginPreparedJourney(
          _sara,
          mainGuardianId: _additional,
          agreedPaidAdditionalGuardianIds: {_main},
        ),
        isTrue,
      );
      expect(model.hasRequiredPaidGuardianAccess(_main, _sara), isTrue);
      expect(model.hasRequiredPaidGuardianAccess(_additional, _sara), isFalse);
    },
  );

  test(
    'missing Main and upgrade after a Basic preparation require a fresh decision',
    () {
      final model = ViewRequestDraftModel();
      model.setSampleGuardianMembership(
        _additional,
        DraftGuardianMembership.basic,
      );
      _ready(model);
      model.setSampleGuardianMembership(
        _additional,
        DraftGuardianMembership.one,
      );
      final before = model.snapshot();
      expect(model.beginPreparedJourney(_sara), isFalse);
      _unchanged(before, model);
      model.setOwnMainGuardianPresent(false);
      final noMain = model.snapshot();
      expect(
        model.beginPreparedJourney(
          _sara,
          agreedPaidAdditionalGuardianIds: _agreement,
        ),
        isFalse,
      );
      _unchanged(noMain, model);
      model.setOwnMainGuardianPresent(true);
      expect(
        model.beginPreparedJourney(
          _sara,
          agreedPaidAdditionalGuardianIds: _agreement,
        ),
        isTrue,
      );
    },
  );

  test(
    'linked Main alone needs no Additional agreement; Basic Main remains View',
    () {
      final model = ViewRequestDraftModel();
      model.setSampleGuardianMembership(_main, DraftGuardianMembership.basic);
      _ready(model);
      expect(
        model.beginPreparedJourney(_sara, linkedGuardianIds: {_main}),
        isTrue,
      );
      expect(model.sampleGuardianAccessFor(_main, _sara, isMain: true), (
        view: true,
        chat: false,
      ));
      expect(model.sampleGuardianAccessFor(_additional, _sara), (
        view: false,
        chat: false,
      ));
    },
  );

  test(
    'legacy seeded grants stay optional and upgrade never shares old chat',
    () {
      final model = ViewRequestDraftModel()..fillCapacity();
      expect(model.hasRequiredPaidGuardianAccess(_additional, _sara), isFalse);
      expect(
        model.setSampleGuardianJourneyAccess(
          _additional,
          _sara,
          viewEnabled: false,
        ),
        isTrue,
      );
      model.setSampleGuardianMembership(
        _additional,
        DraftGuardianMembership.basic,
      );
      model.setSampleGuardianMembership(
        _additional,
        DraftGuardianMembership.one,
      );
      expect(model.sampleGuardianAccessFor(_additional, _sara), (
        view: false,
        chat: false,
      ));
      expect(model.hasRequiredPaidGuardianAccess(_additional, _sara), isFalse);
    },
  );

  test('downgrade and unlink withdraw stored Chat and agreement evidence', () {
    final model = ViewRequestDraftModel(capacity: 3);
    _begin(model);
    model.setSampleGuardianMembership(
      _additional,
      DraftGuardianMembership.basic,
    );
    expect(model.snapshot().requiredPaidGuardianAccess, isEmpty);
    expect(model.sampleGuardianAccessFor(_additional, _sara).chat, isFalse);
    model.setSampleGuardianMembership(_additional, DraftGuardianMembership.one);
    expect(model.sampleGuardianAccessFor(_additional, _sara).chat, isFalse);
    expect(model.hasRequiredPaidGuardianAccess(_additional, _sara), isFalse);
    _begin(model, _aisha);
    expect(model.hasRequiredPaidGuardianAccess(_additional, _aisha), isTrue);
    expect(model.revokeSampleGuardianAccess(_additional), isTrue);
    expect(model.snapshot().requiredPaidGuardianAccess, isEmpty);
    expect(model.sampleGuardianAccessFor(_additional, _aisha), (
      view: false,
      chat: false,
    ));
    expect(model.revokeSampleGuardianAccess('unknown'), isFalse);
  });

  test(
    'end, blocked eligibility, replacement and reset never leak required pairs',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      _begin(model);
      _begin(model, _aisha);
      expect(model.block(_aisha), isTrue);
      expect(model.hasRequiredPaidGuardianAccess(_additional, _aisha), isFalse);
      expect(model.end(_aisha), isTrue);
      expect(model.snapshot().requiredPaidGuardianAccess, {
        '$_additional|$_sara',
      });
      _begin(model, 'draft-maryam');
      _begin(model, 'draft-hana');
      final oldProgress = model.snapshot().progress[_sara];
      expect(
        model.replaceJourneyForRequest('draft-amira', _sara, incoming: true),
        isTrue,
      );
      expect(model.hasRequiredPaidGuardianAccess(_additional, _sara), isFalse);
      expect(
        model.hasRequiredPaidGuardianAccess(_additional, 'draft-amira'),
        isFalse,
      );
      expect(model.snapshot().progress[_sara], oldProgress);
      expect(model.sampleGuardianAccessFor(_additional, 'draft-amira'), (
        view: false,
        chat: false,
      ));
      model.reset();
      expect(model.snapshot().requiredPaidGuardianAccess, isEmpty);
    },
  );

  test(
    'required evidence is detached, immutable, restored and eligibility-checked',
    () {
      final model = ViewRequestDraftModel();
      _begin(model);
      final snapshot = model.snapshot();
      expect(snapshot.requiredPaidGuardianAccess, {'$_additional|$_sara'});
      expect(
        () => snapshot.requiredPaidGuardianAccess.clear(),
        throwsUnsupportedError,
      );
      final restored = ViewRequestDraftModel.fromSnapshot(snapshot);
      expect(
        restored.hasRequiredPaidGuardianAccess(_additional, _sara),
        isTrue,
      );
      expect(restored.hasRequiredPaidGuardianAccess('unknown', _sara), isFalse);
      expect(
        restored.hasRequiredPaidGuardianAccess(_additional, 'unknown'),
        isFalse,
      );
      expect(restored.end(_sara), isTrue);
      expect(
        restored.hasRequiredPaidGuardianAccess(_additional, _sara),
        isFalse,
      );
      expect(model.hasRequiredPaidGuardianAccess(_additional, _sara), isTrue);
      expect(snapshot.requiredPaidGuardianAccess, {'$_additional|$_sara'});
    },
  );

  test(
    'server rows cannot assert undeployed paid-agreement presentation proof',
    () {
      final row = GuardianJourneyAccessState.fromRow({
        'attempt_id': 'attempt',
        'match_id': 'match',
        'counterpart_first_name': 'Sara',
        'included': true,
        'can_change': false,
        'guardian_is_main': false,
        'chat_available': true,
        'chat_enabled': true,
        'guardian_chat_entitled': true,
        'required_by_paid_agreement': true,
      });
      expect(row, isNotNull);
      expect(row!.requiredByPaidAgreement, isFalse);
    },
  );
}
