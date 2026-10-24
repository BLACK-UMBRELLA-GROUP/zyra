import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/settings/sign_in_security_screen.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'widget-test-key',
    );
    ZyraText.useTestFontStubs = true;
  });

  tearDownAll(() => ZyraText.useTestFontStubs = false);

  testWidgets(
    'shows only the currently connected Google method without a linking action',
    (tester) async {
      await _setSession(const ['google']);
      await _pumpScreen(tester);

      expect(find.text('How you sign in'), findsOneWidget);
      expect(
        find.text(
          'These are the sign-in methods currently connected to your ZYRA account.',
        ),
        findsOneWidget,
      );
      expect(find.text('CURRENT SIGN-IN METHODS'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('google.member@example.com'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Not connected'), findsNothing);
      expect(find.text('Your ways into ZYRA'), findsNothing);

      final googleMethod = find.byKey(const ValueKey('sign_in_method_google'));
      expect(googleMethod, findsOneWidget);
      expect(
        find.descendant(of: googleMethod, matching: find.byType(TextButton)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows both methods when both are already connected', (
    tester,
  ) async {
    await _setSession(const ['google', 'apple']);
    await _pumpScreen(tester);

    final appleMethod = find.byKey(const ValueKey('sign_in_method_apple'));
    final googleMethod = find.byKey(const ValueKey('sign_in_method_google'));

    expect(appleMethod, findsOneWidget);
    expect(googleMethod, findsOneWidget);
    expect(
      tester.getTopLeft(appleMethod).dy,
      lessThan(tester.getTopLeft(googleMethod).dy),
    );
    expect(
      find.descendant(of: appleMethod, matching: find.byType(TextButton)),
      findsNothing,
    );
    expect(
      find.descendant(of: googleMethod, matching: find.byType(TextButton)),
      findsNothing,
    );
    expect(find.text('Not connected'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a seeded email-only account truthful and non-actionable', (
    tester,
  ) async {
    await _setSession(const ['email']);
    await _pumpScreen(tester);

    final emailMethod = find.byKey(const ValueKey('sign_in_method_email'));
    expect(emailMethod, findsOneWidget);
    expect(find.text('Email sign-in'), findsOneWidget);
    expect(
      find.descendant(
        of: emailMethod,
        matching: find.text('email.member@example.com'),
      ),
      findsOneWidget,
    );
    expect(find.text('Apple'), findsNothing);
    expect(find.text('Google'), findsNothing);
    expect(
      find.descendant(of: emailMethod, matching: find.byType(TextButton)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: SignInSecurityScreen()));
  await tester.pump();
}

Future<void> _setSession(List<String> providers) async {
  const userId = '00000000-0000-0000-0000-000000000277';
  const createdAt = '2026-08-29T00:00:00.000Z';
  final primaryProvider = providers.first;
  final accountEmail = '$primaryProvider.member@example.com';
  final identities = <Map<String, Object?>>[
    for (final provider in providers)
      {
        'id': '$provider-id',
        'user_id': userId,
        'identity_data': {
          'email': '$provider.member@example.com',
          'email_verified': true,
        },
        'identity_id': '$provider-subject',
        'provider': provider,
        'created_at': createdAt,
        'last_sign_in_at': createdAt,
        'updated_at': createdAt,
      },
  ];

  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token': 'oa-zyra-277-widget-test-token',
      'token_type': 'bearer',
      'user': {
        'id': userId,
        'app_metadata': {'provider': primaryProvider, 'providers': providers},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'email': accountEmail,
        'created_at': createdAt,
        'identities': identities,
      },
    }),
  );
}
