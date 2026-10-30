// The app's top segmented pill — frosted glass, a single sliding fill,
// labels that brighten and dim continuously with the gesture.
//
// EXTRACTED 2026-08-13 (Founder: "in Network section at top we have
// Discover and Requests but make it same as Seeker's Connections page top
// slider pill"). It lived as a private class inside connections_screen.dart
// with a hardcoded three-label list, so the Guardian side could not use it
// and had grown its own pair of plain rounded buttons instead — two
// controls doing one job, looking nothing alike.
//
// Nothing about the appearance or behaviour changed in the move. The only
// difference is that the labels are a parameter now, so the fill divides by
// however many there are.
//
// The retained Founder-ratified design decisions:
//
//  · A SLIDING FILL, not independently-tinted segments (2026-08-03). The
//    old version coloured whichever segment was selected, which cannot
//    render "60% of the way across". One box positioned by `position` can,
//    which is what lets it travel with a swipe instead of snapping at the
//    end of it.
//  · Unseen counts remain available to accessibility without painting
//    notification dots. Selection fill, lock icons and swipe motion remain.

import 'zyra_tap_feedback.dart';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// The Connections selector is the app-wide motion reference.
///
/// Keep tap travel and swipe settling here so two-, three- and four-segment
/// controls differ only in distance, never in timing or resistance.
abstract final class ZyraSegmentedMotion {
  static const Duration selectionDuration = Duration(milliseconds: 260);
  static const Curve selectionCurve = Curves.easeOutCubic;
  static const ScrollPhysics pagePhysics = PageScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  static Future<void> animateToPage(PageController controller, int page) =>
      controller.animateToPage(
        page,
        duration: selectionDuration,
        curve: selectionCurve,
      );
}

class ZyraSegmentedToggle extends StatelessWidget {
  /// Segment labels, left to right. The fill divides by however many are
  /// given; callers currently use between two and four.
  final List<String> labels;

  /// 0.0 = first segment, 1.0 = second, and so on — fractional values are
  /// mid-swipe positions, which is the whole point of this control. Feed it
  /// a PageController's live `page` value, not the settled index.
  final double position;

  /// Segment index to move to.
  final ValueChanged<int> onChanged;

  /// Accessibility unseen count per segment, same order as [labels].
  /// Omit entirely where nothing is ever unseen. No visual badge is painted.
  final List<int> badges;

  /// Label size. 11.5 is right for three segments — at 13pt
  /// "Introductions" ellipsises inside a third of a phone, and a truncated
  /// label on a control this small reads as a bug. With two segments there
  /// is room for 13. Four-segment callers use a smaller explicit size.
  final double labelSize;

  /// Optional keys for each interactive segment. This preserves direct
  /// accessibility and test targets for screens using this shared control.
  final List<Key> segmentKeys;

  /// Segments that remain visible but need a higher membership. A small gold
  /// lock communicates the boundary without changing the app's structure.
  final Set<int> lockedIndexes;

  // [icons] and [showFill] lived here for a few hours on 2026-08-13
  // (DR-ZYRA-153), added so Browse's action bar could be this control.
  // REMOVED the same day (DR-ZYRA-155): that bar now has to match the
  // nav bar's own shell, not this one's, so it draws its own segments
  // and these two fields had no caller left. A parameter kept for a
  // user that no longer exists is the machinery this file's neighbours
  // delete on sight. Git has them if a second selector ever wants icons.

  const ZyraSegmentedToggle({
    super.key,
    required this.labels,
    required this.position,
    required this.onChanged,
    this.badges = const [],
    this.labelSize = 11.5,
    this.segmentKeys = const [],
    this.lockedIndexes = const {},
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ZyraColors.frostFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ZyraColors.frostBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: LayoutBuilder(
              builder: (context, c) {
                final seg = c.maxWidth / labels.length;
                return SizedBox(
                  height: 34,
                  child: Stack(
                    children: [
                      Positioned(
                        left: position * seg,
                        top: 0,
                        bottom: 0,
                        width: seg,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: ZyraColors.frostSelectedFill,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: ZyraColors.frostSelectedBorder,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < labels.length; i++)
                            Expanded(
                              child: _label(
                                labels[i],
                                // Distance from this segment, clamped — the
                                // label is fully lit at its own index and
                                // dims as the fill leaves it, in either
                                // direction.
                                (1 - (position - i).abs()).clamp(0.0, 1.0),
                                () => onChanged(i),
                                badges.length > i ? badges[i] : 0,
                                segmentKeys.length > i ? segmentKeys[i] : null,
                                lockedIndexes.contains(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// `weight` runs 0..1 with the fill, so labels brighten and dim
  /// continuously rather than swapping at the end of the gesture.
  Widget _label(
    String text,
    double weight,
    VoidCallback onTap,
    int badge,
    Key? key,
    bool locked,
  ) {
    return Builder(
      builder: (context) => Semantics(
        label: locked ? '$text, locked, upgrade available' : text,
        value: badge > 0 ? (badge == 1 ? '1 unseen' : '$badge unseen') : null,
        button: true,
        child: GestureDetector(
          key: key,
          onTap: ZyraTapFeedback.onTap(context, onTap),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZyraText.button(
                      size: labelSize,
                      color: ZyraColors.ink(0.45 + (0.55 * weight)),
                    ),
                  ),
                ),
                if (locked)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Icon(
                      Icons.lock_rounded,
                      key: ValueKey('segmented-$text-lock'),
                      size: 11,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
