// Public Browse presentation with prepared local colour photographs. Pixel
// checks distinguish a horizontal wrap from a dissolve or blank decode frame.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_photo_renderer.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_profile_name_block.dart';

const _id = 'wrap-motion-sara';
const _boundary = ValueKey('browse-wrap-motion-paint');

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _tap => _key('concept_browse_photo_tap_$_id');
Finder get _pager => _key('concept_browse_photo_swipe_$_id');
Finder get _outgoing => _key('concept_browse_photo_wrap_$_id');
Finder get _incoming => _key('concept_browse_photo_wrap_incoming_$_id');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Photo-wrap fixtures must remain offline.');
  }
}

class _PhotoHost extends StatefulWidget {
  const _PhotoHost(this.renderer, this.sources);

  final ZyraBrowseLocalPhotoRenderer renderer;
  final List<String> sources;

  @override
  State<_PhotoHost> createState() => _PhotoHostState();
}

class _PhotoHostState extends State<_PhotoHost> {
  int decisions = 0;

  @override
  Widget build(BuildContext context) => ZyraBrowseDesigns(
    key: const ValueKey('wrap-motion-browse'),
    profiles: [
      SeekerProfile(
        id: _id,
        firstName: 'Sara',
        surnameLine: 'Fixture',
        age: 27,
        city: 'Birmingham',
        gender: 'female',
        photos: widget.sources,
      ),
    ],
    selectedIndex: 0,
    design: ZyraOneJourneyBrowseDesign.portraitCard,
    photoBuilder: widget.renderer.build,
    showSave: false,
    onNext: () => decisions++,
    onPrevious: () => decisions++,
    onRequest: (_) => decisions++,
    onProfile: (_) => decisions++,
  );
}

Widget _app(Widget body, {bool quiet = false, bool accessible = false}) =>
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: quiet,
          accessibleNavigation: accessible,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(key: _boundary, child: body),
      ),
    );

Future<String> _source(WidgetTester tester, Color color) async {
  final source = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..color = color);
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 4);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return 'data:image/png;base64,${base64Encode(bytes!.buffer.asUint8List())}';
    } finally {
      image.dispose();
      picture.dispose();
    }
  });
  return source!;
}

Future<void> _mount(
  WidgetTester tester,
  ZyraBrowseLocalPhotoRenderer renderer,
  List<String> sources, {
  bool quiet = false,
  bool accessible = false,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  expect(await tester.runAsync(() => renderer.prepare(sources)), isTrue);
  await tester.pumpWidget(
    _app(_PhotoHost(renderer, sources), quiet: quiet, accessible: accessible),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _selected(WidgetTester tester, int index) {
  final dot = tester.widget<AnimatedContainer>(
    _key('concept_browse_photo_dot_${_id}_$index'),
  );
  expect(dot.constraints!.maxWidth, 20);
  expect(dot.constraints!.maxHeight, 5);
  expect((dot.decoration! as BoxDecoration).color, ZyraColors.journeyGold);
  expect(tester.widget<PageView>(_pager).controller!.page, closeTo(index, .01));
  expect(tester.state<_PhotoHostState>(find.byType(_PhotoHost)).decisions, 0);
}

Future<void> _last(WidgetTester tester, int count) async {
  for (var index = 1; index <= count; index++) {
    await tester.tap(_tap);
    await tester.pumpAndSettle();
    _selected(tester, index);
  }
}

void _details(WidgetTester tester) {
  final details = _key('concept_browse_details_$_id');
  expect(details, findsOneWidget);
  expect(
    find.descendant(of: details, matching: find.byType(RawImage)),
    findsNothing,
  );
  expect(
    find.descendant(of: details, matching: find.byType(ZyraProfileNameBlock)),
    findsNothing,
  );
}

typedef _FramePixels = ({List<int> left, List<int> right});

Future<_FramePixels> _readPixels(WidgetTester tester) async {
  final viewport = tester.getRect(_tap);
  final boundaryRect = tester.getRect(find.byKey(_boundary));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      List<int> at(double fraction) {
        final x =
            (viewport.left + viewport.width * fraction - boundaryRect.left)
                .round();
        final y = (viewport.top + 30 - boundaryRect.top).round();
        final offset = (y * image.width + x) * 4;
        return [for (var c = 0; c < 4; c++) bytes!.getUint8(offset + c)];
      }

      return (left: at(.25), right: at(.75));
    } finally {
      image.dispose();
    }
  });
  return pixels!;
}

