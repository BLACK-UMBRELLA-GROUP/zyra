# ZYRA — Settings & Identity

**Status:** CURRENT_VERSION — APPROVED by Founder, 2026-08-20
**Version:** V2
**Date:** 2026-08-20
**Owner:** Founder
**Documentation Owner:** Fable
**Supersedes:** `ZYRA_SETTINGS_AND_IDENTITY_2026-08-20_V1.md`
**Governing references:** ZYRA_GOVERNANCE; DR-ZYRA-209; DR-ZYRA-210;
ZYRA_ENGINEERING_INVARIANTS

---

## What changed from V1

V1 stated that ZYRA had no account recovery, could not change the account
email, and should not invent either. The Founder changed that position on
2026-08-20 after reviewing a passwordless design. V2 now separates three
different things that V1 treated as one:

1. a provider identity used to sign in;
2. a private recovery email used for one-time-code recovery; and
3. a contact or notification email, which is not an authentication factor.

V2 also records the Founder-approved Developer Access upgrade: the
Founder's Google Workspace identity uses the existing Google button and is
authorised by a protected, exact-account role. There is no third public
sign-in option and no domain-wide trust.

The identity-freeze, Identity Correction and App Lock decisions from V1
remain unchanged.

---

## 1. Identity principles

1. **Identity becomes trusted at first publication.** Before publication it
   is a draft and freely correctable. Afterwards other people may rely on it.
2. **Publication state and identity state are independent.** A member may
   withdraw their profile without reopening frozen identity fields.
3. **A member may always withdraw.** Leaving never becomes a route to assume
   a different identity.
4. **Frozen-field corrections use the Identity Correction process.** They
   are never ordinary profile edits.
5. **Every write path enforces the same rule.** Client convention is not a
   security boundary.
6. **Authentication identity and product persona are separate.** A real
   Founder account does not become Adam, Maryam or another seeded persona.

---

## 2. Profile identity fields

| Field | Rule | Enforcement |
|---|---|---|
| First name | Editable permanently; trim and 1–60 character limit on every write path | Column grant, constraint and trim trigger |
| Surname line | Editable | Column grant; length limit remains unresolved |
| Bio | Editable | Column grant; product limit is governed by onboarding decisions |
| Date of birth | Frozen at first publication | No client column grant plus `first_published_at`; correction only through §6 |
| Gender | Frozen at first publication | No client column grant plus `first_published_at`; correction only through §6 |
| Product role/persona | Never changed by an ordinary profile edit | Server-authorised account/persona flow |

Name-change history remains deliberately deferred until identity
verification exists. A verification system must define what is verified and
what happens when a verified fact changes before any badge is shown.

---

## 3. Authentication account model

### 3.1 One account, multiple verified ways in

One Supabase `auth.users.id` is the account principal. Apple, Google and a
verified recovery-email identity may be attached to that same principal.
Linking another identity must preserve the existing user id, profile,
Guardians, Journey history and entitlements.

**Never merge or link accounts merely because two providers return the same
email address.** Provider subject identifiers are the durable identity.
Email is a mutable provider claim and is not sufficient proof that two
accounts are the same person.

### 3.2 Public entry

- **Continue with Apple** and **Continue with Google** remain the only normal
  public sign-in and sign-up methods.
- A first provider sign-in creates the auth principal and routes incomplete
  accounts into onboarding.
- There is no ZYRA password.
- `Use recovery email` is a recovery path for an address verified from
  inside an existing Apple/Google account. It is not open email sign-up and
  is not a third account-creation method.
- Recovery-code requests must use `shouldCreateUser: false`, return neutral
  copy for unknown addresses and never create a profile from a typo.

### 3.3 Linking a second provider

Apple or Google may be added as another way into the current ZYRA account
only from an authenticated session using the provider's native proof and
Supabase identity linking. A normal sign-in operation must never be
substituted for linking because it may switch to another account.

