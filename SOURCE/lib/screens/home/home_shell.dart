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

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../../dev/dev_scenario_panel.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/notification_bell.dart';
import '../browse/browse_screen.dart';
import '../connections/connections_screen.dart';
import '../profile/profile_screen.dart';
import '../wali/seeker_wali_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  /// True while a tab is showing something that must own the entire
  /// screen — currently only Browse's sponsored card. Hides the Bell and
  /// the nav bar, which otherwise render above the tab content and cover
  /// its corners (2026-08-01, Founder: "the skip in the top right is
  /// behind the bell icon").
  bool _chromeHidden = false;

  /// Tab index -> the page the dev scenario panel gates on. The panel is
  /// a sibling of the IndexedStack, not a child, so it cannot read this
  /// itself — it has to be pushed. Debug-only work; in a release build the
  /// panel does not exist and this is a field assignment nothing reads.
  static const _devPages = [
    DevPage.browse,
    DevPage.connections,
    DevPage.guardian,
    DevPage.profile,
  ];

  @override
  void initState() {
    super.initState();
    ZyraDevScenario.instance.setCurrentPage(_devPages[_tab]);
  }

  void _goToTab(int index) {
    setState(() => _tab = index);
    ZyraDevScenario.instance.setCurrentPage(_devPages[index]);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      BrowseScreen(
        onNavigateToConnections: () => _goToTab(1),
        onFullScreenTakeover: (taking) {
          if (_chromeHidden == taking) return;
          setState(() => _chromeHidden = taking);
        },
      ),
      // "View profile" on a Guardian Suggestion parks the profile in
      // AppState and asks for the Browse tab (Founder, 2026-08-05). Browse
      // consumes it on its next build. Done through the shell because
      // Connections cannot change the tab itself — it doesn't own the
      // IndexedStack.
      ConnectionsScreen(onNavigateToBrowse: () => _goToTab(0)),
      const SeekerWaliTab(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // FIXED 2026-07-27 (Founder, dev-mode report: "when on dev i
          // click home and change profiles a old picture shows up
          // before it changes to the profile photos"). Was
          // `pages[_tab]` — a single child that swaps WIDGET TYPE every
          // time `_tab` changes (BrowseScreen ↔ ConnectionsScreen ↔
          // SeekerWaliTab ↔ ProfileScreen all sit at the same Stack
          // position), so Flutter fully disposed and recreated whatever
          // screen you left, every single tab switch. Returning to
          // Browse therefore re-ran its initState() from scratch each
          // time — re-triggering the fresh-fetch flash fixed in
          // browse_screen.dart this same pass, repeatedly, and also
          // silently losing your place in the swipe deck (_index reset
          // to 0) on every trip back. IndexedStack keeps all 4 tabs
          // mounted with their State preserved and just toggles which
          // one paints, so BrowseScreen's fetch now genuinely only runs
          // once, and switching tabs and back leaves you exactly where
          // you were.
          IndexedStack(index: _tab, children: pages),
          // 2026-07-26 (Founder review of the Browse page): the Dev
          // Access wrench that used to sit here is gone — it was
          // redundant with DevNavOverlay's Home button (Back also
          // removed from that overlay this same pass, per "I don't use
          // it, for dev let's just keep the home button"). Home resets
          // to WelcomeScreen, which already has its own Dev Access entry
          // point (welcome_screen.dart) — so nothing is actually lost,
          // just one fewer redundant shortcut in release-adjacent chrome.
          // CHANGED 2026-07-26 (Founder: "move the bell icon to right
          // underneath the 3 dots... meaning u might have to move the
          // home button on left"). Bell no longer sits top-left — it
          // sits top-right. DevNavOverlay's Home button moved to the
          // left this same pass to stay clear of it (dev_nav_overlay.dart).
          //
          // CHANGED 2026-07-27 (Founder: "im thinking of removing the 3
          // [dot] button" — chose "remove icon, centre placecard" when
          // asked to decide between that and a bottom-sheet variant,
          // over keeping the icon as a discoverable fallback). The "..."
          // (more_horiz) icon that used to sit above the Bell here is
          // gone — the Help/Report card it opened is now reached via a
          // long-press held in the centre of the Browse photo instead
          // (see browse_screen.dart _onCentreLongPress). This Column
          // collapsed to a single item now that there's only the Bell —
          // simplified to Align directly rather than leaving a
          // now-pointless Column wrapper around one child.
          // 2026-08-01: hidden while Browse is showing a full-screen
          // takeover (the sponsored card). The Bell and the nav bar below
          // are siblings of the tab content in this Stack, so they render
          // ON TOP of it — the sponsored card's own Skip button sat
          // underneath the Bell and could not be tapped.
          if (!_chromeHidden)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: Align(
                  alignment: Alignment.topRight,
                  child: NotificationBell(),
                ),
              ),
            ),
          // 2026-07-26 (Founder: "connections icon is not a hear[t]... use
          // these icons I have from Lovable" — reference image showed a
          // magnifying glass, then a pill of bookmark / shield-check /
          // person icons). Mapped 1:1 onto the four existing tabs — the
          // Founder's instruction was explicitly to copy the icon glyphs
          // only, not the reference image's circle+pill layout, which
          // stays exactly as it was. Heart (favorite_border) is gone
          // entirely; Connections is a bookmark now, matching the "Save"
          // terminology already used elsewhere in this app (DR-ZYRA-099).
          if (!_chromeHidden)
            FloatingNavBar(
            currentIndex: _tab,
            onTap: _goToTab,
            items: const [
              FloatingNavItem(icon: Icons.search, label: 'Browse'),
              FloatingNavItem(icon: Icons.bookmark_border, label: 'Connections'),
              // 2026-07-26: swapped from verified_user_outlined —
              // Founder reported the active highlight badge looks
              // vertically unbalanced specifically on this tab (more
              // space below the icon than above). Layout math centres
              // all 4 icons identically, so this is very likely the
              // glyph itself: verified_user's inner person-check shape
              // sits high in its bounding box. gpp_good is a plainer
              // shield-checkmark with no inner figure, which sits more
              // symmetrically — worth a visual check once built; if it
              // still looks off, the fix is a different icon, not more
              // layout tuning (see floating_nav_bar.dart's centring fix
              // this same pass, which addresses the layout side).
              FloatingNavItem(icon: Icons.gpp_good_outlined, label: 'Guardian'),
              FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
          // DEV SCENARIO PANEL — 2026-08-01 (Founder: "make a toggle side
          // button where I can select the options to see how it works").
          //
          // Last in the Stack so its pull-out tab sits above the nav bar
          // rather than under it.
          //
          // GATED TWICE, deliberately. This check is the first guard; the
          // widget's own build() returns SizedBox.shrink() in a release
          // build as the second. The 2026-07-26 audit found Developer
          // Access reachable in a release build precisely because one
          // entry point was guarded and another was not — one guard is
          // how that happens again.
          if (!kReleaseMode) const DevScenarioPanel(),
        ],
      ),
    );
  }
}
