# BUILD BRIEF — SIGN UP (LOCK 34 V1) — 18 NOV 2026
Spec: `PRODUCT/APPROVED/SIGN_UP/RECORD/SIGN_UP_SPEC_CURRENT_VERSION_V1.md`. Prototype: Founder's private copy V271 (Sign up layout). **Masters: `SIGN_UP/MASTERS/` (41, list in spec §6, QUESTIONS 166). Setup sequence: spec §3.8d (QUESTIONS 167).** Exception to AD-AIOS-149 approved by the Founder 18 Nov.

## Scope
Build the whole sign-up and setup flow of the spec in the planned app (Founder preview, sample data, no server calls), replacing the old onboarding screens for the preview path only. The old member app's sign-up is not changed by this line.
1. Splash and Welcome per §3.1–3.2, with Apple/Google order by platform.
2. Steps and order per §2–3, shared step frame (progress bar, ‹ Back, full-height card, bottom gold button), swipe cards for role and membership (card = choice).
3. Validation and red error state per §1 and §3.5; name counts per §3.4.
4. Identity check step per §3.8 (preview: Verify now marks verified; Do this later keeps unverified).
5. Membership only after verification; Account ready, setup continuation, "Finish later and go to ZYRA", My ZYRA Needs you card and Continue setting up per §3.8c–3.9.
6. Gates in the preview: unverified → Profiles / Network gate page; setup incomplete → Request a Journey blocked with the spec line.
7. Reduce Motion: no splash animation, instant step changes.
## Checks
- iPhone: Apple button first; full path Seeker and Guardian, verify now and later; paused setup resumes at the right step; Journey request blocked until setup done.
- No email sign-up or recovery email anywhere. Tests for each step; no new failures.
