// Founder review candidates only. This file never promotes or changes an
// approved baseline. Capture with --update-goldens and
// --dart-define=ZYRA_ONBOARDING_CAPTURE_CANDIDATES=true.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

const _capture = bool.fromEnvironment('ZYRA_ONBOARDING_CAPTURE_CANDIDATES');
const _root = ValueKey('onboarding-study-candidate');
const _candidateDirectory = 'candidates/onboarding_quote_first_2026_10_01';

Future<void> _pumpLab(
  WidgetTester tester,
  ZyraOnboardingDirection direction,
  double textScale,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _root,
        child: DevOnboardingDirectionsScreen(initialDirection: direction),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectReachable(
  WidgetTester tester,
  String key,
  Size viewport, {
  required String reason,
}) {
  final action = find.byKey(ValueKey(key));
  expect(action.hitTestable(), findsOneWidget, reason: reason);
  final rect = tester.getRect(action);
  expect(rect.left, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.right, lessThanOrEqualTo(viewport.width), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(24), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(viewport.height - 24), reason: reason);
  expect(rect.height, greaterThanOrEqualTo(44), reason: reason);
  expect(rect.width, greaterThanOrEqualTo(44), reason: reason);
}

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  await expectLater(
    find.byKey(_root),
    matchesGoldenFile('$_candidateDirectory/$name.png'),
  );
}

