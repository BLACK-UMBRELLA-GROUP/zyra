---
id: DOC-ZYRA-0301
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - capture every planned-app screen at real iPhone size, every reachable state, as the picture baseline the ZYRA chat records each LOCK from (core rule 11). Screenshots only - no code change
links: [DR-ZYRA-274, DOC-ZYRA-0278, DOC-ZYRA-0286, AD-AIOS-115]
owner: ZYRA chat
---

# BASELINE CAPTURE BRIEF — 29 OCT 2026

**Founder decision, 29 Oct 2026:** "Codex screenshots" — the pictures for the planned app's LOCK records come from the real
build, captured by Codex; the ZYRA chat adds states, specs and the Founder's words and records each area's LOCK.

## What to do

| Step | Detail |
|---|---|
| 1 | Run the Founder preview by the **first route that works**, in this order, and say in the task note which one you used: **(a)** the paired iPhone 15 Pro Max, if connected (`./run.sh` profile build); **(b)** an iPhone 15 Pro Max simulator — **you may create one** with `xcrun simctl` if none exists; **(c)** if the native build route is held, the repo's visual test harness (`test/visual/`, the same route that made `candidates/browse_photo_frame_2026_10_10/`): render every page at **430 × 932 logical, device pixel ratio 3** with the app's own tab bar and top bar. Route (c) lacks the iOS status bar; that is acceptable for the baseline — say so in INDEX.md. Only if all three fail: FAILED with the exact blocker. No code changes to the app; a new test file under `test/visual/` for route (c) is allowed and is committed |
| 2 | Capture **every page** listed in DOC-ZYRA-0286 (`PRODUCT/BLUEPRINT/ZYRA_PLANNED_SCREEN_INVENTORY_GENERATED.md`), for **both roles** (Seeker, Guardian), with the real tab bar / top bar on, nothing cropped |
| 3 | For each page, capture **every state the preview can reach** with its local preview controls: normal, empty, loading, error, locked/held, and each tab or option variant. Where the preview has no such state, write "not in preview" in the index — do not invent one |
| 4 | Save PNGs to `PRODUCT/APPROVED/BASELINE/SCREENSHOTS/<role>/<area>/<page_id>__<state>.png` (area = the DOC-ZYRA-0278 §3 area; page_id = the inventory id, e.g. `requests__received_empty.png`). No other folders, no loose files beside subfolders |
| 5 | Write `PRODUCT/APPROVED/BASELINE/SCREENSHOTS/INDEX.md`: one row per picture — role, area, page id, state, how it was reached (taps / preview control), file path. Mark pages or states that could not be captured and why |
| 6 | Write `PRODUCT/APPROVED/BASELINE/SCREENSHOTS/BUILD.json` (core rule 8): commit SHA, Flutter version, build mode, device model and resolution, timestamp |
| 7 | Task note in `BLACK UMBRELLA GROUP/REPORTS/DAILY/` — "Built from: not a design task (capture)", picture count, disk size, any page the inventory lists that the app no longer opens |
| 8 | Commit and push within core rule 2 (no file over 50 MB; expect 150–250 PNGs). Mark the queue line BUILT (or FAILED, with why) and add the task-note date |

## Do not

- Change any code, design, wording or asset. If something looks wrong, note it in the task note — do not fix it.
- Touch `PRODUCT/BLUEPRINT/` or anything else under `PRODUCT/APPROVED/` outside `BASELINE/SCREENSHOTS/`.
- Capture with developer controls visible unless the state needs them (then capture once with, once without).

## Change log

| Date | Change |
|---|---|
| 2026-10-29 15:33 | Queue line 1 FAILED: phone disconnected, no matching simulator, native route held (Codex task 6) |
| 2026-10-29 15:45 | Step 1 rewritten by the ZYRA chat: three routes in order, simulator creation allowed, visual-test render as the fallback. Re-queued as line 2 |

## Check (the ZYRA chat)

INDEX rows cover all 49 pages × both roles where the page exists for that role; every PNG at the device's native size with
bars on; BUILD.json present; no code diff in the commit. Result goes in the ZYRA chat note (charter rule 8).
