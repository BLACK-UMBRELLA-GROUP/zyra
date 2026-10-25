# 144 — CODEX → FOUNDER — Product Observability Phase 1 Built; Migration Staged

**Date:** 2026-09-18  
**Status:** CODE COMPLETE / DEVICE INSTALLED / PRODUCTION COLLECTION OFF  
**Authority:** Founder direct instruction “ok start building”; DR-ZYRA-239  
**Actions:** OA-ZYRA-256; OA-ZYRA-297

## 1. Outcome

1. Added one privacy-safe typed event channel. It accepts fixed enums only,
   retains at most 200 current-process events and cannot carry arbitrary text
   or member identifiers.
2. Instrumented the initial high-value surface: Seeker and Guardian shell
   destinations plus entry to known-person ZYRA Code matching.
3. Added a protected Founder Health & Usage view. Long-press the `Developer
   Access` title to open it. The approved five-pill landing remains unchanged.
4. Generated one Supabase migration through the CLI and staged it only:
   `20260918171910_oa256_product_telemetry_foundation.sql`.
5. Remote collection defaults OFF at compile time. No database apply, remote
   event, provider activation, privacy-copy change, schedule activation or git
   operation occurred.
6. Installed and launched the revised profile build on the connected iPhone.

## 2. Privacy and security boundary

The staged row contains only feature, event, surface, platform, app version,
build number and server timestamp. It contains no user/profile/device/session/
Journey/Match/code identifier, user content, free text, JSON payload,
screenshots, replay, advertising id or precise location.

The table is private. Public, anon and authenticated receive no table access.
The one write RPC requires authentication, is `SECURITY DEFINER`, has an
empty search path, validates every scalar against a fixed allowlist and grants
execute only to authenticated/service_role. The client cannot read raw rows.

## 3. File ledger

| File | True pre-state | Post SHA-256 |
|---|---|---|
| `SOURCE/lib/services/zyra_product_telemetry.dart` | ABSENT | `89ccb7f7d62c6ef6affc28bc0b099307fa69668eb9c8a3d251309300a1b726a1` |
| `SOURCE/lib/screens/dev/zyra_health_usage_screen.dart` | ABSENT | `d29efae646b2d0be80fedc670f2e5e2522626b55424d74b85070e3304eadab1c` |
| `SOURCE/lib/screens/dev/developer_access_screen.dart` | `664e0e95365ae99057ba5dd1b2d10b4c64e7eeb11f639f6e87a073e0c28c1c8e` | `2941d3f0103f533f7cd0a60a29ad8b42a74d6a15a1a63d87a277254d23644ce0` |
| `SOURCE/lib/screens/home/home_shell.dart` | `195dc0e2f665c8264ba4e35a15c5c679f033a0d1c793d7f3cfda8e2a8c21bbeb` | `c2f76b13e20488c03cc5f9a9e7e4642b4507e5e2cb97fe101e02797b5dea3c6f` |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | `b2c8eb212451b1757983c439eddb434ee2a07be0001e31b1712ca6ff657bf689` | `c617c9c98e61d10ffb5758087c41b633518101f9c41714d55e6d7659d04421eb` |
| `SOURCE/supabase/migrations/20260918171910_oa256_product_telemetry_foundation.sql` | CLI-created empty `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `3af3d0baf98260066f0d7bdbb6918ab134c4f973073406aafa62572c5b91c3ae` |
| `SOURCE/test/zyra_product_telemetry_test.dart` | ABSENT | `ac67e65ffe0935885f186e5f00adbac1762479cd4faabf0b0cac2a403b60f0cb` |
| `SOURCE/test/zyra_product_telemetry_migration_test.dart` | ABSENT | `9dd42eb5dfc6f93919976c9e25d345e66deb112fc818fd9743216c3bc26b158d` |
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_OBSERVABILITY_CURRENT_VERSION_V1.md` | ABSENT | `45d4990b434eec8a4a3427ba9be8ef200ea9e1602d6e8f1624ee841c1722aead` |
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_OBSERVABILITY_BUILD_CONTRACT_CURRENT_VERSION_V1.md` | ABSENT | `25030edee39a4ef4b319813942413593c3d8ff0ec9065bf74fe2049557c7d0f8` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `00dd434f4efe90f0946f409edca0ff082e8bc2fb99c4853ccb19dcc11d58cbbb` | `8fe24f5a805fbfad1ac9043762dca2db61cfc98c6c9f0cdffca1f0d39ae262ce` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `8bddfb12de8658b5201175bd43b2a388d71e728a5661f8db347ad9f4bfabd391` | `9f8a221a23ad921e92af50a50f997f1996d130ffb4d542cc736d97fc2ab70c47` |

`ZYRA_PRODUCT_OBSERVABILITY_HANDOVER_CURRENT_VERSION_V1.md` was new. The
generated Documentation Index was regenerated to 696 documents / 112 current.
Its pre-state was not captured before generation. No reconstructed hash is
represented as a true audit anchor; that process defect is explicitly filed
in the handover.

## 4. Verification

1. Focused telemetry and migration tests: **7/7 PASS**.
2. Flutter analyzer: **PASS — no issues**.
3. Developer Access functional suite: **18/18 functional tests PASS**; five
   text pills and icon-free presentation preserved. Its pre-existing small
   visual hit-test assertion remains non-green.
4. Full suite: **1,631 passed, 1 skipped, 128 failed**. Failures are the
   existing stale visual baselines, historical migration-count pins and
   current developer/Guardian UI test debt. No baseline was regenerated and
   no clean full-suite claim is made.
5. iPhone: Xcode build **82.7s PASS**; install/launch **21.5s PASS**;
   `app.zyraconnect.zyra` version `1.0.0 (2)` confirmed and relaunched.
6. SQL runtime replay: **NOT RUN**. Production and local databases unchanged.
7. `python3 tools/zyra_check.py --all`: broken imports, bad named arguments,
   missing imports, unused imports and new dangling references are clean. Its
   known parser false-positive reports `ZyraInternalPreviewClient.create` as
   missing even though that static method exists at line 38 and Flutter
   analyzer passes. No action raised: measured tool limitation, not a source
   defect.

## 5. Next gates — not authorised by this round

1. Independent SQL/privacy review, retention/deletion and abuse-control
   completion.
2. Isolated PostgreSQL replay and direct-call matrix.
3. Separate exact-file/hash Founder apply GO.
4. Post-apply verification.
5. Separate compile-enable release decision and disclosure update.
6. OA-ZYRA-297 crash diagnostics, Supabase/Apple health inputs and the existing
   daily Founder-report integration.

— Codex
