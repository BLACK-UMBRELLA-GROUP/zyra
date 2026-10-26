---
id: DOC-ZYRA-0292
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 (Browse) - how Seekers find each other in the planned app - who appears and in what order, filters, the profile card and photos, requesting, hide, block and report, Find by ZYRA Code, browsing limits and revisits - each marked built, different or missing, with its decision
links: [OA-ZYRA-309, OA-ZYRA-317, OA-ZYRA-312, DOC-ZYRA-0283, DOC-ZYRA-0291, DR-ZYRA-280, DR-ZYRA-282]
owner: Fable
---

# ZYRA BLUEPRINT — PART 2 — BROWSE RULES — V1 (DRAFT)

Status: **DRAFT for Shakeel.** Written 26 Oct 2026 from the planned app (`_discover`, `_filters`, the Portrait card design, the
browse options menu), the old app's Browse services and the server (`zyra_browse_ranked_ids`, `score_candidates`, blocks).
Last column: **Built** · **Different** · **Missing**.


> **How to read the server column (added 26 Oct, after the live check DOC-ZYRA-0294):** "Built" here means **in the repository
> files**. Production is about two months behind. Not live today: per-Guardian View/Chat switches and agreed access
> (`zyra_set_guardian_journey_permission`), Family places, the Main-Guardian Journey hold, the Guardian Circle, read receipts,
> the verified trial, Browse ranking (`zyra_browse_ranked_ids`) and the 5 Oct security fixes. Everything else marked Built is live.

## In one paragraph

The **Profiles** tab shows one person at a time on a **Portrait card**: public details first, then a swipeable photo gallery.
Only Seekers of the opposite gender who are active, complete, not blocked and **with a free Journey place** appear — and only
while **you** have a free place (Seeker One can keep browsing when full). People are ordered **by compatibility** (the server
already ranks this way). You can filter by **age, distance, country of residence, nationality and ethnicity**. From a card you
**Request a Journey** (tap again to cancel), or open the options menu for **Compatibility** (using an Unlock), **Find by ZYRA
Code**, **Filters**, **Hide** and **Report / Block**. Seeker Basic sees **25 profiles every 4 hours**. There is no Save, Pass
or Consider any more.

## 1. Who appears

| Rule | Decision | Server |
|---|---|---|
| Opposite gender, Seeker role, active, profile complete, viewable, not blocked either way | DR-ZYRA-131, DR-ZYRA-123 | **Built** — `zyra_browse_ranked_ids`, `zyra_can_view_profile` |
| Not someone who shares a Guardian with you, nor your own Guardian | DR-ZYRA-123 | **Built** — `zyra_can_match` (checked when a request would start a Journey) |
| Only people with a free Journey place; only while you have one (One: also when full) | DR-ZYRA-280 §2, DR-ZYRA-282 | **Missing** |
| Not people you hid | DR-ZYRA-095 | **Missing** — the app calls `zyra_my_hidden_profile_ids` / `zyra_set_profile_hidden`, which no migration creates ("prepared, not deployed") |
| Not people who paused their profile ("Pause My Profile" in Settings) | — | **Missing** — the app calls `zyra_my_profile_pause_state` / `zyra_set_my_profile_pause`, which no migration creates |
| Not people you are already in a request or Journey with | DR-ZYRA-280 | **Missing** in the request form |
| A person you ended a Journey with can appear again, without reopening the old Journey | DR-ZYRA-268 | **Missing** in the request form |

## 2. Order

| Rule | Decision | Server |
|---|---|---|
| Highest compatibility first; ties keep the order they arrived in | DR-ZYRA-211, DR-ZYRA-250 | **Built** — `zyra_browse_ranked_ids` (uses the older scorer `score_candidates_legacy`) |
| Scoring follows the six approved Compatibility policies (twelve categories, strict answers) | DR-ZYRA-250 | **Different** — Browse still ranks with the legacy scorer |

## 3. Filters

| Filter | Planned app | Server |
|---|---|---|
| Age | "Any age (18+)" or a set range | **Missing** — not filtered on the server |
| Distance | "Any distance" or a range; needs the phone's location | **Missing** — no location stored or filtered |
| Country of residence, nationality, ethnicity | Pick from lists | **Missing** — not filtered on the server |

## 4. The card and photos

| Rule | Decision | Server |
|---|---|---|
| Portrait card: public details first, then photos you can swipe through; the one chosen design | DR-ZYRA-276 | — (app) |
| Photos come from the private photo store, never public links | — | **Built** — private `profile-photos` bucket, owner checks |
| Name shown as the first name and age · city | DR-ZYRA-162, DR-ZYRA-163 | — (app) |
| Profiles you have looked at are remembered on the phone (for the "new" cue) | — | app only |

## 5. Actions

| Action | Rule | Decision | Server |
|---|---|---|---|
| **Request a Journey** | Sends a request; tap again to cancel | DR-ZYRA-280, DR-ZYRA-277 | **Missing** |
| Compatibility | Shows this person's score using a Compatibility Unlock | DR-ZYRA-250, DR-ZYRA-135 | **Built** — `zyra_unlock_profile` |
| Find by ZYRA Code | Look someone up by code | DR-ZYRA-231 | **Built** — `zyra_preview_match_code`, `zyra_consider_match_code` |
| Hide | Removes them from your Browse and stops them sending you requests; they are not told | DR-ZYRA-095, DR-ZYRA-284 | **Missing** (see §1) |
| Report | Report a profile | DR-ZYRA-095 | **Built** — `profile_reports` |
| Block | Removes them everywhere, closes messages both ways, ends access | DR-ZYRA-131 | **Built** — `zyra_block_user`, `zyra_unblock_user` |
| ~~Save, Pass, Consider, Like~~ | Retired | DR-ZYRA-274, DR-ZYRA-280 | old tables `saves`, `passes`, `likes` remain — clean-up |

## 6. Limits

| Rule | Decision | Server |
|---|---|---|
| Seeker Basic: 25 profiles every 4 hours; Seeker One: unlimited | DR-ZYRA-282 | **Missing** — counted only on the phone today (`zyra_seeker_basic_usage_store.dart`: "not a security boundary") |
| Seeker One may revisit up to 10 declined profiles | DR-ZYRA-282 | **Missing** |
| Pending requests: Basic 3, Seeker One 25 | DR-ZYRA-283 | **Missing** |

## 7. Found while mapping

| # | Finding | Goes to |
|---|---|---|
| 1 | The app calls **5 database functions that no migration creates**: hide (`zyra_my_hidden_profile_ids`, `zyra_set_profile_hidden`), Pause My Profile (`zyra_my_profile_pause_state`, `zyra_set_my_profile_pause`) and the old `wali_has_wali_one`. The first four are marked "prepared, not deployed"; the last is a left-over in an old-app file | OA-ZYRA-317 (build them); OA-ZYRA-312 (are any live?); clean-up for the left-over |
| 2 | Browse ranks with the **legacy** compatibility scorer, not the six approved policies | OA-ZYRA-317 |
| 3 | The data inventory (part 3) did not list database **views** (e.g. `zyra_my_attempt_participation`) | **Fixed 26 Oct** — generator now lists views |

## 8. Questions

| # | Question |
|---|---|
| Q1 | Pending requests — **decided: Basic 3, Seeker One 25** (DR-ZYRA-283) |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft (OA-ZYRA-309) |
