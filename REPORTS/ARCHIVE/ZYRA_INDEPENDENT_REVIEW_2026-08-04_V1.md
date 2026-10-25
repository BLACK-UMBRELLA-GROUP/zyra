# ZYRA — Full Independent Review

**Document:** ZYRA_INDEPENDENT_REVIEW_2026-08-04_V1.md
**Reviewer:** Fable (UX & Product Experience Lead), acting as independent reviewer at Founder request
**Date:** 2026-08-04
**Scope:** Whole product — app, database, backend functions, documentation, security, UX
**Method:** Live database interrogation (not documentation reading), source inspection, doc-vs-implementation comparison. Every claim below is evidenced. Where I could not verify, I say so.

**Standing limits:** no Flutter toolchain in my sandbox (cannot compile or run); no penetration testing performed against the live API — findings are derived from RLS policies, grants and function definitions read directly from Postgres. I am not a lawyer.

---

## 1. Executive Summary

ZYRA is further along than most solo-founder products at this stage and the governance around it is genuinely unusual — 100+ decision records, a real engineering audit, verified fixes. That is the good news, and it is not faint praise.

The core finding of this review is a pattern, not a list: **the product's documentation and its enforcement boundary have drifted apart, and the drift always runs the same way — the documents describe the intended product, the database permits more.** Every critical finding below is an instance of that one pattern.

Three things are true simultaneously:

