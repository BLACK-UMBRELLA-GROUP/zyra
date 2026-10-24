import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/profile/avatar_adjust_screen.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/profile/photo_crop_review_screen.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

const _editorKey = ValueKey('retained-photo-editor-owner');
const _asset = 'assets/dev/one_journey_photos/seeker_self.jpg';
const _presentationMethods = <String>{
  'SystemChrome.setApplicationSwitcherDescription',
  'SystemChrome.setSystemUIOverlayStyle',
  'SystemSound.play',
};
const _forbiddenNativeChannels = <MethodChannel>[
  MethodChannel('plugins.flutter.io/image_picker'),
  MethodChannel('app.zyraconnect.zyra/profile_photo'),
  MethodChannel('com.aboutyou.dart_packages.sign_in_with_apple'),
  MethodChannel('plugins.flutter.io/google_sign_in'),
];

Uint8List _bytes(int colour) {
  final photo = img.Image(width: 60, height: 80);
  img.fill(photo, color: img.ColorRgb8(colour, 70, 110));
  return img.encodePng(photo);
}

String _photo(int colour) =>
    'data:image/png;base64,${base64Encode(_bytes(colour))}';

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('The retained local photo editor must not use HTTP.');
  }
}

class _Owner {
  bool allowed = true;
  final List<List<String>> photos = [];
  final List<Offset> avatars = [];
  // Retained widgets pin these callback instances for the owner's lifetime.
  late final bool Function() guard = _allowed;
  late final ValueChanged<List<String>> publishPhotos = _publishPhotos;
  late final ValueChanged<Offset> publishAvatar = _publishAvatar;

  bool _allowed() => allowed;

  void _publishPhotos(List<String> value) {
    expect(allowed, isTrue);
    photos.add(List<String>.of(value));
  }

  void _publishAvatar(Offset value) {
    expect(allowed, isTrue);
    avatars.add(value);
  }
}

Widget _harness(Widget child, {double textScale = 1}) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, body) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
      textScaler: TextScaler.linear(textScale),
    ),
    child: body!,
  ),
  home: Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: child,
    ),
  ),
);

EditPhotosScreen _editor(
  _Owner owner, {
  List<String>? photos,
  ZyraPhotoBatchRunner? runner,
  ZyraHapticLevel hapticLevel = ZyraInteractionStyle.currentDefaultHapticLevel,
}) => EditPhotosScreen.preview(
  key: _editorKey,
  canAct: owner.guard,
  initialPhotos: photos ?? [_photo(90), _photo(140)],
  gender: 'female',
  initialAlignmentX: .1,
  initialAlignmentY: -.2,
  onPhotosChanged: owner.publishPhotos,
  onAvatarChanged: owner.publishAvatar,
  photoBatchRunner: runner,
  hapticLevel: hapticLevel,
);

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_harness(child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _compact(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('photos-compact-toggle')));
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const ValueKey('photo-large-0')),
    const Offset(0, -150),
  );
  await tester.pumpAndSettle();
}

