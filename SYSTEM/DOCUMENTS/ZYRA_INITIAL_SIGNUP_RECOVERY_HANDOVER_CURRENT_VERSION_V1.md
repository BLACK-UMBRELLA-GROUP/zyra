---
id: DOC-ZYRA-0207
type: HANDOVER
status: CURRENT
feature: IDENTITY AND SIGN-IN
purpose: ZYRA — Initial Signup Recovery and IDV Truth — As-built Handover
links: []
owner: ZYRA chat
---

# ZYRA — Initial Signup Recovery and IDV Truth — As-built Handover

**Version:** V1
**Status:** CURRENT_VERSION — Guardian first-photo client checked, installed and native-launched; physical acceptance pending; prior account-switch delivery retained; provider capture unavailable
**Date:** 2026-10-12
**Owner:** Codex under AD-AIOS-111; Founder is sole approval authority
**Governing Reference:** Founder personal-account device report 2026-09-13; DR-ZYRA-219/220/221; OA-ZYRA-266 and OA-ZYRA-286; IMPLEMENTATION_HANDOVER_STANDARD

## 1. Scope and authority

The Founder reported that personal signup never opened a document/selfie check,
yet said verification was in progress, that closing/reopening restarted initial
signup, and later that choosing the wrong personal account left no clear route
back to sign in. This handover covers the bounded client correction, its
same-device recovery mechanism and the first-time-setup account escape. It is
not approval to activate a provider, change server permissions, buy a service,
publish privacy terms or upload a build.

Founder ↔ Codex is the current route under AD-AIOS-109. Historical mailbox 027
is the technical IDV design, refined by 029 and DR-220/221. Its old solicitor
and undecided-capability-matrix gates are superseded: the matrix is ruled and
compliance is in-house. Provider contract/privacy acceptance and the real
server-enforcement audit still apply. The one-app override under OA-286 is
unchanged; the cancelled separate Test application is not restored.

The August onboarding persistence audit remains historical evidence. This
handover owns the new short pre-profile draft, not the existing long-form,
post-profile answers/progress system.

## 2. Measured causes

- Production uses `ZyraUnavailableIdentityVerificationProvider`; no document or
  selfie capture is connected. Consent alone creates a coarse `pending` row.
  That is not evidence that capture started or a provider is processing it.
- The initial Seeker/Guardian answers and profile-creation callback previously
  lived only in widget memory. A missing `profiles` row routed cold starts to
  role selection. The existing-account IDV rollout fuse is intentionally off,
  so it did not restore a pre-profile verification checkpoint.
- Read-only main-project checks on 2026-09-13 returned zero Edge Functions and
  the eight Phase-A IDV routines. A scoped name/text-reference check found no
  downstream policy/routine references to the IDV predicates. That check is
  not a complete semantic security audit or evidence about provider-account
  ownership; mailbox 030 §6 remains a production activation blocker.

## 3. Client truth correction

Missing-provider pending is explicitly unavailable, including on remount.
Configured-provider pending uses neutral start/resume/check-result wording:
the coarse RPC has no capture-start flag. Launch cancellation, returned failure,
unavailability and exceptions never grant access. Retry launches the adapter;
result refresh is separate. Canonical terminal/review states retain their
meaning. Only a verified identity can receive the duplicate-only review copy.

Verification admission remains server-result based. Local drafts, launch
callbacks, email text and preview state are never verification authority.
Sensitive errors are not copied into logs or user messages. Finalization,
navigation and signout failures must release the busy state and stay truthful.

## 4. Protected same-device draft

The draft stores only the initial role, completed-step checkpoint, introductory
screen flag, entered first name, gender, date of birth and Guardian relationship.
It stores no verification grant, consent truth, document/selfie, face data,
provider payload, password or token. Key names hash the backend endpoint and
authenticated user ID. This is isolation, not anonymisation.

