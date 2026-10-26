---
id: DOC-ZYRA-0285
type: REPORT
status: CURRENT
feature: CODE HEALTH
purpose: Deep review of the planned ZYRA app (the Founder preview) against the old member app and the database - what it is, what is sample only, what the server lacks, and the clean-up list
links: [OA-ZYRA-316, OA-ZYRA-317, DR-ZYRA-274, DOC-ZYRA-0284]
owner: Fable
---

# ZYRA — PLANNED APP DEEP REVIEW — 26 OCT 2026

Read-only review by Fable from the code in `SOURCE/lib` (import map of all 342 files), the database migrations and the
handovers. Nothing was changed in the app. Step 2 of OA-ZYRA-316.

## 1. In five lines

1. **The planned app is a complete design running on sample people.** Every screen works, but it has no real data:
   the preview blocks all writes on purpose, and no member can open it.
2. **It reuses most of the app's building blocks** (theme, widgets, profile editing, settings, Guardian screens) and adds its own
   Browse, Introductions, Journey, My ZYRA, Guardian Circle and Profile pages (66 files, 37,830 lines including its helpers).
3. **The database does not yet support six things the plan relies on** (§4). Connecting the plan to real members is the
   biggest piece of work left, and it is server work as much as app work.
4. **Clean-up is large and safe to stage:** 22 files nothing uses (5,767 lines), 26 old-app-only files (19,280 lines) plus the
   old Journey screen, about 140 design alternatives kept after a choice was made, and tests bigger than the app itself.
5. **Pause and Save are gone from the plan; "Request restart" is not** — it is shown as a planned feature that is not
   available yet. DR-ZYRA-274 is corrected.

## 2. What the planned app is

| Area | What it does in the preview | Reuses from the old app |
|---|---|---|
| Start | The Founder signs in → launch screen → the preview, with sample Seeker or Guardian role | Splash, welcome, sign-in |
| Browse | One design ("Portrait card"): public details, then a swipeable photo gallery; filters (country, nationality, ethnicity); hide; report. **No Save** | Photo widgets, report sheet design |
| Introductions | Send and receive requests to begin a Journey; a red dot for unseen requests; decline or accept | — (new) |
| Places | Basic = **1** Journey place; ZYRA One = **3**. Pending requests do not take a place; an accepted request reserves a place for **both** people while they prepare | — (new) |
| Preparing | Both people must mark themselves **ready**; only then does the Journey begin, at Salam | — (new) |
| Journey | The same 8 stages as today (Salam → Compatibility → Guardian Gate → 3 phases → Family → Conversation), plus a **Journey Bio** step after Compatibility; each stage moves on when both choose Continue | Stage names, questions, Life Snapshot |
| Journey options | View profile, Timeline, Journey Bio, Compatibility score, Guardians, Report, **End**. **No Pause** | End confirmation design |
| Ended Journeys | Read-only archive (Bio, Compatibility, Guardians); **"Request restart"** page saying it is not available yet | — |
| Compatibility | Locked until both reveal; Unlocks catalogue: £2.99 for 1, £6.99 for 3, £9.99 for 5 | Score designs |
| Guardians | Main and other Guardians, invite, access agreement, per-Journey access, Guardian Circle discussion | Guardian screens, family messaging |
| My ZYRA | One-page dashboard: requests, current Journeys, ended history, Guardian info | Quiet dashboard |
| Profile and settings | Own profile preview, edit profile, photos, membership, personalisation, notifications, privacy, help, report, switch Seeker/Guardian account | Most profile and settings screens |
| Membership | Seeker or Guardian **Basic: £4.99 one-time joining fee**, no monthly fee; **ZYRA One monthly**; family places priced per place | Membership catalogue |

## 3. What is sample only

Everything in the preview is fictional: people, requests, Journeys, Guardians, payments. `ZyraInternalPreviewClient` latches
the network so a preview cannot write, and the model says so in its first line: *"Disposable request/transition UI, not a new
canonical server lifecycle."* Buttons such as "simulate peer ready" and "Demo: both agree" exist to walk through flows alone.

## 4. What the database does not support yet (OA-ZYRA-317)

| # | The plan needs | The database today |
|---|---|---|
| 1 | Introductions — a request to **begin** a Journey | Journeys start from a mutual like and one person's tap; `journey_requests` is only for returning after an ending, and is switched off |
| 2 | Preparing — both ready, places reserved | Nothing; a Journey becomes active in one step |
| 3 | Basic gets **1** place after a £4.99 joining fee | Basic gets **0** places (24 Sep "paid-only" migration) |
| 4 | Journey Bio step | No table or function |
| 5 | No Pause, no Save | Full Pause flow (functions, 10-paused cap, 13 lock triggers) and a `saves` table |
| 6 | Request restart after an ending | Built (`request_new_journey`) but switched off; it restarts at Compatibility |