Future<void> _flush(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 60 && !ready(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(
    ready(),
    isTrue,
    reason: 'The retained photo operation did not become ready.',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NoNetwork network;
  late HttpOverrides? previousNetwork;
  late List<String> memberPhotos;
  late Map<String, Object?> preferenceSnapshot;
  late ZyraHapticLevel globalHapticSnapshot;
  final nativeCalls = <String>[];
  final hapticCalls = <MethodCall>[];
  final forbiddenNativeCalls = <String>[];

  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.finishSignOut();
    expect(ZyraInternalPreviewClient.isActive, isFalse);
    SharedPreferences.setMockInitialValues({
      'zyra.cached_account_owner': 'synthetic-retained-member',
      'zyra.avatar_alignment_x': .35,
      'zyra.avatar_alignment_y': -.45,
    });
    await ZyraLocalPrefs.init();
    await ZyraLocalPrefs.bindAccount('synthetic-retained-member');
    final preferences = await SharedPreferences.getInstance();
    globalHapticSnapshot = ZyraInteractionStyle.hapticLevel;
    preferenceSnapshot = {
      for (final key in preferences.getKeys()) key: preferences.get(key),
    };
    final state = AppState.instance;
    state.name = 'Unchanged member';
    state.gender = 'male';
    memberPhotos = [_photo(15)];
    state.photos = List<String>.of(memberPhotos);
    state.avatarAlignmentX = .35;
    state.avatarAlignmentY = -.45;
    network = _NoNetwork();
    previousNetwork = HttpOverrides.current;
    HttpOverrides.global = network;
    nativeCalls.clear();
    hapticCalls.clear();
    forbiddenNativeCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          nativeCalls.add(call.method);
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        });
    for (final channel in _forbiddenNativeChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            forbiddenNativeCalls.add('${channel.name}:${call.method}');
            throw PlatformException(code: 'retained-local-photo-only');
          });
    }
  });

  tearDown(() async {
    try {
      expect(network.attempts, 0);
      expect(forbiddenNativeCalls, isEmpty);
      expect(
        nativeCalls.where(
          (method) =>
              !method.startsWith('HapticFeedback.') &&
              !_presentationMethods.contains(method),
        ),
        isEmpty,
      );
      expect(ZyraInternalPreviewClient.isActive, isFalse);
      expect(AppState.instance.photos, memberPhotos);
      expect(AppState.instance.name, 'Unchanged member');
      expect(AppState.instance.avatarAlignmentX, .35);
      expect(AppState.instance.avatarAlignmentY, -.45);
      expect(ZyraInteractionStyle.hapticLevel, globalHapticSnapshot);
      final preferences = await SharedPreferences.getInstance();
      expect({
        for (final key in preferences.getKeys()) key: preferences.get(key),
      }, preferenceSnapshot);
    } finally {
      HttpOverrides.global = previousNetwork;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      for (final channel in _forbiddenNativeChannels) {
        messenger.setMockMethodCallHandler(channel, null);
      }
      AppState.instance.resetForAccountChange();
      ZyraText.useTestFontStubs = false;
    }
  });

  testWidgets(
    'embedded editor retains gallery and aligned heading without a back arrow',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, _editor(owner));
      expect(find.byKey(const ValueKey('photos-page-view')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('main-photo-solid-gold-border')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('photos-title')),
      );
      expect(title.style!.fontSize, 28);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('photos-title'))).dx,
        20,
      );
      expect(
        find.descendant(
          of: find.byType(EditPhotosScreen),
          matching: find.byType(Scaffold),
        ),
        findsNothing,
      );
      expect(owner.photos, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact promotion updates only caller photos and avatar draft', (
    tester,
  ) async {
    final owner = _Owner();
    final initial = [_photo(90), _photo(140)];
    await _mount(tester, _editor(owner, photos: initial));
    await _compact(tester);
    await tester.tap(find.byKey(const ValueKey('compact-photo-1')));
    await tester.pump();
    await tester.tap(find.text('Make main photo'));
    await tester.pumpAndSettle();
    expect(owner.photos.single, [initial[1], initial[0]]);
    expect(owner.avatars.single, Offset.zero);
    expect(find.byKey(const ValueKey('photos-page-view')), findsOneWidget);
  });

  for (final level in const [ZyraHapticLevel.off, ZyraHapticLevel.strong]) {
    testWidgets(
      'photo confirmation honors caller ${level.name} haptics without changing member preferences',
      (tester) async {
        final owner = _Owner();
        final initial = [_photo(90), _photo(140)];
        await _mount(
          tester,
          _editor(owner, photos: initial, hapticLevel: level),
        );
        await _compact(tester);
        await tester.tap(find.byKey(const ValueKey('compact-photo-1')));
        await tester.pump();
        hapticCalls.clear();
        await tester.tap(find.text('Make main photo'));
        await tester.pumpAndSettle();

        expect(owner.photos.single, [initial[1], initial[0]]);
        expect(owner.avatars.single, Offset.zero);
        expect(
          hapticCalls.map((call) => call.arguments).toList(),
          level == ZyraHapticLevel.off
              ? isEmpty
              : ['HapticFeedbackType.heavyImpact'],
        );
        expect(ZyraInteractionStyle.hapticLevel, globalHapticSnapshot);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'avatar Save receives caller ${level.name} haptics from the photo editor',
      (tester) async {
        final owner = _Owner();
        await _mount(tester, _editor(owner, hapticLevel: level));
        await _reveal(tester);
        await tester.tap(find.byKey(const ValueKey('adjust-main-avatar')));
        await tester.pumpAndSettle();
        expect(find.byType(AvatarAdjustScreen), findsOneWidget);
        expect(
          tester
              .widget<AvatarAdjustScreen>(find.byType(AvatarAdjustScreen))
              .hapticLevel,
          level,
        );
        hapticCalls.clear();
        await tester.tap(find.byKey(const ValueKey('avatar-adjust-save')));
        await tester.pumpAndSettle();

        expect(find.byType(EditPhotosScreen), findsOneWidget);
        expect(find.byType(AvatarAdjustScreen), findsNothing);
        expect(owner.avatars.single, const Offset(.1, -.2));
        expect(owner.photos, isEmpty);
        expect(
          hapticCalls.map((call) => call.arguments).toList(),
          level == ZyraHapticLevel.off
              ? isEmpty
              : ['HapticFeedbackType.heavyImpact'],
        );
        expect(ZyraInteractionStyle.hapticLevel, globalHapticSnapshot);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('removal reuses confirmation and preserves the only photo', (
    tester,
  ) async {
    final owner = _Owner();
    final initial = [_photo(90), _photo(140)];
    await _mount(tester, _editor(owner, photos: initial));
    await _reveal(tester);
    await tester.tap(find.byKey(const ValueKey('remove-photo-0')));
    await tester.pumpAndSettle();
    expect(find.text('Remove this photo?'), findsOneWidget);
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(owner.photos.single, [initial[1]]);
    await _reveal(tester);
    await tester.tap(find.byKey(const ValueKey('remove-photo-0')));
    await tester.pump();
    expect(
      find.text('Add a replacement before removing your only photo.'),
      findsOneWidget,
    );
    expect(owner.photos, hasLength(1));
  });

  testWidgets(
    'reviewed batch addition uses remaining capacity without member persistence',
    (tester) async {
      final owner = _Owner();
      final added = _photo(200);
      await _mount(
        tester,
        _editor(
          owner,
          runner: (context, remaining, progress) async {
            expect(remaining, 3);
            progress('Adding 1 of 1');
            return ZyraPhotoBatchResult.added([added]);
          },
        ),
      );
      await _compact(tester);
      await tester.tap(find.byKey(const ValueKey('compact-add-2')));
      await tester.pumpAndSettle();
      expect(owner.photos.single, hasLength(3));
      expect(owner.photos.single.last, added);
    },
  );

  testWidgets(
    'six-photo draft does not launch another picker and oversized result is rejected',
    (tester) async {
      final owner = _Owner();
      var calls = 0;
      Future<ZyraPhotoBatchResult> runner(
        BuildContext context,
        int remaining,
        ValueChanged<String?> progress,
      ) async {
        calls++;
        return ZyraPhotoBatchResult.added(
          List.generate(7, (index) => _photo(index + 60)),
        );
      }

      await _mount(
        tester,
        _editor(
          owner,
          photos: List.generate(6, (index) => _photo(index + 60)),
          runner: runner,
        ),
      );
      await _compact(tester);
      expect(find.byKey(const ValueKey('compact-add-5')), findsNothing);
      expect(find.text('All photo spaces used'), findsOneWidget);
      expect(calls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _harness(_editor(owner, photos: [], runner: runner)),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('edit-photos-add')));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(owner.photos, isEmpty);
      expect(
        find.text('Those photos could not be added. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'late picker result and progress are inert after owner revocation',
    (tester) async {
      final owner = _Owner();
      final pending = Completer<ZyraPhotoBatchResult>();
      ValueChanged<String?>? progress;
      await _mount(
        tester,
        _editor(
          owner,
          photos: [],
          runner: (context, remaining, onProgress) {
            progress = onProgress;
            return pending.future;
          },
        ),
      );
      await tester.tap(find.byKey(const ValueKey('edit-photos-add')));
      await tester.pump();
      owner.allowed = false;
      progress!('Late progress');
      pending.complete(ZyraPhotoBatchResult.added([_photo(210)]));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('photos-preview-unavailable')),
        findsOneWidget,
      );
      expect(owner.photos, isEmpty);
      expect(owner.avatars, isEmpty);
      owner.allowed = true;
      await tester.pumpWidget(_harness(_editor(owner)));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('photos-preview-unavailable')),
        findsOneWidget,
      );
    },
  );

  testWidgets('disposed editor ignores late picker completion', (tester) async {
    final owner = _Owner();
    final pending = Completer<ZyraPhotoBatchResult>();
    await _mount(
      tester,
      _editor(
        owner,
        photos: [],
        runner: (context, remaining, onProgress) => pending.future,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('edit-photos-add')));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(ZyraPhotoBatchResult.added([_photo(210)]));
    await tester.pump();
    expect(owner.photos, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preview-to-default update cannot restore or persist member data',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, _editor(owner));
      final staleToggle = tester
          .widget<IconButton>(
            find.byKey(const ValueKey('photos-compact-toggle')),
          )
          .onPressed!;
      await tester.pumpWidget(
        _harness(const EditPhotosScreen(key: _editorKey)),
      );
      staleToggle();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('photos-preview-unavailable')),
        findsOneWidget,
      );
      expect(owner.photos, isEmpty);
    },
  );

  testWidgets(
    'remote references and remote runner results fail closed locally',
    (tester) async {
      final owner = _Owner();
      await _mount(
        tester,
        _editor(owner, photos: ['https://example.invalid/photo.jpg']),
      );
      expect(
        find.byKey(const ValueKey('photos-preview-unavailable')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _harness(
          _editor(
            owner,
            photos: [],
            runner: (context, remaining, progress) async =>
                const ZyraPhotoBatchResult.added([
                  'https://example.invalid/photo.jpg',
                ]),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('edit-photos-add')));
      await tester.pumpAndSettle();
      expect(owner.photos, isEmpty);
      expect(find.byKey(const ValueKey('photos-empty-state')), findsOneWidget);
    },
  );

  testWidgets(
    'avatar editor returns to the retained gallery and publishes only local alignment',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, _editor(owner));
      await _reveal(tester);
      await tester.tap(find.byKey(const ValueKey('adjust-main-avatar')));
      await tester.pumpAndSettle();
      expect(find.byType(AvatarAdjustScreen), findsOneWidget);
      expect(find.byType(ZyraPullDownBackScope), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      final avatar = find.byKey(const ValueKey('avatar-adjust-drag'));
      expect(avatar.hitTestable(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('avatar-adjust-accessible-scroll')),
        findsNothing,
      );
      final gesture = await tester.startGesture(tester.getCenter(avatar));
      // First win the avatar's pan recognizer, then deliver an accepted update.
      // Pan uses a 36px threshold, twice the outer vertical drag's threshold.
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(20, -30));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      final rendered = tester.widget<ZyraAvatarImage>(
        find.descendant(of: avatar, matching: find.byType(ZyraAvatarImage)),
      );
      expect(rendered.alignmentX, lessThan(.1));
      expect(rendered.alignmentY, greaterThan(-.2));
      await tester.tap(find.byKey(const ValueKey('avatar-adjust-save')));
      await tester.pumpAndSettle();
      expect(owner.avatars, hasLength(1));
      expect(owner.avatars.single.dx, lessThan(.1));
      expect(owner.avatars.single.dy, greaterThan(-.2));
      expect(find.byType(EditPhotosScreen), findsOneWidget);
    },
  );

  testWidgets(
    'avatar keeps instructions and actions reachable at compact 200 percent text',
    (tester) async {
      final owner = _Owner();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _harness(
          AvatarAdjustScreen(
            photo: _photo(90),
            initialAlignmentX: .1,
            initialAlignmentY: -.2,
            preview: true,
            gender: 'female',
            canAct: owner.guard,
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      final avatar = tester.getRect(
        find.byKey(const ValueKey('avatar-adjust-drag')),
      );
      expect(avatar.width, greaterThan(0));
      expect(avatar.width, lessThanOrEqualTo(252));
      expect(avatar.height, closeTo(avatar.width, .01));
      expect(
        find.byKey(const ValueKey('avatar-adjust-accessible-scroll')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.text('Drag in any direction to position your avatar.'),
      );
      await tester.pumpAndSettle();
      final instructions = tester.getRect(
        find.text('Drag in any direction to position your avatar.'),
      );
      expect(
        find
            .text('Drag in any direction to position your avatar.')
            .hitTestable(),
        findsOneWidget,
      );
      expect(instructions.bottom, lessThanOrEqualTo(544));
      expect(
        tester
            .widget<Text>(
              find.text('Drag in any direction to position your avatar.'),
            )
            .style!
            .fontSize,
        13,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('avatar-adjust-save')),
      );
      await tester.pumpAndSettle();
      final reset = tester.getRect(
        find.byKey(const ValueKey('avatar-adjust-reset')),
      );
      final save = tester.getRect(
        find.byKey(const ValueKey('avatar-adjust-save')),
      );
      expect(instructions.left, greaterThanOrEqualTo(34));
      expect(instructions.right, lessThanOrEqualTo(286));
      expect(reset.bottom, lessThanOrEqualTo(544));
      expect(save.bottom, lessThanOrEqualTo(544));
      expect(
        find.byKey(const ValueKey('avatar-adjust-save')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'covered avatar action and revoked stale save cannot pop or publish',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, _editor(owner));
      await _reveal(tester);
      await tester.tap(find.byKey(const ValueKey('adjust-main-avatar')));
      await tester.pumpAndSettle();
      final staleSave = tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('avatar-adjust-save')),
          )
          .onPressed!;
      final context = tester.element(find.byType(AvatarAdjustScreen));
      final navigation = Navigator.of(context);
      final covered = navigation.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Cover route')),
        ),
      );
      await tester.pumpAndSettle();
      staleSave();
      await tester.pump();
      expect(find.text('Cover route'), findsOneWidget);
      expect(owner.avatars, isEmpty);
      navigation.pop();
      await covered;
      await tester.pumpAndSettle();
      owner.allowed = false;
      staleSave();
      await tester.pump();
      expect(owner.avatars, isEmpty);
      expect(
        find.byKey(const ValueKey('avatar-preview-unavailable')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'retained local crop confirms through sanitizer without network or global writes',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, _editor(owner));
      await _reveal(tester);
      await tester.tap(find.byKey(const ValueKey('adjust-photo-0')));
      await _flush(
        tester,
        () => find.byType(PhotoCropReviewScreen).evaluate().isNotEmpty,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await _flush(tester, () {
        final button = find.byKey(const ValueKey('photo-crop-confirm'));
        return button.evaluate().isNotEmpty &&
            tester.widget<FilledButton>(button).onPressed != null;
      });
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(ZyraPullDownBackScope), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('photo-crop-confirm')));
      await _flush(tester, () => owner.photos.isNotEmpty);
      await tester.pumpAndSettle();
      final output = owner.photos.single.first;
      expect(output.startsWith('data:image/jpeg;base64,'), isTrue);
      final decoded = img.decodeJpg(
        base64Decode(output.substring(output.indexOf(',') + 1)),
      );
      expect(decoded, isNotNull);
      expect(decoded!.exif.isEmpty, isTrue);
      expect(decoded.width, lessThanOrEqualTo(1440));
      expect(decoded.height, lessThanOrEqualTo(1440));
      expect(owner.avatars.single, Offset.zero);
      expect(find.byType(EditPhotosScreen), findsOneWidget);
    },
  );

  testWidgets(
    'bundled photos paint locally and avatar edits never open network providers',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, _editor(owner, photos: [_asset]));
      expect(find.byKey(const ValueKey('photos-page-view')), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      await _reveal(tester);
      await tester.tap(find.byKey(const ValueKey('adjust-main-avatar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('avatar-adjust-save')));
      await tester.pumpAndSettle();
      expect(owner.avatars.single, const Offset(.1, -.2));
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'confirmation opened before revocation cannot remove a photo afterwards',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, _editor(owner));
      await _reveal(tester);
      await tester.tap(find.byKey(const ValueKey('remove-photo-0')));
      await tester.pumpAndSettle();
      owner.allowed = false;
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(owner.photos, isEmpty);
      expect(owner.avatars, isEmpty);
      expect(
        find.byKey(const ValueKey('photos-preview-unavailable')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'stale crop confirmation is disabled after preview owner revocation',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, _editor(owner));
      await _reveal(tester);
      await tester.tap(find.byKey(const ValueKey('adjust-photo-0')));
      await _flush(
        tester,
        () => find.byType(PhotoCropReviewScreen).evaluate().isNotEmpty,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await _flush(tester, () {
        final button = find.byKey(const ValueKey('photo-crop-confirm'));
        return button.evaluate().isNotEmpty &&
            tester.widget<FilledButton>(button).onPressed != null;
      });
      final staleConfirm = tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('photo-crop-confirm')),
          )
          .onPressed!;
      owner.allowed = false;
      staleConfirm();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('crop-preview-unavailable')),
        findsOneWidget,
      );
      expect(owner.photos, isEmpty);
      expect(owner.avatars, isEmpty);
    },
  );

  testWidgets(
    'guard exceptions deny a preview without an authentication fallback',
    (tester) async {
      final owner = _Owner();
      await _mount(
        tester,
        EditPhotosScreen.preview(
          canAct: () => throw StateError('Owner unavailable'),
          initialPhotos: [_photo(90)],
          gender: 'female',
          initialAlignmentX: 0,
          initialAlignmentY: 0,
          onPhotosChanged: owner.publishPhotos,
          onAvatarChanged: owner.publishAvatar,
        ),
      );
      expect(
        find.byKey(const ValueKey('photos-preview-unavailable')),
        findsOneWidget,
      );
      expect(owner.photos, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'frozen own preview reuses Browse card and smooth interactive edge return',
    (tester) async {
      final owner = _Owner();
      var returns = 0;
      final photos = [_photo(90), _photo(140)];
      final profile = SeekerProfile(
        id: 'local-owner',
        firstName: 'Amina',
        surnameLine: 'Rahman',
        age: 29,
        city: 'London',
        gender: 'female',
        photos: photos,
      );
      await _mount(
        tester,
        ZyraBackNavigationPreview(
          revision: 0,
          child: MyProfilePreviewScreen.preview(
            profile: profile,
            canAct: owner.guard,
            onBack: () => returns++,
          ),
        ),
      );
      photos.clear();
      expect(find.byType(ZyraBrowseDesigns), findsOneWidget);
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('Unchanged member'), findsNothing);
      expect(find.byKey(const ValueKey('seeker-profile-close')), findsNothing);
      expect(
        tester
            .widget<ZyraBrowseDesigns>(find.byType(ZyraBrowseDesigns))
            .profiles
            .single
            .photos,
        hasLength(2),
      );
      final scope = find.byKey(const ValueKey('concept_pull_down_back_scope'));
      expect(scope, findsOneWidget);
      final edge = find.byKey(const ValueKey('zyra_back_swipe_edge'));
      expect(edge, findsOneWidget);
      final rect = tester.getRect(edge);
      final gesture = await tester.startGesture(
        Offset(rect.left + 8, rect.top + rect.height * .35),
      );
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(180, 0));
      await tester.pump();
      final surface = tester.widget<Transform>(
        find.byKey(const ValueKey('zyra_back_swipe_translation')),
      );
      expect(surface.transform.storage[12], greaterThan(0));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(returns, 0);
      await tester.pump(const Duration(milliseconds: 140));
      expect(returns, 1);
    },
  );

  testWidgets(
    'revoked own viewer callbacks remain inert and no auth restore starts',
    (tester) async {
      final owner = _Owner();
      var returns = 0;
      await _mount(
        tester,
        MyProfilePreviewScreen.preview(
          profile: const SeekerProfile(
            id: 'local-owner',
            firstName: 'Amina',
            age: 29,
            city: 'London',
            gender: 'female',
            photos: [],
          ),
          canAct: owner.guard,
          onBack: () => returns++,
        ),
      );
      final staleBack = tester
          .widget<ZyraPullDownBackScope>(find.byType(ZyraPullDownBackScope))
          .onBack;
      owner.allowed = false;
      staleBack();
      await tester.pump();
      expect(returns, 0);
      expect(
        find.byKey(const ValueKey('my-profile-preview-unavailable')),
        findsOneWidget,
      );
    },
  );
}
