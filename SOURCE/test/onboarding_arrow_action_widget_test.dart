import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';

const _continue = ValueKey('onboarding_continue');
const _arrow = ValueKey('onboarding_animated_down_arrow');

Future<void> _pumpQuestion(
  WidgetTester tester, {
  required bool arrowMode,
  required bool active,
  VoidCallback? onContinue,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reduceMotion = false,
  bool devPreview = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: ZyraOnboardingArrowScope(
        enabled: arrowMode,
        child: OnboardingScaffold(
          background: ZyraBackgroundVariant.neutral,
          chapterName: 'Your Profile',
          chapterProgress: .35,
          question: 'What is your name?',
          content: const Text('Your answer'),
          fabActive: active,
          onContinue: onContinue,
          devPreview: devPreview,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets('gold arrow is shared presentation with an explicit comparator', (
    tester,
  ) async {
    await _pumpQuestion(
      tester,
      arrowMode: false,
      active: true,
      onContinue: () {},
    );
    expect(find.byKey(_continue), findsOneWidget);
    expect(find.byKey(_arrow), findsNothing);
    await _pumpQuestion(
      tester,
      arrowMode: true,
      active: true,
      onContinue: () {},
      devPreview: false,
    );
    expect(find.byKey(_continue), findsOneWidget);
    expect(find.byKey(_arrow), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabled arrow gives one finite gentle pulse and advances once', (
    tester,
  ) async {
    var advances = 0;
    await _pumpQuestion(
      tester,
      arrowMode: true,
      active: true,
      onContinue: () => advances++,
    );
    final action = find.byKey(_continue);
    expect(action, findsOneWidget);
    expect(find.byKey(_arrow), findsOneWidget);
    expect(
      find.descendant(of: action, matching: find.byType(Material)),
      findsNothing,
    );
    final gesture = tester.widget<GestureDetector>(
      find.descendant(of: action, matching: find.byType(GestureDetector)).first,
    );
    expect(gesture.behavior, HitTestBehavior.opaque);
    expect(gesture.onTap, isNotNull);
    expect(
      tester.widget<Icon>(find.byKey(_arrow)).color,
      ZyraColors.journeyGold,
    );
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: action,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.label == 'Continue',
            ),
          )
          .first,
    );
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.enabled, isTrue);
    expect(semantics.properties.label, 'Continue');
    expect(semantics.properties.onTap, isNotNull);
    final start = tester.getTopLeft(find.byKey(_arrow)).dy;
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.getTopLeft(find.byKey(_arrow)).dy, lessThan(start));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_arrow)).dy, closeTo(start, .1));
    await tester.tap(action);
    expect(advances, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkpoint arrow repeats its bounce while waiting', (
    tester,
  ) async {
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ZyraOnboardingArrowAction(
              active: true,
              repeatCue: true,
              onPressed: () => advances++,
            ),
          ),
        ),
      ),
    );
    final action = find.byType(ZyraOnboardingArrowAction);
    final restingTop = tester.getTopLeft(find.byKey(_arrow)).dy;
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_arrow)).dy, closeTo(restingTop, .1));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.getTopLeft(find.byKey(_arrow)).dy, lessThan(restingTop));
    await tester.tap(action);
    expect(advances, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, name: 'standard'),
    (size: Size(320, 568), scale: 1.4, name: 'compact enlarged'),
  ]) {
    testWidgets('${viewport.name} disabled arrow stays visible, safe, inert', (
      tester,
    ) async {
      var advances = 0;
      await _pumpQuestion(
        tester,
        arrowMode: true,
        active: false,
        onContinue: () => advances++,
        size: viewport.size,
        textScale: viewport.scale,
      );
      final action = find.byKey(_continue);
      final rect = tester.getRect(action);
      expect(rect.size, const Size(52, 52));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(viewport.size.width));
      expect(rect.top, greaterThanOrEqualTo(24));
      expect(rect.bottom, lessThanOrEqualTo(viewport.size.height - 24));
      expect(rect.bottom, closeTo(viewport.size.height - 24 - 14, .1));
      expect(
        find.descendant(of: action, matching: find.byType(Material)),
        findsNothing,
      );
      expect(
        tester.widget<Icon>(find.byKey(_arrow)).color,
        ZyraColors.journeyGold.withValues(alpha: 0.34),
      );
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: action,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == 'Continue',
              ),
            )
            .first,
      );
      expect(semantics.properties.enabled, isFalse);
      expect(semantics.properties.onTap, isNull);
      final gesture = tester.widget<GestureDetector>(
        find
            .descendant(of: action, matching: find.byType(GestureDetector))
            .first,
      );
      expect(gesture.onTap, isNull);
      await tester.tap(action);
      expect(advances, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing callback stays inert even when validation says active', (
    tester,
  ) async {
    await _pumpQuestion(tester, arrowMode: true, active: true);
    final action = find.byKey(_continue);
    final gesture = tester.widget<GestureDetector>(
      find.descendant(of: action, matching: find.byType(GestureDetector)).first,
    );
    expect(gesture.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion removes bounce without disabling the action', (
    tester,
  ) async {
    var advances = 0;
    await _pumpQuestion(
      tester,
      arrowMode: true,
      active: true,
      reduceMotion: true,
      onContinue: () => advances++,
    );
    final start = tester.getTopLeft(find.byKey(_arrow)).dy;
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.getTopLeft(find.byKey(_arrow)).dy, start);
    await tester.tap(find.byKey(_continue));
    expect(advances, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('both stage-intro actions keep original keys in arrow mode', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ZyraOnboardingArrowScope(
          enabled: true,
          child: OnboardingStageIntroScreen(
            stage: SeekerOnboardingStage.buildProfile,
            devPreview: true,
            allowPreviewScrolling: true,
            onContinue: () => advances++,
          ),
        ),
      ),
    );
    final welcome = find.byKey(const ValueKey('onboarding_welcome_continue'));
    expect(welcome, findsNothing);
    for (var item = 0; item < 4; item++) {
      await tester.tap(
        find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
      );
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(welcome);
    await tester.pumpAndSettle();
    expect(welcome.hitTestable(), findsOneWidget);
    expect(
      find.descendant(of: welcome, matching: find.byKey(_arrow)),
      findsOneWidget,
    );
    await tester.tap(welcome);
    await tester.pumpAndSettle();
    final stage = find.byKey(const ValueKey('onboarding_stage_continue'));
    await tester.ensureVisible(stage);
    await tester.pumpAndSettle();
    expect(stage.hitTestable(), findsOneWidget);
    expect(
      find.descendant(of: stage, matching: find.byKey(_arrow)),
      findsOneWidget,
    );
    await tester.tap(stage);
    expect(advances, 1);
    expect(tester.takeException(), isNull);
  });
}
