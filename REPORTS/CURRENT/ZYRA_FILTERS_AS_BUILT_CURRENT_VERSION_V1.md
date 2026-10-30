---
id: ASBUILT-ZYRA-QUEUE37
type: HANDOVER
status: CURRENT
feature: FILTERS
purpose: Current implementation and evidence limits for queue 37, LOCK10 V4 sample Filters
links: [AD-AIOS-115, OA-ZYRA-316, OA-ZYRA-317, OA-ZYRA-321, OA-ZYRA-323]
owner: Codex
---

# Filters — queue 37, LOCK10 V4

Implementation and scoped checks are ready for review on 30 October 2026. **The brief's required real-keyboard proof is pending** under OA-ZYRA-323; queue 37 remains WAITING until the parent resolves that evidence decision. This document does not claim Fable verification, Founder acceptance or member delivery.

Built from `PRODUCT/APPROVED/FILTERS/BRIEFS/BUILD_BRIEF_2026-10-30_V4.md`, `FILTERS/RECORD/FILTERS_SPEC_CURRENT_VERSION_V4.md`, `FILTERS/RECORD/LOCK_RECORD.md`, all ten `FILTERS/MASTERS/f01–f10` pictures, and `LOCATION/RECORD/LOCATION_SPEC_CURRENT_VERSION_V2.md`, its LOCK record and all four Location masters. These are the live V4/V2 files on disk; withdrawn rows 25/31/36 were not retried. Founder: “after everythign is changed lock in filter page for codex”. No design or reference-list change was invented.

## Behavior and files

| Live file under SOURCE | Responsibility |
|---|---|
| `lib/dev/zyra_one_journey_filters_presentation.dart` | Four bounded cards: Age, Where, Nationality and Ethnicity; non-looping blank-card swipe and arrow equivalents; disabled end arrows; Clear (n), preferences link and shared Profiles pill. Search, selected chips, system-keyboard response and responsive control wrapping. Card-local epochs and captured shell guards revoke retained callbacks; control drags never become page swipes. |
| `lib/dev/zyra_browse_filter.dart` | Pure sample-only model. OR within each public-code set, AND across selected kinds; exclusive Near me/Country/Worldwide. Haversine uses the existing rounded real sample-city coordinates; unknown/invalid active criteria fail closed. No device, permission or transport. |
| `lib/dev/zyra_one_journey_concept_shell.dart` | Keeps draft versus applied filters, existing Apply/Back behavior, eligibility exclusions, Browse history and reset. Owns the guarded full-country picker and local origin-sheet attachment seam. Preferences open the member's detached traffic-light editor repository. |
| `lib/dev/zyra_preview_navigation_checkpoint.dart` | Defensively detaches the new code sets when snapshotting. Text/search/focus/card controllers are not persisted. |
| `lib/widgets/zyra_profiles_components.dart`, `lib/widgets/zyra_browse_designs.dart` | Default-preserving reuse of the LOCK7 pill and Profiles marks. Profiles retains its original arrow keys/labels, middle text treatment and 20×5/5 dots. Filters supplies its own arrow labels/keys and gold action text, 30×6/6 marks. |
| `lib/screens/profile/compatibility_editors.dart` | Optional preview-only return callback allows the standalone preferences entry to Save/Back through the shell. Existing ordinary and hub-pushed editors still use their original Navigator return. |

Age starts at Any age (18+) and includes adults older than 70. Only an explicitly set range caps at 70. Near me uses the indexed steps 5, 10, 15, 25, 50, 75, 100, 150, 200, 300 and 500 km; 50 km is index 4 of 10. Country defaults to the existing United Kingdom sample residence. Country and Worldwide contribute zero to Clear. Age range, Near me, any nationality set and any ethnicity set each contribute one. Clear restores the default Country/Any state.

Search retains all 197 country-backed nationality codes (196 distinct demonyms), including both Dominican codes. Only the Filters list disambiguates them as Dominican (Dominica) and Dominican (Dominican Republic); existing public profile labels keep their prior behavior. Ethnicity uses all 28 allowed entries after excluding Prefer not to say. Search is case-insensitive substring matching, excludes selected codes, returns at most eight, and uses the locked Popular order when empty. Adding clears the query; chips remove individually. There are no member counts, City criterion, compatibility score filter, membership filter or private-answer filter.

## Boundary and remaining work

This is the existing protected Founder preview on fictional sample people. Ordinary member sign-in, Guardian tabs, Code page, tab geometry, Browse/request motion and exclusion guards are retained. No dependencies, backend calls, migrations, production data, live location or permission request were added. Filters do not read private compatibility answers; the separate preferences editor writes only to `_accountSession.compatibility`, with local owner/lifetime guards.

