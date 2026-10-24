import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/zyra_dev_local_preview.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/dev/developer_access_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

void main() {
  var httpCalls = 0;
  // Initialise outside testWidgets' fake-async zone: the SDK owns an isolate
  // whose shutdown otherwise waits indefinitely for that zone to advance.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: ZyraInternalFounderPolicy.approvedSupabaseUrl,
      publishableKey: 'local-widget-test',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: ZyraInternalPreviewClient(
        MockClient((_) async {
          httpCalls++;
          return http.Response(
            '{"message":"test backend unavailable"}',
            403,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() {
    httpCalls = 0;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevLocalPreview.genderSelection.value = 'male';
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevLocalPreview.genderSelection.value = 'male';
    ZyraText.useTestFontStubs = false;
  });

  group('ZyraDeveloperAccess', () {
    for (final role in ZyraSignupRole.values) {
      testWidgets('${role.name} signup membership is a guarded local sample', (
        tester,
      ) async {
        const basic = ZyraSignupMembershipChoice(
          kind: ZyraSignupMembershipKind.basic,
        );
        const one = ZyraSignupMembershipChoice(
          kind: ZyraSignupMembershipKind.one,
        );
        final family = ZyraSignupMembershipChoice(
          kind: ZyraSignupMembershipKind.family,
          seekers: role == ZyraSignupRole.seeker ? 1 : 0,
          guardians: role == ZyraSignupRole.guardian ? 1 : 0,
        );
        AppState.instance.applyDevPreset();
        bool premium() => role == ZyraSignupRole.guardian
            ? AppState.instance.waliHasWaliOne
            : AppState.instance.plan == ZyraPlan.one;
        final original = premium();
        expect(
          ZyraDevLocalPreview.applySignupMembershipPreview(
            role: role,
            choice: one,
          ),
          isFalse,
        );
        expect(premium(), original);
        ZyraInternalPreviewClient.beginPreview();
        for (final choice in [basic, one, family]) {
          expect(
            ZyraDevLocalPreview.applySignupMembershipPreview(
              role: role,
              choice: choice,
            ),
            isTrue,
          );
          expect(premium(), choice.kind != ZyraSignupMembershipKind.basic);
        }
        expect(
          ZyraDevLocalPreview.applySignupMembershipPreview(
            role: role,
            choice: const ZyraSignupMembershipChoice(
              kind: ZyraSignupMembershipKind.family,
            ),
          ),
          isFalse,
        );
        expect(premium(), isTrue);
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        expect(
          ZyraDevLocalPreview.applySignupMembershipPreview(
            role: role,
            choice: basic,
          ),
          isFalse,
        );
        expect(premium(), isTrue);
        expect(httpCalls, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    for (final viewport in [
      (size: const Size(390, 844), textScale: 1.0),
      (size: const Size(320, 568), textScale: 1.5),
    ]) {
      testWidgets('landing has five text pills at ${viewport.size.width} width '
          'and ${viewport.textScale} text scale', (tester) async {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(viewport.textScale)),
              child: child!,
            ),
            home: const DeveloperAccessScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
          orderedEquals(const [
            'Developer Access',
            'Seeker',
            'Seeker Basic',
            'Guardian',
            'Guardian Basic',
            'Onboarding',
          ]),
        );
        expect(find.byType(InkWell), findsNWidgets(5));
        expect(find.byType(Icon), findsNothing);
        expect(find.text('Seeker Basic'), findsOneWidget);
        expect(find.text('Guardian Basic'), findsOneWidget);
        expect(
          tester.getCenter(find.text('Developer Access')).dx,
          closeTo(viewport.size.width / 2, 1),
        );
        for (final action in const [
          ('dev_access_seeker', 'Seeker'),
          ('dev_access_seeker_basic', 'Seeker Basic'),
          ('dev_access_guardian', 'Guardian'),
          ('dev_access_guardian_basic', 'Guardian Basic'),
          ('dev_access_signup', 'Onboarding'),
        ]) {
          final pill = find.byKey(ValueKey(action.$1));
          await tester.ensureVisible(pill);
          await tester.pump();
          final inkWell = find.ancestor(
            of: find.text(action.$2),
            matching: find.byType(InkWell),
          );
          expect(pill.hitTestable(), findsOneWidget);
          expect(tester.getSize(pill).height, greaterThanOrEqualTo(80));
          expect(tester.widget<InkWell>(inkWell).onTap, isNotNull);
          expect(
            tester.getCenter(pill).dx,
            closeTo(viewport.size.width / 2, 1),
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    for (final guardian in [false, true]) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} real shell Home opens five-button landing without signout or reset',
        (tester) async {
          final navigator = GlobalKey<NavigatorState>();
          final controlsRouteObserver = ZyraDevControlsRouteObserver();
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigator,
              navigatorObservers: [controlsRouteObserver],
              builder: (context, child) => ZyraGlobalDevOverlayHost(
                navigatorKey: navigator,
                routeObserver: controlsRouteObserver,
                authStateChangesOverride: const Stream<AuthState>.empty(),
                child: child!,
              ),
              home: const DeveloperAccessScreen(),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              ValueKey(guardian ? 'dev_access_guardian' : 'dev_access_seeker'),
            ),
          );
          await tester.pumpAndSettle();
          final shell = guardian ? WaliHomeShell : HomeShell;
          expect(find.byType(shell), findsOneWidget);
          final state = AppState.instance;
          final before = (
            state.name,
            state.gender,
            state.plan,
            state.waliHasWaliOne,
            ZyraAccountState.generation,
            Supabase.instance.client.auth.currentSession,
          );
          expect(ZyraInternalPreviewClient.isActive, isTrue);
          await openZyraDevControls(tester);
          await tester.tap(
            find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
          );
          await tester.pumpAndSettle();
          final home = find.byKey(const ValueKey('dev_home_navigation'));
          await tester.ensureVisible(home);
          await tester.pumpAndSettle();
          expect(find.text('Exit onboarding'), findsNothing);
          expect(
            find.descendant(
              of: home,
              matching: find.byIcon(Icons.home_outlined),
            ),
            findsOneWidget,
          );
          await tester.tap(home);
          await tester.pumpAndSettle();
          expect(find.byType(DeveloperAccessScreen), findsOneWidget);
          for (final key in const [
            'dev_access_seeker',
            'dev_access_guardian',
            'dev_access_signup',
          ]) {
            expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
          }
          expect(find.byType(shell), findsNothing);
          expect(
            find.byType(shell, skipOffstage: false),
            findsOneWidget,
            reason: 'The first root stays retained, not reset or signed out',
          );
          expect((
            state.name,
            state.gender,
            state.plan,
            state.waliHasWaliOne,
            ZyraAccountState.generation,
            Supabase.instance.client.auth.currentSession,
          ), before);
          expect(ZyraInternalPreviewClient.isActive, isTrue);
          expect(
            httpCalls,
            0,
            reason:
                'All transport is mocked; Home makes no member/OAuth/signout request',
          );
          expect(
            ZyraDevSurfaceCoordinator.instance.entryLabel,
            'Developer Access',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      for (final gender in const ['male', 'female']) {
        testWidgets(
          'main local $gender ${guardian ? 'Guardian' : 'Seeker'} preview opens its shell',
          (tester) async {
            ZyraDevLocalPreview.genderSelection.value = gender;
            tester.view.physicalSize = const Size(390, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              const MaterialApp(home: DeveloperAccessScreen()),
            );
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(
                ValueKey(
                  guardian ? 'dev_access_guardian' : 'dev_access_seeker',
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              find.byType(guardian ? WaliHomeShell : HomeShell),
              findsOneWidget,
            );
            expect(ZyraInternalPreviewClient.isActive, isTrue);
            if (guardian) {
              expect(AppState.instance.waliHasWaliOne, isTrue);
            } else {
              expect(AppState.instance.plan, ZyraPlan.one);
            }
            expect(AppState.instance.gender, gender);
            expect(
              AppState.instance.name,
              guardian
                  ? (gender == 'female' ? 'Khadija' : 'Ibrahim')
                  : (gender == 'female' ? 'Maryam' : 'Adam'),
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }

      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} Basic stays a local sample on gender change',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: DeveloperAccessScreen()),
          );
          await tester.pumpAndSettle();
          final action = find.byKey(
            ValueKey(
              guardian
                  ? 'dev_access_guardian_basic'
                  : 'dev_access_seeker_basic',
            ),
          );
          await tester.ensureVisible(action);
          await tester.tap(action);
          await tester.pumpAndSettle();
          final shell = find.byType(guardian ? WaliHomeShell : HomeShell);
          expect(shell, findsOneWidget);
          expect(ZyraInternalPreviewClient.isActive, isTrue);
          expect(AppState.instance.plan, ZyraPlan.basic);
          expect(AppState.instance.waliHasWaliOne, isFalse);
          expect(
            ZyraDevLocalPreview.basicMembershipPreviewLabel(guardian: guardian),
            '${guardian ? 'Guardian' : 'Seeker'} Basic · Preview',
          );
          await ZyraDevLocalPreview.selectGender(
            tester.element(shell),
            'female',
          );
          await tester.pumpAndSettle();
          expect(AppState.instance.gender, 'female');
          expect(AppState.instance.plan, ZyraPlan.basic);
          expect(AppState.instance.waliHasWaliOne, isFalse);
          expect(httpCalls, 0, reason: 'Local samples never write membership.');
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          expect(
            ZyraDevLocalPreview.basicMembershipPreviewLabel(guardian: guardian),
            isNull,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        'Onboarding opens full Welcome then real ${guardian ? 'Guardian' : 'Seeker'} setup',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final navigatorKey = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigatorKey,
              home: const DeveloperAccessScreen(),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const ValueKey('dev_access_signup')));
          await tester.pumpAndSettle();
          expect(find.byType(DevSignUpProcessScreen), findsOneWidget);
          expect(find.byType(WelcomeScreen), findsOneWidget);
          expect(
            tester.widget<WelcomeScreen>(find.byType(WelcomeScreen)).devPreview,
            isTrue,
          );
          expect(
            find.byKey(const ValueKey('dev_access_signup_roles')),
            findsNothing,
          );
          await tester.tap(find.byKey(const ValueKey('welcome_google')));
          await tester.pumpAndSettle();
          // Welcome precedes one four-page verification/How ZYRA works section.
          // Check the full reader, not the superseded seven-card sequence.
          for (var step = 0; step < 5; step++) {
            expect(
              find
                  .byKey(
                    step == 0
                        ? const ValueKey('dev_onboarding_welcome_prelude')
                        : step == 1
                        ? const ValueKey('dev_onboarding_verification_intro')
                        : ValueKey('dev_opening_body_${step - 1}'),
                  )
                  .hitTestable(),
              findsOneWidget,
            );
            expect(find.byType(RoleSelectionScreen), findsNothing);
            if (step == 0) {
              expect(
                find.byKey(const ValueKey('dev_onboarding_story_dot_0')),
                findsNothing,
              );
              expect(find.text('1 / 4'), findsNothing);
              await tester.pump(const Duration(seconds: 3));
              await tester.pumpAndSettle();
              await tester.tap(
                find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
              );
            } else if (step == 1) {
              expect(find.text('1 / 4'), findsOneWidget);
              for (var dot = 0; dot < 4; dot++) {
                expect(
                  find.byKey(ValueKey('dev_onboarding_story_dot_$dot')),
                  findsOneWidget,
                );
              }
              final forward = find.byKey(
                const ValueKey('dev_onboarding_verification_continue'),
              );
              expect(tester.widget<IconButton>(forward).onPressed, isNotNull);
              await tester.tap(forward);
            } else if (step < 4) {
              await tester.tap(find.byKey(const ValueKey('dev_opening_next')));
            } else {
              await tester.tap(
                find.byKey(const ValueKey('dev_onboarding_story_continue')),
              );
            }
            await tester.pumpAndSettle();
          }
          expect(find.byType(RoleSelectionScreen), findsOneWidget);
          expect(
            tester
                .widget<RoleSelectionScreen>(find.byType(RoleSelectionScreen))
                .devPreview,
            isTrue,
          );
          await tester.tap(
            find.byKey(
              ValueKey(
                guardian ? 'role-select-guardian' : 'role-select-seeker',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(RoleSelectionScreen), findsOneWidget);
          expect(
            find.byKey(const ValueKey('role-choice-continue')),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const ValueKey('role-choice-continue')));
          await tester.pumpAndSettle();
          if (guardian) {
            expect(
              find.byType(GuardianOnboardingOverviewScreen),
              findsOneWidget,
            );
            expect(
              tester
                  .widget<GuardianOnboardingOverviewScreen>(
                    find.byType(GuardianOnboardingOverviewScreen),
                  )
                  .devPreview,
              isTrue,
            );
            await tester.tap(
              find.byKey(const ValueKey('account_path_overview_continue')),
            );
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<WaliOnboardingFlow>(find.byType(WaliOnboardingFlow))
                  .devPreview,
              isTrue,
            );
          } else {
            expect(
              tester
                  .widget<OnboardingFlow>(find.byType(OnboardingFlow))
                  .devPreview,
              isTrue,
            );
          }
          expect(tester.takeException(), isNull);

          expect(find.byKey(const ValueKey('dev_signup_close')), findsNothing);
          expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isTrue);
          expect(ZyraDevSurfaceCoordinator.instance.closeOnboarding(), isTrue);
          await tester.pumpAndSettle();
          expect(navigatorKey.currentState!.canPop(), isTrue);
          expect(
            ZyraDevSurfaceCoordinator.instance.canCloseOnboarding,
            isFalse,
          );
          expect(find.byType(DeveloperAccessScreen), findsOneWidget);
          expect(
            find.byKey(const ValueKey('dev_access_signup')),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    for (final action in const [
      'dev_access_seeker',
      'dev_access_seeker_basic',
      'dev_access_guardian',
      'dev_access_guardian_basic',
      'dev_access_signup',
    ]) {
      testWidgets('$action refuses a newly revoked Founder claim', (
        tester,
      ) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        const founder = User(
          id: '11111111-1111-4111-8111-111111111111',
          appMetadata: {'zyra_role': 'founder'},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-09-14T00:00:00Z',
        );
        const member = User(
          id: '11111111-1111-4111-8111-111111111111',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-09-14T00:00:00Z',
        );
        User current = founder;
        var refreshCalls = 0;
        ZyraDeveloperAccess.configureAuthorizationForTesting(
          variant: ZyraAppVariant.production,
          currentUser: () => current,
          refreshSession: () async {
            refreshCalls++;
            if (refreshCalls > 1) current = member;
            return current;
          },
          founderIdentityMatches: (user) =>
              user.appMetadata['zyra_role'] == 'founder',
        );
        await tester.pumpWidget(
          const MaterialApp(home: DeveloperAccessScreen()),
        );
        await tester.pumpAndSettle();
        expect(ZyraDeveloperAccess.isAuthorizedOperator, isTrue);

        final actionFinder = find.byKey(ValueKey(action));
        await tester.ensureVisible(actionFinder);
        await tester.pump();
        await tester.tap(actionFinder);
        await tester.pumpAndSettle();

        expect(refreshCalls, 2);
        expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
        expect(find.byType(HomeShell), findsNothing);
        expect(find.byType(WaliHomeShell), findsNothing);
        expect(
          find.byKey(const ValueKey('dev_access_signup_roles')),
          findsNothing,
        );
        expect(find.byType(DevSignUpProcessScreen), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    for (final guardian in [false, true]) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} gender switch survives removal of '
        'its overlay control during fresh authorization',
        (tester) async {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          const founder = User(
            id: '11111111-1111-4111-8111-111111111111',
            appMetadata: {'zyra_role': 'founder'},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-09-14T00:00:00Z',
          );
          final freshSession = Completer<User?>();
          ZyraDeveloperAccess.configureAuthorizationForTesting(
            variant: ZyraAppVariant.production,
            currentUser: () => founder,
            refreshSession: () => freshSession.future,
            founderIdentityMatches: (user) =>
                user.appMetadata['zyra_role'] == 'founder',
          );
          await ZyraDeveloperAccess.acceptFreshTokenRefresh(founder);
          final coordinator = ZyraDevSurfaceCoordinator.instance;
          final owner = Object();
          if (guardian) {
            coordinator.attachGuardian(owner, (_) {});
          } else {
            coordinator.attachSeeker(owner, (_) {});
          }
          BuildContext? initiatingContext;
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ListenableBuilder(
                  listenable: ZyraDeveloperAccess.authorizationChanges,
                  builder: (context, _) =>
                      ZyraDeveloperAccess.canUseDeveloperTools
                      ? Builder(
                          builder: (controlContext) => TextButton(
                            onPressed: () {
                              initiatingContext = controlContext;
                              unawaited(
                                ZyraDevLocalPreview.selectGender(
                                  controlContext,
                                  'female',
                                ),
                              );
                            },
                            child: const Text('Preview female'),
                          ),
                        )
                      : const Text('Refreshing access'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Preview female'));
          await tester.pump();

          expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
          expect(initiatingContext!.mounted, isFalse);
          expect(find.text('Refreshing access'), findsOneWidget);

          freshSession.complete(founder);
          await tester.pumpAndSettle();

          expect(ZyraDeveloperAccess.isAuthorizedOperator, isTrue);
          expect(
            find.byType(guardian ? WaliHomeShell : HomeShell),
            findsOneWidget,
          );
          expect(AppState.instance.gender, 'female');
          expect(AppState.instance.name, guardian ? 'Khadija' : 'Maryam');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  });
}
