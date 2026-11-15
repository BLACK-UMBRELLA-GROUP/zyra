---
id: DOC-ZYRA-0480
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 31 - the admin-only Developer panel opened by tapping a page title (sample Journeys, Ended Journeys, Journey requests, Introductions)
links: [OA-ZYRA-325, AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — ADMIN-ONLY DEVELOPER PANEL — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Spec: `DEV_TOGGLES/RECORD/DEV_PANEL_SPEC_CURRENT_VERSION_V1.md` (LOCK 31). Reference: prototype V204 (private copy
`BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V224.html`) → tap any Seeker page title.
**This reverses line 44 for this one panel only.** Nothing else line 44 removed comes back.

| Step | Detail |
|---|---|
| 1 | Build after lines 93 and 95 (Ended Journeys menu and the grouped Past card are what the panel loads) |
| 2 | **Gate = server claim only.** Reuse `lib/services/zyra_developer_access.dart` (`zyra_role` in `app_metadata`). Never compare the email text in the app. The panel needs no compile-time flag, so it works in Xcode, TestFlight and App Store builds — but only when the signed-in account has the claim. **The claim is already set (Fable, checked live read-only 12 Nov 17:15 and 18:20; QUESTIONS 129):** the ZYRA admin account holds `app_metadata.zyra_role = 'founder'` and is the **only** account with any `zyra_role` - no server change is needed. Gate the panel on a freshly refreshed session with `zyra_role == 'founder'` **and** the pinned user id and Supabase project in `ZyraInternalFounderPolicy`, **without** the `ZYRA_INTERNAL_FOUNDER_ACCESS` build flag or the production-variant condition (for this panel only; the other founder-preview tools keep their current gate). Do not add an `admin` value |
| 3 | **Open:** tapping the page title on any Seeker page opens the sheet (spec §2). Non-admin: title not tappable, no semantics, no keys |
| 4 | **Sheet:** spec §3 exactly — Developer · account line with the real plan · JOURNEYS (Active 0–3 capped by the plan's places, Ended 0–3) · JOURNEY REQUESTS (Received 0–3, Sent 0–3, Past None / Mixed / Same person) · INTRODUCTIONS 0–3 · **Clear sample data** · **Done**. Existing LOCK 28 ivory sheet component |
| 5 | **Real effect (spec §4):** each control drives the same app state the pages read (Journey tab, My ZYRA counts and Needs-you, Journey requests tabs, Ended Journeys, Introductions, request capacity). No picture swaps. Accept / Decline / Cancel / Remove work on sample items as on real ones |
| 6 | **Sample data store:** app-side, admin account only, cleared by **Clear sample data** and on sign-out; never written to shared tables, never sent to analytics, never visible to another account. Name sample people from the preview pool (Sara, Amira, Hana, Noor, Zainab, Safiya…) |
| 7 | **Release safety:** update line 44's test so it still fails if any developer control is reachable for a non-admin account, and add: admin claim → title opens the panel; no claim → nothing; Clear sample data returns every page to the real state |
| 8 | Tests for each control (counts on each page), plan cap (Seeker Basic: Active 2 and 3 disabled), Past Same person = 20 grouped requests |
| 9 | Gate: `flutter analyze` clean; no new failures. iPhone: protected route only, on Shakeel's GO, telling him the build first |
| 10 | Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
