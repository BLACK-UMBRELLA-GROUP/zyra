-- OA-ZYRA-282 / DR-ZYRA-224 F6 / 044_FABLE-CODEX.
--
-- STAGED ONLY. This file must not be applied until the Founder gives the
-- separate apply GO after Fable verification and external security review.
--
-- Exactly two changes:
--   A. Narrow zyra_attempt_summary_for_guardian to the caller's active Main
--      Guardian relationship and exclude potential attempts.
--   B. Correct zyra_remove_guardian's false hint that pausing permits final
--      Guardian removal. Its enforcement logic is otherwise byte-for-byte
--      equivalent to the currently applied definition.

-- =====================================================================
-- Change A: the narrow successor/Main-Guardian Journey summary.
-- =====================================================================
create or replace function public.zyra_attempt_summary_for_guardian(
  p_seeker uuid
)
returns table (
  attempt_id uuid,
  started_at timestamptz,
  ended_at timestamptz,
  ended boolean
)
language sql
stable
security definer
set search_path = ''
as $function$
  with caller as materialized (
    select (select auth.uid()) as user_id
  )
  select
    a.id,
    a.started_at,
    a.ended_at,
    (a.status = 'ended')
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  cross join caller c
  where c.user_id is not null
    and a.status <> 'potential'
    and p_seeker in (m.seeker_a_id, m.seeker_b_id)
    and exists (
      select 1
      from public.wali_links w
      where w.seeker_id = p_seeker
        and w.wali_id = c.user_id
        and w.status = 'active'
        and w.is_main is true
    );
$function$;

comment on function public.zyra_attempt_summary_for_guardian(uuid) is
  'DR-ZYRA-224 F6 / OA-ZYRA-282. CALLER-BOUND, ACTIVE MAIN-GUARDIAN ONLY. '
  'Potential attempts are excluded. Returns only the opaque attempt identity, '
  'start/end timestamps, and whether the attempt ended; never stage, reason, '
  'notes, counterpart identity, or another Guardian''s observations.';

revoke execute on function public.zyra_attempt_summary_for_guardian(uuid)
  from public, anon;
grant execute on function public.zyra_attempt_summary_for_guardian(uuid)
  to authenticated, service_role;

-- =====================================================================
-- Change B: hint copy only. Enforcement logic is unchanged.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.zyra_remove_guardian(p_wali_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  v_me     uuid := auth.uid();
  v_main   boolean;
  v_others int;
  v_n      int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select is_main into v_main
  from public.wali_links
  where seeker_id = v_me and wali_id = p_wali_id and status = 'active';

  if not found then
    raise exception 'not_your_guardian';
  end if;

  select count(*) into v_others
  from public.wali_links
  where seeker_id = v_me and wali_id <> p_wali_id and status = 'active';

  -- UNCHANGED. Removing your Main while others remain leaves is_main unset
  -- with no promotion, and Family Review reads is_main.
  if coalesce(v_main, false) and v_others > 0 then
    raise exception 'main_guardian_must_be_reassigned';
  end if;

  -- NEW -- DR-ZYRA-136 / OA-ZYRA-173.
  -- Checked against `matches`, which stays authoritative until OA-ZYRA-156
  -- step 7. A paused Journey counts: pause is a behavioural flag on an
  -- ACTIVE Journey (DR-ZYRA-121 item 13), not a lifecycle state, so the
  -- commitment is still live and so is the requirement.
  if v_others = 0 and exists (
    select 1 from public.matches m
     where m.status = 'active'
       and (m.seeker_a_id = v_me or m.seeker_b_id = v_me)
  ) then
    raise exception 'guardian_required_during_journey'
      using hint = 'An active or paused Journey requires you to keep a '
                   'Guardian. Assign another Guardian where possible, or '
                   'end the Journey through the governed flow before '
                   'removing this one.';
  end if;

  update public.wali_links
     set status = 'removed', is_main = false
   where seeker_id = v_me and wali_id = p_wali_id;

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$function$;
