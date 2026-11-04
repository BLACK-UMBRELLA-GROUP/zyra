// Candidate-only real fonts. No approved goldens or live signup are changed.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/queue44_onboarding_story_fixture.dart';
import '../support/queue44_gold_fixture.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';

const _capture = bool.fromEnvironment('ZYRA_PURPOSE_LED_OPENING_CAPTURE');
const _boundary = ValueKey('purpose-led-opening-candidate');

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsOpeningReview');
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
    final logo = FontLoader('SyneOpeningReview')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), logo.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsOpeningReview';
    ZyraText.testWordmarkFontFamily = 'SyneOpeningReview';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });
  for (final compact in [false, true]) {
    testWidgets(
      'purpose-led opening real fonts ${compact ? 'compact140' : 'phone'}',
      (tester) async {
        final size = compact ? const Size(320, 568) : const Size(390, 844);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ZyraDeveloperAccess.setAuthorizedForTesting(true);
        ZyraDevOnboardingGoldDesign.resetForTesting();
        ZyraDevOnboardingGoldMotion.select(
          ZyraOnboardingGoldMotion.pageEntrance,
        );
        addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                textScaler: TextScaler.linear(compact ? 1.4 : 1),
                disableAnimations: true,
              ),
              child: RepaintBoundary(key: _boundary, child: child!),
            ),
            home: OnboardingIntroductionFixture(
              direction: ZyraOnboardingDirection.luma,
              welcomeName: 'Shakeel Ahmad',
              onContinue: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final suffix = compact ? 'compact140' : 'phone';
        await _candidate(tester, 'welcome_$suffix');
        await tester.ensureVisible(
          find.text(
            'May Allah make the path ahead easy for you and guide you towards what is best.',
          ),
        );
        await tester.pumpAndSettle();
        await _candidate(tester, 'welcome_end_$suffix');
        await tester.tap(
          find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
        );
        await tester.pumpAndSettle();
        _expectProgress(tester, 1);
        final trustNext = find.byKey(
          const ValueKey('dev_onboarding_verification_continue'),
        );
        expect(tester.widget<IconButton>(trustNext).onPressed, isNotNull);
        expect(find.byType(ZyraOnboardingArrowAction), findsNothing);
        await _candidate(tester, 'verification_$suffix');
        await tester.ensureVisible(
          find.byKey(const ValueKey('dev_onboarding_verification_closing')),
        );
        await tester.pumpAndSettle();
        await _candidate(tester, 'verification_end_$suffix');
        await tester.tap(
          find.byKey(const ValueKey('dev_onboarding_verification_continue')),
        );
        await tester.pumpAndSettle();
        for (var page = 1; page <= 3; page++) {
          expect(
            find.byKey(ValueKey('dev_opening_body_$page')),
            findsOneWidget,
          );
          _expectProgress(tester, page + 1);
          expect(tester.takeException(), isNull);
          await _candidate(tester, 'theme_${page}_$suffix');
          if (page == 1) {
            expect(
              tester
                  .widget<Text>(
                    find.byKey(const ValueKey('dev_opening_body_1')),
                  )
                  .data,
              'ZYRA introduces you through photos first, so you can see who you’re drawn to. When you both choose to connect, you can get to know the person beyond the first impression.',
            );
            await tester.ensureVisible(
              find.byKey(const ValueKey('dev_opening_body_1')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await _candidate(tester, 'photos_body_$suffix');
            expect(
              find.byKey(const ValueKey('dev_opening_quote_toggle')),
              findsNothing,
            );
            setOpeningQuoteFixtureFromCode(tester, true);
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.byKey(const ValueKey('dev_opening_quote')),
            );
            await tester.pumpAndSettle();
            await _candidate(tester, 'photos_quote_$suffix');
          }
          if (page < 3) {
            await tester.tap(find.byKey(const ValueKey('dev_opening_next')));
            await tester.pumpAndSettle();
          }
        }
        expect(
          find
              .byKey(const ValueKey('dev_onboarding_story_continue'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}

void _expectProgress(WidgetTester tester, int page) {
  expect(find.text('$page / 4'), findsOneWidget);
  for (var index = 0; index < 4; index++) {
    final dot = find.byKey(ValueKey('dev_onboarding_story_dot_$index'));
    expect(dot, findsOneWidget);
    final semantics = tester.widget<Semantics>(dot).properties;
    expect(semantics.selected, index == page - 1);
    expect(
      semantics.value,
      index < page - 1
          ? 'Completed'
          : index == page - 1
          ? 'Current'
          : 'Upcoming',
    );
    final decoration =
        tester
                .widget<Container>(
                  find.descendant(of: dot, matching: find.byType(Container)),
                )
                .decoration!
            as BoxDecoration;
    expect(
      decoration.color,
      index <= page - 1
          ? ZyraColors.journeyGold
          : ZyraColors.foreground.withValues(alpha: .25),
    );
  }
  expect(
    find.byKey(const ValueKey('dev_onboarding_story_dot_4')),
    findsNothing,
  );
}

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.runAsync(
      () => expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile('candidates/four_slide_intro_2026_10_04/$name.png'),
      ),
    );
  } finally {
    image?.dispose();
  }
}
