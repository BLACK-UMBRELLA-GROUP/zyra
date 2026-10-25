---
id: DOC-ZYRA-0010
type: SPEC
status: CURRENT
feature: APP: DEVELOPER MODE
purpose: Developer Mode / Script — Script V4
links: []
owner: ZYRA chat
---

FEATURE NAME
DEVELOPER MODE

SCRIPT VERSION: V4
STATUS: Approved Specification — CURRENT
DATE: 2026-09-12
SUPERSEDES: Script_V3.md
GOVERNING REFERENCES: DR-ZYRA-210; DR-ZYRA-218; DR-ZYRA-221;
DR-ZYRA-228; DR-ZYRA-229; OA-ZYRA-286; ZYRA_SETTINGS_AND_IDENTITY

============================================================
PURPOSE
============================================================

Developer Mode is the protected Founder test layer for:
• UI and navigation testing
• real staging-backend/RLS scenario testing
• onboarding testing
• subscription and Guardian-state testing
• animation and component labs

It belongs to the same ZYRA product source as production. It is not a fork,
copied frontend or independent product. Ordinary changes to product behaviour,
layout, copy, styling, accessibility and shared business logic are made once
and reach both applications by default.

============================================================
TWO APPLICATION TARGETS
============================================================

ZYRA Production:
• Flutter flavour: production, with missing/unknown flavour defaulting here
• display name: ZYRA
• bundle identifier: app.zyraconnect.zyra
• backend: production only
• Developer Access: unavailable and denied

ZYRA Test:
• Flutter flavour: foundertest
• display name: ZYRA Test
• proposed bundle identifier: app.zyraconnect.zyra.test
• backend: separate staging only, with synthetic/test data only
• distribution: Founder-only internal TestFlight, never external or public
• Developer Access: exact Founder UUID plus fresh protected Founder role only

The allowed differences are limited to app identity, compile-time
configuration, backend/environment selection, protected test tooling and the
minimum signing/store metadata those differences require. A product-screen or
feature fork needs a new direct Founder ruling.

Because the feature source is shared, protected tool classes may compile into
both artifacts. The Production/default identity exposes no Developer Access
entry, and the central policy plus every protected leaf denies it at runtime.
The ruled boundary is no reachable/exposed Production route, not a claim that
every tool byte is absent.

============================================================
ACCESS MODEL
============================================================

Developer Access begins only after normal authentication in ZYRA Test and
requires all of the following:

1. the exact foundertest application target;
2. a complete compile-time configuration pinned to the approved staging
   project, never production;
3. an installed iOS bundle identifier/display name matching that compiled
   target before any Supabase initialisation;
4. a successful current Supabase session refresh;
5. the refreshed user UUID byte-matching the separately reviewed exact Founder
   UUID pin supplied by the validated Test configuration; and
6. `app_metadata.zyra_role = founder` on that same refreshed staging Auth
   user.

The UUID and protected role are both mandatory; neither can substitute for the
other. The check repeats at the route and every privileged server boundary.
Removing the role, changing accounts or losing the exact identity denies
access at the next required refresh/check. A refresh failure cannot reuse
stale authority.

Refreshed proof is retained separately for the exact Founder and an exact
seeded persona. Authorisation refresh is single-flight for the same account
and protected-claim identity; an account or relevant-claim switch supersedes
older work, so late results cannot republish a prior principal. The app-wide
developer overlay listens for every Auth event and refreshes again when the
app resumes. `userUpdated` and resume require a real session refresh;
non-refresh events never publish a claim. Starting replacement work clears
proof synchronously. Any transition from previously accepted authority to
denial — including `signedOut` — immediately removes the overlay and schedules
the open guarded surface back through `AuthGate`. An Auth-stream error is the
same fail-closed event: proof and overlay are cleared, the guarded route is
replaced, and only a fixed generic diagnostic is logged.

Never grant access from:
• email text, domain or Google Workspace membership;
• editable `user_metadata`;
• TestFlight group membership;
• Dart build mode, possession of the binary or a local toggle; or
• possession of a seeded-persona credential.

Production denies Developer Access regardless of claim. Missing, misspelled,
mixed or placeholder test configuration fails closed and makes no connection.
There is no runtime backend selector or production fallback.

