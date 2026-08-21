// ZYRA loading indicator — what a user sees in a GAP.
//
// NEW 2026-08-08. Founder: "the gaps when the app is loading… I'm thinking
// either the word ZYRA jumping like it's loading, or just the purple
// background with 4 dots moving left to right."
//
// ── THIS IS NOT THE SPLASH, and the distinction is the whole point.
//
//   SPLASH   plays once at cold start, owns the screen for a fixed 3s, and
//            is a statement. It has its own orbs-and-letters sequence.
//   LOADING  appears only when there is real waiting, for an unknown
//            length of time, and should be forgettable.
//
// Using the splash for a gap is what produced the bug this file was written
// alongside: picking a test account played the full four-second brand
// animation every time. A gap needs something that can appear for 80ms or
// 8 seconds and be right either way.
//
// ── CHANGING THE STYLE IS ONE WORD. [kZyraLoadingStyle] below. All four
// options were built so the choice could be made by looking at them rather
// than by describing them.
//
// ── REPLACED CircularProgressIndicator across the app, 2026-08-08.
// A Material spinner in a bespoke brand is the visual equivalent of a
// default ringtone. 28 of the 38 occurrences are now this widget: the 22
// full-area `Center(child: CircularProgressIndicator())` states, plus the
// six "Waiting for <name>" indicators in journey_flow_screen, which turned
// out to be the most important ones — those are literally the gap the
// Founder was describing.
//
// ── THE TEN THAT REMAIN ARE CORRECT AS THEY ARE, and should stay:
// 14-20px spinners inside buttons, image placeholders and sheets
// (welcome, feedback, app_lock, chapter2, profile_ready,
// zyra_profile_image, report_profile_sheet, and two Guardian buttons).
// The dot track is 106x10; it does not belong in a 16x16 slot, and a
// button that is working is not the same event as a screen that is
// waiting. Do not "finish the job" by migrating those.

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_comet_rule.dart';
import 'zyra_meet_and_pass_rule.dart';

/// How far the [ZyraLoadingStyle.slidingDots] dots travel, in logical
/// pixels. File-level rather than declared inside the switch case: a local
/// in one `case` is scoped to the whole switch block in Dart, which is a
/// collision waiting for the second case that wants a `track`.
const double _track = 96.0;

/// The comet loop's rule width. Matches the footprint the four dots had,
/// so swapping the default does not change any screen's layout.
const double _railWidth = 118.0;

/// The historical comet loop's sweep, as a fraction of its controller — ONE curve,
/// matching the splash's Pass-through fix (2026-08-12; Founder: "you
/// changed it for splash but not loading"). The old staged
/// travel-then-fade had the same frame-measured stall the splash had:
/// every cycle the lights decelerated to a visible dead stop at the
/// centre before vanishing. Now each cycle is one unbroken crossing —
/// enter, meet at speed, carry through, fade while leaving — with the
/// rail alone for the last ~12% as a breath before the next pass. The
/// loop boundary is invisible by construction: a cycle ends with the
/// stage empty, which is exactly how the next one begins.
const Interval _journeySweep = Interval(0.0, 0.88, curve: Curves.easeInOutSine);

enum ZyraLoadingStyle {
  /// CURRENT — Founder-selected 2026-08-20 to match the new Trails Meet
  /// splash language. Two gold dots meet, continue through one another,
  /// fade beyond the connection, then re-enter invisibly on the next loop.
  meetAndPass,

  /// THE SPLASH RULE, ON A LOOP. Two lights run in along a hairline,
  /// overlap briefly at the centre, fade, and go again.
  ///
  /// Chosen 2026-08-09. The point is continuity: the splash ends on this
  /// exact gesture played once, so a gap in the app looks like it belongs
  /// to the same product as the launch rather than to Material.
  cometLoop,

