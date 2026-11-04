// Fresh local evidence only. Never update approved baselines or call Storage.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import '../support/queue44_signup_flow_driver.dart';

const _capture = bool.fromEnvironment('ZYRA_GUARDIAN_FIRST_PHOTO_CAPTURE');
const _captureDirectory = String.fromEnvironment(
  'ZYRA_GUARDIAN_FIRST_PHOTO_CAPTURE_DIR',
);
const _boundary = ValueKey('guardian-signup-first-photo-candidate');
const _question = ValueKey('guardian_signup_first_photo_question');
const _choose = ValueKey('signup_first_photo_choose');
const _continue = ValueKey('wali_onboarding_continue');
const _localPhoto =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

Future<void> _tap(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _top(WidgetTester tester) async {
  final scroll = find.descendant(
    of: find.byKey(_question),
    matching: find.byType(Scrollable),
  );
  tester.state<ScrollableState>(scroll.first).position.jumpTo(0);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsGuardianFirstPhotoAudit');
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
    final wordmark = FontLoader('SyneGuardianFirstPhotoAudit')
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
    ZyraText.testReadingFontFamily = 'PoppinsGuardianFirstPhotoAudit';
    ZyraText.testWordmarkFontFamily = 'SyneGuardianFirstPhotoAudit';
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
    testWidgets('Guardian required photo real fonts ${layout.name}', (
      tester,
    ) async {
      tester.view.physicalSize = layout.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var photoCalls = 0;
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
          home: WaliOnboardingFlow(
            devPreview: true,
            photoRunner: (context, remaining, progress) async {
              photoCalls++;
              expect(remaining, 1);
              return const ZyraPhotoBatchResult.added([_localPhoto]);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var question = 0; question < 4; question++) {
        await advanceSignupQuestionFromCode(tester, installPhotoFixture: false);
      }
      expect(find.byKey(_question), findsOneWidget);
      expect(find.text('QUESTION 5 OF 5'), findsOneWidget);
      expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
      expect(
        tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await _top(tester);
      if (_capture) await _candidate(tester, '${layout.name}_empty');
      await tester.ensureVisible(find.byKey(_choose));
      await tester.pumpAndSettle();
      expect(find.byKey(_choose).hitTestable(), findsOneWidget);
      expect(
        tester.getSize(find.byKey(_choose)).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
      if (_capture) await _candidate(tester, '${layout.name}_empty_choose');
      await _tap(tester, _choose);
      expect(photoCalls, 1);
      expect(
        find.byKey(const ValueKey('signup_first_photo_preview')),
        findsOneWidget,
      );
      expect(find.text('Choose a different photo'), findsOneWidget);
      expect(
        tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
        isTrue,
      );
      expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await _top(tester);
      if (_capture) await _candidate(tester, '${layout.name}_selected');
      await tester.ensureVisible(find.byKey(_choose));
      await tester.pumpAndSettle();
      expect(find.byKey(_choose).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (_capture) await _candidate(tester, '${layout.name}_selected_choose');
      await tester.ensureVisible(find.byKey(_continue));
      await tester.pumpAndSettle();
      expect(find.byKey(_continue).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (_capture) {
        await _candidate(tester, '${layout.name}_selected_continue');
      }
      await _tap(tester, _continue);
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(find.byKey(_question), findsNothing);
      expect(photoCalls, 1);
      expect(
        AppState.instance.photos,
        isEmpty,
        reason:
            'A local Guardian fixture is not a new public Seeker photo projection',
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _candidate(WidgetTester tester, String name) async {
  expect(
    autoUpdateGoldenFiles,
    isTrue,
    reason: 'New capture evidence requires the explicit capture/update flags',
  );
  expect(_captureDirectory, isNotEmpty);
  expect(
    _captureDirectory.startsWith('/'),
    isTrue,
    reason: 'Evidence must name a task-owned absolute output directory',
  );
  final output = File('$_captureDirectory/$name.png');
  expect(
    output.existsSync(),
    isFalse,
    reason: 'Never overwrite an earlier candidate or approved baseline',
  );
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(data, isNotNull);
    await tester.runAsync(() async {
      await output.parent.create(recursive: true);
      await output.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    });
  } finally {
    image?.dispose();
  }
}