Completed-step saves are serialized, read back, and account-checked before
navigation. A failed save is visible and does not advance the form. Partial
typing on the current unanswered question is not promised to survive a kill.
Draft parsing validates version, field types, role/step consistency, bounded
name/size and adult calendar date. Corrupt/unknown data is an error, not empty.

Native persistence is pinned `flutter_secure_storage` 11.1.1:

- iOS/macOS: app-default Keychain group, unlocked-this-device accessibility,
  synchronization disabled. No shared app group or iCloud draft storage.
- Android: isolated `zyra_signup_draft` namespace, RSA-OAEP/AES-GCM package
  defaults, destructive reset-on-error disabled. Data, wrapped-key and config
  preference files are excluded from cloud and device-transfer backups.
- Web/Linux/Windows: no sensitive draft persistence or plaintext fallback.
  New signup must explain the unsupported protected-storage path; existing
  member routing is not converted into a new signup-storage requirement there.

Readback detects a missing/silent write; it is not a hardware flush proof.
Android's underlying package uses asynchronous preference persistence, so
abrupt-kill/power-loss durability requires native-device acceptance. Apple
Keychain operations return an OS result. No physical-device result is inferred
from mocked storage tests.

## 5. Lifecycle, navigation and account boundaries

Role selection establishes a draft; each completed short question updates it.
The verification checkpoint is saved before the IDV page opens. On cold start,
protected Founder authorization is resolved first, preserving the local-only
developer boundary. Ordinary same-device recovery loads only the current
account's draft and asks the server for that account's current IDV result.
This path is independent of the dormant existing-member rollout fuse.

A retained verification draft also owns recovery after a partially-created
profile, so a failed Guardian publication cannot silently become completion
on restart. No-draft members retain ordinary role routing. A real recovery
read failure cannot become an empty state or cached-shell success. An enabled
existing-member IDV gate cannot be bypassed by a failed profile lookup.

After a server-verified result, finalization reconstructs the profile operation
from the draft, confirms the expected account/role and successful Guardian
publication, clears that exact draft, then hydrates app state and navigates.
Expected-account IDV/profile/confirmation calls bind their request to the
captured session token in memory; the global HTTP client and Founder preview
denial boundary are retained. No token is persisted or logged. Account changes
and expired/unverifiable sessions fail closed.

Explicit signout clears the current account's draft and prevents a late queued
save from resurrecting it. Force-closing the app does not clear the draft.
Protected developer previews do not read or write real signup drafts.

First-time setup now presents **Use a different account** on role selection,
both roles' initial overview/question pages and every identity-verification
state. It asks for confirmation, clears only that authenticated account's
protected unfinished setup on the current device, signs out the local Supabase
session and returns to Welcome. It does not delete the account or server data.
The action captures the expected user ID and rechecks it immediately before
cleanup and logout, so a route opened for account A cannot sign out replacement
principal B.

When Google is linked, ZYRA also clears google_sign_in's app-local remembered
account so the next Google attempt can choose another identity. This uses
Google `signOut()`, never `disconnect()`: it does not revoke the member's Google
grant. Failure of this best-effort chooser reset cannot block ZYRA's own local
session and draft cleanup. Cancelling the confirmation changes nothing and
preserves the session and draft. Completed members retain the conventional **Sign
out** action in Account/Profile; **Use a different account** is the clearer
first-time-setup label and is not shown in developer previews, duplicate-account
resolution, migration-gated previews or later progressive onboarding.

For older builds with a saved server IDV attempt but no draft, the result/check
page is restored. Once verified, the app honestly asks for the lost basic
details once more. It cannot recover answers that were never saved.

## 6. Live component map

All source paths below are relative to
`/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/`.

