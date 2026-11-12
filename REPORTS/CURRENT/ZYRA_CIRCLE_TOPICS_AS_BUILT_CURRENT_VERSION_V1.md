---
id: AS-BUILT-ZYRA-LOCK20-V4
type: HANDOVER
status: CURRENT
feature: GUARDIAN CIRCLE
purpose: As-built handover for Guardian Circle unread counts and mute in the Founder preview
links: [AD-AIOS-115, DR-ZYRA-344, DOC-ZYRA-0391, OA-ZYRA-317]
owner: Codex
---

# Guardian Circle unread and mute

Queue line 103 implements LOCK 20 V4 §0 for the Seeker and Guardian Founder preview. Entry is through the Seeker’s Guardian tab or the Guardian’s linked Seeker page. Main is the catch-up transcript and opening it clears Main’s own unread messages. Journey tabs and Past rows clear the exact opened chat. The selected pill is blank. Past totals exclude muted chats, and unread, unmuted chats sort by latest message before the remaining rows sort by Journey end date. The Circle menu can mute an open chat or the entire Circle. The Past list shows only the whole-Circle control.

`SOURCE/lib/dev/zyra_circle_topics_presentation.dart` renders the pills, rows and mute indicators. `zyra_conversation_unread_badge.dart` shares the LOCK 17 count rendering with the existing conversation button. `zyra_one_journey_circle_topics_state.dart` is part of `SOURCE/lib/screens/wali/family_messaging_screens.dart` and owns read clearing, ordering, and guarded sheet actions. Guardian Basic keeps read-only access. Each Past item requires the admitted archive, and the Guardian’s Past view still requires shared summaries.

`zyra_guardian_circle_preview.dart` carries the caller-owned transcript and tags. `zyra_one_journey_concept_shell.dart` owns receipts and mute preferences by Circle and viewer, and forwards eligible unread messages to My ZYRA and tab attention. `zyra_one_journey_guardian_tabs.dart` renders the Guardian’s My ZYRA items. `zyra_preview_navigation_checkpoint.dart` carries the state in memory across the existing preview checkpoint. Whole-Circle mute suppresses attention and retains unread counts. Per-chat mute retains messages and shows muted counts in grey. A fresh preview starts without unread counts. The existing offline arrival fixture supplies messages for verification.

**Server gate** · Q138, OA-ZYRA-317. The available read and mute calls address the whole Circle. Fable owns the server contract for per-member, per-chat read state, mute state and notification suppression. The member server path uses its existing contract. There are no migrations, deployment or device delivery in this line.

**Verification** · `SOURCE/test/visual/line103_circle_unread_and_mute_test.dart` drives both preview routes. `SOURCE/test/guardian_circle_topics_test.dart` covers the existing Circle menu and retained action guards. The full baseline and candidate results, analyser, 430 × 932 captures and archived V222 reference are recorded under `REPORTS/EVIDENCE/OA-ZYRA-317_LINE103_2026-11-12/`. Independent review checked the code and screenshots. Fable and the ZYRA design chat retain handover review.
