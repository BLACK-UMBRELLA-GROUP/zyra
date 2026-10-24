// ZYRA loading indicator — what a user sees in a GAP.
//
// NEW 2026-08-08. Founder: "the gaps when the app is loading… I'm thinking
// either the word ZYRA jumping like it's loading, or just the purple
// background with 4 dots moving left to right."
//
// ── THIS IS NOT THE SPLASH, and the distinction is the whole point.
//
//   SPLASH   plays once at cold start, owns the screen for a fixed 3s, and
//            is a statement. It has its own bloom/draw-and-letters sequence.
//   LOADING  appears only when there is real waiting, for an unknown
//            length of time, and should be forgettable.
//
// Using the splash for a gap is what produced the bug this file was written
// alongside: picking a test account played the full four-second brand
// animation every time. A gap needs something that can appear for 80ms or
// 8 seconds and be right either way.
//
// ── SHARED WAITING PRESENTATIONS. Comet line remains the compact default
// selected on 2026-08-29. Founder direction, 2026-10-20: remove the branded
// full-screen loading presentation entirely. Every full-screen caller now
// gets the same quiet, opaque wait, even if it supplies a compact style.
// A short wait has no artwork or status flash; longer work earns only the
// existing delayed stationary feedback. This is not an access grant.
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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

/// One approved accent for every shared loading study.
///
/// Keeping this public-for-tests prevents a legacy option or its accessible
/// still frame quietly drifting back to white/purple while the newer painters
/// remain gold. The splash wordmark is deliberately not part of this system.
@visibleForTesting
const Color kZyraLoadingAccent = ZyraColors.journeyGold;

/// The historical comet loop's sweep, as a fraction of its controller — ONE
/// curve, originally matching the former splash's Pass-through fix
/// (2026-08-12; Founder: "you changed it for splash but not loading"). The old staged
/// travel-then-fade had the same frame-measured stall the splash had:
/// every cycle the lights decelerated to a visible dead stop at the
/// centre before vanishing. Now each cycle is one unbroken crossing —
/// enter, meet at speed, carry through, fade while leaving — with the
/// rail alone for the last ~12% as a breath before the next pass. The
/// loop boundary is invisible by construction: a cycle ends with the
/// stage empty, which is exactly how the next one begins.
const Interval _journeySweep = Interval(0.0, 0.88, curve: Curves.easeInOutSine);

enum ZyraLoadingStyle {
  /// FORMER selection. Two gold dots meet, continue
  /// through one another, fade beyond the connection, then re-enter
  /// invisibly on the next loop. The splash moved to dot-free Bloom + Draw
  /// on 2026-08-26; loading remains intentionally separate and repeatable.
  meetAndPass,

  /// THE FORMER SPLASH RULE, ON A LOOP. Two lights run along a hairline,
  /// overlap briefly at the centre, fade, and go again.
  ///
  /// CURRENT — Founder-selected 2026-08-29. The current splash remains a
  /// separate one-time brand arrival; this is the repeatable waiting motion.
  cometLoop,

  /// Four dots hold position; the bright one travels left to right.
  /// Superseded by [cometLoop] but kept — the Founder changed his mind
  /// once already between these two, and the implementation is four lines.
  travellingDots,

  /// Four dots physically cross the space and loop. The previous default.
  slidingDots,

  /// A quiet point of gold light expands and settles at the centre.
  softBloom,

  /// A fine gold horizon draws outwards from the centre and releases.
  centreDraw,

  /// The centre bloom arrives first, then resolves into a drawn horizon.
  bloomAndDraw,

  /// Two gold lights orbit a shared centre while remaining visibly linked.
  linkedOrbit,

  /// Five fixed points connect in sequence, like a small constellation.
  constellation,

  /// A hairline bridge holds while soft rings travel away from its centre.
  rippleBridge,
}

extension ZyraLoadingStyleX on ZyraLoadingStyle {
  /// Shared colour contract for both moving and reduced-motion frames.
  Color get accentColor => kZyraLoadingAccent;

