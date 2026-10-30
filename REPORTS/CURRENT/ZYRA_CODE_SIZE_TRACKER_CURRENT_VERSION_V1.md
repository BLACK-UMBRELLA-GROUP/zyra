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
| All app code | 163,176 lines in 322 files |
| Developer and preview code inside it | 44,292 lines in 82 files |
| The Founder preview (planned app) | 25,226 lines in 32 files |
| Test code | 212,900 lines in 481 files |
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

| 2026-10-30 | Queue 18, LOCK3 Guardian information and consent (OA-ZYRA-324 / DR-ZYRA-233) | 163,176 / 322 | 44,292 / 82 | 25,226 / 32 | 212,900 / 481 | 2,612 / 307 MB | 39 | 1 |

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
