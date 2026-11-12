import '../widgets/zyra_floating_surface.dart';
// Founder-selected Soft cards for caller-owned requests and Introductions.
// No member reads, preference writes, request decisions or acknowledgement.
import '../widgets/zyra_tap_feedback.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../screens/connections/connections_section_controller.dart';
import '../theme/zyra_motion.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_preview_spacing.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_segmented_toggle.dart';
import '../widgets/zyra_state_widgets.dart';
import '../widgets/floating_nav_bar.dart';
import 'zyra_one_journey_discovery_presentation.dart'
    show ZyraOneJourneyConnectionsAction;

Color get _helperInk => Color.alphaBlend(
  ZyraColors.ink(.80),
  ZyraColors.isLightPalette ? Colors.white : ZyraColors.luxuryDarkPurple,
);

// Text/icon ink must not inherit the older 45%-alpha unlock decoration.
Color get _accentInk => ZyraColors.isLightPalette
    ? ZyraColors.luxuryDarkPurple
    : Color.alphaBlend(
        Colors.white.withValues(alpha: .16),
        ZyraColors.journeyGold,
      );

bool _quietMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.accessibleNavigationOf(context);

Icon _requestActivityChevron(bool open) => Icon(
  open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
  color: _accentInk,
  size: 23,
);

bool _wholeWordsFit(
  BuildContext context,
  String value,
  TextStyle style,
  double availableWidth,
) {
  if (availableWidth <= 0) return false;
  var effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
  if (MediaQuery.boldTextOf(context)) {
    effectiveStyle = effectiveStyle.copyWith(fontWeight: FontWeight.bold);
  }
  for (final word
      in value.split(RegExp(r'\s+')).where((word) => word.isNotEmpty)) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: effectiveStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout();
    final fits = painter.width <= availableWidth;
    painter.dispose();
    if (!fits) return false;
  }
  return true;
}

Widget _requestActivityPortrait(SeekerProfile profile) {
  final photo = profile.photoUrl;
  // A retained URL cannot become a member/network lookup in this renderer.
  final image = photo.startsWith('data:image/')
      ? ZyraProfileImage(photo, width: 64, height: 64)
      : ColoredBox(
          color: ZyraColors.accentOnCanvas.withValues(alpha: .10),
          child: Center(
            child: Text(
              profile.firstName.isEmpty
                  ? '?'
                  : profile.firstName.characters.first,
              style: ZyraText.heading(size: 28, color: _accentInk),
            ),
          ),
        );
  return ClipOval(
    child: SizedBox(
      width: 64,
      height: 64,
      child: ExcludeSemantics(child: image),
    ),
  );
}

/// Owns only presentation/paging. A single-page leaf has no tab selector.
/// The shell owns the selection, current route and every member action.
class ZyraRequestActivityPresentation extends StatefulWidget {
  const ZyraRequestActivityPresentation({
    super.key,
    required this.labels,
    required this.pages,
    required this.selectedIndex,
    required this.onChanged,
    this.canInteract,
    this.segmentKeys = const [],
    this.title = 'Journey requests',
    this.tabClearance = false,
  }) : assert(labels.length == pages.length),
       assert(labels.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < labels.length);

  final List<String> labels;
  final List<List<Widget>> pages;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool Function()? canInteract;
  final List<Key> segmentKeys;
  final String title;
  final bool tabClearance;

  @override
  State<ZyraRequestActivityPresentation> createState() =>
      _ZyraRequestActivityPresentationState();
}

