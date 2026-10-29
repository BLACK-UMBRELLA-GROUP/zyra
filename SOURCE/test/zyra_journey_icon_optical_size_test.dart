// Optical-size regression evidence for the actual shared navigation glyph.
// Everything is local: synthetic tab metadata, bundled fonts and paint only.
// Optional immutable captures (never update repository golden baselines):
// --dart-define=ZYRA_JOURNEY_ICON_SIZE_CAPTURE=true
// --dart-define=ZYRA_JOURNEY_ICON_SIZE_CAPTURE_DIR=<absolute packet directory>
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';

const _capture = bool.fromEnvironment('ZYRA_JOURNEY_ICON_SIZE_CAPTURE');
const _captureDirectory = String.fromEnvironment(
  'ZYRA_JOURNEY_ICON_SIZE_CAPTURE_DIR',
);
const _boundary = ValueKey('journey-optical-size-capture');
const _font = 'PoppinsJourneyOpticalSize';
const _items = [
  FloatingNavItem(icon: Icons.search, label: 'Browse'),
  FloatingNavItem(
    icon: Icons.route_outlined,
    label: 'Journey',
    useJourneyGlyph: true,
    dot: true,
    badge: 3,
  ),
  FloatingNavItem(icon: Icons.dashboard_outlined, label: 'My ZYRA'),
  FloatingNavItem(icon: Icons.gpp_good_outlined, label: 'Guardian'),
  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Journey icon comparisons must remain offline.');
  }
}

class _Raster {
  const _Raster({
    required this.bytes,
    required this.width,
    required this.height,
    required this.ratio,
    this.padding = 0,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final double ratio;
  final double padding;

  Rect get paintedBounds {
    var left = width;
    var top = height;
    var right = -1;
    var bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        // Ignore barely visible antialias fringes, not legitimate strokes.
        if (bytes[(y * width + x) * 4 + 3] < 32) continue;
        left = math.min(left, x);
        top = math.min(top, y);
        right = math.max(right, x);
        bottom = math.max(bottom, y);
      }
    }
    expect(right, greaterThanOrEqualTo(left), reason: 'The glyph must paint.');
    return Rect.fromLTRB(
      left / ratio - padding,
      top / ratio - padding,
      (right + 1) / ratio - padding,
      (bottom + 1) / ratio - padding,
    );
  }

  double get longestAxis {
    final bounds = paintedBounds;
    return math.max(bounds.width, bounds.height);
  }
}

Future<_Raster> _rasterImage(
  WidgetTester tester,
  ui.Image image, {
  required double ratio,
  double padding = 0,
}) async {
  try {
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    expect(data, isNotNull);
    return _Raster(
      bytes: Uint8List.fromList(data!.buffer.asUint8List()),
      width: image.width,
      height: image.height,
      ratio: ratio,
      padding: padding,
    );
  } finally {
    image.dispose();
  }
}

Future<_Raster> _journeyRaster(
  WidgetTester tester,
  ZyraJourneyIconDesign design, {
  required double size,
  double ratio = 4,
}) async {
  // Paint into an oversized transparent canvas: a clipped 22 px widget alone
  // could conceal a stroke extending outside its assigned navigation box.
  const padding = 8.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(ratio)
    ..translate(padding, padding);
  ZyraJourneyIconPainter(
    color: Colors.white,
    design: design,
  ).paint(canvas, Size.square(size));
  final picture = recorder.endRecording();
  try {
    final image = await tester.runAsync(
      () => picture.toImage(
        ((size + padding * 2) * ratio).round(),
        ((size + padding * 2) * ratio).round(),
      ),
    );
    expect(image, isNotNull);
    return _rasterImage(tester, image!, ratio: ratio, padding: padding);
  } finally {
    picture.dispose();
  }
}

Future<_Raster> _materialRaster(
  WidgetTester tester,
  IconData icon, {
  required double size,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: _boundary,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: size, color: Colors.white),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 4));
  expect(image, isNotNull);
  return _rasterImage(tester, image!, ratio: 4);
}

