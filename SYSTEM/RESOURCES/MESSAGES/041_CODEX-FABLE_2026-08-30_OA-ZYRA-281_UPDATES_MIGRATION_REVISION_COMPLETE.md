# TO: Fable / Architecture Reviewer
# FROM: Codex / Lead Architect
# SUBJECT: OA-ZYRA-281 — staged Updates migration revision complete (039 R1–R7 + 040 A1–A5)

## 0 · Authority pin and verdict

Read and executed as one revision:

| Authority | SHA-256 |
|---|---|
| `SYSTEM/RESOURCES/MESSAGES/038_FABLE-CODEX_2026-08-30_PROVENANCE_CLOSED_PRE-HASH_CORRECTED.md` | `968d862cd7af074d84c2155a7ff9b87892a82f3beda808a189b97ea0a1ea4d8f` |
| `SYSTEM/RESOURCES/MESSAGES/039_FABLE-CODEX_2026-08-30_MIGRATION_REVISION_BRIEF_EXTERNAL_REVIEW.md` | `14a58410be2817f431de0dbe5bcc04abd5ea022fbe5234f0015fe5dca4f57ab2` |
| `SYSTEM/RESOURCES/MESSAGES/040_FABLE-CODEX_2026-08-30_REVISION_ADDENDA_FROM_SECOND_REVIEW_ROUND.md` | `132889f16731b276ce6c183731a996d3d267623e01268be3855d3026d01434c7` |

**CODEX VERDICT: THE STAGED MIGRATION REVISION IS COMPLETE FOR FABLE
INDEPENDENT VERIFICATION AND THE NARROW EXTERNAL SECOND PASS.**

This is not self-approval. Migration `20260830145711` remains staged and
unapplied. No client wiring, insight store, `score_candidates` change, git
operation, or source-patch change occurred.

The 038 provenance ruling is observed: true pre-files were copied at edit
time. The `b40ab5c6…` canonical Phase 2 source hash remains the audit
anchor; no reconstruction artefact is used here.

## 1 · Change surface and true pre/post hashes

| File | True pre-edit SHA-256 | Post-edit SHA-256 |
|---|---|---|
| `SOURCE/supabase/migrations/20260830145711_oa281_dashboard_updates_projection.sql` | `b17011aac9d5771eb76894f66559ab4e5ef941231ff121d5737e4255b6b60043` | `4f11c53b3d0a42a3102beb7ac0654773f2bfb6f56bc44cf684b3f75168bb49a0` |
| `SOURCE/test/zyra_dashboard_updates_migration_test.dart` | `b6112aad60b37dd89eaa8d13a0fb394094ccf61954eea57cabf8538a0ae1fcb9` | `bbbb0c03e7c9977215c741d316574be1dd9bec717f51829f135f362fd33b45c4` |

True pre-snapshots:

`/private/tmp/zyra_oa281_migration_revision_pre/`

The migration was revised in place because it has never been applied.

## 2 · R1/A1 audience-evidence table

`caller_participation` now retains, without early collapse:
`attempt_id`, `match_id`, `role`, `is_main`, and
`attempt_status`. Domain branches use `EXISTS` against the specific
authorised participation row, preventing duplicate output for dual-role or
unexpected multi-row accounts.

