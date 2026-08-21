// Guardian developer scenario panel — the pull-out tab on the Guardian
// shell's right edge. DR-ZYRA-152, 2026-08-13.
//
// Founder: the Guardian side had NO dev toggle at all. The Seeker side
// has had one since 2026-08-01, so every Guardian state — a ward, their
// Journey, a Family Review waiting on you — could only be reached by
// owning two accounts, two devices and a live invite. He tests alone.
//
// ── WHY THIS IS A SECOND WIDGET AND NOT A SECOND STORE.
//
// The state lives in ZyraDevScenario, beside the Seeker fields, under one
// reset(). Only the WIDGET is duplicated, because the two shells mount
// different trees and the cards differ completely — a Guardian has no
// plan, no Browse, no popups.
//
// ── THE SMALL PRIVATE WIDGETS BELOW ARE COPIES, ON PURPOSE.
//
// The Guardian-specific controls remain local because role refusal and
// Journey/ward staging have no Seeker equivalent. The surrounding panel now
// follows the clean Seeker V2 contract: OPEN destinations, contextual tools,
// inline feedback and RESET.
//
// ── THE RED SHAKE IS BACK, AND THIS IS THE CASE IT WAS KEPT FOR.
//
// dev_scenario_panel deleted its _Deniable on 2026-08-12, correctly: once
// plan/page mismatches switched from dimmed to HIDDEN (2026-08-07), a
// shown-but-refused control became an empty set, and the machinery
// guarded nothing for five weeks. Its own note said it was being kept
// "for the rare control that is shown-but-refused; none arrived".
//
// Three have now arrived, and hiding all three would teach the tester
// something false:
//
//   ROLE-GATED       An Additional Guardian gets a strictly SMALLER app —
//                    no counterpart card, so no Journeys at all, and no
//                    Family Review vote. Hide those controls and the role
//                    segment appears to do nothing; the one honest way to
//                    show a missing privilege is a control that is there
//                    and refuses.
//   NOT FAKEABLE     Invitations received, Introductions sent — see §
//                    "Cannot be staged" below. Hidden, they would read as
//                    "not built yet". Refused, they say why and point at
//                    the door that does work.
//
// So: HIDE means "does not apply to you"; REFUSE means "applies, and here
// is why you cannot have it". The Seeker panel has only the first kind.
//
// ── CANNOT BE STAGED, AND SAYS SO.
//
// The panel's founding rule is that a toggle must change something real.
// Two of the sections in the build brief have no reader anywhere in the
// app, so neither got a field:
//
//   Invitations received  `wali_invites` has no recipient column — an
//                         invite is a bearer code typed into
//                         accept_wali_invite_screen. There is no list.
//   Introductions sent    fetchPending() returns suggestions FOR a
//                         Seeker; both callers are Seeker screens. No
//                         Guardian surface shows what this Guardian sent.
//
// Both are drawn, greyed, pointing at Developer Access — the signed-out
// door with real @zyra.test accounts, which is the only honest way to
// exercise either flow today.
//
// RELEASE SAFETY — double-guarded, same as the Seeker panel:
//   1. WaliHomeShell only builds it when !kReleaseMode.
//   2. build() returns SizedBox.shrink() in a release build regardless.

import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../data/zyra_journey_stages.dart';
import '../screens/auth_gate.dart';
import '../services/zyra_auth.dart';
import '../theme/zyra_text.dart';
import 'wali_dashboard_preview.dart';
import 'zyra_dev_scenario.dart';

class WaliDevScenarioPanel extends StatefulWidget {
  final ValueChanged<WaliPage> onOpenPage;

  const WaliDevScenarioPanel({super.key, required this.onOpenPage});

  @override
  State<WaliDevScenarioPanel> createState() => _WaliDevScenarioPanelState();
}

class _WaliDevScenarioPanelState extends State<WaliDevScenarioPanel> {
  bool _open = false;

  static const double _panelWidth = 286;
  static const double _tabWidth = 22;

