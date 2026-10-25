---
id: DOC-ZYRA-9002
type: REPORT
status: CURRENT
feature: REPORTS
purpose: ZYRA Identity, Face and Profile-Photo Verification — Phases 1–3 Technical Review
links: []
owner: ZYRA chat
---

# ZYRA Identity, Face and Profile-Photo Verification — Phases 1–3 Technical Review

**Status:** PRE-DECISION — EXTERNAL SERVICE GATE ACTIVE  
**Version:** V1  
**Date:** 2026-08-26  
**Author:** Codex, Lead Architect  
**Scope:** Repository audit, provider comparison, privacy/security boundary, cost model, and vendor-neutral production architecture only  
**Decision authority:** Founder, following independent Claude review  

## Executive verdict

1. **A specialist external verification service is required.** ZYRA should not build document authentication, liveness detection, biometric matching or a face database itself.
2. **No provider is selected.** The recommended technical co-finalists are **Entrust Identity Verification (Onfido)** and **Veriff**. **Sumsub** is a conditional third finalist. Veriff presently has the best combination of current Flutter support, Saudi/Arabic evidence, recurring biometric authentication and public pricing; Entrust has a strong document/biometric/duplicate platform but a 2026 Flutter SDK transition and quote-only pricing.
3. **The decisive capability is not yet proved by any finalist's public material:** comparing an arbitrary uploaded/gallery profile photo—not a fresh live selfie—against the person originally verified. This must be demonstrated, priced and contractually supported before selection.
4. **ZYRA must remain server-authoritative.** Provider callbacks and client SDK completion events never grant verification. A signed, replay-protected provider webhook must update a private backend state; profile publication and every replacement photo must read that state.
5. **Production work is stopped at the Founder's external-service gate.** No provider signup, SDK, credentials, migration, Edge Function, paid resource or vendor-specific code has been added.

## Governance and trace

The live ZYRA outstanding-action register reported `OA-ZYRA-263` as the next identifier when read on 2026-08-26. This report proposes one umbrella action:

> **Proposed OA-ZYRA-263 — Production identity, liveness and profile-photo ownership verification programme**

It is **not filed or reserved** here. Fable owns the register and must reread the live next identifier immediately before filing. This is an explicit concurrency refusal: Codex will not mutate Fable's register or pre-allocate a sequential identifier during a provider-decision review. Findings below use temporary trace labels `F01`–`F12`; Fable should nest them under the live umbrella OA or allocate child OAs when reconciling this report.

## Phase 1 — Existing ZYRA audit

### Measured repository scope

| Measurement | Result |
|---|---:|
| Repository SQL migrations inspected/searchable | 203 |
| Top-level Flutter test files | 39 |
| Supabase SQL suites | 8 |
| Supabase Edge Function files/directories | 0 |
| IDV/KYC/liveness provider dependencies | 0 |
| Verification tables/RPCs/webhook handlers/provider-session models | 0 |
| Tests covering `ProfileReadyScreen`, `ZyraPhotoService`, `zyra_set_profile_complete`, ID/liveness or photo ownership | 0 |

No live database was probed. No credentials or real identity content were accessed.

### Existing authentication

Apple and Google native identity tokens are exchanged directly with Supabase Auth. Linked identities remain attached to one Supabase user. Passwordless recovery correctly uses `shouldCreateUser: false`, which prevents an unknown recovery email from manufacturing an account, but does not detect the same real person returning under a new OAuth identity.

Evidence:

- `SOURCE/lib/services/zyra_auth.dart:170` — Google sign-in.
- `SOURCE/lib/services/zyra_auth.dart:202` — Apple sign-in with nonce.
- `SOURCE/lib/services/zyra_auth.dart:249` — linked identity path.
- `SOURCE/lib/services/zyra_auth.dart:414` — non-creating recovery OTP.
- `SOURCE/lib/services/zyra_session_router.dart:87` — routing checks a profile row/role, not verification.

Authentication proves control of an Apple/Google identity. It does not prove legal identity, age, face ownership, unique-person status or Guardian relationship.

### Existing identity and publication

`zyra_create_profile` validates a self-declared name, gender and DOB and enforces a calculated 18+ rule. It does not consume provider evidence. `first_published_at` permanently freezes DOB/gender after first publication, which is a useful future seam.

The publication RPC, `zyra_set_profile_complete`, is server-side but currently checks only:

- declared identity fields exist; and
- a Seeker owns at least one `profile_photos` row.

It does not check identity verification, liveness, moderation or photo ownership.

Evidence:

- `SOURCE/supabase/migrations/20260804105522_c3_profile_rpcs_and_column_lockdown.sql:39`.
- `SOURCE/supabase/migrations/20260804104339_c4_minimum_age_enforcement.sql:39`.
- `SOURCE/supabase/migrations/20260807183341_freeze_identity_on_first_publication.sql:37`.
- `SOURCE/supabase/migrations/20260807183341_freeze_identity_on_first_publication.sql:69`.

