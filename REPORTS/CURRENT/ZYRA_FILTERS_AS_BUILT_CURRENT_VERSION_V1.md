---
id: ASBUILT-ZYRA-QUEUE37
type: HANDOVER
status: CURRENT
feature: FILTERS
purpose: Final implementation and evidence provenance for queue 37, LOCK10 V6 sample Filters
links: [AD-AIOS-115, OA-ZYRA-316, OA-ZYRA-317, OA-ZYRA-321, OA-ZYRA-323]
owner: Codex
---

# Filters — queue 37, LOCK10 V6

Queue 37 is BUILT on 30 October 2026. Final tested source is committed and pushed as `9a8f3a8894341eb03b351003778e5ea3c650edf1` (V6 title/spacing/live pack: `b44873338840cebd3f6448e58fbeffd2593b4482`); initial V4 implementation is `aab497389c7a85ca8d5ad5934a9fe6a288082186`. The two real-keyboard captures came from that installed V4 commit. V6 changes only Age/Location presentation and its tests; the heritage controls, search and shared viewport rendering region remains byte-identical. **A native V6 binary is not claimed.** Parent verification, Fable review and Founder acceptance remain separate from this implementation disposition.

Built from `PRODUCT/APPROVED/FILTERS/BRIEFS/BUILD_BRIEF_2026-10-30_V4.md` (the existing filename now directs V6), `FILTERS/RECORD/FILTERS_SPEC_CURRENT_VERSION_V6.md`, `FILTERS/RECORD/LOCK_RECORD.md`, all ten current `FILTERS/MASTERS/f01–f10`, and `LOCATION/RECORD/LOCATION_SPEC_CURRENT_VERSION_V2.md`, its LOCK record and all four live Location masters. Withdrawn rows 25/31/36 were not retried. Founder: “after everythign is changed lock in filter page for codex”; V5: “the slider in real app is way to close to the 2 pills above it fix that please”; V6: “lets change this to location”. Current V6 pack and updated referenced Location pictures were re-read/viewed before the narrow change. No design was invented.

## Behavior and files

| Live file under SOURCE | Responsibility |
|---|---|
| `lib/dev/zyra_one_journey_filters_presentation.dart` | Age, Location, Nationality and Ethnicity cards. Bounded blank-card swipe and arrow equivalents, disabled end arrows, Clear (n), preferences and shared Profiles pill. Search/chips, system-keyboard response and Larger Text wrapping. Captured page/shell guards revoke retained callbacks; control drags never become page swipes. V6 adds the Location title/semantics and 26/22/18 pt gaps. |
| `lib/dev/zyra_browse_filter.dart` | Pure sample model. OR within each public-code set, AND across criteria; exclusive Near me/Country/Worldwide. Haversine uses existing rounded real sample-city coordinates; invalid active criteria fail closed. No device, permission or transport. |
| `lib/dev/zyra_one_journey_concept_shell.dart` | Draft/applied state, Apply/Back, eligibility exclusions, Browse history/reset, guarded full-country picker and home-town origin-sheet seam. Preferences use the member's detached local compatibility repository. |
| `lib/dev/zyra_preview_navigation_checkpoint.dart` | Defensively detaches sets. Search/focus/card controllers are not persisted. |
| `lib/widgets/zyra_profiles_components.dart`, `lib/widgets/zyra_browse_designs.dart` | Reuse of LOCK7 pill and Profiles marks with default behavior retained. Profiles keeps its original keys/labels, middle text and 20×5/5 dots. Filters supplies arrow labels/keys, gold action and 30×6/6 marks. |
| `lib/screens/profile/compatibility_editors.dart` | Optional preview-only return callback lets standalone preferences Save/Back through the shell. Ordinary and hub-pushed editors keep their existing Navigator return. |

Age defaults to Any age (18+) and includes adults older than 70; only an explicit range caps at 70. There are 26 pt after Age segments before the range slider. Location has 22 pt after segments and 18 pt after the Near me origin before its slider. Near me steps are 5, 10, 15, 25, 50, 75, 100, 150, 200, 300 and 500 km; default 50 km is index 4 of 10. Country defaults to United Kingdom. Country/Worldwide count zero; Age range, Near me, any nationality set and any ethnicity set each count one. Clear restores Country/Any.

