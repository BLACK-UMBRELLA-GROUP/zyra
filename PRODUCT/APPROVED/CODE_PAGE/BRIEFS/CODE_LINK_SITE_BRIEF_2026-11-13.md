---
id: DOC-ZYRA-0511
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 9 V4 website side - the zyraconnect.app/c/ page shown for a shared ZYRA Code link when the app is not installed, and the Apple association file
links: [AD-AIOS-115, DR-ZYRA-231, OA-AIOS-407]
owner: ZYRA chat
---

# BUILD BRIEF — SHARED CODE LINK, WEBSITE (LOCK 9 V4) — 13 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Spec: `CODE_PAGE/RECORD/CODE_PAGE_SPEC_CURRENT_VERSION_V4.md` §0b (the link, the website page, privacy, owners). Reference: prototype V226 (private copy
`BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`) → side list **Shared code link → Website page (no app)**.
Repo: **`ZYRA/SITE` only** — read its `AGENTS.md` and `README.md` first. **Commit, never push, never deploy** (OA-AIOS-407). No app change in this line.

| Step | Detail |
|---|---|
| 1 | New page `src/pages/c.astro` (served at `/c/`), `Base` layout with `noindex={true}`, title "A ZYRA Code was shared with you — ZYRA". Not in `public/sitemap.xml`; `robots.txt` unchanged. Add `<meta name="referrer" content="no-referrer">` on this page |
| 2 | Layout: one centred column (max about 420 wide), the website's own fonts, ivory and gold: ZYRA wordmark linking to `/` · h1 **Someone shared their ZYRA Code with you** · "A code only sends a request. They choose whether to link." · the code on one line in a white tile with a thin gold ring, grouped `ZYRA · 7A2F · 09D4 · B81C · 3E6A · 5F0D` · gold button **Copy code** · "Already have ZYRA? Open the app and enter this code." · divider **NEW TO ZYRA?** · "ZYRA isn’t in the App Store yet." · outline button **Join early access** → `/#early-access`. No site menu; the normal site footer below. **No "Open in ZYRA" button** |
| 3 | Script (first-party, on this page only): read the part after `#`; accept it only if it matches `^ZYRA-[0-9A-F]{4}(-[0-9A-F]{4}){4}$` after upper-casing; show it grouped. **Copy code** copies the plain code and reads **Copied** for 2 seconds (announce it to screen readers). The code is never sent anywhere: no network call, no analytics, no cookie, no storage, never written into a link that leaves the page |
| 4 | No valid code after the `#`: h1 **This link isn’t a ZYRA Code** · "Ask them to share their code again." · the same NEW TO ZYRA? part; no code tile, no Copy button. JavaScript off (`<noscript>`): "Open this link on a phone with ZYRA installed." |
| 5 | This page loads no outside script and none of the site's scripts that read the address. If the site ever adds analytics, it must not run on `/c/` |
| 6 | Apple association file `public/.well-known/apple-app-site-association` (no file extension), exactly: `{"applinks":{"details":[{"appIDs":["<TEAM_ID>.app.zyraconnect.zyra"],"components":[{"/":"/c"},{"/":"/c/"}]}]}}` — `<TEAM_ID>` is the `DEVELOPMENT_TEAM` of the Runner target in `ZYRA/SOURCE/ios/Runner.xcodeproj` (already in the public app repo; Fable confirms it in QUESTIONS 140 before the site goes live). It must be served as `application/json`, status 200, with no redirect (add the header the way the site sets headers; if it has none, `public/_headers`) |
| 7 | Checks: `npm run build` passes; `dist/c/index.html` and `dist/.well-known/apple-app-site-association` exist; open the built page with a valid code, with no code, with a wrong code and with JavaScript off; phone width 375 and a computer width; one h1, buttons labelled, text contrast AA |
| 8 | Task note (include the four page states checked). Commit in `ZYRA/SITE` only — **no push**. Mark the queue line BUILT; going live is Fable's route (QUESTIONS 140) |
