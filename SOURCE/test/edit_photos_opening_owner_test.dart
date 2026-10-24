// OA304: actual ordinary Photos must stay bound to its opening principal.
// All Auth sessions, URLs and HTTP responses are synthetic. The injected
// MockClient rejects unrelated traffic; no production service is contacted.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
// The plugin's supported platform interface keeps this picker memory-only.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Cache plugin calls are redirected to a test-owned temporary repository.
// ignore: depend_on_referenced_packages
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/profile/avatar_adjust_screen.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/photo_crop_review_screen.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_image_cache.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000000871';
const _b = '00000000-0000-4000-8000-000000000872';
const _origin = 'https://photo-opening.invalid';
const _editor = ValueKey('opening-photo-editor');
const _fixtureDeadline = Duration(seconds: 4);
String _photo(String owner, String file) =>
    '$_origin/storage/v1/object/sign/profile-photos/$owner/$file?token=synthetic';
Finder _key(String value) => find.byKey(ValueKey(value));

Uint8List _portraitPhoto() {
  final image = img.Image(width: 60, height: 80);
  img.fill(image, color: img.ColorRgb8(92, 61, 112));
  return img.encodePng(image);
}

class _MemoryPicker extends ImagePickerPlatform {
  _MemoryPicker(this.photos, {this.release});
  final List<Uint8List> photos;
  final Completer<void>? release;
  int calls = 0;

  void releasePending() {
    final gate = release;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    calls++;
    await release?.future.timeout(_fixtureDeadline);
    return [
      for (final bytes in photos) XFile.fromData(bytes, mimeType: 'image/png'),
    ];
  }
}

class _NoImageNetwork extends HttpOverrides {
  final requests = <String>[];

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _NoImageHttpClient(requests);
}

class _NoImageHttpClient implements HttpClient {
  _NoImageHttpClient(this.requests);
  final List<String> requests;

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    requests.add('$method ${url.origin}${url.path}');
    return Future.error(
      StateError('Photo paints must use the primed RAM cache.'),
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Backend {
  final calls = <String>[];
  final unexpected = <String>[];
  final readStarted = Completer<void>();
  final deleteStarted = Completer<void>();
  final uploadStarted = Completer<void>();
  Completer<List<Map<String, Object?>>>? readResult;
  Completer<void>? deleteRelease;
  Completer<void>? uploadRelease;
  List<Map<String, Object?>> inserted = [];
  bool acceptInsert = true;

  void releasePending() {
    final read = readResult;
    if (read != null && !read.isCompleted) read.complete([]);
    final deletion = deleteRelease;
    if (deletion != null && !deletion.isCompleted) deletion.complete();
    final upload = uploadRelease;
    if (upload != null && !upload.isCompleted) upload.complete();
  }

  http.Response _reply(
    http.Request request,
    Object? value, [
    int status = 200,
  ]) => http.Response(
    status == 204 ? '' : jsonEncode(value),
    status,
    headers: {'content-type': 'application/json'},
    request: request,
  );

  Future<http.Response> send(http.Request request) async {
    final path = request.url.path;
    if (request.url.origin != _origin) {
      unexpected.add('Unexpected synthetic origin');
      throw StateError('Only the synthetic endpoint is allowed.');
    }
    if (path == '/rest/v1/profile_photos') {
      calls.add(request.method);
      if (request.method == 'GET') {
        expectSync(request.url.queryParameters['user_id'], 'eq.$_a');
        if (!readStarted.isCompleted) readStarted.complete();
        final rows = readResult == null
            ? <Map<String, Object?>>[]
            : await readResult!.future.timeout(_fixtureDeadline);
        return _reply(request, rows);
      }
      if (request.method == 'DELETE') {
        expectSync(request.url.queryParameters['user_id'], 'eq.$_a');
        if (!deleteStarted.isCompleted) deleteStarted.complete();
        await deleteRelease?.future.timeout(_fixtureDeadline);
        return _reply(request, null, 204);
      }
      if (request.method == 'POST') {
        inserted = [
          for (final item in jsonDecode(request.body) as List)
            Map<String, Object?>.from(item as Map),
        ];
        expectSync(inserted.every((row) => row['user_id'] == _a), isTrue);
        return acceptInsert
            ? _reply(request, null, 201)
            : _reply(request, {
                'message': 'Synthetic photo save rejected',
                'code': '42501',
              }, 403);
      }
    }
    if (request.method == 'POST' &&
        path.startsWith('/storage/v1/object/profile-photos/$_a/')) {
      calls.add('UPLOAD');
      if (!uploadStarted.isCompleted) uploadStarted.complete();
      await uploadRelease?.future.timeout(_fixtureDeadline);
      return _reply(request, {
        'Key': path.substring('/storage/v1/object/'.length),
      });
    }
    if (request.method == 'POST' &&
        path == '/storage/v1/object/sign/profile-photos') {
      calls.add('SIGN');
      final body = jsonDecode(request.body) as Map;
      return _reply(request, [
        for (final item in body['paths'] as List)
          {
            'path': item,
            'signedURL': '/object/sign/profile-photos/$item?token=synthetic',
          },
      ]);
    }
    unexpected.add('${request.method} $path');
    throw StateError('Unrelated HTTP is refused by the synthetic transport.');
  }
}

var _sessionRevision = 0;
Future<void> _session(String id, {bool synchronize = true}) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.'
          '${part({'sub': id, 'exp': 4102444800, 'session_revision': ++_sessionRevision})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-18T00:00:00Z',
      },
    }),
  );
  if (synchronize) await ZyraAccountState.synchronize(id);
}

