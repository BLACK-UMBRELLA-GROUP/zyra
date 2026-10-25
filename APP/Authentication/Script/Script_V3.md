---
id: DOC-ZYRA-0003
type: SPEC
status: CURRENT
feature: APP: AUTHENTICATION
purpose: Authentication / Script — Script V3
links: []
owner: ZYRA chat
---

FEATURE NAME
AUTHENTICATION

SCRIPT VERSION: V3
STATUS: Approved Specification — CURRENT
DATE: 2026-09-12
SUPERSEDES: Script_V2.md
GOVERNING REFERENCES: ZYRA_SETTINGS_AND_IDENTITY; DR-ZYRA-209;
DR-ZYRA-210; DR-ZYRA-219; DR-ZYRA-221; DR-ZYRA-228; DR-ZYRA-229; OA-ZYRA-286

============================================================
PUBLIC MEMBER ENTRY
============================================================

The public ZYRA entry remains:
• Continue with Apple
• Continue with Google
• Use recovery email, only for an address already verified from inside an
  existing Apple/Google account

There is no ZYRA password, public email/phone account creation, Founder button,
staff button or Developer Access button before authentication. A first provider
sign-in enters the mandatory onboarding/identity-verification path; an existing
member resumes the truthful routed destination.

Manual Apple/Google identity linking remains OFF in V1 under DR-ZYRA-219.
Recovery is passwordless, uses neutral unknown-address copy and may not create
a user (`shouldCreateUser: false`). Provider identity, recovery email and
contact email remain distinct.

============================================================
APPLICATION AND BACKEND BOUNDARY
============================================================

ZYRA Production uses `app.zyraconnect.zyra`, the production backend and no
Developer Access. Missing or unknown Flutter flavour fails closed to this
production identity and cannot opt into test privilege.

ZYRA Test uses exact flavour `foundertest`, proposed bundle
`app.zyraconnect.zyra.test` and a separate staging backend. All staging URL,
publishable-key and project-reference pins must be present and internally
consistent. The production project reference is explicitly refused. No runtime
environment selector or fallback exists.

A single executable preflight validates the supplied exact staging URL,
reference and public client-key pin, both Test Google client IDs plus native
parity, the exact Founder UUID and all four persona UUIDs against separately
reviewed compile-time pins. All five identity UUIDs must be distinct. The key
must equal its approved pin and be either
`sb_publishable_*` or a legacy JWT carrying exact anonymous role and staging
reference; secret/service-role, wrong-ref and malformed keys fail closed.
Every approved pin is deliberately unassigned today, so the configured Test
path cannot pass before an exact Founder-approved pin revision. Configuration
and staging-startup failures remain on Test-specific lock/retry surfaces;
neither falls through to Welcome, mock state or Production.

On iOS, the compiled Dart target must also match the installed bundle
identifier and display name. That check completes before Supabase
initialisation; mismatch locks the app and makes no backend connection.

Both applications share the same authentication, onboarding and product code.
Only identity/configuration/backend/test tooling may differ unless the Founder
explicitly rules otherwise.

============================================================
FOUNDER AUTHORISATION
============================================================

In ZYRA Test, the Founder uses a normal configured provider sign-in. Developer
Access is allowed only after a successful current session refresh returns a
user whose UUID byte-matches the separately reviewed exact Founder pin and
whose server-controlled `app_metadata.zyra_role` is exactly `founder`. The UUID
and protected role are both required; neither alone grants authority.

The application clears earlier privilege before refresh. Failure, null user,
stale claim, wrong role, wrong target, wrong project, ordinary account or role
removal denies access. Email text, domain membership, editable user metadata,
TestFlight membership, build mode and local flags are never authority.

Refreshed Founder and seeded-persona proof are retained separately. Duplicate
work for the same account and protected-claim identity joins one authorisation
flight; an account or relevant-claim switch supersedes any older result.
Every Auth event and app resume triggers re-evaluation. `userUpdated` and
resume force a real refresh, while non-refresh events never publish a claim.
Replacement work clears proof synchronously. Loss of previously accepted
authority, including `signedOut`, immediately removes the developer overlay
and schedules an open guarded surface through `AuthGate`. An Auth-stream error
is handled by the same fail-closed path and logs only a fixed generic message,
never the error object or stack.

Production denies Developer Access even if a token presents a founder claim.
Every developer destination and privileged server action repeats its own
default-deny check.

Developer Access refreshes before navigation, remains covered during an
asynchronous destination refresh/recheck, and returns to `AuthGate` if that
proof fails. Auth events use the pre-event allowed state so a newly replaced
`currentUser` cannot suppress the authority-loss redirect. Splash Lab menu and
playback leaves also deny direct unauthorised routes.

Sign-out clears refreshed Founder proof before attempting the remote sign-out
and again in `finally`, including duplicate and failed sign-out paths.

