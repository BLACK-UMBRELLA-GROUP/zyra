import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_motion.dart';
import '../theme/zyra_preview_spacing.dart';

/// The gesture and explicit page controls share the same track.
class ZyraSwipeController {
  _ZyraSwipeTrackState? _track;

  bool get isMoving => _track?._isMoving ?? false;

  void animateTo(int index) => _track?._animateTo(index);

  void cancel() => _track?._cancel();
}

class ZyraSwipeTrack extends StatefulWidget {
  const ZyraSwipeTrack({
    super.key,
    this.controller,
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
    required this.onSettled,
    this.canAct,
    this.canMoveTo,
    this.canStartAt,
    this.onDragStart,
    this.onDragSettled,
    this.onBlockedPrevious,
    this.motionIdentity,
    this.dragEnabled = true,
    this.viewportInset = ZyraPreviewSpacing.pageMargin,
  });

  final ZyraSwipeController? controller;
  final int index, itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onSettled;
  final bool Function()? canAct;
  final bool Function(int)? canMoveTo;
  final bool Function(Offset)? canStartAt;
  final VoidCallback? onDragStart, onDragSettled;
  final VoidCallback? onBlockedPrevious;
  final Object? motionIdentity;
  final bool dragEnabled;
  // The parent lays out the card inside this margin. Only paint may enter it.
  final double viewportInset;

  @override
  State<ZyraSwipeTrack> createState() => _ZyraSwipeTrackState();
}

/// Lets a larger page drive the track while only the cards move.
class ZyraSwipeGesture extends StatelessWidget {
  const ZyraSwipeGesture({
    super.key,
    required this.controller,
    required this.child,
    this.canStartAt,
  });

  final ZyraSwipeController controller;
  final Widget child;
  final bool Function(Offset)? canStartAt;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    gestures: {
      _SidewaysDragRecognizer:
          GestureRecognizerFactoryWithHandlers<_SidewaysDragRecognizer>(
            _SidewaysDragRecognizer.new,
            (drag) {
              drag.dragStartBehavior = DragStartBehavior.down;
              drag.onlyAcceptDragOnThreshold = true;
              // Apply the LOCK's travel and speed thresholds in the track.
              // The recognizer must deliver slower releases and short flicks.
              drag.minFlingDistance = 0;
              drag.minFlingVelocity = 0;
              drag.canStartAt = (position) =>
                  controller._track?._allowed() == true &&
                  (canStartAt?.call(position) ?? true);
              drag.onDown = (_) => controller._track?._admitDrag();
              drag.onStart = (_) => controller._track?._startDrag();
              drag.onUpdate = (details) =>
                  controller._track?._updateDrag(details.delta.dx);
              drag.onCancel = () =>
                  controller._track?._endDrag(0, cancel: true);
              drag.onEnd = (details) =>
                  controller._track?._endDrag(details.primaryVelocity ?? 0);
            },
          ),
    },
    child: child,
  );
}

class _SidewaysDragRecognizer extends HorizontalDragGestureRecognizer {
  Offset _travel = Offset.zero;
  bool Function(Offset)? canStartAt;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      (canStartAt?.call(event.localPosition) ?? true) &&
      super.isPointerAllowed(event);

  @override
  bool isPointerPanZoomAllowed(PointerPanZoomStartEvent event) =>
      (canStartAt?.call(event.localPosition) ?? true) &&
      super.isPointerPanZoomAllowed(event);

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) _travel += event.delta;
    if (event is PointerPanZoomUpdateEvent) _travel += event.panDelta;
    super.handleEvent(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind kind,
    double? deviceTouchSlop,
  ) =>
      _travel.dx.abs() >= ZyraMotion.dragSlop &&
      _travel.dx.abs() > _travel.dy.abs();

  @override
  void didStopTrackingLastPointer(int pointer) {
    super.didStopTrackingLastPointer(pointer);
    _travel = Offset.zero;
  }
}

