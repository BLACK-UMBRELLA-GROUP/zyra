import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _received = 'draft-amira';
const _target = 'draft-sara';
const _other = 'draft-aisha';
const _paid = 'draft-guardian-yusuf';

typedef _SafetyIntent = ({int? attempt, int safety, bool end});

_SafetyIntent _capture(ViewRequestDraftModel model, String id) => (
  attempt: model.attemptRevisionFor(id),
  safety: model.personSafetyRevision,
  end:
      model.stateFor(id) == DraftJourneyState.preparing ||
      model.stateFor(id) == DraftJourneyState.active,
);

bool _apply(
  ViewRequestDraftModel model,
  String id,
  _SafetyIntent intent, {
  required bool hide,
}) => model.applyPersonSafety(
  id,
  hide: hide,
  expectedAttemptRevision: intent.attempt,
  expectedSafetyRevision: intent.safety,
  endCurrentJourney: intent.end,
);

Map<String, Object?> _values(ViewRequestDraftModel model) {
  final value = model.snapshot();
  return {
    'capacity': value.capacity,
    'states': value.states,
    'busy': value.busyPeers,
    'hidden': value.hiddenPeers,
    'blocked': value.blockedPeers,
    'attempts': value.attemptRevisions,
    'attemptSequence': value.attemptSequence,
    'waiting': value.waitingAcceptances,
    'waitingSequence': value.acceptanceIntentSequence,
    'requested': value.pendingRequestedAt,
    'progress': value.progress,
    'started': value.journeyStartedAt,
    'activity': value.journeyLastActivityAt,
    'ended': value.endedAttempts,
    'endedIds': value.currentEndedAttemptIds,
    'past': value.pastRequests,
    'accepted': value.outgoingRequestAcceptedAt,
    'acceptedRevision': value.outgoingRequestAcceptedRevisions,
    'acceptedSequence': value.outgoingAcceptedActivityRevision,
    'guardian': value.guardianAccess,
    'paid': value.requiredPaidGuardianAccess,
    'safetyRevision': model.personSafetyRevision,
  };
}

void _prepare(ViewRequestDraftModel model, String id) {
  expect(model.request(id), isTrue);
  expect(model.simulateRecipientAccept(id), isTrue);
}

void _start(ViewRequestDraftModel model, String id) {
  _prepare(model, id);
  expect(
    model.completePreparation(id, agreedPaidAdditionalGuardianIds: {_paid}),
    isTrue,
  );
}

