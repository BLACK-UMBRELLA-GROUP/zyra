# ZYRA — Technical Architecture
**Version:** V2
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Governing Reference:** ZYRA_GOVERNANCE_V1, ZYRA_EXECUTION_V1

---

## 1. Overview

ZYRA is a Flutter mobile application for Islamic matchmaking.
Built for iOS and Android from a single codebase.

---

## 2. Technology Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | Flutter (Dart) | Cross-platform mobile |
| Platforms | iOS, Android | Single codebase |
| Backend | Supabase | PostgreSQL + Auth + Storage + Realtime |
| Authentication | Supabase Auth | Email, social, phone (DR-073) |
| Database | Supabase PostgreSQL | Row-level security enforced (DR-073) |
| Storage | Supabase Storage | Profile images, documents (DR-073) |
| State Management | TBD | Pending architectural decision |

---

## 3. Core User Roles

Corrected 2026-07-12 (DR-077): the Connector role is retired.
Seeker and Guardian are the only valid ZYRA user roles.

| Role | Description | Key Permissions |
|------|-------------|----------------|
| Seeker | Person searching for a match | Browse, journey, messaging |
| Guardian | Guardian (female Seekers) | Journey approval, oversight |

---

## 4. Core Feature Areas

### 4.1 Onboarding
- Seeker profile creation
- Compatibility questions
- Profile completion flow

### 4.2 Matching
- Profile Decision System (swipe/browse)
- Compatibility scoring
- Browse page

### 4.3 Journey
- Structured matchmaking process
- Journey availability management
- Journey state machine

### 4.4 Matches & Relationship Space
- Active matches management
- Relationship Space for accepted matches

### 4.5 Premium
- ZYRA One / Guardian+ entitlements (terminology corrected
  2026-07-12 — was "Guardian Premium tier")
- Profile Unlocks
- Subscription management

### 4.6 Safety & Trust
- Safety features
- Content moderation approach
- Guardian (Guardian) integration

---

## 5. Source Code Location

```
BLACK UMBRELLA GROUP/PROJECTS/ZYRA/SOURCE/
├── lib/
│   └── main.dart          ← App entry point
├── ios/                   ← iOS platform files
├── android/               ← Android platform files
├── pubspec.yaml           ← Flutter dependencies
└── test/                  ← Widget tests
```

---

## 6. Open Architecture Decisions

| ID | Decision |
|----|---------|
| DR-073 | Backend: Supabase (PostgreSQL, Auth, Storage) — Approved 2026-06-26 |
| TBD | State management approach — pending |

These will be captured in SYSTEM/DECISIONS_REGISTER/ when resolved.

---

## 7. Version History

| Version | Date | Change |
|---------|------|--------|
| V1 | 2026-06-26 | Initial baseline — stack partially TBD |
| V2 | 2026-06-26 | Backend confirmed as Supabase (DR-073). Stack updated. Open decisions updated. |

---

## 8. Governing References

- ZYRA_GOVERNANCE_V1 — Project governance
- ZYRA_EXECUTION_V1 — Feature workflow
- TERMINOLOGY_STANDARDS_V1 — Product language
