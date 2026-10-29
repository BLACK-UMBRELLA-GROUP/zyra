// Protected, session-local gold backdrop comparisons for the opening story.
// These are decorative only: no input, persistence, account or score changes.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/zyra_account_state.dart';
import '../services/zyra_developer_access.dart';
import '../theme/zyra_colors.dart';

enum ZyraOnboardingGoldDesign {
  diagonalDust('Diagonal edge');

  const ZyraOnboardingGoldDesign(this.label);
  final String label;
}

enum ZyraOnboardingGoldMotion {
  pageEntrance('Page entrance'),
  liveDrift('Live drift');

  const ZyraOnboardingGoldMotion(this.label);
  final String label;
}

abstract final class ZyraDevOnboardingGoldMotion {
  static const defaultMotion = ZyraOnboardingGoldMotion.liveDrift;
  static final ValueNotifier<ZyraOnboardingGoldMotion> _selection =
      ValueNotifier(defaultMotion);
  static final ValueNotifier<int> _pageEntry = ValueNotifier(0);
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;
  static Listenable get pageEntries => _pageEntry;
  static ZyraOnboardingGoldMotion get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : defaultMotion;

  static bool select(ZyraOnboardingGoldMotion motion) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = defaultMotion;
    }
    _selection.value = motion;
    return true;
  }

  static void pageEntered() {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    _pageEntry.value++;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = defaultMotion;
      _pageEntry.value = 0;
      return true;
    }());
  }
}

abstract final class ZyraDevOnboardingGoldDesign {
  static const defaultDesign = ZyraOnboardingGoldDesign.diagonalDust;
  static final ValueNotifier<ZyraOnboardingGoldDesign> _selection =
      ValueNotifier(defaultDesign);
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;
  static ZyraOnboardingGoldDesign get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : defaultDesign;

  static bool select(ZyraOnboardingGoldDesign design) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = defaultDesign;
    }
    _selection.value = design;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = defaultDesign;
      return true;
    }());
  }
}

/// Paints under the fixed purple canvas content, never above a tappable page.
class ZyraOnboardingGoldBackdrop extends StatefulWidget {
  const ZyraOnboardingGoldBackdrop({super.key});

  @override
  State<ZyraOnboardingGoldBackdrop> createState() =>
      _ZyraOnboardingGoldBackdropState();
}

