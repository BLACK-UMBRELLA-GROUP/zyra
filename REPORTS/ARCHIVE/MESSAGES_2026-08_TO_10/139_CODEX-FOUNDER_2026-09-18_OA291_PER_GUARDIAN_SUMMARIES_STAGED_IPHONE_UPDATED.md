# 139 — CODEX → FOUNDER

**Date:** 2026-09-18  
**Subject:** OA-ZYRA-291 per-Guardian past summaries staged; iPhone updated  
**Authority:** Founder accepted Codex's recommended Guardian authority model  
**Production database:** UNCHANGED — migration staged only  
**Git:** not used

## 1. Outcome

1. Main Guardian remains always included in active Journeys and leads the
   existing protected decisions.
2. Each Additional Guardian now has one collapsed **Active Journey access**
   group on the Seeker Guardian page. Expanding it shows the active Journeys
   and their server-confirmed inclusion switches.
3. Every current Guardian now has a separate **Share past Journey summaries**
   control in the client. It is person-specific, server-confirmed and fails
   closed. The existing Main-only live RPC remains a compatibility fallback
   until the new migration is applied.
4. The past-summary boundary remains exactly four fields: opaque attempt id,
   started_at, ended_at and ended. No person names, stage, messages, answers,
   reasons, notes, compatibility or safety data are added.
5. Membership, Help, linking acceptance and the pricing source now state that
   paid Additional Guardian capacity does not guarantee Journey access.
6. Guardian Notes and reciprocal visibility of authorised Guardians were not
   invented inside this work. They are held under OA-ZYRA-292 for a separate
   privacy/authority contract.

## 2. Staged migration — not applied

- File:
  `SOURCE/supabase/migrations/20260918094504_oa291_per_guardian_past_journey_summaries.sql`
- SHA-256:
  `2cd6dff44ca9b0038e117ec0df6a6171e76ce92c296f1a761a6d41e0fe025b23`
- Adds a role-neutral current-active-link epoch.
- Preserves a valid existing Main consent during migration.
- Rotates authority on removal/reactivation, but not on a continuous
  Main/Additional role switch for the same person.
- Adds one caller-bound Seeker-owned RPC:
  `zyra_guardian_history_consent(uuid, boolean)`.
- Retains `zyra_main_guardian_history_consent(boolean)` as an older-client
  compatibility wrapper.
- Keeps explicit PUBLIC/anon revocation, authenticated/service_role execute,
  empty search_path and schema-qualified relations.
- Replaces no DR-ZYRA-232 current-Journey assignment authority.

This file has not been replayed against a fresh PostgreSQL stack and has not
been applied to production. It is not self-approved.

## 3. Device delivery

- `flutter build ios --profile`: PASS.
- `flutter install --profile -d 00008130-001A2C1E26F8001C`: exit 0.
- Installed app inventory confirms bundle `app.zyraconnect.zyra`, version
  `1.0.0`, build `2`.
- App launch: PASS.
- Installed executable SHA-256:
  `30fa4a42a921eb04b69966d0ca6eb21c6427f6b3ea82cea91d5de07b9cbbe17b`.

The preview controls are available for Founder review. Live Main history keeps
working through the old RPC fallback. Live Additional history remains
unavailable/fail-closed until the staged migration passes its later apply gate.

## 4. Verification

- `flutter analyze`: PASS — no issues.
- Directly affected Guardian/service/UI tests: PASS, 36/36.
- New migration contract tests: PASS, 5/5.
- Membership/layout tests: PASS, 8/8.
- Full `flutter test`: executed; non-green at 125 failures. The run includes
  the existing broad visual/developer-control debt and deliberate approved-
  baseline drift. No approved pixel or manifest was rewritten. The affected
  focused suites above are green.

## 5. Governance

- Filed DR-ZYRA-233.
- Opened OA-ZYRA-291 for this staged implementation.
- Opened held OA-ZYRA-292 for Guardian Notes and reciprocal Journey-access
  transparency.
- Reconciled the Guardian relationship source and pricing source.

## 6. True pre-state and hashes

The true pre-state was captured before source edits at:

`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-291_2026-09-18/prestate/true-pre-files.tar.gz`

Archive SHA-256:
`f17048c86ad4d85c33c7d3341cb3e47fc16f43c151f7cfc9fdc1dfb70c09ae6e`

Key pre → post hashes:

| File | Pre | Post |
|---|---|---|
| `DECISIONS_V1.md` | `8dbfe4db…` | `5c4e762e…` |
| `OUTSTANDING_ACTIONS_V2.md` | `d1ffd09f…` | `eca615ba…` |
| Guardian relationship source | `c619b8a3…` | `1010aeef…` |
| Pricing current V3 | `dd57248b…` | `b4577ae1…` |
| `zyra_wali_link_service.dart` | `23695c24…` | `1cf3f3a1…` |
| `seeker_wali_tab.dart` | `e9f30b91…` | `7fab87b7…` |
| `seeker_guardian_designs.dart` | `d96e9346…` | `378fd094…` |
| `guardian_detail_screen.dart` | `49a7d31c…` | `c8a751eb…` |
| `zyra_membership_catalog.dart` | `a0c89b1b…` | `fead0faf…` |
| `help_content.dart` | `09014197…` | `d3c8d634…` |
| `seeker_wali_tab_truth_test.dart` | `cdceb0d8…` | `532afa45…` |
| `guardian_one_page_designs_test.dart` | `dea64908…` | `cd0aeabb…` |
| `guardianship_manager_phase1_test.dart` | `8decbce5…` | `e4af927e…` |

## 7. Remaining gates

1. Founder visual review of the installed Guardian page.
2. Independent SQL/security review and fresh isolated replay/post-apply
   harness preparation.
3. Only after those pass: a separate Founder GO naming the exact staged file
   and SHA-256 above.
4. Production post-apply role matrix before Additional history is treated as
   live.

