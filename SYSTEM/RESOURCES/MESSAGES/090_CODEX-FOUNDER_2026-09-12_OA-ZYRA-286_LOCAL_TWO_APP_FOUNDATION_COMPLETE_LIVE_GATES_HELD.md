# CODEX → FOUNDER — OA-ZYRA-286 LOCAL TWO-APP FOUNDATION COMPLETE; LIVE GATES HELD

**Date:** 2026-09-12  
**Status:** LOCAL FOUNDATION COMPLETE / LIVE GATES HELD / FOUNDER RULINGS AND ALL EXTERNAL ACTIONS PENDING  
**Authority:** DR-ZYRA-228; OA-ZYRA-286; Founder's direct approval in Codex chat, 2026-09-12  
**Owner:** Codex (local implementation and evidence) · Founder (rulings, live resources, distribution and acceptance)

## 1. Outcome

The local two-app foundation is complete and independently re-audited with no
remaining local blocker:

- one shared Flutter product source now produces the local Production identity
  `ZYRA` / `app.zyraconnect.zyra` and the local Founder Test identity
  `ZYRA Test` / `app.zyraconnect.zyra.test`;
- ordinary UI, copy, accessibility, product and business-logic changes remain
  shared by default; only identity, configuration, backend, protected tooling
  and unavoidable signing/store metadata may differ;
- a missing or unknown Flutter flavour defaults to Production; an exact
  Founder Test target with incomplete, malformed or mixed resources locks
  locally before any backend connection, never falls back to Production and
  never grants Test capability;
- Production has no reachable or exposed Developer Access path. Protected
  classes remain in the shared compilation unit, so this is deliberately a
  reachability/authority statement, not a claim of byte absence;
- the Test icon, lowercase `foundertest` scheme/flavour, build configuration,
  native identity policy, Founder shell and governed archive path are wired
  locally; and
- the server broker, staging SQL and legacy-RPC hardening are staged and inert,
  not deployed or applied. No live Supabase or Apple mutation occurred.

OA-ZYRA-286 remains open. Its register status is now truthfully
`LOCAL FOUNDATION COMPLETE / LIVE GATES HELD`; `Completed` remains `—`.

## 2. Target and delivery boundary

| Concern | Production | Founder Test |
|---|---|---|
| Display / bundle | `ZYRA` / `app.zyraconnect.zyra` | `ZYRA Test` / `app.zyraconnect.zyra.test` |
| Product source | Shared `lib/main.dart` and shared feature source | Same source; ordinary feature forks prohibited |
| Backend | Existing Production pin only | Exact staging pins required; all are currently unassigned |
| Developer Access | Denied at every entry and guarded leaf | Exact current Founder or exact reviewed synthetic persona only |
| Distribution | Existing Production build 2 unchanged | Founder-only internal TestFlight, not yet created or uploaded |
| Icon | Existing `AppIcon` | Dedicated `ZYRATest` local candidate, not yet Founder/device accepted |

Startup verifies the iOS bundle/display identity before Supabase initialises and
locks on mismatch. The executable configuration gate exact-pins the staging
URL/ref, one approved public client key, Google/native OAuth parity, the Founder
UUID and four persona UUIDs. The five identities must be unique. A public key is
accepted only when it is the exact approved `sb_publishable_*` value or the exact
pinned legacy JWT whose role is `anon` and whose ref is staging; secret,
service-role, wrong-ref and malformed keys are rejected.

All resource and identity pins deliberately remain unassigned. Consequently,
`./run.sh check-founder-test-config` currently fails closed. `./run.sh` retains
its Founder Test Profile default through the ignored public staging config;
`./run.sh release` remains explicitly Production. The sole governed local
internal-Test archive path is `SOURCE/tool/build_founder_test_ipa.sh`; it invokes
the same validator, uses the `foundertest` flavour and internal-only export, and
never uploads. A direct Xcode archive is intentionally unsupported because it
cannot prove the required Flutter defines.

## 3. Founder and persona authority

Founder authorization requires both the independently exact-pinned Founder UUID
and a freshly refreshed protected `app_metadata.zyra_role = founder` claim.
Neither fact alone is sufficient. Authorization refresh is single-flight only
for the same account and claim identity; account or claim changes supersede old
work. `userUpdated` and app resume require a real refresh. Sign-out, claim loss,
non-refresh auth loss or auth-stream error clears proof synchronously, removes
the overlay and replaces any protected route. Error logging is fixed generic
text only.

