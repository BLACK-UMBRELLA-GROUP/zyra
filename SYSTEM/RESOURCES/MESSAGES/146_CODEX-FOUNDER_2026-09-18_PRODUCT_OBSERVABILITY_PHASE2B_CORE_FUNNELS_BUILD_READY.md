# CODEX → FOUNDER — Product Observability Phase 2B Core Funnels

**Date:** 2026-09-18  
**Status:** CODE COMPLETE / IPHONE INSTALLED + LAUNCHED / PRODUCTION OFF  
**Authority:** Founder instruction “continue”; DR-ZYRA-239; OA-ZYRA-256

## 1. Outcome

ZYRA's privacy-safe product evidence now covers the principal Membership,
Support, Identity Check and Guardian-management funnels. All call sites use
the existing closed feature/event/surface enums. Production transmission
remains compile-time OFF and the staged migration remains unapplied.

## 2. Coverage added

1. Membership: page opened, correctly separated between Seeker and Guardian
   surfaces.
2. Support: page opened, self-service answer completed, and external email
   launch started/completed/failed.
3. Identity Check: page opened, provider attempt started, verified completion,
   and fixed terminal/technical failure.
4. Guardian management: detail opened; history-consent, report, Make Main and
   removal actions started/completed/failed.

No Support query or question, email, identity reason/result payload, Guardian
id/name/relationship, server error, route, free text or arbitrary attribute is
accepted by the event API.

## 3. Verification

- focused funnel, identity, membership, Guardian truth and base telemetry
  checks: **28/28 PASS**;
- Flutter analyzer: **PASS — no issues**;
- iOS profile build: **PASS — Xcode 43.0s**;
- bundle/version: `app.zyraconnect.zyra`, `1.0.0 (2)`;
- signed executable SHA-256:
  `94819bfb6d5fedee61011daaf8466ac58ccb7b66d454378436236d1411d80214`.

## 4. iPhone install truth

The first two direct installation attempts stopped before installation because
Apple CoreDeviceService did not initialize. Codex restarted only the user
CoreDeviceService and wireless-pairing helper. The phone then ceased to be an
Xcode destination and Flutter reported that it must be unlocked and attached
by cable or reachable on the same network with Developer Mode (`code -27`).

No further retry was made while the device was unavailable. After the Founder
restored the USB connection, Codex rechecked the exact executable hash, then
performed one direct install and launch. Both passed. The device catalog now
confirms `ZYRA`, bundle `app.zyraconnect.zyra`, version `1.0.0`, build `2`.
The Phase 2B build has replaced the earlier local profile build on the phone.

## 5. True edit-time lineage

| File | True pre-state SHA-256 | Post-state SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | `f908a1c8e325c730997ebeac0d4d7929be7f0aed4a267d8de6df46bec2c76f46` | `b554eb780ae93e2fc3aa93e1d38dd2858757f8f125f6535e7096638c6c67834e` |
| `SOURCE/lib/screens/settings/help_support_screen.dart` | `536cdac40d543fc6c1448b76de39e70a5734aeec5d88c03fe463149ac9e21bde` | `755738560b0e714f798e33bfa26f460cafceeeb5c8e8d47caf6b1870c8ed759d` |
| `SOURCE/lib/screens/onboarding/identity_verification_screen.dart` | `afbc67f599c032aefb79653c39b0a2f09acf2c73407502ac364ec16684873c99` | `0b431fb061a3ae9c7bb6e0209fd1777f671067ec9700d204585f8187681de0d2` |
| `SOURCE/lib/screens/wali/guardian_detail_screen.dart` | `c8a751eb465249311a4896959491404bc69fe1d994e1e005035d4ce94a042b37` | `d7a8c42c850a8081e94838d7d4405a2fb04ed9ab3da6284d2b568d9a67607389` |
| `SOURCE/lib/screens/wali/wali_network_screen.dart` | `64b66e5ec03586ac918710bd3130e50353ebc182b447e2bdcaefc5e28947ea06` | `0ca69ba1ce0d69b2dee14dfb453b1f441d7889a48c58bc7ba6436554c71c647b` |
| `SOURCE/lib/screens/wali/wali_profile_screen.dart` | `b818a8b7e398363c2951524f00a27b22506b65da5014e3dd4dd3298d8b8526d8` | `ac81ecd0f7f536c9df02365e5855e9fbfe69f61fdbfd11444e2fc1317ccb8ba4` |
| `SOURCE/test/zyra_observability_funnel_wiring_test.dart` | ABSENT | `36e3551bfe91c1d8c8943e66ec6d8d78b904199226bd78ae8964c1619dabcd46` |

## 6. Governance pre-states

- product specification:
  `442b2092c2860e931fc2cc734446f5505df8e7446454018f27cce08e8e90efcd`;
- build contract:
  `ff3f2bafae6a4e74fccff5a00cfb5fe6a78f75dd7cae83a4f3c817b80b60eaac`;
- handover:
  `a074d09df5afebadcd872e21874fc6d9def74a9c03e280c837ee818e2e3d4482`;
- OA register at the start of this documentation edit:
  `78f1cc7442a5f4c73a710fc149c743cb8a23895b6baedc16a0688f42ee984e08`;
- generated index:
  `b74cbb55ab73a47c42288203813c5ff75f7e67f1b00c2b68203e499c1100982b`.

## 7. Production state

No migration, database, provider, collection flag, scheduler, release or
cloud setting changed. Production product collection and remote crash
reporting remain OFF.
