FEATURE NAME
DEVELOPER MODE

SCRIPT VERSION: V3
STATUS: Approved Specification — CURRENT
DATE: 2026-08-20
SUPERSEDES: Script_V2.md
GOVERNING REFERENCES: DR-013; DR-ZYRA-087; DR-ZYRA-210;
ZYRA_SETTINGS_AND_IDENTITY

============================================================
PURPOSE
============================================================

Developer Mode is a protected layer inside the production codebase for:
• UI and navigation testing
• real-backend/RLS scenario testing
• onboarding testing
• subscription and Guardian-state testing
• animation and component labs

It is not a separate app and never changes production rules to make a test
easier. One frontend, one backend and one product model remain authoritative.

============================================================
ACCESS MODEL
============================================================

Developer Access is available only after normal authentication when:

1. the Supabase session carries a protected server-issued `founder` or
   `developer` role for the exact account; and
2. the app is a non-release build.

The Founder uses the existing Continue with Google button with the approved
Google Workspace account. ZYRA adds no public developer login option.

Never grant access from:
• the Google Workspace domain or email suffix;
• a client-side email comparison;
• editable `user_metadata`;
• a local toggle; or
• possession of a seeded persona password.

Developer Access is not reachable from Welcome before authentication. Every
developer screen, overlay and server action checks authorisation itself and
fails closed. Release builds expose none of them, including for the Founder.

============================================================
DEVELOPER HOME
============================================================

The Developer Access home answers one question first:

  Which experience do you want to test?

Sections:
1. Test Accounts — real backend
2. Test Sign Up — real onboarding questions from a blank test state
3. Labs — app-level comparisons and animation experiments

Membership, Journey states and page-specific scenarios are changed from the
in-app developer panel after entry. Developer tools use the production
components and services they are intended to test.

============================================================
TEST ACCOUNTS
============================================================

The seeded personas remain separate Supabase `@zyra.test` accounts:
• male Seeker
• female Seeker
• male Guardian
• female Guardian

They exercise real sessions, profiles, RLS and backend paths. Local state is
used only where the product still has no persisted equivalent.

The authorised Founder/developer account is the operator, not one of these
personas, and no persona identity is linked to the Founder Google identity.

Target switch flow:

1. authorised operator selects a persona;
2. a protected server-mediated developer action verifies the caller's signed
   role, non-release/dev environment and the persona's `@zyra.test` address;
3. the action returns/establishes only the selected test session; and
4. AuthGate/SessionRouter routes from the persona's real profile row.

The current embedded shared password and direct password sign-in are
technical debt. Remove them only after the protected server-mediated switch
is implemented and proven. Password auth remains non-public throughout.

============================================================
TEST SIGN UP
============================================================

Test Sign Up runs the production onboarding journey from a blank test state:
• validation
• required fields
• error messages
• progress and backward navigation
• conditional questions
• profile completion

There is no invented mid-onboarding tier picker. New accounts start on Basic
and upgrade afterwards, matching production. A real payment bypass is not
specified until a real payment integration exists.

============================================================
IMPLEMENTATION RULES
============================================================

• Developer Mode is a superset of production, never a divergent product.
• Approved improvements update the production implementation where relevant.
• Test controls must label mock/local state separately from real backend
  state.
• Server-mediated developer actions default-deny and keep explicit test-data
  guards.
• The app binary contains no shared developer/test password after OA-ZYRA-245
  closes.
• Tokens, provider credentials, service-role keys and one-time codes are
  never logged or documented.
• Direct/deep-link access is tested; button visibility alone is insufficient.
• No database migration is authorised by this specification.

============================================================
LIVE PREREQUISITES
============================================================

• Real Google OAuth web/iOS client configuration
• Google provider enabled in Supabase with correct redirects
• Exact Founder Supabase user created by real Google sign-in
• Protected role assigned from a trusted server/operator context
• Token/session refresh after role assignment and removal
• Protected server-mediated persona switch
• Allowed-account, denied-account, release-build and deep-link evidence

Until these exist, the design is approved but the upgraded Developer Access
capability is not complete. Tracked by OA-ZYRA-245.
