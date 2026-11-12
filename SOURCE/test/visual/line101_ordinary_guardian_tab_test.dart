import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/widgets/zyra_swipe_track.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/wali/link_guardian_panel.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

const _owner = '00000000-0000-4000-8000-000000000101';
const _captureRoot = ValueKey('line101-ordinary-guardian-capture');
const _output = String.fromEnvironment('ZYRA_LINE101_ORDINARY_CAPTURE_DIR');
const _font = 'PoppinsOrdinaryGuardian';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _capture(WidgetTester tester, String name) async {
  if (_output.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureRoot),
    );
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$_output/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _signInFixture() async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': _owner, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': _owner,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-11-01T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(_owner);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var linkedCount = 0;
  late String localPhoto;
  final linkReads = <http.Request>[];

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.app_links/messages'),
        (_) async => null,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.app_links/events'),
        (_) async => null,
      );
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
    final photo = await rootBundle.load(
      'assets/dev/one_journey_photos/zyra3a.jpg',
    );
    localPhoto =
        'data:image/jpeg;base64,${base64Encode(photo.buffer.asUint8List())}';
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://generated.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        final path = request.url.path.split('/').last;
        final query = request.url.queryParameters;
        final guardIds = [for (var i = 0; i < linkedCount; i++) 'guardian-$i'];
        Object body = const [];
        if (path == 'wali_links' && query['seeker_id'] == 'eq.$_owner') {
          linkReads.add(request);
          body = [
            for (final (index, id) in guardIds.indexed)
              {
                'wali_id': id,
                'is_main': index == 0,
                'relationship': index == 0 ? 'father' : 'brother',
                'active_since': '2026-11-01T00:00:00Z',
              },
          ];
        } else if (path == 'profiles' &&
            query['select']?.replaceAll(' ', '') == 'id,first_name') {
          body = [
            for (final (index, id) in guardIds.indexed)
              {'id': id, 'first_name': index == 0 ? 'Hassan' : 'Yusuf $index'},
          ];
        } else if (path == 'zyra_guardian_journey_access') {
          final args = jsonDecode(request.body) as Map<String, dynamic>;
          final isMain = args['p_guardian'] == 'guardian-0';
          body = [
            {
              'attempt_id': 'attempt-101',
              'match_id': 'match-101',
              'counterpart_first_name': 'Maryam',
              'included': true,
              'can_change': !isMain,
              'guardian_is_main': isMain,
              'chat_available': true,
              'chat_enabled': false,
              'guardian_chat_entitled': true,
            },
          ];
        } else if (path == 'zyra_guardian_history_consent') {
          final args = jsonDecode(request.body) as Map<String, dynamic>;
          body = [
            {
              'enabled': args['p_enabled'] ?? false,
              'active_guardian_link_id': 'link-${args['p_guardian']}',
              'guardian_id': args['p_guardian'],
              'guardian_is_main': args['p_guardian'] == 'guardian-0',
            },
          ];
        }
        return http.Response(
          jsonEncode(body),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await _signInFixture();
    await ZyraLocalPrefs.setCacheSchemaVersion(1);
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    AppState.instance.resetForAccountChange();
    linkReads.clear();
  });

  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });
  tearDownAll(() async {
    ZyraAccountState.clearImagesForTesting = null;
    await Supabase.instance.dispose();
  });

  Future<void> mount(
    WidgetTester tester, {
    required Size size,
    required EdgeInsets insets,
    required ZyraPlan plan,
    required int links,
  }) async {
    linkedCount = links;
    if (!supabaseReady) {
      // Use the app's existing startup retry to admit the synthetic client.
      await tester.pumpWidget(
        MaterialApp(
          home: ZyraStartupGate(
            startupError: const SocketException('fixture'),
            backendConfigured: true,
            initializeClient: () async {},
          ),
        ),
      );
      await tester.tap(_key('zyra_error_primary'));
      await tester.pump();
      expect(supabaseReady, isTrue);
    }
    AppState.instance.hydrateFrom(
      name: 'Adam',
      gender: 'male',
      plan: plan,
      verifiedSeekerPlan: (plan: plan, expiresAt: null),
    );
    await tester.pump();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: insets,
            viewPadding: insets,
            disableAnimations: true,
          ),
          child: RepaintBoundary(key: _captureRoot, child: child!),
        ),
        home: const HomeShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(_key('floating-nav-item-3')));
    await tester.pumpAndSettle();
    expect(linkReads, isNotEmpty);
    expect(tester.takeException(), isNull);
  }

  for (final (size, insets) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    for (final plan in ZyraPlan.values) {
      for (final links in [0, 1]) {
        testWidgets('ordinary ${plan.name} with $links links at $dimensions', (
          tester,
        ) async {
          await mount(
            tester,
            size: size,
            insets: insets,
            plan: plan,
            links: links,
          );
          final nav = tester.getRect(_key('floating-nav-quiet-true'));
          Rect? linked;
          if (links == 1) {
            AppState.instance.setJourneyMatches(
              potential: const [],
              active: [
                JourneyMatch(
                  matchId: 'match-101',
                  status: 'active',
                  profile: SeekerProfile(
                    id: 'counterpart-101',
                    firstName: 'Maryam',
                    age: 31,
                    city: '',
                    photos: [localPhoto],
                    gender: 'female',
                  ),
                ),
              ],
            );
            await tester.pumpAndSettle();
            linked = tester.getRect(_key('guardian-page-static-guardian-0'));
            final portraitFinder = _key(
              'guardian-journey-portrait-attempt-101',
            );
            expect(
              tester
                  .widget<ZyraProfileImage>(
                    find.descendant(
                      of: portraitFinder,
                      matching: find.byType(ZyraProfileImage),
                    ),
                  )
                  .photo,
              localPhoto,
            );
            final portrait = tester.getRect(
              _key('guardian-journey-portrait-attempt-101'),
            );
            final journey = tester.getRect(find.text('Journey with Maryam'));
            final circle = tester.getRect(
              _key('guardian-journey-free-circle-1'),
            );
            final free = tester.getRect(
              find.descendant(
                of: _key('guardian-journey-pending-row-1'),
                matching: find.text('Awaiting a Journey'),
              ),
            );
            expect(journey.left - portrait.right, closeTo(14, .01));
            expect(free.left - circle.right, closeTo(14, .01));
            expect(circle.width, closeTo(40, .01));
            expect(circle.height, closeTo(40, .01));
            expect(_key('guardian-history-consent-toggle'), findsOneWidget);
            expect(tester.getSize(_key('guardian-page-dot-0')).width, 26);
            expect(
              _key('guardian-history-consent-details-toggle'),
              findsNothing,
            );
            if (plan == ZyraPlan.one) {
              final image = find.descendant(
                of: portraitFinder,
                matching: find.byType(Image),
              );
              await tester.runAsync(
                () => precacheImage(
                  tester.widget<Image>(image).image,
                  tester.element(image),
                ),
              );
              await tester.pump();
              await _capture(tester, 'linked_$dimensions');
            }
            await tester.drag(
              _key('guardian-page-view'),
              const Offset(-310, 0),
            );
            await tester.pumpAndSettle();
          }
          final card = _key(
            links == 0 ? 'guardianship-manager-empty' : 'guardian-pager-add',
          );
          final add = _key('guardian-card-add-button');
          expect(tester.getSize(add), const Size.square(104));
          expect(_key('guardian-empty-add'), findsNothing);
          expect(_key('guardian-page-dot-0'), findsNWidgets(links));
          if (links == 1) {
            expect(tester.getSize(_key('guardian-page-dot-0')).width, 11);
          }
          expect(_key('guardian-page-dot-1'), findsNothing);
          final box = tester.getRect(card);
          expect(nav.top - box.bottom, closeTo(16, .01));
          if (linked != null) {
            expect(box.top, closeTo(linked.top, .01));
            expect(box.bottom, closeTo(linked.bottom, .01));
            expect(box.left, closeTo(linked.left, .01));
            expect(box.right, closeTo(linked.right, .01));
          }
          if (plan == ZyraPlan.basic) {
            expect(
              find.text('Guardian Basic place'),
              findsNWidgets(links == 0 ? 1 : 0),
            );
            expect(find.text('Guardian One places'), findsOneWidget);
            expect(find.text('Seeker One: any 10 Guardians ›'), findsOneWidget);
          }
          await _capture(tester, 'add_${plan.name}_${links}_$dimensions');
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(find.byType(LinkGuardianScreen), findsOneWidget);
          expect(find.text('Scan code'), findsOneWidget);
          expect(find.text('Enter code'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }
  }

  testWidgets('ordinary full roster has ten Guardian pages and no Add page', (
    tester,
  ) async {
    await mount(
      tester,
      size: const Size(430, 932),
      insets: const EdgeInsets.only(top: 59, bottom: 34),
      plan: ZyraPlan.basic,
      links: 10,
    );
    final pager = tester.widget<ZyraSwipeTrack>(_key('guardian-page-view'));
    expect(pager.itemCount, 10);
    expect(_key('guardian-page-dot-9'), findsOneWidget);
    expect(_key('guardian-page-dot-10'), findsNothing);
    expect(_key('guardian-add-top'), findsOneWidget);
    expect(_key('guardian-pager-add'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