Manual identity linking must be enabled in Supabase before this works. If a
provider identity is already attached to another ZYRA account, linking is
refused and routed to support; profiles are not silently merged.

### 3.4 Recovery email

- A recovery address is private authentication data, not profile data.
- Adding or changing it requires an authenticated Apple/Google session and
  verification of the new address.
- Secure Email Change remains enabled. Where Supabase requires confirmation
  at both addresses, both confirmations must complete.
- Recovery sign-in uses a six-digit one-time code and creates no password.
- Changing a contact/notification email does not change a sign-in identity.
- Removing the last usable sign-in identity is prohibited. No unlink UI is
  approved in this version.

### 3.5 Sign-in & security presentation

Settings shows the connected providers and addresses honestly. Apple relay
addresses receive the relay explanation. Recovery email is labelled as
recovery, not as the member's Google/Apple account or contact address.
Unknown providers are logged and displayed as an integration problem rather
than disguised as “Your provider”.

---

## 4. Founder and Developer Access

### 4.1 Entry and authorisation

The Founder signs in through the existing **Continue with Google** button
using the approved Google Workspace account. ZYRA does not add a Founder,
staff, admin or developer button to the public authentication choices.

Access is granted only when all of these are true:

1. Google has authenticated the account;
2. the resulting Supabase user carries a protected `founder` or `developer`
   authorisation in server-controlled `app_metadata` or an equivalent
   signed custom claim;
3. the exact account is allowlisted and the claim is current; and
4. the build is non-release and Developer Access is compiled/routed for that
   environment.

The Workspace domain is **not** authority. `@zyra…` ownership, a matching
email suffix, email text in `user_metadata`, or a client-side boolean must
never unlock Developer Access. A future employee using the same domain is an
ordinary user unless their exact account is deliberately authorised.

### 4.2 Routing

- An authorised Founder account enters the normal authenticated router and
  may then open Developer Access in a non-release build.
- Ordinary Google users follow normal onboarding/home routing.
- Developer Access is never reachable before authentication.
- Release builds expose no Developer Access route, control, overlay or
  scenario-switch action, even for the Founder role.
- Every developer destination checks the protected role again. Hiding a
  button is not authorisation.
- Role removal takes effect on token refresh/re-authentication and must
  fail closed when claim state cannot be verified.

### 4.3 Seeded personas

Adam, Maryam and the Guardian test personas remain separate Supabase test
identities. The Founder account is the authorised operator, not a persona.

The target switch flow is a protected server-mediated action that is callable
only from an authorised non-release Founder/developer session, preserves the
existing `@zyra.test` guard and issues the selected persona session without
placing a shared password in the application binary.

The current embedded `_testPassword` plus direct
`signInWithPassword` flow is recorded technical debt. It must be removed
after the protected replacement is proven; seeded accounts are not linked to
the Founder Google identity and are deleted before any real launch.

---

## 5. Security and privacy invariants

1. Privileged authorisation lives in protected server-controlled metadata or
   a signed server-issued claim, never editable user metadata.
2. Access is exact-account and default-deny; email-domain membership alone
   never grants privilege.
3. Authentication failures use neutral copy and do not disclose whether an
   address is registered or privileged.
4. Logs may record user id, provider subject and decision outcome; they must
   not print tokens, OAuth credentials, one-time codes or service-role keys.
5. A client release guard and a server authorisation check are both required.
   Neither substitutes for the other.
6. No secret, password, client secret or service-role key is committed to
   source or written into governed documentation.
7. No database migration is authorised by this decision. The approved
   app-metadata/custom-claim design does not require one. A database-backed
   role table would be a different architecture and needs explicit Founder
   migration authorisation before any SQL is authored or run.

---

## 6. Identity Correction — approved, not yet built

Frozen fields are never directly editable. The approved process remains:

1. member requests an identity correction;
2. selects date of birth or gender;
3. provides a reason and required evidence;
4. support reviews; and
5. an authorised operator performs and records an approved correction.

