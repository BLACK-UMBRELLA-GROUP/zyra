-- OA-ZYRA-290 / DR-ZYRA-232
-- Additional Guardians may be included in a specific active Journey by their
-- own Seeker. Main Guardians remain included by role and cannot be switched
-- off. Inclusion grants the same read-only Journey surfaces currently
-- available to Main Guardians; Main-only decisions remain Main-only.
--
-- STAGED ONLY. This file must not be applied without a separate exact-hash
-- Founder GO.

begin;

create table public.journey_guardian_assignments (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.journey_attempts(id) on delete cascade,
  wali_link_id uuid not null references public.wali_links(id) on delete cascade,
  seeker_id uuid not null references public.profiles(id) on delete cascade,
  granted_by uuid not null references public.profiles(id),
  granted_at timestamptz not null default pg_catalog.clock_timestamp(),
  revoked_by uuid references public.profiles(id),
  revoked_at timestamptz,
  constraint journey_guardian_assignments_revocation_pair check (
    (revoked_at is null and revoked_by is null)
    or (revoked_at is not null and revoked_by is not null)
  )
);

create unique index journey_guardian_assignments_one_live
  on public.journey_guardian_assignments (attempt_id, wali_link_id)
  where revoked_at is null;

create index journey_guardian_assignments_link_history
  on public.journey_guardian_assignments (wali_link_id, granted_at desc);

alter table public.journey_guardian_assignments enable row level security;
revoke all on table public.journey_guardian_assignments
  from public, anon, authenticated;
grant all on table public.journey_guardian_assignments to service_role;

comment on table public.journey_guardian_assignments is
  'Audited per-attempt access grants for Additional Guardians. Live rows have '
  'revoked_at NULL. Main Guardians are never stored here because their active '
  'role is the non-optional Journey authority.';

-- One participation source remains authoritative. A current Main Guardian is
-- always present. An Additional Guardian is present only for an active attempt
-- with an unrevoked assignment belonging to their own Seeker link.
create or replace view public.zyra_attempt_participant_rows as
select a.id as attempt_id,
       m.seeker_a_id as user_id,
       'seeker'::text as role,
       a.match_id,
       null::boolean as is_main,
       a.status as attempt_status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
union all
select a.id,
       m.seeker_b_id,
       'seeker'::text,
       a.match_id,
       null::boolean,
       a.status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
union all
select a.id,
       w.wali_id,
       'guardian'::text,
       a.match_id,
       w.is_main,
       a.status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
join public.wali_links w
  on w.status = 'active'
 and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
where w.is_main is true
   or (
     a.status = 'active'
     and exists (
       select 1
       from public.journey_guardian_assignments jga
       where jga.attempt_id = a.id
         and jga.wali_link_id = w.id
         and jga.seeker_id = w.seeker_id
         and jga.revoked_at is null
     )
   );

comment on view public.zyra_attempt_participant_rows is
  'Canonical unscoped Journey participation: both Seekers; every current Main '
  'Guardian; and per-attempt Seeker-authorised Additional Guardians while the '
  'attempt remains active. Granted to nobody; clients use the caller-scoped '
  'zyra_my_attempt_participation view.';

revoke all on public.zyra_attempt_participant_rows
  from public, anon, authenticated;

create or replace view public.zyra_my_attempt_participation as
select attempt_id, role, match_id, is_main, attempt_status
from public.zyra_attempt_participant_rows
where user_id = (select auth.uid());

comment on view public.zyra_my_attempt_participation is
  'Caller-scoped projection of canonical Journey participation. Additional '
  'Guardians appear only while explicitly included in that active Journey.';

revoke all on public.zyra_my_attempt_participation from public, anon;
grant select on public.zyra_my_attempt_participation to authenticated;

