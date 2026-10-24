# 027 — CODEX → FABLE — 2026-08-29 — OA-ZYRA-280 IDV PROVIDER EVALUATION

## 1. Decision brief

**Status:** REPORT COMPLETE; NO BUILD AUTHORISED  
**Authority:** Founder directive 2026-08-29 · DR-ZYRA-219 items 7–8 ·
OA-ZYRA-266/280 · `026_FABLE-CODEX_2026-08-29_IDV_PROVIDER_EVALUATION_GO.md`  
**Governance:** AD-AIOS-106 — Codex technical challenge/review duty; Fable
retains source-of-truth leadership; Founder remains final authority  
**Recommendation:** make **Sumsub the conditional launch-provider lead**, using
one Sumsub source key/client environment and server-side Similar Search only to
produce `duplicate_review_required = true|false|not_evaluated`. Do not persist
the provider's matching applicant IDs, match criteria, scores, images or
biometrics. Configure duplicates to go to controlled human review, never to an
automatic ban, merge or capability decision.  
**Commercial qualification:** Sumsub's public **$1.35/successful verification +
$149 monthly minimum** is the base IDV price; public pricing does not establish
that biometric Similar Search, its API and the required manual-review routing
are included. The recommendation is therefore conditional on a written
all-in quote and the acceptance gates in §11.  
**Fallback:** Stripe Identity is the fastest operational fallback if the Founder
accepts provider-Dashboard-only duplicate handling. Stripe documents duplicate
selfie detection and manual override, but not a duplicate insight delivered by
API/webhook. It therefore cannot currently feed DR-ZYRA-219's opaque duplicate
signal into Supabase without a human making the final provider-side decision.  
**Price challenger:** Veriff remains technically credible, but the advertised
$0.80 Essential plan is not the relevant duplicate-control price. Its $1.39
Plus plan advertises Risk Insights, FaceBlock and CrossLinks; its explicit
same-integration duplicated-user control is documented as an automatic decline,
which conflicts with DR-ZYRA-219 unless Veriff contractually supplies a
non-blocking review signal.

No provider is selected or approved by this report. The Founder still owns the
capability matrix under OA-ZYRA-266, and implementation remains blocked on that
matrix and the solicitor's Article 9 sign-off. No account, key, SDK, package,
consent screen, schema, migration, production setting or Git state was created
or changed.

## 2. Reconciliation with the 26 August report

This evaluation updates, rather than replaces, the earlier
`CODEX_ZYRA_IDENTITY_FACE_PHOTO_VERIFICATION_PHASES_1_3_2026-08-26_V1.md`.
The architectural conclusion is unchanged: ZYRA must not become a face database;
a specialist provider must collect and retain the identity document, live selfie
and biometric template, while ZYRA retains only an opaque reference and coarse
result.

Two public-evidence updates matter:

1. Stripe now documents duplicate-selfie and duplicate-selfie-with-data-mismatch
   insights. Those insights are described as Identity Dashboard review tools;
   the public VerificationSession/API/webhook material does not expose them as a
   machine-consumable duplicate result.
2. Veriff's current service description explicitly documents a duplicated-user
   velocity check within the current integration, but describes it as an
   automatic decline. That proves detection capability, not compliance with
   ZYRA's human-review-only rule.

The earlier unresolved question also remains unresolved: none of the three
providers publicly proves the exact product rule “compare the IDV selfie with an
arbitrary ZYRA profile photo, while the profile photo and derived template remain
provider-side.” Document-to-selfie matching is proved; the extra profile-photo
comparison is not. It must not be silently bundled into the launch decision.

## 3. Non-negotiable architecture

