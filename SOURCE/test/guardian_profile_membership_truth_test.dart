// Public ordinary-member widget controls; synthetic transport only, no live authority.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/wali/wali_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_entitlement_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_one_profile_avatar.dart';
import 'package:zyra/widgets/zyra_profile_membership_row.dart';

const _a = '00000000-0000-4000-8000-000000003311';
const _b = '00000000-0000-4000-8000-000000003312';

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
        'created_at': '2026-10-16T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Object? answer;
  int status = 200;
  int requests = 0;
  Future<void>? held;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://generated.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.method != 'POST' ||
            request.url.path != '/rest/v1/rpc/wali_has_wali_one') {
          throw StateError('Unexpected ordinary-profile synthetic request.');
        }
        requests++;
        final body = answer;
        final code = status;
        final waiting = held;
        await waiting;
        return http.Response(
          jsonEncode(
            code == 200
                ? body
                : {
                    'code': 'SYNTHETIC_UNAVAILABLE',
                    'message': 'Synthetic read unavailable',
                  },
          ),
          code,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
    answer = true;
    status = 200;
    held = null;
    requests = 0;
    await _session(_a);
  });
  tearDown(() {
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  ZyraProfileMembershipRow row(WidgetTester tester) =>
      tester.widget(find.byKey(const ValueKey('guardian-profile-membership')));
  bool badge(WidgetTester tester) => tester
      .widget<ZyraOneProfileAvatar>(find.byType(ZyraOneProfileAvatar))
      .isOne;
  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaliProfileScreen(
            loadLinkedSeekers: () async =>
                const ZyraSourceResult.available(<WaliLinkedPerson>[]),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(ZyraDeveloperAccess.isMainAppFounderPreview, isFalse);
    expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
  }

  Future<void> flush(WidgetTester tester) async {
    // Advance only synthetic retry clocks; not evidence of production latency.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('pending ordinary membership is not confirmed inactive', (
    tester,
  ) async {
    final release = Completer<void>();
    held = release.future;
    try {
      await mount(tester);
      expect(requests, 1);
      expect(row(tester).value, 'Checking…');
      expect(row(tester).isOne, isFalse);
      expect(badge(tester), isFalse);
    } finally {
      release.complete();
      await flush(tester);
    }
  });

  for (final malformed in [false, true]) {
    testWidgets(
      '${malformed ? 'malformed' : '503'} membership read does not invent an inactive membership',
      (tester) async {
        expect(
          (await ZyraEntitlementService.resolveGuardianPaidAccess())
              .valueOrNull,
          isTrue,
        );
        expect(AppState.instance.waliHasWaliOne, isTrue);
        status = malformed ? 200 : 503;
        answer = null;
        await mount(tester);
        await flush(tester);
        expect(AppState.instance.waliHasWaliOne, isTrue);
        expect(row(tester).value, 'Unavailable');
        expect(row(tester).isOne, isFalse);
        expect(badge(tester), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'confirmed false still clears the ordinary paid membership display',
    (tester) async {
      expect(
        (await ZyraEntitlementService.resolveGuardianPaidAccess()).valueOrNull,
        isTrue,
      );
      answer = false;
      await mount(tester);
      await flush(tester);
      expect(row(tester).value, 'No active membership');
      expect(row(tester).isOne, isFalse);
      expect(badge(tester), isFalse);
      expect(AppState.instance.waliHasWaliOne, isFalse);
    },
  );

  for (final initialPaid in [false, true]) {
    testWidgets(
      'same-owner confirmed ${initialPaid ? 'loss' : 'gain'} updates the mounted membership display',
      (tester) async {
        answer = initialPaid;
        await mount(tester);
        await flush(tester);
        expect(badge(tester), initialPaid);
        answer = !initialPaid;
        expect(
          (await ZyraEntitlementService.resolveGuardianPaidAccess())
              .valueOrNull,
          !initialPaid,
        );
        await tester.pump();
        expect(
          row(tester).value,
          initialPaid ? 'No active membership' : 'Guardian One',
        );
        expect(row(tester).isOne, !initialPaid);
        expect(badge(tester), !initialPaid);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final returnToA in [false, true]) {
    testWidgets(
      'late paid reply is withdrawn for ${returnToA ? 'A-B-A' : 'A-B'}',
      (tester) async {
        final release = Completer<void>();
        held = release.future;
        try {
          await mount(tester);
          expect(requests, 1);
          final generation = ZyraAccountState.generation;
          await tester.runAsync(() async {
            await _session(_b).timeout(const Duration(seconds: 5));
            if (returnToA) {
              await _session(_a).timeout(const Duration(seconds: 5));
            }
          });
          expect(ZyraAccountState.generation, greaterThan(generation));
        } finally {
          release.complete();
        }
        await flush(tester);
        expect(row(tester).value, isNot('Guardian One'));
        expect(row(tester).isOne, isFalse);
        expect(badge(tester), isFalse);
        expect(AppState.instance.waliHasWaliOne, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'confirmed paid display withdraws on ${returnToA ? 'A-B-A' : 'A-B'} without remount',
      (tester) async {
        await mount(tester);
        await flush(tester);
        expect(row(tester).value, 'Guardian One');
        expect(badge(tester), isTrue);
        final generation = ZyraAccountState.generation;
        await tester.runAsync(() async {
          await _session(_b).timeout(const Duration(seconds: 5));
          if (returnToA) await _session(_a).timeout(const Duration(seconds: 5));
        });
        await tester.pump();
        expect(ZyraAccountState.generation, greaterThan(generation));
        expect(row(tester).value, isNot('Guardian One'));
        expect(row(tester).isOne, isFalse);
        expect(badge(tester), isFalse);
        expect(AppState.instance.waliHasWaliOne, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
