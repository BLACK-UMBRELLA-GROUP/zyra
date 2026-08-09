// One Guardian, in full. Reached by tapping their card on the Guardian tab.
//
// ADDED 2026-08-06. Founder: "The entire Guardian card should be tappable
// and open a dedicated Guardian profile or details page… The cards should
// feel like real people you manage, not just labels."
//
// BUILT ONLY ON DATA THAT EXISTS. Founder, same review: "Don't add empty
// sections or placeholders for future features. If data doesn't exist yet,
// don't design as though it does."
//
// So this page has no Verified row (no verification concept exists in
// ZYRA), no photo (Guardian onboarding never asks for one), no Permissions
// section (the Wali One capability model is documented but unbuilt), and no
// Remove Guardian (destructive, and removing a Main Guardian mid-Journey
// has consequences nothing currently handles — approved for a second pass).
//
// Each of those is a real product decision recorded in
// ZYRA_GUARDIAN_PAGE_REVIEW_CURRENT_VERSION_V1.md, not an oversight. If you
// are here to add one of them, read that first.

import 'package:flutter/material.dart';
import '../../services/zyra_report_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/report_profile_sheet.dart';
import '../../widgets/zyra_fade_edges.dart';
import '../connections/connections_screen.dart' show ZyraCardMetrics;

class GuardianDetailScreen extends StatefulWidget {
  final WaliLinkedPerson person;
  final List<GuardianActivity> activity;

  /// How many OTHER Guardians are linked. Decides two things: whether
  /// "Make Main Guardian" is offered at all, and whether removing this one
  /// is possible when they are Main.
  final int otherGuardianCount;

  /// Called after any change, so the tab behind can reload.
  final VoidCallback onChanged;

  const GuardianDetailScreen({
    super.key,
    required this.person,
    required this.activity,
    required this.otherGuardianCount,
    required this.onChanged,
  });

  @override
  State<GuardianDetailScreen> createState() => _GuardianDetailScreenState();
}

class _GuardianDetailScreenState extends State<GuardianDetailScreen> {
  bool _busy = false;

  /// The Remove row has been tapped once and is showing Confirm / Cancel.
  ///
  /// ADDED 2026-08-07 (Founder: "when I click remove guardian, show a
  /// confirm button and cancel on same card").
  ///
  /// In place rather than a dialog. A dialog takes over the screen and hides
  /// the person you are removing; confirming on the card keeps their name,
  /// their relationship and their timeline in view while you decide — which
  /// is the information the decision actually turns on.
  bool _confirmingRemove = false;

  WaliLinkedPerson get person => widget.person;
  List<GuardianActivity> get activity => widget.activity;

  /// When they became a Guardian. Derived from the activity feed rather
  /// than passed separately — `linked` is always present, because a link is
  /// what makes someone a Guardian in the first place.
  GuardianActivity? get _linked {
    for (final a in activity) {
      if (a.type == 'linked') return a;
    }
    return null;
  }

  /// Everything except the linking event, which is shown as a fact above
  /// rather than repeated as news.
  List<GuardianActivity> get _feed =>
      [for (final a in activity) if (a.type != 'linked') a];

  /// Dev Guardians have no server rows, so every action here would fail
  /// against a database that has never heard of them. Better to say so than
  /// to show a real error for a fake person.
  bool get _isDev => person.id.startsWith('dev-guardian-');

