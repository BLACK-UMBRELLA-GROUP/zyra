// Seeker's "Guardian" bottom-nav tab — per APP/Navigation/SEEKER
// NAVIGATION/Summary.md's ratified 4-tab structure (Browse / Connections /
// Wali / Profile).
//
// REBUILT 2026-08-06 as a FAMILY MANAGEMENT page. Founder review:
//
//   "The page currently shows who the Guardians are, but never makes them
//    feel involved. That is the biggest weakness… it should feel less like
//    a contacts page and more like a Family Management page."
//
// The diagnosis that drove this rebuild: every item on the old page was an
// ATTRIBUTE — name, relationship, Main. Attributes are what a contacts app
// stores. What makes a person feel present is evidence of them ACTING, so
// the largest change here is not a badge, it is the activity line on each
// card and the state strip at the top.
//
// WHAT IS DELIBERATELY ABSENT:
//   Verified      — no verification concept exists in ZYRA. A chip claiming
//                   otherwise would be read by families as an assurance we
//                   never made. Founder approved removing it outright.
//   Photos        — Guardian onboarding never asks for one (5 Guardian
//                   profiles, 0 photos). A designed monogram reads as
//                   intentional; a grey silhouette reads as broken.
//   Permissions   — the Wali One capability model is documented, unbuilt.
//   Remove        — destructive, and removing a Main Guardian mid-Journey
//                   has consequences nothing handles yet. Second pass.
//
// Founder: "Don't add empty sections or placeholders for future features.
// If data doesn't exist yet, don't design as though it does."

import 'package:flutter/material.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../connections/connections_screen.dart' show ZyraCardMetrics;
import 'accept_guardian_invite_screen.dart';
import 'guardian_detail_screen.dart';
import 'link_guardian_panel.dart';
import '../../widgets/zyra_loading.dart';

class SeekerWaliTab extends StatefulWidget {
  const SeekerWaliTab({super.key});

  @override
  State<SeekerWaliTab> createState() => _SeekerWaliTabState();
}

class _SeekerWaliTabState extends State<SeekerWaliTab> {
  bool _loading = true;
  List<WaliLinkedPerson> _linked = [];
  Map<String, List<GuardianActivity>> _activity = const {};
  List<PendingInvite> _pending = const [];

  @override
  void initState() {
    super.initState();
    ZyraDevScenario.instance.addListener(_onScenarioChange);
    _load();
  }

  @override
  void dispose() {
    ZyraDevScenario.instance.removeListener(_onScenarioChange);
    super.dispose();
  }

  void _onScenarioChange() {
    if (mounted) setState(() {});
  }

  /// Fake Guardians from the dev panel, or the real linked list.
  ///
  /// Index 0 is Main. Exactly one, matching `wali_links.is_main`.
  List<WaliLinkedPerson> get _people {
    final dev = ZyraDevScenario.instance;
    // Once the panel is driving this page it drives ALL of it, including the
    // zeroes — otherwise "0 Guardians" silently means "show me the real
    // ones", which is the same bug the pending count had.
    if (!dev.guardianOverride) return _linked;
    final n = dev.guardianCount;
    if (n == 0) return const [];

    // Index 0 is Main when there is one. Where the panel asks for
    // Additional WITHOUT a Main, the list starts at index 1 and nobody
    // carries is_main — a state the database can genuinely reach if a Main
    // Guardian is removed, and one the page should not silently invent a
    // Main to cover up.
    final start = dev.mainGuardian ? 0 : 1;
    return [
      for (var i = start;
          i < start + n && i < ZyraDevScenario.fakeGuardians.length;
          i++)
        WaliLinkedPerson(
          id: 'dev-guardian-$i',
          firstName: ZyraDevScenario.fakeGuardians[i].name,
          relationship: ZyraDevScenario.fakeGuardians[i].relationship,
          isMain: dev.mainGuardian && i == 0,
        ),
    ];
  }

  /// Real pending invites, or the dev panel's.
  List<PendingInvite> get _pendingInvites {
    final dev = ZyraDevScenario.instance;
    // FIXED 2026-08-07 (Founder: "0 pending → show 0. There appears to be a
    // counting bug").
    //
    // The test was `pendingInviteCount > 0`, so selecting 0 did not mean
    // "none" — it meant "stop overriding", and the page fell back to the
    // REAL pending invites underneath. With two seeded invites in the
    // database, choosing 0 showed 2.
    //
    // Zero is a value, not an absence. Once ANY Guardian toggle is driving
    // this page, the panel drives all of it, including the zeroes.
    if (dev.guardianOverride) {
      return ZyraDevScenario.fakePending(dev.pendingInviteCount);
    }
    return _pending;
  }

