import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zyra/screens/profile/zyra_profile_video_trim_screen.dart';
import 'package:zyra/theme/zyra_text.dart';

final _thumbnail = img.encodePng(img.Image(width: 8, height: 8));

ZyraProfileVideoTrimData _media() => ZyraProfileVideoTrimData(
  duration: const Duration(seconds: 32),
  frames: List<Uint8List>.filled(10, _thumbnail),
);

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  final strip = find.byKey(const ValueKey('profile-video-filmstrip'));
  final window = find.byKey(const ValueKey('profile-video-trim-window'));
  final preview = find.byKey(const ValueKey('profile-video-trim-preview'));

  for (final (size, top, bottom) in [
    (const Size(430, 932), 59.0, 34.0),
    (const Size(375, 667), 20.0, 0.0),
  ]) {
    testWidgets('fixed ten-second window stays in the filmstrip at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      (Duration, Duration, bool)? range;
      Duration? exportedStart;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: ZyraProfileVideoTrimScreen(
            load: () async => _media(),
            previewBuilder: (_, start, end, reduced) {
              range = (start, end, reduced);
              return const ColoredBox(color: Colors.brown);
            },
            onUse: (start) async => exportedStart = start,
            onChooseAnother: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rect = tester.getRect(strip);
      expect(tester.getSize(preview).width, size.width - 40);
      expect(rect.height, 56);
      expect(tester.getSize(window).width, closeTo(rect.width * 10 / 32, .001));
      expect(tester.getRect(window).left, rect.left);
      expect(find.byType(Image), findsNWidgets(10));
      expect(find.text('No sound'), findsOneWidget);
      expect(find.text('0:00 – 0:10'), findsOneWidget);
      expect(find.text('Video 0:32'), findsOneWidget);
      expect(range, (Duration.zero, const Duration(seconds: 10), true));

      await tester.tapAt(Offset(rect.left + rect.width / 4, rect.center.dy));
      await tester.pump();
      expect(find.text('0:08 – 0:18'), findsOneWidget);
      expect(range, (
        const Duration(seconds: 8),
        const Duration(seconds: 18),
        true,
      ));

      await tester.drag(window, Offset(-rect.width, 0));
      await tester.pump();
      expect(tester.getRect(window).left, closeTo(rect.left, .001));
      expect(find.text('0:00 – 0:10'), findsOneWidget);

      await tester.drag(window, Offset(rect.width, 0));
      await tester.pump();
      expect(tester.getRect(window).right, closeTo(rect.right, .001));
      expect(find.text('0:22 – 0:32'), findsOneWidget);

      await tester.tap(find.text('Use these 10 seconds'));
      await tester.pumpAndSettle();
      expect(exportedStart, const Duration(seconds: 22));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('VoiceOver adjusts the start in one-second steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraProfileVideoTrimScreen(
          load: () async => _media(),
          previewBuilder: (_, _, _, _) => const SizedBox(),
          onUse: (_) async {},
          onChooseAnother: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final slider = tester.getSemantics(strip);
    final initial = slider.getSemanticsData();
    expect(initial.value, 'Start 0:00, 10 seconds');
    expect(initial.hasAction(SemanticsAction.increase), isTrue);
    expect(initial.hasAction(SemanticsAction.decrease), isFalse);
    slider.owner!.performAction(slider.id, SemanticsAction.increase);
    await tester.pump();
    expect(find.text('0:01 – 0:11'), findsOneWidget);
    expect(slider.getSemanticsData().value, 'Start 0:01, 10 seconds');
    slider.owner!.performAction(slider.id, SemanticsAction.decrease);
    await tester.pump();
    expect(find.text('0:00 – 0:10'), findsOneWidget);
  });

  testWidgets('preparing and unavailable states offer the locked recovery', (
    tester,
  ) async {
    final load = Completer<ZyraProfileVideoTrimData>();
    var reopens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraProfileVideoTrimScreen(
          load: () => load.future,
          previewBuilder: (_, _, _, _) => const SizedBox(),
          onUse: (_) async {},
          onChooseAnother: () => reopens++,
        ),
      ),
    );
    expect(find.text('Preparing your video…'), findsOneWidget);
    expect(strip, findsNothing);
    load.completeError(StateError('Missing video'));
    await tester.pumpAndSettle();
    expect(find.text('This video couldn’t be opened'), findsOneWidget);
    expect(
      find.text('Try another video, or save it to your phone first.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Choose another video'));
    expect(reopens, 1);
  });
}