1. **Real, verified progress since 26 July.** DOB is genuinely hidden now (`has_column_privilege(...,'date_of_birth','SELECT')` = false for both roles — the July audit's C2 is closed and I confirmed it myself). The mock-purchase functions are properly guarded to `@zyra.test` accounts. Blocks are enforced *inside RLS* via `zyra_block_exists()`, which is better than most apps manage. Article 9 consent is live with 24 recorded rows — that was raised days ago and is already built.
2. **Two critical security holes are open right now**, both permitting free access to special-category personal data or paid features. Neither is theoretical; both are reachable with the app's own publishable key and a HTTP client.
3. **The product has never run end-to-end.** `matches` = 0 rows. `onboarding_answers` = 0 rows. The Journey system, the compatibility engine, and the entire post-match experience — the actual product — have never executed against real data. Everything anyone believes about them is inference from source code.

**Beta readiness: not yet — but the gap is days of work, not months.** Details in §20.

---

## 2. Critical Issues

### C-1 — Anyone can grant themselves a Profile Unlock, then read another member's religious and ethnic data. **Blocks beta.**

**Evidence.** `profile_unlocks` grants `authenticated` full `INSERT, UPDATE, DELETE` (verified via `role_table_grants`), its only INSERT policy is `WITH CHECK (unlocker_id = auth.uid())`, and there is **no trigger on the table** (`pg_trigger` returns zero non-internal rows). Payment is client-side only — `zyra_unlock_service.dart`'s own header says the record is real but the purchase is not. Then `seeker_details_for_unlocked(p_target)` — `SECURITY DEFINER` — returns `sect, sect_other, revert_status, country_of_birth, nationality, ethnicity, languages`, gated solely on a row existing in `profile_unlocks`.

**Risk.** Two HTTP requests with the app's publishable key: insert your own unlock row for any target UUID, then call the function. You receive that person's madhhab, revert status, ethnicity and nationality. **Impact:** unauthorised disclosure of Article 9 special-category data — the single most sensitive data ZYRA holds, about a minority community. **Likelihood:** high once anyone inspects the app bundle; the pattern is well known and the key ships in the binary.

**Mitigation.** Move the insert behind a `SECURITY DEFINER` RPC that verifies an entitlement (credits balance, or a store receipt when payments land) and `REVOKE INSERT/UPDATE/DELETE ON profile_unlocks FROM authenticated`. Same pattern already used successfully for `accept_wali_invite`. Until payments exist, gate the RPC on a server-side credit ledger rather than trust.

### C-2 — The Founder's stated model of Profile Unlock does not match what is built. **Needs a decision before the solicitor is briefed.**

In the Article 9 brief on 2026-08-01 the position was: *"Users do NOT purchase someone's raw onboarding answers… Users receive additional compatibility insights."* The function above returns **raw stored fields**, not derived insights. I gave advice on that brief in good faith and must correct it now: my "insights, not raw answers" mitigation does not currently exist in the code.

This is not necessarily wrong as a product — showing sect and ethnicity after an unlock may be exactly right for a marriage platform — but the legal analysis, the consent wording and the Privacy Policy must describe *what actually happens*. Decide which one changes: the code (derive insights) or the description (say plainly that unlocking reveals stated background details). Either is defensible; the mismatch is not.

### C-3 — Privilege escalation to `role='admin'` is still open. **Blocks beta.**

**Evidence.** Verified live: `has_column_privilege('authenticated','profiles','role','UPDATE')` = **true**, likewise `date_of_birth`, `gender`, `profile_complete`, `is_active`. This is the July audit's C4, still unfixed. Any user can self-promote to admin, falsify their age, change gender (bypassing segregation), and self-publish without moderation.

**Blocker note.** The audit correctly identified why this can't be revoked alone: `ZyraProfileService._createProfile` UPSERTs those columns. Fix order: create-profile RPC first, then revoke. This is the single most important engineering task on the list.

### C-4 — No minimum-age enforcement anywhere. **Blocks beta.**

`pg_constraint` has **zero** CHECK constraints referencing `date_of_birth`. Combined with C-3 (users can rewrite their own DOB), a marriage platform has no server-side guarantee that any account belongs to an adult. Both Terms and the app stores will assume 18+. Add `CHECK (date_of_birth <= current_date - interval '18 years')` plus client validation.

### C-5 — Zero real matches; the product's core has never executed.

`matches` = 0, `onboarding_answers` = 0, `seeker_details` = 24. So: `score_candidates()` reads Chapter 3/4 answers that do not exist for anyone → compatibility scoring returns neutral for every candidate in practice. The Journey system, Family Review Period, timeline milestones, chat and the Wali journey view have **never run once** against real rows. This isn't a defect to fix; it's a *verification debt* — until two real accounts complete onboarding, match, and walk a Journey end to end, nothing in that half of the product is known to work. It should be the next thing that happens, before any new feature.

---

## 3. High Priority

**H-1 — Gender segregation is still client-side only.** `profiles_select` (read live) allows any authenticated user to read every active+complete profile of either gender; the rule exists only in a Dart `.eq('gender', …)`. For this product that is not a normal access-control gap — it is a religious-integrity guarantee that the server does not keep. Add the opposite-gender condition to the policy.

**H-2 — `ages_for()` accepts arbitrary UUIDs with no authorisation check.** Body verified: `SELECT ... WHERE p.id = ANY(p_ids)` — no filter on whether the caller may see those profiles. It is the workaround that partially undoes the DOB fix (you can't read the date; you can read the age for any UUID, including hidden or opposite-gender profiles). Add the same visibility predicate the Browse query uses.

**H-3 — `score_candidates()` likewise takes arbitrary candidate IDs.** With crafted preference data this becomes an oracle for inferring another member's religious answers. Lower likelihood than C-1 (requires effort), higher sensitivity (Article 9 inference). Restrict to candidates the caller may actually see.

**H-4 — Reports go nowhere.** 3 reports exist; 0 have moved off `pending`. No queue, no triage, no notification. The Online Safety Act duties and the app-store review both assume otherwise. Minimum viable fix: an email/notification on insert plus a manual admin view — not a full moderation product.

**H-5 — Anonymous EXECUTE on journey mutation functions.** `end_journey`, `promote_journey_to_active`, `suspend_journey`, `resume_journey`, `zyra_*_clears_others` are all `SECURITY DEFINER` and callable by `anon`. I read each body: they check `caller IS NULL` and raise, so they are **not currently exploitable** — this is defence-in-depth, not an open door. Revoke anyway; the guard is one edit away from being removed by a future session.

**H-6 — Mock data still fronts Browse.** 21 references to `mockProfiles` remain. This is what hid a month-long bug in July, and it will show fabricated people to real beta users. Remove now that 24 real profiles exist.

---

## 4. Medium Priority

- **21 RLS policies still use unwrapped `auth.uid()`** (42 wrapped, 21 not — measured). A fixed problem that returned on newer tables because it was never written down as a rule. Add it to CLAUDE.md, then fix.
- **Missing index `profile_photos(user_id)`** — confirmed absent; every photo fetch in Browse/Connections/Journey sequential-scans. (`matches(seeker_b_id)` *is* now indexed — the July finding was actioned.)
- **75 silent `catch (_)` blocks** (up from 64 in July) against 25 `debugPrint`s. Failures are still largely invisible. The audit's own lesson has partially regressed.
- **No crash reporting or analytics.** In beta you will be told "it didn't work" with nothing to inspect.
- **`AppState` remains one global `ChangeNotifier` mixing backend state, session state and mock state**, with no state-management package in `pubspec.yaml`. `ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md` still says "State Management: TBD" — five weeks on. Not urgent for beta; increasingly expensive after.
- **Two 1,400+ line screens** (`browse_screen.dart` 1,910; `connections_screen.dart` 1,460) — the largest maintainability risk in the codebase.

---

## 5. Low Priority

Duplicated `_fetchAges()` across three services; the photo-mapping block repeated five times; `analysis_options.yaml` is still the stock template with no project rules; `messages` has no UPDATE policy so read receipts can't work as designed; `messages_select` doesn't filter `deleted_at`.

---

## 6. UX Review

**What's genuinely strong.** The Journey model is a real product idea, not a reskinned dating app. Consider/Save/Pass is better vocabulary than like/swipe. "No record, no notification" on Pass is a kindness competitors don't offer. The Help Centre voice is the best writing in the product. The Article 9 consent screen, built in days, is the sort of thing that will make this audience trust the app.

**The dominant UX risk is not a screen — it's untested flow.** With zero matches ever created, every post-match experience is unverified: what a Potential Journey feels like, whether the Family Review Period reads as supportive or bureaucratic, whether a Wali understands what they're being asked. I'd put a two-account walkthrough above any new feature.

**Specific issues.** Onboarding is ~174 questions plus Chapter 2 before a user sees a single profile — the highest-risk conversion surface in the product and it has never been measured; consider a "see who's here first" preview. Terminology is mid-rename: **645 "Wali" vs 272 "Guardian"** in code, with both appearing in user-facing strings — pick one and finish. Empty states don't distinguish "no results" from "network error" from "permission denied". The 50-profile limit and plan gating are enforced client-side only, so the paywall is honesty-based.

## 7. UI Review

**385 hardcoded font sizes and zero `semanticLabel` usages** (2 `Semantics` widgets in 23,000 lines). Practical effect: the app does not respond to iOS Dynamic Type, and VoiceOver reads unlabelled controls. For a product whose own inclusion work names accessibility as Layer 1, this is the largest gap between stated values and shipped product. Also: `withOpacity`→`withValues` migration is done (I did it), but the white38/white54-on-purple text used throughout for secondary copy will likely fail WCAG AA contrast — worth measuring, not guessing. Zero `RepaintBoundary` alongside 11 blur effects is a scrolling-smoothness risk on older devices.

## 8. Engineering Review

Code quality per-file is high — the comment discipline in this codebase is genuinely exceptional and has repeatedly let me reconstruct *why* a decision was made. The weakness is systemic, not local: two parallel truth systems (real path + mock fallback chosen silently at runtime), business rules in the client, and 2 test files for 92 source files. `flutter analyze` is clean as of today. The `run.sh` hardening and the `supabaseReady` guard are both good, recent, defensive work.

## 9. Architecture Review

The Supabase-plus-RLS choice is right and mostly well executed — `zyra_block_exists()` inside the policy layer is exactly the correct instinct. The architectural drift is that **enforcement keeps landing in Dart while the documents assume it lands in Postgres**. Every critical finding in §2 is that drift. The fix is a rule, not a rewrite: *if a document states a guarantee, a database object must enforce it.* Adopt that and the class of bug disappears.

## 10. Security & Privacy Review

Covered above; consolidated verdict: **two blocking issues (C-1, C-3), one legal-model mismatch (C-2), three high (H-1..H-3).** Positives worth recording: private storage bucket verified, signed URLs, block-aware RLS, `@zyra.test` guards on mock purchases, `consents` table with no UPDATE/DELETE policy (immutable audit trail — good design), DOB genuinely hidden. GDPR: Article 9 consent exists and is recording; retention periods, the Wali privacy notice and the Profile Unlock disclosure remain open per the website blueprint. Secrets handling is correct (`.env` gitignored, no keys in source).

## 11. Performance & Scalability Review

Nothing here blocks beta at 24 profiles. Real risks at scale: the missing photo index, per-frame `setState` during Browse drag rebuilding a blurred subtree, a 1-second `Timer.periodic` driving a 24-hour countdown, and 15 unindexed foreign keys. Supabase's connection pooler will not be the bottleneck; the client render path will.

## 12. Product Strategy Observations

The Wali/Guardian model is the moat — no competitor has a real second account with genuine standing. It is also the biggest legal exposure and the least-tested flow. That combination argues for making it the focus of the next fortnight rather than adding surface elsewhere.

One challenge to an approved decision: **"ad-free" as a ZYRA One benefit** (in the Help Centre) when no ads exist anywhere. Your own Muzz teardown criticises pricing on *removal of penalties*. Either commit to ads and say so plainly, or drop the claim — it currently sells the absence of something that was never there.

## 13. Technical Debt

Ranked by cost-of-delay: mock-data fallbacks (actively dangerous), client-side business rules (security), two mega-screens (change velocity), no state management (compounding), 75 silent catches (invisibility), no tests (regression risk).

## 14. Documentation Drift

Notable and largely one-directional. `ZYRA_ARCHITECTURE_V2` still says state management is "TBD" five weeks after the app grew around its absence. `zyra_match_service.dart`'s header describes a schema that changed on 25 July. The FAQ's Wali answer was corrected already — credit where due, someone caught that the old "they do not read your private conversations" line contradicted `messages_select`, which per `WALI_ARCHITECTURE_V6` **intentionally** grants Guardians message access on non-potential matches. That correction is right, and the surviving lesson is that user-facing copy must be regenerated whenever a policy changes.

## 15. Quick Wins

`REVOKE EXECUTE … FROM anon` on the six journey functions (one migration, minutes). Add the age CHECK constraint. Add the `profile_photos(user_id)` index. Delete the `mockProfiles` fallback. Fix the "ad-free" line. Finish the Wali→Guardian rename in user-facing strings. Each is under an hour; together they close one critical-adjacent and several mediums.

## 16. Future Opportunities

Server-computed compatibility insights (would resolve C-2 elegantly and make the unlock genuinely defensible); a moderation queue as a small internal tool; accessibility Layer 1 as a release gate rather than a backlog item; the Shared Life Experiences work once a user base exists.

## 17. Overall Product Score — **6.5 / 10**

Distinctive, coherent, values-led product thinking with an unusually strong governance spine; marked down because the core loop has never run and several user-visible guarantees aren't yet enforced.

## 18. Overall Engineering Score — **6 / 10**

High per-file craft and excellent documentation discipline; systemic issues — client-side enforcement, mock/real duality, near-absent tests, invisible failures — hold it back. Rising trend: the July audit's findings are being closed properly and verifiably.

## 19. Overall UX Score — **6.5 / 10**

Strong voice, genuine differentiation, thoughtful details. Held back by unverified flows, accessibility absence, terminology drift and an unmeasured 174-question onboarding.

## 20. Beta Readiness — **Not yet. Two to three focused days away.**

**Must close before any external user touches it:** C-1 (free unlocks → Article 9 disclosure), C-3 (privilege escalation), C-4 (minimum age), H-1 (server-side gender segregation), H-6 (remove mock profiles), plus one real end-to-end Journey walkthrough (C-5) to establish that the product works at all.

**Should close in the same pass:** H-2, H-3, H-4, H-5 and the quick wins in §15.

**Can follow beta:** state management, screen decomposition, tests, accessibility Layer 1 (though I'd argue accessibility deserves to be a launch gate, not a beta gate — with beta being the moment to start measuring it).

Said plainly: nothing here is a redesign, and nothing here suggests the project is off course. It is a young product whose documents got ahead of its enforcement. Close the gap and this is a beta-ready app in a week.

---

*End of Document*
