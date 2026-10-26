---
id: DOC-ZYRA-0280
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 3 - ZYRA's data in plain words: every table and what it holds, how members' data is protected, the database functions, storage and server functions. Replaces the out-of-date schema document once approved
replaces: [ZYRA_DATABASE_SCHEMA V1 (after approval)]
links: [OA-ZYRA-309, DOC-ZYRA-0281, OA-ZYRA-312]
owner: Fable
---

# ZYRA BLUEPRINT — PART 3 — DATA — V1 (DRAFT)

Status: **DRAFT for Shakeel's review.** Written 25 Oct 2026 by replaying all 229 migrations in `SOURCE/supabase/migrations`
(18 Jul → 5 Oct 2026). No database was touched. The full detail — every column, link, security rule and function — is in the
generated inventory DOC-ZYRA-0281 (`PRODUCT/BLUEPRINT/ZYRA_DATA_INVENTORY_GENERATED.md`); re-generate it with
`SYSTEM/tools/blueprint/generate_data_inventory.py` after any migration.

## In one paragraph

ZYRA keeps its data in Supabase (Postgres): **63 tables**, **205 database functions**, **74 triggers**, one **private** photo bucket and **no server (edge) functions** in the repository. The app reaches almost everything through functions rather than reading tables directly: 194 of the 205 functions run with the database owner's rights and check the caller themselves, and 14 public tables have row-level security switched on with **no** direct-access rules at all — so the only way in is a function. 12 tables sit in a private schema the app cannot reach.

## Tables by area

### Members and profiles (6)

| Table | What it holds | Columns | Direct access from the app |
|---|---|---|---|
| `profiles` | Every member: role (seeker or guardian), name, date of birth, gender, location, bio, whether discoverable | 14 | 2 rule(s) |
| `seeker_details` | A seeker's background and faith details (special-category data under Article 9 — only shown to others through a paid unlock) | 11 | 4 rule(s) |
| `profile_photos` | A member's photos: where each is stored, which is main, display order | 6 | 4 rule(s) |
| `onboarding_answers` | A seeker's compatibility answers, preferences and must-haves from onboarding | 6 | 3 rule(s) |
| `zyra_onboarding_questions` | The server's copy of the onboarding question bank, used to decide when onboarding is complete | 4 | unknown — table made outside the migrations |
| `consents` | Every consent given or withdrawn — never edited, withdrawal is a new row | 6 | 2 rule(s) |

### Identity checks (4)

| Table | What it holds | Columns | Direct access from the app |
|---|---|---|---|
| `identity_verification_attempts` | Each identity check: provider, result, whether a duplicate needs review (private, server-only) | 14 | private schema — none |
| `identity_verification_event_receipts` | Receipts from the identity provider's callbacks, stored as hashes only | 4 | private schema — none |
| `verified_people` | One row per real verified person (a hash, not their details) — stops one person holding several accounts | 4 | private schema — none |
| `verified_person_accounts` | Which accounts belong to which verified person | 4 | private schema — none |

### Discovery (browsing profiles) (6)

| Table | What it holds | Columns | Direct access from the app |
|---|---|---|---|
| `likes` | Who liked whom | 4 | 3 rule(s) |
| `passes` | Who passed on whom | 4 | 3 rule(s) |
| `saves` | Who saved whom for later | 4 | 3 rule(s) |
| `profile_blocks` | Blocks — permanent safety boundaries between two members | 4 | 3 rule(s) |
| `profile_reports` | Reports about a profile; never shown to the person reported | 9 | 2 rule(s) |
| `protection_holds` | Safety bars between two people on a pair (who may not contact whom, until when) | 11 | none (functions only) |

### Matches and Journeys (14)

| Table | What it holds | Columns | Direct access from the app |
|---|---|---|---|
| `matches` | A pair of seekers: status, journey stage, pause and ending details | 22 | 2 rule(s) |
| `journey_attempts` | Each attempt at a Journey for a pair (a pair can try again after ending); only reachable through functions | 21 | none (functions only) |
| `journey_requests` | A pending request to start (or restart) a Journey — one per pair | 11 | 1 rule(s) |
| `journey_salams` | The first greeting each seeker sends | 3 | 2 rule(s) |
| `journey_stage_checkpoints` | Each seeker's move to the next Journey stage | 5 | 1 rule(s) |
| `journey_phase_answers` | Answers to each Journey phase's questions | 7 | 2 rule(s) |
| `journey_phase_ratings` | Ratings each seeker gives during a phase | 7 | 1 rule(s) |
| `journey_phase_checkpoints` | Each seeker's decision at the end of a phase | 5 | 2 rule(s) |
| `journey_compatibility` | The compatibility reveal for a pair: scores and categories each side sees | 8 | none (functions only) |
| `journey_milestone_attestations` | A proposed real-life milestone (meeting, nikah) waiting for the other seeker to confirm | 10 | none (functions only) |
| `timelines` | One timeline per match | 3 | 1 rule(s) |
| `timeline_milestones` | The milestones on that timeline | 5 | 1 rule(s) |
| `conversations` | The chat for a Journey | 5 | 2 rule(s) |
| `messages` | Chat messages in a Journey | 7 | 3 rule(s) |

