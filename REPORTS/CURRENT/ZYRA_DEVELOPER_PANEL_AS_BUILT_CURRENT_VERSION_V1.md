---
id: AS-BUILT-ZYRA-LOCK31
type: HANDOVER
status: CURRENT
feature: DEV_TOGGLES
purpose: As-built handover for LOCK 31 V2 Developer panel, queue line 123; includes line 96 history
links: [OA-ZYRA-325, OA-ZYRA-317, AD-AIOS-115, AD-AIOS-147]
owner: Codex
---

# Developer panel — LOCK 31 V2

## Current delivery — queue line 123, 19 November 2026

Built from `PRODUCT/APPROVED/DEV_TOGGLES/RECORD/DEV_PANEL_SPEC_CURRENT_VERSION_V2.md`
(DOC-ZYRA-0481), the LOCK record (DOC-ZYRA-0482), the 18 November V2 brief
and its V1 requirements. Questions 171, 173 and 174 are ANSWERED and are
recorded in spec §7.4. OA-ZYRA-325 owns this work. The approved sheet reuses
LOCK 28; no new master pictures were required by the design charter.

The panel opens from planned-app titles on the Seeker and Guardian sides,
including shared headings and retained account editors. The title inventory
is `PRODUCT/APPROVED/DEV_TOGGLES/BUILT/LINE123_BUILD/TITLE_INVENTORY.json`.
It records the title, side, route and source for each entry and identifies
shared hooks and titleless exclusions. Line 121 adds Start sign-up and
progress-bar long-press entry; its current record is
`PRODUCT/APPROVED/SIGN_UP/BUILT/AS_BUILT_CURRENT_VERSION_V1.md`.

### Controls and local behaviour

- **View as:** Seeker One, Seeker Basic, Guardian One and Guardian Basic.
  Role, plan limits, tabs, locks and upgrade prompts use local preview state;
  the real account and server plan stay unchanged.
- **Journeys:** Active and Ended counts, Sara/Maryam/Noor selection, and the
  app's nine preview stages in canonical order. Changing one Journey keeps
  the other Journey attempts and their progress. Existing local Accept,
  Decline, Cancel, End and restart rules remain in use.
- **Requests and Introductions:** existing Received, Sent, Past and Guardian
  Introduction controls use the existing sample presentations. An explicit
  zero is an empty sample selection; unset controls preserve the ordinary
  state.
- **My ZYRA:** All caught up, Typical day, New member and Everything use local
  preset state. Line 121 supplies the setup card and saved-step continuation
  for New member and Everything (Q171). Explicitly switching Setup unfinished
  off clears that card and gate.
- **Sign up:** Unverified shows the locked Profiles/Network gate and its typed
  local identity-verification route. It has no live finalizer or provider
  write. Setup unfinished blocks ordinary and restart requests with
  “Finish setting up your profile to start a Journey.” Start sign-up now
  opens the local LOCK 34 rehearsal. Its preferences save into the same
  caller-owned local profile draft; no member or server account is created.
- **Notices:** Seeker inactivity email states and Welcome back use LOCK 32.
  Both Guardian views hide the entire NOTICES section and cannot select an
  inactivity preview (Q174); no Guardian archive or role switch is invented.
- **Error pages:** Phone offline, ZYRA server down and Session ended use the
  shared error page, with its return action owned by the current preview.
- **Clear sample data:** clears local choices and restores the real account
  view. If the real membership is absent or unreadable, initial state and
  Clear use Seeker One samples and the exact line “Viewing as Seeker One ·
  real plan: none” (Q173). This grants nothing on the server.

### Ownership and isolation

The existing pinned account, project, server role claim, exact session
lifetime and account-generation checks remain the authority. A title tap
refreshes proof before the host presents its owned sheet. Each action
requires the current sheet or preview route. Nested account titles require
the exact preview bridge and Navigator owner. Temporary route coverage does
not grant a covered callback permission to act. Proof loss, account changes,
App Lock and backgrounding withdraw access.

The ordinary subtree remains mounted while a local sample shell is shown.
This retains ordinary state across sample activation and Clear without
reissuing its reads. A detached working model protects colliding fixture
identities, and Clear restores the captured native local baseline, including
conversation state. Preview role or plan values never merge into AppState
or server membership. Non-admin titles and member behaviour retain their
existing access rules.

The main implementation is in `SOURCE/lib/widgets/zyra_developer_title.dart`,
`widgets/zyra_developer_panel.dart`, `models/zyra_developer_preview.dart`,
`state/zyra_developer_samples.dart`, and
`dev/zyra_one_journey_concept_shell.dart`. Shared title hooks span the
presentation files listed in the inventory. The typed local verification
entry is in `screens/onboarding/identity_verification_screen.dart`; the
shared unverified gate and inactivity email presentation are in `dev/`.
Paths after the first are relative to `SOURCE/lib`.

### Verification and remaining dependency

