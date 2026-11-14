import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/profile/zyra_manage_profile_video.dart';
import 'package:zyra/services/zyra_profile_video_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_guardian_add_card.dart';

const _captureFont = 'PhotosCapturePoppins';
const _capture = ValueKey('profile-video-photos-capture');
const _directory = String.fromEnvironment(
  'ZYRA_PROFILE_VIDEO_CAPTURE_DIRECTORY',
);

class _Store implements ZyraProfileVideoStore {
  ZyraProfileVideoRecord? record;
  ZyraProfileVideoRefusal? refusal;
  int reads = 0;
  int writes = 0;
  int removes = 0;

  @override
  Future<ZyraProfileVideoRecord?> loadOwn() async {
    reads++;
    return record;
  }

  @override
  Future<Uint8List> readOwn(ZyraProfileVideoRecord record) async =>
      Uint8List(0);

  @override
  Future<ZyraProfileVideoRecord> submit(File clip, Duration duration) async {
    writes++;
    if (refusal case final reason?) throw reason;
    return record = ZyraProfileVideoRecord(
      path: 'fictional/pending.mp4',
      status: ZyraProfileVideoStatus.pending,
      duration: duration,
    );
  }

  @override
  Future<void> remove() async {
    removes++;
    record = null;
  }
}

class _Media extends ZyraProfileVideoMedia {
  _Media(this.directory);
  final Directory directory;
  final starts = <Duration>[];
  Duration duration = const Duration(seconds: 4);
  int picks = 0;

  @override
  Future<XFile?> pick() async => XFile('${directory.path}/pick-${picks++}.mp4');

  @override
  Future<({Duration duration, int videoStartMs})> inspect(String path) async =>
      (duration: duration, videoStartMs: 0);

  @override
  Future<File> export(String path, Duration start) async {
    starts.add(start);
    return File('${directory.path}/export.mp4');
  }

  @override
  Future<Uint8List?> still(String path, {int timeMs = 0}) async =>
      _fixtureFrame();

  @override
  Future<List<Uint8List>> thumbnails(String path) async {
    return List.filled(10, _fixtureFrame());
  }

  Uint8List _fixtureFrame() =>
      File('assets/dev/one_journey_photos/zyra1a.jpg').readAsBytesSync();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _mount(
  WidgetTester tester, {
  required Size size,
  required bool basic,
  required _Store store,
  required _Media media,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final padding = size.width == 430
      ? const EdgeInsets.only(top: 59, bottom: 34)
      : const EdgeInsets.only(top: 20);
  var presentationReady = false;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          padding: padding,
          viewPadding: padding,
        ),
        child: RepaintBoundary(key: _capture, child: child),
      ),
      home: ZyraOneJourneyConceptShell(
        canAct: () => true,
        onExit: () {},
        onPresentationReady: () => presentationReady = true,
        initialCheckpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel(capacity: 3).snapshot(),
          tab: 4,
          pages: const ['manage_photos'],
          seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
        ),
        fixture: ZyraOneJourneyShellFixture(
          profileVideoStore: store,
          profileVideoMedia: media,
        ),
      ),
    ),
  );
  // The Photos page waits for the shell's bundled image decodes, which run
  // outside the widget test clock.
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!presentationReady && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  expect(
    presentationReady,
    isTrue,
    reason: 'The shell did not finish preparing its bundled photo deck in 5 s.',
  );
  await _settle(tester);
  expect(
    find.byKey(const ValueKey('profile-video-photos-grid')),
    findsOneWidget,
    reason: 'Manage Photos did not mount after the bundled photo deck loaded.',
  );
}

