# Supabase key migration

## PROJECT LOCATION

- Major Folder: 10_INTEGRATIONS/
- Purpose: migrate ZYRA's Supabase API-key integration without interrupting member authentication.
- Owns: client key selection, SDK initialization and migration verification.
- References: Authentication, Developer Control, One-App Internal Delivery Runbook V2, mailbox 151.
- Referenced By: OA-AIOS-383; AD-AIOS-110; mailbox 152.
- Existing physical record location: SYSTEM/DOCUMENTS/. No folder relocation is implied.

**Version:** V1  
**Status:** CURRENT_VERSION — client migrated and device verified; TestFlight delivery pending; legacy revocation prohibited  
**Date:** 2026-09-24  
**Owner:** Codex — ZYRA Product under AD-AIOS-110  
**Authority:** Founder's direct relay of mailbox 151 in the active ZYRA task  
**Parent action:** OA-AIOS-383, owned on the group side by Fable  
**Scope:** API-key replacement only; no database migration, JWT rotation, credential revocation or storage changes.

## 1. Outcome and boundary

The Flutter app now uses the existing default publishable key for project
`sxoaxonzjqkgajmlagyk`, organization `pdekarsldtaqlqdthgwh`. No new key was
created. Both initial startup and recovery initialization use the SDK's
publishable-key parameter. The misleading main.dart comment is corrected.

The migrated profile build was installed wirelessly on the Founder's paired
iPhone and cold-launched. Supabase logs confirm successful member-session
refresh with the modern application key after installation and after the
cold launch. A signed, internal-only TestFlight candidate is prepared but
has NOT been uploaded or assigned to testers.

Legacy API keys remain enabled. The JWT signing secret was not rotated.
**This handover does not authorize revocation or close OA-AIOS-383.** Older
distributed binaries still need replacement; one updated phone does not prove
fleet migration. No key values, prefixes or fragments are recorded here.

## 2. As-built implementation

- `SOURCE/lib/config/supabase_config.dart`: existing production configuration
  now supplies the existing default publishable key. This local configuration
  was already ignored; no privileged server key was read or copied into it.
- `SOURCE/lib/config/zyra_supabase_config_policy.dart`: explicit publishable-key
  model, placeholder rejection and client-key-type validation. Privileged and
  legacy key types fail closed; unsupported variants still have no endpoint.
- `SOURCE/lib/config/supabase_config.dart.example`: matching public-key setup.
- `SOURCE/lib/main.dart`: both SDK initialization paths updated; member-session
  restoration remains separate from the public project key.
- Configuration/boundary tests updated; a new mocked SDK regression suite covers
  login, refresh, same-project session persistence, denied access, revoked refresh
  and malformed stored sessions. All fixtures are artificial and HTTP is intercepted.

No dependency upgrades were made. Installed versions used for verification:
supabase_flutter 2.16.0, supabase 2.14.0, gotrue 2.26.0. Existing SDK session
storage is keyed by project host, so changing the API key does not itself change
the session storage slot. Founder authorization and preview-data isolation
were preserved; an email address is not used as an authorization bypass.

## 3. Privileged server/tooling inventory

No active consumer of the legacy service-role API key was found in the inspected
surfaces, so there was no consumer to replace with the existing default secret
key. That secret was not fetched, copied, created or changed.

Read-only checks on 2026-09-24 covered:

- App runtime, source configuration, native/build tooling and relevant active
  ZYRA executable/configuration files outside SOURCE. Archives, dependencies,
  rollback material and PRIVATE directories were excluded.
- Production Supabase: no deployed Edge Functions; custom Edge Function secrets
  inventory empty; Vault secret count zero; no cron job table or enabled HTTP,
  network or cron extensions. Relevant app routine/webhook scans found no caller.
  Extension helper definitions are not deployed application consumers.
- GitHub ZYRA-APP-LAB/zyra: Actions workflows, repository secrets, repository
  variables and environments all empty. ZYRA-APP-LAB/zyra-site workflows and
  repository secrets also empty.
- The website's waitlist endpoint is a non-operational placeholder, with no
  Supabase call or environment lookup. Cloudflare account-level secrets were
  not inspected; no website Supabase consumer was found.
- Seven inspected macOS LaunchAgent plists had no ZYRA/Supabase reference;
  the user has no crontab.
- Existing photo-upload scripts already use staging publishable credentials
  plus a member session and reject production; these were not changed.
- SQL references to the service-role database role are grants/authorization
  definitions, not embedded API credentials. They were left intact.
- A last-24-hour edge-log aggregation returned 23 requests and zero requests
  bearing the legacy service-role API credential in either inspected role field.
  This limited observation is not proof about dormant or external systems.

The conclusion is bounded to these inspected surfaces, not a claim that no
undiscovered external consumer can exist. No Git mutation, credential-folder
inspection or production database write was used.

## 4. Verification evidence

- Focused app/configuration/security suite: 46 checks passed before the new SDK
  suite; new mocked SDK suite: five passed. Unsupported-flavor compiled boundary:
  one passed. Total distinct checks: 52. Final combined rerun and analyzer results
  are recorded in mailbox 152.
- Live HTTP probes with the configured publishable key: Auth settings 200;
  unauthenticated member lookup 401; unauthenticated profile read 401. Public-key
  validity did not grant member or privileged access.
