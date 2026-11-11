import 'package:flutter/material.dart';

import '../theme/zyra_interaction_style.dart';
import 'floating_nav_bar.dart';

/// The shell-owned floating bar shares the same destinations and callbacks
/// with Browse's safety actions.
class ZyraShellNavigation extends StatelessWidget {
  const ZyraShellNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.commitOnRelease = false,
    this.contentEdgeInset,
    this.hapticLevel,
    this.lockedTabBar = false,
    this.interactionEnabled = true,
  }) : assert(
         contentEdgeInset == null ||
             (contentEdgeInset >= 0 && contentEdgeInset < double.infinity),
       );

  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool commitOnRelease;

  /// The fixed LOCK 6 V4 treatment for planned tabs.
  final bool lockedTabBar;
  final bool interactionEnabled;

  /// Null preserves the floating bar's existing edge inset.
  final double? contentEdgeInset;

  /// Explicit local feedback choice. Null preserves member preferences.
  final ZyraHapticLevel? hapticLevel;

  @override
  Widget build(BuildContext context) => FloatingNavBar(
    items: items,
    currentIndex: currentIndex,
    onTap: onTap,
    commitOnRelease: commitOnRelease,
    contentEdgeInset: contentEdgeInset,
    hapticLevel: hapticLevel,
    lockedTabBar: lockedTabBar,
    interactionEnabled: interactionEnabled,
  );
}
