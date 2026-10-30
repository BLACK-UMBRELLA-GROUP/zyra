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
    this.compactWhenIdle = false,
    this.compactV2 = false,
    this.collapseRevision = 0,
    this.interactionEnabled = true,
  }) : assert(
         contentEdgeInset == null ||
             (contentEdgeInset >= 0 && contentEdgeInset < double.infinity),
       );

  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool commitOnRelease;

  /// The locked Founder root treatment; action and member bars retain their
  /// existing behavior unless their owner explicitly opts in.
  final bool compactWhenIdle;
  final bool compactV2;
  final int collapseRevision;
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
    compactWhenIdle: compactWhenIdle,
    compactV2: compactV2,
    collapseRevision: collapseRevision,
    interactionEnabled: interactionEnabled,
  );
}
