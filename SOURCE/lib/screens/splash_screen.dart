// Splash — the branded opening.
//
// NEW 2026-08-07. Founder-approved animation: two soft lights converge and
// merge behind the name, the letters arrive one at a time, and the tagline
// lands with the last of them.
//
// ── IT NOW ALWAYS PLAYS. Founder, 2026-08-07: "every time I open the app I
// want to start with the splash screen."
//
// That is a deliberate reversal of how this file worked an hour ago. The
// first version added ZERO time — it dressed up the wait AuthGate was
// already spending on the session lookup, and vanished the instant that
// finished, sometimes after 80ms. An animation cannot do that: cut it off
// mid-way and it reads as a glitch.
//
// So the splash now runs for [_total] and the app waits for it. The cost is
// real and it is a choice: launch is up to ~1.8s slower than it needs to be,
// bought for a first impression. If that ever feels too long, [_total] is
// the only number to change — every interval below is expressed as a
// fraction of it, so the whole sequence rescales together.
//
// AuthGate holds the other half: it shows this until BOTH the animation has
// finished AND the session has resolved. On a slow network the profile
// fetch outlasts the animation and the last frame simply holds, which is
// why the composition ends in a state that is calm to sit in.
//
// ── THE NATIVE LAUNCH IMAGE MUST BE A FLAT COLOUR, and this is not
// optional. iOS and Android paint a static image before Flutter draws
// anything. If that image contains the wordmark — as it did until today —
// the user sees ZYRA fully assembled, then watches it vanish and rebuild
// itself letter by letter. flutter_native_splash is now configured with a
// colour and no image; assets/splash/splash_logo.png is no longer
// referenced. Do not put it back.
//
// ── GRADIENT. THE BRAND PURPLE, ALWAYS. Never gender-matched.
//
// DR-ZYRA-094's ratified palette lists the Splash Screen under GLOBAL
// BRAND — #8A6A9E -> #3D2A4A — alongside Main Navigation and core
// branding. The MALE and FEMALE gradients are scoped to "Male/Female
// Seeker" and "Male/Female Guardian", which are profile-context screens.
// The splash is not one: it is the brand introducing itself, before the
// app knows or should care who is holding the phone.
//
// ── THIS REVERSES THE 2026-08-07 CHANGE, deliberately. Founder,
// 2026-08-08: "it's got the pink purple colour but it should be the purple
// colour."
//
// That earlier change made the splash gender-matched to kill a flash the
// Founder had reported as "a second of purple before it goes pink" — the
// splash painting neutral, then main.dart's gendered layer taking over
// underneath it. The diagnosis was right and the fix was aimed at the
// wrong half: it removed the flash by making the splash the WRONG COLOUR
// for the whole four seconds, rather than by softening the handoff.
//
// The handoff is now where it belongs — AuthGate cross-fades the splash
// into the resolved screen (see auth_gate.dart), so brand purple resolves
// into the member's own colour as a transition instead of a cut. The
// splash itself stays brand purple start to finish.
//
// If a flash ever reappears, fix it in AuthGate. Do not re-tint the splash.

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../widgets/zyra_comet_rule.dart';
import '../theme/zyra_text.dart';

/// Total time the splash owns the screen.
///
/// 2600 -> 4000ms, Founder 2026-08-08 (benchmarked against Uber): "I want 4
/// seconds with 2 of those seconds showing no animation, just the ZYRA."
/// 4000 -> 3000ms, Founder, later the same day: "make the splash screen 3
/// seconds not 4."
///
/// THE SECOND WAS TAKEN OFF THE HOLD, NOT THE ANIMATION. [_animFraction]
/// moved 0.5 -> 2/3 in the same change, which keeps the sequence at the
/// 2000ms he originally approved and cuts the still hold from 2000ms to
/// 1000ms. Shortening the animation instead would have sped up every
/// interval below — a different composition, not a shorter one, and not
/// what "make it 3 seconds" asks for.
///
/// If 1000ms of stillness turns out to be too brief to read as an arrival,
/// the honest fix is a shorter ANIMATION at 3000ms total (raise
/// [_animFraction] back toward 0.5), not a longer splash.
const Duration _total = Duration(milliseconds: 3000);

