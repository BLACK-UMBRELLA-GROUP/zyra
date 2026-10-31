import 'zyra_tap_feedback.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../data/zyra_membership_catalog.dart';
import '../dev/zyra_app_gold_preview.dart';

import '../models/zyra_dashboard_resolution.dart';
import '../models/zyra_supportive_dashboard.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_promotion_engine.dart';
import '../state/app_state.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_my_zyra_design_kit.dart';
import 'zyra_my_zyra_navigation_card.dart';
import 'floating_nav_bar.dart';
import 'zyra_fade_edges.dart';
import 'zyra_gold_action_pill.dart';
import 'zyra_locked_feature_upgrade.dart';
import 'zyra_segmented_toggle.dart';

/// Founder-selected Quiet Index: no section subtitles, one fine divider
/// between nonempty groups. Domain state and owner actions remain elsewhere.
/// Ordinary data is renderable in every build; fictional supplements require
/// both the existing developer authority and a non-release build.
class ZyraQuietDashboard extends StatefulWidget {
  final DashboardResolution resolution;
  final List<SupportiveCard> fixtureCards;
  final bool fixtureMode;
  final DateTime? comparisonClock;
  final String? firstName;
  final int? selectedTabIndex;
  final ValueChanged<int>? onTabChanged;
  final ValueChanged<SupportiveCard>? onNavigate;

  /// Signals an explicitly opened notification detail, never tab arrival,
  /// passive exposure, closing details, editorial cards or local fixtures.
  /// The parent owns exact-ID/account/session acknowledgement authority.
  final ValueChanged<SupportiveCard>? onNotificationViewed;
  final VoidCallback? onRetry;
  final VoidCallback? onMarkAllNotificationsRead;
  final int unreadCount;
  final Future<void> Function()? onRefresh;
  final bool insightsEntitled;
  final bool blankUntilDeveloperSelection;

  /// Optional presentation-only rehearsal: one information page, no Insights
  /// pager. Ordinary callers keep the existing two-section dashboard.
  final bool singlePage;

  /// Presentation-only heading placement. Ordinary callers keep the original.
  final Alignment titleAlignment;

  /// Opt-in protected preview layout. The three existing Journey destinations
  /// become permanent rows; dynamic actions stay in their own section.
  final bool permanentNavigation;

  /// Session-only activity rehearsal supplied by the protected shell. These
  /// seams are ignored outside its authorized single-page fixture layout.
  final Object? activityPreviewKey;
  final Widget? activityPreviewControls;

  /// Optional caller-owned presentation/upgrade seams for isolated rehearsals.
  /// Ordinary callers retain the current canvas and upgrade destination.
  final Decoration? decoration;
  final VoidCallback? onInsightsUpgrade;

  const ZyraQuietDashboard({
    super.key,
    required this.resolution,
    this.fixtureCards = const [],
    this.fixtureMode = false,
    this.comparisonClock,
    this.firstName,
    this.selectedTabIndex,
    this.onTabChanged,
    this.onNavigate,
    this.onNotificationViewed,
    this.onRetry,
    this.onMarkAllNotificationsRead,
    this.unreadCount = 0,
    this.onRefresh,
    this.insightsEntitled = true,
    this.blankUntilDeveloperSelection = false,
    this.singlePage = false,
    this.titleAlignment = Alignment.centerLeft,
    this.permanentNavigation = false,
    this.activityPreviewKey,
    this.activityPreviewControls,
    this.decoration,
    this.onInsightsUpgrade,
  });

  @override
  State<ZyraQuietDashboard> createState() => _ZyraQuietDashboardState();
}

class _ZyraQuietDashboardState extends State<ZyraQuietDashboard> {
  late int _tab;
  String? _expanded;
  bool _showAllActions = false;
  final _hidden = <String>{};
  final _muted = <SupportiveSection>{};
  late final PageController _pager;
  final _nowScroll = ScrollController();
  final _insightsScroll = ScrollController();
  int _generation = 0;
  double _pagerPosition = 0;
  late int _settledPage;

  bool get _allowed =>
      !widget.fixtureMode ||
      (!kReleaseMode && ZyraDeveloperAccess.canUseDeveloperTools);

  bool _canPreviewActivities(ZyraQuietDashboard candidate) =>
      candidate.fixtureMode &&
      candidate.singlePage &&
      candidate.permanentNavigation &&
      !kReleaseMode &&
      ZyraDeveloperAccess.canUseDeveloperTools;

  Object? get _activityPreviewKey =>
      _canPreviewActivities(widget) ? widget.activityPreviewKey : null;

