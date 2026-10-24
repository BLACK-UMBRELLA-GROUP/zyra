// Seeker Dashboard — one resolver, one production renderer.
//
// Developer scenarios use the same Quiet renderer and governed resolution as
// production. Scenario data never becomes account truth.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../dev/zyra_dev_scenario.dart';
import '../../dev/zyra_supportive_dashboard_preview.dart';
import '../../models/zyra_dashboard_lab.dart';
import '../../models/zyra_dashboard_resolution.dart';
import '../../models/journey_match.dart';
import '../../models/zyra_supportive_dashboard.dart';
import '../../services/zyra_dashboard_adapter.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_notification_service.dart';
import '../../services/zyra_profile_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../widgets/zyra_quiet_dashboard.dart';
import '../../widgets/zyra_glass_dialog.dart';
import '../../theme/zyra_text.dart';

typedef ZyraDashboardSnapshotLoader = Future<DashboardSnapshot> Function();

class SeekerDashboardScreen extends StatefulWidget {
  final int unreadCount;
  final bool isActive;
  final VoidCallback onOpenConnections;
  final VoidCallback? onOpenConnectionsActivity;
  final VoidCallback onOpenGuardian;
  final VoidCallback? onNotificationsChanged;
  final VoidCallback? onOpenDiscovery;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onReviewPreferences;
  final VoidCallback? onResumeOnboarding;
  final ZyraOnboardingProgress? initialOnboardingProgress;

  /// Only the protected first-use rehearsal may supply local incomplete
  /// onboarding truth. Ordinary members continue to use the server adapter.
  final bool onboardingEntryPreview;

  /// Test seam for measured production-state rendering. Normal app code uses
  /// [ZyraSeekerDashboardAdapter.load].
  final ZyraDashboardSnapshotLoader? loadDashboard;

  const SeekerDashboardScreen({
    super.key,
    required this.unreadCount,
    this.isActive = true,
    required this.onOpenConnections,
    this.onOpenConnectionsActivity,
    required this.onOpenGuardian,
    this.onNotificationsChanged,
    this.onOpenDiscovery,
    this.onOpenProfile,
    this.onReviewPreferences,
    this.onResumeOnboarding,
    this.initialOnboardingProgress,
    this.onboardingEntryPreview = false,
    this.loadDashboard,
  });

  @override
  State<SeekerDashboardScreen> createState() => _SeekerDashboardScreenState();
}

class _SeekerDashboardScreenState extends State<SeekerDashboardScreen> {
  static const _resolver = DashboardResolver();
  static const _adapter = ZyraSeekerDashboardAdapter();

  late DashboardResolution _resolution;
  var _loadGeneration = 0;
  late bool _wasUsingLab;
  late final ZyraNotificationOwnerLease? _notificationOwner;
  final Set<String> _pendingAcknowledgements = {};

