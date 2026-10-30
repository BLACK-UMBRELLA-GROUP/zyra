-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317 / OA-ZYRA-319.
-- Local proof only; production requires a separate exact-payload Founder GO.

begin;

create or replace function public.zyra_clear_main_guardian(p_wali_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_n integer;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  update public.wali_links
     set is_main = false
   where seeker_id = v_me
     and wali_id = p_wali_id
     and status = 'active'
     and is_main is true;

  get diagnostics v_n = row_count;
  if v_n = 0 then
    raise exception 'not_your_main_guardian';
  end if;

  return true;
end;
$function$;

comment on function public.zyra_clear_main_guardian(uuid) is
  'DR-ZYRA-236. Caller-bound Seeker action. Demotes the caller''s current '
  'active Main Guardian without unlinking them. The resulting deliberate '
  'no-Main state raises a My ZYRA action and holds ordinary Active Journey '
  'participation in the client until another Main Guardian is assigned. '
  'Ending remains available.';

revoke execute on function public.zyra_clear_main_guardian(uuid)
  from public, anon;
grant execute on function public.zyra_clear_main_guardian(uuid)
  to authenticated, service_role;

create or replace function public.zyra_remove_guardian(p_wali_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_n integer;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  if not exists (
    select 1
    from public.wali_links w
    where w.seeker_id = v_me
      and w.wali_id = p_wali_id
      and w.status = 'active'
  ) then
    raise exception 'not_your_guardian';
  end if;

  update public.wali_links
     set status = 'removed',
         is_main = false
   where seeker_id = v_me
     and wali_id = p_wali_id
     and status = 'active';

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$function$;

comment on function public.zyra_remove_guardian(uuid) is
  'DR-ZYRA-236. Caller-bound Seeker unlink action. A Main Guardian may be '
  'removed without automatic replacement; remaining Guardians stay '
  'Additional until the Seeker deliberately chooses a Main. A no-Main state '
  'holds ordinary Active Journey participation in the client while '
  'Ending remains available.';

revoke execute on function public.zyra_remove_guardian(uuid)
  from public, anon;
grant execute on function public.zyra_remove_guardian(uuid)
  to authenticated, service_role;

-- Caller-scoped read used by the app. It reveals only whether the two required
-- leadership roles exist; it does not reveal Guardian identity, link count,
-- relationship, history permission or Additional-Guardian participation.
create or replace function public.zyra_journey_main_guardian_gate(
  p_match_id uuid
)
returns table (
  self_has_main boolean,
  other_has_main boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_a uuid;
  v_b uuid;
  v_other uuid;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  select m.seeker_a_id, m.seeker_b_id
    into v_a, v_b
  from public.matches m
  where m.id = p_match_id;

  if not found or v_me not in (v_a, v_b) then
    raise exception 'journey_not_available';
  end if;

  v_other := case when v_me = v_a then v_b else v_a end;

  return query
  select
    exists (
      select 1
      from public.wali_links w
      where w.seeker_id = v_me
        and w.status = 'active'
        and w.is_main is true
    ),
    exists (
      select 1
      from public.wali_links w
      where w.seeker_id = v_other
        and w.status = 'active'
        and w.is_main is true
    );
end;
$function$;

comment on function public.zyra_journey_main_guardian_gate(uuid) is
  'DR-ZYRA-236. Caller-bound Journey gate. Returns only whether the caller '
  'and counterpart each have an active Main Guardian. No Guardian identity '
  'or link detail is disclosed.';

revoke execute on function public.zyra_journey_main_guardian_gate(uuid)
  from public, anon;
grant execute on function public.zyra_journey_main_guardian_gate(uuid)
  to authenticated, service_role;

-- One trigger boundary covers the current ordinary Journey write surfaces.
-- It checks BOTH Seekers so one side cannot advance shared state while the
-- other side has deliberately removed Main leadership. auth.uid() null is a
-- trusted server/service path; a Guardian caller is not a romantic party and
-- continues to be governed by the existing Main/Additional policies.
create or replace function public.zyra_enforce_main_guardian_journey_hold()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_payload jsonb := to_jsonb(new);
  v_match_id uuid;
  v_attempt_id uuid;
  v_a uuid;
  v_b uuid;
  v_match_status text;
begin
  if v_me is null then
    return new;
  end if;

  if tg_table_name = 'matches' then
    v_match_id := new.id;
  else
    v_match_id := nullif(v_payload ->> 'match_id', '')::uuid;
  end if;
  v_attempt_id := nullif(v_payload ->> 'attempt_id', '')::uuid;

  -- Messages belong to a conversation rather than carrying match_id or
  -- attempt_id directly. Resolve that existing ownership chain explicitly;
  -- never infer Journey identity from a timestamp or sender.
  if tg_table_name = 'messages' then
    select c.attempt_id
      into v_attempt_id
    from public.conversations c
    where c.id = nullif(v_payload ->> 'conversation_id', '')::uuid;
  end if;

  if v_match_id is null and v_attempt_id is not null then
    select a.match_id into v_match_id
    from public.journey_attempts a
    where a.id = v_attempt_id;
  end if;

  if v_match_id is null then
    raise exception 'journey_guardian_gate_context_missing';
  end if;

  select m.seeker_a_id, m.seeker_b_id, m.status
    into v_a, v_b, v_match_status
  from public.matches m
  where m.id = v_match_id;

  if not found or v_me not in (v_a, v_b) then
    return new;
  end if;

  -- A BEFORE UPDATE reads the old pair row. Use the proposed lifecycle for
  -- activation and End so the hold cannot be bypassed by that transition.
  if tg_table_name = 'matches' then
    v_match_status := new.status;
  end if;

  -- The Founder ruling holds Active Journey participation only. Existing
  -- protections continue to govern potential and ended records.
  if v_match_status is distinct from 'active' then
    return new;
  end if;

  if not exists (
      select 1 from public.wali_links w
      where w.seeker_id = v_a
        and w.status = 'active'
        and w.is_main is true
    ) or not exists (
      select 1 from public.wali_links w
      where w.seeker_id = v_b
        and w.status = 'active'
        and w.is_main is true
    ) then
    raise exception 'main_guardian_required_for_journey'
      using hint = 'Ordinary Journey participation is held until both '
                   'Seekers have an active Main Guardian. End '
                   'remain available.';
  end if;

  return new;
end;
$function$;

comment on function public.zyra_enforce_main_guardian_journey_hold() is
  'DR-ZYRA-236 trigger boundary. Blocks ordinary shared-Journey writes and '
  'activation while either Seeker lacks an active Main Guardian. It does not '
  'block End.';

revoke execute on function public.zyra_enforce_main_guardian_journey_hold()
  from public, anon, authenticated;
grant execute on function public.zyra_enforce_main_guardian_journey_hold()
  to service_role;

do $block$
declare
  v_table text;
begin
  foreach v_table in array array[
    'journey_salams',
    'journey_stage_checkpoints',
    'journey_phase_answers',
    'journey_phase_ratings',
    'journey_phase_checkpoints',
    'journey_family_answers',
    'journey_family_reviews',
    'messages'
  ] loop
    execute format(
      'drop trigger if exists %I on public.%I',
      v_table || '_main_guardian_hold',
      v_table
    );
    execute format(
      'create trigger %I before insert or update on public.%I '
      'for each row execute function public.zyra_enforce_main_guardian_journey_hold()',
      v_table || '_main_guardian_hold',
      v_table
    );
  end loop;
end;
$block$;

drop trigger if exists journey_compatibility_main_guardian_hold
  on public.journey_compatibility;
create trigger journey_compatibility_main_guardian_hold
before update on public.journey_compatibility
for each row
execute function public.zyra_enforce_main_guardian_journey_hold();

drop trigger if exists matches_main_guardian_hold on public.matches;
create trigger matches_main_guardian_hold
before update on public.matches
for each row
when (
  new.status = 'active'
  and (old.journey_stage is distinct from new.journey_stage
       or old.status is distinct from new.status)
)
execute function public.zyra_enforce_main_guardian_journey_hold();

drop trigger if exists journey_attempts_main_guardian_hold
  on public.journey_attempts;
create trigger journey_attempts_main_guardian_hold
before update on public.journey_attempts
for each row
when (
  new.status = 'active'
  and (old.journey_stage is distinct from new.journey_stage
       or old.status is distinct from new.status)
)
execute function public.zyra_enforce_main_guardian_journey_hold();

commit;
