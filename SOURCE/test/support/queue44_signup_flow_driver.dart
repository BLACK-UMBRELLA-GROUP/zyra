import 'package:zyra/screens/onboarding/category_summary_screen.dart';
import 'package:zyra/screens/onboarding/article9_consent_screen.dart';
import 'package:zyra/screens/onboarding/compatibility_category_intro_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/onboarding/transition_screen.dart';
import 'package:zyra/services/zyra_identity_verification_service.dart';
// Code-only test data and navigation helpers for the real first-use screens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_identity_verification.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_onboarding_choice_card.dart';
import 'package:zyra/widgets/zyra_signup_first_photo_card.dart';

const _fixtureEntry = ValueKey('queue44-code-photo-fixture');
const _pixel =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
Future<ZyraPhotoBatchResult> _photo(
  BuildContext context,
  int remaining,
  ValueChanged<String?> progress,
) async => const ZyraPhotoBatchResult.added([_pixel]);

Future<void> _installPhotoFixture(WidgetTester tester) async {
  final seeker = find.byType(OnboardingFlow);
  final guardian = find.byType(WaliOnboardingFlow);
  final finder = seeker.evaluate().isNotEmpty ? seeker : guardian;
  final widget = tester.widget<Widget>(finder);
  if (widget.key == _fixtureEntry) return;
  // A test-supplied runner owns its completion/progress/privacy contract.
  if ((widget is OnboardingFlow && widget.photoRunner != null) ||
      (widget is WaliOnboardingFlow && widget.photoRunner != null)) {
    return;
  }
  final context = tester.element(finder);
  final Widget replacement;
  if (widget is OnboardingFlow) {
    replacement = OnboardingFlow(
      key: _fixtureEntry,
      devPreview: true,
      welcomeName: widget.welcomeName,
      photoRunner: _photo,
    );
  } else {
    replacement = WaliOnboardingFlow(
      key: _fixtureEntry,
      devPreview: true,
      photoRunner: _photo,
    );
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      allowSnapshotting: false,
      builder: (_) => replacement,
    ),
  );
  await tester.pumpAndSettle();
  final stage = find.byKey(const ValueKey('onboarding_stage_continue'));
  if (stage.evaluate().isNotEmpty) {
    await tester.tap(stage);
    await tester.pumpAndSettle();
  }
}

/// Supplies ordinary form answers, then invokes the actual Continue callback.
Future<void> advanceSignupQuestionFromCode(
  WidgetTester tester, {
  bool installPhotoFixture = true,
}) async {
  expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
  if (installPhotoFixture) await _installPhotoFixture(tester);
  final first = find.byKey(const ValueKey('onboarding_first_name'));
  if (first.evaluate().isNotEmpty) {
    await tester.enterText(first, 'Shakeel');
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_last_name')),
      'Preview',
    );
    FocusManager.instance.primaryFocus?.unfocus();
  } else if (find
      .byKey(const ValueKey('seeker_gender_male'))
      .evaluate()
      .isNotEmpty) {
    tester
        .widget<ZyraOnboardingChoiceCard>(
          find.byKey(const ValueKey('seeker_gender_male')),
        )
        .onTap();
  } else if (find
      .byKey(const ValueKey('guardian_gender_male'))
      .evaluate()
      .isNotEmpty) {
    tester
        .widget<ZyraOnboardingChoiceCard>(
          find.byKey(const ValueKey('guardian_gender_male')),
        )
        .onTap();
  } else if (find.text('Select date of birth').evaluate().isNotEmpty) {
    // Supply an adult date through the actual field callback; no modal route
    // is introduced by the test fixture while route-count coverage is active.
    final dynamic picker = tester.widget<Widget>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().endsWith('DobPicker'),
      ),
    );
    picker.onPicked(DateTime(1980, 1, 1));
  } else if (find.byType(ZyraSignupFirstPhotoCard).evaluate().isNotEmpty) {
    tester
        .widget<ZyraSignupFirstPhotoCard>(find.byType(ZyraSignupFirstPhotoCard))
        .onChoose();
  } else {
    final choices = find.byWidgetPredicate(
      (w) =>
          w is ZyraOnboardingChoiceCard &&
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            'guardian_relationship_',
          ),
    );
    expect(choices, findsWidgets);
    tester.widget<ZyraOnboardingChoiceCard>(choices.first).onTap();
  }
  await tester.pumpAndSettle();
  final scaffold = tester.widget<OnboardingScaffold>(
    find.byType(OnboardingScaffold),
  );
  expect(scaffold.fabActive, isTrue);
  scaffold.onContinue!();
  await tester.pumpAndSettle();
}

