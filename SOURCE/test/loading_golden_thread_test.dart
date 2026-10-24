// Regression contract: the retired full-screen brand loader cannot return.
// Filename is retained so existing qualification recipes exercise this policy.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_comet_rule.dart';
import 'package:zyra/widgets/zyra_loading.dart';
import 'package:zyra/widgets/zyra_meet_and_pass_rule.dart';

const _captures = String.fromEnvironment('ZYRA_QUIET_WAIT_CAPTURE_DIR');
const _readingFont = 'PoppinsQuietWait';
const _boundary = ValueKey('quiet-wait-capture');
const _canvas = ValueKey('zyra_full_screen_quiet_canvas');
const _status = ValueKey('zyra_quiet_loading_status');

Widget _app(Widget child, {bool still = false, double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: _readingFont,
        brightness: ZyraColors.isLightPalette
            ? Brightness.light
            : Brightness.dark,
      ),
      builder: (context, content) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: still,
          textScaler: TextScaler.linear(scale),
        ),
        child: content!,
      ),
      home: Scaffold(
        body: RepaintBoundary(key: _boundary, child: child),
      ),
    );

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  bool still = false,
  double scale = 1,
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(child, still: still, scale: scale));
  expect(tester.takeException(), isNull);
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  expect(tester.binding.transientCallbackCount, 0);
  expect(tester.takeException(), isNull);
}

