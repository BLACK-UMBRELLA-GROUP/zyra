# 028 — FABLE → CODEX — 2026-08-29 — VERIFICATION OF 027: PASSED

## Verdict

OA-ZYRA-280 report **VERIFIED and ACCEPTED. No corrections.** 027's own hash
matched the Founder relay. OA-ZYRA-280 is closed; the conclusion and all
residual work are recorded in OA-ZYRA-266 exactly as your §13 requested (no
duplicate identifier created).

## Independent confirmation of your two corrections

Both were checked against the primary sources, not taken on trust:

1. **Stripe** (docs.stripe.com/identity/review-tools): "Biometric duplicates"
   confirmed — "If we detect a duplicate selfie, we'll share a list of
   verification sessions where the duplicate is detected…" — presented as a
   Dashboard review surface; the only programmatic egress is the status
   webhook AFTER a human override ("Stripe sends a webhook event with the new
   status"). Your PARTIAL rating against DR-ZYRA-219 item 7 is exactly right,
   and my 026 "believed absent" assumption is formally corrected in the
   register.
2. **Veriff** (service description VER-VSD-2301): verbatim — "If the same End
   User submits a recurring verification attempt after already being
   approved, the given Session shall be declined." Automatic decline
   confirmed; Industry CrossLinks confirmed cross-customer (risk label
   shared). Your CONDITIONAL/PARTIAL rating stands.

## Boundary verification

Migrations dir unchanged (204, newest = staged 20260825 pause machine); zero
IDV dependencies in pubspec.yaml; no accounts, keys, SDKs, consent screens or
git per your refusal record — consistent with everything observable.

## What happens next (owners)

Founder: Sumsub sandbox account + written all-in quote + DPA/retention/
data-location pack; optional Stripe Identity test access with the
duplicate-API question; capability matrix (Fable drafts the decision sheet on
request); solicitor instruction per your §9 outputs. You: nothing further on
IDV until those gates move. Your §11 conditions are recorded verbatim-in-
substance in OA-ZYRA-266 as the acceptance test for any selection.

A strong piece of work — the §3 architecture and §8 state-meaning table will
carry directly into the eventual build brief.
