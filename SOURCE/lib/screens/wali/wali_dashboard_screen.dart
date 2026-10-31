// Guardian Dashboard — one person-first family-support home.
//
// Each linked Seeker owns one swipeable page. Their authorised current state,
// updates and Guardian-safe Insights live together beneath their name rather
// than being split into abstract Now / Insights destinations.
//
// 2026-08-13, DR-ZYRA-152: the Guardian dev panel composes wards,
// journeys and the staged review only for a protected developer-capable
// session — real rows first, stand-ins topping up, 0 meaning zero. The
// production target calls none of it, including in release mode.
// 2026-08-14 (DR-ZYRA-166): loading is checked before empty.
// 2026-08-15: the journeys fetch distinguishes FAILURE from empty
// (DR-ZYRA-167's rule) — a failed load shows an error with Try again,
// never an empty state with an invite button.
//
// An Additional Guardian contributes to the linked-Seeker count but never to
// Journey-derived copy or aggregates. Main authority is partitioned before
// any Journey field is read, matching DR-ZYRA-225.
//
// Rosters, invitations and per-person Journey context are owned by their
// dedicated pages. This Dashboard only summarises and routes.

import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/zyra_membership_catalog.dart';
import '../../dev/zyra_app_gold_preview.dart';
import 'package:flutter/foundation.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../models/zyra_dashboard_lab.dart';
import '../../models/zyra_dashboard_resolution.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_guardian_dashboard_resolver.dart';
import '../../services/zyra_dashboard_updates_service.dart';
import '../../services/zyra_journey_service.dart';
import '../../services/zyra_notification_service.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../services/zyra_wali_journey_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_account_state.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/zyra_fade_edges.dart';
import '../../widgets/zyra_segmented_toggle.dart';
import '../../widgets/zyra_scrollable_seeker_selector.dart';
import '../../widgets/zyra_guardian_dashboard_profile_card.dart';
import 'wali_journey_detail_screen.dart';
import '../../widgets/zyra_loading.dart';
import '../subscription/upgrade_screen.dart';
import '../profile/seeker_profile_screen.dart';

class WaliDashboardScreen extends StatefulWidget {
  /// A protected zero-linked, no-network result after local onboarding.
  final bool initialOnboardingPreview;
  final bool hasGuardianPlus;
  final bool isActive;
  final int notificationCount;
  final VoidCallback? onOpenNetwork;
  final VoidCallback? onOpenSeekers;
  final ValueChanged<String>? onOpenSeeker;
  final Future<List<SeekerProfile>> Function(List<String> ids)? loadProfiles;
  final VoidCallback? onNotificationsChanged;
  final Future<List<WaliJourneyView>?> Function()? loadJourneys;
  final Future<ZyraDashboardUpdatesPage?> Function()? loadUpdates;
  final Future<ZyraSourceResult<Set<String>>> Function(List<String> matchIds)?
  loadOpenReviews;
  final DateTime? comparisonNow;

  const WaliDashboardScreen({
    super.key,
    this.initialOnboardingPreview = false,
    this.hasGuardianPlus = false,
    this.isActive = true,
    this.notificationCount = 0,
    this.onOpenNetwork,
    this.onOpenSeekers,
    this.onOpenSeeker,
    this.loadProfiles,
    this.onNotificationsChanged,
    this.loadJourneys,
    this.loadUpdates,
    this.loadOpenReviews,
    this.comparisonNow,
  });

  @override
  State<WaliDashboardScreen> createState() => _WaliDashboardScreenState();
}

class _WaliDashboardScreenState extends State<WaliDashboardScreen> {
  static const _dashboardResolver = ZyraGuardianDashboardResolver();

  bool _loading = true;
  late final ZyraNotificationOwnerLease? _notificationOwner;
  final Set<String> _pendingAcknowledgements = {};
  late PageController _pager;
  int _pagerOrigin = 0;
  List<String> _pagerPeople = const [];
  double _pagerPosition = 0;
  int _selectorInteractionRevision = 0;

  /// True when the LAST journeys fetch failed (null from the service).
  /// Rows already on screen stay (stale beats blank); with nothing to
  /// show, the error state owns the body. DR-ZYRA-167's pattern.
  bool _loadFailed = false;
  bool _hasJourneyTruth = false;
  bool _reviewLoadFailed = false;
  bool _hasReviewTruth = false;
  bool _reviewsLoading = true;
  List<WaliJourneyView> _journeys = [];
  Map<String, SeekerProfile> _profiles = const {};
  List<String> _profileRosterIds = const [];
  int _profileGeneration = 0;
  int _loadRevision = 0;
  late final String? _ownerUserId;
  late final int _ownerGeneration;
  bool _profilesLoading = true;

  bool get _currentAccount =>
      ZyraAccountState.userId == _ownerUserId &&
      ZyraAccountState.generation == _ownerGeneration;

  /// Updates has its own query truth. It must not inherit Today's empty or
  /// failure state, and Timeline failures must never become "all caught up".
  bool _updatesLoading = true;
  bool _updatesFailed = false;

  /// Journeys with a Family Review open — the one thing on this screen
  /// that is waiting on THE GUARDIAN. One batched query; Main-only under
  /// RLS, exactly like the detail screen.
  Set<String> _openReviews = const {};

