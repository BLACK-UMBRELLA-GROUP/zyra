---
id: AS-BUILT-ZYRA-LOCK34
type: HANDOVER
status: CURRENT
feature: SIGN UP
purpose: Current as-built LOCK 34 sign-up, including queue lines 121 and 127
links: [DOC-ZYRA-SIGNUP-V2, DR-ZYRA-355, OA-ZYRA-317, OA-ZYRA-325, OA-ZYRA-381, AD-AIOS-115, AD-AIOS-147]
owner: Codex
---

# Sign up — as built

## Current state — line 127, SIGN_UP V2

The Founder preview now lets an unverified sample member look around instead of
showing the old full-page gate. A Seeker sees verified candidates' first names,
ages, nationality and ethnicity. Their surnames and towns are absent; Location
reads “Verify to see”. A Gaussian blur with sigma 14 is clipped to each peer
photo frame, including the details-card avatar and static photo/video pages.
The ivory photo note is on every card page. The details card alone offers
“Verify to request a Journey”; per answered Q201, photo pages keep the normal
five-icon navigation and omit that request action. The member's own photos are
never passed through this blur. The sample browse model excludes unverified
candidates from everyone else's visible list.

The unverified Seeker's Guardian tab withdraws linked people and shows only
the Add a Guardian card. Its card and + action open the local identity check.
The Add a Guardian setup step replaces the code/share state with the approved
verify card and Verify now action. A Guardian can browse Network using initials,
age, nationality and ethnicity; the town is hidden and Introduce/Connect open
the identity check. Guardian Network has no photos to blur. An unverified
Guardian's Seeker name is pending locally and is exposed as linked only after
the sample verification state becomes true.

`ZyraOneJourneyConceptShell` owns the preview verification flag, role, page
and action guards. `ZyraBrowseDesigns` renders the shared photo pager and
verify pill; `zyra_one_journey_browse_designs.dart` forwards the flag. The
Guardian card, setup preview and Network presentation receive that flag from
the shell. `DraftProfile.verified` and the Guardian Network candidate filter
are sample-data boundaries, not server enforcement. All gated actions reuse
the existing local identity-check entry; stale or unauthorized callbacks fail
the shell's current-action guard. The Developer fixture is admitted only by
the existing Founder preview access control; this line adds no public toggle.

Live files added or changed for line 127: `SOURCE/lib/dev/zyra_one_journey_browse_designs.dart`,
`zyra_one_journey_concept_shell.dart`, `zyra_one_journey_guardian_cards.dart`,
`zyra_one_journey_guardian_tabs.dart`, `zyra_signup_preview.dart`,
`zyra_signup_preview_controller.dart`, `zyra_view_request_draft_model.dart`,
`SOURCE/lib/widgets/zyra_browse_designs.dart`, `zyra_guardian_add_card.dart`,
and the focused tests `SOURCE/test/line127_unverified_preview_test.dart`,
`line121_signup_preview_controller_test.dart`, `zyra_developer_panel_entry_test.dart`,
`visual/lock8_v9_network_monogram_test.dart`, and
`visual/lock8_guardian_tabs_capture_test.dart`. The retired
`SOURCE/lib/dev/zyra_developer_unverified_gate.dart` was moved to
`~/_to_delete/LINE127_OLD_GATE_2026-11-24_0650UTC/`; no test references it.
The Network's chevron and verified check are drawn primitives because the
bundled test font rendered the old text symbols as missing-glyph boxes.

The preview uses invented, in-memory data only. It does not fetch a protected
photo or grant verification, membership or a Guardian link. No schema,
migration, package, native host, server, payment or version changes were made.
The live data and authorization contract remains OA-ZYRA-381 with Fable;
real integration remains OA-ZYRA-317. Device and live-service observations
are PENDING. The ZYRA Claude chat owns design comparison, Fable owns document
verification, and the Founder alone approves.

