---
id: DOC-ZYRA-0284
type: REPORT
status: CURRENT
feature: CODE HEALTH
purpose: ZYRA code-size tracker - how much code the app has, how much is developer/preview code, and how many old-app files still carry retired features; one row per clean-up step
links: [OA-ZYRA-316, DR-ZYRA-274]
owner: Fable
---

# ZYRA — CODE SIZE TRACKER

Founder request, 25 Oct 2026: show this table whenever we report on cleaning the code. Numbers come from
`SYSTEM/tools/blueprint/code_size.py` (read-only; counts `SOURCE/lib`). "Save" is not counted because the word is too common
to measure honestly by search; it will be counted file by file in the deep review.

## Latest

| What | Size |
|---|---|
| All app code | 167,772 lines in 331 files |
| Developer and preview code inside it | 48,286 lines in 90 files |
| The Founder preview (planned app) | 29,161 lines in 40 files |
| Test code | 214,692 lines in 496 files |
| Test screenshots (goldens) | 2,612 images, 307 MB |
| Old-app files that still mention Pause | 39 |
| Old-app files that still mention Restart | 1 |

## History

| Date | Step | All app code | Developer + preview | Founder preview | Test code | Goldens | Pause files | Restart files |
|---|---|---|---|---|---|---|---|---|
| 2026-10-25 | Baseline, before any clean-up (OA-ZYRA-316) | 171,658 / 342 | 46,429 / 87 | 24,701 / 31 | 207,814 / 464 (counted 26 Oct) | 3,984 / 467 MB (counted 26 Oct) | 40 | 2 |
| 2026-10-29 | OA-ZYRA-316 Tier 1: 16 unused files removed; 6 retained by scope/dependencies | 167,819 / 326 | 46,118 / 86 | 24,701 / 31 | 206,100 / 459 | 3,349 / 401 MB | 39 | 2 |
| 2026-10-29 | OA-ZYRA-316 Tier 1 remainder: 5 named files removed; onboarding bank retained | 165,953 / 321 | 44,446 / 82 | 24,701 / 31 | 205,716 / 458 | 3,337 / 399 MB | 39 | 2 |
| 2026-10-29 | OA-ZYRA-316 Tier 2: app-side Journey Pause/Save and obsolete restart stub removed | 165,631 / 321 | 44,178 / 82 | 24,433 / 31 | 205,291 / 458 | 3,337 / 399 MB | 39 | 1 |
| 2026-10-29 | Queued baseline capture: four test files; app source unchanged | 165,631 / 321 | 44,178 / 82 | 24,433 / 31 | 207,177 / 462 | 3,337 / 399 MB | 39 | 1 |
| 2026-10-29 | OA-ZYRA-316 Tier 4: 92 unchosen options removed; selected design retained | 161,734 / 320 | 43,364 / 81 | 24,336 / 31 | 205,723 / 461 | 3,337 / 399 MB | 39 | 1 |
| 2026-10-29 | OA-ZYRA-316 matching tests/screenshots: 28 obsolete cases and 699 old captures retired | 161,734 / 320 | 43,364 / 81 | 24,336 / 31 | 205,402 / 461 | 2,638 / 313 MB | 39 | 1 |
| 2026-10-29 | OA-ZYRA-316 queue5: Original photos mode/picker and 26 matching captures removed; six baseline states added | 161,543 / 320 | 43,282 / 81 | 24,257 / 31 | 205,099 / 461 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | LOCK4 profile-details first-photo avatar (queue8) | 161,645 / 320 | 43,282 / 81 | 24,257 / 31 | 205,672 / 463 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | LOCK5 tab-open attention marker (queue9) | 161,735 / 320 | 43,372 / 81 | 24,344 / 31 | 206,561 / 466 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | Queue10 signup/onboarding capture (app unchanged) | 161,735 / 320 | 43,372 / 81 | 24,344 / 31 | 208,744 / 472 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | LOCK2 Requests/Past/capacity/Main message (queue11) | 162,146 / 320 | 43,769 / 81 | 24,739 / 31 | 210,362 / 475 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | Queue13 LOCK3 preflight failed; app/tests unchanged | 162,146 / 320 | 43,769 / 81 | 24,739 / 31 | 210,362 / 475 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | LOCK6 scoped compact tab bar and matching test fixtures (queue14) | 162,681 / 320 | 43,813 / 81 | 24,783 / 31 | 211,414 / 477 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | Queue15 Basic/Guardian capture; app unchanged | 162,681 / 320 | 43,813 / 81 | 24,783 / 31 | 212,463 / 479 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | Queue16 LOCK7 preflight failed; unfinished source withdrawn | 162,681 / 320 | 43,813 / 81 | 24,783 / 31 | 212,463 / 479 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-29 | Queue17 LOCK8 preflight failed; prerequisite13 incomplete | 162,681 / 320 | 43,813 / 81 | 24,783 / 31 | 212,463 / 479 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-30 | Queue 40 LOCK12 V2 Phone access | 167,772 / 331 | 48,286 / 90 | 29,161 / 40 | 214,692 / 496 | 2,612 / 307 MB | 39 | 1 |

| 2026-10-30 | Queue 18, LOCK3 Guardian information and consent (OA-ZYRA-324 / DR-ZYRA-233) | 163,176 / 322 | 44,292 / 82 | 25,226 / 32 | 212,900 / 481 | 2,612 / 307 MB | 39 | 1 |

| 2026-10-30 | Queue 19, LOCK7 single request pill and Larger Text (DR-ZYRA-305) | 163,373 / 322 | 44,301 / 82 | 25,235 / 32 | 213,304 / 483 | 2,612 / 307 MB | 39 | 1 |

| 2026-10-30 | Queue 22: shared tap haptics across the planned app and OA-ZYRA-314 Journey helper | 163,908 / 323 | 44,464 / 82 | 25,373 / 32 | 213,552 / 484 | 2,612 / 307 MB | 39 | 1 |

| 2026-10-30 | Queue 23: Compatibility pages loop by arrow and swipe (Founder-named brief; DR-ZYRA-288 / OA-ZYRA-286) | 163,937 / 323 | 44,493 / 82 | 25,402 / 32 | 213,776 / 485 | 2,612 / 307 MB | 39 | 1 |

