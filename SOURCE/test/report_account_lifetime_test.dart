import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/settings/safety_case_status_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_hidden_profile_store.dart';
import 'package:zyra/services/zyra_report_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/report_profile_sheet.dart';

const _a = '00000000-0000-4000-8000-000000000941';
const _b = '00000000-0000-4000-8000-000000000942';
const _target = '00000000-0000-4000-8000-000000000943';

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
        'created_at': '2026-10-13T00:00:00Z',
      },
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<http.Response> Function(http.Request) respond;
  final requests = <http.Request>[];
  http.Response json(http.Request request, Object? data) => http.Response(
    jsonEncode(data),
    200,
    request: request,
    headers: {'content-type': 'application/json'},
  );
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    respond = (r) async => json(r, null);
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) {
        requests.add(r);
        return respond(r);
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraHiddenProfileStore.clearForAccountChange();
    await _session(_a);
    requests.clear();
    respond = (r) async => json(r, null);
  });
  tearDown(() => ZyraText.useTestFontStubs = false);

  test('late report cannot chain a block into a replacement account', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    respond = (r) async {
      if (r.url.path.endsWith('/profile_reports')) {
        started.complete();
        await release.future;
      }
      return json(r, null);
    };
    final pending = ZyraReportService.reportAndBlock(
      reportedId: _target,
      reason: ZyraReportReason.other,
    );
    await started.future;
    await _session(_b);
    release.complete();
    expect(await pending, isFalse);
    expect(
      requests.where((r) => r.url.path.endsWith('/zyra_block_user')),
      isEmpty,
    );
  });
  for (final operation in ['block', 'unblock']) {
    test(
      'late $operation acknowledgement cannot become current-account success',
      () async {
        final started = Completer<void>();
        final release = Completer<void>();
        respond = (r) async {
          started.complete();
          await release.future;
          return json(r, null);
        };
        final pending = operation == 'block'
            ? ZyraReportService.block(_target)
            : ZyraReportService.unblock(_target);
        await started.future;
        await _session(_b);
        release.complete();
        expect(await pending, isFalse);
      },
    );
    test('$operation explicitly pins the initiating bearer', () async {
      final token = supabase.auth.currentSession!.accessToken;
      expect(
        await (operation == 'block'
            ? ZyraReportService.block(_target)
            : ZyraReportService.unblock(_target)),
        isTrue,
      );
      expect(requests.single.headers['Authorization'], 'Bearer $token');
    });
  }
  test(
    'late safety history is unavailable after account replacement',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      respond = (r) async {
        started.complete();
        await release.future;
        return json(r, [
          {
            'case_id': 'case-a',
            'case_type': 'profile',
            'status': 'pending',
            'created_at': '2026-10-13T00:00:00Z',
          },
        ]);
      };
      final pending = ZyraReportService.safetyCases();
      await started.future;
      await _session(_b);
      release.complete();
      expect(await pending, isNull);
    },
  );

  Future<void> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showReportProfileSheet(
                context,
                profileId: _target,
                firstName: 'Sara',
              ),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Something else'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send report'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'report sheet discards late acknowledgement and never hides as B',
    (tester) async {
      await open(tester);
      final started = Completer<void>();
      final release = Completer<void>();
      respond = (r) async {
        if (r.url.path.endsWith('/profile_reports')) {
          started.complete();
          await release.future;
        }
        return json(r, null);
      };
      await tester.tap(find.text('Send report'));
      await tester.runAsync(() => started.future);
      await tester.runAsync(() => _session(_b));
      release.complete();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(
        requests.where((r) => r.url.path.endsWith('/zyra_block_user')),
        isEmpty,
      );
      expect(find.text('Report sent'), findsNothing);
      expect(
        await tester.runAsync(() => ZyraHiddenProfileStore.records()),
        isEmpty,
      );
    },
  );
  testWidgets('retained submit callback cannot dispatch after A to B to A', (
    tester,
  ) async {
    await open(tester);
    final callback = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send report'))
        .onPressed!;
    await tester.runAsync(() => _session(_b));
    await tester.pump();
    await tester.runAsync(() => _session(_a));
    await tester.pump();
    callback();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
  });
  testWidgets('retained duplicate submit callback sends one report only', (
    tester,
  ) async {
    await open(tester);
    final started = Completer<void>();
    final release = Completer<void>();
    respond = (r) async {
      if (r.url.path.endsWith('/profile_reports')) {
        if (!started.isCompleted) started.complete();
        await release.future;
      }
      return json(r, null);
    };
    final callback = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send report'))
        .onPressed!;
    callback();
    callback();
    await tester.runAsync(() => started.future);
    release.complete();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
    expect(
      requests.where((r) => r.url.path.endsWith('/profile_reports')),
      hasLength(1),
    );
    expect(find.text('Report sent'), findsOneWidget);
  });

  ZyraSafetyCase safetyCase() => ZyraSafetyCase(
    id: 'case-a',
    type: 'profile',
    status: 'reviewing',
    createdAt: DateTime(2026, 10, 13),
    updatedAt: null,
  );
  testWidgets('loaded safety statuses withdraw when the account changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SafetyCaseStatusScreen(loadCases: () async => [safetyCase()]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Under review'), findsOneWidget);
    await tester.runAsync(() => _session(_b));
    await tester.pumpAndSettle();
    expect(find.text('Under review'), findsNothing);
    expect(find.text('No reports submitted'), findsNothing);
  });
  testWidgets('pending safety statuses cannot publish after A to B to A', (
    tester,
  ) async {
    final response = Completer<List<ZyraSafetyCase>?>();
    await tester.pumpWidget(
      MaterialApp(
        home: SafetyCaseStatusScreen(loadCases: () => response.future),
      ),
    );
    await tester.pump();
    await tester.runAsync(() => _session(_b));
    await tester.runAsync(() => _session(_a));
    response.complete([safetyCase()]);
    await tester.pumpAndSettle();
    expect(find.text('Under review'), findsNothing);
    expect(find.text('No reports submitted'), findsNothing);
  });
  testWidgets('thrown safety-status lookup stays recoverable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SafetyCaseStatusScreen(
          loadCases: () async => throw StateError('synthetic unavailable'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an owned report acknowledgement survives a temporary covering page',
    (tester) async {
      await open(tester);
      final release = Completer<void>();
      final started = Completer<void>();
      respond = (request) async {
        if (request.url.path.endsWith('/profile_reports')) {
          started.complete();
          await release.future;
        }
        return json(request, null);
      };
      final navigator = Navigator.of(
        tester.element(find.widgetWithText(FilledButton, 'Send report')),
      );
      await tester.tap(find.text('Send report'));
      await tester.runAsync(() => started.future);
      navigator.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
      );
      await tester.pump(const Duration(milliseconds: 350));
      release.complete();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cover'), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('Report sent'), findsOneWidget);
      expect(
        requests.where((r) => r.url.path.endsWith('/profile_reports')),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
