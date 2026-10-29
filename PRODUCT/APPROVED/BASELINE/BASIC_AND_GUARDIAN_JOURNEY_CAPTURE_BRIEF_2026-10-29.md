---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - capture Seeker Basic, Guardian Basic and the Guardian's view of a Journey in every reachable state, for the prototype
links: [DR-ZYRA-252, DR-ZYRA-282, DR-ZYRA-268, DOC-ZYRA-0301]
owner: ZYRA chat
---

# BASIC PLANS AND GUARDIAN JOURNEY CAPTURE BRIEF — 29 OCT 2026

**Founder, 29 Oct 2026 19:25:** "also the 4 optoins we havee in prototype.. add seeker basic gurdian basic and in journey do
drop down menue with every option possible... maybe even 2 journey tabs - seekers view with every option possible and gurdian
journey tab with every option possibkle"

The baseline has the Seeker side of a Journey (89 pictures) but only one picture of the Guardian's view of a Journey
(`guardian/guardians/guardian__active_journey.png`) and almost nothing on Basic plans. The prototype now has these layouts;
until this capture lands, its Basic pages are drawn from the plan rules (blueprint 2 Membership §6) and its Guardian Journey
list shows the missing states as "Waiting for Codex capture".

| Step | Detail |
|---|---|
| 1 | Same route and settings as `SCREENSHOTS/BUILD.json` (430 × 932 @3x, offline sample data, no network, no real account). Use the preview's own Basic switches (`initialSeekerBasic`, `initialGuardianBasic`, the Profile plan controls). No app code change |
| 2 | **Seeker Basic** → `SCREENSHOTS/seeker_basic/`: all five tabs; Profile tab; Membership; Compatibility Unlocks store (0 included); Add a Guardian when 1 Guardian is already linked; Journey requests at the 3-pending limit; a request arriving while the 1 place is full; Profiles when the 25-per-4-hours limit is reached; Ended Journeys (no restart). Each only where the preview reaches it |
| 3 | **Guardian Basic** → `SCREENSHOTS/guardian_basic/`: every Guardian tab; Network; My ZYRA; Seekers; Profile; Membership; the linked Journey (view only, no chat); Family Review as Main Guardian |
| 4 | **Guardian's view of a Journey** → `SCREENSHOTS/guardian_journey/`: as **Main Guardian** (Guardian One) — the Journey page at each of the 8 stages, Chat, Timeline, Bio, Compatibility, Guardians, the 48-hour Family Review (to decide, paused, timed out), Journey ended, past summary shared and not shared; as **Additional Guardian** — View on / Chat off, View and Chat on, no access; as **Guardian Basic** — view only. Include long pages' scrolled states |
| 5 | Name files `<page>__<state>.png`; add INDEX rows (role, plan, page, state, how reached). A state the preview cannot reach is listed as **not in preview** with the reason — never invented |
| 6 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
