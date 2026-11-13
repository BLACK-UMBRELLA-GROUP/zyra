---
id: AS-BUILT-ZYRA-LOCK31
type: HANDOVER
status: CURRENT
feature: DEV_TOGGLES
purpose: As-built handover for queue line 96 and the Seeker Developer panel
links: [OA-ZYRA-325, OA-ZYRA-317, AD-AIOS-115]
owner: Codex
---

# Seeker Developer panel

Line 96 implements LOCK 31 and the Q129 answer. The source design is
`PRODUCT/APPROVED/DEV_TOGGLES/RECORD/DEV_PANEL_SPEC_CURRENT_VERSION_V1.md`,
its 12 November brief and LOCK record, and the private archived prototype
V204. The sample history and ended actions reuse the presentations verified
for lines 95 and 93.

## Entry and authority

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

Locking the app, leaving the foreground, or starting a fresh check
withdraws sample presentation and retires outstanding action leases.
Only the Developer sheet route owned by that host is removed. A successful
fresh check of the same account and session restores the retained choices.
A transient failure keeps them hidden; a token event alone cannot restore
them. App sign-out or account replacement clears choices synchronously
through the account memory reset. SDK session replacement and a fresh
server claim denial discard choices even while the Seeker host is absent.

## Local sample data

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

## Verification and ownership

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

No migration or server change. Fable and the ZYRA design chat retain their
handover review. Protected iPhone verification was outside this follow-up.

Existing ordinary screens may still withdraw their own view after a
retryable SDK Auth stream error and need to be reopened. Panel choices
remain retained for fresh verification. This follow-up preserves ordinary
Auth guards; the previously filed title gaps remain with the design chat
under OA-ZYRA-325.
