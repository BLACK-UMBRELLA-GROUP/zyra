import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_full_screen_profile_gallery.dart';
import 'package:zyra/widgets/zyra_profile_video_player.dart';

const _personId = 'fictional-profile-video';
const _sara = 'draft-sara';
const _bioButton = ValueKey('journey-bio-gallery-button');
const _bioPortrait = ValueKey('draft_journey_bio_portrait_$_sara');
const _galleryTapArea = ValueKey('bio-gallery-tap-area');
const _photo = 'assets/dev/one_journey_photos/zyra1a.jpg';
const _profile = SeekerProfile(
  id: _personId,
  firstName: 'Amira',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  photos: [_photo],
);
const _captureKey = ValueKey('profile-video-capture');
const _captureFont = 'PoppinsProfileVideo';
const _captureDirectory = String.fromEnvironment(
  'ZYRA_PROFILE_VIDEO_CAPTURE_DIRECTORY',
);

ZyraProfileVideoPlayback _sampleVideo() => ZyraProfileVideoPlayback(
  bytes: Uint8List(0),
  placeholder: Image.asset(
    _photo,
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
  ),
);

Widget _app(Widget content, {bool reduceMotion = true}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduceMotion,
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
    ),
    child: child!,
  ),
  home: RepaintBoundary(key: _captureKey, child: content),
);

Future<void> _capture(
  WidgetTester tester,
  String filename, {
  Finder? portraitScope,
}) async {
  if (_captureDirectory.isEmpty) return;
  final portrait = find.descendant(
    of: portraitScope ?? find.byType(ZyraProfileVideoPage),
    matching: find.byType(RawImage),
  );
  for (var attempt = 0; attempt < 100; attempt++) {
    if (tester
        .widgetList<RawImage>(portrait)
        .any((image) => image.image != null)) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(
    tester.widgetList<RawImage>(portrait).any((image) => image.image != null),
    isTrue,
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final directory = Directory(_captureDirectory);
    expect(directory.isAbsolute, isTrue);
    expect(directory.existsSync(), isTrue);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage();
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${directory.path}/$filename.png').writeAsBytes(
        png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
        flush: true,
      );
    } finally {
      image.dispose();
    }
  });
}

Finder _dot(int page) =>
    find.byKey(ValueKey('concept_browse_photo_dot_${_personId}_$page'));

ViewRequestDraftModel _sharedBioModel({
  required bool ended,
  required DateTime endedAt,
}) {
  final model = ViewRequestDraftModel(capacity: 3, clock: () => endedAt)
    ..seedJourneys(1);
  expect(model.sendSalam(_sara), isTrue);
  expect(model.simulatePeerSalam(_sara), isTrue);
  expect(model.chooseStageContinue(_sara), isTrue);
  expect(model.simulatePeerStageContinue(_sara), isTrue);
  expect(model.advanceStage(_sara), isTrue);
  expect(model.chooseCompatibilityReveal(_sara), isTrue);
  expect(model.simulatePeerCompatibilityReveal(_sara), isTrue);
  expect(model.chooseStageContinue(_sara), isTrue);
  expect(model.simulatePeerStageContinue(_sara), isTrue);
  expect(model.beginBioStep(_sara), isTrue);
  expect(model.chooseBioReveal(_sara), isTrue);
  expect(model.simulatePeerBioReveal(_sara), isTrue);
  expect(model.chooseBioContinue(_sara), isTrue);
  expect(model.simulatePeerBioContinue(_sara), isTrue);
  expect(model.completeBioStep(_sara), isTrue);
  if (ended) expect(model.end(_sara), isTrue);
  return model;
}

