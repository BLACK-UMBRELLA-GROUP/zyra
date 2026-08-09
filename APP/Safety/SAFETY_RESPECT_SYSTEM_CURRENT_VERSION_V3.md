# ZYRA Safety & Respect System
**SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3**
Last updated: 2026-06-28
Authors: Lead Architect (Claude) + Architectural Reviewer (ChatGPT)

---

## Governing Principle

ZYRA is built on trust. The Safety & Respect System exists to protect that trust — not to surveil users or enforce a rigid interpretation of Islamic etiquette.

**Messages remain private by default.**

The system detects patterns and signals, not individual messages. Human review is only triggered at high-confidence escalation points, not as routine monitoring. ZYRA nudges before it punishes, and explains before it restricts.

---

## What This System Does and Does Not Do

| Does | Does Not |
|------|----------|
| Detect harmful, coercive, and exploitative behaviour | Read and archive every message for routine review |
| Gently nudge users when conversations drift from ZYRA's purpose | Judge whether every conversation is "Islamic enough" |
| Build internal trust signals over time | Punish users based on a single automated signal |
| Escalate to human review for long-term or permanent restrictions | Restrict users without explanation |
| Protect users from scams, abuse, and grooming | Flag respectful conversations about marriage expectations, health, or sensitive family topics |
| Treat all users identically regardless of subscription tier | Give Pro users leniency in safety decisions |

---

## Level 1 — Automatic Protection

These are objective safety behaviours that every responsible platform moderates. Detection at this level is high confidence and triggers the escalation path.

**Detected behaviours:**
- Sexual solicitation or explicit sexual content
- Harassment and sustained abusive language
- Threats of any kind
- Blackmail or coercion
- Sharing or requesting explicit images
- Requests for money or financial transfers
- Scam indicators (urgency, offshore requests, identity inconsistencies)
- Grooming patterns (age-gap pressure, isolation from family, secrecy requests)

**Response:** Automated warning followed by escalation review.

---

## Level 2 — Islamic Conduct Signals

These are behavioural patterns inconsistent with ZYRA's purpose. Detection at this level is pattern-based — a single occurrence may produce a nudge, repeated occurrence escalates.

**Detected patterns:**
- Repeated sexual conversations across multiple interactions
- Pressure for unsupervised private meetings
- Requests to hide conversations from a Guardian
- Early or pressured attempts to move communication to WhatsApp, Snapchat, or Telegram
- Requests for intimate photographs
- Manipulation, gaslighting, or emotional coercion
- Repeated disengagement from Guardian involvement after prompts

**Important nuance on contact-sharing:** Families legitimately coordinate logistics outside ZYRA. The signal is early contact-sharing combined with other indicators, or active pressure to move before any Guardian is involved — not contact-sharing alone.

**Response:** AI nudge (Level 3). Escalation only if pattern persists.

---

## Level 3 — AI Nudges

ZYRA's preferred first intervention. A gentle, values-aligned prompt before any restriction is applied.

**Nudge examples:**

> *ZYRA is designed to support respectful conversations focused on marriage. If things feel off, your Guardian is here to help.*

> *Consider involving your Guardian as your journey progresses — their involvement is one of the things that makes ZYRA different.*

**Cooldown rule:** One nudge per conversation thread, not per message. If behaviour continues after one nudge, the system escalates — it does not nudge again.

**Tone:** Warm, not accusatory. ZYRA assumes good intent until the pattern proves otherwise.

---

## Level 4 — Escalation Path

| Stage | Trigger | Action | Human Review Required |
|-------|---------|--------|-----------------------|
| Warning | Level 2 pattern persists after nudge, or Level 1 first occurrence | In-app warning with clear explanation | No |
| Temporary Restriction | Warning ignored, behaviour continues | Limited functionality for defined period | No |
| Human Review | Sustained pattern or serious Level 1 violation | Authorised reviewer assesses the case | Yes |
| Suspension | Reviewer confirms serious violation | Account suspended pending outcome | Yes |
| Permanent Removal | Repeated serious violations or confirmed predatory behaviour | Account permanently closed | Yes — mandatory |

**The AI recommends. Humans decide at long-term and permanent stages.**

No user is permanently restricted based solely on automated signals. Human review is mandatory before any suspension or permanent removal.

**Appeals:** Every restriction from Temporary Restriction onwards has an appeals path. The appeals process must be accessible in-app, not buried in support documentation.

---

## Confidence-Based Signal Model

A single event must not significantly affect the Respect Score or trigger immediate action.

Signals build confidence progressively:

| Confidence Level | Signals | System Response |
|-----------------|---------|-----------------|
| Low | One suspicious message or report | Monitor only. No action. |
| Medium | Repeated similar behaviour across interactions | AI nudge triggered. |
| High | Multiple independent signals, different types | Escalation path begins. |
| Very High | Sustained pattern after warnings | Human review escalation. |

The system avoids reacting to isolated incidents. Trust is built and eroded over time, not in a single moment.

---

## Context-Aware Detection

