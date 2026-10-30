---
id: DOC-ZYRA-0328
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - export the Founder preview (the planned app, sample data only) as a private static web copy the ZYRA chat publishes for the Founder to tap through. Gated on Fable's safety check
links: [DR-ZYRA-279, DR-ZYRA-274, OA-ZYRA-286, AD-AIOS-115]
owner: ZYRA chat
---

# REAL WEB COPY OF THE FOUNDER PREVIEW — BRIEF — 29 OCT 2026

**Founder, 29 Oct 2026:** "Yes, make a real web copy" — answering: Codex exports the real Founder preview as a private web
page (sample people only, no keys, nothing connected), Fable checks it is safe first, the ZYRA chat publishes it.
This is a **review tool**, not a web version of ZYRA: DR-ZYRA-279 (no web app) stands for the product.

## Gate — do nothing until this is true
The newest `BLACK UMBRELLA GROUP/REPORTS/DAILY/<yyyy-mm>/<date>_FABLE_REVIEW.md` contains the line
**`WEB COPY: SAFE TO BUILD`**. If it does not, leave this queue line **WAITING** (do not mark it FAILED) and say so in one
line of your report.

## Steps
| Step | Detail |
|---|---|
| 1 | Work in a temporary copy **outside** `SOURCE/` (e.g. `~/zyra_web_copy_tmp/`). **Never** add a `web/` folder or web code to the ZYRA repo (DR-ZYRA-279) |
| 2 | A web-only entry point that opens the Founder preview (`ZyraOneJourneyConceptShell` via the Founder launch screen's preview path) **directly on its offline sample model** — no sign-in, no Founder-account check, no network. Developer controls hidden |
| 3 | Build with **no** `--dart-define` values, no `.env`, no backend URL or key, nothing from the keys folder. Any package that needs native code or the network is replaced by a stub in the web entry only; app code is unchanged |
| 4 | Safety check of the output: search every built file for `supabase`, `anon`, `key`, `secret`, `token`, `https://` hosts other than fonts; list the results in the task note. Any hit = stop, FAILED |
| 5 | Output to `PRODUCT/APPROVED/WEB_COPY/BUILT/` (static files: index.html, js, assets). Add `PRODUCT/APPROVED/WEB_COPY/BUILT/` to `.gitignore` — a build product is never committed (core rule 8). Size target under 40 MB |
| 6 | Check it opens in a desktop browser at 430 × 932 and that the five Seeker tabs, a request, a Journey and the Guardian role switch work; note anything that does not work on web |
| 7 | Task note (route, safety search results, size, what works / does not), commit only the brief/queue/.gitignore changes, mark the queue line BUILT or FAILED. Delete the temporary folder to `~/_to_delete/` |

## Fable's safety conditions — 30 Oct 2026 (part of the gate; they win over the steps above)

Checked 30 Oct: the Founder preview's code (`lib/dev/zyra_one_journey_concept_shell.dart`) imports, through 318 files,
both git-ignored key files in `lib/config/` (`supabase_config.dart`, `oauth_config.dart`), `supabase_flutter`,
Google and Apple sign-in, and HTTP clients. So:

| # | Condition |
|---|---|
| W1 | Copy `SOURCE/` into the temporary folder **without** `lib/config/supabase_config.dart`, `lib/config/oauth_config.dart`, any `.env`, `GoogleService-Info.plist`, `google-services.json`, `build/` and `.dart_tool/`; then put the two `.example` files in their place. The real key files never leave `SOURCE/`. Never open the keys folder |
| W2 | Build with `--no-web-resources-cdn` (CanvasKit bundled - the published page cannot load it from Google's servers) and no `--dart-define`. Each output file under 15 MB, the whole copy under 40 MB |
| W3 | Output goes to the temporary folder or `SOURCE/build/web_copy/` (git-ignored) - **not** to `PRODUCT/APPROVED/WEB_COPY/BUILT/` (a compiled app outside a build folder trips the disk check; core rule 8). No `.gitignore` change is then needed |
| W4 | Safety search of every output file for: `supabase`, `anon`, `apikey`, `eyJ` (key prefix), `client_id`, `googleusercontent`, `secret`, `token`, and any `https://` host other than fonts. Write the counts in the task note, never the matched text. Any hit that is a URL, key or ID = stop, FAILED |
| W5 | No network at run time: every picture is a sample asset bundled in the copy (anything the preview fetches from the internet, such as picsum.photos, is replaced by a bundled sample or a placeholder); no personal photos. Confirm in the task note that the browser's network log shows only the copy's own files |
| W6 | When the ZYRA chat has published it, move the temporary folder and the output to `~/_to_delete/`. The published page stays private to Shakeel |
