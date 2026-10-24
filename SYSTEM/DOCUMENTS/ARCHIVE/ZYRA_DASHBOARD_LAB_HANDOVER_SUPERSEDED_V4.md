# ZYRA Dashboard Lab — Implementation Handover

**Version:** V4  
**Status:** SUPERSEDED — replaced by `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V5.md` on 2026-08-25  
**Date:** 2026-08-25  
**Implementer:** Codex, Lead Architect  
**Authority:** Founder instruction, 2026-08-25: retain Sectioned Status, replace the other five Dashboard options with five variations of that model, and apply the same model family to Seeker and Wali with role-specific content  
**Supersedes:** `SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_DASHBOARD_LAB_HANDOVER_SUPERSEDED_V3.md`  
**Related rules:** `ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md` · `ZYRA_LEARNING_LOOP_DATA_AUDIT_CURRENT_VERSION_V1.md`  
**Production relationship:** developer-authorised comparison layer; no model has been promoted as the production Dashboard

> Historical evidence only. V5 is the current implementation authority and
> adds the shared Dashboard colour-treatment comparison.

## 1 · What was built

The Dashboard Lab now contains one coherent six-option design family:

1. **Sectioned Status** — the existing balanced section, status-bar and compact-action model.
2. **Priority Sections** — the same sections with one stronger first-priority card.
3. **Compact Sections** — the same information hierarchy in denser rows.
4. **Progress Sections** — section containers where progress and stage movement are the strongest visual signal.
5. **Card Sections** — one contained glass panel per section.
6. **Guided Sections** — the same sections presented as a numbered vertical path.

The retired Journey Command Centre, Modular Personal Hub, Layered Story,
Interactive Canvas and Calm Daily Overview options no longer exist in the
model enum, renderer, developer controls or live visual fixture matrix.

The purpose is controlled comparison: the Founder can test variations without
changing the Dashboard's information architecture each time. All six options
share the same modules, action routing and role adaptation.

## 2 · Shared model, role-specific content

The renderer builds one internal section map from the selected account role.

| Section purpose | Seeker label/content | Wali label/content |
|---|---|---|
| Setup | **Finish setting up**; remaining onboarding answers | Not shown |
| Primary | **Your Journey**; active Journey and next step | **Seekers & Journeys**; next decision, Journeys and supported Seekers |
| Learning | **What ZYRA is learning** developer mock | Not shown; Seeker-only rule retained |
| Updates | **New for you**; activity, family progress and milestone | **Family activity**; Seeker submission, family introduction and stage milestone |
| Tools | **Explore**; Discovery, Saved, Compatibility and Profile | **Guardian tools**; Guardian Network, Profile, Discovery, Saved and Compatibility |

This means Seeker and Wali use the same six visual models while receiving
different truthful information and actions. It is not a copy of Seeker data
inside the Wali shell.

## 3 · Architecture and data flow

```text
Authorised developer
      ↓ Dashboard Action Control
ZyraDashboardLabControls
      ↓ one in-memory ZyraDevScenario
ZyraDashboardViewConfig
      ↓ concept + role + scenario modules
ZyraDashboardExperience
      ↓ one shared role-aware section map
      ├── Sectioned Status
      ├── Priority Sections
      ├── Compact Sections
      ├── Progress Sections
      ├── Card Sections
      └── Guided Sections
              ↓
existing Seeker/Wali destination callbacks
```

`ZyraDashboardExperience` receives plain configuration and callbacks. It does
not read Supabase and does not persist the selected model. The same renderer
is mounted by both account shells; the host supplies its real destinations.

## 4 · Developer controls

Open either role's **Dashboard**, then open **Action Control → Dashboard Lab**.

Available controls:

- six Sectioned Status family choices;
- Current account, Seeker or Guardian preview;
- activity, Journey, learning, onboarding and family scenario states;
- module visibility and section-relative ordering; and
- one reset that restores Sectioned Status and the documented representative state.

The retired **Hero card** and module-size controls were removed because no
current section model consumed them consistently. Every remaining control has
a live reader.

## 5 · OA-ZYRA-259 learning mock retained

The Seeker-only mock still supports insufficient-data, positive, neutral and
preference-review examples plus Basic/ZYRA One depth. It remains labelled
**MOCK INSIGHT**, uses widget-local feedback only, does not infer from account
history, does not rewrite preferences and does not affect recommendations.

All six Seeker models place the learning module within the shared section
hierarchy. Every Wali model excludes it. The existing production-hub preview
path remains separately developer-gated when Dashboard Lab is off.

## 6 · Mock versus production

| Area | Dashboard Lab | Production |
|---|---|---|
| Selected layout | Session-only developer choice | No new model ratified |
| Role content | Deterministic Seeker/Wali examples | Existing account data adapters remain authoritative |
| Module order/visibility | Session-only comparison controls | Not written to member settings |
| Learning | Mock states and local responses | Automated conclusions inactive |
| Entitlements | Visual examples only | Existing entitlement rules unchanged |
| Backend | No reads or writes added | No schema/RPC/RLS/auth change |

