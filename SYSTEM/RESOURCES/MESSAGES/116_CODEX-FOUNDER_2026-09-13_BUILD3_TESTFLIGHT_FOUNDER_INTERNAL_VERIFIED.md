# 116 — Main ZYRA build 3: private TestFlight delivery post-verified

TO: Founder  
FROM: Codex  
DATE: 2026-09-13  
WORK: OA-ZYRA-286  
STATE: EXECUTED → POST-VERIFIED; Founder device acceptance PENDING

- Main ZYRA 1.0.0 (3) uploaded successfully, Apple processing completed, and the
  existing Founder Internal group now has this build available for testing.
- Only admin@zyraconnect.app remains a tester; automatic distribution remains
  OFF. Build 2 is retained. No public or external release.
- Founder opens TestFlight → ZYRA Connect → Update to 1.0.0 (3), then uses
  Continue with Google → admin@zyraconnect.app for local developer previews.
- This proves delivery, not installation or actual-device acceptance. OA286
  remains open; no approval of the app's runtime outcome is inferred.

## 1. Authority and scope

The Founder's bounded main-build-3 approval covered signing, verification/hash,
one upload and private assignment to the existing company tester with automatic
distribution OFF. The separate normal-keychain verification/resume GO and the
preserved earlier stop are recorded in 114–115. This report closes the delivery
step of that named workflow, not all OA286 work.

The Founder manually completed credential entry and reported “upload finished.”
Codex read the safe local result metadata and inspected the actual company App
Store Connect state. Codex did not rerun the uploader, rebuild, re-export, alter
trust or reuse a failed/consumed one-use marker. No database, source, role,
provider, certificate, App ID, tester or public-distribution changes in this
round. No git and no PRIVATE-tree access.

## 2. Exact artifact and Apple target

| Item | Verified value |
|---|---|
| App | ZYRA Connect; device display ZYRA |
| Apple ID | 6810741513 |
| Team | 9Y7Z8F36SJ |
| Provider | 6d66bbe2-8ad1-479b-8938-8e3722d8d38e |
| Bundle | app.zyraconnect.zyra |
| Version / build | 1.0.0 / 3 |
| Build UUID, resolved from Apple UI | f3da4df4-9113-48d0-9ac7-0ae96e437156 |
| Group | Founder Internal |
| Group UUID | 37600523-1fe0-4911-aeef-10502dc8a35b |
| Sole tester | admin@zyraconnect.app |
| Build distribution | Manual for Xcode Builds — automatic OFF |

IPA:
`/private/tmp/zyra-main-internal-1.0.0-build3-20260912.HvNXDL/export/ZYRA.ipa`

SHA-256 `c7a984d9a2c3ea486a28717c6f276cab0a1bcac452a1138e16866681cd08958b`;
24,621,273 bytes. Re-hashed unchanged after the Founder reported completion.
The approved uploader also re-hashed unchanged at
`80641e251ec5d0dcb6e6a64e6d23272efd884f5d0ab195f41e05ae622121853f`.
Report115 holds the completed signing/identity verification: internal-only,
iOS15.0, main Team/bundle, get-task-allow=false, no non-exempt encryption,
eight package pins and 478 source pins unchanged. Those checks were not replayed.

## 3. Upload result and Apple post-verification

The executed one-use uploader's metadata records:

- Started: 2026-09-13T05:27:42.200617Z.
- Completed: 2026-09-13T05:30:27.267263Z.
- Exit code: 0; `UPLOAD_COMMAND_SUCCEEDED_VERIFY_APPLE`.
- Returned status: PROCESSING; exact IPA hash matches §2.
- Returned UUIDs: `67ea7f35-6a3d-633a-d823-82b6855f5804` and
  `f3da4df4-9113-48d0-9ac7-0ae96e437156`. The second is proven to be the
  build UUID by Apple's visible link/row; no meaning is guessed for the first.

Codex refreshed the main app's TestFlight page in the existing Chrome company
session. Fresh Apple UI showed build 3 upload **Complete**, then build 3
**Internal / Ready to Test**, not merely an uploader success claim.

Before assignment, the existing group showed 1 Tester / 1 Build; its sole
tester was admin@zyraconnect.app, build2 already installed. Settings showed
**Manual for Xcode Builds**. Codex opened Add Build, selected only version1.0.0
build3 Internal, and clicked Add once. At approximately 05:34 UTC, the returned
group showed **1 Tester / 2 Builds**:

| Build | Status | Scope |
|---|---|---|
| 1.0.0 (3) | Testing | Internal |
| 1.0.0 (2) | Testing | Internal, retained |

No tester or distribution settings were edited. No new group, external tester,
public link, App Store submission, expiration or removal was performed.

Verified group page:
https://appstoreconnect.apple.com/teams/6d66bbe2-8ad1-479b-8938-8e3722d8d38e/apps/6810741513/testflight/groups/37600523-1fe0-4911-aeef-10502dc8a35b/builds

The historical account-null warning during Xcode export remains preserved in
115. This successful named altool upload does not claim that separate Xcode
warning's root cause was repaired.

## 4. Safe evidence files and one-use state

