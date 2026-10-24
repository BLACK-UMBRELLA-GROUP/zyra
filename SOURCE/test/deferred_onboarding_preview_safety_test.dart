import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/article9_consent_screen.dart';
import 'package:zyra/screens/onboarding/bio_onboarding_flow.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/onboarding/profile_ready_screen.dart';
import 'package:zyra/screens/onboarding/values_preferences_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';

void main() {
  setUp(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  test('deferred Seeker routes default to ordinary member mode', () {
    expect(const Chapter2Flow(gender: 'male').devPreview, isFalse);
    expect(const BioOnboardingFlow(gender: 'male').devPreview, isFalse);
    expect(const ValuesPreferencesFlow(gender: 'male').devPreview, isFalse);
    expect(const ProfileReadyScreen().devPreview, isFalse);
    expect(Article9ConsentScreen(onDecision: (_) {}).devPreview, isFalse);
  });

  for (final (screen, deniedKey) in <(Widget, String)>[
    (
      const Chapter2Flow(gender: 'male', devPreview: true),
      'chapter2_preview_denied',
    ),
    (
      const BioOnboardingFlow(gender: 'male', devPreview: true),
      'bio_preview_denied',
    ),
    (
      const ValuesPreferencesFlow(gender: 'male', devPreview: true),
      'values_preview_denied',
    ),
    (
      const ProfileReadyScreen(devPreview: true),
      'profile_ready_preview_denied',
    ),
    (
      Article9ConsentScreen(devPreview: true, onDecision: (_) {}),
      'article9_preview_denied',
    ),
  ]) {
    testWidgets('$deniedKey closes on developer authorization revocation', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: screen));
      expect(find.byKey(ValueKey(deniedKey)), findsNothing);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(deniedKey)), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('stale Chapter2 dev skip cannot advance after revocation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Chapter2Flow(gender: 'male', devPreview: true)),
    );
    final callback = tester
        .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
        .onDevSkip!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    callback();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('chapter2_preview_denied')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Article9 preview decisions never require a persistence client', (
    tester,
  ) async {
    final decisions = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Article9ConsentScreen(
          devPreview: true,
          onDecision: decisions.add,
        ),
      ),
    );
    final accept = tester.widget<FilledButton>(find.byType(FilledButton));
    await tester.tap(find.text('I agree — use these answers to match me'));
    await tester.pump();
    expect(decisions, [true]);
    await tester.tap(find.text('Skip these questions'));
    await tester.pump();
    expect(decisions, [true, false]);

    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    accept.onPressed!();
    await tester.pump();
    expect(decisions, [true, false]);
    expect(
      find.byKey(const ValueKey('article9_preview_denied')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Values non-question stages expose local skip then deny it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ValuesPreferencesFlow(gender: 'male', devPreview: true),
      ),
    );
    final skip = find.byKey(const ValueKey('deferred_onboarding_dev_skip'));
    expect(skip.hitTestable(), findsOneWidget);
    final stale = tester.widget<TextButton>(skip).onPressed!;
    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsOneWidget);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('values_preview_denied')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DEV skips traverse deferred Seeker pages to the safe end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Chapter2Flow(gender: 'male', devPreview: true)),
    );

    var profileSteps = 0;
    while (find.byType(Chapter2Flow).evaluate().isNotEmpty &&
        profileSteps < 25) {
      final skip = find.byKey(const ValueKey('onboarding_dev_skip'));
      await tester.ensureVisible(skip);
      await tester.tap(skip);
      await tester.pumpAndSettle();
      profileSteps++;
    }
    expect(profileSteps, greaterThan(15));
    expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding_stage_dev_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(BioOnboardingFlow), findsOneWidget);

    var bioSteps = 0;
    while (find.byType(BioOnboardingFlow).evaluate().isNotEmpty &&
        bioSteps < 7) {
      final skip = find.byKey(const ValueKey('onboarding_dev_skip'));
      await tester.ensureVisible(skip);
      await tester.tap(skip);
      await tester.pumpAndSettle();
      bioSteps++;
    }
    expect(bioSteps, 5);
    expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding_stage_dev_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(ValuesPreferencesFlow), findsOneWidget);

    var compatibilitySteps = 0;
    while (find.byType(ValuesPreferencesFlow).evaluate().isNotEmpty &&
        compatibilitySteps < 300) {
      final scaffoldSkip = find.byKey(const ValueKey('onboarding_dev_skip'));
      final otherSkip = find.byKey(
        const ValueKey('deferred_onboarding_dev_skip'),
      );
      final skip = scaffoldSkip.evaluate().isNotEmpty
          ? scaffoldSkip
          : otherSkip;
      expect(skip, findsOneWidget);
      await tester.ensureVisible(skip);
      await tester.tap(skip);
      await tester.pumpAndSettle();
      compatibilitySteps++;
    }
    expect(compatibilitySteps, greaterThan(100));
    expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding_stage_dev_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileReadyScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile_ready_dev_skip')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('deferred skip controls remain usable on compact large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget scaled(Widget child) => MaterialApp(
      builder: (context, routed) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.4)),
        child: routed!,
      ),
      home: child,
    );

    await tester.pumpWidget(
      scaled(const ValuesPreferencesFlow(gender: 'male', devPreview: true)),
    );
    expect(
      find.byKey(const ValueKey('deferred_onboarding_dev_skip')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(scaled(const ProfileReadyScreen(devPreview: true)));
    expect(
      find.byKey(const ValueKey('profile_ready_dev_skip')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
