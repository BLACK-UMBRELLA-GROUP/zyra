# 017 — CODEX → FABLE — 2026-08-29 — BUNDLE ID UNIFICATION

## 1. Status and authority

**Authority:** Founder-ratified DR-ZYRA-218 · tracked by OA-ZYRA-268 · build
brief `015_FABLE-CODEX_2026-08-29_BUNDLE_ID_UNIFICATION_GO.md` · paid Apple
membership context verified in Fable message 016.

**Verdict:** repository-side iOS + Android identifier unification is **CODE
COMPLETE and build-verified**. External OAuth registration and real
authenticated-device verification are **PENDING — not falsely claimed**.

No git operation, database migration, App Store Connect record, Apple App ID,
certificate, entitlement, or signing-team change was performed.

## 2. What changed

| Surface | Before | Live source after |
|---|---|---|
| iOS Runner Debug / Release / Profile | `com.shakeelahmed.zyraapp` | `app.zyraconnect.zyra` |
| iOS RunnerTests Debug / Release / Profile | `com.zyra.app.RunnerTests` | `app.zyraconnect.zyra.RunnerTests` |
| Android `applicationId` | `com.zyra.app` | `app.zyraconnect.zyra` |
| Android namespace | `com.zyra.app` | `app.zyraconnect.zyra` |
| Android Activity package/path | `com.example.app` at `com/example/app` | `app.zyraconnect.zyra` at `app/zyraconnect/zyra` |
| Native/Dart app-icon channel | `com.shakeelahmed.zyraapp/app_icon` | `app.zyraconnect.zyra/app_icon` |

`ios/Runner/Info.plist` already derived `CFBundleIdentifier` from
`$(PRODUCT_BUNDLE_IDENTIFIER)`, so no hardcoded identifier edit was required.

## 3. Live files and hashes

| File | Responsibility | SHA-256 |
|---|---|---|
| `CLAUDE.md` | Correct current signing/bundle guidance and preserve the Phase-2 team gate | `cf91bde47e71146de3c1ce9e04d0f506c006c9bca17ac8e99b0aa29f27520a45` |
| `SOURCE/README.md` | Remove the false OAuth-placeholder statement and record the external-registration boundary | `8c6e414ffc6f58a35de209d21565651bc9853dac3cbb64c0b0ab85418b446eaa` |
| `SOURCE/ios/Runner.xcodeproj/project.pbxproj` | Canonical Runner and RunnerTests identifiers | `8a1175f377aa4e89a971fffdc5116022f784e5fcb56305d504e9a1955b939db4` |
| `SOURCE/ios/Runner/AppDelegate.swift` | Canonical native app-icon MethodChannel endpoint | `43e22f5d293a972e946f2fadf8e9016a28906d79d8a750b8f51e6cb88154bcd7` |
| `SOURCE/lib/services/zyra_dev_app_icon.dart` | Matching Dart MethodChannel endpoint | `4314589e1a5c1df9df48701cfbb1680bce1a74f5b2d744654e380c37a1399cd9` |
| `SOURCE/android/app/build.gradle.kts` | Canonical Android namespace and application ID | `f0472556ae8a213a736c4c8737ae6607ae0bccc7020543c6b025ade7ca882cc2` |
| `SOURCE/android/app/src/main/kotlin/app/zyraconnect/zyra/MainActivity.kt` | Canonical runtime Activity package/path | `475657653d9c048bc10bb2f4eac5d61bacda6fb02c823284f1401e1d170c7df8` |
| `SOURCE/test/bundle_identifier_contract_test.dart` | Static regression contract for both platforms and Google callback pairing | `5d0daa8ce72f950c2a50085ec9fc1f80096a0c4afe2b81e2cab90703c32cc286` |
| `SOURCE/lib/config/oauth_config.dart.example` | Documents bundle/package-specific Google configuration and native Apple boundary | `1242cb0ca9c9f940b35caa8f3944cc74aedbe0fda20ea6e6dcebeba5280b14b5` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V1.md` | Records repository execution and truthful external-auth remainder | `90cbf67fa67c27aecf22f355fb3f3db4a0fc60edbcee2cb99f4822f9cc75a5c5` |
| `SYSTEM/DOCUMENTS/ZYRA_APPLE_SIGNIN_HANDOVER_CURRENT_VERSION_V1.md` | Current paid-team/canonical-ID amendment without overstating Apple readiness | `ff88789c194f61305699cbce0570c9f7b65ef40f8d5bf185ab611ad7cbed2c04` |

Removed: `SOURCE/android/app/src/main/kotlin/com/example/app/MainActivity.kt`.
This handover's own hash is returned to the Founder after writing, avoiding a
self-referential hash.

## 4. Runtime/configuration architecture

Current authentication remains native ID-token exchange:

```text
ZYRA app
  -> Google / Apple native SDK
  -> provider identity token
  -> Supabase signInWithIdToken
  -> Supabase session
  -> authenticated ZYRA router
