---
id: DOC-ZYRA-0127
type: GUIDE
status: CURRENT
feature: CODE AND TOOLS
purpose: ZYRA — Flutter Source
links: []
owner: ZYRA chat
---

# ZYRA — Flutter Source

Matrimonial platform for a faith community. Specs live in `../APP/`, decisions in
`../SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md`, session reports in
`../REPORTS/CURRENT/`. Read those before changing anything here.

## Device testing — THE CONFIRMED, CORRECT WAY (2026-07-19, hardened 2026-08-01)

Before running, export `ZYRA_DEVICE_ID` and (for PROFILE or DEBUG) `ZYRA_INTERNAL_FOUNDER_UUID` in your private shell environment. See the root `README.md` and `.env.example`; the script does not load an env file automatically. Actual identifiers are no longer stored in `run.sh`.

**Every AI session giving Shakeel run instructions must use this — and
only this:**

```
cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && ./run.sh
```

ONE LINE, joined with `&&` — corrected 2026-08-14. This block gave two
lines, which is two pastes and two Returns, and directly contradicted
CLAUDE.md §1, where the Founder confirmed the joined form twice on
2026-08-08 ("THIS IS THE CORRECT VERSION", then "THIS IS NEW TERMINAL
CODE"). Two sources of truth for the one instruction that has already
cost two sessions is exactly the failure CLAUDE.md exists to prevent.
CLAUDE.md is the source of truth; this file follows it.

`run.sh` defaults to a profile build (safe untethered) and prints what
to expect. `./run.sh dev` = debug + hot reload, cable must stay in.
Added 2026-08-01 after the debug-mode trap caught a second session —
documentation alone didn't prevent recurrence, so the safe mode is now
the default mechanically.

Raw equivalent, if the script can't be used:

```
flutter run --profile --flavor production --dart-define=ZYRA_INTERNAL_FOUNDER_ACCESS=true --dart-define=ZYRA_INTERNAL_FOUNDER_UUID="$ZYRA_INTERNAL_FOUNDER_UUID" -d "$ZYRA_DEVICE_ID"
```

- `ZYRA_DEVICE_ID` is your local intended device identifier (confirm with
  `flutter devices` if it changes).
- **`--profile` is mandatory for untethered testing.** Plain
  `flutter run` installs a DEBUG build; iOS kills debug (JIT) apps the
  moment the cable is unplugged and refuses to cold-launch them from
  the icon (white screen → instant close, every time, until
  reinstalled). This looked like a mystery crash for hours on
  2026-07-19. It is not an app bug. Never diagnose "crash after
  unplug" or "won't open from icon" without first asking which mode
  the build was.
- Profile builds: survive unplugging, launch from the icon like a real
  app, keep the DevNavOverlay Back/Home buttons (gated `!kReleaseMode`),
  no hot reload — replug and re-run to pick up code changes.
- Plain `flutter run` (debug, hot reload) is fine ONLY while the cable
  stays connected. Avoid iPhone Mirroring during a debug session — the
  two interfere.
- Full background: `../REPORTS/ARCHIVE/ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md` §7.

## Developer panel

The signed-in ZYRA Founder can tap a page heading across the planned Seeker
and Guardian preview to open **Developer** (LOCK 31 V2, queue line 123).
The panel verifies the pinned Founder account, project, server claim, exact
session lifetime and account generation. The sheet opens only after a fresh
check succeeds and the tapped title still belongs to the foreground route.
Covered or retired title callbacks cannot reopen it.

The four **View as** choices switch only local role, plan limits and locks.
Active sample Journeys use Sara, Maryam and Noor; the Journey and Stage
pickers open the chosen Journey at one of the nine canonical preview stages.
The existing request, history and Introduction selectors remain, alongside
My ZYRA presets, Seeker inactivity previews and shared error pages.
Guardian views have no NOTICES section. Samples use the existing local
presentations and actions, with no server writes or product events.

**Unverified** uses the ordinary Profiles or Guardian Network preview with
hidden town and surname, blurred member photos, and verification actions in
place of requests. Guardian linking waits for verification. These remain
local sample states; the preview cannot finalize live verification.
**Setup unfinished** supplies the Request a Journey gate only until line
121 supplies the setup card and continuation. Start sign-up also waits for
line 121; Everything omits the unavailable setup card. If real membership
is missing or unreadable, the approved start and Clear state are local
Seeker One samples, labelled “Viewing as Seeker One · real plan: none”.
No server membership is granted.

App Lock, backgrounding or a temporary verification failure withdraw sample
actions. A fresh check of the same authorized session restores retained
choices. Signing out, session replacement or loss of the server claim clears
them. **Clear sample data** resets the controls and restores the real view,
with the approved local fallback above when needed.

Run the mocked panel, state, entry and local verification regressions through
the protected driver with the pinned SDK:

```sh
node tooling/no_git_driver.mjs flutter test --no-pub test/zyra_developer_panel_test.dart test/zyra_developer_samples_test.dart test/zyra_developer_panel_entry_test.dart test/line123_preview_journey_model_test.dart test/line123_identity_panel_preview_test.dart
```

The [as-built handover](../REPORTS/CURRENT/ZYRA_DEVELOPER_PANEL_AS_BUILT_CURRENT_VERSION_V1.md)
records title coverage, evidence and final verification. This task has no
migration, native build, phone installation or delivery.

## Founder preview Help & safety

LOCK 37 adds Contact support, Report sent, Advanced, Download my data,
Delete my account and Privacy & data to the local Founder preview for Seeker
and Guardian. Contact, report, export request and account closure use sample
state only. The three legal rows show the approved preview messages; they do
not open hosted documents yet. The closed-page Close action exits the preview.
The focused checks are in `test/zyra_help_safety_preview_test.dart` and
`test/browse_options_menu_test.dart`.

## Founder preview email settings and templates

LOCK 39 changes Settings → Notifications & emails to the sample-only em90
page. Its five switches belong to the current preview account session;
only Journey emails can turn off the corresponding email decision. The 16
approved email samples share one HTML, plain-text and Flutter preview source
in `lib/dev/zyra_email_templates.dart`. This code does not send email or set
device notification permissions. The future email service must provide real
member values and approved action links. The focused checks and optional
430 × 932 capture are in `test/zyra_email_preview_test.dart`; the capture runs
with `--dart-define=ZYRA_LINE133_CAPTURE=true` and writes to
`build/line133_preview/em90.png`.

## Founder preview privacy and security

LOCK 40 adds Settings → Hidden and blocked, App lock, and Sign-in & security
for Seeker and Guardian sample accounts. The hidden and blocked list shows only
the member's own choices; Show again and Unblock do not restore old requests or
Journeys. App lock and the two phone privacy switches use account-bound local
device preferences. Existing enabled App lock users retain Straight away;
newly enabled users start at 1 minute. Four sensitive sample actions ask the
phone's native Face ID or passcode check before changing preview state, and a
cancelled check changes nothing. Sign-in devices and the away rules are sample
display only; there is no live device-session or inactivity service here.
The focused checks are in `test/zyra_privacy_security_preview_test.dart`,
`test/zyra_privacy_sensitive_actions_shell_test.dart`, and
`test/visual/line134_privacy_security_capture_test.dart`. The 430 × 932
captures stay under `build/line134/screens`.

## Founder preview full profiles

Profiles and full profiles share the LOCK 4 V5 card, including Main Guardian
and Compatibility rows. Full profiles use the entry's title and current
Journey or request action. Tap the card to step through its photo pages.
At Larger Text, a fact tile takes the full row when a whole word cannot fit
its half-width tile; words, including hyphenated places, stay intact.
These routes use local Founder sample state.

## Founder preview Membership

LOCK 42 replaces Profile → Membership for Seeker One and Guardian One. The
page uses the shared Settings row, page title and floating surfaces. Billing
amounts come from the membership catalogue; the local account's read-only
sample record supplies its date and trial field. No record means no date or
trial wording. There is no new developer control or live purchase reader.

Compatibility Unlocks and Compare plans open their existing pages. Family
places, coverage information and Restore purchases use the approved shared
preview toasts. Cancel membership uses the existing App Store subscriptions
action. A Family-covered member sees an informational payer card without a
Cancel action. Basic members retain the existing plans page.

Focused behavior tests are `test/zyra_membership_preview_test.dart`; actual
Profile routes, external-action mocks and rendered-text checks are in
`test/visual/line136_membership_capture_test.dart`. Enable its five master
captures and narrow-screen replay with `--dart-define=ZYRA_LINE136_CAPTURE=true`.
The output stays under `build/line136/`. The as-built record is
`../PRODUCT/APPROVED/MEMBERSHIP_PAGE/BUILT/LINE136/HANDOVER_2026-11-24.md`.

## Founder preview Edit profile

LOCK 45 replaces the old Edit profile sections with Photos and video,
About you, Journey Bio and Partner preferences. About you uses the existing
sign-up presenters with Done; Journey Bio edits one existing section at a
time. Counts come from the current local draft. Name, age and gender are
locked, and the inline contact support link opens the existing sample form.
No edit reads or writes a member account. The same photo-rules widget appears
under sign-up Photos and Edit profile's Photos row.

The focused route and rendered-text checks are in
`test/visual/line139_edit_profile_capture_test.dart`. Enable the four master
captures and the 375/430, normal/Larger Text replays with
`--dart-define=ZYRA_LINE139_CAPTURE=true` through the protected test driver.
They write to `build/line139/`, turn real shadows on, repaint after auditing
and hash the actual saved PNGs. The underlined-link audit control is
`test/line139_underlined_text_audit_test.dart`.

## Rendered text audit

For each local queue line, run the whole-project analyzer, ordinary regression,
and focused rendered-text replay for the screens or fixtures it changes through
`node tooling/no_git_driver.mjs flutter ...`. The focused replay uses the
relevant line 126 capture tests and `test/zyra_rendered_text_audit_controls_test.dart`.
The four full-screen corpus drivers are opt-in and are not a local landing gate.

The `Full text audit` job in `.github/workflows/zyra-ci.yml` runs the full
normal and Larger Text corpus at 375 and 430 widths on each main push and the
nightly schedule. Its four settings report separately in job logs and summaries;
audit failures do not fail the workflow or block a queue line. It enables each corpus with
`--dart-define=ZYRA_FULL_TEXT_AUDIT=true` and keeps the audit's existing
coverage and 4.5:1 / 3:1 thresholds.

## Backend

Supabase project `sxoaxonzjqkgajmlagyk`. Config in
`lib/config/supabase_config.dart` (gitignored, real values in place).
Migrations source-controlled in `supabase/migrations/` — keep them in
sync with the live project (`list_migrations`) after any DB change.