| Component | Responsibility |
|---|---|
| `lib/models/zyra_initial_signup_draft.dart` | Strict minimal draft model/checkpoint validation |
| `lib/services/zyra_initial_signup_draft_service.dart` | Native store, scoped serialized repository, guarded finalization |
| `lib/screens/auth/role_selection_screen.dart` | Save initial role, honest legacy recovery notice and principal-bound account escape |
| `lib/widgets/onboarding_scaffold.dart` | Shared initial-question layout and guarded account-escape placement |
| `lib/screens/onboarding/onboarding_stage_intro_screen.dart` | Seeker welcome/stage introductions with the initial-setup escape slot |
| `lib/screens/onboarding/account_path_overview_screen.dart` | Guardian initial overview and guarded account-escape placement |
| `lib/screens/onboarding/onboarding_flow.dart` | Seeker step saves, resume, verified completion and initial-stage escape routing |
| `lib/screens/wali/wali_onboarding_flow.dart` | Guardian step saves, resume, verified completion and initial-stage escape routing |
| `lib/services/zyra_session_router.dart` | Cold-start recovery and unchanged member/Founder boundaries |
| `lib/services/zyra_auth.dart` | Principal-bound local signout, draft/account cleanup and app-local Google chooser reset |
| `lib/widgets/zyra_onboarding_account_exit.dart` | Confirmed first-time-setup escape to Welcome without account deletion |
| `lib/services/zyra_profile_service.dart` | Optional expected-principal writes and Guardian publication failure propagation |
| `lib/screens/onboarding/identity_verification_screen.dart` | Truthful unavailable/pending/retry/review, async failure handling and account escape in every IDV state |
| `lib/services/zyra_identity_verification_service.dart` | Provider-readiness presentation and expected-principal result read |
| `pubspec.yaml`, `pubspec.lock` | Pinned native storage dependency; six added packages, no existing upgrades |
| Apple entitlement files and Android backup XML/manifest | Default Keychain capability and device-only backup exclusions |

Generated platform registrants/metadata change mechanically with the dependency.
The numbered completion report carries the exact file/hash/evidence ledger.
No schema or applied migration is changed.

## 7. Mock versus production and verification

Focused tests use synthetic sessions, fake HTTP and injected stores. They do
not perform real identity checks, create live accounts or prove provider
integration. Preview controls remain local and are not accessible by personal
email alone. Build 3 already on TestFlight does not receive these source changes
remotely. A separately authorised build/delivery and Founder device inspection
are still required.

Final verification: 989 passed, one compile-gated skip and the same 60 previously
recorded visual failures in the full suite. All 60 failure names and actual PNG
hashes match the preserved pre-change comparison; no new final-suite failure.
This is not a full-suite PASS. The skipped existing-account-gate case ran in a
separate enabled-fuse process: 21/21 runtime tests passed. Focused IDV tests:
42/42; draft/flow/intro selection: 25/25; native configuration contracts: 4/4.
At the 2026-09-13 evidence cutoff, whole-tree analyzer was clean and unsigned
debug iOS simulator compile passed on the then-final production bytes. No
signed-device build, native-device Keychain roundtrip, live capture, Apple
upload or Founder acceptance was inferred at that cutoff. The dated addendum
below records the later signed-device delivery without rewriting that evidence.

### 7.1 2026-09-17 account-switch and iPhone delivery addendum

The account-switch correction passed 117 focused tests with one compile-gated
skip and zero focused failures. Coverage includes cancel-without-mutation,
exactly one local Supabase logout, Google chooser reset, account-scoped draft
erasure, other-account draft preservation, metadata-only Google-provider
detection, route-principal replacement denial, all intended Seeker/Guardian/
IDV surfaces and suppression from developer/duplicate previews. Whole-tree
analysis is clean.

The full repository suite reached 1,602 passes, one skip and 100 existing
dashboard/developer/visual failures. This is not a full-suite PASS; the bounded
account-switch suite is green and no claim is made that the unrelated backlog
was repaired by this change.

