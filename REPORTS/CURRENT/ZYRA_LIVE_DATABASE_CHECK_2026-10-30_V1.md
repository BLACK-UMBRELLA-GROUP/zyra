---
id: SERVER0-LIVE-2026-10-30
type: REPORT
status: CURRENT
feature: DATABASE
purpose: Production read-only SERVER 0 check of migration drift, Basic capacity, synthetic flags, filter fields, Pause inventory and safety metadata on 30 Oct 2026
links: [DOC-ZYRA-0329, DOC-ZYRA-0294, OA-ZYRA-317, OA-ZYRA-319, OA-ZYRA-324]
owner: Codex
---

# ZYRA — LIVE DATABASE CHECK — 30 OCT 2026

Production was read only throughout. The connected Supabase project is `sxoaxonzjqkgajmlagyk`, eu-west-1, ACTIVE_HEALTHY,
PostgreSQL 17.6 (image release 17.6.1.147). Every live SQL request used `BEGIN READ ONLY` and `ROLLBACK`; returned values were
catalog metadata, hashes, boolean checks and counts. No credentials, account records, function/view bodies or member contents
were returned. No production DDL, migration apply, user change, deployment or service action was attempted.

Built from `PRODUCT/APPROVED/SERVER/BRIEFS/SERVER_0_BRIEF_2026-10-30.md` and approved DOC-ZYRA-0329 §§3.2, 3.4, 3.6, 4 and 5 line 0.
This is a fresh snapshot; DOC-ZYRA-0294 stays in place for Fable to archive. This report does not certify a production apply.

## What the live pass establishes

| Question in the approved design | Verified result |
|---|---|
| Applied migrations | 211, unchanged between the opening and closing connector lists; exact version/name lists in ignored evidence. Repository has 228 SQL files. 28 have the same name under a different live timestamp; two historical timeline/rewind aliases are accounted for. Exactly 17 remain unapplied, listed below. |
| Basic places today | `zyra_active_journey_cap(uuid)` already returns 1 for Basic and 3 for active `seeker_premium`. Two active Basic rows both have cap 1, with 0–1 places in use; three active One rows all have cap 3, with 0–1 in use. This helper also returns 1 without premium; it is not yet the approved fee-entitlement gate. No new `plan_limits` table was installed. |
| Synthetic flags | `is_synthetic` exists on `onboarding_answers` and `seeker_details`, not `profiles`. Each has 144 rows, all flagged synthetic. |
| Test accounts | 153 auth accounts: 149 end `@zyra.test`, four do not. All 149 profiles belong to test accounts: 144 Seekers and five Guardians. No identities were inspected; the four other accounts were counted only. |
| Filters' fields | `profiles.date_of_birth`, `gender`, `location_text`; `seeker_details.country_of_birth`, `nationality`, `ethnicity` exist. `country_of_birth` is not current residence. There is no structured current-country/city/coordinate field on those tables. Age can come from date of birth. Location rules and new fields belong to the later approved work. |
| Older Pause parts live | Functions `suspend_journey(uuid)`, `resume_journey(uuid)`, `nudge_paused_journey(uuid)`, `restart_journey(uuid)` exist. On matches: `suspended_by`, `suspended_at`, `pause_nudged_at`, `also_paused_by`, `also_paused_at`. On attempts: `paused_by`, `paused_at`, `also_paused_by`, `also_paused_at`. |
| Shared Pause parts live | Neither table has `pause_state`; `transition_journey_pause`, `zyra_reject_locked_journey_write` and `zyra_guard_paused_return_initiation` are absent. There are zero pause-lock triggers calling `zyra_reject_locked_journey_write`; the 13 locks introduced by Aug25 are not live. |
| Message safety | The 9 Aug policy remains: caller is sender, active conversation, active attempt via caller-scoped participation, Seekers only, block helper checked. Policy MD5 `384f2cb6644317e9092d75e877b1ce8c`; canonical participant-view MD5 `caf3438a766235768dc418b9ab6ac363`. The proposed Sep24 replacement is still unapplied. Stage-8-only and paid Guardian Chat rules are not certified live. |
| Feature availability | Hide's two functions, Pause My Profile's two functions, `zyra_browse_ranked_ids`, `zyra_open_family_message_circle` and `zyra_has_paid_role` are absent. Product telemetry foundation remains unapplied; its activation was not changed. |
| Current data counts | Three active attempts, two ended; two messages; seven active subscriptions (Basic Seekers 2, One Seekers 3, One Guardians 2). There are 597 photo rows referencing 99 paths; the photo bucket contains 103 objects. |

