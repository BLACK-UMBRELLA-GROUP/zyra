---
id: SERVER1-TIME-RULES-2026-11-12
type: HANDOVER
status: CURRENT
feature: SERVER 1
purpose: Record the Founder-approved ready reminder, close and retry times for SERVER 1
links: [DOC-ZYRA-0473, DOC-ZYRA-0329, DOC-ZYRA-0283, OA-ZYRA-317]
owner: Fable
---

# SERVER 1 · Accepted Journey request timing

QUESTIONS 117, 118 and 128 set the SERVER 1 timers. Measure the ready window from acceptance.

| Time | Server action |
|---|---|
| 48 hours | Send one reminder to each person who has yet to mark themselves ready. |
| 72 hours | If either person is still waiting to mark themselves ready, close the request as “Not taken up” for both and free both Journey places. |
| After “Not taken up” (Q128) | Wait 7 days after the 1st–4th consecutive result, 14 days after the 5th–9th, and 30 days after the 10th onward. |

Count separately in each direction. Declines, expiries and the 72-hour close count as consecutive “Not taken up” outcomes. A sender’s own cancellation adds no count or wait. A request between the pair that begins a Journey resets the count to zero. Hides and blocks still stop requests. Return `ask_again_after` and `wait_days` to the sender only. The count stays on the server. The ready-state contract uses `ready_deadline_at`, `reminder_sent_at` and `closed_reason` (`not_taken_up`).

Track this work under OA-ZYRA-317 and DOC-ZYRA-0329 area 1. The SERVER 1 request flow is pending.

## Photo cleanup and signing

Line 94 caps the current app's display-photo signing requests at 3,600 seconds. Account deletion removes the gallery rows and revokes new signing access immediately. Signup can sign an owned staging upload while its Auth account exists and the path remains available.

At the Founder's live apply, configure pg_cron and pg_net to invoke the service-owned `zyra-photo-cleanup` worker every hour. Check run results and `zyra_photo_cleanup_failures` for 24-hour deadlines and objects that exhaust 10 attempts. The existing worker processes up to 12 paths per run. Confirm queue capacity and hosted Storage delivery during the live checks under OA-ZYRA-317. The hourly schedule is pending.

SERVER 1 owns a server-side photo signing function that fixes the TTL at 3,600 seconds or less and verifies current photo access before signing. Its acceptance checks cover custom clients and previously issued URLs. Track the member-facing expiry and removal wording under Q131.

## Line 94 V4 server handover

**Authority** DOC-ZYRA-0473 V4, Q117–120, Q123–128, Q130–131, Q133–134 and OA-ZYRA-317. Verified on disposable PostgreSQL. Production apply remains pending.

- Guardian invitations and ZYRA Code link requests last 14 days on new rows. The invitation RPC keeps the ten-place guard and leaves direct writes revoked. Restart eligibility begins after 24 hours and a restart request expires after 30 days. Billing grace has a three-day cap. A verified person can claim the 14-day Guardian One trial once. Deletion leaves the verified-person claim key.
- `delete_own_account()` queues exact photo paths and runs account erasure in one transaction. It clears active and ended Journey participation, Timeline and messages from member and Guardian reads, removes requests and introductions involving the deleted profile, and frees Journey places. Each remaining Seeker with an affected Journey receives one `journey_ended_profile_inactive` notification with an empty JSON object and no match link. The app's approved My ZYRA copy is recorded on the notification row.
- The repository's Circle is one transcript per owning Seeker. The transaction seals the entire deleted Seeker's Circle and removes their own contributions to remaining Circles. The per-Journey Circle topics in the preview have no server conversation key yet. Whole Journey transcripts from both sides go into private `safety_sealed_messages`, with a 365-day purge. Active Journey safety cases and holds keep protected evidence in private custody until closure. Open Circle cases and legal holds keep their sealed context while protection applies. Reports and hold release history survive with detached references.
- Ended Journeys have no time limit. Block temporarily hides both sides. `zyra_remove_ended_journey` removes only the caller's attempt; when both copies are removed, cleanup observes holds and open cases and keeps the minimal reveal reference for an active dependent restart.
- `zyra_touch_activity` is the launch and foreground event. The backfill uses sign-in, authored content, requests, answers and account creation. Only accounts with Ended Journeys enter the inactivity cycle. Outbox dates are 14 and 7 days before the second anniversary, the anniversary, 7 days after and removal at 14 days after. Return cancels pending removal and makes `zyra_my_welcome_back` available once.
- The checked SQL migrations and rollback fixtures are in `SOURCE/supabase/migrations` and `SOURCE/supabase/tests` under Line 94. The daily inactivity and retention entry points were called in replay. Hosted scheduling, email delivery, the live client hookup and the privacy notice follow-up remain under OA-ZYRA-317. Administrative Auth deletion is outside the photo queue entry point.
