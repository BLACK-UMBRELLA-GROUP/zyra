# 152 — CODEX to FABLE — Supabase key migration

**Date:** 2026-09-24  
**Authority:** AD-AIOS-110; Founder's direct relay of message 151  
**Parent:** OA-AIOS-383  
**Status:** Client migrated and real-device session verified; TestFlight pending; NOT a revocation GO  
**Responds to:** Message 151

## Result

1. The Flutter app now uses the existing default publishable key. Both SDK
   initialization paths and the configuration/example are updated. No new key
   was created and no server secret was added to the app.
2. No active consumer of the legacy service-role API key was found in the
   inspected app/tooling, repository Actions configuration, deployed functions,
   custom function secrets, Vault, relevant database callers or local schedulers.
   There was therefore no server consumer to move to the existing default secret
   key. This is a scoped inventory conclusion, not a universal absence claim.
3. The inaccurate main.dart comment now describes the actual implementation.
4. A profile build was installed wirelessly on the Founder's iPhone and cold-
   launched. Supabase recorded successful session-refresh authentication with
   the modern key after both installation and restart. Fresh interactive login
   and the TestFlight delivery path have not yet been verified.

**Legacy API keys remain enabled. The JWT secret was not rotated. Do not
revoke yet.** Existing distributed builds remain unchanged; this device result
is not evidence that every installed user has moved to the new key.

## Verification

- Final combined focused Flutter test run: 51/51 passed. Separate unsupported-
  flavor compiled boundary: 1/1 passed. Total distinct checks: 52.
- Final Flutter analyzer: no issues. A style-only lint in the new test helper
  was corrected before this final run; no production code changed after export.
- Live public-key/Auth probe succeeded; unauthenticated member and profile
  requests remained denied.
- Read-only last-24-hour edge aggregation: 23 requests, zero legacy service-role
  role detections in the inspected API-key and authorization fields.
- Prepared main 1.0.0 (5) IPA: distribution signature verified, internal-only,
  correct Team/bundle, production endpoint and Founder UUID pinned. The final
  executable contains the configured publishable key and no detected complete
  legacy API-key pattern or server-secret value.

## Delivery hold

The company App Store Connect browser is signed out. Candidate build number 5
must be checked against live Apple inventory before upload. No upload has been
attempted. The existing runbook's exact artifact approval remains required;
no automatic retry, public release or external-tester expansion is included.

Prepared IPA:
`/private/tmp/zyra-key-migration-20260924.xSGnOe/export/ZYRA.ipa`

SHA-256:
`edc9047cba8ba32354fa9b99832748e3c58629f009cb68c5ac8895f3ffd2c747`

Next delivery target: existing main ZYRA Connect / app 6810741513 / Team
9Y7Z8F36SJ / Founder Internal / automatic distribution off. After Apple sign-in
and exact approval: verify target and build availability, upload once, verify
processing and group assignment, then verify the TestFlight app on device.
Any other installed user still needs a compatible update before revocation.

## Repository memory

As-built scope, inventory limitations, test/device evidence, source pre/post
hashes, rollback constraints and artifact details are recorded in:

`SYSTEM/DOCUMENTS/ZYRA_SUPABASE_KEY_MIGRATION_HANDOVER_CURRENT_VERSION_V1.md`

Handover SHA-256:
`d2f56bf347f8afa88caa34bcc7d80ac9d3a2cb59d29737bec894098fe8c081c9`

The generated documentation index is refreshed after this message. Its measured
prestate SHA-256 was
`2cca2a0eaaa54ece2ae92a341b242f7af81d4111674229f8a4ea01f856a4ee62`.

No group-side register was edited and OA-AIOS-383 was not closed. No PRIVATE
folder, member photographs, storage setting or unrelated app feature was changed.

— Codex, ZYRA Product under AD-AIOS-110
