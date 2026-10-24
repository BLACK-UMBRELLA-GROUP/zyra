-- OA-ZYRA-256 — privacy-safe first-party product evidence foundation.
--
-- STAGED ONLY on creation. The Flutter compile gate remains OFF. Applying
-- this migration does not itself begin collection, and applying it requires a
-- separate exact Founder GO after privacy/retention and security review.
--
-- There is intentionally no caller id, profile id, Journey id, ZYRA Code,
-- session id, device id, free text or json payload. The server accepts only
-- the fixed taxonomy below. This is product evidence, not an activity log.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;

create table private.zyra_product_events (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default statement_timestamp(),
  feature_key text not null check (
    feature_key in (
      'browse', 'connections', 'myZyra', 'guardian', 'journey', 'profile',
      'zyraCode', 'membership', 'identityCheck', 'support'
    )
  ),
  event_name text not null check (
    event_name in ('shown', 'opened', 'started', 'completed', 'failed')
  ),
  action_key text not null check (
    action_key in (
      'pageView', 'zyraCodeCheck', 'zyraCodeRequest',
      'knownPersonConsider', 'supportAnswer', 'supportEmail',
      'identityProvider', 'guardianHistoryConsent', 'guardianReport',
      'guardianMakeMain', 'guardianRemove'
    )
  ),
  surface_key text not null check (
    surface_key in ('seeker', 'guardian', 'entry')
  ),
  platform_key text not null check (
    platform_key in ('ios', 'android', 'web', 'macos', 'windows', 'linux', 'fuchsia')
  ),
  app_version text not null check (
    length(app_version) between 1 and 32
    and app_version ~ '^[0-9A-Za-z.+-]+$'
  ),
  build_number text not null check (
    length(build_number) between 1 and 32
    and build_number ~ '^[0-9A-Za-z.+-]+$'
  )
);

comment on table private.zyra_product_events is
  'OA-ZYRA-256 first-party aggregate product evidence. Fixed feature, action, '
  'event and surface taxonomy only; '
  'contains no member, device, session, profile, Journey or free-text identity.';

create index zyra_product_events_occurred_idx
  on private.zyra_product_events (occurred_at desc);
create index zyra_product_events_feature_event_idx
  on private.zyra_product_events (
    feature_key,
    action_key,
    event_name,
    occurred_at desc
  );

revoke all on table private.zyra_product_events from public, anon, authenticated;
grant select, insert, delete on table private.zyra_product_events to service_role;
grant usage, select on sequence private.zyra_product_events_id_seq to service_role;

