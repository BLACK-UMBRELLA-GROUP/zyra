# ZYRA External Tester Access — Current Handover V2

**Date:** 2026-09-24  
**Owner:** Codex under AD-AIOS-110  
**Authority:** Direct Founder instruction  
**Status:** Code complete; signed external-review build 5 exported and
post-verified. Upload, App Store Connect credential entry, reviewer reply and
resubmission remain pending separate action-time gates.

## 1. What changed

Apple rejected TestFlight beta build `1.0.0 (4)` on 2026-09-20 under
Guideline 2.1(a), Information Needed. The reviewer could not access all app
functionality. The build exposed a one-field private tester code, while the
Beta App Review Information form had no usable demo username and password.

The external-review route now uses two explicit fields — **User name** and
**Password** — matching App Store Connect. Valid review details unlock the
existing local Seeker and Guardian experiences. Invalid or incomplete details
unlock nothing.

The Welcome entry is now **Review & tester access**. The review screen makes
clear that sample data is local and that no live member account is changed.

## 2. Security and data boundary

- Review access remains default OFF and appears only when the app is compiled
  with `ZYRA_EXTERNAL_TESTER_ACCESS=true`.
- The demo credentials unlock local sample experiences only. They do not create
  a Supabase user, confer Founder authority, bypass RLS, or expose member data.
- The exact Founder UUID/role/backend proof remains a separate protected route.
- Ordinary/public builds omit the review entry because the compile gate is OFF.
- Sign out clears the external-review latch.
- No database migration, Auth account, role, RLS policy or backend data change
  is part of this fix.

## 3. Build and delivery contract

The next external-review candidate is `1.0.0 (5)`. The governed local export
entry point is:

```sh
sh tool/build_external_review_ipa.sh 1.0.0 5
```

`ios/TestFlightExternalExportOptions.plist` deliberately omits
`testFlightInternalTestingOnly`; an internal-only IPA cannot serve an external
tester group. The script fails if that key is later introduced. It also pins
the existing production Team and enables only the local external-review entry,
not Founder access.

Export is not upload. The signed IPA was created after the Founder's explicit
2026-09-24 GO and verified before any upload:

- path: `SOURCE/build/ios/ipa/ZYRA.ipa`;
- SHA-256: `da89aff38201eee83bb0f3685b09a6c1350b9853e34bee831c99e9a44940fca0`;
- size: 25,581,029 bytes;
- bundle/version/build/display: `app.zyraconnect.zyra` / `1.0.0` / `5` /
  `ZYRA`;
- Team: `9Y7Z8F36SJ`; valid Apple Distribution signature;
- existing Store profile UUID `07c3e51d-0bc9-41a9-8b54-ce5be5c94a19` reused;
- `get-task-allow=false`, `beta-reports-active=true`, Apple sign-in `Default`;
- minimum iOS 15.0; non-exempt encryption false;
- `TFInternalTestingOnly` absent from the exported package.

No new certificate/profile was created. The Founder then approved one upload
of that exact immutable IPA to ZYRA Connect Apple ID `6810741513`. The first
private-password prompt ended before credential acceptance or an Apple process
started. A fresh one-use prompt was explicitly requested; it uploaded the same
unchanged IPA exactly once. Apple's upload command returned exit 0 with
`PROCESSING`, and fresh App Store Connect inspection subsequently showed build
5 `Complete` and `Ready to Submit`.

App Store Connect must have **Sign-in required** enabled and the matching demo
username/password entered under TestFlight → Test Information. Review notes
must state: on Welcome choose **Review & tester access**, enter those demo
details, then choose Seeker or Guardian. Do not place any production member or
Founder credential in App Store Connect.

After action-time Founder confirmation, App Store Connect was updated with the
dedicated local-review username and password, corrected two-field access steps,
review notes, company feedback/review email and the Founder-entered review
telephone number. No production member or Founder credential was transmitted.
The information saved with no required-field errors.

Build 5 was added to the existing external group `1ST GROUP` and submitted for
Beta App Review with automatic tester notification retained. Fresh Apple UI
then showed `External Group · 1 Tester · 2 Builds` and build `1.0.0 (5)` as
`Waiting for Review`. Build 4 remains visibly rejected as historical evidence;
it was not deleted or resubmitted. No separate reply was posted to the old
rejection thread because the corrected new build and its complete review access
information are now the active submission.

