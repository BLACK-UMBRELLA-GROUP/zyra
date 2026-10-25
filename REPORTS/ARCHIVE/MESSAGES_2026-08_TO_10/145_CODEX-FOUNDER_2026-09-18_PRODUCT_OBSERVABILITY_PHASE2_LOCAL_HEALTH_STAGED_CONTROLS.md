# CODEX → FOUNDER — Product Observability Phase 2 Local Health + Staged Controls

**Date:** 2026-09-18  
**Status:** CODE COMPLETE / IPHONE UPDATED / PRODUCTION COLLECTION OFF  
**Authority:** Founder instruction “continue”; DR-ZYRA-239; OA-ZYRA-256; OA-ZYRA-297

## 1. Outcome

Phase 2's safe local/staged slice is complete. ZYRA now has bounded local
technical-health evidence, truthful Founder health counts and completed /
failed measurement on both ZYRA Code request funnels. The still-unapplied
first-party migration now stages fixed retention, aggregate access and abuse
controls.

No event, crash diagnostic or error payload was transmitted. No Supabase
migration was applied. No provider, scheduler, compile gate, release or
production setting was activated.

## 2. Reliability boundary

`ZyraReliabilityMonitor` keeps at most 100 current-process incidents and can
record only these fixed fingerprints:

1. backend startup;
2. native app identity;
3. Flutter framework;
4. unhandled platform.

Its API has no exception, stack, route, message, metadata or arbitrary field.
The global handlers still call the prior Flutter/platform handler, so evidence
collection does not swallow or change error handling. The Founder Health &
Usage page states that this evidence is local only.

## 3. Product funnels

Both known-person Browse and Guardian-link ZYRA Code flows now record typed
`started`, `completed` or `failed` outcomes. They use the existing
`zyraCode` feature key and Seeker/Guardian surface enum. Codes, names, ids,
relationships and error text never enter the event.

## 4. Staged SQL revision

Migration `20260918171910_oa256_product_telemetry_foundation.sql` was revised
in place because it remains unapplied. It now stages:

- a service-role-only grouped summary function;
- a service-role-only fixed 30-day raw-event prune function;
- transaction-scoped serialization of concurrent submissions from one
  authenticated principal without storing that principal or its hash;
- a global 5,000-events-per-minute circuit breaker that drops non-critical
  excess evidence without persisting a caller, device, IP or session key.

Raw table access remains denied to public, anon and authenticated. The write
RPC remains authenticated, security-definer, empty-search-path and fixed
taxonomy only. Independent SQL review, isolated replay and exact apply GO are
still required.

## 5. Verification

1. Focused product, migration, reliability and both ZYRA Code flow tests:
   **22/22 PASS**.
2. `flutter analyze`: **PASS — no issues**.
3. Full `flutter test`: **1,636 passed, 1 skipped, 127 failed**. The repository
   remains non-green from the already-recorded visual-baseline, fixed
   migration-count and legacy UI-test debt. Phase 2's focused tests are green;
   no approved pixels were regenerated.
4. iPhone profile build: **PASS — Xcode 39.1s**.
5. Direct install and launch: **PASS** on Founder iPhone, iOS 27.0.
6. Installed identity: `app.zyraconnect.zyra`, `1.0.0 (2)`.
7. Signed executable SHA-256:
   `2159caee43bb7a06bc9e839247f2d3118b19919e034b363082ce4aacd6892759`.
8. SQL runtime replay: **NOT RUN**; the migration is staged and production is
   unchanged.

## 6. True edit-time source lineage

| File | True pre-state SHA-256 | Post-state SHA-256 |
|---|---|---|
| `SOURCE/lib/main.dart` | `494b569deb1985e534a966ac8a9ccf56c49b38f54fdc11b237fa2f73e4882134` | `0786e4fec2a97524b5500ea30aa7cc14ade8cb44555979ad2713bfda5c7771bc` |
| `SOURCE/lib/services/zyra_reliability_monitor.dart` | ABSENT | `05364aca6e4e1e2378ed445b75904f02df5ee4b7b9513ae2bfade964762f23e2` |
| `SOURCE/lib/screens/dev/zyra_health_usage_screen.dart` | `d29efae646b2d0be80fedc670f2e5e2522626b55424d74b85070e3304eadab1c` | `e8b60b017512160355ebeb2f551b7244c5d0741dde7178cbc751046da333bfbf` |
| `SOURCE/lib/screens/browse/find_by_zyra_code_screen.dart` | `0478b0cac1615b5387e553f36a79830654a7f0204bfdda3c1369e1e0278ab22b` | `1d201a3b40cc39f688b17688f53c9d48b215558b33c2629f94097a1467700f00` |
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | `e5fee707da4b742bc7d9cfae3a53cb874c7a3d947fc01b4461c2fbacf6f4fb75` | `fd9ad33ad8a0ae9d434fe04606a2c0947e91ed54df5cbd787c6f2c33dd5cba89` |
| `SOURCE/supabase/migrations/20260918171910_oa256_product_telemetry_foundation.sql` | `3af3d0baf98260066f0d7bdbb6918ab134c4f973073406aafa62572c5b91c3ae` | `b3fe00dac6bd964a169c97764cdd0972ceb7ddfee90dced8dc3bc35524c772ee` |
| `SOURCE/test/zyra_product_telemetry_migration_test.dart` | `9dd42eb5dfc6f93919976c9e25d345e66deb112fc818fd9743216c3bc26b158d` | `fb3d8798c50f8cdb486956147a9f4f3ca856a008e0733bee900a20297ad91249` |
| `SOURCE/test/zyra_reliability_monitor_test.dart` | ABSENT | `107c51e830a043b7b2649bb4c2967b14936363b6a42e0de029cff77b71227ac6` |

## 7. Governance lineage

| File | True pre-state SHA-256 | Post-state SHA-256 before this report/index refresh |
|---|---|---|
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_OBSERVABILITY_CURRENT_VERSION_V1.md` | `45d4990b434eec8a4a3427ba9be8ef200ea9e1602d6e8f1624ee841c1722aead` | `442b2092c2860e931fc2cc734446f5505df8e7446454018f27cce08e8e90efcd` |
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_OBSERVABILITY_BUILD_CONTRACT_CURRENT_VERSION_V1.md` | `25030edee39a4ef4b319813942413593c3d8ff0ec9065bf74fe2049557c7d0f8` | `ff3f2bafae6a4e74fccff5a00cfb5fe6a78f75dd7cae83a4f3c817b80b60eaac` |
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_OBSERVABILITY_HANDOVER_CURRENT_VERSION_V1.md` | `53a2d6ebc36f0fe375ce77c71577cc100a7400e4483ce44325d232ba898c75ab` | `a074d09df5afebadcd872e21874fc6d9def74a9c03e280c837ee818e2e3d4482` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `9f8a221a23ad921e92af50a50f997f1996d130ffb4d542cc736d97fc2ab70c47` | `82613981e70d466fab5a0c7d5b6e17b9452f84c50a9bc1e1b61d784a02975548` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md` | `32f004baff0779c69044476fe2072259d31563c4b53bf1fbd134ea5bc2d45467` | `b74cbb55ab73a47c42288203813c5ff75f7e67f1b00c2b68203e499c1100982b` |

## 8. Remaining gates

Production product evidence and remote crash reporting remain held. The next
safe work is independent SQL/privacy review and isolated replay of the exact
staged migration, plus a separate Founder decision on any remote diagnostics
provider, cost, processing region and activation. Agents still may not apply,
deploy, release or self-approve.
