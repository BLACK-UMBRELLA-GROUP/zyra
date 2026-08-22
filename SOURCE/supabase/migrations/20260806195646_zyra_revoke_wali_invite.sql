-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806195646, applied name
-- 'zyra_revoke_wali_invite') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Cancel an invite code you sent but nobody has redeemed.
--
-- 'revoked' was already in the status CHECK — the schema anticipated this
-- and nothing ever used it.
--
-- An RPC rather than a client UPDATE, even though `authenticated` DOES hold
-- UPDATE on wali_invites and wali_invites_update scopes rows to the
-- inviter. The policy has no WITH CHECK, so a direct update could rewrite
-- the token, the status, or inviter_id on your own row. This exposes one
-- transition and nothing else.
--
-- Safe to build ahead of Remove Guardian: an unredeemed code has no link,
-- no Journey, and no Family Review hanging off it. Revoking it affects
-- nobody but the sender.

create or replace function public.zyra_revoke_wali_invite(p_token text)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me uuid := auth.uid();
  v_n  int;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  -- inviter_id = me is the whole rule. Only pending invites can be
  -- revoked: an accepted one is a live Guardian link and must be removed
  -- through the Guardian flow, not quietly cancelled from behind.
  update public.wali_invites
     set status = 'revoked'
   where token = p_token
     and inviter_id = v_me
     and status = 'pending';

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$function$;

revoke execute on function public.zyra_revoke_wali_invite(text) from public;
revoke execute on function public.zyra_revoke_wali_invite(text) from anon;
grant  execute on function public.zyra_revoke_wali_invite(text) to authenticated;
grant  execute on function public.zyra_revoke_wali_invite(text) to service_role;
