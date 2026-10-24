-- F06/F07 / OA-ZYRA-285, OA-ZYRA-192: PREPARED, NOT PRODUCTION-APPLIED.
-- Local/synthetic Founder GO only. Exact production GO must identify final
-- hashes, fresh catalog, lifecycle/retention limits, rollback and release gates.
-- No grants/backfill, balances, scoring, provider, purchase or Plus activation.
-- Legacy five-type entitlements remain rows; only both paid_plus_* are Plus.
-- New Plus INSERT is a no-op at the table boundary while held, so a future
-- automatic nonfinancial Journey grant cannot abort its enclosing Journey.
-- RPCs report the hold truthfully; a NEW negative Plus ledger entry is refused.
-- No seed/email/metadata/GUC exemption. Existing unchanged Plus is preserved.
--
-- Private account revisions serialize all ledger/entitlement writers and make
-- stale RR/SERIALIZABLE transactions retry (40001) instead of using an old SUM.
-- Successful receipts bind server actor/target/normalized tier; no sensitive
-- response is replayed, no client refresh/key selects a new paid operation.
-- Receipts/guards are new bookkeeping, not calculation snapshots (F12 held).
-- They cascade on subject erasure; privileged dev-reset does not erase receipts:
-- missing entitlement beside a receipt returns recovery_required, never recharge.
-- Retention period, target-erasure reconciliation, provider receipts and lawful
-- receipt audit retention remain unselected production gates, not solved here.
-- Pre-commit failure rolls back; post-commit prefer reviewed forward repair.
-- Restoring old functions/triggers reopens overspend/Plus-hold bypass, not a
-- safe automatic rollback. Releasing Plus needs later exact GO + new contract.

begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
do $preflight$
declare
  expected record;
begin
  if pg_catalog.to_regnamespace('private') is null
     or pg_catalog.to_regclass('public.profile_unlocks') is null
     or pg_catalog.to_regclass('public.unlock_credits') is null then
    raise exception 'F06/F07 precondition: required catalog absent';
  end if;
  if exists (select 1 from pg_trigger where not tgisinternal
             and tgrelid in ('public.profile_unlocks'::regclass,
                             'public.unlock_credits'::regclass))
     or exists (select 1 from pg_class
                where oid in ('public.profile_unlocks'::regclass,
                              'public.unlock_credits'::regclass)
                  and not relrowsecurity)
     or has_table_privilege('authenticated', 'public.profile_unlocks', 'INSERT,UPDATE,DELETE')
     or has_table_privilege('authenticated', 'public.unlock_credits', 'INSERT,UPDATE,DELETE')
     or has_table_privilege('anon', 'public.profile_unlocks', 'INSERT,UPDATE,DELETE')
     or has_table_privilege('anon', 'public.unlock_credits', 'INSERT,UPDATE,DELETE') then
    raise exception 'F06/F07 catalog drift: trigger/RLS/member write grants';
  end if;
  if (select count(*) from pg_policies where schemaname = 'public'
      and tablename in ('profile_unlocks', 'unlock_credits')) <> 2
     or not exists (select 1 from pg_policies where schemaname = 'public'
        and tablename = 'profile_unlocks' and policyname = 'profile_unlocks_select'
        and cmd = 'SELECT' and roles = array['public']::name[]
        and qual = '(unlocker_id = ( SELECT auth.uid() AS uid))' and with_check is null)
     or not exists (select 1 from pg_policies where schemaname = 'public'
        and tablename = 'unlock_credits' and policyname = 'unlock_credits_select_own'
        and cmd = 'SELECT' and roles = array['public']::name[]
        and qual = '(user_id = ( SELECT auth.uid() AS uid))' and with_check is null)
     or not exists (select 1 from pg_indexes where schemaname = 'public'
        and tablename = 'profile_unlocks' and indexname = 'profile_unlocks_once'
        and indexdef = 'CREATE UNIQUE INDEX profile_unlocks_once ON public.profile_unlocks USING btree (unlocker_id, unlocked_id, unlock_type)') then
    raise exception 'F06/F07 catalog drift: own-row policies/permanence index';
  end if;
  for expected in select * from (values
    ('zyra_unlock_profile(uuid,text)', '589ee352818cd72d8c0acb463c91df62'),
    ('zyra_dev_set_plus_unlock(uuid,boolean)', '04ced28b7d35e8c7b69fca323bb4bf68'),
    ('zyra_debug_grant_credits(text,integer)', '6b67563c333ce5f841cfcea82da3af2b'),
    ('grant_zyra_one_credits()', '6a85b2417d5b067df1f18233c3b6217e'),
    ('zyra_dev_reset_account()', '667a0df2264b13193cb2f4c6c2e39a4a'),
    ('zyra_can_view_profile(uuid)', '10bebeecc1fb937cc257816711baf99b')
  ) as signatures(signature, definition_md5)
  loop
    if pg_catalog.md5(pg_catalog.pg_get_functiondef(
        ('public.' || expected.signature)::regprocedure)) <> expected.definition_md5 then
      raise exception 'F06/F07 catalog drift: function %', expected.signature;
    end if;
  end loop;
  if not exists (select 1 from pg_proc p join pg_roles r on r.oid = p.proowner
    where p.oid = 'public.zyra_unlock_profile(uuid,text)'::regprocedure
      and r.rolname = 'postgres' and (r.rolsuper or r.rolbypassrls)) then
    raise exception 'F06/F07 precondition: privileged lookup owner';
  end if;
