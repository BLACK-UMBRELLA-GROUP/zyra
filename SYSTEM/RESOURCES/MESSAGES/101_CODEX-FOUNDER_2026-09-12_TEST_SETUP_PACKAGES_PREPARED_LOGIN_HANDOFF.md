# CODEX → FOUNDER — TEST SETUP PREPARATION / COMPANY LOGIN HANDOFF

**Date:** 2026-09-12  
**Owner:** Codex; Founder sole approver  
**Action:** OA-ZYRA-286 remains open  
**State:** Local preparation/internally verified checks; no new live GO consumed

## 1. Delivery truth

Existing ZYRA 1.0.0 build2 is already private Founder Internal TestFlight.
ZYRA Test is not delivered. Today's actual isolated persona PostgreSQL PASS
and exact cleanup are separately recorded in100; that one-use authority is
consumed and was not reused for this preparation.

The current work advanced the complete-replay route, normal Founder-login
bootstrap and a bounded fixture candidate roster. No new VM/container,
database execution, managed schema, Auth user/role, provider setting, OAuth
credential, Edge deployment, Apple identity/archive/upload or git operation
occurred after100. No production data was copied or inspected for this work.

## 2. Normal Founder-login helper prepared, not live

Task workspace:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/`.

Package: `evidence/oa286-founder-oauth-bootstrap-prep/`.

| Artifact | SHA-256 |
|---|---|
| SHA256SUMS (five files) | `32845080aea9b3d0b4147dc51ba4586b2b8e1a24468d80c7879a257c287644e7` |
| bootstrap.ts | `e327c870328d8c636ff219ca6da81ecb4c6e2082b506c3d7a9e75080eba22f06` |
| deno.lock (nine-package graph) | `3c68689621dca78ff8a2ad5acae60a9f621a0656189e2c133c8d18548edbe7b8` |

Uses the installed pinned Supabase JS2.112.2 social Google PKCE APIs, fixed
Test project `xqweloifosbwfgctzros` and company email. It does not call Admin
Auth, recovery creation, role updates, fixtures or arbitrary endpoints. It
requires a future reviewed public config and exact live GO. The real config
and `live-v1.once` marker remain absent; no listener or live Auth request ran.

Prepared callback:
`http://127.0.0.1:59187/oa286/google/callback`; Google provider callback is the
different server URL `https://xqweloifosbwfgctzros.supabase.co/auth/v1/callback`.
Neither is newly allowlisted by this work. No wildcard/Site URL change.

The helper keeps verifier/tokens in memory only, checks a fresh server `/user`
response for the exact confirmed Google identity and ordinary metadata, and
uses decoded JWT claims only for additional denial. It performs one local-
session signout, never global signout or account deletion. A lost token
response/failed cleanup is explicitly inconclusive; JWTs can remain valid
until expiry even after refresh capability is revoked. Wrong-account OAuth
can create a wrong ordinary Auth user before the helper rejects it; it never
silently deletes or repairs that user. These consequences must be in live GO.

Root internal review corrected a callback URL that could expose a transient
code to a later browser snapshot, Chromium's form-action redirect issue,
fixed-path/symlink constraints, incoming-body and shutdown bounds, and
dependency integrity pins. The terminal callback now redirects to a clean
result URL; browser history can still retain the transient code. Do not take
browser state/screenshots/network logs during the provider/callback interval.

Final worker checks:23/23 PASS, typecheck/lint/format PASS. Root rerun:23/23
PASS (99ms), exit0, with network/read/write/env/run/FFI permissions denied;
actual default preflight under the same denials exited0 and reported
`listening:false`, `auth_requests:0`. Root verified5/5 manifest entries.
These are fake-HTTP/inert local checks, not actual browser/socket/Google/Auth
proof and not independent approval. No fresh full Flutter suite was warranted
or claimed: product source did not change.

## 3. Full replay bootstrap route established, runner still to build

`evidence/oa286-full-replay-preparation/` preserves the exact207 active plus
two reviewed bridge inventory:209 unique versions, unchanged historical
aggregate `5bb9e76128b3f4bc9297cdefbf6feed63da9c226bf720de403478684c7f6901c`.
The213-input inventory adds the two staged boundaries and both transactional
harnesses. Its SHA-256 is
`82c8cf293c81d08feb28e19b8369b3bc2a9fffebefc28531ab0ad77a4f858c25`.

Official source/config packet:
`evidence/oa286-full-replay-preparation/official-cli-v2.116.0/`.
Manifest SHA-256:
`208c56339ac06746abf627da64446078a8c72367dd28d92ba1dbb6f5946aa282`.
Root verified41/41 entries and reran all six static tests:PASS,79ms,exit0.
It contains32 pinned official source files, five installed help/version
outputs, the proposed full config, images list and exact prospective sequence.

The viable route is official `supabase db start` on a new, provably absent
project/data volume: actual platform bootstrap and transient Auth/Storage/
Realtime migration jobs, then the209 ordered files and official history
recording. This avoids an invented platform schema and needs no reset of an
existing database. It requires a separately authorised internal bridge and
loopback-only host-to-VM forwarding, not the consumed V3 network-none setup.

**This is not an executable package.** Remaining preparation: one-use
orchestrator/payload copying and failure-cleanup tests; exact Colima forwarding
and exposure checks; three missing cached service-image immutable IDs; full
combined SQL/post-rollback/scheduler checks; and explicit treatment of the
CLI's lack of an enforced no-pull flag. Proposed config has not undergone
actual CLI command-path parsing. Do not ask to execute this manifest as-is.

