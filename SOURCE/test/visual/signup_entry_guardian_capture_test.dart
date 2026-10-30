// Queue 10: actual shared entry and Guardian signup, with bounded offline
// presenter fixtures for transient states. No OAuth success or real ID check.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/screens/onboarding/transition_screen.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import 'package:zyra/widgets/zyra_signup_first_photo_card.dart';

import 'signup_capture_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Widget _onboarding(Widget child) => OnboardingPreviewStyle(
  directionName: 'luma',
  child: ZyraOnboardingArrowScope(enabled: true, child: child),
);

ScrollPosition? _pageScroll(WidgetTester tester) {
  final positions = tester
      .stateList<ScrollableState>(find.byType(Scrollable).hitTestable())
      .where((state) => ModalRoute.of(state.context)?.isCurrent == true)
      .map((state) => state.position)
      .where(
        (position) =>
            position.axis == Axis.vertical && position.hasContentDimensions,
      )
      .toList();
  if (positions.isEmpty) return null;
  positions.sort((a, b) => b.viewportDimension.compareTo(a.viewportDimension));
  return positions.first;
}

Future<void> _top(SignupCaptureHarness h) async {
  final position = _pageScroll(h.tester);
  if (position != null) position.jumpTo(position.minScrollExtent);
  await h.flush(const Duration(milliseconds: 500));
}

Future<void> _page(
  SignupCaptureHarness h,
  int order,
  String screen,
  String state, {
  required String reached,
}) async {
  await _top(h);
  await h.capture(order, screen, state, reached: reached);
  final position = _pageScroll(h.tester);
  if (position == null || position.maxScrollExtent <= 1) return;
  final maximum = position.maxScrollExtent;
  final stride = math.max(1.0, position.viewportDimension * .72);
  var frame = 1;
  for (var offset = math.min(stride, maximum); ; offset += stride) {
    final target = math.min(offset, maximum);
    position.jumpTo(target);
    await h.flush();
    await h.capture(
      order,
      screen,
      '${state}_scroll_${frame.toString().padLeft(2, '0')}',
      reached:
          '$reached; actual current-route vertical page scroll to '
          '${target.toStringAsFixed(1)} of '
          '${maximum.toStringAsFixed(1)} logical px',
    );
    frame++;
    if (target >= maximum) break;
    expect(frame, lessThan(100));
  }
  await _top(h);
}

Future<void> _currentRoute<T extends Widget>(SignupCaptureHarness h) async {
  var ready = false;
  for (var frame = 0; frame < 30; frame++) {
    final owners = find.byType(T).evaluate().toList();
    if (owners.length == 1) {
      final route = ModalRoute.of(owners.single);
      ready =
          route?.isCurrent == true &&
          route?.animation?.status == AnimationStatus.completed;
      if (ready) break;
    }
    await h.flush(const Duration(milliseconds: 100));
  }
  expect(find.byType(T), findsOneWidget);
  expect(
    ready,
    isTrue,
    reason: 'The actual $T route must own the completed incoming frame.',
  );
}

Future<void> _readingFrame(SignupCaptureHarness h) async {
  // Complete the production entrance and the welcome's three-second reading
  // delay. Successive bounded frames let the entrance's asynchronous finish
  // schedule its later reading timer; two large pumps can start that timer
  // only at the end of the second pump. Looping arrow/gold cues may stay live.
  for (var frame = 0; frame < 14; frame++) {
    await h.flush(const Duration(milliseconds: 200));
  }
}

Future<void> _welcomeAsset(WidgetTester tester) async {
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/auth/google_g_logo.png'),
      tester.element(find.byType(WelcomeScreen)),
    ),
  );
  await tester.pump();
}