Exact personas require exact pinned UUID, email and protected role. A missing or
wrong persona claim receives a dedicated blocked state and cannot be demoted
into an ordinary-member path. Every non-Founder Test account is IDV-gated:

- an ordinary Test member requires `verified`;
- an exact synthetic persona additionally requires duplicate review explicitly
  clear (`NULL` is denied), consent granted, exact fixture marker
  `founder_test_synthetic_idv_fixture_v1`, and non-epoch consent, update and
  decision timestamps; and
- an invalid fixture shows only **Check again** and **Return to sign in**. It
  cannot reach a real consent, provider or deletion flow.

The exact Founder operator bypass remains earlier than the member IDV gate, as
ruled. No fixture row or protected role has been seeded live.

## 4. Staged server surfaces — not live

The Founder persona Edge Function, its durable SQL package and the fifteen-RPC
legacy Developer Access hardening overlay are present only as staged artefacts.
Their project, Founder and four persona source pins are inert sentinels. Nothing
was deployed, applied or executed against a database.

The broker's staged controls include an atomic `4/minute` plus `2.5 seconds`
limit, repeat Founder checks, target validation before rate-slot consumption,
and coarse durable outcomes `post_config_denial`, `mint_failed` and `issued`.
The private outcome table keeps only minute bucket, outcome, count and expiry,
with 30-day cleanup. It stores no caller, Founder, session, persona, token,
email, IP, payload or raw error. The recorder is project/app guarded,
`SECURITY DEFINER`, empty-`search_path`, schema-qualified and executable only by
`service_role`; issuance withholds the response when the durable `issued` audit
does not return scalar true.

These safeguards do not resolve the governing contradiction in §9.
`auth.sessions` is documented only as defence in depth, not as complete GoTrue
session-validity proof. Both SQL harnesses and the Deno policy suite are authored
but unrun: no authorised disposable Supabase-shaped environment or Deno runtime
was available. No runtime evidence is inferred from static tests.

## 5. Credential hygiene and historical redaction

The shared-password client path is removed. The repository has zero
`signInWithPassword` source matches. Legacy helper credentials were removed;
the helpers now require ephemeral caller input, reject Production, demand the
exact staging pin and remain inert while that pin is unassigned. The SQL custom
GUC input is supported only transaction-locally and must be cleared before any
write; session/pre-transaction use is unsupported. None of the helpers ran.

Four historical documents retain their meaning but replace literal legacy test
credential values with `[REDACTED — legacy test credential]`. A final independent
scan found zero matching paths across 1,804 non-generated ZYRA paths. Count-only
binary scans also found zero legacy password-pattern occurrences in the
immutable Production build 2 App.framework and the current Founder Test
simulator App.framework. Production build 2 contains two generic `@zyra.test`
string occurrences; the ruled boundary is no embedded credential and no
reachable/exposed route, not byte absence.

Local removal does not rotate or prove the state of any historic live account.
Live credential status and rotation remain unknown and separately gated.

## 6. Verification evidence

1. Full non-visual Flutter suite: **655/655 PASS**.
2. `flutter analyze --no-pub`: **clean**.
3. `python3 tools/zyra_check.py`: **195 files / 0 findings**; checker unit
   suite: **1/1 PASS**.
4. Fresh unsigned simulator builds: **PASS** for both identities. Production
   resolved to `ZYRA` / `app.zyraconnect.zyra` / `AppIcon` / `1.0.0 (2)` with
   Production OAuth unchanged. Founder Test resolved to `ZYRA Test` /
   `app.zyraconnect.zyra.test` / `ZYRATest` / `1.0.0 (2)` with placeholders only.
5. Locked/missing Founder Test configuration: validator exit **1**, with no
   fallback. The public example fails the Supabase, OAuth, Founder, persona and
   identity pins as intended.
6. Visual suite: **275 pass / 60 known pre-existing golden mismatches**; no
   additional overflow or exception and no pixel regenerated. Approved
   manifests remain exactly
   `4667f42228d76dcb0893c247ea5c95c2f9556f485fc3fb8af3ece76974b5e03e`
   and
   `b8070c0be1c9a62e00704229c849794e39ce87db5f5ab6ab2ea49346e0dd3f26`.
7. Auth-stream fail-closed focused suite: **11/11 PASS**. Credential-helper
   focused suite: **6/6 PASS**; shell syntax clean; inert probes stopped before
   network access.
