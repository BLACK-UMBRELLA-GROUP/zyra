# ZYRA Dashboard Lab — Implementation Handover

**Version:** V3  
**Status:** SUPERSEDED — replaced by `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V4.md` on 2026-08-25  
**Date:** 2026-08-25  
**Implementer:** Codex, Lead Architect  
**Authority:** Founder Dashboard instructions, 2026-08-24 to 2026-08-25; OA-ZYRA-259 P1 brief  
**Supersedes:** `SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_DASHBOARD_LAB_HANDOVER_SUPERSEDED_V2.md`  
**Rules source:** `ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md` (Fable draft; Founder ratification pending)  
**Data audit:** `ZYRA_LEARNING_LOOP_DATA_AUDIT_CURRENT_VERSION_V1.md`  
**Production relationship:** Developer-only comparison/mocking layer; no concept or learning conclusion is promoted to production

> Historical evidence only. This version describes the retired mixed-model
> comparison Lab. It is not the current implementation authority.

## 1 · What exists

The shared Dashboard Lab still offers the six role-aware compositions described
in V2:

1. Journey Command Centre
2. Modular Personal Hub
3. Layered Story
4. Interactive Canvas
5. Calm Daily Overview
6. Sectioned Status

Sectioned Status remains the lower-reading-load option with **Finish setting
up**, **Your Journey**, **New for you** and **Explore** sections, concrete event
copy, status bars and icon-led actions. The previous Browse-gate, developer
failure-bar and reset-isolation correctness fixes remain intact.

V3 adds OA-ZYRA-259 P1 as a compact **What ZYRA is learning** module. This is
an extension of the existing Dashboard, not a new Dashboard and not an
analytics page.

## 2 · Learning mock states

The developer controls can select:

- **Insufficient information** — no conclusion is shown without enough
  separate evidence.
- **Positive pattern** — demonstrates constructive recurring-alignment copy.
- **Neutral pattern** — demonstrates observation without claiming causality.
- **Preference review** — demonstrates a review invitation without changing a
  preference.

Every card is visibly labelled **MOCK INSIGHT** and names its preview plan.
Copy explicitly states that evidence rules are not yet approved. The location
example says it is a mock search; the data audit confirms that current free-text
location cannot support that conclusion in production.

The mock actions are:

- **This feels accurate** — records local UI acknowledgement only;
- **Not relevant** — hides the card locally;
- **Review my preferences** — can open the existing Profile/preferences
  destination supplied by the host;
- **Show me why** — expands a non-identifying aggregate explanation; and
- **Don't show again** — demonstrates family suppression locally.

All feedback is in widget memory. Dismissal/confirmation does not survive a
rebuild, does not write user data and does not alter recommendations.

## 3 · Basic and ZYRA One preview

- **ZYRA Basic:** one highest-priority mock insight.
- **ZYRA One:** one primary mock insight plus two supporting pattern previews
  after user expansion.

This is a design comparison only. It neither reads nor changes the account's
entitlement. The data audit records the unresolved conflict between the Fable
draft (one useful Basic insight) and Product Spec V5 §6 (ZYRA Intelligence is
not available on Basic). Production tiering is blocked until the Founder
ratifies one rule and Fable reconciles the Product Spec.

## 4 · Existing-Dashboard integration

The mock is testable in both relevant developer contexts:

1. **Dashboard Lab on:** Sectioned Status renders the learning section between
   Journey and New for you. Other compositions retain their existing module
   behaviour.
2. **Dashboard Lab off + Show on current Dashboard on:** the existing Seeker
   Dashboard hub keeps Notifications, Connections and Guardian, and adds one
   compact learning card in the same visual language.

Ordinary users never receive the mock. The existing Dashboard receives it only
inside the developer-authority boundary. Guardian rendering excludes the
learning module entirely.

## 5 · Architecture and data flow

```text
Authorised developer
      ↓ Dashboard Action Control
ZyraDashboardLabControls
      ↓ mutates one in-memory ChangeNotifier
ZyraDevScenario
      ↓ state + preview plan
      ├── Lab on  → ZyraDashboardExperience / selected composition
      └── Lab off → existing SeekerDashboardScreen hub
                          ↓
              ZyraDashboardLearningPreviewCard
                          ↓
           local-only explain / confirm / dismiss controls

Ordinary account
      ↓
existing production Dashboard hub only; no learning mock/inference
```

`ZyraDashboardLearningPreviewCard` accepts a plain state, plan and optional
navigation callback. It does not import the developer singleton, Supabase or
any service. The caller owns the developer gate. This keeps the eventual
production adapter replaceable without embedding mock access in the card.

## 6 · Developer controls

Open **Dashboard → Action Control → Dashboard Lab**.

Under **Personalised learning · mock only**:

- choose Basic or ZYRA One;
- choose insufficient, positive, neutral or preference-review;
- keep **Show on current Dashboard** enabled, then turn Dashboard Lab off to
  inspect the card within the existing production-hub layout; or