class _ZyraSwipeTrackState extends State<ZyraSwipeTrack>
    with SingleTickerProviderStateMixin {
  static const _gap = 24.0;

  final _internalController = ZyraSwipeController();
  late final _offset = AnimationController.unbounded(vsync: this);
  bool Function()? _admission, _dragLease;
  double _distance = 0, _width = 0;
  bool _settling = false;

  ZyraSwipeController get _controller =>
      widget.controller ?? _internalController;
  bool get _isMoving => _settling || _dragLease != null;
  double get _stride => _width + _gap;
  bool _allowed() => widget.canAct?.call() ?? true;
  bool _canMoveTo(int index) =>
      index >= 0 &&
      index < widget.itemCount &&
      (widget.canMoveTo?.call(index) ?? true);

  @override
  void initState() {
    super.initState();
    _controller._track = this;
  }

  @override
  void didUpdateWidget(ZyraSwipeTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller ?? _internalController);
      _controller._track = this;
      _cancel();
    }
    if (oldWidget.index != widget.index ||
        oldWidget.itemCount != widget.itemCount ||
        oldWidget.motionIdentity != widget.motionIdentity) {
      _cancel();
    }
  }

  @override
  void dispose() {
    _detach(_controller);
    _offset.dispose();
    super.dispose();
  }

  void _detach(ZyraSwipeController controller) {
    if (identical(controller._track, this)) controller._track = null;
  }

  void _cancel() {
    _admission = null;
    _dragLease = null;
    _settling = false;
    _offset.value = 0;
  }

  void _admitDrag() {
    if (!_isMoving && _allowed()) _admission = widget.canAct ?? () => true;
  }

  void _startDrag() {
    final admission = _admission;
    _admission = null;
    if (_settling || admission?.call() != true || !_allowed()) return;
    _dragLease = admission;
    _distance = 0;
    widget.onDragStart?.call();
  }

  void _updateDrag(double dx) {
    if (_dragLease?.call() != true || !_allowed()) return;
    _distance += dx;
    if (ZyraMotion.reduceMotion(context)) return;
    final neighbour = widget.index + (_distance < 0 ? 1 : -1);
    final displacement = _canMoveTo(neighbour)
        ? _distance
        : _distance * ZyraMotion.endResistance;
    _offset.value = displacement.clamp(-_stride, _stride);
  }

  void _endDrag(double velocity, {bool cancel = false}) {
    _admission = null;
    final lease = _dragLease;
    _dragLease = null;
    if (lease == null) return;
    final direction = _distance == 0 ? velocity : _distance;
    final previous = direction > 0;
    final next = widget.index + (previous ? -1 : 1);
    final current = !cancel && lease() && _allowed();
    final canMove = _canMoveTo(next);
    final quickFlick =
        _distance.abs() >= ZyraMotion.flickDistance &&
        velocity.abs() / 1000 > ZyraMotion.flickSpeed &&
        velocity.sign == direction.sign;
    final passedThreshold = _distance.abs() > _width * ZyraMotion.pageThreshold;
    final atLimit =
        _offset.value.abs() >= _stride && _offset.value.sign == velocity.sign;
    final paintedVelocity = atLimit
        ? 0.0
        : velocity * (canMove ? 1 : ZyraMotion.endResistance);
    if (current && canMove && (passedThreshold || quickFlick)) {
      _settle(
        next,
        lease,
        releaseSpeed: velocity,
        velocity: paintedVelocity,
        fromDrag: true,
      );
      return;
    }
    final onBlockedPrevious = widget.onBlockedPrevious;
    _settle(
      widget.index,
      lease,
      releaseSpeed: velocity,
      velocity: paintedVelocity,
      after: current && previous && _distance >= 18 && !canMove
          ? onBlockedPrevious
          : null,
    );
  }

  void _animateTo(int index) {
    if (_isMoving ||
        !_allowed() ||
        !_canMoveTo(index) ||
        index == widget.index) {
      return;
    }
    _settle(index, widget.canAct ?? () => true);
  }

  Future<void> _settle(
    int next,
    bool Function() lease, {
    VoidCallback? after,
    bool fromDrag = false,
    double? releaseSpeed,
    double velocity = 0,
  }) async {
    _settling = true;
    final initialIndex = widget.index;
    final destination = (initialIndex - next) * _stride;
    try {
      final start = _offset.value;
      if (!ZyraMotion.reduceMotion(context) && start != destination) {
        final distance = destination - start;
        final duration = releaseSpeed == null
            ? ZyraMotion.duration
            : ZyraMotion.settleDuration(distance.abs(), releaseSpeed);
        final curve = releaseSpeed == null
            ? ZyraMotion.curve
            : _ReleaseCurve(
                velocity * duration.inMicroseconds / 1000000 / distance,
              );
        await _offset
            .animateTo(destination, duration: duration, curve: curve)
            .orCancel;
      }
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    _settling = false;
    _offset.value = 0;
    if (!lease() || !_allowed()) return;
    if (next != initialIndex && _canMoveTo(next)) {
      if (fromDrag) widget.onDragSettled?.call();
      widget.onSettled(next);
    }
    after?.call();
  }

  @override
  Widget build(BuildContext context) {
    final track = LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        if (widget.itemCount == 0) return const SizedBox.shrink();
        final current = widget.index;
        final pages = <int, Widget>{};
        final clipper = _SwipeViewportClip(
          inset: widget.viewportInset,
          screenHeight: MediaQuery.sizeOf(context).height,
        );
        return AnimatedBuilder(
          animation: _offset,
          builder: (context, _) {
            final offset = _offset.value;
            final page = current - offset / _stride;
            final start = math.max(0, page.floor());
            final end = math.min(widget.itemCount - 1, page.ceil());
            Widget card(int index) {
              final active = index == current;
              return Transform.translate(
                offset: Offset((index - current) * _stride + offset, 0),
                child: IgnorePointer(
                  ignoring: !active || _isMoving,
                  child: ExcludeFocus(
                    excluding: !active,
                    child: ExcludeSemantics(
                      excluding: !active,
                      child: pages.putIfAbsent(
                        index,
                        () => widget.itemBuilder(context, index),
                      ),
                    ),
                  ),
                ),
              );
            }

            return ClipRect(
              clipBehavior: offset == 0 ? Clip.none : Clip.hardEdge,
              clipper: clipper,
              child: Stack(
                clipBehavior: Clip.none,
                fit: constraints.hasBoundedHeight
                    ? StackFit.expand
                    : StackFit.passthrough,
                children: [
                  for (final index in {
                    current,
                    for (var i = start; i <= end; i++) i,
                  })
                    if (index == current)
                      KeyedSubtree(key: ValueKey(index), child: card(index))
                    else if (_canMoveTo(index))
                      Positioned(
                        key: ValueKey(index),
                        top: 0,
                        left: 0,
                        width: _width,
                        bottom: constraints.hasBoundedHeight ? 0 : null,
                        child: card(index),
                      ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!widget.dragEnabled) return track;
    return ZyraSwipeGesture(
      controller: _controller,
      canStartAt: widget.canStartAt,
      child: track,
    );
  }
}

// Match the painted release velocity at lift, then join the shared easing
// curve with continuous position and velocity. The handoff spans about one
// frame at the minimum settle time, and also lets a spring-back turn around.
class _ReleaseCurve extends Curve {
  const _ReleaseCurve(this.initialSlope);

  final double initialSlope;
  static const _handoff = 1 / 16;

  @override
  double transformInternal(double t) {
    if (t >= _handoff) return ZyraMotion.curve.transform(t);
    final end = ZyraMotion.curve.transform(_handoff);
    const sample = .001;
    final slope =
        (ZyraMotion.curve.transform(_handoff + sample) -
            ZyraMotion.curve.transform(_handoff - sample)) /
        (2 * sample);
    final x = t / _handoff;
    final remaining = 1 - x;
    final progress =
        x * remaining * remaining * _handoff * initialSlope +
        x * x * (3 - 2 * x) * end -
        x * x * remaining * _handoff * slope;
    return math.min(progress, end);
  }
}

class _SwipeViewportClip extends CustomClipper<Rect> {
  const _SwipeViewportClip({required this.inset, required this.screenHeight});

  final double inset, screenHeight;

  // Only the side edges can cross the visible screen. Vertical paint remains
  // visible to the enclosing page, including shadows outside the card.
  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -inset,
    -screenHeight,
    size.width + inset,
    size.height + screenHeight,
  );

  @override
  bool shouldReclip(_SwipeViewportClip oldClipper) =>
      inset != oldClipper.inset || screenHeight != oldClipper.screenHeight;
}
