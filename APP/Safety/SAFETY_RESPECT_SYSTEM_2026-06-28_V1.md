# ZYRA Safety & Respect System
**SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V1**
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
| Escalate to human review only at high confidence | Restrict users without an opportunity to appeal |
| Protect users from scams, abuse, and grooming | Flag respectful conversations about marriage expectations, health, or sensitive family topics |

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

**Response:** Automated warning followed immediately by escalation review.

---

## Level 2 — Islamic Conduct Signals

These are behavioural patterns that are inconsistent with ZYRA's purpose. Detection at this level is pattern-based — a single occurrence may produce a nudge, repeated occurrence escalates.

**Detected patterns:**
- Repeated sexual conversations across multiple interactions
- Pressure for unsupervised private meetings
- Requests to hide conversations from a Wali
- Early or pressured attempts to move communication to WhatsApp, Snapchat, or Telegram
- Requests for intimate photographs
- Manipulation, gaslighting, or emotional coercion
- Repeated disengagement from Wali involvement after prompts

**Important nuance on contact-sharing:** Families legitimately coordinate logistics outside ZYRA. Sharing contact details is not itself a signal. The signal is *early* contact-sharing combined with other indicators, or active pressure to move before any Wali is involved.

**Response:** AI nudge (Level 3). Escalation only if pattern persists.

---

## Level 3 — AI Nudges

ZYRA's preferred intervention. A gentle, values-aligned prompt before any restriction is applied.

**Nudge examples:**

> *ZYRA is designed to support respectful conversations focused on marriage. If things feel off, your Wali is here to help.*

> *Consider involving your Wali as your journey progresses — their involvement is one of the things that makes ZYRA different.*

> *This kind of conversation is better suited to a supported journey. Would you like to bring your Wali in?*

**Cooldown rule:** One nudge per conversation thread, not per message. Repeated nudging within a single conversation feels like surveillance and causes users to disengage. If the behaviour continues after one nudge, the system escalates — it does not nudge again.

**Tone:** Warm, not accusatory. ZYRA assumes good intent until the pattern proves otherwise.

---

## Level 4 — Escalation Path

| Stage | Trigger | Action |
|-------|---------|--------|
| Warning | Level 2 pattern persists after nudge, or Level 1 first occurrence | In-app warning explaining the concern |
| Temporary Restriction | Warning ignored, behaviour continues | Limited functionality for defined period |
| Human Review | Sustained pattern or serious Level 1 violation | A human reviewer assesses the case |
| Suspension | Reviewer confirms serious violation | Account suspended pending outcome |
| Permanent Removal | Repeated serious violations or confirmed predatory behaviour | Account permanently closed |

**Appeals:** Every restriction from Temporary Restriction onwards has an appeals path. No user is permanently removed based solely on automated signals — human review is mandatory before permanent action.

---

## The Respect Score

An internal, non-public trust signal that accumulates over a user's time on ZYRA. Never shown to the user or other users. Used by the system to calibrate response — a first-time low-confidence signal is treated differently for a high-trust user than for a low-trust one.

### Positive signals (increase trust)
- Wali linked and active
- Journey progressing naturally through stages
- Consistent respectful language patterns
- No reports, warnings, or escalations
- Long-standing account with clean history
- Responsive to AI nudges

### Negative signals (decrease trust)
- Reported by another user
- Level 1 or Level 2 pattern detected
- Warning issued
- Wali removed or blocked
- Pressure or coercion patterns detected
- Attempts to move off-platform early

### Decay mechanism
Signals are time-weighted. A negative signal from two years ago carries significantly less weight than a recent one. A user who had early issues but has demonstrated consistent respectful behaviour since should reflect that in their score. The Respect Score is a trust signal, not a permanent record.

### Wali linkage as trust input
Having an active, linked Wali is a meaningful positive signal. It is a genuine indicator of intent — not just a feature used. The system recognises it as such.

### Privacy and GDPR
The Respect Score is personal data. It must be:
- Disclosed in the ZYRA Privacy Policy (existence, purpose, and data used)
- Available to the user on request (right of access)
- Deletable on account closure
- Never shared with third parties or other users

---

## What ZYRA Will Not Do

- Read and archive routine conversations for human review
- Flag sensitive but legitimate marriage discussions (health expectations, family finances, intimacy within marriage)
- Apply a rigid Islamic etiquette checklist to every message
- Restrict users based on a single automated signal without escalation
- Use moderation as a commercial mechanism to push users toward Pro
- Permanently remove users without human review

---

## Moderation Philosophy

ZYRA's moderation protects users from harm. It does not attempt to replace Islamic scholarship or judge the quality of someone's faith through their messages.

Families discussing health, finances, or expectations before marriage are doing exactly what ZYRA is designed to support. The line is not between "Islamic" and "un-Islamic" — the line is between **respectful and harmful**.

> Strong moderation for safety, scams, abuse, coercion, explicit content, and harassment.
> Gentle guidance aligned with ZYRA's values.
> Pattern-based AI rather than constant human monitoring.
> No attempt to judge whether every conversation is sufficiently Islamic.

---

## Governance

This document is a governed system standard. Changes to detection thresholds, escalation criteria, or Respect Score inputs require architectural review and product owner sign-off.

The escalation path — particularly the human review stage — requires a defined moderation team or outsourced trust and safety resource before launch. This is a launch dependency, not a post-launch addition.

---

*Cross-reference: Advertising Standard · Global Platform Principles · Dependency Communication Principle*
