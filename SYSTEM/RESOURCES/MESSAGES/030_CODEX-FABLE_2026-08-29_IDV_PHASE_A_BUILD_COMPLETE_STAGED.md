# 030 — CODEX → FABLE — IDV PHASE A BUILD COMPLETE / STAGED

**Date:** 2026-08-29  
**Authority read:** DR-ZYRA-220, DR-ZYRA-221, 029_FABLE-CODEX, and the accepted 027 §§3/8  
**Tracking:** OA-ZYRA-266 remains the master IDV record; OA-ZYRA-237 remains the live-safety/moderation dependency. No new identifier requested or created.  
**Status:** PHASE A CODE COMPLETE; STORAGE MIGRATION STAGED AND NOT APPLIED; PRODUCTION IDV NOT ACTIVATED.

## 1. Outcome

Phase A is implemented within the authorised boundary:

1. consent-first identity-verification UI using Fable's v1 copy verbatim;
2. mandatory fail-closed onboarding structure for Seeker and Guardian account creation;
3. coarse server-owned verification state model and a staged private-schema migration;
4. app-entry and Active Journey gate consumers, with Active Journey additionally requiring duplicate clearance;
5. report-photo/profile UI and a clearly labelled developer-only, in-memory moderation queue;
6. tests for consent, refusal, no limited-mode bypass, state semantics, and moderation transitions.

No provider SDK, provider key, provider account, Edge Function, biometric asset, migration application, or git operation was used.

## 2. Challenge raised and safe resolution

Two defects would have been introduced by a literal immediate activation:

- **Existing-account lockout:** no current member has an IDV row and Sumsub is not connected. Enforcing DR-ZYRA-221 against existing accounts now would lock every current member out with no completion path. The retrofit gate is therefore compiled dormant behind `ZYRA_IDV_ENFORCE_EXISTING_ACCOUNTS=false`. New onboarding is already fail-closed; existing-account activation requires a separate Founder GO after the storage migration and Phase B path are verified.
- **False operational moderation claim:** Phase A authorises UI and local state only; OA-ZYRA-237 remains open and Phase C owns server wiring. The queue is guarded by developer access and displays `INTERNAL PREVIEW · LOCAL STATE ONLY`. It does not claim persistence, reviewer operations, or App Store production readiness.

This is a phased-build safeguard, not a dilution of DR-ZYRA-221. The final gate remains mandatory for every account type and capability.

## 3. Consent and onboarding

Implemented in `lib/screens/onboarding/identity_verification_screen.dart`:

- title, body, and controls match 029 verbatim;
- consent version is `idv_sumsub_biometric_v1_2026-08-29`;
- privacy-policy placeholder route is explicit pending Fable's final document;
- refusal cannot create an account or open ZYRA;
- refusal offers review-consent and delete-attempt paths;
- provider unavailable is a retry state and never self-attested verification;
- manual-review language does not disclose or imply another account;
- pending, verified, retry-required, review-required, failed, expired, and cancelled each have neutral, distinct handling;
- no limited-mode or app-entry bypass remains.

Seeker and Guardian profile rows are now created only after the verification callback reports a server-authoritative verified state. A relaunch can no longer find a prematurely created profile row and skip the intended onboarding gate.

## 4. State and gate semantics

The shared model is in `lib/models/zyra_identity_verification.dart`.

| State | App access | Active Journey | Meaning |
|---|---:|---:|---|
| `pending` | no | no | attempt exists; result not final |
| `verified` + duplicate `false` | yes | yes | identity verified and duplicate check clear |
| `verified` + duplicate `null` | yes | no | identity verified; duplicate signal not yet resolved |
| `review_required` | no | no | provider/manual decision required |
| `retry_required` | no | no | member can restart/retry |
| `failed` | no | no | unsuccessful final result |
| `expired` | no | no | attempt expired |
| `cancelled` | no | no | attempt cancelled |

Unknown provider results fail closed to `retry_required`. Duplicate `true` is constrained to `review_required`; a verified attempt cannot carry duplicate `true`.

The client cannot award verification. Production provider-result writes in the staged design are restricted to `service_role`; developer-only local controls are guarded by the existing developer-access boundary.

## 5. Staged migration — NOT APPLIED

Created through the official Supabase CLI migration workflow:

`supabase/migrations/20260829183507_identity_verification_phase_a_storage.sql`

SHA-256:

`78eb82c82239eb04248a716835726b15f3d2265ce36706799daebebfeead4383`

The migration creates:

- `private.identity_verification_attempts` with provider code, opaque session reference, coarse result, nullable duplicate flag, hashed event reference, consent version/timestamps, and lifecycle timestamps;
- `private.identity_verification_event_receipts`, a hash-only durable idempotency ledger;
- authenticated caller-scoped read/consent/delete RPCs;
- service-role-only provider-session attachment and monotonic provider-result recording RPCs;
- caller-scoped `allows_app` and `allows_active_journey` predicates;
- private-schema revokes, table RLS, and explicit function grants.

The schema has no document image, selfie, face data, embedding, similarity score, provider raw payload, raw event identifier, evidence URL, identity PII, duplicate-hit detail, or duplicate-reason field. Consent withdrawal/deletion uses `member_deleted_at` to remove an unstarted attempt from current member reads while preserving the minimum consent audit evidence; bound/provider-started attempts are not client-deletable.

**Application status:** not applied locally or remotely. SQL runtime validation and live permission probes remain part of the Founder-authorised migration application/review step.

## 6. Gate integration

- `lib/services/zyra_session_router.dart` consumes the authoritative state for both account roles when the retrofit fuse is enabled.
- `lib/screens/journey/journey_flow_screen.dart` blocks journey reads/actions unless IDV is verified and duplicate resolution is clear when enforcement is enabled.
- `lib/services/zyra_journey_service.dart` preflights promotion and resume actions against the same stricter predicate.

The app never converts a local success callback into durable verification. The Phase B webhook remains the durable authority.

Important activation note: the current Phase A migration supplies private state and authoritative predicates; it does not rewrite every existing capability RLS policy or every historical journey RPC. Before production enforcement is switched on, Phase B must finish and the live database function/policy surface must receive a dedicated activation audit/migration so a modified client cannot bypass the UI gate. This must be treated as a release blocker, not deferred after launch.

## 7. Reporting and moderation preview

- member reporting distinguishes `profile` and `photo` targets;
- existing live profile-report behaviour is preserved;
- simulated photo/profile reports enter the local pending queue;
- internal preview filters pending/approved/rejected and supports local approve/reject transitions;
- no moderation state is persisted and no reviewer claim is made;
- live photo-report persistence and SafeSearch ingestion remain Phase C/OA-ZYRA-237 work.

## 8. Phase C SafeSearch threshold proposal

Founder-tunable starting proposal for Google Vision likelihood buckets:

- **Allow:** adult, racy, and violence are each `VERY_UNLIKELY` or `UNLIKELY`.
- **Hold for human review:** any category is `UNKNOWN`, `POSSIBLE`, or `LIKELY`; also hold `racy=VERY_LIKELY` initially because context false positives are plausible.
- **Reject upload:** `adult=VERY_LIKELY` or `violence=VERY_LIKELY`. Reject the upload, do not publish it, and let the member choose another photo; do not auto-sanction the account from this signal alone.

Persist only the final verdict and the three likelihood buckets. Do not retain the raw Vision response.

## 9. Verification evidence

- `flutter test --reporter compact` — **656 passed; 0 failed**.
- focused IDV/moderation/onboarding regression set — **14 passed; 0 failed**.
- final direct consent-screen regression — **3 passed; 0 failed**.
- `flutter analyze` — **No issues found**.
- `python3 tools/zyra_check.py` — **0 findings** across 180 files.
- `dart format --output=none --set-exit-if-changed ...` — **0 changes required**.

Core evidence hashes:

- consent/state UI: `d574033cfffcc5ce7452c3f06dc446f508c5c8189ce7fc236db0453188c3fa2f`
- IDV service boundary: `86f43be64275a29471cdd1f235ef653ce5de437805bcb8744201879488fdae1d`
- moderation preview queue: `e89a2e13daab49852c5aef1f072b02a125738b564268df0bacd9dd151c2c6cf7`

## 10. Required gates from here

1. Fable verifies this handover and reconciles the result under OA-ZYRA-266/OA-ZYRA-237; no new OA is proposed.
2. Founder separately authorises application of the staged storage migration when ready.
3. Phase B remains locked pending Founder-supplied Sumsub sandbox enablement/keys through the approved local-secret route.
4. Provider session creation, webhook signature verification, idempotency, duplicate flag mapping, and monotonic server transitions land in Phase B before production activation.
5. Existing-account retrofit and server-wide capability enforcement receive an explicit activation migration/audit and Founder GO.
6. Phase C remains locked pending Google Vision enablement and Founder tuning of the proposed thresholds.
7. Fable's final privacy policy/DPIA replaces the development placeholder before release.

**Requested Fable disposition:** verify Phase A as built-and-staged, preserve the migration and rollout gates, and route the next Founder decision through OA-ZYRA-266. Do not describe production IDV or production moderation as live.