Queue 26 owns real current-area explanation, permission, acquisition and the resulting origin. Queue 37's Change action exposes the locked choose-sheet wording and home-town origin; current-area text is present as a future choice and performs no device operation. Its Done callback validates the sheet's own route and the opening Filters epoch. **Written scope refusal:** do not fabricate an area, interpret an absent location result as consent/refusal, request permission, or complete queue 26 inside this task. OA-ZYRA-321/317 continue to own location/server launch work.

The protected native route remains held under OA-ZYRA-323. The Task12 installer exception expired. Shakeel then approved “Allow one PROFILE install and capture (Recommended)” for this queue37 update only, including incidental Flutter/Xcode Git calls, with the existing Apple sandbox, signing and identity unchanged and a stop on failure/drift. The parent owns Device Hub capture after the primary installs and normally cold-launches the app. The one-time installer is authorised but has not run at this commit; no upload, publication or simulator is authorised. Required remaining proof is f07 (`alg`) and f10 (`xyzq`) with the actual iPhone system keyboard at 1290×2796. Proposed minimal route sent to the parent: Founder-operated existing PROFILE `./run.sh` and normal cold launch, followed by the two device screenshots, or a fresh exact one-time installer exception. This fresh human approval does not repair the held native route or authorise a later install. Required keyboard evidence remains pending.

## Checks and evidence

- Full-source protected `flutter analyze --no-pub`: no issues, 5.0 seconds. Driver check: Flutter 3.44.2, five pins, direct and inherited Git-exec denial PASS.
- 38 passing tests across `visual/lock10_filters_capture_test.dart`, `filters_lock10_accessibility_test.dart`, `zyra_browse_filter_test.dart`, `preview_navigation_checkpoint_test.dart` and `request_row_lock7_test.dart`.
- Nine passing focused regressions in `view_request_draft_widget_test.dart`, `browse_next_motion_shell_test.dart`, `browse_screen_invitation_frame_test.dart`, `one_journey_pull_down_routes_test.dart`, selected by `public.*heritage|filter|Filter|Browse Back respects`. City/single-picker setup was migrated to locked controls; domain, motion, offline, stale-callback and history assertions remain.
- 39 passing focused retained-editor/resume checks in `retained_profile_editor_reuse_test.dart` and `one_journey_resume_checkpoint_test.dart`, selected by `traffic lights|generation change during save|foreign cover during save|revoked|fresh|stale|ABA`.
- Final ten-test rerun of the capture interactions and pure model also passed after adding disposed-TextField callback checks and keeping Dominican disambiguation local to Filters. Counts overlap the 86 distinct scoped cases above. There is no unfiltered whole-suite pass claim; prior OA-ZYRA-316 legacy failures remain recorded in Tasks14–16.
- The 320-point, 200% text check wraps controls and scale labels, scrolls card content, checks accessible card/chip/slider labels and haptics. Blank-card swipes move; drags on sliders, segments, chips and search fields stay with controls. Retained chip, field and slider callbacks cannot write across page/session/disposal changes. Preferences Save returns to Filters; origin Done closes its own sheet.

`PRODUCT/APPROVED/FILTERS/BUILT/` holds eight normal captures, two explicitly named `__headless_layout` captures and `master_beside_build.png`. All source captures are 1290×2796, 430×932 @3x, actual local shell and bundled app fonts. The normal card is exactly (21,147,388,648), bottom pill (21,845,388,56); keyboard-inset layout ends the card at y669 and hides the preferences link and pill. f09/f10 preserve the nationality choices from f08, explaining Clear (1).

Comparison is structural, not pixel equality: master card/pill bounds and chip arrangement agree; the actual app's glyph/font rasterisation and minor inner spacing differ from the prototype. The renderer has rectangular screen corners. f07/f10 have blank keyboard regions deliberately; no keyboard was painted or represented as native proof. `REPORTS/EVIDENCE/LOCK10_FILTERS_2026-10-30/` holds JSON hashes/comparison, capture records and text BUILD.json only. No compiled app or source copy is stored there.

`REPORTS/CURRENT/ZYRA_CODE_SIZE_TRACKER_CURRENT_VERSION_V1.md` (DOC-ZYRA-0284) records the measured queue37 row: 165,819 app lines / 326 files; 46,347 developer-preview / 85; 27,228 Founder-preview / 35; 212,384 test / 490; goldens unchanged at 2,612 / 307 MB; old-app Pause 39 / Restart 1. Nothing in Tier3 or the old member app was retired.

No PRODUCT/BLUEPRINT file was edited, as explicitly required by this task. **Written scope refusal:** the generated planned-screen inventory was not regenerated because its output is inside that protected folder; Fable owns reconciling that inventory and the older Browse blueprint wording with LOCK10 V4. This handover is the current implementation trace until then. The document MAP is regenerated for this new handover; unrelated designer/admin edits remain outside the task commit.

## Next owner

Parent: verify code/evidence and resolve the two required native captures with Shakeel before any BUILT/FAILED disposition. Fable: independent handover/blueprint verification and action maintenance. Founder: final acceptance. Queue26, server work and later queue rows remain outside this task.
