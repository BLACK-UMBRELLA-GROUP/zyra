---
id: AS-BUILT-ZYRA-LOCK20-V4
type: HANDOVER
status: CURRENT
feature: GUARDIAN CIRCLE
purpose: As-built handover for Guardian Circle unread counts and mute in the Founder preview
links: [AD-AIOS-115, DR-ZYRA-344, DOC-ZYRA-0391, OA-ZYRA-317, OA-ZYRA-325]
owner: Codex
---

# Guardian Circle unread and mute

Queue line 103 implements LOCK 20 V4 §0 for the Seeker and Guardian Founder preview. Entry is through the Seeker’s Guardian tab or the Guardian’s linked Seeker page. Main is the catch-up transcript and opening it clears Main’s own unread messages. Journey tabs and Past rows clear the exact opened chat. The selected pill is blank. Past totals exclude muted chats, and unread, unmuted chats sort by latest message before the remaining rows sort by Journey end date. The Circle menu can mute an open chat or the entire Circle. The Past list shows only the whole-Circle control.

Main shows the gold **UNREAD MESSAGES** divider before the first unread Main message on entry, including on checkpoint restore. The shell records the reads immediately and hands off only the Circle, viewer, message and sender IDs for that divider. The Topics reader checks the hint against its admitted Main transcript on initial load. Arrivals preserve the displayed divider while the exact message is present in Main. Leaving Main clears the local divider, and reopening Main or restoring a checkpoint recalculates it from current unread messages. Checkpoints carry read keys.

`SOURCE/lib/dev/zyra_circle_topics_presentation.dart` renders the pills, rows and mute indicators. `zyra_conversation_unread_badge.dart` shares the LOCK 17 count rendering with the existing conversation button. `zyra_one_journey_circle_topics_state.dart` is part of `SOURCE/lib/screens/wali/family_messaging_screens.dart` and owns read clearing, ordering, and guarded sheet actions. Guardian Basic keeps read-only access. Each Past item requires the admitted archive, and the Guardian’s Past view still requires shared summaries.

`zyra_guardian_circle_preview.dart` carries the caller-owned transcript and tags. `zyra_one_journey_concept_shell.dart` owns receipts and mute preferences by Circle and viewer, and forwards eligible unread messages to My ZYRA and tab attention. `zyra_one_journey_guardian_tabs.dart` renders the Guardian’s My ZYRA items. `zyra_preview_navigation_checkpoint.dart` carries the state in memory across the existing preview checkpoint. Whole-Circle mute suppresses attention and retains unread counts. Per-chat mute retains messages and shows muted counts in grey. A fresh preview starts without unread counts. The existing offline arrival fixture supplies messages for verification.

**Server gate** · Q138, OA-ZYRA-317. The available read and mute calls address the whole Circle. Fable owns the server contract for per-member, per-chat read state, mute state and notification suppression. The member server path uses its existing contract. There are no migrations, deployment or device delivery in this line.

**13 November follow-up** · Based on `c22d9eb`, after the line 105 follow-up. Uses `PRODUCT/APPROVED/GUARDIAN_CIRCLE/BRIEFS/BUILD_BRIEF_2026-11-12_V4.md` and `PRODUCT/APPROVED/GUARDIAN_CIRCLE/RECORD/GUARDIAN_CIRCLE_SPEC_CURRENT_VERSION_V4.md` §0 (Clears) and §2 (Transcript, gc01). `SOURCE/lib/dev/zyra_one_journey_concept_shell.dart` captures and consumes the hint. `SOURCE/lib/dev/zyra_guardian_circle_preview.dart` carries it in route-local Topics metadata. `SOURCE/lib/screens/wali/family_messaging_screens.dart` validates the hint and `SOURCE/lib/dev/zyra_one_journey_circle_topics_state.dart` manages the divider as messages and selections change. The existing arrival fixture supplies offline test input. No migrations or device checks.

**Back routing** · The inherited Guardian View Journey return is tracked with Q24 under OA-ZYRA-325. The original Line 103 evidence records the matching baseline and candidate failure for returning to the same Topics draft. The divider follow-up covers closing and reopening Circle from its parent.

**Verification** · `SOURCE/test/visual/line103_circle_unread_and_mute_test.dart` drives both preview routes. `SOURCE/test/guardian_circle_topics_test.dart` covers the existing Circle menu and retained action guards. The original Line 103 full baseline and candidate results, analyser, 430 × 932 captures and archived V222 reference are recorded under `REPORTS/EVIDENCE/OA-ZYRA-317_LINE103_2026-11-12/`. The original review checked that code and those screenshots. Fable and the ZYRA design chat retain handover review.

The follow-up used Flutter 3.44.2. `flutter analyze --no-pub` passed. Four Line 103 cases reproduced the missing divider at the baseline and pass with the fix. Both viewer roles are checked through actual entry, checkpoint restore, new arrivals, removal of the divider message, and reopen. The affected run also passed the LOCK 17 raw read and account isolation checks, Circle Topics and source tests, preview authority tests, and family messaging foundation tests. The run passed 96 tests. Two 430 × 932 offline widget captures show the divider before the first unread Main message and match the placement and gold treatment in gc01. See `REPORTS/EVIDENCE/OA-ZYRA-317_LINE103_MAIN_DIVIDER_2026-11-13/` for the captures and test results.

From `SOURCE/`, rerun the affected tests and compare the two captures with:

```sh
flutter test --no-pub \
  --dart-define=ZYRA_BASELINE_COMPARE_ONLY=true \
  --dart-define=ZYRA_LINE103_DIVIDER_CAPTURE=true \
  test/visual/line103_circle_unread_and_mute_test.dart \
  test/lock17_circle_unread_integration_test.dart \
  test/guardian_circle_topics_source_test.dart \
  test/guardian_circle_topics_test.dart \
  test/family_circle_preview_authority_test.dart \
  test/family_messaging_foundation_test.dart
```
