-- OA-ZYRA-299 / DR-ZYRA-241 — server-authoritative Paused return initiation.
--
-- History remains visible to every member. Only the transition from settled
-- Paused -> resume_requested is gated. Recipient answers stay free. The
-- separate Ended -> new Journey path remains revoked by OA-ZYRA-156 and this
-- migration intentionally does not touch or re-grant it.

create function public.zyra_guard_paused_return_initiation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller uuid := auth.uid();
begin
  if old.pause_state <> 'paused' or new.pause_state <> 'resume_requested' then
    return new;
  end if;

  -- Trusted maintenance has no member JWT. The public transition RPC always
  -- retains auth.uid(), even though it is SECURITY DEFINER.
  if v_caller is null then return new; end if;

  if v_caller not in (new.seeker_a_id, new.seeker_b_id) then
    raise exception 'not_a_party';
  end if;

  if not exists (
    select 1
    from public.subscriptions s
    where s.user_id = v_caller
      and s.plan_type = 'seeker_premium'
      and s.status = 'active'
  ) then
    raise exception 'return_membership_required';
  end if;

  if not exists (
    select 1
    from (
      select m.id
      from public.matches m
      where m.status = 'active'
        and m.pause_state in ('paused', 'resume_requested')
        and v_caller in (m.seeker_a_id, m.seeker_b_id)
      order by m.suspended_at desc nulls last, m.id desc
      limit 5
    ) recent
    where recent.id = new.id
  ) then
    raise exception 'return_window_exceeded';
  end if;

  return new;
end;
$$;

revoke all on function public.zyra_guard_paused_return_initiation()
  from public, anon, authenticated;

create trigger matches_guard_paused_return_initiation
before update of pause_state on public.matches
for each row
when (old.pause_state is distinct from new.pause_state)
execute function public.zyra_guard_paused_return_initiation();

comment on function public.zyra_guard_paused_return_initiation() is
  'Paid initiation gate for the five most recent Paused Journeys. Does not gate recipient answers or history visibility.';
