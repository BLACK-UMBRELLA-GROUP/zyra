import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/photo_crop_review_screen.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _captures = String.fromEnvironment('ZYRA_PHOTO_ADD_CAPTURE_DIR');
const _captureKey = ValueKey('photo-add-capture');
const _font = 'PoppinsPhotoGalleryAdd';
const _assets = [
  'assets/dev/one_journey_photos/seeker_self.jpg',
  'assets/dev/one_journey_photos/zyra1a.jpg',
  'assets/dev/one_journey_photos/zyra1b.jpg',
  'assets/dev/one_journey_photos/zyra1c.jpg',
  'assets/dev/one_journey_photos/zyra2a.jpg',
  'assets/dev/one_journey_photos/zyra2b.jpg',
];
const _nativeChannels = [
  MethodChannel('plugins.flutter.io/image_picker'),
  MethodChannel('app.zyraconnect.zyra/profile_photo'),
];

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _pager => _key('photos-page-view');
Finder get _add => _key('photos-add-page-action');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Photo gallery fixtures must remain local.');
  }
}

class _Owner {
  bool allowed = true;
  int closes = 0;
  final updates = <List<String>>[];
  final avatars = <Offset>[];
  // Retain the same caller delegates across rebuilds and owner revocation.
  // ignore: prefer_function_declarations_over_variables
  late final bool Function() guard = () => allowed;
  // ignore: prefer_function_declarations_over_variables
  late final ValueChanged<List<String>> publish = (photos) {
    expect(allowed, isTrue);
    updates.add(List<String>.of(photos));
  };
  late final ValueChanged<Offset> publishAvatar = avatars.add;
}

Widget _app(
  _Owner owner, {
  int count = 1,
  double scale = 1,
  ZyraPhotoBatchRunner? runner,
  GlobalKey<NavigatorState>? navigator,
}) => MaterialApp(
  navigatorKey: navigator,
  theme: ThemeData.dark().copyWith(
    textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      textScaler: TextScaler.linear(scale),
    ),
    child: child!,
  ),
  home: RepaintBoundary(
    key: _captureKey,
    child: Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: ZyraPullDownBackScope(
          routeIdentity: ('photo-add', owner),
          onBack: () => owner.closes++,
          child: EditPhotosScreen.preview(
            key: const ValueKey('photo-add-editor'),
            canAct: owner.guard,
            initialPhotos: _assets.take(count).toList(),
            gender: 'female',
            initialAlignmentX: 0,
            initialAlignmentY: 0,
            onPhotosChanged: owner.publish,
            onAvatarChanged: owner.publishAvatar,
            hapticLevel: ZyraHapticLevel.off,
            photoBatchRunner: runner,
          ),
        ),
      ),
    ),
  ),
);

Future<void> _decodeMountedImages(WidgetTester tester) async {
  for (final element in find.byType(Image).evaluate().toList()) {
    Object? failure;
    await tester.runAsync(
      () => precacheImage(
        (element.widget as Image).image,
        element,
        onError: (error, _) => failure = error,
      ).timeout(const Duration(seconds: 5)),
    );
    expect(failure, isNull);
  }
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester,
  _Owner owner, {
  int count = 1,
  Size size = const Size(393, 852),
  double scale = 1,
  ZyraPhotoBatchRunner? runner,
  GlobalKey<NavigatorState>? navigator,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      owner,
      count: count,
      scale: scale,
      runner: runner,
      navigator: navigator,
    ),
  );
  await tester.pumpAndSettle();
  await _decodeMountedImages(tester);
  expect(tester.takeException(), isNull);
}

double _page(WidgetTester tester) =>
    tester.widget<PageView>(_pager).controller!.page!;