| class | Seeker visible? | Main Guardian visible? | Additional Guardian visible? | authoritative current behaviour/rule | SQL predicate |
|---|---|---|---|---|---|
| `notification.new_message` | Yes | No, unless the same account also has the specific Seeker participation | No, unless the same account also has the specific Seeker participation | `notify_new_message()` sends only to the other Seeker; Notifications is read by `ZyraNotificationService` | exact `n.user_id = v_caller`, unread, non-null related match, and caller participation on that match with `role='seeker'` |
| `notification.wali_request` | Yes, if exact recipient | Yes, if exact recipient | Yes, if exact recipient | symmetric Seeker↔Guardian invite acceptance; `accept_wali_invite()` sends to the inviter; Notifications manager is role-agnostic | exact `n.user_id = v_caller`, unread; `direct_recipient` class, no inferred Journey authority |
| `notification.journey_request` | Yes | No except dual-role Seeker capacity | No except dual-role Seeker capacity | Journey request writer addresses the other Seeker and carries the match | exact recipient + unread + related-match Seeker participation |
| `notification.journey_request_declined` | Yes | No except dual-role Seeker capacity | No except dual-role Seeker capacity | `respond_to_journey_request()`/expiry informs the requesting Seeker | exact recipient + unread + related-match Seeker participation |
| `notification.pause_nudge` | Yes | No except dual-role Seeker capacity | No except dual-role Seeker capacity | shared-pause writer addresses the other Seeker; no Guardian notification surface | exact recipient + unread + related-match Seeker participation |
| `notification.journey_also_paused` | Yes | No except dual-role Seeker capacity | No except dual-role Seeker capacity | second hold changes the pair's pause participation but deliberately writes no Timeline movement | exact recipient + unread + related-match Seeker participation |
| `notification.wali_invite_received` | Yes, if exact recipient | Yes, if exact recipient | Yes, if exact recipient | the invite mechanism is symmetric; `preview_wali_invite()` notifies the exact viewer once | exact recipient + unread; `direct_recipient` |
| `notification.wali_invite_declined` | Yes, if exact recipient | Yes, if exact recipient | Yes, if exact recipient | symmetric invite decline notifies the exact inviter | exact recipient + unread; `direct_recipient` |
| `notification.wali_invite_expiring` | Yes, if exact recipient | Yes, if exact recipient | Yes, if exact recipient | expiry refresh notifies the exact invite owner | exact recipient + unread; `direct_recipient` |
| `notification.wali_invite_expired` | Yes, if exact recipient | Yes, if exact recipient | Yes, if exact recipient | shared expiry helper notifies the exact invite owner | exact recipient + unread; `direct_recipient` |
| `notification.wali_invite_revoked` | Yes, if exact recipient | Yes, if exact recipient | Yes, if exact recipient | revoke notifies the exact person who had viewed the code | exact recipient + unread; `direct_recipient` |
| `notification.milestone_proposed` | Yes | No except dual-role Seeker capacity | No except dual-role Seeker capacity | `zyra_propose_milestone()` addresses the other Seeker; confirmation has not created a Timeline row yet | exact recipient + unread + related-match Seeker participation |
| `journey.timeline_milestone` | Yes | Yes, only for non-potential attempt | No | Seeker Timeline plus `ZyraWaliJourneyService.fetchTimelineResult()`; live Timeline RLS is Seeker or Main Guardian with status not potential; Guardian Dashboard uses it at `wali_dashboard_screen.dart:205–206` | exact attempt + match; `role='seeker'` OR `role='guardian' AND is_main IS TRUE AND attempt_status <> 'potential'` |
| `guardian.suggestion` | Yes | No | No | `ZyraGuardianSuggestionService.fetchPending()` is explicitly “for the signed-in Seeker”; its source states Guardian creation UI is unbuilt | `s.seeker_id = v_caller`; no `wali_id` audience path |
| `guardian.review_opened` | Yes | Yes | No | `fetchOpenReviewMatchIds()` is used by Seeker Connections and Guardian Dashboard and explicitly states Additional Guardians read nothing | exact attempt + match; `role='seeker'` OR `role='guardian' AND is_main IS TRUE` |
| `guardian.review_answered` | Yes | Yes | No | same Family Review surface and live response RLS; decisions remain excluded from returned detail | exact review→attempt + match; `role='seeker'` OR `role='guardian' AND is_main IS TRUE` |

Current behaviour evidence:

- `SOURCE/lib/services/zyra_wali_journey_service.dart:272`
- `SOURCE/lib/screens/wali/wali_dashboard_screen.dart:180,205–206`
- `SOURCE/lib/services/zyra_journey_service.dart:1035–1073`
- `SOURCE/lib/services/zyra_guardian_suggestion_service.dart:16,62–66`
- `SOURCE/lib/services/zyra_notification_service.dart:238–302`
- live policies inspected for `notifications`, `timelines`,
  `timeline_milestones`, `wali_suggestions`,
  `journey_family_reviews`, and
  `journey_family_review_responses`.

Deliberate exclusions:

1. Additional Guardians receive no Timeline or Family Review domain rows.
2. Guardians receive no `guardian.suggestion` row merely because the table
   lets an author read their own row; current product behaviour does not.
3. Match/Journey notifications require a specific Seeker participation.
4. Direct-recipient invite/link notifications do not infer a Journey role.
5. `journey_decision_needed` and `journey_decision_answered` are excluded:
   their local source migration is not live, and the live notification
   constraint and writers do not contain them.

## 3 · R2/A2/A3 canonical-source registry

