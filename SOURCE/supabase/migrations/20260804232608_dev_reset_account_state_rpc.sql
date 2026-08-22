-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804232608, applied name
-- 'dev_reset_account_state_rpc') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Developer Mode "Reset account state" — fix (Fable, 2026-08-05).
--
-- The dev panel was deleting from five tables client-side with
-- hand-written column names: `.eq('seeker_id', …)` for saves, likes and
-- passes. Those columns do not exist — the real ones are saver_id,
-- liker_id and passer_id — so every one of those deletes failed with
-- "column does not exist", which is why the panel reported
-- "Partially reset — these failed: saves likes passes profile_unlocks".
--
-- profile_unlocks failed for a different and CORRECT reason: 2026-08-04
-- revoked INSERT/UPDATE/DELETE on it from `authenticated` to close the
-- free-unlock hole. Granting DELETE back to fix a dev tool would reopen
-- part of that surface, so the reset moves server-side instead: one
-- SECURITY DEFINER function, one transaction, no client-side column
-- names to get wrong again.
--
-- Guarded to seeded @zyra.test accounts, exactly like
-- mock_purchase_wali_premium(). A real user calling this gets an
-- exception, not a wiped account.
create or replace function public.zyra_dev_reset_account()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_me uuid := auth.uid();
  v_saves int; v_likes int; v_passes int; v_unlocks int; v_credits int;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  -- Dev/preview accounts only. Same guard as the mock purchase functions.
  if not exists (
    select 1 from auth.users u
    where u.id = v_me and u.email like '%@zyra.test'
  ) then
    raise exception 'dev_accounts_only'
      using hint = 'zyra_dev_reset_account() is only callable by seeded @zyra.test accounts.';
  end if;

  delete from public.saves           where saver_id    = v_me;  get diagnostics v_saves   = row_count;
  delete from public.likes           where liker_id    = v_me;  get diagnostics v_likes   = row_count;
  delete from public.passes          where passer_id   = v_me;  get diagnostics v_passes  = row_count;
  delete from public.profile_unlocks where unlocker_id = v_me;  get diagnostics v_unlocks = row_count;
  delete from public.unlock_credits  where user_id     = v_me;  get diagnostics v_credits = row_count;

  return jsonb_build_object(
    'saves', v_saves, 'likes', v_likes, 'passes', v_passes,
    'unlocks', v_unlocks, 'credits', v_credits
  );
end;
$$;

revoke execute on function public.zyra_dev_reset_account() from public, anon;
grant execute on function public.zyra_dev_reset_account() to authenticated;

-- Missing DELETE policy on likes, found while tracing the above. saves and
-- passes both have one; likes never did, so a Consider could be written by
-- a client and never withdrawn by one. Own rows only.
drop policy if exists likes_delete on public.likes;
create policy likes_delete on public.likes for delete
  using (liker_id = (select auth.uid()));