Also from OA-ZYRA-315: the identity check and "both answered" are enforced only in the app, not the server.

## 5. The clean-up list

### Tier 1 — nothing uses these (22 files, 5,767 lines)

`guardian_detail_screen` (1,299), `notifications_screen` (723), `journey_experience_lab` (679), `wali_dashboard_preview` (453),
`dev_app_icon_directions` (333), `moderation_review_queue_screen` (311), `journey_map_screen` (262), `zyra_family_pricing_card` (245),
`zyra_journey_request_controller` (236), `dev_splash_lab` (207), `zyra_dev_app_icon` (194), `help_report_sheet` (169),
`zyra_journey_request` model (166), `glass_icon_button` (108), `anchored_card_overlay` (79), `onboarding_bank_contract` (62),
`zyra_paused_limit_refusal` (55), `fab_continue_button` (54), `compatibility_categories` (52), `zyra_journey_request_repository` (39),
`wali_notification_settings_screen` (27), `notification_bell` (14). Some still have tests; those go with them.

### Tier 2 — retired features

| Feature | Where it still lives |
|---|---|
| Pause | 40 old-app files; the preview's own model (pause states and buttons it never shows); server functions, caps and 13 triggers |
| Save | Old Browse and Connections ("Saved"); the preview model's `save`; the server `saves` table |
| Old restart stub | Server `restart_journey`, `suspend_journey`, `resume_journey`, `nudge_paused_journey` (refusal stubs) |

### Tier 3 — the old app, retired when the planned app is connected (26 files, 19,280 lines, plus the old Journey screen)

Largest: `connections_screen` (5,706), `browse_screen` (2,760), `wali_network_screen` (1,619), `wali_dashboard_screen` (1,491),
`report_profile_sheet` (944), `profile_screen` (796), `home_shell` (737), `zyra_dashboard_adapter` (715), `past_journeys_screen` (686).
`journey_flow_screen` (10,142) is still opened from the Guardian Circle, so it is unhooked first, then retired.

### Tier 4 — design alternatives kept after a choice was made (about 140 options in 17 sets)

**Decided 26 Oct, DR-ZYRA-276:** keep only the chosen design in each set; keep the 10 member backgrounds, and the fonts and
navigation styles in developer tools. (Corrected count: the Journey options menu is not a design set.)

| Set | Options | Chosen |
|---|---|---|
| Reading fonts | 18 | Poppins |
| Splash directions | 12 | the current splash |
| Background palettes | 12 | Midnight Plum (10 stay as member choices) |
| Onboarding gold designs / directions | 11 + 11 | one each |
| Journey icon designs | 11 | Couple |
| Browse swipe feedback | 11 | one |
| Menu designs | 9 | one |
| Navigation bar styles | 7 | Floating Glass |
| Role-choice, card, heading, bubble, pulse, network-card designs | 3–6 each | one each |

Each set is a Founder decision: keep a few as member choices (like backgrounds), or remove all but the chosen one.

### Tier 5 — tests

Test code is **207,814 lines in 464 files — more than the app** — with 3,984 screenshot images (467 MB). Tests for removed files,
retired features and unchosen designs go with them. 124 screenshot baselines are already stale (OA-ZYRA-310).

## 6. Mistakes found in this review

| # | What | Whose | Lesson |
|---|---|---|---|
| 1 | 22 files nothing uses were left in the app | Codex | L33 |
| 2 | Design alternatives were kept in the app after the Founder chose one | Codex | L34 |
| 3 | DR-ZYRA-274 called "restart" retired from one handover line; the preview actually shows "Request restart" as planned | Fable | F13 |

## 7. Order proposed

1. **Founder decisions — DONE 26 Oct:** Tier 4 by DR-ZYRA-276; Basic = 1 place after the £4.99 joining fee by DR-ZYRA-275.
2. **Codex, after the freeze, one tier at a time:** Tier 1 → Tier 2 (app side) → Tier 4 → matching tests. Each step
   updates the code-size tracker DOC-ZYRA-0284.
3. **Connect the plan (OA-ZYRA-317):** server work for §4, then connect the preview screens to real data one area at a time.
4. **Retire the old app (Tier 3)** once each area is connected; then remove the preview's sample-only parts.

## Method and limits

Files were grouped by following every `import` from the preview's own files and from the old home screens. A file reached
by both counts as shared, so the shared group (226 files, 108,189 lines) is an over-estimate: some of it is used only by the
old app through one link. Codex confirms each removal with the analyser and tests before it goes.