A signed Founder profile build was installed over the existing local bundle and
launched on the Founder's iPhone. The built app measured 35.1 MB. Device
inventory reports one `ZYRA`, bundle
`app.zyraconnect.zyra`, version `1.0.0`, build `2`. The installed binary SHA-256
is `8de690f13c6e6629e149fdc1e15198c6a8b6fad65d6b377650f8be065cfed4d5`.
Replacement cleared the superseded build's local app sandbox/session; it did
not delete either Apple/Supabase account or any server data. No TestFlight/App
Store upload, database change, migration or git action occurred.

Mailbox 117 carries the exact source ledger and evidence links. Approved
visual pixels and their manifest are unchanged. One older intro test needed
the new account-bound store fixture; its original assertions remain, with
additional saved-checkpoint assertions. Intermediate test-harness failures
and the final evidence are both retained.

## 8. Remaining work and next gates

| Owner/action | Status and required next work |
|---|---|
| OA-ZYRA-266 — real IDV | Sumsub remains conditional lead. Confirm company account/sandbox availability; obtain duplicate-inclusive quote and written tenant-limited human-review-only controls, DPA/region/retention/deletion/provider-use facts; finish the in-house privacy/DPIA package for Founder acceptance. No current account existence is assumed. |
| OA-ZYRA-266 — Phase B and activation | Authenticated short-lived SDK token endpoint, Flutter capture, signed/idempotent webhook, coarse duplicate mapping, no sensitive logs, sandbox denial/retry/duplicate tests, server-enforcement audit and separately authorised production activation. SDK completion is never approval. |
| OA-ZYRA-286 — app delivery/acceptance | The current account-switch profile build is installed and launched; Founder interaction acceptance remains. Test force-close/reopen for both roles and the wrong-account escape on the physical device. TestFlight build 3 is a separate older artifact and does not receive this local source update. Same-device only; cross-device or data lost by old builds is not recovered. |
| OA-ZYRA-286 — supported-platform limitations | Native iOS/macOS/Android recovery is implemented; unsupported protected-storage targets and Android abrupt-kill durability remain explicit test/scope limitations. No new standalone platform project is raised. |

No new OA identifier is raised: these defects and remaining checks belong to
the already-open IDV programme and one-app personal/Founder delivery work.
Neither action is closed by this handover. No provider account, key, SDK,
payment, production write, migration, Apple upload or git action was performed.

