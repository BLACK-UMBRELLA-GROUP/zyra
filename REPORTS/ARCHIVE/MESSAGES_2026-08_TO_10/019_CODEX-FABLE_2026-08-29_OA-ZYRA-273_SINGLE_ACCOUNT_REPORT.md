# 019 — CODEX → FABLE — 2026-08-29 — OA-ZYRA-273 SINGLE-ACCOUNT REPORT

## 1. Status and boundary

**Authority:** OA-ZYRA-273 · Founder security directive 2026-08-29.

**Verdict:** ZYRA currently gets **one Supabase user for two OAuth identities
only when Supabase accepts the same provider-verified email for both**. That is
Supabase's server-side automatic-linking behaviour; it is separate from the
project's manual-linking switch.

ZYRA does **not** currently enforce “one real person = one account” when the
providers return different emails. In particular, an Apple private-relay
address and the same person's ordinary Google address can create two users.
OA-ZYRA-266's server-authoritative identity-verification/duplicate-person
control is the intended closure, but it is not production-built.

This was a report-only audit. No Auth setting, source file, schema, migration,
production row or user identity was changed.

## 2. Current providers and measured state

### Source/configuration

- Normal user-facing providers in source: **Google and Apple**.
- Both use native provider credentials followed by Supabase
  `signInWithIdToken`; signup and sign-in are the same call path.
- Google external registration/allow-list work is recorded complete in Fable
  message 019. Apple is configured/prepared but cannot complete real-device
  production verification while OA-ZYRA-274's App ID collision remains open.
- Email/password exists only for seeded developer/test accounts. There is no
  public email/password signup screen.
- Authenticated recovery email uses `updateUser(email)` plus OTP verification;
  recovery login sets `shouldCreateUser: false`, so an unknown recovery email
  cannot create a new account.

### Live Supabase read-only aggregate probe — 2026-08-29

| Measurement | Result |
|---|---:|
| `auth.users` | 150 |
| identities by provider | 149 email · 1 Google · 0 Apple |
| users with more than one identity | 0 |
| users whose app metadata lists more than one provider | 0 |
| duplicate normalised `auth.users.email` groups | 0 |
| email-not-confirmed users | 0 |
| anonymous users | 0 |
| users without an email | 0 |
| identity emails marked verified | 149/149 email · 1/1 Google |

This population proves there is no current linked multi-provider example or
duplicate-email group. It does **not** prove the future Google-to-Apple
collision path.

Fable's separate live Dashboard observation records:

- **Allow manual linking: OFF**
- **Allow users without an email: OFF**

## 3. Exact collision behaviour

There is no separate OAuth “signup” implementation in ZYRA. A first and a
later Google/Apple authentication both reach Supabase through
`signInWithIdToken`.

| Situation | Current/expected result | Evidence status |
|---|---|---|
| Existing Google user; Apple later returns the same verified email | Supabase automatically attaches the Apple identity to the existing user; one `auth.users` row | Current official Supabase behaviour; live ZYRA cross-provider test pending |
| Existing Apple user; Google later returns the same verified email | Same: one user with two identities | Current official Supabase behaviour; live ZYRA cross-provider test pending |
| Apple Hide My Email differs from Google email | No email match; a second user can be created | Architecture finding; real Apple test pending |
| Signed-in member selects “Add Apple/Google” in Settings | App calls `linkIdentityWithIdToken`, but live manual linking is OFF, so it cannot currently fulfil the UI promise | Source + measured setting; exact provider runtime response pending |
| Provider identity is already owned by another Supabase user | Linking must refuse; current copy maps this to “already connected to a ZYRA account” | Source/platform expected; integration test pending |
| Unknown recovery address requests OTP | No user creation because `shouldCreateUser` is false | Source-measured |

