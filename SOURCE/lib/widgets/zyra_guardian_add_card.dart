import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_floating_surface.dart';

/// LOCK 19 k08 Add a Guardian card. The existing Basic capacity card uses
/// the same surface and replaces only its icon and copy.
class ZyraGuardianAddCard extends StatelessWidget {
  const ZyraGuardianAddCard({super.key, this.needsUpgrade = false});

  final bool needsUpgrade;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 22,
    child: CustomPaint(
      foregroundPainter: ZyraGuardianDashedBorder(
        22,
        ZyraColors.journeyGold.withValues(alpha: .6),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3EDE3),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 360 &&
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 18
                : 34,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ZyraColors.ink(.08),
                ),
                child: Icon(
                  needsUpgrade ? Icons.lock_outline : Icons.add,
                  color: ZyraColors.journeyGold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                needsUpgrade ? 'Add more Guardians' : 'Add a Guardian',
                textAlign: TextAlign.center,
                style: ZyraText.heading(size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                needsUpgrade
                    ? 'Seeker Basic includes 1 Guardian. Seeker One lets you add up to 10.'
                    : 'Share your ZYRA Code, or scan theirs. You choose who joins.',
                textAlign: TextAlign.center,
                style: ZyraText.body(size: 13, color: ZyraColors.ink(.55)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ZyraGuardianDashedBorder extends CustomPainter {
  ZyraGuardianDashedBorder(this.radius, this.color);
  final double radius;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 5) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 2.5, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ZyraGuardianDashedBorder oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
