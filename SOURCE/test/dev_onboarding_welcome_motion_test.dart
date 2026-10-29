import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_directions.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_welcome_motion.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDevWelcomeTextMotion.resetForTesting();
    ZyraDevWelcomePulseIntensity.resetForTesting();
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevWelcomeTextMotion.resetForTesting();
    ZyraDevWelcomePulseIntensity.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  test('fifteen styles in three families reset to Slow descent', () {
    final options = ZyraWelcomeTextMotion.values;
    expect(options, hasLength(15));
    expect(options.map((option) => option.label), [
      'Slow descent',
      'Lighter descent',
      'Deeper descent',
      'Lingering descent',
      'Soft landing',
      'Quiet typewriter',
      'Brisk typewriter',
      'Measured typewriter',
      'Eased typewriter',
      'Soft typewriter',
      'Descent + typewriter',
      'Light descent + typewriter',
      'Deep descent + typewriter',
      'Lingering descent + typewriter',
      'Soft landing + typewriter',
    ]);
    for (final family in ZyraWelcomeTextMotionFamily.values) {
      expect(options.where((option) => option.family == family), hasLength(5));
    }
    expect(ZyraDevWelcomeTextMotion.current, ZyraWelcomeTextMotion.slowDescent);
    expect(
      ZyraDevWelcomeTextMotion.select(ZyraWelcomeTextMotion.lighterDescent),
      isTrue,
    );
    expect(
      ZyraDevWelcomeTextMotion.current,
      ZyraWelcomeTextMotion.lighterDescent,
    );
    ZyraAccountState.resetForTesting();
    expect(ZyraDevWelcomeTextMotion.current, ZyraWelcomeTextMotion.slowDescent);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(
      ZyraDevWelcomeTextMotion.select(ZyraWelcomeTextMotion.softLanding),
      isFalse,
    );
  });

  testWidgets(
    'toggle shows five whole-page motion choices without typing or a dead pulse slider',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: DevOnboardingTransitionPicker()),
          ),
        ),
      );
      for (final motion in ZyraWelcomeTextMotion.values) {
        expect(
          find.byKey(ValueKey('dev_welcome_text_motion_${motion.name}')),
          motion.typesText ? findsNothing : findsOneWidget,
        );
      }
      expect(find.text('Descent + typewriter blends'), findsNothing);
      expect(find.text('Typewriter'), findsNothing);
      expect(find.text('Gold pulse intensity'), findsNothing);
      expect(
        find.byKey(const ValueKey('dev_welcome_pulse_intensity_slider')),
        findsNothing,
      );
      final choice = find.byKey(
        const ValueKey('dev_welcome_text_motion_lighterDescent'),
      );
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump();
      expect(
        ZyraDevWelcomeTextMotion.current,
        ZyraWelcomeTextMotion.lighterDescent,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DevOnboardingTransitionPicker(enabled: false),
            ),
          ),
        ),
      );
      expect(tester.widget<InkWell>(choice).onTap, isNull);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      expect(choice, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('descent variants change only distance, pace or easing', (
    tester,
  ) async {
    Future<(double, double)> sample(ZyraWelcomeTextMotion motion) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraWelcomeTextMotionFrame(
              motion: motion,
              animation: const AlwaysStoppedAnimation<double>(.75),
              child: const Text('Welcome line'),
            ),
          ),
        ),
      );
      final frame = find.byType(ZyraWelcomeTextMotionFrame);
      final opacity = tester.widget<Opacity>(
        find.descendant(of: frame, matching: find.byType(Opacity)),
      );
      final transform = tester.widget<Transform>(
        find.descendant(of: frame, matching: find.byType(Transform)),
      );
      return (opacity.opacity, transform.transform.getTranslation().y);
    }

    final slow = await sample(ZyraWelcomeTextMotion.slowDescent);
    final lighter = await sample(ZyraWelcomeTextMotion.lighterDescent);
    final deeper = await sample(ZyraWelcomeTextMotion.deeperDescent);
    final lingering = await sample(ZyraWelcomeTextMotion.lingeringDescent);
    final landing = await sample(ZyraWelcomeTextMotion.softLanding);

    expect(slow.$1, closeTo(.5, .01));
    expect(slow.$2, closeTo(-8, .1));
    expect(lighter.$1, closeTo(slow.$1, .001));
    expect(lighter.$2, closeTo(-6, .1));
    expect(deeper.$1, closeTo(slow.$1, .001));
    expect(deeper.$2, closeTo(-10, .1));
    expect(lingering.$1, closeTo(slow.$1, .001));
    expect(lingering.$2, closeTo(slow.$2, .001));
    expect(
      ZyraWelcomeTextMotion.lingeringDescent.duration,
      greaterThan(ZyraWelcomeTextMotion.slowDescent.duration),
    );
    expect(landing.$1, closeTo(.875, .001));
    expect(landing.$2, closeTo(-2, .01));
    expect(
      ZyraWelcomeTextMotion.softLanding.duration,
      ZyraWelcomeTextMotion.slowDescent.duration,
    );
  });

  testWidgets('typewriter reveals whole graphemes without moving line layout', (
    tester,
  ) async {
    const full = 'A👨‍👩‍👧‍👦B';
    for (final motion in [
      ZyraWelcomeTextMotion.quietTypewriter,
      ZyraWelcomeTextMotion.descentTypewriter,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraWelcomeTextMotionFrame(
              motion: motion,
              animation: const AlwaysStoppedAnimation<double>(.75),
              child: const ZyraWelcomeLine(
                text: full,
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
      );
      final frame = find.byType(ZyraWelcomeTextMotionFrame);
      final rendered = tester.widget<Text>(
        find.descendant(of: frame, matching: find.byType(Text)),
      );
      final spans = (rendered.textSpan! as TextSpan).children!;
      expect((spans.first as TextSpan).text, 'A👨‍👩‍👧‍👦');
      expect((spans.last as TextSpan).text, 'B');
      expect(rendered.textSpan!.toPlainText(), full);
      expect(rendered.semanticsLabel, full);
      expect(
        find.descendant(of: frame, matching: find.byType(Transform)),
        motion.family == ZyraWelcomeTextMotionFamily.blend
            ? findsOneWidget
            : findsNothing,
      );
    }
  });

  testWidgets(
    'the opening presents complete welcome copy despite an old typing choice',
    (tester) async {
      expect(
        ZyraDevWelcomeTextMotion.select(ZyraWelcomeTextMotion.quietTypewriter),
        isTrue,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: DevOnboardingIntroduction(
            direction: ZyraOnboardingDirection.luma,
            onContinue: _noOp,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final greeting = find.textContaining('Shakeel');
      expect(greeting, findsOneWidget);
      expect(tester.widget<Text>(greeting).data, isNotNull);
      expect(find.textContaining('praise Allah'), findsOneWidget);
      expect(find.textContaining('May Allah'), findsOneWidget);
      expect(find.byType(ZyraWelcomeLine), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('pulse levels are named, guarded and reset with the account', () {
    expect(ZyraDevWelcomePulseIntensity.level, 3);
    expect(ZyraDevWelcomePulseIntensity.label, 'Balanced');
    expect(ZyraDevWelcomePulseIntensity.amplitude, .20);
    expect(ZyraDevWelcomePulseIntensity.select(1), isTrue);
    expect(ZyraDevWelcomePulseIntensity.label, 'Subtle');
    expect(ZyraDevWelcomePulseIntensity.amplitude, .08);
    expect(ZyraDevWelcomePulseIntensity.select(5), isTrue);
    expect(ZyraDevWelcomePulseIntensity.label, 'Bold');
    expect(ZyraDevWelcomePulseIntensity.amplitude, .35);
    expect(ZyraDevWelcomePulseIntensity.select(0), isFalse);
    expect(ZyraDevWelcomePulseIntensity.select(6), isFalse);
    ZyraAccountState.resetForTesting();
    expect(ZyraDevWelcomePulseIntensity.level, 3);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(ZyraDevWelcomePulseIntensity.select(5), isFalse);
  });

  testWidgets(
    'Guardian is the final card and uses an arrow without a pulse dot',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: DevOnboardingIntroduction(
              direction: ZyraOnboardingDirection.luma,
              onContinue: _noOp,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_verification_continue')),
      );
      await tester.pump();
      for (var page = 1; page <= 2; page++) {
        await tester.tap(find.byKey(ValueKey('dev_opening_page_$page')));
        await tester.pump();
      }
      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.byType(ZyraWelcomePulseMark), findsNothing);
      expect(
        find.byKey(const ValueKey('dev_onboarding_story_continue')),
        findsOneWidget,
      );
      expect(find.textContaining('Let’s begin'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final motion in ZyraWelcomeTextMotion.values) {
    testWidgets(
      '${motion.label} cannot reintroduce typed or partial opening text',
      (tester) async {
        expect(ZyraDevWelcomeTextMotion.select(motion), isTrue);
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: DevOnboardingIntroduction(
                direction: ZyraOnboardingDirection.luma,
                onContinue: _noOp,
              ),
            ),
          ),
        );
        await tester.pump();
        final canvas = find.byKey(
          const ValueKey('dev_onboarding_static_canvas'),
        );
        expect(canvas, findsOneWidget);
        expect(find.byType(ZyraWelcomeLine), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('dev_onboarding_verification_continue')),
        );
        await tester.pump();
        final photo = find.byKey(const ValueKey('dev_opening_page_1'));
        expect(photo, findsOneWidget);
        for (final element
            in find
                .descendant(of: photo, matching: find.byType(Text))
                .evaluate()) {
          expect((element.widget as Text).data, isNotNull);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'reduced motion presents all welcome content and an immediate stationary arrow',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: DevOnboardingIntroduction(
              direction: ZyraOnboardingDirection.luma,
              onContinue: _noOp,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Shakeel'), findsOneWidget);
      expect(find.textContaining('praise Allah'), findsOneWidget);
      expect(find.textContaining('May Allah'), findsOneWidget);
      final arrow = find.byKey(
        const ValueKey('dev_onboarding_welcome_continue'),
      );
      expect(arrow, findsOneWidget);
      await tester.tap(arrow);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_verification_continue')),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('dev_opening_page_1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all welcome motions keep outgoing and incoming text separate', (
    tester,
  ) async {
    const old = ValueKey('outgoing_welcome_line');
    const next = ValueKey('incoming_welcome_line');
    for (final motion in ZyraWelcomeTextMotion.values) {
      for (final progress in const <double>[
        0,
        .2,
        .4,
        .49,
        .5,
        .51,
        .6,
        .8,
        1,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ZyraWelcomeTextMotionFrame(
                    key: old,
                    motion: motion,
                    animation: ReverseAnimation(
                      AlwaysStoppedAnimation<double>(progress),
                    ),
                    child: const Text('Outgoing'),
                  ),
                  ZyraWelcomeTextMotionFrame(
                    key: next,
                    motion: motion,
                    animation: AlwaysStoppedAnimation<double>(progress),
                    child: const Text('Incoming'),
                  ),
                ],
              ),
            ),
          ),
        );
        double opacityOf(ValueKey<String> key) => tester
            .widget<Opacity>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Opacity),
              ),
            )
            .opacity;
        expect(
          opacityOf(old) * opacityOf(next),
          0,
          reason: '${motion.name} overlaps at $progress',
        );
      }
    }
  });
}

void _noOp() {}