  /// Four dots hold position; the bright one travels left to right.
  /// Superseded by [cometLoop] but kept — the Founder changed his mind
  /// once already between these two, and the implementation is four lines.
  travellingDots,

  /// Four dots physically cross the space and loop. The previous default.
  slidingDots,
}

// bounceWordmark and sweepWordmark were REMOVED 2026-08-09, not kept as
// options. Both drew the ZYRA wordmark, and the wordmark now belongs to
// the splash — a loading state that renders the brand name competes with
// the screen whose whole job is to render the brand name. Neither was ever
// chosen. Their code is in git if anyone wants it back.

/// THE ONE KNOB. Change this and every loading state in the app follows.
///
/// CHOSEN 2026-08-20 — [ZyraLoadingStyle.meetAndPass], after the splash
/// moved to the gold-dot Trails Meet design. The animation family stays
/// consistent without making a repeating wait pretend to be a one-time
/// arrival.
///
/// Was slidingDots for a few hours on 2026-08-08, after the Founder picked
/// "idea 2, the four dots". The splash then moved from orbs to a comet
/// rule, and loading followed it so the two screens speak one language.
const ZyraLoadingStyle kZyraLoadingStyle = ZyraLoadingStyle.meetAndPass;

class ZyraLoading extends StatefulWidget {
  /// Overrides [kZyraLoadingStyle] for one call site. Leave null.
  final ZyraLoadingStyle? style;

  /// Paints the brand gradient behind the indicator and fills the screen.
  /// False (the default) draws the indicator alone, for use inside a card,
  /// a list, or a button.
  final bool fullScreen;

  /// Optional line under the indicator. Use it only when the wait has a
  /// reason worth naming ("Checking your invite…"); silence beats filler.
  final String? label;

  const ZyraLoading({super.key, this.style, this.label}) : fullScreen = false;

  const ZyraLoading.fullScreen({super.key, this.style, this.label})
    : fullScreen = true;

  @override
  State<ZyraLoading> createState() => _ZyraLoadingState();
}

