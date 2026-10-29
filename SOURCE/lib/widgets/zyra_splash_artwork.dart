// Founder-selected Quiet Horizon artwork, promoted 2026-09-27.
// OA-ZYRA-316 / DR-ZYRA-276: unchosen splash artwork retired.
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

enum ZyraSplashDirection {
  dawnHorizon('6 · Quiet Horizon · Main');

  const ZyraSplashDirection(this.label);
  final String label;
}

/// The Founder-selected production design; previews cannot change this.
const zyraPrimarySplashDirection = ZyraSplashDirection.dawnHorizon;

// Shared by the production splash and protected design previews. Founder
// shortened only the completed-frame pause twice on 2026-09-30; the
// arrival sequence remains 2400ms.
const int zyraSplashMotionMilliseconds = 2400;
const int zyraSplashFinishedHoldMilliseconds = 650;
const Duration zyraSplashTotalDuration = Duration(
  milliseconds:
      zyraSplashMotionMilliseconds + zyraSplashFinishedHoldMilliseconds,
);
const double zyraSplashMotionFraction =
    zyraSplashMotionMilliseconds /
    (zyraSplashMotionMilliseconds + zyraSplashFinishedHoldMilliseconds);

/// Protected replay of the selected Quiet Horizon artwork.
class ZyraSplashStudy extends StatefulWidget {
  const ZyraSplashStudy({super.key, required this.direction});
  final ZyraSplashDirection direction;

  @override
  State<ZyraSplashStudy> createState() => _ZyraSplashStudyState();
}

class _ZyraSplashStudyState extends State<ZyraSplashStudy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    animationBehavior: AnimationBehavior.preserve,
    vsync: this,
    duration: zyraSplashTotalDuration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => ZyraSplashArtworkFrame(
      direction: widget.direction,
      progress: MediaQuery.disableAnimationsOf(context)
          ? 1.0
          : (_controller.value / zyraSplashMotionFraction).clamp(0.0, 1.0),
    ),
  );
}

/// Shared code-native artwork. Production supplies its own lifecycle progress;
/// developer previews animate this exact frame without touching AuthGate.
class ZyraSplashArtworkFrame extends StatelessWidget {
  const ZyraSplashArtworkFrame({
    super.key,
    required this.direction,
    required this.progress,
    this.tagline = 'Connecting with trust',
  });

  final ZyraSplashDirection direction;
  final double progress;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final arrival = Curves.easeOutCubic.transform(
      (progress / .68).clamp(0.0, 1.0),
    );
    final taglineArrival = Curves.easeOut.transform(
      ((progress - .35) / .5).clamp(0.0, 1.0),
    );
    final design = MediaQuery.sizeOf(context).shortestSide.clamp(280.0, 480.0);
    final wordmarkSize = design * .19;
    // The small onboarding header is Syne at 18 with 4 points of tracking.
    // Scale the tracking with the letters so the splash is the same mark,
    // rather than a more tightly spaced version at a larger size.
    final wordmarkTracking =
        ZyraText.wordmark(size: 18).letterSpacing! * wordmarkSize / 18;
    final brand = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Opacity(
            opacity: arrival,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - arrival)),
              child: Text(
                'ZYRA',
                key: const ValueKey('splash_study_wordmark'),
                style: ZyraText.wordmark(
                  size: wordmarkSize,
                  color: ZyraColors.splashWordmark,
                ).copyWith(letterSpacing: wordmarkTracking),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: taglineArrival,
          child: Text(
            tagline,
            style: ZyraText.subtext(
              size: ZyraText.taglineSize(context),
              color: ZyraColors.splashTagline,
            ),
          ),
        ),
      ],
    );
    return DecoratedBox(
      key: ValueKey('splash_study_${direction.name}'),
      // The selected Quiet Horizon retains the brand palette.
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _HuluArtwork(direction, progress, design)),
          Align(
            alignment: const Alignment(0, -.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _HuluArtwork extends CustomPainter {
  const _HuluArtwork(this.direction, this.progress, this.design);
  final ZyraSplashDirection direction;
  final double progress;
  final double design;
  static const gold = ZyraColors.splashWordmark;
  static const plumLight = Color(0xFFB691C9);

  void _glow(
    Canvas canvas,
    Offset centre,
    double width,
    double height,
    Color color,
    double alpha,
  ) {
    final rect = Rect.fromCenter(center: centre, width: width, height: height);
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(1, height / width);
    canvas.drawCircle(
      Offset.zero,
      width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * .25),
            color.withValues(alpha: 0),
          ],
          stops: const [0, .48, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: width / 2)),
    );
    canvas.restore();
    // Keep rect construction explicit for proportional geometry debugging.
    assert(rect.width > 0 && rect.height > 0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress);
    final centre = Offset(size.width / 2, size.height * .47);
    final unit = design / 390;
    final stroke = Paint()
      ..color = gold.withValues(alpha: .48 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final horizon = centre + Offset(0, design * .24);
    _glow(canvas, horizon, design * 1.6, design * .32, gold, .18 * t);
    canvas.drawLine(
      horizon - Offset(design * .32 * t, 0),
      horizon + Offset(design * .32 * t, 0),
      stroke,
    );
    _glow(
      canvas,
      horizon + Offset(0, 44 * unit),
      design * 1.2,
      design * .55,
      plumLight,
      .16 * t,
    );
  }

  @override
  bool shouldRepaint(_HuluArtwork oldDelegate) =>
      oldDelegate.direction != direction ||
      oldDelegate.progress != progress ||
      oldDelegate.design != design;
}
