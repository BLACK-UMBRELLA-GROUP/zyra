> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded on 2026-09-18 by `ZYRA_PAID_MEMBERSHIP_HANDOVER_2026-09-18_V2.md`.
> The current version is `ZYRA_PAID_MEMBERSHIP_HANDOVER_CURRENT_VERSION_V5.md`, in this folder.
> This file keeps its `CURRENT_VERSION` filename deliberately. Renaming it
> would break references held in the registers and in sealed mailbox messages,
> which are never edited after filing. Recorded under **OA-AIOS-384**.
> Banner added by Fable 2026-09-23 under AD-AIOS-110. **The body below is
> unchanged** and remains the truthful record of what was current at the time.

---

# ZYRA — Paid Membership Client Handover

**Version:** V1
**Status:** CURRENT_VERSION — client retirement implemented; paid-only activation HELD
**Date:** 2026-09-13
**Owner:** Codex under AD-AIOS-109; Founder is sole approver
**Authority:** Founder direct instruction to remove the free version, adverts and upgrade notifications; preserve removed material outside the app; offer One plus Additional Guardian
**Product specification:** ZYRA_PRICING (V3); supersession notice in ZYRA_PRODUCT_SPEC
**Actions:** OA-ZYRA-253, OA-ZYRA-266, OA-ZYRA-175/176, OA-ZYRA-286

## 1. What exists now

This is a client-presentation retirement, not a completed paid membership
backend. The sole Membership page offers information about **ZYRA One** and
**Additional Guardian**. It no longer displays a Basic comparison, downgrade
button, fake checkout or success confirmation. Following the Founder's
"Separate charge" clarification (report 119), Membership and Help describe
Compatibility Unlock/Plus as separate optional purchases at unchanged single/
five-pack prices, with checkout explicitly unavailable. Two membership
subscriptions remain; compatibility purchases are not extra subscription tiers.
Weekly/monthly catalogue prices are unchanged. The intended fourteen-day trial
is explicitly described as planned, not currently activated.

Removed throughout the client: Browse advert creative, advert cadence/state,
forced advert previews, commercial promotion campaigns and campaign storage,
upgrade-suggestion settings, paid feature teasers, and Guardian mock-purchase
entry points. Real notification permission education, opt-outs and safety
controls remain. Known legacy plan values still restrict capabilities; they
do not prove that a member is entitled to One or a trial.

Uncertain access uses **Access not confirmed** instead of claiming inactivity.
The existing boolean service can mean failure as well as denial, so neither
false nor a default legacy plan may be described as confirmed expiry. A true
Guardian result is labelled Guardian access, not claimed One ownership.

Browse's previous fifty-profile refusal applied to One too. One now bypasses
that client daily limit. Legacy cap values and all server caps remain unchanged;
no paid capability was granted by changing the default plan.

## 2. Files and ownership

All SOURCE-relative changed files and exact pre/post SHA-256 values are in
`SYSTEM/RESOURCES/TEMPORARY/ZYRA_PAID_ONLY_ROLLBACK_2026-09-13/prestate.ycqtLs/source-ledger.json`.
The full original files, forward patch and reverse patch are beside it.
Report 119's separate-charge clarification adds a subsequent four-file client/
test delta and current-document amendments. Its true pre-state and post-hash
ledger live beside `separate-charge.8P7OYJ/before.tar.gz` under the same rollback
parent. Report 118's ledger and receipt remain immutable evidence of that point
in time, not the final post-hashes after this clarification.

