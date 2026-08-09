// Fixed-order question bank for the Pre-Journey Ritual's three
// sustained phases and the Family Compatibility stage, per
// APP/Journey/PRE-JOURNEY RITUAL/Summary.md.
//
// NAMING, 2026-08-09: `phase1/2/3` here are STORAGE names and match
// matches.journey_stage's phase_1/phase_2/phase_3. What the member
// reads is Faith & Values, Building a Life and Navigating Life, and
// that lives in exactly one place — data/zyra_journey_stages.dart.
// Do not put a user-facing label in this file.
//
// DELIBERATE V1 SIMPLIFICATION (Founder decision, 2026-07-25): the
// spec calls for "Part A — AI-generated questions (adaptive)" that
// react to answer tensions and private ratings in real time. There is
// no LLM integration anywhere in this codebase, so this file stands
// in with a fixed, curated, hand-written question set per phase
// instead. Real AI-adaptive question selection (and Part B's
// searchable personal question library) is future work — out of
// scope for this pass.

class JourneyQuestion {
  final String id; // stable string id, e.g. 'p1_q1'
  final String text;
  const JourneyQuestion({required this.id, required this.text});
}

class JourneyQuestions {
  JourneyQuestions._();

  // phase_1, shown as "Faith & Values". Guiding question: "Are we
  // fundamentally compatible?" — the question itself now lives on
  // ZyraJourneyStage.guidingQuestion; this is a pointer, not a copy.
  // Topics: practising Islam, marriage intentions, core
  // values, non-negotiables, daily lifestyle, personality basics.
  static const List<JourneyQuestion> phase1 = [
    JourneyQuestion(id: 'p1_q1', text: 'How would you describe your relationship with your faith day to day?'),
    JourneyQuestion(id: 'p1_q2', text: 'What does practising Islam look like in your daily routine — prayer, worship, and beyond?'),
    JourneyQuestion(id: 'p1_q3', text: 'What is drawing you to marriage at this point in your life?'),
    JourneyQuestion(id: 'p1_q4', text: 'What are two or three core values you would never compromise on in a marriage?'),
    JourneyQuestion(id: 'p1_q5', text: 'Is there anything you consider a non-negotiable when choosing a spouse?'),
    JourneyQuestion(id: 'p1_q6', text: 'What does a typical weekday look like for you right now?'),
    JourneyQuestion(id: 'p1_q7', text: 'How would people close to you describe your personality?'),
    JourneyQuestion(id: 'p1_q8', text: 'What role does your family play in your day-to-day decisions?'),
  ];

  // phase_2, shown as "Building a Life". Guiding question: "Could we
  // realistically build a life together?" Topics: children, career
  // ambitions, financial expectations, living arrangements, household
  // responsibilities, work-life balance.
  static const List<JourneyQuestion> phase2 = [
    JourneyQuestion(id: 'p2_q1', text: 'How do you feel about having children, and if so, roughly how many and when?'),
    JourneyQuestion(id: 'p2_q2', text: 'What are your career ambitions over the next five to ten years?'),
    JourneyQuestion(id: 'p2_q3', text: 'What are your expectations around finances — earning, saving, and spending — in a marriage?'),
    JourneyQuestion(id: 'p2_q4', text: 'Where would you want to live, and how do you feel about living near or with extended family?'),
    JourneyQuestion(id: 'p2_q5', text: 'How do you picture household responsibilities being shared between spouses?'),
    JourneyQuestion(id: 'p2_q6', text: 'How do you currently balance work with the rest of your life, and how do you want that to look in marriage?'),
    JourneyQuestion(id: 'p2_q7', text: 'Would you expect your spouse to work outside the home, and does that depend on circumstances?'),
  ];

  // phase_3, shown as "Navigating Life". Guiding question: "Can we
  // navigate life together?" Topics: conflict resolution, communication styles,
  // family expectations, long-term goals, health, difficult
  // situations, personal growth.
  static const List<JourneyQuestion> phase3 = [
    JourneyQuestion(id: 'p3_q1', text: 'When you disagree with someone close to you, how do you usually handle it?'),
    JourneyQuestion(id: 'p3_q2', text: 'How would you describe your communication style, especially during a difficult conversation?'),
    JourneyQuestion(id: 'p3_q3', text: 'What expectations do you think your family will have of your spouse?'),
    JourneyQuestion(id: 'p3_q4', text: 'Where do you see yourself, personally and spiritually, in ten years?'),
    JourneyQuestion(id: 'p3_q5', text: 'Is there anything about your health, past or present, that you feel is important for a future spouse to understand?'),
    JourneyQuestion(id: 'p3_q6', text: 'Can you describe a difficult period in your life and how you got through it?'),
    JourneyQuestion(id: 'p3_q7', text: 'What is something you are actively working to improve about yourself?'),
  ];

  static List<JourneyQuestion> forPhase(int phase) => switch (phase) {
        1 => phase1,
        2 => phase2,
        3 => phase3,
        _ => const [],
      };

  // family_stage, shown as "Family Compatibility" — Seeker<->Wali
  // directions only. Wali
  // <-> Wali engagement is explicitly marked TBC in the source spec
  // ("Exact format and questions: TBC") and is not built here.

  /// Questions the SEEKER asks the OTHER PARTY's Guardian.
  static const List<JourneyQuestion> seekerToWali = [
    JourneyQuestion(id: 'fam_stw_q1', text: 'What are your expectations for this marriage?'),
    JourneyQuestion(id: 'fam_stw_q2', text: 'How involved would you like to be in our life together?'),
    JourneyQuestion(id: 'fam_stw_q3', text: 'What are your hopes for your daughter/son in this marriage?'),
    JourneyQuestion(id: 'fam_stw_q4', text: 'Is there anything about our family you would like to understand better before we go further?'),
  ];

  /// Questions a WALI asks the OTHER PARTY's Seeker.
  static const List<JourneyQuestion> waliToSeeker = [
    JourneyQuestion(id: 'fam_wts_q1', text: 'Why do you want to marry?'),
    JourneyQuestion(id: 'fam_wts_q2', text: 'What are your long-term intentions with my son/daughter?'),
    JourneyQuestion(id: 'fam_wts_q3', text: 'How will you support a family, financially and otherwise?'),
    JourneyQuestion(id: 'fam_wts_q4', text: 'How do you plan to involve our family in your life together?'),
  ];
}
