---
id: DOC-ZYRA-0022
type: SPEC
status: CURRENT
feature: APP: JOURNEY
purpose: Journey / Pre-Journey Ritual — Summary: JOURNEY STAGES (Match to Conversation): Defines the structured stages a matched pair progresses through before and during the Conversation Stage.
links: []
owner: ZYRA chat
---

FEATURE NAME
JOURNEY STAGES (Match to Conversation)
Group: 4 — Page Responsibilities

============================================================
SUMMARY
============================================================

Purpose:
Defines the structured stages a matched pair progresses
through before and during the Conversation Stage.

ZYRA does not match two people and open a chat.
It guides both parties through intentional stages of
discovery. Every step has a clear purpose. Every
checkpoint is a shared decision.

------------------------------------------------------------
FULL JOURNEY FLOW
------------------------------------------------------------

Match
  ↓
Salam Exchange
  ↓
Compatibility Reveal
  ↓
Guardian Gate
  ↓
Optional Salam to Guardian(s)
  ↓
Phase 1 — Foundations
  ↓
Phase 2 — Building a Life Together
  ↓
Phase 3 — Future & Challenges
  ↓
Family Compatibility Stage
  ↓
Conversation (with ongoing guidance)
  ↓
Meeting
  ↓
Nikah

------------------------------------------------------------
JOURNEY PURPOSE MAPPING
------------------------------------------------------------

Every step has a clear purpose:

  Match              → Mutual interest confirmed
  Compatibility      → Should we explore this?
  Salam              → Begin respectfully
  Guided Discovery   → Understand each other
  Family Stage       → Involve guardians and families
  Conversation       → Build the relationship
  Meeting            → Meet appropriately
  Nikah              → The intended destination

The flow is intentional rather than endless.
It encourages meaningful progression instead of
maximising time spent chatting.

------------------------------------------------------------
COMPATIBILITY REVEAL (AFTER SALAM)
------------------------------------------------------------

The second Journey threshold, after both people exchange Salam.
This is one of the first meaningful moments two people
experience together. It should feel like an event —
not just another information screen.

CURRENT IMPLEMENTATION TRUTH — 2026-09-10

This note supersedes the older illustrative category and shared-score
wording in this section:

• Each Seeker sees only their own real overall score. There is no shared
  couple score, and the client does not fetch the counterpart's score.
• No server-owned, provenance-safe category scoring contract exists yet.
  The app therefore shows "Detailed compatibility isn’t available yet."
  and renders no category values, bars or category-derived insight.
• Historical rows may contain synthetic category JSON created by copying
  the overall score. The production client neither selects nor renders it.
  Future category work must version its real provenance and deliberately
  handle those legacy rows before detail can return.
• The Compatibility Reveal milestone records that the threshold completed;
  it does not publish either person's private percentage as one shared fact.
• The caller-scoped OA-ZYRA-283 RPC boundary and matching client wiring were
  prepared on 2026-09-10, but the migration is STAGED ONLY and NOT APPLIED.
  Production therefore still has the old shared-row authorization until the
  Founder gives the separate hash-specific apply GO and the post-apply matrix
  passes. Truthful read-failure handling remains separate in OA-ZYRA-284.

FLOW — THREE STATES:

STATE 1 — WAITING (before both tap)
  Button label: "Reveal Compatibility"
  Subtext: "Neither of you sees the result until
            you both choose to reveal."
  Status indicators:
    • Green dot = you have tapped
    • Grey dot  = waiting for the other person
  Warm, mutual framing — not "tap to inspect them."

STATE 2 — TRANSITIONAL MOMENT (both have tapped)
  Screen shown briefly before the score appears.
  Text: "You both chose to reveal."
        "Revealing your compatibility..."
  Purpose: turns the reveal into a shared milestone.
           Creates anticipation and emotional weight.
  Followed by animation:
    • Profile pictures slide together
    • Percentage counts up from 0
    • Subtle visual effect (glow or pulse)

STATE 3 — REVEALED (score visible)
  Your Overall Compatibility: 87%

  Category breakdown:
  "Detailed compatibility isn’t available yet."
  No category percentages render until real category scoring exists.

  ZYRA Insight (ZYRA One, deterministic today):
  Gives a short interpretation of the caller's genuine overall score only.
  It makes no category, population or marriage-outcome claim.

  Summary gives the score meaning — a direction for
  the journey, not just a number.

  Visible to: each matched Seeker sees their own score in this screen.