Future<void> _entry(
  SignupCaptureHarness h, {
  required bool capture,
  required bool guardian,
}) async {
  final tester = h.tester;
  await h.mount(const DevSignUpProcessScreen());
  expect(find.byType(WelcomeScreen), findsOneWidget);
  expect(ZyraInternalPreviewClient.isActive, isTrue);
  expect(
    ZyraDevOnboardingInteraction.current,
    ZyraOnboardingAdvanceMode.animatedDownArrow,
  );
  await _welcomeAsset(tester);
  if (capture) {
    await _page(
      h,
      2,
      'welcome',
      'normal',
      reached:
          'Actual protected signup entry; local provider controls, iOS order.',
    );
  }
  await h.tap('welcome_apple');
  await _readingFrame(h);
  expect(_key('dev_onboarding_welcome_prelude'), findsOneWidget);
  if (capture) {
    await _page(
      h,
      3,
      'welcome_prelude',
      'normal',
      reached:
          'Actual local Apple control, then complete production reading delay.',
    );
  }
  await h.tap('dev_onboarding_welcome_continue');
  await _readingFrame(h);
  expect(_key('dev_onboarding_verification_intro'), findsOneWidget);
  if (capture) {
    await _page(
      h,
      4,
      'verification_intro',
      'normal',
      reached: 'Actual welcome down arrow; no provider or identity request.',
    );
  }
  await h.tap('dev_onboarding_verification_continue');
  await _readingFrame(h);
  for (var page = 1; page <= 3; page++) {
    expect(_key('dev_opening_page_$page'), findsOneWidget);
    if (capture) {
      await _page(
        h,
        page + 4,
        'opening_story_$page',
        'normal',
        reached:
            'Actual Luma opening story page $page of three after verification.',
      );
    }
    await h.tap(
      page == 3 ? 'dev_onboarding_story_continue' : 'dev_opening_page_$page',
    );
    await _readingFrame(h);
  }
  expect(find.byType(RoleSelectionScreen), findsOneWidget);
  if (capture) {
    await _page(
      h,
      8,
      'role_choice',
      'empty',
      reached:
          'Actual final introduction arrow opens the unselected role choice.',
    );
  }
  await h.tap(guardian ? 'role-select-guardian' : 'role-select-seeker');
  final continueAction = _key('role-choice-continue');
  for (var frame = 0; frame < 8; frame++) {
    if (continueAction.evaluate().isNotEmpty &&
        tester.widget<ZyraOnboardingArrowAction>(continueAction).active) {
      break;
    }
    await h.flush(const Duration(milliseconds: 150));
  }
  expect(
    tester.widget<ZyraOnboardingArrowAction>(continueAction).active,
    isTrue,
    reason: 'The actual role selection must finish its focus animation.',
  );
  if (capture) {
    await _page(
      h,
      8,
      'role_choice',
      'selected',
      reached:
          'Actual ${guardian ? 'Guardian' : 'Seeker'} choice, before Continue.',
    );
  }
}

Future<void> _dob(
  SignupCaptureHarness h,
  String value, {
  bool capturePicker = false,
}) async {
  final tester = h.tester;
  await h.tapFinder(find.byIcon(Icons.calendar_today_outlined));
  expect(find.byType(DatePickerDialog), findsOneWidget);
  if (capturePicker) {
    await _page(
      h,
      11,
      'date_picker',
      'normal',
      reached:
          'Actual date-of-birth field opens the production Material date picker.',
    );
  }
  await h.tapFinder(find.byTooltip('Switch to input'));
  final field = find.descendant(
    of: find.byType(DatePickerDialog),
    matching: find.byType(TextField),
  );
  expect(field, findsOneWidget);
  await tester.enterText(field, value);
  await h.flush();
  await h.tapFinder(find.text('OK'));
  expect(find.byType(DatePickerDialog), findsNothing);
}

Future<void> _photoQuestion(
  SignupCaptureHarness h,
  ZyraPhotoBatchRunner runner,
) async {
  await h.mount(
    _onboarding(WaliOnboardingFlow(devPreview: true, photoRunner: runner)),
  );
  for (var question = 0; question < 4; question++) {
    await h.tap('onboarding_dev_skip');
  }
  expect(_key('guardian_signup_first_photo_question'), findsOneWidget);
}