Widget _barApp({
  required int selected,
  ValueChanged<int>? onTap,
  List<FloatingNavItem> items = _items,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    brightness: Brightness.dark,
    fontFamily: _capture ? _font : null,
  ),
  home: RepaintBoundary(
    key: _boundary,
    child: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: Material(
        color: Colors.transparent,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(393, 120),
            padding: EdgeInsets.only(bottom: 14),
            viewPadding: EdgeInsets.only(bottom: 14),
            disableAnimations: true,
          ),
          child: Stack(
            children: [
              FloatingNavBar(
                items: items,
                currentIndex: selected,
                onTap: onTap ?? (_) {},
                contentEdgeInset: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

Future<void> _mountBar(
  WidgetTester tester, {
  required int selected,
  ValueChanged<int>? onTap,
  List<FloatingNavItem> items = _items,
}) async {
  tester.view.physicalSize = const Size(393, 120);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    _barApp(selected: selected, onTap: onTap, items: items),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<Uint8List> _frame(
  WidgetTester tester, {
  required String name,
  double ratio = 1,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(
    () => boundary.toImage(pixelRatio: ratio),
  );
  expect(image, isNotNull);
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(data, isNotNull);
    final bytes = Uint8List.fromList(data!.buffer.asUint8List());
    if (_capture) {
      expect(_captureDirectory.startsWith('/'), isTrue);
      final directory = Directory(_captureDirectory);
      expect(directory.existsSync(), isTrue);
      final file = File('${directory.path}/$name.png');
      expect(file.existsSync(), isFalse, reason: 'Captures are immutable.');
      await tester.runAsync(() async {
        await file.create(exclusive: true);
        await file.writeAsBytes(bytes, flush: true);
      });
    }
    return bytes;
  } finally {
    image!.dispose();
  }
}

Future<ui.Image> _decodedFrame(WidgetTester tester, Uint8List bytes) async {
  final image = await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  });
  expect(image, isNotNull);
  return image!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  final haptics = <MethodCall>[];

  setUpAll(() async {
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
    if (_capture) {
      final reading = FontLoader(_font);
      for (final weight in ['ExtraLight', 'Regular', 'Medium']) {
        reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
      }
      await reading.load();
    }
  });

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _capture ? _font : null;
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          haptics.add(call);
          return null;
        });
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    AppState.instance.resetForAccountChange();
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final example in [
    ('selected Couple at 22 px', 22.0),
    ('selected Couple at 48 px', 48.0),
  ]) {
    testWidgets('${example.$1} has the expected optical size', (tester) async {
      final size = example.$2;
      final materialSearch = await _materialRaster(
        tester,
        Icons.search,
        size: size,
      );
      final materialProfile = await _materialRaster(
        tester,
        Icons.person_outline,
        size: size,
      );
      expect(ZyraJourneyIconPainter.artworkExtent, 21);
      final expectedFootprint = size * 21 / 24;
      final tolerance = math.max(.9, size * .04);
      for (final design in ZyraJourneyIconDesign.values) {
        final raster = await _journeyRaster(tester, design, size: size);
        final bounds = raster.paintedBounds;
        final reason = '${design.label}, ${example.$1}, visible $bounds';
        expect(
          raster.longestAxis,
          closeTo(expectedFootprint, tolerance),
          reason: reason,
        );
        // The bundled person outline is deliberately narrower than search.
        // Compare against the larger peer's actual footprint, rather than
        // guessing one universal ink size for different Material drawings.
        final peerExtent = math.max(
          materialSearch.longestAxis,
          materialProfile.longestAxis,
        );
        expect(
          raster.longestAxis / peerExtent,
          inInclusiveRange(.9, 1.2),
          reason: 'Journey must have comparable visible size to peers: $reason',
        );
        // Use painted bounds, not a constant SizedBox, for centring and safety.
        expect(bounds.center.dx, closeTo(size / 2, tolerance), reason: reason);
        expect(bounds.center.dy, closeTo(size / 2, tolerance), reason: reason);
        expect(bounds.left, greaterThan(0), reason: reason);
        expect(bounds.top, greaterThan(0), reason: reason);
        expect(bounds.right, lessThan(size), reason: reason);
        expect(bounds.bottom, lessThan(size), reason: reason);
      }
    });
  }

  for (final design in const [ZyraJourneyIconDesign.couple]) {
    for (final selected in [0, 1]) {
      testWidgets(
        '${design.label} retains real bar geometry ${selected == 1 ? 'selected' : 'inactive'}',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final calls = <int>[];
          await _mountBar(
            tester,
            selected: selected,
            items: [
              _items.first,
              const FloatingNavItem(
                icon: Icons.route_outlined,
                label: 'Journey',
                useJourneyGlyph: true,
              ),
              ..._items.skip(2),
            ],
          );
          expect(
            tester.widget<ZyraJourneyIcon>(find.byType(ZyraJourneyIcon)).color,
            selected == 1 ? ZyraColors.foreground : ZyraColors.ink(.45),
          );
          await _mountBar(tester, selected: selected, onTap: calls.add);
          final finder = find.byType(ZyraJourneyIcon);
          expect(finder, findsOneWidget);
          final glyph = tester.widget<ZyraJourneyIcon>(finder);
          expect(glyph.size, ZyraNavBarMetrics.iconSize);
          expect(tester.getSize(finder), const Size.square(22));
          expect(glyph.color, ZyraColors.journeyGold);
          final painter = tester
              .widgetList<CustomPaint>(
                find.descendant(of: finder, matching: find.byType(CustomPaint)),
              )
              .map((widget) => widget.painter)
              .whereType<ZyraJourneyIconPainter>()
              .single;
          expect(painter.design, design);
          final scale = tester.widget<AnimatedScale>(
            find.ancestor(of: finder, matching: find.byType(AnimatedScale)),
          );
          expect(scale.scale, 1);
          for (final icon in [Icons.search, Icons.person_outline]) {
            final peer = tester.widget<Icon>(find.byIcon(icon));
            expect(peer.size, 22);
            expect(tester.getSize(find.byIcon(icon)), const Size.square(22));
            expect(
              tester
                  .widget<AnimatedScale>(
                    find.ancestor(
                      of: find.byIcon(icon),
                      matching: find.byType(AnimatedScale),
                    ),
                  )
                  .scale,
              1,
            );
          }

          final cell = find.byKey(const ValueKey('floating-nav-item-1'));
          final activity = tester.widget<Semantics>(cell).properties;
          expect(activity.label, 'Journey');
          expect(activity.value, '3 unread');
          // Existing unread metadata changes the glyph tint and spoken cue;
          // it does not draw a separate badge over the common-size artwork.
          expect(
            find.descendant(of: cell, matching: find.byType(Positioned)),
            findsNothing,
          );
          expect(
            find.descendant(of: cell, matching: find.text('3')),
            findsNothing,
          );
          final highlight = tester.widget<ZyraNavHighlight>(
            find.byType(ZyraNavHighlight),
          );
          expect(highlight.width, ZyraNavBarMetrics.restingHighlightSize);
          expect(highlight.height, ZyraNavBarMetrics.restingHighlightSize);
          final highlightRect = tester.getRect(find.byType(ZyraNavHighlight));
          final selectedCell = tester.getRect(
            find.byKey(ValueKey('floating-nav-item-$selected')),
          );
          expect(highlightRect.center.dx, closeTo(selectedCell.center.dx, .01));
          expect(highlightRect.center.dy, closeTo(selectedCell.center.dy, .01));
          final outer = tester.widget<Positioned>(
            find
                .descendant(
                  of: find.byType(FloatingNavBar),
                  matching: find.byType(Positioned),
                )
                .first,
          );
          expect((outer.left, outer.right, outer.bottom), (20, 20, 0));

          final destination = selected == 1 ? 0 : 1;
          await tester.tapAt(
            tester.getCenter(
              find.byKey(ValueKey('floating-nav-item-$destination')),
            ),
          );
          await tester.pumpAndSettle();
          expect(calls, [destination]);
          expect(
            haptics.where(
              (call) =>
                  call.method == 'HapticFeedback.vibrate' &&
                  call.arguments == 'HapticFeedbackType.selectionClick',
            ),
            hasLength(1),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'revoking developer authority retains the canonical Couple icon and size',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mountBar(tester, selected: 1);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<ZyraJourneyIconPainter>()
          .single;
      expect(painter.design, ZyraJourneyIconDesign.couple);
      expect(
        tester.getSize(find.byType(ZyraJourneyIcon)),
        const Size.square(22),
      );
      expect(tester.takeException(), isNull);
    },
  );

  if (_capture) {
    testWidgets(
      'capture the canonical Couple selected/inactive bars and real-font contact sheets',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final frames = <(ZyraJourneyIconDesign, ui.Image, ui.Image)>[];
        addTearDown(() {
          for (final frame in frames) {
            frame.$2.dispose();
            frame.$3.dispose();
          }
        });
        final unique = <String>{};
        for (final design in const [ZyraJourneyIconDesign.couple]) {
          await _mountBar(tester, selected: 1);
          final active = await _frame(
            tester,
            name: '${design.name}-selected-nav-1x',
          );
          await _mountBar(tester, selected: 0);
          final inactive = await _frame(
            tester,
            name: '${design.name}-inactive-nav-1x',
          );
          unique.add(base64Encode(active));
          frames.add((
            design,
            await _decodedFrame(tester, active),
            await _decodedFrame(tester, inactive),
          ));
        }
        expect(unique, hasLength(1));

        const sheetSize = Size(850, 280);
        tester.view.physicalSize = sheetSize;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: RepaintBoundary(
              key: _boundary,
              child: Material(
                color: ZyraColors.luxuryDarkPurple,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Couple · canonical Journey navigation',
                        style: TextStyle(
                          color: ZyraColors.foreground,
                          fontFamily: _font,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selected (left) · inactive (right) · 48 px comparison',
                        style: TextStyle(
                          color: ZyraColors.foregroundSecondary,
                          fontFamily: _font,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final frame in frames)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                frame.$1.label,
                                style: TextStyle(
                                  color: ZyraColors.foreground,
                                  fontFamily: _font,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RawImage(
                                        image: frame.$2,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: RawImage(
                                        image: frame.$3,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ZyraJourneyIcon(
                                      color: ZyraColors.foreground,
                                      size: 48,
                                      design: frame.$1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byKey(_boundary)), sheetSize);
        expect(find.byType(RawImage), findsNWidgets(2));
        await _frame(tester, name: 'couple-navigation-contact-sheet-1x');
        await _frame(
          tester,
          name: 'couple-navigation-contact-sheet-2x',
          ratio: 2,
        );
      },
    );
  }
}
