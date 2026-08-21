import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_entitlements.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';

const _profile = SeekerProfile(
  id: 'other',
  firstName: 'Arif',
  age: 31,
  city: 'London',
  photos: ['https://example.invalid/arif.jpg'],
  gender: 'male',
);

JourneyMatch _ended(Duration ago) => JourneyMatch(
  matchId: 'match',
  profile: _profile,
  status: 'ended',
  endedAt: DateTime.now().subtract(ago),
);

void main() {
  group('60-day New Journey request window', () {
    test('remains open after the cooling period and before day 60', () {
      final journey = _ended(const Duration(days: 30));

      expect(journey.isWithinNewJourneyRequestWindow, isTrue);
      expect(journey.canRestart, isTrue);
    });

    test('does not offer a direct request after day 60', () {
      final journey = _ended(const Duration(days: 61));

      expect(journey.isWithinNewJourneyRequestWindow, isFalse);
      expect(journey.canRestart, isFalse);
      expect(journey.restartAvailableIn, 'the 60-day request window has ended');
    });

    test('keeps the existing 24-hour cooling period', () {
      final journey = _ended(const Duration(hours: 12));

      expect(journey.isWithinNewJourneyRequestWindow, isTrue);
      expect(journey.isInCoolingPeriod, isTrue);
      expect(journey.canRestart, isFalse);
    });

    test('never applies the request window to a live Journey', () {
      final journey = JourneyMatch(
        matchId: 'active-match',
        profile: _profile,
        status: 'active',
        endedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      expect(journey.isWithinNewJourneyRequestWindow, isFalse);
      expect(journey.canRestart, isFalse);
    });
  });

  test('Ended Connections display caps are Basic 1 and ZYRA One 5', () {
    expect(ZyraEntitlements.basic.ended, 1);
    expect(ZyraEntitlements.one.ended, 5);
  });
}
