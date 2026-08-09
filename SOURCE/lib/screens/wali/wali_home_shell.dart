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

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/glass_icon_button.dart';
import '../../widgets/notification_bell.dart';
import '../dev/developer_access_screen.dart';
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

  void _goToTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const WaliDashboardScreen(),
      const WaliSeekersScreen(),
      const WaliNetworkScreen(),
      WaliProfileScreen(onNavigateToNetwork: () => _goToTab(2)),
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          pages[_tab],
          // Top-right chrome: Bell icon (2026-07-26, #16) and Dev Access
          // (2026-07-26, #27 — parity with Seeker's HomeShell) — same
          // rule/widgets as the Seeker HomeShell; WaliHomeShell
          // previously had no top-right chrome at all.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NotificationBell(),
                    // FIXED 2026-08-01 (audit finding C1 — Critical).
                    // Unguarded, so the Developer Access wrench shipped in
                    // release builds on the Guardian home screen — hardcoded
                    // credentials for six real accounts, plan switching,
                    // and the mock purchase RPCs, one tap from a guardian's
                    // home screen. See welcome_screen.dart for the full
                    // note; the destination screen now refuses to render in
                    // release as well.
                    if (!kReleaseMode) ...[
                      const SizedBox(width: 10),
                      GlassIconButton(
                        icon: Icons.build_outlined,
                        size: 38,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DeveloperAccessScreen()),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          FloatingNavBar(
            currentIndex: _tab,
            onTap: _goToTab,
            items: const [
              FloatingNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
              FloatingNavItem(icon: Icons.people_outline, label: 'Seekers'),
              FloatingNavItem(icon: Icons.diversity_3_outlined, label: 'Network'),
              FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}
