import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_full_profile_preview.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';
import 'visual/baseline_capture_support.dart';

const _captureDirectory = String.fromEnvironment('ZYRA_LINE135_CAPTURE_DIR');
const _captureRoot = ValueKey('line135_capture_root');

const _profile = SeekerProfile(
  id: 'draft-sara',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  publicNationality: 'Pakistani',
  publicEthnicity: 'Pakistani',
  gender: 'female',
  photos: ['first', 'second'],
  seekerPlan: ZyraPlan.one,
  mainGuardianRelationship: 'Father',
);

Future<void> _mount(
  WidgetTester tester,
  ZyraFullProfileSituation situation, {
  bool Function()? canAct,
  VoidCallback? onAction,
  VoidCallback? onSecondary,
  ValueChanged<ZyraFullProfileOption>? onOption,
  double width = 430,
  double height = 932,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(textScale),
        ),
        child: RepaintBoundary(key: _captureRoot, child: child!),
      ),
      home: Scaffold(
        body: ZyraFullProfilePreview(
          key: ValueKey((situation, width, height, textScale)),
          profile: _profile,
          situation: situation,
          introductionByline: 'Hassan · Father',
          canAct: canAct ?? () => true,
          photoBuilder:
              (
                context,
                source, {
                required width,
                required height,
                required alignment,
              }) => ColoredBox(
                key: ValueKey('photo_$source'),
                color: Colors.teal,
              ),
          onAction: onAction,
          onSecondary: onSecondary,
          onOption: onOption,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  expect(_captureDirectory, isNotEmpty);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureRoot),
    );
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_captureDirectory/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_captureDirectory.isNotEmpty) {
    setUpAll(() => baselineSetUp(evidenceRoot: null));
    tearDownAll(baselineTearDown);
  }
  final originalFonts = ZyraText.useTestFontStubs;
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = originalFonts);

  testWidgets('Journey title, shared card and fixed action stay visible', (
    tester,
  ) async {
    var continued = 0;
    await _mount(
      tester,
      ZyraFullProfileSituation.journey,
      onAction: () => continued++,
    );
    expect(find.text('Journey'), findsOneWidget);
    expect(find.byType(ZyraProfileDetailsPage), findsOneWidget);
    expect(find.text('Main Guardian · Father'), findsOneWidget);
    expect(find.text('Compatibility score'), findsOneWidget);
    expect(find.text('Sara Ahmed'), findsOneWidget);
    expect(find.text('Continue Journey'), findsOneWidget);
    expect(find.text('Request a Journey'), findsNothing);
    await tester.tap(find.text('Continue Journey'));
    expect(continued, 1);
  });

  testWidgets('card taps step details through photos and wrap; no swipe', (
    tester,
  ) async {
    await _mount(tester, ZyraFullProfileSituation.general);
    expect(find.byType(ZyraProfileDetailsPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('full_profile_card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo_first')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('full_profile_card')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo_first')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('full_profile_card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo_second')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('full_profile_card')));
    await tester.pumpAndSettle();
    expect(find.byType(ZyraProfileDetailsPage), findsOneWidget);
  });

  testWidgets('Introduction keeps the source and both caller actions', (
    tester,
  ) async {
    var requested = 0, declined = 0;
    await _mount(
      tester,
      ZyraFullProfileSituation.introduction,
      onAction: () => requested++,
      onSecondary: () => declined++,
    );
    expect(find.text('Introduction'), findsOneWidget);
    expect(find.text('Put forward by Hassan · Father'), findsOneWidget);
    await tester.tap(find.text('Decline'));
    await tester.tap(find.text('Request a Journey'));
    expect((requested, declined), (1, 1));
  });

  testWidgets('options choose Hide, Report and Block only while current', (
    tester,
  ) async {
    final selected = <ZyraFullProfileOption>[];
    var current = true;
    await _mount(
      tester,
      ZyraFullProfileSituation.general,
      canAct: () => current,
      onOption: selected.add,
    );
    await tester.tap(find.byKey(const ValueKey('full_profile_options')));
    await tester.pumpAndSettle();
    expect(find.text('Hide Sara'), findsOneWidget);
    expect(find.text('Report Sara'), findsOneWidget);
    expect(find.text('Block Sara'), findsOneWidget);
    await tester.tap(find.text('Block Sara'));
    await tester.pumpAndSettle();
    expect(selected, [ZyraFullProfileOption.block]);
    current = false;
    await _mount(
      tester,
      ZyraFullProfileSituation.general,
      canAct: () => current,
      onOption: selected.add,
    );
    expect(
      find.byKey(const ValueKey('full_profile_unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('375 point Larger Text keeps actions in the viewport', (
    tester,
  ) async {
    await _mount(
      tester,
      ZyraFullProfileSituation.received,
      width: 375,
      height: 667,
      textScale: 1.3,
    );
    expect(find.text('Journey request'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  if (_captureDirectory.isNotEmpty) {
    testWidgets('capture the locked full-profile states at 430 and 375', (
      tester,
    ) async {
      await _mount(
        tester,
        ZyraFullProfileSituation.journey,
        onAction: () {},
        onOption: (_) {},
      );
      await _capture(tester, 'fp01_journey_430');
      await tester.tap(find.byKey(const ValueKey('full_profile_options')));
      await _capture(tester, 'fp04_options_430');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await _mount(
        tester,
        ZyraFullProfileSituation.received,
        onAction: () {},
        onSecondary: () {},
      );
      await _capture(tester, 'fp02_received_430');
      await _mount(tester, ZyraFullProfileSituation.sent);
      await _capture(tester, 'fp03_sent_430');
      await _mount(
        tester,
        ZyraFullProfileSituation.introduction,
        onAction: () {},
        onSecondary: () {},
      );
      await _capture(tester, 'fp06_introduction_430');
      await tester.tap(find.byKey(const ValueKey('full_profile_card')));
      await _capture(tester, 'fp07_photo_430');
      await _mount(
        tester,
        ZyraFullProfileSituation.introduction,
        width: 375,
        height: 812,
        textScale: 1.3,
        onAction: () {},
        onSecondary: () {},
      );
      final action = tester.getRect(
        find.byKey(const ValueKey('full_profile_action_Request_a_Journey')),
      );
      final actionText = tester.getRect(find.text('Request a Journey'));
      expect(actionText.top, greaterThanOrEqualTo(action.top + 2));
      expect(actionText.bottom, lessThanOrEqualTo(action.bottom - 2));
      await _capture(tester, 'introduction_375_large');
    });
  }
}
