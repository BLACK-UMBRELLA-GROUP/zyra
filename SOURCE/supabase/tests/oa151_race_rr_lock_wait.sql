-- Real stale-snapshot worker blocked behind writer, not a sequential race.
\set ON_ERROR_STOP on
set statement_timeout='3s';
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then
    raise exception 'OA151 RR observation isolation refused';
  end if;
end; $guard$;
select pg_stat_clear_snapshot();
with observed as materialized (
  select exists(select 1 from pg_stat_activity a join pg_stat_activity b
    on a.datname=b.datname where a.datname=current_database()
      and a.application_name='OA151_RR_STALE' and a.wait_event_type='Lock'
      and b.application_name='OA151_RR_WRITER' and b.xact_start is not null
      and b.pid=any(pg_blocking_pids(a.pid))) as ok
), recorded as (
  insert into oa151_synthetic.race_outcomes(name,proved)
    select 'rr_actual_lock_wait',true from observed where ok
    on conflict(name) do update set proved=true returning proved
)
select ok from observed;
