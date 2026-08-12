-- DR-ZYRA-136, Founder-approved 2026-08-10. Closes OA-ZYRA-173 and
-- contradiction-audit finding 2.9 with one principle:
--
--   OVERSIGHT THAT CAN BE SWITCHED OFF QUIETLY IS NOT OVERSIGHT.
--
-- The Guardian Gate requires a Main Guardian on BOTH sides before a Journey
-- can begin. Both families commit on that basis. Two paths let one Seeker
-- dissolve their own side of it afterwards, and this migration closes both.
--
-- THE COST, recorded rather than glossed: a Seeker whose Guardian becomes a
-- problem mid-Journey can no longer simply remove him. That is a real harm,
-- accepted because ENDING or PAUSING is always available and always free --
-- nobody is trapped in a process, only in the requirement that it has a
-- witness. Reopen if beta shows people held in Journeys by this rule.

-- 1. zyra_remove_guardian -- refuse the LAST Guardian during a live Journey.
--
-- The existing guard already refused removing your MAIN while others remain
-- (nothing would promote a replacement). What it explicitly permitted was
-- removing your last one: "that leaves an empty page, which is a real and
-- recoverable state". True between Journeys. Not true during one -- the empty
-- page is the other family deciding alone (OA-ZYRA-173, measured).
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
      using hint = 'Your Journey needs a Guardian on your side. Link someone '
                   'else first, or end or pause the Journey.';
  end if;

  update public.wali_links
     set status = 'removed', is_main = false
   where seeker_id = v_me and wali_id = p_wali_id;

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$function$;

-- 2. zyra_clear_main_guardian -- RETIRED.
--
-- Audit 2.9, Founder-ruled 2026-08-10: the no-Main-Guardian state is NOT
-- acceptable and the action must stop being offered.
--
-- This function had NO guard of any kind. It demoted your Main and stopped.
-- Its entire purpose was to produce the state the Founder has now forbidden:
-- Guardians present, none Main, so Family Review has no voter and the
-- Guardian's message access closes -- oversight ending with nothing said.
--
-- There is no legitimate caller. REASSIGNING Main is zyra_set_main_guardian,
-- which demotes the incumbent and promotes the replacement in one
-- transaction. Clearing WITHOUT a replacement is the forbidden act itself.
--
-- Retired rather than dropped, following restart_journey's precedent: a
-- caller reappearing later fails loudly, with the reason, instead of getting
-- a bare "function does not exist" from PostgREST.
CREATE OR REPLACE FUNCTION public.zyra_clear_main_guardian(p_wali_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
begin
  raise exception 'main_guardian_cannot_be_cleared'
    using hint = 'A Seeker may not be left without a Main Guardian '
                 '(DR-ZYRA-136). Choose a different Guardian as Main '
                 'instead -- zyra_set_main_guardian reassigns in one step.';
end;
$function$;

COMMENT ON FUNCTION public.zyra_clear_main_guardian(UUID) IS
  'RETIRED 2026-08-10 -- DR-ZYRA-136, contradiction-audit 2.9. Always throws. '
  'It created the no-Main-Guardian state, which the Founder has ruled '
  'unacceptable. Use zyra_set_main_guardian to reassign.';

COMMENT ON FUNCTION public.zyra_remove_guardian(UUID) IS
  'DR-ZYRA-136 / OA-ZYRA-173. Refuses removal of a Seeker''s LAST Guardian '
  'while they are party to an active Journey (a paused Journey counts -- '
  'pause is a flag on an active Journey, not a state). Ending or pausing '
  'the Journey remains free.';