| 2026-10-30 | Queue 29, LOCK8 V2: Guardian five tabs, local Family Review and private Connect (DR-ZYRA-306 / OA-ZYRA-325) | 164,449 / 323 | 44,964 / 82 | 25,859 / 32 | 213,661 / 486 | 2,612 / 307 MB | 39 | 1 |

| 2026-10-30 | Queue 30, LOCK9 V2: shared local Code page and fictional alias adapter (DR-ZYRA-231) | 165,020 / 325 | 45,619 / 84 | 26,514 / 34 | 211,809 / 488 | 2,612 / 307 MB | 39 | 1 |

| 2026-10-30 | Queue 32 LOCK6 V2: planned roots 60%, master idle slot spacing (DR-ZYRA-304) | 165,050 / 325 | 45,619 / 84 | 26,514 / 34 | 211,880 / 488 | 2,612 / 307 MB | 39 | 1 |

| 2026-10-30 | Queue 37 LOCK10 V6: Filters cards, public sets and preferences (AD-AIOS-115 / OA-ZYRA-316) | 165,880 / 326 | 46,408 / 85 | 27,289 / 35 | 212,438 / 490 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-30 | Queue 26 LOCK11: optional coarse foreground area and actual profile hometown (OA-ZYRA-321 / OA-ZYRA-323) | 166,377 / 328 | 46,905 / 87 | 27,784 / 37 | 213,091 / 492 | 2,612 / 307 MB | 39 | 1 |
| 2026-10-30 | Queue 38 LOCK13 V2: Journey place cards and ordinary options page (AD-AIOS-115 / OA-ZYRA-317) | 167,295 / 330 | 47,823 / 89 | 28,698 / 39 | 213,972 / 494 | 2,612 / 307 MB | 39 | 1 |

Note: the first count given to the Founder on 25 Oct said 45,620 lines / 84 files of developer code; it missed the three
developer screens in `screens/dev/`. The baseline above is the corrected figure.

## Tier 1 — 29 Oct 2026 (OA-ZYRA-316 / DR-ZYRA-274)

Removed 16 unreachable source files (3,839 lines), their dedicated tests and only their cases in shared suites. Moved all
retired files into `~/_to_delete/OA-ZYRA-316_TIER1_2026-10-29/`, preserving paths; nothing permanently deleted. Retired
12 active Guardian Detail screenshot baselines and the matching 12 promoted captures, plus 7 unapproved Notifications
captures. The 112 surviving active baselines and all 36 historical baselines retain their original bytes. No screenshot
was regenerated or re-approved. Five visual fixtures (19 render variants) belonged to the removed screens.

Six entries from the original 22-file list remain:

- `SOURCE/lib/dev/journey_experience_lab.dart`, `wali_dashboard_preview.dart`, `dev_app_icon_directions.dart` and
  `dev_splash_lab.dart`: Shakeel explicitly protected `SOURCE/lib/dev/` from Tier 1 changes.
- `SOURCE/lib/services/zyra_dev_app_icon.dart`: imported by the protected app-icon directions screen.
- `SOURCE/lib/data/onboarding_bank_contract.dart`: used by `SOURCE/tool/generate_onboarding_bank_sql_values.dart`,
  which regenerates the onboarding-bank SQL parity suite (OA-ZYRA-196). It is not unused tooling.

The old Seeker/Guardian shells, sign-in/onboarding/recovery routes, the Founder-only sample preview and
`PRODUCT/BLUEPRINT/` are unchanged. Tier 3 waits for OA-ZYRA-317. No server, migration, Tier 2 or Tier 4 change was made.
The developer-code reduction is the unused `screens/dev/moderation_review_queue_screen.dart`; no `lib/dev/` file changed.

Before this step the measured screenshot inventory was 3,380 / 403 MB, rather than the historical 3,984 / 467 MB above.
This step moved exactly 31 images. Pause/Restart counts use the existing broad non-developer-file search; they are not a
feature audit, and legitimate profile Pause may be included. Planned Request restart stays in the Founder preview.

Checks and commit are recorded in the 29 Oct daily task note. The exact source move inventory and hashes are in
`REPORTS/EVIDENCE/OA-ZYRA-316_TIER1_2026-10-29/removed_sources.json` (local evidence, not a source/build copy).
Remaining Tier 1 entries stay under OA-ZYRA-316 for Fable's review; no decision or action register was changed.

## Note 29 Oct 2026 (Fable, from the ZYRA chat note (h))

The historical golden baseline in this tracker (3,984 files / 467 MB) differs from the figure Codex measured before Tier 1 of OA-ZYRA-316 (3,380 files / 403 MB). The difference is the evidence copies moved to `_to_delete` on 27 Oct (OA-AIOS-405) and git-ignored build output; neither is app code. From Tier 1 onwards the tracker uses Codex's measured figures, with the code-size table in each task note (standard §3).


## Tier 1 remainder — 29 Oct 2026

Founder clarified that the protection covers the Founder preview, and explicitly named five further removals: the four
previously retained developer labs/gallery files plus `services/zyra_dev_app_icon.dart`. They and their matching
test/gallery captures moved to `~/_to_delete/OA-ZYRA-316_TIER1_REMAINDER_2026-10-29/`. Removed 1,866 source lines,
one visual suite and 12 candidate PNGs (2,358,031 bytes), plus obsolete cases in six mixed suites. All seven native
icon/asset checks, HomeTools and live splash-motion coverage remain. Native assets/configuration and the icon artwork
generator are unchanged. Only `onboarding_bank_contract.dart` remains from the original 22-file list because active
tooling uses it. Founder preview and old member routes are byte-identical. Analyser clean; 71 focused tests pass.

## Tier 2 — 29 Oct 2026

