---
id: DOC-ZYRA-0181
type: HANDOVER
status: CURRENT
feature: GUARDIAN NETWORK
purpose: FEATURE NAME
links: []
owner: ZYRA chat
---

# FEATURE NAME

Guardian Network Request Page

## PROJECT LOCATION

- Major Folder: `01_PAGES/`
- Purpose: Provide a dedicated Guardian Network surface for reviewing and sending a request to another Main Guardian.
- Owns: Request-page presentation, dismissal behaviour, and the handoff to the existing request action.
- References: Guardian Network discovery, Guardian relationship roles, and request-state authority.
- Referenced By: Guardian Network `Speak to Guardian` action.

## APPROVED SUMMARY

Selecting `Speak to Guardian` opens a dedicated full-screen modal page instead of a bottom sheet. The page can be dismissed through either the top-left close control or a downward swipe.

The first version intentionally preserves the existing concise request question and send action. Additional Guardian details and request context will be selected after Founder review of the physical page.

## SCRIPT SUMMARY

- Replaced the request bottom sheet with a full-screen modal route.
- Added a shared-page gradient, centred Guardian identity treatment, lower primary action, top-left close control, swipe handle, and interactive downward dismissal.
- A completed downward drag dismisses the route; an incomplete drag animates back into place.
- `Send request` continues to call the existing Guardian Network analytics, stage transition, and advance behaviour.
- No additional profile data, database fields, request authority, membership rules, or compatibility data were introduced.

## FLOW BLUEPRINT

`Guardian Network card` → `Speak to Guardian` → `Guardian request page`

From the request page:

- `Send request` → existing request stage transition → return to Network.
- `X`, `Not yet`, or swipe down → return to Network without sending.

## VERIFICATION

- Guardian Network Flutter tests: 12 passed.
- Flutter analyser: no issues found.
- iOS profile build: succeeded.
- Wireless installation and launch completed on device `00008130-001A2C1E26F8001C`.
- Bundle: `app.zyraconnect.zyra`.
- App binary SHA-256: `35bff31e14df61c1e6972b47254fee7eed7ed166baa7a08a778de24b388da32c`.

## APPROVED TO-DO LIST

- Founder review of the first full-screen layout.
- Decide which additional Guardian and request details belong on this page.
