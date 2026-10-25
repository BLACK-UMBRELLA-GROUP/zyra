# 111 — CODEX → FOUNDER: one app confirmed; Test retirement scoped

Date: 2026-09-12
Owner/action: OA-ZYRA-286
Authority: direct Founder instruction confirming Apple sign-in and requiring one
ZYRA app with company-Founder developer access and personal member experience.
Status: active delivery changed to ONE APP; launcher and documentation corrected.
Cloud deletion, complete native/code removal, signing and upload NOT executed.

## 1. Confirmed account and Apple state

Read-only Chrome evidence:
- Signed-in Apple account: admin@zyraconnect.app.
- Provider URL: 6d66bbe2-8ad1-479b-8938-8e3722d8d38e.
- App: ZYRA Connect, Apple ID 6810741513.
- The Apps inventory contains only ZYRA Connect; no separate Test record.
- Main TestFlight upload/build lists contain only 1.0.0 (2), Internal/Testing,
  assigned Founder Internal. Build 3 is absent in the visible current inventory,
  not reserved or uploaded.
- Company Google client inventory is in project zyra-app-506315, signed in as
  admin@zyraconnect.app. Its two dedicated Test clients were identified and
  selected for deletion confirmation only; no Delete action occurred.

Read-only main Supabase Auth query returned exactly one protected Founder:
dfcbd00d-bc22-4d6e-999b-3a9264cf3510, confirmed company Google account,
app_metadata.zyra_role=founder. No role/account/provider was changed.

The new internal main build requires that exact UUID, main endpoint, explicit
compile opt-in and freshly refreshed protected role. Personal identities do
not match the gate and retain normal member onboarding/backend permissions.
Email text alone is not authority. Founder mode is explicitly LOCAL developer
previews/signup skips/scenario controls, not real test-account switching or
production administration. No shared credential has been reintroduced.
The currently installed immutable build 2 still lacks this new code.

## 2. Executed local correction

SOURCE/run.sh now:
- defaults to production-flavour PROFILE with the exact internal-Founder
  flag/UUID; dev/debug use the same main identity;
- preserves profile unplug/cold-launch behavior and the existing phone ID;
- keeps release public/main without the internal-Founder defines;
- refuses check-founder-test-config, test, foundertest, founder-test and
  unknown modes with exit 64 before Flutter.

Only run.sh and its direct contract test changed in source. Mocked executable
tests intercept Flutter with an ephemeral fake executable; no actual device
run/signing/network occurs. Shared app Dart code from 110 is unchanged.

The ZYRA bootstrap and two current handovers now state ONE ACTIVE APP,
separate Test delivery CANCELLED, not a pending replay. Former two-app
instructions/acceptance criteria are explicitly RETIRED REFERENCE ONLY.
Historical content was not erased. Remaining resource/source cleanup is
stated as incomplete, not concealed by the wording change.

## 3. Verification

- Fresh internal account/preview/refresh-race/route-boundary selection: 31/31 PASS.
- Launcher plus retained archive/release-tooling regression selection: 20/20 PASS.
- Delegated launcher-only mocked selection: 5/5 PASS; bash syntax PASS.
- Full analyzer after the launcher test change: no issues.
- Previous complete application suite remains the measured 110 result:
  950 PASS / 60 pre-existing visual mismatches, with all 60 reconstructed
  pre-change actual PNGs byte-identical. No new full-suite run or approved
  pixel regeneration is claimed here.
- No new archive/build/install/upload occurred in this turn.

