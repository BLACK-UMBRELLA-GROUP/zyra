// Ordinary rendered Code callers with synthetic SDK sessions and strict fake
// HTTP. Only reads are injected; Accept/Decline/Cancel use original services.
// This proves local caller lifetime, not provider, capacity, or server authority.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/screens/browse/find_by_zyra_code_screen.dart';
import 'package:zyra/services/zyra_discovery_service.dart';
import 'package:zyra/main.dart' show supabase, supabaseReady;
import 'package:zyra/screens/wali/accept_wali_invite_screen.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-0000-0000-000000009821';
const _b = '00000000-0000-0000-0000-000000009822';
const _requestId = '00000000-0000-0000-0000-000000009823';
const _host = 'guardian-code-caller-evidence.invalid';
const _codeA = 'ZYRA-1A01-1B02-1C03-1D04-1E05';
const _codeNew = 'ZYRA-2A01-2B02-2C03-2D04-2E05';
const _acceptPath = '/rest/v1/rpc/zyra_accept_guardian_request';
const _declinePath = '/rest/v1/rpc/zyra_decline_guardian_request';
const _cancelPath = '/rest/v1/rpc/zyra_cancel_guardian_request';
const _rotatePath = '/rest/v1/rpc/zyra_rotate_my_personal_code';
const _previewPath = '/rest/v1/rpc/zyra_preview_personal_code';
const _legacyPath = '/rest/v1/rpc/preview_wali_invite';
const _matchPath = '/rest/v1/rpc/zyra_preview_match_code';
const _sendPath = '/rest/v1/rpc/zyra_request_guardian_link';
const _considerPath = '/rest/v1/rpc/zyra_consider_match_code';
const _changedError =
    'Your account changed. Please check your Guardian requests before continuing.';

Future<void> _session(String id) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-not-a-provider-token',
      'user': {
        'id': id,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'email': 'code-caller@example.invalid',
        'created_at': '2026-10-08T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(id);
}

ZyraGuardianLinkRequest _row({
  String direction = 'incoming',
  String name = 'Synthetic Seeker',
}) => ZyraGuardianLinkRequest(
  id: _requestId,
  direction: direction,
  otherFirstName: name,
  otherRole: 'seeker',
  status: 'pending',
  createdAt: DateTime.utc(2026, 10, 8),
  expiresAt: DateTime.utc(2100),
);

class _Reads {
  String code = _codeA;
  List<ZyraGuardianLinkRequest> rows = [_row()];
  int codeCalls = 0;
  int requestCalls = 0;
  final heldCodes = <int, Completer<ZyraSourceResult<ZyraPersonalCode>>>{};
  final heldRequests =
      <int, Completer<ZyraSourceResult<List<ZyraGuardianLinkRequest>>>>{};

  Future<ZyraSourceResult<ZyraPersonalCode>> personalCode({
    String? roleContext,
  }) {
    expectSync(roleContext, 'wali');
    final held = heldCodes[++codeCalls];
    return held?.future ??
        Future.value(
          ZyraSourceResult.available(
            ZyraPersonalCode(code: code, roleContext: 'wali'),
          ),
        );
  }

  Future<ZyraSourceResult<List<ZyraGuardianLinkRequest>>> requests() {
    final held = heldRequests[++requestCalls];
    return held?.future ?? Future.value(ZyraSourceResult.available(rows));
  }
}

class _Rpc {
  final http.Request request;
  final Completer<http.Response> reply = Completer<http.Response>();
  _Rpc(this.request);