create or replace function public.zyra_record_product_event(
  p_feature_key text,
  p_event_name text,
  p_action_key text,
  p_surface_key text,
  p_platform_key text,
  p_app_version text,
  p_build_number text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required';
  end if;

  -- Explicit guards give callers a stable 22023 contract before the table's
  -- integrity constraints provide the final independent enforcement layer.
  if p_feature_key is null or p_feature_key not in (
    'browse', 'connections', 'myZyra', 'guardian', 'journey', 'profile',
    'zyraCode', 'membership', 'identityCheck', 'support'
  ) then
    raise exception using errcode = '22023', message = 'Unknown feature key';
  end if;
  if p_event_name is null or p_event_name not in (
    'shown', 'opened', 'started', 'completed', 'failed'
  ) then
    raise exception using errcode = '22023', message = 'Unknown event name';
  end if;
  if p_action_key is null or p_action_key not in (
    'pageView', 'zyraCodeCheck', 'zyraCodeRequest',
    'knownPersonConsider', 'supportAnswer', 'supportEmail',
    'identityProvider', 'guardianHistoryConsent', 'guardianReport',
    'guardianMakeMain', 'guardianRemove'
  ) then
    raise exception using errcode = '22023', message = 'Unknown action key';
  end if;
  if p_surface_key is null or p_surface_key not in (
    'seeker', 'guardian', 'entry'
  ) then
    raise exception using errcode = '22023', message = 'Unknown surface key';
  end if;
  if p_platform_key is null or p_platform_key not in (
    'ios', 'android', 'web', 'macos', 'windows', 'linux', 'fuchsia'
  ) then
    raise exception using errcode = '22023', message = 'Unknown platform key';
  end if;
  if p_app_version is null
     or length(p_app_version) not between 1 and 32
     or p_app_version !~ '^[0-9A-Za-z.+-]+$' then
    raise exception using errcode = '22023', message = 'Invalid app version';
  end if;
  if p_build_number is null
     or length(p_build_number) not between 1 and 32
     or p_build_number !~ '^[0-9A-Za-z.+-]+$' then
    raise exception using errcode = '22023', message = 'Invalid build number';
  end if;

  -- Serialize concurrent submissions from one authenticated principal without
  -- storing that principal or its hash. This is a transaction-scoped lock;
  -- it disappears when the call ends and is not product evidence.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(auth.uid()::text, 256)
  );

  -- Privacy-safe project circuit breaker. Telemetry is non-critical, so it is
  -- safer to drop excess evidence than let a broken or hostile client create
  -- unbounded write cost. This uses only the occurred_at index and persists no
  -- caller, device, network or session identifier.
  if (
    select count(*)
    from private.zyra_product_events as events
    where events.occurred_at >= statement_timestamp() - interval '1 minute'
  ) >= 5000 then
    return;
  end if;

  insert into private.zyra_product_events (
    feature_key,
    event_name,
    action_key,
    surface_key,
    platform_key,
    app_version,
    build_number
  ) values (
    p_feature_key,
    p_event_name,
    p_action_key,
    p_surface_key,
    p_platform_key,
    p_app_version,
    p_build_number
  );
end;
$function$;

comment on function public.zyra_record_product_event(text, text, text, text, text, text, text) is
  'Records one allowlisted, identifier-free ZYRA product event for an '
  'authenticated caller. No arbitrary attributes or caller identity persist.';

revoke all on function public.zyra_record_product_event(text, text, text, text, text, text, text)
  from public, anon;
grant execute on function public.zyra_record_product_event(text, text, text, text, text, text, text)
  to authenticated, service_role;

create or replace function public.zyra_product_event_summary(
  p_from timestamptz,
  p_to timestamptz
)
returns table (
  feature_key text,
  event_name text,
  action_key text,
  surface_key text,
  platform_key text,
  app_version text,
  build_number text,
  event_count bigint,
  first_seen_at timestamptz,
  last_seen_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    events.feature_key,
    events.event_name,
    events.action_key,
    events.surface_key,
    events.platform_key,
    events.app_version,
    events.build_number,
    count(*)::bigint as event_count,
    min(events.occurred_at) as first_seen_at,
    max(events.occurred_at) as last_seen_at
  from private.zyra_product_events as events
  where p_from is not null
    and p_to is not null
    and p_from < p_to
    and events.occurred_at >= p_from
    and events.occurred_at < p_to
  group by
    events.feature_key,
    events.event_name,
    events.action_key,
    events.surface_key,
    events.platform_key,
    events.app_version,
    events.build_number
  order by event_count desc, events.feature_key, events.event_name;
$function$;

comment on function public.zyra_product_event_summary(timestamptz, timestamptz) is
  'Service-role-only aggregate product evidence. Returns fixed taxonomy and '
  'counts; it cannot return member, device, session or free-text data.';

revoke all on function public.zyra_product_event_summary(timestamptz, timestamptz)
  from public, anon, authenticated;
grant execute on function public.zyra_product_event_summary(timestamptz, timestamptz)
  to service_role;

create or replace function public.zyra_prune_product_events()
returns bigint
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_deleted bigint;
begin
  delete from private.zyra_product_events as events
  where events.occurred_at < statement_timestamp() - interval '30 days';

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$function$;

comment on function public.zyra_prune_product_events() is
  'Service-role-only fixed retention control. Deletes raw product events '
  'older than 30 days and returns only the deleted row count.';

revoke all on function public.zyra_prune_product_events()
  from public, anon, authenticated;
grant execute on function public.zyra_prune_product_events()
  to service_role;