8. Independent narrow re-audit after both final findings: **PASS**, no remaining
   local blocker.
9. Existing uploaded Production build 2 IPA is byte-unchanged:
   `1e17a1c3475db1bcb01e59415768d94480538bb601aedcdc8fdd706ea1a7b673`.

## 7. Key hash ledger

### Governance and documentation pre → post/new

| File | True pre SHA-256 | Final SHA-256 |
|---|---|---|
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `8940194130b9543e696e8021dc8af7eaafcd34e11a66502eb897ed0f40e00dcb` | `ac9025fc53a2f68d48683b68e1de7e7b98eef65b4ccbc7b59780c7ec5f4406a2` |
| `AGENTS.md` | `14c710123d30e9f5c31a27b5963a7ea23eb61a3b94e829a2f4ce18b5cf0b56f1` | `7999dd41393b264bc58882608c85310eafc548d32995a48759ceda7e0330b120` |
| `CLAUDE.md` | `eb4650a662a9b75801c00cb080b6866e298df75511ab84e8d5117ce06a730f5c` | `2f25d3548ffc9891c3751b060e5d5989f66ffc96d4d7a1ab57fcfb8cd0fc47c3` |
| `SYSTEM/tools/generate_doc_index.py` | `7b742c23bd80b40f6562b95da04ad4bdbd895550ede0f7f9dd747fed915a2ffa` | `9a13c2e20ca595adf2ac90446153d33caac6d139d0fab3e43b31108dae8de540` |
| `APP/Developer Mode/Summary.md` | ABSENT | `84c478b87cf45e55d60fb777fad1596f5c0d1707122b378f45c3680c0abcdbf4` |
| `APP/Authentication/Summary.md` | ABSENT | `9f7d68375a3ad898135e06bc96c43134dcb375547cdcfa6afc7d2a11370dfcfc` |
| `SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V3.md` | ABSENT | `76147a65c753558f81427eb6243af5de8d1e9593e1f4c3502ebca75ccc963d3f` |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md` | ABSENT | `dad505fa498e7cd99302efeaeb4146d0a8b2cb2301303f24aa44669aac51f6d8` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md` | ABSENT | `b3372386125c533ac2cfd2e2db8cc4d90282519b85725a6ae3dcd5e4a18f434e` |

The superseded Settings V2, Developer Control V1, App Store Runbook V1 and
Documentation Index V3 were byte-preserved in their established archive paths.
Future implementation references now name OA-ZYRA-286; historical register
entries were not rewritten.

### Critical local security artefacts

| File / surface | Final SHA-256 |
|---|---|
| Developer authorization | `14ccdeb377a8030ca6775761cc70d4b148efc9b6e9739415a3bbdbf78feb5e07` |
| Global authorization overlay | `99d1e2a17ad237821c3e13a500925261305c0c76fd8b9ce8bde56288446fd33e` |
| Session router | `c98afa9d6c313c390f42b957dadb3755cc89f5806c5c0d57a492a6fca2cbe672` |
| IDV screen | `8d4e32709c0505cdb02a4859ad9ec12304d64bb4e755f03e6b23b54f480caff1` |
| Approved-resource pins | `1364aafc27d946769b54e20c066af76344823763439d9e98754711ac33ea8b58` |
| Executable config validator | `424efa7002fc7ee070b75bd66b83e8d37a7724773d2a09c284e0814a3b578828` |
| `run.sh` | `ee9a251128ee0a9f6dd8920d95d71716f1e8b893750701a6e33998655fc503fe` |
| Governed Founder Test IPA builder | `88a63966f53e5c035e8786e191c79810c28cd7aa2aeb1442282592468cb59aed` |
| Staged persona/audit SQL | `8501da59ce97e2277115764bcbdc518f04379f6f71269f0ece432a5c99908f02` |
| Staged Edge entrypoint | `5f552948e83bc692d2ab0d7bfbf118dd741e03a43bd14dd1f325c00191241e04` |
| Staged Edge policy | `9a9c480ff7411d455465ef86fc52f34dcc8a181184003597055e61ee37ec05f9` |
| Staged Edge README | `b3e355cee3e13c49a771cdff29a59edb86f9fde969114aa63d81503b5530555e` |

