import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';

const _gradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF30203F), Color(0xFF160E20)],
);

bool _select(bool enabled) => ZyraAppGoldStyle.instance.select(
  enabled,
  expectedGeneration: ZyraAccountState.generation,
  expectedRevision: ZyraAppGoldStyle.instance.revision,
);

Future<Uint8List> _pixels(
  Decoration decoration, {
  Size size = const Size(240, 360),
  Offset offset = Offset.zero,
  Size? canvasSize,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final painter = decoration.createBoxPainter();
  try {
    painter.paint(
      canvas,
      offset,
      ImageConfiguration(size: size, textDirection: TextDirection.ltr),
    );
  } finally {
    painter.dispose();
  }
  final picture = recorder.endRecording();
  final bounds = canvasSize ?? size;
  final image = await picture.toImage(
    bounds.width.round(),
    bounds.height.round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = Uint8List.fromList(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return result;
}

Widget _app(
  Widget child, {
  bool reduce = false,
  bool accessible = false,
  bool ticker = true,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(320, 568),
      disableAnimations: reduce,
      accessibleNavigation: accessible,
    ),
    child: TickerMode(
      enabled: ticker,
      child: ZyraAppGoldPreviewHost(child: Scaffold(body: child)),
    ),
  ),
);

Future<Uint8List> _widgetPixels(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = Uint8List.fromList(bytes!.buffer.asUint8List());
  image.dispose();
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await ZyraAccountState.synchronize(null);
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraAppGoldRenderer.instance.resetForTesting();
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraAppGoldStyle.instance.restore(false);
    ZyraAppGoldRenderer.instance.resetForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
  });

  test('app Gold stays Off without developer authority', () {
    final renderer = ZyraAppGoldRenderer.instance;
    expect(renderer.renderingEnabled, isFalse);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(_select(true), isFalse);
    expect(renderer.renderingEnabled, isFalse);
  });

  test('developer admission cannot revive the retired Gold choice', () {
    final member = ZyraAppGoldStyle.instance;
    expect(_select(true), isFalse);
    final previousRevision = member.revision;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(member.enabled, isFalse);
    expect(member.revision, previousRevision);
    expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    expect(member.enabled, isFalse);
    expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
  });

  test('stale generation and revision selections are refused', () {
    final selection = ZyraAppGoldStyle.instance;
    final generation = ZyraAccountState.generation;
    final revision = selection.revision;
    expect(_select(true), isFalse);
    expect(
      selection.select(
        false,
        expectedGeneration: generation,
        expectedRevision: revision,
      ),
      isFalse,
    );
    expect(selection.enabled, isFalse);
    ZyraAccountState.resetForTesting();
    expect(selection.enabled, isFalse);
    expect(
      selection.select(
        true,
        expectedGeneration: generation,
        expectedRevision: selection.revision,
      ),
      isFalse,
    );
    expect(selection.enabled, isFalse);
    expect(_select(false), isFalse);
    expect(_select(true), isFalse);
    expect(selection.enabled, isFalse);
  });

  test(
    'account presentation reset cannot enable Gold or notify dormant painters',
    () async {
      final selection = ZyraAppGoldStyle.instance;
      expect(_select(true), isFalse);
      final revision = selection.revision;
      var repaints = 0;
      final painter = const ZyraAppGoldDecoration(
        gradient: _gradient,
      ).createBoxPainter(() => repaints++);
      await ZyraAccountState.synchronize(
        '11111111-1111-4111-8111-111111111111',
      );
      expect(selection.enabled, isFalse);
      expect(selection.revision, revision);
      expect(repaints, 0);
      expect(_select(true), isFalse);
      expect(selection.enabled, isFalse);
      expect(repaints, 0);
      painter.dispose();
    },
  );

  test('Off decoration paints exactly the existing background', () async {
    const ordinary = BoxDecoration(
      gradient: _gradient,
      borderRadius: BorderRadius.all(Radius.circular(18)),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFFE5CE8E))),
      boxShadow: [BoxShadow(color: Color(0x44000000), blurRadius: 5)],
    );
    const decorated = ZyraAppGoldDecoration(
      gradient: _gradient,
      borderRadius: BorderRadius.all(Radius.circular(18)),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFFE5CE8E))),
      boxShadow: [BoxShadow(color: Color(0x44000000), blurRadius: 5)],
    );
    expect(await _pixels(decorated), orderedEquals(await _pixels(ordinary)));
  });

  test(
    'retired Gold callbacks leave the existing canvas pixels unchanged',
    () async {
      const decorated = ZyraAppGoldDecoration(gradient: _gradient);
      final off = await _pixels(decorated);
      expect(_select(true), isFalse);
      final on = await _pixels(decorated);
      expect(on, orderedEquals(off));
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(await _pixels(decorated), orderedEquals(on));
      expect(_select(false), isFalse);
      expect(await _pixels(decorated), orderedEquals(off));
    },
  );

  test('rounded clipping keeps the background inside its shape', () async {
    expect(_select(true), isFalse);
    const decorated = ZyraAppGoldDecoration(
      gradient: _gradient,
      borderRadius: BorderRadius.all(Radius.circular(100)),
    );
    final pixels = await _pixels(decorated, size: const Size(200, 300));
    for (final position in const [
      Offset(0, 0),
      Offset(199, 0),
      Offset(0, 299),
      Offset(199, 299),
    ]) {
      expect(
        pixels[(position.dy.toInt() * 200 + position.dx.toInt()) * 4 + 3],
        0,
      );
    }
  });

  test(
    'decoration interpolation retains the gold painter at intermediate frames',
    () {
      const first = ZyraAppGoldDecoration(gradient: _gradient);
      const second = ZyraAppGoldDecoration(color: Color(0xFF160E20));
      const ordinary = BoxDecoration(color: Color(0xFF30203F));
      for (final amount in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(
          Decoration.lerp(first, second, amount),
          isA<ZyraAppGoldDecoration>(),
        );
        expect(first.lerpFrom(ordinary, amount), isA<ZyraAppGoldDecoration>());
        expect(first.lerpTo(ordinary, amount), isA<ZyraAppGoldDecoration>());
        expect(first.lerpFrom(null, amount), isA<ZyraAppGoldDecoration>());
        expect(first.lerpTo(null, amount), isA<ZyraAppGoldDecoration>());
      }
    },
  );

  test('disposing the painter detaches selection and animation listeners', () {
    final selection = ZyraAppGoldRenderer.instance;
    final before = selection.debugPainterCount;
    var repaints = 0;
    final painter = const ZyraAppGoldDecoration(
      gradient: _gradient,
    ).createBoxPainter(() => repaints++);
    expect(selection.debugPainterCount, before + 1);
    expect(_select(true), isFalse);
    selection.frame.value = .25;
    expect(repaints, 1);
    painter.dispose();
    expect(selection.debugPainterCount, before);
    expect(_select(false), isFalse);
    selection.frame.value = .75;
    expect(repaints, 1);
  });

  testWidgets('opaque children stay unchanged and buttons still receive taps', (
    tester,
  ) async {
    const boundaryKey = ValueKey('app_gold_opaque_child');
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 240,
              height: 360,
              child: DecoratedBox(
                decoration: const ZyraAppGoldDecoration(gradient: _gradient),
                child: ColoredBox(
                  color: const Color(0xFF443D55),
                  child: Center(
                    child: FilledButton(
                      onPressed: () => taps++,
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final off = await tester.runAsync(() => _widgetPixels(tester, boundaryKey));
    expect(_select(true), isFalse);
    await tester.pump();
    final on = await tester.runAsync(() => _widgetPixels(tester, boundaryKey));
    expect(on, orderedEquals(off!));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(ZyraAppGoldRenderer.instance.debugPainterCount, 0);
  });

  for (final accessible in [false, true]) {
    testWidgets(
      'reduced-motion mode stays static (${accessible ? 'accessible navigation' : 'disable animations'})',
      (tester) async {
        final selection = ZyraAppGoldRenderer.instance;
        expect(_select(true), isFalse);
        await tester.pumpWidget(
          _app(
            const DecoratedBox(
              decoration: ZyraAppGoldDecoration(gradient: _gradient),
              child: SizedBox.expand(),
            ),
            reduce: !accessible,
            accessible: accessible,
          ),
        );
        expect(selection.reducedMotion, isTrue);
        final frame = selection.frame.value;
        await tester.pump(const Duration(seconds: 6));
        expect(selection.frame.value, frame);
        expect(frame, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(selection.debugPainterCount, 0);
      },
    );
  }

}