-- The Seeker reads and changes only an active Guardian link that they own.
-- Supplying NULL/NULL is a read. Supplying an attempt and boolean is a write.
create or replace function public.zyra_guardian_journey_access(
  p_guardian uuid,
  p_attempt uuid default null,
  p_enabled boolean default null
)
returns table (
  attempt_id uuid,
  match_id uuid,
  counterpart_first_name text,
  included boolean,
  can_change boolean,
  guardian_is_main boolean
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_is_main boolean;
begin
  if v_caller is null then
    raise exception 'not_signed_in';
  end if;
  if p_guardian is null then
    raise exception 'guardian_required';
  end if;
  if (p_attempt is null) <> (p_enabled is null) then
    raise exception 'attempt_and_enabled_must_be_supplied_together';
  end if;

  select w.id, w.is_main
  into v_link_id, v_is_main
  from public.wali_links w
  where w.seeker_id = v_caller
    and w.wali_id = p_guardian
    and w.status = 'active';

  if not found then
    raise exception 'active_guardian_link_not_found';
  end if;

  if p_attempt is not null then
    if v_is_main then
      raise exception 'main_guardian_always_included';
    end if;
    if not exists (
      select 1
      from public.journey_attempts a
      join public.matches m on m.id = a.match_id
      where a.id = p_attempt
        and a.status = 'active'
        and v_caller in (m.seeker_a_id, m.seeker_b_id)
    ) then
      raise exception 'active_owned_journey_not_found';
    end if;

    if p_enabled then
      insert into public.journey_guardian_assignments (
        attempt_id, wali_link_id, seeker_id, granted_by
      ) values (
        p_attempt, v_link_id, v_caller, v_caller
      )
      on conflict (attempt_id, wali_link_id) where revoked_at is null
      do nothing;
    else
      update public.journey_guardian_assignments jga
      set revoked_by = v_caller,
          revoked_at = pg_catalog.clock_timestamp()
      where jga.attempt_id = p_attempt
        and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller
        and jga.revoked_at is null;
    end if;
  end if;

  return query
  select a.id,
         a.match_id,
         other_profile.first_name,
         (
           v_is_main
           or exists (
             select 1
             from public.journey_guardian_assignments jga
             where jga.attempt_id = a.id
               and jga.wali_link_id = v_link_id
               and jga.seeker_id = v_caller
               and jga.revoked_at is null
           )
         ),
         not v_is_main,
         v_is_main
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  join public.profiles other_profile
    on other_profile.id = case
      when m.seeker_a_id = v_caller then m.seeker_b_id
      else m.seeker_a_id
    end
  where a.status = 'active'
    and v_caller in (m.seeker_a_id, m.seeker_b_id)
  order by a.started_at desc nulls last, a.created_at desc, a.id;
end;
$function$;

revoke execute on function public.zyra_guardian_journey_access(uuid, uuid, boolean)
  from public, anon;
grant execute on function public.zyra_guardian_journey_access(uuid, uuid, boolean)
  to authenticated, service_role;

comment on function public.zyra_guardian_journey_access(uuid, uuid, boolean) is
  'Reads or changes one Seeker-owned Guardian link across the caller''s active '
  'Journeys. Main is immutable ON. Additional changes are server-confirmed, '
  'per attempt and audited; no caller may act for the other Seeker.';

-- Full Journey reads now follow canonical participation. Main-only decision
-- tables/RPCs are intentionally untouched.
drop policy if exists conversations_select on public.conversations;
create policy conversations_select on public.conversations
for select using (
  exists (
    select 1 from public.zyra_my_attempt_participation r
    where r.attempt_id = conversations.attempt_id
      and (
        r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status <> 'potential')
      )
  )
);

drop policy if exists messages_select on public.messages;
create policy messages_select on public.messages
for select using (
  exists (
    select 1
    from public.conversations c
    join public.zyra_my_attempt_participation r
      on r.attempt_id = c.attempt_id
    where c.id = messages.conversation_id
      and (
        r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status <> 'potential')
      )
  )
);

