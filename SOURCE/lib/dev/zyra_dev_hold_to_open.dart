// Presentation-only developer entry gesture. The caller retains all admission,
// account and route authority; a completed hold never grants that authority.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class ZyraDevHoldToOpen extends StatefulWidget {
  const ZyraDevHoldToOpen({
    super.key,
    required this.child,
    required this.enabled,
    required this.identity,
    required this.canOpen,
    required this.onOpen,
  });

  final Widget child;
  final bool enabled;
  final Object identity;
  final bool Function() canOpen;
  final VoidCallback onOpen;

  @override
  State<ZyraDevHoldToOpen> createState() => _ZyraDevHoldToOpenState();
}

class _HoldBinding {
  const _HoldBinding({
    required this.epoch,
    required this.identity,
    required this.canOpen,
    required this.onOpen,
    required this.route,
  });

  final int epoch;
  final Object identity;
  final bool Function() canOpen;
  final VoidCallback onOpen;
  final ModalRoute<dynamic>? route;
}

class _ZyraDevHoldToOpenState extends State<ZyraDevHoldToOpen>
    with WidgetsBindingObserver {
  int _epoch = 0;
  bool _fired = false;
  bool _foreground = true;
  bool _routeCurrent = true;
  ModalRoute<dynamic>? _route;
  _HoldBinding? _binding;
  _DevHoldGestureRecognizer? _recognizer;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  void _invalidate() {
    _epoch++;
    _binding = null;
    _fired = false;
    _recognizer?.cancelHold();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final current = route?.isCurrent ?? true;
    if (!identical(route, _route) || current != _routeCurrent) {
      _invalidate();
      _route = route;
      _routeCurrent = current;
    }
  }

  @override
  void didUpdateWidget(covariant ZyraDevHoldToOpen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.identity != widget.identity ||
        !identical(oldWidget.canOpen, widget.canOpen) ||
        !identical(oldWidget.onOpen, widget.onOpen)) {
      _invalidate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // A resume is not a fresh press: invalidate both sides of a lifecycle ABA.
    _invalidate();
  }

  bool _admitted() {
    if (!mounted || !widget.enabled || !_foreground || !_routeCurrent) {
      return false;
    }
    final route = ModalRoute.of(context);
    if (!identical(route, _route) || !(route?.isCurrent ?? true)) {
      return false;
    }
    try {
      return widget.canOpen();
    } catch (_) {
      return false;
    }
  }

  bool _begin() {
    _binding = null;
    _fired = false;
    if (!_admitted()) return false;
    _binding = _HoldBinding(
      epoch: _epoch,
      identity: widget.identity,
      canOpen: widget.canOpen,
      onOpen: widget.onOpen,
      route: _route,
    );
    return true;
  }

  bool _validBinding() {
    final binding = _binding;
    return binding != null &&
        !_fired &&
        binding.epoch == _epoch &&
        binding.identity == widget.identity &&
        identical(binding.canOpen, widget.canOpen) &&
        identical(binding.onOpen, widget.onOpen) &&
        identical(binding.route, _route) &&
        _admitted();
  }

  void _open() {
    if (!_validBinding()) return;
    final open = _binding!.onOpen;
    _fired = true;
    // Consume the captured press before calling a caller that may navigate.
    _binding = null;
    open();
  }

  void _end() {
    _binding = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _invalidate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    key: const ValueKey('dev_controls_hold_surface'),
    behavior: HitTestBehavior.translucent,
    // This hidden comparison must not create an accessibility shortcut that
    // bypasses its actual three-second pointer gesture.
    excludeFromSemantics: true,
    gestures: <Type, GestureRecognizerFactory>{
      _DevHoldGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<_DevHoldGestureRecognizer>(
            () => _DevHoldGestureRecognizer(debugOwner: this),
            (recognizer) {
              _recognizer = recognizer;
              recognizer
                ..begin = _begin
                ..canComplete = _validBinding
                ..onInterrupted = _end
                ..onLongPressStart = (_) => _open();
            },
          ),
    },
    child: widget.child,
  );
}

/// Uses the normal long-press arena/slop behavior. The longer deadline lets a
/// child's ordinary long press, text selection or scroll win first.
class _DevHoldGestureRecognizer extends LongPressGestureRecognizer {
  _DevHoldGestureRecognizer({super.debugOwner})
    : super(duration: const Duration(seconds: 3));

  bool Function()? begin;
  bool Function()? canComplete;
  VoidCallback? onInterrupted;
  final Set<int> _down = <int>{};
  bool _observingOtherPointers = false;

  void _track(PointerDownEvent event) {
    _down.add(event.pointer);
    GestureBinding.instance.pointerRouter.addRoute(event.pointer, _trackEnd);
    if (!_observingOtherPointers) {
      _observingOtherPointers = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(
        _observeOtherPointer,
      );
    }
  }

  void _observeOtherPointer(PointerEvent event) {
    if (event is! PointerDownEvent || _down.contains(event.pointer)) return;
    // Observe only to cancel an already active hold. Never enter the arena
    // for another surface, and require every finger to leave before rearming.
    _track(event);
    onInterrupted?.call();
    cancelHold();
  }

  @override
  void addPointer(PointerDownEvent event) {
    final first = _down.isEmpty;
    // Track denied and secondary pointers too, so lifting only one finger
    // cannot rearm a hold while another finger remains on this surface.
    _track(event);
    if (!first) {
      onInterrupted?.call();
      cancelHold();
      return;
    }
    if (event.buttons != kPrimaryButton || !(begin?.call() ?? false)) return;
    super.addPointer(event);
  }

  void _trackEnd(PointerEvent event) {
    if (event is! PointerUpEvent && event is! PointerCancelEvent) return;
    GestureBinding.instance.pointerRouter.removeRoute(event.pointer, _trackEnd);
    _down.remove(event.pointer);
    if (_down.isEmpty && _observingOtherPointers) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        _observeOtherPointer,
      );
      _observingOtherPointers = false;
    }
    onInterrupted?.call();
  }

  void cancelHold() {
    resolve(GestureDisposition.rejected);
    final primary = primaryPointer;
    if (primary != null && state == GestureRecognizerState.possible) {
      // The arena may already have been resolved. Stop the deadline in either
      // case, without inventing a fresh recognizer or a fresh pointer sequence.
      rejectGesture(primary);
    }
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer == primaryPointer) onInterrupted?.call();
  }

  @override
  void didExceedDeadline() {
    if (!(canComplete?.call() ?? false)) {
      cancelHold();
      return;
    }
    // Accepting here cancels an underlying tap before invoking onOpen.
    super.didExceedDeadline();
  }

  @override
  void dispose() {
    for (final pointer in _down) {
      GestureBinding.instance.pointerRouter.removeRoute(pointer, _trackEnd);
    }
    _down.clear();
    if (_observingOtherPointers) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        _observeOtherPointer,
      );
      _observingOtherPointers = false;
    }
    super.dispose();
  }
}