Code commit `8de131596c51776650c03e30da24b786d65e77e2` (OA-ZYRA-325). The protected pinned Flutter 3.44.2
run passed **368 tests across 25 suites, zero skips and zero failures**;
analysis reported no issues. Scope includes panel controls, all four
presets, proof lifetimes, App Lock, release safety, Journey models,
IDV isolation, nested profile editors, Photos and Help reuse. Temporary
proof suspension hides samples while retaining the local page for a
successful recheck of the same session. Covered callbacks remain inert;
true owner loss is terminal.

Seven captures cover normal phone presentation and 2x text at 320×568 and
430×932. All controls scroll into hit-testable positions without layout
exceptions. The inventory traces 82 original titles and six added surfaces.
Public checking reviewed 68 lexical hits: 66 unchanged lines and two
harmless code syntax/name hits. Gitleaks found zero leaks in changed files.
Independent review verified actual preview headings and ownership guards.
The final isolated snapshot also checks all five inactivity return actions,
the Circle wrapper permission contract and legacy identity mode-change
warnings. Typed panel proof denial remains terminal.

`PRODUCT/APPROVED/DEV_TOGGLES/BUILT/LINE123_BUILD/` holds BUILD metadata,
checks, reviewed public scan, master audit, inventory and screenshots.
No compiled app or source copy is evidence. Remote CI is checked after
push and reported with the task result.

No migration, backend change, dependency upgrade, native build or phone
installation is part of this task. Founder iPhone verification remains a
separate delivery step. The measurements above belong to line 123.
Line 121's handover records its later sign-up flow, setup card, saved-step
continuation and progress-bar entry, with their separate tests and captures.

## Historical line 96 delivery and follow-up — 12–13 November 2026

The notes below describe the earlier V1 delivery and its verification.
The line 123 sections above supersede V1 title gaps, control limits and
missing-membership behaviour. Historical counts are not line 123 results.

Line 96 implements LOCK 31 and the Q129 answer. The source design is
`PRODUCT/APPROVED/DEV_TOGGLES/RECORD/DEV_PANEL_SPEC_CURRENT_VERSION_V1.md`,
its 12 November brief and LOCK record, and the private archived prototype
V204. The sample history and ended actions reuse the presentations verified
for lines 95 and 93.

### Entry and authority

The ordinary signed-in Seeker taps the visible heading. The five main tabs
use their existing titles where present. Profiles is a full-bleed card in
the ordinary app and gains a heading only for this Founder session. Journey
requests, Ended Journeys and sample Introductions use their own headings.
Explicit hooks cover the actual ordinary Settings, Scan, profile editing
and Preview, quick check, preferences, compatibility, safety reports, Help, Journey detail, Timeline and Seeker Circle headings. Some V204 screens have no matching ordinary route
or heading. The protected opt-in Founder preview remains a separate entry
path. Those remaining title surfaces are referred to the ZYRA design chat
under OA-ZYRA-325.

The panel verifies the SDK project, token issuer, pinned account, exact
session lifetime and account generation against a fresh Auth response.
Its proof and narrow Auth observer stay mounted above App Lock. The ordinary
Seeker host and Navigator still unmount. The observer can withdraw access
or discard choices; it cannot grant access or route the protected Founder
preview. The panel's own refresh responses and transient errors are kept
separate from legacy authorization routing.

Tapping an already available heading keeps the sample view mounted while
the same account and session retain their current, unexpired proof. During
the check, the SDK treats the original session as expired 30 seconds before
the token expires. The Developer sheet opens only after the refresh succeeds
and the tapped heading is still current. Locking the app, leaving the
foreground, proof expiry, or a failed or timed-out refresh withdraws sample
presentation and retires outstanding action leases. The host removes its
own Developer sheet route.
A successful fresh check of the same account and session restores retained
choices. A token event alone cannot restore them after suspension. App
sign-out or account replacement clears choices synchronously through the
account memory reset. SDK session replacement and a fresh server claim
denial discard choices even while the Seeker host is absent.

### Local sample data

**Clear sample data** removes the in-memory choices and leaves the panel
open. An explicit selector choice replaces its own view, including zero.
When Active or Ended is unset, actions add sample rows alongside ordinary
rows, counts and retry states. Only real admitted identities enter existing
live reads. New samples use verified spare capacity; a full real slot is
never a replacement option. A failed capacity read preserves the last
known display but blocks new sample admissions until a successful read.
Sample actions make no server writes and send no product events.

Sample restart uses Seeker One, the five most recent sample Ended attempts
(including locally removed attempts for ranking), a 24-hour wait and a free
place. Its Sent request expires after 30 days; the original Ended row
survives. This overlay keeps live Ended identities out of sample ranking and
actions. Past applies the Line 95 / Q128 waits to outgoing sample history
from the date each request moved to Past. Cancellations do not add a step;
starting a sample Journey resets that pair's streak. SERVER 1 still owns
real restart, readiness closure and real request history (OA-ZYRA-317).