CHECKPOINT ACTIONS (after reveal):

  PRIMARY:
    Continue Journey  →  large, clear button → move to Salam

  SECONDARY:
    Pause Journey     →  smaller button below
    (previously "Step Back" — renamed for clarity.
     Pause = hold, not rejection.)

  DANGER (de-emphasised):
    End Journey       →  small, low-prominence link/button
    If tapped: animates red + confirmation dialog appears.
    Accidental taps must be prevented — this is a
    high-consequence action beside a positive moment.
    Confirmed End Journey → 24-hour cooling period.

TIMELINE MILESTONE (auto-added on reveal):
  Date
  "You both revealed your compatibility."
  This entry stays permanently on the timeline —
  couples can look back on this moment years later.

Note: User-facing name for this feature is TBC.

------------------------------------------------------------
SALAM EXCHANGE
------------------------------------------------------------

The beginning of the relationship.

Flow:
• Person A sends Salam.
• Person B receives notification and sends Salam back.
• Neither moves forward until both have acted.
• Not automatic — both must make the choice.

Timeline Milestone: ✓ Salam Exchanged — [date]

UX: "Send your Salam to [Name] to begin your journey."

------------------------------------------------------------
GUARDIAN GATE
------------------------------------------------------------

After the Salam, before any meaningful discussion begins.

A Seeker must have a linked, active Main Guardian to proceed.

If no Guardian linked:
  Prompt appears: "To begin your journey, you need
  to link a Guardian."
  Match and score are preserved while they sort it.

Main Guardian Rules:
• One Guardian must be designated as Main Guardian.
• Main Guardian must be active — a ghost Guardian blocks progress.
• Exact inactivity threshold: TBC.

Multiple Guardians:
• Seekers may have multiple Guardians (including Premium Guardians).
• Open question: if Person B has 5 Premium Guardians but
  Person A wants to engage with only one, does the
  Seeker have priority to choose?
  Risk: conflicts with Premium feature Guardians paid for.
  Decision needed — dedicated discussion.

------------------------------------------------------------
OPTIONAL SALAM TO GUARDIAN(S)
------------------------------------------------------------

After the Guardian Gate, each party may send a Salam
to the other person's Guardian(s).

• Optional — not required to proceed.
• Async — no waiting. Response comes whenever it comes.
• Guardian must be reading the phases for the journey
  to continue into the next stage.

------------------------------------------------------------
PHASE STRUCTURE — PHASES 1, 2, AND 3
------------------------------------------------------------

Each phase has two parts:
  Part A — AI-generated questions (adaptive)
  Part B — User-chosen questions (searchable library)

After every set of questions, 3 options appear:
  1. Continue       — move to next set or phase
  2. Ask More       — ~10 more questions (or ~5 deeper)
  3. End Journey    — see End Journey rules below

Neither party can advance until both choose the same
direction. End Journey can be chosen by either party.

ADAPTIVE AI QUESTIONS
AI questions are not fixed. They adapt in real time.

Example:
  Person A: "I definitely want children."
  Person B: "I'm unsure."
  → AI automatically generates follow-up questions
    on this tension before moving on.

The experience feels intelligent, not scripted.
AI prioritises areas where answers diverge or where
private ratings signal concern.

PRIVATE RATINGS (after every reveal)
After reading each answer, the user privately rates it
using human phrases — not colours or numbers:

  "This answer reassured me."
  "I'd like to discuss this further."
  "This concerns me."

Visibility: PRIVATE — only the rater and the AI.
Never shown to the other party or the Guardian.

The AI uses ratings to adapt the next set of questions
and may recommend:
"Before progressing, consider exploring finances further."
It speaks in general terms — it never reveals
who rated what or how.

PUBLIC (visible to both parties + Guardian):
  All question answers.

PART A — AI QUESTIONS
  Set 1 (~10 questions) [mandatory]
    AI selects questions themed to this phase.
    Adaptive — follows up on specific answer tensions.
    Both answer independently.
    Simultaneous reveal when both submit.
    Private rating per answer.
    Set Checkpoint: Continue / Ask More / End Journey.
    ↓
  Set 2 (~10 more) [optional]
    AI adapts based on ratings and answer tensions.
    Same reveal, rating, checkpoint flow.
    ↓
  Set 3 (~5 deeper) [optional]
    AI focuses on unresolved tensions.
    Same flow. → Move to Part B.

