// THE CANONICAL JOURNEY STAGE MODEL — one definition, every surface.
//
// Agreed with the Founder 2026-08-09 after working the wording through
// from the machine outwards rather than from a copy deck inwards.
//
// ── WHY THIS FILE EXISTS. Before it, three screens each carried their own
// switch over the same eight strings, and they had already drifted:
//
//   wali_journey_detail_screen  'Phase 1 — Foundations'
//   wali_dashboard_screen       'Phase 1'
//   connections_screen          did not show stages at all — it said
//                               'In the Pre-Journey Ritual' for seven of
//                               the eight, which is not even true: the
//                               Ritual is what turns a POTENTIAL Journey
//                               into an Active one, and all eight of these
//                               stages run while status is already
//                               'active'.
//
// A fourth copy was about to be written for the Connections subtitle. That
// is invariant I3 — "one path, or the paths will drift" — and this project
// has paid for ignoring it twice already today, in four copies of an
// age-fetch and two copies of a comet animation.
//
// ═══════════════════════════════════════════════════════════════════════
// THE NAMING PHILOSOPHY. Read this before adding or renaming a stage.
// ═══════════════════════════════════════════════════════════════════════
//
//   EVERY LABEL NAMES THE SUBJECT OF THE COUPLE'S ATTENTION AT THAT
//   MOMENT.
//
// Not what the software is doing. Not what the stage is "for". What the
// two of them are actually thinking about. Revealing their compatibility ·
// the Salam · their Guardians · faith and values · building a life ·
// navigating life · the two families · each other, freely.
//
// ── AND THE STAGES ARE NOT ALL ONE KIND OF THING, which is why an earlier
// attempt to force them all into "topic" or all into "purpose" kept
// producing one label that felt wrong:
//
//   THRESHOLD    a mutual act both parties must complete. Nothing is
//                discussed; it is a door. zyra_advance_stage() moves
//                these directly.
//   SUSTAINED    a subject worked through over days or weeks, with a
//                question set behind it and a Family Review at the end.
//                zyra_advance_stage() REFUSES these with
//                'gated_transition' — they go through open_family_review.
//   DESTINATION  the end of the sequence.
//
// ── THE GRAMMAR IS LOAD-BEARING. Thresholds and the destination are noun
// phrases; the two longest sustained phases are gerunds — "Building a
// Life", "Navigating Life". That is deliberate. A threshold is something
// you COMPLETE; a phase is something you DO OVER TIME. Flattening all
// eight into tidy noun phrases would hide a distinction the user can feel.
// If you add a stage, match the grammar of its kind.
//
// ── ONE KNOWN EXCEPTION, recorded rather than hidden: "Guardian Gate"
// names a mechanism, not a subject. It is kept because it is already
// approved and already on two screens, and because "gate" is honest that
// the Journey stops there.
//
// ═══════════════════════════════════════════════════════════════════════
// EXTENDING THIS
// ═══════════════════════════════════════════════════════════════════════
//
// Founder, 2026-08-09: "if we ever need icons, colours, descriptions,
// helper text, progress indicators or localisation, I'd rather extend this
// one shared definition than create separate mappings."
//
// So: add a FIELD to [ZyraJourneyStage], never a second map somewhere
// else. [icon] and [description] are deliberately absent rather than
// stubbed — nobody has designed them, and a null field that every screen
// null-checks is worse than a field that does not exist yet.
//
// Localisation, when it comes: [label] becomes a key and the lookup moves
// behind a delegate. Having one map is the precondition for that being a
// half-day change instead of a hunt.

/// What kind of thing a stage is. See the philosophy note above — this is
/// not decoration, it decides the grammar of the label and whether
/// zyra_advance_stage() can move it directly.
enum ZyraStageKind { threshold, sustained, destination }

class ZyraJourneyStage {
  /// The value stored in `matches.journey_stage`. Authoritative — this
  /// list is the CHECK constraint on that column, in order.
  final String value;

  /// The user-facing label. Identical for Seeker and Guardian, on every
  /// screen, by design.
  final String label;

  final ZyraStageKind kind;

  /// 1-based position, for "step 4 of 8" style progress. Derived from the
  /// list order rather than hand-written, so it cannot fall out of step.
  final int order;

  /// The question the couple is answering during this stage, where one
  /// exists. Shown in the Journey flow above the question set.
  ///
  /// These three are not new copy — they were already on screen, in
  /// journey_flow_screen's `_phaseGuidingQuestion`, and the phase labels
  /// were derived FROM them. Moved here so the label and the question can
  /// never say different things.
  final String? guidingQuestion;

