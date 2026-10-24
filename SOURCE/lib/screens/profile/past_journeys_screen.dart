import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Supabase;
import '../../dev/zyra_app_gold_preview.dart';

import '../../models/journey_match.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_journey_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_card_metrics.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_segmented_toggle.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../matches/journey_timeline_screen.dart';

typedef PastJourneysLoader =
    Future<List<JourneyMatch>?> Function({required List<String> statuses});

/// The profile-owned archive for Paused and Ended Journey records.
///
/// Connections remains the live working surface. This page is deliberately
/// read-only: an archived row never gains a return action merely because it
/// is visible here. Exact expiry, response-time and Paused-cap rules remain
/// owned by OA-ZYRA-299 rather than being invented in the client.
class PastJourneysScreen extends StatefulWidget {
  final PastJourneysLoader? loader;
  final List<JourneyMatch>? previewPaused;
  final List<JourneyMatch>? previewEnded;

  const PastJourneysScreen({
    super.key,
    this.loader,
    this.previewPaused,
    this.previewEnded,
  });

  @override
  State<PastJourneysScreen> createState() => _PastJourneysScreenState();
}

class _PastJourneysScreenState extends State<PastJourneysScreen> {
  late final PageController _pageController;
  double _position = 0;
  bool _loading = true;
  bool _failed = false;
  List<JourneyMatch> _paused = const [];
  List<JourneyMatch> _ended = const [];
  late final (String?, int) _owner;
  late final (bool, String?) _sdkOwner;
  String? _initialAccessToken;
  StreamSubscription<AuthState>? _authSubscription;
  int _sdkGeneration = 0;
  ModalRoute<dynamic>? _ownerRoute;
  bool _routeWasCurrent = true;
  int _routeRevision = 0;
  bool _revoked = false;
  int _loadRequest = 0;

  bool get _ownerCurrent =>
      mounted &&
      !_revoked &&
      _sdkGeneration == 0 &&
      _sdkOwner == _readSdkOwner() &&
      (!_sdkOwner.$1 || _sdkOwner.$2 == _owner.$1) &&
      !ZyraAccountState.isSigningOut &&
      _owner == (ZyraAccountState.userId, ZyraAccountState.generation);

  (bool, String?) _readSdkOwner() {
    try {
      return (true, ZyraAuth.currentUser?.id);
    } catch (_) {
      return (false, null);
    }
  }

