# 113 — CODEX → FOUNDER: Test cloud retirement verified

**Date:** 2026-09-12 · **Work:** OA-ZYRA-286 · **Operator:** Codex
**Status:** three named cloud resources EXECUTED → POST-VERIFIED. One shared
Google domain listing remains unresolved. Main replacement Apple delivery is
NOT complete. Only the Founder approves; this report is not self-acceptance.

## 1. Authority and scope

The Founder cancelled the separate ZYRA Test app, retained one main ZYRA app,
approved deleting Test-only cloud resources and keeping historical records.
The immediate final gate named the empty Supabase Test project and Google's
two Test clients; the Founder replied **"Confirm"**. That was the action-time
confirmation consumed in this round. The earlier blocked action in 112 was
not bypassed. No migration, production mutation, signing, Apple registration,
upload, new credential, VM/replay or git operation was authorized or performed.

## 2. Exact destructive actions and postchecks

### Supabase

- Deleted: **ZYRA Test**, `xqweloifosbwfgctzros`, organization
  `pdekarsldtaqlqdthgwh`, eu-west-1, created 2026-09-12T11:10:32.999669Z.
- Fresh read-only project identity was ACTIVE_HEALTHY / PostgreSQL17.6.1.166.
- Fresh count query returned **0 Auth users, 0 public base tables, 0 Storage
  buckets, 0 Storage objects**. The earlier function inventory was empty.
- In the exact project's settings, the confirmation named ZYRA Test and said
  the action could not be undone. Typed its non-secret project name and
  clicked the final delete button once.
- Postcheck: browser returned to the organization project list containing only
  the main project. Connector `list_projects` independently returned exactly
  `sxoaxonzjqkgajmlagyk` / ZYRA-APP-LAB's Project / **ACTIVE_HEALTHY**.
- The deleted Test project's own Auth configuration, including its temporary
  loopback callback, is retired with it. No query ran against the deleted DB.
- **Recovery:** Supabase deletion is permanent; no user/app/storage content was
  present to recover. This was not a reset, pause or replacement project.

Fresh precheck SQL, Test project only:

```sql
select 'auth_users' as area, count(*) as count from auth.users
union all select 'public_tables', count(*)
from information_schema.tables
where table_schema='public' and table_type='BASE TABLE'
union all select 'storage_buckets', count(*) from storage.buckets
union all select 'storage_objects', count(*) from storage.objects;
```

### Google

In company account `admin@zyraconnect.app`, project `zyra-app-506315`, selected
only these two exact rows after checking their complete client links:

| Retired client | Exact client ID |
|---|---|
| ZYRA Test Supabase Web | 734578322486-k3v6akqgv55pv3ukgj521lh7ebokja6r.apps.googleusercontent.com |
| ZYRA Test iOS | 734578322486-lk30rpiog0gh01f679qvmpgen8a0jak8.apps.googleusercontent.com |

The confirmation said **Delete 2 credentials**, immediate loss of API use,
and **30 days** to restore through Google's deleted-credentials page. One
final Delete was submitted. Postcheck: both Test rows disappeared and only
these three exact main clients remained, all unselected:

| Preserved main client | Exact client ID |
|---|---|
| ZYRA Android | 734578322486-1o7jvjl39cnhaqm30akdn9kg8ph89kgs.apps.googleusercontent.com |
| ZYRA iOS | 734578322486-eoh5ba4usl0svs9ihqh2ltagqfgusnft.apps.googleusercontent.com |
| ZYRA Supabase Web | 734578322486-gvi63m04ogd7bbmsunokuq2klkepetq1.apps.googleusercontent.com |

The possible Test Web secret-exposure action is resolved by **client
retirement, not rotation**. Exposure was unconfirmed. No secret was read,
entered, copied or saved; unrelated credentials/sessions were not revoked.
The manual-only credential-handling preference remains in force.

## 3. Residual Google metadata — not silently repaired

The shared Branding page still lists the deleted Test project's domain
`xqweloifosbwfgctzros.supabase.co` alongside the main domain.
Removing only the Test row produced Google's warning that it was used by the
main Web client's URIs and that client credentials must first be updated.
**Discard changes** was used; both original domain values and disabled
Save/Discard controls were then observed. No Branding save occurred.

Read-only inspection of the named main Web client showed **exactly one**
redirect: `https://sxoaxonzjqkgajmlagyk.supabase.co/auth/v1/callback`, and no
JavaScript origins. No Test URI was visible. This conflicts with the warning;
the reason is not established. Main-client fields were not changed or saved.
OA-ZYRA-286 retains this bounded discrepancy. Do not change the main callback,
rotate its secret or revive Test resources as a speculative repair.

## 4. Apple/source state remains unchanged

No separate Apple Test App ID or App Store Connect record was created by the
cancelled workflow (111/112 evidence), so no Apple registration was deleted.
Main Apple6810741513 / Team9Y7Z8F36SJ / `app.zyraconnect.zyra` is preserved.
The recorded live TestFlight version remains **1.0.0 (2)**; this turn did not
change or freshly re-audit Apple. The developer-access candidate **1.0.0 (3)**
is unsigned compiled source, not a signed IPA, upload or assigned build.

