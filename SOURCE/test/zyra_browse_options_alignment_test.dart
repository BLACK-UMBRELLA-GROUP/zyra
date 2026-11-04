// Actual shared native IconButton paint/gesture ownership. No member lookup,
// account, profile mutation, network request or haptic implementation is added.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_browse_options_button.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_BROWSE_TAP_CAPTURE_DIRECTORY',
);
const _boundary = ValueKey('browse-tap-paint');
const _header = ValueKey('browse-tap-header');
const _subject = ValueKey('browse-tap-subject');
const _menu = ValueKey('concept_browse_menu');
const _halo = ValueKey('browse-menu-tap-feedback');
const _font = 'PoppinsBrowseTapAlignment';
const _person = SeekerProfile(
  id: 'paint-only-person',
  firstName: 'Sara',
  surnameLine: 'Ahmad',
  age: 27,
  city: 'Birmingham',
  photos: [],
  gender: 'female',
);

Finder _glyph() => find.descendant(
  of: find.byKey(_menu),
  matching: find.byIcon(Icons.more_horiz_rounded),
);

double _alpha(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(find.byKey(_halo)).decoration as BoxDecoration)
        .color!
        .a;

void _expectGeometry(WidgetTester tester, double width) {
  final target = tester.getRect(find.byKey(_menu));
  final glyph = tester.getRect(_glyph());
  final header = tester.getRect(find.byKey(_header));
  final halo = tester.getRect(find.byKey(_halo));
  expect(target.size, const Size(48, 48));
  expect(glyph.size, const Size(24, 24));
  expect(halo.size, const Size(48, 48));
  expect(glyph.right, closeTo(header.right, .01));
  expect(target.right, closeTo(header.right, .01));
  expect(header.left, 20);
  expect(header.right, width - 20);
  expect(halo.center.dx, closeTo(glyph.center.dx, .01));
  expect(halo.center.dy, closeTo(glyph.center.dy, .01));
  expect(halo.right - target.right, closeTo(12, .01));
  expect(halo.right, lessThan(width));
  expect(find.byKey(_menu).hitTestable(), findsOneWidget);
  final button = tester.widget<IconButton>(find.byKey(_menu));
  expect(button.icon, isA<Icon>());
  expect((button.icon as Icon).icon, Icons.more_horiz_rounded);
  expect((button.icon as Icon).size, 24);
  expect(button.tooltip, 'Profiles options for Sara Ahmad');
  expect(
    button.style!.overlayColor!.resolve({WidgetState.pressed}),
    Colors.transparent,
  );
  expect(button.style!.splashFactory, NoSplash.splashFactory);
  expect(tester.takeException(), isNull);
}

