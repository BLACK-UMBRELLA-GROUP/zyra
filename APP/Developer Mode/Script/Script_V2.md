FEATURE NAME
DEVELOPER MODE

SCRIPT VERSION: V2
STATUS: Approved Specification
SOURCE: Master Script Part 2; ChatGPT UX proposal 2026-07-25
(OA-ZYRA-139); Founder instruction 2026-07-18/19 (Test Accounts
rebuild, see SOURCE/lib/screens/dev/developer_access_screen.dart)

Filing note (2026-07-25) — DR-ZYRA-100: this version corrects V1's
DEVELOPER TESTING section, which used stale terminology (Seeker
Basic/Pro/Premium, Basic/Pro/Premium Guardian) predating the 2026-07-12
tier-naming correction applied everywhere else in the repository
(ZYRA Basic/ZYRA One for Seekers, Standard/Guardian+). It also
did not reflect that Test Accounts were substantially rebuilt in code
on 2026-07-19 (real Supabase-backed accounts, not just UI mock) —
that work predates this filing and was never written back into this
document. This version also adds Test Sign-Up, a new capability from
the same 2026-07-25 proposal. Checked first against Authentication,
Onboarding, and Premium documentation, and against live code
(`developer_access_screen.dart`, `upgrade_screen.dart`) per this
proposal's own "review existing documentation, do not duplicate"
instruction — findings below.

============================================================
DEVELOPER MODE OVERVIEW
============================================================

Developer Mode exists inside the production application.

It is designed for:
• UI testing
• Navigation testing
• Subscription testing
• Guardian testing
• Animation testing
• Feature development

Developer Mode must never become a separate application.
Only one production codebase exists.

============================================================
DEVELOPER MODE NAVIGATION
============================================================

Top Right:
• Back
• Home
• Bell

• Back returns to previous Developer page.
• Home returns to Developer Home.
• Bell uses the production Notification system.
• No duplicate notification implementation.

============================================================
DEVELOPER BUTTON DESIGN
============================================================

Back, Home and Bell share:
• Glassmorphism
• Background Blur
• Rounded Corners
• Border Thickness
• Shadow
• Transparency
• Hover State
• Press Animation
• Visual Weight

All three buttons belong to one visual component family.

============================================================
DEVELOPER TESTING — TWO METHODS (renamed 2026-07-25, was
"DEVELOPER TESTING")
============================================================

Two independent testing methods, per DR-ZYRA-100 — they serve
different purposes and remain separate, per the source proposal's
own instruction:

1. Test Accounts (mostly already built — see below)
2. Test Sign-Up (new)

------------------------------------------------------------
1. TEST ACCOUNTS
------------------------------------------------------------

**Status: mostly already built, 2026-07-19, per direct Founder
request** (`SOURCE/lib/screens/dev/developer_access_screen.dart`).
This section corrects the terminology V1 used and records what
already exists in code, rather than specifying it as new.

Existing presets (real Supabase-backed accounts — real auth session,
real RLS, real profiles/subscriptions rows, not just local mock
state):
• Seeker — ZYRA Basic, male
• Seeker — ZYRA Basic, female
• Seeker — ZYRA One, male
• Seeker — ZYRA One, female
• Guardian (one persona — linked to the female Basic Seeker test account)
• Guardian + Guardian+ (same persona, Guardian+ gate opened via
  a local mock toggle — the entitlement engine has no schema
  representation for Guardian tiers yet, per code comment)

Selecting a preset signs the developer into the corresponding real
account and lands directly on the fully-onboarded Home/WaliHome for
that scenario.

**Gap identified against the 2026-07-25 proposal:** the proposal
asks for a full 4-tier-by-2-gender matrix on both Seeker and Guardian
(8 accounts total: Male/Female × Basic/One, for both account types).
Seeker side already matches this exactly. Guardian side does not — only
one gender (male) and no real tier split exists (Guardian+ is a
mock boolean toggle, not a second seeded account on a distinct plan).
This is a real, additive gap — not a conflict — logged in Approved
Future Work below, since completing it requires Guardian-tier schema
work not yet built (see WALI_ARCHITECTURE_CURRENT_VERSION_V6 for the
Standard Guardian/Guardian+ entitlement model this would need to
plug into).

