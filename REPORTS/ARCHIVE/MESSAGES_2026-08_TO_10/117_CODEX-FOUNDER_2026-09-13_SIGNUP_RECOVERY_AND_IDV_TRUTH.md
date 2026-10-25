# 117 — CODEX → FOUNDER: Signup recovery and truthful IDV state

Date: 2026-09-13 · Existing work: OA-ZYRA-266 / OA-ZYRA-286.
Status: bounded client correction INTERNALLY VERIFIED, NOT DELIVERED.
Real provider capture remains UNAVAILABLE. Founder is the sole approver.

## 1. Request, cause and outcome

The Founder reported two personal-account defects on the delivered app:
consenting never opened real identity capture but showed a check-in-progress
message, and closing/reopening returned initial signup to page one.

Confirmed causes: production still selects the unavailable IDV adapter;
consent's coarse pending row does not mean a provider check started. Short
pre-profile answers were in widget memory; the cold-start router had neither
those answers nor the profile-finalization callback. The dormant existing-
member rollout fuse was not a recovery mechanism for that pre-profile state.

Implemented locally:

- Missing-provider pending is honestly unavailable, including after restart.
  Configured pending has neutral start/resume/check-result wording, not an
  invented processing claim. Launch failures/cancellations/exceptions retain
  a usable retry path and never grant verification.
- Completed initial Seeker and Guardian questions save into an account/backend-
  scoped protected same-device draft before advancing. Reopening restores the
  saved question or verification checkpoint and obtains fresh server state.
- Server-verified completion reconstructs and confirms the correct profile
  operation, preserves recoverability after a partial Guardian operation,
  clears the exact draft, and hydrates the restored account state.
- Old builds' already-lost answers cannot be recovered. An existing server
  attempt returns to verification; once verified, the app honestly requests
  unsaved basic details once more rather than silently restarting or looping.

No actual IDV capture, provider account, provider key, IDV SDK, payment, cloud
write, schema/migration, signing, Apple upload, public release or git operation
was performed. The current TestFlight binary is unchanged by this patch.

## 2. Security and native boundary

The new draft contains role/checkpoint/intro flag, first name, gender, DOB and
Guardian relationship only. No local verification grant, consent authority,
provider payload, document/selfie, biometric, credential or token is stored.
Fields and checkpoint consistency are strictly validated; read failure or
corrupt data is not treated as empty. Saves are serialized and read back.

Pinned dependency: flutter_secure_storage 11.1.1. Six new resolved packages,
zero existing dependency upgrades. Apple uses the app-default Keychain group,
unlocked-this-device accessibility and synchronizable:false. Android uses its
isolated namespace, package RSA-OAEP/AES-GCM defaults, reset-on-error disabled,
and exact data/key/config preference exclusions from both cloud and transfer
backups. Existing native project/signing configuration and minimum deployment
targets are unchanged. The ledger distinguishes unchanged pre-snapshotted
native files from changed registrants/configuration.

Web/Linux/Windows do not receive a plaintext draft fallback. New protected
signup is unavailable there; ordinary member routing remains independent of
that new storage requirement. Android preference readback is not proof of
power-loss durability because the package persists preferences asynchronously.
No cross-device, reinstall or partial-current-keystroke recovery is promised.

Expected-principal profile/confirmation/IDV calls explicitly pin the captured
session Authorization on the existing immutable request builder. This avoids
the installed SDK's async token lookup changing authority to a newly signed-in
account, and preserves the shared Founder-preview HTTP denial wrapper. Tokens
stay in memory only. Actor/expiry checks bracket relevant awaits. A→B and
A→B→A cases are tested. The ordinary IDV screen cannot navigate/sign out over
a replacement account. Consent/result/delete calls are all covered.

Explicit logout serializes and verifies draft deletion and blocks late queued
saves; failed erasure remains visible/retryable. Force-close preserves progress.
Confirmed attempt deletion followed by failed logout is described accurately;
ambiguous deletion replies say deletion could not be confirmed, never that
nothing changed. Busy states always recover. Developer previews do not access
real drafts; local data never grants admission. The existing-member enforcement
fuse stays OFF in production and the protected Founder boundary is unchanged.

## 3. Internal review and measured verification

