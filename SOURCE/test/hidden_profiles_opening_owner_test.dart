// OA304: a rendered Hidden Profiles action belongs to its opening principal.
// Synthetic SDK sessions, injected data/ACKs and intercepted HTTP only.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/settings/hidden_profiles_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_hidden_profile_store.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000004801';
const _b = '00000000-0000-4000-8000-000000004802';
const _target = '00000000-0000-4000-8000-000000004803';
const _cachePrefix = 'zyra.hidden_profiles.v1.';

Map<String, Object?> _record(String firstName) => {
  'id': _target,
  'first_name': firstName,
  'surname_line': 'Khan',
  'age': 28,
  'city': 'Manchester',
  'gender': 'female',
  'is_demo': false,
};

Map<String, dynamic> _sessionJson(
  String id, {
  String sessionMarker = 'opening',
  String tokenMarker = 'opening',
}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800, 'session_id': sessionMarker, 'jti': tokenMarker})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-refresh',
    'user': {
      'id': id,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-18T00:00:00Z',
    },
  };
}

Future<void> _session(
  String id, {
  bool synchronize = true,
  String sessionMarker = 'opening',
}) async {
  await supabase.auth.setInitialSession(
    jsonEncode(_sessionJson(id, sessionMarker: sessionMarker)),
  );
  if (synchronize) await ZyraAccountState.synchronize(id);
}

