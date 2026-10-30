---
id: TBC (Fable assigns)
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 9 - ZYRA Code page (V2 - what Check code leads to on Add a Guardian / Add a Seeker)
links: [DOC-ZYRA-0282, DR-ZYRA-231, AD-AIOS-115]
owner: ZYRA chat
---

# CODE PAGE — SPEC — V2 (LOCKED 30 OCT 2026)

V1 is in `../ARCHIVE/CODE_PAGE_SPEC_2026-10-30_V1.md`. **What changed:** V1 said Check code on Add a Guardian opens "today's next
step (e.g. the Main Guardian sheet)". That was wrong and contradicted DR-ZYRA-231 (a code never creates a link). Queue line 24
stopped on it. V2 draws the real next step: found card → **Send request** → **Request sent**. Nothing else changes.

Masters (430 × 932 @3x) in `../MASTERS/`: `scan__empty`, `scan__typing`, `scan__found`, `add_guardian__normal`,
`guardian_signup_add_seeker__normal` (V1, unchanged) and **new** `add_guardian__found`, `add_guardian__sent`,
`guardian_signup_add_seeker__found`, `guardian_signup_add_seeker__sent`.

| Item | Rule |
|---|---|
| Scan (Profiles ••• → Scan) | Title "Scan"; round person-search icon; "Already know someone?" / "Scan or enter their ZYRA Code to find their profile."; **live camera frame** 250 × 250, radius 26, gold corner brackets, a slow gold scan line, text "Point at their ZYRA Code"; divider "OR ENTER THEIR CODE"; **five code boxes** after a gold "ZYRA" prefix (4 characters each, 58 × 56, radius 12; the box being typed in has a gold border; letters upper-case, letters and numbers only); full-width gold **Check code** button (52 high). No "Enter code" button — the boxes are always visible |
| Typing | One hidden text field drives the boxes; paste fills all five; the camera stays live while typing. Check code with fewer than 20 characters: toast "Enter all 20 characters." |
| Scan — found | Below Check code: a card with initial (or photo), first name, "Seeker · first name and role only". Not found / errors keep today's messages |
| Add a Guardian (Seeker) and Add a Seeker (Guardian sign-up step) | Centred title; **Your ZYRA Code** card (label, code 20 pt light, "They can send a request. You still choose whether to link.", Copy · QR · Share); divider "OR USE THEIR CODE"; camera frame 190 × 190; divider "OR ENTER IT"; the five boxes; gold Check code |
| **Add a … — found** (new) | Check code shows a card under the button: initial, first name, "Guardian · first name and role only" (Add a Guardian) or "Seeker · first name and role only" (Add a Seeker), and a full-width gold **Send request** (52 high) inside the card. The page scrolls to show it |
| **Add a … — sent** (new) | Send request turns the card into: gold "Request sent" under the role line, and "<Name> chooses whether to link. You'll see them in Guardians once they accept." (Add a Seeker: "…in Seekers…"). No sheet opens. The Main Guardian sheet only appears later, when a request is **accepted** (existing first-link event, LOCK 2 §2.4, server work OA-ZYRA-317) |
| Founder preview behaviour | Local only: Check code shows the found card; Send request shows the sent state; nothing is sent or linked, no invitation is created. Names in the masters (Yusuf, Hassan, Adam) are samples: show whichever sample the code resolves to in the preview's existing sample namespaces (DRAFT/DEMO); unknown codes use today's not-found message |
| Camera permission | First use asks through the Phone access pattern (LOCK 12); if refused, the frame shows "Camera is off — enter the code below" and the boxes still work |
| Accessibility | Boxes read as one field "ZYRA Code, 20 characters"; Larger Text: boxes may shrink their letter spacing but never clip; the frame shrinks before the boxes do |
| Not changed | What a code reveals (first name and role only); linking rules (a code sends a request, the other person accepts — DR-ZYRA-231); the Main Guardian sheet and the Make Main action |
