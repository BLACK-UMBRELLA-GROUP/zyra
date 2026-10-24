# FEATURE NAME

Guardian Network Modes

## PROJECT LOCATION

- Major Folder: `02_NAVIGATION/`
- Purpose: Separate Network discovery from sent and received requests while keeping Seeker context clear.
- Owns: Guardian Network mode navigation, header-level Seeker selection, and the Seeker picker presentation.
- References: Guardian Network request stages, linked Seekers, shared ZYRA sheet styling, and Guardian relationship authority.
- Referenced By: Guardian Network discovery and request-management surfaces.

## APPROVED SUMMARY

Guardian Network has three horizontally swipeable modes: `Browser`, `Sent requests`, and `Received`. The selected Seeker appears in the main page header opposite `Network`.

Selecting the Seeker name now opens a rounded ZYRA sheet instead of the platform's rectangular popup menu. Each Seeker is presented as a clean person row with an initial, name, and a restrained gold selected state.

Families with sent or received requests remain excluded from Browser and appear only in their relevant request mode. Received-request connection uses the current gold-accent action treatment.

## SCRIPT SUMMARY

- Replaced `PopupMenuButton` with a transparent modal host and `GNSheetShell`.
- The picker uses rounded ZYRA surfaces, circular initials, app spacing, and a gold selected border/check.
- Selecting a row closes the sheet and writes the shared `GNContext`.
- Header placement, mode swipe, request isolation, and request-stage authority remain unchanged.
- No database, RLS, membership, compatibility, or production-service changes were made.

## FLOW BLUEPRINT

`Network header` → selected Seeker name → ZYRA Seeker sheet → choose Seeker → all modes update

`Network` → swipe/tap `Browser` | `Sent requests` | `Received`

## VERIFICATION

- Guardian Network Flutter tests: 14 passed.
- Flutter analyser: no issues found.
- iOS profile build: succeeded.
- Wireless installation and launch completed on device `00008130-001A2C1E26F8001C`.
- Bundle: `app.zyraconnect.zyra`.
- App binary SHA-256: `2b402fc31147bf9a5b5b32133130b8420ad0e8a3711dae6bfa978f283a2262b3`.

## APPROVED TO-DO LIST

- Founder visual review of the ZYRA Seeker selection sheet.
