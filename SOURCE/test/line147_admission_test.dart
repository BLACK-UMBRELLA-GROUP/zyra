import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/zyra_family_introduction_preview.dart';
import 'package:zyra/dev/zyra_full_profile_preview.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_session_router.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';
import 'package:zyra/widgets/zyra_app_lock_gate.dart';
import 'package:zyra/widgets/zyra_developer_title.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

const _owner = ZyraInternalFounderPolicy.approvedFounderUserId;
const _project = ZyraInternalFounderPolicy.approvedSupabaseUrl;
final _samples = ZyraDeveloperSamples.instance;
Finder _key(String value) => find.byKey(ValueKey(value));

Map<String, Object?> _session({String user = _owner, int version = 0}) {
  String part(Object data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  const metadata = {'zyra_role': 'founder'};
  return {
    'access_token':
        '${part({'alg': 'HS256'})}.${part({'iss': '$_project/auth/v1', 'sub': user, 'exp': 4102444800, 'session_id': 'line147-admission-session', 'app_metadata': metadata, 'jti': 'fixture-$version'})}.${part([1])}',
    'refresh_token': 'synthetic-line147-refresh-$version',
    'token_type': 'bearer',
    'user': {
      'id': user,
      'aud': 'authenticated',
      'email': 'sample-admin@example.org',
      'created_at': '2026-11-12T00:00:00Z',
      'app_metadata': metadata,
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var identity = _owner;
  var refresh = 0;
  final requests = <({String method, String path})>[];

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
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add((method: request.method, path: request.url.path));
        Object response = const [];
        if (request.url.path == '/auth/v1/token') {
          response = _session(user: identity, version: ++refresh);
        } else if (request.url.path == '/rest/v1/profiles' &&
            request.url.queryParameters['select'] ==
                'role,first_name,surname_line,gender,location_text') {
          response = [
            {
              'role': 'seeker',
              'first_name': 'Sample Admin',
              'gender': 'male',
              'location_text': 'Leeds',
            },
          ];
        } else if (request.url.path == '/rest/v1/subscriptions') {
          response = [
            {'plan_type': 'seeker_premium', 'expires_at': null},
          ];
        } else if (request.url.path.endsWith('/ages_for_one')) {
          response = 29;
        }
        return http.Response(
          jsonEncode(response),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    identity = _owner;
    await supabase.auth.setInitialSession(jsonEncode(_session()));
    await ZyraAccountState.synchronize(identity);
    requests.clear();
  });

  tearDown(() {
    _samples.resetForAccountChange();
    ZyraAppLock.instance.clearForSignOut();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 8; frame++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  Future<GlobalKey<NavigatorState>> mount(
    WidgetTester tester, {
    required ViewRequestDraftModel model,
    int waiting = 0,
    int viewAs = 0,
  }) async {
    await tester.runAsync(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await ZyraSessionRouter.resolveHome();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
    final navigator = GlobalKey<NavigatorState>();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (_, child) => ZyraDeveloperPanelSession(
          child: ZyraAppLockGate(
            child: ZyraAccountSessionHost(
              navigatorKey: navigator,
              child: MediaQuery(
                data: MediaQueryData.fromView(tester.view).copyWith(
                  padding: const EdgeInsets.only(top: 59, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                  disableAnimations: true,
                ),
                child: child!,
              ),
            ),
          ),
        ),
        home: ZyraDeveloperSeekerScope(
          preview: true,
          child: Builder(
            builder: (context) {
              bool currentPreview() {
                final bridge = ZyraDeveloperSeekerScope.bridgeOf(context);
                return context.mounted &&
                    bridge?.canPresent == true &&
                    bridge?.viewAs != null &&
                    _samples.hasSamples;
              }

              return ZyraOneJourneyConceptShell(
                canAct: () =>
                    currentPreview() && ModalRoute.isCurrentOf(context) == true,
                // Match both admission predicates in the real Founder wrapper.
                canActInOwnedDialog: currentPreview,
                onExit: () {},
                initialTab: 2,
                fixture: ZyraOneJourneyShellFixture(
                  model: model,
                  seededWaitingRequests: waiting,
                ),
              );
            },
          ),
        ),
      ),
    );
    await settle(tester);
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_view_as_$viewAs'));
    await tap(tester, _key('dev_active_0'));
    await tap(tester, _key('dev_introductions_1'));
    await tap(tester, _key('dev_done'));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
    });
    return navigator;
  }

  Future<void> ordinaryRoute(WidgetTester tester, String route) async {
    await tap(tester, _key('concept-my-introductions'));
    await tap(tester, _key('sample-introduction-draft-noor-header'));
    if (route == 'profile') {
      await tap(tester, find.text('View profile'));
    } else if (route == 'circle') {
      await tap(tester, find.text('Ask my Guardians'));
      expect(_samples.introductionShares.single.person.id, 'draft-noor');
      await tap(tester, find.text('View'));
    }
  }

  // The seeded count represents other fixed fictional requests. All admission
  // still runs through the actual shell callback and current Navigator route.
  for (final plan in [
    (name: 'Basic', viewAs: 1, cap: 5),
    (name: 'One', viewAs: 0, cap: 20),
  ]) {
    for (final route in ['card', 'profile', 'circle']) {
      for (final full in [true, false]) {
        testWidgets('LOCK49 ordinary $route honors ${plan.name} ${plan.cap} '
            '${full ? 'full cap' : 'one free slot'}', (tester) async {
          final model = ViewRequestDraftModel(capacity: 3);
          await mount(
            tester,
            model: model,
            waiting: plan.cap - (full ? 0 : 1),
            viewAs: plan.viewAs,
          );
          await ordinaryRoute(tester, route);
          final before = requests.length;
          expect(_samples.waitingSentProfileIds, isEmpty);
          await tap(tester, find.text('Request a Journey'));
          if (full) {
            expect(_key('lock48_requests_full'), findsOneWidget);
            expect(
              find.textContaining('You have ${plan.cap} requests waiting.'),
              findsOneWidget,
            );
            expect(_samples.waitingSentProfileIds, isEmpty);
            expect(
              _samples.receivedIntroductions.single.person.id,
              'draft-noor',
            );
            await tap(tester, find.text('Not now'));
          } else {
            expect(_key('lock48_requests_full'), findsNothing);
            expect(_samples.waitingSentProfileIds, ['draft-noor']);
            expect(_samples.receivedIntroductions, isEmpty);
          }
          expect(model.waitingSentProfileIds, isEmpty);
          expect(requests, hasLength(before));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final guard in ['Pause', 'Block', 'departed', 'covered', 'account']) {
    testWidgets('LOCK49 Circle ordinary callback rejects $guard state', (
      tester,
    ) async {
      final model = ViewRequestDraftModel(capacity: 3);
      final navigator = await mount(tester, model: model);
      await ordinaryRoute(tester, 'circle');
      final retained = tester
          .widget<ZyraFullProfilePreview>(find.byType(ZyraFullProfilePreview))
          .onAction!;
      final person = _samples.receivedIntroductions.single.person;
      final before = requests.length;
      switch (guard) {
        case 'Pause':
          expect(model.ownProfilePrivacy!.pause(), isTrue);
        case 'Block':
          expect(_samples.blockSampleProfile(person), isTrue);
        case 'departed':
          expect(model.markPeerDeparted(person.id), isTrue);
        case 'covered':
          unawaited(
            navigator.currentState!.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Covered profile')),
              ),
            ),
          );
        case 'account':
          await tester.runAsync(
            () => ZyraAccountState.synchronize('other-owner'),
          );
      }
      await settle(tester);
      retained();
      await settle(tester);
      expect(_samples.waitingSentProfileIds, isEmpty);
      expect(model.waitingSentProfileIds, isEmpty);
      expect(_key('lock48_requests_full'), findsNothing);
      expect(requests, hasLength(before));
      expect(tester.takeException(), isNull);
    });
  }

  for (final yes in [true, false]) {
    testWidgets('LOCK49 family Circle ${yes ? 'both yes' : 'any no'} '
        'does not spend a waiting-send place', (tester) async {
      final model = ViewRequestDraftModel(capacity: 3);
      await mount(tester, model: model, waiting: 20);
      await tap(tester, _key('concept-my-introductions'));
      await tap(tester, _key('family-introduction-sample-aisha-header'));
      final family = _samples.familyIntroduction('sample-aisha')!;
      expect(
        _samples.saveFamilyIntroductionAnswer(
          family,
          side: ZyraFamilyIntroductionSide.receiver,
          yes: true,
        ),
        isTrue,
      );
      await settle(tester);
      await tap(tester, find.text('Ask my Guardians'));
      final share = _samples.introductionShares.single;
      expect(
        _samples.shareIntroduction('draft-aisha', familyId: family.id),
        isTrue,
      );
      expect(_samples.introductionShares.single, same(share));
      await tap(tester, find.text('View'));
      final before = requests.length;
      await tap(tester, find.text(yes ? 'I’d like to begin' : 'Not for me'));
      expect(
        family.phase,
        yes
            ? ZyraFamilyIntroductionPhase.preparing
            : ZyraFamilyIntroductionPhase.notTakenForward,
      );
      expect(_key('lock48_requests_full'), findsNothing);
      expect(_samples.waitingSentProfileIds, isEmpty);
      expect(model.waitingSentProfileIds, isEmpty);
      expect(_samples.activeRows, hasLength(yes ? 1 : 0));
      expect(requests, hasLength(before));
      expect(tester.takeException(), isNull);
    });
  }

  for (final replaced in ['role', 'account']) {
    testWidgets('LOCK49 retained Main reply rejects a changed $replaced', (
      tester,
    ) async {
      final model = ViewRequestDraftModel(capacity: 3);
      await mount(tester, model: model, viewAs: 2);
      tester
          .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
          .onTap(2);
      await settle(tester);
      await tap(tester, _key('guardian_connect'));
      await tap(tester, _key('guardian_connect_tab_1'));
      final page = tester.widget<ZyraGuardianTabsPresentation>(
        find.byType(ZyraGuardianTabsPresentation),
      );
      final family = _samples.familyIntroduction('received-noor')!;
      expect(page.adamMain, isTrue);
      expect(family.phase, ZyraFamilyIntroductionPhase.awaitingReply);
      final before = requests.length;
      if (replaced == 'role') {
        await tap(tester, _key('dev_page_title'));
        await tap(tester, _key('dev_view_as_0'));
        await tap(tester, _key('dev_done'));
      } else {
        await tester.runAsync(
          () => ZyraAccountState.synchronize('other-owner'),
        );
        await settle(tester);
      }
      final afterReplacement = requests.length;
      page.onAction(
        'family_introduction:open:${family.id}:${family.phase.name}',
      );
      await settle(tester);
      expect(family.phase, ZyraFamilyIntroductionPhase.awaitingReply);
      expect(requests, hasLength(afterReplacement));
      expect(
        requests
            .skip(before)
            .where((r) => r.method != 'GET' && r.path.startsWith('/rest/')),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
