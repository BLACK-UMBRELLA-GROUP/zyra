// The comet rule — two lights running toward each other along a hairline.
//
// ONE implementation, used by TWO screens, deliberately:
//
//   SPLASH   plays it once. The lights arrive, overlap, and fade, leaving
//            the rail under the wordmark for the still second at the end.
//   LOADING  plays it on a loop. Same gesture, repeating, because the app
//            is waiting rather than arriving.
//
// Extracted from splash_screen.dart on 2026-08-09 the moment the second
// caller appeared. This codebase has already paid for the alternative
// today: four private copies of the same age-fetching method meant one
// bug in four places and no guarantee a fix reached all of them (I3, "one
// path, or the paths will drift"). A second copy of an animation is the
// same trade with a prettier surface.
//
// ── WHAT REPLACED THE ORBS, AND WHY. Founder, 2026-08-08: "I just don't
// like the purple ball the pink and blue creates in end." Two soft discs
// meeting concentrically make a large area of a colour nobody chose —
// screen(#D4868F, #3D5A80) over the mid-gradient lands on ~#EBC7E1, a pale
// lilac. The merge was never the problem; the surface area was. Two lines
// meeting make the same colour across a few pixels.
//
// ── WHY BlendMode.screen. royalBlue (#3D5A80) is DARKER than the purple
// it sits on (~#644A74 mid-screen). Painted normally it is a muddy smear;
// screened it lifts to a light periwinkle and reads as light rather than
// ink. Measured, not guessed.
//
// RepaintBoundary is required, not decorative: backgroundBlendMode
// composites against whatever is already painted in the current layer, so
// each comet needs a layer to blend into.

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';

class ZyraCometRule extends StatelessWidget {
  /// Total width of the rule in logical pixels.
  final double width;

  /// 0 = both comets off-stage, 1 = arrived and overlapping.
  final double travel;

  /// 0 = comets at full strength, 1 = fully gone. The rail is unaffected —
  /// on the splash it is what survives into the hold.
  final double fade;

  /// The faint rail's own fade-in, so it is established before anything
  /// travels along it. Pass 1 to have it simply present.
  final double railOpacity;

  final double thickness;

  /// Clip the comets to the rule's own width.
  ///
  /// FALSE on the splash: at travel 0 each comet sits a full half-rule
  /// outside the box, and letting it slide in from off-screen is the
  /// entrance. The screen edge does the clipping.
  ///
  /// TRUE for the looping loading indicator, which may be 118px wide
  /// inside a card — unclipped, its comets would paint 59px into whatever
  /// is beside them.
  final bool clip;

  /// How far past centre each comet pushes, as a fraction of a half-rule.
  ///
  /// THIS IS THE MERGE. Each comet is exactly half the rule, so at 0 they
  /// would meet edge to edge and never touch — two colours arriving and
  /// stopping. At 0.09 the two bright ends overlap and produce the
  /// pink-blue mix across roughly 20 logical pixels, which is the whole
  /// point of the image and about a hundredth of the area the orbs used.
  final double overshoot;

  const ZyraCometRule({
    super.key,
    required this.width,
    required this.travel,
    this.fade = 0,
    this.railOpacity = 1,
    this.thickness = 2,
    this.overshoot = 0.09,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final half = width / 2;
    final t = travel.clamp(0.0, 1.0);
    final alpha = (1 - fade).clamp(0.0, 1.0);

    // Both comets are Positioned at left:0, so dx is measured from the
    // LEFT edge of the rule for both of them — which is why the two
    // expressions are not mirror images of each other.
    //
    //   rose  starts at -half   (entirely off the left edge)
    //         ends   at +overshoot*half   (right edge just past centre)
    //   blue  starts at  width  (entirely off the right edge)
    //         ends   at  half - overshoot*half  (left edge just past centre)
    //
    // Blue's start is `width`, NOT `half`. Written as `half` first time
    // through, which put it in its final resting place at t = 0 — it never
    // travelled, it just faded up already arrived. Spelled out here so it
    // does not have to be re-derived.
    final reach = half + overshoot * half;
    final roseDx = -half + t * reach;
    final blueDx = width - t * reach;

    return SizedBox(
      width: width,
      height: thickness,
      child: Stack(
        clipBehavior: clip ? Clip.hardEdge : Clip.none,
        children: [
          Opacity(
            opacity: railOpacity.clamp(0.0, 1.0) * 0.14,
            child: Align(
              alignment: Alignment.center,
              child: Container(width: width, height: 1, color: Colors.white),
            ),
          ),
          // Positioned lives HERE, not inside _Comet. A StatelessWidget
          // that returns a Positioned does work — the framework skips
          // component elements when looking for the Stack — but it breaks
          // the moment anyone wraps _Comet in anything owning a render
          // object, and the failure is a runtime "Incorrect use of
          // ParentDataWidget", not a compile error.
          Positioned(
            left: 0,
            top: 0,
            child: _Comet(
              colour: ZyraColors.rosePink, // female palette
              width: half,
              thickness: thickness,
              dx: roseDx,
              opacity: alpha,
              brightEnd: _BrightEnd.right,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _Comet(
              colour: ZyraColors.royalBlue, // male palette
              width: half,
              thickness: thickness,
              dx: blueDx,
              opacity: alpha,
              brightEnd: _BrightEnd.left,
            ),
          ),
        ],
      ),
    );
  }
}

/// Which end of a comet carries the colour. Always the end facing centre —
/// the two bright ends are what meet.
///
/// An enum rather than an [Alignment], because comparing Alignments to pick
/// a gradient direction reads as geometry when it is really a two-state
/// choice, and it invites someone to pass topLeft.
enum _BrightEnd { left, right }

/// One half of the rule: a tail fading to nothing at the outer end and full
/// colour at the inner one.
class _Comet extends StatelessWidget {
  final Color colour;
  final double width;
  final double thickness;
  final double dx;
  final double opacity;
  final _BrightEnd brightEnd;

  const _Comet({
    required this.colour,
    required this.width,
    required this.thickness,
    required this.dx,
    required this.opacity,
    required this.brightEnd,
  });

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: Offset(dx, 0),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: RepaintBoundary(
            child: Container(
              width: width,
              height: thickness,
              decoration: BoxDecoration(
                backgroundBlendMode: BlendMode.screen,
                borderRadius: BorderRadius.circular(thickness),
                gradient: LinearGradient(
                  begin: brightEnd == _BrightEnd.right
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  end: brightEnd == _BrightEnd.right
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  colors: [colour.withValues(alpha: 0.0), colour],
                ),
              ),
            ),
          ),
        ),
      );
}
