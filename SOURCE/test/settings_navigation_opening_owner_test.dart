// OA-ZYRA-304/305: Settings rows belong to the opening member and route,
// including injected preference sources. Synthetic SDK events and local
// confirmed reads only; no provider, device-security, paid grant or backend I/O.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/settings/notification_settings_screen.dart';
import 'package:zyra/screens/settings/settings_screen.dart';
import 'package:zyra/screens/settings/sign_in_security_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_notification_prefs_service.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000003411';
const _b = '00000000-0000-4000-8000-000000003412';
const _settingsKey = ValueKey('settings-opening-navigation-owner');
const _coverKey = ValueKey('unrelated-settings-cover');

Map<String, Object?> _sessionJson(String id, {String marker = 'opening'}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800, 'session_id': 'synthetic-opening', 'jti': marker})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-in-memory-only',
    'user': {
      'id': id,
      'app_metadata': <String, Object?>{'provider': 'google'},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-18T00:00:00Z',
    },
  };
}

Future<void> _session(String id, {bool synchronize = true}) async {
  await supabase.auth.setInitialSession(jsonEncode(_sessionJson(id)));
  if (synchronize) await ZyraAccountState.synchronize(id);
}

void _emit(AuthChangeEvent event, Session session) {
  // Synthetic SDK notification only; no identity, entitlement or real session
  // is created, refreshed, linked or authorized by this test event.
  // ignore: invalid_use_of_internal_member
  supabase.auth.notifyAllSubscribers(event, session: session, broadcast: false);
}

class _Sources {
  int links = 0;
  int preferenceReads = 0;
  int preferenceWrites = 0;
  late final Future<ZyraSourceResult<List<WaliLinkedPerson>>> Function(bool)
  loadLinks = _loadLinks;
  late final Future<Map<ZyraNotifyCategory, bool>?> Function() loadPreferences =
      _loadPreferences;
  late final Future<bool> Function(ZyraNotifyCategory, bool) savePreference =
      _savePreference;

  Future<ZyraSourceResult<List<WaliLinkedPerson>>> _loadLinks(bool _) async {
    links++;
    return const ZyraSourceResult.available(<WaliLinkedPerson>[]);
  }

  Future<Map<ZyraNotifyCategory, bool>?> _loadPreferences() async {
    preferenceReads++;
    return {for (final category in ZyraNotifyCategory.values) category: false};
  }

  Future<bool> _savePreference(ZyraNotifyCategory _, bool _) async {
    preferenceWrites++;
    return true;
  }
}

const _commonRows = [
  'Sign-in & security',
  'App lock',
  'Advanced',
  'Pause My Profile',
  'Notifications & emails',
  'Membership',
  'Help & support',
  'Send feedback',
  'Privacy & data',
];

List<String> _rows(bool guardian) => [
  ..._commonRows,
  if (guardian) 'Guardian privacy' else ...['Hidden Profiles'],
];

VoidCallback _row(WidgetTester tester, String label) => tester
    .widget<InkWell>(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
    )
    .onTap!;

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _settle(WidgetTester tester) async {
  await _flush(tester);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}

