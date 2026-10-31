import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_draft_compatibility_score_designs.dart';

/// Display-only Compatibility for the protected, fictional member preview.
///
/// The caller owns balances, reveal state, navigation and callback lifetime.
/// This widget cannot read answers, grant access, spend credits or load people.
/// The locked halo is neutral artwork, not a concealed or approximate score.
class ZyraDraftCompatibilityPresentation extends StatelessWidget {
  const ZyraDraftCompatibilityPresentation({
    super.key,
    required this.personName,
    required this.balance,
    required this.overallScore,
    required this.revealed,
    this.onUnlock,
    this.onBuyMore,
  }) : assert(balance >= 0),
       assert(overallScore >= 0 && overallScore <= 100);

  final String personName;
  final int balance;
  final int overallScore;
  final bool revealed;
  final VoidCallback? onUnlock;
  final VoidCallback? onBuyMore;

  Widget _lockedActions() {
    final enabled = balance > 0 && onUnlock != null;
    return Builder(
      builder: (context) => Column(
        key: const ValueKey('draft_compatibility_actions'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ZyraFloatingSurface(
            radius: 999,
            circle: false,
            gold: false,
            child: OutlinedButton(
              key: const ValueKey('draft_compatibility_reveal'),
              onPressed: ZyraTapFeedback.onTap(
                context,
                enabled ? onUnlock : null,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: ZyraColors.goldText,
                disabledForegroundColor: ZyraColors.goldText.withValues(
                  alpha: .45,
                ),
                backgroundColor: ZyraColors.journeyGold.withValues(alpha: .08),
                side: BorderSide(
                  color: ZyraColors.journeyGold.withValues(
                    alpha: enabled ? .6 : .2,
                  ),
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Unlock compatibility',
                textAlign: TextAlign.center,
                style: ZyraText.button(size: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$balance ${balance == 1 ? 'unlock' : 'unlocks'} left',
            key: const ValueKey('draft_compatibility_balances'),
            textAlign: TextAlign.center,
            style: ZyraText.subtext(
              size: 11.5,
              color: ZyraColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              key: const ValueKey('draft_compatibility_buy_more'),
              onPressed: ZyraTapFeedback.onTap(context, onBuyMore),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: ZyraColors.goldText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Get more unlocks',
                textAlign: TextAlign.center,
                style: ZyraText.button(size: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locked(BuildContext context, BoxConstraints constraints) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final compactHeading =
        constraints.maxWidth < 300 &&
        MediaQuery.textScalerOf(context).scale(26) > 40;
    final headingStyle = ZyraText.heading(
      size: compactHeading ? 20 : 26,
    ).copyWith(height: 1.2);
    final headingHeight =
        _textSize(
          context,
          'Compatibility score',
          headingStyle,
          constraints.maxWidth,
        ).height +
        16;
    final available = constraints.hasBoundedHeight
        ? (constraints.maxHeight - headingHeight).clamp(0.0, double.infinity)
        : 660.0;
    // Only decorative artwork adapts to a short phone. Text and controls retain
    // their full accessible sizes; overflow scrolls the entire composition.
    final diameter = (available - 376)
        .clamp(144.0, 248.0)
        .clamp(0.0, (constraints.maxWidth - 42).clamp(0.0, double.infinity))
        .toDouble();
    return ZyraShadowScrollView(
      key: const ValueKey('draft_compatibility_viewport'),
      child: Column(
        key: const ValueKey('draft_compatibility_presentation'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Compatibility score', style: headingStyle),
          const SizedBox(height: 16),
          Container(
            key: const ValueKey('draft_compatibility_card'),
            constraints: BoxConstraints(minHeight: available),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ZyraColors.cardSurface, ZyraColors.lowerSurface],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: ZyraColors.espresso.withValues(alpha: .13),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall',
                  style: ZyraText.heading(size: 25, color: ZyraColors.espresso),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: largeText ? 20 : 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          key: const ValueKey(
                            'draft_compatibility_locked_halo',
                          ),
                          width: diameter,
                          height: diameter,
                          padding: const EdgeInsets.all(16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 12,
                                color: ZyraColors.journeyGold.withValues(
                                  alpha: .22,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ZyraColors.journeyGold.withValues(
                                    alpha: .04,
                                  ),
                                  blurRadius: 34,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 38,
                              color: ZyraColors.journeyGold.withValues(
                                alpha: .85,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You and $personName',
                        textAlign: TextAlign.center,
                        style: ZyraText.heading(
                          size: 21,
                          color: ZyraColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your compatibility, ready to reveal',
                        textAlign: TextAlign.center,
                        style: ZyraText.body(
                          size: 14,
                          color: ZyraColors.goldText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock your overall score and six areas of compatibility.',
                        textAlign: TextAlign.center,
                        style: ZyraText.subtext(
                          size: 12.5,
                          color: ZyraColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                _lockedActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Disclosure remains caller-owned. The locked-in Golden Halo reader is
      // never mounted, even offstage, until the caller grants result access.
      if (revealed) {
        final compactHeading =
            constraints.maxWidth < 300 &&
            MediaQuery.textScalerOf(context).scale(26) > 40;
        final titleStyle = ZyraText.heading(
          size: compactHeading ? 20 : 26,
        ).copyWith(height: 1.2);
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Compatibility score', style: titleStyle),
            const SizedBox(height: 16),
          ],
        );
        final reader = ZyraCompatibilityScoreReader(
          personName: personName,
          overallScore: overallScore,
        );
        final headingHeight =
            16 +
            _textSize(
              context,
              'Compatibility score',
              titleStyle,
              constraints.maxWidth,
            ).height;
        final minimumReaderHeight =
            MediaQuery.textScalerOf(context).scale(14) > 20 ? 400.0 : 220.0;
        if (constraints.hasBoundedHeight &&
            constraints.maxHeight < headingHeight + minimumReaderHeight) {
          // Short landscape/very large text must scroll the composition, not
          // squeeze the pager or scale down its text and touch targets.
          return ZyraShadowScrollView(
            key: const ValueKey('draft_compatibility_reader_scroll_fallback'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                SizedBox(height: 400, child: reader),
              ],
            ),
          );
        }
        return Column(
          key: const ValueKey('draft_compatibility_presentation'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: constraints.hasBoundedHeight
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            heading,
            if (constraints.hasBoundedHeight)
              Expanded(child: reader)
            else
              SizedBox(height: 540, child: reader),
          ],
        );
      }
      return _locked(context, constraints);
    },
  );
}

Size _textSize(
  BuildContext context,
  String text,
  TextStyle style,
  double width,
) {
  var measuredStyle = DefaultTextStyle.of(context).style.merge(style);
  if (MediaQuery.boldTextOf(context)) {
    measuredStyle = measuredStyle.merge(
      const TextStyle(fontWeight: FontWeight.bold),
    );
  }
  final measured = TextPainter(
    text: TextSpan(text: text, style: measuredStyle),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: width);
  final size = measured.size;
  measured.dispose();
  return size;
}
