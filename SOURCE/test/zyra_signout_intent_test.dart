// HAPTICS/BRIEFS/HAPTICS_BRIEF_2026-10-30.md §3; no visual master required.
// Logout may clear only the account lifetime which owned its initiating
// control. Native Google cleanup and all Auth transport are synthetic here.
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
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_account_exit.dart';

const _a = '00000000-0000-4000-8000-000000001314';
const _b = '00000000-0000-4000-8000-000000001315';
var _sessionRevision = 0;

class _FailingDraftStore implements ZyraSignupDraftStore {
  int deletes = 0;
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {
    deletes++;
    throw StateError('Synthetic protected erasure refused');
  }
}

_FailingDraftStore _installFailingStore() {
  final store = _FailingDraftStore();
  ZyraInitialSignupDraftService.setRepositoryForTesting(
    ZyraSignupDraftRepository(
      store: store,
      backend: 'https://test.invalid',
      currentUserId: () => ZyraAuth.currentUser?.id,
      isPreview: () => false,
    ),
  );
  return store;
}

Map<String, Object?> _sessionData(String id) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'session_id': ++_sessionRevision, 'exp': 4102444800})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-refresh',
    'user': {
      'id': id,
      'app_metadata': {
        'provider': 'google',
        'providers': ['google'],
      },
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-13T00:00:00Z',
    },
  };
}

