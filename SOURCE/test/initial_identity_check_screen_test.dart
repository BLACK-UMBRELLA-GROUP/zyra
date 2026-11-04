import 'support/queue44_signup_flow_driver.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/zyra_identity_verification.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_identity_verification_service.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';

const _userA = '00000000-0000-0000-0000-000000000001';
const _userB = '00000000-0000-0000-0000-000000000002';
final _requestPaths = <String>[];
Future<http.Response> Function(http.Request)? _requestOverride;

Future<void> _setSession(String userId) => supabase.auth.setInitialSession(
  jsonEncode({
    'access_token':
        '${base64Url.encode(utf8.encode('{"alg":"none"}'))}.'
        '${base64Url.encode(utf8.encode(jsonEncode({'sub': userId, 'exp': 4102444800})))}.local-test-signature',
    'token_type': 'bearer',
    'refresh_token': 'local-fake-refresh',
    'user': {
      'id': userId,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-09-13T00:00:00Z',
    },
  }),
);

http.Response _rpcState([String result = 'pending', http.Request? request]) =>
    http.Response(
      jsonEncode({
        'result': result,
        'duplicate_review_required': null,
        'consent_granted': true,
        'consent_version': kIdentityVerificationConsentVersion,
        'consent_recorded_at': '2026-09-13T00:00:00Z',
        'updated_at': '2026-09-13T00:00:00Z',
      }),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );

class _DeleteFailureStore implements ZyraSignupDraftStore {
  int deleteCalls = 0;
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {
    deleteCalls++;
    throw StateError('private Keychain details');
  }
}

ZyraIdentityVerificationState _state(
  ZyraIdentityVerificationResult result, {
  ZyraDuplicateReviewState duplicate = ZyraDuplicateReviewState.notEvaluated,
}) => ZyraIdentityVerificationState(
  result: result,
  duplicateReview: duplicate,
  consentGranted: true,
  consentVersion: kIdentityVerificationConsentVersion,
  consentRecordedAt: DateTime.utc(2026, 9, 13),
  updatedAt: DateTime.utc(2026, 9, 13),
);

class _Provider implements ZyraIdentityVerificationProviderAdapter {
  final Future<ZyraVerificationLaunchOutcome> Function() action;
  int calls = 0;

  _Provider(this.action);

  @override
  Future<ZyraVerificationLaunchOutcome> launch() {
    calls++;
    return action();
  }
}

Future<void> _settlePublicExit(WidgetTester tester, Finder button) async {
  final dynamic action = tester.widget<TextButton>(button).onPressed!;
  final Future<void> flight = action() as Future<void>;
  var settled = false;
  Object? failure;
  StackTrace? failureStack;
  flight.then(
    (_) => settled = true,
    onError: (Object error, StackTrace stack) {
      failure = error;
      failureStack = stack;
      settled = true;
    },
  );
  // A busy animation cannot settle by advancing only the fake clock while
  // stream cancellation is waiting for a real event turn.
  for (var frame = 0; frame < 80 && !settled; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(settled, isTrue, reason: 'Owned exit callback completed');
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 2),
  );
}

