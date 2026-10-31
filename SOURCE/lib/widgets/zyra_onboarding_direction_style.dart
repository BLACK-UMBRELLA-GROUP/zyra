// Shared onboarding visual language. Ordinary onboarding uses the selected
// Luma direction, including protected developer rehearsals.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';

/// The developer flow may override this scope; it is deliberately independent
/// of the preview-picker enum so normal onboarding never imports developer code.
class OnboardingPreviewStyle extends InheritedWidget {
  const OnboardingPreviewStyle({
    super.key,
    required this.directionName,
    required super.child,
  }) : assert(directionName == 'luma');

  final String directionName;

  /// A preview-only lookup, retained for isolated design studies. Shared
  /// onboarding screens use [effectiveStyleOf] so they also receive Luma.
  static OnboardingPreviewStyle? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OnboardingPreviewStyle>();
    return scope;
  }

  /// Founder-selected visual default for ordinary onboarding. This resolver
  /// changes presentation only: it grants no preview or developer authority.
  /// Protected rehearsals use this same selected style.
  static OnboardingPreviewStyle? effectiveStyleOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OnboardingPreviewStyle>();
    if (scope != null) {
      return scope;
    }
    return const OnboardingPreviewStyle(
      directionName: 'luma',
      child: SizedBox.shrink(),
    );
  }

  bool get centered => true;
  bool get spacious => true;
  double get titleSize => 29;
  double get cardRadiusValue => 30;
  BorderRadius get cardRadius => BorderRadius.circular(cardRadiusValue);
  double get buttonRadius => 999;
  double get cardVerticalPadding => 21;
  double get sectionGap => 29;
  IconData get markerIcon => Icons.auto_awesome_rounded;

  /// Keep the Midnight Plum / gold palette. Composition, not a new brand
  /// colour, distinguishes each option.
  LinearGradient get backgroundGradient => ZyraColors.brandGradient;

  BoxDecoration cardDecoration({bool selected = false}) {
    return BoxDecoration(
      color: selected
          ? ZyraColors.journeyGold.withValues(alpha: .14)
          : ZyraColors.frostFill,
      border: Border.all(
        color: selected
            ? ZyraColors.journeyGold.withValues(alpha: .68)
            : ZyraColors.frostBorder,
        width: .7,
      ),
      borderRadius: cardRadius,
      boxShadow: [
        BoxShadow(
          color: ZyraColors.journeyGold.withValues(alpha: .055),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ],
    );
  }

  ButtonStyle get primaryButtonStyle => FilledButton.styleFrom(
    backgroundColor: ZyraColors.goldTextFill,
    foregroundColor: ZyraColors.luxuryDarkPurple,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    minimumSize: const Size.fromHeight(50),
  );

  @override
  bool updateShouldNotify(OnboardingPreviewStyle oldWidget) =>
      directionName != oldWidget.directionName;
}

/// One small, repeatable motif throughout a selected route. It stays purely
/// decorative: no borrowed artwork, labels, hit areas or user data.
class OnboardingPreviewAccent extends StatelessWidget {
  const OnboardingPreviewAccent({
    super.key,
    required this.style,
    this.size = 84,
    this.progress = .5,
  });

  final OnboardingPreviewStyle style;
  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        key: ValueKey('onboarding-preview-accent-${style.directionName}'),
        painter: _OnboardingPreviewAccentPainter(
          style.directionName,
          progress.clamp(0.0, 1.0).toDouble(),
        ),
      ),
    ),
  );
}

/// Fractional progress belongs to a named section. Exact journey stages use
/// the step constructor; decorative cells must never imply a false page count.
class OnboardingPreviewProgress extends StatelessWidget {
  const OnboardingPreviewProgress({
    super.key,
    required this.style,
    required this.progress,
    this.semanticValue,
  }) : currentStep = null,
       totalSteps = null,
       assert(progress != null);

  const OnboardingPreviewProgress.steps({
    super.key,
    required this.style,
    required int currentStep,
    required int totalSteps,
  }) : progress = null,
       semanticValue = null,
       currentStep = currentStep,
       totalSteps = totalSteps,
       assert(currentStep > 0),
       assert(totalSteps > 0),
       assert(currentStep <= totalSteps);

  final OnboardingPreviewStyle style;
  final double? progress;
  final String? semanticValue;
  final int? currentStep;
  final int? totalSteps;

  @override
  Widget build(BuildContext context) {
    final step = currentStep;
    if (step != null) {
      return OnboardingStageProgress(
        key: ValueKey('onboarding-preview-progress-${style.directionName}'),
        currentStep: step,
        totalSteps: totalSteps!,
      );
    }
    final value = progress!.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: semanticValue ?? 'Progress in this section',
      value: '${(value * 100).round()}%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            key: ValueKey('onboarding-preview-progress-${style.directionName}'),
            height: 5,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: ZyraColors.foreground.withValues(alpha: .14),
              valueColor: AlwaysStoppedAnimation<Color>(ZyraColors.journeyGold),
            ),
          ),
        ),
      ),
    );
  }
}

/// A finite, numbered journey indicator shared by ordinary onboarding and
/// every visual direction. The active segment and completed segments are
/// distinct, while screen readers hear the exact stage position once.
class OnboardingStageProgress extends StatelessWidget {
  const OnboardingStageProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  }) : assert(currentStep > 0),
       assert(totalSteps > 0),
       assert(currentStep <= totalSteps);

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Sign-up journey stage',
    value: 'Stage $currentStep of $totalSteps',
    child: ExcludeSemantics(
      child: SizedBox(
        height: 7,
        child: Row(
          children: [
            for (var index = 0; index < totalSteps; index++) ...[
              if (index != 0) const SizedBox(width: 7),
              Expanded(
                child: AnimatedContainer(
                  key: ValueKey('onboarding-stage-progress-segment-$index'),
                  duration: const Duration(milliseconds: 220),
                  height: 5,
                  decoration: BoxDecoration(
                    color: index == currentStep - 1
                        ? ZyraColors.journeyGold
                        : index < currentStep - 1
                        ? ZyraColors.journeyGold.withValues(alpha: .65)
                        : ZyraColors.foreground.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _OnboardingPreviewAccentPainter extends CustomPainter {
  const _OnboardingPreviewAccentPainter(this.directionName, this.progress);

  final String directionName;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);
    final gold = ZyraColors.journeyGold;
    final muted = gold.withValues(alpha: .25);
    final softStroke = Paint()
      ..color = muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = gold.withValues(alpha: .16);
    canvas.drawCircle(const Offset(50, 50), 38, softStroke);
    canvas.drawCircle(const Offset(50, 50), 27, fill);
    canvas.drawCircle(const Offset(50, 50), 11, Paint()..color = gold);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        Offset(50 + 43 * math.cos(a), 50 + 43 * math.sin(a)),
        2,
        Paint()..color = gold,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_OnboardingPreviewAccentPainter oldDelegate) =>
      directionName != oldDelegate.directionName ||
      progress != oldDelegate.progress;
}