  @override
  void initState() {
    super.initState();
    _notificationOwner = ZyraNotificationOwnerLease.capture();
    _resolution = _resolver.resolve(
      _localOnboardingPreviewAllowed
          ? _localOnboardingSnapshot()
          : _loadingSnapshot(),
    );
    _wasUsingLab = _usingLab;
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      ZyraDevScenario.instance.addListener(_scenarioChanged);
    }
    SupportiveDashboardPreview.instance.addListener(_scenarioChanged);
    ZyraDeveloperAccess.authorizationChanges.addListener(_scenarioChanged);
    ZyraWaliLinkService.invitationRevision.addListener(_sourceChanged);
    ZyraWaliLinkService.linkRevision.addListener(_sourceChanged);
    if (!_wasUsingLab) _reload();
  }

  @override
  void didUpdateWidget(covariant SeekerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unreadCount != widget.unreadCount ||
        oldWidget.initialOnboardingProgress !=
            widget.initialOnboardingProgress ||
        oldWidget.onboardingEntryPreview != widget.onboardingEntryPreview ||
        oldWidget.loadDashboard != widget.loadDashboard) {
      _reload();
    }
  }

  @override
  void dispose() {
    _notificationOwner?.dispose();
    ZyraDevScenario.instance.removeListener(_scenarioChanged);
    SupportiveDashboardPreview.instance.removeListener(_scenarioChanged);
    ZyraDeveloperAccess.authorizationChanges.removeListener(_scenarioChanged);
    ZyraWaliLinkService.invitationRevision.removeListener(_sourceChanged);
    ZyraWaliLinkService.linkRevision.removeListener(_sourceChanged);
    super.dispose();
  }

  void _sourceChanged() => _reload();

  bool get _requestedLocalOnboardingPreview =>
      widget.onboardingEntryPreview &&
      widget.initialOnboardingProgress?.complete == false;

  bool get _localOnboardingPreviewAllowed =>
      _requestedLocalOnboardingPreview &&
      ZyraInternalPreviewClient.isActive &&
      ZyraDeveloperAccess.canUseDeveloperTools;

  bool get _usingLab {
    if (_requestedLocalOnboardingPreview) return false;
    final preview = SupportiveDashboardPreview.instance;
    return SupportiveDashboardPreview.allowed &&
        preview.enabled &&
        !preview.useCurrentSources;
  }

  void _scenarioChanged() {
    if (_requestedLocalOnboardingPreview) {
      // Rebuild the same synthetic incomplete state if developer authority
      // returns; never resume by loading a real member snapshot.
      if (_localOnboardingPreviewAllowed) {
        _reload();
      } else {
        ++_loadGeneration;
      }
      return;
    }
    final usingLab = _usingLab;
    if (!_wasUsingLab && usingLab) ++_loadGeneration;
    if (_wasUsingLab && !usingLab) _reload();
    _wasUsingLab = usingLab;
  }

  Future<void> _reload() async {
    if (_requestedLocalOnboardingPreview) {
      // A revoked or unlatched rehearsal stays denied; it may not fall
      // through to real account reads or reuse a previous member snapshot.
      if (!_localOnboardingPreviewAllowed) return;
      ++_loadGeneration;
      setState(
        () => _resolution = _resolver.resolve(_localOnboardingSnapshot()),
      );
      return;
    }
    // Local candidates never initiate account reads or notification writes.
    if (_usingLab) return;
    final generation = ++_loadGeneration;
    try {
      final snapshot = await (widget.loadDashboard ?? _adapter.load)();
      if (!mounted || generation != _loadGeneration) return;
      final next = _resolver.resolve(snapshot).retainUpdatesFrom(_resolution);
      setState(() => _resolution = next);
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      final next = _resolver
          .resolve(_failedSnapshot())
          .retainUpdatesFrom(_resolution);
      setState(() => _resolution = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = AppState.instance.name?.trim();
    final scenario = ZyraDevScenario.instance;
    final preview = SupportiveDashboardPreview.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        scenario,
        preview,
        ZyraDeveloperAccess.authorizationChanges,
      ]),
      builder: (context, _) {
        if (_requestedLocalOnboardingPreview) {
          if (!_localOnboardingPreviewAllowed) {
            return const SizedBox.expand(
              key: ValueKey('seeker_onboarding_preview_denied'),
            );
          }
          return _production(firstName);
        }
        if (SupportiveDashboardPreview.allowed && preview.enabled) {
          final fixtureMode = !preview.useCurrentSources;
          final fixture = fixtureMode ? preview.fixture : null;
          return ZyraQuietDashboard(
            key: ValueKey(
              'supportive-${fixtureMode ? preview.scenario.name : 'sources'}-${preview.action.name}-${preview.status.name}-${preview.change.name}-${preview.editorial.name}-${preview.insight.name}-${preview.reflection.name}',
            ),
            resolution: fixture?.resolution ?? _resolution,
            fixtureCards: fixture?.cards ?? const [],
            fixtureMode: fixtureMode,
            comparisonClock: fixtureMode
                ? SupportiveDashboardFixtures.clock
                : null,
            firstName: firstName,
            selectedTabIndex: preview.tabIndex,
            onTabChanged: preview.selectTab,
            onRetry: fixtureMode ? null : _reload,
            onNavigate: (card) {
              // Capture the mode. A sample callback can never become live
              // after changing tabs, scenarios or accounts.
              if (!SupportiveDashboardPreview.allowed) return;
              if (fixtureMode) {
                _showPreviewDestination(card);
              } else {
                _navigate(card.target);
              }
            },
          );
        }
        return _production(
          firstName,
          blankUntilDeveloperSelection:
              SupportiveDashboardPreview.allowed && !preview.enabled,
        );
      },
    );
  }

  void _showPreviewDestination(SupportiveCard card) {
    final owner =
        card.ownerLabel ??
        switch (card.target) {
          ZyraDashboardTarget.guardian => 'Guardian',
          ZyraDashboardTarget.connectionsJourneys => 'Connections · Journey',
          ZyraDashboardTarget.connectionsActivity => 'Connections · Activity',
          ZyraDashboardTarget.onboarding => 'Onboarding',
          _ =>
            card.actionLabel == 'View membership'
                ? 'Membership'
                : 'Article / guide',
        };
    showZyraGlassDialog<void>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: ZyraDeveloperAccess.authorizationChanges,
        builder: (context, _) {
          if (!SupportiveDashboardPreview.allowed) {
            return const Text('Preview closed');
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destination preview', style: ZyraText.chapterLabel()),
                const SizedBox(height: 12),
                Text(card.title, style: ZyraText.heading(size: 20)),
                if (card.detail != null) ...[
                  const SizedBox(height: 12),
                  Text(card.detail!, style: ZyraText.body(size: 14)),
                ],
                const SizedBox(height: 16),
                Text('Owner page: $owner', style: ZyraText.body(size: 14)),
                const SizedBox(height: 8),
                Text(
                  'This is a local design example. No request, payment, '
                  'Journey action or private note is sent or saved.',
                  style: ZyraText.subtext(size: 12),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Back to My ZYRA'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool get _canAcknowledge =>
      mounted &&
      widget.isActive &&
      !_usingLab &&
      !_requestedLocalOnboardingPreview &&
      _notificationOwner?.isCurrent == true &&
      ModalRoute.of(context)?.isCurrent == true;

  VoidCallback? _notificationAction() {
    final resolution = _resolution;
    final capturedIds = Set<String>.unmodifiable([
      for (final item in resolution.recently)
        ?ZyraNotificationService.dashboardNotificationId(
          item.signal.id,
          item.signal.isUnread,
        ),
    ]);
    if (capturedIds.isEmpty || resolution.updatesAreLastKnown) return null;
    return () => _acknowledgeShown(capturedIds, resolution);
  }

  ValueChanged<SupportiveCard> _notificationViewedAction() {
    final resolution = _resolution;
    return (card) {
      final id = ZyraNotificationService.dashboardNotificationId(
        card.id,
        card.isUnread,
      );
      if (id == null ||
          resolution.updatesAreLastKnown ||
          !resolution.recently.any((item) => item.signal.id == card.id)) {
        return;
      }
      unawaited(_acknowledgeShown({id}, resolution));
    };
  }

  Future<void> _acknowledgeShown(
    Set<String> ids,
    DashboardResolution capturedResolution,
  ) async {
    if (!_canAcknowledge ||
        ids.isEmpty ||
        !identical(capturedResolution, _resolution)) {
      return;
    }
    final freshIds = ids.difference(_pendingAcknowledgements);
    if (freshIds.isEmpty) return;
    _pendingAcknowledgements.addAll(freshIds);
    final result = await ZyraNotificationService.acknowledgeIds(freshIds);
    _pendingAcknowledgements.removeAll(freshIds);
    // A concurrent confirmed view may have refreshed the resolution. It does
    // not expand this write's IDs; refresh the current owner's truth only.
    if (!_canAcknowledge) return;
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
    await _reload();
  }

  Widget _production(
    String? firstName, {
    bool blankUntilDeveloperSelection = false,
  }) => KeyedSubtree(
    key: const ValueKey('seeker-production-dashboard'),
    child: ZyraQuietDashboard(
      resolution: _resolution,
      firstName: firstName,
      onNavigate: (card) => _navigate(card.target),
      onNotificationViewed: _notificationViewedAction(),
      onRetry: _reload,
      onRefresh: _reload,
      blankUntilDeveloperSelection: blankUntilDeveloperSelection,
      insightsEntitled: AppState.instance.plan == ZyraPlan.one,
      onMarkAllNotificationsRead: _notificationAction(),
      unreadCount: widget.unreadCount,
      selectedTabIndex: ZyraDeveloperAccess.canUseDeveloperTools
          ? ZyraDevScenario.instance.dashboardTab.index
          : null,
      onTabChanged: (index) {
        if (ZyraDeveloperAccess.canUseDeveloperTools) {
          ZyraDevScenario.instance.setDashboardTab(
            ZyraDashboardTab.values[index],
          );
        }
      },
    ),
  );

  void _navigate(ZyraDashboardTarget target) {
    switch (target) {
      case ZyraDashboardTarget.none:
        return;
      case ZyraDashboardTarget.discovery:
        widget.onOpenDiscovery?.call();
      case ZyraDashboardTarget.connectionsJourneys:
        widget.onOpenConnections();
      case ZyraDashboardTarget.connectionsActivity:
        (widget.onOpenConnectionsActivity ?? widget.onOpenConnections)();
      case ZyraDashboardTarget.guardian:
        widget.onOpenGuardian();
      case ZyraDashboardTarget.notifications:
        // My ZYRA is the notification centre. Notification-only update rows
        // stay in Now instead of opening a second screen.
        return;
      case ZyraDashboardTarget.profile:
        widget.onOpenProfile?.call();
      case ZyraDashboardTarget.preferences:
        (widget.onReviewPreferences ?? widget.onOpenProfile)?.call();
      case ZyraDashboardTarget.onboarding:
        widget.onResumeOnboarding?.call();
    }
  }

  DashboardSnapshot _loadingSnapshot() => const DashboardSnapshot(
    role: DashboardRole.seeker,
    onboarding: DashboardSource.loading(),
    journeys: DashboardSource.loading(),
    updates: DashboardSource.loading(),
    guardianInvitations: DashboardSource.loading(),
    insights: DashboardSource.loading(),
    advisories: DashboardSource.loading(),
    stableState: DashboardStableState(
      orientationItems: DashboardSource.loading(),
      family: DashboardSource.loading(),
    ),
  );

  DashboardSnapshot _localOnboardingSnapshot() =>
      ZyraSeekerDashboardAdapter.buildSnapshot(
        onboarding: DashboardSource.available(
          widget.initialOnboardingProgress!,
        ),
        journeys: const DashboardSource.available(<JourneyMatch>[]),
        updates: const DashboardSource.available(<DashboardSignal>[]),
        guardianInvitations: const DashboardSource.available(<PendingInvite>[]),
        linkedPeople: const DashboardSource.available(<WaliLinkedPerson>[]),
      );

  DashboardSnapshot _failedSnapshot() {
    const failure = DashboardFailure(code: 'dashboard_load_failed');
    return const DashboardSnapshot(
      role: DashboardRole.seeker,
      onboarding: DashboardSource.unavailable(failure),
      journeys: DashboardSource.unavailable(failure),
      updates: DashboardSource.unavailable(failure),
      guardianInvitations: DashboardSource.unavailable(failure),
      insights: DashboardSource.unavailable(failure),
      advisories: DashboardSource.unavailable(failure),
      stableState: DashboardStableState(
        orientationItems: DashboardSource.unavailable(failure),
        family: DashboardSource.unavailable(failure),
      ),
    );
  }
}