void _expectPages(WidgetTester tester, int actualCount) {
  final pager = tester.widget<PageView>(_pager);
  expect(pager.physics, isA<ClampingScrollPhysics>());
  expect(
    pager.childrenDelegate.estimatedChildCount,
    actualCount + (actualCount < 5 ? 1 : 0),
  );
  for (var index = 0; index < actualCount; index++) {
    expect(_key('photo-page-dot-$index'), findsOneWidget);
  }
  expect(_key('photo-page-dot-$actualCount'), findsNothing);
  expect(
    _key('photo-add-page-indicator'),
    actualCount < 5 ? findsOneWidget : findsNothing,
  );
}

Future<void> _swipeTo(WidgetTester tester, int target) async {
  while ((_page(tester) - target).abs() > .01) {
    final before = _page(tester);
    await tester.timedDrag(
      _pager,
      Offset(before < target ? -300 : 300, 0),
      const Duration(milliseconds: 350),
    );
    await tester.pumpAndSettle();
    expect(
      (_page(tester) - before).abs(),
      closeTo(1, .01),
      reason: 'Each real horizontal swipe must reach the next gallery page.',
    );
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  await _decodeMountedImages(tester);
  if (name == '01-one-photo' || name == '03-five-photos') {
    final painted = find.descendant(
      of: _key('photo-large-0'),
      matching: find.byType(RawImage),
    );
    expect(painted, findsOneWidget);
    final image = tester.widget<RawImage>(painted).image;
    expect(image, isNotNull);
    expect(image!.width, greaterThan(0));
    expect(image.height, greaterThan(0));
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldStubs = ZyraText.useTestFontStubs;
  final oldFamily = ZyraText.testReadingFontFamily;
  final oldHttp = HttpOverrides.current;
  late _NoNetwork network;
  late List<String> memberPhotos;
  final nativeCalls = <String>[];

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError(
          'Capture output must be an existing absolute directory.',
        );
      }
      var path = '';
      for (final component
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (component == '.' || component == '..') {
          throw StateError('Capture output cannot contain aliases.');
        }
        path += '/$component';
        if (FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError(
            'Capture output must be existing nonlinked directories.',
          );
        }
      }
    }
    final font = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    memberPhotos = List<String>.of(AppState.instance.photos);
    network = _NoNetwork();
    HttpOverrides.global = network;
    nativeCalls.clear();
    for (final channel in _nativeChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            nativeCalls.add('${channel.name}:${call.method}');
            throw PlatformException(code: 'fixture-picker-not-allowed');
          });
    }
  });

  tearDown(() {
    expect(network.attempts, 0);
    expect(nativeCalls, isEmpty);
    expect(AppState.instance.photos, memberPhotos);
    HttpOverrides.global = oldHttp;
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFamily;
    for (final channel in _nativeChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  for (final count in [1, 4]) {
    testWidgets('$count photos swipe to one virtual Add page and back', (
      tester,
    ) async {
      final owner = _Owner();
      var calls = 0;
      await _mount(
        tester,
        owner,
        count: count,
        runner: (_, remaining, _) async {
          calls++;
          return const ZyraPhotoBatchResult.cancelled();
        },
      );
      _expectPages(tester, count);
      if (count == 1) await _capture(tester, '01-one-photo');
      await _swipeTo(tester, count);
      expect(_add.hitTestable(), findsOneWidget);
      expect(find.text('Add a new photo'), findsOneWidget);
      expect(calls, 0, reason: 'Swiping is not permission to open the picker.');
      expect(owner.updates, isEmpty);
      expect(owner.closes, 0);
      for (final prefix in [
        'adjust-photo',
        'remove-photo',
        'make-main-revealed',
      ]) {
        expect(
          find.descendant(
            of: _key('photos-add-page'),
            matching: _key('$prefix-$count'),
          ),
          findsNothing,
        );
      }
      if (count == 1) await _capture(tester, '02-add-page');
      await tester.timedDrag(
        _pager,
        const Offset(-300, 0),
        const Duration(milliseconds: 350),
      );
      await tester.pumpAndSettle();
      expect(_page(tester), closeTo(count.toDouble(), .01));
      expect(owner.closes, 0);
      await _swipeTo(tester, count - 1);
      expect(_key('photo-large-${count - 1}').hitTestable(), findsOneWidget);
      expect(_add.hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'native Add tap reviews once and never publishes a virtual entry',
    (tester) async {
      final owner = _Owner();
      final reviewed = Completer<ZyraPhotoBatchResult>();
      var calls = 0;
      await _mount(
        tester,
        owner,
        runner: (_, remaining, _) {
          calls++;
          expect(remaining, 4);
          return reviewed.future;
        },
      );
      await _swipeTo(tester, 1);
      final semantics = tester.ensureSemantics();
      try {
        final data = tester.getSemantics(_add).getSemanticsData();
        expect(data.label, 'Add a new photo');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(find.bySemanticsLabel('Photo 2 of 1'), findsNothing);
        final stale = tester.widget<InkWell>(_add).onTap!;
        await tester.tap(_add);
        stale();
        expect(calls, 1);
        reviewed.complete(ZyraPhotoBatchResult.added([_assets[1]]));
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(owner.updates, [
          [_assets[0], _assets[1]],
        ]);
        _expectPages(tester, 2);
        expect(_page(tester), closeTo(1, .01));
        expect(_key('photo-large-1').hitTestable(), findsOneWidget);
      } finally {
        semantics.dispose();
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final result in [
    const ZyraPhotoBatchResult.cancelled(),
    const ZyraPhotoBatchResult.error(),
  ]) {
    testWidgets('${result.outcome.name} leaves the virtual page available', (
      tester,
    ) async {
      final owner = _Owner();
      var calls = 0;
      await _mount(
        tester,
        owner,
        runner: (_, _, _) async {
          calls++;
          return result;
        },
      );
      await _swipeTo(tester, 1);
      await tester.tap(_add);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(owner.updates, isEmpty);
      expect(_page(tester), closeTo(1, .01));
      expect(_add.hitTestable(), findsOneWidget);
      expect(tester.widget<InkWell>(_add).onTap, isNotNull);
      if (result.outcome == ZyraPhotoBatchOutcome.error) {
        expect(find.text(result.memberErrorMessage), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('busy Add disables duplicate taps and stale callbacks', (
    tester,
  ) async {
    final owner = _Owner();
    final pending = Completer<ZyraPhotoBatchResult>();
    var calls = 0;
    await _mount(
      tester,
      owner,
      runner: (_, _, _) {
        calls++;
        return pending.future;
      },
    );
    await _swipeTo(tester, 1);
    final stale = tester.widget<InkWell>(_add).onTap!;
    await tester.tap(_add);
    await tester.pump();
    expect(tester.widget<InkWell>(_add).onTap, isNull);
    stale();
    await tester.pump();
    expect(calls, 1);
    expect(owner.updates, isEmpty);
    pending.complete(const ZyraPhotoBatchResult.cancelled());
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(_add).onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the fifth photo removes Add and a retained action cannot add six',
    (tester) async {
      final owner = _Owner();
      var calls = 0;
      await _mount(
        tester,
        owner,
        count: 4,
        runner: (_, remaining, _) async {
          calls++;
          expect(remaining, 1);
          return ZyraPhotoBatchResult.added([_assets[4]]);
        },
      );
      await _swipeTo(tester, 4);
      final stale = tester.widget<InkWell>(_add).onTap!;
      await tester.tap(_add);
      await tester.pumpAndSettle();
      expect(owner.updates.single, _assets.take(5).toList());
      _expectPages(tester, 5);
      expect(_page(tester), closeTo(4, .01));
      expect(_key('photos-add-page'), findsNothing);
      stale();
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(owner.updates, hasLength(1));
      await tester.tap(_key('photos-compact-toggle'));
      await tester.pumpAndSettle();
      expect(find.text('All photo spaces used'), findsOneWidget);
      for (var index = 0; index < 5; index++) {
        expect(_key('compact-photo-$index'), findsOneWidget);
        expect(_key('compact-add-$index'), findsNothing);
      }
      expect(_key('compact-photo-5'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final count in [5, 6]) {
    testWidgets(
      '$count retained photos stay viewable without another Add page',
      (tester) async {
        final owner = _Owner();
        var calls = 0;
        await _mount(
          tester,
          owner,
          count: count,
          runner: (_, _, _) async {
            calls++;
            return const ZyraPhotoBatchResult.cancelled();
          },
        );
        _expectPages(tester, count);
        if (count == 5) await _capture(tester, '03-five-photos');
        await _swipeTo(tester, count - 1);
        expect(_key('photos-add-page'), findsNothing);
        expect(_key('photo-large-${count - 1}').hitTestable(), findsOneWidget);
        await tester.tap(_key('photos-compact-toggle'));
        await tester.pumpAndSettle();
        expect(find.text('All photo spaces used'), findsOneWidget);
        for (var index = 0; index < count; index++) {
          expect(_key('compact-photo-$index'), findsOneWidget);
          expect(_key('compact-add-$index'), findsNothing);
        }
        expect(_key('compact-photo-$count'), findsNothing);
        expect(calls, 0);
        expect(owner.updates, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('legacy sixth photo still opens crop review and can be removed', (
    tester,
  ) async {
    final owner = _Owner();
    await _mount(tester, owner, count: 6);
    await _swipeTo(tester, 5);
    await tester.drag(_key('photo-large-5'), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(_key('adjust-photo-5').hitTestable(), findsOneWidget);
    await tester.tap(_key('adjust-photo-5'));
    for (
      var attempt = 0;
      attempt < 60 && find.byType(PhotoCropReviewScreen).evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.byType(PhotoCropReviewScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    bool cropReady() {
      final confirm = _key('photo-crop-confirm');
      return confirm.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(confirm).onPressed != null;
    }

    for (var attempt = 0; attempt < 60 && !cropReady(); attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(cropReady(), isTrue, reason: 'The legacy photo crop must decode.');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cancel photo editing'), findsNothing);
    final back = _key('zyra_visible_back_button');
    expect(back, findsNothing);
    await swipeZyraBack(tester);
    expect(find.byType(PhotoCropReviewScreen), findsNothing);
    expect(owner.updates, isEmpty);
    expect(_page(tester), closeTo(5, .01));
    await tester.tap(_key('remove-photo-5'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this photo?'), findsOneWidget);
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(owner.updates.single, _assets.take(5).toList());
    _expectPages(tester, 5);
    expect(_key('photos-add-page'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switching from virtual Add to grid selects the last real photo',
    (tester) async {
      final owner = _Owner();
      await _mount(tester, owner, count: 4);
      await _swipeTo(tester, 4);
      await tester.tap(_key('photos-compact-toggle'));
      await tester.pumpAndSettle();
      expect(_key('compact-photo-3'), findsOneWidget);
      expect(_key('compact-photo-4'), findsNothing);
      expect(_key('compact-add-4'), findsOneWidget);
      await tester.tap(find.text('Make main photo'));
      await tester.pumpAndSettle();
      expect(owner.updates.single.first, _assets[3]);
      expect(owner.updates.single, hasLength(4));
      expect(_page(tester), closeTo(0, .01));
      expect(owner.avatars.single, Offset.zero);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'revoked Add and late picker results remain inert after owner ABA',
    (tester) async {
      final owner = _Owner();
      final pending = Completer<ZyraPhotoBatchResult>();
      var calls = 0;
      await _mount(
        tester,
        owner,
        runner: (_, _, _) {
          calls++;
          return pending.future;
        },
      );
      await _swipeTo(tester, 1);
      final stale = tester.widget<InkWell>(_add).onTap!;
      await tester.tap(_add);
      owner.allowed = false;
      stale();
      pending.complete(ZyraPhotoBatchResult.added([_assets[1]]));
      await tester.pumpAndSettle();
      expect(_key('photos-preview-unavailable'), findsOneWidget);
      expect(owner.updates, isEmpty);
      owner.allowed = true;
      stale();
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(owner.updates, isEmpty);
      expect(_key('photos-preview-unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a covered gallery denies retained Add until its route returns', (
    tester,
  ) async {
    final owner = _Owner();
    final navigator = GlobalKey<NavigatorState>();
    var calls = 0;
    await _mount(
      tester,
      owner,
      navigator: navigator,
      runner: (_, _, _) async {
        calls++;
        return const ZyraPhotoBatchResult.cancelled();
      },
    );
    await _swipeTo(tester, 1);
    final stale = tester.widget<InkWell>(_add).onTap!;
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Covered'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(owner.updates, isEmpty);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_add.hitTestable(), findsOneWidget);
    await tester.tap(_add);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(owner.updates, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed Add ignores its late reviewed result', (tester) async {
    final owner = _Owner();
    final pending = Completer<ZyraPhotoBatchResult>();
    await _mount(tester, owner, runner: (_, _, _) => pending.future);
    await _swipeTo(tester, 1);
    await tester.tap(_add);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(ZyraPhotoBatchResult.added([_assets[1]]));
    await tester.pumpAndSettle();
    expect(owner.updates, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final added in <List<String>>[
    const [],
    [_assets[4], _assets[5]],
  ]) {
    testWidgets(
      'four-photo Add rejects ${added.length} invalid reviewed results',
      (tester) async {
        final owner = _Owner();
        await _mount(
          tester,
          owner,
          count: 4,
          runner: (_, remaining, _) async {
            expect(remaining, 1);
            return ZyraPhotoBatchResult.added(added);
          },
        );
        await _swipeTo(tester, 4);
        await tester.tap(_add);
        await tester.pumpAndSettle();
        expect(owner.updates, isEmpty);
        expect(
          find.text('Those photos could not be added. Please try again.'),
          findsOneWidget,
        );
        _expectPages(tester, 4);
        expect(_add.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Add page fits 320px double text and exposes one meaningful action',
    (tester) async {
      final owner = _Owner();
      await _mount(
        tester,
        owner,
        size: const Size(320, 568),
        scale: 2,
        runner: (_, _, _) async => const ZyraPhotoBatchResult.cancelled(),
      );
      await _swipeTo(tester, 1);
      final semantics = tester.ensureSemantics();
      try {
        final action = tester.getRect(_add);
        final icon = tester.widget<Icon>(_key('photos-add-page-icon'));
        final title = tester.widget<Text>(_key('photos-add-page-title'));
        expect(icon.size, 64);
        expect(action.width, greaterThanOrEqualTo(44));
        expect(action.height, greaterThanOrEqualTo(44));
        expect(title.data, 'Add a new photo');
        expect(title.maxLines, isNull);
        expect(title.overflow, isNull);
        for (final key in ['photos-add-page-icon', 'photos-add-page-title']) {
          final content = tester.getRect(_key(key));
          expect(content.left, greaterThanOrEqualTo(action.left));
          expect(content.right, lessThanOrEqualTo(action.right));
          expect(content.top, greaterThanOrEqualTo(action.top));
          expect(content.bottom, lessThanOrEqualTo(action.bottom));
        }
        final paragraph = tester.renderObject<RenderParagraph>(
          _key('photos-add-page-title'),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        final data = tester.getSemantics(_add).getSemanticsData();
        expect(data.label, 'Add a new photo');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(find.bySemanticsLabel('Photo 2 of 1'), findsNothing);
        await _capture(tester, '04-add-page-compact-200');
      } finally {
        semantics.dispose();
      }
      expect(owner.closes, 0);
      expect(owner.updates, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
