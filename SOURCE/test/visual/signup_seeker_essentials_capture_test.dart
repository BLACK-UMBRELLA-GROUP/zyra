// Queue 10: existing Seeker account essentials and the finish-later handoff.
// All answers and photos stay in the protected local walkthrough.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import 'package:zyra/widgets/zyra_signup_first_photo_card.dart';

import 'signup_capture_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Widget _selectedPresentation(Widget child) => OnboardingPreviewStyle(
  directionName: 'luma',
  child: ZyraOnboardingArrowScope(enabled: true, child: child),
);

ScrollPosition? _pageScroll(WidgetTester tester) {
  final positions = tester
      .stateList<ScrollableState>(find.byType(Scrollable))
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
  String state,
  String reached,
) async {
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
          '$reached; actual page scroll to '
          '${target.toStringAsFixed(1)} of '
          '${maximum.toStringAsFixed(1)} logical px',
    );
    frame++;
    if (target >= maximum) break;
    expect(frame, lessThan(100));
  }
  await _top(h);
}

Future<void> _date(
  SignupCaptureHarness h,
  String input, {
  bool capturePicker = false,
}) async {
  final tester = h.tester;
  await h.tapFinder(find.byIcon(Icons.calendar_today_outlined));
  expect(find.byType(DatePickerDialog), findsOneWidget);
  if (capturePicker) {
    await h.capture(
      12,
      'date_picker',
      'normal',
      reached: 'Actual date-of-birth field opens the current Material picker.',
    );
  }
  await h.tapFinder(find.byTooltip('Switch to input'));
  final field = find.descendant(
    of: find.byType(DatePickerDialog),
    matching: find.byType(TextField),
  );
  expect(field, findsOneWidget);
  await tester.enterText(field, input);
  await h.flush();
  await h.tapFinder(find.text('OK'));
  expect(find.byType(DatePickerDialog), findsNothing);
}