void _seed(String owner, {String file = 'fresh.jpg'}) {
  AppState.instance.setProfilePhotos([_photo(owner, file)]);
  AppState.instance.avatarAlignmentX = .35;
  AppState.instance.avatarAlignmentY = -.25;
}

Future<void> _flush(WidgetTester tester) async {
  // SDK transport/platform responses can complete outside FakeAsync, while
  // their continuations and queued presentation writes need a widget pump.
  // One real turn followed by one final pump can strand that second wave in
  // the outgoing test's zone and block the next setUp's preference cleanup.
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _until(
  WidgetTester tester,
  bool Function() done, {
  String reason = 'The synthetic photo workflow must progress.',
}) async {
  for (var attempt = 0; attempt < 80 && !done(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(done(), isTrue, reason: reason);
}

Future<void> _mount(
  WidgetTester tester, {
  ZyraPhotoBatchRunner? runner,
  GlobalKey<NavigatorState>? navigator,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await _primePhotoPaints(tester);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: EditPhotosScreen(key: _editor, photoBatchRunner: runner),
    ),
  );
  await _flush(tester);
  expect(tester.takeException(), isNull);
}

Future<void> _primePhotoPaints(WidgetTester tester) async {
  final image = await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(_portraitPhoto());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  });
  try {
    for (final owner in [_a, _b]) {
      for (final file in [
        'first.jpg',
        'second.jpg',
        'restored.jpg',
        'fresh.jpg',
        'obsolete.jpg',
      ]) {
        final url = _photo(owner, file);
        PaintingBinding.instance.imageCache.putIfAbsent(
          CachedNetworkImageProvider(
            url,
            cacheKey: ZyraImageCache.keyFor(url),
            cacheManager: ZyraImageCache.manager,
          ),
          () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: image!.clone())),
          ),
        );
      }
    }
    await tester.pump();
  } finally {
    image?.dispose();
  }
}

