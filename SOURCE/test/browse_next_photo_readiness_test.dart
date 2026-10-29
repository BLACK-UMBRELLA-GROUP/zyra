// Local prepared photographs only. No member, URL, service or disk cache.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_photo_renderer.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_profile_name_block.dart';

const _boundary = ValueKey('prepared-browse-paint');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Prepared Browse photographs must remain offline.');
  }
}

class _BrowseHost extends StatefulWidget {
  const _BrowseHost(this.renderer, this.profiles);

  final ZyraBrowseLocalPhotoRenderer renderer;
  final List<SeekerProfile> profiles;

  @override
  State<_BrowseHost> createState() => _BrowseHostState();
}

class _BrowseHostState extends State<_BrowseHost> {
  int selected = 0;
  int requests = 0;

  @override
  Widget build(BuildContext context) => ZyraOneJourneyBrowseDesigns(
    profiles: widget.profiles,
    selectedIndex: selected,
    design: ZyraOneJourneyBrowseDesign.portraitCard,
    photoBuilder: widget.renderer.build,
    onNext: () =>
        setState(() => selected = (selected + 1) % widget.profiles.length),
    onPrevious: () =>
        setState(() => selected = (selected - 1) % widget.profiles.length),
    onRequest: (_) => setState(() => requests++),
  );
}

Finder _key(String key) => find.byKey(ValueKey(key));

SeekerProfile _profile(String id, String name, List<String> photos) =>
    SeekerProfile(
      id: id,
      firstName: name,
      surnameLine: 'Fixture',
      age: 27,
      city: 'Birmingham',
      gender: 'female',
      photos: photos,
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
  expect(source, isNotNull);
  return source!;
}

Future<void> _ready(
  WidgetTester tester,
  ZyraBrowseLocalPhotoRenderer renderer,
  Iterable<String> sources,
) async {
  final prepared = await tester.runAsync(() => renderer.prepare(sources));
  expect(prepared, isTrue);
  for (final source in sources) {
    expect(renderer.isReady(source), isTrue);
  }
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  bool quiet = false,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: quiet,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(key: _boundary, child: child),
      ),
    ),
  );
  // Intentionally no settle: the very first painted frame must be ready.
  expect(tester.takeException(), isNull);
}

Future<void> _expectPixel(
  WidgetTester tester,
  String id,
  Color expected, {
  Offset? sampleAt,
}) async {
  final photo = _key('concept_browse_photo_swipe_$id');
  expect(photo, findsOneWidget);
  final photoRect = tester.getRect(photo);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final boundaryRect = tester.getRect(find.byKey(_boundary));
  final rgba = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final sample =
          sampleAt ?? Offset(photoRect.center.dx, photoRect.top + 30);
      final x = (sample.dx - boundaryRect.left).round();
      final y = (sample.dy - boundaryRect.top).round();
      final offset = (y * image.width + x) * 4;
      return [for (var c = 0; c < 4; c++) bytes!.getUint8(offset + c)];
    } finally {
      image.dispose();
    }
  });
  final argb = expected.toARGB32();
  final channels = [
    (argb >> 16) & 255,
    (argb >> 8) & 255,
    argb & 255,
    (argb >> 24) & 255,
  ];
  for (var channel = 0; channel < 4; channel++) {
    expect(
      rgba![channel],
      closeTo(channels[channel], 1),
      reason:
          'The actual first frame is the correct photo, not a blank or stale frame.',
    );
  }
}

void _expectIdentity(WidgetTester tester, String id) {
  final details = _key('concept_browse_details_$id');
  if (details.evaluate().isNotEmpty) {
    expect(details, findsOneWidget);
    expect(
      find.descendant(of: details, matching: find.byType(Image)),
      findsOneWidget,
    );
    _expectDetailsAvatar(tester, details);
    return;
  }
  expect(find.byType(ZyraProfileNameBlock), findsNothing);
  expect(_key('concept_browse_identity_$id'), findsNothing);
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'concept_browse_photo_${id}_',
          ),
    ),
    findsWidgets,
  );
}

void _expectDetailsAvatar(WidgetTester tester, Finder details) {
  final photo = find.descendant(of: details, matching: find.byType(Image));
  expect(photo, findsOneWidget);
  final image = tester.widget<Image>(photo);
  expect((image.width, image.height), (50, 50));
  expect(image.fit, BoxFit.cover);
  expect(image.alignment, Alignment.center);
  final frame = find.descendant(of: photo, matching: find.byType(RawImage));
  expect(frame, findsOneWidget);
  expect(tester.widget<RawImage>(frame).image, isNotNull);
}

