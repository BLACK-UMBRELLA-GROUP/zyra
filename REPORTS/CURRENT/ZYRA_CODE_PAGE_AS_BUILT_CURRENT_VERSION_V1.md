---
id: ASBUILT-ZYRA-QUEUE30
type: HANDOVER
status: CURRENT
feature: CODE PAGE
purpose: As-built LOCK 9 V3 Code pages, queue 105, and prior V2 implementation
links: [AD-AIOS-115, DR-ZYRA-231, OA-ZYRA-316, OA-ZYRA-317]
owner: Codex
---

# ZYRA Code page — line 105, LOCK 9 V3

Add a Guardian and Add a Seeker now open on My code. Their code and the
Profiles Scan entry share the light scanner and the five-box manual field.
The source is the 12 November V3 brief, DOC-ZYRA-0343 §0, LOCK record
DOC-ZYRA-0344, Q137 and the archived snapshot of prototype V224. The
historical V2 handover below describes the 30 October build only.

| Surface | Entry and behavior |
|---|---|
| Ordinary Add a Guardian / Add a Seeker | Guardian Add action or signup Support and guidance → Continue, through the existing callers to `ZyraCodeScreen`. My code uses the account-scoped code read. Check shows first name and role; Send uses the existing request RPC and keeps the Guardian relationship and Seeker capacity checks. Existing pending request controls and manual older-invite fallback remain. |
| Ordinary Scan | Profiles action menu → Scan via `HomeShell` and `FindByZyraCodeScreen`. First name and role only; the ordinary matching route retains Consider and the original server matching boundary. |
| Founder preview | Existing Profiles and Guardian entry points, plus the signup rehearsal. Uses the DRAFT/DEMO fixtures, local results and simulated Send. Protected Add and signup previews do not open native camera, clipboard or share sheets. Local rotation changes the sample QR only. Founder Scan retains the guarded capture path. |

`SOURCE/lib/dev/zyra_draft_local_code_page.dart` is the shared presenter;
`zyra_request_tab_pill.dart` shares the Journey requests pill, and the title
uses `ZyraTabTitle`. `zyra_known_person_code_content.dart` owns the
camera lifetime. The camera accepts only an unmodified `ZYRA-` code with
five groups of four uppercase hexadecimal characters. Bad payloads show the
two-second hint and never open a URL. Manual entry retains its existing code
and sample alias handling. The timed preview sent state retains
the 14-day wording from Guardian rules DOC-ZYRA-0290 V5 and the 12 November
time-rules brief. Ordinary sent state does not claim an expiry before the
server change.

Rotation uses the shared LOCK 28 confirm sheet and the existing
`zyra_rotate_my_personal_code(p_role_context)` contract. An account change
invalidates pending actions and a late refresh cannot restore a replaced
QR. Cancel leaves the code and requests in place. The code page maps the
exact `too_many_code_checks` server error; an empty successful lookup stays
not found. Only line 106 owns the server signal. No migration, service
deployment, live service calls or device installation were performed.

**13 November, Q139 / OA-ZYRA-317.** From the reissued V3 brief
(DOC-ZYRA-0477), spec V4 §0 and §0b (DOC-ZYRA-0343), the LOCK record and
prototype V226, ordinary Share sends “Here’s my ZYRA Code. Enter it in ZYRA
to send me a request:” followed by a newline and the plain code, with the
subject “My ZYRA Code”. Founder demo sharing retains its sample wording.
Copy and QR use the plain code. Lines 108 and 109 own the link work.

Q139 verification covered both ordinary Add roles, Founder sample sharing,
exact subject and body, plain QR and clipboard values, and raw validation
at the native and injected scanner entry points. The 151 focused tests and
six LOCK 9 visual widget cases passed. `flutter analyze --no-pub` was clean.
The camera and share sheet were checked through their platform test doubles.
The full test run matched 38 recorded baseline failures. Two additional
failures used non-hex camera fixtures and passed when replayed with valid
grouped codes. See the 13 November task note for the run totals.

