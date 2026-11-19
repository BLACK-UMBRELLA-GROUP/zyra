import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/zyra_text.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_first_tour_steps.dart';

const _gold = Color(0xFFA9792E);
const _ivory = Color(0xFFFBF7F0);
const _ink = Color(0xFF2B2420);
const _muted = Color(0xFF6E6257);

/// LOCK 36's single, blocking presentation. The owner supplies only rectangles
/// from its current pages; this widget never invokes any highlighted control.
class ZyraFirstTourOverlay extends StatefulWidget {
  const ZyraFirstTourOverlay({
    super.key,
    required this.index,
    required this.guardian,
    required this.firstName,
    required this.onNext,
    required this.onBack,
    required this.targetRect,
    required this.navBarTop,
    this.canAct,
  });

  final int index;
  final bool guardian;
  final String firstName;
  final VoidCallback onNext, onBack;
  final Rect? Function(String) targetRect;
  final double Function() navBarTop;
  final bool Function()? canAct;

  @override
  State<ZyraFirstTourOverlay> createState() => _ZyraFirstTourOverlayState();
}

class _ZyraFirstTourOverlayState extends State<ZyraFirstTourOverlay>
    with SingleTickerProviderStateMixin {
  final _noteKey = GlobalKey();
  late final AnimationController _gesture = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  _TourPlacement? _placement;
  Size _size = Size.zero;
  bool _scheduled = false;
  bool _quiet = false;

  List<ZyraFirstTourStep> get _steps =>
      widget.guardian ? zyraGuardianTourSteps : zyraSeekerTourSteps;
  int get _index => widget.index.clamp(0, _steps.length + 1);
  bool get _isCard => _index == 0 || _index == _steps.length + 1;
  ZyraFirstTourStep? get _step => _isCard ? null : _steps[_index - 1];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    _quiet =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    _syncGesture();
  }

  @override
  void didUpdateWidget(covariant ZyraFirstTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.guardian != widget.guardian) {
      _placement = null;
      _syncGesture();
    }
  }

  void _syncGesture() {
    _gesture.stop();
    _gesture.value = 0;
    if (!_quiet && !_isCard) {
      _gesture.duration = Duration(milliseconds: _step!.swipe ? 2000 : 1800);
      _gesture.repeat();
    }
  }

  @override
  void dispose() {
    _gesture.dispose();
    super.dispose();
  }

  void _scheduleMeasure() {
    if (_scheduled || _isCard) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || _isCard) return;
      final box = _noteKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize || _size.isEmpty) return;
      final step = _step!;
      final tab = _visible(widget.targetRect('floating-nav-item-${step.tab}'));
      if (tab == null) return;
      final target = step.targetKey == null
          ? null
          : _visible(widget.targetRect(step.targetKey!));
      final nav = _padded(tab, 4);
      final isTab = target == null;
      var lit = isTab ? nav : _padded(target, 8);
      final height = box.size.height;
      final limit = widget.navBarTop() - 12;
      double top;
      bool above;
      if (!isTab && lit.bottom + 14 + height <= limit) {
        top = lit.bottom + 14;
        above = false;
      } else if (isTab || lit.top - 14 - height >= 48) {
        top = lit.top - 14 - height;
        above = true;
      } else {
        // Q175: expose only the top of an item too tall for either side.
        // Its gold edge and cut-out end together, 14 pt before the note.
        final bottom = math.min(
          lit.bottom,
          math.max(lit.top + 64, limit - 14 - height),
        );
        lit = Rect.fromLTRB(lit.left, lit.top, lit.right, bottom);
        top = lit.bottom + 14;
        above = false;
      }
      final next = _TourPlacement(
        target: lit,
        tab: nav,
        top: top,
        height: height,
        above: above,
        tabOnly: isTab,
      );
      if (next != _placement) setState(() => _placement = next);
    });
  }

  Rect? _visible(Rect? rect) {
    if (rect == null || !rect.isFinite || rect.isEmpty) return null;
    final visible = rect.intersect(Offset.zero & _size);
    return visible.isEmpty ? null : visible;
  }

  Rect _padded(Rect rect, double pad) => Rect.fromLTRB(
    math.max(4, rect.left - pad),
    math.max(0, rect.top - pad),
    math.min(_size.width - 4, rect.right + pad),
    math.min(_size.height, rect.bottom + pad),
  );

  void _next() {
    if (widget.canAct?.call() ?? true) widget.onNext();
  }

  void _back() {
    if (widget.canAct?.call() ?? true) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size != _size) {
            _size = size;
            _placement = null;
          }
          _scheduleMeasure();
          final next = ZyraTapFeedback.onTap(
            context,
            _next,
            canAct: widget.canAct,
          )!;
          final back = ZyraTapFeedback.onTap(
            context,
            _back,
            canAct: widget.canAct,
          )!;
          return GestureDetector(
            key: const ValueKey('first_tour_overlay'),
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapUp: (details) {
              if (_index > 0 && details.localPosition.dx < size.width * .2) {
                back();
              } else {
                next();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TourShade(placement: _placement, card: _isCard),
                    ),
                  ),
                ),
                if (_isCard)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _card(next),
                    ),
                  )
                else ...[
                  if (_placement case final p?) ...[
                    Positioned.fromRect(
                      rect: p.target,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          key: const ValueKey('first_tour_target'),
                          decoration: BoxDecoration(
                            border: Border.all(color: _gold, width: 2),
                            borderRadius: BorderRadius.circular(
                              p.tabOnly ? p.target.shortestSide / 2 : 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: p.tab,
                      child: const IgnorePointer(
                        child: SizedBox(key: ValueKey('first_tour_tab')),
                      ),
                    ),
                    _touch(p, _step!),
                    Positioned(
                      left:
                          ((p.target.center.dx).clamp(36, size.width - 36)) - 9,
                      top: p.above ? p.top + p.height - 10 : p.top - 8,
                      width: 18,
                      height: 18,
                      child: IgnorePointer(
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _ivory,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    left: 20,
                    right: 20,
                    top: _placement?.top ?? 48,
                    child: Opacity(
                      opacity: _placement == null ? 0 : 1,
                      child: _note(next),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed) => Semantics(
    button: true,
    label: label,
    onTap: onPressed,
    excludeSemantics: true,
    child: GestureDetector(
      key: const ValueKey('first_tour_next'),
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _gold,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: ZyraText.button(
            size: 14,
            color: _ivory,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    ),
  );

  Widget _card(VoidCallback next) {
    final welcome = _index == 0;
    return Container(
      key: const ValueKey('first_tour_card'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      decoration: BoxDecoration(
        color: _ivory,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x402B2420),
            offset: Offset(0, 20),
            blurRadius: 50,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ZYRA',
            style: ZyraText.body(
              size: 22,
              color: _gold,
            ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 7.04),
          ),
          const SizedBox(height: 16),
          Semantics(
            sortKey: const OrdinalSortKey(0),
            child: Text(
              welcome
                  ? 'Hi ${widget.firstName}, welcome'
                  : 'That’s everything, ${widget.firstName}',
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: 24,
                color: _ink,
              ).copyWith(fontWeight: FontWeight.w300, height: 1.25),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            sortKey: const OrdinalSortKey(1),
            child: Text(
              welcome
                  ? 'Let’s walk through the app together, one page at a time. It only takes a minute.'
                  : 'You can see this again any time from Settings. Bismillah — let’s begin.',
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: 15,
                color: _muted,
              ).copyWith(fontWeight: FontWeight.w300, height: 1.55),
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicWidth(
            child: _button(welcome ? 'Let’s go' : 'Start using ZYRA', next),
          ),
        ],
      ),
    );
  }

  Widget _note(VoidCallback next) {
    final step = _step!;
    final pageSteps = _steps.where((s) => s.tab == step.tab).toList();
    final pageIndex = pageSteps.indexOf(step);
    final page = (widget.guardian
        ? const ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile']
        : const [
            'Profiles',
            'Journey',
            'My ZYRA',
            'Guardian',
            'Profile',
          ])[step.tab];
    return KeyedSubtree(
      key: _noteKey,
      child: Container(
        key: const ValueKey('first_tour_note'),
        decoration: BoxDecoration(
          color: _ivory,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x472B2420),
              offset: Offset(0, 14),
              blurRadius: 36,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                '${page.toUpperCase()} · PAGE ${step.tab + 1} OF 5',
                style: ZyraText.body(
                  size: 11,
                  color: _gold,
                ).copyWith(letterSpacing: 1.4),
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              sortKey: const OrdinalSortKey(0),
              liveRegion: true,
              child: Text(
                step.title,
                style: ZyraText.body(
                  size: 19,
                  color: _ink,
                ).copyWith(fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 4),
            Semantics(
              sortKey: const OrdinalSortKey(1),
              child: Text(
                step.body,
                style: ZyraText.body(
                  size: 14.5,
                  color: _muted,
                ).copyWith(fontWeight: FontWeight.w300, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < pageSteps.length; i++) ...[
                        if (i != 0) const SizedBox(width: 5),
                        Container(
                          width: i == pageIndex ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == pageIndex
                                ? _gold
                                : const Color(0x2E3E2E1E),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _button(_index == _steps.length ? 'Finish' : 'Next', next),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _touch(_TourPlacement p, ZyraFirstTourStep step) {
    final x = (step.swipe || step.photo)
        ? p.target.left + p.target.width * .72
        : p.target.center.dx;
    // V290 anchors both the card swipe and photo tap beside the photo.
    final y = step.targetKey == 'tour_profiles_card'
        ? p.target.top + p.target.height * .3
        : p.target.center.dy;
    return Positioned(
      left: x - 20,
      top: y - 20,
      width: 40,
      height: 40,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _gesture,
          builder: (context, _) {
            final t = _gesture.value;
            final swipeProgress = Curves.easeInOut.transform(
              ((t - .15) / .55).clamp(0, 1),
            );
            final opacity = _quiet
                ? 1.0
                : step.swipe
                ? (t < .15
                      ? t / .15
                      : t > .7
                      ? (1 - t) / .3
                      : 1.0)
                : t < .18
                ? t / .18
                : t > .8
                ? (1 - t) / .2
                : 1.0;
            final scale = _quiet
                ? 1.0
                : step.swipe
                ? (t < .15 ? 1.15 - .27 * (t / .15) : .88)
                : t < .18
                ? 1.25 - .25 * t / .18
                : t < .32
                ? 1 - .22 * (t - .18) / .14
                : t < .46
                ? .78 + .22 * (t - .32) / .14
                : 1.0;
            return Transform.translate(
              offset: Offset(
                !_quiet && step.swipe
                    ? -p.target.width * .44 * swipeProgress
                    : 0,
                0,
              ),
              child: Opacity(
                opacity: opacity.clamp(0, 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!step.swipe && !_quiet && t > .3)
                      Opacity(
                        opacity: (.9 * (1 - (t - .3) / .7)).clamp(0, 1),
                        child: Transform.scale(
                          scale: .6 + 1.6 * (t - .3) / .7,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _gold, width: 2),
                            ),
                          ),
                        ),
                      ),
                    Transform.scale(
                      key: const ValueKey('first_tour_touch'),
                      scale: scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x99FFFFFF),
                          border: Border.all(color: _gold, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x402B2420),
                              offset: Offset(0, 4),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

@immutable
class _TourPlacement {
  const _TourPlacement({
    required this.target,
    required this.tab,
    required this.top,
    required this.height,
    required this.above,
    required this.tabOnly,
  });
  final Rect target, tab;
  final double top, height;
  final bool above, tabOnly;

  @override
  bool operator ==(Object other) =>
      other is _TourPlacement &&
      target == other.target &&
      tab == other.tab &&
      top == other.top &&
      height == other.height &&
      above == other.above &&
      tabOnly == other.tabOnly;
  @override
  int get hashCode => Object.hash(target, tab, top, height, above, tabOnly);
}

class _TourShade extends CustomPainter {
  const _TourShade({required this.placement, required this.card});
  final _TourPlacement? placement;
  final bool card;

  @override
  void paint(Canvas canvas, Size size) {
    var shade = Path()..addRect(Offset.zero & size);
    final p = placement;
    if (!card && p != null) {
      final holes = [
        RRect.fromRectAndRadius(
          p.target,
          Radius.circular(p.tabOnly ? p.target.shortestSide / 2 : 22),
        ),
        if (!p.tabOnly)
          RRect.fromRectAndRadius(
            p.tab,
            Radius.circular(p.tab.shortestSide / 2),
          ),
      ];
      for (final hole in holes) {
        shade = Path.combine(
          PathOperation.difference,
          shade,
          Path()..addRRect(hole),
        );
      }
    }
    canvas.drawPath(
      shade,
      Paint()..color = _ink.withValues(alpha: card ? .45 : .5),
    );
  }

  @override
  bool shouldRepaint(covariant _TourShade oldDelegate) =>
      placement != oldDelegate.placement || card != oldDelegate.card;
}