  String get label => switch (this) {
    ZyraLoadingStyle.meetAndPass => 'Meet & pass',
    ZyraLoadingStyle.cometLoop => 'Comet line',
    ZyraLoadingStyle.travellingDots => 'Travelling light',
    ZyraLoadingStyle.slidingDots => 'Flowing dots',
    ZyraLoadingStyle.softBloom => 'Soft bloom',
    ZyraLoadingStyle.centreDraw => 'Centre draw',
    ZyraLoadingStyle.bloomAndDraw => 'Bloom + draw',
    ZyraLoadingStyle.linkedOrbit => 'Linked orbit',
    ZyraLoadingStyle.constellation => 'Constellation',
    ZyraLoadingStyle.rippleBridge => 'Ripple bridge',
  };

  String get description => switch (this) {
    ZyraLoadingStyle.meetAndPass =>
      'The current two-light crossing with a quiet reset.',
    ZyraLoadingStyle.cometLoop =>
      'Two lights cross a fine horizon in one continuous sweep.',
    ZyraLoadingStyle.travellingDots =>
      'Four fixed points brighten in a calm left-to-right rhythm.',
    ZyraLoadingStyle.slidingDots =>
      'Four lights flow physically across one compact track.',
    ZyraLoadingStyle.softBloom =>
      'One restrained gold light breathes at the centre.',
    ZyraLoadingStyle.centreDraw =>
      'A fine horizon grows outwards from a still centre.',
    ZyraLoadingStyle.bloomAndDraw =>
      'A soft arrival resolves into a complete gold horizon.',
    ZyraLoadingStyle.linkedOrbit =>
      'Two linked lights orbit a shared point without breaking apart.',
    ZyraLoadingStyle.constellation =>
      'Five points connect progressively, then begin again quietly.',
    ZyraLoadingStyle.rippleBridge =>
      'A stable connection sends subtle rings out from its centre.',
  };
}

// bounceWordmark and sweepWordmark were REMOVED 2026-08-09, not kept as
// options. Both drew the ZYRA wordmark, and the wordmark now belongs to
// the splash. Neither was ever chosen. All runtime loading presentations
// remain wordmark-free; the later full-screen branded loader is removed too.

/// The compact default. Full-screen waits always use [ZyraQuietLoading];
/// an explicit style affects only a compact presentation.
///
/// CHOSEN 2026-08-29 — [ZyraLoadingStyle.cometLoop]. This is an
/// unknown-duration wait loop, not the splash's one-time brand arrival.
///
/// Was slidingDots for a few hours on 2026-08-08, after the Founder picked
/// "idea 2, the four dots". The splash then moved from orbs to a comet
/// rule, and loading followed it so the two screens speak one language.
const ZyraLoadingStyle kZyraLoadingStyle = ZyraLoadingStyle.cometLoop;

/// A passive gap, not a splash or an access grant. Fast work paints only the
/// opaque brand canvas; longer visible work earns a small, stationary label.
class ZyraQuietLoading extends StatefulWidget {
  const ZyraQuietLoading({super.key, this.canvasKey});

  /// Keeps a caller's canvas identity on the actual opaque painted box.
  final Key? canvasKey;

  @override
  State<ZyraQuietLoading> createState() => _ZyraQuietLoadingState();
}

