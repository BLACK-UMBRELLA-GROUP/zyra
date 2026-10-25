# 115 — Build 3 exported and verified; upload credential handoff

**Date:** 2026-09-12
**From:** Codex — Operations, Governance & Delivery
**To / only approver:** Founder
**Work:** OA-ZYRA-286
**State:** Signed internal IPA EXPORTED and INTERNALLY VERIFIED. Upload NOT RUN.
Founder-operated credential entry is pending. Build 2 remains in TestFlight.

## 1. Exact authority and successful resumption

After the stopped check recorded in 114, the Founder replied **Approve** to:
one repeat signature verification with normal Mac keychain access, no rebuild or
trust-setting change, then resume the already-approved build-3 delivery only if
it passes; stop on any further failure. This is not standing retry authority.

The exact archive's four recorded byte hashes were checked before the single
repeat verification. At **19:41:15 UTC**, `codesign --verify --deep --strict`
returned **0 / PASS** in normal Mac keychain context. No source rebuild, trust
repair or signing replacement was needed for this check. The earlier restricted-
environment failure is preserved unchanged in 114 and its one-use evidence.
The environment difference is established; no failed check was silently waived.

At **19:42:40 UTC**, one `xcodebuild -exportArchive` operation succeeded using
the verified archive and existing internal export options. It included only
`-allowProvisioningUpdates`, not device-registration permission. Destination was
`export`, not `upload`. All **478** source pins remained unchanged.

At **19:43:27 UTC**, final exported IPA signature, identity, profile and
entitlement verification passed using normal Mac keychain access. No upload,
new build assignment, production operation, migration, git or public release
has occurred in this round.

## 2. Exact exported artifact

IPA:

`/private/tmp/zyra-main-internal-1.0.0-build3-20260912.HvNXDL/export/ZYRA.ipa`

**SHA-256:** `c7a984d9a2c3ea486a28717c6f276cab0a1bcac452a1138e16866681cd08958b`

Size: **24,621,273 bytes**. Hash rechecked after uploader preparation; unchanged.

| Verified item | Value |
| --- | --- |
| Apple ID / bundle | 6810741513 / app.zyraconnect.zyra |
| Team / provider | 9Y7Z8F36SJ / 6d66bbe2-8ad1-479b-8938-8e3722d8d38e |
| Version / build / runtime name | 1.0.0 / 3 / ZYRA |
| Minimum OS / architecture | iOS 15.0 / arm64 |
| Embedded internal-only flag | TFInternalTestingOnly=true |
| Non-exempt encryption | ITSAppUsesNonExemptEncryption=false |
| Application identifier | 9Y7Z8F36SJ.app.zyraconnect.zyra |
| Entitlements | get-task-allow=false; beta-reports-active=true; Apple sign-in Default |
| Distribution certificate SHA-1 | A27EAF3659989C7DF469F1A10B1C11F799E4FC73 |
| Store profile UUID | 07c3e51d-0bc9-41a9-8b54-ce5be5c94a19 |
| Store profile SHA-256 | 9901ffde2f863c8af8dee4e9ff3c03f032808f2c63e83acdb988dd46cb056293 |

The Distribution certificate and embedded Store profile match the existing
build-2 assets, with September 2027 expiry. The distribution summary reports
the same certificate/Team for all three embedded frameworks. Final deep/strict
signature verification passed; the exact profile is not a device profile.

Fresh post-export Chrome inspection showed the existing main App ID
`3B2LH9N6VS`, exact Team/bundle and unchanged enabled IAP, Push Notifications
and Sign In with Apple capabilities. Save was disabled; no edits occurred.
Fresh App Store Connect inspection showed `admin@zyraconnect.app` and only
build 2, still Testing in Founder Internal, with one invite/install. Build 3
was absent from uploads and builds. No new app registration was created.

## 3. Export warning and remaining authentication boundary

The export log contains a store-configuration lookup warning for account
`(null)`: Code 1085, no provider associated with that App Store Connect user.
Export nevertheless returned success, and the resulting main-company package
passed local distribution-signature/profile checks. This warning is preserved;
it does **not** prove upload authentication succeeds, nor did an upload fail.
No account was switched or repaired in response. OA-ZYRA-286 retains the issue
until authenticated upload/post-verification resolves or narrows it.

Installed official `altool.1` documentation supports uploading the exact IPA
with app-specific-password authentication; omission of the password argument
makes it read stdin. No documented path was found for using the Xcode session
to upload an already-exported exact IPA. Xcode's upload destination re-exports
an archive, so it is not used here. No cached credential extraction is permitted.

A subagent's sandboxed `altool --help` inspection failed on cache/packaged-
resource access. It was not an authentication/upload call and was not retried.
Syntax was read from the installed official manual instead. Normal-access
`xcrun --find altool` resolves the official selected Xcode executable:
`/Applications/Xcode.app/Contents/Developer/usr/bin/altool`.

## 4. Prepared one-use, hidden-input upload

Prepared helper, **not executed**:

`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-main-build3-delivery.HvNXDL/upload_once.py`

SHA-256: `80641e251ec5d0dcb6e6a64e6d23272efd884f5d0ab195f41e05ae622121853f`.

