# CODEX → FOUNDER — TESTFLIGHT FOUNDER INTERNAL CONFIGURED

**Date:** 2026-09-12  
**Status:** EXECUTED / POST-VERIFIED / READY TO TEST / FOUNDER INSTALL + ACCEPTANCE PENDING  
**Authority:** Founder's direct instruction to create `Founder Internal`, keep automatic distribution off, add only `admin@zyraconnect.app`, assign only ZYRA `1.0.0 (2)`, read Apple's latest email and correct its issue  
**Operating authority:** AD-AIOS-109; FOUNDER_CODEX_OPERATING_MODEL  
**Outstanding action:** OA-ZYRA-283  

## 1. Outcome

The private Founder TestFlight path is active and post-verified:

- app: `ZYRA Connect` / Apple ID `6810741513` / bundle
  `app.zyraconnect.zyra`;
- Team: `9Y7Z8F36SJ` / provider public ID
  `6d66bbe2-8ad1-479b-8938-8e3722d8d38e`;
- build: ZYRA `1.0.0 (2)`, internal, `Ready to Test`;
- internal group: `Founder Internal`, group ID
  `37600523-1fe0-4911-aeef-10502dc8a35b`;
- distribution: `Manual for Xcode Builds` — automatic distribution OFF;
- tester: exactly one, `admin@zyraconnect.app` / Shakeel Ahmad /
  Account Holder, status `Invited` on 2026-09-12; and
- assignment: exactly one build, ZYRA `1.0.0 (2)`.

No external tester/group or public App Store release was authorised or
changed. Founder invitation acceptance, installation/device result and
OA-ZYRA-283 acceptance remain pending.

## 2. Upload identity retained

Apple retained the exact previously authorised IPA:

- IPA SHA-256:
  `1e17a1c3475db1bcb01e59415768d94480538bb601aedcdc8fdd706ea1a7b673`;
- version/build: `1.0.0 (2)`;
- delivery/build UUID: `924609e0-7f2c-43dc-b7e7-6851acc20828`; and
- encryption declaration: no non-exempt encryption.

Apple accepted the delivery before the local `altool` wrapper failed while
serialising its own success response. App Store Connect later showed upload
`Complete` and build `Ready to Test`, so no upload retry was made.

## 3. Latest Apple email

The newest substantive Apple delivery email was read in
`admin@zyraconnect.app`. It is from verified sender
`no_reply@email.apple.com`, timestamp 2026-09-12 09:18, subject
`The uploaded build for ZYRA Connect has one or more issues.` It says delivery
was successful and reports one non-blocking warning:

`ITMS-90068: MinimumOSVersion too low` — build 2 declares iOS 13.0; starting
in Spring 2027 Apple will require iOS 15.0 or later for upload or submission.

The later 09:33 Apple email is the expected internal TestFlight invitation:
`Shakeel Ahmad has invited you to test ZYRA Connect.`

## 4. Corrective source change

The already-uploaded build 2 is immutable and truthfully remains minimum iOS
13.0. It is valid for the current private test. For the next build, the three
authoritative Xcode project configurations — Debug, Profile and Release — now
set `IPHONEOS_DEPLOYMENT_TARGET = 15.0`. A release-preflight test requires
exactly those three iOS 15 entries and rejects any iOS 13 target assignment.

No generated Swift-package file was hand-edited. Flutter regenerated its
package platform declaration from the project setting. No version/build-number
change, signed archive, upload, migration, production access, approved-pixel
change or git action occurred. A future corrected upload requires a new build
number and a new exact Founder archive/upload authority.

## 5. Verification

1. App Store Connect group page: `Internal Group · 1 Tester · 1 Build`.
2. Settings: `Manual for Xcode Builds`.
3. Testers: only `admin@zyraconnect.app`, status `Invited`.
4. Builds: only `1.0.0 (2)`, iOS, `Ready to Test`.
5. Effective Release settings: deployment target `15.0`, target triple
   `ios15.0`, recommended target `15.0`.
