---
id: DOC-ZYRA-0046
type: SPEC
status: CURRENT
feature: APP: PLATFORM
purpose: Platform — GLOBAL PLATFORM PRINCIPLES CURRENT VERSION V1: ZYRA Global Platform Principles: These principles govern how ZYRA expands internationally.
links: []
owner: ZYRA chat
---

# ZYRA Global Platform Principles
**GLOBAL_PLATFORM_PRINCIPLES_CURRENT_VERSION_V1**
Last updated: 2026-06-28
Authors: Lead Architect (Claude) + Architectural Reviewer (ChatGPT)

---

## Purpose

These principles govern how ZYRA expands internationally. They are architectural decisions, not implementation details — each one must be treated as a platform-wide constraint from day one, not a feature added later.

---

## Principle 1 — Regional Pricing

### Standard
Subscription pricing must reflect the purchasing power and economic conditions of each region, not simply currency conversion from the UK base price.

The goal is not to make ZYRA as cheap as possible everywhere. The goal is to make it **fair and accessible** within each region while remaining **commercially sustainable**.

### How It Works
- App Store (Apple) and Google Play use fixed pricing tier brackets per country. ZYRA selects the appropriate tier bracket for each market rather than setting an arbitrary local price.
- The UK price (£34.99/month ZYRA One, £9.99/month independent Guardian+) is the reference price. Regional prices are independently set based on local market conditions, not derived by formula.
  (Terminology and pricing corrected 2026-07-12 against ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5 / DR-075 — was "£19.99/month Seeker Pro, £9.99/month Guardian Pro".)
- A commercial sustainability floor applies to every market. No regional price may fall below the point where server and operational costs are covered per paying user.

### Volatility and Review
- Currency volatility in markets such as Pakistan, Nigeria, and Turkey means prices cannot be set once and left indefinitely.
- Regional prices are reviewed at minimum annually, or when significant currency movement (>15%) occurs.
- Price increases in existing markets require user notice in advance and must not trigger mid-subscription.

### Governance
Regional pricing decisions require product owner sign-off. They are not engineering configuration changes.

---

## Principle 2 — Multi-Language by Design

### Standard
Internationalisation (i18n) is a platform principle, not a future enhancement. Every part of ZYRA must be designed with localisation in mind from day one.

**English must not be embedded into the architecture.**

### Scope
Every surface must be localisation-ready at build time:

| Surface | Localisation Requirement |
|---------|-------------------------|
| Interface labels and navigation | String externalisation — no hardcoded English |
| Journey questions and prompts | Translatable string keys, not inline text |
| Notifications (push and email) | Template-based with language parameter |
| AI outputs (ZYRA Insights, Recommendations, Summaries) | Generated in user's language, not translated post-hoc |
| Timeline entries and milestone text | Localised at generation time |
| Subscription and purchase flows | Full localisation including legal text |
| Error messages and system copy | String externalisation from day one |

### RTL Support
Arabic and Urdu require right-to-left (RTL) interface layout. RTL is a **UI layout concern**, not a text replacement concern. Every screen must be designed RTL-aware from the beginning. Retrofitting RTL onto an existing interface requires redesigning every screen — this cost is unacceptable at scale.

**RTL readiness is a Day 1 requirement, not a future language pack.**

### AI Output Language
ZYRA's AI guidance (Insights, Recommendations, Journey Summaries) must be **generated** in the user's chosen language. Translating English AI output into another language after generation degrades quality — nuance is lost, and errors are introduced. The language parameter must flow through to the generation prompt itself.

### Priority Languages (Initial)
English, Arabic, Urdu, Bengali, Turkish, Malay. Additional languages follow community demand and regional expansion.

---

## Principle 3 — Cross-Language Communication

### Standard
Every participant in a ZYRA journey communicates in the language they are most comfortable using. ZYRA handles translation invisibly in the background.

**To the user, the technology does not exist. The benefit does.**

### How It Works
Each user sets a preferred language. When a message is sent, ZYRA detects the source language and delivers the message to the recipient in their preferred language. Neither participant needs to translate, switch languages, or interact with any translation interface.

**Example:**
- A Seeker writes in English.
- Their Guardian receives and reads the message in Bengali.
- The Guardian replies in Bengali.
- The Seeker receives the reply in English.

Both participants experience a seamless conversation in their own language.

### Roll-Out Phases

| Phase | Scope |
|-------|-------|
| Phase 1 | Seeker ↔ Guardian communication |
| Phase 2 | Guardian ↔ Guardian communication (family-to-family) |
| Phase 3 | Future expansion as platform grows |

### User-Facing Language
This feature is never described as "AI translation" or "automatic translation." The user-facing framing is simply:

> **Communicate in your own language.**

No technical explanation. No AI branding. The feature is invisible; the benefit is self-evident.

### Data Governance
- Both the original message and the translated message are stored.
- The **original message is the source of truth** for any review, dispute, or Guardian oversight purpose.
- Translated messages are labelled internally as derived content.
- Users are informed in privacy documentation that messages may be translated for delivery, without exposing implementation detail in the UI.

### Quality Standard
Translation quality must meet a minimum standard before any language pair is enabled. A language pair that produces unreliable or misleading translations must not be shipped — a mistranslation in a marriage context carries real-world consequence. Language pairs are enabled progressively as quality is validated.

### Why This Differentiates ZYRA
Most internationalised apps support multiple languages. ZYRA's cross-language communication means a father in Sylhet and his son's potential match's family in London can communicate naturally, in their own words, without an intermediary. This is not a translation feature. It is a family connection feature.

---

## Relationship Between Principles

These three principles reinforce each other:

- **Regional Pricing** makes ZYRA financially accessible in every market.
- **Multi-Language by Design** makes the product usable in every market.
- **Cross-Language Communication** makes the product *meaningful* in every market — particularly in diaspora communities where generations speak different languages at home.

Together they position ZYRA not as a UK app with international support, but as a global marriage platform for a faith community built for how families in the community actually live.

---

## Governance

These principles are platform-wide constraints. Any feature, screen, or infrastructure decision that conflicts with these principles requires explicit architectural review and product owner approval before proceeding.

---

*Cross-reference: Advertising Standard · Subscription Transparency Standard · AI Tiering*
