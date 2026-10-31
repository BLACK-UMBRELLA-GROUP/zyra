---
id: DOC-ZYRA-0323
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 7 - the Profiles request row (one pill with Previous, Request a Journey, Next)
links: [DR-ZYRA-276, DOC-ZYRA-0282]
owner: ZYRA chat
---

# REQUEST ROW — SPEC — V1 (LOCKED 29 OCT 2026)

Masters (430 × 932 @3x): `../MASTERS/request_row__not_requested.png`, `request_row__sent.png`, `request_row__first_profile.png`.

| Item | Rule (logical points) |
|---|---|
| Shape | **One pill**, full width of the card (same side margins as the card), height **56**, fully rounded, glass fill as today's pills |
| Border | Gold at 60% while not requested; full journey gold once the request is sent |
| Left section | Previous: **68 wide**, gold chevron (about 24 high), tap area the full 68 × 56 |
| Middle | "Request a Journey" (white, 14) — tap sends the request as today. After sending: "**Request sent**" in gold; tapping again keeps today's behaviour (undo before it is seen, per LOCK 2) |
| Right section | Next: **68 wide**, gold chevron, tap area 68 × 56 |
| Dividers | A thin glass-border line, **28 high**, centred, between each section |
| First profile | Previous chevron faded (white at about 28%) and does nothing; VoiceOver says "Previous profile, unavailable" |
| Other labels | Any other label the row shows today (e.g. "Journey archived", other Journey states) keeps its wording and sits in the middle section |
| Accessibility | Three separate buttons for screen readers, labels unchanged ("Previous profile · no decision", the request label, "Next profile · no decision"); each tap area at least 44 high |
| Where | Seeker Profiles tab only (the Details-first card, LOCK 4). Guardian Network keeps its own row |
