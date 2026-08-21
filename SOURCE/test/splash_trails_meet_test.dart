import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/widgets/zyra_trails_meet_rule.dart';

void main() {
  test('Trails Meet geometry draws two halves into the same centre', () {
    final start = ZyraTrailsMeetFrame.at(width: 240, progress: 0);
    expect(start.leftDot, start.start);
    expect(start.rightDot, start.end);

    final halfway = ZyraTrailsMeetFrame.at(width: 240, progress: 0.5);
    expect(halfway.leftDot, lessThan(halfway.centre));
    expect(halfway.rightDot, greaterThan(halfway.centre));
    expect(
      halfway.centre - halfway.leftDot,
      closeTo(halfway.rightDot - halfway.centre, 0.001),
    );

    final connected = ZyraTrailsMeetFrame.at(width: 240, progress: 1);
    expect(connected.leftDot, connected.centre);
    expect(connected.rightDot, connected.centre);
  });

  testWidgets(
    'the real splash defaults to Trails Meet and keeps its wordmark',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      expect(
        find.byKey(const ValueKey('splash_trails_meet_rule')),
        findsOneWidget,
      );
      expect(find.text('Z'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );
}
