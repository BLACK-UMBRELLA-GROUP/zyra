# Founder Report — The First Overnight Run, What It Taught Us, and What Changed

**For:** Shakeel (Founder)
**From:** Fable
**Date:** 2026-08-23
**Covers:** the overnight API run (01:00–01:09 UK night), the morning finisher, the review day with Codex, and every change made as a result.
**Money spent on everything in this report after the run itself: $0.00.**

---

## 1. What you asked for

You wanted the first real API test: Fable and Codex working on your own API keys, overnight, unattended — not producing advice, but physically delivering the Guardian Network first draft into the ZYRA app, gated by flutter analyze, with every task's cost measured. Measurement first; spending limits designed later. That run fired at 02:00:05 UK time and the machine did exactly what it was built to do — including failing safely.

## 2. What happened overnight — the short story

The run had seven stages. The first three went well: Fable wrote its position from the Guardian Network spec, Codex challenged it, and Fable closed the discussion into a build contract (the "agreed rules"). Cost for that whole discussion: about 17 cents.

Then Codex generated the screen — a good draft, but it was **cut off mid-sentence on its very last line**, because I had given the engine a 9,000-token output limit and the file needed slightly more than that. Think of it as a printer running out of paper one line before the end.

The engine saw errors and did what it was designed to do: it paid Codex to fix them, up to four times. This is where the money went wrong. Each "fix" rewrote the entire file from scratch — and each rewrite hit the same paper-out limit and got cut off again. Worse, the first rewrite quietly introduced a new mistake: 19 colour-opacity calls written in a style our codebase forbids (`withAlpha` instead of `withValues` — the codebase uses `withValues` 478 times with zero exceptions). No fix round ever repaired that. The error count went **6 → 16 → 20 → 19 → 12** across the paid rounds. The run ended worse than it started.

At that point the safety rails worked perfectly: the engine put your original screen back untouched, recorded everything, and went to sleep. You woke up to a safe app and a full ledger — which is exactly what "failing safely" was supposed to look like.

## 3. The morning finisher

The actual repair cost nothing. I converted all 19 forbidden opacity calls to the codebase convention mechanically — no AI involved — and you ran the one-line apply command yourself. Flutter analyze passed clean, and the Guardian Network first draft went live in the app with its FIRST DRAFT header.

## 4. The money

| Stage | Cost | Worth it? |
|---|---|---|
| Discussion (Fable position, Codex challenge, agreed rules) | $0.171 | Yes — produced the build contract |
| Codex builds the screen | $0.127 | Yes — ~90% of what shipped came from this draft |
| Four failed fix rounds | **$0.463** | **No — 54% of the whole run, ended with more errors than it started** |
| Fable's final verification | $0.089 | Partly — see §6, it verified the wrong file |
| Morning repair + apply | $0.000 | Yes — this is what actually delivered |
| **Total** | **$0.8495 (~£0.67)** | 21% of the $4.00 safety ceiling |

Your other question — why the OpenAI/Codex side cost 2.9× the Anthropic/Fable side ($0.63 vs $0.22): 73% of the OpenAI money went on **output tokens**, and 98% of those output tokens were the same ~1,370-line file being regenerated five times. It wasn't Codex being expensive — it was my engine's protocol paying full price for the whole file every round to change a few lines. With the same run shape under the new controls, the modelled cost is **$0.36–0.39 — about 55% cheaper — with fewer ways to fail.**

## 5. The review day — what Codex caught, and what I found

Per your instruction, I wrote the full evidence-based review (document 04), you relayed it to Codex, and he replied with verdicts. He agreed with almost everything and improved seven proposals with better engineering (all accepted). He also caught a real error in my review:

**Codex was right:** the engine's final verification step read the file **after** the original had been restored — so the run's "contradiction check" reviewed your old screen, not the failed draft. My review had claimed otherwise. The engine code confirms it, and I've owned the correction on the record (document 05).

Digging into his claim surfaced three more things nobody had noticed:

1. **The build contract itself was cut off.** The agreed-rules document declares "Rules 1–47" but ends mid-sentence in Rule 22 — Fable's own contract-writing task hit ITS token cap (3,000 exactly). Every later stage built against half a contract, and nothing checked. So the night actually had **three** truncations, on both providers.
2. **The "original" screen was already a Guardian Network draft** (from the earlier daytime work) — which is why the wrong-file verification read plausibly: the two files are siblings.
3. **Two real gaps are in the live draft:** the Discover card showed candidates' **full first names** where the agreed privacy rule (Rule 12) requires an initial only — and the profile sheet that opens when you tap "View" was an **empty shell** (the truncation battles amputated its content in a way flutter analyze can't see).

