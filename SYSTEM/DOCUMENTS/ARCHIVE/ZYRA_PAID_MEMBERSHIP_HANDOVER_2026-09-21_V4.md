> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded on 2026-09-21 by `ZYRA_PAID_MEMBERSHIP_HANDOVER_CURRENT_VERSION_V5.md`, in this folder, which is current.
> This file keeps its `CURRENT_VERSION` filename deliberately. Renaming it
> would break references held in the registers and in sealed mailbox messages,
> which are never edited after filing. Recorded under **OA-AIOS-384**.
> Banner added by Fable 2026-09-23 under AD-AIOS-110. **The body below is
> unchanged** and remains the truthful record of what was current at the time.

---

# ZYRA — Paid Membership Client Handover

**Version:** V4
**Status:** CURRENT_VERSION — pricing, Family calculator, permission disclosure and Guardian preview updated; live commercial activation and split authority held
**Date:** 2026-09-18
**Owner:** Codex under Founder authority
**Decisions:** DR-ZYRA-235; DR-ZYRA-238
**Commercial source:** `BUSINESS/ZYRA PRICING/ARCHIVE/ZYRA_PRICING_2026-09-24_V5.md`
**Capability source:** `APP/Standards/JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V7.md`
**Actions:** OA-ZYRA-253; OA-ZYRA-293; OA-ZYRA-296

## 1. Membership products

The client presents four standalone products:

- ZYRA One — Seeker: £29.99/month;
- Seeker Basic: £9.99 one-time;
- ZYRA One — Guardian: £19.99/month;
- Guardian Basic: £9.99 one-time.

