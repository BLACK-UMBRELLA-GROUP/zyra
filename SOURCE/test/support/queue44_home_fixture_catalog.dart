// Historical callback and label data available to tests through code only.
import 'package:flutter/foundation.dart';
import 'package:zyra/widgets/zyra_splash_artwork.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';
import 'queue44_dashboard_fixture_catalog.dart';
import 'queue44_gold_fixture.dart';
import 'queue44_onboarding_interaction_fixture.dart';
import 'queue44_onboarding_transition_fixture.dart';
import 'queue44_welcome_motion_fixture.dart';
import 'queue44_settings_fixture.dart';

class Queue44HomeCatalog {
  Queue44HomeCatalog({
    bool busy = false,
    VoidCallback? home,
    VoidCallback? restart,
    VoidCallback? reset,
    VoidCallback? accounts,
  }) : commands = Map.unmodifiable({
         'dev_home_navigation': busy ? null : home,
         'dev_home_login': restart,
         'dev_reset_state': busy ? null : reset,
         'dev_switch_accounts': accounts,
       }),
       enabled = !busy;
  final Map<String, VoidCallback?> commands;
  final bool enabled;
  static const sections = [
    'navigation',
    'discovery_direction',
    'splash',
    'onboarding',
    'settings',
    'account',
  ];
  List<ZyraFixtureChoice> get choices => [
    for (final value in ZyraSplashDirection.values)
      ZyraFixtureChoice(
        id: 'dev_splash_${value.name}',
        label: value.label,
        group: 'Splash',
      ),
    for (final value in ZyraOnboardingDirection.values)
      ZyraFixtureChoice(
        id: 'dev_onboarding_${value.name}',
        label: value.label,
        group: 'Onboarding',
      ),
    for (final value in ZyraOnboardingStoryNavigation.values)
      ZyraFixtureChoice(
        id: 'dev_onboarding_story_${value.name}',
        label: value == ZyraOnboardingStoryNavigation.tapThrough
            ? 'Tap through'
            : 'Scroll down',
        group: 'Onboarding',
      ),
    for (final value in ZyraOnboardingAdvanceMode.values)
      ZyraFixtureChoice(
        id: 'dev_onboarding_advance_${value.name}',
        label: value == ZyraOnboardingAdvanceMode.continueButton
            ? 'Continue'
            : 'Animated down arrow',
        group: 'Onboarding',
      ),
    ...queue44MotionChoices(enabled: enabled),
    for (final value in ZyraSettingsDesign.values)
      ZyraFixtureChoice(
        id: 'dev_settings_design_${value.name}',
        label: value == ZyraSettingsDesign.current ? 'Current' : 'Smooth cards',
        group: 'Settings',
        onSelected: enabled ? () => ZyraDevSettingsDesign.select(value) : null,
      ),
  ];
}

List<ZyraFixtureChoice> queue44MotionChoices({bool enabled = true}) => [
  for (final value in ZyraWelcomeTextMotion.values.where(
    (value) => value.family == ZyraWelcomeTextMotionFamily.descent,
  ))
    ZyraFixtureChoice(
      id: 'dev_welcome_text_motion_${value.name}',
      label: value.label,
      group: 'Opening slide motion',
      onSelected: enabled
          ? () {
              ZyraDevWelcomeTextMotion.select(value);
            }
          : null,
    ),
  for (final value in ZyraOnboardingGoldDesign.values)
    ZyraFixtureChoice(
      id: 'dev_onboarding_gold_design_${value.name}',
      label: value.label,
      group: 'Opening gold accents',
      onSelected: enabled
          ? () {
              ZyraDevOnboardingGoldDesign.select(value);
            }
          : null,
    ),
  for (final value in ZyraOnboardingGoldMotion.values)
    ZyraFixtureChoice(
      id: 'dev_onboarding_gold_motion_${value.name}',
      label: value.label,
      group: 'Gold animation',
      onSelected: enabled
          ? () {
              ZyraDevOnboardingGoldMotion.select(value);
            }
          : null,
    ),
  for (final value in ZyraOnboardingPageTransition.values)
    ZyraFixtureChoice(
      id: 'dev_onboarding_transition_${value.name}',
      label: value.label,
      group: 'Page transition',
      onSelected: enabled
          ? () {
              ZyraDevOnboardingTransition.select(value);
            }
          : null,
    ),
];
