// OA-ZYRA-371 / Q190: actual presenters over pure-white photos, with bundled
// Poppins and the normal rendered-text auditor. No network or capture writes.
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_photo_text_fade.dart';

import 'support/zyra_rendered_text_contrast.dart';

const _font = 'ZYRAPhotoFadePoppins';
const _boundary = ValueKey('photo-fade-test-boundary');
const _profile = SeekerProfile(
  id: 'photo-fade-sara',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'Female',
  photos: ['local-white'],
);
late MemoryImage _white;
final _observations = <Map<String, Object?>>[];
final _retainedObservations = <Map<String, Object?>>[];

Future<void> _mount(
  WidgetTester tester,
  Size size,
  double scale,
  Widget child,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: _font),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: size.width == 375
              ? const EdgeInsets.only(top: 20)
              : const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: _boundary,
          child: ColoredBox(color: Colors.white, child: child),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    await precacheImage(_white, tester.element(find.byKey(_boundary)));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
}

double _contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

Future<void> _mountRetained(
  WidgetTester tester,
  ValueNotifier<double> scale, {
  required bool overflow,
}) async {
  final card = ZyraJourneyPhotoCard(
    surfaceKey: const ValueKey('retained-photo'),
    scrollKey: const ValueKey('retained-photo-scroll'),
    photo: _white,
    children: [
      for (var i = 0; i < 4; i++)
        const Text(
          'Reading line over photo',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 14,
            height: 1.4,
            color: Colors.white,
          ),
        ),
      if (overflow) const SizedBox(height: 300),
    ],
  );
  await _mount(
    tester,
    const Size(375, 667),
    1,
    Center(
      child: SizedBox(
        width: 300,
        height: 240,
        child: ValueListenableBuilder<double>(
          valueListenable: scale,
          child: card,
          builder: (context, value, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(value)),
            child: child!,
          ),
        ),
      ),
    ),
  );
}

Future<List<int>> _retainedPixel(
  WidgetTester tester,
  RenderZyraPhotoTextFade fade,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final point = MatrixUtils.transformPoint(
    fade.getTransformTo(boundary),
    Offset(
      fade.size.width / 2,
      (fade.fadeGeometry.darkTop + 1).clamp(2, fade.size.height - 2),
    ),
  );
  List<int>? result;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final p = (point.dy.floor() * image.width + point.dx.floor()) * 4;
      result = [for (var c = 0; c < 4; c++) bytes!.getUint8(p + c)];
    } finally {
      image.dispose();
    }
  });
  return result!;
}

Future<void> _retainedProof(
  WidgetTester tester,
  RenderZyraPhotoTextFade retained,
  RenderAbstractViewport viewport,
  double oldDarkTop,
  String action,
) async {
  final current = tester.renderObject<RenderZyraPhotoTextFade>(
    find.byType(ZyraPhotoTextFade),
  );
  final currentViewport = RenderAbstractViewport.of(
    tester.renderObject(find.text('Reading line over photo').first),
  );
  expect(identical(current, retained), isTrue);
  expect(identical(currentViewport, viewport), isTrue);
  expect(viewport.isRepaintBoundary, isTrue);
  expect(current.fadeGeometry.darkTop, lessThan(oldDarkTop));
  // Sample normal UI pixels first. Calling the auditor here would recursively
  // force a repaint and could conceal a retained-display-list regression.
  final normal = await _retainedPixel(tester, current);
  current.markNeedsPaint();
  await tester.pump();
  final forced = await _retainedPixel(tester, current);
  final alpha = (255 - normal[0]) / (255 - 10);
  _retainedObservations.add({
    'action': action,
    'same_fade_and_viewport': true,
    'viewport_repaint_boundary': viewport.isRepaintBoundary,
    'normal_ui_rgba': normal,
    'forced_parent_rgba': forced,
    'normal_dark_alpha_over_white': alpha,
    'auditor_called': false,
  });
  expect(normal, forced);
  expect(normal[3], 255);
  expect(alpha, greaterThanOrEqualTo(.70));
}

