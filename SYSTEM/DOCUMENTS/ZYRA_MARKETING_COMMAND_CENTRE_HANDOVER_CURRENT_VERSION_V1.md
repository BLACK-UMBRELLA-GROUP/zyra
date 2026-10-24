# ZYRA Marketing Command Centre — As-Built Handover

**Version:** V1  
**Status:** CURRENT_VERSION — CODEX POST-VERIFIED; awaiting Founder acceptance  
**Date:** 2026-10-06  
**Owner:** Codex (implementation and governed record) · Founder (acceptance)  
**Authority:** Founder direct GO, “ok do those”, 2026-10-04; ZYRA-first AIOS/Marketing presentation GO, 2026-10-05; AD-AIOS-111  
**Owning actions:** OA-ZYRA-301; OA-AIOS-392; OA-AIOS-379 (workspace presentation)

## 1. What was built

AIOS Marketing Command Centre V4 adds a non-secret nine-platform account
control register, master ideas with linked platform variants, and a
Europe/London planning calendar limited to three distinct ideas per day.
Multiple platform variants of one master idea may share the same day.

Founder approval identity now includes the selected account, campaign,
schedule, media reference and optional media SHA-256 as well as the public
copy, link, risk and spend fields. Any change still invalidates approval.

Live OAuth, social publishing, public replies, advertising and credentials are
not implemented. Their state is fail-closed and no execution endpoint exists.

## 2. Architecture and invariants

- ZYRA owns the engine, web UI and atomic state; AIOS mounts the same instance.
- Account records accept non-secret operating facts only. Passwords, tokens,
  API keys, recovery codes and similar values are rejected.
- Nine placeholder rows start `NEEDS_RECONCILIATION`; they do not claim account
  ownership, security acceptance or a live connection.
- A content variant belongs to one master idea and one destination account
  before it may enter Founder review.
- Approval hashes cover all public and delivery-defining content fields.
- Published/measured records remain immutable.
- Sensitive community categories remain human-only.
- Connection, automated-publishing and automated-reply flags remain false.

## 3. Data flow

```text
non-secret account facts -> account register
master idea -> one or more platform variants -> brand/compliance checks
variant + account + media + schedule -> exact Founder preview/hash
Founder approval -> manual publishing pack -> public URL -> manual metrics
```

Failures reject the write and leave the prior atomic state intact. The daily
limit counts distinct campaign IDs, not the number of platform variants.

## 4. Live files

- `SYSTEM/tools/zyra_marketing_center.py` — schema upgrade, validation,
  account/campaign routes, calendar limit and approval identity.
  SHA-256: `2bf247255203083a6f295fb7ba5553529caede24b5d6cdb2e1fb7dafc3729d15`
- `SYSTEM/tools/zyra_marketing_web/index.html` — Accounts, Master ideas,
  Calendar and expanded variant forms.
  SHA-256: `fcae9f2df54236b8091ed585b9463cde1e9b27b86dbcb7ead26b15bf5be93928`
- `SYSTEM/tools/zyra_marketing_web/app.js` — rendering and local workflow
  actions. SHA-256:
  `094d1f8490c58d67aeff7acc6634a66f88386ffe1180a2ff6d04a7e2c8e27049`
- `SYSTEM/tools/zyra_marketing_web/app.css` — responsive account, campaign
  and calendar presentation. SHA-256:
  `6892c8a2be73b1569bdcd222dd67cc7dfcaaea64c5d25f6be4f084857bbcbead`
- `BLACK UMBRELLA GROUP/AIOS/marketing_bridge.py` — mounts new local routes.
  SHA-256: `15fb65b7e1efc4b5e18209d0c3ba91cb0b4bcf17db996f9ac42853643bc17de0`
- `BLACK UMBRELLA GROUP/AIOS/workspace_marketing_shell.py` — shares the
  Founder sidebar and home styling through an external CSS asset, leaving
  the ZYRA Store, template and workflow unchanged.
  SHA-256: `df6873a975cbc17bed19008c476ad904d30efa2d7e26e774fe2153de4cabea1a`
- `BUSINESS/ZYRA MARKETING SYSTEM/ZYRA_MARKETING_SYSTEM_CURRENT_VERSION_V4.md`
  — current specification. SHA-256:
  `6ee1a484a05e4fde68e57409aebda5417e5dd1c98817402ea9877fbe11d6698d`
- `SYSTEM/RESOURCES/MARKETING_COMMAND_CENTER/state.json` — atomic runtime
  state. Older V1 state is upgraded in memory and persists as V2 on its next
  mutation; no destructive migration is required.

Pre-edit hashes for the code/UI files were not captured before implementation.
That audit-anchor requirement was missed and is recorded here as a deviation;
no reconstructed value is presented as pre-edit evidence. Pre-edit hashes were
captured before the subsequent OA and supporting-document edits.

Supporting-document trace (`pre → post`):

- `Script Summary.md`: `0722a21e…f465983 → a0cde3ee…ca81e345`
- `Flow Blueprint.md`: `2cda80ed…ee1a4c5 → 1461416e…f183f3f`
- ZYRA OA register: `924990a4…e93ee76 → fe7eaba7…338c074`
- AIOS OA register: `4e59f115…0390e5 → 7b10a445…fd506`
- regenerated documentation index post-hash: `c7a55750…169cee`

