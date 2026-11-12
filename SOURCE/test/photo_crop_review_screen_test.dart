import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zyra/models/zyra_profile_photo_geometry.dart';
import 'package:zyra/screens/profile/photo_crop_review_screen.dart';
import 'package:zyra/theme/zyra_text.dart';

Uint8List _portraitPhoto() {
  final source = img.Image(width: 300, height: 400);
  img.fill(source, color: img.ColorRgb8(92, 61, 112));
  return img.encodePng(source);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets('crop uses one direct confirmation action without a preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final photo = _portraitPhoto();
    await tester.pumpWidget(
      MaterialApp(home: PhotoCropReviewScreen(photos: [photo])),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Crop photo'), findsOneWidget);
    expect(find.text('Add Photo'), findsOneWidget);
    expect(find.textContaining('Pinch to zoom'), findsNothing);
    expect(find.text('Preview photo'), findsNothing);
    expect(find.byKey(const ValueKey('photo-preview')), findsNothing);
  });

  testWidgets('crop uses one full canvas without a nested frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final photo = _portraitPhoto();
    await tester.pumpWidget(
      MaterialApp(home: PhotoCropReviewScreen(photos: [photo])),
    );
    // The shared loading mark intentionally animates while the crop package
    // decodes, so this screen is not expected to become globally "settled".
    await tester.pump(const Duration(milliseconds: 500));

    final canvas = find.byKey(const ValueKey('photo-crop-canvas'));
    expect(canvas, findsOneWidget);
    final size = tester.getSize(canvas);
    expect(
      size.width / size.height,
      closeTo(zyraProfilePhotoAspectRatio, 0.001),
    );
    expect(find.textContaining('Pinch to zoom'), findsNothing);
  });

  for (final (viewport, portrait) in [
    (const Size(430, 932), true),
    (const Size(375, 667), false),
  ]) {
    testWidgets('uses the widest full crop at $viewport', (tester) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = img.Image(
        width: portrait ? 240 : 480,
        height: portrait ? 480 : 240,
      );
      img.fill(source, color: img.ColorRgb8(20, 20, 20));
      // Paint opposite source edges on the axis that must stay fully visible.
      for (final (start, end, color) in [
        (0, 10, img.ColorRgb8(240, 20, 20)),
        (229, 239, img.ColorRgb8(20, 240, 20)),
      ]) {
        img.fillRect(
          source,
          x1: portrait ? start : 0,
          y1: portrait ? 0 : start,
          x2: portrait ? end : source.width - 1,
          y2: portrait ? source.height - 1 : end,
          color: color,
        );
      }
      final photo = img.encodePng(source);
      List<Uint8List>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<List<Uint8List>>(
                      MaterialPageRoute(
                        builder: (_) => PhotoCropReviewScreen(photos: [photo]),
                      ),
                    );
                  },
                  child: const Text('Open crop'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open crop'));
      final confirm = find.byKey(const ValueKey('photo-crop-confirm'));
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 80; attempt++) {
          await tester.pump(const Duration(milliseconds: 20));
          if (confirm.evaluate().isNotEmpty &&
              tester.widget<FilledButton>(confirm).onPressed != null) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
        final guide = find.byKey(const ValueKey('photo-crop-guide'));
        final frame = tester.getSize(guide);
        final safeHeight = frame.width / (335 / 467);
        final inset = (frame.height - safeHeight) / 2;
        expect(inset, greaterThan(0));
        expect(
          guide,
          paints
            ..line()
            ..line()
            ..line()
            ..line()
            ..line(p1: Offset(0, inset), p2: Offset(frame.width, inset))
            ..line(
              p1: Offset(0, inset + safeHeight),
              p2: Offset(frame.width, inset + safeHeight),
            ),
        );
        await tester.tap(confirm);
        for (var attempt = 0; attempt < 80 && result == null; attempt++) {
          await tester.pump(const Duration(milliseconds: 20));
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      final crop = img.decodeImage(result!.single)!;
      expect(
        crop.width,
        closeTo(portrait ? 240 : 240 * zyraProfilePhotoAspectRatio, 1),
      );
      expect(
        crop.height,
        closeTo(portrait ? 240 / zyraProfilePhotoAspectRatio : 240, 1),
      );
      final first = crop.getPixel(
        portrait ? 2 : crop.width ~/ 2,
        portrait ? crop.height ~/ 2 : 2,
      );
      final last = crop.getPixel(
        portrait ? crop.width - 3 : crop.width ~/ 2,
        portrait ? crop.height ~/ 2 : crop.height - 3,
      );
      expect(first.r, greaterThan(200));
      expect(last.g, greaterThan(200));
    });
  }

  testWidgets('a photo batch uses Continue and reserves Finish for the last', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final photo = _portraitPhoto();
    await tester.pumpWidget(
      MaterialApp(home: PhotoCropReviewScreen(photos: [photo, photo, photo])),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);
  });
}
