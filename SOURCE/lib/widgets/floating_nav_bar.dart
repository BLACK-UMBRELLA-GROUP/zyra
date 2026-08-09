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
// RESOLVED 2026-07-26 — Founder supplied 3 reference screen
// recordings (2 from Instagram, 1 of the original Lovable ZYRA
// prototype in motion) with explicit instruction: "drop the text."
// `showLabels` now defaults to false — icon-only, matching all 3
// references. The Lovable video is the authoritative spec for this
// bar specifically: a circular highlight badge (bigger + more
// opaque than this file previously had it, tuned below) behind the
// active icon only, not the labelled-pill look tried earlier. The
// Instagram clips corroborate the specific ask that started this
// pass — the deselect/shrink transition reading as smooth, not
// mechanical — hence the curve change below. Parameter kept (not
// deleted) in case a future context wants labels back; both current
// call sites (HomeShell, WaliHomeShell) rely on the new default.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
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
    this.showLabels = false,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  // Slimmer than before (62) now the bar is icon-only — matches the
  // Lovable reference video's proportions once the label row is gone.
  static const double _barHeight = 58;
  // Bigger relative to the icon than before (44) — the reference
  // video's badge clearly reads as larger than the icon's own tap
  // target, not a tight halo around it.
  static const double _highlightSize = 46;

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
    if (index != widget.currentIndex) {
      // 2026-07-26 (nav bar refinement pass — CHATGPT_REPLY_NAVBAR_
      // PHOTO_MENU_2026-07-26.md §1): a small, cheap "premium app"
      // detail that was simply missing — every native tab bar (iOS
      // Control Center, Instagram, Flutter's own Switch/Radio) gives a
      // light tap on selection change. Fires on crossing into a new
      // cell during a drag-scrub too, not just a discrete tap, since
      // both paths call this same method.
      HapticFeedback.selectionClick();
      widget.onTap(index);
    }
  }

  void _endTouch() => setState(() => _touchX = null);

  @override
  Widget build(BuildContext context) {
    // 2026-07-26 (Founder: "when not touched it becomes more
    // transparent, when touched less transparent") — the bar's own
    // glass fill now reacts to touch state, not just the highlight
    // badge. `dragging` is hoisted up here (previously computed inside
    // LayoutBuilder's builder) since the container's decoration needs
    // it too, and it never actually depended on `constraints` anyway.
    final dragging = _touchX != null;
    // FIXED 2026-07-26 (Founder screenshot: "when it's smaller the blob
    // is out of place now so that needs to be fixed to match new size
    // also"). The highlight's size and vertical centring were still
    // hardcoded against the constant `_barHeight`/`_highlightSize` —
    // correct for the full (touched) size, but wrong the moment the bar
    // itself started shrinking when idle (added this same session).
    // These mirror the exact height expression the AnimatedContainer
    // below uses, so the badge always matches whatever size the bar
    // actually is right now, not just its full-size resting state.
    final currentBarHeight = dragging ? _barHeight : _barHeight * 0.86;
    final currentHighlightSize = dragging ? _highlightSize : _highlightSize * 0.86;
    return Positioned(
      left: 24,
      right: 24,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14),
        // 2026-07-26 (Founder, repeated across several passes: "the
        // navigation bar (NOT ICONS) — bar smaller when it's not
        // clicked"). Every earlier pass only changed the ICONS' scale
        // or the bar's opacity — never the bar's own footprint. This
        // AnimatedPadding shrinks the whole glass unit's WIDTH —
        // wrapping the ClipRRect so the blur/fill/border all shrink
        // together, not just the content inside them (doing this only
        // on the inner Container would leave a mismatched blurred
        // rectangle showing around a smaller pill). Height shrinks via
        // the AnimatedContainer below, same `dragging` flag. `dragging`
        // is true for the whole press (tap or drag), not just an
        // active drag — touch to expand to full size, release to
        // shrink back, matching "smaller when not clicked."
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: dragging ? 0 : 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: currentBarHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: dragging ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: dragging ? 0.30 : 0.18), width: 1),
                ),
                child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  // FIXED 2026-08-01 (Founder: "the blob is closer to the
                  // bottom then the top... the magnifier glass doesnt seem to
                  // be dead in middle"). This is real, not perception —
                  // measured off the Founder's own screenshots at 3x: 15
                  // physical px of gap above the badge against 9 below.
                  //
                  // ROOT CAUSE: `currentBarHeight` is the AnimatedContainer's
                  // OUTER height, but this Stack sits INSIDE that container's
                  // 1px border. A BoxDecoration border insets the child —
                  // Container wraps it in Padding(decoration.padding), which
                  // for Border.all(width: 1) is EdgeInsets.all(1) — so the
                  // Stack is 2px shorter than `currentBarHeight`. Centring the
                  // badge against the outer height therefore parked it exactly
                  // 1 logical px (3 physical px at 3x) below true centre.
                  //
                  // NOT the two bar sizes, which was the standing hypothesis:
                  // the error is a constant 1px in BOTH the idle and touched
                  // states, because the border is 1px in both. Note the icon
                  // Row was never wrong — it's a non-Positioned child of a
                  // centre-aligned Stack, so it centres against the real inner
                  // height. That mismatch is exactly why the badge and the
                  // glyph inside it disagreed with each other.
                  //
                  // constraints.maxHeight IS this Stack's real height, so the
                  // fix also survives any future border/padding change, and it
                  // tracks the container's ANIMATED height through the 220ms
                  // resize rather than snapping to the target value — the
                  // badge now stays centred during the transition, not just at
                  // each end of it.
                  final innerHeight = constraints.maxHeight;
                  final highlightTop = (innerHeight - currentHighlightSize) / 2;
                  final cellWidth = barWidth / widget.items.length;
                  final highlightLeft = dragging
                      ? (_touchX! - currentHighlightSize / 2).clamp(0.0, barWidth - currentHighlightSize)
                      : cellWidth * widget.currentIndex + (cellWidth - currentHighlightSize) / 2;
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
                      // FIXED 2026-07-26 (root cause identified in
                      // CHATGPT_REPLY_NAVBAR_PHOTO_MENU_2026-07-26.md §1
                      // — this one line was the entire "icon sits too
                      // high" / "circle feels like it's sitting on top
                      // of the bar rather than belonging to it" bug).
                      // Stack's default alignment is topStart. The
                      // highlight circle below is wrapped in its own
                      // Positioned/AnimatedPositioned so it was already
                      // correctly centred — but the icon+label Row is a
                      // plain (non-Positioned) Stack child, so without
                      // this line it fell back to topStart and pinned
                      // to the top of the 62px bar instead of sitting in
                      // the middle with the (correctly centred) circle
                      // behind it. The two symptoms were one bug.
                      alignment: Alignment.center,
                      children: [
                        // The sliding highlight — Lovable-style single blob,
                        // not a per-item background. Follows the finger
                        // directly (no easing) while actively touching;
                        // eases to the settled tab centre otherwise.
                        dragging
                            ? Positioned(
                                left: highlightLeft,
                                top: highlightTop,
                                child: _Highlight(size: currentHighlightSize),
                              )
                            : AnimatedPositioned(
                                // FIXED 2026-07-26 (Founder reference videos —
                                // "gets smaller when user clicks off it" /
                                // shrink transition should feel smooth, not
                                // mechanical). easeOutCubic arrives and stops
                                // dead on time; easeOutBack overshoots very
                                // slightly past the target then settles,
                                // which is what a spring-driven native tab
                                // bar actually does. Slowed 260ms→320ms to
                                // give that overshoot room to read instead
                                // of feeling rushed.
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutBack,
                                left: highlightLeft,
                                top: highlightTop,
                                child: _Highlight(size: currentHighlightSize),
                              ),
                        Row(
                          children: List.generate(widget.items.length, (i) {
                            final selected = i == liveIndex;
                            final item = widget.items[i];
                            final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.45);
                            // REVISED 2026-07-26 (Founder, after testing
                            // the previous tuning on-device: "still not
                            // showing... I want the WHOLE navigation tab
                            // to shrink. It's as simple as that"). The
                            // prior pass deliberately held inactive icons
                            // at normal size and only grew the active
                            // one — a correct read of the brief at the
                            // time, but too subtle to register on a real
                            // screen. This flips the baseline: the
                            // SELECTED icon sits at normal size (1.0) and
                            // every unselected icon visibly shrinks
                            // (0.78) — matching the Instagram reference
                            // videos, where inactive icons read as
                            // distinctly smaller, not just "not bigger."
                            final icon = AnimatedScale(
                              scale: selected ? 1.0 : 0.78,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutBack,
                              child: Icon(item.icon, color: color, size: 22),
                            );
                            return Expanded(
                              child: IgnorePointer(
                                // Touch handling now lives on the bar-wide
                                // GestureDetector above so a press/drag
                                // anywhere on the bar is tracked as one
                                // continuous gesture — individual cells no
                                // longer need (or intercept) their own taps.
                                //
                                // FIXED 2026-07-26 (Founder: blob looks
                                // "unprofessional" — icon sits with more
                                // space below it than above, inside the
                                // highlight). `Center` here guarantees
                                // true geometric centring regardless of
                                // any Column min-size quirk — the
                                // showLabels branch below still needs the
                                // Column (two children to stack
                                // vertically), but the far more common
                                // icon-only case no longer goes through it
                                // at all. If the badge still looks
                                // off-centre after this on a specific
                                // icon (e.g. a shield glyph), that's the
                                // glyph's own optical weight, not layout —
                                // see the Guardian icon swap note in
                                // home_shell.dart from this same pass.
                                child: widget.showLabels
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          icon,
                                          const SizedBox(height: 2),
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 220),
                                            style: ZyraText.subtext(size: 10, color: color),
                                            child: Text(item.label),
                                          ),
                                        ],
                                      )
                                    : Center(child: icon),
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
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  final double size;
  const _Highlight({required this.size});

  @override
  Widget build(BuildContext context) {
    // TUNED 2026-07-26 against the Lovable reference video: that badge
    // reads as a clearly-visible solid fill, not a thin outlined ring —
    // fill raised 0.20→0.28, border softened 0.28→0.12 (a faint edge for
    // definition against the bar's own blur, not a crisp outline that
    // competes with the fill for attention).
    //
    // AnimatedContainer (was plain Container) as of the same pass that
    // made `size` itself vary with idle/touched state — without this,
    // toggling `dragging` would snap the badge to its new size instead
    // of resizing smoothly alongside the bar's own 220ms transition.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
    );
  }
}
