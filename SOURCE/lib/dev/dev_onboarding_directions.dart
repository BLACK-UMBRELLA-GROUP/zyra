// Every style starts the protected local onboarding journey at Welcome.
// In-flow choices restart its nested Navigator; live Auth stays unchanged.
import 'package:flutter/material.dart';

import '../services/zyra_developer_access.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_onboarding_study.dart';
import '../widgets/zyra_segmented_toggle.dart';
import 'dev_onboarding_gold_design.dart';
import 'dev_onboarding_interaction.dart';
import 'dev_onboarding_transition.dart';
import 'dev_onboarding_welcome_motion.dart';
import 'zyra_dev_signup.dart';
import 'zyra_dev_surface_coordinator.dart';

export '../widgets/zyra_onboarding_study.dart' show ZyraOnboardingDirection;

/// A separate Home category shared by Seeker, Guardian and entry previews.
/// The chosen style is session-local, never a live onboarding default.
class DevOnboardingDirectionPicker extends StatelessWidget {
  const DevOnboardingDirectionPicker({
    super.key,
    this.enabled = true,
    this.onBeforeOpen,
  });

  final bool enabled;
  final VoidCallback? onBeforeOpen;

  @override
  Widget build(BuildContext context) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Onboarding directions', style: ZyraText.body(size: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final direction in ZyraOnboardingDirection.values)
              ActionChip(
                key: ValueKey('dev_onboarding_${direction.name}'),
                label: Text(direction.label, style: ZyraText.body(size: 11)),
                onPressed: !enabled
                    ? null
                    : () {
                        // Capability may be revoked while this panel is open.
                        // The full flow also observes revocation.
                        if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
                        onBeforeOpen?.call();
                        if (ZyraDevSurfaceCoordinator.instance
                            .restartOnboarding(direction)) {
                          return;
                        }
                        ZyraDevSignUp.start(context, direction: direction);
                      },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Opening story', style: ZyraText.body(size: 13)),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: ZyraDevOnboardingStoryNavigation.changes,
          builder: (context, _) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in ZyraOnboardingStoryNavigation.values)
                ActionChip(
                  key: ValueKey('dev_onboarding_story_${mode.name}'),
                  backgroundColor:
                      ZyraDevOnboardingStoryNavigation.current == mode
                      ? ZyraColors.frostSelectedFill
                      : ZyraColors.frostFill,
                  label: Text(
                    mode == ZyraOnboardingStoryNavigation.tapThrough
                        ? 'Tap through'
                        : 'Scroll down',
                    style: ZyraText.body(size: 11),
                  ),
                  onPressed: enabled
                      ? () => ZyraDevOnboardingStoryNavigation.select(mode)
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Onboarding navigation', style: ZyraText.body(size: 13)),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: ZyraDevOnboardingInteraction.changes,
          builder: (context, _) {
            final selected = ZyraDevOnboardingInteraction.current;
            final reduceMotion = MediaQuery.disableAnimationsOf(context);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: ZyraColors.frostFill,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: ZyraColors.frostBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    for (final mode in ZyraOnboardingAdvanceMode.values)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected == mode,
                          enabled: enabled,
                          label:
                              mode == ZyraOnboardingAdvanceMode.continueButton
                              ? 'Continue button'
                              : 'Animated down arrow',
                          child: InkWell(
                            key: ValueKey(
                              'dev_onboarding_advance_${mode.name}',
                            ),
                            borderRadius: BorderRadius.circular(19),
                            onTap: enabled
                                ? () =>
                                      ZyraDevOnboardingInteraction.select(mode)
                                : null,
                            child: AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : ZyraSegmentedMotion.selectionDuration,
                              curve: ZyraSegmentedMotion.selectionCurve,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected == mode
                                    ? ZyraColors.frostSelectedFill
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: selected == mode
                                      ? ZyraColors.frostSelectedBorder
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                mode == ZyraOnboardingAdvanceMode.continueButton
                                    ? 'Continue'
                                    : 'Animated down arrow',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ZyraText.button(
                                  size: 11,
                                  color: selected == mode
                                      ? ZyraColors.foreground
                                      : ZyraColors.foregroundSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Kept in its own developer-toggle section: changing the motion does not
/// restart the four-page welcome story or alter an ordinary signup route.
class DevOnboardingTransitionPicker extends StatelessWidget {
  const DevOnboardingTransitionPicker({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ZyraDeveloperAccess.authorizationChanges,
      ZyraDevOnboardingTransition.changes,
      ZyraDevWelcomeTextMotion.changes,
      ZyraDevWelcomePulseIntensity.changes,
      ZyraDevWelcomePulseDesign.changes,
      ZyraDevOnboardingGoldDesign.changes,
      ZyraDevOnboardingGoldMotion.changes,
    ]),
    builder: (context, _) {
      if (!ZyraDeveloperAccess.canUseDeveloperTools) {
        return const SizedBox.shrink();
      }
      final selected = ZyraDevOnboardingTransition.current;
      final welcomeSelected = ZyraDevWelcomeTextMotion.current;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Opening slide motion', style: ZyraText.body(size: 13)),
          const SizedBox(height: 8),
          for (final family in [ZyraWelcomeTextMotionFamily.descent]) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final motion in ZyraWelcomeTextMotion.values.where(
                  (candidate) => candidate.family == family,
                ))
                  Semantics(
                    button: true,
                    selected: welcomeSelected == motion,
                    enabled: enabled,
                    label: motion.label,
                    child: InkWell(
                      key: ValueKey('dev_welcome_text_motion_${motion.name}'),
                      borderRadius: BorderRadius.circular(18),
                      onTap: enabled
                          ? () => ZyraDevWelcomeTextMotion.select(motion)
                          : null,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: welcomeSelected == motion
                              ? ZyraColors.frostSelectedFill
                              : ZyraColors.frostFill,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: welcomeSelected == motion
                                ? ZyraColors.frostSelectedBorder
                                : ZyraColors.frostBorder,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Text(
                            motion.label,
                            style: ZyraText.button(
                              size: 11,
                              color: welcomeSelected == motion
                                  ? ZyraColors.foreground
                                  : ZyraColors.foregroundSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text('Opening gold accents', style: ZyraText.body(size: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final design in ZyraOnboardingGoldDesign.values)
                Semantics(
                  button: true,
                  selected: ZyraDevOnboardingGoldDesign.current == design,
                  enabled: enabled,
                  label: design.label,
                  child: InkWell(
                    key: ValueKey('dev_onboarding_gold_design_${design.name}'),
                    borderRadius: BorderRadius.circular(18),
                    onTap: enabled
                        ? () => ZyraDevOnboardingGoldDesign.select(design)
                        : null,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ZyraDevOnboardingGoldDesign.current == design
                            ? ZyraColors.frostSelectedFill
                            : ZyraColors.frostFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: ZyraDevOnboardingGoldDesign.current == design
                              ? ZyraColors.frostSelectedBorder
                              : ZyraColors.frostBorder,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(7, 4, 12, 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ZyraOnboardingGoldSwatch(design),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                design.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: ZyraText.button(size: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Gold animation', style: ZyraText.body(size: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final motion in ZyraOnboardingGoldMotion.values)
                ActionChip(
                  key: ValueKey('dev_onboarding_gold_motion_${motion.name}'),
                  backgroundColor: ZyraDevOnboardingGoldMotion.current == motion
                      ? ZyraColors.frostSelectedFill
                      : ZyraColors.frostFill,
                  label: Text(motion.label, style: ZyraText.body(size: 11)),
                  onPressed: enabled
                      ? () => ZyraDevOnboardingGoldMotion.select(motion)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Separate comparison page transition',
            style: ZyraText.body(size: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final transition in ZyraOnboardingPageTransition.values)
                Semantics(
                  button: true,
                  selected: selected == transition,
                  enabled: enabled,
                  label: transition.label,
                  child: InkWell(
                    key: ValueKey(
                      'dev_onboarding_transition_${transition.name}',
                    ),
                    borderRadius: BorderRadius.circular(18),
                    onTap: enabled
                        ? () => ZyraDevOnboardingTransition.select(transition)
                        : null,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected == transition
                            ? ZyraColors.frostSelectedFill
                            : ZyraColors.frostFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected == transition
                              ? ZyraColors.frostSelectedBorder
                              : ZyraColors.frostBorder,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Text(
                          transition.label,
                          style: ZyraText.button(
                            size: 11,
                            color: selected == transition
                                ? ZyraColors.foreground
                                : ZyraColors.foregroundSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}
