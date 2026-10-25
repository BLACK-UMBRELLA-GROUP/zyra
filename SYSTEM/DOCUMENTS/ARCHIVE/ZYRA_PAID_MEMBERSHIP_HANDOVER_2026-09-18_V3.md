> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded on 2026-09-18 by `ZYRA_PAID_MEMBERSHIP_HANDOVER_2026-09-21_V4.md`.
> The current version is `ZYRA_PAID_MEMBERSHIP_HANDOVER_CURRENT_VERSION_V5.md`, in this folder.
> This file keeps its `CURRENT_VERSION` filename deliberately. Renaming it
> would break references held in the registers and in sealed mailbox messages,
> which are never edited after filing. Recorded under **OA-AIOS-384**.
> Banner added by Fable 2026-09-23 under AD-AIOS-110. **The body below is
> unchanged** and remains the truthful record of what was current at the time.

---

# ZYRA — Paid Membership Client Handover

**Version:** V3
**Status:** CURRENT_VERSION — four-tier client and Basic limits implemented; live commercial activation held
**Date:** 2026-09-18
**Owner:** Codex under Founder authority
**Decision:** DR-ZYRA-235
**Commercial source:** `BUSINESS/ZYRA PRICING/ARCHIVE/ZYRA_PRICING_2026-09-24_V5.md`
**Capability source:** `APP/Standards/ARCHIVE/JOURNEY_CAPABILITY_GRANT_RULES_2026-09-18_V6.md`
**Actions:** OA-ZYRA-253; OA-ZYRA-293

## 1. Implemented client truth

The read-only Membership page now presents four products: ZYRA One — Seeker
at £29.99/month, Seeker Basic at £9.99 one-time, ZYRA One — Guardian at
£19.99/month and Guardian Basic at £9.99 one-time. Help, Profile, Settings and
Guardian membership labels use the same names.

Developer Access now exposes five paths in the approved order: Seeker, Seeker
Basic, Guardian, Guardian Basic and Sign Up. The unqualified role buttons stage
the corresponding One membership; Basic buttons stage the limited membership.

Seeker Basic uses the existing one-Active-Journey plan rule and adds:

- 50 active Considers and 10 Saves;
- 5 Considers per calendar day;
- 25 committed profile swipes per four-hour window;
- a clearly labelled advert preview after each 5 swipes;
- a locked Insights surface while Now remains available.

Four-hour and daily usage survive app relaunch on the same device and are
scoped to the signed-in account or isolated Founder preview identity. ZYRA One
bypasses these Basic Browse limits and advert cadence.

## 2. Preserved authority and safety

- The existing server-backed Basic one-Active-Journey/One three-Active-Journey
  matrix remains authoritative and was not loosened.
- Essential reporting, blocking, consent, privacy and account controls remain
  available on Basic.
- Membership does not create Guardian links, grant Main authority or erase
  relationships/history.
- Guardian Basic remains view-only at the paid participation boundaries.
- No fake checkout, entitlement grant, real advert impression or payment
  success state was added.

## 3. Deliberate production boundary

No production migration, StoreKit/Play product, receipt verification, paid
activation, ad SDK, ad unit, tracking consent change or TestFlight upload is
part of this update. Device counters are appropriate for preview testing but
are bypassable by reinstall/cross-device use. OA-ZYRA-293 owns authoritative
server quotas and live advertising prerequisites; OA-ZYRA-253 continues to own
billing and paid entitlements.

The live advert provider must be selected only with privacy, consent,
age/audience, App Store/Play policy and failure-mode review. Until then the
interstitial says “Advert preview” and states that no provider is connected.

## 4. Source ledger

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/data/zyra_seeker_basic_policy.dart` | Canonical Seeker Basic limits and advert cadence | `00753fdc42b47eb4e5341687794fd7bb48d0bf65edc278834dcf7eab4947b5ed` |
| `SOURCE/lib/services/zyra_seeker_basic_usage_store.dart` | Account-scoped device persistence for swipe windows and daily Considers | `c3e5c02581ea11e5cdd929f4fcd11c515ab9b3ccb2b9cf2834a87e67cb339c22` |
| `SOURCE/lib/data/zyra_membership_catalog.dart` | Four-product catalogue and current prices | `80e888c45b64026ae9b0fc9af37dd93999ce3a310c20ad4c2fb3c721ba088af8` |
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | Responsive four-tier membership information | `00e673ff17ff8583ed9ba063eaaff6e08e5c6d078ebb38cf7b71ee6fb307b9d0` |
| `SOURCE/lib/screens/dev/developer_access_screen.dart` | Five Developer Access routes | `664e0e95365ae99057ba5dd1b2d10b4c64e7eeb11f639f6e87a073e0c28c1c8e` |
| `SOURCE/lib/dev/zyra_dev_local_preview.dart` | Paid/Basic Seeker and Guardian preview selection | `cb1f7e56866d6d087b47bc95884d910c30c5d55e79a8774c8e7693bc5c1b290b` |
| `SOURCE/lib/screens/browse/browse_screen.dart` | Basic quotas, refusal states and fifth-swipe advert preview | `e483ce2fe11fd75ca1720c35e58e1d0711983566d641010b44ccd48cc5d6dd71` |
| `SOURCE/lib/widgets/zyra_quiet_dashboard.dart` | Seeker Basic Insights lock explanation | `a1fc31a4868cef9d6419e767e606a3b724da4f8b07ffe43b22b21ccdb894305d` |
| `SOURCE/lib/constants/zyra_plan_names.dart` | Legacy DB plan values mapped to current product names | `ed0151f2ff5c356a3e64ad1a4208599a3cc458695a1353e6afc9571dfc2b0a44` |
| `SOURCE/lib/data/help_content.dart` | Four-tier price and capability help copy | `d3c88493fc76b5b9ea020814ecbee5d343846dad15e6eb658c2f47bceb1d1f95` |
| `SOURCE/test/seeker_basic_policy_test.dart` | Limit, advert cadence and reset-window regression | `5766a2f5eeb600612f01db4721676b4cf123ed1e67bf1ea8e0933a850e23c3ed` |
| `SOURCE/test/paid_only_membership_catalog_test.dart` | Product, pricing and responsive catalogue regression | `075fb3c2397889cf1af8a3b2a828acab9cabdbe35990f0ecdb42f346e2a3faaa` |
| `SOURCE/test/zyra_developer_access_test.dart` | Five-route and correct-tier preview regression | `5a2b5310b00b6e2caf08cb483cd44267e257bba1a60e6c4561f80697bebde06d` |
| `SOURCE/test/zyra_quiet_dashboard_test.dart` | Seeker Basic Insights denial regression | `4fa0f2146aab7987f1679db9b86f7232d119ef0447eae6ec0a442d79a2616a11` |

## 5. Verification

- Focused membership, Developer Access, Dashboard, policy and Guardian
  regressions: **70/70 PASS**.
- Full `flutter analyze`: **PASS — no issues**.
- Static structural check: **no new findings**; its known analyzer-clean
  `lib/main.dart` preview-client false positive remains baselined.
- Signed iPhone profile build: **PASS** — `Runner.app` built successfully;
  executable SHA-256
  `fee7571e301e3464c1f057ff6d808e523d590e2170749fdce5e53c6efa01216e`.
- Wireless device install: **not completed** because no iPhone was visible to
  Flutter or `devicectl`; the device reported unavailable/locked on the local
  network at delivery time.
- Production database migration: **not created and not applied**.
- Git operation: none.
