import 'support/queue44_scenario_fixture_catalog.dart';
import 'support/queue44_dashboard_fixture_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_entitlements.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_dashboard_lab.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

late Queue44SeekerCatalog _fixture;
List<ZyraFixtureChoice> _options(WidgetTester tester) => _fixture.options;

Finder get _categoryControls => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('dev_page_options_dropdown_');
});

Future<void> _apply(WidgetTester tester, String id) async {
  await _options(tester).singleWhere((option) => option.id == id).onSelected!();
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String id) async {
  final option = _options(tester).singleWhere((option) => option.id == id);
  await option.onSelected!();
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester, {
  VoidCallback? onIntroductions,
  ValueChanged<int>? onSection,
  double textScale = 1,
}) async {
  final owner = UniqueKey();
  _fixture = Queue44SeekerCatalog(
    current: () => find.byKey(owner).evaluate().isNotEmpty,
    onIntroductions: onIntroductions,
    onSection: onSection,
  );
  await tester.pumpWidget(MaterialApp(home: SizedBox(key: owner)));
  await tester.pumpAndSettle();
}

void main() {
  final scenario = ZyraDevScenario.instance;

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    AppState.instance.setPlan(ZyraPlan.basic);
    scenario
      ..reset()
      ..setConnectionsSection(0);
    SupportiveDashboardPreview.instance.reset();
  });

  tearDown(() {
    scenario.reset();
    SupportiveDashboardPreview.instance.reset();
    AppState.instance.setPlan(ZyraPlan.basic);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  for (final page in DevPage.values) {
    testWidgets('${page.name} Actions separates every contextual category', (
      tester,
    ) async {
      scenario.setCurrentPage(page);
      await _mount(tester);

      expect(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == 'ZyraDevPageOptions',
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dev_page_options_dropdown')),
        findsNothing,
      );
      expect(find.text('Page options'), findsNothing);
      final groups = _options(tester).map((option) => option.group).toSet();
      for (final group in groups) {
        expect(
          find.byKey(ValueKey('dev_page_options_dropdown_$group')),
          findsNothing,
          reason: '${page.name}: $group needs its own control',
        );
      }
      expect(groups, isNotEmpty);
      expect(_categoryControls, findsNothing);
      expect(find.text('OPEN PAGE'), findsNothing);
      expect(find.text('ACCOUNT SCENARIOS'), findsNothing);
      expect(find.text('ZYRA DEV · ACTIONS'), findsNothing);
      expect(find.text('MAIN APP · LOCAL PREVIEW ONLY'), findsNothing);
      expect(
        find.byKey(const ValueKey('main_app_founder_preview_panel_banner')),
        findsNothing,
      );
      expect(
        _options(tester).map((option) => option.id).toSet().length,
        _options(tester).length,
      );
      expect(scenario.introductionPreviewCount, 0);
      expect(scenario.consideredPreviewCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Browse keeps Full Aura and plan-appropriate limit previews', (
    tester,
  ) async {
    scenario.setCurrentPage(DevPage.browse);
    await _mount(tester);
    expect(
      _options(
        tester,
      ).where((option) => option.id.startsWith('browse-motion-')),
      hasLength(ZyraBrowseSwipeFeedbackStyle.values.length),
    );
    expect(
      _options(tester).map((option) => option.id),
      containsAll([
        'browse-save-limit',
        'browse-consider-limit',
        'browse-daily-limit',
      ]),
    );

    await _select(
      tester,
      _options(tester)
          .singleWhere(
            (option) =>
                option.label == ZyraBrowseSwipeFeedbackStyle.fullAura.label,
          )
          .id,
    );
    expect(
      scenario.browseSwipeFeedbackStyle,
      ZyraBrowseSwipeFeedbackStyle.fullAura,
    );

    AppState.instance.setPlan(ZyraPlan.one);
    await tester.pumpAndSettle();
    expect(
      _options(tester).any((option) => option.id == 'browse-save-limit'),
      isTrue,
    );
    expect(
      _options(tester).any((option) => option.id == 'browse-consider-limit'),
      isFalse,
    );
    expect(
      _options(tester).any((option) => option.id == 'browse-daily-limit'),
      isFalse,
    );
  });

  testWidgets('Journeys keeps all bounded counts without live actions', (
    tester,
  ) async {
    scenario.setCurrentPage(DevPage.connections);
    await _mount(tester);
    for (final plan in ZyraPlan.values) {
      AppState.instance.setPlan(plan);
      await tester.pumpAndSettle();
      final limits = ZyraEntitlements.of(plan);
      for (final entry in {
        'active-journeys': limits.active,
        'potential-journeys': limits.potential,
        'paused-journeys': limits.paused,
        'ended-journeys': limits.ended,
      }.entries) {
        expect(
          _options(tester).where((option) => option.id.startsWith(entry.key)),
          hasLength(ZyraEntitlements.devMaxFor(entry.value) + 1),
        );
      }
      expect(
        _options(
          tester,
        ).any((option) => option.id == 'connections-live-journey'),
        isFalse,
      );
    }
    await _apply(tester, 'active-journeys-2');
    expect(scenario.activeJourneys, 2);
    await _apply(tester, 'active-journeys-0');
    expect(scenario.activeJourneys, 0);
  });

  testWidgets(
    'Connections follows real section state without selecting or staging',
    (tester) async {
      AppState.instance.setPlan(ZyraPlan.one);
      scenario.setCurrentPage(DevPage.connections);
      final sections = <int>[];
      await _mount(tester, onSection: sections.add);
      final oldJourneyOption = _options(
        tester,
      ).singleWhere((option) => option.id == 'active-journeys-1');

      scenario.setConnectionsSection(1);
      await tester.pumpAndSettle();
      expect(_fixture.title, 'Connections · Activity');
      expect(_options(tester), hasLength(18));
      expect(
        _options(tester).any((option) => option.id.startsWith('credits-')),
        isFalse,
      );
      expect(
        _options(
          tester,
        ).any((option) => option.id.startsWith('guardians-on-decided-')),
        isFalse,
      );
      await oldJourneyOption.onSelected!();
      expect(scenario.activeJourneys, 0);
      await _apply(tester, 'considered-profiles-3');
      expect(scenario.consideredPreviewCount, 3);
      await _apply(tester, 'saved-profiles-2');
      expect(scenario.savedPreviewCount, 2);
      await _apply(tester, 'passed-profiles-1');
      expect(scenario.passedPreviewCount, 1);

      scenario.setConnectionsSection(2);
      await tester.pumpAndSettle();
      expect(_fixture.title, 'Connections · Introductions');
      expect(_options(tester), hasLength(6));
      expect(scenario.introductionPreviewCount, 0);
      expect(sections, isEmpty);
      expect(
        find.byKey(const ValueKey('dev_connections_section_picker')),
        findsNothing,
      );
    },
  );

  testWidgets('Introduction selection calls its existing reveal once', (
    tester,
  ) async {
    scenario
      ..setCurrentPage(DevPage.connections)
      ..setConnectionsSection(2);
    var reveals = 0;
    await _mount(tester, onIntroductions: () => reveals++);
    await _apply(tester, 'test-introductions-4');
    expect(scenario.introductionPreviewCount, 4);
    expect(reveals, 1);
  });

  testWidgets('Guardian and active Journey retain only their own choices', (
    tester,
  ) async {
    scenario.setCurrentPage(DevPage.guardian);
    await _mount(tester);
    expect(_options(tester), hasLength(14));
    expect(
      _options(tester).map((option) => option.id),
      containsAll([
        'guardian-code-valid',
        'guardian-code-invalid',
        'guardian-active-journeys-0',
        'guardian-active-journeys-1',
        'guardian-active-journeys-2',
        'guardian-active-journeys-3',
      ]),
    );
    expect(
      _options(tester).any((option) => option.group == 'Data source'),
      isFalse,
    );
    expect(
      _options(tester).any((option) => option.group == 'Membership'),
      isFalse,
    );
    await _apply(tester, 'guardian-active-journeys-3');
    expect(scenario.guardianPreviewActiveJourneyCount, 3);
    await _apply(tester, 'main-guardian-linked');
    expect(scenario.mainGuardian, isTrue);
    await _apply(tester, 'additional-guardians-5');
    expect(scenario.additionalGuardianCount, 5);

    scenario.setCurrentPage(DevPage.activeJourney);
    await tester.pumpAndSettle();
    expect(_options(tester), hasLength(ZyraPauseDevScenario.values.length));
    for (final pause in ZyraPauseDevScenario.values) {
      await _apply(tester, 'pause-${pause.name}');
      expect(scenario.pauseScenario, pause);
    }
  });

  testWidgets(
    'Profile membership is local and stale or revoked callbacks are inert',
    (tester) async {
      scenario.setCurrentPage(DevPage.profile);
      await _mount(tester);
      expect(_options(tester).map((option) => option.id), [
        'profile-membership-inactive',
        'profile-membership-one',
        'profile-notification-banner',
        'profile-notification-reset',
      ]);
      final one = _options(
        tester,
      ).singleWhere((option) => option.id == 'profile-membership-one');
      await _apply(tester, one.id);
      expect(AppState.instance.plan, ZyraPlan.one);
      expect(_fixture.notice, contains('Account membership was unchanged'));
      await _apply(tester, 'profile-membership-inactive');
      scenario.setCurrentPage(DevPage.browse);
      await tester.pumpAndSettle();
      await one.onSelected!();
      expect(AppState.instance.plan, ZyraPlan.basic);

      scenario.setCurrentPage(DevPage.profile);
      await tester.pumpAndSettle();
      final revoked = _options(
        tester,
      ).singleWhere((option) => option.id == one.id);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      await revoked.onSelected!();
      expect(AppState.instance.plan, ZyraPlan.basic);
      expect(_categoryControls, findsNothing);
    },
  );

  testWidgets('separate category controls fit a narrow screen at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    scenario
      ..setCurrentPage(DevPage.connections)
      ..setConnectionsSection(2);
    await _mount(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await _select(tester, 'test-introductions-1');
    expect(scenario.introductionPreviewCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My ZYRA header follows the active renderer tab', (tester) async {
    scenario.setCurrentPage(DevPage.dashboard);
    await _mount(tester);
    expect(_fixture.title, 'My ZYRA · Now');
    scenario.setDashboardTab(ZyraDashboardTab.insights);
    await tester.pumpAndSettle();
    expect(_fixture.title, 'My ZYRA · Insights');

    SupportiveDashboardPreview.instance.selectView(true);
    await tester.pumpAndSettle();
    expect(_fixture.title, 'My ZYRA · Now');
    SupportiveDashboardPreview.instance.selectTab(1);
    await tester.pumpAndSettle();
    expect(_fixture.title, 'My ZYRA · Insights');
    for (final group in _options(
      tester,
    ).map((option) => option.group).toSet()) {
      expect(
        find.byKey(ValueKey('dev_page_options_dropdown_$group')),
        findsNothing,
      );
    }
  });

  testWidgets('legacy seeded controls remain in their existing page catalogs', (
    tester,
  ) async {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    scenario.setCurrentPage(DevPage.connections);
    await _mount(tester);
    expect(
      _options(tester).any((option) => option.id == 'connections-live-journey'),
      isTrue,
    );
    scenario.setConnectionsSection(1);
    await tester.pumpAndSettle();
    expect(
      _options(tester).map((option) => option.id),
      containsAll([
        'credits-plus-1',
        'credits-plus-5',
        'guardians-on-decided-0',
        'guardians-on-decided-3',
      ]),
    );
    expect(
      _options(
        tester,
      ).any((option) => option.id.startsWith('credits-standard-')),
      isFalse,
    );
    for (final count in const [1, 5]) {
      final unlock = _options(
        tester,
      ).singleWhere((option) => option.id == 'credits-plus-$count');
      expect(unlock.label, 'Compatibility Unlock credits · +$count');
      expect(unlock.group, 'Compatibility data');
    }
    scenario.setCurrentPage(DevPage.guardian);
    await tester.pumpAndSettle();
    expect(
      _options(tester).map((option) => option.id),
      containsAll(['guardian-source-preview', 'guardian-source-live']),
    );
  });

  testWidgets('failed membership selection stays unchanged and reports failure', (
    tester,
  ) async {
    // No Supabase singleton is initialized: failure is local, without a request.
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    scenario.setCurrentPage(DevPage.profile);
    await _mount(tester);
    await _select(tester, 'profile-membership-one');
    expect(AppState.instance.plan, ZyraPlan.basic);
    expect(_fixture.failure, contains('Membership did not change'));
    expect(find.byKey(const ValueKey('dev_page_option_error')), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_page_options_dropdown_Membership')),
      findsNothing,
    );
  });
}
