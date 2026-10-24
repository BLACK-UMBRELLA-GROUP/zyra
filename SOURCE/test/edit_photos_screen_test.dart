import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/screens/profile/profile_screen.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(
      name: 'Adam',
      gender: 'male',
      location: 'London',
    );
    AppState.instance.setProfilePhotos(const [
      'https://example.invalid/one.jpg',
      'https://example.invalid/two.jpg',
    ]);
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('Photos opens as a large swipeable ZYRA gallery', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileScreen())),
    );

    final editPhotos = find.byKey(const ValueKey('edit-photos-action'));
    expect(editPhotos, findsOneWidget);
    expect(editPhotos.hitTestable(), findsOneWidget);
    await tester.tap(editPhotos);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(EditPhotosScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('photos-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('photos-page-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-large-0')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('photo-large-0'))).height,
      greaterThan(700),
    );
    expect(find.byKey(const ValueKey('photo-page-dot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-page-dot-1')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('photo-page-dot-0'))).dy -
          tester.getBottomLeft(find.byKey(const ValueKey('photo-large-0'))).dy,
      greaterThanOrEqualTo(16),
    );
    expect(
      find.byKey(const ValueKey('main-photo-solid-gold-border')),
      findsOneWidget,
    );
    final photosScreen = find.byType(EditPhotosScreen);
    expect(
      find.descendant(
        of: photosScreen,
        matching: find.byIcon(Icons.chevron_left_rounded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: photosScreen,
        matching: find.byIcon(Icons.chevron_right_rounded),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('adjust-photo-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('photo-large-0')));
    await tester.pump();
    expect(find.text('Crop photo'), findsNothing);
    expect(find.text('2 / 6'), findsNothing);
    expect(find.textContaining('Choose several'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('main photo swipe reveals independent avatar adjustment', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EditPhotosScreen()));
    await tester.pump();

    final photo = find.byKey(const ValueKey('photo-large-0'));
    final closedPhotoTop = tester.getTopLeft(photo).dy;
    final closedPhotoHeight = tester.getSize(photo).height;
    await tester.drag(photo, const Offset(0, -150));
    await tester.pumpAndSettle();
    final avatarAction = find.byKey(const ValueKey('adjust-main-avatar'));
    final adjustAction = find.byKey(const ValueKey('adjust-photo-0'));
    final deleteAction = find.byKey(const ValueKey('remove-photo-0'));
    expect(adjustAction.hitTestable(), findsOneWidget);
    expect(avatarAction.hitTestable(), findsOneWidget);
    expect(deleteAction.hitTestable(), findsOneWidget);
    expect(tester.getSize(adjustAction).width, greaterThan(100));
    expect(tester.getSize(avatarAction).width, greaterThan(100));
    expect(tester.getSize(deleteAction).width, 52);
    expect(tester.getTopLeft(photo).dy, closeTo(closedPhotoTop, 0.1));
    expect(tester.getSize(photo).height, lessThan(closedPhotoHeight));
    expect(
      tester.getTopLeft(avatarAction).dy - tester.getBottomLeft(photo).dy,
      greaterThan(20),
    );
    expect(find.text('Edit avatar'), findsOneWidget);
    expect(find.text('Delete photo'), findsNothing);
    expect(
      find.descendant(
        of: deleteAction,
        matching: find.byIcon(Icons.delete_outline_rounded),
      ),
      findsOneWidget,
    );

    final avatarButton = tester.widget<OutlinedButton>(avatarAction);
    expect(
      avatarButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      ZyraColors.foreground,
    );
    expect(
      avatarButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      ZyraColors.surfaceFill,
    );

    await tester.tap(avatarAction);
    await tester.pumpAndSettle();

    expect(find.text('Adjust avatar'), findsOneWidget);
    expect(
      find.text('Drag in any direction to position your avatar.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.open_with_rounded), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('avatar-adjust-drag')),
      const Offset(60, -70),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('avatar-adjust-save')));
    await tester.pumpAndSettle();

    // The photo follows the finger: rightward motion shifts the crop left,
    // and upward motion shifts it down within Alignment coordinates.
    expect(AppState.instance.avatarAlignmentX, lessThan(0));
    expect(AppState.instance.avatarAlignmentY, greaterThan(0));
    expect(find.byType(EditPhotosScreen), findsOneWidget);
  });

  testWidgets('photo removal is confirmed and updates the profile state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EditPhotosScreen()));
    await tester.pump();

    await tester.drag(
      find.byKey(const ValueKey('photo-large-0')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('remove-photo-0')));
    await tester.pumpAndSettle();
    expect(find.text('Remove this photo?'), findsOneWidget);

    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();

    expect(AppState.instance.photos, hasLength(1));
    expect(AppState.instance.photos.single, 'https://example.invalid/two.jpg');
    expect(find.byKey(const ValueKey('photo-large-0')), findsOneWidget);
  });

  testWidgets('compact view selects and promotes a new main photo', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EditPhotosScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('photos-compact-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photos-compact-grid')), findsOneWidget);
    expect(find.text('MAIN'), findsNothing);
    expect(find.text('Main photo'), findsNothing);
    expect(find.text('3 photo spaces available'), findsOneWidget);
    for (var index = 2; index < 5; index++) {
      expect(find.byKey(ValueKey('compact-add-$index')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('compact-photo-1')));
    await tester.pumpAndSettle();

    final mainBorder = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('compact-photo-border-0')),
    );
    final selectedBorder = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('compact-photo-border-1')),
    );
    expect(
      (mainBorder.decoration as BoxDecoration).border,
      Border.all(color: ZyraColors.journeyGold, width: 1.8),
    );
    expect(
      (selectedBorder.decoration as BoxDecoration).border,
      Border.all(color: ZyraColors.surfaceBorder, width: 0.7),
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('Make main photo'));
    await tester.pumpAndSettle();

    expect(AppState.instance.photos.first, 'https://example.invalid/two.jpg');
    expect(find.byKey(const ValueKey('photos-page-view')), findsOneWidget);
  });

  testWidgets('Developer Preview adds a reviewed local photo batch', (
    tester,
  ) async {
    const localPhoto1 =
        'data:image/png;base64,'
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    const localPhoto2 = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';
    await tester.pumpWidget(
      MaterialApp(
        home: EditPhotosScreen(
          photoBatchRunner: (context, remaining, onProgress) async {
            expect(remaining, 3);
            onProgress('Adding 2 of 2');
            return const ZyraPhotoBatchResult.added([localPhoto1, localPhoto2]);
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('photos-compact-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compact-add-2')));
    await tester.pumpAndSettle();

    expect(AppState.instance.photos, hasLength(4));
    expect(AppState.instance.photos.last, localPhoto2);
    expect(
      AppState.instance.photos.any((photo) => photo.contains('picsum.photos')),
      isFalse,
    );
    expect(find.byKey(const ValueKey('photo-page-dot-3')), findsOneWidget);
  });

  testWidgets('empty page uses the shared text-led empty state', (
    tester,
  ) async {
    AppState.instance.setProfilePhotos(const []);
    await tester.pumpWidget(const MaterialApp(home: EditPhotosScreen()));
    await tester.pump();

    expect(find.byKey(const ValueKey('photos-empty-state')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-photos-add')), findsOneWidget);
    expect(find.text('No photos yet'), findsOneWidget);
    expect(find.text('Add your first profile photo to begin.'), findsOneWidget);
    expect(find.text('Add photo'), findsNothing);

    final compactToggle = tester.widget<IconButton>(
      find.byKey(const ValueKey('photos-compact-toggle')),
    );
    expect(compactToggle.onPressed, isNull);
  });
}
