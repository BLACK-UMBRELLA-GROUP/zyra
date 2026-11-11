import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/zyra_guardian_capacity.dart';
import '../data/zyra_seeker_plan_limits.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_floating_surface.dart';

/// LOCK 19 Add a Guardian card, including the V7 Seeker Basic places.
class ZyraGuardianAddCard extends StatelessWidget {
  const ZyraGuardianAddCard({
    super.key,
    this.basicCapacity,
    this.onUpgrade,
    this.allowContentScroll = false,
  });

  final ZyraGuardianCapacity? basicCapacity;
  final VoidCallback? onUpgrade;
  final bool allowContentScroll;

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
        child: _content(context),
      ),
    ),
  );
  Widget _content(BuildContext context) {
    final capacity = basicCapacity;
    final basicUsed = capacity?.basicPlaceUsed;
    final content = Padding(
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
            child: Icon(Icons.add, color: ZyraColors.journeyGold, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            'Add a Guardian',
            textAlign: TextAlign.center,
            style: ZyraText.heading(size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            capacity == null
                ? 'Share your ZYRA Code, or scan theirs. You choose who joins.'
                : basicUsed == true
                ? ZyraGuardianCapacity.basicLimitMessage
                : '${capacity.linkedGuardianCount} of ${ZyraSeekerPlanLimits.maxLinkedGuardians} Guardians. '
                      'One Guardian can be on Guardian Basic; the rest need Guardian One.',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 13, color: ZyraColors.ink(.55)),
          ),
          if (capacity != null && basicUsed != null) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _place(
                    basicUsed ? 'Used' : 'Free',
                    'Guardian Basic place',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _place(
                    '${capacity.guardianOnePlaces}',
                    'Guardian One places',
                  ),
                ),
              ],
            ),
          ],
          if (onUpgrade != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onUpgrade,
              child: Text(
                'Seeker One: any 10 Guardians ›',
                textAlign: TextAlign.center,
                style: ZyraText.body(size: 13, color: ZyraColors.goldText),
              ),
            ),
          ],
        ],
      ),
    );
    if (!allowContentScroll && capacity == null) return content;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        primary: false,
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: content,
        ),
      ),
    );
  }

  Widget _place(String value, String label) => DecoratedBox(
    decoration: BoxDecoration(
      color: ZyraColors.ivoryTop,
      border: Border.all(color: ZyraColors.surfaceBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        children: [
          Text(value, style: ZyraText.heading(size: 17)),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 11, color: ZyraColors.ink(.66)),
          ),
        ],
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
