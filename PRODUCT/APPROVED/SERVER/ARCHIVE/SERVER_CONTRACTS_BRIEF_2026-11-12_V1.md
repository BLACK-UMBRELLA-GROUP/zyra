---
id: DOC-ZYRA-0472
type: PLAN
status: SUPERSEDED
feature: PRODUCT BLUEPRINT
purpose: Codex server brief - the four server contracts Fable answered in QUESTIONS rows 91, 92, 94, 95 (Guardian place on invitations, compatibility topics, Seeker One filters, photo sources and removal); throw-away databases only
links: [AD-AIOS-115, AD-AIOS-142, OA-ZYRA-317, OA-ZYRA-302, DOC-ZYRA-0329]
owner: Fable
---

> **SUPERSEDED 12 Nov 2026 by `../BRIEFS/SERVER_CONTRACTS_BRIEF_2026-11-12_V2.md`. Do not build from this file.**

# SERVER BRIEF — CONTRACTS FROM QUESTIONS 91, 92, 94, 95 — 12 NOV 2026

**Founder-named task.** ZYRA chat, 12 Nov: "Fable answers rows 91, 92, 94 and 95 so lines 84, 85 and 88 can move."
The exact contracts are the **Answer** cells of `PRODUCT/APPROVED/QUESTIONS.md` rows 91, 92, 94, 95 - build exactly those,
no extra fields. Unclear → new `QUESTIONS.md` row and stop that part only.
**Throw-away databases only - no production change, no function deploy** (same rule as SERVER 0 and line 85; live after
SERVER 0 is live and the Founder's own words). No downloads, no tool installs (F33).
ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).

| Step | Detail |
|---|---|
| 1 | One migration per area, written to apply after SERVER 0 and line 85: `<ts>_q91_guardian_place_on_invite.sql`, `<ts>_q92_compatibility_topics.sql`, `<ts>_q94_seeker_one_filters.sql`, `<ts>_q95_photo_sources_and_removal.sql` |
| 2 | Q91: extend `preview_wali_invite` and `accept_wali_invite` as answered; link `place_kind` + invitation id; row lock on the Seeker's links during accept |
| 3 | Q92: `zyra_compatibility_topics(p_subject, p_journey)` - security definer, `search_path = ''`, `authenticated` only; locked = names without scores |
| 4 | Q94: discovery request gains the two lists; Basic → ignored, `one_filters_applied = false` |
| 5 | Q95: bucket `profile-photo-sources` + policies; `profile_photos` columns; `zyra_save_profile_photo`, `zyra_my_photo_sources`, `zyra_remove_profile_photo`; table `photo_object_deletions`; Edge Function `SOURCE/supabase/functions/zyra-photo-cleanup/` (service role, Deno, no npm packages); reset and account deletion queue every path |
| 6 | Tests on a throw-away database (`SOURCE/supabase/tests/q91_q92_q94_q95_assertions.sql`): Basic place free → Guardian Basic accepted; place used → refused `needs_guardian_one` unless paid; holder never returned; two accepts at once → one wins. Topics: Basic Seeker locked (no scores in the result), Unlock on that person opens, Unlock on someone else does not; Guardian One open, Guardian Basic locked even after the Seeker's Unlock; stranger gets nothing; archive over 3 months gets nothing. Filters: Basic lists ignored, One applied, downgrade keeps saved choices. Photos: other members cannot read sources; stale revision refused; remove queues both paths; cleanup skips a path still referenced; reset / account deletion queue legacy and new paths |
| 7 | Contract note `PRODUCT/APPROVED/SERVER/RECORD/SERVER_CONTRACTS_2026-11-12.md`: names, inputs, returns, refusal codes (`needs_guardian_one`, `stale`), for the app lines |
| 8 | Gate: whole replay clean; step 6 all pass; `flutter analyze` unchanged (no app code here) |
| 9 | Task note; commit within core rule 2; mark this line BUILT, FAILED or QUESTION. **No live apply, no deploy** |

## Not in this line
Live apply · App Store purchases (OA-ZYRA-317 item 7) · the app lines (81 follow-up, 86-88 keep their preview data until the
planned app is connected area by area).