void _emit(AuthChangeEvent event, Session session) {
  // Synthetic queued SDK notification only: no network, session mutation,
  // authorization grant or new account-generation publication.
  // ignore: invalid_use_of_internal_member
  supabase.auth.notifyAllSubscribers(event, session: session, broadcast: false);
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

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

VoidCallback _rowAction(WidgetTester tester) => tester
    .widget<TextButton>(find.widgetWithText(TextButton, 'Unhide'))
    .onPressed!;

VoidCallback _confirmationAction(WidgetTester tester) => tester
    .widget<FilledButton>(find.widgetWithText(FilledButton, 'Unhide'))
    .onPressed!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  final pending = <Completer<bool>>[];
  var unhideCalls = 0;
  late Future<bool> Function(String) unhide;
  late String otherCacheBefore;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        throw StateError('No HTTP belongs to this injected page test.');
      }),
    );
  });

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    ZyraText.useTestFontStubs = true;
    final otherCache = jsonEncode([_record('Other owner')]);
    otherCacheBefore = otherCache;
    SharedPreferences.setMockInitialValues({
      '$_cachePrefix$_a': jsonEncode([_record('Amira')]),
      '$_cachePrefix$_b': otherCache,
      'hidden-opening-owner-sentinel': 'keep',
    });
    await ZyraLocalPrefs.init();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    requests.clear();
    unhideCalls = 0;
    unhide = (_) async => true;
  });

  tearDown(() {
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    debugDefaultTargetPlatformOverride = null;
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<GlobalKey<NavigatorState>> mount(WidgetTester tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: HiddenProfilesScreen(
          loadServerIds: () async => const [_target],
          unhideServerProfile: (id) {
            unhideCalls++;
            expect(id, _target);
            return unhide(id);
          },
        ),
      ),
    );
    await _until(
      tester,
      () => find.text('Hidden profile').evaluate().isNotEmpty,
      'Opening owner hidden list',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return navigator;
  }

  void ownerWidgetTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await _operation(tester, () => _session(_a), 'Synthetic owner A');
        await body(tester);
        expect(requests, isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('$_cachePrefix$_b'), otherCacheBefore);
        expect(prefs.getString('hidden-opening-owner-sentinel'), 'keep');
        expect(tester.takeException(), isNull);
      } finally {
        try {
          for (final ack in pending) {
            if (!ack.isCompleted) ack.complete(false);
          }
          pending.clear();
          await tester.pumpWidget(const SizedBox.shrink());
          await _flush(tester);
          await _operation(
            tester,
            () => ZyraAccountState.synchronize(null),
            'Account cleanup',
          );
          // Static serialization tails must not retain this discarded fake
          // clock. Rehome both queues from the real/root zone, then pump.
          var hiddenDone = false;
          var preferencesDone = false;
          Zone.root.run(() {
            ZyraHiddenProfileStore.forget(
              'opening-owner-drain',
            ).then<void>((_) => hiddenDone = true);
            ZyraLocalPrefs.bindAccount(_a);
            ZyraLocalPrefs.bindAccount(
              null,
            ).then<void>((_) => preferencesDone = true);
          });
          await _until(
            tester,
            () => hiddenDone && preferencesDone,
            'Static queue rehoming',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  ownerWidgetTest(
    'same opening owner confirms and completes real unhide flow',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('Unhide'));
      await tester.pumpAndSettle();
      expect(find.text('Unhide profile?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unhide'));
      await _until(
        tester,
        () => find.text('No hidden profiles').evaluate().isNotEmpty,
        'Confirmed owner A unhide',
      );
      expect(unhideCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('$_cachePrefix$_a'), isNull);
    },
  );

  for (final change in ['replacement', 'ABA', 'same-ID-generation']) {
    ownerWidgetTest('rendered Unhide refuses $change opening lifetime', (
      tester,
    ) async {
      await mount(tester);
      final action = _rowAction(tester);
      if (change == 'same-ID-generation') {
        ZyraAccountState.resetForTesting();
      } else {
        await _operation(tester, () => _session(_b), 'Replacement owner');
        if (change == 'ABA') {
          await _operation(tester, () => _session(_a), 'Owner A returns');
        }
      }
      action();
      await _flush(tester);
      expect(find.text('Unhide profile?'), findsNothing);
      expect(find.text('Hidden profile'), findsNothing);
      expect(find.text('Hidden profiles unavailable'), findsOneWidget);
      expect(unhideCalls, 0);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Try again'),
            )
            .onPressed,
        isNull,
      );
    });
  }

  ownerWidgetTest(
    'SDK-only principal change revokes without a generation change',
    (tester) async {
      await mount(tester);
      final action = _rowAction(tester);
      final generation = ZyraAccountState.generation;
      await _operation(
        tester,
        () => _session(_b, synchronize: false),
        'SDK-only principal B',
      );
      expect(ZyraAccountState.generation, generation);
      action();
      await _flush(tester);
      expect(find.text('Unhide profile?'), findsNothing);
      expect(find.text('Hidden profile'), findsNothing);
      expect(unhideCalls, 0);
    },
  );

  ownerWidgetTest(
    'queued SDK-only ABA permanently revokes the opening action',
    (tester) async {
      await mount(tester);
      final action = _rowAction(tester);
      final generation = ZyraAccountState.generation;
      await _operation(tester, () async {
        // Both SDK writes run before either asynchronous notification is read.
        // The getter is already A when B's queued AuthState reaches the page.
        final toB = _session(_b, synchronize: false);
        final backToA = _session(_a, synchronize: false);
        expect(supabase.auth.currentUser?.id, _a);
        await Future.wait([toB, backToA]);
      }, 'Queued SDK-only A to B to A');
      expect(ZyraAccountState.generation, generation);
      expect(supabase.auth.currentUser?.id, _a);
      action();
      await _flush(tester);
      expect(find.text('Unhide profile?'), findsNothing);
      expect(find.text('Hidden profile'), findsNothing);
      expect(find.text('Hidden profiles unavailable'), findsOneWidget);
      expect(unhideCalls, 0);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Try again'),
            )
            .onPressed,
        isNull,
      );
    },
  );

  ownerWidgetTest(
    'same-ID SDK session replacement revokes without generation change',
    (tester) async {
      await mount(tester);
      final action = _rowAction(tester);
      final generation = ZyraAccountState.generation;
      await _operation(
        tester,
        () => _session(_a, synchronize: false, sessionMarker: 'replacement'),
        'New SDK session for owner A',
      );
      expect(ZyraAccountState.generation, generation);
      expect(supabase.auth.currentUser?.id, _a);
      // A later matching snapshot cannot restore the revoked opening lifetime.
      await _operation(
        tester,
        () => _session(_a, synchronize: false),
        'Original SDK snapshot returns',
      );
      action();
      await _flush(tester);
      expect(find.text('Unhide profile?'), findsNothing);
      expect(find.text('Hidden profile'), findsNothing);
      expect(find.text('Hidden profiles unavailable'), findsOneWidget);
      expect(unhideCalls, 0);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Try again'),
            )
            .onPressed,
        isNull,
      );
    },
  );

  ownerWidgetTest(
    'matching snapshot and same-owner token refresh retain unhide',
    (tester) async {
      await mount(tester);
      final generation = ZyraAccountState.generation;
      final opening = supabase.auth.currentSession!;
      final refreshed = Session.fromJson(
        _sessionJson(_a, tokenMarker: 'refreshed-token'),
      )!;
      expect(refreshed.accessToken, isNot(opening.accessToken));
      _emit(AuthChangeEvent.initialSession, opening);
      _emit(AuthChangeEvent.tokenRefreshed, refreshed);
      _emit(AuthChangeEvent.userUpdated, refreshed);
      await _flush(tester);
      expect(ZyraAccountState.generation, generation);
      expect(find.text('Hidden profile'), findsOneWidget);
      await tester.tap(find.text('Unhide'));
      await tester.pumpAndSettle();
      expect(find.text('Unhide profile?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unhide'));
      await _until(
        tester,
        () => find.text('No hidden profiles').evaluate().isNotEmpty,
        'Healthy refreshed owner A unhide',
      );
      expect(unhideCalls, 1);
    },
  );

  ownerWidgetTest(
    'old open confirmation cannot dispatch into replacement owner',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('Unhide'));
      await tester.pumpAndSettle();
      final confirm = _confirmationAction(tester);
      await _operation(
        tester,
        () => _session(_b),
        'Owner replacement in dialog',
      );
      confirm();
      await tester.pumpAndSettle();
      expect(unhideCalls, 0);
      expect(find.text('Hidden profiles unavailable'), findsOneWidget);
      expect(find.text('Hidden profile'), findsNothing);
    },
  );

  ownerWidgetTest('covered row action is inert and still works after return', (
    tester,
  ) async {
    final navigator = await mount(tester);
    final action = _rowAction(tester);
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
      ),
    );
    await tester.pumpAndSettle();
    action();
    await tester.pumpAndSettle();
    expect(find.text('Unhide profile?'), findsNothing);
    expect(unhideCalls, 0);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unhide'));
    await tester.pumpAndSettle();
    expect(find.text('Unhide profile?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(unhideCalls, 0);
    expect(find.text('Hidden profile'), findsOneWidget);
  });

  for (final cover in [false, true]) {
    ownerWidgetTest(
      'late unhide ACK after ${cover ? 'route cover' : 'owner replacement'} cannot publish success',
      (tester) async {
        final ack = Completer<bool>();
        pending.add(ack);
        unhide = (_) => ack.future;
        final navigator = await mount(tester);
        await tester.tap(find.text('Unhide'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Unhide'));
        await _until(tester, () => unhideCalls == 1, 'Owned unhide dispatch');
        if (cover) {
          unawaited(
            navigator.currentState!.push<void>(
              MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Cover')),
              ),
            ),
          );
          await tester.pumpAndSettle();
        } else {
          await _operation(
            tester,
            () => _session(_b),
            'Owner changes in flight',
          );
        }
        ack.complete(true);
        await _flush(tester);
        if (cover) {
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
        }
        expect(find.text('No hidden profiles'), findsNothing);
        expect(find.text('Hidden profiles unavailable'), findsOneWidget);
        expect(find.text('Amira can appear in Browse again.'), findsNothing);
        expect(unhideCalls, 1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('$_cachePrefix$_a'), isNull);
      },
    );
  }
}
