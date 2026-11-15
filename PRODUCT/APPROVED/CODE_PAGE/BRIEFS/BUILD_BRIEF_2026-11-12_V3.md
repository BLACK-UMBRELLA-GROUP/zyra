---
id: DOC-ZYRA-0477
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 9 V3 - refreshed ZYRA Code pages (My code / Their code tabs, Scan in the same style, Get a new code, ZYRA-only scanner, check limits)
links: [AD-AIOS-115, DR-ZYRA-231]
owner: ZYRA chat
---

# BUILD BRIEF — ZYRA CODE PAGES REFRESH (LOCK 9 V3) — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Spec: `CODE_PAGE/RECORD/CODE_PAGE_SPEC_CURRENT_VERSION_V4.md` §0 (LOCK 9 V3, kept in V4) and §0b row "Share message until then (line 105)". Reference: prototype V226 (private copy
`BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`) → Guardian tab → + (Add a Guardian), and Profiles ••• → Scan.
**13 Nov (QUESTIONS 139 answered):** steps 3 and 5 below are exact now. The link itself (website page, opening in the app, Share and QR carrying the link) is **not** this line — it is lines 108 and 109.
Pages: Seeker **Add a Guardian**, Guardian sign-up **Add a Seeker** (same layout, its own title and role words), **Scan**.

| Step | Detail |
|---|---|
| 1 | Header: shared page-title style, left; muted line "A code only sends a request. You choose who joins." (Scan: "Scan or enter their ZYRA Code to find their profile.") |
| 2 | Tabs **My code · Their code** using the existing request tab pills; opens on My code (Scan: no tabs, Their code card only) |
| 3 | **My code** card filling the height: real QR of the member's code (196 pt, white rounded tile, thin gold ring) · grouped code · line · gold **Share my code** — share sheet with exactly this text: `Here’s my ZYRA Code. Enter it in ZYRA to send me a request:` new line, the plain code; subject `My ZYRA Code` (the Founder demo preview keeps its sample wording). The QR carries the plain code · outline **Copy code** (plain code) · text button **Get a new code** → LOCK 28 confirm (spec words) → `zyra_rotate_my_personal_code` → toast |
| 4 | **Their code** card filling the height: 250 pt camera frame — light ivory when off (gold brackets, gold camera icon, "Tap to scan their code"; refused permission: "Camera is off — enter the code below"), live camera with the gold scan line when on; "OR ENTER IT" + existing five boxes + **Check code**; found / sent card (V2) |
| 5 | **Scanner:** accept only a plain ZYRA code (`ZYRA-` then five groups of four `0-9 A-F`). Everything else — every web address included, until line 109 adds the one ZYRA code link — is ignored with "This isn't a ZYRA Code" in the frame for 2 s; never open a URL from a scan |
| 6 | **Check limits:** show "Too many tries. Try again later." when the server refuses for rate limit (QUESTIONS 137); until it exists keep the message wired to the server error |
| 7 | Remove the old dark-brown frame and the three-button row; no empty space at the bottom on 430 × 932 and 375 × 667 |
| 8 | Tests: tabs, QR encodes the code, Get a new code confirm + rotate call, non-ZYRA QR ignored, rate-limit message, found / sent unchanged |
| 9 | Gate: `flutter analyze` clean; no new failures. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
