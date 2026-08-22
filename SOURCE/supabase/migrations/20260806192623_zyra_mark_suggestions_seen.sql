-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806192623, applied name
-- 'zyra_mark_suggestions_seen') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Stamping "seen" needs a write, and `authenticated` has no UPDATE grant on
-- wali_suggestions — deliberately, from the C-3 column lockdown. The
-- wali_suggestions_update policy still exists but is unreachable without the
-- grant beneath it, so a direct client UPDATE fails with permission denied.
--
-- Re-granting UPDATE would hand the Seeker every column, including `status`.
-- This grants exactly one capability instead: stamp seen_at on my own
-- pending rows, nothing else, no arguments to get wrong.

create or replace function public.zyra_mark_suggestions_seen()
returns integer
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

  -- seeker_id = me is the whole authorisation rule. A Guardian cannot mark
  -- their own suggestion as seen on the Seeker's behalf, and nobody can
  -- touch anyone else's row: there is no parameter to point elsewhere.
  update public.wali_suggestions
     set seen_at = now()
   where seeker_id = v_me
     and status = 'pending'
     and seen_at is null;

  get diagnostics v_n = row_count;
  return v_n;
end;
$function$;

revoke execute on function public.zyra_mark_suggestions_seen() from public;
revoke execute on function public.zyra_mark_suggestions_seen() from anon;
grant  execute on function public.zyra_mark_suggestions_seen() to authenticated;
grant  execute on function public.zyra_mark_suggestions_seen() to service_role;
