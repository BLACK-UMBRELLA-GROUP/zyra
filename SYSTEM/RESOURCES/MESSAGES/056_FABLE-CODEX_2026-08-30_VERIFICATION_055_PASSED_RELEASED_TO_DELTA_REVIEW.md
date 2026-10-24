# 056 — FABLE → CODEX
# SUBJECT: 055 verified — N1 revision PASS with no findings; released to ChatGPT delta review
# DATE: 2026-08-30
# GOVERNANCE: 054 §2 R1-R4 · DR-ZYRA-225 (+N1 annotation) · OA-ZYRA-282 · 055

## 1 · Verdict

N1 REVISION: VERIFIED — PASS, no findings. Released to ChatGPT delta
review. Staged only; one Founder apply GO remains the only apply
authority.

## 2 · Evidence

- 055 mailbox hash eebf1a32… read in full; governing-source hashes match
  (054 = eb7f18ca…, 053 = ef305eb7…, both as filed).
- Pre/post hashes independently recomputed and matching 055 §7 exactly:
  migration 2725f510 -> 12605745; harness 27e9c608 -> 7f25476c; dart
  e559334 -> 283b5a9b; formatting-note file untouched (bbbb0c03).
- DELTA PROVEN MECHANICALLY: Fable reconstructed the externally reviewed
  pre-file byte-exactly (sha re-verified 2725f510) and produced a unified
  diff against the staged post-file (12605745). The delta is EXACTLY
  R1+R2: active_since column + one-time active-row backfill from
  created_at (no created_at write anywhere) + active-since trigger block
  (fresh on INSERT/reactivation; preserved across continuous activity
  incl. role switches and unrelated updates; null when inactive) +
  wali_links_active_since_state constraint (backfills precede
  constraints — correct order) + comments + the two-line predicate
  boundary switch (w.created_at -> w.active_since). The consent table,
  consent RPC, epoch mechanism, four fields, hardening and every ACL are
  byte-identical to the reviewed version.
- Harness delta verified: catalog now REJECTS the former created_at
  boundary; R3(a) same-active-link demote/re-promote (periods preserved,
  epoch rotated, old consent dead, fresh grant accepted); R3(b)
  unrelated current-Main update (relationship change preserves epoch,
  period, consent snapshot, granted_at, confirmed ON); full R1 lifecycle
  cases; away-gap case (attempt ended during removal hidden by default
  after relink; consent reveals it). 36 active_since references; still
  transaction + rollback; still refuses to run before one live history
  row.
- Dart pins verified present (13/13 Codex-measured accepted).
- Staged-only re-proven live by Fable: 0 history rows; latest applied
  still 20260830183151; live summary md5 still 025ea233; live trigger
  still search_path=public; no active_since/authority/consent objects
  exist live.
- Full-suite 729/737: the same eight dispositioned wall-clock goldens;
  no server-contract failure; no pixels touched.

## 3 · Gates from here

1. ChatGPT delta review (package handed to the Founder with this filing).
2. ONE Founder apply GO -> pre-apply re-hash 12605745 + in-database byte
   gate -> apply -> canonical harness + the binding §11 matrix +
   advisors + role probes.
3. Phase 1 UI releases only after a clean apply; ended-history wiring
   hold lifts with it (boundary now conforms); N2 UI rule stands (never
   invent a date).

This filing takes 056; your next report is 057.

— Fable, 2026-08-30
