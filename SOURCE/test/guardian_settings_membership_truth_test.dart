// Ordinary rendered Profile→Settings controls. All transport is synthetic and bounded.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/settings/settings_screen.dart';
import 'package:zyra/screens/wali/wali_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_entitlement_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000003321';
const _b = '00000000-0000-4000-8000-000000003322';

class _ObservedDisplay extends ValueNotifier<String> {
  _ObservedDisplay(super.value);
  bool get hasSubscriptions => hasListeners;
}

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
  int entitlementRequests = 0;
  Future<void>? held;
  final unexpected = <String>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://generated.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/rest/v1/rpc/wali_has_wali_one') {
          entitlementRequests++;
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
        }
        if (request.method == 'GET' &&
            request.url.path == '/rest/v1/wali_links' &&
            request.url.queryParameters['wali_id'] ==
                'eq.${ZyraAccountState.userId}' &&
            request.url.queryParameters['status'] == 'eq.active') {
          return http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        unexpected.add('${request.method} ${request.url.path}');
        throw StateError('Unexpected synthetic Settings transport.');
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
    entitlementRequests = 0;
    held = null;
    unexpected.clear();
    await _session(_a);
  });
  tearDown(() {
    expect(unexpected, isEmpty);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  Finder value(String label) {
    final membership = find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.text('Membership'),
        )
        .first;
    return find.descendant(
      of: find.ancestor(of: membership, matching: find.byType(Row)).first,
      matching: find.text(label),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<void> profile(WidgetTester tester) async {
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
    expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
    expect(ZyraDeveloperAccess.isMainAppFounderPreview, isFalse);
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Settings'), 200);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  }

  Future<void> replaceOwner(WidgetTester tester, bool returnToA) async {
    final generation = ZyraAccountState.generation;
    await tester.runAsync(() async {
      await _session(_b).timeout(const Duration(seconds: 5));
      if (returnToA) {
        await _session(_a).timeout(const Duration(seconds: 5));
      }
    });
    await tester.pump();
    expect(ZyraAccountState.generation, greaterThan(generation));
  }

  testWidgets(
    'pending Profile→Settings remains Checking rather than inactive',
    (tester) async {
      final release = Completer<void>();
      held = release.future;
      try {
        await profile(tester);
        await openSettings(tester);
        expect(value('Checking…'), findsWidgets);
        expect(value('No active membership'), findsNothing);
        expect(entitlementRequests, 1);
      } finally {
        release.complete();
        await flush(tester);
      }
    },
  );

  for (final malformed in [false, true]) {
    testWidgets(
      '${malformed ? 'malformed' : '503'} Profile→Settings remains Unavailable',
      (tester) async {
        status = malformed ? 200 : 503;
        answer = null;
        await profile(tester);
        await flush(tester);
        await openSettings(tester);
        expect(value('Unavailable'), findsWidgets);
        expect(value('No active membership'), findsNothing);
        expect(value('Guardian One'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final paid in [false, true]) {
    testWidgets(
      'confirmed ${paid ? 'paid' : 'false'} Profile→Settings retains canonical membership',
      (tester) async {
        answer = paid;
        await profile(tester);
        await flush(tester);
        await openSettings(tester);
        expect(
          value(paid ? 'Guardian One' : 'No active membership'),
          findsWidgets,
        );
        expect(entitlementRequests, 1);
        await tester.scrollUntilVisible(find.text('MEMBERSHIP'), 200);
        expect(
          value(paid ? 'Guardian One' : 'No active membership'),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final succeeds in [false, true]) {
    testWidgets(
      'shared pending read resolves ${succeeds ? 'paid' : 'unavailable'} while Settings stays open',
      (tester) async {
        final release = Completer<void>();
        held = release.future;
        status = succeeds ? 200 : 503;
        try {
          await profile(tester);
          await openSettings(tester);
          expect(entitlementRequests, 1);
        } finally {
          release.complete();
        }
        await flush(tester);
        expect(value(succeeds ? 'Guardian One' : 'Unavailable'), findsWidgets);
        expect(value('No active membership'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final initialPaid in [false, true]) {
    testWidgets(
      'same-owner confirmed ${initialPaid ? 'loss' : 'gain'} updates mounted Settings',
      (tester) async {
        answer = initialPaid;
        await profile(tester);
        await flush(tester);
        await openSettings(tester);
        answer = !initialPaid;
        expect(
          (await ZyraEntitlementService.resolveGuardianPaidAccess())
              .valueOrNull,
          !initialPaid,
        );
        await tester.pump();
        expect(
          value(initialPaid ? 'No active membership' : 'Guardian One'),
          findsWidgets,
        );
        expect(
          value(initialPaid ? 'Guardian One' : 'No active membership'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final returnToA in [false, true]) {
    testWidgets(
      'mounted Settings withdraws paid display after ${returnToA ? 'A-B-A' : 'A-B'}',
      (tester) async {
        await profile(tester);
        await flush(tester);
        await openSettings(tester);
        expect(value('Guardian One'), findsWidgets);
        await replaceOwner(tester, returnToA);
        expect(value('Unavailable'), findsWidgets);
        expect(value('Guardian One'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'late pending reply cannot restore Settings after ${returnToA ? 'A-B-A' : 'A-B'}',
      (tester) async {
        final release = Completer<void>();
        held = release.future;
        try {
          await profile(tester);
          await openSettings(tester);
          await replaceOwner(tester, returnToA);
        } finally {
          release.complete();
        }
        await flush(tester);
        expect(value('Unavailable'), findsWidgets);
        expect(value('Guardian One'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final returnToA in [false, true]) {
    testWidgets(
      'quiet retained Settings source withdraws after ${returnToA ? 'A-B-A' : 'A-B'}',
      (tester) async {
        final display = ValueNotifier<String>('Guardian One');
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: SettingsScreen(
                guardian: true,
                guardianMembershipDisplay: display,
                loadLinkedPeople: (_) async =>
                    const ZyraSourceResult.available(<WaliLinkedPerson>[]),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(value('Guardian One'), findsWidgets);
          await replaceOwner(tester, returnToA);
          expect(value('Unavailable'), findsWidgets);
          expect(value('Guardian One'), findsNothing);
          display.value = 'Checking…';
          await tester.pump();
          display.value = 'Guardian One';
          await tester.pump();
          expect(value('Unavailable'), findsWidgets);
          expect(value('Guardian One'), findsNothing);
          expect(entitlementRequests, 0);
          expect(AppState.instance.waliHasWaliOne, isFalse);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          display.dispose();
        }
      },
    );
  }

  testWidgets(
    'Settings source rebind withdraws and disposes its display subscription',
    (tester) async {
      final first = _ObservedDisplay('Unavailable');
      final second = _ObservedDisplay('Guardian One');
      Future<ZyraSourceResult<List<WaliLinkedPerson>>> loadLinkedPeople(
        bool asWali,
      ) async => const ZyraSourceResult.available(<WaliLinkedPerson>[]);
      final loadLinks = loadLinkedPeople;
      Future<void> mount(
        ValueNotifier<String> display, {
        Key key = const ValueKey('retained-settings'),
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              key: key,
              guardian: true,
              guardianMembershipDisplay: display,
              loadLinkedPeople: loadLinks,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      try {
        await mount(first);
        expect(value('Unavailable'), findsWidgets);
        expect(first.hasSubscriptions, isTrue);
        expect(second.hasSubscriptions, isFalse);
        final originalState = tester.state(find.byType(SettingsScreen));
        first.value = 'Checking…';
        await tester.pump();
        expect(value('Checking…'), findsWidgets);
        await mount(second);
        expect(tester.state(find.byType(SettingsScreen)), same(originalState));
        expect(value('Unavailable'), findsWidgets);
        expect(value('Guardian One'), findsNothing);
        expect(first.hasSubscriptions, isFalse);
        expect(second.hasSubscriptions, isTrue);
        first.value = 'Guardian One';
        await tester.pump();
        expect(value('Unavailable'), findsWidgets);
        expect(value('Guardian One'), findsNothing);
        expect(value('Checking…'), findsNothing);
        second.value = 'No active membership';
        await tester.pump();
        expect(value('Unavailable'), findsWidgets);
        expect(value('No active membership'), findsNothing);
        await mount(first);
        expect(tester.state(find.byType(SettingsScreen)), same(originalState));
        expect(value('Unavailable'), findsWidgets);
        expect(value('Guardian One'), findsNothing);
        expect(first.hasSubscriptions, isTrue);
        expect(second.hasSubscriptions, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(first.hasSubscriptions, isFalse);
        expect(second.hasSubscriptions, isFalse);

        second.value = 'Guardian One';
        await mount(second, key: const ValueKey('fresh-settings'));
        expect(
          tester.state(find.byType(SettingsScreen)),
          isNot(same(originalState)),
        );
        expect(value('Guardian One'), findsWidgets);
        expect(first.hasSubscriptions, isFalse);
        expect(second.hasSubscriptions, isTrue);
        first.value = 'Checking…';
        await tester.pump();
        expect(value('Guardian One'), findsWidgets);
        expect(value('Checking…'), findsNothing);
        second.value = 'No active membership';
        await tester.pump();
        expect(value('No active membership'), findsWidgets);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(first.hasSubscriptions, isFalse);
        expect(second.hasSubscriptions, isFalse);
        first.value = 'Guardian One';
        second.value = 'Unavailable';
        await replaceOwner(tester, false);
        expect(entitlementRequests, 0);
        expect(AppState.instance.waliHasWaliOne, isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        first.dispose();
        second.dispose();
      }
    },
  );

  testWidgets(
    'held Profile reply is harmless after Settings and Profile dispose',
    (tester) async {
      final release = Completer<void>();
      held = release.future;
      try {
        await profile(tester);
        await openSettings(tester);
        expect(value('Checking…'), findsWidgets);
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        release.complete();
        await flush(tester);
      }
      expect(entitlementRequests, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
