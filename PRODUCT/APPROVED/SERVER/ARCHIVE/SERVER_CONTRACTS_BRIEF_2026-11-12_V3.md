---
id: DOC-ZYRA-0472
type: PLAN
status: SUPERSEDED
feature: PRODUCT BLUEPRINT
purpose: Codex server brief V3 - the server contracts Fable answered in QUESTIONS rows 91, 92, 94, 95 and 97-99 (Guardian place on invitations, compatibility topics, Seeker One filters, photo sources and removal); throw-away databases only
links: [AD-AIOS-115, AD-AIOS-142, OA-ZYRA-317, OA-ZYRA-302, DOC-ZYRA-0329]
owner: Fable
---

> **SUPERSEDED 12 Nov 2026 by `../BRIEFS/SERVER_CONTRACTS_BRIEF_2026-11-12_V4.md`. Do not build from this file.**

# SERVER BRIEF — CONTRACTS FROM QUESTIONS 91, 92, 94, 95, 97, 98, 99 — 12 NOV 2026 — V3

**Founder-named task.** ZYRA chat, 12 Nov: "Fable answers rows 91, 92, 94 and 95 so lines 84, 85 and 88 can move."
The exact contracts are the **Answer** cells of `PRODUCT/APPROVED/QUESTIONS.md` rows 91, 92, 94, 95, **97, 98, 99** - build exactly
those, no extra fields. **V2 (12 Nov, Codex blockers handed over mid-run, AD-AIOS-147):** row 97 replaces Q92's six scored topics with
**12 DR-ZYRA-250 areas returned as bands** (LOCK 27 V3); row 98 makes the Journey input `p_match_id`; row 99 replaces Q94 with the
new RPC `zyra_discover_profile_ids`. Where rows 92 / 94 and 97-99 differ, **97-99 win**. **V3 (12 Nov 10:15):** rows **100** (new strict scorer
`zyra_score_direction_v1`, `capture_version`, saved table `zyra_directional_results`, Journey adapter, D6) and **101** (`profile_hides` +
the two hide RPCs; home place in the private `seeker_home_places`, NOT `seeker_details`) win over 97 and 99 where they differ.
V1 and V2 are in `../ARCHIVE/`. Unclear → new `QUESTIONS.md` row and stop that part only.
**Throw-away databases only - no production change, no function deploy** (same rule as SERVER 0 and line 85; live after
SERVER 0 is live and the Founder's own words). No downloads, no tool installs (F33).
ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).

| Step | Detail |
|---|---|
| 1 | One migration per area, written to apply after SERVER 0 and line 85: `<ts>_q91_guardian_place_on_invite.sql`, `<ts>_q92_compatibility_topics.sql`, `<ts>_q94_seeker_one_filters.sql`, `<ts>_q95_photo_sources_and_removal.sql` |
| 2 | Q91: extend `preview_wali_invite` and `accept_wali_invite` as answered; link `place_kind` + invitation id; row lock on the Seeker's links during accept |
| 3a | Q100: `capture_version` on preference rows (existing = `v0`); `zyra_score_direction_v1` (service only, typed states `ok` / `incomplete` / `invalid` / `needs_reconfirmation`, no score unless `ok`); table `zyra_directional_results` + `zyra_save_direction_result`; Journey reveal adapter copies `overall` into `journey_compatibility`; `score_candidates` untouched |
| 3 | Q92 + Q97 + Q98 (bands only from an `ok` saved row): table `zyra_question_area` seeded from `chapter3Categories` (line 1243 list) + the chapter 2 attributes; `area_bands` jsonb written once beside each saved directional Overall (D5), area % never stored; `zyra_compatibility_topics(p_subject uuid, p_match_id uuid default null)` - security definer, `search_path = ''`, `authenticated` only, returns `overall`, `topics_locked`, 12 rows `(area_no, area_code, band)` in D3 order; locked = band null |
| 4 | Q99 + Q101 (replaces Q94): `profile_hides` + `zyra_set_profile_hidden` / `zyra_my_hidden_profile_ids` (excluded both ways); private table `seeker_home_places` (rounded to 2 decimals, owner-only RLS, no Guardian policy) + `zyra_set_my_home_place`; `seeker_details` untouched; new RPC `zyra_discover_profile_ids(...)` exactly as row 99 (ids only, `one_filters_applied`, `location_applied`, keyset paging ≤ 50, today's order, existing hide/block rules); Basic → Nationality / Ethnicity ignored |
| 5 | Q95: bucket `profile-photo-sources` + policies; `profile_photos` columns; `zyra_save_profile_photo`, `zyra_my_photo_sources`, `zyra_remove_profile_photo`; table `photo_object_deletions`; Edge Function `SOURCE/supabase/functions/zyra-photo-cleanup/` (service role, Deno, no npm packages); reset and account deletion queue every path |
| 6 | Tests on a throw-away database (`SOURCE/supabase/tests/q91_q92_q94_q95_assertions.sql`): Basic place free → Guardian Basic accepted; place used → refused `needs_guardian_one` unless paid; holder never returned; two accepts at once → one wins. Areas: map covers every scored item once and all 12 areas; band thresholds 75 / 50 / under 3 items; bands saved once and unchanged after answer edits or a restart (same pair, new attempt or match); no area % anywhere in results. Topics: Basic Seeker locked (no bands in the result), Unlock on that person opens, Unlock on someone else does not; Guardian One open, Guardian Basic locked even after the Seeker's Unlock; stranger gets nothing; archive over 3 months gets nothing. Scorer: missing light or answer → `incomplete`, no score; legacy `v0` amber → `needs_reconfirmation`; saved row written once and reused for Journey and Unlock+. Privacy: a linked Guardian and any other member cannot read `seeker_home_places`; hidden both ways never appear. Discovery: Basic lists ignored, One applied; near / country / worldwide; no home place → Worldwide only; never a count; paging stable. Photos: other members cannot read sources; stale revision refused; remove queues both paths; cleanup skips a path still referenced; reset / account deletion queue legacy and new paths |
| 7 | Contract note `PRODUCT/APPROVED/SERVER/RECORD/SERVER_CONTRACTS_2026-11-12.md`: names, inputs, returns, refusal codes (`needs_guardian_one`, `stale`), for the app lines |
| 8 | Gate: whole replay clean; step 6 all pass; `flutter analyze` unchanged (no app code here) |
| 9 | Task note; commit within core rule 2; mark this line BUILT, FAILED or QUESTION. **No live apply, no deploy** |

## Not in this line
Live apply · App Store purchases (OA-ZYRA-317 item 7) · the app lines (81 follow-up, 86-88 keep their preview data until the
planned app is connected area by area).