The final auth-stream correction is independently chained:
`lib/dev/zyra_global_dev_overlay.dart`
`35f631c1ebf576054e809bab96edc64bda16f6a454de988bd02f6bc8a55777a4`
→ `99d1e2a17ad237821c3e13a500925261305c0c76fd8b9ce8bde56288446fd33e`;
its test
`9dd10bbc9b2c07da97ba1cd10caf56836110cbbbf938c809a1ba6f46dc5a0c50`
→ `1cd21346d5849cfecf63eb0386bcb562555e5dea37a7a3ef63b4b7fd0e39f8a3`.

The four redacted historical files also have true pre/post hashes:

| File | True pre SHA-256 | Final SHA-256 |
|---|---|---|
| `REPORTS/CURRENT/ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md` | `8b7b6759f7d2117b48faf7852a069708d0b96c16ae0b0b85bc4002e3259af1ad` | `7c22d5ac617f2f9b2ea177b51554813a4c28769fc1bca1746de206e1356d64e9` |
| `SYSTEM/DOCUMENTS/ZYRA_ENGINEERING_AUDIT_CURRENT_VERSION_V1.md` | `98441440203d1c1b131f8441a10a430de34b2e0cd26b89b43ea1bf7e4fdb40c4` | `b379feef427f36823ccbb3f5ba1c4e46c1987d5b20844fbac0fbe8fcd95b10d1` |
| `SYSTEM/RESOURCES/TEMPORARY/CHATGPT_REPLY_ENGINEERING_AUDIT_2026-07-26.md` | `0041417398e3f02ede9800702aad32048d40e1eafb9d4e9c6370ad66c804c91f` | `6b270fed55707c53c42204b1d111060f9d488150837533cd0fb4e1030721dcf5` |
| `SYSTEM/RESOURCES/TEMPORARY/SESSION_HANDOVER_2026-07-25.md` | `8a416442cee44ecd90d2fe70406d06814c521162bbbd82d523d19af00ff5bcdf` | `2a286e6f00211e6c6e994591ee313b3f48915e008094a4ab9f05206d8101134d` |

Two implementation files lacked a true before-edit snapshot at the point they
entered their respective agents' scope:
`SOURCE/test/zyra_founder_persona_staging_sql_test.dart` and
`SOURCE/lib/screens/onboarding/identity_verification_screen.dart`. Their
pre-hashes are recorded as **uncaptured** and were not reconstructed or promoted
as audit anchors. No unrecorded value is invented here.

## 8. No external action statement

This local programme did not create or change a staging project, schema, Auth
principal/role, OAuth client, provider setting, Apple App ID, App Store Connect
record, certificate, provisioning profile, signed archive, IPA, TestFlight
group, tester or upload. It did not apply or deploy SQL/functions, touch
Production data, regenerate approved pixels, change Production build 2, or run
git.

## 9. Required Founder rulings and live gates

The next decision is a narrow governance ruling, not a deploy approval:

> Amend/clarify DR-ZYRA-228 and OA-ZYRA-286 item 6 to permit the exact
> Founder-authorized staging broker to return one short-lived, one-use Supabase
> magic-link `token_hash` over TLS solely so the native Test client can redeem a
> real synthetic-persona RLS session, subject to no logging/persistence,
> replay-denial, durable successful `issued` audit and independent expiry proof;
> **or** reject that exception and require a proxy/fixture-only design with no
> real persona bearer session.

The current broker cannot be promoted under the literal rule that it returns no
token or privileged credential. No deployment may silently treat `token_hash`
as exempt.

Separately, the Founder must accept the documented `auth.sessions`
defence-in-depth limitation or require a supported session-introspection
alternative. Before any persona is enabled, the Founder must approve exact
staging/Founder/persona pins and reviewed synthetic fixture IDV states, and
fixture-only behaviour must be directly proved.

Only after those rulings may separately scoped gates be requested, in order:

1. staging project and exact resource creation/configuration;
2. reviewed schema replay and staged SQL-harness execution in an authorised
   disposable Supabase-shaped environment;
3. protected Founder/persona role and synthetic-fixture provisioning;
4. SQL apply, Edge/legacy-RPC deployment and direct negative/live verification;
5. Test OAuth resources and redirect verification;
6. Apple Test App ID/App Store record, signing and archive identity proof;
7. one exact internal TestFlight upload, Founder-only group assignment and
   device acceptance.

Every stage requires its own exact Founder GO. Public/external distribution,
Production backend/config changes and Production build replacement remain out
of scope.

## 10. Register disposition

OA-ZYRA-286 is **not closed**. Local construction and evidence are complete;
the governance ruling, staging/server execution, Apple delivery and final
Founder acceptance remain outstanding.
