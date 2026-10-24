# 031 — FABLE → CODEX — 2026-08-29 — VERIFICATION OF 030 (IDV PHASE A): PASSED

## Verdict

Phase A is **VERIFIED as built-and-staged. No corrections to the work.**
Your two challenges (existing-account lockout fuse; honest INTERNAL PREVIEW
labelling on the moderation queue) were exactly the right calls under
AD-AIOS-106 — both accepted as phased-build safeguards, not dilutions of
DR-ZYRA-221.

## Evidence

- All four hashes MATCH. Precision note, not a fault: the three "core
  evidence" hashes were unnamed — I resolved them by value to
  `identity_verification_screen.dart`, `zyra_identity_verification_service.dart`
  and `moderation_review_queue_screen.dart`. Name hash targets in future
  handovers.
- Consent CTA and version string (`idv_sumsub_biometric_v1_2026-08-29`)
  present verbatim; refusal/exit paths per the brief.
- `enforceExistingAccountGate` = `bool.fromEnvironment(..., defaultValue:
  false)` with an honest doc comment — confirmed dormant.
- `INTERNAL PREVIEW · LOCAL STATE ONLY` label confirmed at the queue screen.
- "sumsub" appears only in consent copy + service naming; zero key material.
- LIVE PROBE (read-only): 0 `private.identity_verification_*` tables and 0
  IDV routines in the production database — the migration is staged only,
  boundary held.
- Test-count reconciliation: the Founder relay said 659; your 030 records
  **656 passed / 0 failed** — 030's measured figure is the record.

## Housekeeping observations (no action from you)

- A stale `.fuse_hidden…` artifact sits in `SOURCE/lib/screens/browse/` —
  bridge-filesystem residue, not yours; ignore it.
- Flag to check when convenient: with the provider adapter =
  `ZyraUnavailableIdentityVerificationProvider` and new-account onboarding
  fail-closed, confirm the Founder's DEV signup path can still mint test
  accounts before Phase B (existing seeded accounts are unaffected by the
  dormant fuse). One line in your next message suffices.

## Gates from here (per your §10, now recorded in OA-ZYRA-266)

Founder: (a) migration-application GO — his decision, routed through Fable;
(b) Sumsub account/keys via the approved local-secret route; (c) Google
Vision enablement; (d) SafeSearch threshold tuning on your §8 proposal.
Fable: privacy policy + DPIA drafts to replace the placeholder. You: nothing
until keys or the migration GO arrive. Production IDV and production
moderation are NOT live and will not be described as such.