PART B — PERSONAL QUESTIONS (searchable library)
  Each person searches and selects questions they want
  the other to answer. Type what you mean — system
  finds the closest match in the library.

  Set 1 (~10 questions) [mandatory for Part B]
    Same reveal, rating, checkpoint flow.
    ↓
  Set 2 (~10 more) [optional]
    Same flow.
    ↓
  Set 3 (~5 more) [optional]
    Same flow. → Phase Checkpoint.

PHASE CHECKPOINT
  Continue Journey  →  advance to next phase
  Step Back         →  journey paused
  End Journey       →  see below




------------------------------------------------------------
BETWEEN-CHAPTER PROGRESS OVERVIEW
------------------------------------------------------------

After completing each phase, the overview screen updates
to show cumulative progress before the next phase begins.

Format:
  ✓  Foundations            (completed)
  →  Building a Life        (current)
  ○  The Road Ahead         (upcoming)

Purpose: people love seeing progress. It makes the
journey feel like something being built, not just
a series of tasks being completed.

------------------------------------------------------------
TAPPABLE TOPIC CHIPS
------------------------------------------------------------

The topic chips shown on each Phase Intro screen
(Faith · Daily Life · Core Values etc.) are tappable.

On tap: a small tooltip appears explaining what that
topic covers in more detail.

Example:
  Tap "Core Values"
  → "Questions about honesty, priorities, decision
     making and personal principles."

Tapping is optional — chips still serve as visual
labels if not tapped.

Purpose: helps people feel prepared before they answer,
reducing anxiety and improving answer quality.

------------------------------------------------------------
PRE-PHASE OVERVIEW SCREEN
------------------------------------------------------------

Shown once, after the chapter change screen, before
Phase 1 intro begins.

Purpose: gives both users a clear roadmap of what is
coming. Informative and positive — not poetic.

Content:
  "Before you begin, here's what the next steps look like."

  Phase 1 — Foundations
  Questions about your faith, daily life, and core values.
  These help you understand the principles each of you
  lives by.

  Phase 2 — Building a Life Together
  Questions about children, finances, where you'd live,
  and how you'd share responsibilities.

  Phase 3 — Future & Challenges
  Questions about how you communicate, handle disagreement,
  and approach the future together.

  "Each phase has two parts — AI-chosen questions and
   questions you select yourself. You answer all questions
   in one go before seeing each other's answers."

CTA: Swipe up to begin.

Tone: clear, warm, informative. Not poetic or abstract.

------------------------------------------------------------
PHASE INTRO SCREEN TONE
------------------------------------------------------------

Phase intros should be informative and positively framed.
Not poetic or abstract.

WRONG (too poetic):
  "The strongest marriages often begin with shared
   principles. These questions explore the values and
   beliefs each of you builds your life upon."

RIGHT (informative, warm):
  "Part One covers faith, daily life, and core values.
   These questions help you understand the principles
   and beliefs each of you lives by."

Each intro should answer:
  • What topics will be covered in this phase?
  • Why does this phase matter?

Keep it to 2–3 sentences. Clear and grounded.

------------------------------------------------------------
GUARDIAN ONE — OPTIONAL ANSWER RATINGS
------------------------------------------------------------

(Corrected 2026-07-12 against WALI_ARCHITECTURE_CURRENT_VERSION_V6
— was "Guardian Premium" / "Guardian Basic".)

Guardian+ can optionally rate each answer using the
same phrase system as the private Seeker ratings:
  "This answer reassured me."
  "I'd like to discuss this further."
  "This concerns me."

VISIBILITY (different from Seeker ratings):
  • Seeker-to-Seeker ratings: private — never shown to anyone.
  • Guardian+ ratings: visible to the Seeker they
    support. Their Seeker sees what their Guardian thought.

Purpose:
  Gives the Guardian an active, visible voice in the journey.
  The Seeker can factor in their Guardian's perspective.
  The other party and their Guardian do NOT see these ratings.

This is a Guardian+ feature only. Standard Guardian can
observe but cannot rate.

------------------------------------------------------------
PHASE TRANSITION SCREENS
------------------------------------------------------------

CHAPTER CHANGE SCREEN (before any phase begins)
Shown once, after Meet Their Guardians, before Phase 1.

Purpose: signals to both users that the journey has
shifted from "getting started" to "understanding each other."

Text:
  "You've taken the first steps together."
  "Now it's time to understand one another."

