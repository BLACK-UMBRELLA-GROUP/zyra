# ZYRA Repository Audit — Terminology & Pricing Consistency
**Report type:** Report (immutable once published, per AD-087)
**Date:** 2026-07-12
**Prepared by:** Claude (Founder Office / Development Office)
**Requested by:** Shakeel (Founder), following ChatGPT's Programme A proposal
**Source of truth used for comparison:** `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md` (2026-07-04) and `JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V3.md`
**Scope:** Every file flagged during the Issue 1/2 investigation (2026-07-12) as containing possible legacy pricing or terminology. No edits made — audit only.

---

## Confirmed current model (for reference throughout this report)

- **Tiers:** ZYRA Basic (free) and ZYRA One (£34.99/month, £349.90/year). No "Pro" tier exists.
- ZYRA One is purchasable by a Seeker or a Wali. A Seeker's ZYRA One includes one bundled Extended Wali entitlement, assignable to a linked Wali. A Wali may also buy Extended Wali independently (£9.99/month). Identical capabilities either way (AD-081).
- **Profile-decision terms:** Decline / Save / Like (not Decline / Review / Consider).
- **Wali capability labels:** "Standard Wali" and "Extended Wali" — not "Wali Basic / Wali Pro / Wali Premium" (`JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V3.md` explicitly invalidates the latter).
- **Connector role:** Retired, per Founder decision 2026-07-12. To be removed from Architecture V2, not deferred.

---

## Classification key

| Class | Meaning |
|---|---|
| Current | Matches Product Spec V3 model. No action. |
| Legacy — retained | An archived/dated snapshot (filename carries a date, not `CURRENT_VERSION`). Correctly out of date by design — reference only, not touched. |
| Stale | Live/current document, but contains outdated terms, prices, or tier names that need correcting. Structure is still basically right. |
| Superseded | The document's entire premise has been replaced by a newer governing document elsewhere. Recommend archiving and replacing rather than editing in place. |

---

## Current — no action required

| File | Note |
|---|---|
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md` | The source of truth used for this whole audit. |
| `APP/Standards/JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V3.md` | Explicitly declares "Wali Basic/Premium/Pro" invalid and defines Standard/Extended Wali. Correct and current. |
| `APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V5.md` | Explicitly documents its own migration away from "Pro Seat model" to Capability Independence. Clean. |

## Legacy — intentionally retained (dated snapshots, no action)

| File |
|---|
| `SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_PRODUCT_SPEC_2026-06-27_V1.md` |
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_SPEC_2026-07-04_V2.md` |
| `APP/Standards/WALI_ARCHITECTURE_2026-06-28_V1.md`, `V2` |
| `APP/Standards/WALI_ARCHITECTURE_2026-07-04_V3.md`, `V4` |
| `APP/Standards/JOURNEY_CAPABILITY_GRANT_RULES_2026-07-04_V1.md`, `V2` |

These are dated-suffix files by convention — they're supposed to hold the terminology that was current when they were written. No correction needed; flagging them would be treating the archive as if it were live.

---

## Superseded — recommend archive + replace rather than edit

| File | Issue | Recommended correction | Priority |
|---|---|---|---|
| `APP/Premium/WALI PREMIUM/Summary.md` | Entire document is built around "Wali Premium" as a standalone paid tier separate from "Seeker Pro," with open questions about "tiered pricing separate from Seeker Pro." This whole model was replaced by the Extended Wali entitlement (bundled-or-independent, AD-081) in Wali Architecture V5. | Archive this Summary; write a new one that describes the feature as "Extended Wali capabilities," referencing Wali Architecture V5 and the Journey Capability Grant Rules rather than re-defining tiers itself. | Critical |
| `APP/Matching/PROFILE DECISION SYSTEM/Summary.md` (+ its `References.md` and `Flow Diagram.md`) | Built entirely around the three-action Decline/Review/Consider model (50-profile Review cap, Mutual Consideration match rule) — not just a naming difference from Save/Like, a structurally different decision system. | Archive and rewrite against Product Spec V3 Part 2 (Browse Stage & Potential Journey Stage), which already defines Save/Like behaviour in detail. | Critical |

---

## Stale — same structure, needs updating

