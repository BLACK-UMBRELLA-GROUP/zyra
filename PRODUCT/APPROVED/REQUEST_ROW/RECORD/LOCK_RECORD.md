---
id: DOC-ZYRA-0322
type: DECISION
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: LOCK record for LOCK 7 - the Profiles request row - one pill holding Previous, Request a Journey and Next (option A4)
links: [AD-AIOS-115, DR-ZYRA-276]
owner: ZYRA chat
---

# LOCK RECORD — REQUEST ROW

| Date | Founder's words | What it locks |
|---|---|---|
| 2026-10-29 (comments on the prototype's request row) | Asked for ways to make the Previous / Request a Journey / Next row better; liked the arrow pill and the round button; asked for 5 options of each | Ten options shown (A1–A5 arrow pill, B1–B5 round button), prototype V34 |
| 2026-10-29 19:23 | "i dont mind a4 but would like arrow sections maybe a little larger" | A4 with larger arrow sections (prototype V37) |
| 2026-10-29 19:37 | "always once i confirm somethgin remove optoins. in this case i mean arrow pill and rount button from prototype" | Other options removed (V38) |
| 2026-10-29 19:45 | Question "Should I LOCK it so Codex builds it into the app?" → **"LOCK A4"** | **LOCK** of `RECORD/REQUEST_ROW_SPEC_CURRENT_VERSION_V1.md` and `MASTERS/` (prototype V39) |

Replaces today's three separate pills (‹ · Request a Journey · ›) under the Profiles card.
| 2026-10-30 06:2x | Codex's preflight: "Request a Journey" does not fit at very large text. Question → **"Pill grows taller (Recommended)"** | Spec **V2** (Larger Text row). Masters unchanged |

Pictures showing sample photos moved to the private group folder 9 Nov 2026 (OA-AIOS-430); recaptured with placeholders when ZYRA restarts.
| 2026-11-11 13:48 | "the gold ring around profile card - i dunno i dont like it too much maybe its too thick and maybe it lack animation- show me some solutions in prototype" → prototype V147–V149 (Today / A thin + light sweep / B thin + slow glow / C draws itself) → clickable **"B · Thin + slow glow"** | **LOCK 7 V3**: sent ring 1.5 pt gold + breathing inner glow 3.2 s; static under Reduce Motion. Spec `REQUEST_ROW_SPEC_CURRENT_VERSION_V3.md`; built by queue line 77 step 5d |
| 2026-11-11 20:1x | "make the request button be below the 4 boxes and user can swipe left right to view profile - seeker basic cant if he goes left to go back a pop up shows to upgrade" → prototype V178 (A inside the card / B under the card) → answer "but only on the first page ie the profiel card" → V179. Basic back pop-up question not answered: kept as shown (assumption told to the Founder) | **LOCK 7 V4**: ‹ › pill removed; button in the card under the tiles, first page only; swipe changes profile (LOCK 26); Seeker Basic back → upgrade sheet. Spec `REQUEST_ROW_SPEC_CURRENT_VERSION_V4.md`; built by queue line 81 step 1f |