end;
$preflight$;

create table private.zyra_unlock_release_gate (
  singleton boolean primary key default true check (singleton),
  plus_spend_enabled boolean not null default false,
  -- A flag flip is NOT a validated result/launch gate. Enabling requires a
  -- separately reviewed DDL/contract migration, never a member/seed switch.
  constraint zyra_plus_release_held check (not plus_spend_enabled)
);
insert into private.zyra_unlock_release_gate values (true, false);
create table private.zyra_unlock_account_guards (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  revision bigint not null default 0
);
create table private.zyra_unlock_operations (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  unlocker_id uuid not null references public.profiles(id) on delete cascade,
  unlocked_id uuid not null references public.profiles(id) on delete cascade,
  tier text not null check (tier in ('paid_single', 'paid_plus_single')),
  -- Original identities survive privileged simulated entitlement deletion;
  -- deliberately not FK SET NULL, so the successful receipt cannot be lost.
  unlock_id uuid not null,
  debit_id uuid not null,
  created_at timestamptz not null default now(),
  unique (unlocker_id, unlocked_id, tier),
  check (unlocker_id <> unlocked_id)
);
alter table private.zyra_unlock_release_gate owner to postgres;
alter table private.zyra_unlock_account_guards owner to postgres;
alter table private.zyra_unlock_operations owner to postgres;
alter table private.zyra_unlock_release_gate enable row level security;
alter table private.zyra_unlock_release_gate force row level security;
alter table private.zyra_unlock_account_guards enable row level security;
alter table private.zyra_unlock_account_guards force row level security;
alter table private.zyra_unlock_operations enable row level security;
alter table private.zyra_unlock_operations force row level security;
revoke all on private.zyra_unlock_release_gate, private.zyra_unlock_account_guards,
  private.zyra_unlock_operations from public, anon, authenticated, service_role,
  supabase_storage_admin;

create function private.zyra_plus_spend_available() returns boolean
language sql stable security definer set search_path = '' as $function$
  select coalesce((select plus_spend_enabled
    from private.zyra_unlock_release_gate where singleton), false);
$function$;
create function private.zyra_lock_unlock_account(p_user uuid) returns void
language plpgsql security definer set search_path = '' as $function$
begin
  -- Subject erasure is a terminal FK cascade, not a balance mutation to repair.
  if not exists (select 1 from public.profiles where id = p_user) then
    return;
  end if;
  insert into private.zyra_unlock_account_guards (user_id, revision)
  values (p_user, 1) on conflict (user_id) do update
  set revision = private.zyra_unlock_account_guards.revision + 1;
end;
$function$;
create function private.zyra_guard_unlock_row() returns trigger
language plpgsql security definer set search_path = '' as $function$
begin
  perform private.zyra_lock_unlock_account(case when tg_op = 'DELETE'
    then old.unlocker_id else new.unlocker_id end);
  if tg_op = 'DELETE' then return old; end if;
  if tg_op = 'UPDATE' then
    if new.id is distinct from old.id or new.unlocker_id is distinct from old.unlocker_id
       or new.unlocked_id is distinct from old.unlocked_id
       or new.unlock_type is distinct from old.unlock_type then
      raise exception using errcode = '55000', message = 'unlock_identity_immutable';
    end if;
    return new; -- Existing unchanged held Plus/nonfinancial timestamps allowed.
  end if;
  if new.unlock_type in ('paid_plus_single', 'paid_plus_bundle')
     and not private.zyra_plus_spend_available() then
    return null; -- Hold a new grant without rolling back an enclosing Journey.
  end if;
  return new;
