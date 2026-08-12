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
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

class ZyraIntelligenceCard extends StatelessWidget {
  final ZyraIntelligence intelligence;

  /// Tightens the vertical margins for use inside an already-padded list.
  final bool compact;

  const ZyraIntelligenceCard({super.key, required this.intelligence, this.compact = false});

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
            style: ZyraText.chapterLabel(color: const Color(0xCCD8BEEE)),
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
                        color: Color(0x99D8BEEE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(child: Text(prompt, style: ZyraText.subtext(size: 12.5))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The ZYRA Basic side of the same moment.
///
/// Deliberately NOT a card: no border, no fill, no lock icon, no blurred
/// number behind it. It borrows the privacy-indicator idiom already used in
/// onboarding and on Compatibility Unlock — a small dot and one line of plain
/// text — because "upgrade prompts must feel like a natural invitation, not a
/// paywall" (AI TIERING), and because the screen it sits on is complete
/// without it.
///
/// Pass null intelligence and render nothing at all where even this is too
/// much. That is a legitimate call.
class ZyraIntelligenceInvitation extends StatelessWidget {
  final ZyraIntelligenceKind kind;
  final VoidCallback? onTap;

  const ZyraIntelligenceInvitation({super.key, required this.kind, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 5, right: 9),
              decoration: const BoxDecoration(
                color: ZyraColors.privateDot,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                ZyraJourneyIntelligence.invitationFor(kind),
                style: ZyraText.privacyText(color: ZyraColors.privateText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