Removed dormant Journey Pause/Resume state, Save model/storage and hidden UI paths from the Founder preview and shared
presentation files; removed the unreferenced always-throwing restartJourney stub and its unused exception. Live callers
already hid Save. Planned Request restart, End/history, ownership guards, account/profile Pause and ordinary member
sign-in routes remain. No old-app-only file or backend changed. Nine source files lose 322 lines; minimal API fixture
adaptations retain active coverage. Historical photo-dismiss fixtures expecting a direct vertical drag predate this task
and are carried to the separate matching-tests cleanup under OA-ZYRA-316; current edge/back behavior is unchanged.
Preview Timeline examples also exclude the retired Pause/continue events; canonical old-app history vocabulary stays.
Analyser clean (3.7s); 42 focused suites, 21 Timeline cases and two retained photo/delegate cases were checked.
Count correction: the historical 1,055 total included 94 hidden harness events (961 visible cases). The final combined
Tier 4 run below supplies saved passing evidence for the affected Tier 2 suites as well.
No screenshot regenerated. Exact paths/checks are in local Tier2 JSON evidence and the daily task note.

## Queued baseline capture — 29 Oct 2026

Capture-only queue line 2 adds four visual harness/test files (1,886 lines); app source is unchanged. The 301 full-phone
PNG review inputs live in PRODUCT/APPROVED/BASELINE/SCREENSHOTS (260,375,095 bytes), outside this tool's SOURCE/test
golden count. Actual production theme, iOS target, local portraits and platform glyph fallback were verified. The
generated index accounts for all 49 page IDs in both roles and all nine root tabs; legacy Notifications has no opener,
and Saved/Paused are retired. No LOCK or product design is created by this capture.
## Tier 4 — 29 Oct 2026

Kept the selected design in each of 17 sets: 49 of 141 choices, removing 92 unchosen choices. Founder explicitly chose
current Glass Signals over the stale Classic Glass line in DR-ZYRA-276. All ten dark backgrounds, eighteen fonts and
seven navigation styles remain in developer tools. All 31 Founder preview files remain, including the current Portrait
split large-text fallback. Ordinary member routing, account Pause, services and backend are unchanged.

Thirty-one source paths lose 3,897 lines (one retired menu module moved to ~/_to_delete). Required fixture adaptations
and its dedicated visual suite move close removed APIs; PNG retirement follows as a separate task. Full analyser clean
(4.2s). Across 96 affected suites, 1,798 visible cases pass after replacing the stale Browse-label suite with its passing
retry; hidden harness events are excluded. Another 26 manifest/navigation cases pass. All 261 compared chosen PNGs
match the pre-cleanup baseline exactly; 20 changed developer panels are intentionally excluded. All 303 baseline
artifacts remain byte-identical. Source hashes and counts are in local Tier4 evidence. No screenshot regeneration,
backend, Blueprint or Tier3 change. Tier3 still waits for OA-ZYRA-317.

## Matching test and screenshot retirement — 29 Oct 2026

Removed 28 obsolete direct-vertical-drag/Transform photo-dismiss cases and their unused helpers (321 test lines),
retaining both valid photo/delegate cases and current owned-edge/back-route coverage. Moved 699 positively mapped
unchosen captures (90,249,038 bytes): 343 non-Luma onboarding, 21 retired splash, 166 Classic Glass, 78 menu/role/network,
and 91 old light-only outputs. Ambiguous screenshots stay. All 2,638 surviving test PNGs retain their original hashes;
112 active and 36 archived approved baselines and both approval manifests are untouched.

Also moved 20 explicitly unchosen Circle captures from the queued review packet: 301 original, 281 retained. INDEX and
BUILD record retirement while preserving the capture commit and original evidence rows; all retained PNG bytes stay.
The 20 developer-panel pictures are marked historical before the option lists shortened. Total 719 moved PNGs,
102,090,028 bytes, under ~/_to_delete/OA-ZYRA-316_TIER4_TESTS_2026-10-29/. No image regenerated, design approved or
app source changed. Full analyser clean (4.1s); 186 cases across five photo/back-route suites and five approval-manifest
cases pass. Exact inventories, move hashes and audits are in local Tier4_TESTS evidence. Tier3 waits for OA-ZYRA-317.

Historical candidate-only manifest SYSTEM/tools/ui_gate/CANDIDATES/manifest.json still records 87 moved outputs
(66 Classic Glass and 21 light navigation). It is not an active approval record and remains unchanged. The exact
original-path-to-destination mapping and hashes are in
REPORTS/EVIDENCE/OA-ZYRA-316_TIER4_TESTS_2026-10-29/png_move_receipt.json; the candidate-reference audit records these
87 references. This preserves promotion history without presenting retired pictures as active baselines.

## Profiles photo mode cleanup — 29 Oct 2026

Queue5 removes the unused Original photos enum/overlay, developer Profile cards picker and checkpoint mode field.
Details first is the sole behavior; its photo page wrapper, geometry, timing, dots and separate gallery/photo ordinals
remain. Five lib paths lose191lines; tests retire26 obsolete variants while retaining rendering/ownership guards.
Twenty-six visually confirmed unapproved old Profiles overlays and three explicitly retired baseline PNGs moved to
~/_to_delete/OA-ZYRA-316_PROFILES_PHOTOS_2026-10-29/ (29PNG,10,339,295B). Eight manifests and148 approved PNGs have no overlap/drift.
Six new430×932@3x baseline states capture clean photo1/2, icon-only options on Profiles/full-profile, one-unlock reveal,
and selected report reason. Packet284PNG includes278 unchanged survivors. Twenty-eight existing chosen captures
match exactly after cleanup. Full analyser and nine affected suites pass after restoring the existing photo wrapper;
initial capture fixture mistakes (selected person and icon hit target) were corrected. No native build, backend,
Blueprint or Tier3 change. Outside-Profiles overlays flagged unchanged: Seeker full profile, Guardian network profile,
Guardian linked profile. Local evidence: OA-ZYRA-316_PROFILES_PHOTOS_2026-10-29.

## LOCK4 profile details photo — 29 Oct 2026

Queue8 fills the existing56×56gold-ring details emblem with the caller's first admitted photo, centred cover, with2pt
clear gap inside the border. No-photo/loading/error retains the existing gold person icon; ordinary gallery defaults
remain. Three shared widget paths add102lines; developer/Founder preview counts are unchanged. Six original/new
focused suites plus shared fallback/privacy/gallery checks were run; fixture expectations adapt to the newly admitted
avatar without dropping original cases. Two built1290×2796states and master/built pairs are recorded; outside the56pt
emblem, default Profiles pixels match the preserved baseline exactly. All286baseline artifacts stay byte-identical.
Missing-photo capture is an explicit bounded shared-presenter fixture because the actual editor retains the last photo.
No backend, old-member route, Blueprint, native build or source copies.