The authorised Founder may enter the ZYRA Test operator shell before member
onboarding/IDV. This narrow exception belongs only to that non-member staging
operator and grants no bypass to members or production.

============================================================
SEEDED PERSONAS
============================================================

Synthetic Seeker and Guardian personas remain separate staging identities.
The Founder account operates the tool and is never linked to those identities.
Persona-only controls require exact agreement between the compiled UUID, fixed
email and protected `app_metadata.zyra_test_persona` claim.
Pinned UUID/email with a missing or wrong protected persona claim receives the
dedicated identity-blocked surface and cannot fall through as an ordinary
member.

Every non-Founder Founder Test session is subject to the existing-account IDV
gate. An ordinary Test member needs canonical `verified`. A pinned synthetic
persona additionally requires duplicate review explicitly clear, granted
consent, exact marker `founder_test_synthetic_idv_fixture_v1`, and non-epoch
consent-recorded/update/decision timestamps before app entry or in-app
developer capability. Null duplicate state, a production consent version, or
missing/pending/retry-required/review-required/failed/expired/cancelled state
denies. The exact fresh Founder operator remains the earlier, non-member
bypass.
Invalid or missing synthetic state presents only **Check again** and **Return
to sign in**; it never exposes the real consent/provider/delete flow.

Persona switching must be performed by a staging-only server boundary that
validates the independently exact-pinned Founder UUID with a freshly checked
protected Founder role and accepts only a fixed server-side allowlist. Neither
binary may embed a shared test password, service-role key,
OTP, action link or reusable privileged credential. DR-ZYRA-229 permits only
the short-lived, one-use `token_hash` response over TLS for immediate native
`verifyOTP` exchange. It remains sensitive authentication material even though
hashed. No exchange material may be logged, displayed or persisted.

============================================================
CURRENT STATUS — 2026-09-12
============================================================

The shared-source application variant, fail-closed backend selector and exact
Founder-UUID plus fresh-role policy are implemented locally with focused tests.
The Google OAuth client selector is variant-aware: Test values default to empty
and Test refuses either Production client ID. Real Test OAuth clients and
provider/redirect configuration are not created or verified. The legacy
shared-password client path and plaintext legacy credential literals in
retained repository helpers/history are removed locally. Seed/photo helpers
now require ephemeral caller input, reject Production and remain inert behind
an unassigned staging pin. This is not evidence of live account rotation; live
credential status is unknown. Local persona client/Edge Function source is
staged. DR-ZYRA-229 approves its narrow one-use token-hash exchange design;
exact pins, independent expiry/replay proof and separate deployment GO are
still required before live use.
Independent exact Edge source pins now cover the Founder UUID and all four
persona UUIDs, but each remains deliberately unassigned and inert. Runtime
values must byte-match valid unique assigned pins, and client/server parity
must be proved before deployment.

The staged delivery audit distinguishes post-configuration denial, mint
failure and actual issuance from the older pre-mint `authorized` decision. It
stores only 30-day minute-bucketed outcome counts and no identity, session,
persona, token, email, IP, payload or raw error. Issuance-audit failure
withholds the exchange; denial-audit failure never turns denial into access.

The companion persona database boundary and the fifteen-legacy-RPC security
overlay are staged outside active migrations, unapplied and sentinel-inert.
The persona boundary adds protected-role re-read, exact `auth.sessions`
correlation and durable atomic rate limiting; the RPC overlay adds exact
staging/persona/fixture checks. The complete persona transactional harness
passed once against the narrow disposable PostgreSQL17.6 test setup on
2026-09-12, with rollback, exact container cleanup and VM shutdown verified
(message 100). The fifteen-RPC overlay harness and combined full-schema
replay remain unrun; this persona-only result is not managed Auth or live
Supabase proof. The
`auth.sessions` row check is defence in depth rather than complete GoTrue
runtime-validity proof. The Founder accepted that limitation in DR-ZYRA-229;
fresh server `getUser`, fresh Admin Founder checks and the database boundary
remain required. That design acceptance is not deployment approval.
The exact synthetic-fixture admission policy is implemented locally, but no
staging verification row was approved or seeded. Persona enablement therefore
still waits for Founder approval of the reviewed exact-marker rows and proof
that the resulting behaviour is fixture-only. This client gate does not invent
a predicate in the separately staged RPC overlay.
Report 091 records all eleven Edge policy tests passing with type checking and
the SDK-pinned Edge entrypoint check passing. These are local checks, not live
SQL or Auth verification.

The empty staging project is post-verified (message 093 and the Developer
Control handover). Application schema, providers, exact Founder staging
principal/role/UUID pins, deployed persona service and Apple ZYRA Test identity
are not live. The local scaffold is not a working remote test channel.

No live provider setting, Auth mutation, migration, deployment, archive or
upload is authorised by this specification. OA-ZYRA-286 owns the remaining
implementation and evidence. OA-ZYRA-245 remains completed Guardian Network
history and is not the Developer Access action.
