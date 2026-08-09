// Help/Report menu — centred glass card.
//
// PRESENTATION HISTORY, because this has moved four times and the reasons
// matter more than the moves:
//
//   1. anchored card from a top-right "..." icon
//   2. centred showDialog card, dark glass
//   3. bottom sheet in the solid brand gradient  (2026-07-27)
//   4. bottom sheet, dark translucent glass      (2026-07-27, 3rd pass)
//   5. bottom sheet, ratified gender gradient    (2026-08-01)
//   6. CENTRED GLASS CARD                        (2026-08-01, current)
//
// The file was `help_report_card.dart` / class `HelpReportCard` through
// stages 1–2 and was renamed at stage 3 to match what it had become. The
// name stays `HelpReportSheet` now despite being a card again — renaming
// it back would churn every call site for no gain, and the class doc says
// what it is.
//
// STAGE 6 (Founder: "the holding down to help and support — let's see how
// it looks with this similar centre piece transparent effect").
//
// The reference is _showCapReachedModal in browse_screen.dart, and the
// values below are copied from it rather than re-picked:
//
//   blur 30 · white 0.14 fill · white 0.22 border · radius 24 · inset 36
//
// Note this deliberately DROPS the gender gradient added earlier the same
// day. That was the right answer for a bottom sheet — a sheet anchored to
// the screen edge should be continuous with the screen behind it. A
// centred card is the opposite: it floats, nothing anchors it, and it
// should read as glass over the photo rather than as a piece of the page.
// The save-limit modal already established that language; two centred
// cards on the same screen wearing different materials would be the
// inconsistency.
//
// Opened via showDialog from browse_screen.dart's long-press-centre
// gesture (_openHelpReportSheet) — see that file's header for the gesture
// history, including why the hold is 300ms and not Flutter's default.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/zyra_text.dart';

class HelpReportSheet extends StatelessWidget {
  final VoidCallback onHelp;
  final VoidCallback onReport;

  /// Retained for call-site compatibility and deliberately unused while
  /// this renders as a centred card — see the stage-6 note above. If it
  /// ever returns to being an anchored sheet, this is what the gender
  /// gradient needs.
  final String? gender;

  const HelpReportSheet({
    super.key,
    required this.onHelp,
    required this.onReport,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        // OUTSIDE the ClipRRect, not on the Container inside it. The
        // save-limit modals had it the other way round and rendered a
        // second ghost frame 36pt wider than the card on every side
        // (Founder, 2026-08-01: "two extra transparent frames sticking
        // out"). Same trap, avoided here by construction.
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The drag handle went with the bottom sheet. A
                    // centred card is not draggable, and a handle on one
                    // would be an affordance that does nothing.
                    //
                    // SPLIT 2026-08-01 (Founder: "the 2 options open the
                    // same thing"). Both rows used to push
                    // HelpSupportScreen, so there was no way to report
                    // anyone in ZYRA at all. They are now genuinely
                    // different destinations:
                    //
                    //   Report  -> about a PERSON. Reason list, writes to
                    //              profile_reports, blocks them.
                    //   Help    -> about the APP. Billing, bugs, how
                    //              things work. No subject.
                    //
                    // Subtitles were added and removed the same day
                    // (Founder: "it doesn't seem correct to write
                    // 'something wrong with this person'"). Correct call —
                    // they were solving a problem that stopped existing
                    // the moment the two rows pointed somewhere different.
                    _Row(
                      icon: Icons.flag_outlined,
                      label: 'Report this profile',
                      onTap: onReport,
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.12),
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _Row(
                      icon: Icons.help_outline,
                      label: 'Help and support',
                      onTap: onHelp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 14),
              Text(label, style: ZyraText.body(size: 15, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