Future<void> _proof(WidgetTester tester, String state) async {
  final finder = find.byType(ZyraPhotoTextFade);
  expect(finder, findsOneWidget);
  final render = tester.renderObject<RenderZyraPhotoTextFade>(finder);
  final geometry = render.fadeGeometry;
  expect(geometry.firstTextTop, isNotNull);
  expect(
    geometry.darkTop,
    lessThanOrEqualTo(
      (geometry.firstTextTop! - 8).clamp(0.0, render.size.height),
    ),
  );
  expect(
    geometry.darkTop - geometry.clearTop,
    closeTo(render.size.height * .30, 1e-8),
  );
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  // Eight points before the first text line has no glyph ink. The centre
  // stays inside the card's existing rounded border even for a full dark band.
  final local = Offset(
    render.size.width / 2,
    geometry.darkTop.clamp(2, render.size.height - 2),
  );
  final point = MatrixUtils.transformPoint(
    render.getTransformTo(boundary),
    local,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final p = (point.dy.floor() * image.width + point.dx.floor()) * 4;
      expect(pixels!.getUint8(p + 3), 255);
      final bg = Color.fromARGB(
        255,
        pixels.getUint8(p),
        pixels.getUint8(p + 1),
        pixels.getUint8(p + 2),
      );
      expect(_contrast(Colors.white, bg), greaterThanOrEqualTo(4.5));
    } finally {
      image.dispose();
    }
  });
  final audit = await auditZyraRenderedText(tester, boundary);
  expect(audit.runs, greaterThan(0));
  final photoInkFailures = audit.failures
      .where(
        (failure) =>
            failure['source_ink']?.toString().endsWith('ffffff') ?? false,
      )
      .toList();
  _observations.add({
    'state': state,
    'card_height': render.size.height,
    'first_text_top': geometry.firstTextTop,
    'dark_top': geometry.darkTop,
    'clear_top': geometry.clearTop,
    'photo_ink_failures': photoInkFailures,
    'other_frame_findings': audit.failures
        .where(
          (failure) =>
              !(failure['source_ink']?.toString().endsWith('ffffff') ?? false),
        )
        .toList(),
  });
  expect(
    audit.failures.where((failure) => failure['coverage_error'] != null),
    isEmpty,
  );
  expect(
    photoInkFailures,
    isEmpty,
    reason:
        'Q190 white photo-reading ink; other frame findings are retained '
        'in build/line126-q190-photo-fade-proof.json and the full audit remains separate',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldStubs = ZyraText.useTestFontStubs;
  final oldFamily = ZyraText.testReadingFontFamily;
  setUpAll(() async {
    final loader = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
    ]) {
      loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await loader.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint()..color = Colors.white);
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      _white = MemoryImage(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
      picture.dispose();
    }
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFamily;
    File('build/line126-q190-photo-fade-proof.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'authority': 'Q190 / spec V9 Text on photos row62',
        'scope':
            'Measured photo fade and white reading ink only; not a full-frame or corpus pass',
        'prototype_nuance':
            'V324 Seeker .76 stop is28% of card (40% of70% scrim). Written30%-card transition is normative; locked RGB/bottom alpha retained.',
        'observations': _observations,
        'retained_paint_checks': _retainedObservations,
      }),
    );
  });

  testWidgets('Q190 retained live TextScaler updates normal fade pixels', (
    tester,
  ) async {
    final scale = ValueNotifier(1.0);
    addTearDown(scale.dispose);
    await _mountRetained(tester, scale, overflow: false);
    final fade = tester.renderObject<RenderZyraPhotoTextFade>(
      find.byType(ZyraPhotoTextFade),
    );
    final viewport = RenderAbstractViewport.of(
      tester.renderObject(find.text('Reading line over photo').first),
    );
    final oldTop = fade.fadeGeometry.darkTop;
    scale.value = 1.3;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await _retainedProof(
      tester,
      fade,
      viewport,
      oldTop,
      'live_text_scale_1_to_1.3',
    );
  });

  testWidgets('Q190 retained overlay scroll updates normal fade pixels', (
    tester,
  ) async {
    final scale = ValueNotifier(1.3);
    addTearDown(scale.dispose);
    await _mountRetained(tester, scale, overflow: true);
    final fade = tester.renderObject<RenderZyraPhotoTextFade>(
      find.byType(ZyraPhotoTextFade),
    );
    final viewport = RenderAbstractViewport.of(
      tester.renderObject(find.text('Reading line over photo').first),
    );
    final oldTop = fade.fadeGeometry.darkTop;
    final state = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('retained-photo-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(state.position.maxScrollExtent, greaterThan(8));
    state.position.jumpTo(8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.position.pixels, 8);
    await _retainedProof(
      tester,
      fade,
      viewport,
      oldTop,
      'overlay_scroll_0_to_8',
    );
  });

  for (final size in [const Size(430, 932), const Size(375, 667)]) {
    for (final scale in [1.0, 1.3]) {
      for (final scene in [
        'Seeker Basic',
        'Seeker One',
        'Guardian Basic',
        'Guardian One',
        'Profile',
      ]) {
        testWidgets('Q190 $scene white photo ${size.width.toInt()} @$scale', (
          tester,
        ) async {
          final Widget child;
          if (scene.startsWith('Seeker')) {
            child = ZyraOneJourneyTab(
              journeys: [
                ZyraJourneyTabCard(
                  id: 'sara',
                  firstName: 'Sara',
                  details: '27 · Birmingham',
                  stageNumber: 1,
                  stageLabel: 'Salam Exchange',
                  nextStep: 'Your next step · Exchange Salams',
                  photo: _white,
                ),
              ],
              capacity: scene.endsWith('Basic') ? 1 : 3,
              index: 0,
              sessionIdentity: Object(),
              onIndexChanged: (_) {},
              onContinue: () {},
              onOptions: () {},
              onBrowse: () {},
              onPlans: () {},
            );
          } else if (scene.startsWith('Guardian')) {
            child = Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 110),
              child: ZyraGuardianJourneyPager(
                cards: [
                  ZyraGuardianJourneyCard(
                    id: 'sara',
                    title: 'Adam & Sara',
                    details:
                        'Sara Ahmed · 27 · Birmingham · You: Main Guardian · ${scene.endsWith('Basic') ? 'View only' : 'View and Chat'}',
                    stageLine: 'Stage 4 of 8 · Family Review',
                    photo: _white,
                  ),
                ],
                index: 0,
                identity: Object(),
                onAction: (_) {},
              ),
            );
          } else {
            child = ZyraOneJourneyBrowsePresentation(
              profile: _profile,
              onMenu: () {},
              showMenu: false,
              imageBuilder: (_, _) => Image(image: _white, fit: BoxFit.cover),
            );
          }
          await _mount(tester, size, scale, child);
          await _proof(
            tester,
            '$scene ${size.width.toInt()}x${size.height.toInt()}@$scale',
          );
        });
      }
    }
  }

  for (final photo in ['', 'data:image/png;base64,invalid']) {
    testWidgets(
      'Q190 actual profile placeholder ${photo.isEmpty ? 'empty' : 'invalid'}',
      (tester) async {
        await _mount(
          tester,
          const Size(375, 667),
          1.3,
          ZyraOneJourneyBrowsePresentation(
            profile: SeekerProfile(
              id: 'missing',
              firstName: 'Sara',
              age: 27,
              city: 'Birmingham',
              gender: 'Female',
              photos: [photo],
            ),
            onMenu: () {},
            showMenu: false,
          ),
        );
        await _proof(
          tester,
          'placeholder ${photo.isEmpty ? 'empty' : 'invalid'} 375x667@1.3',
        );
      },
    );
  }
}