```text
Authenticated ZYRA user
  -> authenticated Supabase Edge Function creates/reuses one provider session
  -> function returns only a short-lived SDK token or hosted session URL
  -> Flutter opens provider capture flow
  -> document + selfie travel directly from device to provider
  -> provider stores/processes document, media and biometric template

Provider
  -> signed HTTPS webhook to a dedicated Supabase Edge Function
  -> exact raw body verified before parsing; replay/idempotency enforced
  -> provider session reference bound to the expected ZYRA user/attempt
  -> detailed provider result collapsed in memory to a coarse result
  -> raw body, PII, media, face embedding, score and hit list discarded

ZYRA private server-side record (conceptual; no schema authorised)
  -> provider code
  -> opaque provider session/reference
  -> coarse verification result
  -> opaque duplicate-review flag
  -> provider event reference for idempotency
  -> created/updated/decided timestamps

Human review when duplicate flag exists
  -> authorised reviewer works in provider console
  -> reviewer never receives a ZYRA automatic-ban recommendation
  -> provider override/final event returns through the same signed webhook
  -> ZYRA stores only the final coarse result and reference
```

Permitted coarse results for design discussion are `pending`, `verified`,
`retry_required`, `review_required`, `failed`, `expired` and `cancelled`.
`duplicate_review_required` is `true`, `false` or `not_evaluated`. Even this
minimal shape is **design only** and remains subject to the Founder/solicitor
gates; it is not a migration proposal.

Prohibited at ZYRA rest, logs, analytics, crash reports and support exports:

- identity-document or selfie files/URLs;
- facial embeddings, templates or similarity/confidence scores;
- extracted name, date of birth, document number or address;
- provider duplicate-hit applicant IDs, matching fields or criteria;
- full webhook/API payloads and human-readable biometric rejection reasons; and
- any cross-customer biometric or fraud-network identity.

## 4. Supabase result/webhook design — report only