  @override
  void initState() {
    super.initState();
    _tab = widget.singlePage ? 0 : (widget.selectedTabIndex ?? 0).clamp(0, 1);
    _pagerPosition = _tab.toDouble();
    _settledPage = _tab;
    _pager = PageController(initialPage: _tab)..addListener(_trackPager);
    ZyraDeveloperAccess.authorizationChanges.addListener(_clearAuthorityState);
  }

  void _clearAuthorityState() {
    if (!mounted) return;
    setState(() {
      _generation++;
      _resetPrivateState();
    });
  }

  void _resetPrivateState() {
    _expanded = null;
    _hidden.clear();
    _muted.clear();
    _showAllActions = false;
  }

  @override
  void didUpdateWidget(covariant ZyraQuietDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixtureMode != widget.fixtureMode ||
        oldWidget.singlePage != widget.singlePage ||
        oldWidget.permanentNavigation != widget.permanentNavigation ||
        (_canPreviewActivities(oldWidget)
                ? oldWidget.activityPreviewKey
                : null) !=
            _activityPreviewKey) {
      _generation++;
      _resetPrivateState();
      if (widget.singlePage) {
        _tab = _settledPage = 0;
        _pagerPosition = 0;
      }
    }
    if (!widget.singlePage &&
        widget.selectedTabIndex != null &&
        oldWidget.selectedTabIndex != widget.selectedTabIndex) {
      final target = widget.selectedTabIndex!.clamp(0, 1);
      void move() {
        if (!mounted || !_pager.hasClients || target == _settledPage) return;
        ZyraSegmentedMotion.animateToPage(_pager, target);
      }

      if (_pager.hasClients) {
        move();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => move());
      }
    }
  }

  void _trackPager() {
    if (!mounted || !_pager.hasClients || _pager.page == null) return;
    final position = _pager.page!.clamp(0.0, 1.0);
    final settled = position == position.roundToDouble()
        ? position.round()
        : null;
    final pageChanged = settled != null && settled != _settledPage;
    final positionChanged = (position - _pagerPosition).abs() >= 0.001;
    if (!positionChanged && !pageChanged) return;
    setState(() {
      if (pageChanged) {
        _pagerPosition = settled.toDouble();
      } else if (positionChanged) {
        _pagerPosition = position;
      }
      if (!pageChanged) return;
      _settledPage = settled;
      _tab = settled;
      _expanded = null;
      _generation++;
    });
    if (pageChanged) widget.onTabChanged?.call(settled);
  }

  void _selectTab(int tab) {
    if (!_allowed || widget.singlePage) return;
    ZyraSegmentedMotion.animateToPage(_pager, tab);
  }

  @override
  void dispose() {
    ZyraDeveloperAccess.authorizationChanges.removeListener(
      _clearAuthorityState,
    );
    _pager.dispose();
    _nowScroll.dispose();
    _insightsScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Never re-interpret a denied sample snapshot as ordinary account data.
    if (!_allowed) {
      return const SizedBox.shrink(key: ValueKey('quiet-index-fixture-denied'));
    }
    return Container(
      key: const ValueKey('my-zyra-quiet-dashboard'),
      decoration:
          widget.decoration ??
          ZyraAppGoldDecoration(
            gradient: ZyraColors.genderGradient(AppState.instance.gender),
          ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: widget.titleAlignment,
                  child: Text(
                    'My ZYRA',
                    key: const ValueKey('my-zyra-main-title'),
                    textAlign: widget.titleAlignment.x > 0
                        ? TextAlign.right
                        : TextAlign.left,
                    style: ZyraText.pageTitle(),
                  ),
                ),
              ),
              if (!widget.singlePage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: _navigation(),
                ),
              Expanded(
                child: widget.singlePage
                    ? _content(context, 0, _nowScroll)
                    : PageView(
                        key: const ValueKey('my-zyra-pages'),
                        controller: _pager,
                        physics: ZyraSegmentedMotion.pagePhysics,
                        children: [
                          _content(context, 0, _nowScroll),
                          _content(context, 1, _insightsScroll),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, int tab, ScrollController scroll) {
    final generation = _generation;
    final fixtureMode = widget.fixtureMode;
    final singlePage = widget.singlePage;
    final permanentNavigation = widget.permanentNavigation;
    final activityPreviewKey = _activityPreviewKey;
    final capturedResolution = widget.resolution;
    final notificationViewed = widget.onNotificationViewed;
    bool current() =>
        mounted &&
        _allowed &&
        generation == _generation &&
        fixtureMode == widget.fixtureMode &&
        singlePage == widget.singlePage &&
        permanentNavigation == widget.permanentNavigation &&
        activityPreviewKey == _activityPreviewKey;
    if (widget.blankUntilDeveloperSelection) {
      return _scrollSurface(
        ListView(
          key: ValueKey('my-zyra-quiet-scroll-$tab'),
          controller: scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 130),
        ),
        current,
        tab,
      );
    }
    final data = MyZyraReviewData(
      resolution: widget.resolution,
      isInsights: tab == 1,
      fixtureMode: fixtureMode,
      fixtureCards: widget.fixtureCards,
      clock: widget.comparisonClock ?? DateTime.now(),
      hiddenCards: _hidden,
      mutedSections: _muted,
      showAllActions: _showAllActions,
    );
    final kit = MyZyraDesignKit(
      data: data,
      firstName: widget.firstName,
      showAllActions: _showAllActions,
      expandedEvidence: _expanded,
      onOpen: (card) {
        if (!current()) return;
        setState(() => _expanded = null);
        widget.onNavigate?.call(card);
      },
      onEvidence: (id) {
        if (!current()) return;
        final opening = _expanded != id;
        setState(() => _expanded = opening ? id : null);
        if (!opening ||
            fixtureMode ||
            tab != 0 ||
            _settledPage != 0 ||
            _pagerPosition != 0 ||
            notificationViewed == null ||
            !identical(capturedResolution, widget.resolution) ||
            !identical(notificationViewed, widget.onNotificationViewed) ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        for (final card in data.changes) {
          if (card.id == id && card.isUnread == true) {
            notificationViewed(card);
            break;
          }
        }
      },
      onHide: (card) {
        if (!current() || !fixtureMode) return;
        setState(() {
          _hidden.add(card.id);
          _expanded = null;
        });
      },
      onMute: (card) {
        if (!current() || !fixtureMode) return;
        setState(() {
          _muted.add(card.section);
          _expanded = null;
        });
      },
      onMoreActions: () {
        if (current()) setState(() => _showAllActions = !_showAllActions);
      },
      onResetInsights: () {
        if (current()) setState(_resetPrivateState);
      },
      onRetry: widget.onRetry == null
          ? null
          : () {
              if (current()) widget.onRetry!();
            },
    );
    final groups = <Widget>[];
    final insightsBlocked = data.isInsights && !widget.insightsEntitled;
    if (data.isInsights && !insightsBlocked) {
      for (final section in SupportiveSection.values.where(
        (v) => v.isInsight,
      )) {
        final cards = data.insights.where((c) => c.section == section).toList();
        if (cards.isNotEmpty) groups.add(_items(cards.map((c) => kit.item(c))));
      }
    } else if (!data.isInsights) {
      if (data.actions.isNotEmpty) {
        final actions = _items([
          permanentNavigation
              ? _permanentLead(kit, data.actions.first)
              : kit.item(data.actions.first, prominent: true),
          for (final card in data.actions.skip(1))
            kit.item(card, compact: true),
          if (data.actionCount > 3) kit.moreActions,
        ]);
        final activity = permanentNavigation
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _permanentHeading(
                    data.actions.any((card) => card.hasNewActivity)
                        ? 'New activity'
                        : 'Activity',
                    gold: data.actions.any((card) => card.hasNewActivity),
                  ),
                  const SizedBox(height: 16),
                  actions,
                ],
              )
            : actions;
        groups.add(_previewActivity(context, activity));
      }
      if (data.statuses.isNotEmpty) {
        if (permanentNavigation) {
          final destinations = [
            for (final id in ZyraMyZyraNavigationCard.destinationIds)
              ...data.statuses.where((card) => card.id == id),
          ];
          if (destinations.isNotEmpty) {
            groups.add(
              Column(
                key: _canPreviewActivities(widget)
                    ? const ValueKey('my-zyra-preview-permanent-group')
                    : null,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _permanentHeading('Quick access'),
                  const SizedBox(height: 16),
                  for (final (index, card) in destinations.indexed) ...[
                    if (index > 0) const SizedBox(height: 12),
                    ZyraMyZyraNavigationCard(
                      key: _canPreviewActivities(widget)
                          ? ValueKey('my-zyra-preview-destination-${card.id}')
                          : null,
                      card: card,
                      onOpen: () => kit.onOpen(card),
                    ),
                  ],
                ],
              ),
            );
          }
          final otherStatuses = data.statuses.where(
            (card) => !ZyraMyZyraNavigationCard.isDestination(card.id),
          );
          if (otherStatuses.isNotEmpty) {
            groups.add(_items(otherStatuses.map((card) => kit.item(card))));
          }
        } else {
          groups.add(_items(data.statuses.map((card) => kit.item(card))));
        }
      }
      final canMarkRead =
          !fixtureMode &&
          widget.onMarkAllNotificationsRead != null &&
          (widget.unreadCount > 0 ||
              data.changes.any((c) => c.isUnread == true));
      if (data.changes.isNotEmpty || canMarkRead) {
        groups.add(
          _items([
            ...data.changes.map((c) => _disclosure(kit, c)),
            if (canMarkRead)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('quiet-index-mark-read'),
                  onPressed: ZyraTapFeedback.onTap(context, () {
                    if (current() && !fixtureMode) {
                      widget.onMarkAllNotificationsRead!();
                    }
                  }),
                  child: Text(
                    'Mark all read',
                    style: ZyraText.body(
                      size: 12.5,
                      color: MyZyraDesignKit.secondary,
                    ),
                  ),
                ),
              ),
          ]),
        );
      }
      if (data.editorial.isNotEmpty) {
        groups.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source attribution, not a category heading.
              kit.label('ZYRA'),
              const SizedBox(height: 10),
              _items(data.editorial.map((c) => _disclosure(kit, c))),
            ],
          ),
        );
      }
    }
    return _scrollSurface(
      ListView(
        key: ValueKey('my-zyra-quiet-scroll-$tab'),
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 130),
        children: [
          if (_canPreviewActivities(widget) &&
              widget.activityPreviewControls != null)
            Padding(
              key: const ValueKey('my-zyra-activity-preview-controls'),
              padding: const EdgeInsets.only(bottom: 16),
              child: widget.activityPreviewControls!,
            ),
          if (insightsBlocked)
            Padding(
              key: const ValueKey('quiet-index-insights-locked'),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    key: const ValueKey('seeker-insights-content-lock'),
                    color: ZyraColors.journeyGold,
                    size: 28,
                  ),
                  const SizedBox(height: 16),
                  kit.heading(
                    'Insights are part of ${ZyraMembershipCatalog.seekerOneTitle}',
                  ),
                  const SizedBox(height: 18),
                  kit.body(
                    'Upgrade to unlock deeper activity and Journey insights. '
                    'Your current Journey and account controls remain available.',
                  ),
                  const SizedBox(height: 24),
                  ZyraGoldActionPill(
                    key: const ValueKey('seeker-insights-upgrade'),
                    label: 'View ${ZyraMembershipCatalog.seekerOneTitle}',
                    icon: Icons.workspace_premium_outlined,
                    onPressed:
                        widget.onInsightsUpgrade ??
                        () => openSeekerLockedFeaturePlan(
                          context,
                          feature: ZyraPromotionFeature.zyraIntelligence,
                        ),
                  ),
                ],
              ),
            )
          else
            kit.notice,
          if (data.quietNow && !data.isInsights)
            Padding(
              key: const ValueKey('my-zyra-quiet'),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  kit.heading('You’re all caught up', size: 30),
                  const SizedBox(height: 16),
                  kit.body('Nothing needs your attention right now.'),
                ],
              ),
            ),
          if (data.isInsights &&
              !insightsBlocked &&
              data.insights.isEmpty &&
              data.resolution.insightsState == DashboardSectionState.available)
            _emptyInsights(kit),
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Divider(
                  key: ValueKey('quiet-index-group-rule-$i'),
                  height: 1,
                  thickness: .7,
                  color: MyZyraDesignKit.ink.withValues(alpha: .25),
                ),
              ),
            groups[i],
          ],
          if (data.isInsights && !insightsBlocked) kit.resetInsights,
        ],
      ),
      current,
      tab,
    );
  }

  Widget _previewActivity(BuildContext context, Widget activity) {
    final previewKey = _activityPreviewKey;
    if (previewKey == null) return activity;
    final keyed = KeyedSubtree(key: ValueKey(previewKey), child: activity);
    // Reduced motion must not retain an AnimatedSize whose duration is zero:
    // rendering the current group directly also removes outgoing semantics.
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return keyed;
    }
    return AnimatedSize(
      key: const ValueKey('my-zyra-activity-preview-size'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topLeft,
      child: AnimatedSwitcher(
        key: const ValueKey('my-zyra-activity-preview-transition'),
        duration: const Duration(milliseconds: 180),
        reverseDuration: const Duration(milliseconds: 140),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final outgoing = child.key != keyed.key;
          return IgnorePointer(
            ignoring: outgoing,
            child: ExcludeSemantics(
              excluding: outgoing,
              child: FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: keyed,
      ),
    );
  }

  Widget _scrollSurface(Widget child, bool Function() current, int tab) {
    if (widget.onRefresh != null && !widget.fixtureMode) {
      child = RefreshIndicator(
        color: ZyraColors.accentOnCanvas,
        backgroundColor: ZyraColors.surfaceFill,
        onRefresh: () async {
          if (current()) await widget.onRefresh!();
        },
        child: child,
      );
    }
    return ZyraFadeEdges.bottomOnly(
      key: ValueKey(
        'dashboard-nav-scroll-fade-${tab == 0 ? 'now' : 'insights'}',
      ),
      bottom:
          ZyraNavBarMetrics.restingHeight + ZyraNavBarMetrics.bottomInset + 10,
      child: child,
    );
  }

  Widget _items(Iterable<Widget> values) {
    final items = values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          items[i],
        ],
      ],
    );
  }

  Widget _permanentHeading(String label, {bool gold = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          label,
          key: ValueKey(
            gold
                ? 'my-zyra-new-activity-heading'
                : label == 'Quick access'
                ? 'my-zyra-quick-access-heading'
                : 'my-zyra-activity-heading',
          ),
          style: ZyraText.body(
            size: 11,
            color: gold ? ZyraColors.goldText : ZyraColors.foregroundSecondary,
          ).copyWith(letterSpacing: 1.2, height: 1.5),
        ),
      ),
    ],
  );

  Widget _permanentLead(MyZyraDesignKit kit, SupportiveCard card) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          final scaler = MediaQuery.textScalerOf(context);
          final direction = Directionality.of(context);
          var chosen = 14.0;
          for (final size in [29.0, 26.0, 24.0, 22.0, 20.0, 18.0, 16.0, 14.0]) {
            final style = ZyraText.heading(
              size: size,
              color: MyZyraDesignKit.ink,
            ).copyWith(height: 1.22);
            var fits = true;
            for (final word in card.title.trim().split(RegExp(r'\s+'))) {
              final painter = TextPainter(
                text: TextSpan(text: word, style: style),
                textDirection: direction,
                textScaler: scaler,
              )..layout();
              fits = fits && painter.width <= available;
              painter.dispose();
              if (!fits) break;
            }
            if (fits) {
              chosen = size;
              break;
            }
          }
          return kit.item(card, prominent: true, prominentSize: chosen);
        },
      );

  Widget _disclosure(MyZyraDesignKit kit, SupportiveCard card) {
    final expanded = _expanded == card.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expanded)
          KeyedSubtree(
            key: ValueKey('quiet-index-details-${card.id}'),
            child: kit.item(card),
          )
        else
          kit.summary(card),
        Semantics(
          expanded: expanded,
          child: TextButton(
            key: ValueKey('quiet-index-disclosure-${card.id}'),
            onPressed: ZyraTapFeedback.onTap(
              context,
              () => kit.onEvidence(card.id),
            ),
            style: TextButton.styleFrom(
              foregroundColor: MyZyraDesignKit.secondary,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.centerLeft,
            ),
            child: Semantics(
              label: '${expanded ? 'Close' : 'Read'} details: ${card.title}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(
                    child: kit.label(
                      expanded ? 'Close details' : 'Read details',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    expanded ? Icons.remove_rounded : Icons.add_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyInsights(MyZyraDesignKit kit) => Padding(
    key: ValueKey(
      kit.data.allInsightsHidden
          ? 'my-zyra-insights-hidden'
          : 'my-zyra-insights-empty',
    ),
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kit.heading(
          kit.data.allInsightsHidden
              ? 'These Insights are hidden in this preview'
              : 'Insights will grow with your ZYRA experience',
          size: 27,
        ),
        const SizedBox(height: 18),
        kit.body(
          kit.data.allInsightsHidden
              ? 'Your preview choices are not saved to your account.'
              : 'ZYRA will only show an Insight when reliable information genuinely supports it. We will not guess or fill this page with generic statistics.',
        ),
      ],
    ),
  );

  Widget _navigation() => Semantics(
    label: 'My ZYRA section selector',
    child: ZyraSegmentedToggle(
      key: const ValueKey('my-zyra-tab-slider'),
      labels: const ['Now', 'Insights'],
      position: _pagerPosition,
      segmentKeys: const [
        ValueKey('my-zyra-now-tab'),
        ValueKey('my-zyra-insights-tab'),
      ],
      lockedIndexes: widget.insightsEntitled ? const {} : const {1},
      onChanged: _selectTab,
    ),
  );
}
