## Implementation vs. Documentation Contradiction Check

---

### PREAMBLE

The file is the **first-draft preview path only**. The production path (non-developer builds) shows: entitlement gate → empty Discover/Requests pages. The preview path is explicitly scoped to `ZyraDeveloperAccess.canUseDeveloperTools` and carries a prominent FIRST DRAFT marker. I evaluate each rule against both paths where relevant.

---

### RULE-BY-RULE VERDICTS

**Rule 1 — No feed without an active Seeker context.**
Production path: empty states only, no feed rendered. Preview path: `_GuardianNetworkDiscover` renders a `_NetworkContextNotice` ("Link a Seeker first") when `wards.isEmpty`, and a "Choose a Seeker" notice when multiple wards exist and none is selected. No candidate feed, saved list, passed list, or introduction count renders without a selected Seeker.
**HELD.**

**Rule 2 — Single-Seeker context, always.**
`_selectedSeekerId` is a single nullable string. All `_previewDecisions` keys are keyed `'${selected?.id}/${recommendation.id}'`. No cross-Seeker bleed is possible in the implemented state management.
**HELD.**

**Rule 3 — Seeker selector behaviour.**
`_NetworkSeekerSelector`: one ward → static `_SeekerChoice` with `expanded: true`, no dropdown, `onTap: () {}` (no-op). Two or more → horizontal scroll row, no default selection, screen does not proceed past the notice until a selection is made. C3 filtering (excluding linked Seekers with consent OFF) is not implemented in the preview — `ZyraDevScenario.composeWaliWards` is a dev composition function, not a live eligibility filter — but this is the preview path; production path has no selector at all. The rule is binding on the production implementation; the preview is explicitly provisional.
**NOT EXERCISED** (production path; preview path is correctly labelled provisional).

**Rule 4 — Composite key `(guardian_id, seeker_id, candidate_id)`.**
`_previewDecisions` uses `'${selected?.id}/${recommendation.id}'` — a two-part key missing `guardian_id`. In the preview context there is only one Guardian (the logged-in user), so the omission is not functionally dangerous, but the key does not match the mandated composite form. This is a preview-only structure with no database writes.
**NOT EXERCISED** (no production table rows, cache entries, or subscription channels are written).

**Rule 5 — `can_introduce()` is the master gate.**
Production path: no feed, no candidates, no server calls. Preview path: explicitly documented as "no action on this page changes live data" and "Suggest, Pass and View in that preview never call a service or create a production permission." No server gate is bypassed because no server calls are made.
**NOT EXERCISED** (correctly; preview is explicitly non-production).

**Rules 6–11 — Eligibility and filtering.**
No live eligibility evaluation occurs in either path. Production path shows empty states. Preview uses hardcoded `guardianNetworkPreviewRecommendations`. These rules govern server-side and live-client behaviour that does not exist yet.
**NOT EXERCISED.**

**Rule 12 — Approved field set for Discover card.**
The `_GuardianNetworkRecommendationCard` displays: first name (not initial — full first name), age, region (not city ✅), `familyContext` (maps to Guardian relationship label), recommendation reason chips. **No photo rendered** — the `ZyraProfileImage('')` is overlaid with the initial letter, effectively suppressing the image. City, full name, occupation detail, Chapter 3/4 answers: absent ✅.

One discrepancy: Rule 12 specifies **first-name initial**, not first name. The card displays `recommendation.firstName` in full (e.g., "Amira, 26"). The profile sheet also displays the full first name.

This is a **FIRST DRAFT** preview screen explicitly labelled provisional, and the spec note on Rule 12 itself is marked WORKING RULE (D2 pending). The preview disclaimer footer reads "Preview fields and recommendation reasons are provisional." The profile sheet states "This first draft deliberately withholds photos, surnames and contact details. Final visibility follows the Guardian Network specification."
**VIOLATED** (first name displayed in full at Rung 0; Rule 12 requires initial only). Mitigated by WORKING RULE status and explicit preview disclaimer, but the contradiction is present and must be flagged.

**Rule 13 — No free text anywhere on the card.**
No free-text input field exists anywhere in the implementation. Cards are system-controlled. Guardian cannot annotate.
**HELD.**

**Rule 14 — Recommendation-reason chips are taxonomy-controlled.**
Chips come from `recommendation.reasons`, sourced from `guardianNetworkPreviewRecommendations` in `guardian_network_preview.dart` (not in scope of this file but referenced). The disclaimer "Preview fields and recommendation reasons are provisional" covers this. No free-text input path exists.
**HELD** (with the caveat that the underlying data source is provisional).