  const ZyraJourneyStage({
    required this.value,
    required this.label,
    required this.kind,
    required this.order,
    this.guidingQuestion,
  });
}

class ZyraJourneyStages {
  ZyraJourneyStages._();

  /// Shown INSTEAD of the stage whenever a Family Review is open.
  ///
  /// An override, not a stage — there is no `family_review` value in the
  /// database and there must not be. It is the gate between stages 4→5,
  /// 5→6, 6→7 and 7→8. A Journey is never "in" Family Review; it is in
  /// phase_2 with a review open.
  ///
  /// It wins because it is the only moment an Active Journey is stalled
  /// for a reason the Seeker cannot act on. "Building a Life" while two
  /// Guardians deliberate explains nothing about why nothing is moving.
  static const String familyReviewOverride = 'Family Review';

  /// In order. This IS the successor sequence — index n advances to
  /// index n+1, and `conversation` is terminal.
  static const List<ZyraJourneyStage> all = [
    ZyraJourneyStage(
      value: 'compatibility_reveal',
      label: 'Compatibility Reveal',
      kind: ZyraStageKind.threshold,
      order: 1,
    ),
    ZyraJourneyStage(
      value: 'salam_exchange',
      label: 'Salam Exchange',
      kind: ZyraStageKind.threshold,
      order: 2,
    ),
    ZyraJourneyStage(
      value: 'wali_gate',
      label: 'Guardian Gate',
      kind: ZyraStageKind.threshold,
      order: 3,
    ),
    ZyraJourneyStage(
      value: 'phase_1',
      label: 'Faith & Values',
      kind: ZyraStageKind.sustained,
      order: 4,
      guidingQuestion: 'Are we fundamentally compatible?',
    ),
    ZyraJourneyStage(
      value: 'phase_2',
      label: 'Building a Life',
      kind: ZyraStageKind.sustained,
      order: 5,
      guidingQuestion: 'Could we realistically build a life together?',
    ),
    ZyraJourneyStage(
      value: 'phase_3',
      label: 'Navigating Life',
      kind: ZyraStageKind.sustained,
      order: 6,
      guidingQuestion: 'Can we navigate life together?',
    ),
    ZyraJourneyStage(
      value: 'family_stage',
      label: 'Family Compatibility',
      kind: ZyraStageKind.sustained,
      order: 7,
    ),
    // "Open Conversation", not "Conversation" — Founder, 2026-08-09.
    //
    // Both are accurate: free messaging genuinely begins here and nowhere
    // earlier (ChatScreen has exactly one entry point in the app, gated on
    // this stage; the phases exchange structured answers, not messages).
    // But the Journey is conversational THROUGHOUT, so the bare word
    // implied talking starts here. "Open" names what actually changes:
    // the structure lifts.
    ZyraJourneyStage(
      value: 'conversation',
      label: 'Open Conversation',
      kind: ZyraStageKind.destination,
      order: 8,
    ),
  ];

  static final Map<String, ZyraJourneyStage> _byValue = {
    for (final s in all) s.value: s,
  };

  /// Total stages, for "step 4 of 8". Derived, never written down twice.
  static int get count => all.length;

  /// Null for an unknown or absent stage — a Potential Journey has no
  /// stage at all, so null is a legitimate answer, not an error.
  static ZyraJourneyStage? of(String? value) =>
      value == null ? null : _byValue[value];

  /// The `phase_N` stage for a 1-based phase number.
  ///
  /// journey_flow_screen carries the phase as an int — its three phase
  /// views are ONE widget parameterised by number, not three widgets — so
  /// it cannot call [of] directly. This is the bridge, and it lives here
  /// rather than there so the `phase_$n` naming convention sits with the
  /// values it names.
  static ZyraJourneyStage? phase(int n) => of('phase_$n');

  /// The label for a stage, with the Family Review override applied.
  ///
  /// [reviewOpen] must come from real data. Passing a hardcoded false is
  /// fine and honest — it simply never shows the override — but passing a
  /// guess is not, because this string is the only explanation the Seeker
  /// gets for why their Journey has stopped.
  ///
  /// [fallback] covers a stage the app does not recognise, which can only
  /// happen if the database gains a value this file has not been taught.
  static String labelFor(String? value, {bool reviewOpen = false,
      String fallback = 'Journey in progress'}) {
    if (reviewOpen) return familyReviewOverride;
    return of(value)?.label ?? fallback;
  }
}