## LOCK5 tab attention — 29 Oct 2026

Queue9 adds a detached monotonic received-arrival sequence and tab-open checkpoint marker. Visiting My ZYRA clears
its navigation gold without acknowledging any request or changing the internal New activity rules. Later arrivals,
including a fresh attempt from the same sample person after reset, are newer than the old marker. Three preview paths
add90lines; four test paths cover model isolation, real navigation, restore and stale callback guards. All affected
suites and analyser pass. Two actual-shell captures preserve LOCK4 geometry; no pixels change outside the My ZYRA icon,
and all289 prior baseline/LOCK4 picture artifacts are unchanged. No server, old-member, Blueprint or native change.

## Corrected LOCK2 Requests and Guardians — 29 Oct 2026

Queue11 adds passive indefinite Past requests with original-request and move dates, cancel/decline outcomes, newest-first
ordering and exact30-day Not taken up resend boundary. Requests now has three sections; sent button wording/semantics
match the LOCK. Keep my Journeys leaves the received request intact. The existing local Make Main action opens its
one-time subject-bound notice; first accepted real link remains deferred to OA-ZYRA-317. Nine lib paths add411lines,
including optional shared semantic seams whose defaults preserve other callers. All311 other app files are unchanged.

Four capture cases produce14same-name1290×2796built pictures, visually compared beside masters; unchanged default
Profiles is byte-identical to LOCK4. The prototype's sample identity/layout differs from the actual baseline as recorded
in BUILD; existing fonts, photos, back gestures, report/demo controls and LOCK4/5 behavior stay. Tests cover exact dates,
indefinite retention, cooldown, callbacks, restoration, capacity invariants and compact200% reading. Older regression
fixtures were updated for LOCK4 avatars/LOCK5 attention/current LOCK2 words without dropping cases. No backend, ordinary
member route, Blueprint or native change. Checks and commit are in the daily Task19 note and local LOCK2 evidence.

## LOCK6 tab bar — 29 Oct 2026

The Founder preview roots use the locked gold underline,40% idle bar and expand-only first gesture. Full size lasts
three seconds after release; scrolling collapses it. VoiceOver/Switch Control/Larger Text keep full targets. An owned
250ms ease animation snaps immediately for native or MediaQuery Reduce Motion, including mid-transition toggles while
a pointer remains held. Existing activity gold and callback/route guards remain. Only three lib paths change; the
shared opt-in defaults off, preserving ordinary member bars, developer styles and the Profiles action bar.

Five widget suites pass103cases;31affected Founder suites pass after selective fixture retries (710cases). The
fixtures now expand before selecting and use unchanged page reservations independently of the new idle bar. No cases
were dropped. Two actual-shell capture cases create four1290×2796pictures; Seeker pixels above navigation remain
identical to LOCK2. Existing Guardian four-tab destinations/body stay per the LOCK6 spec. Final recapture after the
animation fix is byte-identical. No backend, Blueprint, old-member route, native build or retired file change.

## Basic plans and Guardian Journey capture — 29 Oct 2026

Queue15 adds two visual suites and52actual1290×2796pictures:21Seeker Basic,18Guardian Basic and13Guardian Journey.
Eight cases pass after correcting one fixture button type and supplying the existing local preview session for Add
Guardian. Visible title/demo-code assertions prevent that frame being accepted blank. All52frames were visually checked;
all320app files and1,113prior PNGs are unchanged. No new golden approvals or app implementation. INDEX/BUILD record
19unreachable requested states and existing policy gaps, including quota/link caps, Basic restart and default credit,
Guardian readers/Family Review and consent-bound past summaries. Capture-only scope explicitly refuses product fixes.


## LOCK3 Guardian information and consent — 30 Oct 2026

Queue 18 adds the Seeker Profile education row and four bounded cards, built from the revised LOCK3 V2.
The device stores only the preview education marker. Existing Profiles details content and bottom pills are shared
without changing their metrics. Guardian Circle past topics and safe archives now require that Guardian’s consent;
revocation invalidates retained callbacks, removal clears the grant, and removed links cannot restore it from a checkpoint.
Shared topics show only first names and dates. The Seeker’s own Circle remains unchanged.

The analyser is clean; 281 focused tests pass, followed by six explicit iOS capture cases. Five 1290 × 2796 captures and
the master-beside-build sheet live in PRODUCT/APPROVED/GUARDIAN_INFO/BUILT/. Existing LOCK4 card/action pixels above
the navigation area are identical; its old full screenshot differs only where the later LOCK6 changed navigation.
No old master or baseline was overwritten. Production remains under OA-ZYRA-317; no migration, native build, installation,
upload or Tier 3 route removal was attempted. The daily task note records the two ZYRA commits and verification commands.


## LOCK7 request pill — 30 Oct 2026

Queue 19 builds the revised locked request row (DOC-ZYRA-0322/0323 V2/0324; DR-ZYRA-305, AD-AIOS-115).
The Seeker Profiles root alone supplies `requestRowLabels` through the sample wrapper. The shared presenter keeps its
three-pill default for other callers, including own-profile inspection; hidden inspection omits feed chrome. Guardian
Network, the options bar and navigation are unchanged. The row is one glass surface, 390 × 56 at the 430-point viewport,
with 68 × 56 arrow targets, two 28-point dividers and the locked gold border/sent treatment. At 200% text the tested
430/393/320-point widths all wrap the request label to two lines, with an 88-point stable height for all four root labels.
The layout reserve and rendered row use the same text measurement, so changing labels does not move the card.

Live files: `SOURCE/lib/widgets/zyra_profiles_components.dart` owns presentation and measurement;
`SOURCE/lib/widgets/zyra_browse_designs.dart` preserves caller eligibility and semantics while selecting the opted-in row;
`SOURCE/lib/dev/zyra_one_journey_browse_designs.dart` forwards the opt-in;
`SOURCE/lib/dev/zyra_one_journey_concept_shell.dart` opts in only the existing Seeker root.
No request state, persistence, transport, role admission or callback authority moved into the row. Existing keys,
request/cancel callbacks, labels and the member-controlled feedback remain. No migration or retired source is involved.
The feature remains sample-only in the Founder preview; ordinary members wait for OA-ZYRA-317.

