-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317 / OA-ZYRA-319.
-- Local proof only; production requires a separate exact-payload Founder GO.

begin;

alter table public.family_messages
  add column if not exists sender_deleted_at timestamptz;

alter table public.family_message_reports
  add column if not exists status text not null default 'pending'
    check (status in ('pending', 'reviewing', 'actioned', 'dismissed')),
  add column if not exists reviewed_at timestamptz;

-- Preserve honest authorship labels without restoring access to a removed
-- Guardian's old membership epoch. Deleted profiles are intentionally
-- anonymous; a linked Guardian who has left the Circle is shown by role,
-- not as though they were still a current participant.
create or replace function public.zyra_family_messages(
  p_thread uuid,
  p_before timestamptz default null,
  p_limit integer default 50
) returns table (
  message_id uuid,
  sender_id uuid,
  sender_first_name text,
  kind text,
  body text,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select
    message.id,
    message.sender_id,
    case
      when message.sender_id is null then 'Deleted member'
      when exists (
        select 1
        from public.family_message_memberships former
        where former.thread_id = message.thread_id
          and former.user_id = message.sender_id
          and former.member_role = 'guardian'
          and former.left_at is not null
      ) and not exists (
        select 1
        from public.family_message_memberships current_member
        where current_member.thread_id = message.thread_id
          and current_member.user_id = message.sender_id
          and current_member.left_at is null
      ) then 'Former Guardian'
      else sender.first_name
    end,
    message.kind,
    message.body,
    message.created_at
  from public.family_messages message
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = (select auth.uid())
   and membership.left_at is null
  left join public.profiles sender on sender.id = message.sender_id
  where message.thread_id = p_thread
    and message.created_at >= membership.readable_from
    and (p_before is null or message.created_at < p_before)
  order by message.created_at desc, message.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;
revoke execute on function public.zyra_family_messages(uuid,timestamptz,integer)
  from public, anon;
grant execute on function public.zyra_family_messages(uuid,timestamptz,integer)
  to authenticated;

create table if not exists public.family_message_report_evidence (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null unique,
  thread_id uuid not null,
  message_id uuid not null,
  reported_sender_id uuid,
  reason text not null,
  reported_body text not null,
  immediate_context jsonb not null default '[]'::jsonb,
  reported_at timestamptz not null,
  closed_at timestamptz,
  retain_until timestamptz,
  legal_hold boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.family_message_report_evidence enable row level security;
revoke all on public.family_message_report_evidence
  from public, anon, authenticated;
grant select, insert, update, delete on public.family_message_report_evidence
  to service_role;

create or replace function public.zyra_capture_family_message_report_evidence()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.family_message_report_evidence (
    report_id, thread_id, message_id, reported_sender_id, reason,
    reported_body, immediate_context, reported_at
  )
  select
    new.id,
    new.thread_id,
    new.message_id,
    message.sender_id,
    new.reason,
    message.body,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'message_id', context_message.id,
        'sender_id', context_message.sender_id,
        'body', context_message.body,
        'created_at', context_message.created_at
      ) order by context_message.created_at, context_message.id)
      from (
        select candidate.*
        from public.family_messages candidate
        where candidate.thread_id = new.thread_id
          and candidate.created_at between
            message.created_at - interval '10 minutes'
            and message.created_at + interval '10 minutes'
        order by abs(extract(epoch from (candidate.created_at - message.created_at))),
                 candidate.id
        limit 11
      ) context_message
    ), '[]'::jsonb),
    new.created_at
  from public.family_messages message
  where message.id = new.message_id;
  return new;
end;
$$;

revoke all on function public.zyra_capture_family_message_report_evidence()
  from public, anon, authenticated;

drop trigger if exists family_message_report_capture_evidence
  on public.family_message_reports;
create trigger family_message_report_capture_evidence
after insert on public.family_message_reports
for each row execute function public.zyra_capture_family_message_report_evidence();

create or replace function public.zyra_mark_family_message_sender_deleted()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.family_messages
  set sender_deleted_at = coalesce(sender_deleted_at, now())
  where sender_id = old.id;
  return old;
end;
$$;
revoke all on function public.zyra_mark_family_message_sender_deleted()
  from public, anon, authenticated;

drop trigger if exists profiles_mark_family_message_sender_deleted
  on public.profiles;
create trigger profiles_mark_family_message_sender_deleted
before delete on public.profiles
for each row execute function public.zyra_mark_family_message_sender_deleted();

create or replace function public.zyra_close_family_message_report(
  p_report_id uuid,
  p_legal_hold boolean default false
)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'moderation_authority_required';
  end if;
  update public.family_message_report_evidence evidence
  set closed_at = now(),
      legal_hold = p_legal_hold,
      retain_until = case when p_legal_hold then null
        else now() + interval '24 months' end
  where evidence.report_id = p_report_id;
  if not found then raise exception 'report_evidence_not_found'; end if;
  update public.family_message_reports report
  set status = 'actioned', reviewed_at = now()
  where report.id = p_report_id;
end;
$$;
revoke all on function public.zyra_close_family_message_report(uuid,boolean)
  from public, anon, authenticated;
grant execute on function public.zyra_close_family_message_report(uuid,boolean)
  to service_role;

create or replace function public.zyra_purge_expired_family_message_data()
returns table(deleted_messages bigint, deleted_evidence bigint)
language plpgsql security definer set search_path = ''
as $$
declare
  v_messages bigint;
  v_evidence bigint;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service_role_required';
  end if;
  delete from public.family_messages message
  where message.sender_id is null
    and message.sender_deleted_at <= now() - interval '12 months'
    and not exists (
      select 1 from public.family_message_report_evidence evidence
      where evidence.message_id = message.id
        and (evidence.legal_hold or evidence.retain_until > now())
    );
  get diagnostics v_messages = row_count;

  delete from public.family_message_report_evidence evidence
  where not evidence.legal_hold
    and evidence.closed_at is not null
    and evidence.retain_until <= now();
  get diagnostics v_evidence = row_count;

  return query select v_messages, v_evidence;
end;
$$;
revoke all on function public.zyra_purge_expired_family_message_data()
  from public, anon, authenticated;
grant execute on function public.zyra_purge_expired_family_message_data()
  to service_role;

comment on table public.family_message_report_evidence is
  'Protected moderation evidence: reported message plus bounded immediate '
  'context. Service-role only. Retained 24 months after case closure unless '
  'an active legal/safety hold requires longer.';

commit;