### Critical mock-to-production defect — F01

The onboarding verification mock is wired to the real publication boundary:

1. `ProfileReadyScreen` states that photo and ID checks are mocked.
2. A two-second timer sets photo approval.
3. A second two-second timer sets ID verified.
4. Those local booleans call the real `zyra_set_profile_complete(true)` RPC.
5. A visible “simulate failed check” action has no release/developer-access guard.

Evidence: `SOURCE/lib/screens/onboarding/profile_ready_screen.dart:1-6`, `:36-47`, `:50-91`, and `:189-201`.

This does not let the client update `profile_complete` directly, but it does let manufactured client facts satisfy an under-specified server gate. It is the first production defect to close once an implementation phase is authorised. Until the real backend exists, the safe interim is fail-closed publication, not another mock success path.

### Existing profile-photo path — F02/F03

The real path is currently:

`gallery picker → client reads bytes → trusts filename extension → direct client upload to profile-photos → signed URL → client deletes/reinserts profile_photos rows`

The bucket is private, which is good, but it is simultaneously the upload and display bucket. The current table contains path/order/primary only. Owners can insert, update and delete their own rows. There is no quarantine, immutable job version, MIME inspection, byte-size validation, EXIF guarantee, moderation state, face-count state, ownership state or manual-review state.

Evidence:

- `SOURCE/lib/services/zyra_photo_service.dart:224-293`.
- `SOURCE/supabase/migrations/20260718190011_initial_schema.sql:100-139`.
- `SOURCE/supabase/migrations/20260719080749_private_profile_photos_bucket.sql:20`.
- `SOURCE/supabase/migrations/20260805232842_photo_storage_read_by_displaying_profile.sql:47-89`.

The UI asks for three photos, but the server accepts one. Photo replacement after onboarding is still a stub.

- `SOURCE/lib/screens/onboarding/chapter2_flow.dart:313`.
- `SOURCE/supabase/migrations/20260807183341_freeze_identity_on_first_publication.sql:102-108`.
- `SOURCE/lib/screens/profile/profile_screen.dart:236`.

### Guardian identity and relationship — F04

A Guardian currently self-declares name, DOB and gender and is immediately published because the code explicitly states there is no ID check. The relationship is correctly stored per Guardian–Seeker link as a Guardian's claim; that is not evidence of kinship.

Evidence:

- `SOURCE/lib/screens/wali/wali_onboarding_flow.dart:47`.
- `SOURCE/lib/services/zyra_profile_service.dart:123-146`.
- `SOURCE/supabase/migrations/20260807140750_wali_invites_relationship_flow_b.sql:8`.
- `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_RELATIONSHIP_CAPTURE_FLOWS_CURRENT_VERSION_V1.md:8`.

The normal Guardian pages correctly omit a verified badge because no verification system exists, but the Guardian Network preview renders `✓ VERIFIED` and `ID verified · 2026`. Those strings are provisional mock presentation and must never be promoted into production evidence.

- `SOURCE/lib/screens/wali/guardian_detail_screen.dart:11-19`.
- `SOURCE/lib/screens/wali/seeker_wali_tab.dart:17-20`.
- `SOURCE/lib/screens/wali/wali_gn_shared.dart:658-674`, `:925-930`, `:1369-1404`.

### Recovery, deletion and re-verification — F05

Account deletion removes Supabase rows and profile-photo objects. It cannot request or confirm erasure from a future verification provider. Identity Correction is approved but unbuilt; the reviewer, evidence, SLA, audit trail and reversibility are unresolved.

- `SOURCE/lib/services/zyra_auth.dart:522-568`.
- `SOURCE/supabase/migrations/20260726170000_delete_own_account.sql:36`.
- `SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V2.md:203-219`.

Profile reset correctly preserves frozen identity. Future verified identity must also survive profile reset without preserving deleted profile-photo biometric material unnecessarily.

### Developer/testing gap — F06

Developer tooling contains labels for verification but no real state model or reader. The requested matrix—Not started, ID capture, liveness capture, processing, verified, retry, manual review, rejected, photo states, provider unavailable and re-verification—does not exist. No test covers the current verification mock or its publication effect.

Any future mock adapter must be physically incapable of invoking the production state-transition authority in release builds.

### Documentation drift — F07

Current governed documents already describe more than the code provides:

- `IMAGE_HANDLING_CURRENT_VERSION_V2.md` specifies server validation, EXIF stripping, derivatives, face detection, safety/authenticity checks, human review, three photos and completed ID verification. None of that pipeline is built.
- OA-ZYRA-131 is marked actioned because its wording was merged into the image standard, not because engineering exists.
- `APP/Onboarding/PROFILE COMPLETION/Summary.md` says nothing is permanent and personal information remains editable, conflicting with the approved identity freeze and any future verified identity.
- `WALI_ARCHITECTURE_CURRENT_VERSION_V6.md` refers to verified email/mobile and a Verified Guardian badge, while ZYRA has no phone verification or Guardian ID verification.
- `ZYRA_LEGAL_RESEARCH_CURRENT_VERSION_V1.md` honestly records that identity/photo verification is absent and that processor, transfer, retention and disclaimer coverage is needed.

These documents must be reconciled only after the Founder approves the provider/architecture decision.

## Phase 2 — External provider review

### Outsource versus own

**Outsource to a specialist:**

- government-document capture, validity/authenticity, OCR and NFC;
- live selfie/video/motion capture;
- liveness, presentation-attack, replay/injection and deepfake detection;
- ID portrait to live-face comparison;
- 1:1 returning-user biometric authentication;
- tenant-scoped duplicate/known-person signals where approved;
- specialist/manual verification review;
- biometric templates and raw capture retention under contract.

**ZYRA owns:**

- purpose, consent and legal-basis UX/evidence;
- when verification and re-verification are required;
- authenticated server-side session creation;
- webhook authentication, replay protection and idempotency;
- minimal, server-owned verification state;
- publication and photo-visibility gates;
- badge meaning;
- Guardian relationship confirmation as a separate claim;
- failure copy, appeals and support routing;
- provider deletion orchestration and audit;
- privacy-safe aggregate monitoring and cost accounting.

### Provider comparison

| Provider | Document + age | Face/liveness | Duplicate/re-auth | Flutter | UK/Saudi | Profile-photo proof | Pricing | Technical verdict |
|---|---|---|---|---|---|---|---|---|
| **Veriff** | Yes | Passive liveness, replay/injection/deepfake signals | Biometric Authentication; FaceBlock/CrossLinks | First-party SDK; 7.1.0 published Aug 2026 | 230+ territories; official Saudi ID/residence-permit Arabic evidence | **Not proved for arbitrary gallery photo** | $0.80 / $1.39 / $1.89 tiers | **Co-finalist; current integration/cost edge** |
| **Entrust / Onfido** | Yes; 2,500+ documents/195 countries | Photo/video/Motion; Motion iBeta PAD L2 | Known Faces and reverification | First-party legacy Flutter supported; replacement SDK transition during 2026 | Strong UK; current Saudi matrix must be supplied | **Not proved; public reports expect live media** | Quote only | **Co-finalist; strong assurance/platform depth** |
| **Sumsub** | Yes | Advanced liveness and face match | Duplicate signals and face authentication | Current Flutter SDK, but Flutter 1.38 removed Face Authentication actions | Official Saudi physical/digital ID/passport/residence/NFC evidence | **Not proved; current flow starts with liveness** | $1.35 Basic; $1.85 Compliance | **Conditional finalist after parity/security diligence** |
| Persona | Yes | Selfie/video liveness | Accounts, Face Lists, fraud graph | No first-party Flutter; hosted/native bridge needed | Global claim; current Saudi document proof needed | Not proved | Quote / eligibility-limited startup offer | Strong workflow alternative, weaker Flutter fit |
| Stripe Identity | Yes | Matching selfie | Review tools; no full returning-biometric lifecycle | Hosted/iOS/Android/React Native, no first-party Flutter | Saudi listed, but Arabic-script extraction unsupported | Not supported publicly | £1.25 UK completed verification | Initial-IDV fallback only |
| FaceTec | ID scan plus 3D face stack | Strong 3D liveness | Re-auth and 1:N | No first-party Flutter found | Contract-dependent | **Explicit 3D-to-arbitrary-2D portrait API** | Quote | Possible two-vendor add-on; conflicts with minimal ZYRA biometric custody |
| iProov | Not a full document vendor | High-assurance liveness/auth | Returning authentication | Official Flutter wrapper | Contract-dependent | Not documented | Quote | Liveness layer only, not primary vendor |

Primary sources:

- Veriff: [Identity Verification](https://www.veriff.com/product/identity-verification), [Biometric Authentication](https://devdocs.veriff.com/docs/biometric-authentication), [Flutter releases](https://devdocs.veriff.com/docs/release-notes), [Saudi Arabic support](https://www.veriff.com/blog/veriff-now-supports-arabic-documents), [retention](https://www.veriff.com/data-retention/ver-vdr-2301), [pricing](https://www.veriff.com/plans/self-serve).
- Entrust: [product overview](https://www.entrust.com/products/identity-verification), [document/biometric reports](https://documentation.identity.entrust.com/getting-started/general-introduction), [Flutter SDK](https://documentation.identity.entrust.com/sdk/flutter), [Known Faces](https://documentation.identity.entrust.com/guide/known-faces-report).
- Sumsub: [pricing](https://sumsub.com/pricing/), [face authentication](https://docs.sumsub.com/reference/face-authentication), [Flutter changelog](https://docs.sumsub.com/docs/flutter-plugin-changelog), [duplicate risk labels](https://docs.sumsub.com/docs/applicant-risk-labels), [go-live/liveness](https://docs.sumsub.com/docs/go-live).
- Persona: [integration choices](https://docs.withpersona.com/choosing-an-integration-method), [mobile SDKs](https://docs.withpersona.com/mobile-sdks), [startup offer](https://withpersona.com/startups/).
- Stripe: [verification checks/coverage](https://docs.stripe.com/identity/verification-checks?locale=en-GB), [UK pricing](https://stripe.com/gb/identity), [redaction](https://docs.stripe.com/api/identity/verification_sessions/redact).
- FaceTec: [API suite](https://api-docs-postman.facetec.com/), [data boundary](https://www.facetec.com/data), [developers](https://www.facetec.com/developers).
- iProov: [product overview](https://docs.iproov.com/getting-started/product-overview), [Flutter SDK](https://github.com/iProov/flutter).

### Technical recommendation to Claude and Founder

Run the same scripted proof-of-capability and commercial RFP with **Veriff and Entrust first**. Include **Sumsub only after** it answers the current Flutter recurring-auth parity, retention and 2026 incident-remediation questions.

The provisional preference is **Veriff** for ZYRA's present Flutter/UK/Saudi/cost shape, but it is not approvable until it demonstrates the exact uploaded-profile-photo operation and acceptable configurable retention. Entrust remains equal at the formal shortlist because it may provide the stronger end-to-end trust platform once its current Flutter roadmap, Saudi matrix, cost and static-photo operation are evidenced.

If neither finalist can prove the profile-photo requirement, stop again. Do not silently weaken the requirement. Return to Founder/Claude before considering a separate FaceTec biometric service, because that would materially increase ZYRA's biometric custody and operational burden.

### Mandatory live demo/RFP acceptance test

The vendor must demonstrate, using test identities and non-production media:

1. An arbitrary uploaded profile image—not a newly captured live selfie—is compared 1:1 against the original verified identity reference.
2. Separate outcomes exist for `no_face`, `multiple_faces`, `quality_or_occlusion`, `match`, `mismatch`, `manual_review` and technical failure.
3. The verdict is bound to the exact immutable photo bytes/version.
4. Group photos, head coverings, glasses, side profiles, older photos, appearance change, accessibility accommodations and false-reject appeals have documented paths.
5. The reference remains at the provider; ZYRA does not download or store a template, ID portrait or verification selfie.
6. The feature has a binding per-photo price, retention schedule, deletion API/SLA, geography/subprocessor map and accuracy/fairness evidence.

Generic “Face Match”, “Biometric Authentication” or “Known Faces” marketing does not pass this test. Those products usually compare a new live capture with an existing reference, which is a different operation.

## Phase 3 — Recommended production architecture

### Trust flow

```text
Authenticated ZYRA app
  → authenticated ZYRA session-creation endpoint
  → provider SDK/hosted capture receives a short-lived token
  → ID + live face go directly from device to provider
  → provider performs document, age, liveness and face checks
  → provider sends signed webhook to ZYRA backend
  → backend validates signature, timestamp, event id and case binding
  → backend writes minimum state in a private server-only schema
  → public/profile RPC reads a safe derived status
  → publication RPC grants visibility only when all required states pass
```

Supabase explicitly recommends verifying an external provider's signature inside an Edge Function webhook and keeping internal tables outside exposed Data API schemas. See [Securing Edge Functions](https://supabase.com/docs/guides/functions/auth) and [Securing the Data API](https://supabase.com/docs/guides/api/securing-your-api).

### Backend components to build after approval

1. **Authenticated session-creation Edge Function**
   - verifies the Supabase user JWT;
   - generates a ZYRA-specific random verification-subject id;
   - maps it privately to `auth.users.id`;
   - requests a short-lived provider session/token;
   - never returns provider API secrets.

2. **Provider webhook Edge Function**
   - `verify_jwt=false` only because the provider cannot send a Supabase JWT;
   - verifies the provider HMAC/signature against the exact raw body;
   - enforces timestamp tolerance and replay refusal;
   - inserts a unique provider event id for idempotency;
   - checks event → case → ZYRA-user binding;
   - maps only allowlisted results to an atomic server transition;
   - rejects unknown states rather than treating them as success.

3. **Private verification schema**
   - not listed as an exposed Data API schema;
   - no `anon` or `authenticated` writes;
   - server-only state transition functions;
   - one safe derived RPC/view returns only the current user's coarse state.

4. **Private photo quarantine**
   - a new object version is uploaded to a quarantine bucket/path;
   - object keys are immutable and bound to a SHA-256 digest;
   - safety moderation, face count/quality and ownership matching are distinct states;
   - the current visible photo remains unchanged while a replacement is pending;
   - only a server transition promotes an exact approved object/derivative into the display set;
   - public/display queries require `safety=verified AND ownership=verified`.

5. **Deletion and review worker**
   - queues provider deletion/redaction;
   - retries safely;
   - records requested/confirmed timestamps;
   - keeps account deletion truthful while external erasure is pending;
   - routes manual-review and appeals without exposing raw biometric material to ordinary staff or AI agents.

This design will require migrations, Edge Functions and storage-policy changes. **None are authorised or written in this phase.** Every applied migration must later have a same-change repository file.

### Minimum server-owned records

Suggested logical fields; exact schema awaits provider approval and migration authorisation:

| Record | Minimum fields |
|---|---|
| Verification subject | internal subject UUID, user UUID mapping, provider code, opaque provider subject id, created/deleted timestamps |
| Verification case | purpose, policy version, coarse state, provider case id, requested/completed timestamps, retry count, non-sensitive reason category |
| Identity result | document status, face/liveness status, `adult_18_plus`, verified-DOB match flag, name-match flag where required, expiry/reverify date |
| Photo job | immutable photo version/digest, quarantine path, safety status, face-count status, ownership status, terminal reason, review timestamps |
| Webhook ledger | provider event id, case id, received timestamp, signature result, processing result; no raw payload after processing |
| Deletion job | provider subject/case reference, requested timestamp, retry count, confirmed timestamp |
| Audit event | actor type, transition, coarse reason, timestamp; no media, biometric score, document data or payload |

### Data that may leave ZYRA

- government-ID images and document fields required for verification;
- live selfie/video/motion/liveness frames;
- device/network/capture telemetry genuinely needed for spoof detection;
- the exact quarantined profile photo submitted for ownership matching;
- pseudonymous case/subject identifiers;
- name and DOB only to the degree required for matching/age.

Do not send religion, ethnicity, compatibility answers, Journey content, Guardian relationship, subscription or unrelated profile fields.

### Data ZYRA should retain

- opaque provider subject/case references;
- coarse identity/document/face/photo states;
- `adult_18_plus` and DOB/name match flags;
- provider/policy version and timestamps;
- non-sensitive retry/review/re-verification reason categories;
- deletion request/confirmation and audit metadata.

ZYRA should not retain raw ID images, document numbers, provider selfies/liveness recordings, biometric templates/embeddings, full provider responses, raw confidence scores or biometric diagnostic data in ordinary tables, logs, analytics, crash reports or AI systems.

### State machines

Identity/account state:

```text
not_started
→ session_created
→ capturing_document
→ capturing_liveness
→ processing
→ verified

processing → retry_required
processing → manual_review
processing → rejected
processing → provider_unavailable
verified   → reverification_required
verified   → revoked
any        → deletion_pending → deleted
```

Profile-photo state:

```text
uploaded_quarantined
→ safety_checking + face_checking + ownership_checking
→ verified → promoted/visible

checking → needs_retry
checking → manual_review
checking → mismatch
checking → multiple_faces
checking → no_face
checking → provider_unavailable
```

No non-verified photo becomes visible, and a pending replacement never removes the currently verified photo.

### Publication invariant

For a Seeker to become/remain publicly visible:

```text
identity_document = verified
AND adult_18_plus = true
AND face_liveness = verified
AND reverify_required = false
AND minimum visible-photo count satisfied
AND every visible photo safety = verified
AND every visible photo ownership = verified
```

For a Guardian, identity document/adult/face status applies, but profile-photo requirements depend on the approved Guardian photo model. Guardian relationship remains a separate link claim.

### Public badge meaning

Internally preserve distinct facts:

- `IDENTITY_DOCUMENT_VERIFIED`
- `ADULT_18_PLUS_CONFIRMED`
- `LIVE_FACE_MATCHED_TO_ID`
- `VISIBLE_PROFILE_PHOTOS_OWNERSHIP_VERIFIED`
- `GUARDIAN_RELATIONSHIP_CLAIMED`
- `GUARDIAN_RELATIONSHIP_RECIPROCALLY_CONFIRMED`

Proposed public rule for a Seeker:

> **Verified person** means ZYRA's specialist provider confirmed a valid identity document, confirmed the account holder was a live person matching that document, confirmed they are 18+, and every photo currently visible on that profile passed ZYRA's ownership checks.

This badge must not claim background checks, character, safety, marital status or Guardian kinship.

A Guardian should display **Identity verified** separately. “Father”, “brother”, etc. remains a claimed relationship unless ZYRA creates a distinct reciprocal/evidence standard. Identity verification alone never proves kinship.

The existing public first/surname fields remain casually editable. Therefore the badge cannot currently mean “the displayed name matches the ID.” Product must decide whether public names are display names or verified identity facts before that meaning is added.

### Duplicate-account and ban-evasion boundary

- Ask the provider for **tenant-scoped** repeat-person/known-face detection.
- Receive only an opaque match/risk result or stable provider subject token.
- Route a match to human review; never permanently ban solely on an automated biometric result.
- Do not perform one-to-many facial search in Supabase.
- Never reveal which account matched.
- Do not enable cross-customer fraud-network matching without separate necessity, controller-role, notice and transfer approval.
- Resolve the tension between erasure and ban-evasion retention with UK/Saudi counsel. A hashed document number remains personal data.

### Risk-based re-verification

Valid triggers:

- legal-name, verified DOB or document correction;
- suspicious recovery after all trusted factors are lost;
- credible account-transfer/impersonation report;
- multiple independent photo-ownership failures;
- material device/session anomaly combined with a sensitive action;
- provider invalidation or high-confidence duplicate/fraud referral;
- long dormancy followed by identity and all-photo replacement;
- authorised safety investigation.

Not sufficient alone:

- time passing;
- routine phone replacement;
- one poor-quality photo;
- biography/preference changes;
- random periodic checks.

Use:

`risk signal → non-biometric step-up where adequate → biometric re-verification only when necessary → manual review on mismatch → appeal`

### Failure and review language

| Category | System meaning | User treatment |
|---|---|---|
| Technical failure | Provider/network/session did not complete | “We couldn't complete the check. Nothing has been decided. Try again.” |
| Poor capture | Blur/glare/occlusion/quality | Specific recapture advice; no fraud implication |
| Unsupported document | Coverage limitation | Offer another accepted document or support path |
| Mismatch | Automated comparison did not reach threshold | Retry once, then manual review/appeal |
| Manual review | Provider or ZYRA needs a closer look | Honest pending state and expected response window |
| Definitive rejection | Reviewed evidence cannot establish identity | Neutral refusal plus support/appeal; never “your identity is fake” |
| Provider unavailable | External service outage | Keep pending/invisible; do not invent success |

### Photo edge cases

- **Group/multiple faces:** never auto-select a person; retry or manual review.
- **No face/obscured face/side profile/poor light:** quality retry first, manual route when appropriate.
- **Sunglasses:** prompt for a clearer primary photo; do not infer intent.
- **Old photos/appearance change:** lower-confidence results route to review or a new live re-verification, not automatic rejection.
- **Religious/head coverings:** coverings are not a failure. Require only the facial area technically necessary, offer private guidance and human review, and demand vendor demographic/head-covering evidence.
- **Accessibility:** offer a supported assisted/manual path and do not require gestures, movements or presentation a person cannot perform where a reasonable alternative exists.
- **False rejection:** visible appeal with a human empowered to overturn; monitor overturn rates.

### Developer/testing adapter

After provider approval, implement a vendor-neutral `VerificationGateway` interface with:

- production adapter: provider API/SDK and server webhook only;
- mock adapter: deterministic test state stream, compiled/routed only in protected non-release Developer Access;
- UI state model: all requested identity/photo/error/reverify states;
- hard invariant: mock adapter cannot call the production verification transition or publish RPC;
- server invariant: release clients cannot write verification state even if modified.

Required tests:

- Flutter state/route tests for every requested mock state and retry path;
- release-build absence tests for mock controls;
- SQL grants/RLS tests proving authenticated/anon cannot write verification state;
- webhook signature, stale timestamp, replay, duplicate event and out-of-order event tests;
- case-to-user misbinding tests;
- publication refusal for every incomplete state;
- quarantine visibility and exact-photo-version tests;
- account deletion/provider-erasure retry tests;
- Guardian identity/relationship separation tests;
- provider sandbox end-to-end tests followed by real-device UK and Saudi document pilots.

### Monitoring

Allowlisted aggregate events only:

- verification started/terminal outcome;
- completion and retry rates;
- manual-review rate/age;
- average verification duration;
- provider error category/outage;
- photo ownership outcome bucket;
- re-verification trigger category;
- appeal and overturned-decision rates;
- duplicate referral rate;
- webhook signature/replay failures;
- invoiced cost per attempt and per successfully verified person.

Exclude names, email, DOB, document number, images, media URLs, templates, biometric scores, detailed provider payloads and free-text reviewer notes. Current ZYRA privacy UI says no analytics exists; that disclosure and its lawful basis must be updated before monitoring activation.

## Privacy and legal gates

This section is technical risk guidance, not legal advice.

### United Kingdom

The ICO states that technically processing facial images to uniquely identify a person is special-category biometric data, even if the biometric information exists only transiently. ZYRA needs an Article 6 lawful basis and a separate Article 9 condition. Explicit consent is often the most appropriate condition, but must be freely given and may require a viable non-biometric alternative. A DPIA is required before production biometric recognition, and high residual risk may require ICO consultation.

Sources:

- [ICO biometric concepts](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/biometric-data-guidance-biometric-recognition/key-data-protection-concepts/).
- [ICO lawful biometric processing](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/biometric-data-guidance-biometric-recognition/how-do-we-process-biometric-data-lawfully/).
- [ICO DPIA/accountability guidance](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/biometric-data-guidance-biometric-recognition/how-do-we-demonstrate-our-compliance-with-our-data-protection-obligations/).
- [ICO processor-contract requirements](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/contracts-and-liabilities-between-controllers-and-processors-multi/what-needs-to-be-included-in-the-contract/).

Provider use of biometrics for its own fraud network/model improvement must be separately classified; it may make the provider an independent or joint controller for that purpose. Accuracy, demographic false-match/false-reject evidence, a human appeal and a written Article 28 agreement are mandatory diligence topics.

### Saudi Arabia

Saudi PDPL treats biometric identification as sensitive processing and can apply to processing outside the Kingdom concerning people residing in Saudi Arabia. Sensitive processing requires an impact assessment; legitimate interest is not a valid basis for sensitive data. Cross-border transfer, DPO, registration/local-representative and any biometric-register duties require Saudi counsel before launch.

Sources:

- [SDAIA PDPL implementing regulation](https://dgp.sdaia.gov.sa/wps/portal/pdp/knowledgecenter/details/PDPL2/).
- [SDAIA controller/processor guide](https://dgp.sdaia.gov.sa/wps/portal/pdp/knowledgecenter/details/PDPLCP/).
- [SDAIA transfer regulation](https://dgp.sdaia.gov.sa/wps/portal/pdp/knowledgecenter/details/RegulationonPersonalDataTransferOutsidetheKingdom/).
- [SDAIA transfer-risk guidance](https://dgp.sdaia.gov.sa/wps/portal/pdp/knowledgecenter/details/RiskAssessmentGuideline%20orTransferringPersonalData/).

### Provisional retention targets

Subject to DPIA, contract and counsel:

- provider raw ID/liveness capture: delete immediately after finalisation where feasible; otherwise an explicit appeal/review window provisionally capped at 30 days;
- abandoned sessions: expiry plus a short operational window, provisionally seven days;
- ZYRA minimal verification audit: account lifetime plus a short, defined dispute window;
- duplicate/ban-evasion restriction record: separately justified and time-limited;
- provider deletion: auditable queued command with retry and confirmed completion.

## Cost model

### Published initial ID + selfie baseline

Assumption: each number is a new user completing one billable initial check in a month. USD list prices are shown for cross-provider comparison; taxes, FX, support, manual review, photo checks and enterprise discounts are excluded. Stripe's UK page separately publishes £1.25 per completed verification.

| Plan | Unit/minimum | 100 | 1,000 | 10,000 | 100,000 |
|---|---:|---:|---:|---:|---:|
| Stripe Identity | $1.50 | $150 | $1,500 | $15,000 | $150,000 |
| Veriff Essential | $0.80; $49 minimum | $80 | $800 | $8,000 | $80,000* |
| Veriff Plus | $1.39; $99 minimum | $139 | $1,390 | $13,900 | $139,000* |
| Veriff Premium | $1.89; $209 minimum | $209 | $1,890 | $18,900 | $189,000* |
| Sumsub Basic | $1.35; $149 minimum | $149 | $1,350 | $13,500 | $135,000* |
| Sumsub Compliance | $1.85; $299 minimum | $299 | $1,850 | $18,500 | $185,000* |

`*` Raw arithmetic only. At 100,000 and generally above self-service limits, enterprise pricing is required; these are not procurement quotes.

Persona's normal detailed pricing and Entrust pricing are quote-only. Persona's startup offer cannot be assumed. If 10% of users require an additional billable session, multiply the variable initial-check cost by 1.10. At a 5% manual-review rate, monthly cases are 5, 50, 500 and 5,000; a binding review price is required.

### Profile-photo sensitivity

No finalist publishes a clear self-service price for repeated arbitrary profile-photo-to-verified-reference matching.

Assume 0.25 replacement photos per active verified user per month:

| Active users | Monthly photo checks | $0.10* | $0.25* | $0.50* | Full $1.50 IDV equivalent |
|---:|---:|---:|---:|---:|---:|
| 100 | 25 | $2.50 | $6.25 | $12.50 | $37.50 |
| 1,000 | 250 | $25 | $62.50 | $125 | $375 |
| 10,000 | 2,500 | $250 | $625 | $1,250 | $3,750 |
| 100,000 | 25,000 | $2,500 | $6,250 | $12,500 | $37,500 |

`*` Sensitivity assumptions, not vendor quotes.

If three onboarding photos are also matched at a hypothetical $0.25 each, add $75 / $750 / $7,500 / $75,000 at 100 / 1,000 / 10,000 / 100,000 new users. Re-running a full identity flow for every profile photo is commercially and experientially unsuitable.

Real formula:

```text
monthly cost
= initial IDV checks
+ billable retries
+ profile-photo ownership checks
+ risk-based re-verifications
+ manual reviews/appeals
+ fixed minimums, retention/storage, support and tax
```

## Threat model summary

| Threat | Required control |
|---|---|
| Modified client sets `verified=true` | No client grants; private schema; server-only transition |
| Forged/replayed webhook | Raw-body signature verification, timestamp tolerance, unique event ledger |
| Provider session attached to wrong user | Server-created pseudonymous subject; case binding checked on every event |
| Unverified photo briefly visible | Quarantine bucket and verified-only display predicate |
| Photo replaced after decision | Immutable object version + content digest bound to verdict |
| Duplicate false positive causes wrongful ban | Tenant scope, human review, appeal, no auto-ban |
| Provider/administrator over-access | Least privilege, separate operator role, audit, no ordinary table/media browsing |
| ID/selfie leaks into logs/analytics | Strict allowlist/redaction; no payload logging or session replay |
| Provider outage becomes fake success | `provider_unavailable`; fail closed and recover truthfully |
| Account deletion misses vendor data | Queued deletion, retry, confirmation and exception handling |
| Consent withdrawn while badge remains | Unpublish/revoke badge and run approved deletion/alternative flow |
| Bias/accessibility false rejection | Demographic evidence, supported alternatives, human override and outcome monitoring |
| Account recovery transfers identity | Non-biometric step-up first; risk-based re-verification when trust factors are lost |

## Required decisions before Phase 4

Founder/Claude/provider/counsel must resolve:

1. Which finalist proves arbitrary uploaded-profile-photo ownership matching.
2. Whether ZYRA may require biometric verification for profile publication or must offer a non-biometric alternative.
3. UK Article 6 basis and Article 9 condition.
4. UK and Saudi DPIAs, transfer mechanisms and DPO/registration implications.
5. Provider/controller roles, model-training/fraud-network use and subprocessors.
6. Exact retention/deletion, including duplicate/ban-evasion exceptions.
7. Manual-review and appeal owner/SLA.
8. Whether displayed name is a chosen display name or an ID-verified fact.
9. Guardian public trust language and whether reciprocal confirmation is sufficient for the relationship label.
10. Binding prices for initial check, retry, manual review, recurring authentication, duplicate search and each new profile-photo match.

## OA-ready findings

| Ref | Finding/action | Severity |
|---|---|---|
| F01 | Mock onboarding timers can cause real publication; replace with fail-closed backend state | Critical |
| F02 | Publication RPC checks declared fields + one client-owned photo, not verification | Critical |
| F03 | Build quarantine, server-owned photo state and exact-photo promotion | Critical |
| F04 | Separate Guardian identity from relationship claim; remove unsupported production badges | High |
| F05 | Build provider-aware correction, recovery, re-verification and deletion | High |
| F06 | Build protected deterministic developer matrix and adversarial tests | High |
| F07 | Reconcile Image Handling, Profile Completion, Settings/Identity, Wali and legal docs | High |
| F08 | Run Entrust/Veriff RFP/demo; Sumsub conditional; Founder/Claude selects | High |
| F09 | Complete UK/Saudi DPIA, lawful-basis, transfer and retention work | Critical |
| F10 | Build server-authoritative Edge Function/webhook/private-schema foundation | Critical |
| F11 | Define duplicate/ban-evasion policy without a ZYRA face database | High |
| F12 | Add privacy-safe monitoring and cost ledger with no identity/biometric content | Medium |

## Phase gate and change evidence

**Changed:** this point-in-time technical report only.  
**Source files changed:** none.  
**Migrations authored/applied:** none.  
**Provider accounts/resources/credentials created:** none.  
**Real identity documents or biometric media processed:** none.  
**Live Supabase data probed:** none.  
**Measured evidence:** repository counts and exact source/migration paths above; official provider, ICO, SDAIA and Supabase documentation linked inline.

**STOP:** Await Claude's independent product/security/privacy/commercial review and the Founder's explicit provider approval. Phase 4 must not begin before that decision returns and Codex reconciles it against this code audit.