- keep Dashboard Lab on and choose Sectioned Status to inspect the sectioned
  composition.

Reset Dashboard Lab restores positive + Basic and enables the current-hub
preview. The control copy states that no production inference runs.

## 7 · Mock versus production

| Area | P1 developer mock | Production |
|---|---|---|
| Insight source | Selected in memory | Inactive; no aggregator exists |
| Evidence | Example-only copy | Must meet ratified thresholds and server-side anonymity rules |
| Confirmation/dismissal | Widget-local | No persistence built |
| Preferences | Never changed | Explicit user edits remain authoritative |
| Recommendation ranking | Unchanged | No learning influence built |
| Basic/One | Visual depth comparison | Entitlement rule unresolved |
| Guardian visibility | None | Seeker-only v1 rule |
| Article 9 categories | Mock wording only | Legally gated and inactive |
| Messages | Never read | Prohibited source |

## 8 · Live files and SHA-256

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | Learning state/plan/module types and immutable config | `b2f7830b2c1a4d49853df409c021339c355c53455dd72cc7c159697d15eff796` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | Shared in-memory learning state and current-hub switch | `fbd51c749096500668273fa43b7d03a8c6907dbb5f6fba5cfdb808a8672989b5` |
| `SOURCE/lib/dev/zyra_dashboard_lab_controls.dart` | Mock-only state, plan and current-hub controls | `fdec68709e0170f68260adf7e21926fd00a023f72951c0da8463637d5df0fc4e` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | Learning card, copy, tier depth and local response controls | `57fb5f43650efdb222c727a04ff1345b75d03170ca3f92a794666e171906bcc6` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | Developer-gated compact card in the existing Dashboard hub | `14f52050b727696e674f954ea418d098a603248a39c65fe08c486abfc63a6681` |
| `SOURCE/test/dashboard_lab_test.dart` | Four states, tier depth, response controls, causal-copy boundary | `a49d11d9c778f8e602bdefabb6d7f56425658690c37024b3d7bbf46157188d9d` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | Existing-hub integration and developer-only visibility | `87c14b02acb377e3b3e2580eb78cd33b43182ac75697b603035d26dd9879c494` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Four learning fixtures across the phone matrix | `0a40a94db2288bd54d0e126d6bfa8119e388c7345a7257f7eb511ec91460c0a9` |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | Learning state and fixture declarations | `3f64200d07288a3012fda387e27747dcb3ce05b28f4b81d17bf8ef81b86f2d2f` |

This handover omits its own hash because embedding it would change that hash.

## 9 · Measured verification

| Measurement | Result |
|---|---|
| Formatting gate | PASS · 203 Dart files checked, 0 changed |
| Focused Dashboard + existing-hub suite | PASS · 29/29 |
| Visual fixture test | PASS · 118/118, including all four states at 320×568, 390×844 and 430×932 |
| Full repository suite | PASS · 338/338 |
| Static analysis | PASS · no issues |
| iOS debug build | PASS · `build/ios/iphoneos/Runner.app` |
| Aggregate SQL probes | PASS · counts only; results recorded in the data audit |
| Physical iPhone review | PENDING · Founder installs through `run.sh` |

Candidate screenshots remain unapproved evidence. No golden baseline was
self-promoted; OA-ZYRA-257 remains the visual-baseline authority.

## 10 · Migrations

No migration was created or applied. No schema, RPC, RLS policy, trigger,
Storage rule, authentication state, persisted preference or entitlement was
changed.

## 11 · Known gaps and next gates

1. Founder ratification of `ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md` and final
   copy is pending.
2. Fable must reconcile the Product Spec Basic-entitlement contradiction and
   the audit's current-state-versus-history correction.
3. Founder review of the four mocks on a physical phone is pending.
4. Production aggregation, evidence persistence and ranking influence are not
   built. They belong to later OA-ZYRA-259 phases and require their own
   authority/evidence.
5. Compatibility category scoring, synthetic-data separation, structured
   pool-impact logic and Article 9 clearance remain dependencies.
6. Visual baselines remain Founder-pending under OA-ZYRA-257.

## 12 · Authority and archive state

This V3 file is the only current Dashboard Lab as-built authority. V1 and V2
are preserved in `SYSTEM/DOCUMENTS/ARCHIVE/` and marked superseded. The
production Seeker Dashboard handover remains authoritative for the ordinary
live hub. The Fable learning-loop document owns proposed product rules; the
Codex data audit owns measured technical reality.

No git command was run. Codex did not self-approve a design, evidence
threshold, entitlement rule or visual baseline.

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-24 | Added five role-aware Dashboard comparison concepts. |
| V2 | 2026-08-25 | Added Sectioned Status, specific events, onboarding progress and correctness cleanup. |
| V3 | 2026-08-25 | Added OA-ZYRA-259 P1 learning mocks in the Lab and existing Dashboard hub, full local response controls, Basic/One preview, data-audit linkage and updated evidence. |