class _ZyraRequestActivityPresentationState
    extends State<ZyraRequestActivityPresentation> {
  late final PageController _pager;
  int _selectionRevision = 0;
  int _renderRevision = 0;

  @override
  void initState() {
    super.initState();
    _pager = PageController(initialPage: widget.selectedIndex, keepPage: false);
  }

  void _select(int index, {bool synchronize = false}) {
    if (!mounted ||
        !_pager.hasClients ||
        (!synchronize && !(widget.canInteract?.call() ?? true)) ||
        index < 0 ||
        index >= widget.pages.length) {
      return;
    }
    ++_selectionRevision;
    if (_quietMotion(context)) {
      _pager.jumpToPage(index);
    } else {
      unawaited(ZyraSegmentedMotion.animateToPage(context, _pager, index));
    }
  }

  @override
  void didUpdateWidget(covariant ZyraRequestActivityPresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selection = ++_selectionRevision;
    final target = widget.selectedIndex;
    if (oldWidget.selectedIndex != target &&
        (!_pager.hasClients || _pager.page?.round() != target)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            selection == _selectionRevision &&
            target == widget.selectedIndex) {
          // Current caller selection may change while controls cover a page.
          // Synchronise it without treating restoration as a member action.
          _select(target, synchronize: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Widget _tab(int index, int revision) {
    final selected = widget.selectedIndex == index;
    final radius = BorderRadius.circular(22);
    void action() {
      if (mounted && revision == _renderRevision) _select(index);
    }

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: widget.labels[index],
      onTap: ZyraTapFeedback.onTap(context, action),
      excludeSemantics: true,
      child: ZyraFloatingSurface(
        radius: 999,
        child: Material(
          color: selected
              ? ZyraColors.accentOnCanvas.withValues(alpha: .12)
              : ZyraColors.surfaceFill,
          borderRadius: radius,
          child: InkWell(
            key: widget.segmentKeys.length > index
                ? widget.segmentKeys[index]
                : null,
            borderRadius: radius,
            onTap: ZyraTapFeedback.onTap(context, action),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected
                      ? ZyraColors.accentOnCanvas.withValues(alpha: .70)
                      : ZyraColors.surfaceBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.labels[index],
                textAlign: TextAlign.center,
                style: ZyraText.button(
                  size: 12,
                  color: selected ? ZyraColors.foreground : _helperInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(int index) {
    final content = widget.pages[index];
    final bottom = widget.tabClearance
        ? ZyraNavBarMetrics.contentBottomClearance(context)
        : 110.0;
    if (content.length == 1 && content.single is ZyraRequestActivityEmpty) {
      // Like the Journey empty page: centre in the available body, with
      // natural scrolling only when enlarged text needs more reading space.
      return Padding(
        // The locked normal frame reserves the lower quiet area. Enlarged
        // text reclaims it and keeps the existing natural reading scroll.
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          widget.tabClearance
              ? bottom
              : MediaQuery.textScalerOf(context).scale(12.5) <= 12.5
              ? 250
              : 110,
        ),
        child: LayoutBuilder(
          key: ValueKey('request_activity_empty_viewport_$index'),
          builder: (context, constraints) => ZyraShadowScrollView(
            key: PageStorageKey('concept_connections_page_$index'),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: content.single,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      key: PageStorageKey('concept_connections_page_$index'),
      padding: EdgeInsets.fromLTRB(
        ZyraPreviewSpacing.pageMargin,
        0,
        ZyraPreviewSpacing.pageMargin,
        bottom,
      ),
      itemCount: content.length,
      itemBuilder: (context, i) => content[i],
      separatorBuilder: (context, i) =>
          const SizedBox(height: ZyraPreviewSpacing.cardToCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revision = ++_renderRevision;
    final multiplePages = widget.pages.length > 1;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                var style = ZyraText.pageTitle();
                // Keep whole title words at compact/enlarged type without
                // changing the user's text scaler or shrinking the page.
                for (final size in [26.0, 24.0, 22.0, 20.0]) {
                  style = ZyraText.heading(size: size);
                  var fits = true;
                  for (final word in widget.title.split(' ')) {
                    final painter = TextPainter(
                      text: TextSpan(text: word, style: style),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout();
                    fits = fits && painter.width <= constraints.maxWidth;
                    painter.dispose();
                  }
                  if (fits) break;
                }
                return Text(
                  widget.title,
                  key: const ValueKey('concept_connections_title'),
                  style: style,
                );
              },
            ),
          ),
          if (multiplePages) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Natural chips replace equal columns at enlarged text;
                  // labels remain untruncated and preserve the user's size.
                  if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                    return Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (
                          var index = 0;
                          index < widget.labels.length;
                          index++
                        )
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: _tab(index, revision),
                          ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (
                        var index = 0;
                        index < widget.labels.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 6),
                        Expanded(child: _tab(index, revision)),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
          ],
          Expanded(
            child: !multiplePages
                ? _list(0)
                : PageView(
                    key: const ValueKey('request_activity_pager'),
                    controller: _pager,
                    physics: ZyraSegmentedMotion.pagePhysics,
                    onPageChanged: (index) {
                      if (mounted &&
                          revision == _renderRevision &&
                          (widget.canInteract?.call() ?? true)) {
                        widget.onChanged(index);
                      }
                    },
                    children: [
                      for (var index = 0; index < widget.pages.length; index++)
                        _list(index),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// One canonical Soft card. The caller owns and guards its expansion/actions.
class ZyraRequestActivityCard extends StatelessWidget {
  const ZyraRequestActivityCard({
    super.key,
    required this.profile,
    required this.subtitle,
    required this.cardId,
    required this.controller,
    required this.primary,
    required this.onToggle,
    this.headerKey,
    this.onReport,
    this.canInteract,
    this.actions = const [],
    this.detail,
  });

  final SeekerProfile profile;
  final String subtitle;
  final String? detail;
  final String cardId;
  final ZyraConnectionsExpansionController controller;
  final ZyraOneJourneyConnectionsAction primary;
  final VoidCallback? onToggle;
  final VoidCallback? onReport;
  final bool Function()? canInteract;
  final Key? headerKey;
  final List<ZyraOneJourneyConnectionsAction> actions;

  String get _name =>
      '${profile.firstName} ${profile.surnameLine ?? ''}'.trim();

  Widget _portrait() => _requestActivityPortrait(profile);

  Widget _identity() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _name,
        key: ValueKey('request_activity_name_$cardId'),
        style: ZyraText.heading(size: 21),
      ),
      if (profile.age > 0 || profile.city.isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(
          [
            if (profile.age > 0) '${profile.age}',
            if (profile.city.isNotEmpty) profile.city,
          ].join(' · '),
          style: ZyraText.subtext(size: 12, color: _helperInk),
        ),
      ],
      const SizedBox(height: 10),
      Text(subtitle, style: ZyraText.subtext(size: 12, color: _accentInk)),
    ],
  );

  Widget _header(BuildContext context, bool open) => Semantics(
    button: true,
    expanded: open,
    enabled: onToggle != null,
    child: InkWell(
      key: headerKey,
      onTap: ZyraTapFeedback.onTap(
        context,
        onToggle == null
            ? null
            : () {
                if (canInteract?.call() == false) return;
                onToggle!();
                if (controller.value != cardId) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted ||
                      controller.value != cardId ||
                      canInteract?.call() == false) {
                    return;
                  }
                  unawaited(
                    Scrollable.ensureVisible(
                      context,
                      alignment: 0,
                      duration: _quietMotion(context)
                          ? Duration.zero
                          : ZyraMotion.duration,
                      curve: ZyraMotion.curve,
                    ),
                  );
                });
              },
      ),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chevron = _requestActivityChevron(open);
            final horizontalNameWidth = constraints.maxWidth - 64 - 16 - 5 - 23;
            final stackIdentity =
                MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                !_wholeWordsFit(
                  context,
                  _name,
                  ZyraText.heading(size: 21),
                  horizontalNameWidth,
                );
            if (stackIdentity) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_portrait(), chevron],
                  ),
                  const SizedBox(height: 16),
                  _identity(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _portrait(),
                const SizedBox(width: 16),
                Expanded(child: _identity()),
                const SizedBox(width: 5),
                chevron,
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _button(
    ZyraOneJourneyConnectionsAction action, {
    bool primary = false,
  }) {
    final enabled = action.onTap != null;
    final radius = BorderRadius.circular(24);
    void invoke() {
      if (canInteract?.call() == false) return;
      action.onTap?.call();
    }

    final onTap = enabled ? invoke : null;
    return Builder(
      builder: (context) => Semantics(
        button: true,
        enabled: enabled,
        label: action.label,
        onTap: ZyraTapFeedback.onTap(context, onTap),
        excludeSemantics: true,
        child: Material(
          // The expanded parent already owns the card fill. A second pale
          // layer used to wash the primary action out; its edge is sufficient.
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            key: action.key,
            onTap: ZyraTapFeedback.onTap(context, onTap),
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: primary && enabled
                      ? ZyraColors.accentOnCanvas.withValues(alpha: .70)
                      : ZyraColors.surfaceBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (action.icon != null) ...[
                    Icon(
                      action.icon,
                      size: 18,
                      color: enabled ? ZyraColors.foreground : _helperInk,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: ZyraText.button(
                        size: 13,
                        color: enabled ? ZyraColors.foreground : _helperInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandedActions() => Builder(
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _button(primary, primary: true),
          if (detail != null) ...[
            const SizedBox(height: 10),
            Text(detail!, style: ZyraText.subtext(size: 12, color: _helperInk)),
          ],
          for (final action in actions) ...[
            const SizedBox(height: 10),
            _button(action),
          ],
          if (onReport != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Report ${profile.firstName}',
                onPressed: ZyraTapFeedback.onTap(context, () {
                  if (canInteract?.call() != false) onReport!();
                }),
                icon: Icon(Icons.flag_outlined, size: 20, color: _helperInk),
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: controller,
    builder: (context, selected, _) {
      final open = selected == cardId;
      final actions = open
          ? _expandedActions()
          : const SizedBox(width: double.infinity);
      return ZyraFloatingSurface(
        radius: 26,
        circle: false,
        gold: false,
        child: Container(
          key: ValueKey('request_activity_card_$cardId'),
          decoration: BoxDecoration(
            color: open
                ? ZyraColors.surfaceEmphasisFill
                : ZyraColors.surfaceFill,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: open
                  ? ZyraColors.surfaceEmphasisBorder
                  : ZyraColors.surfaceBorder,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, open),
                // No RenderAnimatedSize exists on reduced-motion/accessibility
                // paths: zero-duration animation still had layout state/tickers.
                if (_quietMotion(context))
                  actions
                else
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: actions,
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Single outcomes keep their display-only card. A group can reveal history.
class ZyraPastRequestActivityCard extends StatelessWidget {
  const ZyraPastRequestActivityCard({
    super.key,
    required this.profile,
    required this.subtitle,
    required this.status,
    required this.cardId,
    this.controller,
    this.canInteract,
    this.history = const [],
    this.askAgain,
  });

  final SeekerProfile profile;
  final String subtitle;
  final String status;
  final String cardId;
  final ZyraConnectionsExpansionController? controller;
  final bool Function()? canInteract;
  final List<({String date, String status})> history;
  final String? askAgain;

  String get _name =>
      '${profile.firstName} ${profile.surnameLine ?? ''}'.trim();

  Widget _identity() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _name,
        key: ValueKey('past_request_activity_name_$cardId'),
        style: ZyraText.heading(size: 21),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: ZyraText.subtext(size: 12, color: _helperInk)),
      const SizedBox(height: 10),
      Text(
        status,
        key: ValueKey('past_request_activity_status_$cardId'),
        style: ZyraText.subtext(size: 12, color: _helperInk),
      ),
    ],
  );

  Widget _header({bool? open}) => LayoutBuilder(
    builder: (context, constraints) {
      final chevron = open == null ? null : _requestActivityChevron(open);
      final nameWidth =
          constraints.maxWidth - 64 - 16 - (chevron == null ? 0 : 5 + 23);
      final stackIdentity =
          MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
          !_wholeWordsFit(
            context,
            _name,
            ZyraText.heading(size: 21),
            nameWidth,
          );
      final portrait = _requestActivityPortrait(profile);
      if (stackIdentity) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chevron == null)
              portrait
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [portrait, chevron],
              ),
            const SizedBox(height: 16),
            _identity(),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          portrait,
          const SizedBox(width: 16),
          Expanded(child: _identity()),
          if (chevron != null) ...[const SizedBox(width: 5), chevron],
        ],
      );
    },
  );

  Widget _surface({required Widget child, bool open = false}) =>
      ZyraFloatingSurface(
        radius: 26,
        circle: false,
        gold: false,
        child: Container(
          key: ValueKey('past_request_activity_card_$cardId'),
          decoration: BoxDecoration(
            color: open
                ? ZyraColors.surfaceEmphasisFill
                : ZyraColors.surfaceFill,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: open
                  ? ZyraColors.surfaceEmphasisBorder
                  : ZyraColors.surfaceBorder,
            ),
          ),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final expansion = controller;
    if (expansion == null) {
      return _surface(
        child: Padding(padding: const EdgeInsets.all(18), child: _header()),
      );
    }
    return ValueListenableBuilder<String?>(
      valueListenable: expansion,
      builder: (context, selected, _) {
        final open = selected == cardId;
        bool isCurrent() => canInteract?.call() != false;
        return _surface(
          open: open,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  expanded: open,
                  child: InkWell(
                    key: ValueKey('past_request_activity_header_$cardId'),
                    borderRadius: BorderRadius.circular(24),
                    onTap: ZyraTapFeedback.onTap(context, () {
                      if (!isCurrent()) return;
                      if (expansion.value == cardId) {
                        expansion.close(cardId);
                        return;
                      }
                      expansion.open(cardId);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted ||
                            expansion.value != cardId ||
                            !isCurrent()) {
                          return;
                        }
                        unawaited(
                          Scrollable.ensureVisible(
                            context,
                            alignment: 0,
                            duration: _quietMotion(context)
                                ? Duration.zero
                                : ZyraMotion.duration,
                            curve: ZyraMotion.curve,
                          ),
                        );
                      });
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: _header(open: open),
                    ),
                  ),
                ),
                if (open)
                  _PastRequestHistory(
                    entries: history,
                    askAgain: askAgain,
                    canInteract: () => expansion.value == cardId && isCurrent(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PastRequestHistory extends StatefulWidget {
  const _PastRequestHistory({
    required this.entries,
    required this.askAgain,
    required this.canInteract,
  });

  final List<({String date, String status})> entries;
  final String? askAgain;
  final bool Function() canInteract;

  @override
  State<_PastRequestHistory> createState() => _PastRequestHistoryState();
}

class _PastRequestHistoryState extends State<_PastRequestHistory> {
  static const _initialRowCount = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final entries = _showAll
        ? widget.entries
        : widget.entries.take(_initialRowCount);
    final muted = ZyraText.subtext(size: 12, color: _helperInk);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, thickness: 1, color: ZyraColors.surfaceBorder),
          const SizedBox(height: 6),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(entry.date, style: muted)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.status,
                      style: muted,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          if (!_showAll && widget.entries.length > _initialRowCount)
            InkWell(
              onTap: ZyraTapFeedback.onTap(context, () {
                if (widget.canInteract()) setState(() => _showAll = true);
              }),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    'Show all ${widget.entries.length}',
                    style: ZyraText.subtext(
                      size: 12,
                      color: ZyraColors.goldText,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.askAgain case final line?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(line, style: muted),
            ),
        ],
      ),
    );
  }
}

/// An empty collection uses the same quiet, unboxed state as Journey.
class ZyraRequestActivityEmpty extends StatelessWidget {
  const ZyraRequestActivityEmpty({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ZyraEmptyState(
    key: const ValueKey('request_activity_empty'),
    icon: icon,
    title: title,
    message: message,
  );
}