  /// Dev Guardians get dev activity, or the panel would show a working
  /// feature looking broken — the same trap the relationship fixtures set
  /// earlier today, when the only place a relationship ever appeared was a
  /// hardcoded fake.
  List<GuardianActivity> _activityFor(WaliLinkedPerson p) {
    if (ZyraDevScenario.instance.guardianOverride) {
      return ZyraDevScenario.fakeActivityFor(p.id);
    }
    return _activity[p.id] ?? const [];
  }

  Future<void> _load() async {
    final linked = await ZyraWaliLinkService.fetchLinkedPeople(asWali: false);
    final activity = await ZyraWaliLinkService.fetchActivity();
    final pending = await ZyraWaliLinkService.fetchPendingInvites();
    if (!mounted) return;
    setState(() {
      _linked = linked;
      _activity = activity;
      _pending = pending;
      _loading = false;
    });
  }

  void _openDetail(WaliLinkedPerson person) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GuardianDetailScreen(
        person: person,
        activity: _activityFor(person),
        otherGuardianCount: _people.length - 1,
        onChanged: _load,
      ),
    ));
  }

  void _openAdd() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LinkGuardianScreen(
        onLinked: _load,
        gender: AppState.instance.gender,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final people = _people;
    final showSpinner = _loading && !ZyraDevScenario.instance.guardianOverride;

    // GRADIENT RESTORED 2026-08-06. Removing it was the wrong fix and it
    // showed immediately: the app-level gradient in main.dart follows the
    // CACHED gender, while every tab paints its own from
    // AppState.instance.gender. Dropping this one left the Guardian tab a
    // different pink from Connections, which is the page that is correct.
    //
    // So this now does exactly what connections_screen.dart does, because
    // matching the page that looks right is more reliable than reasoning
    // about which of two gradients should win.
    return Container(
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
      child: SafeArea(
        child: showSpinner
            ? const ZyraLoading()
            // NO RefreshIndicator. It was added with the rebuild and it is
            // what drew the pale band across the top of this page when you
            // scrolled back up (Founder, 2026-08-06: "it creates that pink
            // line at top, remove that so it's all seamless").
            //
            // Its arc renders on its own opaque surface, which cannot sit
            // invisibly on a gradient — there is no single colour behind it
            // to match. Nothing here needs pull-to-refresh either: the page
            // reloads on open and after any linking action, so the gesture
            // was costing a visible seam to duplicate something that had
            // already happened.
            //
            // BouncingScrollPhysics keeps the overscroll feel without the
            // indicator, so the page still gives when you pull it.
            : ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children:
                    people.isEmpty ? _emptyChildren() : _populatedChildren(people),
              ),
      ),
    );
  }

  // ── Empty ────────────────────────────────────────────────────────────
  //
  // Founder: "If a user has no Guardians, don't leave the page feeling
  // empty. Show a proper empty state explaining why Guardians matter, with
  // a prominent centred + button."
  //
  // The invite controls stay inline here rather than behind the +, because
  // with nothing else on the screen, hiding the only available action
  // behind a tap would be perverse.
  // ── Empty ────────────────────────────────────────────────────────────
  //
  // SIMPLIFIED 2026-08-07. Three things went, all for the same reason.
  //
  // THE EXPLANATORY PARAGRAPH (Founder: "this is onboarding copy — once
  // someone is on the Guardian page they already understand what Guardians
  // are"). It was added on 2026-08-06 to give the page purpose. It reads
  // well once and becomes furniture on every visit after.
  //
  // THE 'Add your first Guardian' CAPTION and the inline LinkGuardianPanel
  // (Founder: "this duplicates the same action — keep the large centred +").
  // Three routes to one destination on a page with nothing else on it. The
  // + opens the same screen the panel offered, with both options on it.
  //
  // The earlier note here argued the invite controls had to be inline
  // because "hiding the only available action behind a tap would be
  // perverse". That was right when the + did not exist. It does now.
  List<Widget> _emptyChildren() => [
        const SizedBox(height: 8),
        Text('Guardians', style: ZyraText.heading(size: 26)),
        if (ZyraDevScenario.instance.receivedInviteCount > 0) ...[
          const SizedBox(height: 24),
          ..._receivedSection(),
        ],
        const SizedBox(height: 40),
        Center(child: _AddGuardianButton(onTap: _openAdd, large: true)),
        // RESTORED 2026-08-07 on an EMPTY page only. It was removed with the
        // duplicate "Add Guardian" action, and on a populated page that was
        // right — the + sits under a list of Guardians, so what it adds is
        // obvious from context.
        //
        // On an empty page there is no context. A bare circle on a blank
        // screen is a puzzle, not an invitation.
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Add a Guardian',
            style: ZyraText.body(size: 15, color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
        if (_pendingInvites.isNotEmpty) ...[
          const SizedBox(height: 44),
          ..._pendingSection(),
        ],
      ];

  // ── Populated ────────────────────────────────────────────────────────
  List<Widget> _populatedChildren(List<WaliLinkedPerson> people) {
    // FIXED 2026-08-06 (Founder: "additional guardians toggle — if I select
    // 1 it's 0, if 2 it's 1").
    //
    // This was `people.first` and `people.skip(1)`, splitting by POSITION.
    // fetchLinkedPeople sorts Main first, so that read correctly right up
    // until a Seeker had no Main at all — then the first ADDITIONAL Guardian
    // was rendered in the Main slot and the Additional list lost one, which
    // is exactly the off-by-one reported.
    //
    // Position was never the question. `is_main` is, and the code two
    // methods up already says the page must not invent a Main to cover the
    // gap — then this one did.
    WaliLinkedPerson? found;
    final additional = <WaliLinkedPerson>[];
    for (final p in people) {
      if (p.isMain && found == null) {
        found = p;
      } else {
        additional.add(p);
      }
    }
    // FINAL, deliberately. Dart does not carry a null-promotion on a
    // MUTABLE local into a closure, so `onTap: () => _openDetail(main)`
    // below would still see a nullable and fail to compile. Copying to a
    // final is what makes the promotion hold inside the callbacks.
    final WaliLinkedPerson? main = found;

    return [
      const SizedBox(height: 4),
      Text('Guardians', style: ZyraText.heading(size: 26)),
      const SizedBox(height: 20),

      // Founder point 9. The smallest change with the largest effect on the
      // actual complaint: a contacts list has no state, a management surface
      // tells you the state of the thing you manage before you read
      // anything else. Needs no schema — all three numbers are already here.
      // SUMMARY STRIP REMOVED 2026-08-07 (Founder: "it doesn't provide
      // enough value to justify occupying the most prominent space on the
      // page. The Guardians themselves should become the focus").
      //
      // It was added on 2026-08-06 to give the page a sense of state, and it
      // did — but the state it reported is legible from the page itself in
      // one glance, so it was spending the best position on a restatement.

      // FIRST, above the Guardians themselves. An invitation waiting on you
      // is the only thing on this page that is someone else's move, and
      // outstanding action outranks state (Badge Standard).
      //
      // FIXED 2026-08-07: this was only ever rendered in the EMPTY branch.
      // The insertion into this one silently missed its anchor, so the
      // section vanished the moment a single Guardian existed — which is
      // exactly the wrong way round, since a Seeker with Guardians is more
      // likely to be sent another invitation, not less.
      ..._receivedSection(),

      if (main != null) ...[
        Text('MAIN GUARDIAN', style: ZyraText.chapterLabel(color: Colors.white)),
        const SizedBox(height: 10),
        _GuardianCard(
          person: main,
          main: true,
          activity: _activityFor(main),
          onTap: () => _openDetail(main),
        ),
      ] else ...[
        // A real state, not an error: Guardians linked, none designated
        // Main. Said out loud rather than papered over by promoting
        // whoever happens to be first, because Family Review needs a Main
        // and the Seeker is the one who has to choose.
        Text('NO MAIN GUARDIAN', style: ZyraText.chapterLabel(color: Colors.white)),
        const SizedBox(height: 6),
        // SIMPLIFIED 2026-08-07. The original explained the concept, the
        // route and the consequence in one paragraph — three jobs for a line
        // that only needs to say what to do next.
        Text(
          'Choose one of your Guardians below.',
          style: ZyraText.subtext(size: 12.5, color: Colors.white60),
        ),
      ],

      if (additional.isNotEmpty) ...[
        const SizedBox(height: 26),
        Text('ADDITIONAL GUARDIANS', style: ZyraText.chapterLabel(color: Colors.white54)),
        const SizedBox(height: 12),
        ...additional.map((p) => _GuardianCard(
              person: p,
              main: false,
              activity: _activityFor(p),
              onTap: () => _openDetail(p),
            )),
      ],

      if (_pendingInvites.isNotEmpty) ...[
        const SizedBox(height: 26),
        ..._pendingSection(),
      ],

      // Founder point 3: "I don't want a text button underneath. Instead a
      // centred circular + beneath the final Guardian card." The flow reads
      // Main → Additional → Additional → +, so the control sits where the
      // next Guardian would go and invites rather than instructs.
      const SizedBox(height: 30),
      Center(child: _AddGuardianButton(onTap: _openAdd)),
    ];
  }

  // Founder point 7: pending invitations get their own section rather than
  // being mixed with active Guardians.
  //
  // The label is the SENDER'S private note. There is no recipient identity
  // on an invite — the flow is "generate a code, share it however you
  // like" — so without a label there is genuinely nothing to show but the
  // code, and a list of codes does not feel like a network.
  /// Invitations sent TO you, awaiting your answer.
  ///
  /// PREVIEW ONLY (2026-08-07). It sits ABOVE everything else because an
  /// invitation waiting on you is the only thing on this page that is
  /// someone else's move — Badge Standard reasoning: outstanding action
  /// outranks state.
  ///
  /// It cannot be real yet. `wali_invites` has no recipient — the flow is
  /// "generate a code, share it however you like" — so nobody knows an
  /// invite is for you until you type the code in. There is nothing to
  /// list. See ZyraDevScenario.fakeReceived.
  List<Widget> _receivedSection() {
    final items = ZyraDevScenario.fakeReceived(
        ZyraDevScenario.instance.receivedInviteCount);
    if (items.isEmpty) return const [];
    return [
      Text('INVITATIONS RECEIVED', style: ZyraText.chapterLabel(color: Colors.white)),
      const SizedBox(height: 10),
      ...items.map((i) => _ReceivedInviteCard(
            from: i.from,
            relationshipCode: i.relationship,
            daysAgo: i.daysAgo,
          )),
      const SizedBox(height: 26),
    ];
  }

  List<Widget> _pendingSection() => [
        Text('PENDING INVITATIONS', style: ZyraText.chapterLabel(color: Colors.white54)),
        const SizedBox(height: 12),
        ..._pendingInvites.map((i) => _PendingInviteCard(
              invite: i,
              onCancel: () => _cancelInvite(i),
            )),
      ];

  /// Confirm, then revoke. Cheap to undo — generating another code takes one
  /// tap — but it is still someone's expectation being withdrawn, and a
  /// destructive action with no confirmation is how people lose things they
  /// meant to keep.
  Future<void> _cancelInvite(PendingInvite invite) async {
    final name = invite.label ?? 'this invite';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F33),
        title: Text('Cancel invitation?', style: ZyraText.heading(size: 17)),
        content: Text(
          invite.label == null
              ? 'The code ${invite.token} will stop working. You can always '
                  'generate a new one.'
              : 'The code you sent for $name will stop working. You can '
                  'always generate a new one.',
          style: ZyraText.subtext(size: 13.5, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep it', style: ZyraText.body(size: 14, color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cancel invitation',
              style: ZyraText.body(size: 14, color: Colors.redAccent.shade100),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Dev invites are not real rows — there is nothing to revoke, so the
    // panel just drops one rather than calling a server that has never
    // heard of them.
    if (ZyraDevScenario.instance.pendingInviteCount > 0) {
      ZyraDevScenario.instance.set_(() =>
          ZyraDevScenario.instance.pendingInviteCount -= 1);
      return;
    }

    final ok = await ZyraWaliLinkService.revokeInvite(invite.token);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That didn't go through. Try again.")),
      );
    }
  }
}

