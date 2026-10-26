---
id: DOC-ZYRA-0293
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 (Messaging) - when Seekers can message in a Journey, what Guardians can read and write, read receipts, notifications, what blocks, pauses and endings do to a conversation, the archive, and the Guardian Circle - each marked built, different or missing, with its decision
links: [OA-ZYRA-309, OA-ZYRA-317, OA-ZYRA-319, DOC-ZYRA-0283, DOC-ZYRA-0290]
owner: Fable
---

# ZYRA BLUEPRINT — PART 2 — MESSAGING RULES — V1 (DRAFT)

Status: **DRAFT for Shakeel.** Written 26 Oct 2026 from the planned app (`conversationOpen`, the Journey page's Messages) and the
server (`conversations`, `messages`, their security rules, triggers and the Guardian Circle functions). Last column: **Built** ·
**Different** · **Missing**. Server rules were checked by reading the migrations, not by running them.


> **How to read the server column (added 26 Oct, after the live check DOC-ZYRA-0294):** "Built" here means **in the repository
> files**. Production is about two months behind. Not live today: per-Guardian View/Chat switches and agreed access
> (`zyra_set_guardian_journey_permission`), Family places, the Main-Guardian Journey hold, the Guardian Circle, read receipts,
> the verified trial, Browse ranking (`zyra_browse_ranked_ids`) and the 5 Oct security fixes. Everything else marked Built is live.

## In one paragraph

In a Journey, the two Seekers talk through the stages (Salam, answers, Family questions); the **free conversation opens only at
the last stage, Open Conversation**, once the last 48-hour Family Review has passed. Main Guardians and included Additional
Guardians can read it, and can write only if they are paid and allowed. A block ends the Journey and closes the conversation;
an ended Journey's messages stay readable as an archive for three months. Families also talk in the **Guardian Circle**, which is
built but not live. **One serious problem was found:** in the newest version of the database files, the rule that decides who
may send a message no longer checks blocks or whether the Journey has ended, and two of those files cannot be applied one after
the other (§6).

## 1. When Seekers can message

| Rule | Decision | Server |
|---|---|---|
| Stages 1–7 use structured steps (Salam, reveals, answers), not free chat | DR-ZYRA-190, DR-ZYRA-110 | **Built** |
| Free conversation opens at stage 8, Open Conversation, when the last Family Review passes | DR-ZYRA-110, DR-ZYRA-277 | **Different** — the server marks the conversation active at stage 8, but the current send rule does not check that mark (§6), so only the app holds it back |
| Only while both Seekers have a Main Guardian; End still works | DR-ZYRA-236 | **Built** — trigger on `messages` |
| The first message adds "Conversation started" to the Timeline | — | **Built** — trigger `create_conversation_started_milestone` |

## 2. Guardians and messages

| Rule | Decision | Server |
|---|---|---|
| Main and included Additional Guardians can read an active Journey's conversation | DR-ZYRA-232 | **Built** — `messages_select` |
| They can write only with Chat allowed and a paid Guardian role | DR-ZYRA-232, DR-ZYRA-268 | **Different** — the send rule checks the Chat switch but not the Guardian's paid role |
| Guardians never see ended or not-yet-begun Journeys' messages | DR-ZYRA-233 | **Built** (5 Oct read rules) |

## 3. Receipts and notifications

| Rule | Decision | Server |
|---|---|---|
| A small "seen" receipt under your latest message | — | **Built** — `zyra_mark_journey_messages_read` |
| The other person gets an in-app notification for a new message | — | **Built** — trigger `notify_new_message` |
| Phone push notifications | DR-ZYRA-278 | **Missing** |

## 4. Blocks, endings and the archive

| Rule | Decision | Server |
|---|---|---|
| A block ends the Journey (reason recorded as safety concern) and closes the conversation | DR-ZYRA-131 | **Built** — `zyra_block_user` → `zyra_end_match_internal` |
| No one can send into a blocked or ended Journey | DR-ZYRA-131 (9 Aug fix) | **At risk** — see §6 |
| An ended Journey's messages stay readable to the two Seekers for three months; never reopened | DR-ZYRA-268, DR-ZYRA-280 | read **Built**; 3-month limit **Missing** |
| A blocked person shows as "User not found", not as archived content | DR-ZYRA-268 | app |
| ~~Pause freezes the conversation~~ | Pause retired (DR-ZYRA-274) | remove the pause lock on `messages` in the clean-up |

## 5. Guardian Circle

Rules are in the Guardian page (DOC-ZYRA-0290 §6): one transcript with Journey discussion cards; every member needs their own
paid role; mute, report, read receipts, time-limited storage. **Built, not live** (release switch off; OA-ZYRA-298 not applied).

## 6. Found while mapping — serious (OA-ZYRA-319)

| # | Finding | Why it matters |
|---|---|---|
| 1 | **The send rule lost its safety checks.** On 9 Aug the rule for sending a Journey message was fixed to refuse blocked people, closed conversations and ended Journeys. The 24 Sep "paid-only" file replaced it with a version that checks only that you are a participant and the Journey is not just "potential" | If that file is live, a blocked or ended counterpart could still post into the old conversation |
| 2 | **Two database files cannot be applied one after the other.** The 24 Sep file builds the participants list with a "can chat" column; the 5 Oct file rebuilds the same list without it. The database refuses to drop a column that way, so replaying all migrations in order would stop at 5 Oct | The app cannot be rebuilt from its files as they are — the core aim of this blueprint. It also shows production and the files differ (the 24 Sep file is marked "staging only") |
| 3 | Guardian send rule checks the Chat switch but not the Guardian's own paid role | Guardian Basic could send if their switch is on (DR-ZYRA-268 says no) |

**Live check 26 Oct (DOC-ZYRA-0294):** production still has the safe 9 Aug rule — finding 1 is **not live**. Findings 2 and 3
are repository problems that must be fixed before any of those files are applied. A test replay on a throw-away database
will confirm finding 2.

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft (OA-ZYRA-309) |
