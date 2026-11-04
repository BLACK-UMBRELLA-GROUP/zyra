import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_dev_local_preview.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/queue44_gold_fixture.dart';
import 'support/queue44_onboarding_opening_fixture.dart';

const _founder = User(
  id: '11111111-1111-4111-8111-111111111111',
  appMetadata: {'zyra_role': 'founder'},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-09-14T00:00:00Z',
);
const _member = User(
  id: '11111111-1111-4111-8111-111111111111',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-09-14T00:00:00Z',
);

Future<ZyraLocalPreviewPresentation> _prepare({
  required bool guardian,
  bool premium = true,
  String gender = 'male',
}) async {
  final preparation = await ZyraDevLocalPreview.prepare(
    current: () => true,
    isWali: guardian,
    premium: premium,
    gender: gender,
  );
  expect(preparation, isNotNull);
  final presentation = preparation!.commit();
  expect(presentation, isNotNull);
  return presentation!;
}

Widget _screen(ZyraLocalPreviewPresentation recipe) => ViewRequestDraftScreen(
  key: UniqueKey(),
  ownerGeneration: recipe.generation,
  ownerId: recipe.ownerId,
  restoreLocation: false,
  initialGuardianRole: recipe.guardian,
  initialSeekerBasic: !recipe.premium,
  initialGuardianBasic: !recipe.premium,
);

Future<void> _render(
  WidgetTester tester,
  ZyraLocalPreviewPresentation recipe, {
  double textScale = 1,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  final navigator = navigatorKey ?? GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [ZyraPreviewRouteObserver()],
      builder: (context, child) => ZyraAccountSessionHost(
        navigatorKey: navigator,
        authStateChangesOverride: const Stream<AuthState>.empty(),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
      home: _screen(recipe),
    ),
  );
  await tester.pumpAndSettle();
}

