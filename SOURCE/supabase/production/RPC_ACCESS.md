# Owner-rights routine access

Line 110 reviews the `SECURITY DEFINER` routines with an effective `authenticated` EXECUTE grant in the ZYRA schema. The disposable clean database has 132 public signatures and eight private signatures in this inventory, with no anonymous grant. Overloads are listed separately. Function grants and schema visibility are separate. `private` is excluded from the Data API and its policy and view helpers are called within the database.

## Public routines

| Signature | Access boundary |
|---|---|
| `accept_wali_invite(text, text)` | Requires a pending legacy invitation token, complementary roles and available Guardian capacity. |
| `ages_for(uuid[])` | Caps lookup at 50 IDs and returns ages only for profiles visible to the caller. |
| `ages_for_one(uuid)` | Returns the age only for a profile visible to the caller. |
| `delete_own_account()` | Queues cleanup and erases the caller's Auth account. |
| `end_journey(uuid)` | Checks the caller is a Seeker in the specified Journey before ending it. |
| `end_journey(uuid, text)` | Checks the caller is a Seeker in the specified Journey before ending it. |
| `guardians_for_unlocked(uuid)` | Requires the caller's Plus unlock and checks current blocking state. |
| `nudge_paused_journey(uuid)` | Requires a Seeker party who did not pause the Journey and applies the nudge guard. |
| `open_family_review(uuid, text, text)` | Requires a Seeker party eligible to open the review at the supplied stage. |
| `preview_wali_invite(text)` | Returns the limited preview for a bearer of the matching legacy invitation token. |
| `promote_journey_to_active(uuid)` | Requires a Seeker party and checks pair eligibility and active Journey capacity. |
| `reopen_family_review(uuid)` | Uses the private active review helper to check party rights and paused status. |
| `resolve_family_review_if_due(uuid)` | Checks Seeker party or Main Guardian access before resolving a due review. |
| `restart_journey(uuid)` | Checks the caller is a Seeker party and refuses direct restart because mutual consent is required. |
| `resume_journey(uuid)` | Only the Seeker who paused can resume, subject to holds and slot rules. |
| `score_candidates(uuid[])` | Uses only caller preferences and visible candidates and returns a computed score. |
| `seeker_details_for_unlocked(uuid)` | Requires the caller's unlock for the specified profile and checks current blocking state. |
| `suspend_journey(uuid)` | Requires a Seeker party before applying the pause and plan rules. |
| `unlock_balance(text)` | Returns the caller's credits for the selected tier. |
| `wali_has_wali_one()` | Checks plan status for the caller's Guardian role. |
| `wali_review_decision(uuid, text)` | Locks an active review under the Main Guardian authority guard and attributes the decision to the caller. |
| `zyra_accept_guardian_request(uuid, text)` | Checks caller verification and requires the caller to be the request recipient able to accept. |
| `zyra_advance_stage(uuid, text)` | Requires a Seeker party and validates the current stage and readiness. |
| `zyra_answers_refresh_onboarding_complete()` | Trigger routine uses the row's member ID. PostgreSQL requires trigger invocation. |
| `zyra_attempt_summary_for_guardian(uuid)` | Requires an active Guardian link and applies ended Journey visibility and history consent. |
| `zyra_available_journey_return_ids()` | Delegates to caller-scoped eligibility and returns eligible match IDs. |
| `zyra_block_exists(uuid)` | Returns whether the caller and supplied member have a block in either direction. |
| `zyra_block_user(uuid)` | Creates the caller's block and applies its rules to Journeys involving the caller. |
| `zyra_can_guardian_link(uuid, uuid)` | A signed-in caller can check Guardian eligibility for a pair that includes them. |
| `zyra_can_match(uuid, uuid)` | A signed-in caller can check Journey eligibility for a pair that includes them. |
| `zyra_can_read_ended_match(uuid)` | Returns whether the caller can read the current ended projection. |
| `zyra_can_read_photo_object(text)` | Checks the caller's relationship to a valid, currently readable profile photo. |
| `zyra_can_read_profile_video_object(text)` | Checks the caller's ownership or eligibility to read an approved video. |
| `zyra_can_view_attempt(uuid)` | Tests whether the caller appears in the scoped attempt's participation set. |
| `zyra_can_view_profile(uuid)` | Tests caller visibility via ownership, active Guardian links, shared Journeys or Browse eligibility. |
| `zyra_cancel_guardian_request(uuid)` | Requires a verified caller who initiated the pending request. |
| `zyra_clear_main_guardian(uuid)` | Scopes the Main Guardian update to the calling Seeker. |
| `zyra_compatibility_for_plus(uuid)` | Requires an eligible Seeker party and their Plus unlock before returning the private score. |
| `zyra_compatibility_topics(uuid, uuid)` | Requires caller eligibility through a supported unlock or Journey relationship before revealing approved fields. |
| `zyra_confirm_milestone(uuid)` | Requires the other Seeker to confirm a pending attestation in their shared Journey. |
| `zyra_confirm_preference_lights(jsonb)` | Validates and saves confirmation on the calling Seeker's own preference rows. |
| `zyra_consider_match_code(text)` | Rechecks the verified, budgeted caller preview and pair eligibility before recording the caller's consideration. |
| `zyra_counterpart_card(uuid)` | Requires an authorised active Guardian for a Seeker in the Journey and applies block and safety rules. |
| `zyra_create_guardian_invitation()` | Creates a time-limited invitation for the calling Seeker and enforces Guardian capacity. |
| `zyra_create_profile(text, text, text, date)` | Creates or updates the profile tied to the calling Auth member. |
| `zyra_dashboard_updates(integer, timestamp with time zone, text, uuid)` | Joins dashboard events to caller ownership or participation before returning a bounded page. |
| `zyra_decline_guardian_request(uuid)` | Requires the verified intended caller and a pending Personal Code request. |
| `zyra_decline_wali_invite(text)` | Uses possession of the pending invitation token and forbids declining one's own invitation. |
| `zyra_delete_my_unstarted_identity_verification_attempt()` | Deletes only the caller's unstarted verification attempt. |
| `zyra_discover_profile_ids(integer, integer, text, integer, text, text[], text[], integer, uuid)` | Requires an active Seeker caller and applies caller visibility, hide, block and entitlement rules. |
| `zyra_expire_due_journey_requests(uuid)` | Expires only due pending requests where the caller is both a request party and a Seeker in the match, and returns only their count. The optional match ID further limits the result. |
| `zyra_expire_due_wali_invites()` | Sweeps only the verified caller's pending Guardian invitations. |
| `zyra_family_message_can_read(uuid, timestamp with time zone)` | Requires the caller's active Circle membership and its readable-from boundary. |
| `zyra_family_message_chats(uuid)` | Uses private chat admission and the caller's Circle membership to return chat summaries. |
| `zyra_family_message_circles()` | Returns Circles joined through the caller's membership. |
| `zyra_family_message_participants(uuid)` | Binds participant reads to the caller's own membership and applicable readability rules. |
| `zyra_family_messages(uuid, timestamp with time zone, integer)` | Returns Main Circle messages under caller membership and readability rules. |
| `zyra_family_messages_v2(uuid, timestamp with time zone, integer)` | Requires caller membership and chat visibility when reading messages and their state. |
| `zyra_family_messages_v3(uuid, timestamp with time zone, integer)` | Requires caller membership and per-chat admission and bounds the message page. |
| `zyra_guardian_activity()` | Reads activity on the calling Seeker's own Guardian links. |
| `zyra_guardian_history_consent(uuid, boolean)` | Toggles history consent on the calling Seeker's own active Guardian link. |
| `zyra_guardian_journey_access(uuid, uuid, boolean)` | Requires the calling Seeker's active Guardian link and own Journey attempt. |
| `zyra_guardian_journey_chat_access(uuid, uuid, boolean, boolean)` | Requires the calling Seeker's active Guardian link and Journey before updating view and chat settings. |
| `zyra_guardian_journey_permissions(uuid)` | Returns active Journey permissions when the caller is one of the Guardian link parties. |
| `zyra_journey_busy_flags(uuid[])` | Returns counterpart availability flags only for the calling Seeker's eligible Journeys. |
| `zyra_journey_compatibility_state(uuid)` | Requires a Seeker party in the Journey and returns the permitted reveal state. |
| `zyra_journey_main_guardian_gate(uuid)` | Requires a Seeker party in a readable Journey before returning Main Guardian flags. |
| `zyra_journey_return_available(uuid)` | Delegates to the caller-and-Journey-bounded restart eligibility check. |
| `zyra_main_guardian_history_consent(boolean)` | Toggles history consent on the calling Seeker's own active Main Guardian link. |
| `zyra_mark_family_chat_read(uuid)` | Uses private chat admission and records read state under the caller's ID. |
| `zyra_mark_family_messages_read(uuid)` | Requires caller membership and updates the caller's own Main chat read state. |
| `zyra_mark_journey_messages_read(uuid)` | Requires Journey participation and updates read state for the caller. |
| `zyra_mark_suggestions_seen()` | Marks Guardian suggestions belonging to the calling Seeker. |
| `zyra_match_ending(uuid)` | Requires current participation or ended visibility and redacts another member's safety note. |
| `zyra_may_request_new_journey(uuid)` | Checks Seeker party, ended visibility, plan, block, pair and slot rules for the caller. |
| `zyra_may_send_journey_message(uuid)` | Checks caller participation, Journey state, blocked relations and Guardian sending rights. |
| `zyra_milestone_attestation_state(uuid)` | Returns attestation state only to a Seeker party in the specified Journey. |
| `zyra_my_code_check_budget()` | Reports budget calculated from the caller's own attempts. |
| `zyra_my_ended_journeys()` | Returns the caller's visible ended Journeys and applies reason redaction. |
| `zyra_my_guardian_requests()` | Requires identity verification and reads requests involving the caller. |
| `zyra_my_hidden_profile_ids()` | Returns hides made by the caller. |
| `zyra_my_identity_verification_allows_active_journey()` | Reads the caller's current verification eligibility for active Journeys. |
| `zyra_my_identity_verification_allows_app()` | Reads the caller's current verification eligibility for general app access. |
| `zyra_my_identity_verification_state()` | Reads the caller's own current verification state. |
| `zyra_my_inactivity_notice()` | Reads the caller's own active inactivity notice. |
| `zyra_my_lights_needed_for_compatibility()` | Delegates to the caller-scoped preference light helper. |
| `zyra_my_lights_needing_reconfirmation()` | Reads the caller's preference lights via the private helper and caller-owned details. |
| `zyra_my_lights_needing_reconfirmation(boolean)` | Reads the caller's preference lights via the private helper and caller-owned details. |
| `zyra_my_onboarding_progress()` | Calculates onboarding progress for the caller. |
| `zyra_my_paid_access(text)` | Calls the private-access paid role check using the caller's ID. |
| `zyra_my_personal_code(text)` | Reads or creates a code scoped to the verified caller and their own role. |
| `zyra_my_photo_sources()` | Returns active photo source metadata owned by the caller. |
| `zyra_my_profile_video()` | Returns video submission state belonging to the caller. |
| `zyra_my_safety_cases()` | Scopes report lookup to the caller as reporter. |
| `zyra_my_welcome_back()` | Consumes the welcome-back flag belonging to the caller. |
| `zyra_notification_preferences()` | Returns the caller's notification settings. |
| `zyra_open_family_message_circle(uuid)` | Requires the owner or an active Guardian with applicable Circle access and enforces blocking. |
| `zyra_preview_match_code(text)` | Requires the caller's verification, locks and charges a shared lookup budget and checks target eligibility. |
| `zyra_preview_personal_code(text)` | Requires the caller's verification, charges the shared lookup budget and checks target eligibility. |
| `zyra_profile_video_for(uuid)` | Delegates approved video visibility to the caller-aware object check. |
| `zyra_profiles_set_onboarding_complete()` | Trigger routine derives completion from the row. PostgreSQL requires trigger invocation. |
| `zyra_propose_milestone(uuid, text, date)` | Requires a Seeker party, validates the milestone and attributes the proposal to the caller. |
| `zyra_record_identity_verification_consent(text, boolean)` | Creates or changes identity verification consent for the caller. |
| `zyra_record_journey_milestone()` | Trigger routine derives Timeline events from the changed match row. PostgreSQL requires trigger invocation. |
| `zyra_record_product_event(text, text, text, text, text, text, text)` | Requires authentication and allows only bounded, allowlisted telemetry fields without storing caller identity. |
| `zyra_remove_ended_journey(uuid)` | Passes the caller's ID to the private removal routine for that caller's own copy. |
| `zyra_remove_guardian(uuid)` | Removes an active Guardian link owned by the calling Seeker. |
| `zyra_remove_my_profile_video()` | Marks the caller's video removed and returns its path. |
| `zyra_remove_profile_photo(uuid, integer)` | Requires photo ownership and matching revision before queueing object removal. |
| `zyra_report_family_message(uuid, uuid, text)` | Requires chat visibility during membership to report a visible message from another sender. |
| `zyra_request_guardian_link(text, text)` | Rechecks verified caller's budgeted preview and relationship rules before creating a caller-bound request. |
| `zyra_reset_profile()` | Resets the caller's profile and queues their photo cleanup. |
| `zyra_reset_search()` | Clears passes belonging to the caller. |
| `zyra_resolve_code_link(text)` | Verifies the caller, charges one check against the shared preview budget, and returns only the eligible preview fields or a status without member data. |
| `zyra_reveal_journey_compatibility(uuid)` | Requires a Seeker party in the Journey and records that caller's reveal. |
| `zyra_revoke_wali_invite(text)` | Lets the original inviter revoke a pending invitation. |
| `zyra_rotate_my_personal_code(text)` | Rotates the verified caller's code for their role. |
| `zyra_save_profile_photo(uuid, text, text, jsonb, integer, integer)` | Verifies caller ownership, private source path, revisions and matching Storage metadata. |
| `zyra_send_family_message(uuid, text)` | Uses caller membership, chat admission and sender rate limits. The two-argument form delegates to the same function. |
| `zyra_send_family_message(uuid, text, uuid)` | Uses caller membership, chat admission and sender rate limits. The two-argument form delegates to the same function. |
| `zyra_set_family_chat_muted(uuid, boolean)` | Requires chat admission and updates mute state for the caller. |
| `zyra_set_family_message_muted(uuid, boolean)` | Requires Circle membership and updates whole-Circle mute state for the caller. |
| `zyra_set_guardian_journey_permission(uuid, uuid, boolean, boolean)` | Requires the active Guardian link owner who is also a Seeker party before updating permissions. |
| `zyra_set_main_guardian(uuid)` | Selects a Main Guardian among the calling Seeker's active links. |
| `zyra_set_my_home_place(text, numeric, numeric)` | Writes rounded home location only to the calling Seeker's private row. |
| `zyra_set_notification_preference(text, boolean)` | Writes allowed notification categories for the caller. |
| `zyra_set_profile_complete(boolean)` | Changes completion on the caller's profile after validating its data. |
| `zyra_set_profile_hidden(uuid, boolean)` | Requires a Seeker caller and a permissible target and changes only the caller's hide state. |
| `zyra_submit_feedback(text, text, text, text, text)` | Validates and limits feedback attributable to the authenticated caller. |
| `zyra_touch_activity()` | Records activity and adjusts inactivity status for the caller. |
| `zyra_unblock_user(uuid)` | Removes only the block made by the caller. |
| `zyra_unlock_profile(uuid, text)` | Requires an eligible calling Seeker, visible target and sufficient caller credits before atomic unlock. |

