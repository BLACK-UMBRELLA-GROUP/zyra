-- Restore the caller-scoped safety case endpoint used by Help & Support.
--
-- Production currently predates the Guardian Circle reporting tables, while
-- the client and later paid-only contract already expect this RPC. Keep one
-- migration valid on both sides of that rollout: today it returns profile
-- reports; once family_message_reports exists it includes those cases too.
create or replace function public.zyra_my_safety_cases()
returns table (
  case_id uuid,
  case_type text,
  status text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  if to_regclass('public.family_message_reports') is null then
    return query
      select report.id, 'profile'::text, report.status,
             report.created_at, report.reviewed_at
      from public.profile_reports report
      where report.reporter_id = v_me
      order by report.created_at desc, report.id desc;
    return;
  end if;

  return query execute $query$
    select report.id, 'profile'::text, report.status,
           report.created_at, report.reviewed_at
    from public.profile_reports report
    where report.reporter_id = $1
    union all
    select report.id, 'guardian_circle'::text, report.status,
           report.created_at, report.reviewed_at
    from public.family_message_reports report
    where report.reporter_id = $1
    order by created_at desc, id desc
  $query$ using v_me;
end;
$$;

revoke all on function public.zyra_my_safety_cases()
  from public, anon;
grant execute on function public.zyra_my_safety_cases()
  to authenticated;

comment on function public.zyra_my_safety_cases() is
  'Caller-scoped safety case status only. Never returns the reported person identity and remains available regardless of membership state.';