Future<void> _save(WidgetTester tester, String name) async {
  if (_directory.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_capture),
    );
    final image = await boundary.toImage();
    try {
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await File('$_directory/$name.png').writeAsBytes(
        png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (_directory.isEmpty) return;
    final fonts = FontLoader(_captureFont);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      fonts.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([fonts.load(), icons.load()]);
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    if (_directory.isNotEmpty) ZyraText.testReadingFontFamily = _captureFont;
  });
  tearDown(() {
    ZyraText.testReadingFontFamily = null;
    ZyraText.useTestFontStubs = false;
  });

  for (final size in const [Size(430, 932), Size(375, 667)]) {
    final resolution = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets(
      'Basic video tile opens Seeker One without access at $resolution',
      (tester) async {
        final directory = Directory.systemTemp.createTempSync(
          'zyra-video-test',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final store = _Store();
        final media = _Media(directory);
        await _mount(
          tester,
          size: size,
          basic: true,
          store: store,
          media: media,
        );
        expect(find.text('4 photo spaces available'), findsOneWidget);
        expect(find.text('Add a video'), findsNothing);
        final lockedTile = find.ancestor(
          of: find.text('See Seeker One ›'),
          matching: find.byType(ZyraPhotoGridTile),
        );
        final lockedOutline = find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.foregroundPainter is ZyraGuardianDashedBorder,
        );
        final outline = tester.widget<CustomPaint>(
          find.descendant(of: lockedTile, matching: lockedOutline),
        );
        final dashedBorder =
            outline.foregroundPainter! as ZyraGuardianDashedBorder;
        expect(
          dashedBorder.color,
          ZyraColors.journeyGold.withValues(alpha: .5),
        );
        final mainPhoto = find.byWidgetPredicate(
          (widget) =>
              widget is ZyraPhotoGridTile && widget.label == 'Main photo',
        );
        final mainTile = tester.widget<Material>(
          find.descendant(of: mainPhoto, matching: find.byType(Material)),
        );
        final mainShape = mainTile.shape! as RoundedRectangleBorder;
        expect(
          mainShape.side,
          const BorderSide(color: ZyraColors.journeyGold, width: 1.5),
        );
        expect(
          find.descendant(of: mainPhoto, matching: find.byIcon(Icons.check)),
          findsOneWidget,
        );
        await _save(tester, 'photos_basic_$resolution');
        await tester.tap(find.text('See Seeker One ›'));
        await _settle(tester);
        expect(find.text('Profile video'), findsOneWidget);
        expect(find.text('1 silent video'), findsOneWidget);
        expect(store.reads, 0);
        expect(media.picks, 0);
      },
    );

    testWidgets('Short video goes directly to checking at $resolution', (
      tester,
    ) async {
      final directory = Directory.systemTemp.createTempSync('zyra-video-test');
      addTearDown(() => directory.deleteSync(recursive: true));
      final store = _Store();
      final media = _Media(directory);
      await _mount(
        tester,
        size: size,
        basic: false,
        store: store,
        media: media,
      );
      final grid = find.byKey(const ValueKey('profile-video-photos-grid'));
      final tile = find.text('Add a video');
      expect(tester.getCenter(tile).dx, greaterThan(size.width / 2));
      expect(tester.getCenter(tile).dy, greaterThan(tester.getCenter(grid).dy));
      await _save(tester, 'photos_add_$resolution');
      await tester.tap(tile);
      await _settle(tester);
      expect(media.starts, [Duration.zero]);
      expect(store.record!.duration, const Duration(seconds: 4));
      expect(find.text('Choose 10 seconds'), findsNothing);
      expect(find.text('Being checked'), findsOneWidget);
      expect(find.text('Only you can see it for now'), findsOneWidget);
      await _save(tester, 'photos_checking_$resolution');
    });
  }

  testWidgets('Owner removal uses the LOCK 28 sheet', (tester) async {
    final directory = Directory.systemTemp.createTempSync('zyra-video-test');
    addTearDown(() => directory.deleteSync(recursive: true));
    final store = _Store()
      ..record = const ZyraProfileVideoRecord(
        path: 'fictional/approved.mp4',
        status: ZyraProfileVideoStatus.approved,
        duration: Duration(seconds: 10),
      );
    await _mount(
      tester,
      size: const Size(430, 932),
      basic: false,
      store: store,
      media: _Media(directory),
    );
    expect(find.text('10 s'), findsOneWidget);
    await _save(tester, 'photos_live_430x932');
    await tester.tap(find.byTooltip('Remove video'));
    await _settle(tester);
    expect(find.text('Remove your video?'), findsOneWidget);
    await _save(tester, 'photos_remove_430x932');
    await tester.tap(find.text('Keep video'));
    await _settle(tester);
    expect(store.removes, 0);
    await tester.tap(find.byTooltip('Remove video'));
    await _settle(tester);
    await tester.tap(find.text('Remove video'));
    await _settle(tester);
    expect(store.removes, 1);
    expect(find.text('Add a video'), findsOneWidget);
  });

  testWidgets('selected long segment reaches export and keeps server refusal', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('zyra-video-test');
    addTearDown(() => directory.deleteSync(recursive: true));
    final store = _Store()
      ..refusal = const ZyraProfileVideoRefusal('has_sound');
    final media = _Media(directory)..duration = const Duration(seconds: 32);
    await _mount(
      tester,
      size: const Size(430, 932),
      basic: false,
      store: store,
      media: media,
    );
    await tester.tap(find.text('Add a video'));
    await _settle(tester);
    final strip = tester.getRect(
      find.byKey(const ValueKey('profile-video-filmstrip')),
    );
    await tester.tapAt(Offset(strip.left + strip.width / 4, strip.center.dy));
    await tester.pump();
    await tester.tap(find.text('Use these 10 seconds'));
    await _settle(tester);
    expect(media.starts, [const Duration(seconds: 8)]);
    expect(store.writes, 1);
    expect(find.text('Choose 10 seconds'), findsNothing);
    expect(
      find.text('Your video still has sound. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Being checked'), findsNothing);
  });
}
