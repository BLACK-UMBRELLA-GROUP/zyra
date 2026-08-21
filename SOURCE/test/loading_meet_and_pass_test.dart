import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_comet_rule.dart';
import 'package:zyra/widgets/zyra_loading.dart';
import 'package:zyra/widgets/zyra_meet_and_pass_rule.dart';

void main() {
  test('Meet and Pass crosses once, fades out, and resets while invisible', () {
    final start = ZyraMeetAndPassFrame.at(width: 120, progress: 0);
    expect(start.leftDot, start.start);
    expect(start.rightDot, start.end);
    expect(start.dotOpacity, 0);

    final beforeMeeting = ZyraMeetAndPassFrame.at(width: 120, progress: 0.40);
    expect(beforeMeeting.leftDot, lessThan(beforeMeeting.rightDot));

    final afterMeeting = ZyraMeetAndPassFrame.at(width: 120, progress: 0.50);
    expect(afterMeeting.leftDot, greaterThan(afterMeeting.rightDot));
    expect(afterMeeting.dotOpacity, 1);

    final blankBoundary = ZyraMeetAndPassFrame.at(width: 120, progress: 1);
    expect(blankBoundary.dotOpacity, 0);
  });

  testWidgets('shared ZYRA loading now defaults to Meet and Pass', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ZyraLoading())),
    );

    expect(
      find.byKey(const ValueKey('loading_meet_and_pass_rule')),
      findsOneWidget,
    );
    expect(find.byType(ZyraCometRule), findsNothing);

    await tester.pump(const Duration(milliseconds: 1400));
    expect(
      find.byKey(const ValueKey('loading_meet_and_pass_rule')),
      findsOneWidget,
    );
  });

  testWidgets('reduced motion keeps a static connected gold indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Scaffold(body: ZyraLoading())),
      ),
    );

    expect(
      find.byKey(const ValueKey('loading_meet_and_pass_rule')),
      findsOneWidget,
    );
  });
}
