-- OA-ZYRA-281 / DR-ZYRA-216 / DR-ZYRA-217 / DR-ZYRA-222 / DR-ZYRA-223
-- Meaningful-movement projection: unread-backed notifications plus
-- authoritative domain events. This is not an inbox or history; the
-- Notifications manager remains the notification-history surface.
--
-- STAGED ONLY on 2026-08-30. Applying this file requires a separate Founder
-- GO after Fable verification. The projection reads existing authoritative
-- rows only: it creates no event store and performs no user-data write.

create index if not exists notifications_dashboard_updates_unread_idx
on public.notifications (user_id, created_at desc, id desc)
where read_at is null;

create index if not exists wali_suggestions_dashboard_updates_seeker_idx
on public.wali_suggestions (seeker_id, created_at desc, id desc);

create index if not exists journey_family_reviews_dashboard_updates_idx
on public.journey_family_reviews (attempt_id, opened_at desc, id desc)
where attempt_id is not null;

-- This table has the real composite PK (review_id, wali_id), not an id
-- column. Preserve that schema and use wali_id as the deterministic tie-break.
create index if not exists journey_family_review_responses_dashboard_updates_idx
on public.journey_family_review_responses
  (review_id, responded_at desc, wali_id);

create index if not exists timeline_milestones_dashboard_updates_idx
on public.timeline_milestones (timeline_id, occurred_at desc, id desc);

