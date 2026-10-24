import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
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

  testWidgets('crop uses one full 3:4 canvas without a nested frame', (
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
    expect(size.width / size.height, closeTo(3 / 4, 0.001));
    expect(find.textContaining('Pinch to zoom'), findsNothing);
  });

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