| Component | Responsibility |
|---|---|
| `lib/data/zyra_membership_catalog.dart` | Exactly two membership subscriptions; separate compatibility purchase information with unchanged prices; fourteen-day planned trial; checkout explicitly unavailable. No entitlement or clock logic. |
| `lib/screens/subscription/upgrade_screen.dart` | Historical route name retained, now read-only Membership screen. Responsive billing chips; no purchase/downgrade mutation. |
| `lib/constants/zyra_plan_names.dart` / `lib/data/help_content.dart` | Member-facing neutral access and commercial descriptions. Legacy DB strings retained. Help's old single-Journey claim corrected to existing One caps, not new capacity. |
| Profile, Settings and Guardian Profile | Remove sales comparisons/preferences; retain user-initiated Membership route, privacy/account controls and held second-context setup. |
| Guardian Network screen | Remove mock purchase and commercial details; retain truthful not-yet-available Network, accepted-link requirement and manual Membership route. |
| Browse | Remove ad creative, cadence, rendering and forced popup; neutral cap refusal; One does not stop at fifty profiles. |
| Promotion engine / bottom surface | No commercial campaign eligibility or persisted campaign state. Notification permission education/cadence/opt-out remain. Old public signatures are inert compatibility, not a hidden campaign switch. |
| Locked-feature / paused-limit / intelligence widgets and both dashboard presentations | Remove upsell invitations without revealing protected content. Existing caps, empty/failure/data states survive. |
| `profile_unlock_screen.dart` | Remove unused sale prices and purchase footer. Existing credit-spend, permanent unlock and Guardian-disclosure checks remain; detailed-category fuse unchanged. |
| Developer controls, scenarios and dashboard lab model | Remove sponsored-card control and state, commercial forced prompts and visible Basic/Guardian+ sales labels. Internal legacy scenario enums remain for denial/regression fixtures. Protected Founder authorization unchanged. |
| Focused tests and visual constructor adapter | Cover no offers, no false payment success, notification preservation, neutral failed-access copy, caps and responsive Membership information. No approved baseline changed. |

One writer owned each slice. Main agent wrote catalogue/Membership/help/plan
names/compatibility footer and filing; bounded internal agents owned promotion,
Guardian/settings/developer controls, and neutral dashboard/widget slices.
Internal cross-checks are not external review or Founder acceptance.

## 3. State and data flow

Membership route → local read-only catalogue → explanatory unavailable state.
Selecting Weekly/Monthly changes displayed information only. It does not start
a trial, mutate AppState, call a purchase RPC or record payment success.

Existing session hydration → legacy server subscription model → existing
capability gates remains unchanged. No client-default-to-One shortcut exists.
Locked feature taps explain unavailable access in place, not checkout. Current
Guardian Network remains unavailable in production even for entitled users.

Existing compatibility rights → unchanged unlock/Guardian services → existing
disclosure checks. Removing a purchase route neither erases historic rights nor
grants new ones. The category breakdown remains truthful/unavailable.

Initial signup drafts, native secure storage, signout, IDV recovery and Founder
authorization from report 117 are byte-preserved. No identity-provider adapter
was selected or enabled. No real trial starts during verification.

## 4. Existing limitations — not solved by this patch

1. **Real paid-only participation (OA-ZYRA-253):** existing database/API still
   permits legacy Basic use. Source labels do not constitute server enforcement.
   No real StoreKit/Play purchase adapter, receipt verification, renewal handling
   or trial eligibility record exists. Existing hydration and caps ignore expiry.
2. **Contextual Guardian allocation (OA-ZYRA-253):** `wali_has_wali_one()` returns
   one boolean combining own Guardian purchase with any linked premium Seeker.
   It does not establish which Main relationship funded access. Checking that
   a Main link also exists is unsafe (Main for non-paying A, Additional for
   paying B). A contextual server resolver and allocation ledger are needed.
3. **Both contexts / transfers (OA-ZYRA-253 plus OA-ZYRA-175/176):** one identity
   with both contexts is approved direction but server/client still route a
   single `profiles.role`; invite acceptance rejects same-role pairs. Preserve
   no-self-Guardian, Main-only authority and later DR-123/124 exclusion rules.
   Former-direct-Guardian exclusion and deletion-retention defects remain real
   recorded gates before opening previously impossible matches.
4. **Commercial choices (OA-ZYRA-253):** exact access-transfer scope/cooldown and
   trial interaction with promised launch discounts are not invented. Derived
   annual price remains unconfirmed. Founder answered the compatibility question:
   separate charge, not unlimited inclusion. Existing credits/rights and the
   prior three-credit rule are not silently revoked; any future change to the
   allowance needs explicit supersession when actual billing is scoped.
5. **IDV (OA-ZYRA-266):** provider selection/contract/keys/capture are not live.
6. **Delivery / device acceptance (OA-ZYRA-286):** local source is not uploaded.
   Existing TestFlight build 3 does not contain this change or report 117's fix.
