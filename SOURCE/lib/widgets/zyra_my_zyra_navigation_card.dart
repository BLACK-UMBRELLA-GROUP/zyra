import 'zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../models/zyra_supportive_dashboard.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// A presentation-only destination in the protected My ZYRA preview.
/// The caller still owns the card's identity, route and permission checks.
class ZyraMyZyraNavigationCard extends StatelessWidget {
  const ZyraMyZyraNavigationCard({
    super.key,
    required this.card,
    required this.onOpen,
  });

  final SupportiveCard card;
  final VoidCallback onOpen;

  static const destinationIds = <String>[
    'concept-my-requests',
    'concept-my-introductions',
    'concept-my-ended',
  ];

  static bool isDestination(String id) => destinationIds.contains(id);

  IconData get _icon => switch (card.id) {
    'concept-my-requests' => Icons.inbox_outlined,
    'concept-my-introductions' => Icons.groups_outlined,
    'concept-my-ended' => Icons.history_rounded,
    _ => Icons.arrow_forward_rounded,
  };

  TextStyle _titleStyle(double size) => ZyraText.body(
    size: size,
    color: ZyraColors.foreground,
  ).copyWith(height: 1.4);

  bool _wholeWordsFit(BuildContext context, double width, double size) {
    final style = _titleStyle(size);
    for (final word in card.title.trim().split(RegExp(r'\s+'))) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final fits = painter.width <= width;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }

  Widget _iconBadge() => ExcludeSemantics(
    child: Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ZyraColors.surfaceEmphasisFill,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        _icon,
        size: 22,
        color: ZyraColors.isLightPalette
            ? ZyraColors.luxuryDarkPurple
            : ZyraColors.journeyGold,
      ),
    ),
  );

  Widget _chevron() => ExcludeSemantics(
    child: Icon(
      Icons.chevron_right_rounded,
      size: 20,
      color: ZyraColors.foregroundSecondary,
    ),
  );

  Widget _detail(String? detail) => detail == null || detail.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            detail,
            style: ZyraText.body(
              size: 12,
              color: ZyraColors.foregroundSecondary,
            ).copyWith(height: 1.6),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final detail = card.detail?.trim();
    return Material(
      key: ValueKey('my-zyra-item-${card.id}'),
      color: ZyraColors.surfaceFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: ZyraColors.surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('my-zyra-route-${card.id}'),
        onTap: ZyraTapFeedback.onTap(context, onOpen),
        child: Semantics(
          key: card.hasNewActivity
              ? ValueKey('my-zyra-activity-${card.id}')
              : null,
          value: card.hasNewActivity ? 'New activity' : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 98),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final inlineTitleWidth =
                      constraints.maxWidth - 44 - 14 - 12 - 20;
                  final stacked =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                      !_wholeWordsFit(context, inlineTitleWidth, 17);
                  final titleSize = stacked
                      ? [17.0, 16.0, 15.0, 14.0, 13.0, 12.0, 11.0].firstWhere(
                          (size) => _wholeWordsFit(
                            context,
                            constraints.maxWidth,
                            size,
                          ),
                          orElse: () => 11,
                        )
                      : 17.0;
                  if (stacked) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [_iconBadge(), const Spacer(), _chevron()],
                        ),
                        const SizedBox(height: 12),
                        Text(card.title, style: _titleStyle(titleSize)),
                        _detail(detail),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      _iconBadge(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.title, style: _titleStyle(titleSize)),
                            _detail(detail),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _chevron(),
                    ],
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