  void _devNotice() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview Guardian — sign in as a real account to try this. (dev)'),
        ),
      );

  // Report and Remove are INDEPENDENT (Founder, 2026-08-06). Reporting says
  // "this person broke the rules"; removing says "I no longer want them
  // linked". Someone may report an impersonated Guardian account and still
  // want the link kept while it is investigated, so reporting never unlinks
  // and never blocks.
  Future<void> _report() async {
    if (_isDev) return _devNotice();
    await showReportProfileSheet(
      context,
      profileId: person.id,
      firstName: person.firstName,
      source: ZyraReportSource.guardian,
    );
  }

  Future<void> _makeMain() async {
    if (_isDev) return _devNotice();
    final confirmed = await _confirm(
      title: 'Make ${person.firstName} your Main Guardian?',
      body: 'Your Main Guardian is the one asked to act on your Journey. '
          'Whoever holds it now becomes an Additional Guardian.',
      action: 'Make Main Guardian',
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final ok = await ZyraWaliLinkService.setMainGuardian(person.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.onChanged();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That didn't go through. Please try again.")),
      );
    }
  }

  /// Steps the Main Guardian down to Additional.
  ///
  /// Confirmed rather than immediate: it leaves the Seeker with no Main
  /// Guardian, and Family Review has nobody to ask until one is set. That is
  /// recoverable in two taps but should not happen by accident.
  Future<void> _makeAdditional() async {
    if (_isDev) return _devNotice();
    final confirmed = await _confirm(
      title: 'Make ${person.firstName} an Additional Guardian?',
      body: widget.otherGuardianCount == 0
          ? "You'll have no Main Guardian. ZYRA asks your Main Guardian to "
              'act on your Journey, so set one before your Journey needs a '
              'decision.'
          : "You'll have no Main Guardian until you choose another. Any of "
              'your other Guardians can take the role.',
      action: 'Make Additional',
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final ok = await ZyraWaliLinkService.clearMainGuardian(person.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.onChanged();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That didn't go through. Please try again.")),
      );
    }
  }

  /// First tap — arms the inline confirm. The refusal case still uses a
  /// dialog, because it is an explanation rather than a decision and there
  /// is nothing on the card for it to become.
  void _askRemove() {
    // NO DEV GUARD HERE, from 2026-08-07 (Founder: "when I click remove
    // guardian I want that error message removed").
    //
    // It used to refuse before showing anything, so on a panel Guardian the
    // confirm step could never be seen — the dev notice fired first. The
    // guard now sits on the ACTION rather than the question: the panel opens
    // for everyone, and only the final Confirm knows the difference.

    // Refused before asking, rather than after. Offering an action and then
    // rejecting it is worse than not offering it — the server enforces this
    // too, but the user should not have to hit the wall to learn the rule.
    if (person.isMain && widget.otherGuardianCount > 0) {
      _confirm(
        title: 'Choose a new Main Guardian first',
        body: '${person.firstName} is your Main Guardian. Make one of your '
            'other Guardians Main, then remove ${person.firstName}.',
        action: null,
      );
      return;
    }
    setState(() => _confirmingRemove = true);
  }

  /// Second tap — the actual removal. The dev guard lives here now, so the
  /// confirm step is reachable on a panel Guardian even though the removal
  /// itself cannot be.
  Future<void> _remove() async {
    if (_isDev) {
      setState(() => _confirmingRemove = false);
      return _devNotice();
    }
    setState(() => _busy = true);
    final error = await ZyraWaliLinkService.removeGuardian(person.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      widget.onChanged();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String? action,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F33),
        title: Text(title, style: ZyraText.heading(size: 17)),
        content: Text(body, style: ZyraText.subtext(size: 13.5, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              action == null ? 'OK' : 'Cancel',
              style: ZyraText.body(size: 14, color: Colors.white70),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                action,
                style: ZyraText.body(
                  size: 14,
                  color: destructive ? Colors.redAccent.shade100 : Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent AppBar over the gradient — without extendBody the
      // Scaffold's flat background shows through and cuts the gradient off
      // with a hard strip. Same fix notifications_screen got on 2026-07-27.
      extendBodyBehindAppBar: true,
      // Scaffold background must be transparent too. Without it the theme's
      // own surface colour shows through wherever the gradient Container
      // does not paint, which is what puts a pale band across the top.
      backgroundColor: Colors.transparent,
      // Transparency and the scrolled-under tint are handled globally by
      // `appBarTheme` in main.dart — see the note there. Only the icon
      // colour is set here.
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          // Top right, matching every other report entry point in the app.
          IconButton(
            onPressed: _busy ? null : _report,
            tooltip: 'Report ${person.firstName}',
            icon: Icon(
              Icons.flag_outlined,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      // NO GRADIENT HERE, 2026-08-06 (Founder: "can we still remove that
      // line when scrolling on that Wali page and make it seamless").
      //
      // main.dart already wraps EVERY screen in a gender-matched gradient
      // via MaterialApp's `builder:`. This screen painted a second, identical
      // one over the body. Two gradients drawn over boxes that do not start
      // at the same pixel produce a visible horizontal seam exactly where
      // the lower one begins — which is why the line sat precisely at the
      // bottom of the app bar, and why it looked like a scrolling artefact
      // when it was really a painting one.
      //
      // Removing the duplicate is the fix rather than nudging the geometry:
      // one gradient cannot seam against itself.
      // GRADIENT RESTORED — removing it made this page a different pink from
      // Connections, because the app-level fallback follows the CACHED
      // gender while every page paints its own from AppState.
      //
      // The lines at top and bottom were NOT the gradient. They are the
      // scroll edge: Material draws an overscroll indicator against an
      // opaque surface, which on a gradient reads as a hard rule appearing
      // and vanishing as you reach either end. ScrollConfiguration below
      // removes it, which is what makes the page feel like one surface.
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: ZyraFadeEdges(
            // Fades where content meets the viewport edge, so a monogram
            // scrolling under the app bar dissolves instead of being sliced
            // into a half-disc with a flat top — which is what the "line"
            // actually was.
            top: 34,
            child: ScrollConfiguration(
            behavior: const _SeamlessScroll(),
            child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 60),
            children: [
              Center(child: _Monogram(letter: person.firstName)),
              const SizedBox(height: 18),
              Center(child: Text(person.firstName, style: ZyraText.heading(size: 27))),
              // NO relationship line and NO chips here. Removed 2026-08-07
              // (Founder: "the screen repeats the same information —
              // Abdul / Brother / Active … Brother / Active").
              //
              // The DETAILS rows below carry Relationship, Role and Status
              // in full. Repeating two of them under the avatar said the
              // same thing twice within one screenful, which is the exact
              // duplication this pass removes. The name stands alone.

              const SizedBox(height: 32),
              Text('DETAILS', style: ZyraText.chapterLabel(color: Colors.white54)),
              const SizedBox(height: 12),
              _Row(
                label: 'Relationship',
                value: person.relationshipLabel ?? 'Not recorded',
                dim: person.relationshipLabel == null,
              ),
              _Row(
                label: 'Role',
                value: person.isMain ? 'Main Guardian' : 'Additional Guardian',
              ),
              // "Linked 3 March" is what a Verified chip was reaching for —
              // it makes the relationship feel established — with the
              // difference that every word of it is true.
              _Row(
                label: 'Linked',
                value: _linked == null ? 'Not recorded' : _linked!.whenLabel,
                dim: _linked == null,
              ),
              _Row(label: 'Status', value: 'Active'),

              const SizedBox(height: 30),
              Text('TIMELINE', style: ZyraText.chapterLabel(color: Colors.white54)),
              const SizedBox(height: 4),
              Text(
                person.isMain
                    ? 'What ${person.firstName} has done on your Journey.'
                    : 'What ${person.firstName} has done. Only your Main '
                        'Guardian is asked to act on your Journey.',
                style: ZyraText.subtext(size: 11.5, color: Colors.white38),
              ),
              const SizedBox(height: 14),
              if (_feed.isEmpty)
                // An honest nothing. Founder: "If there is no activity,
                // don't invent it." A Guardian who has only just linked has
                // genuinely done nothing yet, and saying so is better than
                // padding the page with a fabricated milestone.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
                  ),
                  child: Text(
                    'Nothing yet. This fills in as '
                    '${person.firstName} takes part in your Journey.',
                    style: ZyraText.subtext(size: 12.5, color: Colors.white38),
                  ),
                )
              else
                ..._feed.map((a) => _ActivityRow(activity: a)),

              // ── Manage ──────────────────────────────────────────────
              //
              // Last on the page, and deliberately. These are the only two
              // things that change a real relationship, and neither should
              // sit where a thumb lands while reading.
              const SizedBox(height: 34),
              Text('MANAGE', style: ZyraText.chapterLabel(color: Colors.white54)),
              const SizedBox(height: 12),

              // PROMOTE — offered to any Additional Guardian.
              //
              // The `otherGuardianCount > 0` condition was removed
              // 2026-08-07. It was wrong: a Seeker with ONE Guardian who is
              // not Main has nobody acting on their Journey, and that is
              // exactly when promoting matters most. The old test hid the
              // button in the case that needed it.
              if (!person.isMain) ...[
                _ActionRow(
                  icon: Icons.shield_outlined,
                  label: 'Make Main Guardian',
                  hint: 'They become the one asked to act on your Journey.',
                  onTap: _busy ? null : _makeMain,
                ),
                const SizedBox(height: 10),
              ],

              // DEMOTE — the counterpart, on the Main's own page.
              //
              // Founder, 2026-08-07: "with main guardian we need a button to
              // make additional guardian."
              //
              // Leaves nobody Main, which the Guardian tab handles and
              // prompts about. The warning below is the UI's job, not the
              // database's — no Main is a legitimate state, just an
              // unfinished one.
              if (person.isMain) ...[
                _ActionRow(
                  icon: Icons.shield_moon_outlined,
                  label: 'Make Additional Guardian',
                  hint: widget.otherGuardianCount == 0
                      ? "You'll have no Main Guardian until you set one."
                      : "You'll need to choose a new Main Guardian.",
                  onTap: _busy ? null : _makeAdditional,
                ),
                const SizedBox(height: 10),
              ],

              // Two states, same card. Tapping Remove turns the row into the
              // question rather than opening one somewhere else.
              if (!_confirmingRemove)
                _ActionRow(
                  icon: Icons.person_remove_outlined,
                  label: 'Remove Guardian',
                  hint: person.isMain && widget.otherGuardianCount > 0
                      ? 'Choose a new Main Guardian first.'
                      : 'They will no longer be linked to you.',
                  destructive: true,
                  onTap: _busy ? null : _askRemove,
                )
              else
                // EXPANDS TO FIT (Founder, 2026-08-07: "make it so the box
                // expands if needed").
                //
                // No fixed height anywhere: the Column sizes to its children,
                // the body text wraps to as many lines as the name and the
                // context need, and the buttons below grow with their labels
                // rather than truncating. A confirmation that clips the
                // sentence explaining what you are confirming is worse than
                // no confirmation.
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE08080).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
                    border: Border.all(
                        color: const Color(0xFFE08080).withValues(alpha: 0.34),
                        width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remove ${person.firstName}?',
                          style: ZyraText.body(
                              size: 15, color: const Color(0xFFE08080))),
                      const SizedBox(height: 4),
                      Text(
                        widget.otherGuardianCount == 0
                            ? "You'll have no Guardian until you add another. "
                                'You can invite them again at any time.'
                            : "They'll no longer follow your Journey. You can "
                                'invite them again at any time.',
                        style: ZyraText.subtext(size: 12, color: Colors.white54),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Cancel FIRST and to the left — the safe option
                          // sits where a thumb rests, and the destructive one
                          // takes a deliberate reach.
                          Expanded(
                            child: _SmallAction(
                              label: 'Cancel',
                              onTap: _busy
                                  ? null
                                  : () => setState(() => _confirmingRemove = false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SmallAction(
                              label: _busy ? 'Removing…' : 'Confirm',
                              destructive: true,
                              onTap: _busy ? null : _remove,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                ),

              // The reporting explainer that sat here is gone (Founder,
              // 2026-08-07: "if reporting behaviour needs explaining, it
              // belongs inside the reporting flow, not permanently on the
              // Guardian profile"). Correct — it is read once and then
              // becomes furniture on a page visited often.
            ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// Removes the overscroll indicator. Material paints it on an opaque
/// surface, so on a gradient it reads as a hard line appearing at the top
/// and bottom of the scroll — which is exactly what it was.
class _SeamlessScroll extends ScrollBehavior {
  const _SeamlessScroll();

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

/// A compact button for the inline confirm pair.
class _SmallAction extends StatelessWidget {
  final String label;
  final bool destructive;
  final VoidCallback? onTap;
  const _SmallAction({required this.label, required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? const Color(0xFFE08080) : Colors.white;
    return Material(
      color: destructive
          ? const Color(0xFFE08080).withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Container(
          // Horizontal padding as well as vertical, so a longer label like
          // "Removing…" grows the button instead of touching its border.
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: tint.withValues(alpha: destructive ? 0.40 : 0.18),
              width: destructive ? 1 : 0.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: ZyraText.body(
                size: 14,
                color: tint.withValues(alpha: onTap == null ? 0.4 : 1)),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool destructive;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? Colors.redAccent.shade100 : Colors.white;
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.11),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: tint.withValues(alpha: 0.85)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: ZyraText.body(size: 15, color: tint)),
                    const SizedBox(height: 2),
                    Text(hint, style: ZyraText.subtext(size: 11.5, color: Colors.white38)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final GuardianActivity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final line = activity.line;
    if (line == null) return const SizedBox.shrink();
    final outstanding = activity.isOutstanding;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A timeline rail — dot with a line running through it, so a
            // run of entries reads as a sequence rather than a stack of
            // unrelated rows.
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: outstanding ? 0.95 : 0.35),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 0.5,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line,
                      style: ZyraText.body(
                        size: 14,
                        color: Colors.white.withValues(alpha: outstanding ? 1 : 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.whenLabel,
                      style: ZyraText.subtext(size: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool dim;
  const _Row({required this.label, required this.value, this.dim = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ZyraText.subtext(size: 13, color: Colors.white54))),
          Text(
            value,
            style: ZyraText.body(
              size: 14,
              color: Colors.white.withValues(alpha: dim ? 0.35 : 0.95),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: strong ? 0.20 : 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: strong ? 0.30 : 0.14),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: ZyraText.subtext(
          size: 11.5,
          color: Colors.white.withValues(alpha: strong ? 1 : 0.65),
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  final String letter;
  const _Monogram({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 0.5),
      ),
      child: Center(
        child: Text(
          letter.isEmpty ? '?' : letter.characters.first.toUpperCase(),
          style: ZyraText.heading(size: 42),
        ),
      ),
    );
  }
}
