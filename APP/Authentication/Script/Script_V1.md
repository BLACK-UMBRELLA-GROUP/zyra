FEATURE NAME
AUTHENTICATION

SCRIPT VERSION: V1
STATUS: Approved Specification
SOURCE: Master Script Part 2

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
• Wali
• Admin

Default Roles:
• New Seeker → User
• New Wali   → Wali
• Owner      → Admin (manually assigned in database)

------------------------------------------------------------
DEVELOPER BUTTON VISIBILITY
------------------------------------------------------------

| Role  | Developer Button |
|-------|-----------------|
| Admin | Visible         |
| User  | Hidden          |
| Wali  | Hidden          |

Developer tools must never be visible to non-admin users.

------------------------------------------------------------
DEVELOPER PAGE SECURITY
------------------------------------------------------------

Every Developer page verifies: role == Admin

If verification fails:
Access Denied → Redirect → Home

Developer URLs must never be accessible by non-admin users.
