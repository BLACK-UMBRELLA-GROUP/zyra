---
id: DOC-ZYRA-0343
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 9 - ZYRA Code pages (V3 - refreshed Add a Guardian / Add a Seeker as My code / Their code tabs, Scan in the same style, Get a new code, scanner and check limits)
links: [DOC-ZYRA-0282, DR-ZYRA-231, AD-AIOS-115]
owner: ZYRA chat
---

# CODE PAGE — SPEC — V3 (LOCKED 30 OCT 2026 · V3 REFRESH 12 NOV)

**V3 (12 Nov 21:41–21:55, prototype V223 → V224):** Founder (iPhone, Add a Guardian): "This page now looks outdated and need refreshing" → **"Two tabs"**; asked "what about whole concept, can it be restructured or is code the way? Does qr code pose any security risks?" → ZYRA chat answer (code = request only, first name and role only, 20 random characters; QR = the same code) → clickables **"Get a new code"**, **"Scanner reads ZYRA codes only"**, **"Limit code checks"** (all Recommended). Same pages too: **"Yes always, shouldn’t have to ask"**. §0 replaces the V2 layout rows for these pages; found / sent states and rules are unchanged. V2 is in `../ARCHIVE/CODE_PAGE_SPEC_2026-11-12_V2.md`.

## 0. V3 layout (Add a Guardian · Guardian sign-up Add a Seeker · Profiles ••• → Scan)
| Item | Rule |
|---|---|
| Header | Page title in the shared title style, left (e.g. **Add a Guardian** / **Add a Seeker**), back by swipe / pull-down as every page; muted line under it: **A code only sends a request. You choose who joins.** |
| Tabs | **My code · Their code** — the Journey requests tab pills (two equal). Opens on **My code** |
| My code | One card filling the space to the bottom margin, content centred: QR **196 pt** on a white rounded tile (radius 22, thin gold ring, soft shadow) · the code under it in groups (`ZYRA · XXXX · …`, 16 pt light, letter-spaced) · "They can send a request. You still choose whether to link." · gold **Share my code** (52) · outline **Copy code** · small muted text button **Get a new code** |
| Get a new code | LOCK 28 confirm: **Get a new code?** / "Your current code and QR stop working straight away. Anyone you shared it with will need the new one. Requests already sent to you stay." / red **Get new code** / **Keep my code** → toast "New code ready. Your old code no longer works." (server `zyra_rotate_my_personal_code`) |
| Their code | One card filling the space, content centred: camera frame **250 pt** — **light** when the camera is off (ivory fill, gold corner brackets, gold camera icon, "Tap to scan their code"; no dark brown), dark live view with the gold scan line once on; then "OR ENTER IT" and the five boxes + gold **Check code**; found / sent card below (V2 rules). Camera refused: the light frame reads "Camera is off — enter the code below" |
| Scan (Profiles ••• → Scan) | Same as the Their code card (no tabs): title **Scan**, line "Scan or enter their ZYRA Code to find their profile." |
| Scanner | Reads **ZYRA codes only**. Any other QR (a web link, anything else) is ignored and the frame shows "This isn't a ZYRA Code" for 2 s; ZYRA never opens a link from a scanned QR. A shared ZYRA link opens only the app or zyraconnect.app |
| Check limits | Too many code checks from one account in an hour → "Too many tries. Try again later." (limit set on the server, Fable — QUESTIONS 137) |


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
| 2026-11-12 | V3 | Refresh: My code / Their code tabs, big QR, light camera frame, Get a new code, Scan in the same style, ZYRA-only scanner, check limits (Founder 21:41–21:55). V2 archived |
