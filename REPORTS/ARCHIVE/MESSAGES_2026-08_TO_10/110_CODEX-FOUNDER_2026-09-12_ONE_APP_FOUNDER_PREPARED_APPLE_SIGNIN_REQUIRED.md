# 110 — CODEX → FOUNDER: one-app internal Founder preview prepared

Date: 2026-09-12
Owner/action: OA-ZYRA-286
Authority: latest direct Founder instruction in the active Codex task; AD-AIOS-109.
Status: CODEX PREPARED; scoped checks internally verified. Full suite remains
950 PASS / 60 pre-existing visual FAIL. NOT signed, uploaded, installed or
Founder accepted. No approval or closure is claimed.

## 1. Outcome and current delivery boundary

The current ZYRA app source now admits the existing exact, authenticated
company Founder to local developer previews in an explicitly opted-in internal
build. A personal account follows ordinary member onboarding and backend
permissions. Email text alone never grants authority.

The immutable installed 1.0.0 (2) does not acquire this code remotely. A new
internal-only build is required. The separate ZYRA Test Apple channel, V5 VM
packet and staging delivery are HELD under the latest one-app direction.
Nothing in the earlier Test-only bounded GO transfers to a production mutation
or a different upload artifact.

Exact approved existing identity:
- Main bundle: `app.zyraconnect.zyra`; display name: ZYRA.
- Apple app ID: `6810741513`; Team: `9Y7Z8F36SJ`.
- Provider: `6d66bbe2-8ad1-479b-8938-8e3722d8d38e`.
- Backend: `sxoaxonzjqkgajmlagyk`.
- Existing Founder UUID: `dfcbd00d-bc22-4d6e-999b-3a9264cf3510`.
- Account: `admin@zyraconnect.app`, confirmed Google identity with existing
  protected `app_metadata.zyra_role=founder`, verified read-only. No profile.
  No role, account, provider or database change was needed or performed.

The Founder-request source and earlier helper disposition are preserved in
the task workspace at `evidence/oa286-one-app-founder-direction-20260912.md`.

## 2. What changed

Admission requires all of: production flavour; default-OFF explicit
`ZYRA_INTERNAL_FOUNDER_ACCESS=true`; exact compiled
`ZYRA_INTERNAL_FOUNDER_UUID`; exact main endpoint; the authenticated UUID;
and a freshly refreshed protected Founder role. Default/public builds remain
closed. Refresh failure, revoked claim, principal change and late refresh
completion deny access. Auth update/resume paths re-prove authority.

Developer Access provides four enabled, labelled LOCAL previews:
Seeker/Guardian × male/female, bypassing signup into the existing role shells.
The existing local signup labs and scenario controls remain. These are
sample UI states, NOT real signed-in test personas. No shared credentials,
production persona login or account impersonation was restored.

The main preview scenario panel latches its local-only context. Server-backed
Journey, membership, credits and Guardian writes are guarded/omitted. Main
preview never calls the Test persona broker. A custom SDK HTTP client denies
all data requests for the Founder/preview latch, including reads, to avoid
mixing live people with samples. It forwards ordinary personal sessions to the
unchanged server authorization/RLS. JWT payload inspection in this client is
DENIAL-only, never identity proof; unknown data tokens and wrong hosts deny.
Only required refresh/logout/user-check Auth endpoints remain available while
protected. The installed SDK's separate Realtime path is blocked at the sole
Chat channel entry. No server authorization was weakened.

A persistent LOCAL PREVIEW · NO LIVE DATA warning follows the deny latch even
after authorization loss or failed sign-out. Preview identity values do not
overwrite the cached real identity. Successful sign-out clears preview
AppState/scenarios before releasing the latch; failed exit stays denied.
Personal signup is not bypassed and personal access receives no developer role.

`http 1.6.0` was already locked/transitively installed and is now an explicit
direct dependency. Offline dependency resolution changed no package version.

## 3. Local build and verification

Final commands ran against SOURCE with no cloud execution:
- Explicit-internal focused selection: **83/83 PASS**. Covers exact identity
  admission/denial, refresh races, route gates, local scenario controls,
  request isolation, persistent warning and actual role-shell navigation.
- Dedicated preview landing/shell tests: **10/10 PASS**.
- Full analyzer: **no issues**.
- Full default test suite: **950 PASS / 60 FAIL**, all failures visual golden
  comparisons. No other final failure.
- A separate scratch pre-change visual run: **275 PASS / 60 FAIL**; same failure
  names and byte-identical actual PNGs for all 60 current failures. This proves
  they predate this pivot, not that approved baselines may be overwritten.
  Approved pixels were neither regenerated nor edited. They remain an open
  baseline discrepancy under OA-ZYRA-286 pending disposition.
- `sh -n tool/build_internal_founder_ipa.sh`: PASS.
- Final unsigned iPhone RELEASE compile: PASS (25.3 MB, Xcode 53.8 seconds),
  production flavour and both explicit internal flags, local candidate
  `1.0.0 (3)`, bundle `app.zyraconnect.zyra`, display ZYRA, minimum iOS 15.0.
  Candidate build number 3 is NOT yet checked/reserved on Apple.

