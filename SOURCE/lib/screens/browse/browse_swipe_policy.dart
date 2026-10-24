import 'dart:ui';

/// The three intentional decisions available from the Browse photo deck.
enum ZyraBrowseSwipeDecision { pass, save, consider }

/// The physical edge that must carry the live and commit-time cue.
enum ZyraBrowseSwipeCueEdge { left, top, right }

/// The intent acquired during one continuous press-and-drag.
///
/// Once Browse recognises a horizontal or vertical gesture it keeps that axis
/// until the finger lifts. This prevents a small downward drift while a person
/// returns a horizontal swipe towards centre from flashing the Save cue.
enum ZyraBrowseSwipeAxis { horizontal, vertical }

/// One authoritative translation from finger movement to a Browse decision.
///
/// Flutter reports a left-to-right drag with a positive [Offset.dx] and a
/// right-to-left drag with a negative one. Keeping that coordinate rule here
/// prevents the live preview, released action, fling and edge cue from drifting
/// into different meanings as the developer lab treatments evolve.
abstract final class ZyraBrowseSwipePolicy {
  static const double previewActivation = 20;
  static const double commitThreshold = 120;

  static ZyraBrowseSwipeAxis? previewAxis(Offset offset) {
    final horizontalDistance = offset.dx.abs();
    final downwardDistance = offset.dy;
    if (horizontalDistance <= previewActivation &&
        downwardDistance <= previewActivation) {
      return null;
    }
    return horizontalDistance > downwardDistance.abs()
        ? ZyraBrowseSwipeAxis.horizontal
        : ZyraBrowseSwipeAxis.vertical;
  }

  static ZyraBrowseSwipeDecision? previewDecision(
    Offset offset, {
    ZyraBrowseSwipeAxis? lockedAxis,
  }) => _decisionFor(
    offset,
    threshold: previewActivation,
    lockedAxis: lockedAxis,
  );

  static ZyraBrowseSwipeDecision? committedDecision(
    Offset offset, {
    ZyraBrowseSwipeAxis? lockedAxis,
  }) =>
      _decisionFor(offset, threshold: commitThreshold, lockedAxis: lockedAxis);

  static ZyraBrowseSwipeDecision? _decisionFor(
    Offset offset, {
    required double threshold,
    ZyraBrowseSwipeAxis? lockedAxis,
  }) {
    final axis =
        lockedAxis ??
        (offset.dx.abs() > offset.dy.abs()
            ? ZyraBrowseSwipeAxis.horizontal
            : ZyraBrowseSwipeAxis.vertical);
    if (axis == ZyraBrowseSwipeAxis.horizontal) {
      // Finger/card moves left: negative/Consider.
      if (offset.dx < -threshold) return ZyraBrowseSwipeDecision.consider;
      // Finger/card moves right: positive/Pass.
      if (offset.dx > threshold) return ZyraBrowseSwipeDecision.pass;
      return null;
    }
    if (offset.dy > threshold) return ZyraBrowseSwipeDecision.save;
    return null;
  }

  static Offset flingTarget(ZyraBrowseSwipeDecision decision) =>
      switch (decision) {
        ZyraBrowseSwipeDecision.pass => const Offset(600, 0),
        ZyraBrowseSwipeDecision.save => const Offset(0, 900),
        ZyraBrowseSwipeDecision.consider => const Offset(-600, 0),
      };

  static ZyraBrowseSwipeCueEdge cueEdge(ZyraBrowseSwipeDecision decision) =>
      switch (decision) {
        // The growing line counterbalances the moving card: Pass travels
        // right while its red line rises on the LEFT; Consider travels left
        // while its green line rises on the RIGHT.
        ZyraBrowseSwipeDecision.pass => ZyraBrowseSwipeCueEdge.left,
        // A downward drag reveals the Save cue from behind the card's top edge.
        ZyraBrowseSwipeDecision.save => ZyraBrowseSwipeCueEdge.top,
        ZyraBrowseSwipeDecision.consider => ZyraBrowseSwipeCueEdge.right,
      };
}
