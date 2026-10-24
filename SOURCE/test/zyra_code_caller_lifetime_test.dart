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
import 'package:zyra/main.dart' show supabase, supabaseReady;
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
            {_acceptPath, _declinePath, _cancelPath}.contains(request.url.path);
        if (!allowed) {
          denied.add('${request.method} ${request.url}');
          throw StateError('Strict Code evidence transport refused request');
        }
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final accept = request.url.path == _acceptPath;
        final keys = payload.keys.toSet();
        if (payload['p_request_id'] != _requestId ||
            keys.length != (accept ? 2 : 1) ||
            !keys.contains('p_request_id') ||
            accept &&
                (!keys.contains('p_relationship') ||
                    payload['p_relationship'] != 'father')) {
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
    expect(find.text(_codeA), findsOneWidget);
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
      expect(find.text(_codeA), findsNothing);
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
      expect(find.text(_codeNew), findsOneWidget);
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
