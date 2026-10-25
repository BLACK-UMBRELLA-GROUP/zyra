# ZYRA UI Consistency Gate — Initial Baseline Audit

**Date:** 2026-08-24  
**Programme:** OA-ZYRA-257 · **Decision:** DR-ZYRA-214  
**Technical owner:** Codex · **Product/design authority:** Fable · **Baseline authority:** Founder  
**Measured run:** `13353577` · source fingerprint `408f6cf300091e03`  
**Verdict:** **BASELINE-PENDING** — the technical gate passes; no screenshot is approved yet and recurring execution remains off.

## Executive result

- All deterministic and functional layers passed: formatter, Flutter analyzer, `zyra_check`, 44 representative render variants and the complete 224-test Flutter suite.
- Forty-four candidate screenshots were produced with locally bundled Jost/Syne test fonts. They are review evidence only, never baselines.
- The L2 ledger has **0 open regressions**. Ten setup-time findings are retained as resolved history, including test-font false positives and checker-parser defects.
- L1 reports **153 live review findings**: 0 critical, 0 high, 13 medium and 140 low. These are mainly duplication/token/copy inventory candidates and remain for Fable triage; the gate did not redesign, rewrite or delete anything.
- Cost was **$0.00**, duration **30.0 seconds**, AI calls **0**. An unchanged-tree invocation skipped in 0.2 seconds at $0.00.

## 1 · Current-state consistency audit

| Layer | Measured result | Truth boundary |
|---|---|---|
| L1 deterministic | PASS-WITH-FINDINGS · 153 live | Findings are review candidates, not automatic product decisions. |
| Formatting | PASS · 193 Dart files checked | Thirteen formatter-only corrections were applied before the final run. |
| Flutter analyzer | PASS · no issues | Current Dart/Flutter compilation analysis is clean. |
| Structural/reference checker | PASS | Three false-positive classes were corrected and regression-tested. |
| L2 render | PASS · 44/44 variants | Overflow/layout exceptions absent with real approved typography metrics. |
| Candidate capture | PASS · 44 PNGs | Candidate-only; 0 approved baselines. |
| Flutter suite | PASS · 224 tests | Includes 45 visual-harness tests plus 179 existing non-visual tests. |
| Recurring run | OFF | Cannot be enabled before Fable review and Founder baseline approval. |

L1 rule distribution:

| Rule | Count | Audit meaning |
|---|---:|---|
| UIG-09 | 123 | Cross-file duplicate/canonical-copy candidates. |
| UIG-07 | 10 | Developer wording sites requiring release-boundary review. |
| UIG-10 | 9 | Unreferenced UI/reachability candidates. |
| UIG-11 | 9 | Component/class inventory findings. |
| UIG-03 | 8 | Raw typography-size use outside the canonical API. |
| UIG-02 | 5 | Colour/token drift candidates. |
| UIG-04 | 3 | Radius/dimension drift candidates. |
| UIG-05 | 1 | One-off component dimension candidate. |

The permanent evidence is `REPORTS/ZYRA_VISUAL_AUDIT_2026-08-24_13353577.md` and the deduplicated ledgers are `visual_state.json` (L2) and `state.json` (L1).

## 2 · Design-token inventory

`INVENTORIES/DESIGN_TOKEN_INVENTORY.json` records:

- 51 named colour/gradient observations from the live token sources.
- 11 typography API entries from `zyra_text.dart`.
- 6 canonical card metrics.
- 10 observed usage categories covering radii, spacing, icon sizes, button heights, durations, curves, font sizes, gradients, shadows and borders.
- 2 explicit gaps requiring design authority rather than automated replacement.

Canonical source files are `lib/theme/zyra_colors.dart`, `lib/theme/zyra_text.dart` and `lib/theme/zyra_card_metrics.dart`. Observed values do not become approved tokens merely by appearing in the inventory.

## 3 · Component inventory

`INVENTORIES/COMPONENT_INVENTORY.json` records 43 shared-widget entries, use counts, configured contract status and replacement where governed. Twelve component contracts are currently explicit in `ui_gate_config.json`; unknown widgets remain observed rather than silently approved. No duplicate same-named widget classes were detected.

## 4 · Terminology and copy inventory

`INVENTORIES/TERMINOLOGY_COPY_INVENTORY.json` records 10 approved terms, 5 retired terms with replacements, 5 review-only developer expressions and 205 cross-file duplicate-string candidates. The checker flags copy for review and never rewrites product language.

## 5 · Screenshot/state matrix

`state_matrix.json` covers all 20 Founder-required key screen families. The risk-based render subset has 12 fixtures and 44 variants across:

- Female Seeker, Male Seeker and Guardian.
- ZYRA Basic and ZYRA One.
- small 320×568, standard 390×844 and large 430×932 phones.
- normal text and focused 130% accessibility text.
- long names, long locations, large copy and six linked Seekers.
- normal, empty, loading, error, locked, upgrade, disabled and expanded states in the current render set.

