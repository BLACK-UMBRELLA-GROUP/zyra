// Caller-owned return navigation. This scope has no route, account, provider,
// persistence or Journey-stage authority; it only invokes the bound onBack.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../theme/zyra_colors.dart';

/// Caller-owned presentation checkpoint. A revision invalidates captured
/// returns without owning a route, account or permission to navigate.

class ZyraBackNavigationPreview extends InheritedWidget {
  const ZyraBackNavigationPreview({
    super.key,
    required this.revision,
    required super.child,
  });

  final int revision;

  static int revisionOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ZyraBackNavigationPreview>()
          ?.revision ??
      0;

  @override
  bool updateShouldNotify(ZyraBackNavigationPreview oldWidget) =>
      oldWidget.revision != revision;
}

/// The caller-owned return is available by left-edge swipe, assistive action
/// or keyboard dismissal without reserving visible navigation chrome.
/// Existing shared and manual hosts supply their own eligibility. Exactly
/// one ancestor owns the return affordance and its interactive edge.
class ZyraPullDownCloseCue extends StatefulWidget {
  const ZyraPullDownCloseCue({
    super.key,
    required this.child,
    required this.enabled,
    this.paintBackground = true,
    this.inlineBackHeader = false,
    this.returnForegroundColor,
    this.onBack,
    this.routeIdentity,
  });

  final Widget child;
  final bool enabled;
  // A caller with a full-viewport background can retain that shared painting
  // (including scoped palette/gold) behind the moving surface.
  final bool paintBackground;

  /// Retains the caller's existing nested return binding. There is no visible
  /// heading-slot button; return eligibility and edge ownership stay here.
  final bool inlineBackHeader;
  // Retained constructor compatibility for callers that previously styled the
  // removed visual return. It has no effect on the swipe or assistive action.
  final Color? returnForegroundColor;
  final VoidCallback? onBack;
  final Object? routeIdentity;

  @override
  State<ZyraPullDownCloseCue> createState() => _ZyraPullDownCloseCueState();
}

