# ZYRA UI Consistency & Visual Regression Gate

**Document:** ZYRA_UI_CONSISTENCY_GATE_CURRENT_VERSION_V1.md
**Status:** CURRENT_VERSION — the governed system for detecting visual, copy, component and parity drift across ZYRA. Founder-directed 2026-08-23 (22-section directive, received in chat; this document is its governed form and maps every section — the numbers in brackets, e.g. [§16], are the directive's own).
**Date:** 2026-08-23 · **Owner:** Founder · **Author:** Fable
**Register:** OA-ZYRA-257 (programme) · DR-ZYRA-214 (adoption decision)
**Authority split [§1]:** Fable = product/design authority and register filing. Codex = technical implementation, automated checks, screenshots, comparisons, evidence. The system itself decides NOTHING — it measures, reports and queues.

**Objective:** Codex can add features quickly without ZYRA slowly becoming inconsistent. Every build inherits the current design language automatically; every regression is visible; every approved change updates the baseline deliberately; no duplicate UI systems; no silent visual drift; the Founder never has to discover basic inconsistencies manually on the phone.

---

## 1 · Architecture — three layers, cheapest first [§1, §18]

| Layer | What | Runs | Cost | Owner |
|---|---|---|---|---|
| **L1 Deterministic** | `SOURCE/tools/zyra_ui_gate.py` — token lint, colour/radius/height drift, retired terminology, dev-wording leaks, duplicate strings, orphan/duplicate widgets, £-price budgets, banned APIs. Change-gated: skips itself when no `lib/**.dart` changed. | Every UI change; overnight; pre-release | **$0.00** | Fable (built, live 2026-08-23) |
| **L2 Render & compare** | Flutter golden/screenshot tests over the representative matrix (§4); pixel comparison against approved baselines; overflow assertions; dev-toggle count-vs-render checks. | After UI-affecting changes; pre-release; overnight only when L1 detects change | **$0.00** (local flutter test) | Codex (to build — brief issued with this doc) |
| **L3 Interpretation** | AI review ONLY of L1/L2 findings that genuinely need judgement: expected-approved-change vs genuine regression vs baseline-needs-approval vs inconclusive [§7]. Never full-repository reasoning on a schedule. | Only when L1/L2 produce new unexplained findings | Budgeted per engine stage rules | Codex via the Execution Engine |

Trigger rules [§2]: required after any UI-affecting implementation, before a UI feature is marked complete, before a release build; overnight ONLY when relevant files changed since the last successful audit (L1's tree fingerprint is the change detector — no change, no spend).

## 2 · Sources of truth [§3]

The audit compares the app against, in order: approved CURRENT_VERSION documentation; the canonical design system (`lib/theme/zyra_colors.dart` — 60+ named tokens, `zyra_text.dart`, `zyra_card_metrics.dart`); approved terminology (ZYRA_PRICING V2 names/prices, GN spec Rule 42 naming set, retired-terms list inside the gate tool); approved baseline screenshots (once §5 creates them); production-intended behaviour. An old screenshot is never authoritative merely because it exists. Every approved baseline records: screen · state · role · plan · device size · date approved · governing document · baseline version [§3].

**Founder visual rule reaffirmed 2026-09-30:** no heart icon anywhere in the
app, including onboarding art, Browse/Consider actions, dashboard indicators,
compatibility and developer previews. Keep each action's meaning, label and
route; replace only the icon with a context-appropriate neutral symbol. The
deterministic Flutter-source guard is `SOURCE/test/no_heart_icons_test.dart`;
image assets and candidate app icons require visual inspection as well. This
rule supersedes historical references that prescribed a heart icon; it does
not alter Consider, Save, Match or Journey semantics.

## 3 · What each layer checks (directive mapping)

**L1 today (rules UIG-01…11):** token sources [§4]; hard-coded colours vs tokens, cross-file colour duplicates, token-shadowing literals [§4]; raw fontSize outside ZyraText [§4]; one-off radii and button heights with full histograms [§4]; retired terminology + the £9.99-appears-once budget [§8]; dev wording outside `lib/dev` flagged verify-gated [§8, §13]; duplicate long strings [§8, §9]; orphan/unreachable dart files [§9]; same-named widget classes in multiple files [§5, §9]; banned APIs (withOpacity/withAlpha).

**L2 to build (Codex):** the screenshot matrix [§6] — roles (Female Seeker · Male Seeker · Guardian) × plans (Basic · One) × states (normal/empty/loading/error/locked/upgrade/disabled/selected/expanded/paused/ended) × key screens (auth, onboarding, Browse, Saved, Activity, Connections, Introductions, Guardian section/Dashboard/Network, Journey states + Timeline, Notifications, Profile, Settings, Subscription, Help) × devices (small/standard/large phone) × text scale (normal/large) + stress data (long names, long locations, large counts, multiple Seekers). Risk-based representative suite, not every permutation nightly [§6]. Detections [§7]: overflow, clipping, safe-area escapes, misalignment, inconsistent card heights/padding/margins/button heights, nav size changes, contrast, seams, wrapping, loading-vs-loaded layout shift, Male/Female divergence, stale Guardian styling. Plus [§13]: every dev toggle maps to current architecture, reset returns to approved zero, toggle-created counts match rendered counts (10 staged = 10 rendered or the test fails). Plus [§14]: goldens run WITH flutter analyze, dart format check, the existing suite, zyra_check and the reference checker — a pretty screenshot alone never marks a screen ready.

**L3 rules [§7, §17]:** classify only; propose only. Automatic changes are limited to proven, deterministic, reversible corrections (formatting; governed literal conventions; verified-safe unused-import removal). Never automatic: redesigns, product copy, pricing, entitlements, permissions, flows, baseline replacement, deleting ambiguous components.

## 4 · Parity and accessibility [§11, §12]

Cross-role/cross-plan comparisons (Female vs Male Seeker, Seeker vs Guardian, Basic vs One, one vs many Seekers) flag missing screens, old designs, wrong permissions, wrong plan promotions, role leakage and unjustified divergence — using the approved Seeker experience as reference without blind copying. Accessibility checks ride the L2 matrix: contrast, touch targets ≥ standard minimums, dynamic type, screen-reader labels, focus order, destructive-action clarity, no colour-only meaning, reduced motion, no essential long-press-only interactions.

## 5 · Baseline governance [§19, §21]

A changed screenshot NEVER auto-replaces a baseline. Process: change detected → Codex explains the difference → Fable checks product/design intent → Founder approves where required → new baseline versioned → old baseline archived → governing document updated. **No recurring run is enabled before**: current-state audit done (✔ first L1 run 2026-08-23), token/component inventories curated, existing screenshots classified, the state matrix built, an initial full baseline audit presented, and Fable/Founder approve the baseline [§21]. A regression system is never built against an unverified current state.

## 6 · Findings, dedup and reports [§15, §16]

Every run writes a permanent report to `SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_UI_AUDIT_<date>_<runid>.md` — verdict, source-tree fingerprint, files changed, checks run, findings by severity (🔴 broken flow/privacy/production dev control · 🟠 major inconsistency/overflow/wrong entitlement/component · 🟡 copy/spacing/duplicate/accessibility · 🟢 polish), new/reopened/resolved/suppressed, duration, cost. Findings carry a **stable fingerprint** (rule + file + key, line-independent); the ledger in `state.json` tracks first-seen/last-seen/occurrence-count/status so the same issue is never re-filed nightly [§16]. The report is evidence; **the OA register is the queue** — Fable graduates genuine findings to OAs, and `suppressions.json` records reviewed false-positives by fingerprint with reviewer and reason. Cost tracking [§18] rides the existing AI-usage telemetry (run/session/provider/tokens/cost) plus per-report counts; deterministic runs report $0.00 by construction.

## 7 · AIOS dashboard [§20]

Phase P4 adds a UI Consistency area to the AIOS workspace reading `state.json` + reports: last run, verdict, screens checked, new/open/resolved regressions, critical-high counts, role/device coverage, cost, trend; opening screenshot comparisons, finding detail, source file, governing rule, related OA, prior occurrences.

## 8 · First-run truth (2026-08-23, run 1daa7708) and phases [§21, §22]

First L1 audit: **PASS-WITH-FINDINGS — 178 findings (0 critical, 0 high, 41 medium, 137 low), 154 files, 0.3s, $0.00.** Zero high confirms the recent governance held (no retired terms user-facing, price budgets clean, banned APIs absent). The mediums are real drift: token-shadowing colours (e.g. `connections_screen` hard-codes the primaryAction purple 5×; `glass_icon_button` hard-codes frost tokens), unregistered colours used across 3–5 files (one gold literal 54 uses across 5 files), 9 raw fontSizes (3 in the new GN files), dev-wording strings to verify as gated, and 8 orphan-file candidates including the retired `notification_bell.dart`.

| Phase | Work | Owner | Exit |
|---|---|---|---|
| **P0 ✔ done** | This spec · L1 tool live · first audit · registers · Codex brief | Fable | This document |
| **P1** | Triage run 1daa7708: fix or suppress every finding class; curate token + component + terminology inventories [§22 items 2–4] from tool output | Fable (+Founder on naming) | Inventories filed; L1 verdict CLEAN-or-suppressed |
| **P2** | L2 golden/screenshot harness + state matrix runner + dev-toggle validation | Codex | Matrix runs locally; first baseline set captured |
| **P3** | Baseline review & approval; enable overnight change-gated run (engine job) | Founder + Fable | Approved baseline v1; recurring run armed |
| **P4** | AIOS dashboard area | Fable | Dashboard live |
| **P5** | Steady state: gate required per §2 triggers; L3 on demand | All | — |

— END — Fable re-verifies this document against the live tool and reports at every meaningful change (IMPLEMENTATION_HANDOVER_STANDARD applies). —
