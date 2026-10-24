// Ordinary display ownership follows the actual SDK as well as AccountState.
// All Auth sessions and HTTP responses below are synthetic and local.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/profile/past_journeys_screen.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';

const _a = '00000000-0000-4000-8000-000000001324';
const _b = '00000000-0000-4000-8000-000000001325';
var _sessionRevision = 0;
final _photo = _localPhoto();

String _localPhoto() {
  final photo = img.Image(width: 30, height: 40);
  img.fill(photo, color: img.ColorRgb8(90, 70, 110));
  return 'data:image/png;base64,${base64Encode(img.encodePng(photo))}';
}

const _paused = JourneyMatch(
  matchId: 'sdk-history-attempt',
  status: 'active',
  pause: ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
  profile: SeekerProfile(
    id: 'sdk-history-peer',
    firstName: 'Maryam',
    age: 29,
    city: 'Leeds',
    gender: 'female',
    photos: [],
  ),
);

Future<void> _sdkSession(String id) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'session_id': ++_sessionRevision, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-13T00:00:00Z',
      },
    }),
  );
}

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var requests = 0;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests++;
        throw StateError(
          'Display fixture attempted an unexpected HTTP request.',
        );
      }),
    );
  });
  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await _sdkSession(_a);
    await ZyraAccountState.synchronize(_a);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(
      name: 'Adam',
      gender: 'male',
      dob: DateTime(1997, 3, 14),
      location: 'London',
      plan: ZyraPlan.one,
    );
    AppState.instance.photos = [_photo];
    requests = 0;
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.clearImagesForTesting = null;
    ZyraInternalPreviewClient.finishSignOut();
  });
  tearDownAll(() => Supabase.instance.dispose());

  void displayTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
        expect(requests, 0, reason: 'No member transport in display fixtures');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester);
        await tester.runAsync(() => ZyraAccountState.synchronize(null));
        await _flush(tester);
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  displayTest('profile image fixture decodes completely offline', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        base64Decode(_photo.split(',').last),
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          expect(frame.image.width, greaterThan(0));
          expect(frame.image.height, greaterThan(0));
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    });
    expect(tester.takeException(), isNull);
  });

  for (final surface in ['profile', 'history']) {
    for (final replacement in ['different SDK owner', 'SDK A B A']) {
      displayTest(
        '$surface withdraws on $replacement before AccountState binds',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: surface == 'profile'
                  ? const MyProfilePreviewScreen()
                  : PastJourneysScreen(
                      loader: ({required statuses}) async =>
                          statuses.single == 'active' ? [_paused] : [],
                    ),
            ),
          );
          await tester.pumpAndSettle();
          if (surface == 'profile') {
            // Identity copy is intentionally IgnorePointer so photo gestures
            // pass through it. Assert its actual model and on-screen bounds,
            // not whether that non-interactive label accepts a pointer.
            final name = find.text('Adam');
            expect(name, findsOneWidget);
            final rendered = tester.widget<ZyraBrowseDesigns>(
              find.byType(ZyraBrowseDesigns),
            );
            expect(rendered.readOnlyPreview, isTrue);
            expect(rendered.design, ZyraOneJourneyBrowseDesign.portraitCard);
            expect(rendered.profiles, hasLength(1));
            expect(rendered.profiles.single.firstName, 'Adam');
            expect(rendered.profiles.single.city, 'London');
            expect(rendered.profiles.single.photos, [_photo]);
            expect(find.byType(SeekerProfileScreen), findsNothing);
            final nameBounds = tester.getRect(name);
            final viewport = tester.getRect(find.byType(ZyraBrowseDesigns));
            expect(nameBounds.height, greaterThan(0));
            expect(nameBounds.top, greaterThanOrEqualTo(viewport.top));
            expect(nameBounds.bottom, lessThanOrEqualTo(viewport.bottom));
            expect(nameBounds.left, greaterThanOrEqualTo(viewport.left));
            expect(nameBounds.right, lessThanOrEqualTo(viewport.right));
          } else {
            expect(find.text('Maryam, 29').hitTestable(), findsOneWidget);
          }
          final generation = ZyraAccountState.generation;
          await tester.runAsync(() async {
            await _sdkSession(_b);
            if (replacement == 'SDK A B A') await _sdkSession(_a);
          });
          expect(ZyraAccountState.userId, _a);
          expect(ZyraAccountState.generation, generation);
          await _flush(tester);
          expect(
            find.byType(ZyraBrowseDesigns, skipOffstage: false),
            findsNothing,
          );
          expect(find.byType(SeekerProfileScreen), findsNothing);
          expect(find.text('Adam', skipOffstage: false), findsNothing);
          expect(find.text('Maryam, 29', skipOffstage: false), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  displayTest('SDK replacement prevents the second sequential history read', (
    tester,
  ) async {
    final first = Completer<List<JourneyMatch>?>();
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PastJourneysScreen(
          loader: ({required statuses}) {
            calls.add(statuses.single);
            return statuses.single == 'active'
                ? first.future
                : Future.value([]);
          },
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() => _sdkSession(_b));
    first.complete([_paused]);
    await _flush(tester);
    expect(calls, ['active']);
    expect(find.text('Maryam, 29', skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
