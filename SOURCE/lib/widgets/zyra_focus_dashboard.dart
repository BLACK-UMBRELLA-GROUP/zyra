// LOCK15 V2 Focus presentation. Callers own sources, navigation and authority.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_floating_surface.dart';
import 'zyra_tap_feedback.dart';

class ZyraFocusItem {
  const ZyraFocusItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    this.actionKey,
    this.secondaryLabel,
    this.onSecondaryAction,
    this.secondaryKey,
  });
  final String id, title, detail, actionLabel;
  final IconData icon;
  final VoidCallback onAction;
  final String? actionKey, secondaryLabel, secondaryKey;
  final VoidCallback? onSecondaryAction;
}

class ZyraFocusChip {
  const ZyraFocusChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.id,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? id;
}

class ZyraFocusTile {
  const ZyraFocusTile({
    required this.label,
    required this.status,
    required this.icon,
    required this.onTap,
    this.isNew = false,
    this.locked = false,
    this.id,
  });
  final String label, status;
  final IconData icon;
  final VoidCallback onTap;
  final bool isNew, locked;
  final String? id;
}

class ZyraFocusDashboard extends StatefulWidget {
  const ZyraFocusDashboard({
    super.key,
    this.title = 'My ZYRA',
    this.greeting,
    required this.items,
    required this.chips,
    required this.tiles,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.previewControls,
  });
  final String title;
  final String? greeting;
  final List<ZyraFocusItem> items;
  final List<ZyraFocusChip> chips;
  final List<ZyraFocusTile> tiles;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final Widget? previewControls;
  @override
  State<ZyraFocusDashboard> createState() => _ZyraFocusDashboardState();
}

