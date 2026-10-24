import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/settings/feedback_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_feedback_service.dart';
import 'package:zyra/theme/zyra_text.dart';

const _owner = '00000000-0000-0000-0000-000000000911';
const _other = '00000000-0000-0000-0000-000000000912';
const _packageChannel = MethodChannel('dev.fluttercommunity.plus/package_info');

Future<void> _session(String id) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return supabase.auth.setInitialSession(
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
        'created_at': '2026-10-13T00:00:00Z',
      },
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<http.Response> Function(http.Request) responder;
  final requests = <http.Request>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  http.Response json(http.Request request, Object? value) => http.Response(
    jsonEncode(value),
    200,
    request: request,
    headers: {'content-type': 'application/json'},
  );

  Future<ZyraFeedbackResult> submit() => ZyraFeedbackService.submit(
    category: ZyraFeedbackCategory.problem,
    message: 'Synthetic private draft for the original account.',
    screen: 'settings/feedback',
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    responder = (request) async => json(request, {'status': 'sent'});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) {
        requests.add(request);
        return responder(request);
      }),
    );
  });

  tearDownAll(() async {
    messenger.setMockMethodCallHandler(_packageChannel, null);
    await Supabase.instance.dispose();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await _session(_owner);
    await ZyraAccountState.synchronize(_owner);
    requests.clear();
    responder = (request) async => json(request, {'status': 'sent'});
  });

  tearDown(() {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });

  // Run first: PackageInfo intentionally caches its first successful platform
  // lookup. Later cases test the cached-version path and pending RPCs.
  test(
    'account change during platform lookup never sends the old draft',
    () async {
      final started = Completer<void>();
      final package = Completer<Object?>();
      messenger.setMockMethodCallHandler(_packageChannel, (_) {
        started.complete();
        return package.future;
      });
      final pending = submit();
      await started.future;
      await _session(_other);
      await ZyraAccountState.synchronize(_other);
      package.complete({
        'appName': 'ZYRA',
        'packageName': 'app.zyraconnect.zyra',
        'version': '1.0.0',
        'buildNumber': '5',
      });
      expect(await pending, ZyraFeedbackResult.failed);
      expect(requests, isEmpty);
    },
  );

  test(
    'late success is discarded after a different account signs in',
    () async {
      final started = Completer<void>();
      final delayed = Completer<http.Response>();
      late http.Request request;
      responder = (value) {
        request = value;
        started.complete();
        return delayed.future;
      };
      final pending = submit();
      await started.future;
      await _session(_other);
      await ZyraAccountState.synchronize(_other);
      delayed.complete(json(request, {'status': 'sent'}));
      expect(await pending, ZyraFeedbackResult.failed);
    },
  );

  test(
    'late success is discarded after same-account generation changes',
    () async {
      final started = Completer<void>();
      final delayed = Completer<http.Response>();
      late http.Request request;
      responder = (value) {
        request = value;
        started.complete();
        return delayed.future;
      };
      final pending = submit();
      await started.future;
      ZyraAccountState.resetForTesting();
      delayed.complete(json(request, {'status': 'sent'}));
      expect(await pending, ZyraFeedbackResult.failed);
    },
  );

  test(
    'pending sign-out refuses dispatch despite retained SDK session',
    () async {
      await ZyraAccountState.beginSignOut();
      requests.clear();
      expect(await submit(), ZyraFeedbackResult.failed);
      expect(requests, isEmpty);
    },
  );

  test('normal submit preserves payload and original caller', () async {
    expect(await submit(), ZyraFeedbackResult.sent);
    expect(requests.length, 1);
    final request = requests.single;
    expect(request.url.path, endsWith('/rpc/zyra_submit_feedback'));
    final payload = jsonDecode(request.body);
    expect(payload['p_category'], 'problem');
    expect(
      payload['p_message'],
      'Synthetic private draft for the original account.',
    );
    expect(payload['p_app_version'], '1.0.0+5');
    expect(payload['p_screen'], 'settings/feedback');
    final bearer = request.headers['authorization']!.substring(7);
    final subject = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(bearer.split('.')[1]))),
    )['sub'];
    expect(subject, _owner);
  });

  Future<void> showForm(WidgetTester tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpWidget(const MaterialApp(home: FeedbackScreen()));
    await tester.enterText(
      find.byType(TextField),
      'Synthetic retained private draft',
    );
    await tester.pump();
  }

  GestureDetector sendButton(WidgetTester tester) =>
      tester.widget<GestureDetector>(
        find
            .ancestor(
              of: find.text('Send'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );

  testWidgets(
    'account replacement withdraws a retained draft and controls',
    (tester) async {
      await showForm(tester);
      await tester.runAsync(() async {
        await _session(_other);
        await ZyraAccountState.synchronize(_other);
      });
      await tester.pump();
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Synthetic retained private draft'), findsNothing);
      expect(find.text('Send'), findsNothing);
      expect(requests, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'retained Send callback cannot submit into the next account',
    (tester) async {
      await showForm(tester);
      final callback = sendButton(tester).onTap!;
      await tester.runAsync(() async {
        await _session(_other);
        await ZyraAccountState.synchronize(_other);
      });
      callback();
      await tester.pump();
      await tester.pump();
      expect(requests, isEmpty);
      expect(find.text('Thank you'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'old successful send cannot thank a replacement account',
    (tester) async {
      await showForm(tester);
      final delayed = Completer<http.Response>();
      http.Request? request;
      responder = (value) {
        request = value;
        return delayed.future;
      };
      sendButton(tester).onTap!();
      await tester.pump();
      expect(request, isNotNull);
      await tester.runAsync(() async {
        await _session(_other);
        await ZyraAccountState.synchronize(_other);
      });
      delayed.complete(json(request!, {'status': 'sent'}));
      await tester.pump();
      await tester.pump();
      expect(find.text('Thank you'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'ordinary send still displays thanks for its unchanged owner',
    (tester) async {
      await showForm(tester);
      sendButton(tester).onTap!();
      await tester.pump();
      await tester.pump();
      expect(find.text('Thank you'), findsOneWidget);
      expect(requests.length, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}
