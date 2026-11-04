// Candidate-only phone captures of the four-card onboarding footer after
// removing redundant gesture instructions. Never update approved baselines.
// Capture with --update-goldens and
// --dart-define=ZYRA_ONBOARDING_HINT_CLEANUP_CAPTURE_CANDIDATES=true.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/queue44_onboarding_story_fixture.dart';
import '../support/queue44_gold_fixture.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';

const _capture = bool.fromEnvironment(
  'ZYRA_ONBOARDING_HINT_CLEANUP_CAPTURE_CANDIDATES',
);
const _directory = 'candidates/onboarding_hint_cleanup_2026_10_01';
const _boundary = ValueKey('onboarding-hint-cleanup-candidate');

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  await expectLater(
    find.byKey(_boundary),
    matchesGoldenFile('$_directory/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsOnboardingHintAudit');
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
    final wordmark = FontLoader('SyneOnboardingHintAudit')
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
    ZyraText.testReadingFontFamily = 'PoppinsOnboardingHintAudit';
    ZyraText.testWordmarkFontFamily = 'SyneOnboardingHintAudit';
  });

  setUp(() {
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  testWidgets('current card three keeps a clean footer after Back and return', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: child!,
        ),
        home: RepaintBoundary(
          key: _boundary,
          child: ZyraOnboardingArrowScope(
            enabled: true,
            child: OnboardingIntroductionFixture(
              direction: ZyraOnboardingDirection.luma,
              onContinue: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final prelude = find.byKey(
      const ValueKey('dev_onboarding_welcome_prelude'),
    );
    for (var line = 0; line < 2; line++) {
      await tester.tap(prelude);
      await tester.pumpAndSettle();
    }
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
    );
    await tester.pumpAndSettle();
    final trust = find.byKey(
      const ValueKey('dev_onboarding_verification_intro'),
    );
    expect(trust.hitTestable(), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_verification_continue')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_opening_page_1')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('dev_opening_next')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_opening_page_2')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_onboarding_skip')), findsNothing);
    expect(find.text('Tap the page to continue reading'), findsNothing);
    expect(find.text('Swipe right for the next page'), findsNothing);
    expect(tester.takeException(), isNull);
    await _candidate(tester, 'luma_card_3_full__phone');
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_story_back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_opening_page_1')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('dev_opening_next')));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('Tap the page to continue reading'), findsNothing);
    expect(find.text('Swipe right for the next page'), findsNothing);
    expect(tester.takeException(), isNull);
    await _candidate(tester, 'luma_card_3_return__phone');
  });
}
