import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'support/queue44_scenario_fixture_catalog.dart';
import 'support/queue44_dashboard_fixture_catalog.dart';

List<ZyraFixtureChoice> _guardianChoices() {
  final state = ZyraDevScenario.instance;
  final page = state.currentPage;
  final live = state.useLiveGuardianData;
  ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
  try {
    state.setCurrentPage(DevPage.guardian);
    state.setUseLiveGuardianData(false);
    return Queue44SeekerCatalog(current: () => true).options;
  } finally {
    state.setCurrentPage(page);
    state.setUseLiveGuardianData(live);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
  }
}

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
      final choices = _guardianChoices().where(
        (choice) => choice.id.startsWith('guardian-active-journeys-'),
      );
      expect(choices.map((choice) => choice.id), [
        for (final count in [0, 1, 2, 3]) 'guardian-active-journeys-$count',
      ]);
      expect(File('lib/dev/dev_scenario_panel_v2.dart').existsSync(), isFalse);
    } finally {
      scenario.setGuardianPreviewActiveJourneyCount(1);
    }
  });
  test('Quiet sections is canonical and has no comparison toggle', () {
    final choices = _guardianChoices();
    expect(
      choices.map((choice) => choice.group),
      isNot(contains('Guardian Page Design')),
    );
    expect(
      choices.any((choice) => choice.id.startsWith('guardian-design-')),
      isFalse,
    );
    expect(
      choices.map((choice) => choice.id),
      containsAll([
        'guardian-source-live',
        'guardian-source-preview',
        'main-guardian-linked',
        'main-guardian-none',
        'additional-guardians-0',
      ]),
    );
    expect(
      choices.map((choice) => choice.group),
      isNot(contains('Received invitations')),
    );
    expect(
      choices.map((choice) => choice.group),
      isNot(contains('Pending invitations')),
    );
    expect(File('lib/dev/dev_scenario_panel_v2.dart').existsSync(), isFalse);
    expect(
      File('lib/dev/zyra_dashboard_lab_controls.dart').existsSync(),
      isFalse,
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