drop policy if exists timelines_select on public.timelines;
create policy timelines_select on public.timelines
for select using (
  exists (
    select 1 from public.zyra_my_attempt_participation r
    where r.attempt_id = timelines.attempt_id
      and (
        r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status <> 'potential')
      )
  )
);

drop policy if exists timeline_milestones_select on public.timeline_milestones;
create policy timeline_milestones_select on public.timeline_milestones
for select using (
  exists (
    select 1
    from public.timelines t
    join public.zyra_my_attempt_participation r
      on r.attempt_id = t.attempt_id
    where t.id = timeline_milestones.timeline_id
      and (
        r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status <> 'potential')
      )
  )
);

drop policy if exists journey_family_answers_read on public.journey_family_answers;
create policy journey_family_answers_read on public.journey_family_answers
for select using (
  exists (
    select 1 from public.zyra_my_attempt_participation r
    where r.attempt_id = journey_family_answers.attempt_id
      and r.role in ('seeker', 'guardian')
  )
);

drop policy if exists matches_select on public.matches;
create policy matches_select on public.matches
for select using (
  seeker_a_id = (select auth.uid())
  or seeker_b_id = (select auth.uid())
  or exists (
    select 1
    from public.journey_attempts a
    join public.wali_links w
      on w.wali_id = (select auth.uid())
     and w.status = 'active'
     and w.seeker_id in (matches.seeker_a_id, matches.seeker_b_id)
    where a.match_id = matches.id
      and a.status <> 'potential'
      and (
        w.is_main is true
        or (
          a.status = 'active'
          and exists (
            select 1
            from public.journey_guardian_assignments jga
            where jga.attempt_id = a.id
              and jga.wali_link_id = w.id
              and jga.seeker_id = w.seeker_id
              and jga.revoked_at is null
          )
        )
      )
  )
);

create or replace function public.zyra_counterpart_card(p_match_id uuid)
returns table (
  counterpart_first_name text,
  counterpart_age integer,
  guardian_first_name text,
  guardian_surname_line text,
  guardian_contact text
)
language sql
stable
security definer
set search_path = ''
as $function$
  with m as (
    select mm.*
    from public.matches mm
    where mm.id = p_match_id
      and mm.status <> 'potential'
      and mm.end_reason is distinct from 'safety_concern'
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
           or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
      )
  ),
  mine as (
    select w.seeker_id as my_ward
    from m
    join public.wali_links w
      on w.wali_id = (select auth.uid())
     and w.status = 'active'
     and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
    where w.is_main is true
       or exists (
         select 1
         from public.journey_attempts a
         join public.journey_guardian_assignments jga
           on jga.attempt_id = a.id
          and jga.wali_link_id = w.id
          and jga.seeker_id = w.seeker_id
          and jga.revoked_at is null
         where a.match_id = m.id
           and a.status = 'active'
       )
    limit 1
  ),
  other as (
    select case when mine.my_ward = m.seeker_a_id then m.seeker_b_id
                else m.seeker_a_id end as other_seeker
    from m, mine
  )
  select p.first_name,
         date_part('year', age(p.date_of_birth))::int,
         g.first_name,
         g.surname_line,
         null::text
  from other
  join public.profiles p on p.id = other.other_seeker
  left join public.wali_links ow
    on ow.seeker_id = other.other_seeker
   and ow.status = 'active'
   and ow.is_main is true
  left join public.profiles g on g.id = ow.wali_id;
$function$;

revoke execute on function public.zyra_counterpart_card(uuid)
  from public, anon;
grant execute on function public.zyra_counterpart_card(uuid)
  to authenticated;

comment on function public.zyra_counterpart_card(uuid) is
  'Restricted counterpart identity card for an authorised Guardian Journey '
  'participant. Main participates by role; Additional participates only while '
  'the owning Seeker includes them in that active Journey.';

commit;