// ── Summary strip ──────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int main;
  final int additional;
  final int pending;
  const _SummaryStrip({required this.main, required this.additional, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Row(
        children: [
          _stat('$main', 'Main'),
          _divider(),
          _stat('$additional', 'Additional'),
          _divider(),
          // Pending is dimmed at zero rather than hidden: a strip that
          // changes shape is harder to read at a glance than one that
          // always says the same three things.
          _stat('$pending', 'Pending', dim: pending == 0),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, {bool dim = false}) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: ZyraText.heading(size: 20).copyWith(
                color: Colors.white.withValues(alpha: dim ? 0.35 : 1),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: ZyraText.subtext(
                size: 11,
                color: Colors.white.withValues(alpha: dim ? 0.3 : 0.6),
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 0.5,
        height: 26,
        color: Colors.white.withValues(alpha: 0.14),
      );
}

// ── Guardian card ──────────────────────────────────────────────────────
//
// Founder point 7 (cards): "They currently feel like rows. I'd like each
// Guardian to feel like a person with presence." Founder point 9: "The Main
// Guardian should naturally become the visual anchor of the page."
//
// This deliberately departs from ZyraCardMetrics, which the Guardian cards
// were standardised onto on 2026-08-05. That standard exists so cards in a
// MIXED list do not fight each other — Connections, where a Journey card
// and a suggestion card sit side by side. This page is a single list of one
// kind of thing, and its whole purpose is that one of them outranks the
// others. Radius and spacing still come from the standard; only the
// vertical generosity and the avatar differ, and only for Main.
class _GuardianCard extends StatelessWidget {
  final WaliLinkedPerson person;
  final bool main;
  final List<GuardianActivity> activity;
  final VoidCallback onTap;

  const _GuardianCard({
    required this.person,
    required this.main,
    required this.activity,
    required this.onTap,
  });

  /// The most recent thing they did — or the thing still owed, which
  /// outranks it. A Guardian you are waiting on is the most useful thing
  /// the card can tell you, even if something newer happened since.
  GuardianActivity? get _headline {
    if (activity.isEmpty) return null;
    for (final a in activity) {
      if (a.isOutstanding) return a;
    }
    return activity.first;
  }

  @override
  Widget build(BuildContext context) {
    final avatar = main ? 62.0 : 48.0;
    final head = _headline;

    return Padding(
      padding: EdgeInsets.only(bottom: main ? 0 : ZyraCardMetrics.spacing),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(main ? 18 : 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: main ? 0.16 : 0.07),
              borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: main ? 0.30 : 0.13),
                width: main ? 1 : 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Monogram(letter: person.firstName, size: avatar, main: main),
                SizedBox(width: main ? 16 : 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.firstName,
                        style: ZyraText.heading(size: main ? 20 : 16),
                      ),
                      // relationshipLabel, not relationship: the field holds
                      // a code ('uncle') and the reader needs "Paternal
                      // Uncle".
                      if (person.relationshipLabel != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          person.relationshipLabel!,
                          style: ZyraText.subtext(
                            size: main ? 13 : 12,
                            color: Colors.white.withValues(alpha: main ? 0.75 : 0.55),
                          ),
                        ),
                      ],
                      // STATUS LINE REMOVED 2026-08-07 (Founder: "remove the
                      // status text completely… the page should feel like a
                      // list of trusted family members, not a status
                      // dashboard").
                      //
                      // It was added on 2026-08-06 to make Guardians feel
                      // present, and it did — but presence and monitoring
                      // read the same on a card. The activity still exists
                      // in full on the Timeline of each Guardian's detail
                      // page, which is where history belongs.
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // NO 'Main Guardian' CHIP. Removed 2026-08-07 — the
                    // section heading directly above already says MAIN
                    // GUARDIAN, and a card repeating its own heading is the
                    // clearest case of the duplication this pass removes.
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The initial, treated as a deliberate choice rather than a missing photo.
///
/// Guardian onboarding has never asked for a photo, so every Guardian would
/// render a placeholder. A soft gradient disc with a well-set letter reads
/// as designed; a grey silhouette reads as a failed image load.
class _Monogram extends StatelessWidget {
  final String letter;
  final double size;
  final bool main;
  const _Monogram({required this.letter, required this.size, required this.main});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: main ? 0.28 : 0.16),
            Colors.white.withValues(alpha: main ? 0.10 : 0.06),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: main ? 0.30 : 0.16),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          letter.isEmpty ? '?' : letter.characters.first.toUpperCase(),
          style: ZyraText.heading(size: size * 0.40),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool strong;
  const _Chip({required this.label, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: strong ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: strong ? 0.28 : 0.14),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: ZyraText.subtext(
          size: 10.5,
          color: Colors.white.withValues(alpha: strong ? 1 : 0.65),
        ),
      ),
    );
  }
}