Future<VoidCallback> _mainAction(WidgetTester tester) async {
  await tester.tap(_key('photos-compact-toggle'));
  await tester.pumpAndSettle();
  await tester.tap(_key('compact-photo-1'));
  await tester.pumpAndSettle();
  final button = find.widgetWithText(FilledButton, 'Make main photo');
  expect(button.hitTestable(), findsOneWidget);
  return tester.widget<FilledButton>(button).onPressed!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Backend backend;
  late ImagePickerPlatform originalPicker;
  late Directory cacheRoot;
  sqflite.DatabaseFactory? previousDatabaseFactory;
  final oldHttp = HttpOverrides.current;
  final imageNetwork = _NoImageNetwork();
  var cacheInitialized = false;

  setUpAll(() async {
    backend = _Backend();
    originalPicker = ImagePickerPlatform.instance;
    HttpOverrides.global = imageNetwork;
    cacheRoot = await Directory.systemTemp.createTemp(
      'zyra-photo-opening-test-',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cacheRoot.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      (call) async => switch (call.method) {
        'openDatabase' => 1,
        'query' =>
          (call.arguments as Map?)?['sql'] == 'PRAGMA user_version'
              ? <Map<String, Object?>>[
                  {'user_version': 3},
                ]
              : <Map<String, Object?>>[],
        'batch' => <Object?>[],
        'insert' || 'update' => 0,
        'getDatabasesPath' => cacheRoot.path,
        'databaseExists' => false,
        _ => null,
      },
    );
    previousDatabaseFactory = sqflite.databaseFactoryOrNull;
    sqflite.databaseFactory = sqflite.databaseFactorySqflitePlugin;
    // The cache opens eagerly. Keep its platform setup outside FakeAsync;
    // pixels below are primed in RAM and never downloaded or stored on disk.
    await ZyraImageCache.manager
        .getFileFromCache('synthetic-not-present')
        .timeout(_fixtureDeadline);
    cacheInitialized = true;
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: _origin,
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) => backend.send(request)),
    );
  });

  setUp(() async {
    backend = _Backend();
    imageNetwork.requests.clear();
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    await ZyraLocalPrefs.clear().timeout(_fixtureDeadline);
    await _session(_a).timeout(_fixtureDeadline);
    AppState.instance.setProfilePhotos([
      _photo(_a, 'first.jpg'),
      _photo(_a, 'second.jpg'),
    ]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    try {
      expect(backend.unexpected, isEmpty);
      expect(
        imageNetwork.requests,
        isEmpty,
        reason: 'No image HTTP or real native cache access.',
      );
    } finally {
      ZyraText.useTestFontStubs = false;
      ZyraAccountState.clearImagesForTesting = null;
      ImagePickerPlatform.instance = originalPicker;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    }
  });
  tearDownAll(() async {
    try {
      await Supabase.instance.dispose();
      if (cacheInitialized) await ZyraImageCache.manager.dispose();
    } finally {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('com.tekartik.sqflite'),
        null,
      );
      sqflite.databaseFactory = previousDatabaseFactory;
      HttpOverrides.global = oldHttp;
      await cacheRoot.delete(recursive: true);
    }
  });

  void photoTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        // Finish this test's async work while its FakeAsync zone is alive.
        // Never carry an avatar preference write or an intentionally held
        // synthetic HTTP response into the next test's setup zone.
        await tester.pumpWidget(const SizedBox.shrink());
        final picker = ImagePickerPlatform.instance;
        if (picker is _MemoryPicker) picker.releasePending();
        backend.releasePending();
        await _flush(tester);
        var preferencesDrained = false;
        unawaited(
          ZyraLocalPrefs.bindAccount(ZyraLocalPrefs.accountOwner).then((_) {
            preferencesDrained = true;
          }),
        );
        await _until(
          tester,
          () => preferencesDrained,
          reason:
              'Photo preference writes must finish in their owning test zone.',
        );
        await tester.runAsync(
          () => ZyraAccountState.synchronize(null).timeout(_fixtureDeadline),
        );
        await _flush(tester);
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  photoTest('current opening owner can promote a photo and persist its order', (
    tester,
  ) async {
    await _mount(tester);
    final promote = await _mainAction(tester);
    promote();
    await _until(
      tester,
      () =>
          backend.calls.contains('POST') &&
          _key('photos-page-view').evaluate().isNotEmpty,
      reason:
          'The same opening owner must complete the actual replacement POST and return to the gallery.',
    );
    await _flush(tester);
    expect(backend.calls, ['DELETE', 'POST']);
    expect(AppState.instance.photos, [
      _photo(_a, 'second.jpg'),
      _photo(_a, 'first.jpg'),
    ]);
    expect(backend.inserted.map((row) => row['storage_path']), [
      '$_a/second.jpg',
      '$_a/first.jpg',
    ]);
    expect(_key('photos-page-view'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  photoTest(
    'owned restore publishes only after the opening owner is confirmed',
    (tester) async {
      AppState.instance.setProfilePhotos([]);
      backend.readResult = Completer<List<Map<String, Object?>>>();
      await _mount(tester);
      await _until(
        tester,
        () => backend.readStarted.isCompleted,
        reason: 'The opening owner must start its synthetic restore read.',
      );
      backend.readResult!.complete([
        {'storage_path': '$_a/restored.jpg', 'display_order': 0},
      ]);
      await _until(
        tester,
        () => AppState.instance.photos.contains(_photo(_a, 'restored.jpg')),
        reason:
            'The confirmed opening owner restore must publish its signed photo.',
      );
      await _flush(tester);
      expect(backend.calls, ['GET', 'SIGN']);
      expect(AppState.instance.photos, [_photo(_a, 'restored.jpg')]);
      expect(_key('photo-large-0'), findsOneWidget);
    },
  );

  for (final aba in [false, true]) {
    photoTest('late restore cannot replace ${aba ? 'new A' : 'B'} photos', (
      tester,
    ) async {
      AppState.instance.setProfilePhotos([]);
      backend.readResult = Completer<List<Map<String, Object?>>>();
      await _mount(tester);
      await _until(tester, () => backend.readStarted.isCompleted);
      await tester.runAsync(() async {
        await _session(_b);
        if (aba) await _session(_a);
      });
      _seed(aba ? _a : _b);
      final expected = List.of(AppState.instance.photos);
      backend.readResult!.complete([
        {'storage_path': '$_a/obsolete.jpg', 'display_order': 0},
      ]);
      await _flush(tester);
      expect(AppState.instance.photos, expected);
      expect(backend.calls, ['GET']);
      expect(_key('photos-owner-unavailable'), findsOneWidget);
      expect(_key('photo-large-0'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    photoTest('late save cannot roll old photos into ${aba ? 'new A' : 'B'}', (
      tester,
    ) async {
      backend.deleteRelease = Completer<void>();
      await _mount(tester);
      final promote = await _mainAction(tester);
      promote();
      await _until(
        tester,
        () => backend.deleteStarted.isCompleted,
        reason:
            'The first owner DELETE must be in flight before replacing the account.',
      );
      expect(AppState.instance.photos.first, _photo(_a, 'second.jpg'));
      await tester.runAsync(() async {
        await _session(_b);
        if (aba) await _session(_a);
      });
      _seed(aba ? _a : _b);
      final expected = List.of(AppState.instance.photos);
      backend.deleteRelease!.complete();
      await _flush(tester);
      expect(AppState.instance.photos, expected);
      expect(AppState.instance.avatarAlignmentX, .35);
      expect(AppState.instance.avatarAlignmentY, -.25);
      expect(backend.calls, ['DELETE']);
      expect(_key('photos-owner-unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final accepted in [true, false]) {
    photoTest(
      'covered save reconciles its ${accepted ? 'ACK' : 'rejection'} and releases busy state',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        backend.acceptInsert = accepted;
        backend.deleteRelease = Completer<void>();
        await _mount(tester, navigator: navigator);
        final original = List.of(AppState.instance.photos);
        final promote = await _mainAction(tester);
        promote();
        await _until(tester, () => backend.deleteStarted.isCompleted);
        final cover = navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Unrelated save cover')),
          ),
        );
        await tester.pumpAndSettle();
        backend.deleteRelease!.complete();
        bool editorReady() {
          final toggles = find
              .byKey(
                const ValueKey('photos-compact-toggle'),
                skipOffstage: false,
              )
              .evaluate();
          return backend.calls.contains('POST') &&
              toggles.length == 1 &&
              (toggles.single.widget as IconButton).onPressed != null;
        }

        await _until(
          tester,
          editorReady,
          reason:
              'The current owner must reconcile the save result and release busy state behind a cover.',
        );
        expect(find.text('Unrelated save cover'), findsOneWidget);
        expect(backend.calls, ['DELETE', 'POST']);
        expect(
          AppState.instance.photos,
          accepted
              ? [_photo(_a, 'second.jpg'), _photo(_a, 'first.jpg')]
              : original,
        );
        navigator.currentState!.pop();
        await cover;
        await _flush(tester);
        expect(
          tester.widget<IconButton>(_key('photos-compact-toggle')).onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  photoTest('saved main action cannot act after account ABA', (tester) async {
    await _mount(tester);
    final promote = await _mainAction(tester);
    await tester.runAsync(() async {
      await _session(_b);
      await _session(_a);
    });
    _seed(_a);
    final expected = List.of(AppState.instance.photos);
    promote();
    await _flush(tester);
    expect(AppState.instance.photos, expected);
    expect(backend.calls, isEmpty);
    expect(_key('photos-owner-unavailable'), findsOneWidget);
  });

  photoTest('late injected picker result cannot populate a replacement owner', (
    tester,
  ) async {
    AppState.instance.setProfilePhotos([_photo(_a, 'first.jpg')]);
    final pending = Completer<ZyraPhotoBatchResult>();
    ValueChanged<String?>? progress;
    var calls = 0;
    await _mount(
      tester,
      runner: (context, remaining, onProgress) {
        calls++;
        expect(remaining, 4);
        progress = onProgress;
        return pending.future;
      },
    );
    await tester.drag(_key('photos-page-view'), const Offset(-350, 0));
    await tester.pumpAndSettle();
    await tester.tap(_key('photos-add-page-action'));
    await tester.pump();
    expect(calls, 1);
    await tester.runAsync(() => _session(_b));
    _seed(_b);
    final expected = List.of(AppState.instance.photos);
    progress!('Obsolete picker progress');
    pending.complete(ZyraPhotoBatchResult.added([_photo(_a, 'obsolete.jpg')]));
    await _flush(tester);
    expect(AppState.instance.photos, expected);
    expect(find.text('Obsolete picker progress'), findsNothing);
    expect(backend.calls, isEmpty);
  });

  photoTest(
    'same SDK principal with a new session revokes without router reset',
    (tester) async {
      await _mount(tester);
      final generation = ZyraAccountState.generation;
      final promote = await _mainAction(tester);
      await tester.runAsync(() => _session(_a, synchronize: false));
      await _flush(tester);
      expect(ZyraAccountState.generation, generation);
      promote();
      await _flush(tester);
      expect(backend.calls, isEmpty);
      expect(_key('photos-owner-unavailable'), findsOneWidget);
    },
  );

  photoTest('preference binding ABA terminally denies the old editor', (
    tester,
  ) async {
    await _mount(tester);
    final promote = await _mainAction(tester);
    await tester.runAsync(() async {
      await ZyraLocalPrefs.bindAccount(_b);
      await ZyraLocalPrefs.bindAccount(_a);
    });
    promote();
    await _flush(tester);
    expect(backend.calls, isEmpty);
    expect(_key('photos-owner-unavailable'), findsOneWidget);
  });

  photoTest('stale avatar save cannot publish or pop its covering route', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await _mount(tester, navigator: navigator);
    await tester.drag(_key('photo-large-0'), const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(_key('adjust-main-avatar'));
    await tester.pumpAndSettle();
    expect(find.byType(AvatarAdjustScreen), findsOneWidget);
    await tester.drag(_key('avatar-adjust-drag'), const Offset(-30, 20));
    await tester.pumpAndSettle();
    final save = tester
        .widget<FilledButton>(_key('avatar-adjust-save'))
        .onPressed!;
    final route = ModalRoute.of(
      tester.element(find.byType(AvatarAdjustScreen)),
    );
    await tester.runAsync(() => _session(_b));
    _seed(_b);
    final preferences = await SharedPreferences.getInstance();
    final before = {
      for (final key in preferences.getKeys()) key: preferences.get(key),
    };
    save();
    await _flush(tester);
    expect(route!.isCurrent, isTrue);
    expect(_key('avatar-owner-unavailable'), findsOneWidget);
    expect(_key('avatar-adjust-drag'), findsNothing);
    expect(AppState.instance.avatarAlignmentX, .35);
    expect(AppState.instance.avatarAlignmentY, -.25);
    expect({
      for (final key in preferences.getKeys()) key: preferences.get(key),
    }, before);
    expect(backend.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  photoTest(
    'avatar header Back returns normally but denies cover and replacement',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await _mount(tester, navigator: navigator);
      await tester.drag(_key('photo-large-0'), const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(_key('adjust-main-avatar'));
      await tester.pumpAndSettle();
      Finder headerBack() => find.descendant(
        of: find.byType(AvatarAdjustScreen),
        matching: find.widgetWithIcon(IconButton, Icons.arrow_back_ios_new),
      );
      tester.widget<IconButton>(headerBack()).onPressed!();
      await _flush(tester);
      expect(find.byType(AvatarAdjustScreen), findsNothing);
      expect(_key('photos-page-view'), findsOneWidget);

      await tester.tap(_key('adjust-main-avatar'));
      await tester.pumpAndSettle();
      final back = tester.widget<IconButton>(headerBack()).onPressed!;
      final avatarRoute = ModalRoute.of(
        tester.element(find.byType(AvatarAdjustScreen)),
      );
      final cover = navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Unrelated avatar cover')),
        ),
      );
      await tester.pumpAndSettle();
      back();
      await _flush(tester);
      expect(find.text('Unrelated avatar cover'), findsOneWidget);
      expect(avatarRoute!.isCurrent, isFalse);

      await tester.runAsync(() => _session(_b));
      _seed(_b);
      back();
      await _flush(tester);
      expect(find.text('Unrelated avatar cover'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('avatar-owner-unavailable'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      navigator.currentState!.pop();
      await cover;
      await _flush(tester);
      expect(avatarRoute.isCurrent, isTrue);
      back();
      await _flush(tester);
      expect(avatarRoute.isCurrent, isTrue);
      expect(_key('avatar-owner-unavailable'), findsOneWidget);
      expect(AppState.instance.photos, [_photo(_b, 'fresh.jpg')]);
      expect(backend.calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  photoTest(
    'guarded picker returning under a cover cancels without a crop or upload',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final release = Completer<void>();
      final picker = _MemoryPicker([_portraitPhoto()], release: release);
      ImagePickerPlatform.instance = picker;
      final generation = ZyraAccountState.generation;
      ZyraPhotoBatchResult? completed;
      await _mount(
        tester,
        navigator: navigator,
        runner: (context, remaining, progress) async {
          final result = await runZyraPhotoBatchFlow(
            context,
            remaining: remaining,
            localPreview: false,
            onProgress: progress,
            canProceed: () =>
                ZyraAccountState.isCurrent(_a, generation) &&
                supabase.auth.currentUser?.id == _a,
          );
          completed = result;
          return result;
        },
      );
      tester
          .widget<PageView>(_key('photos-page-view'))
          .controller!
          .jumpToPage(2);
      await tester.pumpAndSettle();
      await tester.tap(_key('photos-add-page-action'));
      await _until(tester, () => picker.calls == 1);
      final cover = navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Unrelated picker cover')),
        ),
      );
      await tester.pumpAndSettle();
      release.complete();
      await _until(
        tester,
        () => completed != null,
        reason:
            'The guarded picker must finish as cancelled while its parent is covered.',
      );
      expect(completed!.outcome, ZyraPhotoBatchOutcome.cancelled);
      expect(find.text('Unrelated picker cover'), findsOneWidget);
      expect(
        find.byType(PhotoCropReviewScreen, skipOffstage: false),
        findsNothing,
      );
      expect(backend.calls, isEmpty);
      expect(AppState.instance.photos, [
        _photo(_a, 'first.jpg'),
        _photo(_a, 'second.jpg'),
      ]);
      navigator.currentState!.pop();
      await cover;
      await _flush(tester);
      expect(_key('photos-page-view'), findsOneWidget);
      expect(
        tester.widget<InkWell>(_key('photos-add-page-action')).onTap,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final aba in [false, true]) {
    photoTest(
      'ordinary batch crop withdraws after owner ${aba ? 'ABA' : 'change'}',
      (tester) async {
        final picker = _MemoryPicker([_portraitPhoto(), _portraitPhoto()]);
        ImagePickerPlatform.instance = picker;
        await _mount(tester);
        final pager = tester
            .widget<PageView>(_key('photos-page-view'))
            .controller!;
        pager.jumpToPage(2);
        await tester.pumpAndSettle();
        await tester.tap(_key('photos-add-page-action'));
        await _until(tester, () => find.byType(Crop).evaluate().isNotEmpty);
        expect(picker.calls, 1);
        final cropped = tester.widget<Crop>(find.byType(Crop)).onCropped;
        final route = ModalRoute.of(
          tester.element(find.byType(PhotoCropReviewScreen)),
        );
        await tester.runAsync(() async {
          await _session(_b);
          if (aba) await _session(_a);
        });
        _seed(aba ? _a : _b);
        final expected = List.of(AppState.instance.photos);
        await _flush(tester);
        expect(_key('crop-owner-unavailable'), findsOneWidget);
        expect(find.byType(Crop), findsNothing);
        cropped(CropSuccess(_portraitPhoto()));
        await _flush(tester);
        expect(route!.isCurrent, isTrue);
        expect(AppState.instance.photos, expected);
        expect(backend.calls, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    photoTest(
      'owner ${aba ? 'ABA' : 'change'} stops a batch before its next upload',
      (tester) async {
        ImagePickerPlatform.instance = _MemoryPicker([
          _portraitPhoto(),
          _portraitPhoto(),
        ]);
        backend.uploadRelease = Completer<void>();
        await _mount(tester);
        tester
            .widget<PageView>(_key('photos-page-view'))
            .controller!
            .jumpToPage(2);
        await tester.pumpAndSettle();
        await tester.tap(_key('photos-add-page-action'));
        await _until(tester, () => find.byType(Crop).evaluate().isNotEmpty);
        tester
            .widget<Crop>(find.byType(Crop))
            .onCropped(CropSuccess(_portraitPhoto()));
        await tester.pump();
        tester
            .widget<Crop>(find.byType(Crop))
            .onCropped(CropSuccess(_portraitPhoto()));
        await _until(tester, () => backend.uploadStarted.isCompleted);
        await tester.runAsync(() async {
          await _session(_b);
          if (aba) await _session(_a);
        });
        _seed(aba ? _a : _b);
        final expected = List.of(AppState.instance.photos);
        backend.uploadRelease!.complete();
        await _flush(tester);
        expect(backend.calls, ['UPLOAD']);
        expect(AppState.instance.photos, expected);
        expect(_key('photos-owner-unavailable'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  photoTest('ordinary local preview cannot revive after preview session ABA', (
    tester,
  ) async {
    ZyraInternalPreviewClient.beginPreview();
    await _mount(tester);
    final promote = await _mainAction(tester);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraInternalPreviewClient.beginPreview();
    _seed(_a);
    final expected = List.of(AppState.instance.photos);
    promote();
    await _flush(tester);
    expect(AppState.instance.photos, expected);
    expect(backend.calls, isEmpty);
    expect(_key('photos-owner-unavailable'), findsOneWidget);
  });
}
