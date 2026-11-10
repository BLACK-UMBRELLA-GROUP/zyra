import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

class ZyraInfoRow extends StatelessWidget {
  const ZyraInfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.copy,
    this.onTap,
    this.iconGap = 14,
    this.copySize = 12,
  });
  final IconData icon;
  final String title;
  final String? copy;
  final VoidCallback? onTap;
  final double iconGap;
  final double copySize;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: copy == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: ZyraColors.journeyGold),
            ),
          ),
          SizedBox(width: iconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.body(size: 14)),
                if (copy != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    copy!,
                    style: ZyraText.subtext(
                      size: copySize,
                    ).copyWith(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ZyraColors.ink(.28),
            ),
          ],
        ],
      ),
    );
    return MergeSemantics(
      child: onTap == null
          ? row
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: row,
            ),
    );
  }
}