List<int> _rgba(Color color) {
  final argb = color.toARGB32();
  return [
    (argb >> 16) & 255,
    (argb >> 8) & 255,
    argb & 255,
    (argb >> 24) & 255,
  ];
}

Future<void> _pixels(
  WidgetTester tester,
  List<int> left,
  List<int> right,
) async {
  final pixels = await _readPixels(tester);
  void matches(List<int> actual, List<int> expected, String side) {
    for (var c = 0; c < 4; c++) {
      expect(
        actual[c],
        closeTo(expected[c], 1),
        reason:
            '$side must match its prepared photo or captured details frame.',
      );
    }
  }

  matches(pixels.left, left, 'Left quarter');
  matches(pixels.right, right, 'Right quarter');
}

Future<void> _photoPixels(WidgetTester tester, Color left, Color right) =>
    _pixels(tester, _rgba(left), _rgba(right));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late bool previousFontStubs;

  setUp(() {
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousFontStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = previousFontStubs;
  });

  for (final count in [2, 3]) {
    testWidgets(
      '$count-photo gallery scrolls from its last photo to details over 420ms',
      (tester) async {
        final colors = [Colors.red, Colors.blue, if (count == 3) Colors.green];
        final sources = [
          for (final color in colors) await _source(tester, color),
        ];
        final renderer = ZyraBrowseLocalPhotoRenderer();
        addTearDown(renderer.dispose);
        await _mount(tester, renderer, sources);
        final detailsPixels = await _readPixels(tester);
        await _last(tester, count);
        final card = tester.getRect(_key('concept_browse_portrait_card'));
        final footer = tester.getRect(_key('concept_browse_footer'));
        final pagination = tester.getRect(
          _key('concept_browse_photo_pagination'),
        );
        await tester.tap(_tap);
        await tester.pump();
        _selected(tester, 0);
        expect(_incoming, findsOneWidget);
        expect(_outgoing, findsOneWidget);
        expect(
          tester.widget<SlideTransition>(_incoming).position.value.dx,
          closeTo(1, .001),
        );
        expect(
          tester.widget<SlideTransition>(_outgoing).position.value.dx,
          closeTo(0, .001),
        );
        await _photoPixels(tester, colors.last, colors.last);

        await tester.tap(_tap);
        await tester.pump(const Duration(milliseconds: 210));
        expect(
          tester.widget<SlideTransition>(_incoming).position.value.dx,
          closeTo(.5, .025),
        );
        expect(
          tester.widget<SlideTransition>(_outgoing).position.value.dx,
          closeTo(-.5, .025),
        );
        expect(
          find.descendant(of: _incoming, matching: find.byType(FadeTransition)),
          findsNothing,
        );
        expect(
          find.descendant(of: _outgoing, matching: find.byType(FadeTransition)),
          findsNothing,
        );
        // At half translation the right quarter exposes the details page's
        // original left quarter. Compare all RGBA channels to its steady frame.
        await _pixels(tester, _rgba(colors.last), detailsPixels.left);
        _details(tester);
        expect(
          tester
              .widgetList<RawImage>(find.byType(RawImage))
              .every((image) => image.image != null),
          isTrue,
        );
        expect(tester.getRect(_key('concept_browse_portrait_card')), card);
        expect(tester.getRect(_key('concept_browse_footer')), footer);
        expect(
          tester.getRect(_key('concept_browse_photo_pagination')),
          pagination,
        );
        _selected(tester, 0);

        await tester.tap(_tap);
        await tester.pump(const Duration(milliseconds: 10));
        expect(
          tester.widget<SlideTransition>(_incoming).position.value.dx,
          inExclusiveRange(0, .5),
        );
        await tester.pump(const Duration(milliseconds: 200));
        _details(tester);
        await _pixels(tester, detailsPixels.left, detailsPixels.right);
        await tester.pump(const Duration(milliseconds: 16));
        expect(_incoming, findsOneWidget);
        expect(
          tester.widget<SlideTransition>(_incoming).position.value,
          Offset.zero,
        );
        expect(_outgoing, findsNothing);
        _selected(tester, 0);
        _details(tester);
        await _pixels(tester, detailsPixels.left, detailsPixels.right);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Previous page semantics wraps from details to the last photo with horizontal motion',
    (tester) async {
      final sources = [
        await _source(tester, Colors.red),
        await _source(tester, Colors.blue),
        await _source(tester, Colors.green),
      ];
      final renderer = ZyraBrowseLocalPhotoRenderer();
      addTearDown(renderer.dispose);
      await _mount(tester, renderer, sources);
      final detailsPixels = await _readPixels(tester);
      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Profile details',
        ),
      );
      // Read the actual logical-gallery semantic action, not a profile
      // navigation callback. Spaces are retained in its public label.
      semantics.properties.customSemanticsActions!.entries
          .singleWhere((entry) => entry.key.label == 'Previous page')
          .value();
      await tester.pump();
      _selected(tester, 3);
      await tester.pump(const Duration(milliseconds: 210));
      expect(
        tester.widget<SlideTransition>(_incoming).position.value.dx,
        closeTo(-.5, .025),
      );
      expect(
        tester.widget<SlideTransition>(_outgoing).position.value.dx,
        closeTo(.5, .025),
      );
      await _pixels(tester, _rgba(Colors.green), detailsPixels.left);
      await tester.pump(const Duration(milliseconds: 226));
      expect(_incoming, findsOneWidget);
      expect(
        tester.widget<SlideTransition>(_incoming).position.value,
        Offset.zero,
      );
      expect(_outgoing, findsNothing);
      _selected(tester, 3);
      await _photoPixels(tester, Colors.green, Colors.green);
      expect(tester.takeException(), isNull);
    },
  );

  for (final accessible in [false, true]) {
    testWidgets(
      'Quiet wrap is immediate with no translation, accessible=$accessible',
      (tester) async {
        final sources = [
          await _source(tester, Colors.red),
          await _source(tester, Colors.blue),
          await _source(tester, Colors.green),
        ];
        final renderer = ZyraBrowseLocalPhotoRenderer();
        addTearDown(renderer.dispose);
        await _mount(
          tester,
          renderer,
          sources,
          quiet: !accessible,
          accessible: accessible,
        );
        final detailsPixels = await _readPixels(tester);
        await _last(tester, 3);
        await tester.tap(_tap);
        await tester.pump();
        expect(_incoming, findsOneWidget);
        expect(
          tester.widget<SlideTransition>(_incoming).position.value,
          Offset.zero,
        );
        expect(_outgoing, findsNothing);
        _selected(tester, 0);
        _details(tester);
        await _pixels(tester, detailsPixels.left, detailsPixels.right);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'A drag from the outgoing left photograph cancels wrap translation',
    (tester) async {
      final sources = [
        await _source(tester, Colors.red),
        await _source(tester, Colors.blue),
        await _source(tester, Colors.green),
      ];
      final renderer = ZyraBrowseLocalPhotoRenderer();
      addTearDown(renderer.dispose);
      await _mount(tester, renderer, sources);
      final detailsPixels = await _readPixels(tester);
      await _last(tester, 3);
      await tester.tap(_tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      await _pixels(tester, _rgba(Colors.green), detailsPixels.left);
      final viewport = tester.getRect(_tap);
      final finger = await tester.startGesture(
        Offset(viewport.left + viewport.width * .25, viewport.center.dy),
      );
      await finger.moveBy(const Offset(-80, 0));
      await tester.pump();
      expect(_outgoing, findsNothing);
      expect(
        tester.widget<SlideTransition>(_incoming).position.value,
        Offset.zero,
      );
      expect(
        tester
            .widget<PageView>(_pager)
            .controller!
            .position
            .isScrollingNotifier
            .value,
        isTrue,
      );
      await finger.moveBy(const Offset(-180, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await finger.up();
      await tester.pumpAndSettle();
      _selected(tester, 1);
      await _photoPixels(tester, Colors.red, Colors.red);
      await tester.pump(const Duration(milliseconds: 500));
      expect(_outgoing, findsNothing);
      expect(
        tester.widget<SlideTransition>(_incoming).position.value,
        Offset.zero,
      );
      _selected(tester, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reduced motion enabled mid-wrap settles immediately with no later translation',
    (tester) async {
      final sources = [
        await _source(tester, Colors.red),
        await _source(tester, Colors.blue),
        await _source(tester, Colors.green),
      ];
      final renderer = ZyraBrowseLocalPhotoRenderer();
      addTearDown(renderer.dispose);
      await _mount(tester, renderer, sources);
      final detailsPixels = await _readPixels(tester);
      await _last(tester, 3);
      await tester.tap(_tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_outgoing, findsOneWidget);
      expect(
        tester.widget<SlideTransition>(_incoming).position.value.dx,
        inExclusiveRange(0, 1),
      );
      await tester.pumpWidget(_app(_PhotoHost(renderer, sources), quiet: true));
      await tester.pump();
      expect(_outgoing, findsNothing);
      expect(
        tester.widget<SlideTransition>(_incoming).position.value,
        Offset.zero,
      );
      _selected(tester, 0);
      _details(tester);
      await _pixels(tester, detailsPixels.left, detailsPixels.right);
      await tester.pump(const Duration(milliseconds: 500));
      expect(_outgoing, findsNothing);
      expect(
        tester.widget<SlideTransition>(_incoming).position.value,
        Offset.zero,
      );
      _selected(tester, 0);
      _details(tester);
      await _pixels(tester, detailsPixels.left, detailsPixels.right);
      expect(tester.takeException(), isNull);
    },
  );

  for (final change in ['source replacement', 'disposal']) {
    testWidgets('Wrap translation is revoked by $change with no late motion', (
      tester,
    ) async {
      final sources = [
        await _source(tester, Colors.red),
        await _source(tester, Colors.blue),
        await _source(tester, Colors.green),
      ];
      final replacement = [
        await _source(tester, Colors.purple),
        await _source(tester, Colors.orange),
      ];
      final renderer = ZyraBrowseLocalPhotoRenderer();
      addTearDown(renderer.dispose);
      // All explicitly supplied local frames are ready before changing the
      // source list; no replacement decodes behind an old identity.
      expect(
        await tester.runAsync(
          () => renderer.prepare([...sources, ...replacement]),
        ),
        isTrue,
      );
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(_PhotoHost(renderer, sources)));
      await tester.pumpAndSettle();
      final detailsPixels = await _readPixels(tester);
      await _last(tester, 3);
      await tester.tap(_tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_incoming, findsOneWidget);
      await tester.pumpWidget(
        change == 'disposal'
            ? const SizedBox.shrink()
            : _app(_PhotoHost(renderer, replacement)),
      );
      await tester.pump();
      expect(_incoming, change == 'disposal' ? findsNothing : findsOneWidget);
      if (change != 'disposal') {
        expect(
          tester.widget<SlideTransition>(_incoming).position.value,
          Offset.zero,
        );
      }
      expect(_outgoing, findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_incoming, change == 'disposal' ? findsNothing : findsOneWidget);
      if (change != 'disposal') {
        expect(
          tester.widget<SlideTransition>(_incoming).position.value,
          Offset.zero,
        );
      }
      expect(_outgoing, findsNothing);
      if (change != 'disposal') {
        _selected(tester, 0);
        _details(tester);
        await _pixels(tester, detailsPixels.left, detailsPixels.right);
        await tester.tap(_tap);
        await tester.pumpAndSettle();
        _selected(tester, 1);
        await _photoPixels(tester, Colors.purple, Colors.purple);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
