import 'package:flutter/material.dart';

import '../theme/zyra_interaction_style.dart';

/// Carries the local preview's choice through routes, sheets and dialogs.
/// Ordinary member controls use the saved device choice when no scope exists.
class ZyraTapFeedback extends InheritedTheme {
  const ZyraTapFeedback({
    super.key,
    required this.level,
    required this.canAct,
    required super.child,
  });

  final ZyraHapticLevel Function() level;
  final bool Function() canAct;

  static VoidCallback? onTap(
    BuildContext context,
    VoidCallback? action, {
    ZyraHapticLevel Function()? level,
    bool Function()? canAct,
  }) {
    if (action == null) return null;
    final scope = context.dependOnInheritedWidgetOfExactType<ZyraTapFeedback>();
    return () {
      if (!context.mounted ||
          (canAct != null && !canAct()) ||
          (scope != null && !scope.canAct())) {
        return;
      }
      ZyraInteractionStyle.performSelectionTap(
        action,
        level: level?.call() ?? scope?.level(),
      );
    };
  }

  static ValueChanged<T>? onChanged<T>(
    BuildContext context,
    ValueChanged<T>? action, {
    ZyraHapticLevel Function()? level,
    bool Function()? canAct,
  }) {
    if (action == null) return null;
    final scope = context.dependOnInheritedWidgetOfExactType<ZyraTapFeedback>();
    return (value) {
      if (!context.mounted ||
          (canAct != null && !canAct()) ||
          (scope != null && !scope.canAct())) {
        return;
      }
      ZyraInteractionStyle.performSelectionTap(
        () => action(value),
        level: level?.call() ?? scope?.level(),
      );
    };
  }

  @override
  Widget wrap(BuildContext context, Widget child) =>
      ZyraTapFeedback(level: level, canAct: canAct, child: child);

  @override
  bool updateShouldNotify(ZyraTapFeedback oldWidget) =>
      level != oldWidget.level || canAct != oldWidget.canAct;
}