============================================================
FOUNDER OPERATOR EXCEPTION
============================================================

The authenticated and freshly authorised Founder may enter the ZYRA Test
operator shell without completing member onboarding or identity verification.
This is a non-member staging operator capability, not a member entitlement.
It grants no ordinary account a bypass, cannot reach production and does not
weaken the mandatory verification gate for any member row or product action.

============================================================
TEST ACCOUNTS AND PERSONA SWITCHING
============================================================

Seeded Seeker and Guardian personas remain separate staging Auth users and use
only synthetic/test data. They never become or link to the Founder identity.
An exact compiled UUID, exact fixed email and protected
`app_metadata.zyra_test_persona` value must all agree; an email suffix or
build mode is never enough to expose persona-only controls.
If a pinned UUID/email has a missing or wrong protected persona claim, the
router shows a dedicated identity-blocked surface and never demotes it into an
ordinary member shell.

Founder Test enforces the existing-account verification gate for every
non-Founder session regardless of the Production rollout fuse. An ordinary
non-persona Test member needs canonical `verified`. A pinned synthetic persona
is stricter: app entry and in-app developer capability require the
caller-scoped state to have `result = verified`, duplicate review explicitly
clear (not null), consent granted, exact consent marker
`founder_test_synthetic_idv_fixture_v1`, and non-epoch
`consent_recorded_at`, `updated_at` and `decided_at`. Missing, pending,
retry/review-required, failed, expired, cancelled or production-like consent
state denies. The freshly authorised Founder operator exception is evaluated
before this member gate and remains the only bypass.
For a missing or invalid persona fixture, the gate offers only **Check again**
and **Return to sign in**. It never exposes the real member consent, provider
launch or attempt-deletion flow to manufacture a synthetic state.

The permitted switch flow is:

1. the authorised Founder selects an enumerated persona;
2. a staging-only server action validates the independently exact-pinned
   Founder UUID and freshly checked protected Founder role;
3. the action resolves only a fixed, server-side allowlist of synthetic
   `@zyra.test` identities; and
4. the app establishes the selected test session without embedding or
   exposing a reusable credential.

Neither application binary may contain a shared test password, seeded-account
password, service-role key, OTP, action link or other privileged credential.
No secret or exchange material may be logged, displayed or persisted.
DR-ZYRA-229 permits only the sensitive short-lived, one-use `token_hash`
response over TLS for immediate native `verifyOTP` exchange; it does not
permit embedding credentials or returning access/refresh tokens from the broker.

============================================================
DEVELOPER HOME AND CONTROLS
============================================================

The existing Developer Access home continues to organise:
1. Test Accounts — real staging-backed synthetic personas
2. Test Sign Up — production onboarding logic against a blank staging state
3. Labs — shared app comparisons and controlled scenarios

Developer tools reuse the production components and services they test.
Test-only controls label mock/local state separately from real staging state.
Direct/deep-link access is checked; button visibility is never treated as the
security boundary. The Splash Lab menu and playback leaf each deny direct
unauthorised entry. Opening Developer Access from the overlay first refreshes
the current session; the destination remains covered while it performs its
own asynchronous refresh/recheck and returns to `AuthGate` on denial.

Every onboarding `devPreview` request is normalised through current developer
capability, and Test Sign Up repeats a leaf-route capability check. Supplying a
preview argument never creates authority.

============================================================
IMPLEMENTATION AND LIVE STATUS — 2026-09-12
============================================================

Locally implemented/staged under OA-ZYRA-286:
• a central production/foundertest variant policy;
• separate compile-time Supabase selection with fail-closed staging pins;
• one inert approved-resource pin policy and one executable validator for the
  exact staging reference, URL and public client-key pin, both Google
  clients/native parity, the exact Founder UUID and all four persona UUIDs;
• pre-Supabase iOS bundle/display-name verification that locks a mixed
  native/Dart artifact without making a backend connection;
• exact-Founder-UUID plus successful-refresh protected-role policy;
• mandatory Founder Test member admission, including the stricter synthetic
  persona fixture/duplicate-clear gate for app and in-app tool capability;