Line 127 evidence is in `SIGN_UP/BUILT/LINE127/`: five 430 × 932 captures,
five focused rendered-text audit JSON files (51 runs, 34,747 painted pixels,
zero failures), task note, and a text `BUILD.json`. The protected analyzer,
focused tests and ordinary regression are recorded there. The protected
ordinary regression finished with 7,892 passes, 206 opt-in skips and zero
failures in 7m47s on the combined checkout; the disjoint line132 source/test
edit is excluded from this line's commit. The full four-setting
text audit is a hosted reporting job under line 143, not this local gate.
Implementation commit `ff8b484c997658a1bcd628ef8bb5b3334e0ebb54`
contains the app, tests, README and screenshot evidence; `BUILD.json` carries
that source SHA and the pinned Flutter 3.44.2/Dart 3.12.2 toolchain receipt.
Authority: SIGN_UP spec V2 and 22 November build brief, LOCK record and masters
s31–s35, Q198/Q201 answers, then this as-built record. The historical line 121
implementation below remains the source of the original sign-up/setup flow.

## Historical state — line 121, SIGN_UP V1

Line 121 implements the LOCK 34 V1 Apple/Google sign-up rehearsal and setup
in the admitted Founder preview. Its authority is DR-ZYRA-355, the 18 November
build brief, spec, LOCK record and 41 phone masters. Questions 166/167/170/172
are ANSWERED. Source work began only after line 123 committed and
SOURCE/lib/test/ios were clean at `1c5757c4`, 19 November 05:37:37 UTC.

The Founder opens Developer → Start sign-up. Splash leads to Welcome;
Apple comes first on iPhone and Google on Android. Seeker and Guardian have
their locked role-specific sequences, validation, identity rehearsal and
Account ready. Membership appears only after Seeker verification. Its CTA
uses the existing unavailable-checkout message. Preview Skip can bypass data
entry; it never starts a trial, payment or membership entitlement.

Finish setting up opens the complete existing Partner preferences editor
for a Seeker, then About you, Add a Guardian and All set. Guardian setup uses
About you then All set. The bar counts applicable option lights, using the
existing gender/conditional bank: initially 320 for male and 325 for female;
chapter 3 question 3 = No hides six, giving 314/319. The five separate Chapter 2
setup lights are outside this existing count. Partial light and hard-choice
changes save immediately to detached local drafts. Next works at any count.
Unanswered options remain in Profile → Partner preferences.

Pausing opens My ZYRA with Continue setting up and preserves the step and
role-specific About text. Completion requires traversal to All set; positioning
a fixture there cannot grant completion. The local own profile receives
validated name, age, gender, heritage, location, photo order and preference
choices. Guardian identity/About and Seeker preferences are separate. Clear
sample data restores the captured local baseline. Sign-out or owner loss
retires the rehearsal; this is in-memory sample state, not cross-launch storage.

At line 121, unverified hid Profiles/Network and protected profile shortcuts. Verify now
uses the matching role's rehearsal; a saved controller for the other role is
never reused. Incomplete setup blocks both ordinary and Ended Journey restart
requests with the locked message. New member and Everything materialize the
Setup unfinished flag; explicitly switching it off clears the card and gate.
The progress bar's long press uses the existing typed Developer admission.

## Live files and ownership

| File under SOURCE | Job |
|---|---|
| lib/dev/zyra_signup_preview_controller.dart | Role-specific steps, validation, pause/resume and completion |
| lib/dev/zyra_signup_preview.dart | Locked cards, fields, searches, photos and local actions |
| lib/dev/zyra_signup_preferences_preview.dart | Nested existing editor and persistent n/N continuation bar |
| lib/dev/zyra_developer_unverified_gate.dart | Retired by line 127; historical line 121 gate only |
| lib/dev/zyra_one_journey_concept_shell.dart | Entry, controller lifetime, local profile projection, dashboard and request gates |
| lib/dev/zyra_request_account_session.dart | Guarded role-local profile/preferences/About application and baseline restoration |
| lib/screens/profile/compatibility_editors.dart | Opt-in partial-answer autosave; ordinary editor defaults unchanged |
| lib/models/zyra_developer_preview.dart | Optional Start sign-up value/action contract |
| lib/widgets/zyra_developer_title.dart | Freshly admitted Start sign-up bridge and progress long press |
| lib/widgets/zyra_developer_panel.dart | Start sign-up action |
| test/line121_signup_preview_controller_test.dart | Step, validation, count-independent completion and resume tests |
| test/line121_signup_preview_widget_test.dart | Rendered provider order, errors, swipe/CTA and local boundaries |
| test/line121_preference_setup_test.dart | Partial answers, hard choices, ownership, ordinary save and narrow layout |
| test/line121_signup_account_session_test.dart | Local account projection, role separation and restoration |
| test/zyra_developer_panel_test.dart | Existing panel remains safe when optional sign-up callback is absent |
| test/zyra_developer_panel_entry_test.dart | Real admitted shell entry, flags, profile, gates and resume regressions |
| test/visual/line121_signup_capture_test.dart | Opt-in actual app captures for 39 masters; shell test captures remaining 2 |