| File | Issue | Recommended correction | Priority |
|---|---|---|---|
| `BUSINESS/ZYRA PRICING/Summary.md` | Lists "Seeker Pro £4.99, Seeker Premium £9.99, Wali Pro £2.99, Wali Premium £4.99" — fully obsolete price list. This is the master pricing document. | Replace with ZYRA Basic (free) / ZYRA One (£34.99/mo, £349.90/yr) / independent Extended Wali (£9.99/mo). | Critical |
| `BUSINESS/ZYRA PRICING/Flow Diagram.md` | Promo flows reference "Free Wali Pro Subscription," "First-time Seeker Pro/Premium subscriber" bonuses. | Rework promo logic around ZYRA One / Extended Wali entitlement instead of Pro/Premium tiers. | Critical |
| `BUSINESS/ZYRA TERMINOLOGY/Summary.md` | This is the terminology source-of-truth document (per DR-014) and it still defines Decline/Review/Consider as the approved terms — directly contradicts Product Spec V3. | Update to Decline/Save/Like; remove the Review/Consider section. | Critical |
| `BUSINESS/ZYRA TERMINOLOGY/References.md` | Cross-references Decline/Review/Consider as used "throughout" the product. | Update alongside Summary.md. | High |
| `BUSINESS/USER FEATURES/Summary.md` | Full feature-comparison matrix built on Seeker Basic/Pro(No Wali)/Premium(No Wali)/Pro(Wali)/Premium(Wali) and Wali Basic/Pro/Premium — five- and three-column tables that no longer match any real tier. | Rebuild as a two-column ZYRA Basic vs ZYRA One comparison, with a separate note for the Extended Wali entitlement axis. | Critical |
| `BUSINESS/USER FEATURES/References.md` | "Timeline access is a Pro and Premium feature," "Wali Premium can request family introductions." | Update tier references to ZYRA One / Extended Wali. | High |
| `APP/Navigation/SEEKER NAVIGATION/Summary.md` | Nav differs by "Seeker Premium" / "Wali Premium," with an explicit "Confirmed: 2026-06-27" note — predates Product Spec V3 by over a week. | Update nav-by-tier table to ZYRA Basic / ZYRA One / Extended Wali axis. | High |
| `APP/Navigation/SEEKER NAVIGATION/References.md` | Same Pro/Premium tier references. | Update alongside Summary.md. | Medium |
| `APP/Navigation/SEEKER NAVIGATION/Script/Script_V2.md` | Implementation script referencing Decline/Review/Consider. | Update once Summary.md is corrected — scripts should follow Summary per DR-013. | Medium |
| `APP/Profiles/Script/Script_V1.md` | Implementation script using Seeker Pro/Premium and Review/Consider. Notable because this is a Script (closer to implementation), not just planning. | Update to Save/Like and ZYRA Basic/One before this guides any real Flutter code. | High |
| `APP/Premium/Profile Unlocks/Summary.md` | "Seeker Only (Basic, Pro, Premium)," gated on "moved to Review or Consider." Also still marked "(Name TBC)" / "decision pending" — unfinished independent of this issue. | Update tier gating to ZYRA Basic/One; flag the naming decision as a separate small open item. | Medium |
| `APP/Premium/SUBSCRIPTION TRANSPARENCY/TRANSPARENCY_CURRENT_VERSION_V1.md` | Marked `CURRENT_VERSION` and "Approved," but every example is built on "Seeker Premium," "Wali Premium subscription" as tier names. Misleading given its Approved status. | Rewrite examples around ZYRA One / Extended Wali; re-issue as V2 once corrected (per single-current-version rule). | Critical |
| `APP/Journey/PRE-JOURNEY RITUAL/Summary.md` | References "Wali Premium," and has one explicitly open question referencing "Premium Walis" access conflicts. | Update terminology; the open question itself can likely be resolved once phrased in Extended Wali terms (a Seeker has one bundled entitlement to assign — the ambiguity may already be resolved by that rule). | Medium |
| `APP/Platform/GLOBAL_PLATFORM_PRINCIPLES_CURRENT_VERSION_V1.md` | `CURRENT_VERSION` doc citing "£19.99/month Seeker Pro, £9.99/month Wali Pro" as the reference price for App Store/Google Play regional pricing tiers. | Update reference price to £34.99/month ZYRA One (Seeker) and £9.99/month Extended Wali. | High |
| `APP/Premium/ADVERTISING/ADVERTISING_STANDARD_CURRENT_VERSION_V1.md` | `CURRENT_VERSION` doc entirely structured around "Seeker Pro = ad-free, Wali Pro = no ads" — the whole ad-eligibility table uses retired tier names. | Remap table to ZYRA Basic (ads) vs ZYRA One (ad-free); Wali ad policy unaffected in substance, just needs renaming. | High |
| `SYSTEM/DOCUMENTS/ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md` | Still lists Connector as a third user role (Founder decided 2026-07-12: retired). State Management still "TBD" (Issue 6 — separately deferred, not a staleness issue). | Remove the Connector row and its capability note. Leave State Management TBD as-is; that's tracked separately. | High |
| `SYSTEM/DOCUMENTS/ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md` | Two SQL comments say "Wali Premium" (e.g. `-- Wali Premium: suggest profiles to their linked Seeker`). Comments only — no logic depends on the wording. | Cosmetic rename to "Extended Wali" in comments before this schema is applied to a real Supabase project (OA-101/103). | Low |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_V1.md` | Points to the `APP/Premium/WALI PREMIUM/` folder by its current (soon-to-be-renamed) name. | Follows automatically once the underlying folder/Summary is renamed — not independent work. | Low |
| `BUSINESS/APP BREAKDOWN/Flow Diagram.md` | One ambiguous hit — "Premium Lock" as a UI element name. Could just mean a generic paywall icon, not necessarily a retired tier reference. | Confirm with a quick look before treating as an issue — likely no action needed. | Low |

---

## Summary counts

| Classification | Count |
|---|---|
| Current | 3 |
| Legacy — retained | 8 |
| Superseded | 2 (covers 4 files including sub-documents) |
| Stale | 18 |

**Critical priority items:** 5 — `ZYRA PRICING/Summary.md`, `ZYRA PRICING/Flow Diagram.md`, `ZYRA TERMINOLOGY/Summary.md`, `USER FEATURES/Summary.md`, `SUBSCRIPTION TRANSPARENCY`, plus the two Superseded documents (`WALI PREMIUM/Summary.md`, `PROFILE DECISION SYSTEM/Summary.md`).

**Recommended fix order:** Terminology and Pricing Summaries first (they're cited as source-of-truth by everything else) → the two Superseded documents (Wali Premium, Profile Decision System) → the remaining Stale High-priority docs → Medium → Low. Fixing source-of-truth docs first means every other correction can reference the corrected version instead of guessing.

---

*No files were modified during this audit. Awaiting Founder review and approval before any corrections are made.*
