import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dashboard_lab_controls.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_dashboard_lab.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/screens/wali/wali_dashboard_screen.dart';
import 'package:zyra/services/zyra_dashboard_updates_service.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

final scenario = ZyraDevScenario.instance;
final preview = SupportiveDashboardPreview.instance;

final _categoryDropdowns = find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'dev_page_options_dropdown_',
      ),
);

List<ZyraDevPageOption> options([
  ZyraDashboardRole role = ZyraDashboardRole.seeker,
]) => zyraDashboardPageOptions(scenario, role);

Future<void> select(
  String suffix, [
  ZyraDashboardRole role = ZyraDashboardRole.seeker,
]) async {
  final choice = options(
    role,
  ).singleWhere((option) => option.id.endsWith(suffix));
  expect(choice.onSelected, isNotNull);
  await choice.onSelected!();
}

DashboardSnapshot emptySnapshot() => const DashboardSnapshot(
  role: DashboardRole.seeker,
  onboarding: DashboardSource.available([]),
  journeys: DashboardSource.available(
    DashboardJourneyState(
      summary: DashboardJourneySummary(
        id: 'test-searching',
        kind: DashboardJourneyKind.searching,
        title: 'Ready for introductions',
      ),
    ),
  ),
  updates: DashboardSource.available([]),
  guardianInvitations: DashboardSource.available([]),
  insights: DashboardSource.available([]),
);

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    preview.reset();
    scenario
      ..resetDashboardLab()
      ..setDashboardLabEnabled(false)
      ..setWaliRole(WaliRole.main)
      ..setUseLiveGuardianData(false);
    AppState.instance.setWaliRealLinkedSeekers(const []);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    preview.reset();
    scenario.resetDashboardLab();
  });

  test(
    'Now has 40 content choices including resume request and no design group',
    () {
      final catalog = options();
      expect(catalog, hasLength(40));
      expect(catalog.map((choice) => choice.id).toSet(), hasLength(40));
      final counts = <String, int>{};
      for (final choice in catalog) {
        counts.update(choice.group, (value) => value + 1, ifAbsent: () => 1);
      }
      expect(counts, {
        'Page view': 6,
        'What Needs You': 8,
        'Current status': 6,
        'What Changed': 9,
        'From ZYRA': 8,
        'Updates availability': 3,
      });
      expect(catalog.take(6).map((choice) => choice.label), [
        'Current page data',
        'All Now sections',
        'All clear',
        'Several actions',
        'Recent changes together',
        'From ZYRA example',
      ]);
      expect(
        catalog.map((choice) => choice.label),
        isNot(
          contains(anyOf('APP SURFACE', 'DASHBOARD TAB', 'Dashboard testing')),
        ),
      );
      expect(
        catalog.map((choice) => choice.group),
        isNot(contains('Design comparison')),
      );
      expect(catalog.where((choice) => choice.selected), isEmpty);
    },
  );

  test(
    'all existing Now card choices dispatch to their exact owners',
    () async {
      for (final value in SupportiveActionExample.values) {
        await select('-action-${value.name}');
        expect(preview.action, value);
        expect(preview.scenario, SupportivePreviewScenario.oneAction);
        expect(preview.tabIndex, 0);
      }
      for (final value in SupportiveStatusExample.values) {
        await select('-status-${value.name}');
        expect(preview.status, value);
        expect(preview.scenario, SupportivePreviewScenario.statusExample);
      }
      for (final value in SupportiveChangeExample.values) {
        await select('-change-${value.name}');
        expect(preview.change, value);
        expect(preview.scenario, SupportivePreviewScenario.changed);
      }
      for (final value in SupportiveEditorialExample.values) {
        await select('-editorial-${value.name}');
        expect(preview.editorial, value);
        expect(preview.scenario, SupportivePreviewScenario.editorial);
      }
      expect(scenario.dashboardLabEnabled, isFalse);
      expect(preview.useCurrentSources, isFalse);
    },
  );

  test('recent changes contains exactly the three existing change cards', () async {
    preview.selectChange(SupportiveChangeExample.mainChanged);
    await select('-changes');
    final fixture = preview.fixture;
    final cards = mergeSupportiveCards(
      supportiveCardsFromResolution(
        fixture.resolution,
        comparisonClock: SupportiveDashboardFixtures.clock,
      ),
      fixture.cards,
    );
    expect(cards, hasLength(3));
    expect(cards.map((card) => card.section).toSet(), {
      SupportiveSection.changed,
    });
    expect(cards.map((card) => card.title).toSet(), {
      'Your Journey with ${AppState.instance.gender == 'female' ? 'Adam' : 'Maryam'} has resumed',
      'Main Guardian changed',
      'Family Review for your Journey with ${AppState.instance.gender == 'female' ? 'Adam' : 'Maryam'} is complete',
    });
    expect(fixture.cards, isEmpty);
    expect(fixture.resolution.otherActions, isEmpty);
    expect(fixture.resolution.intelligence, isEmpty);
  });

  test('Updates choices retain the existing truthful source states', () async {
    await select('-loading');
    expect(
      preview.fixture.resolution.updatesState,
      DashboardSectionState.loading,
    );
    await select('-failed');
    expect(
      preview.fixture.resolution.updatesState,
      DashboardSectionState.unavailable,
    );
    await select('-last-known');
    expect(preview.fixture.resolution.updatesAreLastKnown, isTrue);
    expect(preview.fixture.resolution.recently, isNotEmpty);
  });

  test('Insights retains 24 content choices and no design comparisons', () {
    scenario.setDashboardTab(ZyraDashboardTab.insights);
    final catalog = options();
    expect(catalog, hasLength(24));
    expect(catalog.map((choice) => choice.id).toSet(), hasLength(24));
    expect(catalog.map((choice) => choice.label), [
      'Current page data',
      'All four categories',
      'No insights yet',
      'Insights unavailable',
      'Family values',
      'Deen — sensitive example',
      'Helpful reflections',
      'Earlier family involvement',
      'Completed Journeys',
      'Paused Journeys',
      'Repeated ending stage',
      'Communication pace',
      'Personalised guidance',
      'General guidance',
      'Communication',
      'Shared values',
      'Family involvement',
      'Pace',
      'Clarity',
      'Discuss location earlier',
      'Involve family earlier',
      'Clarify expectations',
      'Take more time',
      'Communicate more directly',
    ]);
    expect(
      catalog.map((choice) => choice.label),
      isNot(contains('Insights loading')),
    );
    expect(
      catalog.map((choice) => choice.group),
      isNot(contains('Design comparison')),
    );
    expect(catalog.where((choice) => choice.selected), isEmpty);
  });

  test(
    'all Insights and reflection choices dispatch without changing tab',
    () async {
      scenario.setDashboardTab(ZyraDashboardTab.insights);
      for (final value in SupportiveInsightExample.values.where(
        (value) => value != SupportiveInsightExample.all,
      )) {
        await select('-insight-${value.name}');
        expect(preview.insight, value);
        expect(preview.tabIndex, 1);
      }
      for (final value in SupportiveReflectionTopic.values) {
        await select('-reflection-${value.name}');
        expect(preview.reflection, value);
        expect(preview.insight, SupportiveInsightExample.reflectionTheme);
        expect(preview.tabIndex, 1);
      }
      await select('-insight-reflectionTheme');
      expect(preview.reflection, SupportiveReflectionTopic.pace);
      await select('-empty');
      expect(preview.fixture.cards, isEmpty);
      expect(
        preview.fixture.resolution.insightsState,
        DashboardSectionState.available,
      );
      await select('-failed');
      expect(
        preview.fixture.resolution.insightsState,
        DashboardSectionState.unavailable,
      );
    },
  );

  test(
    'current data preserves the actual tab when preview is activated',
    () async {
      scenario.setDashboardTab(ZyraDashboardTab.insights);
      expect(preview.tabIndex, 0);
      await select('-current');
      expect(preview.enabled, isTrue);
      expect(preview.useCurrentSources, isTrue);
      expect(preview.tabIndex, 1);
      expect(
        zyraDashboardOptionsTitle(scenario, ZyraDashboardRole.seeker),
        'Insights',
      );
      preview.selectTab(0);
      expect(
        zyraDashboardOptionsTitle(scenario, ZyraDashboardRole.seeker),
        'Now',
      );
      expect(options(), hasLength(40));
      expect(scenario.dashboardTab, ZyraDashboardTab.insights);
    },
  );

  testWidgets(
    'fresh developer My ZYRA stays blank until a dropdown option is chosen',
    (tester) async {
      scenario.setDashboardLabEnabled(true);
      await tester.pumpWidget(
        MaterialApp(
          home: SeekerDashboardScreen(
            unreadCount: 0,
            onOpenConnections: () {},
            onOpenGuardian: () {},
            loadDashboard: () async => emptySnapshot(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var dashboard = tester.widget<ZyraQuietDashboard>(
        find.byType(ZyraQuietDashboard),
      );
      expect(dashboard.blankUntilDeveloperSelection, isTrue);
      expect(options().where((option) => option.selected), isEmpty);
      expect(find.text('No Guardian connected yet'), findsNothing);
      expect(find.text('You’re all caught up'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('my-zyra-insights-tab')));
      await tester.pumpAndSettle();
      dashboard = tester.widget<ZyraQuietDashboard>(
        find.byType(ZyraQuietDashboard),
      );
      expect(dashboard.blankUntilDeveloperSelection, isTrue);
      expect(find.text('Insights are part of ZYRA One'), findsNothing);
      expect(find.text('Insights are part of Seeker One'), findsNothing);
      expect(
        find.text('Guardian Insights are part of Guardian One'),
        findsNothing,
      );
      expect(
        find.text('Insights will grow with your ZYRA experience'),
        findsNothing,
      );

      await select('-empty');
      await tester.pumpAndSettle();
      dashboard = tester.widget<ZyraQuietDashboard>(
        find.byType(ZyraQuietDashboard),
      );
      expect(dashboard.blankUntilDeveloperSelection, isFalse);
      expect(
        find.text('Insights will grow with your ZYRA experience'),
        findsOneWidget,
      );
    },
  );

  test(
    'equivalent aliases remain selected only while their state is current',
    () async {
      await select('-editorial');
      expect(
        options().where((option) => option.selected).map((option) => option.id),
        ['seeker-now-editorial', 'seeker-now-editorial-productUpdate'],
      );
      preview.selectEditorial(SupportiveEditorialExample.newsletter);
      expect(
        options()
            .singleWhere((option) => option.id == 'seeker-now-editorial')
            .selected,
        isFalse,
      );
      preview.selectTab(1);
      await select('-insight-reflectionTheme');
      expect(
        options().where((option) => option.selected).map((option) => option.id),
        [
          'seeker-insights-insight-reflectionTheme',
          'seeker-insights-reflection-pace',
        ],
      );
      preview.selectReflection(SupportiveReflectionTopic.communication);
      expect(
        options()
            .singleWhere(
              (option) =>
                  option.id == 'seeker-insights-insight-reflectionTheme',
            )
            .selected,
        isFalse,
      );
    },
  );

  test(
    'revoked authority and release mode cannot create sample state',
    () async {
      final callback = options()
          .singleWhere((option) => option.id == 'seeker-now-all')
          .onSelected!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await callback();
      expect(preview.enabled, isFalse);
      final fixture = SupportiveDashboardFixtures.build(
        SupportivePreviewScenario.recentChanges,
      );
      expect(fixture.cards, isEmpty);
      expect(fixture.resolution.recently, isEmpty);
      for (final authorized in [false, true]) {
        expect(
          supportivePreviewAllowed(
            isRelease: true,
            developerAuthorized: authorized,
          ),
          isFalse,
        );
      }
    },
  );

  test(
    'Guardian uses only existing role catalog, not Seeker samples',
    () async {
      final now = options(ZyraDashboardRole.guardian);
      expect(
        now,
        hasLength(
          1 +
              ZyraGuardianDashboardTodayState.values.length +
              ZyraDashboardUpdatesState.values.length +
              2,
        ),
      );
      expect(now.map((option) => option.id).toSet(), hasLength(now.length));
      expect(now.any((option) => option.id.startsWith('seeker')), isFalse);
      scenario.setWaliRole(WaliRole.additional);
      await select('-state-activeJourney', ZyraDashboardRole.guardian);
      expect(scenario.waliRole, WaliRole.additional);
      await select('-state-mainGuardian', ZyraDashboardRole.guardian);
      expect(scenario.waliRole, WaliRole.main);
      scenario.setDashboardTab(ZyraDashboardTab.insights);
      expect(
        options(ZyraDashboardRole.guardian),
        hasLength(1 + ZyraGuardianDashboardInsightsState.values.length + 2),
      );
      await select('-state-insufficient', ZyraDashboardRole.guardian);
      expect(
        scenario.dashboardGuardianInsightsState,
        ZyraGuardianDashboardInsightsState.insufficient,
      );
      expect(scenario.dashboardGuardianPremium, isTrue);
      await select('-current', ZyraDashboardRole.guardian);
      expect(scenario.dashboardLabEnabled, isFalse);
      expect(scenario.dashboardTab, ZyraDashboardTab.insights);
      expect(preview.enabled, isFalse);
    },
  );

  testWidgets('host-provided choices have their own category dropdown', (
    tester,
  ) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZyraDashboardLabControls(
              scenario: scenario,
              additionalOptions: [
                ZyraDevPageOption(
                  id: 'extra-role',
                  label: 'Existing role choice',
                  group: 'Role',
                  onSelected: () => selected = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final pageOptions = tester
        .widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions))
        .options;
    expect(
      _categoryDropdowns,
      findsNWidgets(pageOptions.map((option) => option.group).toSet().length),
    );
    for (final group in pageOptions.map((option) => option.group).toSet()) {
      expect(
        find.byKey(ValueKey('dev_page_options_dropdown_$group')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('dev_page_options_dropdown')),
      findsNothing,
    );
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(
      tester
          .widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions))
          .options,
      hasLength(41),
    );
    final group = pageOptions
        .singleWhere((option) => option.id == 'extra-role')
        .group;
    final dropdown = find.byKey(ValueKey('dev_page_options_dropdown_$group'));
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    final extra = find.byKey(const ValueKey('extra-role'));
    expect(find.byKey(ValueKey(pageOptions.first.id)), findsNothing);
    await tester.ensureVisible(extra);
    await tester.pumpAndSettle();
    await tester.tap(extra);
    await tester.pumpAndSettle();
    expect(selected, isTrue);
  });

  testWidgets('Seeker current-data swipe controls options without a tab jump', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SeekerDashboardScreen(
          unreadCount: 0,
          onOpenConnections: () {},
          onOpenGuardian: () {},
          loadDashboard: () async {
            loads++;
            return emptySnapshot();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(scenario.dashboardTab, ZyraDashboardTab.insights);
    expect(scenario.dashboardLabEnabled, isFalse);
    expect(preview.enabled, isFalse);
    expect(options(), hasLength(24));
    await select('-current');
    await tester.pumpAndSettle();
    final dashboard = tester.widget<ZyraQuietDashboard>(
      find.byType(ZyraQuietDashboard),
    );
    expect(dashboard.selectedTabIndex, 1);
    expect(dashboard.fixtureMode, isFalse);
    expect(loads, 1);
    await select('-empty');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
          .selectedTabIndex,
      1,
    );
    expect(
      loads,
      1,
      reason: 'Choosing sample content must not start a live read.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fresh Guardian Dashboard stays blank until data is chosen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WaliDashboardScreen(
          hasGuardianPlus: true,
          loadJourneys: () async => [],
          loadUpdates: () async =>
              ZyraDashboardUpdatesPage(rows: [], nextCursor: null),
          loadOpenReviews: (_) async =>
              const ZyraSourceResult.available(<String>{}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      options(ZyraDashboardRole.guardian).where((option) => option.selected),
      isEmpty,
    );
    expect(
      find.byKey(const ValueKey('guardian-dashboard-right-now')),
      findsNothing,
    );

    await select('-state-noSeekers', ZyraDashboardRole.guardian);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('guardian-dashboard-right-now')),
      findsOneWidget,
    );

    scenario.setDashboardTab(ZyraDashboardTab.insights);
    await tester.pumpAndSettle();
    expect(scenario.dashboardTab, ZyraDashboardTab.insights);
    expect(
      zyraDashboardOptionsTitle(scenario, ZyraDashboardRole.guardian),
      'Insights',
    );
    expect(find.byKey(const ValueKey('guardian-insights-empty')), findsNothing);
    expect(find.byKey(const ValueKey('guardian-dev-insight')), findsNothing);
    expect(
      options(ZyraDashboardRole.guardian).where((option) => option.selected),
      isEmpty,
    );

    await select('-current', ZyraDashboardRole.guardian);
    await tester.pumpAndSettle();
    expect(scenario.dashboardLabEnabled, isFalse);
    expect(
      find.byKey(const ValueKey('guardian-insights-empty')),
      findsOneWidget,
    );

    await select('-state-insufficient', ZyraDashboardRole.guardian);
    await tester.pumpAndSettle();
    expect(scenario.dashboardTab, ZyraDashboardTab.insights);
    expect(find.text('Now'), findsNothing);
    expect(find.text('Insights'), findsNothing);
    expect(
      find.byKey(const ValueKey('guardian-dashboard-fade-empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-insights-empty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
