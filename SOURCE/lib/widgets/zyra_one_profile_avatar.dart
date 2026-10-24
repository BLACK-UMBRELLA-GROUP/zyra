import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_colors.dart';

/// The shared Profile avatar treatment. ZYRA One is recognised with a quiet
/// gold ring; Basic keeps the same footprint without a decorative ring.
class ZyraOneProfileAvatar extends StatelessWidget {
  const ZyraOneProfileAvatar({
    super.key,
    required this.isOne,
    required this.child,
    this.guardian = false,
  });

  final bool isOne;
  final Widget child;
  final bool guardian;

  @override
  Widget build(BuildContext context) => Semantics(
    label: isOne
        ? '${guardian ? ZyraMembershipCatalog.guardianOneTitle : ZyraMembershipCatalog.seekerOneTitle} profile'
        : 'Profile',
    image: true,
    child: Container(
      key: const ValueKey('profile-membership-avatar'),
      width: 68,
      height: 68,
      padding: EdgeInsets.all(isOne ? 3 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isOne
            ? Border.all(color: ZyraColors.journeyGold, width: 1.5)
            : null,
        boxShadow: isOne
            ? [
                BoxShadow(
                  color: ZyraColors.journeyGold.withValues(alpha: 0.16),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: ClipOval(child: child),
    ),
  );
}