6. Fresh unsigned release compile: PASSED; built
   `build/ios/iphoneos/Runner.app` with `MinimumOSVersion=15.0` and Mach-O
   `minos 15.0`.
7. Focused release-preflight suite: 8 passed.
8. Non-visual Flutter suite: 565 passed, 0 failed.
9. Full/default suite: 840 passed and the same 60 registered visual-golden
   mismatches failed; no approved pixel was regenerated or changed.
10. `flutter analyze --no-pub`: no issues.
11. `python3 tools/zyra_check.py`: 0 findings across 186 files.
12. `python3 -m unittest tools/test_zyra_check.py`: 1 passed.

## 6. True pre/post ledger

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/ios/Runner.xcodeproj/project.pbxproj` | `4a2e785108b8ed4d44e01efb49f69713b1fa3477c4601f8b52426293923d0939` | `a46dd7d38630b2abcd473cebdd5660f9581393d649a3c0501a7d4e2e0a267269` |
| `SOURCE/test/zyra_ios_testflight_release_preflight_test.dart` | `749ce6cb6f5ba24f6f5b3ab57105206940c5221417f30dbd2f3a574f1690e134` | `996847a58905e5971a0c6790dc51a5e1fc8695a61fb02b1d77ab3578fa6ba6e4` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `b2657f436d2f3251b98d7111fa9f7361833ab388ce11054ade023b76ec723d20` | `32ec3730fbcbea83f173b14b0166c569c5c4ed650ad73098fcf43b8c171770f4` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V1.md` | `898c5b8645e755507a784962638f17d4a58ce16b20074e9f01d5662c295339cf` | `b9339a8198d4951fd1bf0c5ea2794f37bd808ec8677745730697f74342fa7ad0` |
| `SYSTEM/DOCUMENTS/ZYRA_JOURNEY_COMPATIBILITY_BOUNDARY_HANDOVER_CURRENT_VERSION_V1.md` | `443641dbf84dd68c261c181bc51a8252247b85810e6296969ae0d03dbfb6c8c9` | `79968523d24d604f1c0910ceffcf1f871db434d456ff41f9d474bfc131bcdb38` |
| `SYSTEM/DOCUMENTS/ZYRA_APPLE_SIGNIN_HANDOVER_CURRENT_VERSION_V1.md` | `8563bbb74fb749a4d0d3682d269bbe6e74fb381e8ac2521e9a2e33d3f3b257db` | `03b8065f28ed2d9d2f10ccf75807546a96e879eddf50a0f2e7b2d275fad74efe` |
| `CLAUDE.md` | `5182941c14dfc0ceef6e463b5848512f118c303330e51eb6d8eaa9445322aa69` | `eb4650a662a9b75801c00cb080b6866e298df75511ab84e8d5117ce06a730f5c` |
| AIOS `OUTSTANDING_ACTIONS_V1.md` | `b4d9a2f43ffe9c1f7e9b94df9ff00974af06e160010034c6ff9bc62debc8e174` | `4d5f37c05b981280a638ea6f0984cf529d30d04b6c19a6849637e98ff1ed23b3` |
| `ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V3.md` | `e9d6b11a533c7db2fd442463b70db5ca97378b022231547cc4ffec5575140fc2` | `749e5b0a10e61ac2876b729ca17ec58f0583f7ba3a238bba3e7c8360f67b0200` |

The AIOS register's byte-identical true pre-state is preserved at
`BLACK UMBRELLA GROUP/ARCHIVE/REGISTER_BACKUPS/OUTSTANDING_ACTIONS_V1_2026-09-12_pre_testflight_founder_internal_094058.md`, SHA-256
`b4d9a2f43ffe9c1f7e9b94df9ff00974af06e160010034c6ff9bc62debc8e174`.

## 7. Founder action remaining

Open the 09:33 TestFlight invitation on the iPhone, accept it, install ZYRA,
and return the device result. No same-Wi-Fi connection to the Mac is required.
