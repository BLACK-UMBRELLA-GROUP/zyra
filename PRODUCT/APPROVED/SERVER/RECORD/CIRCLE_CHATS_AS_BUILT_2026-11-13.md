---
id: ASBUILT-ZYRA-LINE107-CIRCLE-CHATS
type: HANDOVER
status: CURRENT
feature: GUARDIAN CIRCLE
purpose: As-built Guardian Circle chat contract for disposable database verification
links: [DOC-ZYRA-0510, DOC-ZYRA-0391, DR-ZYRA-344, OA-ZYRA-317, OA-ZYRA-340]
owner: Codex
---

# Guardian Circle chats · server handover

**Live: no.** Queue line 107 implements DOC-ZYRA-0510, Q138 and the 13 November 07:55 corrections in Q141. LOCK 20 V4 governs unread and mute. LOCK 20 V3 and DR-ZYRA-344 keep Past chats open without a time cutoff. Journey sends require the line 94 V4 archive and account-deletion schema.

## Entry points and storage

| Entry point | Behaviour |
|---|---|
| `zyra_family_message_chats(p_thread_id)` | Returns each admitted chat's UUID, kind, current or Past state, permitted counterpart name, last message and end timestamps, unread count, both mute flags, `counts_toward_total` and `alerts_on`. |
| `zyra_mark_family_chat_read(p_chat_id)` | Advances only the caller's read timestamp for this chat and marks the caller's pending alert read. |
| `zyra_set_family_chat_muted(p_chat_id, p_muted)` | Changes only the caller's mute for this chat. The existing whole-Circle mute RPC keeps its scope. |
| `zyra_send_family_message(p_thread, p_body[, p_chat_id])` | Omitted or null chat ID selects Main. An explicit ID must belong to the Circle and be admitted for the caller. The existing send entitlement, length and rate checks apply. |

`family_message_chats` stores one Main per Circle and one Journey chat per Circle and started attempt. The upgrade backfills legacy messages into Main. Journey end preserves the chat ID and restart gets a new ID. The authenticated transcript filters `family_messages` by `chat_id` under row-level access. Main requires active Circle membership. Current Journey admission checks the Circle's Seeker, Main Guardian or assigned Guardian as applicable. Past admission uses the Seeker's archived copy and current Guardian summary-sharing authority. Membership epochs, blocking and safety restrictions still apply. The legacy transcript and Circle summary RPCs read Main. The legacy whole-thread read advances that caller's inherited watermark.

`family_message_chat_state` stores read and mute timestamps per member and chat. Unread counts include messages from other members after the latest applicable read or admission timestamp. Lifecycle messages are excluded. An individually muted chat keeps its unread count and contributes zero to the total. Whole-Circle mute preserves the total. `alerts_on` is true when both mute switches are off.

## Alerts and lifecycle

An eligible send writes or refreshes one unread `circle_message` per admitted active recipient and chat. The payload is the fixed title **Guardian Circle**, the fixed body **New message in your Guardian Circle**, and the opaque `related_chat_id`. The recipient's latest `circle` notification preference defaults to on. Muted and opted-out arrivals produce no event, including after unmute or opt-in. An existing unread event refreshes its arrival time. Opening the chat through its read RPC marks the event read. A fresh membership epoch hides earlier events and starts a new event on its first eligible arrival. The send, read and mute RPCs serialize their writes on the Circle. Circle event acknowledgement uses the Circle RPCs. The legacy notification API can still mark its other event types read.

The server feed for My ZYRA and tab attention is the caller's RLS-filtered `notifications` rows with `type = 'circle_message'` and `read_at is null`. Use `id`, `related_chat_id` and `created_at` to identify and order events. Arrival decides alert delivery. The current app preview still uses sample data. The legacy generic badge can count all unread types, so the planned consumers need wiring before live use under OA-ZYRA-317. Push is deferred under OA-ZYRA-317 item 9.

Removing an ended Journey hides the owning Seeker's chat and alerts from their Circle. Mutual removal purges the chat with its attempt when protection permits. Counterpart account deletion seals affected transcripts in private custody and removes their Circle chats and alerts immediately. Open reports and protection holds retain hidden evidence through the existing line 94 custody and purge flow.

## Files and verification

- `SOURCE/supabase/staging/20261113075511_line107_circle_chat_foundation.sql` contains the transaction, backfill, access checks, RPCs, alerts and line 94 lifecycle integration. It follows the line 94 V4 migrations and stays in staging. The transaction verifies the expected line 94 departure-trigger text before extending it and aborts on a mismatch. On a disposable run, roll back by discarding the database.
- `SOURCE/supabase/tests/line107_circle_chats_assertions.sql` checks the contract using synthetic Seekers and Guardians. The SQL fixture rolls back. The deployed app has no new developer control.
- The local build queue marks only line 107. Its source row and server brief were already in the shared working tree. The public commit contains this handover and the SQL change.

The existing server send entitlement remains in force. Guardian Basic access parity, app consumers, hosted transport and apply are tracked under OA-ZYRA-317. Before live use, Fable reviews the staging SQL and handover, the app owner verifies consumer wiring, and Shakeel authorises the apply. The current work uses disposable PostgreSQL.

### Disposable replay results

PostgreSQL 17.6 from the existing `public.ecr.aws/supabase/postgres:17.6.1.147` image ran with networking disabled and no host port. The replay used `ad9178093dcb0a50e9c3d1f4909ab2c0886f95cf` as its baseline, with 244 repository migrations and the two existing OA-ZYRA-198 historical replay bridges. Both empty and populated upgrades used the exact staging SQL. Its SHA-256 is `0031a102cf6516e7011e45a80e6d09d7d02748abcd446200ac154d68452be2c7`.

| Check | Result |
|---|---|
| Ordered baseline replay | 246 migration files passed |
| Line 107 fixture | 81 assertions passed |
| Populated upgrade from legacy Circle data | 26 assertions passed |
| Line 94 time, invitation, deletion, archive, activity and photo regression fixtures | 204 assertions passed |
| Line 106 code-check limit and Server 0 combined fixtures | 63 assertions passed |
| `plpgsql_check` over the changed functions and triggers | 0 diagnostics |

The six line 94 suites, line 106 and Server 0 combined also passed before the candidate was applied. The older `server0_v2_contract_assertions.sql` (departed-sender message expectation) and `server0_v2_restart_preparation_assertions.sql` (internal RPC grants) failed at their same assertions before and after the change. They are outside line 107. Independent source review found no line 107 blocker. Hosted transport and device checks are outside this disposable server run.

To replay on a fresh disposable database at the same baseline, apply the staging file with `psql -X -v ON_ERROR_STOP=1 -f` and then run `line107_circle_chats_assertions.sql` from the tests directory, keeping its relative fixture path available. Run the same assertion files against the baseline and candidate for regressions. For the populated upgrade, seed the legacy Circle thread, memberships, messages and participant state before applying staging, then verify the IDs, Main backfill and caller-scoped reads and mutes.
