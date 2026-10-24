import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
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

  testWidgets('shared ZYRA loading now defaults to Comet line', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ZyraLoading())),
    );

    expect(find.byType(ZyraCometRule), findsOneWidget);
    expect(
      find.byKey(const ValueKey('zyra_loading_cometLoop')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byType(ZyraCometRule), findsOneWidget);
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
      find.byKey(const ValueKey('zyra_loading_cometLoop')),
      findsOneWidget,
    );
  });

  testWidgets('all ten options render real motion without a loading wordmark', (
    tester,
  ) async {
    expect(ZyraLoadingStyle.values, hasLength(10));

    for (final style in ZyraLoadingStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ZyraLoading(style: style)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        find.byKey(ValueKey('zyra_loading_${style.name}')),
        findsOneWidget,
        reason: '${style.label} must have a measurable rendered state',
      );
      expect(
        find.text('ZYRA'),
        findsNothing,
        reason: 'the locked wordmark belongs to splash, not repeat loaders',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('all ten options have a static reduced-motion frame', (
    tester,
  ) async {
    for (final style in ZyraLoadingStyle.values) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(body: ZyraLoading(style: style)),
          ),
        ),
      );

      expect(
        find.byKey(ValueKey('zyra_loading_${style.name}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('all ten moving and reduced-motion options share approved gold', () {
    expect(kZyraLoadingAccent, ZyraColors.journeyGold);
    for (final style in ZyraLoadingStyle.values) {
      expect(
        style.accentColor,
        ZyraColors.journeyGold,
        reason: '${style.label} must not drift from ZYRA gold',
      );
    }
  });

  testWidgets(
    'an explicit historical study does not change the shared default',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ZyraLoading())),
      );
      expect(
        find.byKey(const ValueKey('zyra_loading_cometLoop')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZyraLoading(style: ZyraLoadingStyle.constellation),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('zyra_loading_constellation')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ZyraLoading())),
      );
      expect(
        find.byKey(const ValueKey('zyra_loading_cometLoop')),
        findsOneWidget,
      );
    },
  );
}
