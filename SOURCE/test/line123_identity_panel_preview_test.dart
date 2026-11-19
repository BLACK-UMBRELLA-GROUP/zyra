import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/zyra_identity_verification.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/settings/privacy_and_data_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_identity_verification_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/theme/zyra_text.dart';

const _owner = ZyraInternalFounderPolicy.approvedFounderUserId;
const _project = ZyraInternalFounderPolicy.approvedSupabaseUrl;
const _screenKey = ValueKey('line123-panel-idv-owner');
Finder _key(String value) => find.byKey(ValueKey(value));

Map<String, Object?> _session({
  String lifetime = 'line123-synthetic-session',
  String? claim = 'founder',
  int version = 0,
}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final metadata = {'zyra_role': ?claim};
  final claims = {
    'iss': '$_project/auth/v1',
    'sub': _owner,
    'exp': 4102444800,
    'session_id': lifetime,
    'app_metadata': metadata,
    'jti': 'line123-fixture-$version',
  };
  return {
    'access_token': '${part({'alg': 'HS256'})}.${part(claims)}.${part([1])}',
    'refresh_token': 'line123-synthetic-refresh-$version',
    'token_type': 'bearer',
    'user': {
      'id': _owner,
      'aud': 'authenticated',
      'email': 'sample-admin@example.org',
      'created_at': '2026-11-19T00:00:00Z',
      'app_metadata': metadata,
      'user_metadata': <String, Object?>{},
    },
  };
}

// An explicit constructor fixture, never a provider result or app action.
ZyraIdentityVerificationState _verifiedFixture() =>
    ZyraIdentityVerificationState(
      result: ZyraIdentityVerificationResult.verified,
      duplicateReview: ZyraDuplicateReviewState.clear,
      consentGranted: true,
      consentVersion: kIdentityVerificationConsentVersion,
      consentRecordedAt: DateTime.utc(2026, 11, 19),
      updatedAt: DateTime.utc(2026, 11, 19),
      decidedAt: DateTime.utc(2026, 11, 19),
    );

class _CountingProvider implements ZyraIdentityVerificationProviderAdapter {
  var calls = 0;

  @override
  Future<ZyraVerificationLaunchOutcome> launch() async {
    calls++;
    return ZyraVerificationLaunchOutcome.unavailable;
  }
}

