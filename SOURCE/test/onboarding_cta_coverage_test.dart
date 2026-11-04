import 'support/queue44_signup_flow_driver.dart';
import 'support/queue44_signup_flow_fixture.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'support/queue44_onboarding_interaction_fixture.dart';
import 'support/queue44_gold_fixture.dart';
import 'support/queue44_onboarding_story_fixture.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/screens/onboarding/transition_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

const _account = 'cta-coverage-existing-member';
const _firstNameField = ValueKey('onboarding_first_name');
const _lastNameField = ValueKey('onboarding_last_name');
const _openingThemeCount = 3;
int _networkRequests = 0;
int _ownerReads = 0;
late FakeSignupStore _store;

bool _isArrow(ZyraOnboardingAdvanceMode mode) =>
    mode == ZyraOnboardingAdvanceMode.animatedDownArrow;

Future<void> _mount(
  WidgetTester tester, {
  required ZyraOnboardingDirection direction,
  required ZyraOnboardingAdvanceMode mode,
  Size viewport = const Size(430, 932),
  double textScale = 1,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  expect(ZyraDevOnboardingInteraction.select(mode), isTrue);
  expect(
    ZyraDevOnboardingStoryNavigation.select(
      _isArrow(mode)
          ? ZyraOnboardingStoryNavigation.scrollDown
          : ZyraOnboardingStoryNavigation.tapThrough,
    ),
    isTrue,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: child!,
      ),
      home: SignupFlowFixture(initialDirection: direction),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(WelcomeScreen), findsOneWidget);
  expect(ZyraInternalPreviewClient.isActive, isTrue);
}

void _expectAction(
  WidgetTester tester,
  String key,
  ZyraOnboardingAdvanceMode mode, {
  required bool enabled,
}) {
  final action = find.byKey(ValueKey(key));
  expect(action, findsOneWidget);
  if (_isArrow(mode)) {
    final arrowFinder = tester.widget(action) is ZyraOnboardingArrowAction
        ? action
        : find.descendant(
            of: action,
            matching: find.byType(ZyraOnboardingArrowAction),
          );
    expect(arrowFinder, findsOneWidget);
    final arrow = tester.widget<ZyraOnboardingArrowAction>(arrowFinder);
    expect(arrow.active && arrow.onPressed != null, enabled);
    expect(
      find.descendant(
        of: action,
        matching: find.byKey(const ValueKey('onboarding_animated_down_arrow')),
      ),
      findsOneWidget,
    );
  } else {
    expect(
      find.descendant(
        of: action,
        matching: find.byKey(const ValueKey('onboarding_animated_down_arrow')),
      ),
      findsNothing,
    );
    final widget =
        tester.widget(action) is FilledButton ||
            tester.widget(action) is InkWell ||
            tester.widget(action) is GestureDetector
        ? tester.widget(action)
        : tester.widget(
            find
                .descendant(
                  of: action,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is FilledButton ||
                        widget is InkWell ||
                        widget is GestureDetector,
                  ),
                )
                .first,
          );
    if (widget is FilledButton) {
      expect(widget.onPressed != null, enabled);
    } else if (widget is InkWell) {
      expect(widget.onTap != null, enabled);
    } else if (widget is GestureDetector) {
      expect(widget.onTap != null, enabled);
    } else {
      fail('Unexpected primary action ${widget.runtimeType} at $key');
    }
  }
}

Future<void> _advance(WidgetTester tester, String key) async {
  if (key == 'onboarding_dev_skip') {
    await advanceSignupQuestionFromCode(tester);
    return;
  }
  final action = find.byKey(ValueKey(key));
  expect(action.hitTestable(), findsOneWidget);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _completeStoryPage(
  WidgetTester tester, {
  required ZyraOnboardingDirection direction,
  required ZyraOnboardingAdvanceMode mode,
  required int page,
}) async {
  final story = find.byKey(ValueKey('dev_opening_page_${page + 1}'));
  expect(story.hitTestable(), findsOneWidget);
  if (page == _openingThemeCount - 1 || _isArrow(mode)) {
    _expectAction(
      tester,
      'dev_onboarding_story_continue',
      ZyraOnboardingAdvanceMode.animatedDownArrow,
      enabled: true,
    );
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_story_continue')),
    );
  } else {
    await tester.tap(story);
  }
  await tester.pumpAndSettle();
}

