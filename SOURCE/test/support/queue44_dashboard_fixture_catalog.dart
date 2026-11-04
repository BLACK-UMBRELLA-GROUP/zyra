// Code-only Dashboard samples. No controls, routes or widgets are provided.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zyra/models/zyra_dashboard_lab.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';

@immutable
class ZyraFixtureChoice {
  const ZyraFixtureChoice({
    required this.id,
    required this.label,
    required this.group,
    this.onSelected,
    this.selected = false,
    this.unavailableReason,
  });
  final String id, label, group;
  final FutureOr<void> Function()? onSelected;
  final bool selected;
  final String? unavailableReason;
}

String zyraDashboardOptionsTitle(
  ZyraDevScenario scenario,
  ZyraDashboardRole hostRole,
) {
  final preview = SupportiveDashboardPreview.instance;
  final tab =
      hostRole == ZyraDashboardRole.seeker &&
          SupportiveDashboardPreview.allowed &&
          preview.enabled
      ? ZyraDashboardTab.values[preview.tabIndex]
      : scenario.dashboardTab;
  return tab.label;
}

List<ZyraFixtureChoice> zyraDashboardPageOptions(
  ZyraDevScenario scenario,
  ZyraDashboardRole hostRole,
) => hostRole == ZyraDashboardRole.seeker
    ? _seekerOptions(scenario)
    : _guardianOptions(scenario);