// ── Pending invitation ─────────────────────────────────────────────────
class _PendingInviteCard extends StatelessWidget {
  final PendingInvite invite;
  final VoidCallback onCancel;
  const _PendingInviteCard({required this.invite, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final days = invite.daysLeft;
    final title = invite.label ?? 'Invite ${invite.token}';

    return Padding(
      padding: const EdgeInsets.only(bottom: ZyraCardMetrics.spacing),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
        ),
        child: Row(
          children: [
            // Hollow, because nobody is in it yet.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.hourglass_empty,
                size: 18,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ZyraText.body(size: 15, color: Colors.white70)),
                  const SizedBox(height: 3),
                  Text(
                    days == null
                        ? 'Waiting for acceptance'
                        : days == 0
                            ? 'Expires today'
                            : 'Waiting · expires in $days ${days == 1 ? "day" : "days"}',
                    style: ZyraText.subtext(size: 11.5, color: Colors.white38),
                  ),
                ],
              ),
            ),
            const _Chip(label: 'Pending'),
            const SizedBox(width: 4),
            // Cancel lives on the card rather than behind a tap-through:
            // a pending invite has no detail page worth opening, and the
            // only thing you can do with one is withdraw it.
            IconButton(
              onPressed: onCancel,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              tooltip: 'Cancel invitation',
              icon: Icon(
                Icons.close,
                size: 17,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add button ─────────────────────────────────────────────────────────
//
// Founder point 3. A circle, centred, sitting where the next Guardian would
// go — so the page reads Main → Additional → Additional → +, and the
// control invites rather than instructs.
class _AddGuardianButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool large;
  const _AddGuardianButton({required this.onTap, this.large = false});

  @override
  Widget build(BuildContext context) {
    final d = large ? 74.0 : 56.0;
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1),
          ),
          child: Icon(Icons.add, size: large ? 34 : 26, color: Colors.white),
        ),
      ),
    );
  }
}

