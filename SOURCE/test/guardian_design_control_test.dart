import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';

void main() {
  test('Guardian preview includes zero through three active Journeys', () {
    final scenario = ZyraDevScenario.instance;
    try {
      for (final count in [0, 1, 2, 3]) {
        scenario.setGuardianPreviewActiveJourneyCount(count);
        expect(scenario.guardianPreviewActiveJourneyCount, count);
      }
      scenario.setGuardianPreviewActiveJourneyCount(-1);
      expect(scenario.guardianPreviewActiveJourneyCount, 0);
      scenario.setGuardianPreviewActiveJourneyCount(4);
      expect(scenario.guardianPreviewActiveJourneyCount, 3);
      final panel = File(
        'lib/dev/dev_scenario_panel_v2.dart',
      ).readAsStringSync();
      expect(panel, contains('for (final count in const [0, 1, 2, 3])'));
    } finally {
      scenario.setGuardianPreviewActiveJourneyCount(1);
    }
  });
  test('Quiet sections is canonical and has no comparison toggle', () {
    final panel = File('lib/dev/dev_scenario_panel_v2.dart').readAsStringSync();
    final guardianStart = panel.indexOf(
      'List<ZyraDevPageOption> _guardianOptions()',
    );
    expect(guardianStart, greaterThanOrEqualTo(0));
    final guardianEnd = panel.indexOf(
      'List<ZyraDevPageOption> _profileOptions()',
      guardianStart,
    );
    expect(guardianEnd, greaterThan(guardianStart));
    final guardianTools = panel.substring(guardianStart, guardianEnd);
    final dashboardTools = File(
      'lib/dev/zyra_dashboard_lab_controls.dart',
    ).readAsStringSync();

    expect(guardianTools, isNot(contains("group: 'Guardian Page Design'")));
    expect(guardianTools, isNot(contains('guardian-design-')));
    expect(guardianTools, contains('if (!_localOnly)'));
    expect(guardianTools, contains('_scenario.setUseLiveGuardianData(live)'));
    expect(guardianTools, contains('_scenario.setMainGuardian(linked)'));
    expect(guardianTools, contains('_scenario.setAdditionalGuardians'));
    expect(guardianTools, isNot(contains('pending-invitation states below')));
    expect(guardianTools, isNot(contains('Received invitations')));
    expect(guardianTools, isNot(contains('Pending invitations')));
    expect(
      dashboardTools,
      isNot(contains('Guardian invitations remain owned')),
    );
    expect(
      dashboardTools,
      isNot(contains('by Dashboard, not the Guardian page')),
    );

    final tab = File(
      'lib/screens/wali/seeker_wali_tab.dart',
    ).readAsStringSync();
    final manager = File(
      'lib/screens/wali/seeker_guardian_designs.dart',
    ).readAsStringSync();
    final scenario = File('lib/dev/zyra_dev_scenario.dart').readAsStringSync();
    expect(tab, contains('SeekerGuardianPage'));
    expect(tab, isNot(contains('ZyraDeveloperAccess.canUseDeveloperTools')));
    expect(tab, isNot(contains('guardianPageDesign')));
    expect(manager, contains('class GuardianshipManagerView'));
    expect(manager, contains('class SeekerGuardianPage'));
    expect(manager, contains('class _QuietSections'));
    expect(manager, isNot(contains('class _FullProfileCanvas')));
    expect(manager, isNot(contains('class _SnapshotFirst')));
    expect(manager, isNot(contains('class _SwipeStack')));
    expect(manager, isNot(contains('class _JourneyFocus')));
    expect(manager, contains('PageView.builder'));
    expect(manager, contains("'Share past Journey summaries'"));
    expect(manager, isNot(contains('Swipe to view')));
    expect(manager, isNot(contains('RELATIONSHIP HISTORY')));
    expect(manager, isNot(contains("label: 'CAN VIEW'")));
    expect(manager, isNot(contains('Timeline and Journey conversation')));
    expect(manager, isNot(contains('MAIN GUARDIAN LEADS')));
    expect(manager, isNot(contains("label: 'LEADS'")));
    expect(manager, isNot(contains('Limited Journey summary')));
    for (final retired in const [
      '_GuardianFocusCarousel',
      'GuardianActivityResolver',
      'guardianPulseCarousel',
      'sharedPathCarousel',
      'actionBoardCarousel',
      'activityFlowCarousel',
      'livingLinkCarousel',
    ]) {
      expect(manager, isNot(contains(retired)));
    }
    expect(scenario, isNot(contains('enum ZyraGuardianPageDesign')));
    expect(scenario, isNot(contains('guardianPageDesign')));
    expect(scenario, isNot(contains('setGuardianPageDesign')));
    for (final retired in const [
      'guardianPulseCarousel',
      'sharedPathCarousel',
      'actionBoardCarousel',
      'activityFlowCarousel',
      'livingLinkCarousel',
    ]) {
      expect(scenario, isNot(contains(retired)));
    }
  });
}
