import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

class _UnavailableDraftStore implements ZyraSignupDraftStore {
  int reads = 0;

  @override
  Future<String?> read(String key) async {
    reads++;
    throw StateError('Synthetic private storage failure');
  }

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('Unexpected test write');

  @override
  Future<void> delete(String key) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      // Every HTTP request is intercepted; no provider or live account call.
      httpClient: MockClient(
        (request) async => http.Response(
          '[]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    await ZyraLocalPrefs.init();
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraText.useTestFontStubs = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const userId = '00000000-0000-0000-0000-000000000804';
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    // Unsigned synthetic session fixture, never a live credential.
    final token =
        '${part({'alg': 'none'})}.'
        '${part({'sub': userId, 'exp': 4102444800})}.synthetic';
    await supabase.auth.setInitialSession(
      jsonEncode({
        'access_token': token,
        'token_type': 'bearer',
        'refresh_token': 'synthetic-refresh',
        'user': {
          'id': userId,
          'app_metadata': {'provider': 'google'},
          'user_metadata': <String, Object?>{},
          'aud': 'authenticated',
          'created_at': '2026-09-13T06:00:00Z',
        },
      }),
    );
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () async => supabase.auth.currentUser,
      founderIdentityMatches: (_) => false,
    );
  });
  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.resetForTesting();
    ZyraText.useTestFontStubs = false;
    debugDefaultTargetPlatformOverride = null;
  });

  void expectRecovered(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.byType(ZyraErrorBanner), findsOneWidget);
    expect(find.textContaining('Synthetic'), findsNothing);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('welcome_recovery_email')),
          )
          .onPressed,
      isNotNull,
    );
    debugDefaultTargetPlatformOverride = null;
  }

  for (final provider in ['Google', 'Apple']) {
    testWidgets('$provider thrown sign-in releases the Welcome controls', (
      tester,
    ) async {
      Future<ZyraAuthResult> failure() async =>
          throw StateError('Synthetic private provider detail');
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(googleSignIn: failure, appleSignIn: failure),
        ),
      );
      await tester.tap(find.text('Continue with $provider'));
      await tester.pumpAndSettle();
      expectRecovered(tester);
    });
  }

  testWidgets('post-OAuth failed protected routing releases Welcome controls', (
    tester,
  ) async {
    final store = _UnavailableDraftStore();
    ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: store,
        backend: 'https://example.supabase.co',
        currentUserId: () => supabase.auth.currentUser?.id,
        isPreview: () => false,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
          googleSignIn: () async => const ZyraAuthResult.success(),
        ),
      ),
    );
    await tester.tap(find.text('Continue with Google'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(store.reads, greaterThan(0));
    expectRecovered(tester);
  });

  testWidgets('disposed Welcome ignores a late thrown provider result', (
    tester,
  ) async {
    final result = Completer<ZyraAuthResult>();
    await tester.pumpWidget(
      MaterialApp(home: WelcomeScreen(googleSignIn: () => result.future)),
    );
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    result.completeError(StateError('Synthetic private late result'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(WelcomeScreen), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