class _ZyraLoadingState extends State<ZyraLoading>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  AnimationController get _c => _controller ??= AnimationController(
    vsync: this,
    // Matches the measured preview for Meet and Pass. The former 1400ms
    // comet cycle was intentionally busier; the gold-dot language needs a
    // calmer pace so the meeting remains legible on small inline loaders.
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    // Reduced-motion builds never request the controller. Do not create an
    // animation solely in order to dispose it during unmount.
    _controller?.dispose();
    super.dispose();
  }

  /// Where dot/letter [i] sits in the loop, 0..1, wrapped.
  ///
  /// Wrapped rather than an [Interval], because an Interval clamps at both
  /// ends — the stagger has to survive crossing the loop boundary or the
  /// wave visibly restarts instead of continuing.
  double _phase(int i, double stagger) {
    final t = (_c.value - i * stagger) % 1.0;
    return t < 0 ? t + 1 : t;
  }

  /// A single smooth peak at [at], zero elsewhere. 0..1.
  double _peak(double t, {double at = 0.30, double width = 0.30}) {
    final d = (t - at).abs();
    if (d >= width) return 0;
    return Curves.easeInOut.transform(1 - d / width);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? kZyraLoadingStyle;

    // ACCESSIBILITY. Flutter's equivalent of prefers-reduced-motion. The
    // shape stays and the motion stops — a static indicator still says
    // "waiting", which a blank screen does not.
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final Widget indicator = still
        ? _StillFallback(style: style)
        : AnimatedBuilder(
            animation: _c,
            builder: (context, _) => _build(style),
          );

    final Widget content = widget.label == null
        ? indicator
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              indicator,
              const SizedBox(height: 18),
              Text(
                widget.label!,
                textAlign: TextAlign.center,
                style: ZyraText.subtext(color: Colors.white70),
              ),
            ],
          );

    if (!widget.fullScreen) return Center(child: content);

    return DecoratedBox(
      // GENDER-MATCHED — Founder, 2026-08-08: "if the app is in purple it
      // should be purple with 4 dots, if it's a female account should be
      // pink/purple 4 dots, and if it's male it should be blue/purple with
      // 4 dots."
      //
      // ── THIS IS THE OPPOSITE RULE TO THE SPLASH, AND DELIBERATELY SO.
      //
      //   SPLASH   brand purple always. It is the brand introducing
      //            itself, before the app knows or should care who is
      //            holding the phone (DR-ZYRA-125).
      //   LOADING  matches whatever it is interrupting. It appears INSIDE
      //            a session, over a background that is already the
      //            member's colour — so painting brand purple here drops a
      //            purple panel over a pink app, which is the same flash
      //            the splash rule exists to avoid, arriving from the
      //            other direction.
      //
      // genderGradient() gives all three of the Founder's cases from one
      // call: null gender (signed out, cold start, first launch) returns
      // the neutral brand purple, and the two known genders return their
      // own. No branching needed here.
      decoration: BoxDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: Center(child: content),
    );
  }

  Widget _build(ZyraLoadingStyle style) {
    switch (style) {
      case ZyraLoadingStyle.meetAndPass:
        return ZyraMeetAndPassRule(
          width: _railWidth,
          progress: Curves.easeInOutSine.transform(_c.value),
        );

      case ZyraLoadingStyle.cometLoop:
        // The splash's own gesture, looped — same widget, same continuous
        // Pass-through motion (see _journeySweep), so the launch and the
        // gaps speak one language and can never drift apart.
        //
        // clip: true — inline in a card this box is ~118px, and the sweep
        // deliberately runs from outside one edge to outside the other.
        return ZyraCometRule(
          width: _railWidth,
          travel: 0,
          ending: ZyraSplashEnding.passThrough,
          journey: _journeySweep.transform(_c.value),
          clip: true,
        );

      case ZyraLoadingStyle.travellingDots:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final p = _peak(_phase(i, 0.09));
            return Padding(
              padding: EdgeInsets.only(right: i == 3 ? 0 : 10),
              child: Transform.scale(
                scale: 1 + 0.42 * p,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Lerp, not two colours — the dot never "switches",
                    // it brightens.
                    color:
                        Color.lerp(Colors.white24, Colors.white, p) ??
                        Colors.white24,
                  ),
                ),
              ),
            );
          }),
        );

      case ZyraLoadingStyle.slidingDots:
        return SizedBox(
          width: _track + 10,
          height: 10,
          child: Stack(
            children: List.generate(4, (i) {
              final t = _phase(i, 0.08);
              // Fade in over the first 14% and out over the last 18%, so
              // dots enter and leave rather than popping at the edges.
              final o = t < 0.14 ? t / 0.14 : (t > 0.82 ? (1 - t) / 0.18 : 1.0);
              return Positioned(
                left: Curves.easeInOut.transform(t) * _track,
                top: 0,
                child: Opacity(
                  opacity: o.clamp(0.0, 1.0) * 0.92,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
    }
  }
}

/// What reduced-motion users see. Deliberately not nothing.
class _StillFallback extends StatelessWidget {
  final ZyraLoadingStyle style;
  const _StillFallback({required this.style});

  @override
  Widget build(BuildContext context) {
    if (style == ZyraLoadingStyle.meetAndPass) {
      // A completed connection, held still: the accessible alternative
      // communicates waiting without repeatedly separating the dots.
      return const ZyraMeetAndPassRule(width: _railWidth, progress: 0.44);
    }
    if (style == ZyraLoadingStyle.cometLoop) {
      // The finished frame: both comets arrived and overlapping. Static,
      // but it is the composition rather than an arbitrary pose.
      return const ZyraCometRule(width: _railWidth, travel: 1, clip: true);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        4,
        (i) => Padding(
          padding: EdgeInsets.only(right: i == 3 ? 0 : 10),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}