Verification uses local fake camera, share, clipboard and RPC calls, plus
the ordinary and Founder app routes at 430 × 932 and 375 × 667. The
prototype's drawn QR is a reference for layout; the app generates a QR that
was decoded from the screenshots. See
`REPORTS/EVIDENCE/LINE105_2026-11-13/` and the 13 November line 105 task
note for the source comparison, results, and independent review. Fable and
the ZYRA design chat retain their separate handover review.

### 13 November follow-up — Line 105 request safeguards

Add and Scan now pass one lookup guard from `zyra_draft_local_code_page.dart`
through their callers to `zyra_wali_link_service.dart` and
`zyra_discovery_service.dart`. It binds the exact entry, attempt, account
generation, route and visible Their code view. An edit, cover, tab change,
app interruption or timeout retires the attempt. Its reply cannot publish a
result, record an outcome event or clear a newer check.

On signed-in ordinary Add, Check recognises a manually entered eight-digit
hex invite and offers the existing invite screen with the code filled in.
The member still presses Check there. A manual personal-code check that
returns an authoritative empty result can offer the same screen with a blank
field. Scan and camera entries do not offer it; edits and new checks clear
it. In the ordinary Founder Guardian demo, Send simulates a request only
after the visible relationship is selected. Detached and signup fixtures
keep their existing local behaviour.

Verification: `flutter analyze --no-pub` reported no issues and 150 tests
passed in nine affected suites, including caller and camera lifetime,
Founder fixtures, the shared code page, signup, invitation reuse, Guardian
capacity, known-person matching and the link service. Tests used local fake
transport and camera. This follow-up made no server or Line 96 Developer
title changes and did not run on a device.

---

## Historical V2 handover

ZYRA Code page — queue 30, LOCK 9 V2

Built 30 October 2026 from `PRODUCT/APPROVED/CODE_PAGE/BRIEFS/BUILD_BRIEF_2026-10-30_V2.md`,
`RECORD/CODE_PAGE_SPEC_CURRENT_VERSION_V2.md`, `RECORD/LOCK_RECORD.md` and all nine `MASTERS/*.png` in that feature folder.
The Founder locked “all three”. This is a local Founder-preview implementation; ordinary member sign-in remains the old
app until OA-ZYRA-317. No native build, phone installation, upload, migration, real invitation or account link occurred.
Fable verification and Founder acceptance remain separate.

## Current behavior and live files

- `SOURCE/lib/dev/zyra_draft_local_code_page.dart` owns the shared camera frame, five boxes, Check code and result card.
  The single hidden field filters uppercase ASCII letters/numbers and accepts exactly twenty characters. A short input
  shows “Enter all 20 characters.” The active box has the gold edge; Check code stays enabled when empty. Results contain
  an initial, first name and role only. Scan has no View profile or consent action. Add pages show Send request and then
  the locked Request sent text; those actions change widget state only.
- `SOURCE/lib/dev/zyra_draft_local_code_aliases.dart` translates explicit fictional presentation aliases to unchanged
  canonical DRAFT/DEMO fixtures. Unknown twenty-character values show the existing not-found copy without calling any
  reader. Only complete exact known canonical fixtures or their explicit formatted aliases adapt on paste/scan; URIs,
  unknown suffixes, oversize paste and real codes cannot become a known local record through truncation.
- `SOURCE/lib/dev/zyra_draft_code_entry.dart` retains the exact canonical DRAFT resolver and caller-owned Scan admission.
  Its facade passes only first name and Seeker role to the shared page. The old onViewProfile constructor argument stays
  source-compatible but the locked card exposes no action that can invoke it.
- `SOURCE/lib/screens/wali/zyra_code_screen.dart` selects this page only for a requested local adapter or signup preview.
  Add a Guardian uses the existing local owner/session/account/role/overlay guards. Guardian sign-up Add a Seeker uses
  the existing requested-preview authorization. `_lockedLookup` passes only canonical fictional fixtures to the supplied
  local callback or existing demo resolver. No local failure falls through to ordinary service readers or mutations.
  Copy and Share retain their local explanatory notices; QR changes local presentation only. The existing DEV skip
  remains guarded. Superseded signup-only composition/style branches were removed; ordinary member code UI is retained.