## Migration difference

The exact original file identities are pinned in the NOT READY disposition:
`PRODUCT/APPROVED/SERVER/RECORD/SERVER_0_READY_2026-10-30.md`. The 17 unapplied files remain unchanged and unmoved because the
approved keep/drop set failed preflight. No runnable production payload or new migration was generated.

- `20260825120000_shared_pause_decision_state_machine.sql`
- `20260918140508_oa294_main_guardian_optional_journey_hold.sql`
- `20260918145126_oa295_known_person_code_matching.sql`
- `20260918171910_oa256_product_telemetry_foundation.sql`
- `20260919185927_oa298_family_messaging_foundation.sql`
- `20260919191016_oa299_journey_return_initiation_gate.sql`
- `20260923225150_retire_unused_legacy_purchase_mutators.sql`
- `20260924100231_founder_paid_only_returns_guardian_circle_contract.sql`
- `20260925215350_family_circle_participant_list.sql`
- `20260926144532_family_message_sender_identity.sql`
- `20260926233533_message_read_receipts.sql`
- `20261005113808_oa305_f01_safety_report_retention.sql`
- `20261005114141_f02_guardian_current_attempt_read_boundary.sql`
- `20261005113453_f03_photo_row_object_owner_binding.sql`
- `20261005120711_oa305_f04_private_legacy_score_and_browse_ids.sql`
- `20261005120004_oa305_f05_private_progress_helpers.sql`
- `20261005120420_f06_f07_unlock_hold_serialization_receipts.sql`

## Security advisor

The connector reports the same counts as 26 Oct: one security-definer-view error, 98 callable security-definer-function
warnings, one leaked-password-protection warning and 16 RLS-without-policy informational findings. These are existing
OA-ZYRA-312 / OA-ZYRA-317 launch-review work, not findings fixed by this check. The caller-scoped view was inspected through
metadata and hashes; its design is not independently approved by this report.

Remediation references: [view linter](https://supabase.com/docs/guides/database/database-linter?lint=0010_security_definer_view),
[function linter](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable),
[password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection),
[RLS linter](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

## Evidence and disposition

`REPORTS/EVIDENCE/SERVER0_2026-10-30/` contains JSON only: live metadata and advisor counts, both migration inventories,
all 228 source hashes, the 52-file test inventory, replay outcomes, isolated contract proofs and BUILD.json. No source,
compiled output or database data is stored there. Migration-history equality and unchanged catalog hashes support the
read-only record; no claim is made that a live write was applied.

SERVER 0 is **NOT READY**. Written refusals R1–R4 in the disposition route the replay and keep/drop conflicts to
OA-ZYRA-317 / OA-ZYRA-319 / OA-ZYRA-324 and the existing OA-ZYRA-198 historical-bridge rules. Queue row 28 alone closes FAILED.
No production action is requested or authorised by this report.

## Current official references checked

The [Supabase changelog](https://supabase.com/changelog) was fetched as Markdown, including relevant PostgreSQL and extension
breaking changes. The [17.11 change](https://supabase.com/changelog/postgres-15-19-17-11-breaking-changes) concerns an upgrade;
this task kept the existing 17.6 runtime. [Extension version handling](https://supabase.com/changelog/extension-version-pinning-ignored)
was checked; no dependency or upgrade was installed. The connected docs search confirmed the
[testing workflow](https://supabase.com/docs/guides/local-development/testing/overview) and
[pgTAP guidance](https://supabase.com/docs/guides/database/extensions/pgtap). Installed CLI 2.116.0 and relevant command help
were inspected. No CLI link, pull, push, reset or migration apply was run.