Primary references checked for implementation:
[native storage](https://pub.dev/packages/flutter_secure_storage),
[Apple device-only option](https://pub.dev/documentation/flutter_secure_storage/latest/flutter_secure_storage/KeychainAccessibility.html),
[Android backup rules](https://developer.android.com/identity/data/autobackup),
[Sumsub Flutter](https://docs.sumsub.com/docs/flutter-plugin),
[Sumsub signed webhooks](https://docs.sumsub.com/docs/webhook-manager),
[Sumsub duplicate check](https://docs.sumsub.com/reference/get-duplicate-applicants-check-result).

## 9. Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-09-13 | Initial as-built record for the Founder-reported IDV presentation and short-signup restart defects. Not provider activation or device acceptance. |
| V1 addendum | 2026-09-17 | Added the principal-bound **Use a different account** lifecycle, Google chooser boundary, focused evidence and signed Founder-profile iPhone delivery. |
| V1 addendum | 2026-10-12 | Guardian requires one first photo before membership; schema 5 and an opaque Guardian finalization marker extend same-device recovery. See §10 for current boundaries and evidence. |

## 10. Guardian first photo and current recovery rules

The Founder's 2026-10-12 direct instruction requires one photo for Guardian
signup. Guardian essentials are now five questions: names, date of birth,
gender, relationship and one photo. Membership and verified identity follow.
Seeker essentials stay at four questions, including one first photo; the later
Seeker profile still needs three photos. The new rule does not add a Guardian
public photo gallery or change another member's access to a photo.

The protected draft is now schema 5 and includes the public surname,
commercial preference and tokenless owner-folder JPEG reference introduced
since the September record. It never stores the photo bytes, signed display URL,
identity result or payment proof. Older valid Guardian membership drafts resume
at the new photo question without losing answers or the selected preference.
Legacy Guardian payloads containing photo references remain invalid. Existing
Seeker schema 4 photos are preserved.

Both roles confirm their first photo after the verified server result and
expected profile/surname readback. Guardian creation is unpublished in this
client until the owned object and photo row are confirmed. On failure, signup
does not navigate as completed or clear its recovery state. A confirmed
owner/backend-bound Guardian marker is written before profile creation. The
strict payload is only `{version:1,pending:true}`; explicit signout retains that
marker while erasing form answers, photo reference and membership preference.
Successful finalization erases the form, then the matching marker.

Ordinary same-device routing checks both markers and unfinished drafts before
opening a member shell. Two markers or a profile/draft/marker role conflict
fail closed. A profile connection failure cannot bypass retained recovery via
the cached role; a failed protected-store read also cannot be treated as empty.
Marker-only recovery re-asks erased essentials rather than reconstructing them
from a provider display name, while own saved photos can be reused. Signing and
photo reads must finish before membership or verification is actionable.

Exact-source verification passes 672 tests across 37 named suites, one existing
compile-fuse skip and zero failures; that held-fuse case separately passes in
an enabled test process without changing the phone rollout setting. Analysis
is clean and the 23-file formatting gate changes zero. Three real-font layout
cases pass with 15 new captures; enlarged text remains scrollable and inherited
header truncation is OA-ZYRA-304, not a native accessibility acceptance.
The signed main PROFILE build passes the existing identity/profile checks;
the initial phone connection check fails, then the same paired device is
reachable but locked at 10:14:39 UTC. That earlier artifact was not installed
or native-launched; unlock was requested under DR-ZYRA-257. The subsequent
combined delivery is recorded below.
Evidence is recorded in
`SYSTEM/RESOURCES/REVIEWS/OA303_GUARDIAN_FIRST_PHOTO_2026_10_12.kIP4UQ/`.
The detailed implementation and current results belong to the onboarding
handover §110; older measurements above remain dated history.

OA-ZYRA-303 retains atomic server and cross-device enforcement: profile creation,
photo attachment and publication are separate operations, and current server
Guardian publication is not changed here. No historic Guardian backfill or
global photo admission gate is introduced. OA-ZYRA-302 retains real stored-object
and Android acceptance; OA-ZYRA-304/286 retain physical recovery/accessibility
acceptance; OA-ZYRA-253 retains commerce and receipt authority. No provider,
migration, SQL, RLS, bucket, release fuse or live member mutation is part of
this client change. Founder acceptance remains separate from internal checks.

### Combined phone delivery completed

The Guardian first-photo change is now installed with the later Journey icon
sizing update, without additional Guardian product edits. Its final frozen
tree has 4,953 paths; the icon packet's PRE retains the 4,952-path Guardian
baseline and its five documented Dart deltas. Final targeted regression passes
408/408 across fourteen suites, including the first-photo flow/commit guards.
The preceding 672-test recovery run remains dated evidence.

The same-main PROFILE build and repeated strict signature/identity/profile
checks pass. PREINSTALL_2 and DELIVERED retain artifact SHA-256
`868a18ae6eb1368ff9db23086a41d620b2673dcec3e3427d8db1998f93562836`.
Fresh same-device unlock is confirmed. INSTALL at 11:20:02 UTC and immediate
LAUNCH at 11:20:03 UTC succeed; POST at 11:20:04 UTC confirms main bundle
1.0.0(5), PID1447 and container `0D4B9B4A-B623-4920-802C-982390DC7F18`.
Evidence: `SYSTEM/RESOURCES/REVIEWS/OA151_JOURNEY_ICON_SIZE_2026_10_12.x5mkLX/`;
the onboarding handover §110 records the current complete delivery. App data
is preserved. Physical Founder acceptance and the existing server, storage,
provider and commerce gates remain separate and open.