/// How much of [_total] the animation occupies. The remainder is a
/// deliberate STILL HOLD on the finished composition.
///
/// ── WHY A HOLD IS A REAL DESIGN ELEMENT AND NOT DEAD TIME.
/// An animation that finishes and immediately hands off reads as a
/// transition — something on the way to somewhere. The same animation
/// followed by stillness reads as an arrival. The pause is what turns
/// motion into a statement, and it is why the composition ends on the
/// wordmark alone with the orbs fully gone: there has to be something
/// worth looking at while it holds.
///
/// ── HOW IT WORKS. Every interval below is expressed as a fraction of the
/// ANIMATION, not of [_total]. `_at()` divides the controller by this
/// fraction and clamps, so the first 2000ms plays the whole sequence and
/// the remainder holds every value pinned at 1.0. One controller, no
/// second timer, and the two numbers are independently adjustable.
///
/// 0.5 -> 2/3 on 2026-08-08, alongside [_total] 4000 -> 3000. Deliberately
/// expressed as `2 / 3` rather than `0.667`: the intent is "the animation
/// keeps its 2000ms", and 2/3 of 3000 is exactly that. A rounded decimal
/// would silently drift the sequence if [_total] ever changes again.
const double _animFraction = 2 / 3;

class SplashScreen extends StatefulWidget {
  /// Fired once when the animation completes. AuthGate uses it as one of
  /// the two conditions for moving on.
  final VoidCallback? onFinished;
  const SplashScreen({super.key, this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _total)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished?.call();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Fractions of the ANIMATION, so the whole sequence rescales from one
  // number.
  //
  // ── COMET RULE, replacing the two orbs. Founder, 2026-08-09, having
  // been shown five orb designs, five line designs and six variations of
  // the two he liked: "below the tag line design."
  //
  // The orbs are gone, not disabled. What replaced them:
  //
  //   THE PROBLEM WITH THE ORBS. Two soft discs meeting concentrically
  //   made a large area of a colour nobody chose — screen(#D4868F,
  //   #3D5A80) over the mid-gradient lands on ~#EBC7E1, a pale lilac,
  //   and it sat there for most of the screen. Founder: "I just don't
  //   like the purple ball the pink and blue creates in end."
  //
  //   WHY A LINE FIXES IT RATHER THAN AVOIDS IT. The merge was never the
  //   problem — the surface area was. Two lines meeting make the same
  //   colour across a few pixels instead of a third of the display. The
  //   two tails still overlap, deliberately, by 9% of a half-rule.
  //
  // The rail is drawn faintly BEFORE the comets arrive and stays after
  // they have gone, so the still second at the end holds a composition
  // rather than floating text.
  static const _railIn = Interval(0.05, 0.22, curve: Curves.easeOut);
  static const _cometTravel = Interval(0.00, 0.62, curve: Cubic(.25, .6, .3, 1));
  static const _cometFade = Interval(0.62, 0.90, curve: Curves.easeIn);

  static const _letterStagger = 0.085; // ~150ms apart
  static const _letterStart = 0.16;
  static const _letterLen = 0.30;

  // Lands WITH the final letter rather than after it — the name completing
  // and the promise appearing read as one gesture, and it saves ~400ms.
  static const _tagline = Interval(0.66, 0.92, curve: Cubic(.22, .9, .3, 1));

  /// Controller progress remapped onto the animation phase. Past
  /// [_animFraction] this clamps to 1.0, which is what makes the tail of
  /// the splash completely still rather than slowly drifting.
  double get _anim => (_c.value / _animFraction).clamp(0.0, 1.0);

  double _at(Interval i) => i.transform(_anim);

  @override
  Widget build(BuildContext context) {
    final m = _SplashMetrics.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        // GLOBAL BRAND, per DR-ZYRA-094. Not genderGradient() — see the
        // note at the top of this file before changing it back.
        gradient: ZyraColors.brandGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // ONE BLOCK — 2026-08-09. Founder: "ZYRA and Connecting
            // Through Trust doesn't have space, so maybe the line is
            // below Connecting Through Trust."
            //
            // The wordmark and the tagline used to be separated by a
            // generous gap, which made them read as two things stacked on
            // one screen. They are now one unit with a hairline of space
            // between them, and the rule sits under the pair — so it
            // underlines the whole statement instead of dividing it.
            return Align(
              alignment: const Alignment(0, -0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Wordmark(progress: _anim, size: m.wordmark),
                  SizedBox(height: m.gap),
                  Opacity(
                    opacity: _at(_tagline),
                    child: Transform.translate(
                      offset: Offset(0, 6 * (1 - _at(_tagline))),
                      child: Text(
                        'Connecting Through Trust',
                        style: ZyraText.subtext(
                            size: m.tagline, color: Colors.white70),
                      ),
                    ),
                  ),
                  SizedBox(height: m.ruleGap),
                  // Shared with ZyraLoading — see widgets/zyra_comet_rule
                  // .dart. The splash plays it once; loading loops it.
                  ZyraCometRule(
                    width: m.ruleWidth,
                    travel: _at(_cometTravel),
                    fade: _at(_cometFade),
                    railOpacity: _at(_railIn),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Every dimension on this screen, derived from one number.
///
/// ── WHY. The composition was tuned by eye on a 390pt iPhone and every
/// size was hardcoded. Measured on other devices it degraded in both
/// directions, and the orbs degraded worse than the type:
///
///   iPhone SE 320pt  orbs are WIDER THAN THE SCREEN — they bleed off both
///                    edges and read as two blobs at the margins rather
///                    than two lights meeting
///   iPad 768pt       orbs small in a large field, flung far apart because
///                    the travel was a fraction of screen width; wordmark
///                    ~30% of the width and visibly lost
///
/// The wordmark itself never overflowed anywhere — Syne is narrow, so
/// "ZYRA" at 74pt is only 229pt wide and clears a 320pt screen by 46pt
/// each side. The problem was proportion, not fit.
///
/// ── THE DESIGN WIDTH. Everything scales off `min(shortestSide, 480)`.
///
/// Capping at 480 is what makes tablets work: past that a phone
/// composition stops growing and simply centres in the extra space, which
/// is how a splash should behave on an iPad rather than stretching to
/// fill it.
///
/// Using the SHORTEST side, not the width, is what makes landscape work.
/// On a tablet turned sideways the width is enormous and the height is
/// what constrains the composition.
///
/// ── 390pt IS UNCHANGED, deliberately. 390 x 0.19 = 74.1, which is the
/// size the Founder approved on his own device. The ratios were chosen to
/// reproduce the approved composition exactly there and to fix everything
/// either side of it.
class _SplashMetrics {
  final double design;
  final double wordmark;
  final double tagline;
  /// Wordmark to tagline. TIGHT since 2026-08-09 — they are one block.
  final double gap;

  /// Tagline to the rule. The only generous space in the composition.
  final double ruleGap;

  /// Total width of the comet rule.
  final double ruleWidth;

  const _SplashMetrics._({
    required this.design,
    required this.wordmark,
    required this.tagline,
    required this.gap,
    required this.ruleGap,
    required this.ruleWidth,
  });

  factory _SplashMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final design = (size.shortestSide).clamp(280.0, 480.0);
    return _SplashMetrics._(
      design: design,
      // Clamps are a safety net, not the mechanism — at the capped design
      // width neither bound is reached. They exist so an unexpected
      // viewport (a foldable's cover screen, a desktop window) cannot
      // produce something absurd.
      wordmark: (design * 0.19).clamp(56.0, 96.0),
      // Formula moved to ZyraText.taglineSize so the Welcome screen can
      // share it. Same ratio, floor lifted 11.0 -> 12.5.
      tagline: ZyraText.taglineSize(context),
      // 0.0359 -> 0.0128 on 2026-08-09. That is 5pt on a 390pt phone,
      // down from 14 — the wordmark and the tagline are one block now,
      // and 14pt read as two separate things on one screen.
      gap: (design * 0.0128).clamp(4.0, 8.0),
      // 26pt on a 390pt phone. The rule needs real air above it or it
      // reads as an underline on the tagline rather than under the pair.
      ruleGap: (design * 0.0667).clamp(18.0, 34.0),
      // 60% of the design width — wider than the tagline, so the rule
      // holds the block rather than matching it.
      ruleWidth: design * 0.60,
    );
  }
}

/// Z · Y · R · A, each arriving in turn.
///
/// Four Texts in a Row rather than one Text, because each letter needs its
/// own opacity and offset. The last letter's tracking is zeroed — a
/// trailing 4pt on the final glyph would push the whole word 2pt left of
/// centre, which is exactly the kind of thing that looks like nothing and
/// feels wrong.
class _Wordmark extends StatelessWidget {
  final double progress;

  /// Passed in rather than hardcoded — see _SplashMetrics. 74 on the
  /// Founder's 390pt phone, which is the size he approved; smaller on an
  /// SE, larger on a tablet.
  final double size;
  const _Wordmark({required this.progress, required this.size});

  static const _letters = ['Z', 'Y', 'R', 'A'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_letters.length, (i) {
        final begin = _SplashScreenState._letterStart + i * _SplashScreenState._letterStagger;
        final t = Interval(
          begin,
          (begin + _SplashScreenState._letterLen).clamp(0.0, 1.0),
          curve: const Cubic(.22, .9, .3, 1),
        ).transform(progress);

        // The 74 that produced this on a 390pt phone came from the size
        // comparison the Founder approved — that widget was mislabelled
        // (cards ~215px standing in for a 390pt phone, a 0.55 scale, sizes
        // picked by eye rather than divided through), so the card marked
        // "60" was really drawing at ~74pt. Confirmed against a
        // true-device-scale render, then made proportional here.
        final base = ZyraText.wordmark(size: size);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: Text(
              _letters[i],
              style: i == _letters.length - 1 ? base.copyWith(letterSpacing: 0) : base,
            ),
          ),
        );
      }),
    );
  }
}