Future<void> _until(
  WidgetTester tester,
  bool Function() completed,
  String description,
) async {
  for (var frame = 0; frame < 100 && !completed(); frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(completed(), isTrue, reason: '$description did not settle.');
}

Future<void> _operation(
  WidgetTester tester,
  Future<void> Function() action,
  String description,
) async {
  var completed = false;
  Object? failure;
  StackTrace? failureStack;
  action().then<void>(
    (_) => completed = true,
    onError: (Object error, StackTrace stack) {
      failure = error;
      failureStack = stack;
      completed = true;
    },
  );
  await _until(tester, () => completed, description);
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final unexpected = <String>[];
  late GlobalKey<NavigatorState> navigation;
  late _Sources sources;
  late ValueNotifier<String> display;

  SettingsScreen settings({
    bool guardian = false,
    _Sources? replacement,
    ValueNotifier<String>? membership,
  }) {
    final bound = replacement ?? sources;
    return SettingsScreen(
      key: _settingsKey,
      guardian: guardian,
      guardianMembershipDisplay: membership ?? display,
      loadLinkedPeople: bound.loadLinks,
      loadNotificationPreferences: bound.loadPreferences,
      saveNotificationPreference: bound.savePreference,
    );
  }

  Future<void> mount(WidgetTester tester, {bool guardian = false}) async {
    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _flush(tester);
      await _operation(
        tester,
        () => ZyraAccountState.synchronize(null),
        'Synthetic account cleanup',
      );
      // Keep a completed serialization tail out of the outgoing FakeAsync
      // zone so the next test's real setUp cannot wait on a discarded clock.
      var preferencesDone = false;
      Zone.root.run(() {
        ZyraLocalPrefs.bindAccount(_a);
        ZyraLocalPrefs.bindAccount(
          null,
        ).then<void>((_) => preferencesDone = true);
      });
      await _until(tester, () => preferencesDone, 'Preference cleanup');
    });
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigation,
        home: settings(guardian: guardian),
      ),
    );
    await _settle(tester);
    expect(sources.links, 1);
    expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
    expect(ZyraDeveloperAccess.isMainAppFounderPreview, isFalse);
  }

  List<VoidCallback> retain(WidgetTester tester, bool guardian) => [
    for (final label in _rows(guardian)) _row(tester, label),
  ];

  void denyAssertions(WidgetTester tester) {
    expect(navigation.currentState!.canPop(), isFalse);
    expect(sources.preferenceReads, 0);
    expect(sources.preferenceWrites, 0);
    expect(find.byType(NotificationSettingsScreen), findsNothing);
    expect(tester.takeException(), isNull);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    PackageInfo.setMockInitialValues(
      appName: 'Synthetic ZYRA',
      packageName: 'invalid.zyra.settings.test',
      version: '0.0.0',
      buildNumber: '0',
      buildSignature: '',
    );
    await Supabase.initialize(
      url: 'https://settings-navigation-evidence.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        unexpected.add('${request.method} ${request.url}');
        throw StateError('Settings navigation must not use HTTP.');
      }),
    );
  });

  setUp(() async {
    navigation = GlobalKey<NavigatorState>();
    sources = _Sources();
    display = ValueNotifier('No active membership');
    unexpected.clear();
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraProductTelemetry.instance.resetForTest();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await _session(_a).timeout(const Duration(seconds: 4));
  });

  tearDown(() {
    expect(unexpected, isEmpty);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    display.dispose();
  });
  tearDownAll(() => Supabase.instance.dispose());

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    for (final returnToA in [false, true]) {
      testWidgets(
        '$role retained rows deny account ${returnToA ? 'ABA' : 'replacement'}',
        (tester) async {
          await mount(tester, guardian: guardian);
          final actions = retain(tester, guardian);
          await tester.runAsync(() async {
            await _session(_b).timeout(const Duration(seconds: 4));
            if (returnToA) {
              await _session(_a).timeout(const Duration(seconds: 4));
            }
          });
          await _flush(tester);
          for (final action in actions) {
            action();
          }
          await _settle(tester);
          denyAssertions(tester);
        },
        timeout: const Timeout(Duration(seconds: 25)),
      );
    }

    testWidgets(
      '$role covered rows do nothing and remain usable after return',
      (tester) async {
        await mount(tester, guardian: guardian);
        final actions = retain(tester, guardian);
        final notifications = _row(tester, 'Notifications & emails');
        unawaited(
          navigation.currentState!.push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(key: _coverKey, body: Text('Unrelated')),
            ),
          ),
        );
        await _settle(tester);
        for (final action in actions) {
          action();
        }
        await _settle(tester);
        expect(find.byKey(_coverKey), findsOneWidget);
        expect(sources.preferenceReads, 0);
        expect(sources.preferenceWrites, 0);
        navigation.currentState!.pop();
        await _settle(tester);
        notifications();
        await _settle(tester);
        expect(find.byType(NotificationSettingsScreen), findsOneWidget);
        expect(sources.preferenceReads, 1);
        expect(sources.preferenceWrites, 0);
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );

    testWidgets(
      '$role disposed row callbacks never look up a deactivated ancestor',
      (tester) async {
        await mount(tester, guardian: guardian);
        final actions = retain(tester, guardian);
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester);
        for (final action in actions) {
          action();
        }
        await _flush(tester);
        expect(sources.preferenceReads, 0);
        expect(sources.preferenceWrites, 0);
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );
  }

  testWidgets(
    'SDK-only ABA cannot reuse old Settings without a generation change',
    (tester) async {
      await mount(tester);
      final actions = retain(tester, false);
      final generation = ZyraAccountState.generation;
      await tester.runAsync(() async {
        await _session(
          _b,
          synchronize: false,
        ).timeout(const Duration(seconds: 4));
        await _session(
          _a,
          synchronize: false,
        ).timeout(const Duration(seconds: 4));
      });
      await _flush(tester);
      expect(ZyraAccountState.generation, generation);
      for (final action in actions) {
        action();
      }
      await _settle(tester);
      denyAssertions(tester);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  for (final mode in ['role', 'sources', 'membership display']) {
    testWidgets(
      'same-key $mode replacement permanently denies retained rows',
      (tester) async {
        await mount(tester);
        final actions = retain(tester, false);
        final state = tester.state(find.byType(SettingsScreen));
        final replacement = _Sources();
        final replacementDisplay = ValueNotifier('Unavailable');
        addTearDown(replacementDisplay.dispose);
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigation,
            home: settings(
              guardian: mode == 'role',
              replacement: mode == 'sources' ? replacement : null,
              membership: mode == 'membership display'
                  ? replacementDisplay
                  : null,
            ),
          ),
        );
        await _settle(tester);
        expect(tester.state(find.byType(SettingsScreen)), same(state));
        // Even restoring the original constructor cannot resurrect its lifetime.
        await tester.pumpWidget(
          MaterialApp(navigatorKey: navigation, home: settings()),
        );
        await _settle(tester);
        for (final action in actions) {
          action();
        }
        await _settle(tester);
        denyAssertions(tester);
        expect(replacement.preferenceReads, 0);
        expect(replacement.preferenceWrites, 0);
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );
  }

  testWidgets(
    'preview latch ABA cannot make old ordinary rows active again',
    (tester) async {
      await mount(tester);
      final actions = retain(tester, false);
      ZyraInternalPreviewClient.beginPreview();
      ZyraInternalPreviewClient.finishSignOut();
      await _flush(tester);
      for (final action in actions) {
        action();
      }
      await _settle(tester);
      denyAssertions(tester);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'same-member token refresh and healthy rebuild preserve navigation',
    (tester) async {
      await mount(tester);
      final notifications = _row(tester, 'Notifications & emails');
      final refreshed = Session.fromJson(
        _sessionJson(_a, marker: 'refreshed'),
      )!;
      _emit(AuthChangeEvent.tokenRefreshed, refreshed);
      AppState.instance.setPlan(AppState.instance.plan);
      await _flush(tester);
      notifications();
      await _settle(tester);
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(sources.preferenceReads, 1);
      expect(sources.preferenceWrites, 0);
      navigation.currentState!.pop();
      await _settle(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'account change during a child never refreshes stale row authority',
    (tester) async {
      await mount(tester);
      final actions = retain(tester, false);
      _row(tester, 'Sign-in & security')();
      await _settle(tester);
      expect(find.byType(SignInSecurityScreen), findsOneWidget);
      await tester.runAsync(
        () => _session(_b).timeout(const Duration(seconds: 4)),
      );
      await _flush(tester);
      navigation.currentState!.pop();
      await _settle(tester);
      for (final action in actions) {
        action();
      }
      await _settle(tester);
      denyAssertions(tester);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  for (final replaceOwner in [false, true]) {
    testWidgets(
      'retained Settings Back respects cover and ${replaceOwner ? 'changed' : 'current'} owner',
      (tester) async {
        await mount(tester);
        unawaited(
          navigation.currentState!.push<void>(
            MaterialPageRoute(builder: (_) => settings()),
          ),
        );
        await _settle(tester);
        final back = tester
            .widget<BackButton>(find.byType(BackButton))
            .onPressed!;
        unawaited(
          navigation.currentState!.push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(key: _coverKey, body: Text('Unrelated')),
            ),
          ),
        );
        await _settle(tester);
        back();
        await _settle(tester);
        expect(find.byKey(_coverKey), findsOneWidget);
        if (replaceOwner) {
          await tester.runAsync(
            () => _session(_b).timeout(const Duration(seconds: 4)),
          );
          await _flush(tester);
        }
        navigation.currentState!.pop();
        await _settle(tester);
        back();
        await _settle(tester);
        expect(navigation.currentState!.canPop(), replaceOwner);
        expect(sources.preferenceReads, 0);
        expect(sources.preferenceWrites, 0);
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );
  }
}