• shared-source iOS production/foundertest scheme and configuration scaffold;
• a wired, visibly TEST-marked local icon candidate for foundertest;
• removal of the legacy shared-password sign-in path from the Flutter client
  and plaintext legacy credential literals from retained repository helpers
  and historical records;
• a local/staged persona client and Edge Function source;
• a separate, sentinel-inert persona authorisation/rate-limit SQL package
  outside active migrations;
• a separate, sentinel-inert security overlay for all fifteen legacy
  developer/mock RPCs, also outside active migrations; and
• focused policy/scaffold tests.

The Founder's existing `./run.sh` command now selects a foundertest Profile
build by default and refuses before launch unless its ignored staging public
configuration exists and does not identify Production. `./run.sh release` is
the explicit Production device route. The command spelling is stable; its
safe default is now the isolated Test target requested by the Founder.
Its internal `check-founder-test-config` mode is also the single preflight used
by the governed local Test archive script. It compares every supplied public
resource to the separately reviewed compile-time pins, including the Founder
UUID and four distinct persona UUIDs. All five identity pins are required to
be unique. Those pins are all deliberately unassigned today, so no configured
device/archive path can pass until an exact Founder-approved pin revision is
reviewed.

The Supabase client-key gate admits only the exact approved key. Its permitted
public formats are `sb_publishable_*`, or a legacy JWT whose decoded claims
contain exact `role = anon` and the approved staging project reference. A
secret/service-role key, wrong-reference legacy JWT, malformed value or key
that merely has a plausible shape is rejected. The key is never emitted by
the validator.

Google OAuth selection is also variant-aware locally: Founder Test client IDs
default to empty and explicit Production IDs are refused. The real Test OAuth
clients, redirect/provider configuration and matching ignored local values do
not yet exist and remain live setup work.

`tool/build_founder_test_ipa.sh` is the sole governed staged archive path for
ZYRA Test. It validates the Test configuration, uses the exact foundertest
flavour/Dart config and internal-TestFlight-only export options, and stops
after local IPA export. It never uploads or creates Apple/backend resources;
even local archive execution requires its own exact Founder approval.
Direct Xcode archive is not an alternative: selecting the native scheme alone
does not establish the Dart flavour/define contract and is intentionally
rejected by the native/Dart identity gate when mixed.

An unconfigured or mixed Founder Test artifact stays on the Test lock screen.
A staging-initialisation failure stays on a Test-specific retry screen. Neither
condition falls through to public Welcome, member authentication, mock state
or Production.

The empty staging Supabase project is created and post-verified; its exact
identity and evidence are in the Developer Control handover and message 093.
This does not enable an application connection or a persona.

Still held behind separate exact Founder gates:
• staging schema replay, Auth principal/role assignment, provider settings and
  any Edge Function or migration deployment;
• Apple registration of app.zyraconnect.zyra.test and its App Store Connect
  record;
• signed archive, IPA export and TestFlight upload/distribution.

The current production ZYRA record, backend and build 2 are unchanged. A local
file or passing unit test does not mean the live ZYRA Test channel exists.

The staged persona source currently returns a short-lived, one-use magic-link
token hash directly to the Auth SDK. DR-ZYRA-229 approves that narrow exchange
design. Independent expiry/replay proof and separate deployment GO remain
required before live use. The staged function also remains pinned
to an unassigned project sentinel. Independent exact source pins now cover the
Founder UUID and all four persona UUIDs, but every pin is deliberately
`UNASSIGNED_UNTIL_FOUNDER_APPROVAL`. Runtime environment UUIDs must byte-match
valid assigned pins and remain unique; case or whitespace drift fails closed.
Exact assignment plus client/server parity are still required before
deployment.

Its separate staged database package is outside `supabase/migrations`, has
never been applied, and is deliberately inert through an unassigned project
reference and nil Founder UUID. It re-reads the protected Founder role,
correlates the JWT session ID with `auth.sessions`, checks an explicit
`not_after`, and atomically enforces four requests per minute with a 2.5-second
minimum interval. Its private state and audit counts contain no credential or
session identifier. A separate coarse post-configuration delivery audit records
only minute-bucketed counts for `post_config_denial`, `mint_failed` and
`issued`, with 30-day expiry. It stores no caller, Founder, session, persona,
token, email, IP, payload or raw error. The older `authorized` outcome remains
a pre-mint decision and is not treated as issuance. Failure to record `issued`
withholds the token hash; denial-audit failure still preserves denial.
Failures before runtime configuration is valid are intentionally unaudited.
The public recorder is an exact project/app-guarded, empty-`search_path`
definer callable only by `service_role`; its private table/helper remain
unavailable to that client role.

