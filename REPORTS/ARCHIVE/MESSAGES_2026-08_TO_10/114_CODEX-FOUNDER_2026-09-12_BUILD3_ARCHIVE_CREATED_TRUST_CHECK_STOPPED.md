# 114 — Build 3 archive created; signature-trust check stopped delivery

**Date:** 2026-09-12
**From:** Codex — Operations, Governance & Delivery
**To / only approver:** Founder
**Work:** OA-ZYRA-286
**State:** Archive created. First signature verification failed in the default
sandbox. STOPPED before export or upload; no retry. Build 2 remains in TestFlight.

## 1. Authority and scope

The Founder replied **Approve** to one complete main ZYRA 1.0.0 build 3 delivery:
sign, verify and record its IPA hash, upload once, and assign only the existing
company tester to Founder Internal with automatic distribution OFF. The proposal
explicitly disclosed that cloud signing may create necessary managed signing
certificates/profiles. This named build-only GO replaced separate signing and
final-hash upload approvals; it did not grant standing authority for future builds.

The exact target remained Apple ID `6810741513`, Team `9Y7Z8F36SJ`, provider
`6d66bbe2-8ad1-479b-8938-8e3722d8d38e`, bundle `app.zyraconnect.zyra`, runtime name
ZYRA, version 1.0.0 build 3, account/sole tester `admin@zyraconnect.app`, existing
Founder Internal group `37600523-1fe0-4911-aeef-10502dc8a35b`.

No public release, new app/device registration, database changes or retries;
stop on any failed check or unexpected change. Founder retains credentials,
security-key prompts and agreement decisions. No trust-setting repair is approved.
The direct approval is recorded in the evidence directory's `APPROVAL.md`.

## 2. Preflight and archive results

At 19:20:02 UTC, the Xcode settings/package preflight passed: the main bundle,
company Team, production scheme, Release-production, version/build 1.0.0/3,
iOS 15.0, exact internal Founder defines and all eight cached package pins matched.
The only application target was Runner. Packages were not updated or re-resolved.

Direct Xcode archive creation succeeded at **19:23:03 UTC** using existing local
company Development signing assets. Neither provisioning-update nor device-
registration flags were used. The source manifest pinned **478 files** before
archive; the post-archive comparison reported **zero changes**.

Artifact root:

`/private/tmp/zyra-main-internal-1.0.0-build3-20260912.HvNXDL`

Archive:

`/private/tmp/zyra-main-internal-1.0.0-build3-20260912.HvNXDL/ZYRA-1.0.0-3.xcarchive`

Read-only archive metadata reports the exact main bundle/Team and 1.0.0 (3),
arm64, with `Apple Development: Shakeel Ahmad (C5LDDW3Z2Z)`. The embedded main
Development profile hash matches the preflight profile. Development entitlement
`get-task-allow=true` is not a distribution approval; a later successful export
would require a distribution profile and `get-task-allow=false`.

Fresh official Apple UI inspection also found the existing main App ID
`3B2LH9N6VS`, Team `9Y7Z8F36SJ`, exact main bundle and three enabled capabilities:
default In-App Purchase, Push Notifications and Sign In with Apple. No UI edits
or Save action occurred. No additional Apple app registration was present.

## 3. Exact stop and uncertainty

The first signature check was:

```sh
codesign --verify --deep --strict '/private/tmp/zyra-main-internal-1.0.0-build3-20260912.HvNXDL/ZYRA-1.0.0-3.xcarchive/Products/Applications/Runner.app'
```

Codex ran this in the **default restricted workspace environment**, not the
normal Mac keychain-access context used for the successful archive. It returned
exit 1, `CSSMERR_TP_NOT_TRUSTED`, architecture arm64. The workflow stopped here.

The cause is **not proven**. Earlier read-only identity inventories differed by
environment: the restricted environment returned no valid identities, while the
normal-access inventory returned two Development identities. That makes an
environment/keychain-trust limitation plausible, but does not establish it as
the cause of this failure or establish that the archive signature is valid.
No normal-context repeat verification has occurred. Neither a defective binary
nor failed Apple cloud signing is established by this result.

No retry, rebuild, export, IPA/hash, upload, Apple processing or new group/build
assignment occurred. No certificate, trust setting, profile or App ID was repaired.
The unused upload allowance is not authority to override the failed gate.

An approval request has been presented for **one repeat signature verification
with normal Mac keychain access, without rebuilding or changing trust settings,
then resumption of the already-approved build-3 delivery only if it passes**.
At filing, that request is pending. Any further failure requires another stop.

## 4. Verification evidence and archive hashes

