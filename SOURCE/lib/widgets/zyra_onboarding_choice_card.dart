import 'zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// The role-choice page's quiet gold/frost language adapted to answers.
/// Selection changes appearance, never card height, visibility or navigation.
class ZyraOnboardingChoiceCard extends StatelessWidget {
  const ZyraOnboardingChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.multiple = false,
  }) : assert(icon == null || leading == null);

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? leading;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 480);
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      selected: multiple ? null : selected,
      checked: multiple ? selected : null,
      inMutuallyExclusiveGroup: !multiple,
      label: label,
      onTap: ZyraTapFeedback.onTap(context, onTap),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOutCubic,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: selected
              ? ZyraColors.journeyGold.withValues(alpha: .13)
              : ZyraColors.frostFill,
          border: Border.all(
            color: selected
                ? ZyraColors.journeyGold.withValues(alpha: .85)
                : ZyraColors.frostBorder,
            width: selected ? 1.2 : .8,
            // Paint weight can change without shifting long-label layout.
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          borderRadius: radius,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ZyraColors.journeyGold.withValues(alpha: .11),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: ZyraColors.journeyGold.withValues(alpha: .04),
            onTap: ZyraTapFeedback.onTap(context, onTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  if (icon != null || leading != null) ...[
                    SizedBox(
                      width: 32,
                      child:
                          leading ??
                          Icon(icon, color: ZyraColors.journeyGold, size: 26),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(label, style: ZyraText.option(size: 17)),
                  ),
                  const SizedBox(width: 14),
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeInOutCubic,
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? ZyraColors.journeyGold.withValues(alpha: .18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(multiple ? 7 : 13),
                      border: Border.all(
                        color: ZyraColors.journeyGold.withValues(
                          alpha: selected ? .9 : .45,
                        ),
                      ),
                    ),
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: duration,
                      curve: Curves.easeInOutCubic,
                      child: const Icon(
                        Icons.check_rounded,
                        color: ZyraColors.journeyGold,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One restrained entry for a whole answer group, not staggered text reveals.
/// A question-specific key lets a new question enter without replaying on tap.
class ZyraOnboardingChoiceEntrance extends StatelessWidget {
  const ZyraOnboardingChoiceEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
    );
  }
}
