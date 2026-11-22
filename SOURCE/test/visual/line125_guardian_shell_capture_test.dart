// OA-ZYRA-397: opt-in evidence uses the actual Guardian shell and quick route.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LINE125_GUARDIAN_OUTPUT');
final _samples = ZyraDeveloperSamples.instance;

void main() {
  setUpAll(() async {
    if (_output.isNotEmpty) await baselineSetUp(evidenceRoot: _output);
  });
  tearDownAll(() async {
    if (_output.isNotEmpty) await baselineTearDown();
  });
  tearDown(() {
    _samples.clear();
    _samples.unbind();
  });

  testWidgets(
    'line125 Guardian introductions uses the real Guardian quick-page nav',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = BaselineHarness(
        tester,
        group: 'line125_guardian_shell',
        outputRoot: _output,
        evidenceRoot: _output,
        flatOutput: true,
        reduceMotion: true,
      );
      await tester.runAsync(() async {
        await ZyraAccountState.synchronize('line125-guardian-capture');
        _samples.bind(
          authorized: () => true,
          capacity: () => 3,
          isSeekerOne: () => true,
        );
        _samples.recordRealCounts(
          ZyraAccountState.userId,
          ZyraAccountState.generation,
          active: 0,
        );
      });
      _samples.setIntroductions(1);
      expect(
        _samples.declineIntroduction(_samples.introductionRows!.single),
        isTrue,
      );
      await harness.mount(
        guardian: true,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: ViewRequestDraftModel(capacity: 3).snapshot(),
          tab: 2,
          pages: const [],
          guardianTabs: const ZyraGuardianTabsSnapshot(
            introduced: {'adam:aisha'},
          ),
        ),
      );
      await harness.tap('guardian_introductions');
      harness.assertPage('guardian_introductions');
      expect(find.text("Introductions you've made"), findsOneWidget);
      expect(find.text('Not taken forward'), findsOneWidget);
      expect(find.text('Suggested to Adam'), findsOneWidget);
      final navigation = tester.widget<ZyraShellNavigation>(
        find.byType(ZyraShellNavigation),
      );
      expect(navigation.currentIndex, 2);
      expect(navigation.items.first.icon, Icons.search);
      expect(navigation.items[1].useJourneyGlyph, isTrue);
      expect(navigation.items.map((item) => item.label), [
        'Network',
        'Journeys',
        'My ZYRA',
        'Seekers',
        'Profile',
      ]);
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        void repaint(RenderObject node) {
          node.markNeedsPaint();
          node.visitChildren(repaint);
        }

        repaint(
          tester.renderObject(
            find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
          ),
        );
        await tester.pump();
        await harness.capture(
          'guardian_shell',
          'introductions',
          'not_taken_forward',
          'Actual local Guardian shell reached from My ZYRA; OA-ZYRA-397.',
          fileName: 'guardian_introductions_made__not_taken_forward.png',
        );
      } finally {
        debugDisableShadows = previousShadows;
      }
      expect(tester.takeException(), isNull);
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