Future<void> _enterOpeningStory(WidgetTester tester) async {
  final prelude = find.byKey(const ValueKey('dev_onboarding_welcome_prelude'));
  if (prelude.evaluate().isNotEmpty) {
    final welcomeArrow = find.byKey(
      const ValueKey('dev_onboarding_welcome_continue'),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.ensureVisible(welcomeArrow);
    await tester.pumpAndSettle();
    await tester.tap(welcomeArrow);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_onboarding_verification_intro')),
      findsOneWidget,
    );
  }
  if (find
      .byKey(const ValueKey('dev_onboarding_verification_intro'))
      .evaluate()
      .isEmpty) {
    return;
  }
  expect(
    find.byKey(const ValueKey('dev_onboarding_story_dot_0')),
    findsOneWidget,
  );
  expect(find.text('1 / 4'), findsOneWidget);
  expect(
    find.byKey(const ValueKey('dev_onboarding_story_dot_3')),
    findsOneWidget,
  );
  final sectionArrow = find.byKey(
    const ValueKey('dev_onboarding_verification_continue'),
  );
  await tester.ensureVisible(sectionArrow);
  await tester.pumpAndSettle();
  await tester.tap(sectionArrow);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('dev_opening_page_1')), findsOneWidget);
  expect(find.text('2 / 4'), findsOneWidget);
}