A read-only public-registry metadata attempt to resolve those missing image
IDs failed with HTTPError; no IDs were established and no image layers or
binaries were downloaded. Cache-readiness remains unresolved. No VM, Docker
daemon or database was contacted for this metadata inspection.

## 4. Google inventory, held forms and sign-in prerequisite

Read-only company Google Cloud session observed under admin@zyraconnect.app:
project ZYRA App, `zyra-app-506315`, number734578322486. Exactly three existing
clients:ZYRA Android, ZYRA iOS, ZYRA Supabase Web; no Test client. Audience is
External/Testing with exactly the company address listed as one test user.
No existing secret was opened/downloaded, and no client was changed.

Prepared but did not submit the new Web-client form:ZYRA Test Supabase Web,
no JavaScript origins, only the exact Test server callback above. Google
states supplied URI domains may be added to authorised consent domains; the
existing domain list has not been verified. Creation/secret-transfer impact
must be covered in the next exact credential GO. The proposed Test iOS client
uses bundle `app.zyraconnect.zyra.test`, never the Production App Store ID.

Google shows an aggregate secure-flows warning and incomplete Branding notice,
and no configured scope rows. Their cause/runtime effect is not yet established.
They are tracked within this OA's sign-in readiness; do not silently change
existing clients, publishing, scopes, billing or account security.

Current native Google code requires the documented iOS **Skip nonce check**
compatibility setting on Test Google for its ID-token flow: the native SDK
generates a nonce whose raw value is not returned to Dart. Custom nonce
support exists, but the plugin's one-time initialisation is not a proper
per-login reset. This proposal waives only Supabase's nonce comparison, not
signature/audience checking; it is not a maximum-security claim. No setting
was applied. Disclose this specific trade-off in the provider GO. Production
and Apple nonce behavior stay untouched. Normal browser PKCE bootstrap is a
separate flow and does not itself need this native compatibility setting.

Supabase dashboard requires a fresh company sign-in. Browser automatic safety
review blocked starting the GitHub cross-service login without specific
approval; a later state read was also blocked. No workaround was attempted.
Founder was asked to complete the existing company GitHub login personally
in the held Supabase tab. Actual Test provider pre-state is not yet observed.

Detailed preparation:
`evidence/oa286-test-oauth-readiness.md`, SHA-256
`b5984988dddab280330bee738797328a545fe93b60060102a52f25682762e55d`.
Company Google form and Supabase sign-in tabs are marked for handoff. No new
OAuth client, confidential transfer, Auth setting or sign-in helper execution
is implied by opening/preparing those pages.

## 5. Finite fixture candidates, not accounts or fixture SQL

`evidence/oa286-fixture-candidate-plan.md`, SHA-256
`07cbdb6e6779e86aaf6f8d0eca78d517c8580326e34b5ac3022260d9daaabe63`.

Draft27 = four fixed interactive personas + three fixed Guardian-pool
identities + twenty auxiliary Seekers (ten per gender). Founder is a separate
normal provider-backed operator, not a fixture. Only four entries are
interactive; six Browse,22 suggestion and22 Journey-party capabilities are
enumerated, never domain-wide admission. Automated table count checked these
numbers; internal source review found no count/capability contradiction.

Guardian-pool wali/male is an explicit proposed coverage choice, not an overlay
gender restriction. Synthetic-IDV proposals explicitly require false duplicate
flag, NULL member_deleted_at, after-epoch timestamps, exact synthetic marker
and no provider refs/receipts; the existing sumsub enum default is disclosed,
not represented as real verification. All UUIDs and exact product fixture
values remain unassigned/unapproved. No complete SQL manifest exists and no
row was created. Max-ten and repeated-Journey coverage still need actual
selector/runtime proof; counts alone are not that proof.

## 6. Canonical reconciliation / true pre-state

True pre-files at edit time:
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_NEXT_SETUP_PRESTATE.FCuGoW/`.

| File | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| APP/Authentication/Script/Script_V3.md | `096d2188690a605e9253afd2108951d0dbc9bb7f5d25bf9de1851afcfdd5d7d7` | `fa83ade3425de9382bfb1d367c093e47377ac61a3c6f806cc215e75b36a418e7` |
| SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md | `1d9baee24f8678ebbcafb07c0c03b70d71f6c52843f220263f73eee1b98ea0da` | `101bebd68dfd01506ca655bc58abf21923a9ae0cf46bdb1dbc2c7a0b4a8f096b` |

Authentication changed only its stale persona-SQL-unrun status to100's narrow
PASS, preserving combined/runtime limitations. OA received the truthful next-
setup result; OA-ZYRA-287 remains the next unused identifier. This report and
new task-local preparation artifacts had initial pre-state ABSENT; internal
draft/test iterations occurred before their final freeze. No approved source
artifact, pixel, SQL, binary or previous attempt was rewritten.

## 7. Next boundary

Founder company-dashboard login is the next live prerequisite. Then inspect
the exact Test provider pre-state and present the bounded credential/provider
payload and consequences before applying it. Full-replay runner preparation
also remains local work; its future execution requires its own complete
manifest and GO. Do not re-open settled DR-ZYRA-229 design questions. Do not
claim the two-app programme closed or promise same-day delivery as a fact.