## Private policy and view routines

| Signature | Access boundary |
|---|---|
| `zyra_family_chat_message_visible(uuid, timestamp with time zone)` | Applies private caller-aware chat admission and the member's readable-from boundary in access policies. |
| `zyra_my_attempt_participation_rows()` | Filters the protected participation set by the authenticated caller without accepting a member ID. |
| `zyra_photo_caller_exists()` | Requires the JWT subject to still have an Auth account. |
| `zyra_photo_not_queued(text)` | Blocks staged photo reads once the object is queued for deletion. The surrounding policy checks the caller owns the path. |
| `zyra_photo_path_writable(text, text)` | Binds the path to the caller's upload folder and serializes writes against cleanup. |
| `zyra_photo_reference_owned(uuid, text)` | Checks Storage ownership matches the referenced profile photo path. The surrounding policy binds the photo row to the caller. |
| `zyra_source_photo_path_owned(text, text)` | Binds source photo ownership to the existing Auth caller. |
| `zyra_unreferenced_photo_path_writable(text, text)` | Checks the caller's path authority and allows the operation only when the object is unreferenced. |

## Q152 Journey callers

In `001_baseline.sql`, the two public eligibility wrappers return false for a signed-in member when neither supplied ID is theirs. They then delegate to the corresponding `private` owner-rights predicate with fixed search path and member execution revoked. The held request and response routines listed here remain available to the trusted callers defined by their grants.

