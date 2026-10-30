import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_state_widgets.dart';
import 'zyra_subscription_wallet_draft.dart';

/// Protected, detached examples. This view owns no real account or receipt.
class ZyraSubscriptionWalletPreview extends StatefulWidget {
  const ZyraSubscriptionWalletPreview({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onSwitch,
    required this.onSetup,
    required this.onMembership,
    this.currentRole = ZyraWalletRole.seeker,
    this.onBack,
    this.canAct,
    this.showBackButton = true,
    this.switchOnly = false,
  });

  final ZyraSubscriptionWalletDraft draft;
  final ValueChanged<ZyraSubscriptionWalletDraft> onChanged;
  final ValueChanged<ZyraWalletRole> onSwitch;
  final ValueChanged<ZyraWalletRole> onSetup;
  final ValueChanged<ZyraWalletRole> onMembership;
  final ZyraWalletRole currentRole;
  final VoidCallback? onBack;
  final bool Function()? canAct;
  final bool showBackButton;
  final bool switchOnly;

  @override
  State<ZyraSubscriptionWalletPreview> createState() =>
      _ZyraSubscriptionWalletPreviewState();
}

class _WalletHaloPager extends StatefulWidget {
  const _WalletHaloPager({
    super.key,
    required this.group,
    required this.count,
    required this.initialPage,
    required this.navigationHeight,
    required this.canAct,
    required this.onInteraction,
    required this.onChanged,
    required this.itemBuilder,
  });
  final String group;
  final int count;
  final int initialPage;
  final double navigationHeight;
  final bool Function() canAct;
  final VoidCallback onInteraction;
  final ValueChanged<int> onChanged;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<_WalletHaloPager> createState() => _WalletHaloPagerState();
}

class _WalletHaloPagerState extends State<_WalletHaloPager> {
  late final _pages = PageController(
    initialPage: widget.initialPage,
    keepPage: false,
  );
  late int _page = widget.initialPage;
  int _epoch = 0;
  bool _rewindScheduled = false;
  bool _rewinding = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _fresh(int epoch) => mounted && epoch == _epoch && widget.canAct();

  void _reconcilePosition() {
    if (!mounted ||
        !_pages.hasClients ||
        _rewindScheduled ||
        ((_pages.page ?? _page.toDouble()) - _page).abs() < .001) {
      return;
    }
    _rewindScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rewindScheduled = false;
      if (!mounted ||
          !_pages.hasClients ||
          _pages.position.isScrollingNotifier.value ||
          ((_pages.page ?? _page.toDouble()) - _page).abs() < .001) {
        return;
      }
      // A denied in-flight swipe can finish physically without accepting a
      // new page. Rewind only local presentation to the last accepted page;
      // never call owner/draft callbacks while reconciling, even if canAct
      // becomes true again before this bounded post-frame callback.
      _rewinding = true;
      try {
        _pages.jumpToPage(_page);
      } finally {
        _rewinding = false;
      }
    });
  }

  void _go(int page, int epoch) {
    if (!_fresh(epoch) ||
        !_pages.hasClients ||
        page < 0 ||
        page >= widget.count) {
      return;
    }
    widget.onInteraction();
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final epoch = ++_epoch;
    Widget arrow(bool previous) => IconButton(
      key: ValueKey('wallet_${widget.group}_${previous ? 'previous' : 'next'}'),
      tooltip:
          '${previous ? 'Previous' : 'Next'} ${widget.group == 'profiles' ? 'profile' : 'Family place'}',
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: const EdgeInsets.all(10),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      color: _walletGold,
      onPressed: ZyraTapFeedback.onTap(
        context,
        (previous ? _page > 0 : _page < widget.count - 1)
            ? () => _go(_page + (previous ? -1 : 1), epoch)
            : null,
      ),
      icon: Icon(
        previous ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
        size: 22,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth == 0 &&
                  notification.metrics.axis == Axis.horizontal) {
                if (notification is ScrollStartNotification &&
                    // Accessibility/focus reveal can adjust an inset child's
                    // horizontal offset without choosing another page. Keep
                    // its adjacent confirmation; only a real swipe cancels.
                    notification.dragDetails != null &&
                    !_rewinding &&
                    _fresh(epoch)) {
                  widget.onInteraction();
                }
                if (notification is ScrollEndNotification && !_rewinding) {
                  _reconcilePosition();
                }
              }
              return false;
            },
            child: PageView.builder(
              key: ValueKey('wallet_${widget.group}_pages'),
              controller: _pages,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.count,
              onPageChanged: (page) {
                if (_rewinding ||
                    page == _page ||
                    !_fresh(epoch) ||
                    page < 0 ||
                    page >= widget.count) {
                  return;
                }
                setState(() => _page = page);
                widget.onChanged(page);
              },
              itemBuilder: widget.itemBuilder,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: widget.navigationHeight,
          child: Row(
            children: [
              arrow(true),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_page + 1} of ${widget.count} ${widget.group == 'profiles' ? 'profiles' : 'places'}',
                      key: ValueKey('wallet_${widget.group}_position'),
                      semanticsLabel:
                          '${widget.group == 'profiles' ? 'Profile' : 'Family place'} ${_page + 1} of ${widget.count}',
                      textAlign: TextAlign.center,
                      style: _walletBodyStyle(11),
                    ),
                    const SizedBox(height: 7),
                    ExcludeSemantics(
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var page = 0; page < widget.count; page++) ...[
                              if (page > 0) const SizedBox(width: 6),
                              Container(
                                key: ValueKey(
                                  'wallet_${widget.group}_dot_$page',
                                ),
                                width: page == _page ? 22 : 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: page == _page
                                      ? _walletGold
                                      : ZyraColors.foregroundSecondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              arrow(false),
            ],
          ),
        ),
      ],
    );
  }
}