Six key screen families have dedicated render fixtures now: Authentication, Onboarding, Guardian Dashboard, Guardian Network, Notifications and Subscription/upgrade. The other 14 are truthfully labelled `existing-widget+static`; dedicated approved screenshots remain an activation/steady-state expansion, not claimed coverage.

## 6 · Visual-regression and golden framework

`SOURCE/test/visual/zyra_visual_regression_test.dart`:

- Renders real current widgets, not painted mock screenshots.
- Applies deterministic role, plan, device, text-scale and stress data.
- Loads repository-pinned Jost/Syne binaries directly for readable, stable evidence without network access or changing production font behaviour.
- Fails on Flutter layout exceptions/overflow.
- Compares only entries explicitly present in `test/visual/approved/manifest.json`.
- Writes only to `test/visual/candidates/` when candidate capture is explicitly enabled.

`SOURCE/tools/zyra_visual_gate.py` orchestrates fingerprinting, inventories, L1, formatting, analyzer, `zyra_check`, render tests, candidate capture and the optional full suite. Stable fingerprints update occurrences and close verified findings rather than creating nightly duplicates.

## 7 · Duplicate/dead UI report

`INVENTORIES/DUPLICATE_DEAD_UI_REPORT.md` records 10 unreferenced/reachability candidates and no duplicate widget names. `NotificationBell` and `FabContinueButton` are classified as retired candidates with replacements; eight other files remain high-risk intent-unknown candidates. Nothing was deleted or archived automatically.

## 8 · Developer-toggle consistency

`INVENTORIES/DEVELOPER_TOGGLE_INVENTORY.json` confirms:

- Current architecture: `ZyraDevScenario`, `ZyraDevSurfaceCoordinator`, `ZyraGlobalDevOverlay` and `GNContext/GNScene/GNStage`.
- Four developer-control groups are present.
- Reset handling and release guards are detected.
- Four current verification-test sites are recorded.
- No retired Guardian Network terminology hits remain in live developer controls.

The six-linked-Seeker fixture passes at all three device sizes and 130% text, providing measured count/overflow evidence for the current Guardian slider. This is not an exhaustive semantic proof for every toggle; expansion remains matrix-driven.

## 9 · AIOS dashboard

AIOS now exposes `/ui-consistency` in the ZYRA workspace. It reads evidence only and provides:

- last run, verdict, render count, new/open/resolved counts, critical/high count, role/device coverage, cost and history trend;
- permanent reports, inventories, matrix, baseline manifest and related OA;
- candidate/approved screenshot comparison (or an explicit no-baseline state);
- per-finding evidence, expected/actual, impact, correction, owner, status and occurrence history;
- safe source-file access confined to ZYRA.

It deliberately provides no baseline approval, promotion, finding closure or scheduling action. Four focused dashboard/security tests pass.

## 10 · Run frequency and cost model

| Trigger | Layers | Cost rule |
|---|---|---|
| After UI-affecting implementation | L1 + focused L2; full suite when risk warrants | Local $0.00 |
| Before UI feature completion | L1 + L2 + analyzer/structural checks | Local $0.00 |
| Before release | Full L1/L2/functional suite | Local $0.00 |
| Overnight after activation | Run only if the UI fingerprint changed | Skip unchanged at $0.00; no AI |
| New unexplained finding | L3 interpretation only | Must use an approved governed budget and record provider/model/tokens/cost |

No recurring job has been created or enabled. The current overnight pause and all engine budget/scheduling controls remain unchanged.

## 11 · Baseline and finding governance

1. Candidate PNGs are unapproved evidence.
2. A changed render cannot update an approved baseline.
3. Codex explains the difference and supplies evidence.
4. Fable checks product/design intent and files/updates register truth.
5. Founder approves where the governing rule requires it.
6. The new baseline receives screen, state, role, plan, device, date, approver, governing reference, version and SHA-256 metadata.
7. The prior version is archived; it is never silently overwritten.
8. Stable finding fingerprints retain first/last seen, count and status. Reports are evidence; OA-ZYRA-257/register actions are the queue.

## 12 · Activation plan

The technical implementation is complete but activation is intentionally blocked:

1. Fable reviews the 44 candidates, inventories, L1 triage and this audit against current product/design authority.
2. Any genuine design/copy/component finding is filed or updated in the register; false positives receive explicit suppressions with reviewer/reason.
3. Founder approves the initial baseline set after any required corrections.
4. Approved PNGs are versioned and both baseline manifests are populated with full governance metadata and hashes.
5. Codex runs a first approved-comparison pass; it must pass without replacing a baseline.
6. Fable reconciles the CURRENT_VERSION gate document phase/status tables with the as-built implementation.
7. Only then may an authorised engine change enable the change-gated recurring run.

No migrations were created or applied. No product/design decision was automated.
