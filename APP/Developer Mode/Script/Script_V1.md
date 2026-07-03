FEATURE NAME
DEVELOPER MODE

SCRIPT VERSION: V1
STATUS: Approved Specification
SOURCE: Master Script Part 2

============================================================
DEVELOPER MODE OVERVIEW
============================================================

Developer Mode exists inside the production application.

It is designed for:
• UI testing
• Navigation testing
• Subscription testing
• Wali testing
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
DEVELOPER TESTING
============================================================

Test accounts:

Male Seeker:
• Basic
• Pro
• Premium

Female Seeker:
• Basic
• Pro
• Premium

Test every combination with:
• No Wali
• Basic Wali
• Pro Wali
• Premium Wali

Future subscription combinations should be added without
changing the production architecture.

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
