---
id: DOC-ZYRA-0304
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - remove the unused "Original photos" Profiles layout (DR-ZYRA-276 consequence) and capture the missing Details-first photo pages for the baseline
links: [DR-ZYRA-276, OA-ZYRA-316]
owner: ZYRA chat
---

# PROFILES PHOTOS — CLEAN-UP AND CAPTURE BRIEF — 29 OCT 2026

**Founder, 29 Oct 2026:** "since users first picture is a name card the photos dont need info in them now in latest app its
like that ... ensure its all correct and codex gives u right screenshot". The Profiles card is **Details first**: page 1 is
the name card; photo pages show only the photo. Blueprint Browse rules §4 updated the same day.

| Step | Detail |
|---|---|
| 1 | Remove the unchosen **"Original photos"** gallery mode (DR-ZYRA-276: only the chosen design stays): `ZyraBrowseGalleryMode.originalPhotos`, the `identityOnPhoto` overlay path in `widgets/zyra_browse_designs.dart`, the developer "Profile cards" picker (`_browseGalleryModePicker`, shell ≈ line 7540) and the saved-checkpoint field if it then has one value. Details first becomes the only behaviour. Photo pages must look exactly as today in Details first (no scrim, no name). Remove its tests and screenshots; analyser and tests pass |
| 2 | Baseline: move `profiles_tab__gallery_originalPhotos.png` and `controls__browse_originalPhotos.png` (and the `controls__browse_detailsFirst.png` picker picture if the picker is gone) to `~/_to_delete/`, and drop their INDEX rows |
| 3 | Capture the missing states with the same route as BUILD.json: `profiles_tab__photo_1.png` and `profiles_tab__photo_2.png` (Details first, first and second photo page, dots showing the right page). Add INDEX rows and a BUILD.json note |
| 3b | Also capture `profiles_tab__options_open.png`: Profiles with ••• tapped (the tab bar shows the five action icons, **icons only, no text** — Founder 29 Oct: "in the app theres no text under the icons"). The baseline had no picture of this state |
| 3c | Also capture the states the baseline missed (Founder 29 Oct: "ensure you have every correct from app not just this but whole app"): `compatibility__revealed.png` (Profiles ••• → Compatibility score → Unlock compatibility, with 1 unlock), `report__reason_selected.png` (a profile → Report, one reason chosen), `profile__options_open.png` (full profile ••• open). Name and index them like the rest |
| 4 | Check any other baseline picture that shows a name or details on top of a profile photo outside the Profiles card (full profile, Journey card) and list them in the task note — do not change those screens |
| 5 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED. Code-size table |

Do not change any other design, wording or screen.