  /// The one RPC-backed Updates page. A failed refresh retains these rows and
  /// marks them visibly last-known; only a successful empty response clears.
  List<ZyraDashboardUpdate> _updates = const [];

  @override
  void initState() {
    super.initState();
    _notificationOwner = ZyraNotificationOwnerLease.capture();
    _ownerUserId = ZyraAccountState.userId;
    _ownerGeneration = ZyraAccountState.generation;
    if (widget.initialOnboardingPreview) {
      _loading = false;
      _hasJourneyTruth = true;
      _reviewsLoading = false;
      _hasReviewTruth = true;
      _updatesLoading = false;
      _profilesLoading = false;
    }
    _configurePager(_wards, selectedIndex: 0);
    AppState.instance.addListener(_onChange);
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      ZyraDevScenario.instance.addListener(_onChange);
    }
    if (!widget.initialOnboardingPreview) {
      _load();
      _loadProfiles();
    }
  }

  void _onPagerScroll() {
    if (!_pager.hasClients || _pagerPeople.isEmpty) return;
    final rawPage = (_pager.page ?? _pagerOrigin.toDouble()) - _pagerOrigin;
    final nearest = rawPage.roundToDouble();
    final page = (rawPage - nearest).abs() < .001 ? nearest : rawPage;
    if ((page - _pagerPosition).abs() < .000001 || !mounted) return;
    setState(() => _pagerPosition = page);
  }

  void _configurePager(
    List<WaliLinkedPerson> people, {
    required int selectedIndex,
  }) {
    _pagerPeople = [for (final person in people) person.id];
    // The origin is a whole number of laps, so logical page0 is person0.
    // Recentring at idle keeps repeated laps away from PageView's lower bound.
    _pagerOrigin = people.length > 3 ? people.length * 100000 : 0;
    _pagerPosition = selectedIndex.toDouble();
    _pager = PageController(
      initialPage: _pagerOrigin + selectedIndex,
      keepPage: false,
    )..addListener(_onPagerScroll);
  }

  void _recenterCarousel() {
    final count = _pagerPeople.length;
    if (count <= 3 || _pagerPosition.abs() < count * 100) return;
    final controller = _pager;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          controller != _pager ||
          !controller.hasClients ||
          controller.position.isScrollingNotifier.value) {
        return;
      }
      final index = _pagerPosition.round() % count;
      // A whole-lap shift leaves the same three names and person visible.
      setState(() => _selectorInteractionRevision++);
      controller.jumpToPage(_pagerOrigin + index);
    });
  }

  /// The authority context behind this compact summary — panel-composed in
  /// protected Test sessions and untouched for normal members. The Dashboard does not
  /// render these rows as a roster.
  List<WaliLinkedPerson> get _wards {
    if (widget.initialOnboardingPreview) return const [];
    final real = AppState.instance.waliRealLinkedSeekers;
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return real;
    return ZyraDevScenario.composeWaliWards(real: real);
  }

  /// The Journeys this screen draws.
  List<WaliJourneyView> get _visibleJourneys {
    if (widget.initialOnboardingPreview) return const [];
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return _journeys;
    return ZyraDevScenario.composeWaliJourneys(wards: _wards, real: _journeys);
  }

  Future<void> _loadProfiles({bool force = false}) async {
    if (widget.initialOnboardingPreview || !_currentAccount) return;
    final ids = [
      for (final person in _wards)
        if (widget.loadProfiles != null || !person.id.startsWith('dev-ws'))
          person.id,
    ];
    if (!force &&
        _profileGeneration > 0 &&
        listEquals(ids, _profileRosterIds)) {
      return;
    }
    _profileRosterIds = ids;
    final generation = ++_profileGeneration;
    setState(() {
      _profiles = const {};
      _profilesLoading = ids.isNotEmpty;
    });
    List<SeekerProfile> profiles;
    try {
      profiles = widget.loadProfiles != null
          ? await widget.loadProfiles!(ids)
          : await ZyraDiscoveryService.profilesByIds(
              ids,
              includeWithoutPhotos: true,
            );
    } catch (_) {
      profiles = const [];
    }
    if (!mounted || generation != _profileGeneration || !_currentAccount) {
      return;
    }
    final linkedIds = {for (final person in _wards) person.id};
    setState(() {
      _profiles = {
        for (final profile in profiles)
          if (ids.contains(profile.id) && linkedIds.contains(profile.id))
            profile.id: profile,
      };
      _profilesLoading = false;
    });
  }

  SeekerProfile? _profileFor(WaliLinkedPerson person) {
    final confirmed = _profiles[person.id];
    if (confirmed != null) return confirmed;
    if (widget.loadProfiles != null ||
        !ZyraDeveloperAccess.canUseDeveloperTools ||
        !person.id.startsWith('dev-ws')) {
      return null;
    }
    // Protected local stand-ins only. Never borrow Journey-partner details or
    // turn absent real member data into a demo profile.
    final index = int.tryParse(person.id.substring('dev-ws'.length)) ?? 0;
    final fixture = mockProfiles[index % mockProfiles.length];
    return SeekerProfile(
      id: person.id,
      firstName: person.firstName,
      age: fixture.age,
      city: fixture.city,
      photos: fixture.photos,
      gender: fixture.gender,
    );
  }

  void _openProfile(WaliLinkedPerson person) {
    // Re-check current roster/model at tap time, after carousel or roster moves.
    if (!_wards.any((linked) => linked.id == person.id)) return;
    final profile = _profileFor(person);
    if (profile == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SeekerProfileScreen(
          profile: profile,
          swipeDownToDismiss: true,
          emptyPhoto: profile.photos.isEmpty
              ? DecoratedBox(
                  decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
                  child: Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 104,
                      color: Colors.white.withValues(alpha: .16),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _load() async {
    if (widget.initialOnboardingPreview || !_currentAccount) return;
    final revision = ++_loadRevision;
    final reads = await Future.wait<Object?>([
      (widget.loadJourneys ?? ZyraWaliJourneyService.fetchLinkedJourneys)(),
      (widget.loadUpdates ?? ZyraDashboardUpdatesService.fetchPage)(),
    ]);
    final journeys = reads[0] as List<WaliJourneyView>?;
    final updates = reads[1] as ZyraDashboardUpdatesPage?;
    if (!mounted || revision != _loadRevision || !_currentAccount) return;
    setState(() {
      if (journeys == null) {
        _loadFailed = true; // keep whatever we already had
        _reviewsLoading = false;
      } else {
        _loadFailed = false;
        _hasJourneyTruth = true;
        _journeys = journeys;
      }
      if (updates == null) {
        _updatesFailed = true;
      } else {
        _updatesFailed = false;
        _updates = updates.rows;
      }
      _updatesLoading = false;
      _loading = false;
    });
    if (journeys == null) return;

    // Second pass, deliberately not awaited before the list renders —
    // each of these makes the dashboard MORE specific, none is needed
    // for it to be correct.
    final mainSeekerIds = {
      for (final person in _wards)
        if (person.isMain) person.id,
    };
    final live = journeys
        .where(
          (j) =>
              mainSeekerIds.contains(j.linkedSeekerId) &&
              j.status != 'ended' &&
              !j.isJourneyLocked,
        )
        .map((j) => j.matchId)
        .toList();
    final openResult =
        await (widget.loadOpenReviews ??
            ZyraJourneyService.fetchOpenReviewMatchIdsResult)(live);
    if (!mounted || revision != _loadRevision || !_currentAccount) return;
    setState(() {
      _reviewsLoading = false;
      if (openResult.isAvailable) {
        _reviewLoadFailed = false;
        _hasReviewTruth = true;
        _openReviews = openResult.valueOrNull ?? const <String>{};
      } else {
        _reviewLoadFailed = true;
      }
    });
  }

  Future<void> _retry() async {
    if (widget.initialOnboardingPreview || !_currentAccount) return;
    _loadProfiles(force: true);
    setState(() {
      _loading = true;
      _updatesLoading = true;
      _reviewsLoading = true;
    });
    await _load();
  }

  bool _isCurrentUpdatePerson(String? personId) {
    if (!mounted ||
        !widget.isActive ||
        !_currentAccount ||
        widget.initialOnboardingPreview ||
        _dashboardLabActive ||
        ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }
    if (_pagerPeople.isEmpty) return personId == null && _wards.isEmpty;
    if ((_pagerPosition - _pagerPosition.round()).abs() > .001) return false;
    return _pagerPeople[_pagerPosition.round() % _pagerPeople.length] ==
            personId &&
        _wards.any((person) => person.id == personId);
  }

  bool _canAcknowledgePerson(String? personId) =>
      _isCurrentUpdatePerson(personId) && _notificationOwner?.isCurrent == true;

  Future<void> _acknowledgeShown(
    Set<String> ids,
    String? personId,
    int capturedRevision,
  ) async {
    if (!_canAcknowledgePerson(personId) ||
        ids.isEmpty ||
        capturedRevision != _loadRevision ||
        _updatesFailed ||
        _updatesLoading) {
      return;
    }
    final freshIds = ids.difference(_pendingAcknowledgements);
    if (freshIds.isEmpty) return;
    _pendingAcknowledgements.addAll(freshIds);
    final result = await ZyraNotificationService.acknowledgeIds(freshIds);
    _pendingAcknowledgements.removeAll(freshIds);
    if (!_canAcknowledgePerson(personId)) return;
    if (!result.isConfirmed) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text("Couldn't mark these updates as read. Try again."),
        ),
      );
      return;
    }
    widget.onNotificationsChanged?.call();
    await _load();
  }

  @override
  void dispose() {
    _notificationOwner?.dispose();
    ++_loadRevision;
    ++_profileGeneration;
    AppState.instance.removeListener(_onChange);
    // UNGATED removes — OA-ZYRA-250 (2026-08-23). The adds are gated,
    // and a gate that reads auth state can FLAP between initState and
    // dispose (the dev account switcher changes who is signed in), which
    // leaks the listener; the next notify then calls setState on a
    // defunct State and crashes. removeListener on a never-registered
    // listener is a documented no-op, so removing without gates is safe
    // in every build.
    ZyraDevScenario.instance.removeListener(_onChange);
    _pager.removeListener(_onPagerScroll);
    _pager.dispose();
    super.dispose();
  }

  // Mounted-guarded — OA-ZYRA-250: a notify arriving during teardown
  // must never reach setState on a defunct State.
  void _onChange() {
    if (!mounted || !_currentAccount) return;
    if (!widget.initialOnboardingPreview) _loadProfiles();
    final people = _wards;
    final ids = [for (final person in people) person.id];
    if (listEquals(ids, _pagerPeople)) {
      setState(() {});
      return;
    }
    final oldIndex = _pagerPeople.isEmpty
        ? 0
        : _pagerPosition.round() % _pagerPeople.length;
    final oldId = _pagerPeople.isEmpty ? null : _pagerPeople[oldIndex];
    final retained = oldId == null ? -1 : ids.indexOf(oldId);
    final selected = people.isEmpty
        ? 0
        : retained >= 0
        ? retained
        : oldIndex.clamp(0, people.length - 1);
    final retired = _pager..removeListener(_onPagerScroll);
    setState(() {
      _selectorInteractionRevision++;
      _configurePager(people, selectedIndex: selected);
    });
    // The rebuilt PageView detaches before its retired controller is disposed.
    WidgetsBinding.instance.addPostFrameCallback((_) => retired.dispose());
  }

  bool get _dashboardLabActive =>
      !widget.initialOnboardingPreview &&
      ZyraDeveloperAccess.canUseDeveloperTools &&
      ZyraDevScenario.instance.dashboardLabEnabled;

  /// Real open reviews plus the panel's staged one in debug/profile.
  Set<String> _reviewIds(List<WaliJourneyView> journeys) {
    if (widget.initialOnboardingPreview) return const {};
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return _openReviews;
    return {..._openReviews, ...ZyraDevScenario.waliOpenReviewIds(journeys)};
  }

  String _ago(DateTime at) {
    final d = (widget.comparisonNow ?? DateTime.now()).difference(at);
    if (d.inMinutes < 60) return 'just now';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    return '${(d.inDays / 30).floor()}mo ago';
  }

  void _openJourney(WaliJourneyView j) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaliJourneyDetailScreen(
          journey: j,
          hasGuardianOne: widget.hasGuardianPlus,
        ),
      ),
    );
  }

  /// Everything waiting on the Guardian, as cards: open Family Reviews
  /// first (a decision), then Journeys parked at the Guardian Gate (a
  /// step only a Guardian can complete).
  List<Widget> _attentionCards(List<GuardianDashboardAttention> items) => [
    for (final item in items)
      _AttentionCard(
        title: item.title,
        body: item.detail,
        cta: item.actionLabel,
        onTap: () => _openJourney(item.journey),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    // Composed ONCE per build — these walk the ward list, and calling
    // them per row would recompose for every card drawn.
    final rawLinked = _wards;
    final journeys = _visibleJourneys;
    final reviewIds = _reviewIds(journeys);
    final dev = ZyraDeveloperAccess.canUseDeveloperTools
        ? ZyraDevScenario.instance
        : null;
    final firstName =
        AppState.instance.waliName?.trim() ?? AppState.instance.name?.trim();

    final greeting = firstName == null || firstName.isEmpty
        ? 'Your ZYRA, in one place.'
        : 'Assalamu alaikum, $firstName.';
    return Container(
      decoration: ZyraAppGoldDecoration(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guardian Dashboard',
                      style: ZyraText.heading(size: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(greeting, style: ZyraText.subtext(size: 13.5)),
                  ],
                ),
              ),
              if (rawLinked.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: _seekerNavigation(rawLinked),
                ),
              Expanded(
                child: rawLinked.isEmpty
                    ? _guardianPage(
                        pageKey: 'empty',
                        children: _guardianCombinedChildren(
                          person: null,
                          resolution: _dashboardResolver.resolve(
                            linkedPeople: const [],
                            journeys: journeys,
                            openReviewIds: reviewIds,
                          ),
                          attention: const [],
                          dev: dev,
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification &&
                              notification.depth == 0 &&
                              notification.dragDetails != null) {
                            setState(() => _selectorInteractionRevision++);
                          }
                          if (notification is ScrollEndNotification &&
                              notification.depth == 0) {
                            _recenterCarousel();
                          }
                          return false;
                        },
                        child: KeyedSubtree(
                          // A new roster/controller needs a fresh Scrollable;
                          // otherwise Flutter absorbs the retired pixel offset.
                          key: ObjectKey(_pager),
                          child: PageView.custom(
                            key: const ValueKey('guardian-dashboard-pages'),
                            controller: _pager,
                            physics: ZyraSegmentedMotion.pagePhysics,
                            childrenDelegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final personIndex = index % rawLinked.length;
                                final person = rawLinked[personIndex];
                                final personJourneys = [
                                  for (final journey in journeys)
                                    if (journey.linkedSeekerId == person.id)
                                      journey,
                                ];
                                final resolution = _dashboardResolver.resolve(
                                  linkedPeople: [person],
                                  journeys: personJourneys,
                                  openReviewIds: reviewIds,
                                );
                                final page = _guardianPage(
                                  pageKey: person.id,
                                  children: _guardianCombinedChildren(
                                    person: person,
                                    resolution: resolution,
                                    attention: _attentionCards(
                                      resolution.attention,
                                    ),
                                    dev: dev,
                                  ),
                                );
                                return Semantics(
                                  label:
                                      '${person.firstName}, Seeker ${personIndex + 1} of ${rawLinked.length}',
                                  child: page,
                                );
                              },
                              childCount: rawLinked.length > 3
                                  ? null
                                  : rawLinked.length,
                              // Virtual lap indexes are never accessibility ordinals.
                              addSemanticIndexes: false,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seekerNavigation(List<WaliLinkedPerson> people) =>
      ZyraScrollableSeekerSelector(
        key: const ValueKey('guardian-dashboard-seeker-selector'),
        labels: [for (final person in people) person.firstName],
        segmentKeys: [
          for (final person in people)
            ValueKey('guardian-dashboard-seeker-${person.id}'),
        ],
        position: _pagerPosition,
        interactionRevision: _selectorInteractionRevision,
        onChanged: (index) {
          if (!_pager.hasClients) return;
          if (MediaQuery.disableAnimationsOf(context)) {
            _pager.jumpToPage(_pagerOrigin + index);
          } else {
            ZyraSegmentedMotion.animateToPage(_pager, _pagerOrigin + index);
          }
        },
      );

  Widget _guardianPage({
    required String pageKey,
    required List<Widget> children,
  }) => ZyraFadeEdges.bottomOnly(
    key: ValueKey('guardian-dashboard-fade-$pageKey'),
    bottom:
        ZyraNavBarMetrics.restingHeight + ZyraNavBarMetrics.bottomInset + 10,
    child: RefreshIndicator(
      color: ZyraColors.accentOnCanvas,
      backgroundColor: ZyraColors.surfaceFill,
      onRefresh: () async => _retry(),
      child: ListView(
        key: PageStorageKey('guardian-dashboard-$pageKey'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
        children: children,
      ),
    ),
  );

  List<Widget> _guardianCombinedChildren({
    required WaliLinkedPerson? person,
    required GuardianDashboardResolution resolution,
    required List<Widget> attention,
    required ZyraDevScenario? dev,
  }) {
    final showNow =
        widget.initialOnboardingPreview ||
        !ZyraDeveloperAccess.canUseDeveloperTools ||
        dev?.dashboardGuardianOptionSelected(ZyraDashboardTab.now) == true;
    final showInsights =
        !widget.initialOnboardingPreview &&
        (!ZyraDeveloperAccess.canUseDeveloperTools ||
            dev?.dashboardGuardianOptionSelected(ZyraDashboardTab.insights) ==
                true);
    if (ZyraDeveloperAccess.canUseDeveloperTools && !showNow && !showInsights) {
      return const [];
    }
    final profileHeader = <Widget>[
      if (person != null) ...[
        GuardianDashboardProfileCard(
          person: person,
          profile: _profileFor(person),
          detailsLoading: _profilesLoading && _profileFor(person) == null,
          onViewProfile: () => _openProfile(person),
        ),
        const SizedBox(height: 20),
      ],
    ];
    if (showNow &&
        _dashboardLabActive &&
        dev?.dashboardGuardianTodayState ==
            ZyraGuardianDashboardTodayState.loading) {
      return [
        ...profileHeader,
        const SizedBox(height: 210, child: ZyraLoading()),
      ];
    }
    if (showNow &&
        _dashboardLabActive &&
        dev?.dashboardGuardianTodayState ==
            ZyraGuardianDashboardTodayState.fullFailure) {
      return [
        ...profileHeader,
        SizedBox(
          height: 300,
          child: ZyraEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load your dashboard",
            message: 'Check your connection.',
            ctaLabel: 'Try again',
            onCta: _retry,
          ),
        ),
      ];
    }
    if (showNow && (_loading || (_reviewsLoading && !_hasReviewTruth))) {
      return [
        ...profileHeader,
        const SizedBox(height: 210, child: ZyraLoading()),
      ];
    }
    return [
      ...profileHeader,
      if (showNow) ...[
        ..._guardianToday(resolution, attention, dev, person),
        const SizedBox(height: 22),
        ..._guardianUpdates(dev, person),
      ],
      if (showNow && showInsights) const SizedBox(height: 22),
      if (showInsights)
        _guardianSection(
          key: ValueKey('guardian-dashboard-insights-${person?.id ?? 'empty'}'),
          label: 'INSIGHTS',
          children: _guardianInsights(dev, person),
        ),
    ];
  }

  List<Widget> _guardianToday(
    GuardianDashboardResolution resolution,
    List<Widget> attention,
    ZyraDevScenario? dev,
    WaliLinkedPerson? person,
  ) {
    final truthFailed = _loadFailed || _reviewLoadFailed;
    final hasCompleteTruth = _hasJourneyTruth && _hasReviewTruth;
    if (resolution.linkedSeekerCount == 0) {
      return [
        if (truthFailed && hasCompleteTruth)
          _ErrorBanner(
            onRetry: _retry,
            message:
                "Couldn't refresh Guardian priorities — showing last-known Dashboard state.",
          ),
        ..._emptyGuardianToday(resolution),
      ];
    }
    if (truthFailed && !hasCompleteTruth) {
      return [
        _ErrorBanner(
          onRetry: _retry,
          message: "Couldn't refresh Guardian priorities.",
        ),
        _guardianSection(
          key: const ValueKey('guardian-dashboard-right-now'),
          label: 'RIGHT NOW',
          children: const [
            _GuardianStatusCard(
              key: ValueKey('guardian-dashboard-journey-unavailable'),
              icon: Icons.cloud_off_outlined,
              eyebrow: 'PRIORITIES UNAVAILABLE',
              title: 'Your Guardian priorities could not be refreshed',
              detail: 'Try again before relying on this summary.',
            ),
          ],
        ),
        if (person == null) ...[
          const SizedBox(height: 22),
          _familySnapshot(resolution, journeyStatusAvailable: false),
        ],
      ];
    }
    return [
      if (truthFailed)
        _ErrorBanner(
          onRetry: _retry,
          message:
              "Couldn't refresh Guardian priorities — showing last-known Dashboard state.",
        )
      else if (_dashboardLabActive &&
          dev?.dashboardGuardianTodayState ==
              ZyraGuardianDashboardTodayState.partialFailure)
        _ErrorBanner(onRetry: _retry),
      _guardianSection(
        key: const ValueKey('guardian-dashboard-right-now'),
        label: 'RIGHT NOW',
        children: attention.isEmpty
            ? const [
                _GuardianStatusCard(
                  icon: Icons.check_circle_outline_rounded,
                  eyebrow: 'ALL SETTLED',
                  title: 'Nothing needs you right now',
                  detail: 'Your current Guardian responsibilities are clear.',
                ),
              ]
            : [attention.first],
      ),
      if (person == null) ...[
        const SizedBox(height: 22),
        _familySnapshot(resolution),
      ],
    ];
  }

  List<Widget> _emptyGuardianToday(GuardianDashboardResolution resolution) => [
    _guardianSection(
      key: const ValueKey('guardian-dashboard-right-now'),
      label: 'RIGHT NOW',
      children: const [
        _GuardianStatusCard(
          icon: Icons.check_circle_outline_rounded,
          eyebrow: 'ALL SETTLED',
          title: 'Everything is settled right now',
          detail: 'There are no linked Seeker responsibilities to review.',
        ),
      ],
    ),
    const SizedBox(height: 22),
    _familySnapshot(resolution),
  ];

  List<Widget> _guardianUpdates(
    ZyraDevScenario? dev,
    WaliLinkedPerson? person,
  ) {
    final previewRows = _dashboardLabActive
        ? _guardianDevUpdateRows(dev!.dashboardUpdatesState, person?.firstName)
        : null;
    final visibleUpdates = person == null
        ? _updates
        : _updates.where((update) {
            if (update.relatedMatchId == null) return true;
            return _journeys.any(
              (journey) =>
                  journey.matchId == update.relatedMatchId &&
                  journey.linkedSeekerId == person.id,
            );
          });
    final capturedRevision = _loadRevision;
    final capturedIds = Set<String>.unmodifiable([
      for (final update in visibleUpdates)
        ?ZyraNotificationService.dashboardNotificationId(
          'update:${update.classKey}:${update.sourceId}',
          update.isUnread,
        ),
    ]);
    final rows =
        previewRows ??
        [
          for (final update in visibleUpdates)
            _updateRow(
              update,
              personId: person?.id,
              capturedRevision: capturedRevision,
            ),
        ];
    final loading = !_dashboardLabActive && _updatesLoading;
    final failed = !_dashboardLabActive && _updatesFailed;
    return [
      if ((failed && rows.isNotEmpty) ||
          (_dashboardLabActive &&
              dev?.dashboardGuardianTodayState ==
                  ZyraGuardianDashboardTodayState.partialFailure))
        _ErrorBanner(onRetry: _retry, lastKnown: rows.isNotEmpty),
      _guardianSection(
        key: const ValueKey('guardian-dashboard-updates'),
        label: 'UPDATES',
        action:
            !_dashboardLabActive &&
                capturedIds.isNotEmpty &&
                widget.onNotificationsChanged != null
            ? TextButton(
                key: const ValueKey('guardian-dashboard-mark-all-read'),
                onPressed: () => _acknowledgeShown(
                  capturedIds,
                  person?.id,
                  capturedRevision,
                ),
                child: const Text('Mark all read'),
              )
            : null,
        children: loading && rows.isEmpty
            ? const [
                _GuardianStatusCard(
                  key: ValueKey('guardian-updates-loading'),
                  icon: Icons.sync_rounded,
                  eyebrow: 'UPDATES',
                  title: 'Checking for Guardian updates',
                ),
              ]
            : failed && rows.isEmpty
            ? [
                _GuardianStatusCard(
                  key: const ValueKey('guardian-updates-unavailable'),
                  icon: Icons.sync_problem_outlined,
                  eyebrow: 'UPDATES UNAVAILABLE',
                  title: 'Guardian updates could not be refreshed',
                  detail: 'Try again before relying on this list.',
                  actionLabel: 'Retry',
                  onTap: _retry,
                ),
              ]
            : rows.isEmpty
            ? const [
                _GuardianStatusCard(
                  key: ValueKey('guardian-updates-empty'),
                  icon: Icons.notifications_none_rounded,
                  eyebrow: 'ALL CAUGHT UP',
                  title: 'No Guardian updates yet',
                  detail:
                      'Meaningful Journey and Family Review movement will appear here.',
                ),
              ]
            : rows,
      ),
    ];
  }

  List<Widget> _guardianDevUpdateRows(
    ZyraDashboardUpdatesState state,
    String? selectedName,
  ) {
    if (state == ZyraDashboardUpdatesState.none ||
        state == ZyraDashboardUpdatesState.allRead) {
      return const [];
    }
    final actionable = state == ZyraDashboardUpdatesState.oneActionable;
    final count = switch (state) {
      ZyraDashboardUpdatesState.several || ZyraDashboardUpdatesState.mixed => 3,
      _ => 1,
    };
    final person = selectedName?.trim().isNotEmpty == true
        ? selectedName!.trim()
        : 'Your Seeker';
    final entries = [
      (person, 'Journey moved forward', 'Today'),
      (person, 'Family Review completed', 'Yesterday'),
      (person, 'Guardian step completed', '2d ago'),
    ];
    return [
      for (var index = 0; index < count; index++)
        _RecentRow(
          key: ValueKey('guardian-dev-update-$index'),
          title: entries[index].$1,
          label: actionable && index == 0
              ? 'Family Review is ready'
              : entries[index].$2,
          when: entries[index].$3,
          // A synthetic update has no authorised Journey destination.
          // Keep it a fact, not a button that ripples without acting.
          onTap: null,
        ),
    ];
  }

  List<Widget> _guardianInsights(
    ZyraDevScenario? dev,
    WaliLinkedPerson? person,
  ) {
    final insightOwner = person == null
        ? 'GUARDIAN INSIGHTS'
        : '${person.firstName.toUpperCase()} · INSIGHTS';
    final entitled = _dashboardLabActive
        ? dev?.dashboardGuardianPremium == true
        : widget.hasGuardianPlus;
    if (!entitled) {
      return [
        _GuardianStatusCard(
          key: const ValueKey('guardian-insights-locked'),
          icon: Icons.lock_rounded,
          eyebrow: insightOwner,
          title:
              'Guardian Insights are part of ${ZyraMembershipCatalog.guardianOneTitle}',
          detail:
              'Upgrade to unlock deeper family-process and Guardian-responsibility insights. Your existing responsibilities remain available.',
          actionLabel: 'View ${ZyraMembershipCatalog.guardianOneTitle}',
          actionKey: const ValueKey('guardian-insights-upgrade'),
          premiumBoundary: true,
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const UpgradeScreen(
                telemetrySurface: ZyraTelemetrySurface.guardian,
              ),
            ),
          ),
        ),
      ];
    }
    if (!_dashboardLabActive ||
        dev?.dashboardGuardianInsightsState ==
            ZyraGuardianDashboardInsightsState.insufficient) {
      return [
        _GuardianStatusCard(
          key: const ValueKey('guardian-insights-empty'),
          icon: Icons.insights_outlined,
          eyebrow: insightOwner,
          title: 'No Guardian insights available yet',
          detail:
              'ZYRA will only show a Guardian insight when real, governed family-process evidence supports it.',
        ),
      ];
    }
    final (title, detail) = switch (dev!.dashboardGuardianInsightsState) {
      ZyraGuardianDashboardInsightsState.familyProcess => (
        'A family handoff may need clearer timing',
        'A process insight about coordination only — never a private Seeker judgement.',
      ),
      ZyraGuardianDashboardInsightsState.multiSeeker => (
        'One family responsibility may need attention sooner',
        'The overview prioritises permitted responsibilities across linked Seekers.',
      ),
      ZyraGuardianDashboardInsightsState.journeyPreparation => (
        'A Journey is approaching a Guardian step',
        'Preparing early can make the next family handoff feel calmer.',
      ),
      ZyraGuardianDashboardInsightsState.guardianNetwork => (
        'Your Guardian Network has an open coordination step',
        'Open Network to review roles and current family connection status.',
      ),
      ZyraGuardianDashboardInsightsState.premium => (
        'A deeper family-process view is ready',
        'This preview adds family-process context without exposing private Seeker behaviour.',
      ),
      ZyraGuardianDashboardInsightsState.insufficient => throw StateError(''),
    };
    return [
      _GuardianStatusCard(
        key: const ValueKey('guardian-dev-insight'),
        icon: Icons.insights_outlined,
        eyebrow: 'DEV PREVIEW · $insightOwner',
        title: title,
        detail: detail,
      ),
    ];
  }

  Widget _guardianSection({
    required Key key,
    required String label,
    required List<Widget> children,
    Widget? action,
  }) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
              ),
            ),
            ?action,
          ],
        ),
      ),
      ...children,
    ],
  );

  Widget _familySnapshot(
    GuardianDashboardResolution resolution, {
    bool journeyStatusAvailable = true,
  }) {
    final linked = resolution.linkedSeekerCount;
    final needsYou = resolution.needsYouCount;
    final linkedLabel = '$linked linked ${linked == 1 ? 'Seeker' : 'Seekers'}';
    final needsLabel = !journeyStatusAvailable
        ? 'Journey status unavailable'
        : needsYou == 0
        ? 'Nothing needs you'
        : '$needsYou ${needsYou == 1 ? 'needs' : 'need'} you';
    return _guardianSection(
      key: const ValueKey('guardian-dashboard-family-orientation'),
      label: 'FAMILY SNAPSHOT',
      children: [
        _GuardianStatusCard(
          key: const ValueKey('guardian-dashboard-family-snapshot'),
          icon: Icons.people_outline_rounded,
          eyebrow: 'YOUR FAMILY',
          title: '$linkedLabel · $needsLabel',
          detail:
              'Open Seekers for relationships, roles and authorised context.',
          actionLabel: 'View Seekers',
          actionKey: const ValueKey('guardian-dashboard-view-seekers'),
          onTap: widget.onOpenSeekers,
        ),
      ],
    );
  }

  Widget _updateRow(
    ZyraDashboardUpdate update, {
    required String? personId,
    required int capturedRevision,
  }) {
    final mainSeekerIds = {
      for (final person in _wards)
        if (person.isMain) person.id,
    };
    WaliJourneyView? journey;
    for (final candidate in _journeys) {
      if (candidate.matchId == update.relatedMatchId &&
          mainSeekerIds.contains(candidate.linkedSeekerId)) {
        journey = candidate;
        break;
      }
    }
    final signal = update.toDashboardSignal(
      personContext: journey?.linkedSeekerName,
    );
    final navigationJourney = journey;
    final VoidCallback? onTap = switch (signal.target) {
      ZyraDashboardTarget.notifications => null,
      ZyraDashboardTarget.connectionsJourneys when navigationJourney != null =>
        () => _openJourney(navigationJourney),
      _ => null,
    };
    final notificationId = ZyraNotificationService.dashboardNotificationId(
      signal.id,
      signal.isUnread,
    );
    return _RecentRow(
      key: ValueKey('guardian-update-${signal.id}'),
      title: signal.title,
      label: signal.detail ?? '',
      when: _ago(update.occurredAt),
      isUnread: signal.isUnread,
      onTap: notificationId == null && onTap == null
          ? null
          : () {
              if (!_isCurrentUpdatePerson(personId) ||
                  capturedRevision != _loadRevision) {
                return;
              }
              if (notificationId != null) {
                unawaited(
                  _acknowledgeShown(
                    {notificationId},
                    personId,
                    capturedRevision,
                  ),
                );
              }
              // Re-check role and object membership before reusing the captured
              // Journey destination; a former Main row is not a fresh grant.
              if (onTap != null &&
                  navigationJourney != null &&
                  _journeys.contains(navigationJourney) &&
                  _wards.any(
                    (person) =>
                        person.id == navigationJourney.linkedSeekerId &&
                        person.isMain,
                  )) {
                onTap();
              }
            },
    );
  }
}

