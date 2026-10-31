---
id: DOC-ZYRA-0323
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 7 - the Profiles request row (one pill with Previous, Request a Journey, Next)
links: [DR-ZYRA-276, DOC-ZYRA-0282]
owner: ZYRA chat
---

# REQUEST ROW — SPEC — V2 (LOCKED 29 OCT 2026, LARGER TEXT RULE 30 OCT)

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
| **Larger Text** (Founder 30 Oct: "Pill grows taller") | When the label does not fit on one line at the member's text size, it wraps onto **two lines** (centred) and the pill grows taller to fit, minimum 56; the arrow sections keep their **68** width and stay vertically centred. The row height stays the same whichever label is shown at that text size (sized for the longest label, e.g. "Request a Journey"). Never shrink, clip or cut off the text |
| Where | Seeker Profiles tab only (the Details-first card, LOCK 4). Guardian Network keeps its own row |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-29 | V1 | LOCKed (LOCK_RECORD.md) |
| 2026-10-30 | V2 | Larger Text rule after Codex's preflight (line 16 FAILED: label 259 pt at 200% text, middle 252 pt). Founder: "Pill grows taller (Recommended)". V1 archived in ARCHIVE/ |
