# 083 — CODEX → FOUNDER

**Date:** 2026-09-11  
**Workstream:** ZYRA Founder-only internal TestFlight  
**Authority:** Founder direction to continue every safe phone-free preparation;
AD-AIOS-109 operating authority  
**State:** OFFLINE PREFLIGHT COMPLETE / EXTERNAL GATES UNCHANGED  
**Production:** NOT ACCESSED  
**Migration replay/apply:** NOT RUN  
**Apple transmission:** NOT RUN  
**Git:** NOT USED

---

## 1. Outcome

ZYRA's next internal-TestFlight source identity is now governed as
`1.0.0+2`. The source owns an internal-only App Store Connect export contract,
the iOS bundle carries the audited standard-encryption exemption, feedback
records use the installed bundle version, and a dedicated release-preflight
test pins the exact release boundary.

A fresh unsigned iOS release compile succeeds and proves:

- display name and bundle name: `ZYRA`;
- bundle identifier: `app.zyraconnect.zyra`;
- marketing version: `1.0.0`;
- build number: `2`;
- minimum iOS: `13.0`;
- `ITSAppUsesNonExemptEncryption=false`.

This is preparation evidence only. No signed archive or new IPA was created,
and nothing was sent to Apple.

## 2. Source changes

1. `SOURCE/pubspec.yaml`
   - changed the source-owned build from `1.0.0+1` to `1.0.0+2`;
   - removes dependence on a one-off command-line build-number override.
2. `SOURCE/ios/Runner/Info.plist`
   - added Boolean `ITSAppUsesNonExemptEncryption=false`.
3. `SOURCE/ios/TestFlightInternalExportOptions.plist`
   - new governed export contract;
   - `method=app-store-connect`;
   - `destination=export`, so exporting cannot consume Upload GO;
   - automatic signing on paid Team `9Y7Z8F36SJ`;
   - `testFlightInternalTestingOnly=true`;
   - Apple build-number mutation disabled;
   - byte-identical to the successful retained Xcode-generated internal-only
     export-options shape.
4. `SOURCE/lib/services/zyra_feedback_service.dart`
   - removed the hard-coded `1.0.0+1` report label;
   - now reads the installed version/build through the already-present
     `package_info_plus` dependency;
   - a lookup failure sends NULL instead of inventing a version and does not
     prevent the feedback submission.
5. `SOURCE/test/zyra_ios_testflight_release_preflight_test.dart`
   - new seven-test contract pinning paid-team signing, canonical app identity,
     Sign in with Apple, export compliance, internal-only export, source build
     2, dynamic feedback metadata, both staged Journey release hashes, the
     client hold, and the forbidden old IPA identity.
6. Current records were reconciled in the App Store runbook, OA-ZYRA-274,
   OA-ZYRA-283, the Journey boundary handover and the documentation index.
   No new OA was created.

## 3. Export-compliance basis

The release-source audit found:

- ZYRA-authored cryptographic code only hashes the Sign in with Apple OAuth
  nonce with SHA-256;
- network transport is standard HTTPS/WSS through platform and third-party
  libraries;
- no custom cipher, proprietary encryption, VPN/NetworkExtension, CryptoKit,
  CommonCrypto or ATS arbitrary-load exception exists in Runner;
- the transitive cryptography packages are not invoked by ZYRA application
  code for encryption.

Apple documents `ITSAppUsesNonExemptEncryption=NO` for an app that uses no
encryption or only exempt encryption, and says TestFlight Internal Only builds
cannot be distributed externally or to customers:

- https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers

On the measured source, `false` is technically supportable for this bounded
internal build. Export-law responsibility remains the Founder's; App Store
Connect's answer must match the source declaration.

## 4. Release-security observations

Two read-only Codex sub-reviews checked source/build configuration and release
exposure. They are internal verification, not an independent approval.

- Developer controls and embedded test credentials are absent from the release
  AOT binary. Release access is also denied by `ZyraDeveloperAccess`.
- Two server-guarded development RPC names remain in AOT. This is existing
  public-launch cleanup under OA-ZYRA-184, not a blocker for the ruled
  Founder-only internal build.
- Existing engineering-audit risk R8 remains: some real Journey/Match photo
  fallbacks can render `picsum.photos` stock faces. It is accepted here only as
  a named controlled-internal residual; it blocks external/public testing
  until removed or separately ruled.
- No locally usable Apple Distribution identity was proved by this offline
  pass. The retained evidence used Apple's cloud-managed distribution
  certificate. A fresh signed export therefore still requires the authenticated
  Xcode/Apple step and was not attempted while the Founder was away.

## 5. Verification evidence

1. `plutil -lint` on source Info.plist, source export options and compiled
   Runner Info.plist: **3/3 OK**.
2. New release-preflight contract: **7/7 passed**.
3. Release-preflight plus existing bundle/OAuth contract: **11/11 passed**.
4. Full non-visual Flutter suite, explicitly excluding the visual file:
   **560/560 passed**.
