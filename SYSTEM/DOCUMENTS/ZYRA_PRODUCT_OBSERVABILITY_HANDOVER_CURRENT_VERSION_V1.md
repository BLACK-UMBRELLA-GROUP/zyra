# ZYRA — Product Observability Implementation Handover

**Version:** V1  
**Status:** CODE COMPLETE — Phase 2 local/staged slice and live-local AIOS Founder surface; production collection and migration held  
**Date:** 2026-09-18  
**Builder:** Codex  
**Verification:** Focused automated checks complete; independent review pending  
**Authority:** Founder direct instruction “ok start building”; DR-ZYRA-239; OA-ZYRA-256; OA-ZYRA-297

## 1. What exists

`ZyraProductTelemetry` accepts only typed feature/event/surface values, keeps
the latest 200 events in process memory, and exposes a read-only snapshot. It
records Seeker and Guardian shell destinations plus the Seeker ZYRA Code
route. Remote transmission is compile-time disabled in the ordinary build.

The Founder-only Health & Usage screen reports the true compile state,
session counts, remote accept/failure counts and the privacy boundary. It is
reached by long-pressing the `Developer Access` title, so the approved five-
pill landing remains unchanged.

Phase 2 adds `ZyraReliabilityMonitor`, a 100-item in-memory channel accepting
only four fixed technical fingerprints. Flutter framework, unhandled platform,
backend-startup and native-identity failures increment local counts without
capturing exception text, stacks, routes or member values. Health & Usage now
shows those truthful local counts. Both real ZYRA Code entry flows now record
started/completed/failed outcomes through the existing typed product channel.

Migration `20260918171910_oa256_product_telemetry_foundation.sql` creates a
private identifier-free table and authenticated write RPC. It now also stages
a fixed 30-day prune function, service-role-only aggregate summary,
transaction-scoped caller serialization and a 5,000-events-per-minute global
circuit breaker. It is staged only and has not been applied.

Phase 2B extends the existing closed event API across Membership, Support,
Identity Check and Guardian-management actions. The new call sites pass enums
only. Support search/question text, identity outcomes/reasons, Guardian ids,
names, relationships and server errors are not event fields.

Phase 2C adds an independent fixed action enum and makes the Founder view
zero-inclusive. Feature totals can now be separated from the specific
governed action used, and unused features/actions remain visible with a zero
count. The still-staged server schema and aggregate function carry the same
fixed `action_key`; production transmission remains off.

Phase 2D adds a dedicated **ZYRA Health & Usage** page to the existing AIOS
portal. `zyra_observability_engine.py` owns a strict, aggregate-only file
contract; `workspace_home.py` renders the Founder report; and `workspace.py`
serves `/zyra-health` plus the read-only `/api/zyra-health` endpoint. Full
AIOS Founder scope is required. Customer-scoped ZYRA portal sessions do not
see the navigation item and receive 403 on both routes.

## 2. Live files

| File | Responsibility |
|---|---|
| `SOURCE/lib/services/zyra_product_telemetry.dart` | Typed taxonomy, bounded memory, default-off remote sink |
| `SOURCE/lib/services/zyra_reliability_monitor.dart` | Bounded fixed-category local health evidence |
| `SOURCE/lib/main.dart` | Framework/platform hooks plus fixed startup fingerprints |
| `SOURCE/lib/screens/dev/zyra_health_usage_screen.dart` | Founder truth view |
| `SOURCE/lib/screens/browse/find_by_zyra_code_screen.dart` | Known-person funnel outcomes |
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | Guardian-link funnel outcomes |
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | Role-aware Membership open evidence |
| `SOURCE/lib/screens/settings/help_support_screen.dart` | Support open/self-service/email funnel |
| `SOURCE/lib/screens/onboarding/identity_verification_screen.dart` | Identity Check open/start/terminal outcomes |
| `SOURCE/lib/screens/wali/guardian_detail_screen.dart` | Guardian-management action outcomes |
| `SOURCE/lib/screens/dev/developer_access_screen.dart` | Protected long-press entry point |
| `SOURCE/lib/screens/home/home_shell.dart` | Seeker shell and ZYRA Code evidence |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | Guardian shell evidence |
| `SOURCE/supabase/migrations/20260918171910_oa256_product_telemetry_foundation.sql` | Staged private storage/RPC |
| `SOURCE/test/zyra_product_telemetry_test.dart` | Default-off, typed, bounded and UI truth tests |
| `SOURCE/test/zyra_product_telemetry_migration_test.dart` | Static SQL security/taxonomy tests |
| `SOURCE/test/zyra_reliability_monitor_test.dart` | Fixed-field and bounded-memory health tests |
| `SOURCE/test/zyra_observability_funnel_wiring_test.dart` | Role-aware screen and closed-API wiring tests |