Future<void> _mount(
  WidgetTester tester,
  ZyraDeveloperPanelAccess access, {
  bool devPreview = true,
  ZyraIdentityVerificationState? initialState,
  Future<String?> Function()? finalizeOnboarding,
  Future<void> Function(BuildContext)? onContinue,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: InitialIdentityCheckScreen(
        key: _screenKey,
        devPreview: devPreview,
        developerPanelAccess: access,
        initialState: initialState,
        finalizeOnboarding: finalizeOnboarding,
        onContinue: onContinue,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final proofs = <ZyraDeveloperPanelAccess>[];
  final requests = <String>[];
  var version = 0;
  var lifetime = 'line123-synthetic-session';
  String? claim = 'founder';
  late _CountingProvider provider;

  Future<void> installSession() => supabase.auth.setInitialSession(
    jsonEncode(
      _session(lifetime: lifetime, claim: claim, version: 1000 + version),
    ),
  );

  Future<ZyraDeveloperPanelAccess> admitted(WidgetTester tester) async {
    final access = ZyraDeveloperPanelAccess();
    proofs.add(access);
    expect(await tester.runAsync(access.verify), isTrue);
    expect(access.email, isNotNull);
    expect(access.verifiedLifetime, isNotNull);
    return access;
  }

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'com.llfbandit.app_links/messages',
      'com.llfbandit.app_links/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: _project,
      publishableKey: 'line123-synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add(request.url.path);
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode(
              _session(lifetime: lifetime, claim: claim, version: ++version),
            ),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"message":"unexpected local test request"}',
          403,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = true;
    version = 0;
    lifetime = 'line123-synthetic-session';
    claim = 'founder';
    await installSession();
    await ZyraAccountState.synchronize(_owner);
    requests.clear();
    provider = _CountingProvider();
    ZyraIdentityVerificationService.setProviderForTesting(provider);
  });

  tearDown(() {
    expect(provider.calls, 0);
    expect(requests.where((path) => path != '/auth/v1/token'), isEmpty);
    expect(ZyraProductTelemetry.instance.snapshot.sessionEventCount, 0);
    for (final proof in proofs) {
      proof.dispose();
    }
    proofs.clear();
    ZyraIdentityVerificationService.resetProviderForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets(
    'invalid typed proof never borrows legacy permission or revives',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      final access = ZyraDeveloperPanelAccess();
      proofs.add(access);
      await _mount(tester, access);
      expect(_key('identity_preview_denied'), findsOneWidget);
      expect(_key('identity-consent-agree'), findsNothing);
      expect(await tester.runAsync(access.verify), isTrue);
      await tester.pumpAndSettle();
      expect(access.email, isNotNull);
      expect(_key('identity_preview_denied'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('panel argument without devPreview stays denied and isolated', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final access = await admitted(tester);
    var finalized = 0;
    var continued = 0;
    await _mount(
      tester,
      access,
      devPreview: false,
      initialState: _verifiedFixture(),
      finalizeOnboarding: () async {
        finalized++;
        return null;
      },
      onContinue: (_) async {
        continued++;
      },
    );
    expect(_key('identity_preview_denied'), findsOneWidget);
    expect(_key('identity-continue'), findsNothing);
    expect(_key('identity-use-different-account'), findsNothing);
    expect(finalized, 0);
    expect(continued, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('panel-only claim keeps provider attempt local and unavailable', (
    tester,
  ) async {
    final access = await admitted(tester);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    requests.clear();
    await _mount(tester, access);
    await _tap(tester, _key('identity-consent-agree'));
    expect(find.text('Verification is unavailable.'), findsOneWidget);
    expect(_key('identity-continue'), findsNothing);
    expect(requests, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('explicit verified fixture continues locally without finalizer', (
    tester,
  ) async {
    final access = await admitted(tester);
    var finalized = 0;
    var continued = 0;
    requests.clear();
    await _mount(
      tester,
      access,
      initialState: _verifiedFixture(),
      finalizeOnboarding: () async {
        finalized++;
        return null;
      },
      onContinue: (_) async {
        continued++;
      },
    );
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    await _tap(tester, _key('identity-continue'));
    expect(continued, 1);
    expect(finalized, 0);
    expect(requests, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final loss in ['suspend', 'claim', 'session']) {
    testWidgets(
      'panel $loss loss permanently retires mounted IDV and stale Continue',
      (tester) async {
        final access = await admitted(tester);
        var continued = 0;
        await _mount(
          tester,
          access,
          initialState: _verifiedFixture(),
          onContinue: (_) async {
            continued++;
          },
        );
        final dynamic button = tester.widget<Widget>(_key('identity-continue'));
        final VoidCallback stale = button.onPressed;
        if (loss == 'suspend') {
          access.suspend();
        } else {
          if (loss == 'claim') claim = null;
          if (loss == 'session') lifetime = 'line123-replacement-session';
          await tester.runAsync(installSession);
        }
        await tester.pumpAndSettle();
        expect(_key('identity_preview_denied'), findsOneWidget);
        stale();
        await tester.pumpAndSettle();
        expect(continued, 0);
        claim = 'founder';
        await tester.runAsync(installSession);
        expect(await tester.runAsync(access.verify), isTrue);
        await tester.pumpAndSettle();
        expect(access.email, isNotNull);
        expect(_key('identity_preview_denied'), findsOneWidget);
        stale();
        await tester.pumpAndSettle();
        expect(continued, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('replacing panel object cannot resurrect the same IDV owner', (
    tester,
  ) async {
    final first = await admitted(tester);
    final second = await admitted(tester);
    final initial = _verifiedFixture();
    var continued = 0;
    Future<void> next(BuildContext _) async {
      continued++;
    }

    await _mount(tester, first, initialState: initial, onContinue: next);
    final dynamic button = tester.widget<Widget>(_key('identity-continue'));
    final VoidCallback stale = button.onPressed;
    await _mount(tester, second, initialState: initial, onContinue: next);
    expect(_key('identity_preview_denied'), findsOneWidget);
    await _mount(tester, first, initialState: initial, onContinue: next);
    expect(_key('identity_preview_denied'), findsOneWidget);
    stale();
    await tester.pumpAndSettle();
    expect(continued, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('healthy same-session title refresh preserves panel IDV lease', (
    tester,
  ) async {
    final access = await admitted(tester);
    await _mount(tester, access, initialState: _verifiedFixture());
    expect(await tester.runAsync(access.refreshForTitle), isTrue);
    await tester.pumpAndSettle();
    expect(_key('identity-continue'), findsOneWidget);
    expect(_key('identity_preview_denied'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('panel privacy descendants revoke with the original proof', (
    tester,
  ) async {
    final access = await admitted(tester);
    await _mount(tester, access);
    await _tap(tester, _key('identity-privacy-policy'));
    expect(find.byType(IdentityVerificationPrivacyScreen), findsOneWidget);
    await _tap(tester, _key('identity_privacy_summary'));
    expect(find.byType(PrivacyAndDataScreen), findsNothing);
    access.suspend();
    await tester.pumpAndSettle();
    expect(_key('identity_preview_privacy_unavailable'), findsOneWidget);
    expect(await tester.runAsync(access.verify), isTrue);
    await tester.pumpAndSettle();
    expect(_key('identity_preview_privacy_unavailable'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
