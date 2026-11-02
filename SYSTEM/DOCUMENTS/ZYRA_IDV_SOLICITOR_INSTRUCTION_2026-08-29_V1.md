---
id: DOC-ZYRA-0206
type: GUIDE
status: CURRENT
feature: IDENTITY AND SIGN-IN
purpose: ZYRA — Solicitor Instruction Pack: Identity Verification & Biometric Processing
links: []
owner: ZYRA chat
---

# ZYRA — Solicitor Instruction Pack: Identity Verification & Biometric Processing

**Version:** V1
**Status:** WITHDRAWN 2026-08-29 (DR-ZYRA-220) — the Founder cancelled solicitor review the same day this pack was prepared; it was never sent anywhere. Retained as history AND as the INTERNAL compliance checklist: the seven questions in Section E are now answered in-house (Fable drafts, Founder signs) under the DR-ZYRA-220 self-serve compliance path.
**Date:** 2026-08-29
**Prepared by:** Fable (Company Operations), from Codex technical evaluation 027 §9 and ICO public guidance
**Register:** OA-ZYRA-266 (master IDV record) · DR-ZYRA-219 · OA-ZYRA-259 (existing solicitor instruction list — this pack may be combined with the Article 9 compatibility questions already held there)

> **How this pack is organised.** Section A-D give the solicitor the factual
> context. Section E contains the seven questions on which written legal
> advice is requested. Section F (annex) contains engineering facts and
> provider-published terms — provided as evidence, clearly separated so that
> technical assumptions are never mistaken for settled legal positions.

---

## A · Who is instructing and product context

- ZYRA is a UK-first matrimonial (marriage-seeking) mobile app for a faith community,
  pre-launch, operated by its sole founder (company structure to be confirmed
  in the engagement; currently enrolled with Apple as an Individual
  developer).
- The product's premise is supervised, intentional courtship: a "Seeker" may
  involve a "Guardian" (family oversight role). Trust and user safety are the
  brand's core promise.
- Planned first release: United Kingdom only, iOS App Store (expected 18+
  age rating). No production users exist today; a seeded test population only.
- Data platform: Supabase (Postgres, EU-hosted project), Flutter mobile app.

## B · Proposed identity-verification model (what we intend)

1. A specialist identity-verification provider performs, on its own
   infrastructure: identity-document authenticity checking; live-selfie
   capture with liveness detection; biometric face-match of the selfie to
   the document portrait.
2. The member's document and selfie travel directly from their device to the
   provider. ZYRA's servers never receive, store or log the document image,
   the selfie, any facial template/embedding, or any similarity score.
3. ZYRA stores only: which provider was used; an opaque provider session
   reference; a coarse result (e.g. verified / retry / review / failed); an
   opaque yes/no "duplicate review required" flag; timestamps.
4. Conditional preferred provider: **Sumsub** (customer-controller /
   provider-processor DPA published; European data centres with selectable
   regional processing). Operational fallback: **Stripe Identity** (publishes
   a DPA; states identity-verification data is processed and stored in the
   United States; mixed processor/controller roles). Neither is contractually
   selected; selection is conditional on this advice and written commercial/
   data terms.
5. No decision about a member is fully automated: any duplicate signal
   routes to human review; verification failure produces a neutral retry or
   a governed support path.

## C · Product rules already ruled internally (Founder decisions on record)

- **No ZYRA-owned face database** — ever. Biometric material lives only with
  the provider (DR-ZYRA-219 item 7).
- **Duplicate signal → human review → Founder/authorised resolution. Never
  an automatic account ban solely from duplicate detection** (Founder
  direction 2026-08-29; a provider whose documented duplicate handling
  auto-declines has been excluded for exactly this reason).
- No automatic account merging; no client-side identity inference; the
  authentication server (Supabase) is the sole authority on identity
  linking (DR-ZYRA-219 items 1-3).
- Verification is a trust gate, never a paywall: whatever tier of the app
  requires verification, the check is free of charge to the member.
- The set of app capabilities that will REQUIRE verification is a pending
  Founder decision (a capability matrix accompanies this pack); the current
  recommendation gates person-to-person connection (matching and beyond),
  leaving browse-only use available without biometrics — deliberately, so
  that consent is not coerced by total exclusion from the service.

## D · Why we believe this is special-category processing

We proceed on the assumption that the face-match step is biometric data used
for the purpose of uniquely identifying a natural person (UK GDPR Article 9),
requiring both an Article 6 lawful basis and an Article 9 condition, a DPIA,
and an Article 28 processor contract. We have relied on ICO public guidance
(references in Annex F.4) but have made no legal determinations. All
conclusions are for the solicitor.

---

## E · The seven questions requiring written legal advice

*(These reproduce, in instruction form, the seven outputs identified in the
internal technical evaluation. Written advice is requested on each.)*

