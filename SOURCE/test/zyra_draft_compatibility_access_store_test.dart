// Pure local access only; no member ledger, services or private answers.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_draft_compatibility_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _invalidCounts = [-1, 2, 3, 4, 6, 1000000];
const _invalidPeople = [
  '',
  'unknown',
  'draft-missing',
  'draft-guardian-hassan',
  'draft-self',
  'dev_demo_sara',
  'sample-sara',
  'DRAFT-SARA',
  'draft-sara ',
  ' draft-sara',
  'draft-sara\n',
  'draft-sara/anything',
  '00000000-0000-4000-8000-000000000001',
];

void main() {
  test('unspent credits are not a used per-person grant', () {
    for (final count in [0, 1, 5]) {
      final store = ZyraDraftCompatibilityAccessStore(
        canAct: () => true,
        balance: count,
      );
      expect(store.current, isTrue);
      expect(store.balance, count);
      for (final person in draftProfiles) {
        expect(store.isUnlocked(person.id), isFalse);
        expect(store.resultFor(person.id), isNull);
      }
    }
  });

  test('invalid initial counts cannot create a store', () {
    for (final count in _invalidCounts) {
      expect(
        () => ZyraDraftCompatibilityAccessStore(
          canAct: () => true,
          balance: count,
        ),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'balance'),
        ),
      );
    }
  });

  test('only exact named people can use or read local access', () {
    final store = ZyraDraftCompatibilityAccessStore(
      canAct: () => true,
      balance: 5,
    );
    for (final id in _invalidPeople) {
      expect(store.unlock(id), isFalse);
      expect(store.isUnlocked(id), isFalse);
      expect(store.resultFor(id), isNull);
      expect(store.balance, 5);
    }
    expect(store.unlock(_sara), isTrue);
    expect(store.balance, 4);
  });

  test('used access survives repeated reads and never spends twice', () {
    final store = ZyraDraftCompatibilityAccessStore(canAct: () => true);
    expect(store.unlock(_sara), isTrue);
    final result = store.resultFor(_sara)!;
    expect(result.profileId, _sara);
    expect(result.overallScore, 76);
    expect(store.balance, 0);
    for (var visit = 0; visit < 5; visit++) {
      expect(store.isUnlocked(_sara), isTrue);
      expect(store.resultFor(_sara), same(result));
      expect(store.unlock(_sara), isFalse);
      expect(store.balance, 0);
    }
    expect(store.isUnlocked(_aisha), isFalse);
    expect(store.resultFor(_aisha), isNull);
    expect(store.unlock(_aisha), isFalse);
  });

  test('all people share one count but never another person\'s grant', () {
    final store = ZyraDraftCompatibilityAccessStore(
      canAct: () => true,
      balance: 5,
    );
    expect(store.unlock(_sara), isTrue);
    final sara = store.resultFor(_sara)!;
    expect(store.balance, 4);
    expect(store.isUnlocked(_aisha), isFalse);
    expect(store.unlock(_aisha), isTrue);
    expect(store.balance, 3);
    final aisha = store.resultFor(_aisha)!;
    expect(aisha.profileId, _aisha);
    expect(
      aisha.overallScore,
      ZyraDraftCompatibilityPreview(_aisha, balance: 0).overallScore,
    );
    expect(store.resultFor(_sara), same(sara));
    expect(store.unlock(_sara), isFalse);
    expect(store.balance, 3);
  });

  test('exact count assignment never erases or creates used access', () {
    final store = ZyraDraftCompatibilityAccessStore(canAct: () => true);
    expect(store.unlock(_sara), isTrue);
    final result = store.resultFor(_sara)!;
    for (final count in [0, 1, 5, 5]) {
      expect(store.setBalance(count: count), isTrue);
      expect(store.balance, count);
      expect(store.resultFor(_sara), same(result));
      expect(store.isUnlocked(_aisha), isFalse);
      expect(store.unlock(_sara), isFalse);
      expect(store.balance, count);
    }
    for (final count in _invalidCounts) {
      expect(store.setBalance(count: count), isFalse);
      expect(store.balance, 5);
      expect(store.resultFor(_sara), same(result));
    }
  });

  test('a different viewer lifetime has no inherited balance or grant', () {
    final first = ZyraDraftCompatibilityAccessStore(canAct: () => true);
    final second = ZyraDraftCompatibilityAccessStore(
      canAct: () => true,
      balance: 0,
    );
    expect(first.unlock(_sara), isTrue);
    expect(second.resultFor(_sara), isNull);
    expect(second.isUnlocked(_sara), isFalse);
    expect(second.unlock(_sara), isFalse);
    expect(second.balance, 0);
    expect(first.isUnlocked(_sara), isTrue);
  });

  test('denial is terminal even when the external guard later recovers', () {
    var allowed = true;
    final store = ZyraDraftCompatibilityAccessStore(
      canAct: () => allowed,
      balance: 5,
    );
    expect(store.unlock(_sara), isTrue);
    allowed = false;
    expect(store.resultFor(_sara), isNull);
    expect(store.current, isFalse);
    allowed = true;
    expect(store.current, isFalse);
    expect(store.balance, 0);
    expect(store.resultFor(_sara), isNull);
    expect(store.unlock(_aisha), isFalse);
    expect(store.setBalance(count: 5), isFalse);
    expect(store.reset(), isFalse);
  });

  test('guard exceptions deny and cannot revive an old result', () {
    var failing = false;
    final store = ZyraDraftCompatibilityAccessStore(
      canAct: () {
        if (failing) throw StateError('Synthetic denied owner');
        return true;
      },
    );
    expect(store.unlock(_sara), isTrue);
    failing = true;
    expect(store.balance, 0);
    failing = false;
    expect(store.resultFor(_sara), isNull);
    expect(store.unlock(_sara), isFalse);
  });

  test('explicit reset clears grants while malformed reset is inert', () {
    final store = ZyraDraftCompatibilityAccessStore(canAct: () => true);
    expect(store.unlock(_sara), isTrue);
    final result = store.resultFor(_sara)!;
    for (final count in _invalidCounts) {
      expect(store.reset(balance: count), isFalse);
      expect(store.balance, 0);
      expect(store.resultFor(_sara), same(result));
    }
    expect(store.reset(balance: 5), isTrue);
    expect(store.balance, 5);
    expect(store.isUnlocked(_sara), isFalse);
    expect(store.unlock(_sara), isTrue);
    expect(store.resultFor(_sara), isNot(same(result)));
    expect(store.balance, 4);
    expect(store.reset(), isTrue);
    expect(store.balance, 1);
    expect(store.resultFor(_sara), isNull);
  });

  test('close is terminal and idempotent for all retained operations', () {
    final store = ZyraDraftCompatibilityAccessStore(canAct: () => true);
    expect(store.unlock(_sara), isTrue);
    store.close();
    store.close();
    expect(store.current, isFalse);
    expect(store.balance, 0);
    expect(store.resultFor(_sara), isNull);
    expect(store.unlock(_aisha), isFalse);
    expect(store.setBalance(count: 5), isFalse);
    expect(store.reset(), isFalse);
  });

  test('used access cannot alter relationship, consent or biography', () {
    final journey = ViewRequestDraftModel(capacity: 3)..seedJourneys(3);
    final before = journey.snapshot();
    final store = ZyraDraftCompatibilityAccessStore(canAct: () => true);
    expect(store.unlock(_sara), isTrue);
    expect(journey.snapshot().states, before.states);
    expect(journey.snapshot().progress, before.progress);
    expect(journey.capacity, 3);
    expect(journey.hasChosenCompatibilityReveal(_sara), isFalse);
    expect(journey.peerHasChosenCompatibilityReveal(_sara), isFalse);
    expect(journey.canViewJourneyCompatibility(_sara), isFalse);
    expect(journey.canViewJourneyBio(_sara), isFalse);
  });

  test('source has only fictional dependencies and no hydration authority', () {
    final source = File(
      'lib/dev/zyra_draft_compatibility_access_store.dart',
    ).readAsStringSync();
    final dependencies = source
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.startsWith('import '))
        .toList();
    expect(dependencies, [
      "import 'zyra_draft_compatibility_preview.dart';",
      "import 'zyra_view_request_draft_model.dart';",
    ]);
    for (final forbidden in [
      'fromSnapshot(',
      'fromJson(',
      'toJson(',
      'SharedPreferences',
      'ZyraAuth',
      'ZyraUnlockService',
      'supabase',
      '.rpc(',
    ]) {
      expect(source.contains(forbidden), isFalse, reason: forbidden);
    }
  });
}