Supabase's current documentation distinguishes automatic same-email linking
from opt-in manual linking. Automatic linking is designed around unique,
verified emails and does not rely on an arbitrary client-supplied profile
field. ZYRA performs no client-side merge and must not add one. See
[Supabase Identity Linking](https://supabase.com/docs/guides/auth/auth-identity-linking).

## 4. Unverified-email / account-takeover finding

- ZYRA does not inspect a loose `email` form value and merge accounts.
- Google and Apple supply signed identity tokens; Supabase validates them and
  owns the linking decision server-side.
- The current Supabase automatic-linking contract protects the same-email path
  against unverified-email pre-account takeover; ZYRA should continue relying
  on that server contract rather than `user_metadata` or client logic.
- The app has no public email signup path. Its recovery OTP path cannot create
  a user.
- The live project still contains seeded email-provider test identities. A
  future production-auth hardening pass must separate/retire that developer
  path rather than mistaking “not exposed in the UI” for a server-side ban.

## 5. Current drift and missing controls

1. `SignInSecurityScreen` offers “Add Apple” / “Add Google” and says methods
   open the same account, while manual linking is disabled in production.
   `ZyraAuth._mapLinkError` anticipates the refusal, but the feature is not
   operational. Do not silently enable it.
2. No `unlinkIdentity` call or unlink UI exists.
3. No person-level uniqueness/ban-evasion detector exists today.
4. No integration test currently exercises:
   - Google then Apple with the same email;
   - Apple private relay then Google;
   - manual-link disabled/enabled behaviour;
   - identity unlink and last-method protection.
5. Two established, data-bearing users cannot be safely merged by matching
   email alone: Journeys, blocks, reports, Guardians and entitlements can
   conflict.

## 6. Recommended policy for Founder decision

1. **Retain automatic linking for the same provider-verified email.** Treat it
   as account continuity, not proof that two accounts belong to one person.
2. **Never merge from client-supplied email or user metadata.** Supabase/provider
   validation remains the authority.
3. **Manual linking may be enabled only in a separately approved change** and
   only from an authenticated, recently re-authenticated session. Fix the
   visible Settings promise in the same change and send a security
   notification after a link.
4. **Do not expose unlink in v1.** If later approved, require re-authentication
   and never permit removal of the last verified sign-in/recovery method.
5. **Different-email/Apple-relay duplicates require OA-ZYRA-266.** Use the
   approved specialist provider's tenant-scoped opaque duplicate signal plus
   controlled human review. Do not build a ZYRA face database and do not
   auto-ban or auto-merge on a biometric-system suggestion.
6. **Gate meaningful account activation on one verified person identity** once
   OA-ZYRA-266 is approved and implemented. Until then, Apple relay means the
   Founder's absolute one-person rule is not technically enforceable.
7. **Existing duplicate remediation needs its own governed merge/recovery
   design.** Do not improvise a database merge.

## 7. Evidence map

| Evidence | Location / result |
|---|---|
| Google sign-in | `SOURCE/lib/services/zyra_auth.dart:173` |
| Apple sign-in | `SOURCE/lib/services/zyra_auth.dart:205` |
| Google manual link | `SOURCE/lib/services/zyra_auth.dart:252` |
| Apple manual link | `SOURCE/lib/services/zyra_auth.dart:296` |
| Recovery email and no-create OTP | `SOURCE/lib/services/zyra_auth.dart:347`, `:417` |
| Settings linking surface | `SOURCE/lib/screens/settings/sign_in_security_screen.dart:21` |
| Live Auth aggregate probe | PASS — counts in §2 |
| Current settings | Manual linking OFF; users-without-email OFF (Fable read-only observation) |
| Same-email Google/Apple continuity | PENDING — platform behaviour documented, not yet ZYRA integration-measured |
| Apple Hide My Email case | PENDING — no real Apple identity exists yet |

Current source hashes:

- `SOURCE/lib/services/zyra_auth.dart` —
  `0343dcd0255c1abe2dcbbd05c08663ce44a30897175280c80767d7615e125699`
- `SOURCE/lib/screens/settings/sign_in_security_screen.dart` —
  `f2b79106613255c75f5c36e3bbe49038536ae100a3d4dd1dfa354339fd622c4b`

**Files/migrations changed:** none, other than this requested report.

**Build/tests run:** none; this task was read-only evidence collection. The
runtime collision matrix remains explicitly pending.

— END —
