---
id: DOC-ZYRA-0512
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 9 V4 app side - ZYRA opens the shared code link, the scanner reads it, and Share and the QR carry it
links: [AD-AIOS-115, DR-ZYRA-231]
owner: ZYRA chat
---

# BUILD BRIEF — SHARED CODE LINK, APP (LOCK 9 V4) — 13 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Spec: `CODE_PAGE/RECORD/CODE_PAGE_SPEC_CURRENT_VERSION_V4.md` §0b (The link · What opens in the app). Reference: prototype V226 (private copy
`BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`).

| Step | Detail |
|---|---|
| 1 | **Build only after** lines 105 and 108 are BUILT **and** Fable's note in QUESTIONS 140 says the website page and the Apple setting are live. If not, mark this line QUESTION and stop — do not ship Share or QR links that open nothing |
| 2 | iPhone and iPad: add Associated Domains `applinks:zyraconnect.app` to the Runner entitlements. **No custom address scheme** (`zyra://`). Never show the website inside the app |
| 3 | One small parser used everywhere (link opening and scanner): returns the code, or nothing. Accept only `https`, host exactly `zyraconnect.app`, path exactly `/c/` or `/c`, no query, and a `#` part matching `^ZYRA-[0-9A-F]{4}(-[0-9A-F]{4}){4}$` after upper-casing. Everything else is not a ZYRA link |
| 4 | **Opening a link:** follow spec rows 1–10 exactly — toast "This isn't a ZYRA Code." for a bad link; finish sign-in, sign-up or App lock first and carry on (code in memory for this session only, never saved, never logged; in the Guardian sign-up it fills Add a Seeker); one code check; then Seeker + Guardian code → Add a Guardian, Their code, found card; Guardian + Seeker code → Add a Seeker, Their code, found card; Seeker + Seeker code → Scan found card; every other case → the member's Their code page with the code in the boxes and today's message. Role = the role in use now; never switch role. Opens on top; back returns. **Nothing is sent, linked or saved until Send request is tapped** |
| 4b | **One code check for a link (Fable 14 Nov; spec §0b steps 3-7).** New migration `public.zyra_resolve_code_link(p_code text)` returning one row `(outcome text, owner_first_name text, owner_role text, owner_age int, owner_location text)`; owner rights, `search_path = ''`, EXECUTE for `authenticated` only. Order: not signed in / identity check → the same errors as today; then the **same shared limit charged once** (same lock, counters and `too_many_code_checks` as line 106); look the code up in any role; `outcome` = **`add_guardian`** (caller Seeker, owner Guardian) or **`add_seeker`** (caller Guardian, owner Seeker), both with exactly today's `zyra_preview_personal_code` eligibility, first name and role only; **`scan`** (Seeker and Seeker) with exactly today's `zyra_preview_match_code` eligibility, first name, age, location; **`own_code`** (caller's own code, no names); **`unavailable`** for everything else (unknown or replaced code, Guardian + Guardian, blocked or not eligible - never says which). Write exactly one attempt row (`succeeded` true only for the three found outcomes). Move the two eligibility rules and the limit charge into private helpers used by all three functions, so the rules cannot drift; the two existing previews keep their signatures and behaviour. App: a link uses only this function; route `add_guardian`/`add_seeker`/`scan` to steps 4-6, and `own_code`, `unavailable` and the limit error to step 7. Server tests on throw-away Postgres 17: each outcome; one attempt row per call; limit reached; anon refused; Q152 guards still hold. **No live apply** (with the rest, OA-ZYRA-317); line 110's clean baseline must include this migration. |
| 5 | **Scanner:** also accepts the link through the same parser (takes the code out; never loads the page); every other web address is still "This isn't a ZYRA Code" |
| 6 | **Share my code:** `Here’s my ZYRA Code. Open it in ZYRA to send me a request:` new line, `https://zyraconnect.app/c/#<CODE>`; subject `My ZYRA Code`. **QR** carries the same link. **Copy code** stays the plain code. The Founder demo preview keeps its sample wording and never produces a working link |
| 7 | Tests — parser accepts: the exact link, `/c#…`, lower-case code. Rejects: `http`, `www.zyraconnect.app`, any other host (including `zyraconnect.app.example.com`, and an address that puts `zyraconnect.app` as a user name before an at-sign in front of another host), look-alike letters, another path, any query, text after the code, an encoded `%23`, wrong length, letters outside `0-9 A-F`. Routing: each row of step 4, signed-out carry-on, limit reached, own code. The code never appears in logs, analytics or storage |
| 8 | **(14 Nov: the iPhone install moves to line 117, DOC-ZYRA-0514; do the link checks there.)** iPhone, on Shakeel's GO (protected route, tell him the build first): tap a real link in Messages → ZYRA opens on the found card; scan the new QR with the iPhone Camera and with ZYRA's scanner. **Confirm the `#` part reaches the app.** If iOS or the plugin drops it, stop and file a QUESTIONS row — do not move the code into the address path |
| 9 | Gate: `flutter analyze` clean; no new failures. Any new package is named in the task note with why. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
