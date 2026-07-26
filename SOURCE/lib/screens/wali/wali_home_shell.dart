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

import 'package:flutter/material.dart';
import '../../widgets/floating_nav_bar.dart';
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

  static const _pages = [
    WaliDashboardScreen(),
    WaliSeekersScreen(),
    WaliNetworkScreen(),
    WaliProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _pages[_tab],
          FloatingNavBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
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