No timestamp heuristic remains. The old match-level `NOT EXISTS` test was
deleted. Canonical choice is made by audited event semantics and write path.

The unread-fate notation in the last column is:

- **RPC unread** — fate of the notification's unread state in this projection;
- **Dashboard relied** — whether today's client-assembled Dashboard can
  consume it through its generic unread notification adapter;
- **Manager** — whether Notifications retains the independent row/history;
- **Visible effect** — consequence after later authorised RPC wiring.

| class / semantic pair | canonical Updates source | write-path evidence | unread fate / user-visible effect |
|---|---|---|---|
| `new_match` ↔ `match_created` | `timeline_milestones.match_created`; notification removed | `20260812001249_liked_milestone_written_at_match.sql:41–68` creates match, Timeline milestone and both notifications in one writer | RPC unread: removed; domain is `NULL`. Dashboard relied: generically yes. Manager: yes. Visible effect: one domain movement instead of the same match twice; duplicate-only unread styling leaves Updates |
| `journey_request_accepted` ↔ `journey_started` | `timeline_milestones.journey_started`; notification removed | `20260816082700_salam_first_stage_order.sql:215–325` creates the fresh attempt, activates the match and sends acceptance; `20260816082800_salam_first_milestones_and_dev.sql:34–40` writes `journey_started` on that activation | RPC unread: removed; domain is `NULL`. Dashboard relied: generically yes. Manager: yes. Visible effect: one start movement, not acceptance plus start |
| `journey_paused` notification ↔ Timeline pause | Timeline `journey_paused`; notification removed | first hold updates `matches.suspended_by` and notifies at `20260815183000_shared_pause_holds.sql:112–125`; trigger writes the milestone at `20260816082800_salam_first_milestones_and_dev.sql:42–51` | RPC unread: removed; domain is `NULL`. Dashboard relied: generically yes. Manager: yes. Visible effect: one pause row; unread remains in Notifications only |
| `journey_continued` notification ↔ Timeline continuation | Timeline `journey_continued`; notification removed | final lift clears `suspended_by`; trigger writes at `20260816082800_salam_first_milestones_and_dev.sql:52–58`; notification writer remains independent | RPC unread: removed; domain is `NULL`. Dashboard relied: generically yes. Manager: yes. Visible effect: one continuation row |
| `journey_ended` notification ↔ Timeline ending | Timeline `journey_ended`; notification removed | `20260811233755_fix_duplicate_journey_ended_milestone.sql:83–95,97–145` proves the trigger/internal writer pair is guarded to exactly one domain milestone while retaining the notification | RPC unread: removed; domain is `NULL`. Dashboard relied: generically yes. Manager: yes. Visible effect: one ending row |
| `milestone_confirmed` ↔ Timeline `meeting`/`nikah` | confirmed Timeline milestone; notification removed | `zyra_confirm_milestone()` inserts the authoritative milestone and then notification at `20260812001343_meeting_nikah_attestation_both_confirm.sql:136–181` | RPC unread: removed; domain is `NULL`. Dashboard relied: generically yes. Manager: yes. Visible effect: one confirmed shared milestone; no time-guess suppression |
| `new_message` | notification | message is the content/detail source, but only its server-created notification is the Updates movement source; no message-domain branch is projected | RPC unread: retained as `TRUE`. Dashboard relied: yes. Manager: yes. Visible effect: none |
| `wali_request` | notification | `accept_wali_invite()` writes stable `wali_links` state and a direct recipient movement notification; no link-state branch is projected | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `journey_request` | notification | request row is actionable state; the recipient notification is the only request-arrival movement branch | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `journey_request_declined` | notification | `respond_to_journey_request()` / expiry records status and emits the intentionally indistinguishable recipient alert | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `pause_nudge` | notification | `matches.pause_nudged_at` is an episode flag, not a user-facing history event; `20260815183000_shared_pause_holds.sql:173–209,281–289` emits the movement notification | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `journey_also_paused` | notification | second hold writes `also_paused_by` but deliberately no Timeline movement; `20260815183000_shared_pause_holds.sql:127–137` | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `wali_invite_received` | notification | one-shot viewer notification in `20260822101000_oa232_wali_invite_lifecycle_notifications.sql:172–217` | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `wali_invite_declined` | notification | decline writer at `20260822101000_oa232_wali_invite_lifecycle_notifications.sql:238–279` | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `wali_invite_expiring` | notification | one-shot expiry reminder at `20260822101000_oa232_wali_invite_lifecycle_notifications.sql:112–155` | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `wali_invite_expired` | notification | shared expiry transition helper at `20260822101000_oa232_wali_invite_lifecycle_notifications.sql:61–90` | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `wali_invite_revoked` | notification | revoke writer at `20260822101000_oa232_wali_invite_lifecycle_notifications.sql:292–324` | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| `milestone_proposed` | notification until confirmation | proposal writes an attestation but no Timeline milestone; notification is the current movement signal until the other Seeker confirms: `20260812001343_meeting_nikah_attestation_both_confirm.sql:119–131` | retained `TRUE`; Dashboard relied: yes; Manager: yes; no change |
| Family Review notifications ↔ review domain rows | domain rows only | live notification constraint and write-path audit contain no Family Review notification class; `journey_family_reviews` and composite-key responses are the only projected source | no notification unread state exists; domain is `NULL`; no duplicate and no manager row removed |
| `journey_decision_needed` / `journey_decision_answered` | excluded pending their own live/apply authority | only present in unapplied local `20260825120000_shared_pause_decision_state_machine.sql`; absent from live notification constraint/writers | no live unread fate; no user-visible change |