Founder clarified monthly-only subscription pricing on 18 September. The
current client already had no yearly price or billing-period selector. The
catalogue now explicitly says that Family is billed monthly and the planned
Seeker trial continues as a monthly subscription; regression tests pin the
monthly One prices and absence of yearly/weekly options. Basic one-time fees,
Compatibility purchases, Family calculation and trial length are unchanged.
Evidence and true pre-states:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/zyra-monthly-only.NZMqxb/REPORT.md`.
This is a source update, not a phone install, store billing change or upload.

Developer Access exposes Seeker, Seeker Basic, Guardian, Guardian Basic and
Sign Up. The unqualified role buttons stage the corresponding One membership.

The Membership screen also presents an informational **Build your ZYRA
Family** calculator. The former "Family unchanged" Help placeholder has been
replaced by the configurable rule in the commercial source (§1.1). Family is
not added to the entitlement enum or represented as an active store product.

## 2. Guardian purchase and permission truth

Guardian One makes paid features eligible; it does not guarantee that an
Additional Guardian may view or enter every linked Seeker Journey. The linked
Seeker controls View and Chat separately per Additional Guardian and per
active Journey. Chat requires View. Turning View off also turns Chat off and
disables it until View is restored.

A Main Guardian's View and plan-enabled Chat access cannot be switched off
while that person remains Main. Guardian Basic remains View-only and has no
Chat or Guardian Network eligibility.

This limitation is now stated on the Membership page and in Help content. It
must also appear in final checkout terms, purchase confirmation, link
acceptance and legal copy before paid activation.

## 3. Guardian-page client behaviour

The Founder preview now:

- replaces the misleading `Chat — Included` status with a Chat switch;
- keeps View and Chat independently visible for Additional Guardians;
- clears and disables Chat when View is turned off;
- keeps the compact access card label-only, without explanatory text beneath
  the controls; membership and Help surfaces retain the required disclosure;
- shows Main Guardian View and Chat as `Required`, with no disable switches
  and no explanatory paragraph beneath the controls; Main uses the same
  collapsible **Active Journey access** row as Additional Guardians and no
  longer wraps the Required rows in a translucent access card;
- keeps **Make Main Guardian**, **Remove as Main Guardian** and **Remove
  Guardian** active in Founder preview: Confirm updates the local cards
  immediately, promotion demotes the former Main, demotion does not
  auto-promote a replacement, and removal removes only the selected card;
- presents Make/Remove-as-Main with a quiet neutral treatment while retaining
  red for the destructive Remove Guardian action.

The Guardian scroll viewport also fades smoothly into the fixed page-position
dots and includes bottom clearance. Partially visible Manage actions no longer
form a hard purple seam at the viewport boundary while the user drags.

The live OA-ZYRA-290 server presently returns one combined Journey-inclusion
boolean. Therefore the new Chat switch remains preview-only until OA-ZYRA-296
adds separate audited server state, membership eligibility and conversation /
message RLS enforcement. The app does not claim local preview state is live.

## 4. Seeker Basic boundary

Later Founder revision, 2026-09-18: Seeker Basic retains one Active Journey,
10 Potential Journeys, one Paused Journey, 25 active Considers, five Saves,
five Considers per calendar day, 25 committed profile swipes per four-hour
window, Now access and no Insights. Basic has zero revisitable ended Journeys
and declined profiles; the corresponding sections remain visible and locked.
One shows the latest ten ended Journeys and latest ten profiles the user passed
on. Neither limit deletes records or changes Browse suppression of passed profiles.

Linked Guardian capacity is one on Basic and ten on One, including Main. It is
the Seeker's link capacity, not free paid Guardian memberships and not a cap on
how many Seekers a Guardian supports. Existing links and safe management paths
remain on downgrade; new capacity-consuming actions use the revised policy.

Comparison labels are ZYRA Basic / ZYRA One within the chosen role, and Unlimited
replaces No plan limit. Remove advert-preview cadence from comparison copy only;
the truthful advert preview and its five-swipe test cadence remain. Device
counters and capacity preflights are not server authority. OA-ZYRA-293 owns
quota reconciliation; OA-ZYRA-261 owns the saved server Pause 5/10 mismatch;
Guardian write-path enforcement also concerns OA-ZYRA-289 and OA-ZYRA-253.

## 5. Production holds

No StoreKit/Play product, receipt verification, paid activation, ad SDK or
Guardian permission migration is activated by this client update. OA-ZYRA-253
owns billing and paid entitlements; OA-ZYRA-293 owns Basic quotas and live
advertising; OA-ZYRA-296 owns separate View/Chat authority.

Any OA-ZYRA-296 production database change requires an exact reviewed
migration, isolated replay, security/advisor verification and a separate
Founder GO naming the file and SHA-256.

## 6. Verification

The following measurements belong to the earlier Guardian delivery, not the
pricing correction's phone deployment. Latest pricing measurements are in §7.

- Latest Guardian-page and live-truth regressions: **17/17 PASS**. The wider
  membership/Guardian suite passed **40/40** before this presentation-only
  follow-up.
- Full `flutter analyze`: **PASS — no issues**.
- Signed iPhone profile build: **PASS** — app version `1.0.0 (2)`, executable
  SHA-256 `2159caee43bb7a06bc9e839247f2d3118b19919e034b363082ce4aacd6892759`.
- Wireless/device installation and launch: **PASS** on the Founder iPhone.
- Production database change: **none**.
- Git operation: **none**.

## 7. 2026-09-18 configurable Family pricing reconciliation

Authority: the Founder's explicit current pricing/app correction and the
previous Family calculator discussion in `ZYRA APP BUILD`, reconciled into
the commercial source §1.1. The four standalone prices were already correct;
Family was missing from the Membership screen and its Help wording was stale.

Architecture and entry: existing Membership/UpgradeScreen route → local
Family card → pure quote model in `lib/data/zyra_membership_catalog.dart`.
Independent Seeker/Guardian counters start at zero, each bounded 0–10. The
calculator reads the same integer-pence One prices used by membership cards,
then displays the individual total, percentage/pound saving and monthly total.
It neither persists counts nor reads/writes backend, billing or account state.
No new developer control is needed. Both roles use the existing shared route.

Files: `lib/data/zyra_membership_catalog.dart` (prices, terms, pure quote),
`lib/widgets/zyra_family_pricing_card.dart` (new local calculator),
`lib/screens/subscription/upgrade_screen.dart` (shared entry),
`lib/data/help_content.dart` (Family explanation), and
`test/family_membership_pricing_test.dart` (new tests).

Verification: `flutter test --no-pub test/paid_only_membership_catalog_test.dart
test/family_membership_pricing_test.dart` — **16/16 PASS**, including all 121
valid combinations, invalid bounds, zero/one-role selections, 40% ceiling,
penny reconciliation, inert entitlements and layouts at widths 320/390 with
text scales 1/2. Full analyzer result and pre/post SHA-256 ledger are filed in
`SYSTEM/RESOURCES/PRICING_RECONCILIATION_2026-09-18/REPORT.md`.

Scope/status: client source and governed pricing corrected; no database,
store product, payment, git, TestFlight upload, phone install or publication
performed by this pricing correction. The concurrent website redesign source
is deliberately untouched. Its old pricing is a separate surface discrepancy,
recorded in the same report for that workstream, not silently marked fixed.
Full commercial activation remains OA-ZYRA-253; Basic server quotas/adverts
remain OA-ZYRA-293. No duplicate action is raised for this bounded source
correction. Founder visual acceptance remains pending.

## 8. 2026-09-18 later membership allowance revision

The Founder directly revised the Basic/One allowance table after website review.
Pricing V5 §2 is the current commercial matrix. The website comparison and client
policies now carry the revised allowances. This is client/source implementation,
not server-enforced paid activation. No publication, phone install, TestFlight
upload or production migration is performed by this revision.

Implementation evidence, true pre-states, final hashes and test results:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/zyra-membership-limits.GDA19U/REPORT.md`.
That report distinguishes checked client behaviour from unresolved server quotas.
The preceding §6/§7 device/test results remain historical measurements, not
evidence of a new installation. The prior website publication request is paused
while this revised comparison is reviewed.
