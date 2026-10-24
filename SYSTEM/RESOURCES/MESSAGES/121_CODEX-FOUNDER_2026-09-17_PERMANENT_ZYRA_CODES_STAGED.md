# 121 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** Permanent ZYRA Codes and two-sided Guardian requests staged  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289

## 1. Outcome

Founder-selected Option 1 is implemented in source for both roles:

1. permanent role-specific ZYRA Code;
2. Copy, local QR and native Share;
3. Scan code or Enter code;
4. first name + role preview only;
5. recipient-bound request;
6. code-owner Accept/Decline and requester Cancel;
7. `wali_links` written only after owner acceptance.

The old Generate Invite Code UI is removed. Legacy seven-day codes remain
usable through a fallback shown only after a permanent-code lookup fails.

## 2. Security design

- random 80-bit non-sequential code;
- code is a discovery handle, never a credential;
- rotation plus hash-only no-owner retired-code non-reuse;
- 10 previews/hour and 30/day per authenticated caller;
- neutral result for invalid/self/blocked/same-role/ineligible/already-linked;
- block, role, romantic-conflict and existing-link checks repeated at write;
- no photo, IDV claim or third-party QR/deep-link provider;
- relationship answer remains Guardian-owned in both directions;
- direct authenticated invite inserts are revoked, and legacy summaries do
  not misread personal-code requests;
- a trigger blocks the old legacy accept RPC from accepting a personal-code
  request unless the code owner is the accepter.

## 3. Staged migration — NOT APPLIED

`20260917144606_oa289_permanent_personal_codes_guardian_requests.sql`  
SHA-256: `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575`

Read-only live inspection confirmed the expected `wali_invites` pre-state,
`pgcrypto` in `extensions`, and no live history row for this migration or the
earlier staged `20260917133709`. No production mutation occurred.

## 4. Verification

1. `flutter analyze`: PASS, zero issues.
2. Focused affected tests: PASS, 38/38.
3. iOS profile no-codesign build: PASS, 35.0 MB.
4. Full suite: executed but remains non-green from existing broad
   visual/developer debt. The one directly affected old-invite expectation
   was updated and its focused suite passes.
5. OA-ZYRA-289 SQL harness prepared, SHA-256
   `e1f04bc60b382dccbe36551ad7b506039e50eb336fd1c3320ac9f8f6dd971815`;
   not executed because an isolated replay is a separate destructive gate.
6. No app install, migration apply, cloud write, TestFlight or git operation.

## 5. Records

- DR-ZYRA-231 filed; next decision ID is DR-ZYRA-232.
- OA-ZYRA-289 filed; next action ID is OA-ZYRA-290.
- Guardian relationship source reconciled.
- Full hashes and pre-state ledger:
  `ZYRA_PERSONAL_CODE_AND_GUARDIAN_REQUEST_HANDOVER_CURRENT_VERSION_V1.md`.

## 6. Gate

Do not run `./run.sh` yet: the new page correctly depends on RPCs that are not
live. The next safe step is an authorised isolated database replay. After it
passes, the Founder can review the exact migration hash for one production
apply, followed by post-apply checks and then the phone install.