Subtext:
  "You'll answer a series of questions together.
   Neither of you will see the other's answers
   until you've both responded.
   There are no right or wrong answers — only
   an opportunity to understand each other better."

CTA: Swipe up to begin.

------------------------------------------------------------
PHASE INTRO SCREENS (one per phase)
------------------------------------------------------------

Each phase opens with its own intro screen.
It is a chapter heading, not a UI label.

Format:
  Understanding Each Other
  Part [N]
  [Phase Name]

  AI intro text (2–3 lines, warm and purposeful)

Phase 1 — Foundations
  "Understanding Each Other · Part One · Foundations"
  AI text: "The strongest marriages often begin with
  shared principles. These questions explore the
  values and beliefs each of you builds your life upon."

Phase 2 — Building a Life Together
  "Understanding Each Other · Part Two · Building a Life"
  AI text: "From family expectations to daily routines,
  these questions explore what life together might
  actually look like for you both."

Phase 3 — Future & Challenges
  "Understanding Each Other · Part Three · The Road Ahead"
  AI text: "How you navigate difficulty matters as much
  as how you enjoy the good. These questions explore
  how you both approach the future."

CTA: Swipe up to begin this part.

OPEN QUESTION: Phase structure may expand to 4 phases
(Foundations / Family & Marriage / Communication / Lifestyle).
Current approved structure is 3 phases. Needs discussion.

------------------------------------------------------------
ANSWER FLOW — ALL 10 FIRST, THEN REVEAL
------------------------------------------------------------

APPROVED CHANGE — replaces previous per-question flow.

Previous (rejected):
  Answer Q1 → submit → wait → reveal → rate → Q2 → repeat

New (approved):
  Answer all 10 questions in one session.
  Submit all 10 at once.
  Wait for the other person to complete their 10.
  Both sets of answers reveal together.
  Rate each answer privately after the reveal.

Why:
  Removes constant interruption of per-question waiting.
  Creates a bigger, more meaningful reveal moment.
  Feels like opening 10 envelopes together.

WAITING SCREEN COPY (after submitting all 10):
  Title: "Waiting for Maryam's answers"
  Subtext: "Maryam will see your answers once she shares hers."

  Note: "Your answers are with Maryam" is rejected —
  technically incorrect since she hasn't seen them yet.

  This subtly reinforces:
  • Fairness — both see each other at the same time.
  • The mutual nature of the journey.
  Every time.

------------------------------------------------------------
PHASE 1 — FOUNDATIONS
------------------------------------------------------------

Guiding Question: "Are we fundamentally compatible?"
Topics: Practising the faith, marriage intentions, core values,
non-negotiables, daily lifestyle, personality basics.

Timeline Milestone (on Continue):
AI synthesises shared compatible points.
Example: "You both felt prayer was central to daily life."

------------------------------------------------------------
PHASE 2 — BUILDING A LIFE TOGETHER
------------------------------------------------------------

Guiding Question: "Could we realistically build a life together?"
Topics: Children, career ambitions, financial expectations,
living arrangements, household responsibilities, work-life balance.

Timeline Milestone (on Continue):
Example: "You both want to live close to family."

------------------------------------------------------------
PHASE 3 — FUTURE & CHALLENGES
------------------------------------------------------------

Guiding Question: "Can we navigate life together?"
Topics: Conflict resolution, communication styles, family
expectations, long-term goals, health, difficult situations,
personal growth.

Timeline Milestone (on Continue):
Example: "You both value open communication."

------------------------------------------------------------
FAMILY COMPATIBILITY STAGE
------------------------------------------------------------

Purpose: "Involve guardians and families."

Previously referred to as "Guardian & Family Questions."
Renamed to reflect its true scope — this is about
family compatibility, not just guardian formalities.

THREE DIRECTIONS OF ENGAGEMENT:

1. SEEKER → GUARDIAN (other person's Guardian)
   The Seeker asks the other Guardian questions.
   Examples:
   • What are your expectations for this marriage?
   • How involved would you like to be?
   • What are your hopes for your daughter/son?

2. GUARDIAN → SEEKER
   The Guardian asks the other Seeker questions.
   Examples:
   • Why do you want to marry?
   • What are your long-term intentions?
   • How will you support a family?

3. GUARDIAN ↔ GUARDIAN (if both matched parties have a Guardian)
   The two Guardians can engage with each other directly.
   This mirrors how families speak to each other in
   traditional marriage processes in the faith community.
   Exact format and questions: TBC.

4. OPTIONAL FAMILY INTRODUCTIONS (future)
   Beyond Guardians, broader family introductions may
   be possible in future. Not yet specified.

Same set structure as Phases 1–3 (sets of ~10/10/5).
Same adaptive AI, simultaneous reveal, private ratings,
and set checkpoints throughout.

Timeline Milestone (on Continue):
Example: "Families have been introduced."

Guardian Visibility:
• Phases 1–3: Guardian observes, cannot submit answers.
• Family Stage: Guardian is an active participant.

------------------------------------------------------------
CONVERSATION STAGE
------------------------------------------------------------

Purpose: "Build the relationship."

This is NOT the reward at the end of a checklist.
The structured journey continues — it simply becomes
less rigid and more open.

What opens:
• Free messaging between matched parties.

What continues alongside it:
• Voice notes.
• Shared milestones on the Timeline.
• AI conversation prompts — suggested topics or
  questions to keep the conversation meaningful.
• Optional: continue asking questions from the library.
• Timeline continues recording meaningful moments.
• Guardian remains visible to messages and timeline.

The goal: the conversation is richer because they've
already covered so much together. The AI continues
to support — not to control, but to guide.

------------------------------------------------------------
END JOURNEY — COOLING PERIOD
------------------------------------------------------------

Respectful end (no block / no report):
• Journey enters 24-hour inactive period.
• No messages or actions during this time.
• After 24 hours, journey officially disconnects.
• Journey slot freed for both parties.
• Timeline preserved as historical record.

End with block or report:
• Journey ends immediately. No cooling period.
• Block / report handled by Safety system.

------------------------------------------------------------
PRIVACY MODEL
------------------------------------------------------------

DEFAULT RULE: Everything is PUBLIC.
Private is the exception and must be explicitly stated.

PUBLIC (both matched parties + linked Guardian):
  • Compatibility Reveal completion milestone (without a percentage)
  • All question answers across all phases
  • Guardian hearts / likes on answers
  • Timeline milestones
  • Conversation messages
  • Family Compatibility stage content

PRIVATE (rater + AI only — never shown to others):
  • Per-answer ratings and phrases
  • Each Seeker's caller-owned compatibility percentage

NEVER VISIBLE TO ANYONE:
  • Raw onboarding compatibility responses
  • Which onboarding questions drove the score

Users are told at each phase:
"Your answers are shared with [Name] and your Guardian.
 Your ratings are private and used only to guide
 your journey."

------------------------------------------------------------
GUARDIAN — VISIBILITY AND ENGAGEMENT
------------------------------------------------------------

Guardian can see everything across the entire journey:
  • Compatibility Reveal completion milestone; the current Guardian client
    does not display either Seeker's private compatibility percentage
  • All question answers across all phases
  • Family Compatibility stage content
  • Timeline milestones
  • Conversation messages

Guardian can heart / like individual answers.
Hearts are visible to everyone (both parties + Guardian).

Phases 1–3: Guardian observes only.
Family Stage: Guardian is an active participant.

Note: Full Guardian design is a future dedicated session.
Current focus is the Seeker experience.

============================================================
OPEN DISCUSSIONS
============================================================

• User-facing names for each phase and stage.
• User-facing name for the Compatibility Reveal feature.
• Salam to Guardian(s) — exact inactivity rules for Guardian.
• Multiple Guardians — Seeker priority to choose one vs
  all Premium Guardians having access (Premium conflict).
• Guardian ↔ Guardian format and question library.
• Optional family introductions (future stage).
• AI conversation prompt design for Conversation Stage.
• Voice note format and rules.
• Exact question counts per set (currently ~10/10/5).

============================================================
APPROVED TO-DO LIST
============================================================

• Design Compatibility Reveal screen with category
  breakdown and AI summary.
• Design Salam Exchange screen.
• Design Guardian Gate prompt screen.
• Design Phase question screens (all three phases).
• Design simultaneous reveal screen.
• Design set checkpoint screen (3 options).
• Design adaptive AI question logic.
• Design private rating phrases UI.
• Build AI question library (Phase 1, 2, 3).
• Build personal question library (searchable).
• Design Family Compatibility stage screens.
• Design Guardian ↔ Guardian engagement.
• Design Conversation Stage with AI prompts.
• Define Timeline milestone wording per stage.
• Draft T&C wording for Guardian requirement.
