---
id: DOC-ZYRA-0004
type: SPEC
status: CURRENT
feature: APP: AUTHENTICATION
purpose: Authentication — Summary
links: []
owner: ZYRA chat
---

# Authentication

> CURRENT SIGNUP MEMBERSHIP AMENDMENT — 2026-10-03 / DR-ZYRA-252:
> Required account details → role-aware membership preference → real IDV →
> confirmed account finalization. Basic is £4.99 once, not £0; choosing any
> membership does not prove payment, begin a trial, allocate a Family place or
> bypass verification. Per-owner/backend native storage retains only the
> commercial preference after identity-form erasure; logout clears both
> records with queue/epoch protection. Legacy unfinished accounts collect the
> new choice without losing answers. No live auth policy, provider, receipt,
> release flag or backend change is made. Onboarding Preview §93 / OA-ZYRA-303.

> CURRENT ONE-APP / PROGRESSIVE ONBOARDING OVERLAY — 2026-10-02:
> AD-AIOS-111 and OA-ZYRA-286 supersede the historical dual-app/staging
> description below. One main ZYRA app carries a protected Founder-only local
> preview; ordinary members do not receive its skip/authorization controls.
> Signup requires essentials (including both required public names under
> DR-ZYRA-251 / OA-ZYRA-145) and real server-verified identity before account
> finalization. Then Seekers choose profile setup now or My ZYRA/finish later;
> returning unfinished accounts resume from My ZYRA. Preview never writes
> member data or becomes live when authorization is revoked. This cleanup
> does not configure IDV or change the held existing-account enforcement flag.
> Onboarding Preview handover §89–90 / OA-ZYRA-303 are the current client facts;
> the earlier deployment history below is retained, not current instructions.

**Status:** Production member model current; dual-app Founder-test boundary
implemented locally but not live
**Updated:** 2026-09-12
**Authority:** DR-ZYRA-209 · DR-ZYRA-219 · DR-ZYRA-221 · DR-ZYRA-228 · DR-ZYRA-229 ·
OA-ZYRA-286 · `Script/Script_V3.md`

Members enter with Apple or Google. Recovery email is an already-verified,
passwordless recovery route; it cannot create an account. There is no public
ZYRA password, email/phone signup, Founder login or Developer Access button.

Production ZYRA authenticates against production and always denies Developer
Access. ZYRA Test's configured target must be the isolated staging project
recorded in the Developer Control handover. A successful current session refresh must return the independently
pinned exact Founder UUID plus protected `app_metadata.zyra_role = founder`
before the Founder operator shell; neither condition alone, nor
email/domain/TestFlight membership, grants authority.
An iOS bundle/display-name mismatch locks before Supabase initialises, and
sign-out clears refreshed Founder proof on every path.
Every Auth event and app resume also re-check proof. `userUpdated` and resume
require a real refresh, account/claim changes supersede older work, and proof
clears synchronously while replacement work runs. Non-refresh loss including
`signedOut` immediately removes developer controls and the open guarded route
through `AuthGate`. Auth-stream errors take the same fail-closed path and log
only a fixed generic diagnostic.
Developer Access refreshes before navigation and at its destination, while
Splash Lab leaves repeat their own guard.

The Founder operator may bypass member onboarding/IDV only inside the isolated
staging operator shell. Every real or synthetic member remains governed by the
normal onboarding and verification rules.

Founder Test now enforces existing-account IDV for every non-Founder session.
Ordinary Test members need `verified`; pinned personas also need exact marker
`founder_test_synthetic_idv_fixture_v1`, consent, explicit duplicate-clear and
non-epoch consent/update/decision timestamps before app entry or in-app test
capability.
Pinned UUID/email with a missing or wrong protected persona claim receives a
dedicated blocked surface and is never treated as an ordinary member.
Invalid or missing pinned-persona state exposes only **Check again** and
**Return to sign in**, never the real consent/provider/delete flow.

The local source contains the fail-closed target, backend and claim policy. The
shared executable Test preflight exact-pins the staging URL/reference/public
client key, Google/native values, the exact Founder UUID and all four persona
UUIDs against intentionally unassigned approved-resource pins; the five
identity UUIDs must be unique. It therefore cannot pass until an exact
Founder-approved pin revision. It permits only the exact pinned
`sb_publishable_*` value or exact pinned legacy anonymous/staging-ref JWT, and
rejects secret/service-role, wrong-ref and malformed keys. Test configuration
or startup failure stays on a Test-specific lock/retry surface, never Welcome
or Production. The Google OAuth client selector is target-aware, defaults Test
to disabled and refuses Production IDs in Test; real Test OAuth clients and
provider settings are not yet created. The legacy shared-password path and
plaintext literals in retained repository helpers/history are removed locally.
Those helpers require ephemeral caller input, refuse Production and remain
inert while the staging pin is unassigned; live credential rotation remains
unknown and separately gated. Persona broker source is staged. DR-ZYRA-229
permits its one-use token_hash over TLS solely for immediate native Auth
redemption, never embedded/logged/displayed/persisted. The token-return design
ruling is settled; live expiry/replay and integration proof remain required. Its
environment-supplied persona
UUIDs are now checked against independent exact Edge source pins, while the
client independently pins its Founder and persona identities. The Founder and
four persona pins all remain unassigned and inert. Exact assignment and
client/server parity are still required before deployment.
The staged broker also records only coarse 30-day, minute-bucketed
post-configuration delivery counts for denial, mint failure and issuance; it
stores no identity or exchange material and withholds issuance if the `issued`
outcome cannot be recorded. It remains unapplied and undeployed.

Its persona SQL boundary and the separate fifteen-RPC developer overlay are
also only staged, sentinel-inert and unapplied; both SQL harnesses remain
authored but unrun. DR-ZYRA-229 records Founder acceptance of the limited
`auth.sessions` validity check as defence in depth; fresh server getUser and
fresh Admin Founder checks remain mandatory. This is not deployment approval.
The exact fixture policy is local, but no staging row is approved or seeded:
no persona may be enabled until the Founder approves the reviewed synthetic
states and fixture-only behaviour is proved. The staged RPC overlay has not
silently gained an IDV predicate.

The Edge policy suite now passes 11/11 in Deno with type-checking enabled, and
the entrypoint type-check passes (message 091); these are not live Auth evidence.

The empty staging project now exists and is post-verified (message 093 and the
Developer Control handover). No application schema, live Founder UUID/role/
provider configuration, Apple Test record, signed build or TestFlight upload
exists yet. Those remain separately and exactly Founder-gated under OA-ZYRA-286.