The system must consider the wider conversational context, not individual keywords.

**Legitimate conversations that must not be flagged:**
- Discussing intimacy within marriage
- Medical conditions, fertility, or family planning
- Sensitive family finances or expectations before marriage
- Health topics relevant to compatibility

Keyword-based filtering alone will generate unacceptable false positives in these areas. Context-aware detection is architecturally heavier than keyword matching — it requires more sophisticated AI processing and carries a higher compute cost per message. This is a conscious cost decision, not an assumption.

**The standard:** The system should be more confident that harm is occurring before acting, not less.

---

## Explainability Standard

Whenever ZYRA takes action against a user, the user receives a clear explanation of what was detected and what action was taken.

**Required:**
> *We've temporarily limited this feature because our systems detected behaviour that may breach our Community Standards. If you believe this is an error, you can appeal below.*

**Not acceptable:**
> *Account restricted.*

Explainability is not just good UX — it is a legal requirement. Under GDPR Article 22, where automated decisions have a significant effect on a user, they have the right to an explanation and human review. The explainability standard ensures compliance and builds trust even when users disagree with the outcome.

---

## The Respect Score

An internal, non-public trust signal that accumulates over a user's time on ZYRA. Never shown to the user or other users. Used by the system to calibrate response thresholds only.

### Positive signals (increase trust)
- Guardian linked and active
- Journey progressing naturally through stages
- Consistent respectful language patterns
- No reports, warnings, or escalations
- Long-standing account with clean history
- Responsive to AI nudges

### Negative signals (decrease trust)
- Reported by another user
- Level 1 or Level 2 pattern detected
- Warning issued
- Guardian removed or blocked
- Pressure or coercion patterns detected
- Attempts to move off-platform early

### Decay mechanism
Signals are time-weighted. A negative signal from two years ago carries significantly less weight than a recent one. A user who had early issues but has demonstrated consistent respectful behaviour since should reflect that in their score.

### Trust is earned from behaviour — not purchases

**Pro membership must never influence the Respect Score.** A Pro subscriber who violates safety standards is treated identically to a Basic user. Paying for a subscription does not confer additional trust, leniency, or preferential moderation treatment. Trust is earned through behaviour, period.

### The Respect Score Must Never Become a Social Score

This is a hard architectural boundary:

| The Respect Score... | Status |
|----------------------|--------|
| Used by the safety system to calibrate responses | ✅ Permitted |
| Accessible to authorised human reviewers | ✅ Permitted |
| Displayed publicly or to other users | ❌ Prohibited |
| Used to rank profiles or influence discovery | ❌ Prohibited |
| Used as a compatibility or matching signal | ❌ Prohibited |
| Used in marketing or product features | ❌ Prohibited |
| Accessible to product analytics or recommendation systems | ❌ Prohibited |

The Respect Score exists for operational safety. It is siloed from every other system. Access is restricted to the safety system and authorised human reviewers only.

### Rehabilitative by Design

The Respect Score is neither a permanent reputation nor a punishment system. It is a continuously evolving assessment of recent behavioural trust.

The system is designed so that users who genuinely change their behaviour can gradually rebuild trust over time. The decay mechanism supports this technically; this principle makes it explicit philosophically.

**The three-part trust philosophy:**
- Trust is earned through consistent respectful behaviour.
- Trust can be lost through harmful or coercive behaviour.
- Trust can be rebuilt through sustained improvement over time.

This philosophy guides every future decision around moderation, appeals, decay calibration, and enforcement. A user who had issues early in their ZYRA journey should not be permanently defined by them. The system looks at who someone is now, weighted by recent behaviour — not who they were.

This also shapes how appeals are assessed. A user who appeals a restriction and then demonstrates sustained improvement should see that reflected. The appeals process is not a one-time gate — it is part of the rehabilitative path.

### Privacy and GDPR
The Respect Score is personal data. It must be:
- Disclosed in the ZYRA Privacy Policy (existence, purpose, and data used)
- Available to the user on request (right of access)
- Deletable on account closure
- Never shared with third parties, other users, or internal systems beyond safety

---

## Moderation Philosophy

ZYRA's moderation protects users from harm. It does not attempt to replace Islamic scholarship or judge the quality of someone's faith through their messages.

The line is not between "Islamic" and "un-Islamic." The line is between **respectful and harmful**.

> Strong moderation for safety, scams, abuse, coercion, explicit content, and harassment.
> Gentle guidance aligned with ZYRA's values.
> Pattern-based AI with context awareness rather than keyword filtering.
> Explainability at every escalation stage.
> Human review before any long-term or permanent restriction.
> No attempt to judge whether every conversation is sufficiently Islamic.

---

## Governance

This document is a governed system standard. Changes to detection thresholds, escalation criteria, confidence model, or Respect Score inputs require architectural review and product owner sign-off.

The human review stage is a **launch dependency**. ZYRA requires a defined moderation team or outsourced trust and safety resource before the first user is onboarded.

---

*Cross-reference: Advertising Standard · Global Platform Principles · Dependency Communication Principle*
