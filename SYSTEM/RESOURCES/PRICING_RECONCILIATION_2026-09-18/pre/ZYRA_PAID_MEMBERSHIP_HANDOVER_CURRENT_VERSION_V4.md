# ZYRA — Paid Membership Client Handover

**Version:** V4
**Status:** CURRENT_VERSION — permission disclosure and Guardian preview updated; live split authority held
**Date:** 2026-09-18
**Owner:** Codex under Founder authority
**Decisions:** DR-ZYRA-235; DR-ZYRA-238
**Commercial source:** `BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V5.md`
**Capability source:** `APP/Standards/JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V7.md`
**Actions:** OA-ZYRA-253; OA-ZYRA-293; OA-ZYRA-296

## 1. Membership products

The client presents four products:

- ZYRA One — Seeker: £29.99/month;
- Seeker Basic: £9.99 one-time;
- ZYRA One — Guardian: £19.99/month;
- Guardian Basic: £9.99 one-time.

Developer Access exposes Seeker, Seeker Basic, Guardian, Guardian Basic and
Sign Up. The unqualified role buttons stage the corresponding One membership.

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

Seeker Basic retains one Active Journey, 50 active Considers, 10 Saves, five
Considers per calendar day, 25 committed profile swipes per four-hour window,
an advert preview after every five swipes, Now access and no Insights. Device
counters remain preview-grade until OA-ZYRA-293 provides server authority.

## 5. Production holds

No StoreKit/Play product, receipt verification, paid activation, ad SDK or
Guardian permission migration is activated by this client update. OA-ZYRA-253
owns billing and paid entitlements; OA-ZYRA-293 owns Basic quotas and live
advertising; OA-ZYRA-296 owns separate View/Chat authority.

Any OA-ZYRA-296 production database change requires an exact reviewed
migration, isolated replay, security/advisor verification and a separate
Founder GO naming the file and SHA-256.

## 6. Verification

- Latest Guardian-page and live-truth regressions: **17/17 PASS**. The wider
  membership/Guardian suite passed **40/40** before this presentation-only
  follow-up.
- Full `flutter analyze`: **PASS — no issues**.
- Signed iPhone profile build: **PASS** — app version `1.0.0 (2)`, executable
  SHA-256 `2159caee43bb7a06bc9e839247f2d3118b19919e034b363082ce4aacd6892759`.
- Wireless/device installation and launch: **PASS** on the Founder iPhone.
- Production database change: **none**.
- Git operation: **none**.
