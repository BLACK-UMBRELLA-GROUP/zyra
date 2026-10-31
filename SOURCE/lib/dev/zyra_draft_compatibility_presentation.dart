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
/// The locked Monogram is neutral artwork, not a concealed or approximate score.
class ZyraDraftCompatibilityPresentation extends StatelessWidget {
  const ZyraDraftCompatibilityPresentation({
    super.key,
    required this.personName,
    required this.balance,
    required this.overallScore,
    required this.revealed,
    this.onUnlock,
    this.onBuyMore,
    this.canAct,
  }) : assert(balance >= 0),
       assert(overallScore >= 0 && overallScore <= 100);

  final String personName;
  final int balance;
  final int overallScore;
  final bool revealed;
  final VoidCallback? onUnlock;
  final VoidCallback? onBuyMore;
  final bool Function()? canAct;

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
            gold: true,
            child: FilledButton(
              key: const ValueKey('draft_compatibility_reveal'),
              onPressed: ZyraTapFeedback.onTap(
                context,
                enabled ? onUnlock : null,
                canAct: canAct,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                foregroundColor: ZyraColors.onPrimaryAction,
                backgroundColor: ZyraColors.goldTextFill,
                side: BorderSide.none,
                disabledBackgroundColor: ZyraColors.journeyGold.withValues(
                  alpha: .35,
                ),
                disabledForegroundColor: ZyraColors.espresso.withValues(
                  alpha: .6,
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
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('draft_compatibility_buy_more'),
            onPressed: ZyraTapFeedback.onTap(
              context,
              onBuyMore,
              canAct: canAct,
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: ZyraColors.goldText,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '$balance ${balance == 1 ? 'Unlock' : 'Unlocks'} left · ',
                    style: ZyraText.subtext(
                      size: 13,
                      color: ZyraColors.secondaryText,
                    ),
                  ),
                  TextSpan(
                    text: 'Get more',
                    style: ZyraText.body(size: 13, color: ZyraColors.goldText),
                  ),
                ],
              ),
              key: const ValueKey('draft_compatibility_balances'),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationRow(IconData icon, String title, String detail) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ZyraColors.journeyGold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: ZyraText.body(size: 14)),
              const SizedBox(height: 3),
              Text(
                detail,
                style: ZyraText.subtext(size: 12.5).copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _locked(
    BuildContext context,
    BoxConstraints constraints,
  ) => ZyraShadowScrollView(
    key: const ValueKey('draft_compatibility_viewport'),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
      ),
      child: IntrinsicHeight(
        child: Column(
          key: const ValueKey('draft_compatibility_presentation'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Compatibility score', style: ZyraText.heading(size: 26)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          key: const ValueKey(
                            'draft_compatibility_locked_halo',
                          ),
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFFA9792E,
                              ).withValues(alpha: .7),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 34,
                            color: ZyraColors.journeyGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You and $personName',
                        textAlign: TextAlign.center,
                        style: ZyraText.heading(size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'READY TO REVEAL',
                        textAlign: TextAlign.center,
                        style: ZyraText.body(
                          size: 11,
                          color: ZyraColors.goldText,
                        ).copyWith(letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 22),
                      ZyraFloatingSurface(
                        child: Container(
                          key: const ValueKey('draft_compatibility_card'),
                          decoration: BoxDecoration(
                            color: ZyraColors.surfaceFill,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: [
                              _informationRow(
                                Icons.insights_rounded,
                                'Your overall score and six areas',
                                'Faith & Values, Family, Lifestyle and more',
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 54,
                                  right: 18,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: ZyraColors.espresso.withValues(
                                    alpha: .10,
                                  ),
                                ),
                              ),
                              _informationRow(
                                Icons.lock_outline_rounded,
                                'Uses 1 Unlock',
                                'It stays unlocked for $personName, also in a Journey Bio',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _lockedActions(),
          ],
        ),
      ),
    ),
  );

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