Workspace evidence root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/`.

Logs:
`oa286-one-app-account-boundary-recheck.log`,
`oa286-retirement-launcher-regression.log`,
`oa286-retirement-analyzer.log`.

## 4. Exact external retirement targets — prepared, NOT deleted

1. Supabase project `xqweloifosbwfgctzros`, name ZYRA Test, org
   `pdekarsldtaqlqdthgwh`, eu-west-1.
   Fresh checks: ACTIVE_HEALTHY; zero Auth users, public application tables,
   Storage buckets/objects and deployed Edge Functions. This does not mean the
   project/configuration/logs do not exist. Deletion is destructive and loses
   this project identity/configuration; no automatic restoration is promised.
2. Google client **ZYRA Test Supabase Web**:
   `734578322486-k3v6akqgv55pv3ukgj521lh7ebokja6r.apps.googleusercontent.com`.
3. Google client **ZYRA Test iOS**:
   `734578322486-lk30rpiog0gh01f679qvmpgen8a0jak8.apps.googleusercontent.com`.

Both Google targets are in project zyra-app-506315 and were freshly verified
by name and full link ID. Deleting them disables the retired Test login path.
Do not delete the Google project, company Google/Apple accounts, or the main
ZYRA Supabase Web, ZYRA iOS and ZYRA Android clients.

Retained main clients:
- Web: 734578322486-gvi63m04ogd7bbmsunokuq2klkepetq1.apps.googleusercontent.com
- iOS: 734578322486-eoh5ba4usl0svs9ihqh2ltagqfgusnft.apps.googleusercontent.com
- Android: 734578322486-1o7jvjl39cnhaqm30akdn9kg8ph89kgs.apps.googleusercontent.com

The old Test callback/branding-domain reference also requires bounded cleanup.
The loopback redirect belongs to the retired Test project; no Production
redirect may be removed. The Test Web secret's precautionary rotation remains
unperformed; if its client is deleted, record retirement rather than falsely
claiming rotation. No secret field was opened, entered or captured.

Browser action-time destructive confirmation remains required. The Founder
also needs to clarify retaining historical decisions/security evidence while
removing active Test-only setup; “no document/data exists” has not been achieved.

## 5. Local cleanup inventory and protected shared dependencies

Prepared candidates, not deleted:
- config/founder_test.public.json.example
- ios/Flutter/{Debug,Profile,Release}-foundertest.xcconfig
- ios/Flutter/FounderTestSecrets.xcconfig.example
- ios/Runner.xcodeproj/xcshareddata/xcschemes/foundertest.xcscheme
- ios/Runner/Assets.xcassets/ZYRATest.appiconset/
- ios/ZYRATestInternalExportOptions.plist
- assets/icon/icon_founder_test.png
- tool/build_founder_test_ipa.sh and tool/validate_founder_test_config.dart
- Test resource/config validator and old persona modules, only after all shared
  imports/callers are refactored:
  lib/config/zyra_founder_test_approved_resources.dart,
  lib/config/zyra_founder_test_configuration_validator.dart,
  lib/config/zyra_founder_persona_policy.dart,
  lib/services/zyra_founder_persona_service.dart.
- supabase/functions/zyra-founder-persona-session/ and the un-applied Test-only
  founder_persona / dev_rpc_hardening staging packages.

The nine foundertest build configurations/references in project.pbxproj need
surgical removal, not project deletion. Shared variants, OAuth/Supabase config,
native identity, auth/router, IDV/onboarding and Developer Access require
dependency-aware edits. Preserve the production scheme/config/icons and
TestFlightInternalExportOptions.plist: “TestFlight” does not mean “second app”.

Preserve the main internal-Founder policy, HTTP/Realtime denial, preview
panels/banner, identity-cache/sign-out guards and their tests. Preserve shared
regression fixtures and migration history; matching a test email or the word
“test” is not evidence that a file belongs exclusively to the retired app.
No dependency package was found exclusive to the retired flavour.
Consumed one-use markers and historical approvals are not disposable fixtures.

## 6. Signing finding — separate from cleanup

No Apple login blocker remains. However the unexecuted signed build helper
invokes installed Flutter tooling which adds -allowProvisioningUpdates and
-allowProvisioningDeviceRegistration for signed builds/exports.
Source evidence:
flutter_tools/lib/src/ios/mac.dart and commands/build_ios.dart.
Therefore “sign locally, with no certificate/profile/registration change” is
not guaranteed merely by the helper's export-only destination.

Keep its execution held until the signing path is constrained to inspected
existing assets, or the exact provisioning actions receive appropriate GO.
No SDK guard was bypassed, no local credentials were read, and no cloud
signing operation was attempted. This finding remains under OA-ZYRA-286;
it is not a reason to revive the cancelled second-app pipeline.

## 7. True pre-state and SHA-256 ledger

Root true pre-files: evidence/oa286-retirement-prestate.xujhHx/.
Delegated true pre-files: evidence/oa286-one-app-run-target-prestate.xa1Nci/.
All five existing edited files have actual pre-edit byte copies.

| File (relative to ZYRA) | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| AGENTS.md | 7999dd41393b264bc58882608c85310eafc548d32995a48759ceda7e0330b120 | c5b448a4e5493651a053cb255835d140df30be69866e288f75aaab0adf822dc0 |
| SOURCE/run.sh | ee9a251128ee0a9f6dd8920d95d71716f1e8b893750701a6e33998655fc503fe | 2d193069dd68f03768ae5b1bf5ef4059851a962861220d38d921e66eee871a7e |
| SOURCE/test/zyra_run_target_contract_test.dart | 11f149b3d0a83ec82ca12dc65ec78b02cfc561e336874fd49612a136e463ba88 | 71fd77d79ee4107abe7bc45e427c888a93152edb9f799d60e233e7fd417d5a80 |
| SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md | ebc9fcc884240532da8d20726e17fd7d0d42abdde5dbbc68340d79ce51c047a8 | 508bfb1fc1e6fc9dd5ea6e6249bccff83b156f580628ecbcb384c28e5ba8bc27 |
| SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md | 071363fc314ed01afd55801e1b4893983cdca1d9a8762fbe0f90c4e2e97c836f | 1ce6f512c157386cd06cb1089e99161b745c976301f454a3c59053d817d73fad |

This numbered report is new. No material file/cloud resource was deleted;
removed launcher helper code remains recoverable in its true pre-file.
No git, migration, public release, user/role/credential mutation, VM or replay.
The existing large OA/decision registers were not edited without full-file
reading; this OA-ZYRA-286 report and the current bootstrap/handovers preserve
the active direction pending bounded register reconciliation. No closure or
self-approval is claimed.
