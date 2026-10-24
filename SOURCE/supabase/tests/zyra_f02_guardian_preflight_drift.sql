-- F02 synthetic fail-closed preflight test setup, NOT a project migration.
-- Root runs one fresh isolated bootstrap per case, invokes this file with
-- -v f02_drift_kind=view|policy|grant|helper|trigger|column_grant|
-- private_column_grant|constraint|index, then supplies the new
-- staged migration. Each candidate invocation MUST fail before durable DDL.
\set ON_ERROR_STOP on
select set_config('zyra.f02_drift_kind', :'f02_drift_kind', false);
do $drift_fixture$
begin
  if current_database() not like 'zyra_oa305_f02_%'
     or current_setting('zyra.synthetic_f02',true) is distinct from 'yes'
     or current_user <> 'postgres'
  then raise exception 'F02 drift fixture requires isolated synthetic bootstrap'; end if;
  case current_setting('zyra.f02_drift_kind')
    when 'view' then
      create or replace view public.zyra_attempt_participant_rows as
      select attempt_id,user_id,role,match_id,is_main,attempt_status,true as can_chat
      from (select a.id as attempt_id,m.seeker_a_id as user_id,'seeker'::text as role,
                   a.match_id,null::boolean as is_main,a.status as attempt_status
            from public.journey_attempts a join public.matches m on m.id=a.match_id) changed;
    when 'policy' then
      create policy f02_unexpected_permissive_select on public.messages
        for select using (false);
    when 'grant' then
      grant select on public.zyra_attempt_participant_rows to authenticated;
    when 'column_grant' then
      grant select(user_id) on public.zyra_attempt_participant_rows to authenticated;
    when 'private_column_grant' then
      grant select(granted_at) on public.journey_guardian_assignments to authenticated;
    when 'constraint' then
      alter table public.wali_links drop constraint wali_links_active_since_state;
      alter table public.wali_links add constraint wali_links_active_since_state
        check (status <> 'active' or active_since is not null);
    when 'index' then
      drop index public.journey_guardian_assignments_one_live;
      create index journey_guardian_assignments_one_live
        on public.journey_guardian_assignments(attempt_id,wali_link_id) where revoked_at is null;
    when 'helper' then
      alter function public.auto_designate_main_wali() set search_path='public';
    when 'trigger' then
      alter table public.wali_links disable trigger wali_links_auto_main;
    else raise exception 'Unknown F02 drift kind';
  end case;
  raise notice 'F02 synthetic drift installed; candidate must refuse %',current_setting('zyra.f02_drift_kind');
end;
$drift_fixture$;