Known live bug (unresolved, tracked separately): OA-ZYRA-128 — Test
Account profile theme (Blue/Purple, Pink/Purple gradients) not
applying correctly on load. Not addressed by this filing.

------------------------------------------------------------
2. TEST SIGN-UP (new, 2026-07-25, from OA-ZYRA-139)
------------------------------------------------------------

**Status: new — not built.** Distinct from the existing "Jump to
Screen" mechanism (still present, unchanged): Jump to Screen drops
the developer directly into any onboarding chapter or Home on mock
state, for viewing UI without exercising the flow. Test Sign-Up is
the opposite intent — it runs the complete, real onboarding journey
from the very beginning, using real application logic throughout:

• Validation
• Required fields
• Error messages
• Input checking
• Navigation
• Progress tracking
• Conditional questions
• Account creation flow

The goal is not to simulate onboarding — it is to exercise the real
experience a user would have, so validation errors, missing required
fields, invalid inputs, navigation logic, conditional question flow,
and success states can all be verified end-to-end.

**Payment step — important caveat found during filing:** the source
proposal specifies that selecting a ZYRA One account during Test
Sign-Up should "show the normal payment step" with a developer option
to bypass it. Checked against `SOURCE/lib/screens/subscription/
upgrade_screen.dart`: **no real payment processing exists in the
codebase yet** — no App Store/Play Store in-app purchase integration,
no Stripe. The existing upgrade screen is explicitly a mock (code
comment: *"This is a preview build — no payment is actually taken"*)
that flips a local entitlement flag. This means there is currently no
real "normal payment step" for Test Sign-Up to show before bypassing
— today, every path is effectively already a bypass, by necessity,
not by developer choice. This section of the proposal is accurate and
worth keeping as forward-looking spec (once real payment integration
lands, Test Sign-Up should show it and offer a bypass), but is **not
buildable as literally described until real payment integration
exists** — flagged rather than silently treated as ready to build.

============================================================
DEVELOPER IMPLEMENTATION RULES
============================================================

• Developer Mode is used for experimentation.
• Any approved UI improvement must also update the
  production implementation.
• Developer Mode must never permanently diverge from
  production.
• Production remains the single source of truth.
• Whenever a feature is improved in Developer Mode and
  approved, update the production implementation.

============================================================
DEVELOPER DESIGN PRINCIPLE
============================================================

Developer Mode is a protected development layer.

It exists only to:
• Test
• Iterate
• Validate

The project always consists of:
• One Database
• One Backend
• One Frontend
• One Production Codebase

Developer Mode simply unlocks additional functionality
for Admin users.

============================================================
DEVELOPER MODE SECTION (PRODUCTION PAGES)
============================================================

Every production page Summary includes a DEVELOPER MODE
section at the bottom where applicable.

Standard format:

🔵 DEVELOPER ONLY  — visible to Admin only
⚪ PRODUCTION      — visible to all users

Developer features are always a superset of production.
Developer features never override or break production features.
Conflicts between developer and production must be flagged
and resolved before either is implemented.

============================================================
APPROVED FUTURE WORK
============================================================

• Complete the Guardian side of Test Accounts to match the Seeker
  side's full gender × tier matrix (Female Guardian persona; a real
  Standard/Guardian+ tier split rather than a mock toggle) —
  depends on Guardian-tier entitlement schema work not yet built.
• Build Test Sign-Up (this filing is specification only).
• Wire Test Sign-Up's payment step to real payment integration once
  that exists; until then, it necessarily remains a full bypass.
• Fix OA-ZYRA-128 (Test Account theme/gradient bug).
