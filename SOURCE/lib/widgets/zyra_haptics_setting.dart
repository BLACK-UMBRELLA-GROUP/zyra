// LOCK 21 V2: shared, owner-guarded Settings control.
import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';

class ZyraHapticsSetting extends StatefulWidget {
  const ZyraHapticsSetting({
    super.key,
    required this.level,
    this.ownerIdentity,
    this.readLevel,
    required this.canAct,
    required this.onChanged,
    required this.row,
  });

  final ZyraHapticLevel level;
  final Object? ownerIdentity;
  final ZyraHapticLevel Function()? readLevel;
  final bool Function() canAct;
  final bool Function(ZyraHapticLevel) onChanged;
  final Widget Function(bool expanded, VoidCallback onTap) row;

  @override
  State<ZyraHapticsSetting> createState() => _ZyraHapticsSettingState();
}

class _HapticPointer {
  _HapticPointer(this.id);
  final int id;
  bool released = false;
}

class _ZyraHapticsSettingState extends State<ZyraHapticsSetting>
    with WidgetsBindingObserver {
  static const _levels = ZyraHapticLevel.values;
  bool _expanded = false;
  int _expandEpoch = 0;
  int _ownerEpoch = 0;
  bool? _routeCurrent;
  bool _foreground = true;
  _HapticPointer? _pointer;
  bool Function()? _gestureOwner;
  bool Function(ZyraHapticLevel)? _gestureChange;
  ZyraHapticLevel Function()? _gestureRead;
  ZyraHapticLevel? _startLevel;
  ZyraHapticLevel? _acceptedLevel;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    setState(() {
      _foreground = foreground;
      _revokeGesture();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _revokeGesture() {
    _ownerEpoch++;
    _gestureOwner = null;
    _gestureChange = null;
    _gestureRead = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (_routeCurrent != current) _revokeGesture();
    _routeCurrent = current;
  }

  @override
  void didUpdateWidget(covariant ZyraHapticsSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerIdentity != widget.ownerIdentity ||
        (oldWidget.level != widget.level &&
            (_gestureOwner == null || _acceptedLevel != widget.level))) {
      _revokeGesture();
    }
  }

  ZyraHapticLevel _level(double value) => _levels[value.round()];

  bool _current(bool Function() owner) =>
      mounted && _expanded && owner() && widget.canAct();

  void _start(
    double value,
    bool Function() owner,
    bool Function(ZyraHapticLevel) change,
    ZyraHapticLevel Function()? read,
  ) {
    final start = _level(value);
    if (!_current(owner) || (read != null && read() != start)) return;
    _gestureOwner = owner;
    _gestureChange = change;
    _gestureRead = read;
    _startLevel = _acceptedLevel = start;
  }

  void _change(double value) {
    final owner = _gestureOwner;
    final level = _level(value);
    if (owner == null || !_current(owner) || level == _acceptedLevel) return;
    final read = _gestureRead;
    if (read != null && read() != _acceptedLevel) {
      _revokeGesture();
      return;
    }
    if (_gestureChange?.call(level) == true) _acceptedLevel = level;
  }

  void _end(double value) {
    final owner = _gestureOwner;
    final level = _level(value);
    final accepted = _acceptedLevel;
    final start = _startLevel;
    final pointer = _pointer;
    final read = _gestureRead;
    // A cancel ends Flutter's Slider interaction too. Snapshot the pointer
    // release now so a later up after a lost gesture cannot play feedback.
    final released = pointer == null || pointer.released;
    _gestureOwner = null;
    _gestureChange = null;
    _gestureRead = null;
    if (owner == null ||
        !released ||
        !_current(owner) ||
        accepted != level ||
        (read != null && read() != level) ||
        start == level) {
      return;
    }
    unawaited(ZyraInteractionStyle.emitSelectionHaptic(level: level));
  }

  void _finishPointer(int id, {required bool released}) {
    final pointer = _pointer;
    if (pointer == null || pointer.id != id) return;
    pointer.released = released;
    // Keep cancellation distinct from a VoiceOver action until Slider's
    // recognizers have processed this same pointer event.
    scheduleMicrotask(() {
      if (identical(_pointer, pointer)) _pointer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final admitted = widget.canAct;
    final change = widget.onChanged;
    final read = widget.readLevel;
    final identity = widget.ownerIdentity;
    final ownerEpoch = _ownerEpoch;
    final epoch = _expandEpoch;
    bool owner() =>
        mounted &&
        widget.ownerIdentity == identity &&
        ownerEpoch == _ownerEpoch &&
        _routeCurrent == true &&
        _foreground &&
        _expandEpoch == epoch &&
        admitted();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.row(_expanded, () {
          if (owner() && widget.canAct()) {
            setState(() {
              _expandEpoch++;
              _expanded = !_expanded;
              _gestureOwner = null;
              _gestureChange = null;
              _gestureRead = null;
            });
          } else {
            ZyraInteractionStyle.cancelSelectionTap();
          }
        }),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Listener(
                  onPointerDown: (event) =>
                      _pointer ??= _HapticPointer(event.pointer),
                  onPointerUp: (event) =>
                      _finishPointer(event.pointer, released: true),
                  onPointerCancel: (event) =>
                      _finishPointer(event.pointer, released: false),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: ZyraColors.journeyGold,
                      inactiveTrackColor: ZyraColors.journeyGold.withValues(
                        alpha: .2,
                      ),
                      activeTickMarkColor: Colors.transparent,
                      inactiveTickMarkColor: Colors.transparent,
                      showValueIndicator: ShowValueIndicator.never,
                      thumbShape: const _HapticThumb(),
                    ),
                    child: Slider(
                      key: const ValueKey('zyra-haptic-strength-slider'),
                      value: widget.level.index.toDouble(),
                      max: (_levels.length - 1).toDouble(),
                      divisions: _levels.length - 1,
                      label: 'Haptic strength',
                      semanticFormatterCallback: (value) => _level(value).label,
                      onChangeStart: (value) =>
                          _start(value, owner, change, read),
                      onChanged: (value) {
                        if (owner()) _change(value);
                      },
                      onChangeEnd: (value) {
                        if (owner()) _end(value);
                      },
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (final level in _levels)
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              level.label,
                              style:
                                  ZyraText.subtext(
                                    size: 11,
                                    color: level == widget.level
                                        ? ZyraColors.goldText
                                        : ZyraColors.foregroundMuted,
                                  ).copyWith(
                                    fontWeight: level == widget.level
                                        ? FontWeight.w500
                                        : null,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HapticThumb extends SliderComponentShape {
  const _HapticThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.square(26);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas
      ..drawCircle(center, 13, Paint()..color = ZyraColors.journeyGold)
      ..drawCircle(center, 12, Paint()..color = ZyraColors.ivoryTop);
  }
}
