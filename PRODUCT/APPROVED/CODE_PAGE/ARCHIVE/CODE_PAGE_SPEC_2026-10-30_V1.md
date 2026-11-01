---
id: DOC-ZYRA-0341
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 9 - ZYRA Code page
links: [DOC-ZYRA-0282]
owner: ZYRA chat
---

# CODE PAGE — SPEC — V1 (LOCKED 30 OCT 2026)

Masters (430 × 932 @3x): `../MASTERS/scan__empty.png`, `scan__typing.png`, `scan__found.png`, `add_guardian__normal.png`,
`guardian_signup_add_seeker__normal.png`. One layout for every place a member finds or links someone by ZYRA Code.

| Item | Rule |
|---|---|
| Scan (Profiles ••• → Scan) | Title "Scan"; round person-search icon; "Already know someone?" / "Scan or enter their ZYRA Code to find their profile."; **live camera frame** 250 × 250, radius 26, gold corner brackets, a slow gold scan line, text "Point at their ZYRA Code"; divider "OR ENTER THEIR CODE"; **five code boxes** after a gold "ZYRA" prefix (4 characters each, 58 × 56, radius 12; the box being typed in has a gold border; letters upper-case, letters and numbers only); full-width gold **Check code** button (52 high). No "Enter code" button — the boxes are always visible |
| Typing | One hidden text field drives the boxes; paste fills all five; the camera stays live while typing |
| Found | Below Check code: a card with photo/initial, first name, "Seeker · first name and role only" (today's rule). Not found / errors keep today's messages |
| Add a Guardian (Seeker) and Add a Seeker (Guardian sign-up step) | Centred title; **Your ZYRA Code** card (label, code 20 pt light, "They can send a request. You still choose whether to link.", Copy · QR · Share); divider "OR USE THEIR CODE"; camera frame 190 × 190; divider "OR ENTER IT"; the five boxes; gold Check code. Check code opens today's next step (e.g. the Main Guardian sheet) |
| Camera permission | First use asks through the Phone access pattern (LOCK 12); if refused, the frame shows "Camera is off — enter the code below" and the boxes still work |
| Accessibility | Boxes read as one field "ZYRA Code, 20 characters"; Larger Text: boxes may shrink their letter spacing but never clip; the frame shrinks before the boxes do |
| Not changed | What a code reveals (first name and role only), linking rules, the Main Guardian sheet |
