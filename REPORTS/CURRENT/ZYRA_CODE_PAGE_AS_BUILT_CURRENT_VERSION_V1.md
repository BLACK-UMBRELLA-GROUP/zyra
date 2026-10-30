---
id: ASBUILT-ZYRA-QUEUE30
type: HANDOVER
status: CURRENT
feature: CODE PAGE
purpose: As-built LOCK 9 V2 local Code page, queue 30
links: [AD-AIOS-115, DR-ZYRA-231, OA-ZYRA-316, OA-ZYRA-317]
owner: Codex
---

# ZYRA Code page — queue 30, LOCK 9 V2

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