It pins the exact IPA/hash, company account, provider, Apple ID, main bundle,
version/build and verified internal-only state. It requires a real TTY, disables
and checks ECHO/ECHONL before accepting input, restores terminal flags and has
no visible-input fallback. The app-specific password goes only to altool stdin,
not arguments, environment variables, browser, Keychain or disk. Raw Apple
responses are not saved; evidence retains only status words, UUIDs and numeric
codes. Exclusive session/upload markers prevent a second invocation. The
wrapper stops on drift, error or timeout and terminates its own process group.
No historical build-2 or cancelled Test helper is reused.

Internal offline review: **12/12 PASS**, including real local PTY tests with a
fake string (no echo; terminal settings restored), non-TTY denial, exact target
and hash guards, single-use behavior, stdin-only handling and process cleanup.
One preparation finding—missing cleanup after a normal nonzero child exit—was
fixed before any real invocation and the updated helper was retested. No real
Apple process, network, credential or Keychain operation occurred in these tests.

Test file:
`evidence/oa286-upload-offline-review.71QY5b/test_upload_offline.py`

Test SHA-256: `01ee17f383aeb672b7dd65c605538f21eb3f6f00f815640e0e3f880d9f308008`.
The same directory preserves initial and corrected helper snapshots. This is
Codex internal verification, not independent approval or Founder acceptance.

The Founder has been asked to generate a fresh company app-specific password
named **ZYRA Build 3 Upload**, keep it private and reply Ready. Generation and
security prompts are Founder-operated. No password/prompt has been captured,
and no upload-session/start/result marker exists at filing. Only after the
Founder is ready should the reviewed helper run in a normal interactive Terminal:

```sh
/usr/bin/python3 "/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-main-build3-delivery.HvNXDL/upload_once.py"
```

Never enter a password into chat, a screenshot, command arguments or a normal
shell prompt. Do not run the helper speculatively or repeat a failed invocation.
The existing named build-3 delivery GO covers one upload after successful
verification; no new final-hash approval is being invented for this build.

## 5. Evidence and true pre-states

Evidence root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-main-build3-delivery.HvNXDL/`

| Result file | SHA-256 |
| --- | --- |
| resume-verification-result.json | 5a3dcc4638bfb3473ee4b60f63d6200126ebd37923fe35f0e130bfcd2e0baddd |
| export-result.json | 388395c594cf7d92695efcf423a738ff55540abad78110edff3fad378296181c |
| verify-export-result.json | f21f08bb8d36306a5642b2a92d46aa6d16a6360cd4da4656be8bf2a4d26007a1 |

Executed scripts and exclusive start/result markers are preserved. Do not replay
the archive, repeat verification or export scripts. `export.log` retains the
warning and success. No source change or Flutter suite rerun occurred this round;
112's dated **910 PASS / 60 known visual failures**, clean analyzer and focused
security checks remain distinct from the packaging checks here. No full-suite
PASS, visual waiver or device acceptance is claimed.

True current-document preimages were copied **before editing**, under their
basenames in `evidence/oa286-build3-resume-prestate.D6leTj/`. Current paths below
are relative to `/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/`.

| Current file | True pre SHA-256 | Post SHA-256 |
| --- | --- | --- |
| AGENTS.md | f934b2964475d6fb4e1cdb7cbc32cb8523ea155593d65738ea1c1527566c36b0 | 20e4c59676803b7a9302f6fbd72daa3bcea3a75f89fc717a63ecf0b58aee8c09 |
| SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md | fe823101eeb461ee74ea915e6ff48519f44137e4452ac85496d8d5181ebd1c0a | 3d865d4963ae8528138e9d1eae5b44e7b2c8772b1bc7a51c61be8172fca12ab5 |
| SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md | 5d00e83b8032064754a1f12fdd4645542a172b6d0d9c867d67105035928e4e45 | 82809cb3d00f6ae64c3788e75c239d4d9b72e87039160af57d5fa5d9a3639c76 |
| SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md | 0faef91613fb092533babe00232a663685fe8af9cab9c4ab84eca17ef3d770c0 | fe17647b6dd4578e7936414a680266813d48ca0e99353c19fd3caf824653c60a |

The register's true preimage is separately preserved in
`evidence/oa286-build3-resume-prestate.M4xE10/OUTSTANDING_ACTIONS_V2.md`.
Only OA-ZYRA-286 changed; it stays open and all counts/NEXT IDENTIFIER are
unchanged. Generated index filing hashes accompany this report in evidence.
No new OA, CLAUDE edit, historical-report rewrite or governance-model change is
included. The operations skill required preserving the earlier stop and recording
this separately approved resumption, not treating preparation as delivery.

## 6. What remains

Founder credential entry → one exact upload → verify Apple processing and
internal-only build → assign build 3 to the existing Founder Internal group
only, sole tester `admin@zyraconnect.app`, automatic distribution OFF → Founder
updates from TestFlight and checks company Developer Access and personal-member
behavior. Any failed check, upload failure or target drift stops the workflow;
no retry, source rebuild, new app/device or production change by implication.
Public release and unrelated production/security gates remain closed.
