---
id: ASBUILT-ZYRA-QUEUE26
type: HANDOVER
status: CURRENT
feature: LOCATION
purpose: Implementation, privacy boundary and evidence for queue 26, LOCK11 Location app part
links: [AD-AIOS-115, OA-ZYRA-321, OA-ZYRA-323, OA-ZYRA-317]
owner: Codex
---

# Location — queue 26, LOCK11

Queue 26 is BUILT on 30 October 2026. Tested source is `d12180232cf77033aaa5970d7d7dbb54952e7ee6`, pushed to origin/main. This is the protected Founder preview with sample people. The app can request an optional approximate foreground area through stock CoreLocation; no new package was needed. **No native compile, install, permission prompt, Settings or device-lifecycle run is claimed.** Those checks remain unverified under OA-ZYRA-323. Parent verification, Fable review and Founder acceptance are separate.

## Built from

`PRODUCT/APPROVED/LOCATION/BRIEFS/BUILD_BRIEF_2026-10-30.md`, `LOCATION/RECORD/LOCATION_SPEC_CURRENT_VERSION_V2.md`, its `LOCK_RECORD.md` and four current `LOCATION/MASTERS/` images were read/viewed fresh. Queue 37 was confirmed BUILT. Current `FILTERS/RECORD/FILTERS_SPEC_CURRENT_VERSION_V6.md` and its LOCK record govern the dependency; the older V4 wording in the Location brief/queue is superseded by that current Location card. Founder: “so lets build location” and “LOCK as drawn”. No design was invented. The existing AppDelegate channel pattern and stock platform APIs implement the brief without adding a dependency.

## Behavior and entry

Profiles options → Filters → Location → Near me → Change opens the locked two-choice sheet. Home town and its point come from the actual sample ownProfile city: London, rather than the master picture's Manchester example. Opening the app, Filters, Near me, the choose sheet or Home town performs no location-channel call and requests no permission. My current area first shows the locked explanation. Not now performs no request; Continue alone starts the native request. Allowed coarse data changes the actual sample radius calculation and the origin line. Missing/invalid/unavailable/unsupported data stays on home town. Refusal stays home and shows exactly “No problem — distances start from your home town.” A later explicit attempt after refusal opens system Settings. A permission grant there clears the refusal cache through permission change/resume status checking, without acquiring a location on resume.

The sheets are inline modal overlays inside the admitted preview. They preserve the host's exact current-route/account guard, block underlying gestures and semantics, and deny retained callbacks. They do not introduce a weaker admission route. A 44 pt action target is retained. Normal 430 pt sheet bounds are (0,532,430,400) for choices and (0,600,430,332) for explanation, measured from the masters and asserted by the capture test. Larger Text wraps/scrolls at 320 pt and 2×; choose/explain have separate scroll identities. The dark barrier leaves underlying gold controls painted enabled while callbacks remain blocked.

## Live files

| File under SOURCE | Job |
|---|---|
| `lib/dev/zyra_one_journey_location.dart` | Mockable MethodChannel adapter and session-only approximate-origin owner, account/flow epochs, permission changes, resume checks, Settings path and clear seam for LOCK12. Real sample-town lookup follows the account profile city. |
| `lib/dev/zyra_one_journey_location_sheet.dart` | Locked choose/explain copy, radio choices, Continue, Not now and Done; guarded shared haptics and accessible modal layout. |
| `lib/dev/zyra_one_journey_concept_shell.dart` | Owns location lifetime, inline sheets and flow guard; binds both draft/applied filters to the valid area or hometown; strips device area from outgoing navigation checkpoints. Navigation, controls open/close, role changes and foreign route changes cancel pending flow. Disposal clears state. |
| `lib/dev/zyra_one_journey_filters_presentation.dart` | Receives hometown/current-area display from the owner. Covered controls preserve their paint while their existing callback guard rejects writes. |
| `lib/dev/zyra_browse_filter.dart` | Adds explicit nullable origin replacement; existing Haversine/eligibility/public-code filter rules continue. |
| `ios/Runner/AppDelegate.swift` | Lazy stock CoreLocation adapter on the existing implicit-engine channel seam; no project-file or package edit. |
| `ios/Runner/Info.plist` | Exact locked When In Use purpose and `NSLocationDefaultAccuracyReduced=true`. |
| `test/zyra_location_lock11_test.dart`, `test/visual/lock11_location_capture_test.dart` | Controller/privacy/native-source-contract checks and actual admitted-host/shell interaction/render checks with mocked location. |

