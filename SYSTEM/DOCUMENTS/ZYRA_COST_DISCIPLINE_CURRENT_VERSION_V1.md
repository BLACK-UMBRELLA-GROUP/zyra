---
id: DOC-ZYRA-0250
type: STANDARD
status: CURRENT
feature: PRODUCT
purpose: ZYRA COST DISCIPLINE — TESTING AND REAL LIFE
links: []
owner: ZYRA chat
---

============================================================
Black Umbrella Group AI ORGANISATION — ZYRA
============================================================
ZYRA COST DISCIPLINE — TESTING AND REAL LIFE
============================================================
Document Name:    ZYRA cost discipline — what we spend, what we
                  refuse to spend, and the triggers that change it
Scope:            ZYRA (app, Supabase project, supporting estate)
Document Type:    Operating policy (CURRENT_VERSION)
Author:           Fable (Company Operations)
Status:           Filed 2026-08-22 on the Founder's word ("yes do
                  that"), following the Supabase egress
                  investigation (OA-AIOS-344)
Governing:        Accounting architecture P6 (no fake automation /
                  honest phasing); OA-AIOS-344; OA-ZYRA-233
============================================================

1. THE STANDING PICTURE (what ZYRA costs today)
------------------------------------------------------------

  Supabase            Free plan (no card on file — cannot bill)
  Cloudflare          Free (site, admin door, tunnel, Access)
  Google Workspace    Already paid (company email estate)
  AI APIs             Prepaid only: Claude $4.83, OpenAI $5.00 —
                      metered by AIOS, LOW-flagged, hard-capped
                      by what is prepaid
  Push/APNs/FCM       £0 (platform services are free)
  ────────────────────────────────────────────────────────────
  Marginal monthly cost of building ZYRA: £0.

2. WHAT WENT WRONG ONCE (and must not repeat)
------------------------------------------------------------

  Cycle 18 Jul–18 Aug: 16.295 GB uncached egress vs the 5 GB
  free cap — bandwidth, not size (whole bucket: 0.287 GB). The
  same full-size profile photos were re-downloaded ~50x through
  freshly-generated signed URLs (every regeneration busts every
  cache), across 26 test accounts and heavy dev/audit days.
  No money was owed (Free plan cannot charge); the risk was
  throttling (402s) if repeated. Current cycle reset clean.
  Evidence and daily chart: OA-AIOS-344.

3. TESTING RULES (now, all £0)
------------------------------------------------------------

  T1  Land OA-ZYRA-233 (promoted): compress/resize at upload,
      device disk cache (one download per device), reuse
      long-lived signed URLs — never regenerate per render.
      Image Transformations are UNAVAILABLE on Free (verified
      2026-08-22) — the no-cost path is the path.
  T2  Test accounts wear tiny photos (~20 KB placeholders).
      Synthetic Seekers do not need portraits; they need pixels.
  T3  Iterate locally, verify remotely: the Supabase CLI local
      stack runs migrations and SQL suites for free; the live
      project is for final verification. Codex's call on timing.
  T4  Narrow queries, never whole-table dumps — applies to every
      seat, including Fable's probes.
  T5  Prefer one test account on image-heavy screens over
      cycling many.
  T6  The meter is the truth: Fable checks the usage page weekly
      during heavy development and flags the Founder at ~50% of
      any cap mid-cycle.

4. REAL-LIFE RULES (launch and after)
------------------------------------------------------------

  R1  Photos are a dating app's entire bandwidth bill. Standing
      architecture: every upload compressed to ~150–200 KB;
      cards serve thumbnails; full image only on profile open;
      device caching everywhere. Built once, scales forever.
  R2  Pay only when users exist. The free tier's real ceilings
      (5 GB egress, 500 MB database) are fine for testing and
      impossible for a live app. The one planned upgrade is
      Supabase Pro (~$25/mo, 250 GB egress) — TRIGGER: real
      users arriving at launch, ideally alongside revenue.
      Never upgrade to make a warning banner go away.
  R3  Stay on genuinely-free rails: APNs/FCM push, Cloudflare
      front, AIOS as the ops/analytics surface instead of paid
      dashboards.
  R4  AI stays out of the request path. Matching is SQL (already
      true). Any future AI feature runs batched, budgeted, and
      inside AIOS's OPF spend guardrails.
  R5  Known fixed cost to plan, not fear: Apple Developer
      Programme (~$99/yr) when App Store submission is real —
      it belongs in the Budgets view in advance.
  R6  Honest phasing (accounting architecture P6) governs every
      new connector or service: a cost becomes real only when
      its prerequisite is real. No spend ahead of its trigger.

5. TRIGGERS THAT REOPEN THIS DOCUMENT
------------------------------------------------------------

  - Any cycle crossing 50% of a free cap mid-development
  - Launch decision (activates R2 and R5 planning)
  - First revenue (re-baselines what "cheap" must mean)
  - Supabase plan/pricing changes

============================================================
END OF DOCUMENT
============================================================
