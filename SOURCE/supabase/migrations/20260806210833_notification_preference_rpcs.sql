-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806210833, applied name
-- 'notification_preference_rpcs') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Read current state, and append a change.

create or replace function public.zyra_notification_preferences()
returns table(category text, enabled boolean, changed_at timestamptz)
language sql
stable
security definer
set search_path to 'public'
as $function$
  -- DEFAULTS MATTER LEGALLY, so they live here rather than in the client
  -- where a future screen could quietly disagree with them.
  --
  --   Product notifications default ON — the user asked for the product.
  --   Marketing and product updates default OFF. Under UK GDPR consent must
  --   be a positive opt-in; a pre-ticked box is not consent. A user who has
  --   never touched the switch has NOT agreed to marketing, and the absence
  --   of a row must therefore read as "no".
  with defaults(category, enabled) as (
    values ('matches_journeys',  true),
           ('guardian_activity', true),
           ('introductions',     true),
           ('marketing_emails',  false),
           ('product_updates',   false)
  ),
  latest as (
    select distinct on (p.category)
           p.category, p.enabled, p.changed_at
    from public.notification_preferences p
    where p.user_id = (select auth.uid())
    order by p.category, p.changed_at desc
  )
  select d.category,
         coalesce(l.enabled, d.enabled),
         l.changed_at
  from defaults d
  left join latest l on l.category = d.category;
$function$;

create or replace function public.zyra_set_notification_preference(
  p_category text,
  p_enabled  boolean
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  if p_category not in ('matches_journeys','guardian_activity',
                        'introductions','marketing_emails','product_updates') then
    raise exception 'unknown_category: %', p_category;
  end if;

  -- Always an INSERT. Never an upsert, never an update: withdrawing consent
  -- must leave a trace, and overwriting the row it withdraws would erase
  -- the very thing that proves it happened.
  insert into public.notification_preferences (user_id, category, enabled)
  values (v_me, p_category, p_enabled);

  return true;
end;
$function$;

revoke execute on function public.zyra_notification_preferences() from public;
revoke execute on function public.zyra_notification_preferences() from anon;
grant  execute on function public.zyra_notification_preferences() to authenticated;
grant  execute on function public.zyra_notification_preferences() to service_role;

revoke execute on function public.zyra_set_notification_preference(text, boolean) from public;
revoke execute on function public.zyra_set_notification_preference(text, boolean) from anon;
grant  execute on function public.zyra_set_notification_preference(text, boolean) to authenticated;
grant  execute on function public.zyra_set_notification_preference(text, boolean) to service_role;
