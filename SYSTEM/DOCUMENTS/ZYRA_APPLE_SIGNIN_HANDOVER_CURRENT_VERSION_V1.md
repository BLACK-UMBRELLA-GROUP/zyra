# ZYRA Apple Sign-In — As-Built Handover

**Version:** V1  
**Status:** CURRENT_VERSION — paid-team App ID/capability and internal TestFlight build verified; provider audience and real Apple login verification pending  
**Date:** 2026-09-12  
**Implementer:** Codex (Lead Architect)  
**Documentation review:** PENDING — Fable has not yet checked this handover against the live files  
**Authority:** Founder instruction, 2026-08-23 (“the apple login page doesnt work, check and fix”); DR-ZYRA-102; OA-102  

## 0AA. Current-state amendment — 2026-09-12

Authenticated App Store Connect verification now proves app `ZYRA Connect`,
Apple ID `6810741513`, Team `9Y7Z8F36SJ`, bundle
`app.zyraconnect.zyra`. The exact ZYRA `1.0.0 (2)` IPA is uploaded and
`Ready to Test`; the sole internal group `Founder Internal` has automatic
distribution OFF, only `admin@zyraconnect.app`, and only build 2. The
invitation is sent; Founder installation and device acceptance remain pending.
This does not prove the Supabase Apple audience or a real Apple login, which
remain separate open checks.

Apple's delivery warning `ITMS-90068: MinimumOSVersion too low` did not block
build 2. That uploaded binary is immutable at minimum iOS 13.0. All three
Xcode source configurations now require iOS 15.0 for the next build
(`SOURCE/ios/Runner.xcodeproj/project.pbxproj` SHA-256
`a46dd7d38630b2abcd473cebdd5660f9581393d649a3c0501a7d4e2e0a267269`),
and release preflight guards that value. A new binary requires a new build
number and separate exact Founder archive/upload authority.

## 0A. Historical current-state amendment — 2026-09-11

The 2026-08-29 blocker below is no longer current source truth.

- `SOURCE/ios/Runner.xcodeproj/project.pbxproj` now sets automatic signing,
  paid Team `9Y7Z8F36SJ` and bundle `app.zyraconnect.zyra` for Runner
  Debug/Profile/Release (SHA-256
  `4a2e785108b8ed4d44e01efb49f69713b1fa3477c4601f8b52426293923d0939`).
- `SOURCE/ios/Runner/Runner.entitlements` now carries
  `com.apple.developer.applesignin = Default` (SHA-256
  `b2cff52cf90d8cc5be5a2803c78f759d1dffcf00f0f54615b5330c53fea46d29`).
- A local Store export created 2026-09-10 19:13 carries application identifier
  `9Y7Z8F36SJ.app.zyraconnect.zyra`, `get-task-allow=false`,
  `beta-reports-active=true`, the Sign in with Apple entitlement and a paid-
  team Store profile expiring 2027-09-10. This proves the paid-team App ID and
  capability existed at export time.
- That IPA predates the Request New Journey TestFlight hold and is not a valid
  release artifact. It must never be uploaded.
- No retained governed record explains who performed the signing/capability
  switch. Implementation bytes prove state, not provenance or approval.
- A 2026-09-11 read-only App Store Connect check redirected a fresh Chrome tab
  to login. Therefore the current app record, agreements, build/upload state,
  canonical Supabase Apple audience and real device Apple login remain
  unverified. No portal or provider change is claimed here.

The source is locally ready for a fresh signed build only after the separate
database release gates close. The sections below preserve the 2026-08-23/29
history and must not be read as the current signing state.

## 0. Historical current-state amendment — 2026-08-29

DR-ZYRA-218 / OA-ZYRA-268 changed the iOS source bundle ID from
`com.shakeelahmed.zyraapp` to `app.zyraconnect.zyra`. The paid Apple Developer
membership is now active (Team ID `9Y7Z8F36SJ`), but this identifier-only
slice deliberately did **not** create the Apple App ID, switch Xcode away from
the existing Personal Team `JB25YJ2T3N`, or add the Sign in with Apple
capability/entitlement. Those actions remain App Store Runbook Phase 2.

The live Supabase Apple provider was re-measured and is enabled but still
allows only `com.shakeelahmed.zyraapp`. It has not been changed speculatively:
the canonical audience must be added when the canonical Apple App ID and
capability are created. Therefore native Apple login on the new bundle remains
**PENDING — not production-capable and not device-verified**. Sections below
retain the 2026-08-23 investigation history; this amendment owns current truth.

## 1. Outcome

The Apple failure was traced end to end.

- Supabase Auth had Apple **Disabled** while Google was enabled.
- The iOS Runner target had no Sign in with Apple entitlement.
- The Apple exception paths in `zyra_auth.dart` swallowed the diagnostic details.
- The live Supabase auth log also contained an earlier rejected Apple token exchange:
  `Passed nonce and nonce in id_token should either both exist or not`
  (HTTP 400, 2026-08-22 19:16:26Z). The current Dart file was modified after
  that event and already passed the hashed nonce into Apple's native request.

Applied:

1. Enabled the Apple provider in the live Supabase project with native Client
   ID `com.shakeelahmed.zyraapp`.
2. Moved raw-nonce generation to Supabase's maintained
   `generateRawNonce()` implementation while retaining SHA-256 for the nonce
   sent to Apple.
3. Added explicit diagnostic logging for Apple authorization, Supabase token
   exchange and unexpected failures in both sign-in and identity-linking flows.
4. Attempted and measured the required iOS entitlement. Xcode refused it
   because Runner is signed by Personal Team `JB25YJ2T3N`; Apple does not
   permit Sign in with Apple on a Personal Team. The entitlement change was
   therefore reverted so the whole iPhone build remains installable.

