---
id: DOC-ZYRA-0379
type: PLAN
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Codex task - second attempt at a private web copy of the Founder preview, after the 30 Oct run failed W2 (size) and W4 (web addresses)
links: [DR-ZYRA-279, DR-ZYRA-307, OA-ZYRA-286]
owner: ZYRA chat
---

# REAL WEB COPY OF THE FOUNDER PREVIEW — BRIEF V2 — 30 OCT 2026

**Founder, 29 Oct 2026:** "Yes, make a real web copy". **30 Oct 2026**, after the first run failed (61 MB against 40 MB; sign-in and
remote-image web addresses in the output): chose **"Fix and retry (Recommended)"**. A review tool only; DR-ZYRA-279 (no web app) stands.
The first brief is in `../ARCHIVE/WEB_COPY_BRIEF_2026-10-29.md`; its steps 1–3 and 6–7 and Fable's W1, W3, W5, W6 still apply.
This brief changes **W2 (size)** and **W4 (web addresses)**, so it needs Fable's agreement first.

## Gate — do nothing until this is true
The newest Fable review contains the line **`WEB COPY V2: SAFE TO BUILD`**. Until then leave the queue line WAITING (not FAILED).
If Fable changes any condition below, Fable's wording wins.

## What changes from the first attempt
| # | Change |
|---|---|
| C1 — no sign-in or network code | In the **temporary copy only**, the web entry (`lib/web_copy_main.dart`) uses stubs instead of `supabase_flutter`, Google sign-in, Apple sign-in and the HTTP clients (dependency overrides or conditional imports in the temporary copy; `SOURCE/` unchanged). A sign-in button, if reachable, shows "Not available in the web copy" |
| C2 — no remote pictures | Every picture the preview would fetch (e.g. picsum.photos) is replaced by a bundled sample asset; no personal photos |
| C3 — smaller output | Build with `--no-web-resources-cdn`, no `--dart-define`, no `--wasm`. Remove from the output the engine files a non-wasm build never loads (`canvaskit/skwasm*`). Bundled sample pictures at most 1080 px on the long side, JPEG quality ~80. Keep only the font files the app uses |
| W2′ — size | Whole copy **under 60 MB** and every file **under 15 MB** (the private page's limits are 64 MB per upload and 15 MB per file). Over → stop, FAILED, with a table of sizes by folder |
| W4′ — safety search | (a) **Keys and IDs — must be zero:** `supabase`, `anon`, `apikey`, `eyJ`, `client_id`, `googleusercontent`, `secret`, `token` used as a credential. Any hit → stop, FAILED. Write counts only, never the matched text. (b) **Web addresses:** list every `https://` host and its count. Allowed only if it is a font host or text inside Flutter/Dart framework code that is never contacted; anything from sign-in, Supabase or remote images → stop, FAILED |
| W5′ — proof nothing goes online | In step 6, open the copy in a desktop browser with the network log on, go through the five Seeker tabs, a request, a Journey and the Guardian role switch; the log must show **only the copy's own files**. Any other request → stop, FAILED. Record the request count in the task note |

## Output and hand-over
Output to the temporary folder or `SOURCE/build/web_copy/` (W3). Task note: route, sizes table, safety counts, network-log
result, what works and what does not on web. Mark the line BUILT or FAILED. The ZYRA chat publishes it as a private page for
Shakeel; then the temporary folder goes to `~/_to_delete/` (W6).
