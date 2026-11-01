---
id: DOC-ZYRA-0380
type: PLAN
status: CURRENT
feature: ZYRA WEB COPY
purpose: Real web copy of the Founder preview - third attempt; W4 allows licence text (required, never contacted)
links: [OA-ZYRA-286, DR-ZYRA-307, DR-ZYRA-279]
owner: ZYRA chat
---

# REAL WEB COPY OF THE FOUNDER PREVIEW — BRIEF V3 — 30 OCT 2026

Replaces V2 (`../ARCHIVE/WEB_COPY_BRIEF_2026-10-30_V2.md`, queue line 21, FAILED at W4′). Everything in V2 still applies
(C1–C3, W1, W2′, W3, W5′, W6) **except W4′(b)**, changed below. Founder 30 Oct: "Fix and retry"; "provide fix".

**Why it failed:** the bundled font licences and the licence notices file contain web addresses (e.g. the licence's own home page).
They are legal text that must ship with the fonts and packages; the app never contacts them. V2's wording only allowed font hosts and
framework code, so Codex correctly stopped rather than strip the licences.

## Gate — do nothing until this is true
The newest Fable review contains the line **`WEB COPY V3: SAFE TO BUILD`**. Until then leave the queue line WAITING (not FAILED).
If Fable changes any condition below, Fable's wording wins.

## W4″ — safety search (replaces W4′)
| Part | Rule |
|---|---|
| (a) Keys and IDs | Unchanged from V2: zero hits for `supabase`, `anon`, `apikey`, `eyJ`, `client_id`, `googleusercontent`, `secret`, `token` used as a credential. Counts only, never the matched text |
| (b) Web addresses | List every `https://` host with its count **and the file it is in**. Allowed: (1) font hosts; (2) text inside Flutter/Dart framework code that is never contacted; (3) **text inside licence files** — `assets/NOTICES` (or `NOTICES.Z`), bundled font licence files (`OFL.txt`, `LICENSE*`) and package licence notices. Never remove or edit a licence. Anything else, or any host from sign-in, Supabase or remote images → stop, FAILED |
| (c) Proof | W5′ (network log shows only the copy's own files) is the deciding test: an allowed host in (b) that is ever requested → stop, FAILED |

## W5′ walk-through (adjusted)
Go through the five Seeker tabs, a request and a Journey. If the developer-toggle removal line has been built first, there is no
Guardian role switch — skip that part and say so in the task note.

## Output and hand-over
As V2: task note with route, sizes table, safety counts with the licence-file breakdown, network-log result. Mark BUILT or FAILED.
The ZYRA chat publishes it as a private page for Shakeel.