Color get _walletGold => ZyraColors.isLightPalette
    ? const Color(0xFF76531F)
    : ZyraColors.journeyGold;
TextStyle _walletBodyStyle(double size) =>
    ZyraText.body(size: size, color: ZyraColors.foreground).copyWith(
      height: 1.5,
      letterSpacing: .25,
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
    );
TextStyle _walletHeading(double size) =>
    ZyraText.heading(size: size, color: ZyraColors.foreground).copyWith(
      height: 1.25,
      letterSpacing: .25,
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
    );
TextStyle get _walletButtonStyle =>
    ZyraText.button(size: 13, color: _walletGold).copyWith(
      height: 1.5,
      letterSpacing: .1,
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
    );
Size _walletTextSize(
  String value,
  TextStyle style,
  TextScaler scaler,
  TextDirection direction,
  double width,
) {
  final painter = TextPainter(
    text: TextSpan(text: value, style: style),
    textScaler: scaler,
    textDirection: direction,
  )..layout(maxWidth: width.clamp(1, double.infinity).toDouble());
  final size = painter.size;
  painter.dispose();
  return size;
}

double _actionHeight(
  String label,
  double width,
  TextScaler scaler,
  TextDirection direction,
) =>
    (_walletTextSize(
              label,
              _walletButtonStyle,
              scaler,
              direction,
              width - 32,
            ).height +
            28)
        .clamp(48, double.infinity)
        .toDouble();

bool _identityStacks(
  String title,
  String subtitle,
  double titleSize,
  double width,
  TextScaler scaler,
  TextDirection direction,
) {
  final textWidth = width - 98; // The 80px halo and its 18px gap.
  for (final entry in [
    (title, _walletHeading(titleSize)),
    (subtitle, _walletBodyStyle(13)),
  ]) {
    for (final word in entry.$1.split(RegExp(r'\s+'))) {
      if (_walletTextSize(
            word,
            entry.$2,
            scaler,
            direction,
            double.infinity,
          ).width >
          textWidth) {
        return true;
      }
    }
  }
  return false;
}

double _identityHeight(
  String title,
  String subtitle,
  double titleSize,
  double width,
  TextScaler scaler,
  TextDirection direction,
) {
  final stacked = _identityStacks(
    title,
    subtitle,
    titleSize,
    width,
    scaler,
    direction,
  );
  final textWidth = stacked ? width : width - 98;
  final textHeight =
      _walletTextSize(
        title,
        _walletHeading(titleSize),
        scaler,
        direction,
        textWidth,
      ).height +
      6 +
      _walletTextSize(
        subtitle,
        _walletBodyStyle(13),
        scaler,
        direction,
        textWidth,
      ).height;
  return stacked
      ? 80 + 12 + textHeight
      : textHeight.clamp(80, double.infinity).toDouble();
}

class ZyraSubscriptionSwitchPreview extends StatelessWidget {
  const ZyraSubscriptionSwitchPreview({
    super.key,
    required this.draft,
    required this.currentRole,
    required this.onChanged,
    required this.onSwitch,
    required this.onSetup,
    required this.onMembership,
    this.onBack,
    this.canAct,
    this.showBackButton = true,
  });

  final ZyraSubscriptionWalletDraft draft;
  final ZyraWalletRole currentRole;
  final ValueChanged<ZyraSubscriptionWalletDraft> onChanged;
  final ValueChanged<ZyraWalletRole> onSwitch;
  final ValueChanged<ZyraWalletRole> onSetup;
  final ValueChanged<ZyraWalletRole> onMembership;
  final VoidCallback? onBack;
  final bool Function()? canAct;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) => ZyraSubscriptionWalletPreview(
    draft: draft,
    currentRole: currentRole,
    onChanged: onChanged,
    onSwitch: onSwitch,
    onSetup: onSetup,
    onMembership: onMembership,
    onBack: onBack,
    canAct: canAct,
    showBackButton: showBackButton,
    switchOnly: true,
  );
}

