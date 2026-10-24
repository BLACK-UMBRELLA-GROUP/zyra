import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/onboarding/article9_consent_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _owner = '00000000-0000-0000-0000-000000000921';
const _other = '00000000-0000-0000-0000-000000000922';

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
  final decisions = <bool>[];

  http.Response saved(http.Request request) => http.Response(
    'null',
    200,
    request: request,
    headers: {'content-type': 'application/json'},
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    responder = (request) async => saved(request);
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
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await _session(_owner);
    await ZyraAccountState.synchronize(_owner);
    requests.clear();
    decisions.clear();
    responder = (request) async => saved(request);
  });
  tearDown(() {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });

  Future<void> showConsent(WidgetTester tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpWidget(
      MaterialApp(home: Article9ConsentScreen(onDecision: decisions.add)),
    );
  }

  Future<void> changeOwner(WidgetTester tester, String owner) async {
    await tester.runAsync(() async {
      await _session(owner);
      await ZyraAccountState.synchronize(owner);
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'old consent screen withdraws before next member can agree',
    (tester) async {
      await showConsent(tester);
      await changeOwner(tester, _other);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Skip these questions'), findsNothing);
      expect(requests, isEmpty);
      expect(decisions, isEmpty);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'retained accept callback cannot consent the next account',
    (tester) async {
      await showConsent(tester);
      final accept = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      await changeOwner(tester, _other);
      accept();
      await tester.pump();
      await tester.pump();
      expect(requests, isEmpty);
      expect(decisions, isEmpty);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'returning original account cannot revive old consent controls',
    (tester) async {
      await showConsent(tester);
      final accept = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      await changeOwner(tester, _other);
      await changeOwner(tester, _owner);
      accept();
      await tester.pump();
      await tester.pump();
      expect(find.byType(FilledButton), findsNothing);
      expect(requests, isEmpty);
      expect(decisions, isEmpty);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'same-account replacement invalidates the rendered decision',
    (tester) async {
      await showConsent(tester);
      final accept = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      await tester.runAsync(() async {
        ZyraAccountState.resetForTesting();
        await ZyraAccountState.synchronize(_owner);
      });
      await tester.pump();
      accept();
      await tester.pump();
      expect(requests, isEmpty);
      expect(decisions, isEmpty);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'late saved consent does not revive a withdrawn screen',
    (tester) async {
      await showConsent(tester);
      final delayed = Completer<http.Response>();
      http.Request? request;
      responder = (value) {
        request = value;
        return delayed.future;
      };
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
      await tester.pump();
      expect(request, isNotNull);
      await changeOwner(tester, _other);
      delayed.complete(saved(request!));
      await tester.pump();
      await tester.pump();
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(decisions, isEmpty);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  for (final granted in [true, false]) {
    testWidgets(
      'unchanged owner can record granted=$granted',
      (tester) async {
        await showConsent(tester);
        if (granted) {
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
        } else {
          final skip = tester.widget<TextButton>(
            find.ancestor(
              of: find.text('Skip these questions'),
              matching: find.byType(TextButton),
            ),
          );
          skip.onPressed!();
        }
        await tester.pump();
        await tester.pump();
        expect(requests.length, 1);
        expect(jsonDecode(requests.single.body)['user_id'], _owner);
        expect(jsonDecode(requests.single.body)['granted'], granted);
        expect(decisions, [granted]);
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );
  }
}
