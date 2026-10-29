---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - capture the current sign-up and onboarding screens (Seeker and Guardian) for the baseline, screen by screen
links: [DR-ZYRA-286, DOC-ZYRA-0296]
owner: ZYRA chat
---

# SIGN-UP CAPTURE BRIEF — 29 OCT 2026

**Founder, 29 Oct 2026:** wants the prototype to switch between four layouts — "seeker - gurdian - sign up - journey". The
baseline has no sign-up pictures (it covered the planned app after sign-in only).

| Step | Detail |
|---|---|
| 1 | Same route and settings as `SCREENSHOTS/BUILD.json` (430 × 932 @3x, offline sample data, no network, no real account) |
| 2 | Capture, in order, every screen a new member sees from opening the app to the app's first tab: splash, welcome, sign in / sign up, role choice (Seeker / Guardian), each setup and question screen, identity-check entry screen (do not start a real check), photos, membership choice, and the screen that opens the app. Both roles. Include each screen's empty, error and loading state where the screen has one |
| 3 | Save to `SCREENSHOTS/signup/<role>/<nn>_<screen>__<state>.png` with `nn` = order in the flow (01, 02 …); add INDEX rows (role, order, screen, state, how reached) and a BUILD.json note |
| 4 | No app code change. Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
