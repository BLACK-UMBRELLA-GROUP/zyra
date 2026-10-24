// Decision model — ONE STATE PER PROFILE.
//
// Founder decision 2026-08-03: Saved, Considering and Declined are
// mutually exclusive. A profile sits in exactly one of them, or none. The
// most recent action wins.
//
// THIS FILE PREVIOUSLY ASSERTED THE OPPOSITE. On 2026-08-01 it tested a
// two-axis model where Saved was a bookmark that survived every decision,
// with cases named "Decline does not destroy a bookmark". Those tests
// passed and the model was coherent. It was reversed on sight:
//
//   "a user can't be both saved and considered, so there's an error there"
//
// The tests are inverted rather than deleted so the reversal is visible in
// history. A future reader finding `_expectExactlyOneState` and wondering
// why a bookmark cannot coexist with a decision has the answer here.
//
// What is unchanged from the original file, because it was right then and
// is right now:
//
//   - `.contains(p)` is reference equality (SeekerProfile has no
//     operator==), so a refetched profile is a different object with the
//     same id. Every method matches on id.
//   - Considering can only be replaced by another action, never silently
//     withdrawn — the other person may already have been told.
//
// Pure state assertions: no widgets, no network, no Supabase.

import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/state/app_state.dart';

const _usman = SeekerProfile(
  id: 'test-usman',
  firstName: 'Usman',
  age: 35,
  city: 'London',
  photos: ['https://example.invalid/1.jpg'],
  gender: 'male',
);

const _other = SeekerProfile(
  id: 'test-other',
  firstName: 'Tariq',
  age: 30,
  city: 'Leeds',
  photos: ['https://example.invalid/2.jpg'],
  gender: 'male',
);

AppState get _s => AppState.instance;

void _clear() {
  _s.declined.clear();
  _s.saved.clear();
  _s.outgoingLikes.clear();
}

bool _isDeclined(SeekerProfile p) => _s.declined.any((x) => x.id == p.id);
bool _isConsidering(SeekerProfile p) =>
    _s.outgoingLikes.any((x) => x.id == p.id);
bool _isSaved(SeekerProfile p) => _s.saved.any((x) => x.id == p.id);

/// The invariant the whole model rests on. Asserted after every transition
/// rather than only at the end, so a test tells you WHICH step broke it.
void _expectExactlyOneState(SeekerProfile p, {required String expected}) {
  final states = <String>[
    if (_isSaved(p)) 'saved',
    if (_isConsidering(p)) 'considering',
    if (_isDeclined(p)) 'declined',
  ];
  expect(
    states.length,
    lessThanOrEqualTo(1),
    reason: '${p.firstName} is in ${states.length} states at once: $states',
  );
  expect(states.isEmpty ? 'none' : states.first, expected);

  for (final list in [_s.declined, _s.outgoingLikes, _s.saved]) {
    final ids = list.map((x) => x.id).toList();
    expect(ids.length, ids.toSet().length, reason: 'duplicate entry: $ids');
  }
}

