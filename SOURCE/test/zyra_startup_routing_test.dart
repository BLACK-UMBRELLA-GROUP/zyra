import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/zyra_founder_launch_screen.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/screens/auth_gate.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_session_router.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

const _a = '00000000-0000-4000-8000-000000000701';
const _b = '00000000-0000-4000-8000-000000000702';
const _founder = ZyraInternalFounderPolicy.approvedFounderUserId;

// Unsigned synthetic sessions and intercepted HTTP only. No live credentials.
Future<void> _session(String id, {bool founder = false}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': founder ? {'zyra_role': 'founder'} : {},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-09-14T00:00:00Z',
      },
    }),
  );
}

Future<void> _settlePreview(WidgetTester tester) async {
  // The launch uses a real preference queue as well as Flutter's fake clock.
  // Keep both moving without waiting indefinitely for a loading animation.
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
}

Future<void> _disposePreviewAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _settlePreview(tester);
  // Start the new preference tail in the real zone, then flush the previous
  // widget zone before it ends. The next ordinary test cannot flush this one.
  await tester.runAsync(() async {
    unawaited(ZyraAccountState.synchronize(null));
  });
  var preferencesDrained = false;
  ZyraLocalPrefs.bindAccount(null).then((_) => preferencesDrained = true);
  var accountDrained = false;
  ZyraAccountState.synchronize(null).then((_) => accountDrained = true);
  for (
    var frame = 0;
    frame < 20 && (!preferencesDrained || !accountDrained);
    frame++
  ) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(preferencesDrained, isTrue, reason: 'Preference queue is drained');
  expect(accountDrained, isTrue, reason: 'Account queue is drained');
  expect(ZyraConceptPreviewIsolation.active, isFalse);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <String>[];
  Future<void> Function(String path)? beforeResponse;
  Completer<void>? refreshGate;
  var refreshFails = false;
  var profileFails = false;

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/events'),
      (_) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        requests.add(path);
        await beforeResponse?.call(path);
        Object? body = [];
        var status = 200;
        if (path == '/rest/v1/profiles') {
          if (request.url.queryParameters['id']?.startsWith('neq.') == true) {
            // Mounting an ordinary shell also asks Browse for other people.
            // This fixture has no candidates; its own-row response is not a
            // synthetic candidate and must not be returned for that query.
            body = [];
          } else if (profileFails) {
            status = 503;
            body = {'message': 'synthetic service unavailable'};
          } else {
            body = [
              {
                'role': 'seeker',
                'first_name': 'Prior member',
                'surname_line': 'Prior family',
                'gender': 'female',
                'location_text': 'Prior city',
              },
            ];
          }
        } else if (path.endsWith('/ages_for_one')) {
          body = 29;
        } else if (path == '/rest/v1/subscriptions') {
          body = [
            {'plan_type': 'seeker_premium'},
          ];
        }
        return http.Response(
          jsonEncode(body),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  setUp(() async {
    ZyraAccountState.resetForTesting();
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize(null);
    await _session(_a);
    await ZyraAccountState.synchronize(_a);
    requests.clear();
    beforeResponse = null;
    refreshGate = null;
    refreshFails = false;
    profileFails = false;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () async {
        await refreshGate?.future;
        if (refreshFails) throw StateError('synthetic refresh unavailable');
        return supabase.auth.currentUser;
      },
      founderIdentityMatches: (user) =>
          user.id == _founder && user.appMetadata['zyra_role'] == 'founder',
    );
  });

  tearDown(() async {
    beforeResponse = null;
    ZyraSessionRouter.setReadTimeoutForTesting(null);
    await Future<void>.delayed(Duration.zero);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    debugDefaultTargetPlatformOverride = null;
  });
  tearDownAll(() => Supabase.instance.dispose());

  test(
    'hung profile read recovers and late response cannot hydrate the account',
    () async {
      ZyraSessionRouter.setReadTimeoutForTesting(
        const Duration(milliseconds: 30),
      );
      final release = Completer<void>();
      beforeResponse = (path) async {
        if (path == '/rest/v1/profiles') await release.future;
      };
      await expectLater(
        ZyraSessionRouter.resolveHome(),
        throwsA(isA<TimeoutException>()),
      );
      expect(AppState.instance.hydrated, isFalse);
      release.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(AppState.instance.hydrated, isFalse);
      expect(AppState.instance.name, isNull);
    },
  );

  test(
    'timed-out subscription response cannot later publish a paid plan',
    () async {
      ZyraSessionRouter.setReadTimeoutForTesting(
        const Duration(milliseconds: 30),
      );
      final release = Completer<void>();
      beforeResponse = (path) async {
        if (path == '/rest/v1/subscriptions') await release.future;
      };
      expect(await ZyraSessionRouter.resolveHome(), isA<HomeShell>());
      expect(AppState.instance.plan, ZyraPlan.basic);
      release.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(AppState.instance.plan, ZyraPlan.basic);
    },
  );

  test(
    'ordinary account still hydrates and opens its own member shell',
    () async {
      expect(await ZyraSessionRouter.resolveHome(), isA<HomeShell>());
      expect(AppState.instance.name, 'Prior member');
      expect(AppState.instance.gender, 'female');
      expect(ZyraLocalPrefs.cachedRole, 'seeker');
    },
  );

  test(
    'fresh Founder authorization resolves before any member request',
    () async {
      await _session(_founder, founder: true);
      expect(
        await ZyraSessionRouter.resolveHome(),
        isA<ZyraFounderLaunchScreen>(),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'failed Founder refresh cannot read a profile or reuse cached role',
    () async {
      await _session(_founder, founder: true);
      await ZyraAccountState.synchronize(_founder);
      ZyraLocalPrefs.setCachedRole('seeker');
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      refreshFails = true;
      await expectLater(
        ZyraSessionRouter.resolveHome(),
        throwsA(isA<ZyraPreviewAuthorizationException>()),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'latched preview denies member routing after a personal sign-in',
    () async {
      ZyraInternalPreviewClient.beginPreview();
      await expectLater(
        ZyraSessionRouter.resolveHome(),
        throwsA(isA<ZyraPreviewAuthorizationException>()),
      );
      expect(requests, isEmpty);
    },
  );

  for (final pauseAt in [
    '/rest/v1/profiles',
    '/rest/v1/rpc/ages_for_one',
    '/rest/v1/subscriptions',
    '/rest/v1/rpc/zyra_my_onboarding_progress',
  ]) {
    test(
      'account change during $pauseAt cannot publish or return old state',
      () async {
        final started = Completer<void>();
        final release = Completer<void>();
        beforeResponse = (path) async {
          if (path != pauseAt) return;
          if (!started.isCompleted) started.complete();
          await release.future;
        };
        final route = ZyraSessionRouter.resolveHome();
        final failed = expectLater(route, throwsA(isA<StateError>()));
        await started.future;
        await _session(_b);
        await ZyraAccountState.synchronize(_b);
        AppState.instance.name = 'Current member';
        release.complete();
        await failed;
        expect(AppState.instance.name, 'Current member');
        expect(AppState.instance.gender, isNull);
        expect(ZyraLocalPrefs.cachedRole, isNull);
      },
    );
  }

  test(
    'A to B to A during hydration still rejects the obsolete generation',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      beforeResponse = (path) async {
        if (!path.endsWith('/ages_for_one')) return;
        started.complete();
        await release.future;
      };
      final route = ZyraSessionRouter.resolveHome();
      final failed = expectLater(route, throwsA(isA<StateError>()));
      await started.future;
      await _session(_b);
      await ZyraAccountState.synchronize(_b);
      await _session(_a);
      await ZyraAccountState.synchronize(_a);
      AppState.instance.name = 'New A session';
      release.complete();
      await failed;
      expect(AppState.instance.name, 'New A session');
    },
  );

  test(
    'late background decisions cannot erase the next account’s choices',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      beforeResponse = (path) async {
        if (path != '/rest/v1/saves') return;
        started.complete();
        await release.future;
      };
      expect(await ZyraSessionRouter.resolveHome(), isA<HomeShell>());
      await started.future;
      await _session(_b);
      await ZyraAccountState.synchronize(_b);
      AppState.instance.hydrateDecisions(
        saved: [mockProfiles.first],
        considered: [],
        passed: [],
      );
      release.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(AppState.instance.saved.map((profile) => profile.id), [
        mockProfiles.first.id,
      ]);
    },
  );

  test(
    'a cached member role never rescues a switched-account failure',
    () async {
      ZyraLocalPrefs.setCachedRole('wali');
      beforeResponse = (path) async {
        if (path != '/rest/v1/profiles') return;
        await _session(_b);
        await ZyraAccountState.synchronize(_b);
      };
      profileFails = true;
      await expectLater(
        ZyraSessionRouter.resolveHome(),
        throwsA(isA<StateError>()),
      );
    },
  );

  testWidgets('denied preview offers access retry without member traffic', (
    tester,
  ) async {
    await tester.runAsync(() async {
      ZyraAccountState.resetForTesting();
      await _session(_founder, founder: true);
      await ZyraAccountState.synchronize(_founder);
    });
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    refreshFails = true;
    await tester.pumpWidget(
      const MaterialApp(home: AuthGate(playSplash: false)),
    );
    await _settlePreview(tester);
    expect(find.text('Preview access needs checking.'), findsNothing);
    expect(find.text('Couldn’t open this page.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('zyra_error_compact_notice')),
      findsOneWidget,
    );
    expect(find.text('Sign out'), findsOneWidget);
    expect(requests, isEmpty);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    expect(AppState.instance.hydrated, isFalse);
    refreshFails = false;
    final pending = Completer<void>();
    refreshGate = pending;
    await tester.tap(find.byKey(const ValueKey('zyra_error_primary')));
    // Observe 0/16/100/799/800ms and 3s, not only the settled destination.
    // The replaced FutureBuilder future must not paint its old error while
    // a fresh proof operation is still pending.
    for (final elapsed in [
      Duration.zero,
      const Duration(milliseconds: 16),
      const Duration(milliseconds: 84),
      const Duration(milliseconds: 699),
      const Duration(milliseconds: 1),
      const Duration(milliseconds: 2200),
    ]) {
      await tester.pump(elapsed);
      expect(find.byType(ZyraFullScreenError), findsNothing);
      expect(find.text('Preview access needs checking.'), findsNothing);
      expect(find.text('Couldn’t open this page.'), findsNothing);
      expect(find.text('ZYRA'), findsNothing);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(AppState.instance.hydrated, isFalse);
      expect(requests, isEmpty);
      expect(tester.takeException(), isNull);
    }
    pending.complete();
    refreshGate = null;
    await _settlePreview(tester);
    expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
    expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
      ),
      findsNothing,
    );
    expect(find.byType(HomeShell), findsNothing);
    expect(ZyraInternalPreviewClient.isActive, isTrue);
    expect(ZyraConceptPreviewIsolation.active, isTrue);
    expect(requests, isEmpty);
    expect(tester.takeException(), isNull);
    await _disposePreviewAndDrain(tester);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'ordinary service recovery Retry and reopening restore the same member shell',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      expect(ZyraInternalFounderPolicy.enabled, isFalse);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      ZyraLocalPrefs.setCachedRole(null);
      profileFails = true;

      await tester.pumpWidget(
        const MaterialApp(home: AuthGate(playSplash: false)),
      );
      // Pinned postgrest 2.8.0 retains real GET503 retry delays of 1+2+4s.
      // An animated Golden loader used to keep pumpAndSettle advancing that
      // clock accidentally. Quiet waiting must instead observe actual error
      // readiness, without changing/retrying/bypassing the SDK policy.
      for (
        var step = 0;
        step < 10 && find.byType(ZyraFullScreenError).evaluate().isEmpty;
        step++
      ) {
        await _settlePreview(tester);
      }
      expect(tester.takeException(), isNull);
      final recovery = tester.widget<ZyraFullScreenError>(
        find.byType(ZyraFullScreenError),
      );
      expect(recovery.kind, ZyraErrorKind.serviceUnavailable);
      expect(find.byType(HomeShell), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
        ),
        findsNothing,
      );
      expect(AppState.instance.hydrated, isFalse);
      expect(find.textContaining('synthetic'), findsNothing);
      final failedProfileReads = requests
          .where((path) => path == '/rest/v1/profiles')
          .length;
      expect(failedProfileReads, greaterThan(0));

      profileFails = false;
      await tester.tap(find.byKey(const ValueKey('zyra_error_primary')));
      await _settlePreview(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(ZyraFullScreenError), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
        ),
        findsNothing,
      );
      expect(supabase.auth.currentUser?.id, _a);
      expect(AppState.instance.name, 'Prior member');
      expect(AppState.instance.gender, 'female');
      expect(ZyraLocalPrefs.cachedRole, 'seeker');
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(
        requests.where((path) => path == '/rest/v1/profiles').length,
        greaterThan(failedProfileReads),
        reason: 'Retry performs a fresh owner-bound lookup',
      );

      // This is a widget remount with the retained synthetic session. It is
      // deliberately not a claim about OS process death or native storage.
      await tester.pumpWidget(const SizedBox.shrink());
      await _settlePreview(tester);
      await tester.pumpWidget(
        const MaterialApp(home: AuthGate(playSplash: false)),
      );
      await _settlePreview(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(ZyraFullScreenError), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
        ),
        findsNothing,
      );
      expect(supabase.auth.currentUser?.id, _a);
      expect(AppState.instance.name, 'Prior member');
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      var drained = false;
      ZyraAccountState.synchronize(
        supabase.auth.currentUser?.id,
      ).then((_) => drained = true);
      for (var frame = 0; frame < 20 && !drained; frame++) {
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(
        drained,
        isTrue,
        reason: 'Fixture queues finish in their own zone',
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