Future<void> _reachFirstQuestion(
  WidgetTester tester, {
  required ZyraOnboardingDirection direction,
  required ZyraOnboardingAdvanceMode mode,
  required bool guardian,
}) async {
  await _mount(tester, direction: direction, mode: mode);
  await _advance(tester, 'welcome_google');
  await _enterOpeningStory(tester);
  for (var page = 0; page < _openingThemeCount; page++) {
    expect(find.byType(OnboardingIntroductionFixture), findsOneWidget);
    expect(
      find.byKey(ValueKey('dev_opening_page_${page + 1}')),
      findsOneWidget,
    );
    await _completeStoryPage(
      tester,
      direction: direction,
      mode: mode,
      page: page,
    );
  }
  expect(find.byType(RoleSelectionScreen), findsOneWidget);
  expect(find.byKey(const ValueKey('role-choice-continue')), findsNothing);
  await _advance(
    tester,
    guardian ? 'role-select-guardian' : 'role-select-seeker',
  );
  expect(find.byType(RoleSelectionScreen), findsOneWidget);
  _expectAction(
    tester,
    'role-choice-continue',
    ZyraOnboardingAdvanceMode.animatedDownArrow,
    enabled: true,
  );
  await _advance(tester, 'role-choice-continue');
  if (guardian) {
    expect(find.byType(GuardianOnboardingOverviewScreen), findsOneWidget);
    _expectAction(
      tester,
      'account_path_overview_continue',
      mode,
      enabled: true,
    );
    await _advance(tester, 'account_path_overview_continue');
    expect(find.byType(WaliOnboardingFlow), findsOneWidget);
  } else {
    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding_welcome_continue')),
      findsNothing,
    );
    expect(find.text('First, your account.'), findsOneWidget);
    expect(find.text('Together, we’ll build four things.'), findsNothing);
    _expectAction(tester, 'onboarding_stage_continue', mode, enabled: true);
    await _advance(tester, 'onboarding_stage_continue');
  }
  expect(find.text("What's your name?"), findsOneWidget);
  expect(find.byKey(_firstNameField), findsOneWidget);
  expect(find.byKey(_lastNameField), findsOneWidget);
  expect(
    find.text('Both names will appear on your public profile.'),
    findsOneWidget,
  );
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsCtaCoverage');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneCtaCoverage')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.testReadingFontFamily = 'PoppinsCtaCoverage';
    ZyraText.testWordmarkFontFamily = 'SyneCtaCoverage';
    SharedPreferences.setMockInitialValues({
      'zyra.cached_account_owner': _account,
      'zyra.cached_first_name': 'Existing member',
      'zyra.cached_gender': 'female',
      'zyra.cached_role': 'seeker',
    });
    await Supabase.initialize(
      url: ZyraInternalFounderPolicy.approvedSupabaseUrl,
      publishableKey: 'local-widget-test',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: ZyraInternalPreviewClient(
        MockClient((_) async {
          _networkRequests++;
          return http.Response('offline test denies API requests', 403);
        }),
      ),
    );
    await ZyraLocalPrefs.init();
    await ZyraLocalPrefs.bindAccount(_account);
  });

  tearDownAll(() async {
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    await Supabase.instance.dispose();
  });

  setUp(() {
    _networkRequests = 0;
    _ownerReads = 0;
    _store = FakeSignupStore();
    ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: _store,
        backend: 'https://example.invalid',
        currentUserId: () {
          _ownerReads++;
          return _account;
        },
        isPreview: () => ZyraInternalPreviewClient.isActive,
      ),
    );
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    OnboardingFixtureController.instance.resetForTesting();
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    OnboardingFixtureController.instance.resetForTesting();
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  for (final direction in ZyraOnboardingDirection.values) {
    for (final mode in ZyraOnboardingAdvanceMode.values) {
      for (final guardian in [false, true]) {
        testWidgets(
          '${direction.name} ${mode.name} ${guardian ? 'Guardian' : 'Seeker'}: entry to validated question',
          (tester) async {
            await _reachFirstQuestion(
              tester,
              direction: direction,
              mode: mode,
              guardian: guardian,
            );
            final key = guardian
                ? 'wali_onboarding_continue'
                : 'onboarding_continue';
            await tester.enterText(find.byKey(_firstNameField), '');
            await tester.pumpAndSettle();
            _expectAction(tester, key, mode, enabled: false);
            // A disabled arrow and a disabled Continue button have the same
            // validation boundary: neither may leave the unanswered question.
            await tester.tap(find.byKey(ValueKey(key)), warnIfMissed: false);
            await tester.pump();
            expect(find.text("What's your name?"), findsOneWidget);
            await tester.enterText(find.byKey(_firstNameField), 'Amina');
            await tester.pumpAndSettle();
            _expectAction(tester, key, mode, enabled: false);
            await tester.enterText(find.byKey(_lastNameField), '   ');
            await tester.pumpAndSettle();
            _expectAction(tester, key, mode, enabled: false);
            await tester.enterText(find.byKey(_lastNameField), 'Ahmed');
            await tester.pumpAndSettle();
            _expectAction(tester, key, mode, enabled: true);
            // A valid surname cannot compensate for a missing first name.
            await tester.enterText(find.byKey(_firstNameField), '');
            await tester.pumpAndSettle();
            _expectAction(tester, key, mode, enabled: false);
            await tester.tap(find.byKey(ValueKey(key)), warnIfMissed: false);
            await tester.pump();
            expect(find.text("What's your name?"), findsOneWidget);
            await tester.enterText(find.byKey(_firstNameField), 'Amina');
            await tester.pumpAndSettle();
            _expectAction(tester, key, mode, enabled: true);
            await _advance(tester, key);
            expect(
              find.text(
                guardian ? 'When were you born?' : "What's your gender?",
              ),
              findsOneWidget,
            );
            expect(_networkRequests, 0);
            expect(_store.operations, 0);
            expect(_ownerReads, 0);
            expect(ZyraDevOnboardingInteraction.current, mode);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }

  testWidgets(
    'complete opening pages advance once with a final section arrow',
    (tester) async {
      await _mount(
        tester,
        direction: ZyraOnboardingDirection.luma,
        mode: ZyraOnboardingAdvanceMode.animatedDownArrow,
      );
      await _advance(tester, 'welcome_google');
      await _enterOpeningStory(tester);
      final story = find.byKey(const ValueKey('dev_opening_page_1'));
      expect(story.hitTestable(), findsOneWidget);
      expect(find.text('Reported from Imam Ahmad'), findsOneWidget);
      _expectAction(
        tester,
        'dev_onboarding_story_continue',
        ZyraOnboardingAdvanceMode.animatedDownArrow,
        enabled: true,
      );
      expect(find.text('2 / 4'), findsOneWidget);
      await _completeStoryPage(
        tester,
        direction: ZyraOnboardingDirection.luma,
        mode: ZyraOnboardingAdvanceMode.animatedDownArrow,
        page: 0,
      );
      expect(find.text('3 / 4'), findsOneWidget);
      for (var page = 1; page < _openingThemeCount; page++) {
        await _completeStoryPage(
          tester,
          direction: ZyraOnboardingDirection.luma,
          mode: ZyraOnboardingAdvanceMode.animatedDownArrow,
          page: page,
        );
      }
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(_networkRequests, 0);
      expect(_store.operations, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('tap-through story has a down-arrow section handoff', (
    tester,
  ) async {
    await _mount(
      tester,
      direction: ZyraOnboardingDirection.luma,
      mode: ZyraOnboardingAdvanceMode.continueButton,
    );
    await _advance(tester, 'welcome_google');
    await _enterOpeningStory(tester);
    for (var page = 0; page < _openingThemeCount; page++) {
      expect(
        find.byKey(const ValueKey('dev_onboarding_story_continue')),
        page == _openingThemeCount - 1 ? findsOneWidget : findsNothing,
      );
      await _completeStoryPage(
        tester,
        direction: ZyraOnboardingDirection.luma,
        mode: ZyraOnboardingAdvanceMode.continueButton,
        page: page,
      );
    }
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(_networkRequests, 0);
    expect(_store.operations, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('compact large-text downward story remains readable', (
    tester,
  ) async {
    await _mount(
      tester,
      direction: ZyraOnboardingDirection.luma,
      mode: ZyraOnboardingAdvanceMode.animatedDownArrow,
      viewport: const Size(320, 568),
      textScale: 1.4,
    );
    await _advance(tester, 'welcome_google');
    await _enterOpeningStory(tester);
    for (var page = 0; page < _openingThemeCount; page++) {
      await _completeStoryPage(
        tester,
        direction: ZyraOnboardingDirection.luma,
        mode: ZyraOnboardingAdvanceMode.animatedDownArrow,
        page: page,
      );
    }
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final direction in ZyraOnboardingDirection.values) {
    testWidgets(
      '${direction.name} shows complete stories before one tap and final arrow',
      (tester) async {
        await _mount(
          tester,
          direction: direction,
          mode: ZyraOnboardingAdvanceMode.animatedDownArrow,
        );
        await _advance(tester, 'welcome_google');
        await _enterOpeningStory(tester);
        for (var page = 0; page < _openingThemeCount; page++) {
          await _completeStoryPage(
            tester,
            direction: direction,
            mode: ZyraOnboardingAdvanceMode.animatedDownArrow,
            page: page,
          );
          if (page < _openingThemeCount - 1) {
            expect(find.text('${page + 3} / 4'), findsOneWidget);
          } else {
            expect(
              find.byKey(const ValueKey('dev_opening_page_3')),
              findsNothing,
            );
          }
        }
        expect(find.byType(RoleSelectionScreen), findsOneWidget);
        expect(_networkRequests, 0);
        expect(_store.operations, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'switching advance style mid-question retains entered data and validation',
    (tester) async {
      await _reachFirstQuestion(
        tester,
        direction: ZyraOnboardingDirection.luma,
        mode: ZyraOnboardingAdvanceMode.continueButton,
        guardian: false,
      );
      const key = 'onboarding_continue';
      await tester.enterText(find.byKey(_firstNameField), '');
      await tester.pumpAndSettle();
      _expectAction(
        tester,
        key,
        ZyraOnboardingAdvanceMode.continueButton,
        enabled: false,
      );
      await tester.enterText(find.byKey(_lastNameField), 'Ahmed');
      await tester.pumpAndSettle();
      _expectAction(
        tester,
        key,
        ZyraOnboardingAdvanceMode.continueButton,
        enabled: false,
      );
      expect(
        ZyraDevOnboardingInteraction.select(
          ZyraOnboardingAdvanceMode.animatedDownArrow,
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.byType(SignupFlowFixture), findsOneWidget);
      expect(find.text("What's your name?"), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(_lastNameField)).controller?.text,
        'Ahmed',
      );
      expect(find.byType(OnboardingIntroductionFixture), findsNothing);
      _expectAction(
        tester,
        key,
        ZyraOnboardingAdvanceMode.animatedDownArrow,
        enabled: false,
      );
      await tester.enterText(find.byKey(_firstNameField), 'Amina');
      await tester.pumpAndSettle();
      _expectAction(
        tester,
        key,
        ZyraOnboardingAdvanceMode.animatedDownArrow,
        enabled: true,
      );
      await _advance(tester, key);
      expect(find.text("What's your gender?"), findsOneWidget);
      expect(_networkRequests, 0);
      expect(_store.operations, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final mode in ZyraOnboardingAdvanceMode.values) {
    testWidgets('${mode.name} Seeker handoff CTA reaches profile chapter', (
      tester,
    ) async {
      await _reachFirstQuestion(
        tester,
        direction: ZyraOnboardingDirection.luma,
        mode: mode,
        guardian: false,
      );
      for (var question = 0; question < 4; question++) {
        await _advance(tester, 'onboarding_dev_skip');
      }
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(find.byType(InitialIdentityCheckScreen), findsNothing);
      await _advance(tester, 'signup_membership_basic');
      _expectAction(tester, 'signup_membership_continue', mode, enabled: true);
      await _advance(tester, 'signup_membership_continue');
      expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
      await _advance(tester, 'identity-consent-agree');
      await verifyIdentityFromCode(tester);
      if (_isArrow(mode)) {
        _expectAction(tester, 'identity-continue', mode, enabled: true);
      } else {
        expect(find.byKey(const ValueKey('identity-continue')), findsOneWidget);
      }
      await _advance(tester, 'identity-continue');
      expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Continue profile setup'),
        findsOneWidget,
      );
      await _advance(tester, 'seeker_post_identity_continue_setup');
      expect(find.byType(SeekerOnboardingOverviewScreen), findsOneWidget);
      for (var item = 0; item < 4; item++) {
        await tester.tap(
          find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
        );
        await tester.pumpAndSettle();
      }
      _expectAction(tester, 'onboarding_welcome_continue', mode, enabled: true);
      await _advance(tester, 'onboarding_welcome_continue');
      _expectAction(tester, 'onboarding_stage_continue', mode, enabled: true);
      await _advance(tester, 'onboarding_stage_continue');
      expect(find.byType(Chapter2Flow), findsOneWidget);
      expect(_networkRequests, 0);
      expect(_store.operations, 0);
      expect(_ownerReads, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      '${mode.name} Guardian identity and transition CTAs reach code',
      (tester) async {
        await _reachFirstQuestion(
          tester,
          direction: ZyraOnboardingDirection.luma,
          mode: mode,
          guardian: true,
        );
        for (var question = 0; question < 5; question++) {
          await _advance(tester, 'onboarding_dev_skip');
        }
        expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
        expect(find.byType(InitialIdentityCheckScreen), findsNothing);
        await _advance(tester, 'signup_membership_basic');
        _expectAction(
          tester,
          'signup_membership_continue',
          mode,
          enabled: true,
        );
        await _advance(tester, 'signup_membership_continue');
        expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
        await _advance(tester, 'identity-consent-agree');
        await verifyIdentityFromCode(tester);
        if (_isArrow(mode)) {
          _expectAction(tester, 'identity-continue', mode, enabled: true);
        } else {
          expect(
            find.byKey(const ValueKey('identity-continue')),
            findsOneWidget,
          );
        }
        final identityContinue = find.byKey(
          const ValueKey('identity-continue'),
        );
        await tester.ensureVisible(identityContinue);
        await tester.pumpAndSettle();
        await tester.tap(identityContinue);
        // The Guardian transition owns a repeating chevron animation in the
        // Continue variant; a bounded pump avoids waiting for it to settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(TransitionScreen), findsOneWidget);
        if (_isArrow(mode)) {
          _expectAction(tester, 'transition_continue', mode, enabled: true);
          await tester.tap(find.byKey(const ValueKey('transition_continue')));
        } else {
          final button = find.descendant(
            of: find.byType(TransitionScreen),
            matching: find.text('Continue'),
          );
          await tester.ensureVisible(button);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(button);
        }
        await tester.pumpAndSettle();
        expect(find.byType(ZyraCodeScreen), findsOneWidget);
        expect(_networkRequests, 0);
        expect(_store.operations, 0);
        expect(_ownerReads, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