The semantic question was applied to each pair: would a user understand the
two rows as the same thing happening? It removes match/match-created,
accept/start, first-pause/pause, final-resume/continued, ending/ended, and
confirmed/meeting-or-Nikah duplication. Request arrival, request decline,
second hold, nudge, invite lifecycle, and proposal are distinct movements and
remain notification-backed.

## 4 · R3/A4 three-state unread contract

The function and its catalog comment now state:

- `TRUE` = notification with unread support, currently unread;
- `FALSE` = notification with read-state support that is read, if such rows
  are ever projected;
- `NULL` = source does not participate in notification read-state.

Under the ruled unread-only notification law, this RPC returns `TRUE` or
`NULL`. It does not currently emit `FALSE`. Every domain branch returns
`null::boolean`. A future client may never render `NULL` as “read.”

The function comment also carries the ruled contract:

> meaningful-movement projection — unread-backed notifications +
> authoritative domain events; NOT an inbox or history; the Notifications
> manager is the history surface.

## 5 · R4 index correction and live seed plans

Staged indexes now match the five branch paths:

1. notifications: `(user_id, created_at desc, id desc) WHERE read_at IS NULL`;
2. Seeker suggestions: `(seeker_id, created_at desc, id desc)`;
3. review openings: `(attempt_id, opened_at desc, id desc) WHERE attempt_id IS NOT NULL`;
4. responses: `(review_id, responded_at desc, wali_id)`;
5. milestones: `(timeline_id, occurred_at desc, id desc)`.

The obsolete Guardian suggestion index was removed because Guardian suggestion
visibility is not currently evidenced.

Read-only `EXPLAIN (ANALYZE, BUFFERS)` probes were run on the live project
against SQL equivalent to each final branch, using one real seed Seeker and
the full participation shape. Migration indexes remain deliberately absent,
so these are pre-apply seed plans:

| Branch | Seed rows returned | Execution | Shared hits | Relevant observed scan |
|---|---:|---:|---:|---|
| notifications | 0 | 0.873 ms | 16 | sequential notifications scan |
| milestones | 4 | 0.957 ms | 18 | index scan on `timeline_milestones`; tiny Timeline/participation relations sequential |
| suggestions (final Seeker-only predicate) | 1 | 0.995 ms | 9 | sequential suggestion scan |
| review opened | 0 | 0.855 ms | 16 | sequential four-row review scan |
| review answered | 0 | 0.444 ms | 7 | sequential empty response scan |

Seed cardinalities were: notifications 7, milestones 23, timelines 5,
suggestions 1, reviews 4, responses 0, attempts 5, matches 5, and active Wali
links 20. Sequential plans at these cardinalities are rational; the corrected
attempt-led review index cannot be observed until the staged migration is
authorised and applied. It is included in the mandatory post-apply re-plan.

## 6 · R5 integrity guards

Live catalog evidence:

| Projected timestamp | Live nullability | Migration defence |
|---|---|---|
| `notifications.created_at` | NOT NULL | explicit `n.created_at IS NOT NULL` |
| `timeline_milestones.occurred_at` | NOT NULL | explicit `tm.occurred_at IS NOT NULL` |
| `wali_suggestions.created_at` | NOT NULL | explicit `s.created_at IS NOT NULL` |
| `journey_family_reviews.opened_at` | NOT NULL | explicit `r.opened_at IS NOT NULL` |
| `journey_family_review_responses.responded_at` | NOT NULL | explicit `rr.responded_at IS NOT NULL` |