void main() {
  setUp(_clear);

  group('every transition leaves exactly one state', () {
    test('save then consider — the save is cleared', () {
      _s.save(_usman);
      _expectExactlyOneState(_usman, expected: 'saved');
      _s.like(_usman);
      _expectExactlyOneState(_usman, expected: 'considering');
    });

    test('consider then save — the consider is cleared', () {
      _s.like(_usman);
      _s.save(_usman);
      _expectExactlyOneState(_usman, expected: 'saved');
    });

    test('save then pass', () {
      _s.save(_usman);
      _s.decline(_usman);
      _expectExactlyOneState(_usman, expected: 'declined');
    });

    test('pass then save', () {
      _s.decline(_usman);
      _s.save(_usman);
      _expectExactlyOneState(_usman, expected: 'saved');
    });

    test('consider then pass', () {
      _s.like(_usman);
      _s.decline(_usman);
      _expectExactlyOneState(_usman, expected: 'declined');
    });

    test('pass then consider', () {
      _s.decline(_usman);
      _s.like(_usman);
      _expectExactlyOneState(_usman, expected: 'considering');
    });

    test('every ordering of all three ends in the last one applied', () {
      _s.save(_usman);
      _s.like(_usman);
      _s.decline(_usman);
      _expectExactlyOneState(_usman, expected: 'declined');

      _s.decline(_usman);
      _s.save(_usman);
      _s.like(_usman);
      _expectExactlyOneState(_usman, expected: 'considering');

      _s.like(_usman);
      _s.decline(_usman);
      _s.save(_usman);
      _expectExactlyOneState(_usman, expected: 'saved');
    });

    test('flip-flopping never accumulates', () {
      for (var i = 0; i < 5; i++) {
        _s.save(_usman);
        _s.like(_usman);
        _s.decline(_usman);
      }
      _expectExactlyOneState(_usman, expected: 'declined');
      expect(_s.saved, isEmpty);
      expect(_s.outgoingLikes, isEmpty);
      expect(_s.declined.length, 1);
    });

    test('a re-fetched profile is the same person, not a second entry', () {
      // SeekerProfile has no operator==, so `.contains(p)` compares
      // references. A refetch builds new objects with the same ids.
      const refetched = SeekerProfile(
        id: 'test-usman',
        firstName: 'Usman',
        age: 35,
        city: 'London',
        photos: ['https://example.invalid/1.jpg'],
        gender: 'male',
      );
      _s.save(_usman);
      _s.save(refetched);
      expect(_s.saved.length, 1, reason: 'same id, one entry');
      _s.like(refetched);
      _expectExactlyOneState(_usman, expected: 'considering');
      expect(_s.saved, isEmpty, reason: 'matched by id, not reference');
    });
  });

  group('unsave', () {
    test('leaves the profile in no state, so it becomes browsable again', () {
      _s.save(_usman);
      _s.unsave(_usman);
      _expectExactlyOneState(_usman, expected: 'none');
      expect(_s.decidedProfileIds.contains(_usman.id), isFalse);
    });
  });

  group('one profile never affects another', () {
    test('acting on Usman leaves Tariq alone', () {
      _s.save(_other);
      _s.like(_usman);
      _s.decline(_usman);
      _expectExactlyOneState(_usman, expected: 'declined');
      _expectExactlyOneState(_other, expected: 'saved');
    });
  });

  group('Reset Search clears Declined only', () {
    test('Considering and Saved are untouched', () {
      _s.decline(_usman);
      _s.like(_other);
      const third = SeekerProfile(
        id: 'test-third',
        firstName: 'Bilal',
        age: 28,
        city: 'Bradford',
        photos: ['https://example.invalid/3.jpg'],
        gender: 'male',
      );
      _s.save(third);

      _s.resetDeclined();

      expect(_s.declined, isEmpty);
      expect(
        _isConsidering(_other),
        isTrue,
        reason: 'already decided to Consider — no need to rediscover',
      );
      expect(_isSaved(third), isTrue, reason: 'deliberately kept');
    });
  });

  group('deck membership', () {
    test('every state removes a profile from Browse', () {
      // CHANGED 2026-08-03. Saved used to be EXCLUDED from this set — a
      // bookmark was not a decision, so saved profiles stayed browsable
      // and wore a badge. With one state per profile, saving is acting.
      _s.save(_usman);
      expect(_s.decidedProfileIds.contains(_usman.id), isTrue);

      _s.like(_usman);
      expect(_s.decidedProfileIds.contains(_usman.id), isTrue);

      _s.decline(_usman);
      expect(_s.decidedProfileIds.contains(_usman.id), isTrue);
    });

    test('Reset Search puts declined profiles back in the deck', () {
      _s.decline(_usman);
      expect(_s.decidedProfileIds.contains(_usman.id), isTrue);
      _s.resetDeclined();
      expect(_s.decidedProfileIds.contains(_usman.id), isFalse);
    });
  });
}