7. **Visual baseline drift:** full suite retains sixty pre-existing golden
   comparison failures. Approved pixels are never regenerated to conceal drift.
   New Membership candidates are separate, unapproved review artifacts.

The master register is not closed or bulk rewritten by this report. No new OA
identifier is raised: the above existing actions own the work; this handover and
118 provide the bounded update and exact continuation surface. Full register
and downstream specification reconciliation remain part of OA-ZYRA-253.

## 5. Migration / deployment status

**None.** No migration was authored or applied; no production query was used as
a test; no billing/account-policy change, Apple upload, credentials, certificates
or git operation occurred. Legacy SQL identifiers, privacy functions, romantic
predicates and profile/unlock ownership are unchanged.

The next backend contract must name server-owned trial and receipt truth,
Main-context allocation, transfer concurrency/revocation, mixed-role identity,
expiry and safety/history continuity. Review each schema/RLS/RPC/trigger/client/
documentation dependency before construction. Any production apply must retain
the exact Founder artifact/environment GO and denial/post-apply probes.

## 6. Evidence, rollback and verification

True pre-state was captured before the first edit at
`SYSTEM/RESOURCES/TEMPORARY/ZYRA_PAID_ONLY_ROLLBACK_2026-09-13/prestate.ycqtLs/`:

- `source-before.tar.gz` — original lib/test text, pubspec, run script, README;
  SHA-256 `f169927d78b494b766ecd8bfc1aace27a1e5a37c2e7b7848ef1d5e3f03638f3a`.
- `governance-before.tar.gz` — original pricing directory, product spec and index;
  SHA-256 `c3e8a18ea71c002678270d24d8b03c08f1ae0119ac285ea19fbdff8c3613bdd9`.
- `source-ledger.json`, `forward.patch`, `reverse.patch` — precise changed text,
  generated against those retained bytes, never reconstructed originals.

Recoverability does not authorize blind rollback: check current post hashes,
apply only the named reverse hunks, preserve subsequent edits, and rerun tests.
Never restore the entire source archive over a later worktree. No material was
irrecoverably deleted. Approved screenshots/migrations remain in place.

Measured focused results: catalogue/compatibility/context 12/12; promotion
15/15; dashboard/refusal/intelligence 40/40; Guardian/developer controls 38/38.
Both integrated full suites: 999 passed, one compile-gated skip, sixty visual
comparison failures. The final run after panel cleanup completed in 67 seconds;
all sixty failing names and actual image hashes match report 117 exactly. Final
full analyzer: no issues, 5.1 seconds. Explicit IDV-enforcement regression:
21/21 pass. The panel wording-only cleanup also passed its 29 focused tests.
Unsigned iOS simulator compilation passed; no device install or upload.
Four new unapproved Membership candidates were captured outside SOURCE; all
original candidate and approved pixels/manifests remain byte-preserved. Final
artifact hashes are in report 118's adjacent `completion-receipt.json`.

Subsequent separate-charge copy amendment (report 119): 26/26 focused catalogue,
layout, Help and promotion-retirement tests pass; full analyzer clean (7.3s).
No entitlement or payment code changed. Full suite/compile/capture were not
rerun for that amendment; the earlier four unapproved Membership candidates
predate its compatibility information section. Its true pre/post hashes are in
the separate-charge evidence receipt, and supersede only the affected live
pins from report 118 without modifying that historical receipt.

During construction the footer removal briefly caused a syntax error; repaired
before the measured final checks. Large-text testing caught a segmented-control
overflow, replaced with wrapping chips. A test then assumed an off-screen lazy
child existed; changed to scroll to it. Subsequent focused tests pass. These
are local development failures, not production incidents.

## 7. Next bounded work

1. Founder reviews the new Membership presentation and resolves transfer scope.
   Separate optional compatibility charges are confirmed in report 119.
2. Prepare the real billing/dual-context/server-access contract, explicitly
   resolve OA-175/176, and verify state/permission/expiry boundaries.
3. Build and test under that bounded contract; separate exact live activation
   GO, then migration/payment post-verification.
4. Batch this UI change with the prior signup recovery into a separately
   approved next TestFlight build; Founder tests on device.

Only the client-retirement slice is implemented here. The overall request is
not marked complete, accepted, or live.
