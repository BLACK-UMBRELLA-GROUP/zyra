// Guardian home shell — one stable navigation structure for every membership.
// Guardian Basic sees paid destinations in place with a lock; entitlement
// changes access and content, never the shape of the app.
//
// 2026-07-19, DR-ZYRA-089: moved to the floating glassmorphic pill
// nav — WALI ARCHITECTURE always specified "floating glass pill: same
// design as Seeker nav" (this file's own comment previously flagged the
// solid-bar version as a known deviation, "both should move to the
// floating-pill treatment together if that gets confirmed"). Confirmed
// today alongside removing Luxury Dark Purple (the bar's previous
// colour) from active use app-wide — DR-ZYRA-090, zyra_colors.dart.
//
// 2026-07-19, DR-ZYRA-091: nav bar rebuilt onto the shared
// FloatingNavBar widget so this stays visually identical to Seeker's
// HomeShell — see widgets/floating_nav_bar.dart.
//
// 2026-08-13 (Founder) — THREE CHANGES, all parity with the Seeker shell:
//
//  1. THE DEV WRENCH IS GONE. It was the Guardian's only route to the
//     account switcher when it was added; the dev side toggle
//     (DevScenarioPanel) replaced that, and the Seeker shell dropped its
//     own wrench for the same reason on 2026-07-26. Keeping it here left
//     the Guardian with two doors to one room, one of which was a
//     debug-only icon sitting in the corner of a real screen.
//
//  2. THE BELL BECOMES A TAB, exactly as it did on the Seeker side
//     (DR-ZYRA-149). The floating overlay is gone; Notifications sits in
//     the nav bar, left of Profile, carrying the unread badge the Bell
//     used to show. The shell owns the 20s unread poll now.
//
//     This DOES supersede the 2026-08-13 note in home_shell.dart that
//     "the Wali side keeps its Bell — the Guardian shell was not part of
//     this ruling". It is part of it now, by the Founder's instruction to
//     bring Guardian into line with Seeker.
//
//  3. SEEKERS AND NETWORK SWAP PLACES. Network moves left of Seekers.
//
// 2026-07-26 (OA-ZYRA-124 per-account-type UX review, #27): two parity
// gaps with the Seeker HomeShell fixed. (1) There was no Dev Access
// shortcut here at all — a Wali test account had no way back to the
// account switcher without an app restart, unlike Seeker's HomeShell.
// (2) WaliProfileScreen's plan badge/"Manage Subscription" row had
// nowhere real to go — the real purchase surface is the Network tab's
// "Get Guardian+" button (wali_network_screen.dart), not the Seeker-
// only UpgradeScreen (which sells ZYRA Basic/One via AppState.plan, a
// different entitlement entirely) — so a callback is threaded through,
// same pattern as HomeShell's onNavigateToConnections passed into
// BrowseScreen.

// 2026-08-13, DR-ZYRA-152 — THE GUARDIAN DEV TOGGLE. The Seeker shell has
// had a pull-out scenario panel since 2026-08-01; this side had none, so
// every Guardian state (a ward, their Journey, a Family Review waiting on
// you) needed two accounts and a live invite to reach. WaliDevScenarioPanel
// mounts as the LAST child of this Stack — above the nav bar, so its tab
// stays tappable — and the shell pushes the current tab into the shared
// scenario, exactly as HomeShell does with setCurrentPage, so the panel can
// draw only the controls for the page on screen.

import 'dart:async';

import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../dev/zyra_dev_surface_coordinator.dart';
import '../../services/zyra_notification_service.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../services/zyra_promotion_engine.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/zyra_shell_navigation.dart';
import '../../widgets/zyra_keyboard_dismiss_scope.dart';
import '../../widgets/zyra_bottom_promotion.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../services/zyra_wali_link_service.dart';
import 'wali_dashboard_screen.dart';
import 'wali_network_screen.dart';
import 'wali_profile_screen.dart';
import 'wali_seekers_screen.dart';

@visibleForTesting
List<WaliPage> waliPagesForMembership({required bool hasGuardianOne}) => [
  WaliPage.dashboard,
  WaliPage.network,
  WaliPage.seekers,
  WaliPage.profile,
];

