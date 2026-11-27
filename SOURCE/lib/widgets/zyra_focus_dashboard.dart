// LOCK15 V2 Focus presentation. Callers own sources, navigation and authority.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import '../theme/zyra_colors.dart';
import '../theme/zyra_preview_spacing.dart';
import '../theme/zyra_text.dart';
import 'floating_nav_bar.dart';
import 'zyra_floating_surface.dart';
import 'zyra_tab_title.dart';
import 'zyra_tap_feedback.dart';
import 'zyra_profiles_components.dart';
import 'zyra_swipe_track.dart';

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
    this.canInteract,
    this.previewControls,
  });
  final String title;
  final String? greeting;
  final List<ZyraFocusItem> items;
  final List<ZyraFocusChip> chips;
  final List<ZyraFocusTile> tiles;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final bool Function()? canInteract;
  final Widget? previewControls;
  @override
  State<ZyraFocusDashboard> createState() => _ZyraFocusDashboardState();
}

class _ZyraFocusDashboardState extends State<ZyraFocusDashboard> {
  late int _index = widget.initialIndex;
  int _render = 0;
  final _track = ZyraSwipeController();

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

  void select(int next, int render) {
    if (!mounted ||
        render != _render ||
        !(widget.canInteract?.call() ?? true)) {
      return;
    }
    if (widget.items.length < 2) return;
    next = next.clamp(0, widget.items.length - 1);
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
    style:
        ZyraText.body(
          size: size,
          color: gold
              ? ZyraColors.goldText
              : muted
              ? ZyraColors.foregroundMuted
              : ZyraColors.foreground,
        ).copyWith(
          fontWeight: ZyraText.minimumReadingWeight(size, weight),
          height: height,
        ),
  );