- Wireless local build: profile mode, production flavor, existing main bundle
  `app.zyraconnect.zyra`, version 1.0.0 (3), existing Founder-only compile opt-in.
  Build and installation completed; an explicit cold launch also succeeded.
- Backend evidence: member refresh responses were 200 at 09:49:07.195 and
  09:49:11.547 UTC, then 09:50:24.258, 09:50:24.565 and 09:50:28.593 UTC after
  the cold launch. Modern-key identification, Dart client and refresh grant were
  checked without returning key/token values.
- Real-device proof is **restored-session authentication and refresh**, not a
  fresh interactive password/Google/Apple login. The existing session was preserved.
- Installed AOT executable SHA-256:
  `0a015060ff988cc68a2e74220b62c65e5a963940ee93eb4a837392ca32d083d6`.
  Exact configured publishable key present; full legacy API-token pattern count zero.

## 5. TestFlight artifact and remaining delivery gate

Candidate: main ZYRA Connect 1.0.0 (5), internal TestFlight only.
Build number 5 must be checked against live App Store Connect before upload;
the browser is signed out. No existing Apple build has been changed.

IPA:
`/private/tmp/zyra-key-migration-20260924.xSGnOe/export/ZYRA.ipa`

SHA-256:
`edc9047cba8ba32354fa9b99832748e3c58629f009cb68c5ac8895f3ffd2c747`

Archive and build/export logs are in the same temporary parent directory.
These paths are local working artifacts, not a permanent release archive.

- Archive and export succeeded using existing signing configuration without
  provisioning-update or device-registration command flags.
- Export reports the retained cloud-managed distribution certificate and Store
  profile. No certificate/profile creation or revocation was requested.
- Final extracted IPA passes strict, deep signature verification; correct Team
  `9Y7Z8F36SJ`, bundle `app.zyraconnect.zyra`, minimum iOS 15.0,
  get-task-allow false and internal-TestFlight-only true.
- Final release executable contains the exact configured publishable key;
  detected complete legacy API-key patterns and server-secret values both zero.
- Export logged an App Store account/provider lookup warning. Export/signature
  success does not prove upload authentication or Apple acceptance.
- App Store Connect target: company account, app ID 6810741513, existing Founder
  Internal group, automatic distribution off. No external/public distribution,
  new tester or new App ID is included in this prepared artifact.

Remaining: Founder Apple sign-in; verify current build inventory and exact
account/provider; obtain the runbook's exact artifact upload GO; upload once,
post-verify processing and existing internal-group assignment; verify the
TestFlight-delivered app on device. Stop on failure or identity/hash drift.
Broader rollout to any other installed users remains a separate explicit gate
before final legacy-key revocation.

## 6. Source evidence ledger

All hashes below are file SHA-256 values, not credentials. Prestate hashes were
measured before implementation. Paths are relative to SOURCE/.

| File | Before | After |
|---|---|---|
| lib/config/supabase_config.dart | afe492f77c7cb3043f9dc7ae75ca67094f5caf02b14aa0e65be40070fb1000c3 | 969ebc83f6d5c3652a49f3c89095f2b4ed898cb1e424c379d496657dbb898418 |
| lib/config/zyra_supabase_config_policy.dart | d1dce327e5aba5aa739e04f60715e3dd379bd9623963032da2530e688f08afdd | cb9017b12ba503c6d16c3d7724e047691c36b7e18405b6b5160e9da5f1931b24 |
| lib/config/supabase_config.dart.example | 96211938baa9369cd4b67c0562a68c62c93606fbb9b49544ade6ea626994c08c | e2043540766f3a9d050a21292769f99ec23de104acdbff9f81e9251354830400 |
| lib/main.dart | 7c42cbb8e0f4a0c96c5ab68a29a3fd60ea865be5ab373f1e5a60eecfa5a395c5 | 9f468ba407abfac88d663cabc6aca2dc63305adebec47f5967c927ab5a8b44e0 |
| test/supabase_config_variant_test.dart | c0891c532de0acf5ca1eaf0f0a66e98df92a54cfd7535e35277ed8b74261e162 | b0da83eededdf1fe3da17e4679a0cc47060380468f8b182131fe2c0ad4a7aa76 |
| test/compiled_app_boundary_test.dart | 6f53c49b657cf3f91cf0c4abb0360992fe99c534c0a0cbdb1026d914113655ab | e9393cc884f7e7fa029b262a55abd142f3e2883726dbd8226d3cd5a807afb4f1 |
| test/supabase_publishable_auth_test.dart | absent | 5e9d338ed5ac5e1b24ef806b9b9b04d6dd23e992639ea7c2734188e259497504 |

## 7. Handover and rollback

Fable retains OA-AIOS-383 and final revocation coordination. The app migration
does not revoke an exposed privileged key. Leave legacy API keys and the JWT
secret unchanged until explicit final authority and rollout evidence exist.

No backend state was changed, so no schema/data rollback is required. Existing
older binaries remain compatible while legacy keys are enabled. Do not restore
legacy client configuration as an automatic rollback or overwrite unrelated
work in the shared source tree. Any regression requires a scoped correction
and a newly verified build. Existing unrelated changes were preserved.

OA-ZYRA-276 storage capacity/photo handling is explicitly outside this work.
No storage objects, limits, billing settings or member records were changed.
