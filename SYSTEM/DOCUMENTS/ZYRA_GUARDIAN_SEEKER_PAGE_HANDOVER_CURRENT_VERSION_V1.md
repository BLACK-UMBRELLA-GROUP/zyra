---
id: DOC-ZYRA-0192
type: HANDOVER
status: CURRENT
feature: GUARDIAN NETWORK
purpose: FEATURE NAME
links: []
owner: ZYRA chat
---

# FEATURE NAME

> **Scoped Seeker-side permission amendment — 2026-10-20 / OA-ZYRA-305:**
> Founder confirms Basic Additional Guardians have optional View and no Chat
> column. Paid Additional Guardians have fixed View/Chat only for new Journeys
> after explicit Seeker agreement; existing Journeys are not retroactively shared.
> Capability Grant Rules V7's controlling amendment owns this product direction.
> The protected draft model validates the exact current paid Additional roster
> before Begin, records pair evidence only on deliberate agreement, rejects
> changes to agreed fixed grants, and invalidates evidence on downgrade, unlink,
> end, replacement and reset. Upgrade alone never restores old chat permission.
> Known Basic pages omit Chat entirely; empty slots remain unticked/disabled.
> A constructor-only DTO marker is not parsed from undeployed server fields.
> Real entitlement proof, both-participant disclosure/consent and attempt-bound
> server/RLS enforcement remain HELD under OA-ZYRA-296/305. No schema or backend
> operation occurred. The current packet is
> `SYSTEM/RESOURCES/REVIEWS/OA305_MY_ZYRA_ACTIVITY_2026_10_20.PrA0zH/`;
> its verification and separate delivery state supersede no historical device
> receipt below. Current source is not a new iPhone installation.

Guardian Seeker Page

## PROJECT LOCATION

- Major Folder: `01_PAGES/`
- Purpose: Present each linked Seeker as a full Guardian-facing workspace.
- Owns: Guardian-side Seeker page presentation, horizontal person navigation, and embedded quiet sections.
- References: Guardian relationship authority, Journey summaries, Family Messages, Guardian Network, and shared profile imagery.
- Referenced By: Guardian navigation and Guardian account experiences.

## APPROVED SUMMARY

The Guardian `Seekers` page follows the same interaction model as the Seeker `Guardian` page. Each linked Seeker occupies one full page. Guardians move between linked Seekers by swiping horizontally; page dots communicate position.

The previous roster-card screen and tap-through intermediate workspace are removed from the primary flow. The header and add action remain available. Existing empty, loading, error, Main Guardian, Additional Guardian, Journey, Family Messages, and Guardian Network truth remain authoritative.

## SCRIPT SUMMARY

- `GuardianSeekerRosterView` flattens authorised linked-Seeker groups into one ordered page collection.
- A horizontal `PageView` renders one Seeker workspace per page and preserves the selected Seeker by identifier when data refreshes.
- Each production page embeds `WaliSeekerWorkspaceScreen` without its standalone scaffold or back control.
- Embedded presentation uses quiet, border-light sections for identity, details, Journey access, Journey summary, Family Messages, and Guardian Network.
- A bottom fade and compact page dots provide a clean transition into the persistent navigation bar.
- The existing standalone workspace mode remains available for compatibility, but the Guardian `Seekers` tab no longer requires a card tap or intermediate route.
- No database schema, migration, RLS, identity, membership, or relationship-authority changes were made.

## FLOW BLUEPRINT

`Guardian navigation` → `Seekers` → `Full-page linked Seeker` ↔ `Swipe to another linked Seeker`

Within each Seeker page, authorised actions continue to open the existing Journey, Family Messages, and Guardian Network destinations.

## VERIFICATION

- Focused Flutter tests: 19 passed.
- Flutter analyser: no issues found.
- iOS profile build: succeeded.
- Wireless device deployment: installed and launched on device `00008130-001A2C1E26F8001C`.
- Bundle: `app.zyraconnect.zyra`.
- App binary SHA-256: `d50f94b9aba8664b269214046a3962471ab1ea26c9ede869297d512a55d8ed8d`.

## APPROVED TO-DO LIST

- Founder visual acceptance on the physical device.
