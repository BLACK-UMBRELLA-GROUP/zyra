// Founder review candidates only. These images are not approved baselines.
// Staged-reveal candidates use new directories so earlier comparison
// captures remain intact. Capture with --update-goldens and
// --dart-define=ZYRA_ONBOARDING_TRANSITION_CAPTURE_CANDIDATES=true.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_transition.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

const _capture = bool.fromEnvironment(
  'ZYRA_ONBOARDING_TRANSITION_CAPTURE_CANDIDATES',
);
const _root = ValueKey('onboarding-transition-candidate');
const _directory = 'candidates/onboarding_card_tilt_content_only_2026_10_01';
const _storyDirectory = 'candidates/onboarding_staged_intro_2026_10_01';

Future<void> _revealStory(WidgetTester tester, int page) async {
  final story = find.byKey(ValueKey('onboarding-study-scroll-luma-$page'));
  for (var stage = 0; stage < 1; stage++) {
    await tester.tap(story);
    await tester.pumpAndSettle();
  }
}

Future<void> _captureFrame(WidgetTester tester, String name) async {
  if (!_capture ||
      !name.startsWith('${ZyraOnboardingPageTransition.cardTilt.name}__')) {
    return;
  }
  await expectLater(
    find.byKey(_root),
    matchesGoldenFile('$_directory/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsTransitionAudit');
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
    final wordmark = FontLoader('SyneTransitionAudit')
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
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsTransitionAudit';
    ZyraText.testWordmarkFontFamily = 'SyneTransitionAudit';
  });

  setUp(() {
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDevOnboardingTransition.resetForTesting();
  });

  tearDown(() {
    ZyraDevOnboardingTransition.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  testWidgets('Luma arrow-default four-page standalone candidate at 390×844', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: child!,
        ),
        home: RepaintBoundary(
          key: _root,
          child: ZyraOnboardingArrowScope(
            enabled: true,
            child: const DevOnboardingDirectionsScreen(
              initialDirection: ZyraOnboardingDirection.luma,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var page = 0; page < ZyraOnboardingDirection.storyPageCount; page++) {
      expect(find.text('${page + 1} / 4'), findsOneWidget);
      expect(
        find
            .byKey(ValueKey('onboarding-study-scroll-luma-$page'))
            .hitTestable(),
        findsOneWidget,
      );
      await _revealStory(tester, page);
      if (_capture) {
        await expectLater(
          find.byKey(_root),
          matchesGoldenFile(
            '$_storyDirectory/luma__page_${page + 1}__standard.png',
          ),
        );
      }
      if (page < ZyraOnboardingDirection.storyPageCount - 1) {
        await tester.tap(
          find.byKey(ValueKey('onboarding-study-scroll-luma-$page')),
        );
        await tester.pumpAndSettle();
      } else {
        expect(
          find.byKey(const ValueKey('dev_onboarding_continue')),
          findsOneWidget,
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  for (final transition in ZyraOnboardingPageTransition.values) {
    testWidgets('${transition.label} mid-frame review at 390×844', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      expect(ZyraDevOnboardingTransition.select(transition), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: _root,
            child: ZyraOnboardingArrowScope(
              enabled: true,
              child: const DevOnboardingDirectionsScreen(
                initialDirection: ZyraOnboardingDirection.luma,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 4'), findsOneWidget);
      await _revealStory(tester, 0);
      await _captureFrame(tester, '${transition.name}__first');

      await tester.tapAt(const Offset(200, 250));
      await tester.pump();
      await tester.pump(
        Duration(milliseconds: transition.duration.inMilliseconds ~/ 4),
      );
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, '${transition.name}__first_to_second_early');
      await tester.pump(
        Duration(milliseconds: transition.duration.inMilliseconds ~/ 4),
      );
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, '${transition.name}__first_to_second_mid');
      await tester.pump(
        Duration(milliseconds: transition.duration.inMilliseconds ~/ 4),
      );
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, '${transition.name}__first_to_second_late');

      await tester.pumpAndSettle();
      expect(find.text('2 / 4'), findsOneWidget);
      await _revealStory(tester, 1);
      if (transition == ZyraOnboardingPageTransition.cardTilt) {
        await tester.tap(find.byKey(const ValueKey('dev_onboarding_back')));
        await tester.pump();
        await tester.pump(
          Duration(milliseconds: transition.duration.inMilliseconds ~/ 4),
        );
        expect(tester.takeException(), isNull);
        await _captureFrame(
          tester,
          '${transition.name}__second_to_first_early',
        );
        await tester.pump(
          Duration(milliseconds: transition.duration.inMilliseconds ~/ 4),
        );
        expect(tester.takeException(), isNull);
        await _captureFrame(tester, '${transition.name}__second_to_first_mid');
        await tester.pump(
          Duration(milliseconds: transition.duration.inMilliseconds ~/ 4),
        );
        expect(tester.takeException(), isNull);
        await _captureFrame(tester, '${transition.name}__second_to_first_late');
        await tester.pumpAndSettle();
        expect(find.text('1 / 4'), findsOneWidget);
        await tester.tapAt(const Offset(200, 250));
        await tester.pumpAndSettle();
        expect(find.text('2 / 4'), findsOneWidget);
      }
      await tester.tapAt(const Offset(200, 250));
      await tester.pump();
      await tester.pump(
        Duration(milliseconds: transition.duration.inMilliseconds ~/ 2),
      );
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, '${transition.name}__second_to_third_mid');

      await tester.pumpAndSettle();
      expect(find.text('3 / 4'), findsOneWidget);
      await _revealStory(tester, 2);
      await tester.tap(
        find.byKey(const ValueKey('onboarding-study-scroll-luma-2')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, '${transition.name}__third_to_fourth_mid');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();
      expect(find.text('4 / 4'), findsOneWidget);
      await _revealStory(tester, 3);
      await _captureFrame(tester, '${transition.name}__fourth');
      await tester.tap(find.byKey(const ValueKey('dev_onboarding_back')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, '${transition.name}__fourth_to_third_early');
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, '${transition.name}__fourth_to_third_mid');
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, '${transition.name}__fourth_to_third_late');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('3 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