Future<List<int>> _detailsFrame(
  WidgetTester tester,
  String id, {
  List<int>? expected,
}) async {
  final details = _key('concept_browse_details_$id');
  expect(details, findsOneWidget);
  final profile = tester
      .widget<_BrowseHost>(find.byType(_BrowseHost))
      .profiles
      .singleWhere((profile) => profile.id == id);
  expect(
    find.descendant(of: details, matching: find.text(profile.firstName)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: details, matching: find.text('Age')),
    findsOneWidget,
  );
  expect(
    find.descendant(of: details, matching: find.text('Location')),
    findsOneWidget,
  );
  expect(
    find.descendant(of: details, matching: find.byType(Image)),
    findsOneWidget,
  );
  _expectDetailsAvatar(tester, details);
  final viewport = tester.getRect(_key('concept_browse_photo_swipe_$id'));
  final detailsRect = tester.getRect(details);
  expect(detailsRect.left, closeTo(viewport.left, .01));
  expect(detailsRect.top, closeTo(viewport.top, .01));
  final boundaryFinder = find.byKey(_boundary);
  final boundaryRect = tester.getRect(boundaryFinder);
  final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final left = (viewport.left - boundaryRect.left + 2).round();
      final top = (viewport.top - boundaryRect.top + 2).round();
      final width = (viewport.width - 4).floor();
      final height = (viewport.height - 4).floor();
      return [
        for (var row = 0; row < height; row++)
          ...bytes!.buffer.asUint8List(
            ((top + row) * image.width + left) * 4,
            width * 4,
          ),
      ];
    } finally {
      image.dispose();
    }
  });
  expect(pixels, isNotEmpty);
  if (expected != null) {
    expect(pixels!.length, expected.length);
    var firstMismatch = -1;
    for (var index = 0; index < expected.length; index++) {
      if ((pixels[index] - expected[index]).abs() > 1) {
        firstMismatch = index;
        break;
      }
    }
    expect(
      firstMismatch,
      -1,
      reason:
          'The first Next/Back frame must paint the correct complete details page.',
    );
  }
  return pixels!;
}

Future<void> _advancePhoto(
  WidgetTester tester,
  String id,
  int photoIndex,
  Color expected,
) async {
  final pager = _key('concept_browse_photo_swipe_$id');
  final media = MediaQuery.of(tester.element(pager));
  await tester.tap(_key('concept_browse_photo_tap_$id'));
  await tester.pump();
  if (!media.disableAnimations && !media.accessibleNavigation) {
    // Inspect the first incoming sliver at 20% of the 420ms animation,
    // before settling can hide a blank or stale initial decode.
    await tester.pump(const Duration(milliseconds: 84));
    expect(
      tester.widget<PageView>(pager).controller!.page,
      inExclusiveRange(photoIndex, photoIndex + .5),
    );
    final viewport = tester.getRect(pager);
    final incoming = _key('concept_browse_photo_${id}_$photoIndex');
    final exposed = tester.getRect(incoming).intersect(viewport);
    expect(exposed.width, greaterThan(1));
    final images = tester
        .widgetList<RawImage>(
          find.descendant(of: incoming, matching: find.byType(RawImage)),
        )
        .toList();
    expect(images, isNotEmpty);
    expect(images.every((image) => image.image != null), isTrue);
    await _expectPixel(
      tester,
      id,
      expected,
      sampleAt: Offset(exposed.center.dx, viewport.top + 30),
    );
  } else {
    await _expectPixel(tester, id, expected);
  }
  await tester.pumpAndSettle();
}

