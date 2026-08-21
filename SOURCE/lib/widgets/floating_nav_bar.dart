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
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// THE BAR'S GEOMETRY, in one place — DR-ZYRA-155, 2026-08-13.
///
/// Browse's action bar has to be the SAME BAR with different contents
/// (Founder: "the navigation bar should feel like it transforms, not
/// gets replaced... keep the exact same height, size, position, spacing,
/// visual weight"). Two widgets holding two copies of 24/28/58/0.86
/// would drift the first time one of them is tuned — which is precisely
/// how the action bar ended up visibly smaller than the bar it replaced
/// in the first place.
///
/// These are the IDLE values. The nav bar grows to [height] mid-drag;
/// nothing else does.
class ZyraNavBarMetrics {
  ZyraNavBarMetrics._();

  /// Inset from each screen edge.
  static const double sideInset = 24;

  /// Bottom inset applied inside SafeArea.
  static const double bottomInset = 14;

  /// Full height, reached while dragging.
  static const double height = 58;

  /// Resting height — what the bar is whenever nobody is touching it,
  /// and therefore what anything replacing it must match.
  static const double restingHeight = height * 0.86;

  static const double radius = 28;
  static const double blurSigma = 22;

  /// Idle glass, and what a touch lifts it to.
  ///
  /// THE BAR BREATHES ON TOUCH, and that turned out to be the missing
  /// half of "it doesn't feel like the same component" (Founder,
  /// 2026-08-13): the nav bar grows wider, taller and brighter under a
  /// finger and settles back when released. Anything claiming to BE
  /// this bar has to do the same, or it reads as a still photograph of
  /// it. All six values below move together on the same flag.
  static const double fill = 0.10;
  static const double fillTouched = 0.20;
  static const double borderAlpha = 0.18;
  static const double borderAlphaTouched = 0.30;

  /// Horizontal inset applied to the WHOLE glass unit at rest — the bar
  /// is narrower when nobody is touching it, and grows to 0 on touch.
  static const double restingSideSqueeze = 10;

  /// The moving circle behind the active icon.
  static const double highlightSize = 46;
  static const double restingHighlightSize = highlightSize * 0.86;

  /// Glyph size inside the bar.
  static const double iconSize = 22;

  /// Icon colours — full white when active, dimmed when not.
  static const double iconAlphaInactive = 0.45;

  /// How long the bar takes to grow or settle.
  static const Duration breath = Duration(milliseconds: 220);
}

/// The moving circle behind the active icon.
///
/// PUBLIC since 2026-08-13 (DR-ZYRA-156) so Browse's action bar draws
/// THE highlight rather than a lookalike. It was `_Highlight`; nothing
/// about it changed in the move.
///
/// TUNED 2026-07-26 against the Lovable reference video: that badge
/// reads as a clearly-visible solid fill, not a thin outlined ring —
/// fill raised 0.20→0.28, border softened 0.28→0.12 (a faint edge for
/// definition against the bar's own blur, not a crisp outline that
/// competes with the fill for attention).
///
/// AnimatedContainer (was plain Container) as of the same pass that
/// made `size` itself vary with idle/touched state — without this,
/// toggling `dragging` would snap the badge to its new size instead
/// of resizing smoothly alongside the bar's own 220ms transition.
class ZyraNavHighlight extends StatelessWidget {
  final double size;
  const ZyraNavHighlight({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: ZyraNavBarMetrics.breath,
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final String label;

  /// Unread count rendered as a small dot on the icon's shoulder —
  /// ADDED 2026-08-13 (DR-ZYRA-149) when Notifications became a tab and
  /// the Bell's badge had to survive the move. 0 renders nothing.
  final int badge;

  /// A plain dot with NO NUMBER — "there is something here", nothing
  /// more.
  ///
  /// ADDED 2026-08-13 (DR-ZYRA-154). Counts and dots answer different
  /// questions and the app already knew that: the Connections segment
  /// badges were changed from numbers to a bare dot on 2026-08-06 —
  /// "the heading already says how many; the dot only has to answer
  /// whether there is anything." A navigation indicator is that same
  /// question one level up. Notifications keeps its COUNT because it is
  /// an inbox and the size of the pile is the useful fact; Connections
  /// and Guardian get a DOT because "3 things happened over there"
  /// changes nothing about whether you go and look.
  ///
  /// [badge] wins if both are set — a real count is strictly more
  /// information than a dot, so silently showing less would be the
  /// wrong way to resolve it.
  final bool dot;

  const FloatingNavItem({
    required this.icon,
    required this.label,
    this.badge = 0,
    this.dot = false,
  });
}

class FloatingNavBar extends StatefulWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;

  /// When false (tabs), [onTap] fires the MOMENT a scrub crosses into a
  /// new cell — that is the scrubbing feel, and switching tab as your
  /// finger passes over it is the whole point of it.
  ///
  /// When true, a scrub only moves the highlight and [onTap] fires ONCE,
  /// on release, for the cell under the finger.
  ///
  /// ADDED 2026-08-13 (DR-ZYRA-161) because Browse's action bar is this
  /// widget now, and for ACTIONS the live-fire behaviour is a bug rather
  /// than a feel: sliding left to right ran Hide Profile as the finger
  /// passed over it, before it had been lifted. A tab change is
  /// reversible by scrubbing onward; an action is not.
  final bool commitOnRelease;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = false,
    this.commitOnRelease = false,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  // Slimmer than before (62) now the bar is icon-only — matches the
  // Lovable reference video's proportions once the label row is gone.
  static const double _barHeight = ZyraNavBarMetrics.height;
  // Bigger relative to the icon than before (44) — the reference
  // video's badge clearly reads as larger than the icon's own tap
  // target, not a tight halo around it.
  static const double _highlightSize = ZyraNavBarMetrics.highlightSize;

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
    _lastIndex = index;
    if (index != widget.currentIndex) {
      // 2026-07-26 (nav bar refinement pass — CHATGPT_REPLY_NAVBAR_
      // PHOTO_MENU_2026-07-26.md §1): a small, cheap "premium app"
      // detail that was simply missing — every native tab bar (iOS
      // Control Center, Instagram, Flutter's own Switch/Radio) gives a
      // light tap on selection change. Fires on crossing into a new
      // cell during a drag-scrub too, not just a discrete tap, since
      // both paths call this same method.
      HapticFeedback.selectionClick();
      // The haptic still fires on every crossing — feeling the cells go
      // by is the feedback that makes a scrub legible. Only the ACTION
      // waits (see [commitOnRelease]).
      if (!widget.commitOnRelease) widget.onTap(index);
    }
  }