```

There is no app-level `signInWithOAuth`, `redirectTo`, magic-link callback, or
custom Supabase auth deep link in current code, so the bundle change does not
require a Supabase mobile callback URL. The provider-to-Supabase web callback
remains `https://sxoaxonzjqkgajmlagyk.supabase.co/auth/v1/callback`.

No `GoogleService-Info.plist`, `google-services.json`, iOS `.entitlements`,
associated-domains configuration, AASA/assetlinks file, or push entitlement
exists. Manual Google client IDs are intentional in the present build.

## 5. External provider measurements — 2026-08-29

The live Supabase dashboard was measured read-only:

- Google: **Enabled**. Allowed client IDs are the existing web client followed
  by the pre-unification iOS client. There is no Android client ID in the
  allow-list.
- Apple: **Enabled**. Allowed client IDs contain only
  `com.shakeelahmed.zyraapp`.
- Google iOS source values are internally consistent: `GIDClientID`, the local
  gitignored `googleIosClientId`, and the reversed URL scheme match one
  another. The repository cannot prove that Google Cloud has rebound that
  credential to `app.zyraconnect.zyra`.
- Google Cloud inspection reached the account's passkey confirmation. No
  credential was created, rebound, or exposed; persistent OAuth credential
  work remains an explicit external action.

Android `signingReport` measured the current Debug/Profile/Release test key as:

`SHA-1 3C:98:53:23:D6:B0:3C:77:35:58:F0:48:85:D1:E3:85:6F:ED:4E:F9`

The current Android Release build intentionally uses that Debug key. A real
production signing key will require its own Google Android OAuth registration.

## 6. Verification evidence

| Measurement | Result |
|---|---|
| `flutter test --no-pub test/bundle_identifier_contract_test.dart` | PASS — 4/4 |
| Full `flutter test --no-pub` | PASS — 616/616 |
| `flutter analyze --no-pub` | PASS — no issues |
| `python3 tools/zyra_check.py` | PASS — 173 files, 0 findings; 5 baselined dangling-doc references, 0 new |
| `plutil -lint ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj` | PASS |
| `flutter build ios --debug --simulator --no-pub` | PASS — `build/ios/iphonesimulator/Runner.app` |
| Built iOS Debug `CFBundleIdentifier` probe | `app.zyraconnect.zyra` |
| `flutter build ios --release --no-codesign --no-pub` | PASS — `build/ios/iphoneos/Runner.app` |
| Built iOS Release `CFBundleIdentifier` probe | `app.zyraconnect.zyra` |
| `flutter build apk --debug --no-pub` | PASS — `app-debug.apk` |
| Debug APK `aapt dump badging` | package `app.zyraconnect.zyra`; launchable Activity `app.zyraconnect.zyra.MainActivity` |
| `flutter build apk --release --no-pub` | PASS — `app-release.apk`, 63.5 MB |
| Release APK `aapt dump badging` | package `app.zyraconnect.zyra`; launchable Activity `app.zyraconnect.zyra.MainActivity` |
| Fresh iPhone 17 Pro Simulator install | PASS — canonical bundle installed into a new app container |
| Simulator launch | PASS — PID 21944; ZYRA splash resolved to the real Apple/Google sign-in screen |
| Physical iPhone fresh install | **PENDING — intentionally not attempted because automatic signing still targets the old Personal Team and could implicitly reserve the canonical App ID, crossing the brief's hard boundary** |
| Real Google login + authenticated route | **PENDING — canonical Google iOS/Android OAuth registrations not yet configured** |
| Real Apple login + authenticated route | **PENDING — canonical Apple App ID/capability/entitlement/provider audience not yet configured** |
| Android device runtime | **PENDING — no Android device/emulator connected** |