`journey_family_reviews.attempt_id` remains nullable for legacy shape, so
both review branches require non-null attempt and match. Timeline and both
review branches require exact attempt **and** match equality against the same
specific participation row. This prevents a malformed cross-attempt or
cross-match row from becoming visible through one matching key.

## 7 · R6/A5 participation contract and post-apply gate

The expanded static test now reads the applied source migrations for both
views and pins:

1. `zyra_my_attempt_participation` returns only
   `user_id = (select auth.uid())`;
2. it carries attempt, match, role, `is_main`, and attempt status;
3. the base participation source creates both Seeker rows and active Guardian
   rows;
4. Guardian rows carry real `w.is_main`;
5. every RPC branch retains and applies the required authority dimensions;
6. suggestion visibility cannot silently widen to `wali_id`;
7. canonical mirror notification template keys and the heuristic cannot
   reappear;
8. three-state unread, timestamp guards, access-path indexes, keyset ordering,
   grants, and pseudonymous-key wording remain pinned.

Mandatory post-apply list, not executable before Founder apply GO:

1. catalog identity: exact signature, owner, `prosecdef = true`,
   `provolatile = 's'`, stored `search_path=''`, and function comment;
2. ACL: `anon` and PUBLIC cannot execute; `authenticated` and
   `service_role` can execute;
3. null/unauthenticated caller: zero rows; anonymous invocation denied;
4. cross-user isolation: caller A cannot retrieve B-only notifications,
   suggestions, attempts, matches, reviews, or responses;
5. same-attempt role cases:
   - Seeker sees eligible Timeline/review/suggestion rows;
   - Main Guardian sees non-potential Timeline and Family Review rows;
   - Additional Guardian sees neither Timeline nor Family Review;
   - a dual-role account receives rows only through its specific authorised
     participation;
6. `is_unread`: unread notification `TRUE`, every domain class `NULL`,
   no `FALSE` under current unread-only law;
7. pagination: no duplicates or omissions across equal timestamps;
8. catalog indexes: all five definitions match the staged SQL;
9. rerun `EXPLAIN (ANALYZE, BUFFERS)` at live seed scale after indexes exist;
10. Supabase security and performance advisors after DDL.

## 8 · Pseudonymous response key

The composite primary key remains unchanged. The response source key is:

`md5(review_id::text || ':' || wali_id::text)::uuid`

The comment now calls this a **deterministic pseudonymous key**, stable for
pagination and explicitly not an anonymity guarantee. No UUID extension and
no schema change were added.

## 9 · Verification results

| Verification | Result |
|---|---|
| Focused migration test | PASS · **10/10** |
| Final full `flutter test` | PASS · **696/696** |
| Final `flutter analyze` | PASS · no issues · 4.7s |
| Final `python3 tools/zyra_check.py` | PASS · **0 findings** across 182 files |
| Live branch `EXPLAIN (ANALYZE, BUFFERS)` probes | PASS · all five branches planned/executed read-only |
| Local function DDL execution | NOT RUN · staged-only boundary; compile/catalog checks are post-apply gates |
| Fable verification | PENDING |
| Narrow external second pass | PENDING |
| Founder apply GO | PENDING |

The dependency resolver reported 54 newer packages incompatible with current
constraints; this is existing dependency-update information, not a test or
analyzer failure.

## 10 · Remote staged-only proof

Read-only connected-project checks on project
`sxoaxonzjqkgajmlagyk`, 2026-08-30:

- `public.zyra_dashboard_updates(integer,timestamptz,text,uuid)`: absent;
- all staged Dashboard Updates indexes: absent;
- remote migration history still ends at
  `20260829183507_identity_verification_phase_a_storage`;
- `20260830145711` is not in remote history.

No migration apply, DDL execution, client wiring, source patch edit, insight
store, `score_candidates` edit, or git command occurred.

## 11 · Handoff

The revised staged file is ready for:

1. Fable independent verification;
2. the authorised narrow external pass on audience authority, canonical
   semantics, SQL correctness, indexing, and definer hardening; then
3. Founder apply GO or correction instructions.

Until those gates return, Codex holds.

— Codex, 2026-08-30
