// Pure fictional state only: no UI, provider, private answers or real wallet.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _presets = [0, 1, 5];
const _invalidCounts = [-1, 2, 3, 4, 6, 1000000];

List<Object> _snapshot(ZyraDraftCompatibilityPreview preview) => [
  preview.profileId,
  preview.balance,
  preview.revealed,
  preview.overallScore,
];

void main() {
  test(
    'every exact named draft fixture starts locked with one local credit',
    () {
      for (final person in draftProfiles) {
        final preview = ZyraDraftCompatibilityPreview(person.id);
        expect(preview.profileId, person.id);
        expect(preview.balance, 1);
        expect(preview.revealed, isFalse);
        expect(preview.overallScore, inInclusiveRange(68, 90));
      }
    },
  );

  test('UUIDs, unknown IDs, Guardian IDs and near-matches are refused', () {
    for (final id in [
      '',
      'unknown',
      'draft-missing',
      'draft-guardian-hassan',
      'dev_demo_sara',
      'sample-sara',
      'DRAFT-SARA',
      'draft-sara ',
      ' draft-sara',
      'draft-sara\n',
      'draft-sara/anything',
      '00000000-0000-4000-8000-000000000001',
    ]) {
      expect(
        () => ZyraDraftCompatibilityPreview(id),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'profileId',
          ),
        ),
        reason: 'A draft-looking prefix alone is not fixture authority: $id',
      );
    }
  });

  test('all exact initial 0/1/5 counts start locked', () {
    for (final count in _presets) {
      final preview = ZyraDraftCompatibilityPreview(_sara, balance: count);
      expect(preview.balance, count);
      expect(preview.revealed, isFalse);
    }
  });

  test('invalid initial balances are rejected', () {
    for (final count in _invalidCounts) {
      expect(
        () => ZyraDraftCompatibilityPreview(_sara, balance: count),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'balance'),
        ),
      );
    }
  });

  test('presets assign exactly, never increment or disclose', () {
    final preview = ZyraDraftCompatibilityPreview(_sara, balance: 5);
    for (final count in _presets) {
      expect(preview.setBalance(count: count), isTrue);
      expect(preview.balance, count);
      expect(preview.revealed, isFalse);
      final once = _snapshot(preview);
      expect(preview.setBalance(count: count), isTrue);
      expect(_snapshot(preview), once);
    }
  });

  test('invalid assignments cannot change stock or an existing result', () {
    for (final revealed in [false, true]) {
      final preview = ZyraDraftCompatibilityPreview(_sara, balance: 5);
      if (revealed) expect(preview.unlock(), isTrue);
      final before = _snapshot(preview);
      for (final count in _invalidCounts) {
        expect(preview.setBalance(count: count), isFalse);
        expect(_snapshot(preview), before);
      }
    }
  });

  test('Overall remains a stable fictional display, never answer scoring', () {
    expect(ZyraDraftCompatibilityPreview(_sara).overallScore, 76);
    for (final person in draftProfiles) {
      final first = ZyraDraftCompatibilityPreview(person.id);
      final second = ZyraDraftCompatibilityPreview(person.id);
      final fixtureValue =
          68 + person.id.codeUnits.fold<int>(0, (sum, unit) => sum + unit) % 23;
      expect(first.overallScore, fixtureValue);
      expect(second.overallScore, fixtureValue);
      expect(first.unlock(), isTrue);
      expect(first.overallScore, fixtureValue);
      expect(second.revealed, isFalse);
    }
  });

  for (final count in [1, 5]) {
    test('one complete reveal spends one of $count credits only once', () {
      final preview = ZyraDraftCompatibilityPreview(_sara, balance: count);
      expect(preview.unlock(), isTrue);
      expect(preview.balance, count - 1);
      expect(preview.revealed, isTrue);
      final once = _snapshot(preview);
      expect(preview.unlock(), isFalse);
      expect(preview.unlock(), isFalse);
      expect(_snapshot(preview), once);
      expect(preview.setBalance(count: 5), isTrue);
      expect(preview.unlock(), isFalse);
      expect(preview.balance, 5);
      expect(preview.revealed, isTrue);
    });
  }

  test('zero stays locked until an explicit valid local assignment', () {
    final preview = ZyraDraftCompatibilityPreview(_sara, balance: 0);
    final before = _snapshot(preview);
    expect(preview.unlock(), isFalse);
    expect(preview.unlock(), isFalse);
    expect(_snapshot(preview), before);
    expect(preview.setBalance(count: 1), isTrue);
    expect(preview.revealed, isFalse);
    expect(preview.unlock(), isTrue);
    expect(preview.balance, 0);
    expect(preview.revealed, isTrue);
  });

  test('reopening is an independent one-credit locked instance', () {
    final old = ZyraDraftCompatibilityPreview(_sara, balance: 5);
    expect(old.unlock(), isTrue);
    final oldState = _snapshot(old);
    final reopened = ZyraDraftCompatibilityPreview(_sara);
    expect(reopened.profileId, old.profileId);
    expect(reopened.balance, 1);
    expect(reopened.revealed, isFalse);
    expect(reopened.overallScore, old.overallScore);
    expect(reopened.setBalance(count: 0), isTrue);
    expect(_snapshot(old), oldState);
  });

  test('separate peer and same-peer instances never share local stock', () {
    final sara = ZyraDraftCompatibilityPreview(_sara);
    final aisha = ZyraDraftCompatibilityPreview(_aisha);
    final anotherSara = ZyraDraftCompatibilityPreview(_sara);
    final aishaBefore = _snapshot(aisha);
    final saraBefore = _snapshot(anotherSara);
    expect(sara.unlock(), isTrue);
    expect(sara.setBalance(count: 5), isTrue);
    expect(_snapshot(aisha), aishaBefore);
    expect(_snapshot(anotherSara), saraBefore);
  });

  test('the preview cannot alter Journey state, consent or capacity', () {
    final journey = ViewRequestDraftModel(capacity: 3);
    expect(journey.request(_sara), isTrue);
    final states = Map<String, DraftJourneyState>.of(journey.states);
    final preview = ZyraDraftCompatibilityPreview(_sara);
    expect(preview.unlock(), isTrue);
    expect(journey.states, states);
    expect(journey.capacity, 3);
    expect(journey.occupiedCount, 0);
    expect(journey.hasChosenCompatibilityReveal(_sara), isFalse);
    expect(journey.peerHasChosenCompatibilityReveal(_sara), isFalse);
    expect(journey.compatibilityRevealed(_sara), isFalse);
  });

  test('the model imports only the pure fictional fixture source', () {
    final source = File(
      'lib/dev/zyra_draft_compatibility_preview.dart',
    ).readAsStringSync();
    final dependencies = source
        .split('\n')
        .map((line) => line.trim())
        .where(
          (line) =>
              line.startsWith('import ') ||
              line.startsWith('export ') ||
              line.startsWith('part '),
        )
        .toList();
    expect(dependencies, ["import 'zyra_view_request_draft_model.dart';"]);
  });
}
