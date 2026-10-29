// Queue 10: actual optional-setup handoff and existing detached loader states.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/services/zyra_profile_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import 'package:zyra/widgets/zyra_loading.dart';

import 'signup_capture_support.dart';

Widget _presentation(Widget child) => ZyraOnboardingArrowScope(
  enabled: true,
  child: OnboardingPreviewStyle(directionName: 'luma', child: child),
);

/// Scroll only the current page's actual inner reader. The enclosing PageView
/// remains under the existing reveal/Continue guards throughout the capture.
Future<void> _reader(
  SignupCaptureHarness h,
  int order,
  String screen,
  String state, {
  required String readerKey,
  required String reached,
}) async {
  final scroll = find.descendant(
    of: find.byKey(ValueKey(readerKey)),
    matching: find.byType(Scrollable),
  );
  expect(scroll, findsOneWidget);
  final position = h.tester.state<ScrollableState>(scroll).position;
  position.jumpTo(position.minScrollExtent);
  await h.flush();
  await h.capture(order, screen, state, reached: reached);
  final maximum = position.maxScrollExtent;
  if (maximum > 1) {
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
            '$reached; actual inner-reader scroll to '
            '${target.toStringAsFixed(1)} of '
            '${maximum.toStringAsFixed(1)} logical px',
      );
      frame++;
      if (target >= maximum) break;
      expect(frame, lessThan(20));
    }
  }
  position.jumpTo(position.minScrollExtent);
  await h.flush();
}

void main() {
  setUpAll(signupCaptureSetUp);
  tearDownAll(signupCaptureTearDown);

  testWidgets(
    'capture actual Complete setup next steps and Profile introduction',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'seeker',
        group: 'seeker_overview',
      );
      AppState.instance.applyDevPreset(
        name: 'Shakeel',
        gender: 'male',
        dob: DateTime(1990, 1, 1),
      );
      await h.mount(
        _presentation(const SeekerPostIdentityChoiceScreen(devPreview: true)),
      );
      await h.tap('seeker_post_identity_continue_setup');
      expect(find.byType(SeekerOnboardingOverviewScreen), findsOneWidget);
      expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
      expect(find.text('Your next steps, Shakeel.'), findsOneWidget);
      await h.flush(const Duration(seconds: 3));
      const reached =
          'Actual local post-identity choice Continue profile setup opens '
          'SeekerOnboardingOverviewScreen(devPreview:true); current '
          'Your next steps reader, no account or verification result';
      await _reader(
        h,
        17,
        'complete_setup_next_steps',
        'initial',
        readerKey: 'onboarding_preview_welcome_scrollable',
        reached: reached,
      );
      for (var revealed = 1; revealed <= 4; revealed++) {
        // Tap inside the page's visible raw reveal area, avoiding controls.
        final area = find.byKey(
          const ValueKey('onboarding_welcome_reveal_tap_area'),
        );
        final box = tester.getRect(area);
        await tester.tapAt(Offset(box.center.dx, box.top + 30));
        await h.flush(const Duration(milliseconds: 600));
        expect(
          find.byKey(ValueKey('onboarding_roadmap_item_$revealed')),
          findsOneWidget,
        );
        await _reader(
          h,
          17,
          'complete_setup_next_steps',
          'roadmap_$revealed',
          readerKey: 'onboarding_preview_welcome_scrollable',
          reached: '$reached; actual tap reveals $revealed of4 setup steps',
        );
      }
      await h.tap('onboarding_welcome_continue');
      await h.flush(const Duration(milliseconds: 1200));
      expect(
        find.byKey(const ValueKey('onboarding_stage_build_profile')),
        findsOneWidget,
      );
      expect(find.text('Let’s begin with your profile.'), findsOneWidget);
      await _reader(
        h,
        18,
        'profile_stage',
        'normal',
        readerKey: 'onboarding_stage_scrollable',
        reached:
            'Actual four-step roadmap Continue settles on Your Profile '
            'stage; no PageView controller or protected checkpoint forced',
      );
      await h.tap('onboarding_stage_continue');
      await h.flush();
      expect(find.byType(Chapter2Flow), findsOneWidget);
      expect(find.text('Add your photos'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'capture existing setup overview public-loader loading and error states',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'seeker',
        group: 'seeker_overview_states',
      );
      final progress = Completer<ZyraOnboardingProgress?>();
      addTearDown(() {
        if (!progress.isCompleted) progress.complete(null);
      });
      await h.mount(
        _presentation(
          SeekerOnboardingOverviewScreen(
            gender: 'male',
            progressLoader: () => progress.future,
            answersLoader: () async => null,
            profileCompleteLoader: () async => false,
          ),
        ),
      );
      expect(find.byType(ZyraLoading), findsOneWidget);
      await h.capture(
        17,
        'complete_setup_progress',
        'loading',
        reached:
            'Detached actual SeekerOnboardingOverviewScreen; all three '
            'existing public loaders injected locally, progress Future pending; '
            'no auth principal, transport, private state or continuation invoked',
      );
      progress.completeError(StateError('Local progress-read failure'));
      await h.flush();
      expect(
        find.text(
          'Your saved setup could not be loaded. Try again to continue safely.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ZyraLoading), findsNothing);
      await h.capture(
        17,
        'complete_setup_progress',
        'error',
        reached:
            'The same existing public local progress loader throws; actual '
            'current recovery text and Try again button, no account or network',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