List<ZyraFixtureChoice> _seekerOptions(ZyraDevScenario scenario) {
  final preview = SupportiveDashboardPreview.instance;
  final insights =
      zyraDashboardOptionsTitle(scenario, ZyraDashboardRole.seeker) ==
      'Insights';
  final prefix = insights ? 'seeker-insights' : 'seeker-now';
  final sample = preview.enabled && !preview.useCurrentSources;
  final options = <ZyraFixtureChoice>[];

  void add(
    String id,
    String label,
    String group,
    VoidCallback apply, {
    bool selected = false,
  }) {
    options.add(
      ZyraFixtureChoice(
        id: '$prefix-$id',
        label: label,
        group: group,
        selected: selected,
        unavailableReason: SupportiveDashboardPreview.allowed
            ? null
            : 'Local examples require an authorized non-release build.',
        onSelected: SupportiveDashboardPreview.allowed
            ? () {
                // Recheck at dispatch: a menu may outlive its authorization.
                if (SupportiveDashboardPreview.allowed) apply();
              }
            : null,
      ),
    );
  }

  void state(
    String id,
    String label,
    SupportivePreviewScenario value, {
    String group = 'Page view',
  }) {
    add(
      id,
      label,
      group,
      () => preview.selectScenario(value),
      selected: sample && preview.scenario == value,
    );
  }

  add(
    'current',
    'Current page data',
    'Page view',
    () {
      // Capture before activating the new renderer; its previous session tab
      // must not pull an Insights page back to Now.
      final tab = insights ? 1 : 0;
      preview.selectTab(tab);
      preview.selectSources(true);
      preview.selectView(true);
    },
    selected: preview.enabled && preview.useCurrentSources,
  );

  if (!insights) {
    state('all', 'All Now sections', SupportivePreviewScenario.allNow);
    state('clear', 'All clear', SupportivePreviewScenario.allClear);
    state(
      'several',
      'Several actions',
      SupportivePreviewScenario.severalActions,
    );
    state(
      'changes',
      'Recent changes together',
      SupportivePreviewScenario.recentChanges,
    );
    add(
      'editorial',
      'From ZYRA example',
      'Page view',
      () => preview.selectEditorial(SupportiveEditorialExample.productUpdate),
      selected:
          sample &&
          preview.scenario == SupportivePreviewScenario.editorial &&
          preview.editorial == SupportiveEditorialExample.productUpdate,
    );

    for (final value in SupportiveActionExample.values) {
      add(
        'action-${value.name}',
        value.label,
        'What Needs You',
        () => preview.selectAction(value),
        selected:
            sample &&
            preview.scenario == SupportivePreviewScenario.oneAction &&
            preview.action == value,
      );
    }
    for (final value in SupportiveStatusExample.values) {
      final label = switch (value) {
        SupportiveStatusExample.noGuardian => 'No Guardian connected',
        SupportiveStatusExample.paused => 'Journey paused',
        _ => value.label,
      };
      add(
        'status-${value.name}',
        label,
        'Current status',
        () => preview.selectStatus(value),
        selected:
            sample &&
            preview.scenario == SupportivePreviewScenario.statusExample &&
            preview.status == value,
      );
    }
    for (final value in SupportiveChangeExample.values) {
      add(
        'change-${value.name}',
        value.label,
        'What Changed',
        () => preview.selectChange(value),
        selected:
            sample &&
            preview.scenario == SupportivePreviewScenario.changed &&
            preview.change == value,
      );
    }
    for (final value in SupportiveEditorialExample.values) {
      add(
        'editorial-${value.name}',
        value.label,
        'From ZYRA',
        () => preview.selectEditorial(value),
        selected:
            sample &&
            preview.scenario == SupportivePreviewScenario.editorial &&
            preview.editorial == value,
      );
    }
    state(
      'loading',
      'Updates loading',
      SupportivePreviewScenario.loading,
      group: 'Updates availability',
    );
    state(
      'failed',
      'Updates unavailable',
      SupportivePreviewScenario.failed,
      group: 'Updates availability',
    );
    state(
      'last-known',
      'Last-known updates',
      SupportivePreviewScenario.lastKnown,
      group: 'Updates availability',
    );
    return options;
  }

  add(
    'all',
    'All four categories',
    'Page view',
    () => preview.selectInsight(SupportiveInsightExample.all),
    selected:
        sample &&
        preview.scenario == SupportivePreviewScenario.insightsPopulated &&
        preview.insight == SupportiveInsightExample.all,
  );
  state('empty', 'No insights yet', SupportivePreviewScenario.insightsEmpty);
  state(
    'failed',
    'Insights unavailable',
    SupportivePreviewScenario.insightsFailed,
  );

  const insightChoices = [
    (SupportiveInsightExample.familyValues, 'Family values', 'What’s Working'),
    (
      SupportiveInsightExample.deen,
      'Deen — sensitive example',
      'What’s Working',
    ),
    (
      SupportiveInsightExample.helpfulReflections,
      'Helpful reflections',
      'What’s Working',
    ),
    (
      SupportiveInsightExample.familyInvolvement,
      'Earlier family involvement',
      'What’s Working',
    ),
    (
      SupportiveInsightExample.completedJourneys,
      'Completed Journeys',
      'What Keeps Happening',
    ),
    (
      SupportiveInsightExample.pausedJourneys,
      'Paused Journeys',
      'What Keeps Happening',
    ),
    (
      SupportiveInsightExample.repeatedStage,
      'Repeated ending stage',
      'What Keeps Happening',
    ),
    (
      SupportiveInsightExample.reflectionTheme,
      'Communication pace',
      'What You’ve Learned',
    ),
    (
      SupportiveInsightExample.personalisedGuide,
      'Personalised guidance',
      'What May Help',
    ),
    (
      SupportiveInsightExample.generalGuide,
      'General guidance',
      'What May Help',
    ),
  ];
  for (final (value, label, group) in insightChoices) {
    add(
      'insight-${value.name}',
      label,
      group,
      () {
        if (value == SupportiveInsightExample.reflectionTheme) {
          preview.selectReflection(SupportiveReflectionTopic.pace);
        } else {
          preview.selectInsight(value);
        }
      },
      selected:
          sample &&
          preview.scenario == SupportivePreviewScenario.insightsPopulated &&
          preview.insight == value &&
          (value != SupportiveInsightExample.reflectionTheme ||
              preview.reflection == SupportiveReflectionTopic.pace),
    );
  }
  for (final value in SupportiveReflectionTopic.values) {
    final parts = value.label.split(' · ');
    add(
      'reflection-${value.name}',
      parts.last,
      value.index < 5
          ? 'Reflection topics · positive'
          : 'Reflection topics · different approach',
      () => preview.selectReflection(value),
      selected:
          sample &&
          preview.scenario == SupportivePreviewScenario.insightsPopulated &&
          preview.insight == SupportiveInsightExample.reflectionTheme &&
          preview.reflection == value,
    );
  }
  return options;
}

