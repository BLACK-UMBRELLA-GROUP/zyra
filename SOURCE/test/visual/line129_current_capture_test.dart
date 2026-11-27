import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';

import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LINE129_CAPTURE_DIR');

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _output.isEmpty ? null : _output));
  tearDownAll(baselineTearDown);

  testWidgets(
    'line 129 captures current Journey tab navigation',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = BaselineHarness(
        tester,
        group: 'line129',
        outputRoot: _output,
        evidenceRoot: _output,
        flatOutput: true,
      );
      await harness.mount(tab: 1, model: ViewRequestDraftModel(capacity: 3));
      await harness.capture(
        'journey',
        'empty',
        'current',
        'Current Founder preview Journey tab navigation.',
        fileName: 'j01_one__no_journey.png',
      );
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'line 129 captures current Past requests',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = ViewRequestDraftModel(capacity: 3);
      expect(
        model.seedPastRequest(
          profileId: 'draft-aisha',
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: DateTime.utc(2026, 10, 12),
          movedAt: DateTime.utc(2026, 10, 14),
        ),
        isTrue,
      );
      expect(
        model.seedPastRequest(
          profileId: 'draft-maryam',
          outcome: DraftPastRequestOutcome.youDeclined,
          requestedAt: DateTime.utc(2026, 10, 20),
          movedAt: DateTime.utc(2026, 10, 22),
        ),
        isTrue,
      );
      final harness = BaselineHarness(
        tester,
        group: 'line129',
        outputRoot: _output,
        evidenceRoot: _output,
        flatOutput: true,
      );
      await harness.mount(
        tab: 2,
        pages: const ['requests'],
        requestsTab: 2,
        model: model,
      );
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Maryam Hussain'), findsOneWidget);
      expect(find.text('Aisha Khan'), findsOneWidget);
      await harness.capture(
        'requests',
        'past',
        'current',
        'Current Founder preview Past requests fixture.',
        fileName: 'requests__past.png',
      );
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'line 129 captures the mute notice above the sheet',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = BaselineHarness(
        tester,
        group: 'line129',
        outputRoot: _output,
        evidenceRoot: _output,
        flatOutput: true,
      );
      await harness.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel(capacity: 3).snapshot(),
          tab: 3,
          pages: const ['guardian_circle'],
          guardianHistory: const {'draft-guardian-hassan': true},
        ),
      );
      await harness.tap('circle_topics_menu');
      await harness.tap('circle_topics_mute');
      expect(
        find.text('Circle muted — no alerts, messages still arrive.'),
        findsOneWidget,
      );
      await harness.capture(
        'circle',
        'mute',
        'current',
        'Current Founder preview mute notice above the sheet.',
        fileName: 'seeker_mute_notice.png',
      );
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'line 129 captures corrected Hide confirmation wording',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = BaselineHarness(
        tester,
        group: 'line129',
        outputRoot: _output,
        evidenceRoot: _output,
        flatOutput: true,
      );
      await harness.mount(
        tab: 1,
        pages: const ['profile'],
        model: ViewRequestDraftModel(capacity: 3)..seedJourneys(2),
      );
      await harness.tap('draft_safety');
      await harness.tap('draft_report_reason_fakeProfile');
      await harness.tap('draft_safety_hide');
      expect(find.textContaining('Settings → Hidden and blocked.'), findsOneWidget);
      await harness.capture(
        'safety',
        'hide',
        'current',
        'Current Founder preview Hide confirmation wording.',
        fileName: 'b02_hide_confirm.png',
      );
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
