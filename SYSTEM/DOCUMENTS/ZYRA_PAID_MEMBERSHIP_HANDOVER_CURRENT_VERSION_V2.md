> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded on 2026-09-18 by `ZYRA_PAID_MEMBERSHIP_HANDOVER_CURRENT_VERSION_V3.md`.
> The current version is `ZYRA_PAID_MEMBERSHIP_HANDOVER_CURRENT_VERSION_V5.md`, in this folder.
> This file keeps its `CURRENT_VERSION` filename deliberately. Renaming it
> would break references held in the registers and in sealed mailbox messages,
> which are never edited after filing. Recorded under **OA-AIOS-384**.
> Banner added by Fable 2026-09-23 under AD-AIOS-110. **The body below is
> unchanged** and remains the truthful record of what was current at the time.

---

# ZYRA — Paid Membership Client Handover

**Version:** V2
**Status:** CURRENT_VERSION — repriced client implemented; live paid activation held
**Date:** 2026-09-18
**Owner:** Codex under Founder authority
**Decision:** DR-ZYRA-234
**Commercial source:** `BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V4.md`
**Capability source:** `APP/Standards/JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V5.md`
**Action:** OA-ZYRA-253

## 1. Implemented client truth

The read-only Membership catalogue now presents exactly three current account
offers: **ZYRA One — Seeker at £29.99/month**, **ZYRA One — Guardian at
£19.99/month**, and **Guardian Free**. Weekly prices, the former combined
Seeker-plus-Guardian allocation and the Additional Guardian subscription card
are removed. Additional Guardian remains a relationship role throughout the
app. ZYRA Family is unchanged and no Family source was modified.

Membership and Help describe Guardian Free as Journey viewing only, with no
Journey commenting, conversation entry or Guardian Network page. Guardian One
describes Journey-wide comments, permitted conversation entry and Guardian
Network discovery/recommendations. The current conversation view remains
read-only; no message sending or comment service was invented.

The Guardian shell now derives its destinations from entitlement. Free state
renders **My ZYRA · Seekers · Profile** with no Network destination or workspace
Network shortcut. Paid state renders **My ZYRA · Network · Seekers · Profile**.
The Journey detail continues to show Journey/timeline and essential Family
Review controls for free Guardians, but does not fetch or render conversation
messages or the Family-stage answer form. Developer preview can still stage
paid Network truth explicitly.

## 2. Safety and authority preserved

- Invitation, consent, reporting, blocking, privacy and essential safety
  controls remain available without payment.
- Payment cannot create a link, promote a Guardian to Main or bypass Seeker
  permission, per-Journey assignment or romantic exclusions.
- Membership changes do not delete links, Journeys, messages or history.
- Compatibility Unlock/Plus prices and unavailable checkout remain unchanged.
- The planned fourteen-day trial is retained for Seeker One only; a Guardian
  trial is not claimed.

## 3. Deliberate activation boundary

No checkout, StoreKit/Play product, receipt verification, subscription
mutation, migration, production database change or TestFlight upload is part
of this client update. The existing `wali_has_wali_one()` server resolver still
contains the superseded bundled-Seeker path and cannot be treated as the final
commercial authority. Server-enforced Guardian comments, paid conversation
entry and Network access remain OA-ZYRA-253 work. Guardian Notes/comments also
retain OA-ZYRA-292's separate privacy and audit design gate.