## 7 · Live files and SHA-256

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | Six current concepts, roles, modules and immutable config | `c064c1f52cc275f0a53be9b875b0b12be1d6149dfa879ad655bae1cf26106c5b` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | Shared in-memory state and complete reset | `0e99781d80da376c87713e4029cb82b5c17bfe8173fc6bbabd5c5f4a2ffb8ef6` |
| `SOURCE/lib/dev/zyra_dashboard_lab_controls.dart` | Six-model comparison and live scenario controls | `f7e776b27fee583503ef43a6ee01c2d2560aeda8da77392e99200949719bdc4a` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | Shared role section map and six renderers | `7301635e69b1570d2329059747a0df504149f346be47fd552443b846ee268432` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | Seeker host and existing-hub learning preview | `14f52050b727696e674f954ea418d098a603248a39c65fe08c486abfc63a6681` |
| `SOURCE/test/dashboard_lab_test.dart` | Six-option contract, role parity, controls and learning behaviour | `f8c869aed61499094cfc9122fe40ca81a15590843037639a5fa38d654de7d020` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | Existing Seeker host and developer-boundary checks | `51f488209f5ed6adff5841ea064e941af0b80ab5b2ceec509af470638c5a57ca` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Seeker/Wali phone-matrix render fixtures | `aed0174cbc51d9488c4e8023918d8ac1da29d0bb65cef31b38114befb005c288` |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | Current six-model visual inventory | `f5f58aab7c6bca90bf7c285277ff6305bcc8d754c291815ccaf58fdd1b3b259d` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/manifest.json` | Candidate-only screenshot inventory | `5a9600a13bbd78faa7e45d0f734376427f1d6ba82aa7f07c73d9d59e3763f552` |
| `SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_VISUAL_AUDIT_2026-08-25_cbf078d8.md` | Passing local visual-gate evidence | `5bba747540bfed8f741bf46b29153b329173d83a48cb060eadcaf6676f8d7191` |

This handover omits its own hash because embedding it would change that hash.

## 8 · Measured verification

| Measurement | Result |
|---|---|
| Formatting gate | PASS · 203 Dart files checked · 0 changed |
| Focused Dashboard + Seeker host suite | PASS · 30/30 |
| Dashboard concept × role matrix | PASS · all six concepts on Seeker and Wali at 320×568 |
| Visual fixture test | PASS · 118/118 test cases; 117 screen variants at 320×568, 390×844 and 430×932 |
| Full repository suite | PASS · 339/339 |
| Static analysis | PASS · no issues |
| iOS debug build | PASS · `build/ios/iphoneos/Runner.app` |
| Local UI gate | BASELINE-PENDING · every deterministic/render check passed; 0 open L2 findings; 0 approved baselines |
| Physical iPhone review | PENDING · Founder installs through `run.sh` |

Candidate screenshots are evidence only. Codex did not approve or promote a
golden baseline; that remains under OA-ZYRA-257.

## 9 · Retired implementation and archive locations

- Previous as-built authority:
  `SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_DASHBOARD_LAB_HANDOVER_SUPERSEDED_V3.md`.
- Thirty candidate screenshots for the five retired mixed models:
  `SYSTEM/RESOURCES/UI_GATE/ARCHIVE/RETIRED_DASHBOARD_MODELS_2026-08-25/`.
- Current candidate directory contains 117 current screen variants and no
  retired Dashboard model names.

## 10 · Migrations

No migration was created or applied. No database schema, RLS policy, RPC,
trigger, Storage rule, authentication state, entitlement or persisted member
preference changed.

## 11 · Known limitations and remaining work

1. The Founder must compare the six options on a physical phone and select or
   refine a direction; this handover does not self-approve one.
2. Visual candidates remain unapproved until OA-ZYRA-257 baseline governance
   is completed.
3. Dashboard role examples are deterministic Lab data; production adapters
   are unchanged.
4. OA-ZYRA-259 production learning remains inactive pending approved evidence,
   privacy, wording and entitlement rules.
5. Fable must verify this V4 handover against disk and reconcile the related
   documentation/register trace.

## 12 · Authority and archive state

This V4 file is the only current Dashboard Lab as-built authority. V1–V3 are
archived and marked superseded. The production Seeker Dashboard handover still
owns the ordinary live hub; the learning-loop documents still own proposed
learning rules and measured data feasibility.

No git command was run. Codex did not self-approve a layout, baseline,
entitlement rule or production learning system.

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-24 | Added five role-aware Dashboard comparison concepts. |
| V2 | 2026-08-25 | Added Sectioned Status, specific events, onboarding progress and correctness cleanup. |
| V3 | 2026-08-25 | Added OA-ZYRA-259 P1 learning mocks, response controls, Basic/One preview and data-audit linkage. |
| V4 | 2026-08-25 | Retired the five mixed models; created five Sectioned Status variations; enforced Seeker/Wali role parity; removed stale controls; refreshed tests, visual fixtures and evidence. |