Future<void> _revealStory(WidgetTester tester) async {
  for (var stage = 0; stage < 1; stage++) {
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_continue')));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsOnboardingAudit');
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
    final wordmark = FontLoader('SyneOnboardingAudit')
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
    ZyraText.testReadingFontFamily = 'PoppinsOnboardingAudit';
    ZyraText.testWordmarkFontFamily = 'SyneOnboardingAudit';
  });

  setUp(() {
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDevOnboardingInteraction.resetForTesting();
    expect(
      ZyraDevOnboardingInteraction.select(
        ZyraOnboardingAdvanceMode.continueButton,
      ),
      isTrue,
    );
  });

  tearDown(() {
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final viewport in const [
    (size: Size(390, 844), textScale: 1.0, label: 'standard'),
    (size: Size(390, 844), textScale: 1.3, label: 'text_130'),
    (size: Size(320, 568), textScale: 1.4, label: 'compact_140'),
    (size: Size(430, 932), textScale: 1.3, label: 'large_130'),
  ]) {
    for (final direction in ZyraOnboardingDirection.values.skip(1)) {
      testWidgets(
        '${direction.name} four-slide real-font review ${viewport.label}',
        (tester) async {
          tester.view.physicalSize = viewport.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _pumpLab(tester, direction, viewport.textScale);
          for (
            var page = 0;
            page < ZyraOnboardingDirection.storyPageCount;
            page++
          ) {
            final reason = '${direction.name}, ${viewport.label}, page $page';
            await _revealStory(tester);
            expect(
              find
                  .byKey(
                    ValueKey('onboarding-study-scroll-${direction.name}-$page'),
                  )
                  .hitTestable(),
              findsOneWidget,
              reason: reason,
            );
            for (final key in const [
              'dev_onboarding_continue',
              'dev_onboarding_close',
              'dev_onboarding_previous_direction',
              'dev_onboarding_next_direction',
            ]) {
              _expectReachable(tester, key, viewport.size, reason: reason);
            }
            expect(
              find.text('${page + 1} / 4'),
              findsOneWidget,
              reason: reason,
            );
            if (page > 0) {
              _expectReachable(
                tester,
                'dev_onboarding_back',
                viewport.size,
                reason: reason,
              );
            }
            expect(tester.takeException(), isNull, reason: reason);
            await _candidate(
              tester,
              '${direction.name}__page_${page + 1}__${viewport.label}',
            );
            final story = find.byKey(
              ValueKey('onboarding-study-scroll-${direction.name}-$page'),
            );
            // Enlarged-text users can read the entire story vertically while
            // the horizontal page swipe and bottom Continue remain separate.
            final heading = find.byKey(
              ValueKey('onboarding-study-heading-${direction.name}-$page'),
            );
            await tester.ensureVisible(heading);
            await tester.pumpAndSettle();
            expect(heading.hitTestable(), findsOneWidget, reason: reason);
            final lastCopy = find
                .descendant(of: story, matching: find.byType(Text))
                .last;
            await tester.ensureVisible(lastCopy);
            await tester.pumpAndSettle();
            expect(lastCopy.hitTestable(), findsOneWidget, reason: reason);
            _expectReachable(
              tester,
              'dev_onboarding_continue',
              viewport.size,
              reason: reason,
            );
            expect(tester.takeException(), isNull, reason: reason);
            if (page < ZyraOnboardingDirection.storyPageCount - 1) {
              await tester.tap(
                find.byKey(const ValueKey('dev_onboarding_continue')),
              );
              await tester.pumpAndSettle();
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'current welcome and stage real-font review ${viewport.label}',
      (tester) async {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pumpLab(
          tester,
          ZyraOnboardingDirection.current,
          viewport.textScale,
        );
        for (final key in const [
          'dev_onboarding_close',
          'dev_onboarding_previous_direction',
          'dev_onboarding_next_direction',
        ]) {
          _expectReachable(tester, key, viewport.size, reason: viewport.label);
        }
        final welcome = find.byKey(
          const ValueKey('onboarding_welcome_continue'),
        );
        await _candidate(tester, 'current__welcome__${viewport.label}');
        for (var item = 0; item < 4; item++) {
          await tester.tap(
            find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
          );
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(welcome);
        await tester.pumpAndSettle();
        expect(welcome.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(welcome);
        await tester.pumpAndSettle();
        final stage = find.byKey(const ValueKey('onboarding_stage_continue'));
        await tester.ensureVisible(stage);
        await tester.pumpAndSettle();
        expect(stage.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _candidate(tester, 'current__stage__${viewport.label}');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('first-page quote remains readable at compact 2.0× text', (
    tester,
  ) async {
    const viewport = Size(320, 568);
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpLab(tester, ZyraOnboardingDirection.atoms, 2.0);
    await _revealStory(tester);
    expect(find.text('1 / 4'), findsOneWidget);
    final story = find.byKey(const ValueKey('onboarding-study-scroll-atoms-0'));
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: story, matching: find.byType(Scrollable)).first,
        )
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    final attribution = find.byKey(
      const ValueKey('onboarding-study-attribution-atoms-0'),
    );
    await tester.ensureVisible(attribution);
    await tester.pumpAndSettle();
    expect(attribution.hitTestable(), findsOneWidget);
    final explanation = find.text('A principle that helped shape ZYRA.');
    await tester.ensureVisible(explanation);
    await tester.pumpAndSettle();
    expect(explanation.hitTestable(), findsOneWidget);
    _expectReachable(
      tester,
      'dev_onboarding_continue',
      viewport,
      reason: 'Atoms page 1 at compact 2.0×',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Atoms standard closing lines remain above page controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpLab(tester, ZyraOnboardingDirection.atoms, 1.0);
    await _revealStory(tester);
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_continue')));
    await tester.pumpAndSettle();
    await _revealStory(tester);
    for (final closing in const [
      'Built for Muslims serious about marriage.',
      'You see the compatibility result—not each other’s private answers.',
      'Support beside you, every step of the way.',
    ]) {
      final text = find.text(closing);
      expect(text, findsOneWidget);
      expect(
        tester.getRect(text).bottom,
        lessThan(
          tester
              .getRect(find.byKey(const ValueKey('dev_onboarding_page_count')))
              .top,
        ),
      );
      if (closing != 'Support beside you, every step of the way.') {
        await tester.tap(find.byKey(const ValueKey('dev_onboarding_continue')));
        await tester.pumpAndSettle();
        await _revealStory(tester);
      }
    }
  });
}
