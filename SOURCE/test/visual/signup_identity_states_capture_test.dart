// Existing public identity presenters only; no check, provider or account.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_identity_verification.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

import 'signup_capture_support.dart';

Widget _style(Widget child) => OnboardingPreviewStyle(
  directionName: 'luma',
  child: ZyraOnboardingArrowScope(enabled: true, child: child),
);

ZyraIdentityVerificationState _state(ZyraIdentityVerificationResult result) {
  final date = DateTime.utc(2026, 10, 29, 12);
  return ZyraIdentityVerificationState(
    result: result,
    duplicateReview: result == ZyraIdentityVerificationResult.verified
        ? ZyraDuplicateReviewState.clear
        : ZyraDuplicateReviewState.notEvaluated,
    consentGranted: result != ZyraIdentityVerificationResult.cancelled,
    consentVersion: 'offline-display-fixture',
    consentRecordedAt: date,
    updatedAt: date,
  );
}

void main() {
  setUpAll(signupCaptureSetUp);
  tearDownAll(signupCaptureTearDown);

  for (final role in ['seeker', 'guardian']) {
    testWidgets(
      '$role existing identity states stay display-only and offline',
      (tester) async {
        final h = SignupCaptureHarness(
          tester,
          role: role,
          group: '${role}_identity_states',
        );
        final order = role == 'seeker' ? 15 : 16;
        for (final result in ZyraIdentityVerificationResult.values) {
          await h.mount(
            _style(
              InitialIdentityCheckScreen(
                devPreview: true,
                initialState: _state(result),
              ),
            ),
          );
          expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
          await h.capture(
            order,
            'identity_check',
            result.storageValue,
            reached:
                'Existing public devPreview initialState display fixture: '
                '${result.storageValue}. No provider or continuation invoked; '
                'this is not a verification result or account admission.',
          );
        }

        await h.mount(
          _style(const InitialIdentityCheckScreen(devPreview: true)),
        );
        await h.tap('identity-consent-agree');
        await h.capture(
          order,
          'identity_check',
          'provider_unavailable',
          reached:
              'Actual consent control in protected local preview returns its '
              'built-in unavailable provider state; no real check starts.',
        );

        final pending = Completer<void>();
        await h.mount(
          _style(
            InitialIdentityCheckScreen(
              devPreview: true,
              onDevSkip: (_) => pending.future,
            ),
          ),
        );
        await h.tap('identity_dev_skip');
        expect(
          tester
              .widget<TextButton>(
                find.byKey(const ValueKey('identity_dev_skip')),
              )
              .onPressed,
          isNull,
        );
        await h.capture(
          order,
          'identity_check',
          'preview_continuation_loading',
          reached:
              'Existing onDevSkip callback awaits a local Completer. Actual '
              'busy/disabled surface; no identity result or finalizer.',
        );
        pending.completeError(StateError('Local continuation fixture'));
        await h.flush();
        expect(
          find.text('The preview could not continue. Try again.'),
          findsOneWidget,
        );
        await h.capture(
          order,
          'identity_check',
          'preview_continuation_error',
          reached:
              'Existing onDevSkip local callback rejects; actual preview error '
              'surface. No server, provider, auth success or private state.',
        );
      },
      skip: !signupCaptureEnabled,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
