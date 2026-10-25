# 026 — FABLE → CODEX — 2026-08-29 — IDENTITY-VERIFICATION PROVIDER EVALUATION (OA-ZYRA-280, report-only)

## Authority and gates

Founder directive 2026-08-29: move identity verification (OA-ZYRA-266)
forward TODAY. Governance unchanged: this is an EVALUATION, not a build.
DR-ZYRA-219 items 7-8 bind everything: no ZYRA face database, no
auto-ban/auto-merge, tenant-scoped opaque duplicate signal + human review,
and NO implementation before the Founder's capability matrix and the
solicitor's Article 9 gate (OA-ZYRA-259/266). Nothing here ships.

## The shape (already decided by ruling)

Specialist provider does: document authenticity AI + selfie liveness +
face-match to document. Provider holds all biometric data. ZYRA stores ONLY:
verified flag, provider reference/session id, timestamps. The "photo AI
checker" layer = the same provider selfie matched to profile photos as a
product rule on top — evaluate feasibility, do not design product rules.

## Candidates to evaluate (2026-08 indicative pricing)

1. **Stripe Identity** — ~$1.50/check, NO monthly minimum; ZYRA already has
   a Stripe account (onboarding pending). Evaluate: Flutter path (native
   iOS/Android SDK vs web-redirect flow), webhook/result flow into Supabase,
   whether ANY tenant-scoped duplicate/1:N signal exists (believed absent —
   confirm).
2. **Sumsub** — ~$1.35/check + ~$150/mo minimum; official Flutter SDK;
   applicant DEDUPLICATION exists — evaluate whether it delivers the
   DR-ZYRA-219 opaque duplicate signal (tenant-scoped, no raw biometrics to
   ZYRA).
3. **Veriff** — ~$0.80/check + ~$49/mo minimum; official Flutter plugin;
   check duplicate/re-verification capability.
4. (Desk-note only, no deep dive: Persona now $250/mo + annual contract;
   Onfido/Yoti sales-gated pricing.)

## Deliverable — report as 027_CODEX-FABLE

Per candidate: Flutter integration path + effort; data-flow diagram
(document/selfie NEVER at rest in ZYRA; opaque result only); result/webhook
handling into Supabase (design only — no migration, no schema change);
duplicate-signal capability vs DR-219 item 7; failure/retry UX implications;
per-check + minimum cost at our launch volumes; UK/GDPR processor posture
(DPA availability, where biometrics are stored). Finish with a reasoned
recommendation: launch provider + duplicate-control path (may be one
provider or a staged pair).

## Hard boundaries

- Report only: NO provider account creation, NO API keys, NO SDK added to
  the app, NO migration, NO consent screens, NO git. Sandbox trials need
  Founder-created accounts — request via Fable if docs alone are
  insufficient.
- Cost figures marked as quoted-from-docs vs estimated.
- The capability matrix (which ZYRA features require verification) is
  FOUNDER definition work in OA-ZYRA-266 — do not propose it as settled.