void _expectQuiet(WidgetTester tester, {bool feedback = false}) {
  expect(find.byType(ZyraQuietLoading), findsOneWidget);
  expect(find.byKey(_canvas), findsOneWidget);
  expect(find.text('ZYRA'), findsNothing);
  for (final key in const [
    'zyra_loading_wordmark',
    'zyra_loading_golden_thread',
    'zyra_loading_golden_thread_track',
    'zyra_loading_golden_thread_glint',
  ]) {
    expect(find.byKey(ValueKey(key)), findsNothing);
  }
  expect(find.byType(ZyraCometRule), findsNothing);
  expect(find.byType(ZyraMeetAndPassRule), findsNothing);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(
    find.descendant(
      of: find.byType(ZyraQuietLoading),
      matching: find.byType(CustomPaint),
    ),
    findsNothing,
  );
  expect(find.byKey(_status), feedback ? findsOneWidget : findsNothing);
  expect(tester.binding.transientCallbackCount, 0);
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    // Explicit caller-owned absolute directory; never replace a capture.
    final file = File('$_captures/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late bool oldFontStubs;
  late String? oldReadingFont;

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      final directory = Directory(_captures);
      if (!_captures.startsWith('/') ||
          FileSystemEntity.typeSync(_captures, followLinks: false) !=
              FileSystemEntityType.directory ||
          directory.resolveSymbolicLinksSync() != directory.path) {
        throw StateError(
          'Quiet wait captures require an existing absolute nonlinked directory.',
        );
      }
    }
    final reading = FontLoader(_readingFont)
      ..addFont(rootBundle.load('assets/fonts/Poppins-Light.ttf'));
    await reading.load();
  });

  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    oldReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _readingFont;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  tearDown(() {
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldReadingFont;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  for (final still in [false, true]) {
    for (final style in <ZyraLoadingStyle?>[null, ...ZyraLoadingStyle.values]) {
      testWidgets(
        'fullscreen ${style?.name ?? 'default'} ${still ? 'reduced' : 'moving'} never renders branding or motion',
        (tester) async {
          try {
            await _mount(
              tester,
              ZyraLoading.fullScreen(style: style, label: 'Checking access…'),
              still: still,
            );
            _expectQuiet(tester);
            expect(find.text('Checking access…'), findsNothing);
            final box = tester.widget<DecoratedBox>(find.byKey(_canvas));
            expect(
              (box.decoration as BoxDecoration).gradient,
              ZyraColors.brandGradient,
            );
            expect(
              tester.getRect(find.byKey(_canvas)),
              tester.getRect(find.byKey(_boundary)),
            );
            await tester.pump(const Duration(milliseconds: 799));
            _expectQuiet(tester);
            await tester.pump(const Duration(milliseconds: 1));
            _expectQuiet(tester, feedback: true);
            expect(find.text('Updating…'), findsOneWidget);
            await tester.pump(const Duration(seconds: 10));
            _expectQuiet(tester, feedback: true);
            expect(tester.binding.hasScheduledFrame, isFalse);
          } finally {
            await _dispose(tester);
          }
        },
      );
    }
  }

  testWidgets('quiet fullscreen capture before and after delayed feedback', (
    tester,
  ) async {
    try {
      await _mount(tester, const ZyraLoading.fullScreen());
      _expectQuiet(tester);
      await _capture(tester, 'quiet-fullscreen-first-frame');
      await tester.pump(const Duration(milliseconds: 800));
      _expectQuiet(tester, feedback: true);
      await _capture(tester, 'quiet-fullscreen-delayed-feedback');
    } finally {
      await _dispose(tester);
    }
  });

  testWidgets('runtime motion preference never starts a fullscreen ticker', (
    tester,
  ) async {
    final still = ValueNotifier(false);
    addTearDown(still.dispose);
    try {
      await _mount(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: still,
          builder: (context, value, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: value),
            child: const ZyraLoading.fullScreen(),
          ),
        ),
      );
      final state = tester.state(find.byType(ZyraLoading));
      for (final value in [true, false, true, false]) {
        still.value = value;
        await tester.pump();
        expect(tester.state(find.byType(ZyraLoading)), same(state));
        _expectQuiet(tester);
      }
    } finally {
      await _dispose(tester);
    }
  });

  testWidgets('same-State inline motion stops for every fullscreen switch', (
    tester,
  ) async {
    try {
      await _mount(tester, const ZyraLoading());
      final state = tester.state(find.byType(ZyraLoading));
      expect(find.byType(ZyraCometRule), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 1);
      for (final style in ZyraLoadingStyle.values) {
        await tester.pumpWidget(_app(ZyraLoading.fullScreen(style: style)));
        expect(tester.state(find.byType(ZyraLoading)), same(state));
        _expectQuiet(tester);
        await tester.pumpWidget(_app(ZyraLoading(style: style)));
        expect(tester.state(find.byType(ZyraLoading)), same(state));
        expect(find.byType(ZyraQuietLoading), findsNothing);
        expect(
          find.byKey(ValueKey('zyra_loading_${style.name}')),
          findsOneWidget,
        );
        expect(find.text('ZYRA'), findsNothing);
        expect(tester.binding.transientCallbackCount, 1);
      }
    } finally {
      await _dispose(tester);
    }
  });

  testWidgets('hidden time does not earn feedback and visible time restarts', (
    tester,
  ) async {
    try {
      await _mount(tester, const ZyraLoading.fullScreen());
      await tester.pump(const Duration(milliseconds: 700));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 8));
      _expectQuiet(tester);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 799));
      _expectQuiet(tester);
      await tester.pump(const Duration(milliseconds: 1));
      _expectQuiet(tester, feedback: true);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      // Paused apps do not paint. Require the first resumed frame to be
      // quiet, rather than asserting that a suspended frame was repainted.
      await tester.pump(const Duration(seconds: 8));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      _expectQuiet(tester);
      await tester.pump(const Duration(milliseconds: 799));
      _expectQuiet(tester);
      await tester.pump(const Duration(milliseconds: 1));
      _expectQuiet(tester, feedback: true);
    } finally {
      await _dispose(tester);
    }
  });

  testWidgets(
    'a covered route resets feedback rather than counting hidden time',
    (tester) async {
      try {
        await _mount(tester, const ZyraLoading.fullScreen());
        await tester.pump(const Duration(milliseconds: 700));
        final navigator = Navigator.of(
          tester.element(find.byType(ZyraLoading)),
        );
        final covered = navigator.push<void>(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => const Scaffold(body: Text('Cover')),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 8));
        expect(find.byKey(_status, skipOffstage: false), findsNothing);
        navigator.pop();
        await tester.pump();
        await covered;
        await tester.pump(const Duration(milliseconds: 799));
        _expectQuiet(tester);
        await tester.pump(const Duration(milliseconds: 1));
        _expectQuiet(tester, feedback: true);
      } finally {
        await _dispose(tester);
      }
    },
  );

  testWidgets('opaque waiting blocks underlying touch and private semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    try {
      await _mount(
        tester,
        Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: 'Private profile',
                button: true,
                child: GestureDetector(onTap: () => taps++),
              ),
            ),
            const Positioned.fill(child: ZyraLoading.fullScreen()),
          ],
        ),
      );
      _expectQuiet(tester);
      expect(find.bySemanticsLabel('Private profile'), findsNothing);
      expect(find.bySemanticsLabel('Updating ZYRA'), findsNothing);
      await tester.tapAt(tester.getCenter(find.byKey(_canvas)));
      expect(taps, 0);
      await tester.pump(const Duration(milliseconds: 800));
      _expectQuiet(tester, feedback: true);
      expect(find.bySemanticsLabel('Private profile'), findsNothing);
      final feedback = find.bySemanticsLabel('Updating ZYRA');
      expect(feedback, findsOneWidget);
      expect(
        tester
            .getSemantics(feedback)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
    } finally {
      await _dispose(tester);
      semantics.dispose();
    }
  });

  testWidgets(
    'delayed feedback fits small large-text and landscape safe bounds',
    (tester) async {
      try {
        await _mount(
          tester,
          const ZyraLoading.fullScreen(label: 'An old full-screen reason'),
          scale: 2,
          size: const Size(320, 568),
        );
        await tester.pump(const Duration(milliseconds: 800));
        for (final size in [const Size(320, 568), const Size(844, 390)]) {
          tester.view.physicalSize = size;
          await tester.pump();
          _expectQuiet(tester, feedback: true);
          final screen = tester.getRect(find.byKey(_boundary));
          final label = tester.getRect(find.byKey(_status));
          expect(label.left, greaterThanOrEqualTo(screen.left + 24));
          expect(label.right, lessThanOrEqualTo(screen.right - 24));
          expect(label.top, greaterThanOrEqualTo(screen.top + 59));
          expect(label.bottom, lessThanOrEqualTo(screen.bottom - 34));
          expect(find.text('An old full-screen reason'), findsNothing);
        }
        await _capture(tester, 'quiet-fullscreen-small-text200-landscape');
      } finally {
        await _dispose(tester);
      }
    },
  );

  testWidgets('readiness removes waiting immediately and cancels its timer', (
    tester,
  ) async {
    try {
      await _mount(tester, const ZyraLoading.fullScreen());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(_app(const Text('Ready')));
      expect(find.text('Ready'), findsOneWidget);
      expect(find.byType(ZyraQuietLoading), findsNothing);
      await tester.pump(const Duration(seconds: 8));
      expect(find.text('Ready'), findsOneWidget);
      expect(find.byKey(_status), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    } finally {
      await _dispose(tester);
    }
  });

  testWidgets('optional compact reasons and the chosen inline motion remain', (
    tester,
  ) async {
    try {
      const reason = 'Checking your invitation…';
      await _mount(tester, const ZyraLoading(label: reason), still: true);
      expect(kZyraLoadingStyle, ZyraLoadingStyle.cometLoop);
      expect(ZyraLoadingStyle.values, hasLength(10));
      expect(find.text(reason), findsOneWidget);
      expect(find.byType(ZyraCometRule), findsOneWidget);
      expect(find.byType(ZyraQuietLoading), findsNothing);
      expect(find.text('ZYRA'), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    } finally {
      await _dispose(tester);
    }
  });
}