## 4. Source ledger

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/data/zyra_membership_catalog.dart` | Three-product monthly catalogue and truthful trial/availability copy | `fead0fafe9eaeb06c05a7ae486663a50cf829ed292f3a8f163a30e66acd93017` |
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | Responsive Seeker One, Guardian One and Guardian Free presentation | `42900d41cb2e2c34d523e7bed627051312f863fa5ecd896caa5cc05075425262` |
| `SOURCE/lib/data/help_content.dart` | Prices and Guardian capability explanation | `d3c8d634b9a0b1f8debcd6980876618c0298dfce013f7123185450c321aaefb7` |
| `SOURCE/lib/constants/zyra_plan_names.dart` | Legacy DB-value to current member-facing name mapping | `d4c67f3160ccf0e8286e11885dae9a0e7ea64ffce2c538535f7b9c607d736efa` |
| `SOURCE/lib/services/zyra_entitlement_service.dart` | Legacy seam comment aligned to Guardian One pricing | `5e693a332cdd5199dc136c8d5d4de4341bb6e6ac543f3791fd4edda1da74a43c` |
| `SOURCE/lib/state/app_state.dart` | Legacy local Guardian plan seam aligned to current naming | `a832e77a414a473676f13be55eea4cc36760368afc34ed61bf5b418deab5bd66` |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | Entitlement-derived three/four-tab Guardian navigation | `b2c8eb212451b1757983c439eddb434ee2a07be0001e31b1712ca6ff657bf689` |
| `SOURCE/lib/screens/wali/wali_seekers_screen.dart` | Guardian membership propagated into Seeker workspaces | `4fdf70a94f5ee657fd2d685570261069de2039e3b55341cb61d596bbfe1d3a44` |
| `SOURCE/lib/screens/wali/wali_seeker_workspace_screen.dart` | Paid-only Network shortcut and Journey membership propagation | `461c685e801de257d38c84d9d3133ebc223ef0d749dd3bdb3674f9712165b813` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | Guardian membership propagated into Journey detail | `c46eeebe3c2f056f2449d571e8e04404cc5a6c3035af2a07a6d6cac44612d15e` |
| `SOURCE/lib/screens/wali/wali_journey_detail_screen.dart` | Free Journey view with paid-only conversation and Family answer participation | `149eabf6b527933a6caeab5df06e445157bd0e39812244217d003330eff743f7` |
| `SOURCE/lib/screens/wali/wali_profile_screen.dart` | Current Guardian membership name on profile and settings surfaces | `91b5d9d163a82dd26a6be09938c122a83642c52c724592a06aeb42c62f892fdc` |
| `SOURCE/lib/screens/wali/wali_network_screen.dart` | Current Guardian membership name across Network access states | `aa8cfd256016ade18f8a8b0fa420833602ff57d2af27e34190335c714b3e41aa` |
| `SOURCE/lib/services/zyra_wali_journey_service.dart` | Guardian Journey read boundary aligned to Free and One presentation | `ff034390c31dd02efbf0b43af43a4fb55497f0ae4ab9d0edb0abab9ff817ecc8` |
| `SOURCE/test/paid_only_membership_catalog_test.dart` | Prices, titles, responsive catalogue and navigation matrix | `dd5520dea1ddfaf576323a4b3b7bc2517f609e776ac8631a2df06c245cfcb628` |
| `SOURCE/test/wali_journey_detail_truth_test.dart` | Free Guardian no-conversation-fetch/render regression | `539f28d46892ef42b5c70b92afbaaa7a1a56d3d24be6e84619eafa0653d88574` |
| `SOURCE/test/guardian_network_preview_test.dart` | Guardian One product-name and four-state Network regressions | `01a2aa675b803cda4ca19e8577732f0bf89c44f2d5795ede09e205cf32f3629f` |

## 5. Verification

- Focused Membership/Guardian regression set: **46/46 PASS**.
- Full `flutter analyze`: **PASS — no issues**.
- Static structural check: **no new findings**; its known analyzer-clean
  `lib/main.dart` preview-client false positive remains baselined.
- Founder iPhone profile build: **PASS** — signed profile build installed
  wirelessly as the single `app.zyraconnect.zyra` version `1.0.0`, build `2`;
  Runner process confirmed after host detach. Built executable SHA-256:
  `72eef617ca8a29c8f5c9e6fc9891f327d45bc90e771b6702f4a4cc63c9d3d7ef`.
  Apple's explicit relaunch request was denied because the phone was locked,
  while process inventory still confirmed Runner present.
- Git operation: none.