class _GuardianStatusCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String? detail;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onTap;
  final bool premiumBoundary;

  const _GuardianStatusCard({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    this.detail,
    this.actionLabel,
    this.actionKey,
    this.onTap,
    this.premiumBoundary = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ZyraColors.surfaceBorder, width: 0.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: premiumBoundary
              ? ZyraColors.journeyGold
              : ZyraColors.ink(0.72),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: ZyraText.chapterLabel(color: ZyraColors.ink(0.50)),
              ),
              const SizedBox(height: 4),
              Text(title, style: ZyraText.body(size: 14.2)),
              if (detail?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(detail!, style: ZyraText.subtext(size: 11.7)),
              ],
              if (actionLabel != null && onTap != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  key:
                      actionKey ??
                      const ValueKey('guardian-dashboard-status-action'),
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: premiumBoundary
                        ? ZyraText.button(size: 13, color: ZyraColors.goldText)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// One thing waiting on the Guardian — the accent surface the Family
/// Review badge already used, grown into a card with a verb.
class _AttentionCard extends StatelessWidget {
  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;
  const _AttentionCard({
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ZyraColors.surfaceEmphasisFill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ZyraColors.surfaceEmphasisBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ZyraText.body(size: 13.5, color: Colors.white),
                      ),
                      SizedBox(height: 3),
                      Text(body, style: ZyraText.subtext(size: 11.5)),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  cta,
                  style: ZyraText.body(size: 12.5, color: Colors.white),
                ),
                Icon(
                  Icons.chevron_right,
                  color: ZyraColors.ink(0.54),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet recency row — fact, then when. Taps through to the Journey.
class _RecentRow extends StatelessWidget {
  final String title;
  final String label;
  final String when;
  final bool? isUnread;
  final VoidCallback? onTap;
  const _RecentRow({
    super.key,
    required this.title,
    required this.label,
    required this.when,
    this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            if (isUnread != null) ...[
              Icon(
                Icons.circle,
                key: isUnread == true
                    ? ValueKey('guardian-update-unread-$title')
                    : null,
                size: isUnread == true ? 7 : 5,
                color: isUnread == true
                    ? ZyraColors.actionFill
                    : ZyraColors.foreground.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label.trim().isEmpty ? title : '$title — $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZyraText.subtext(
                  size: 12.5,
                  color: ZyraColors.ink(0.70),
                ),
              ),
            ),
            Text(
              when,
              style: ZyraText.subtext(
                size: 11,
                color: ZyraColors.foreground.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The stale-but-shown state: rows render, the truth about the refresh
/// failing is said out loud. DR-ZYRA-167's rule on this screen.
class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  final bool lastKnown;
  final String? message;
  const _ErrorBanner({
    required this.onRetry,
    this.lastKnown = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZyraColors.surfaceBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 15,
              color: ZyraColors.foreground.withValues(alpha: 0.5),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message ??
                    (lastKnown
                        ? "Couldn't refresh Updates — showing last-known rows."
                        : "Couldn't refresh — showing what was loaded."),
                style: ZyraText.subtext(size: 11.5),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: ZyraText.body(size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
