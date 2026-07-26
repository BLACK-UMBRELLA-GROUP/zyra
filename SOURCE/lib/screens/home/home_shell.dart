// Home shell — bottom navigation across Browse / Connections / Wali /
// Profile.
//
// 2026-07-26 (DR-ZYRA-101 audit, nav bar fix): rebuilt from 3 tabs
// (Browse/Matches/Profile) to the 4 tabs approved in APP/Navigation/
// SEEKER NAVIGATION/Summary.md's NAVIGATION STRUCTURE table for both
// ZYRA Basic and ZYRA One Seekers. That spec document itself flagged
// this exact gap under CURRENT STATUS (2026-07-19, unresolved): "live
// Seeker nav has only 3 tabs... matches neither the 4-tab spec nor any
// coherent variant." A separate 2026-07-19 discussion item (OA-ZYRA-129)
// proposed a 5th tab (Network, locked for Seekers) — Founder decision
// 2026-07-26 was to build the ratified 4-tab structure and NOT add
// Network, since "Network is never available to Seekers (any tier)"
// is an explicitly confirmed rule (2026-06-27) and OA-ZYRA-129 was
// never ratified against it. The Matches tab is renamed Connections
// and now also houses Passed/Saved/Considered per that same spec's
// CONNECTIONS section — see screens/connections/connections_screen.dart.
// The new Wali tab is screens/wali/seeker_wali_tab.dart, a tab-body
// wrapper around the existing LinkWaliScreen mechanism.
//
// 2026-07-19 (OA-ZYRA-125 §3, DR-ZYRA-089): the fixed solid dark-purple
// `bottomNavigationBar` bar was replaced with a floating glassmorphic
// pill. `extendBody: true` was already set, so BrowseScreen's
// full-bleed photo already reached the bottom of the screen — the
// change is purely about what floats on top of it.
//
// 2026-07-19, DR-ZYRA-091: nav bar itself rebuilt onto the shared
// FloatingNavBar widget (widgets/floating_nav_bar.dart) — Founder
// supplied Instagram + Lovable reference recordings; the icon-grows-
// when-selected behaviour and the single sliding circular highlight
// (rather than each item having its own static background) both come
// from those references. See that file's header for full detail.

import 'package:flutter/material.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/glass_icon_button.dart';
import '../browse/browse_screen.dart';
import '../connections/connections_screen.dart';
import '../dev/developer_access_screen.dart';
import '../profile/profile_screen.dart';
import '../wali/seeker_wali_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _goToTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      BrowseScreen(onNavigateToConnections: () => _goToTab(1)),
      const ConnectionsScreen(),
      const SeekerWaliTab(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          pages[_tab],
          // Dev Access shortcut — reachable from anywhere inside the app,
          // not just the pre-auth Welcome screen (2026-07-18 fix: this
          // was previously only reachable before signing in, so there was
          // no way back to the account switcher once inside HomeShell).
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: GlassIconButton(
                  icon: Icons.build_outlined,
                  size: 38,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DeveloperAccessScreen()),
                  ),
                ),
              ),
            ),
          ),
          FloatingNavBar(
            currentIndex: _tab,
            onTap: _goToTab,
            items: const [
              FloatingNavItem(icon: Icons.explore_outlined, label: 'Browse'),
              FloatingNavItem(icon: Icons.favorite_border, label: 'Connections'),
              FloatingNavItem(icon: Icons.shield_outlined, label: 'Wali'),
              FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}
