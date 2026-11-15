---
id: DOC-ZYRA-0323
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 7 - the Profiles Request a Journey button (inside the card, under the tiles) and swipe to change profile
links: [DR-ZYRA-276, DOC-ZYRA-0282]
owner: ZYRA chat
---

# REQUEST ROW — SPEC — V4 (LOCKED 29 OCT 2026, LARGER TEXT RULE 30 OCT, SENT RING 11 NOV, BUTTON IN CARD + SWIPE 11 NOV)

**V4 replaces the pill.** The masters in `../MASTERS/` show the old ‹ · Request · › pill and are **out of date** — the reference is the prototype copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V194.html` (Seeker → Profiles; Seeker Basic for the back pop-up). Rows marked "(V1–V3, replaced)" are kept for history only.

| Item (V4) | Rule (logical points) |
|---|---|
| Founder | 11 Nov: "make the request button be below the 4 boxes and user can swipe left right to view profile - seeker basic cant if he goes left to go back a pop up shows to upgrade"; placement answer "only on the first page ie the profile card" (prototype V178 → V179) |
| Button | **"Request a Journey"**, one full-width button **inside the profile card**, directly under the four tiles, **12** above it, same side padding as the tiles. Height **52**, fully rounded, 1 pt border journey gold at 60 % (`#A9792E` 60 %), fill `#FBF7F0`, text 15 regular in the body text colour, soft shadow (0 6 16, 8 %) |
| Sent | Label **"Request sent"**, text `#845F24` medium, border full `#A9792E`. Tap again keeps today's behaviour (undo before it is seen, LOCK 2). The V3 sent ring + breathing glow on the card stays |
| Only on the first page | The button shows **only on the first page of the card** (photo, name, four tiles). The photo pages (tap the card to see photos) show **no** button |
| Previous / Next | The ‹ › pill and the separate arrows are **removed**. Change profile by **swiping the card** left (next) or right (previous) with the shared swipe (LOCK 26, `APP_SWIPE/RECORD/APP_SWIPE_SPEC_CURRENT_VERSION_V1.md`): the neighbour card follows the finger, 24 pt gap, 0.24 s settle, spring back on short drags, 30 % resistance at the ends, a swipe never fires a tap. The page dots under the title follow |
| Seeker Basic going back | Seeker Basic sees each profile once. A swipe **back** meets resistance and springs back (no previous card), and once the drag passes about 18 pt a bottom sheet opens: lock icon in a thin gold ring, title **"Going back comes with Seeker One"**, text **"Seeker Basic shows each profile once. With Seeker One you can swipe back and look again at up to 10 profiles you passed."**, gold **See Seeker One** (opens the Seeker One upgrade page, LOCK 25) and **Not now** (closes). Swiping forward works as normal. Seeker One: back works up to 10 passed profiles (Seeker One upgrade page row "Look again at declined profiles") |
| Space | Under the card: 16 to the tab bar (LOCK 24) — no button and no gap below the card |
| Accessibility | VoiceOver: the button keeps its label; the card offers "Next profile" and "Previous profile" actions (Seeker Basic previous opens the sheet); Reduce Motion: swipe changes instantly |
| Larger Text | The button grows taller and the label wraps; never clip |

## Earlier rows (V1–V3, replaced by V4 where they conflict)


| Item (V1–V3) | Rule (logical points) |
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
| **Card ring after sending (V3)** | Founder 11 Nov: the 5 pt ring is "too thick and maybe it lack animation" → clickable **"B · Thin + slow glow"** (prototype V149). Once the request is sent, the profile card shows a **1.5 pt journey-gold ring** (`#A9792E`, solid) on its edge, following the card radius, plus a **soft gold glow inside the card edge** (`#E8C98A`, about 26 pt blur, 3 pt spread) that **breathes**: 0 → 50 % opacity and back over **3.2 s**, ease-in-out, repeating while the request stays sent. Ring fades in over 260 ms on send and out over 180 ms on undo. Reduce Motion or accessible navigation on: thin ring only, no breathing glow. Replaces today's 5 pt ring at 65 %. No pictures (charter rule 13): the prototype is the reference |
| Where | Seeker Profiles tab only (the Details-first card, LOCK 4). Guardian Network keeps its own row |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-11-11 | V4 | Pill removed: "Request a Journey" button inside the card under the tiles, first page only; swipe the card to change profile (LOCK 26); Seeker Basic back → "Going back comes with Seeker One" sheet. V3 archived in ARCHIVE/ |
| 2026-10-29 | V1 | LOCKed (LOCK_RECORD.md) |
| 2026-11-11 | V3 | Sent ring: 1.5 pt gold ring + slow breathing inner glow (Founder "B · Thin + slow glow"). V2 archived in ARCHIVE/ |
| 2026-10-30 | V2 | Larger Text rule after Codex's preflight (line 16 FAILED: label 259 pt at 200% text, middle 252 pt). Founder: "Pill grows taller (Recommended)". V1 archived in ARCHIVE/ |
