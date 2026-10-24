// Candidate-only real-font review captures. Approved goldens are untouched.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/profile_ready_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

import '../profile_ready_screen_test.dart' show ReviewRepository, snapshot;

const _capture = bool.fromEnvironment('ZYRA_ONBOARDING_REVIEW_CAPTURE');
const _boundary = ValueKey('onboarding-review-candidate');

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsReviewAudit');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneReviewAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsReviewAudit';
    ZyraText.testWordmarkFontFamily = 'SyneReviewAudit';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });
  tearDown(() => ZyraDeveloperAccess.resetAuthorizationForTesting());

  for (final (label, state, size, scale) in [
    ('ready', snapshot(), const Size(390, 844), 1.0),
    ('incomplete', snapshot(missing: 3), const Size(390, 844), 1.0),
    ('live', snapshot(complete: true), const Size(390, 844), 1.0),
    ('compact_large_text', snapshot(), const Size(320, 568), 1.4),
  ]) {
    testWidgets('review $label is readable with safe fixed actions', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = ReviewRepository()..value = state;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: RepaintBoundary(key: _boundary, child: child!),
          ),
          home: ProfileReadyScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('profile_review_my_zyra')).hitTestable(),
        findsOneWidget,
      );
      expect(repository.publications, 0);
      if (!_capture) return;
      expect(autoUpdateGoldenFiles, isTrue);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_boundary),
      );
      final image = await tester.runAsync(() => boundary.toImage());
      try {
        final data = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.png),
        );
        await tester.runAsync(
          () => expectLater(
            data!.buffer.asUint8List(),
            matchesGoldenFile(
              'candidates/onboarding_full_cleanup_2026_10_02/review_$label.png',
            ),
          ),
        );
      } finally {
        image?.dispose();
      }
      if (label == 'compact_large_text') {
        await tester.ensureVisible(find.text('Review choices'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final lower = await tester.runAsync(() => boundary.toImage());
        try {
          final data = await tester.runAsync(
            () => lower!.toByteData(format: ui.ImageByteFormat.png),
          );
          await tester.runAsync(
            () => expectLater(
              data!.buffer.asUint8List(),
              matchesGoldenFile(
                'candidates/onboarding_full_cleanup_2026_10_02/review_${label}_lower.png',
              ),
            ),
          );
        } finally {
          lower?.dispose();
        }
      }
    });
  }
}