Future<void> _openBio(
  WidgetTester tester, {
  required DateTime endedAt,
  required DateTime Function() clock,
  bool ended = false,
  bool approved = true,
  bool shared = true,
}) async {
  ZyraDeveloperAccess.resetAuthorizationForTesting();
  ZyraDeveloperAccess.setAuthorizedForTesting(true);
  addTearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });
  final ready = Completer<void>();
  final model = shared
      ? _sharedBioModel(ended: ended, endedAt: endedAt)
      : (ViewRequestDraftModel(capacity: 3)..seedJourneys(1));
  await tester.pumpWidget(
    _app(
      ZyraOneJourneyConceptShell(
        canAct: () => true,
        onExit: () {},
        fixture: ZyraOneJourneyShellFixture(
          profileVideoLoader: (id) async => approved && id == _sara
              ? ZyraProfileVideoPlayback(bytes: Uint8List(0))
              : null,
        ),
        previewClock: clock,
        initialCheckpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: model.snapshot(),
          tab: ended ? 2 : 1,
          pages: ended
              ? const ['ended', 'ended_bio']
              : const ['journey', 'bio'],
          personId: _sara,
        ),
        onPresentationReady: () {
          if (!ready.isCompleted) ready.complete();
        },
      ),
    ),
  );
  for (var attempt = 0; attempt < 100 && !ready.isCompleted; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(ready.isCompleted, isTrue);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (_captureDirectory.isEmpty) return;
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
    if (_captureDirectory.isNotEmpty) {
      ZyraText.testReadingFontFamily = _captureFont;
    }
  });
  tearDown(() {
    ZyraText.testReadingFontFamily = null;
    ZyraText.useTestFontStubs = false;
  });

  for (final size in const [Size(430, 932), Size(375, 667)]) {
    final resolution = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('Profiles appends approved video after photos at $resolution', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var hasApproval = true;
      late StateSetter update;
      final video = _sampleVideo();
      final galleryChanges = <int>[];
      final photoChanges = <int>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return ZyraBrowseDesigns(
                  profiles: const [_profile],
                  selectedIndex: 0,
                  design: ZyraOneJourneyBrowseDesign.portraitCard,
                  profileVideo: hasApproval ? video : null,
                  onGalleryIndexChanged: (_, index) =>
                      galleryChanges.add(index),
                  onPhotoIndexChanged: (_, index) => photoChanges.add(index),
                  photoBuilder:
                      (
                        context,
                        photo, {
                        required width,
                        required height,
                        required alignment,
                      }) => Image.asset(
                        photo,
                        width: width,
                        height: height,
                        alignment: alignment,
                        fit: BoxFit.cover,
                      ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_dot(2), findsOneWidget);
      expect(_dot(3), findsNothing);
      expect(find.text('Video · no sound'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('concept_browse_dot_target_1')),
      );
      await tester.pumpAndSettle();
      expect(photoChanges, [0]);
      await tester.tap(
        find.byKey(const ValueKey('concept_browse_dot_target_2')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Video · no sound'), findsOneWidget);
      expect(galleryChanges, [1, 2]);
      expect(photoChanges, [0]);

      update(() => hasApproval = false);
      await tester.pumpAndSettle();
      expect(find.text('Video · no sound'), findsNothing);
      expect(_dot(2), findsNothing);
      expect(_dot(1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Profiles shell opens the approved final page at $resolution', (
      tester,
    ) async {
      ZyraDeveloperAccess.resetAuthorizationForTesting();
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      addTearDown(() {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        ZyraDeveloperAccess.resetAuthorizationForTesting();
      });
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ready = Completer<void>();
      final viewed = <String>[];
      await tester.pumpWidget(
        _app(
          ZyraOneJourneyConceptShell(
            canAct: () => true,
            onExit: () {},
            fixture: ZyraOneJourneyShellFixture(
              profileVideoLoader: (id) async {
                viewed.add(id);
                return switch (id) {
                  'draft-amira' ||
                  'draft-sara' => ZyraProfileVideoPlayback(bytes: Uint8List(0)),
                  _ => null,
                };
              },
            ),
            onPresentationReady: () {
              if (!ready.isCompleted) ready.complete();
            },
          ),
        ),
      );
      for (var attempt = 0; attempt < 100 && !ready.isCompleted; attempt++) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
      }
      expect(ready.isCompleted, isTrue);
      await tester.pumpAndSettle();
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      final person = browse.profiles[browse.selectedIndex];
      expect(viewed, contains(person.id));
      expect(browse.profileVideo, isNotNull);
      final videoPage = person.photos.length + 1;
      await tester.tap(
        find.byKey(ValueKey('concept_browse_dot_target_$videoPage')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Video · no sound'), findsOneWidget);
      expect(find.byType(FloatingNavBar), findsOneWidget);
      await _capture(tester, 'profiles_last_video_$resolution');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Preview uses the shared final video page at $resolution', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final requested = <String>[];
      await tester.pumpWidget(
        _app(
          MyProfilePreviewScreen.preview(
            profile: _profile,
            canAct: () => true,
            onBack: () {},
            loadProfileVideo: (ownerId) async {
              requested.add(ownerId);
              return _sampleVideo();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requested, [_personId]);
      expect(_dot(2), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('concept_browse_dot_target_2')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Video · no sound'), findsOneWidget);
      expect(find.byType(ZyraProfileVideoPage), findsOneWidget);
      await _capture(tester, 'preview_last_video_$resolution');
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(430, 932), Size(375, 667)]) {
    final resolution = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('Journey Bio opens the shared gallery at $resolution', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final endedAt = DateTime.utc(2026, 11, 12, 10);
      await _openBio(tester, endedAt: endedAt, clock: () => endedAt);
      final portrait = find.byKey(_bioPortrait);
      final button = find.byKey(_bioButton);
      expect(find.text('Photos & video ›'), findsOneWidget);
      expect(tester.getSize(button).height, 34);
      expect(
        tester.getTopLeft(button).dy,
        greaterThan(
          tester
              .getBottomLeft(
                find.byKey(const ValueKey('draft_journey_bio_name')),
              )
              .dy,
        ),
      );
      await tester.tap(portrait);
      await tester.pumpAndSettle();
      expect(find.byType(ZyraFullScreenProfileGallery), findsNothing);
      await _capture(
        tester,
        'journey_bio_gallery_entry_$resolution',
        portraitScope: portrait,
      );

      await tester.tap(button);
      await tester.pumpAndSettle();
      final gallery = find.byType(ZyraFullScreenProfileGallery);
      expect(gallery, findsOneWidget);
      expect(tester.getSize(gallery), size);
      expect(find.text('Video · no sound'), findsNothing);
      final photos = tester
          .widget<ZyraFullScreenProfileGallery>(gallery)
          .photos;
      expect(photos, hasLength(2));
      expect(find.byKey(const ValueKey('bio-gallery-dot-2')), findsOneWidget);

      final area = tester.getRect(find.byKey(_galleryTapArea));
      await tester.tapAt(Offset(area.right - 40, area.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Video · no sound'), findsNothing);
      await tester.dragFrom(area.center, const Offset(-125, 0));
      await tester.pumpAndSettle();
      expect(find.text('Video · no sound'), findsOneWidget);
      await _capture(tester, 'journey_bio_last_video_$resolution');
      await tester.tapAt(Offset(area.left + 40, area.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Video · no sound'), findsNothing);

      if (size.width == 375) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      } else {
        await tester.tap(find.byKey(const ValueKey('bio-gallery-close')));
      }
      await tester.pumpAndSettle();
      expect(gallery, findsNothing);
      expect(button, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final approved in [false, true]) {
    testWidgets('Ended Bio gallery remains open with approval $approved', (
      tester,
    ) async {
      final endedAt = DateTime.utc(2026, 8, 12, 10);
      final expiry = endedAt.add(const Duration(days: 365));
      var now = expiry.subtract(const Duration(seconds: 5));
      await _openBio(
        tester,
        endedAt: endedAt,
        clock: () => now,
        ended: true,
        approved: approved,
      );
      expect(
        find.text(approved ? 'Photos & video ›' : 'Photos ›'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(_bioButton));
      await tester.pumpAndSettle();
      expect(find.byType(ZyraFullScreenProfileGallery), findsOneWidget);
      expect(
        find.byKey(const ValueKey('bio-gallery-dot-2')),
        approved ? findsOneWidget : findsNothing,
      );
      if (approved) {
        final area = tester.getRect(find.byKey(_galleryTapArea));
        // Previous wraps from the first photo to the approved last page.
        await tester.tapAt(Offset(area.left + 40, area.center.dy));
        await tester.pumpAndSettle();
        expect(find.text('Video · no sound'), findsOneWidget);
      }

      now = expiry;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(ZyraFullScreenProfileGallery), findsOneWidget);
      expect(find.text('Journey access has ended'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an unreadable Bio never opens the profile gallery', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 11, 12, 10);
    await _openBio(tester, endedAt: now, clock: () => now, shared: false);
    expect(find.byKey(_bioButton), findsNothing);
    expect(find.byType(ZyraFullScreenProfileGallery), findsNothing);
  });

  testWidgets('new profile cannot receive an old approval response', (
    tester,
  ) async {
    var owner = 'old-profile';
    late StateSetter update;
    final oldApproval = Completer<ZyraProfileVideoPlayback?>();
    Future<ZyraProfileVideoPlayback?> load(String id) =>
        id == 'old-profile' ? oldApproval.future : Future.value(null);
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return ZyraProfileVideoAccess(
              ownerId: owner,
              load: load,
              builder: (_, video) => Text(video == null ? 'Photos' : 'Video'),
            );
          },
        ),
      ),
    );
    update(() => owner = 'new-profile');
    await tester.pump();
    oldApproval.complete(_sampleVideo());
    await tester.pumpAndSettle();
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Video'), findsNothing);
  });

  testWidgets(
    'Low Power shows the still and tap-to-play control',
    (tester) async {
      const media = MethodChannel('zyra/profile_video');
      final requests = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(media, (call) async {
        requests.add(call.method);
        return call.method == 'lowPowerMode' ? true : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(media, null));
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: ZyraProfileVideoPlayer(
              path: 'fixture.mp4',
              active: true,
              still: Text('Poster frame'),
            ),
          ),
          reduceMotion: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, containsAll(['lowPowerMode', 'still']));
      expect(find.text('Poster frame'), findsOneWidget);
      expect(find.byTooltip('Play video'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets('upgrade row is Seeker-only and gated on video availability', (
    tester,
  ) async {
    Future<void> show({required bool guardian, required bool enabled}) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ZyraOneUpgradePage(
              guardian: guardian,
              includesProfileVideo: enabled,
              canContinue: () => true,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(guardian: false, enabled: false);
    expect(find.text('Profile video'), findsNothing);
    await show(guardian: false, enabled: true);
    expect(find.text('Profile video'), findsOneWidget);
    expect(find.text('1 silent video'), findsOneWidget);
    await show(guardian: true, enabled: true);
    expect(find.text('Profile video'), findsNothing);
  });
}