  Widget button(
    String label,
    VoidCallback callback,
    String? id, {
    bool gold = true,
    required bool Function() canAct,
  }) => Builder(
    builder: (context) => ZyraFloatingSurface(
      radius: 28,
      gold: gold,
      child: TextButton(
        key: id == null ? null : ValueKey(id),
        onPressed: ZyraTapFeedback.onTap(context, callback, canAct: canAct),
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

  Widget _caughtUp() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      text('ALL CAUGHT UP', 11, muted: true),
      const SizedBox(height: 5),
      text('Nothing needs you right now.', 21, weight: FontWeight.w300),
    ],
  );

  Widget _focusItem(int page, bool Function() current) {
    final item = widget.items[page];
    bool active() => current() && page == index;
    return Column(
      key: ValueKey('focus-item-${item.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: ZyraColors.surfaceFill,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 26, color: ZyraColors.journeyGold),
        ),
        const SizedBox(height: 16),
        Text(
          widget.items.length == 1
              ? 'NEEDS YOU'
              : 'NEEDS YOU · ${page + 1} OF ${widget.items.length}',
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
              button(
                item.actionLabel,
                item.onAction,
                item.actionKey,
                canAct: active,
              ),
              if (item.secondaryLabel != null && item.onSecondaryAction != null)
                button(
                  item.secondaryLabel!,
                  item.onSecondaryAction!,
                  item.secondaryKey,
                  gold: false,
                  canAct: active,
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

  Widget tile(
    ZyraFocusTile tile, {
    required double horizontalPadding,
    required double verticalPadding,
  }) => Builder(
    builder: (context) => ZyraFloatingSurface(
      radius: 26,
      child: Material(
        color: ZyraColors.cardSurface,
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
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: ZyraColors.surfaceFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        tile.icon,
                        size: 20,
                        color: ZyraColors.journeyGold,
                      ),
                    ),
                    if (tile.locked)
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: Container(
                          key: ValueKey('${tile.id}_lock_badge'),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ZyraColors.cardSurface,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF3E2E1E,
                                ).withValues(alpha: .18),
                                offset: const Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 11,
                            color: ZyraColors.journeyGold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final available = _tileLabelWidth(
                      context,
                      tile.label,
                      constraints.maxWidth,
                    );
                    final fit = _fitTileLabel(context, tile.label, available);
                    final label = Text(
                      fit.display,
                      key: ValueKey(
                        'focus-tile-label-${tile.id ?? tile.label}',
                      ),
                      semanticsLabel: tile.label,
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: fit.style,
                    );
                    return available == constraints.maxWidth
                        ? label
                        : OverflowBox(
                            maxWidth: available,
                            fit: OverflowBoxFit.deferToChild,
                            child: label,
                          );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  tile.status,
                  textAlign: TextAlign.center,
                  style: ZyraText.body(
                    size: 10.5,
                    color: tile.isNew
                        ? ZyraColors.goldTextStrong
                        : ZyraColors.secondaryStrong,
                  ).copyWith(height: 1.45, letterSpacing: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  double _tileLabelWidth(BuildContext context, String label, double width) {
    // At 375 pt with Larger Text, the locked 'ductions' fragment needs
    // 0.06 pt more than the nominal padded box. Give only the label a
    // quarter point inside the existing inset without moving the tile.
    final compactText =
        width < 66 && MediaQuery.textScalerOf(context).scale(11.5) > 11.5;
    return compactText && label == 'Introductions' ? width + .25 : width;
  }

  static const _smallScreenLabelBreaks = <String, List<String>>{
    'Introductions': ['Intro', 'ductions'],
    'Notifications': ['Notifi', 'cations'],
  };

  // Q180/Q183: these are the syllables of the locked quick-access labels.
  // Only a word wider than its line receives a visible hyphenated break.
  static const _tileLabelSyllables = <String, List<String>>{
    'Journey': ['Jour', 'ney'],
    'Journeys': ['Jour', 'neys'],
    'request': ['re', 'quest'],
    'requests': ['re', 'quests'],
    'Introduction': ['In', 'tro', 'duc', 'tion'],
    'Introductions': ['In', 'tro', 'duc', 'tions'],
    'Notification': ['No', 'ti', 'fi', 'ca', 'tion'],
    'Notifications': ['No', 'ti', 'fi', 'ca', 'tions'],
    'Connect': ['Con', 'nect'],
    'Guardian': ['Guar', 'dian'],
    'Guardians': ['Guar', 'dians'],
    'Ended': ['End', 'ed'],
  };

  ({String display, TextStyle style, double height}) _fitTileLabel(
    BuildContext context,
    String value,
    double available,
  ) {
    final width = available.clamp(1.0, double.infinity).toDouble();
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final inherited = DefaultTextStyle.of(context).style;
    var style = inherited
        .merge(ZyraText.body(size: 11.5))
        .copyWith(fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.25);
    double measure(String text, TextStyle atStyle) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: atStyle),
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final result = painter.width;
      painter.dispose();
      return result;
    }

    final words = value.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    double longest(double size) {
      var result = 0.0;
      for (final word in words) {
        final measured = measure(word, style.copyWith(fontSize: size));
        if (measured > result) result = measured;
      }
      return result;
    }

    // Check the actual scaler rather than replacing it with a linear or
    // no-scaling override. Larger Text retains its selected size unchanged.
    final standardScale =
        (scaler.scale(11.5) - 11.5).abs() < .0001 &&
        (scaler.scale(10) - 10).abs() < .0001;
    if (standardScale && longest(11.5) > width) {
      var low = 10.0;
      var high = 11.5;
      if (longest(low) <= width) {
        for (var step = 0; step < 24; step++) {
          final middle = (low + high) / 2;
          if (longest(middle) <= width) {
            low = middle;
          } else {
            high = middle;
          }
        }
      }
      style = style.copyWith(fontSize: low);
    }

    final lines = <String>[];
    for (final paragraph in value.split('\n')) {
      var line = '';
      void flush() {
        if (line.isNotEmpty) lines.add(line);
        line = '';
      }

      for (final word in paragraph.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        if (measure(word, style) <= width) {
          final joined = line.isEmpty ? word : '$line $word';
          if (measure(joined, style) <= width) {
            line = joined;
          } else {
            flush();
            line = word;
          }
          continue;
        }
        final preferred = _smallScreenLabelBreaks[word];
        final syllables = List<String>.of(
          preferred != null &&
                  measure('${preferred.first}-', style) <= width &&
                  measure(preferred.last, style) <= width
              ? preferred
              : _tileLabelSyllables[word] ?? [word],
        );
        while (syllables.isNotEmpty) {
          final prefix = line.isEmpty ? '' : '$line ';
          var count = 0;
          var fragment = '';
          for (var end = 1; end <= syllables.length; end++) {
            final candidate =
                syllables.take(end).join() +
                (end < syllables.length ? '-' : '');
            if (measure('$prefix$candidate', style) > width) break;
            count = end;
            fragment = candidate;
          }
          if (count == 0 && line.isNotEmpty) {
            flush();
            continue;
          }
          // Do not invent a letter-level split for an uncatalogued word or
          // an indivisible syllable. The rendered fit gate reports it.
          if (count == 0) {
            line = syllables.join();
            syllables.clear();
          } else {
            line = '$prefix$fragment';
            syllables.removeRange(0, count);
            if (syllables.isNotEmpty) flush();
          }
        }
      }
      flush();
    }
    final display = lines.join('\n');
    final painter = TextPainter(
      text: TextSpan(text: display, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return (display: display, style: style, height: height);
  }

  double tileHeight(
    BuildContext context,
    double width,
    double horizontalPadding,
  ) {
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
              .copyWith(
                height: lineHeight,
                letterSpacing: 0,
                fontWeight: ZyraText.minimumReadingWeight(
                  size,
                  FontWeight.w300,
                ),
              ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: available.clamp(1, double.infinity));
      return painter.height;
    }

    final textWidth = width - 2 * horizontalPadding;
    var result = 0.0;
    for (final tile in widget.tiles) {
      final label = _fitTileLabel(
        context,
        tile.label,
        _tileLabelWidth(context, tile.label, textWidth),
      );
      final value =
          84 + label.height + height(tile.status, 10.5, textWidth, 1.45);
      if (value > result) result = value;
    }
    return result.ceilToDouble() + 1;
  }

  Widget _tiles(BuildContext context, BoxConstraints bounds, double bottom) {
    final width =
        (bounds.maxWidth -
            2 * ZyraPreviewSpacing.pageMargin -
            (widget.tiles.length - 1) * ZyraPreviewSpacing.cardToCard) /
        widget.tiles.length;
    // The older 320 pt viewport can fit a large-text tile at the scroll end
    // by spending up to eight points less on its vertical padding.
    final compact =
        bounds.maxWidth <= 320 &&
        MediaQuery.textScalerOf(context).scale(14) > 14;
    // At 320 pt the 12 pt gaps take 3 pt from each of the four tiles.
    // Keep the original Larger Text content width inside the tile.
    final horizontalPadding = compact ? 3.5 : 5.0;
    final naturalHeight = tileHeight(context, width, horizontalPadding);
    final recovered = compact
        ? (naturalHeight - (bounds.maxHeight - bottom))
              .clamp(0.0, 8.0)
              .toDouble()
        : 0.0;
    return SizedBox(
      height: naturalHeight - recovered,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: ZyraPreviewSpacing.cardToCard),
            Expanded(
              child: tile(
                widget.tiles[i],
                horizontalPadding: horizontalPadding,
                verticalPadding: 14 - recovered / 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final render = ++_render;
    final bottom = ZyraNavBarMetrics.contentBottomClearance(context);
    const top = 16.0;
    bool current() =>
        mounted && render == _render && (widget.canInteract?.call() ?? true);
    final content = SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, bounds) => ZyraShadowScrollView(
          key: const PageStorageKey('my-zyra-focus-scroll'),
          padding: EdgeInsets.fromLTRB(
            ZyraPreviewSpacing.pageMargin,
            top,
            ZyraPreviewSpacing.pageMargin,
            bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (bounds.maxHeight - top - bottom).clamp(
                0,
                double.infinity,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ZyraTabTitle(widget.title),
                    if (widget.greeting != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        widget.greeting!,
                        style: ZyraText.subtext(size: 12.5),
                      ),
                    ],
                    if (widget.items.length > 1) ...[
                      const SizedBox(height: ZyraPreviewSpacing.titleToDots),
                      ZyraProfilesDots(
                        count: widget.items.length,
                        index: index,
                        dotKey: (i) => ValueKey('focus-dot-$i'),
                        targetKey: (i) => ValueKey('focus-dot-target-$i'),
                        itemLabel: (i) =>
                            'Item ${i + 1} of ${widget.items.length}',
                        canAct: current,
                        onSelected: (i) {
                          if (current()) _track.animateTo(i);
                        },
                      ),
                    ],
                    if (widget.previewControls != null) widget.previewControls!,
                  ],
                ),
                Padding(
                  key: const ValueKey('focus-area'),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: widget.items.isEmpty
                      ? _caughtUp()
                      : ZyraSwipeTrack(
                          controller: _track,
                          index: index,
                          itemCount: widget.items.length,
                          canAct: current,
                          dragEnabled: false,
                          onDragSettled: ZyraTapFeedback.onTap(
                            context,
                            () {},
                            canAct: current,
                          ),
                          onSettled: (i) => select(i, render),
                          itemBuilder: (context, page) =>
                              _focusItem(page, current),
                        ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.chips.isNotEmpty) ...[
                      Wrap(
                        key: const ValueKey('tour_status_pills'),
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.chips.map(chip).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],
                    KeyedSubtree(
                      key: const ValueKey('tour_quick_access'),
                      child: _tiles(context, bounds, bottom),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return ZyraSwipeGesture(
      key: const ValueKey('my-zyra-whole-page-swipe'),
      controller: _track,
      canStartAt: (position) {
        final box = context.findRenderObject();
        if (box is! RenderBox || !box.hasSize) return false;
        final barTop = box.size.height - bottom + ZyraNavBarMetrics.contentGap;
        return position.dy < barTop;
      },
      child: content,
    );
  }
}
