import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
// The pinned cache manager's database factory is stubbed for this widget test.
// ignore: depend_on_referenced_packages
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/browse/browse_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_discovery_service.dart';
import 'package:zyra/services/zyra_image_cache.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_photo_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_profile_photo_frame.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var mode = 'empty';
  sqflite.DatabaseFactory? previousDatabaseFactory;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const cacheDatabase = MethodChannel('com.tekartik.sqflite');
  setUpAll(() async {
    final scratch = await Directory.systemTemp.createTemp('zyra-browse-paint-');
    messenger.setMockMethodCallHandler(pathProvider, (_) async => scratch.path);
    messenger.setMockMethodCallHandler(
      cacheDatabase,
      (call) async => switch (call.method) {
        'openDatabase' => 1,
        'query' =>
          (call.arguments as Map?)?['sql'] == 'PRAGMA user_version'
              ? <Map<String, Object?>>[
                  {'user_version': 3},
                ]
              : <Map<String, Object?>>[],
        'getDatabasesPath' => scratch.path,
        'databaseExists' => false,
        _ => null,
      },
    );
    previousDatabaseFactory = sqflite.databaseFactoryOrNull;
    sqflite.databaseFactory = sqflite.databaseFactorySqflitePlugin;
    await ZyraImageCache.manager.getFileFromCache('synthetic-not-present');
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        http.Response json(Object body, [int status = 200]) => http.Response(
          jsonEncode(body),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
        if (request.url.path == '/rest/v1/profiles') {
          if (mode == 'query_failure') return json({'message': 'offline'}, 503);
          if (request.url.queryParameters['select'] == 'gender') {
            return json({'gender': 'male'});
          }
          if (mode == 'empty') return json([]);
          return json([
            {
              'id': '00000000-0000-0000-0000-000000000812',
              'first_name': 'Aaliyah',
              'gender': 'female',
              'location_text': 'London',
              'profile_photos': [
                {'storage_path': 'synthetic/photo.jpg', 'display_order': 0},
              ],
            },
          ]);
        }
        if (request.url.path.contains('/object/sign/')) {
          return json([
            {
              'path': 'synthetic/photo.jpg',
              'signedURL': '/synthetic/photo.jpg?token=synthetic',
            },
          ]);
        }
        if (request.url.path.endsWith('/score_candidates')) {
          if (mode == 'score_failure') return json({'message': 'offline'}, 503);
          return json([]); // Server exclusion by Hard Requirements.
        }
        return json([]);
      }),
    );
  });
  tearDownAll(() async {
    try {
      await Supabase.instance.dispose();
      await ZyraImageCache.manager.dispose();
    } finally {
      messenger.setMockMethodCallHandler(pathProvider, null);
      messenger.setMockMethodCallHandler(cacheDatabase, null);
      sqflite.databaseFactory = previousDatabaseFactory;
    }
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    mode = 'empty';
    AppState.instance.resetForAccountChange();
    AppState.instance.plan = ZyraPlan.one;
    ZyraPhotoService.clearUrlMemoForSignOut();
  });
  tearDown(() {
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });

  test(
    'a signed-out discovery read is unavailable, not an empty success',
    () async {
      final result = await ZyraDiscoveryService.fetchCandidatesResult();
      expect(result.failure, ZyraSourceFailure.signedOut);
      expect(result.isAvailable, false);
    },
  );

  test('missing profile photo is a valid neutral placeholder', () {
    const profile = SeekerProfile(
      id: 'no-photo',
      firstName: 'Aaliyah',
      age: 27,
      city: 'London',
      photos: [],
      gender: 'female',
    );
    expect(profile.photoUrl, isEmpty);
  });

  Future<void> session() {
    const id = '00000000-0000-0000-0000-000000000811';
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return Supabase.instance.client.auth.setInitialSession(
      jsonEncode({
        'access_token':
            '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
        'token_type': 'bearer',
        'refresh_token': 'synthetic-refresh',
        'user': {
          'id': id,
          'app_metadata': <String, Object?>{},
          'user_metadata': <String, Object?>{},
          'aud': 'authenticated',
          'email': 'synthetic@example.invalid',
          'created_at': '2026-09-14T00:00:00Z',
        },
      }),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
  }

  void browseTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        // These widget fixtures must open for the actual synthetic SDK owner,
        // including when selected without the preceding service-read test.
        // Keep the earlier signed-out service test genuinely signed out.
        await tester.runAsync(() async {
          await session();
          await ZyraAccountState.synchronize(
            Supabase.instance.client.auth.currentUser!.id,
          );
        });
        await flush(tester);
        // Account synchronization clears display state; restore only this
        // fixture's existing local plan, not any backend entitlement.
        AppState.instance.plan = ZyraPlan.one;
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await flush(tester);
        await tester.runAsync(() => ZyraAccountState.synchronize(null));
        await flush(tester);
      }
    });
  }

  test(
    'HTTP query failure and failed Hard Requirement check never become candidate success',
    () async {
      await session();
      mode = 'query_failure';
      final query = await ZyraDiscoveryService.fetchCandidatesResult();
      expect(query.isUnavailable, true);
      mode = 'score_failure';
      final score = await ZyraDiscoveryService.fetchCandidatesResult();
      expect(score.isUnavailable, true);
      expect(score.valueOrNull, isNull);
      mode = 'excluded';
      final excluded = await ZyraDiscoveryService.fetchCandidatesResult();
      expect(excluded.isAvailable, true);
      expect(excluded.valueOrNull, isEmpty);
      mode = 'empty';
    },
  );

  browseTest(
    'failed Browse read shows retry, not all caught up; empty retry is truthful',
    (tester) async {
      var reads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowseScreen(
              loadHiddenIds: () async => const [],
              loadCandidates: () async => ++reads == 1
                  ? const ZyraSourceResult.unavailable(
                      ZyraSourceFailure.requestFailed,
                    )
                  : const ZyraSourceResult.available([]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t load profiles'), findsOneWidget);
      expect(find.text("You're all caught up"), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('Couldn’t load profiles'), findsNothing);
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('Advert preview'), findsNothing);
    },
  );

  browseTest('a throwing Browse source also leaves a visible retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowseScreen(
            loadHiddenIds: () async => const [],
            loadCandidates: () async => throw StateError('offline'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load profiles'), findsOneWidget);
    expect(find.text("You're all caught up"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in [const Size(430, 932), const Size(375, 667)]) {
    browseTest('ordinary Profiles paints all legacy photo edges at $viewport', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const urls = [
        'https://fixture.invalid/legacy-wide-first.jpg',
        'https://fixture.invalid/legacy-wide-second.jpg',
      ];
      final source = img.Image(width: 120, height: 80);
      img.fillRect(
        source,
        x1: 0,
        y1: 0,
        x2: 119,
        y2: 9,
        color: img.ColorRgb8(255, 0, 0),
      );
      img.fillRect(
        source,
        x1: 0,
        y1: 70,
        x2: 119,
        y2: 79,
        color: img.ColorRgb8(0, 0, 255),
      );
      img.fillRect(
        source,
        x1: 0,
        y1: 10,
        x2: 9,
        y2: 69,
        color: img.ColorRgb8(0, 255, 0),
      );
      img.fillRect(
        source,
        x1: 110,
        y1: 10,
        x2: 119,
        y2: 69,
        color: img.ColorRgb8(255, 255, 255),
      );

      // Ordinary Browse precaches and paints via the same cached provider.
      // Seed those exact keys with synthetic bytes and avoid network/disk.
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(img.encodePng(source));
        final image = (await codec.getNextFrame()).image;
        for (final url in urls) {
          final provider = CachedNetworkImageProvider(url);
          PaintingBinding.instance.imageCache.putIfAbsent(
            provider,
            () => OneFrameImageStreamCompleter(
              SynchronousFuture(ImageInfo(image: image.clone())),
            ),
          );
          addTearDown(
            () => PaintingBinding.instance.imageCache.evict(provider),
          );
        }
        image.dispose();
        codec.dispose();
      });
      const boundaryKey = ValueKey('ordinary-browse-photo-paint');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: BrowseScreen(
                loadHiddenIds: () async => const [],
                loadCandidates: () async => const ZyraSourceResult.available([
                  SeekerProfile(
                    id: 'synthetic-legacy-photo',
                    firstName: 'Aaliyah',
                    age: 27,
                    city: 'London',
                    gender: 'female',
                    photos: urls,
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final photo = find.byType(ZyraProfilePhotoFrame);
      final raw = find.descendant(of: photo, matching: find.byType(RawImage));
      final aperture = tester.getRect(raw);
      expect(aperture.size.aspectRatio, closeTo(3 / 4, .000001));
      expect(tester.widget<RawImage>(raw).fit, BoxFit.contain);
      final paintedSize = applyBoxFit(
        BoxFit.contain,
        const Size(120, 80),
        aperture.size,
      ).destination;
      final painted = Rect.fromCenter(
        center: aperture.center,
        width: paintedSize.width,
        height: paintedSize.height,
      );
      final boundaryFinder = find.byKey(boundaryKey);
      final origin = tester.getTopLeft(boundaryFinder);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        boundaryFinder,
      );
      final edges = await tester.runAsync(() async {
        final frame = await boundary.toImage();
        try {
          final bytes = (await frame.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          List<int> at(Offset point) {
            final local = point - origin;
            final offset =
                (local.dy.round() * frame.width + local.dx.round()) * 4;
            return [
              for (var channel = 0; channel < 3; channel++)
                bytes.getUint8(offset + channel),
            ];
          }

          return (
            top: at(Offset(painted.center.dx, painted.top + 5)),
            bottom: at(Offset(painted.center.dx, painted.bottom - 5)),
            left: at(Offset(painted.left + 5, painted.center.dy)),
            right: at(Offset(painted.right - 5, painted.center.dy)),
            center: at(painted.center),
          );
        } finally {
          frame.dispose();
        }
      });
      // Browse paints its original gradients over the photo.
      expect(edges!.top[0], greaterThan(edges.top[2] + 100));
      expect(edges.bottom[2], greaterThan(edges.bottom[0] + 100));
      expect(edges.left[1], greaterThan(edges.left[0] + 100));
      expect(edges.right[0], greaterThan(edges.center[0] + 100));
      expect(edges.right[1], greaterThan(edges.center[1] + 100));
      expect(edges.right[2], greaterThan(edges.center[2] + 100));

      final profileImage = find.descendant(
        of: photo,
        matching: find.byType(ZyraProfileImage),
      );
      expect(tester.widget<ZyraProfileImage>(profileImage).photo, urls[0]);
      await tester.tapAt(Offset(aperture.width * .75, aperture.top - 12));
      await tester.pumpAndSettle();
      expect(tester.widget<ZyraProfileImage>(profileImage).photo, urls[1]);
      expect(tester.takeException(), isNull);
      debugPrint('Ordinary Profiles aperture at $viewport: ${aperture.size}');
    });
  }

  browseTest('an older in-flight deck cannot overwrite a newer refresh', (
    tester,
  ) async {
    final older = Completer<ZyraSourceResult<List<SeekerProfile>>>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowseScreen(
            loadHiddenIds: () async => const [],
            loadCandidates: () => ++calls == 1
                ? older.future
                : Future.value(const ZyraSourceResult.available([])),
          ),
        ),
      ),
    );
    AppState.instance.refreshBrowseDeck();
    await tester.pumpAndSettle();
    expect(find.text("You're all caught up"), findsOneWidget);
    older.complete(
      const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed),
    );
    await tester.pumpAndSettle();
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.text('Couldn’t load profiles'), findsNothing);
  });

  browseTest('account replacement discards pending candidates', (tester) async {
    final pending = Completer<ZyraSourceResult<List<SeekerProfile>>>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowseScreen(
            loadHiddenIds: () async => const [],
            loadCandidates: () {
              calls++;
              return pending.future;
            },
          ),
        ),
      ),
    );
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
    pending.complete(
      const ZyraSourceResult.available([
        SeekerProfile(
          id: 'old-owner-pending-candidate',
          firstName: 'Previous account candidate',
          age: 27,
          city: 'London',
          gender: 'female',
          photos: [],
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('browse-owner-unavailable')),
      findsOneWidget,
    );
    expect(find.text('Previous account candidate'), findsNothing);
    expect(find.text("You're all caught up"), findsNothing);
    expect(find.text('Couldn’t load profiles'), findsNothing);
    expect(find.text('Try again'), findsNothing);
    expect(find.byType(ZyraBrowseMoreActionsButton), findsNothing);
    AppState.instance.refreshBrowseDeck();
    await tester.pumpAndSettle();
    expect(calls, 1, reason: 'An obsolete deck cannot dispatch a new read.');
    expect(
      find.byKey(const ValueKey('browse-owner-unavailable')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final unavailable in [true, false]) {
    browseTest(
      'personal-hide ${unavailable ? 'unknown' : 'confirmed'} state controls real deck',
      (tester) async {
        const peer = SeekerProfile(
          id: '00000000-0000-4000-8000-000000005301',
          firstName: 'Hidden candidate',
          age: 25,
          city: 'London',
          gender: 'female',
          photos: [],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BrowseScreen(
                loadCandidates: () async =>
                    const ZyraSourceResult.available([peer]),
                loadHiddenIds: () async => unavailable ? null : [peer.id],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Hidden candidate'), findsNothing);
        expect(
          find.text('Couldn’t load profiles'),
          unavailable ? findsOneWidget : findsNothing,
        );
        expect(
          find.text("You're all caught up"),
          unavailable ? findsNothing : findsOneWidget,
        );
      },
    );
  }
}
