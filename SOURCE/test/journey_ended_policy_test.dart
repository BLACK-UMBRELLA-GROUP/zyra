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
  group('paid New Journey return eligibility', () {
    test('remains open after the cooling period', () {
      final journey = _ended(const Duration(days: 30));

      expect(journey.isWithinNewJourneyRequestWindow, isTrue);
      expect(journey.canRestart, isTrue);
    });

    test('has no age expiry when the Journey remains in the latest five', () {
      final journey = _ended(const Duration(days: 61));

      expect(journey.isWithinNewJourneyRequestWindow, isTrue);
      expect(journey.canRestart, isTrue);
      expect(journey.restartAvailableIn, 'you can ask again');
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

  test('Ended Connections display caps are Basic 0 and ZYRA One 10', () {
    expect(ZyraEntitlements.basic.ended, 0);
    expect(ZyraEntitlements.one.ended, 10);
  });

  test('return initiation windows are paid and limited to five', () {
    expect(ZyraEntitlements.basic.pausedReturnWindow, 0);
    expect(ZyraEntitlements.basic.endedReturnWindow, 0);
    expect(ZyraEntitlements.one.pausedReturnWindow, 5);
    expect(ZyraEntitlements.one.endedReturnWindow, 5);
  });
}
