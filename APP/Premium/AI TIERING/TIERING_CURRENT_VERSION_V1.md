---
id: DOC-ZYRA-0048
type: SPEC
status: CURRENT
feature: APP: PREMIUM
purpose: Premium / Ai Tiering — TIERING CURRENT VERSION V1: ZYRA AI Tiering — Product Principles
links: []
owner: ZYRA chat
---

# ZYRA AI Tiering — Product Principles
**CURRENT_VERSION_V1** | Status: Approved | Authors: Lead Architect + Architectural Reviewer

---

## Core Principle

> **One excellent experience. ZYRA enhances it.**
> **Basic users should feel the app is intelligent. Premium users should feel the app understands them.**

Design one complete screen that works without AI. Then ask: *"If ZYRA could reason here, what would it add?"* That addition is the Premium layer. No screen should feel broken or incomplete without it.

---

## The Design Test

Before building any feature, ask: **"Can this screen exist without AI at all?"**

- If **yes** → that is the canonical design. Premium adds ZYRA's layer on top. One screen, not two.
- If **no** → redesign it. A screen that feels broken without AI has been designed wrong.

This keeps the product maintainable, reduces UI divergence, and ensures Basic users never encounter an obviously incomplete interface.

---

## Two Types of Intelligence

| Type | Role | Available to |
|------|------|-------------|
| **System intelligence** | Fairness, structure, consistency | Everyone (Basic + Premium) |
| **ZYRA intelligence** | Judgement, interpretation, guidance | Premium only |

**System intelligence includes:**
- Compatibility calculations and category scores
- Journey progression and stage flow
- Question library and preventing repeated questions
- Timeline milestones
- Rules-based journey recommendations
- Guardian read access and participation

**ZYRA intelligence includes:**
- Reasoning about this specific couple's journey
- Recommending next steps at checkpoints
- Interpreting alignment patterns
- Generating personalised summaries
- Adaptive follow-up questions based on answer tensions
- Conversation topic suggestions pulled from journey data

---

## Branding Standard

Never call these "AI features" in the product. Users subscribe for **better guidance**, not AI.

All Premium intelligence is branded as:

| Label | Used for |
|-------|----------|
| **ZYRA Recommendation** | Suggesting next steps at checkpoints |
| **ZYRA Insight** | Observations about alignment and patterns |
| **ZYRA Summary** | End-of-stage and end-of-journey summaries |

Internally these are LLM calls. Externally they are simply how ZYRA helps people through the journey.

---

## Applied Examples

### Compatibility Score
- **Basic**: 84% overall + category breakdown (Faith 95%, Family 80%, Lifestyle 74%)
- **Premium**: Same + ZYRA Insight: *"Your strongest alignment is faith and long-term goals. Your biggest opportunity for discussion is balancing family expectations with career ambitions."*

### Stage Checkpoints
- **Basic**: "Foundations complete. 74% alignment. Would you like to continue to Building a Life or explore another topic?" — user chooses based on their own read of the data.
- **Premium**: Same screen + ZYRA Recommendation: *"Based on your answers, we'd recommend exploring family expectations before continuing."*

### Question Journey
- **Basic**: Full access to question library. Standard question set. User browses and selects freely.
- **Premium**: Same library + ZYRA suggests which questions matter most for this specific couple. Adaptive follow-up questions generated from answer tensions — not a fixed library pick, but AI-triggered based on ratings.

### Conversation Stage
- **Basic**: Voice notes and written messages. No AI suggestions. Full conversation functionality.
- **Premium**: ZYRA topic suggestions pulled from journey data. Mid-conversation ZYRA Insights. Compatibility scores surfaced in context as conversation prompts.

### Timeline
- **Basic**: Full timeline of journey milestones.
- **Premium**: ZYRA Insights within the timeline (*"During this stage you both frequently returned to the topic of family and future children."*)

### Guardian Summary
- **Basic**: Guardian can read the conversation thread.
- **Premium**: AI-generated ZYRA Summary delivered to the Guardian: *"Maryam and Ahmed appear strongly aligned on Deen. Family expectations may benefit from an early discussion."*

### Journey Summary (end of all chapters)
- **Basic**: Overall Journey Alignment % + chapter-by-chapter breakdown.
- **Premium**: Full ZYRA Summary — a multi-paragraph narrative of the entire journey, what stood out, where alignment is strong, what would benefit from further discussion.

---

## Caching Architecture

AI outputs are **generated artefacts**, not live services. Generate once, store, reuse. Do not regenerate on every page load.

| Output | Generated when |
|--------|---------------|
| Compatibility summary | Once — after both complete the full journey |
| Stage summary | Once — at end of each chapter |
| Guardian summary | Once — at end of Family Involvement stage |
| Follow-up question recommendations | Once — per chapter, based on ratings at that point |
| Conversation insights | Once per insight trigger — not regenerated on reopen |
| Journey summary | Once — at journey completion |

This keeps Premium feeling AI-powered while controlling ongoing LLM costs at scale.

---

## Trial and Upgrade Model

### First Journey — 7-Day Premium Trial

Every Basic user receives **7 days of Premium free**, triggered automatically when they begin their first Journey — not their first match.

A match alone is passive. A Journey requires the user to have matched, revealed compatibility, exchanged Salam, and chosen to continue. The trial rewards genuine engagement, not accidental or opportunistic sign-ups.

**How it works:**
- Trial starts silently and automatically the moment the user begins their first Journey
- Not advertised in advance — delivered as a surprise after the Journey begins
- The user sees a gift notification: *"To help you get the most from your first journey together, we've unlocked 7 days of ZYRA Premium. Explore everything Premium has to offer until [date]."*
- This feels like a gift, not a promotion

**Trial rules:**
- One free Premium trial per Seeker account — lifetime
- Starts automatically on first Journey
- Cannot be paused, transferred, or restarted
- Does not renew automatically without explicit consent
- Applies to the active Journey only — not banked for future matches

**Why this increases conversions:**
Users won't be subscribing based on a feature list. They'll be subscribing because after seven days they'll think: *"I don't want to lose the guidance ZYRA has been giving us."* That is a much stronger conversion reason than curiosity.

### Upgrade Prompts (Post-Trial)

After the trial ends, upgrade reminders appear at **high-value moments** in the journey — not everywhere, but at the points where ZYRA intelligence creates the most visible difference.

**Recommended placement:**
- Stage checkpoints — where ZYRA Recommendation would appear for Premium users
- After receiving compatibility score — before the ZYRA Insight layer is shown
- On the question library screen — where ZYRA would surface personalised suggestions
- In the conversation stage — where ZYRA topic prompts would appear

Upgrade prompts must feel like a natural invitation, not a paywall. By this point the user has already experienced ZYRA intelligence during their trial and understands what they are being offered.

---

## The Broader Design Philosophy

This tiering model reflects a principle that extends beyond pricing. It becomes the test for every future feature decision:

**System intelligence** provides fairness, structure, and consistency — the foundation everyone deserves.

**ZYRA intelligence** provides judgement, interpretation, and guidance — the layer that makes the journey feel personal.

Every feature built into ZYRA should be tested against this distinction. If it is rules-based and deterministic, it belongs to everyone. If it requires reasoning about this specific couple, it is ZYRA intelligence and belongs to Premium.

---

*Document status: Approved V1. Supersedes all previous informal tiering discussions.*
