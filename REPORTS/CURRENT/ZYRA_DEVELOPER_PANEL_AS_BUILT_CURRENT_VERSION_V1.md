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

`SOURCE/lib/services/zyra_developer_access.dart` owns a panel-specific proof.
It verifies the actual SDK project and token issuer, pinned user, account
generation, current session lifetime and Founder claim against the
`refreshSession` response. Token events alone cannot grant panel access.
The panel's own token refresh does not grant the older preview authority.
The ordinary Seeker shell, current route, selected tab and foreground
state bound title taps. Revocation or account change withdraws sample data
and dismisses the exact open sheet. Its place cap uses the verified plan
and falls to zero when no plan is confirmed.

## Local sample data

The sheet uses the shared ivory surface. **Clear sample data** removes the
in-memory choices. Sign-out clears them synchronously. Each selector
replaces its own view of the account data, and zero is a valid override.
The Received, Sent and Past defaults are empty before SERVER 1.
Ended and Introduction counts and the Active count come from the ordinary
account readers. The local actions use bundled sample people, including
Sara's 20 Past requests. Accept and capacity choices use the verified
place count. A sample request, Journey action or Introduction cannot write
member records or send a product event.

| Source | Ownership |
|---|---|
| `widgets/zyra_account_session_host.dart`, `widgets/zyra_developer_title.dart`, `services/zyra_session_router.dart`, `screens/home/home_shell.dart` | Account lifetime, ordinary Seeker admission, foreground headings, sheet ownership and sample navigation |
| `widgets/zyra_developer_panel.dart`, `widgets/zyra_confirm_sheet.dart` | LOCK 31 controls and shared sheet surface |
| `state/zyra_developer_samples.dart`, `screens/connections/zyra_sample_activity.dart` | Local data, capacity, sample cards and actions |
| `screens/home/seeker_dashboard_screen.dart`, `widgets/zyra_quiet_dashboard.dart`, `widgets/zyra_my_zyra_design_kit.dart` | My ZYRA counts, places, Needs you and direct links |
| `screens/connections/connections_screen.dart`, `screens/profile/past_journeys_screen.dart`, `screens/wali/seeker_wali_tab.dart`, `dev/zyra_request_activity_presentation.dart` | Ordinary Journey and Introductions, archive, Seeker Guardian access and grouped request presentation |

Paths in the table are relative to `SOURCE/lib`. Other changed screen files
attach their title hooks in place. The commit lists the complete paths.

## Verification and ownership

Flutter 3.44.2. Tests use a mocked signed-in Seeker and synthetic Supabase
responses. Independent Codex review checked auth lifetime, sample write
paths and the phone-sized panel against V204. The rendered sheet differs
slightly in type weight and vertical position. Evidence is in
`REPORTS/EVIDENCE/OA-ZYRA-325_LINE96_2026-11-13/`.

Analyzer clean. Full-suite comparison, with the affected route assertion
rerun, shows 7,212 passed, 122 skipped and 38 failures matched to baseline
by suite and test name. The starting baseline had 7,180 passed, 122 skipped
and 42 failures. The final title and sample changes also passed 95 focused
tests. The full comparison and evidence scope are filed with the images.
No migration or server change. Server-owned test records remain with Fable
under SERVER 1 and OA-ZYRA-317. Fable and the ZYRA design chat retain their
handover review. Protected iPhone verification is pending Shakeel's exact
device request.