| Source | Ownership |
|---|---|
| `widgets/zyra_account_session_host.dart`, `widgets/zyra_developer_title.dart`, `services/zyra_session_router.dart`, `screens/home/home_shell.dart` | Account lifetime, ordinary Seeker admission, foreground headings, sheet ownership and sample navigation |
| `widgets/zyra_developer_panel.dart`, `widgets/zyra_confirm_sheet.dart` | LOCK 31 controls and shared sheet surface |
| `state/zyra_developer_samples.dart`, `screens/connections/zyra_sample_activity.dart` | Local data, capacity, sample cards and actions |
| `screens/home/seeker_dashboard_screen.dart`, `widgets/zyra_quiet_dashboard.dart`, `widgets/zyra_my_zyra_design_kit.dart` | My ZYRA counts, places, Needs you and direct links |
| `screens/connections/connections_screen.dart`, `screens/profile/past_journeys_screen.dart`, `screens/wali/seeker_wali_tab.dart`, `dev/zyra_request_activity_presentation.dart` | Ordinary Journey and Introductions, archive, Seeker Guardian access and grouped request presentation |

Paths in the table are relative to `SOURCE/lib`. The follow-up also updates
`main.dart` and `services/zyra_account_state.dart` for lock and account reset,
`services/zyra_developer_access.dart` for proof,
`services/zyra_journey_service.dart` for raw occupied-place counts,
`screens/wali/seeker_guardian_designs.dart` for the combined display,
and `dev/zyra_one_journey_options.dart` and
`dev/zyra_view_request_draft_model.dart` to reuse the Ended menu and Past
wait thresholds. Both READMEs and the mocked entry and sample suites were
updated.

The title refresh correction updates `services/zyra_developer_access.dart`
and `widgets/zyra_developer_title.dart`. Its widget regressions live in
`SOURCE/test/zyra_developer_panel_entry_test.dart`.

### Verification and ownership

Original delivery (Flutter 3.44.2): tests used a mocked signed-in Seeker and synthetic Supabase
responses. Independent Codex review checked auth lifetime, sample write
paths and the phone-sized panel against V204. The rendered sheet differs
slightly in type weight and vertical position. Evidence is in
`REPORTS/EVIDENCE/OA-ZYRA-325_LINE96_2026-11-13/`.

Analyzer clean. Full-suite comparison, with the affected route assertion
rerun, shows 7,212 passed, 122 skipped and 38 failures matched to baseline
by suite and test name. The starting baseline had 7,180 passed, 122 skipped
and 42 failures. The final title and sample changes also passed 95 focused
tests. The full comparison and evidence scope are filed with the images.
Follow-up, 13 November 2026: `flutter analyze --no-pub` reported no
issues. `flutter test --no-pub test/zyra_developer_panel_entry_test.dart`
passed 23 tests, including real App Lock widget teardown with mocked local
authentication, retired and retryable refreshes, sign-out while locked,
claim denial, and replacement followed by a return to the original
session. A second test run passed 257 across the following suites:

- `zyra_developer_panel_test`, `zyra_developer_samples_test`,
  `developer_controls_release_safety_test`, `zyra_developer_access_test`,
  `zyra_developer_access_concurrency_test`, `zyra_developer_route_gate_test`,
  `zyra_account_state_test`, `zyra_app_lock_lifecycle_test`,
  `auth_gate_lifetime_test`.
- `line93_time_rules_test`, `view_request_draft_past_requests_test`,
  `past_journeys_screen_test`, `seeker_wali_tab_truth_test`,
  `guardian_permission_circle_controls_test`, `seeker_dashboard_screen_test`,
  `zyra_journey_profile_hydration_test`, `one_journey_full_capacity_model_test`,
  `one_journey_full_capacity_flow_test`.

Suites are Dart files in `SOURCE/test` run with `flutter test --no-pub`.
An independent read-only Codex review checked the proof and lease
boundaries, real-versus-sample row sources, and Line 93 / Line 95 parity.

Title refresh correction, 13 November 2026: both sample-title widget tests
reproduced the lost tap against `c0869e6` with the mock Auth response held
across a rendered frame. `flutter test --no-pub
test/zyra_developer_panel_entry_test.dart` passed all 27 tests after the fix.
The four added cases cover the actual sample Journey requests and Journey
headings, the 10-second timeout, and the original proof reaching the SDK
expiry cutoff during the wait. A late response leaves access suspended.
A fresh explicit verification of the same session restores the samples.
`flutter analyze --no-pub` reported no issues. A focused
`flutter test --no-pub` run passed 115 tests across these 12 suites:

- `zyra_developer_panel_entry_test`, `zyra_developer_samples_test`,
  `zyra_developer_panel_test`, `zyra_developer_access_test`,
  `zyra_developer_access_concurrency_test`, `zyra_developer_route_gate_test`.
- `zyra_internal_founder_policy_test`, `developer_controls_release_safety_test`,
  `global_hidden_dev_controls_test`, `zyra_app_lock_lifecycle_test`,
  `auth_gate_lifetime_test`, `auth_gate_recovery_test`.

Independent Codex review checked the title refresh proof and expiry path.

No migration or server change. Fable and the ZYRA design chat retain their
handover review. Protected iPhone verification was outside this follow-up.

Existing ordinary screens may still withdraw their own view after a
retryable SDK Auth stream error and need to be reopened. Panel choices
remain retained for fresh verification. This follow-up preserves ordinary
Auth guards; the previously filed title gaps remain with the design chat
under OA-ZYRA-325.
