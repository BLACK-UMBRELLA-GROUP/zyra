import 'package:flutter/material.dart';

import '../models/zyra_compatibility_area.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// One display-only row. A null band represents a locked area.
class ZyraCompatibilityAreaRow extends StatelessWidget {
  const ZyraCompatibilityAreaRow({
    super.key,
    required this.area,
    required this.band,
    this.availableWidth,
  });

  final ZyraCompatibilityArea area;
  final ZyraCompatibilityBand? band;
  final double? availableWidth;

  @override
  Widget build(BuildContext context) {
    // The reader already knows its width during intrinsic height measurement.
    final width = availableWidth;
    return width == null
        ? LayoutBuilder(
            builder: (context, constraints) => _row(constraints.maxWidth),
          )
        : _row(width);
  }

  Widget _row(double width) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      decoration: BoxDecoration(
        border: area.index == 0
            ? null
            : Border(top: BorderSide(color: ZyraColors.divider)),
      ),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                area.label,
                style: ZyraText.body(
                  size: 13.5,
                  color: ZyraColors.espresso,
                ).copyWith(letterSpacing: 0),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width * .48),
            child: _status(),
          ),
        ],
      ),
    );
  }

  Widget _status() {
    final value = band;
    if (value == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 13,
            color: ZyraColors.journeyGold,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text('Locked', style: _statusStyle(ZyraColors.mutedText)),
          ),
        ],
      );
    }
    if (value == ZyraCompatibilityBand.notEnoughAnswers) {
      return Text(
        value.label,
        textAlign: TextAlign.end,
        style: _statusStyle(
          ZyraColors.mutedText,
        ).copyWith(fontStyle: FontStyle.italic),
      );
    }
    final strong = value == ZyraCompatibilityBand.strong;
    final good = value == ZyraCompatibilityBand.good;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: strong ? ZyraColors.goldTextFill : ZyraColors.ivoryTop,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: strong
              ? ZyraColors.goldTextFill
              : good
              ? const Color(0xFFA9792E).withValues(alpha: .6)
              : ZyraColors.divider,
        ),
      ),
      child: Text(
        value.label,
        textAlign: TextAlign.end,
        style: _statusStyle(good ? ZyraColors.goldText : ZyraColors.espresso),
      ),
    );
  }

  TextStyle _statusStyle(Color color) =>
      ZyraText.body(size: 12, color: color).copyWith(letterSpacing: 0);
}
