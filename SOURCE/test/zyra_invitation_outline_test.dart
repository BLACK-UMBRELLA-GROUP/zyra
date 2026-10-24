import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_invitation_outline.dart';

const _outlineKey = ValueKey('decorative-invitation-outline');
const _cardKey = ValueKey('underlying-card');
const _actionKey = ValueKey('underlying-action');
const _radius = BorderRadius.all(Radius.circular(14));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platformCalls = <MethodCall>[];
  var taps = 0;

  Widget subject({
    required bool sent,
    bool disableAnimations = false,
    bool accessibleNavigation = false,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          key: _cardKey,
          width: 200,
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Semantics(
                label: 'Original person action',
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  key: _actionKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const ColoredBox(color: Colors.black),
                ),
              ),
              Positioned.fill(
                child: ZyraInvitationOutline(
                  key: _outlineKey,
                  sent: sent,
                  borderRadius: _radius,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Finder within(Type type) =>
      find.descendant(of: find.byKey(_outlineKey), matching: find.byType(type));
  BoxDecoration decoration(WidgetTester tester) =>
      tester.widget<DecoratedBox>(within(DecoratedBox)).decoration
          as BoxDecoration;
  double alpha(WidgetTester tester) =>
      (decoration(tester).border! as Border).top.color.a;
  void expectFixedStroke(WidgetTester tester) {
    final border = decoration(tester).border! as Border;
    for (final side in [border.top, border.right, border.bottom, border.left]) {
      expect(side.width, 5);
      expect(side.style, BorderStyle.solid);
      expect(side.color, border.top.color);
    }
  }

  setUp(() {
    taps = 0;
    platformCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });
  tearDown(() {
    expect(
      platformCalls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
      reason: 'Decorative outline has no haptic or action authority.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('unsent outline is transparent and does not add a fill', (
    tester,
  ) async {
    await tester.pumpWidget(subject(sent: false));
    await tester.pumpAndSettle();
    expect(alpha(tester), 0);
    expect(decoration(tester).color, isNull);
    expect(decoration(tester).borderRadius, _radius);
    expectFixedStroke(tester);
    expect(
      tester.getRect(find.byKey(_outlineKey)),
      tester.getRect(find.byKey(_cardKey)),
    );
    expect(taps, 0);
  });

  testWidgets('sending fades gold in through a measured midpoint', (
    tester,
  ) async {
    await tester.pumpWidget(subject(sent: false));
    final before = tester.getRect(find.byKey(_cardKey));
    await tester.pumpWidget(subject(sent: true));
    expect(alpha(tester), 0);
    final animation = tester.widget<TweenAnimationBuilder<double>>(
      within(TweenAnimationBuilder<double>),
    );
    expect(animation.duration, const Duration(milliseconds: 260));
    expect(animation.curve, Curves.easeOutCubic);
    expectFixedStroke(tester);
    await tester.pump(const Duration(milliseconds: 130));
    expect(alpha(tester), inExclusiveRange(0, .65));
    expectFixedStroke(tester);
    expect(tester.getRect(find.byKey(_cardKey)), before);
    expect(tester.getRect(find.byKey(_outlineKey)), before);
    expect(taps, 0);
    await tester.pumpAndSettle();
    expect(alpha(tester), closeTo(.65, .001));
    expectFixedStroke(tester);
    expect(decoration(tester).color, isNull);
    expect(decoration(tester).borderRadius, _radius);
    expect(tester.getRect(find.byKey(_outlineKey)), before);
    expect(
      (decoration(tester).border! as Border).top.color,
      ZyraColors.journeyGold.withValues(alpha: .65),
    );
    expect(taps, 0);
  });

  testWidgets(
    'cancelling sent state fades back to transparent without action',
    (tester) async {
      await tester.pumpWidget(subject(sent: true));
      await tester.pumpAndSettle();
      final before = tester.getRect(find.byKey(_cardKey));
      await tester.pumpWidget(subject(sent: false));
      expect(alpha(tester), closeTo(.65, .001));
      final animation = tester.widget<TweenAnimationBuilder<double>>(
        within(TweenAnimationBuilder<double>),
      );
      expect(animation.duration, const Duration(milliseconds: 180));
      expectFixedStroke(tester);
      await tester.pump(const Duration(milliseconds: 90));
      expect(alpha(tester), inExclusiveRange(0, .65));
      expectFixedStroke(tester);
      await tester.pumpAndSettle();
      expect(alpha(tester), 0);
      expectFixedStroke(tester);
      expect(tester.getRect(find.byKey(_cardKey)), before);
      expect(taps, 0);
    },
  );

  testWidgets('cancellation during fade-in retargets from its current alpha', (
    tester,
  ) async {
    await tester.pumpWidget(subject(sent: false));
    await tester.pumpWidget(subject(sent: true));
    await tester.pump(const Duration(milliseconds: 80));
    final midway = alpha(tester);
    expect(midway, inExclusiveRange(0, .65));
    await tester.pumpWidget(subject(sent: false));
    expect(alpha(tester), closeTo(midway, .001));
    await tester.pump(const Duration(milliseconds: 90));
    expect(alpha(tester), inExclusiveRange(0, midway));
    await tester.pumpAndSettle();
    expect(alpha(tester), 0);
    expectFixedStroke(tester);
    expect(taps, 0);
  });

  for (final quiet in const [
    (disable: true, accessible: false),
    (disable: false, accessible: true),
    (disable: true, accessible: true),
  ]) {
    testWidgets('quiet ${quiet.disable}/${quiet.accessible} uses final alpha', (
      tester,
    ) async {
      await tester.pumpWidget(
        subject(
          sent: true,
          disableAnimations: quiet.disable,
          accessibleNavigation: quiet.accessible,
        ),
      );
      expect(alpha(tester), closeTo(.65, .001));
      expectFixedStroke(tester);
      await tester.pumpWidget(
        subject(
          sent: false,
          disableAnimations: quiet.disable,
          accessibleNavigation: quiet.accessible,
        ),
      );
      expect(alpha(tester), 0);
      expectFixedStroke(tester);
      expect(taps, 0);
      await tester.pumpAndSettle();
      expect(alpha(tester), 0);
    });
  }

  for (final accessible in [false, true]) {
    for (final finalSent in [false, true]) {
      testWidgets(
        'quiet flag $accessible snaps an existing $finalSent animation to final alpha',
        (tester) async {
          await tester.pumpWidget(subject(sent: !finalSent));
          await tester.pumpAndSettle();
          await tester.pumpWidget(subject(sent: finalSent));
          await tester.pump(const Duration(milliseconds: 60));
          expect(alpha(tester), inExclusiveRange(0, .65));
          // Keep the same target: changing only the accessibility preference
          // must stop an already-running fade, not merely change its duration.
          await tester.pumpWidget(
            subject(
              sent: finalSent,
              disableAnimations: !accessible,
              accessibleNavigation: accessible,
            ),
          );
          expect(alpha(tester), closeTo(finalSent ? .65 : 0, .001));
          expectFixedStroke(tester);
          expect(taps, 0);
          await tester.pumpAndSettle();
          expect(alpha(tester), closeTo(finalSent ? .65 : 0, .001));
          expectFixedStroke(tester);
        },
      );
    }
  }

  testWidgets(
    'outline ignores pointers and has no gesture/callback authority',
    (tester) async {
      await tester.pumpWidget(subject(sent: true));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IgnorePointer>(within(IgnorePointer)).ignoring,
        isTrue,
      );
      expect(within(GestureDetector), findsNothing);
      expect(within(InkWell), findsNothing);
      expect(within(Listener), findsNothing);
      await tester.tap(find.byKey(_actionKey));
      await tester.pumpAndSettle();
      expect(taps, 1, reason: 'Only the underlying caller action runs.');
    },
  );

  testWidgets('outline adds no accessibility node or action', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(subject(sent: true));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ExcludeSemantics>(within(ExcludeSemantics)).excluding,
        isTrue,
      );
      expect(find.bySemanticsLabel('Original person action'), findsOneWidget);
      expect(within(Semantics), findsNothing);
      expect(taps, 0);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('disposing a fading outline invokes no action or late callback', (
    tester,
  ) async {
    await tester.pumpWidget(subject(sent: true));
    await tester.pump(const Duration(milliseconds: 70));
    expect(alpha(tester), inExclusiveRange(0, .65));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });
}