List<ZyraFixtureChoice> _guardianOptions(ZyraDevScenario scenario) {
  final insights = scenario.dashboardTab == ZyraDashboardTab.insights;
  final prefix = insights ? 'guardian-insights' : 'guardian-now';
  final options = <ZyraFixtureChoice>[];

  void add(
    String id,
    String label,
    String group,
    VoidCallback apply, {
    bool selected = false,
  }) {
    options.add(
      ZyraFixtureChoice(
        id: '$prefix-$id',
        label: label,
        group: group,
        selected: selected,
        onSelected: () {
          if (ZyraDeveloperAccess.canUseDeveloperTools) {
            scenario.markDashboardGuardianOptionSelected(
              insights ? ZyraDashboardTab.insights : ZyraDashboardTab.now,
            );
            apply();
          }
        },
      ),
    );
  }

  add(
    'current',
    'Current page data',
    'Page view',
    () => scenario.setDashboardLabEnabled(false),
    selected:
        scenario.dashboardGuardianOptionSelected(
          insights ? ZyraDashboardTab.insights : ZyraDashboardTab.now,
        ) &&
        !scenario.dashboardLabEnabled,
  );
  if (!insights) {
    for (final value in ZyraGuardianDashboardTodayState.values) {
      add(
        'state-${value.name}',
        value.label,
        'Guardian Now',
        () {
          final role = scenario.waliRole;
          scenario.setDashboardGuardianTodayState(value);
          if (value != ZyraGuardianDashboardTodayState.mainGuardian &&
              value != ZyraGuardianDashboardTodayState.additionalGuardian) {
            scenario.setWaliRole(role);
          }
          scenario.setDashboardLabEnabled(true);
        },
        selected:
            scenario.dashboardGuardianOptionSelected(ZyraDashboardTab.now) &&
            scenario.dashboardLabEnabled &&
            scenario.dashboardGuardianTodayState == value,
      );
    }
    for (final value in ZyraDashboardUpdatesState.values) {
      add(
        'updates-${value.name}',
        value.label,
        'Updates',
        () {
          scenario.setDashboardUpdatesState(value);
          scenario.setDashboardLabEnabled(true);
        },
        selected:
            scenario.dashboardGuardianOptionSelected(ZyraDashboardTab.now) &&
            scenario.dashboardLabEnabled &&
            scenario.dashboardUpdatesState == value,
      );
    }
  } else {
    for (final value in ZyraGuardianDashboardInsightsState.values) {
      add(
        'state-${value.name}',
        value.label,
        'Guardian Insights',
        () {
          scenario.setDashboardGuardianInsightsState(value);
          // These are already-rendered local examples, not a grant of real
          // Guardian access or a new source of family intelligence.
          scenario.setDashboardGuardianPremium(true);
          scenario.setDashboardLabEnabled(true);
        },
        selected:
            scenario.dashboardGuardianOptionSelected(
              ZyraDashboardTab.insights,
            ) &&
            scenario.dashboardLabEnabled &&
            scenario.dashboardGuardianPremium &&
            scenario.dashboardGuardianInsightsState == value,
      );
    }
  }
  for (final access in [false, true]) {
    add(
      access ? 'access' : 'no-access',
      access ? 'Guardian access' : 'No access',
      'Guardian access',
      () {
        scenario.setDashboardGuardianPremium(access);
        scenario.setDashboardLabEnabled(true);
      },
      selected:
          scenario.dashboardGuardianOptionSelected(
            insights ? ZyraDashboardTab.insights : ZyraDashboardTab.now,
          ) &&
          scenario.dashboardLabEnabled &&
          scenario.dashboardGuardianPremium == access,
    );
  }
  return options;
}