  void _watchSdkOwner() {
    _sdkOwner = _readSdkOwner();
    if (!_sdkOwner.$1) return;
    _initialAccessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    _authSubscription = ZyraAuth.authStateChanges.listen(
      (state) {
        if (!mounted || _revoked) return;
        if (_sdkOwner != _readSdkOwner() ||
            (state.session != null && state.session!.user.id != _sdkOwner.$2) ||
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.passwordRecovery ||
            (state.event == AuthChangeEvent.initialSession &&
                state.session?.accessToken != _initialAccessToken)) {
          ++_sdkGeneration;
          _accountChanged();
        }
      },
      onError: (Object error, StackTrace stack) {
        ++_sdkGeneration;
        _accountChanged();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _owner = (ZyraAccountState.userId, ZyraAccountState.generation);
    _pageController = PageController()..addListener(_followSwipe);
    _watchSdkOwner();
    AppState.instance.addListener(_accountChanged);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownerRoute = ModalRoute.of(context);
    final current = _ownerRoute?.isCurrent ?? true;
    if (_routeWasCurrent && !current) ++_routeRevision;
    _routeWasCurrent = current;
    if (!_ownerCurrent) _accountChanged();
  }

  void _accountChanged() {
    if (!mounted || _revoked || _ownerCurrent) return;
    _revoked = true;
    _authSubscription?.cancel();
    ++_loadRequest;
    _paused = const [];
    _ended = const [];
    _loading = false;
    _failed = false;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
    }
    binding.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = _ownerRoute;
      if (route != null && !route.isFirst && route.navigator != null) {
        route.navigator!.removeRoute(route);
      } else {
        setState(() {});
      }
    });
    binding.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    AppState.instance.removeListener(_accountChanged);
    _revoked = true;
    ++_loadRequest;
    _paused = const [];
    _ended = const [];
    _pageController
      ..removeListener(_followSwipe)
      ..dispose();
    super.dispose();
  }

  void _followSwipe() {
    final page = _pageController.page;
    if (!_ownerCurrent || page == null || page == _position) return;
    setState(() => _position = page);
  }

  void _selectPage(int index) {
    if (!_ownerCurrent) return;
    ZyraSegmentedMotion.animateToPage(_pageController, index);
  }

  Future<void> _load() async {
    if (!_ownerCurrent) return;
    final request = ++_loadRequest;
    bool current() => _ownerCurrent && request == _loadRequest;
    if (widget.previewPaused != null || widget.previewEnded != null) {
      setState(() {
        _paused = widget.previewPaused ?? const [];
        _ended = widget.previewEnded ?? const [];
        _loading = false;
      });
      return;
    }

    final loader = widget.loader ?? ZyraJourneyService.fetchJourneyMatches;
    List<JourneyMatch>? active;
    List<JourneyMatch>? ended;
    try {
      active = await loader(statuses: const ['active']);
      // The two reads must belong to the same captured account. A first
      // response never authorizes dispatching the second for a new owner.
      if (!current()) return;
      ended = await loader(statuses: const ['ended']);
    } catch (_) {
      if (!current()) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    if (!current()) return;
    final loadedActive = active;
    final loadedEnded = ended;
    if (loadedActive == null || loadedEnded == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    setState(() {
      _paused = loadedActive
          .where((journey) => journey.isSuspended)
          .toList(growable: false);
      _ended = loadedEnded;
      _loading = false;
      _failed = false;
    });
  }

  @override
  Widget build(BuildContext context) => !_ownerCurrent
      ? const SizedBox.expand(key: ValueKey('past-journeys-unavailable'))
      : Scaffold(
          body: Container(
            decoration: ZyraAppGoldDecoration(
              gradient: ZyraColors.genderGradient(AppState.instance.gender),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () {
                            if (_ownerCurrent &&
                                (_ownerRoute?.isCurrent ?? false)) {
                              Navigator.of(context).maybePop();
                            }
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: ZyraColors.foregroundSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Past Journeys',
                            style: ZyraText.heading(size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: ZyraSegmentedToggle(
                      key: const ValueKey('past-journeys-toggle'),
                      labels: const ['Paused', 'Ended'],
                      position: _position,
                      onChanged: _selectPage,
                      labelSize: 13,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: PageView(
                        key: const ValueKey('past-journeys-pages'),
                        controller: _pageController,
                        physics: ZyraSegmentedMotion.pagePhysics,
                        onPageChanged: (index) {
                          if (_ownerCurrent) {
                            setState(() => _position = index.toDouble());
                          }
                        },
                        children: [_body(0), _body(1)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

  Widget _body(int index) {
    final routeRevision = _routeRevision;
    if (_loading) return const Center(child: ZyraLoading());
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ZyraEmptyState(
            icon: Icons.refresh_rounded,
            title: "We couldn't load this just now",
            message: 'Check your connection and try again. Nothing changed.',
            ctaLabel: 'Try again',
            onCta: () {
              if (!_ownerCurrent) return;
              setState(() {
                _loading = true;
                _failed = false;
              });
              _load();
            },
          ),
        ),
      );
    }

    final rows = index == 0 ? _paused : _ended;
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ZyraEmptyState(
            icon: index == 0
                ? Icons.pause_circle_outline_rounded
                : Icons.history_rounded,
            title: index == 0
                ? 'No Paused Journeys yet'
                : 'No Ended Journeys yet',
            message: index == 0
                ? 'Journeys placed on hold will appear here until they continue or end.'
                : 'Journeys brought to a close will appear here, with their history kept.',
          ),
        ),
      );
    }

    // Preview/test archives do not initialise Supabase. Keep the archive
    // renderable from local preview rows without touching the auth singleton.
    String? currentUserId;
    if (widget.previewPaused == null && widget.previewEnded == null) {
      try {
        currentUserId = ZyraAuth.currentUser?.id;
      } catch (_) {
        currentUserId = null;
      }
    }
    final requestsForYou = index == 0
        ? rows
              .where(
                (journey) =>
                    journey.pause.isPending &&
                    journey.pause.requestedBy != null &&
                    journey.pause.requestedBy != currentUserId,
              )
              .toList(growable: false)
        : const <JourneyMatch>[];
    final ordinary = requestsForYou.isEmpty
        ? rows
        : rows.where((journey) => !requestsForYou.contains(journey)).toList();

    return ListView(
      key: ValueKey<String>('past-journeys-${index == 0 ? 'paused' : 'ended'}'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 42),
      children: [
        if (requestsForYou.isNotEmpty) ...[
          _PastSectionLabel('REQUESTS FOR YOU'),
          const SizedBox(height: 8),
          ...requestsForYou.map(
            (journey) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PastJourneyCard(
                journey: journey,
                canAct: () => _ownerCurrent && routeRevision == _routeRevision,
                ownerCurrent: () => _ownerCurrent,
              ),
            ),
          ),
          if (ordinary.isNotEmpty) ...[
            const SizedBox(height: 6),
            _PastSectionLabel('YOUR PAUSED JOURNEYS'),
            const SizedBox(height: 8),
          ],
        ],
        ...ordinary.map(
          (journey) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PastJourneyCard(
              journey: journey,
              canAct: () => _ownerCurrent && routeRevision == _routeRevision,
              ownerCurrent: () => _ownerCurrent,
            ),
          ),
        ),
      ],
    );
  }
}

class _PastSectionLabel extends StatelessWidget {
  final String text;
  const _PastSectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: ZyraText.chapterLabel(color: ZyraColors.foregroundMuted),
  );
}

