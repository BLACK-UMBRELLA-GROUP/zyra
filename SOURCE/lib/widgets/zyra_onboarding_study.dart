// Founder-requested Mobbin onboarding comparisons, 2026-09-28.
// Pure local artwork/copy, not a registration flow or a permission request.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dev/dev_onboarding_welcome_motion.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

enum ZyraOnboardingDirection {
  luma('2 · Luma');

  const ZyraOnboardingDirection(this.label);
  final String label;

  /// These are visual welcome stories, not canonical signup chapters.
  static const storyPageCount = 4;
}

/// Initial style for the protected developer rehearsal only. An explicit
/// toggle selection still takes precedence; ordinary member onboarding is
/// not changed by this preview default.
const zyraDefaultDevOnboardingDirection = ZyraOnboardingDirection.luma;

const _storyBodies = [
  'ZYRA introduces you through photos first, so you can see who you’re drawn to. When you both choose to connect, you can get to know the person beyond the first impression.',
  'ZYRA shows where your values and expectations align, where they differ and what may need a conversation.',
  'You can invite more than one Guardian to support you. Once your Journey begins, they can share each stage, offer guidance and help you decide what comes next.',
];

const _storyEyebrows = ['MARRIAGE-FIRST', 'COMPATIBILITY', 'GUARDIAN SUPPORT'];
const _storyHeadings = [
  'Match on attraction.\nConnect on deen.',
  'See where you align\nbefore moving forward.',
  'A Journey you share\nwith your Guardians.',
];
const _storyNotes = [
  'Built for Muslims serious about marriage.',
  'You see the compatibility result—not each other’s private answers.',
  'Support beside you, every step of the way.',
];

// A shortened, faithful translation of the first part of the passage in
// al-Mardawi's al-Insaf (Dar Ihya al-Turath al-Arabi, vol. 8, p. 19).
// Al-Mardawi reports Imam Ahmad's words; this is not a Prophetic hadith.
const _imamAhmadExcerpt =
    'When a man seeks a woman’s hand, he asks first about her beauty. '
    'If it is spoken well of, he asks about her religion. If that too is '
    'spoken well of, he marries her; otherwise, his refusal is for the '
    'sake of religion.';
const _imamAhmadAttribution =
    'Reported from Imam Ahmad (may Allah have mercy on him) by al-Mardawi in al-Insaf, 8:19.';
const _imamAhmadExplanation = 'A principle that helped shape ZYRA.';

/// The selected Luma composition uses the existing ZYRA palette and type APIs.
/// No photographed members, borrowed logos, inputs, timers, storage or APIs.
class ZyraOnboardingStudy extends StatelessWidget {
  const ZyraOnboardingStudy({
    super.key,
    required this.direction,
    required this.page,
    this.scrollController,
    this.swipeNavigation = false,
    this.revealStep = 2,
    this.animateReveal = false,
    this.entered = true,
    this.sectionLead = false,
    this.alignArtwork = false,
    this.welcomeMotion,
  }) : assert(page >= 0 && page < ZyraOnboardingDirection.storyPageCount);

  final ZyraOnboardingDirection direction;
  final int page;
  final ScrollController? scrollController;
  final bool swipeNavigation;

  /// 0 = artwork and label; 1 = heading; 2 = quote/explanation. The
  /// continuous photo-first card uses 3 for its photo explanation after the
  /// Imam Ahmad quote, without adding a numbered page.
  /// Direct artwork previews remain fully visible by default.
  final int revealStep;
  final bool animateReveal;
  final bool entered;

  /// Labels the first explanatory card in the seven-step continuous preview
  /// and shows the excerpt without visible reference text. The separate
  /// four-card design comparison keeps its sourced quote page.
  final bool sectionLead;

  /// Keeps the four continuous-story illustrations in one top-aligned slot.
  final bool alignArtwork;
  final ZyraWelcomeTextMotion? welcomeMotion;

  Widget _reveal(int step, Widget child) => _StoryReveal(
    visible: entered && revealStep >= step,
    animate: animateReveal,
    motion: welcomeMotion,
    child: child,
  );

