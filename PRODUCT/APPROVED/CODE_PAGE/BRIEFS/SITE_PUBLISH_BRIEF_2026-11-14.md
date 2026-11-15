---
id: DOC-ZYRA-0513
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - publish the ZYRA website (line 108 code-link page and Apple app-link file) by pushing ZYRA/SITE main, then verify the live addresses so line 109 can be built
links: [OA-AIOS-407, DR-ZYRA-352, DOC-ZYRA-0511]
owner: Fable
---

# BRIEF — PUBLISH THE ZYRA WEBSITE (LINE 108) — 14 NOV 2026

**Founder-named task.** Founder 14 Nov: "TAKE OVER MY PC WHERE NECCECERY AND DO THESE ... SO WE CAN GERT LATEST VERSION".
**Founder's Cloudflare check (OA-AIOS-407) done by Fable in his Chrome, 14 Nov:** Cloudflare Pages project `zyra-site`
deploys `main` automatically (build `npm run build`, output `dist`). Live production = commit `d0eacf4`, the same as
`origin/main`; nothing newer was uploaded by hand, so a push cannot replace a manual release. Local `main` is ahead
(line 108 and admin commits). The Cloudflare GitHub app is installed on BLACK-UMBRELLA-GROUP with access to `zyra-site`.
Cloudflare shows a Git-installation warning from the 25 Oct repo move, so the push may not start a build by itself.

| Step | Detail |
|---|---|
| 1 | In `ZYRA/SITE`: `pnpm build` and the route tests (`node scripts/verify-routes.mjs`) pass; `dist/c/index.html` and `dist/.well-known/apple-app-site-association` exist; run `fable_public_check.py` on the files changed since `d0eacf4` |
| 2 | Push `main` to `origin` (core rule 2: normal push, no force) |
| 3 | Wait up to 10 minutes, then check from the Mac: `https://zyraconnect.app/c/` answers 200 HTML; `https://zyraconnect.app/.well-known/apple-app-site-association` answers 200, JSON, no redirect, with `9Y7Z8F36SJ.app.zyraconnect.zyra` |
| 4 | If no new deployment appeared (old page still served): mark this line QUESTION to Fable with "Cloudflare did not build after push" - Fable fixes the Git link in the dashboard with the Founder. Do not upload by any other route, install wrangler, or touch Cloudflare settings |
| 5 | Add **"live 14 Nov"** with both status codes to QUESTIONS row 140, so line 109 can start (Associated Domains is already on, Fable 14 Nov). Task note (under 4 KB): commit pushed, the two URL checks. Mark BUILT only when both URLs pass |

Not in this line: DNS, Cloudflare settings, the app (line 109), any other site change.