class WaliHomeShell extends StatefulWidget {
  /// A protected, local-only landing after rehearsing Guardian onboarding.
  /// This does not represent a created or verified member account.
  final bool initialOnboardingPreview;
  final Future<int?> Function()? loadUnreadCount;

  const WaliHomeShell({
    super.key,
    this.initialOnboardingPreview = false,
    this.loadUnreadCount,
  });

  @override
  State<WaliHomeShell> createState() => _WaliHomeShellState();
}

class _WaliHomeShellState extends State<WaliHomeShell> {
  WaliPage _page = WaliPage.dashboard;
  String? _requestedSeekerId;
  int _seekerSelectionRequest = 0;

  /// The Bell's unread count, relocated (2026-08-13) — the same 20s poll
  /// the Bell widget ran, now feeding the Dashboard tab's badge. Same
  /// mechanism as the Seeker shell, deliberately: two shells polling two
  /// different ways would drift.
  int _unread = 0;
  int _unreadRevision = 0;
  late final String? _ownerUserId;
  late final int _ownerGeneration;
  late final ZyraNotificationOwnerLease? _notificationOwner;
  Timer? _unreadPoll;
  bool _hasGuardianPlus = false;

  bool get _currentAccount =>
      ZyraAccountState.userId == _ownerUserId &&
      ZyraAccountState.generation == _ownerGeneration;

  bool get _previewAllowed =>
      widget.initialOnboardingPreview &&
      ZyraDeveloperAccess.canUseDeveloperTools &&
      ZyraDeveloperAccess.isMainAppPreview &&
      ZyraInternalPreviewClient.isActive;

  void _onPreviewAuthorityChanged() {
    if (mounted) setState(() {});
  }

  bool get _effectiveHasGuardianOne {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return _hasGuardianPlus;
    return switch (ZyraPromotionEngine.instance.developerGuardianNetworkState) {
      ZyraDeveloperGuardianNetworkState.unlinkedBasic ||
      ZyraDeveloperGuardianNetworkState.linkedBasic => false,
      _ => true,
    };
  }