**Q1 — Lawful bases.** What are the appropriate Article 6 lawful basis and
Article 9 condition for (a) ID-document-to-selfie biometric verification and
(b) provider-side duplicate face comparison within our own user population?
If explicit consent is the appropriate Article 9 condition: what must our
consent flow contain for the consent to be specific, informed, freely given
and withdrawable — and does offering a browse-only unverified tier satisfy
the "suitable alternative" expectation? Separately: would a future
profile-photo-to-selfie comparison need its own distinct basis and consent?

**Q2 — DPIA.** Please advise on (or review our draft of) a DPIA covering:
false matches; demographic and accessibility performance of face-match
technology; the duplicate-review process; limits on automated
decision-making; the alternative verification path; the 18+ age boundary and
risk of minors; misuse scenarios; breach impact; and data-subject rights
handling. Which residual risks, if any, would require prior consultation
with the ICO?

**Q3 — Provider roles.** For each candidate provider, please characterise
the controller/processor split between: customer-directed verification
(ZYRA-directed); the provider's own fraud-prevention, security,
product-improvement, reusable-identity and cross-network processing (where
the provider acts as an independent controller). What disclosures do we owe
members about the provider's independent uses, and what contractual limits
should we require?

**Q4 — International transfers.** Sumsub publishes European data-centre
storage with selectable regional processing; Stripe states US
processing/storage for identity-verification data. Please advise on the
transfer mechanism and transfer-risk assessment required in each case for a
UK controller, and whether either posture is materially preferable.

**Q5 — Retention and deletion.** What contractual retention terms should we
require for media, biometric templates, backups and search indices;
what deletion SLA is appropriate; how should deletion interact with the
duplicate-detection index (a deleted member's face leaving the comparison
population); and what export/deletion terms do we need at contract
termination?

**Q6 — Prohibited provider uses.** Which provider uses should be expressly
prohibited or narrowed in contract: model training on our members' biometric
data; cross-customer biometric matching; fraud-network sharing; independent
retention beyond our instruction? (One candidate's terms permit service
development/machine-learning use and independent retention — see Annex F.3.)

**Q7 — Human review and automated decisions.** Does our duplicate-review
design (flag → human review in the provider console → authorised resolution;
never an automatic ban) keep us outside Article 22 solely-automated
significant decisions? What appeal/contest mechanism, reviewer authorisation,
evidence-retention and audit-trail arrangements should we operate so that a
false duplicate match is correctable and demonstrably fair?

---

## F · Annex — engineering facts and provider-published terms (evidence, not legal positions)

### F.1 Data held by ZYRA under the proposed model
Provider code; opaque session reference; coarse result enum; boolean
duplicate-review flag; event reference for idempotency; timestamps. Expressly
prohibited at ZYRA rest/logs/analytics: document or selfie files/URLs; facial
embeddings/templates; similarity or confidence scores; extracted document
attributes (name, DOB, document number, address); provider duplicate-hit
applicant IDs or match criteria; full webhook/API payloads.

### F.2 Verification data flow (as designed)
Device → provider (direct capture upload). Provider → ZYRA: signed webhook to
a dedicated server function; signature verified before parsing; payload
collapsed in memory to the coarse result; raw payload discarded. Human
review of duplicates occurs in the provider's console; ZYRA ingests only the
final coarse outcome.

### F.3 Provider-published terms as researched 2026-08-29 (sources on file)
- **Sumsub:** DPA within public terms (customer controller / Sumsub
  processor for customer-directed verification; UK transfer provisions);
  European data-centre storage with "Local Data Processing" regional options;
  retention configurable by customer instruction; deletion removes the
  applicant from the search index; "Sumsub ID" reusable-identity product
  would make Sumsub a controller and is intended to remain disabled.
  Duplicate detection ("Similar Search") is API-documented; inclusion in the
  Basic price tier is not publicly confirmed.
- **Stripe Identity:** DPA published; support material states identity
  verification data is processed/stored in the United States regardless of
  user location; biometric identifiers normally retained up to one year,
  other submitted identity data up to three years unless deleted sooner;
  processor for customer-directed verification and independent controller
  for fraud/security and certain other uses; duplicate-selfie detection is
  surfaced in its human review Dashboard, with no publicly documented
  API/webhook duplicate field.
- **Veriff (excluded candidate, for completeness):** published service
  description documents automatic decline of duplicate users within an
  integration ("…the given Session shall be declined"), cross-customer
  "Industry CrossLinks" risk labels, ~90-day active retention plus up to
  three-year archive including face embeddings, and DPA/service terms
  permitting some independent business use including service development /
  machine learning. Excluded under the internal human-review-only rule
  unless renegotiated in writing.

### F.4 Public guidance relied on for framing (not legal advice)
ICO: lawful biometric processing; biometric recognition as special-category
data; DPIA triggers; Article 28 contract content. (Links held in the
internal evaluation 027 §9/§12.)

### F.5 What the instructing client will provide on engagement
The internal technical evaluation (027) in full; the capability matrix with
Founder decisions; the chosen provider's contract pack (DPA, retention,
data-location, sub-processor list) once obtained; a DPIA draft if the
solicitor prefers to review rather than author.

— END —
