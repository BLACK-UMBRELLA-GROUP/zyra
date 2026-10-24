import 'package:flutter/material.dart';

import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// Caller-owned display facts. A portrait, when present, is prepared by the
/// caller; this presenter never looks up a member or loads an image itself.
class ZyraRequestCapacityItem {
  const ZyraRequestCapacityItem({
    required this.id,
    required this.name,
    this.subtitle,
    this.portrait,
  });

  final String id;
  final String name;
  final String? subtitle;
  final Widget? portrait;
}

/// Passive full-capacity choice. Selection and continuation are callbacks,
/// not authority to end a Journey, accept a request or change membership.
class ZyraRequestCapacityChoice extends StatelessWidget {
  const ZyraRequestCapacityChoice({
    super.key,
    required this.firstName,
    required this.capacity,
    required this.items,
    required this.onSelected,
    required this.onCancel,
    this.selectedId,
    this.onContinue,
  });

  final String firstName;
  final int capacity;
  final List<ZyraRequestCapacityItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final canContinue =
        onContinue != null &&
        selectedId != null &&
        items.any((item) => item.id == selectedId);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const ValueKey('request_capacity_choice'),
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    value:
                        '$capacity Journey ${capacity == 1 ? 'place' : 'places'} in use',
                    child: Text(
                      'Your Journey places are full.',
                      style: ZyraText.heading(size: 26).copyWith(height: 1.2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a Journey to end before beginning with $firstName, '
                    'or cancel this request.',
                    style: ZyraText.subtext(size: 14).copyWith(height: 1.4),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      if (index > 0)
                        const SizedBox(height: ZyraCardMetrics.spacing),
                      _CapacityRow(
                        item: items[index],
                        selected: items[index].id == selectedId,
                        onSelected: onSelected,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    key: const ValueKey('request_capacity_continue'),
                    onPressed: canContinue ? onContinue : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      foregroundColor: ZyraColors.journeyGold,
                      disabledForegroundColor: ZyraColors.ink(.4),
                      backgroundColor: canContinue
                          ? ZyraColors.journeyGold.withValues(alpha: .08)
                          : Colors.transparent,
                      side: BorderSide(
                        color: canContinue
                            ? ZyraColors.journeyGold.withValues(alpha: .75)
                            : ZyraColors.surfaceBorder,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'End Journey & continue',
                      textAlign: TextAlign.center,
                      style: ZyraText.button(
                        size: 13,
                        color: canContinue
                            ? ZyraColors.journeyGold
                            : ZyraColors.ink(.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      key: const ValueKey('request_capacity_cancel'),
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        foregroundColor: ZyraColors.foregroundSecondary,
                      ),
                      child: Text(
                        'Cancel request',
                        style: ZyraText.button(
                          size: 13,
                          color: ZyraColors.foregroundSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapacityRow extends StatelessWidget {
  const _CapacityRow({
    required this.item,
    required this.selected,
    required this.onSelected,
  });

  final ZyraRequestCapacityItem item;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.subtitle?.trim();
    final radius = BorderRadius.circular(ZyraCardMetrics.cardRadius);
    void select() => onSelected(item.id);
    return Semantics(
      key: ValueKey('request_capacity_journey_${item.id}'),
      label: item.name,
      value: subtitle,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      onTap: select,
      excludeSemantics: true,
      child: Material(
        color: ZyraColors.surfaceFill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? ZyraColors.journeyGold : ZyraColors.surfaceBorder,
            width: selected ? 1.4 : .8,
          ),
        ),
        child: InkWell(
          onTap: select,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(ZyraCardMetrics.padding),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      ZyraCardMetrics.thumbRadius,
                    ),
                    child: SizedBox(
                      width: ZyraCardMetrics.thumb,
                      height: ZyraCardMetrics.thumb,
                      child:
                          item.portrait ??
                          ColoredBox(
                            color: ZyraColors.ink(.08),
                            child: Icon(
                              Icons.person_outline,
                              size: 24,
                              color: ZyraColors.ink(.6),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: ZyraCardMetrics.gap),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: ZyraText.heading(size: 17)),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(subtitle, style: ZyraText.subtext(size: 12)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected
                        ? ZyraColors.journeyGold
                        : ZyraColors.ink(.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
