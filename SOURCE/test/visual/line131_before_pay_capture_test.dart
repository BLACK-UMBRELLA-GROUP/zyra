import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_guardian_before_pay_preview.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_family_sheet.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'baseline_capture_support.dart';

const _captureDirectory = String.fromEnvironment('ZYRA_LINE131_CAPTURE_DIR');
const _boundary = ValueKey('line131-before-pay-boundary');

Future<void> _capture(WidgetTester tester, String state) async {
  if (_captureDirectory.isEmpty) return;
  final oldShadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    await tester.pump();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundary),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        expect(image.width, 1290);
        expect(image.height, 2796);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$_captureDirectory/$state.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
    });
  } finally {
    debugDisableShadows = oldShadows;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  testWidgets('LOCK38 b07 and b08 keep the tick and action on a full phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notices = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: ZyraText.testReadingFontFamily),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(430, 932),
            padding: EdgeInsets.only(top: 59, bottom: 34),
          ),
          child: RepaintBoundary(
            key: _boundary,
            child: ZyraGuardianBeforePayPreview(
              seekerFirstName: 'Adam',
              canAct: () => true,
              onNotice: notices.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final button = find.byKey(const ValueKey('guardian-before-pay-continue'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await _capture(tester, 'b07_before_you_pay');

    await tester.tap(
      find.byKey(const ValueKey('guardian-before-pay-understand')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'b08_before_you_pay_ticked');
    expect(notices, isEmpty);
  });

  testWidgets('LOCK38 Unlocks purchase area fits a full phone', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: ZyraText.testReadingFontFamily),
        home: Scaffold(
          body: RepaintBoundary(
            key: _boundary,
            child: ColoredBox(
              color: ZyraColors.ivoryTop,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ZyraDraftCompatibilityStorePresentation(
                    balance: 1,
                    isSeekerOne: true,
                    founderPreview: true,
                    canAct: () => true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, 'b02_unlocks_store');
  });

  testWidgets('LOCK38 Family price sheet disclosure fits a full phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: ZyraText.testReadingFontFamily),
        home: Scaffold(
          backgroundColor: ZyraColors.ivoryTop,
          body: RepaintBoundary(
            key: _boundary,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ZyraGuardianFamilySheet(
                guardianName: 'Ibrahim',
                canAct: () => true,
                invited: false,
                familyState: ZyraGuardianFamilyState.noFamily,
                seekers: 1,
                guardians: 1,
                onInvite: () {},
                onCancelInvite: () {},
                onClose: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('guardian-family-introduction-primary')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('£49.98 a month, renewing'), findsOneWidget);
    await _capture(tester, 'b03_family_price_sheet');
  });

  for (final basic in [true, false]) {
    testWidgets('LOCK38 signup ${basic ? 'Basic' : 'One'} disclosure fits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = ZyraSignupPreviewController()
        ..seedSetup(guardian: false, verified: true)
        ..setMembershipBasic(basic)
        ..setStep(ZyraSignupStep.membership);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: ZyraText.testReadingFontFamily),
          home: Scaffold(
            body: RepaintBoundary(
              key: _boundary,
              child: ZyraSignupPreview(
                controller: controller,
                canAct: () => true,
                preferencesBuilder: (_) => const SizedBox.shrink(),
                onPause: () {},
                onEnter: () {},
                samplePhotos: const [],
                ownCode: 'ZYRA-7Q4M-K2XD-9P3L-W8RT-F6NB',
                onShareCode: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final printTop = tester.getTopLeft(
        find.byKey(
          ValueKey(
            'purchase-fine-print-${basic ? 'seekerBasic' : 'seekerOne'}',
          ),
        ),
      );
      final buttonTop = tester.getTopLeft(
        find.byKey(const ValueKey('signup_membership_checkout')),
      );
      expect(printTop.dy, lessThan(buttonTop.dy));
      await _capture(tester, basic ? 'b04_signup_basic' : 'b05_signup_one');
    });
  }
}