Evidence root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-main-build3-delivery.HvNXDL/`

| File | SHA-256 |
|---|---|
| upload-session-started.json | e216da5b9f3f2fd38c19c451beb00c4bbffc8e7b94fbd7a7ec4d97785ac49000 |
| upload-started.json | dbfd56fc9287dd7e9ba0b6028e5254bbedd3e0e7c34cdf20938555cef88d2667 |
| upload-result.json | 35b15b3f1b96f2c6a8d57445f9710c3f74cdf4513f74db984cacab76976b2434 |
| apple-post-verification.json | d711261aef5b1a32e4c89e5f01ebc7cae2124cee12c08af2c8d222d5e0aec22f |

The final JSON is a transcript-backed Codex summary of fresh accessibility
observations, explicitly not a raw Apple API export. No credential value,
clipboard content or secret-field screenshot was captured. The app-specific
password was manually entered through the tested hidden-stdin flow; no new
persistent credential was stored. No claim is made that the Founder has since
revoked the password. Session/upload tombstones are consumed and preserved.

## 5. Current records and true pre-state ledger

Root was the sole writer for AGENTS, CLAUDE, runbook, handover and this report.
The operations subagent was the sole writer of OA286 in the register. The
index subagent owns only the generated index refresh, never Apple actions.

True pre-edit byte copies for the first four rows were taken immediately
before this edit and are preserved under:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-build3-delivered-prestate.QtdPDL/`

Paths below are relative to
`/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/`.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| AGENTS.md | 20e4c59676803b7a9302f6fbd72daa3bcea3a75f89fc717a63ecf0b58aee8c09 | 035eb710182c2e1e4fb17678e40e9fc737aec2cc7d4e529545537e0a0b1f7167 |
| CLAUDE.md | 1af2674e48bb3a90ca4011aa4f801f3192719ca749c606b3d3c0d95bcf30562c | b7780e50fd4a5347c699f774ab4f3b37d0eb1d815e3af82eebef71401fc4fc66 |
| SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md | 3d865d4963ae8528138e9d1eae5b44e7b2c8772b1bc7a51c61be8172fca12ab5 | c6a884ecfbd06afde027c29d12d78cae37f732a3848fba1a1c80720b7fefe55f |
| SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md | 82809cb3d00f6ae64c3788e75c239d4d9b72e87039160af57d5fa5d9a3639c76 | 2a0a2f4fdf0ad0373ce044fd878b8d2296cd04c9e522a2bfe89b31f13fbde144 |
| SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md | fe17647b6dd4578e7936414a680266813d48ca0e99353c19fd3caf824653c60a | 334be6808a89005820df9f253776c2791c6d5dd0d4ede07dde0cd7974046e7d7 |

Register true preimage:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-build3-upload-final-prestate.apsk5a/OUTSTANDING_ACTIONS_V2.md`.
Pre969,095 bytes/19,411 lines; post971,980 bytes/19,457 lines. Exactly two hunks,
both in OA286. The271 existing OA headings, TOTAL286 and NEXT OA-ZYRA-287 are
unchanged. OA286 remains OPEN. Historical failed stops/approvals are preserved.

The generated documentation index refresh follows filing this report; its
separate true pre/post receipt is retained in the report116 index evidence.
This report is a new file, not a reconstructed pre-existing document.

## 6. Validation and remaining boundary

Fresh checks in this round: unchanged IPA/helper hashes; safe uploader exit0
metadata; actual Apple processing complete; correct build identity; sole tester;
manual group setting; exact single-build selection; final Testing association;
four current-document diffs reviewed against true preimages; OA-only diff and
register counters internally checked. No source edit or fresh app test run.

Earlier report112 remains the latest source-retirement suite: 89/89 focused
runtime/security,29/29 native/tooling,1/1 compiled retired-flavor denial, analyzer
clean. Full910 PASS/60 known visual failures; all60 actual PNGs byte-identical
to pre-change. No full-suite PASS, visual waiver or device acceptance claimed.
The uploader's final12/12 offline hidden-entry/cleanup tests are in115.

Only the pinned, refreshed company Google Founder identity should reach the
local developer previews in this internal build. Personal identities keep
ordinary onboarding/IDV and member permissions. Previews are local-only, not
production account impersonation or privileged data mutation. Public/default
builds remain locked. Actual phone confirmation of both account experiences is
still owed by the Founder; no live database test was inferred or performed here.

OA286 also retains Google's contradictory shared Branding-domain dependency
for the retired Test domain. No cleanup attempt was made in this delivery
round. Existing production security/IDV/moderation/public-launch gates remain.

## 7. Founder-accepted update cadence

The Founder accepted: Terminal for frequent small UI changes; bundled TestFlight
updates for testing away from the Mac. One codebase and one app, not a revived
second Test app. The usual local command remains:

```sh
cd "/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE" && ./run.sh
```

An app-specific password is not required to be newly generated per build;
fresh one-use credentials were this temporary no-storage workflow. Persistent
upload authentication is a future separately gated setup; no API key or stored
password was authorized/created here. Cadence acceptance does not authorize
future uploads or change exact-action safety gates. The current runbook owns
this practice and links Apple's primary guidance.

**Outcome:** requested build-3 delivery is post-verified and available privately.
Founder now updates on the iPhone and confirms the developer/personal paths.
Only the Founder accepts; no self-approval or independent-review claim.