create or replace function public.zyra_dashboard_updates(
  p_limit integer default 3,
  p_cursor_occurred_at timestamptz default null,
  p_cursor_class_key text default null,
  p_cursor_source_id uuid default null
)
returns table (
  occurred_at timestamptz,
  class_key text,
  source_id uuid,
  title_key text,
  detail_key text,
  destination_key text,
  related_match_id uuid,
  is_unread boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_limit integer := greatest(1, least(coalesce(p_limit, 3), 20));
  v_cursor_parts integer :=
    (p_cursor_occurred_at is not null)::integer
    + (p_cursor_class_key is not null)::integer
    + (p_cursor_source_id is not null)::integer;
begin
  if v_cursor_parts not in (0, 3) then
    raise exception 'dashboard_updates_cursor_incomplete'
      using errcode = '22023';
  end if;

  if v_caller is null then
    return;
  end if;

  return query
  with
  notification_templates(
    notification_type,
    title_key,
    detail_key,
    destination_key,
    audience_kind
  ) as (
    values
      ('new_message'::text,
       'dashboard_updates.notification.new_message.title',
       'dashboard_updates.notification.new_message.detail',
       'notifications'::text,
       'seeker_match'::text),
      ('wali_request',
       'dashboard_updates.notification.wali_request.title',
       'dashboard_updates.notification.wali_request.detail',
       'notifications',
       'direct_recipient'),
      ('journey_request',
       'dashboard_updates.notification.journey_request.title',
       'dashboard_updates.notification.journey_request.detail',
       'notifications',
       'seeker_match'),
      ('journey_request_declined',
       'dashboard_updates.notification.journey_request_declined.title',
       'dashboard_updates.notification.journey_request_declined.detail',
       'notifications',
       'seeker_match'),
      ('pause_nudge',
       'dashboard_updates.notification.pause_nudge.title',
       'dashboard_updates.notification.pause_nudge.detail',
       'notifications',
       'seeker_match'),
      ('journey_also_paused',
       'dashboard_updates.notification.journey_also_paused.title',
       'dashboard_updates.notification.journey_also_paused.detail',
       'notifications',
       'seeker_match'),
      ('wali_invite_received',
       'dashboard_updates.notification.wali_invite_received.title',
       'dashboard_updates.notification.wali_invite_received.detail',
       'notifications',
       'direct_recipient'),
      ('wali_invite_declined',
       'dashboard_updates.notification.wali_invite_declined.title',
       'dashboard_updates.notification.wali_invite_declined.detail',
       'notifications',
       'direct_recipient'),
      ('wali_invite_expiring',
       'dashboard_updates.notification.wali_invite_expiring.title',
       'dashboard_updates.notification.wali_invite_expiring.detail',
       'notifications',
       'direct_recipient'),
      ('wali_invite_expired',
       'dashboard_updates.notification.wali_invite_expired.title',
       'dashboard_updates.notification.wali_invite_expired.detail',
       'notifications',
       'direct_recipient'),
      ('wali_invite_revoked',
       'dashboard_updates.notification.wali_invite_revoked.title',
       'dashboard_updates.notification.wali_invite_revoked.detail',
       'notifications',
       'direct_recipient'),
      -- A proposal has no Timeline row yet, so notification is the canonical
      -- representation until the other Seeker confirms it.
      ('milestone_proposed',
       'dashboard_updates.notification.milestone_proposed.title',
       'dashboard_updates.notification.milestone_proposed.detail',
       'notifications',
       'seeker_match')
  ),
  milestone_templates(milestone_type, title_key, detail_key) as (
    values
      ('liked'::text,
       'dashboard_updates.journey.timeline_milestone.title'::text,
       'dashboard_updates.journey.timeline_milestone.liked.detail'::text),
      ('match_created',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.match_created.detail'),
      ('journey_started',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.journey_started.detail'),
      ('compatibility_revealed',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.compatibility_revealed.detail'),
      ('salam_exchanged',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.salam_exchanged.detail'),
      ('guardian_linked',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.guardian_linked.detail'),
      ('phase_1_complete',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.phase_1_complete.detail'),
      ('phase_2_complete',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.phase_2_complete.detail'),
      ('phase_3_complete',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.phase_3_complete.detail'),
      ('family_stage',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.family_stage.detail'),
      ('conversation_started',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.conversation_started.detail'),
      ('journey_paused',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.journey_paused.detail'),
      ('journey_continued',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.journey_continued.detail'),
      ('journey_ended',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.journey_ended.detail'),
      ('meeting',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.meeting.detail'),
      ('nikah',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.nikah.detail')
  ),
  caller_participation as materialized (
    select
      p.attempt_id,
      p.match_id,
      p.role,
      p.is_main,
      p.attempt_status
    from public.zyra_my_attempt_participation p
  ),
  notification_rows as (
    select
      n.created_at as occurred_at,
      ('notification.' || nt.notification_type)::text as class_key,
      n.id as source_id,
      nt.title_key,
      nt.detail_key,
      nt.destination_key,
      n.related_match_id,
      true as is_unread
    from public.notifications n
    join notification_templates nt on nt.notification_type = n.type
    where n.user_id = v_caller
      and n.read_at is null
      and n.created_at is not null
      and (
        nt.audience_kind = 'direct_recipient'
        or (
          nt.audience_kind = 'seeker_match'
          and n.related_match_id is not null
          and exists (
            select 1
            from caller_participation cp
            where cp.match_id = n.related_match_id
              and cp.role = 'seeker'
          )
        )
      )
  ),
  milestone_rows as (
    select
      tm.occurred_at,
      'journey.timeline_milestone'::text as class_key,
      tm.id as source_id,
      mt.title_key,
      mt.detail_key,
      'connections.journeys'::text as destination_key,
      t.match_id as related_match_id,
      null::boolean as is_unread
    from public.timeline_milestones tm
    join milestone_templates mt on mt.milestone_type = tm.milestone_type
    join public.timelines t on t.id = tm.timeline_id
    where tm.occurred_at is not null
      and t.attempt_id is not null
      and t.match_id is not null
      and exists (
        select 1
        from caller_participation cp
        where cp.attempt_id = t.attempt_id
          and cp.match_id = t.match_id
          and (
            cp.role = 'seeker'
            or (
              cp.role = 'guardian'
              and cp.is_main is true
              and cp.attempt_status <> 'potential'
            )
          )
      )
  ),
  suggestion_rows as (
    select
      s.created_at as occurred_at,
      'guardian.suggestion'::text as class_key,
      s.id as source_id,
      'dashboard_updates.guardian.suggestion.title'::text as title_key,
      'dashboard_updates.guardian.suggestion.detail'::text as detail_key,
      'guardian'::text as destination_key,
      null::uuid as related_match_id,
      null::boolean as is_unread
    from public.wali_suggestions s
    where s.created_at is not null
      -- The current app exposes pending suggestions to the Seeker only.
      -- Guardian-side suggestion creation/history UI remains unbuilt, so a
      -- Guardian author row is not audience authority for this projection.
      and s.seeker_id = v_caller
  ),
  review_opened_rows as (
    select
      r.opened_at as occurred_at,
      'guardian.review_opened'::text as class_key,
      r.id as source_id,
      'dashboard_updates.guardian.review_opened.title'::text as title_key,
      'dashboard_updates.guardian.review_opened.detail'::text as detail_key,
      'connections.journeys'::text as destination_key,
      r.match_id as related_match_id,
      null::boolean as is_unread
    from public.journey_family_reviews r
    where r.opened_at is not null
      and r.attempt_id is not null
      and r.match_id is not null
      and exists (
        select 1
        from caller_participation cp
        where cp.attempt_id = r.attempt_id
          and cp.match_id = r.match_id
          and (
            cp.role = 'seeker'
            or (cp.role = 'guardian' and cp.is_main is true)
          )
      )
  ),
  review_answered_rows as (
    select
      rr.responded_at as occurred_at,
      'guardian.review_answered'::text as class_key,
      -- Deterministic pseudonymous key derived from the composite primary key;
      -- it is stable for pagination and is not an anonymity guarantee.
      md5(rr.review_id::text || ':' || rr.wali_id::text)::uuid as source_id,
      'dashboard_updates.guardian.review_answered.title'::text as title_key,
      'dashboard_updates.guardian.review_answered.detail'::text as detail_key,
      'connections.journeys'::text as destination_key,
      r.match_id as related_match_id,
      null::boolean as is_unread
    from public.journey_family_review_responses rr
    join public.journey_family_reviews r on r.id = rr.review_id
    where rr.responded_at is not null
      and r.attempt_id is not null
      and r.match_id is not null
      and exists (
        select 1
        from caller_participation cp
        where cp.attempt_id = r.attempt_id
          and cp.match_id = r.match_id
          and (
            cp.role = 'seeker'
            or (cp.role = 'guardian' and cp.is_main is true)
          )
      )
  ),
  updates as (
    select * from notification_rows
    union all
    select * from milestone_rows
    union all
    select * from suggestion_rows
    union all
    select * from review_opened_rows
    union all
    select * from review_answered_rows
  )
  select
    u.occurred_at,
    u.class_key,
    u.source_id,
    u.title_key,
    u.detail_key,
    u.destination_key,
    u.related_match_id,
    u.is_unread
  from updates u
  where p_cursor_occurred_at is null
     or (u.occurred_at, u.class_key, u.source_id)
        < (p_cursor_occurred_at, p_cursor_class_key, p_cursor_source_id)
  order by u.occurred_at desc, u.class_key desc, u.source_id desc
  limit v_limit;
end;
$$;

comment on function public.zyra_dashboard_updates(
  integer,
  timestamptz,
  text,
  uuid
) is
  'OA-ZYRA-281: caller-scoped, allowlisted, read-only meaningful-movement projection — unread-backed notifications + authoritative domain events; NOT an inbox or history; the Notifications manager is the history surface. is_unread is three-state: TRUE means an unread notification; FALSE is reserved for a future explicit read-notification projection; NULL means a domain event and must never be rendered as read.';

revoke execute on function public.zyra_dashboard_updates(
  integer,
  timestamptz,
  text,
  uuid
) from public, anon;

grant execute on function public.zyra_dashboard_updates(
  integer,
  timestamptz,
  text,
  uuid
) to authenticated, service_role;