The first update, once delivered, is **TestFlight → ZYRA Connect → Update**;
internet access is enough, not the same Wi-Fi. Signing/export authority and
exact artifact upload remain separate unresolved delivery gates (112).

No SOURCE files changed in this round. Source retirement and its byte-preserved
52-file archives remain as measured in 112. Do not rerun consumed workflows.
No Flutter suite/analyzer was rerun for cloud/document-only changes. The latest
dated results remain 112's 910 PASS / 60 known visual failures, clean analyzer,
and unsigned main compile PASS; not a full-suite PASS or device acceptance.

## 5. True pre-states and document reconciliation

Before editing, root copied actual current bytes to:

`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-cloud-retirement-prestate.eKlRTm/`

Paths below are relative to `/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/`.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| AGENTS.md | cfe8004a3772420993bd2f6356fb8e5d02bf98ec8eb2c46993c7b0515beb7b54 | 5e8fd93e8685973b3bf73e27524c1e024b97c1e88139da20f3fae898f9b30428 |
| SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md | cec7ae8d2693e4fca9d0fdebfe9672a3ea42c1dc284a4fd9275f7f652cb8dc89 | 30d627e45a78ea1a1fa89514061825fa04c591e2f04d82386ede66d4194ddf62 |
| SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md | c1d256b3c24f4285b77ca08bbf378cb628ec058bd70efe97f271982870285d74 | db80ba4abcc1de098e1ae2f60260c35fe5544c6acde0f2ea874e7070838d11ea |
| SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V3.md | 461e4697cc000d1710ed2d207c471c412982c4f752076cded7460f4769ba283d | 7b1e824afd129db0525313c521bb50693db1a51bdf488233a230b7a6b4a77cf7 |
| SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md | 4df0b98811173ed72aa09baac2523d0e9086ffe571c162ffc107b30bde2cd49d | 8710c2b9c7c55cd3ec8306a42fee6dde8b4367b6add130bbd91400264f3d6bc2 |
| SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md | 5f1cc382cb973347d88a2f8199a0fbe3231f607a0004e9a1740bb9742ae1723c | f838e3bcad5a85d2c415650a3a59462f05f37725c713b8eb2f54e0bd44965bdc |

These current files now distinguish the three verified deletions from the
residual domain listing, retain signing/upload holds, and link this report.
Report112, historical decisions, consumed one-use markers and prior archive
bytes were not rewritten. New report113 has no pre-file; its final hash is
returned separately, not recursively embedded.

Settings & Identity now describes the one-app local-preview boundary; its
unchanged member identity/authentication, Identity Correction and App Lock
sections (2/3/6/7) were verified byte-identical. Its complete former V3 and the
index pre-file are preserved in:

`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-settings-retirement-prestate.amCYRs/`

The existing index generator was unchanged. A guarded traversal excluded
PRIVATE paths, symlinks and mount crossings; final generation succeeded with
**644 documents: 95 current, 84 archived, 465 ungoverned**. The diff added only
23 existing/new mailbox entries (091–113) and refreshed three intended current
document rows plus derived counts. Version/Date/Owner metadata in the narrowed
handovers was split onto separate lines to match the generator's parser.
The first guard wrapper hit a Python3.9 `Path.stat` keyword incompatibility
before writing; switching the wrapper to `lstat` allowed normal generation.
No generator, source or cloud fix was made. Root rechecked final document hashes.

OA-ZYRA-286 was reconciled by its single assigned writer after a complete
register read. Its current title/status now name one main app and the three
verified Test deletions; a dated addendum preserves every historical programme
entry beneath the new direction. The secret item is retirement-not-rotation,
and the domain discrepancy plus signing/upload/acceptance remain OPEN.
The actual 959,456-byte pre-register is preserved in the root archive above.
The unified diff has only two hunks inside OA-ZYRA-286; root reviewed both.
The OA-286 heading occurs once; counts, TOTAL286 and NEXT OA-ZYRA-287 are
unchanged. No other OA or historical decision was edited. The final register
hash pair is recorded in the ledger above; final size is 962,550 bytes.

Group account register entries for the retained main services are not deleted.
Local read-only validator:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/verify-oa286-cloud-retirement-documents.mjs`
SHA-256: `a93c66c737cf3f44453dafdf394e8dfae178294d1df8777431b6a1002dc3e6e5`.
It passed six current/history hash pins, five true pre-state pins, four
byte-identical Settings sections, and ten report-ledger hash checks.
This is Codex internal verification, not an independent review or approval.

## 6. Open items and acceptance

OA-ZYRA-286 remains OPEN: resolve the contradictory shared-domain dependency;
complete bounded main-build signing/export, exact upload, processing/group
verification and Founder device acceptance. No new identifier, public release,
full-cloud-erasure claim or programme closure is made.