The analyser is clean. Seven focused/regression suites pass 111 cases, including actual-shell send/cancel and stale
callback checks, shared gallery, own preview, options and LOCK6 navigation. Three explicit iOS capture cases pass and
produce the three 1290 × 2796 pictures in `PRODUCT/APPROVED/REQUEST_ROW/BUILT/`, beside their masters and the comparison
sheet. `SOURCE/test/request_row_lock7_test.dart` covers six new geometry/accessibility/guard cases; the capture suite is
`SOURCE/test/visual/lock7_request_row_capture_test.dart`. No approved baseline was overwritten.

Comparison is scoped: row measurements and states match the V2 specification; the complete prototype masters and actual
screens are not pixel-identical. The existing actual app has LOCK4 photos, smaller identity typography, different details
spacing/viewport and pagination, the sent-card Glass Signals outline, an unframed screen and current LOCK6 navigation.
Written refusal: do not redraw these unrelated surfaces or overwrite masters to imitate the older prototype. Fable and
the ZYRA design chat own independent comparison/verification; Founder acceptance remains separate.

Supplementary UI gate: PASS-WITH-FINDINGS (354 advisory findings: 0 critical/high, 13 medium, 341 low). The older static
checker exits 1 on 106 heuristic findings, including existing named-constructor/export false positives; no broken import
or new dangling document reference is reported. Written refusal: checker repair and unrelated legacy findings are outside
row 19. Clean Flutter analysis and compiled regression/capture tests are the measured implementation checks. Scratch
reports are moved to `/Users/shakeelahmad/_to_delete/ZYRA_QUEUE19_2026-10-30/`; only screenshots/JSON/BUILD.json remain as
evidence. The daily Task 5 note records exact commands, source/evidence commits and disk measurements.


## Queue 22 — shared tap haptics — 30 Oct 2026

Built from `PRODUCT/APPROVED/HAPTICS/BRIEFS/HAPTICS_BRIEF_2026-10-30.md` and blueprint part 5 §6
(DOC-ZYRA-0282; Founder: "ensure this and all buttons have haptic feedback"). Shared tap callbacks read the
current preview session or member device level, preserve disabled controls, and own one pulse through delegated
callbacks. Photo/page swipes, navigation dragging, scrolling and typing stay silent. The four direct phone calls in
`journey_flow_screen.dart` now use the shared setting helper (OA-ZYRA-314 item a only). The old member app remains.
No visual, relationship-rule, server, migration, sign-in or Tier 3 change was made. No pictures are required by this brief.

Headless validation: 302 tests across 19 focused suites pass, including every current tab root in both roles, actual
request pills and sheets, Off, disabled/revoked controls, immediate Personalisation selection, photo editors and compact
navigation geometry. The task note lists commands and the complete control-family inventory. Fable's independent
verification remains separate; no native build/install/upload was attempted.


## Queue 23 — Compatibility loop — 30 Oct 2026

Built from `PRODUCT/APPROVED/COMPATIBILITY_LOOP/BRIEFS/COMPATIBILITY_LOOP_BRIEF_2026-10-30.md`: the Founder asked
for page 7 → 1 and page 1 → 7 by arrow and swipe, keeping the existing design. Both arrows stay gold and enabled.
The shared reader keeps seven logical pages and uses duplicate end pages to travel one adjacent page at each wrap,
then silently recentres on the identical content. A reentrancy guard prevents scroll-end notifications recursively
recentering. The existing reduced-motion/accessibility direct jump and person/value reset remain. No new state is saved.

Live files: `SOURCE/lib/dev/zyra_draft_compatibility_score_designs.dart` owns the pagination; its shared caller remains
`zyra_draft_compatibility_presentation.dart`. Profiles after an Unlock, Journey after reveal and the Ended Journey archive
all use that caller and retain their access guards. No scoring, unlock spending, person loading, persistence or route
authority moved into the reader. The Founder preview still uses sample people; ordinary member adoption waits for
OA-ZYRA-317. No migration, native build, installation, upload, old member route or Blueprint change was made.

Validation: seven focused/regression suites pass 75 cases before the final additional rapid-tap case; the final reader
suite passes all 12 cases, making 76 distinct cases across those suites. Coverage includes both arrow/swipe wraps,
repeated wraps, always-enabled arrows, exact counters and screen-reader labels, one-page animation in both directions,
a second arrow during a wrap, person reset, rebuild retention, 200% text, haptic level and Off, and bounded Guardian
LOCK3 cards. The analyser is clean. `SOURCE/test/zyra_draft_compatibility_score_designs_test.dart` adds wrap coverage;
`zyra_draft_compatibility_presentation_test.dart` updates only the superseded endpoint/count expectations.

The explicit iOS capture suite `SOURCE/test/visual/compatibility_loop_capture_test.dart` renders the real local Profiles
reveal at 430 × 932 @3x. Before frames are in local evidence; page 7 after a previous-arrow wrap and page 1 after a
left-swipe wrap are in `PRODUCT/APPROVED/COMPATIBILITY_LOOP/BUILT/`. Before/built comparison sheets sit alongside them.
Both complete frames are pixel-identical outside the newly enabled endpoint arrow: page 7 changes only physical pixels
(1099, 2516)–(1144, 2559), and page 1 only (146, 2516)–(191, 2559). The brief explicitly needs no new design master;
existing actual frames are the reference. No approved master or baseline was overwritten. BUILD.json records code SHA,
Flutter 3.44.2, headless test mode/target, timestamps, file hashes and capture scope. Fable and the ZYRA designer own
independent verification and Founder acceptance; no product finding beyond this requested change was introduced.

## Guardian tabs LOCK8 V2 — queue 29, 30 October 2026

