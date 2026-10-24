import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/profile/profile_screen.dart';
import 'package:zyra/screens/wali/wali_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_account_switch_sheet.dart';

const _member = '00000000-0000-4000-8000-000000000861';
const _otherMember = '00000000-0000-4000-8000-000000000862';

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
        'created_at': '2026-10-08T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        final Object body;
        if (request.method == 'POST' && path.endsWith('/unlock_balance')) {
          body = <Object>[];
        } else if (request.method == 'POST' &&
            path.endsWith('/wali_has_wali_one')) {
          body = false;
        } else {
          throw StateError('Unexpected synthetic transport operation: $path');
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
    requests.clear();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraText.useTestFontStubs = true;
    await _session(_member);
    AppState.instance.name = 'Synthetic member';
    AppState.instance.waliName = 'Synthetic member';
    AppState.instance.gender = 'male';
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
    expect(
      requests.every(
        (request) =>
            request.method == 'POST' &&
            (request.url.path.endsWith('/unlock_balance') ||
                request.url.path.endsWith('/wali_has_wali_one')),
      ),
      isTrue,
      reason: 'Only allowlisted read RPCs may use the fake transport.',
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  Widget profile(bool guardian) => MaterialApp(
    home: Scaffold(
      body: guardian
          ? WaliProfileScreen(
              loadLinkedSeekers: () async =>
                  const ZyraSourceResult.available(<WaliLinkedPerson>[]),
            )
          : const ProfileScreen(),
    ),
  );

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    testWidgets('ordinary $role Profile does not expose context switching', (
      tester,
    ) async {
      await tester.pumpWidget(profile(guardian));
      await tester.pumpAndSettle();

      expect(ZyraDeveloperAccess.isMainAppFounderPreview, isFalse);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(find.byType(ZyraAccountSwitchButton), findsNothing);
      expect(find.byType(ZyraAccountSwitchScreen), findsNothing);
    });

    testWidgets('authorised $role Profile renders the public switch button', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      await tester.pumpWidget(profile(guardian));
      await tester.pumpAndSettle();

      expect(find.byType(ZyraAccountSwitchButton), findsOneWidget);
      expect(
        find.byKey(const ValueKey('switch-account-button')),
        findsOneWidget,
      );
    });

    testWidgets('revoked $role public switch callback cannot open a route', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      await tester.pumpWidget(profile(guardian));
      await tester.pumpAndSettle();
      final callback = tester
          .widget<ZyraAccountSwitchButton>(find.byType(ZyraAccountSwitchButton))
          .onPressed;
      final state = AppState.instance;
      final name = state.name;
      final guardianName = state.waliName;
      final plan = state.plan;
      final guardianOne = state.waliHasWaliOne;
      final generation = ZyraAccountState.generation;
      final beforeRequests = requests.length;

      // Invoke the callback from the actual previously authorised renderer,
      // before a rebuild can remove its button. No private State access or
      // ordinary button exposure is involved.
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      callback();
      await tester.pumpAndSettle();

      expect(find.byType(ZyraAccountSwitchScreen), findsNothing);
      expect(find.byType(GuardianOnboardingOverviewScreen), findsNothing);
      expect(find.byType(SeekerOnboardingOverviewScreen), findsNothing);
      expect(state.name, name);
      expect(state.waliName, guardianName);
      expect(state.plan, plan);
      expect(state.waliHasWaliOne, guardianOne);
      expect(ZyraAccountState.userId, _member);
      expect(ZyraAccountState.generation, generation);
      expect(requests.length, beforeRequests);
    });

    testWidgets('revoked $role open picker cannot change account context', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      await tester.pumpWidget(profile(guardian));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('switch-account-button')));
      await tester.pumpAndSettle();
      expect(find.byType(ZyraAccountSwitchScreen), findsOneWidget);
      final state = AppState.instance;
      final name = state.name;
      final guardianName = state.waliName;
      final plan = state.plan;
      final guardianOne = state.waliHasWaliOne;
      final generation = ZyraAccountState.generation;
      final beforeRequests = requests.length;

      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.tap(
        find.text(guardian ? 'Seeker Account' : 'Guardian Account'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ZyraAccountSwitchScreen), findsNothing);
      expect(find.byType(GuardianOnboardingOverviewScreen), findsNothing);
      expect(find.byType(SeekerOnboardingOverviewScreen), findsNothing);
      expect(
        find.byType(guardian ? WaliProfileScreen : ProfileScreen),
        findsOneWidget,
      );
      expect(state.name, name);
      expect(state.waliName, guardianName);
      expect(state.plan, plan);
      expect(state.waliHasWaliOne, guardianOne);
      expect(ZyraAccountState.userId, _member);
      expect(ZyraAccountState.generation, generation);
      expect(requests.length, beforeRequests);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$role open picker denies A to B to A account replacement', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      await tester.pumpWidget(profile(guardian));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('switch-account-button')));
      await tester.pumpAndSettle();
      expect(find.byType(ZyraAccountSwitchScreen), findsOneWidget);
      final originalGeneration = ZyraAccountState.generation;

      // Auth storage/session Futures use real asynchronous work, unlike the
      // widget clock. Keep this replacement outside FakeAsync, with a bound
      // so a broken fixture cannot wait indefinitely.
      await tester.runAsync(() async {
        await _session(_otherMember).timeout(const Duration(seconds: 5));
        await _session(_member).timeout(const Duration(seconds: 5));
      });
      expect(ZyraDeveloperAccess.isMainAppFounderPreview, isTrue);
      expect(ZyraAccountState.generation, greaterThan(originalGeneration));
      final state = AppState.instance;
      state.name = 'Fresh replacement member';
      state.waliName = 'Fresh replacement Guardian';
      final generation = ZyraAccountState.generation;
      final beforeRequests = requests.length;
      await tester.tap(
        find.text(guardian ? 'Seeker Account' : 'Guardian Account'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ZyraAccountSwitchScreen), findsNothing);
      expect(find.byType(GuardianOnboardingOverviewScreen), findsNothing);
      expect(find.byType(SeekerOnboardingOverviewScreen), findsNothing);
      expect(
        find.byType(guardian ? WaliProfileScreen : ProfileScreen),
        findsOneWidget,
      );
      expect(state.name, 'Fresh replacement member');
      expect(state.waliName, 'Fresh replacement Guardian');
      expect(state.plan, ZyraPlan.basic);
      expect(state.waliHasWaliOne, isFalse);
      expect(ZyraAccountState.userId, _member);
      expect(ZyraAccountState.generation, generation);
      expect(requests.length, beforeRequests);
      expect(tester.takeException(), isNull);
    });
  }
}
