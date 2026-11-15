---
id: DOC-ZYRA-0485
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 20 V4 - unread bubbles on Circle tab pills and Past rows, unread first, mute one chat
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN CIRCLE V4 — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Reference: prototype V222 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`). Layout from the app's existing components.

Spec: `GUARDIAN_CIRCLE/RECORD/GUARDIAN_CIRCLE_SPEC_CURRENT_VERSION_V4.md` §0 (LOCK 20 V4). Seeker and Guardian sides.

| Step | Detail |
|---|---|
| 1 | Reuse the existing unread bubble component (UNREAD_BADGE V1) — do not draw a new one. Add it to each Circle tab pill (top-right, −3/−3, tab total; none on the current pill) and to each Past row before the › |
| 2 | Past list order: unread (and not muted) first, newest message first; then newest-ended first |
| 3 | Opening a chat marks it read; bubbles and totals update |
| 4 | ••• sheet: "Mute the Main chat" / "Mute <first name>’s chat" for the chat you are in, then "Mute the whole Circle"; Unmute variants with "Muted" on the right; on the Past list only the whole-Circle row |
| 5 | Muted chat: no push / My ZYRA / tab attention; bell-off 13 pt after its name; grey bubble (#D9D0C2 / #5C5048); excluded from totals; not moved to the top; toasts as spec. Per member, per chat. If the server has no per-chat mute yet, keep it on preview data and mark this line QUESTION for that part (Fable) |
| 6 | Tests for counts, 9+, order, clearing, mute rules |
| 7 | Gate: `flutter analyze` clean; no new failures. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