### Phase 2C edit-time lineage

| File | True Phase 2C pre-state SHA-256 | Phase 2C post-state SHA-256 |
|---|---|---|
| `SOURCE/lib/services/zyra_product_telemetry.dart` | `89ccb7f7d62c6ef6affc28bc0b099307fa69668eb9c8a3d251309300a1b726a1` | `a5afb057c224d32d927554f7b3f5be64320183b93431d90bd48e833331c8f15e` |
| `SOURCE/lib/screens/dev/zyra_health_usage_screen.dart` | `e8b60b017512160355ebeb2f551b7244c5d0741dde7178cbc751046da333bfbf` | `1fc363200a01d8f29f387d3635a73596dfc571509fd1860a58a266eef3652a31` |
| `SOURCE/lib/screens/home/home_shell.dart` | `c2f76b13e20488c03cc5f9a9e7e4642b4507e5e2cb97fe101e02797b5dea3c6f` | `9e1cd277346f86ad2b58ce7a9be5b7cdbe109f5bd044876f94a1de8eeb3abe60` |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | `c617c9c98e61d10ffb5758087c41b633518101f9c41714d55e6d7659d04421eb` | `bff37639eb83ec7cf8a3eacec49887b784ad3c55131901a21c6bb87f50cb8fc9` |
| `SOURCE/lib/screens/browse/find_by_zyra_code_screen.dart` | `1d201a3b40cc39f688b17688f53c9d48b215558b33c2629f94097a1467700f00` | `0f11597d93cb07428de10f992757448bb5abcee92dbade6f275c1e8092975c68` |
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | `fd9ad33ad8a0ae9d434fe04606a2c0947e91ed54df5cbd787c6f2c33dd5cba89` | `83bd29054e4daae55f9ee0bfc510393b3d41f859d489b429ce4f3a8fce1a5518` |
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | `b554eb780ae93e2fc3aa93e1d38dd2858757f8f125f6535e7096638c6c67834e` | `dbc596b99a2d2da7bc1c187d8833c49be29f3d6760a3c4a35cd9d1aa243b1ef0` |
| `SOURCE/lib/screens/settings/help_support_screen.dart` | `755738560b0e714f798e33bfa26f460cafceeeb5c8e8d47caf6b1870c8ed759d` | `5b02cc5c6145913ccc0a5b20baffda5331977beae3c01b853cd8dcb57f3cfc82` |
| `SOURCE/lib/screens/onboarding/identity_verification_screen.dart` | `0b431fb061a3ae9c7bb6e0209fd1777f671067ec9700d204585f8187681de0d2` | `f9457c1b4c729182221a4b7afd2d24f27559ededf2c7e5393e08493e5efd2fa6` |
| `SOURCE/lib/screens/wali/guardian_detail_screen.dart` | `d7a8c42c850a8081e94838d7d4405a2fb04ed9ab3da6284d2b568d9a67607389` | `43d320d7fdeb8658b63e8471c45676bb0ae0f76fa708872fc338a0f6cd4037c2` |
| `SOURCE/supabase/migrations/20260918171910_oa256_product_telemetry_foundation.sql` | `b3fe00dac6bd964a169c97764cdd0972ceb7ddfee90dced8dc3bc35524c772ee` | `dd20f85ed308c85efca18b9e33564405fce760fc1238190dc50a6ed673614dca` |
| `SOURCE/test/zyra_product_telemetry_test.dart` | `ac67e65ffe0935885f186e5f00adbac1762479cd4faabf0b0cac2a403b60f0cb` | `716b1ae442b58450b77087d5891845fb432aed09b7018c9697119a80156091d3` |
| `SOURCE/test/zyra_product_telemetry_migration_test.dart` | `fb3d8798c50f8cdb486956147a9f4f3ca856a008e0733bee900a20297ad91249` | `ee6f49e1dcdd11330d684834b7d4f7e7ae77cc04097a5328020be24a6f7fb041` |
| `SOURCE/test/zyra_observability_funnel_wiring_test.dart` | `36e3551bfe91c1d8c8943e66ec6d8d78b904199226bd78ae8964c1619dabcd46` | `3f76a9e09ae1370cb08ea9f07635ae30d09b38c3e67e29050eaff38182d8197f` |

