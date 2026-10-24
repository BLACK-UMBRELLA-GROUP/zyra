-- DR-ZYRA-230 / OA-ZYRA-288 — STAGED ONLY. Do not apply without the
-- Founder's separate migration apply GO after review of this exact file.
--
-- Founder ruling, 2026-09-17: every active Guardian has Journey information.
-- Preserve the existing four-field data-minimised summary and caller/Seeker
-- binding. Additional Guardians receive current active/paused summary rows and
-- ended rows from their own continuous active-link period. The existing
-- Seeker-controlled full-history grant remains Main-only. This migration does
-- not widen Main-only actions or expose counterpart identity, stage, messages,
-- compatibility answers, end reasons, notes or safety information.

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
  ),
  current_guardian_link as materialized (
    select
      w.id,
      w.active_since,
      w.is_main,
      w.main_guardian_authority_id
    from public.wali_links w
    cross join caller c
    where c.user_id is not null
      and w.seeker_id = p_seeker
      and w.wali_id = c.user_id
      and w.status = 'active'
  )
  select
    a.id,
    a.started_at,
    a.ended_at,
    (a.status = 'ended')
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  cross join current_guardian_link w
  where p_seeker in (m.seeker_a_id, m.seeker_b_id)
    and (
      a.status = 'active'
      or (
        a.status = 'ended'
        and (
          a.ended_at >= w.active_since
          or (
            w.is_main is true
            and exists (
              select 1
              from public.guardian_journey_history_consents c
              where c.wali_link_id = w.id
                and c.main_guardian_authority_id =
                  w.main_guardian_authority_id
            )
          )
        )
      )
    );
$function$;

comment on function public.zyra_attempt_summary_for_guardian(uuid) is
  'DR-ZYRA-230. CALLER-BOUND ACTIVE GUARDIANS. Every active Guardian receives '
  'the current active/paused attempt plus ended attempts from their own '
  'continuous active-link period. A valid assignment-bound full-history '
  'grant can widen ended history only for the current Main Guardian. Positive '
  'active/ended allowlist fails future statuses closed. Four fields only; '
  'never counterpart, stage, messages, answers, reason, notes or safety data.';

revoke execute on function public.zyra_attempt_summary_for_guardian(uuid)
  from public, anon;
grant execute on function public.zyra_attempt_summary_for_guardian(uuid)
  to authenticated, service_role;
