---
id: DOC-ZYRA-0510
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex server brief - Guardian Circle chats with stable ids (Main, current Journey, Past), per-member read and mute, muted-chat notification rules (LOCK 20 V4, QUESTIONS 138), throw-away databases only
links: [AD-AIOS-115, OA-ZYRA-317, OA-ZYRA-340, DR-ZYRA-334]
owner: Fable
---

# SERVER BRIEF — GUARDIAN CIRCLE CHATS — 13 NOV 2026

**Founder-named task** (LOCK 20 V4, queue line 103; QUESTIONS 138 answered by Fable). The exact contract is the Answer cells
of QUESTIONS **138 and 141** (141 wins where they differ: Past always open, whole-Circle mute keeps counts, the alert event). **Throw-away databases only - no live apply, no deploy.** No downloads, no installs.

| Step | Detail |
|---|---|
| 1 | Table `family_message_chats` + backfill: one **Main** chat per existing Circle thread; every existing message gets `chat_id` = that Main chat |
| 2 | Journey chats: created when a Journey attempt of the Circle's Seeker begins; same id for life (current → Past by the attempt's end) |
| 3 | Table `family_message_chat_state` (per member, per chat: `last_read_at`, `muted_at`); whole-Circle mute and its counts stay on `family_message_participant_state` unchanged |
| 4 | Reads and writes exactly as row 138: `zyra_family_message_chats`, `zyra_mark_family_chat_read`, `zyra_set_family_chat_muted`; `zyra_send_family_message` gains `p_chat_id` (Main when null) |
| 5 | Alerts as row 141: `circle_message` rows written at arrival for recipients with `alerts_on`, one unread row per chat, no message text or names, no catch-up after unmute; push deferred. Journey-chat sends only when line 94 is BUILT |
| 6 | Tests: ids stable across end and restart; access per chat (Main for every Circle member, Journey chats only with access to that attempt, Past always open (LOCK 20 V3, DR-ZYRA-344)); counts exclude own and lifecycle messages; mark read is per chat and per member; muted chat and muted Circle send no notification; whole-Circle mute still works as before |
| 7 | Task note; commit within core rule 2; BUILT, FAILED or QUESTION |
