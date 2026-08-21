// ZYRA splash — Founder-approved "Trails Meet" connection.
//
// Two gold points begin near opposite ends, move toward the same centre,
// and each draw its own half of the connection behind it. The completed
// line and joined centre point stay still for the splash hold.
//
// This is intentionally separate from the loading loop. The splash is a
// single arrival gesture; loading uses Meet and Pass so it can repeat
// without visibly pulling an established connection backwards.

import 'package:flutter/material.dart';

class ZyraTrailsMeetRule extends StatelessWidget {
  static const Color gold = Color(0xFFE8C98A);

  final double width;
  final double progress;
  final double opacity;

  const ZyraTrailsMeetRule({
    super.key,
    required this.width,
    required this.progress,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Two lights connecting',
      child: RepaintBoundary(
        child: SizedBox(
          key: const ValueKey('splash_trails_meet_rule'),
          width: width,
          // Keep the same two-point layout footprint as the former comet
          // rule. The dots paint beyond this hairline without moving the
          // approved wordmark/tagline block vertically.
          height: 2,
          child: CustomPaint(
            painter: ZyraTrailsMeetPainter(
              progress: progress,
              opacity: opacity,
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class ZyraTrailsMeetFrame {
  final double start;
  final double end;
  final double centre;
  final double leftDot;
  final double rightDot;

  const ZyraTrailsMeetFrame({
    required this.start,
    required this.end,
    required this.centre,
    required this.leftDot,
    required this.rightDot,
  });

  factory ZyraTrailsMeetFrame.at({
    required double width,
    required double progress,
  }) {
    final p = progress.clamp(0.0, 1.0);
    final start = width * 0.08;
    final end = width - start;
    final centre = width / 2;
    return ZyraTrailsMeetFrame(
      start: start,
      end: end,
      centre: centre,
      leftDot: start + (centre - start) * p,
      rightDot: end + (centre - end) * p,
    );
  }
}

@visibleForTesting
class ZyraTrailsMeetPainter extends CustomPainter {
  final double progress;
  final double opacity;

  const ZyraTrailsMeetPainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    final alpha = opacity.clamp(0.0, 1.0);
    if (alpha <= 0 || size.width <= 0) return;

    final frame = ZyraTrailsMeetFrame.at(width: size.width, progress: p);
    final y = size.height / 2;
    final radius = (size.width * 0.0195).clamp(3.8, 5.0);

    final trail = Paint()
      ..color = ZyraTrailsMeetRule.gold.withValues(
        alpha: alpha * (0.46 + 0.42 * p),
      )
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(frame.start, y), Offset(frame.leftDot, y), trail);
    canvas.drawLine(Offset(frame.rightDot, y), Offset(frame.end, y), trail);

    final glow = Paint()
      ..color = ZyraTrailsMeetRule.gold.withValues(alpha: alpha * 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final dot = Paint()
      ..color = ZyraTrailsMeetRule.gold.withValues(alpha: alpha);

    for (final x in [frame.leftDot, frame.rightDot]) {
      canvas.drawCircle(Offset(x, y), radius * 1.55, glow);
      canvas.drawCircle(Offset(x, y), radius, dot);
    }
  }

  @override
  bool shouldRepaint(covariant ZyraTrailsMeetPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}
