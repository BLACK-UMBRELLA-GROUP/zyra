// Queue 10: capture existing signup presenters offline without a member account.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_transition.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';

import 'baseline_capture_support.dart';

const signupCaptureEnabled = bool.fromEnvironment('ZYRA_SIGNUP_CAPTURE');
const signupEvidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/SIGNUP_CAPTURE_2026-10-29';

Future<void> signupCaptureSetUp() async {
  await baselineSetUp(evidenceRoot: signupEvidence);
  ZyraInternalPreviewClient.finishSignOut();
  ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
  ZyraDevSurfaceCoordinator.instance.resetForTesting();
  ZyraDevOnboardingGoldMotion.resetForTesting();
  ZyraDevOnboardingInteraction.resetForTesting();
  ZyraDevOnboardingStoryNavigation.resetForTesting();
  ZyraDevOnboardingTransition.resetForTesting();
  ZyraInternalPreviewClient.beginPreview();
}

Future<void> signupCaptureTearDown() async {
  ZyraDevSurfaceCoordinator.instance.resetForTesting();
  ZyraInternalPreviewClient.finishSignOut();
  AppState.instance.resetForAccountChange();
  await baselineTearDown();
}

class SignupCaptureHarness {
  SignupCaptureHarness(this.tester, {required this.role, required String group})
    : assert(role == 'seeker' || role == 'guardian'),
      _capture = BaselineHarness(
        tester,
        group: group,
        outputRoot: '$baselineRoot/signup/$role',
        evidenceRoot: signupEvidence,
        flatOutput: true,
      );

  final WidgetTester tester;
  final String role;
  final BaselineHarness _capture;
  List<Map<String, Object?>> get rows => _capture.rows;

  Future<void> mount(Widget child) async {
    await _capture.mountPresentation(
      child: KeyedSubtree(key: UniqueKey(), child: child),
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: role == 'guardian',
        model: ViewRequestDraftModel(
          capacity: 3,
          clock: () => DateTime.utc(2026, 10, 29, 12),
        ).snapshot(),
        tab: 0,
        pages: const [],
      ),
    );
  }

  Future<void> flush([Duration? duration]) async {
    if (duration != null) await tester.pump(duration);
    await _capture.flush();
  }

  Future<void> tap(String key) => tapFinder(find.byKey(ValueKey(key)));

  Future<void> tapFinder(Finder target) async {
    expect(target, findsOneWidget);
    final scrolls = find.ancestor(
      of: target,
      matching: find.byType(Scrollable),
    );
    if (scrolls.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await flush();
    }
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    await flush();
  }

  Future<void> capture(
    int order,
    String screen,
    String state, {
    required String reached,
  }) => _capture.capture(
    'signup',
    '${order.toString().padLeft(2, '0')}_$screen',
    state,
    reached,
  );
}