### Guardians (12)

| Table | What it holds | Columns | Direct access from the app |
|---|---|---|---|
| `wali_links` | Guardian ↔ seeker relationships: status, main guardian, relationship | 10 | 2 rule(s) |
| `wali_invites` | Guardian invitations and requests between members | 21 | 2 rule(s) |
| `wali_suggestions` | A guardian suggesting a profile to their seeker | 8 | 3 rule(s) |
| `guardian_journey_permissions` | What each guardian may see or chat about in each Journey | 6 | none (functions only) |
| `guardian_journey_history_consents` | Whether a guardian may see past Journey summaries | 4 | none (functions only) |
| `journey_guardian_assignments` | Extra guardians given access to one Journey attempt, with who granted and revoked it | 8 | none (functions only) |
| `journey_family_answers` | Family questions and answers inside a Journey | 7 | 2 rule(s) |
| `journey_family_reviews` | A family review step opened before a Journey moves stage | 9 | 1 rule(s) |
| `journey_family_review_responses` | Each guardian's decision in that review (never shown to the seekers) | 4 | 1 rule(s) |
| `zyra_personal_codes` | Each member's permanent ZYRA Code, used to find a known person | 6 | private schema — none |
| `zyra_personal_code_attempts` | Code look-ups, for rate limiting | 4 | private schema — none |
| `zyra_retired_personal_code_hashes` | Old codes (as hashes) so they are never reused | 2 | private schema — none |

### Guardian circle messaging (6)

| Table | What it holds | Columns | Direct access from the app |
|---|---|---|---|
| `family_message_threads` | One shared Guardian Circle chat per seeker | 4 | 1 rule(s) |
| `family_messages` | Messages in that circle | 7 | 1 rule(s) |
| `family_message_memberships` | Who is in the circle and from when they can read | 7 | none (functions only) |
| `family_message_participant_state` | Each member's read, mute and archive state | 5 | 1 rule(s) |
| `family_message_reports` | Reports about circle messages | 9 | none (functions only) |
| `family_message_report_evidence` | Protected copy of a reported message for moderation | 13 | none (functions only) |

### Membership and money (11)

| Table | What it holds | Columns | Direct access from the app |
|---|---|---|---|
| `subscriptions` | A member's plan: type, status, billing period, dates | 11 | 1 rule(s) |
| `family_subscriptions` | A ZYRA Family plan: owner, seats for seekers and guardians, billing | 12 | none (functions only) |
| `family_seat_assignments` | Who holds each seat on a Family plan | 7 | none (functions only) |
| `family_membership_invitations` | Invitations to join a Family plan | 9 | none (functions only) |
| `family_ownership_transfers` | Handing a Family plan to a new owner | 11 | none (functions only) |
| `seeker_trial_ledger` | Free-trial use per verified person (private) | 7 | private schema — none |
| `profile_unlocks` | Compatibility unlocks a member has bought or used | 5 | 1 rule(s) |
| `unlock_credits` | Each member's unlock credit ledger | 8 | 1 rule(s) |
| `zyra_unlock_operations` | Receipts for each unlock spend (private) | 7 | private schema — none |
| `zyra_unlock_account_guards` | Stops two unlock spends running at once (private) | 2 | private schema — none |
| `zyra_unlock_release_gate` | One switch: whether paid unlock spending is on (private) | 2 | private schema — none |

### Notifications, feedback and product data (4)

| Table | What it holds | Columns | Direct access from the app |
|---|---|---|---|
| `notifications` | In-app notifications | 8 | 2 rule(s) |
| `notification_preferences` | Each member's notification choices (a log, never edited) | 6 | 1 rule(s) |
| `app_feedback` | Ideas and problem reports sent from Settings | 8 | 1 rule(s) |
| `zyra_product_events` | Anonymous product usage counts (private; collection is off) | 9 | private schema — none |

