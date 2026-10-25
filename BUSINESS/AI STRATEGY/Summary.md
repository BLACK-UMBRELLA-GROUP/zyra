---
id: DOC-ZYRA-0088
type: PLAN
status: CURRENT
feature: BUSINESS: AI STRATEGY
purpose: Ai Strategy — Summary: ZYRA — AI STRATEGY (GOVERNED SUMMARY)
links: []
owner: ZYRA chat
---

============================================================
ZYRA — AI STRATEGY (GOVERNED SUMMARY)
============================================================
Version:      V1
Status:       CURRENT_VERSION — governed (in-place promotion)
Owner:        Founder (content) · Fable (documentation filing)
Promoted:     2026-08-20 under OA-ZYRA-209 — Founder standing
              instruction; recommendation executed: governed
              headers first, filename renames deferred until the
              OA-ZYRA-201 reference-stability decision.
Supersession: This file is the single current version of this
              system summary. Any prior unversioned copies are
              superseded in place.
============================================================

============================================================
ZYRA PROJECT
============================================================
BUSINESS / AI STRATEGY
Summary
============================================================
Owner:        Project Owner
Status:       In Planning
Group:        5 — Application Architecture
Last Updated: 2026-06-21
============================================================


OVERVIEW
============================================================

AI is a core operational service within ZYRA — not a
chatbot feature. The objective is to reduce operational
workload, improve user experience, maintain platform
quality, and support long-term scalability.

AI operates across eight service areas:
  1. Customer Support
  2. Moderation
  3. Verification
  4. Trust & Safety
  5. Report Investigation
  6. Profile Assistance
  7. Conversation Assistance (Future)
  8. Platform Operations

Individual service areas will each require their own
APP feature folder as they are prioritised for development.


AI COST STRATEGY
============================================================

AI costs are driven by usage, not total users.

Principles
------------------------------------------------------------
  • Only invoke AI when necessary
  • Cache previous AI results where possible
  • Use smaller models for simple tasks
  • Reserve premium models for complex reasoning
  • Backend enforces AI budgeting — no unrestricted usage

Model Tiers
------------------------------------------------------------
  Simple task    →  Small model
  Medium task    →  Medium model
  Complex task   →  Large model

Usage Examples
------------------------------------------------------------
  Photo moderation
    Run once on upload. Repeat only if the photo changes.

  Profile improvement
    Only when the user requests it.

  Support
    Only when the user requests assistance.

  Avoid unnecessary AI execution on routine app usage.


SERVICE AREAS
============================================================

1. Customer Support
------------------------------------------------------------
  • Live chat
  • Email replies
  • FAQ assistance
  • Account guidance
  • Escalation to human agents when required

2. Moderation
------------------------------------------------------------
  • Nude detection
  • Explicit content detection
  • Offensive image detection
  • Multiple people detection
  • Fake profile detection
  • Image quality checks
  • AI-generated image detection (future)

3. Verification
------------------------------------------------------------
  • ID quality checking
  • Expired document detection
  • Face matching
  • Liveness verification
  • Guidance when verification fails

4. Trust & Safety
------------------------------------------------------------
  • Scam detection
  • Spam detection
  • Suspicious behaviour monitoring
  • Mass messaging detection
  • Fraud indicators

5. Report Investigation
------------------------------------------------------------
  AI summarises reports before moderator review.
  Moderators receive concise evidence summaries rather
  than reading every message manually.

6. Profile Assistance
------------------------------------------------------------
  • Improve biographies
  • Improve writing quality
  • Detect missing information
  • Suggest profile improvements

7. Conversation Assistance (Future)
------------------------------------------------------------
  Guidance only — AI does not generate conversations.
  Examples:
    • Conversation has stalled
    • Appropriate time to involve Guardian
    • Communication suggestions

  Confirmed as future. Not for near-term implementation.

8. Platform Operations
------------------------------------------------------------
  Developer Assistance
    • Why are users abandoning onboarding?
    • Which screen has the highest drop-off?
    • Which verification stage fails most often?
    • Daily operational summaries

  Administration
    Natural language business queries:
    • How many users joined today?
    • How many failed verification?
    • Outstanding moderation queue size?
    • Daily platform summary

  Marketing
    • Blog generation
    • SEO content
    • Social media content
    • Email campaigns
    • Ad copy
    • App Store descriptions
    • Video scripts
    • Customer feedback analysis
    • Marketing performance summaries


AI EMAIL HANDLING
============================================================

Workflow
------------------------------------------------------------
  Customer email received
  ↓
  AI categorises request
  ↓
  AI drafts response
  ↓
  High confidence  →  Send automatically
  Low confidence   →  Human review queue

AI-Handled Cases
------------------------------------------------------------
  • FAQs
  • Password assistance
  • Verification guidance
  • Navigation help

Human-Handled Cases
------------------------------------------------------------
  • Abuse
  • Appeals
  • Legal matters
  • Safeguarding
  • Complex disputes


CURRENT STATUS
============================================================

In Planning. All items are ideas pending individual review,
prioritisation, and approval before implementation begins.

Individual service areas will each become their own APP
feature folder as they are prioritised.


APPROVED FUTURE WORK
============================================================

  • Break individual service areas into APP feature folders
    as each is prioritised for development.
  • Formalise AI cost model as a technical architecture
    decision before development begins.
  • Conversation Assistance confirmed as future work only.
  • AI-generated image detection confirmed as future work
    within Moderation.
  • Define human escalation thresholds for AI email handling.


============================================================
END OF DOCUMENT
============================================================
