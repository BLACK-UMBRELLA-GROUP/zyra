// Wali home shell — fixed 4-tab navigation per WALI ARCHITECTURE
// §WALI NAVIGATION: Dashboard · Seekers · Network · Profile, no
// Universal Toggle (that's a Seeker-only mechanic).
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

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../dev/wali_dev_scenario_panel.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_notification_service.dart';
import '../../widgets/floating_nav_bar.dart';
import '../notifications/notifications_screen.dart';
import 'wali_dashboard_screen.dart';
import 'wali_network_screen.dart';
import 'wali_profile_screen.dart';
import 'wali_seekers_screen.dart';

class WaliHomeShell extends StatefulWidget {
  const WaliHomeShell({super.key});

  @override
  State<WaliHomeShell> createState() => _WaliHomeShellState();
}

class _WaliHomeShellState extends State<WaliHomeShell> {
  int _tab = 0;

  /// The Bell's unread count, relocated (2026-08-13) — the same 20s poll
  /// the Bell widget ran, now feeding the Notifications tab's badge. Same
  /// mechanism as the Seeker shell, deliberately: two shells polling two
  /// different ways would drift.
  int _unread = 0;
  Timer? _unreadPoll;

  /// The tab order, as an enum the dev panel can gate on. Index-matched to
  /// [_pages] below — if one moves, both move.
  static const List<WaliPage> _devPages = [
    WaliPage.dashboard,
    WaliPage.network,
    WaliPage.seekers,
    WaliPage.notifications,
    WaliPage.profile,
  ];

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    _unreadPoll = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshUnread(),
    );
    if (!kReleaseMode) {
      // The panel needs to know where we ARE before the first tab change,
      // or its first open shows the wrong card.
      ZyraDevScenario.instance.setCurrentWaliPage(_devPages[_tab]);
      ZyraDevScenario.instance.addListener(_onScenarioChange);
    }
  }

  @override
  void dispose() {
    _unreadPoll?.cancel();
    if (!kReleaseMode) {
      ZyraDevScenario.instance.removeListener(_onScenarioChange);
    }
    super.dispose();
  }

  /// Repaints the badge when the panel's staged unread count changes.
  /// Debug/profile only — never registered in a release build.
  void _onScenarioChange() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshUnread() async {
    final count = await ZyraNotificationService.fetchUnreadCount();
    // Null = the fetch failed (BUG-05, OA-ZYRA-225, 2026-08-15) — hold
    // the last known badge, same rule as the Seeker shell.
    if (mounted && count != null && count != _unread) {
      setState(() => _unread = count);
    }
  }

  /// What the badge shows.
  ///
  /// The staged count WINS while it is above zero, and only the badge is
  /// staged — the list behind it stays real rows. A count that disagreed
  /// with the list it labels would be worse than no control, so the panel
  /// says as much on the Notifications card.
  int get _badgeCount {
    if (kReleaseMode) return _unread;
    final staged = ZyraDevScenario.instance.waliUnread;
    return staged > 0 ? staged : _unread;
  }

  void _goToTab(int index) {
    setState(() => _tab = index);
    if (!kReleaseMode) {
      ZyraDevScenario.instance.setCurrentWaliPage(_devPages[index]);
    }
    // Rows are marked read inside the Notifications tab — re-read on ANY
    // tab change rather than waiting out the poll, so the badge never
    // lingers after the Guardian has already looked.
    _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    // ORDER — Network then Seekers (2026-08-13, Founder: "swap in nav bar
    // Seekers and Network around"). Profile stays last; Notifications sits
    // left of it, matching the Seeker shell's placement exactly.
    final pages = [
      const WaliDashboardScreen(),
      const WaliNetworkScreen(),
      const WaliSeekersScreen(),
      const NotificationsScreen(isTab: true),
      WaliProfileScreen(onNavigateToNetwork: () => _goToTab(1)),
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // IndexedStack, not `pages[_tab]` — 2026-08-13, parity with the
          // Seeker shell. A bare index swaps WIDGET TYPE on every tab
          // change, so Flutter disposed and rebuilt whichever screen you
          // left; the Network tab re-ran its entitlement fetch every single
          // visit. IndexedStack keeps all five mounted and just toggles
          // which one paints.
          IndexedStack(index: _tab, children: pages),
          // NO TOP-RIGHT CHROME — 2026-08-13. The Bell became tab four and
          // the dev wrench retired to the side toggle, so this corner
          // belongs to each page again, exactly as it does on the Seeker
          // side. The history of both stays in git.
          FloatingNavBar(
            currentIndex: _tab,
            onTap: _goToTab,
            // No longer const: Notifications carries the live unread badge.
            items: [
              FloatingNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
              ),
              FloatingNavItem(
                icon: Icons.diversity_3_outlined,
                label: 'Network',
              ),
              FloatingNavItem(icon: Icons.people_outline, label: 'Seekers'),
              FloatingNavItem(
                icon: Icons.notifications_none,
                label: 'Notifications',
                badge: _badgeCount,
              ),
              FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
          // LAST CHILD, so the pull-out tab sits above the nav bar and
          // stays tappable. Guarded here AND inside the widget, per the
          // 2026-07-26 audit finding that Developer Access once shipped
          // reachable in a release build.
          if (!kReleaseMode)
            WaliDevScenarioPanel(
              onOpenPage: (page) => _goToTab(_devPages.indexOf(page)),
            ),
        ],
      ),
    );
  }
}
