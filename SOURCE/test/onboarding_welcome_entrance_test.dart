import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

Future<void> _pumpWelcome(
  WidgetTester tester, {
  bool devPreview = true,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
        ),
        child: child!,
      ),
      home: OnboardingPreviewStyle(
        directionName: 'luma',
        child: ZyraOnboardingArrowScope(
          enabled: true,
          child: OnboardingStageIntroScreen(
            stage: SeekerOnboardingStage.buildProfile,
            devPreview: devPreview,
            allowPreviewScrolling: devPreview,
            onContinue: () {},
          ),
        ),
      ),
    ),
  );
}

double _opacityAt(WidgetTester tester, int step) {
  final reveal = find.byKey(ValueKey('onboarding_welcome_reveal_$step'));
  final opacity = find.descendant(of: reveal, matching: find.byType(Opacity));
  return tester.widget<Opacity>(opacity).opacity;
}

double _roadmapOpacity(WidgetTester tester, int item) => tester
    .widget<AnimatedOpacity>(
      find.byKey(ValueKey('onboarding_roadmap_item_$item')),
    )
    .opacity;

Future<void> _revealNext(WidgetTester tester) async {
  await tester.tapAt(const Offset(195, 700));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  testWidgets('Welcome reveals one roadmap item per tap, then the arrow', (
    tester,
  ) async {
    await _pumpWelcome(tester);

    expect(_opacityAt(tester, 2), 0);
    expect(_roadmapOpacity(tester, 1), 0);
    expect(_roadmapOpacity(tester, 4), 0);
    expect(
      find.byKey(const ValueKey('onboarding_welcome_progress_cue')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 1650));
    expect(_opacityAt(tester, 2), 1);
    expect(_roadmapOpacity(tester, 1), 0);
    expect(
      find.byKey(const ValueKey('onboarding_welcome_continue')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 1400));
    for (var step = 0; step < 3; step++) {
      expect(_opacityAt(tester, step), 1);
    }
    for (var item = 1; item <= 4; item++) {
      await _revealNext(tester);
      expect(_roadmapOpacity(tester, item), 1);
      if (item < 4) {
        expect(_roadmapOpacity(tester, item + 1), 0);
        expect(
          find.byKey(const ValueKey('onboarding_welcome_continue')),
          findsNothing,
        );
      }
    }
    expect(
      find.byKey(const ValueKey('onboarding_welcome_continue')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced-motion Welcome still reveals on demand without movement',
    (tester) async {
      await _pumpWelcome(tester, disableAnimations: true);
      expect(find.text('Together, we’ll build four things.'), findsOneWidget);
      expect(_roadmapOpacity(tester, 4), 0);
      await _revealNext(tester);
      expect(_roadmapOpacity(tester, 1), 1);
      expect(
        find.byKey(const ValueKey('onboarding_welcome_continue')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('screen-reader navigation bypasses the automatic entrance', (
    tester,
  ) async {
    await _pumpWelcome(tester, accessibleNavigation: true);
    expect(find.text('Your Journey Bio'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding_welcome_reveal_2')),
      findsNothing,
    );
    expect(_roadmapOpacity(tester, 2), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary signup also requires four deliberate reveals', (
    tester,
  ) async {
    await _pumpWelcome(tester, devPreview: false);
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('Compatibility'), findsOneWidget);
    expect(_roadmapOpacity(tester, 1), 0);
    expect(
      find.byKey(const ValueKey('onboarding_welcome_continue')),
      findsNothing,
    );
    for (var item = 1; item <= 4; item++) {
      await _revealNext(tester);
    }
    expect(
      find.byKey(const ValueKey('onboarding_welcome_continue')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (setting, disableAnimations, accessibleNavigation) in const [
    ('normal settings', false, false),
    ('screen-reader navigation', false, true),
    ('reduced motion', true, false),
  ]) {
    testWidgets(
      'ordinary $setting reveals roadmap through semantic actions then continues',
      (tester) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        final semantics = tester.ensureSemantics();
        try {
          await _pumpWelcome(
            tester,
            devPreview: false,
            disableAnimations: disableAnimations,
            accessibleNavigation: accessibleNavigation,
          );
          await tester.pumpAndSettle();
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          final pager = tester
              .widget<PageView>(
                find.byKey(const ValueKey('onboarding_intro_page_view')),
              )
              .controller!;
          expect(pager.page, closeTo(0, .001));
          const titles = [
            'Your profile',
            'Your Journey Bio',
            'Compatibility',
            'Review & go live',
          ];
          final reveal = find.semantics.byLabel('Reveal next setup step');
          final continuation = find.semantics.byLabel(
            'Continue to Your Profile',
          );

          void expectRevealedRows(int revealed) {
            for (var index = 0; index < titles.length; index++) {
              expect(
                _roadmapOpacity(tester, index + 1),
                index < revealed ? 1 : 0,
              );
              expect(
                find.semantics.byLabel(RegExp(RegExp.escape(titles[index]))),
                index < revealed ? findsOne : findsNothing,
                reason: 'Only the first $revealed setup steps are revealed.',
              );
            }
          }

          expectRevealedRows(0);
          for (var revealed = 0; revealed < titles.length; revealed++) {
            expect(reveal, findsOne);
            expect(
              reveal.evaluate().single,
              isSemantics(
                label: 'Reveal next setup step',
                value: '$revealed of 4 revealed',
                isButton: true,
                hasEnabledState: true,
                isEnabled: true,
                hasTapAction: true,
              ),
            );
            expect(continuation, findsNothing);
            expect(
              find.byKey(const ValueKey('onboarding_welcome_continue')),
              findsNothing,
            );
            tester.semantics.tap(reveal);
            await tester.pumpAndSettle();
            expectRevealedRows(revealed + 1);
            expect(pager.page, closeTo(0, .001));
          }

          expect(reveal, findsNothing);
          expect(continuation, findsOne);
          expect(
            continuation.evaluate().single,
            isSemantics(
              label: 'Continue to Your Profile',
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
            ),
          );
          tester.semantics.tap(continuation);
          await tester.pumpAndSettle();
          expect(pager.page, closeTo(1, .001));
          expect(find.text('Let’s begin with your profile.'), findsOneWidget);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