Phase 2C governance pre-states were captured before edit: product spec
`54347b566eea57278e5693877a99507b063614cf4a3bf7dd8a0884103f1b6d6a`,
build contract
`a2ff8157efb428f7c4b3a5ab8107a3c2aea0b70614c05d09361784feebd66c49`,
handover
`f6d57a03114519882e3703653d947b5b2354cc4720095ee31749958e196b9053`,
OA register
`92740f37be7c435914e97c4bce87d44d8431aab1274db44c271d7e6ffa3f0201`
and generated index
`09b2438950d44bea2a38c8bd275ae34933ade6cc5436f0ce08e6825b1323178d`.

### Edit-time lineage

| File | True pre-state SHA-256 | Post-state SHA-256 |
|---|---|---|
| `SOURCE/lib/services/zyra_product_telemetry.dart` | ABSENT | `89ccb7f7d62c6ef6affc28bc0b099307fa69668eb9c8a3d251309300a1b726a1` |
| `SOURCE/lib/screens/dev/zyra_health_usage_screen.dart` | ABSENT | `d29efae646b2d0be80fedc670f2e5e2522626b55424d74b85070e3304eadab1c` |
| `SOURCE/lib/screens/dev/developer_access_screen.dart` | `664e0e95365ae99057ba5dd1b2d10b4c64e7eeb11f639f6e87a073e0c28c1c8e` | `2941d3f0103f533f7cd0a60a29ad8b42a74d6a15a1a63d87a277254d23644ce0` |
| `SOURCE/lib/screens/home/home_shell.dart` | `195dc0e2f665c8264ba4e35a15c5c679f033a0d1c793d7f3cfda8e2a8c21bbeb` | `c2f76b13e20488c03cc5f9a9e7e4642b4507e5e2cb97fe101e02797b5dea3c6f` |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | `b2c8eb212451b1757983c439eddb434ee2a07be0001e31b1712ca6ff657bf689` | `c617c9c98e61d10ffb5758087c41b633518101f9c41714d55e6d7659d04421eb` |
| `SOURCE/supabase/migrations/20260918171910_oa256_product_telemetry_foundation.sql` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` (CLI-created empty file) | `3af3d0baf98260066f0d7bdbb6918ab134c4f973073406aafa62572c5b91c3ae` |
| `SOURCE/test/zyra_product_telemetry_test.dart` | ABSENT | `ac67e65ffe0935885f186e5f00adbac1762479cd4faabf0b0cac2a403b60f0cb` |
| `SOURCE/test/zyra_product_telemetry_migration_test.dart` | ABSENT | `9dd42eb5dfc6f93919976c9e25d345e66deb112fc818fd9743216c3bc26b158d` |

The generated Documentation Index was regenerated after the three governed
documents were added. Its pre-state was not snapshotted before generation;
no reconstructed value is presented as an audit anchor. This is a process
defect in this round and is stated rather than hidden.

### Phase 2 edit-time lineage

| File | True Phase 2 pre-state SHA-256 | Phase 2 post-state SHA-256 |
|---|---|---|
| `SOURCE/lib/main.dart` | `494b569deb1985e534a966ac8a9ccf56c49b38f54fdc11b237fa2f73e4882134` | `0786e4fec2a97524b5500ea30aa7cc14ade8cb44555979ad2713bfda5c7771bc` |
| `SOURCE/lib/services/zyra_reliability_monitor.dart` | ABSENT | `05364aca6e4e1e2378ed445b75904f02df5ee4b7b9513ae2bfade964762f23e2` |
| `SOURCE/lib/screens/dev/zyra_health_usage_screen.dart` | `d29efae646b2d0be80fedc670f2e5e2522626b55424d74b85070e3304eadab1c` | `e8b60b017512160355ebeb2f551b7244c5d0741dde7178cbc751046da333bfbf` |
| `SOURCE/lib/screens/browse/find_by_zyra_code_screen.dart` | `0478b0cac1615b5387e553f36a79830654a7f0204bfdda3c1369e1e0278ab22b` | `1d201a3b40cc39f688b17688f53c9d48b215558b33c2629f94097a1467700f00` |
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | `e5fee707da4b742bc7d9cfae3a53cb874c7a3d947fc01b4461c2fbacf6f4fb75` | `fd9ad33ad8a0ae9d434fe04606a2c0947e91ed54df5cbd787c6f2c33dd5cba89` |
| `SOURCE/supabase/migrations/20260918171910_oa256_product_telemetry_foundation.sql` | `3af3d0baf98260066f0d7bdbb6918ab134c4f973073406aafa62572c5b91c3ae` | `b3fe00dac6bd964a169c97764cdd0972ceb7ddfee90dced8dc3bc35524c772ee` |
| `SOURCE/test/zyra_product_telemetry_migration_test.dart` | `9dd42eb5dfc6f93919976c9e25d345e66deb112fc818fd9743216c3bc26b158d` | `fb3d8798c50f8cdb486956147a9f4f3ca856a008e0733bee900a20297ad91249` |
| `SOURCE/test/zyra_reliability_monitor_test.dart` | ABSENT | `107c51e830a043b7b2649bb4c2967b14936363b6a42e0de029cff77b71227ac6` |

Phase 2 governance pre-states were also captured before edit: product spec
`45d4990b434eec8a4a3427ba9be8ef200ea9e1602d6e8f1624ee841c1722aead`,
build contract
`25030edee39a4ef4b319813942413593c3d8ff0ec9065bf74fe2049557c7d0f8`
and OA register
`9f8a221a23ad921e92af50a50f997f1996d130ffb4d542cc736d97fc2ab70c47`.

### Phase 2B edit-time lineage

| File | True Phase 2B pre-state SHA-256 | Phase 2B post-state SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | `f908a1c8e325c730997ebeac0d4d7929be7f0aed4a267d8de6df46bec2c76f46` | `b554eb780ae93e2fc3aa93e1d38dd2858757f8f125f6535e7096638c6c67834e` |
| `SOURCE/lib/screens/settings/help_support_screen.dart` | `536cdac40d543fc6c1448b76de39e70a5734aeec5d88c03fe463149ac9e21bde` | `755738560b0e714f798e33bfa26f460cafceeeb5c8e8d47caf6b1870c8ed759d` |
| `SOURCE/lib/screens/onboarding/identity_verification_screen.dart` | `afbc67f599c032aefb79653c39b0a2f09acf2c73407502ac364ec16684873c99` | `0b431fb061a3ae9c7bb6e0209fd1777f671067ec9700d204585f8187681de0d2` |
| `SOURCE/lib/screens/wali/guardian_detail_screen.dart` | `c8a751eb465249311a4896959491404bc69fe1d994e1e005035d4ce94a042b37` | `d7a8c42c850a8081e94838d7d4405a2fb04ed9ab3da6284d2b568d9a67607389` |
| `SOURCE/lib/screens/wali/wali_network_screen.dart` | `64b66e5ec03586ac918710bd3130e50353ebc182b447e2bdcaefc5e28947ea06` | `0ca69ba1ce0d69b2dee14dfb453b1f441d7889a48c58bc7ba6436554c71c647b` |
| `SOURCE/lib/screens/wali/wali_profile_screen.dart` | `b818a8b7e398363c2951524f00a27b22506b65da5014e3dd4dd3298d8b8526d8` | `ac81ecd0f7f536c9df02365e5855e9fbfe69f61fdbfd11444e2fc1317ccb8ba4` |
| `SOURCE/test/zyra_observability_funnel_wiring_test.dart` | ABSENT | `36e3551bfe91c1d8c8943e66ec6d8d78b904199226bd78ae8964c1619dabcd46` |

## 3. Data flow

```text
typed app event
  -> bounded current-process list
  -> Founder Health & Usage view
  -> [compile gate OFF: stop]
  -> [future approved build only] authenticated RPC
  -> private identifier-free row
