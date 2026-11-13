import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_confirm_sheet.dart';
import 'package:zyra/widgets/zyra_developer_panel.dart';

const _captureDirectory = String.fromEnvironment('ZYRA_LOCK31_CAPTURE_DIR');
const _boundary = ValueKey('lock31_capture_boundary');
const _email =
    'founder'
    '@'
    'example.test';

Finder _key(String name) => find.byKey(ValueKey('dev_$name'));

const _real = ZyraDeveloperPanelValues(
  active: 0,
  ended: 0,
  received: 0,
  sent: 0,
  past: ZyraDeveloperPast.none,
  introductions: 0,
);

Future<void> _mount(
  WidgetTester tester, {
  required int places,
  required ValueNotifier<ZyraDeveloperPanelValues> values,
  required List<String> changes,
  double width = 430,
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 932);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(platform: TargetPlatform.iOS),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          ),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: ZyraColors.ivoryTop,
          body: Builder(
            builder: (context) => SafeArea(
              child: TextButton(
                child: Text('My ZYRA', style: ZyraText.pageTitle()),
                onPressed: () => Navigator.of(context).push(
                  zyraDeveloperPanelRoute(
                    context,
                    email: _email,
                    planName: places == 1 ? 'Seeker Basic' : 'Seeker One',
                    journeyPlaces: places,
                    values: values,
                    onActive: (value) => changes.add('active $value'),
                    onEnded: (value) => changes.add('ended $value'),
                    onReceived: (value) => changes.add('received $value'),
                    onSent: (value) => changes.add('sent $value'),
                    onPast: (value) => changes.add('past ${value.name}'),
                    onIntroductions: (value) =>
                        changes.add('introductions $value'),
                    onClear: () {
                      changes.add('clear');
                      values.value = _real;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _open(tester);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('My ZYRA'));
  await tester.pumpAndSettle();
  expect(_key('panel'), findsOneWidget);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$_captureDirectory/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('ZYRALock31Poppins');
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'SemiBold']) {
      loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await loader.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'ZYRALock31Poppins';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  testWidgets('Basic uses the real plan, caps Active and resets in place', (
    tester,
  ) async {
    final values = ValueNotifier(_real);
    addTearDown(values.dispose);
    final changes = <String>[];
    await _mount(tester, places: 1, values: values, changes: changes);
    expect(find.textContaining('$_email · Seeker Basic'), findsOneWidget);
    expect(find.text('Seeker Basic has 1 place'), findsOneWidget);
    expect(tester.widget<TextButton>(_key('active_2')).onPressed, isNull);
    expect(tester.widget<TextButton>(_key('active_3')).onPressed, isNull);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      expect(find.bySemanticsLabel('Active Journeys 0'), findsOneWidget);
      expect(find.bySemanticsLabel('Active Journeys 3'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
    for (final key in [
      'active_1',
      'ended_3',
      'received_1',
      'sent_3',
      'past_2',
      'introductions_2',
    ]) {
      await tester.tap(_key(key));
      await tester.pump();
    }
    expect(changes, [
      'active 1',
      'ended 3',
      'received 1',
      'sent 3',
      'past samePerson',
      'introductions 2',
    ]);
    values.value = const ZyraDeveloperPanelValues(
      active: 1,
      ended: 3,
      received: 1,
      sent: 3,
      past: ZyraDeveloperPast.samePerson,
      introductions: 2,
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'lock31_developer_basic');
    await tester.tap(_key('clear'));
    await tester.pump();
    expect(changes.last, 'clear');
    expect(values.value, _real);
    expect(find.text('Sample data cleared.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Sample data cleared.'), findsNothing);
    await tester.tap(_key('done'));
    await tester.pumpAndSettle();
    expect(_key('panel'), findsNothing);
  });

  testWidgets('One permits 3 and closes by backdrop or swipe', (tester) async {
    final values = ValueNotifier(_real);
    addTearDown(values.dispose);
    final changes = <String>[];
    await _mount(tester, places: 3, values: values, changes: changes);
    expect(find.text('Seeker One has 3 places'), findsOneWidget);
    await tester.tap(_key('active_3'));
    await tester.pumpAndSettle();
    expect(changes, ['active 3']);
    await _capture(tester, 'lock31_developer_one');
    await tester.tapAt(const Offset(215, 90));
    await tester.pumpAndSettle();
    expect(_key('panel'), findsNothing);
    await _open(tester);
    await tester.drag(find.text('Developer'), const Offset(0, 420));
    await tester.pumpAndSettle();
    expect(_key('panel'), findsNothing);
  });

  testWidgets(
    'large text fits a compact phone and the last control is reachable',
    (tester) async {
      final values = ValueNotifier(_real);
      addTearDown(values.dispose);
      await _mount(
        tester,
        places: 1,
        values: values,
        changes: [],
        width: 320,
        scale: 2,
      );
      expect(
        tester.getSize(_key('panel')).height,
        lessThanOrEqualTo(932 * .88),
      );
      await tester.ensureVisible(_key('done'));
      await tester.pumpAndSettle();
      expect(_key('done').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(ZyraIvorySheetHandle),
        const Offset(0, 520),
      );
      await tester.pumpAndSettle();
      expect(_key('panel'), findsNothing);
    },
  );
}