Future<void> _mount(
  WidgetTester tester, {
  double width = 393,
  bool align = true,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  bool settle = true,
  required ValueChanged<SeekerProfile?> onOpen,
}) async {
  tester.view.physicalSize = Size(width, 300);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child: Scaffold(
          // LOCK14 V5 Ivory; APP_COLOURS/MASTERS/c01_profiles.png.
          backgroundColor: ZyraColors.ivoryTop,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
            child: Column(
              children: [
                Row(
                  key: _header,
                  children: [
                    Expanded(
                      child: Text(
                        'Browse',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 26,
                          fontWeight: FontWeight.w200,
                          color: ZyraColors.foreground,
                        ),
                      ),
                    ),
                    ZyraBrowseOptionsButton(
                      key: _subject,
                      profile: _person,
                      alignToContentEdge: align,
                      onOpen: onOpen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<({int width, ByteData bytes})> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (width: image.width, bytes: bytes!);
    } finally {
      image.dispose();
    }
  }))!;
}

List<int> _pixel(({int width, ByteData bytes}) image, Offset point) {
  final offset = (point.dy.floor() * image.width + point.dx.floor()) * 4;
  return [
    for (var channel = 0; channel < 4; channel++)
      image.bytes.getUint8(offset + channel),
  ];
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  expect(_captureDirectory.startsWith('/'), isTrue);
  expect(Directory(_captureDirectory).existsSync(), isTrue);
  final file = File('$_captureDirectory/$name.png');
  expect(
    file.existsSync(),
    isFalse,
    reason: 'review captures are never rewritten',
  );
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
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
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Profiles compatibility action is labelled Compatibility score', () {
    expect(ZyraBrowseAction.compatibility.label, 'Compatibility score');
  });
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final reading = FontLoader(_font)
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-ExtraLight.ttf').readAsBytesSync(),
          ),
        ),
      );
    await Future.wait([icons.load(), reading.load()]);
  });
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final width in [320.0, 393.0]) {
    testWidgets('held circle is glyph-centred and unclipped at ${width}px', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final opened = <SeekerProfile?>[];
      await _mount(tester, width: width, onOpen: opened.add);
      _expectGeometry(tester, width);
      expect(_alpha(tester), 0);
      final glyph = tester.getRect(_glyph());
      final target = tester.getRect(find.byKey(_menu));
      final outside = Offset(glyph.right + 6, glyph.center.dy);
      expect(target.contains(outside), isFalse);
      final idle = _pixel(await _pixels(tester), outside);
      await _capture(tester, 'idle_${width.toInt()}');
      final press = await tester.startGesture(glyph.center);
      await tester.pump(const Duration(milliseconds: 110));
      expect(opened, isEmpty);
      expect(_alpha(tester), closeTo(.1, .001));
      _expectGeometry(tester, width);
      final held = _pixel(await _pixels(tester), outside);
      expect(held[3], 255);
      // LOCK14 V5 gold overlay on Ivory can darken the canvas. Verify
      // actual 10% compositing rather than a Plum-era brightening threshold.
      final gold = ZyraColors.journeyGold;
      final components = [gold.r, gold.g, gold.b];
      for (var channel = 0; channel < 3; channel++) {
        expect(
          held[channel],
          closeTo(
            (components[channel] * 255 * .1 + idle[channel] * .9).round(),
            1,
          ),
        );
      }
      await _capture(tester, 'held_${width.toInt()}');
      await press.cancel();
      await tester.pump();
      expect(opened, isEmpty);
      await tester.pump(const Duration(milliseconds: 80));
      expect(_alpha(tester), inExclusiveRange(0, .1));
      await _capture(tester, 'cancel_fade_${width.toInt()}');
      await tester.pumpAndSettle();
      expect(_alpha(tester), 0);
      expect(opened, isEmpty);
      _expectGeometry(tester, width);
    });

    testWidgets(
      'quick tap opens once and leaves a brief centred fade ${width}px',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final opened = <SeekerProfile?>[];
        await _mount(tester, width: width, onOpen: opened.add);
        await tester.tapAt(tester.getCenter(_glyph()));
        await tester.pump();
        expect(opened, [_person]);
        expect(_alpha(tester), greaterThan(0));
        _expectGeometry(tester, width);
        await _capture(tester, 'quick_tap_${width.toInt()}');
        await tester.pump(const Duration(milliseconds: 80));
        expect(_alpha(tester), inExclusiveRange(0, .1));
        await tester.pumpAndSettle();
        expect(_alpha(tester), 0);
        expect(opened, [_person]);
      },
    );
  }

  testWidgets('native focus feedback uses the same centred circle', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <SeekerProfile?>[];
    await _mount(tester, onOpen: opened.add);
    final focus = Focus.of(tester.element(_glyph()), createDependency: false);
    focus.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(
      tester.widget<IconButton>(find.byKey(_menu)).statesController!.value,
      contains(WidgetState.focused),
    );
    expect(_alpha(tester), closeTo(.1, .001));
    _expectGeometry(tester, 393);
    expect(opened, isEmpty);
    focus.unfocus();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_alpha(tester), 0);
  });

  testWidgets('native hover circle does not activate navigation', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <SeekerProfile?>[];
    await _mount(tester, onOpen: opened.add);
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));
    await mouse.moveTo(tester.getCenter(_glyph()));
    await tester.pump();
    expect(_alpha(tester), closeTo(.08, .001));
    _expectGeometry(tester, 393);
    await mouse.moveTo(const Offset(10, 10));
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(_alpha(tester), 0);
    expect(opened, isEmpty);
  });

  for (final accessible in [false, true]) {
    testWidgets('quiet feedback clears instantly accessible=$accessible', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = 0;
      await _mount(
        tester,
        disableAnimations: !accessible,
        accessibleNavigation: accessible,
        onOpen: (_) => opened++,
      );
      final press = await tester.startGesture(tester.getCenter(_glyph()));
      await tester.pump(const Duration(milliseconds: 110));
      expect(_alpha(tester), closeTo(.1, .001));
      _expectGeometry(tester, 393);
      await press.up();
      await tester.pump();
      expect(opened, 1);
      expect(_alpha(tester), 0);
      await tester.pump(const Duration(milliseconds: 250));
      expect(_alpha(tester), 0);
      expect(opened, 1);
    });
  }

  testWidgets('quiet-mode change stops an existing release fade', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = 0;
    await _mount(tester, onOpen: (_) => opened++);
    await tester.tapAt(tester.getCenter(_glyph()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(_alpha(tester), inExclusiveRange(0, .1));
    await _mount(
      tester,
      disableAnimations: true,
      settle: false,
      onOpen: (_) => opened++,
    );
    expect(_alpha(tester), 0);
    expect(opened, 1);
    _expectGeometry(tester, 393);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('disposing a running release leaves no callback or ticker', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = 0;
    await _mount(tester, onOpen: (_) => opened++);
    await tester.tapAt(tester.getCenter(_glyph()));
    await tester.pump();
    expect(_alpha(tester), greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));
    expect(opened, 1);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'non-edge button keeps native centred feedback and icon contract',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = 0;
      await _mount(tester, align: false, onOpen: (_) => opened++);
      final button = tester.widget<IconButton>(find.byKey(_menu));
      expect(button.icon, isA<Icon>());
      expect((button.icon as Icon).size, 24);
      expect(button.style, isNull);
      expect(find.byKey(_halo), findsNothing);
      expect(tester.getRect(find.byKey(_menu)).size, const Size(48, 48));
      expect(tester.getCenter(_glyph()), tester.getCenter(find.byKey(_menu)));
      await tester.tap(find.byKey(_menu));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('native semantics retain one labelled navigation action', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    var opened = 0;
    try {
      await _mount(tester, onOpen: (_) => opened++);
      final finder = find.byKey(_menu);
      final node = tester.getSemantics(finder);
      final data = node.getSemanticsData();
      expect(data.tooltip, 'Profiles options for Sara Ahmad');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(find.byTooltip('Profiles options for Sara Ahmad'), findsOneWidget);
      tester
          .renderObject<RenderObject>(finder)
          .owner!
          .semanticsOwner!
          .performAction(node.id, ui.SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