## Triggers (automatic rules) — 74

Corrected 25 Oct: the first draft said 18; the generator missed "constraint" triggers, triggers made in a loop, and triggers
dropped and re-created in the same file (lesson F11). The groups that matter most:

| What they do | Count | Rule they enforce |
|---|---|---|
| Pause lock (`zyra_reject_locked_journey_write`, locked progress) | 13 | Nothing in a paused Journey can be written or advanced, on every Journey table and messages |
| Main Guardian hold (`zyra_enforce_main_guardian_journey_hold`) | 11 | Ordinary Journey writes and messages are refused unless both Seekers have an active Main Guardian; Pause and End still work |
| Link to the current attempt (`zyra_set_attempt_from_match`) | 10 | New Journey rows are tied to the current attempt automatically |
| Active Journey limit (`zyra_enforce_one_active_match`, `_attempt`) | 2 | No one goes over their plan's Active Journey limit |
| Mutual like makes a match (`create_match_on_mutual_like`) | 1 | Two likes in both directions create a match |
| Like / save / pass exclusive | 3 | One state per profile: a like removes a save or pass, and so on |
| Family plan seats, ownership, trials | 7 | Seat capacity, verified seats, owner-only changes |
| Others | 27 | Timestamps, onboarding-complete flag, milestones, notifications, photo and unlock owner checks, personal codes, family messaging lifecycle |

The full list is in DOC-ZYRA-0281.

## Storage and server functions

| Item | Detail |
|---|---|
| `profile-photos` bucket | Created public on 18 Jul, made **private** on 19 Jul. Photos are served through signed links |
| Server (edge) functions | None in `SOURCE/supabase/functions` |

## Database functions (what the app calls)

205 functions. Grouped by name (a rough sort — a few could sit in two areas); every one is listed with its inputs, who may run it and the tables it touches in DOC-ZYRA-0281. "Who may run it" there comes from plain grant lines only; grants made in loops and sweeps are not followed, so the live database is the reliable answer.

| Area | Functions |
|---|---|
| Developer test helpers | 13 |
| Guardian circle messaging and Family plans | 32 |
| Journeys (stages, phases, requests, attempts, reveal, milestones) | 64 |
| Guardians, codes and permissions | 33 |
| Unlocks, membership and payments | 10 |
| Safety (blocks, reports, holds) | 5 |
| Profiles, photos, onboarding, identity, consent | 32 |
| Notifications, feedback, product data | 9 |
| Shared helpers (ages, scoring, timestamps, checks) | 7 |

## Found while mapping

1. **The schema document is badly out of date.** `ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1` (DOC-ZYRA-0074) names only 13 of the 63 tables — the Journey, Guardian, Family, identity and unlock tables are all missing. ZYRA's map now routes to this blueprint instead; once Shakeel approves this part, the old document is marked superseded.
2. **13 developer test functions are in the migrations** and, per their grant lines, any signed-in member may call them (whether the live database matches is checked under OA-ZYRA-312): `zyra_debug_grant_credits`, `zyra_dev_counterpart_complete`, `zyra_dev_guardians_on_decided`, `zyra_dev_reset_account`, `zyra_dev_rewind_journey`, `zyra_dev_seed_journey`, `zyra_dev_set_compatibility`, `zyra_dev_set_counterpart_reveal`, `zyra_dev_set_guardian_suggestions`, `zyra_dev_set_guardians_on_decided`, `zyra_dev_set_journey_stage`, `zyra_dev_set_plus_unlock`, `zyra_dev_set_seeker_plan`. Each one refuses unless the caller's email ends in `@zyra.test`. That is safe only while nobody can create an account with such an email. Raised as **OA-ZYRA-312** (check the sign-up settings; consider moving them out of production) — nothing changed now.
3. **One table was created outside the migrations:** `zyra_onboarding_questions` (first made by hand as `zyra_seed_ch4_questions`, renamed in a migration on 11 Aug). Its security settings cannot be read from the repository; part of OA-ZYRA-312.

## Limits of this part

- Read from the migration files, not the live database. Anything applied by hand, or built with dynamic SQL, is not seen. Checking the live database needs Shakeel's GO.
- Function bodies are summarised by the tables they touch, not explained line by line; part 2 (rules per feature) explains behaviour.

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-25 | V1 | First draft from the migrations (OA-ZYRA-309) |
| 2026-10-25 | V1 | Trigger count corrected 18 → 74 and a trigger section added (generator fix, lesson F11) |