Search retains 197 country-backed nationality codes (196 distinct demonyms). Only Filters disambiguates Dominican (Dominica) and Dominican (Dominican Republic); other public labels retain prior behavior. Ethnicity has 28 allowed entries after excluding Prefer not to say. Case-insensitive substring search excludes chosen codes, returns at most eight and uses locked Popular order when empty. Adding clears the query; chips remove individually. No member counts, City, compatibility-score, membership or private-answer filter was added.

## Scope and native provenance

This is the protected Founder preview on fictional sample people. Ordinary member sign-in, Guardian tabs, Code page, tab geometry, Browse/request motion and exclusion guards remain. No dependency, backend, migration, production data, live location or permission change. Filters do not read private compatibility answers; the separate preferences editor writes only to `_accountSession.compatibility` under local lifetime guards.

Queue 26 owns real current-area explanation, permission and acquisition. Queue 37 attaches locked choose-sheet wording and home-town origin; current-area text is an inert future seam. Done validates the sheet route and opening Filters epoch. **Written scope refusal:** do not invent an area, interpret absent results as consent/refusal, request permission or complete queue 26 here. OA-ZYRA-321/317 retain location/server ownership.

The protected native route remains held under OA-ZYRA-323. The Task 12 installer exception expired. Shakeel separately approved “Allow one PROFILE install and capture (Recommended)” for this queue 37 update, including incidental Flutter/Xcode Git, existing Apple sandbox/signing/identity and stop on failure/drift. The existing `./run.sh` ran once in PROFILE; Xcode build completed in 88.2 s. Deep strict signature verification passed for `app.zyraconnect.zyra`, version `1.0.0+5`, team `9Y7Z8F36SJ`, Xcode `27.1 (27A9275)`. The still-attaching launcher was stopped, exited 0 and left no SDK/LLDB process. A normal foreground cold launch succeeded with no debugger or console attached. No second install, upload or publication occurred. This consumed exception does not authorise a later install or repair the held native route.

Parent captured raw 1290×2796 PNGs through Xcode Device Hub Screenshot with View Screen active and Capture Keyboard off. Primary and parent both viewed them; dimensions, sizes and SHA256 agree:

| State | Native content | Capture time | Raw SHA256 |
|---|---|---|---|
| f07 | Nationality, `alg`, Add Algerian, Clear, actual iOS keyboard; footer hidden | 18:19:56 | `cbc523af2fc6cc320028495493225f8db847c722b0c17ab9e7d3cbf2fafb0fb3` |
| f10 | Ethnicity, `xyzq`, `No ethnicity called “xyzq”.`, Clear (1), retained Algerian/British fixture; actual keyboard, footer hidden | 18:25:29 | `7096626aa55f22dc0819ee309981bffb61af4a31b5253daef5d9e9a71527870a` |

Source stayed immutable at `aab4973` through both captures. Final V6 work began only after f10 delivery. `v6_scope_provenance.json` records identical hashes for the presenter from `_chip` through the end: heritage controls/search and shared viewport rendering. Added segment keys affect Age/Location only. Raw native PNGs were never recompressed. Final V6 is evidenced by scoped tests, geometry and headless captures; these native V4 states prove unchanged keyboard branches, not a native V6 installation.

During capture, a focused field initially lacked a software keyboard. A read-only audit found no app focus/suppression defect. After Screen Sharing stopped, Shakeel confirmed physical retapping opened the keyboard. Screenshot without a live stream yielded a stale Age probe, which was rejected and moved to `_to_delete` by the parent. On reconnect, Device > Keyboard > Toggle Software Keyboard restored the visible keyboard. This is capture-tool/input-state troubleshooting; its precise root cause is unproven. No code change or reinstall was used. Parent then stopped Screen Sharing; View Screen is available again and Capture Keyboard is disabled/off. Phone is usable standalone.

## Checks and evidence

