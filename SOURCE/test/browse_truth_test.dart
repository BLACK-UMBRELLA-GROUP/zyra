import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/browse/browse_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_discovery_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_photo_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var mode = 'empty';
  setUpAll(() async {
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
  tearDownAll(() => Supabase.instance.dispose());
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
