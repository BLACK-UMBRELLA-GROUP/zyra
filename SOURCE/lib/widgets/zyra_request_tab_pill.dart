import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_floating_surface.dart';
import 'zyra_tap_feedback.dart';

/// The pill used by Journey requests and the two ZYRA Code tabs.
class ZyraRequestTabPill extends StatelessWidget {
  const ZyraRequestTabPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tapKey,
    this.selectedFill,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Key? tapKey;
  final Color? selectedFill;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final helperInk = Color.alphaBlend(
      ZyraColors.ink(.80),
      ZyraColors.isLightPalette ? Colors.white : ZyraColors.luxuryDarkPurple,
    );
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: label,
      onTap: ZyraTapFeedback.onTap(context, onTap),
      excludeSemantics: true,
      child: ZyraFloatingSurface(
        radius: 999,
        child: Material(
          color: selected
              ? selectedFill ?? ZyraColors.accentOnCanvas.withValues(alpha: .12)
              : ZyraColors.surfaceFill,
          borderRadius: radius,
          child: InkWell(
            key: tapKey,
            borderRadius: radius,
            onTap: ZyraTapFeedback.onTap(context, onTap),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected
                      ? ZyraColors.accentOnCanvas.withValues(alpha: .70)
                      : ZyraColors.surfaceBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: ZyraText.button(
                  size: 12,
                  color: selected ? ZyraColors.foreground : helperInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