Future<void> _firstPhoto(WidgetTester tester, String id, Color expected) async {
  expect(_key('concept_browse_details_$id'), findsOneWidget);
  await _advancePhoto(tester, id, 0, expected);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late bool previousFontStubs;
  late bool previousFatal;

  setUp(() {
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousFontStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
    previousFatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = previousFontStubs;
    WidgetController.hitTestWarningShouldBeFatal = previousFatal;
  });

  for (final quiet in [false, true]) {
    testWidgets('Next and Back have correct ready first pixels, quiet=$quiet', (
      tester,
    ) async {
      final red = await _source(tester, Colors.red);
      final blue = await _source(tester, Colors.blue);
      final renderer = ZyraBrowseLocalPhotoRenderer();
      addTearDown(renderer.dispose);
      await _ready(tester, renderer, [red, blue]);
      // Prepare an independent reference for Amira's complete details page.
      // The real Next/Back checks below inspect the first frame, without settle.
      await _mount(
        tester,
        _BrowseHost(renderer, [
          _profile('ready-amira', 'Amira', [blue]),
        ]),
        quiet: quiet,
      );
      final amiraDetails = await _detailsFrame(tester, 'ready-amira');
      await _mount(
        tester,
        _BrowseHost(renderer, [
          _profile('ready-sara', 'Sara', [red]),
          _profile('ready-amira', 'Amira', [blue]),
        ]),
        quiet: quiet,
      );
      _expectIdentity(tester, 'ready-sara');
      final saraDetails = await _detailsFrame(tester, 'ready-sara');
      await _firstPhoto(tester, 'ready-sara', Colors.red);
      await _expectPixel(tester, 'ready-sara', Colors.red);
      final card = tester.getRect(_key('concept_browse_portrait_card'));
      for (var repeat = 0; repeat < 3; repeat++) {
        await tester.tap(_key('concept_next_profile'));
        await tester.pump();
        _expectIdentity(tester, 'ready-amira');
        await _detailsFrame(tester, 'ready-amira', expected: amiraDetails);
        await _firstPhoto(tester, 'ready-amira', Colors.blue);
        await _expectPixel(tester, 'ready-amira', Colors.blue);
        expect(tester.getRect(_key('concept_browse_portrait_card')), card);
        await tester.tap(_key('concept_previous_profile'));
        await tester.pump();
        _expectIdentity(tester, 'ready-sara');
        await _detailsFrame(tester, 'ready-sara', expected: saraDetails);
        await _firstPhoto(tester, 'ready-sara', Colors.red);
        await _expectPixel(tester, 'ready-sara', Colors.red);
        expect(tester.getRect(_key('concept_browse_portrait_card')), card);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Details and three prepared photos form one complete gallery, quiet=$quiet',
      (tester) async {
        final sources = [
          await _source(tester, Colors.red),
          await _source(tester, Colors.blue),
          await _source(tester, Colors.green),
        ];
        final renderer = ZyraBrowseLocalPhotoRenderer();
        addTearDown(renderer.dispose);
        await _ready(tester, renderer, sources);
        await _mount(
          tester,
          _BrowseHost(renderer, [_profile('ready-sara', 'Sara', sources)]),
          quiet: quiet,
        );
        final tap = _key('concept_browse_photo_tap_ready-sara');
        _expectIdentity(tester, 'ready-sara');
        for (final (index, expected) in [
          Colors.red,
          Colors.blue,
          Colors.green,
        ].indexed) {
          await _advancePhoto(tester, 'ready-sara', index, expected);
          await _expectPixel(tester, 'ready-sara', expected);
        }
        await tester.tap(tap);
        await tester.pump();
        // Ordinary motion begins with the prepared outgoing photograph;
        // the incoming page is the dedicated public details surface.
        if (!quiet) {
          await _expectPixel(tester, 'ready-sara', Colors.green);
          await tester.pump(const Duration(milliseconds: 210));
          final images = tester.widgetList<RawImage>(find.byType(RawImage));
          expect(images, isNotEmpty);
          expect(images.every((image) => image.image != null), isTrue);
          await tester.pump(const Duration(milliseconds: 210));
        }
        await tester.pump(const Duration(milliseconds: 16));
        expect(_key('concept_browse_details_ready-sara'), findsOneWidget);
        _expectIdentity(tester, 'ready-sara');
        await _firstPhoto(tester, 'ready-sara', Colors.red);
        await _expectPixel(tester, 'ready-sara', Colors.red);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Rebuilds reuse the provider and resolve synchronously', (
    tester,
  ) async {
    final source = await _source(tester, Colors.red);
    final renderer = ZyraBrowseLocalPhotoRenderer();
    addTearDown(renderer.dispose);
    await _ready(tester, renderer, [source]);
    await _mount(
      tester,
      _BrowseHost(renderer, [
        _profile('ready-sara', 'Sara', [source]),
      ]),
    );
    await _firstPhoto(tester, 'ready-sara', Colors.red);
    final first = tester.widget<Image>(find.byType(Image)).image;
    await tester.tap(_key('draft_profile_ready-sara'));
    await tester.pump();
    final second = tester.widget<Image>(find.byType(Image)).image;
    expect(identical(first, second), isTrue);
    expect(tester.widget<Image>(find.byType(Image)).gaplessPlayback, isFalse);
    final stream = second.resolve(const ImageConfiguration());
    var delivered = false;
    final listener = ImageStreamListener((image, synchronous) {
      delivered = true;
      expect(synchronous, isTrue);
      image.dispose();
    });
    stream.addListener(listener);
    expect(delivered, isTrue);
    stream.removeListener(listener);
    await _expectPixel(tester, 'ready-sara', Colors.red);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unprepared and nonlocal sources never construct a provider', (
    tester,
  ) async {
    final renderer = ZyraBrowseLocalPhotoRenderer();
    addTearDown(renderer.dispose);
    final local = await _source(tester, Colors.blue);
    await _mount(
      tester,
      Builder(
        builder: (context) => Column(
          children: [
            for (final source in [
              local,
              'https://member.example.invalid/signed.jpg',
            ])
              renderer.build(
                context,
                source,
                width: 100,
                height: 100,
                alignment: Alignment.topCenter,
              ),
          ],
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(ZyraProfileImage), findsNWidgets(2));
    expect(renderer.isReady(local), isFalse);
    expect(
      await renderer.prepare(['https://member.example.invalid/signed.jpg']),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'The protected wrapper sanitises sources before an injected builder',
    (tester) async {
      final received = <String>[];
      await _mount(
        tester,
        ZyraOneJourneyBrowseDesigns(
          profiles: [
            _profile('nonlocal', 'Nadia', [
              'https://member.example.invalid/signed.jpg',
            ]),
          ],
          selectedIndex: 0,
          design: ZyraOneJourneyBrowseDesign.portraitCard,
          photoBuilder:
              (
                context,
                source, {
                required width,
                required height,
                required alignment,
              }) {
                received.add(source);
                return const ColoredBox(color: Colors.grey);
              },
        ),
      );
      expect(
        received,
        [''],
        reason: 'The avatar invokes only the wrapper-sanitised first source.',
      );
      await tester.tap(_key('concept_browse_photo_tap_nonlocal'));
      await tester.pumpAndSettle();
      expect(received, isNotEmpty);
      expect(received.every((source) => source.isEmpty), isTrue);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final invalid in [
    'data:image/png;base64,%%%invalid',
    'data:image/png;base64,',
    'data:image/png,not-base64',
    'data:image/png;base64,YmFk',
  ]) {
    testWidgets('Malformed local image preparation fails closed: $invalid', (
      tester,
    ) async {
      final renderer = ZyraBrowseLocalPhotoRenderer();
      addTearDown(renderer.dispose);
      final result = await tester.runAsync(() => renderer.prepare([invalid]));
      expect(result, isFalse);
      expect(renderer.isReady(invalid), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Replacement revokes the prior source and pending preparation', (
    tester,
  ) async {
    final red = await _source(tester, Colors.red);
    final blue = await _source(tester, Colors.blue);
    final renderer = ZyraBrowseLocalPhotoRenderer();
    addTearDown(renderer.dispose);
    final results = await tester.runAsync(() async {
      final old = renderer.prepare([red]);
      final replacement = renderer.prepare([blue]);
      return (old: await old, replacement: await replacement);
    });
    expect(results!.old, isFalse);
    expect(results.replacement, isTrue);
    expect(renderer.isReady(red), isFalse);
    expect(renderer.isReady(blue), isTrue);
    await _mount(
      tester,
      _BrowseHost(renderer, [
        _profile('ready-amira', 'Amira', [blue]),
      ]),
    );
    await _firstPhoto(tester, 'ready-amira', Colors.blue);
    await _expectPixel(tester, 'ready-amira', Colors.blue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Disposal revokes pending work and cannot prepare or render again',
    (tester) async {
      final source = await _source(tester, Colors.red);
      final renderer = ZyraBrowseLocalPhotoRenderer();
      final result = await tester.runAsync(() async {
        final preparation = renderer.prepare([source]);
        renderer.dispose();
        renderer.dispose();
        return await preparation;
      });
      expect(result, isFalse);
      expect(renderer.isReady(source), isFalse);
      expect(await renderer.prepare([source]), isFalse);
      await _mount(
        tester,
        Builder(
          builder: (context) => renderer.build(
            context,
            source,
            width: 100,
            height: 100,
            alignment: Alignment.topCenter,
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('An oversized allowlist is rejected and revokes old frames', (
    tester,
  ) async {
    final source = await _source(tester, Colors.red);
    final renderer = ZyraBrowseLocalPhotoRenderer();
    addTearDown(renderer.dispose);
    await _ready(tester, renderer, [source]);
    final body = source.substring(source.indexOf(',') + 1);
    final tooMany = [
      for (var i = 0; i <= ZyraBrowseLocalPhotoRenderer.maximumSources; i++)
        'data:image/png;fixture=$i;base64,$body',
    ];
    expect(await renderer.prepare(tooMany), isFalse);
    expect(renderer.isReady(source), isFalse);
    expect(tooMany.any(renderer.isReady), isFalse);
    expect(tester.takeException(), isNull);
  });
}
