---
id: DOC-ZYRA-0180
type: HANDOVER
status: CURRENT
feature: GUARDIAN NETWORK
purpose: FEATURE NAME
links: []
owner: ZYRA chat
---

# FEATURE NAME

Guardian Network Profile Viewer

## PROJECT LOCATION

- Major Folder: `01_PAGES/`
- Purpose: Let a Guardian inspect a Network Seeker's permitted profile photos in the established full-screen profile experience.
- Owns: Guardian Network profile-view presentation and its dismissal controls.
- References: Seeker Browser visual conventions, Guardian Network photo visibility, and the shared read-only Seeker profile viewer.
- Referenced By: Guardian Network discovery cards.

## APPROVED SUMMARY

Selecting `View profile` on a Guardian Network discovery card opens a full-screen, edge-to-edge profile viewer instead of a bottom sheet. It uses the same photo treatment, identity position, scrim, and photo navigation conventions as the Seeker Browser.

The viewer can be closed either by swiping down or by selecting the top-left close control. Guardian Network continues to expose only the bounded display identity and photo access already permitted on its discovery card.

The discovery card's `Next` control now sits below the profile actions in the lower thumb zone rather than at the top-right of the card.

## SCRIPT SUMMARY

- Guardian Network reuses `SeekerProfileScreen` with Browser-matched identity layout.
- The shared viewer supports an explicit close control and swipe-down dismissal at the same time when requested by a caller.
- Existing Connections and profile-preview callers retain their previous dismissal configuration.
- The full-screen route is marked as a modal profile inspection surface.
- Provisional Guardian Network data continues to use its privacy-safe full-frame placeholder until real permitted profile photos are supplied by the authoritative service.
- No membership, compatibility, relationship, database, RLS, or photo-visibility authority changed.

## FLOW BLUEPRINT

`Guardian Network card` → `View profile` → `Full-screen profile viewer` → `Swipe down or close`

`Guardian Network card` → `Next` in lower action zone → `Next served family`

## VERIFICATION

- Relevant Flutter tests: 38 passed.
- Flutter analyser: no issues found.
- iOS profile build: succeeded.
- Wireless installation and launch completed on device `00008130-001A2C1E26F8001C`.
- Bundle: `app.zyraconnect.zyra`.
- App binary SHA-256: `09924c514728dcb7d53a3a81312dd1fcc5bcb21e49704965f4b8e44e18042890`.

## APPROVED TO-DO LIST

- Founder visual acceptance on the physical device.