Read-only internal reviewer found and builders corrected: restored-field
hydration, Guardian second-write actor race, immutable-header binding TOCTOU,
false publication success, partial-profile restart bypass, enabled-IDV gate
cached-role fallback, and exit/erasure failure handling. Final source review
reported no outstanding blocking code finding. This is not external review,
Founder acceptance or proof that real identity verification is deployed.

Commands were local from SOURCE, with fake HTTP/stores and synthetic accounts:

| Check | Final result |
|---|---|
| `flutter test --no-pub --reporter expanded` | 989 PASS / 1 compile-gated SKIP / 60 previously recorded visual failures; exit 1, 65s |
| `flutter test --no-pub --dart-define=ZYRA_IDV_ENFORCE_EXISTING_ACCOUNTS=true test/zyra_signup_runtime_test.dart` | 21/21 PASS; includes the separately enabled skipped case, 7s |
| IDV screen/service + state/admission focused selection | 42/42 PASS |
| Draft/repository + flow + existing intro selection | 25/25 PASS |
| Native storage configuration contract test | 4/4 PASS |
| `flutter analyze --no-pub` | No issues, 5.4s |
| `flutter build ios --simulator --debug --no-codesign --no-pub` | PASS; final Xcode build 29.1s |

All 60 visual failure names and actual PNG hashes match the preserved pre-change
comparison from reports 110/112. No approved PNG or manifest was regenerated.
Approved manifest remains
`4667f42228d76dcb0893c247ea5c95c2f9556f485fc3fb8af3ece76974b5e03e`.
Full-suite PASS is not claimed. No new final-suite failure remains.

The first full run had 988 PASS / 1 SKIP / 61 failures: the known 60 plus the
existing intro test lacking a signed-in principal/protected-store fixture.
That test-only adaptation preserved all original scroll/layout/text assertions
and added three checkpoint assertions; the final full run above then passed
that case. Earlier focused harness failures (fake-async, platform cleanup,
Postgrest mock response envelopes) and lint corrections are preserved in the
writers' evidence. No test assertion was removed or cloud retry performed.

The native result is an unsigned simulator compile, not physical Keychain
execution, a signed iPhone release or device acceptance. Before delivery is
called accepted, test both roles' saved-step/verification restart, old no-draft
attempts, explicit logout cleanup, personal-account isolation and unavailable
provider truth on the actual device. Real provider success/cancel/duplicate
flows require Phase B, not this mock-based proof.

## 4. True pre-state and complete hash ledger

