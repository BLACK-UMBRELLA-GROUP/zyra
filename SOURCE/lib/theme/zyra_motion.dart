import 'package:flutter/material.dart';

/// LOCK 26 motion shared by swipe tracks and scrolling.
abstract final class ZyraMotion {
  static const duration = Duration(milliseconds: 420);
  static const curve = Cubic(0.22, 1, 0.36, 1);
  static const minimumSettleFraction = 0.60;
  static const pageThreshold = 0.22;
  static const flickDistance = 12.0;
  static const flickSpeed = 0.45; // Logical pixels per millisecond.
  static const dragSlop = 8.0;
  static const endResistance = 0.30;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  static Duration scrollDuration(BuildContext context) =>
      reduceMotion(context) ? Duration.zero : duration;

  static Duration settleDuration(double distance, double pixelsPerSecond) {
    final base = duration.inMilliseconds;
    final speed = pixelsPerSecond.abs() / 1000;
    if (speed == 0) return duration;
    return Duration(
      milliseconds: (distance / speed * 1.6)
          .clamp(base * minimumSettleFraction, base)
          .round(),
    );
  }

  static const scrollPhysics = BouncingScrollPhysics();

  /// Pull-to-refresh must accept a drag even when the list fits the viewport.
  static const refreshScrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  /// Fixed cards only admit internal scroll when the content overflows.
  /// Their separate layout locks call for no bounce even at larger text sizes.
  static const fixedCardScrollPhysics = _FixedCardScrollPhysics();
}

class _FixedCardScrollPhysics extends ClampingScrollPhysics {
  const _FixedCardScrollPhysics({super.parent});

  @override
  _FixedCardScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _FixedCardScrollPhysics(parent: buildParent(ancestor));

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) =>
      position.minScrollExtent < position.maxScrollExtent;
}