Build artifact lineage:

| Artifact | SHA-256 |
|---|---|
| iOS Simulator Runner binary | `5fceb8b37509535497a7cd5ee873d2bd31a91ff0e16519206ea5c551fd98554b` |
| iOS Release/no-codesign Runner binary | `24990e87d7ebf690b38a196b100a1cf83c4f4970b69800d6fb30dd16a41c2d85` |
| Android Debug APK | `bec359d416b678b815cb90ab6f0369952c3c33bda29d0d3d670ccd1b54d1ca26` |
| Android Release APK | `4a85b08dcfe0d3d4aa9c3dd0a6b5ecccbe0b6713f1c36dfa31033d83acbef696` |

Android builds emit existing future-compatibility warnings about plugins that
still apply the Kotlin Gradle Plugin (especially `sign_in_with_apple`) and
Gradle 10 deprecations. They do not fail this work, but are technical debt and
must not be mistaken for identifier defects.

## 7. Sweep result and deliberate remaining hits

The live mobile sweep across `SOURCE` (excluding generated build/cache/Pods)
finds legacy identifiers only in:

1. `SOURCE/test/bundle_identifier_contract_test.dart` — negative assertions
   that prevent regression.
2. `SOURCE/macos/Runner/Configs/AppInfo.xcconfig` — dormant macOS target,
   deliberately outside DR-ZYRA-218's iOS + Android scope and not a shipping
   ZYRA platform in this slice.

Governed decisions, briefs, register rows and archived backups retain the old
values as historical before-state evidence; they are not live configuration.

## 8. Mock versus production

- The new identifier values are production source and appear in real built
  iOS/Android products.
- The simulator launch is real runtime evidence, not a mock screenshot.
- OAuth provider registration has **not** been mocked or bypassed. Developer
  account controls cannot grant a production provider token.
- No database or persisted user data was changed. A different bundle ID gets a
  separate app container, so existing developer installs appear beside the
  new app and do not share local session/cache/preferences. This is expected;
  there are no production users to migrate.

## 9. Exact remaining sequence / owner

1. **Founder-guided Google Cloud action:** rebind the existing iOS OAuth client
   to `app.zyraconnect.zyra` if the console permits it, otherwise create a new
   iOS client. Create an Android OAuth client for package
   `app.zyraconnect.zyra` plus the measured SHA-1. Creating persistent OAuth
   credentials requires Founder confirmation/passkey.
2. **Codex:** if Google issues a new iOS client ID, update all three paired
   locations together: `ios/Runner/Info.plist` `GIDClientID`, its reversed URL
   scheme, and gitignored `lib/config/oauth_config.dart`; keep the web/server
   client unchanged unless Google explicitly replaces it.
3. **Codex/Founder-guided Supabase:** add the canonical iOS and Android Google
   client IDs after Google creates them; web client remains first. Then perform
   a real Google login and authenticated-route observation.
4. **Runbook Phase 2 only:** register `app.zyraconnect.zyra` under paid Team
   `9Y7Z8F36SJ`, enable Sign in with Apple, add Runner entitlements, switch
   signing team, allow the canonical Apple client in Supabase, and measure a
   real Apple login. Do not perform these as part of OA-ZYRA-268.
5. **Fable:** verify this handover against disk, reconcile OA-ZYRA-268's status,
   and retain the OAuth/runtime remainder as an open measured gate rather than
   closing it by inference.

## 10. Authority map

| Truth | Authority |
|---|---|
| Canonical identifier decision | DR-ZYRA-218 |
| Execution tracking | OA-ZYRA-268 |
| Build contract | Fable message 015 |
| Paid Apple membership / Team ID | Fable message 016 + App Store Runbook V1 |
| Live implementation | Files and hashes in §3 |
| Point-in-time measured handover | This 017 |
| Independent verification | PENDING — Fable |
| Founder approval | PENDING |

— END —
