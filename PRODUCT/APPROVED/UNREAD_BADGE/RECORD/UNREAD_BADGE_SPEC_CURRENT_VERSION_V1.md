---
id: TBC (Fable assigns)
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 17 - unread-count bubble on conversation icons (gold)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# UNREAD BUBBLE — SPEC — V1 (LOCKED 31 OCT 2026)

Master (430 × 932 @3x, Ivory, prototype V104): `../MASTERS/u01_guardian_tab_circle_unread.png`.

| Item | Rule |
|---|---|
| What | A small round bubble with the number of unread messages, on the top-right of an icon button that opens a conversation |
| Where | Seeker Guardian tab header — the Guardian Circle button (whatever Guardian tab layout is current). Same component on every other icon button that opens a conversation with unread messages (e.g. a Circle or Guardian chat icon), Seeker and Guardian |
| Look | Height 16, min width 16, fully round (8); padding 0 4; number 10 pt semibold; **fill `#C08A3A` (gold), number `#2B2420`** (5.0 : 1); 2 pt ring in the page background colour; sits −3 / −3 from the button's top-right |
| Count | 1–9 shows the number; 10 or more shows "9+"; 0 = no bubble |
| Clears | When the conversation is opened (messages marked read) |
| Not | No red (red means danger in ZYRA); no bubble on non-conversation buttons; tab-bar attention stays the LOCK 5 gold icon |
