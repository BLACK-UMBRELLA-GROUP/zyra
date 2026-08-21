// Accepting a Guardian invitation you RECEIVED.
//
// ADDED 2026-08-07. Founder: "pressing accept should take me to a new page
// with last button on that page being confirm."
//
// A full page rather than a sheet, deliberately: agreeing to a Guardian is
// one of the few decisions in ZYRA that a family will treat as binding, and
// it deserves a screen rather than something that slides over the one behind
// it.
//
// WHOSE ANSWER IS THIS?
//
// The relationship is a statement about the GUARDIAN, so the Guardian makes
// it — ratified 2026-08-07. He already said "I am her father" when he
// created the invite, so his answer arrives PRE-SELECTED here.
//
// She is confirming, not authoring. But it is editable, because he can be
// wrong and she is the one who will live with the label. One tap in the
// normal case; a correction is possible without being invited.
//
// PREVIEW ONLY. `wali_invites` has no recipient, so there is no real
// invitation to accept — see ZyraDevScenario.fakeReceived. The layout is
// real so it can be judged; Confirm does not write anything yet.

import 'package:flutter/material.dart';
import '../../data/zyra_reference_data.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_fade_edges.dart';
import '../../theme/zyra_card_metrics.dart';

class AcceptGuardianInviteScreen extends StatefulWidget {
  final String from;

  /// The relationship code the inviting Guardian stated. Pre-selects.
  final String? theirAnswer;

  const AcceptGuardianInviteScreen({
    super.key,
    required this.from,
    this.theirAnswer,
  });

  @override
  State<AcceptGuardianInviteScreen> createState() => _AcceptGuardianInviteScreenState();
}

class _AcceptGuardianInviteScreenState extends State<AcceptGuardianInviteScreen> {
  String? _relationship;

  @override
  void initState() {
    super.initState();
    _relationship = widget.theirAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.white70)),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                // Same fade as the Guardian detail page. Content passing the
                // viewport edge dissolves rather than being cut, which is
                // what produced the "line" — most visibly on the monogram,
                // where a sliced circle reads as a horizontal rule.
                child: ZyraFadeEdges(
                  top: 34,
                  child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Center(child: _Monogram(letter: widget.from)),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(widget.from, style: ZyraText.heading(size: 26)),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'wants to be your Guardian',
                        style: ZyraText.subtext(size: 14.5, color: Colors.white70),
                      ),
                    ),

                    const SizedBox(height: 36),
                    // The wording the Founder settled on: it covers Imam and
                    // Legal Guardian, which "How are you related?" does not.
                    Text(
                      'What best describes their role in your marriage journey?',
                      style: ZyraText.body(size: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.theirAnswer == null
                          ? 'Choose one.'
                          : '${widget.from} chose this. Change it if it is not right.',
                      style: ZyraText.subtext(size: 12.5, color: Colors.white38),
                    ),
                    const SizedBox(height: 18),

                    // GROUPED CHIPS — the full proposed list, 2026-08-07.
                    //
                    // Grouping is what makes twenty-three values scannable
                    // where a flat wrap would be a wall. Five headings, and
                    // the eye lands on the right one before reading any
                    // chip.
                    //
                    // Values outside the live seven cannot be SAVED yet —
                    // the CHECK constraint on wali_links.relationship still
                    // allows seven. Harmless here because Confirm writes
                    // nothing, and the point of the screen is to judge the
                    // layout at full size.
                    for (final g in zyraGuardianRelationshipGroups) ...[
                      Text(
                        g.title.toUpperCase(),
                        style: ZyraText.chapterLabel(color: Colors.white54),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          for (final r in g.items)
                            _RelChip(
                              label: r.name,
                              selected: _relationship == r.code,
                              // Dimmed where the value cannot yet be stored,
                              // so the preview never pretends the enum is
                              // wider than it is.
                              preview: !zyraRelationshipIsLive(r.code),
                              onTap: () => setState(() => _relationship = r.code),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],

                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10), width: 0.5),
                      ),
                      child: Text(
                        'Once linked, ${widget.from} can follow your Journey and '
                        'read conversations within it. You can remove them at '
                        'any time.',
                        style: ZyraText.subtext(size: 12.5, color: Colors.white60),
                      ),
                    ),
                  ],
                ),
                ),
              ),

              // LAST on the page, as asked. Pinned rather than scrolled with
              // the content: the decision should be reachable without
              // hunting for it, and the list above may grow.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _relationship == null
                          ? ZyraColors.iconButtonBg
                          : ZyraColors.accentBg,
                      border: Border.all(
                        color: _relationship == null
                            ? ZyraColors.iconButtonBorder
                            : ZyraColors.accentBorder,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: _relationship == null
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Preview only — nothing linked. (dev)'),
                                  ),
                                );
                                Navigator.of(context).pop();
                              },
                        child: Center(
                          child: Text('Confirm', style: ZyraText.button()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelChip extends StatelessWidget {
  final String label;
  final bool selected;

  /// Not yet in the live enum — selectable here, unsavable in production.
  final bool preview;
  final VoidCallback onTap;
  const _RelChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ZyraColors.accentBg : ZyraColors.iconButtonBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? ZyraColors.accentBorder : ZyraColors.iconButtonBorder,
              width: selected ? 1 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: ZyraText.body(
              size: 14,
              color: Colors.white.withValues(
                  alpha: selected ? 1 : (preview ? 0.42 : 0.65)),
            ),
          ),
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
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 0.5),
      ),
      child: Center(
        child: Text(
          letter.isEmpty ? '?' : letter.characters.first.toUpperCase(),
          style: ZyraText.heading(size: 38),
        ),
      ),
    );
  }
}