VoidCallback verifiedIdentityFixtureCallback(WidgetTester tester) {
  final finder = find.byType(InitialIdentityCheckScreen);
  final context = tester.element(finder);
  final original = tester.widget<InitialIdentityCheckScreen>(finder);
  return () {
    if (!context.mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        !original.devPreview ||
        !ZyraDeveloperAccess.canUseDeveloperTools) {
      return;
    }
    final now = DateTime.now().toUtc();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        allowSnapshotting: false,
        builder: (_) => InitialIdentityCheckScreen(
          devPreview: true,
          requireDuplicateResolution: original.requireDuplicateResolution,
          finalizeOnboarding: original.finalizeOnboarding,
          onContinue: original.onContinue,
          initialState: ZyraIdentityVerificationState(
            result: ZyraIdentityVerificationResult.verified,
            duplicateReview: ZyraDuplicateReviewState.clear,
            consentGranted: true,
            consentVersion: kIdentityVerificationConsentVersion,
            consentRecordedAt: now,
            updatedAt: now,
            decidedAt: now,
          ),
        ),
      ),
    );
  };
}

Future<void> verifyIdentityFromCode(WidgetTester tester) async {
  expect(find.byKey(const ValueKey('identity-dev-verified')), findsNothing);
  verifiedIdentityFixtureCallback(tester)();
  await tester.pumpAndSettle();
}

/// Captures the actual guarded source Continue callback for a deferred fixture.
/// The source owner, route and authority checks remain inside that callback.
VoidCallback deferredOnboardingContinueFixtureCallback(WidgetTester tester) {
  final consent = find.byType(Article9ConsentScreen);
  if (consent.evaluate().isNotEmpty) {
    final decision = tester.widget<Article9ConsentScreen>(consent).onDecision;
    return () => decision(true);
  }
  final question = find.byType(OnboardingScaffold);
  if (question.evaluate().isNotEmpty) {
    final action = tester.widget<OnboardingScaffold>(question).onContinue;
    if (action == null) {
      throw StateError(
        'The real question Continue is disabled; supply its answer fixture first.',
      );
    }
    return action;
  }
  final category = find.byType(CompatibilityCategoryIntroScreen);
  if (category.evaluate().isNotEmpty) {
    return tester.widget<CompatibilityCategoryIntroScreen>(category).onContinue;
  }
  final summary = find.byType(CategorySummaryScreen);
  if (summary.evaluate().isNotEmpty) {
    return tester.widget<CategorySummaryScreen>(summary).onContinue;
  }
  final stage = find.byType(OnboardingStageIntroScreen);
  if (stage.evaluate().isNotEmpty) {
    return tester.widget<OnboardingStageIntroScreen>(stage).onContinue;
  }
  final transition = find.byType(TransitionScreen);
  if (transition.evaluate().isNotEmpty) {
    return tester.widget<TransitionScreen>(transition).onContinue;
  }
  final boundary = find.byWidgetPredicate(
    (widget) => const {
      '_CompatibilityBoundaryScreen',
      '_PreferenceGuideScreen',
      '_PreferenceGuide',
    }.contains(widget.runtimeType.toString()),
  );
  if (boundary.evaluate().isNotEmpty) {
    final dynamic page = tester.widget<Widget>(boundary);
    final VoidCallback action = page.onContinue;
    return action;
  }
  throw StateError(
    'No actual deferred onboarding Continue on the current fixture route.',
  );
}
