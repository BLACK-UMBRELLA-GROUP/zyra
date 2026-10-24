import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_seeker_basic_policy.dart';
import 'package:zyra/services/zyra_seeker_basic_usage_store.dart';

void main() {
  test('Seeker Basic exposes the Founder-approved limits', () {
    expect(ZyraSeekerBasicPolicy.activeJourneyLimit, 1);
    expect(ZyraSeekerBasicPolicy.totalConsiderLimit, 25);
    expect(ZyraSeekerBasicPolicy.totalSaveLimit, 5);
    expect(ZyraSeekerBasicPolicy.dailyConsiderLimit, 5);
    expect(ZyraSeekerBasicPolicy.swipeLimit, 25);
    expect(ZyraSeekerBasicPolicy.swipeWindow, const Duration(hours: 4));
    expect(ZyraSeekerBasicPolicy.advertEverySwipes, 5);
  });

  test('advert cadence is every fifth swipe and cap begins at 25', () {
    for (var swipe = 1; swipe <= 25; swipe++) {
      expect(
        ZyraSeekerBasicPolicy.advertDue(swipe),
        swipe % 5 == 0,
        reason: 'swipe $swipe',
      );
    }
    expect(ZyraSeekerBasicPolicy.swipeLimitReached(24), isFalse);
    expect(ZyraSeekerBasicPolicy.swipeLimitReached(25), isTrue);
  });

  test('usage resets swipes after four hours and considers next day', () {
    final start = DateTime(2026, 9, 18, 9);
    final usage = ZyraSeekerBasicUsage(
      swipeWindowStartedAt: start,
      swipes: 25,
      considerDay: '2026-09-18',
      considersToday: 5,
    );

    final before = usage.normalized(start.add(const Duration(hours: 3)));
    expect(before.swipes, 25);
    expect(before.considersToday, 5);

    final after = usage.normalized(start.add(const Duration(hours: 25)));
    expect(after.swipes, 0);
    expect(after.considersToday, 0);
  });
}