- Final V6 protected full-source `flutter analyze --no-pub`: no issues, 4.5 s. Driver check: Flutter 3.44.2, five pins, direct and inherited Git-exec denial PASS.
- Final V6 38 passing cases: `visual/lock10_filters_capture_test.dart`, `filters_lock10_accessibility_test.dart`, `zyra_browse_filter_test.dart`, `preview_navigation_checkpoint_test.dart`, `request_row_lock7_test.dart`, with `--dart-define=ZYRA_LOCK10_CAPTURE=true`.
- Rendered bounds assert 26/22/18 pt gaps. Location visible title and semantics are checked; 320 pt at 1×/2× text wraps/scrolls, with adjustable slider/chip labels and haptics. Swipes move blank cards; segment/slider/chip/field drags do not page. Old chip/field/slider callbacks are denied across page/session/disposal. Both Age handles are dragged with frame pumps to endpoints 18/70. Preferences Save and origin Done return correctly.
- Before narrow V6, nine focused Browse/filter/history/motion/outline cases passed across `view_request_draft_widget_test.dart`, `browse_next_motion_shell_test.dart`, `browse_screen_invitation_frame_test.dart`, `one_journey_pull_down_routes_test.dart`, selected by `public.*heritage|filter|Filter|Browse Back respects`.
- Before narrow V6, 39 retained-editor/resume cases passed across `retained_profile_editor_reuse_test.dart`, `one_journey_resume_checkpoint_test.dart`, selected by `traffic lights|generation change during save|foreign cover during save|revoked|fresh|stale|ABA`.
- Total task scope is 86 distinct passing cases; final V6 reran the 38 relevant cases. The earlier ten-test final V4 rerun overlaps those counts. No whole-suite pass claim; legacy OA-ZYRA-316 failures remain in Tasks 14–16. Capture/boundary tests made zero network attempts. Commands and phases are recorded in `verification.json`.

All Flutter/Dart commands used `node tooling/no_git_driver.mjs` from SOURCE; only primary ran SDK commands. The single authorised installer exception is separately recorded. The read-only helper found no issue in the final V6 patch.

`PRODUCT/APPROVED/FILTERS/BUILT/` contains eight normal V6 headless renders, two explicitly named V6 `__headless_layout` renders, two raw native V4 keyboard images and one `master_beside_build.png`. Normal card is (21,147,388,648), pill (21,845,388,56); headless inset card bottom is 669. The latter is only layout proof. The final comparison uses native canonical f07/f10 and labels their V4 provenance. Actual iOS27 predictive row/insets create a shorter card than the prototype keyboard illustration. App font/glyph rasterisation, inner spacing and prototype screen corners differ; pixel equality is not claimed. Current title/gaps, card/pill structure and chip arrangement are checked. Parent found black thumb outlines and an extra 11 pt range-track inset per end. Final plain gold thumbs have zero black outline pixels; range track x150–1139 now matches the master with uniform 4 pt height. Actual font/control geometry places f02 slider centre 3 pt and f04 23 pt below the prototype; f04 track is 1 pt wider per end. Explicit empty gaps and the 44 pt action target remain; no baseline offsets were invented. `master_comparison.json` records the measurements.

`REPORTS/EVIDENCE/LOCK10_FILTERS_2026-10-30/` contains JSON receipts, hashes, comparison, verification and text BUILD.json only. BUILD.json identifies final source `9a8f3a8` separately from installed source `aab4973` and records all 14 source/test hashes. No compiled app or source tree was copied into evidence. The authorised app remains in SOURCE build storage; ignored app.dill also remains generated build storage, never committed.

DOC-ZYRA-0284 records 165,880 app lines / 326 files; 46,408 developer-preview / 85; 27,289 Founder-preview / 35; 212,438 tests / 490. Goldens remain 2,612 / 307 MB; old-app Pause 39 / Restart 1. No Tier 3 or old-member code was retired.

No PRODUCT/BLUEPRINT file was edited. **Written scope refusal:** planned-screen inventory generation writes into that protected folder, so Fable owns its reconciliation and old Browse wording. The current document MAP indexes this handover; unrelated designer/admin edits remain outside task commits.

## Next owner

Parent: verify final queue row, source/evidence commits and Task 19, then archive this child chat. Fable: independent handover/blueprint review and action maintenance. Founder: final acceptance. Queue 26 and all later work require their own chat; no later row was attempted.