Future<void> _session(String id) async {
  await supabase.auth.setInitialSession(jsonEncode(_sessionData(id)));
  await ZyraAccountState.synchronize(id);
}

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 15; frame++) {
    await tester.pump(const Duration(milliseconds: 30));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _accountTransition(
  WidgetTester tester,
  Future<void> Function() transition,
) async {
  var completed = false;
  Object? failure;
  StackTrace? failureStack;
  transition().then(
    (_) => completed = true,
    onError: (Object error, StackTrace stack) {
      failure = error;
      failureStack = stack;
      completed = true;
    },
  );
  for (var frame = 0; frame < 60 && !completed; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(completed, isTrue, reason: 'Synthetic account transition settled');
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
}

Future<void> _rehomePreferences(WidgetTester tester) async {
  var settled = false;
  Zone.root.run(() {
    ZyraLocalPrefs.bindAccount(_a);
    ZyraLocalPrefs.bindAccount(null).then((_) => settled = true);
  });
  for (var frame = 0; frame < 60 && !settled; frame++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(
    settled,
    isTrue,
    reason: 'Preference queue re-homed before fake-zone exit',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <String>[];
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request.url.path);
        if (request.url.path == '/auth/v1/logout') {
          return http.Response('', 204, request: request);
        }
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode(_sessionData(_a)),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '[]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraAuth.setGoogleSignOutForTesting(() async {});
  });
  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraAuth.setGoogleSignOutForTesting(null);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    debugDefaultTargetPlatformOverride = null;
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> prepareService() async {
    await _session(_a).timeout(const Duration(seconds: 5));
    requests.clear();
  }

  test('default logout cannot log out B during native cleanup for A', () async {
    await prepareService();
    ZyraAuth.setGoogleSignOutForTesting(() => _session(_b));
    await expectLater(ZyraAuth.signOut(), throwsStateError);
    expect(ZyraAuth.currentUser?.id, _b);
    expect(requests, isNot(contains('/auth/v1/logout')));
    expect(ZyraAccountState.isSigningOut, isFalse);
    expect(ZyraAccountState.userId, _b);
  });

  test('default logout cannot inherit a fresh same-ID sign-in', () async {
    await prepareService();
    ZyraAuth.setGoogleSignOutForTesting(() => _session(_a));
    await expectLater(ZyraAuth.signOut(), throwsStateError);
    expect(ZyraAuth.currentUser?.id, _a);
    expect(requests, isNot(contains('/auth/v1/logout')));
    expect(ZyraAccountState.isSigningOut, isFalse);
    expect(ZyraAccountState.userId, _a);
  });

  test(
    'default logout latches A to B to A replacement during native cleanup',
    () async {
      await prepareService();
      ZyraAuth.setGoogleSignOutForTesting(() async {
        await _session(_b);
        await _session(_a);
      });
      await expectLater(ZyraAuth.signOut(), throwsStateError);
      expect(ZyraAuth.currentUser?.id, _a);
      expect(requests, isNot(contains('/auth/v1/logout')));
    },
  );

  test('ordinary logout still clears its own session', () async {
    await prepareService();
    await ZyraAuth.signOut();
    expect(ZyraAuth.currentUser, isNull);
    expect(requests.where((path) => path == '/auth/v1/logout'), hasLength(1));
  });

  test(
    'failed protected erasure keeps the same SDK owner neutral and permits explicit retry',
    () async {
      await prepareService();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final store = _installFailingStore();
      final generation = ZyraAccountState.generation;
      try {
        for (var attempt = 1; attempt <= 2; attempt++) {
          await expectLater(ZyraAuth.signOut(), throwsStateError);
          expect(store.deletes, attempt);
          expect(ZyraAuth.currentUser?.id, _a);
          expect(ZyraAccountState.userId, isNull);
          expect(ZyraAccountState.generation, generation + attempt);
          expect(ZyraAccountState.isSigningOut, isFalse);
          expect(requests, isNot(contains('/auth/v1/logout')));
        }
      } finally {
        // Failed secure erasure does not make production UI await cache work.
        // Drain this fixture's owned work before its synthetic cleaner is unset.
        await ZyraAccountState.synchronize(
          null,
        ).timeout(const Duration(seconds: 5));
      }
    },
  );

  test(
    'healthy same-owner token refresh during native cleanup still permits logout',
    () async {
      await prepareService();
      final originalToken = supabase.auth.currentSession!.accessToken;
      var refreshed = false;
      final subscription = ZyraAuth.authStateChanges.listen((state) {
        if (state.event == AuthChangeEvent.tokenRefreshed) refreshed = true;
      });
      addTearDown(subscription.cancel);
      ZyraAuth.setGoogleSignOutForTesting(() async {
        await supabase.auth.refreshSession();
        expect(supabase.auth.currentSession!.accessToken, isNot(originalToken));
      });
      await ZyraAuth.signOut();
      expect(refreshed, isTrue);
      expect(ZyraAuth.currentUser, isNull);
      expect(requests.where((path) => path == '/auth/v1/token'), hasLength(1));
      expect(requests.where((path) => path == '/auth/v1/logout'), hasLength(1));
    },
  );

  test(
    'native Google cleanup failure does not block own-session logout',
    () async {
      await prepareService();
      ZyraAuth.setGoogleSignOutForTesting(() async {
        throw StateError('Synthetic native chooser failure');
      });
      await ZyraAuth.signOut();
      expect(ZyraAuth.currentUser, isNull);
      expect(requests.where((path) => path == '/auth/v1/logout'), hasLength(1));
    },
  );

  // Queue 22 standard haptics: the public button is a VoidCallback wrapper.
  // Drive that callback and await observable completion; it returns no Future.
  // Authority: PRODUCT/APPROVED/HAPTICS (member tap feedback), unchanged exit rules.
  Future<void> settleExit(WidgetTester tester) async {
    await tester.pump();
    for (var frame = 0; frame < 80; frame++) {
      await _flush(tester);
      if (find.text('Signing out…').evaluate().isEmpty) return;
    }
    fail('The public exit control did not settle.');
  }

  void startExit(WidgetTester tester) {
    tester
        .widget<TextButton>(
          find.byKey(const ValueKey('onboarding_account_exit')),
        )
        .onPressed!();
  }

  void exitTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      try {
        await _accountTransition(tester, () => _session(_a));
        requests.clear();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(
              body: ZyraOnboardingAccountExit(expectedUserId: _a),
            ),
          ),
        );
        await body(tester);
      } finally {
        try {
          // Cancel any still-open confirmation normally so its own awaiting
          // callback finishes. Disposing a Navigator need not complete popped.
          for (
            var routes = 0;
            routes < 5 && (navigator.currentState?.canPop() ?? false);
            routes++
          ) {
            navigator.currentState!.pop(false);
            await _flush(tester);
          }
          await settleExit(tester);
          await tester.pumpWidget(const SizedBox.shrink());
          await _flush(tester);
          var preferencesDrained = false;
          ZyraLocalPrefs.bindAccount(
            null,
          ).then((_) => preferencesDrained = true);
          var accountDrained = false;
          ZyraAccountState.synchronize(null).then((_) => accountDrained = true);
          for (
            var frame = 0;
            frame < 30 && (!preferencesDrained || !accountDrained);
            frame++
          ) {
            await tester.pump();
            await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          }
          expect(preferencesDrained, isTrue);
          expect(accountDrained, isTrue);
          await _rehomePreferences(tester);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  exitTest(
    'onboarding exit cannot reuse a previous same-ID lifetime confirmation',
    (tester) async {
      startExit(tester);
      await tester.pumpAndSettle();
      await _accountTransition(tester, () async {
        await ZyraAccountState.synchronize(null);
        await _session(_a);
      });
      await tester.tap(
        find.byKey(const ValueKey('onboarding_account_exit_confirm')),
      );
      await _flush(tester);
      expect(ZyraAuth.currentUser?.id, _a);
      expect(requests, isNot(contains('/auth/v1/logout')));
      expect(tester.takeException(), isNull);
    },
  );

  exitTest('onboarding exit permits only one confirmation flight', (
    tester,
  ) async {
    final dynamic action = tester
        .widget<TextButton>(
          find.byKey(const ValueKey('onboarding_account_exit')),
        )
        .onPressed!;
    action();
    action();
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton, skipOffstage: false), findsOneWidget);
  });

  Future<void> failOwnedExit(WidgetTester tester) async {
    startExit(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('onboarding_account_exit_confirm')),
    );
    await settleExit(tester);
    await _flush(tester);
  }

  exitTest(
    'owned protected-erasure failure can be retried twice from the same exit control',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final store = _installFailingStore();
      for (var attempt = 1; attempt <= 2; attempt++) {
        await failOwnedExit(tester);
        expect(store.deletes, attempt);
        expect(
          find.text("We couldn't sign you out. Please try again."),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextButton>(
                find.byKey(const ValueKey('onboarding_account_exit')),
              )
              .onPressed,
          isNotNull,
        );
        expect(ZyraAuth.currentUser?.id, _a);
        expect(requests, isNot(contains('/auth/v1/logout')));
      }
    },
  );

  for (final replacement in ['B', 'fresh A', 'A to B to A']) {
    exitTest(
      'failed exit retry is terminally denied after raw SDK $replacement replacement',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final store = _installFailingStore();
        await failOwnedExit(tester);
        final dynamic retained = tester
            .widget<TextButton>(
              find.byKey(const ValueKey('onboarding_account_exit')),
            )
            .onPressed!;
        await _accountTransition(tester, () async {
          if (replacement != 'fresh A') {
            await supabase.auth.setInitialSession(jsonEncode(_sessionData(_b)));
          }
          if (replacement != 'B') {
            await supabase.auth.setInitialSession(jsonEncode(_sessionData(_a)));
          }
        });
        retained();
        await _flush(tester);
        expect(store.deletes, 1);
        expect(find.byType(FilledButton), findsNothing);
        expect(
          tester
              .widget<TextButton>(
                find.byKey(const ValueKey('onboarding_account_exit')),
              )
              .onPressed,
          isNull,
        );
        expect(requests, isNot(contains('/auth/v1/logout')));
        expect(ZyraAuth.currentUser?.id, replacement == 'B' ? _b : _a);
      },
    );
  }

  exitTest(
    'raw SDK A to B to A cannot inherit an already open exit confirmation',
    (tester) async {
      startExit(tester);
      await tester.pumpAndSettle();
      await _accountTransition(tester, () async {
        await supabase.auth.setInitialSession(jsonEncode(_sessionData(_b)));
        await supabase.auth.setInitialSession(jsonEncode(_sessionData(_a)));
      });
      await tester.tap(
        find.byKey(const ValueKey('onboarding_account_exit_confirm')),
      );
      await settleExit(tester);
      expect(requests, isNot(contains('/auth/v1/logout')));
      expect(ZyraAuth.currentUser?.id, _a);
    },
  );

  exitTest(
    'owned exit allows healthy refresh and its own signed-out event before Welcome',
    (tester) async {
      ZyraAuth.setGoogleSignOutForTesting(() async {
        await supabase.auth.refreshSession();
      });
      startExit(tester);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('onboarding_account_exit_confirm')),
      );
      await settleExit(tester);
      await _flush(tester);
      expect(ZyraAuth.currentUser, isNull);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(requests.where((path) => path == '/auth/v1/logout'), hasLength(1));
    },
  );

  for (final replacement in ['B', 'fresh A', 'A to B to A']) {
    exitTest(
      'delayed native cleanup preserves terminal error after raw SDK $replacement replacement',
      (tester) async {
        final release = Completer<void>();
        ZyraAuth.setGoogleSignOutForTesting(() => release.future);
        try {
          startExit(tester);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('onboarding_account_exit_confirm')),
          );
          await tester.pump();
          await _accountTransition(tester, () async {
            if (replacement != 'fresh A') {
              await supabase.auth.setInitialSession(
                jsonEncode(_sessionData(_b)),
              );
            }
            if (replacement != 'B') {
              await supabase.auth.setInitialSession(
                jsonEncode(_sessionData(_a)),
              );
            }
          });
          release.complete();
          await settleExit(tester);
          await _flush(tester);
          expect(
            find.text('Your account changed. Close and reopen ZYRA.'),
            findsOneWidget,
          );
          expect(
            find.text("We couldn't sign you out. Please try again."),
            findsNothing,
          );
          expect(
            tester
                .widget<TextButton>(
                  find.byKey(const ValueKey('onboarding_account_exit')),
                )
                .onPressed,
            isNull,
          );
          expect(ZyraAuth.currentUser?.id, replacement == 'B' ? _b : _a);
          expect(requests, isNot(contains('/auth/v1/logout')));
        } finally {
          if (!release.isCompleted) release.complete();
        }
      },
    );
  }
}
