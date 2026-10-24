-- Real pg_stat_activity/pg_blocking_pids observation, not sequential simulation.
\set ON_ERROR_STOP on
set statement_timeout='3s';
do $guard$
begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then raise exception 'OA151 observation isolation refused'; end if;
end; $guard$;
select pg_stat_clear_snapshot();
-- Root polls this bounded boolean until true, while both workers remain alive.
with observed as materialized (
  select exists(select 1 from pg_stat_activity a join pg_stat_activity b
    on a.datname=b.datname where a.datname=current_database()
      and a.application_name='OA151_BASIC_A' and a.xact_start is not null
      and b.application_name='OA151_BASIC_B' and b.wait_event_type='Lock'
      and a.pid=any(pg_blocking_pids(b.pid))) as ok
), recorded as (
  insert into oa151_synthetic.race_outcomes(name,proved)
    select 'actual_basic_lock_wait',true from observed where ok
    on conflict(name) do update set proved=true returning proved
)
select ok from observed;
