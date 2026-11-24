---
id: DOC-ZYRA-HELP-SAFETY-AS-BUILT-V1
type: HANDOVER
status: CURRENT
feature: LOCK 37 HELP AND SAFETY
purpose: Founder preview implementation and verification of Help and safety pages
links: [DR-ZYRA-366, Q200, Q203, Q204, AD-AIOS-115]
owner: Codex
---

# Help and safety — as built — 24 Nov 2026

## Current state

LOCK 37 is implemented in the local Founder preview for Seeker and Guardian, both plans. Settings opens Contact support, Advanced, and Privacy & data. Contact support requires a selected topic and 10–1000 message characters before Send; the optional screenshot row changes to the approved added state. Send opens Message sent. The existing profile Report form now opens Report sent, with Done and Block too paths. Advanced opens Download my data and Delete my account. The data request changes to Requested in local preview state; its Seeker and Guardian contents differ as locked. Delete opens the confirmation sheet; Keep cancels, Delete opens the closed page, and Close exits the preview through the same host exit callback as Sign out. Privacy & data shows the three Q203 prototype toasts and opens the data page. The App Store subscription row uses the fixed Apple subscriptions destination.

## Authority and design decisions

- DR-ZYRA-366 / Founder 22 Nov: “Help & safety pages”, Decision 7 “A · 30 days to change mind”, “Lock and queue”; LOCK 37 spec V1 and build brief V1; masters h01–h13 plus h03b, h07g and h08g.
- Q200: no in-phone Back control; the existing iOS edge swipe returns. The existing LOCK 14 token contrast check governs this line.
- Q203: legal rows show exact approved prototype toasts while member-app hosted documents are absent. Follow-up belongs to Fable under OA-ZYRA-304.
- Q204: the locked Journey fact icon is Material `people_outline`, gold, after re-rendered h07–h10 masters; no heart exception.
- All support, report, export and deletion outcomes are local sample states. No server-side inbox, report queue, export, soft deletion or restoration was built.

## Live files and boundaries

| File | Job |
|---|---|
| `SOURCE/lib/dev/zyra_help_safety_preview.dart` | LOCK 37 page content and local contact form state. |
| `SOURCE/lib/dev/zyra_one_journey_account_presentation.dart` | Settings Contact support action and row. |
| `SOURCE/lib/dev/zyra_one_journey_concept_shell.dart` | Route ownership, guarded callbacks, sample data request/closure state, preview exit, legal messages and App Store action. |
| `SOURCE/lib/dev/zyra_draft_browse_utility_presentation.dart` | Optional Report submit callback, active only where the shell supplies it. |
| `SOURCE/test/zyra_help_safety_preview_test.dart` | Contact, screenshot, Guardian export, deletion and report state tests. |
| `SOURCE/test/browse_options_menu_test.dart` | Actual shell Report sent and closed-page preview-exit routes. |
| `SOURCE/test/founder_launch_review_test.dart`, `SOURCE/test/whole_app_settings_destinations_test.dart` | Updated return and Settings destination coverage for the new locked routes. |
| `SOURCE/test/journey_block_hide_v2_guard_test.dart`, `SOURCE/test/visual/lock16_journey_block_hide_v2_test.dart`, `SOURCE/test/visual/lock22_report_v2_capture_test.dart` | Existing Report/Block/Hide assertions updated for the enabled preview submit action. |
| `SOURCE/README.md` | Founder preview scope and focused test entry. |

The shell owns route and account freshness. The contact widget owns only unsent form values. A stale route/account cannot submit, request data, close, or show an App Store failure notice. The host owns the preview exit; the shell does not sign out the real account. Sample request and close times last only for the shell lifetime. No migration or persistent data change exists.

## Checks and evidence

- Protected whole-project analyzer: **PASS**, `node tooling/no_git_driver.mjs flutter analyze --no-pub` (24 Nov, final run).
- Focused changed-screen/route tests: **PASS** — `test/no_heart_icons_test.dart`, `test/zyra_help_safety_preview_test.dart`, `test/browse_options_menu_test.dart`, `test/journey_block_hide_v2_guard_test.dart`, `test/whole_app_settings_destinations_test.dart`, `test/founder_launch_review_test.dart`, `test/visual/lock22_report_v2_capture_test.dart`, `test/visual/lock16_journey_block_hide_v2_test.dart` through the protected driver. The shell Close path has an additional focused pass after independent review.
- Scoped 430 × 932 real-font captures: eight direct page states under ignored `SOURCE/build/line130_capture/`; h02, h05, h06, h07 and h09 were visually compared with current masters. These are local screen checks, not a whole-app four-setting audit or native/device evidence.
- Protected ordinary regression: **PASS**, `node tooling/no_git_driver.mjs flutter test --no-pub` — 7,889 passed, 206 skipped, zero failures in 7:51. First run failed on the original heart/master conflict and old Report assumptions; Q204 and affected tests were corrected before the final run. An interrupted run after review is not a pass or failure claim.
- Independent review: two shell findings (closed-page exit path and stale post-await App Store notice) fixed before the final gate. No server, native build, phone install or device observation was performed.

## Open items and next owner

Fable owns OA-ZYRA-304: approve and publish member-app Privacy Policy, Terms and photo-privacy documents and supply their URLs; the current Q203 toasts remain until that separate locked contract exists. Server support inbox, report queue, export and deletion/restore work is outside this preview line and awaits its own approved contract. No other open implementation gap is claimed. Next queue line is selected by the coordinator after line 130 is BUILT.

## Dated log

- 24 Nov: Q200 preflight released; Q203 answered; Q204 replaced incorrect heart masters with `people_outline`. Implemented the sample-only pages, focused tests and shell routes. Final regression and commit recorded in the line 130 task note when complete.
