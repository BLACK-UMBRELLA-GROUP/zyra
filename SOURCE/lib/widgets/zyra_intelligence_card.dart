// ONE visual idiom for every piece of ZYRA intelligence, everywhere it
// appears. Added 2026-08-11 with data/zyra_journey_intelligence.dart.
//
// It is one widget for the same reason zyra_journey_stages.dart is one map:
// this content shows up at six different points in the Journey, and six
// hand-rolled containers would have drifted into six slightly different
// things within a fortnight. Add a FIELD here before adding a second card.
//
// The label — ZYRA Insight / ZYRA Recommendation / ZYRA Summary — comes from
// the model, never from the call site, so no screen can invent a fourth name
// or slip the word "AI" onto a chip.

import 'package:flutter/material.dart';
import '../data/zyra_journey_intelligence.dart';
import '../data/zyra_membership_catalog.dart';
import '../services/zyra_promotion_engine.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_gold_action_pill.dart';
import 'zyra_locked_feature_upgrade.dart';

class ZyraIntelligenceCard extends StatelessWidget {
  final ZyraIntelligence intelligence;

  /// Tightens the vertical margins for use inside an already-padded list.
  final bool compact;

  const ZyraIntelligenceCard({
    super.key,
    required this.intelligence,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final it = intelligence;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: compact ? 8 : 14),
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: ZyraColors.accentBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZyraColors.accentBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            it.label.toUpperCase(),
            style: ZyraText.chapterLabel(color: ZyraColors.goldText),
          ),
          const SizedBox(height: 8),
          Text(it.body, style: ZyraText.body(size: 13.5)),
          if (it.followUps.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final prompt in it.followUps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 7, right: 9),
                      decoration: const BoxDecoration(
                        color: Color(0x99A9792E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(prompt, style: ZyraText.subtext(size: 12.5)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Visible membership boundary for Journey intelligence. Basic members keep
/// the same Journey layout, see what belongs here, and can deliberately open
/// membership information without gaining or mutating entitlement.
class ZyraIntelligenceInvitation extends StatelessWidget {
  final ZyraIntelligenceKind kind;
  final VoidCallback? onTap;

  const ZyraIntelligenceInvitation({super.key, required this.kind, this.onTap});

  String get _label => switch (kind) {
    ZyraIntelligenceKind.insight => 'ZYRA Insight',
    ZyraIntelligenceKind.recommendation => 'ZYRA Recommendation',
    ZyraIntelligenceKind.summary => 'ZYRA Summary',
  };

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('zyra-intelligence-${kind.name}-locked'),
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 14),
    padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
    decoration: BoxDecoration(
      color: ZyraColors.accentBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ZyraColors.accentBorder, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_rounded, size: 17, color: ZyraColors.journeyGold),
            const SizedBox(width: 8),
            Text(
              _label.toUpperCase(),
              style: ZyraText.chapterLabel(color: ZyraColors.goldText),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Available with ${ZyraMembershipCatalog.seekerOneTitle}.',
          style: ZyraText.body(size: 13.5),
        ),
        const SizedBox(height: 14),
        ZyraGoldActionPill(
          label: 'View ${ZyraMembershipCatalog.seekerOneTitle}',
          icon: Icons.workspace_premium_outlined,
          onPressed:
              onTap ??
              () => openSeekerLockedFeaturePlan(
                context,
                feature: ZyraPromotionFeature.zyraIntelligence,
              ),
        ),
      ],
    ),
  );
}