The unresolved questions remain: who performs the operator action, what
evidence is sufficient, what response time/copy is promised, and whether a
correction is reversible. This process must not be exposed until somebody
can action its queue.

---

## 7. App Lock and approved Settings scope

App Lock remains a flagship privacy control. It uses the device biometric or
device passcode, stores no ZYRA PIN, obscures app-switcher snapshots, locks on
pause/hidden lifecycle states, and always permits Sign out instead.

| Settings item | Decision |
|---|---|
| Notifications | Five ZYRA categories; OS permission first requested at the first Journey; no feature gated behind permission |
| Language | Deferred until a second language exists; Arabic/Urdu require right-to-left layout planning |
| Restore Purchases | Required with real in-app purchases; not a standalone fiction before IAP exists |
| Contact blocking | Deferred; reference-code blocking before address-book access |
| Manage Account | Take a break; Reset profile; I'm getting married; Delete profile; Delete account |
| Sign-in & security | Connected Apple/Google identities, recovery email, provider-specific explanation and no-password statement |

---

## 8. Current implementation state and prerequisites

### Built locally, not yet proven live

The app source contains Apple/Google identity linking, recovery-email setup,
passwordless recovery and the updated Sign-in & security screens. Their live
operation depends on Supabase provider and email-template configuration and
must not be described as production-ready until exercised against the real
project.

### Developer Access upgrade — approved, not yet implemented

Current source still has a pre-authentication Developer Access button in
non-release builds and an embedded shared test password. That is the old
architecture, not the approved target in §4. Implementation is tracked by
OA-ZYRA-245.

### Live configuration prerequisites and blockers

1. Create/configure the real Google OAuth web and iOS clients for ZYRA's
   actual identifiers and authorised redirect URI.
2. Replace the placeholder Google client ids in the local, non-committed
   OAuth configuration.
3. Enable Google in Supabase Auth and supply the matching client credentials.
4. Enable Apple separately before claiming the public Apple button works.
5. Enable manual identity linking before offering linked Apple/Google backup
   sign-in.
6. Configure recovery and secure-email-change templates to deliver the
   one-time token, plus SMTP, expiry and rate limits suitable for production.
7. Assign the protected Founder/developer claim to the exact verified
   Supabase user from a trusted server/operator context, then refresh the
   session and verify both allowed and denied accounts.
8. Build a protected server-mediated persona switch before deleting the old
   shared-password flow.

Evidence reported to Documentation Owner on 2026-08-20: the live public
Supabase auth settings had email enabled and both Apple and Google disabled;
the local Google OAuth file still held placeholder client ids. No claim is
made here that provider credentials, callback configuration, manual linking,
email templates or the protected role are configured.

---

## 9. Evidence required before completion

- Authorised Founder Google account signs in through the ordinary Google
  button and reaches Developer Access only in a non-release build.
- A second Google Workspace user and a non-Workspace Google user both route
  normally and cannot open any developer destination.
- The same Founder account on a release build has no developer route.
- Direct/deep-link attempts to every developer destination fail without the
  protected claim.
- Role removal plus token refresh removes access.
- Scenario switching succeeds without any shared password in the binary and
  continues to enforce the `@zyra.test` persona guard.
- Recovery and provider-linking tests prove the Supabase user id does not
  change and unknown recovery emails cannot create accounts.
- `flutter analyze`, the relevant Flutter tests and `tools/zyra_check.py`
  pass after implementation.

Until this evidence exists, the architecture is approved and documented but
the capability is not complete.

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-07 | Identity freeze, Identity Correction, Settings decisions, provider/email presentation and App Lock. |
| V2 | 2026-08-20 | Passwordless recovery and linked identities; exact-account Google Workspace Founder authorisation; Developer Access moved behind authentication and protected non-release routing; live prerequisites and evidence gates recorded. |
