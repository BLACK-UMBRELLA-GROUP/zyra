---
id: DOC-ZYRA-0289
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 7 - trace - for each rule of the planned app, the decision that set it (DR) and the code that does it (planned-app file, server function); rules with no decision of their own, and code that contradicts a decision
links: [OA-ZYRA-309, DOC-ZYRA-0278, DOC-ZYRA-0283, DOC-ZYRA-0287, DOC-ZYRA-0288, DR-ZYRA-274]
owner: Fable
---

# ZYRA BLUEPRINT — PART 7 — TRACE — V1 (DRAFT)

Status: **DRAFT for Shakeel.** Written 26 Oct 2026 by matching the rules in parts 2, 4 and 6 against the decisions register
(`SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md`, searched through its index) and the code. "Planned app" means the preview files in
`SOURCE/lib/dev/` (model: `zyra_view_request_draft_model.dart` = **M**, shell: `zyra_one_journey_concept_shell.dart` = **S**).
"Server" means database functions in `SOURCE/supabase/migrations/` (full list: DOC-ZYRA-0281). With this, all seven parts exist in draft; part 2 so far covers the Journey only (the other
features' rule pages are still to write).

## In one paragraph

Every rule now traces to a decision. **Nine planned-app rules had no decision of their own** — they came in with the
preview, because no decision was recorded between 10 and 25 Oct (lesson S13) — and were confirmed on 26 Oct as DR-ZYRA-280 (§2). **Three places where code contradicts a decision** are in §3; all are already tracked.

## 1. Rule → decision → code

### Journey (part 2)

| Rule | Decision | Planned app | Server |
|---|---|---|---|
| The planned app is the Founder preview; Pause and Save retired | DR-ZYRA-274 | whole preview | old Pause flow still present (OA-ZYRA-316) |
| Basic 1 place (after £4.99), ZYRA One 3 | DR-ZYRA-275, DR-ZYRA-252 | M `capacity`, `hasCapacity` | `zyra_active_journey_cap` (Basic 0 today) |
| Up to 5 pending requests; 7-day expiry; 48 h to get ready | DR-ZYRA-277 (also DR-ZYRA-241 §5 for 7 days) | not in the preview yet | missing |
| Both must tap ready before beginning | DR-ZYRA-277 | M `markReady`, `beginPreparedJourney` | missing |
| Accepting reserves both people's places | DR-ZYRA-280 | M `_accept`, `occupiedCount` | missing |
| Full ZYRA One member may end one Journey to accept a request | DR-ZYRA-280 | M `replaceJourneyForRequest`; S "End & accept request" | missing |
| Salam first, both send | DR-ZYRA-190, DR-ZYRA-198 | M `sendSalam`, `salamComplete` | `zyra_advance_stage` |
| Compatibility shown only after both reveal | DR-ZYRA-135, DR-ZYRA-211 | M `chooseCompatibilityReveal` | `zyra_reveal_journey_compatibility` |
| Journey Bio step after Compatibility | DR-ZYRA-280 | M `beginBioStep`, `completeBioStep` | missing |
| Guardian Gate needs both Main Guardians; no skipping | DR-ZYRA-202, DR-ZYRA-136 | M `_mainLeadershipPresent` | `zyra_advance_stage` (`wali_gate`) |
| Nothing moves while a Seeker lacks a Main Guardian; End still works | DR-ZYRA-236 | M `canParticipateInJourney` | trigger `zyra_enforce_main_guardian_journey_hold` (11 tables) |
| Real questions and a 48-hour Family Review after stages 4–7 | DR-ZYRA-110, DR-ZYRA-277 | not in the preview (demo "both continue") | `open_family_review`, `wali_review_decision`, `resolve_family_review_if_due` |
| End any time, free; reasons; safety reason hidden from the other side | DR-ZYRA-142 (never auto-ended), DR-ZYRA-268 | M `end`; S End confirmation | `end_journey`, `zyra_match_ending` |
| Ended Journeys read-only; history never overwritten | DR-ZYRA-268, DR-ZYRA-241 | M `_recordEndedAttempt` | `zyra_end_match_internal` |
| Ended archive readable for three months | DR-ZYRA-280 | S "Journey access lasts for three months" | missing |
| Request restart = a new Journey, the other accepts, 24 h wait | DR-ZYRA-241 §4, DR-ZYRA-277 | S `ended_restart` (not available yet) | `request_new_journey` (switched off, DR-ZYRA-227) |
| Identity check before any Journey | DR-ZYRA-221 | M/S gate in the app | **app only** (OA-ZYRA-315 a) |

### Seeing people and requests

| Rule | Decision | Planned app | Server |
|---|---|---|---|
| Journeys start from a **request**, not a mutual like | DR-ZYRA-280 | M `request`, `acceptReceived` | `create_match_on_mutual_like` (old model) |
| You see people only while you (and they) have a free place; ZYRA One can browse when full | DR-ZYRA-280 | M `discoverableProfiles`, `canBrowse` | missing |
| Hide, block, report from the browse menu | DR-ZYRA-095, DR-ZYRA-131 | M `hide`, `block`; S options menu | blocks built; hide missing |
| Introductions = people your Guardians put forward | DR-ZYRA-157, DR-ZYRA-160 (card system); DR-ZYRA-280 for the planned meaning | S `introductions` | `wali_suggestions`, `zyra_mark_suggestions_seen` (built) |

### Guardians

| Rule | Decision | Planned app | Server |
|---|---|---|---|
| Main Guardian always included and can chat (if paid) | DR-ZYRA-232 §1, DR-ZYRA-268 | M `sampleGuardianAccessFor` | `zyra_guardian_journey_permissions` |
| Seeker switches Additional Guardians' View / Chat per Journey | DR-ZYRA-232 §2 | M `setSampleGuardianJourneyAccess` | `zyra_set_guardian_journey_permission` |
| Guardian Basic has no Journey chat; chat needs a paid Guardian | DR-ZYRA-268, DR-ZYRA-243 | M `canUseSampleGuardianChat` | Circle participants need their own paid role (DR-ZYRA-248) |
| Agreed paid Additional Guardians stay on for a new Journey | DR-ZYRA-280 | M `hasRequiredPaidGuardianAccess`; S `guardian_access_agreement` | missing |
| Guardian links by permanent ZYRA Codes; two-sided requests | DR-ZYRA-226, DR-ZYRA-231 | S `scan`, `guardian_invite` | `zyra_request_guardian_link`, `zyra_accept_guardian_request` |
| A Guardian may "Speak to Guardian" of another family | DR-ZYRA-280 | S `network_request` | missing |

### Membership, payments and outside services (parts 4 and 6)

| Rule | Decision | Code |
|---|---|---|
| Seeker Basic and Guardian Basic £4.99 once; Seeker One £29.99 / month; Guardian One £19.99 / month | DR-ZYRA-252, DR-ZYRA-235 | `lib/data/zyra_membership_catalog.dart`; no purchase code (OA-ZYRA-317 7) |
| Compatibility Unlocks £2.99 / £6.99 / £9.99 | DR-ZYRA-250 | `zyra_membership_catalog.dart`; `profile_unlocks`, `unlock_credits` tables |
| ZYRA One bundles Seeker and Guardian access | DR-ZYRA-243 | `zyra_has_paid_role` |
| Identity check by Sumsub, mandatory | DR-ZYRA-220, DR-ZYRA-221 | `zyra_identity_verification_service.dart` (provider slot empty, switch off) |
| Phone push notifications; privacy-safe crash reporting | DR-ZYRA-278 | not built |
| One app; the Founder's internal build shows the preview | DR-ZYRA-229, DR-ZYRA-266, DR-ZYRA-274 | `services/zyra_session_router.dart`, `lib/config/zyra_internal_founder_policy.dart` |
| Keep Android; remove web and desktop projects | DR-ZYRA-279 | `SOURCE/android` etc. (clean-up) |
| Look and feel: Midnight Plum, Poppins, Syne wordmark, Classic Glass | Colour theme V2 (DOC-ZYRA-0102), DR-ZYRA-276 | `lib/theme/` |

## 2. Planned-app rules that had no decision of their own — CONFIRMED 26 Oct (DR-ZYRA-280)

These came in with the preview. The Founder confirmed all nine on 26 Oct 2026.

| # | Rule |
|---|---|
| 1 | Journeys start from a request the other person accepts — not from a mutual like |
| 2 | You only see people, and are only seen, while you have a free place; ZYRA One can browse when full |
| 3 | Accepting a request reserves a place for both people while they get ready |
| 4 | A full ZYRA One member may end one Journey to accept a new request |
| 5 | A Journey Bio step after Compatibility, revealed only when both choose |
| 6 | Ended Journeys stay readable for three months |
| 7 | Agreed paid Additional Guardians stay on for a new Journey and the Seeker cannot switch them off for it |
| 8 | Guardians can "Speak to Guardian" of another family's Seeker |
| 9 | Introductions are people your Guardians put forward |

## 3. Code that contradicts a decision

| # | Decision | Code | Tracked |
|---|---|---|---|
| 1 | DR-ZYRA-241 §5 and DR-ZYRA-277: requests expire after **7 days** | `request_new_journey` sets **30 days** | OA-ZYRA-317 |
| 2 | DR-ZYRA-221: identity verification mandatory, the app does not open until verified | The production switch is **off** (no provider yet) and the server never checks it before a Journey | OA-ZYRA-315 (a), OA-ZYRA-317 (8) |
| 3 | DR-ZYRA-275: Basic has 1 place | Server gives Basic **0** (24 Sep repository rule) | OA-ZYRA-317 (3) |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft (OA-ZYRA-309) |
| 2026-10-26 | V1 | The nine rules confirmed (DR-ZYRA-280) |
