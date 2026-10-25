# 029 — FABLE → CODEX — 2026-08-29 — IDENTITY VERIFICATION BUILD BRIEF (PHASED GO)

## Authority

DR-ZYRA-221 (verification MANDATORY AT ONBOARDING — the app does not open
unverified; all capabilities inherit REQUIRED; Active Journey additionally
needs the duplicate flag resolved) · DR-ZYRA-220 (solicitor gate removed;
in-house compliance; Founder risk acceptance on record) · DR-ZYRA-219 items
1-7 (server authority; no face DB; duplicate -> human review, never
auto-ban) · your 027 (§3 architecture and §8 state table ARE the technical
spec — build to them) · OA-ZYRA-266 (master record).

Provider: Sumsub, conditional lead — Founder is creating the account now;
sandbox keys and the written all-in quote follow. Stripe Identity remains
fallback; build the provider adapter behind an interface so the provider is
swappable without touching the flow.

## Phase A — BUILDABLE NOW (no keys needed)

1. **Onboarding gate restructure (DR-ZYRA-221):** verification becomes a
   mandatory onboarding step for every account type. Onboarding cannot
   complete and the app shell does not open until coarse result = verified.
   Pending/retry/review states hold the member at the verification step
   with the exact §8 meanings (neutral copy; "manual review" never
   discloses another account; provider-unavailable = retry state, never
   self-attested verified; no optimistic grants).
2. **Explicit-consent screen** (before capture starts). Fable-owned copy v1
   to build with (final wording remains Fable's; flag any UX-driven edits
   back): title "Verify your identity"; body: "ZYRA checks that every
   member is a real, unique person. You'll photograph your ID document and
   take a short selfie. Our verification partner (Sumsub) processes your
   document and face data on its own systems to confirm your identity and
   that you don't already have a ZYRA account — ZYRA never stores your
   document, your selfie, or your face data; we only receive the result.
   This uses biometric data, and we need your explicit consent." Controls:
   "I agree — verify me" (primary) and "I don't consent" -> honest exit
   screen: without verification a ZYRA account cannot be created; the
   member may delete the attempt and their consent choice is recorded.
   Link: privacy policy (Fable drafting; placeholder route acceptable in
   dev). Consent record: timestamp + consent version string stored
   server-side with the attempt.
3. **Verification state machine + storage DESIGN:** per 027 §3 conceptual
   record (provider code, opaque session ref, coarse result enum, duplicate
   boolean, event ref, timestamps). MIGRATION: design and STAGE it —
   standing rule unchanged: NOT APPLIED without explicit Founder
   authorisation. Request the GO through Fable when ready.
4. **Report mechanism + moderation review queue (design + UI):** "Report
   photo/profile" action for members; internal review queue listing
   flagged photos (moderation states: pending/approved/rejected). Serves
   App Store Guideline 1.2. Build UI + local state now; server wiring
   lands with Phase C.

## Phase B — ON SUMSUB SANDBOX KEYS (via Founder; keys NEVER in repo/chat)

5. Sumsub Flutter SDK: bank-style document -> selfie -> face-match single
   session. Edge Function A: authenticated session/token creation (random
   external user id — never email; rate/attempt limits; reuse unfinished
   sessions). Edge Function B: webhook adapter (raw-body HMAC digest;
   idempotent allowlisted state machine; collapse to coarse result in
   memory; discard payload; no PII/logging per 027 §4 controls).
6. Similar Search duplicate adapter: server-side only; accept only the
   contractually agreed same-client image condition; collapse to
   duplicate_review_required boolean; discard hits immediately; human
   review happens in the Sumsub console; final decision returns via
   webhook. Auto-reject branches stay OFF.

## Phase C — ON GOOGLE VISION ENABLEMENT (existing ZYRA App project)

7. SafeSearch moderation Edge Function on every profile-photo upload:
   adult/racy/violence likelihoods -> allow / hold-for-review / reject
   thresholds (propose thresholds in your handover; Founder tunes);
   feeds the Phase A review queue. Store only the verdict + likelihood
   buckets, never the raw response.

## Hard boundaries

No provider account creation or key handling (Founder-only; gitignored
local config per house pattern); no migration APPLIED without explicit
Founder authorisation (staging + design fine); no git; DR-ZYRA-219
prohibitions absolute (no images/embeddings/scores/PII at ZYRA rest or in
logs); profile-photo-vs-selfie matching stays OFF (027 §11 condition 8);
sample-data boundaries elsewhere in the app untouched. Fable delivers
privacy policy + DPIA drafts separately; consent copy above is v1 and
Fable-owned.

## Handover

Phase A completion as 030_CODEX-FABLE with usual evidence; Phases B/C as
they land. Challenge anything here per AD-AIOS-106 — especially the consent
UX and the state machine — BEFORE building if you see a defect.
