// Home shell — bottom navigation across Browse / Connections / Wali /
// Notifications / Profile.
//
// 2026-08-13 (DR-ZYRA-149, Founder via the ChatGPT nav brief + his own
// placement correction): NOTIFICATIONS BECAME THE FIFTH TAB — "left of
// profile, right of guardian" — and the floating Bell overlay that sat
// top-right over every tab since 2026-07-26 is GONE. This supersedes
// APP/Navigation/SEEKER NAVIGATION Summary's "Notifications are not a
// navigation tab" rule (doc update raised as OA-ZYRA-206). The Bell's
// unread badge survives the move: this shell now owns the 20s unread
// poll the Bell used to run, feeding the tab's badge; opening the tab
// marks rows read in the screen itself, and leaving it re-reads the
// count. The Wali side keeps its Bell — the Guardian shell was not part
// of this ruling.
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

import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode, setEquals;
import 'package:flutter/material.dart';

import '../../dev/dev_scenario_panel_v2.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_notification_service.dart';
import '../../widgets/floating_nav_bar.dart';
import '../browse/browse_screen.dart';
import '../connections/connections_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/help_support_screen.dart';
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
    DevPage.notifications,
    DevPage.profile,
  ];

  /// The Bell's unread count, relocated (DR-ZYRA-149): same 20s poll the
  /// Bell widget ran, now feeding the Notifications tab's badge.
  int _unread = 0;
  Timer? _unreadPoll;

  /// Sections with something waiting — the nav bar's dots (DR-ZYRA-154).
  ///
  /// A SET, not counts: the dot says whether, not how many. See
  /// ZyraNotificationService.fetchSectionsWithUnread.
  Set<ZyraNavSection> _sectionDots = const {};

  /// ACTION MODE — 2026-08-13 (DR-ZYRA-150, Founder's ChatGPT brief,
  /// built on his word over the counter-proposal): Browse's ⋮ asks this
  /// shell to transform the nav bar into two pills — Report Profile /
  /// Help & Support — and a tap anywhere else restores it. Non-null IS
  /// the mode: the value is what Report should do right now (Browse
  /// hands over "report whoever is on the card"), so the shell never
  /// needs to know who is on screen.
  /// CARRIES TWO ACTIONS SINCE 2026-08-13 (DR-ZYRA-155): Hide Profile
  /// left the report sheet and became its own option, so the card has
  /// to hand over both. Still non-null IS the mode, and the shell still
  /// never learns who is on the card.
  ({VoidCallback report, VoidCallback hide, VoidCallback compatibility})?
  _cardActions;
  bool get _actionMode => _cardActions != null;

  /// Which action the bar is sitting on while in action mode.
  ///
  /// STARTS AT 0, AND THAT IS SAFE NOW IN A WAY IT WAS NOT. DR-ZYRA-153
  /// refused to show any resting highlight, because Report Profile was
  /// the first option and a circle resting on it would have said that
  /// option was already chosen. The Founder's 2026-08-13 reorder put
  /// Compatibility Unlock first and Report last, so the resting
  /// highlight now sits on the most benign action on the bar — and the
  /// bar can look exactly like the nav bar, which always highlights
  /// something.
  int _actionIndex = 0;

  /// The action bar's items, in the Founder's display order.
  static const List<({IconData icon, String label, _CardAct act})>
  _actionOptions = [
    // insights_outlined, matching the Compatibility action on the
    // Connections cards exactly — one idea, one glyph, wherever it is
    // reached from.
    (
      icon: Icons.insights_outlined,
      label: 'Compatibility',
      act: _CardAct.compatibility,
    ),
    (icon: Icons.visibility_off_outlined, label: 'Hide', act: _CardAct.hide),
    (icon: Icons.help_outline, label: 'Help', act: _CardAct.help),
    (icon: Icons.flag_outlined, label: 'Report', act: _CardAct.report),
  ];

  /// Runs the chosen action and closes action mode.
  ///
  /// COMMIT-ON-RELEASE IS OPTED INTO, VIA FloatingNavBar.commitOnRelease.
  ///
  /// CORRECTED 2026-08-13 (DR-ZYRA-161). This comment previously claimed
  /// commit-on-release was already the bar's behaviour. It was not, and
  /// the claim was made without reading _handleTouchAt closely enough:
  /// the bar fires onTap the moment a scrub CROSSES a cell, which is
  /// right for tabs and was a live bug here — sliding left to right ran
  /// Hide Profile as the finger passed over it, before it was lifted.
  /// The behaviour is now a property on the shared widget rather than an
  /// assumption about it.
  ///
  /// Two things changed. Report is now LAST, furthest from the thumb.
  /// And — checked before adopting this, not assumed — NONE of the four
  /// actions is irreversible on its own: Report opens a sheet that
  /// requires a reason, Hide opens a confirmation, Help and
  /// Compatibility push a screen you can leave. Every one of them has a
  /// next step, so an accidental tap costs a dismissal.
  void _runAction(int index) {
    final act = _actionOptions[index].act;
    final actions = _cardActions;
    if (actions == null) return;
    setState(() {
      _actionIndex = index;
      _cardActions = null;
    });
    switch (act) {
      case _CardAct.compatibility:
        actions.compatibility();
      case _CardAct.hide:
        actions.hide();
      case _CardAct.help:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
      case _CardAct.report:
        actions.report();
    }
  }

  @override
  void initState() {
    super.initState();
    ZyraDevScenario.instance.setCurrentPage(_devPages[_tab]);
    _refreshUnread();
    _unreadPoll = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshUnread(),
    );
  }

  @override
  void dispose() {
    _unreadPoll?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    final count = await ZyraNotificationService.fetchUnreadCount();
    final dots = await ZyraNotificationService.fetchSectionsWithUnread();
    if (!mounted) return;
    // NULL = THE FETCH FAILED — BUG-05 (OA-ZYRA-225, 2026-08-15): hold
    // the last known badge and dots rather than zeroing marks that may
    // still be earned. A lie in the optimistic direction is still a lie.
    final newCount = count ?? _unread;
    final newDots = dots ?? _sectionDots;
    if (newCount != _unread || !setEquals(newDots, _sectionDots)) {
      setState(() {
        _unread = newCount;
        _sectionDots = newDots;
      });
    }
  }

  /// Which section each tab IS, for the dot-clearing rule. Index-matched
  /// to the nav items below; null where a tab is nobody's destination.
  static const List<ZyraNavSection?> _tabSections = [
    null, // Browse
    ZyraNavSection.connections,
    ZyraNavSection.guardian,
    // Notifications is deliberately null. Arriving is what clears a dot
    // everywhere else, because the dot points at something ELSE; here
    // the notifications ARE the content, so opening the tab marks
    // nothing. That is what leaves Mark all read something to do.
    null,
    null, // Profile
  ];

  void _goToTab(int index) {
    setState(() => _tab = index);
    ZyraDevScenario.instance.setCurrentPage(_devPages[index]);
    // OPENING A SECTION CLEARS ITS DOT — DR-ZYRA-154 (Founder: "the user
    // does NOT need to open the exact notification item for the dot to
    // disappear"). Awaited before the refresh so the count that comes
    // back is the one after the clear, not a stale read racing it.
    final section = _tabSections[index];
    if (section != null) {
      ZyraNotificationService.markSectionRead(
        section,
      ).then((_) => _refreshUnread());
    }
    // Rows get marked read inside the Notifications tab — re-read the
    // count on ANY tab change rather than waiting out the poll, so the
    // badge never lingers after the person has already looked.
    _refreshUnread();
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
        onOpenActions: (actions) => setState(() {
          _cardActions = actions;
          // Always opens on Compatibility. Leaving the highlight where
          // the last visit left it would mean the bar sometimes opened
          // sitting on Report.
          _actionIndex = 0;
        }),
      ),
      // "View profile" on a Guardian Suggestion parks the profile in
      // AppState and asks for the Browse tab (Founder, 2026-08-05). Browse
      // consumes it on its next build. Done through the shell because
      // Connections cannot change the tab itself — it doesn't own the
      // IndexedStack.
      ConnectionsScreen(onNavigateToBrowse: () => _goToTab(0)),
      const SeekerWaliTab(),
      // Tab four (DR-ZYRA-149): the Bell's destination, now a
      // destination proper — isTab hides the back arrow that would
      // otherwise pop HomeShell itself.
      const NotificationsScreen(isTab: true),
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
          // THE BELL OVERLAY IS GONE — 2026-08-13 (DR-ZYRA-149): its
          // destination is tab four now, its badge lives on that tab,
          // and the top-right corner belongs to each page again. The
          // long history of this corner (bell top-left -> top-right,
          // the retired ⋯) stays in git.
          // 2026-07-26 (Founder: "connections icon is not a hear[t]... use
          // these icons I have from Lovable" — reference image showed a
          // magnifying glass, then a pill of bookmark / shield-check /
          // person icons). Mapped 1:1 onto the four existing tabs — the
          // Founder's instruction was explicitly to copy the icon glyphs
          // only, not the reference image's circle+pill layout, which
          // stays exactly as it was. Heart (favorite_border) is gone
          // entirely; Connections is a bookmark now, matching the "Save"
          // terminology already used elsewhere in this app (DR-ZYRA-099).
          // Mid action-mode: one full-screen catcher UNDER the action
          // bar — "user clicks anywhere and the nav bar returns". It
          // deliberately swallows that tap (dismissing is the tap's
          // whole meaning; letting it also page a photo would make one
          // gesture do two things).
          if (_actionMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _cardActions = null),
              ),
            ),
          // ONE BAR — 2026-08-13 (DR-ZYRA-159). Action mode swaps the
          // ITEMS; it does not build a second bar. Everything the
          // Founder kept pointing at — height, width, inset, spacing,
          // icon scale, the highlight, the way it grows under a
          // finger — is now identical because it is the same widget,
          // not because four decisions in a row got the numbers to
          // agree.
          if (!_chromeHidden)
            FloatingNavBar(
              currentIndex: _actionMode ? _actionIndex : _tab,
              onTap: _actionMode ? _runAction : _goToTab,
              // ACTIONS WAIT FOR THE FINGER TO LIFT — DR-ZYRA-161. Tabs
              // keep firing live as you scrub, which is what makes the
              // nav bar feel scrubable; running Report or Hide as a
              // finger passes over them is a different thing entirely.
              commitOnRelease: _actionMode,
              // No longer const: the Notifications item carries the live
              // unread badge (DR-ZYRA-149).
              items: _actionMode
                  ? [
                      for (final o in _actionOptions)
                        FloatingNavItem(icon: o.icon, label: o.label),
                    ]
                  : [
                      FloatingNavItem(icon: Icons.search, label: 'Browse'),
                      FloatingNavItem(
                        icon: Icons.bookmark_border,
                        label: 'Connections',
                        dot: _sectionDots.contains(ZyraNavSection.connections),
                      ),
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
                      FloatingNavItem(
                        icon: Icons.gpp_good_outlined,
                        label: 'Guardian',
                        dot: _sectionDots.contains(ZyraNavSection.guardian),
                      ),
                      FloatingNavItem(
                        icon: Icons.notifications_none,
                        label: 'Notifications',
                        badge: _unread,
                      ),
                      FloatingNavItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                      ),
                    ],
            ),
          // (The transformed bar is the SAME FloatingNavBar above, with
          // its items swapped — see _runAction and _actionOptions.)
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
          if (!kReleaseMode)
            DevScenarioPanelV2(
              onOpenPage: (page) => _goToTab(_devPages.indexOf(page)),
            ),
        ],
      ),
    );
  }
}

/// What an action-bar option DOES, independent of where it sits.
///
/// The order below is display order (Founder, 2026-08-13): most
/// relevant profile action first, then privacy, support, and
/// safety/reporting. Each item carries its act, so reordering the list
/// cannot rewire the buttons.
enum _CardAct { compatibility, hide, help, report }

/// _ActionModeBar DELETED 2026-08-13 (DR-ZYRA-159).
///
/// It was a hand-built replica of FloatingNavBar: same metrics, same
/// highlight widget, same gesture wiring, same glass — reached across
/// four decisions (153, 155, 156, 158), each closing another visible
/// gap between the copy and the original. The Founder's side-by-side
/// screenshots closed the argument: a replica converges on the thing it
/// copies and never arrives, because every future change to the real
/// bar has to be noticed and mirrored by hand.
///
/// Browse's ⋯ now swaps the ITEMS in the real FloatingNavBar. There is
/// one bar. Its contents change. Nothing can drift because there is
/// nothing to keep in step — which is what "the same navigation
/// component changing state, not a separate design" actually requires.