Future<void> _drainExitCleanup(WidgetTester tester) async {
  var settled = false;
  Object? failure;
  StackTrace? failureStack;
  ZyraAccountState.synchronize(null).then(
    (_) => settled = true,
    onError: (Object error, StackTrace stack) {
      failure = error;
      failureStack = stack;
      settled = true;
    },
  );
  for (var frame = 0; frame < 80 && !settled; frame++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(settled, isTrue, reason: 'Owned exit cache cleanup completed');
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
  var rehomed = false;
  Zone.root.run(() {
    // Keep the next test from inheriting completed queue Futures owned by
    // this clock. These are only the suite's synthetic account bindings.
    ZyraAccountState.synchronize(_userA);
    ZyraAccountState.synchronize(null).then((_) => rehomed = true);
  });
  for (var frame = 0; frame < 80 && !rehomed; frame++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(
    rehomed,
    isTrue,
    reason: 'Owned exit cleanup queue re-homed before fixture exit',
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'local-widget-test',
      // Synthetic state/exit tests do not exercise native URI delivery.
      // Keep real app-link channels outside this intercepted Auth fixture.
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        _requestPaths.add(request.url.path);
        if (_requestOverride != null) return _requestOverride!(request);
        if (request.url.path.endsWith('zyra_my_identity_verification_state') ||
            request.url.path.endsWith(
              'zyra_record_identity_verification_consent',
            )) {
          return _rpcState('pending', request);
        }
        if (request.url.path.endsWith(
          'zyra_delete_my_unstarted_identity_verification_attempt',
        )) {
          return http.Response(
            'true',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/auth/v1/logout') {
          return http.Response(
            '{}',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"message":"local test denied"}',
          403,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    _requestPaths.clear();
    _requestOverride = null;
    await _setSession(_userA);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraIdentityVerificationService.resetProviderForTesting();
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
  });

  test(
    'provider configuration is not verification or a network health check',
    () {
      expect(ZyraIdentityVerificationService.isProviderConfigured, isFalse);
      ZyraIdentityVerificationService.setProviderForTesting(
        _Provider(() async => ZyraVerificationLaunchOutcome.unavailable),
      );
      expect(ZyraIdentityVerificationService.isProviderConfigured, isTrue);
      expect(_state(ZyraIdentityVerificationResult.pending).allowsApp, isFalse);
      ZyraIdentityVerificationService.resetProviderForTesting();
      expect(ZyraIdentityVerificationService.isProviderConfigured, isFalse);
    },
  );

  for (final startingResult in <ZyraIdentityVerificationResult?>[
    null,
    ZyraIdentityVerificationResult.pending,
    ZyraIdentityVerificationResult.cancelled,
  ]) {
    testWidgets('code identity state from ${startingResult?.name ?? 'consent'} '
        'requires verified ordinary Continue', (tester) async {
      var finalized = 0;
      var continued = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            devPreview: true,
            initialState: startingResult == null
                ? null
                : _state(startingResult),
            finalizeOnboarding: () async {
              finalized++;
              return null;
            },
            onContinue: (_) async => continued++,
          ),
        ),
      );
      final action = find.byKey(const ValueKey('identity_dev_skip'));
      expect(action, findsNothing);
      expect(find.byKey(const ValueKey('identity-continue')), findsNothing);
      expect(finalized, 0);
      expect(continued, 0);
      await verifyIdentityFromCode(tester);
      await tester.tap(find.byKey(const ValueKey('identity-continue')));
      await tester.pumpAndSettle();
      expect(finalized, 1);
      expect(continued, 1);
      expect(_requestPaths, isEmpty);
    });
  }

  testWidgets(
    'identity skip stays absent and verified Continue rejects revocation',
    (tester) async {
      var continued = 0;
      await tester.pumpWidget(
        const MaterialApp(home: InitialIdentityCheckScreen()),
      );
      expect(find.byKey(const ValueKey('identity_dev_skip')), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            key: const ValueKey('fresh-admitted-identity-preview'),
            devPreview: true,
            initialState: _state(ZyraIdentityVerificationResult.verified),
            onContinue: (_) async => continued++,
          ),
        ),
      );
      final dynamic continueButton = tester.widget<Widget>(
        find.byKey(const ValueKey('identity-continue')),
      );
      final VoidCallback stale = continueButton.onPressed;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      expect(continued, 0);
      expect(
        find.byKey(const ValueKey('identity_preview_denied')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('identity_dev_skip')), findsNothing);
      expect(_requestPaths, isEmpty);
    },
  );

  testWidgets(
    'code fixture runs consent and verified state without developer controls',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: InitialIdentityCheckScreen(devPreview: true)),
      );

      expect(find.text('Verify your identity'), findsOneWidget);
      expect(find.text('I agree — verify me'), findsOneWidget);
      expect(find.text("I don't consent"), findsOneWidget);
      expect(find.text('Continue to ZYRA'), findsNothing);
      expect(
        find.byKey(const ValueKey('identity-use-different-account')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('identity-consent-agree')));
      await tester.pumpAndSettle();

      expect(find.text('Verification is unavailable.'), findsOneWidget);
      expect(find.text('Your check is in progress.'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('DEVELOPER STATE · LOCAL ONLY'), findsNothing);

      await verifyIdentityFromCode(tester);
      await tester.pump();

      expect(find.text('Identity verified.'), findsOneWidget);
      expect(find.byKey(const ValueKey('identity-continue')), findsOneWidget);
    },
  );

  testWidgets('production entry is consent-first with no limited-mode bypass', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: InitialIdentityCheckScreen()),
    );

    expect(find.text(kIdentityVerificationConsentBody), findsOneWidget);
    expect(find.text('I agree — verify me'), findsOneWidget);
    expect(find.text("I don't consent"), findsOneWidget);
    expect(find.textContaining('limited mode'), findsNothing);
    expect(find.text('Identity verified.'), findsNothing);
    expect(
      find.byKey(const ValueKey('identity-use-different-account')),
      findsOneWidget,
    );
  });

  testWidgets('refusal gives the honest exit and deletion choice', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: InitialIdentityCheckScreen(devPreview: true)),
    );

    await tester.tap(find.byKey(const ValueKey('identity-consent-decline')));
    await tester.pumpAndSettle();

    expect(find.text('Verification is required.'), findsOneWidget);
    expect(find.text('Delete verification attempt'), findsOneWidget);
    expect(find.text('Review consent again'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('identity-use-different-account')),
      findsNothing,
    );
  });

  testWidgets('verified initial signup still exposes account switching', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InitialIdentityCheckScreen(
          initialState: _state(ZyraIdentityVerificationResult.verified),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('identity-continue')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('identity-use-different-account')),
      findsOneWidget,
    );
  });

  testWidgets(
    'pending with no adapter is unavailable before and after remount',
    (tester) async {
      final pending = _state(ZyraIdentityVerificationResult.pending);
      for (var mount = 0; mount < 2; mount++) {
        await tester.pumpWidget(
          MaterialApp(
            home: InitialIdentityCheckScreen(
              key: ValueKey(mount),
              initialState: pending,
            ),
          ),
        );
        expect(find.text('Verification is unavailable.'), findsOneWidget);
        expect(find.text('Your check is in progress.'), findsNothing);
        expect(find.byKey(const ValueKey('identity-retry')), findsOneWidget);
        expect(find.text('Continue to ZYRA'), findsNothing);
        expect(pending.result, ZyraIdentityVerificationResult.pending);
      }
    },
  );

  testWidgets('pending with an adapter remains neutral and can start capture', (
    tester,
  ) async {
    final provider = _Provider(
      () async => ZyraVerificationLaunchOutcome.unavailable,
    );
    ZyraIdentityVerificationService.setProviderForTesting(provider);
    await tester.pumpWidget(
      MaterialApp(
        home: InitialIdentityCheckScreen(
          initialState: _state(ZyraIdentityVerificationResult.pending),
        ),
      ),
    );
    expect(find.text("Your identity isn't verified yet."), findsOneWidget);
    expect(find.text('Your check is in progress.'), findsNothing);
    expect(find.text('Start or resume check'), findsOneWidget);
    expect(find.text('Check for a result'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('identity-retry')));
    await tester.pumpAndSettle();
    expect(provider.calls, 1);
    expect(find.text('Verification is unavailable.'), findsOneWidget);
    expect(find.text('Continue to ZYRA'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('identity-retry')));
    await tester.pumpAndSettle();
    expect(provider.calls, 2);
  });

  for (final scenario in [
    (
      label: 'returned failure',
      action: () async => ZyraVerificationLaunchOutcome.failed,
      title: "The identity check couldn't open.",
    ),
    (
      label: 'cancellation',
      action: () async => ZyraVerificationLaunchOutcome.cancelled,
      title: 'The identity check was closed.',
    ),
    (
      label: 'thrown exception',
      action: () async => throw StateError('private provider details'),
      title: "The identity check couldn't open.",
    ),
  ]) {
    testWidgets('${scenario.label} clears busy and offers a real retry', (
      tester,
    ) async {
      final provider = _Provider(scenario.action);
      ZyraIdentityVerificationService.setProviderForTesting(provider);
      var finalized = 0;
      var continued = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            initialState: _state(ZyraIdentityVerificationResult.pending),
            finalizeOnboarding: () async {
              finalized++;
              return null;
            },
            onContinue: (_) async => continued++,
          ),
        ),
      );
      for (var attempt = 1; attempt <= 2; attempt++) {
        await tester.tap(find.byKey(const ValueKey('identity-retry')));
        await tester.pumpAndSettle();
        expect(provider.calls, attempt);
        expect(find.text(scenario.title), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.text('Your check is in progress.'), findsNothing);
        expect(find.textContaining('private provider details'), findsNothing);
        expect(find.text('Continue to ZYRA'), findsNothing);
        expect(finalized, 0);
        expect(continued, 0);
      }
    });
  }

  testWidgets(
    'an unfinished launch blocks duplicate taps and disposal is safe',
    (tester) async {
      final completion = Completer<ZyraVerificationLaunchOutcome>();
      final provider = _Provider(() => completion.future);
      ZyraIdentityVerificationService.setProviderForTesting(provider);
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            initialState: _state(ZyraIdentityVerificationResult.pending),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('identity-retry')));
      await tester.pump();
      expect(provider.calls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      completion.complete(ZyraVerificationLaunchOutcome.failed);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    (
      result: ZyraIdentityVerificationResult.failed,
      title: "We couldn't verify your identity.",
    ),
    (
      result: ZyraIdentityVerificationResult.expired,
      title: 'This check expired.',
    ),
    (
      result: ZyraIdentityVerificationResult.reviewRequired,
      title: 'A manual review is needed.',
    ),
  ]) {
    testWidgets(
      '${scenario.result.storageValue} preserves its canonical meaning before retry',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: InitialIdentityCheckScreen(
              initialState: _state(scenario.result),
            ),
          ),
        );
        expect(find.text(scenario.title), findsOneWidget);
        expect(find.text('Verification is unavailable.'), findsNothing);
        expect(find.text('Continue to ZYRA'), findsNothing);
      },
    );
  }

  testWidgets('a launched callback is not a server verification grant', (
    tester,
  ) async {
    final provider = _Provider(
      () async => ZyraVerificationLaunchOutcome.launched,
    );
    ZyraIdentityVerificationService.setProviderForTesting(provider);
    var finalized = 0;
    var continued = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: InitialIdentityCheckScreen(
          initialState: _state(ZyraIdentityVerificationResult.pending),
          finalizeOnboarding: () async {
            finalized++;
            return null;
          },
          onContinue: (_) async => continued++,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('identity-retry')));
    await tester.pumpAndSettle();
    expect(provider.calls, 1);
    expect(find.text('Your check is in progress.'), findsNothing);
    expect(find.text('Continue to ZYRA'), findsNothing);
    expect(finalized, 0);
    expect(continued, 0);
    expect(tester.takeException(), isNull);
  });

  for (final result in ZyraIdentityVerificationResult.values.where(
    (result) => result != ZyraIdentityVerificationResult.verified,
  )) {
    testWidgets(
      '${result.storageValue} never claims a verified duplicate hold',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: InitialIdentityCheckScreen(
              initialState: _state(result),
              requireDuplicateResolution: true,
            ),
          ),
        );
        expect(find.textContaining('Your identity is confirmed'), findsNothing);
        expect(find.text('Continue to ZYRA'), findsNothing);
        expect(find.text('Return to Journey'), findsNothing);
      },
    );
  }

  testWidgets(
    'verified duplicate-unresolved result retains the stricter hold',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            initialState: _state(ZyraIdentityVerificationResult.verified),
            requireDuplicateResolution: true,
          ),
        ),
      );
      expect(find.text('A review is still in progress.'), findsOneWidget);
      expect(find.textContaining('Your identity is confirmed'), findsOneWidget);
      expect(find.text('Return to Journey'), findsNothing);
      expect(find.text('Verification is unavailable.'), findsNothing);
    },
  );

  for (final throws in [false, true]) {
    testWidgets(
      'finalizer ${throws ? 'exception' : 'error'} stays retryable and does not continue',
      (tester) async {
        var finalized = 0;
        var continued = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: InitialIdentityCheckScreen(
              initialState: _state(ZyraIdentityVerificationResult.verified),
              finalizeOnboarding: () async {
                finalized++;
                if (throws) throw StateError('private finalizer details');
                return 'Setup could not be saved.';
              },
              onContinue: (_) async => continued++,
            ),
          ),
        );
        for (var attempt = 1; attempt <= 2; attempt++) {
          await tester.tap(find.byKey(const ValueKey('identity-continue')));
          await tester.pumpAndSettle();
          expect(finalized, attempt);
          expect(continued, 0);
          expect(
            find.text(
              throws
                  ? "We couldn't finish setup. Please try again."
                  : 'Setup could not be saved.',
            ),
            findsOneWidget,
          );
          expect(
            find.textContaining('private finalizer details'),
            findsNothing,
          );
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNotNull,
          );
        }
      },
    );
  }

  testWidgets('navigation exception after verification releases busy state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InitialIdentityCheckScreen(
          initialState: _state(ZyraIdentityVerificationResult.verified),
          onContinue: (_) async =>
              throw StateError('private navigation details'),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('identity-continue')));
    await tester.pumpAndSettle();
    expect(
      find.text("We couldn't finish setup. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('private navigation details'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'server-verified result continues even when capture is unavailable',
    (tester) async {
      var finalized = 0;
      var continued = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            initialState: _state(
              ZyraIdentityVerificationResult.verified,
              duplicate: ZyraDuplicateReviewState.clear,
            ),
            requireDuplicateResolution: true,
            finalizeOnboarding: () async {
              finalized++;
              return null;
            },
            onContinue: (_) async => continued++,
          ),
        ),
      );
      expect(find.text('Identity verified.'), findsOneWidget);
      expect(find.text('Verification is unavailable.'), findsNothing);
      expect(
        find.byKey(const ValueKey('identity-use-different-account')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('identity-continue')));
      await tester.pumpAndSettle();
      expect(finalized, 1);
      expect(continued, 1);
    },
  );

  for (final action in [
    'consent',
    'delete',
    'refresh',
    'launch',
    'continue',
    'signout',
  ]) {
    testWidgets(
      'account change blocks $action without touching the new account',
      (tester) async {
        final provider = _Provider(
          () async => ZyraVerificationLaunchOutcome.launched,
        );
        ZyraIdentityVerificationService.setProviderForTesting(provider);
        var finalized = 0;
        var continued = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: InitialIdentityCheckScreen(
              initialState: action == 'consent'
                  ? null
                  : _state(
                      action == 'delete'
                          ? ZyraIdentityVerificationResult.cancelled
                          : action == 'continue'
                          ? ZyraIdentityVerificationResult.verified
                          : ZyraIdentityVerificationResult.pending,
                    ),
              finalizeOnboarding: () async {
                finalized++;
                return null;
              },
              onContinue: (_) async => continued++,
            ),
          ),
        );
        await _setSession(_userB);
        final finder = switch (action) {
          'consent' => find.byKey(const ValueKey('identity-consent-agree')),
          'delete' => find.byKey(const ValueKey('identity-delete-attempt')),
          'refresh' => find.byKey(const ValueKey('identity-refresh')),
          'continue' => find.byKey(const ValueKey('identity-continue')),
          'signout' => find.byKey(
            const ValueKey('identity-use-different-account'),
          ),
          _ => find.byKey(const ValueKey('identity-retry')),
        };
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('identity-session-changed')),
          findsOneWidget,
        );
        expect(_requestPaths, isEmpty);
        expect(provider.calls, 0);
        expect(finalized, 0);
        expect(continued, 0);
        expect(supabase.auth.currentUser?.id, _userB);
        expect(find.byType(WelcomeScreen), findsNothing);
      },
    );
  }

  testWidgets(
    'ordinary unauthenticated page cannot show a verification grant',
    (tester) async {
      await tester.runAsync(
        () => supabase.auth.signOut(scope: SignOutScope.local),
      );
      _requestPaths.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            initialState: _state(ZyraIdentityVerificationResult.verified),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('identity-session-changed')),
        findsOneWidget,
      );
      expect(find.text('Identity verified.'), findsNothing);
      expect(find.byKey(const ValueKey('identity-continue')), findsNothing);
      expect(_requestPaths, isEmpty);
    },
  );

  testWidgets(
    'account change while launching prevents refresh and continuation',
    (tester) async {
      final completion = Completer<ZyraVerificationLaunchOutcome>();
      final provider = _Provider(() => completion.future);
      ZyraIdentityVerificationService.setProviderForTesting(provider);
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            initialState: _state(ZyraIdentityVerificationResult.pending),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('identity-retry')));
      await tester.pump();
      await _setSession(_userB);
      completion.complete(ZyraVerificationLaunchOutcome.launched);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('identity-session-changed')),
        findsOneWidget,
      );
      expect(_requestPaths, isEmpty);
      expect(supabase.auth.currentUser?.id, _userB);
    },
  );

  testWidgets('account change while finalizing prevents navigation', (
    tester,
  ) async {
    final completion = Completer<String?>();
    var continued = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: InitialIdentityCheckScreen(
          initialState: _state(ZyraIdentityVerificationResult.verified),
          finalizeOnboarding: () => completion.future,
          onContinue: (_) async => continued++,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('identity-continue')));
    await tester.pump();
    await _setSession(_userB);
    completion.complete(null);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('identity-session-changed')),
      findsOneWidget,
    );
    expect(continued, 0);
    expect(supabase.auth.currentUser?.id, _userB);
  });

  for (final throws in [false, true]) {
    testWidgets(
      'deletion ${throws ? 'transport failure' : 'false result'} makes no no-change claim',
      (tester) async {
        _requestOverride = (request) async {
          if (throws) throw StateError('private transport failure');
          return http.Response(
            'false',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        };
        await tester.pumpWidget(
          MaterialApp(
            home: InitialIdentityCheckScreen(
              initialState: _state(ZyraIdentityVerificationResult.cancelled),
            ),
          ),
        );
        for (var attempt = 1; attempt <= 2; attempt++) {
          await tester.tap(
            find.byKey(const ValueKey('identity-delete-attempt')),
          );
          await tester.pumpAndSettle();
          expect(
            find.text("We couldn't confirm deletion. Please try again."),
            findsOneWidget,
          );
          expect(find.textContaining('Nothing else was changed'), findsNothing);
          expect(
            find.textContaining('private transport failure'),
            findsNothing,
          );
          expect(find.byType(WelcomeScreen), findsNothing);
          expect(supabase.auth.currentUser?.id, _userA);
          expect(_requestPaths.length, attempt);
          expect(
            _requestPaths.every(
              (path) => path.endsWith(
                'zyra_delete_my_unstarted_identity_verification_attempt',
              ),
            ),
            isTrue,
          );
        }
      },
    );
  }

  for (final deleteAttempt in [false, true]) {
    testWidgets(
      'Keychain signout failure ${deleteAttempt ? 'after deletion' : 'on exit'} stays truthful and retryable',
      (tester) async {
        final store = _DeleteFailureStore();
        final previousCleaner = ZyraAccountState.clearImagesForTesting;
        // These intercepted protected-erasure cases exercise neither native
        // filesystem directories nor real image-cache maintenance.
        ZyraAccountState.clearImagesForTesting = () async {};
        try {
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
              home: InitialIdentityCheckScreen(
                initialState: _state(
                  deleteAttempt
                      ? ZyraIdentityVerificationResult.cancelled
                      : ZyraIdentityVerificationResult.pending,
                ),
              ),
            ),
          );
          for (var attempt = 1; attempt <= 2; attempt++) {
            await _settlePublicExit(
              tester,
              deleteAttempt && attempt == 1
                  ? find.byKey(const ValueKey('identity-delete-attempt'))
                  : deleteAttempt
                  ? find.byKey(const ValueKey('identity-delete-attempt'))
                  : find.byKey(
                      const ValueKey('identity-use-different-account'),
                    ),
            );
            expect(store.deleteCalls, attempt);
            expect(
              find.text(
                deleteAttempt
                    ? 'Your verification attempt was deleted, but sign-out could not be completed. Please try signing out again.'
                    : "We couldn't finish signing out. Please try again.",
              ),
              findsOneWidget,
            );
            expect(
              find.textContaining('private Keychain details'),
              findsNothing,
            );
            expect(find.byType(WelcomeScreen), findsNothing);
            expect(supabase.auth.currentUser?.id, _userA);
            expect(
              _requestPaths
                  .where(
                    (path) => path.endsWith(
                      'zyra_delete_my_unstarted_identity_verification_attempt',
                    ),
                  )
                  .length,
              deleteAttempt ? 1 : 0,
            );
            expect(
              _requestPaths.where((path) => path == '/auth/v1/logout'),
              isEmpty,
            );
          }
        } finally {
          try {
            await _drainExitCleanup(tester);
          } finally {
            ZyraAccountState.clearImagesForTesting = previousCleaner;
          }
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
