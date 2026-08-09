# ZYRA — Infrastructure Stack

**Version:** V1
**Status:** Approved
**Date:** 2026-07-04
**Owner:** ZYRA Technical Governance
**Source:** Architecture & Governance (ChatGPT), 2026-07-04

---

## Overview

This document records the approved infrastructure stack for the ZYRA platform. This is the current preferred stack. Changes require a formal decision record.

---

## Core Infrastructure

| Service | Role |
|---------|------|
| **Supabase** | Primary database, authentication, real-time subscriptions, row-level security |
| **Flutter** | App framework — single Dart codebase for iOS, Android, and web (corrected 2026-07-18, DR-ZYRA-078 — this row previously said "Expo + EAS / React Native," a drafting inconsistency with the Architecture doc and the actual project scaffold, neither of which ever moved off Flutter) |
| **Resend** | Transactional email delivery (invitations, notifications, system emails) |
| **Vercel** | Web hosting, edge functions, API routes where applicable |
| **Stripe** | Payment processing — ZYRA One subscriptions, Guardian+ subscriptions |
| **RevenueCat** | In-app purchase management — subscription state, entitlement tracking, iOS/Android billing |
| **Cloudflare** | CDN, DDoS protection, DNS, image delivery |
| **GitHub** | Source control, CI/CD integration |

---

## Observability

| Service | Role |
|---------|------|
| **Better Stack** | Log aggregation, uptime monitoring, alerting |
| **Sentry** | Application error tracking, crash reporting, performance monitoring |
| **PostHog** | Product analytics, feature flags, session replay, user behaviour |

---

## AI Observability

| Service | Role |
|---------|------|
| **Langfuse** | AI observability — prompt versioning, token tracking, cost analysis, trace inspection, AI evaluation, production debugging |

### Why Langfuse

Langfuse fills the same role for AI operations that Sentry fills for application crashes. As AI becomes a core platform capability in ZYRA (compatibility scoring, Journey intelligence, Guardian AI Summary, adaptive questions), observability over AI behaviour is essential from the start.

Langfuse specifically provides:
- **Prompt versioning** — track prompt changes and their effect on output quality
- **Token tracking** — monitor consumption per feature and per user segment
- **Cost analysis** — understand AI cost per Journey, per user, per feature
- **Trace inspection** — debug multi-step AI chains (e.g. compatibility calculation + recommendation + Guardian summary)
- **AI evaluation** — measure output quality over time
- **Production debugging** — identify and resolve AI regressions without code changes

Adopting Langfuse early — before AI features are in production — ensures the observability infrastructure is in place when it is needed, not retrofitted after problems emerge.

---

## Architecture Alignment

| Concern | Approach |
|---------|---------|
| Subscription entitlements | RevenueCat manages platform billing; Supabase stores entitlement state for AIOS resolution |
| AI capability resolution | AIOS reads entitlement from Supabase; Langfuse traces all AI resolution calls |
| Notification delivery | Resend (email), native push via Expo (in-app); notification rules in dedicated specification |
| Document storage (profile photos, etc.) | Supabase Storage + Cloudflare CDN |

---

## Deferred Infrastructure Decisions

| Item | Notes |
|------|-------|
| Push notification service | Native Expo push vs. third-party (e.g. OneSignal) — to be decided |
| Video/audio communication | Not in current scope; deferred to Family Stage |
| Search infrastructure | Supabase full-text search initially; may need Algolia/Meilisearch at scale |
| AI model provider | AIOS provider abstraction is in place; specific model selection deferred per feature |

---

*ZYRA Infrastructure Stack — V1 — Approved 2026-07-04*
