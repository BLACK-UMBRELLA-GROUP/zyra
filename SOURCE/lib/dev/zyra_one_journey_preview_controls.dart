// Compact current-theme local choices; no preferences or member authority.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

class ZyraConceptPreviewChoice extends StatelessWidget {
  const ZyraConceptPreviewChoice({
    super.key,
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? ZyraColors.surfaceEmphasisFill : ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? ZyraColors.surfaceEmphasisBorder
                : ZyraColors.surfaceBorder,
            width: selected ? 1 : .6,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_outline
                        : Icons.circle_outlined,
                    size: 18,
                    color: selected
                        ? ZyraColors.journeyGold
                        : ZyraColors.ink(.4),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: ZyraText.body(size: 12.5)),
                        if (detail.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(detail, style: ZyraText.subtext(size: 10.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
