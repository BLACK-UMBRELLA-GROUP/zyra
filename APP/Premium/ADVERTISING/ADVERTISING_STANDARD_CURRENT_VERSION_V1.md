# ZYRA Advertising Standard
**ADVERTISING_CURRENT_VERSION_V1**
Last updated: 2026-06-28
Authors: Lead Architect (Claude) + Architectural Reviewer (ChatGPT)

---

## Governing Principle

ZYRA's advertising model exists to keep the platform genuinely free for Basic users — not to monetise their marriage journey. Advertising is a background funding mechanism, never a product experience.

**Pro removes interruptions. It does not unlock marriage itself.**

Any advertising that conflicts with ZYRA's values, mission, or the trust of its users will be rejected regardless of commercial value.

---

## Model Overview

| Tier | Advertising |
|------|-------------|
| Seeker Basic | Ad-supported (see placement rules) |
| Seeker Pro | Completely ad-free |
| Wali Basic | No ads |
| Wali Pro | No ads |

---

## Placement Rules

These are non-negotiable regardless of sponsor tier or commercial arrangement.

1. **Browse and Discovery only.** Ads appear only within the browse/discovery experience — as sponsored cards within the profile feed.
2. **Never inside an active journey.** Once a journey has begun, no ads appear at any stage — conversation, checkpoints, meeting, or Nikah.
3. **Never on the Guardians tab.** Wali and family oversight screens are ad-free for all users.
4. **Never mid-conversation.** No ads between messages or within any communication surface.
5. **Frequency cap: approximately every 10 profile interactions.** The exact interval is a governed product rule, not a hardcoded implementation constant. It will be reviewed against retention data and adjusted as needed.
6. **Sponsored cards must be visually distinct.** A clear "Sponsored" label is required. Card treatment must differ from real profiles. No ambiguity between a match and an advertisement is acceptable — this would be a critical trust violation.

---

## Phase Model

### Phase 1 — Certified Ad Network (Immediate)
Use a certified advertising network with ZYRA's category blocklist applied. No location targeting. Revenue begins flowing while the curated sponsor platform is built.

**Requirement:** The selected network must support category-level blocking. Any network that cannot guarantee category exclusion will not be used.

### Phase 2 — Curated Sponsor Portal (Medium Term)
Manual onboarding of individual sponsors. ZYRA vets each sponsor against the Advertising Standard before their campaign goes live. Sponsors are aligned Muslim-friendly businesses rather than network-sourced placements.

### Phase 3 — Local Sponsorship Platform (Long Term)
Full self-serve or managed sponsorship with geographic targeting, campaign management, impression reporting, and category exclusivity enforcement. This is a B2B product surface requiring its own portal and account management.

---

## Accepted Advertising Categories

The following categories are provisionally accepted, subject to individual vetting of each advertiser:

- Islamic books and publishing
- Halal travel and tourism
- Hajj and Umrah providers
- Islamic finance and banking
- Modest clothing and fashion
- Halal food and restaurants
- Education and universities
- Family services
- Health and wellbeing
- Home services
- Wedding services
- Local Muslim businesses
- General mainstream brands that do not conflict with Islamic values

---

## Rejected Advertising Categories

The following categories are permanently rejected. No commercial arrangement overrides this list.

- Gambling and betting of any kind
- Alcohol and alcohol-adjacent products
- Dating apps and non-Islamic matchmaking platforms
- Interest-based financial products (Riba)
- Adult content of any kind
- Explicit entertainment
- Tobacco and vaping products
- Any content that conflicts with ZYRA's values or Islamic principles

---

## Long-Term Vision — Curated Sponsorship Platform

The long-term goal is for ZYRA to become a curated sponsorship platform for Muslim-friendly businesses — not an automated advertising network.

This matters because:
- Curated sponsors are vetted against ZYRA's values before going live
- Advertisers reach a trusted Muslim audience, not a generic one
- Local businesses can reach their own communities affordably
- ZYRA retains editorial control over every placement

### Sponsorship Tiers (Future)

| Tier | Scope |
|------|-------|
| Local Sponsor | Single city or postcode area |
| Regional Sponsor | Multi-city or county coverage |
| National Sponsor | Full UK (or target market) coverage |
| Exclusive Category Sponsor | Category exclusivity within a geography |

### Pricing Dimensions (Future)
Pricing will scale across:
- Geographic coverage
- Monthly impressions delivered
- Campaign duration
- Category exclusivity rights

### Local Targeting Architecture Requirement
User location must be captured and stored at signup — even before local targeting is implemented. Retrofitting location data onto an existing user base is significantly harder than capturing it from the start. This is a **Day 1 data architecture requirement**, not a Phase 3 concern.

### Category Exclusivity Enforcement
If a sponsor holds exclusive category rights within a geography, the system must guarantee no competing category ads are served to users in that area during the campaign period. This is a **contract commitment enforced at the data layer**, not a UI configuration.

---

## B2B Product Note

The Local and Regional sponsorship tiers require a sponsor portal — a separate product surface with:
- Campaign creation and management
- Geographic targeting configuration
- Impression and engagement reporting
- Renewal and billing management

This portal is a future build. It should be named and scoped now so it is not designed as an afterthought when Phase 3 begins.

---

## Governance

This document is a governed business rule. All advertising providers — network or direct — must be evaluated against this standard before onboarding.

Changes to the Accepted or Rejected categories require review by the Lead Architect and sign-off from the product owner.

The frequency cap (currently: ~10 profile interactions) is a governed product constant reviewed quarterly against retention and engagement data.

---

*Cross-reference: Subscription Transparency Standard · Dependency Communication Principle · AI Tiering*
