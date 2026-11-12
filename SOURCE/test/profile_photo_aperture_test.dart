import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zyra/dev/zyra_browse_photo_renderer.dart';
import 'package:zyra/dev/zyra_draft_journey_bio_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/models/zyra_profile_photo_geometry.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/profile/photo_crop_review_screen.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

const _id = 'draft-sara';
const _galleryPage = ValueKey('concept_browse_photo_${_id}_0');

Uint8List _portrait() {
  final photo = img.Image(width: 90, height: 120);
  img.fill(photo, color: img.ColorRgb8(20, 20, 20));
  for (var x = 0; x < photo.width; x++) {
    photo.setPixelRgb(x, 0, 255, 0, 0);
    photo.setPixelRgb(x, photo.height - 1, 0, 0, 255);
  }
  for (var y = 1; y < photo.height - 1; y++) {
    photo.setPixelRgb(0, y, 0, 255, 0);
    photo.setPixelRgb(photo.width - 1, y, 255, 255, 255);
  }
  return img.encodePng(photo);
}

Future<void> _mount(WidgetTester tester, Size viewport, Widget home) async {
  final safeArea = viewport.height == 932
      ? const EdgeInsets.only(top: 59, bottom: 34)
      : const EdgeInsets.only(top: 20);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: safeArea,
          viewPadding: safeArea,
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

Future<Size> _expectFullPhoto(
  WidgetTester tester,
  Key key, {
  Key? boundsKey,
}) async {
  final page = find.byKey(key);
  final imageFinder = find.descendant(of: page, matching: find.byType(Image));
  final image = tester.widget<Image>(imageFinder);
  Object? error;
  await tester.runAsync(
    () => precacheImage(
      image.image,
      tester.element(imageFinder),
      onError: (exception, _) => error = exception,
    ).timeout(const Duration(seconds: 5)),
  );
  expect(error, isNull);
  await tester.pumpAndSettle();
  final rawFinder = find.descendant(of: page, matching: find.byType(RawImage));
  final raw = tester.widget<RawImage>(rawFinder);
  final aperture = tester.getRect(rawFinder);
  expect(
    aperture,
    tester.getRect(boundsKey == null ? page : find.byKey(boundsKey)),
  );
  expect(raw.fit, BoxFit.cover);
  final source = Size(
    raw.image!.width.toDouble(),
    raw.image!.height.toDouble(),
  );
  expect(source, const Size(90, 120));
  final fitted = applyBoxFit(raw.fit!, source, aperture.size);
  expect(fitted.destination.width, closeTo(aperture.width, .000001));
  expect(fitted.destination.height, closeTo(aperture.height, .000001));
  expect(tester.takeException(), isNull);
  return aperture.size;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  for (final viewport in [const Size(430, 932), const Size(375, 667)]) {
    testWidgets(
      '${viewport.width.toInt()}×${viewport.height.toInt()} legacy 3:4 photos cover the full photo bounds',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final photo = _portrait();
        final source = 'data:image/png;base64,${base64Encode(photo)}';
        final profile = SeekerProfile(
          id: _id,
          firstName: 'Sara',
          age: 29,
          city: 'Birmingham',
          gender: 'female',
          photos: [source],
        );
        await _mount(tester, viewport, PhotoCropReviewScreen(photos: [photo]));
        final crop = tester.getSize(
          find.byKey(const ValueKey('photo-crop-canvas')),
        );
        expect(crop.aspectRatio, closeTo(zyraProfilePhotoAspectRatio, .000001));

        final renderer = ZyraBrowseLocalPhotoRenderer();
        addTearDown(renderer.dispose);
        expect(await tester.runAsync(() => renderer.prepare([source])), isTrue);
        await _mount(
          tester,
          viewport,
          Scaffold(
            body: Builder(
              builder: (context) => ZyraOneJourneyBrowseDesigns(
                profiles: [profile],
                selectedIndex: 0,
                design: ZyraOneJourneyBrowseDesign.portraitCard,
                photoBuilder: renderer.build,
                initialGalleryIndices: const {_id: 1},
                fixedTabFooter: true,
                bottomPadding: ZyraNavBarMetrics.contentBottomClearance(
                  context,
                ),
                profileSwipe: (
                  previousIndex: null,
                  nextIndex: null,
                  onBlockedPrevious: null,
                  canAct: () => true,
                ),
              ),
            ),
          ),
        );
        final profiles = await _expectFullPhoto(tester, _galleryPage);
        expect(
          profiles.aspectRatio,
          closeTo(
            viewport.width == 430
                ? crop.aspectRatio
                : zyraCompactProfilePhotoAspectRatio,
            .000001,
          ),
        );
        expect(
          tester
              .widget<Image>(
                find.descendant(
                  of: find.byKey(_galleryPage),
                  matching: find.byType(Image),
                ),
              )
              .alignment,
          Alignment.center,
        );

        await _mount(
          tester,
          viewport,
          ZyraBackNavigationPreview(
            revision: 0,
            child: MyProfilePreviewScreen.preview(
              profile: profile,
              canAct: () => true,
              onBack: () {},
              hapticLevel: ZyraHapticLevel.off,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final previewTap = tester.getRect(
          find.byKey(const ValueKey('concept_browse_photo_tap_$_id')),
        );
        await tester.tapAt(Offset(previewTap.right - 36, previewTap.center.dy));
        await tester.pumpAndSettle();
        final preview = await _expectFullPhoto(tester, _galleryPage);

        await _mount(
          tester,
          viewport,
          Scaffold(
            body: Builder(
              builder: (context) => ZyraDraftJourneyBioPresentation(
                subjectId: _id,
                firstName: profile.firstName,
                projection: ZyraDraftJourneyBioProjection.fixtureFor(
                  _id,
                  useLegacyFixture: true,
                ),
                portrait: renderer.build(
                  context,
                  source,
                  width: 104,
                  height: 132,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
        );
        final journeyBio = await _expectFullPhoto(
          tester,
          const ValueKey('draft_journey_bio_portrait_$_id'),
        );

        await _mount(
          tester,
          viewport,
          Scaffold(
            body: EditPhotosScreen.preview(
              canAct: () => true,
              initialPhotos: [source, source],
              gender: profile.gender,
              initialAlignmentX: 0,
              initialAlignmentY: 0,
              onPhotosChanged: (_) {},
              onAvatarChanged: (_) {},
              hapticLevel: ZyraHapticLevel.off,
            ),
          ),
        );
        final large = await _expectFullPhoto(
          tester,
          const ValueKey('photo-large-0'),
        );
        await tester.tap(find.byKey(const ValueKey('photos-compact-toggle')));
        await tester.pumpAndSettle();
        final grid = await _expectFullPhoto(
          tester,
          const ValueKey('compact-photo-0'),
          boundsKey: const ValueKey('compact-photo-border-0'),
        );
        expect(grid.aspectRatio, closeTo(crop.aspectRatio, .000001));
        final tile = tester.getRect(
          find.byKey(const ValueKey('compact-photo-1')),
        );
        final add = tester.getRect(find.byKey(const ValueKey('compact-add-2')));
        expect(tile.size, add.size);
        expect(tile.width, greaterThan(grid.width));
        // The original grid slot still responds to taps beside the narrower tile.
        await tester.tapAt(Offset(tile.left + 4, tile.center.dy));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('make-main-1')), findsOneWidget);
        debugPrint(
          'Photo apertures at $viewport: crop $crop, Profiles $profiles, '
          'Preview $preview, Journey Bio $journeyBio, large $large, grid $grid',
        );
      },
    );
  }
}