Replaced the old Guardian presenter with the locked five-tab pages and local Family Review / private Connect samples. The removed presenter and obsolete cases moved to /Users/shakeelahmad/_to_delete/ZYRA_LOCK8_GUARDIAN_TABS_2026-10-30/. The new presenter follows the existing zyra_one_journey_* naming so the planned-app count includes it. Existing member/sign-in routes, backend, personal Journey Pause retirement and the screenshot inventory stay unchanged. Default shared Circle/navigation behavior is retained; Guardian navigation alone opts into current LOCK6 V2 geometry. Thirteen affected suites and the twelve-case LOCK8 capture/behavior suite are recorded with exact measured results in Task 14 and its JSON evidence. Five starting-code test failures are separately reproduced and refused as unrelated OA-ZYRA-316 work, rather than counted as passing. The twenty feature captures are beside the masters, outside the SOURCE/test golden count. Fable's independent verification is pending.

Queue 30: the two shared files follow the planned-app naming pattern and are counted above. The replaced local UI suites moved to the global _to_delete; ordinary member routes remain. Details, guards and measured scope: `ZYRA_CODE_PAGE_AS_BUILT_CURRENT_VERSION_V1.md`.


## Queue 38 — Journey tab LOCK13 V2 — 30 October 2026

Built from `PRODUCT/APPROVED/JOURNEY_TAB/BRIEFS/BUILD_BRIEF_2026-10-30.md`,
`RECORD/LOCK_RECORD.md`, `RECORD/JOURNEY_TAB_SPEC_CURRENT_VERSION_V2.md` and all eight `MASTERS/j01–j08` pictures
under that feature folder. Queue 38 was freshly checked as WAITING. The sample Seeker tab now has one swipe card per
place, Journeys ordered by actual local activity before free places, non-looping shared LOCK7 arrows/pill and Profiles dots,
an explicit empty state, Basic's one-place upsell, and the seven-row options page. The options page retains LOCK6 navigation
and has no inner ellipsis. Existing shared pill/dot defaults and ordinary `zyra_one_journey_options.dart` remain.

Live implementation: `SOURCE/lib/dev/zyra_one_journey_tab.dart` owns presentation; `zyra_one_journey_options_page.dart`
composes the 104-pixel photo, 41-pixel painted Continue action with a 44-pixel hit area, and seven rows of at least 60 pixels.
`zyra_one_journey_concept_shell.dart` owns selection, ordering, fresh callbacks and all existing destinations. Its Continue
Journey body is byte-identical to the starting index; the only message-content hook records a successful local message's
activity. `zyra_view_request_draft_model.dart` stores immutable local activity times on successful existing actions without
changing relationship states, permissions or stages. `zyra_preview_navigation_checkpoint.dart` adds only a bounded detached
place index, clamped again to current capacity and omitted by the existing long-return location-reset path.

Actual preview state remains authoritative. Preparing uses the existing “Preparing together · place reserved” copy and
shows no begun stage/progress; readiness and Begin still use the unchanged Journey page. The Seeker model has no open
Family Review/deadline source. Therefore the built Sara frames truthfully show the current question action, not the master's
illustrative 41-hour timer. This existing preview gap belongs to OA-ZYRA-317; no timer, answers, server workflow or relationship
state was invented. Blocked occupied places redact identity/photo/VoiceOver and retain End. Bio and Compatibility retain
their current gates and explanatory destinations; unlocked pages use the existing disclosure handlers.

Validation and limits are recorded in daily Task 22 and JSON evidence. Nine focused suites passed 171 cases; the final local bottom-clearance and outline-button adjustments were checked by the final 14-case actual-shell capture suite and clean analyser. Normal body-to-bar clearance is 14 pixels; small-phone clearance is 28 at normal text and 20 at 200% text. The existing global tab bar is unchanged. All eight actual
430×932 @3x renders and master-beside-build comparisons sit in `PRODUCT/APPROVED/JOURNEY_TAB/BUILT/`. These are headless
Flutter renders with local photos and real shell routes, not an iPhone delivery or a pixel-identical claim. The current actual
navigation/glyph/font metrics and unframed app viewport differ from the prototype's frame. No master was changed.

Written refusal: no whole-suite cleanup or claim, no queue 39/35 work, no Blueprint edit/generated inventory rewrite, no
old member/sign-in retirement, new dependency, backend/migration, native build/install, upload or publication. Fable owns
inventory maintenance and independent verification; Founder acceptance remains separate.


## Queue 40 — Phone access LOCK12 V2 — 30 October 2026

Added the admitted Settings entry, education receipt, exact five-row permission page, native metadata/request/Settings adapter and three locked purpose strings. The actual App lock owns the Face ID pill; this page never enables it. No new dependency, location fix, photo fetch, camera session, remote push-token registration, backend or migration. Existing member routes and LOCK11 rounded location class remain. Seven focused suites passed 95 distinct cases and final analysis is clean; two real Flutter renders and two comparisons sit beside the masters. Mocked permission behaviour is separate from native/device proof (OA-ZYRA-323). Source/render manifest and exact commands are in LOCK12_PHONE_ACCESS_V2 evidence; current as-built handover is ZYRA_PHONE_ACCESS_AS_BUILT_CURRENT_VERSION_V1.md. No whole-suite or pixel-parity claim. Fable's existing oversized-history/archive and protected inventory maintenance remain out of this row's scope.


## Queue 42 — Ivory LOCK14 V5 — 31 October 2026

Built the locked Ivory roles, separate small-gold text and text-bearing gold fill, shared warm floating surfaces, sole member palette and matching icon/launch/splash assets. Existing content/navigation, permission ownership and member preferences remain; Background picker removed. The source pack contains the single live V5 spec and its related archive trace. Rows 43/44 remain separate.

| Scope | Before | After |
|---|---:|---:|
| All app code | 167,772 lines / 331 files | 168,386 lines / 332 files |
| Developer/preview | 48,286 / 90 | 48,626 / 90 |
| Founder planned app | 29,161 / 40 | 29,504 / 40 |
| Tests | 214,692 / 496 | 215,160 / 498 |