end;
$function$;
create function private.zyra_guard_unlock_credit() returns trigger
language plpgsql security definer set search_path = '' as $function$
declare
  v_balance bigint;
begin
  perform private.zyra_lock_unlock_account(case when tg_op = 'DELETE'
    then old.user_id else new.user_id end);
  if tg_op = 'DELETE' then return old; end if; -- Existing privileged reset/erasure.
  if tg_op = 'UPDATE' then
    if new.id is distinct from old.id or new.user_id is distinct from old.user_id
       or new.tier is distinct from old.tier or new.delta is distinct from old.delta
       or new.reason is distinct from old.reason
       or (new.related_unlock_id is distinct from old.related_unlock_id
           and new.related_unlock_id is not null) then
      raise exception using errcode = '55000', message = 'unlock_ledger_append_only';
    end if;
    return new; -- FK SET NULL/note/timestamp changes are not another debit.
  end if;
  if new.delta < 0 then
    if new.tier = 'paid_plus_single' and not private.zyra_plus_spend_available() then
      raise exception using errcode = '55000', message = 'plus_unavailable';
    end if;
    if new.reason = 'spend' then
      if new.delta <> -1 or new.related_unlock_id is null or not exists (
        select 1 from public.profile_unlocks u where u.id = new.related_unlock_id
          and u.unlocker_id = new.user_id
          and ((new.tier = 'paid_single' and u.unlock_type in ('paid_single', 'paid_bundle', 'automatic_match'))
            or (new.tier = 'paid_plus_single' and u.unlock_type in ('paid_plus_single', 'paid_plus_bundle')))
      ) then
        raise exception using errcode = '55000', message = 'invalid_unlock_debit_binding';
      end if;
      if exists (select 1 from public.unlock_credits c
        where c.user_id = new.user_id and c.related_unlock_id = new.related_unlock_id
          and c.reason = 'spend') then
        raise exception using errcode = '55000', message = 'unlock_already_debited';
      end if;
    end if;
    select coalesce(sum(c.delta), 0) into v_balance from public.unlock_credits c
    where c.user_id = new.user_id and c.tier = new.tier;
    if v_balance + new.delta < 0 then
      raise exception using errcode = '55000', message = 'insufficient_credits';
    end if;
  end if;
  return new;
end;
$function$;
alter function private.zyra_plus_spend_available() owner to postgres;
alter function private.zyra_lock_unlock_account(uuid) owner to postgres;
alter function private.zyra_guard_unlock_row() owner to postgres;
alter function private.zyra_guard_unlock_credit() owner to postgres;
revoke all on function private.zyra_plus_spend_available(),
  private.zyra_lock_unlock_account(uuid), private.zyra_guard_unlock_row(),
  private.zyra_guard_unlock_credit() from public, anon, authenticated, service_role,
  supabase_storage_admin;
create trigger zyra_unlock_row_guard before insert or update or delete
on public.profile_unlocks for each row execute function private.zyra_guard_unlock_row();
create trigger zyra_unlock_credit_guard before insert or update or delete
on public.unlock_credits for each row execute function private.zyra_guard_unlock_credit();