void main() {
  for (final hide in [false, true]) {
    final action = hide ? 'hide' : 'block';

    for (final capacity in [1, 3]) {
      for (final active in [false, true]) {
        test('$action ends exact ${active ? 'active' : 'preparing'} '
            'attempt at capacity $capacity and retains Timeline', () {
          final now = DateTime.utc(2026, 10, 31, 16);
          final model = ViewRequestDraftModel(
            capacity: capacity,
            clock: () => now,
          );
          if (active) {
            _start(model, _target);
            expect(model.sendSalam(_target), isTrue);
          } else {
            _prepare(model, _target);
            expect(model.markReady(_target), isTrue);
          }
          if (capacity == 3) _start(model, _other);
          final before = model.snapshot();
          final occupied = model.occupiedCount;
          final intent = _capture(model, _target);

          expect(_apply(model, _target, intent, hide: hide), isTrue);
          expect(model.stateFor(_target), DraftJourneyState.ended);
          expect(model.occupiedCount, occupied - 1);
          expect(model.isHidden(_target), hide);
          expect(model.isBlocked(_target), !hide);
          expect(model.currentEndedAttemptFor(_target)?.endedAt, now);
          expect(
            model.currentEndedAttemptFor(_target)?.progress,
            before.progress[_target],
          );
          expect(model.snapshot().progress, before.progress);
          expect(model.snapshot().states[_other], before.states[_other]);
          expect(model.snapshot().endedAttempts.length, 1);
          expect(
            model.snapshot().requiredPaidGuardianAccess,
            isNot(contains('$_paid|$_target')),
          );
          if (capacity == 3) {
            expect(
              model.snapshot().requiredPaidGuardianAccess,
              contains('$_paid|$_other'),
            );
          }
          final after = _values(model);
          expect(_apply(model, _target, intent, hide: hide), isFalse);
          expect(_values(model), after);
        });
      }
    }

    for (final state in ['absent', 'received', 'sent', 'ended']) {
      test(
        '$action without a Journey leaves $state relationship untouched',
        () {
          final model = ViewRequestDraftModel();
          final id = state == 'received' ? _received : _target;
          if (state == 'sent') expect(model.request(id), isTrue);
          if (state == 'ended') {
            _start(model, id);
            expect(model.end(id), isTrue);
          }
          final before = model.snapshot();
          expect(_apply(model, id, _capture(model, id), hide: hide), isTrue);
          final after = model.snapshot();
          expect(after.states, before.states);
          expect(after.progress, before.progress);
          expect(after.endedAttempts, before.endedAttempts);
          expect(after.guardianAccess, before.guardianAccess);
          expect(
            after.requiredPaidGuardianAccess,
            before.requiredPaidGuardianAccess,
          );
          expect(model.isHidden(id), hide);
          expect(model.isBlocked(id), !hide);
        },
      );
    }

    for (final held in [false, true]) {
      test('$action of accepted Waiting ${held ? 'with' : 'without'} held '
          'ending preserves every current Journey', () {
        final model = ViewRequestDraftModel(capacity: 3);
        expect(model.setPeerOccupied(_received, true), isTrue);
        if (held) {
          _start(model, _target);
          _start(model, _other);
          _start(model, 'draft-maryam');
          expect(
            model.replaceJourneyForRequest(_received, _target, incoming: true),
            isTrue,
          );
        } else {
          expect(model.acceptReceived(_received), isTrue);
        }
        final before = model.snapshot();
        expect(
          _apply(model, _received, _capture(model, _received), hide: hide),
          isTrue,
        );
        final after = model.snapshot();
        expect(after.states, before.states);
        expect(after.waitingAcceptances, before.waitingAcceptances);
        expect(after.progress, before.progress);
        expect(after.endedAttempts, before.endedAttempts);
        expect(after.guardianAccess, before.guardianAccess);
        expect(
          after.requiredPaidGuardianAccess,
          before.requiredPaidGuardianAccess,
        );
        expect(model.occupiedCount, held ? 3 : 0);
        expect(after.progress.containsKey(_received), isFalse);
        if (held) expect(model.stateFor(_target), DraftJourneyState.active);
      });
    }

    test(
      '$action rejects stale reset and replacement attempt with no mutation',
      () {
        final model = ViewRequestDraftModel();
        _start(model, _target);
        final old = _capture(model, _target);
        model.reset();
        _start(model, _target);
        final before = _values(model);
        expect(_apply(model, _target, old, hide: hide), isFalse);
        expect(_values(model), before);
        expect(model.stateFor(_target), DraftJourneyState.active);
      },
    );

    test('$action rejects absent-attempt reset ABA with no mutation', () {
      final model = ViewRequestDraftModel();
      final old = _capture(model, _target);
      model.reset();
      final before = _values(model);
      expect(_apply(model, _target, old, hide: hide), isFalse);
      expect(_values(model), before);
    });

    test('$action rejects occupancy changes before ending or flagging', () {
      final model = ViewRequestDraftModel();
      expect(model.request(_target), isTrue);
      final beforeAcceptance = _capture(model, _target);
      expect(model.simulateRecipientAccept(_target), isTrue);
      final before = _values(model);
      expect(_apply(model, _target, beforeAcceptance, hide: hide), isFalse);
      expect(_values(model), before);
      final beforeEnding = _capture(model, _target);
      expect(model.end(_target), isTrue);
      final ended = _values(model);
      expect(_apply(model, _target, beforeEnding, hide: hide), isFalse);
      expect(_values(model), ended);
    });

    test(
      '$action rejects wrong target attempt and unknown person atomically',
      () {
        final model = ViewRequestDraftModel(capacity: 3);
        _start(model, _target);
        _start(model, _other);
        final wrongTarget = _capture(model, _target);
        final before = _values(model);
        expect(_apply(model, _other, wrongTarget, hide: hide), isFalse);
        expect(
          _apply(model, 'unknown', _capture(model, 'unknown'), hide: hide),
          isFalse,
        );
        expect(_values(model), before);
      },
    );

    test('$action refuses a fresh duplicate as well as a replay', () {
      final model = ViewRequestDraftModel();
      expect(
        _apply(model, _target, _capture(model, _target), hide: hide),
        isTrue,
      );
      final before = _values(model);
      expect(
        _apply(model, _target, _capture(model, _target), hide: hide),
        isFalse,
      );
      expect(_values(model), before);
    });
  }

  test('unhide cannot revive an old hide confirmation', () {
    final model = ViewRequestDraftModel();
    final old = _capture(model, _target);
    expect(_apply(model, _target, old, hide: true), isTrue);
    expect(model.unhide(_target), isTrue);
    final before = _values(model);
    expect(_apply(model, _target, old, hide: true), isFalse);
    expect(_values(model), before);
  });

  test('already hidden current person can be ended and blocked explicitly', () {
    final model = ViewRequestDraftModel();
    _start(model, _target);
    expect(model.hide(_target), isTrue);
    expect(
      _apply(model, _target, _capture(model, _target), hide: false),
      isTrue,
    );
    expect(model.stateFor(_target), DraftJourneyState.ended);
    expect(model.isHidden(_target), isTrue);
    expect(model.isBlocked(_target), isTrue);
  });

  test('ordinary hide and block retain visibility-only public behavior', () {
    final model = ViewRequestDraftModel();
    _start(model, _target);
    final before = model.snapshot();
    expect(model.hide(_target), isTrue);
    expect(model.hide(_target), isTrue);
    expect(model.block(_target), isTrue);
    expect(model.block(_target), isTrue);
    expect(model.snapshot().states, before.states);
    expect(model.snapshot().progress, before.progress);
    expect(model.snapshot().endedAttempts, before.endedAttempts);
    expect(
      model.snapshot().requiredPaidGuardianAccess,
      before.requiredPaidGuardianAccess,
    );
  });
}