5. `flutter analyze`: **No issues found**.
6. `python3 tools/zyra_check.py`: **0 findings**; five pre-existing dangling
   references remain baselined, with zero new findings.
7. `python3 -m unittest tools/test_zyra_check.py`: **1/1 passed**.
8. `flutter build ios --release --no-codesign`: **passed**; Runner.app 24.8 MB.
9. Full Flutter/visual observation: **835 passed, 60 failed**. Every failure is
   in the existing governed visual-regression file and the count is unchanged
   from the recorded pre-work visual debt. No approved image was regenerated,
   edited or deleted.

One first analyzer invocation was run concurrently with the iOS build and lost
the Flutter generated-cache race. That was tool contention, not a source
diagnostic. It was rerun alone and completed cleanly as recorded above.

## 6. Binary and held identities

| Object | SHA-256 | Meaning |
|---|---|---|
| Fresh unsigned build-2 `Runner` executable | `6a9f0fd20552ec3c05482d7286d1f3a1443b22284792cb0e7467f448cd91fe53` | compile evidence only; not signed/uploadable |
| Retained pre-hold build-1 IPA | `4685a31b2e2159d07777ffba8c729b2d371a6d96256c57e7eccb2a8abe074815` | byte-preserved evidence; explicitly forbidden from upload |
| OA-ZYRA-283 staged boundary | `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d` | unchanged; not applied |
| Request New Journey staged hold | `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545` | unchanged; not applied |
| OA-ZYRA-198 V2 replay bridge | `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` | internally verified only; replay not authorised |

## 7. True pre/post file ledger

True pre-files were copied at edit time to an isolated local scratch directory;
the hashes below were measured before the first edit. New files are recorded
as absent rather than given reconstructed pre-images.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/pubspec.yaml` | `e8b3af2663a4f4b63e72a5e0b74bc4659cd5e6137f5cb12f171cac7181890700` | `6cd4d5370583d225e1d6b8a8cdc45b961217a6f2dc45e5ab7b3e4fd489025314` |
| `SOURCE/ios/Runner/Info.plist` | `8582dcb004d738320b1c95ac3d46036119b12fd5580882cf1cc801dca944ec5d` | `a88ec4184f3fe734f6a6184ce27217e536cd4c069e995541b038d7d64767fb88` |
| `SOURCE/ios/TestFlightInternalExportOptions.plist` | absent | `665805d3130b65c6b5344ff360d15501aa85b27ad4827d3f53ad3ce2bc003cc9` |
| `SOURCE/lib/services/zyra_feedback_service.dart` | `3eff47b254e259d27b6d75a2c78e4421c7c5b3bca8d35fe37a8a9d6edf3fa51d` | `5315a5a572144b27a8027c757a91cd61c2ca2aada4d54f049ee2dd6326490913` |
| `SOURCE/test/zyra_ios_testflight_release_preflight_test.dart` | absent | `749ce6cb6f5ba24f6f5b3ab57105206940c5221417f30dbd2f3a574f1690e134` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V1.md` | `28f9e79b47316ecce6d27540243d861519d5545fc6f823a89e1ea6c2fdbc59fb` | `f024e35110bff0d9abb75c0b1ebd79774d7f20bb61b9da5b69c00708ae3f9d9c` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `9a87db27cfa26079f46f280420c198c17d766e63be9eb972ccadb2700cfa3508` | `012976fa7831c65e2bd095e6488505b85f08e7eaeeb3edee5d179cab7fb8de61` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V3.md` | `74d16cb4c309e9994fd5e49c2d1989fc509a1fd093cd696df36df94f8f086c09` | `dcfa1ebd4df13f5b423861ef00b583aa1c177d6e17b57ff4ba231c7cee137e2b` |
| `SYSTEM/DOCUMENTS/ZYRA_JOURNEY_COMPATIBILITY_BOUNDARY_HANDOVER_CURRENT_VERSION_V1.md` | `7e8e9cbf83a6c07a687de7ac78a4a7494364662f9834a23d601e3df13393adc9` | `ccaf7ad9f3e5027cfdfefa3dd186f3297f40f05f282d51f08883d5238e7e5fe2` |

## 8. Gates deliberately preserved

- no V2 full replay;
- no production access or migration apply;
- no App Store Connect authentication or account/metadata change;
- no signed archive or IPA creation;
- no upload or tester distribution;
- no use of the retained pre-hold IPA;
- no access to the private credential directory;
- no git command;
- no claim of independent approval or Founder acceptance.

## 9. Current conclusion

Every useful offline preparation that fits the current authority is complete.
The next internal build is constrained to TestFlight Internal Only and source
build 2, but TestFlight is not yet live. The OA-ZYRA-198 replay, exact
production apply, authenticated App Store Connect verification, fresh signed
export, exact Upload GO and Founder install remain separate future gates.

— END OF MESSAGE 083 —