I then did what the run should have done: a proper contradiction review of the exact live file, hash-verified (document 06). Result: the draft is **safe** (the non-developer path shows only empty states, nothing can leak), the skeleton is faithful to the rules we could check — and the known issues are exactly the ones listed above.

## 6. Fixes already applied today

Per your "quick fix, then test" decision, the **full-name privacy issue is fixed and live** — cards now show "A., 27" style initials. Done mechanically, $0, hash-checked before and after. Remaining draft gaps (three missing card fields, the empty profile sheet, the Save button, completing the contract's rules 22–47) are logged as OA-ZYRA-246 and wait for your direction — they're Phase-2-sized, not quick fixes.

## 7. The machine was rebuilt so this can't happen again

Fable and Codex agreed fourteen permanent controls (the rulebook is now a live document: `AIOS_EXECUTION_ENGINE_CURRENT_VERSION_V1.md`), and I implemented all of them in the engine today — tested by a 65-check harness that replays last night's failure patterns against a fake app. Every check passes. In plain terms, the engine now:

- **treats any cut-off output as invalid** — code AND documents. A contract must end with a counted "END — Rule N of N" line or nothing downstream will use it. Last night's silent half-contract is impossible now.
- **runs the free fixer first** — the forbidden-opacity converter (the thing that actually repaired the draft, for $0) now runs automatically before any paid fix round.
- **buys patches, not rewrites** — fix rounds return a few changed lines which the engine verifies and applies; a whole file coming back from a fix round is refused. Last night's five full-file regenerations can't recur.
- **stops paying when it isn't working** — if a fix round doesn't shrink the error set, no identical round is bought. Rounds 2–4 (35 wasted cents) would not happen today.
- **checks the file hasn't changed before writing** — your own edits can never be clobbered by a stale overnight draft.
- **verifies the exact draft by fingerprint (hash)** — the wrong-file verification Codex caught is structurally impossible now, and every report states exactly which version it reviewed.
- **is honest about "ready"** — "FOUNDER REVIEW: ready" now requires the full gate (format, analyze, focused tests where they exist, zyra_check, and a parsed contradiction verdict), never just "the API call worked".
- **records richer accounting** — every AI call now logs its run/session, attempt number, whether it was truncated, the draft fingerprints, and two separate statuses: "did the call work" vs "did the result pass". This feeds the new usage pages (§9).

## 8. One action for you

**Restart AIOS when convenient** — Ctrl+C in its Terminal window, then start it again the same way you always do. The new engine and (shortly) the new usage pages only load on restart; until then the old code stays in memory. Nothing is armed overnight, so there's no urgency.

## 9. What happens next

- **Now building (your go):** the AI Usage rebuild + the new API Runs history — one shared record store, grouped by session ("one business task = one session"), permanent history, cost and efficiency views, simple dashboard. Old page reviewed first (KEEP/MODIFY/REBUILD/REMOVE), per your spec. Spending limits and alerts stay out of scope, as you directed.
- **With you:** phone-test the Guardian Network draft (open the Wali → Network tab; the known-issues list is document 06); paste document 05 to Codex when convenient — it closes the loop unless he objects; D1–D13 ratification when you're ready.
- **Open in the registers:** OA-AIOS-357 (proper AIOS service install), OA-AIOS-361 (the usage rebuild, in progress), OA-ZYRA-246 (remaining draft gaps + contract completion). Separate API keys for Black Umbrella vs ZYRA stay parked as OA-AIOS-355.

## 10. The one-line summary

The experiment cost £0.67, failed safely, taught us exactly where every wasted cent went, and the machine that runs the next experiment has been rebuilt so it cannot repeat a single one of those failures — for free.

---

*Evidence for every claim: `ZYRA/SYSTEM/RESOURCES/OVERNIGHT_GN_2026-08-23/` (documents 04, 05, 06, RUN_REPORT, RUN_LEDGER, all drafts and analyzer passes) and the engine harness `overnight_engine_harness.py` beside the engine.*