class _WalletIntent {
  const _WalletIntent({
    required this.placeId,
    required this.forSelf,
    required this.anchorId,
  });
  final String placeId;
  final bool forSelf;
  final String anchorId;
}

class _ZyraSubscriptionWalletPreviewState
    extends State<ZyraSubscriptionWalletPreview> {
  int _renderEpoch = 0;
  _WalletIntent? _intent;
  bool _family = false;
  int _profilePage = 0;
  int _familyPage = 0;

  @override
  void didUpdateWidget(covariant ZyraSubscriptionWalletPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.draft, oldWidget.draft) ||
        widget.currentRole != oldWidget.currentRole ||
        widget.switchOnly != oldWidget.switchOnly) {
      _intent = null;
    }
    if (widget.draft.ownerId != oldWidget.draft.ownerId ||
        widget.switchOnly != oldWidget.switchOnly) {
      _family = false;
      _profilePage = 0;
      _familyPage = 0;
    }
    if (_familyPage >= widget.draft.places.length) _familyPage = 0;
    _renderEpoch++;
  }

  bool Function() _fresh(int epoch) {
    final draft = widget.draft;
    final role = widget.currentRole;
    final switchOnly = widget.switchOnly;
    return () =>
        mounted &&
        epoch == _renderEpoch &&
        identical(widget.draft, draft) &&
        widget.draft.ownerId == draft.ownerId &&
        widget.draft.revision == draft.revision &&
        widget.currentRole == role &&
        widget.switchOnly == switchOnly &&
        (ModalRoute.of(context)?.isCurrent ?? false) &&
        (widget.canAct?.call() ?? true);
  }

  VoidCallback _guard(bool Function() fresh, VoidCallback action) => () {
    if (fresh()) action();
  };

  @override
  Widget build(BuildContext context) {
    final fresh = _fresh(++_renderEpoch);
    if (!widget.switchOnly) return _haloWallet(fresh);
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('wallet_switch_scroll'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showBackButton && widget.onBack != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('wallet_back'),
                  style: TextButton.styleFrom(
                    foregroundColor: ZyraColors.journeyGold,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: ZyraTapFeedback.onTap(
                    context,
                    _guard(fresh, widget.onBack!),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 22),
                  label: Text(
                    'Back',
                    style: ZyraText.button(color: ZyraColors.journeyGold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Semantics(
              header: true,
              child: Text('Switch profile', style: ZyraText.pageTitle()),
            ),
            const SizedBox(height: 12),
            _body(
              'Check the membership already covering your ${widget.currentRole.other.label} profile before you continue.',
              size: 14,
            ),
            const SizedBox(height: 12),
            _body(
              'No purchase, account or invitation is changed here.',
              size: 11.5,
            ),
            const SizedBox(height: 24),
            _roleCard(widget.currentRole.other, fresh),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  bool Function() _pageFresh(bool Function() fresh, bool family, int page) =>
      () =>
          fresh() &&
          _family == family &&
          (family ? _familyPage : _profilePage) == page;

  void _clearIntent() {
    if (_intent != null) setState(() => _intent = null);
  }

  Widget _haloWallet(bool Function() fresh) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final family = _family;
        bool pagerFresh() => fresh() && _family == family;
        final width = (constraints.maxWidth - 40)
            .clamp(1, double.infinity)
            .toDouble();
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        double text(String value, TextStyle style, double available) =>
            _walletTextSize(value, style, scaler, direction, available).height;
        final titleStyle = _walletHeading(width < scaler.scale(220) ? 20 : 26);
        final stacked =
            _walletTextSize(
              'subscriptions',
              titleStyle,
              scaler,
              direction,
              double.infinity,
            ).width >
            width - 52;
        final titleHeight = text(
          'Your subscriptions',
          titleStyle,
          stacked ? width : width - 52,
        );
        final headerHeight = stacked
            ? titleHeight + 44
            : titleHeight.clamp(44, double.infinity).toDouble();
        final pillHeight =
            (text('Family places', _walletButtonStyle, double.infinity) + 20)
                .clamp(48, double.infinity)
                .toDouble();
        final navigationHeight =
            (text(
                      _family
                          ? '${widget.draft.places.length} of ${widget.draft.places.length} places'
                          : '2 of 2 profiles',
                      _walletBodyStyle(11),
                      width - 104,
                    ) +
                    13)
                .clamp(44, double.infinity)
                .toDouble();
        final availabilityHeight =
            _family &&
                widget.draft.inventoryAvailable &&
                widget.draft.places.isNotEmpty
            ? (text(_availabilityLabel, _walletBodyStyle(13), width - 34) + 26)
                      .clamp(52, double.infinity)
                      .toDouble() +
                  14
            : 0.0;
        var pageHeight = 0.0;
        if (_family) {
          if (!widget.draft.inventoryAvailable) {
            pageHeight =
                text(_emptyPlacesCopy, _walletBodyStyle(13), width - 38) + 38;
          } else {
            for (final place in widget.draft.places) {
              final candidate = _placeHeight(place, width, scaler, direction);
              if (candidate > pageHeight) pageHeight = candidate;
            }
          }
        } else {
          for (final role in ZyraWalletRole.values) {
            final candidate = _roleHeight(role, width, scaler, direction);
            if (candidate > pageHeight) pageHeight = candidate;
          }
        }
        final hasPages =
            !_family ||
            (widget.draft.inventoryAvailable && widget.draft.places.isNotEmpty);
        final backHeight = widget.showBackButton && widget.onBack != null
            ? (text('Back', _walletButtonStyle, width - 8) + 16)
                      .clamp(48, double.infinity)
                      .toDouble() +
                  12
            : 0.0;
        final fixedHeight =
            40 +
            backHeight +
            headerHeight +
            16 +
            pillHeight +
            16 +
            availabilityHeight +
            (hasPages ? 12 + navigationHeight : 0);
        final fill =
            constraints.hasBoundedHeight &&
            constraints.maxHeight >= fixedHeight + pageHeight;
        final group = _family ? 'family' : 'profiles';
        final count = _family
            ? widget.draft.places.length
            : ZyraWalletRole.values.length;
        final current = _family ? _familyPage : _profilePage;
        final pager = hasPages
            ? _WalletHaloPager(
                key: ValueKey('wallet_${group}_${widget.draft.ownerId}_$count'),
                group: group,
                count: count,
                initialPage: current,
                navigationHeight: navigationHeight,
                canAct: pagerFresh,
                onInteraction: _guard(pagerFresh, _clearIntent),
                onChanged: (page) {
                  if (!pagerFresh() || page < 0 || page >= count) return;
                  setState(() {
                    _intent = null;
                    if (family) {
                      _familyPage = page;
                    } else {
                      _profilePage = page;
                    }
                  });
                },
                itemBuilder: (context, page) => family
                    ? _haloPlaceCard(
                        widget.draft.places[page],
                        page,
                        _pageFresh(fresh, true, page),
                      )
                    : _haloRoleCard(
                        ZyraWalletRole.values[page],
                        _pageFresh(fresh, false, page),
                      ),
              )
            : widget.draft.inventoryAvailable
            ? ZyraEmptyState(
                key: const ValueKey('wallet_places_empty'),
                icon: Icons.card_giftcard_outlined,
                message: _emptyPlacesCopy,
              )
            : _card(
                id: 'wallet_places_empty',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_body(_emptyPlacesCopy)],
                ),
              );
        final information = IconButton(
          key: const ValueKey('wallet_info'),
          tooltip: 'About your subscriptions',
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            maximumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: ZyraTapFeedback.onTap(
            context,
            _guard(fresh, _showInformation),
          ),
          icon: Icon(Icons.info_outline_rounded, size: 21, color: _walletGold),
        );
        final title = Semantics(
          header: true,
          child: Text(
            'Your subscriptions',
            key: const ValueKey('wallet_title'),
            style: titleStyle,
          ),
        );
        final headingContent = <Widget>[
          if (widget.showBackButton && widget.onBack != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('wallet_back'),
                style: TextButton.styleFrom(
                  foregroundColor: _walletGold,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: ZyraTapFeedback.onTap(
                  context,
                  _guard(fresh, widget.onBack!),
                ),
                icon: const Icon(Icons.arrow_back, size: 22),
                label: Text('Back', style: _walletButtonStyle),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (stacked) ...[
            Align(alignment: Alignment.centerRight, child: information),
            title,
          ] else
            Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 8),
                information,
              ],
            ),
          const SizedBox(height: 16),
          _groupPills(fresh, width, pillHeight, scaler, direction),
          const SizedBox(height: 16),
          if (availabilityHeight > 0) ...[
            Container(
              key: const ValueKey('wallet_availability'),
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _walletGold.withValues(alpha: .08),
                border: Border.all(color: _walletGold.withValues(alpha: .35)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(_availabilityLabel, style: _walletBodyStyle(13)),
            ),
            const SizedBox(height: 14),
          ],
        ];
        if (_family &&
            widget.draft.inventoryAvailable &&
            widget.draft.places.isEmpty) {
          // Use the shared empty state's actual intrinsic text layout rather
          // than a measured card height. It fills the remaining body when it
          // fits, and the same viewport scrolls naturally at enlarged text.
          if (!constraints.hasBoundedHeight) {
            return SingleChildScrollView(
              key: const ValueKey('wallet_scroll'),
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...headingContent, pager],
              ),
            );
          }
          return CustomScrollView(
            key: const ValueKey('wallet_scroll'),
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: headingContent,
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: pager,
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          key: const ValueKey('wallet_scroll'),
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: fill ? constraints.maxHeight : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...headingContent,
                  if (fill)
                    Expanded(child: pager)
                  else
                    SizedBox(
                      height:
                          pageHeight + (hasPages ? 12 + navigationHeight : 0),
                      child: pager,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  String get _availabilityLabel {
    final count = widget.draft.places
        .where((place) => place.state == ZyraWalletPlaceState.available)
        .length;
    return '$count ${count == 1 ? 'place' : 'places'} available';
  }

  String get _emptyPlacesCopy => widget.draft.inventoryAvailable
      ? 'No Family places. Your individual memberships stay separate.'
      : 'Your available places could not be checked. No places are assumed to be spare.';

  Widget _groupPills(
    bool Function() fresh,
    double width,
    double height,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final labels = ['Profiles', 'Family places'];
    final preferred = labels
        .map(
          (label) =>
              _walletTextSize(
                label,
                _walletButtonStyle,
                scaler,
                direction,
                double.infinity,
              ).width +
              32,
        )
        .reduce((a, b) => a > b ? a : b);
    Widget pill(int index) => Semantics(
      selected: _family == (index == 1),
      inMutuallyExclusiveGroup: true,
      child: OutlinedButton(
        key: ValueKey(
          index == 0 ? 'wallet_group_profiles' : 'wallet_group_family',
        ),
        onPressed: ZyraTapFeedback.onTap(
          context,
          _guard(fresh, () {
            if (_family == (index == 1)) return;
            setState(() {
              _intent = null;
              _family = index == 1;
            });
          }),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(44, height),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: _family == (index == 1)
              ? _walletGold.withValues(alpha: .18)
              : ZyraColors.surfaceFill,
          side: BorderSide(
            color: _family == (index == 1)
                ? _walletGold
                : ZyraColors.surfaceBorder,
          ),
          shape: const StadiumBorder(),
        ),
        child: Text(labels[index], softWrap: false, style: _walletButtonStyle),
      ),
    );
    if ((width - 8) / 2 < preferred) {
      return SingleChildScrollView(
        key: const ValueKey('wallet_groups_rail'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < 2; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              SizedBox(width: preferred, height: height, child: pill(index)),
            ],
          ],
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: pill(0)),
          const SizedBox(width: 8),
          Expanded(child: pill(1)),
        ],
      ),
    );
  }

  void _showInformation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const ValueKey('wallet_info_dialog'),
        backgroundColor: ZyraColors.isLightPalette
            ? const Color(0xFFF4EFF6)
            : const Color(0xFF30253E),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'About your subscriptions',
                      style: _walletHeading(20),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('wallet_info_close'),
                    tooltip: 'Close',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: ZyraTapFeedback.onTap(context, () {
                      if (dialogContext.mounted &&
                          (ModalRoute.of(dialogContext)?.isCurrent ?? false)) {
                        Navigator.of(dialogContext).pop();
                      }
                    }),
                    icon: Icon(Icons.close_rounded, color: _walletGold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _body(
                        'No purchase, account or invitation is changed here.',
                      ),
                      const SizedBox(height: 12),
                      _body(
                        'Profile readiness and membership coverage are separate. Real paid subscriptions are not verified here.',
                      ),
                      const SizedBox(height: 12),
                      _body(
                        'Assigning a place does not create a Guardian link or permission to view or chat. Invitations need the recipient’s agreement. Funded places cannot be reused until renewal.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleHalo(
    ZyraWalletRole role, {
    required String title,
    required String subtitle,
    required double titleSize,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = _identityStacks(
        title,
        subtitle,
        titleSize,
        constraints.maxWidth,
        MediaQuery.textScalerOf(context),
        Directionality.of(context),
      );
      final halo = ExcludeSemantics(
        child: Container(
          key: ValueKey('wallet_halo_${role.name}'),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _walletGold.withValues(alpha: .08),
            border: Border.all(color: _walletGold.withValues(alpha: .7)),
            boxShadow: [
              BoxShadow(
                color: _walletGold.withValues(alpha: .08),
                blurRadius: 20,
              ),
            ],
          ),
          child: Icon(
            role == ZyraWalletRole.seeker
                ? Icons.person_outline
                : Icons.shield_outlined,
            size: 32,
            color: _walletGold,
          ),
        ),
      );
      final details = Column(
        crossAxisAlignment: stacked
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: stacked ? TextAlign.center : TextAlign.left,
            style: _walletHeading(titleSize),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: stacked ? TextAlign.center : TextAlign.left,
            style: _walletBodyStyle(13),
          ),
        ],
      );
      return stacked
          ? Column(
              key: ValueKey('wallet_identity_${role.name}_stacked'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: halo),
                const SizedBox(height: 12),
                details,
              ],
            )
          : Row(
              key: ValueKey('wallet_identity_${role.name}_row'),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                halo,
                const SizedBox(width: 18),
                Expanded(child: details),
              ],
            );
    },
  );

  String _primaryLabel(ZyraWalletRole role) {
    final next = widget.draft.nextStep(role);
    if (role == widget.currentRole &&
        next == ZyraWalletNextStep.switchProfile) {
      return 'Current profile';
    }
    return switch (next) {
      ZyraWalletNextStep.switchProfile => 'Switch to ${role.label}',
      ZyraWalletNextStep.finishSetup => 'Finish ${role.label} setup',
      ZyraWalletNextStep.usePlace => 'Use a ${role.label} place for me',
      ZyraWalletNextStep.chooseMembership => 'Choose ${role.label} membership',
      ZyraWalletNextStep.startSetup => 'Set up ${role.label} profile',
      ZyraWalletNextStep.unavailable => 'Check unavailable',
    };
  }

  Widget _haloRoleCard(ZyraWalletRole role, bool Function() fresh) {
    final facts = widget.draft.forRole(role);
    final next = widget.draft.nextStep(role);
    return _card(
      id: 'wallet_role_${role.name}',
      emphasized: facts.isCovered,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _roleHalo(
            role,
            title: '${role.label} profile',
            subtitle: facts.coverageLabel(role),
            titleSize: 23,
          ),
          const SizedBox(height: 16),
          _body(facts.readinessLabel),
          const SizedBox(height: 12),
          _body(_roleDetail(role, next), size: 12),
          const SizedBox(height: 18),
          if (_intent?.anchorId == 'role_${role.name}')
            _confirmation(fresh)
          else
            _action(
              id: 'wallet_primary_${role.name}',
              label: _primaryLabel(role),
              onPressed:
                  (role == widget.currentRole &&
                          next == ZyraWalletNextStep.switchProfile) ||
                      next == ZyraWalletNextStep.unavailable
                  ? null
                  : _guard(fresh, () => _handlePrimary(role, next)),
            ),
        ],
      ),
    );
  }

  bool _canUsePlace(ZyraWalletPlace place) {
    final facts = widget.draft.forRole(place.role);
    return place.state == ZyraWalletPlaceState.available &&
        !facts.isOne &&
        facts.coverage != ZyraWalletCoverage.unavailable &&
        facts.readiness != ZyraWalletReadiness.unknown;
  }

  Widget _haloPlaceCard(
    ZyraWalletPlace place,
    int index,
    bool Function() fresh,
  ) => _card(
    id: 'wallet_place_${place.id}',
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _body('Family place ${index + 1}', size: 11),
        const SizedBox(height: 12),
        _roleHalo(
          place.role,
          title: '${place.role.label} One',
          subtitle: place.statusLabel,
          titleSize: 20,
        ),
        if (place.state == ZyraWalletPlaceState.invitationPending) ...[
          const SizedBox(height: 12),
          _body('Not active · awaiting recipient agreement', size: 11.5),
        ],
        if (place.state == ZyraWalletPlaceState.fundedUntilRenewal) ...[
          const SizedBox(height: 12),
          _body('Not available to reassign', size: 11.5),
        ],
        if (_intent?.anchorId == 'place_${place.id}') ...[
          const SizedBox(height: 18),
          _confirmation(fresh),
        ] else if (place.state == ZyraWalletPlaceState.available) ...[
          const SizedBox(height: 18),
          if (_canUsePlace(place)) ...[
            _action(
              id: 'wallet_use_${place.id}',
              label: 'Use for me',
              onPressed: _guard(
                fresh,
                () => setState(
                  () => _intent = _WalletIntent(
                    placeId: place.id,
                    forSelf: true,
                    anchorId: 'place_${place.id}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _action(
            id: 'wallet_assign_${place.id}',
            label: 'Assign to someone',
            onPressed: _guard(
              fresh,
              () => setState(
                () => _intent = _WalletIntent(
                  placeId: place.id,
                  forSelf: false,
                  anchorId: 'place_${place.id}',
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  double _roleHeight(
    ZyraWalletRole role,
    double width,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final inner = width - 38;
    double text(String value, TextStyle style, [double? available]) =>
        _walletTextSize(
          value,
          style,
          scaler,
          direction,
          available ?? inner,
        ).height;
    final facts = widget.draft.forRole(role);
    final hero = _identityHeight(
      '${role.label} profile',
      facts.coverageLabel(role),
      23,
      inner,
      scaler,
      direction,
    );
    final action = _intent?.anchorId == 'role_${role.name}'
        ? _confirmationHeight(inner, scaler, direction)
        : _actionHeight(_primaryLabel(role), inner, scaler, direction);
    return 38 +
        hero +
        16 +
        text(facts.readinessLabel, _walletBodyStyle(13)) +
        12 +
        text(
          _roleDetail(role, widget.draft.nextStep(role)),
          _walletBodyStyle(12),
        ) +
        18 +
        action;
  }

  double _placeHeight(
    ZyraWalletPlace place,
    double width,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final inner = width - 38;
    double text(String value, TextStyle style, [double? available]) =>
        _walletTextSize(
          value,
          style,
          scaler,
          direction,
          available ?? inner,
        ).height;
    final hero = _identityHeight(
      '${place.role.label} One',
      place.statusLabel,
      20,
      inner,
      scaler,
      direction,
    );
    final numberHeight = text(
      'Family place ${widget.draft.places.indexOf(place) + 1}',
      _walletBodyStyle(11),
      inner,
    );
    var height = 38 + numberHeight + 12 + hero;
    if (place.state == ZyraWalletPlaceState.invitationPending) {
      height +=
          12 +
          text(
            'Not active · awaiting recipient agreement',
            _walletBodyStyle(11.5),
          );
    }
    if (place.state == ZyraWalletPlaceState.fundedUntilRenewal) {
      height += 12 + text('Not available to reassign', _walletBodyStyle(11.5));
    }
    if (_intent?.anchorId == 'place_${place.id}') {
      height += 18 + _confirmationHeight(inner, scaler, direction);
    } else if (place.state == ZyraWalletPlaceState.available) {
      height +=
          18 + _actionHeight('Assign to someone', inner, scaler, direction);
      if (_canUsePlace(place)) {
        height += 8 + _actionHeight('Use for me', inner, scaler, direction);
      }
    }
    return height;
  }

  double _confirmationHeight(
    double width,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final intent = _intent!;
    final place = widget.draft.places.singleWhere(
      (place) => place.id == intent.placeId,
    );
    final inner = width - 38;
    final recipient = place.role == ZyraWalletRole.seeker ? 'Amina' : 'Omar';
    final heading = intent.forSelf
        ? 'Use this ${place.role.label} place?'
        : 'Assign this ${place.role.label} place?';
    final detail = intent.forSelf
        ? 'Profile setup stays separate. No real subscription changes are made here.'
        : 'Preview an invitation for $recipient. It will stay pending until agreement; no invitation is sent and no access or Guardian link is granted.';
    return 38 +
        _walletTextSize(
          heading,
          _walletHeading(20),
          scaler,
          direction,
          inner,
        ).height +
        12 +
        _walletTextSize(
          detail,
          _walletBodyStyle(13),
          scaler,
          direction,
          inner,
        ).height +
        16 +
        _actionHeight(
          intent.forSelf ? 'Use this place' : 'Preview invitation',
          inner,
          scaler,
          direction,
        ) +
        8 +
        _actionHeight('Cancel', inner, scaler, direction);
  }

  Widget _roleCard(ZyraWalletRole role, bool Function() fresh) {
    final facts = widget.draft.forRole(role);
    final next = widget.draft.nextStep(role);
    final current = role == widget.currentRole;
    final readyCurrent = current && next == ZyraWalletNextStep.switchProfile;
    final label = readyCurrent
        ? 'Current profile'
        : switch (next) {
            ZyraWalletNextStep.switchProfile => 'Switch to ${role.label}',
            ZyraWalletNextStep.finishSetup => 'Finish ${role.label} setup',
            ZyraWalletNextStep.usePlace => 'Use a ${role.label} place for me',
            ZyraWalletNextStep.chooseMembership =>
              'Choose ${role.label} membership',
            ZyraWalletNextStep.startSetup => 'Set up ${role.label} profile',
            ZyraWalletNextStep.unavailable => 'Check unavailable',
          };
    return _card(
      id: 'wallet_role_${role.name}',
      emphasized: facts.isCovered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                role == ZyraWalletRole.seeker
                    ? Icons.person_outline
                    : Icons.shield_outlined,
                color: ZyraColors.journeyGold,
                size: 27,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${role.label} profile',
                      style: ZyraText.heading(size: 20),
                    ),
                    const SizedBox(height: 7),
                    _body(facts.coverageLabel(role)),
                    const SizedBox(height: 6),
                    _body(facts.readinessLabel, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _body(_roleDetail(role, next), size: 12),
          const SizedBox(height: 16),
          if (_intent?.anchorId == 'role_${role.name}')
            _confirmation(fresh)
          else
            _action(
              id: 'wallet_primary_${role.name}',
              label: label,
              onPressed: readyCurrent || next == ZyraWalletNextStep.unavailable
                  ? null
                  : _guard(fresh, () => _handlePrimary(role, next)),
            ),
        ],
      ),
    );
  }

  String _roleDetail(ZyraWalletRole role, ZyraWalletNextStep next) {
    final facts = widget.draft.forRole(role);
    return switch (next) {
      ZyraWalletNextStep.switchProfile =>
        facts.coverage == ZyraWalletCoverage.basic
            ? 'Basic already covers this role. You do not need to buy it again to switch.'
            : 'This role is already covered. No additional membership purchase is needed to switch.',
      ZyraWalletNextStep.finishSetup =>
        'Membership is already covered. Complete this profile’s setup without buying it again.',
      ZyraWalletNextStep.usePlace =>
        'You have an available ${role.label} One place. Review using it for yourself before continuing.',
      ZyraWalletNextStep.chooseMembership =>
        'This profile is ready, but it has no confirmed membership. Review a membership before continuing.',
      ZyraWalletNextStep.startSetup =>
        'Set up this profile first. No membership is purchased automatically.',
      ZyraWalletNextStep.unavailable =>
        'We cannot confirm this profile, coverage or available places. Nothing is treated as unpaid and no purchase is offered.',
    };
  }

  void _handlePrimary(ZyraWalletRole role, ZyraWalletNextStep expected) {
    if (widget.draft.nextStep(role) != expected) return;
    switch (expected) {
      case ZyraWalletNextStep.switchProfile:
        widget.onSwitch(role);
      case ZyraWalletNextStep.finishSetup:
      case ZyraWalletNextStep.startSetup:
        widget.onSetup(role);
      case ZyraWalletNextStep.chooseMembership:
        widget.onMembership(role);
      case ZyraWalletNextStep.usePlace:
        final available = widget.draft.availableFor(role);
        if (available.isEmpty) return;
        setState(() {
          _intent = _WalletIntent(
            placeId: available.first.id,
            forSelf: true,
            anchorId: 'role_${role.name}',
          );
        });
      case ZyraWalletNextStep.unavailable:
        return;
    }
  }

  Widget _confirmation(bool Function() fresh) {
    final intent = _intent!;
    final matches = widget.draft.places.where(
      (place) => place.id == intent.placeId,
    );
    if (matches.isEmpty) return const SizedBox.shrink();
    final place = matches.single;
    final recipient = place.role == ZyraWalletRole.seeker ? 'Amina' : 'Omar';
    return Semantics(
      liveRegion: true,
      child: _card(
        id: 'wallet_confirmation',
        emphasized: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              intent.forSelf
                  ? 'Use this ${place.role.label} place?'
                  : 'Assign this ${place.role.label} place?',
              style: widget.switchOnly
                  ? ZyraText.heading(size: 20)
                  : _walletHeading(20),
            ),
            const SizedBox(height: 12),
            _body(
              intent.forSelf
                  ? 'Profile setup stays separate. No real subscription changes are made here.'
                  : 'Preview an invitation for $recipient. It will stay pending until agreement; no invitation is sent and no access or Guardian link is granted.',
            ),
            const SizedBox(height: 16),
            _action(
              id: 'wallet_confirm',
              label: intent.forSelf ? 'Use this place' : 'Preview invitation',
              onPressed: _guard(fresh, () {
                if (!identical(_intent, intent)) return;
                final next = intent.forSelf
                    ? widget.draft.useAvailablePlace(
                        place.role,
                        placeId: place.id,
                      )
                    : widget.draft.assignFictionalRecipient(place.id);
                if (identical(next, widget.draft)) return;
                setState(() => _intent = null);
                widget.onChanged(next);
              }),
            ),
            const SizedBox(height: 8),
            _action(
              id: 'wallet_cancel',
              label: 'Cancel',
              onPressed: _guard(fresh, () {
                if (identical(_intent, intent)) setState(() => _intent = null);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(String value, {double size = 13}) => Text(
    value,
    style: widget.switchOnly
        ? ZyraText.body(
            size: size,
            color: ZyraColors.foregroundBody,
          ).copyWith(height: 1.5)
        : _walletBodyStyle(size),
  );

  Widget _card({String? id, bool emphasized = false, required Widget child}) =>
      Container(
        key: id == null ? null : ValueKey(id),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          // Coverage is signalled by the gold outline, not a pale overlay.
          color: ZyraColors.surfaceFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: emphasized
                ? ZyraColors.journeyGold.withValues(alpha: 0.5)
                : ZyraColors.surfaceBorder,
          ),
        ),
        child: child,
      );

  Widget _action({
    required String id,
    required String label,
    required VoidCallback? onPressed,
  }) => OutlinedButton(
    key: ValueKey(id),
    style: OutlinedButton.styleFrom(
      foregroundColor: ZyraColors.journeyGold,
      disabledForegroundColor: ZyraColors.foregroundSecondary,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      tapTargetSize: widget.switchOnly
          ? null
          : MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(
        color: onPressed == null
            ? ZyraColors.surfaceBorder
            : ZyraColors.journeyGold.withValues(alpha: 0.65),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    onPressed: ZyraTapFeedback.onTap(context, onPressed),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: widget.switchOnly
          ? ZyraText.button(
              size: 13,
              color: onPressed == null
                  ? ZyraColors.foregroundSecondary
                  : ZyraColors.journeyGold,
            )
          : _walletButtonStyle.copyWith(
              color: onPressed == null
                  ? ZyraColors.foregroundSecondary
                  : _walletGold,
            ),
    ),
  );
}