Unsigned output is SOURCE/build/ios/iphoneos/Runner.app. App.framework/App
SHA-256: `c989bcdf53c056c799089eb23e2142711ceac9d66d04395948d0d736ffb35159`.
Output Info.plist SHA-256:
`3b18b7c51a25ca1f68a8be520c36bd613f6b9629ad1b1841ad44b3bedc79c8d0`.
These are compile evidence, not a signed upload artifact.

The prepared local export script requires the unchanged
`ios/TestFlightInternalExportOptions.plist` internal-only flag, export
destination, exact Team and disabled version management. It was syntax-checked,
NOT executed. Plist SHA-256:
`665805d3130b65c6b5344ff360d15501aa85b27ad4827d3f53ad3ce2bc003cc9`.
No signed replacement IPA exists.

## 4. Evidence and pre-state honesty

Workspace:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3`.

Complete exact-path pre/post ledger:
`evidence/oa286-one-app-22-file-hash-ledger.json`, SHA-256
`fc87c6b79cf71a6900ce20a95252d11ba8b5e16932afa98f0bd9c51dcbe480e0`.

It covers 20 source/test/tool/dependency files and two current handovers:
14 true pre-edit file snapshots, six originally absent files, and two explicitly
disclosed pre-state deviations. True snapshots are byte copies under
`evidence/oa286-one-app-prestate.EqjN1G/`.

Deviation: the delegated `lib/dev/dev_scenario_panel_v2.dart` and
`test/dev_scenario_panel_policy_test.dart` had exact pre-hashes recorded but
not true pre-file copies. Later scratch reconstructions match those hashes
exactly (`96f81052…cc97` and `b32e3fa3…0a04`). They are reconstructions,
NOT true captured prestates or retrospective audit anchors. Scratch path:
`/private/tmp/zyra-one-app-prechange-visual.oqI5yq/SOURCE/`.
This process defect is disclosed rather than silently relabelled.

Earlier local test defects are preserved in logs: a static source allowlist
needed the two new isolated files; the legacy landing test needed explicit
non-main-preview mode; two shell-test attempts hung in SDK cleanup because
initialization/disposal occurred inside widget fake-async. Only those owned
test processes were interrupted. SDK setup/teardown was moved outside that
zone, auto-refresh disabled for mocks, and both real shell-entry tests pass.
No network workflow was retried in correcting local tests.

Final log hashes:
- enabled-verified:
  `0861f0122590bbbbd2cfb43b37b6991e6c02928708b722d0211388e33a2b85b9`
- analyzer-verified:
  `ce8c2544ef25323964249de74dbd2cea46514a830b1d1db5bd8dd9dce640a65f`
- full-suite-verified:
  `5205c66c321f8597125af62308181b3ead5ff08e270fb7f3966ad4d97fe73021`
- unsigned-build-verified:
  `66c49e10e22da78c5d14144f9cf0b79adecc61b268ebcb5fc679f509c55f427f`
- shell-entry-tests-verified:
  `826f1580a2bc7399cb48d860480fe48546b4c41bafb6a16d4b210efae84dd63c`
- prechange-full-visual-tests:
  `44286f8366b8aaa2facefc54fd064c4acb805febce5879da790a098216e2e556`

Each log is `evidence/oa286-one-app-<name>.log`.
Common normalized 60-image manifest SHA:
`b66b7a12f15bac1e77d748f2f256f1209101ddef563abd70144e7e90240f12e6`.
Durable final-log comparison: `evidence/oa286-one-app-prechange-vs-final-visual-actuals-v1.tsv`,
SHA-256 `f167ab4f371ec43cb30a131996caffdecabbb9fd4c68df65cf785ca87501f1da`.
It records 60/60 identical failure names and corresponding actual PNG hashes
against the final 950/60 run, with no new Flutter execution.

## 5. Unchanged external state and next delivery gate

No production/staging mutation, migration, VM/replay run, Edge deployment,
Apple registration, certificate change, signing, upload, tester change or public
release occurred for this pivot. No git or PRIVATE-tree access. Old build 2 IPA
was rehashed unchanged:
`1e17a1c3475db1bcb01e59415768d94480538bb601aedcdc8fdd706ea1a7b673`.

App Store Connect in Chrome currently shows an expired login. The relevant app
page was opened and left for Founder sign-in with `admin@zyraconnect.app`.
Passwords and security-key prompts remain the Founder's actions. There is no
valid fresh Apple account/build-number proof to replace by assumption.

After sign-in: verify the exact account/app/team and unused build number,
prepare/inspect a signed internal-only export, obtain any required exact
artifact-bound upload GO, upload once, verify processing and assign only the
Founder Internal group (automatic distribution OFF, only admin), then verify
Founder installation. Do not claim delivery until those steps actually pass.
The 60 proven pre-existing visual discrepancies need an explicit documented
disposition, not self-approval or automatic baseline promotion.

Current handovers were reconciled. The large master OA register was not edited
because it was not completely loaded for writing; this report is the durable
OA-ZYRA-286 evidence and leaves register reconciliation outstanding. No new OA
identifier or closure was invented. The old Test callback cleanup and manual
Google client-secret rotation remain open, not prerequisites silently executed
during this delivery.

## 6. Founder summary

One-app source fix prepared and locally tested. Company Founder gets local
developer previews; personal login remains a normal user. Not yet on
TestFlight. Immediate required action: company Apple sign-in in the prepared
Chrome tab; no secrets should be sent to Codex.