Workspace evidence root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/`

`signup-recovery-native.oM8q7g/complete-source-ledger.json` is the complete
43-row ledger: 33 changed/new paths (25 modified, eight new), ten explicitly
unchanged native pre-snapshot paths. The changed count includes three generated
package-cache metadata files; they are not hand-authored app changes.
Every row names its exact SOURCE path and full pre/post hash. New files are
marked null pre-state. Generated build outputs are not source/audit anchors.

Ledger SHA-256:
`b5335abdb5d980a0ec3825adf70ddd78459de097abef7702d8f389768525f58f`.

True original preimages, taken before editing rather than reconstructed:

- `signup-resume-prestate.rioS9u/`: six original production files and the later
  intro test preimage; HANDOVER.md and INTRO_TEST_ADDENDUM.md give ownership,
  exact original/final hashes and test details.
- `oa266-idv-truth-prestate.h4qgWH/`: original IDV screen/service/test bytes.
  `oa266-idv-session-extension-prestate.fcvEqh/` and
  `oa266-idv-screen-principal-prestate.jopg20/` preserve true intermediate
  states. FINAL_DELETE_COPY_ADDENDUM.md supersedes the latter README's earlier
  final screen/test hashes and closes its flagged copy caveat.
- `signup-recovery-native.oM8q7g/native-prestate.tar`: 25 native/dependency/
  registrant/cache preimages, SHA-256
  `3d2c41cfe06124c03ab3d1fa4032e5e6814a0a1a543647b513095fb095e1e1ad`.
  Generated iOS build settings were additionally copied before building under
  `pre-build-generated/`; no config values are reproduced in this report.

Critical final source hashes:

| SOURCE path | SHA-256 |
|---|---|
| lib/screens/onboarding/identity_verification_screen.dart | b90950ef4cce6a036914f22a97c12f11ece6bc025484cd4761f6542cb0005db0 |
| lib/services/zyra_identity_verification_service.dart | f8f0b82f74c0deb52a89a437bbb67b1510208dd21dc5323c8e70ff0f32f79ccd |
| lib/services/zyra_session_router.dart | e73cb0b901c746f7600d9e266d893a5b1b46c41a90be90aad90cf58767aa2d23 |
| lib/services/zyra_initial_signup_draft_service.dart | f39dcf1bbeab94033001dfd0175187a1aef0935cc53c717625f9b9e6cb6a35c9 |
| lib/models/zyra_initial_signup_draft.dart | ff3e829acfb5681707635fb05555c13a42860133a901f542a558193a845ffe3b |

Root evidence in `signup-recovery-native.oM8q7g/`:

| File | SHA-256 |
|---|---|
| full-suite-final.log | 80509fb778b84fe81288db0b9ff4afb6693c961c597a5158515ea55cd76f27da |
| visual-actual-comparison.json | 5e6eedbca51307ebb6d10b0cce87136c47dc7ab4f921edff7985524428ddd114 |
| runtime-enabled-fuse.log | 6b51e6fd689d8bbff909014e92bbbca93e3d1dcc78631ef8a85d55ec97dc4d89 |
| ios-simulator-build-final.log | fe28107add3b6d32593bd3c358c3b3913bb917d8fb80e933f5ff056375e83d47 |

## 5. As-built records and existing OA ownership

New current handover:
`SYSTEM/DOCUMENTS/ZYRA_INITIAL_SIGNUP_RECOVERY_HANDOVER_CURRENT_VERSION_V1.md`
SHA-256 `90e767d558ebb80b5700bd2583e4fdba244b21096f7e87efaa809bd24a47e048`.
Its pre-state was ABSENT. This report's pre-state was also ABSENT.

The documentation index is regenerated using its existing tool with a guarded
walk excluding PRIVATE, symlink and other mounted trees. True pre-index was
copied at edit time, SHA-256
`9ba68fb1fb748cba1c6a2a207ebfad6917d727c01a7d525a7ab7f1ecf2e80379`.
Final record/index hashes and generator receipt live beside this report's
evidence, avoiding self-referential report hashes.

No new OA identifier or closure is invented. OA-266 owns real IDV and the
production activation/security work; OA-286 owns the one-app personal/Founder
delivery and device acceptance. This bounded handover/report records the new
defects and disposition under those existing owners. The large master OA and
decision registers were not silently rewritten without a full-target read;
their bounded reconciliation remains owed. No earlier approval is widened.

## 6. Real identity checks — remaining work and gates

Read-only current-project inspection returned no deployed Edge Functions and
the eight Phase-A IDV routines. A scoped IDV-name/reference check found no
downstream policy/routine enforcement references; this is not a complete
semantic authorization audit. Mailbox 030 §6 remains a real activation blocker.
Provider-account existence is unconfirmed; the Founder has been asked whether
a Sumsub business account already exists, with no request for chat credentials.

Sumsub remains the conditional launch lead from the prior evaluation, not a
new claim that price/duplicate controls/privacy terms are settled. Before
activation: confirm business account/sandbox availability, duplicate-inclusive
cost and tenant-limited human-review controls, DPA/region/retention/deletion/
subprocessor/provider-use facts, and finish in-house DPIA/privacy acceptance.
DR-220 removed the old solicitor gate and DR-221 ruled the capability matrix;
neither is reintroduced as an unanswered gate.

Phase B still requires authenticated short-lived SDK sessions, real Flutter
capture, signed raw-body/idempotent webhook processing, opaque result/reference
storage, safe duplicate-review mapping, explicit no-sensitive-log behavior,
sandbox cases and the server-enforcement audit. SDK completion is never approval.
No timestamp heuristic or client-local flag substitutes for a server decision.
Any required production migration/activation and new Apple delivery need their
applicable exact authority; this report is not an apply/upload instruction.

Current primary references checked:
[Sumsub Flutter capture](https://docs.sumsub.com/docs/flutter-plugin),
[access tokens](https://docs.sumsub.com/reference/generate-access-token),
[webhook signatures](https://docs.sumsub.com/docs/webhook-manager),
[duplicate-check semantics](https://docs.sumsub.com/reference/get-duplicate-applicants-check-result),
[protected native storage](https://pub.dev/packages/flutter_secure_storage),
[Android backup exclusions](https://developer.android.com/identity/data/autobackup).

Founder-facing outcome: local restart and misleading-status corrections are
ready for delivery preparation; real identity verification is not yet live.