- `SOURCE/lib/widgets/zyra_known_person_code_content.dart` retains `ZyraCodeCapture` and all native route/lifecycle,
  one-result and disposal guards. One optional unavailable-message parameter lets the new caller show the locked
  “Camera is off — enter the code below”; existing callers retain their prior text.

Scan is reached through Profiles → ••• → Scan. Add a Guardian uses the Seeker Guardian page's plus control. Guardian
signup reaches Add a Seeker after responsibilities. These pages deliberately do not resume from saved leaf checkpoints;
the capture tests enter through the actual taps. Local Add/signup retain their no-native-camera path. Scan activates the
existing guarded inline camera by tapping its frame; tests use no camera unless an explicit guarded fake is supplied.
The frame and input remain together while typing. The later Phone access work stays in its own queue line.

## Alias adapter and disclosure boundary

The initial preflight identified that canonical fictional codes do not fit twenty boxes. The parent reviewed the exact
LOCK and confirmed a presentation-only fixture adapter is routine implementation of its approved found/sent behavior.
No spec, LOCK, canonical resolver, production parser or product rule was changed, and no short-input exception was added.

| Context | Twenty-character master alias | Exact existing canonical sample | Rendered substitution |
|---|---|---|---|
| Scan | `7K2MQ9TD4HXA2B8C5E1F` | `ZYRA-DRAFT-SARA` | Sara replaces sample Yusuf |
| Add a Guardian | same alias, scoped to this context | `ZYRA-DEMO-GUARDIAN-IBRAHIM` | Ibrahim replaces sample Hassan |
| Add a Seeker | same alias, scoped to this context | `ZYRA-DEMO-SEEKER-ADAM` | Adam retained |

The Scan table also explicitly maps `DRAFTAMIRA0000000000` → `ZYRA-DRAFT-AMIRA`, `DRAFTAISHA0000000000` → `ZYRA-DRAFT-AISHA`, `DRAFTMARYAM000000000` → `ZYRA-DRAFT-MARYAM`, `DRAFTHANA00000000001` → `ZYRA-DRAFT-HANA`, `DRAFTNOOR00000000001` → `ZYRA-DRAFT-NOOR`, `DRAFTZAINAB000000000` → `ZYRA-DRAFT-ZAINAB`, `DRAFTSAFIYA000000000` → `ZYRA-DRAFT-SAFIYA`. The
machine manifest records every pair. Each contains a non-hex letter. Tests use the actual `ZyraPersonalCode.fromRow`
`code` key, reject bare and `ZYRA-XXXX-…` forms, and include a valid production-hex positive control. Production service
methods themselves forward raw input, so parser rejection is supplementary evidence: the actual local dispatch boundary,
not a downstream parser, prevents live lookup. Actual caller tests deny network clients and observe zero live readers,
link callbacks, telemetry and invitation-revision changes.

## Lifetime, accessibility and feedback

Lookup completions and retained buttons bind an input revision and caller overlay epoch. Editing, cover/uncover,
backgrounding, rebinding, disposal and owner revocation prevent stale identity or sent state. A throwing owner/epoch
fails closed. Inactive-only permission prompts retain the camera session; hidden/paused/detached invalidate it, and an
old capture cannot revive. The shared guarded camera remains the transport owner.

The boxes expose one “ZYRA Code, 20 characters” field. At 320 × 568 and 200% text, pages scroll, controls grow/wrap,
letter rendering scales within the boxes, and the camera frame shrinks before the input area. Enabled taps use
`ZyraTapFeedback`; Material's duplicate feedback is disabled, and rejected retained callbacks cancel shared feedback.
One enabled Check tap emits one pulse at the supplied level; Off emits none. The slow scan line uses the app's existing
`disableAnimations` or `accessibleNavigation` policy, plus TickerMode/current-route/resumed checks; quiet motion holds it
still. It performs no haptic or service work.