Current truthful state: server and Dart preparation are complete, but real
Apple login cannot work on the current Personal Team build. A paid/eligible
Apple Developer team must be selected before the native capability can be
checked in and device-verified.

## 2. Why this architecture

ZYRA keeps the native iOS Apple flow:

```text
Apple button
  -> one secure raw nonce from Supabase Auth
  -> SHA-256 nonce sent to AuthenticationServices
  -> Apple identity token
  -> raw nonce + identity token exchanged with Supabase Auth
  -> Supabase session
  -> ZyraSessionRouter
```

The nonce is not removed or bypassed. It protects the token exchange from
replay. ZYRA also continues to capture Apple's one-time `givenName` after a
successful first authorization and stores it as user metadata without turning
a metadata-write failure into a login failure.

Native-only Apple configuration uses the iOS bundle ID as an allowed Supabase
client ID. No Apple OAuth secret is configured because browser/web Apple OAuth
is not part of this build.

## 3. Live files and responsibilities

| File/config | Current responsibility | SHA-256 / measured state |
|---|---|---|
| `SOURCE/lib/services/zyra_auth.dart` | Native Apple credential request, secure nonce exchange, name capture, identity linking and truthful diagnostics | `b5ae209a8853a8091e493e20c8871e7c25d546c201c5c32a28d218a0812353e1` |
| `SOURCE/lib/screens/welcome_screen.dart` | Apple/Google entry UI, one-provider loading state and post-auth routing | unchanged in this work |
| `SOURCE/ios/Runner.xcodeproj/project.pbxproj` | iOS signing team and bundle ID | restored to pre-work SHA `56335240345fdeeb3e9519d0f788d4ac55d65e6d225ba8d5fc1c65edea34ac69` |
| Supabase Auth provider configuration | Accepts native Apple ID tokens for `com.shakeelahmed.zyraapp` | dashboard measured: before `Apple Disabled`; after reload `Apple Enabled` |

No Apple entitlement is present in the live iOS project. That absence is
intentional only to keep Personal Team profile builds working until an
eligible Apple team exists.

## 4. Entry points, controls and boundaries

- Public entry: `WelcomeScreen` -> `ZyraAuth.signInWithApple()`.
- Authenticated backup method: Settings -> `ZyraAuth.linkAppleIdentity()`.
- Platform priority remains unchanged: Apple is first/larger on iOS; Google
  is first/larger on Android.
- There is no mock Apple user and no developer bypass in this flow.
- Supabase configuration is live. On-device Apple authorization is
  **not production-capable** under the current signing team.

## 5. Failure paths

- User cancellation returns `ZyraAuthOutcome.cancelled` and clears the
  selected button's progress state.
- Apple authorization failures are logged as
  `ZYRA Apple sign-in authorization failed: ...`.
- Supabase exchange failures are logged as
  `ZYRA Apple token exchange failed: ...` and mapped to approved calm UI copy.
- Unexpected failures are logged separately and return the connection error.

No tokens, authorization codes, nonce values or credentials are printed.

## 6. Migration and external configuration

- Database migrations: **none**.
- Supabase migration files: **none**.
- Live external change: Apple provider enabled for the native iOS bundle ID.
- Apple Developer change still required: select an eligible paid Developer
  Program team, enable Sign in with Apple for the App ID, then add
  `com.apple.developer.applesignin = Default` to Runner's signed
  entitlements.

## 7. Measurements

| Measurement | Result |
|---|---|
| Supabase auth-log probe, last 24h | Earlier Apple request found: HTTP 400 nonce-presence mismatch; no successful Apple event |
| Supabase dashboard before/after | Apple `Disabled` -> `Enabled`; native client ID saved and survived reload |
| `plutil -lint ios/Runner.xcodeproj/project.pbxproj` | PASS |
| `flutter analyze` | PASS — no issues |
| `flutter test test/zyra_auth_name_test.dart` | PASS — 3/3 |
| Full `flutter test` | PASS — 152/152 |
| `python3 tools/zyra_check.py` | 3 pre-existing heuristics: two exception-constructor false positives and one unused-import heuristic; 0 new dangling references |
| Profile build with Apple entitlement | FAIL as expected: Personal Team does not support Sign in with Apple; provisioning profile lacks the capability |
| Profile build after reverting unsupported entitlement | PASS — `build/ios/iphoneos/Runner.app`, 32.6 MB |
| Real Apple device login | **PENDING — blocked by Apple Developer team eligibility** |

## 8. Remaining gap and next steps

1. Founder selects or enrols an Apple Developer Program team that supports
   Sign in with Apple.
2. Lead Architect adds the Runner entitlement to Debug/Profile/Release and
   confirms Xcode's generated provisioning profile contains it.
3. Build and install with `./run.sh`.
4. Perform a real first-time Apple login and a returning Apple login on the
   iPhone.
5. Measure Supabase auth logs for a successful
   `grant_type=id_token, provider=apple` exchange and verify routing.
6. Fable checks this handover against code and reconciles OA-102's current
   “ACHIEVED” wording, which presently overstates Apple readiness.

No new OA is filed in this implementation turn: Fable owns governed register
filing, and the next action depends first on the Founder's external Apple
Developer membership decision. This explicit refusal prevents an unapproved
identifier reservation while keeping the gap visible.

## 9. Authority map

| Truth | Authority |
|---|---|
| Product sign-in rule | DR-ZYRA-102 / OA-102 |
| Live implementation | `SOURCE/lib/services/zyra_auth.dart`, `SOURCE/lib/screens/welcome_screen.dart` |
| Current as-built and blocker | This handover |
| External provider reference | Supabase Auth Apple provider configuration |

— END —