Evidence directory:

`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-main-build3-delivery.HvNXDL/`

`preflight.mjs` and `archive.mjs` have executed and their one-use start markers
are preserved. They must not be replayed. `archive.log` records archive success;
`signature-check-stop.json` preserves the failed check and explicit limits.

| Evidence file | SHA-256 |
| --- | --- |
| source-before.json | 59ffce74ee2d3165ec44f13687e039f02b45d21fe462ffbdb40137913d940b85 |
| preflight-result.json | 07aec088e106a42e7a7a292db139b5886ab19632b4db89ee97ba7770c5fb9366 |
| archive-result.json | 3e170a59be29ce5e02ba04545097b60d6f5e4be0eaab6307f13070bf51b49e8d |
| signature-check-stop.json | 82cc9d4a3d543a69b2efdfb1e3dd31e159fb8bf189b471c13091cca9682cbd6b |

The following are byte hashes, **not proof of signature validity**. Paths are
relative to the archive above.

| Archive file | SHA-256 |
| --- | --- |
| Info.plist | cb623476b86da758fd92ddcebe9eda66fed192b4dc3eef53538b20070d5b0c7d |
| Products/Applications/Runner.app/Info.plist | 3b18b7c51a25ca1f68a8be520c36bd613f6b9629ad1b1841ad44b3bedc79c8d0 |
| Products/Applications/Runner.app/Runner | 81dc1eed12b246a7eb3f653f7e84c79031f4822b7550b40fb0c3dfe0d6cbfc12 |
| Products/Applications/Runner.app/embedded.mobileprovision | 1af45878575c7449b427169878ace2caae4d39be5425fe54e1906fe6415b96d7 |

No Flutter suite was rerun during this unchanged-source archive operation.
Report 112 remains the dated source verification: 89/89 focused runtime/security,
29/29 native/tooling, 1/1 compiled retired-flavor denial, analyzer clean; full
suite **910 PASS / 60 known visual failures**, whose actual pixels matched the
preserved pre-change evidence. No full-suite PASS or visual waiver is claimed.

## 5. True pre-state and document reconciliation

The five existing documents below were copied byte-for-byte into the evidence
directory, under their displayed basenames, **before** this turn's edits. These
are true snapshots, not reconstructed audit anchors. The register was updated
only in OA-ZYRA-286; count and next identifier OA-ZYRA-287 were unchanged.
CLAUDE's stale two-app bootstrap was corrected to the one-app, fail-closed model.
The other current documents record the bounded GO and actual stopped outcome.

Paths are beneath `/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/`.

| Current file | True pre SHA-256 | Post SHA-256 |
| --- | --- | --- |
| AGENTS.md | 5e8fd93e8685973b3bf73e27524c1e024b97c1e88139da20f3fae898f9b30428 | f934b2964475d6fb4e1cdb7cbc32cb8523ea155593d65738ea1c1527566c36b0 |
| CLAUDE.md | 2f25d3548ffc9891c3751b060e5d5989f66ffc96d4d7a1ab57fcfb8cd0fc47c3 | 1af2674e48bb3a90ca4011aa4f801f3192719ca749c606b3d3c0d95bcf30562c |
| SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md | 30d627e45a78ea1a1fa89514061825fa04c591e2f04d82386ede66d4194ddf62 | fe823101eeb461ee74ea915e6ff48519f44137e4452ac85496d8d5181ebd1c0a |
| SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md | db80ba4abcc1de098e1ae2f60260c35fe5544c6acde0f2ea874e7070838d11ea | 5d00e83b8032064754a1f12fdd4645542a172b6d0d9c867d67105035928e4e45 |
| SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md | f838e3bcad5a85d2c415650a3a59462f05f37725c713b8eb2f54e0bd44965bdc | 0faef91613fb092533babe00232a663685fe8af9cab9c4ab84eca17ef3d770c0 |

Report 113 and earlier dated records remain unchanged. Source, approved visual
baselines, migrations and existing cloud registrations were not changed here.
No git, production operation, retired Test workflow or new OA was performed.
The operations skill required truthful current-state reconciliation and true
pre-state preservation; it does not confer approval or waive this failed gate.

## 6. Remaining gate

Build 3 is **not yet available in TestFlight**. Await the named one-check
verification/resume approval; if granted, preserve this stop as history and
continue only after the fresh normal-context verification passes. After export,
verify final IPA identity/signature/profile/internal-only flag and hash before
one upload, then company-only manual group assignment. Founder device acceptance
remains separate. OA-ZYRA-286 and public-launch restrictions remain open.
