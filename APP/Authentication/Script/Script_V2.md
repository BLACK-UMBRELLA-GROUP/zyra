FEATURE NAME
AUTHENTICATION

SCRIPT VERSION: V2
STATUS: Superseded 2026-09-12 by Script_V3.md
DATE: 2026-08-20
SUPERSEDES: Script_V1.md
GOVERNING REFERENCES: ZYRA_SETTINGS_AND_IDENTITY; DR-ZYRA-209;
DR-ZYRA-210

SUPERSESSION NOTE (2026-09-12): DR-ZYRA-228 replaces this version's
non-release-only Developer Access rule with the isolated Founder-only ZYRA Test
target. OA-ZYRA-286, not OA-ZYRA-245, is the canonical implementation action.
Public member authentication remains unchanged. This file is historical.

============================================================
WELCOME SCREEN
============================================================

The Welcome Screen is the public entry point to ZYRA.

Display:
• ZYRA
• Connecting Through Trust
• Continue with Apple
• Continue with Google
• Use recovery email

Apple and Google are the only normal public account-creation and sign-in
methods. The platform-native provider leads visually. Sign-up and sign-in
are one provider action: a first-time account enters onboarding; an existing
account resumes its normal destination.

There is no ZYRA password and no public email or phone sign-up.

“Use recovery email” is shown only as a passwordless recovery route for an
address previously verified from inside an Apple/Google account. Recovery
uses a six-digit one-time code, sets `shouldCreateUser: false`, returns
neutral copy for unknown addresses and never creates a new profile.

There is no public Founder, staff, admin or Developer Access sign-in button.

============================================================
LINKED SIGN-IN METHODS
============================================================

From Sign-in & security, an authenticated member may:
• link Apple to an existing Google account;
• link Google to an existing Apple account; and
• add or change a verified recovery email.

All methods remain attached to the same Supabase user id. ZYRA never links
or merges accounts from matching email text alone. If an identity belongs to
another account, the link is refused and handled through support.

Provider identity, recovery email and contact/notification email are three
different concepts and must be labelled separately.

============================================================
FOUNDER / DEVELOPER AUTHORISATION
============================================================

The Founder uses Continue with Google with the approved Google Workspace
account. The exact Supabase user receives a protected `founder`/`developer`
role in server-controlled `app_metadata` or an equivalent signed custom
claim.

The Workspace domain is not authority. Email suffixes, client booleans and
editable user metadata never unlock Developer Access.

After normal authentication:
• exact protected role + non-release build → Developer Access available;
• ordinary Google account → normal onboarding/home;
• release build → Developer Access unavailable for every account.

Every developer destination repeats the protected authorisation check.
Developer Access is never pre-authentication.

============================================================
LIVE CONFIGURATION GATE
============================================================

Before Google sign-in is described as working:
• real Google web and iOS OAuth clients exist;
• local non-committed client ids are not placeholders;
• Google provider and redirect configuration are enabled in Supabase;
• the exact Founder account has signed in once and received the protected
  server-issued role; and
• allowed, denied and release-build routes are tested.

Apple requires its own provider configuration. Linked identities require
manual identity linking. Recovery requires token-bearing OTP/email-change
templates, Secure Email Change, SMTP, expiry and rate-limit configuration.

No database migration is authorised by this specification.

============================================================
SECURITY RULES
============================================================

• Protected authorisation is server-controlled and default-deny.
• No credential, OAuth secret, service-role key, password or one-time code is
  stored in source or documentation.
• Unknown accounts receive neutral responses.
• A hidden button is not an authorisation boundary.
• Release and server checks are both required.
• Removing the protected role removes access after session refresh.

============================================================
DEVELOPER PERSONAS
============================================================

Seeded Seeker and Guardian personas remain separate `@zyra.test` identities.
The Founder account operates the developer tool; it does not become or link
to a persona.

Persona switching must move to a protected server-mediated action that
keeps the `@zyra.test` guard and does not embed a shared password in the app
binary. The current shared-password flow is technical debt and remains open
under OA-ZYRA-286 until replaced and proven.