  Widget _storyText(
    int step,
    String text,
    TextStyle style, {
    TextAlign textAlign = TextAlign.left,
    Key? textKey,
  }) {
    final motion = welcomeMotion;
    if (motion == null || !motion.typesText) {
      return Text(text, key: textKey, textAlign: textAlign, style: style);
    }
    return _StoryTypedText(
      text: text,
      style: style,
      textAlign: textAlign,
      textKey: textKey,
      motion: motion,
      visible: entered && revealStep >= step,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 510;
      if (page == 0) {
        return _QuotePage(
          direction: direction,
          compact: compact,
          minHeight: constraints.maxHeight,
          scrollController: scrollController,
          swipeNavigation: swipeNavigation,
          revealStep: revealStep,
          animateReveal: animateReveal,
          entered: entered,
        );
      }
      // The reported principle opens the story; the three themed explanation
      // cards retain their existing artwork and copy associations afterward.
      final contentPage = page - 1;
      final roomy = constraints.maxWidth >= 430;
      final headingSize = sectionLead && contentPage == 0
          ? (compact ? 22.0 : 25.0)
          : (compact ? 25.0 : 29.0);
      // The continuous story uses one artwork slot even when copy lengths
      // differ. Standalone design comparisons retain their own compositions.
      final artworkHeight = alignArtwork
          ? (compact ? 120.0 : 140.0)
          : (constraints.maxHeight * .43 - (contentPage == 1 ? 32 : 0)).clamp(
              140.0,
              290.0,
            );
      final explanationStep = 2;
      final explanation = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _storyText(
            explanationStep,
            _storyBodies[contentPage],
            ZyraText.body(
              size: sectionLead
                  ? (compact ? 14.0 : (roomy ? 17 : 16))
                  : (compact ? 12.5 : 14),
              color: ZyraColors.foregroundSecondary,
            ).copyWith(height: sectionLead ? 1.38 : 1.6),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sectionLead ? 7 : (compact ? 12 : 18)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                contentPage == 1
                    ? Icons.lock_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 16,
                color: ZyraColors.journeyGold,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _storyText(
                  explanationStep,
                  _storyNotes[contentPage],
                  ZyraText.subtext(
                    size: sectionLead ? (roomy ? 13.5 : 13) : 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      final text = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _reveal(
            0,
            _storyText(
              0,
              sectionLead && contentPage == 0
                  ? 'HOW ZYRA WORKS'
                  : _storyEyebrows[contentPage],
              ZyraText.chapterLabel(color: ZyraColors.goldText),
            ),
          ),
          SizedBox(height: sectionLead ? 6 : 10),
          _reveal(
            1,
            _storyText(
              1,
              _storyHeadings[contentPage],
              ZyraText.heading(size: headingSize),
              textKey: ValueKey(
                'onboarding-study-heading-${direction.name}-$page',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: sectionLead ? 7 : 13),
          if (sectionLead && contentPage == 0)
            AnimatedSwitcher(
              duration:
                  !animateReveal || MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : (welcomeMotion?.duration ??
                        const Duration(milliseconds: 620)),
              transitionBuilder: (child, animation) =>
                  ZyraWelcomeTextMotionFrame(
                    motion: welcomeMotion ?? ZyraWelcomeTextMotion.slowDescent,
                    animation: animation,
                    child: child,
                  ),
              child: !entered || revealStep < 2
                  ? const SizedBox.shrink(
                      key: ValueKey('onboarding-study-photo-stage-heading'),
                    )
                  : KeyedSubtree(
                      key: const ValueKey(
                        'onboarding-study-photo-stage-complete',
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            container: true,
                            label:
                                'Reported excerpt from Imam Ahmad, recorded by '
                                'al-Mardawi in al-Insaf, volume 8, page 19. '
                                '$_imamAhmadExcerpt',
                            child: ExcludeSemantics(
                              child: Container(
                                key: ValueKey(
                                  'onboarding-study-quote-panel-${direction.name}-$page',
                                ),
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 8 : 10,
                                  vertical: compact ? 6 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ZyraColors.journeyGold.withValues(
                                    alpha: .07,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: ZyraColors.journeyGold.withValues(
                                      alpha: .18,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _storyText(
                                      2,
                                      'Reported from Imam Ahmad',
                                      ZyraText.subtext(
                                        size: compact ? 12 : 13,
                                        color: ZyraColors.goldText,
                                      ),
                                      textKey: ValueKey(
                                        'onboarding-study-quote-attribution-${direction.name}-$page',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 5),
                                    _storyText(
                                      2,
                                      '“$_imamAhmadExcerpt”',
                                      ZyraText.body(
                                        size: compact ? 14 : (roomy ? 17 : 16),
                                        color: ZyraColors.foregroundSecondary,
                                      ).copyWith(
                                        height: 1.3,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textKey: ValueKey(
                                        'onboarding-study-quote-${direction.name}-$page',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          explanation,
                        ],
                      ),
                    ),
            )
          else
            _reveal(2, explanation),
        ],
      );
      final artwork = _reveal(
        0,
        ExcludeSemantics(
          child: SizedBox(
            height: artworkHeight,
            width: double.infinity,
            child: CustomPaint(
              key: ValueKey('onboarding-study-art-${direction.name}-$page'),
              painter: _OnboardingStudyPainter(
                direction,
                contentPage,
                storyPage: page,
              ),
            ),
          ),
        ),
      );
      return SingleChildScrollView(
        key: ValueKey('onboarding-study-scroll-${direction.name}-$page'),
        controller: scrollController,
        physics: swipeNavigation
            ? alignArtwork && contentPage == 2
                  ? const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    )
                  : const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    )
            : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              alignArtwork ? (compact ? 12 : 46) : (compact ? 12 : 22),
              24,
              16,
            ),
            child: Column(
              mainAxisAlignment: alignArtwork
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                artwork,
                SizedBox(height: alignArtwork ? 8 : (compact ? 10 : 14)),
                text,
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Reuses each selected direction's large story artwork for the three
/// role-neutral welcome messages and the final handoff card.
class ZyraOnboardingStoryArtwork extends StatelessWidget {
  const ZyraOnboardingStoryArtwork({
    super.key,
    required this.direction,
    required this.topic,
    this.height = 260,
    this.symbol,
  }) : assert(topic >= 0 && topic < 3);

  final ZyraOnboardingDirection direction;
  final int topic;
  final double height;
  // An additional intro checkpoint reuses the same gold halo and anchor,
  // without adding an artificial fourth photos/compatibility/Guardian topic.
  final IconData? symbol;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        key: ValueKey('onboarding-welcome-art-${direction.name}-$topic'),
        painter: _OnboardingStudyPainter(
          direction,
          topic,
          storyPage: topic + 1,
          introSymbol: symbol,
        ),
      ),
    ),
  );
}

class _QuotePage extends StatelessWidget {
  const _QuotePage({
    required this.direction,
    required this.compact,
    required this.minHeight,
    required this.scrollController,
    required this.swipeNavigation,
    required this.revealStep,
    required this.animateReveal,
    required this.entered,
  });

  final ZyraOnboardingDirection direction;
  final bool compact;
  final double minHeight;
  final ScrollController? scrollController;
  final bool swipeNavigation;
  final int revealStep;
  final bool animateReveal;
  final bool entered;

  Widget _reveal(int step, Widget child) => _StoryReveal(
    visible: entered && revealStep >= step,
    animate: animateReveal,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    const page = 0;
    final alignment = TextAlign.center;
    return SingleChildScrollView(
      key: ValueKey('onboarding-study-scroll-${direction.name}-$page'),
      controller: scrollController,
      physics: swipeNavigation
          ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
          : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, compact ? 12 : 22, 24, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _reveal(
                0,
                Align(
                  alignment: Alignment.center,
                  child: ExcludeSemantics(
                    child: Container(
                      key: ValueKey(
                        'onboarding-study-art-${direction.name}-$page',
                      ),
                      width: compact ? 72 : 92,
                      height: compact ? 72 : 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ZyraColors.journeyGold.withValues(alpha: .08),
                        border: Border.all(
                          color: ZyraColors.journeyGold.withValues(alpha: .5),
                        ),
                      ),
                      child: Icon(
                        Icons.format_quote_rounded,
                        size: compact ? 33 : 42,
                        color: ZyraColors.journeyGold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 20),
              _reveal(
                0,
                Text(
                  'A PRINCIPLE BEHIND ZYRA',
                  textAlign: alignment,
                  style: ZyraText.chapterLabel(color: ZyraColors.goldText),
                ),
              ),
              const SizedBox(height: 10),
              _reveal(
                1,
                Text(
                  'It is reported from\nImam Ahmad:',
                  key: ValueKey(
                    'onboarding-study-heading-${direction.name}-$page',
                  ),
                  textAlign: alignment,
                  style: ZyraText.heading(size: compact ? 25 : 29),
                ),
              ),
              SizedBox(height: compact ? 12 : 18),
              _reveal(
                2,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      container: true,
                      label:
                          'Reported excerpt from Imam Ahmad, recorded by '
                          'al-Mardawi in al-Insaf, volume 8, page 19. '
                          '$_imamAhmadExcerpt',
                      child: ExcludeSemantics(
                        child: Container(
                          padding: EdgeInsets.all(compact ? 15 : 18),
                          decoration: BoxDecoration(
                            color: ZyraColors.surfaceFill,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: ZyraColors.journeyGold.withValues(
                                alpha: .22,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '“$_imamAhmadExcerpt”',
                                key: ValueKey(
                                  'onboarding-study-quote-${direction.name}-$page',
                                ),
                                textAlign: alignment,
                                style: ZyraText.body(
                                  size: compact ? 13.5 : 15,
                                  color: ZyraColors.foreground,
                                ).copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _imamAhmadAttribution,
                                key: ValueKey(
                                  'onboarding-study-attribution-${direction.name}-$page',
                                ),
                                textAlign: alignment,
                                style: ZyraText.subtext(
                                  size: compact ? 11 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    Text(
                      _imamAhmadExplanation,
                      textAlign: alignment,
                      style: ZyraText.body(
                        size: compact ? 12.5 : 14,
                        color: ZyraColors.foregroundSecondary,
                      ).copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Retains each line's place in the composition so reading reveals never
/// shove the next line or change the scroll position. Reduced-motion users
/// receive the same stages without opacity or movement animation.
class _StoryTypedText extends StatelessWidget {
  const _StoryTypedText({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.textKey,
    required this.motion,
    required this.visible,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final Key? textKey;
  final ZyraWelcomeTextMotion motion;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return ZyraWelcomeLine(
        text: text,
        style: style,
        textAlign: textAlign,
        textKey: textKey,
        visibleFraction: visible ? 1 : 0,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: motion.duration,
      curve: motion.easedTyping ? Curves.easeInOutSine : Curves.linear,
      builder: (context, fraction, _) => ZyraWelcomeLine(
        text: text,
        style: style,
        textAlign: textAlign,
        textKey: textKey,
        visibleFraction: fraction,
      ),
    );
  }
}

class _StoryReveal extends StatelessWidget {
  const _StoryReveal({
    required this.visible,
    required this.animate,
    required this.child,
    this.motion,
  });

  final bool visible;
  final bool animate;
  final Widget child;
  final ZyraWelcomeTextMotion? motion;

  @override
  Widget build(BuildContext context) {
    final hidden = ExcludeSemantics(excluding: !visible, child: child);
    if (!animate || MediaQuery.disableAnimationsOf(context)) {
      return Opacity(opacity: visible ? 1 : 0, child: hidden);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: motion?.duration ?? const Duration(milliseconds: 620),
      curve: motion?.easeOut == true
          ? Curves.easeOutCubic
          : Curves.easeInOutSine,
      child: hidden,
      builder: (context, amount, child) => Opacity(
        opacity: amount,
        child: Transform.translate(
          offset: Offset(0, (1 - amount) * (motion?.travel ?? 12)),
          child: child,
        ),
      ),
    );
  }
}

/// Original code-native illustrations. References influence composition only;
/// no source-brand assets, logos, photos, or slogans are reproduced.
class _OnboardingStudyPainter extends CustomPainter {
  _OnboardingStudyPainter(
    this.direction,
    this.page, {
    required this.storyPage,
    this.introSymbol,
  });
  final ZyraOnboardingDirection direction;
  final IconData? introSymbol;

  /// Original artwork topic: attraction, compatibility or Guardian support.
  final int page;

  /// Position in the four-card opening story, including the quote card.
  final int storyPage;
  Color get gold => ZyraColors.journeyGold;
  Color get ink => ZyraColors.foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 320, size.height / 280);
    canvas.save();
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 280 * scale) / 2,
    );
    canvas.scale(scale);
    _glow(canvas);
    canvas.restore();
  }

  void _card(Canvas c, Rect r, {double radius = 22, double alpha = .09}) {
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()..color = ink.withValues(alpha: alpha),
    );
  }

  void _icon(
    Canvas c,
    IconData icon,
    Offset center,
    double size, {
    Color? color,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color ?? gold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(c, center - Offset(p.width / 2, p.height / 2));
  }

  void _halo(Canvas c, Offset at, double radius) {
    c.drawCircle(
      at,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [gold.withValues(alpha: .28), gold.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: at, radius: radius)),
    );
  }

  void _glow(Canvas c) {
    _halo(c, const Offset(160, 130), 123);
    c.drawCircle(
      const Offset(160, 130),
      61,
      Paint()..color = gold.withValues(alpha: .10),
    );
    c.drawCircle(
      const Offset(160, 130),
      88,
      Paint()
        ..color = gold.withValues(alpha: .22)
        ..style = PaintingStyle.stroke,
    );
    _icon(
      c,
      introSymbol ??
          [
            Icons.auto_awesome_rounded,
            Icons.tune_rounded,
            Icons.people_outline_rounded,
          ][page],
      const Offset(160, 130),
      69,
    );
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + .45;
      final at = Offset(160 + 112 * math.cos(a), 130 + 112 * math.sin(a));
      c.drawCircle(
        at,
        i == page ? 8 : 4,
        Paint()..color = gold.withValues(alpha: i == page ? .8 : .3),
      );
    }
    _card(c, const Rect.fromLTWH(100, 238, 120, 24), radius: 12, alpha: .06);
  }

  @override
  bool shouldRepaint(_OnboardingStudyPainter oldDelegate) =>
      oldDelegate.direction != direction ||
      oldDelegate.page != page ||
      oldDelegate.storyPage != storyPage ||
      oldDelegate.introSymbol != introSymbol;
}