## 4. Live files

- `SOURCE/lib/config/zyra_external_tester_policy.dart` — default-OFF compile
  gate and demo credential comparison values.
- `SOURCE/lib/services/zyra_developer_access.dart` — exact two-field review
  authorization and local latch.
- `SOURCE/lib/screens/auth/tester_access_screen.dart` — review login and choice
  of Seeker or Guardian local experience.
- `SOURCE/lib/screens/welcome_screen.dart` — conditional review entry.
- `SOURCE/pubspec.yaml` — next candidate version `1.0.0+5`.
- `SOURCE/ios/TestFlightExternalExportOptions.plist` — external TestFlight
  export options.
- `SOURCE/tool/build_external_review_ipa.sh` — guarded signed export command.
- `SOURCE/test/zyra_external_tester_access_test.dart` — credential, gate and UI
  behavior.
- `SOURCE/test/zyra_external_testflight_release_preflight_test.dart` — prevents
  internal-only export or Founder flags from entering the external build.

## 5. Data flow

```text
Default-OFF external build flag
        ↓
Welcome: Review & tester access
        ↓
Exact local demo username + password
        ↓ valid                     ↓ invalid
Local review latch                  Clear denial
        ↓
Seeker or Guardian sample shell
        ↓
Internal preview client denies backend reads/writes
```

## 6. Verification completed

- Apple rejection message read directly in App Store Connect: Guideline 2.1(a),
  reviewer unable to access all/part of the app; demo credentials requested.
- `flutter test test/zyra_external_tester_access_test.dart
  test/zyra_developer_route_gate_test.dart` — 7/7 PASS.
- `flutter test test/zyra_developer_access_test.dart
  test/zyra_developer_access_concurrency_test.dart
  test/zyra_external_tester_access_test.dart
  test/supabase_publishable_auth_test.dart` — 28/28 PASS.
- `flutter test test/zyra_external_testflight_release_preflight_test.dart
  test/zyra_external_tester_access_test.dart` — 6/6 PASS.
- `flutter analyze` — PASS, no issues.
- `plutil -lint ios/TestFlightExternalExportOptions.plist` — PASS.
- Unsigned external-review iPhone release compile — PASS, 27.2 MB.
- Compiled product verified as bundle `app.zyraconnect.zyra`, version `1.0.0`,
  build `5`.
- Signed external-review IPA export — PASS, 25,581,029 bytes.
- Deep/strict code-sign verification — PASS; existing Apple Distribution
  identity and Store profile reused.
- Exported IPA external-TestFlight eligibility check — PASS; internal-only
  marker absent.
- Compiled review-entry string check — PASS.
- One-use Apple upload — PASS; exit 0 and `PROCESSING` returned for the exact
  approved SHA-256, with no duplicate upload.
- Fresh App Store Connect processing check — PASS; build 5 `Complete`, then
  `Ready to Submit`.
- Beta App Review information save — PASS; sign-in required enabled and zero
  required-field errors.
- External group submission — PASS; `1ST GROUP` now contains build 5 with
  status `Waiting for Review` and its existing sole tester retained.

## 7. Remaining steps and limits

1. Monitor Apple until build 5 moves from `Waiting for Review` to an approval,
   rejection or request for information.
2. If approved, verify the existing tester can install/update and can enter the
   local Seeker and Guardian review experiences on a real device.
3. Treat any Apple reviewer reply as a new external representational action and
   obtain action-time Founder confirmation before posting it.
4. External testers must not upload real photos until the separately governed
   photo metadata/size work is shipped.

The upload and review submission prove Apple receipt and current review state;
they do not yet prove approval, tester installation or real-device acceptance.

## 8. Authority map

- Product authority: direct Founder instruction in the ZYRA app task.
- Apple evidence: App Store Connect rejection thread dated 2026-09-20.
- Delivery runbook: `ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md`.
- This as-built handover supersedes
  `ARCHIVE/ZYRA_EXTERNAL_TESTER_ACCESS_HANDOVER_2026-09-20_V1.md`.
