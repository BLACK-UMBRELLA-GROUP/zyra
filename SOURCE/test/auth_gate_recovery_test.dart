// Local Auth-stream recovery only. Synthetic sessions and intercepted HTTP;
// this is not deployed provider, connectivity or member-admission acceptance.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/screens/auth_gate.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

const _a = '00000000-0000-4000-8000-000000000961';
const _b = '00000000-0000-4000-8000-000000000962';
const _founder = ZyraInternalFounderPolicy.approvedFounderUserId;

Future<void> _session(String id) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
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
        'created_at': '2026-10-10T00:00:00Z',
      },
    }),
  );
}

void _emit(AuthChangeEvent event, {Session? session}) {
  // Intercepted SDK event, not a real refresh or proof grant. The app's
  // existing resolver still refreshes/validates through its policy below.
  // ignore: invalid_use_of_internal_member
  supabase.auth.notifyAllSubscribers(event, session: session, broadcast: false);
}

void _streamError() {
  // ignore: invalid_use_of_internal_member
  supabase.auth.notifyException(
    http.ClientException('SocketException: private-diagnostic-marker'),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
}

Future<void> _mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: AuthGate(playSplash: false)));
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _settle(tester);
  // Prevent a completed fake-zone preference tail surviving into the next
  // fixture's real-zone setup. The same queue-drain contract as startup tests.
  await tester.runAsync(() async {
    unawaited(ZyraAccountState.synchronize(null));
  });
  var accountDrained = false;
  var preferencesDrained = false;
  ZyraAccountState.synchronize(null).then((_) => accountDrained = true);
  ZyraLocalPrefs.bindAccount(null).then((_) => preferencesDrained = true);
  for (
    var frame = 0;
    frame < 20 && (!accountDrained || !preferencesDrained);
    frame++
  ) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(accountDrained && preferencesDrained, isTrue);
  expect(tester.takeException(), isNull);
  debugDefaultTargetPlatformOverride = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var refreshes = 0;
  var requests = 0;
  var refreshFails = false;
  var profileReplyError = false;
  Future<void> Function(String path)? beforeResponse;
  Completer<void>? refreshGate;

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
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-recovery-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests++;
        final path = request.url.path;
        await beforeResponse?.call(path);
        if (profileReplyError && path == '/rest/v1/profiles') {
          return http.Response(
            jsonEncode({
              'message': 'JWT expired private-route-marker',
              'code': 'PGRST301',
            }),
            401,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        Object? body = [];
        if (path == '/rest/v1/profiles') {
          final id = request.url.queryParameters['id'];
          if (id?.startsWith('eq.') == true) {
            body = [
              {
                'role': 'seeker',
                'first_name': id == 'eq.$_b' ? 'Member B' : 'Member A',
                'surname_line': 'Synthetic family',
                'gender': 'female',
                'location_text': 'Synthetic city',
              },
            ];
          }
        } else if (path.endsWith('/ages_for_one')) {
          body = 29;
        }
        return http.Response(
          jsonEncode(body),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    await ZyraAccountState.synchronize(null);
    await _session(_a);
    await ZyraAccountState.synchronize(_a);
    refreshes = 0;
    requests = 0;
    refreshFails = false;
    profileReplyError = false;
    beforeResponse = null;
    refreshGate = null;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () async {
        refreshes++;
        await refreshGate?.future;
        if (refreshFails) throw StateError('Synthetic proof refresh failure');
        return supabase.auth.currentUser;
      },
      founderIdentityMatches: (_) => false,
    );
  });

  tearDown(() {
    beforeResponse = null;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    debugDefaultTargetPlatformOverride = null;
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets('healthy same-owner events do not restart routing', (
    tester,
  ) async {
    await _mount(tester);
    expect(find.byType(HomeShell), findsOneWidget);
    final initialRefreshes = refreshes;
    _emit(AuthChangeEvent.tokenRefreshed);
    _emit(AuthChangeEvent.tokenRefreshed);
    _emit(AuthChangeEvent.signedIn);
    await _settle(tester);
    expect(refreshes, initialRefreshes);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(ZyraFullScreenError), findsNothing);
    await _dispose(tester);
  });

  for (final event in [
    AuthChangeEvent.tokenRefreshed,
    AuthChangeEvent.signedIn,
  ]) {
    testWidgets('$event recovers a same-owner stream failure once', (
      tester,
    ) async {
      await _mount(tester);
      final initialRefreshes = refreshes;
      _streamError();
      await _settle(tester);
      final recovery = tester.widget<ZyraFullScreenError>(
        find.byType(ZyraFullScreenError),
      );
      expect(recovery.kind, ZyraErrorKind.offline);
      expect(find.text('We couldn’t connect to ZYRA.'), findsOneWidget);
      expect(find.text('Return to welcome'), findsOneWidget);
      expect(find.textContaining('private-diagnostic-marker'), findsNothing);

      _emit(event);
      _emit(event);
      _emit(AuthChangeEvent.tokenRefreshed);
      await _settle(tester);
      expect(refreshes, initialRefreshes + 1);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(ZyraFullScreenError), findsNothing);
      expect(supabase.auth.currentUser?.id, _a);
      expect(AppState.instance.name, 'Member A');
      // A retained error-screen action cannot start another request after
      // recovery has advanced the rendered route/request lifetime.
      recovery.onPrimary();
      recovery.onSecondary();
      await _settle(tester);
      expect(refreshes, initialRefreshes + 1);
      expect(find.byType(WelcomeScreen), findsNothing);
      await _dispose(tester);
    });
  }

  testWidgets('non-success and wrong-session events keep recovery held', (
    tester,
  ) async {
    await _mount(tester);
    final oldSession = supabase.auth.currentSession!;
    // Construct a different-owner event without replacing the current owner.
    final otherJson = oldSession.toJson();
    otherJson['user'] = {...oldSession.user.toJson(), 'id': _b};
    final otherSession = Session.fromJson(otherJson)!;
    final initialRefreshes = refreshes;
    _streamError();
    await _settle(tester);
    _emit(AuthChangeEvent.userUpdated);
    _emit(AuthChangeEvent.initialSession);
    _emit(AuthChangeEvent.tokenRefreshed, session: otherSession);
    await _settle(tester);
    expect(refreshes, initialRefreshes);
    expect(find.byType(ZyraFullScreenError), findsOneWidget);
    expect(supabase.auth.currentUser?.id, _a);
    await _dispose(tester);
  });

  testWidgets('replacement owner routes itself and old callbacks stay inert', (
    tester,
  ) async {
    await _mount(tester);
    _streamError();
    await _settle(tester);
    final oldRecovery = tester.widget<ZyraFullScreenError>(
      find.byType(ZyraFullScreenError),
    );
    await tester.runAsync(() => _session(_b));
    await _settle(tester);
    expect(supabase.auth.currentUser?.id, _b);
    expect(AppState.instance.name, 'Member B');
    final replacementRefreshes = refreshes;
    oldRecovery.onPrimary();
    oldRecovery.onSecondary();
    _emit(AuthChangeEvent.tokenRefreshed);
    await _settle(tester);
    expect(refreshes, replacementRefreshes);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(AppState.instance.name, 'Member B');
    await _dispose(tester);
  });

  testWidgets('disposed recovery ignores later events and retained actions', (
    tester,
  ) async {
    await _mount(tester);
    _streamError();
    await _settle(tester);
    final oldRecovery = tester.widget<ZyraFullScreenError>(
      find.byType(ZyraFullScreenError),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    final initialRefreshes = refreshes;
    oldRecovery.onPrimary();
    oldRecovery.onSecondary();
    _emit(AuthChangeEvent.tokenRefreshed);
    await _settle(tester);
    expect(refreshes, initialRefreshes);
    expect(find.byType(AuthGate), findsNothing);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('recovery still requires fresh proof and cannot admit preview', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _session(_founder);
      await ZyraAccountState.synchronize(_founder);
    });
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    refreshFails = true;
    await _mount(tester);
    expect(find.byType(HomeShell), findsNothing);
    _streamError();
    await _settle(tester);
    final oldRecovery = tester.widget<ZyraFullScreenError>(
      find.byType(ZyraFullScreenError),
    );
    final initialRefreshes = refreshes;
    final initialRequests = requests;
    final pending = Completer<void>();
    refreshGate = pending;
    try {
      _emit(AuthChangeEvent.tokenRefreshed);
      _emit(AuthChangeEvent.tokenRefreshed);
      // Account synchronization crosses the real preference queue before the
      // proof callback starts. Drain that queue without advancing the UI clock
      // so the sampled frames are measured from an actually pending request.
      for (var turn = 0; turn < 20 && refreshes == initialRefreshes; turn++) {
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(refreshes, initialRefreshes + 1);
      for (final elapsed in [
        Duration.zero,
        const Duration(milliseconds: 16),
        const Duration(milliseconds: 84),
        const Duration(milliseconds: 699),
        const Duration(milliseconds: 1),
        const Duration(milliseconds: 2200),
      ]) {
        await tester.pump(elapsed);
        expect(find.byType(ZyraFullScreenError), findsNothing);
        expect(find.text('Preview access needs checking.'), findsNothing);
        expect(find.text('Couldn’t open this page.'), findsNothing);
        expect(find.text('ZYRA'), findsNothing);
        expect(find.byType(HomeShell), findsNothing);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(requests, initialRequests);
        expect(supabase.auth.currentUser?.id, _founder);
      }
      // A callback retained from the old failure cannot retry or sign out the
      // owner while this newer proof request is pending.
      oldRecovery.onPrimary();
      oldRecovery.onSecondary();
      await tester.pump();
      expect(refreshes, initialRefreshes + 1);
      expect(supabase.auth.currentUser?.id, _founder);
      pending.complete();
      refreshGate = null;
      await _settle(tester);
      final recovery = tester.widget<ZyraFullScreenError>(
        find.byType(ZyraFullScreenError),
      );
      expect(recovery.kind, ZyraErrorKind.previewAccess);
      expect(find.text('Couldn’t open this page.'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('zyra_error_compact_notice')),
        findsOneWidget,
      );
      expect(refreshes, initialRefreshes + 1);
      expect(requests, initialRequests);
      expect(find.byType(HomeShell), findsNothing);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    } finally {
      if (!pending.isCompleted) pending.complete();
      refreshGate = null;
      await _dispose(tester);
    }
  });

  testWidgets('route diagnostic log contains opaque code and type only', (
    tester,
  ) async {
    final lines = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) lines.add(message);
    };
    try {
      await _mount(tester);
      _streamError();
      await _settle(tester);
      final routeLogs = lines.where(
        (line) => line.startsWith('ZYRA route failed ['),
      );
      expect(routeLogs.length, 1);
      expect(
        routeLogs.single,
        matches(
          RegExp(
            r'^ZYRA route failed \[ZY-[0-9A-Z]{4}\] \(ClientException\)\.$',
          ),
        ),
      );
      expect(routeLogs.single, isNot(contains('private-diagnostic-marker')));
      await _dispose(tester);
    } finally {
      debugPrint = original;
    }
  });

  testWidgets('resolver failure logs no raw response before recovery', (
    tester,
  ) async {
    final lines = <String>[];
    final original = debugPrint;
    profileReplyError = true;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) lines.add(message);
    };
    try {
      await _mount(tester);
      expect(find.byType(ZyraFullScreenError), findsOneWidget);
      final logs = lines.where(
        (line) =>
            line.startsWith('ZYRA resolveHome failed [') ||
            line.startsWith('ZYRA route failed ['),
      );
      expect(logs, hasLength(2));
      expect(
        logs.every((line) => line.contains('(PostgrestException)')),
        isTrue,
      );
      expect(
        logs.every((line) => !line.contains('private-route-marker')),
        isTrue,
      );
      expect(logs.every((line) => !line.contains('JWT expired')), isTrue);
      await _dispose(tester);
    } finally {
      debugPrint = original;
    }
  });
}
