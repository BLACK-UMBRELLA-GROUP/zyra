import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';

const _gradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF30203F), Color(0xFF160E20)],
);

bool _select(bool enabled) => ZyraDevAppGold.instance.select(
  enabled,
  expectedGeneration: ZyraAccountState.generation,
  expectedRevision: ZyraDevAppGold.instance.revision,
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

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraText.useTestFontStubs = true;
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
  });

  tearDown(() {
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  test('app gold defaults Off and unauthorized accounts cannot enable it', () {
    final selection = ZyraDevAppGold.instance;
    expect(selection.enabled, isFalse);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(_select(true), isFalse);
    expect(selection.enabled, isFalse);
  });

  test('revocation and reauthorization do not revive a previous On choice', () {
    final selection = ZyraDevAppGold.instance;
    expect(_select(true), isTrue);
    expect(selection.enabled, isTrue);
    final previousRevision = selection.revision;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(selection.enabled, isFalse);
    expect(selection.revision, greaterThan(previousRevision));
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    expect(selection.enabled, isFalse);
  });

  test('stale generation and revision selections are refused', () {
    final selection = ZyraDevAppGold.instance;
    final generation = ZyraAccountState.generation;
    final revision = selection.revision;
    expect(_select(true), isTrue);
    expect(
      selection.select(
        false,
        expectedGeneration: generation,
        expectedRevision: revision,
      ),
      isFalse,
    );
    expect(selection.enabled, isTrue);
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
    expect(_select(false), isTrue);
    expect(_select(true), isTrue);
    expect(selection.enabled, isTrue);
  });

  test('account presentation reset clears On and notifies mounted painters', () {
    final selection = ZyraDevAppGold.instance;
    expect(_select(true), isTrue);
    final revision = selection.revision;
    var repaints = 0;
    final painter = const ZyraAppGoldDecoration(
      gradient: _gradient,
    ).createBoxPainter(() => repaints++);
    ZyraAccountState.resetForTesting();
    // The real account synchronizer updates the generation before resetting
    // AppState. Reproduce that synchronous sequence without disk/backend work.
    AppState.instance.resetForAccountChange();
    expect(selection.enabled, isFalse);
    expect(selection.revision, greaterThan(revision));
    expect(repaints, 1);
    expect(_select(true), isTrue);
    expect(selection.enabled, isTrue);
    expect(repaints, 2);
    painter.dispose();
  });

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
    'On changes visible pixels; revocation restores identical Off pixels',
    () async {
      const decorated = ZyraAppGoldDecoration(gradient: _gradient);
      final off = await _pixels(decorated);
      expect(_select(true), isTrue);
      final on = await _pixels(decorated);
      expect(on, isNot(orderedEquals(off)));
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(await _pixels(decorated), orderedEquals(off));
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      expect(await _pixels(decorated), orderedEquals(off));
    },
  );

  test(
    'particles translate with their canvas and cannot spill outside it',
    () async {
      expect(_select(true), isTrue);
      // Isolate particle alpha from the background gradient. That checks
      // geometry without shader/compositing channel rounding differences.
      const decorated = ZyraAppGoldDecoration();
      const size = Size(200, 300);
      const offset = Offset(17, 23);
      const bounds = Size(240, 350);
      final local = await _pixels(decorated, size: size);
      final positioned = await _pixels(
        decorated,
        size: size,
        offset: offset,
        canvasSize: bounds,
      );
      for (var y = 0; y < bounds.height.toInt(); y++) {
        for (var x = 0; x < bounds.width.toInt(); x++) {
          final index = (y * bounds.width.toInt() + x) * 4;
          final inside = x >= 17 && x < 217 && y >= 23 && y < 323;
          if (!inside) {
            expect(positioned[index + 3], 0, reason: 'Outside ($x, $y)');
            continue;
          }
          final localIndex = ((y - 23) * size.width.toInt() + x - 17) * 4;
          expect(positioned[index + 3], closeTo(local[localIndex + 3], 1));
        }
      }
    },
  );

  test('rounded clipping keeps the gold inside the background shape', () async {
    expect(_select(true), isTrue);
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
    final selection = ZyraDevAppGold.instance;
    final before = selection.debugPainterCount;
    var repaints = 0;
    final painter = const ZyraAppGoldDecoration(
      gradient: _gradient,
    ).createBoxPainter(() => repaints++);
    expect(selection.debugPainterCount, before + 1);
    expect(_select(true), isTrue);
    selection.frame.value = .25;
    expect(repaints, 2);
    painter.dispose();
    expect(selection.debugPainterCount, before);
    expect(_select(false), isTrue);
    selection.frame.value = .75;
    expect(repaints, 2);
  });

  test(
    'ordinary member choice paints gold and Off restores original pixels',
    () async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      const decoration = ZyraAppGoldDecoration(gradient: _gradient);
      final off = await _pixels(decoration);
      final member = ZyraAppGoldStyle.instance;
      expect(
        member.select(
          true,
          expectedGeneration: ZyraAccountState.generation,
          expectedRevision: member.revision,
        ),
        isTrue,
      );
      expect(await _pixels(decoration), isNot(orderedEquals(off)));
      expect(
        member.select(
          false,
          expectedGeneration: ZyraAccountState.generation,
          expectedRevision: member.revision,
        ),
        isTrue,
      );
      expect(await _pixels(decoration), orderedEquals(off));
    },
  );

  testWidgets('ordinary member choice starts and stops the shared live clock', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    final member = ZyraAppGoldStyle.instance;
    final clock = ZyraDevAppGold.instance;
    await tester.pumpWidget(
      _app(
        const DecoratedBox(
          decoration: ZyraAppGoldDecoration(gradient: _gradient),
          child: SizedBox.expand(),
        ),
      ),
    );
    member.select(
      true,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: member.revision,
    );
    await tester.pump();
    final initial = clock.frame.value;
    await tester.pump(const Duration(milliseconds: 600));
    expect(clock.frame.value, isNot(initial));
    member.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: member.revision,
    );
    final stopped = clock.frame.value;
    await tester.pump(const Duration(seconds: 2));
    expect(clock.frame.value, stopped);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(clock.debugPainterCount, 0);
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
    expect(_select(true), isTrue);
    await tester.pump();
    final on = await tester.runAsync(() => _widgetPixels(tester, boundaryKey));
    expect(on, orderedEquals(off!));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(ZyraDevAppGold.instance.debugPainterCount, 0);
  });

  testWidgets(
    'picker updates immediately, refuses stale callbacks and hides on revocation',
    (tester) async {
      await tester.pumpWidget(_app(const DevAppGoldPicker()));
      final toggle = find.byKey(const ValueKey('dev_app_gold_toggle'));
      final oldCallback = tester.widget<Switch>(toggle).onChanged!;
      oldCallback(true);
      await tester.pump();
      expect(tester.widget<Switch>(toggle).value, isTrue);
      expect(_select(false), isTrue);
      oldCallback(true);
      await tester.pump();
      expect(tester.widget<Switch>(toggle).value, isFalse);
      final accountCallback = tester.widget<Switch>(toggle).onChanged!;
      ZyraAccountState.resetForTesting();
      accountCallback(true);
      await tester.pump();
      expect(ZyraDevAppGold.instance.enabled, isFalse);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      expect(toggle, findsNothing);
      oldCallback(true);
      expect(ZyraDevAppGold.instance.enabled, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('busy picker is disabled; compact layout remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: DevAppGoldPicker(enabled: false),
            ),
          ),
        ),
      ),
    );
    final toggle = find.byKey(const ValueKey('dev_app_gold_toggle'));
    await tester.ensureVisible(toggle);
    expect(tester.widget<Switch>(toggle).onChanged, isNull);
    expect(ZyraDevAppGold.instance.enabled, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final (label, panel) in <(String, Widget Function(ValueNotifier<int>))>[
    (
      'Entry',
      (requests) =>
          ZyraEntryDevPanel(pageLabel: 'Auth fixture', openRequests: requests),
    ),
    (
      'Seeker',
      (requests) =>
          DevScenarioPanelV2(onOpenPage: (_) {}, openRequests: requests),
    ),
    (
      'Guardian',
      (requests) =>
          WaliDevScenarioPanel(onOpenPage: (_) {}, openRequests: requests),
    ),
  ]) {
    testWidgets(
      '$label shared Home omits gold without changing member choice',
      (tester) async {
        ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
        final member = ZyraAppGoldStyle.instance;
        member.select(
          true,
          expectedGeneration: ZyraAccountState.generation,
          expectedRevision: member.revision,
        );
        final semantics = tester.ensureSemantics();
        final openRequests = ValueNotifier<int>(0);
        await tester.pumpWidget(
          _app(Stack(fit: StackFit.expand, children: [panel(openRequests)])),
        );
        await tester.pump();
        openRequests.value++;
        // The saved member gold choice deliberately keeps its clock alive.
        // Flush the real open request and finite panel transition, not all
        // future frames from the unrelated decorative animation.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final home = find
            .byKey(const ValueKey('dev_controls_tab_home'))
            .hitTestable();
        expect(home, findsOneWidget);
        await tester.tap(home);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final section = find.byKey(const ValueKey('dev_home_section_app_gold'));
        final toggle = find.byKey(const ValueKey('dev_app_gold_toggle'));
        expect(section, findsNothing);
        expect(find.text('App gold accents'), findsNothing);
        expect(find.byType(DevAppGoldPicker), findsNothing);
        expect(toggle, findsNothing);
        expect(find.bySemanticsLabel('App gold accents'), findsNothing);
        expect(
          find.byKey(const ValueKey('dev_home_section_account')),
          findsOneWidget,
        );
        expect(member.enabled, isTrue);
        expect(ZyraDevAppGold.instance.enabled, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        openRequests.dispose();
        semantics.dispose();
      },
    );

    testWidgets(
      '$label developer Home and gold toggle are absent for ordinary accounts',
      (tester) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        final openRequests = ValueNotifier<int>(0);
        await tester.pumpWidget(
          _app(Stack(fit: StackFit.expand, children: [panel(openRequests)])),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('dev_controls_tab_home')),
          findsNothing,
        );
        expect(find.byType(DevAppGoldPicker), findsNothing);
        expect(find.byKey(const ValueKey('dev_app_gold_toggle')), findsNothing);
        expect(_select(true), isFalse);
        expect(ZyraDevAppGold.instance.enabled, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        openRequests.dispose();
      },
    );
  }

  for (final guardian in [false, true]) {
    testWidgets(
      'busy ${guardian ? 'Guardian' : 'Seeker'} shared Home has no gold toggle',
      (tester) async {
        await tester.pumpWidget(
          _app(
            SingleChildScrollView(
              child: ZyraDevHomeTools(
                busy: true,
                guardian: guardian,
                onHome: () {},
                onRestart: () {},
                onReset: null,
                onAccounts: () {},
                onSeekerSignUp: () {},
                onGuardianSignUp: () {},
              ),
            ),
          ),
        );
        final toggle = find.byKey(const ValueKey('dev_app_gold_toggle'));
        await tester.pumpAndSettle();
        expect(toggle, findsNothing);
        expect(find.byType(DevAppGoldPicker), findsNothing);
        expect(
          find.byKey(const ValueKey('dev_home_section_app_gold')),
          findsNothing,
        );
        expect(ZyraDevAppGold.instance.enabled, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final accessible in [false, true]) {
    testWidgets(
      'reduced-motion mode stays static (${accessible ? 'accessible navigation' : 'disable animations'})',
      (tester) async {
        final selection = ZyraDevAppGold.instance;
        expect(_select(true), isTrue);
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

  testWidgets(
    'one clock animates multiple canvases without rebuilding content and stops Off',
    (tester) async {
      final selection = ZyraDevAppGold.instance;
      var contentBuilds = 0;
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: const ZyraAppGoldDecoration(gradient: _gradient),
                  child: Builder(
                    builder: (_) {
                      contentBuilds++;
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ),
              const Expanded(
                child: DecoratedBox(
                  decoration: ZyraAppGoldDecoration(gradient: _gradient),
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      );
      expect(selection.debugPainterCount, 2);
      expect(contentBuilds, 1);
      expect(_select(true), isTrue);
      await tester.pump();
      final initial = selection.frame.value;
      await tester.pump(const Duration(milliseconds: 600));
      expect(selection.frame.value, isNot(initial));
      expect(contentBuilds, 1);
      expect(_select(false), isTrue);
      final stopped = selection.frame.value;
      await tester.pump(const Duration(seconds: 2));
      expect(selection.frame.value, stopped);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(selection.debugPainterCount, 0);
    },
  );

  testWidgets(
    'live clock pauses in the background and while TickerMode is disabled',
    (tester) async {
      final selection = ZyraDevAppGold.instance;
      const content = DecoratedBox(
        decoration: ZyraAppGoldDecoration(gradient: _gradient),
        child: SizedBox.expand(),
      );
      expect(_select(true), isTrue);
      await tester.pumpWidget(_app(content));
      await tester.pump(const Duration(milliseconds: 600));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final paused = selection.frame.value;
      await tester.pump(const Duration(seconds: 2));
      expect(selection.frame.value, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(selection.frame.value, isNot(paused));
      await tester.pumpWidget(_app(content, ticker: false));
      final hidden = selection.frame.value;
      await tester.pump(const Duration(seconds: 2));
      expect(selection.frame.value, hidden);
      await tester.pumpWidget(_app(content));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(selection.frame.value, isNot(hidden));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(selection.debugPainterCount, 0);
    },
  );
}