  final ZyraDevScenario _s = ZyraDevScenario.instance;
  String? _notice;

  /// Collapsed section cards, by id — session-local, same as the Seeker
  /// panel: the arrangement survives opens, a fresh launch starts open.
  final Set<String> _collapsedCards = {};

  @override
  void initState() {
    super.initState();
    _s.addListener(_onChange);
  }

  @override
  void dispose() {
    _s.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _goHome() async {
    setState(() {
      _open = false;
      _notice = null;
    });
    try {
      await ZyraAuth.signOut();
    } catch (error) {
      debugPrint('ZYRA Guardian developer Home sign-out failed: $error');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate(playSplash: true)),
      (route) => false,
    );
  }

  Widget _card(
    String id,
    IconData icon,
    String title,
    List<Widget> children, {
    String? subtitle,
  }) {
    return _SectionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      collapsed: _collapsedCards.contains(id),
      onToggle: () => setState(
        () => _collapsedCards.contains(id)
            ? _collapsedCards.remove(id)
            : _collapsedCards.add(id),
      ),
      children: children,
    );
  }

  /// NO CONFIRM DIALOG, and that is a difference from the Seeker panel
  /// rather than an omission. Its Reset deletes real rows — mock plan
  /// writes, wali_suggestions, granted credits — so it asks first.
  /// Nothing on this side writes to the server: every Guardian control
  /// here composes stand-ins in memory. There is nothing to lose and
  /// nothing to confirm.
  void _reset() {
    _s.reset();
    setState(() => _notice = 'Guardian and Seeker previews reset.');
  }

  void _openPage(WaliPage page) {
    setState(() {
      _open = false;
      _notice = null;
    });
    widget.onOpenPage(page);
  }

  /// The reason the role segment refuses a control, or null when it does
  /// not. One sentence, because it is read on a 286pt panel.
  String? get _roleDenial => _s.waliIsMain
      ? null
      : 'Additional Guardians have no counterpart card, so no Journeys '
            'reach the Dashboard and there is no Family Review vote to cast. '
            'Switch the role above to stage these.';

  @override
  Widget build(BuildContext context) {
    // Backstop — see the header. Not an else-branch of the mount point.
    if (kReleaseMode) return const SizedBox.shrink();

    final page = _s.currentWaliPage;

    return Positioned(
      top: 0,
      bottom: 0,
      right: _open ? 0 : -_panelWidth,
      width: _panelWidth + _tabWidth,
      child: Row(
        children: [
          _Tab(open: _open, onTap: () => setState(() => _open = !_open)),
          Expanded(
            child: Material(
              color: const Color(0xF20E0B12),
              child: SafeArea(
                left: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  children: [
                    // Same information architecture as the Seeker panel,
                    // deliberately — one tool, two sides:
                    //   1. Session actions   Home · Reset
                    //   2. Context bar       page · role · what's live
                    //   3. SET UP FIRST      role, the choice everything
                    //                        else depends on
                    //   4. THE CURRENT TAB   one card, sub-sectioned
                    //   5. TESTING ALONE     what cannot be staged, and
                    //                        the door that does work
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ZYRA DEV',
                                style: ZyraText.chapterLabel(
                                  color: Colors.white54,
                                ),
                              ),
                              Text(
                                page.label,
                                style: ZyraText.heading(size: 18),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Home',
                          onPressed: _goHome,
                          icon: const Icon(
                            Icons.home_outlined,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                        _ResetButton(onTap: _reset),
                        IconButton(
                          onPressed: () => setState(() => _open = false),
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'OPEN',
                      style: ZyraText.chapterLabel(color: Colors.white38),
                    ),
                    const SizedBox(height: 7),
                    _WaliDestinations(current: page, onOpen: _openPage),
                    if (_notice != null) ...[
                      const SizedBox(height: 10),
                      _WaliInlineNotice(
                        message: _notice!,
                        onDismiss: () => setState(() => _notice = null),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _Now(page: page, role: _s.waliRole),
                    const SizedBox(height: 12),

                    // ── 3 · SET UP FIRST ────────────────────────────────
                    _card(
                      'wali-setup',
                      Icons.flag_outlined,
                      'Set up first',
                      subtitle: 'Choose before you walk the app',
                      [
                        _Control(
                          label: 'Your role',
                          hint:
                              'wali_links.is_main is a real privilege '
                              'boundary, not a label. Main gets the '
                              'counterpart card and the Family Review vote; '
                              'Additional gets neither.',
                          child: _Segment(
                            options: const ['Main', 'Additional'],
                            index: _s.waliIsMain ? 0 : 1,
                            onChanged: (i) => _s.setWaliRole(
                              i == 0 ? WaliRole.main : WaliRole.additional,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── 4 · THE CURRENT TAB ─────────────────────────────
                    if (page == WaliPage.dashboard)
                      _card(
                        'wali-dashboard',
                        Icons.dashboard_outlined,
                        'Dashboard',
                        [
                          const _SubHeader('Your Seekers'),
                          _Control(
                            label: 'Linked Seekers',
                            hint:
                                'Real links first, stand-ins after. 0 means '
                                'zero — your real links included — which is '
                                'what makes Reset mean reset.',
                            child: _CountRow(
                              value: _s.waliLinkedSeekers,
                              max: ZyraDevScenario.fakeWards.length,
                              onChanged: _s.setWaliLinkedSeekers,
                            ),
                          ),
                          const _SubHeader('Their Journeys'),
                          _Deniable(
                            denied: _roleDenial,
                            child: _Control(
                              label: 'Active Journeys',
                              hint:
                                  'One per Seeker — the database enforces it '
                                  'with a unique partial index, so this caps '
                                  'at your Seeker count.',
                              child: _CountRow(
                                value: _s.waliActiveJourneys,
                                max: _s.waliLinkedSeekers,
                                onChanged: _s.setWaliActiveJourneys,
                              ),
                            ),
                          ),
                          _Deniable(
                            denied: _roleDenial,
                            child: _Control(
                              label: 'Stage',
                              hint:
                                  'Where the Active Journeys sit. Fed by the '
                                  'one canonical map (DR-ZYRA-129) — no stage '
                                  'name is written in this file.',
                              child: _StageRow(
                                index: _s.waliStageIndex,
                                onChanged: _s.setWaliStageIndex,
                              ),
                            ),
                          ),
                          _Deniable(
                            denied: _roleDenial,
                            child: _Control(
                              label: 'Paused Journeys',
                              hint:
                                  'Paused by the other family — a Guardian '
                                  'cannot pause a Journey, so "paused by you" '
                                  'is not a state this role can be in. Takes '
                                  'the Seeker slots Active left.',
                              child: _CountRow(
                                value: _s.waliPausedJourneys,
                                max:
                                    (_s.waliLinkedSeekers -
                                            _s.waliActiveJourneys)
                                        .clamp(0, _s.waliLinkedSeekers),
                                onChanged: _s.setWaliPausedJourneys,
                              ),
                            ),
                          ),
                          _Deniable(
                            denied: _roleDenial,
                            child: _Control(
                              label: 'Ended Journeys',
                              hint:
                                  'History, not a slot — an ended Journey '
                                  'does not stop the same Seeker holding an '
                                  'active one, so these are not capped by the '
                                  'Seeker count.',
                              child: _CountRow(
                                value: _s.waliEndedJourneys,
                                max: 5,
                                onChanged: _s.setWaliEndedJourneys,
                              ),
                            ),
                          ),
                          // ── WARD ACTIVITY — DR-ZYRA-171. Staged ONLY:
                          // a ward's Browse decisions have no Guardian
                          // read path in RLS today, so these chips exist
                          // to review the DESIGN, and the panel says so
                          // rather than letting a mock read as a feature.
                          const _SubHeader('Ward activity (staged)'),
                          _Control(
                            label: 'Saved',
                            hint:
                                'Chips on every ward card. No server read '
                                'exists for a ward\'s Browse activity — '
                                'these are design stand-ins, and the real '
                                'read is a raised privacy decision.',
                            child: _CountRow(
                              value: _s.wardSaved,
                              max: 30,
                              onChanged: _s.setWardSaved,
                            ),
                          ),
                          _Control(
                            label: 'Considering',
                            hint: 'Same staging rule as Saved.',
                            child: _CountRow(
                              value: _s.wardConsidered,
                              max: 30,
                              onChanged: _s.setWardConsidered,
                            ),
                          ),
                          _Control(
                            label: 'Declined',
                            hint: 'Same staging rule as Saved.',
                            child: _CountRow(
                              value: _s.wardDeclined,
                              max: 30,
                              onChanged: _s.setWardDeclined,
                            ),
                          ),
                          const _SubHeader('Family Review'),
                          _Deniable(
                            denied:
                                _roleDenial ??
                                (_s.waliActiveJourneys == 0
                                    ? 'A review gates one stage to the next, so '
                                          'it needs a running Journey to sit on. '
                                          'Stage an Active Journey first.'
                                    : null),
                            child: _Control(
                              label: 'Review awaiting you',
                              hint:
                                  'Opens a 48h window on every staged Active '
                                  'Journey. Continue and Pause write to the '
                                  'staged review and the screen re-reads it — '
                                  'no snackbar standing in for the product.',
                              child: _Segment(
                                options: const ['Off', 'On'],
                                index: _s.waliReviewWaiting ? 1 : 0,
                                onChanged: (i) =>
                                    _s.setWaliReviewWaiting(i == 1),
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (page == WaliPage.seekers)
                      _card('wali-seekers', Icons.people_outline, 'Seekers', [
                        _Control(
                          label: 'Linked Seekers',
                          hint:
                              'The same count the Dashboard reads — one '
                              'control, both screens, so they cannot '
                              'disagree.',
                          child: _CountRow(
                            value: _s.waliLinkedSeekers,
                            max: ZyraDevScenario.fakeWards.length,
                            onChanged: _s.setWaliLinkedSeekers,
                          ),
                        ),
                        const _SubHeader('Invitations'),
                        _Control(
                          label: 'Invitations sent',
                          hint:
                              'Codes you created that nobody has redeemed. '
                              'Real rows first — the list on Invite your '
                              'Seeker is new, and reads the same '
                              'fetchPendingInvites() the Seeker side has '
                              'always used.',
                          child: _CountRow(
                            value: _s.waliSentInvites,
                            max: ZyraDevScenario.fakeWaliInvites.length,
                            onChanged: _s.setWaliSentInvites,
                          ),
                        ),
                      ]),

                    if (page == WaliPage.notifications)
                      _card(
                        'wali-notifications',
                        Icons.notifications_none,
                        'Notifications',
                        [
                          _Control(
                            label: 'Unread badge',
                            hint:
                                'Overrides the tab badge while above zero. '
                                'The Bell became tab four on 2026-08-13 '
                                '(DR-ZYRA-149) — this is that badge, not the '
                                'retired overlay.',
                            child: _CountRow(
                              value: _s.waliUnread,
                              max: 12,
                              onChanged: _s.setWaliUnread,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'The badge only. The LIST behind it is real rows '
                              'and is not staged — a count that disagreed with '
                              'the list it labels would be worse than no '
                              'control.',
                              style: ZyraText.subtext(
                                size: 10.5,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (page == WaliPage.network)
                      _card(
                        'wali-network',
                        Icons.diversity_3_outlined,
                        'Network',
                        [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Nothing to stage. Guardian+ is a REAL '
                              'entitlement — wali_has_extended_wali() reads a '
                              'subscriptions row, and the page\'s own "Get '
                              'Guardian+" button writes one through '
                              'mock_purchase_wali_premium(). A toggle here '
                              'would set a flag the server would then '
                              'contradict, which is exactly how the old '
                              'unlock-credits control went wrong.\n\n'
                              'Both Network tabs are empty by design until '
                              'real Network data exists.',
                              style: ZyraText.subtext(
                                size: 10.5,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (page == WaliPage.profile)
                      _card('wali-profile', Icons.person_outline, 'Profile', [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Your role lives under Set up first. Guardian '
                            'profile scenarios (verification, photo, '
                            'completion) have no reader yet — the Seeker '
                            'side\'s equivalent is tracked as OA-ZYRA-202.',
                            style: ZyraText.subtext(
                              size: 10.5,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ]),

                    // ── 4b · THE INTENDED DASHBOARD ─────────────────────
                    _card(
                      'wali-preview',
                      Icons.grid_view_outlined,
                      'Dashboard preview',
                      subtitle: 'What it could hold, before it is built',
                      [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Opens a read-only screen showing what the Guardian '
                            'dashboard could hold, with every section marked '
                            'BUILT, DESIGNED or BLOCKED. It follows the '
                            'steppers above, so it can be argued with rather '
                            'than admired. Writes nothing.',
                            style: ZyraText.subtext(
                              size: 10.5,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        _Control(
                          label: 'Open the preview',
                          hint:
                              'Debug and profile builds only. No route in the '
                              'real app reaches it.',
                          child: _StripButton(
                            label: 'Guardian dashboard — preview',
                            icon: Icons.open_in_new,
                            onTap: () {
                              setState(() => _open = false);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WaliDashboardPreview(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // ── 5 · TESTING ALONE ───────────────────────────────
                    _card(
                      'wali-alone',
                      Icons.groups_outlined,
                      'Testing alone',
                      subtitle: 'What this panel cannot fake',
                      [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'A toggle must change something real. These two '
                            'have no reader anywhere in the app, so they are '
                            'shown refused rather than given a stepper that '
                            'writes into nothing — which would look exactly '
                            'like a feature that had been checked.',
                            style: ZyraText.subtext(
                              size: 10.5,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        const _SubHeader('Not fakeable'),
                        _Deniable(
                          denied:
                              'wali_invites has no recipient — an invite is '
                              'a bearer code, so nobody knows who it is for '
                              'until it is typed in. There is no list to stage '
                              'and no screen that renders one. Use Developer '
                              'Access and a second @zyra.test account.',
                          child: _Control(
                            label: 'Invitations received',
                            hint:
                                'Needs invites to become ADDRESSED rather '
                                'than bearer tokens. That is a product '
                                'decision, not a screen.',
                            child: _CountRow(
                              value: 0,
                              max: 5,
                              onChanged: (_) {},
                            ),
                          ),
                        ),
                        _Deniable(
                          denied:
                              'Nothing on the Guardian side lists what you '
                              'put forward — fetchPending() returns '
                              'suggestions FOR a Seeker, and both its callers '
                              'are Seeker screens. Sign in as the Seeker via '
                              'Developer Access to see them land.',
                          child: _Control(
                            label: 'Introductions sent',
                            hint:
                                'The Seeker panel stages the receiving half '
                                'of this, on Connections → Introductions.',
                            child: _CountRow(
                              value: 0,
                              max: 5,
                              onChanged: (_) {},
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Debug and profile builds only. Never present in a '
                      'release build — guarded at the mount point and again '
                      'inside this widget.',
                      style: ZyraText.subtext(size: 10, color: Colors.white24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Guardian-specific panel primitives — see the header.
// ═══════════════════════════════════════════════════════════════════════

class _WaliDestinations extends StatelessWidget {
  final WaliPage current;
  final ValueChanged<WaliPage> onOpen;

  const _WaliDestinations({required this.current, required this.onOpen});

  static const _items = [
    (WaliPage.dashboard, Icons.dashboard_outlined, 'Dashboard'),
    (WaliPage.network, Icons.diversity_3_outlined, 'Network'),
    (WaliPage.seekers, Icons.people_outline, 'Seekers'),
    (WaliPage.notifications, Icons.notifications_none, 'Alerts'),
    (WaliPage.profile, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final item in _items)
          SizedBox(
            width: 78,
            height: 52,
            child: Material(
              color: current == item.$1
                  ? const Color(0xFF3A2D43)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onOpen(item.$1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$2, size: 16, color: Colors.white60),
                    const SizedBox(height: 3),
                    Text(
                      item.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZyraText.subtext(size: 9, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WaliInlineNotice extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _WaliInlineNotice({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF78C69D);
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 2, 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: ZyraText.subtext(size: 10, color: Colors.white70),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

/// Current context — tab, role, and how much of the panel is live.
class _Now extends StatelessWidget {
  final WaliPage page;
  final WaliRole role;
  const _Now({required this.page, required this.role});

  int get _live {
    final s = ZyraDevScenario.instance;
    var n = 0;
    if (s.waliLinkedSeekers > 0) n++;
    if (s.waliActiveJourneys > 0) n++;
    if (s.waliPausedJourneys > 0) n++;
    if (s.waliEndedJourneys > 0) n++;
    if (s.waliReviewWaiting) n++;
    if (s.waliSentInvites > 0) n++;
    if (s.waliUnread > 0) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final live = _live;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${page.label} · ${role.label}',
            style: ZyraText.body(size: 12, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            live == 0
                ? 'Everything at zero — the app is showing real state.'
                : '$live scenario${live == 1 ? '' : 's'} live.',
            style: ZyraText.subtext(size: 10.5, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

/// One control: label, hint, the input itself.
///
/// No plan filter — a Guardian has no ZYRA Basic/One. Role gating is done
/// by wrapping in [_Deniable] rather than by a field here, because role
/// REFUSES where the Seeker panel's plan filter HIDES.
class _Control extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _Control({
    required this.label,
    required this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ZyraText.subtext(size: 12.5, color: Colors.white)),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: ZyraText.subtext(size: 10, color: Colors.white38),
            ),
          ],
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// Dims its child and refuses the tap with a red shake and the reason.
///
/// REINSTATED 2026-08-13 — see the file header for why the Seeker panel
/// was right to delete its version and why this side needs one. The
/// implementation is deliberately the simplest thing that shakes: a
/// TweenSequence on an offset, driven once per refused tap.
class _Deniable extends StatefulWidget {
  final String? denied;
  final Widget child;
  const _Deniable({required this.denied, required this.child});

  @override
  State<_Deniable> createState() => _DeniableState();
}

class _DeniableState extends State<_Deniable>
    with SingleTickerProviderStateMixin {
  bool _showReason = false;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 8, end: -7), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -7, end: 5), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _refuse() {
    _c.forward(from: 0);
    setState(() => _showReason = true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.denied == null) return widget.child;

    const danger = Color(0xFFE08080);
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) =>
          Transform.translate(offset: Offset(_shake.value, 0), child: child),
      child: GestureDetector(
        // Opaque so the tap lands here and never on the control beneath —
        // a refused control that still changes the value is worse than no
        // refusal at all.
        behavior: HitTestBehavior.opaque,
        onTap: _refuse,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: danger.withValues(alpha: 0.22),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Opacity(opacity: 0.38, child: IgnorePointer(child: widget.child)),
              if (_showReason) ...[
                const SizedBox(height: 5),
                Text(
                  widget.denied!,
                  style: ZyraText.subtext(size: 9.5, color: danger),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A collapsible section card.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool collapsed;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.collapsed,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: ZyraText.subtext(
                            size: 10.5,
                            color: Colors.white70,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: ZyraText.subtext(
                              size: 9.5,
                              color: Colors.white38,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    collapsed
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 16,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }
}

/// A small labelled divider INSIDE a section card.
class _SubHeader extends StatelessWidget {
  final String label;
  const _SubHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: ZyraText.subtext(size: 9, color: Colors.white38),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _Tab({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: _WaliDevScenarioPanelState._tabWidth,
          height: 92,
          decoration: BoxDecoration(
            color: const Color(0xF20E0B12),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 0.5,
            ),
          ),
          child: RotatedBox(
            quarterTurns: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  open ? Icons.close : Icons.tune,
                  size: 13,
                  color: Colors.white60,
                ),
                const SizedBox(width: 4),
                Text(
                  open ? 'CLOSE' : 'OPEN',
                  style: ZyraText.subtext(size: 8.5, color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// − value + — the panel's control for every count. Hold to repeat.
class _CountRow extends StatefulWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _CountRow({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_CountRow> createState() => _CountRowState();
}

class _CountRowState extends State<_CountRow> {
  Timer? _repeat;

  void _step(int dir) {
    final next = widget.value + dir;
    if (next < 0 || next > widget.max) return;
    widget.onChanged(next);
  }

  void _startRepeat(int dir) {
    _repeat?.cancel();
    _repeat = Timer.periodic(const Duration(milliseconds: 140), (_) {
      final next = widget.value + dir;
      if (next < 0 || next > widget.max) {
        _stopRepeat();
        return;
      }
      widget.onChanged(next);
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  Widget _btn(String glyph, int dir, bool enabled) {
    return GestureDetector(
      onTap: enabled ? () => _step(dir) : null,
      onLongPressStart: enabled ? (_) => _startRepeat(dir) : null,
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          glyph,
          style: ZyraText.body(
            size: 15,
            color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.25),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          _btn('−', -1, widget.value > 0),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.value}',
                  style: ZyraText.body(size: 15, color: Colors.white),
                ),
                Text(
                  'of ${widget.max}',
                  style: ZyraText.subtext(size: 9, color: Colors.white38),
                ),
              ],
            ),
          ),
          _btn('+', 1, widget.value < widget.max),
        ],
      ),
    );
  }
}

/// − Faith & Values + — the stage picker.
///
/// A STEPPER, NOT AN EIGHT-WAY SEGMENT. The house rule since 2026-08-12 is
/// one interaction per kind of data: segments for two-way choices, the
/// − + row for everything with a range. Eight labels across 286pt would
/// each be three characters wide, and "Building a Life" would not fit at
/// all. Labels and count come from ZyraJourneyStages — the one map — so
/// a rename lands here without a second edit.
class _StageRow extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _StageRow({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final stages = ZyraJourneyStages.all;
    final i = index.clamp(0, stages.length - 1);
    final stage = stages[i];

    Widget btn(String glyph, int dir, bool enabled) => GestureDetector(
      onTap: enabled ? () => onChanged(i + dir) : null,
      child: Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          glyph,
          style: ZyraText.body(
            size: 15,
            color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.25),
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          btn('−', -1, i > 0),
          Expanded(
            child: Column(
              children: [
                Text(
                  stage.label,
                  textAlign: TextAlign.center,
                  style: ZyraText.body(size: 12.5, color: Colors.white),
                ),
                Text(
                  '${stage.order} of ${ZyraJourneyStages.count}',
                  style: ZyraText.subtext(size: 9, color: Colors.white38),
                ),
              ],
            ),
          ),
          btn('+', 1, i < stages.length - 1),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  const _Segment({
    required this.options,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: i == index
                        ? Colors.white.withValues(alpha: 0.20)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    options[i],
                    style: ZyraText.subtext(
                      size: 11.5,
                      color: Colors.white.withValues(
                        alpha: i == index ? 1 : 0.45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFE08080);
    return TextButton(
      onPressed: onTap,
      child: Text('Reset', style: ZyraText.subtext(size: 11.5, color: danger)),
    );
  }
}

/// A full-width button in the panel — used where the control is a door
/// rather than a value. Same glass as _StripAction's enabled state.
class _StripButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _StripButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: ZyraText.button(size: 12, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
