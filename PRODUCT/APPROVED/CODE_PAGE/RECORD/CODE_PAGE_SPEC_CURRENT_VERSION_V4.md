---
id: DOC-ZYRA-0343
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 9 - ZYRA Code pages (V4 - V3 refresh plus the shared code link - exact zyraconnect.app address, what it opens in the app, the website page when the app is not installed, and who owns each part)
links: [DOC-ZYRA-0282, DR-ZYRA-231, AD-AIOS-115]
owner: ZYRA chat
---

# CODE PAGE — SPEC — V4 (LOCKED 30 OCT 2026 · V3 REFRESH 12 NOV · V4 CODE LINK 13 NOV)

**V4 (13 Nov 06:46–07:05, prototype V225 → V226, QUESTIONS 139):** Codex asked for the exact link. Founder clickables: **"Code after a # (Recommended)"** · **"Show who it is (Recommended)"** · website page **"LOCK it (Recommended)"** · until live **"Send the code as text (Recommended)"**. New §0b; §0 rows *My code* and *Scanner* point to it. V3 is in `../ARCHIVE/CODE_PAGE_SPEC_2026-11-13_V3.md`.

**V3 (12 Nov 21:41–21:55, prototype V223 → V224):** Founder (iPhone, Add a Guardian): "This page now looks outdated and need refreshing" → **"Two tabs"**; asked "what about whole concept, can it be restructured or is code the way? Does qr code pose any security risks?" → ZYRA chat answer (code = request only, first name and role only, 20 random characters; QR = the same code) → clickables **"Get a new code"**, **"Scanner reads ZYRA codes only"**, **"Limit code checks"** (all Recommended). Same pages too: **"Yes always, shouldn’t have to ask"**. §0 replaces the V2 layout rows for these pages; found / sent states and rules are unchanged. V2 is in `../ARCHIVE/CODE_PAGE_SPEC_2026-11-12_V2.md`.

## 0. V3 layout (Add a Guardian · Guardian sign-up Add a Seeker · Profiles ••• → Scan)
| Item | Rule |
|---|---|
| Header | Page title in the shared title style, left (e.g. **Add a Guardian** / **Add a Seeker**), back by swipe / pull-down as every page; muted line under it: **A code only sends a request. You choose who joins.** |
| Tabs | **My code · Their code** — the Journey requests tab pills (two equal). Opens on **My code** |
| My code | One card filling the space to the bottom margin, content centred: QR **196 pt** on a white rounded tile (radius 22, thin gold ring, soft shadow) · the code under it in groups (`ZYRA · XXXX · …`, 16 pt light, letter-spaced) · "They can send a request. You still choose whether to link." · gold **Share my code** (52; message and link in §0b) · outline **Copy code** (always copies the plain code) · small muted text button **Get a new code** |
| Get a new code | LOCK 28 confirm: **Get a new code?** / "Your current code and QR stop working straight away. Anyone you shared it with will need the new one. Requests already sent to you stay." / red **Get new code** / **Keep my code** → toast "New code ready. Your old code no longer works." (server `zyra_rotate_my_personal_code`) |
| Their code | One card filling the space, content centred: camera frame **250 pt** — **light** when the camera is off (ivory fill, gold corner brackets, gold camera icon, "Tap to scan their code"; no dark brown), dark live view with the gold scan line once on; then "OR ENTER IT" and the five boxes + gold **Check code**; found / sent card below (V2 rules). Camera refused: the light frame reads "Camera is off — enter the code below" |
| Scan (Profiles ••• → Scan) | Same as the Their code card (no tabs): title **Scan**, line "Scan or enter their ZYRA Code to find their profile." |
| Scanner | Reads **ZYRA codes only**. Any other QR (a web link, anything else) is ignored and the frame shows "This isn't a ZYRA Code" for 2 s; ZYRA never opens a link from a scanned QR. From queue line 109 the scanner also reads the one ZYRA code link of §0b (it takes the code out of it and never loads the page) |
| Check limits | Too many code checks from one account in an hour → "Too many tries. Try again later." (limit set on the server, Fable — QUESTIONS 137) |


## 0b. The shared code link (V4)
**Why this shape:** the part of a web address after `#` is never sent to a website. So the code never reaches the website, its records or the preview robots of message apps; only the app or the member's own browser ever reads it.

### The link
| Item | Rule |
|---|---|
| Exact address | `https://zyraconnect.app/c/#<CODE>` — for example `https://zyraconnect.app/c/#ZYRA-7A2F-09D4-B81C-3E6A-5F0D` |
| `<CODE>` | The member's ZYRA Code exactly as the server gives it: `ZYRA-` then five groups of four characters `0-9 A-F`, joined by hyphens (`^ZYRA-[0-9A-F]{4}(-[0-9A-F]{4}){4}$`, 29 characters), upper case |
| Nothing else | No name, no account id, no query string (`?…`), no tracking, nothing after the code |
| Reading a link (app and scanner) | Accept only: `https`, host exactly `zyraconnect.app` (no `www`, no other name), path exactly `/c/` or `/c`, no query, and a `#` part that is one valid code (lower-case letters are accepted and made upper case). Anything else is **not** a ZYRA link |
| Where it is used | **Share my code** and the **QR** on My code — from queue line 109, when the website page is live. **Copy code** always copies the plain code |
| Share message, link live | `Here’s my ZYRA Code. Open it in ZYRA to send me a request:` new line, the link. Subject: My ZYRA Code |
| Share message until then (line 105) | `Here’s my ZYRA Code. Enter it in ZYRA to send me a request:` new line, the plain code. The QR carries the plain code; the scanner reads plain codes only |
| New code | Get a new code changes the code, so old links and QRs stop working at the same moment (QUESTIONS 137) |

