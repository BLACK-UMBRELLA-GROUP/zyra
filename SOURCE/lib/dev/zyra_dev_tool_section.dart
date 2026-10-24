import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';

/// One category, one surface. The enclosing developer panel owns scrolling;
/// sections never mix independent controls into a single catch-all menu.
class ZyraDevToolSection extends StatelessWidget {
  const ZyraDevToolSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ZyraColors.surfaceBorder),
    ),
    child: Padding(padding: const EdgeInsets.all(14), child: child),
  );
}