Measured with SYSTEM/tools/blueprint/code_size.py. Goldens remain 2,612 images / 307 MB; old Pause/Restart file counts 39/1 unchanged. Validation: 297 distinct targeted cases (18 suites, V5 expectation rerun); final render/colour and footer checks also rerun after the final paint-only fixes. Analyzer and protected SDK checks clean. Fourteen master/build pairs plus 17 enlarged-text/high-contrast states are in APP_COLOURS/BUILT; bound JSON evidence is REPORTS/EVIDENCE/LOCK14_IVORY_V5_2026-10-31. These are headless Flutter renders and native asset projection, not an iPhone launch/install or pixel-parity claim. Existing current-layout/fixture/stencil differences are enumerated in evidence. Old member-route retirement remains OA-ZYRA-317, device acceptance OA-ZYRA-323, independent build review OA-ZYRA-328. No backend, migration, native build/install, dependency change or row43/44 implementation. Seven obsolete Background-only test snippets (11,366 bytes) moved to ~/_to_delete/ZYRA_QUEUE42_IVORY_V4/retired_background_tests; no member data removed.


## Queue 43 — My ZYRA Focus LOCK15 V2 — 31 October 2026

Built the locked Seeker and Guardian Focus presentation with one addressed item, bounded paging/swipe, actual status chips and four quick tiles. Focus consumption is separate from request attention; immutable outgoing-acceptance provenance, dated ending events and event tie ordering survive restore. Undated history creates no new event. Guardian review identity uses a revision, not countdown hours. Existing review/Connect rules and Basic locks remain. Extra Guardian kinds without an addressed local source remain absent; details are in MY_ZYRA/BUILT/SOURCE_LIMITS.json.

| Scope | Before | After |
|---|---:|---:|
| All app code | 168,386 lines / 332 files | 169,360 lines / 334 files |
| Developer/preview | 48,626 / 90 | 49,600 / 92 |
| Founder planned app | 29,504 / 40 | 30,423 / 42 |
| Tests | 215,160 / 498 | 215,310 / 501 |
| Test goldens | 2,612 / 307 MB | 2,612 / 307 MB |
| Old Pause / Restart files | 39 / 1 | 39 / 1 |

Measured with SYSTEM/tools/blueprint/code_size.py, explicitly including the two new Founder-only Focus files in both preview categories; historical classifications are unchanged. Validation: 224 cases across 14 targeted suites; full analyser clean; protected SDK 3.44.2 and format checks pass. Eleven 430×932 @3x master/build pairs, two 430pt enlarged-text renders and two end-scrolled 320pt/200% renders are in MY_ZYRA/BUILT. The compact checks prove 8pt clearance above the unchanged navigation, including Guardian Basic locked labels; pager hit and semantics rectangles are 44×44. Existing widget/font/icon and inherited navigation differences are recorded, without a pixel-parity or device claim. Two obsolete Founder dashboard integration tests and generic activity-detail code moved to ~/_to_delete/ZYRA_QUEUE43_FOCUS_V2; replacement coverage preserves model/permission invariants. Five legacy pale-text expectations in my_zyra_attention_dot_test.dart now use the locked foreground token; all 19 cases there pass. No native build/install/upload, backend, migration or row44/45 work.


## Queue 46 — conversation unread badge LOCK17 — 31 October 2026

Shared gold badge on the Seeker Guardian header's existing Circle icon; its count is projected from the same admitted Circle fixture as the reader. Opening marks only that Circle/viewer/message/sender read in the account-owned memory checkpoint. Focus consumption remains separate. Other preview conversation icons have no existing unread-count source and receive no invented count. The gold box is16pt plus an external2pt page ring; paint order prevents the adjacent Add shadow shading it. Existing member header paint order is retained when no preview decorator is supplied.

| Scope | Before | After |
|---|---:|---:|
| All app code | 169,360 lines / 334 files | 169,530 lines / 335 files |
| Developer/preview | 49,600 / 92 | 49,741 / 93 |
| Founder planned app | 30,423 / 42 | 30,559 / 43 |
| Tests | 215,310 / 501 | 215,980 / 504 |
| Test goldens | 2,612 / 307 MB | 2,612 / 307 MB |
| Old Pause / Restart files | 39 / 1 | 39 / 1 |

Measured by SYSTEM/tools/blueprint/code_size.py; the new Founder-only badge is explicitly counted in both preview categories without reclassifying historical files. Final scoped validation:139 cases across8 complete suites plus5 selected actual Circle ownership/admission guards; analyser clean. Wider run:145 passed/37 failed, with29 Founder white-canvas/internal-hold,5 Journey-title/slot and3 Circle-control/old-slot cases enumerated in UNREAD_BADGE/BUILT/REGRESSION_LIMITS.json under existing OA-ZYRA-328 review linkage. The two composer-loss cases also reproduce with both badge decoration and read clearing disabled; exact transient denial cause remains unproven. Those behaviours were not changed under LOCK17. Actual local sample count1 is retained (master illustrates2). Six renders and u01 comparison/geometry are in UNREAD_BADGE/BUILT; no device/native/server work. Current Guardian layout and page dots await queue47.


## Queue 52 — Profile tab Monogram LOCK21 — 31 October 2026

Seeker and Guardian One/Basic now share the locked centred header, wrapping pills and four floating card groups. Existing account actions stay shell-owned; Basic membership selects the existing role upgrade section, Your Seekers selects its tab, Safety stays on the existing page, and Invite stays held. Removed the former Profile-only row/info/balance widgets and duplicate Guardian Profile presentation. No new Founder-only file or classifier exception was needed.

| Scope | Before | After |
|---|---:|---:|
| All app code | 169,530 lines / 335 files | 169,252 lines / 335 files |
| Developer/preview | 49,741 / 93 | 49,463 / 93 |
| Founder planned app | 30,559 / 43 | 30,281 / 43 |
| Tests | 215,980 / 504 | 216,633 / 506 |
| Test goldens | 2,612 / 307 MB | 2,612 / 307 MB |
| Old Pause / Restart files | 39 / 1 | 39 / 1 |

Measured with SYSTEM/tools/blueprint/code_size.py. Validation: 107 distinct scoped cases across seven suites; final capture and retained-route cases rerun after their final fixture/API repairs; analyser/format/protected driver clean. Six 430×932 @3x states, four 200% text states and six master/build pairs are in PROFILE_TAB/BUILT. QA.json records the actual two-Seeker summary, Basic balance1, existing tab attention, photo crop and native-widget/frame differences; no pixel-parity or device claim. Existing old member routes remain under OA-ZYRA-317, parent verification under OA-ZYRA-328. No queue48/49/50/51/64, native delivery or server work.


