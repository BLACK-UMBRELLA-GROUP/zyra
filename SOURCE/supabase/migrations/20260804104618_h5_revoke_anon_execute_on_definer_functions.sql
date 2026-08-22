-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804104618, applied name
-- 'h5_revoke_anon_execute_on_definer_functions') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- H-5 — anonymous EXECUTE on SECURITY DEFINER functions.
--
-- Fable read each body and reported them NOT currently exploitable: they
-- check the caller and raise when it is null. I re-read them and agree.
-- This is defence in depth, and Fable's own justification is the right one
-- — "the guard is one edit away from being removed by a future session".
--
-- A SECURITY DEFINER function runs as its owner. The only thing standing
-- between anon and owner privileges is a hand-written null check inside
-- each body. That is a guarantee held in application logic, in a project
-- whose whole review finding was that guarantees belong in the enforcement
-- boundary. Revoking EXECUTE moves it there.
--
-- TRIGGER FUNCTIONS (zyra_*_clears_others, auto_designate_main_wali,
-- notify_new_message, create_*_milestone) should never have been callable
-- by anyone. They are invoked by the trigger machinery, which does not
-- consult EXECUTE grants at all — so revoking from PUBLIC costs nothing
-- and closes a direct-RPC path that had no business existing.
--
-- REVOKE FROM PUBLIC **AND** FROM anon, both. Learned the hard way twice
-- today: PUBLIC and a named role are separate grants, and revoking one
-- leaves the other. Belt and braces is the correct amount of paranoia
-- here.

do $$
declare
  f record;
  fns text[] := array[
    -- journey mutations, flagged by the review
    'end_journey', 'promote_journey_to_active', 'suspend_journey',
    'resume_journey', 'restart_journey',
    -- trigger functions: never call these directly
    'zyra_like_clears_others', 'zyra_pass_clears_others', 'zyra_save_clears_others',
    'auto_designate_main_wali', 'notify_new_message',
    'create_conversation_started_milestone', 'create_match_on_mutual_like',
    'touch_seeker_details',
    -- everything else that is DEFINER and should be signed-in only
    'accept_wali_invite', 'preview_wali_invite', 'delete_own_account',
    'open_family_review', 'reopen_family_review', 'resolve_family_review_if_due',
    'wali_review_decision', 'wali_has_wali_one', 'zyra_reset_search',
    'zyra_block_exists', 'create_notification',
    'mock_purchase_wali_premium', 'mock_set_wali_plan'
  ];
begin
  for f in
    select p.oid::regprocedure::text as sig, p.proname
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = any(fns)
  loop
    execute format('revoke all on function %s from public', f.sig);
    execute format('revoke all on function %s from anon', f.sig);

    -- Trigger functions get NO grant back. Nothing calls them by name.
    if f.proname not in (
      'zyra_like_clears_others','zyra_pass_clears_others','zyra_save_clears_others',
      'auto_designate_main_wali','notify_new_message',
      'create_conversation_started_milestone','create_match_on_mutual_like',
      'touch_seeker_details','create_notification'
    ) then
      execute format('grant execute on function %s to authenticated', f.sig);
    end if;
  end loop;
end $$;

-- preview_wali_invite is the one genuine question mark: a Guardian may
-- need to preview an invite code BEFORE signing in. Verified against the
-- app first — accept_wali_invite_screen.dart calls it only from an
-- authenticated session, and the invite flow requires an account. Left
-- authenticated-only. If a pre-signup preview is ever wanted, that is a
-- deliberate re-grant, not an accident.
