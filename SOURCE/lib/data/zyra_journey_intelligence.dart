// THE ZYRA INTELLIGENCE LAYER — ZYRA Insight · ZYRA Recommendation ·
// ZYRA Summary. Added 2026-08-11.
//
// APP/Premium/AI TIERING/TIERING_CURRENT_VERSION_V1.md, and the three rules
// from it that shape every line of this file:
//
//   1. NEVER CALL THIS "AI" ON SCREEN. "Users subscribe for better guidance,
//      not AI." The three brand names above are the only labels that reach a
//      member. There is no user-facing string in this file containing the
//      word AI, and there must not be one.
//
//   2. THE SCREEN MUST WORK WITHOUT IT. "Can this screen exist without AI at
//      all? If no → redesign it. A screen that feels broken without AI has
//      been designed wrong." So every entry point here returns NULL for ZYRA
//      Basic, and every caller renders nothing rather than a gap, a lock icon
//      or a blurred teaser.
//
//   3. ADDITIVE, NOT WITHHELD. "One screen, not two." ZYRA One puts a layer
//      on top of the same screen. Basic is not a degraded One.
//
// ═════════════════════════════════════════════════════════════════════════
// WHAT THIS IS HONESTLY MADE OF — read before extending it.
// ═════════════════════════════════════════════════════════════════════════
//
// THERE IS NO MODEL BEHIND THIS. No LLM is integrated anywhere in this
// codebase. What follows is deterministic: it reads the Seeker's own private
// ratings and the real compatibility figures, and states what they say.
//
// That is the SAME standing decision already taken for the question sets —
// data/journey_questions.dart stands in for "AI-generated adaptive questions"
// with a fixed curated bank, Founder decision 2026-07-25 — and it is recorded
// here in the same words rather than quietly repeated.
//
// It sits behind ZYRA One anyway, because that is where the real thing will
// sit, and because a first draft that shows the tier difference is the point
// of the draft. When a model does arrive, the CALLERS should not change: they
// ask this file a question and render what comes back.
//
// ⚠️ The honest caveat, stated once: some of what this returns is arithmetic
// on ratings the member typed themselves. It is a fair reflection, not an
// interpretation. Nothing here should be sold as more than that until there
// is something more behind it. See OA-ZYRA-193 (scoring method not ratified).

import 'journey_questions.dart';
import '../state/app_state.dart' show ZyraPlan;

enum ZyraIntelligenceKind { insight, recommendation, summary }

class ZyraIntelligence {
  final ZyraIntelligenceKind kind;

  /// The body copy. One or two sentences — this is a layer on a screen that
  /// already works, not an article.
  final String body;

  /// Adaptive follow-up prompts, where the stage has any. The spec's example
  /// is a real one: A says "I definitely want children", B says "I'm unsure"
  /// → follow-ups on that tension before moving on. Ours are triggered by the
  /// Seeker's own private rating rather than by reading both answers, which
  /// is the part that needs a model.
  final List<String> followUps;

  const ZyraIntelligence(this.kind, this.body, {this.followUps = const []});

  /// The ONLY user-facing name for this content.
  String get label => switch (kind) {
    ZyraIntelligenceKind.insight => 'ZYRA Insight',
    ZyraIntelligenceKind.recommendation => 'ZYRA Recommendation',
    ZyraIntelligenceKind.summary => 'ZYRA Summary',
  };
}

class ZyraJourneyIntelligence {
  ZyraJourneyIntelligence._();

  static bool availableTo(ZyraPlan plan) => plan == ZyraPlan.one;

  // ── Rating helpers. `ratings` is questionId -> 'reassured' |
  // 'discuss_further' | 'concerns', exactly as journey_phase_ratings stores
  // it, and exactly what the member tapped.

  static List<String> _topicsRated(
    Iterable<JourneyQuestion> questions,
    Map<String, String> ratings,
    String rating,
  ) {
    return [
      for (final q in questions)
        if (ratings[q.id] == rating) q.topic,
    ];
  }