## Queue 53 — Filters Monogram LOCK10 V7 — 31 October 2026

Replaced the old bare card head with the locked 92pt ring,36pt icon,28pt light title and11pt live current choice. Age/Location center their full intrinsic content when it fits; taller content scrolls without negative minimum-height constraints. Nationality/Ethnicity retain their existing top placement. No filter model, Location permissions/origin/cancel, full-list search, chip, haptic, swipe, arrow or bottom-pill behavior changed. No new app source file or classifier exception.

| Scope | Before | After |
|---|---:|---:|
| All app code | 169,252 lines / 335 files | 169,323 lines / 335 files |
| Developer/preview | 49,463 / 93 | 49,534 / 93 |
| Founder planned app | 30,281 / 43 | 30,352 / 43 |
| Tests | 216,633 / 506 | 216,995 / 507 |
| Test goldens | 2,612 / 307 MB | 2,612 / 307 MB |
| Old Pause / Restart files | 39 / 1 | 39 / 1 |

Measured with SYSTEM/tools/blueprint/code_size.py. Validation:52 distinct scoped cases across6 suites; analyser/format/protected SDK clean. Ten430×932 @3x renders, four200% text renders and an all-ten master/build sheet are in FILTERS/BUILT/V7. QA.json records actual full-content centering and raster head-anchor differences, inherited paint/pill/font/footer differences, London sample origin versus Manchester illustration, and headless keyboard-inset limits. Written refusal to redesign inherited surfaces/footer or build failed queue49 under this head-only row; parent visual review remains OA-ZYRA-328. Existing37 wider failures were not rerun or claimed green. Old member routes remain under OA-ZYRA-317. No native delivery, server, dependency or other queue work.

Parent-requested footer triage: two actual-shell diagnostic runs at430×932/200% Poppins reproduced identical18pt clipping with V7 enabled and with only the old head/top placement restored in memory. Intrinsic label68pt is constrained to50pt at y795; following pill starts845. Exact source restored in finally (matching SHA). FOOTER_DIAGNOSTIC.json records method/assertions and written refusal under OA-ZYRA-328; no exact old whole-baseline claim, no all-Larger-Text-clean claim.


## Queue 55 — Unity pass LOCK22 V1 — 31 October 2026

Replaced the locked Compatibility, Unlocks catalogue and account Safety layouts with the retained V1 Monogram specification. Removed the old locked big-ring layouts, balance strip, information dialog and Safety's disabled submission action. Existing catalogue prices, eight examples, unlock/debit/reveal ownership, report-profile flow and ordinary routes remain; unknown ordinary balances remain undisclosed. Existing plan data supplies both header variants; stale pack/pager/terms delegates reject before haptics. No new source file or classifier exception.

| Scope | Before | After |
|---|---:|---:|
| All app code | 169,323 lines / 335 files | 168,980 lines / 335 files |
| Developer/preview | 49,534 / 93 | 49,190 / 93 |
| Founder planned app | 30,352 / 43 | 30,008 / 43 |
| Tests | 216,995 / 507 | 216,034 / 508 |
| Test goldens | 2,612 / 307 MB | 2,612 / 307 MB |
| Old Pause / Restart files | 39 / 1 | 39 / 1 |

Measured with SYSTEM/tools/blueprint/code_size.py. Validation:97 distinct scoped cases across8 suites; analyser and format clean. Four standard and seven200% text actual-shell frames plus four full-size master/build pairs and contact sheet are in UNITY_PASS/BUILT/V1. QA.json records native Flutter typography, safe-area/frame, shadow and anchor differences; no pixel-parity or full-app/a11y-clean claim. Two unrelated Profile-row fixture failures from the broader Membership visual suite are refused under OA-ZYRA-328; full inherited37 failures not rerun. Obsolete ring-specific store test moved to /Users/shakeelahmad/_to_delete/ZYRA_QUEUE55_UNITY_V1_2026-10-31/, replaced with catalogue/ownership/reachability checks. Ordinary member routes remain under OA-ZYRA-317; parent visual/contract review remains OA-ZYRA-328. No later UNITY V2–V5 build, native delivery or backend work.


## Queue 57 — Journey options LOCK13 V3 — 31 October 2026

Replaced only the V2 Journey options page with its locked round identity head, full-width gold Continue and three floating cards. All seven V2 destinations, real stage/profile fields, readiness/disclosure/entitlement/account/route/epoch guards, shared feedback and End confirmation remain. Removed the page's single-card layout; the old 38-circle icons remain in still-used inline/sheet menus. No new source file or classifier exception.

| Scope | Before | After |
|---|---:|---:|
| All app code | 168,980 lines / 335 files | 169,082 lines / 335 files |
| Developer/preview | 49,190 / 93 | 49,292 / 93 |
| Founder planned app | 30,008 / 43 | 30,110 / 43 |
| Tests | 216,034 / 508 | 216,511 / 509 |
| Test goldens | 2,612 / 307 MB | 2,612 / 307 MB |
| Old Pause / Restart files | 39 / 1 | 39 / 1 |

Measured with SYSTEM/tools/blueprint/code_size.py. Validation: 73 distinct scoped cases across six suites (five complete, eight selected prior-Compatibility cases); analyser, format and protected SDK check clean. Three430×932 @3x actual-shell renders, four200% head/end frames, three master/build pairs and contact sheet are in JOURNEY_TAB/BUILT/V3. CASE_LEDGER.json excludes loading/setup events and names two stale My ZYRA entry fixtures that fail before options; written refusal under OA-ZYRA-328 to repair those in this row. QA.json records retained Poppins/icon/shadow/frame differences and the actual Sara stage4 Compatibility unlock versus illustrative locked masters. No pixel-parity, full-app, whole-suite or all-accessibility claim; inherited wider37 failures not rerun. Parent visual/contract verification remains OA-ZYRA-328, old member retirement OA-ZYRA-317. No native delivery/backend work. Source3341baf.
