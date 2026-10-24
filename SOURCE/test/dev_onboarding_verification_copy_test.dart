import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_welcome_motion.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

const _oldRequirement =
    'Identity verification is required to complete sign-up.';
const _trustHeading = 'Verified people.\nSerious intentions.';
const _trustBody =
    'Every Seeker and Guardian must complete identity verification before joining ZYRA.';
const _trustClosing = 'A shared standard for a community focused on marriage.';
const _trustPage = ValueKey('dev_onboarding_verification_intro');
const _trustHeadingKey = ValueKey('dev_onboarding_verification_heading');
const _trustBodyKey = ValueKey('dev_onboarding_verification_body');
const _trustClosingKey = ValueKey('dev_onboarding_verification_closing');
const _trustArrow = ValueKey('dev_onboarding_verification_continue');
const _trustBack = ValueKey('dev_onboarding_verification_back');
const _trustWait = ValueKey('dev_onboarding_verification_arrow_wait');
const _welcomeArrow = ValueKey('dev_onboarding_welcome_continue');
const _captureRoot = ValueKey('verification-intro-candidate');
const _capture = bool.fromEnvironment(
  'ZYRA_VERIFICATION_INTRO_CAPTURE_CANDIDATES',
);

Future<void> _mount(
  WidgetTester tester, {
  ZyraOnboardingDirection direction = ZyraOnboardingDirection.luma,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reducedMotion = false,
  bool accessibleNavigation = false,
  VoidCallback? onContinue,
  VoidCallback? onBack,
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
          disableAnimations: reducedMotion,
          accessibleNavigation: accessibleNavigation,
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: RepaintBoundary(key: _captureRoot, child: child!),
      ),
      home: DevOnboardingIntroduction(
        direction: direction,
        welcomeName: 'Amina Zahra',
        onContinue: onContinue ?? () {},
        onBackToProvider: onBack,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _waitForArrow(WidgetTester tester, Key key) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  final arrow = find.byKey(key);
  await tester.ensureVisible(arrow);
  await tester.pumpAndSettle();
  expect(arrow.hitTestable(), findsOneWidget);
}

Future<void> _openTrust(WidgetTester tester) async {
  await _waitForArrow(tester, _welcomeArrow);
  await tester.tap(find.byKey(_welcomeArrow));
  await tester.pumpAndSettle();
  expect(find.byKey(_trustPage), findsOneWidget);
}

void _expectNoThemeProgress() {
  for (var theme = 0; theme < 4; theme++) {
    expect(
      find.byKey(ValueKey('dev_onboarding_story_dot_$theme')),
      findsNothing,
    );
    expect(find.text('${theme + 1} / 4'), findsNothing);
  }
  expect(find.text('1 / 5'), findsNothing);
}

void _expectSectionProgress(int position) {
  expect(find.text('$position / 4'), findsOneWidget);
  for (var dot = 0; dot < 4; dot++) {
    final indicator = find.byKey(ValueKey('dev_onboarding_story_dot_$dot'));
    expect(indicator, findsOneWidget);
    final semantics = indicator.evaluate().single.widget as Semantics;
    expect(semantics.properties.selected, dot == position - 1);
    expect(
      semantics.properties.value,
      dot < position - 1
          ? 'Completed'
          : dot == position - 1
          ? 'Current'
          : 'Upcoming',
    );
  }
  expect(
    find.byKey(const ValueKey('dev_onboarding_story_dot_4')),
    findsNothing,
  );
}

void _expectBoundedClaims() {
  expect(find.text(_oldRequirement), findsNothing);
  expect(find.text('All members are verified.'), findsNothing);
  expect(find.text('Everyone here is verified.'), findsNothing);
  expect(
    find.textContaining(RegExp('Muzz', caseSensitive: false)),
    findsNothing,
  );
}

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  await expectLater(
    find.byKey(_captureRoot),
    matchesGoldenFile(
      'visual/candidates/four_slide_intro_2026_10_04/audit_$name.png',
    ),
  );
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsVerificationIntroAudit');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneVerificationIntroAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.testReadingFontFamily = 'PoppinsVerificationIntroAudit';
    ZyraText.testWordmarkFontFamily = 'SyneVerificationIntroAudit';
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevWelcomeTextMotion.resetForTesting();
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevWelcomeTextMotion.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  tearDownAll(() {
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final direction in ZyraOnboardingDirection.values.skip(1)) {
    testWidgets(
      '${direction.name} separates Welcome from four meaningful section pages',
      (tester) async {
        var completed = 0;
        await _mount(
          tester,
          direction: direction,
          onContinue: () => completed++,
        );
        expect(find.text('Welcome to ZYRA, Amina.'), findsOneWidget);
        expect(find.text(_trustBody), findsNothing);
        expect(
          find.text(
            'We praise Allah and send peace and blessings upon His Messenger ﷺ.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'May Allah make the path ahead easy for you and guide you towards what is best.',
          ),
          findsOneWidget,
        );
        _expectBoundedClaims();
        _expectNoThemeProgress();

        await _openTrust(tester);
        expect(find.text(_trustHeading), findsOneWidget);
        expect(find.text(_trustBody), findsOneWidget);
        expect(find.text(_trustClosing), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dev_onboarding_verification_art')),
          findsOneWidget,
        );
        expect(find.text('Welcome to ZYRA, Amina.'), findsNothing);
        expect(find.byKey(const ValueKey('dev_opening_page_1')), findsNothing);
        _expectBoundedClaims();
        _expectSectionProgress(1);
        expect(completed, 0);
        expect(tester.widget(find.byKey(_trustArrow)), isA<IconButton>());
        expect(find.byKey(_trustWait), findsNothing);
        await tester.tap(find.byKey(_trustArrow));
        await tester.pumpAndSettle();

        for (var page = 1; page <= 3; page++) {
          expect(
            find.byKey(ValueKey('dev_opening_page_$page')),
            findsOneWidget,
          );
          _expectSectionProgress(page + 1);
          expect(find.text(_trustBody), findsNothing);
          if (page < 3) {
            await tester.tap(find.byKey(ValueKey('dev_opening_page_$page')));
            await tester.pumpAndSettle();
          }
        }
        expect(completed, 0);
        await tester.tap(
          find.byKey(const ValueKey('dev_onboarding_story_continue')),
        );
        await tester.pumpAndSettle();
        expect(completed, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('trust is immediately available after entry and after Back', (
    tester,
  ) async {
    await _mount(tester);
    await _waitForArrow(tester, _welcomeArrow);
    await tester.tap(find.byKey(_welcomeArrow));
    await tester.pump();
    final motionMilliseconds = ZyraDevWelcomeTextMotion.current.milliseconds;
    await tester.pump(
      Duration(milliseconds: (motionMilliseconds * .35).round() + 1),
    );
    await tester.pump();
    await tester.pump(
      Duration(milliseconds: (motionMilliseconds * .65).round() + 1),
    );
    await tester.pump();
    expect(find.byKey(_trustPage), findsOneWidget);
    expect(find.byKey(_trustWait), findsNothing);
    _expectSectionProgress(1);
    expect(tester.widget(find.byKey(_trustArrow)), isA<IconButton>());
    expect(find.byKey(_trustArrow).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(_trustArrow));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_story_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(_trustPage), findsOneWidget);
    expect(find.byKey(_trustWait), findsNothing);
    _expectSectionProgress(1);
    expect(tester.widget(find.byKey(_trustArrow)), isA<IconButton>());
    expect(find.byKey(_trustArrow).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final accessible in [false, true]) {
    testWidgets(
      '${accessible ? 'screen reader' : 'reduced motion'} gets complete trust and immediate action',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _mount(
            tester,
            reducedMotion: !accessible,
            accessibleNavigation: accessible,
          );
          await tester.tap(find.byKey(_welcomeArrow));
          await tester.pump();
          expect(find.byKey(_trustPage), findsOneWidget);
          expect(find.byKey(_trustWait), findsNothing);
          expect(find.byKey(_trustArrow).hitTestable(), findsOneWidget);
          expect(find.text(_trustHeading), findsOneWidget);
          expect(find.text(_trustBody), findsOneWidget);
          expect(find.text(_trustClosing), findsOneWidget);
          expect(find.bySemanticsLabel(_trustBody), findsOneWidget);
          expect(find.byType(ZyraWelcomeLine), findsNothing);
          await tester.tap(find.byKey(_trustArrow));
          await tester.pump();
          expect(find.text('2 / 4'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('trust Back returns to Welcome and Skip advances one page', (
    tester,
  ) async {
    var completed = 0;
    var returnedToProvider = 0;
    await _mount(
      tester,
      reducedMotion: true,
      onContinue: () => completed++,
      onBack: () => returnedToProvider++,
    );
    await _openTrust(tester);
    await tester.tap(find.byKey(_trustBack));
    await tester.pump();
    expect(find.text('Welcome to ZYRA, Amina.'), findsOneWidget);
    expect(find.byKey(_trustPage), findsNothing);
    expect(returnedToProvider, 0);
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_welcome_back')));
    await tester.pump();
    expect(returnedToProvider, 1);
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_skip')));
    await tester.pump();
    expect(find.byKey(_trustPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_skip')));
    await tester.pump();
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_opening_page_2')), findsNothing);
    expect(completed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated trust forward callbacks cannot skip the photos page', (
    tester,
  ) async {
    var completed = 0;
    await _mount(tester, onContinue: () => completed++);
    await _openTrust(tester);
    final action = tester
        .widget<IconButton>(find.byKey(_trustArrow))
        .onPressed!;
    action();
    action();
    action();
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_opening_page_2')), findsNothing);
    expect(completed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('revocation cancels trust actions and does not rearm on return', (
    tester,
  ) async {
    var completed = 0;
    await _mount(tester, onContinue: () => completed++);
    await _openTrust(tester);
    final skip = tester
        .widget<TextButton>(find.byKey(const ValueKey('dev_onboarding_skip')))
        .onPressed!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(_trustPage), findsNothing);
    expect(find.text(_trustBody), findsNothing);
    expect(find.byKey(_trustArrow), findsNothing);
    skip();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpAndSettle();
    expect(find.byKey(_trustPage), findsNothing);
    expect(find.byKey(const ValueKey('dev_opening_page_1')), findsNothing);
    expect(completed, 0);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    (name: 'phone', size: Size(390, 844), scale: 1.0, reduced: false),
    (name: 'phone_large', size: Size(390, 844), scale: 1.4, reduced: false),
    (name: 'compact_large', size: Size(320, 568), scale: 1.4, reduced: true),
  ]) {
    testWidgets('${viewport.name} real-font Welcome and trust stay readable', (
      tester,
    ) async {
      await _mount(
        tester,
        size: viewport.size,
        textScale: viewport.scale,
        reducedMotion: viewport.reduced,
      );
      await _waitForArrow(tester, _welcomeArrow);
      _expectBoundedClaims();
      await _candidate(tester, 'welcome_${viewport.name}');
      final prayer = find.text(
        'May Allah make the path ahead easy for you and guide you towards what is best.',
      );
      await tester.ensureVisible(prayer);
      await tester.pumpAndSettle();
      expect(prayer.hitTestable(), findsOneWidget);
      expect(find.byKey(_welcomeArrow).hitTestable(), findsOneWidget);
      await _candidate(tester, 'welcome_end_${viewport.name}');
      await tester.tap(find.byKey(_welcomeArrow));
      await tester.pumpAndSettle();
      await _candidate(tester, 'trust_${viewport.name}');
      _expectSectionProgress(1);

      for (final key in [_trustHeadingKey, _trustBodyKey, _trustClosingKey]) {
        final text = find.byKey(key);
        await tester.ensureVisible(text);
        await tester.pumpAndSettle();
        expect(text.hitTestable(), findsOneWidget);
        expect(
          tester.widget<Text>(text).style?.fontFamily,
          'PoppinsVerificationIntroAudit',
        );
        final pageRect = tester.getRect(find.byKey(_trustPage));
        final textRect = tester.getRect(text);
        expect(textRect.left, greaterThanOrEqualTo(pageRect.left));
        expect(textRect.right, lessThanOrEqualTo(pageRect.right));
        expect(textRect.top, greaterThanOrEqualTo(pageRect.top));
        expect(textRect.bottom, lessThanOrEqualTo(pageRect.bottom));
        expect(
          textRect.bottom,
          lessThan(tester.getRect(find.byKey(_trustArrow)).top),
        );
      }
      expect(find.byKey(_trustArrow).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _candidate(tester, 'trust_end_${viewport.name}');
      await tester.tap(find.byKey(_trustArrow));
      await tester.pumpAndSettle();
      expect(find.text('2 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('developer denial exposes neither Welcome nor trust', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await _mount(tester);
    expect(find.byKey(_trustPage), findsNothing);
    expect(find.text(_trustBody), findsNothing);
    expect(find.text('Welcome to ZYRA, Amina.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