  /// "a, b and c" — an Oxford-free list, because these appear mid-sentence.
  static String _list(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 1 · COMPATIBILITY REVEAL — ZYRA Insight
  // ═══════════════════════════════════════════════════════════════════════

  static ZyraIntelligence? compatibility({
    required ZyraPlan plan,
    required double score,
  }) {
    if (!availableTo(plan)) return null;

    final band = score >= 80
        ? 'You are starting from a lot of common ground.'
        : score >= 60
        ? 'There is real common ground here, and some genuine differences.'
        : 'Your score points to more differences to explore. It is a starting '
              'point, not a verdict.';

    return ZyraIntelligence(ZyraIntelligenceKind.insight, band);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 2 · AFTER A PHASE REVEAL — adaptive follow-ups from tension
  // ═══════════════════════════════════════════════════════════════════════

  static ZyraIntelligence? phaseFollowUps({
    required ZyraPlan plan,
    required List<JourneyQuestion> questions,
    required Map<String, String> ratings,
    required String otherName,
  }) {
    if (!availableTo(plan)) return null;

    final prompts = <String>[];
    for (final q in questions) {
      switch (ratings[q.id]) {
        case 'concerns':
          prompts.add(
            'On ${q.topic} — what would need to be true for that to '
            'sit more easily with you?',
          );
        case 'discuss_further':
          prompts.add(
            "On ${q.topic} — what does $otherName's answer make you "
            'want to ask next?',
          );
      }
    }
    if (prompts.isEmpty) return null;

    return ZyraIntelligence(
      ZyraIntelligenceKind.recommendation,
      prompts.length == 1
          ? 'One answer is worth going back to before you move on.'
          : '${prompts.length} answers are worth going back to before you move on.',
      // Three is the limit by choice: a list of nine reads as homework, and
      // nobody carries nine questions into a conversation.
      followUps: prompts.take(3).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 3 · PHASE CHECKPOINT — ZYRA Recommendation
  // ═══════════════════════════════════════════════════════════════════════

  static ZyraIntelligence? phaseCheckpoint({
    required ZyraPlan plan,
    required List<JourneyQuestion> questions,
    required Map<String, String> ratings,
  }) {
    if (!availableTo(plan)) return null;

    final concerns = _topicsRated(questions, ratings, 'concerns');
    final discuss = _topicsRated(questions, ratings, 'discuss_further');
    final reassured = _topicsRated(questions, ratings, 'reassured');

    if (concerns.isEmpty && discuss.isEmpty && reassured.isEmpty) {
      return const ZyraIntelligence(
        ZyraIntelligenceKind.recommendation,
        'You have not marked any answers yet. Marking them privately is what '
        'shapes what ZYRA suggests next — and nobody else ever sees it.',
      );
    }

    if (concerns.isNotEmpty) {
      return ZyraIntelligence(
        ZyraIntelligenceKind.recommendation,
        'Before you continue, it would be worth returning to '
        '${_list(concerns)}. Moving on does not close the subject, but this is '
        'the easiest moment to raise it.',
      );
    }

    if (discuss.isNotEmpty) {
      return ZyraIntelligence(
        ZyraIntelligenceKind.recommendation,
        'You flagged ${_list(discuss)} as worth exploring further. Continuing '
        'is reasonable — carry those with you rather than leaving them here.',
      );
    }

    return const ZyraIntelligence(
      ZyraIntelligenceKind.recommendation,
      'Nothing you marked needs revisiting. Continuing is the natural step.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 4 · END OF A PHASE — ZYRA Summary
  // ═══════════════════════════════════════════════════════════════════════

  static ZyraIntelligence? phaseSummary({
    required ZyraPlan plan,
    required String phaseLabel,
    required List<JourneyQuestion> questions,
    required Map<String, String> ratings,
    required String otherName,
  }) {
    if (!availableTo(plan)) return null;

    final reassured = _topicsRated(questions, ratings, 'reassured');
    final open = [
      ..._topicsRated(questions, ratings, 'concerns'),
      ..._topicsRated(questions, ratings, 'discuss_further'),
    ];
    if (reassured.isEmpty && open.isEmpty) return null;

    final parts = <String>[];
    if (reassured.isNotEmpty) {
      parts.add('$otherName\'s answers on ${_list(reassured)} reassured you');
    }
    if (open.isNotEmpty) {
      parts.add('${_list(open)} ${open.length == 1 ? "is" : "are"} still open');
    }

    return ZyraIntelligence(
      ZyraIntelligenceKind.summary,
      'Across $phaseLabel, ${parts.join(', and ')}.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 5 · FAMILY COMPATIBILITY — the Guardian's ZYRA Summary
  // ═══════════════════════════════════════════════════════════════════════
  //
  // ⚠️ SHOWN, NOT SENT. The Guardian app has no Journey screen to receive
  // this on (WALI_ARCHITECTURE §Guardian+ / "Guardian AI Summary"), so this
  // renders on the SEEKER's screen as what their Guardian would be given.
  // The copy says "would be shared" for that reason and must keep saying so
  // until the Guardian side exists — the alternative is telling someone their
  // family received something nobody sent.

  static ZyraIntelligence? guardianSummary({
    required ZyraPlan plan,
    required String otherName,
    required Map<String, String> ratings,
    required List<JourneyQuestion> questions,
  }) {
    if (!availableTo(plan)) return null;

    final reassured = _topicsRated(questions, ratings, 'reassured');
    final open = [
      ..._topicsRated(questions, ratings, 'concerns'),
      ..._topicsRated(questions, ratings, 'discuss_further'),
    ];

    final body = StringBuffer(
      'This is the summary your Guardian would be given: ',
    );
    if (reassured.isNotEmpty) {
      body.write(
        'you and $otherName appear well aligned on ${_list(reassured)}. ',
      );
    } else {
      body.write(
        'you and $otherName have worked through the phases together. ',
      );
    }
    if (open.isNotEmpty) {
      body.write('${_list(open)} may benefit from an early conversation.');
    } else {
      body.write('Nothing was left flagged as unresolved.');
    }
    // Never names who rated what — "AI speaks in general terms, it never
    // reveals who rated what or how" (PRE-JOURNEY RITUAL/Summary.md). The
    // ratings read here are the SIGNED-IN Seeker's own, so this is their
    // reflection being passed to their own Guardian, not the other party's.
    return ZyraIntelligence(ZyraIntelligenceKind.summary, body.toString());
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 6 · OPEN CONVERSATION — topic suggestions
  // ═══════════════════════════════════════════════════════════════════════

  static ZyraIntelligence? conversationTopics({
    required ZyraPlan plan,
    required Map<String, String> ratings,
    required String otherName,
  }) {
    if (!availableTo(plan)) return null;

    // Every phase, because Open Conversation is where the whole Journey is
    // finally allowed to be one conversation rather than three.
    final all = [
      ...JourneyQuestions.phase1,
      ...JourneyQuestions.phase2,
      ...JourneyQuestions.phase3,
    ];
    final open = [
      ..._topicsRated(all, ratings, 'concerns'),
      ..._topicsRated(all, ratings, 'discuss_further'),
    ];
    if (open.isEmpty) return null;

    return ZyraIntelligence(
      ZyraIntelligenceKind.recommendation,
      'The structure has lifted, but these were left open along the way.',
      followUps: [
        for (final t in open.take(3))
          'Talk to $otherName about $t — you marked it as worth returning to.',
      ],
    );
  }
}