class _ZyraQuietLoadingState extends State<ZyraQuietLoading>
    with WidgetsBindingObserver {
  Timer? _feedbackTimer;
  ModalRoute<dynamic>? _route;
  int _feedbackGeneration = 0;
  bool _feedbackVisible = false;

  bool get _foreground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return mounted &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed) &&
        (_route?.isCurrent ?? true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _reconcileFeedback();
  }

  bool _resetFeedback() {
    _feedbackGeneration++;
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    final changed = _feedbackVisible;
    _feedbackVisible = false;
    return changed;
  }

  void _reconcileFeedback({bool repaint = false}) {
    if (!_foreground) {
      final changed = _resetFeedback();
      if (repaint && changed && mounted) setState(() {});
      return;
    }
    if (_feedbackVisible || _feedbackTimer != null) return;
    final generation = _feedbackGeneration;
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || generation != _feedbackGeneration) return;
      _feedbackTimer = null;
      if (!_foreground) {
        _resetFeedback();
        return;
      }
      setState(() => _feedbackVisible = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      final changed = _resetFeedback();
      if (changed && mounted) setState(() {});
      return;
    }
    _reconcileFeedback(repaint: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetFeedback();
    _route = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedbackVisible && _foreground;
    final style =
        Theme.of(context).textTheme.bodySmall ??
        DefaultTextStyle.of(context).style;
    return BlockSemantics(
      child: AbsorbPointer(
        child: Semantics(
          container: true,
          liveRegion: feedback,
          label: feedback ? 'Updating ZYRA' : null,
          child: ExcludeSemantics(
            child: SizedBox.expand(
              child: DecoratedBox(
                key: widget.canvasKey,
                decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
                child: feedback
                    ? SafeArea(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Updating…',
                              key: const ValueKey('zyra_quiet_loading_status'),
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: style.copyWith(
                                color: ZyraColors.journeyGold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ZyraLoading extends StatefulWidget {
  /// Overrides [kZyraLoadingStyle] for one compact call site. Full-screen
  /// waiting never uses animated styles, including an explicit override.
  final ZyraLoadingStyle? style;

  /// Fills the screen with the quiet, opaque waiting canvas. False (the
  /// default) draws a compact indicator inside a card, list or button.
  final bool fullScreen;

  /// Optional compact wait reason. Full-screen waits use only the shared
  /// delayed feedback, never an immediate call-site label or wordmark.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reconcileMotion();
  }

  @override
  void didUpdateWidget(covariant ZyraLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reconcileMotion();
  }

  void _reconcileMotion() {
    // A motion preference can change without replacing this wait. Stop the
    // existing ticker as well as painting a still frame, and never create one
    // merely to serve an initially reduced-motion presentation.
    final still =
        widget.fullScreen ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    final controller = _controller;
    if (controller != null) {
      if (still) {
        controller.stop();
      } else if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

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
    if (widget.fullScreen) {
      return const ZyraQuietLoading(
        canvasKey: ValueKey('zyra_full_screen_quiet_canvas'),
      );
    }

    // A call-site override remains useful for focused historical visual
    // tests. Inline waits retain the compact Founder-approved Comet line.
    return _buildForStyle(context, widget.style ?? kZyraLoadingStyle);
  }

  Widget _buildForStyle(BuildContext context, ZyraLoadingStyle style) {
    // ACCESSIBILITY. Flutter's equivalent of prefers-reduced-motion. The
    // shape stays and the motion stops — a static indicator still says
    // "waiting", which a blank screen does not.
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final Widget motion = still
        ? _StillFallback(style: style)
        : AnimatedBuilder(
            animation: _c,
            builder: (context, _) => _build(style),
          );
    final indicator = Semantics(
      label: 'Loading',
      child: KeyedSubtree(
        key: ValueKey('zyra_loading_${style.name}'),
        child: motion,
      ),
    );

    final Widget content = widget.label == null
        ? indicator
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              indicator,
              SizedBox(height: 18),
              Text(
                widget.label!,
                textAlign: TextAlign.center,
                style: ZyraText.subtext(color: ZyraColors.ink(0.70)),
              ),
            ],
          );

    return Center(child: content);
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
          ending: ZyraCometEnding.passThrough,
          journey: _journeySweep.transform(_c.value),
          clip: true,
          accentColor: style.accentColor,
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
                        Color.lerp(
                          style.accentColor.withValues(alpha: 0.24),
                          style.accentColor,
                          p,
                        ) ??
                        style.accentColor.withValues(alpha: 0.24),
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: style.accentColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        );

      case ZyraLoadingStyle.softBloom:
      case ZyraLoadingStyle.centreDraw:
      case ZyraLoadingStyle.bloomAndDraw:
      case ZyraLoadingStyle.linkedOrbit:
      case ZyraLoadingStyle.constellation:
      case ZyraLoadingStyle.rippleBridge:
        return CustomPaint(
          size: const Size(_railWidth, 34),
          painter: _ZyraLoadingMotionPainter(style: style, progress: _c.value),
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
      return ZyraCometRule(
        width: _railWidth,
        travel: 1,
        clip: true,
        accentColor: style.accentColor,
      );
    }
    if (style == ZyraLoadingStyle.softBloom ||
        style == ZyraLoadingStyle.centreDraw ||
        style == ZyraLoadingStyle.bloomAndDraw ||
        style == ZyraLoadingStyle.linkedOrbit ||
        style == ZyraLoadingStyle.constellation ||
        style == ZyraLoadingStyle.rippleBridge) {
      return CustomPaint(
        size: const Size(_railWidth, 34),
        painter: _ZyraLoadingMotionPainter(style: style, progress: 0.48),
      );
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.accentColor.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

/// The six new compact motion studies. They share a footprint and palette so
/// changing the developer option never moves the surrounding layout.
class _ZyraLoadingMotionPainter extends CustomPainter {
  final ZyraLoadingStyle style;
  final double progress;

  const _ZyraLoadingMotionPainter({
    required this.style,
    required this.progress,
  });

  static const _gold = kZyraLoadingAccent;

  double get _pulse => 0.5 - 0.5 * math.cos(progress * math.pi * 2);

  Paint _line({double alpha = 0.72, double width = 1}) => Paint()
    ..color = _gold.withValues(alpha: alpha.clamp(0.0, 1.0))
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  void _dot(
    Canvas canvas,
    Offset centre, {
    double radius = 2.2,
    double alpha = 1,
    double glow = 0,
  }) {
    if (glow > 0) {
      canvas.drawCircle(
        centre,
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _gold.withValues(alpha: 0.30 * alpha),
              _gold.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: glow)),
      );
    }
    canvas.drawCircle(
      centre,
      radius,
      Paint()..color = _gold.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    switch (style) {
      case ZyraLoadingStyle.softBloom:
        _paintSoftBloom(canvas, centre);
      case ZyraLoadingStyle.centreDraw:
        _paintCentreDraw(canvas, centre);
      case ZyraLoadingStyle.bloomAndDraw:
        _paintBloomAndDraw(canvas, centre);
      case ZyraLoadingStyle.linkedOrbit:
        _paintLinkedOrbit(canvas, centre);
      case ZyraLoadingStyle.constellation:
        _paintConstellation(canvas, centre);
      case ZyraLoadingStyle.rippleBridge:
        _paintRippleBridge(canvas, centre);
      case ZyraLoadingStyle.meetAndPass:
      case ZyraLoadingStyle.cometLoop:
      case ZyraLoadingStyle.travellingDots:
      case ZyraLoadingStyle.slidingDots:
        // These four retain their dedicated widgets above.
        return;
    }
  }

  void _paintSoftBloom(Canvas canvas, Offset centre) {
    final radius = 7 + 12 * _pulse;
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _gold.withValues(alpha: 0.32 + 0.16 * _pulse),
            _gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
    _dot(
      canvas,
      centre,
      radius: 1.8 + 0.8 * _pulse,
      alpha: 0.82 + 0.18 * _pulse,
    );
  }

  void _paintCentreDraw(Canvas canvas, Offset centre) {
    final raw = progress < 0.72
        ? progress / 0.72
        : (1 - (progress - 0.72) / 0.28).clamp(0.0, 1.0);
    final extent = 49 * Curves.easeInOutCubic.transform(raw);
    canvas.drawLine(
      Offset(centre.dx - extent, centre.dy),
      Offset(centre.dx + extent, centre.dy),
      _line(alpha: 0.35 + raw * 0.55, width: 1.25),
    );
    _dot(canvas, centre, radius: 1.65, alpha: 0.72 + 0.28 * raw);
  }

  void _paintBloomAndDraw(Canvas canvas, Offset centre) {
    final bloom = progress < 0.42
        ? Curves.easeOutCubic.transform((progress / 0.42).clamp(0.0, 1.0))
        : (1 - (progress - 0.42) / 0.58).clamp(0.0, 1.0);
    final draw = progress < 0.18
        ? 0.0
        : progress < 0.76
        ? Curves.easeInOutCubic.transform((progress - 0.18) / 0.58)
        : (1 - (progress - 0.76) / 0.24).clamp(0.0, 1.0);
    final glowRadius = 5 + 11 * bloom;
    canvas.drawCircle(
      centre,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _gold.withValues(alpha: 0.28 * bloom),
            _gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: glowRadius)),
    );
    final extent = 48 * draw;
    canvas.drawLine(
      Offset(centre.dx - extent, centre.dy),
      Offset(centre.dx + extent, centre.dy),
      _line(alpha: 0.22 + 0.68 * draw, width: 1.15),
    );
    _dot(canvas, centre, radius: 1.6 + bloom, alpha: 0.70 + 0.30 * bloom);
  }

  void _paintLinkedOrbit(Canvas canvas, Offset centre) {
    final angle = progress * math.pi * 2;
    final offset = Offset(math.cos(angle) * 31, math.sin(angle) * 8);
    final first = centre + offset;
    final second = centre - offset;
    canvas.drawLine(first, second, _line(alpha: 0.34, width: 0.8));
    _dot(canvas, centre, radius: 1.1, alpha: 0.42);
    _dot(canvas, first, radius: 2.2, glow: 7, alpha: 0.78 + 0.22 * _pulse);
    _dot(canvas, second, radius: 2.2, glow: 7, alpha: 0.78 + 0.22 * _pulse);
  }

  void _paintConstellation(Canvas canvas, Offset centre) {
    final points = <Offset>[
      centre + const Offset(-49, 5),
      centre + const Offset(-27, -5),
      centre + const Offset(-4, 3),
      centre + const Offset(22, -6),
      centre + const Offset(49, 4),
    ];
    final draw = progress < 0.78
        ? Curves.easeInOutCubic.transform(progress / 0.78)
        : (1 - (progress - 0.78) / 0.22).clamp(0.0, 1.0);
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], _line(alpha: 0.16));
    }
    final scaled = draw * (points.length - 1);
    final completeSegments = scaled.floor().clamp(0, points.length - 1);
    for (var i = 0; i < completeSegments; i++) {
      canvas.drawLine(points[i], points[i + 1], _line(alpha: 0.78, width: 1.1));
    }
    if (completeSegments < points.length - 1) {
      final local = scaled - completeSegments;
      canvas.drawLine(
        points[completeSegments],
        Offset.lerp(
          points[completeSegments],
          points[completeSegments + 1],
          local,
        )!,
        _line(alpha: 0.78, width: 1.1),
      );
    }
    for (var i = 0; i < points.length; i++) {
      final reached = i <= scaled.ceil();
      _dot(
        canvas,
        points[i],
        radius: reached ? 1.9 : 1.35,
        alpha: reached ? 0.88 : 0.24,
        glow: reached && (scaled - i).abs() < 0.8 ? 6 : 0,
      );
    }
  }

  void _paintRippleBridge(Canvas canvas, Offset centre) {
    canvas.drawLine(
      Offset(centre.dx - 48, centre.dy),
      Offset(centre.dx + 48, centre.dy),
      _line(alpha: 0.32, width: 0.8),
    );
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final alpha = math.sin(phase * math.pi).clamp(0.0, 1.0) * 0.38;
      canvas.drawCircle(
        centre,
        3 + 18 * phase,
        _line(alpha: alpha, width: 0.9),
      );
    }
    _dot(
      canvas,
      centre,
      radius: 1.8 + _pulse * 0.7,
      alpha: 0.78 + _pulse * 0.22,
      glow: 7,
    );
  }

  @override
  bool shouldRepaint(covariant _ZyraLoadingMotionPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.progress != progress;
}