Current Supabase guidance distinguishes authenticated client calls from external
webhooks. Session creation should retain default `verify_jwt = true` and use an
authenticated user context subject to RLS. The provider webhook must use
`verify_jwt = false`/`auth: 'none'` because the provider has no Supabase JWT, and
must authenticate the provider signature inside the handler before any write.
Provider credentials and webhook secrets belong only in Edge Function secrets.
[Supabase authenticated/external-webhook guidance](https://supabase.com/docs/guides/functions/auth)
and [secrets guidance](https://supabase.com/docs/guides/functions/secrets)
support this split.

Required implementation controls if a later build is authorised:

1. **One authenticated session-creation function.** Validate the Supabase user,
   enforce rate/attempt limits, reuse an unfinished provider session where safe,
   and send only a random opaque ZYRA reference to the provider—not email, name
   or a document attribute.
2. **One provider-specific webhook adapter.** Read the exact raw bytes once;
   validate the documented signature in constant time; validate timestamp or
   freshness where the provider supplies it; reject unknown integrations,
   sessions and algorithms; and acknowledge only after a durable idempotent
   state transition.
3. **Canonical result retrieval.** Where practical, use the signed event as the
   trigger and retrieve the current decision server-to-server by opaque session
   reference. Never expand/download sensitive result fields.
4. **Allowlisted state machine.** Duplicate/out-of-order events are harmless;
   a later retry or processing event cannot downgrade an accepted final event;
   a provider manual override is accepted only as a documented final event.
5. **No payload logging.** Logs contain a generated correlation ID, provider
   event-reference hash, mapped result and timing only. Error monitoring must not
   capture request bodies or headers containing secrets.
6. **Private storage.** The conceptual record is not exposed through the Data API
   to anonymous or ordinary authenticated clients. A user-facing read returns
   only that user's coarse state. New Supabase projects no longer expose new
   tables automatically, but explicit grants and RLS would still both need review
   in any authorised migration.
7. **Client is never authority.** SDK completion, redirect success and local
   callbacks may update progress UI only. They cannot grant verification or any
   capability.

Provider mapping:

| Provider | Signed input | Coarse mapping | Duplicate handling |
|---|---|---|---|
| Stripe | `Stripe-Signature`; raw-body verification | `verified` → verified; `requires_input` → retry; processing → pending; cancelled/redacted → closed | Duplicate insight is documented in Dashboard, not public API/webhook. Reviewer may override there; resulting status webhook is the only ZYRA input. |
| Sumsub | `X-Payload-Digest` over raw bytes with declared HMAC algorithm | `GREEN` → verified; `RETRY`/resubmission → retry; final RED → failed; workflow/manual queue → review | Server may query Similar Search, convert any qualifying same-client image hit to one boolean, then immediately discard hit IDs/criteria. Operator final decision returns by webhook. |
| Veriff | `X-HMAC-SIGNATURE` HMAC-SHA256 over raw body plus integration binding | approved → verified; resubmission → retry; review → review; declined → failed; expired/abandoned → closed | Do not enable an automatic duplicate decline. Accept only a contractually configured same-integration non-blocking review event/label. Disable Industry CrossLinks. |

## 5. Candidate evaluation

### 5.1 Stripe Identity

**Flutter path and effort.** Stripe publishes Identity integrations for Web,
iOS, Android and React Native, but not a first-party Flutter Identity SDK. The
lowest-risk Flutter path is the Stripe-hosted verification URL in a secure
system browser with an app return link; it is a **low-to-medium** integration.
A native embedded experience would require maintaining Flutter platform-channel
wrappers around both native Identity SDKs and is **high** effort/maintenance.
Server creation and webhook authority are required in either case.

**Data flow.** Device media goes directly to Stripe. The client receives only a
short-lived client secret/ephemeral key or hosted URL. Stripe warns not to log,
store or place such tokens in URLs. ZYRA must not request expanded verified
outputs, file objects, selfie images or VerificationReports; it needs only the
session status/reference.

**Duplicate fit.** Stripe documents two selfie insights: duplicate selfie and
duplicate selfie with mismatching document data. It also shows linked
VerificationSessions and supports manual override/blocklisting in the Identity
Dashboard. This is genuine duplicate capability and corrects the earlier
“absent” assumption. However, the current public docs describe the insight as a
Dashboard surface; it is absent from the published VerificationSession events
and result fields. It is therefore **PARTIAL against DR-ZYRA-219 item 7**:
provider-side human review is possible, but no documented tenant-scoped opaque
duplicate signal can be mapped automatically into Supabase. Stripe also uses
Stripe-network fraud signals, so the contract/DPIA must distinguish account-local
duplicate matching from cross-network fraud scoring.

**Failure/retry UX.** A VerificationSession can be reused after
`requires_input`; the returned error can guide a neutral retry. Webhook status,
not redirect completion, remains authoritative. Every completed
VerificationReport—verified or unverified—is billable, so multiple submitted
attempts can increase cost. The UX should reuse the same session, rate-limit
restarts, present “try again” without storing reason text, and offer a human
alternative if biometric consent is refused or valid users repeatedly fail.

**Price.** UK list price is **£1.25 per completed document+selfie verification**,
no public monthly minimum, with the first 50 free. The global pricing reference
used in the earlier report is **US$1.50**. This is the cleanest low-volume
commercial model, but retry exposure must be forecast.

**UK/GDPR posture.** Stripe publishes a DPA and supports programmatic redaction,
but its own help material says Identity verification data is processed/stored in
the United States regardless of user location; biometric identifiers are
normally retained up to one year and other submitted identity data for three
years unless deleted sooner or a longer legal basis applies. Stripe is a
processor for some customer-directed verification processing and an independent
controller for fraud/security and certain other uses. This mixed-role, US-storage
model is workable only after the transfer assessment, retention instructions,
controller-use disclosures and Article 9 basis are legally accepted.

**Profile-photo rule.** Not proved. Stripe proves selfie-to-ID matching, not an
API for matching the capture against an arbitrary ZYRA profile photo.

### 5.2 Sumsub

**Flutter path and effort.** Sumsub has an official Flutter plugin. An
authenticated backend creates a short-lived, applicant-scoped MobileSDK access
token; Flutter starts the SDK with it; capture uploads directly to Sumsub. This
is a **medium** integration: the client path is supported, while the server
adapter, token refresh, duplicate filtering and workflow configuration are the
material work. SDK analytics must be disabled unless the DPIA explicitly accepts
them.

**Data flow.** Use a random external user ID and a dedicated ZYRA source key.
Never send email as the provider identity key. Webhooks use HTTPS, contain no
personal applicant information by design, and can be signed with HMAC-SHA256 or
SHA512. Sumsub requires digesting the unmodified raw body and retries failed
delivery five times after the first attempt.

**Duplicate fit.** Sumsub has the strongest documented programmatic capability.
Similar Search can return `SIMILAR_SEARCH` and detailed `duplicateApplicantHits`
including matched applicant IDs, fields and whether the criterion was text or
image; risk documentation also describes same-face matches within the client's
environment. Source-key controls allow duplicate handling to be isolated within
a key/client context, and workflow rules can send cases to manual review.

The native API is **too revealing for ZYRA to persist**. The compliant adapter
must inspect the response transiently, accept only the agreed same-client
image/face condition, map it to one boolean, and discard every ID, field, score,
criterion and payload. “Consider all new similar applicants as duplicates” and
automatic-rejection branches must remain off. Fraud Networks, cross-client
signals and reusable-KYC identity sharing must not be used. With those written
controls, Sumsub is the best fit to DR-ZYRA-219 item 7; without them it fails.

**Failure/retry UX.** Sumsub exposes “Resubmission requested” with
`reviewRejectType: RETRY`, can show the user which capture step needs repeating,
and supports manual override of Face Match/Similar Search. ZYRA should show the
provider capture guidance transiently but store only `retry_required`. A
duplicate should enter neutral “verification under review” UX. Public pricing
says incomplete applicants are not billed and only successful verifications are
charged, but the contract must define whether a manually rejected duplicate or
repeated reviewed applicant is a chargeable “successful verification.”

**Price.** Basic is **US$1.35 per successful verification with a $149 monthly
minimum**; Compliance is $1.85 with a $299 minimum. Basic includes ID
verification and liveness/face match. The public price page does not promise
Similar Search/API/manual-review routing in Basic. The all-in launch cost is
therefore **quote required**, not $1.35 assumed.

**UK/GDPR posture.** Sumsub's public terms include a DPA: the customer is
controller and Sumsub processor for customer-directed verification, with UK
transfer provisions/IDTA or SCC mechanisms and subprocessor terms. Its service
privacy notice says personal data is stored in European data centres, while
Local Data Processing offers selectable regional storage/processing on request;
some platform, billing and analytics data remains central. Retention can be set
by customer instruction and full deletion removes the applicant from the search
index. Contract review must confirm the exact UK/EU region, backup/search-index
deletion, biometric retention, support access, controller exceptions and no
model-training use. Sumsub ID makes Sumsub a controller for the reusable identity
account and must remain disabled unless separately approved.

**Profile-photo rule.** Not proved. Face Match/Face Authentication proves live
selfie comparison to an ID or stored applicant profile, not the exact arbitrary
ZYRA gallery-photo rule under the required storage boundary.

### 5.3 Veriff

**Flutter path and effort.** Veriff has an official Flutter plugin, currently
requiring iOS 13+ and Android 8/API 26+. The backend creates a session URL;
Flutter passes it into the SDK; results arrive by webhook. This is a **medium**
integration. The SDK requires camera, microphone and photo-library permissions,
plus Android foreground-service declarations; those implications need future
product/legal review, not implementation now.

**Data flow and webhooks.** Capture uploads to Veriff. Decision webhooks are
at-least-once, may arrive out of order, require a response within five seconds
and may retry for up to a week. Veriff signs the raw body with HMAC-SHA256. The
adapter must be idempotent, handle both Essential Full Auto and Plus/Premium
payload variants, and map only the documented decision enum.

**Duplicate fit.** Veriff documents three relevant tools, with different
meanings:

- FaceBlock is customer-specific but matches incoming faces only against a
  curated blocklist/known-fraud set and retains its face data for three years;
- CrossLinks connects sessions using technical, document and face-embedding
  signals, while Industry CrossLinks expressly crosses customers and must be
  disabled for ZYRA; and
- Velocity Abuse can detect a person previously approved in the current
  integration, but the documented action is automatic decline.

The detection technology exists, but the public configuration does not prove a
same-integration, non-blocking, webhook/API duplicate signal. It is
**CONDITIONAL/PARTIAL against DR-ZYRA-219 item 7**. Veriff must agree in writing
to return `review` (or an equivalent coarse label) without automatic decline and
without Industry CrossLinks. A dashboard-only risk label or an auto-decline is
not sufficient.

**Failure/retry UX.** Veriff supports `resubmission_requested`; the same session
URL should be reused and retry attempts inside the same end-user session are not
charged. A new session after abandonment is charged. `review` is not sent by
default and requires agreement/configuration. ZYRA should keep retry reasons
transient, map review neutrally and never treat SDK completion as approval.

**Price.** Essential is **US$0.80/check + $49 monthly minimum** but is not the
relevant duplicate-control comparison. Plus is **$1.39/check + $99 minimum** and
advertises Risk Insights, FaceBlock and CrossLinks; Premium is $1.89 + $209.
Self-serve is capped at 10,000 sessions/month and Enterprise is quoted above the
published scale. A compliant non-blocking duplicate mode may require a custom
plan, so the all-in cost remains quote-dependent.

**UK/GDPR posture.** Veriff publishes a DPA, subprocessor/transfer provisions and
retention schedules. Its published enterprise default retains full IDV data,
including media and face embeddings, for 90 days active plus up to three years
in archive; FaceBlock/biometric authentication embeddings can be retained three
years. Its DPA/service terms also allow some independent permitted-business use,
including service development/machine learning, and independent retention where
lawful. The contract would need a materially narrower retention/controller-use
position before selection.

**Profile-photo rule.** Not proved. FaceBlock Import accepts external portrait
photos, but it is a blocklist product that creates/stores biometric embeddings
for three years; it is not an acceptable proxy for a benign match-to-own-profile
rule.

## 6. Comparative verdict

| Criterion | Stripe Identity | Sumsub | Veriff |
|---|---|---|---|
| First-party Flutter | No | Yes | Yes |
| Fastest low-volume commercial start | **Best** | Monthly minimum | Low minimum |
| Programmatic same-tenant duplicate path | Dashboard insight only; API/webhook not proved | **Best evidence**, but detailed API must be collapsed | Detection proved; non-blocking signal not proved |
| Human review without ZYRA face data | Stripe Dashboard/manual override | **Provider workflow/manual override** | Possible only with agreed `review` configuration |
| No automatic duplicate ban | Possible operationally | Must configure manual review | Documented duplicate-user mode auto-declines; conflict |
| Base price relevant to duplicate control | £1.25; duplicate Dashboard included/documented | $1.35 base; duplicate inclusion unproved | $1.39 Plus, not $0.80 Essential; custom mode may cost more |
| Retry billing | Completed verified/unverified report billable | Public FAQ says successful only; define contractually | Same-session resubmission not charged |
| Data-location/retention concern | US storage; 1y biometrics/3y other data; mixed roles | EU/LDP options; exact region/retention must be contracted | Long default/archive/FaceBlock retention; permitted-business use |
| Overall | Operational fallback | **Conditional launch lead** | Contract/price challenger |

## 7. Launch-volume cost model

No numerical launch forecast is recorded in MESSAGES/026 or OA-ZYRA-280.
Accordingly, these are transparent monthly planning bands—not a demand forecast.
They exclude VAT, FX, add-ons, support, manual-review labour and failed/retry
usage except where the provider's public billing rule excludes it.

| Completed users/month | Stripe UK list | Stripe global reference | Sumsub Basic base | Veriff Essential (no adequate duplicate path proved) | Veriff Plus (closer comparator) |
|---:|---:|---:|---:|---:|---:|
| 25 | £31.25* | $37.50* | $149 minimum | $49 minimum | $99 minimum |
| 100 | £125 | $150 | $149 minimum | $80 | $139 |
| 500 | £625 | $750 | $675 | $400 | $695 |
| 1,000 | £1,250 | $1,500 | $1,350 | $800 | $1,390 |
| 10,000 | £12,500 | $15,000 | $13,500 | $8,000** | $13,900** |

\* Stripe advertises the first 50 verifications free; table shows steady-state
list cost so the one-off promotion does not distort ongoing comparison.  
\** Veriff self-serve has a 10,000-session monthly cap and recommends Enterprise
from 5,000+; actual scale price is quote-based.

The decision-relevant totals are not the cheapest displayed numbers. Sumsub's
duplicate-inclusive total is unknown; Veriff's compliant duplicate mode may be
custom; Stripe's failed submitted attempts can add charges. Written quotes must
price the exact ID document + liveness + face match + same-client duplicate
review bundle and define every chargeable event.

## 8. Failure, review and retry policy to carry into the capability matrix

This report does not decide which ZYRA features verification gates. Whichever
matrix the Founder later selects, the integration must preserve these meanings:

| State | User-safe product meaning | Forbidden consequence |
|---|---|---|
| Pending/provider processing | “We are checking your verification.” | No optimistic capability grant |
| Capture retry required | “We could not complete that check; please try again.” | No fraud accusation; no new provider identity unless required |
| Duplicate review required | “Your verification needs a manual review.” | No automatic ban, merge, shadow restriction or disclosure of another account |
| Final failed | Neutral failure plus governed support/alternative path | No biometric reason stored in ZYRA; no permanent inference beyond approved policy |
| Provider unavailable | Retry later/circuit-breaker state | No fallback to client self-attestation as “verified” |
| Consent refused/withdrawn | Solicitor-approved non-biometric alternative or clearly defined consequence | No claim that consent is freely given if refusal has hidden detriment |

False-positive appeal, reviewer access, evidence retention, deletion requests and
override audit must be defined before production. Reviewers should work inside
the provider console so ZYRA does not ingest the underlying document, selfie or
match evidence.

## 9. UK/GDPR gate

This is not legal advice. ICO guidance establishes the minimum questions for the
solicitor:

- biometric recognition used to identify a person is special-category biometric
  data and needs both an Article 6 lawful basis and a separate Article 9
  condition;
- explicit consent is often the most appropriate condition, but it must be
  specific, informed, freely given and withdrawable, normally with a suitable
  alternative; if no valid condition exists, the processing must not occur;
- special-category/biometric access decisions and innovative technology are
  strong DPIA triggers; and
- the controller/processor relationship requires an Article 28 contract,
  documented instructions, subprocessor governance, deletion/return terms,
  security assistance and audit rights.

Required written legal/procurement outputs before build:

1. ZYRA's Article 6 basis and Article 9 condition for ID-to-selfie and duplicate
   face comparison, plus the separate basis for any future profile-photo match.
2. DPIA covering false matches, demographic/accessibility performance, duplicate
   review, automated-decision limits, alternative verification, children/age
   boundary, misuse, breach impact and data-subject rights.
3. Provider roles for customer-directed processing versus provider fraud,
   security, product-improvement, reusable-identity and cross-network processing.
4. Exact storage/processing countries, subprocessors, UK transfer mechanism and
   transfer-risk assessment.
5. Contractual retention for media/templates/backups/search indices; deletion
   SLA; effect of deletion on duplicate control; and termination export/deletion.
6. Express prohibition or accepted terms for model training, cross-customer
   biometric matching, fraud-network sharing and provider independent retention.
7. Human-review/appeal mechanism and assurance that a duplicate signal is not an
   automatic significant decision.

Primary ICO references:
[lawful biometric processing](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/biometric-data-guidance-biometric-recognition/how-do-we-process-biometric-data-lawfully/),
[special-category biometric definition](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/biometric-data-guidance-biometric-recognition/biometric-recognition/),
[DPIA triggers](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/data-protection-impact-assessments-dpias/when-do-we-need-to-do-a-dpia/),
and [Article 28 contract content](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/contracts-and-liabilities-between-controllers-and-processors-multi/what-needs-to-be-included-in-the-contract/).

## 10. Desk notes — not launch finalists

**Persona.** Public Essential pricing starts at **$250/month with a 12-month
minimum term**. Persona offers hosted, embedded and mobile SDK flows, Government
ID/Selfie checks, webhooks, and higher-tier Graph/image-list/linked-account tools;
custom retention and EU hosting are plan-dependent. No public first-party
Flutter route or launch-priced opaque duplicate webhook was established. It is a
capable orchestration platform, but its minimum contract and likely Growth-tier
fraud tooling are disproportionate for this launch shortlist.
[Persona pricing](https://withpersona.com/pricing/) ·
[integration methods](https://docs.withpersona.com/choosing-an-integration-method) ·
[processor privacy](https://withpersona.com/legal/privacy-policy)

**Entrust Identity Verification (Onfido).** The existing Onfido Flutter SDK is
supported, but Entrust released its new SDK generation for iOS/Android/React
Native in January 2026 and says its replacement Flutter SDK is due later in
2026. Pricing is sales-gated. Workflow Studio, Motion and Known Faces are strong,
but the Flutter transition, unknown price and controller use for fraud/service
improvement make it a later RFP candidate rather than today's launch lead.
[SDK transition](https://documentation.identity.entrust.com/sdk) ·
[existing Flutter SDK](https://documentation.identity.entrust.com/sdk/flutter) ·
[data-protection schedule](https://www.entrust.com/sites/default/files/documentation/licensingandagreements/entrust-identity-verification-schedule.pdf)

**Yoti.** Yoti publicly offers document+selfie, liveness/face match, no-code web
links and embedded IDV, with optional human checks. Public terms say checks are
charged when completed regardless of outcome; current per-check pricing is
sales-gated. The researched public material did not establish a first-party
Flutter SDK or same-tenant opaque duplicate signal. Its UK identity credentials
justify keeping it on the later procurement list, not displacing the three
evaluated candidates now.
[Yoti Identity Verification](https://info.yoti.com/identity-verification) ·
[Yoti organisation terms](https://www.yoti.com/wp-content/uploads/2023/10/Yoti-Organisation-TCs-v4.6-27-September-2023.pdf)

## 11. Recommendation and Founder-created sandbox request

### Recommended launch path

Proceed with **one provider, not a staged biometric pair**: Sumsub for ID
document authenticity, selfie liveness, face-to-document match and
same-client duplicate review. A second biometric provider would double DPIA,
deletion, incident-response and user-rights complexity without a proved launch
benefit.

The duplicate-control path is:

```text
dedicated ZYRA source key/client environment
  -> allow completion; no automatic duplicate rejection
  -> Similar Search in provider/backend only
  -> accept only contractually defined same-client face/image duplicate event
  -> collapse to duplicate_review_required boolean
  -> human review in Sumsub console
  -> final provider decision webhook
  -> opaque final result in ZYRA
```

### Conditions that must all pass

1. **Commercial:** written all-in price for IDV + liveness + face match +
   biometric Similar Search/API + manual-review routing; precise chargeable-event
   and retry definition.
2. **Scope:** written confirmation that the duplicate search can be limited to
   ZYRA's own client/source-key population and that Fraud Networks/cross-client
   biometric matching can be disabled.
3. **Control:** duplicates can be routed to review without auto-reject, ban,
   merge or disclosure of the matched account.
4. **Data minimisation:** the integration may ignore/not retrieve PII/media and
   may discard hit details immediately; no sensitive webhook body is required.
5. **Privacy:** solicitor accepts the Article 9 condition, DPIA, DPA, roles,
   region/transfers, retention/deletion, subprocessors and provider-use limits.
6. **Product:** Founder supplies the capability matrix; support/appeal and a
   lawful non-biometric alternative are defined.
7. **Sandbox evidence:** Flutter iOS/Android completion, resubmission, manual
   review, duplicate false-positive override, replay/out-of-order webhooks,
   deletion, accessibility and representative photo performance all pass.
8. **Profile-photo separation:** arbitrary ZYRA profile-photo matching remains
   off until separately proved and approved.

Public docs cannot close conditions 1–5 or prove the exact duplicate payload in
the selected commercial tier. Fable should therefore ask the Founder to create
a **Sumsub sandbox/trial account** and request its written DPA/retention/data-
location pack plus a duplicate-inclusive quote. If the Founder wishes to retain
a live fallback, use the existing Stripe onboarding to request **Stripe Identity
test access** and written confirmation of whether duplicate-selfie insights can
be exposed as an account-local API/webhook flag. Codex must receive no account
password, API key or webhook secret during the evaluation round.

If Sumsub fails any condition, do not improvise a second face database. Re-open
the choice between:

- Stripe with provider-Dashboard human duplicate review and status override, if
  the Founder accepts the operational/manual limitation and solicitor accepts
  Stripe's role/storage posture; or
- Veriff Plus/Enterprise only after a written non-blocking, same-integration
  duplicate review signal and narrowed retention/provider-use terms.

## 12. Primary provider sources checked 2026-08-29

**Stripe:** [Identity UK pricing/security](https://stripe.com/gb/identity) ·
[VerificationSession API/events/redaction](https://docs.stripe.com/identity/verification-sessions?locale=en-GB) ·
[Identity insights](https://docs.stripe.com/identity/insights?locale=en-GB) ·
[review tools and biometric duplicates](https://docs.stripe.com/identity/review-tools?locale=en-GB) ·
[Identity billing](https://support.stripe.com/questions/billing-for-stripe-identity) ·
[data roles, location and retention](https://support.stripe.com/questions/managing-your-id-verification-information?locale=en-GB) ·
[Stripe DPA](https://stripe.com/legal/dpa)

**Sumsub:** [pricing](https://sumsub.com/pricing/) ·
[Flutter plugin](https://docs.sumsub.com/docs/flutter-plugin) ·
[webhook signing/retries](https://docs.sumsub.com/docs/webhook-manager) ·
[duplicate applicants API](https://docs.sumsub.com/reference/get-duplicate-applicants-check-result) ·
[source-key duplicate controls](https://docs.sumsub.com/docs/source-keys) ·
[manual override](https://docs.sumsub.com/docs/approve-rejected-applicants) ·
[Local Data Processing](https://docs.sumsub.com/docs/local-data-processing) ·
[DPA in terms](https://sumsub.com/terms-and-conditions/) ·
[service privacy notice](https://sumsub.com/privacy-notice-service/)

**Veriff:** [self-serve pricing](https://www.veriff.com/plans/self-serve) ·
[Flutter plugin](https://devdocs.veriff.com/docs/flutter-plugin) ·
[webhook delivery](https://devdocs.veriff.com/docs/webhooks-guide) ·
[HMAC verification](https://devdocs.veriff.com/docs/hmac-authentication-and-endpoint-security) ·
[decision statuses](https://devdocs.veriff.com/docs/verification-session-status-codes-table) ·
[duplicate/fraud service description](https://www.veriff.com/service-description/ver-vsd-2301) ·
[DPA](https://www.veriff.com/data-processing-addendum/ver-DPA-2303) ·
[retention](https://www.veriff.com/data-retention/ver-vdr-2301)

## 13. Trace and refusal record

- **OA-ZYRA-280:** deliverable supplied; Fable may verify and close the
  report-only action when this evidence is accepted.
- **OA-ZYRA-266:** remains open for the Founder capability matrix, provider
  decision, solicitor gate, sandbox evidence and any separately authorised
  build.
- **OA-ZYRA-259/Article 9:** remains blocking; no legal conclusion is inferred.
- **DR-ZYRA-219 items 7–8:** fully preserved; no face database, auto-ban,
  auto-merge or capability matrix was introduced.
- **New OA/DR:** none proposed. The unresolved work is already owned by
  OA-ZYRA-266/280; creating a duplicate identifier would reduce traceability.
- **Written refusals:** no provider account/key/SDK/package, schema/migration,
  consent UI, capability gate, production configuration, user data, biometric
  test set or Git operation was created or touched.

— END —