## 5. Entry point and access

Canonical entry: `http://127.0.0.1:7700/marketing/`.

AIOS permits only full Founder scope to this route. The service remains bound
to localhost. The existing launch service was restarted once after the build
and returned on the same port with a new PID. No install, remote exposure or
account connection was performed.

## 6. Mock versus live behaviour

Live/local: state validation, account records, campaign relationships, calendar
limit, approval identity, manual pack export, event records and UI.

Provisional/manual: real handles, login identities and security statuses have
not been reconciled. Metrics and publication URLs are manually entered.

Not implemented: platform authentication, token storage, scheduling APIs,
publishing, comment/DM ingestion, automated replies, advertising and automatic
analytics.

## 7. Original 2026-10-04 verification

- `python3 -m py_compile ...zyra_marketing_center.py ...marketing_bridge.py` — PASS.
- `python3 -m unittest discover -s SYSTEM/tools -p test_zyra_marketing_center.py`
  — 11 passed, 0 failed.
- `python3 -m unittest test_marketing_bridge.py` — 4 passed, 0 failed.
- Launch service after restart — RUNNING; port 7700 listening on localhost.
- `/marketing/` — HTTP 200, 16,997 bytes.
- `/marketing/api/state` — schema version 2; 9 accounts; 3 campaigns; 3
  variants; live connections false.
- Browser verification — Command, Social accounts, Master ideas and Calendar
  render; no browser console errors or warnings observed.
- JavaScript CLI syntax check was unavailable because Node.js is not installed;
  browser parsing/execution and zero console errors provide the runtime check.

## 8. Remaining gates

Owned by OA-ZYRA-301 / OA-AIOS-392:

1. Reconcile each real handle, URL, login identity and non-secret security fact.
2. Harden request-level AIOS authentication and CSRF protection before tokens.
3. Select and approve an encrypted external secret store.
4. Approve one provider/platform connection at a time with least privilege and
   tested revocation/recovery.
5. Add controlled scheduling/publishing only after steps 2–4.
6. Add read-only analytics ingestion before any community write capability.

No new OA was created because the two existing actions already own every gap.

## 9. Rollback

Stop the AIOS service, restore the previous five code/UI files from the
Founder's repository history, and start the same local service. State V2 is a
superset of V1; older code ignores the added top-level collections and added
content fields. Do not delete account/campaign records during rollback.

## 10. Authority map

- Product/operating specification: ZYRA Marketing System V4.
- Build contract: `Script Summary.md` and `Flow Blueprint.md`.
- As-built truth: this handover.
- Trace/action ownership: OA-ZYRA-301 and OA-AIOS-392.
- Final acceptance: Founder only.

## 11. 2026-10-05 — aligned with the ZYRA-led AIOS workspace

The mounted `/marketing/` page now retains the actual shared AIOS sidebar and
uses the same charcoal background, system type, quiet gold controls, card
styling and page spacing. Its ten existing Marketing sections are secondary
tabs, not another global sidebar. One Marketing heading replaces the separate
wordmark/header/back link. The header says Private workspace rather than
claiming that an authenticated remote session is local-only.

This is a presentation adapter; the existing standalone ZYRA HTML/CSS/JS and
marketing engine are unchanged. All form/control IDs, local workflow routes,
account/campaign records, approval identity, manual-only publication and
connection restrictions are retained. Only full Founder scope can reach the
mount. `/marketing` canonicalizes to `/marketing/` after that guard.

The CSS is external and same-origin: `/marketing/aios-shell.css`. The existing
self-only CSP remains; no unsafe-inline allowance was added. If the source
template no longer fits the adapter, the bridge returns HTTP 503 rather than
silently displaying a separate app. Modal centering was explicitly preserved.

Verification on 5 October, repeated after midnight on 6 October Europe/London:
51 AIOS/bridge regressions and 11 unchanged engine regressions
passed, plus compilation. A separate Codex internal review passed 24 fixture
tests and checked unchanged control signatures. Live browser checks exercised
all ten sections, global navigation to Overview/Finance, and the account
dialog without saving; no horizontal overflow at the actual 1280 × 720
viewport. No mobile device was tested. Runtime state was byte-identical before
and after those checks; no account fact or content record was rewritten.
The same localhost service was restarted once and its health/mount/CSS probes
passed. No provider, public publishing or release approval took place.

True pre-edit bridge and handover backups are in Group
`ARCHIVE/CODE_BACKUPS/AIOS_ZYRA_MARKETING_ALIGNMENT_2026-10-05/`.
The comprehensive pre/post hashes, ownership, runtime probe, screenshots and
presentation-only rollback are recorded in Group
`SYSTEM/ARCHITECTURE/AIOS_WORKSPACE_HANDOVER_CURRENT_VERSION_V1.md`, §9.
That dated OA-AIOS-379 evidence is presentation-only; OA-ZYRA-301 / OA-AIOS-392
remaining connection/security/legal/publication gates are unchanged.
