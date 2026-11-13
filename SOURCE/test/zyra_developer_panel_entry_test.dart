import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_session_router.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';
import 'package:zyra/widgets/zyra_app_lock_gate.dart';

const _owner = ZyraInternalFounderPolicy.approvedFounderUserId;
const _project = ZyraInternalFounderPolicy.approvedSupabaseUrl;
const _member = 'ordinary-seeker-fixture';
const _captureRoot = ValueKey('line96-capture');
const _captures = String.fromEnvironment('ZYRA_LINE96_CAPTURE_DIR');

Finder _key(String key) => find.byKey(ValueKey(key));

Map<String, Object?> _session({
  String user = _owner,
  String issuer = _project,
  String lifetime = 'synthetic-session-one',
  String? claim = 'founder',
  String? jwtClaim,
  int version = 0,
  int expiry = 4102444800,
}) {
  String part(Object data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  final metadata = {'zyra_role': ?claim};
  final claims = {
    'iss': '$issuer/auth/v1',
    'sub': user,
    'exp': expiry,
    'session_id': lifetime,
    'app_metadata': jwtClaim == null ? metadata : {'zyra_role': jwtClaim},
    'jti': 'fixture-$version',
  };
  return {
    'access_token': '${part({'alg': 'HS256'})}.${part(claims)}.${part([1])}',
    'refresh_token': 'synthetic-refresh-$version',
    'token_type': 'bearer',
    'user': {
      'id': user,
      'aud': 'authenticated',
      'email': 'sample-admin@example.org',
      'created_at': '2026-11-12T00:00:00Z',
      'app_metadata': metadata,
      'user_metadata': {'zyra_role': 'founder'},
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var refreshCalls = 0;
  var profileRole = 'seeker';
  var plan = 'seeker_basic';
  var currentIdentity = _owner;
  var readsAndWrites = <({String method, String path})>[];
  var respondToRefresh = (int version) async => _session(version: version);

  Future<void> initialize({String endpoint = _project}) => Supabase.initialize(
    url: endpoint,
    publishableKey: 'synthetic-test-only',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: false,
      detectSessionInUri: false,
      localStorage: EmptyLocalStorage(),
    ),
    httpClient: MockClient((request) async {
      final path = request.url.path;
      readsAndWrites.add((method: request.method, path: path));
      Object? response = const [];
      if (path == '/auth/v1/token') {
        response = await respondToRefresh(++refreshCalls);
      } else if (path == '/rest/v1/profiles' &&
          request.url.queryParameters['select'] ==
              'role,first_name,surname_line,gender,location_text') {
        response = [
          {
            'role': profileRole,
            'first_name': 'Sample Admin',
            'gender': 'male',
            'location_text': 'Leeds',
          },
        ];
      } else if (path == '/rest/v1/subscriptions') {
        response = [
          {'plan_type': plan, 'expires_at': null},
        ];
      } else if (path.endsWith('/ages_for_one')) {
        response = 29;
      }
      return http.Response(
        jsonEncode(response),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  Future<void> installSession(Map<String, Object?> session) async {
    await supabase.auth.setInitialSession(jsonEncode(session));
    await ZyraAccountState.synchronize(currentIdentity);
  }

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/events'),
      (_) async => null,
    );
    final font = FontLoader('PoppinsLine96')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Light.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await initialize();
  });

  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsLine96';
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    currentIdentity = _owner;
    await installSession(_session());
    refreshCalls = 0;
    profileRole = 'seeker';
    plan = 'seeker_basic';
    currentIdentity = _owner;
    readsAndWrites = [];
    respondToRefresh = (version) async =>
        _session(user: currentIdentity, version: version);
  });

  tearDown(() {
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraDeveloperSamples.instance.resetForAccountChange();
    ZyraAppLock.instance.clearForSignOut();
  });

  tearDownAll(() => Supabase.instance.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 8; frame++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  Future<GlobalKey<NavigatorState>> mount(WidgetTester tester) async {
    final home = (await tester.runAsync(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        return await ZyraSessionRouter.resolveHome();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }))!;
    final navigator = GlobalKey<NavigatorState>();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigator,
        builder: (_, child) => ZyraDeveloperPanelSession(
          child: ZyraAppLockGate(
            child: ZyraAccountSessionHost(
              navigatorKey: navigator,
              child: MediaQuery(
                data: MediaQueryData.fromView(tester.view).copyWith(
                  padding: const EdgeInsets.only(top: 59, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                  disableAnimations: true,
                ),
                child: RepaintBoundary(key: _captureRoot, child: child!),
              ),
            ),
          ),
        ),
        home: home,
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    return navigator;
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
    expect(tester.takeException(), isNull);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (_captures.isEmpty) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_captureRoot),
      );
      final image = await boundary.toImage();
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$_captures/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  testWidgets(
    'ordinary Seeker title opens the Basic panel after explicit refresh',
    (tester) async {
      await mount(tester);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(ZyraInternalPreviewClient.isActive, isFalse);
      expect(find.text('My ZYRA'), findsOneWidget);
      expect(_key('dev_page_title'), findsOneWidget);
      final before = refreshCalls;
      await tap(tester, find.text('My ZYRA'));
      expect(refreshCalls, before + 1);
      expect(_key('dev_panel'), findsOneWidget);
      expect(find.textContaining('Seeker Basic'), findsWidgets);
      expect(find.text('Seeker Basic has 1 place'), findsOneWidget);
      readsAndWrites.clear();
      final telemetry =
          ZyraProductTelemetry.instance.snapshot.sessionEventCount;
      await tap(tester, _key('dev_active_2'));
      expect(ZyraDeveloperSamples.instance.active, isNull);
      await tap(tester, _key('dev_active_1'));
      await tap(tester, _key('dev_ended_2'));
      await tap(tester, _key('dev_received_3'));
      await tap(tester, _key('dev_sent_2'));
      await tap(tester, _key('dev_past_2'));
      await tap(tester, _key('dev_introductions_2'));
      expect(ZyraDeveloperSamples.instance.active, 1);
      expect(ZyraDeveloperSamples.instance.ended, 2);
      expect(ZyraDeveloperSamples.instance.received, 3);
      expect(ZyraDeveloperSamples.instance.sent, 2);
      expect(ZyraDeveloperSamples.instance.introductions, 2);
      await capture(tester, 'line96_ordinary_basic_panel');
      await tap(tester, _key('dev_done'));
      await tester.scrollUntilVisible(
        find.text('1 of 1 place in use'),
        200,
        scrollable: find
            .descendant(
              of: _key('my-zyra-quiet-scroll-0'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('1 of 1 place in use'), findsOneWidget);
      expect(find.text('Journey requests'), findsOneWidget);
      final requests = find.text('Journey requests');
      await tester.scrollUntilVisible(
        requests,
        160,
        scrollable: find
            .descendant(
              of: _key('my-zyra-quiet-scroll-0'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tap(tester, requests);
      expect(find.text('Received'), findsOneWidget);
      expect(_key('dev_page_title'), findsOneWidget);
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_clear'));
      expect(ZyraDeveloperSamples.instance.hasSamples, isFalse);
      await tap(tester, _key('dev_done'));
      expect(_key('dev_panel'), findsNothing);
      expect(
        readsAndWrites.where(
          (call) => call.method != 'GET' && call.path != '/auth/v1/token',
        ),
        isEmpty,
      );
      expect(
        ZyraProductTelemetry.instance.snapshot.sessionEventCount,
        telemetry,
      );
      await dispose(tester);
    },
  );

  testWidgets('offstage and covered title callbacks cannot open the panel', (
    tester,
  ) async {
    final navigator = await mount(tester);
    final titleTap = tester
        .widget<GestureDetector>(_key('dev_page_title'))
        .onTap!;
    final before = refreshCalls;
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      ),
    );
    await settle(tester);
    titleTap();
    await settle(tester);
    expect(refreshCalls, before);
    expect(_key('dev_panel'), findsNothing);
    navigator.currentState!.pop();
    await settle(tester);

    final delayed = Completer<void>();
    respondToRefresh = (version) async {
      await delayed.future;
      return _session(version: version);
    };
    await tester.tap(find.text('My ZYRA'));
    await settle(tester);
    await tester.tapAt(tester.getCenter(_key('floating-nav-item-4')));
    await settle(tester);
    expect(find.text('My ZYRA').hitTestable(), findsNothing);
    expect(_key('dev_page_title'), findsNothing);
    await tester.tapAt(tester.getCenter(_key('floating-nav-item-2')));
    await settle(tester);
    expect(find.text('My ZYRA'), findsOneWidget);
    delayed.complete();
    await settle(tester);
    expect(_key('dev_panel'), findsNothing);
    expect(_key('dev_page_title'), findsOneWidget);
    await dispose(tester);
  });

  testWidgets(
    'Guardian role has no title affordance even with the pinned claim',
    (tester) async {
      profileRole = 'wali';
      await mount(tester);
      expect(find.byType(WaliHomeShell), findsOneWidget);
      expect(_key('dev_page_title'), findsNothing);
      expect(ZyraDeveloperSamples.instance.isAuthorized, isFalse);
      await dispose(tester);
    },
  );

  testWidgets('sign-out intent clears the overlay and removes only its sheet', (
    tester,
  ) async {
    final navigator = await mount(tester);
    await tap(tester, find.text('My ZYRA'));
    await tap(tester, _key('dev_received_3'));
    expect(ZyraDeveloperSamples.instance.received, 3);
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Independent route')),
        ),
      ),
    );
    await settle(tester);
    await tester.runAsync(ZyraAccountState.beginSignOut);
    await settle(tester);
    expect(_key('dev_panel'), findsNothing);
    expect(find.text('Independent route'), findsOneWidget);
    navigator.currentState!.pop();
    await settle(tester);
    expect(_key('dev_panel'), findsNothing);
    expect(ZyraDeveloperSamples.instance.hasSamples, isFalse);
    expect(_key('dev_page_title'), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    await dispose(tester);
  });

  final samples = ZyraDeveloperSamples.instance;

  void resume(WidgetTester tester) {
    final binding = tester.binding;
    if (binding.lifecycleState == AppLifecycleState.paused) {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    }
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  void suspend(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  }

  Future<void> lock(WidgetTester tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      (_) async => true,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/local_auth'),
        null,
      ),
    );
    final enabled = await tester.runAsync(
      () => ZyraAppLock.instance.setEnabled(true),
    );
    expect(enabled, isTrue);
    suspend(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(samples.isAuthorized, isFalse);
    await settle(tester);
    expect(find.byType(ZyraAccountSessionHost), findsNothing);
    expect(find.text('Locked'), findsOneWidget);
  }

  testWidgets(
    'App Lock teardown restores choices only after same-session proof',
    (tester) async {
      await mount(tester);
      await tap(tester, find.text('My ZYRA'));
      await tap(tester, _key('dev_received_3'));
      final heldAction = tester
          .widget<TextButton>(_key('dev_received_2'))
          .onPressed!;
      final lease = samples.generation;
      final before = refreshCalls;
      await lock(tester);
      expect(samples.isCurrentLease(lease), isFalse);
      expect(samples.receivedRows, isNull);
      expect(_key('dev_panel'), findsNothing);
      final delayed = Completer<void>();
      respondToRefresh = (version) async {
        await delayed.future;
        return _session(version: version);
      };
      resume(tester);
      await settle(tester);
      expect(samples.isAuthorized, isFalse);
      expect(refreshCalls, before + 1);
      delayed.complete();
      await settle(tester);
      expect(samples.received, 3);
      heldAction();
      expect(samples.received, 3);
      expect(samples.isCurrentLease(lease), isFalse);
      await dispose(tester);
    },
  );

  testWidgets('unlock waits for a retired refresh then reproofs once', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, find.text('My ZYRA'));
    await tap(tester, _key('dev_received_3'));
    await tap(tester, _key('dev_done'));
    final before = refreshCalls;
    final retired = Completer<void>();
    final fresh = Completer<void>();
    respondToRefresh = (version) async {
      await (version == before + 1 ? retired : fresh).future;
      return _session(version: version);
    };
    await tap(tester, find.text('My ZYRA'));
    expect(refreshCalls, before + 1);
    await lock(tester);
    resume(tester);
    await settle(tester);
    expect(refreshCalls, before + 1);
    retired.complete();
    await settle(tester);
    expect(refreshCalls, before + 2);
    expect(_key('dev_page_title'), findsNothing);
    expect(samples.receivedRows, isNull);
    fresh.complete();
    await settle(tester);
    expect(samples.received, 3);
    expect(refreshCalls, before + 2);
    expect(_key('dev_panel'), findsNothing);
    await dispose(tester);
  });

  testWidgets(
    'temporary refresh error suspends choices until explicit reproof',
    (tester) async {
      await mount(tester);
      await tap(tester, find.text('My ZYRA'));
      await tap(tester, _key('dev_received_3'));
      final lease = samples.generation;
      final before = refreshCalls;
      suspend(tester);
      expect(samples.isCurrentLease(lease), isFalse);
      // A response the SDK cannot decode produces a non-terminal auth error
      // without exercising its separate network retry/backoff policy.
      respondToRefresh = (_) async => {'access_token': 'malformed-fixture'};
      resume(tester);
      await settle(tester);
      expect(refreshCalls, before + 1);
      expect(_key('dev_panel'), findsNothing);
      expect(_key('dev_page_title'), findsNothing);
      expect(samples.receivedRows, isNull);

      respondToRefresh = (version) async => _session(version: version);
      await tester.runAsync(() => supabase.auth.refreshSession());
      await settle(tester);
      expect(refreshCalls, before + 2);
      expect(_key('dev_page_title'), findsNothing);
      expect(samples.receivedRows, isNull);
      suspend(tester);
      resume(tester);
      await settle(tester);
      expect(refreshCalls, before + 3);
      expect(samples.received, 3);
      expect(samples.isCurrentLease(lease), isFalse);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      await dispose(tester);
    },
  );

  testWidgets('claim denial empties choices even after same-session reproof', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, find.text('My ZYRA'));
    await tap(tester, _key('dev_received_3'));
    await tap(tester, _key('dev_done'));
    respondToRefresh = (version) async =>
        _session(claim: null, version: version);
    await tap(tester, find.text('My ZYRA'));
    expect(_key('dev_panel'), findsNothing);
    expect(_key('dev_page_title'), findsNothing);
    expect(samples.hasSamples, isFalse);
    respondToRefresh = (version) async => _session(version: version);
    suspend(tester);
    resume(tester);
    await settle(tester);
    expect(_key('dev_page_title'), findsOneWidget);
    expect(samples.receivedRows, isNull);
    expect(samples.hasSamples, isFalse);
    await dispose(tester);
  });

  for (final signOut in [true, false]) {
    testWidgets(
      signOut
          ? 'sign-out from App Lock wipes choices even after same-session proof'
          : 'same-account SDK session replacement while locked wipes choices',
      (tester) async {
        await mount(tester);
        await tap(tester, find.text('My ZYRA'));
        await tap(tester, _key('dev_received_3'));
        await lock(tester);
        if (signOut) {
          final nextGeneration = ZyraAccountState.generation + 1;
          // Account reset is immediate even though remote cleanup is async.
          await tester.runAsync(() async {
            debugDefaultTargetPlatformOverride = TargetPlatform.linux;
            try {
              final signingOut = ZyraAuth.signOut();
              expect(ZyraAccountState.generation, nextGeneration);
              await signingOut;
            } finally {
              debugDefaultTargetPlatformOverride = null;
            }
          });
          await tester.runAsync(() => installSession(_session(version: 90)));
        } else {
          await tester.runAsync(() async {
            await supabase.auth.setInitialSession(
              jsonEncode(
                _session(lifetime: 'replacement-session', version: 90),
              ),
            );
            await Future<void>.delayed(Duration.zero);
            await supabase.auth.setInitialSession(
              jsonEncode(_session(version: 91)),
            );
          });
        }
        resume(tester);
        await settle(tester);
        expect(_key('dev_page_title'), findsOneWidget);
        expect(samples.receivedRows, isNull);
        expect(samples.hasSamples, isFalse);
        await dispose(tester);
      },
    );
  }

  for (final pinned in [true, false]) {
    testWidgets(
      pinned
          ? 'pinned Seeker without claim has no Developer UI'
          : 'other Seeker with claim has no Developer UI',
      (tester) async {
        currentIdentity = pinned ? _owner : _member;
        respondToRefresh = (version) async => _session(
          user: currentIdentity,
          claim: pinned ? null : 'founder',
          version: version,
        );
        await tester.runAsync(
          () => installSession(
            _session(user: currentIdentity, claim: pinned ? null : 'founder'),
          ),
        );
        await mount(tester);
        expect(find.byType(HomeShell), findsOneWidget);
        final title = find.text('My ZYRA');
        final semantics = tester.ensureSemantics();
        expect(tester.getSemantics(title).getSemanticsData().actions, 0);
        semantics.dispose();
        await tap(tester, title);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith('dev_'),
          ),
          findsNothing,
        );
        await dispose(tester);
      },
    );
  }

  test('a token event alone never publishes panel authority', () async {
    final access = ZyraDeveloperPanelAccess();
    addTearDown(access.dispose);
    access.observe(
      AuthState(AuthChangeEvent.tokenRefreshed, supabase.auth.currentSession),
    );
    expect(access.email, isNull);
    expect(refreshCalls, 0);
  });

  for (final (name, response) in <(String, Map<String, Object?> Function(int))>[
    ('replayed session', (_) => _session()),
    ('wrong principal', (version) => _session(user: _member, version: version)),
    (
      'wrong issuer',
      (version) => _session(issuer: 'https://wrong.invalid', version: version),
    ),
    (
      'wrong session',
      (version) => _session(lifetime: 'different-session', version: version),
    ),
    ('stale session', (version) => _session(expiry: 1, version: version)),
    ('missing claim', (version) => _session(claim: null, version: version)),
    ('wrong claim', (version) => _session(claim: 'admin', version: version)),
    (
      'wrong JWT claim',
      (version) => _session(jwtClaim: 'admin', version: version),
    ),
  ]) {
    test('explicit refresh denies $name', () async {
      respondToRefresh = (version) async => response(version);
      final access = ZyraDeveloperPanelAccess();
      addTearDown(access.dispose);
      expect(await access.verify(), isFalse);
      expect(access.email, isNull);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(ZyraInternalPreviewClient.isActive, isFalse);
    });
  }

  test('wrong actual project is rejected with no refresh', () async {
    await Supabase.instance.dispose();
    await initialize(endpoint: 'https://wrong.invalid');
    try {
      await installSession(_session());
      final access = ZyraDeveloperPanelAccess();
      addTearDown(access.dispose);
      expect(await access.verify(), isFalse);
      expect(refreshCalls, 0);
    } finally {
      await Supabase.instance.dispose();
      await initialize();
    }
  });

  test(
    'account change before refresh starts retires the captured session',
    () async {
      final access = ZyraDeveloperPanelAccess();
      addTearDown(access.dispose);
      final verification = access.verify();
      await ZyraAccountState.synchronize(_member);
      expect(await verification, isFalse);
      expect(refreshCalls, 0);
      expect(access.email, isNull);
    },
  );
}
