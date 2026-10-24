# ZYRA — Privacy Policy: Identity Verification & Photo Moderation Sections (DRAFT)

**Version:** V1
**Status:** DRAFT — NOT FINAL LEGAL AUTHORITY (DR-ZYRA-220 in-house compliance path; Founder review + sign-off required; items marked ⚖️ would benefit from solicitor confirmation if that decision is ever revisited)
**Date:** 2026-08-29
**Author:** Fable
**Register:** OA-ZYRA-266 · DR-ZYRA-219/220/221
**Scope note:** These are the identity-verification and photo-moderation sections for the app-grade privacy policy. They are written to be dropped into the full policy (which also covers profiles, matching, Guardians, notifications, payments). Wording reflects the ACTUAL built architecture (030/031-verified) — if the architecture changes, this document must change with it.

---

## Draft user-facing sections

### Verifying your identity

ZYRA requires every member to verify their identity before their account
opens. We do this so that every person you meet on ZYRA is a real, unique
individual.

Verification is carried out by our specialist verification partner,
**Sumsub** *(⚖️ provider named pending final contract; replace if the
fallback provider is used)*. During verification you will photograph your
identity document and take a short video selfie. This happens inside our
partner's secure capture flow: **your document and your face data go
directly from your device to Sumsub — they are never uploaded to, stored
on, or visible to ZYRA's own systems.**

Sumsub checks that your document is genuine, that your selfie is a live
person, and that your face matches your document photo. Because this uses
your biometric data (special-category data under UK GDPR), we ask for your
**explicit consent** before the process starts. If you do not consent, we
cannot open a ZYRA account for you — identity verification is a condition
of membership *(⚖️ consent-as-condition wording — recorded Founder
decision DR-ZYRA-221)*.

**What ZYRA receives and stores:** only the outcome — whether verification
succeeded, a reference number, the date, and your consent record. ZYRA
never holds your ID document, your selfie, your face template, or any
similarity score, and we never build a face database.

### Duplicate-account checks

To keep ZYRA safe, our verification partner also checks whether your
verified face already belongs to another ZYRA account (this comparison
happens only within ZYRA's own membership, on Sumsub's systems — never
across other companies' services). If a possible duplicate is found, the
result is a single yes/no flag sent to ZYRA. **A duplicate flag never
results in an automatic ban.** It is always reviewed by an authorised
human, and while that review happens you will simply see that your
verification is under manual review. We will never disclose another
account's details to you, or yours to anyone else, as part of this
process.

### If verification does not succeed

You can retry if a capture goes wrong. If a check cannot be completed, we
show you a neutral message and a route to support. Verification decisions
about your membership are never made solely by a machine: any adverse
outcome that would prevent you joining involves human review, and you can
contest it through support. *(⚖️ Article 22 posture)*

### Your photos

Every photo uploaded to a ZYRA profile is automatically screened by an
image-safety service (Google Cloud Vision SafeSearch) for nudity, sexual
content and graphic violence before it appears anywhere. Photos that fail
screening are not published; borderline photos are held for human review.
We store only the screening outcome — not the analysis itself. Members can
also report any photo or profile, and reports go to human review.

### Keeping and deleting verification data

- ZYRA keeps its verification outcome record (result, reference, consent
  record, timestamps) for as long as your account exists, and deletes it
  with your account, keeping only the minimal consent evidence we are
  required to retain. *(⚖️ retention period for consent evidence)*
- Sumsub retains the document, selfie and biometric template on its
  systems under its agreement with ZYRA. Retention period and deletion:
  **[TO BE COMPLETED FROM THE SIGNED SUMSUB DPA — do not publish before
  this is filled]**. When your data is deleted by Sumsub, your face also
  leaves the duplicate-check comparison.
- You may withdraw consent at any time before verification completes; an
  unstarted attempt can be deleted from the app. Withdrawing consent after
  membership means closing your account. *(⚖️ withdrawal-consequence
  wording)*

### Who processes this data

- **Sumsub** — identity verification processor acting on ZYRA's
  instructions; European data-centre storage *(exact region per contract —
  TO BE COMPLETED)*; sub-processors per its published list *(link on
  signature)*.
- **Google Cloud** — image-safety screening of profile photos (the photo
  is analysed and the safety verdict returned; ZYRA stores the verdict
  only).
- ZYRA's own data platform (Supabase, EU-hosted) stores only the outcome
  records described above.

### Your rights

You have the rights UK GDPR gives you: access, rectification, erasure,
restriction, objection, portability, and the right not to be subject to
solely automated decisions with legal or similarly significant effect.
For anything involving your document, selfie or biometric data, we will
coordinate with Sumsub, which holds that data. Contact:
support@zyraconnect.app. You may complain to the ICO (ico.org.uk).

### Guardians

Guardian accounts verify their identity on the same basis as Seekers
*(per DR-ZYRA-221; held-open exemption flag — if the Founder exempts
Guardians at launch, this sentence changes)*. Guardian activity within a
Seeker's journey is described in the Guardian section of the full policy.

---

## Items requiring completion before publication (tracked in OA-ZYRA-266)

1. Sumsub contract facts: exact storage region, retention period, deletion
   SLA, sub-processor list link (from the signed DPA/quote pack).
2. Full-policy merge: these sections join the app-wide policy (profiles,
   matching, Guardian data, notifications, purchases) before any store
   submission — the App Store requires the complete policy at a public URL.
3. ⚖️-marked wordings: consent-as-condition, withdrawal consequence,
   consent-evidence retention, Article 22 posture — Founder-accepted under
   DR-ZYRA-220; revisit with a solicitor only if that decision changes.