  @override
  void initState() {
    super.initState();
    _ownerUserId = ZyraAccountState.userId;
    _ownerGeneration = ZyraAccountState.generation;
    _notificationOwner = widget.initialOnboardingPreview
        ? null
        : ZyraNotificationOwnerLease.capture();
    if (widget.initialOnboardingPreview) {
      // The raw mode, not the current capability, owns this deny-only branch.
      // Losing authority must not fall through to ordinary member reads.
      ZyraDeveloperAccess.authorizationChanges.addListener(
        _onPreviewAuthorityChanged,
      );
      ZyraInternalPreviewClient.changes.addListener(_onPreviewAuthorityChanged);
    } else {
      ZyraNotificationService.confirmedAcknowledgements.addListener(
        _onConfirmedAcknowledgement,
      );
      ZyraProductTelemetry.instance.record(
        feature: ZyraTelemetryFeature.myZyra,
        name: ZyraTelemetryEventName.opened,
        action: ZyraTelemetryAction.pageView,
        surface: ZyraTelemetrySurface.guardian,
      );
      _refreshUnread();
      ZyraEntitlementService.hasWaliOne().then((has) {
        if (!mounted || !_currentAccount) return;
        setState(() {
          _hasGuardianPlus = has;
        });
      });
      _unreadPoll = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _refreshUnread(),
      );
    }
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      // The panel needs to know where we ARE before the first tab change,
      // or its first open shows the wrong card.
      ZyraDevScenario.instance.setCurrentWaliPage(_page);
      ZyraDevScenario.instance.addListener(_onScenarioChange);
      ZyraPromotionEngine.instance.addListener(_onMembershipPreviewChange);
      ZyraDevSurfaceCoordinator.instance.attachGuardian(this, _openDevPage);
    }
  }

  @override
  void dispose() {
    ZyraNotificationService.confirmedAcknowledgements.removeListener(
      _onConfirmedAcknowledgement,
    );
    _notificationOwner?.dispose();
    _unreadPoll?.cancel();
    ++_unreadRevision;
    ZyraDeveloperAccess.authorizationChanges.removeListener(
      _onPreviewAuthorityChanged,
    );
    ZyraInternalPreviewClient.changes.removeListener(
      _onPreviewAuthorityChanged,
    );
    // Capability can disappear before disposal when a persona signs out.
    // removeListener is a no-op when no matching listener was registered, so
    // removal must be unconditional to avoid a dead shell retaining callbacks.
    ZyraDevScenario.instance.removeListener(_onScenarioChange);
    ZyraPromotionEngine.instance.removeListener(_onMembershipPreviewChange);
    ZyraDevSurfaceCoordinator.instance.detachGuardian(this);
    super.dispose();
  }

  void _openDevPage(WaliPage page) {
    if (!mounted) return;
    // The retired Notifications preview resolves to its live owner: Dashboard.
    final destination = page == WaliPage.notifications
        ? WaliPage.dashboard
        : page;
    _goToPage(destination);
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }

  /// Repaints the badge when the panel's staged unread count changes.
  /// Debug/profile only — never registered in a release build.
  void _onScenarioChange() {
    if (mounted) setState(() {});
  }

  void _onMembershipPreviewChange() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refreshUnread() async {
    if (widget.initialOnboardingPreview || !_currentAccount) return;
    // The explicit injected loader is read-only fixture data. Production
    // polling must retain the same SDK and preview lifetime as this shell.
    if ((_notificationOwner != null && !_notificationOwner.isCurrent) ||
        (widget.loadUnreadCount == null && _notificationOwner == null)) {
      return;
    }
    final revision = ++_unreadRevision;
    final count =
        await (widget.loadUnreadCount ??
            ZyraNotificationService.fetchUnreadCount)();
    // Null = the fetch failed (BUG-05, OA-ZYRA-225, 2026-08-15) — hold
    // the last known badge, same rule as the Seeker shell.
    if (mounted &&
        revision == _unreadRevision &&
        _currentAccount &&
        count != null &&
        count != _unread) {
      setState(() => _unread = count);
    }
  }

  void _onConfirmedAcknowledgement() {
    if (!mounted ||
        widget.initialOnboardingPreview ||
        !_currentAccount ||
        _notificationOwner?.isCurrent != true) {
      return;
    }
    unawaited(_refreshUnread());
  }

  /// What the badge shows.
  ///
  /// The staged count WINS while it is above zero, and only the badge is
  /// staged — the list behind it stays real rows. A count that disagreed
  /// with the list it labels would be worse than no control, so the panel
  /// says as much on the Notifications card.
  int get _badgeCount {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return _unread;
    final staged = ZyraDevScenario.instance.waliUnread;
    return staged > 0 ? staged : _unread;
  }

  void _goToPage(WaliPage page, {bool preserveSeekerRequest = false}) {
    dismissZyraKeyboardAfterNavigation();
    final changed = page != _page;
    setState(() {
      _page = page;
      if (!preserveSeekerRequest && _requestedSeekerId != null) {
        _requestedSeekerId = null;
        _seekerSelectionRequest++;
      }
    });
    if (changed && !widget.initialOnboardingPreview) {
      ZyraProductTelemetry.instance.record(
        feature: switch (page) {
          WaliPage.dashboard ||
          WaliPage.notifications => ZyraTelemetryFeature.myZyra,
          WaliPage.network => ZyraTelemetryFeature.connections,
          WaliPage.seekers => ZyraTelemetryFeature.guardian,
          WaliPage.profile => ZyraTelemetryFeature.profile,
        },
        name: ZyraTelemetryEventName.opened,
        action: ZyraTelemetryAction.pageView,
        surface: ZyraTelemetrySurface.guardian,
      );
    }
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      ZyraDevScenario.instance.setCurrentWaliPage(page);
    }
    // Re-read on every tab change rather than waiting out the poll.
    _refreshUnread();
  }

  void _openSeeker(String seekerId) {
    // IDs, not names or Dashboard indexes: the roster groups people by role
    // and attention, and this tab stays mounted between visits.
    setState(() {
      _requestedSeekerId = seekerId;
      _seekerSelectionRequest++;
    });
    _goToPage(WaliPage.seekers, preserveSeekerRequest: true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialOnboardingPreview && !_previewAllowed) {
      return Scaffold(
        key: const ValueKey('guardian_onboarding_preview_denied'),
        body: DecoratedBox(
          decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
          child: Center(
            child: Text(
              'Preview unavailable. Return to Developer Access.',
              style: ZyraText.subtext(size: 15),
            ),
          ),
        ),
      );
    }
    final hasGuardianOne = _effectiveHasGuardianOne;
    final visiblePages = waliPagesForMembership(hasGuardianOne: hasGuardianOne);
    final currentIndex = visiblePages
        .indexOf(_page)
        .clamp(0, visiblePages.length - 1);
    final pages = [
      WaliDashboardScreen(
        isActive: _page == WaliPage.dashboard,
        initialOnboardingPreview: widget.initialOnboardingPreview,
        hasGuardianPlus: hasGuardianOne,
        notificationCount: _badgeCount,
        onOpenNetwork: () => _goToPage(WaliPage.network),
        onOpenSeekers: () => _goToPage(WaliPage.seekers),
        onOpenSeeker: _openSeeker,
        onNotificationsChanged: _refreshUnread,
      ),
      // The preview is an uncreated account. Mounting live tabs in the
      // IndexedStack would eagerly read entitlements, links and profile data.
      // Keep the local Network experience, and inject an empty roster for
      // Seekers. Profile is intentionally unavailable until real sign-up.
      const WaliNetworkScreen(),
      WaliSeekersScreen(
        loadLinks: widget.initialOnboardingPreview
            ? () async => const ZyraSourceResult.available(<WaliLinkedPerson>[])
            : null,
        hasGuardianOne: hasGuardianOne,
        requestedSeekerId: _requestedSeekerId,
        selectionRequest: _seekerSelectionRequest,
        onOpenNetwork: () => _goToPage(WaliPage.network),
      ),
      if (widget.initialOnboardingPreview)
        _localProfilePlaceholder()
      else
        WaliProfileScreen(
          onNavigateToNetwork: () => _goToPage(WaliPage.network),
        ),
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // IndexedStack, not `pages[_tab]` — 2026-08-13, parity with the
          // Seeker shell. A bare index swaps WIDGET TYPE on every tab
          // change, so Flutter disposed and rebuilt whichever screen you
          // left; the Network tab re-ran its entitlement fetch every single
          // visit. IndexedStack keeps every visible destination mounted and
          // just toggles which one paints.
          ZyraMenuCanvas(
            child: IndexedStack(index: currentIndex, children: pages),
          ),
          // NO TOP-RIGHT CHROME. Notifications live in Dashboard and the dev
          // wrench retired to the side toggle, so this corner
          // belongs to each page again, exactly as it does on the Seeker
          // side. The history of both stays in git.
          ZyraShellNavigation(
            currentIndex: currentIndex,
            onTap: (index) => _goToPage(visiblePages[index]),
            // Dashboard carries the live unread badge.
            items: [
              FloatingNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                badge: _badgeCount,
              ),
              FloatingNavItem(
                icon: Icons.diversity_3_outlined,
                label: 'Network',
                dimmed: !hasGuardianOne,
              ),
              FloatingNavItem(icon: Icons.people_outline, label: 'Seekers'),
              FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
          if (!widget.initialOnboardingPreview)
            ZyraBottomPromotion(
              role: ZyraPromotionRole.guardian,
              placement: _page == WaliPage.profile
                  ? ZyraPromotionPlacement.profile
                  : ZyraPromotionPlacement.home,
              isCalmLanding: ModalRoute.of(context)?.isCurrent ?? true,
              isEntitled: hasGuardianOne,
              upgradeOfferAvailable: true,
              onOpenPlan: (_) => _goToPage(WaliPage.network),
            ),
          // Developer controls are app-wide in MaterialApp.builder. This
          // shell only registers the real Guardian-tab callback.
        ],
      ),
    );
  }

  Widget _localProfilePlaceholder() => DecoratedBox(
    decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Your Guardian profile will appear here after sign-up.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 16),
          ),
        ),
      ),
    ),
  );
}