Future<void> _guardianFlow(SignupCaptureHarness h) async {
  final tester = h.tester;
  await _entry(h, capture: false, guardian: true);
  await h.tap('role-choice-continue');
  for (
    var frame = 0;
    frame < 8 &&
        find.byType(GuardianOnboardingOverviewScreen).evaluate().isEmpty;
    frame++
  ) {
    await h.flush(const Duration(milliseconds: 150));
  }
  expect(find.byType(GuardianOnboardingOverviewScreen), findsOneWidget);
  await _readingFrame(h);
  await _page(
    h,
    9,
    'guardian_overview',
    'normal',
    reached: 'Actual Guardian choice and Continue in the full entry flow.',
  );
  await h.tap('account_path_overview_continue');
  expect(find.byType(WaliOnboardingFlow), findsOneWidget);
  await _page(
    h,
    10,
    'name',
    'empty',
    reached: 'Actual Guardian setup begins with empty first and last names.',
  );
  await tester.enterText(_key('onboarding_first_name'), 'Hassan');
  await tester.enterText(_key('onboarding_last_name'), 'Rahman');
  FocusManager.instance.primaryFocus?.unfocus();
  await h.flush();
  await _page(
    h,
    10,
    'name',
    'filled',
    reached:
        'Real name fields filled with fictional local names; keyboard dismissed.',
  );
  await h.tap('wali_onboarding_continue');
  expect(find.text('When were you born?'), findsOneWidget);
  await _page(
    h,
    11,
    'date_of_birth',
    'empty',
    reached: 'Actual question 2 after the name Continue arrow.',
  );
  await _dob(h, '01/01/2012', capturePicker: true);
  expect(
    find.text("You'll need to be 18 or over to continue."),
    findsOneWidget,
  );
  await _page(
    h,
    11,
    'date_of_birth',
    'error',
    reached:
        'Actual date picker accepted an under-18 date; existing validation refuses Continue.',
  );
  await _dob(h, '01/01/1981');
  await _page(
    h,
    11,
    'date_of_birth',
    'selected',
    reached: 'Actual date picker selects fictional adult date 1 January 1981.',
  );
  await h.tap('wali_onboarding_continue');
  expect(_key('guardian_gender_male'), findsOneWidget);
  await _page(
    h,
    12,
    'gender',
    'empty',
    reached: 'Actual question 3 before selecting an answer.',
  );
  await h.tap('guardian_gender_male');
  await _page(
    h,
    12,
    'gender',
    'male_selected',
    reached: 'Actual Male choice; used for the local Guardian traversal.',
  );
  await h.tap('guardian_gender_female');
  await _page(
    h,
    12,
    'gender',
    'female_selected',
    reached: 'Actual Female choice on the same screen, before restoring Male.',
  );
  await h.tap('guardian_gender_male');
  await h.tap('wali_onboarding_continue');
  expect(_key('guardian_relationship_Father'), findsOneWidget);
  await _page(
    h,
    13,
    'relationship',
    'empty',
    reached:
        'Actual question 4; Male relationship choices, no answer selected.',
  );
  await h.tap('guardian_relationship_Father');
  await _page(
    h,
    13,
    'relationship',
    'selected',
    reached: 'Actual Father choice, before Continue.',
  );
  await h.tap('wali_onboarding_continue');
  expect(_key('guardian_signup_first_photo_question'), findsOneWidget);
  await _page(
    h,
    14,
    'photo',
    'empty',
    reached:
        'Actual required Guardian photo question; no picker or upload started.',
  );
  await h.tap('onboarding_dev_skip');
  expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
  await _page(
    h,
    15,
    'membership',
    'empty',
    reached:
        'Existing local photo Skip fixture advances to the actual membership screen.',
  );
  for (final choice in ['basic', 'one', 'family']) {
    await h.tap('signup_membership_$choice');
    await _page(
      h,
      15,
      'membership',
      '${choice}_selected',
      reached:
          'Actual $choice membership card, no purchase or entitlement action.',
    );
    if (choice == 'family') {
      await h.tap('signup_family_seekers_add');
      await _page(
        h,
        15,
        'membership',
        'family_estimate',
        reached:
            'Actual Family selector adds one Seeker to the required Guardian place; local estimate.',
      );
    }
  }
  await h.tap('signup_membership_basic');
  await h.tap('signup_membership_continue');
  await _currentRoute<InitialIdentityCheckScreen>(h);
  await _page(
    h,
    16,
    'identity_check',
    'consent',
    reached:
        'Actual Basic Continue enters the local mandatory identity consent screen; no real check.',
  );
  // The dedicated identity-state capture suite owns all result/privacy and
  // transient variants. This path uses only the existing local DEV handoff.
  await h.tap('identity_dev_skip');
  await _currentRoute<TransitionScreen>(h);
  await _page(
    h,
    17,
    'guardian_responsibilities',
    'normal',
    reached:
        'Actual existing identity Skip DEV opens Support and guidance; no check or member finalization.',
  );
  await h.tap('transition_continue');
  await _currentRoute<ZyraCodeScreen>(h);
  await _page(
    h,
    18,
    'zyra_code',
    'normal',
    reached:
        'Actual responsibilities Continue opens the bounded fictional personal-code screen.',
  );
  await h.tap('local-code-qr');
  await _page(
    h,
    18,
    'zyra_code',
    'qr',
    reached:
        'Actual QR control displays the fictional signup code; no share, clipboard or camera.',
  );
  await h.tap('local-code-qr');
  await h.tester.enterText(
    find.byKey(const ValueKey('local-code-field')),
    '7K2MQ9TD4H',
  );
  FocusManager.instance.primaryFocus?.unfocus();
  await h.flush();
  await _page(
    h,
    18,
    'zyra_code',
    'enter_info',
    reached:
        'Actual signup Enter code control displays its existing local informational response.',
  );
  await h.tap('onboarding_dev_skip');
  await _currentRoute<WaliHomeShell>(h);
  await _page(
    h,
    19,
    'first_tab',
    'normal',
    reached:
        'Actual existing Skip to Guardian DEV action enters WaliHomeShell first tab with local sample data. This is the current signup destination, not the replacement Founder shell.',
  );
}