| Call site | Variant | Why |
|---|---|---|
| `likes_insert` on `public.likes` | `public.zyra_can_match` | The policy binds `liker_id` to the caller. |
| `passes_insert` on `public.passes` | `public.zyra_can_match` | The policy binds `passer_id` to the caller. |
| `saves_insert` on `public.saves` | `public.zyra_can_match` | The policy binds `saver_id` to the caller. |
| `public.create_match_on_mutual_like()` via `likes_create_match` | `public.zyra_can_match` | Direct member inserts and `public.zyra_consider_match_code` set `NEW.liker_id` to the caller. Trusted maintenance can insert without a member identity. |
| `public.promote_journey_to_active(uuid)` | `public.zyra_can_match` | The caller is a Seeker in the match before the eligibility recheck. |
| `public.request_new_journey(uuid)` | `public.zyra_can_match` | The pair contains the authenticated requester. |
| `public.respond_to_journey_request(uuid, text)` | `public.zyra_can_match` | The pair contains the authenticated recipient. |
| `public.zyra_consider_match_code(text)` | `public.zyra_can_match` | Consideration checks the calling Seeker and code holder. |
| `public.zyra_may_request_new_journey(uuid)` | `public.zyra_can_match` | The pair contains the calling Seeker whose eligibility is checked. |
| `private.zyra_personal_code_match_eligible(uuid, text, uuid)` | `public.zyra_can_match` | The match preview and link resolver pass the authenticated caller verified by the shared budget helper and the code holder. |
| `public.zyra_can_match(uuid, uuid)` | `private.zyra_can_match_pair` | The member-facing pair guard runs before the existing eligibility rules. |
| `public.accept_wali_invite(text, text)` | `public.zyra_can_guardian_link` | The link pair includes the authenticated accepter. |
| `public.zyra_accept_guardian_request(uuid, text)` | `public.zyra_can_guardian_link` | The link pair includes the authenticated accepter. |
| `private.zyra_personal_code_guardian_eligible(uuid, text, uuid, text)` | `public.zyra_can_guardian_link` | The Guardian preview and link resolver pass the authenticated caller verified by the shared budget helper and the code holder. |
| `public.zyra_request_guardian_link(text, text)` | `public.zyra_can_guardian_link` | The link request uses the caller and code holder. |
| `public.zyra_can_guardian_link(uuid, uuid)` | `private.zyra_can_guardian_link_pair` | The member-facing pair guard runs before the existing link rules. |
| `public.zyra_enforce_guardian_link_allowed()` via `zyra_wali_links_guardian_link_allowed` | `private.zyra_can_guardian_link_pair` | The owner-rights trigger validates rows on trusted writes where the authenticated identity need not be in the link. Removing a link keeps its early return. |
| `ZyraJourneyService.expireDueJourneyRequests()` in `SOURCE/lib/services/zyra_journey_service.dart` | `public.zyra_expire_due_journey_requests` | Connections calls the service without a match ID to close the signed-in member's due requests. |
| `public.zyra_expire_due_journey_requests(uuid)` | `private.zyra_close_expired_journey_requests` | Passes the caller's authenticated ID and optional match ID. A missing identity returns zero. |
| `private.zyra_expire_due_journey_requests_all()` | `private.zyra_close_expired_journey_requests` | Supplies neither a member nor a match filter. Execution is reserved for the owner. |