class _ZyraOnboardingGoldBackdropState extends State<ZyraOnboardingGoldBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);
  bool _reducedMotion = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    ZyraDevOnboardingGoldMotion.changes.addListener(_startMotion);
    ZyraDevOnboardingGoldMotion.pageEntries.addListener(_onPageEntered);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (!_started || _reducedMotion != reduced) {
      _reducedMotion = reduced;
      _started = true;
      _startMotion();
    }
  }

  void _startMotion() {
    if (!mounted) return;
    _motion.stop();
    if (_reducedMotion) {
      _motion.value = 1;
      return;
    }
    switch (ZyraDevOnboardingGoldMotion.current) {
      case ZyraOnboardingGoldMotion.pageEntrance:
        _motion.duration = const Duration(milliseconds: 1050);
        _motion.forward(from: 0);
      case ZyraOnboardingGoldMotion.liveDrift:
        _motion.duration = const Duration(milliseconds: 4800);
        _motion.repeat();
    }
  }

  void _onPageEntered() {
    if (ZyraDevOnboardingGoldMotion.current ==
        ZyraOnboardingGoldMotion.pageEntrance) {
      _startMotion();
    }
  }

  @override
  void dispose() {
    ZyraDevOnboardingGoldMotion.changes.removeListener(_startMotion);
    ZyraDevOnboardingGoldMotion.pageEntries.removeListener(_onPageEntered);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ListenableBuilder(
      listenable: Listenable.merge([
        ZyraDevOnboardingGoldDesign.changes,
        ZyraDevOnboardingGoldMotion.changes,
        _motion,
      ]),
      builder: (context, _) => CustomPaint(
        key: const ValueKey('dev_onboarding_gold_backdrop'),
        painter: ZyraOnboardingGoldPainter(
          ZyraDevOnboardingGoldDesign.current,
          motion: ZyraDevOnboardingGoldMotion.current,
          motionValue: _motion.value,
          reducedMotion: _reducedMotion,
        ),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

/// The small toggle preview uses the same geometry with stronger visibility.
class ZyraOnboardingGoldSwatch extends StatelessWidget {
  const ZyraOnboardingGoldSwatch(this.design, {super.key});
  final ZyraOnboardingGoldDesign design;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(7),
    child: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: SizedBox(
        width: 56,
        height: 36,
        child: CustomPaint(
          painter: ZyraOnboardingGoldPainter(design, preview: true),
        ),
      ),
    ),
  );
}

// Normalised, deterministic coordinates for the selected diagonal dust.
const _goldDustPoints = <(double, double, double)>[
  (.08, .12, .38),
  (.23, .15, .58),
  (.39, .09, .32),
  (.66, .16, .48),
  (.89, .11, .7),
  (.13, .28, .52),
  (.81, .29, .38),
  (.95, .42, .53),
  (.07, .48, .4),
  (.17, .63, .64),
  (.87, .57, .58),
  (.73, .7, .38),
  (.09, .83, .46),
  (.31, .9, .5),
  (.55, .86, .3),
  (.91, .88, .64),
  (.49, .19, .25),
  (.63, .94, .42),
];

class ZyraOnboardingGoldPainter extends CustomPainter {
  const ZyraOnboardingGoldPainter(
    this.design, {
    this.preview = false,
    this.motion = ZyraOnboardingGoldMotion.pageEntrance,
    this.motionValue = 1,
    this.reducedMotion = false,
  });
  final ZyraOnboardingGoldDesign design;
  final bool preview;
  final ZyraOnboardingGoldMotion motion;
  final double motionValue;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final points = _goldDustPoints.map(
      (point) =>
          (point.$1, .76 - .55 * point.$1 + .23 * (point.$2 - .5), point.$3),
    );
    const opacity = .28;
    const radiusScale = 1.0;

    final gold = ZyraColors.splashWordmark;
    // The old full-page flecks were sub-pixel on a phone and almost invisible
    // against purple, even though the toggle swatches looked different. Keep
    // the swatches compact, but give each full-page fleck a soft halo and a
    // readable core so choosing a pattern has a visible effect on-device.
    final previewStrength = preview ? 2.8 : 1.8;
    var index = 0;
    for (final (x, y, weight) in points) {
      var opacityFactor = 1.0;
      var verticalShift = 0.0;
      if (!preview && !reducedMotion) {
        switch (motion) {
          case ZyraOnboardingGoldMotion.pageEntrance:
            final staggered = (motionValue - index * .018).clamp(0.0, 1.0);
            final eased = Curves.easeOutCubic.transform(staggered);
            opacityFactor = eased;
            verticalShift = (1 - eased) * 10;
          case ZyraOnboardingGoldMotion.liveDrift:
            final wave = math.sin(motionValue * 2 * math.pi + index * .77);
            opacityFactor = .7 + .3 * ((wave + 1) / 2);
            verticalShift = wave * 7;
        }
      }
      final radius =
          (preview ? 1.2 : size.shortestSide * .018) * weight * radiusScale;
      final center = Offset(size.width * x, size.height * y + verticalShift);
      if (!preview) {
        final haloRadius = radius * 3.2;
        canvas.drawCircle(
          center,
          haloRadius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                gold.withValues(alpha: .16 * weight * opacityFactor),
                gold.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: center, radius: haloRadius)),
        );
      }
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = gold.withValues(
            alpha: (opacity * weight * previewStrength * opacityFactor).clamp(
              0.0,
              1.0,
            ),
          ),
      );
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant ZyraOnboardingGoldPainter oldDelegate) =>
      oldDelegate.design != design ||
      oldDelegate.preview != preview ||
      oldDelegate.motion != motion ||
      oldDelegate.motionValue != motionValue ||
      oldDelegate.reducedMotion != reducedMotion;
}
