# CODEX → FOUNDER — PERSONA RULING RECORDED / STAGING COST QUOTED

**Date:** 2026-09-12  
**Status:** DESIGN DECISION RECORDED / PROJECT CREATION AWAITING EXACT GO  
**Authority:** Founder's “I confirm” response to the recommended one-use test-account sign-in and existing-organisation choice  
**Owner:** Astra / Codex; Founder remains sole approver  
**Owning action:** OA-ZYRA-286 — remains open

## 1. Outcome and scope

DR-ZYRA-229 records the Founder's narrow persona-exchange decision and the
previously described session-check limitation. It prospectively qualifies
DR-ZYRA-228 item 6 without rewriting that historical decision. Current feature
scripts, summaries, settings, handover, release runbook and broker README now
agree with the ruling. Message 091 remains an immutable earlier snapshot;
its pending design questions are settled by this report, not by a source change.

The permitted broker response contains only a short-lived, one-use `token_hash`
over TLS for immediate native `verifyOTP` redemption. The hash is sensitive
authentication material: never embedded, logged, displayed or persisted. It
does not authorise the broker to return passwords, service keys, action links,
email OTPs, or access/refresh tokens. The ordinary persona session resulting
from Auth is distinct from that ephemeral exchange material.

Fresh server `getUser`, fresh Admin Founder checks, independent exact pins,
fixed synthetic allowlist, session-row/`not_after` and database checks, durable
rate limiting, no-store responses, successful issued audit, and independently
proved 120-second expiry/replay rejection all remain required. Accepting the
documented `auth.sessions` limitation does not make the row check complete
GoTrue time-box, inactivity or single-session validity proof.

## 2. Organisation and cost — not creation

The Founder selected the existing organisation `ZYRA-APP-LAB's Org`, ID
`pdekarsldtaqlqdthgwh`, for staging preparation. Supabase reports its plan as
`free`. Its project-cost response was:

```json
{"type":"project","recurrence":"monthly","amount":0}
```

The zero monthly quote was shown to the Founder. The proposed exact project
is **ZYRA Test**, in **EU West (Ireland), `eu-west-1`**, separate from production.
An asynchronous approval question asks whether to create this one empty backend
at that quote, with no production copy, migration, role change or Apple upload.
That question has not been answered as of filing. The cost-confirmation tool
returned a cost ID; it did not supply a new user decision. Neither that ID,
preselected UI choices nor the earlier organisation selection authorises
project creation. No project has been created in this work.

## 3. Verification and remaining gates

- Register diff confirms DR-ZYRA-228 and earlier history are byte-preserved;
  only DR-ZYRA-229 and the register's total/next-identifier footer were added.
  Next DR identifier is 230. Only OA-ZYRA-286 was reconciled; no OA was closed
  or allocated, and the next OA remains 287.
- True pre-files were captured before each edit, not reconstructed. The ten
  changed files and SHA-256 values are recorded below. Targeted searches found
  no stale pending token/session ruling or Deno-unavailable statement in these
  current feature documents. Historical messages/scripts are not rewritten.
- A second Codex agent read the ten snapshot-to-current diffs and found no
  material inconsistency or authority expansion. This is internal review,
  not external verification or Founder approval of any live action.
- Edge runtime source, policy, policy tests and dependency config still match
  message 091 exactly. No Dart, SQL, native configuration or resource pin changed.
  The eleven Deno policy passes and clean entrypoint check are 091 evidence,
  not new executions. Full Flutter/analyzer/visual suites were not rerun for
  this documentation-only reconciliation.
- Both staged SQL runtime harnesses remain unrun. Project creation, schema
  replay, synthetic fixtures, Founder/persona Auth provisioning, OAuth, source
  pin assignment, deployment, Apple identity, archive, upload and final device
  acceptance remain separate unfinished work under OA-ZYRA-286.
- No production read/write, SQL/reset/replay, service startup, account/role
  change, signing/archive/upload, approved-pixel update, or git command occurred.

## 4. True pre-state and complete ledger

All paths below are relative to `DEVELOPMENT/SUB BUSINESS/ZYRA`.
Snapshot directory:
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_RULING_PRESTATE.hgP9I7/`.
Snapshots preserve actual pre-edit bytes and end in `.pre`; they are not
current governed documents or reconstructed audit anchors.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `8b56176a972e68cf33f96395d10295a449b6af1f141906c0dbb198fa9db7584e` | `60e5c15c09ff67f1f91c64ef979e8969b507bc3b65b35a35ce008cda760049e4` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `ac9025fc53a2f68d48683b68e1de7e7b98eef65b4ccbc7b59780c7ec5f4406a2` | `b7049be77e547e248dbc4623c105be0887782c8cc360033a13e97ebb373cb0b0` |
| `SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V3.md` | `76147a65c753558f81427eb6243af5de8d1e9593e1f4c3502ebca75ccc963d3f` | `c6583a712a3d15b43b3cb777f1ee3ddfceb2b7df0a34caf83e3584b24a56e35c` |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md` | `b223bb5e70ac54ca186fdd5e9c2626f15103ec3b02dbf29d4ed5ab40337d1140` | `f3e13b0f70c75d3b549e41f721324a7934c0244c52f9ab9b59f2e6b4aa8bcc93` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md` | `3651b7895f0425bb074484dbf870a4884119a678bfb433576629f35c0f2ab5d1` | `63a0948d7469391e6727608b0067b682d868def2bcd799eef489de536e1666b7` |
| `APP/Developer Mode/Summary.md` | `84c478b87cf45e55d60fb777fad1596f5c0d1707122b378f45c3680c0abcdbf4` | `21f982fb5d31080d60066895b5158c123020d4860aafb434848842bd61f9fe14` |
| `APP/Authentication/Summary.md` | `9f7d68375a3ad898135e06bc96c43134dcb375547cdcfa6afc7d2a11370dfcfc` | `008a9aeeb30c74f657e51a9acfbf0962c6b940f33023e394d8de722f05d5d600` |
| `SOURCE/supabase/functions/zyra-founder-persona-session/README.md` | `1f60d7fdad3850f8617e45c5334104135e27e8ff532dffc2ca69726a27e6699f` | `6043c61e965a0c3527102612f668cdaf9316980248a76ceebeb8d0f39d5cdd76` |
| `APP/Authentication/Script/Script_V3.md` | `198965a917e2ae899f34a32ec2790a205433b496ade2919c39f79c6b8adba837` | `9176c1a29c843e38c844f2b7ecc511fb850e743e1e1c56e6a733adec7a9c88a3` |
| `APP/Developer Mode/Script/Script_V4.md` | `88d4d76ecd1b620ae522689dc8844572603bdf684c918c7b9d39256ee1f1c130` | `a34e4b234607f8a8427548f86f88304d76bae66eb0985184bf22cae695be4c2d` |

Snapshot filenames respectively: `DECISIONS_V1.md.pre`,
`OUTSTANDING_ACTIONS_V2.md.pre`,
`ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V3.md.pre`,
`ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md.pre`,
`ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md.pre`,
`Developer_Mode_Summary.md.pre`, `Authentication_Summary.md.pre`,
`README.md.pre`, `Authentication_Script_V3.md.pre`,
`Developer_Mode_Script_V4.md.pre`.

This report is new (pre-state ABSENT). It records a Founder ruling and local
reconciliation; it is not self-approval of deployment or of the finished Test app.
