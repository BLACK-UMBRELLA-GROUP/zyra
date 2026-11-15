---
id: DOC-ZYRA-0506
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - app side of the Founder's 12 Nov time-rule decisions (QUESTIONS 117, 118)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — TIME RULES — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Source: QUESTIONS **117** (48-hour ready window), **118** and **119** (Founder time-rule decisions). **Server parts belong to Fable** (rows 117–118, OA-ZYRA-317). Build every app part now against preview data; anything that needs a server field that does not exist yet → keep it on preview data and mark this line QUESTION for that part only.

| Step | Detail |
|---|---|
| 1 | Guardian invitation and ZYRA code link request: every shown time and expiry uses **14 days** ("<Name> has 14 days to accept…", Expired after 14 days) — GUARDIAN_CARD V12 |
| 2 | Guardian One upgrade page line: "£19.99 a month · **14 days free to start**", shown only if the App Store product offers it (Q86) — UPGRADE_PAGES V4 |
| 3 | Ready window (row 117): at 48 hours the person who has not tapped gets one reminder — push + My ZYRA Needs-you item "Your Journey with <name> is waiting" · "Tap I'm ready to begin within 24 hours to start." · gold **I'm ready to begin**; the other person sees "Waiting for <name>"; at 72 hours it shows as "Not taken up" for both |
| 4 | "Not taken up" and the ask-again wait: any app copy that says when you can ask the same person again uses **7 days**; ask again after an ended Journey: 24-hour wait, request lasts **30 days** |
| 5 | **Account deleted (Founder 12 Nov 17:19–17:25, replaces the earlier "This member has left ZYRA" wording; QUESTIONS 132/134):** every Journey with that person — active or ended — closes and **disappears for the other Seeker at once**, with its Timeline and its Guardian Circle; Journey requests, Past items and Introductions with that person go too. The Journey place is freed. One My ZYRA Needs-you item, no name kept: **One of your Journeys has ended** / **This profile is no longer active. Your place is free for a new Journey.** / gold **Open Journey**. The words "This member has left ZYRA" (and "Former member") are not used anywhere. Never show the safety copy in the app. Server side is line 94 (Fable, QUESTIONS 134); until then preview data. Prototype V212 (side list **Member left ZYRA → My ZYRA item**) |
| 5b | **Ended Journeys (row 119):** no 3-month limit anywhere in the app (remove "access lasts three months" copy). ••• on an ended Journey: "Request a new Journey" · red **Remove from my Journeys** · Cancel → LOCK 28 confirm sheet "Remove this Journey?" … Remove Journey / Keep Journey → removed from this Seeker's Ended Journeys only, toast "Removed from your Journeys."; cannot be undone. **Block:** while either person has blocked the other, that ended Journey is hidden for **both**; unblock shows it again for both (nothing is deleted by a block). Prototype V202 (My ZYRA → Ended Journeys → •••) |
| 6 | Visual check of the changed screens; tests for each number and the reminder state |
| 7 | Gate: `flutter analyze` clean; no new failures |
| 8 | iPhone on Shakeel's GO only; task note; commit within core rule 2; mark queue line 93 BUILT, FAILED or QUESTION |
