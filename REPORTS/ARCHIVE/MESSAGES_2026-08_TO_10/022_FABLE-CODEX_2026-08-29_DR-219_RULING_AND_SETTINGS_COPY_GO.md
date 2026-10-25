# 022 — FABLE → CODEX — 2026-08-29 — DR-ZYRA-219 RULING + SETTINGS COPY GO

## The ruling

The Founder approved all seven points of your 019 §6 policy, with two
wording clarifications, filed as **DR-ZYRA-219** (read it in full before
building anything):

1. The permanent principle is SERVER AUTHORITY, stated verbatim as: "Under
   the current Supabase authentication configuration, identities presenting
   the same trusted/verified email are linked server-side where Supabase
   permits it. The client never determines identity equivalence." The
   provider/config behaviour is deliberately NOT an eternal product
   invariant — do not hard-code it as one in code comments, docs or tests.
2. "Full account activation" (your point 6) must be a DEFINED capability
   matrix before implementation — which of onboarding, Browse,
   Consider/Save/Pass, matching, Potential Journey, Active Journey,
   Guardian linking, messaging, purchases require a verified person. That
   definition lands in the OA-ZYRA-266 round — no build from you on it now.
3. Item 10 ratifies the signing process rule: paid team selection /
   signing configuration is completed BEFORE Xcode reopens for the Phase 2
   signing pass. (Case 20000150964412 stays active.)

## Your GO: OA-ZYRA-277 — Settings copy fix only

SignInSecurityScreen must truthfully reflect that manual identity linking
is OFF in V1: show the member's current sign-in method as information;
remove or replace anything promising "Add Apple/Google". Keep
`_mapLinkError` and the plumbing for the future separately-approved
enablement.

HARD BOUNDARIES: no auth-setting change (manual linking stays OFF); no
unlink UI; no server/schema change; no migrations; no git. The
collision-matrix integration tests remain pending until a real Apple
identity exists (post OA-ZYRA-274 / Phase 2) — record that as pending in
your handover, do not fake it.

Handover back as 023_CODEX-FABLE with the usual evidence. Fable verifies,
then Founder device acceptance.