## Privacy, state and failure boundaries

The native adapter requests only When In Use, sets `desiredAccuracy=kCLLocationAccuracyReduced`, uses one-shot `requestLocation`, stops on cancellation/background/timeout, and rounds latitude/longitude to a 0.1 degree grid **before** the channel result. It returns a sanitized status or that coarse pair only. It never returns a full CLLocation, precise point, altitude, speed, raw error or log. iOS can let a member change Precise in Settings; reduced desired accuracy and native rounding still prevent an exact point entering Flutter. No Always or temporary-full-accuracy API is used. The manager is identity checked, detached on cancellation, and each FlutterResult is completed once.

Dart independently refuses off-grid, non-finite, out-of-range or malformed responses. A permission result must survive account generation/user, sign-out/admission, route, role, controls, flow and lifecycle checks, followed by another native status check before it can become the origin. Inactive alone is the permission-dialog interval and keeps the epoch; a result waits for resumed. Hidden/paused/detached invalidates the flow and clears area. Resume withdraws an existing point while permission status is pending. Revocation clears area; switching Home town clears it explicitly. A replacement controller owns the single channel handler, so the older controller cannot detach its successor or cancel a successor request.

Only the two internal active/editing filter instances can hold the coarse point during this shell lifetime. Outgoing checkpoints replace it with the profile-town point; restoration never revives device area. There is no preferences write, server call, repository, saved location or exact coordinate in Dart. No origin or distance number is added to cards, profiles or Guardians. Account disposal drops the only in-memory area. The `clear()` seam is available for the separate Phone access queue line; row 27 was not implemented here.

## Verification and evidence

All SDK calls ran only in this primary chat from SOURCE through the pinned `node tooling/no_git_driver.mjs` wrapper. Flutter 3.44.2, five SDK pins and direct/inherited Git-exec denial checks pass. Final analysis: no issues found (3.6 s). Info.plist lint: OK.

- Six affected suites passed 62 cases: Location controller/visual, Filters visual/accessibility, pure browse filter and navigation checkpoint.
- After final sheet geometry/typography/scroll identity, the two Location suites passed all 30 cases again; this overlaps the 62.
- Nine affected Browse Apply/Back/Clear, stale filter, filtered motion/history and public-boundary cases passed across four selected suites.
- Total: 71 distinct passing cases. Captures made zero network attempts. No unfiltered whole-suite pass is claimed; existing unrelated OA-ZYRA-316 legacy failures were outside this row.

`PRODUCT/APPROVED/LOCATION/BUILT/` contains the three real 1290×2796 Flutter state renders and `master_beside_build.png`, plus text BUILD.json. All three were viewed beside the current masters. Sheet heights and option text inset now follow measured master geometry; actual London label is correct. Font/glyph rasterisation, text baselines and prototype screen corners differ, as do the existing V6 card origin/slider positions already recorded by queue 37. Exact 22/18 pt Location gaps remain. **No pixel-parity claim.** The fourth master is an iPhone prompt reference only; it was not fabricated or captured.

`REPORTS/EVIDENCE/LOCK11_LOCATION_2026-10-30/` contains JSON receipts/comparison/verification and text BUILD.json only. Hashes bind source, masters and rendered PNGs. Nothing compiled and no source tree was copied into evidence. Exact commands/counts are in `verification.json`.

## Scope, limits and next owner

No dependency, backend, migration, production data, signing, upload, publication, old-member/sign-in route or Tier 3 retirement changed. No PRODUCT/BLUEPRINT file was edited. Written scope refusal: protected inventory/Browse wording reconciliation and unrelated map warnings are for Fable, not this build. OA-ZYRA-321 retains DPIA/launch ownership; OA-ZYRA-317 retains member/server integration; OA-ZYRA-323 retains native compiler/prompt/Settings/device proof. No new Founder decision is needed to mark this app-part build complete within its mocked-check/render brief. Native proof still requires its own authorised route.

The read-only reviewers' pre-handover implementation findings (resume gate, Settings recovery, channel ownership and controls A→B→A) were fixed and regression checked within this LOCK11 work. Helpers ran no SDK, Git, device or service actions. Their accounting is in Task 20. Parent verifies row 26, these files, commits and Task 20, then archives this chat. Fable reviews independently; Founder accepts. No other queue row was processed.