`SOURCE/lib/screens/connections/connections_screen.dart` calls `ZyraJourneyService.expireDueJourneyRequests()` on load. The service passes the existing `p_match_id` argument as null for that call. The worker locks due rows with `SKIP LOCKED`, sets `closed_reason` to `expired`, and sends the existing notification without creating a decline cooldown. The Jobs specification owns the scheduled caller of the whole-database sweep under audit F-07.

## Q154 shared-code checks

Line 109's `public.zyra_resolve_code_link(text)` and both existing preview RPCs call `private.zyra_begin_personal_code_check()` to verify the caller, serialize concurrent checks by caller, and enforce the same hourly and daily limits. The two private eligibility helpers share the existing preview and Q152 caller checks. The resolver records one attempt, returns only the corresponding preview fields on success, and creates no request, link or consideration. The resolver grants execution to `authenticated`. Its three new private helpers inherit owner authority inside their calling RPCs. They have no direct execution grants for API roles.

## Follow-up

The older `end_journey` overloads also distinguish a missing match ID from a match the caller cannot change. Their writes require a Seeker party. This error difference is tracked with the caller-scope follow-up under OA-ZYRA-317.

## Service boundaries

The photo cleanup claim and completion calls, profile-video recording and review, identity provider callbacks, verified trial grants, product-event summaries and pruning, inactivity and retention jobs, and report closure are reserved for trusted database and service roles. Public owner-rights routines have no anonymous EXECUTE grant. Check effective role privileges on the applied catalog as part of server verification.
