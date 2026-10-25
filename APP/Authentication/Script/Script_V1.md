---
id: DOC-ZYRA-0001
type: SPEC
status: SUPERSEDED
feature: APP: AUTHENTICATION
purpose: Authentication / Script — Script V1
links: []
owner: ZYRA chat
---

FEATURE NAME
AUTHENTICATION

SCRIPT VERSION: V1
STATUS: Approved Specification — PARTIALLY STALE, see note
SOURCE: Master Script Part 2

STATUS NOTE (2026-07-19): the Buttons list below (Begin Your
Journey / I Already Have An Account, Email/Phone/Google/Apple
sign-up methods) predates the 2026-07-18 Founder instruction
that reworked Welcome Screen to Google + Apple sign-in ONLY —
no password, no email, no phone, no magic link, no separate
sign-up/sign-in fork (see SOURCE/lib/screens/welcome_screen.dart
header comment). This section was not rewritten as part of
today's filing pass — flagging the staleness rather than
silently leaving it undocumented. Separately, DR-ZYRA-088
(2026-07-19, PROPOSED/not ratified) made three further
refinements on top of the current Google/Apple-only build:
wordmark letter-spacing widened for a more premium feel,
tightened vertical spacing (less empty space between logo,
slogan, and buttons), and platform-native sign-in button
priority — Apple shown as the larger/primary button on iOS,
Google larger/primary elsewhere, rather than a fixed order.

============================================================
WELCOME SCREEN
============================================================

The Welcome Screen is the entry point to ZYRA.

Display:
• ZYRA
• Premium minimalist branding
• Purple brand background
• Clean luxury spacing

Buttons:
1. Developer Access
2. Begin Your Journey
3. I Already Have An Account

Every button must perform a navigation action.
No dead buttons.

============================================================
STANDARD USER FLOW
============================================================

------------------------------------------------------------
BEGIN YOUR JOURNEY
------------------------------------------------------------

Display sign up methods:
• Email
• Phone
• Google
• Apple

Flow: Role Selection → Onboarding → Home

------------------------------------------------------------
I ALREADY HAVE AN ACCOUNT
------------------------------------------------------------

Display sign in methods:
• Email
• Phone
• Google
• Apple

Flow: → Home

============================================================
ADMIN PERMISSION SYSTEM
============================================================

Every account stores a role.

Roles:
• User
• Guardian
• Admin

Default Roles:
• New Seeker → User
• New Guardian   → Guardian
• Owner      → Admin (manually assigned in database)

------------------------------------------------------------
DEVELOPER BUTTON VISIBILITY
------------------------------------------------------------

| Role  | Developer Button |
|-------|-----------------|
| Admin | Visible         |
| User  | Hidden          |
| Guardian  | Hidden          |

Developer tools must never be visible to non-admin users.

------------------------------------------------------------
DEVELOPER PAGE SECURITY
------------------------------------------------------------

Every Developer page verifies: role == Admin

If verification fails:
Access Denied → Redirect → Home

Developer URLs must never be accessible by non-admin users.