class _ZyraPullDownCloseCueState extends State<ZyraPullDownCloseCue>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _revision = 0;
  int _epoch = 0;
  bool _taken = false;
  ModalRoute<dynamic>? _route;
  bool _routeCurrent = true;
  bool _ancestorActive = false;
  VoidCallback? _inheritedBack;
  VoidCallback? _inheritedBridge;
  VoidCallback? _accessibleBack;
  late final HorizontalDragGestureRecognizer _backSwipe;
  final Set<int> _swipePointers = <int>{};
  int _swipeSerial = 0;
  int? _swipePointer;
  int? _swipeEpoch;
  VoidCallback? _swipeBack;
  Offset _swipeOrigin = Offset.zero;
  Offset _swipeTravel = Offset.zero;
  double _swipeWidth = 0;
  bool _swipeAccepted = false;
  bool _swipeReleased = false;
  bool? _swipeRightward;
  VelocityTracker? _swipeVelocity;
  double _swipeReleaseVelocity = 0;
  Size? _mediaSize;
  EdgeInsets? _mediaInsets;
  EdgeInsets? _mediaPadding;
  bool _swipeForeground = true;
  bool _swipeReducedMotion = false;
  bool _swipeSettling = false;
  bool _completedSwipeSlide = false;
  late final AnimationController _swipeMotion;
  static const _swipeCloseDuration = Duration(milliseconds: 240);
  static const _swipeRestoreDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _swipeMotion = AnimationController.unbounded(vsync: this);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _swipeForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _backSwipe = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _swipeStart
      ..onEnd = _swipeEnd
      ..onCancel = _cancelSwipe;
  }

  void _resetSwipe({bool keepPosition = false}) {
    _swipeSerial++;
    _swipeMotion.stop(canceled: true);
    if (!keepPosition) {
      _swipeMotion.value = 0;
      _completedSwipeSlide = false;
    }
    _swipeSettling = false;
    _swipePointer = null;
    _swipeEpoch = null;
    _swipeBack = null;
    _swipeOrigin = Offset.zero;
    _swipeTravel = Offset.zero;
    _swipeWidth = 0;
    _swipeAccepted = false;
    _swipeReleased = false;
    _swipeRightward = null;
    _swipeVelocity = null;
    _swipeReleaseVelocity = 0;
    // Keep actual down IDs until their up/cancel. A mode/owner change cannot
    // turn an old finger into a fresh gesture, or hide a second contact.
  }

  void _invalidate({bool preserveCompletedSlide = false}) {
    _epoch++;
    _inheritedBridge = null;
    _accessibleBack = null;
    if (!preserveCompletedSlide) _taken = false;
    _resetSwipe(keepPosition: preserveCompletedSlide);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final reducedMotion = media.disableAnimations || media.accessibleNavigation;
    if (_mediaSize != media.size ||
        _mediaInsets != media.viewInsets ||
        _mediaPadding != media.padding ||
        _swipeReducedMotion != reducedMotion) {
      _mediaSize = media.size;
      _mediaInsets = media.viewInsets;
      _mediaPadding = media.padding;
      _swipeReducedMotion = reducedMotion;
      _resetSwipe();
    }
    _backSwipe.gestureSettings = media.gestureSettings;
    final revision = ZyraBackNavigationPreview.revisionOf(context);
    final route = ModalRoute.of(context);
    final current = route?.isCurrent ?? true;
    final ancestor =
        context
            .dependOnInheritedWidgetOfExactType<_ZyraBottomCueOwner>()
            ?.active ??
        false;
    final inheritedBack = context
        .dependOnInheritedWidgetOfExactType<_ZyraInlineBackBinding>()
        ?.onBack;
    if (revision != _revision ||
        !identical(route, _route) ||
        current != _routeCurrent ||
        ancestor != _ancestorActive ||
        !identical(inheritedBack, _inheritedBack)) {
      // A consumed edge close may have popped its own Navigator route. Keep
      // that departing surface offscreen through the route's reverse rather
      // than snapping it back to rest for a second exit. No pending gesture
      // or return authority survives this transition.
      final preserveCompletedSlide =
          _completedSwipeSlide &&
          _taken &&
          identical(route, _route) &&
          _routeCurrent &&
          !current &&
          revision == _revision &&
          ancestor == _ancestorActive;
      _revision = revision;
      _route = route;
      _routeCurrent = current;
      _ancestorActive = ancestor;
      _inheritedBack = inheritedBack;
      _invalidate(preserveCompletedSlide: preserveCompletedSlide);
    }
  }

  @override
  void didUpdateWidget(covariant ZyraPullDownCloseCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.inlineBackHeader != widget.inlineBackHeader ||
        oldWidget.routeIdentity != widget.routeIdentity ||
        !identical(oldWidget.onBack, widget.onBack)) {
      // A shared return owner also revokes its callback/epoch while its
      // Navigator route departs. Keep only the already consumed visual slide;
      // no gesture or callback binding is retained for that noncurrent route.
      final preserveCompletedSlide =
          _completedSwipeSlide &&
          _taken &&
          identical(ModalRoute.of(context), _route) &&
          (_route?.isCurrent ?? true) == false &&
          oldWidget.enabled == widget.enabled &&
          oldWidget.inlineBackHeader == widget.inlineBackHeader;
      _invalidate(preserveCompletedSlide: preserveCompletedSlide);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _swipeForeground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) _resetSwipe();
  }

  @override
  void didChangeMetrics() => _resetSwipe();

  @override
  void dispose() {
    _epoch++;
    _swipeSerial++;
    _swipeForeground = false;
    // Cancel the ticker without broadcasting a new visual value to children
    // while this element and its AnimatedBuilder are being disposed.
    _swipeMotion.stop(canceled: true);
    WidgetsBinding.instance.removeObserver(this);
    _backSwipe.dispose();
    _swipeMotion.dispose();
    super.dispose();
  }

  bool get _swipeBindingCurrent =>
      mounted &&
      _swipeForeground &&
      !_taken &&
      widget.enabled &&
      widget.onBack != null &&
      widget.routeIdentity != null &&
      !_ancestorActive &&
      _routeCurrent &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  bool get _canStartSwipe => _swipeBindingCurrent && !_swipeSettling;

  bool get _validSwipe =>
      _swipeBindingCurrent &&
      _swipePointer != null &&
      _swipeEpoch == _epoch &&
      _swipeBack != null;

  void _observeSwipeDown(PointerDownEvent event) {
    _swipePointers.add(event.pointer);
    if (_swipePointers.length > 1 || _swipeReleased) _resetSwipe();
  }

  void _edgeDown(PointerDownEvent event) {
    _observeSwipeDown(event);
    if (!_canStartSwipe ||
        _swipePointers.length != 1 ||
        event.buttons != kPrimaryButton) {
      return;
    }
    _resetSwipe();
    _swipePointer = event.pointer;
    _swipeEpoch = _epoch;
    _swipeBack = _capturedBack(preserveCompletedSlide: true);
    _swipeOrigin = event.position;
    _swipeWidth = context.size?.width ?? 0;
    _swipeVelocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    // Like Flutter's Cupertino edge detector, this recognizer enters before
    // a child's horizontal pager only at the edge. The translucent no-child
    // Listener still lets the child's taps and vertical scrolling participate.
    _backSwipe.addPointer(event);
  }

  void _observeSwipeMove(PointerMoveEvent event) {
    if (!_validSwipe || event.pointer != _swipePointer) return;
    _swipeTravel = event.position - _swipeOrigin;
    _swipeVelocity?.addPosition(event.timeStamp, event.position);
    if (_swipeRightward == null && _swipeTravel.distance > kTouchSlop) {
      _swipeRightward =
          _swipeTravel.dx > 0 && _swipeTravel.dx > _swipeTravel.dy.abs() * 1.1;
      if (_swipeRightward != true) _resetSwipe();
    }
    _trackSwipe();
  }

  void _observeSwipeUp(PointerUpEvent event) {
    _swipePointers.remove(event.pointer);
    if (!_validSwipe || event.pointer != _swipePointer) return;
    _swipeTravel = event.position - _swipeOrigin;
    _swipeVelocity?.addPosition(event.timeStamp, event.position);
    _swipeReleaseVelocity =
        _swipeVelocity?.getVelocity().pixelsPerSecond.dx ?? 0;
    _swipeReleased = true;
  }

  void _observeSwipeCancel(PointerCancelEvent event) {
    _swipePointers.remove(event.pointer);
    if (event.pointer == _swipePointer) _cancelSwipe();
  }

  void _swipeStart(DragStartDetails details) {
    if (!_validSwipe || _swipePointers.length != 1) return;
    _swipeAccepted = true;
    _trackSwipe();
  }

  void _trackSwipe() {
    if (!_validSwipe ||
        !_swipeAccepted ||
        _swipeRightward != true ||
        _swipeSettling ||
        _swipeReducedMotion) {
      return;
    }
    _swipeMotion.value = _swipeTravel.dx.clamp(0.0, _swipeWidth).toDouble();
  }

  void _cancelSwipe() {
    final animate =
        mounted &&
        _swipeBindingCurrent &&
        !_swipeReducedMotion &&
        _swipeMotion.value > 0;
    _resetSwipe(keepPosition: animate);
    if (!animate) return;
    final serial = _swipeSerial;
    _swipeSettling = true;
    unawaited(() async {
      try {
        await _swipeMotion
            .animateTo(
              0,
              duration: _swipeRestoreDuration,
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      } on TickerCanceled {
        return;
      }
      if (mounted && serial == _swipeSerial) _resetSwipe();
    }());
  }

  void _swipeEnd(DragEndDetails details) {
    if (!_validSwipe ||
        !_swipeAccepted ||
        !_swipeReleased ||
        _swipeRightward != true ||
        _swipePointers.isNotEmpty ||
        _swipeWidth <= 0 ||
        _swipeTravel.dx <= _swipeTravel.dy.abs()) {
      _cancelSwipe();
      return;
    }
    final distance = _swipeTravel.dx;
    // The arena's post-slop fling distance can discard a deliberate short
    // flick. Use the same admitted pointer's complete travel/velocity, still
    // requiring accepted horizontal ownership, 24px and genuine release.
    final velocity = math.max(
      details.primaryVelocity ?? 0,
      _swipeReleaseVelocity,
    );
    final commit =
        distance + .01 >= math.max(48.0, math.min(72.0, _swipeWidth * .16)) ||
        (distance >= 24 && velocity >= 500);
    final serial = _swipeSerial;
    final back = _swipeBack!;
    // Finish only after dispatch, so cancel/multitouch in this release turn
    // can revoke it. Both inputs share _capturedBack's exact once-only owner.
    scheduleMicrotask(() async {
      if (!_validSwipe ||
          serial != _swipeSerial ||
          !_swipeReleased ||
          _swipePointers.isNotEmpty ||
          !identical(back, _swipeBack)) {
        return;
      }
      _swipeSettling = true;
      if (!_swipeReducedMotion) {
        try {
          await _swipeMotion
              .animateTo(
                commit ? _swipeWidth : 0,
                duration: commit ? _swipeCloseDuration : _swipeRestoreDuration,
                curve: Curves.easeOutCubic,
              )
              .orCancel;
        } on TickerCanceled {
          return;
        }
      }
      // Motion never carries navigation authority. Its completion must still
      // own the exact live binding, genuine release and untouched pointer set.
      if (!_validSwipe ||
          serial != _swipeSerial ||
          !_swipeReleased ||
          _swipePointers.isNotEmpty ||
          !identical(back, _swipeBack)) {
        return;
      }
      _resetSwipe(keepPosition: commit);
      if (commit) back();
    });
  }

  VoidCallback _capturedBack({bool preserveCompletedSlide = false}) {
    final epoch = _epoch;
    final revision = _revision;
    final identity = widget.routeIdentity;
    final callback = widget.onBack;
    final route = _route;
    return () {
      if (!mounted ||
          _taken ||
          !widget.enabled ||
          callback == null ||
          identity == null ||
          epoch != _epoch ||
          revision != _revision ||
          identity != widget.routeIdentity ||
          !identical(callback, widget.onBack) ||
          !identical(route, _route) ||
          !_routeCurrent ||
          (ModalRoute.of(context)?.isCurrent ?? true) == false ||
          ZyraBackNavigationPreview.revisionOf(context) != revision ||
          (context
                  .dependOnInheritedWidgetOfExactType<_ZyraBottomCueOwner>()
                  ?.active ??
              false)) {
        return;
      }
      final keepSlide =
          preserveCompletedSlide &&
          !_swipeReducedMotion &&
          _swipeMotion.value > 0;
      _resetSwipe(keepPosition: keepSlide);
      _completedSwipeSlide = keepSlide;
      setState(() => _taken = true);
      if (keepSlide) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // A caller may intentionally decline a return. Restore only its
          // visual surface after the owner has had a frame to remove it;
          // never re-arm the consumed action or expose a different owner.
          if (!mounted ||
              !_taken ||
              !_completedSwipeSlide ||
              epoch != _epoch ||
              revision != _revision ||
              identity != widget.routeIdentity ||
              !identical(callback, widget.onBack) ||
              !identical(route, _route) ||
              !_routeCurrent ||
              (ModalRoute.of(context)?.isCurrent ?? true) == false) {
            return;
          }
          _completedSwipeSlide = false;
          _swipeMotion.value = 0;
        });
      }
      callback();
    };
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final ancestor = context
        .dependOnInheritedWidgetOfExactType<_ZyraBottomCueOwner>();
    final inheritedOwner = ancestor?.active ?? false;
    final inheritedInline = context
        .dependOnInheritedWidgetOfExactType<_ZyraInlineBackBinding>();
    final forwardInline = inheritedOwner && inheritedInline?.available == true;
    final ownsReturn =
        widget.enabled &&
        widget.onBack != null &&
        widget.routeIdentity != null &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        !inheritedOwner;
    // A nested Circle Navigator inherits its parent's admitted return. Its
    // leaf exposes that same guarded assistive action, never another owner.
    final inheritedReturn =
        forwardInline &&
        !widget.inlineBackHeader &&
        !identical(inheritedInline!.route, _route);
    final back = ownsReturn && !_taken
        ? _accessibleBack ??= _capturedBack()
        : inheritedReturn
        ? _inheritedBridge ??= _captureInheritedBack(inheritedInline.onBack)
        : null;
    // An admitted same-route manual child has no independent return. Let its
    // keyboard event reach the existing ancestor owner, while blocked,
    // covered or consumed boundaries still absorb it without navigating.
    final delegateKeyboard =
        inheritedOwner &&
        !inheritedReturn &&
        back == null &&
        widget.enabled &&
        widget.onBack != null &&
        widget.routeIdentity != null &&
        !_taken &&
        _routeCurrent &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        identical(inheritedInline?.route, _route);
    // Keep exactly the same child element ancestry when the keyboard, route
    // coverage or eligibility changes. Return eligibility must never recreate
    // an editor, draft composer, scroll position or nested Navigator.
    return Shortcuts(
      shortcuts: delegateKeyboard
          ? const <ShortcutActivator, Intent>{}
          : const {SingleActivator(LogicalKeyboardKey.escape): DismissIntent()},
      child: Actions(
        actions: {
          if (!delegateKeyboard)
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                // An ineligible nested host must not let Escape fall through
                // to a different ancestor's return authority.
                back?.call();
                return null;
              },
            ),
        },
        child: Semantics(
          key: const ValueKey('zyra_pull_down_back_semantics'),
          container: true,
          explicitChildNodes: true,
          onDismiss: back,
          customSemanticsActions: back == null
              ? null
              : {CustomSemanticsAction(label: 'Back'): back},
          child: _ZyraBottomCueOwner(
            active: inheritedOwner || ownsReturn,
            child: _ZyraInlineBackBinding(
              route: forwardInline ? inheritedInline!.route : _route,
              available:
                  forwardInline || (widget.inlineBackHeader && ownsReturn),
              onBack: forwardInline ? inheritedInline!.onBack : back,
              child: Listener(
                key: const ValueKey('zyra_back_swipe_pointer'),
                behavior: HitTestBehavior.translucent,
                onPointerDown: _observeSwipeDown,
                onPointerMove: _observeSwipeMove,
                onPointerUp: _observeSwipeUp,
                onPointerCancel: _observeSwipeCancel,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Eligibility/caller binding was captured in build, never queried
                    // from this deferred layout.
                    final width = constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : media.size.width;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: widget.paintBackground && ownsReturn
                            ? ZyraColors.brandGradient
                            : null,
                      ),
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          // Keep the moving surface's ancestry stable at rest. The
                          // edge sensor stays stationary; no cached page is revealed.
                          AnimatedBuilder(
                            animation: _swipeMotion,
                            builder: (context, child) => ClipRect(
                              clipBehavior: Clip.hardEdge,
                              child: Transform.translate(
                                key: const ValueKey(
                                  'zyra_back_swipe_translation',
                                ),
                                offset: Offset(_swipeMotion.value, 0),
                                child: IgnorePointer(
                                  ignoring:
                                      _swipeSettling || _swipeMotion.value > 0,
                                  child: ExcludeSemantics(
                                    excluding:
                                        _swipeSettling ||
                                        _swipeMotion.value > 0,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient:
                                            widget.paintBackground && ownsReturn
                                            ? ZyraColors.brandGradient
                                            : null,
                                        boxShadow: _swipeMotion.value > 0
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: .18),
                                                  blurRadius: 18,
                                                  offset: const Offset(-6, 0),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: child,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: widget.child,
                          ),
                          if (ownsReturn && !_taken)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: math.min(
                                width,
                                math.max(44.0, media.padding.left),
                              ),
                              child: Listener(
                                key: const ValueKey('zyra_back_swipe_edge'),
                                behavior: HitTestBehavior.translucent,
                                onPointerDown: _edgeDown,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback? _captureInheritedBack(VoidCallback? callback) {
    if (callback == null) return null;
    final epoch = _epoch;
    final revision = _revision;
    final route = _route;
    final identity = widget.routeIdentity;
    return () {
      if (!mounted ||
          _taken ||
          !widget.enabled ||
          identity == null ||
          epoch != _epoch ||
          revision != _revision ||
          identity != widget.routeIdentity ||
          !identical(route, _route) ||
          !_routeCurrent ||
          (ModalRoute.of(context)?.isCurrent ?? true) == false ||
          ZyraBackNavigationPreview.revisionOf(context) != revision ||
          !identical(callback, _inheritedBack) ||
          !identical(
            callback,
            context
                .dependOnInheritedWidgetOfExactType<_ZyraInlineBackBinding>()
                ?.onBack,
          )) {
        return;
      }
      setState(() => _taken = true);
      callback();
    };
  }
}

/// Compatibility for retained heading slots. Return navigation is now
/// presented through the owning edge and assistive action, not visible chrome.
class ZyraInlineBackButton extends StatelessWidget {
  const ZyraInlineBackButton({super.key});

  /// A retained heading must not reserve an empty Back-button slot.
  static Size? preferredSizeOf(BuildContext context) => null;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ZyraInlineBackBinding extends InheritedWidget {
  const _ZyraInlineBackBinding({
    required this.route,
    required this.available,
    required this.onBack,
    required super.child,
  });

  final bool available;
  final ModalRoute<dynamic>? route;
  final VoidCallback? onBack;

  @override
  bool updateShouldNotify(_ZyraInlineBackBinding oldWidget) =>
      route != oldWidget.route ||
      available != oldWidget.available ||
      onBack != oldWidget.onBack;
}

class _ZyraBottomCueOwner extends InheritedWidget {
  const _ZyraBottomCueOwner({required this.active, required super.child});

  final bool active;

  @override
  bool updateShouldNotify(_ZyraBottomCueOwner oldWidget) =>
      active != oldWidget.active;
}

/// A caller-owned page return with an interactive left-edge swipe and
/// assistive/keyboard actions. Child scrollables keep their gesture ownership.
/// Supply a stable callback and change [routeIdentity] when its owner changes.
class ZyraPullDownBackScope extends StatefulWidget {
  const ZyraPullDownBackScope({
    super.key,
    required this.child,
    required this.onBack,
    required this.routeIdentity,
    this.enabled = true,
    this.paintBackground = true,
    this.inlineBackHeader = false,
    this.returnForegroundColor,
  });

  final Widget child;
  final VoidCallback onBack;
  final Object routeIdentity;
  final bool enabled;
  final bool paintBackground;
  final bool inlineBackHeader;
  final Color? returnForegroundColor;

  @override
  State<ZyraPullDownBackScope> createState() => _ZyraPullDownBackScopeState();
}

class _ZyraPullDownBackScopeState extends State<ZyraPullDownBackScope> {
  int _epoch = 0;
  ModalRoute<dynamic>? _modalRoute;
  bool _modalCurrent = true;
  int _navigationRevision = 0;
  bool _backTaken = false;
  VoidCallback? _accessibleBack;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final current = route?.isCurrent ?? true;
    final revision = ZyraBackNavigationPreview.revisionOf(context);
    if (!identical(route, _modalRoute) ||
        current != _modalCurrent ||
        revision != _navigationRevision) {
      _modalRoute = route;
      _modalCurrent = current;
      _navigationRevision = revision;
      _invalidateBinding();
    }
  }

  void _invalidateBinding() {
    ++_epoch;
    _accessibleBack = null;
    _backTaken = false;
  }

  @override
  void didUpdateWidget(covariant ZyraPullDownBackScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeIdentity != widget.routeIdentity ||
        !identical(oldWidget.onBack, widget.onBack) ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.inlineBackHeader != widget.inlineBackHeader) {
      _invalidateBinding();
    }
  }

  @override
  void dispose() {
    ++_epoch;
    super.dispose();
  }

  bool _validBinding(int epoch, Object route, VoidCallback back) =>
      mounted &&
      widget.enabled &&
      _modalCurrent &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      _navigationRevision == ZyraBackNavigationPreview.revisionOf(context) &&
      epoch == _epoch &&
      route == widget.routeIdentity &&
      identical(back, widget.onBack) &&
      !_backTaken;

  void _takeBack(int epoch, Object route, VoidCallback back) {
    if (!_validBinding(epoch, route, back)) return;
    _backTaken = true;
    setState(() {});
    back();
  }

  @override
  Widget build(BuildContext context) {
    final epoch = _epoch;
    final route = widget.routeIdentity;
    final back = widget.onBack;
    // A repaint is not a new return owner. Only an actual binding change
    // clears this callback; consumed returns cannot re-arm the child edge.
    final accessibleBack = _accessibleBack ??= () =>
        _takeBack(epoch, route, back);
    // The cue exposes this same guarded action for assistive technology,
    // keyboard and edge input, including callers that use it directly.
    // Existing callers retain system Back; no competing pop handler is added.
    return ZyraPullDownCloseCue(
      enabled: widget.enabled,
      paintBackground: widget.paintBackground,
      inlineBackHeader: widget.inlineBackHeader,
      returnForegroundColor: widget.returnForegroundColor,
      onBack: accessibleBack,
      routeIdentity: (widget.routeIdentity, epoch),
      child: widget.child,
    );
  }
}