class _PastJourneyCard extends StatelessWidget {
  final JourneyMatch journey;
  final bool Function() canAct;
  final bool Function() ownerCurrent;

  const _PastJourneyCard({
    required this.journey,
    required this.canAct,
    required this.ownerCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final profile = journey.profile;
    final state = journey.status == 'ended'
        ? 'Ended Journey'
        : journey.pausedFor.isEmpty
        ? 'Paused Journey'
        : 'Paused · ${journey.pausedFor}';

    return Material(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
      child: InkWell(
        key: ValueKey('past-journey-card-${journey.matchId}'),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        onTap: () {
          if (!canAct() ||
              (ModalRoute.of(context)?.isCurrent ?? false) != true) {
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              // An ordinary row contains a pair ID, not selected-attempt
              // provenance. Never substitute the pair's current Timeline
              // for the historical Journey the person selected.
              builder: (_) => !journey.isMock
                  ? PastJourneyArchiveUnavailableScreen(
                      firstName: profile.firstName,
                      canAct: ownerCurrent,
                    )
                  : JourneyTimelineScreen(
                      withProfile: profile,
                      isMock: journey.isMock,
                      journeyStage: journey.journeyStage,
                    ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(ZyraCardMetrics.padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
            border: Border.all(color: ZyraColors.surfaceBorder, width: 0.6),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  ZyraCardMetrics.thumbRadius,
                ),
                child: profile.photos.isEmpty
                    ? Container(
                        width: ZyraCardMetrics.thumb,
                        height: ZyraCardMetrics.thumb,
                        color: ZyraColors.iconButtonBg,
                        alignment: Alignment.center,
                        child: Text(
                          profile.firstName.isEmpty
                              ? '?'
                              : profile.firstName[0],
                          style: ZyraText.heading(size: 16),
                        ),
                      )
                    : ZyraProfileImage(
                        profile.photoUrl,
                        width: ZyraCardMetrics.thumb,
                        height: ZyraCardMetrics.thumb,
                      ),
              ),
              const SizedBox(width: ZyraCardMetrics.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.firstName}, ${profile.age}',
                      style: ZyraText.body(
                        size: 14,
                        color: ZyraColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(state, style: ZyraText.subtext(size: 11)),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ZyraColors.foregroundMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Truthful read-only destination until an archive row can identify the
/// exact authorised attempt. This deliberately has no reader, retry or
/// mutation action: an unavailable historical attempt is not a current one.
class PastJourneyArchiveUnavailableScreen extends StatefulWidget {
  const PastJourneyArchiveUnavailableScreen({
    super.key,
    required this.firstName,
    required this.canAct,
  });
  final String firstName;
  final bool Function() canAct;

  @override
  State<PastJourneyArchiveUnavailableScreen> createState() =>
      _PastJourneyArchiveUnavailableScreenState();
}

class _PastJourneyArchiveUnavailableScreenState
    extends State<PastJourneyArchiveUnavailableScreen> {
  late final String _openingFirstName;
  late final bool Function() _openingCanAct;
  ModalRoute<dynamic>? _route;
  StreamSubscription<AuthState>? _subscription;
  bool _revoked = false;
  bool _wasCurrent = true;
  int _revision = 0;
  bool get _current {
    if (!mounted || _revoked) return false;
    try {
      if (_openingCanAct()) return true;
    } catch (_) {
      // A failed caller check is denial, never permission to adopt a later
      // guard or publish this opening person's content.
    }
    _withdraw();
    return false;
  }

  @override
  void initState() {
    super.initState();
    _openingFirstName = widget.firstName;
    _openingCanAct = widget.canAct;
    AppState.instance.addListener(_checkOwner);
    try {
      _subscription = ZyraAuth.authStateChanges.listen(
        (_) => _checkOwner(),
        onError: (Object _, StackTrace _) => _withdraw(),
      );
    } catch (_) {
      // Detached archive previews may not initialise the SDK. Their caller
      // still owns the lifetime and no service is read by this destination.
    }
  }

  void _checkOwner() {
    if (!mounted || _revoked || _current) return;
    _withdraw();
  }

  void _withdraw() {
    if (!mounted || _revoked) return;
    _revoked = true;
    ++_revision;
    final route = _route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (route != null && route.isActive && !route.isFirst) {
        route.navigator?.removeRoute(route);
      } else {
        setState(() {});
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
    if (WidgetsBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final current = _route?.isCurrent ?? true;
    if (_wasCurrent && !current) ++_revision;
    _wasCurrent = current;
    _checkOwner();
  }

  @override
  void didUpdateWidget(
    covariant PastJourneyArchiveUnavailableScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.firstName != _openingFirstName ||
        !identical(widget.canAct, _openingCanAct)) {
      _withdraw();
    }
  }

  @override
  void dispose() {
    _revoked = true;
    _subscription?.cancel();
    AppState.instance.removeListener(_checkOwner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_current) return const SizedBox.shrink();
    final revision = _revision;
    void back() {
      if (_current && revision == _revision && _route?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    }

    return Scaffold(
      key: const ValueKey('past-journey-archive-unavailable'),
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text('Journey history', style: ZyraText.heading(size: 17)),
        leading: BackButton(onPressed: back),
      ),
      body: DecoratedBox(
        decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Text(
                'History with $_openingFirstName',
                style: ZyraText.pageTitle(),
              ),
              const SizedBox(height: 20),
              Text(
                'This Journey’s history is not available in this view yet. '
                'A different or current Journey has not been opened instead.',
                style: ZyraText.body(size: 15),
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                key: const ValueKey('past-journey-archive-back'),
                onPressed: back,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                ),
                child: Text(
                  'Back to Past Journeys',
                  style: ZyraText.button(size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