create or replace function public.zyra_unlock_profile(p_target uuid, p_tier text)
returns jsonb language plpgsql security definer set search_path = '' as $function$
declare
  v_me uuid := (select auth.uid());
  v_balance bigint;
  v_unlock uuid;
  v_debit uuid;
  v_operation uuid;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if p_tier is null or p_tier not in ('paid_single', 'paid_plus_single') then
    raise exception 'unknown_tier' using hint = 'paid_single or paid_plus_single';
  end if;
  if p_target = v_me then raise exception 'cannot_unlock_self'; end if;
  if not exists (select 1 from public.profiles where id = v_me and role = 'seeker') then
    raise exception using errcode = '42501', message = 'seeker_required';
  end if;
  if not exists (select 1 from public.profiles where id = p_target and role = 'seeker')
     or not coalesce(public.zyra_can_view_profile(p_target), false) then
    raise exception 'not_visible';
  end if;
  perform private.zyra_lock_unlock_account(v_me);
  -- Recheck current visibility after a wait; do not replay a sensitive response.
  if not coalesce(public.zyra_can_view_profile(p_target), false) then
    raise exception 'not_visible';
  end if;
  select o.id into v_operation from private.zyra_unlock_operations o
  where o.unlocker_id = v_me and o.unlocked_id = p_target and o.tier = p_tier;
  if exists (select 1 from public.profile_unlocks u
    where u.unlocker_id = v_me and u.unlocked_id = p_target
      and ((p_tier = 'paid_single' and u.unlock_type in
        ('paid_single', 'paid_bundle', 'automatic_match', 'paid_plus_single', 'paid_plus_bundle'))
        or (p_tier = 'paid_plus_single' and u.unlock_type in ('paid_plus_single', 'paid_plus_bundle')))
  ) then
    return jsonb_build_object('status', 'already_unlocked', 'charged', false,
                             'operation_id', v_operation);
  end if;
  if v_operation is not null then
    return jsonb_build_object('status', 'recovery_required', 'charged', false,
                             'operation_id', v_operation);
  end if;
  if p_tier = 'paid_plus_single' and not private.zyra_plus_spend_available() then
    return jsonb_build_object('status', 'plus_unavailable', 'charged', false);
  end if;
  select coalesce(sum(c.delta), 0) into v_balance from public.unlock_credits c
  where c.user_id = v_me and c.tier = p_tier;
  if v_balance < 1 then
    return jsonb_build_object('status', 'insufficient_credits', 'charged', false, 'balance', v_balance);
  end if;
  insert into public.profile_unlocks (unlocker_id, unlocked_id, unlock_type)
  values (v_me, p_target, p_tier) returning id into v_unlock;
  if v_unlock is null then
    raise exception using errcode = '55000', message = 'unlock_not_created';
  end if;
  insert into public.unlock_credits (user_id, tier, delta, reason, related_unlock_id)
  values (v_me, p_tier, -1, 'spend', v_unlock) returning id into v_debit;
  insert into private.zyra_unlock_operations (unlocker_id, unlocked_id, tier, unlock_id, debit_id)
  values (v_me, p_target, p_tier, v_unlock, v_debit) returning id into v_operation;
  return jsonb_build_object('status', 'unlocked', 'charged', true,
                           'balance', v_balance - 1, 'operation_id', v_operation);
end;
$function$;
revoke all on function public.zyra_unlock_profile(uuid,text) from public, anon;
grant execute on function public.zyra_unlock_profile(uuid,text) to authenticated, service_role;

-- Preserve the exact old dev guard; do not turn an email into new authority.
-- F36 removal/replacement remains separate. Held new Plus reports false rather
-- than pretending the suppressed INSERT succeeded or aborting its caller.
create or replace function public.zyra_dev_set_plus_unlock(p_other_id uuid, p_has boolean)
returns boolean language plpgsql security definer set search_path = '' as $function$
declare
  caller uuid := (select auth.uid());
  v_email text;
begin
  if caller is null then raise exception 'not_signed_in'; end if;
  select email into v_email from auth.users where id = caller;
  if v_email is null or v_email not like '%@zyra.test' then
    raise exception 'dev_only' using hint = 'Plus simulation is limited to seeded @zyra.test accounts.';
  end if;
  if p_other_id = caller then raise exception 'not_a_party'; end if;
  perform private.zyra_lock_unlock_account(caller);
  if p_has then
    if exists (select 1 from public.profile_unlocks where unlocker_id = caller
      and unlocked_id = p_other_id and unlock_type in ('paid_plus_single', 'paid_plus_bundle')) then
      return true;
    end if;
    if not private.zyra_plus_spend_available() then return false; end if;
    insert into public.profile_unlocks (unlocker_id, unlocked_id, unlock_type)
    values (caller, p_other_id, 'paid_plus_single') on conflict do nothing;
    return found;
  else
    delete from public.profile_unlocks where unlocker_id = caller
      and unlocked_id = p_other_id and unlock_type = 'paid_plus_single';
    return p_has;
  end if;
end;
$function$;
revoke all on function public.zyra_dev_set_plus_unlock(uuid,boolean) from public, anon;
grant execute on function public.zyra_dev_set_plus_unlock(uuid,boolean) to authenticated, service_role;
commit;