### What opens in the app (ZYRA installed)
The iPhone opens ZYRA itself from the link (Apple Universal Link for `zyraconnect.app`; no custom `zyra://` address; never a web page inside the app).
| Step | Rule |
|---|---|
| 1 | Not a valid ZYRA link → ZYRA opens as normal with the toast **This isn't a ZYRA Code.** |
| 2 | Signed out, in sign-up, or App lock on → finish that first, then carry on. The code is held in memory for this app session only (never saved, never logged); in the Guardian sign-up it fills the Add a Seeker step |
| 3 | ZYRA checks the code once (it counts as one code check; the LOCK 9 V3 limit message applies) |
| 4 | **Seeker opening a Guardian's code** → Add a Guardian, **Their code** tab, code in the boxes, found card: first name · "Guardian · first name and role only" · gold **Send request** |
| 5 | **Guardian opening a Seeker's code** → Add a Seeker, **Their code** tab, found card: first name · "Seeker · first name and role only" · gold **Send request** |
| 6 | **Seeker opening a Seeker's code** → Scan with its found card (today's Scan result) |
| 7 | Any other case (Guardian + Guardian code, your own code, unknown or replaced code, limit reached) → your Their code page (Seeker: Scan; Guardian: Add a Seeker) with the code in the boxes and today's message for that case |
| 8 | "You are" = the role in use right now; ZYRA never switches role by itself |
| 9 | The page opens on top of wherever the member is; back returns there |
| 10 | **Opening a link never sends, links or saves anything.** Only **Send request** sends (DR-ZYRA-231) |

### The website page (app not installed, or opened on a computer)
Address `https://zyraconnect.app/c/` (`/c` forwards to it; browsers keep the `#` part). Reference: prototype V226, side list **Shared code link → Website page (no app)**. Uses the website's own fonts, ivory and gold; one centred column (max about 420 wide on a computer).
| Part | Words |
|---|---|
| Top | ZYRA wordmark (links to the home page). No site menu; the website's normal footer sits below the column |
| Title | **Someone shared their ZYRA Code with you** |
| Line | A code only sends a request. They choose whether to link. |
| Code | The code on one line in a white tile with a thin gold ring, shown in groups (`ZYRA · 7A2F · 09D4 · B81C · 3E6A · 5F0D`) |
| Button | Gold **Copy code** (copies the plain code; reads **Copied** for 2 seconds) |
| Line | Already have ZYRA? Open the app and enter this code. |
| Divider | NEW TO ZYRA? |
| Until ZYRA is in the App Store | "ZYRA isn’t in the App Store yet." · outline **Join early access** → the early-access form on the home page (`/#early-access`) |
| When ZYRA is in the App Store | The line goes; the button reads **Get ZYRA** and opens ZYRA's App Store page |
| No valid code after the `#` | Title **This link isn’t a ZYRA Code** · "Ask them to share their code again." · the same NEW TO ZYRA? part |
| No "Open in ZYRA" button | When ZYRA is installed the iPhone opens the app from the link itself (Safari also shows its own "Open" bar) |
| Privacy | The page reads the code in the browser only. It is never sent anywhere, never stored (no cookies, no storage), never put in analytics. The page is marked not to be listed by search engines, sends no referrer, loads no outside scripts, and is not in the sitemap. With JavaScript off: "Open this link on a phone with ZYRA installed." |

### Who owns what
| Piece | Owner |
|---|---|
| The link, the app behaviour, the website page and its words | ZYRA chat (this LOCK) |
| Website page `/c/` and the Apple association file in `ZYRA/SITE` | Codex — queue line 108 (commit only) |
| Putting the website live (Shakeel's Cloudflare check, OA-AIOS-407) and the Apple developer setting that lets ZYRA open `zyraconnect.app` links | Fable's release route, with Shakeel — QUESTIONS 140 |
| App: opening the link, scanner reading it, Share and QR switching to it | Codex — queue line 109, after QUESTIONS 140 says the page is live |
| Server | Nothing new (code check and limits already exist — line 106) |
| Android | Not in this LOCK (iPhone and iPad first) |

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

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-11-12 | V3 | Refresh: My code / Their code tabs, big QR, light camera frame, Get a new code, Scan in the same style, ZYRA-only scanner, check limits (Founder 21:41–21:55). V2 archived |
| 2026-11-13 | V4 | The shared code link: `https://zyraconnect.app/c/#<CODE>`, what opens in the app, the website page, owners; Share sends the code as text until the link is live (Founder 06:46–07:05, QUESTIONS 139). V3 archived |
