import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import 'zyra_guardian_circle_topic_options.dart';

/// One fixed floating container. Only its interior varies; the Circle owns
/// the route, admitted catalogs, snapshot and every guarded callback.
class ZyraCircleDiscussionPickerPresentation extends StatelessWidget {
  const ZyraCircleDiscussionPickerPresentation({
    super.key,
    required this.design,
    required this.currentTopics,
    required this.pastTopics,
    required this.selected,
    required this.canSelect,
    required this.onSelected,
    required this.onClose,
    this.launcherBounds,
  });

  final ZyraCircleBubbleDesign design;
  final List<ZyraCircleDiscussionTopic> currentTopics;
  final List<ZyraCircleDiscussionTopic> pastTopics;
  final ZyraCircleDiscussionTopic selected;
  final bool Function() canSelect;
  final ValueChanged<ZyraCircleDiscussionTopic> onSelected;
  final VoidCallback onClose;

  /// Bounds in the owning Navigator overlay, not global screen coordinates.
  final Rect? launcherBounds;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final padding = MediaQuery.paddingOf(context);
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        final keyboardReading =
            keyboard > 0 && MediaQuery.textScalerOf(context).scale(13) >= 20;
        final safe = Rect.fromLTRB(
          padding.left,
          padding.top,
          math.max(padding.left, constraints.maxWidth - padding.right),
          math.max(
            padding.top,
            constraints.maxHeight - math.max(padding.bottom, keyboard),
          ),
        );
        const margin = 14.0;
        final width = math.max(0.0, math.min(safe.width - margin * 2, 380.0));
        final maxHeight = math.max(0.0, safe.height - 24);
        if (width <= 0 || maxHeight <= 24) return const SizedBox.shrink();
        final height = math.min(
          maxHeight,
          keyboardReading ? maxHeight : math.min(560.0, safe.height * .78),
        );
        final anchor = launcherBounds;
        final left = anchor != null
            ? anchor.left
                  .clamp(safe.left + margin, safe.right - margin - width)
                  .toDouble()
            : safe.left + (safe.width - width) / 2;
        final top = ((anchor?.top ?? safe.bottom) - height - 12)
            .clamp(safe.top + 12, safe.bottom - height - 12)
            .toDouble();
        final radius = BorderRadius.circular(22);
        return Stack(
          children: [
            Positioned(
              key: const ValueKey('circle_picker_floating_surface'),
              left: left,
              top: top,
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ZyraColors.modalSheetSurface,
                  borderRadius: radius,
                  border: Border.all(
                    color: ZyraColors.journeyGold.withValues(alpha: .3),
                    width: .8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .25),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: ZyraCircleTopicPicker(
                      currentTopics: currentTopics,
                      pastTopics: pastTopics,
                      selected: selected,
                      canSelect: canSelect,
                      onSelected: onSelected,
                      embedded: true,
                      showGeneralConversation: false,
                      bubbleDesign: design,
                      onClose: onClose,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