class _ZyraFocusDashboardState extends State<ZyraFocusDashboard> {
  late int _index = widget.initialIndex;
  int get index =>
      widget.items.isEmpty ? 0 : _index.clamp(0, widget.items.length - 1);
  @override
  void didUpdateWidget(ZyraFocusDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _index = widget.initialIndex;
    }
    _index = index;
  }

  void step(int delta) {
    if (widget.items.length < 2) return;
    final next = (index + delta).clamp(0, widget.items.length - 1);
    if (next == index) return;
    setState(() => _index = next);
    widget.onIndexChanged?.call(next);
  }

  Widget text(
    String value,
    double size, {
    bool muted = false,
    bool gold = false,
    FontWeight weight = FontWeight.w300,
    double height = 1.45,
  }) => Text(
    value,
    textAlign: TextAlign.center,
    style: ZyraText.body(
      size: size,
      color: gold
          ? ZyraColors.goldText
          : muted
          ? ZyraColors.foregroundMuted
          : ZyraColors.foreground,
    ).copyWith(fontWeight: weight, height: height),
  );

  Widget button(
    String label,
    VoidCallback callback,
    String? id, {
    bool gold = true,
  }) => Builder(
    builder: (context) => ZyraFloatingSurface(
      radius: 28,
      gold: gold,
      child: TextButton(
        key: id == null ? null : ValueKey(id),
        onPressed: ZyraTapFeedback.onTap(context, callback),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          backgroundColor: gold
              ? ZyraColors.primaryAction
              : ZyraColors.surfaceFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: gold ? Colors.transparent : ZyraColors.surfaceBorder,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: ZyraText.body(
            size: 14,
            color: gold ? ZyraColors.onPrimaryAction : ZyraColors.foreground,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    ),
  );

  Widget balancedTitle(String title) => LayoutBuilder(
    builder: (context, box) {
      final style = ZyraText.body(
        size: 25,
      ).copyWith(fontWeight: FontWeight.w300, height: 1.25);
      double width(String value) {
        final painter = TextPainter(
          text: TextSpan(text: value, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        return painter.width;
      }

      var balanced = title;
      if (!title.contains('\n') && width(title) > box.maxWidth) {
        final words = title.split(' ');
        var difference = double.infinity;
        for (var i = 1; i < words.length; i++) {
          final first = words.take(i).join(' '),
              second = words.skip(i).join(' ');
          final firstWidth = width(first), secondWidth = width(second);
          final gap = (firstWidth - secondWidth).abs();
          if (firstWidth <= box.maxWidth &&
              secondWidth <= box.maxWidth &&
              gap < difference) {
            balanced = '$first\n$second';
            difference = gap;
          }
        }
      }
      return Text(balanced, textAlign: TextAlign.center, style: style);
    },
  );

  Widget focus() {
    if (widget.items.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          text('ALL CAUGHT UP', 11, muted: true),
          const SizedBox(height: 5),
          text('Nothing needs you right now.', 21, weight: FontWeight.w300),
        ],
      );
    }
    final item = widget.items[index];
    return Column(
      key: ValueKey('focus-item-${item.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: ZyraColors.frostFill.withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 26, color: ZyraColors.journeyGold),
        ),
        const SizedBox(height: 16),
        Text(
          widget.items.length == 1
              ? 'NEEDS YOU'
              : 'NEEDS YOU · ${index + 1} OF ${widget.items.length}',
          style: ZyraText.body(
            size: 11.5,
            color: ZyraColors.goldText,
          ).copyWith(letterSpacing: .5),
        ),
        const SizedBox(height: 12),
        balancedTitle(item.title),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: text(item.detail, 12.5, muted: true),
        ),
        if (item.actionLabel.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              button(item.actionLabel, item.onAction, item.actionKey),
              if (item.secondaryLabel != null && item.onSecondaryAction != null)
                button(
                  item.secondaryLabel!,
                  item.onSecondaryAction!,
                  item.secondaryKey,
                  gold: false,
                ),
            ],
          ),
        ],
        if (widget.items.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const ValueKey('focus-previous'),
                tooltip: 'Previous item',
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                padding: const EdgeInsets.only(bottom: 24),
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                onPressed: index == 0
                    ? null
                    : ZyraTapFeedback.onTap(context, () => step(-1)),
                icon: const Icon(Icons.chevron_left, size: 16),
                color: ZyraColors.foreground,
                disabledColor: ZyraColors.foregroundMuted.withValues(alpha: .5),
              ),
              for (var i = 0; i < widget.items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == index ? 30 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == index
                          ? ZyraColors.journeyGold
                          : ZyraColors.foregroundMuted.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              IconButton(
                key: const ValueKey('focus-next'),
                tooltip: 'Next item',
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                padding: const EdgeInsets.only(bottom: 24),
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                onPressed: index == widget.items.length - 1
                    ? null
                    : ZyraTapFeedback.onTap(context, () => step(1)),
                icon: const Icon(Icons.chevron_right, size: 16),
                color: ZyraColors.foreground,
                disabledColor: ZyraColors.foregroundMuted.withValues(alpha: .5),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget chip(ZyraFocusChip chip) => Builder(
    builder: (context) => ZyraFloatingSurface(
      radius: 28,
      child: TextButton(
        key: chip.id == null ? null : ValueKey(chip.id!),
        onPressed: ZyraTapFeedback.onTap(context, chip.onTap),
        style: TextButton.styleFrom(
          backgroundColor: ZyraColors.surfaceFill,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: ZyraColors.surfaceBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(chip.icon, size: 16, color: ZyraColors.journeyGold),
            const SizedBox(width: 8),
            Flexible(child: text(chip.label, 12)),
          ],
        ),
      ),
    ),
  );

  Widget tile(ZyraFocusTile tile) => Builder(
    builder: (context) => ZyraFloatingSurface(
      radius: 26,
      child: Material(
        color: ZyraColors.surfaceFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: ZyraColors.surfaceBorder),
        ),
        child: InkWell(
          key: tile.id == null ? null : ValueKey(tile.id!),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          onTap: ZyraTapFeedback.onTap(context, tile.onTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ZyraColors.frostFill.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tile.icon,
                    size: 20,
                    color: ZyraColors.journeyGold,
                  ),
                ),
                const SizedBox(height: 8),
                text(tile.label, 11.5, height: 1.25),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (tile.locked) ...[
                      Icon(
                        Icons.lock_outline,
                        size: 13,
                        color: ZyraColors.foregroundMuted,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: text(
                        tile.status,
                        10.5,
                        muted: !tile.isNew,
                        gold: tile.isNew,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  double tileHeight(BuildContext context, double width) {
    double height(
      String value,
      double size,
      double available,
      double lineHeight,
    ) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: DefaultTextStyle.of(context).style
              .merge(ZyraText.body(size: size))
              .copyWith(height: lineHeight, fontWeight: FontWeight.w300),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: available.clamp(1, double.infinity));
      return painter.height;
    }

    var result = 0.0;
    for (final tile in widget.tiles) {
      final value =
          84 +
          height(tile.label, 11.5, width - 10, 1.25) +
          height(tile.status, 10.5, width - 10 - (tile.locked ? 17 : 0), 1.45);
      if (value > result) result = value;
    }
    return result.ceilToDouble() + 1;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, bounds) => ZyraShadowScrollView(
        key: const PageStorageKey('my-zyra-focus-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (bounds.maxHeight - 116).clamp(0, double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.title,
                    style: ZyraText.heading(
                      size: 28,
                    ).copyWith(fontWeight: FontWeight.w300, height: 1.2),
                  ),
                  if (widget.greeting != null) ...[
                    const SizedBox(height: 14),
                    Text(widget.greeting!, style: ZyraText.subtext(size: 12.5)),
                  ],
                  if (widget.previewControls != null) widget.previewControls!,
                ],
              ),
              GestureDetector(
                key: const ValueKey('focus-area'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() < 100) return;
                  ZyraTapFeedback.onTap(
                    context,
                    () => step(velocity < 0 ? 1 : -1),
                  )?.call();
                },
                child: Padding(
                  // The visible pager is 20px. Its 44px touch boxes extend 24px
                  // below that paint; balancing space above preserves centring.
                  padding: EdgeInsets.only(
                    top: widget.items.length > 1 ? 48 : 24,
                    bottom: 24,
                  ),
                  child: focus(),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.chips.isNotEmpty) ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.chips.map(chip).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    height: tileHeight(
                      context,
                      (bounds.maxWidth - 40 - (widget.tiles.length - 1) * 8) /
                          widget.tiles.length,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < widget.tiles.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: tile(widget.tiles[i])),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