  void complete(Object? value, {int status = 200}) => reply.complete(
    http.Response.bytes(
      status == 204 ? const [] : utf8.encode(jsonEncode(value)),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <_Rpc>[];
  final denied = <String>[];
  late _Reads reads;
  int linked = 0;
  const linksMethods = MethodChannel('com.llfbandit.app_links/messages');
  const linksEvents = MethodChannel('com.llfbandit.app_links/events');

  setUp(() async {
    calls.clear();
    denied.clear();
    linked = 0;
    reads = _Reads();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(linksMethods, (_) async => null)
      ..setMockMethodCallHandler(linksEvents, (_) async => null);
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = true;
    await Supabase.initialize(
      url: 'https://$_host',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) {
        final allowed =
            request.url.scheme == 'https' &&
            request.url.host == _host &&
            request.url.port == 443 &&
            request.url.userInfo.isEmpty &&
            request.url.query.isEmpty &&
            request.url.fragment.isEmpty &&
            request.method == 'POST' &&
            {
              _acceptPath,
              _declinePath,
              _cancelPath,
              _rotatePath,
              _previewPath,
              _legacyPath,
              _matchPath,
              _sendPath,
              _considerPath,
            }.contains(request.url.path);
        if (!allowed) {
          denied.add('${request.method} ${request.url}');
          throw StateError('Strict Code evidence transport refused request');
        }
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final expected = switch (request.url.path) {
          _rotatePath => {'p_role_context': 'wali'},
          _previewPath || _matchPath || _considerPath => {'p_code': _codeA},
          _legacyPath => {'p_token': 'AB12CD34'},
          _sendPath => {'p_code': _codeA, 'p_relationship': 'father'},
          _acceptPath => {
            'p_request_id': _requestId,
            'p_relationship': 'father',
          },
          _ => {'p_request_id': _requestId},
        };
        if (payload.length != expected.length ||
            !expected.entries.every((e) => payload[e.key] == e.value)) {
          denied.add('Unexpected RPC payload on ${request.url.path}');
          throw StateError('Strict Code evidence transport refused payload');
        }
        final call = _Rpc(request);
        calls.add(call);
        return call.reply.future;
      }),
    );
    await _session(_a);
    expect(supabaseReady, isFalse);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    expect(ZyraDeveloperAccess.isMainAppPreview, isFalse);
    expect(ZyraInternalPreviewClient.isActive, isFalse);
    expect(ZyraProductTelemetry.productionCollectionEnabled, isFalse);
    expect(calls, isEmpty);
  });

  tearDown(() async {
    ZyraWaliLinkService.setCodeReadyForTesting(null);
    ZyraDiscoveryService.setCodeReadyForTesting(null);
    // No normal test leaves an ACK pending; this is failure-cleanup only.
    for (final call in calls) {
      if (!call.reply.isCompleted) call.complete(false);
    }
    await ZyraAccountState.synchronize(null);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = false;
    await Supabase.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(linksMethods, null)
      ..setMockMethodCallHandler(linksEvents, null);
    expect(denied, isEmpty);
  });