That `auth.sessions` correlation is defence in depth, not a complete copy of
GoTrue runtime validity: time-box, inactivity and single-session invalidation
are not all guaranteed to remove the row immediately. DR-ZYRA-229 records the
Founder's acceptance of that limitation while retaining fresh server `getUser`,
fresh Admin Founder checks and the database boundary. It does not approve
deployment. The transactional SQL
harness is authored but has not been run against a disposable Supabase-shaped
database.

Before the staged server path consumes a durable rate slot, it validates the
exact, confirmed, unbanned persona target. It then repeats a fresh Admin check
for the exact, confirmed, unbanned Founder immediately before database
authorisation and mint. These local safeguards do not make the function live.
DR-ZYRA-229 resolves the narrow token-return design question. Report 091 records
all eleven Edge policy tests passing with type checking and the SDK-pinned
entrypoint check passing; neither substitutes for live SQL or Auth verification.

The fifteen legacy public developer/mock RPCs also have a separate staged,
unapplied overlay. It preserves their implementations behind a non-exposed
private schema and recreates public wrappers with exact staging project,
authenticated JWT, registered UUID/email/protected-persona-claim and
per-fixture capability checks. The unassigned project sentinel and empty
registry make every wrapper fail closed as filed. Its transactional harness is
authored but unrun; the overlay requires review, disposable replay evidence,
exact pinning and its own Founder apply GO before use.

The retained seed/photo helpers now accept only ephemeral caller-supplied
credentials, refuse Production and remain inert behind an unassigned exact
staging pin. The SQL seed requires both target and password custom settings in
the same open transaction and clears the password setting before row writes;
a session-local or pre-transaction setting is not a supported invocation.
This is local repository hygiene, not proof that any historical live account
credential has been rotated. Live credential status remains unknown and any
rotation/execution requires its own reviewed staging-only plan and Founder GO.

The exact synthetic IDV admission policy is implemented locally, but no
staging fixture state has been approved or seeded. Before any persona is
enabled, the Founder must approve those reviewed synthetic rows and
fixture-only behaviour must be proved. The separate staged RPC overlay does
not gain an invented IDV predicate from this client policy.

============================================================
VERIFICATION BEFORE COMPLETION
============================================================

Completion requires evidence that:
• both apps build from the same feature source and install side by side;
• one ordinary shared change reaches both without copied implementation;
• production denies every Developer Access route and reaches only production;
• Test reaches only the exact staging project and fails closed on mixed pins;
• the exact approved Founder UUID plus fresh protected role succeeds while a
  UUID-only, role-only, null, stale, ordinary, wrong-project, removed-role and
  direct/deep-link case fails;
• same-account duplicate refreshes join one authorisation flight, while an
  account or protected-claim switch supersedes late prior work;
• `userUpdated`, app resume and every other Auth-event class preserve the
  fresh-token rule; proof clears synchronously, and authority loss including
  `signedOut` retracts the overlay and guarded route without waiting for
  unrelated UI activity;
• an Auth-stream error follows the same immediate fail-closed retraction and
  does not log the error object or stack;
• persona selection is exact-allowlisted, synthetic-only and leaks no secret;
• all fifteen developer/mock RPCs deny anon, Production, unregistered callers
  and unregistered affected fixtures after the separately gated overlay;
• only exact-marker, verified, duplicate-clear, consented, timestamped and
  Founder-approved synthetic fixture states can enable a pinned persona, with
  fixture-only behaviour proved;
• sign-out clears refreshed Founder proof before the request and again on
  every completion/failure path;
• retained seed/photo helpers contain no legacy credential literal, accept
  only ephemeral caller input, reject Production and stop while the exact
  staging pin is unassigned;
• the Test app remains Founder-only internal TestFlight; and
• no production data is copied to staging.

This specification authorises no live service mutation, migration, signed
archive or upload. Those actions remain separately and exactly Founder-gated.