void _noRetiredEntry() {
  for (final key in const [
    'dev_access_seeker',
    'dev_access_guardian',
    'dev_access_signup',
    'dev_controls_hold_surface',
    'dev_controls_overlay',
  ]) {
    expect(find.byKey(ValueKey(key)), findsNothing);
  }
}

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
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
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
      testWidgets(
        'planned member navigation has five destinations without access pills at ${viewport.size.width} width '
        'and ${viewport.textScale} text scale',
        (tester) async {
          tester.view.physicalSize = viewport.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _render(
            tester,
            await _prepare(guardian: false),
            textScale: viewport.textScale,
          );
          final navigation = tester.widget<ZyraShellNavigation>(
            find.byType(ZyraShellNavigation),
          );
          expect(
            navigation.items.map((item) => item.label),
            orderedEquals([
              'Profiles',
              'Journey',
              'My ZYRA',
              'Guardian',
              'Profile',
            ]),
          );
          expect(navigation.interactionEnabled, isTrue);
          for (var index = 0; index < 5; index++) {
            final item = find.byKey(ValueKey('floating-nav-item-$index'));
            expect(item, findsOneWidget);
            final semantics = tester.widget<Semantics>(item).properties;
            expect(semantics.button, isTrue);
            expect(semantics.enabled, isTrue);
            expect(semantics.onTap, isNotNull);
            final rect = tester.getRect(item);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(viewport.size.width));
          }
          _noRetiredEntry();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    for (final guardian in [false, true]) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} member Appearance route returns without signout or reset',
        (tester) async {
          final navigator = GlobalKey<NavigatorState>();
          final recipe = await _prepare(guardian: guardian);
          await _render(tester, recipe, navigatorKey: navigator);
          final original = tester.state(find.byType(ViewRequestDraftScreen));
          final state = AppState.instance;
          final before = (
            state.name,
            state.gender,
            state.plan,
            state.waliHasWaliOne,
            ZyraAccountState.generation,
            Supabase.instance.client.auth.currentSession,
          );
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => PersonalisationScreen.preview(
                canAct: () =>
                    ZyraDeveloperAccess.canUseDeveloperTools &&
                    recipe.generation == ZyraAccountState.generation,
                palette: ZyraDevPalette.ivory,
                hapticLevel: ZyraHapticLevel.medium,
                goldEnabled: true,
                onHapticChanged: (_) {},
                onGoldChanged: (_) {},
                embedded: false,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(PersonalisationScreen), findsOneWidget);
          _noRetiredEntry();
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
          expect(
            tester.state(find.byType(ViewRequestDraftScreen)),
            same(original),
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
                'Member navigation makes no OAuth, membership or signout request.',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      for (final gender in const ['male', 'female']) {
        testWidgets(
          'main local $gender ${guardian ? 'Guardian' : 'Seeker'} preview opens its shell',
          (tester) async {
            final recipe = await _prepare(guardian: guardian, gender: gender);
            await _render(tester, recipe);
            final screen = tester.widget<ViewRequestDraftScreen>(
              find.byType(ViewRequestDraftScreen),
            );
            expect(screen.initialGuardianRole, guardian);
            expect(recipe.guardian, guardian);
            expect(recipe.premium, isTrue);
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
            expect(httpCalls, 0);
            _noRetiredEntry();
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }

      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} Basic stays a local sample on gender change',
        (tester) async {
          await _render(
            tester,
            await _prepare(guardian: guardian, premium: false),
          );
          expect(AppState.instance.plan, ZyraPlan.basic);
          expect(AppState.instance.waliHasWaliOne, isFalse);
          expect(
            ZyraDevLocalPreview.basicMembershipPreviewLabel(guardian: guardian),
            '${guardian ? 'Guardian' : 'Seeker'} Basic · Preview',
          );
          await _render(
            tester,
            await _prepare(
              guardian: guardian,
              premium: false,
              gender: 'female',
            ),
          );
          expect(AppState.instance.gender, 'female');
          expect(AppState.instance.plan, ZyraPlan.basic);
          expect(AppState.instance.waliHasWaliOne, isFalse);
          final screen = tester.widget<ViewRequestDraftScreen>(
            find.byType(ViewRequestDraftScreen),
          );
          expect(
            guardian ? screen.initialGuardianBasic : screen.initialSeekerBasic,
            isTrue,
          );
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
          ZyraInternalPreviewClient.beginPreview();
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigatorKey,
              home: const Scaffold(body: Text('Member origin')),
            ),
          );
          navigatorKey.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => Queue44WelcomeFixture(
                devPreview: true,
                devIntroductionBuilder: (context) => OnboardingOpeningFixture(
                  direction: ZyraOnboardingDirection.luma,
                  welcomeName: 'Adam',
                  onContinue: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const RoleSelectionScreen(devPreview: true),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(WelcomeScreen), findsOneWidget);
          expect(
            tester.widget<WelcomeScreen>(find.byType(WelcomeScreen)).devPreview,
            isTrue,
          );
          _noRetiredEntry();
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

          navigatorKey.currentState!.popUntil((route) => route.isFirst);
          await tester.pumpAndSettle();
          expect(find.text('Member origin'), findsOneWidget);
          expect(ZyraInternalPreviewClient.isActive, isTrue);
          expect(httpCalls, 0);
          _noRetiredEntry();
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    for (final command in const [
      (name: 'Seeker', guardian: false, premium: true),
      (name: 'Seeker Basic', guardian: false, premium: false),
      (name: 'Guardian', guardian: true, premium: true),
      (name: 'Guardian Basic', guardian: true, premium: false),
      (name: 'Onboarding', guardian: false, premium: false),
    ]) {
      testWidgets(
        '${command.name} fixture entry refuses a newly revoked Founder claim',
        (tester) async {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          User current = _founder;
          var refreshCalls = 0;
          ZyraDeveloperAccess.configureAuthorizationForTesting(
            variant: ZyraAppVariant.production,
            currentUser: () => current,
            refreshSession: () async {
              refreshCalls++;
              if (refreshCalls > 1) current = _member;
              return current;
            },
            founderIdentityMatches: (user) =>
                user.appMetadata['zyra_role'] == 'founder',
          );
          expect(
            await ZyraDeveloperAccess.refreshCurrentAuthorization(),
            isTrue,
          );
          expect(ZyraDeveloperAccess.isAuthorizedOperator, isTrue);
          if (command.name == 'Onboarding') {
            expect(
              await ZyraDeveloperAccess.refreshCurrentAuthorization(),
              isFalse,
            );
            await tester.pumpWidget(
              const MaterialApp(home: Queue44WelcomeFixture(devPreview: true)),
            );
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('welcome_preview_denied')),
              findsOneWidget,
            );
            expect(find.byKey(const ValueKey('welcome_google')), findsNothing);
            expect(find.byType(RoleSelectionScreen), findsNothing);
            expect(find.byType(OnboardingFlow), findsNothing);
          } else {
            final preparation = await ZyraDevLocalPreview.prepare(
              current: () => true,
              isWali: command.guardian,
              premium: command.premium,
            );
            expect(preparation, isNull);
            await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: Text('Member origin'))),
            );
          }
          expect(refreshCalls, 2);
          expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
          expect(find.byType(ViewRequestDraftScreen), findsNothing);
          expect(find.byType(HomeShell), findsNothing);
          expect(find.byType(WaliHomeShell), findsNothing);
          expect(httpCalls, 0);
          _noRetiredEntry();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    for (final guardian in [false, true]) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} code fixture entry survives disposal of its initiating child during fresh authorization',
        (tester) async {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          final freshSession = Completer<User?>();
          ZyraDeveloperAccess.configureAuthorizationForTesting(
            variant: ZyraAppVariant.production,
            currentUser: () => _founder,
            refreshSession: () => freshSession.future,
            founderIdentityMatches: (user) =>
                user.appMetadata['zyra_role'] == 'founder',
          );
          await ZyraDeveloperAccess.acceptFreshTokenRefresh(_founder);
          BuildContext? initiatingContext;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ListenableBuilder(
                  listenable: ZyraDeveloperAccess.authorizationChanges,
                  builder: (context, _) =>
                      ZyraDeveloperAccess.canUseDeveloperTools
                      ? Builder(
                          builder: (memberContext) {
                            initiatingContext = memberContext;
                            return const Text('Member page');
                          },
                        )
                      : const Text('Refreshing access'),
                ),
              ),
            ),
          );
          final context = initiatingContext!;
          final route = ModalRoute.of(context);
          final operation = ZyraDevLocalPreview.open(
            context,
            isWali: guardian,
            gender: 'female',
          );
          await tester.pump();
          expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
          expect(context.mounted, isFalse);
          expect(route!.isCurrent, isTrue);
          expect(find.text('Refreshing access'), findsOneWidget);
          freshSession.complete(_founder);
          await tester.pumpAndSettle();
          expect(await operation, isTrue);
          expect(ZyraDeveloperAccess.isAuthorizedOperator, isTrue);
          expect(
            find.byType(guardian ? WaliHomeShell : HomeShell),
            findsOneWidget,
          );
          expect(AppState.instance.gender, 'female');
          expect(AppState.instance.name, guardian ? 'Khadija' : 'Maryam');
          expect(httpCalls, 0);
          _noRetiredEntry();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  });
}