```

No event has a map/free-text extension point. Remote failure increments an
in-memory count and is discarded; the member action continues.

```text
fixed technical failure
  -> fixed enum fingerprint only
  -> bounded current-process health list
  -> Founder Health & Usage view
  -> stop (no remote sink exists)
```

## 4. Mock versus production

- **Live now:** typed in-memory product channel, fixed-category local health
  monitor and Founder session view.
- **Staged, not live:** private table, write RPC, aggregate RPC, 30-day prune
  function and identifier-free abuse controls.
- **Live locally in AIOS:** Founder-only aggregate report surface and
  read-only API, truthfully showing collection off.
- **Not built/activated:** production aggregate ingestion bridge, retention
  job, privacy opt-out, solicitor sign-off, Sentry/error provider, Apple API
  ingestion and scheduler integration.
- **Production collection:** OFF.

## 5. Security invariants

1. No member/caller identifier is persisted.
2. No free text, JSON payload or user-content field exists.
3. Raw table stays in `private`; clients have no direct read/write grant.
4. RPC is authenticated, `SECURITY DEFINER`, empty search path and explicit
   fixed-value guarded.
5. Client and table constraints independently enforce the taxonomy.
6. Telemetry cannot block product behaviour.
7. Reliability evidence cannot accept raw errors, stacks, routes or fields.
8. Aggregate and retention functions are service-role only.

## 6. Verification

- Phase 2 focused command covering product telemetry, migration controls,
  reliability monitor and both ZYRA Code flows — **22/22 PASS**.
- Phase 2B focused command covering Membership, Support, Identity Check,
  Guardian truth and the base telemetry view — **28/28 PASS**.
- Phase 2C focused command covering action taxonomy, staged SQL parity,
  funnels, identity, ZYRA Code fixtures and Guardian truth — **36/36 PASS**.
- AIOS observability + dashboard consistency focused command — **12/12 PASS**.
- AIOS Python compile — **PASS** with an isolated bytecode cache.
- Live-local AIOS verification — `/health` returned `AIOS Workspace OK`;
  `/zyra-health` contained the Founder-only Health & Usage surface and
  `Collection off`; `/api/zyra-health` returned schema version 1,
  `collection_enabled: false` and the complete zero-valued taxonomies.
- `flutter analyze` — **PASS, no issues**.
- Developer Access functional suite excluding its already-stale small visual
  assertion — **18/18 functional tests PASS**; the existing five text pills
  and icon-free surface remain intact.
- Current full `flutter test` — **1,636 passed, 1 skipped, 127 failed**. The suite remains
  already non-green from stale visual baselines, historical fixed migration
  counts and current developer/Guardian UI tests. The new telemetry-focused
  tests pass; no approved pixels were changed. This run is evidence of the
  existing repository-wide debt, not a clean regression claim.
- SQL runtime replay — **NOT RUN**; staged migration has not been applied to
  any local or remote database.
- Phase 2 connected-iPhone profile build **PASS (39.1s)**; direct install and
  launch **PASS** on iOS 27.0; bundle `app.zyraconnect.zyra`, version
  `1.0.0 (2)`; signed executable SHA-256
  `2159caee43bb7a06bc9e839247f2d3118b19919e034b363082ce4aacd6892759`.
  The complete round is recorded in message 145.
- Phase 2B profile build **PASS (43.0s)**; signed executable SHA-256
  `94819bfb6d5fedee61011daaf8466ac58ccb7b66d454378436236d1411d80214`.
  After the Founder restored the USB connection, the hash was rechecked,
  direct installation **PASS**, launch **PASS**, and device catalog identity
  confirmed `app.zyraconnect.zyra` version `1.0.0 (2)`. Message 146 records
  the earlier CoreDevice stop and final successful completion.
- Phase 2C profile build **PASS**; final signed executable SHA-256
  `648754b5be0aee1f12a4746e5bc5f8df07107b1f40d8fa9acdae15f6584fab7b`.
  Three direct CoreDevice installation attempts first stopped before transfer.
  The supported Flutter deployment then installed and launched the app in
  27.5s, after which Flutter lost only its local profile VM socket. Device
  catalog verification passed and a separate direct app launch passed. ZYRA
  `1.0.0 (2)` is installed and running on the iPhone.

## 7. Known gaps and owners

- OA-ZYRA-256: production privacy, independent review of staged retention,
  access and abuse controls, isolated replay, exact apply and compile-enable
  gates.
- OA-ZYRA-297: the AIOS Founder report surface is built; production aggregate
  feed, crash provider, live service-health ingestion, scheduler activation
  and bounded agent triage remain held.
- Existing broad test failures remain owned by their existing visual/test
  debt actions; no new action is raised here because this change neither
  caused nor widened them.

## 8. Authority map

- Product specification: `ZYRA_PRODUCT_OBSERVABILITY`
- Build contract: `ZYRA_PRODUCT_OBSERVABILITY_BUILD_CONTRACT`
- As-built truth: this handover
- Earlier promotion-only local taxonomy: `ZYRA_RESPECTFUL_PROMOTION_AND_PERMISSION`
- Production gate: OA-ZYRA-256
