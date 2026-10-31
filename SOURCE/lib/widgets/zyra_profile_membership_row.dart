import 'zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// The one membership-status treatment used directly on both Profile pages.
///
/// It deliberately looks like profile information rather than a promotional
/// badge. Guardian can still open membership from the row without adding a
/// different visual hierarchy from Seeker.
class ZyraProfileMembershipRow extends StatelessWidget {
  const ZyraProfileMembershipRow({
    super.key,
    required this.value,
    required this.isOne,
    this.onTap,
  });

  final String value;
  final bool isOne;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        button: onTap != null,
        label:
            'Membership, $value, ${isOne ? 'manage membership' : 'view membership options'}',
        child: InkWell(
          key: ValueKey(isOne ? 'membership-manage' : 'membership-upgrade'),
          onTap: ZyraTapFeedback.onTap(context, onTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Icon(
                  isOne
                      ? Icons.workspace_premium_outlined
                      : Icons.person_outline_rounded,
                  size: 20,
                  color: isOne
                      ? ZyraColors.journeyGold
                      : ZyraColors.foregroundSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ZyraText.body(
                          size: 14,
                          color: ZyraColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOne ? 'Manage membership' : 'View your options',
                        style: ZyraText.subtext(
                          size: 11.5,
                          color: isOne
                              ? ZyraColors.goldText
                              : ZyraColors.foregroundSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: ZyraColors.ink(0.28),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
