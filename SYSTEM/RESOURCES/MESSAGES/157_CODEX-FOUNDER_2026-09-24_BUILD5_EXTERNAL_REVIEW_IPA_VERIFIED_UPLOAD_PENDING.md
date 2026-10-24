# 157 — ZYRA build 5 external-review IPA verified; upload pending

TO: Founder  
FROM: Codex  
DATE: 2026-09-24  
AUTHORITY: Direct Founder confirmation in the ZYRA app task  
STATE: FOUNDER GO → EXECUTED → POST-VERIFIED; upload NOT STARTED

- Signed ZYRA `1.0.0 (5)` external-TestFlight IPA exported successfully.
- Team, bundle, signature, profile, entitlements, version/build and external
  eligibility all passed verification.
- The existing Apple Distribution identity and Store profile were reused; no
  new signing asset was created.
- No upload, external-group change, tester notification, App Review credential
  entry, reviewer reply or submission occurred.

## Immutable artifact

Path: `SOURCE/build/ios/ipa/ZYRA.ipa`  
SHA-256: `da89aff38201eee83bb0f3685b09a6c1350b9853e34bee831c99e9a44940fca0`  
Size: 25,581,029 bytes

| Check | Verified value |
| --- | --- |
| App Store Connect app | ZYRA Connect; Apple ID 6810741513 |
| Bundle | app.zyraconnect.zyra |
| Version / build / display | 1.0.0 / 5 / ZYRA |
| Team | 9Y7Z8F36SJ |
| Minimum iOS | 15.0 |
| Signing | Apple Distribution; deep/strict verification passed |
| Store profile | Existing UUID 07c3e51d-0bc9-41a9-8b54-ce5be5c94a19 |
| Entitlements | get-task-allow=false; beta reports active; Apple sign-in Default |
| Encryption declaration | Non-exempt encryption false |
| External eligibility | TFInternalTestingOnly absent |

## Next exact gate

Founder GO must bind to the artifact hash above, ZYRA Connect Apple ID
`6810741513`, Team `9Y7Z8F36SJ`, bundle `app.zyraconnect.zyra`, version/build
`1.0.0 (5)` and a single upload. Stop on any drift or failure. Apple processing
must be verified before group assignment.

Demo credential entry, replying to Apple and submitting for TestFlight App
Review are separate representational actions and require action-time Founder
confirmation after the form is prepared.