Future<void> _currentRoute<T extends Widget>(SignupCaptureHarness h) async {
  final target = find.byType(T);
  bool ready() {
    final owners = target.evaluate().toList();
    if (owners.length != 1) return false;
    final route = ModalRoute.of(owners.single);
    return route?.isCurrent == true &&
        route?.animation?.status == AnimationStatus.completed;
  }

  // Membership commits its fallback child before pushReplacement's incoming
  // route finishes. Wait for that outgoing owner to leave; capture only the
  // one completed, current route, never an arbitrary first matching widget.
  for (var frame = 0; frame < 20 && !ready(); frame++) {
    await h.flush(const Duration(milliseconds: 100));
  }
  expect(target, findsOneWidget);
  expect(ready(), isTrue, reason: '$T must own the completed current route');
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
    ZyraInternalPreviewClient.beginPreview();
  });

  testWidgets(
    'signup Seeker essentials through actual finish-later first tab',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'seeker',
        group: 'seeker_essentials',
      );
      final asset = await rootBundle.load(
        'assets/dev/one_journey_photos/seeker_self.jpg',
      );
      final source =
          'data:image/jpeg;base64,${base64Encode(asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes))}';
      final pendingPhoto = Completer<ZyraPhotoBatchResult>();
      var attempts = 0;
      await h.mount(
        _selectedPresentation(
          OnboardingFlow(
            devPreview: true,
            photoRunner: (context, remaining, progress) {
              expect(remaining, 1);
              attempts++;
              progress('Preparing 1 of 1');
              if (attempts == 1) return pendingPhoto.future;
              return Future.value(ZyraPhotoBatchResult.added([source]));
            },
          ),
        ),
      );
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      expect(
        ZyraDevOnboardingInteraction.current,
        ZyraOnboardingAdvanceMode.animatedDownArrow,
      );
      await h.flush(const Duration(seconds: 4));
      expect(find.text('First, your account.'), findsOneWidget);
      await _page(
        h,
        9,
        'account_intro',
        'normal',
        'Existing protected Seeker account intro; B captures the shared role-choice entry.',
      );
      await h.tap('onboarding_stage_continue');
      expect(find.text("What's your name?"), findsOneWidget);
      await _page(
        h,
        10,
        'name',
        'empty',
        'Actual account-intro Continue enters question 1 with both fields empty.',
      );
      await tester.enterText(_key('onboarding_first_name'), 'Amina');
      FocusManager.instance.primaryFocus?.unfocus();
      await _page(
        h,
        10,
        'name',
        'partial',
        'Actual first-name field only; existing Continue validation remains disabled.',
      );
      expect(
        tester
            .widget<ZyraOnboardingArrowAction>(_key('onboarding_continue'))
            .active,
        isFalse,
      );
      await tester.enterText(_key('onboarding_last_name'), 'Rahman');
      FocusManager.instance.primaryFocus?.unfocus();
      await _page(
        h,
        10,
        'name',
        'filled',
        'Both actual name fields contain fictional local names; keyboard dismissed.',
      );
      await h.tap('onboarding_continue');
      expect(_key('seeker_gender_female'), findsOneWidget);
      await _page(
        h,
        11,
        'gender',
        'empty',
        'Actual question 2 before selecting an answer.',
      );
      await h.tap('seeker_gender_male');
      await _page(
        h,
        11,
        'gender',
        'male_selected',
        'Actual Male choice, before selecting Female for the remaining local path.',
      );
      await h.tap('seeker_gender_female');
      await _page(
        h,
        11,
        'gender',
        'female_selected',
        'Actual Female choice; local fixture follows the current Female path.',
      );
      await h.tap('onboarding_continue');
      expect(find.text('When were you born?'), findsOneWidget);
      await _page(
        h,
        12,
        'date_of_birth',
        'empty',
        'Actual question 3 has no answer yet.',
      );
      await _date(h, '01/01/2012', capturePicker: true);
      expect(
        find.text("You'll need to be 18 or over to continue."),
        findsOneWidget,
      );
      await _page(
        h,
        12,
        'date_of_birth',
        'error',
        'Actual picker accepted an under-18 date; existing validation refuses Continue.',
      );
      expect(
        tester
            .widget<ZyraOnboardingArrowAction>(_key('onboarding_continue'))
            .active,
        isFalse,
      );
      await _date(h, '01/01/1996');
      await _page(
        h,
        12,
        'date_of_birth',
        'selected',
        'Actual date picker selects the fictional adult date 1 January 1996.',
      );
      await h.tap('onboarding_continue');
      expect(_key('signup_first_photo_question'), findsOneWidget);
      await _page(
        h,
        13,
        'photo',
        'empty',
        'Actual required question 4; no platform picker or upload started.',
      );
      await h.tap('signup_first_photo_choose');
      expect(
        tester
            .widget<ZyraSignupFirstPhotoCard>(
              find.byType(ZyraSignupFirstPhotoCard),
            )
            .busy,
        isTrue,
      );
      await _page(
        h,
        13,
        'photo',
        'loading',
        'Actual Choose awaits the existing injected local photoRunner; Preparing 1 of 1.',
      );
      pendingPhoto.complete(const ZyraPhotoBatchResult.error());
      await h.flush();
      expect(
        tester
            .widget<ZyraSignupFirstPhotoCard>(
              find.byType(ZyraSignupFirstPhotoCard),
            )
            .busy,
        isFalse,
      );
      await _page(
        h,
        13,
        'photo',
        'error',
        'Same injected runner returns the current public error result; no photo upload.',
      );
      await h.tap('signup_first_photo_choose');
      expect(_key('signup_first_photo_preview'), findsOneWidget);
      await _page(
        h,
        13,
        'photo',
        'selected',
        'Actual retry chooses the existing bundled seeker_self sample, decoded locally.',
      );
      await h.tap('onboarding_continue');
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      await _page(
        h,
        14,
        'membership',
        'empty',
        'Actual first-photo Continue enters the unselected membership screen.',
      );
      for (final choice in ['basic', 'one', 'family']) {
        await h.tap('signup_membership_$choice');
        await _page(
          h,
          14,
          'membership',
          '${choice}_selected',
          'Actual $choice membership card; no purchase or entitlement action.',
        );
        if (choice == 'family') {
          await h.tap('signup_family_guardians_add');
          await _page(
            h,
            14,
            'membership',
            'family_estimate',
            'Actual Family selector adds a Guardian to the required Seeker place; local estimate.',
          );
        }
      }
      await h.tap('signup_membership_basic');
      await h.tap('signup_membership_continue');
      await _currentRoute<InitialIdentityCheckScreen>(h);
      expect(find.byType(OnboardingFlow), findsNothing);
      await _page(
        h,
        15,
        'identity_check',
        'consent',
        'Actual Basic Continue opens identity consent; no real check is started.',
      );
      await h.tap('identity_dev_skip');
      await _currentRoute<SeekerPostIdentityChoiceScreen>(h);
      await _page(
        h,
        16,
        'post_identity_choice',
        'normal',
        'Existing protected identity Skip handoff; it grants no verification or live account.',
      );
      await h.tap('seeker_post_identity_finish_later');
      await _currentRoute<HomeShell>(h);
      final shell = tester.widget<HomeShell>(find.byType(HomeShell));
      expect(shell.initialTab, 2);
      expect(shell.deferredOnboardingDevPreview, isTrue);
      expect(find.byType(SeekerDashboardScreen), findsOneWidget);
      await _page(
        h,
        17,
        'my_zyra_finish_later',
        'normal',
        'Actual Go to My ZYRA finish-later action opens ordinary HomeShell tab2 in its existing offline deferred-onboarding preview mode.',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'signup Seeker existing membership saving and error presenters',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'seeker',
        group: 'seeker_essentials',
      );
      for (final saving in [true, false]) {
        await h.mount(
          _selectedPresentation(
            SignupMembershipChoiceScreen(
              role: ZyraSignupRole.seeker,
              choice: const ZyraSignupMembershipChoice(
                kind: ZyraSignupMembershipKind.basic,
              ),
              onChanged: (_) => fail('Capture cannot select a membership.'),
              onContinue: () => fail('Capture cannot continue or purchase.'),
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
          14,
          'membership',
          saving ? 'loading' : 'error',
          'Existing public membership presenter supplied ${saving ? 'saving=true' : 'its error argument'} in a bounded fixture; no persistence, purchase or live navigation.',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
