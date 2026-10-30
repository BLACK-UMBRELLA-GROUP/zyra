---
id: DOC-ZYRA-0317
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 5 - gold tab icons signal new activity and clear when the tab is opened
links: [DOC-ZYRA-0282]
owner: ZYRA chat
---

# TAB ICON ATTENTION — SPEC — V1 (LOCKED 29 OCT 2026)

| Item | Rule |
|---|---|
| Meaning of gold | A tab icon in the bottom bar is gold **only** when that tab has something new for the member (today: My ZYRA with an unseen received Journey request, `_hasNewReceivedRequests`). Gold is never decoration |
| Clearing | **Opening that tab clears the gold at once** — tapping the icon is enough; the member does not have to open the request itself. (Today the gold stays until the request is viewed.) |
| Coming back | The gold returns only when something **new** arrives after that tab was last opened |
| Inside the tab | Unchanged: the "New activity" heading and any per-item gold dots inside My ZYRA keep their current rules |
| Other tabs | Same rule for any tab that later gets new-activity gold (e.g. Guardian Circle messages) |
| Selected tab | The gold ring around the selected tab is the selection marker, not attention — unchanged |
| Masters | `../MASTERS/tab_bar__my_zyra_new_activity_gold.png` (before), `../MASTERS/tab_bar__my_zyra_seen_plain.png` (after opening My ZYRA and coming back) |

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-10-29 | V1 | LOCKed by the Founder |
