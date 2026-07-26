// Shared floating glassmorphic nav bar — 2026-07-19.
//
// Styling reference, per Founder-supplied screen recordings:
//   - Instagram: icon grows when selected, shrinks when not, smooth
//     animated transition between states.
//   - Lovable's ZYRA build: floating rounded glass pill, no fixed
//     per-item background — a single circular highlight "blob" sits
//     behind whichever icon is active and slides/morphs to the newly
//     selected tab rather than each item having its own static state.
//
// This widget combines both: a single circular highlight that slides
// between evenly-spaced tab cells, plus per-icon AnimatedScale so the
// active icon is visibly larger. Used by both HomeShell (Seeker) and
// WaliHomeShell so the two navs stay visually identical, per WALI
// ARCHITECTURE's "floating glass pill: same design as Seeker nav."
//
// UPDATED 2026-07-25 (Founder request: "touch moving" — confirmed via
// clarifying question to mean "draggable along the bar... press and
// slide to preview/switch tabs, like scrubbing"). Previously each
// item only responded to a discrete onTap (tap-up). Now the whole bar
// is one GestureDetector: a horizontal drag (or a single tap) is
// tracked continuously, the highlight follows the raw finger position
// directly (no animation lag while actively dragging), and the active
// tab switches live the moment the finger crosses into a new cell —
// exactly like scrubbing. The eased AnimatedPositioned slide is kept
// for the "settle" moment once the finger lifts, and for programmatic
// tab changes that don't originate from this bar.
//
// Text labels kept for now — Founder is still deciding label vs
// no-label (neither reference video shows text), easy to drop later
// via `showLabels: false`.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/zyra_text.dart';

class FloatingNavItem {
  final IconData icon;
  final String label;
  const FloatingNavItem({required this.icon, required this.label});
}

class FloatingNavBar extends StatefulWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  static const double _barHeight = 62;
  static const double _highlightSize = 44;

  // Raw finger x-position while actively dragging/pressing, relative to
  // the bar's own width — null when not touching, in which case the
  // highlight falls back to the eased, animated position for
  // widget.currentIndex (tap or programmatic change).
  double? _touchX;

  int _indexForX(double x, double barWidth) {
    final cellWidth = barWidth / widget.items.length;
    final i = (x / cellWidth).floor();
    return i.clamp(0, widget.items.length - 1);
  }

  void _handleTouchAt(double x, double barWidth) {
    setState(() => _touchX = x.clamp(0, barWidth));
    final index = _indexForX(x, barWidth);
    if (index != widget.currentIndex) widget.onTap(index);
  }

  void _endTouch() => setState(() => _touchX = null);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final cellWidth = barWidth / widget.items.length;
                  final dragging = _touchX != null;
                  final highlightLeft = dragging
                      ? (_touchX! - _highlightSize / 2).clamp(0.0, barWidth - _highlightSize)
                      : cellWidth * widget.currentIndex + (cellWidth - _highlightSize) / 2;
                  final liveIndex = dragging ? _indexForX(_touchX!, barWidth) : widget.currentIndex;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _handleTouchAt(d.localPosition.dx, barWidth),
                    onTapUp: (_) => _endTouch(),
                    onTapCancel: _endTouch,
                    onHorizontalDragStart: (d) => _handleTouchAt(d.localPosition.dx, barWidth),
                    onHorizontalDragUpdate: (d) => _handleTouchAt(d.localPosition.dx, barWidth),
                    onHorizontalDragEnd: (_) => _endTouch(),
                    onHorizontalDragCancel: _endTouch,
                    child: Stack(
                      children: [
                        // The sliding highlight — Lovable-style single blob,
                        // not a per-item background. Follows the finger
                        // directly (no easing) while actively touching;
                        // eases to the settled tab centre otherwise.
                        dragging
                            ? Positioned(
                                left: highlightLeft,
                                top: (_barHeight - _highlightSize) / 2,
                                child: _Highlight(size: _highlightSize),
                              )
                            : AnimatedPositioned(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                left: highlightLeft,
                                top: (_barHeight - _highlightSize) / 2,
                                child: _Highlight(size: _highlightSize),
                              ),
                        Row(
                          children: List.generate(widget.items.length, (i) {
                            final selected = i == liveIndex;
                            final item = widget.items[i];
                            final color = selected ? Colors.white : Colors.white.withOpacity(0.45);
                            return Expanded(
                              child: IgnorePointer(
                                // Touch handling now lives on the bar-wide
                                // GestureDetector above so a press/drag
                                // anywhere on the bar is tracked as one
                                // continuous gesture — individual cells no
                                // longer need (or intercept) their own taps.
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Instagram-style: bigger when selected,
                                    // smaller when not, animated between.
                                    AnimatedScale(
                                      scale: selected ? 1.0 : 0.82,
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      child: Icon(item.icon, color: color, size: selected ? 24 : 20),
                                    ),
                                    if (widget.showLabels) ...[
                                      const SizedBox(height: 2),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 220),
                                        style: ZyraText.subtext(size: 10, color: color),
                                        child: Text(item.label),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
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
    );
  }
}

class _Highlight extends StatelessWidget {
  final double size;
  const _Highlight({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.20),
        border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
      ),
    );
  }
}