/// An invitation waiting on YOU. Accept or Decline, nothing else — a
/// received invite has no detail worth opening.
class _ReceivedInviteCard extends StatelessWidget {
  final String from;

  /// The stored CODE the inviting Guardian chose, passed through to
  /// pre-select on the acceptance screen. Not rendered on the card.
  final String? relationshipCode;
  final int daysAgo;
  const _ReceivedInviteCard({
    required this.from,
    required this.relationshipCode,
    required this.daysAgo,
  });

  String get _when => daysAgo == 0
      ? 'today'
      : daysAgo == 1
          ? 'yesterday'
          : '$daysAgo days ago';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ZyraCardMetrics.spacing),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Brighter than a Guardian card: this one is waiting on you.
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.26), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.26),
                        Colors.white.withValues(alpha: 0.10),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(from.characters.first.toUpperCase(),
                        style: ZyraText.heading(size: 18)),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(from, style: ZyraText.heading(size: 17)),
                      const SizedBox(height: 3),
                      // REMOVED 2026-08-07: "says they are your Father".
                      //
                      // It was accurate but it put a claim on the card before
                      // she had engaged with it, which made the card argue a
                      // point rather than present a decision. His answer now
                      // appears on the acceptance screen, pre-selected, where
                      // it is something she confirms rather than something
                      // asserted at her.
                      Text(
                        'wants to be your Guardian',
                        style: ZyraText.subtext(size: 12.5, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text('Invited $_when',
                          style: ZyraText.subtext(size: 11, color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InviteAction(
                    label: 'Decline',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preview only. (dev)')),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InviteAction(
                    label: 'Accept',
                    primary: true,
                    // A full page, not a sheet — agreeing to a Guardian is
                    // treated as binding by families and deserves a screen.
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AcceptGuardianInviteScreen(
                        from: from,
                        theirAnswer: relationshipCode,
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteAction extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _InviteAction({required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? ZyraColors.accentBg : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: primary
                  ? ZyraColors.accentBorder
                  : Colors.white.withValues(alpha: 0.16),
              width: primary ? 1 : 0.5,
            ),
          ),
          child: Text(label,
              style: ZyraText.body(
                  size: 14,
                  color: Colors.white.withValues(alpha: primary ? 1 : 0.75))),
        ),
      ),
    );
  }
}
