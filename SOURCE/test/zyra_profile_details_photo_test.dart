// LOCK 4: caller-admitted Details-card photo and unchanged identity geometry.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_loading.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

const _person = SeekerProfile(
  id: 'details-avatar-person',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  publicNationality: 'British',
  publicEthnicity: 'South Asian',
  gender: 'female',
  photos: ['caller-admitted-first', 'caller-admitted-second'],
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Details avatar tests must use caller-admitted images.');
  }
}

Finder _avatar() => find.byKey(
  const ValueKey('concept_browse_details_avatar_details-avatar-person'),
);
Finder _photo() => find.byKey(
  const ValueKey('concept_browse_details_avatar_photo_details-avatar-person'),
);

({MemoryImage provider, Completer<ImageInfo> frame}) _pending(int id) {
  // The cache owns this synthetic provider before mounting. No decoder or
  // transport is used; completing its real ImageStream supplies the frame.
  final provider = MemoryImage(Uint8List.fromList([id, 2, 3, 4]));
  final frame = Completer<ImageInfo>();
  PaintingBinding.instance.imageCache.putIfAbsent(
    provider,
    () => OneFrameImageStreamCompleter(frame.future),
  );
  return (provider: provider, frame: frame);
}

Future<ui.Image> _pixels(WidgetTester tester, Color color) async {
  final pixels = (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..color = color);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(4, 4);
    } finally {
      picture.dispose();
    }
  }))!;
  addTearDown(pixels.dispose);
  return pixels;
}

Future<void> _mount(WidgetTester tester, {Widget? firstPhoto}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            height: 700,
            child: ZyraProfileDetailsPage(
              profile: _person,
              firstPhoto: firstPhoto,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

void _expectFallback(WidgetTester tester) {
  final icon = find.descendant(
    of: _avatar(),
    matching: find.byIcon(Icons.person_outline),
  );
  expect(icon, findsOneWidget);
  expect(tester.widget<Icon>(icon).size, 29);
  expect(tester.widget<Icon>(icon).color, ZyraColors.journeyGold);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byType(LinearProgressIndicator), findsNothing);
  expect(find.byType(ZyraLoading), findsNothing);
  expect(find.byIcon(Icons.broken_image), findsNothing);
}

Map<String, Rect> _identityGeometry(WidgetTester tester) => {
  for (final value in [
    'Sara',
    'Ahmed',
    'Age',
    '27',
    'Location',
    'Birmingham',
    'Nationality',
    'British',
    'Ethnicity',
    'South Asian',
  ])
    value: tester.getRect(find.text(value)),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousHttp = HttpOverrides.current;
  final previousStubs = ZyraText.useTestFontStubs;
  late _NoNetwork network;

  setUp(() {
    ZyraText.useTestFontStubs = true;
    network = _NoNetwork();
    HttpOverrides.global = network;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousHttp;
    ZyraText.useTestFontStubs = previousStubs;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('missing caller photo keeps the existing gold-ring person icon', (
    tester,
  ) async {
    await _mount(tester);
    _expectFallback(tester);
    expect(tester.getSize(_avatar()), const Size(56, 56));
    expect(_photo(), findsNothing);
    expect(find.byType(Image), findsNothing);
    final decoration =
        tester.widget<Container>(_avatar()).decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(
      (decoration.border! as Border).top.color,
      ZyraColors.journeyGold.withValues(alpha: .65),
    );
    expect(decoration.boxShadow!.single.blurRadius, 24);
    expect(
      decoration.boxShadow!.single.color,
      ZyraColors.journeyGold.withValues(alpha: .07),
    );
  });

  testWidgets(
    'loaded photo fits the unchanged ring and leaves identity fixed',
    (tester) async {
      await _mount(tester);
      final before = _identityGeometry(tester);
      final stream = _pending(1);
      final pixels = await _pixels(tester, Colors.teal);
      stream.frame.complete(ImageInfo(image: pixels.clone()));
      await _mount(
        tester,
        firstPhoto: Image(
          image: stream.provider,
          fit: BoxFit.fill,
          alignment: Alignment.bottomRight,
        ),
      );
      await tester.pump();
      final outer = tester.getRect(_avatar());
      final photo = tester.getRect(_photo());
      final decoration =
          tester.widget<Container>(_avatar()).decoration! as BoxDecoration;
      final ring = (decoration.border! as Border).top.width;
      expect(outer.size, const Size(56, 56));
      expect(photo.size, const Size(50, 50));
      expect(photo.left - outer.left - ring, 2);
      expect(outer.right - photo.right - ring, 2);
      expect(photo.top - outer.top - ring, 2);
      expect(outer.bottom - photo.bottom - ring, 2);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, same(stream.provider));
      expect(image.fit, BoxFit.cover);
      expect(image.alignment, Alignment.center);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(_identityGeometry(tester), before);
    },
  );

  testWidgets(
    'pending and failed real Image frames use the icon without a loader',
    (tester) async {
      final stream = _pending(2);
      await _mount(tester, firstPhoto: Image(image: stream.provider));
      _expectFallback(tester);
      expect(find.byType(RawImage), findsNothing);
      final before = _identityGeometry(tester);
      stream.frame.completeError(
        StateError('Synthetic admitted-photo decode failure'),
      );
      await tester.pump();
      await tester.pump();
      _expectFallback(tester);
      expect(tester.getSize(_avatar()), const Size(56, 56));
      expect(_identityGeometry(tester), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'source replacement never shows the previous photo while waiting',
    (tester) async {
      final first = _pending(3);
      final firstPixels = await _pixels(tester, Colors.teal);
      first.frame.complete(ImageInfo(image: firstPixels.clone()));
      await _mount(
        tester,
        firstPhoto: Image(image: first.provider, gaplessPlayback: true),
      );
      await tester.pump();
      expect(find.byType(RawImage), findsOneWidget);
      final before = _identityGeometry(tester);
      final next = _pending(4);
      await _mount(
        tester,
        firstPhoto: Image(image: next.provider, gaplessPlayback: true),
      );
      _expectFallback(tester);
      expect(find.byType(RawImage), findsNothing);
      expect(tester.widget<Image>(find.byType(Image)).gaplessPlayback, isFalse);
      final nextPixels = await _pixels(tester, Colors.blue);
      next.frame.complete(ImageInfo(image: nextPixels.clone()));
      await tester.pump();
      await tester.pump();
      expect(find.byType(RawImage), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(_identityGeometry(tester), before);
    },
  );

  for (final source in ['', 'data:image/png;base64,%%%']) {
    testWidgets('shared photo failure stays scoped to the avatar: $source', (
      tester,
    ) async {
      await _mount(
        tester,
        firstPhoto: ZyraProfileImage(
          source,
          width: 50,
          height: 50,
          showLoader: true,
        ),
      );
      _expectFallback(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ZyraProfileImage(source, width: 50, height: 50)),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(find.byType(ZyraProfileImageFallback), findsNothing);
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(ZyraProfileImage),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        ZyraColors.luxuryDarkPurple,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