The shell pins a controller and lease to the existing account generation,
route and Developer bridge. Retained child routes may keep their local draft;
covered or retired callbacks cannot mutate it. Starting another rehearsal
invalidates the prior controller/lease. The nested editor shares only detached
snapshots with its caller. No authority is inferred from role, verification,
setup or plan sample flags. Non-Founder routes retain the existing admission.

## Verification and picture comparison

Implementation commit `b0911faaf95ecf1c43c95f9d8cbcbbdbd74f4bd0` passed the
pinned Flutter 3.44.2 full suite: **7,430 visible passes, 163 skips and zero
failures across 570 suites**, 455.540 seconds. Hidden setup/teardown events
are excluded. Six scoped sign-up/panel suites contribute 86 passes within that
full run; the opt-in capture suite contributes 39 of its skips. Final full
analysis reported no issues. Hosted [CI44476628733](https://github.com/BLACK-UMBRELLA-GROUP/zyra/actions/runs/44476628733) passed all three test shards and analyzers for that commit; `LINE121/CI.json` retains the receipt. The first diagnostic run found a platform-dialog
policy breach and two obsolete pre-121 panel expectations; those were corrected
before the successful run against the frozen final 17 source/test files.

Separate opt-in capture runs passed 39 presenter cases plus one actual-shell
case producing two screenshots: **41 screen captures**, with four labeled
master/build comparison images. Every master and capture is 1290×2796
(430×932 @3x), using actual shared app fonts/theme. Final image hashes match
`LINE121/MASTER_AUDIT.json`; `CURRENT41_REVIEW.json` proves 40 final images
match the reviewed pixels and the corrected gate was separately inspected.
All four retained pair columns match current capture pixels exactly.
`LINE121_CHECKS.json` records commands, source/input/image hashes and counts;
`BUILD.json` records code commit, Flutter version, mode and timestamp.

At 320×568 with doubled text, tests navigate first/last preference categories,
a question and its light control, and hit both setup-bar actions. Role,
membership, identity, name and About steps scroll to their primary action.
Setup headings scroll with content and the bar uses two rows. Normal 430×932
keeps its locked geometry. Two independent reviews covered state/permissions,
local isolation and final pictures. Root inspected preferences, both actual
shell states and the final gate comparison. No pixel-equality or physical
screen/VoiceOver acceptance is inferred.

The pictures retain existing shared foundations required by the brief:
`ZyraColors.cardSurface` and shadows, Syne wordmark, current title/nav/icon
metrics and bundled abstract sample portraits. The prototype master uses a
lighter solid card, different wordmark rendering and a seated-person fixture.
The identity screen includes the spec-required explanation under Do this later,
which its master omits. Error captures omit the prototype-only Demo hint.
These are recorded differences, not pixel-equality or device-acceptance claims.
Written refusal under this LOCK: do not redraw shared tokens/fonts or add new
photography to imitate those prototype fixtures.

## Boundaries, gaps and next owner

No server, authentication provider, identity provider or purchase operation is
added. Share my code uses the existing platform share action with the fictional
code; tests do not invoke a real share. This line changes no schema, migrations,
dependencies, native configuration or version. Old member onboarding remains.
Real integration remains with OA-ZYRA-317; Developer controls with OA-ZYRA-325.
Written refusal: this UI brief does not authorize live accounts, payments,
identity decisions or visibility writes.

Native build, installation, physical iPhone and VoiceOver observation are
PENDING under the separate Founder-present delivery. No line 98 attempt was
made. Fable/ZYRA Claude own the independent design/document comparison and
Founder acceptance; a tested commit does not supply that approval.

Authority: `RECORD/SIGN_UP_SPEC_CURRENT_VERSION_V1.md` states the product;
`BRIEFS/BUILD_BRIEF_2026-11-18_V1.md` states the build contract; this file states
implementation. Previous LINE121_PREFLIGHT folders remain historical questions,
not current blockers or completed-build measurements. README, queue 121,
planned-screen inventory and MAP accompany the completed handover.