  void size(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget subject({bool productionReads = false}) => MaterialApp(
    home: ZyraCodeScreen(
      asGuardian: true,
      onLinked: () => linked++,
      loadPersonalCode: productionReads ? null : reads.personalCode,
      loadGuardianRequests: productionReads ? null : reads.requests,
    ),
  );

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> render(WidgetTester tester) async {
    size(tester);
    await tester.pumpWidget(subject());
    await flush(tester);
    expect(find.text('Synthetic Seeker'), findsOneWidget);
    expect(find.text(_codeA.replaceAll("-", " · ")), findsOneWidget);
  }

  Finder button(String action) => action == 'accept'
      ? find.widgetWithText(FilledButton, 'Accept')
      : find.widgetWithText(
          TextButton,
          action == 'decline' ? 'Decline' : 'Cancel request',
        );

  Future<void> visible(WidgetTester tester, Finder target) async {
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.pump();
    expect(target.hitTestable(), findsOneWidget);
  }

  Future<void> action(WidgetTester tester, String kind) async {
    final target = button(kind);
    await visible(tester, target);
    await tester.tap(target.hitTestable());
    if (kind == 'accept') {
      await tester.pumpAndSettle();
      expect(find.text('How are you related?'), findsOneWidget);
      final father = find.widgetWithText(ListTile, 'Father');
      expect(father.hitTestable(), findsOneWidget);
      await tester.tap(father.hitTestable());
    }
    await flush(tester);
    expect(calls, hasLength(1));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Future<void> press(WidgetTester t, String label) async {
    final target = find.text(label);
    await t.ensureVisible(target);
    await t.pump();
    await t.tap(target.hitTestable());
    await flush(t);
  }

  Future<void> check(WidgetTester t) async {
    final field = find.byKey(const ValueKey('local-code-field'));
    await t.enterText(field, _codeA);
    FocusManager.instance.primaryFocus?.unfocus();
    await flush(t);
    await press(t, 'Check code');
  }

  testWidgets('ordinary share and copy use the same raw value as the QR', (
    t,
  ) async {
    final deviceCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const share = MethodChannel('dev.fluttercommunity.plus/share');
    messenger.setMockMethodCallHandler(share, (call) async {
      deviceCalls.add(call);
      return '';
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') deviceCalls.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(share, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await render(t);
    expect(find.byKey(const ValueKey(('zyra-qr', _codeA))), findsOneWidget);
    await press(t, 'Share my code');
    await press(t, 'Copy code');
    expect(deviceCalls.map((call) => (call.arguments as Map)['text']), [
      _codeA,
      _codeA,
    ]);
    expect(calls, isEmpty);
  });

  testWidgets(
    'rotation requires confirmation and publishes through a stale refresh and pause',
    (t) async {
      ZyraWaliLinkService.setCodeReadyForTesting(true);
      await render(t);
      await press(t, 'Get a new code');
      expect(find.text('Get a new code?'), findsOneWidget);
      expect(calls, isEmpty);
      await press(t, 'Keep my code');
      expect(calls, isEmpty);
      await press(t, 'Get a new code');
      await press(t, 'Get new code');
      expect(calls.single.request.url.path, _rotatePath);
      ZyraWaliLinkService.invitationRevision.value++;
      await flush(t);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      calls.single.complete([
        {'code': _codeNew, 'role_context': 'wali'},
      ]);
      await flush(t);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(t);
      expect(find.byKey(const ValueKey(('zyra-qr', _codeA))), findsNothing);
      expect(find.byKey(const ValueKey(('zyra-qr', _codeNew))), findsOneWidget);
      expect(
        find.text('New code ready. Your old code no longer works.'),
        findsOneWidget,
      );
      expect(find.text('Synthetic Seeker'), findsOneWidget);
    },
  );

  for (final scan in [false, true]) {
    testWidgets(
      '${scan ? 'Scan' : 'Add'} only maps the exact check limit signal',
      (t) async {
        ZyraWaliLinkService.setCodeReadyForTesting(true);
        ZyraDiscoveryService.setCodeReadyForTesting(true);
        if (scan) {
          size(t);
          await t.pumpWidget(const MaterialApp(home: FindByZyraCodeScreen()));
          await flush(t);
        } else {
          await render(t);
          await press(t, 'Their code');
        }
        for (final message in [
          'too_many_code_checks',
          'not_too_many_code_checks',
        ]) {
          await check(t);
          expect(calls.last.request.url.path, scan ? _matchPath : _previewPath);
          calls.last.complete({
            'code': 'P0001',
            'message': message,
          }, status: 400);
          await flush(t);
          expect(
            find.text('Too many tries. Try again later.'),
            message == 'too_many_code_checks' ? findsOneWidget : findsNothing,
          );
        }
        expect(
          find.text("The code couldn't be checked. Please try again."),
          findsOneWidget,
        );
        await check(t);
        calls.last.complete([]);
        await flush(t);
        expect(
          find.text(
            scan
                ? 'That code is not available.'
                : 'Invalid code. Please try again.',
          ),
          findsOneWidget,
        );
        expect(find.text('Too many tries. Try again later.'), findsNothing);
        expect(
          find.text('Check an older invite code'),
          scan ? findsNothing : findsOneWidget,
        );
      },
    );
  }

  Iterable<ZyraTelemetryEventName> checkEvents() => ZyraProductTelemetry
      .instance
      .snapshot
      .recentEvents
      .where((event) => event.action == ZyraTelemetryAction.zyraCodeCheck)
      .map((event) => event.name);

  testWidgets(
    'Add offers an exact manual older invite and checks only on tap',
    (t) async {
      ZyraWaliLinkService.setCodeReadyForTesting(true);
      await render(t);
      await press(t, 'Their code');
      final field = find.byKey(const ValueKey('local-code-field'));
      const legacyLabel = 'Check an older invite code';
      for (final invalid in ['AB12CG34', 'AB12-CD34']) {
        await t.enterText(field, invalid);
        await flush(t);
        await press(t, 'Check code');
        expect(find.text(legacyLabel), findsNothing);
        expect(calls, isEmpty);
      }
      await t.enterText(field, ' ab12cd34 ');
      await flush(t);
      expect(find.text(legacyLabel), findsNothing);
      await press(t, 'Check code');
      expect(calls, isEmpty);
      expect(checkEvents(), isEmpty);
      await press(t, legacyLabel);
      expect(
        t
            .widget<AcceptWaliInviteScreen>(find.byType(AcceptWaliInviteScreen))
            .initialCode,
        'AB12CD34',
      );
      expect(calls, isEmpty);
      await press(t, 'Check Code');
      expect(calls.single.request.url.path, _legacyPath);
      calls.single.complete([]);
      await flush(t);
      expect(
        find.text("That code wasn't found. Check it and try again."),
        findsOneWidget,
      );
    },
  );

  testWidgets('Add offers generic older entry only for a manual empty reply', (
    t,
  ) async {
    ZyraWaliLinkService.setCodeReadyForTesting(true);
    await render(t);
    await press(t, 'Their code');
    const legacyLabel = 'Check an older invite code';
    await check(t);
    calls.last.complete([]);
    await flush(t);
    expect(find.text(legacyLabel), findsOneWidget);
    for (final message in ['too_many_code_checks', 'unavailable']) {
      await press(t, 'Check code'); // A new check of the same entry.
      expect(find.text(legacyLabel), findsNothing);
      calls.last.complete({'code': 'P0001', 'message': message}, status: 400);
      await flush(t);
      expect(find.text(legacyLabel), findsNothing);
    }
    await press(t, 'Check code');
    calls.last.complete([
      {'owner_first_name': 'Wrong Role', 'owner_role': 'wali'},
    ]);
    await flush(t);
    expect(find.text(legacyLabel), findsNothing);
    await press(t, 'Check code');
    calls.last.complete([]);
    await flush(t);
    await press(t, legacyLabel);
    expect(
      t
          .widget<AcceptWaliInviteScreen>(find.byType(AcceptWaliInviteScreen))
          .initialCode,
      isNull,
    );
    expect(
      calls.every((call) => call.request.url.path == _previewPath),
      isTrue,
    );
  });

  testWidgets('Add tab change retires lookup without clearing its retry', (
    t,
  ) async {
    ZyraWaliLinkService.setCodeReadyForTesting(true);
    await render(t);
    await press(t, 'Their code');
    await check(t);
    final scroll = Scrollable.of(t.element(find.text('Checking…'))).position;
    scroll.jumpTo(scroll.minScrollExtent);
    await t.pump();
    await press(t, 'My code');
    await press(t, 'Their code');
    await press(t, 'Check code');
    expect(calls.map((call) => call.request.url.path), [
      _previewPath,
      _previewPath,
    ]);
    calls.first.complete([
      {'owner_first_name': 'Stale', 'owner_role': 'seeker'},
    ]);
    await flush(t);
    expect(find.text('Stale'), findsNothing);
    expect(find.text('Checking…'), findsOneWidget);
    expect(checkEvents(), [
      ZyraTelemetryEventName.started,
      ZyraTelemetryEventName.started,
    ]);
    calls.last.complete([
      {'owner_first_name': 'Current', 'owner_role': 'seeker'},
    ]);
    await flush(t);
    expect(find.text('Current'), findsOneWidget);
    expect(checkEvents(), [
      ZyraTelemetryEventName.started,
      ZyraTelemetryEventName.started,
      ZyraTelemetryEventName.completed,
    ]);
  });

  testWidgets('Add rechecks its lookup before dispatch after start telemetry', (
    t,
  ) async {
    ZyraWaliLinkService.setCodeReadyForTesting(true);
    await render(t);
    await press(t, 'Their code');
    final telemetry = ZyraProductTelemetry.instance;
    void revoke() {
      telemetry.removeListener(revoke);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    }

    telemetry.addListener(revoke);
    addTearDown(() => telemetry.removeListener(revoke));
    try {
      await check(t);
    } finally {
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
    expect(calls, isEmpty);
    expect(checkEvents(), [ZyraTelemetryEventName.started]);
  });

  testWidgets('Scan does not offer the manual older invite flow', (t) async {
    ZyraDiscoveryService.setCodeReadyForTesting(true);
    size(t);
    await t.pumpWidget(const MaterialApp(home: FindByZyraCodeScreen()));
    await flush(t);
    await t.enterText(
      find.byKey(const ValueKey('local-code-field')),
      'AB12CD34',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await flush(t);
    await press(t, 'Check code');
    expect(find.text('Enter all 20 characters.'), findsOneWidget);
    expect(find.text('Check an older invite code'), findsNothing);
    expect(calls, isEmpty);
    expect(checkEvents(), isEmpty);
  });

  for (final interruption in ['edit', 'cover', 'inactive', 'timeout']) {
    testWidgets('Scan ignores old lookup after $interruption and retry', (
      t,
    ) async {
      ZyraDiscoveryService.setCodeReadyForTesting(true);
      final navigator = GlobalKey<NavigatorState>();
      size(t);
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const FindByZyraCodeScreen(),
        ),
      );
      await flush(t);
      await check(t);
      final old = calls.single;
      expect(old.request.url.path, _matchPath);

      switch (interruption) {
        case 'edit':
          final field = find.byKey(const ValueKey('local-code-field'));
          await t.enterText(field, 'A');
          await check(t);
        case 'cover':
          unawaited(
            navigator.currentState!.push<void>(
              MaterialPageRoute(builder: (_) => const Scaffold()),
            ),
          );
          await flush(t);
          navigator.currentState!.pop();
          await flush(t);
          await press(t, 'Check code');
        case 'inactive':
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await flush(t);
          await press(t, 'Check code');
        case 'timeout':
          await t.pump(const Duration(seconds: 10));
          await flush(t);
          expect(
            find.text("The code couldn't be checked. Please try again."),
            findsOneWidget,
          );
          await press(t, 'Check code');
      }
      expect(calls, hasLength(2));
      expect(calls.last.request.url.path, _matchPath);

      old.complete([
        {
          'owner_first_name': 'Old result',
          'owner_age': 30,
          'owner_location': 'Sample City',
        },
      ]);
      await flush(t);
      expect(find.text('Checking…'), findsOneWidget);
      expect(find.text('Old result'), findsNothing);
      expect(checkEvents(), [
        ZyraTelemetryEventName.started,
        ZyraTelemetryEventName.started,
      ]);

      calls.last.complete([
        {
          'owner_first_name': 'Current result',
          'owner_age': 30,
          'owner_location': 'Sample City',
        },
      ]);
      await flush(t);
      expect(find.text('Current result'), findsOneWidget);
      expect(checkEvents(), [
        ZyraTelemetryEventName.started,
        ZyraTelemetryEventName.started,
        ZyraTelemetryEventName.completed,
      ]);
    });
  }

  testWidgets('Scan drops an ACK from an earlier account generation', (
    t,
  ) async {
    ZyraDiscoveryService.setCodeReadyForTesting(true);
    size(t);
    await t.pumpWidget(const MaterialApp(home: FindByZyraCodeScreen()));
    await flush(t);
    await check(t);
    expect(calls.single.request.url.path, _matchPath);
    await t.runAsync(() async {
      await _session(_b).timeout(const Duration(seconds: 3));
      await _session(_a).timeout(const Duration(seconds: 3));
    });
    calls.single.complete([
      {
        'owner_first_name': 'Old account result',
        'owner_age': 30,
        'owner_location': 'Sample City',
      },
    ]);
    await flush(t);
    expect(find.text('Old account result'), findsNothing);
    expect(checkEvents(), [ZyraTelemetryEventName.started]);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'ordinary Add a Seeker requires relationship and sends one request',
    (t) async {
      ZyraWaliLinkService.setCodeReadyForTesting(true);
      await render(t);
      await press(t, 'Their code');
      await check(t);
      calls.single.complete([
        {'owner_first_name': 'Sam', 'owner_role': 'seeker'},
      ]);
      await flush(t);
      expect(find.text('Seeker · first name and role only'), findsOneWidget);
      await press(t, 'Send request');
      expect(calls, hasLength(1));
      expect(find.text('Choose how you are related first.'), findsOneWidget);
      await press(t, 'Father');
      await press(t, 'Send request');
      expect(calls.last.request.url.path, _sendPath);
      calls.last.complete(_requestId);
      await flush(t);
      expect(find.text('Request sent'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(linked, 0);
    },
  );

  testWidgets('production read defaults retain not-ready refusal', (
    tester,
  ) async {
    size(tester);
    await tester.pumpWidget(subject(productionReads: true));
    await flush(tester);
    expect(find.text("Your ZYRA Code couldn't be refreshed."), findsOneWidget);
    expect(reads.requestCalls, 0);
    expect(reads.codeCalls, 0);
    expect(calls, isEmpty);
    await unmount(tester);
  });

  for (final kind in ['decline', 'cancel', 'accept']) {
    testWidgets('current-owner $kind ACK reloads real rendered caller', (
      tester,
    ) async {
      if (kind == 'cancel') reads.rows = [_row(direction: 'outgoing')];
      await render(tester);
      await action(tester, kind);
      expect(
        calls.single.request.url.path,
        kind == 'decline'
            ? _declinePath
            : kind == 'cancel'
            ? _cancelPath
            : _acceptPath,
      );
      reads.rows = [];
      calls.single.complete(
        kind == 'accept' ? null : true,
        status: kind == 'accept' ? 204 : 200,
      );
      await flush(tester);
      expect(find.text('Synthetic Seeker'), findsNothing);
      expect(reads.requestCalls, greaterThan(1));
      expect(linked, kind == 'accept' ? 1 : 0);
      await unmount(tester);
    });

    for (final replacement in ['A-B', 'A-B-A']) {
      testWidgets('late $kind ACK cannot publish after $replacement', (
        tester,
      ) async {
        if (kind == 'cancel') reads.rows = [_row(direction: 'outgoing')];
        await render(tester);
        await action(tester, kind);
        final previousReads = reads.requestCalls;
        await tester.runAsync(
          () => _session(_b).timeout(const Duration(seconds: 3)),
        );
        if (replacement == 'A-B-A') {
          await tester.runAsync(
            () => _session(_a).timeout(const Duration(seconds: 3)),
          );
        }
        calls.single.complete(kind == 'accept' ? null : true);
        await flush(tester);
        expect(reads.requestCalls, previousReads);
        expect(linked, 0);
        expect(find.text(_changedError), findsNothing);
        expect(find.text("That request couldn't be declined."), findsNothing);
        expect(find.text("That request couldn't be cancelled."), findsNothing);
        await unmount(tester);
      });
    }

    testWidgets('disposed $kind caller cannot reload or link after ACK', (
      tester,
    ) async {
      if (kind == 'cancel') reads.rows = [_row(direction: 'outgoing')];
      await render(tester);
      await action(tester, kind);
      final previousReads = reads.requestCalls;
      await unmount(tester);
      calls.single.complete(kind == 'accept' ? null : true);
      await flush(tester);
      expect(reads.requestCalls, previousReads);
      expect(linked, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final replacement in ['A-B', 'A-B-A']) {
    testWidgets('delayed Code reads cannot render after $replacement', (
      tester,
    ) async {
      size(tester);
      final code = Completer<ZyraSourceResult<ZyraPersonalCode>>();
      final rows = Completer<ZyraSourceResult<List<ZyraGuardianLinkRequest>>>();
      reads.heldCodes[1] = code;
      reads.heldRequests[1] = rows;
      await tester.pumpWidget(subject());
      await tester.pump();
      expect(reads.requestCalls, 1);
      await tester.runAsync(
        () => _session(_b).timeout(const Duration(seconds: 3)),
      );
      if (replacement == 'A-B-A') {
        await tester.runAsync(
          () => _session(_a).timeout(const Duration(seconds: 3)),
        );
      }
      code.complete(
        const ZyraSourceResult.available(
          ZyraPersonalCode(code: _codeA, roleContext: 'wali'),
        ),
      );
      rows.complete(ZyraSourceResult.available([_row()]));
      await flush(tester);
      expect(find.text(_codeA.replaceAll("-", " · ")), findsNothing);
      expect(find.text('Synthetic Seeker'), findsNothing);
      expect(calls, isEmpty);
      await unmount(tester);
    });

    testWidgets(
      'relationship choice cannot dispatch old request after $replacement',
      (tester) async {
        await render(tester);
        await visible(tester, button('accept'));
        await tester.tap(button('accept').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('How are you related?'), findsOneWidget);
        await tester.runAsync(
          () => _session(_b).timeout(const Duration(seconds: 3)),
        );
        if (replacement == 'A-B-A') {
          await tester.runAsync(
            () => _session(_a).timeout(const Duration(seconds: 3)),
          );
        }
        await tester.tap(find.widgetWithText(ListTile, 'Father').hitTestable());
        await flush(tester);
        // Complete an erroneous baseline dispatch before the assertion/cleanup.
        for (final call in calls) {
          call.complete(null);
        }
        await flush(tester);
        expect(calls, isEmpty);
        expect(linked, 0);
        await unmount(tester);
      },
    );
  }

  for (final kind in ['decline', 'cancel']) {
    testWidgets('rapid public $kind taps dispatch at most one RPC', (
      tester,
    ) async {
      if (kind == 'cancel') reads.rows = [_row(direction: 'outgoing')];
      await render(tester);
      final target = button(kind);
      await visible(tester, target);
      await tester.tap(target.hitTestable());
      await tester.tap(target.hitTestable());
      await flush(tester);
      reads.rows = [];
      for (final call in calls) {
        call.complete(true);
      }
      await flush(tester);
      expect(calls, hasLength(1));
      expect(linked, 0);
      await unmount(tester);
    });
  }

  testWidgets(
    'older service-triggered refresh cannot overwrite latest rows/code',
    (tester) async {
      await render(tester);
      final olderCode = Completer<ZyraSourceResult<ZyraPersonalCode>>();
      final olderRows =
          Completer<ZyraSourceResult<List<ZyraGuardianLinkRequest>>>();
      reads.heldCodes[2] = olderCode;
      reads.heldRequests[2] = olderRows;
      await action(tester, 'decline');
      reads.code = _codeNew;
      reads.rows = [_row(name: 'Latest Synthetic Seeker')];
      calls.single.complete(true);
      await flush(tester);
      expect(reads.requestCalls, 3);
      expect(find.text('Latest Synthetic Seeker'), findsOneWidget);
      olderCode.complete(
        const ZyraSourceResult.available(
          ZyraPersonalCode(code: _codeA, roleContext: 'wali'),
        ),
      );
      olderRows.complete(
        ZyraSourceResult.available([_row(name: 'Older Synthetic Seeker')]),
      );
      await flush(tester);
      expect(find.text('Latest Synthetic Seeker'), findsOneWidget);
      expect(find.text(_codeNew.replaceAll("-", " · ")), findsOneWidget);
      expect(find.text('Older Synthetic Seeker'), findsNothing);
      await unmount(tester);
    },
  );

  for (final kind in ['decline', 'cancel', 'accept']) {
    for (final replacement in ['A-B', 'A-B-A']) {
      testWidgets(
        'retained public $kind refuses stale displayed owner $replacement',
        (tester) async {
          if (kind == 'cancel') reads.rows = [_row(direction: 'outgoing')];
          await render(tester);
          await visible(tester, button(kind));
          final callback = tester
              .widget<ButtonStyleButton>(button(kind))
              .onPressed!;
          await tester.runAsync(
            () => _session(_b).timeout(const Duration(seconds: 3)),
          );
          if (replacement == 'A-B-A') {
            await tester.runAsync(
              () => _session(_a).timeout(const Duration(seconds: 3)),
            );
          }
          // Retain and invoke the real public button before the next frame.
          callback();
          await flush(tester);
          final father = find.widgetWithText(ListTile, 'Father').hitTestable();
          if (father.evaluate().isNotEmpty) {
            await tester.tap(father);
            await flush(tester);
          }
          for (final call in calls) {
            call.complete(kind == 'accept' ? null : true);
          }
          await flush(tester);
          expect(calls, isEmpty);
          expect(linked, 0);
          await unmount(tester);
        },
      );
    }

    testWidgets(
      'current-owner $kind rejection preserves error and allows retry',
      (tester) async {
        if (kind == 'cancel') reads.rows = [_row(direction: 'outgoing')];
        await render(tester);
        await action(tester, kind);
        final priorReads = reads.requestCalls;
        calls.single.complete(
          kind == 'accept'
              ? {'message': 'request_expired', 'code': 'P0001'}
              : false,
          status: kind == 'accept' ? 400 : 200,
        );
        await flush(tester);
        expect(
          find.text(
            kind == 'accept'
                ? 'This request has expired.'
                : kind == 'decline'
                ? "That request couldn't be declined."
                : "That request couldn't be cancelled.",
          ),
          findsOneWidget,
        );
        expect(find.text('Synthetic Seeker'), findsOneWidget);
        expect(reads.requestCalls, priorReads);
        expect(linked, 0);
        await visible(tester, button(kind));
        await tester.tap(button(kind).hitTestable());
        if (kind == 'accept') {
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(ListTile, 'Father').hitTestable(),
          );
        }
        await flush(tester);
        expect(calls, hasLength(2));
        reads.rows = [];
        calls.last.complete(kind == 'accept' ? null : true);
        await flush(tester);
        expect(find.text('Synthetic Seeker'), findsNothing);
        expect(linked, kind == 'accept' ? 1 : 0);
        await unmount(tester);
      },
    );
  }

  testWidgets('rapid public Accept taps start only one relationship request', (
    tester,
  ) async {
    await render(tester);
    await visible(tester, button('accept'));
    final retained = tester.widget<FilledButton>(button('accept')).onPressed!;
    await tester.tap(button('accept').hitTestable());
    retained();
    await tester.pumpAndSettle();
    final father = find.widgetWithText(ListTile, 'Father').hitTestable();
    expect(father, findsOneWidget);
    await tester.tap(father);
    await flush(tester);
    // Drain any erroneously duplicated baseline modal/ACK before assertions.
    final duplicateFather = find
        .widgetWithText(ListTile, 'Father')
        .hitTestable();
    if (duplicateFather.evaluate().isNotEmpty) {
      await tester.tap(duplicateFather);
      await flush(tester);
    }
    reads.rows = [];
    for (final call in calls) {
      call.complete(null);
    }
    await flush(tester);
    expect(calls, hasLength(1));
    expect(linked, 1);
    expect(find.text('How are you related?'), findsNothing);
    await unmount(tester);
  });

  testWidgets('dismissed relationship sheet releases local action for retry', (
    tester,
  ) async {
    await render(tester);
    await visible(tester, button('accept'));
    await tester.tap(button('accept').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('How are you related?'), findsOneWidget);
    Navigator.of(tester.element(find.text('How are you related?'))).pop();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await action(tester, 'accept');
    reads.rows = [];
    calls.single.complete(null);
    await flush(tester);
    expect(linked, 1);
    await unmount(tester);
  });
}