void main() {
  setUpAll(() async {
    if (signupCaptureEnabled) await signupCaptureSetUp();
  });
  tearDownAll(() async {
    if (signupCaptureEnabled) await signupCaptureTearDown();
  });
  setUp(() {
    if (!signupCaptureEnabled) return;
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    AppState.instance.resetForAccountChange();
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraInternalPreviewClient.beginPreview();
  });

  for (final role in ['seeker', 'guardian']) {
    testWidgets(
      'signup shared entry sequence $role',
      (tester) async {
        final h = SignupCaptureHarness(
          tester,
          role: role,
          group: 'entry_$role',
        );
        await h.mount(const SplashScreen());
        await h.flush(const Duration(milliseconds: 3100));
        await _page(
          h,
          1,
          'splash',
          'normal',
          reached:
              'Actual production splash at its finished hold; no startup/auth gate mounted.',
        );
        await _entry(h, capture: true, guardian: role == 'guardian');
      },
      skip: !signupCaptureEnabled,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'signup offline provider states $role',
      (tester) async {
        final h = SignupCaptureHarness(
          tester,
          role: role,
          group: 'entry_$role',
        );
        for (final provider in ['apple', 'google']) {
          final pending = Completer<ZyraAuthResult>();
          await h.mount(
            WelcomeScreen(
              appleSignIn: () => pending.future,
              googleSignIn: () => pending.future,
            ),
          );
          await _welcomeAsset(tester);
          await h.tap('welcome_$provider');
          expect(find.byType(CircularProgressIndicator), findsWidgets);
          await _page(
            h,
            2,
            'welcome',
            '${provider}_loading',
            reached:
                'Actual public Welcome $provider control awaits an injected local callback; no OAuth or success routing.',
          );
          pending.complete(
            const ZyraAuthResult.error("That didn't work. Please try again."),
          );
          await h.flush();
          expect(
            find.text("That didn't work. Please try again."),
            findsOneWidget,
          );
          await _page(
            h,
            2,
            'welcome',
            '${provider}_error',
            reached:
                'The same injected local callback returns the existing public sign-in error; no real account.',
          );
        }
      },
      skip: !signupCaptureEnabled,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets(
    'signup Guardian actual path through first tab',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'guardian',
        group: 'entry_guardian',
      );
      await _guardianFlow(h);
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'signup Guardian female relationship choices',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'guardian',
        group: 'entry_guardian',
      );
      await h.mount(_onboarding(const WaliOnboardingFlow(devPreview: true)));
      // Existing local Skip answers only the preceding name/date questions.
      // The gender and relationship choices below remain actual UI actions.
      await h.tap('onboarding_dev_skip');
      await h.tap('onboarding_dev_skip');
      expect(_key('guardian_gender_female'), findsOneWidget);
      await h.tap('guardian_gender_female');
      await h.tap('wali_onboarding_continue');
      expect(_key('guardian_relationship_Mother'), findsOneWidget);
      expect(_key('guardian_relationship_Father'), findsNothing);
      await _page(
        h,
        13,
        'relationship',
        'female_empty',
        reached:
            'Existing local name/date Skip controls, then actual Female choice and Continue; the current Mother/Grandmother/Sister/Paternal Aunt/Other list is unselected.',
      );
      await h.tap('guardian_relationship_Mother');
      await _page(
        h,
        13,
        'relationship',
        'female_selected',
        reached:
            'Actual Mother relationship choice after Female; no account or link action.',
      );
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'signup Guardian local photo loading error and selected states',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'guardian',
        group: 'entry_guardian',
      );
      final pending = Completer<ZyraPhotoBatchResult>();
      await _photoQuestion(h, (context, remaining, progress) {
        expect(remaining, 1);
        progress('Preparing 1 of 1');
        return pending.future;
      });
      await h.tap('signup_first_photo_choose');
      final card = tester.widget<ZyraSignupFirstPhotoCard>(
        find.byType(ZyraSignupFirstPhotoCard),
      );
      expect(card.busy, isTrue);
      await _page(
        h,
        14,
        'photo',
        'loading',
        reached:
            'Actual photo Choose action awaits the existing injected local photoRunner and reports Preparing 1 of 1.',
      );
      pending.complete(const ZyraPhotoBatchResult.error());
      await h.flush();
      await _page(
        h,
        14,
        'photo',
        'error',
        reached:
            'Same existing local photoRunner returns its normal error result; no platform picker or upload.',
      );
      final bytes = await rootBundle.load(
        'assets/dev/one_journey_photos/guardian_self.jpg',
      );
      // The existing bundled Guardian sample supplies a real offline image;
      // no arbitrary signed URL, member image or source mutation is admitted.
      final source =
          'data:image/jpeg;base64,${base64Encode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes))}';
      await _photoQuestion(
        h,
        (context, remaining, progress) async =>
            ZyraPhotoBatchResult.added([source]),
      );
      await h.tap('signup_first_photo_choose');
      final preview = _key('signup_first_photo_preview');
      expect(preview, findsOneWidget);
      for (final element
          in find
              .descendant(of: preview, matching: find.byType(Image))
              .evaluate()) {
        await tester.runAsync(
          () => precacheImage((element.widget as Image).image, element),
        );
      }
      await h.flush();
      await _page(
        h,
        14,
        'photo',
        'selected',
        reached:
            'Actual photo Choose action receives a decodable bundled local sample image from existing photoRunner; no account persistence.',
      );
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'signup Guardian membership saving and error presenters',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'guardian',
        group: 'entry_guardian',
      );
      for (final saving in [true, false]) {
        await h.mount(
          _onboarding(
            SignupMembershipChoiceScreen(
              role: ZyraSignupRole.guardian,
              choice: const ZyraSignupMembershipChoice(
                kind: ZyraSignupMembershipKind.basic,
              ),
              onChanged: (_) =>
                  fail('State capture cannot select a membership.'),
              onContinue: () =>
                  fail('State capture cannot continue or purchase.'),
              onBack: () {},
              saving: saving,
              error: saving
                  ? null
                  : "We couldn't save your progress securely. Please try again.",
              devPreview: true,
            ),
          ),
        );
        await _page(
          h,
          15,
          'membership',
          saving ? 'loading' : 'error',
          reached:
              'Existing public membership presenter supplied ${saving ? 'saving=true' : 'its error argument'} in a bounded fixture; no backend, purchase, account or navigation callback.',
        );
      }
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
