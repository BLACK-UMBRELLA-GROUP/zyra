// New local candidates only. No approved baselines, member or Storage calls.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import '../support/queue44_signup_flow_driver.dart';

const _capture = bool.fromEnvironment('ZYRA_SIGNUP_FIRST_PHOTO_CAPTURE');
const _boundary = ValueKey('signup-first-photo-candidate');
const _localPhoto =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

Future<void> _tap(WidgetTester tester, String key) async {
  final action = find.byKey(ValueKey(key));
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsFirstPhotoAudit');
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
    final wordmark = FontLoader('SyneFirstPhotoAudit')
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
    ZyraText.testReadingFontFamily = 'PoppinsFirstPhotoAudit';
    ZyraText.testWordmarkFontFamily = 'SyneFirstPhotoAudit';
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  setUp(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.resetForAccountChange();
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    AppState.instance.resetForAccountChange();
  });

  for (final layout in [
    (name: 'phone', size: const Size(390, 844), scale: 1.0),
    (name: 'compact140', size: const Size(320, 568), scale: 1.4),
    (name: 'compact200', size: const Size(320, 568), scale: 2.0),
  ]) {
    testWidgets('first required photo real fonts ${layout.name}', (
      tester,
    ) async {
      tester.view.physicalSize = layout.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(layout.scale),
              disableAnimations: true,
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: OnboardingPreviewStyle(
              directionName: 'luma',
              child: ZyraOnboardingArrowScope(
                enabled: true,
                child: RepaintBoundary(key: _boundary, child: child!),
              ),
            ),
          ),
          home: OnboardingFlow(
            devPreview: true,
            welcomeName: 'Amina',
            photoRunner: (context, remaining, progress) async =>
                const ZyraPhotoBatchResult.added([_localPhoto]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('First, your account.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (_capture) await _candidate(tester, '${layout.name}_account_intro');
      await tester.ensureVisible(
        find.byKey(const ValueKey('onboarding_stage_continue')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding_stage_continue')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      if (_capture) {
        await _candidate(tester, '${layout.name}_account_intro_action');
      }
      await _tap(tester, 'onboarding_stage_continue');
      for (var index = 0; index < 3; index++) {
        await advanceSignupQuestionFromCode(tester, installPhotoFixture: false);
      }
      expect(
        find.byKey(const ValueKey('signup_first_photo_question')),
        findsOneWidget,
      );
      expect(find.text('QUESTION 4 OF 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (_capture) await _candidate(tester, '${layout.name}_empty');
      await tester.ensureVisible(
        find.byKey(const ValueKey('signup_first_photo_choose')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('signup_first_photo_choose')).hitTestable(),
        findsOneWidget,
      );
      if (_capture) await _candidate(tester, '${layout.name}_empty_action');
      await _tap(tester, 'signup_first_photo_choose');
      expect(
        find.byKey(const ValueKey('signup_first_photo_preview')),
        findsOneWidget,
      );
      expect(find.text('Choose a different photo'), findsOneWidget);
      final advance = tester.widget<ZyraOnboardingArrowAction>(
        find.byKey(const ValueKey('onboarding_continue')),
      );
      expect(advance.active, isTrue);
      expect(tester.takeException(), isNull);
      final questionScroll = find.descendant(
        of: find.byKey(const ValueKey('signup_first_photo_question')),
        matching: find.byType(Scrollable),
      );
      tester.state<ScrollableState>(questionScroll.first).position.jumpTo(0);
      await tester.pumpAndSettle();
      if (_capture) await _candidate(tester, '${layout.name}_selected');
      await tester.ensureVisible(
        find.byKey(const ValueKey('signup_first_photo_choose')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('signup_first_photo_choose')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('onboarding_continue')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      if (_capture) await _candidate(tester, '${layout.name}_selected_action');
    });
  }
}

Future<void> _candidate(WidgetTester tester, String name) async {
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
        matchesGoldenFile('candidates/signup_first_photo_2026_10_04/$name.png'),
      ),
    );
  } finally {
    image?.dispose();
  }
}