  /// [commit] is true for a release, false for a cancel.
  ///
  /// Cancels must never fire: a gesture the arena took away from this
  /// widget, or one interrupted by a route change, is not a choice. Only
  /// matters when [commitOnRelease] is set — otherwise onTap has already
  /// fired live and there is nothing left to do here.
  void _endTouch({bool commit = false}) {
    final x = _touchX;
    setState(() => _touchX = null);
    if (!widget.commitOnRelease || !commit || x == null) return;
    // barWidth is not in scope here, and does not need to be: the index
    // was resolved on the last move, so recompute from the same clamped
    // x against the width the layout last reported.
    final index = _lastIndex;
    if (index != null) widget.onTap(index);
  }

  /// The cell the finger was last over. Written by [_handleTouchAt] so
  /// [_endTouch] does not need the bar's width to resolve it again.
  int? _lastIndex;

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
    final currentBarHeight = dragging
        ? _barHeight
        : ZyraNavBarMetrics.restingHeight;
    final currentHighlightSize = dragging
        ? _highlightSize
        : ZyraNavBarMetrics.restingHighlightSize;
    return Positioned(
      left: ZyraNavBarMetrics.sideInset,
      right: ZyraNavBarMetrics.sideInset,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: ZyraNavBarMetrics.bottomInset),
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
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: dragging ? 0.30 : 0.18,
                    ),
                    width: 1,
                  ),
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
                    final highlightTop =
                        (innerHeight - currentHighlightSize) / 2;
                    final cellWidth = barWidth / widget.items.length;
                    final highlightLeft = dragging
                        ? (_touchX! - currentHighlightSize / 2).clamp(
                            0.0,
                            barWidth - currentHighlightSize,
                          )
                        : cellWidth * widget.currentIndex +
                              (cellWidth - currentHighlightSize) / 2;
                    final liveIndex = dragging
                        ? _indexForX(_touchX!, barWidth)
                        : widget.currentIndex;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) =>
                          _handleTouchAt(d.localPosition.dx, barWidth),
                      onTapUp: (_) => _endTouch(commit: true),
                      onTapCancel: _endTouch,
                      onHorizontalDragStart: (d) =>
                          _handleTouchAt(d.localPosition.dx, barWidth),
                      onHorizontalDragUpdate: (d) =>
                          _handleTouchAt(d.localPosition.dx, barWidth),
                      onHorizontalDragEnd: (_) => _endTouch(commit: true),
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
                                  child: ZyraNavHighlight(
                                    size: currentHighlightSize,
                                  ),
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
                                  child: ZyraNavHighlight(
                                    size: currentHighlightSize,
                                  ),
                                ),
                          Row(
                            children: List.generate(widget.items.length, (i) {
                              final selected = i == liveIndex;
                              final item = widget.items[i];
                              final color = selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45);
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
                              final icon = Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedScale(
                                    scale: selected ? 1.0 : 0.78,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      item.icon,
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  // The badge sits OUTSIDE the scale so an
                                  // unselected tab's count doesn't shrink
                                  // with its icon (DR-ZYRA-149).
                                  // The bare dot — same shoulder, same
                                  // colour, no number. Sized to the
                                  // numbered badge's minWidth so the two
                                  // sit on the same optical line when a
                                  // bar carries one of each.
                                  if (item.badge == 0 && item.dot)
                                    const Positioned(
                                      top: -2,
                                      right: -3,
                                      child: SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: Center(
                                          child: SizedBox(
                                            width: 7,
                                            height: 7,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: ZyraColors.unlockDot,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (item.badge > 0)
                                    Positioned(
                                      top: -5,
                                      right: -7,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 15,
                                          minHeight: 15,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: ZyraColors.unlockDot,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          item.badge > 9
                                              ? '9+'
                                              : '${item.badge}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: ZyraColors.luxuryDarkPurple,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            icon,
                                            const SizedBox(height: 2),
                                            AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              style: ZyraText.subtext(
                                                size: 10,
                                                color: color,
                                              ),
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

// _Highlight became the public ZyraNavHighlight, above (DR-ZYRA-156).
