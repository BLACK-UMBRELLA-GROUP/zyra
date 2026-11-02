---
id: DOC-ZYRA-0382
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex fix brief - the shared ‹ · label · › bottom pill must be the ivory pill of the LOCK 14 V5 and LOCK 10 V7 masters (today gold-filled on Journey tab and Filters; unreadable on Filters) and the Filters preferences link must not clip at Larger Text
links: [AD-AIOS-115]
owner: ZYRA chat
---

# FIX BRIEF — BOTTOM PILL BACK TO THE MASTERS (LOCK 14 V5 · LOCK 10 V7) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after lines 42 and 53 (both BUILT); before line 44.
Found by the ZYRA chat comparing `APP_COLOURS/BUILT/COMPARISONS/c01, c02, c06` and `FILTERS/BUILT/V7/master_beside_build.png`, plus Codex's `FILTERS/BUILT/V7/FOOTER_DIAGNOSTIC.json`.

| Step | Detail |
|---|---|
| 1 | Compare the masters with today's build: LOCK 14 V5 masters **c01** (Profiles "Request sent"), **c02** (Journey tab "Continue Journey"), **c06** (Filters "Show profiles") and LOCK 10 V7 masters **f01–f10**. In every master the ‹ · label · › pill is **ivory** (Ivory pill surface, thin gold border, soft shadow), label in normal ink `#2B2420`, gold ‹ ›, thin dividers |
| 2 | Today the same pill is **gold-filled** on the Journey tab ("Continue Journey") and on Filters ("Show profiles"); on Filters its label is gold-brown on gold and cannot be read. Make the pill ivory in **every** state and page that uses it, exactly as the masters. It is never gold-filled. Actions, arrows, enabled/disabled logic unchanged |
| 3 | Filters "Your preferences also shape who you see ›": remove the fixed 50 pt height so the link grows with Larger Text and never overlaps the pill (FOOTER_DIAGNOSTIC: 68 pt needed at 200 %) |
| 4 | Change nothing else. Gold-filled **buttons** (e.g. Unlock compatibility, Check code, Send request) stay gold (LOCK 14 V4). Tests: pill ivory on Profiles, Journey tab, Filters; label contrast ≥ 4.5 : 1; at 200 % text the Filters link bottom ≤ pill top. Analyser clean |
| 5 | Render c01, c02, c06, Filters f01 and one 200 % Filters frame into `FILTERS/BUILT/V7FIX/` with master-beside-build; task note; commit within core rule 2; mark queue line 71 BUILT or FAILED |