**Rule 15 — Progressive disclosure ladder never inverted.**
Region displayed, not city ✅. No higher-rung fields at Rung 0.
**HELD.**

**Rule 16 — Uniform field set; no per-user sparseness.**
All preview cards show the same field set. No conditional omission per profile.
**HELD.**

**Rule 17 — v1 action set: View · Save · Pass · Suggest · FIR.**
Actions rendered: **View · Pass · Suggest**. Save is absent. FIR is absent. The Requests tab shows staged suggestions but no FIR surface.

Save and FIR are absent. Rule 17 lists Save and FIR as part of the v1 action set. However, the header comment states this is a "FIRST DRAFT" and "the governed Guardian Network reconciliation owns the unresolved ranking, visibility, consent and authority decisions." The action set incompleteness is a first-draft gap, not a contradiction of a finalised surface. The preview is not the production implementation.
**NOT EXERCISED** (Save and FIR not implemented; correctly scoped as first-draft provisional).

**Rule 18 — View is silent.**
`onView` calls `_showPreviewProfile` — a local modal sheet. No service call, no notification, no aggregation.
**HELD.**

**Rule 19 — Save and Pass are private; Pass is reversible.**
Pass: sets `GuardianNetworkCardDecision.passed` in `_previewDecisions`. The `_DecisionConfirmation` widget for a passed card shows an "Undo" button that calls `onDecision(GuardianNetworkCardDecision.undecided)`. Reversible ✅. No notification to candidate or Guardian ✅. Save: not implemented (see Rule 17 note).
**HELD** (for Pass). **NOT EXERCISED** (for Save).

**Rule 20 — Suggestion is not consent.**
The `_GuardianNetworkRequests` tab displays staged suggestions with copy "awaiting their choice." No suggestion is described as consent. The Requests tab header: "No request has been sent to another family." The `_DecisionConfirmation` for a suggested card reads "Suggestion staged for the Seeker." No push notification is triggered (no service call).
**HELD.**

**Rule 21 — Decline reasons never disclosed.**
No decline-reason surface exists in the implementation. Requests tab shows only "awaiting their choice."
**HELD.**

**Rule 22 — FIR consent chain enforced server-side.**
FIR not implemented. No FIR surface exists.
**NOT EXERCISED.**

**Rules 23–47 — Not present in this file.**
These rules govern database schema, real-time subscriptions, rate limits, capacity caps, notifications, Seeker authority, audit logging, RLS policies, and rollout. None of these are implemented in this UI file. The file makes no database calls, no subscription registrations, no notification dispatches.
**NOT EXERCISED** (correctly; this is a UI-only first draft with explicit no-live-data disclaimer).

---

### INVENTED PRODUCT RULES CHECK

Scanning for UI behaviour, copy, or constraints not traceable to the agreed rules:

- **"Curated set" label** on the Discover header: presentational copy, not a product rule.
- **"Shortlisted around their choices — never outside them"**: accurate paraphrase of Rule 6 (hard filters absolute).
- **`GuardianNetworkPreviewPlan.basic` → plan notice**: a dev-preview scaffolding construct, not a production product rule.
- **Capacity reached banner**: maps to Rule 42 (introduction capacity cap). Not invented.
- **"No request has been sent to another family" copy in Requests tab**: consistent with Rule 20 (suggestion is not consent, FIR not yet sent).
- **Requests tab showing "staged suggestions"**: the preview frames suggestions as staged, awaiting Seeker choice. Consistent with Rule 20.

**No invented product rules found.**

---

### SUMMARY OF VERDICTS

| Status | Rules |
|---|---|
| **HELD** | 1, 2, 13, 14, 15, 16, 18, 19 (Pass), 20, 21 |
| **VIOLATED** | **12** — first name displayed in full; Rule 12 requires first-name initial only at Rung 0 |
| **NOT EXERCISED** | 3 (production), 4, 5, 6, 7, 8, 9, 10, 11, 17 (Save/FIR), 19 (Save), 22, 23–47 |

---

### READINESS VERDICT

**NOT READY** for Founder on-device testing on one narrow, fixable ground: the Discover card and profile sheet display the candidate's **full first name** where Rule 12 mandates the **first-name initial only** at Rung 0. Every other implemented surface is clean — no invented rules, no consent-chain violations, no field leakage beyond region, no free text, no photo, Pass is reversible and silent, suggestion copy correctly does not imply consent. The Rule 12 violation is contained within the first-draft preview path (production path shows only empty states) and the preview carries explicit disclaimers that fields are provisional