## Verification and evidence

The final combined run passes 249 distinct cases across sixteen suites: the shared local page (26), canonical Scan
facade, actual Add caller, signup boundary/process, Browse/retained routes, original known-person/member code paths,
existing camera/caller lifetime, demo fixtures, LOCK2 Main Guardian guards, shared haptic parity, LOCK8 Guardian tabs
and the three LOCK9 capture cases. The command uses a name filter excluding only the three reproduced starting-code
cases below. Full Flutter analysis is clean; Flutter 3.44.2, five SDK pins and direct/nested exec-denial proofs pass.
The unfiltered full repository suite is not claimed to pass.

| Additional starting-code failure, reproduced on exact `600f5393eb62fe4f625fd17a60c62c0f29cb76a5` | Scope |
|---|---|
| first held bar touch removes cue before breathing false | `browse_options_menu_test.dart` |
| first held bar touch removes cue before breathing true | same suite |
| Guardian Help uses original FAQ and returns to Settings | `zyra_retained_route_reuse_test.dart` |

For this bounded proof the primary read exact Git objects without a Git history command, held current bytes in memory,
temporarily restored three behavior files and two original tests, ran only those three cases, and restored every current
file byte-for-byte in `finally`. The Guardian Help assertion still expects the old Guardian Profile presenter; unchanged
navigation/source hashes and the three failures are in the JSON. Written refusal: unrelated Browse/Help repairs exceed
LOCK9 and remain OA-ZYRA-316. The five earlier starting-code failures in daily Task14 remain open and were not rerun or
counted as passing. UI gate: PASS-WITH-FINDINGS, zero critical/high, five medium and 337 low; the older heuristic checker
reports 114 heuristic findings, including existing named-constructor/export false positives, and no broken imports. These are not substitutes for the clean analyzer and compiled tests; unrelated checker/governance
repairs are refused under this row and remain with Fable/OA-ZYRA-316/313/314.

The three obsolete local UI suites moved to `/Users/shakeelahmad/_to_delete/ZYRA_LOCK9_CODE_PAGE_2026-10-30/retired_tests/`
and were replaced with tests for the locked disclosure/lifetime boundaries. Their removed View/Reset/Enter-code and
signup motif assertions are not reported as kept passing cases. Original ordinary-member code/lifetime suites remain.
Other changed fixtures update only this feature's field/action keys, removed Scan age/city/profile navigation, and the
replaced signup styling. New coverage is in `SOURCE/test/local_code_page_lock9_test.dart` and
`SOURCE/test/visual/lock9_code_page_capture_test.dart`.

Nine actual 1290 × 2796 renders with the master names are in `PRODUCT/APPROVED/CODE_PAGE/BUILT/`, plus
`MASTER_BESIDE_BUILD.png` containing all nine master/build pairs. Every pair was visually inspected, including gold
button fills, active/neutral boxes, initials, result states, spacing and reachable controls. No small arrows are present
in these masters. Exact gold is #E8C98A. Final physical gold-button bounds match every master, including both Send buttons. The final two-pixel Send-gap adjustment was recaptured in all nine images and re-analyzed cleanly. The rounded prototype phone edge and drawn icon glyphs differ from actual shared
app rendering. Small font/line-height and result wrapping differences remain recorded in `comparison.json`; they do not
omit copy or add an action. These inherited differences stay with the designer/Fable under OA-ZYRA-325; no global
safe-area or glyph redesign was invented. No approved master or baseline was overwritten.

Local `REPORTS/EVIDENCE/LOCK9_CODE_PAGE_2026-10-30/` contains JSON, screenshots if required, and BUILD.json with the exact
source commit, Flutter version, headless-test mode/target and UTC timestamp. It has no app binary, copied source or
credentials. Code-size measurement is recorded in DOC-ZYRA-0284 and daily Task15. No server migration exists for this row.
Next owner: Fable/design chat independently verify the nine pairs; real service wiring remains OA-ZYRA-317.
