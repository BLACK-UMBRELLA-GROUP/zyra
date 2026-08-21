-- v2 of zyra_dev_seed_journey (DR-ZYRA-180), same migration day.
-- v1 inserted journey_attempts itself — but zyra_create_first_attempt()
-- already makes attempt 1 on every matches insert, and
-- zyra_enforce_one_active_attempt() already holds the PLAN-AWARE limit
-- (Basic 1, One 3). So: let the triggers do their jobs, read the
-- attempt they made, and translate the limit refusal into words.
create or replace function public.zyra_dev_seed_journey()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  caller    uuid := (select auth.uid());
  v_email   text;
  v_gender  text;
  v_partner uuid;
  v_name    text;
  v_current text;
  v_match   uuid;
  v_attempt uuid;
begin
  if caller is null then raise exception 'not_signed_in'; end if;

  select email into v_email from auth.users where id = caller;
  if v_email is null or v_email not like '%@zyra.test' then
    raise exception 'dev_only'
      using hint = 'Seeding a Journey is limited to seeded @zyra.test accounts.';
  end if;

  select gender into v_gender from profiles where id = caller;
  if v_gender is null then raise exception 'no_profile_gender'; end if;

  -- First seeded browse account of the opposite gender that is free:
  -- no active match of their own, never matched with the caller before.
  select u.id, p.first_name into v_partner, v_name
    from auth.users u
    join profiles p on p.id = u.id
   where u.email like 'dev.browse.%@zyra.test'
     and p.gender is distinct from v_gender
     and not exists (select 1 from matches m
                      where m.status = 'active'
                        and (m.seeker_a_id = u.id or m.seeker_b_id = u.id))
     and not exists (select 1 from matches m
                      where (m.seeker_a_id = u.id and m.seeker_b_id = caller)
                         or (m.seeker_b_id = u.id and m.seeker_a_id = caller))
   order by u.email
   limit 1;
  if v_partner is null then
    raise exception 'no_free_partner'
      using hint = 'Every seeded browse account of the opposite gender is taken or already matched with you.';
  end if;

  begin
    insert into matches (seeker_a_id, seeker_b_id, status, journey_stage)
    values (v_partner, caller, 'active', 'compatibility_reveal')
    returning id into v_match;
  exception when others then
    if sqlerrm = 'one_active_journey_limit' then
      select p.first_name into v_current
        from matches m
        join profiles p on p.id = case when m.seeker_a_id = caller then m.seeker_b_id else m.seeker_a_id end
       where m.status = 'active' and m.suspended_by is null
         and (m.seeker_a_id = caller or m.seeker_b_id = caller)
       order by m.created_at desc limit 1;
      return format('Your plan''s live-Journey slots are full%s — End or pause one, then seed again.',
                    case when v_current is null then '' else format(' (you''re with %s)', v_current) end);
    end if;
    raise;
  end;

  -- zyra_create_first_attempt() made attempt 1 during the insert above.
  select id into v_attempt from journey_attempts
   where match_id = v_match and attempt_number = 1;
  if v_attempt is null then raise exception 'attempt_not_created'; end if;

  insert into conversations (match_id, attempt_id, status)
  values (v_match, v_attempt, 'closed')
  on conflict (attempt_id) do nothing;

  insert into timelines (match_id, attempt_id)
  values (v_match, v_attempt)
  on conflict (attempt_id) do nothing;

  return format('Seeded a real Journey with %s — it starts at Compatibility Reveal.', v_name);
end;
$$;

revoke all on function public.zyra_dev_seed_journey() from public;
grant execute on function public.zyra_dev_seed_journey() to authenticated;
