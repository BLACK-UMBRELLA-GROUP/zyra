---
id: TBC (Fable assigns)
type: PLAN
status: ARCHIVED (2026-10-30)
feature: SERVER
purpose: Codex task SERVER 0 - live read-only pass and catch-up of the 17 unapplied database files on a throw-away database, with tests and replay; stops before any production change
links: [DOC-ZYRA-0329, DOC-ZYRA-0294, OA-ZYRA-317, OA-ZYRA-319, OA-ZYRA-324, DR-ZYRA-274]
owner: ZYRA chat
---

# SERVER 0 — LIVE PASS AND CATCH-UP — BRIEF — 30 OCT 2026

**Built from:** `ZYRA/REPORTS/CURRENT/ZYRA_SERVER_DESIGN_2026-10-30_V1.md` (DOC-ZYRA-0329) §4 and §5 line 0 — approved by the
Founder 30 Oct ("Yes, approved"; §6 Q5 **"Yes, Fable's plan"**). Founder to the ZYRA chat, 30 Oct: "queue SERVER 0 when ready".

**This line never changes the live database.** It prepares and proves the catch-up on a throw-away database and stops. Applying
to production is a separate queue line that needs the Founder's own words "apply SERVER 0 to live" after a confirmed backup.

| Step | Detail |
|---|---|
| 1 | Read DOC-ZYRA-0329 (§3.2, §3.4, §4, §5), the live check `REPORTS/CURRENT/ZYRA_LIVE_DATABASE_CHECK_2026-10-26_V1.md` (DOC-ZYRA-0294) and `SOURCE/supabase/tests/`. Never open the keys folder; never print, log or copy a key, URL secret or token |
| 2 | **Live read-only pass** (production, read-only queries only, same method as DOC-0294): which migration files are applied; answer every "not verified" line in DOC-0329 (e.g. the `is_synthetic` flag, the profile fields Filters need, test-account counts). Write `ZYRA/REPORTS/CURRENT/ZYRA_LIVE_DATABASE_CHECK_2026-10-30_V1.md` (new id; older one stays until Fable archives it) |
| 3 | **Throw-away database** (local Supabase or a branch — never production): replay every migration in `SOURCE/supabase/migrations` from empty in order (OA-ZYRA-319 replay test). Record the result |
| 4 | Apply the unapplied files exactly as DOC-0329 §4 decides: **drop** 25 Aug `shared_pause_decision_state_machine` (move the file to `~/_to_delete/SERVER0_DROPPED_2026-10-30/` with a note; never delete); **keep** 18 Sep Main-Guardian hold, known-person code matching, product telemetry (stays off); 19 Sep Circle messaging; 23 Sep retire legacy purchase functions; 25–26 Sep Circle participants, sender identity, read receipts; 5 Oct f01–f07 in that order after the 24 Sep rewrite. **Rewrite** as new dated files (the originals moved to `~/_to_delete/` with a note): 24 Sep paid-only contract → Basic 1 place, safe send rule kept (§3.2), view replay fixed; 19 Sep Journey return gate → ended-then-restart (§3.6). Each file does one thing |
| 5 | Run all SQL suites in `SOURCE/supabase/tests` **before and after** step 4 on the throw-away database; add an impersonation test for every rule a kept or rewritten file changes. All must pass |
| 6 | **Stop.** Write `PRODUCT/APPROVED/SERVER/RECORD/SERVER_0_READY_<date>.md`: the exact ordered list of files for production with SHA-256 each, test results before/after, replay result, anything that differed from the live pass, and the backup plan (point-in-time backup confirmed before any apply; no drops in the same change that stops writes) |
| 7 | No app code change, no production write, no drop on production, no dependency added. Task note (plain words), commit within core rule 2 (migration files and reports only), mark this line BUILT or FAILED |
