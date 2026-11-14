-- ZYRA line 110 clean production baseline.
-- Apply as postgres to a fresh Supabase PostgreSQL 17 project only after acceptance.
-- Application schema, grants, Storage policies and fixed reference data.
-- Derived from 245 source migrations (including line 109), two historical replay bridges,
-- and the corrected line 107 staging SQL.
-- Platform objects are preinstalled.

BEGIN;
SET LOCAL search_path = '';
SET LOCAL check_function_bodies = false;
SET LOCAL row_security = off;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE SCHEMA private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA private TO service_role;


--
-- Name: zyra_alert_family_chat_arrival(uuid, uuid, uuid, timestamp with time zone); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_alert_family_chat_arrival(p_thread uuid, p_chat uuid, p_sender uuid, p_arrived_at timestamp with time zone) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  -- A relink begins a new membership epoch. Retire stale unread rows so
  -- the first eligible arrival in the new epoch gets its own event ID.
  update public.notifications n set read_at = p_arrived_at
  from public.family_message_memberships member
  where member.thread_id = p_thread and member.left_at is null
    and n.user_id = member.user_id and n.related_chat_id = p_chat
    and n.type = 'circle_message' and n.read_at is null
    and n.created_at < member.readable_from;

  insert into public.notifications(user_id, type, title, body, related_chat_id, created_at)
  select member.user_id, 'circle_message', 'Guardian Circle',
    'New message in your Guardian Circle', p_chat, p_arrived_at
  from public.family_message_memberships member
  cross join lateral private.zyra_family_chat_admission(p_chat, member.user_id) admitted
  left join public.family_message_chat_state local
    on local.chat_id = p_chat and local.user_id = member.user_id
  left join public.family_message_participant_state circle
    on circle.thread_id = p_thread and circle.user_id = member.user_id
  left join lateral (
    select prefs.enabled from public.notification_preferences prefs
    where prefs.user_id = member.user_id and prefs.category = 'circle'
    order by prefs.seq desc limit 1
  ) preference on true
  where member.thread_id = p_thread and member.left_at is null and member.user_id <> p_sender
    and p_arrived_at >= admitted.readable_from
    and local.muted_at is null and circle.muted_at is null and coalesce(preference.enabled, true)
  on conflict (user_id, related_chat_id) where type = 'circle_message' and read_at is null
  do update set created_at = greatest(notifications.created_at, excluded.created_at);
end;
$$;


--
-- Name: zyra_attempt_has_open_report(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_attempt_has_open_report(p_attempt_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  select exists (
    select 1 from private.report_protected_attempts p
    join public.profile_reports r on r.id = p.report_id
    where p.attempt_id = p_attempt_id and r.status in ('pending', 'reviewing')
  ) or exists (
    select 1 from private.zyra_family_chat_report_attempts p
    join public.family_message_reports r on r.id = p.report_id
    left join public.family_message_report_evidence e on e.report_id = r.id
    where p.attempt_id = p_attempt_id
      and (r.status in ('pending', 'reviewing') or e.legal_hold)
  );
$$;


--
-- Name: zyra_clear_deleted_guardian_trial(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_clear_deleted_guardian_trial() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  if new.claimed_by is null then
    new.started_at := null;
    new.ends_at := null;
  end if;
  return new;
end;
$$;


--
-- Name: zyra_compatibility_answer(jsonb, text, jsonb, boolean); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_compatibility_answer(p_value jsonb, p_question text, p_options jsonb, p_multi boolean) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $$
declare
  v_selected jsonb;
  v_choice jsonb;
begin
  if p_multi then
    v_selected := private.zyra_compatibility_input(p_value, 'array');
  else
    v_selected := jsonb_build_array(private.zyra_compatibility_input(p_value, 'string'));
  end if;
  if jsonb_array_length(v_selected) = 0 then
    raise exception using errcode = 'P8910', message = 'compatibility_selection_missing';
  end if;
  for v_choice in select value from jsonb_array_elements(v_selected) loop
    perform private.zyra_compatibility_input(v_choice, 'string');
    if not (p_options ? (v_choice #>> '{}')) then
      raise exception using errcode = 'P8911', message = 'compatibility_answer_outside_bank';
    end if;
  end loop;
  if jsonb_array_length(v_selected) <> (select count(distinct value) from jsonb_array_elements(v_selected))
     or (p_question in ('ch3_q37','ch3_q97') and v_selected ? 'None' and jsonb_array_length(v_selected) > 1) then
    raise exception using errcode = 'P8911', message = 'compatibility_selection_invalid';
  end if;
  return v_selected;
end;
$$;


--
-- Name: zyra_compatibility_input(jsonb, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_compatibility_input(p_value jsonb, p_type text) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $$
begin
  if p_value is null or p_value = 'null'::jsonb then
    raise exception using errcode = 'P8910', message = 'compatibility_input_missing';
  end if;
  if jsonb_typeof(p_value) is distinct from p_type then
    raise exception using errcode = 'P8911', message = 'compatibility_input_invalid';
  end if;
  return p_value;
end;
$$;


--
-- Name: zyra_compatibility_light(jsonb, uuid, text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_compatibility_light(p_value jsonb, p_viewer uuid, p_question text, p_option text) RETURNS numeric
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
declare
  v_light text := private.zyra_compatibility_input(p_value, 'string') #>> '{}';
begin
  case v_light
    when 'green' then return 1;
    when 'red' then return 0;
    when 'amber' then
      if exists (
        select 1 from public.preference_light_confirmations c
        where c.user_id = p_viewer and c.capture_version = 'v1' and c.light = v_light
          and ((c.question_id = p_question and c.option_value = p_option)
            or (p_question = 'sect' and c.question_id = 'ch2.sect.matrix'
              and c.option_value = p_option)
            or (p_option = 'flexibility' and c.option_value = '*'
              and c.question_id = 'ch2.' || p_question || '.flexibility'))
      ) then return 0.5; end if;
    when 'yellow' then null;
    else
      raise exception using errcode = 'P8911', message = 'compatibility_light_invalid';
  end case;
  raise exception using errcode = 'P8912', message = 'compatibility_light_needs_reconfirmation';
end;
$$;


--
-- Name: zyra_compatibility_sect_key(text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_compatibility_sect_key(p_subject_sect text, p_third_key text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
  select case
    when p_subject_sect is null or p_subject_sect in ('sunni', 'shia') then p_subject_sect
    else p_third_key
  end;
$$;


--
-- Name: zyra_create_notification(uuid, text, text, text, uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_create_notification(p_user_id uuid, p_type text, p_title text, p_body text, p_related_match_id uuid, p_actor_id uuid DEFAULT NULL::uuid, p_invite_id uuid DEFAULT NULL::uuid, p_link_id uuid DEFAULT NULL::uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_category text := public.zyra_notification_category(p_type);
  v_enabled boolean;
  v_notification_id uuid;
  v_has_departed boolean;
begin
  if v_category is not null then
    select p.enabled into v_enabled
    from public.notification_preferences p
    where p.user_id = p_user_id and p.category = v_category
    order by p.seq desc limit 1;

    if not coalesce(v_enabled, v_category not in ('marketing_emails', 'product_updates')) then
      return;
    end if;
  end if;

  -- A notification written after account erasure must not recreate a preview
  -- for that departed participant. Taking the match lock serializes the check
  -- with the erasure transaction.
  if p_related_match_id is not null then
    select (m.seeker_a_id is null or m.seeker_b_id is null) into v_has_departed
    from public.matches m where m.id = p_related_match_id for share;
    if not found or v_has_departed then return; end if;
  end if;

  insert into public.notifications(user_id, type, title, body, related_match_id)
  values (p_user_id, p_type, p_title, p_body, p_related_match_id)
  returning id into v_notification_id;

  if p_actor_id is not null or p_invite_id is not null or p_link_id is not null then
    insert into private.zyra_guardian_notification_sources(notification_id, actor_id, invite_id, link_id)
    values (v_notification_id, p_actor_id, p_invite_id, p_link_id);
  end if;
end;
$$;


--
-- Name: zyra_current_sect_third_key(text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_current_sect_third_key(p_sect text, p_words text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $_$
  select case
    when p_sect is null or p_sect in ('sunni', 'shia') then 'other'
    when p_sect !~ '^[a-z0-9]+(-[a-z0-9]+)*$' then null
    when p_words is null or p_sect = code then p_sect
    when p_sect = 'other' then case when code not in ('sunni', 'shia') then code end
    when length(p_words) + (
      select count(*) from regexp_split_to_table(p_words, '') letter
      where octet_length(letter) = 4
    ) = 60 and (
      lower(p_words) collate "C" !~ '[a-z0-9]' or starts_with(p_sect, code)
    ) then p_sect
    else null
  end
  from (select public.zyra_sect_code(p_words) as code) words;
$_$;


--
-- Name: zyra_enforce_personal_request_owner_acceptance(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_enforce_personal_request_owner_acceptance() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if new.source = 'personal_code'
     and new.status = 'accepted'
     and old.status is distinct from 'accepted'
     and new.accepted_by is distinct from new.inviter_id then
    raise exception 'personal_request_requires_owner_acceptance';
  end if;
  return new;
end;
$$;


--
-- Name: zyra_enforce_photo_row_owner(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_enforce_photo_row_owner() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if new.user_id is distinct from (select auth.uid())
     or not private.zyra_photo_reference_owned(new.user_id, new.storage_path) then
    raise exception using errcode = '42501', message = 'photo_reference_not_owned';
  end if;
  if new.removed_at is null and exists (
    select 1 from public.photo_object_deletions d where d.attempts > 0
      and ((d.bucket = 'profile-photos' and d.path = new.storage_path)
        or (d.bucket = 'profile-photo-sources' and d.path = new.source_path))
  ) then
    raise exception using errcode = '22023', message = 'photo_path_retired';
  end if;
  if tg_op = 'UPDATE' and new.revision = old.revision then
    new.revision := old.revision + 1;
  end if;
  return new;
end;
$$;


--
-- Name: zyra_enforce_photo_upload_fence(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_enforce_photo_upload_fence() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
declare
  v_folder text;
  v_uuid_pattern constant text := '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
begin
  if tg_op <> 'INSERT' and old.bucket_id in ('profile-photos', 'profile-photo-sources') then
    v_folder := pg_catalog.split_part(old.name, '/', 1);
    if v_folder ~ v_uuid_pattern then
      perform private.zyra_lock_photo_folder(v_folder);
      if private.zyra_photo_object_referenced(old.bucket_id, old.name) then
        raise exception using errcode = '42501', message = 'photo_object_referenced';
      end if;
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  if new.bucket_id is null or new.bucket_id not in ('profile-photos', 'profile-photo-sources') then
    return new;
  end if;

  v_folder := pg_catalog.split_part(new.name, '/', 1);
  if v_folder !~ v_uuid_pattern then return new; end if;
  perform private.zyra_lock_photo_folder(v_folder);
  if (new.owner_id = v_folder and not exists (select 1 from auth.users u where u.id = v_folder::uuid))
     or exists (
       select 1 from public.photo_object_deletions d
        where d.bucket = new.bucket_id and d.path = new.name and d.attempts > 0
     ) then
    raise exception using errcode = '42501', message = 'photo_path_retired';
  end if;
  return new;
end;
$_$;


--
-- Name: zyra_erase_departing_notification_previews(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_erase_departing_notification_previews(p_user_id uuid) RETURNS void
    LANGUAGE sql
    SET search_path TO ''
    AS $_$
  with departing_references(id) as (
    select p_user_id
    union all
    select m.id from public.matches m where p_user_id in (m.seeker_a_id, m.seeker_b_id)
    union all
    select r.id from public.journey_requests r where p_user_id in (r.requested_by, r.requested_to)
    union all
    select i.id from public.wali_invites i
    where p_user_id in (i.inviter_id, i.recipient_id, i.seen_by, i.accepted_by, i.declined_by)
    union all
    select l.id from public.wali_links l where p_user_id in (l.seeker_id, l.wali_id)
  ), affected as (
    select source.notification_id
    from private.zyra_guardian_notification_sources source
    left join public.wali_invites invite on invite.id = source.invite_id
    left join public.wali_links link on link.id = source.link_id
    where p_user_id in (source.actor_id, invite.inviter_id, invite.recipient_id, invite.seen_by,
      invite.accepted_by, invite.declined_by, link.seeker_id, link.wali_id)
    union
    select n.id from public.notifications n
    where n.payload <> '{}'::jsonb and exists (
      select 1
      from jsonb_path_query(n.payload, '$.** ? (@.type() == "string")') field(value)
      join departing_references ref on lower(field.value #>> '{}') = ref.id::text
    )
  )
  update public.notifications n
  set title = 'This profile is no longer active', body = null, payload = '{}'::jsonb
  from affected where n.id = affected.notification_id;

  -- A legacy Guardian preview can outlive its invite and contain a name
  -- without an ID. Erase the preview rather than matching on a name alone.
  update public.notifications n
  set title = '', body = null, payload = '{}'::jsonb
  where n.related_match_id is null
    and n.type in ('wali_request','wali_invite_received','wali_invite_declined',
      'wali_invite_expiring','wali_invite_expired','wali_invite_revoked')
    and (n.title <> '' or n.body is not null)
    and not exists (
      select 1 from private.zyra_guardian_notification_sources source
      where source.notification_id = n.id
        and (source.actor_id is not null or source.invite_id is not null or source.link_id is not null)
    );
$_$;


--
-- Name: zyra_family_chat_admission(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_family_chat_admission(p_chat uuid) RETURNS TABLE(thread_id uuid, kind text, state text, other_first_name text, ended_at timestamp with time zone, readable_from timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select * from private.zyra_family_chat_admission(p_chat, (select auth.uid()));
$$;


--
-- Name: zyra_family_chat_admission(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_family_chat_admission(p_chat uuid, p_user uuid) RETURNS TABLE(thread_id uuid, kind text, state text, other_first_name text, ended_at timestamp with time zone, readable_from timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select c.thread_id, c.kind,
    case when a.status = 'ended' then 'past' else 'current' end,
    case when p_user = (select auth.uid())
      and a.end_reason is distinct from 'safety_concern'
      and (a.status <> 'ended' or member.member_role = 'guardian'
        or public.zyra_can_view_profile(other.id)) then other.first_name end,
    a.ended_at, member.readable_from
  from public.family_message_chats c
  join public.family_message_threads t on t.id = c.thread_id
  join public.family_message_memberships member
    on member.thread_id = t.id and member.user_id = p_user and member.left_at is null
  left join public.wali_links link
    on link.seeker_id = t.seeker_id and link.wali_id = member.user_id and link.status = 'active'
  left join public.journey_attempts a on a.id = c.attempt_id
  left join public.matches m on m.id = a.match_id
  left join public.profiles other on other.id =
    case when t.seeker_id = m.seeker_a_id then m.seeker_b_id else m.seeker_a_id end
  left join private.zyra_ended_journey_visibility ended on ended.attempt_id = a.id
  where c.id = p_chat
    and (c.kind = 'main' or (
      a.started_at is not null
      and t.seeker_id in (m.seeker_a_id, m.seeker_b_id)
      and other.id is not null
      and not exists (
        select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
      )
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = t.seeker_id and b.blocked_id = other.id)
           or (b.blocker_id = other.id and b.blocked_id = t.seeker_id)
           or (b.blocker_id = member.user_id and b.blocked_id in (t.seeker_id, other.id))
           or (b.blocked_id = member.user_id and b.blocker_id in (t.seeker_id, other.id))
      )
      and (
        (a.status = 'active' and (
          member.user_id = t.seeker_id or link.is_main is true or exists (
            select 1 from public.journey_guardian_assignments assignment
            where assignment.attempt_id = a.id and assignment.seeker_id = t.seeker_id
              and assignment.wali_link_id = link.id and assignment.revoked_at is null
              and assignment.granted_at >= link.active_since
          )
        )) or (
          a.status = 'ended'
          and ((t.seeker_id = ended.seeker_a_id and ended.seeker_a_visible)
            or (t.seeker_id = ended.seeker_b_id and ended.seeker_b_visible))
          and (a.end_reason is distinct from 'safety_concern' or a.ended_by = member.user_id)
          and (member.user_id = t.seeker_id or exists (
            select 1 from public.guardian_journey_history_consents consent
            where consent.wali_link_id = link.id
              and consent.guardian_link_authority_id = link.guardian_link_authority_id
          ))
        )
      )
    ));
$$;


--
-- Name: zyra_family_chat_create_for_attempt(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_family_chat_create_for_attempt() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare v_seeker uuid;
begin
  if new.status <> 'active' or new.started_at is null then return new; end if;
  if tg_op = 'UPDATE' and old.status = 'active' and old.started_at is not null then
    return new;
  end if;
  -- Take the same lock as Circle creation. UUID order is stable for both sides.
  for v_seeker in
    select p.id from public.matches m
    cross join lateral (values (m.seeker_a_id), (m.seeker_b_id)) p(id)
    where m.id = new.match_id
      and m.seeker_a_id is not null and m.seeker_b_id is not null
      and not exists (
        select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
      )
    order by p.id
  loop
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_seeker::text, 107));
    insert into public.family_message_chats(thread_id, kind, attempt_id, created_at)
    select t.id, 'journey', new.id, new.started_at
    from public.family_message_threads t where t.seeker_id = v_seeker
    on conflict (thread_id, attempt_id) do nothing;
  end loop;
  return new;
end;
$$;


--
-- Name: zyra_family_chat_create_for_thread(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_family_chat_create_for_thread() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(new.seeker_id::text, 107));
  insert into public.family_message_chats(thread_id, kind, created_at)
  values (new.id, 'main', new.created_at);

  insert into public.family_message_chats(thread_id, kind, attempt_id, created_at)
  select new.id, 'journey', a.id, a.started_at
  from public.matches m
  join public.journey_attempts a on a.match_id = m.id
  where new.seeker_id in (m.seeker_a_id, m.seeker_b_id)
    and m.seeker_a_id is not null and m.seeker_b_id is not null
    and a.started_at is not null and a.status in ('active', 'ended')
    and not exists (
      select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
    )
  on conflict (thread_id, attempt_id) do nothing;
  return new;
end;
$$;


--
-- Name: zyra_family_chat_message_visible(uuid, timestamp with time zone); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_family_chat_message_visible(p_chat uuid, p_created_at timestamp with time zone) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select exists (
    select 1 from private.zyra_family_chat_admission(p_chat) admitted
    where p_created_at >= admitted.readable_from
  );
$$;


--
-- Name: zyra_family_message_default_main(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_family_message_default_main() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if new.chat_id is null then
    select c.id into new.chat_id from public.family_message_chats c
    where c.thread_id = new.thread_id and c.kind = 'main';
  end if;
  return new;
end;
$$;


--
-- Name: zyra_generate_personal_code(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_generate_personal_code() RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_hex text;
  v_code text;
begin
  loop
    v_hex := upper(encode(extensions.gen_random_bytes(10), 'hex'));
    v_code := 'ZYRA-' || substr(v_hex, 1, 4) || '-' ||
              substr(v_hex, 5, 4) || '-' || substr(v_hex, 9, 4) || '-' ||
              substr(v_hex, 13, 4) || '-' || substr(v_hex, 17, 4);
    exit when not exists (
      select 1 from private.zyra_personal_codes c where c.code = v_code
    ) and not exists (
      select 1 from private.zyra_retired_personal_code_hashes r
      where r.code_sha256 = extensions.digest(v_code, 'sha256')
    );
  end loop;
  return v_code;
end;
$$;


--
-- Name: zyra_guard_legacy_photo_row_write(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_guard_legacy_photo_row_write() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  if current_user = 'authenticated' and old.source_path is not null then
    if tg_op = 'DELETE' or new.storage_path is distinct from old.storage_path then
      raise exception using errcode = '42501', message = 'photo_requires_revision_write';
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;


--
-- Name: zyra_guard_unlock_credit(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_guard_unlock_credit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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
$$;


--
-- Name: zyra_guard_unlock_row(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_guard_unlock_row() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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
$$;


--
-- Name: zyra_guardian_invite_capacity(uuid, uuid, timestamp with time zone); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_guardian_invite_capacity(p_seeker uuid, p_exclude_guardian uuid, p_at timestamp with time zone) RETURNS TABLE(active_count integer, basic_place_free boolean)
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  select count(*)::integer,
         coalesce(bool_and(public.zyra_has_paid_role(wl.wali_id, 'guardian', p_at)), true)
  from public.wali_links wl
  where wl.seeker_id = p_seeker
    and wl.status = 'active'
    and wl.wali_id is distinct from p_exclude_guardian;
$$;


--
-- Name: zyra_hidden_ch2_light_applicable(text, jsonb); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_hidden_ch2_light_applicable(p_group text, p_preference jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $_$
  select case when p_group in ('country_of_birth', 'nationality', 'ethnicity', 'languages')
    and p_preference -> 'skipped' = 'false'::jsonb
    and jsonb_typeof(p_preference -> 'preferred') = 'array'
  then (
    select count(*) = count(distinct item.value)
      and bool_and(jsonb_typeof(item.value) = 'string' and (item.value #>> '{}') ~
        case p_group when 'ethnicity' then '^[a-z][a-z_]*$'
          when 'languages' then '^[a-z]{2}$' else '^[A-Z]{2}$' end)
      and bool_or(p_group <> 'languages' or item.value <> '"en"'::jsonb)
    from jsonb_array_elements(p_preference -> 'preferred') item(value)
  ) else false end;
$_$;


--
-- Name: zyra_identity_verification_allows_user(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_identity_verification_allows_user(p_user_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select coalesce((
    select attempt.result = 'verified'
    from private.identity_verification_attempts attempt
    where attempt.user_id = p_user_id
      and attempt.member_deleted_at is null
    order by (attempt.result = 'verified') desc, attempt.created_at desc
    limit 1
  ), false);
$$;


--
-- Name: zyra_inactivity_ended_attempts(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_inactivity_ended_attempts(p_user uuid) RETURNS TABLE(attempt_id uuid, match_id uuid)
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  select a.id, m.id
  from public.matches m
  join public.journey_attempts a on a.match_id = m.id and a.status = 'ended'
  left join private.zyra_ended_journey_removals r on r.attempt_id = a.id
  where (m.seeker_a_id = p_user and r.seeker_a_removed_at is null)
     or (m.seeker_b_id = p_user and r.seeker_b_removed_at is null);
$$;


--
-- Name: zyra_invalidate_preference_light_confirmations(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_invalidate_preference_light_confirmations() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_chapter integer := tg_argv[0]::integer;
  v_old jsonb := to_jsonb(old) -> tg_argv[1];
  v_new jsonb;
  v_confirm_call boolean := current_setting('zyra.confirm_preference_lights', true) = 'on';
begin
  if tg_op = 'UPDATE' and new.user_id is not distinct from old.user_id then
    v_new := to_jsonb(new) -> tg_argv[1];
  end if;
  if v_new is null then
    delete from public.preference_light_confirmations c
    where c.user_id = old.user_id
      and (v_chapter = 2) = (c.question_id like 'ch2.%' or c.question_id in (
        'sect', 'revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages'));
    return null;
  end if;

  if v_new is not distinct from v_old then return null; end if;

  delete from public.preference_light_confirmations c
  where c.user_id = old.user_id
    and (v_chapter = 2) = (c.question_id like 'ch2.%' or c.question_id in (
      'sect', 'revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages'))
    and (v_old #> private.zyra_preference_receipt_path(v_chapter, c.question_id, c.option_value))
      is distinct from (v_new #> private.zyra_preference_receipt_path(v_chapter, c.question_id, c.option_value))
    -- A caller can set a GUC. Keeping a changed receipt also requires a
    -- matching row written in this statement by the protected RPC.
    and not coalesce(v_confirm_call and c.confirmed_at = statement_timestamp()
      and to_jsonb(c.light) =
        (v_new #> private.zyra_preference_receipt_path(v_chapter, c.question_id, c.option_value)), false);
  return null;
end;
$$;


--
-- Name: zyra_keep_red_ch2_hard_requirements(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_keep_red_ch2_hard_requirements() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_current_keys text[] := array_remove(array['sunni', 'shia',
    private.zyra_current_sect_third_key(new.sect, new.sect_other)], null);
  v_sect jsonb := new.preferences -> 'sect';
  v_matrix jsonb := v_sect -> 'matrix';
  v_incoming_hard jsonb := v_sect -> 'hard_requirement';
  v_old_matrix jsonb;
  v_old_hard jsonb;
  v_retired_matrix jsonb := '{}'::jsonb;
  v_retired_hard jsonb := '[]'::jsonb;
  v_current_matrix jsonb;
  v_hard jsonb;
  v_keep_hard_order boolean;
begin
  if tg_op = 'UPDATE' then
    v_old_matrix := old.preferences #> '{sect,matrix}';
    v_old_hard := old.preferences #> '{sect,hard_requirement}';
    if jsonb_typeof(v_old_matrix) = 'object' then
      v_retired_matrix := v_old_matrix - v_current_keys;
    end if;
    if jsonb_typeof(v_old_hard) = 'array' then
      select coalesce(jsonb_agg(item.value order by item.ordinal), '[]'::jsonb)
      into v_retired_hard
      from jsonb_array_elements_text(v_old_hard) with ordinality as item(value, ordinal)
      where not (item.value = any(v_current_keys));
    end if;
  end if;

  -- Leave hard-list shape validation to its existing CHECK. Do not let a
  -- malformed replacement erase retired data that cannot be merged.
  if not public.zyra_ch2_sect_hard_shape_ok(new.preferences) then
    return new;
  end if;
  if ((v_retired_matrix <> '{}'::jsonb or v_retired_hard <> '[]'::jsonb)
      and (jsonb_typeof(new.preferences) is distinct from 'object'
        or coalesce(jsonb_typeof(v_sect), 'null') not in ('object', 'null')))
     or (v_retired_matrix <> '{}'::jsonb
         and coalesce(jsonb_typeof(v_matrix), 'null') not in ('object', 'null')) then
    raise exception using errcode = '22023', message = 'invalid_sect_preferences';
  end if;

  if jsonb_typeof(v_matrix) = 'object' or v_retired_matrix <> '{}'::jsonb then
    select coalesce(jsonb_object_agg(key, v_matrix -> key), '{}'::jsonb)
    into v_current_matrix
    from unnest(v_current_keys) current_key(key)
    where v_matrix ? key;
    v_sect := jsonb_set(coalesce(nullif(v_sect, 'null'::jsonb), '{}'::jsonb),
      '{matrix}', v_retired_matrix || v_current_matrix);
  end if;

  if v_incoming_hard is not null or v_retired_hard <> '[]'::jsonb then
    -- A confirmation preserves the submitted list's order while clearing
    -- current flags whose lights changed. A replacement restores old retired
    -- flags in their original order after the new current flags.
    v_keep_hard_order := v_incoming_hard is not distinct from v_old_hard;
    select coalesce(jsonb_agg(item.value order by item.ordinal), '[]'::jsonb)
    into v_hard
    from jsonb_array_elements_text(coalesce(v_incoming_hard, '[]'::jsonb))
      with ordinality as item(value, ordinal)
    where case when item.value = any(v_current_keys) then v_matrix ->> item.value = 'red'
               else v_keep_hard_order end;
    if not v_keep_hard_order then
      v_hard := v_hard || v_retired_hard;
    end if;
    v_sect := jsonb_set(coalesce(nullif(v_sect, 'null'::jsonb), '{}'::jsonb),
      '{hard_requirement}', v_hard);
  end if;
  if v_sect is distinct from new.preferences -> 'sect' then
    new.preferences := jsonb_set(new.preferences, '{sect}', v_sect);
  end if;
  return new;
end;
$$;


--
-- Name: zyra_keep_red_ch4_hard_requirements(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_keep_red_ch4_hard_requirements() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if new.ch4_hard_requirements is not null
     and public.zyra_ch4_hard_shape_ok(new.ch4_hard_requirements) then
    select coalesce(jsonb_object_agg(q.key,
      private.zyra_red_hard_requirements(new.ch4_preferences -> q.key, q.value)), '{}'::jsonb)
    into new.ch4_hard_requirements from jsonb_each(new.ch4_hard_requirements) q;
  end if;
  return new;
end;
$$;


--
-- Name: zyra_link_report_attempts(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_link_report_attempts() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_match_id uuid;
begin
  if new.status not in ('pending', 'reviewing') then return new; end if;
  -- INSERT has already locked the pair. Reopening a closed case must also
  -- serialize with its pair's archive purge.
  if tg_op = 'UPDATE' and old.status in ('pending', 'reviewing') then return new; end if;

  if new.attempt_id is not null then
    -- An exact case can reopen while a retired attempt is still held.
    select m.id into v_match_id from public.matches m
    join public.journey_attempts a on a.match_id = m.id
    where a.id = new.attempt_id
    for update of m;
  else
    select m.id into v_match_id from public.matches m
    where m.seeker_a_id = least(new.reporter_id, new.reported_id)
      and m.seeker_b_id = greatest(new.reporter_id, new.reported_id)
    for update;
  end if;

  insert into private.report_protected_attempts (report_id, attempt_id)
  select new.id, a.id from public.journey_attempts a
  where a.match_id = v_match_id and (new.attempt_id is null or a.id = new.attempt_id)
  on conflict do nothing;
  return new;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: journey_family_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_family_reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    from_stage text NOT NULL,
    to_stage text NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    deadline_at timestamp with time zone NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    attempt_id uuid,
    CONSTRAINT journey_family_reviews_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'continued'::text, 'paused'::text])))
);


--
-- Name: COLUMN journey_family_reviews.from_stage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_reviews.from_stage IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_family_reviews.to_stage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_reviews.to_stage IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_family_reviews.opened_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_reviews.opened_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_family_reviews.deadline_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_reviews.deadline_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_family_reviews.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_reviews.status IS 'OWNERSHIP: joint — the OUTCOME is disclosable. Individual Guardian decisions are not (see journey_family_review_responses).';


--
-- Name: COLUMN journey_family_reviews.resolved_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_reviews.resolved_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_family_reviews.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_reviews.attempt_id IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';


--
-- Name: zyra_lock_active_family_review(uuid, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_active_family_review(p_review_id uuid, p_expected_status text) RETURNS public.journey_family_reviews
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
declare
  v_review public.journey_family_reviews%rowtype;
  v_match public.matches%rowtype;
  v_caller uuid := (select auth.uid());
begin
  select r.* into v_review from public.journey_family_reviews r
  join public.matches m on m.id = r.match_id
  where r.id = p_review_id and m.seeker_a_id is not null and m.seeker_b_id is not null;
  if not found then raise exception 'review not found'; end if;
  if v_review.attempt_id is null then raise exception 'review_has_no_attempt'; end if;

  select * into v_match from public.matches
  where id = v_review.match_id and seeker_a_id is not null and seeker_b_id is not null
  for update;
  if not found then raise exception 'review not found'; end if;
  if v_caller is null or not exists (
    select 1 from public.wali_links link
    where link.wali_id = v_caller and link.status = 'active' and link.is_main
      and link.seeker_id in (v_match.seeker_a_id, v_match.seeker_b_id)
  ) then raise exception 'not an authorised Wali for this Journey'; end if;

  select * into v_review from public.journey_family_reviews
  where id = p_review_id and match_id = v_match.id for update;
  if not found then raise exception 'review not found'; end if;
  if v_match.status <> 'active' or not exists (
    select 1 from public.journey_attempts attempt
    where attempt.id = v_review.attempt_id and attempt.match_id = v_match.id
      and attempt.status = 'active'
  ) then raise exception 'journey_not_active'; end if;
  if v_review.status <> p_expected_status then
    if p_expected_status = 'paused' then raise exception 'review is not paused'; end if;
    raise exception 'review already resolved';
  end if;
  return v_review;
end;
$$;


--
-- Name: zyra_lock_family_chat(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_family_chat(p_chat_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform 1 from public.profiles where id = (select auth.uid()) for key share;
  if not found then raise exception 'family_chat_not_found'; end if;
  perform 1
  from public.family_message_threads t
  join private.zyra_family_chat_admission(p_chat_id) a on a.thread_id = t.id
  for update of t;
  if not found or not exists (select 1 from private.zyra_family_chat_admission(p_chat_id)) then
    raise exception 'family_chat_not_found';
  end if;
end;
$$;


--
-- Name: zyra_lock_family_chat_match(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_family_chat_match(p_thread uuid, p_chat uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform 1 from public.family_message_chats chat
  join public.journey_attempts attempt on attempt.id = chat.attempt_id
  join public.matches pair on pair.id = attempt.match_id
  cross join lateral private.zyra_family_chat_admission(chat.id) admitted
  where chat.id = p_chat and chat.thread_id = p_thread
  for update of pair;
  return found;
end;
$$;


--
-- Name: zyra_lock_family_chat_profiles(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_family_chat_profiles(p_thread uuid, p_reported uuid DEFAULT NULL::uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform profile.id from public.profiles profile
  where profile.id = p_reported or profile.id in (
    select member.user_id from public.family_message_memberships member
    where member.thread_id = p_thread and member.left_at is null
  )
  order by profile.id for key share of profile;
end;
$$;


--
-- Name: zyra_lock_family_message_thread(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_family_message_thread(p_thread uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare v_me uuid := auth.uid();
begin
  perform 1 from public.profiles where id = v_me for key share;
  if not found then raise exception 'circle_not_found'; end if;
  perform 1 from public.family_message_threads t where t.id = p_thread
    and exists (
      select 1 from public.family_message_memberships m
      where m.thread_id = t.id and m.user_id = v_me and m.left_at is null
    ) for update;
  if not found or not exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = p_thread and membership.user_id = v_me
      and membership.left_at is null
  ) then raise exception 'circle_not_found'; end if;
end;
$$;


--
-- Name: zyra_lock_member_photo_statement(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_member_photo_statement() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is not null then perform private.zyra_lock_photo_folder(v_me::text); end if;
  return null;
end;
$$;


--
-- Name: zyra_lock_message_match(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_message_match() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_has_departed boolean;
begin
  select m.seeker_a_id is null into v_has_departed
  from public.matches m
  join public.conversations c on c.match_id = m.id
  where c.id = new.conversation_id for share of m;
  if not found or v_has_departed then
    raise exception using errcode = '42501', message = 'journey_not_available';
  end if;
  return new;
end;
$$;


--
-- Name: zyra_lock_photo_folder(text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_photo_folder(p_folder text) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('zyra-photo:' || p_folder, 0));
  -- The advisory lock orders current writers. The shared row write also
  -- rejects a stale repeatable-read/serializable snapshot after lock handoff.
  insert into private.zyra_photo_folder_guard (folder) values (p_folder)
  on conflict (folder) do update set folder = excluded.folder;
end;
$$;


--
-- Name: zyra_lock_unlock_account(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_lock_unlock_account(p_user uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  -- Subject erasure is a terminal FK cascade, not a balance mutation to repair.
  if not exists (select 1 from public.profiles where id = p_user) then
    return;
  end if;
  insert into private.zyra_unlock_account_guards (user_id, revision)
  values (p_user, 1) on conflict (user_id) do update
  set revision = private.zyra_unlock_account_guards.revision + 1;
end;
$$;


--
-- Name: zyra_match_has_active_hold(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_match_has_active_hold(p_match_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  select exists (
    select 1 from public.protection_holds h
    where h.match_id = p_match_id and h.released_at is null
      and (h.expires_at is null or h.expires_at > pg_catalog.now())
  );
$$;


--
-- Name: zyra_match_has_protected_data(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_match_has_protected_data(p_match_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  select private.zyra_match_has_active_hold(p_match_id) or exists (
    select 1 from public.journey_attempts a
    where a.match_id = p_match_id and private.zyra_attempt_has_open_report(a.id)
  );
$$;


--
-- Name: zyra_my_attempt_participation_rows(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_my_attempt_participation_rows() RETURNS TABLE(attempt_id uuid, role text, match_id uuid, is_main boolean, attempt_status text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT row.attempt_id, row.role, row.match_id, row.is_main, row.attempt_status
  FROM public.zyra_attempt_participant_rows AS row
  WHERE row.user_id = (SELECT auth.uid())
$$;


--
-- Name: zyra_normalize_personal_code(text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_normalize_personal_code(p_code text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $$
declare
  v_compact text := upper(regexp_replace(coalesce(p_code, ''), '[^0-9A-Z]', '', 'g'));
begin
  if length(v_compact) <> 24 or left(v_compact, 4) <> 'ZYRA' then
    return null;
  end if;
  return 'ZYRA-' || substr(v_compact, 5, 4) || '-' ||
         substr(v_compact, 9, 4) || '-' || substr(v_compact, 13, 4) || '-' ||
         substr(v_compact, 17, 4) || '-' || substr(v_compact, 21, 4);
end;
$$;


--
-- Name: zyra_photo_caller_exists(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_photo_caller_exists() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select exists (select 1 from auth.users u where u.id = (select auth.uid()));
$$;


--
-- Name: zyra_photo_not_queued(text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_photo_not_queued(p_path text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select not exists (
    select 1 from public.photo_object_deletions d
    where d.bucket = 'profile-photos' and d.path = p_path
  );
$$;


--
-- Name: zyra_photo_object_referenced(text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_photo_object_referenced(p_bucket text, p_path text) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select case p_bucket
    when 'profile-photos' then exists (
      select 1 from public.profile_photos p where p.storage_path = p_path and p.removed_at is null
    )
    when 'profile-photo-sources' then exists (
      select 1 from public.profile_photos p where p.source_path = p_path and p.removed_at is null
    )
    else false end;
$$;


--
-- Name: zyra_photo_path_writable(text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_photo_path_writable(p_bucket text, p_path text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null or p_path is null or pg_catalog.split_part(p_path, '/', 1) <> v_me::text then
    return false;
  end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  return exists (select 1 from auth.users u where u.id = v_me)
    and not exists (
      select 1 from public.photo_object_deletions d
      where d.bucket = p_bucket and d.path = p_path and d.attempts > 0
    );
end;
$$;


--
-- Name: zyra_photo_reference_owned(uuid, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_photo_reference_owned(p_user_id uuid, p_path text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select (select auth.uid()) is not null
    and p_user_id is not null
    and pg_catalog.split_part(p_path, '/', 1) = p_user_id::text
    and pg_catalog.length(p_path) > 37
    and exists (
      select 1 from storage.objects o
      where o.bucket_id = 'profile-photos' and o.name = p_path
        and o.owner_id = p_user_id::text
    );
$$;


--
-- Name: zyra_plus_spend_available(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_plus_spend_available() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select coalesce((select plus_spend_enabled
    from private.zyra_unlock_release_gate where singleton), false);
$$;


--
-- Name: zyra_preference_control_visible(text, jsonb, integer, text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_preference_control_visible(p_gender text, p_answers jsonb, p_chapter integer, p_question text, p_option text) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  select case when p_chapter = 2 then
    p_question in ('ch2.sect.matrix', 'ch2.sect.outside_flexibility', 'ch2.revert.flexibility')
  else exists (
    select 1 from public.zyra_onboarding_questions q
    where q.qid = p_question and q.ch4_scored and q.options ? p_option
      and q.gender_visibility in ('all',
        case p_gender when 'male' then 'womenOnly' when 'female' then 'menOnly' end)
      and (q.show_if_qid is null or not coalesce(
        q.show_if_not_any_of ? (p_answers ->> q.show_if_qid), false))
  ) end;
$$;


--
-- Name: zyra_preference_light_controls(text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_preference_light_controls(p_gender text, p_sect text) RETURNS TABLE(question_id text, option_value text, chapter integer, path text[])
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  select q.qid, o.option_value, 4, array[q.qid, o.option_value]
  from public.zyra_onboarding_questions q
  cross join lateral jsonb_array_elements_text(q.options) o(option_value)
  where q.ch4_scored
    and q.gender_visibility in ('all',
      case p_gender when 'male' then 'womenOnly' when 'female' then 'menOnly' end)
  union all
  select 'ch2.sect.matrix', sect_code, 2, array['sect', 'matrix', sect_code]
  from unnest(array['sunni', 'shia', p_sect]) sect_code
  where sect_code is not null
  union all
  select 'ch2.sect.outside_flexibility', '*', 2, array['sect', 'outside_flexibility']
  union all
  select 'ch2.' || group_id || '.flexibility', '*', 2, array[group_id, 'flexibility']
  from unnest(array['revert', 'location', 'country_of_birth', 'nationality', 'ethnicity', 'languages']) group_id;
$$;


--
-- Name: zyra_preference_lights_to_check(boolean); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_preference_lights_to_check(p_hidden boolean) RETURNS TABLE(question_id text, option_value text, light text)
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  select c.question_id, c.option_value, 'amber'::text
  from public.profiles p
  left join public.onboarding_answers o on o.user_id = p.id
  left join public.seeker_details d on d.user_id = p.id
  cross join lateral private.zyra_preference_light_controls(
    p.gender, private.zyra_current_sect_third_key(d.sect, d.sect_other)) c
  cross join lateral (
    select case c.chapter when 4 then o.ch4_preferences #>> c.path
      else d.preferences #>> c.path end as light,
      private.zyra_preference_control_visible(p.gender, o.ch3_answers,
        c.chapter, c.question_id, c.option_value) as visible
  ) current_control
  where p.id = (select auth.uid()) and p.role = 'seeker'
    and current_control.light in ('amber', 'yellow')
    and (case when p_hidden then not current_control.visible and (
        c.chapter = 4 or private.zyra_hidden_ch2_light_applicable(c.path[1], d.preferences -> c.path[1])
      ) else current_control.visible end)
    and not exists (
      select 1 from public.preference_light_confirmations r
      where r.user_id = p.id and r.light = current_control.light
        and (c.chapter = 2) = (r.question_id like 'ch2.%' or r.question_id in (
          'sect', 'revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages'))
        and private.zyra_preference_receipt_path(c.chapter, r.question_id, r.option_value) = c.path
    )
  order by c.question_id, c.option_value;
$$;


--
-- Name: zyra_preference_receipt_path(integer, text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_preference_receipt_path(p_chapter integer, p_question text, p_option text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
  select case
    when p_chapter = 4 then array[p_question, p_option]
    when p_question in ('sect', 'ch2.sect.matrix') then array['sect', 'matrix', p_option]
    when p_option = '*' and p_question like 'ch2.%' then (string_to_array(p_question, '.'))[2:3]
    else array[p_question, 'flexibility'] end;
$$;


--
-- Name: zyra_protect_new_report_attempt(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_protect_new_report_attempt() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  insert into private.report_protected_attempts (report_id, attempt_id)
  select r.id, new.id from public.matches m
  join public.profile_reports r on least(r.reporter_id, r.reported_id) = m.seeker_a_id
    and greatest(r.reporter_id, r.reported_id) = m.seeker_b_id
  where m.id = new.match_id and r.status in ('pending', 'reviewing') and r.attempt_id is null
  on conflict do nothing;
  return new;
end;
$$;


--
-- Name: zyra_protect_report_attempts_before_departure(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_protect_report_attempts_before_departure(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  perform m.id from public.matches m
  where p_user_id in (m.seeker_a_id, m.seeker_b_id)
  order by m.id for update;

  insert into private.report_protected_attempts (report_id, attempt_id)
  select r.id, a.id from public.profile_reports r
  join public.matches m on m.seeker_a_id = least(r.reporter_id, r.reported_id)
    and m.seeker_b_id = greatest(r.reporter_id, r.reported_id)
  join public.journey_attempts a on a.match_id = m.id
    and (r.attempt_id is null or r.attempt_id = a.id)
  where p_user_id in (r.reporter_id, r.reported_id) and r.status in ('pending', 'reviewing')
  on conflict do nothing;
end;
$$;


--
-- Name: zyra_purge_account_deleted_match(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_purge_account_deleted_match(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  perform m.id
  from public.matches m
  join private.zyra_account_deleted_matches d on d.match_id = m.id
  where m.id = p_match_id
  for update of m;
  if not found then return; end if;

  if not private.zyra_match_has_protected_data(p_match_id) then
    delete from public.matches where id = p_match_id;
  elsif not private.zyra_match_has_active_hold(p_match_id) then
    delete from public.journey_attempts a
    where a.match_id = p_match_id and not private.zyra_attempt_has_open_report(a.id);
  end if;
end;
$$;


--
-- Name: zyra_purge_account_deleted_matches(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_purge_account_deleted_matches() RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
declare
  v_match_id uuid;
begin
  for v_match_id in
    select d.match_id
    from private.zyra_account_deleted_matches d
    order by d.match_id
  loop
    perform private.zyra_purge_account_deleted_match(v_match_id);
  end loop;
end;
$$;


--
-- Name: zyra_purge_closed_ended_journeys(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_purge_closed_ended_journeys() RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
declare
  v_attempt_id uuid;
begin
  for v_attempt_id in
    select r.attempt_id
    from private.zyra_ended_journey_removals r
    join public.journey_attempts a on a.id = r.attempt_id
    join public.matches m on m.id = a.match_id
    where a.status = 'ended'
      and r.seeker_a_removed_at is not null and r.seeker_b_removed_at is not null
      and not exists (
        select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
      )
    order by m.id, a.attempt_number
  loop
    perform private.zyra_purge_ended_journey(v_attempt_id);
  end loop;
  perform private.zyra_purge_account_deleted_matches();
end;
$$;


--
-- Name: zyra_purge_ended_journey(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_purge_ended_journey(p_attempt_id uuid) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
declare
  v_match public.matches%rowtype;
  v_removal private.zyra_ended_journey_removals%rowtype;
  v_attempt public.journey_attempts%rowtype;
begin
  select m.* into v_match
  from public.matches m join public.journey_attempts a on a.match_id = m.id
  where a.id = p_attempt_id and a.status = 'ended'
  for update of m;
  if not found then return; end if;

  select * into v_attempt from public.journey_attempts a
  where a.id = p_attempt_id and a.status = 'ended' for update;
  if not found then return; end if;

  select * into v_removal from private.zyra_ended_journey_removals r
  where r.attempt_id = p_attempt_id;
  if not found
      or v_removal.seeker_a_removed_at is null
      or v_removal.seeker_b_removed_at is null then
    return;
  end if;

  if private.zyra_match_has_active_hold(v_match.id)
     or private.zyra_attempt_has_open_report(p_attempt_id) then
    return;
  end if;

  if v_match.status = 'ended' and not exists (
    select 1 from public.journey_attempts newer
    where newer.match_id = v_match.id and newer.attempt_number > v_attempt.attempt_number
  ) then
    insert into private.zyra_purged_ended_match_projections(match_id)
    values (v_match.id) on conflict do nothing;
    update public.matches
    set journey_stage = null, ended_by = null, end_note = null
    where id = v_match.id;
  end if;

  -- Q92/Q98's active restart can use this mutual consent. Preserve its
  -- dependency without the former attempt's scores, answers or lifecycle text.
  insert into private.zyra_journey_reveal_tombstones (
    attempt_id, match_id, created_at, started_at, ended_at, revealed_at, consent_for_attempt_id
  )
  select v_attempt.id, v_match.id, v_attempt.created_at, v_attempt.started_at, v_attempt.ended_at,
         jc.revealed_at, active.id
  from public.journey_compatibility jc
  join public.journey_attempts active on active.match_id = jc.match_id and active.status = 'active'
  where jc.match_id = v_match.id and jc.attempt_id = p_attempt_id
    and jc.seeker_a_revealed and jc.seeker_b_revealed
    and v_attempt.end_reason is distinct from 'safety_concern'
    and v_attempt.attempt_number < active.attempt_number
    and exists (
      select 1 from public.journey_requests r
      where r.match_id = v_match.id and r.attempt_id = active.id and r.status = 'accepted'
    );

  -- The exact attempt's FKs cascade all shared content and archive state.
  -- Accepted restart requests that produced it cannot survive with a null
  -- attempt, so erase those rows explicitly first. Other attempts stay intact.
  delete from public.journey_requests where attempt_id = p_attempt_id;
  delete from public.journey_attempts where id = p_attempt_id;
end;
$$;


--
-- Name: zyra_queue_deleted_photo_source(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_queue_deleted_photo_source() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform private.zyra_queue_owned_photo_object(old.user_id, 'profile-photo-sources', old.source_path);
  return old;
end;
$$;


--
-- Name: zyra_queue_owned_photo_object(uuid, text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_queue_owned_photo_object(p_owner uuid, p_bucket text, p_path text) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  insert into public.photo_object_deletions (bucket, path)
  select p_bucket, p_path
  where pg_catalog.split_part(p_path, '/', 1) = p_owner::text
    and pg_catalog.length(p_path) > 37
    and not exists (
      select 1 from storage.objects o where o.bucket_id = p_bucket and o.name = p_path
        and o.owner_id is not null and o.owner_id <> p_owner::text
    )
  on conflict (bucket, path) do nothing;
$$;


--
-- Name: zyra_queue_photo_folder(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_queue_photo_folder(p_owner uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_object record;
begin
  for v_object in
    select 'profile-photos'::text as bucket, p.storage_path as path
      from public.profile_photos p where p.user_id = p_owner
    union
    select 'profile-photo-sources', p.source_path from public.profile_photos p where p.user_id = p_owner
    union
    select o.bucket_id, o.name from storage.objects o
      where o.bucket_id in ('profile-photos', 'profile-photo-sources')
        and o.name like p_owner::text || '/%'
  loop
    perform private.zyra_queue_owned_photo_object(p_owner, v_object.bucket, v_object.path);
  end loop;
end;
$$;


--
-- Name: zyra_red_hard_requirements(jsonb, jsonb); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_red_hard_requirements(p_lights jsonb, p_requirements jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
  select coalesce(jsonb_agg(item.value order by item.ordinal), '[]'::jsonb)
  from jsonb_array_elements_text(p_requirements) with ordinality as item(value, ordinal)
  where p_lights ->> item.value = 'red';
$$;


--
-- Name: zyra_remove_departing_profile(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_remove_departing_profile() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_deleted_at timestamptz := clock_timestamp();
  v_purge_at timestamptz := v_deleted_at + interval '8760 hours';
  v_match_ids uuid[];
  v_match_id uuid;
begin
  -- The profile row lock also excludes a new owner reference. Lock existing
  -- owner rows before deciding whether any plan still has coverage.
  perform 1 from public.family_subscriptions family
  where family.owner_id = old.id order by family.id for update;
  if exists (
    select 1 from public.family_subscriptions family
    where family.owner_id = old.id
      and family.status in ('active', 'billing_grace', 'cancel_at_period_end')
  ) then raise exception 'family_owner_must_transfer'; end if;

  update public.family_ownership_transfers transfer
  set status = 'cancelled'
  where old.id in (transfer.current_owner_id, transfer.replacement_owner_id)
    and transfer.status in ('pending_acceptance', 'pending_purchase', 'scheduled');

  update public.family_subscriptions family
  set status = 'cancelled'
  where family.owner_id = old.id and family.status = 'pending';

  update private.seeker_trial_ledger trial
  set claimed_by = null, status = 'completed', payment_authorisation_ref_hash = null,
      started_at = null, ends_at = null, updated_at = null
  where trial.claimed_by = old.id;

  -- Preserve report links before detaching either participant. This also
  -- locks the matches in a deterministic order.
  perform private.zyra_protect_report_attempts_before_departure(old.id);
  perform private.zyra_erase_departing_notification_previews(old.id);

  update public.protection_holds
  set released_by = null, released_by_departed = true
  where released_by = old.id;

  -- Both invite actor FKs null on profile deletion. Their paired checks also
  -- require clearing the corresponding time in the same statement.
  update public.wali_invites invite
  set seen_at = case when invite.seen_by = old.id then null else invite.seen_at end,
      seen_by = case when invite.seen_by = old.id then null else invite.seen_by end,
      declined_at = case when invite.declined_by = old.id then null else invite.declined_at end,
      declined_by = case when invite.declined_by = old.id then null else invite.declined_by end,
      label = null
  where old.id in (invite.seen_by, invite.declined_by, invite.accepted_by);


  select coalesce(array_agg(m.id order by m.id), '{}'::uuid[]) into v_match_ids
  from public.matches m where old.id in (m.seeker_a_id, m.seeker_b_id);

  perform t.id from public.family_message_threads t
  where t.seeker_id = old.id
     or exists (
       select 1 from public.family_message_chats chat
       join public.journey_attempts attempt on attempt.id = chat.attempt_id
       where chat.thread_id = t.id and attempt.match_id = any(v_match_ids)
     )
     or exists (select 1 from public.family_messages msg
                where msg.thread_id = t.id and msg.sender_id = old.id)
  order by t.id for update;

  perform private.zyra_seal_departing_family_journey_chats(old.id, v_match_ids, v_deleted_at);

  insert into private.safety_sealed_messages
    (source, source_message_id, thread_id, sender_id, body, sent_at, sealed_at, purge_at)
  select 'journey', msg.id, msg.conversation_id, msg.sender_id,
    msg.content, msg.created_at, v_deleted_at, v_purge_at
  from public.messages msg
  join public.conversations conversation on conversation.id = msg.conversation_id
  where conversation.match_id = any(v_match_ids)
  union all
  select 'guardian_circle', msg.id, msg.thread_id, msg.sender_id,
    msg.body, msg.created_at, v_deleted_at, v_purge_at
  from public.family_messages msg
  join public.family_message_threads thread on thread.id = msg.thread_id
  where msg.kind = 'message' and (thread.seeker_id = old.id or msg.sender_id = old.id)
    and exists (select 1 from public.family_message_chats chat
                where chat.id = msg.chat_id and chat.kind = 'main')
  on conflict (source, source_message_id) do nothing;

  insert into private.zyra_report_sealed_messages(report_id, sealed_message_id)
  select protection.report_id, sealed.id
  from private.report_protected_attempts protection
  join public.conversations conversation on conversation.attempt_id = protection.attempt_id
  join private.safety_sealed_messages sealed on sealed.thread_id = conversation.id
    and sealed.source = 'journey'
  where conversation.match_id = any(v_match_ids)
  on conflict do nothing;

  insert into private.zyra_circle_seal_protections(sealed_message_id, report_id)
  select sealed.id, report.id
  from public.family_message_reports report
  join public.family_message_threads thread on thread.id = report.thread_id
  join private.safety_sealed_messages sealed
    on sealed.source = 'guardian_circle' and sealed.thread_id = report.thread_id
    and sealed.circle_chat_id is null
    and not exists (select 1 from private.zyra_family_chat_report_attempts protection
                    where protection.report_id = report.id)
  where thread.seeker_id = old.id
    or (sealed.source_message_id = report.message_id and sealed.sender_id = old.id)
  on conflict do nothing;

  update public.family_message_reports report
  set sealed_message_id = protection.sealed_message_id
  from private.zyra_circle_seal_protections protection
  join private.safety_sealed_messages sealed on sealed.id = protection.sealed_message_id
  where report.id = protection.report_id and report.message_id = sealed.source_message_id;

  -- A Circle is currently keyed by its owning Seeker. That owner's entire
  -- Circle disappears. In another Seeker's Circle, remove the deleted
  -- account's own contributions and let its membership FK cascade.
  delete from public.family_message_threads where seeker_id = old.id;
  with removed as (
    delete from public.family_messages where sender_id = old.id returning thread_id
  )
  update public.family_message_threads thread
  set last_message_at = (
    select max(msg.created_at) from public.family_messages msg
    where msg.thread_id = thread.id and msg.sender_id is distinct from old.id
      and exists (select 1 from public.family_message_chats chat
                  where chat.id = msg.chat_id and chat.kind = 'main')
  )
  where thread.id in (select thread_id from removed);

  -- Recipient identity is needed only for this insert. DISTINCT covers
  -- pairs with multiple attempts and an existing Journey plus requests.
  insert into public.notifications(user_id, type, title, body, payload)
  select distinct survivor.id, 'journey_ended_profile_inactive',
    'One of your Journeys has ended',
    'This profile is no longer active. Your place is free for a new Journey.', '{}'::jsonb
  from public.matches m
  join public.profiles survivor on survivor.id =
    case when m.seeker_a_id = old.id then m.seeker_b_id else m.seeker_a_id end
  where m.id = any(v_match_ids) and survivor.role = 'seeker'
    and (m.status in ('active', 'ended') or exists (
      select 1 from public.journey_attempts a
      where a.match_id = m.id and a.status in ('active', 'ended')
    ));

  delete from public.notifications where related_match_id = any(v_match_ids);
  delete from public.journey_requests
  where match_id = any(v_match_ids) or old.id in (requested_by, requested_to);
  delete from public.wali_suggestions where old.id in (wali_id, seeker_id, suggested_id);

  insert into private.zyra_account_deleted_matches(match_id)
  select unnest(v_match_ids);

  -- Preserve the records whose author FK would otherwise erase content
  -- even when its parent attempt is protected. Unprotected attempts and
  -- their temporary snapshots are purged together below.
  insert into private.zyra_deleted_attempt_evidence(attempt_id, records)
  select a.id, jsonb_build_object(
    'message_senders', (select jsonb_agg(jsonb_build_object('id', msg.id, 'sender_id', msg.sender_id))
      from public.messages msg join public.conversations c on c.id = msg.conversation_id
      where c.attempt_id = a.id and msg.sender_id = old.id),
    'family_answers', (select jsonb_agg(to_jsonb(r)) from public.journey_family_answers r
      where r.attempt_id = a.id and r.answerer_id = old.id),
    'guardian_assignments', (select jsonb_agg(to_jsonb(r))
      from public.journey_guardian_assignments r
      join public.wali_links link on link.id = r.wali_link_id
      where r.attempt_id = a.id
        and old.id in (r.seeker_id, r.granted_by, r.revoked_by, link.wali_id)),
    'milestone_attestations', (select jsonb_agg(to_jsonb(r)) from public.journey_milestone_attestations r
      where r.attempt_id = a.id and old.id in (r.proposed_by, r.confirmed_by)),
    'phase_answers', (select jsonb_agg(to_jsonb(r)) from public.journey_phase_answers r
      where r.attempt_id = a.id and r.seeker_id = old.id),
    'phase_checkpoints', (select jsonb_agg(to_jsonb(r)) from public.journey_phase_checkpoints r
      where r.attempt_id = a.id and r.seeker_id = old.id),
    'phase_ratings', (select jsonb_agg(to_jsonb(r)) from public.journey_phase_ratings r
      where r.attempt_id = a.id and r.rater_id = old.id),
    'salams', (select jsonb_agg(to_jsonb(r)) from public.journey_salams r
      where r.attempt_id = a.id and r.seeker_id = old.id),
    'stage_checkpoints', (select jsonb_agg(to_jsonb(r)) from public.journey_stage_checkpoints r
      where r.attempt_id = a.id and r.seeker_id = old.id)
  )
  from public.journey_attempts a where a.match_id = any(v_match_ids)
    and (private.zyra_attempt_has_open_report(a.id)
      or private.zyra_match_has_active_hold(a.match_id));

  -- Clear both participant keys before later FK cascades. Null keys and the
  -- private marker give retained records no membership or restart route.
  update public.matches
  set seeker_a_id = null, seeker_b_id = null,
      status = 'ended', ended_at = coalesce(ended_at, v_deleted_at),
      suspended_by = null, suspended_at = null, also_paused_by = null, also_paused_at = null
  where id = any(v_match_ids);

  update public.journey_attempts
  set status = 'ended', ended_at = coalesce(ended_at, v_deleted_at),
      paused_by = null, paused_at = null, also_paused_by = null, also_paused_at = null
  where match_id = any(v_match_ids);

  update public.conversations
  set status = 'closed', closed_at = coalesce(closed_at, v_deleted_at)
  where match_id = any(v_match_ids);

  foreach v_match_id in array v_match_ids loop
    perform private.zyra_purge_account_deleted_match(v_match_id);
  end loop;
  return old;
end;
$$;


--
-- Name: zyra_remove_ended_journey_for(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_remove_ended_journey_for(p_attempt_id uuid, p_seeker_id uuid) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
declare
  v_match public.matches%rowtype;
  v_removed_at timestamptz := pg_catalog.clock_timestamp();
begin
  select m.* into v_match
  from public.matches m join public.journey_attempts a on a.match_id = m.id
  where a.id = p_attempt_id and a.status = 'ended'
    and p_seeker_id in (m.seeker_a_id, m.seeker_b_id)
  for update of m;
  if not found then
    raise exception using errcode = '42501', message = 'ended_journey_not_available';
  end if;

  insert into private.zyra_ended_journey_removals as r (
    attempt_id, seeker_a_removed_at, seeker_b_removed_at
  ) values (
    p_attempt_id,
    case when p_seeker_id = v_match.seeker_a_id then v_removed_at end,
    case when p_seeker_id = v_match.seeker_b_id then v_removed_at end
  ) on conflict (attempt_id) do update
  set seeker_a_removed_at = coalesce(r.seeker_a_removed_at, excluded.seeker_a_removed_at),
      seeker_b_removed_at = coalesce(r.seeker_b_removed_at, excluded.seeker_b_removed_at);

  perform private.zyra_purge_ended_journey(p_attempt_id);
end;
$$;


--
-- Name: zyra_resolve_report_attempt(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_resolve_report_attempt() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_match_id uuid;
begin
  -- Match deletion already holds the departing profile lock before locking
  -- pairs. Use that same order when filing against the pair.
  perform p.id from public.profiles p
  where p.id in (new.reporter_id, new.reported_id)
  order by p.id for key share;

  select m.id into v_match_id from public.matches m
  where m.seeker_a_id = least(new.reporter_id, new.reported_id)
    and m.seeker_b_id = greatest(new.reporter_id, new.reported_id)
  for update;

  if new.attempt_id is not null then
    if new.source not in ('journey', 'chat') or not exists (
      select 1 from public.journey_attempts a
      where a.id = new.attempt_id and a.match_id = v_match_id and a.status in ('active', 'ended')
    ) then
      raise exception using errcode = '42501', message = 'report_attempt_not_available';
    end if;
  elsif new.source in ('journey', 'chat') then
    -- An older client may report from either the active or an ended card.
    -- Only infer an exact ID when there is one possible attempt; otherwise
    -- link every attempt so an older report cannot lose its evidence.
    select (array_agg(a.id))[1] into new.attempt_id from public.journey_attempts a
    where a.match_id = v_match_id and a.status in ('active', 'ended')
    having count(*) = 1;
  end if;
  return new;
end;
$$;


--
-- Name: zyra_retire_personal_code(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_retire_personal_code() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if tg_op = 'DELETE' then
    insert into private.zyra_retired_personal_code_hashes(code_sha256)
    values (extensions.digest(old.code, 'sha256'))
    on conflict do nothing;
    return old;
  end if;
  if new.code is distinct from old.code then
    insert into private.zyra_retired_personal_code_hashes(code_sha256)
    values (extensions.digest(old.code, 'sha256'))
    on conflict do nothing;
  end if;
  return new;
end;
$$;


--
-- Name: zyra_run_inactivity_job_at(timestamp with time zone); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_run_inactivity_job_at(p_now timestamp with time zone) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    SET "TimeZone" TO 'UTC'
    AS $$
declare
  v_account record;
  v_notice public.zyra_inactivity_notices%rowtype;
  v_due_at timestamptz;
  v_count integer;
  v_attempt record;
  v_variables jsonb;
begin
  if not pg_try_advisory_xact_lock(hashtextextended('zyra-inactivity-job', 0)) then return; end if;

  for v_account in
    select p.id, p.first_name, p.last_active_at, calendar.anniversary
    from public.profiles p
    cross join lateral (
      select ((p.last_active_at at time zone 'UTC') + interval '2 years') at time zone 'UTC' as anniversary
    ) calendar
    left join public.zyra_inactivity_notices n on n.user_id = p.id
    where calendar.anniversary <= p_now + interval '14 days'
      and (
        n.user_id is null
        or ((n.cleared_at is not null or n.completed_at is not null) and p.last_active_at > n.warned_at)
        or (n.cleared_at is null and n.completed_at is null and n.removal_due_at <= p_now)
      )
    order by p.id
    for no key update of p skip locked
  loop
    -- Recheck the notice after taking the profile lock. It may have been
    -- cleared while the initial query was reading its snapshot.
    select * into v_notice from public.zyra_inactivity_notices n where n.user_id = v_account.id;

    if v_notice.user_id is null or (
      (v_notice.cleared_at is not null or v_notice.completed_at is not null)
      and v_account.last_active_at > v_notice.warned_at
    ) then
      select count(*)::integer into v_count from private.zyra_inactivity_ended_attempts(v_account.id);
      if v_count = 0 then continue; end if;
      v_due_at := v_account.anniversary + interval '14 days';

      insert into public.zyra_inactivity_notices (user_id, warned_at, removal_due_at)
      values (v_account.id, p_now, v_due_at)
      on conflict (user_id) do update
      set warned_at = excluded.warned_at, removal_due_at = excluded.removal_due_at,
          cleared_at = null, completed_at = null, welcome_back_pending = false
      returning * into v_notice;

      v_variables := jsonb_build_object(
        'first_name', v_account.first_name, 'ended_journeys', v_count, 'removal_date', v_due_at::date
      );
      insert into public.email_outbox (user_id, template_key, variables, due_at)
      select v_account.id, email.template_key, v_variables, v_account.anniversary + email.offset_days
      from (values
        ('inactivity_1', interval '-14 days'),
        ('inactivity_2', interval '-7 days'),
        ('inactivity_3', interval '0 days'),
        ('inactivity_4', interval '7 days')
      ) email(template_key, offset_days);

      -- Q124 keeps this signal for My ZYRA. Email is the only outbound
      -- inactivity communication in LOCK 32.
      if p_now < v_due_at then
        perform public.create_notification(v_account.id, 'inactivity_warning', '', null, null);
      end if;
    end if;

    if v_notice.cleared_at is not null or v_notice.completed_at is not null
       or v_notice.removal_due_at > p_now then
      continue;
    end if;

    v_count := 0;
    for v_attempt in
      select eligible.attempt_id, eligible.match_id
      from private.zyra_inactivity_ended_attempts(v_account.id) eligible
      order by eligible.match_id, eligible.attempt_id
    loop
      -- Manual removal, report filing and account deletion lock the pair
      -- first. Under that lock, recheck in case this copy was already removed.
      perform 1 from public.matches m where m.id = v_attempt.match_id for update;
      if not found then continue; end if;
      if not exists (
        select 1 from private.zyra_inactivity_ended_attempts(v_account.id) eligible
        where eligible.attempt_id = v_attempt.attempt_id
      ) then continue; end if;

      perform private.zyra_remove_ended_journey_for(v_attempt.attempt_id, v_account.id);
      v_count := v_count + 1;
    end loop;

    delete from public.notifications where user_id = v_account.id and type = 'inactivity_warning';
    -- A delayed job keeps the planned dates for the audit trail. Superseded
    -- reminders must not go out after the archive was removed.
    update public.email_outbox set cancelled_at = p_now
    where user_id = v_account.id and due_at >= v_notice.removal_due_at - interval '28 days'
      and due_at < v_notice.removal_due_at and sent_at is null and cancelled_at is null;
    if v_count = 0 then
      update public.zyra_inactivity_notices set cleared_at = p_now where user_id = v_account.id;
    else
      update public.zyra_inactivity_notices set completed_at = p_now where user_id = v_account.id;
      -- The completion email is inserted only with the removal itself. Its
      -- date stays anchored to the inactivity anniversary if the job ran late.
      insert into public.email_outbox (user_id, template_key, variables, due_at)
      values (v_account.id, 'inactivity_5', jsonb_build_object(
        'first_name', v_account.first_name, 'ended_journeys', v_count,
        'removal_date', v_notice.removal_due_at::date
      ), v_notice.removal_due_at);
    end if;
  end loop;

  perform private.zyra_purge_closed_ended_journeys();
end;
$$;


--
-- Name: zyra_directional_results; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_directional_results (
    viewer uuid NOT NULL,
    subject uuid NOT NULL,
    capture_version text NOT NULL,
    inputs_hash text NOT NULL,
    overall numeric NOT NULL,
    area_bands jsonb NOT NULL,
    state text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT zyra_directional_results_area_bands_check CHECK (((jsonb_typeof(area_bands) = 'array'::text) AND (jsonb_array_length(area_bands) = 12) AND (NOT jsonb_path_exists(area_bands, '$[*]?(((@ != "strong" && @ != "good") && @ != "some_differences") && @ != "not_enough")'::jsonpath)))),
    CONSTRAINT zyra_directional_results_capture_version_check CHECK ((capture_version = ANY (ARRAY['v0'::text, 'v1'::text]))),
    CONSTRAINT zyra_directional_results_check CHECK ((viewer <> subject)),
    CONSTRAINT zyra_directional_results_inputs_hash_check CHECK ((inputs_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT zyra_directional_results_overall_check CHECK (((overall >= (0)::numeric) AND (overall <= (100)::numeric))),
    CONSTRAINT zyra_directional_results_state_check CHECK ((state = 'ok'::text))
);


--
-- Name: zyra_save_direction_result(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_save_direction_result(p_viewer uuid, p_subject uuid) RETURNS private.zyra_directional_results
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
declare
  v_result private.zyra_directional_results%rowtype;
begin
  perform pg_advisory_xact_lock(hashtextextended(
    'zyra-compatibility-direction:' || p_viewer::text || ':' || p_subject::text, 0));
  select r.* into v_result from private.zyra_directional_results r
  where r.viewer = p_viewer and r.subject = p_subject;
  if found then
    return v_result;
  end if;
  -- A first save uses one coherent capture. Preference updates and
  -- confirmation writes lock these same rows, in chapter order.
  perform o.user_id from public.onboarding_answers o
  where o.user_id in (p_viewer, p_subject)
  order by o.user_id for share;
  perform d.user_id from public.seeker_details d
  where d.user_id in (p_viewer, p_subject)
  order by d.user_id for share;

  select p_viewer, p_subject, s.capture_version, s.inputs_hash, s.overall, s.area_bands, s.state, now()
    into v_result
    from public.zyra_score_direction_v1(p_viewer, p_subject) s;
  if v_result.state = 'ok' then
    insert into private.zyra_directional_results
    select v_result.*
    on conflict (viewer, subject) do nothing
    returning * into v_result;
    if not found then
      select r.* into strict v_result from private.zyra_directional_results r
      where r.viewer = p_viewer and r.subject = p_subject;
    end if;
  end if;
  return v_result;
end;
$$;


--
-- Name: zyra_seal_departing_family_journey_chats(uuid, uuid[], timestamp with time zone); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_seal_departing_family_journey_chats(p_user uuid, p_match_ids uuid[], p_deleted_at timestamp with time zone) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  insert into private.safety_sealed_messages
    (source, source_message_id, thread_id, sender_id, body, sent_at, sealed_at, purge_at,
     circle_chat_id, circle_attempt_id)
  select 'guardian_circle', msg.id, msg.thread_id, msg.sender_id, msg.body, msg.created_at,
    p_deleted_at, p_deleted_at + interval '8760 hours', chat.id, attempt.id
  from public.family_messages msg
  join public.family_message_chats chat on chat.id = msg.chat_id
  join public.journey_attempts attempt on attempt.id = chat.attempt_id
  where msg.kind = 'message'
    and (attempt.match_id = any(p_match_ids) or msg.sender_id = p_user)
  on conflict (source, source_message_id) do nothing;

  insert into private.zyra_circle_seal_protections(sealed_message_id, report_id)
  select sealed.id, protection.report_id
  from private.zyra_family_chat_report_attempts protection
  join private.safety_sealed_messages sealed on sealed.circle_chat_id = protection.chat_id
  join public.journey_attempts attempt on attempt.id = protection.attempt_id
  where attempt.match_id = any(p_match_ids) or sealed.sender_id = p_user
  on conflict do nothing;

  -- Populate the report pointer before either message FK is detached.
  update public.family_message_reports report
  set sealed_message_id = sealed.id
  from private.zyra_family_chat_report_attempts protection
  join private.safety_sealed_messages sealed on sealed.circle_chat_id = protection.chat_id
  join public.journey_attempts attempt on attempt.id = protection.attempt_id
  where report.id = protection.report_id and report.message_id = sealed.source_message_id
    and (attempt.match_id = any(p_match_ids) or sealed.sender_id = p_user);

  -- Neither Circle can see a counterpart's chat after departure. The
  -- private seals retain the exact attempt identity after live rows cascade.
  delete from public.family_message_chats chat
  using public.journey_attempts attempt
  where chat.attempt_id = attempt.id and attempt.match_id = any(p_match_ids);
end;
$$;


--
-- Name: zyra_sect_light_missing(jsonb, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_sect_light_missing(p_preferences jsonb, p_option text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
  select jsonb_typeof(p_preferences) = 'object'
    and coalesce(jsonb_typeof(p_preferences -> 'sect'), 'null') in ('object', 'null')
    and coalesce(jsonb_typeof(p_preferences #> '{sect,matrix}'), 'null') in ('object', 'null')
    and p_preferences #>> array['sect', 'matrix', p_option] is null;
$$;


--
-- Name: zyra_source_photo_path_owned(text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_source_photo_path_owned(p_path text, p_owner text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  select p_owner = (select auth.uid())::text and
    exists (select 1 from auth.users u where u.id = (select auth.uid())) and
    p_path ~ ('^' || p_owner || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]jpg$');
$_$;


--
-- Name: zyra_touch_identity_verification_attempt(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_touch_identity_verification_attempt() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'private'
    AS $$
begin
  new.updated_at := now();
  return new;
end;
$$;


--
-- Name: zyra_unreferenced_photo_path_writable(text, text); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_unreferenced_photo_path_writable(p_bucket text, p_path text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not private.zyra_photo_path_writable(p_bucket, p_path) then return false; end if;
  return not private.zyra_photo_object_referenced(p_bucket, p_path);
end;
$$;


--
-- Name: zyra_version_compatibility_capture(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_version_compatibility_capture() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.capture_version := 'v1';
    else
      new.capture_version := old.capture_version;
    end if;
  end if;
  return new;
end;
$$;


--
-- Name: accept_wali_invite(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accept_wali_invite(p_token text, p_relationship text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_invite public.wali_invites%rowtype;
  v_accepter_id uuid := auth.uid();
  v_accepter_role text;
  v_inviter_role text;
  v_accepter_name text;
  v_seeker_id uuid;
  v_wali_id uuid;
  v_link_id uuid;
  v_relationship text;
  v_active_count integer;
  v_place_free boolean;
  v_place_kind text;
  v_guardian_one boolean;
  v_invitation_id uuid;
  v_at timestamptz;
begin
  if v_accepter_id is null then
    raise exception 'Not signed in';
  end if;

  if p_relationship is not null
     and p_relationship not in ('father','brother','grandfather','uncle',
                                'legal_guardian','family_representative','other') then
    raise exception 'Unknown relationship: %', p_relationship;
  end if;

  select wi.* into v_invite
  from public.wali_invites wi
  where wi.token = p_token and wi.status = 'pending' and wi.source = 'legacy_code'
  for update;
  if not found then
    raise exception 'Invite not found or already used';
  end if;

  -- This helper is the shared expiry predicate. On refusal its update rolls
  -- back with the exception. The preview and expiry sweep persist expiry.
  if public.expire_wali_invite_if_due(v_invite) <> 'pending' then
    raise exception 'invite_expired'
      using hint = 'This invite has expired. Ask for a new code.';
  end if;

  if v_invite.inviter_id = v_accepter_id then
    raise exception 'Cannot accept your own invite';
  end if;

  select p.role, p.first_name into v_accepter_role, v_accepter_name
  from public.profiles p where p.id = v_accepter_id;
  if v_accepter_role is null then
    raise exception 'Complete your profile before accepting an invite';
  end if;

  select p.role into v_inviter_role
  from public.profiles p where p.id = v_invite.inviter_id;
  if v_inviter_role is null then
    raise exception 'Invite is no longer valid';
  end if;
  if v_inviter_role is distinct from v_invite.inviter_role then
    raise exception 'invite_role_mismatch'
      using hint = 'This invite does not match the account that sent it. Ask them to send a new one.';
  end if;

  if v_inviter_role = 'seeker' then
    if v_accepter_role <> 'wali' then
      raise exception 'This invite is for a Wali account';
    end if;
    v_seeker_id := v_invite.inviter_id;
    v_wali_id := v_accepter_id;
  elsif v_inviter_role = 'wali' then
    if v_accepter_role <> 'seeker' then
      raise exception 'This invite is for a Seeker account';
    end if;
    v_seeker_id := v_accepter_id;
    v_wali_id := v_invite.inviter_id;
  else
    raise exception 'Invalid invite';
  end if;

  -- Serialize even when there are no link rows to lock. A write conflict
  -- also forces a stale repeatable-read transaction to retry.
  insert into private.zyra_guardian_invite_accept_guards as guard (seeker_id, revision)
  values (v_seeker_id, 1)
  on conflict (seeker_id) do update set revision = guard.revision + 1;

  perform wl.id
  from public.wali_links wl
  where wl.seeker_id = v_seeker_id and (wl.status = 'active' or wl.wali_id = v_wali_id)
  order by wl.id
  for update;

  if public.expire_wali_invite_if_due(v_invite) <> 'pending' then
    raise exception 'invite_expired'
      using hint = 'This invite has expired. Ask for a new code.';
  end if;

  if not public.zyra_can_guardian_link(v_seeker_id, v_wali_id) then
    raise exception 'romantic_edge_exists'
      using hint = 'These two people have a Journey together. A Guardian '
                   'relationship cannot be created over one. End the Journey '
                   'first if that is really what you both want.';
  end if;

  if v_inviter_role = 'seeker' then
    v_at := clock_timestamp();
    -- Re-accepting a code for the same pair reuses its link and consumes
    -- neither another total place nor another Basic place.
    select capacity.active_count, capacity.basic_place_free into v_active_count, v_place_free
    from private.zyra_guardian_invite_capacity(v_seeker_id, v_wali_id, v_at) capacity;

    if v_active_count >= 10 then
      raise exception 'guardian_capacity_exceeded';
    end if;
    v_guardian_one := public.zyra_has_paid_role(v_wali_id, 'guardian', v_at);
    if not v_guardian_one and not v_place_free
       and not public.zyra_has_paid_role(v_seeker_id, 'seeker', v_at) then
      raise exception 'needs_guardian_one';
    end if;
    v_place_kind := case when v_guardian_one then 'guardian_one' else 'basic_place' end;
    v_invitation_id := v_invite.id;
  end if;

  v_relationship := coalesce(p_relationship, v_invite.relationship);

  insert into public.wali_links as existing (
    seeker_id, wali_id, status, relationship, place_kind, invitation_id
  ) values (
    v_seeker_id, v_wali_id, 'active', v_relationship, v_place_kind, v_invitation_id
  )
  on conflict (seeker_id, wali_id) do update
    set status = 'active',
        relationship = coalesce(excluded.relationship, existing.relationship),
        place_kind = coalesce(excluded.place_kind, existing.place_kind),
        invitation_id = coalesce(excluded.invitation_id, existing.invitation_id)
  returning id into v_link_id;

  -- Linking extinguishes one-sided intent silently in both directions.
  delete from public.likes
   where (liker_id = v_seeker_id and liked_id = v_wali_id)
      or (liker_id = v_wali_id and liked_id = v_seeker_id);
  delete from public.saves
   where (saver_id = v_seeker_id and saved_id = v_wali_id)
      or (saver_id = v_wali_id and saved_id = v_seeker_id);
  delete from public.passes
   where (passer_id = v_seeker_id and passed_id = v_wali_id)
      or (passer_id = v_wali_id and passed_id = v_seeker_id);

  update public.wali_invites
     set status = 'accepted', accepted_at = now(), accepted_by = v_accepter_id
   where id = v_invite.id;

  perform private.zyra_create_notification(
    v_invite.inviter_id, 'wali_request', 'Wali Link Accepted',
    coalesce(v_accepter_name, 'Someone') || ' accepted your Wali link invite.', null, v_accepter_id, v_invite.id, v_link_id);
  return v_link_id;
end;
$$;


--
-- Name: ages_for(uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ages_for(p_ids uuid[]) RETURNS TABLE(id uuid, age integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if p_ids is null or array_length(p_ids, 1) is null then return; end if;
  -- 50 = Browse's page size, so every legitimate caller fits.
  -- A caller needing more is enumerating.
  if array_length(p_ids, 1) > 50 then
    raise exception 'ages_for_batch_too_large'
      using hint = 'Maximum 50 ids per call. Page the request, or use ages_for_one().';
  end if;
  return query
    select p.id, date_part('year', age(p.date_of_birth))::int
    from public.profiles p
    where p.id = any(p_ids) and public.zyra_can_view_profile(p.id);
end;
$$;


--
-- Name: FUNCTION ages_for(p_ids uuid[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.ages_for(p_ids uuid[]) IS 'Batch age lookup, HARD CAPPED AT 50 ids (I10, 2026-08-08) — it is a visibility oracle in proportion to its batch size. Use ages_for_one() for a single id. Do not raise the cap without revisiting I10.';


--
-- Name: ages_for_one(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ages_for_one(p_id uuid) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select date_part('year', age(p.date_of_birth))::int
  from public.profiles p
  where p.id = p_id and public.zyra_can_view_profile(p.id);
$$;


--
-- Name: FUNCTION ages_for_one(p_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.ages_for_one(p_id uuid) IS 'Single-id age lookup. Prefer over ages_for(uuid[]) wherever the caller has one id — one visibility hypothesis per call (I10). NULL when the caller may not view the target, indistinguishable from a missing DOB.';


--
-- Name: auto_designate_main_wali(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auto_designate_main_wali() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if new.status = 'active' then
    if tg_op = 'INSERT' then
      new.active_since := pg_catalog.clock_timestamp();
      new.guardian_link_authority_id := pg_catalog.gen_random_uuid();
    elsif old.status is distinct from 'active'
       or old.active_since is null
       or old.guardian_link_authority_id is null then
      new.active_since := pg_catalog.clock_timestamp();
      new.guardian_link_authority_id := pg_catalog.gen_random_uuid();
    else
      -- Role changes and unrelated updates do not restart one continuous
      -- relationship period or rotate its per-person history permission.
      new.active_since := old.active_since;
      new.guardian_link_authority_id := old.guardian_link_authority_id;
    end if;
  else
    new.active_since := null;
    new.guardian_link_authority_id := null;
  end if;

  if new.status = 'active' and not exists (
    select 1
    from public.wali_links w
    where w.seeker_id = new.seeker_id
      and w.is_main is true
      and w.status = 'active'
  ) then
    new.is_main := true;
  end if;

  if new.status = 'active' and new.is_main is true then
    if tg_op = 'INSERT' then
      new.main_guardian_authority_id := pg_catalog.gen_random_uuid();
    elsif old.status is distinct from 'active'
       or old.is_main is distinct from true
       or old.main_guardian_authority_id is null then
      new.main_guardian_authority_id := pg_catalog.gen_random_uuid();
    else
      new.main_guardian_authority_id := old.main_guardian_authority_id;
    end if;
  else
    new.main_guardian_authority_id := null;
  end if;

  return new;
end;
$$;


--
-- Name: FUNCTION auto_designate_main_wali(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.auto_designate_main_wali() IS 'DR-ZYRA-225/233. Preserves first-active-link Main designation; maintains the Main-assignment epoch; and maintains a separate role-neutral active-link epoch for per-Guardian past-summary permission. The link epoch rotates on activation/reactivation, survives continuous Main/Additional switches, and is null while inactive.';


--
-- Name: create_conversation_started_milestone(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_conversation_started_milestone() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE v_timeline_id UUID; v_already_exists BOOLEAN;
BEGIN
  SELECT t.id INTO v_timeline_id FROM conversations c
   JOIN timelines t ON t.attempt_id = c.attempt_id
   WHERE c.id = NEW.conversation_id;
  IF v_timeline_id IS NULL THEN RETURN NEW; END IF;
  SELECT EXISTS (SELECT 1 FROM timeline_milestones
    WHERE timeline_id = v_timeline_id AND milestone_type = 'conversation_started')
    INTO v_already_exists;
  IF NOT v_already_exists THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline_id, 'conversation_started');
  END IF;
  RETURN NEW;
END; $$;


--
-- Name: create_match_on_mutual_like(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_match_on_mutual_like() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  reciprocal_exists BOOLEAN;
  a_id UUID; b_id UUID;
  new_match_id UUID; new_attempt_id UUID; new_timeline_id UUID;
  a_name TEXT; b_name TEXT;
  first_like TIMESTAMPTZ;
BEGIN
  SELECT EXISTS (SELECT 1 FROM likes WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id)
    INTO reciprocal_exists;
  IF NOT reciprocal_exists THEN RETURN NEW; END IF;

  -- UNCHANGED (2026-08-07): mutual interest is necessary, not sufficient.
  IF NOT public.zyra_can_match(NEW.liker_id, NEW.liked_id) THEN RETURN NEW; END IF;

  IF NEW.liker_id < NEW.liked_id THEN a_id := NEW.liker_id; b_id := NEW.liked_id;
  ELSE                                a_id := NEW.liked_id; b_id := NEW.liker_id; END IF;

  IF EXISTS (SELECT 1 FROM matches WHERE seeker_a_id = a_id AND seeker_b_id = b_id) THEN
    RETURN NEW;
  END IF;

  INSERT INTO matches (seeker_a_id, seeker_b_id, status)
    VALUES (a_id, b_id, 'potential') RETURNING id INTO new_match_id;

  -- Created by matches_create_first_attempt (AFTER INSERT). Read it back
  -- rather than assuming the downstream BEFORE triggers will find it.
  SELECT a.id INTO new_attempt_id FROM journey_attempts a
   WHERE a.match_id = new_match_id ORDER BY a.attempt_number DESC LIMIT 1;
  IF new_attempt_id IS NULL THEN RAISE EXCEPTION 'no_attempt_created_for_match'; END IF;

  INSERT INTO conversations (match_id, attempt_id) VALUES (new_match_id, new_attempt_id);
  INSERT INTO timelines     (match_id, attempt_id) VALUES (new_match_id, new_attempt_id)
    RETURNING id INTO new_timeline_id;

  -- ADDED 2026-08-12: the origin of the story. The reciprocal like's
  -- created_at is by definition earlier than NEW's (it existed first).
  SELECT l.created_at INTO first_like FROM likes l
   WHERE l.liker_id = NEW.liked_id AND l.liked_id = NEW.liker_id
   ORDER BY l.created_at ASC LIMIT 1;
  INSERT INTO timeline_milestones (timeline_id, milestone_type, occurred_at)
    VALUES (new_timeline_id, 'liked', COALESCE(LEAST(first_like, NEW.created_at), NOW()));

  INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (new_timeline_id, 'match_created');

  SELECT first_name INTO a_name FROM profiles WHERE id = a_id;
  SELECT first_name INTO b_name FROM profiles WHERE id = b_id;
  PERFORM create_notification(a_id,'new_match','New Match', COALESCE(b_name,'Someone')||' matched with you.', new_match_id);
  PERFORM create_notification(b_id,'new_match','New Match', COALESCE(a_name,'Someone')||' matched with you.', new_match_id);
  RETURN NEW;
END; $$;


--
-- Name: create_notification(uuid, text, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_notification(p_user_id uuid, p_type text, p_title text, p_body text, p_related_match_id uuid) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select private.zyra_create_notification(p_user_id, p_type, p_title, p_body, p_related_match_id);
$$;


--
-- Name: delete_own_account(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_own_account() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_due_at timestamptz;
begin
  if v_me is null then raise exception 'Not signed in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  perform private.zyra_queue_photo_folder(v_me);
  v_due_at := clock_timestamp() + interval '24 hours';
  update public.photo_object_deletions d
    set account_delete_due_at = least(d.account_delete_due_at, v_due_at)
    where pg_catalog.split_part(d.path, '/', 1) = v_me::text and d.done_at is null;
  delete from auth.users where id = v_me;
end;
$$;


--
-- Name: end_journey(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.end_journey(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE m RECORD; caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;
  PERFORM public.zyra_end_match_internal(p_match_id, caller, NULL);
END; $$;


--
-- Name: end_journey(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.end_journey(p_match_id uuid, p_reason text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE m RECORD; caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;
  IF p_reason = 'no_response' THEN
    RAISE EXCEPTION 'reason_is_system_only'
      USING HINT='no_response is recorded by the system, not chosen by a person.';
  END IF;
  IF p_reason IS NOT NULL AND p_reason NOT IN
     ('not_compatible','circumstances_changed','marrying_elsewhere',
      'family_decision','safety_concern','prefer_not_to_say') THEN
    RAISE EXCEPTION 'unknown_end_reason: %', p_reason;
  END IF;
  -- safety_concern permitted: someone may feel unsafe without wanting to
  -- block. Step 0 conceals it from everyone but the person who raised it,
  -- and matches_no_note_on_safety_ending forbids a note. No new disclosure.
  PERFORM public.zyra_end_match_internal(p_match_id, caller, p_reason);
END; $$;


--
-- Name: wali_invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wali_invites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    token text DEFAULT upper(encode(extensions.gen_random_bytes(4), 'hex'::text)) NOT NULL,
    inviter_id uuid NOT NULL,
    inviter_role text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    accepted_at timestamp with time zone,
    accepted_by uuid,
    expires_at timestamp with time zone DEFAULT (now() + '14 days'::interval) NOT NULL,
    label text,
    relationship text,
    expiring_notified_at timestamp with time zone,
    seen_by uuid,
    seen_at timestamp with time zone,
    declined_by uuid,
    declined_at timestamp with time zone,
    source text DEFAULT 'legacy_code'::text NOT NULL,
    personal_code_id uuid,
    recipient_id uuid,
    request_expires_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    issued_by_guardian_invitation_rpc boolean DEFAULT false NOT NULL,
    CONSTRAINT wali_invites_declined_pair CHECK (((declined_by IS NULL) = (declined_at IS NULL))),
    CONSTRAINT wali_invites_guardian_invitation_duration CHECK (((NOT issued_by_guardian_invitation_rpc) OR ((source = 'legacy_code'::text) AND (inviter_role = 'seeker'::text) AND (expires_at = (created_at + '14 days'::interval))))),
    CONSTRAINT wali_invites_inviter_role_check CHECK ((inviter_role = ANY (ARRAY['seeker'::text, 'wali'::text]))),
    CONSTRAINT wali_invites_label_length CHECK (((label IS NULL) OR (char_length(label) <= 40))),
    CONSTRAINT wali_invites_personal_request_shape CHECK (((source <> 'personal_code'::text) OR ((personal_code_id IS NOT NULL) AND (recipient_id IS NOT NULL) AND (request_expires_at IS NOT NULL) AND (token IS NOT NULL)))),
    CONSTRAINT wali_invites_relationship_check CHECK (((relationship IS NULL) OR (relationship = ANY (ARRAY['father'::text, 'brother'::text, 'grandfather'::text, 'uncle'::text, 'legal_guardian'::text, 'family_representative'::text, 'other'::text])))),
    CONSTRAINT wali_invites_relationship_owner_check CHECK (((relationship IS NULL) OR ((source = 'legacy_code'::text) AND (inviter_role = 'wali'::text)) OR (source = 'personal_code'::text))),
    CONSTRAINT wali_invites_seen_pair CHECK (((seen_by IS NULL) = (seen_at IS NULL))),
    CONSTRAINT wali_invites_source_check CHECK ((source = ANY (ARRAY['legacy_code'::text, 'personal_code'::text]))),
    CONSTRAINT wali_invites_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text, 'revoked'::text, 'expired'::text, 'cancelled'::text])))
);


--
-- Name: COLUMN wali_invites.token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.token IS 'OWNERSHIP: row-scoped(inviter_id) — a live credential while unredeemed. Never export a usable token.';


--
-- Name: COLUMN wali_invites.inviter_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.inviter_id IS 'OWNERSHIP: row-scoped(inviter_id)';


--
-- Name: COLUMN wali_invites.inviter_role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.inviter_role IS 'OWNERSHIP: row-scoped(inviter_id)';


--
-- Name: COLUMN wali_invites.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.status IS 'OWNERSHIP: row-scoped(inviter_id)';


--
-- Name: COLUMN wali_invites.accepted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.accepted_at IS 'OWNERSHIP: joint(inviter_id, accepted_by)';


--
-- Name: COLUMN wali_invites.accepted_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.accepted_by IS 'OWNERSHIP: joint(inviter_id, accepted_by)';


--
-- Name: COLUMN wali_invites.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.expires_at IS 'OWNERSHIP: row-scoped(inviter_id)';


--
-- Name: COLUMN wali_invites.label; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.label IS 'OWNERSHIP: row-scoped(inviter_id) — the sender''s private note for who this code was intended for ("Dad", "Uncle Ibrahim"). Never shown to the recipient and never returned by preview_wali_invite. Not an identity claim: whoever redeems the code becomes the Guardian regardless.';


--
-- Name: COLUMN wali_invites.relationship; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.relationship IS 'OWNERSHIP: row-scoped(inviter_id) — the inviting Guardian''s statement about themselves ("I am her father"), carried onto wali_links.relationship when the Seeker accepts. Null for Seeker-sent invites, where the Guardian is asked at acceptance instead. Per LINK, not per account.';


--
-- Name: COLUMN wali_invites.expiring_notified_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.expiring_notified_at IS 'One-shot marker for the day-5 Guardian invitation reminder.';


--
-- Name: COLUMN wali_invites.seen_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.seen_by IS 'First authenticated bearer who previewed this manual invite code. Used only to send received/revoked lifecycle notifications; not proof that the sender intended the code for this person.';


--
-- Name: COLUMN wali_invites.recipient_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.recipient_id IS 'For source=personal_code, the authenticated requester. The code owner is inviter_id. A link is never created until the owner accepts.';


--
-- Name: COLUMN wali_invites.request_expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_invites.request_expires_at IS 'Stored deadline for an addressed personal-code request. New code requests use 14 days.';


--
-- Name: expire_wali_invite_if_due(public.wali_invites); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.expire_wali_invite_if_due(p_invite public.wali_invites) RETURNS text
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
declare
  v_label text;
  v_status text;
begin
  if p_invite.status = 'pending' and p_invite.expires_at < clock_timestamp() then
    update public.wali_invites
       set status = 'expired'
     where id = p_invite.id
       and status = 'pending'
       and expires_at < clock_timestamp()
     returning label into v_label;

    if found then
      perform private.zyra_create_notification(
        p_invite.inviter_id,
        'wali_invite_expired',
        'Guardian invitation expired',
        case when v_label is null
          then 'A Guardian invitation expired.'
          else v_label || '''s Guardian invitation expired.'
        end, null, null, p_invite.id, null);
      return 'expired';
    end if;

    -- Another transaction may have accepted/revoked/declined the row after
    -- the caller read it. Report the state that actually won, not expiry.
    select wi.status into v_status
      from public.wali_invites wi where wi.id = p_invite.id;
    return coalesce(v_status, p_invite.status);
  end if;
  return p_invite.status;
end;
$$;


--
-- Name: grant_zyra_one_credits(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.grant_zyra_one_credits() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  -- 'seeker_premium' IS ZYRA One. Not a typo.
  if new.plan_type = 'seeker_premium' and new.status = 'active' then
    insert into public.unlock_credits (user_id, tier, delta, reason, note)
    values (new.user_id, 'paid_plus_single', 3, 'zyra_one_included',
            'Included with ZYRA One')
    on conflict do nothing;
  end if;
  return new;
end $$;


--
-- Name: guardians_for_unlocked(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guardians_for_unlocked(p_target uuid) RETURNS TABLE(first_name text, gender text, location_text text, is_main boolean, relationship text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select p.first_name, p.gender, p.location_text,
         coalesce(w.is_main, false), w.relationship
  from public.wali_links w
  join public.profiles p on p.id = w.wali_id
  where w.seeker_id = p_target
    and w.status = 'active'
    and exists (
      select 1 from public.profile_unlocks u
      where u.unlocker_id = (select auth.uid())
        and u.unlocked_id = p_target
        and u.unlock_type = 'paid_plus_single'
    )
    and not public.zyra_block_exists(p_target)
  order by coalesce(w.is_main, false) desc, w.created_at;
$$;


--
-- Name: has_article9_consent(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_article9_consent() RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  select coalesce(
    (select c.granted
       from public.consents c
      where c.user_id = (select auth.uid())
        and c.consent_type = 'article9_special_category'
      order by c.recorded_at desc
      limit 1),
    false);
$$;


--
-- Name: notify_new_message(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_new_message() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE v_match_id UUID; v_a UUID; v_b UUID; v_recipient UUID; v_sender_name TEXT;
BEGIN
  SELECT m.id, m.seeker_a_id, m.seeker_b_id INTO v_match_id, v_a, v_b
  FROM conversations c
  JOIN journey_attempts ja ON ja.id = c.attempt_id
  JOIN matches m          ON m.id  = ja.match_id
  WHERE c.id = NEW.conversation_id;
  IF v_match_id IS NULL THEN RETURN NEW; END IF;
  v_recipient := CASE WHEN NEW.sender_id = v_a THEN v_b ELSE v_a END;
  SELECT first_name INTO v_sender_name FROM profiles WHERE id = NEW.sender_id;
  PERFORM create_notification(v_recipient,'new_message', COALESCE(v_sender_name,'New message'),
                              left(NEW.content,140), v_match_id);
  RETURN NEW;
END; $$;


--
-- Name: nudge_paused_journey(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nudge_paused_journey(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare m record; caller uuid := auth.uid(); v_name text;
begin
  if caller is null then raise exception 'not_signed_in'; end if;
  select * into m from matches where id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  if not found then raise exception 'match not found'; end if;
  if caller <> m.seeker_a_id and caller <> m.seeker_b_id then
    raise exception 'not a party to this match';
  end if;
  if m.status <> 'active' or m.suspended_by is null then
    raise exception 'journey_not_paused';
  end if;
  -- A holder has no use for a nudge — their button is Resume. EXTENDED
  -- 2026-08-15 (DR-ZYRA-170) to cover the second hold: with both hands
  -- holding there is nobody left to nudge.
  if caller is not distinct from m.suspended_by
     or caller is not distinct from m.also_paused_by then
    raise exception 'pauser_cannot_nudge';
  end if;
  -- ONE per episode. The client greys its button from the same flag, so
  -- reaching this is a race or a stale screen, not a normal path.
  if m.pause_nudged_at is not null then
    raise exception 'already_nudged'
      using hint = 'One nudge per pause — they already know you are ready.';
  end if;

  update matches set pause_nudged_at = now() where id = p_match_id;

  -- One notification to the PAUSER alone. No wali copy — Guardian-silent
  -- is part of the decision: a whisper, not a family event.
  select first_name into v_name from profiles where id = caller;
  perform create_notification(
    m.suspended_by, 'pause_nudge', 'Whenever you are ready',
    coalesce(v_name, 'They') || ' is ready to continue, whenever you are.',
    p_match_id);
end $$;


--
-- Name: open_family_review(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.open_family_review(p_match_id uuid, p_from_stage text, p_to_stage text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  v_attempt UUID;
  v_expected_to TEXT;
  existing_id UUID;
  new_id UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;

  -- ── LIFECYCLE, 2026-08-09 (audit 2.2). Same three tests zyra_advance_stage
  -- applies before it will move anything.
  IF m.status <> 'active' THEN
    RAISE EXCEPTION 'journey_not_active';
  END IF;
  IF m.suspended_by IS NOT NULL THEN
    RAISE EXCEPTION 'journey_paused';
  END IF;
  IF m.journey_stage IS DISTINCT FROM p_from_stage THEN
    RAISE EXCEPTION 'stage_moved'
      USING HINT = 'This Journey is no longer at that stage. Reload before continuing.';
  END IF;

  -- ── THE TRANSITION MUST BE ONE OF THE FOUR GATED ONES, and p_to_stage
  -- must be its real successor. Previously both were accepted verbatim.
  IF p_from_stage NOT IN ('phase_1','phase_2','phase_3','family_stage') THEN
    RAISE EXCEPTION 'not_a_gated_transition'
      USING HINT = 'This transition does not open a Family Review Period. '
                   'Call zyra_advance_stage() instead.';
  END IF;

  v_expected_to := CASE p_from_stage
                     WHEN 'phase_1'      THEN 'phase_2'
                     WHEN 'phase_2'      THEN 'phase_3'
                     WHEN 'phase_3'      THEN 'family_stage'
                     WHEN 'family_stage' THEN 'conversation'
                   END;

  IF p_to_stage IS DISTINCT FROM v_expected_to THEN
    RAISE EXCEPTION 'invalid_transition'
      USING HINT = format('A Family Review from %s can only lead to %s.',
                          p_from_stage, v_expected_to);
  END IF;

  -- Resolve the attempt this review belongs to. Same selection rule as
  -- zyra_set_attempt_from_match(), stated here because this function now
  -- writes attempt_id explicitly rather than leaving it to the trigger.
  SELECT a.id INTO v_attempt
  FROM journey_attempts a
  WHERE a.match_id = p_match_id
  ORDER BY (a.status = 'active') DESC, a.attempt_number DESC
  LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  -- Idempotency now keyed on the ATTEMPT, not the match. Identical today
  -- (one attempt per match); correct once a pair can have several.
  SELECT id INTO existing_id FROM journey_family_reviews
    WHERE attempt_id = v_attempt AND status = 'pending';
  IF existing_id IS NOT NULL THEN
    RETURN existing_id;
  END IF;

  INSERT INTO journey_family_reviews (match_id, attempt_id, from_stage, to_stage, deadline_at)
    VALUES (p_match_id, v_attempt, p_from_stage, p_to_stage, NOW() + INTERVAL '48 hours')
    RETURNING id INTO new_id;
  RETURN new_id;
END;
$$;


--
-- Name: preview_wali_invite(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.preview_wali_invite(p_token text) RETURNS TABLE(inviter_first_name text, inviter_role text, invite_status text, inviter_ward_count integer, seeker_plan text, basic_place_free boolean, needs_guardian_one boolean, expires_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_invite public.wali_invites%rowtype;
  v_status text;
  v_viewer uuid := auth.uid();
  v_viewer_role text;
  v_inviter_name text;
  v_inviter_role text;
  v_is_seeker_one boolean;
  v_place_free boolean;
  v_needs_one boolean;
  v_at timestamptz := clock_timestamp();
begin
  select wi.* into v_invite
  from public.wali_invites wi
  where wi.token = upper(trim(p_token))
    and wi.source = 'legacy_code';
  if not found then return; end if;

  v_status := public.expire_wali_invite_if_due(v_invite);
  select p.first_name, p.role into v_inviter_name, v_inviter_role
  from public.profiles p
  where p.id = v_invite.inviter_id;

  if v_status = 'pending'
     and v_viewer is not null
     and v_viewer <> v_invite.inviter_id then
    select p.role into v_viewer_role
    from public.profiles p
    where p.id = v_viewer;

    -- A new bearer can preview before a profile exists. The notification
    -- marker refers to a profile, so record it only when that row exists.
    if found then
      update public.wali_invites
         set seen_by = v_viewer,
             seen_at = clock_timestamp()
       where id = v_invite.id
         and status = 'pending'
         and seen_by is null;

      if found then
        perform private.zyra_create_notification(
          v_viewer,
          'wali_invite_received',
          'Guardian invitation received',
          coalesce(v_inviter_name, 'Someone') || ' sent you a Guardian invitation.', null, v_invite.inviter_id, v_invite.id, null);
      end if;
    end if;

    if v_invite.inviter_role = 'seeker' and v_inviter_role = 'seeker'
       and (v_viewer_role is null or v_viewer_role = 'wali') then
      v_is_seeker_one := public.zyra_has_paid_role(v_invite.inviter_id, 'seeker', v_at);
      if v_is_seeker_one then
        v_place_free := true;
      else
        select capacity.basic_place_free into v_place_free
        from private.zyra_guardian_invite_capacity(v_invite.inviter_id, null, v_at) capacity;
      end if;
      v_needs_one := not v_place_free
        and not public.zyra_has_paid_role(v_viewer, 'guardian', v_at);
    end if;
  end if;

  return query
  select v_inviter_name,
         v_invite.inviter_role,
         v_status,
         (select count(distinct wl.seeker_id)::integer
          from public.wali_links wl
          where wl.wali_id = v_invite.inviter_id and wl.status = 'active'),
         case v_is_seeker_one when true then 'one' when false then 'basic' end,
         v_place_free,
         v_needs_one,
         v_invite.expires_at;
end;
$$;


--
-- Name: promote_journey_to_active(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.promote_journey_to_active(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE m RECORD; caller UUID := auth.uid(); v_attempt UUID; v_party UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status <> 'potential' THEN
    RAISE EXCEPTION 'match is not in potential state (status=%)', m.status;
  END IF;

  -- UNCHANGED (2026-08-07): re-checked at promotion, not merely at
  -- creation — a Guardian link or a block may have appeared in between.
  IF NOT public.zyra_can_match(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_match'
      USING HINT = 'Something has changed since this match was made — a '
                   'Guardian relationship or a block now exists between you.';
  END IF;

  -- UNCHANGED in role, and kept deliberately even though the constraint
  -- trigger backstops it: this produces a clear, actionable error before
  -- the trigger fires. The trigger is the race-proof guarantee (audit R7:
  -- SELECT INTO takes no row lock); this is the good message.
  -- 2026-08-12 (later the same day as pause-frees-slot): per-party,
  -- per-plan — Basic 1 / One 3, and paused rows never count.
  FOREACH v_party IN ARRAY ARRAY[m.seeker_a_id, m.seeker_b_id] LOOP
    IF zyra_active_journey_count(v_party, p_match_id) >= zyra_active_journey_cap(v_party) THEN
      RAISE EXCEPTION 'one_active_journey_limit'
        USING HINT = CASE WHEN v_party = caller
          THEN 'You are at your plan''s Active Journey limit. End or pause one before starting another.'
          ELSE 'The other person is at their Active Journey limit right now.'
        END;
    END IF;
  END LOOP;

  -- SALAM FIRST (DR-ZYRA-183): a Journey begins with the greeting.
  UPDATE matches SET status = 'active', journey_stage = 'salam_exchange'
   WHERE id = p_match_id;

  -- NEW. The omission that gated steps 4, 6 and 7.
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status <> 'ended') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  UPDATE journey_attempts
     SET status        = 'active',
         journey_stage = 'salam_exchange',
         started_at    = COALESCE(started_at, NOW())
   WHERE id = v_attempt;
END; $$;


--
-- Name: reopen_family_review(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reopen_family_review(p_review_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform private.zyra_lock_active_family_review(p_review_id, 'paused');
  delete from public.journey_family_review_responses where review_id = p_review_id;
  update public.journey_family_reviews
  set status = 'pending', opened_at = now(), deadline_at = now() + interval '48 hours', resolved_at = null
  where id = p_review_id;
end;
$$;


--
-- Name: request_new_journey(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.request_new_journey(p_match_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_match public.matches%rowtype;
  v_other uuid;
  v_request uuid;
  v_name text;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  select * into v_match from public.matches
  where id = p_match_id and seeker_a_id is not null and seeker_b_id is not null
  for update;
  if not found then raise exception 'match_not_found'; end if;
  if v_caller is distinct from v_match.seeker_a_id
     and v_caller is distinct from v_match.seeker_b_id then
    raise exception 'not_a_party';
  end if;
  v_other := case when v_caller = v_match.seeker_a_id
    then v_match.seeker_b_id else v_match.seeker_a_id end;

  if v_match.status <> 'ended' then raise exception 'journey_not_ended'; end if;
  if v_match.ended_at is null
     or now() < v_match.ended_at + interval '24 hours' then
    raise exception 'cooling_period_active';
  end if;
  if not public.zyra_has_paid_role(v_caller, 'seeker') then
    raise exception 'return_membership_required';
  end if;
  if public.zyra_active_journey_cap(v_other) = 0 then
    raise exception 'not_available';
  end if;
  if not exists (
    select 1 from (
      select match.id
      from public.matches match
      where match.status = 'ended'
        and v_caller in (match.seeker_a_id, match.seeker_b_id)
      order by match.ended_at desc nulls last, match.id desc
      limit 5
    ) recent where recent.id = p_match_id
  ) then
    raise exception 'return_window_exceeded';
  end if;
  if public.zyra_block_exists(v_other)
     or not public.zyra_can_match(v_caller, v_other)
     or public.zyra_hold_blocks(v_caller, v_other) then
    raise exception 'not_available';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(least(v_match.seeker_a_id, v_match.seeker_b_id)::text, 0)
  );
  perform pg_advisory_xact_lock(
    hashtextextended(greatest(v_match.seeker_a_id, v_match.seeker_b_id)::text, 0)
  );
  if public.zyra_active_journey_count(v_match.seeker_a_id, v_match.id)
       >= public.zyra_active_journey_cap(v_match.seeker_a_id)
     or public.zyra_active_journey_count(v_match.seeker_b_id, v_match.id)
       >= public.zyra_active_journey_cap(v_match.seeker_b_id) then
    raise exception 'journey_capacity_unavailable';
  end if;
  if exists (
    select 1 from public.journey_requests request
    where request.match_id = p_match_id and request.status = 'pending'
  ) then
    raise exception 'request_already_pending';
  end if;

  insert into public.journey_requests (
    match_id, requested_by, requested_to, expires_at
  ) values (
    p_match_id, v_caller, v_other, now() + interval '30 days'
  ) returning id into v_request;

  select profile.first_name into v_name
  from public.profiles profile where profile.id = v_caller;
  perform public.create_notification(
    v_other,
    'journey_request',
    'A new Journey',
    coalesce(v_name, 'Someone') ||
      ' would like to begin a new Journey with you.',
    p_match_id
  );
  return v_request;
end;
$$;


--
-- Name: resolve_family_review_if_due(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resolve_family_review_if_due(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  r RECORD;
  caller UUID := auth.uid();
  m RECORD;
  v_attempt UUID;
  is_party BOOLEAN;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN RETURN; END IF;

  -- UNCHANGED authorisation: a party, or a Main Guardian of either side.
  is_party := caller IS NOT NULL AND (caller = m.seeker_a_id OR caller = m.seeker_b_id);
  IF NOT is_party AND NOT EXISTS (
    SELECT 1 FROM wali_links WHERE wali_id = caller AND status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)
  ) THEN
    RETURN;
  END IF;

  -- ── LIFECYCLE, 2026-08-09 (audit 2.2). A timer must not carry an ended
  -- or paused Journey forward. Paused simply defers: the next call after
  -- a resume will resolve it.
  IF m.status <> 'active' OR m.suspended_by IS NOT NULL THEN RETURN; END IF;

  SELECT a.id INTO v_attempt
  FROM journey_attempts a
  WHERE a.match_id = p_match_id
  ORDER BY (a.status = 'active') DESC, a.attempt_number DESC
  LIMIT 1;
  IF v_attempt IS NULL THEN RETURN; END IF;

  SELECT * INTO r FROM journey_family_reviews
    WHERE attempt_id = v_attempt AND status = 'pending' AND deadline_at <= NOW();
  IF NOT FOUND THEN RETURN; END IF;

  -- ── STALENESS GUARD, 2026-08-09 (audit 2.2). A review is a decision
  -- about one specific moment in the Journey. If the stage has moved since
  -- it was opened, the premise is gone — do nothing and leave the row for
  -- a human, rather than teleporting the Journey to a stale destination.
  IF m.journey_stage IS DISTINCT FROM r.from_stage THEN RETURN; END IF;

  UPDATE journey_family_reviews SET status = 'continued', resolved_at = NOW() WHERE id = r.id;
  UPDATE matches          SET journey_stage = r.to_stage WHERE id = p_match_id;
  UPDATE journey_attempts SET journey_stage = r.to_stage WHERE id = v_attempt;
  IF r.to_stage = 'conversation' THEN
    UPDATE conversations SET status = 'active' WHERE attempt_id = v_attempt;
  END IF;
END;
$$;


--
-- Name: respond_to_journey_request(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.respond_to_journey_request(p_request_id uuid, p_decision text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_request public.journey_requests%rowtype;
  v_match public.matches%rowtype;
  v_attempt uuid;
  v_attempt_number integer;
  v_name text;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  if p_decision not in ('accept', 'decline', 'decline_never') then
    raise exception 'unknown_decision';
  end if;
  select * into v_request
  from public.journey_requests request
  where request.id = p_request_id
  for update;
  if not found then raise exception 'request_not_found'; end if;
  if v_request.requested_to <> v_caller then
    raise exception 'not_yours_to_answer';
  end if;
  if v_request.status <> 'pending' then raise exception 'already_answered'; end if;
  if v_request.expires_at <= now() then raise exception 'request_expired'; end if;

  if public.zyra_active_journey_cap(v_caller) = 0 then
    update public.journey_requests
    set status = 'recipient_unavailable',
        responded_at = now(),
        closed_reason = 'recipient_unavailable'
    where id = p_request_id;
    perform public.create_notification(
      v_request.requested_by,
      'journey_request_declined',
      'Journey request',
      'This person is not available to reconnect right now.',
      v_request.match_id
    );
    return 'recipient_unavailable';
  end if;

  select * into v_match
  from public.matches match
  where match.id = v_request.match_id
  for update;
  if not found or v_match.status <> 'ended' then
    raise exception 'journey_not_ended';
  end if;

  if p_decision in ('decline', 'decline_never') then
    update public.journey_requests
    set status = 'declined', responded_at = now(), closed_reason = 'declined'
    where id = p_request_id;
    insert into public.protection_holds (
      match_id, restricted_id, protected_id, hold_type, appealable, expires_at
    ) values (
      v_request.match_id,
      v_request.requested_by,
      v_caller,
      case when p_decision = 'decline_never'
        then 'decline_permanent' else 'decline_cooldown' end,
      true,
      case when p_decision = 'decline_never'
        then null else now() + interval '30 days' end
    );
    perform public.create_notification(
      v_request.requested_by,
      'journey_request_declined',
      'Journey request',
      'Your request to begin a new Journey was not taken up.',
      v_request.match_id
    );
    return 'declined';
  end if;

  if not public.zyra_has_paid_role(v_request.requested_by, 'seeker')
     or public.zyra_block_exists(v_request.requested_by)
     or not public.zyra_can_match(v_caller, v_request.requested_by)
     or public.zyra_hold_blocks(v_caller, v_request.requested_by) then
    raise exception 'not_available';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(least(v_match.seeker_a_id, v_match.seeker_b_id)::text, 0)
  );
  perform pg_advisory_xact_lock(
    hashtextextended(greatest(v_match.seeker_a_id, v_match.seeker_b_id)::text, 0)
  );
  if public.zyra_active_journey_count(v_match.seeker_a_id, v_match.id)
       >= public.zyra_active_journey_cap(v_match.seeker_a_id)
     or public.zyra_active_journey_count(v_match.seeker_b_id, v_match.id)
       >= public.zyra_active_journey_cap(v_match.seeker_b_id) then
    raise exception 'journey_capacity_unavailable';
  end if;

  select coalesce(max(attempt.attempt_number), 0) + 1
  into v_attempt_number
  from public.journey_attempts attempt
  where attempt.match_id = v_request.match_id;

  insert into public.journey_attempts (
    match_id, attempt_number, status, journey_stage, started_at
  ) values (
    v_request.match_id,
    v_attempt_number,
    'active',
    'salam_exchange',
    now()
  ) returning id into v_attempt;

  -- matches is the permanent pair envelope. The prior Journey remains an
  -- immutable ended journey_attempt; this update projects only the new current
  -- attempt so legacy list code can find it.
  update public.matches
  set status = 'active',
      journey_stage = 'salam_exchange',
      ended_at = null,
      ended_by = null,
      end_reason = null,
      end_note = null
  where id = v_request.match_id;

  insert into public.conversations(match_id, attempt_id, status)
  values (v_request.match_id, v_attempt, 'active');
  insert into public.timelines(match_id, attempt_id)
  values (v_request.match_id, v_attempt)
  on conflict (attempt_id) do nothing;

  update public.journey_requests
  set status = 'accepted', responded_at = now(), attempt_id = v_attempt,
      closed_reason = 'accepted'
  where id = p_request_id;

  select profile.first_name into v_name
  from public.profiles profile where profile.id = v_caller;
  perform public.create_notification(
    v_request.requested_by,
    'journey_request_accepted',
    'A new Journey',
    coalesce(v_name, 'They') || ' accepted. Your new Journey has begun.',
    v_request.match_id
  );
  return 'accepted';
end;
$$;


--
-- Name: restart_journey(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restart_journey(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
BEGIN
  -- Identity checks still run first, so the error a caller receives never
  -- confirms the existence of a match they are not part of.
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match not found';
  END IF;

  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;

  -- OA-ZYRA-154. A Journey may not be reopened by one person.
  RAISE EXCEPTION 'restart_requires_mutual_consent'
    USING HINT = 'Starting again needs both people to agree. This will be '
                 'available as Request New Journey.';

  -- ---------------------------------------------------------------------
  -- Preserved for OA-ZYRA-159, which will run this AFTER the other party
  -- accepts. Deliberately already stripped of every destructive statement,
  -- so nobody reinstating it can reinstate the defect by accident:
  --
  --   • no DELETEs — V3 item 13, all Journey history is preserved
  --   • ended_at is NOT cleared — the prior ending stays on the record
  --   • conversations goes to 'active', not 'closed'
  --   • 2026-08-12: the slot check below already carries suspended_by IS
  --     NULL — pause frees the slot; do not reinstate it without that.
  --
  -- IF m.status <> 'ended' THEN RAISE EXCEPTION 'match is not ended'; END IF;
  -- IF EXISTS (SELECT 1 FROM matches WHERE status = 'active' AND suspended_by IS NULL
  --            AND id <> p_match_id
  --            AND (seeker_a_id IN (m.seeker_a_id, m.seeker_b_id)
  --              OR seeker_b_id IN (m.seeker_a_id, m.seeker_b_id)))
  -- THEN RAISE EXCEPTION 'one_active_journey_limit'; END IF;
  --
  -- UPDATE matches SET status = 'active', journey_stage = 'compatibility_reveal'
  --  WHERE id = p_match_id;
  -- UPDATE conversations SET status = 'active', closed_at = NULL
  --  WHERE match_id = p_match_id;
  -- ---------------------------------------------------------------------
END;
$$;


--
-- Name: FUNCTION restart_journey(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.restart_journey(p_match_id uuid) IS 'OA-ZYRA-154: refuses. A Journey cannot be reopened by one party. Replaced by Request New Journey (OA-ZYRA-159). Previously deleted six tables of history and cleared ended_at.';


--
-- Name: resume_journey(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resume_journey(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE m RECORD; caller UUID := auth.uid(); other_id UUID; v_attempt UUID; v_name TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;
  IF m.suspended_by IS NULL THEN RAISE EXCEPTION 'journey_not_paused'; END IF;

  -- DR-ZYRA-170: you lift only YOUR OWN hold. This replaces "only the
  -- suspending Seeker may resume" — under shared holds nobody resumes
  -- anybody else, and nobody asks.
  IF caller IS DISTINCT FROM m.suspended_by
     AND caller IS DISTINCT FROM m.also_paused_by THEN
    RAISE EXCEPTION 'no_hold_to_lift'
      USING HINT = 'Only your own pause is yours to lift.';
  END IF;

  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;

  -- SECONDARY LIFT — the Journey stays paused on the primary hold. Your
  -- lift IS your standing "I'm ready": pause_nudged_at is set (only one
  -- non-holder can exist, so the flag is unambiguous) and the existing
  -- pause_nudge notification carries the word. No Timeline event — the
  -- Journey's own state never moved.
  IF caller IS NOT DISTINCT FROM m.also_paused_by THEN
    UPDATE matches SET also_paused_by=NULL, also_paused_at=NULL,
                       pause_nudged_at=NOW() WHERE id=p_match_id;
    UPDATE journey_attempts SET also_paused_by=NULL, also_paused_at=NULL
     WHERE v_attempt IS NOT NULL AND id=v_attempt;
    PERFORM create_notification(
      m.suspended_by, 'pause_nudge', 'Whenever you are ready',
      coalesce(v_name, 'They') || ' is ready to continue, whenever you are.',
      p_match_id);
    RETURN;
  END IF;

  -- caller holds the PRIMARY from here.
  IF m.also_paused_by IS NOT NULL THEN
    -- PROMOTION — their hold becomes the (only) hold, keeping THEIR
    -- original hold time; the Journey stays paused. suspended_by never
    -- touches NULL, so the milestone trigger stays silent — verified
    -- against its live body. The lifter's ready signal stands the same
    -- way a secondary lift's does.
    UPDATE matches SET suspended_by = m.also_paused_by,
                       suspended_at = coalesce(m.also_paused_at, NOW()),
                       also_paused_by = NULL, also_paused_at = NULL,
                       pause_nudged_at = NOW()
     WHERE id = p_match_id;
    UPDATE journey_attempts SET paused_by = m.also_paused_by,
                       paused_at = coalesce(m.also_paused_at, NOW()),
                       also_paused_by = NULL, also_paused_at = NULL
     WHERE v_attempt IS NOT NULL AND id = v_attempt;
    PERFORM create_notification(
      m.also_paused_by, 'pause_nudge', 'Whenever you are ready',
      coalesce(v_name, 'They') || ' is ready to continue, whenever you are.',
      p_match_id);
    RETURN;
  END IF;

  -- FINAL LIFT — the Journey goes active. Eligibility and slot checks
  -- unchanged from the 2026-08-08/12 rulings (OA-ZYRA-174; pause frees
  -- the slot, plan-aware caps).
  IF NOT public.zyra_can_continue_journey(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_continue'
      USING HINT='This Journey cannot resume: one of you has blocked the '
                 'other, or one of you is now the other''s Guardian.';
  END IF;
  IF zyra_active_journey_count(caller, p_match_id) >= zyra_active_journey_cap(caller) THEN
    RAISE EXCEPTION 'self_in_active_journey'
      USING HINT='You are at your plan''s Active Journey limit. Pause or '
                 'end one first — then resume this one.';
  END IF;
  IF zyra_active_journey_count(other_id, p_match_id) >= zyra_active_journey_cap(other_id) THEN
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT='This Journey stays paused for now. You can wait, or end it '
                 'yourself if you would rather.';
  END IF;

  -- pause_nudged_at cleared: the flag is per-episode and the episode is
  -- over (DR-ZYRA-142).
  UPDATE matches SET suspended_by = NULL, suspended_at = NULL,
                     pause_nudged_at = NULL WHERE id = p_match_id;
  UPDATE journey_attempts SET paused_by = NULL, paused_at = NULL
   WHERE v_attempt IS NOT NULL AND id = v_attempt;
  UPDATE conversations SET status='active'
   WHERE v_attempt IS NOT NULL AND attempt_id = v_attempt AND status='paused';

  -- The silent re-activation ends here: the other person is TOLD the
  -- Journey is active again (they used to just find it moved).
  PERFORM create_notification(
    other_id, 'journey_continued', 'Your Journey continues',
    coalesce(v_name, 'They') || ' has lifted their pause — your Journey together is active again.',
    p_match_id);
END; $$;


--
-- Name: FUNCTION resume_journey(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.resume_journey(p_match_id uuid) IS 'Clears the pause on both rows. Still reads Active-Journey state from matches, authoritative until step 7.';


--
-- Name: score_candidates(uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.score_candidates(p_candidate_ids uuid[]) RETURNS TABLE(candidate_id uuid, score numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_me UUID := auth.uid();
  v_my_prefs JSONB; v_my_hard JSONB; v_candidate_id UUID; v_ch3 JSONB;
  v_pref_rec RECORD; v_value TEXT; v_light TEXT;
  v_total NUMERIC; v_max NUMERIC; v_excluded BOOLEAN;
  v_multi_total NUMERIC; v_multi_count INT;
  v_my_ch2 JSONB; v_cand RECORD; v_block JSONB; v_pref_arr JSONB;
  v_third_sect_key text; v_sect_key text;
  v_ch2_weight INT := 1;   -- STILL OPEN — OA-ZYRA-193(e), now answerable.
BEGIN
  IF v_me IS NULL THEN RETURN; END IF;
  IF p_candidate_ids IS NULL OR array_length(p_candidate_ids, 1) IS NULL THEN RETURN; END IF;

  SELECT oa.ch4_preferences, oa.ch4_hard_requirements INTO v_my_prefs, v_my_hard
    FROM onboarding_answers oa WHERE oa.user_id = v_me;
  SELECT sd.preferences, private.zyra_current_sect_third_key(sd.sect, sd.sect_other)
    INTO v_my_ch2, v_third_sect_key
    FROM seeker_details sd WHERE sd.user_id = v_me;

  v_my_prefs := COALESCE(v_my_prefs, '{}'::jsonb);
  v_my_ch2   := COALESCE(v_my_ch2,   '{}'::jsonb);
  v_my_hard  := COALESCE(v_my_hard,  '{}'::jsonb);

  IF v_my_prefs = '{}'::jsonb AND v_my_ch2 = '{}'::jsonb AND v_my_hard = '{}'::jsonb THEN
    FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
      CONTINUE WHEN NOT public.zyra_can_view_profile(v_candidate_id);
      candidate_id := v_candidate_id; score := NULL; RETURN NEXT;
    END LOOP;
    RETURN;
  END IF;

  FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
    CONTINUE WHEN NOT public.zyra_can_view_profile(v_candidate_id);

    SELECT oa.ch3_answers INTO v_ch3 FROM onboarding_answers oa WHERE oa.user_id = v_candidate_id;
    v_ch3 := COALESCE(v_ch3, '{}'::jsonb);
    v_total := 0; v_max := 0; v_excluded := FALSE;

    FOR v_pref_rec IN SELECT * FROM jsonb_each(v_my_hard) LOOP
      DECLARE v_answer JSONB := v_ch3 -> v_pref_rec.key;
      BEGIN
        CONTINUE WHEN v_answer IS NULL OR jsonb_typeof(v_answer) = 'null';
        IF jsonb_typeof(v_answer) = 'array' THEN
          IF EXISTS (SELECT 1 FROM jsonb_array_elements_text(v_answer) t
                      WHERE v_pref_rec.value ? t.value) THEN v_excluded := TRUE; END IF;
        ELSE
          IF v_pref_rec.value ? (v_answer #>> '{}') THEN v_excluded := TRUE; END IF;
        END IF;
      END;
      EXIT WHEN v_excluded;
    END LOOP;
    IF v_excluded THEN CONTINUE; END IF;

    FOR v_pref_rec IN SELECT * FROM jsonb_each(v_my_prefs) LOOP
      DECLARE
        v_prefs_for_question JSONB := v_pref_rec.value;
        v_answer JSONB := v_ch3 -> v_pref_rec.key;
      BEGIN
        IF v_answer IS NULL OR jsonb_typeof(v_answer) = 'null' THEN CONTINUE; END IF;
        IF jsonb_typeof(v_answer) = 'array' THEN
          v_multi_total := 0;
          v_multi_count := 0;
          FOR v_value IN SELECT jsonb_array_elements_text(v_answer) LOOP
            v_light := v_prefs_for_question ->> v_value;
            IF v_light IS NULL THEN CONTINUE; END IF;
            v_multi_total := v_multi_total + zyra_light_weight(v_light);
            v_multi_count := v_multi_count + 1;
          END LOOP;
          IF v_multi_count > 0 THEN
            v_max := v_max + 1;
            v_total := v_total + (v_multi_total / v_multi_count);
          END IF;
        ELSE
          v_value := v_answer #>> '{}';
          v_light := v_prefs_for_question ->> v_value;
          IF v_light IS NOT NULL THEN
            v_max := v_max + 1; v_total := v_total + zyra_light_weight(v_light);
          END IF;
        END IF;
      END;
    END LOOP;

    IF v_my_ch2 <> '{}'::jsonb THEN
      SELECT sd.sect, sd.revert_status, sd.country_of_birth,
             sd.nationality, sd.ethnicity, sd.languages
        INTO v_cand FROM seeker_details sd WHERE sd.user_id = v_candidate_id;

      IF FOUND THEN
        v_block := v_my_ch2 -> 'sect';
        v_sect_key := private.zyra_compatibility_sect_key(v_cand.sect, v_third_sect_key);
        IF v_block IS NOT NULL AND v_sect_key IS NOT NULL THEN
          IF (v_block -> 'hard_requirement') ? v_sect_key THEN
            v_excluded := TRUE;
          ELSE
            v_light := v_block -> 'matrix' ->> v_sect_key;
            -- Keep the existing Browse half-weight for a confirmed current Amber.
            IF v_light = 'amber' AND EXISTS (
              SELECT 1 FROM public.preference_light_confirmations c
              WHERE c.user_id = v_me
                AND c.question_id IN ('sect', 'ch2.sect.matrix')
                AND c.option_value = v_sect_key
                AND c.light = 'amber' AND c.capture_version = 'v1'
            ) THEN
              v_light := 'yellow';
            END IF;
            IF v_light IS NOT NULL THEN
              v_max   := v_max   + v_ch2_weight;
              v_total := v_total + zyra_light_weight(v_light) * v_ch2_weight;
            END IF;
          END IF;
        END IF;

        IF NOT v_excluded AND COALESCE(v_cand.revert_status, FALSE) THEN
          v_light := v_my_ch2 -> 'revert' ->> 'flexibility';
          IF v_light IS NOT NULL THEN
            v_max   := v_max   + v_ch2_weight;
            v_total := v_total + zyra_light_weight(v_light) * v_ch2_weight;
          END IF;
        END IF;

        IF NOT v_excluded THEN
          FOR v_pref_rec IN
            SELECT * FROM (VALUES
              ('country_of_birth', v_cand.country_of_birth),
              ('nationality',      v_cand.nationality),
              ('ethnicity',        v_cand.ethnicity)
            ) AS t(key, cand_value)
          LOOP
            v_block := v_my_ch2 -> v_pref_rec.key;
            CONTINUE WHEN v_block IS NULL
                       OR COALESCE((v_block ->> 'skipped')::boolean, FALSE)
                       OR v_pref_rec.cand_value IS NULL;
            v_pref_arr := v_block -> 'preferred';
            IF v_pref_arr IS NULL OR jsonb_array_length(v_pref_arr) = 0 THEN CONTINUE; END IF;
            IF v_pref_arr ? v_pref_rec.cand_value THEN v_light := 'green';
            ELSE v_light := v_block ->> 'flexibility'; END IF;
            IF v_light IS NOT NULL THEN
              v_max   := v_max   + v_ch2_weight;
              v_total := v_total + zyra_light_weight(v_light) * v_ch2_weight;
            END IF;
          END LOOP;

          v_block := v_my_ch2 -> 'languages';
          IF v_block IS NOT NULL
             AND NOT COALESCE((v_block ->> 'skipped')::boolean, FALSE)
             AND v_cand.languages IS NOT NULL
             AND array_length(v_cand.languages, 1) > 0 THEN
            SELECT jsonb_agg(p.value) INTO v_pref_arr
              FROM jsonb_array_elements_text(COALESCE(v_block -> 'preferred', '[]'::jsonb)) p
             WHERE p.value <> 'en';
            IF v_pref_arr IS NOT NULL AND jsonb_array_length(v_pref_arr) > 0 THEN
              IF EXISTS (SELECT 1 FROM jsonb_array_elements_text(v_pref_arr) p
                          WHERE p.value = ANY (v_cand.languages)) THEN v_light := 'green';
              ELSE v_light := v_block ->> 'flexibility'; END IF;
              IF v_light IS NOT NULL THEN
                v_max   := v_max   + v_ch2_weight;
                v_total := v_total + zyra_light_weight(v_light) * v_ch2_weight;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;

    IF v_excluded THEN CONTINUE; END IF;

    candidate_id := v_candidate_id;
    IF v_max = 0 THEN score := NULL;
    ELSE score := round(LEAST(100, GREATEST(0, (v_total / v_max) * 100)), 1);
    END IF;
    RETURN NEXT;
  END LOOP;
END;
$$;


--
-- Name: FUNCTION score_candidates(p_candidate_ids uuid[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.score_candidates(p_candidate_ids uuid[]) IS 'Caller-scoped compatibility scorer. Multi-select questions average selected-option lights and contribute one denominator unit (OA-ZYRA-228 option a).';


--
-- Name: seeker_details_for_unlocked(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seeker_details_for_unlocked(p_target uuid) RETURNS TABLE(user_id uuid, sect text, sect_other text, revert_status boolean, country_of_birth text, nationality text, ethnicity text, languages text[])
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select d.user_id, d.sect, d.sect_other, d.revert_status,
         d.country_of_birth, d.nationality, d.ethnicity, d.languages
  from public.seeker_details d
  where d.user_id = p_target
    and exists (
      select 1 from public.profile_unlocks u
      where u.unlocker_id = (select auth.uid())
        and u.unlocked_id = p_target
    )
    -- A block overrides a past purchase, in either direction.
    and not public.zyra_block_exists(p_target);
$$;


--
-- Name: suspend_journey(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.suspend_journey(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  m RECORD; caller UUID := auth.uid(); caller_plan TEXT; v_attempt UUID;
  v_cap INT; v_held INT; v_other UUID; v_name TEXT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;

  -- Idempotent for a hand already holding — a stale screen's second tap
  -- is not an error.
  IF caller IS NOT DISTINCT FROM m.suspended_by
     OR caller IS NOT DISTINCT FROM m.also_paused_by THEN
    RETURN;
  END IF;

  -- DR-ZYRA-170: the cap counts holds you currently HOLD, either column.
  SELECT plan_type INTO caller_plan FROM subscriptions WHERE user_id=caller AND status='active';
  v_cap := CASE WHEN caller_plan = 'seeker_premium' THEN 10 ELSE 5 END;
  SELECT COUNT(*) INTO v_held FROM matches
   WHERE status = 'active' AND (suspended_by = caller OR also_paused_by = caller)
     AND id <> p_match_id;
  IF v_held >= v_cap THEN
    RAISE EXCEPTION 'paused_limit_reached'
      USING HINT = 'Your plan holds up to ' || v_cap || ' paused Journeys.';
  END IF;

  v_other := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  SELECT first_name INTO v_name FROM profiles WHERE id = caller;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;

  IF m.suspended_by IS NULL THEN
    -- FIRST HOLD — the pre-existing behaviour, plus the notification the
    -- other person never used to get. pause_nudged_at cleared: a NEW
    -- pause is a NEW episode (DR-ZYRA-142).
    UPDATE matches SET suspended_by=caller, suspended_at=NOW(),
                       pause_nudged_at=NULL WHERE id=p_match_id;
    UPDATE journey_attempts SET paused_by=caller, paused_at=NOW()
     WHERE v_attempt IS NOT NULL AND id=v_attempt;
    UPDATE conversations SET status='paused'
     WHERE v_attempt IS NOT NULL AND attempt_id=v_attempt;
    PERFORM create_notification(
      v_other, 'journey_paused', 'A pause, not an ending',
      coalesce(v_name, 'They') || ' has paused your Journey. Everything you built together is kept.',
      p_match_id);
  ELSE
    -- MIRROR — the other party rests too. Journey-level state is
    -- unchanged (still paused), so the milestone trigger correctly
    -- writes nothing: the Timeline pair stays one 'paused', nameless.
    UPDATE matches SET also_paused_by=caller, also_paused_at=NOW()
     WHERE id=p_match_id;
    UPDATE journey_attempts SET also_paused_by=caller, also_paused_at=NOW()
     WHERE v_attempt IS NOT NULL AND id=v_attempt;
    PERFORM create_notification(
      v_other, 'journey_also_paused', 'Resting together',
      coalesce(v_name, 'They') || ' has also paused. Your Journey rests until you both continue.',
      p_match_id);
  END IF;
END; $$;


--
-- Name: FUNCTION suspend_journey(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.suspend_journey(p_match_id uuid) IS 'Pause recorded on BOTH matches.suspended_by and journey_attempts.paused_by. Since 2026-08-11 both plans may pause: cap 5 (Basic) / 10 (ZYRA One) counted over pauses the caller initiated; raises paused_limit_reached at the cap. suspension_requires_one is retired.';


--
-- Name: touch_seeker_details(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_seeker_details() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
begin
  new.updated_at := now();
  return new;
end $$;


--
-- Name: unlock_balance(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.unlock_balance(p_tier text DEFAULT NULL::text) RETURNS TABLE(tier text, balance integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select c.tier, coalesce(sum(c.delta), 0)::int
  from public.unlock_credits c
  where c.user_id = (select auth.uid())
    and (p_tier is null or c.tier = p_tier)
  group by c.tier;
$$;


--
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: wali_has_wali_one(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.wali_has_wali_one() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  caller UUID := auth.uid();
BEGIN
  IF caller IS NULL THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1 FROM subscriptions
    WHERE user_id = caller AND plan_type = 'wali_premium' AND status = 'active'
  ) THEN
    RETURN true;
  END IF;

  IF EXISTS (
    SELECT 1 FROM wali_links wl
    JOIN subscriptions s ON s.user_id = wl.seeker_id
    WHERE wl.wali_id = caller AND wl.status = 'active'
      AND s.plan_type = 'seeker_premium' AND s.status = 'active'
  ) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;


--
-- Name: wali_review_decision(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.wali_review_decision(p_review_id uuid, p_decision text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_review public.journey_family_reviews%rowtype;
  v_expected_count integer;
  v_continued_count integer;
begin
  if p_decision not in ('continue','pause') then raise exception 'invalid decision'; end if;
  v_review := private.zyra_lock_active_family_review(p_review_id, 'pending');
  insert into public.journey_family_review_responses (review_id, wali_id, decision)
  values (p_review_id, (select auth.uid()), p_decision)
  on conflict (review_id, wali_id) do update set decision = excluded.decision, responded_at = now();

  if p_decision = 'pause' then
    update public.journey_family_reviews set status = 'paused', resolved_at = now()
    where id = p_review_id;
    return;
  end if;

  select count(distinct link.wali_id) into v_expected_count
  from public.matches match
  join public.wali_links link on link.seeker_id in (match.seeker_a_id, match.seeker_b_id)
  where match.id = v_review.match_id and link.status = 'active' and link.is_main;

  select count(*) into v_continued_count from public.journey_family_review_responses
  where review_id = p_review_id and decision = 'continue';
  if v_expected_count >= 1 and v_continued_count >= v_expected_count then
    update public.journey_family_reviews set status = 'continued', resolved_at = now()
    where id = p_review_id;
    update public.matches set journey_stage = v_review.to_stage where id = v_review.match_id;
    update public.journey_attempts set journey_stage = v_review.to_stage where id = v_review.attempt_id;
    if v_review.to_stage = 'conversation' then
      update public.conversations set status = 'active' where attempt_id = v_review.attempt_id;
    end if;
  end if;
end;
$$;


--
-- Name: withdraw_journey_request(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.withdraw_journey_request(p_request_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
begin
  update public.journey_requests request
  set status = 'withdrawn', withdrawn_at = now(), closed_reason = 'sender_withdrew'
  where request.id = p_request_id
    and request.requested_by = v_caller
    and request.status = 'pending';
  if not found then raise exception 'request_not_withdrawable'; end if;
end;
$$;


--
-- Name: zyra_accept_family_invitation(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_accept_family_invitation(p_invitation uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_invitation public.family_membership_invitations%rowtype;
  v_seat uuid;
begin
  select * into v_invitation
  from public.family_membership_invitations invitation
  where invitation.id = p_invitation
  for update;
  if not found or v_invitation.invited_user_id <> v_caller then
    raise exception 'family_invitation_not_found';
  end if;
  if v_invitation.status <> 'pending' then
    raise exception 'family_invitation_not_pending';
  end if;
  if v_invitation.expires_at <= now() then
    update public.family_membership_invitations
    set status = 'expired', responded_at = now()
    where id = p_invitation;
    raise exception 'family_invitation_expired';
  end if;
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = v_caller
      and binding.role = v_invitation.role
  ) then raise exception 'family_invitation_role_mismatch'; end if;

  insert into public.family_seat_assignments (
    family_subscription_id, member_id, role, funded_until
  )
  select family.id, v_caller, v_invitation.role, family.coverage_ends_at
  from public.family_subscriptions family
  where family.id = v_invitation.family_subscription_id
    and family.status = 'active'
    and coalesce(family.coverage_ends_at, 'infinity'::timestamptz) > now()
  returning id into v_seat;
  if v_seat is null then raise exception 'family_not_available'; end if;

  update public.family_membership_invitations
  set status = 'accepted', responded_at = now()
  where id = p_invitation;
  return v_seat;
end;
$$;


--
-- Name: zyra_accept_guardian_request(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_accept_guardian_request(p_request_id uuid, p_relationship text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_request public.wali_invites%rowtype;
  v_requester_role text;
  v_owner_role text;
  v_seeker uuid;
  v_wali uuid;
  v_relationship text;
  v_link_id uuid;
  v_owner_name text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  if p_relationship is not null and p_relationship not in (
    'father','brother','grandfather','uncle','legal_guardian',
    'family_representative','other'
  ) then raise exception 'unknown_relationship'; end if;

  select * into v_request from public.wali_invites wi
  where wi.id = p_request_id and wi.source = 'personal_code'
  for update;
  if not found or v_request.inviter_id <> v_me then raise exception 'request_unavailable'; end if;
  if v_request.status <> 'pending' then raise exception 'request_not_pending'; end if;
  if v_request.request_expires_at <= clock_timestamp() then
    raise exception 'request_expired';
  end if;

  select p.role, p.first_name into v_owner_role, v_owner_name
  from public.profiles p where p.id = v_me;
  select p.role into v_requester_role
  from public.profiles p where p.id = v_request.recipient_id;
  if v_owner_role is distinct from v_request.inviter_role
     or v_requester_role = v_owner_role
     or v_requester_role not in ('seeker','wali') then
    raise exception 'role_context_changed';
  end if;
  if public.zyra_block_exists(v_request.recipient_id)
     or not public.zyra_can_guardian_link(v_me, v_request.recipient_id) then
    raise exception 'request_unavailable';
  end if;
  if not private.zyra_identity_verification_allows_user(v_request.recipient_id) then
    raise exception 'request_unavailable';
  end if;

  if v_owner_role = 'seeker' then
    v_seeker := v_me; v_wali := v_request.recipient_id;
    v_relationship := v_request.relationship;
    if p_relationship is not null then raise exception 'relationship_owned_by_guardian'; end if;
    if v_relationship is null then raise exception 'relationship_required'; end if;
  else
    v_seeker := v_request.recipient_id; v_wali := v_me;
    v_relationship := p_relationship;
    if v_relationship is null then raise exception 'relationship_required'; end if;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'zyra-wali-link:' || v_seeker::text || ':' || v_wali::text,
      231
    )
  );
  if exists (
    select 1 from public.wali_links wl
    where wl.seeker_id = v_seeker
      and wl.wali_id = v_wali
      and wl.status = 'active'
  ) then
    raise exception 'already_linked';
  end if;

  insert into public.wali_links as existing
    (seeker_id, wali_id, status, relationship)
  values (v_seeker, v_wali, 'active', v_relationship)
  on conflict (seeker_id, wali_id) do update
    set status = 'active',
        relationship = coalesce(excluded.relationship, existing.relationship)
  returning id into v_link_id;

  delete from public.likes
   where (liker_id = v_seeker and liked_id = v_wali)
      or (liker_id = v_wali and liked_id = v_seeker);
  delete from public.saves
   where (saver_id = v_seeker and saved_id = v_wali)
      or (saver_id = v_wali and saved_id = v_seeker);
  delete from public.passes
   where (passer_id = v_seeker and passed_id = v_wali)
      or (passer_id = v_wali and passed_id = v_seeker);

  update public.wali_invites
     set status = 'accepted', accepted_at = clock_timestamp(), accepted_by = v_me
   where id = v_request.id;
  perform private.zyra_create_notification(
    v_request.recipient_id, 'wali_request', 'Guardian request accepted',
    coalesce(v_owner_name, 'They') || ' accepted your Guardian request.', null, v_me, v_request.id, v_link_id);
  return v_link_id;
end;
$$;


--
-- Name: zyra_active_journey_cap(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_active_journey_cap(p_user uuid) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select case
    when public.zyra_has_paid_role(p_user, 'seeker') then 3
    when exists (
      select 1 from public.subscriptions s
      where s.user_id = p_user and s.plan_type = 'seeker_basic'
        and s.status = 'active'
        and (s.expires_at is null or s.expires_at > now())
    ) then 1
    else 0 end;
$$;


--
-- Name: zyra_active_journey_count(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_active_journey_count(p_user uuid, p_exclude uuid DEFAULT NULL::uuid) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select count(*)::int from matches
  where status = 'active' and suspended_by is null
    and (seeker_a_id = p_user or seeker_b_id = p_user)
    and (p_exclude is null or id <> p_exclude);
$$;


--
-- Name: zyra_advance_stage(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_advance_stage(p_match_id uuid, p_from_stage text) RETURNS TABLE(advanced boolean, stage text, reason text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  caller     uuid := (select auth.uid());
  m          record;
  next_stage text;
  a_ok       boolean;
  b_ok       boolean;
begin
  if caller is null then
    raise exception 'not_authenticated';
  end if;

  select * into m from matches where id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  if not found then
    raise exception 'match_not_found';
  end if;
  if caller <> m.seeker_a_id and caller <> m.seeker_b_id then
    raise exception 'not_a_party';
  end if;

  if m.status <> 'active' then
    return query select false, m.journey_stage, 'journey_not_active'; return;
  end if;
  if m.suspended_by is not null then
    return query select false, m.journey_stage, 'journey_paused'; return;
  end if;
  if m.journey_stage is distinct from p_from_stage then
    return query select false, m.journey_stage, 'stage_moved'; return;
  end if;

  -- SALAM FIRST (DR-ZYRA-183): the greeting, then the number. Only
  -- this map moved; the gates below are exactly as they were.
  next_stage := case p_from_stage
                  when 'salam_exchange'       then 'compatibility_reveal'
                  when 'compatibility_reveal' then 'wali_gate'
                  when 'wali_gate'            then 'phase_1'
                end;

  if next_stage is null then
    if p_from_stage in ('phase_1','phase_2','phase_3','family_stage') then
      raise exception 'gated_transition'
        using hint = 'This transition opens a Family Review Period. '
                     'Call open_family_review() instead.';
    end if;
    if p_from_stage = 'conversation' then
      return query select false, m.journey_stage, 'terminal_stage'; return;
    end if;
    raise exception 'unknown_stage: %', p_from_stage;
  end if;

  if p_from_stage = 'compatibility_reveal' then
    insert into journey_stage_checkpoints as jsc (match_id, stage, seeker_id)
    values (p_match_id, p_from_stage, caller)
    on conflict do nothing;
  end if;

  if p_from_stage = 'compatibility_reveal' then

    select coalesce(jc.seeker_a_revealed, false) and coalesce(jc.seeker_b_revealed, false)
      into a_ok
      from journey_compatibility jc where jc.match_id = p_match_id;
    if not coalesce(a_ok, false) then
      return query select false, p_from_stage, 'waiting_for_reveal'; return;
    end if;

    -- ALIAS-QUALIFIED: jsc.stage, not stage. See header.
    select count(distinct jsc.seeker_id) = 2 into b_ok
      from journey_stage_checkpoints jsc
     where jsc.match_id  = p_match_id
       and jsc.stage     = p_from_stage
       and jsc.seeker_id in (m.seeker_a_id, m.seeker_b_id);
    if not coalesce(b_ok, false) then
      return query select false, p_from_stage, 'waiting_for_continue'; return;
    end if;

  elsif p_from_stage = 'salam_exchange' then

    select count(distinct js.seeker_id) = 2 into a_ok
      from journey_salams js
     where js.match_id  = p_match_id
       and js.seeker_id in (m.seeker_a_id, m.seeker_b_id);
    if not coalesce(a_ok, false) then
      return query select false, p_from_stage, 'waiting_for_salam'; return;
    end if;

  elsif p_from_stage = 'wali_gate' then

    select exists (select 1 from wali_links wl
                    where wl.seeker_id = caller and wl.is_main and wl.status = 'active')
      into a_ok;
    if not a_ok then
      return query select false, p_from_stage, 'guardian_required_self'; return;
    end if;

    select exists (select 1 from wali_links wl
                    where wl.seeker_id = case when caller = m.seeker_a_id
                                              then m.seeker_b_id else m.seeker_a_id end
                      and wl.is_main and wl.status = 'active')
      into b_ok;
    if not b_ok then
      return query select false, p_from_stage, 'guardian_required_other'; return;
    end if;

  end if;

  update matches
     set journey_stage = next_stage
   where id = p_match_id and journey_stage = p_from_stage;

  if not found then
    select m2.journey_stage into next_stage from matches m2 where m2.id = p_match_id;
    return query select false, next_stage, 'stage_moved'; return;
  end if;

  update journey_attempts ja
     set journey_stage = next_stage
   where ja.match_id = p_match_id and ja.status <> 'ended';

  return query select true, next_stage, 'advanced';
end;
$$;


--
-- Name: FUNCTION zyra_advance_stage(p_match_id uuid, p_from_stage text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_advance_stage(p_match_id uuid, p_from_stage text) IS 'Advances the three ungated Pre-Journey Ritual transitions and REFUSES the four Family-Review-gated ones. Replaces the client-side UPDATE that RLS silently discarded (release blocker, Founder 2026-08-07). Returns (advanced, stage, reason) — callers must surface the reason, never swallow it. See PRE-JOURNEY RITUAL and GUARDIAN & ROMANTIC RULES (current versions).';


--
-- Name: zyra_all_iso639_1(text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_all_iso639_1(p text[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'public'
    AS $_$
  select p is null
      or not exists (select 1 from unnest(p) x where x !~ '^[a-z]{2}$');
$_$;


--
-- Name: zyra_answers_refresh_onboarding_complete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_answers_refresh_onboarding_complete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  PERFORM zyra_refresh_onboarding_complete(
    CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id ELSE NEW.user_id END);
  RETURN NULL;
END;
$$;


--
-- Name: zyra_assert_family_owner_seat(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_assert_family_owner_seat(p_family uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_family public.family_subscriptions%rowtype;
begin
  select * into v_family
  from public.family_subscriptions family
  where family.id = p_family;
  if not found or v_family.owner_id is null then return; end if;

  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = v_family.owner_id
      and binding.role = v_family.owner_role
  ) then raise exception 'verified_family_owner_required'; end if;

  if (v_family.owner_role = 'seeker' and v_family.seeker_places < 1)
     or (v_family.owner_role = 'guardian' and v_family.guardian_places < 1) then
    raise exception 'family_owner_place_required';
  end if;

  if not exists (
    select 1
    from public.family_seat_assignments seat
    where seat.family_subscription_id = p_family
      and seat.member_id = v_family.owner_id
      and seat.role = v_family.owner_role
      and (seat.removed_at is null or seat.funded_until > now())
  ) then raise exception 'family_owner_seat_required'; end if;
end;
$$;


--
-- Name: zyra_attach_identity_verification_provider_session(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_attach_identity_verification_provider_session(p_user_id uuid, p_provider_code text, p_provider_session_ref text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'private'
    AS $$
declare
  v_id uuid;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service_role_required';
  end if;
  if p_provider_code not in ('sumsub', 'stripe') then
    raise exception 'unsupported_provider';
  end if;
  if p_provider_session_ref is null
     or char_length(p_provider_session_ref) not between 1 and 255 then
    raise exception 'invalid_provider_session_ref';
  end if;

  select id into v_id
  from private.identity_verification_attempts
  where user_id = p_user_id
    and member_deleted_at is null
    and consent_granted
    and result in ('pending', 'retry_required')
    and (provider_session_ref is null
         or provider_session_ref = p_provider_session_ref)
  order by created_at desc
  limit 1
  for update;

  if v_id is null then raise exception 'no_eligible_attempt'; end if;

  update private.identity_verification_attempts
     set provider_code = p_provider_code,
         provider_session_ref = p_provider_session_ref,
         result = 'pending'
   where id = v_id;
  return true;
end;
$$;


--
-- Name: zyra_attempt_participants(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_attempt_participants(p_attempt uuid) RETURNS TABLE(user_id uuid, role text, is_main boolean, attempt_status text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select r.user_id, r.role, r.is_main, r.attempt_status
  from public.zyra_attempt_participant_rows r
  where r.attempt_id = p_attempt;
$$;


--
-- Name: FUNCTION zyra_attempt_participants(p_attempt uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_attempt_participants(p_attempt uuid) IS 'NOT CLIENT-CALLABLE as of 2026-08-08. Has no caller check. Do not re-grant without adding a zyra_can_view_attempt() guard.';


--
-- Name: zyra_attempt_summary_for_guardian(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_attempt_summary_for_guardian(p_seeker uuid) RETURNS TABLE(attempt_id uuid, started_at timestamp with time zone, ended_at timestamp with time zone, ended boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  with current_guardian_link as materialized (
    select w.id, w.active_since, w.guardian_link_authority_id
    from public.wali_links w
    where w.seeker_id = p_seeker and w.wali_id = (select auth.uid()) and w.status = 'active'
  )
  select a.id, a.started_at, a.ended_at, a.status = 'ended'
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  cross join current_guardian_link w
  left join private.zyra_ended_journey_visibility v on v.attempt_id = a.id
  where p_seeker in (m.seeker_a_id, m.seeker_b_id)
    and not exists (
      select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
    )
    and (a.status = 'active' or (
      a.status = 'ended'
      and ((p_seeker = v.seeker_a_id and v.seeker_a_visible)
        or (p_seeker = v.seeker_b_id and v.seeker_b_visible))
      and (a.ended_at >= w.active_since or exists (
        select 1 from public.guardian_journey_history_consents c
        where c.wali_link_id = w.id and c.guardian_link_authority_id = w.guardian_link_authority_id
      ))
    ));
$$;


--
-- Name: FUNCTION zyra_attempt_summary_for_guardian(p_seeker uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_attempt_summary_for_guardian(p_seeker uuid) IS 'DR-ZYRA-230/233. CALLER-BOUND ACTIVE GUARDIANS. Every active Guardian sees the current active/paused attempt plus ended attempts from the current continuous link period. A valid per-link Seeker permission widens to all ended summaries for that same Guardian. Positive active/ended allowlist fails future statuses closed. Four fields only; never counterpart, stage, messages, answers, reasons, notes or safety data.';


--
-- Name: zyra_available_journey_return_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_available_journey_return_ids() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select * from public.zyra_may_request_new_journey_ids();
$$;


--
-- Name: zyra_block_exists(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_block_exists(p_other uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM profile_blocks
    WHERE (blocker_id = auth.uid() AND blocked_id = p_other)
       OR (blocked_id = auth.uid() AND blocker_id = p_other)
  );
$$;


--
-- Name: zyra_block_user(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_block_user(p_other uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_me uuid := auth.uid();
  v_match RECORD;
  v_ended int := 0;
BEGIN
  IF v_me IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  IF p_other IS NULL OR p_other = v_me THEN RAISE EXCEPTION 'cannot_block_self'; END IF;
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_other) THEN
    RAISE EXCEPTION 'no_such_user';
  END IF;

  INSERT INTO profile_blocks (blocker_id, blocked_id)
  VALUES (v_me, p_other) ON CONFLICT DO NOTHING;

  -- Every live Journey between the pair. Plural on purpose: nothing
  -- guarantees there is only one, and a loop that assumes one is the kind
  -- of assumption that survives until it does not.
  FOR v_match IN
    SELECT id FROM matches
    WHERE status <> 'ended'
      AND (   (seeker_a_id = v_me AND seeker_b_id = p_other)
           OR (seeker_a_id = p_other AND seeker_b_id = v_me) )
  LOOP
    PERFORM public.zyra_end_match_internal(v_match.id, v_me, 'safety_concern');
    v_ended := v_ended + 1;
  END LOOP;

  RETURN jsonb_build_object('status','blocked','journeys_ended',v_ended);
END;
$$;


--
-- Name: zyra_can_continue_journey(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_can_continue_journey(p_a uuid, p_b uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select not exists (
           select 1 from public.profile_blocks x
           where (x.blocker_id = p_a and x.blocked_id = p_b)
              or (x.blocker_id = p_b and x.blocked_id = p_a))
     and not exists (
           select 1 from public.wali_links w
           where w.status = 'active'
             and (   (w.seeker_id = p_a and w.wali_id = p_b)
                  or (w.seeker_id = p_b and w.wali_id = p_a)));
$$;


--
-- Name: FUNCTION zyra_can_continue_journey(p_a uuid, p_b uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_can_continue_journey(p_a uuid, p_b uuid) IS 'OA-ZYRA-174. May an EXISTING Journey continue? Blocks and Tier-0 only. Not zyra_can_match: Tier-1 is a matching rule, grandfathered for Journeys already under way. Internal predicate — not client-callable.';


--
-- Name: zyra_can_guardian_link_pair(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_can_guardian_link_pair(p_a uuid, p_b uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select
        p_a is not null
    and p_b is not null
    -- Nobody is their own Guardian. Also a table CHECK
    -- (wali_links_no_self_link); stated here so the predicate is complete
    -- on its own rather than relying on a constraint one layer down.
    and p_a <> p_b
    -- ANY status, including 'ended'. An ended Journey can be revived by
    -- restart_journey(), so a Guardian link over one would create a pair
    -- the system can resurrect into a state zyra_can_match() forbids.
    -- "Absolute" was the Founder's word, and a past romance between a
    -- Guardian and their Seeker is the conflict of interest the Guardian
    -- role exists to prevent.
    and not exists (
      select 1 from public.matches m
      where (m.seeker_a_id = p_a and m.seeker_b_id = p_b)
         or (m.seeker_a_id = p_b and m.seeker_b_id = p_a)
    );
$$;


--
-- Name: zyra_can_guardian_link(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_can_guardian_link(p_a uuid, p_b uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    caller uuid := auth.uid();
BEGIN
    IF caller IS NOT NULL AND caller IS DISTINCT FROM p_a AND caller IS DISTINCT FROM p_b THEN
        RETURN false;
    END IF;

    RETURN private.zyra_can_guardian_link_pair(p_a, p_b);
END;
$$;


--
-- Name: FUNCTION zyra_can_guardian_link(p_a uuid, p_b uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_can_guardian_link(p_a uuid, p_b uuid) IS 'Tests whether a Seeker and Guardian can link. A signed-in caller must be one of the pair.';


--
-- Name: zyra_can_match_pair(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.zyra_can_match_pair(p_a uuid, p_b uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select exists (
    select 1
    from public.profiles a, public.profiles b
    where a.id = p_a
      and b.id = p_b
      and a.id <> b.id
      -- A Guardian is not a romantic candidate. Neither is an admin.
      and a.role = 'seeker'
      and b.role = 'seeker'
      -- OA-ZYRA-193(c), 2026-08-11. No question is optional, so a pair
      -- cannot become a match on half an answer sheet.
      and a.onboarding_complete
      and b.onboarding_complete
      -- The segregation rule. NOT NULL on the column, checked anyway
      -- because a future nullable column would otherwise open it silently.
      and a.gender is not null
      and b.gender is not null
      and a.gender <> b.gender
      and not exists (
        select 1 from public.profile_blocks x
        where (x.blocker_id = p_a and x.blocked_id = p_b)
           or (x.blocker_id = p_b and x.blocked_id = p_a)
      )
      -- TIER-0 — one of them guards the other.
      and not exists (
        select 1 from public.wali_links w
        where w.status = 'active'
          and (   (w.seeker_id = p_a and w.wali_id = p_b)
               or (w.seeker_id = p_b and w.wali_id = p_a) )
      )
      -- TIER-1 — they share a Guardian. Added 2026-08-08.
      and not exists (
        select 1
        from public.wali_links wa
        join public.wali_links wb on wb.wali_id = wa.wali_id
        where wa.seeker_id = p_a
          and wb.seeker_id = p_b
          and wa.status in ('active','removed')
          and wb.status in ('active','removed')
      )
  );
$$;


--
-- Name: zyra_can_match(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_can_match(p_a uuid, p_b uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    caller uuid := auth.uid();
BEGIN
    IF caller IS NOT NULL AND caller IS DISTINCT FROM p_a AND caller IS DISTINCT FROM p_b THEN
        RETURN false;
    END IF;

    RETURN private.zyra_can_match_pair(p_a, p_b);
END;
$$;


--
-- Name: FUNCTION zyra_can_match(p_a uuid, p_b uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_can_match(p_a uuid, p_b uuid) IS 'Tests romantic eligibility for a pair. A signed-in caller must be one of the pair.';


--
-- Name: zyra_can_read_ended_match(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_can_read_ended_match(p_match_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select coalesce((
    select (v.seeker_a_id = (select auth.uid()) and v.seeker_a_visible)
        or (v.seeker_b_id = (select auth.uid()) and v.seeker_b_visible)
    from private.zyra_ended_journey_visibility v
    join public.journey_attempts a on a.id = v.attempt_id
    where v.match_id = p_match_id
      and not exists (
        select 1 from private.zyra_purged_ended_match_projections p where p.match_id = p_match_id
      )
    order by a.attempt_number desc
    limit 1
  ), false);
$$;


--
-- Name: zyra_can_read_photo_object(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_can_read_photo_object(p_object_name text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select (select auth.uid()) is not null and exists (
    select 1 from public.profile_photos pp
    where pp.storage_path = p_object_name and pp.removed_at is null
      and private.zyra_photo_reference_owned(pp.user_id, pp.storage_path)
      and public.zyra_can_view_profile(pp.user_id)
  );
$$;


--
-- Name: FUNCTION zyra_can_read_photo_object(p_object_name text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_can_read_photo_object(p_object_name text) IS 'F03: private object owner_id, canonical owner prefix and profile row owner must agree; existing profile visibility remains authoritative. No seed exemption.';


--
-- Name: zyra_can_read_profile_video_object(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_can_read_profile_video_object(p_object_name text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select (select auth.uid()) is not null and exists (
    select 1
    from public.profile_videos video
    join storage.objects object
      on object.id = video.id
     and object.bucket_id = 'profile-videos'
     and object.name = video.storage_path
    where video.storage_path = p_object_name
      and video.status = 'approved'
      and public.zyra_has_paid_role(video.user_id, 'seeker')
      and public.zyra_can_view_profile(video.user_id)
  );
$$;


--
-- Name: zyra_can_view_attempt(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_can_view_attempt(p_attempt uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from public.zyra_attempt_participant_rows r
    where r.attempt_id = p_attempt
      and r.user_id = (select auth.uid())
  );
$$;


--
-- Name: FUNCTION zyra_can_view_attempt(p_attempt uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_can_view_attempt(p_attempt uuid) IS 'May the CALLER see this attempt? Boolean, full access only. The successor-Guardian summary case is deliberately NOT here — see zyra_attempt_summary_for_guardian().';


--
-- Name: zyra_can_view_profile(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_can_view_profile(p_target uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    p_target = (select auth.uid())

    -- CLAUSE 2 — your own ward, or your own Guardian. UNCHANGED.
    -- This is the entire legitimate basis of Guardian visibility.
    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )

    -- CLAUSE 3 — the two Seekers of a shared attempt. SEEKERS ONLY.
    --   2026-08-08 (item 1): Guardians removed entirely. Previously any
    --     participant could see any participant, which handed every
    --     Guardian a gender-blind view of the other family.
    --   The old status guard (Step 1) is gone with them — it existed to
    --     stop families meeting at 'potential', and Seeker<->Seeker was
    --     always exempt from it anyway, because clause 4 requires
    --     is_active and this clause is the only thing keeping a PAUSED
    --     counterpart visible in Potential Journeys.
    --   Block guards (Step 1b) retained verbatim, both halves.
    --   2026-08-11: NOT gated on onboarding completeness, on purpose —
    --     see the header. A live Journey outranks a tidy pool.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.matches mm on mm.id = me.match_id
      where me.user_id   = (select auth.uid())
        and me.role = 'seeker'
        and p_target <> me.user_id
        and p_target in (mm.seeker_a_id, mm.seeker_b_id)
        -- (b) durable: a safety ending is terminal, block row or not
        and mm.end_reason is distinct from 'safety_concern'
        -- (a) live: a standing block, for pairs with nothing to end
        and not exists (
          select 1 from public.profile_blocks b
          where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
             or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
        )
    )

    -- CLAUSE 4 — browsing.
    --
    -- 2026-08-11, OA-ZYRA-193(c): both parties must have finished
    -- onboarding. Reads the materialised profiles.onboarding_complete
    -- rather than recomputing — this function is the USING clause of
    -- profiles_select and runs per row on every profile read in the app.
    or exists (
      select 1
      from public.profiles p
      cross join lateral (
        select pv.role, pv.gender, pv.onboarding_complete
          from public.profiles pv where pv.id = (select auth.uid())
      ) viewer
      where p.id = p_target
        and p.is_active = true
        and p.profile_complete = true
        and p.onboarding_complete = true          -- they finished
        and viewer.onboarding_complete = true     -- and so did you
        and not public.zyra_block_exists(p_target)
        and viewer.role = 'seeker'
        and viewer.gender is not null
        and p.gender is not null
        and p.gender <> viewer.gender
    );
$$;


--
-- Name: FUNCTION zyra_can_view_profile(p_target uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_can_view_profile(p_target uuid) IS 'May the CALLER see this profile? self · Guardian link · shares an attempt (via zyra_attempt_participant_rows) · opposite-gender browsing. Participation logic is NOT duplicated here — it is read from the one view.';


--
-- Name: zyra_cancel_guardian_request(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_cancel_guardian_request(p_request_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  update public.wali_invites wi
     set status = 'cancelled', cancelled_at = clock_timestamp()
   where wi.id = p_request_id and wi.source = 'personal_code'
     and wi.recipient_id = v_me and wi.status = 'pending'
     and wi.request_expires_at > clock_timestamp();
  return found;
end;
$$;


--
-- Name: zyra_capture_family_message_report_evidence(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_capture_family_message_report_evidence() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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
        where candidate.chat_id = message.chat_id
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

  insert into private.zyra_family_chat_report_attempts(report_id, attempt_id, chat_id)
  select new.id, chat.attempt_id, chat.id
  from public.family_messages message
  join public.family_message_chats chat on chat.id = message.chat_id
  where message.id = new.message_id and chat.attempt_id is not null;
  return new;
end;
$$;


--
-- Name: zyra_ch2_sect_hard_shape_ok(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_ch2_sect_hard_shape_ok(p jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    SET search_path TO 'public'
    AS $$
  SELECT p IS NULL
      OR p -> 'sect' -> 'hard_requirement' IS NULL
      OR ( jsonb_typeof(p -> 'sect' -> 'hard_requirement') = 'array'
       AND NOT EXISTS (
             SELECT 1 FROM jsonb_array_elements(p -> 'sect' -> 'hard_requirement') a
              WHERE jsonb_typeof(a) <> 'string' ) );
$$;


--
-- Name: FUNCTION zyra_ch2_sect_hard_shape_ok(p jsonb); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_ch2_sect_hard_shape_ok(p jsonb) IS 'Shape guard for seeker_details.preferences->sect->hard_requirement. Accepts an array of sect labels only. Exists so the retired boolean form cannot be written by an older client build — a silent old-shape write would read as "no exclusion at all", failing OPEN on a promise the Seeker made about Article 9 data.';


--
-- Name: zyra_ch4_hard_shape_ok(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_ch4_hard_shape_ok(p jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    SET search_path TO 'public'
    AS $$
  SELECT p IS NULL
      OR ( jsonb_typeof(p) = 'object'
       AND NOT EXISTS (
             SELECT 1
               FROM jsonb_each(p) e
              WHERE jsonb_typeof(e.value) <> 'array'
                 OR EXISTS ( SELECT 1
                               FROM jsonb_array_elements(e.value) a
                              WHERE jsonb_typeof(a) <> 'string' )
           ) );
$$;


--
-- Name: FUNCTION zyra_ch4_hard_shape_ok(p jsonb); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_ch4_hard_shape_ok(p jsonb) IS 'Shape guard for onboarding_answers.ch4_hard_requirements. Accepts {question_id: [option_label, ...]} only. Exists so the retired {question_id: bool} shape cannot be written by an older client build — a silent old-shape write would read as "no hard requirement at all", which fails OPEN on a promise the Seeker made. Fail loudly instead.';


--
-- Name: zyra_claim_photo_object_deletions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_claim_photo_object_deletions() RETURNS TABLE(bucket text, path text, attempts integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_item record;
  v_now timestamptz := clock_timestamp();
begin
  -- Keep Q95's single claim, folder serialization and retry lease.
  if not pg_catalog.pg_try_advisory_xact_lock(
    pg_catalog.hashtextextended('zyra-photo-cleanup-claim', 0)
  ) then return; end if;
  for v_item in
    select d.bucket, d.path
    from public.photo_object_deletions d
    left join private.zyra_photo_cleanup_leases l on l.bucket = d.bucket and l.path = d.path
    where d.done_at is null and d.attempts < 10 and (l.expires_at is null or l.expires_at < v_now)
      and not private.zyra_photo_object_referenced(d.bucket, d.path)
    order by d.account_delete_due_at nulls last, d.attempts, d.bucket, d.path
    limit 12
  loop
    if not pg_catalog.pg_try_advisory_xact_lock(pg_catalog.hashtextextended(
      'zyra-photo:' || pg_catalog.split_part(v_item.path, '/', 1), 0
    )) then continue; end if;
    perform private.zyra_lock_photo_folder(pg_catalog.split_part(v_item.path, '/', 1));
    if private.zyra_photo_object_referenced(v_item.bucket, v_item.path) then
      continue;
    end if;
    return query
    update public.photo_object_deletions d
      set attempts = d.attempts + 1, last_error = 'cleanup_interrupted'
      where d.bucket = v_item.bucket and d.path = v_item.path and d.done_at is null
      returning d.bucket, d.path, d.attempts;
    if found then
      insert into private.zyra_photo_cleanup_leases (bucket, path, expires_at)
      values (v_item.bucket, v_item.path, v_now + interval '2 minutes')
      on conflict on constraint zyra_photo_cleanup_leases_pkey do update set expires_at = excluded.expires_at;
      return;
    end if;
  end loop;
end;
$$;


--
-- Name: zyra_clear_main_guardian(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_clear_main_guardian(p_wali_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := (select auth.uid());
  v_n integer;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  update public.wali_links
     set is_main = false
   where seeker_id = v_me
     and wali_id = p_wali_id
     and status = 'active'
     and is_main is true;

  get diagnostics v_n = row_count;
  if v_n = 0 then
    raise exception 'not_your_main_guardian';
  end if;

  return true;
end;
$$;


--
-- Name: FUNCTION zyra_clear_main_guardian(p_wali_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_clear_main_guardian(p_wali_id uuid) IS 'DR-ZYRA-236. Caller-bound Seeker action. Demotes the caller''s current active Main Guardian without unlinking them. The resulting deliberate no-Main state raises a My ZYRA action and holds ordinary Active Journey participation in the client until another Main Guardian is assigned. Ending remains available.';


--
-- Name: zyra_close_family_message_report(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_close_family_message_report(p_report_id uuid, p_legal_hold boolean DEFAULT false) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: zyra_close_unavailable_journey_requests(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_close_unavailable_journey_requests() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_count integer;
begin
  with unavailable as (
    update public.journey_requests request
    set status = 'recipient_unavailable',
        responded_at = now(),
        closed_reason = 'recipient_unavailable'
    where request.status = 'pending'
      and public.zyra_active_journey_cap(request.requested_to) = 0
    returning request.requested_by, request.match_id
  ), notified as (
    select public.create_notification(
      unavailable.requested_by,
      'journey_request_declined',
      'Journey request',
      'This person is not available to reconnect right now.',
      unavailable.match_id
    )
    from unavailable
  )
  select count(*)::integer into v_count from notified;
  return coalesce(v_count, 0);
end;
$$;


--
-- Name: zyra_compatibility_for_plus(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_compatibility_for_plus(p_match_id uuid) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
  v_counterpart uuid;
  v_result private.zyra_directional_results;
begin
  if v_caller is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  select m.seeker_a_id, m.seeker_b_id, m.status, m.journey_stage,
         m.suspended_by, m.also_paused_by,
         coalesce(pg_catalog.to_jsonb(m) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_match
    from public.matches as m
   where m.id = p_match_id
     and v_caller in (m.seeker_a_id, m.seeker_b_id)
   for update;

  if not found then
    raise exception using errcode = '42501', message = 'not_a_party';
  end if;

  if v_match.status is distinct from 'active'
     or v_match.journey_stage is distinct from 'compatibility_reveal'
     or v_match.suspended_by is not null
     or v_match.also_paused_by is not null
     or v_match.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  select a.id, a.journey_stage, a.paused_by, a.also_paused_by,
         coalesce(pg_catalog.to_jsonb(a) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_attempt
    from public.journey_attempts as a
   where a.match_id = p_match_id
     and a.status = 'active'
   for update;

  if not found
     or v_attempt.journey_stage is distinct from 'compatibility_reveal'
     or v_attempt.paused_by is not null
     or v_attempt.also_paused_by is not null
     or v_attempt.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  v_is_a := v_caller = v_match.seeker_a_id;
  v_counterpart := case
    when v_is_a then v_match.seeker_b_id
    else v_match.seeker_a_id
  end;

  if not exists (
    select 1
      from public.profile_unlocks as unlocks
     where unlocks.unlocker_id = v_caller
       and unlocks.unlocked_id = v_counterpart
       and unlocks.unlock_type in ('paid_plus_single', 'paid_plus_bundle')
  ) then
    raise exception using errcode = '42501', message = 'plus_required';
  end if;

  insert into public.journey_compatibility (match_id, attempt_id)
  values (p_match_id, v_attempt.id)
  on conflict (match_id) do nothing;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id
   for update;

  if v_compat.attempt_id is distinct from v_attempt.id then
    raise exception using
      errcode = '55000',
      message = 'compatibility_attempt_mismatch';
  end if;

  v_result := private.zyra_save_direction_result(v_caller, v_counterpart);
  if v_result.state is distinct from 'ok' then
    return null;
  end if;

  -- Retain the legacy score-only projection and the Main Guardian write
  -- gate on changes to that projection. Plus never changes reveal consent.
  update public.journey_compatibility as jc
     set seeker_a_score = case when v_is_a then v_result.overall else jc.seeker_a_score end,
         seeker_b_score = case when v_is_a then jc.seeker_b_score else v_result.overall end
   where jc.match_id = p_match_id
     and (case when v_is_a then jc.seeker_a_score else jc.seeker_b_score end)
         is distinct from v_result.overall;
  return v_result.overall;
end;
$$;


--
-- Name: FUNCTION zyra_compatibility_for_plus(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_compatibility_for_plus(p_match_id uuid) IS 'DR-ZYRA-135 / DOC-ZYRA-0472. Existing Plus entitlements can read the caller-owned saved Overall without changing either reveal flag.';


--
-- Name: zyra_compatibility_topics(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_compatibility_topics(p_subject uuid, p_match_id uuid DEFAULT NULL::uuid) RETURNS TABLE(overall numeric, topics_locked boolean, area_no smallint, area_code text, band text, state text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_role text;
  v_viewer uuid;
  v_match public.matches%rowtype;
  v_attempt_id uuid;
  v_attempt_number integer;
  v_mutual boolean := false;
  v_unlocked boolean := false;
  v_open boolean;
  v_result private.zyra_directional_results%rowtype;
begin
  if v_caller is null or p_subject is null or v_caller = p_subject then return; end if;
  select p.role into v_role from public.profiles p where p.id = v_caller;
  if v_role is null or v_role not in ('seeker', 'wali') then return; end if;
  if not exists (select 1 from public.profiles p where p.id = p_subject and p.role = 'seeker')
     or public.zyra_block_exists(p_subject) then return; end if;

  if v_role = 'seeker' then
    select exists (
      select 1 from public.profile_unlocks u
      where u.unlocker_id = v_caller and u.unlocked_id = p_subject
        and u.unlock_type in ('paid_single', 'paid_bundle', 'paid_plus_single', 'paid_plus_bundle')
    ) into v_unlocked;
  end if;

  if p_match_id is null then
    if v_role <> 'seeker' or not v_unlocked
       or not public.zyra_can_view_profile(p_subject) then return; end if;
    v_viewer := v_caller;
  else
    select m.* into v_match
    from public.matches m
    where m.id = p_match_id and p_subject in (m.seeker_a_id, m.seeker_b_id)
      and m.status in ('active', 'ended')
      and m.seeker_a_id is not null and m.seeker_b_id is not null
      and m.end_reason is distinct from 'safety_concern'
      and not exists (
        select 1 from private.zyra_purged_ended_match_projections p where p.match_id = m.id
      );
    if not found then return; end if;
    v_viewer := case when p_subject = v_match.seeker_a_id then v_match.seeker_b_id
                     else v_match.seeker_a_id end;
    if v_role = 'seeker' and v_viewer <> v_caller then return; end if;

    select a.id, a.attempt_number, jc.seeker_a_revealed and jc.seeker_b_revealed
      into v_attempt_id, v_attempt_number, v_mutual
    from public.journey_attempts a
    left join public.journey_compatibility jc on jc.match_id = a.match_id and jc.attempt_id = a.id
    where a.match_id = v_match.id and a.status = v_match.status
      and (a.status = 'active' or a.end_reason is distinct from 'safety_concern')
    order by a.attempt_number desc
    limit 1;
    if not found then return; end if;
    if v_match.status = 'ended' and not exists (
      select 1 from private.zyra_ended_journey_visibility v
      where v.attempt_id = v_attempt_id and ((v.seeker_a_id = v_viewer and v.seeker_a_visible)
        or (v.seeker_b_id = v_viewer and v.seeker_b_visible))
    ) then return; end if;

    -- Accepted restarts resume at Salam exchange and leave the prior
    -- match-keyed reveal row on its original attempt. Carry that mutual
    -- consent within this match; check access against the selected attempt.
    if v_mutual is not true then
      select exists (
        select 1 from public.journey_requests r
        where r.match_id = v_match.id and r.attempt_id = v_attempt_id and r.status = 'accepted'
          and (
            exists (
              select 1 from public.journey_compatibility jc
              join public.journey_attempts prior on prior.id = jc.attempt_id
                and prior.match_id = jc.match_id
              where jc.match_id = r.match_id and prior.status = 'ended'
                and prior.attempt_number < v_attempt_number
                and prior.end_reason is distinct from 'safety_concern'
                and jc.seeker_a_revealed and jc.seeker_b_revealed
            ) or exists (
              select 1 from private.zyra_journey_reveal_tombstones t
              where t.match_id = r.match_id and t.consent_for_attempt_id = r.attempt_id
            )
          )
      ) into v_mutual;
    end if;

    if v_role = 'wali' then
      if v_mutual is not true or public.zyra_block_exists(v_viewer) then return; end if;
      if v_match.status = 'active' then
        -- F02's exact-attempt and continuous-link checks, scoped to the
        -- one linked Seeker whose direction this request would disclose.
        if not exists (
          select 1 from public.wali_links w
          where w.seeker_id = v_viewer and w.wali_id = v_caller and w.status = 'active'
            and (w.is_main or exists (
              select 1 from public.journey_guardian_assignments a
              where a.attempt_id = v_attempt_id and a.wali_link_id = w.id
                and a.seeker_id = v_viewer and a.revoked_at is null
                and a.granted_at >= w.active_since
            ))
        ) then return; end if;
      elsif not exists (
        select 1 from public.zyra_attempt_summary_for_guardian(v_viewer) archive
        where archive.attempt_id = v_attempt_id and archive.ended
      ) then return;
      end if;
    elsif v_mutual is not true and not v_unlocked then
      return;
    end if;
  end if;

  -- Safety endings remain private after the live block is removed, including
  -- when the same pair is addressed through an old paid Profile Unlock.
  if exists (
    select 1 from public.matches m
    where ((m.seeker_a_id = v_viewer and m.seeker_b_id = p_subject)
        or (m.seeker_b_id = v_viewer and m.seeker_a_id = p_subject))
      and m.end_reason = 'safety_concern'
  ) or exists (
    select 1 from public.profile_blocks b
    where (b.blocker_id = v_viewer and b.blocked_id = p_subject)
       or (b.blocker_id = p_subject and b.blocked_id = v_viewer)
  ) then return; end if;

  select d.* into v_result
  from private.zyra_directional_results d
  where d.viewer = v_viewer and d.subject = p_subject;
  if not found and v_role = 'seeker' and (v_unlocked or v_mutual is true) then
    v_result := private.zyra_save_direction_result(v_viewer, p_subject);
  end if;

  v_open := case v_role
    when 'seeker' then public.zyra_has_paid_role(v_caller, 'seeker') or v_unlocked
    else public.zyra_has_paid_role(v_caller, 'guardian')
  end;
  return query
    select case when v_result.state = 'ok' then v_result.overall end,
           not v_open,
           a.area_no::smallint,
           a.area_code,
           case when v_open and v_result.state = 'ok'
                then v_result.area_bands ->> (a.area_no - 1) end,
           coalesce(v_result.state, 'incomplete')
    from (values
      (1, 'deen'), (2, 'marriage'), (3, 'children'), (4, 'family'),
      (5, 'finances'), (6, 'work'), (7, 'home'), (8, 'communication'),
      (9, 'personality'), (10, 'lifestyle'), (11, 'digital'), (12, 'culture')
    ) a(area_no, area_code)
    order by a.area_no;
end;
$$;


--
-- Name: zyra_confirm_milestone(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_confirm_milestone(p_attestation_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  caller UUID := auth.uid();
  att RECORD; m RECORD; v_timeline UUID; v_name TEXT; v_label TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  select a.* into att from journey_milestone_attestations a
         join matches mm on mm.id = a.match_id
         where a.id = p_attestation_id and mm.seeker_a_id is not null and mm.seeker_b_id is not null
         for update of mm;
  IF NOT FOUND OR att.status <> 'pending' THEN RAISE EXCEPTION 'attestation_not_pending'; END IF;

  SELECT * INTO m FROM matches WHERE id = att.match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party'; END IF;
  IF caller = att.proposed_by THEN
    RAISE EXCEPTION 'not_yours_to_confirm'
      USING HINT = 'The other Seeker confirms — that is what makes it a shared record.';
  END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'journey_not_active'; END IF;
  IF m.suspended_by IS NOT NULL THEN RAISE EXCEPTION 'journey_paused'; END IF;

  INSERT INTO timelines (match_id, attempt_id) VALUES (att.match_id, att.attempt_id)
  ON CONFLICT (attempt_id) DO NOTHING;
  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = att.attempt_id;

  IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                  WHERE timeline_id = v_timeline AND milestone_type = att.milestone_type) THEN
    -- Noon UTC: every viewer within ±11h of UTC renders the same calendar
    -- date the pair attested.
    INSERT INTO timeline_milestones (timeline_id, milestone_type, occurred_at)
    VALUES (v_timeline, att.milestone_type,
            (att.occurred_on::timestamp + interval '12 hours') AT TIME ZONE 'UTC');
  END IF;

  UPDATE journey_milestone_attestations
     SET status = 'confirmed', confirmed_by = caller, confirmed_at = now()
   WHERE id = p_attestation_id;

  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  v_label := CASE att.milestone_type WHEN 'meeting' THEN 'first meeting' ELSE 'Nikah' END;
  PERFORM create_notification(
    att.proposed_by, 'milestone_confirmed', 'Milestone confirmed',
    COALESCE(v_name,'They')||' confirmed your '||v_label||'. It is now on your Timeline.',
    att.match_id);
END; $$;


--
-- Name: FUNCTION zyra_confirm_milestone(p_attestation_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_confirm_milestone(p_attestation_id uuid) IS 'Counterpart-only confirmation; writes the timeline_milestones row at noon UTC of the attested date. NOT EXISTS-guarded like every other milestone writer.';


--
-- Name: zyra_confirm_preference_lights(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_confirm_preference_lights(p_items jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := (select auth.uid());
  v_gender text;
  v_third_sect_key text;
  v_answers jsonb;
  v_ch4 jsonb;
  v_ch2 jsonb;
  v_item jsonb;
  v_control record;
  v_light text;
  v_block jsonb;
  v_matrix jsonb;
  v_ch4_changed boolean := false;
  v_ch2_changed boolean := false;
  v_previous_flag text := current_setting('zyra.confirm_preference_lights', true);
begin
  if not public.has_article9_consent() then
    raise exception using errcode = '42501', message = 'consent_required';
  end if;
  if v_me is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;
  select p.gender into v_gender
  from public.profiles p where p.id = v_me and p.role = 'seeker';
  if not found then
    raise exception using errcode = '42501', message = 'seeker_required';
  end if;
  if jsonb_typeof(p_items) is distinct from 'array' then
    raise exception using errcode = '22023', message = 'invalid_preference_lights';
  end if;
  if jsonb_array_length(p_items) = 0 then
    raise exception using errcode = '22023', message = 'invalid_preference_lights';
  end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) is distinct from 'object' then
      raise exception using errcode = '22023', message = 'invalid_preference_lights';
    end if;
    if v_item - array['question_id', 'option_value', 'light'] <> '{}'::jsonb
       or jsonb_typeof(v_item -> 'question_id') is distinct from 'string'
       or jsonb_typeof(v_item -> 'option_value') is distinct from 'string'
       or jsonb_typeof(v_item -> 'light') is distinct from 'string'
       or v_item ->> 'light' not in ('green', 'amber', 'red') then
      raise exception using errcode = '22023', message = 'invalid_preference_lights';
    end if;
  end loop;
  if exists (
    select 1 from jsonb_to_recordset(p_items) i(question_id text, option_value text)
    group by i.question_id, i.option_value having count(*) > 1
  ) then
    raise exception using errcode = '22023', message = 'invalid_preference_lights';
  end if;

  -- Use the same row-before-receipt order as ordinary preference writers.
  select o.ch3_answers, o.ch4_preferences into v_answers, v_ch4 from public.onboarding_answers o
  where o.user_id = v_me for update;
  select d.preferences, private.zyra_current_sect_third_key(d.sect, d.sect_other)
    into v_ch2, v_third_sect_key
  from public.seeker_details d
  where d.user_id = v_me for update;

  -- Q113 admits any current state of a displayed or setup control. A
  -- hidden Chapter 4 option must be in the caller's separate affected list.
  for v_control in
    select i.question_id, i.option_value, i.light, c.chapter, c.path
    from jsonb_to_recordset(p_items) i(question_id text, option_value text, light text)
    left join private.zyra_preference_light_controls(v_gender, v_third_sect_key) c
      on c.question_id = i.question_id and c.option_value = i.option_value
  loop
    if v_control.chapter is null or (v_control.chapter = 4
       and not private.zyra_preference_control_visible(v_gender, v_answers,
         v_control.chapter, v_control.question_id, v_control.option_value)
       and not exists (
         select 1 from public.zyra_my_lights_needed_for_compatibility() h
         where h.question_id = v_control.question_id and h.option_value = v_control.option_value
       )) then
      raise exception using errcode = '22023', message = 'invalid_preference_lights';
    end if;
    v_light := v_control.light;
    if v_control.chapter = 4 then
      if jsonb_typeof(v_ch4) is distinct from 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      v_block := coalesce(v_ch4 -> v_control.question_id, '{}'::jsonb);
      if jsonb_typeof(v_block) <> 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      v_block := v_block || jsonb_build_object(v_control.option_value, v_light);
      v_ch4 := jsonb_set(v_ch4, array[v_control.question_id], v_block);
      v_ch4_changed := true;
    else
      if jsonb_typeof(v_ch2) is distinct from 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      v_block := coalesce(v_ch2 -> v_control.path[1], '{}'::jsonb);
      if v_control.question_id = 'ch2.sect.matrix' and v_block = 'null'::jsonb then
        v_block := '{}'::jsonb;
      end if;
      if jsonb_typeof(v_block) <> 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      if cardinality(v_control.path) = 3 then
        v_matrix := coalesce(nullif(v_block -> 'matrix', 'null'::jsonb), '{}'::jsonb);
        if jsonb_typeof(v_matrix) <> 'object' then
          raise exception using errcode = '22023', message = 'invalid_preference_lights';
        end if;
        v_block := jsonb_set(v_block, array['matrix'],
          v_matrix || jsonb_build_object(v_control.path[3], v_light));
      else
        v_block := v_block || jsonb_build_object(v_control.path[2], v_light);
      end if;
      v_ch2 := jsonb_set(v_ch2, array[v_control.path[1]], v_block);
      v_ch2_changed := true;
    end if;
  end loop;

  perform set_config('zyra.confirm_preference_lights', 'on', true);
  insert into public.preference_light_confirmations (user_id, question_id, option_value, light, confirmed_at)
  -- Refresh a matching legacy setup receipt in place. Its identity forms
  -- part of the existing score hash, which a same-value save must preserve.
  select v_me, coalesce(prior.question_id, i.question_id),
    coalesce(prior.option_value, i.option_value), i.light, statement_timestamp()
  from jsonb_to_recordset(p_items) i(question_id text, option_value text, light text)
  left join public.preference_light_confirmations prior
    on prior.user_id = v_me and prior.light = i.light and (
      (i.question_id = 'ch2.sect.matrix' and prior.question_id = 'sect'
        and prior.option_value = i.option_value)
      or (i.option_value = '*' and prior.option_value = 'flexibility'
        and prior.question_id in ('revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages')
        and i.question_id = 'ch2.' || prior.question_id || '.flexibility')
    )
  on conflict (user_id, question_id, option_value) do update
  set light = excluded.light, confirmed_at = excluded.confirmed_at;

  if v_ch4_changed then
    update public.onboarding_answers set ch4_preferences = v_ch4 where user_id = v_me;
  end if;
  if v_ch2_changed then
    update public.seeker_details set preferences = v_ch2 where user_id = v_me;
  end if;
  perform set_config('zyra.confirm_preference_lights', coalesce(v_previous_flag, ''), true);
end;
$$;


--
-- Name: zyra_consider_match_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_consider_match_code(p_code text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_preview_name text;
  v_match_exists boolean := false;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  -- Re-run the complete preview boundary at mutation time. A prior preview is
  -- never authority: the code, block state, verification or eligibility may
  -- have changed before the member presses Consider.
  select preview.owner_first_name
    into v_preview_name
  from public.zyra_preview_match_code(p_code) preview;
  if v_preview_name is null then return null; end if;

  select c.owner_id into v_owner
  from private.zyra_personal_codes c
  join public.profiles p
    on p.id = c.owner_id
   and p.role = c.role_context
  where c.code = v_code
    and c.role_context = 'seeker';

  if v_owner is null
     or v_owner = v_me
     or not private.zyra_identity_verification_allows_user(v_owner)
     or not public.zyra_can_view_profile(v_owner)
     or not public.zyra_can_match(v_me, v_owner) then
    return null;
  end if;

  insert into public.likes(liker_id, liked_id)
  values (v_me, v_owner)
  on conflict (liker_id, liked_id) do nothing;

  select exists (
    select 1
    from public.matches m
    where (m.seeker_a_id = least(v_me, v_owner)
       and m.seeker_b_id = greatest(v_me, v_owner))
  ) into v_match_exists;

  return case when v_match_exists then 'matched' else 'considered' end;
end;
$$;


--
-- Name: FUNCTION zyra_consider_match_code(p_code text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_consider_match_code(p_code text) IS 'Creates the caller''s ordinary Consider for an eligible Seeker resolved by permanent ZYRA Code. Rechecks the full preview boundary at mutation time and does not create a Match without an existing reciprocal Consider.';


--
-- Name: zyra_counterpart_card(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_counterpart_card(p_match_id uuid) RETURNS TABLE(counterpart_first_name text, counterpart_age integer, guardian_first_name text, guardian_surname_line text, guardian_contact text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  with m as (
    select mm.* from public.matches mm
    where mm.id = p_match_id and mm.status <> 'potential'
      and mm.end_reason is distinct from 'safety_concern'
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
           or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
      )
  ), mine as (
    select w.seeker_id as my_ward
    from m join public.wali_links w
      on w.wali_id = (select auth.uid()) and w.status = 'active'
     and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
    where exists (
      select 1 from public.journey_attempts a
      where a.match_id = m.id and a.status = 'active'
        and (w.is_main is true or exists (
          select 1 from public.journey_guardian_assignments jga
          where jga.attempt_id = a.id and jga.wali_link_id = w.id
            and jga.seeker_id = w.seeker_id and jga.revoked_at is null
            and jga.granted_at >= w.active_since
        ))
    )
    limit 1
  ), other as (
    select case when mine.my_ward = m.seeker_a_id then m.seeker_b_id
                else m.seeker_a_id end as other_seeker
    from m, mine
  )
  select p.first_name, date_part('year', age(p.date_of_birth))::int,
         g.first_name, g.surname_line, null::text
  from other join public.profiles p on p.id = other.other_seeker
  left join public.wali_links ow
    on ow.seeker_id = other.other_seeker and ow.status = 'active' and ow.is_main is true
  left join public.profiles g on g.id = ow.wali_id;
$$;


--
-- Name: FUNCTION zyra_counterpart_card(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_counterpart_card(p_match_id uuid) IS 'Restricted counterpart identity card for an authorised Guardian Journey participant. Main participates by role; Additional participates only while the owning Seeker includes them in that active Journey.';


--
-- Name: zyra_create_first_attempt(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_create_first_attempt() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  insert into public.journey_attempts
    (match_id, attempt_number, status, journey_stage, started_at, created_at)
  values (new.id, 1, new.status, new.journey_stage,
          case when new.status = 'active' then now() end, now())
  on conflict (match_id, attempt_number) do nothing;
  return new;
end $$;


--
-- Name: FUNCTION zyra_create_first_attempt(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_create_first_attempt() IS 'Maintains V3 §2''s invariant: a match always has attempt 1. Without this, stage 3 would re-point nine tables at attempts that do not exist.';


--
-- Name: zyra_create_guardian_invitation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_create_guardian_invitation() RETURNS TABLE(token text, expires_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_seeker uuid := (select auth.uid());
  v_due public.wali_invites%rowtype;
  v_created_at timestamptz;
  v_active_count integer;
  v_pending_count integer;
  v_token text;
begin
  if v_seeker is null then raise exception 'not_signed_in'; end if;
  if not exists (
    select 1 from public.profiles p where p.id = v_seeker and p.role = 'seeker'
  ) then
    raise exception 'seeker_required';
  end if;

  -- Resolve old invitations in the same lock order as acceptance: invite
  -- rows before the Seeker guard. The stored deadline determines expiry.
  for v_due in
    select wi.* from public.wali_invites wi
    where wi.inviter_id = v_seeker and wi.source = 'legacy_code'
      and wi.status = 'pending' and wi.expires_at <= clock_timestamp()
    order by coalesce(wi.request_expires_at, wi.expires_at), wi.id
  loop
    perform public.expire_wali_invite_if_due(v_due);
  end loop;

  insert into private.zyra_guardian_invite_accept_guards as guard (seeker_id, revision)
  values (v_seeker, 1)
  on conflict (seeker_id) do update set revision = guard.revision + 1;

  v_created_at := clock_timestamp();
  select capacity.active_count into v_active_count
  from private.zyra_guardian_invite_capacity(v_seeker, null, v_created_at) capacity;
  select count(*) into v_pending_count from public.wali_invites wi
  where wi.inviter_id = v_seeker and wi.source = 'legacy_code'
    and wi.status = 'pending' and wi.expires_at > v_created_at;
  if v_active_count + v_pending_count >= 10 then
    raise exception 'guardian_limit';
  end if;

  loop
    v_token := private.zyra_generate_personal_code();
    insert into public.wali_invites as wi (
      token, inviter_id, inviter_role, created_at, expires_at,
      issued_by_guardian_invitation_rpc
    )
    values (
      v_token, v_seeker, 'seeker', v_created_at,
      v_created_at + interval '14 days', true
    )
    on conflict on constraint wali_invites_token_key do nothing
    returning wi.token, wi.expires_at into token, expires_at;
    exit when found;
  end loop;

  return next;
end;
$$;


--
-- Name: zyra_create_profile(text, text, text, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_create_profile(p_role text, p_first_name text, p_gender text, p_dob date) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_me       uuid := auth.uid();
  v_existing record;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  -- 'admin' is deliberately unreachable here even though the column CHECK
  -- permits it. If an admin role is ever needed it will be granted by an
  -- operator, never claimed by a client.
  IF p_role NOT IN ('seeker','wali') THEN
    RAISE EXCEPTION 'invalid_role' USING HINT = 'seeker or wali';
  END IF;
  IF p_gender NOT IN ('male','female') THEN
    RAISE EXCEPTION 'invalid_gender';
  END IF;
  IF p_first_name IS NULL OR btrim(p_first_name) = '' THEN
    RAISE EXCEPTION 'first_name_required';
  END IF;
  IF char_length(p_first_name) > 60 THEN
    RAISE EXCEPTION 'first_name_too_long';
  END IF;
  -- Checked here as well as by the constraint, so the client gets a named
  -- error rather than a raw constraint violation.
  IF p_dob IS NULL OR p_dob > (current_date - interval '18 years') THEN
    RAISE EXCEPTION 'must_be_18';
  END IF;

  SELECT role, profile_complete, first_published_at
    INTO v_existing
    FROM public.profiles WHERE id = v_me;

  IF v_existing IS NULL THEN
    INSERT INTO public.profiles (id, role, first_name, gender, date_of_birth)
    VALUES (v_me, p_role, btrim(p_first_name), p_gender, p_dob);
    RETURN jsonb_build_object('status','created');
  END IF;

  -- EVER published: identity is frozen, permanently. Was
  -- `v_existing.profile_complete`, which meant "published RIGHT NOW" and
  -- so could be turned off first. Name stays editable through the ordinary
  -- column grant, so this is not a dead end for someone fixing a typo —
  -- only for someone changing who they are.
  --
  -- A genuine correction (a mistyped birth year) has no self-service route
  -- by design and is a support case. Founder 2026-08-07.
  IF v_existing.first_published_at IS NOT NULL THEN
    UPDATE public.profiles SET first_name = btrim(p_first_name) WHERE id = v_me;
    RETURN jsonb_build_object('status','name_only','reason','identity_frozen');
  END IF;

  -- Never published: everything is still correctable, but role never flips.
  UPDATE public.profiles
     SET first_name    = btrim(p_first_name),
         gender        = p_gender,
         date_of_birth = p_dob
   WHERE id = v_me;
  RETURN jsonb_build_object('status','updated');
END;
$$;


--
-- Name: zyra_dashboard_updates(integer, timestamp with time zone, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_dashboard_updates(p_limit integer DEFAULT 3, p_cursor_occurred_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_cursor_class_key text DEFAULT NULL::text, p_cursor_source_id uuid DEFAULT NULL::uuid) RETURNS TABLE(occurred_at timestamp with time zone, class_key text, source_id uuid, title_key text, detail_key text, destination_key text, related_match_id uuid, is_unread boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_limit integer := greatest(1, least(coalesce(p_limit, 3), 20));
  v_cursor_parts integer :=
    (p_cursor_occurred_at is not null)::integer
    + (p_cursor_class_key is not null)::integer
    + (p_cursor_source_id is not null)::integer;
begin
  if v_cursor_parts not in (0, 3) then
    raise exception 'dashboard_updates_cursor_incomplete'
      using errcode = '22023';
  end if;

  if v_caller is null then
    return;
  end if;

  return query
  with
  notification_templates(
    notification_type,
    title_key,
    detail_key,
    destination_key,
    audience_kind
  ) as (
    values
      ('new_message'::text,
       'dashboard_updates.notification.new_message.title',
       'dashboard_updates.notification.new_message.detail',
       'notifications'::text,
       'seeker_match'::text),
      ('wali_request',
       'dashboard_updates.notification.wali_request.title',
       'dashboard_updates.notification.wali_request.detail',
       'notifications',
       'direct_recipient'),
      ('journey_request',
       'dashboard_updates.notification.journey_request.title',
       'dashboard_updates.notification.journey_request.detail',
       'notifications',
       'seeker_match'),
      ('journey_request_declined',
       'dashboard_updates.notification.journey_request_declined.title',
       'dashboard_updates.notification.journey_request_declined.detail',
       'notifications',
       'seeker_match'),
      ('pause_nudge',
       'dashboard_updates.notification.pause_nudge.title',
       'dashboard_updates.notification.pause_nudge.detail',
       'notifications',
       'seeker_match'),
      ('journey_also_paused',
       'dashboard_updates.notification.journey_also_paused.title',
       'dashboard_updates.notification.journey_also_paused.detail',
       'notifications',
       'seeker_match'),
      ('wali_invite_received',
       'dashboard_updates.notification.wali_invite_received.title',
       'dashboard_updates.notification.wali_invite_received.detail',
       'notifications',
       'direct_recipient'),
      ('wali_invite_declined',
       'dashboard_updates.notification.wali_invite_declined.title',
       'dashboard_updates.notification.wali_invite_declined.detail',
       'notifications',
       'direct_recipient'),
      ('wali_invite_expiring',
       'dashboard_updates.notification.wali_invite_expiring.title',
       'dashboard_updates.notification.wali_invite_expiring.detail',
       'notifications',
       'direct_recipient'),
      ('wali_invite_expired',
       'dashboard_updates.notification.wali_invite_expired.title',
       'dashboard_updates.notification.wali_invite_expired.detail',
       'notifications',
       'direct_recipient'),
      ('wali_invite_revoked',
       'dashboard_updates.notification.wali_invite_revoked.title',
       'dashboard_updates.notification.wali_invite_revoked.detail',
       'notifications',
       'direct_recipient'),
      -- A proposal has no Timeline row yet, so notification is the canonical
      -- representation until the other Seeker confirms it.
      ('milestone_proposed',
       'dashboard_updates.notification.milestone_proposed.title',
       'dashboard_updates.notification.milestone_proposed.detail',
       'notifications',
       'seeker_match')
  ),
  milestone_templates(milestone_type, title_key, detail_key) as (
    values
      ('liked'::text,
       'dashboard_updates.journey.timeline_milestone.title'::text,
       'dashboard_updates.journey.timeline_milestone.liked.detail'::text),
      ('match_created',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.match_created.detail'),
      ('journey_started',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.journey_started.detail'),
      ('compatibility_revealed',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.compatibility_revealed.detail'),
      ('salam_exchanged',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.salam_exchanged.detail'),
      ('guardian_linked',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.guardian_linked.detail'),
      ('phase_1_complete',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.phase_1_complete.detail'),
      ('phase_2_complete',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.phase_2_complete.detail'),
      ('phase_3_complete',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.phase_3_complete.detail'),
      ('family_stage',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.family_stage.detail'),
      ('conversation_started',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.conversation_started.detail'),
      ('journey_paused',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.journey_paused.detail'),
      ('journey_continued',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.journey_continued.detail'),
      ('journey_ended',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.journey_ended.detail'),
      ('meeting',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.meeting.detail'),
      ('nikah',
       'dashboard_updates.journey.timeline_milestone.title',
       'dashboard_updates.journey.timeline_milestone.nikah.detail')
  ),
  caller_participation as materialized (
    select
      p.attempt_id,
      p.match_id,
      p.role,
      p.is_main,
      p.attempt_status
    from public.zyra_my_attempt_participation p
  ),
  notification_rows as (
    select
      n.created_at as occurred_at,
      ('notification.' || nt.notification_type)::text as class_key,
      n.id as source_id,
      nt.title_key,
      nt.detail_key,
      nt.destination_key,
      n.related_match_id,
      true as is_unread
    from public.notifications n
    join notification_templates nt on nt.notification_type = n.type
    where n.user_id = v_caller
      and n.read_at is null
      and n.created_at is not null
      and (
        nt.audience_kind = 'direct_recipient'
        or (
          nt.audience_kind = 'seeker_match'
          and n.related_match_id is not null
          and exists (
            select 1
            from caller_participation cp
            where cp.match_id = n.related_match_id
              and cp.role = 'seeker'
          )
        )
      )
  ),
  milestone_rows as (
    select
      tm.occurred_at,
      'journey.timeline_milestone'::text as class_key,
      tm.id as source_id,
      mt.title_key,
      mt.detail_key,
      'connections.journeys'::text as destination_key,
      t.match_id as related_match_id,
      null::boolean as is_unread
    from public.timeline_milestones tm
    join milestone_templates mt on mt.milestone_type = tm.milestone_type
    join public.timelines t on t.id = tm.timeline_id
    where tm.occurred_at is not null
      and t.attempt_id is not null
      and t.match_id is not null
      and exists (
        select 1
        from caller_participation cp
        where cp.attempt_id = t.attempt_id
          and cp.match_id = t.match_id
          and (
            cp.role = 'seeker'
            or (
              cp.role = 'guardian'
              and cp.is_main is true
              and cp.attempt_status <> 'potential'
            )
          )
      )
  ),
  suggestion_rows as (
    select
      s.created_at as occurred_at,
      'guardian.suggestion'::text as class_key,
      s.id as source_id,
      'dashboard_updates.guardian.suggestion.title'::text as title_key,
      'dashboard_updates.guardian.suggestion.detail'::text as detail_key,
      'guardian'::text as destination_key,
      null::uuid as related_match_id,
      null::boolean as is_unread
    from public.wali_suggestions s
    where s.created_at is not null
      -- The current app exposes pending suggestions to the Seeker only.
      -- Guardian-side suggestion creation/history UI remains unbuilt, so a
      -- Guardian author row is not audience authority for this projection.
      and s.seeker_id = v_caller
  ),
  review_opened_rows as (
    select
      r.opened_at as occurred_at,
      'guardian.review_opened'::text as class_key,
      r.id as source_id,
      'dashboard_updates.guardian.review_opened.title'::text as title_key,
      'dashboard_updates.guardian.review_opened.detail'::text as detail_key,
      'connections.journeys'::text as destination_key,
      r.match_id as related_match_id,
      null::boolean as is_unread
    from public.journey_family_reviews r
    where r.opened_at is not null
      and r.attempt_id is not null
      and r.match_id is not null
      and exists (
        select 1
        from caller_participation cp
        where cp.attempt_id = r.attempt_id
          and cp.match_id = r.match_id
          and (
            cp.role = 'seeker'
            or (cp.role = 'guardian' and cp.is_main is true)
          )
      )
  ),
  review_answered_rows as (
    select
      rr.responded_at as occurred_at,
      'guardian.review_answered'::text as class_key,
      -- Deterministic pseudonymous key derived from the composite primary key;
      -- it is stable for pagination and is not an anonymity guarantee.
      md5(rr.review_id::text || ':' || rr.wali_id::text)::uuid as source_id,
      'dashboard_updates.guardian.review_answered.title'::text as title_key,
      'dashboard_updates.guardian.review_answered.detail'::text as detail_key,
      'connections.journeys'::text as destination_key,
      r.match_id as related_match_id,
      null::boolean as is_unread
    from public.journey_family_review_responses rr
    join public.journey_family_reviews r on r.id = rr.review_id
    where rr.responded_at is not null
      and r.attempt_id is not null
      and r.match_id is not null
      and exists (
        select 1
        from caller_participation cp
        where cp.attempt_id = r.attempt_id
          and cp.match_id = r.match_id
          and (
            cp.role = 'seeker'
            or (cp.role = 'guardian' and cp.is_main is true)
          )
      )
  ),
  updates as (
    select * from notification_rows
    union all
    select * from milestone_rows
    union all
    select * from suggestion_rows
    union all
    select * from review_opened_rows
    union all
    select * from review_answered_rows
  )
  select
    u.occurred_at,
    u.class_key,
    u.source_id,
    u.title_key,
    u.detail_key,
    u.destination_key,
    u.related_match_id,
    u.is_unread
  from updates u
  where p_cursor_occurred_at is null
     or (u.occurred_at, u.class_key, u.source_id)
        < (p_cursor_occurred_at, p_cursor_class_key, p_cursor_source_id)
  order by u.occurred_at desc, u.class_key desc, u.source_id desc
  limit v_limit;
end;
$$;


--
-- Name: FUNCTION zyra_dashboard_updates(p_limit integer, p_cursor_occurred_at timestamp with time zone, p_cursor_class_key text, p_cursor_source_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_dashboard_updates(p_limit integer, p_cursor_occurred_at timestamp with time zone, p_cursor_class_key text, p_cursor_source_id uuid) IS 'OA-ZYRA-281: caller-scoped, allowlisted, read-only meaningful-movement projection — unread-backed notifications + authoritative domain events; NOT an inbox or history; the Notifications manager is the history surface. is_unread is three-state: TRUE means an unread notification; FALSE is reserved for a future explicit read-notification projection; NULL means a domain event and must never be rendered as read.';


--
-- Name: zyra_decline_guardian_request(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_decline_guardian_request(p_request_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_requester uuid;
  v_name text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  update public.wali_invites wi
     set status = 'declined', declined_by = v_me, declined_at = clock_timestamp()
   where wi.id = p_request_id and wi.source = 'personal_code'
     and wi.inviter_id = v_me and wi.status = 'pending'
     and wi.request_expires_at > clock_timestamp()
  returning wi.recipient_id into v_requester;
  if v_requester is null then return false; end if;
  select p.first_name into v_name from public.profiles p where p.id = v_me;
  perform private.zyra_create_notification(
    v_requester, 'wali_request', 'Guardian request declined',
    coalesce(v_name, 'They') || ' declined your Guardian request.', null, v_me, p_request_id, null);
  return true;
end;
$$;


--
-- Name: zyra_decline_wali_invite(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_decline_wali_invite(p_token text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
  v_invite public.wali_invites%rowtype;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select * into v_invite
    from public.wali_invites wi
   where wi.token = upper(trim(p_token));
  if not found then raise exception 'invite_not_found'; end if;
  if v_invite.inviter_id = v_me then raise exception 'cannot_decline_own_invite'; end if;

  if v_invite.status = 'declined' and v_invite.declined_by = v_me then
    return true;
  end if;
  if public.expire_wali_invite_if_due(v_invite) = 'expired' then
    raise exception 'invite_expired';
  end if;
  if v_invite.status <> 'pending' then raise exception 'invite_not_pending'; end if;

  update public.wali_invites
     set status = 'declined',
         declined_by = v_me,
         declined_at = clock_timestamp(),
         seen_by = coalesce(seen_by, v_me),
         seen_at = coalesce(seen_at, clock_timestamp())
   where id = v_invite.id and status = 'pending';
  if not found then raise exception 'invite_not_pending'; end if;

  perform private.zyra_create_notification(
    v_invite.inviter_id,
    'wali_invite_declined',
    'Guardian invitation declined',
    case when v_invite.label is null
      then 'Your Guardian invitation was declined.'
      else v_invite.label || ' declined your Guardian invitation.'
    end, null, v_me, v_invite.id, null);
  return true;
end;
$$;


--
-- Name: zyra_delete_my_unstarted_identity_verification_attempt(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_delete_my_unstarted_identity_verification_attempt() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'private'
    AS $$
declare
  v_me uuid := auth.uid();
  v_id uuid;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  select id into v_id
  from private.identity_verification_attempts
  where user_id = v_me
    and member_deleted_at is null
    and provider_session_ref is null
    and result in ('pending', 'retry_required', 'failed', 'expired', 'cancelled')
  order by created_at desc
  limit 1
  for update;

  if v_id is null then return false; end if;

  update private.identity_verification_attempts
     set member_deleted_at = now(),
         result = 'cancelled',
         decided_at = coalesce(decided_at, now())
   where id = v_id;
  return true;
end;
$$;


--
-- Name: zyra_discover_profile_ids(integer, integer, text, integer, text, text[], text[], integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_discover_profile_ids(p_age_min integer DEFAULT 18, p_age_max integer DEFAULT NULL::integer, p_location text DEFAULT 'worldwide'::text, p_distance_km integer DEFAULT NULL::integer, p_country text DEFAULT NULL::text, p_nationalities text[] DEFAULT '{}'::text[], p_ethnicities text[] DEFAULT '{}'::text[], p_limit integer DEFAULT 50, p_after uuid DEFAULT NULL::uuid) RETURNS TABLE(profile_id uuid, one_filters_applied boolean, location_applied boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_one boolean := public.zyra_has_paid_role((select auth.uid()), 'seeker');
  v_caller uuid := (select auth.uid());
  v_gender text;
  v_home_lat double precision;
  v_home_lon double precision;
  v_country text;
  v_location text := coalesce(p_location, 'worldwide');
  v_location_applied boolean;
  v_nationalities text[] := coalesce(p_nationalities, '{}');
  v_ethnicities text[] := coalesce(p_ethnicities, '{}');
  v_one_filters_applied boolean;
begin
  select viewer.gender, home.lat, home.lon,
         coalesce(p_country, home.country_code)
  into v_gender, v_home_lat, v_home_lon, v_country
  from public.profiles viewer
  left join private.seeker_home_places home on home.user_id = viewer.id
  where viewer.id = v_caller and viewer.role = 'seeker' and viewer.is_active;
  if not found then
    return;
  end if;

  if v_location not in ('near', 'country', 'worldwide') then
    raise exception using errcode = '22023', message = 'invalid_discovery_location';
  end if;
  v_location_applied := v_location = 'country' or
    (v_location = 'near' and v_home_lat is not null and v_home_lon is not null);
  if v_location = 'near' and v_location_applied
     and (p_distance_km is null or p_distance_km not between 5 and 500) then
    raise exception using errcode = '22023', message = 'invalid_discovery_distance';
  end if;
  v_one_filters_applied := v_one and (
    pg_catalog.cardinality(v_nationalities) > 0 or pg_catalog.cardinality(v_ethnicities) > 0
  );

  return query
  with eligible as materialized (
    select candidate.id
    from public.profiles candidate
    left join public.seeker_details details on details.user_id = candidate.id
    left join private.seeker_home_places home on home.user_id = candidate.id
    cross join lateral (
      select extract(year from pg_catalog.age(current_date, candidate.date_of_birth))::int as years
    ) age
    where candidate.id <> v_caller
      and candidate.role = 'seeker'
      and candidate.gender <> v_gender
      and candidate.is_active
      and candidate.profile_complete
      and not exists (
        select 1 from public.profile_hides hide
        where (hide.hider = v_caller and hide.hidden = candidate.id)
           or (hide.hider = candidate.id and hide.hidden = v_caller)
      )
      and not public.zyra_block_exists(candidate.id)
      and public.zyra_can_view_profile(candidate.id)
      and exists (
        select 1 from public.profile_photos photo
        where photo.user_id = candidate.id
          and public.zyra_can_read_photo_object(photo.storage_path)
      )
      and age.years >= greatest(coalesce(p_age_min, 18), 18)
      and (p_age_max is null or age.years <= p_age_max)
      and (not v_one or pg_catalog.cardinality(v_nationalities) = 0
           or details.nationality = any(v_nationalities))
      and (not v_one or pg_catalog.cardinality(v_ethnicities) = 0
           or details.ethnicity = any(v_ethnicities))
      and case
        when not v_location_applied then true
        when v_location = 'country' then home.country_code = v_country
        when home.lat is null or home.lon is null then false
        else
          2.0 * 6371.0 * pg_catalog.asin(pg_catalog.sqrt(least(1.0,
            pg_catalog.power(pg_catalog.sin(pg_catalog.radians(home.lat - v_home_lat) / 2.0), 2)
            + pg_catalog.cos(pg_catalog.radians(v_home_lat))
              * pg_catalog.cos(pg_catalog.radians(home.lat))
              * pg_catalog.power(pg_catalog.sin(pg_catalog.radians(home.lon - v_home_lon) / 2.0), 2)
          ))) <= p_distance_km
      end
  ), ranked as materialized (
    -- The existing Browse scorer suppresses hard-requirement failures and
    -- ranks scored candidates above unscored candidates. Keep scores internal.
    -- A UUID tie-break makes the formerly unordered source ties pageable.
    select scored.candidate_id as id, -coalesce(scored.score, -1) as sort_score
    from public.score_candidates(array(select e.id from eligible e)) scored
  ), cursor_row as (
    select r.id, r.sort_score from ranked r where r.id = p_after
  )
  select r.id, v_one_filters_applied, v_location_applied
  from ranked r
  where p_after is null or exists (
    select 1 from cursor_row c where (r.sort_score, r.id) > (c.sort_score, c.id)
  )
  order by r.sort_score, r.id
  limit least(greatest(coalesce(p_limit, 50), 0), 50);
end;
$$;


--
-- Name: zyra_end_match_internal(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_end_match_internal(p_match_id uuid, p_ended_by uuid, p_reason text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE m RECORD; v_attempt UUID; v_timeline_id UUID; v_other UUID; v_ender_name TEXT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND OR m.status = 'ended' THEN RETURN; END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY a.attempt_number DESC LIMIT 1;

  UPDATE matches
     SET status='ended', ended_at=NOW(), ended_by=p_ended_by,
         end_reason=p_reason, suspended_by=NULL, suspended_at=NULL
   WHERE id = p_match_id;

  UPDATE journey_attempts
     SET status='ended', ended_at=NOW(), ended_by=p_ended_by,
         end_reason=p_reason, paused_by=NULL, paused_at=NULL
   WHERE match_id = p_match_id AND status <> 'ended';

  -- Re-pointed onto the attempt.
  UPDATE conversations SET status='closed', closed_at=NOW()
   WHERE (v_attempt IS NOT NULL AND attempt_id = v_attempt) AND status <> 'closed';

  SELECT id INTO v_timeline_id FROM timelines
   WHERE (v_attempt IS NOT NULL AND attempt_id = v_attempt);
  -- GUARDED 2026-08-12: the matches UPDATE above fires
  -- matches_record_journey_milestone, which usually writes this milestone
  -- first. Both writers now check, so exactly one row lands either way.
  IF v_timeline_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM timeline_milestones
       WHERE timeline_id = v_timeline_id AND milestone_type = 'journey_ended') THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline_id, 'journey_ended');
  END IF;

  -- UNCHANGED — OPTION B. The person who ended it is not told; they know.
  -- SEEKERS ONLY: the body carries the counterpart's name, and after
  -- Step 1 a Guardian may not be entitled to it. Notifying them would
  -- push a name through a channel the visibility rules do not govern.
  IF p_ended_by IS NOT NULL THEN
    v_other := CASE WHEN m.seeker_a_id = p_ended_by THEN m.seeker_b_id ELSE m.seeker_a_id END;
    SELECT first_name INTO v_ender_name FROM profiles WHERE id = p_ended_by;
    PERFORM create_notification(
      v_other, 'journey_ended', 'Journey ended',
      'Your Journey with ' || COALESCE(v_ender_name,'someone') || ' has ended.',
      p_match_id);
  END IF;
END; $$;


--
-- Name: FUNCTION zyra_end_match_internal(p_match_id uuid, p_ended_by uuid, p_reason text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_end_match_internal(p_match_id uuid, p_ended_by uuid, p_reason text) IS 'THE only way a Journey ends. Ordinary endings and block-endings both go through here so their observable artefacts are byte-identical and differ only in end_reason, which zyra_match_ending() conceals. Do not add a second ending path — a difference between two paths is a disclosure channel. NOT client-callable: p_ended_by would be forgeable.';


--
-- Name: zyra_enforce_family_seat_capacity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_enforce_family_seat_capacity() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_family uuid;
  v_seekers integer;
  v_guardians integer;
begin
  v_family := case when tg_op = 'DELETE'
    then old.family_subscription_id
    else new.family_subscription_id
  end;
  perform pg_advisory_xact_lock(hashtextextended(v_family::text, 0));
  select family.seeker_places, family.guardian_places
  into v_seekers, v_guardians
  from public.family_subscriptions family
  where family.id = v_family
  for update;

  if (
    select count(*)
    from public.family_seat_assignments seat
    where seat.family_subscription_id = v_family
      and seat.role = 'seeker'
      and (seat.removed_at is null or seat.funded_until > now())
  ) > v_seekers then
    raise exception 'family_seeker_capacity_exceeded';
  end if;
  if (
    select count(*)
    from public.family_seat_assignments seat
    where seat.family_subscription_id = v_family
      and seat.role = 'guardian'
      and (seat.removed_at is null or seat.funded_until > now())
  ) > v_guardians then
    raise exception 'family_guardian_capacity_exceeded';
  end if;
  return null;
end;
$$;


--
-- Name: zyra_enforce_guardian_link_allowed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_enforce_guardian_link_allowed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  -- A link being retired is always permitted. The rule guards the creation
  -- of a bond, not its ending — and blocking removal would strand people.
  IF NEW.status = 'removed' THEN
    RETURN NEW;
  END IF;

  IF NOT private.zyra_can_guardian_link_pair(NEW.seeker_id, NEW.wali_id) THEN
    RAISE EXCEPTION 'romantic_edge_exists'
      USING HINT = 'These two people have a Journey together. A Guardian '
                   'relationship cannot be created over one. End the Journey '
                   'first if that is really what you both want.';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: zyra_enforce_main_guardian_journey_hold(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_enforce_main_guardian_journey_hold() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := (select auth.uid());
  v_payload jsonb := to_jsonb(new);
  v_match_id uuid;
  v_attempt_id uuid;
  v_a uuid;
  v_b uuid;
  v_match_status text;
begin
  if v_me is null then
    return new;
  end if;

  if tg_table_name = 'matches' then
    v_match_id := new.id;
  else
    v_match_id := nullif(v_payload ->> 'match_id', '')::uuid;
  end if;
  v_attempt_id := nullif(v_payload ->> 'attempt_id', '')::uuid;

  -- Messages belong to a conversation rather than carrying match_id or
  -- attempt_id directly. Resolve that existing ownership chain explicitly;
  -- never infer Journey identity from a timestamp or sender.
  if tg_table_name = 'messages' then
    select c.attempt_id
      into v_attempt_id
    from public.conversations c
    where c.id = nullif(v_payload ->> 'conversation_id', '')::uuid;
  end if;

  if v_match_id is null and v_attempt_id is not null then
    select a.match_id into v_match_id
    from public.journey_attempts a
    where a.id = v_attempt_id;
  end if;

  if v_match_id is null then
    raise exception 'journey_guardian_gate_context_missing';
  end if;

  select m.seeker_a_id, m.seeker_b_id, m.status
    into v_a, v_b, v_match_status
  from public.matches m
  where m.id = v_match_id;

  if not found or v_me not in (v_a, v_b) then
    return new;
  end if;

  -- A BEFORE UPDATE reads the old pair row. Use the proposed lifecycle for
  -- activation and End so the hold cannot be bypassed by that transition.
  if tg_table_name = 'matches' then
    v_match_status := new.status;
  end if;

  -- The Founder ruling holds Active Journey participation only. Existing
  -- protections continue to govern potential and ended records.
  if v_match_status is distinct from 'active' then
    return new;
  end if;

  if not exists (
      select 1 from public.wali_links w
      where w.seeker_id = v_a
        and w.status = 'active'
        and w.is_main is true
    ) or not exists (
      select 1 from public.wali_links w
      where w.seeker_id = v_b
        and w.status = 'active'
        and w.is_main is true
    ) then
    raise exception 'main_guardian_required_for_journey'
      using hint = 'Ordinary Journey participation is held until both '
                   'Seekers have an active Main Guardian. End '
                   'remain available.';
  end if;

  return new;
end;
$$;


--
-- Name: FUNCTION zyra_enforce_main_guardian_journey_hold(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_enforce_main_guardian_journey_hold() IS 'DR-ZYRA-236 trigger boundary. Blocks ordinary shared-Journey writes and activation while either Seeker lacks an active Main Guardian. It does not block End.';


--
-- Name: zyra_enforce_one_active_attempt(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_enforce_one_active_attempt() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_a uuid;
  v_b uuid;
  v_party uuid;
begin
  -- A paused attempt (paused_by set) is not in the Active pool.
  if new.status <> 'active' or new.paused_by is not null then
    return null;
  end if;

  select m.seeker_a_id, m.seeker_b_id into v_a, v_b
  from public.matches m where m.id = new.match_id;

  -- Serialise on the participants, in a stable order so two transactions
  -- touching the same pair can never deadlock against each other.
  perform pg_advisory_xact_lock(hashtextextended(least(v_a,v_b)::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(greatest(v_a,v_b)::text, 0));

  foreach v_party in array array[v_a, v_b] loop
    if (select count(*) from public.journey_attempts a
          join public.matches m on m.id = a.match_id
        where a.status = 'active'
          and a.paused_by is null
          and a.id <> new.id
          and (m.seeker_a_id = v_party or m.seeker_b_id = v_party)
       ) >= zyra_active_journey_cap(v_party) then
      raise exception 'one_active_journey_limit'
        using hint = 'One of you is at their plan''s Active Journey limit. End or pause one first.';
    end if;
  end loop;

  return null;
end $$;


--
-- Name: FUNCTION zyra_enforce_one_active_attempt(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_enforce_one_active_attempt() IS 'LIVE as of 2026-08-08 step 5 — promote now sets an attempt to active, so this fires. Runs alongside zyra_enforce_one_active_match() on matches; both raise one_active_journey_limit. The matches one retires at step 7.';


--
-- Name: zyra_enforce_one_active_match(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_enforce_one_active_match() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare v_party uuid;
begin
  -- A paused row (suspended_by set) is not in the Active pool — being
  -- paused, or being updated while paused, needs no cap check.
  if new.status <> 'active' or new.suspended_by is not null then
    return null;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(least(new.seeker_a_id, new.seeker_b_id)::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(greatest(new.seeker_a_id, new.seeker_b_id)::text, 0));

  -- Each party against THEIR OWN plan's cap (Basic 1 / One 3). The count
  -- excludes this row, so entering the pool is refused exactly when the
  -- party already stands at their cap.
  foreach v_party in array array[new.seeker_a_id, new.seeker_b_id] loop
    if zyra_active_journey_count(v_party, new.id) >= zyra_active_journey_cap(v_party) then
      raise exception 'one_active_journey_limit'
        using hint = 'One of you is at their plan''s Active Journey limit. End or pause one first.';
    end if;
  end loop;

  return null;
end $$;


--
-- Name: FUNCTION zyra_enforce_one_active_match(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_enforce_one_active_match() IS 'One Active Journey per PERSON — the platform invariant. The two per-side partial indexes cannot express it; this can. Kept alongside them, not instead of. Moves to journey_attempts at step 7, once an attempt''s status is actually maintained.';


--
-- Name: zyra_expire_due_journey_requests(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION private.zyra_close_expired_journey_requests(p_match_id uuid, p_member_id uuid) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  request_row record;
  v_count integer := 0;
begin
  for request_row in
    select request.*
    from public.journey_requests request
    join public.matches match on match.id = request.match_id
    where request.status = 'pending'
      and request.expires_at <= now()
      and (p_match_id is null or request.match_id = p_match_id)
      and (
        p_member_id is null
        or (
          p_member_id in (request.requested_by, request.requested_to)
          and p_member_id in (match.seeker_a_id, match.seeker_b_id)
        )
      )
    for update of request skip locked
  loop
    update public.journey_requests
    set status = 'declined', responded_at = now(), closed_reason = 'expired'
    where id = request_row.id;

    -- Expiry is not a decline: no decline cooldown is created.

    perform public.create_notification(
      request_row.requested_by,
      'journey_request_declined',
      'Journey request',
      'Your request to begin a new Journey was not taken up.',
      request_row.match_id
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

CREATE FUNCTION private.zyra_expire_due_journey_requests_all() RETURNS integer
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
    SELECT private.zyra_close_expired_journey_requests(NULL, NULL);
$$;

CREATE FUNCTION public.zyra_expire_due_journey_requests(p_match_id uuid DEFAULT NULL::uuid) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    caller uuid := auth.uid();
BEGIN
    IF caller IS NULL THEN
        RETURN 0;
    END IF;

    RETURN private.zyra_close_expired_journey_requests(p_match_id, caller);
END;
$$;


--
-- Name: FUNCTION zyra_expire_due_journey_requests(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_expire_due_journey_requests(p_match_id uuid) IS 'Expires due pending requests for the signed-in Seeker. A NULL match ID covers all their Journeys. Expiry creates no decline cooldown.';


--
-- Name: zyra_expire_due_wali_invites(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_expire_due_wali_invites() RETURNS TABLE(expiring_count integer, expired_count integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_invite public.wali_invites%rowtype;
  v_deadline timestamptz;
  v_expiring integer := 0;
  v_expired integer := 0;
  v_label text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;

  for v_invite in
    select wi.*
      from public.wali_invites wi
     where wi.inviter_id = v_me
       and wi.status = 'pending'
     order by coalesce(wi.request_expires_at, wi.expires_at), wi.id
  loop
    v_deadline := coalesce(v_invite.request_expires_at, v_invite.expires_at);
    if v_deadline < clock_timestamp() then
      if public.expire_wali_invite_if_due(v_invite) = 'expired' then
        v_expired := v_expired + 1;
      end if;
    elsif v_deadline <= clock_timestamp() + interval '2 days'
       and v_invite.expiring_notified_at is null then
      update public.wali_invites
         set expiring_notified_at = clock_timestamp()
       where id = v_invite.id
         and status = 'pending'
         and expiring_notified_at is null
       returning label into v_label;

      if found then
        v_expiring := v_expiring + 1;
        perform private.zyra_create_notification(
          v_me,
          'wali_invite_expiring',
          'Guardian invitation expiring',
          case when v_label is null
            then 'A Guardian invitation expires in two days.'
            else v_label || '''s Guardian invitation expires in two days.'
          end, null, null, v_invite.id, null);
      end if;
    end if;
  end loop;

  return query select v_expiring, v_expired;
end;
$$;


--
-- Name: FUNCTION zyra_expire_due_wali_invites(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_expire_due_wali_invites() IS 'Expire invitations and personal-code requests using each stored deadline; warn within two days.';


--
-- Name: zyra_family_formula_monthly_pence(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_formula_monthly_pence(p_seekers integer, p_guardians integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $$
declare
  v_members integer;
  v_discount integer;
  v_gross integer;
begin
  if p_seekers not between 0 and 10
     or p_guardians not between 0 and 10
     or p_seekers + p_guardians = 0 then
    raise exception 'invalid_family_place_count';
  end if;
  v_members := p_seekers + p_guardians;
  v_discount := least(40, greatest(0, (v_members - 2) * 5));
  v_gross := p_seekers * 2999 + p_guardians * 1999;
  return (v_gross * (100 - v_discount) + 50) / 100;
end;
$$;


--
-- Name: zyra_family_message_can_read(uuid, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_message_can_read(p_thread uuid, p_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = p_thread
      and membership.user_id = (select auth.uid())
      and membership.left_at is null
      and (p_created_at is null or p_created_at >= membership.readable_from)
  );
$$;


--
-- Name: zyra_family_message_chats(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_message_chats(p_thread_id uuid) RETURNS TABLE(chat_id uuid, kind text, state text, other_first_name text, last_message_at timestamp with time zone, ended_at timestamp with time zone, unread_count bigint, muted boolean, circle_muted boolean, counts_toward_total boolean, alerts_on boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select c.id, admitted.kind, admitted.state, admitted.other_first_name,
    messages.last_message_at, admitted.ended_at, messages.unread_count,
    local.muted_at is not null, circle.muted_at is not null, local.muted_at is null,
    local.muted_at is null and circle.muted_at is null
  from public.family_message_chats c
  cross join lateral private.zyra_family_chat_admission(c.id) admitted
  left join public.family_message_chat_state local
    on local.chat_id = c.id and local.user_id = (select auth.uid())
  left join public.family_message_participant_state circle
    on circle.thread_id = c.thread_id and circle.user_id = (select auth.uid())
  cross join lateral (
    select max(msg.created_at) as last_message_at,
      count(*) filter (
        where msg.sender_id is distinct from (select auth.uid())
          and msg.created_at > greatest(local.last_read_at, circle.last_read_at, admitted.readable_from)
      ) as unread_count
    from public.family_messages msg
    where msg.chat_id = c.id and msg.kind = 'message' and msg.created_at >= admitted.readable_from
  ) messages
  where c.thread_id = p_thread_id;
$$;


--
-- Name: FUNCTION zyra_family_message_chats(p_thread_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_family_message_chats(p_thread_id uuid) IS 'Raw counts include muted arrivals. Visible Circle totals exclude individually muted chats. alerts_on reflects both mute switches; delivery is decided at arrival.';


--
-- Name: zyra_family_message_circle_can_send(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_message_circle_can_send(p_seeker uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select
    p_seeker is not null
    and public.zyra_has_paid_role(p_seeker, 'seeker')
    and exists (
      select 1 from public.wali_links link
      where link.seeker_id = p_seeker
        and link.status = 'active'
        and not exists (
          select 1 from public.profile_blocks block
          where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
             or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
        )
    )
    and not exists (
      select 1 from public.wali_links link
      where link.seeker_id = p_seeker
        and link.status = 'active'
        and not exists (
          select 1 from public.profile_blocks block
          where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
             or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
        )
        and not public.zyra_has_paid_role(link.wali_id, 'guardian')
    );
$$;


--
-- Name: FUNCTION zyra_family_message_circle_can_send(p_seeker uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_family_message_circle_can_send(p_seeker uuid) IS 'Authoritative circle-scoped family-message entitlement resolver.';


--
-- Name: zyra_family_message_circles(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_message_circles() RETURNS TABLE(thread_id uuid, seeker_id uuid, seeker_first_name text, participant_count bigint, last_message text, last_message_at timestamp with time zone, unread_count bigint, can_send boolean, access_reason text, muted boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select thread.id, thread.seeker_id, profile.first_name,
    (select count(*) from public.family_message_memberships member_count
     where member_count.thread_id = thread.id and member_count.left_at is null),
    latest.body, latest.created_at,
    count(unread.id) filter (where unread.id is not null),
    public.zyra_family_message_circle_can_send(thread.seeker_id),
    case when not exists (
      select 1 from public.family_message_memberships guardian
      where guardian.thread_id = thread.id
        and guardian.member_role = 'guardian' and guardian.left_at is null
    ) then 'link_inactive'
    when public.zyra_family_message_circle_can_send(thread.seeker_id)
      then 'ready' else 'membership_required' end,
    coalesce(state.muted_at is not null, false)
  from public.family_message_threads thread
  join public.profiles profile on profile.id = thread.seeker_id
  join public.family_message_memberships me
    on me.thread_id = thread.id and me.user_id = (select auth.uid())
   and me.left_at is null
  join public.family_message_chats chat on chat.thread_id = thread.id and chat.kind = 'main'
  left join lateral (
    select message.body, message.created_at from public.family_messages message
    where message.chat_id = chat.id
      and message.created_at >= me.readable_from
    order by message.created_at desc, message.id desc limit 1
  ) latest on true
  left join public.family_message_participant_state state
    on state.thread_id = thread.id and state.user_id = (select auth.uid())
  left join public.family_message_chat_state chat_state
    on chat_state.chat_id = chat.id and chat_state.user_id = (select auth.uid())
  left join public.family_messages unread
    on unread.chat_id = chat.id
   and unread.sender_id is distinct from (select auth.uid())
   and unread.kind = 'message'
   and unread.created_at >= me.readable_from
   and unread.created_at > coalesce(greatest(state.last_read_at, chat_state.last_read_at), '-infinity'::timestamptz)
  group by thread.id, profile.first_name, latest.body, latest.created_at, state.muted_at,
    me.readable_from
  order by latest.created_at desc nulls last, thread.created_at desc;
$$;


--
-- Name: zyra_family_message_participants(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_message_participants(p_thread uuid) RETURNS TABLE(user_id uuid, first_name text, member_role text, is_main_guardian boolean, is_current_user boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select
    member.user_id,
    profile.first_name,
    member.member_role,
    coalesce(link.is_main, false),
    member.user_id = (select auth.uid())
  from public.family_message_memberships member
  join public.family_message_threads thread
    on thread.id = member.thread_id
  join public.profiles profile
    on profile.id = member.user_id
  join public.family_message_memberships caller
    on caller.thread_id = member.thread_id
   and caller.user_id = (select auth.uid())
   and caller.left_at is null
  left join public.wali_links link
    on member.member_role = 'guardian'
   and link.seeker_id = thread.seeker_id
   and link.wali_id = member.user_id
   and link.status = 'active'
  where member.thread_id = p_thread
    and member.left_at is null
  order by
    case member.member_role when 'seeker' then 0 else 1 end,
    coalesce(link.is_main, false) desc,
    member.joined_at,
    member.user_id;
$$;


--
-- Name: FUNCTION zyra_family_message_participants(p_thread uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_family_message_participants(p_thread uuid) IS 'Names and roles of current members, visible only to another current member of the same Guardian Circle.';


--
-- Name: zyra_family_messages(uuid, timestamp with time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_messages(p_thread uuid, p_before timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limit integer DEFAULT 50) RETURNS TABLE(message_id uuid, sender_id uuid, sender_first_name text, kind text, body text, created_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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
  join public.family_message_chats chat on chat.id = message.chat_id and chat.kind = 'main'
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


--
-- Name: zyra_family_messages_v2(uuid, timestamp with time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_messages_v2(p_thread uuid, p_before timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limit integer DEFAULT 50) RETURNS TABLE(message_id uuid, sender_id uuid, sender_first_name text, sender_relationship text, sender_role_label text, kind text, body text, created_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select
    message.id,
    message.sender_id,
    case
      when message.sender_id is null then 'Deleted member'
      when sender_membership.member_role = 'guardian'
        and sender_membership.left_at is not null
        and not exists (
          select 1
          from public.family_message_memberships current_member
          where current_member.thread_id = message.thread_id
            and current_member.user_id = message.sender_id
            and current_member.left_at is null
        ) then 'Former Guardian'
      else sender.first_name
    end,
    case
      when sender_membership.member_role = 'guardian'
        then sender_link.relationship
      else null
    end,
    case
      when message.sender_id is null then null
      when sender_membership.member_role = 'seeker' then 'Seeker'
      when sender_membership.member_role = 'guardian'
        and sender_membership.left_at is not null
        and not exists (
          select 1
          from public.family_message_memberships current_member
          where current_member.thread_id = message.thread_id
            and current_member.user_id = message.sender_id
            and current_member.left_at is null
        ) then 'Former Guardian'
      when sender_membership.member_role = 'guardian'
        and coalesce(sender_link.is_main, false) then 'Main Guardian'
      when sender_membership.member_role = 'guardian'
        then 'Additional Guardian'
      else null
    end,
    message.kind,
    message.body,
    message.created_at
  from public.family_messages message
  join public.family_message_chats chat on chat.id = message.chat_id and chat.kind = 'main'
  join public.family_message_threads thread
    on thread.id = message.thread_id
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = (select auth.uid())
   and membership.left_at is null
  left join public.profiles sender
    on sender.id = message.sender_id
  left join lateral (
    select sender_epoch.member_role, sender_epoch.left_at
    from public.family_message_memberships sender_epoch
    where sender_epoch.thread_id = message.thread_id
      and sender_epoch.user_id = message.sender_id
    order by (sender_epoch.left_at is null) desc, sender_epoch.joined_at desc
    limit 1
  ) sender_membership on true
  left join lateral (
    select link.relationship, link.is_main
    from public.wali_links link
    where link.seeker_id = thread.seeker_id
      and link.wali_id = message.sender_id
    order by (link.status = 'active') desc,
      link.active_since desc nulls last
    limit 1
  ) sender_link on true
  where message.thread_id = p_thread
    and message.created_at >= membership.readable_from
    and (p_before is null or message.created_at < p_before)
  order by message.created_at desc, message.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;


--
-- Name: FUNCTION zyra_family_messages_v2(p_thread uuid, p_before timestamp with time zone, p_limit integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_family_messages_v2(p_thread uuid, p_before timestamp with time zone, p_limit integer) IS 'Current Circle members can read message sender name, Guardian relationship code and current Circle role. Caller membership and readable_from remain the authority boundary.';


--
-- Name: zyra_family_messages_v3(uuid, timestamp with time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_messages_v3(p_thread uuid, p_before timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limit integer DEFAULT 50) RETURNS TABLE(message_id uuid, sender_id uuid, sender_first_name text, sender_relationship text, sender_role_label text, kind text, body text, created_at timestamp with time zone, read_by jsonb, unread_for_me boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select
    message.id,
    message.sender_id,
    case
      when message.sender_id is null then 'Deleted member'
      when sender_membership.member_role = 'guardian'
        and sender_membership.left_at is not null
        and not exists (
          select 1
          from public.family_message_memberships current_member
          where current_member.thread_id = message.thread_id
            and current_member.user_id = message.sender_id
            and current_member.left_at is null
        ) then 'Former Guardian'
      else sender.first_name
    end,
    case
      when sender_membership.member_role = 'guardian'
        then sender_link.relationship
      else null
    end,
    case
      when message.sender_id is null then null
      when sender_membership.member_role = 'seeker' then 'Seeker'
      when sender_membership.member_role = 'guardian'
        and sender_membership.left_at is not null
        and not exists (
          select 1
          from public.family_message_memberships current_member
          where current_member.thread_id = message.thread_id
            and current_member.user_id = message.sender_id
            and current_member.left_at is null
        ) then 'Former Guardian'
      when sender_membership.member_role = 'guardian'
        and coalesce(sender_link.is_main, false) then 'Main Guardian'
      when sender_membership.member_role = 'guardian'
        then 'Additional Guardian'
      else null
    end,
    message.kind,
    message.body,
    message.created_at,
    case
      when message.sender_id = (select auth.uid()) then coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'user_id', reader.user_id,
            'first_name', reader_profile.first_name,
            'role_label', case
              when reader.member_role = 'seeker' then 'Seeker'
              when coalesce(reader_link.is_main, false) then 'Main Guardian'
              else 'Additional Guardian'
            end,
            'read_at', greatest(reader_state.last_read_at, reader_chat.last_read_at)
          ) order by greatest(reader_state.last_read_at, reader_chat.last_read_at), reader.user_id
        )
        from public.family_message_memberships reader
        left join public.family_message_participant_state reader_state
          on reader_state.thread_id = reader.thread_id
         and reader_state.user_id = reader.user_id
        left join public.family_message_chat_state reader_chat
          on reader_chat.chat_id = message.chat_id and reader_chat.user_id = reader.user_id
        join public.profiles reader_profile on reader_profile.id = reader.user_id
        left join public.wali_links reader_link
          on reader_link.seeker_id = thread.seeker_id
         and reader_link.wali_id = reader.user_id
         and reader_link.status = 'active'
        where reader.thread_id = message.thread_id
          and reader.left_at is null
          and reader.user_id <> message.sender_id
          and message.created_at >= reader.readable_from
          and greatest(reader_state.last_read_at, reader_chat.last_read_at) >= message.created_at
      ), '[]'::jsonb)
      else '[]'::jsonb
    end,
    message.kind = 'message' and message.sender_id is distinct from (select auth.uid())
      and message.created_at > coalesce(
        greatest(caller_state.last_read_at, caller_chat.last_read_at),
        '-infinity'::timestamptz
      )
  from public.family_messages message
  join public.family_message_chats chat on chat.id = message.chat_id and chat.kind = 'main'
  join public.family_message_threads thread
    on thread.id = message.thread_id
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = (select auth.uid())
   and membership.left_at is null
  left join public.family_message_participant_state caller_state
    on caller_state.thread_id = message.thread_id
   and caller_state.user_id = (select auth.uid())
  left join public.family_message_chat_state caller_chat
    on caller_chat.chat_id = message.chat_id and caller_chat.user_id = (select auth.uid())
  left join public.profiles sender on sender.id = message.sender_id
  left join lateral (
    select sender_epoch.member_role, sender_epoch.left_at
    from public.family_message_memberships sender_epoch
    where sender_epoch.thread_id = message.thread_id
      and sender_epoch.user_id = message.sender_id
    order by (sender_epoch.left_at is null) desc, sender_epoch.joined_at desc
    limit 1
  ) sender_membership on true
  left join lateral (
    select link.relationship, link.is_main
    from public.wali_links link
    where link.seeker_id = thread.seeker_id
      and link.wali_id = message.sender_id
    order by (link.status = 'active') desc,
      link.active_since desc nulls last
    limit 1
  ) sender_link on true
  where message.thread_id = p_thread
    and message.created_at >= membership.readable_from
    and (p_before is null or message.created_at < p_before)
  order by message.created_at desc, message.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;


--
-- Name: FUNCTION zyra_family_messages_v3(p_thread uuid, p_before timestamp with time zone, p_limit integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_family_messages_v3(p_thread uuid, p_before timestamp with time zone, p_limit integer) IS 'Versioned Guardian Circle history with sender identity, caller-unread state and read receipts visible only on messages sent by the caller. Current membership and readable_from remain the authority boundary.';


--
-- Name: zyra_family_owner_row_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_owner_row_guard() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform public.zyra_assert_family_owner_seat(new.id);
  return null;
end;
$$;


--
-- Name: zyra_family_owner_seat_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_family_owner_seat_guard() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform public.zyra_assert_family_owner_seat(
    case when tg_op = 'DELETE'
      then old.family_subscription_id
      else new.family_subscription_id
    end
  );
  return null;
end;
$$;


--
-- Name: zyra_finish_photo_object_deletion(text, text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_finish_photo_object_deletion(p_bucket text, p_path text, p_attempt integer, p_error text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  -- An expired attempt cannot finish a later attempt or alter its lease.
  update public.photo_object_deletions d
    set last_error = left(p_error, 128), done_at = case when p_error is null then now() end
    where d.bucket = p_bucket and d.path = p_path and d.attempts = p_attempt
      and d.done_at is null and d.attempts > 0;
  -- Leave a failed attempt's lease in place as the retry cooldown, so a
  -- single invocation cannot exhaust the same path's attempts in a loop.
  if found and p_error is null then
    delete from private.zyra_photo_cleanup_leases l where l.bucket = p_bucket and l.path = p_path;
  end if;
end;
$$;


--
-- Name: zyra_forfeit_seeker_trial_on_family_seat(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_forfeit_seeker_trial_on_family_seat() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_person uuid;
begin
  if new.role <> 'seeker'
     or not (new.removed_at is null or new.funded_until > now()) then
    return new;
  end if;
  select binding.verified_person_id into v_person
  from private.verified_person_accounts binding
  where binding.user_id = new.member_id and binding.role = 'seeker';
  if v_person is null then raise exception 'verified_family_member_required'; end if;

  insert into private.seeker_trial_ledger (
    verified_person_id, claimed_by, status, updated_at
  ) values (
    v_person, new.member_id, 'family_forfeited', now()
  ) on conflict (verified_person_id) do update
    set status = 'family_forfeited',
        ends_at = least(
          coalesce(private.seeker_trial_ledger.ends_at, now()),
          now()
        ),
        updated_at = now();
  return new;
end;
$$;


--
-- Name: zyra_guard_ended_restart_initiation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_guard_ended_restart_initiation() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare v_caller uuid := (select auth.uid());
begin
  if v_caller is null then return new; end if;
  if new.requested_by is distinct from v_caller
     or not public.zyra_may_request_new_journey(new.match_id)
     or not exists (select 1 from public.matches m where m.id = new.match_id
       and new.requested_to = case when m.seeker_a_id=v_caller then m.seeker_b_id else m.seeker_a_id end)
  then raise exception 'restart_not_available'; end if;
  if new.expires_at is distinct from now() + interval '30 days' then
    raise exception 'restart_expiry_must_be_thirty_days';
  end if;
  return new;
end;
$$;


--
-- Name: zyra_guard_family_place_reduction(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_guard_family_place_reduction() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_funded_seekers integer;
  v_funded_guardians integer;
begin
  if new.seeker_places >= old.seeker_places
     and new.guardian_places >= old.guardian_places then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(new.id::text, 0));

  select
    count(*) filter (where seat.role = 'seeker'),
    count(*) filter (where seat.role = 'guardian')
  into v_funded_seekers, v_funded_guardians
  from public.family_seat_assignments seat
  where seat.family_subscription_id = new.id
    and (seat.removed_at is null or seat.funded_until > now());

  if new.seeker_places < v_funded_seekers then
    raise exception 'family_seeker_places_still_funded';
  end if;
  if new.guardian_places < v_funded_guardians then
    raise exception 'family_guardian_places_still_funded';
  end if;
  return new;
end;
$$;


--
-- Name: zyra_guardian_activity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_guardian_activity() RETURNS TABLE(wali_id uuid, activity_type text, occurred_at timestamp with time zone, detail text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  with my_guardians as (
    select w.wali_id, w.created_at, coalesce(w.is_main, false) as is_main
    from public.wali_links w
    where w.seeker_id = (select auth.uid())
      and w.status = 'active'
  )

  -- They accepted, and the link began.
  select g.wali_id, 'linked'::text, g.created_at, null::text
  from my_guardians g

  union all

  -- They put someone forward. The only type with real data today.
  select s.wali_id, 'suggested', s.created_at, p.first_name
  from public.wali_suggestions s
  join my_guardians g on g.wali_id = s.wali_id
  join public.profiles p on p.id = s.suggested_id
  where s.seeker_id = (select auth.uid())

  union all

  -- They answered a Family Review on one of my Journeys.
  select r.wali_id, 'review_answered', r.responded_at, r.decision
  from public.journey_family_review_responses r
  join my_guardians g on g.wali_id = r.wali_id
  join public.journey_family_reviews rev on rev.id = r.review_id
  join public.zyra_my_attempt_participation p on p.attempt_id = rev.attempt_id and p.role = 'seeker'

  union all

  -- A review is open and the Main Guardian has not answered it.
  -- Scoped to Main because only the Main Guardian is asked to act — the
  -- same rule the page already states in its own copy.
  select g.wali_id, 'review_waiting', rev.opened_at, null
  from public.journey_family_reviews rev
  join public.zyra_my_attempt_participation p on p.attempt_id = rev.attempt_id and p.role = 'seeker'
  join my_guardians g on g.is_main
  where rev.status = 'open'
    and not exists (
      select 1 from public.journey_family_review_responses rr
      where rr.review_id = rev.id and rr.wali_id = g.wali_id
    )

  order by 3 desc nulls last;
$$;


--
-- Name: zyra_guardian_history_consent(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_guardian_history_consent(p_guardian uuid, p_enabled boolean DEFAULT NULL::boolean) RETURNS TABLE(enabled boolean, active_guardian_link_id uuid, guardian_id uuid, guardian_is_main boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_link_authority_id uuid;
  v_main_authority_id uuid;
  v_is_main boolean;
begin
  if v_caller is null then
    raise exception 'not_signed_in';
  end if;
  if p_guardian is null then
    raise exception 'guardian_required';
  end if;

  select
    w.id,
    w.guardian_link_authority_id,
    w.main_guardian_authority_id,
    w.is_main
  into
    v_link_id,
    v_link_authority_id,
    v_main_authority_id,
    v_is_main
  from public.wali_links w
  where w.seeker_id = v_caller
    and w.wali_id = p_guardian
    and w.status = 'active';

  if not found then
    if p_enabled is true then
      raise exception 'active_guardian_required_for_history_consent';
    end if;
    return query
    select false, null::uuid, null::uuid, null::boolean;
    return;
  end if;

  if p_enabled is true then
    insert into public.guardian_journey_history_consents (
      wali_link_id,
      main_guardian_authority_id,
      guardian_link_authority_id,
      granted_at
    ) values (
      v_link_id,
      v_main_authority_id,
      v_link_authority_id,
      pg_catalog.clock_timestamp()
    )
    on conflict (wali_link_id) do update
      set main_guardian_authority_id = excluded.main_guardian_authority_id,
          guardian_link_authority_id = excluded.guardian_link_authority_id,
          granted_at = excluded.granted_at;
  elsif p_enabled is false then
    delete from public.guardian_journey_history_consents c
    where c.wali_link_id = v_link_id;
  end if;

  return query
  select
    exists (
      select 1
      from public.guardian_journey_history_consents c
      where c.wali_link_id = v_link_id
        and c.guardian_link_authority_id = v_link_authority_id
    ),
    v_link_id,
    p_guardian,
    v_is_main;
end;
$$;


--
-- Name: FUNCTION zyra_guardian_history_consent(p_guardian uuid, p_enabled boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_guardian_history_consent(p_guardian uuid, p_enabled boolean) IS 'DR-ZYRA-233 Seeker-owned, caller-derived permission for one current active Guardian to see all past four-field Journey summaries. NULL reads; TRUE grants; FALSE revokes. No counterpart identity, stage, messages, answers, reasons, notes or safety information is returned or authorised.';


--
-- Name: zyra_guardian_journey_access(uuid, uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_guardian_journey_access(p_guardian uuid, p_attempt uuid DEFAULT NULL::uuid, p_enabled boolean DEFAULT NULL::boolean) RETURNS TABLE(attempt_id uuid, match_id uuid, counterpart_first_name text, included boolean, can_change boolean, guardian_is_main boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
#variable_conflict use_column
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_is_main boolean;
  v_active_since timestamptz;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  if p_guardian is null then raise exception 'guardian_required'; end if;
  if (p_attempt is null) <> (p_enabled is null) then
    raise exception 'attempt_and_enabled_must_be_supplied_together';
  end if;
  select w.id, w.is_main, w.active_since
  into v_link_id, v_is_main, v_active_since
  from public.wali_links w
  where w.seeker_id = v_caller and w.wali_id = p_guardian and w.status = 'active'
  for update;
  if not found then raise exception 'active_guardian_link_not_found'; end if;

  if p_attempt is not null then
    if v_is_main then raise exception 'main_guardian_always_included'; end if;
    if not exists (
      select 1 from public.journey_attempts a
      join public.matches m on m.id = a.match_id
      where a.id = p_attempt and a.status = 'active'
        and v_caller in (m.seeker_a_id, m.seeker_b_id)
    ) then raise exception 'active_owned_journey_not_found'; end if;
    if p_enabled then
      update public.journey_guardian_assignments jga
      set revoked_by = v_caller, revoked_at = pg_catalog.clock_timestamp()
      where jga.attempt_id = p_attempt and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller and jga.revoked_at is null
        and jga.granted_at < v_active_since;
      insert into public.journey_guardian_assignments (
        attempt_id, wali_link_id, seeker_id, granted_by
      ) values (p_attempt, v_link_id, v_caller, v_caller)
      on conflict (attempt_id, wali_link_id) where revoked_at is null do nothing;
    else
      update public.journey_guardian_assignments jga
      set revoked_by = v_caller, revoked_at = pg_catalog.clock_timestamp()
      where jga.attempt_id = p_attempt and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller and jga.revoked_at is null;
    end if;
  end if;

  return query
  select a.id, a.match_id, other_profile.first_name,
    (v_is_main or exists (
      select 1 from public.journey_guardian_assignments jga
      where jga.attempt_id = a.id and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller and jga.revoked_at is null
        and jga.granted_at >= v_active_since
    )), not v_is_main, v_is_main
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  join public.profiles other_profile on other_profile.id = case
    when m.seeker_a_id = v_caller then m.seeker_b_id else m.seeker_a_id end
  where a.status = 'active' and v_caller in (m.seeker_a_id, m.seeker_b_id)
  order by a.started_at desc nulls last, a.created_at desc, a.id;
end;
$$;


--
-- Name: FUNCTION zyra_guardian_journey_access(p_guardian uuid, p_attempt uuid, p_enabled boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_guardian_journey_access(p_guardian uuid, p_attempt uuid, p_enabled boolean) IS 'Reads or changes one Seeker-owned Guardian link across the caller''s active Journeys. Main is immutable ON. Additional changes are server-confirmed, per attempt and audited; no caller may act for the other Seeker.';


--
-- Name: zyra_guardian_journey_chat_access(uuid, uuid, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_guardian_journey_chat_access(p_guardian uuid, p_attempt uuid DEFAULT NULL::uuid, p_enabled boolean DEFAULT NULL::boolean, p_chat_enabled boolean DEFAULT NULL::boolean) RETURNS TABLE(attempt_id uuid, match_id uuid, counterpart_first_name text, included boolean, can_change boolean, guardian_is_main boolean, chat_available boolean, chat_enabled boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_is_main boolean;
  v_match_id uuid;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  if p_guardian is null then raise exception 'guardian_required'; end if;
  if p_attempt is null and (p_enabled is not null or p_chat_enabled is not null) then
    raise exception 'attempt_required_for_change';
  end if;

  select link.id, link.is_main into v_link_id, v_is_main
  from public.wali_links link
  where link.seeker_id = v_caller
    and link.wali_id = p_guardian
    and link.status = 'active';
  if not found then raise exception 'active_guardian_link_not_found'; end if;

  if p_attempt is not null then
    select attempt.match_id into v_match_id
    from public.journey_attempts attempt
    join public.matches match on match.id = attempt.match_id
    where attempt.id = p_attempt
      and attempt.status = 'active'
      and v_caller in (match.seeker_a_id, match.seeker_b_id);
    if v_match_id is null then raise exception 'active_owned_journey_not_found'; end if;
    if v_is_main and (p_enabled is not null or p_chat_enabled is not null) then
      raise exception 'main_guardian_access_required';
    end if;

    perform * from public.zyra_guardian_journey_access(p_guardian, p_attempt, p_enabled);

    insert into public.guardian_journey_permissions (
      wali_link_id, match_id, can_view, can_chat, updated_by, updated_at
    ) values (
      v_link_id,
      v_match_id,
      coalesce(p_enabled, true),
      case
        when p_enabled is false then false
        else coalesce(p_chat_enabled, true)
      end,
      v_caller,
      now()
    )
    on conflict on constraint guardian_journey_permissions_pkey do update
      set can_view = coalesce(p_enabled, guardian_journey_permissions.can_view),
          can_chat = case
            when coalesce(p_enabled, guardian_journey_permissions.can_view) is false
              then false
            else coalesce(
              p_chat_enabled,
              guardian_journey_permissions.can_chat
            )
          end,
          updated_by = v_caller,
          updated_at = now();
  end if;

  return query
  select
    attempt.id,
    attempt.match_id,
    counterpart.first_name,
    case when v_is_main then true else coalesce(permission.can_view, true) end,
    not v_is_main,
    v_is_main,
    true,
    case when v_is_main then true else coalesce(permission.can_chat, true) end
  from public.journey_attempts attempt
  join public.matches match on match.id = attempt.match_id
  join public.profiles counterpart on counterpart.id = case
    when match.seeker_a_id = v_caller then match.seeker_b_id
    else match.seeker_a_id
  end
  left join public.guardian_journey_permissions permission
    on permission.wali_link_id = v_link_id
   and permission.match_id = attempt.match_id
  where attempt.status = 'active'
    and v_caller in (match.seeker_a_id, match.seeker_b_id)
  order by attempt.started_at desc nulls last, attempt.created_at desc, attempt.id;
end;
$$;


--
-- Name: zyra_guardian_journey_permissions(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_guardian_journey_permissions(p_wali_link_id uuid) RETURNS TABLE(match_id uuid, can_view boolean, can_chat boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select
    match.id,
    case when link.is_main then true else coalesce(permission.can_view, true) end,
    case when link.is_main then true else coalesce(permission.can_chat, true) end
  from public.wali_links link
  join public.matches match
    on link.seeker_id in (match.seeker_a_id, match.seeker_b_id)
   and match.status = 'active'
  left join public.guardian_journey_permissions permission
    on permission.wali_link_id = link.id and permission.match_id = match.id
  where link.id = p_wali_link_id
    and link.status = 'active'
    and (link.seeker_id = (select auth.uid())
      or link.wali_id = (select auth.uid()));
$$;


--
-- Name: zyra_has_paid_role(uuid, text, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_has_paid_role(p_user uuid, p_role text, p_at timestamp with time zone DEFAULT now()) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select
    p_user is not null
    and p_role in ('seeker', 'guardian')
    and (
      exists (
        select 1
        from public.subscriptions subscription
        where subscription.user_id = p_user
          and subscription.plan_type = case p_role
            when 'seeker' then 'seeker_premium'
            else 'wali_premium'
          end
          and (
            (
              subscription.status = 'active'
              and (
                subscription.expires_at is null
                or subscription.expires_at > p_at
                or subscription.billing_grace_until > p_at
              )
            )
            or (
              subscription.status = 'cancelled'
              and subscription.coverage_ends_at > p_at
            )
          )
      )
      or exists (
        select 1
        from public.family_seat_assignments seat
        join public.family_subscriptions family
          on family.id = seat.family_subscription_id
        where seat.member_id = p_user
          and seat.role = p_role
          and coalesce(seat.funded_until, 'infinity'::timestamptz) > p_at
          and (
            seat.removed_at is null
            or coalesce(seat.funded_until, seat.removed_at) > p_at
          )
          and (
            (
              family.status in ('active', 'cancel_at_period_end')
              and coalesce(
                family.coverage_ends_at,
                'infinity'::timestamptz
              ) > p_at
            )
            or (
              family.status = 'billing_grace'
              and family.billing_grace_until > p_at
            )
          )
      )
    );
$$;


--
-- Name: FUNCTION zyra_has_paid_role(p_user uuid, p_role text, p_at timestamp with time zone); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_has_paid_role(p_user uuid, p_role text, p_at timestamp with time zone) IS 'Single server authority for paid Seeker/Guardian role access. Covers a direct One entitlement or a currently funded Family role seat; no Basic or free fallback exists.';


--
-- Name: zyra_hold_blocks(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_hold_blocks(p_restricted uuid, p_protected uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.protection_holds h
     WHERE h.restricted_id = p_restricted
       AND h.protected_id  = p_protected
       AND h.released_at IS NULL
       AND (h.expires_at IS NULL OR h.expires_at > NOW())
  );
$$;


--
-- Name: FUNCTION zyra_hold_blocks(p_restricted uuid, p_protected uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_hold_blocks(p_restricted uuid, p_protected uuid) IS 'OA-ZYRA-157. True if an active hold restricts p_restricted toward p_protected. Boolean only, by design — the reason and the expiry must never reach the restricted person. EXECUTE withheld from authenticated: server-side callers only.';


--
-- Name: zyra_journey_busy_flags(uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_journey_busy_flags(p_match_ids uuid[]) RETURNS TABLE(match_id uuid, in_another_journey boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT
    requested.id AS match_id,
    EXISTS (
      SELECT 1
      FROM public.matches AS other_match
      WHERE other_match.id <> requested.id
        AND other_match.status = 'active'
        AND other_match.suspended_by IS NULL
        AND other_match.also_paused_by IS NULL
        AND (
          other_match.seeker_a_id = CASE
            WHEN requested.seeker_a_id = auth.uid()
              THEN requested.seeker_b_id
            ELSE requested.seeker_a_id
          END
          OR other_match.seeker_b_id = CASE
            WHEN requested.seeker_a_id = auth.uid()
              THEN requested.seeker_b_id
            ELSE requested.seeker_a_id
          END
        )
        AND auth.uid() NOT IN (
          other_match.seeker_a_id,
          other_match.seeker_b_id
        )
    ) AS in_another_journey
  FROM public.matches AS requested
  WHERE requested.id = ANY(COALESCE(p_match_ids, '{}'::uuid[]))
    AND auth.uid() IN (requested.seeker_a_id, requested.seeker_b_id)
    AND (requested.status <> 'ended' OR public.zyra_can_read_ended_match(requested.id));
$$;


--
-- Name: FUNCTION zyra_journey_busy_flags(p_match_ids uuid[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_journey_busy_flags(p_match_ids uuid[]) IS 'For requested Journey rows owned by auth.uid(), returns whether the other party has a different unsuspended active match. OA-ZYRA-204.';


--
-- Name: zyra_journey_compatibility_state(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_journey_compatibility_state(p_match_id uuid) RETURNS TABLE(mine_revealed boolean, counterpart_revealed boolean, my_score numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
begin
  if v_caller is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  -- Match absence and non-participation deliberately have one observable
  -- result. A caller cannot use this function to enumerate match ids.
  select m.seeker_a_id, m.seeker_b_id, m.status, m.journey_stage,
         m.suspended_by, m.also_paused_by,
         coalesce(pg_catalog.to_jsonb(m) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_match
    from public.matches as m
   where m.id = p_match_id
     and v_caller in (m.seeker_a_id, m.seeker_b_id);

  if not found then
    raise exception using errcode = '42501', message = 'not_a_party';
  end if;

  if v_match.status is distinct from 'active'
     or v_match.journey_stage is distinct from 'compatibility_reveal'
     or v_match.suspended_by is not null
     or v_match.also_paused_by is not null
     or v_match.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  select a.id, a.journey_stage, a.paused_by, a.also_paused_by,
         coalesce(pg_catalog.to_jsonb(a) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_attempt
    from public.journey_attempts as a
   where a.match_id = p_match_id
     and a.status = 'active';

  if not found
     or v_attempt.journey_stage is distinct from 'compatibility_reveal'
     or v_attempt.paused_by is not null
     or v_attempt.also_paused_by is not null
     or v_attempt.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  v_is_a := v_caller = v_match.seeker_a_id;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id;

  if not found then
    mine_revealed := false;
    counterpart_revealed := false;
    my_score := null;
    return next;
    return;
  end if;

  -- The table is still keyed by match_id until OA-ZYRA-156 finishes. Never
  -- reinterpret a prior-attempt row as the current Journey.
  if v_compat.attempt_id is distinct from v_attempt.id then
    raise exception using
      errcode = '55000',
      message = 'compatibility_attempt_mismatch';
  end if;

  mine_revealed := case
    when v_is_a then v_compat.seeker_a_revealed
    else v_compat.seeker_b_revealed
  end;
  counterpart_revealed := case
    when v_is_a then v_compat.seeker_b_revealed
    else v_compat.seeker_a_revealed
  end;

  -- Ordinary Reveal remains mutual: the caller's own precomputed Plus score
  -- is not returned through the ordinary state RPC until both consent flags
  -- are true.
  my_score := case
    when v_compat.seeker_a_revealed and v_compat.seeker_b_revealed then
      case
        when v_is_a then v_compat.seeker_a_score
        else v_compat.seeker_b_score
      end
    else null
  end;

  return next;
end;
$$;


--
-- Name: FUNCTION zyra_journey_compatibility_state(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_journey_compatibility_state(p_match_id uuid) IS 'OA-ZYRA-283. Current active Journey compatibility state, caller-relative. Returns mutual flags and only the caller-owned score after mutual reveal.';


--
-- Name: zyra_journey_main_guardian_gate(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_journey_main_guardian_gate(p_match_id uuid) RETURNS TABLE(self_has_main boolean, other_has_main boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := (select auth.uid());
  v_a uuid;
  v_b uuid;
  v_status text;
  v_other uuid;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  select m.seeker_a_id, m.seeker_b_id, m.status
    into v_a, v_b, v_status
  from public.matches m
  where m.id = p_match_id and m.seeker_a_id is not null and m.seeker_b_id is not null;

  if not found or (v_me is distinct from v_a and v_me is distinct from v_b)
      or (v_status = 'ended' and not public.zyra_can_read_ended_match(p_match_id)) then
    raise exception 'journey_not_available';
  end if;

  v_other := case when v_me = v_a then v_b else v_a end;

  return query
  select
    exists (
      select 1
      from public.wali_links w
      where w.seeker_id = v_me
        and w.status = 'active'
        and w.is_main is true
    ),
    exists (
      select 1
      from public.wali_links w
      where w.seeker_id = v_other
        and w.status = 'active'
        and w.is_main is true
    );
end;
$$;


--
-- Name: FUNCTION zyra_journey_main_guardian_gate(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_journey_main_guardian_gate(p_match_id uuid) IS 'DR-ZYRA-236. Caller-bound Journey gate. Returns only whether the caller and counterpart each have an active Main Guardian. No Guardian identity or link detail is disclosed.';


--
-- Name: zyra_journey_return_available(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_journey_return_available(p_match_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select public.zyra_may_request_new_journey(p_match_id);
$$;


--
-- Name: zyra_light_weight(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_light_weight(p_light text) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'public'
    AS $$
  select case p_light
           when 'green'  then 1.0
           when 'yellow' then 0.5
           when 'red'    then 0.0
           else 0.0
         end::numeric;
$$;


--
-- Name: FUNCTION zyra_light_weight(p_light text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_light_weight(p_light text) IS 'The ratified light weighting (OA-ZYRA-193a): green 1, yellow 0.5, red 0. Replaces zyra_light_points, which encoded the retired centred scale.';


--
-- Name: zyra_like_clears_others(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_like_clears_others() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  DELETE FROM passes WHERE passer_id = NEW.liker_id AND passed_id = NEW.liked_id;
  DELETE FROM saves  WHERE saver_id  = NEW.liker_id AND saved_id  = NEW.liked_id;
  RETURN NEW;
END;
$$;


--
-- Name: zyra_main_guardian_history_consent(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_main_guardian_history_consent(p_enabled boolean DEFAULT NULL::boolean) RETURNS TABLE(enabled boolean, active_main_link_id uuid, main_guardian_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_guardian uuid;
begin
  if v_caller is null then
    raise exception 'not_signed_in';
  end if;

  select w.wali_id
  into v_guardian
  from public.wali_links w
  where w.seeker_id = v_caller
    and w.status = 'active'
    and w.is_main is true;

  if not found then
    if p_enabled is true then
      raise exception 'main_guardian_required_for_history_consent';
    end if;
    return query select false, null::uuid, null::uuid;
    return;
  end if;

  return query
  select
    state.enabled,
    state.active_guardian_link_id,
    state.guardian_id
  from public.zyra_guardian_history_consent(v_guardian, p_enabled) state;
end;
$$;


--
-- Name: FUNCTION zyra_main_guardian_history_consent(p_enabled boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_main_guardian_history_consent(p_enabled boolean) IS 'Compatibility wrapper for DR-ZYRA-225 clients. Reads or changes the current Main Guardian through zyra_guardian_history_consent(uuid, boolean).';


--
-- Name: zyra_mark_family_chat_read(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_mark_family_chat_read(p_chat_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := (select auth.uid());
  v_read_at timestamptz;
begin
  perform private.zyra_lock_family_chat(p_chat_id);
  v_read_at := clock_timestamp();
  insert into public.family_message_chat_state as chat_state (chat_id, user_id, last_read_at)
  values (p_chat_id, v_me, v_read_at)
  on conflict (chat_id, user_id) do update
    set last_read_at = greatest(chat_state.last_read_at, excluded.last_read_at);
  update public.notifications
  set read_at = v_read_at
  where user_id = v_me and related_chat_id = p_chat_id
    and type = 'circle_message' and read_at is null and created_at <= v_read_at;
end;
$$;


--
-- Name: zyra_mark_family_message_sender_deleted(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_mark_family_message_sender_deleted() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  update public.family_messages
  set sender_deleted_at = coalesce(sender_deleted_at, now())
  where sender_id = old.id;
  return old;
end;
$$;


--
-- Name: zyra_mark_family_messages_read(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_mark_family_messages_read(p_thread uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_read_at timestamptz;
begin
  perform private.zyra_lock_family_message_thread(p_thread);
  v_read_at := clock_timestamp();
  insert into public.family_message_participant_state as circle_state
    (thread_id, user_id, last_read_at)
  values (p_thread, v_me, v_read_at)
  on conflict (thread_id, user_id) do update
    set last_read_at = greatest(circle_state.last_read_at, excluded.last_read_at);
  update public.notifications n set read_at = v_read_at
  from public.family_message_chats chat
  where chat.id = n.related_chat_id and chat.thread_id = p_thread
    and n.user_id = v_me and n.type = 'circle_message'
    and n.read_at is null and n.created_at <= v_read_at;
end;
$$;


--
-- Name: zyra_mark_journey_messages_read(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_mark_journey_messages_read(p_conversation uuid) RETURNS timestamp with time zone
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_now timestamptz := clock_timestamp();
begin
  if v_caller is null then
    raise exception 'authentication_required';
  end if;

  if not exists (
    select 1
    from public.conversations conversation
    join public.zyra_my_attempt_participation p on p.attempt_id = conversation.attempt_id
    where conversation.id = p_conversation and p.role = 'seeker'
  ) then
    raise exception 'conversation_not_available';
  end if;

  update public.messages message
  set read_at = coalesce(message.read_at, v_now)
  where message.conversation_id = p_conversation
    and message.sender_id <> v_caller
    and message.read_at is null;

  return v_now;
end;
$$;


--
-- Name: FUNCTION zyra_mark_journey_messages_read(p_conversation uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_mark_journey_messages_read(p_conversation uuid) IS 'Marks only the other Seeker''s messages read after proving the caller is one of the two Seekers in the conversation. Guardians cannot write a Seeker read receipt.';


--
-- Name: zyra_mark_suggestions_seen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_mark_suggestions_seen() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
  v_n  int;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  -- seeker_id = me is the whole authorisation rule. A Guardian cannot mark
  -- their own suggestion as seen on the Seeker's behalf, and nobody can
  -- touch anyone else's row: there is no parameter to point elsewhere.
  update public.wali_suggestions
     set seen_at = now()
   where seeker_id = v_me
     and status = 'pending'
     and seen_at is null;

  get diagnostics v_n = row_count;
  return v_n;
end;
$$;


--
-- Name: zyra_match_ending(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_match_ending(p_match_id uuid) RETURNS TABLE(ended_by uuid, end_reason text, end_note text, ended_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select m.ended_by,
         case when m.end_reason = 'safety_concern' and m.ended_by is distinct from (select auth.uid())
           then 'prefer_not_to_say' else m.end_reason end,
         case when m.end_reason = 'safety_concern' and m.ended_by is distinct from (select auth.uid())
           then null else m.end_note end,
         m.ended_at
  from public.matches m
  where m.id = p_match_id
    and (m.status = 'ended' and public.zyra_can_read_ended_match(m.id)
      or m.status <> 'ended' and exists (
        select 1 from public.zyra_my_attempt_participation p where p.match_id = m.id
      ));
$$;


--
-- Name: FUNCTION zyra_match_ending(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_match_ending(p_match_id uuid) IS 'THE only route to how a Journey ended. Substitutes prefer_not_to_say for safety_concern for everyone except the person who raised it — including their own Guardian (Founder, strict, 2026-08-08). GOVERNANCE RULE FOR CALLERS: prefer_not_to_say must render identically whether genuine or substituted. One string, one layout, one behaviour. A different tone, an extra sentence or a separate code path would make the rendering the disclosure.';


--
-- Name: zyra_may_request_new_journey(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_may_request_new_journey(p_match_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_match public.matches%rowtype;
  v_other uuid;
begin
  if v_caller is null then return false; end if;
  select * into v_match from public.matches where id = p_match_id;
  if not found or v_match.seeker_a_id is null or v_match.seeker_b_id is null
     or v_caller not in (v_match.seeker_a_id, v_match.seeker_b_id) then
    return false;
  end if;
  v_other := case when v_caller = v_match.seeker_a_id
    then v_match.seeker_b_id else v_match.seeker_a_id end;
  return v_match.status = 'ended'
    and v_match.ended_at is not null
    and now() >= v_match.ended_at + interval '24 hours'
    and public.zyra_has_paid_role(v_caller, 'seeker')
    and public.zyra_active_journey_cap(v_other) > 0
    and not public.zyra_block_exists(v_other)
    and public.zyra_can_match(v_caller, v_other)
    and not public.zyra_hold_blocks(v_caller, v_other)
    and not exists (
      select 1 from public.journey_requests request
      where request.match_id = p_match_id and request.status = 'pending'
    )
    and exists (
      select 1 from (
        select match.id
        from public.matches match
        where match.status = 'ended'
          and v_caller in (match.seeker_a_id, match.seeker_b_id)
        order by match.ended_at desc nulls last, match.id desc
        limit 5
      ) recent where recent.id = p_match_id
    )
    and public.zyra_active_journey_count(v_match.seeker_a_id, v_match.id)
      < public.zyra_active_journey_cap(v_match.seeker_a_id)
    and public.zyra_active_journey_count(v_match.seeker_b_id, v_match.id)
      < public.zyra_active_journey_cap(v_match.seeker_b_id);
end;
$$;


--
-- Name: zyra_may_request_new_journey_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_may_request_new_journey_ids() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select match.id
  from public.matches match
  where (select auth.uid()) in (match.seeker_a_id, match.seeker_b_id)
    and public.zyra_may_request_new_journey(match.id);
$$;


--
-- Name: FUNCTION zyra_may_request_new_journey_ids(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_may_request_new_journey_ids() IS 'OA-ZYRA-159 stage 5b. The ended match_ids on which the caller may request a new Journey, in one query. Absence carries no reason, by design.';


--
-- Name: zyra_may_send_journey_message(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_may_send_journey_message(p_conversation uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select exists (
    select 1
    from public.conversations c
    join public.journey_attempts a on a.id = c.attempt_id
    join public.matches m on m.id = a.match_id and m.id = c.match_id
    join public.zyra_attempt_participant_rows r
      on r.attempt_id = a.id and r.match_id = m.id
     and r.user_id = (select auth.uid())
    where c.id = p_conversation
      and c.status = 'active' and a.status = 'active'
      and m.status = 'active' and a.journey_stage = 'conversation'
      and not exists (select 1 from public.journey_attempts newer
                      where newer.match_id = m.id
                        and newer.attempt_number > a.attempt_number)
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = m.seeker_a_id and b.blocked_id = m.seeker_b_id)
           or (b.blocker_id = m.seeker_b_id and b.blocked_id = m.seeker_a_id)
           or (b.blocker_id = (select auth.uid())
               and b.blocked_id in (m.seeker_a_id, m.seeker_b_id))
           or (b.blocked_id = (select auth.uid())
               and b.blocker_id in (m.seeker_a_id, m.seeker_b_id))
      )
      and (
        r.role = 'seeker'
        or (
          r.role = 'guardian'
          and public.zyra_has_paid_role((select auth.uid()), 'guardian')
          and exists (
            select 1 from public.wali_links w
            left join public.guardian_journey_permissions permission
              on permission.wali_link_id = w.id and permission.match_id = m.id
            where w.wali_id = (select auth.uid()) and w.status = 'active'
              and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
              and (w.is_main or (coalesce(permission.can_view, true)
                                 and coalesce(permission.can_chat, true)))
              and (w.is_main or exists (
                select 1 from public.journey_guardian_assignments assignment
                where assignment.attempt_id = a.id and assignment.wali_link_id = w.id
                  and assignment.seeker_id = w.seeker_id
                  and assignment.revoked_at is null
                  and assignment.granted_at >= w.active_since
              ))
          )
        )
      )
  );
$$;


--
-- Name: zyra_milestone_attestation_state(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_milestone_attestation_state(p_match_id uuid) RETURNS TABLE(id uuid, milestone_type text, occurred_on date, proposed_by uuid)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE caller UUID := auth.uid(); m RECORD; v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RETURN; END IF;
  SELECT * INTO m FROM matches WHERE matches.id = p_match_id and seeker_a_id is not null and seeker_b_id is not null;
  IF NOT FOUND OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN RETURN; END IF;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RETURN; END IF;
  RETURN QUERY
  SELECT t.id, t.milestone_type, t.occurred_on, t.proposed_by
    FROM journey_milestone_attestations t
   WHERE t.attempt_id = v_attempt AND t.status = 'pending';
END; $$;


--
-- Name: FUNCTION zyra_milestone_attestation_state(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_milestone_attestation_state(p_match_id uuid) IS 'Pending attestations for the caller''s match — the Timeline screen''s read path; table itself has no grants.';


--
-- Name: zyra_my_code_check_budget(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_code_check_budget() RETURNS TABLE(checks_left_this_hour integer, checks_left_today integer, next_check_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_hour_count integer;
  v_day_count integer;
  v_attempts timestamptz[];
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select count(*) filter (where a.attempted_at >= v_now - interval '1 hour'),
         count(*),
         array_agg(a.attempted_at order by a.attempted_at desc)
    into v_hour_count, v_day_count, v_attempts
  from private.zyra_personal_code_attempts a
  where a.caller_id = v_me
    and a.attempted_at >= v_now - interval '1 day';

  -- The existing windows include their lower bound. Use the first instant
  -- after it and wait for both windows when both have reached their cap.
  return query select
    greatest(10 - v_hour_count, 0),
    greatest(30 - v_day_count, 0),
    greatest(
      case when v_hour_count >= 10
        then v_attempts[10] + interval '1 hour 1 microsecond' end,
      case when v_day_count >= 30
        then v_attempts[30] + interval '1 day 1 microsecond' end
    );
end;
$$;


--
-- Name: FUNCTION zyra_my_code_check_budget(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_my_code_check_budget() IS 'Remaining rolling code checks for the signed-in account, and the next allowed check time when either limit has been reached.';


--
-- Name: zyra_my_ended_journeys(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_ended_journeys() RETURNS TABLE(attempt_id uuid, match_id uuid, started_at timestamp with time zone, ended_at timestamp with time zone, journey_stage text, end_reason text, end_note text, display_name text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select a.id, a.match_id, a.started_at, a.ended_at, a.journey_stage,
         case when a.end_reason = 'safety_concern' and a.ended_by is distinct from caller.id
           then 'prefer_not_to_say' else a.end_reason end,
         case when a.end_reason = 'safety_concern' and a.ended_by is distinct from caller.id
           then null else a.end_note end,
         case when a.end_reason is distinct from 'safety_concern'
           and public.zyra_can_view_profile(other.id) then profile.first_name end
  from private.zyra_ended_journey_visibility v
  join public.journey_attempts a on a.id = v.attempt_id
  cross join (select (select auth.uid()) as id) caller
  cross join lateral (
    select case when caller.id = v.seeker_a_id then v.seeker_b_id else v.seeker_a_id end as id
  ) other
  left join public.profiles profile on profile.id = other.id
  where (v.seeker_a_visible and v.seeker_a_id = caller.id)
     or (v.seeker_b_visible and v.seeker_b_id = caller.id)
  order by a.ended_at desc nulls last, a.id;
$$;


--
-- Name: zyra_my_guardian_requests(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_guardian_requests() RETURNS TABLE(request_id uuid, direction text, other_first_name text, other_role text, status text, relationship text, created_at timestamp with time zone, expires_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;

  return query
  select wi.id,
         case when wi.inviter_id = v_me then 'incoming' else 'outgoing' end,
         other_profile.first_name,
         other_profile.role,
         case when wi.status = 'pending' and wi.request_expires_at <= now()
              then 'expired' else wi.status end,
         wi.relationship,
         wi.created_at,
         wi.request_expires_at
  from public.wali_invites wi
  join public.profiles other_profile
    on other_profile.id = case when wi.inviter_id = v_me
                               then wi.recipient_id else wi.inviter_id end
  where wi.source = 'personal_code'
    and (wi.inviter_id = v_me or wi.recipient_id = v_me)
  order by wi.created_at desc;
end;
$$;


--
-- Name: zyra_my_hidden_profile_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_hidden_profile_ids() RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := (select auth.uid());
begin
  if v_me is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  return pg_catalog.jsonb_build_object(
    'schema_version', 1,
    'viewer_id', v_me,
    'profile_ids', coalesce((
      select pg_catalog.jsonb_agg(h.hidden order by h.hidden)
      from public.profile_hides h where h.hider = v_me
    ), '[]'::jsonb)
  );
end;
$$;


--
-- Name: zyra_my_identity_verification_allows_active_journey(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_identity_verification_allows_active_journey() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'private'
    AS $$
  select coalesce((
    select result = 'verified' and duplicate_review_required is false
    from private.identity_verification_attempts
    where user_id = auth.uid() and member_deleted_at is null
    order by (result = 'verified') desc, created_at desc
    limit 1
  ), false);
$$;


--
-- Name: zyra_my_identity_verification_allows_app(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_identity_verification_allows_app() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'private'
    AS $$
  select coalesce((
    select result = 'verified'
    from private.identity_verification_attempts
    where user_id = auth.uid() and member_deleted_at is null
    order by (result = 'verified') desc, created_at desc
    limit 1
  ), false);
$$;


--
-- Name: zyra_my_identity_verification_state(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_identity_verification_state() RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'private'
    AS $$
declare
  v_me uuid := auth.uid();
  v_attempt private.identity_verification_attempts%rowtype;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  select * into v_attempt
  from private.identity_verification_attempts
  where user_id = v_me and member_deleted_at is null
  order by
    (result = 'verified') desc,
    created_at desc
  limit 1;

  if not found then return null; end if;

  return jsonb_build_object(
    'result', v_attempt.result,
    'duplicate_review_required', v_attempt.duplicate_review_required,
    'consent_granted', v_attempt.consent_granted,
    'consent_version', v_attempt.consent_version,
    'consent_recorded_at', v_attempt.consent_recorded_at,
    'updated_at', v_attempt.updated_at,
    'decided_at', v_attempt.decided_at
  );
end;
$$;


--
-- Name: zyra_my_inactivity_notice(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_inactivity_notice() RETURNS TABLE(removal_due_at timestamp with time zone, ended_journeys integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select n.removal_due_at, archive.total
  from public.zyra_inactivity_notices n
  cross join lateral (
    select count(*)::integer as total from private.zyra_inactivity_ended_attempts(n.user_id)
  ) archive
  where n.user_id = (select auth.uid()) and n.cleared_at is null and n.completed_at is null
    and archive.total > 0;
$$;


--
-- Name: zyra_my_lights_needed_for_compatibility(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_lights_needed_for_compatibility() RETURNS TABLE(question_id text, option_value text, light text, reason text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select c.*, 'hidden_but_applicable'::text
  from private.zyra_preference_lights_to_check(true) c;
$$;


--
-- Name: zyra_my_lights_needing_reconfirmation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_lights_needing_reconfirmation() RETURNS TABLE(question_id text, option_value text, light text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select * from private.zyra_preference_lights_to_check(false);
$$;


--
-- Name: zyra_my_lights_needing_reconfirmation(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_lights_needing_reconfirmation(p_include_missing boolean) RETURNS TABLE(question_id text, option_value text, light text, reason text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select c.*, null::text as reason
  from private.zyra_preference_lights_to_check(false) c
  union all
  select 'ch2.sect.matrix', k.sect_key, null::text, 'missing'
  from public.profiles p
  join public.seeker_details d on d.user_id = p.id
  cross join lateral unnest(array['sunni', 'shia',
    private.zyra_current_sect_third_key(d.sect, d.sect_other)
  ]) k(sect_key)
  where p_include_missing
    and p.id = (select auth.uid()) and p.role = 'seeker'
    and k.sect_key is not null
    and private.zyra_sect_light_missing(d.preferences, k.sect_key)
  order by question_id, option_value;
$$;


--
-- Name: zyra_my_onboarding_progress(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_onboarding_progress() RETURNS TABLE(complete boolean, questions_due integer, questions_missing integer, has_chapter_2 boolean, basic_profile boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  me       UUID := (SELECT auth.uid());
  v_gender TEXT;
  v_ans    JSONB;
BEGIN
  IF me IS NULL THEN RETURN; END IF;

  SELECT p.gender INTO v_gender FROM profiles p WHERE p.id = me;
  SELECT coalesce(oa.ch3_answers,'{}'::jsonb) INTO v_ans
    FROM onboarding_answers oa WHERE oa.user_id = me;
  v_ans := coalesce(v_ans, '{}'::jsonb);

  RETURN QUERY
  SELECT
    zyra_onboarding_complete(me),
    (SELECT count(*)::int FROM (SELECT DISTINCT q.qid FROM zyra_onboarding_questions q) d
      WHERE zyra_question_is_due(d.qid, v_gender, v_ans)),
    (SELECT count(*)::int FROM zyra_onboarding_missing(me)),
    EXISTS (SELECT 1 FROM seeker_details sd
             WHERE sd.user_id = me AND sd.preferences IS NOT NULL
               AND sd.preferences <> '{}'::jsonb),
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = me AND p.profile_complete);
END;
$$;


--
-- Name: zyra_my_paid_access(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_paid_access(p_role text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select public.zyra_has_paid_role((select auth.uid()), p_role);
$$;


--
-- Name: zyra_my_personal_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_personal_code(p_role_context text DEFAULT NULL::text) RETURNS TABLE(code text, role_context text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_role text;
  v_requested_role text;
  v_code text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  select p.role into v_role from public.profiles p where p.id = v_me;
  if v_role not in ('seeker', 'wali') then raise exception 'profile_role_unavailable'; end if;
  v_requested_role := coalesce(p_role_context, v_role);
  if v_requested_role <> v_role then raise exception 'role_context_not_authorised'; end if;

  select c.code into v_code
  from private.zyra_personal_codes c
  where c.owner_id = v_me and c.role_context = v_requested_role;

  if v_code is null then
    loop
      begin
        insert into private.zyra_personal_codes as inserted
          (owner_id, role_context, code)
        values (v_me, v_requested_role, private.zyra_generate_personal_code())
        returning inserted.code into v_code;
        exit;
      exception when unique_violation then
        select c.code into v_code
        from private.zyra_personal_codes c
        where c.owner_id = v_me and c.role_context = v_requested_role;
        if v_code is not null then exit; end if;
      end;
    end loop;
  end if;

  return query select v_code, v_requested_role;
end;
$$;


--
-- Name: zyra_my_photo_sources(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_photo_sources() RETURNS TABLE(photo uuid, display_path text, source_path text, crop jsonb, rotation integer, revision integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select p.id, p.storage_path, s.name, p.crop, p.rotation, p.revision
  from public.profile_photos p
  left join storage.objects s on s.bucket_id = 'profile-photo-sources'
    and s.name = p.source_path and s.owner_id = p.user_id::text
  where p.user_id = (select auth.uid()) and p.removed_at is null
    and private.zyra_photo_reference_owned(p.user_id, p.storage_path)
  order by p.display_order, p.id;
$$;


--
-- Name: zyra_my_profile_video(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_profile_video() RETURNS TABLE(id uuid, status text, reject_reason text, storage_path text, duration_ms integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select latest.id, latest.status, latest.reject_reason, latest.storage_path, latest.duration_ms
  from (
    select video.*
    from public.profile_videos video
    where video.user_id = (select auth.uid())
    order by video.created_at desc, video.id desc
    limit 1
  ) latest
  where latest.status = 'rejected'
     or (
       latest.status in ('pending', 'approved')
       and exists (
         select 1
         from storage.objects object
         where object.id = latest.id
           and object.bucket_id = 'profile-videos'
           and object.name = latest.storage_path
       )
     );
$$;


--
-- Name: zyra_my_safety_cases(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_safety_cases() RETURNS TABLE(case_id uuid, case_type text, status text, created_at timestamp with time zone, updated_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;


--
-- Name: FUNCTION zyra_my_safety_cases(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_my_safety_cases() IS 'Caller-scoped safety case status only. Never returns the reported person identity and remains available regardless of membership state.';


--
-- Name: zyra_my_welcome_back(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_my_welcome_back() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  update public.zyra_inactivity_notices set welcome_back_pending = false
  where user_id = (select auth.uid()) and welcome_back_pending;
  return found;
end;
$$;


--
-- Name: zyra_normalise_profile_identity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_normalise_profile_identity() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.first_name IS NOT NULL THEN
    NEW.first_name := btrim(NEW.first_name);
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: FUNCTION zyra_normalise_profile_identity(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_normalise_profile_identity() IS 'Trims first_name on every write path. Deliberately NOT extended to surname_line or bio — those have the same missing-limit problem but no agreed limit yet, and inventing one here would be a decision smuggled into a migration. See ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION.';


--
-- Name: zyra_notification_category(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_notification_category(p_type text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $$
declare v_category text;
begin
  if p_type in ('new_device_signin', 'password_changed', 'account_action', 'inactivity_warning',
    'journey_ended_profile_inactive') then
    return null;
  end if;
  v_category := case p_type
    when 'new_match' then 'matches_journeys'
    when 'new_message' then 'matches_journeys'
    when 'journey_ended' then 'matches_journeys'
    when 'journey_request' then 'matches_journeys'
    when 'journey_request_accepted' then 'matches_journeys'
    when 'journey_request_declined' then 'matches_journeys'
    when 'milestone_proposed' then 'matches_journeys'
    when 'milestone_confirmed' then 'matches_journeys'
    when 'pause_nudge' then 'matches_journeys'
    when 'journey_paused' then 'matches_journeys'
    when 'journey_also_paused' then 'matches_journeys'
    when 'journey_continued' then 'matches_journeys'
    when 'wali_request' then 'guardian_activity'
    when 'wali_invite_received' then 'guardian_activity'
    when 'wali_invite_declined' then 'guardian_activity'
    when 'wali_invite_expiring' then 'guardian_activity'
    when 'wali_invite_expired' then 'guardian_activity'
    when 'wali_invite_revoked' then 'guardian_activity'
    when 'family_review_opened' then 'guardian_activity'
    when 'family_review_due' then 'guardian_activity'
    when 'guardian_digest' then 'guardian_activity'
    when 'introduction_received' then 'introductions'
    when 'introduction_answered' then 'introductions'
    when 'entitlement_changed' then 'product_updates'
    when 'credits_low' then 'product_updates'
    when 'circle_message' then 'circle'
    else null
  end;
  if v_category is null then
    raise exception 'unknown_notification_type: %', p_type using errcode = '22023';
  end if;
  return v_category;
end;
$$;


--
-- Name: zyra_notification_preferences(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_notification_preferences() RETURNS TABLE(category text, enabled boolean, changed_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  with defaults(category, enabled) as (
    values ('matches_journeys', true), ('guardian_activity', true),
           ('introductions', true), ('marketing_emails', false),
           ('product_updates', false), ('circle', true)
  ),
  latest as (
    select distinct on (p.category) p.category, p.enabled, p.changed_at
    from public.notification_preferences p
    where p.user_id = (select auth.uid())
    order by p.category, p.seq desc
  )
  select d.category, coalesce(l.enabled, d.enabled), l.changed_at
  from defaults d left join latest l on l.category = d.category;
$$;


--
-- Name: zyra_onboarding_complete(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_onboarding_complete(p_user uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles p
     WHERE p.id = p_user AND p.role = 'seeker'
       AND p.profile_complete
       AND zyra_onboarding_data_complete(p.id, p.gender)
  );
$$;


--
-- Name: FUNCTION zyra_onboarding_complete(p_user uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_onboarding_complete(p_user uuid) IS 'OA-ZYRA-193(c). True when this Seeker has finished onboarding: basic profile, Chapter 2, and every Chapter 3/4 question they were actually shown. Applicability accounts for gender AND conditional showIf rules — a question skipped because it did not apply is not missing.';


--
-- Name: zyra_onboarding_data_complete(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_onboarding_data_complete(p_user uuid, p_gender text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT p_gender IS NOT NULL
    AND EXISTS (SELECT 1 FROM seeker_details sd
                 WHERE sd.user_id = p_user
                   AND sd.preferences IS NOT NULL
                   AND sd.preferences <> '{}'::jsonb)
    AND NOT EXISTS (
      SELECT 1
        FROM zyra_onboarding_questions q
        LEFT JOIN onboarding_answers oa ON oa.user_id = p_user
       WHERE (q.gender_visibility = 'all'
              OR (q.gender_visibility = 'menOnly'   AND p_gender = 'male')
              OR (q.gender_visibility = 'womenOnly' AND p_gender = 'female'))
         AND (q.show_if_qid IS NULL
              OR coalesce(oa.ch3_answers,'{}'::jsonb) -> q.show_if_qid IS NULL
              OR jsonb_typeof(coalesce(oa.ch3_answers,'{}'::jsonb) -> q.show_if_qid) = 'null'
              OR NOT (coalesce(q.show_if_not_any_of,'[]'::jsonb)
                        ? (coalesce(oa.ch3_answers,'{}'::jsonb) ->> q.show_if_qid)))
         AND (NOT (coalesce(oa.ch3_answers,'{}'::jsonb) ? q.qid)
              OR (q.ch4_scored
                  AND NOT (coalesce(oa.ch4_preferences,'{}'::jsonb) ? q.qid)))
    );
$$;


--
-- Name: zyra_onboarding_missing(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_onboarding_missing(p_user uuid) RETURNS TABLE(qid text, needs_answer boolean, needs_preference boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_gender TEXT; v_ans JSONB; v_prefs JSONB;
BEGIN
  SELECT p.gender INTO v_gender FROM profiles p WHERE p.id = p_user;
  IF v_gender IS NULL THEN RETURN; END IF;
  SELECT coalesce(oa.ch3_answers,'{}'::jsonb), coalesce(oa.ch4_preferences,'{}'::jsonb)
    INTO v_ans, v_prefs FROM onboarding_answers oa WHERE oa.user_id = p_user;
  v_ans := coalesce(v_ans,'{}'::jsonb); v_prefs := coalesce(v_prefs,'{}'::jsonb);

  RETURN QUERY
  SELECT d.qid,
         NOT (v_ans ? d.qid) AS needs_answer,
         (d.scored AND NOT (v_prefs ? d.qid)) AS needs_preference
    FROM (SELECT q.qid, bool_or(q.ch4_scored) AS scored
            FROM zyra_onboarding_questions q GROUP BY q.qid) d
   WHERE zyra_question_is_due(d.qid, v_gender, v_ans)
     AND (NOT (v_ans ? d.qid) OR (d.scored AND NOT (v_prefs ? d.qid)));
END;
$$;


--
-- Name: zyra_open_family_message_circle(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_open_family_message_circle(p_seeker uuid) RETURNS TABLE(thread_id uuid, seeker_id uuid, seeker_first_name text, participant_count bigint, can_send boolean, access_reason text, muted boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_thread uuid;
  v_can_send boolean;
  v_has_guardian boolean;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if p_seeker is null then raise exception 'invalid_seeker'; end if;
  if v_me <> p_seeker and not exists (
    select 1 from public.wali_links link
    where link.seeker_id = p_seeker and link.wali_id = v_me
      and link.status = 'active'
      and not exists (
        select 1 from public.profile_blocks block
        where (block.blocker_id = p_seeker and block.blocked_id = v_me)
           or (block.blocker_id = v_me and block.blocked_id = p_seeker)
      )
  ) then raise exception 'no_guardian_circle_access'; end if;

  insert into public.family_message_threads as circle (seeker_id)
  values (p_seeker)
  -- The RETURNS TABLE output also has a seeker_id variable. Naming the
  -- constraint avoids PL/pgSQL's ambiguous-column error on first execution.
  on conflict on constraint family_message_threads_one_circle_per_seeker
  do update set seeker_id = excluded.seeker_id
  returning circle.id into v_thread;
  perform public.zyra_sync_family_message_circle_members(p_seeker);

  if not exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = v_thread and membership.user_id = v_me
      and membership.left_at is null
  ) then raise exception 'no_guardian_circle_access'; end if;

  v_can_send := public.zyra_family_message_circle_can_send(p_seeker);
  select exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = v_thread
      and membership.member_role = 'guardian'
      and membership.left_at is null
  ) into v_has_guardian;

  return query
  select v_thread, profile.id, profile.first_name,
    (select count(*) from public.family_message_memberships membership
     where membership.thread_id = v_thread and membership.left_at is null),
    v_can_send,
    case when not v_has_guardian then 'link_inactive'
         when v_can_send then 'ready'
         else 'membership_required' end,
    coalesce(state.muted_at is not null, false)
  from public.profiles profile
  left join public.family_message_participant_state state
    on state.thread_id = v_thread and state.user_id = v_me
  where profile.id = p_seeker;
end;
$$;


--
-- Name: zyra_pass_clears_others(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_pass_clears_others() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  DELETE FROM likes WHERE liker_id = NEW.passer_id AND liked_id = NEW.passed_id;
  DELETE FROM saves WHERE saver_id = NEW.passer_id AND saved_id = NEW.passed_id;
  RETURN NEW;
END;
$$;


--
-- Name: zyra_product_event_summary(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_product_event_summary(p_from timestamp with time zone, p_to timestamp with time zone) RETURNS TABLE(feature_key text, event_name text, action_key text, surface_key text, platform_key text, app_version text, build_number text, event_count bigint, first_seen_at timestamp with time zone, last_seen_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select
    events.feature_key,
    events.event_name,
    events.action_key,
    events.surface_key,
    events.platform_key,
    events.app_version,
    events.build_number,
    count(*)::bigint as event_count,
    min(events.occurred_at) as first_seen_at,
    max(events.occurred_at) as last_seen_at
  from private.zyra_product_events as events
  where p_from is not null
    and p_to is not null
    and p_from < p_to
    and events.occurred_at >= p_from
    and events.occurred_at < p_to
  group by
    events.feature_key,
    events.event_name,
    events.action_key,
    events.surface_key,
    events.platform_key,
    events.app_version,
    events.build_number
  order by event_count desc, events.feature_key, events.event_name;
$$;


--
-- Name: FUNCTION zyra_product_event_summary(p_from timestamp with time zone, p_to timestamp with time zone); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_product_event_summary(p_from timestamp with time zone, p_to timestamp with time zone) IS 'Service-role-only aggregate product evidence. Returns fixed taxonomy and counts; it cannot return member, device, session or free-text data.';


--
-- Name: zyra_profile_video_for(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_profile_video_for(p_user uuid) RETURNS TABLE(storage_path text, duration_ms integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select video.storage_path, video.duration_ms
  from public.profile_videos video
  where video.user_id = p_user
    and video.status = 'approved'
    and public.zyra_can_read_profile_video_object(video.storage_path);
$$;


--
-- Name: zyra_profiles_set_onboarding_complete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_profiles_set_onboarding_complete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- BEFORE, and computed from NEW: no second write, so no recursion.
  NEW.onboarding_complete :=
    (NEW.role = 'seeker' AND NEW.profile_complete
     AND zyra_onboarding_data_complete(NEW.id, NEW.gender));
  RETURN NEW;
END;
$$;


--
-- Name: zyra_propose_milestone(uuid, text, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_propose_milestone(p_match_id uuid, p_type text, p_occurred_on date) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  caller UUID := auth.uid();
  m RECORD; v_attempt UUID; v_timeline UUID; v_other UUID;
  v_pending RECORD; v_id UUID; v_name TEXT; v_label TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  IF p_type NOT IN ('meeting','nikah') THEN RAISE EXCEPTION 'bad_milestone_type'; END IF;
  IF p_occurred_on > current_date THEN
    RAISE EXCEPTION 'milestone_in_future'
      USING HINT = 'A milestone records something that has happened.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id and seeker_a_id is not null and seeker_b_id is not null for update;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'journey_not_active'; END IF;
  IF m.suspended_by IS NOT NULL THEN
    RAISE EXCEPTION 'journey_paused'
      USING HINT = 'A paused Journey is frozen — resume it first.';
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = v_attempt;
  IF v_timeline IS NOT NULL AND EXISTS (
      SELECT 1 FROM timeline_milestones
       WHERE timeline_id = v_timeline AND milestone_type = p_type) THEN
    RAISE EXCEPTION 'milestone_already_recorded';
  END IF;

  SELECT * INTO v_pending FROM journey_milestone_attestations
   WHERE attempt_id = v_attempt AND milestone_type = p_type AND status = 'pending';
  IF FOUND THEN
    IF v_pending.proposed_by <> caller THEN
      -- The other party already proposed this — the right move is to
      -- confirm theirs, not to race a second proposal.
      RAISE EXCEPTION 'confirm_theirs_instead'
        USING HINT = 'They have already proposed this milestone — confirm or discuss it.';
    END IF;
    UPDATE journey_milestone_attestations SET status = 'superseded' WHERE id = v_pending.id;
  END IF;

  INSERT INTO journey_milestone_attestations
    (match_id, attempt_id, milestone_type, occurred_on, proposed_by)
  VALUES (p_match_id, v_attempt, p_type, p_occurred_on, caller)
  RETURNING id INTO v_id;

  v_other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;
  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  v_label := CASE p_type WHEN 'meeting' THEN 'first meeting' ELSE 'Nikah' END;
  PERFORM create_notification(
    v_other, 'milestone_proposed', 'Milestone to confirm',
    COALESCE(v_name,'They')||' says your '||v_label||' was on '
      ||to_char(p_occurred_on,'DD FMMonth YYYY')||'. Confirm it to add it to your Timeline.',
    p_match_id);
  RETURN v_id;
END; $$;


--
-- Name: FUNCTION zyra_propose_milestone(p_match_id uuid, p_type text, p_occurred_on date); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_propose_milestone(p_match_id uuid, p_type text, p_occurred_on date) IS 'Proposes a meeting/nikah milestone (Founder 2026-08-12). Party-only, active un-paused Journeys, never future-dated, one pending per type; the counterpart is notified and must confirm before anything reaches the Timeline.';


--
-- Name: zyra_prune_product_events(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_prune_product_events() RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_deleted bigint;
begin
  delete from private.zyra_product_events as events
  where events.occurred_at < statement_timestamp() - interval '30 days';

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;


--
-- Name: FUNCTION zyra_prune_product_events(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_prune_product_events() IS 'Service-role-only fixed retention control. Deletes raw product events older than 30 days and returns only the deleted row count.';


--
-- Name: zyra_purge_expired_family_message_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_purge_expired_family_message_data() RETURNS TABLE(deleted_messages bigint, deleted_evidence bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: zyra_purge_expired_safety_messages(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_purge_expired_safety_messages() RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_count bigint;
begin
  delete from private.safety_sealed_messages sealed
  where sealed.purge_at <= now() and not exists (
    select 1 from private.zyra_circle_seal_protections protection
    join public.family_message_reports report on report.id = protection.report_id
    left join public.family_message_report_evidence evidence on evidence.report_id = report.id
    where protection.sealed_message_id = sealed.id
      and (report.status in ('pending', 'reviewing') or evidence.legal_hold)
  ) and not exists (
    select 1 from public.journey_attempts attempt
    where attempt.id = sealed.circle_attempt_id
      and (private.zyra_attempt_has_open_report(attempt.id)
        or private.zyra_match_has_active_hold(attempt.match_id))
  );
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;


--
-- Name: zyra_question_is_due(text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_question_is_due(p_qid text, p_gender text, p_answers jsonb) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
      FROM zyra_onboarding_questions q
     WHERE q.qid = p_qid
       -- gender half
       AND (q.gender_visibility = 'all'
            OR (q.gender_visibility = 'menOnly'   AND p_gender = 'male')
            OR (q.gender_visibility = 'womenOnly' AND p_gender = 'female'))
       -- conditional half. Unanswered controller shows the question, matching
       -- ShowIf.evaluate: "showing a question that could have been skipped is
       -- recoverable, whereas hiding one that should have been asked is not."
       AND (q.show_if_qid IS NULL
            OR p_answers -> q.show_if_qid IS NULL
            OR jsonb_typeof(p_answers -> q.show_if_qid) = 'null'
            OR (jsonb_typeof(p_answers -> q.show_if_qid) = 'array'
                AND NOT EXISTS (
                  SELECT 1 FROM jsonb_array_elements_text(p_answers -> q.show_if_qid) v
                   WHERE coalesce(q.show_if_not_any_of,'[]'::jsonb) ? v.value))
            OR (jsonb_typeof(p_answers -> q.show_if_qid) <> 'array'
                AND NOT (coalesce(q.show_if_not_any_of,'[]'::jsonb)
                           ? (p_answers ->> q.show_if_qid))))
  );
$$;


--
-- Name: zyra_record_identity_verification_consent(text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_record_identity_verification_consent(p_consent_version text, p_granted boolean) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'private'
    AS $$
declare
  v_me uuid := auth.uid();
  v_attempt private.identity_verification_attempts%rowtype;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;
  if p_consent_version is distinct from
     'idv_sumsub_biometric_v1_2026-08-29' then
    raise exception 'unsupported_consent_version';
  end if;

  -- Verified is terminal. A public client cannot create a fresh pending row
  -- over it or use consent replay to move itself backwards/forwards.
  select * into v_attempt
  from private.identity_verification_attempts
  where user_id = v_me
    and member_deleted_at is null
    and result = 'verified'
  limit 1;

  if not found then
    -- Close unfinished unbound attempts before recording a new explicit
    -- decision. A provider-bound attempt is left untouched and must be
    -- resolved through the Phase B webhook adapter.
    update private.identity_verification_attempts
       set result = 'cancelled',
           decided_at = coalesce(decided_at, now())
     where user_id = v_me
       and member_deleted_at is null
       and provider_session_ref is null
       and result in ('pending', 'retry_required', 'review_required');

    insert into private.identity_verification_attempts (
      user_id,
      result,
      consent_granted,
      consent_version,
      decided_at
    ) values (
      v_me,
      case when p_granted then 'pending' else 'cancelled' end,
      p_granted,
      p_consent_version,
      case when p_granted then null else now() end
    )
    returning * into v_attempt;
  end if;

  return jsonb_build_object(
    'result', v_attempt.result,
    'duplicate_review_required', v_attempt.duplicate_review_required,
    'consent_granted', v_attempt.consent_granted,
    'consent_version', v_attempt.consent_version,
    'consent_recorded_at', v_attempt.consent_recorded_at,
    'updated_at', v_attempt.updated_at,
    'decided_at', v_attempt.decided_at
  );
end;
$$;


--
-- Name: zyra_record_identity_verification_provider_result(text, text, text, boolean, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_record_identity_verification_provider_result(p_provider_code text, p_provider_session_ref text, p_result text, p_duplicate_review_required boolean, p_provider_event_ref_hash text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'private'
    AS $_$
declare
  v_attempt private.identity_verification_attempts%rowtype;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service_role_required';
  end if;
  if p_result not in (
    'pending', 'verified', 'retry_required', 'review_required',
    'failed', 'expired', 'cancelled'
  ) then
    raise exception 'invalid_coarse_result';
  end if;
  if p_provider_event_ref_hash is null
     or p_provider_event_ref_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_event_reference_hash';
  end if;
  if p_duplicate_review_required is true and p_result <> 'review_required' then
    raise exception 'duplicate_requires_review';
  end if;
  if p_result = 'verified' and p_duplicate_review_required is true then
    raise exception 'verified_cannot_require_duplicate_review';
  end if;

  -- Idempotency: a replay of an already-durable event is a success.
  if exists (
    select 1 from private.identity_verification_event_receipts
    where provider_event_ref_hash = p_provider_event_ref_hash
  ) then
    return true;
  end if;

  select * into v_attempt
  from private.identity_verification_attempts
  where provider_code = p_provider_code
    and provider_session_ref = p_provider_session_ref
    and member_deleted_at is null
  limit 1
  for update;

  if not found then raise exception 'unknown_provider_session'; end if;

  -- Allowlisted monotonic state machine. Final states never reopen, and a
  -- review can resolve only to another review, verified or failed.
  if not (
    (v_attempt.result in ('pending', 'retry_required') and p_result in (
      'pending', 'retry_required', 'review_required', 'verified',
      'failed', 'expired', 'cancelled'
    ))
    or (v_attempt.result = 'review_required'
        and p_result in ('review_required', 'verified', 'failed'))
    or v_attempt.result = p_result
  ) then
    raise exception 'invalid_identity_verification_transition';
  end if;

  update private.identity_verification_attempts
     set result = p_result,
         duplicate_review_required = p_duplicate_review_required,
         provider_event_ref_hash = p_provider_event_ref_hash,
         decided_at = case
           when p_result in ('verified', 'failed', 'expired', 'cancelled')
             then coalesce(decided_at, now())
           else decided_at
         end
   where id = v_attempt.id;

  insert into private.identity_verification_event_receipts (
    provider_event_ref_hash,
    attempt_id,
    mapped_result
  ) values (
    p_provider_event_ref_hash,
    v_attempt.id,
    p_result
  );
  return true;
end;
$_$;


--
-- Name: zyra_record_journey_milestone(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_record_journey_milestone() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_timeline UUID;
  v_attempt  UUID;
  v_type     TEXT;
  v_old_ord  INT;
  v_new_ord  INT;
  -- SALAM FIRST (DR-ZYRA-183): this array decides forward vs backward,
  -- so it must mirror zyra_advance_stage's map exactly.
  v_order    TEXT[] := ARRAY['salam_exchange','compatibility_reveal','wali_gate',
                             'phase_1','phase_2','phase_3','family_stage','conversation'];
BEGIN
  -- Account erasure may close a held match without creating new Timeline data.
  IF EXISTS (
    SELECT 1 FROM private.zyra_account_deleted_matches d WHERE d.match_id = NEW.id
  ) THEN RETURN NEW; END IF;

  -- A purged match projection must never write legacy events to an older
  -- surviving attempt. A new active attempt starts a new projection.
  IF NEW.status = 'ended' AND EXISTS (
    SELECT 1 FROM private.zyra_purged_ended_match_projections p WHERE p.match_id = NEW.id
  ) THEN RETURN NEW; END IF;
  IF NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active' THEN
    DELETE FROM private.zyra_purged_ended_match_projections WHERE match_id = NEW.id;
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = NEW.id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RETURN NEW; END IF;

  INSERT INTO timelines (match_id, attempt_id) VALUES (NEW.id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;
  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = v_attempt;
  IF v_timeline IS NULL THEN RETURN NEW; END IF;

  IF NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_started') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_started');
    END IF;
  END IF;

  -- Pauses and resumes — DR-ZYRA-142 (2026-08-12): the Timeline records
  -- the PAIR, dated, nameless and reasonless. Deliberately NOT deduped:
  -- a couple may pause many times, and each "paused … continued" pair is
  -- part of the story, quiet by styling rather than by omission. Who
  -- paused is never written — the Timeline is the keepsake, not a ledger
  -- of responsibility (Main Guardians can read it, which is exactly why).
  IF NEW.suspended_by IS NOT NULL AND OLD.suspended_by IS NULL THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_paused');
  END IF;
  -- An end-while-paused writes no "continued": journey_ended below
  -- already closes the chapter.
  IF NEW.suspended_by IS NULL AND OLD.suspended_by IS NOT NULL
     AND NEW.status = 'active' THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_continued');
  END IF;

  IF NEW.journey_stage IS DISTINCT FROM OLD.journey_stage
     AND OLD.journey_stage IS NOT NULL THEN

    v_old_ord := array_position(v_order, OLD.journey_stage);
    v_new_ord := array_position(v_order, NEW.journey_stage);

    IF v_old_ord IS NOT NULL AND v_new_ord IS NOT NULL AND v_new_ord > v_old_ord THEN

      v_type := CASE OLD.journey_stage
                  WHEN 'compatibility_reveal' THEN 'compatibility_revealed'
                  WHEN 'salam_exchange'       THEN 'salam_exchanged'
                  WHEN 'wali_gate'            THEN 'guardian_linked'
                  WHEN 'phase_1'              THEN 'phase_1_complete'
                  WHEN 'phase_2'              THEN 'phase_2_complete'
                  WHEN 'phase_3'              THEN 'phase_3_complete'
                  WHEN 'family_stage'         THEN 'family_stage'
                END;

      IF v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = v_type) THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (v_timeline, v_type);
      END IF;

      IF NEW.journey_stage = 'conversation' AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = 'conversation_started') THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type)
        VALUES (v_timeline, 'conversation_started');
      END IF;
    END IF;
  END IF;

  -- Endings — NOW GUARDED (2026-08-12): zyra_end_match_internal writes the
  -- same milestone after this trigger has fired.
  IF NEW.status = 'ended' AND OLD.status IS DISTINCT FROM 'ended' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_ended') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_ended');
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: FUNCTION zyra_record_journey_milestone(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_record_journey_milestone() IS 'Writes a Timeline milestone whenever a match starts, advances a Journey stage forward, or ends. Forward-only, so a dev rewind leaves no trace. One place, because journey_stage is moved from five.';


--
-- Name: zyra_record_product_event(text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_record_product_event(p_feature_key text, p_event_name text, p_action_key text, p_surface_key text, p_platform_key text, p_app_version text, p_build_number text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
begin
  if auth.uid() is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required';
  end if;

  -- Explicit guards give callers a stable 22023 contract before the table's
  -- integrity constraints provide the final independent enforcement layer.
  if p_feature_key is null or p_feature_key not in (
    'browse', 'connections', 'myZyra', 'guardian', 'journey', 'profile',
    'zyraCode', 'membership', 'identityCheck', 'support'
  ) then
    raise exception using errcode = '22023', message = 'Unknown feature key';
  end if;
  if p_event_name is null or p_event_name not in (
    'shown', 'opened', 'started', 'completed', 'failed'
  ) then
    raise exception using errcode = '22023', message = 'Unknown event name';
  end if;
  if p_action_key is null or p_action_key not in (
    'pageView', 'zyraCodeCheck', 'zyraCodeRequest',
    'knownPersonConsider', 'supportAnswer', 'supportEmail',
    'identityProvider', 'guardianHistoryConsent', 'guardianReport',
    'guardianMakeMain', 'guardianRemove'
  ) then
    raise exception using errcode = '22023', message = 'Unknown action key';
  end if;
  if p_surface_key is null or p_surface_key not in (
    'seeker', 'guardian', 'entry'
  ) then
    raise exception using errcode = '22023', message = 'Unknown surface key';
  end if;
  if p_platform_key is null or p_platform_key not in (
    'ios', 'android', 'web', 'macos', 'windows', 'linux', 'fuchsia'
  ) then
    raise exception using errcode = '22023', message = 'Unknown platform key';
  end if;
  if p_app_version is null
     or length(p_app_version) not between 1 and 32
     or p_app_version !~ '^[0-9A-Za-z.+-]+$' then
    raise exception using errcode = '22023', message = 'Invalid app version';
  end if;
  if p_build_number is null
     or length(p_build_number) not between 1 and 32
     or p_build_number !~ '^[0-9A-Za-z.+-]+$' then
    raise exception using errcode = '22023', message = 'Invalid build number';
  end if;

  -- Serialize concurrent submissions from one authenticated principal without
  -- storing that principal or its hash. This is a transaction-scoped lock;
  -- it disappears when the call ends and is not product evidence.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(auth.uid()::text, 256)
  );

  -- Privacy-safe project circuit breaker. Telemetry is non-critical, so it is
  -- safer to drop excess evidence than let a broken or hostile client create
  -- unbounded write cost. This uses only the occurred_at index and persists no
  -- caller, device, network or session identifier.
  if (
    select count(*)
    from private.zyra_product_events as events
    where events.occurred_at >= statement_timestamp() - interval '1 minute'
  ) >= 5000 then
    return;
  end if;

  insert into private.zyra_product_events (
    feature_key,
    event_name,
    action_key,
    surface_key,
    platform_key,
    app_version,
    build_number
  ) values (
    p_feature_key,
    p_event_name,
    p_action_key,
    p_surface_key,
    p_platform_key,
    p_app_version,
    p_build_number
  );
end;
$_$;


--
-- Name: FUNCTION zyra_record_product_event(p_feature_key text, p_event_name text, p_action_key text, p_surface_key text, p_platform_key text, p_app_version text, p_build_number text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_record_product_event(p_feature_key text, p_event_name text, p_action_key text, p_surface_key text, p_platform_key text, p_app_version text, p_build_number text) IS 'Records one allowlisted, identifier-free ZYRA product event for an authenticated caller. No arbitrary attributes or caller identity persist.';


--
-- Name: zyra_record_profile_video(uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_record_profile_video(p_user uuid, p_path text, p_duration_ms integer) RETURNS uuid
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select public.zyra_record_profile_video(p_user, p_path, p_duration_ms, (
    select object.id from storage.objects object
    where object.bucket_id = 'profile-videos' and object.name = p_path
  ));
$$;


--
-- Name: zyra_record_profile_video(uuid, text, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_record_profile_video(p_user uuid, p_path text, p_duration_ms integer, p_object_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
declare
  v_previous public.profile_videos%rowtype;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('zyra_profile_video:' || p_user::text, 0)
  );
  if not public.zyra_has_paid_role(p_user, 'seeker') then
    raise insufficient_privilege using message = 'profile_video_not_allowed';
  end if;
  if p_path is null or pg_catalog.split_part(p_path, '/', 1) <> p_user::text
    or p_path !~ '^[0-9a-f-]{36}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](mp4|mov)$'
    or p_duration_ms is null or p_duration_ms not between 1 and 10500 then
    raise invalid_parameter_value using message = 'profile_video_invalid_upload';
  end if;

  perform 1 from storage.objects object
  where object.id = p_object_id and object.bucket_id = 'profile-videos' and object.name = p_path
  for key share;
  if not found then
    raise object_not_in_prerequisite_state using message = 'profile_video_upload_changed';
  end if;

  select video.* into v_previous
  from public.profile_videos video
  where video.storage_path = p_path;
  if found then
    if v_previous.id = p_object_id and v_previous.status in ('pending', 'approved') then
      return v_previous.id;
    end if;
    raise object_not_in_prerequisite_state using message = 'profile_video_path_used';
  end if;

  update public.profile_videos
  set status = 'removed'
  where user_id = p_user and status in ('pending', 'approved');

  insert into public.profile_videos (id, user_id, storage_path, status, duration_ms)
  values (p_object_id, p_user, p_path, 'pending', p_duration_ms);
  return p_object_id;
end;
$_$;


--
-- Name: zyra_refresh_onboarding_complete(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_refresh_onboarding_complete(p_user uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE profiles p
     SET onboarding_complete =
           (p.role = 'seeker' AND p.profile_complete
            AND zyra_onboarding_data_complete(p.id, p.gender))
   WHERE p.id = p_user
     -- Only when it actually changes: this fires from AFTER triggers on
     -- other tables, and an unconditional UPDATE would re-enter the BEFORE
     -- trigger on profiles on every answer saved during onboarding.
     AND p.onboarding_complete IS DISTINCT FROM
           (p.role = 'seeker' AND p.profile_complete
            AND zyra_onboarding_data_complete(p.id, p.gender));
END;
$$;


--
-- Name: zyra_remove_ended_journey(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_remove_ended_journey(p_attempt_id uuid) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select private.zyra_remove_ended_journey_for(p_attempt_id, (select auth.uid()));
$$;


--
-- Name: zyra_remove_guardian(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_remove_guardian(p_wali_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := (select auth.uid());
  v_n integer;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  if not exists (
    select 1
    from public.wali_links w
    where w.seeker_id = v_me
      and w.wali_id = p_wali_id
      and w.status = 'active'
  ) then
    raise exception 'not_your_guardian';
  end if;

  update public.wali_links
     set status = 'removed',
         is_main = false
   where seeker_id = v_me
     and wali_id = p_wali_id
     and status = 'active';

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$$;


--
-- Name: FUNCTION zyra_remove_guardian(p_wali_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_remove_guardian(p_wali_id uuid) IS 'DR-ZYRA-236. Caller-bound Seeker unlink action. A Main Guardian may be removed without automatic replacement; remaining Guardians stay Additional until the Seeker deliberately chooses a Main. A no-Main state holds ordinary Active Journey participation in the client while Ending remains available.';


--
-- Name: zyra_remove_my_profile_video(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_remove_my_profile_video() RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user uuid := (select auth.uid());
  v_path text;
begin
  if v_user is null then
    raise insufficient_privilege using message = 'profile_video_not_allowed';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('zyra_profile_video:' || v_user::text, 0)
  );
  update public.profile_videos
  set status = 'removed'
  where user_id = v_user and status in ('pending', 'approved')
  returning storage_path into v_path;
  return v_path;
end;
$$;


--
-- Name: zyra_remove_profile_photo(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_remove_profile_photo(photo uuid, expected_revision integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_existing public.profile_photos%rowtype;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  select p.* into v_existing from public.profile_photos p
   where p.id = photo and p.user_id = v_me and p.removed_at is null for update;
  if not found or expected_revision is distinct from v_existing.revision then
    raise exception using errcode = '40001', message = 'stale';
  end if;
  update public.profile_photos
  set removed_at = now(), is_primary = false, revision = v_existing.revision + 1
  where id = photo;
  perform private.zyra_queue_owned_photo_object(v_me, 'profile-photos', v_existing.storage_path);
  perform private.zyra_queue_owned_photo_object(v_me, 'profile-photo-sources', v_existing.source_path);
  return jsonb_build_object('revision', v_existing.revision + 1);
end;
$$;


--
-- Name: zyra_report_family_message(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_report_family_message(p_thread uuid, p_message uuid, p_reason text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_reported uuid;
  v_id uuid;
  v_chat uuid;
  v_kind text;
begin
  if p_reason not in (
    'harassment', 'inappropriate_content', 'violence', 'privacy', 'other'
  ) then raise exception 'invalid_report_reason'; end if;
  select message.chat_id, message.sender_id, chat.kind into v_chat, v_reported, v_kind
  from public.family_messages message
  join public.family_message_chats chat on chat.id = message.chat_id
  where message.id = p_message and message.thread_id = p_thread
    and message.kind = 'message' and message.sender_id is distinct from v_me
    and private.zyra_family_chat_message_visible(message.chat_id, message.created_at);
  if v_chat is null then raise exception 'message_not_reportable'; end if;
  perform private.zyra_lock_family_chat_profiles(p_thread, v_reported);
  if v_kind = 'journey' and not private.zyra_lock_family_chat_match(p_thread, v_chat) then
    raise exception 'message_not_reportable';
  end if;
  select message.sender_id into v_reported
  from public.family_messages message
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = v_me and membership.left_at is null
  where message.id = p_message and message.thread_id = p_thread
    and message.kind = 'message' and message.sender_id is distinct from v_me
    and message.created_at >= membership.readable_from
    and private.zyra_family_chat_message_visible(message.chat_id, message.created_at);
  if v_reported is null then raise exception 'message_not_reportable'; end if;
  insert into public.family_message_reports
    (thread_id, message_id, reporter_id, reported_id, reason)
  values (p_thread, p_message, v_me, v_reported, p_reason)
  returning id into v_id;
  return v_id;
end;
$$;


--
-- Name: zyra_request_guardian_link(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_request_guardian_link(p_code text, p_relationship text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_my_role text;
  v_owner uuid;
  v_owner_role text;
  v_code_id uuid;
  v_request_id uuid;
  v_my_name text;
  v_preview_role text;
  v_created_at timestamptz;
  v_deadline timestamptz;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  if p_relationship is not null and p_relationship not in (
    'father','brother','grandfather','uncle','legal_guardian',
    'family_representative','other'
  ) then raise exception 'unknown_relationship'; end if;

  -- The mutation cannot bypass preview's authentication, neutral filtering or
  -- rate limit by calling this RPC directly.
  select preview.owner_role into v_preview_role
  from public.zyra_preview_personal_code(p_code) preview;
  if v_preview_role is null then return null; end if;

  select p.role, p.first_name into v_my_role, v_my_name
  from public.profiles p where p.id = v_me;
  select c.id, c.owner_id, c.role_context
    into v_code_id, v_owner, v_owner_role
  from private.zyra_personal_codes c
  join public.profiles owner_profile
    on owner_profile.id = c.owner_id and owner_profile.role = c.role_context
  where c.code = v_code;

  if v_owner is null or v_owner = v_me or v_my_role not in ('seeker','wali')
     or v_owner_role = v_my_role
     or public.zyra_block_exists(v_owner)
     or not public.zyra_can_guardian_link(v_me, v_owner) then
    raise exception 'code_unavailable';
  end if;
  if v_my_role = 'wali' and p_relationship is null then
    raise exception 'relationship_required';
  end if;
  if v_my_role = 'seeker' and p_relationship is not null then
    raise exception 'relationship_owned_by_guardian';
  end if;
  if exists (
    select 1 from public.wali_links wl
    where ((wl.seeker_id = v_me and wl.wali_id = v_owner)
        or (wl.seeker_id = v_owner and wl.wali_id = v_me))
      and wl.status = 'active'
  ) then raise exception 'already_linked'; end if;

  update public.wali_invites wi
     set status = 'expired'
   where wi.source = 'personal_code'
     and wi.personal_code_id = v_code_id
     and wi.recipient_id = v_me
     and wi.status = 'pending'
     and wi.request_expires_at <= clock_timestamp();

  v_created_at := clock_timestamp();
  v_deadline := v_created_at + interval '14 days';
  insert into public.wali_invites(
    token, inviter_id, inviter_role, status, relationship, source,
    personal_code_id, recipient_id, created_at, expires_at, request_expires_at
  ) values (
    'REQ-' || upper(encode(extensions.gen_random_bytes(12), 'hex')),
    v_owner, v_owner_role, 'pending',
    case when v_my_role = 'wali' then p_relationship else null end,
    'personal_code', v_code_id, v_me,
    v_created_at, v_deadline, v_deadline
  )
  returning id into v_request_id;

  perform private.zyra_create_notification(
    v_owner, 'wali_request', 'Guardian request',
    coalesce(v_my_name, 'Someone') || ' sent you a Guardian request.', null, v_me, v_request_id, null);
  return v_request_id;
exception
  when unique_violation then raise exception 'request_already_pending';
end;
$$;


--
-- Name: FUNCTION zyra_request_guardian_link(p_code text, p_relationship text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_request_guardian_link(p_code text, p_relationship text) IS 'Creates a 14-day two-sided request against a permanent ZYRA Code. Owner acceptance is mandatory.';


--
-- Name: zyra_require_verified_family_seat(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_require_verified_family_seat() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = new.member_id
      and binding.role = new.role
  ) then
    raise exception 'verified_family_member_required';
  end if;
  return new;
end;
$$;


--
-- Name: zyra_reset_profile(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_reset_profile() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_role text;
  v_active integer;
  v_photos integer;
  v_likes integer;
  v_saves integer;
  v_passes integer;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  select role into v_role from public.profiles where id = v_me;
  if v_role is null then raise exception 'no_profile'; end if;
  if v_role <> 'seeker' then return jsonb_build_object('status','refused','reason','not_a_seeker'); end if;
  select count(*) into v_active from public.matches
  where status = 'active' and (seeker_a_id = v_me or seeker_b_id = v_me);
  if v_active > 0 then
    return jsonb_build_object('status','blocked','reason','active_journey','active',v_active);
  end if;

  perform private.zyra_queue_photo_folder(v_me);
  delete from public.profile_photos where user_id = v_me;
  get diagnostics v_photos = row_count;
  delete from public.onboarding_answers where user_id = v_me;
  delete from public.seeker_details where user_id = v_me;
  delete from public.likes where liker_id = v_me or liked_id = v_me;
  get diagnostics v_likes = row_count;
  delete from public.saves where saver_id = v_me or saved_id = v_me;
  get diagnostics v_saves = row_count;
  delete from public.passes where passer_id = v_me or passed_id = v_me;
  get diagnostics v_passes = row_count;
  update public.profiles set bio = null, location_text = null, profile_complete = false where id = v_me;

  return jsonb_build_object('status','reset','photos',v_photos,'likes',v_likes,
    'saves',v_saves,'passes',v_passes,'storage_paths','[]'::jsonb);
end;
$$;


--
-- Name: FUNCTION zyra_reset_profile(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_reset_profile() IS 'Reset the signed-in Seeker after the existing Journey check. Photo cleanup is queued server-side.';


--
-- Name: zyra_reset_search(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_reset_search() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  me      UUID := auth.uid();
  cleared INTEGER;
BEGIN
  IF me IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;
  DELETE FROM passes WHERE passer_id = me;
  GET DIAGNOSTICS cleared = ROW_COUNT;
  RETURN cleared;
END;
$$;


--
-- Name: zyra_reveal_journey_compatibility(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_reveal_journey_compatibility(p_match_id uuid) RETURNS TABLE(mine_revealed boolean, counterpart_revealed boolean, my_score numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
  v_a_result private.zyra_directional_results;
  v_b_result private.zyra_directional_results;
begin
  if v_caller is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  -- All mutating doorways lock in the same order: match, active attempt,
  -- compatibility row. This serialises simultaneous A/B reveals without a
  -- lost update or duplicate-row race.
  select m.seeker_a_id, m.seeker_b_id, m.status, m.journey_stage,
         m.suspended_by, m.also_paused_by,
         coalesce(pg_catalog.to_jsonb(m) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_match
    from public.matches as m
   where m.id = p_match_id
     and v_caller in (m.seeker_a_id, m.seeker_b_id)
   for update;

  if not found then
    raise exception using errcode = '42501', message = 'not_a_party';
  end if;

  if v_match.status is distinct from 'active'
     or v_match.journey_stage is distinct from 'compatibility_reveal'
     or v_match.suspended_by is not null
     or v_match.also_paused_by is not null
     or v_match.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  select a.id, a.journey_stage, a.paused_by, a.also_paused_by,
         coalesce(pg_catalog.to_jsonb(a) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_attempt
    from public.journey_attempts as a
   where a.match_id = p_match_id
     and a.status = 'active'
   for update;

  if not found
     or v_attempt.journey_stage is distinct from 'compatibility_reveal'
     or v_attempt.paused_by is not null
     or v_attempt.also_paused_by is not null
     or v_attempt.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  v_is_a := v_caller = v_match.seeker_a_id;
  insert into public.journey_compatibility (match_id, attempt_id)
  values (p_match_id, v_attempt.id)
  on conflict (match_id) do nothing;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id
   for update;

  if v_compat.attempt_id is distinct from v_attempt.id then
    raise exception using
      errcode = '55000',
      message = 'compatibility_attempt_mismatch';
  end if;

  -- Every Journey uses the same pair of saved directions. Lock them in
  -- UUID order even if a later match represents the pair with sides reversed.
  if v_match.seeker_a_id < v_match.seeker_b_id then
    v_a_result := private.zyra_save_direction_result(v_match.seeker_a_id, v_match.seeker_b_id);
    v_b_result := private.zyra_save_direction_result(v_match.seeker_b_id, v_match.seeker_a_id);
  else
    v_b_result := private.zyra_save_direction_result(v_match.seeker_b_id, v_match.seeker_a_id);
    v_a_result := private.zyra_save_direction_result(v_match.seeker_a_id, v_match.seeker_b_id);
  end if;

  update public.journey_compatibility as jc
     set seeker_a_revealed = jc.seeker_a_revealed or v_is_a,
         seeker_b_revealed = jc.seeker_b_revealed or not v_is_a,
         seeker_a_score = case when v_a_result.state = 'ok' then v_a_result.overall end,
         seeker_b_score = case when v_b_result.state = 'ok' then v_b_result.overall end,
         revealed_at = case
           when (jc.seeker_a_revealed or v_is_a) and (jc.seeker_b_revealed or not v_is_a)
             then coalesce(jc.revealed_at, pg_catalog.statement_timestamp())
           else null
         end
   where jc.match_id = p_match_id
   returning jc.* into v_compat;

  mine_revealed := case
    when v_is_a then v_compat.seeker_a_revealed
    else v_compat.seeker_b_revealed
  end;
  counterpart_revealed := case
    when v_is_a then v_compat.seeker_b_revealed
    else v_compat.seeker_a_revealed
  end;
  my_score := case when v_compat.seeker_a_revealed and v_compat.seeker_b_revealed then
    case when v_is_a then v_compat.seeker_a_score else v_compat.seeker_b_score end
  end;

  return next;
end;
$$;


--
-- Name: FUNCTION zyra_reveal_journey_compatibility(p_match_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_reveal_journey_compatibility(p_match_id uuid) IS 'OA-ZYRA-283 / DOC-ZYRA-0472. Records the authenticated Seeker consent, projects both saved directions, and returns only the caller-owned Overall after mutual reveal.';


--
-- Name: zyra_review_profile_video(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_review_profile_video(p_video uuid, p_decision text, p_reason text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_reason text := pg_catalog.btrim(p_reason);
begin
  if p_decision is null or p_decision not in ('approved', 'rejected')
    or (p_decision = 'rejected' and (
      v_reason is null or v_reason = '' or pg_catalog.char_length(v_reason) > 160
      or v_reason ~ '[[:cntrl:]]'
    )) then
    raise invalid_parameter_value using message = 'profile_video_invalid_review';
  end if;

  update public.profile_videos video
  set status = p_decision, reviewed_at = clock_timestamp(),
      reject_reason = case when p_decision = 'rejected' then v_reason end
  where video.id = p_video and video.status = 'pending'
    and (
      p_decision = 'rejected' or exists (
        select 1 from storage.objects object
        where object.id = video.id and object.bucket_id = 'profile-videos'
          and object.name = video.storage_path
      )
    );
  if not found then
    raise object_not_in_prerequisite_state using message = 'profile_video_review_unavailable';
  end if;

  -- SERVER 0 has no shared moderation audit table. Reviewer audit: OA-AIOS-413.
end;
$$;


--
-- Name: zyra_revoke_wali_invite(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_revoke_wali_invite(p_token text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
  v_invite public.wali_invites%rowtype;
  v_inviter_name text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select * into v_invite
    from public.wali_invites wi
   where wi.token = upper(trim(p_token))
     and wi.inviter_id = v_me;
  if not found or v_invite.status <> 'pending' then return false; end if;

  update public.wali_invites
     set status = 'revoked'
   where id = v_invite.id and status = 'pending';
  if not found then return false; end if;

  if v_invite.seen_by is not null then
    select p.first_name into v_inviter_name
      from public.profiles p where p.id = v_me;
    perform private.zyra_create_notification(
      v_invite.seen_by,
      'wali_invite_revoked',
      'Guardian invitation withdrawn',
      coalesce(v_inviter_name, 'The sender') || ' withdrew the Guardian invitation.', null, v_me, v_invite.id, null);
  end if;
  return true;
end;
$$;


--
-- Name: zyra_rotate_my_personal_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_rotate_my_personal_code(p_role_context text DEFAULT NULL::text) RETURNS TABLE(code text, role_context text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_role text;
  v_requested_role text;
  v_code text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  select p.role into v_role from public.profiles p where p.id = v_me;
  if v_role not in ('seeker', 'wali') then raise exception 'profile_role_unavailable'; end if;
  v_requested_role := coalesce(p_role_context, v_role);
  if v_requested_role <> v_role then raise exception 'role_context_not_authorised'; end if;

  perform public.zyra_my_personal_code(v_requested_role);
  update private.zyra_personal_codes c
     set code = private.zyra_generate_personal_code(),
         rotated_at = clock_timestamp()
   where c.owner_id = v_me and c.role_context = v_requested_role
   returning c.code into v_code;

  return query select v_code, v_requested_role;
end;
$$;


--
-- Name: zyra_run_inactivity_job(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_run_inactivity_job() RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select private.zyra_run_inactivity_job_at(now());
$$;


--
-- Name: zyra_save_clears_others(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_save_clears_others() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  DELETE FROM passes WHERE passer_id = NEW.saver_id AND passed_id = NEW.saved_id;
  DELETE FROM likes  WHERE liker_id  = NEW.saver_id AND liked_id  = NEW.saved_id;
  RETURN NEW;
END;
$$;


--
-- Name: zyra_save_profile_photo(uuid, text, text, jsonb, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_save_profile_photo(photo uuid, display_path text, source_path text, crop jsonb, rotation integer, expected_revision integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_existing public.profile_photos%rowtype;
  v_revision integer;
  v_x numeric;
  v_y numeric;
  v_w numeric;
  v_h numeric;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  select p.* into v_existing from public.profile_photos p where p.id = photo for update;
  if (found and (v_existing.user_id <> v_me or v_existing.removed_at is not null))
     or expected_revision is distinct from coalesce(v_existing.revision, 0) then
    raise exception using errcode = '40001', message = 'stale';
  end if;
  if photo is null or source_path is distinct from v_me::text || '/' || photo::text || '.jpg'
     or not private.zyra_photo_reference_owned(v_me, display_path) then
    raise exception using errcode = '42501', message = 'photo_reference_not_owned';
  end if;
  -- Coordinate with the Storage API's row lock on delete. A staged source
  -- becomes protected by the source DELETE policy after this transaction.
  perform 1 from storage.objects o
   where o.bucket_id = 'profile-photo-sources' and o.name = source_path and o.owner_id = v_me::text
   for key share;
  if not found then
    raise exception using errcode = '42501', message = 'photo_reference_not_owned';
  end if;
  if jsonb_typeof(crop) is distinct from 'object' then
    raise exception using errcode = '22023', message = 'invalid_crop';
  end if;
  if rotation is null or rotation not in (0, 90, 180, 270)
     or crop - array['x', 'y', 'w', 'h'] <> '{}'::jsonb
     or jsonb_typeof(crop->'x') is distinct from 'number'
     or jsonb_typeof(crop->'y') is distinct from 'number'
     or jsonb_typeof(crop->'w') is distinct from 'number'
     or jsonb_typeof(crop->'h') is distinct from 'number' then
    raise exception using errcode = '22023', message = 'invalid_crop';
  end if;
  v_x := (crop->>'x')::numeric;
  v_y := (crop->>'y')::numeric;
  v_w := (crop->>'w')::numeric;
  v_h := (crop->>'h')::numeric;
  if v_x < 0 or v_y < 0 or v_w <= 0 or v_h <= 0 or v_x + v_w > 1 or v_y + v_h > 1 then
    raise exception using errcode = '22023', message = 'invalid_crop';
  end if;
  v_revision := expected_revision + 1;
  if expected_revision = 0 then
    insert into public.profile_photos (id, user_id, storage_path, source_path, crop, rotation,
                                       revision, display_order, is_primary)
    select photo, v_me, display_path, zyra_save_profile_photo.source_path,
           zyra_save_profile_photo.crop, zyra_save_profile_photo.rotation,
           v_revision, coalesce(max(p.display_order), -1) + 1, count(*) = 0
    from public.profile_photos p where p.user_id = v_me and p.removed_at is null;
  else
    update public.profile_photos p
       set storage_path = display_path, source_path = zyra_save_profile_photo.source_path,
           crop = zyra_save_profile_photo.crop, rotation = zyra_save_profile_photo.rotation,
           revision = v_revision
     where p.id = photo;
    if v_existing.storage_path is distinct from display_path then
      perform private.zyra_queue_owned_photo_object(v_me, 'profile-photos', v_existing.storage_path);
    end if;
    if v_existing.source_path is distinct from source_path then
      perform private.zyra_queue_owned_photo_object(v_me, 'profile-photo-sources', v_existing.source_path);
    end if;
  end if;
  return jsonb_build_object('revision', v_revision);
end;
$$;


--
-- Name: zyra_score_direction_v1(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_score_direction_v1(p_viewer uuid, p_subject uuid) RETURNS TABLE(capture_version text, inputs_hash text, overall numeric, area_bands jsonb, state text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
declare
  v_actor record;
  v_question record;
  v_option text;
  v_code_pattern text;
  v_selected jsonb;
  v_lights jsonb;
  v_hard_options jsonb;
  v_items jsonb := '{}'::jsonb;
  v_points numeric;
  v_ch4_version text;
  v_ch2_version text;
  v_prefs jsonb;
  v_hards jsonb;
  v_ch2_prefs jsonb;
  v_viewer_answers jsonb;
  v_subject_answers jsonb;
  v_viewer_details public.seeker_details%rowtype;
  v_subject_details public.seeker_details%rowtype;
  v_target_gender text;
  v_third_sect_key text;
  v_subject_sect_key text;
  v_current_sect_keys text[];
  v_scoring_sect jsonb;
  v_block jsonb;
  v_preferred jsonb;
  v_actual jsonb;
  v_matching boolean;
begin
  state := 'incomplete';
  if p_viewer is null or p_subject is null or p_viewer = p_subject then
    state := 'invalid';
    return next;
    return;
  end if;

  select d.* into v_viewer_details from public.seeker_details d where d.user_id = p_viewer;
  v_third_sect_key := private.zyra_current_sect_third_key(
    v_viewer_details.sect, v_viewer_details.sect_other);
  if v_third_sect_key is null then
    insert into private.zyra_compatibility_sect_repairs(viewer)
    values (p_viewer)
    on conflict (viewer) do nothing;
    state := 'unavailable';
    return next;
    return;
  end if;

  for v_actor in
    select p.id, p.gender, o.ch3_answers, o.ch4_preferences, o.ch4_hard_requirements,
           o.capture_version as ch4_version
    from public.profiles p
    left join public.onboarding_answers o on o.user_id = p.id
    where p.id in (p_viewer, p_subject) and p.role = 'seeker'
  loop
    if v_actor.gender is null then
      raise exception using errcode = 'P8910', message = 'compatibility_gender_missing';
    end if;
    perform private.zyra_compatibility_input(v_actor.ch3_answers, 'object');
    -- Match each account's own answer vocabulary and each conditional parent.
    for v_question in
      select q.qid, q.options, q.is_multi
      from public.zyra_onboarding_questions q
      where q.gender_visibility in ('all', case v_actor.gender when 'male' then 'menOnly' else 'womenOnly' end)
        and (q.show_if_qid is null or not coalesce(
          q.show_if_not_any_of ? (v_actor.ch3_answers ->> q.show_if_qid), false))
    loop
      perform private.zyra_compatibility_answer(
        v_actor.ch3_answers -> v_question.qid, v_question.qid, v_question.options, v_question.is_multi);
    end loop;

    if v_actor.id = p_viewer then
      v_viewer_answers := v_actor.ch3_answers;
      v_prefs := v_actor.ch4_preferences;
      v_hards := v_actor.ch4_hard_requirements;
      v_ch4_version := v_actor.ch4_version;
    else
      v_subject_answers := v_actor.ch3_answers;
      v_target_gender := v_actor.gender;
    end if;
  end loop;
  if v_viewer_answers is null or v_subject_answers is null then
    return next;
    return;
  end if;
  if v_target_gender = (select gender from public.profiles where id = p_viewer) then
    raise exception using errcode = 'P8911', message = 'compatibility_direction_invalid';
  end if;
  v_current_sect_keys := array['sunni', 'shia', v_third_sect_key];
  if exists (
    select 1 from unnest(v_current_sect_keys) current_key(key)
    where private.zyra_sect_light_missing(v_viewer_details.preferences, key)
  ) then
    raise exception using errcode = 'P8910', message = 'compatibility_input_missing';
  end if;
  perform private.zyra_compatibility_input(v_prefs, 'object');
  perform private.zyra_compatibility_input(v_hards, 'object');

  -- Use the subject's applicable scored items and the viewer's full option
  -- matrices. Each multi-select contributes the mean of all selected lights.
  for v_question in
    select q.qid, q.options, q.is_multi
    from public.zyra_onboarding_questions q
    where q.ch4_scored
      and q.gender_visibility in ('all', case v_target_gender when 'male' then 'menOnly' else 'womenOnly' end)
      and (q.show_if_qid is null or not coalesce(
        q.show_if_not_any_of ? (v_subject_answers ->> q.show_if_qid), false))
    order by q.qid
  loop
    v_lights := private.zyra_compatibility_input(v_prefs -> v_question.qid, 'object');
    v_hard_options := coalesce(v_hards -> v_question.qid, '[]'::jsonb);
    perform private.zyra_compatibility_input(v_hard_options, 'array');
    if exists (select 1 from jsonb_object_keys(v_lights) k where not (v_question.options ? k))
       or exists (select 1 from jsonb_array_elements(v_hard_options) h
                  where jsonb_typeof(h) <> 'string' or not (v_question.options ? (h #>> '{}'))) then
      raise exception using errcode = 'P8911', message = 'compatibility_preference_outside_bank';
    end if;
    for v_option in select jsonb_array_elements_text(v_question.options) loop
      perform private.zyra_compatibility_light(v_lights -> v_option, p_viewer, v_question.qid, v_option);
    end loop;
    v_selected := private.zyra_compatibility_answer(
      v_subject_answers -> v_question.qid, v_question.qid, v_question.options, v_question.is_multi);
    if exists (select 1 from jsonb_array_elements_text(v_selected) s where v_hard_options ? s) then
      raise exception using errcode = 'P8911', message = 'compatibility_hard_exclusion';
    end if;
    select avg(private.zyra_compatibility_light(v_lights -> option, p_viewer, v_question.qid, option))
      into v_points
      from jsonb_array_elements_text(v_selected) as selected(option);
    v_items := v_items || jsonb_build_object(v_question.qid, v_points);
  end loop;

  select d.* into v_subject_details from public.seeker_details d where d.user_id = p_subject;
  v_ch2_version := v_viewer_details.capture_version;
  v_ch2_prefs := private.zyra_compatibility_input(v_viewer_details.preferences, 'object');
  if v_viewer_details.sect is null or v_subject_details.sect is null
     or v_viewer_details.revert_status is null or v_subject_details.revert_status is null
     or v_viewer_details.country_of_birth is null or v_subject_details.country_of_birth is null
     or v_viewer_details.nationality is null or v_subject_details.nationality is null
     or v_viewer_details.ethnicity is null or v_subject_details.ethnicity is null
     or cardinality(v_viewer_details.languages) = 0 or cardinality(v_subject_details.languages) = 0 then
    raise exception using errcode = 'P8910', message = 'compatibility_chapter_two_missing';
  end if;

  v_block := private.zyra_compatibility_input(v_ch2_prefs -> 'sect', 'object');
  v_lights := private.zyra_compatibility_input(v_block -> 'matrix', 'object');
  v_subject_sect_key := private.zyra_compatibility_sect_key(
    v_subject_details.sect, v_third_sect_key);
  v_hard_options := coalesce(v_block -> 'hard_requirement', '[]'::jsonb);
  perform private.zyra_compatibility_input(v_hard_options, 'array');

  foreach v_option in array v_current_sect_keys loop
    perform private.zyra_compatibility_light(v_lights -> v_option, p_viewer, 'sect', v_option);
  end loop;
  if v_hard_options ? v_subject_sect_key then
    raise exception using errcode = 'P8911', message = 'compatibility_hard_exclusion';
  end if;
  v_points := private.zyra_compatibility_light(
    v_lights -> v_subject_sect_key, p_viewer, 'sect', v_subject_sect_key);
  v_items := v_items || jsonb_build_object('sect', v_points);
  v_scoring_sect := jsonb_build_object(
    'matrix', (select jsonb_object_agg(key, v_lights -> key)
               from unnest(v_current_sect_keys) current_key(key)),
    'hard_requirement', array(select key from unnest(v_current_sect_keys) current_key(key)
                              where v_hard_options ? key)
  );

  if v_subject_details.revert_status then
    v_points := private.zyra_compatibility_light(
      v_ch2_prefs -> 'revert' -> 'flexibility', p_viewer, 'revert', 'flexibility');
    v_items := v_items || jsonb_build_object('revert', v_points);
  end if;

  for v_question in
    select * from (values
      ('country_of_birth', to_jsonb(v_subject_details.country_of_birth), '^[A-Z]{2}$'),
      ('nationality', to_jsonb(v_subject_details.nationality), '^[A-Z]{2}$'),
      ('ethnicity', to_jsonb(v_subject_details.ethnicity), '^[a-z][a-z_]*$'),
      ('languages', to_jsonb(v_subject_details.languages), '^[a-z]{2}$')
    ) as c(item, actual, code_pattern)
  loop
    v_block := private.zyra_compatibility_input(v_ch2_prefs -> v_question.item, 'object');
    if (private.zyra_compatibility_input(v_block -> 'skipped', 'boolean') #>> '{}')::boolean then
      continue;
    end if;
    v_preferred := private.zyra_compatibility_input(v_block -> 'preferred', 'array');
    v_code_pattern := v_question.code_pattern;
    if jsonb_array_length(v_preferred) = 0 then
      raise exception using errcode = 'P8910', message = 'compatibility_preference_missing';
    end if;
    if exists (select 1 from jsonb_array_elements(v_preferred) p
               where jsonb_typeof(p) <> 'string' or (p #>> '{}') !~ v_code_pattern)
       or jsonb_array_length(v_preferred) <> (select count(distinct value) from jsonb_array_elements(v_preferred)) then
      raise exception using errcode = 'P8911', message = 'compatibility_preference_code_invalid';
    end if;
    if v_question.item = 'languages' then
      v_preferred := v_preferred - 'en';
    end if;
    if jsonb_array_length(v_preferred) = 0 then
      continue;
    end if;

    v_points := private.zyra_compatibility_light(v_block -> 'flexibility', p_viewer, v_question.item, 'flexibility');
    if v_question.item = 'languages' then
      v_actual := private.zyra_compatibility_input(v_question.actual, 'array');
      if jsonb_array_length(v_actual) = 0 then
        raise exception using errcode = 'P8910', message = 'compatibility_languages_missing';
      end if;
      if exists (select 1 from jsonb_array_elements(v_actual) a
                 where jsonb_typeof(a) <> 'string' or (a #>> '{}') !~ v_code_pattern) then
        raise exception using errcode = 'P8911', message = 'compatibility_language_code_invalid';
      end if;
      v_matching := exists (select 1 from jsonb_array_elements_text(v_actual) a where v_preferred ? a);
    else
      v_actual := private.zyra_compatibility_input(v_question.actual, 'string');
      v_matching := v_preferred ? (v_actual #>> '{}');
    end if;
    v_items := v_items || jsonb_build_object(v_question.item, case when v_matching then 1 else v_points end);
  end loop;

  if exists (select 1 from jsonb_object_keys(v_items) item
             where not exists (select 1 from private.zyra_question_area m where m.question_id = item)) then
    raise exception using errcode = 'P8911', message = 'compatibility_area_missing';
  end if;
  with counts as (
    select a.area, count(*) as items, sum(i.value::numeric) as points
    from jsonb_each_text(v_items) i
    join private.zyra_question_area a on a.question_id = i.key
    group by a.area
  )
  select round(100 * sum(c.points) / nullif(sum(c.items), 0), 1),
         jsonb_agg(case
           when coalesce(c.items, 0) < 3 then 'not_enough'
           when c.points * 4 >= c.items * 3 then 'strong'
           when c.points * 2 >= c.items then 'good'
           else 'some_differences' end order by a.area)
  into overall, area_bands
  from generate_series(1, 12) a(area) left join counts c on c.area = a.area;

  if overall is null then
    area_bands := null;
    return next;
    return;
  end if;
  capture_version := case when v_ch4_version = 'v1' and v_ch2_version = 'v1' then 'v1' else 'v0' end;
  inputs_hash := encode(sha256(convert_to(jsonb_build_array(
    p_viewer, p_subject, v_target_gender, v_viewer_answers, v_subject_answers,
    v_prefs, v_hards, v_ch2_version, v_ch4_version,
    jsonb_set(v_ch2_prefs, '{sect}', v_scoring_sect),
    (select jsonb_agg(jsonb_build_array(c.question_id, c.option_value, c.light)
                      order by c.question_id collate "C", c.option_value collate "C")
       from public.preference_light_confirmations c
      where c.user_id = p_viewer and c.light = 'amber' and c.capture_version = 'v1'
        and (c.question_id not in ('sect', 'ch2.sect.matrix')
          or c.option_value = any(v_current_sect_keys))),
    v_third_sect_key, v_viewer_details.revert_status,
    v_subject_sect_key, v_subject_details.revert_status, v_subject_details.country_of_birth,
    v_subject_details.nationality, v_subject_details.ethnicity, v_subject_details.languages
  )::text, 'UTF8')), 'hex');
  state := 'ok';
  return next;
exception
  when sqlstate 'P8910' or sqlstate 'P8911' or sqlstate 'P8912' then
    state := case sqlstate when 'P8910' then 'incomplete' when 'P8911' then 'invalid'
                 else 'needs_reconfirmation' end;
    capture_version := null;
    inputs_hash := null;
    overall := null;
    area_bands := null;
    return next;
end;
$_$;


--
-- Name: zyra_sect_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_sect_code(p_label text) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    SET search_path TO 'public'
    AS $_$
  SELECT COALESCE(
    NULLIF(
      regexp_replace(
        regexp_replace(lower(btrim(COALESCE(p_label, ''))), '[^a-z0-9]+', '-', 'g'),
        '(^-+|-+$)',
        '',
        'g'
      ),
      ''
    ),
    'other'
  );
$_$;


--
-- Name: zyra_send_family_message(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_send_family_message(p_thread uuid, p_body text) RETURNS uuid
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select public.zyra_send_family_message(p_thread, p_body, null::uuid);
$$;


--
-- Name: zyra_send_family_message(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_send_family_message(p_thread uuid, p_body text, p_chat_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_seeker uuid;
  v_body text := btrim(coalesce(p_body, ''));
  v_id uuid;
  v_chat uuid;
  v_kind text;
  v_match_locked boolean := false;
  v_now timestamptz;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if char_length(v_body) < 1 or char_length(v_body) > 2000 then
    raise exception 'invalid_message_length';
  end if;
  -- The budget is per sender, not per Circle. A Guardian can belong to more
  -- than one Circle, so thread row locks alone permit concurrent requests to
  -- pass the same rate-count check. Always take the sender lock first.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_me::text, 298)
  );
  if exists (
    select 1 from public.family_message_memberships member
    where member.thread_id = p_thread and member.user_id = v_me and member.left_at is null
  ) then
    perform private.zyra_lock_family_chat_profiles(p_thread);
  end if;
  if p_chat_id is not null then
    v_match_locked := private.zyra_lock_family_chat_match(p_thread, p_chat_id);
  end if;
  select thread.seeker_id into v_seeker
  from public.family_message_threads thread
  where thread.id = p_thread for update;
  if v_seeker is null then raise exception 'circle_not_found'; end if;
  perform public.zyra_sync_family_message_circle_members(v_seeker);
  if not exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = p_thread and membership.user_id = v_me
      and membership.left_at is null
  ) then raise exception 'circle_not_found'; end if;
  select chat.id, admitted.kind into v_chat, v_kind
  from public.family_message_chats chat
  cross join lateral private.zyra_family_chat_admission(chat.id) admitted
  where chat.thread_id = p_thread
    and ((p_chat_id is null and chat.kind = 'main') or chat.id = p_chat_id);
  if v_chat is null or (v_kind = 'journey' and not v_match_locked) then
    raise exception 'family_chat_not_found';
  end if;
  if not public.zyra_family_message_circle_can_send(v_seeker) then
    raise exception 'family_message_read_only';
  end if;
  v_now := clock_timestamp();
  if (select count(*) from public.family_messages message
      where message.sender_id = v_me and message.kind = 'message'
        and message.created_at > v_now - interval '1 minute') >= 10 then
    raise exception 'family_message_rate_minute';
  end if;
  if (select count(*) from public.family_messages message
      where message.sender_id = v_me and message.kind = 'message'
        and message.created_at > v_now - interval '1 hour') >= 60 then
    raise exception 'family_message_rate_hour';
  end if;
  insert into public.family_messages (thread_id, chat_id, sender_id, body, created_at)
  values (p_thread, v_chat, v_me, v_body, v_now) returning id into v_id;
  if v_kind = 'main' then
    update public.family_message_threads set last_message_at = v_now where id = p_thread;
  end if;
  insert into public.family_message_chat_state as chat_state (chat_id, user_id, last_read_at)
  values (v_chat, v_me, v_now)
  on conflict (chat_id, user_id) do update
    set last_read_at = greatest(chat_state.last_read_at, excluded.last_read_at);
  update public.notifications set read_at = v_now
  where user_id = v_me and related_chat_id = v_chat
    and type = 'circle_message' and read_at is null and created_at <= v_now;
  perform private.zyra_alert_family_chat_arrival(p_thread, v_chat, v_me, v_now);
  return v_id;
end;
$$;


--
-- Name: zyra_set_attempt_from_match(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_attempt_from_match() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.attempt_id is null and new.match_id is not null then
    -- The live attempt if there is one, else the newest. A pair with an
    -- active attempt is unambiguous; a pair whose only attempt has ended
    -- should still hang its rows on that attempt rather than nothing.
    select a.id into new.attempt_id
    from public.journey_attempts a
    where a.match_id = new.match_id
    order by (a.status = 'active') desc, a.attempt_number desc
    limit 1;
  end if;
  return new;
end $$;


--
-- Name: zyra_set_family_chat_muted(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_family_chat_muted(p_chat_id uuid, p_muted boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare v_me uuid := (select auth.uid());
begin
  perform private.zyra_lock_family_chat(p_chat_id);
  insert into public.family_message_chat_state (chat_id, user_id, muted_at)
  values (p_chat_id, v_me, case when p_muted then clock_timestamp() end)
  on conflict (chat_id, user_id) do update set muted_at = excluded.muted_at;
end;
$$;


--
-- Name: zyra_set_family_message_muted(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_family_message_muted(p_thread uuid, p_muted boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare v_me uuid := auth.uid();
begin
  perform private.zyra_lock_family_message_thread(p_thread);
  insert into public.family_message_participant_state(thread_id, user_id, muted_at)
  values (p_thread, v_me, case when p_muted then now() end)
  on conflict (thread_id, user_id) do update set muted_at = excluded.muted_at;
end;
$$;


--
-- Name: zyra_set_guardian_journey_permission(uuid, uuid, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_guardian_journey_permission(p_wali_link_id uuid, p_match_id uuid, p_can_view boolean, p_can_chat boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_link public.wali_links%rowtype;
begin
  select * into v_link
  from public.wali_links link
  where link.id = p_wali_link_id
  for update;
  if not found or v_link.seeker_id <> v_caller or v_link.status <> 'active' then
    raise exception 'guardian_link_not_available';
  end if;
  if v_link.is_main then raise exception 'main_guardian_access_required'; end if;
  if p_can_chat and not p_can_view then
    raise exception 'guardian_chat_requires_view';
  end if;
  if not exists (
    select 1 from public.matches match
    where match.id = p_match_id
      and match.status = 'active'
      and v_caller in (match.seeker_a_id, match.seeker_b_id)
  ) then
    raise exception 'active_journey_not_available';
  end if;

  perform * from public.zyra_guardian_journey_access(v_link.wali_id,
    (select a.id from public.journey_attempts a where a.match_id = p_match_id
     order by a.attempt_number desc limit 1), p_can_view);

  insert into public.guardian_journey_permissions (
    wali_link_id, match_id, can_view, can_chat, updated_by, updated_at
  ) values (
    p_wali_link_id, p_match_id, p_can_view, p_can_chat, v_caller, now()
  )
  on conflict (wali_link_id, match_id) do update
    set can_view = excluded.can_view,
        can_chat = excluded.can_chat,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;
end;
$$;


--
-- Name: zyra_set_main_guardian(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_main_guardian(p_wali_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
  v_n  int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  if not exists (
    select 1 from public.wali_links
    where seeker_id = v_me and wali_id = p_wali_id and status = 'active'
  ) then
    raise exception 'not_your_guardian';
  end if;

  -- 1. Demote the incumbent, if there is one.
  update public.wali_links
     set is_main = false
   where seeker_id = v_me and status = 'active' and is_main;

  -- 2. Promote the target into the now-vacant slot.
  update public.wali_links
     set is_main = true
   where seeker_id = v_me and wali_id = p_wali_id and status = 'active';

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$$;


--
-- Name: zyra_set_my_home_place(text, numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_my_home_place(p_country text, p_lat numeric, p_lon numeric) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
declare
  v_me uuid := (select auth.uid());
begin
  if v_me is null or not exists (
    select 1 from public.profiles p where p.id = v_me and p.role = 'seeker'
  ) then
    raise exception using errcode = '42501', message = 'discovery_not_allowed';
  end if;
  if p_country is null or p_country !~ '^[A-Z]{2}$'
     or p_lat is null or p_lat not between -90 and 90
     or p_lon is null or p_lon not between -180 and 180 then
    raise exception using errcode = '22023', message = 'invalid_home_place';
  end if;

  insert into private.seeker_home_places (user_id, country_code, lat, lon)
  values (v_me, p_country, pg_catalog.round(p_lat, 2), pg_catalog.round(p_lon, 2))
  on conflict (user_id) do update
    set country_code = excluded.country_code, lat = excluded.lat, lon = excluded.lon,
        updated_at = now();
end;
$_$;


--
-- Name: zyra_set_notification_preference(text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_notification_preference(p_category text, p_enabled boolean) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if p_category not in ('matches_journeys', 'guardian_activity', 'introductions',
                        'marketing_emails', 'product_updates', 'circle') then
    raise exception 'unknown_category: %', p_category;
  end if;
  insert into public.notification_preferences(user_id, category, enabled)
  values (v_me, p_category, p_enabled);
  return true;
end;
$$;


--
-- Name: zyra_set_profile_complete(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_profile_complete(p_complete boolean DEFAULT true) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_me uuid := auth.uid();
  v_p  record;
  v_photos int;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  -- Un-publishing is always allowed: nobody should need permission to
  -- withdraw themselves. It no longer unfreezes identity — first_published_at
  -- is deliberately untouched here.
  IF NOT p_complete THEN
    UPDATE public.profiles SET profile_complete = false WHERE id = v_me;
    RETURN jsonb_build_object('status','unpublished');
  END IF;

  SELECT * INTO v_p FROM public.profiles WHERE id = v_me;
  IF v_p IS NULL THEN
    RAISE EXCEPTION 'no_profile';
  END IF;

  IF v_p.first_name IS NULL OR btrim(v_p.first_name) = ''
     OR v_p.gender IS NULL OR v_p.date_of_birth IS NULL THEN
    RETURN jsonb_build_object('status','incomplete','missing','identity');
  END IF;

  -- A Guardian has no photos and no Browse presence; the photo rule is a
  -- Seeker rule only.
  IF v_p.role = 'seeker' THEN
    PERFORM private.zyra_lock_photo_folder(v_me::text);
    SELECT count(*) INTO v_photos
      FROM public.profile_photos p
      WHERE p.user_id = v_me AND p.removed_at IS NULL
        AND private.zyra_photo_reference_owned(p.user_id, p.storage_path);
    IF v_photos < 1 THEN
      RETURN jsonb_build_object('status','incomplete','missing','photos');
    END IF;
  END IF;

  -- coalesce, not a bare now(): re-publishing after a break must not move
  -- the date, or the freeze would restart every time someone came back.
  UPDATE public.profiles
     SET profile_complete   = true,
         first_published_at = coalesce(first_published_at, now())
   WHERE id = v_me;
  RETURN jsonb_build_object('status','published');
END;
$$;


--
-- Name: zyra_set_profile_hidden(text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_profile_hidden(p_other text, p_hidden boolean) RETURNS jsonb
    LANGUAGE sql
    SET search_path TO ''
    AS $$
  select public.zyra_set_profile_hidden(p_profile => p_other::uuid, p_hidden => p_hidden);
$$;


--
-- Name: zyra_set_profile_hidden(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_set_profile_hidden(p_profile uuid, p_hidden boolean) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_me uuid := (select auth.uid());
begin
  if v_me is null or not exists (
    select 1 from public.profiles p where p.id = v_me and p.role = 'seeker'
  ) then
    raise exception using errcode = '42501', message = 'discovery_not_allowed';
  end if;
  if p_profile is null or p_profile = v_me or p_hidden is null then
    raise exception using errcode = '22023', message = 'invalid_profile_hide';
  end if;

  if p_hidden then
    if not exists (
      select 1
      from public.profiles candidate
      join public.profiles viewer on viewer.id = v_me
      where candidate.id = p_profile and candidate.role = 'seeker'
        and candidate.gender <> viewer.gender
        and public.zyra_can_view_profile(candidate.id)
        and not public.zyra_block_exists(candidate.id)
    ) and not exists (
      select 1 from public.profile_hides h where h.hider = v_me and h.hidden = p_profile
    ) then
      raise exception using errcode = '42501', message = 'profile_unavailable';
    end if;
    insert into public.profile_hides (hider, hidden)
    values (v_me, p_profile)
    on conflict (hider, hidden) do nothing;
  else
    delete from public.profile_hides h
    where h.hider = v_me and h.hidden = p_profile;
  end if;

  return pg_catalog.jsonb_build_object(
    'schema_version', 1, 'viewer_id', v_me, 'profile_id', p_profile, 'hidden', p_hidden
  );
end;
$$;


--
-- Name: zyra_start_verified_guardian_trial(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_start_verified_guardian_trial(p_user uuid, p_verified_person uuid) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
declare
  v_started_at timestamptz := now();
  v_ends_at timestamptz;
begin
  if not exists (
    select 1
    from private.verified_person_accounts binding
    join public.profiles profile on profile.id = binding.user_id
    where binding.verified_person_id = p_verified_person
      and binding.user_id = p_user
      and binding.role = 'guardian'
      and profile.role = 'wali'
  ) then
    raise exception 'verified_guardian_binding_required';
  end if;

  insert into private.guardian_trial_ledger (
    verified_person_id, claimed_by, started_at, ends_at
  )
  values (p_verified_person, p_user, v_started_at, v_started_at + interval '14 days')
  on conflict (verified_person_id) do nothing
  returning ends_at into v_ends_at;

  if not found then
    raise exception 'guardian_trial_already_used';
  end if;
  return v_ends_at;
end;
$$;


--
-- Name: zyra_start_verified_seeker_trial(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_start_verified_seeker_trial(p_user uuid, p_verified_person uuid, p_payment_authorisation_ref_hash text) RETURNS timestamp with time zone
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_end timestamptz;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service_role_required';
  end if;
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.verified_person_id = p_verified_person
      and binding.user_id = p_user
      and binding.role = 'seeker'
  ) then raise exception 'verified_seeker_binding_required'; end if;
  insert into private.seeker_trial_ledger (
    verified_person_id, claimed_by, status,
    payment_authorisation_ref_hash, started_at, ends_at
  ) values (
    p_verified_person, p_user, 'active',
    p_payment_authorisation_ref_hash, now(), now() + interval '14 days'
  ) returning ends_at into v_end;
  return v_end;
exception when unique_violation then
  raise exception 'seeker_trial_already_used';
end;
$$;


--
-- Name: zyra_submit_feedback(text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_submit_feedback(p_category text, p_message text, p_app_version text DEFAULT NULL::text, p_platform text DEFAULT NULL::text, p_screen text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_me     uuid := auth.uid();
  v_msg    text := btrim(coalesce(p_message, ''));
  v_recent int;
  v_id     uuid;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  IF p_category NOT IN ('idea','problem','other') THEN
    RAISE EXCEPTION 'invalid_category';
  END IF;

  IF v_msg = '' THEN
    RETURN jsonb_build_object('status','empty');
  END IF;
  IF char_length(v_msg) > 4000 THEN
    RETURN jsonb_build_object('status','too_long','max',4000);
  END IF;

  -- Rate limit. Not anti-abuse theatre: without it one stuck retry loop
  -- writes thousands of identical rows and the useful feedback is buried
  -- under it. Ten an hour is far more than anyone sends in good faith.
  --
  -- clock_timestamp(), not now(): now() is transaction start time, and
  -- the difference has already produced one wrong result in this codebase
  -- (three consent events sharing a timestamp, 2026-08-06).
  SELECT count(*) INTO v_recent
    FROM public.app_feedback
   WHERE user_id = v_me
     AND created_at > clock_timestamp() - interval '1 hour';

  IF v_recent >= 10 THEN
    RETURN jsonb_build_object('status','rate_limited');
  END IF;

  INSERT INTO public.app_feedback
    (user_id, category, message, app_version, platform, screen)
  VALUES
    (v_me, p_category, v_msg,
     left(nullif(btrim(coalesce(p_app_version,'')), ''), 40),
     left(nullif(btrim(coalesce(p_platform,'')),    ''), 40),
     left(nullif(btrim(coalesce(p_screen,'')),      ''), 80))
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('status','sent','id',v_id);
END;
$$;


--
-- Name: FUNCTION zyra_submit_feedback(p_category text, p_message text, p_app_version text, p_platform text, p_screen text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.zyra_submit_feedback(p_category text, p_message text, p_app_version text, p_platform text, p_screen text) IS 'The only write path into app_feedback. Trims, validates, stamps user_id server-side and rate-limits to 10/hour. There is deliberately no INSERT grant on the table itself.';


--
-- Name: zyra_sync_family_message_block_lifecycle(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_sync_family_message_block_lifecycle() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_first uuid;
  v_second uuid;
  v_seeker uuid;
begin
  if tg_op = 'DELETE' then
    v_first := old.blocker_id;
    v_second := old.blocked_id;
  else
    v_first := new.blocker_id;
    v_second := new.blocked_id;
  end if;
  select link.seeker_id into v_seeker from public.wali_links link
  where (link.seeker_id = v_first and link.wali_id = v_second)
     or (link.seeker_id = v_second and link.wali_id = v_first)
  limit 1;
  if v_seeker is not null then
    perform public.zyra_sync_family_message_circle_members(v_seeker);
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;


--
-- Name: zyra_sync_family_message_circle_members(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_sync_family_message_circle_members(p_seeker uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_thread uuid;
  v_now timestamptz := pg_catalog.clock_timestamp();
begin
  select thread.id into v_thread
  from public.family_message_threads thread
  where thread.seeker_id = p_seeker;
  if v_thread is null then return null; end if;

  insert into public.family_message_memberships (
    thread_id, user_id, member_role, joined_at, readable_from
  ) values (
    v_thread, p_seeker, 'seeker', v_now,
    (select thread.created_at from public.family_message_threads thread
     where thread.id = v_thread)
  )
  on conflict (thread_id, user_id) where left_at is null do nothing;

  update public.family_message_memberships membership
  set left_at = v_now
  where membership.thread_id = v_thread
    and membership.member_role = 'guardian'
    and membership.left_at is null
    and not exists (
      select 1 from public.wali_links link
      where link.seeker_id = p_seeker
        and link.wali_id = membership.user_id
        and link.status = 'active'
        and not exists (
          select 1 from public.profile_blocks block
          where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
             or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
        )
    );

  insert into public.family_message_memberships (
    thread_id, user_id, member_role, joined_at, readable_from
  )
  select v_thread, link.wali_id, 'guardian', v_now, v_now
  from public.wali_links link
  where link.seeker_id = p_seeker and link.status = 'active'
    and not exists (
      select 1 from public.profile_blocks block
      where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
         or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
    )
    and not exists (
      select 1 from public.family_message_memberships membership
      where membership.thread_id = v_thread
        and membership.user_id = link.wali_id
        and membership.left_at is null
    );

  insert into public.family_message_participant_state (thread_id, user_id)
  select membership.thread_id, membership.user_id
  from public.family_message_memberships membership
  where membership.thread_id = v_thread and membership.left_at is null
  on conflict (thread_id, user_id) do nothing;

  return v_thread;
end;
$$;


--
-- Name: zyra_sync_family_message_link_lifecycle(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_sync_family_message_link_lifecycle() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare v_seeker uuid;
begin
  v_seeker := case when tg_op = 'DELETE' then old.seeker_id else new.seeker_id end;
  perform public.zyra_sync_family_message_circle_members(v_seeker);
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;


--
-- Name: zyra_touch_activity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_touch_activity() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    SET "TimeZone" TO 'UTC'
    AS $$
declare
  v_user uuid := (select auth.uid());
  v_now timestamptz := now();
  v_last_active_at timestamptz;
  v_due_at timestamptz;
begin
  if v_user is null then raise exception using errcode = '42501', message = 'not_signed_in'; end if;

  -- The worker takes the same lock before it can remove any copies.
  select p.last_active_at into v_last_active_at
  from public.profiles p where p.id = v_user for no key update;
  if not found then return; end if;

  if v_last_active_at::date < v_now::date then
    update public.profiles set last_active_at = v_now where id = v_user;
  end if;

  update public.zyra_inactivity_notices set cleared_at = v_now, welcome_back_pending = true
  where user_id = v_user and cleared_at is null and completed_at is null
  returning removal_due_at into v_due_at;
  if found then
    update public.email_outbox set cancelled_at = v_now
    where user_id = v_user and due_at >= v_due_at - interval '28 days' and due_at < v_due_at
      and sent_at is null and cancelled_at is null;
    delete from public.notifications where user_id = v_user and type = 'inactivity_warning';
  end if;
end;
$$;


--
-- Name: zyra_unblock_user(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_unblock_user(p_other uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE v_me uuid := auth.uid();
BEGIN
  IF v_me IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  -- Deliberately the ONLY statement. The invariant at the top of this
  -- migration: nothing is recreated or restored. The Journey stays ended,
  -- the conversation stays closed, visibility stays revoked. Reconnecting
  -- means a new Journey under the normal rules.
  DELETE FROM profile_blocks WHERE blocker_id = v_me AND blocked_id = p_other;
END;
$$;


--
-- Name: zyra_unlock_profile(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_unlock_profile(p_target uuid, p_tier text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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
$$;


--
-- Name: zyra_validate_family_ownership_transfer(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_validate_family_ownership_transfer() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_family public.family_subscriptions%rowtype;
begin
  if tg_op = 'UPDATE' then
    if new.status = 'cancelled'
       and new.current_owner_id is not distinct from old.current_owner_id
       and new.replacement_owner_id is not distinct from old.replacement_owner_id
       and new.family_subscription_id = old.family_subscription_id then
      return new;
    end if;
    if old.status in ('completed', 'declined', 'cancelled')
       and new.status = old.status and new.family_subscription_id = old.family_subscription_id
       and (new.current_owner_id is null or new.current_owner_id is not distinct from old.current_owner_id)
       and (new.replacement_owner_id is null or new.replacement_owner_id is not distinct from old.replacement_owner_id)
       and (new.current_owner_id is null or new.replacement_owner_id is null) then
      return new;
    end if;
  end if;
  if new.current_owner_id is null or new.replacement_owner_id is null then
    raise exception 'family_transfer_existing_member_required';
  end if;

  select * into v_family
  from public.family_subscriptions family
  where family.id = new.family_subscription_id;
  if not found or v_family.owner_id is distinct from new.current_owner_id then
    raise exception 'family_transfer_owner_mismatch';
  end if;
  if not exists (
    select 1
    from public.family_seat_assignments seat
    where seat.family_subscription_id = new.family_subscription_id
      and seat.member_id = new.replacement_owner_id
      and seat.role = new.replacement_role
      and seat.removed_at is null
  ) then raise exception 'family_transfer_existing_member_required'; end if;
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = new.replacement_owner_id
      and binding.role = new.replacement_role
  ) then raise exception 'family_transfer_verified_member_required'; end if;
  if new.status in ('scheduled', 'completed')
     and new.effective_at is distinct from v_family.coverage_ends_at then
    raise exception 'family_transfer_must_start_at_renewal';
  end if;
  return new;
end;
$$;


--
-- Name: zyra_validate_profile_name_lengths(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zyra_validate_profile_name_lengths() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  -- profiles_normalise_identity runs first, so compare and count the saved form.
  -- The existing NOT NULL and shape constraints still enforce the lower bound.
  if (tg_op = 'INSERT' or new.first_name is distinct from old.first_name)
    and char_length(new.first_name) > 30 then
    raise exception 'first_name_too_long';
  end if;

  if (tg_op = 'INSERT' or new.surname_line is distinct from old.surname_line)
    and char_length(new.surname_line) > 40 then
    raise exception 'surname_too_long';
  end if;

  return new;
end;
$$;


--
-- Name: guardian_trial_ledger; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.guardian_trial_ledger (
    verified_person_id uuid NOT NULL,
    claimed_by uuid,
    started_at timestamp with time zone,
    ends_at timestamp with time zone,
    CONSTRAINT guardian_trial_duration CHECK ((((claimed_by IS NULL) AND (started_at IS NULL) AND (ends_at IS NULL)) OR ((claimed_by IS NOT NULL) AND (started_at IS NOT NULL) AND (ends_at IS NOT NULL) AND (ends_at = (started_at + '14 days'::interval)))))
);


--
-- Name: identity_verification_attempts; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.identity_verification_attempts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider_code text DEFAULT 'sumsub'::text NOT NULL,
    provider_session_ref text,
    result text NOT NULL,
    duplicate_review_required boolean,
    provider_event_ref_hash text,
    consent_granted boolean NOT NULL,
    consent_version text NOT NULL,
    consent_recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    decided_at timestamp with time zone,
    member_deleted_at timestamp with time zone,
    CONSTRAINT identity_verification_attempts_consent_version_check CHECK ((consent_version ~ '^[a-z0-9][a-z0-9._-]{0,79}$'::text)),
    CONSTRAINT identity_verification_attempts_provider_code_check CHECK ((provider_code = ANY (ARRAY['sumsub'::text, 'stripe'::text]))),
    CONSTRAINT identity_verification_attempts_provider_event_ref_hash_check CHECK (((provider_event_ref_hash IS NULL) OR (provider_event_ref_hash ~ '^[0-9a-f]{64}$'::text))),
    CONSTRAINT identity_verification_attempts_provider_session_ref_check CHECK (((provider_session_ref IS NULL) OR ((char_length(provider_session_ref) >= 1) AND (char_length(provider_session_ref) <= 255)))),
    CONSTRAINT identity_verification_attempts_result_check CHECK ((result = ANY (ARRAY['pending'::text, 'verified'::text, 'retry_required'::text, 'review_required'::text, 'failed'::text, 'expired'::text, 'cancelled'::text]))),
    CONSTRAINT identity_verification_duplicate_routes_to_review CHECK (((duplicate_review_required IS DISTINCT FROM true) OR (result = 'review_required'::text))),
    CONSTRAINT identity_verification_final_has_decision_time CHECK (((result = ANY (ARRAY['pending'::text, 'retry_required'::text, 'review_required'::text])) OR (decided_at IS NOT NULL))),
    CONSTRAINT identity_verification_verified_not_duplicate CHECK (((result <> 'verified'::text) OR (duplicate_review_required IS DISTINCT FROM true)))
);


--
-- Name: TABLE identity_verification_attempts; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON TABLE private.identity_verification_attempts IS 'PRIVATE SERVER-OWNED IDV state. No biometric/document/selfie/PII/raw provider payload columns are permitted. Ordinary clients use only the caller-scoped public RPCs in this migration.';


--
-- Name: COLUMN identity_verification_attempts.provider_session_ref; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON COLUMN private.identity_verification_attempts.provider_session_ref IS 'Opaque provider reference only; never email, name, document data or a URL.';


--
-- Name: COLUMN identity_verification_attempts.duplicate_review_required; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON COLUMN private.identity_verification_attempts.duplicate_review_required IS 'NULL=not_evaluated, FALSE=clear, TRUE=manual review. Never contains a hit id, score or reason.';


--
-- Name: COLUMN identity_verification_attempts.provider_event_ref_hash; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON COLUMN private.identity_verification_attempts.provider_event_ref_hash IS 'SHA-256 event-reference hash for idempotency; never the raw provider event id.';


--
-- Name: identity_verification_event_receipts; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.identity_verification_event_receipts (
    provider_event_ref_hash text NOT NULL,
    attempt_id uuid NOT NULL,
    mapped_result text NOT NULL,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT identity_verification_event_recei_provider_event_ref_hash_check CHECK ((provider_event_ref_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT identity_verification_event_receipts_mapped_result_check CHECK ((mapped_result = ANY (ARRAY['pending'::text, 'verified'::text, 'retry_required'::text, 'review_required'::text, 'failed'::text, 'expired'::text, 'cancelled'::text])))
);


--
-- Name: TABLE identity_verification_event_receipts; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON TABLE private.identity_verification_event_receipts IS 'Hash-only webhook idempotency ledger. No provider event id, body, header, reason, PII, biometric data or duplicate-hit detail.';


--
-- Name: report_protected_attempts; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.report_protected_attempts (
    report_id uuid NOT NULL,
    attempt_id uuid NOT NULL
);


--
-- Name: TABLE report_protected_attempts; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON TABLE private.report_protected_attempts IS 'Internal safety linkage. Open reports protect the linked attempts, including after either participant is detached.';


--
-- Name: safety_sealed_messages; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.safety_sealed_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source text NOT NULL,
    source_message_id uuid NOT NULL,
    thread_id uuid NOT NULL,
    sender_id uuid,
    body text NOT NULL,
    sent_at timestamp with time zone NOT NULL,
    sealed_at timestamp with time zone NOT NULL,
    purge_at timestamp with time zone NOT NULL,
    circle_chat_id uuid,
    circle_attempt_id uuid,
    CONSTRAINT safety_sealed_circle_chat_shape CHECK ((((circle_chat_id IS NULL) AND (circle_attempt_id IS NULL)) OR ((source = 'guardian_circle'::text) AND (circle_chat_id IS NOT NULL) AND (circle_attempt_id IS NOT NULL)))),
    CONSTRAINT safety_sealed_messages_check CHECK ((purge_at = (sealed_at + '8760:00:00'::interval))),
    CONSTRAINT safety_sealed_messages_source_check CHECK ((source = ANY (ARRAY['journey'::text, 'guardian_circle'::text])))
);


--
-- Name: seeker_home_places; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.seeker_home_places (
    user_id uuid NOT NULL,
    country_code text NOT NULL,
    lat numeric(7,2) NOT NULL,
    lon numeric(7,2) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT seeker_home_places_country_code_check CHECK ((country_code ~ '^[A-Z]{2}$'::text)),
    CONSTRAINT seeker_home_places_lat_check CHECK (((lat >= ('-90'::integer)::numeric) AND (lat <= (90)::numeric))),
    CONSTRAINT seeker_home_places_lon_check CHECK (((lon >= ('-180'::integer)::numeric) AND (lon <= (180)::numeric)))
);


--
-- Name: seeker_trial_ledger; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.seeker_trial_ledger (
    verified_person_id uuid NOT NULL,
    claimed_by uuid,
    status text NOT NULL,
    payment_authorisation_ref_hash text,
    started_at timestamp with time zone,
    ends_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT seeker_trial_active_shape CHECK ((((claimed_by IS NULL) AND (status = 'completed'::text) AND (payment_authorisation_ref_hash IS NULL) AND (started_at IS NULL) AND (ends_at IS NULL) AND (updated_at IS NULL)) OR (status = 'family_forfeited'::text) OR ((claimed_by IS NOT NULL) AND (payment_authorisation_ref_hash IS NOT NULL) AND (started_at IS NOT NULL) AND (ends_at = (started_at + '14 days'::interval))))),
    CONSTRAINT seeker_trial_ledger_payment_authorisation_ref_hash_check CHECK (((payment_authorisation_ref_hash IS NULL) OR (payment_authorisation_ref_hash ~ '^[0-9a-f]{64}$'::text))),
    CONSTRAINT seeker_trial_ledger_status_check CHECK ((status = ANY (ARRAY['active'::text, 'cancel_at_end'::text, 'completed'::text, 'family_forfeited'::text])))
);


--
-- Name: verified_people; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.verified_people (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_code text NOT NULL,
    provider_person_ref_hash text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT verified_people_provider_code_check CHECK ((provider_code = 'stripe'::text)),
    CONSTRAINT verified_people_provider_person_ref_hash_check CHECK ((provider_person_ref_hash ~ '^[0-9a-f]{64}$'::text))
);


--
-- Name: verified_person_accounts; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.verified_person_accounts (
    verified_person_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text NOT NULL,
    verified_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT verified_person_accounts_role_check CHECK ((role = ANY (ARRAY['seeker'::text, 'guardian'::text])))
);


--
-- Name: zyra_account_deleted_matches; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_account_deleted_matches (
    match_id uuid NOT NULL
);


--
-- Name: zyra_circle_seal_protections; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_circle_seal_protections (
    sealed_message_id uuid NOT NULL,
    report_id uuid NOT NULL
);


--
-- Name: zyra_compatibility_sect_repairs; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_compatibility_sect_repairs (
    viewer uuid NOT NULL,
    first_seen_at timestamp with time zone DEFAULT statement_timestamp() NOT NULL
);


--
-- Name: zyra_deleted_attempt_evidence; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_deleted_attempt_evidence (
    attempt_id uuid NOT NULL,
    records jsonb NOT NULL
);


--
-- Name: zyra_ended_journey_removals; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_ended_journey_removals (
    attempt_id uuid NOT NULL,
    seeker_a_removed_at timestamp with time zone,
    seeker_b_removed_at timestamp with time zone
);


--
-- Name: TABLE zyra_ended_journey_removals; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON TABLE private.zyra_ended_journey_removals IS 'Private, irreversible, attempt-specific joint archive state. Each side controls only its own removal.';


--
-- Name: journey_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_attempts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    attempt_number integer DEFAULT 1 NOT NULL,
    status text DEFAULT 'potential'::text NOT NULL,
    journey_stage text,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    ended_by uuid,
    end_reason text,
    end_note text,
    paused_by uuid,
    paused_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    also_paused_by uuid,
    also_paused_at timestamp with time zone,
    CONSTRAINT attempts_end_fields_need_ended_status CHECK (((status = 'ended'::text) OR ((ended_by IS NULL) AND (end_reason IS NULL) AND (end_note IS NULL)))),
    CONSTRAINT attempts_end_note_length CHECK (((end_note IS NULL) OR (char_length(end_note) <= 500))),
    CONSTRAINT attempts_end_reason_known CHECK (((end_reason IS NULL) OR (end_reason = ANY (ARRAY['not_compatible'::text, 'circumstances_changed'::text, 'marrying_elsewhere'::text, 'family_decision'::text, 'safety_concern'::text, 'prefer_not_to_say'::text, 'no_response'::text])))),
    CONSTRAINT attempts_no_note_on_safety_ending CHECK (((end_reason IS DISTINCT FROM 'safety_concern'::text) OR (end_note IS NULL))),
    CONSTRAINT attempts_no_response_is_system CHECK (((end_reason IS DISTINCT FROM 'no_response'::text) OR (ended_by IS NULL))),
    CONSTRAINT attempts_pause_needs_active CHECK (((paused_by IS NULL) OR (status = 'active'::text))),
    CONSTRAINT journey_attempts_journey_stage_check CHECK (((journey_stage IS NULL) OR (journey_stage = ANY (ARRAY['compatibility_reveal'::text, 'salam_exchange'::text, 'wali_gate'::text, 'phase_1'::text, 'phase_2'::text, 'phase_3'::text, 'family_stage'::text, 'conversation'::text])))),
    CONSTRAINT journey_attempts_status_check CHECK ((status = ANY (ARRAY['potential'::text, 'active'::text, 'ended'::text])))
);


--
-- Name: TABLE journey_attempts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.journey_attempts IS 'Journey attempts. NO client grants and NO RLS policies, deliberately: read it through zyra_my_attempt_participation (which filters to auth.uid()) or a SECURITY DEFINER function. Revoked 2026-08-07 — it previously held full grants behind zero policies, i.e. it was protected by an absence rather than a decision.';


--
-- Name: COLUMN journey_attempts.attempt_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.attempt_number IS 'OWNERSHIP: joint — INTERNAL ONLY. Never render this. V3 §2: users see dates, not attempt numbers.';


--
-- Name: COLUMN journey_attempts.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.status IS 'OWNERSHIP: joint. TRANSITIONAL until stage 4: matches.status is authoritative and this mirrors it at creation only. After stage 4 this becomes the sole source of truth.';


--
-- Name: COLUMN journey_attempts.journey_stage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.journey_stage IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_attempts.started_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.started_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_attempts.ended_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.ended_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_attempts.ended_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.ended_by IS 'OWNERSHIP: joint — who ended it is knowable to both';


--
-- Name: COLUMN journey_attempts.end_reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.end_reason IS 'OWNERSHIP: per-value. joint for the five stated reasons; safety_concern is row-scoped(ended_by) and MUST NEVER reach the other party by export or any indirect route.';


--
-- Name: COLUMN journey_attempts.end_note; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.end_note IS 'OWNERSHIP: joint — written TO the other person';


--
-- Name: COLUMN journey_attempts.paused_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.paused_by IS 'OWNERSHIP: joint — the other party is told a pause happened';


--
-- Name: COLUMN journey_attempts.paused_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_attempts.paused_at IS 'OWNERSHIP: joint';


--
-- Name: matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.matches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    seeker_a_id uuid,
    seeker_b_id uuid,
    status text DEFAULT 'potential'::text NOT NULL,
    ended_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    journey_stage text,
    suspended_by uuid,
    suspended_at timestamp with time zone,
    ended_by uuid,
    end_reason text,
    end_note text,
    pause_nudged_at timestamp with time zone,
    also_paused_by uuid,
    also_paused_at timestamp with time zone,
    CONSTRAINT matches_also_pause_requires_primary CHECK (((also_paused_by IS NULL) OR (suspended_by IS NOT NULL))),
    CONSTRAINT matches_check CHECK ((seeker_a_id < seeker_b_id)),
    CONSTRAINT matches_deleted_pair_shape CHECK ((((seeker_a_id IS NOT NULL) AND (seeker_b_id IS NOT NULL)) OR ((seeker_a_id IS NULL) AND (seeker_b_id IS NULL) AND (status = 'ended'::text)))),
    CONSTRAINT matches_end_fields_need_ended_status CHECK (((status = 'ended'::text) OR ((ended_by IS NULL) AND (end_reason IS NULL) AND (end_note IS NULL)))),
    CONSTRAINT matches_end_note_length CHECK (((end_note IS NULL) OR (char_length(end_note) <= 500))),
    CONSTRAINT matches_end_reason_known CHECK (((end_reason IS NULL) OR (end_reason = ANY (ARRAY['not_compatible'::text, 'circumstances_changed'::text, 'marrying_elsewhere'::text, 'family_decision'::text, 'safety_concern'::text, 'prefer_not_to_say'::text, 'no_response'::text])))),
    CONSTRAINT matches_holds_distinct CHECK (((also_paused_by IS NULL) OR (also_paused_by <> suspended_by))),
    CONSTRAINT matches_journey_stage_check CHECK ((journey_stage = ANY (ARRAY['compatibility_reveal'::text, 'salam_exchange'::text, 'wali_gate'::text, 'phase_1'::text, 'phase_2'::text, 'phase_3'::text, 'family_stage'::text, 'conversation'::text]))),
    CONSTRAINT matches_no_note_on_safety_ending CHECK (((end_reason IS DISTINCT FROM 'safety_concern'::text) OR (end_note IS NULL))),
    CONSTRAINT matches_no_response_is_system CHECK (((end_reason IS DISTINCT FROM 'no_response'::text) OR (ended_by IS NULL))),
    CONSTRAINT matches_status_check CHECK ((status = ANY (ARRAY['potential'::text, 'active'::text, 'ended'::text])))
);


--
-- Name: COLUMN matches.seeker_a_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.seeker_a_id IS 'OWNERSHIP: joint — who you matched with is equally each party''s own fact. NOT a route to the other person''s data; it is an identifier both already hold.';


--
-- Name: COLUMN matches.seeker_b_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.seeker_b_id IS 'OWNERSHIP: joint — see seeker_a_id.';


--
-- Name: COLUMN matches.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.status IS 'OWNERSHIP: joint';


--
-- Name: COLUMN matches.ended_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.ended_at IS 'When the Journey ended. Set by zyra_end_match_internal(), the single path both ordinary and safety endings take — two paths would drift and the drift would be a disclosure channel. NOTE the companion rule: visibility revoked by a block keys on end_reason=''safety_concern'' (permanent), NOT on a profile_blocks row (deletable). PERMANENT BEHAVIOUR MUST DERIVE FROM PERMANENT DATA.';


--
-- Name: COLUMN matches.journey_stage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.journey_stage IS 'OWNERSHIP: joint';


--
-- Name: COLUMN matches.suspended_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.suspended_by IS 'OWNERSHIP: joint — the other party is told a pause happened';


--
-- Name: COLUMN matches.suspended_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.suspended_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN matches.ended_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.ended_by IS 'OWNERSHIP: joint — who ended it is knowable to both';


--
-- Name: COLUMN matches.end_reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.end_reason IS 'OWNERSHIP: per-value. Joint for the five stated reasons (V3 §8 — a stated reason is kinder than silence). safety_concern is row-scoped(ended_by) and MUST NEVER reach the other party or either family. NOT CLIENT-READABLE since 2026-08-08: RLS decides rows, not values, so the rule cannot be a policy. Read via zyra_match_ending(), which substitutes prefer_not_to_say for anyone not entitled. DO NOT RE-GRANT.';


--
-- Name: COLUMN matches.end_note; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.matches.end_note IS 'OWNERSHIP: joint — written TO the other person. Revoked alongside end_reason 2026-08-08: a note being present or absent is itself a signal about the reason, so it has to travel through the same accessor.';


--
-- Name: profile_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_blocks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    blocker_id uuid NOT NULL,
    blocked_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profile_blocks_check CHECK ((blocker_id <> blocked_id))
);


--
-- Name: TABLE profile_blocks; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.profile_blocks IS 'A block is a TERMINAL safety boundary. Nothing may automatically recreate or restore any relationship, visibility, conversation or Journey that existed before it; reconnecting starts a new Journey under the normal rules. WRITE PATH IS zyra_block_user() / zyra_unblock_user() ONLY — direct grants revoked 2026-08-08 so the atomicity cannot be bypassed. Do not re-grant.';


--
-- Name: COLUMN profile_blocks.blocker_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_blocks.blocker_id IS 'OWNERSHIP: row-scoped(blocker_id)';


--
-- Name: COLUMN profile_blocks.blocked_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_blocks.blocked_id IS 'OWNERSHIP: non-exportable to the blocked person';


--
-- Name: zyra_ended_journey_visibility; Type: VIEW; Schema: private; Owner: -
--

CREATE VIEW private.zyra_ended_journey_visibility AS
 SELECT a.id AS attempt_id,
    m.id AS match_id,
    m.seeker_a_id,
    m.seeker_b_id,
    ((m.seeker_a_id IS NOT NULL) AND (r.seeker_a_removed_at IS NULL) AND (NOT block.present)) AS seeker_a_visible,
    ((m.seeker_b_id IS NOT NULL) AND (r.seeker_b_removed_at IS NULL) AND (NOT block.present)) AS seeker_b_visible
   FROM (((public.journey_attempts a
     JOIN public.matches m ON ((m.id = a.match_id)))
     LEFT JOIN private.zyra_ended_journey_removals r ON ((r.attempt_id = a.id)))
     CROSS JOIN LATERAL ( SELECT (EXISTS ( SELECT 1
                   FROM public.profile_blocks b
                  WHERE (((b.blocker_id = m.seeker_a_id) AND (b.blocked_id = m.seeker_b_id)) OR ((b.blocker_id = m.seeker_b_id) AND (b.blocked_id = m.seeker_a_id))))) AS present) block)
  WHERE ((a.status = 'ended'::text) AND (NOT (EXISTS ( SELECT 1
           FROM private.zyra_account_deleted_matches d
          WHERE (d.match_id = m.id)))));


--
-- Name: zyra_family_chat_report_attempts; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_family_chat_report_attempts (
    report_id uuid NOT NULL,
    attempt_id uuid NOT NULL,
    chat_id uuid NOT NULL
);


--
-- Name: zyra_guardian_invite_accept_guards; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_guardian_invite_accept_guards (
    seeker_id uuid NOT NULL,
    revision bigint NOT NULL
);


--
-- Name: zyra_guardian_notification_sources; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_guardian_notification_sources (
    notification_id uuid NOT NULL,
    actor_id uuid,
    invite_id uuid,
    link_id uuid
);


--
-- Name: zyra_journey_reveal_tombstones; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_journey_reveal_tombstones (
    attempt_id uuid NOT NULL,
    match_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    revealed_at timestamp with time zone,
    consent_for_attempt_id uuid NOT NULL
);


--
-- Name: zyra_personal_code_attempts; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_personal_code_attempts (
    id bigint NOT NULL,
    caller_id uuid NOT NULL,
    attempted_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    succeeded boolean NOT NULL
);


--
-- Name: zyra_personal_code_attempts_id_seq; Type: SEQUENCE; Schema: private; Owner: -
--

ALTER TABLE private.zyra_personal_code_attempts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME private.zyra_personal_code_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: zyra_personal_codes; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_personal_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    owner_id uuid NOT NULL,
    role_context text NOT NULL,
    code text NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    rotated_at timestamp with time zone,
    CONSTRAINT zyra_personal_codes_format CHECK ((code ~ '^ZYRA-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$'::text)),
    CONSTRAINT zyra_personal_codes_role_context_check CHECK ((role_context = ANY (ARRAY['seeker'::text, 'wali'::text])))
);


--
-- Name: TABLE zyra_personal_codes; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON TABLE private.zyra_personal_codes IS 'Server-owned reusable ZYRA discovery handles. One active code per account role context; never a credential and never sufficient to create a link.';


--
-- Name: zyra_photo_cleanup_leases; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_photo_cleanup_leases (
    bucket text NOT NULL,
    path text NOT NULL,
    expires_at timestamp with time zone NOT NULL
);


--
-- Name: zyra_photo_folder_guard; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_photo_folder_guard (
    folder text NOT NULL
);


--
-- Name: zyra_product_events; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_product_events (
    id bigint NOT NULL,
    occurred_at timestamp with time zone DEFAULT statement_timestamp() NOT NULL,
    feature_key text NOT NULL,
    event_name text NOT NULL,
    action_key text NOT NULL,
    surface_key text NOT NULL,
    platform_key text NOT NULL,
    app_version text NOT NULL,
    build_number text NOT NULL,
    CONSTRAINT zyra_product_events_action_key_check CHECK ((action_key = ANY (ARRAY['pageView'::text, 'zyraCodeCheck'::text, 'zyraCodeRequest'::text, 'knownPersonConsider'::text, 'supportAnswer'::text, 'supportEmail'::text, 'identityProvider'::text, 'guardianHistoryConsent'::text, 'guardianReport'::text, 'guardianMakeMain'::text, 'guardianRemove'::text]))),
    CONSTRAINT zyra_product_events_app_version_check CHECK ((((length(app_version) >= 1) AND (length(app_version) <= 32)) AND (app_version ~ '^[0-9A-Za-z.+-]+$'::text))),
    CONSTRAINT zyra_product_events_build_number_check CHECK ((((length(build_number) >= 1) AND (length(build_number) <= 32)) AND (build_number ~ '^[0-9A-Za-z.+-]+$'::text))),
    CONSTRAINT zyra_product_events_event_name_check CHECK ((event_name = ANY (ARRAY['shown'::text, 'opened'::text, 'started'::text, 'completed'::text, 'failed'::text]))),
    CONSTRAINT zyra_product_events_feature_key_check CHECK ((feature_key = ANY (ARRAY['browse'::text, 'connections'::text, 'myZyra'::text, 'guardian'::text, 'journey'::text, 'profile'::text, 'zyraCode'::text, 'membership'::text, 'identityCheck'::text, 'support'::text]))),
    CONSTRAINT zyra_product_events_platform_key_check CHECK ((platform_key = ANY (ARRAY['ios'::text, 'android'::text, 'web'::text, 'macos'::text, 'windows'::text, 'linux'::text, 'fuchsia'::text]))),
    CONSTRAINT zyra_product_events_surface_key_check CHECK ((surface_key = ANY (ARRAY['seeker'::text, 'guardian'::text, 'entry'::text])))
);


--
-- Name: TABLE zyra_product_events; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON TABLE private.zyra_product_events IS 'OA-ZYRA-256 first-party aggregate product evidence. Fixed feature, action, event and surface taxonomy only; contains no member, device, session, profile, Journey or free-text identity.';


--
-- Name: zyra_product_events_id_seq; Type: SEQUENCE; Schema: private; Owner: -
--

ALTER TABLE private.zyra_product_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME private.zyra_product_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: zyra_purged_ended_match_projections; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_purged_ended_match_projections (
    match_id uuid NOT NULL
);


--
-- Name: zyra_question_area; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_question_area (
    question_id text NOT NULL,
    area smallint NOT NULL,
    CONSTRAINT zyra_question_area_area_check CHECK (((area >= 1) AND (area <= 12)))
);


--
-- Name: zyra_report_sealed_messages; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_report_sealed_messages (
    report_id uuid NOT NULL,
    sealed_message_id uuid NOT NULL
);


--
-- Name: zyra_retired_personal_code_hashes; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_retired_personal_code_hashes (
    code_sha256 bytea NOT NULL,
    retired_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: TABLE zyra_retired_personal_code_hashes; Type: COMMENT; Schema: private; Owner: -
--

COMMENT ON TABLE private.zyra_retired_personal_code_hashes IS 'Pseudonymous non-reuse ledger. Only SHA-256 digests survive rotation or account deletion; no owner identifier is retained.';


--
-- Name: zyra_unlock_account_guards; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_unlock_account_guards (
    user_id uuid NOT NULL,
    revision bigint DEFAULT 0 NOT NULL
);

ALTER TABLE ONLY private.zyra_unlock_account_guards FORCE ROW LEVEL SECURITY;


--
-- Name: zyra_unlock_operations; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_unlock_operations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    unlocker_id uuid NOT NULL,
    unlocked_id uuid NOT NULL,
    tier text NOT NULL,
    unlock_id uuid NOT NULL,
    debit_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT zyra_unlock_operations_check CHECK ((unlocker_id <> unlocked_id)),
    CONSTRAINT zyra_unlock_operations_tier_check CHECK ((tier = ANY (ARRAY['paid_single'::text, 'paid_plus_single'::text])))
);

ALTER TABLE ONLY private.zyra_unlock_operations FORCE ROW LEVEL SECURITY;


--
-- Name: zyra_unlock_release_gate; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.zyra_unlock_release_gate (
    singleton boolean DEFAULT true NOT NULL,
    plus_spend_enabled boolean DEFAULT false NOT NULL,
    CONSTRAINT zyra_plus_release_held CHECK ((NOT plus_spend_enabled)),
    CONSTRAINT zyra_unlock_release_gate_singleton_check CHECK (singleton)
);

ALTER TABLE ONLY private.zyra_unlock_release_gate FORCE ROW LEVEL SECURITY;


--
-- Name: app_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_feedback (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    category text NOT NULL,
    message text NOT NULL,
    app_version text,
    platform text,
    screen text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT app_feedback_category_known CHECK ((category = ANY (ARRAY['idea'::text, 'problem'::text, 'other'::text]))),
    CONSTRAINT app_feedback_message_shape CHECK (((message = btrim(message)) AND ((char_length(message) >= 1) AND (char_length(message) <= 4000)))),
    CONSTRAINT app_feedback_short_meta CHECK ((((app_version IS NULL) OR (char_length(app_version) <= 40)) AND ((platform IS NULL) OR (char_length(platform) <= 40)) AND ((screen IS NULL) OR (char_length(screen) <= 80))))
);


--
-- Name: TABLE app_feedback; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.app_feedback IS 'User-submitted ideas and problem reports. Append-only: no UPDATE or DELETE grant exists for anyone, including the author. user_id is ON DELETE SET NULL so an erasure request is never blocked by it.';


--
-- Name: COLUMN app_feedback.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_feedback.user_id IS 'OWNERSHIP: row-scoped(user_id). Nullable — becomes NULL when the account is deleted, at which point the row is no longer personal data.';


--
-- Name: COLUMN app_feedback.category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_feedback.category IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN app_feedback.message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_feedback.message IS 'OWNERSHIP: row-scoped(user_id). The user''s own words, disclosable to them under Article 15.';


--
-- Name: COLUMN app_feedback.app_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_feedback.app_version IS 'OWNERSHIP: row-scoped(user_id). Collected because "it broke" is not actionable without knowing which build.';


--
-- Name: COLUMN app_feedback.platform; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_feedback.platform IS 'OWNERSHIP: row-scoped(user_id). ios | android, nothing finer — the device model is not needed to read a sentence.';


--
-- Name: COLUMN app_feedback.screen; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_feedback.screen IS 'OWNERSHIP: row-scoped(user_id). Where they were when they wrote it.';


--
-- Name: consents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    consent_type text NOT NULL,
    granted boolean NOT NULL,
    policy_version text NOT NULL,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT consents_type_known CHECK ((consent_type = 'article9_special_category'::text))
);


--
-- Name: TABLE consents; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.consents IS 'Append-only consent log. Withdrawal is a new row with granted=false. Never update or delete a row here.';


--
-- Name: COLUMN consents.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.consents.user_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN consents.consent_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.consents.consent_type IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN consents.granted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.consents.granted IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN consents.policy_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.consents.policy_version IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN consents.recorded_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.consents.recorded_at IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    status text DEFAULT 'closed'::text NOT NULL,
    closed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    attempt_id uuid NOT NULL,
    CONSTRAINT conversations_status_check CHECK ((status = ANY (ARRAY['active'::text, 'paused'::text, 'closed'::text])))
);


--
-- Name: COLUMN conversations.match_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.match_id IS 'OWNERSHIP: joint';


--
-- Name: COLUMN conversations.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.status IS 'OWNERSHIP: joint';


--
-- Name: COLUMN conversations.closed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.closed_at IS 'OWNERSHIP: joint — that the conversation closed is observable to both. WHO closed it lives on matches.ended_by.';


--
-- Name: COLUMN conversations.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.created_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN conversations.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.attempt_id IS 'OA-ZYRA-159 stage 4a. THE conversation belongs to an ATTEMPT, not a pair. A new attempt gets a new conversation, so a fresh start is genuinely fresh and the previous attempt''s messages stay with the previous attempt (messages hang off conversation_id). match_id remains until OA-ZYRA-156 step 7 -- do not read this table by it.';


--
-- Name: email_outbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_outbox (
    user_id uuid NOT NULL,
    template_key text NOT NULL,
    variables jsonb NOT NULL,
    due_at timestamp with time zone NOT NULL,
    sent_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    CONSTRAINT email_outbox_template_key_check CHECK ((template_key = ANY (ARRAY['inactivity_1'::text, 'inactivity_2'::text, 'inactivity_3'::text, 'inactivity_4'::text, 'inactivity_5'::text])))
);


--
-- Name: family_membership_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_membership_invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    family_subscription_id uuid NOT NULL,
    invited_by uuid NOT NULL,
    invited_user_id uuid NOT NULL,
    role text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '7 days'::interval) NOT NULL,
    responded_at timestamp with time zone,
    CONSTRAINT family_invitation_response_shape CHECK ((((status = 'pending'::text) AND (responded_at IS NULL)) OR ((status <> 'pending'::text) AND (responded_at IS NOT NULL)))),
    CONSTRAINT family_invitation_seven_day_window CHECK ((expires_at = (created_at + '7 days'::interval))),
    CONSTRAINT family_membership_invitations_role_check CHECK ((role = ANY (ARRAY['seeker'::text, 'guardian'::text]))),
    CONSTRAINT family_membership_invitations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text, 'expired'::text, 'cancelled'::text])))
);


--
-- Name: family_message_chat_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_message_chat_state (
    chat_id uuid NOT NULL,
    user_id uuid NOT NULL,
    last_read_at timestamp with time zone,
    muted_at timestamp with time zone
);


--
-- Name: TABLE family_message_chat_state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.family_message_chat_state IS 'Owner-only member preferences and read state for a specific Circle chat.';


--
-- Name: family_message_chats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_message_chats (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    thread_id uuid NOT NULL,
    kind text NOT NULL,
    attempt_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT family_message_chats_check CHECK (((kind = 'main'::text) = (attempt_id IS NULL))),
    CONSTRAINT family_message_chats_kind_check CHECK ((kind = ANY (ARRAY['main'::text, 'journey'::text])))
);


--
-- Name: TABLE family_message_chats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.family_message_chats IS 'Circle-owned discussion identity. Journey attempt ids are joint identifiers; do not expose them as member fields.';


--
-- Name: family_message_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_message_memberships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    thread_id uuid NOT NULL,
    user_id uuid NOT NULL,
    member_role text NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    readable_from timestamp with time zone DEFAULT now() NOT NULL,
    left_at timestamp with time zone,
    CONSTRAINT family_message_memberships_member_role_check CHECK ((member_role = ANY (ARRAY['seeker'::text, 'guardian'::text]))),
    CONSTRAINT family_message_memberships_time_order CHECK (((left_at IS NULL) OR (left_at >= joined_at)))
);


--
-- Name: TABLE family_message_memberships; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.family_message_memberships IS 'Epoch-scoped Guardian Circle membership; no pre-join history is exposed.';


--
-- Name: family_message_participant_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_message_participant_state (
    thread_id uuid NOT NULL,
    user_id uuid NOT NULL,
    last_read_at timestamp with time zone,
    muted_at timestamp with time zone,
    archived_at timestamp with time zone
);


--
-- Name: family_message_report_evidence; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_message_report_evidence (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    report_id uuid NOT NULL,
    thread_id uuid NOT NULL,
    message_id uuid NOT NULL,
    reported_sender_id uuid,
    reason text NOT NULL,
    reported_body text NOT NULL,
    immediate_context jsonb DEFAULT '[]'::jsonb NOT NULL,
    reported_at timestamp with time zone NOT NULL,
    closed_at timestamp with time zone,
    retain_until timestamp with time zone,
    legal_hold boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE family_message_report_evidence; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.family_message_report_evidence IS 'Protected moderation evidence: reported message plus bounded immediate context. Service-role only. Retained 24 months after case closure unless an active legal/safety hold requires longer.';


--
-- Name: family_message_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_message_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    thread_id uuid,
    message_id uuid,
    reporter_id uuid,
    reported_id uuid,
    reason text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    reviewed_at timestamp with time zone,
    sealed_message_id uuid,
    CONSTRAINT family_message_reports_distinct_people CHECK ((reporter_id <> reported_id)),
    CONSTRAINT family_message_reports_reason_check CHECK ((reason = ANY (ARRAY['harassment'::text, 'inappropriate_content'::text, 'violence'::text, 'privacy'::text, 'other'::text]))),
    CONSTRAINT family_message_reports_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'reviewing'::text, 'actioned'::text, 'dismissed'::text])))
);


--
-- Name: family_message_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_message_threads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    seeker_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_message_at timestamp with time zone
);


--
-- Name: TABLE family_message_threads; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.family_message_threads IS 'One canonical shared Guardian Circle per Seeker. Never a Journey chat.';


--
-- Name: family_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    thread_id uuid NOT NULL,
    sender_id uuid,
    kind text DEFAULT 'message'::text NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sender_deleted_at timestamp with time zone,
    chat_id uuid NOT NULL,
    CONSTRAINT family_messages_body_length CHECK (((char_length(btrim(body)) >= 1) AND (char_length(btrim(body)) <= 2000))),
    CONSTRAINT family_messages_kind_check CHECK ((kind = ANY (ARRAY['message'::text, 'lifecycle'::text]))),
    CONSTRAINT family_messages_sender_shape CHECK ((((kind = 'message'::text) AND (sender_id IS NOT NULL)) OR ((kind = 'lifecycle'::text) AND (sender_id IS NULL))))
);


--
-- Name: family_ownership_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_ownership_transfers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    family_subscription_id uuid NOT NULL,
    current_owner_id uuid,
    replacement_owner_id uuid,
    replacement_role text NOT NULL,
    status text DEFAULT 'pending_acceptance'::text NOT NULL,
    requested_at timestamp with time zone DEFAULT now() NOT NULL,
    accepted_at timestamp with time zone,
    replacement_purchase_confirmed_at timestamp with time zone,
    effective_at timestamp with time zone,
    completed_at timestamp with time zone,
    CONSTRAINT family_ownership_distinct_people CHECK ((current_owner_id <> replacement_owner_id)),
    CONSTRAINT family_ownership_schedule_shape CHECK (((status <> ALL (ARRAY['scheduled'::text, 'completed'::text])) OR ((accepted_at IS NOT NULL) AND (replacement_purchase_confirmed_at IS NOT NULL) AND (effective_at IS NOT NULL)))),
    CONSTRAINT family_ownership_transfers_live_parties_required CHECK ((((current_owner_id IS NOT NULL) AND (replacement_owner_id IS NOT NULL)) OR (status = ANY (ARRAY['completed'::text, 'declined'::text, 'cancelled'::text])))),
    CONSTRAINT family_ownership_transfers_replacement_role_check CHECK ((replacement_role = ANY (ARRAY['seeker'::text, 'guardian'::text]))),
    CONSTRAINT family_ownership_transfers_status_check CHECK ((status = ANY (ARRAY['pending_acceptance'::text, 'pending_purchase'::text, 'scheduled'::text, 'completed'::text, 'declined'::text, 'cancelled'::text])))
);


--
-- Name: family_seat_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_seat_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    family_subscription_id uuid NOT NULL,
    member_id uuid NOT NULL,
    role text NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    removed_at timestamp with time zone,
    funded_until timestamp with time zone,
    CONSTRAINT family_seat_assignment_time_order CHECK (((removed_at IS NULL) OR (removed_at >= assigned_at))),
    CONSTRAINT family_seat_assignments_role_check CHECK ((role = ANY (ARRAY['seeker'::text, 'guardian'::text])))
);


--
-- Name: family_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    owner_id uuid,
    owner_role text NOT NULL,
    status text NOT NULL,
    seeker_places integer NOT NULL,
    guardian_places integer NOT NULL,
    billing_period text DEFAULT 'monthly'::text NOT NULL,
    coverage_ends_at timestamp with time zone,
    billing_grace_started_at timestamp with time zone,
    billing_grace_until timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT family_subscriptions_billing_grace_maximum CHECK ((((billing_grace_started_at IS NULL) AND (billing_grace_until IS NULL)) OR ((billing_grace_started_at IS NOT NULL) AND (billing_grace_until IS NOT NULL) AND (billing_grace_until > billing_grace_started_at) AND (billing_grace_until <= (billing_grace_started_at + '3 days'::interval))))),
    CONSTRAINT family_subscriptions_billing_period_check CHECK ((billing_period = 'monthly'::text)),
    CONSTRAINT family_subscriptions_guardian_places_check CHECK (((guardian_places >= 0) AND (guardian_places <= 10))),
    CONSTRAINT family_subscriptions_live_owner_required CHECK (((owner_id IS NOT NULL) OR (status = ANY (ARRAY['expired'::text, 'cancelled'::text, 'refunded'::text, 'chargeback'::text])))),
    CONSTRAINT family_subscriptions_non_empty CHECK (((seeker_places + guardian_places) > 0)),
    CONSTRAINT family_subscriptions_owner_role_check CHECK ((owner_role = ANY (ARRAY['seeker'::text, 'guardian'::text]))),
    CONSTRAINT family_subscriptions_seeker_places_check CHECK (((seeker_places >= 0) AND (seeker_places <= 10))),
    CONSTRAINT family_subscriptions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'billing_grace'::text, 'cancel_at_period_end'::text, 'expired'::text, 'cancelled'::text, 'refunded'::text, 'chargeback'::text])))
);


--
-- Name: guardian_journey_history_consents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guardian_journey_history_consents (
    wali_link_id uuid NOT NULL,
    main_guardian_authority_id uuid,
    granted_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    guardian_link_authority_id uuid NOT NULL
);


--
-- Name: TABLE guardian_journey_history_consents; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.guardian_journey_history_consents IS 'DR-ZYRA-225/233 current-state permission for past Journey summaries. A row grants only when wali_link_id and guardian_link_authority_id match one current active link. Absent or mismatched means OFF. No direct client access; use zyra_guardian_history_consent(uuid, boolean).';


--
-- Name: COLUMN guardian_journey_history_consents.main_guardian_authority_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.guardian_journey_history_consents.main_guardian_authority_id IS 'Legacy DR-ZYRA-225 Main-assignment snapshot retained for compatibility and audit provenance. New authority uses guardian_link_authority_id.';


--
-- Name: COLUMN guardian_journey_history_consents.guardian_link_authority_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.guardian_journey_history_consents.guardian_link_authority_id IS 'Snapshot of wali_links.guardian_link_authority_id at grant time. A mismatch invalidates permission after removal/reactivation without relying on client cleanup.';


--
-- Name: guardian_journey_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guardian_journey_permissions (
    wali_link_id uuid NOT NULL,
    match_id uuid NOT NULL,
    can_view boolean DEFAULT true NOT NULL,
    can_chat boolean DEFAULT true NOT NULL,
    updated_by uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT guardian_journey_chat_requires_view CHECK ((can_view OR (NOT can_chat)))
);


--
-- Name: journey_compatibility; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_compatibility (
    match_id uuid NOT NULL,
    seeker_a_revealed boolean DEFAULT false NOT NULL,
    seeker_b_revealed boolean DEFAULT false NOT NULL,
    revealed_at timestamp with time zone,
    attempt_id uuid,
    seeker_a_score numeric,
    seeker_b_score numeric,
    seeker_a_categories jsonb,
    seeker_b_categories jsonb
);


--
-- Name: TABLE journey_compatibility; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.journey_compatibility IS 'RPC-only Compatibility Reveal state. Client roles have no direct table privileges; caller-relative access is enforced by OA-ZYRA-283 functions.';


--
-- Name: COLUMN journey_compatibility.seeker_a_revealed; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_compatibility.seeker_a_revealed IS 'OWNERSHIP: row-scoped(matches.seeker_a_id) — one person''s choice to reveal';


--
-- Name: COLUMN journey_compatibility.seeker_b_revealed; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_compatibility.seeker_b_revealed IS 'OWNERSHIP: row-scoped(matches.seeker_b_id)';


--
-- Name: COLUMN journey_compatibility.revealed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_compatibility.revealed_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN journey_compatibility.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_compatibility.attempt_id IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';


--
-- Name: COLUMN journey_compatibility.seeker_a_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_compatibility.seeker_a_score IS 'seeker_a''s own compatibility figure: how well seeker_b''s answers fit seeker_a''s stated preferences. NOT shared with seeker_b — OA-ZYRA-193 a2.';


--
-- Name: COLUMN journey_compatibility.seeker_b_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_compatibility.seeker_b_score IS 'seeker_b''s own compatibility figure. See seeker_a_score.';


--
-- Name: journey_family_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_family_answers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    direction text NOT NULL,
    question_id text NOT NULL,
    answerer_id uuid NOT NULL,
    answer_text text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    attempt_id uuid,
    CONSTRAINT journey_family_answers_direction_check CHECK ((direction = ANY (ARRAY['seeker_to_wali'::text, 'wali_to_seeker'::text])))
);


--
-- Name: COLUMN journey_family_answers.answerer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_answers.answerer_id IS 'OWNERSHIP: row-scoped(answerer_id) — MAY BE A GUARDIAN, not a Seeker. A Guardian''s answers belong to that Guardian and reach neither Seeker''s export.';


--
-- Name: COLUMN journey_family_answers.answer_text; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_answers.answer_text IS 'OWNERSHIP: row-scoped(answerer_id) — see answerer_id.';


--
-- Name: COLUMN journey_family_answers.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_answers.attempt_id IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';


--
-- Name: journey_family_review_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_family_review_responses (
    review_id uuid NOT NULL,
    wali_id uuid NOT NULL,
    decision text NOT NULL,
    responded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT journey_family_review_responses_decision_check CHECK ((decision = ANY (ARRAY['continue'::text, 'pause'::text])))
);


--
-- Name: TABLE journey_family_review_responses; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.journey_family_review_responses IS 'OWNERSHIP: third-party(guardian). NEVER exported to either Seeker. A Guardian is a data subject in their own right; my own Guardian''s decision is not my personal data. A Guardian pausing a Journey, and that being exportable to the Seeker they paused, is a family-safety problem as well as a privacy one.';


--
-- Name: COLUMN journey_family_review_responses.wali_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_review_responses.wali_id IS 'OWNERSHIP: third-party(guardian) — non-exportable to Seekers';


--
-- Name: COLUMN journey_family_review_responses.decision; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_review_responses.decision IS 'OWNERSHIP: third-party(guardian) — non-exportable to Seekers. Only the aggregate review outcome is disclosable.';


--
-- Name: COLUMN journey_family_review_responses.responded_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_family_review_responses.responded_at IS 'OWNERSHIP: third-party(guardian) — non-exportable to Seekers';


--
-- Name: journey_guardian_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_guardian_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attempt_id uuid NOT NULL,
    wali_link_id uuid NOT NULL,
    seeker_id uuid NOT NULL,
    granted_by uuid,
    granted_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    revoked_by uuid,
    revoked_at timestamp with time zone,
    CONSTRAINT journey_guardian_assignments_revocation_pair CHECK (((revoked_by IS NULL) OR (revoked_at IS NOT NULL)))
);


--
-- Name: TABLE journey_guardian_assignments; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.journey_guardian_assignments IS 'Audited per-attempt access grants for Additional Guardians. Live rows have revoked_at NULL. Main Guardians are never stored here because their active role is the non-optional Journey authority.';


--
-- Name: journey_milestone_attestations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_milestone_attestations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    attempt_id uuid NOT NULL,
    milestone_type text NOT NULL,
    occurred_on date NOT NULL,
    proposed_by uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    confirmed_by uuid,
    confirmed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT journey_milestone_attestations_milestone_type_check CHECK ((milestone_type = ANY (ARRAY['meeting'::text, 'nikah'::text]))),
    CONSTRAINT journey_milestone_attestations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'superseded'::text])))
);


--
-- Name: TABLE journey_milestone_attestations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.journey_milestone_attestations IS 'Meeting/Nikah proposals awaiting the other Seeker''s confirmation (Founder 2026-08-12). Confirmation writes the timeline_milestones row; user-attested, both-party record.';


--
-- Name: journey_phase_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_phase_answers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    phase integer NOT NULL,
    seeker_id uuid NOT NULL,
    question_id text NOT NULL,
    answer_text text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    attempt_id uuid,
    CONSTRAINT journey_phase_answers_phase_check CHECK ((phase = ANY (ARRAY[1, 2, 3])))
);


--
-- Name: COLUMN journey_phase_answers.seeker_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_answers.seeker_id IS 'OWNERSHIP: row-scoped(seeker_id)';


--
-- Name: COLUMN journey_phase_answers.answer_text; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_answers.answer_text IS 'OWNERSHIP: row-scoped(seeker_id) — highest-sensitivity free text in the Journey set. The other party''s answers must never appear in an export.';


--
-- Name: COLUMN journey_phase_answers.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_answers.attempt_id IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';


--
-- Name: journey_phase_checkpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_phase_checkpoints (
    match_id uuid NOT NULL,
    phase integer NOT NULL,
    seeker_id uuid NOT NULL,
    decision text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    attempt_id uuid,
    CONSTRAINT journey_phase_checkpoints_decision_check CHECK ((decision = ANY (ARRAY['continue'::text, 'ask_more'::text, 'end'::text]))),
    CONSTRAINT journey_phase_checkpoints_phase_check CHECK ((phase = ANY (ARRAY[1, 2, 3])))
);


--
-- Name: COLUMN journey_phase_checkpoints.seeker_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_checkpoints.seeker_id IS 'OWNERSHIP: row-scoped(seeker_id)';


--
-- Name: COLUMN journey_phase_checkpoints.decision; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_checkpoints.decision IS 'OWNERSHIP: row-scoped(seeker_id) — their decision to continue or end is theirs, even though the outcome affected both.';


--
-- Name: COLUMN journey_phase_checkpoints.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_checkpoints.attempt_id IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';


--
-- Name: journey_phase_ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_phase_ratings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    phase integer NOT NULL,
    rater_id uuid NOT NULL,
    question_id text NOT NULL,
    rating text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    attempt_id uuid,
    CONSTRAINT journey_phase_ratings_phase_check CHECK ((phase = ANY (ARRAY[1, 2, 3]))),
    CONSTRAINT journey_phase_ratings_rating_check CHECK ((rating = ANY (ARRAY['reassured'::text, 'discuss_further'::text, 'concerns'::text])))
);


--
-- Name: COLUMN journey_phase_ratings.rater_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_ratings.rater_id IS 'OWNERSHIP: row-scoped(rater_id)';


--
-- Name: COLUMN journey_phase_ratings.rating; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_ratings.rating IS 'OWNERSHIP: pending-legal — Founder 2026-08-06: whether "they rated you Amber" must be disclosed under Art.15''s source limb is a legal question. A rating I gave is mine; a rating of me is theirs. Withhold until confirmed.';


--
-- Name: COLUMN journey_phase_ratings.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_phase_ratings.attempt_id IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';


--
-- Name: journey_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    requested_by uuid NOT NULL,
    requested_to uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    responded_at timestamp with time zone,
    attempt_id uuid,
    withdrawn_at timestamp with time zone,
    closed_reason text,
    CONSTRAINT requests_accepted_has_attempt CHECK (((status = 'accepted'::text) = (attempt_id IS NOT NULL))),
    CONSTRAINT requests_not_to_self CHECK ((requested_by <> requested_to)),
    CONSTRAINT requests_response_matches_status CHECK ((((status = 'pending'::text) AND (responded_at IS NULL) AND (withdrawn_at IS NULL)) OR ((status = 'withdrawn'::text) AND (responded_at IS NULL) AND (withdrawn_at IS NOT NULL)) OR ((status = ANY (ARRAY['accepted'::text, 'declined'::text, 'recipient_unavailable'::text])) AND (responded_at IS NOT NULL) AND (withdrawn_at IS NULL)))),
    CONSTRAINT requests_status_known CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text, 'withdrawn'::text, 'recipient_unavailable'::text])))
);


--
-- Name: TABLE journey_requests; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.journey_requests IS 'OA-ZYRA-159 / DR-ZYRA-121 item 8. One pending request per pair. Readable by both parties; writable only through request_new_journey() and respond_to_journey_request(). status is coarse ON PURPOSE — which kind of decline, and whether it was a decision or an expiry, is recorded only in protection_holds, which the requester cannot read.';


--
-- Name: journey_salams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_salams (
    match_id uuid NOT NULL,
    seeker_id uuid NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    attempt_id uuid
);


--
-- Name: COLUMN journey_salams.seeker_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_salams.seeker_id IS 'OWNERSHIP: row-scoped(seeker_id)';


--
-- Name: COLUMN journey_salams.sent_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_salams.sent_at IS 'OWNERSHIP: row-scoped(seeker_id)';


--
-- Name: COLUMN journey_salams.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.journey_salams.attempt_id IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';


--
-- Name: journey_stage_checkpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_stage_checkpoints (
    match_id uuid NOT NULL,
    attempt_id uuid,
    stage text NOT NULL,
    seeker_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT journey_stage_checkpoints_stage_known CHECK ((stage = ANY (ARRAY['compatibility_reveal'::text, 'salam_exchange'::text, 'wali_gate'::text, 'phase_1'::text, 'phase_2'::text, 'phase_3'::text, 'family_stage'::text, 'conversation'::text])))
);


--
-- Name: TABLE journey_stage_checkpoints; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.journey_stage_checkpoints IS 'OWNERSHIP: row-scoped(seeker_id), readable by both Seekers of the attempt. One row = "this Seeker has chosen to continue past this stage". Written ONLY by zyra_advance_stage(); no client INSERT grant exists, so a checkpoint cannot be forged or written on another person''s behalf. See PRE-JOURNEY RITUAL (current version).';


--
-- Name: likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.likes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    liker_id uuid NOT NULL,
    liked_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT likes_check CHECK ((liker_id <> liked_id))
);


--
-- Name: COLUMN likes.liker_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.likes.liker_id IS 'OWNERSHIP: row-scoped(liker_id)';


--
-- Name: COLUMN likes.liked_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.likes.liked_id IS 'OWNERSHIP: non-exportable to the liked person unless it has become a mutual match.';


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_id uuid NOT NULL,
    sender_id uuid,
    content text NOT NULL,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: COLUMN messages.sender_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.sender_id IS 'OWNERSHIP: row-scoped(sender_id)';


--
-- Name: COLUMN messages.content; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN messages.read_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN messages.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.deleted_at IS 'OWNERSHIP: row-scoped(sender_id)';


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    category text NOT NULL,
    enabled boolean NOT NULL,
    changed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    seq bigint NOT NULL,
    CONSTRAINT notification_preferences_category_check CHECK ((category = ANY (ARRAY['matches_journeys'::text, 'guardian_activity'::text, 'introductions'::text, 'marketing_emails'::text, 'product_updates'::text, 'circle'::text])))
);


--
-- Name: TABLE notification_preferences; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.notification_preferences IS 'OWNERSHIP: row-scoped(user_id). Append-only consent and preference log. Never UPDATE or DELETE a row — the history IS the evidence. Current state is the newest row per (user_id, category).';


--
-- Name: COLUMN notification_preferences.enabled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notification_preferences.enabled IS 'OWNERSHIP: row-scoped(user_id). For marketing_emails and product_updates this is a record of CONSENT given or withdrawn, and is disclosable to the user under Article 15.';


--
-- Name: COLUMN notification_preferences.seq; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notification_preferences.seq IS 'Monotonic insertion order. The authoritative tiebreaker for "which consent event is current" — changed_at alone is not sufficient, because two events in one transaction can share it.';


--
-- Name: notification_preferences_seq_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_preferences_seq_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_preferences_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_preferences_seq_seq OWNED BY public.notification_preferences.seq;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    body text,
    related_match_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    read_at timestamp with time zone,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    related_chat_id uuid,
    CONSTRAINT notifications_circle_payload_check CHECK ((((type = 'circle_message'::text) = (related_chat_id IS NOT NULL)) AND ((type <> 'circle_message'::text) OR ((related_match_id IS NULL) AND (payload = '{}'::jsonb) AND (title = 'Guardian Circle'::text) AND (NOT (body IS DISTINCT FROM 'New message in your Guardian Circle'::text)))))),
    CONSTRAINT notifications_inactive_notice_anonymous CHECK (((type <> 'journey_ended_profile_inactive'::text) OR ((payload = '{}'::jsonb) AND (related_match_id IS NULL)))),
    CONSTRAINT notifications_type_check CHECK ((type = ANY (ARRAY['new_match'::text, 'new_message'::text, 'wali_request'::text, 'journey_ended'::text, 'journey_request'::text, 'journey_request_accepted'::text, 'journey_request_declined'::text, 'milestone_proposed'::text, 'milestone_confirmed'::text, 'pause_nudge'::text, 'journey_paused'::text, 'journey_also_paused'::text, 'journey_continued'::text, 'wali_invite_received'::text, 'wali_invite_declined'::text, 'wali_invite_expiring'::text, 'wali_invite_expired'::text, 'wali_invite_revoked'::text, 'inactivity_warning'::text, 'journey_ended_profile_inactive'::text, 'circle_message'::text])))
);


--
-- Name: COLUMN notifications.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.user_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN notifications.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.type IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN notifications.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.title IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN notifications.body; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.body IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN notifications.related_match_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.related_match_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN notifications.read_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.read_at IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: onboarding_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.onboarding_answers (
    user_id uuid NOT NULL,
    ch3_answers jsonb DEFAULT '{}'::jsonb NOT NULL,
    ch4_preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    ch4_hard_requirements jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    capture_version text DEFAULT 'v1'::text NOT NULL,
    CONSTRAINT onboarding_answers_capture_version_check CHECK ((capture_version = ANY (ARRAY['v0'::text, 'v1'::text]))),
    CONSTRAINT onboarding_answers_ch4_hard_shape CHECK (public.zyra_ch4_hard_shape_ok(ch4_hard_requirements))
);


--
-- Name: COLUMN onboarding_answers.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.onboarding_answers.user_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN onboarding_answers.ch3_answers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.onboarding_answers.ch3_answers IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN onboarding_answers.ch4_preferences; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.onboarding_answers.ch4_preferences IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN onboarding_answers.ch4_hard_requirements; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.onboarding_answers.ch4_hard_requirements IS 'Per-OPTION hard exclusions: {question_id: [option_label, ...]}. An option listed here is never introduced, full stop — checked independently of ch4_preferences so a dealbreaker set before the questions are walked still binds. WAS {question_id: bool} until 2026-08-10, which could not express "never X, but I would consider Y" on the same question.';


--
-- Name: passes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.passes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    passer_id uuid NOT NULL,
    passed_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT passes_check CHECK ((passer_id <> passed_id))
);


--
-- Name: COLUMN passes.passer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.passes.passer_id IS 'OWNERSHIP: row-scoped(passer_id)';


--
-- Name: COLUMN passes.passed_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.passes.passed_id IS 'OWNERSHIP: non-exportable to the passed person. ZYRA promises "no record, no notification" on a Pass; an export disclosing it would break that promise through a route nobody thought to close.';


--
-- Name: photo_object_deletions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.photo_object_deletions (
    path text NOT NULL,
    bucket text NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    last_error text,
    done_at timestamp with time zone,
    account_delete_due_at timestamp with time zone,
    CONSTRAINT photo_object_deletions_attempts_check CHECK (((attempts >= 0) AND (attempts <= 10))),
    CONSTRAINT photo_object_deletions_bucket_check CHECK ((bucket = ANY (ARRAY['profile-photos'::text, 'profile-photo-sources'::text])))
);


--
-- Name: COLUMN photo_object_deletions.account_delete_due_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.photo_object_deletions.account_delete_due_at IS 'Physical removal deadline for an account deletion. Null for other queue entries.';


--
-- Name: preference_light_confirmations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preference_light_confirmations (
    user_id uuid NOT NULL,
    question_id text NOT NULL,
    option_value text NOT NULL,
    light text NOT NULL,
    capture_version text DEFAULT 'v1'::text NOT NULL,
    confirmed_at timestamp with time zone DEFAULT statement_timestamp() NOT NULL,
    CONSTRAINT preference_light_confirmations_capture_version_check CHECK ((capture_version = 'v1'::text)),
    CONSTRAINT preference_light_confirmations_light_check CHECK ((light = ANY (ARRAY['green'::text, 'amber'::text, 'red'::text])))
);


--
-- Name: profile_hides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_hides (
    hider uuid NOT NULL,
    hidden uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profile_hides_check CHECK ((hider <> hidden))
);


--
-- Name: profile_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_photos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    storage_path text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    display_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    source_path text,
    crop jsonb,
    rotation integer DEFAULT 0 NOT NULL,
    revision integer DEFAULT 1 NOT NULL,
    removed_at timestamp with time zone,
    CONSTRAINT profile_photo_source_name CHECK (((source_path IS NULL) OR (source_path = ((((user_id)::text || '/'::text) || (id)::text) || '.jpg'::text)))),
    CONSTRAINT profile_photos_revision_check CHECK ((revision > 0)),
    CONSTRAINT profile_photos_rotation_check CHECK ((rotation = ANY (ARRAY[0, 90, 180, 270])))
);


--
-- Name: TABLE profile_photos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.profile_photos IS 'OWNERSHIP: row-scoped(user_id). Attachment data follows the same Mine/Theirs/Joint model as Journey data — Founder requirement 2026-08-06. Any future attachment table (documents, evidence, voice notes, media) MUST carry an OWNERSHIP comment on its author column before it is used, and the binary in Storage inherits its row''s class.';


--
-- Name: COLUMN profile_photos.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_photos.user_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN profile_photos.storage_path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_photos.storage_path IS 'OWNERSHIP: row-scoped(user_id) — the Storage object inherits the row''s class. An export must include the FILE, not just the path.';


--
-- Name: COLUMN profile_photos.is_primary; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_photos.is_primary IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN profile_photos.display_order; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_photos.display_order IS 'OWNERSHIP: row-scoped(user_id) — the owner''s own ordering choice.';


--
-- Name: profile_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporter_id uuid,
    reported_id uuid,
    reason text NOT NULL,
    detail text,
    source text DEFAULT 'browse'::text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    reviewed_at timestamp with time zone,
    attempt_id uuid,
    CONSTRAINT profile_reports_reason_check CHECK ((reason = ANY (ARRAY['fake_profile'::text, 'inappropriate_content'::text, 'harassment'::text, 'underage'::text, 'violence'::text, 'privacy'::text, 'other'::text]))),
    CONSTRAINT profile_reports_source_check CHECK ((source = ANY (ARRAY['browse'::text, 'chat'::text, 'journey'::text, 'connections'::text, 'profile'::text, 'guardian'::text]))),
    CONSTRAINT profile_reports_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'reviewing'::text, 'actioned'::text, 'dismissed'::text])))
);


--
-- Name: TABLE profile_reports; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.profile_reports IS 'OWNERSHIP: row-scoped(reporter_id). NON-EXPORTABLE to the reported person, including any attached evidence — §15.3. Handing someone the report filed against them defeats the protection entirely.';


--
-- Name: COLUMN profile_reports.reporter_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_reports.reporter_id IS 'OWNERSHIP: row-scoped(reporter_id)';


--
-- Name: COLUMN profile_reports.reported_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_reports.reported_id IS 'OWNERSHIP: non-exportable to the reported person';


--
-- Name: COLUMN profile_reports.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_reports.reason IS 'OWNERSHIP: non-exportable to the reported person';


--
-- Name: COLUMN profile_reports.detail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_reports.detail IS 'OWNERSHIP: non-exportable to the reported person — free text, and the most likely place for evidence-like content today.';


--
-- Name: COLUMN profile_reports.source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_reports.source IS 'OWNERSHIP: row-scoped(reporter_id)';


--
-- Name: COLUMN profile_reports.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_reports.status IS 'OWNERSHIP: row-scoped(reporter_id)';


--
-- Name: COLUMN profile_reports.reviewed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_reports.reviewed_at IS 'OWNERSHIP: row-scoped(reporter_id)';


--
-- Name: COLUMN profile_reports.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_reports.attempt_id IS 'Exact Journey attempt supplied or resolved at filing. Its ID remains on the safety report after archive purge.';


--
-- Name: profile_unlocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_unlocks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    unlocker_id uuid NOT NULL,
    unlocked_id uuid NOT NULL,
    unlock_type text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profile_unlocks_check CHECK ((unlocker_id <> unlocked_id)),
    CONSTRAINT profile_unlocks_unlock_type_check CHECK ((unlock_type = ANY (ARRAY['paid_single'::text, 'paid_plus_single'::text, 'paid_bundle'::text, 'paid_plus_bundle'::text, 'automatic_match'::text])))
);


--
-- Name: COLUMN profile_unlocks.unlocker_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_unlocks.unlocker_id IS 'OWNERSHIP: row-scoped(unlocker_id)';


--
-- Name: COLUMN profile_unlocks.unlocked_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_unlocks.unlocked_id IS 'OWNERSHIP: non-exportable to the UNLOCKED person. Disclosing it would tell someone who has been paying to look at them.';


--
-- Name: COLUMN profile_unlocks.unlock_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_unlocks.unlock_type IS 'OWNERSHIP: row-scoped(unlocker_id)';


--
-- Name: profile_videos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_videos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    storage_path text NOT NULL,
    status text NOT NULL,
    duration_ms integer NOT NULL,
    reject_reason text,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    reviewed_at timestamp with time zone,
    CONSTRAINT profile_videos_duration_ms_check CHECK (((duration_ms >= 1) AND (duration_ms <= 10500))),
    CONSTRAINT profile_videos_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'removed'::text])))
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    role text DEFAULT 'seeker'::text NOT NULL,
    first_name text NOT NULL,
    date_of_birth date NOT NULL,
    gender text NOT NULL,
    location_text text,
    bio text,
    is_active boolean DEFAULT true NOT NULL,
    profile_complete boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    surname_line text,
    first_published_at timestamp with time zone,
    onboarding_complete boolean DEFAULT false NOT NULL,
    last_active_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profiles_adult_only CHECK ((date_of_birth <= (CURRENT_DATE - '18 years'::interval))),
    CONSTRAINT profiles_dob_plausible CHECK ((date_of_birth >= '1900-01-01'::date)),
    CONSTRAINT profiles_first_name_shape CHECK (((first_name = btrim(first_name)) AND ((char_length(first_name) >= 1) AND (char_length(first_name) <= 60)))),
    CONSTRAINT profiles_gender_check CHECK ((gender = ANY (ARRAY['male'::text, 'female'::text]))),
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['seeker'::text, 'wali'::text, 'admin'::text])))
);


--
-- Name: COLUMN profiles.role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.role IS 'OWNERSHIP: row-scoped(id)';


--
-- Name: COLUMN profiles.first_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.first_name IS 'OWNERSHIP: row-scoped(id) — shown publicly in Browse';


--
-- Name: COLUMN profiles.date_of_birth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.date_of_birth IS 'OWNERSHIP: row-scoped(id) — not client-readable; others see a derived age via ages_for().';


--
-- Name: COLUMN profiles.gender; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.gender IS 'OWNERSHIP: row-scoped(id)';


--
-- Name: COLUMN profiles.location_text; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.location_text IS 'OWNERSHIP: row-scoped(id)';


--
-- Name: COLUMN profiles.bio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.bio IS 'OWNERSHIP: row-scoped(id)';


--
-- Name: COLUMN profiles.is_active; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.is_active IS 'OWNERSHIP: row-scoped(id)';


--
-- Name: COLUMN profiles.profile_complete; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.profile_complete IS 'OWNERSHIP: row-scoped(id)';


--
-- Name: COLUMN profiles.surname_line; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.surname_line IS 'OWNERSHIP: row-scoped(id)';


--
-- Name: COLUMN profiles.first_published_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.first_published_at IS 'Set the first time a profile is published and NEVER cleared, including on un-publish. Gender and date_of_birth are frozen once this is non-null — that is the whole reason the column exists, and it is why profile_complete could not be used: profile_complete is reversible, and PERMANENT BEHAVIOUR MUST DERIVE FROM PERMANENT DATA (Founder invariant, 2026-08-08). BACKFILL WARNING: rows predating 2026-08-07 were backfilled from created_at, a lower bound. Safe to test for NULL. NOT safe to show a user as a date.';


--
-- Name: COLUMN profiles.onboarding_complete; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.onboarding_complete IS 'OA-ZYRA-193(c). Maintained by trigger, never written by the app. True when this Seeker has finished onboarding — basic profile, Chapter 2, and every Chapter 3/4 question they were actually shown. Distinct from profile_complete, which means only the name/date-of-birth/photos step.';


--
-- Name: CONSTRAINT profiles_adult_only ON profiles; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT profiles_adult_only ON public.profiles IS 'ZYRA is 18+. Final authority — client validation is a courtesy, this is the guarantee.';


--
-- Name: protection_holds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protection_holds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid,
    restricted_id uuid,
    protected_id uuid,
    hold_type text NOT NULL,
    appealable boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    released_at timestamp with time zone,
    released_by uuid,
    release_reason text,
    released_by_departed boolean DEFAULT false NOT NULL,
    CONSTRAINT holds_cooldown_must_expire CHECK (((hold_type <> 'decline_cooldown'::text) OR (expires_at IS NOT NULL))),
    CONSTRAINT holds_no_self_hold CHECK ((restricted_id <> protected_id)),
    CONSTRAINT holds_permanent_never_expires CHECK (((hold_type <> 'decline_permanent'::text) OR (expires_at IS NULL))),
    CONSTRAINT holds_release_is_complete CHECK ((((released_at IS NULL) AND (released_by IS NULL) AND (release_reason IS NULL) AND (NOT released_by_departed)) OR ((released_at IS NOT NULL) AND (release_reason IS NOT NULL) AND ((released_by IS NULL) = released_by_departed)))),
    CONSTRAINT holds_safety_is_never_appealable CHECK (((hold_type <> 'safety'::text) OR (appealable = false))),
    CONSTRAINT holds_type_known CHECK ((hold_type = ANY (ARRAY['decline_cooldown'::text, 'decline_permanent'::text, 'safety'::text, 'moderation'::text])))
);


--
-- Name: TABLE protection_holds; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.protection_holds IS 'OA-ZYRA-157 / DR-ZYRA-121 item 5. Directional bars between two people on a pair. Active = released_at IS NULL AND (expires_at IS NULL OR expires_at > now()). RLS on with no policies DELIBERATELY: a hold must be unreadable by the person it restricts. Read it only through zyra_hold_blocks().';


--
-- Name: CONSTRAINT holds_release_is_complete ON protection_holds; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT holds_release_is_complete ON public.protection_holds IS 'A release records a date, reason and actor until that actor deletes their account.';


--
-- Name: saves; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saves (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    saver_id uuid NOT NULL,
    saved_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT saves_check CHECK ((saver_id <> saved_id))
);


--
-- Name: COLUMN saves.saver_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.saves.saver_id IS 'OWNERSHIP: row-scoped(saver_id)';


--
-- Name: COLUMN saves.saved_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.saves.saved_id IS 'OWNERSHIP: non-exportable to the SAVED person — being saved is the saver''s private act.';


--
-- Name: seeker_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seeker_details (
    user_id uuid NOT NULL,
    sect text,
    sect_other text,
    revert_status boolean,
    country_of_birth text,
    nationality text,
    ethnicity text,
    languages text[] DEFAULT '{}'::text[] NOT NULL,
    preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    capture_version text DEFAULT 'v1'::text NOT NULL,
    CONSTRAINT seeker_details_capture_version_check CHECK ((capture_version = ANY (ARRAY['v0'::text, 'v1'::text]))),
    CONSTRAINT seeker_details_cob_is_code CHECK (((country_of_birth IS NULL) OR (country_of_birth ~ '^[A-Z]{2}$'::text))),
    CONSTRAINT seeker_details_ethnicity_is_code CHECK (((ethnicity IS NULL) OR (ethnicity ~ '^[a-z][a-z_]*$'::text))),
    CONSTRAINT seeker_details_languages_are_codes CHECK (public.zyra_all_iso639_1(languages)),
    CONSTRAINT seeker_details_nat_is_code CHECK (((nationality IS NULL) OR (nationality ~ '^[A-Z]{2}$'::text))),
    CONSTRAINT seeker_details_sect_hard_shape CHECK (public.zyra_ch2_sect_hard_shape_ok(preferences)),
    CONSTRAINT seeker_details_sect_known CHECK (((sect IS NULL) OR (sect ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text))),
    CONSTRAINT seeker_details_sect_other_len CHECK (((sect_other IS NULL) OR (char_length(sect_other) <= 60)))
);


--
-- Name: TABLE seeker_details; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.seeker_details IS 'OWNERSHIP: row-scoped(user_id). Article 9 special-category data — always disclosable to its subject, never to anyone else except through a paid unlock (seeker_details_for_unlocked).';


--
-- Name: COLUMN seeker_details.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.user_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN seeker_details.sect; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.sect IS 'Canonical lowercase hyphenated code. The same code keys preferences->sect->matrix and hard_requirement; display labels never enter scoring.';


--
-- Name: COLUMN seeker_details.sect_other; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.sect_other IS 'OWNERSHIP: row-scoped(user_id) — Article 9';


--
-- Name: COLUMN seeker_details.revert_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.revert_status IS 'OWNERSHIP: row-scoped(user_id) — Article 9';


--
-- Name: COLUMN seeker_details.country_of_birth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.country_of_birth IS 'OWNERSHIP: row-scoped(user_id) — Article 9 by inference';


--
-- Name: COLUMN seeker_details.nationality; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.nationality IS 'OWNERSHIP: row-scoped(user_id) — Article 9 by inference';


--
-- Name: COLUMN seeker_details.ethnicity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.ethnicity IS 'OWNERSHIP: row-scoped(user_id) — Article 9';


--
-- Name: COLUMN seeker_details.languages; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.languages IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN seeker_details.preferences; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.seeker_details.preferences IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    plan_type text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    billing_period text,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    billing_grace_started_at timestamp with time zone,
    billing_grace_until timestamp with time zone,
    coverage_ends_at timestamp with time zone,
    CONSTRAINT subscriptions_billing_grace_maximum CHECK ((((billing_grace_started_at IS NULL) AND (billing_grace_until IS NULL)) OR ((billing_grace_started_at IS NOT NULL) AND (billing_grace_until IS NOT NULL) AND (billing_grace_until > billing_grace_started_at) AND (billing_grace_until <= (billing_grace_started_at + '3 days'::interval))))),
    CONSTRAINT subscriptions_billing_period_check CHECK ((billing_period = ANY (ARRAY['monthly'::text, 'annual'::text]))),
    CONSTRAINT subscriptions_plan_type_check CHECK ((plan_type = ANY (ARRAY['seeker_basic'::text, 'seeker_premium'::text, 'wali_basic'::text, 'wali_premium'::text]))),
    CONSTRAINT subscriptions_status_check CHECK ((status = ANY (ARRAY['active'::text, 'expired'::text, 'cancelled'::text])))
);


--
-- Name: COLUMN subscriptions.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subscriptions.user_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN subscriptions.plan_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subscriptions.plan_type IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN subscriptions.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subscriptions.status IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN subscriptions.billing_period; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subscriptions.billing_period IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN subscriptions.started_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subscriptions.started_at IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN subscriptions.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subscriptions.expires_at IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: timeline_milestones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timeline_milestones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    timeline_id uuid NOT NULL,
    milestone_type text NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb,
    CONSTRAINT timeline_milestones_milestone_type_check CHECK ((milestone_type = ANY (ARRAY['liked'::text, 'match_created'::text, 'journey_started'::text, 'compatibility_revealed'::text, 'salam_exchanged'::text, 'guardian_linked'::text, 'phase_1_complete'::text, 'phase_2_complete'::text, 'phase_3_complete'::text, 'family_stage'::text, 'conversation_started'::text, 'meeting'::text, 'nikah'::text, 'journey_ended'::text, 'journey_restarted'::text, 'journey_paused'::text, 'journey_continued'::text])))
);


--
-- Name: COLUMN timeline_milestones.milestone_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timeline_milestones.milestone_type IS 'OWNERSHIP: joint';


--
-- Name: COLUMN timeline_milestones.occurred_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timeline_milestones.occurred_at IS 'OWNERSHIP: joint';


--
-- Name: COLUMN timeline_milestones.metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timeline_milestones.metadata IS 'OWNERSHIP: non-exportable — Founder approved 2026-08-06. Unconstrained jsonb; until it has a defined schema it cannot inherit a class its future contents may not deserve. Loosen later if appropriate, never the other way round.';


--
-- Name: timelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timelines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    attempt_id uuid NOT NULL
);


--
-- Name: COLUMN timelines.match_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timelines.match_id IS 'OWNERSHIP: joint';


--
-- Name: COLUMN timelines.attempt_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timelines.attempt_id IS 'OA-ZYRA-159 stage 4a, and the Journey Timeline specification V3 D2. One timeline per attempt; the SCREEN presents every attempt for a pair as chapters of one relationship. Storage per attempt, presentation per relationship -- that is what makes a restart fresh without erasing history.';


--
-- Name: unlock_credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unlock_credits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    tier text NOT NULL,
    delta integer NOT NULL,
    reason text NOT NULL,
    related_unlock_id uuid,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT unlock_credits_delta_check CHECK ((delta <> 0)),
    CONSTRAINT unlock_credits_reason_check CHECK ((reason = ANY (ARRAY['zyra_one_included'::text, 'purchase'::text, 'debug_grant'::text, 'spend'::text, 'refund'::text, 'adjustment'::text]))),
    CONSTRAINT unlock_credits_sign_matches_reason CHECK ((((reason = 'spend'::text) AND (delta < 0)) OR ((reason = 'refund'::text) AND (delta > 0)) OR ((reason = ANY (ARRAY['zyra_one_included'::text, 'purchase'::text, 'debug_grant'::text])) AND (delta > 0)) OR (reason = 'adjustment'::text))),
    CONSTRAINT unlock_credits_tier_check CHECK ((tier = ANY (ARRAY['paid_single'::text, 'paid_plus_single'::text])))
);


--
-- Name: TABLE unlock_credits; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.unlock_credits IS 'OWNERSHIP: row-scoped(user_id) — the holder''s own ledger.';


--
-- Name: COLUMN unlock_credits.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unlock_credits.user_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN unlock_credits.tier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unlock_credits.tier IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN unlock_credits.delta; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unlock_credits.delta IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN unlock_credits.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unlock_credits.reason IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN unlock_credits.related_unlock_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unlock_credits.related_unlock_id IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: COLUMN unlock_credits.note; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unlock_credits.note IS 'OWNERSHIP: row-scoped(user_id)';


--
-- Name: wali_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wali_links (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    seeker_id uuid NOT NULL,
    wali_id uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_main boolean DEFAULT false NOT NULL,
    relationship text,
    main_guardian_authority_id uuid,
    active_since timestamp with time zone,
    guardian_link_authority_id uuid,
    place_kind text,
    invitation_id uuid,
    CONSTRAINT wali_links_active_since_state CHECK ((((status = 'active'::text) AND (active_since IS NOT NULL)) OR ((status <> 'active'::text) AND (active_since IS NULL)))),
    CONSTRAINT wali_links_guardian_link_authority_state CHECK ((((status = 'active'::text) AND (guardian_link_authority_id IS NOT NULL)) OR ((status <> 'active'::text) AND (guardian_link_authority_id IS NULL)))),
    CONSTRAINT wali_links_main_guardian_authority_state CHECK ((((status = 'active'::text) AND (is_main IS TRUE) AND (main_guardian_authority_id IS NOT NULL)) OR (((status <> 'active'::text) OR (is_main IS FALSE)) AND (main_guardian_authority_id IS NULL)))),
    CONSTRAINT wali_links_no_self_link CHECK ((seeker_id <> wali_id)),
    CONSTRAINT wali_links_place_kind_check CHECK ((place_kind = ANY (ARRAY['basic_place'::text, 'guardian_one'::text]))),
    CONSTRAINT wali_links_relationship_check CHECK (((relationship IS NULL) OR (relationship = ANY (ARRAY['father'::text, 'brother'::text, 'grandfather'::text, 'uncle'::text, 'legal_guardian'::text, 'family_representative'::text, 'other'::text])))),
    CONSTRAINT wali_links_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'removed'::text])))
);


--
-- Name: TABLE wali_links; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.wali_links IS 'Guardian relationships. WRITE PATH IS accept_wali_invite() AND THE zyra_*_guardian() RPCs ONLY — client INSERT/UPDATE/DELETE grants were revoked 2026-08-07 after a demonstrated bypass that let a Seeker create an active link naming any user as their Guardian without consent. Do not re-grant. If a new write is needed, add a SECURITY DEFINER function.';


--
-- Name: COLUMN wali_links.seeker_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.seeker_id IS 'OWNERSHIP: joint(seeker_id, wali_id)';


--
-- Name: COLUMN wali_links.wali_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.wali_id IS 'OWNERSHIP: joint(seeker_id, wali_id)';


--
-- Name: COLUMN wali_links.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.status IS 'OWNERSHIP: joint(seeker_id, wali_id)';


--
-- Name: COLUMN wali_links.is_main; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.is_main IS 'OWNERSHIP: joint(seeker_id, wali_id)';


--
-- Name: COLUMN wali_links.relationship; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.relationship IS 'OWNERSHIP: joint(seeker_id, wali_id) — both parties know the relationship. Disclosed to a Seeker only via guardians_for_unlocked, which is gated on a paid profile unlock. Stored as a code; "uncle" renders as "Paternal Uncle".';


--
-- Name: COLUMN wali_links.main_guardian_authority_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.main_guardian_authority_id IS 'DR-ZYRA-225: opaque current-Main assignment epoch. Rotates whenever this link freshly becomes Main; null for every non-current-Main link. It is not a historical role timestamp and is never displayed.';


--
-- Name: COLUMN wali_links.active_since; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.active_since IS 'DR-ZYRA-225 / 054 N1: server-authoritative start of this link row''s current continuous active period. Fresh on activation/reactivation, preserved across uninterrupted Main/Additional switches and unrelated updates, null while inactive. created_at remains row provenance.';


--
-- Name: COLUMN wali_links.guardian_link_authority_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.guardian_link_authority_id IS 'DR-ZYRA-233 opaque current-active-link epoch for one Seeker/Guardian relationship. Fresh on activation/reactivation, preserved across continuous Main/Additional switches, null while inactive, never displayed.';


--
-- Name: COLUMN wali_links.place_kind; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.place_kind IS 'Guardian place at acceptance of a Seeker-sent legacy invitation. Current eligibility always uses verified entitlements. Legacy links may be null.';


--
-- Name: COLUMN wali_links.invitation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_links.invitation_id IS 'Seeker-sent legacy invitation that recorded this place. Null for links without recorded provenance or when the invitation is removed.';


--
-- Name: CONSTRAINT wali_links_no_self_link ON wali_links; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT wali_links_no_self_link ON public.wali_links IS 'A Guardian relationship requires two people. Integrity, not policy.';


--
-- Name: wali_suggestions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wali_suggestions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    wali_id uuid NOT NULL,
    seeker_id uuid NOT NULL,
    suggested_id uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    seen_at timestamp with time zone,
    CONSTRAINT wali_suggestions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text])))
);


--
-- Name: TABLE wali_suggestions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.wali_suggestions IS 'OWNERSHIP: joint(wali_id, seeker_id) — a Guardian''s suggestion to their Seeker. NON-EXPORTABLE to the suggested person, who is not party to it and must never learn they were suggested or declined.';


--
-- Name: COLUMN wali_suggestions.wali_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_suggestions.wali_id IS 'OWNERSHIP: joint(wali_id, seeker_id)';


--
-- Name: COLUMN wali_suggestions.seeker_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_suggestions.seeker_id IS 'OWNERSHIP: joint(wali_id, seeker_id)';


--
-- Name: COLUMN wali_suggestions.suggested_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_suggestions.suggested_id IS 'OWNERSHIP: non-exportable to the suggested person. They are a third party to this row.';


--
-- Name: COLUMN wali_suggestions.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_suggestions.status IS 'OWNERSHIP: joint(wali_id, seeker_id) — the Seeker''s response to their own Guardian. Never disclosed to the suggested person: "she declined you" is not theirs to receive.';


--
-- Name: COLUMN wali_suggestions.responded_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_suggestions.responded_at IS 'OWNERSHIP: joint(wali_id, seeker_id)';


--
-- Name: COLUMN wali_suggestions.seen_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wali_suggestions.seen_at IS 'OWNERSHIP: row-scoped(seeker_id) — when the Seeker first landed on Introductions with this suggestion present. Null means unseen. Drives the badge only; it is not a read receipt shown to the Guardian, who must not learn whether their suggestion has been looked at but not yet answered.';


--
-- Name: zyra_attempt_participant_rows; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.zyra_attempt_participant_rows AS
 SELECT a.id AS attempt_id,
    participant.user_id,
    'seeker'::text AS role,
    a.match_id,
    NULL::boolean AS is_main,
    a.status AS attempt_status
   FROM (((public.journey_attempts a
     JOIN public.matches m ON ((m.id = a.match_id)))
     LEFT JOIN private.zyra_ended_journey_visibility v ON ((v.attempt_id = a.id)))
     CROSS JOIN LATERAL ( VALUES (m.seeker_a_id,v.seeker_a_visible), (m.seeker_b_id,v.seeker_b_visible)) participant(user_id, archive_visible))
  WHERE ((participant.user_id IS NOT NULL) AND ((a.status <> 'ended'::text) OR participant.archive_visible) AND (NOT (EXISTS ( SELECT 1
           FROM private.zyra_account_deleted_matches d
          WHERE (d.match_id = m.id)))))
UNION ALL
 SELECT a.id AS attempt_id,
    w.wali_id AS user_id,
    'guardian'::text AS role,
    a.match_id,
    w.is_main,
    a.status AS attempt_status
   FROM ((public.journey_attempts a
     JOIN public.matches m ON ((m.id = a.match_id)))
     JOIN public.wali_links w ON (((w.status = 'active'::text) AND ((w.seeker_id = m.seeker_a_id) OR (w.seeker_id = m.seeker_b_id)))))
  WHERE ((a.status = 'active'::text) AND (NOT (EXISTS ( SELECT 1
           FROM private.zyra_account_deleted_matches d
          WHERE (d.match_id = m.id)))) AND ((w.is_main IS TRUE) OR (EXISTS ( SELECT 1
           FROM public.journey_guardian_assignments jga
          WHERE ((jga.attempt_id = a.id) AND (jga.wali_link_id = w.id) AND (jga.seeker_id = w.seeker_id) AND (jga.revoked_at IS NULL) AND (jga.granted_at >= w.active_since))))));


--
-- Name: VIEW zyra_attempt_participant_rows; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.zyra_attempt_participant_rows IS 'F02 and Q126. Exact-attempt participation, with irreversible per-Seeker removal and live pair blocks for archives. Guardian detail remains current-attempt only.';


--
-- Name: zyra_data_ownership; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.zyra_data_ownership AS
 SELECT c.table_name,
    c.column_name,
    COALESCE("substring"(pgd.description, 'OWNERSHIP:\s*([a-z\-]+(\([^)]*\))?)'::text), '*** UNCLASSIFIED ***'::text) AS ownership,
    pgd.description AS note
   FROM ((((information_schema.columns c
     JOIN pg_class cl ON ((cl.relname = (c.table_name)::name)))
     JOIN pg_namespace ns ON (((ns.oid = cl.relnamespace) AND (ns.nspname = (c.table_schema)::name))))
     JOIN pg_tables t ON (((t.tablename = (c.table_name)::name) AND (t.schemaname = (c.table_schema)::name))))
     LEFT JOIN pg_description pgd ON (((pgd.objoid = cl.oid) AND (pgd.objsubid = (c.ordinal_position)::integer))))
  WHERE (((c.table_schema)::name = 'public'::name) AND ((c.column_name)::name <> ALL (ARRAY['id'::name, 'created_at'::name, 'updated_at'::name, 'match_id'::name, 'conversation_id'::name, 'timeline_id'::name, 'review_id'::name, 'attempt_id'::name, 'phase'::name, 'question_id'::name, 'direction'::name])));


--
-- Name: VIEW zyra_data_ownership; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.zyra_data_ownership IS 'OA-ZYRA-155, platform-wide. Scans EVERY public table — a new table appears as UNCLASSIFIED automatically. Never export a row showing UNCLASSIFIED or pending-legal.';


--
-- Name: zyra_inactivity_notices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zyra_inactivity_notices (
    user_id uuid NOT NULL,
    warned_at timestamp with time zone NOT NULL,
    removal_due_at timestamp with time zone NOT NULL,
    cleared_at timestamp with time zone,
    completed_at timestamp with time zone,
    welcome_back_pending boolean DEFAULT false NOT NULL,
    CONSTRAINT zyra_inactivity_notices_check CHECK (((cleared_at IS NULL) OR (completed_at IS NULL))),
    CONSTRAINT zyra_inactivity_notices_check1 CHECK (((NOT welcome_back_pending) OR (cleared_at IS NOT NULL)))
);


--
-- Name: zyra_my_attempt_participation; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.zyra_my_attempt_participation WITH (security_invoker='true') AS
 SELECT attempt_id,
    role,
    match_id,
    is_main,
    attempt_status
   FROM private.zyra_my_attempt_participation_rows() zyra_my_attempt_participation_rows(attempt_id, role, match_id, is_main, attempt_status);


--
-- Name: VIEW zyra_my_attempt_participation; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.zyra_my_attempt_participation IS 'Caller-rights Journey projection. The private helper returns only the signed-in caller’s participation, avoiding policy recursion.';


--
-- Name: zyra_onboarding_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zyra_onboarding_questions (
    qid text NOT NULL,
    gender_visibility text NOT NULL,
    is_multi boolean NOT NULL,
    options jsonb NOT NULL,
    show_if_qid text,
    show_if_not_any_of jsonb,
    ch4_scored boolean DEFAULT true NOT NULL,
    category text
);


--
-- Name: TABLE zyra_onboarding_questions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.zyra_onboarding_questions IS 'The Chapter 3/4 question bank, server-side. Mirrors data/chapter3_categories.dart — a question added there and not here is a question the completeness gate stops requiring. Renamed from zyra_seed_ch4_questions 2026-08-11: it was created for seeding and became canonical.';


--
-- Name: COLUMN zyra_onboarding_questions.show_if_qid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zyra_onboarding_questions.show_if_qid IS 'Mirrors ShowIf.questionId. The question whose answer controls whether this one is asked.';


--
-- Name: COLUMN zyra_onboarding_questions.show_if_not_any_of; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zyra_onboarding_questions.show_if_not_any_of IS 'Mirrors ShowIf.notAnyOf. Hide this question when the controlling answer is any of these.';


--
-- Name: COLUMN zyra_onboarding_questions.ch4_scored; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zyra_onboarding_questions.ch4_scored IS 'Mirrors OnboardingQuestion.ch4Status != none. True: has a Chapter 4 preference screen and feeds score_candidates. False: asked in Chapter 3 as profile detail only.';


--
-- Name: COLUMN zyra_onboarding_questions.category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zyra_onboarding_questions.category IS 'Mirrors OnboardingCategory.name. Nine categories, per the Founder decision of 2026-08-11 on OA-ZYRA-193(d).';


--
-- Name: zyra_photo_cleanup_failures; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.zyra_photo_cleanup_failures WITH (security_invoker='true') AS
 SELECT bucket,
    path,
    attempts,
    last_error,
    account_delete_due_at
   FROM public.photo_object_deletions d
  WHERE ((done_at IS NULL) AND ((attempts = 10) OR (account_delete_due_at <= now())));


--
-- Name: notification_preferences seq; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences ALTER COLUMN seq SET DEFAULT nextval('public.notification_preferences_seq_seq'::regclass);


--
-- Name: guardian_trial_ledger guardian_trial_ledger_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.guardian_trial_ledger
    ADD CONSTRAINT guardian_trial_ledger_pkey PRIMARY KEY (verified_person_id);


--
-- Name: identity_verification_attempts identity_verification_attempts_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.identity_verification_attempts
    ADD CONSTRAINT identity_verification_attempts_pkey PRIMARY KEY (id);


--
-- Name: identity_verification_attempts identity_verification_attempts_provider_event_ref_hash_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.identity_verification_attempts
    ADD CONSTRAINT identity_verification_attempts_provider_event_ref_hash_key UNIQUE (provider_event_ref_hash);


--
-- Name: identity_verification_attempts identity_verification_attempts_provider_session_ref_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.identity_verification_attempts
    ADD CONSTRAINT identity_verification_attempts_provider_session_ref_key UNIQUE (provider_session_ref);


--
-- Name: identity_verification_event_receipts identity_verification_event_receipts_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.identity_verification_event_receipts
    ADD CONSTRAINT identity_verification_event_receipts_pkey PRIMARY KEY (provider_event_ref_hash);


--
-- Name: report_protected_attempts report_protected_attempts_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.report_protected_attempts
    ADD CONSTRAINT report_protected_attempts_pkey PRIMARY KEY (report_id, attempt_id);


--
-- Name: safety_sealed_messages safety_sealed_messages_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.safety_sealed_messages
    ADD CONSTRAINT safety_sealed_messages_pkey PRIMARY KEY (id);


--
-- Name: safety_sealed_messages safety_sealed_messages_source_source_message_id_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.safety_sealed_messages
    ADD CONSTRAINT safety_sealed_messages_source_source_message_id_key UNIQUE (source, source_message_id);


--
-- Name: seeker_home_places seeker_home_places_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.seeker_home_places
    ADD CONSTRAINT seeker_home_places_pkey PRIMARY KEY (user_id);


--
-- Name: seeker_trial_ledger seeker_trial_ledger_payment_authorisation_ref_hash_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.seeker_trial_ledger
    ADD CONSTRAINT seeker_trial_ledger_payment_authorisation_ref_hash_key UNIQUE (payment_authorisation_ref_hash);


--
-- Name: seeker_trial_ledger seeker_trial_ledger_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.seeker_trial_ledger
    ADD CONSTRAINT seeker_trial_ledger_pkey PRIMARY KEY (verified_person_id);


--
-- Name: verified_people verified_people_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.verified_people
    ADD CONSTRAINT verified_people_pkey PRIMARY KEY (id);


--
-- Name: verified_people verified_people_provider_person_ref_hash_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.verified_people
    ADD CONSTRAINT verified_people_provider_person_ref_hash_key UNIQUE (provider_person_ref_hash);


--
-- Name: verified_person_accounts verified_person_accounts_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.verified_person_accounts
    ADD CONSTRAINT verified_person_accounts_pkey PRIMARY KEY (user_id, role);


--
-- Name: verified_person_accounts verified_person_accounts_verified_person_id_role_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.verified_person_accounts
    ADD CONSTRAINT verified_person_accounts_verified_person_id_role_key UNIQUE (verified_person_id, role);


--
-- Name: zyra_account_deleted_matches zyra_account_deleted_matches_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_account_deleted_matches
    ADD CONSTRAINT zyra_account_deleted_matches_pkey PRIMARY KEY (match_id);


--
-- Name: zyra_circle_seal_protections zyra_circle_seal_protections_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_circle_seal_protections
    ADD CONSTRAINT zyra_circle_seal_protections_pkey PRIMARY KEY (sealed_message_id, report_id);


--
-- Name: zyra_compatibility_sect_repairs zyra_compatibility_sect_repairs_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_compatibility_sect_repairs
    ADD CONSTRAINT zyra_compatibility_sect_repairs_pkey PRIMARY KEY (viewer);


--
-- Name: zyra_deleted_attempt_evidence zyra_deleted_attempt_evidence_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_deleted_attempt_evidence
    ADD CONSTRAINT zyra_deleted_attempt_evidence_pkey PRIMARY KEY (attempt_id);


--
-- Name: zyra_directional_results zyra_directional_results_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_directional_results
    ADD CONSTRAINT zyra_directional_results_pkey PRIMARY KEY (viewer, subject);


--
-- Name: zyra_ended_journey_removals zyra_ended_journey_removals_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_ended_journey_removals
    ADD CONSTRAINT zyra_ended_journey_removals_pkey PRIMARY KEY (attempt_id);


--
-- Name: zyra_family_chat_report_attempts zyra_family_chat_report_attempts_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_family_chat_report_attempts
    ADD CONSTRAINT zyra_family_chat_report_attempts_pkey PRIMARY KEY (report_id);


--
-- Name: zyra_guardian_invite_accept_guards zyra_guardian_invite_accept_guards_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_guardian_invite_accept_guards
    ADD CONSTRAINT zyra_guardian_invite_accept_guards_pkey PRIMARY KEY (seeker_id);


--
-- Name: zyra_guardian_notification_sources zyra_guardian_notification_sources_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_guardian_notification_sources
    ADD CONSTRAINT zyra_guardian_notification_sources_pkey PRIMARY KEY (notification_id);


--
-- Name: zyra_journey_reveal_tombstones zyra_journey_reveal_tombstones_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_journey_reveal_tombstones
    ADD CONSTRAINT zyra_journey_reveal_tombstones_pkey PRIMARY KEY (attempt_id);


--
-- Name: zyra_personal_code_attempts zyra_personal_code_attempts_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_personal_code_attempts
    ADD CONSTRAINT zyra_personal_code_attempts_pkey PRIMARY KEY (id);


--
-- Name: zyra_personal_codes zyra_personal_codes_code_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_personal_codes
    ADD CONSTRAINT zyra_personal_codes_code_key UNIQUE (code);


--
-- Name: zyra_personal_codes zyra_personal_codes_owner_id_role_context_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_personal_codes
    ADD CONSTRAINT zyra_personal_codes_owner_id_role_context_key UNIQUE (owner_id, role_context);


--
-- Name: zyra_personal_codes zyra_personal_codes_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_personal_codes
    ADD CONSTRAINT zyra_personal_codes_pkey PRIMARY KEY (id);


--
-- Name: zyra_photo_cleanup_leases zyra_photo_cleanup_leases_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_photo_cleanup_leases
    ADD CONSTRAINT zyra_photo_cleanup_leases_pkey PRIMARY KEY (bucket, path);


--
-- Name: zyra_photo_folder_guard zyra_photo_folder_guard_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_photo_folder_guard
    ADD CONSTRAINT zyra_photo_folder_guard_pkey PRIMARY KEY (folder);


--
-- Name: zyra_product_events zyra_product_events_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_product_events
    ADD CONSTRAINT zyra_product_events_pkey PRIMARY KEY (id);


--
-- Name: zyra_purged_ended_match_projections zyra_purged_ended_match_projections_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_purged_ended_match_projections
    ADD CONSTRAINT zyra_purged_ended_match_projections_pkey PRIMARY KEY (match_id);


--
-- Name: zyra_question_area zyra_question_area_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_question_area
    ADD CONSTRAINT zyra_question_area_pkey PRIMARY KEY (question_id);


--
-- Name: zyra_report_sealed_messages zyra_report_sealed_messages_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_report_sealed_messages
    ADD CONSTRAINT zyra_report_sealed_messages_pkey PRIMARY KEY (report_id, sealed_message_id);


--
-- Name: zyra_retired_personal_code_hashes zyra_retired_personal_code_hashes_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_retired_personal_code_hashes
    ADD CONSTRAINT zyra_retired_personal_code_hashes_pkey PRIMARY KEY (code_sha256);


--
-- Name: zyra_unlock_account_guards zyra_unlock_account_guards_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_unlock_account_guards
    ADD CONSTRAINT zyra_unlock_account_guards_pkey PRIMARY KEY (user_id);


--
-- Name: zyra_unlock_operations zyra_unlock_operations_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_unlock_operations
    ADD CONSTRAINT zyra_unlock_operations_pkey PRIMARY KEY (id);


--
-- Name: zyra_unlock_operations zyra_unlock_operations_unlocker_id_unlocked_id_tier_key; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_unlock_operations
    ADD CONSTRAINT zyra_unlock_operations_unlocker_id_unlocked_id_tier_key UNIQUE (unlocker_id, unlocked_id, tier);


--
-- Name: zyra_unlock_release_gate zyra_unlock_release_gate_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.zyra_unlock_release_gate
    ADD CONSTRAINT zyra_unlock_release_gate_pkey PRIMARY KEY (singleton);


--
-- Name: app_feedback app_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_feedback
    ADD CONSTRAINT app_feedback_pkey PRIMARY KEY (id);


--
-- Name: consents consents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consents
    ADD CONSTRAINT consents_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_attempt_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_attempt_id_key UNIQUE (attempt_id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: email_outbox email_outbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_outbox
    ADD CONSTRAINT email_outbox_pkey PRIMARY KEY (user_id, template_key, due_at);


--
-- Name: family_membership_invitations family_membership_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_membership_invitations
    ADD CONSTRAINT family_membership_invitations_pkey PRIMARY KEY (id);


--
-- Name: family_message_chat_state family_message_chat_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_chat_state
    ADD CONSTRAINT family_message_chat_state_pkey PRIMARY KEY (chat_id, user_id);


--
-- Name: family_message_chats family_message_chats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_chats
    ADD CONSTRAINT family_message_chats_pkey PRIMARY KEY (id);


--
-- Name: family_message_chats family_message_chats_thread_id_attempt_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_chats
    ADD CONSTRAINT family_message_chats_thread_id_attempt_id_key UNIQUE (thread_id, attempt_id);


--
-- Name: family_message_chats family_message_chats_thread_id_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_chats
    ADD CONSTRAINT family_message_chats_thread_id_id_key UNIQUE (thread_id, id);


--
-- Name: family_message_memberships family_message_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_memberships
    ADD CONSTRAINT family_message_memberships_pkey PRIMARY KEY (id);


--
-- Name: family_message_participant_state family_message_participant_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_participant_state
    ADD CONSTRAINT family_message_participant_state_pkey PRIMARY KEY (thread_id, user_id);


--
-- Name: family_message_report_evidence family_message_report_evidence_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_report_evidence
    ADD CONSTRAINT family_message_report_evidence_pkey PRIMARY KEY (id);


--
-- Name: family_message_report_evidence family_message_report_evidence_report_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_report_evidence
    ADD CONSTRAINT family_message_report_evidence_report_id_key UNIQUE (report_id);


--
-- Name: family_message_reports family_message_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_reports
    ADD CONSTRAINT family_message_reports_pkey PRIMARY KEY (id);


--
-- Name: family_message_threads family_message_threads_one_circle_per_seeker; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_threads
    ADD CONSTRAINT family_message_threads_one_circle_per_seeker UNIQUE (seeker_id);


--
-- Name: family_message_threads family_message_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_message_threads
    ADD CONSTRAINT family_message_threads_pkey PRIMARY KEY (id);


--
-- Name: family_messages family_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_messages
    ADD CONSTRAINT family_messages_pkey PRIMARY KEY (id);


--
-- Name: family_ownership_transfers family_ownership_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_ownership_transfers
    ADD CONSTRAINT family_ownership_transfers_pkey PRIMARY KEY (id);


--
-- Name: family_seat_assignments family_seat_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_seat_assignments
    ADD CONSTRAINT family_seat_assignments_pkey PRIMARY KEY (id);


--
-- Name: family_subscriptions family_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_subscriptions
    ADD CONSTRAINT family_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: guardian_journey_history_consents guardian_journey_history_consents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guardian_journey_history_consents
    ADD CONSTRAINT guardian_journey_history_consents_pkey PRIMARY KEY (wali_link_id);


--
-- Name: guardian_journey_permissions guardian_journey_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guardian_journey_permissions
    ADD CONSTRAINT guardian_journey_permissions_pkey PRIMARY KEY (wali_link_id, match_id);


--
-- Name: journey_attempts journey_attempts_match_id_attempt_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_attempts
    ADD CONSTRAINT journey_attempts_match_id_attempt_number_key UNIQUE (match_id, attempt_number);


--
-- Name: journey_attempts journey_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_attempts
    ADD CONSTRAINT journey_attempts_pkey PRIMARY KEY (id);


--
-- Name: journey_compatibility journey_compatibility_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_compatibility
    ADD CONSTRAINT journey_compatibility_pkey PRIMARY KEY (match_id);


--
-- Name: journey_family_answers journey_family_answers_match_id_direction_question_id_answe_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_family_answers
    ADD CONSTRAINT journey_family_answers_match_id_direction_question_id_answe_key UNIQUE (match_id, direction, question_id, answerer_id);


--
-- Name: journey_family_answers journey_family_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_family_answers
    ADD CONSTRAINT journey_family_answers_pkey PRIMARY KEY (id);


--
-- Name: journey_family_review_responses journey_family_review_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_family_review_responses
    ADD CONSTRAINT journey_family_review_responses_pkey PRIMARY KEY (review_id, wali_id);


--
-- Name: journey_family_reviews journey_family_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_family_reviews
    ADD CONSTRAINT journey_family_reviews_pkey PRIMARY KEY (id);


--
-- Name: journey_guardian_assignments journey_guardian_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_guardian_assignments
    ADD CONSTRAINT journey_guardian_assignments_pkey PRIMARY KEY (id);


--
-- Name: journey_milestone_attestations journey_milestone_attestations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_milestone_attestations
    ADD CONSTRAINT journey_milestone_attestations_pkey PRIMARY KEY (id);


--
-- Name: journey_phase_answers journey_phase_answers_match_id_phase_seeker_id_question_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_phase_answers
    ADD CONSTRAINT journey_phase_answers_match_id_phase_seeker_id_question_id_key UNIQUE (match_id, phase, seeker_id, question_id);


--
-- Name: journey_phase_answers journey_phase_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_phase_answers
    ADD CONSTRAINT journey_phase_answers_pkey PRIMARY KEY (id);


--
-- Name: journey_phase_checkpoints journey_phase_checkpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_phase_checkpoints
    ADD CONSTRAINT journey_phase_checkpoints_pkey PRIMARY KEY (match_id, phase, seeker_id);


--
-- Name: journey_phase_ratings journey_phase_ratings_match_id_phase_rater_id_question_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_phase_ratings
    ADD CONSTRAINT journey_phase_ratings_match_id_phase_rater_id_question_id_key UNIQUE (match_id, phase, rater_id, question_id);


--
-- Name: journey_phase_ratings journey_phase_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_phase_ratings
    ADD CONSTRAINT journey_phase_ratings_pkey PRIMARY KEY (id);


--
-- Name: journey_requests journey_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_requests
    ADD CONSTRAINT journey_requests_pkey PRIMARY KEY (id);


--
-- Name: journey_salams journey_salams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_salams
    ADD CONSTRAINT journey_salams_pkey PRIMARY KEY (match_id, seeker_id);


--
-- Name: journey_stage_checkpoints journey_stage_checkpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_stage_checkpoints
    ADD CONSTRAINT journey_stage_checkpoints_pkey PRIMARY KEY (match_id, stage, seeker_id);


--
-- Name: likes likes_liker_id_liked_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_liker_id_liked_id_key UNIQUE (liker_id, liked_id);


--
-- Name: likes likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: matches matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (id);


--
-- Name: matches matches_seeker_a_id_seeker_b_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_seeker_a_id_seeker_b_id_key UNIQUE (seeker_a_id, seeker_b_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: onboarding_answers onboarding_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onboarding_answers
    ADD CONSTRAINT onboarding_answers_pkey PRIMARY KEY (user_id);


--
-- Name: passes passes_passer_id_passed_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passes
    ADD CONSTRAINT passes_passer_id_passed_id_key UNIQUE (passer_id, passed_id);


--
-- Name: passes passes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passes
    ADD CONSTRAINT passes_pkey PRIMARY KEY (id);


--
-- Name: photo_object_deletions photo_object_deletions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photo_object_deletions
    ADD CONSTRAINT photo_object_deletions_pkey PRIMARY KEY (bucket, path);


--
-- Name: preference_light_confirmations preference_light_confirmations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preference_light_confirmations
    ADD CONSTRAINT preference_light_confirmations_pkey PRIMARY KEY (user_id, question_id, option_value);


--
-- Name: profile_blocks profile_blocks_blocker_id_blocked_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_blocks
    ADD CONSTRAINT profile_blocks_blocker_id_blocked_id_key UNIQUE (blocker_id, blocked_id);


--
-- Name: profile_blocks profile_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_blocks
    ADD CONSTRAINT profile_blocks_pkey PRIMARY KEY (id);


--
-- Name: profile_hides profile_hides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_hides
    ADD CONSTRAINT profile_hides_pkey PRIMARY KEY (hider, hidden);


--
-- Name: profile_photos profile_photos_owner_path_ck; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.profile_photos
    ADD CONSTRAINT profile_photos_owner_path_ck CHECK (((split_part(storage_path, '/'::text, 1) = (user_id)::text) AND (length(storage_path) > 37))) NOT VALID;


--
-- Name: profile_photos profile_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_photos
    ADD CONSTRAINT profile_photos_pkey PRIMARY KEY (id);


--
-- Name: profile_reports profile_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_reports
    ADD CONSTRAINT profile_reports_pkey PRIMARY KEY (id);


--
-- Name: profile_unlocks profile_unlocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_unlocks
    ADD CONSTRAINT profile_unlocks_pkey PRIMARY KEY (id);


--
-- Name: profile_videos profile_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_videos
    ADD CONSTRAINT profile_videos_pkey PRIMARY KEY (id);


--
-- Name: profile_videos profile_videos_storage_path_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_videos
    ADD CONSTRAINT profile_videos_storage_path_key UNIQUE (storage_path);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: protection_holds protection_holds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protection_holds
    ADD CONSTRAINT protection_holds_pkey PRIMARY KEY (id);


--
-- Name: saves saves_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saves
    ADD CONSTRAINT saves_pkey PRIMARY KEY (id);


--
-- Name: saves saves_saver_id_saved_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saves
    ADD CONSTRAINT saves_saver_id_saved_id_key UNIQUE (saver_id, saved_id);


--
-- Name: seeker_details seeker_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seeker_details
    ADD CONSTRAINT seeker_details_pkey PRIMARY KEY (user_id);


--
-- Name: subscriptions subscriptions_paid_only_monthly; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions
    ADD CONSTRAINT subscriptions_paid_only_monthly CHECK (((billing_period IS NULL) OR (billing_period = 'monthly'::text))) NOT VALID;


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: timeline_milestones timeline_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timeline_milestones
    ADD CONSTRAINT timeline_milestones_pkey PRIMARY KEY (id);


--
-- Name: timelines timelines_attempt_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timelines
    ADD CONSTRAINT timelines_attempt_id_key UNIQUE (attempt_id);


--
-- Name: timelines timelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timelines
    ADD CONSTRAINT timelines_pkey PRIMARY KEY (id);


--
-- Name: unlock_credits unlock_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unlock_credits
    ADD CONSTRAINT unlock_credits_pkey PRIMARY KEY (id);


--
-- Name: wali_invites wali_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wali_invites
    ADD CONSTRAINT wali_invites_pkey PRIMARY KEY (id);


--
-- Name: wali_invites wali_invites_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wali_invites
    ADD CONSTRAINT wali_invites_token_key UNIQUE (token);


--
-- Name: wali_links wali_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wali_links
    ADD CONSTRAINT wali_links_pkey PRIMARY KEY (id);


--
-- Name: wali_links wali_links_seeker_id_wali_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wali_links
    ADD CONSTRAINT wali_links_seeker_id_wali_id_key UNIQUE (seeker_id, wali_id);


--
-- Name: wali_suggestions wali_suggestions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wali_suggestions
    ADD CONSTRAINT wali_suggestions_pkey PRIMARY KEY (id);


--
-- Name: wali_suggestions wali_suggestions_wali_id_seeker_id_suggested_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wali_suggestions
    ADD CONSTRAINT wali_suggestions_wali_id_seeker_id_suggested_id_key UNIQUE (wali_id, seeker_id, suggested_id);


--
-- Name: zyra_inactivity_notices zyra_inactivity_notices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zyra_inactivity_notices
    ADD CONSTRAINT zyra_inactivity_notices_pkey PRIMARY KEY (user_id);


--
-- Name: zyra_onboarding_questions zyra_seed_ch4_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zyra_onboarding_questions
    ADD CONSTRAINT zyra_seed_ch4_questions_pkey PRIMARY KEY (qid, gender_visibility);


--
-- Name: identity_verification_attempts_one_open_per_user; Type: INDEX; Schema: private; Owner: -
--

CREATE UNIQUE INDEX identity_verification_attempts_one_open_per_user ON private.identity_verification_attempts USING btree (user_id) WHERE ((member_deleted_at IS NULL) AND (result = ANY (ARRAY['pending'::text, 'retry_required'::text, 'review_required'::text])));


--
-- Name: identity_verification_attempts_one_verified_per_user; Type: INDEX; Schema: private; Owner: -
--

CREATE UNIQUE INDEX identity_verification_attempts_one_verified_per_user ON private.identity_verification_attempts USING btree (user_id) WHERE ((member_deleted_at IS NULL) AND (result = 'verified'::text));


--
-- Name: identity_verification_attempts_user_created; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX identity_verification_attempts_user_created ON private.identity_verification_attempts USING btree (user_id, created_at DESC);


--
-- Name: report_protected_attempts_attempt_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX report_protected_attempts_attempt_idx ON private.report_protected_attempts USING btree (attempt_id, report_id);


--
-- Name: safety_sealed_messages_circle_chat; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX safety_sealed_messages_circle_chat ON private.safety_sealed_messages USING btree (circle_chat_id) WHERE (circle_chat_id IS NOT NULL);


--
-- Name: safety_sealed_messages_purge_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX safety_sealed_messages_purge_idx ON private.safety_sealed_messages USING btree (purge_at);


--
-- Name: zyra_directional_results_subject_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_directional_results_subject_idx ON private.zyra_directional_results USING btree (subject);


--
-- Name: zyra_family_chat_report_attempts_attempt; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_family_chat_report_attempts_attempt ON private.zyra_family_chat_report_attempts USING btree (attempt_id);


--
-- Name: zyra_guardian_notification_actor_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_guardian_notification_actor_idx ON private.zyra_guardian_notification_sources USING btree (actor_id);


--
-- Name: zyra_guardian_notification_invite_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_guardian_notification_invite_idx ON private.zyra_guardian_notification_sources USING btree (invite_id);


--
-- Name: zyra_guardian_notification_link_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_guardian_notification_link_idx ON private.zyra_guardian_notification_sources USING btree (link_id);


--
-- Name: zyra_journey_reveal_tombstones_consent_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_journey_reveal_tombstones_consent_idx ON private.zyra_journey_reveal_tombstones USING btree (consent_for_attempt_id);


--
-- Name: zyra_journey_reveal_tombstones_match_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_journey_reveal_tombstones_match_idx ON private.zyra_journey_reveal_tombstones USING btree (match_id);


--
-- Name: zyra_personal_code_attempts_caller_time; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_personal_code_attempts_caller_time ON private.zyra_personal_code_attempts USING btree (caller_id, attempted_at DESC);


--
-- Name: zyra_product_events_feature_event_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_product_events_feature_event_idx ON private.zyra_product_events USING btree (feature_key, action_key, event_name, occurred_at DESC);


--
-- Name: zyra_product_events_occurred_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_product_events_occurred_idx ON private.zyra_product_events USING btree (occurred_at DESC);


--
-- Name: zyra_report_sealed_messages_seal_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX zyra_report_sealed_messages_seal_idx ON private.zyra_report_sealed_messages USING btree (sealed_message_id);


--
-- Name: app_feedback_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX app_feedback_created_idx ON public.app_feedback USING btree (created_at DESC);


--
-- Name: app_feedback_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX app_feedback_user_idx ON public.app_feedback USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: consents_user_type_recent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX consents_user_type_recent ON public.consents USING btree (user_id, consent_type, recorded_at DESC);


--
-- Name: conversations_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX conversations_attempt_idx ON public.conversations USING btree (attempt_id);


--
-- Name: family_invitation_one_pending_role; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX family_invitation_one_pending_role ON public.family_membership_invitations USING btree (family_subscription_id, invited_user_id, role) WHERE (status = 'pending'::text);


--
-- Name: family_message_chat_state_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_message_chat_state_user ON public.family_message_chat_state USING btree (user_id);


--
-- Name: family_message_chats_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_message_chats_attempt ON public.family_message_chats USING btree (attempt_id) WHERE (attempt_id IS NOT NULL);


--
-- Name: family_message_chats_one_main; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX family_message_chats_one_main ON public.family_message_chats USING btree (thread_id) WHERE (kind = 'main'::text);


--
-- Name: family_message_memberships_one_active_epoch; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX family_message_memberships_one_active_epoch ON public.family_message_memberships USING btree (thread_id, user_id) WHERE (left_at IS NULL);


--
-- Name: family_message_memberships_user_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_message_memberships_user_active ON public.family_message_memberships USING btree (user_id, thread_id) WHERE (left_at IS NULL);


--
-- Name: family_message_reports_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_message_reports_pending ON public.family_message_reports USING btree (created_at DESC);


--
-- Name: family_message_reports_sealed_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_message_reports_sealed_idx ON public.family_message_reports USING btree (sealed_message_id) WHERE (sealed_message_id IS NOT NULL);


--
-- Name: family_message_threads_recent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_message_threads_recent ON public.family_message_threads USING btree (last_message_at DESC NULLS LAST);


--
-- Name: family_messages_chat_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_messages_chat_created ON public.family_messages USING btree (chat_id, created_at DESC, id DESC);


--
-- Name: family_messages_sender_rate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_messages_sender_rate ON public.family_messages USING btree (sender_id, created_at DESC) WHERE (kind = 'message'::text);


--
-- Name: family_messages_thread_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_messages_thread_created ON public.family_messages USING btree (thread_id, created_at DESC, id DESC);


--
-- Name: family_seats_one_live_role_per_member; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX family_seats_one_live_role_per_member ON public.family_seat_assignments USING btree (member_id, role) WHERE (removed_at IS NULL);


--
-- Name: family_seats_subscription_live; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX family_seats_subscription_live ON public.family_seat_assignments USING btree (family_subscription_id, role) WHERE (removed_at IS NULL);


--
-- Name: journey_attempts_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_attempts_active ON public.journey_attempts USING btree (status) WHERE (status = 'active'::text);


--
-- Name: journey_attempts_ended_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_attempts_ended_by_idx ON public.journey_attempts USING btree (ended_by);


--
-- Name: journey_attempts_match; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_attempts_match ON public.journey_attempts USING btree (match_id);


--
-- Name: journey_attempts_one_active_per_match; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX journey_attempts_one_active_per_match ON public.journey_attempts USING btree (match_id) WHERE (status = 'active'::text);


--
-- Name: journey_attempts_paused_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_attempts_paused_by_idx ON public.journey_attempts USING btree (paused_by);


--
-- Name: journey_compatibility_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_compatibility_attempt_idx ON public.journey_compatibility USING btree (attempt_id);


--
-- Name: journey_family_answers_answerer_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_family_answers_answerer_idx ON public.journey_family_answers USING btree (answerer_id);


--
-- Name: journey_family_answers_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_family_answers_attempt_idx ON public.journey_family_answers USING btree (attempt_id);


--
-- Name: journey_family_review_responses_dashboard_updates_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_family_review_responses_dashboard_updates_idx ON public.journey_family_review_responses USING btree (review_id, responded_at DESC, wali_id);


--
-- Name: journey_family_review_responses_wali_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_family_review_responses_wali_idx ON public.journey_family_review_responses USING btree (wali_id);


--
-- Name: journey_family_reviews_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_family_reviews_attempt_idx ON public.journey_family_reviews USING btree (attempt_id);


--
-- Name: journey_family_reviews_dashboard_updates_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_family_reviews_dashboard_updates_idx ON public.journey_family_reviews USING btree (attempt_id, opened_at DESC, id DESC) WHERE (attempt_id IS NOT NULL);


--
-- Name: journey_family_reviews_one_pending_per_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX journey_family_reviews_one_pending_per_attempt ON public.journey_family_reviews USING btree (attempt_id) WHERE (status = 'pending'::text);


--
-- Name: journey_family_reviews_one_pending_per_match; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX journey_family_reviews_one_pending_per_match ON public.journey_family_reviews USING btree (match_id) WHERE (status = 'pending'::text);


--
-- Name: journey_guardian_assignments_link_history; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_guardian_assignments_link_history ON public.journey_guardian_assignments USING btree (wali_link_id, granted_at DESC);


--
-- Name: journey_guardian_assignments_one_live; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX journey_guardian_assignments_one_live ON public.journey_guardian_assignments USING btree (attempt_id, wali_link_id) WHERE (revoked_at IS NULL);


--
-- Name: journey_milestone_attestations_match_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_milestone_attestations_match_idx ON public.journey_milestone_attestations USING btree (match_id);


--
-- Name: journey_milestone_attestations_one_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX journey_milestone_attestations_one_pending ON public.journey_milestone_attestations USING btree (attempt_id, milestone_type) WHERE (status = 'pending'::text);


--
-- Name: journey_phase_answers_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_phase_answers_attempt_idx ON public.journey_phase_answers USING btree (attempt_id);


--
-- Name: journey_phase_answers_seeker_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_phase_answers_seeker_idx ON public.journey_phase_answers USING btree (seeker_id);


--
-- Name: journey_phase_checkpoints_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_phase_checkpoints_attempt_idx ON public.journey_phase_checkpoints USING btree (attempt_id);


--
-- Name: journey_phase_checkpoints_seeker_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_phase_checkpoints_seeker_idx ON public.journey_phase_checkpoints USING btree (seeker_id);


--
-- Name: journey_phase_ratings_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_phase_ratings_attempt_idx ON public.journey_phase_ratings USING btree (attempt_id);


--
-- Name: journey_phase_ratings_rater_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_phase_ratings_rater_idx ON public.journey_phase_ratings USING btree (rater_id);


--
-- Name: journey_requests_expiry_sweep_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_requests_expiry_sweep_idx ON public.journey_requests USING btree (expires_at) WHERE (status = 'pending'::text);


--
-- Name: journey_requests_one_pending_per_pair; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX journey_requests_one_pending_per_pair ON public.journey_requests USING btree (match_id) WHERE (status = 'pending'::text);


--
-- Name: journey_requests_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_requests_recipient_idx ON public.journey_requests USING btree (requested_to) WHERE (status = 'pending'::text);


--
-- Name: journey_salams_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_salams_attempt_idx ON public.journey_salams USING btree (attempt_id);


--
-- Name: journey_salams_seeker_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_salams_seeker_idx ON public.journey_salams USING btree (seeker_id);


--
-- Name: journey_stage_checkpoints_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_stage_checkpoints_attempt_idx ON public.journey_stage_checkpoints USING btree (attempt_id);


--
-- Name: journey_stage_checkpoints_seeker_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journey_stage_checkpoints_seeker_idx ON public.journey_stage_checkpoints USING btree (seeker_id);


--
-- Name: likes_liked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX likes_liked ON public.likes USING btree (liked_id, created_at DESC);


--
-- Name: likes_liker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX likes_liker ON public.likes USING btree (liker_id, created_at DESC);


--
-- Name: matches_ended_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX matches_ended_by_idx ON public.matches USING btree (ended_by);


--
-- Name: matches_seeker_a_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX matches_seeker_a_active ON public.matches USING btree (seeker_a_id) WHERE ((status = 'active'::text) AND (suspended_by IS NULL));


--
-- Name: matches_seeker_b_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX matches_seeker_b_active ON public.matches USING btree (seeker_b_id) WHERE ((status = 'active'::text) AND (suspended_by IS NULL));


--
-- Name: matches_suspended_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX matches_suspended_by_idx ON public.matches USING btree (suspended_by);


--
-- Name: messages_conversation_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_conversation_created ON public.messages USING btree (conversation_id, created_at DESC);


--
-- Name: messages_sender_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_sender_idx ON public.messages USING btree (sender_id);


--
-- Name: notification_preferences_current; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_preferences_current ON public.notification_preferences USING btree (user_id, category, seq DESC);


--
-- Name: notifications_dashboard_updates_unread_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_dashboard_updates_unread_idx ON public.notifications USING btree (user_id, created_at DESC, id DESC) WHERE (read_at IS NULL);


--
-- Name: notifications_related_chat; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_related_chat ON public.notifications USING btree (related_chat_id) WHERE (related_chat_id IS NOT NULL);


--
-- Name: notifications_related_match_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_related_match_idx ON public.notifications USING btree (related_match_id);


--
-- Name: notifications_unread_circle_chat; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX notifications_unread_circle_chat ON public.notifications USING btree (user_id, related_chat_id) WHERE ((type = 'circle_message'::text) AND (read_at IS NULL));


--
-- Name: notifications_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_user_created ON public.notifications USING btree (user_id, created_at DESC);


--
-- Name: passes_passed_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX passes_passed_idx ON public.passes USING btree (passed_id);


--
-- Name: passes_passer_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX passes_passer_idx ON public.passes USING btree (passer_id);


--
-- Name: photo_object_deletions_pending_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX photo_object_deletions_pending_idx ON public.photo_object_deletions USING btree (account_delete_due_at, attempts, bucket, path) WHERE ((done_at IS NULL) AND (attempts < 10));


--
-- Name: photo_object_deletions_pending_owner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX photo_object_deletions_pending_owner_idx ON public.photo_object_deletions USING btree (split_part(path, '/'::text, 1)) WHERE (done_at IS NULL);


--
-- Name: profile_blocks_blocked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_blocks_blocked ON public.profile_blocks USING btree (blocked_id, blocker_id);


--
-- Name: profile_blocks_blocker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_blocks_blocker ON public.profile_blocks USING btree (blocker_id, blocked_id);


--
-- Name: profile_hides_hidden; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_hides_hidden ON public.profile_hides USING btree (hidden, hider);


--
-- Name: profile_photos_live_source_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_photos_live_source_idx ON public.profile_photos USING btree (source_path) WHERE ((removed_at IS NULL) AND (source_path IS NOT NULL));


--
-- Name: profile_photos_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX profile_photos_primary ON public.profile_photos USING btree (user_id) WHERE (is_primary = true);


--
-- Name: profile_photos_storage_path_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_photos_storage_path_idx ON public.profile_photos USING btree (storage_path);


--
-- Name: profile_reports_open_legacy_pair_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_reports_open_legacy_pair_idx ON public.profile_reports USING btree (LEAST(reporter_id, reported_id), GREATEST(reporter_id, reported_id)) WHERE ((status = ANY (ARRAY['pending'::text, 'reviewing'::text])) AND (attempt_id IS NULL));


--
-- Name: profile_reports_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_reports_pending ON public.profile_reports USING btree (created_at DESC) WHERE (status = 'pending'::text);


--
-- Name: profile_reports_reported; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_reports_reported ON public.profile_reports USING btree (reported_id, created_at DESC);


--
-- Name: profile_reports_reporter_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_reports_reporter_idx ON public.profile_reports USING btree (reporter_id);


--
-- Name: profile_unlocks_by_unlocker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_unlocks_by_unlocker ON public.profile_unlocks USING btree (unlocker_id);


--
-- Name: profile_unlocks_once; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX profile_unlocks_once ON public.profile_unlocks USING btree (unlocker_id, unlocked_id, unlock_type);


--
-- Name: profile_unlocks_unlocked_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_unlocks_unlocked_idx ON public.profile_unlocks USING btree (unlocked_id);


--
-- Name: profile_videos_latest_by_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_videos_latest_by_user ON public.profile_videos USING btree (user_id, created_at DESC, id DESC);


--
-- Name: profile_videos_one_current_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX profile_videos_one_current_per_user ON public.profile_videos USING btree (user_id) WHERE (status = ANY (ARRAY['pending'::text, 'approved'::text]));


--
-- Name: profiles_browse; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profiles_browse ON public.profiles USING btree (gender, is_active, profile_complete) WHERE ((is_active = true) AND (profile_complete = true));


--
-- Name: profiles_inactivity_anniversary_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profiles_inactivity_anniversary_idx ON public.profiles USING btree ((((last_active_at AT TIME ZONE 'UTC'::text) + '2 years'::interval) AT TIME ZONE 'UTC'::text));


--
-- Name: protection_holds_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX protection_holds_active_idx ON public.protection_holds USING btree (restricted_id, protected_id) WHERE (released_at IS NULL);


--
-- Name: protection_holds_match_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX protection_holds_match_idx ON public.protection_holds USING btree (match_id);


--
-- Name: saves_mutual; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX saves_mutual ON public.saves USING btree (saved_id, saver_id);


--
-- Name: seeker_details_ethnicity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX seeker_details_ethnicity ON public.seeker_details USING btree (ethnicity);


--
-- Name: seeker_details_languages; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX seeker_details_languages ON public.seeker_details USING gin (languages);


--
-- Name: seeker_details_sect; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX seeker_details_sect ON public.seeker_details USING btree (sect);


--
-- Name: subscriptions_active_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX subscriptions_active_user ON public.subscriptions USING btree (user_id) WHERE (status = 'active'::text);


--
-- Name: subscriptions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_user ON public.subscriptions USING btree (user_id) WHERE (status = 'active'::text);


--
-- Name: timeline_milestones_dashboard_updates_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX timeline_milestones_dashboard_updates_idx ON public.timeline_milestones USING btree (timeline_id, occurred_at DESC, id DESC);


--
-- Name: timeline_milestones_timeline_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX timeline_milestones_timeline_idx ON public.timeline_milestones USING btree (timeline_id);


--
-- Name: timelines_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX timelines_attempt_idx ON public.timelines USING btree (attempt_id);


--
-- Name: unlock_credits_balance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX unlock_credits_balance ON public.unlock_credits USING btree (user_id, tier);


--
-- Name: unlock_credits_one_zyra_one_grant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unlock_credits_one_zyra_one_grant ON public.unlock_credits USING btree (user_id, tier) WHERE (reason = 'zyra_one_included'::text);


--
-- Name: unlock_credits_related_unlock_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX unlock_credits_related_unlock_idx ON public.unlock_credits USING btree (related_unlock_id);


--
-- Name: wali_invites_accepted_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_invites_accepted_by_idx ON public.wali_invites USING btree (accepted_by);


--
-- Name: wali_invites_inviter_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_invites_inviter_idx ON public.wali_invites USING btree (inviter_id);


--
-- Name: wali_invites_one_pending_personal_request; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX wali_invites_one_pending_personal_request ON public.wali_invites USING btree (personal_code_id, recipient_id) WHERE ((source = 'personal_code'::text) AND (status = 'pending'::text));


--
-- Name: wali_invites_personal_incoming; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_invites_personal_incoming ON public.wali_invites USING btree (inviter_id, status, created_at DESC) WHERE (source = 'personal_code'::text);


--
-- Name: wali_invites_personal_outgoing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_invites_personal_outgoing ON public.wali_invites USING btree (recipient_id, status, created_at DESC) WHERE (source = 'personal_code'::text);


--
-- Name: wali_links_invitation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_links_invitation_id ON public.wali_links USING btree (invitation_id) WHERE (invitation_id IS NOT NULL);


--
-- Name: wali_links_one_main_per_seeker; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX wali_links_one_main_per_seeker ON public.wali_links USING btree (seeker_id) WHERE ((is_main = true) AND (status = 'active'::text));


--
-- Name: wali_links_seeker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_links_seeker ON public.wali_links USING btree (seeker_id) WHERE (status = 'active'::text);


--
-- Name: wali_links_wali; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_links_wali ON public.wali_links USING btree (wali_id) WHERE (status = 'active'::text);


--
-- Name: wali_suggestions_dashboard_updates_seeker_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_suggestions_dashboard_updates_seeker_idx ON public.wali_suggestions USING btree (seeker_id, created_at DESC, id DESC);


--
-- Name: wali_suggestions_seeker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_suggestions_seeker ON public.wali_suggestions USING btree (seeker_id, status);


--
-- Name: wali_suggestions_suggested_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_suggestions_suggested_idx ON public.wali_suggestions USING btree (suggested_id);


--
-- Name: wali_suggestions_unseen; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wali_suggestions_unseen ON public.wali_suggestions USING btree (seeker_id) WHERE ((seen_at IS NULL) AND (status = 'pending'::text));


--
-- Name: guardian_trial_ledger guardian_trial_clear_deleted_account; Type: TRIGGER; Schema: private; Owner: -
--

CREATE TRIGGER guardian_trial_clear_deleted_account BEFORE UPDATE OF claimed_by ON private.guardian_trial_ledger FOR EACH ROW EXECUTE FUNCTION private.zyra_clear_deleted_guardian_trial();


--
-- Name: identity_verification_attempts identity_verification_attempts_updated_at; Type: TRIGGER; Schema: private; Owner: -
--

CREATE TRIGGER identity_verification_attempts_updated_at BEFORE UPDATE ON private.identity_verification_attempts FOR EACH ROW EXECUTE FUNCTION private.zyra_touch_identity_verification_attempt();


--
-- Name: zyra_personal_codes zyra_retire_personal_code_before_change; Type: TRIGGER; Schema: private; Owner: -
--

CREATE TRIGGER zyra_retire_personal_code_before_change BEFORE DELETE OR UPDATE OF code ON private.zyra_personal_codes FOR EACH ROW EXECUTE FUNCTION private.zyra_retire_personal_code();


--
-- Name: conversations conversations_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER conversations_set_attempt BEFORE INSERT ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: journey_attempts family_message_chats_create_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER family_message_chats_create_attempt AFTER INSERT OR UPDATE OF status, started_at ON public.journey_attempts FOR EACH ROW EXECUTE FUNCTION private.zyra_family_chat_create_for_attempt();


--
-- Name: family_message_threads family_message_chats_create_thread; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER family_message_chats_create_thread AFTER INSERT ON public.family_message_threads FOR EACH ROW EXECUTE FUNCTION private.zyra_family_chat_create_for_thread();


--
-- Name: family_message_reports family_message_report_capture_evidence; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER family_message_report_capture_evidence AFTER INSERT ON public.family_message_reports FOR EACH ROW EXECUTE FUNCTION public.zyra_capture_family_message_report_evidence();


--
-- Name: family_messages family_messages_default_main; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER family_messages_default_main BEFORE INSERT ON public.family_messages FOR EACH ROW EXECUTE FUNCTION private.zyra_family_message_default_main();


--
-- Name: family_subscriptions family_owner_row_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER family_owner_row_guard AFTER INSERT OR UPDATE OF owner_id, owner_role, seeker_places, guardian_places ON public.family_subscriptions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.zyra_family_owner_row_guard();


--
-- Name: family_seat_assignments family_owner_seat_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER family_owner_seat_guard AFTER INSERT OR DELETE OR UPDATE ON public.family_seat_assignments DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.zyra_family_owner_seat_guard();


--
-- Name: family_ownership_transfers family_ownership_transfer_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER family_ownership_transfer_guard BEFORE INSERT OR UPDATE ON public.family_ownership_transfers FOR EACH ROW EXECUTE FUNCTION public.zyra_validate_family_ownership_transfer();


--
-- Name: family_subscriptions family_place_reduction_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER family_place_reduction_guard BEFORE UPDATE OF seeker_places, guardian_places ON public.family_subscriptions FOR EACH ROW EXECUTE FUNCTION public.zyra_guard_family_place_reduction();


--
-- Name: family_seat_assignments family_seat_capacity_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER family_seat_capacity_guard AFTER INSERT OR DELETE OR UPDATE ON public.family_seat_assignments DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_family_seat_capacity();


--
-- Name: family_seat_assignments family_seat_forfeits_seeker_trial; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER family_seat_forfeits_seeker_trial AFTER INSERT OR UPDATE ON public.family_seat_assignments FOR EACH ROW EXECUTE FUNCTION public.zyra_forfeit_seeker_trial_on_family_seat();


--
-- Name: family_seat_assignments family_seat_verified_role_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER family_seat_verified_role_guard BEFORE INSERT OR UPDATE OF member_id, role ON public.family_seat_assignments FOR EACH ROW EXECUTE FUNCTION public.zyra_require_verified_family_seat();


--
-- Name: journey_attempts journey_attempts_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_attempts_main_guardian_hold BEFORE UPDATE ON public.journey_attempts FOR EACH ROW WHEN (((new.status = 'active'::text) AND ((old.journey_stage IS DISTINCT FROM new.journey_stage) OR (old.status IS DISTINCT FROM new.status)))) EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_attempts journey_attempts_one_active_per_person; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER journey_attempts_one_active_per_person AFTER INSERT OR UPDATE OF status, paused_by ON public.journey_attempts NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_one_active_attempt();


--
-- Name: journey_compatibility journey_compatibility_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_compatibility_main_guardian_hold BEFORE UPDATE ON public.journey_compatibility FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_compatibility journey_compatibility_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_compatibility_set_attempt BEFORE INSERT ON public.journey_compatibility FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: journey_family_answers journey_family_answers_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_family_answers_main_guardian_hold BEFORE INSERT OR UPDATE ON public.journey_family_answers FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_family_answers journey_family_answers_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_family_answers_set_attempt BEFORE INSERT ON public.journey_family_answers FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: journey_family_reviews journey_family_reviews_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_family_reviews_main_guardian_hold BEFORE INSERT OR UPDATE ON public.journey_family_reviews FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_family_reviews journey_family_reviews_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_family_reviews_set_attempt BEFORE INSERT ON public.journey_family_reviews FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: journey_phase_answers journey_phase_answers_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_phase_answers_main_guardian_hold BEFORE INSERT OR UPDATE ON public.journey_phase_answers FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_phase_answers journey_phase_answers_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_phase_answers_set_attempt BEFORE INSERT ON public.journey_phase_answers FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: journey_phase_checkpoints journey_phase_checkpoints_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_phase_checkpoints_main_guardian_hold BEFORE INSERT OR UPDATE ON public.journey_phase_checkpoints FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_phase_checkpoints journey_phase_checkpoints_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_phase_checkpoints_set_attempt BEFORE INSERT ON public.journey_phase_checkpoints FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: journey_phase_ratings journey_phase_ratings_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_phase_ratings_main_guardian_hold BEFORE INSERT OR UPDATE ON public.journey_phase_ratings FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_phase_ratings journey_phase_ratings_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_phase_ratings_set_attempt BEFORE INSERT ON public.journey_phase_ratings FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: journey_requests journey_requests_ended_restart_gate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_requests_ended_restart_gate BEFORE INSERT ON public.journey_requests FOR EACH ROW WHEN ((new.status = 'pending'::text)) EXECUTE FUNCTION public.zyra_guard_ended_restart_initiation();


--
-- Name: journey_salams journey_salams_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_salams_main_guardian_hold BEFORE INSERT OR UPDATE ON public.journey_salams FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_salams journey_salams_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_salams_set_attempt BEFORE INSERT ON public.journey_salams FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: journey_stage_checkpoints journey_stage_checkpoints_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_stage_checkpoints_main_guardian_hold BEFORE INSERT OR UPDATE ON public.journey_stage_checkpoints FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: journey_stage_checkpoints journey_stage_checkpoints_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journey_stage_checkpoints_set_attempt BEFORE INSERT ON public.journey_stage_checkpoints FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: likes likes_clear_others; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER likes_clear_others AFTER INSERT ON public.likes FOR EACH ROW EXECUTE FUNCTION public.zyra_like_clears_others();


--
-- Name: likes likes_create_match; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER likes_create_match AFTER INSERT ON public.likes FOR EACH ROW EXECUTE FUNCTION public.create_match_on_mutual_like();


--
-- Name: matches matches_create_first_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER matches_create_first_attempt AFTER INSERT ON public.matches FOR EACH ROW EXECUTE FUNCTION public.zyra_create_first_attempt();


--
-- Name: matches matches_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER matches_main_guardian_hold BEFORE UPDATE ON public.matches FOR EACH ROW WHEN (((new.status = 'active'::text) AND ((old.journey_stage IS DISTINCT FROM new.journey_stage) OR (old.status IS DISTINCT FROM new.status)))) EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: matches matches_one_active_per_person; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER matches_one_active_per_person AFTER INSERT OR UPDATE OF status, suspended_by ON public.matches NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_one_active_match();


--
-- Name: matches matches_record_journey_milestone; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER matches_record_journey_milestone AFTER UPDATE ON public.matches FOR EACH ROW EXECUTE FUNCTION public.zyra_record_journey_milestone();


--
-- Name: messages messages_create_conversation_started_milestone; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_create_conversation_started_milestone AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.create_conversation_started_milestone();


--
-- Name: messages messages_lock_match; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_lock_match BEFORE INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION private.zyra_lock_message_match();


--
-- Name: messages messages_main_guardian_hold; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_main_guardian_hold BEFORE INSERT OR UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_main_guardian_journey_hold();


--
-- Name: messages messages_notify_recipient; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_notify_recipient AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();


--
-- Name: onboarding_answers onboarding_answers_refresh_complete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER onboarding_answers_refresh_complete AFTER INSERT OR DELETE OR UPDATE ON public.onboarding_answers FOR EACH ROW EXECUTE FUNCTION public.zyra_answers_refresh_onboarding_complete();


--
-- Name: onboarding_answers onboarding_answers_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER onboarding_answers_updated_at BEFORE UPDATE ON public.onboarding_answers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: passes passes_clear_others; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER passes_clear_others AFTER INSERT ON public.passes FOR EACH ROW EXECUTE FUNCTION public.zyra_pass_clears_others();


--
-- Name: profile_blocks profile_blocks_family_message_lifecycle; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profile_blocks_family_message_lifecycle AFTER INSERT OR DELETE ON public.profile_blocks FOR EACH ROW EXECUTE FUNCTION public.zyra_sync_family_message_block_lifecycle();


--
-- Name: profiles profiles_normalise_identity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profiles_normalise_identity BEFORE INSERT OR UPDATE OF first_name ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.zyra_normalise_profile_identity();


--
-- Name: profiles profiles_remove_departing_profile; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profiles_remove_departing_profile BEFORE DELETE ON public.profiles FOR EACH ROW EXECUTE FUNCTION private.zyra_remove_departing_profile();


--
-- Name: profiles profiles_set_onboarding_complete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profiles_set_onboarding_complete BEFORE INSERT OR UPDATE OF profile_complete, gender, role ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.zyra_profiles_set_onboarding_complete();


--
-- Name: profiles profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: profiles profiles_validate_name_lengths; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profiles_validate_name_lengths BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.zyra_validate_profile_name_lengths();


--
-- Name: saves saves_clear_others; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER saves_clear_others AFTER INSERT ON public.saves FOR EACH ROW EXECUTE FUNCTION public.zyra_save_clears_others();


--
-- Name: seeker_details seeker_details_refresh_complete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER seeker_details_refresh_complete AFTER INSERT OR DELETE OR UPDATE ON public.seeker_details FOR EACH ROW EXECUTE FUNCTION public.zyra_answers_refresh_onboarding_complete();


--
-- Name: seeker_details seeker_details_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER seeker_details_touch BEFORE UPDATE ON public.seeker_details FOR EACH ROW EXECUTE FUNCTION public.touch_seeker_details();


--
-- Name: subscriptions subscriptions_grant_zyra_one_credits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER subscriptions_grant_zyra_one_credits AFTER INSERT OR UPDATE OF plan_type, status ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.grant_zyra_one_credits();


--
-- Name: timelines timelines_set_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER timelines_set_attempt BEFORE INSERT ON public.timelines FOR EACH ROW EXECUTE FUNCTION public.zyra_set_attempt_from_match();


--
-- Name: wali_invites wali_invites_personal_request_owner_acceptance; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER wali_invites_personal_request_owner_acceptance BEFORE UPDATE OF status ON public.wali_invites FOR EACH ROW EXECUTE FUNCTION private.zyra_enforce_personal_request_owner_acceptance();


--
-- Name: wali_links wali_links_auto_main; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER wali_links_auto_main BEFORE INSERT OR UPDATE ON public.wali_links FOR EACH ROW EXECUTE FUNCTION public.auto_designate_main_wali();


--
-- Name: wali_links wali_links_family_message_lifecycle; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER wali_links_family_message_lifecycle AFTER INSERT OR DELETE OR UPDATE OF status ON public.wali_links FOR EACH ROW EXECUTE FUNCTION public.zyra_sync_family_message_link_lifecycle();


--
-- Name: onboarding_answers zyra_compatibility_capture_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_compatibility_capture_version BEFORE INSERT OR UPDATE ON public.onboarding_answers FOR EACH ROW EXECUTE FUNCTION private.zyra_version_compatibility_capture();


--
-- Name: seeker_details zyra_compatibility_capture_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_compatibility_capture_version BEFORE INSERT OR UPDATE ON public.seeker_details FOR EACH ROW EXECUTE FUNCTION private.zyra_version_compatibility_capture();


--
-- Name: profile_photos zyra_guard_legacy_photo_row_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_guard_legacy_photo_row_write BEFORE DELETE OR UPDATE OF storage_path ON public.profile_photos FOR EACH ROW EXECUTE FUNCTION private.zyra_guard_legacy_photo_row_write();


--
-- Name: seeker_details zyra_invalidate_ch2_preference_light_confirmations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_invalidate_ch2_preference_light_confirmations AFTER DELETE OR UPDATE ON public.seeker_details FOR EACH ROW EXECUTE FUNCTION private.zyra_invalidate_preference_light_confirmations('2', 'preferences');


--
-- Name: onboarding_answers zyra_invalidate_ch4_preference_light_confirmations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_invalidate_ch4_preference_light_confirmations AFTER DELETE OR UPDATE ON public.onboarding_answers FOR EACH ROW EXECUTE FUNCTION private.zyra_invalidate_preference_light_confirmations('4', 'ch4_preferences');


--
-- Name: seeker_details zyra_keep_red_ch2_hard_requirements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_keep_red_ch2_hard_requirements BEFORE INSERT OR UPDATE ON public.seeker_details FOR EACH ROW EXECUTE FUNCTION private.zyra_keep_red_ch2_hard_requirements();


--
-- Name: onboarding_answers zyra_keep_red_ch4_hard_requirements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_keep_red_ch4_hard_requirements BEFORE INSERT OR UPDATE ON public.onboarding_answers FOR EACH ROW EXECUTE FUNCTION private.zyra_keep_red_ch4_hard_requirements();


--
-- Name: profile_reports zyra_link_report_attempts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_link_report_attempts AFTER INSERT OR UPDATE OF status ON public.profile_reports FOR EACH ROW EXECUTE FUNCTION private.zyra_link_report_attempts();


--
-- Name: profile_photos zyra_lock_member_photo_statement; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_lock_member_photo_statement BEFORE INSERT OR DELETE OR UPDATE ON public.profile_photos FOR EACH STATEMENT EXECUTE FUNCTION private.zyra_lock_member_photo_statement();


--
-- Name: profile_photos zyra_photo_row_owner; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_photo_row_owner BEFORE INSERT OR UPDATE ON public.profile_photos FOR EACH ROW EXECUTE FUNCTION private.zyra_enforce_photo_row_owner();


--
-- Name: journey_attempts zyra_protect_new_report_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_protect_new_report_attempt AFTER INSERT ON public.journey_attempts FOR EACH ROW EXECUTE FUNCTION private.zyra_protect_new_report_attempt();


--
-- Name: profile_photos zyra_queue_deleted_photo_source; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_queue_deleted_photo_source AFTER DELETE ON public.profile_photos FOR EACH ROW WHEN ((old.source_path IS NOT NULL)) EXECUTE FUNCTION private.zyra_queue_deleted_photo_source();


--
-- Name: profile_reports zyra_resolve_report_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_resolve_report_attempt BEFORE INSERT ON public.profile_reports FOR EACH ROW EXECUTE FUNCTION private.zyra_resolve_report_attempt();


--
-- Name: unlock_credits zyra_unlock_credit_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_unlock_credit_guard BEFORE INSERT OR DELETE OR UPDATE ON public.unlock_credits FOR EACH ROW EXECUTE FUNCTION private.zyra_guard_unlock_credit();


--
-- Name: profile_unlocks zyra_unlock_row_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_unlock_row_guard BEFORE INSERT OR DELETE OR UPDATE ON public.profile_unlocks FOR EACH ROW EXECUTE FUNCTION private.zyra_guard_unlock_row();


--
-- Name: wali_links zyra_wali_links_guardian_link_allowed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zyra_wali_links_guardian_link_allowed BEFORE INSERT OR UPDATE OF seeker_id, wali_id, status ON public.wali_links FOR EACH ROW EXECUTE FUNCTION public.zyra_enforce_guardian_link_allowed();


--
-- Name: guardian_trial_ledger; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.guardian_trial_ledger ENABLE ROW LEVEL SECURITY;

--
-- Name: identity_verification_attempts; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.identity_verification_attempts ENABLE ROW LEVEL SECURITY;

--
-- Name: identity_verification_event_receipts; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.identity_verification_event_receipts ENABLE ROW LEVEL SECURITY;

--
-- Name: report_protected_attempts; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.report_protected_attempts ENABLE ROW LEVEL SECURITY;

--
-- Name: safety_sealed_messages; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.safety_sealed_messages ENABLE ROW LEVEL SECURITY;

--
-- Name: seeker_home_places; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.seeker_home_places ENABLE ROW LEVEL SECURITY;

--
-- Name: seeker_home_places seeker_home_places_insert_own; Type: POLICY; Schema: private; Owner: -
--

CREATE POLICY seeker_home_places_insert_own ON private.seeker_home_places FOR INSERT TO authenticated WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: seeker_home_places seeker_home_places_read_own; Type: POLICY; Schema: private; Owner: -
--

CREATE POLICY seeker_home_places_read_own ON private.seeker_home_places FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: seeker_home_places seeker_home_places_update_own; Type: POLICY; Schema: private; Owner: -
--

CREATE POLICY seeker_home_places_update_own ON private.seeker_home_places FOR UPDATE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: seeker_trial_ledger; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.seeker_trial_ledger ENABLE ROW LEVEL SECURITY;

--
-- Name: verified_people; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.verified_people ENABLE ROW LEVEL SECURITY;

--
-- Name: verified_person_accounts; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.verified_person_accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_account_deleted_matches; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_account_deleted_matches ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_circle_seal_protections; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_circle_seal_protections ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_compatibility_sect_repairs; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_compatibility_sect_repairs ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_deleted_attempt_evidence; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_deleted_attempt_evidence ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_directional_results; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_directional_results ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_ended_journey_removals; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_ended_journey_removals ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_family_chat_report_attempts; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_family_chat_report_attempts ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_guardian_invite_accept_guards; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_guardian_invite_accept_guards ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_guardian_notification_sources; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_guardian_notification_sources ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_journey_reveal_tombstones; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_journey_reveal_tombstones ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_personal_code_attempts; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_personal_code_attempts ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_personal_codes; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_personal_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_photo_cleanup_leases; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_photo_cleanup_leases ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_photo_folder_guard; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_photo_folder_guard ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_purged_ended_match_projections; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_purged_ended_match_projections ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_question_area; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_question_area ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_report_sealed_messages; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_report_sealed_messages ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_retired_personal_code_hashes; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_retired_personal_code_hashes ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_unlock_account_guards; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_unlock_account_guards ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_unlock_operations; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_unlock_operations ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_unlock_release_gate; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.zyra_unlock_release_gate ENABLE ROW LEVEL SECURITY;

--
-- Name: app_feedback; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.app_feedback ENABLE ROW LEVEL SECURITY;

--
-- Name: app_feedback app_feedback_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY app_feedback_select_own ON public.app_feedback FOR SELECT USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: consents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.consents ENABLE ROW LEVEL SECURITY;

--
-- Name: consents consents_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY consents_insert ON public.consents FOR INSERT WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: consents consents_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY consents_select ON public.consents FOR SELECT USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: conversations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

--
-- Name: conversations conversations_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY conversations_select ON public.conversations FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.attempt_id = conversations.attempt_id) AND ((r.role = 'seeker'::text) OR ((r.role = 'guardian'::text) AND (r.attempt_status = 'active'::text)))))));


--
-- Name: email_outbox; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.email_outbox ENABLE ROW LEVEL SECURITY;

--
-- Name: family_membership_invitations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_membership_invitations ENABLE ROW LEVEL SECURITY;

--
-- Name: family_message_chat_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_message_chat_state ENABLE ROW LEVEL SECURITY;

--
-- Name: family_message_chats; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_message_chats ENABLE ROW LEVEL SECURITY;

--
-- Name: family_message_memberships; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_message_memberships ENABLE ROW LEVEL SECURITY;

--
-- Name: family_message_participant_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_message_participant_state ENABLE ROW LEVEL SECURITY;

--
-- Name: family_message_participant_state family_message_participant_state_self_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY family_message_participant_state_self_read ON public.family_message_participant_state FOR SELECT TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) AND public.zyra_family_message_can_read(thread_id)));


--
-- Name: family_message_report_evidence; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_message_report_evidence ENABLE ROW LEVEL SECURITY;

--
-- Name: family_message_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_message_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: family_message_threads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_message_threads ENABLE ROW LEVEL SECURITY;

--
-- Name: family_message_threads family_message_threads_active_member_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY family_message_threads_active_member_read ON public.family_message_threads FOR SELECT TO authenticated USING (public.zyra_family_message_can_read(id));


--
-- Name: family_messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_messages ENABLE ROW LEVEL SECURITY;

--
-- Name: family_messages family_messages_active_epoch_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY family_messages_active_epoch_read ON public.family_messages FOR SELECT TO authenticated USING (private.zyra_family_chat_message_visible(chat_id, created_at));


--
-- Name: family_ownership_transfers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_ownership_transfers ENABLE ROW LEVEL SECURITY;

--
-- Name: family_seat_assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_seat_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: family_subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.family_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: guardian_journey_history_consents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.guardian_journey_history_consents ENABLE ROW LEVEL SECURITY;

--
-- Name: guardian_journey_permissions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.guardian_journey_permissions ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_inactivity_notices inactivity_notices_owner_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY inactivity_notices_owner_select ON public.zyra_inactivity_notices FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: journey_attempts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_attempts ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_compatibility; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_compatibility ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_family_answers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_family_answers ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_family_answers journey_family_answers_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_family_answers_read ON public.journey_family_answers FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.attempt_id = journey_family_answers.attempt_id) AND (r.role = ANY (ARRAY['seeker'::text, 'guardian'::text]))))));


--
-- Name: journey_family_answers journey_family_answers_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_family_answers_write ON public.journey_family_answers FOR INSERT WITH CHECK (((answerer_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation p
  WHERE ((p.attempt_id = journey_family_answers.attempt_id) AND (p.match_id = journey_family_answers.match_id))))));


--
-- Name: journey_family_review_responses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_family_review_responses ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_family_review_responses journey_family_review_responses_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_family_review_responses_read ON public.journey_family_review_responses FOR SELECT USING ((EXISTS ( SELECT 1
   FROM (public.journey_family_reviews rev
     JOIN public.zyra_my_attempt_participation r ON ((r.attempt_id = rev.attempt_id)))
  WHERE ((rev.id = journey_family_review_responses.review_id) AND ((r.role = 'seeker'::text) OR (r.is_main = true))))));


--
-- Name: journey_family_reviews; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_family_reviews ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_family_reviews journey_family_reviews_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_family_reviews_read ON public.journey_family_reviews FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.attempt_id = journey_family_reviews.attempt_id) AND ((r.role = 'seeker'::text) OR (r.is_main = true))))));


--
-- Name: journey_guardian_assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_guardian_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_milestone_attestations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_milestone_attestations ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_phase_answers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_phase_answers ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_phase_answers journey_phase_answers_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_phase_answers_read ON public.journey_phase_answers FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.attempt_id = journey_phase_answers.attempt_id) AND (r.role = 'seeker'::text)))));


--
-- Name: journey_phase_answers journey_phase_answers_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_phase_answers_write ON public.journey_phase_answers FOR INSERT WITH CHECK (((seeker_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.match_id = journey_phase_answers.match_id) AND (r.role = 'seeker'::text))))));


--
-- Name: journey_phase_checkpoints; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_phase_checkpoints ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_phase_checkpoints journey_phase_checkpoints_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_phase_checkpoints_read ON public.journey_phase_checkpoints FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.attempt_id = journey_phase_checkpoints.attempt_id) AND (r.role = 'seeker'::text)))));


--
-- Name: journey_phase_checkpoints journey_phase_checkpoints_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_phase_checkpoints_write ON public.journey_phase_checkpoints FOR INSERT WITH CHECK (((seeker_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.match_id = journey_phase_checkpoints.match_id) AND (r.role = 'seeker'::text))))));


--
-- Name: journey_phase_ratings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_phase_ratings ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_phase_ratings journey_phase_ratings_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_phase_ratings_own ON public.journey_phase_ratings USING ((rater_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((rater_id = ( SELECT auth.uid() AS uid)));


--
-- Name: journey_requests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_requests journey_requests_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_requests_select ON public.journey_requests FOR SELECT TO authenticated USING (((requested_by = ( SELECT auth.uid() AS uid)) OR (requested_to = ( SELECT auth.uid() AS uid))));


--
-- Name: journey_salams; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_salams ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_salams journey_salams_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_salams_read ON public.journey_salams FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.attempt_id = journey_salams.attempt_id) AND (r.role = 'seeker'::text)))));


--
-- Name: journey_salams journey_salams_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_salams_write ON public.journey_salams FOR INSERT WITH CHECK (((seeker_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.match_id = journey_salams.match_id) AND (r.role = 'seeker'::text))))));


--
-- Name: journey_stage_checkpoints; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journey_stage_checkpoints ENABLE ROW LEVEL SECURITY;

--
-- Name: journey_stage_checkpoints journey_stage_checkpoints_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journey_stage_checkpoints_read ON public.journey_stage_checkpoints FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.attempt_id = journey_stage_checkpoints.attempt_id) AND (r.role = 'seeker'::text)))));


--
-- Name: likes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

--
-- Name: likes likes_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY likes_delete ON public.likes FOR DELETE USING ((liker_id = ( SELECT auth.uid() AS uid)));


--
-- Name: likes likes_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY likes_insert ON public.likes FOR INSERT WITH CHECK (((liker_id = ( SELECT auth.uid() AS uid)) AND public.zyra_can_match(liker_id, liked_id)));


--
-- Name: likes likes_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY likes_select ON public.likes FOR SELECT USING (((liker_id = ( SELECT auth.uid() AS uid)) OR (liked_id = ( SELECT auth.uid() AS uid))));


--
-- Name: profile_reports line94_detached_profile_report_visibility; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY line94_detached_profile_report_visibility ON public.profile_reports AS RESTRICTIVE FOR SELECT TO authenticated USING (((reporter_id IS NOT NULL) AND (reported_id IS NOT NULL)));


--
-- Name: journey_phase_ratings line94_phase_ratings_archive_visibility; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY line94_phase_ratings_archive_visibility ON public.journey_phase_ratings AS RESTRICTIVE TO authenticated USING ((((attempt_id IS NULL) AND (EXISTS ( SELECT 1
   FROM public.matches m
  WHERE (m.id = journey_phase_ratings.match_id)))) OR (EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation p
  WHERE ((p.attempt_id = journey_phase_ratings.attempt_id) AND (p.role = 'seeker'::text))))));


--
-- Name: matches; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

--
-- Name: matches matches_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY matches_select ON public.matches FOR SELECT USING (((seeker_a_id IS NOT NULL) AND (seeker_b_id IS NOT NULL) AND (((status = 'ended'::text) AND public.zyra_can_read_ended_match(id)) OR ((status <> 'ended'::text) AND ((seeker_a_id = ( SELECT auth.uid() AS uid)) OR (seeker_b_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.match_id = matches.id) AND (r.role = 'guardian'::text) AND (r.attempt_status = 'active'::text)))))))));


--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: messages messages_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_insert ON public.messages FOR INSERT TO authenticated WITH CHECK (((sender_id = ( SELECT auth.uid() AS uid)) AND public.zyra_may_send_journey_message(conversation_id)));


--
-- Name: messages messages_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_select ON public.messages FOR SELECT USING ((EXISTS ( SELECT 1
   FROM (public.conversations c
     JOIN public.zyra_my_attempt_participation r ON ((r.attempt_id = c.attempt_id)))
  WHERE ((c.id = messages.conversation_id) AND ((r.role = 'seeker'::text) OR ((r.role = 'guardian'::text) AND (r.attempt_status = 'active'::text)))))));


--
-- Name: notification_preferences; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_preferences notification_preferences_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notification_preferences_select ON public.notification_preferences FOR SELECT USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications notifications_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notifications_select ON public.notifications FOR SELECT USING (((user_id = ( SELECT auth.uid() AS uid)) AND ((related_chat_id IS NULL) OR private.zyra_family_chat_message_visible(related_chat_id, created_at))));


--
-- Name: notifications notifications_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notifications_update ON public.notifications FOR UPDATE USING (((user_id = ( SELECT auth.uid() AS uid)) AND (type <> 'circle_message'::text))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (type <> 'circle_message'::text)));


--
-- Name: onboarding_answers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.onboarding_answers ENABLE ROW LEVEL SECURITY;

--
-- Name: onboarding_answers onboarding_answers_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY onboarding_answers_insert ON public.onboarding_answers FOR INSERT WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: onboarding_answers onboarding_answers_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY onboarding_answers_select ON public.onboarding_answers FOR SELECT USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: onboarding_answers onboarding_answers_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY onboarding_answers_update ON public.onboarding_answers FOR UPDATE USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: passes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.passes ENABLE ROW LEVEL SECURITY;

--
-- Name: passes passes_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY passes_delete ON public.passes FOR DELETE TO authenticated USING ((passer_id = ( SELECT auth.uid() AS uid)));


--
-- Name: passes passes_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY passes_insert ON public.passes FOR INSERT WITH CHECK (((passer_id = ( SELECT auth.uid() AS uid)) AND public.zyra_can_match(passer_id, passed_id)));


--
-- Name: passes passes_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY passes_select ON public.passes FOR SELECT TO authenticated USING ((passer_id = ( SELECT auth.uid() AS uid)));


--
-- Name: photo_object_deletions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.photo_object_deletions ENABLE ROW LEVEL SECURITY;

--
-- Name: preference_light_confirmations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.preference_light_confirmations ENABLE ROW LEVEL SECURITY;

--
-- Name: preference_light_confirmations preference_light_confirmations_read_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY preference_light_confirmations_read_own ON public.preference_light_confirmations FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: profile_blocks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profile_blocks ENABLE ROW LEVEL SECURITY;

--
-- Name: profile_blocks profile_blocks_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_blocks_delete ON public.profile_blocks FOR DELETE USING ((blocker_id = ( SELECT auth.uid() AS uid)));


--
-- Name: profile_blocks profile_blocks_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_blocks_insert ON public.profile_blocks FOR INSERT WITH CHECK ((blocker_id = ( SELECT auth.uid() AS uid)));


--
-- Name: profile_blocks profile_blocks_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_blocks_select ON public.profile_blocks FOR SELECT USING ((blocker_id = ( SELECT auth.uid() AS uid)));


--
-- Name: profile_hides; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profile_hides ENABLE ROW LEVEL SECURITY;

--
-- Name: profile_hides profile_hides_read_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_hides_read_own ON public.profile_hides FOR SELECT TO authenticated USING ((hider = ( SELECT auth.uid() AS uid)));


--
-- Name: profile_photos; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profile_photos ENABLE ROW LEVEL SECURITY;

--
-- Name: profile_photos profile_photos_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_photos_delete ON public.profile_photos FOR DELETE USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: profile_photos profile_photos_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_photos_insert ON public.profile_photos FOR INSERT TO authenticated WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND private.zyra_photo_reference_owned(user_id, storage_path)));


--
-- Name: profile_photos profile_photos_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_photos_select ON public.profile_photos FOR SELECT TO authenticated USING (((removed_at IS NULL) AND private.zyra_photo_reference_owned(user_id, storage_path) AND ((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = profile_photos.user_id) AND p.is_active AND p.profile_complete))))));


--
-- Name: profile_photos profile_photos_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_photos_update ON public.profile_photos FOR UPDATE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND private.zyra_photo_reference_owned(user_id, storage_path)));


--
-- Name: profile_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profile_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: profile_reports profile_reports_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_reports_insert ON public.profile_reports FOR INSERT WITH CHECK (((reporter_id = ( SELECT auth.uid() AS uid)) AND (reported_id IS NOT NULL)));


--
-- Name: profile_reports profile_reports_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_reports_select ON public.profile_reports FOR SELECT USING ((reporter_id = ( SELECT auth.uid() AS uid)));


--
-- Name: profile_unlocks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profile_unlocks ENABLE ROW LEVEL SECURITY;

--
-- Name: profile_unlocks profile_unlocks_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_unlocks_select ON public.profile_unlocks FOR SELECT USING ((unlocker_id = ( SELECT auth.uid() AS uid)));


--
-- Name: profile_videos; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profile_videos ENABLE ROW LEVEL SECURITY;

--
-- Name: profile_videos profile_videos_read_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_videos_read_own ON public.profile_videos FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_select ON public.profiles FOR SELECT USING (public.zyra_can_view_profile(id));


--
-- Name: profiles profiles_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_update ON public.profiles FOR UPDATE USING ((id = ( SELECT auth.uid() AS uid)));


--
-- Name: protection_holds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.protection_holds ENABLE ROW LEVEL SECURITY;

--
-- Name: saves; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.saves ENABLE ROW LEVEL SECURITY;

--
-- Name: saves saves_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY saves_delete ON public.saves FOR DELETE USING ((saver_id = ( SELECT auth.uid() AS uid)));


--
-- Name: saves saves_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY saves_insert ON public.saves FOR INSERT WITH CHECK (((saver_id = ( SELECT auth.uid() AS uid)) AND public.zyra_can_match(saver_id, saved_id)));


--
-- Name: saves saves_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY saves_select ON public.saves FOR SELECT USING ((saver_id = ( SELECT auth.uid() AS uid)));


--
-- Name: seeker_details; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.seeker_details ENABLE ROW LEVEL SECURITY;

--
-- Name: seeker_details seeker_details_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY seeker_details_insert_own ON public.seeker_details FOR INSERT WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: seeker_details seeker_details_select_guardian; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY seeker_details_select_guardian ON public.seeker_details FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.wali_links w
  WHERE ((w.seeker_id = seeker_details.user_id) AND (w.wali_id = ( SELECT auth.uid() AS uid)) AND (w.status = 'active'::text)))));


--
-- Name: seeker_details seeker_details_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY seeker_details_select_own ON public.seeker_details FOR SELECT USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: seeker_details seeker_details_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY seeker_details_update_own ON public.seeker_details FOR UPDATE USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: subscriptions subscriptions_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY subscriptions_select ON public.subscriptions FOR SELECT USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: timeline_milestones; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.timeline_milestones ENABLE ROW LEVEL SECURITY;

--
-- Name: timeline_milestones timeline_milestones_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY timeline_milestones_select ON public.timeline_milestones FOR SELECT USING ((EXISTS ( SELECT 1
   FROM (public.timelines t
     JOIN public.zyra_my_attempt_participation r ON ((r.attempt_id = t.attempt_id)))
  WHERE ((t.id = timeline_milestones.timeline_id) AND ((r.role = 'seeker'::text) OR ((r.role = 'guardian'::text) AND (r.attempt_status <> 'potential'::text)))))));


--
-- Name: timelines; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.timelines ENABLE ROW LEVEL SECURITY;

--
-- Name: timelines timelines_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY timelines_select ON public.timelines FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.zyra_my_attempt_participation r
  WHERE ((r.attempt_id = timelines.attempt_id) AND ((r.role = 'seeker'::text) OR ((r.role = 'guardian'::text) AND (r.attempt_status <> 'potential'::text)))))));


--
-- Name: unlock_credits; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.unlock_credits ENABLE ROW LEVEL SECURITY;

--
-- Name: unlock_credits unlock_credits_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY unlock_credits_select_own ON public.unlock_credits FOR SELECT USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wali_invites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.wali_invites ENABLE ROW LEVEL SECURITY;

--
-- Name: wali_invites wali_invites_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wali_invites_insert ON public.wali_invites FOR INSERT WITH CHECK ((inviter_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wali_invites wali_invites_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wali_invites_select ON public.wali_invites FOR SELECT USING ((inviter_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wali_links; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.wali_links ENABLE ROW LEVEL SECURITY;

--
-- Name: wali_links wali_links_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wali_links_insert ON public.wali_links FOR INSERT WITH CHECK ((seeker_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wali_links wali_links_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wali_links_select ON public.wali_links FOR SELECT USING (((seeker_id = ( SELECT auth.uid() AS uid)) OR (wali_id = ( SELECT auth.uid() AS uid))));


--
-- Name: wali_suggestions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.wali_suggestions ENABLE ROW LEVEL SECURITY;

--
-- Name: wali_suggestions wali_suggestions_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wali_suggestions_insert ON public.wali_suggestions FOR INSERT WITH CHECK (((wali_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.wali_links wl
  WHERE ((wl.wali_id = ( SELECT auth.uid() AS uid)) AND (wl.seeker_id = wali_suggestions.seeker_id) AND (wl.status = 'active'::text))))));


--
-- Name: wali_suggestions wali_suggestions_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wali_suggestions_select ON public.wali_suggestions FOR SELECT USING (((wali_id = ( SELECT auth.uid() AS uid)) OR (seeker_id = ( SELECT auth.uid() AS uid))));


--
-- Name: wali_suggestions wali_suggestions_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wali_suggestions_update ON public.wali_suggestions FOR UPDATE USING ((seeker_id = ( SELECT auth.uid() AS uid)));


--
-- Name: zyra_inactivity_notices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.zyra_inactivity_notices ENABLE ROW LEVEL SECURITY;

--
-- Name: zyra_onboarding_questions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.zyra_onboarding_questions ENABLE ROW LEVEL SECURITY;

-- Foreign-key action order from the historical replay
ALTER TABLE ONLY public.profiles ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.subscriptions ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_photos ADD CONSTRAINT profile_photos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_links ADD CONSTRAINT wali_links_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_links ADD CONSTRAINT wali_links_wali_id_fkey FOREIGN KEY (wali_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.saves ADD CONSTRAINT saves_saver_id_fkey FOREIGN KEY (saver_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.saves ADD CONSTRAINT saves_saved_id_fkey FOREIGN KEY (saved_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.likes ADD CONSTRAINT likes_liker_id_fkey FOREIGN KEY (liker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.likes ADD CONSTRAINT likes_liked_id_fkey FOREIGN KEY (liked_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_unlocks ADD CONSTRAINT profile_unlocks_unlocker_id_fkey FOREIGN KEY (unlocker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_unlocks ADD CONSTRAINT profile_unlocks_unlocked_id_fkey FOREIGN KEY (unlocked_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.matches ADD CONSTRAINT matches_seeker_a_id_fkey FOREIGN KEY (seeker_a_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.matches ADD CONSTRAINT matches_seeker_b_id_fkey FOREIGN KEY (seeker_b_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.conversations ADD CONSTRAINT conversations_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.messages ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.timelines ADD CONSTRAINT timelines_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.timeline_milestones ADD CONSTRAINT timeline_milestones_timeline_id_fkey FOREIGN KEY (timeline_id) REFERENCES public.timelines(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_suggestions ADD CONSTRAINT wali_suggestions_wali_id_fkey FOREIGN KEY (wali_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_suggestions ADD CONSTRAINT wali_suggestions_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_suggestions ADD CONSTRAINT wali_suggestions_suggested_id_fkey FOREIGN KEY (suggested_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.onboarding_answers ADD CONSTRAINT onboarding_answers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_invites ADD CONSTRAINT wali_invites_inviter_id_fkey FOREIGN KEY (inviter_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_salams ADD CONSTRAINT journey_salams_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_salams ADD CONSTRAINT journey_salams_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_compatibility ADD CONSTRAINT journey_compatibility_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_answers ADD CONSTRAINT journey_phase_answers_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_answers ADD CONSTRAINT journey_phase_answers_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_ratings ADD CONSTRAINT journey_phase_ratings_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_ratings ADD CONSTRAINT journey_phase_ratings_rater_id_fkey FOREIGN KEY (rater_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_checkpoints ADD CONSTRAINT journey_phase_checkpoints_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_checkpoints ADD CONSTRAINT journey_phase_checkpoints_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_family_answers ADD CONSTRAINT journey_family_answers_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_family_answers ADD CONSTRAINT journey_family_answers_answerer_id_fkey FOREIGN KEY (answerer_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.matches ADD CONSTRAINT matches_suspended_by_fkey FOREIGN KEY (suspended_by) REFERENCES public.profiles(id);
ALTER TABLE ONLY public.notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.notifications ADD CONSTRAINT notifications_related_match_id_fkey FOREIGN KEY (related_match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_family_reviews ADD CONSTRAINT journey_family_reviews_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_family_review_responses ADD CONSTRAINT journey_family_review_responses_review_id_fkey FOREIGN KEY (review_id) REFERENCES public.journey_family_reviews(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_family_review_responses ADD CONSTRAINT journey_family_review_responses_wali_id_fkey FOREIGN KEY (wali_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_blocks ADD CONSTRAINT profile_blocks_blocker_id_fkey FOREIGN KEY (blocker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_blocks ADD CONSTRAINT profile_blocks_blocked_id_fkey FOREIGN KEY (blocked_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.passes ADD CONSTRAINT passes_passer_id_fkey FOREIGN KEY (passer_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.passes ADD CONSTRAINT passes_passed_id_fkey FOREIGN KEY (passed_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.consents ADD CONSTRAINT consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.seeker_details ADD CONSTRAINT seeker_details_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.unlock_credits ADD CONSTRAINT unlock_credits_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.unlock_credits ADD CONSTRAINT unlock_credits_related_unlock_id_fkey FOREIGN KEY (related_unlock_id) REFERENCES public.profile_unlocks(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.matches ADD CONSTRAINT matches_ended_by_fkey FOREIGN KEY (ended_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.journey_attempts ADD CONSTRAINT journey_attempts_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_attempts ADD CONSTRAINT journey_attempts_ended_by_fkey FOREIGN KEY (ended_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.journey_attempts ADD CONSTRAINT journey_attempts_paused_by_fkey FOREIGN KEY (paused_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.conversations ADD CONSTRAINT conversations_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_compatibility ADD CONSTRAINT journey_compatibility_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_family_answers ADD CONSTRAINT journey_family_answers_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_family_reviews ADD CONSTRAINT journey_family_reviews_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_answers ADD CONSTRAINT journey_phase_answers_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_checkpoints ADD CONSTRAINT journey_phase_checkpoints_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_phase_ratings ADD CONSTRAINT journey_phase_ratings_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_salams ADD CONSTRAINT journey_salams_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.timelines ADD CONSTRAINT timelines_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.notification_preferences ADD CONSTRAINT notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.app_feedback ADD CONSTRAINT app_feedback_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.journey_stage_checkpoints ADD CONSTRAINT journey_stage_checkpoints_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_stage_checkpoints ADD CONSTRAINT journey_stage_checkpoints_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_stage_checkpoints ADD CONSTRAINT journey_stage_checkpoints_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_invites ADD CONSTRAINT wali_invites_accepted_by_fkey FOREIGN KEY (accepted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.protection_holds ADD CONSTRAINT protection_holds_released_by_fkey FOREIGN KEY (released_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.journey_requests ADD CONSTRAINT journey_requests_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_requests ADD CONSTRAINT journey_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_requests ADD CONSTRAINT journey_requests_requested_to_fkey FOREIGN KEY (requested_to) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_requests ADD CONSTRAINT journey_requests_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.journey_milestone_attestations ADD CONSTRAINT journey_milestone_attestations_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_milestone_attestations ADD CONSTRAINT journey_milestone_attestations_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_milestone_attestations ADD CONSTRAINT journey_milestone_attestations_proposed_by_fkey FOREIGN KEY (proposed_by) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_milestone_attestations ADD CONSTRAINT journey_milestone_attestations_confirmed_by_fkey FOREIGN KEY (confirmed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.wali_invites ADD CONSTRAINT wali_invites_seen_by_fkey FOREIGN KEY (seen_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.wali_invites ADD CONSTRAINT wali_invites_declined_by_fkey FOREIGN KEY (declined_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.identity_verification_attempts ADD CONSTRAINT identity_verification_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.identity_verification_event_receipts ADD CONSTRAINT identity_verification_event_receipts_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES private.identity_verification_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.guardian_journey_history_consents ADD CONSTRAINT guardian_journey_history_consents_wali_link_id_fkey FOREIGN KEY (wali_link_id) REFERENCES public.wali_links(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_personal_codes ADD CONSTRAINT zyra_personal_codes_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_personal_code_attempts ADD CONSTRAINT zyra_personal_code_attempts_caller_id_fkey FOREIGN KEY (caller_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_invites ADD CONSTRAINT wali_invites_personal_code_id_fkey FOREIGN KEY (personal_code_id) REFERENCES private.zyra_personal_codes(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.wali_invites ADD CONSTRAINT wali_invites_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_guardian_assignments ADD CONSTRAINT journey_guardian_assignments_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_guardian_assignments ADD CONSTRAINT journey_guardian_assignments_wali_link_id_fkey FOREIGN KEY (wali_link_id) REFERENCES public.wali_links(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.journey_guardian_assignments ADD CONSTRAINT journey_guardian_assignments_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_message_threads ADD CONSTRAINT family_message_threads_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_message_memberships ADD CONSTRAINT family_message_memberships_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.family_message_threads(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_message_memberships ADD CONSTRAINT family_message_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_messages ADD CONSTRAINT family_messages_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.family_message_threads(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_messages ADD CONSTRAINT family_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_message_participant_state ADD CONSTRAINT family_message_participant_state_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.family_message_threads(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_message_participant_state ADD CONSTRAINT family_message_participant_state_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.verified_person_accounts ADD CONSTRAINT verified_person_accounts_verified_person_id_fkey FOREIGN KEY (verified_person_id) REFERENCES private.verified_people(id) ON DELETE RESTRICT;
ALTER TABLE ONLY private.verified_person_accounts ADD CONSTRAINT verified_person_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.seeker_trial_ledger ADD CONSTRAINT seeker_trial_ledger_verified_person_id_fkey FOREIGN KEY (verified_person_id) REFERENCES private.verified_people(id) ON DELETE RESTRICT;
ALTER TABLE ONLY private.seeker_trial_ledger ADD CONSTRAINT seeker_trial_ledger_claimed_by_fkey FOREIGN KEY (claimed_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_seat_assignments ADD CONSTRAINT family_seat_assignments_family_subscription_id_fkey FOREIGN KEY (family_subscription_id) REFERENCES public.family_subscriptions(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_seat_assignments ADD CONSTRAINT family_seat_assignments_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_membership_invitations ADD CONSTRAINT family_membership_invitations_family_subscription_id_fkey FOREIGN KEY (family_subscription_id) REFERENCES public.family_subscriptions(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_membership_invitations ADD CONSTRAINT family_membership_invitations_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_membership_invitations ADD CONSTRAINT family_membership_invitations_invited_user_id_fkey FOREIGN KEY (invited_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_ownership_transfers ADD CONSTRAINT family_ownership_transfers_family_subscription_id_fkey FOREIGN KEY (family_subscription_id) REFERENCES public.family_subscriptions(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.guardian_journey_permissions ADD CONSTRAINT guardian_journey_permissions_wali_link_id_fkey FOREIGN KEY (wali_link_id) REFERENCES public.wali_links(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.guardian_journey_permissions ADD CONSTRAINT guardian_journey_permissions_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.guardian_journey_permissions ADD CONSTRAINT guardian_journey_permissions_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_reports ADD CONSTRAINT profile_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.profile_reports ADD CONSTRAINT profile_reports_reported_id_fkey FOREIGN KEY (reported_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.zyra_unlock_account_guards ADD CONSTRAINT zyra_unlock_account_guards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_unlock_operations ADD CONSTRAINT zyra_unlock_operations_unlocker_id_fkey FOREIGN KEY (unlocker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_unlock_operations ADD CONSTRAINT zyra_unlock_operations_unlocked_id_fkey FOREIGN KEY (unlocked_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_videos ADD CONSTRAINT profile_videos_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_photo_cleanup_leases ADD CONSTRAINT zyra_photo_cleanup_leases_bucket_path_fkey FOREIGN KEY (bucket, path) REFERENCES public.photo_object_deletions(bucket, path);
ALTER TABLE ONLY public.wali_links ADD CONSTRAINT wali_links_invitation_id_fkey FOREIGN KEY (invitation_id) REFERENCES public.wali_invites(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.zyra_guardian_invite_accept_guards ADD CONSTRAINT zyra_guardian_invite_accept_guards_seeker_id_fkey FOREIGN KEY (seeker_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_directional_results ADD CONSTRAINT zyra_directional_results_viewer_fkey FOREIGN KEY (viewer) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_directional_results ADD CONSTRAINT zyra_directional_results_subject_fkey FOREIGN KEY (subject) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.preference_light_confirmations ADD CONSTRAINT preference_light_confirmations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_hides ADD CONSTRAINT profile_hides_hider_fkey FOREIGN KEY (hider) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.profile_hides ADD CONSTRAINT profile_hides_hidden_fkey FOREIGN KEY (hidden) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.seeker_home_places ADD CONSTRAINT seeker_home_places_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_compatibility_sect_repairs ADD CONSTRAINT zyra_compatibility_sect_repairs_viewer_fkey FOREIGN KEY (viewer) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.guardian_trial_ledger ADD CONSTRAINT guardian_trial_ledger_verified_person_id_fkey FOREIGN KEY (verified_person_id) REFERENCES private.verified_people(id) ON DELETE RESTRICT;
ALTER TABLE ONLY private.guardian_trial_ledger ADD CONSTRAINT guardian_trial_ledger_claimed_by_fkey FOREIGN KEY (claimed_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.zyra_account_deleted_matches ADD CONSTRAINT zyra_account_deleted_matches_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.messages ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.journey_guardian_assignments ADD CONSTRAINT journey_guardian_assignments_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.journey_guardian_assignments ADD CONSTRAINT journey_guardian_assignments_revoked_by_fkey FOREIGN KEY (revoked_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_message_reports ADD CONSTRAINT family_message_reports_sealed_message_id_fkey FOREIGN KEY (sealed_message_id) REFERENCES private.safety_sealed_messages(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_message_reports ADD CONSTRAINT family_message_reports_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.family_message_threads(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_message_reports ADD CONSTRAINT family_message_reports_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.family_messages(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_message_reports ADD CONSTRAINT family_message_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_message_reports ADD CONSTRAINT family_message_reports_reported_id_fkey FOREIGN KEY (reported_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_subscriptions ADD CONSTRAINT family_subscriptions_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_ownership_transfers ADD CONSTRAINT family_ownership_transfers_current_owner_id_fkey FOREIGN KEY (current_owner_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_ownership_transfers ADD CONSTRAINT family_ownership_transfers_replacement_owner_id_fkey FOREIGN KEY (replacement_owner_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.protection_holds ADD CONSTRAINT protection_holds_restricted_id_fkey FOREIGN KEY (restricted_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.protection_holds ADD CONSTRAINT protection_holds_protected_id_fkey FOREIGN KEY (protected_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.zyra_report_sealed_messages ADD CONSTRAINT zyra_report_sealed_messages_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.profile_reports(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_report_sealed_messages ADD CONSTRAINT zyra_report_sealed_messages_sealed_message_id_fkey FOREIGN KEY (sealed_message_id) REFERENCES private.safety_sealed_messages(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_guardian_notification_sources ADD CONSTRAINT zyra_guardian_notification_sources_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_guardian_notification_sources ADD CONSTRAINT zyra_guardian_notification_sources_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.zyra_guardian_notification_sources ADD CONSTRAINT zyra_guardian_notification_sources_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.wali_invites(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.zyra_guardian_notification_sources ADD CONSTRAINT zyra_guardian_notification_sources_link_id_fkey FOREIGN KEY (link_id) REFERENCES public.wali_links(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.zyra_deleted_attempt_evidence ADD CONSTRAINT zyra_deleted_attempt_evidence_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_circle_seal_protections ADD CONSTRAINT zyra_circle_seal_protections_sealed_message_id_fkey FOREIGN KEY (sealed_message_id) REFERENCES private.safety_sealed_messages(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_circle_seal_protections ADD CONSTRAINT zyra_circle_seal_protections_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.family_message_reports(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.protection_holds ADD CONSTRAINT protection_holds_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE SET NULL;
ALTER TABLE ONLY private.report_protected_attempts ADD CONSTRAINT report_protected_attempts_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.profile_reports(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.report_protected_attempts ADD CONSTRAINT report_protected_attempts_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_purged_ended_match_projections ADD CONSTRAINT zyra_purged_ended_match_projections_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_journey_reveal_tombstones ADD CONSTRAINT zyra_journey_reveal_tombstones_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_journey_reveal_tombstones ADD CONSTRAINT zyra_journey_reveal_tombstones_consent_for_attempt_id_fkey FOREIGN KEY (consent_for_attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_ended_journey_removals ADD CONSTRAINT zyra_ended_journey_removals_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.zyra_inactivity_notices ADD CONSTRAINT zyra_inactivity_notices_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.email_outbox ADD CONSTRAINT email_outbox_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_message_chats ADD CONSTRAINT family_message_chats_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.family_message_threads(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_message_chats ADD CONSTRAINT family_message_chats_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_message_chat_state ADD CONSTRAINT family_message_chat_state_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES public.family_message_chats(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_message_chat_state ADD CONSTRAINT family_message_chat_state_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_messages ADD CONSTRAINT family_messages_chat_thread_fkey FOREIGN KEY (thread_id, chat_id) REFERENCES public.family_message_chats(thread_id, id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_family_chat_report_attempts ADD CONSTRAINT zyra_family_chat_report_attempts_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.family_message_reports(id) ON DELETE CASCADE;
ALTER TABLE ONLY private.zyra_family_chat_report_attempts ADD CONSTRAINT zyra_family_chat_report_attempts_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.journey_attempts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.notifications ADD CONSTRAINT notifications_related_chat_id_fkey FOREIGN KEY (related_chat_id) REFERENCES public.family_message_chats(id) ON DELETE CASCADE;


-- Line 109 shared code checks and authenticated resolver (d01b414)
create function private.zyra_begin_personal_code_check()
returns uuid
language plpgsql
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_me::text, 231));
  delete from private.zyra_personal_code_attempts a
   where a.caller_id = v_me
     and a.attempted_at < clock_timestamp() - interval '7 days';
  if (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me
        and a.attempted_at >= clock_timestamp() - interval '1 hour') >= 10
     or
     (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me
        and a.attempted_at >= clock_timestamp() - interval '1 day') >= 30 then
    raise exception 'too_many_code_checks';
  end if;

  return v_me;
end;
$function$;

create function private.zyra_personal_code_guardian_eligible(
  p_caller uuid, p_caller_role text, p_owner uuid, p_owner_role text
)
returns boolean
language sql
stable
set search_path = ''
as $function$
  select coalesce(p_owner is not null
    and p_owner <> p_caller
    and private.zyra_identity_verification_allows_user(p_owner)
    and p_caller_role in ('seeker', 'wali')
    and p_owner_role <> p_caller_role
    and not public.zyra_block_exists(p_owner)
    and public.zyra_can_guardian_link(p_caller, p_owner)
    and not exists (
      select 1 from public.wali_links wl
      where ((wl.seeker_id = p_caller and wl.wali_id = p_owner)
          or (wl.seeker_id = p_owner and wl.wali_id = p_caller))
        and wl.status = 'active'
    ), false);
$function$;

create function private.zyra_personal_code_match_eligible(
  p_caller uuid, p_caller_role text, p_owner uuid
)
returns boolean
language sql
stable
set search_path = ''
as $function$
  select coalesce(p_owner is not null
    and p_owner <> p_caller
    and p_caller_role = 'seeker'
    and private.zyra_identity_verification_allows_user(p_owner)
    and public.zyra_can_view_profile(p_owner)
    and public.zyra_can_match(p_caller, p_owner), false);
$function$;

revoke all on function private.zyra_begin_personal_code_check(),
  private.zyra_personal_code_guardian_eligible(uuid, text, uuid, text),
  private.zyra_personal_code_match_eligible(uuid, text, uuid)
  from public, anon, authenticated, service_role;

create function public.zyra_preview_personal_code(p_code text)
returns table(owner_first_name text, owner_role text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := private.zyra_begin_personal_code_check();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_owner_role text;
  v_my_role text;
  v_first_name text;
  v_allowed boolean;
begin
  select c.owner_id, c.role_context, p.first_name
    into v_owner, v_owner_role, v_first_name
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id and p.role = c.role_context
  where c.code = v_code;

  select p.role into v_my_role from public.profiles p where p.id = v_me;
  v_allowed := private.zyra_personal_code_guardian_eligible(
    v_me, v_my_role, v_owner, v_owner_role
  );
  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, v_allowed);
  if not v_allowed then return; end if;

  return query select v_first_name, v_owner_role;
end;
$function$;

create function public.zyra_preview_match_code(p_code text)
returns table(owner_first_name text, owner_age integer, owner_location text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := private.zyra_begin_personal_code_check();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_my_role text;
  v_first_name text;
  v_age integer;
  v_location text;
  v_allowed boolean;
begin
  select c.owner_id,
         p.first_name,
         date_part('year', age(p.date_of_birth))::integer,
         p.location_text
    into v_owner, v_first_name, v_age, v_location
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id and p.role = c.role_context
  where c.code = v_code and c.role_context = 'seeker';

  select p.role into v_my_role from public.profiles p where p.id = v_me;
  v_allowed := private.zyra_personal_code_match_eligible(v_me, v_my_role, v_owner);
  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, v_allowed);
  if not v_allowed then return; end if;

  return query select v_first_name, v_age, v_location;
end;
$function$;

create function public.zyra_resolve_code_link(p_code text)
returns table(
  outcome text,
  owner_first_name text,
  owner_role text,
  owner_age integer,
  owner_location text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := private.zyra_begin_personal_code_check();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_code_role text;
  v_owner_role text;
  v_my_role text;
  v_first_name text;
  v_age integer;
  v_location text;
begin
  select c.owner_id, c.role_context, p.role, p.first_name,
         date_part('year', age(p.date_of_birth))::integer, p.location_text
    into v_owner, v_code_role, v_owner_role, v_first_name, v_age, v_location
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id
  where c.code = v_code;

  select p.role into v_my_role from public.profiles p where p.id = v_me;

  outcome := 'unavailable';
  if v_owner = v_me then
    outcome := 'own_code';
  elsif v_owner_role = v_code_role then
    if private.zyra_personal_code_guardian_eligible(v_me, v_my_role, v_owner, v_code_role) then
      outcome := case when v_my_role = 'seeker' then 'add_guardian' else 'add_seeker' end;
      owner_first_name := v_first_name;
      owner_role := v_code_role;
    elsif v_code_role = 'seeker'
      and private.zyra_personal_code_match_eligible(v_me, v_my_role, v_owner) then
      outcome := 'scan';
      owner_first_name := v_first_name;
      owner_age := v_age;
      owner_location := v_location;
    end if;
  end if;

  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, outcome in ('add_guardian', 'add_seeker', 'scan'));

  return next;
end;
$function$;

revoke all on function public.zyra_resolve_code_link(text)
  from public, anon, service_role;
grant execute on function public.zyra_resolve_code_link(text) to authenticated;

comment on function public.zyra_resolve_code_link(text) is
  'Resolve a shared ZYRA Code using one caller-scoped check across both role routes. '
  'Successful results only disclose the fields already returned by the corresponding preview.';

COMMENT ON FUNCTION public.zyra_preview_match_code(p_code text) IS 'Bearer-code lookup for a known romantic candidate. Returns only Browse-level identity after authentication, both users identity-verified, Seeker-only role, visibility, block, onboarding, gender and Guardian-exclusion checks. Uses the shared personal-code attempt budget; an empty rowset is deliberately indistinguishable across unknown, ineligible and disallowed targets.';
COMMENT ON FUNCTION public.zyra_preview_personal_code(p_code text) IS 'Authenticated, rate-limited and neutral-on-failure preview. Returns first name and role only; no photo and no identity-verification claim.';

-- Application access grants
REVOKE ALL ON FUNCTION private.zyra_can_guardian_link_pair(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_can_match_pair(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_close_expired_journey_requests(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_expire_due_journey_requests_all() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_alert_family_chat_arrival(uuid,uuid,uuid,timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_attempt_has_open_report(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_clear_deleted_guardian_trial() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_compatibility_answer(jsonb,text,jsonb,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_compatibility_input(jsonb,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_compatibility_light(jsonb,uuid,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_compatibility_sect_key(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_create_notification(uuid,text,text,text,uuid,uuid,uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_current_sect_third_key(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_enforce_personal_request_owner_acceptance() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_enforce_photo_row_owner() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_enforce_photo_upload_fence() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_erase_departing_notification_previews(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_family_chat_admission(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_family_chat_admission(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_family_chat_create_for_attempt() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_family_chat_create_for_thread() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_family_chat_message_visible(uuid,timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_family_message_default_main() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_generate_personal_code() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_guard_legacy_photo_row_write() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_guard_unlock_credit() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_guard_unlock_row() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_guardian_invite_capacity(uuid,uuid,timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_hidden_ch2_light_applicable(text,jsonb) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_identity_verification_allows_user(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_inactivity_ended_attempts(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_invalidate_preference_light_confirmations() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_keep_red_ch2_hard_requirements() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_keep_red_ch4_hard_requirements() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_link_report_attempts() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_active_family_review(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_family_chat(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_family_chat_match(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_family_chat_profiles(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_family_message_thread(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_member_photo_statement() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_message_match() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_photo_folder(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_lock_unlock_account(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_match_has_active_hold(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_match_has_protected_data(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_my_attempt_participation_rows() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_normalize_personal_code(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_photo_caller_exists() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_photo_not_queued(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_photo_object_referenced(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_photo_path_writable(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_photo_reference_owned(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_plus_spend_available() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_preference_control_visible(text,jsonb,integer,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_preference_light_controls(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_preference_lights_to_check(boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_preference_receipt_path(integer,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_protect_new_report_attempt() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_protect_report_attempts_before_departure(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_purge_account_deleted_match(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_purge_account_deleted_matches() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_purge_closed_ended_journeys() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_purge_ended_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_queue_deleted_photo_source() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_queue_owned_photo_object(uuid,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_queue_photo_folder(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_red_hard_requirements(jsonb,jsonb) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_remove_departing_profile() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_remove_ended_journey_for(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_resolve_report_attempt() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_retire_personal_code() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_run_inactivity_job_at(timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_save_direction_result(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_seal_departing_family_journey_chats(uuid,uuid[],timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_sect_light_missing(jsonb,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_source_photo_path_owned(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_touch_identity_verification_attempt() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_unreferenced_photo_path_writable(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.zyra_version_compatibility_capture() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.accept_wali_invite(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.ages_for(uuid[]) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.ages_for_one(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.auto_designate_main_wali() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.create_conversation_started_milestone() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.create_match_on_mutual_like() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.create_notification(uuid,text,text,text,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.end_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.end_journey(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.expire_wali_invite_if_due(public.wali_invites) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.grant_zyra_one_credits() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.guardians_for_unlocked(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.has_article9_consent() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.notify_new_message() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.nudge_paused_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.open_family_review(uuid,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.preview_wali_invite(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.promote_journey_to_active(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.reopen_family_review(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.request_new_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.resolve_family_review_if_due(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.respond_to_journey_request(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.restart_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.resume_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.score_candidates(uuid[]) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.seeker_details_for_unlocked(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.suspend_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.touch_seeker_details() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.unlock_balance(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.update_updated_at() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.wali_has_wali_one() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.wali_review_decision(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.withdraw_journey_request(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_accept_family_invitation(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_accept_guardian_request(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_active_journey_cap(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_active_journey_count(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_advance_stage(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_all_iso639_1(text[]) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_answers_refresh_onboarding_complete() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_assert_family_owner_seat(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_attach_identity_verification_provider_session(uuid,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_attempt_participants(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_attempt_summary_for_guardian(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_available_journey_return_ids() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_block_exists(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_block_user(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_can_continue_journey(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_can_guardian_link(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_can_match(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_can_read_ended_match(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_can_read_photo_object(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_can_read_profile_video_object(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_can_view_attempt(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_can_view_profile(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_cancel_guardian_request(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_capture_family_message_report_evidence() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_ch2_sect_hard_shape_ok(jsonb) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_ch4_hard_shape_ok(jsonb) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_claim_photo_object_deletions() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_clear_main_guardian(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_close_family_message_report(uuid,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_close_unavailable_journey_requests() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_compatibility_for_plus(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_compatibility_topics(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_confirm_milestone(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_confirm_preference_lights(jsonb) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_consider_match_code(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_counterpart_card(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_create_first_attempt() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_create_guardian_invitation() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_create_profile(text,text,text,date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_dashboard_updates(integer,timestamp with time zone,text,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_decline_guardian_request(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_decline_wali_invite(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_delete_my_unstarted_identity_verification_attempt() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_discover_profile_ids(integer,integer,text,integer,text,text[],text[],integer,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_end_match_internal(uuid,uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_enforce_family_seat_capacity() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_enforce_guardian_link_allowed() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_enforce_main_guardian_journey_hold() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_enforce_one_active_attempt() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_enforce_one_active_match() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_expire_due_journey_requests(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_expire_due_wali_invites() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_formula_monthly_pence(integer,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_message_can_read(uuid,timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_message_chats(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_message_circle_can_send(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_message_circles() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_message_participants(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_messages(uuid,timestamp with time zone,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_messages_v2(uuid,timestamp with time zone,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_messages_v3(uuid,timestamp with time zone,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_owner_row_guard() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_family_owner_seat_guard() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_finish_photo_object_deletion(text,text,integer,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_forfeit_seeker_trial_on_family_seat() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_guard_ended_restart_initiation() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_guard_family_place_reduction() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_guardian_activity() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_guardian_history_consent(uuid,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_guardian_journey_access(uuid,uuid,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_guardian_journey_chat_access(uuid,uuid,boolean,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_guardian_journey_permissions(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_has_paid_role(uuid,text,timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_hold_blocks(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_journey_busy_flags(uuid[]) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_journey_compatibility_state(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_journey_main_guardian_gate(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_journey_return_available(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_light_weight(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_like_clears_others() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_main_guardian_history_consent(boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_mark_family_chat_read(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_mark_family_message_sender_deleted() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_mark_family_messages_read(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_mark_journey_messages_read(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_mark_suggestions_seen() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_match_ending(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_may_request_new_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_may_request_new_journey_ids() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_may_send_journey_message(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_milestone_attestation_state(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_code_check_budget() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_ended_journeys() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_guardian_requests() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_hidden_profile_ids() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_identity_verification_allows_active_journey() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_identity_verification_allows_app() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_identity_verification_state() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_inactivity_notice() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_lights_needed_for_compatibility() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_lights_needing_reconfirmation() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_lights_needing_reconfirmation(boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_onboarding_progress() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_paid_access(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_personal_code(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_photo_sources() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_profile_video() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_safety_cases() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_my_welcome_back() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_normalise_profile_identity() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_notification_category(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_notification_preferences() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_onboarding_complete(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_onboarding_data_complete(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_onboarding_missing(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_open_family_message_circle(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_pass_clears_others() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_preview_match_code(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_preview_personal_code(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_product_event_summary(timestamp with time zone,timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_profile_video_for(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_profiles_set_onboarding_complete() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_propose_milestone(uuid,text,date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_prune_product_events() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_purge_expired_family_message_data() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_purge_expired_safety_messages() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_question_is_due(text,text,jsonb) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_record_identity_verification_consent(text,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_record_identity_verification_provider_result(text,text,text,boolean,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_record_journey_milestone() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_record_product_event(text,text,text,text,text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_record_profile_video(uuid,text,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_record_profile_video(uuid,text,integer,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_refresh_onboarding_complete(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_remove_ended_journey(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_remove_guardian(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_remove_my_profile_video() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_remove_profile_photo(uuid,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_report_family_message(uuid,uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_request_guardian_link(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_require_verified_family_seat() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_reset_profile() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_reset_search() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_reveal_journey_compatibility(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_review_profile_video(uuid,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_revoke_wali_invite(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_rotate_my_personal_code(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_run_inactivity_job() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_save_clears_others() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_save_profile_photo(uuid,text,text,jsonb,integer,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_score_direction_v1(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_sect_code(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_send_family_message(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_send_family_message(uuid,text,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_attempt_from_match() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_family_chat_muted(uuid,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_family_message_muted(uuid,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_guardian_journey_permission(uuid,uuid,boolean,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_main_guardian(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_my_home_place(text,numeric,numeric) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_notification_preference(text,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_profile_complete(boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_profile_hidden(text,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_set_profile_hidden(uuid,boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_start_verified_guardian_trial(uuid,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_start_verified_seeker_trial(uuid,uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_submit_feedback(text,text,text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_sync_family_message_block_lifecycle() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_sync_family_message_circle_members(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_sync_family_message_link_lifecycle() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_touch_activity() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_unblock_user(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_unlock_profile(uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_validate_family_ownership_transfer() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.zyra_validate_profile_name_lengths() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON SEQUENCE private.zyra_personal_code_attempts_id_seq FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON SEQUENCE private.zyra_product_events_id_seq FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON SEQUENCE public.notification_preferences_seq_seq FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.guardian_trial_ledger FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.identity_verification_attempts FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.identity_verification_event_receipts FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.report_protected_attempts FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.safety_sealed_messages FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.seeker_home_places FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.seeker_trial_ledger FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.verified_people FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.verified_person_accounts FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_account_deleted_matches FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_circle_seal_protections FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_compatibility_sect_repairs FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_deleted_attempt_evidence FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_directional_results FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_ended_journey_removals FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_ended_journey_visibility FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_family_chat_report_attempts FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_guardian_invite_accept_guards FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_guardian_notification_sources FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_journey_reveal_tombstones FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_personal_code_attempts FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_personal_codes FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_photo_cleanup_leases FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_photo_folder_guard FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_product_events FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_purged_ended_match_projections FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_question_area FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_report_sealed_messages FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_retired_personal_code_hashes FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_unlock_account_guards FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_unlock_operations FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE private.zyra_unlock_release_gate FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.app_feedback FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.consents FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.conversations FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.email_outbox FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_membership_invitations FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_message_chat_state FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_message_chats FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_message_memberships FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_message_participant_state FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_message_report_evidence FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_message_reports FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_message_threads FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_messages FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_ownership_transfers FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_seat_assignments FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.family_subscriptions FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.guardian_journey_history_consents FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.guardian_journey_permissions FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_attempts FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_compatibility FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_family_answers FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_family_review_responses FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_family_reviews FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_guardian_assignments FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_milestone_attestations FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_phase_answers FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_phase_checkpoints FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_phase_ratings FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_requests FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_salams FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.journey_stage_checkpoints FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.likes FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.matches FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.messages FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.notification_preferences FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.notifications FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.onboarding_answers FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.passes FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.photo_object_deletions FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.preference_light_confirmations FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.profile_blocks FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.profile_hides FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.profile_photos FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.profile_reports FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.profile_unlocks FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.profile_videos FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.profiles FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.protection_holds FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.saves FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.seeker_details FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.subscriptions FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.timeline_milestones FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.timelines FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.unlock_credits FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.wali_invites FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.wali_links FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.wali_suggestions FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.zyra_attempt_participant_rows FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.zyra_data_ownership FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.zyra_inactivity_notices FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.zyra_my_attempt_participation FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.zyra_onboarding_questions FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.zyra_photo_cleanup_failures FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.likes TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.passes TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.saves TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.app_feedback TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.consents TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.conversations TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_membership_invitations TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_message_memberships TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_message_participant_state TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_message_report_evidence TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_message_reports TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_message_threads TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_messages TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_ownership_transfers TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_seat_assignments TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_subscriptions TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.guardian_journey_history_consents TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.guardian_journey_permissions TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_attempts TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_compatibility TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_family_answers TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_family_review_responses TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_family_reviews TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_guardian_assignments TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_milestone_attestations TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_phase_answers TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_phase_checkpoints TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_phase_ratings TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_requests TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_salams TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.journey_stage_checkpoints TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.likes TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.matches TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.messages TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.notification_preferences TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.notifications TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.onboarding_answers TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.passes TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.profile_blocks TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.profile_photos TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.profile_reports TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.profile_unlocks TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.profiles TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.protection_holds TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.saves TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.seeker_details TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.subscriptions TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.timeline_milestones TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.timelines TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.unlock_credits TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.wali_invites TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.wali_links TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.wali_suggestions TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.zyra_data_ownership TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.zyra_onboarding_questions TO service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, UPDATE ON TABLE public.journey_phase_ratings TO authenticated;
GRANT DELETE, INSERT, SELECT ON TABLE private.zyra_personal_code_attempts TO service_role;
GRANT DELETE, INSERT, SELECT ON TABLE private.zyra_product_events TO service_role;
GRANT DELETE, INSERT, SELECT, UPDATE ON TABLE private.verified_person_accounts TO service_role;
GRANT DELETE, INSERT, SELECT, UPDATE ON TABLE private.zyra_personal_codes TO service_role;
GRANT DELETE, MAINTAIN, TRIGGER ON TABLE public.profile_photos TO authenticated;
GRANT DELETE, SELECT ON TABLE private.safety_sealed_messages TO service_role;
GRANT EXECUTE ON FUNCTION private.zyra_create_notification(uuid,text,text,text,uuid,uuid,uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION private.zyra_family_chat_message_visible(uuid,timestamp with time zone) TO authenticated;
GRANT EXECUTE ON FUNCTION private.zyra_my_attempt_participation_rows() TO authenticated;
GRANT EXECUTE ON FUNCTION private.zyra_photo_caller_exists() TO authenticated;
GRANT EXECUTE ON FUNCTION private.zyra_photo_not_queued(text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.zyra_photo_path_writable(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.zyra_photo_reference_owned(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.zyra_source_photo_path_owned(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.zyra_unreferenced_photo_path_writable(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_wali_invite(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_wali_invite(text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.ages_for(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ages_for(uuid[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.ages_for_one(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ages_for_one(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.auto_designate_main_wali() TO service_role;
GRANT EXECUTE ON FUNCTION public.create_conversation_started_milestone() TO service_role;
GRANT EXECUTE ON FUNCTION public.create_match_on_mutual_like() TO service_role;
GRANT EXECUTE ON FUNCTION public.create_notification(uuid,text,text,text,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO service_role;
GRANT EXECUTE ON FUNCTION public.end_journey(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.end_journey(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.end_journey(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.end_journey(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.expire_wali_invite_if_due(public.wali_invites) TO service_role;
GRANT EXECUTE ON FUNCTION public.grant_zyra_one_credits() TO service_role;
GRANT EXECUTE ON FUNCTION public.guardians_for_unlocked(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.guardians_for_unlocked(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.has_article9_consent() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_article9_consent() TO service_role;
GRANT EXECUTE ON FUNCTION public.notify_new_message() TO service_role;
GRANT EXECUTE ON FUNCTION public.nudge_paused_journey(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nudge_paused_journey(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.open_family_review(uuid,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.open_family_review(uuid,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.preview_wali_invite(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.preview_wali_invite(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.promote_journey_to_active(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.promote_journey_to_active(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.reopen_family_review(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reopen_family_review(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.request_new_journey(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.resolve_family_review_if_due(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_family_review_if_due(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.respond_to_journey_request(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.restart_journey(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restart_journey(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.resume_journey(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resume_journey(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.score_candidates(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.score_candidates(uuid[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.seeker_details_for_unlocked(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.seeker_details_for_unlocked(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.suspend_journey(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.suspend_journey(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.touch_seeker_details() TO service_role;
GRANT EXECUTE ON FUNCTION public.unlock_balance(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unlock_balance(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.update_updated_at() TO service_role;
GRANT EXECUTE ON FUNCTION public.wali_has_wali_one() TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_has_wali_one() TO service_role;
GRANT EXECUTE ON FUNCTION public.wali_review_decision(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_review_decision(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.withdraw_journey_request(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_accept_family_invitation(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_accept_guardian_request(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_accept_guardian_request(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_active_journey_cap(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_active_journey_count(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_advance_stage(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_advance_stage(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_all_iso639_1(text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_all_iso639_1(text[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_answers_refresh_onboarding_complete() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_answers_refresh_onboarding_complete() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_assert_family_owner_seat(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_attach_identity_verification_provider_session(uuid,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_attempt_participants(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_attempt_summary_for_guardian(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_attempt_summary_for_guardian(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_available_journey_return_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_available_journey_return_ids() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_block_exists(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_block_exists(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_block_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_block_user(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_can_continue_journey(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_can_guardian_link(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_can_guardian_link(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_can_match(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_can_match(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_can_read_ended_match(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_can_read_photo_object(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_can_read_photo_object(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_can_read_photo_object(text) TO supabase_storage_admin;
GRANT EXECUTE ON FUNCTION public.zyra_can_read_profile_video_object(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_can_view_attempt(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_can_view_attempt(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_can_view_profile(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_can_view_profile(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_cancel_guardian_request(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_cancel_guardian_request(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_capture_family_message_report_evidence() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_ch2_sect_hard_shape_ok(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_ch2_sect_hard_shape_ok(jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_ch4_hard_shape_ok(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_ch4_hard_shape_ok(jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_claim_photo_object_deletions() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_clear_main_guardian(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_clear_main_guardian(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_close_family_message_report(uuid,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_close_unavailable_journey_requests() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_compatibility_for_plus(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_compatibility_topics(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_confirm_milestone(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_confirm_milestone(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_confirm_preference_lights(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_consider_match_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_consider_match_code(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_counterpart_card(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_counterpart_card(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_create_first_attempt() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_create_guardian_invitation() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_create_profile(text,text,text,date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_create_profile(text,text,text,date) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_dashboard_updates(integer,timestamp with time zone,text,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_dashboard_updates(integer,timestamp with time zone,text,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_decline_guardian_request(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_decline_guardian_request(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_decline_wali_invite(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_decline_wali_invite(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_delete_my_unstarted_identity_verification_attempt() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_delete_my_unstarted_identity_verification_attempt() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_discover_profile_ids(integer,integer,text,integer,text,text[],text[],integer,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_end_match_internal(uuid,uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_enforce_family_seat_capacity() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_enforce_guardian_link_allowed() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_enforce_main_guardian_journey_hold() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_enforce_one_active_attempt() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_enforce_one_active_match() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_expire_due_journey_requests(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_expire_due_journey_requests(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_expire_due_wali_invites() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_expire_due_wali_invites() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_formula_monthly_pence(integer,integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_can_read(uuid,timestamp with time zone) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_can_read(uuid,timestamp with time zone) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_chats(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_chats(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_circle_can_send(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_circles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_circles() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_participants(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_family_message_participants(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_messages(uuid,timestamp with time zone,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_family_messages(uuid,timestamp with time zone,integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_messages_v2(uuid,timestamp with time zone,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_family_messages_v2(uuid,timestamp with time zone,integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_messages_v3(uuid,timestamp with time zone,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_family_messages_v3(uuid,timestamp with time zone,integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_owner_row_guard() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_family_owner_seat_guard() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_finish_photo_object_deletion(text,text,integer,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_forfeit_seeker_trial_on_family_seat() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_guard_ended_restart_initiation() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_guard_family_place_reduction() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_activity() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_activity() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_history_consent(uuid,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_history_consent(uuid,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_journey_access(uuid,uuid,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_journey_access(uuid,uuid,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_journey_chat_access(uuid,uuid,boolean,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_journey_chat_access(uuid,uuid,boolean,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_journey_permissions(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_guardian_journey_permissions(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_has_paid_role(uuid,text,timestamp with time zone) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_hold_blocks(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_journey_busy_flags(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_journey_busy_flags(uuid[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_journey_compatibility_state(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_journey_main_guardian_gate(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_journey_main_guardian_gate(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_journey_return_available(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_journey_return_available(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_light_weight(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_light_weight(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_light_weight(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_like_clears_others() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_main_guardian_history_consent(boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_main_guardian_history_consent(boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_mark_family_chat_read(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_mark_family_chat_read(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_mark_family_message_sender_deleted() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_mark_family_messages_read(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_mark_family_messages_read(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_mark_journey_messages_read(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_mark_journey_messages_read(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_mark_suggestions_seen() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_mark_suggestions_seen() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_match_ending(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_match_ending(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_may_request_new_journey(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_may_request_new_journey(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_may_request_new_journey_ids() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_may_send_journey_message(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_may_send_journey_message(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_milestone_attestation_state(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_milestone_attestation_state(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_code_check_budget() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_ended_journeys() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_guardian_requests() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_guardian_requests() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_hidden_profile_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_identity_verification_allows_active_journey() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_identity_verification_allows_active_journey() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_identity_verification_allows_app() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_identity_verification_allows_app() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_identity_verification_state() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_identity_verification_state() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_inactivity_notice() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_lights_needed_for_compatibility() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_lights_needing_reconfirmation() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_lights_needing_reconfirmation(boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_onboarding_progress() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_onboarding_progress() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_paid_access(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_paid_access(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_personal_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_personal_code(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_photo_sources() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_profile_video() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_safety_cases() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_my_safety_cases() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_my_welcome_back() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_normalise_profile_identity() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_normalise_profile_identity() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_notification_category(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_notification_preferences() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_notification_preferences() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_onboarding_complete(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_onboarding_data_complete(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_onboarding_missing(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_open_family_message_circle(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_open_family_message_circle(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_pass_clears_others() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_preview_match_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_preview_match_code(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_preview_personal_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_preview_personal_code(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_product_event_summary(timestamp with time zone,timestamp with time zone) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_profile_video_for(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_profiles_set_onboarding_complete() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_profiles_set_onboarding_complete() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_propose_milestone(uuid,text,date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_propose_milestone(uuid,text,date) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_prune_product_events() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_purge_expired_family_message_data() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_purge_expired_safety_messages() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_question_is_due(text,text,jsonb) TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_question_is_due(text,text,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_question_is_due(text,text,jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_record_identity_verification_consent(text,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_record_identity_verification_consent(text,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_record_identity_verification_provider_result(text,text,text,boolean,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_record_journey_milestone() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_record_journey_milestone() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_record_product_event(text,text,text,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_record_product_event(text,text,text,text,text,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_record_profile_video(uuid,text,integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_record_profile_video(uuid,text,integer,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_refresh_onboarding_complete(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_remove_ended_journey(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_remove_guardian(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_remove_guardian(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_remove_my_profile_video() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_remove_profile_photo(uuid,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_report_family_message(uuid,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_report_family_message(uuid,uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_request_guardian_link(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_request_guardian_link(text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_require_verified_family_seat() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_reset_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_reset_profile() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_reset_search() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_reset_search() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_reveal_journey_compatibility(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_review_profile_video(uuid,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_revoke_wali_invite(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_revoke_wali_invite(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_rotate_my_personal_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_rotate_my_personal_code(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_run_inactivity_job() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_save_clears_others() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_save_profile_photo(uuid,text,text,jsonb,integer,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_score_direction_v1(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_sect_code(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_send_family_message(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_send_family_message(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_send_family_message(uuid,text,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_send_family_message(uuid,text,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_set_attempt_from_match() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_set_family_chat_muted(uuid,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_set_family_chat_muted(uuid,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_set_family_message_muted(uuid,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_set_family_message_muted(uuid,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_set_guardian_journey_permission(uuid,uuid,boolean,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_set_guardian_journey_permission(uuid,uuid,boolean,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_set_main_guardian(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_set_main_guardian(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_set_my_home_place(text,numeric,numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_set_notification_preference(text,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_set_notification_preference(text,boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_set_profile_complete(boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_set_profile_complete(boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_set_profile_hidden(text,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_set_profile_hidden(uuid,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_start_verified_guardian_trial(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_start_verified_seeker_trial(uuid,uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_submit_feedback(text,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_submit_feedback(text,text,text,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_sync_family_message_block_lifecycle() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_sync_family_message_circle_members(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_sync_family_message_link_lifecycle() TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_touch_activity() TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_unblock_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_unblock_user(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_unlock_profile(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_unlock_profile(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.zyra_validate_family_ownership_transfer() TO service_role;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.consents TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.journey_family_answers TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.journey_phase_answers TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.journey_phase_checkpoints TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.journey_salams TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.messages TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.wali_suggestions TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, UPDATE ON TABLE public.onboarding_answers TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, UPDATE ON TABLE public.seeker_details TO authenticated;
GRANT INSERT, MAINTAIN, REFERENCES, TRIGGER ON TABLE public.profile_reports TO authenticated;
GRANT INSERT, SELECT ON TABLE private.guardian_trial_ledger TO service_role;
GRANT INSERT, SELECT ON TABLE private.identity_verification_event_receipts TO service_role;
GRANT INSERT, SELECT ON TABLE private.zyra_retired_personal_code_hashes TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE private.identity_verification_attempts TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE private.seeker_trial_ledger TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE private.verified_people TO service_role;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.app_feedback TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.conversations TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.journey_family_review_responses TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.journey_family_reviews TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.journey_requests TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.notifications TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.profile_blocks TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.profile_unlocks TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.subscriptions TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.timeline_milestones TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.timelines TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.unlock_credits TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.wali_invites TO authenticated;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER ON TABLE public.wali_links TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.app_feedback TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.consents TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.conversations TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.journey_family_answers TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.journey_family_review_responses TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.journey_family_reviews TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.journey_phase_answers TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.journey_phase_checkpoints TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.journey_phase_ratings TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.journey_salams TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.likes TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.matches TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.matches TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.messages TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.notifications TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.onboarding_answers TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.passes TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.profile_blocks TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.profile_reports TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.profile_unlocks TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.profiles TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.profiles TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.saves TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.seeker_details TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.subscriptions TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.timeline_milestones TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.timelines TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.unlock_credits TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.wali_invites TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.wali_links TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER ON TABLE public.wali_suggestions TO anon;
GRANT MAINTAIN, TRIGGER ON TABLE public.profile_photos TO anon;
GRANT SELECT ON TABLE private.zyra_deleted_attempt_evidence TO service_role;
GRANT SELECT ON TABLE private.zyra_report_sealed_messages TO service_role;
GRANT SELECT ON TABLE public.email_outbox TO service_role;
GRANT SELECT ON TABLE public.family_message_participant_state TO authenticated;
GRANT SELECT ON TABLE public.family_message_threads TO authenticated;
GRANT SELECT ON TABLE public.family_messages TO authenticated;
GRANT SELECT ON TABLE public.journey_stage_checkpoints TO authenticated;
GRANT SELECT ON TABLE public.notification_preferences TO authenticated;
GRANT SELECT ON TABLE public.photo_object_deletions TO service_role;
GRANT SELECT ON TABLE public.preference_light_confirmations TO authenticated;
GRANT SELECT ON TABLE public.profile_hides TO authenticated;
GRANT SELECT ON TABLE public.profile_videos TO authenticated;
GRANT SELECT ON TABLE public.zyra_inactivity_notices TO authenticated;
GRANT SELECT ON TABLE public.zyra_inactivity_notices TO service_role;
GRANT SELECT ON TABLE public.zyra_my_attempt_participation TO authenticated;
GRANT SELECT ON TABLE public.zyra_photo_cleanup_failures TO service_role;
GRANT SELECT, UPDATE, USAGE ON SEQUENCE public.notification_preferences_seq_seq TO anon;
GRANT SELECT, UPDATE, USAGE ON SEQUENCE public.notification_preferences_seq_seq TO authenticated;
GRANT SELECT, UPDATE, USAGE ON SEQUENCE public.notification_preferences_seq_seq TO service_role;
GRANT SELECT, USAGE ON SEQUENCE private.zyra_personal_code_attempts_id_seq TO service_role;
GRANT SELECT, USAGE ON SEQUENCE private.zyra_product_events_id_seq TO service_role;
GRANT INSERT (created_at), SELECT (created_at), UPDATE (created_at) ON TABLE public.profile_photos TO authenticated;
GRANT INSERT (display_order), SELECT (display_order), UPDATE (display_order) ON TABLE public.profile_photos TO authenticated;
GRANT INSERT (id), SELECT (id), UPDATE (id) ON TABLE public.profile_photos TO authenticated;
GRANT INSERT (is_primary), SELECT (is_primary), UPDATE (is_primary) ON TABLE public.profile_photos TO authenticated;
GRANT INSERT (storage_path), SELECT (storage_path), UPDATE (storage_path) ON TABLE public.profile_photos TO authenticated;
GRANT INSERT (user_id), SELECT (user_id), UPDATE (user_id) ON TABLE public.profile_photos TO authenticated;
GRANT SELECT (also_paused_at) ON TABLE public.matches TO authenticated;
GRANT SELECT (also_paused_by) ON TABLE public.matches TO authenticated;
GRANT SELECT (bio), UPDATE (bio) ON TABLE public.profiles TO authenticated;
GRANT SELECT (category) ON TABLE public.app_feedback TO authenticated;
GRANT SELECT (created_at) ON TABLE public.app_feedback TO authenticated;
GRANT SELECT (created_at) ON TABLE public.matches TO authenticated;
GRANT SELECT (created_at) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (created_at) ON TABLE public.profiles TO authenticated;
GRANT SELECT (detail) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (ended_at) ON TABLE public.matches TO authenticated;
GRANT SELECT (ended_by) ON TABLE public.matches TO authenticated;
GRANT SELECT (first_name), UPDATE (first_name) ON TABLE public.profiles TO authenticated;
GRANT SELECT (first_published_at) ON TABLE public.profiles TO authenticated;
GRANT SELECT (gender) ON TABLE public.profiles TO authenticated;
GRANT SELECT (id) ON TABLE public.app_feedback TO authenticated;
GRANT SELECT (id) ON TABLE public.matches TO authenticated;
GRANT SELECT (id) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (id) ON TABLE public.profiles TO authenticated;
GRANT SELECT (is_active), UPDATE (is_active) ON TABLE public.profiles TO authenticated;
GRANT SELECT (journey_stage) ON TABLE public.matches TO authenticated;
GRANT SELECT (location_text), UPDATE (location_text) ON TABLE public.profiles TO authenticated;
GRANT SELECT (message) ON TABLE public.app_feedback TO authenticated;
GRANT SELECT (pause_nudged_at) ON TABLE public.matches TO authenticated;
GRANT SELECT (profile_complete) ON TABLE public.profiles TO authenticated;
GRANT SELECT (reason) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (reported_id) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (reporter_id) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (reviewed_at) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (role) ON TABLE public.profiles TO authenticated;
GRANT SELECT (seeker_a_id) ON TABLE public.matches TO authenticated;
GRANT SELECT (seeker_b_id) ON TABLE public.matches TO authenticated;
GRANT SELECT (source) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (status) ON TABLE public.matches TO authenticated;
GRANT SELECT (status) ON TABLE public.profile_reports TO authenticated;
GRANT SELECT (surname_line), UPDATE (surname_line) ON TABLE public.profiles TO authenticated;
GRANT SELECT (suspended_at) ON TABLE public.matches TO authenticated;
GRANT SELECT (suspended_by) ON TABLE public.matches TO authenticated;
GRANT SELECT (updated_at) ON TABLE public.profiles TO authenticated;
GRANT UPDATE (read_at) ON TABLE public.notifications TO authenticated;
GRANT UPDATE (responded_at) ON TABLE public.wali_suggestions TO authenticated;
GRANT UPDATE (status) ON TABLE public.wali_suggestions TO authenticated;

-- Managed Storage policy and upload fence
CREATE TRIGGER zyra_enforce_photo_upload_fence BEFORE INSERT OR DELETE OR UPDATE OF bucket_id, name, owner_id, metadata, version ON storage.objects FOR EACH ROW EXECUTE FUNCTION private.zyra_enforce_photo_upload_fence();

CREATE POLICY profile_photos_storage_delete ON storage.objects FOR DELETE TO authenticated USING (((bucket_id = 'profile-photos'::text) AND (owner_id = (( SELECT auth.uid() AS uid))::text) AND (split_part(name, '/'::text, 1) = (( SELECT auth.uid() AS uid))::text)));

CREATE POLICY profile_photos_storage_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'profile-photos'::text) AND (owner_id = (( SELECT auth.uid() AS uid))::text) AND (split_part(name, '/'::text, 1) = (( SELECT auth.uid() AS uid))::text) AND (length(name) > 37)));

CREATE POLICY profile_photos_storage_read ON storage.objects FOR SELECT TO authenticated USING (((bucket_id = 'profile-photos'::text) AND ( SELECT private.zyra_photo_caller_exists() AS zyra_photo_caller_exists) AND (owner_id = split_part(name, '/'::text, 1)) AND (length(name) > 37) AND (public.zyra_can_read_photo_object(name) OR ((owner_id = (( SELECT auth.uid() AS uid))::text) AND private.zyra_photo_not_queued(name)))));

CREATE POLICY profile_photos_storage_update ON storage.objects FOR UPDATE TO authenticated USING (((bucket_id = 'profile-photos'::text) AND (owner_id = (( SELECT auth.uid() AS uid))::text) AND (split_part(name, '/'::text, 1) = (( SELECT auth.uid() AS uid))::text))) WITH CHECK (((bucket_id = 'profile-photos'::text) AND (owner_id = (( SELECT auth.uid() AS uid))::text) AND (split_part(name, '/'::text, 1) = (( SELECT auth.uid() AS uid))::text) AND (length(name) > 37)));

CREATE POLICY profile_videos_storage_delete ON storage.objects FOR DELETE TO authenticated USING (((bucket_id = 'profile-videos'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text)));

CREATE POLICY profile_videos_storage_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'profile-videos'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) AND (name ~ '^[0-9a-f-]{36}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](mp4|mov)$'::text) AND ( SELECT public.zyra_my_paid_access('seeker'::text) AS zyra_my_paid_access) AND storage.allow_any_operation(ARRAY['storage.object.upload'::text]) AND (NOT (EXISTS ( SELECT 1
   FROM public.profile_videos video
  WHERE (video.storage_path = objects.name))))));

CREATE POLICY profile_videos_storage_read ON storage.objects FOR SELECT TO authenticated USING (((bucket_id = 'profile-videos'::text) AND ((((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) AND storage.allow_any_operation(ARRAY['storage.object.get_authenticated'::text, 'object.head_authenticated_info'::text, 'object.get_authenticated_info'::text, 'storage.object.list'::text, 'storage.object.list_v2'::text, 'storage.object.upload'::text, 'storage.object.delete'::text, 'storage.object.delete_many'::text])) OR (storage.allow_any_operation(ARRAY['storage.object.get_authenticated'::text, 'object.head_authenticated_info'::text]) AND public.zyra_can_read_profile_video_object(name)))));

CREATE POLICY zyra_display_photo_writable_delete ON storage.objects AS RESTRICTIVE FOR DELETE TO authenticated USING (((bucket_id <> 'profile-photos'::text) OR private.zyra_unreferenced_photo_path_writable(bucket_id, name)));

CREATE POLICY zyra_display_photo_writable_insert ON storage.objects AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((bucket_id <> 'profile-photos'::text) OR private.zyra_photo_path_writable(bucket_id, name)));

CREATE POLICY zyra_display_photo_writable_update ON storage.objects AS RESTRICTIVE FOR UPDATE TO authenticated USING (((bucket_id <> 'profile-photos'::text) OR private.zyra_unreferenced_photo_path_writable(bucket_id, name))) WITH CHECK (((bucket_id <> 'profile-photos'::text) OR private.zyra_unreferenced_photo_path_writable(bucket_id, name)));

CREATE POLICY zyra_photo_sources_delete ON storage.objects FOR DELETE TO authenticated USING (((bucket_id = 'profile-photo-sources'::text) AND private.zyra_source_photo_path_owned(name, owner_id) AND private.zyra_unreferenced_photo_path_writable(bucket_id, name)));

CREATE POLICY zyra_photo_sources_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'profile-photo-sources'::text) AND private.zyra_source_photo_path_owned(name, owner_id) AND private.zyra_photo_path_writable(bucket_id, name)));

CREATE POLICY zyra_photo_sources_read ON storage.objects FOR SELECT TO authenticated USING (((bucket_id = 'profile-photo-sources'::text) AND private.zyra_source_photo_path_owned(name, owner_id) AND storage.allow_any_operation(ARRAY['storage.object.get_authenticated'::text, 'object.head_authenticated_info'::text, 'object.get_authenticated_info'::text, 'storage.object.list'::text, 'storage.object.list_v2'::text, 'storage.object.upload'::text, 'storage.object.delete'::text, 'storage.object.delete_many'::text])));

-- Fixed onboarding, scoring, unlock gate, and bucket records
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q1', 2);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q10', 4);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q100', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q101', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q102', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q103', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q104', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q11', 6);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q12', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q13', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q14', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q15', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q16', 6);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q17', 6);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q18', 6);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q19', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q2', 3);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q20', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q21', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q22', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q23', 2);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q24', 3);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q25', 2);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q26', 2);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q27', 2);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q28', 2);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q29', 3);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q3', 3);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q30', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q31', 2);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q32', 2);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q33', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q34', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q35', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q36', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q37', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q38', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q39', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q4', 4);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q40', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q41', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q42', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q43', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q44', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q45', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q46', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q47', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q48', 3);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q49', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q5', 4);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q50', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q51', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q52', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q53', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q54', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q55', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q56', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q57', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q58', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q59', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q6', 4);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q60', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q61', 9);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q62', 9);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q63', 6);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q64', 7);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q65', 7);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q66', 7);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q67', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q68', 5);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q69', 7);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q7', 4);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q70', 7);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q71', 7);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q72', 7);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q73', 7);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q74', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q75', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q76', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q77', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q78', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q79', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q8', 4);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q80', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q81', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q82', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q83', 8);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q84', 9);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q85', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q86', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q87', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q88', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q89', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q9', 4);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q90', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q91', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q92', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q93', 11);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q94', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q95', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q96', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q97', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q98', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ch3_q99', 10);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('country_of_birth', 12);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('ethnicity', 12);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('languages', 12);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('nationality', 12);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('revert', 1);
INSERT INTO private.zyra_question_area (question_id, area) VALUES ('sect', 1);
INSERT INTO private.zyra_unlock_release_gate (singleton, plus_spend_enabled) VALUES (true, false);
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q1', 'all', false, '["Never Married", "Separated", "Divorced", "Annulled", "Widowed", "Currently Married"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q10', 'all', false, '["No", "One", "Two", "Three", "Four", "Five or more"]', NULL, NULL, false, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q100', 'all', false, '["Every day", "Several times a week", "Weekly", "Occasionally", "Rarely"]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q101', 'all', false, '["No", "Yes", "I''d prefer to discuss this privately later"]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q102', 'all', false, '["No", "Yes", "I''d prefer to discuss this privately later"]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q103', 'all', false, '["I actively prioritise my health", "I try my best to stay healthy", "I am gradually improving my habits", "I haven''t focused on this much yet"]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q104', 'all', false, '["I''m happy with who I am and ready for marriage.", "I''m always striving to become a better Muslim.", "I''m still growing and improving every day.", "I believe marriage will help me become a better person."]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q11', 'all', false, '["No Formal Qualification", "Secondary School / GCSE", "College / A Levels / Equivalent", "Diploma", "Bachelor''s Degree", "Master''s Degree", "Doctorate (PhD)", "Islamic Studies Qualification", "Other"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q12', 'all', false, '["Under £20,000", "£20,000 – £39,999", "£40,000 – £59,999", "£60,000 – £79,999", "£80,000 – £99,999", "£100,000+"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q13', 'all', false, '["Ready now", "Mostly ready", "Still preparing", "Just beginning my journey"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q14', 'all', false, '["I save consistently", "I save when I can", "I''m just starting to save", "I''m not currently saving"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q15', 'all', false, '["Very organised", "Mostly organised", "Fairly relaxed", "Improving my financial habits"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q16', 'all', false, '["Extremely important", "Important", "Moderately important", "Not a major priority"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q17', 'all', false, '["Full-Time", "Part-Time", "No"]', NULL, NULL, false, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q18', 'all', false, '["I plan to continue working", "I''d prefer to reduce my working hours", "I''d prefer not to work", "It depends on our circumstances"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q19', 'all', false, '["Simple and modest", "Moderate", "Flexible depending on circumstances", "I''d rather discuss it together"]', NULL, NULL, false, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q2', 'all', false, '["No", "Yes, living with me", "Yes, shared custody", "Yes, living elsewhere"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q20', 'all', false, '["No debt", "Mortgage only", "Student finance only", "Personal debt", "Business debt", "Multiple types of debt"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q21', 'all', false, '["Yes", "No", "Planning to in the future"]', NULL, NULL, false, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q22', 'all', false, '["Very careful spender", "Balanced spender", "Enjoy spending when appropriate", "Working on improving my spending habits"]', NULL, NULL, true, 'Education & Finances');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q23', 'all', false, '["As soon as possible", "Within 6 months", "Within 1 year", "Within 2 years", "I''m flexible"]', NULL, NULL, true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q24', 'all', false, '["As soon as possible", "Within 1 year", "Within 2–3 years", "After 3 years", "I''ll decide together with my spouse", "If Allah wills"]', 'ch3_q3', '["No"]', true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q25', 'all', false, '["Monogamous Marriage", "Open to Polygamous Marriage", "Currently in a Polygamous Marriage"]', NULL, NULL, true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q26', 'menOnly', false, '["I only wish to have one wife", "I''m open to more than one wife in the future", "I already have more than one wife", "I''m unsure"]', NULL, NULL, true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q26', 'womenOnly', false, '["I would only marry as the only wife", "I would consider being a first wife in a future polygamous marriage", "I would consider being an additional wife", "I''m unsure"]', NULL, NULL, true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q27', 'all', false, '["To build a righteous Muslim family", "Companionship", "To complete half my Deen", "To have children", "Personal growth and partnership", "All of the above equally"]', NULL, NULL, false, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q28', 'all', false, '["Anywhere", "Within my country", "Internationally", "Only for the right person", "I''d prefer not to relocate"]', NULL, NULL, true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q29', 'all', false, '["I would prefer homeschooling", "I would prefer mainstream schooling", "I would consider either", "I haven''t thought about it yet"]', NULL, NULL, true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q3', 'all', false, '["Yes", "No", "If Allah wills", "Unsure"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q30', 'all', false, '["Very important", "Quite important", "Nice occasionally", "Not particularly important"]', NULL, NULL, true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q31', 'all', false, '["I''d like to move quickly if we''re compatible", "A balanced pace", "I''d prefer to take things slowly", "It depends on the situation"]', NULL, NULL, true, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q32', 'all', false, '["Building a large family", "Building a small close-knit family", "Focusing on serving the community together", "Growing together in faith above all else", "A balanced combination of family, faith and personal growth"]', NULL, NULL, false, 'Marriage Goals');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q33', 'all', false, '["Every prayer, every day", "Usually all five prayers", "Most days", "Occasionally", "I''m working towards praying consistently"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q34', 'all', false, '["Daily", "Several times a week", "Weekly", "Occasionally", "I''m working towards reading more regularly"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q35', 'all', false, '["None yet", "Juz ''Amma (30th Juz)", "1–5 Juz", "6–10 Juz", "11–20 Juz", "More than 20 Juz", "Hafiz / Hafizah"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q36', 'all', false, '["Every year", "Most years", "Sometimes", "I have valid exemptions", "I''m working towards fasting consistently"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q37', 'all', true, '["None", "Mondays", "Thursdays", "Mondays & Thursdays", "White Days (13th, 14th & 15th)", "Day of Arafah", "Ashura", "Six Days of Shawwal", "During Sha''ban", "Other Sunnah Fasts"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q38', 'all', false, '["Always", "Usually", "Sometimes", "I''m still learning about Zakat", "Zakat is not currently due upon me"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q39', 'menOnly', false, '["Every prayer, every day", "Most daily prayers", "Jumu''ah (Friday) only", "Occasionally", "I''m working towards attending more regularly"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q4', 'all', false, '["Very involved", "Some involvement", "Only when needed", "Minimal involvement"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q40', 'all', false, '["Regularly", "Occasionally", "Rarely", "Whenever I have the opportunity"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q41', 'all', false, '["Yes", "No", "Planning to, In Sha'' Allah"]', NULL, NULL, false, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q42', 'all', false, '["Yes", "No", "Planning to when able, In Sha'' Allah", "Not currently able"]', NULL, NULL, false, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q43', 'all', false, '["A major part of my life", "Very important", "Important", "Somewhat important", "I''m trying to improve"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q44', 'all', false, '["Weekly", "Monthly", "Occasionally", "Rarely", "Not currently"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q45', 'all', false, '["Daily", "Several times a week", "Weekly", "Occasionally", "Rarely"]', NULL, NULL, false, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q46', 'all', false, '["Hanafi", "Maliki", "Shafi''i", "Hanbali", "I benefit from all recognised Madhhabs", "I''m still learning"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q47', 'all', false, '["I completely avoid them", "I avoid them whenever possible", "I''m currently trying to move away from them", "I''m still learning about this topic"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q48', 'all', false, '["Essential", "Very important", "Important", "Somewhat important"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q49', 'all', false, '["Regularly", "Occasionally", "Rarely", "I''m working towards it"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q5', 'all', false, '["Daily", "Weekly", "Fortnightly", "Monthly", "Occasionally", "Rarely"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q50', 'all', false, '["Daily", "Most days", "Occasionally", "Rarely", "I''m working towards making it a habit"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q51', 'all', false, '["I avoid both pictures and statues", "I avoid statues but accept photographs", "I don''t mind either", "I''m still learning about this topic"]', NULL, NULL, true, 'Faith');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q52', 'all', false, '["I don''t smoke or vape", "I vape only", "I smoke only", "I both smoke and vape", "I''m trying to quit"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q53', 'all', false, '["I never drink alcohol", "I previously drank but no longer do", "I''m trying to stop drinking"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q54', 'all', false, '["I only eat Halal food", "I always avoid pork and alcohol, but Halal is not always available", "I''m improving in this area"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q55', 'all', false, '["I completely avoid music", "I mostly avoid music", "I listen occasionally", "I''m still learning about this topic"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q56', 'all', false, '["Very active", "Active", "Occasionally active", "Rarely active", "I''m working on becoming more active"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q57', 'all', false, '["I enjoy having pets", "I''m happy either way", "I''d prefer not to have pets", "It depends on the type of pet"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q58', 'all', false, '["Very tidy and organised", "Generally tidy", "Fairly relaxed", "I''m working on becoming more organised"]', NULL, NULL, false, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q59', 'all', false, '["Early bird", "Mostly an early bird", "Night owl", "It depends on my schedule"]', NULL, NULL, false, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q6', 'all', false, '["Same home", "Same neighbourhood", "Same city", "Same country", "No preference"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q60', 'all', false, '["I love hosting", "I''m happy to host occasionally", "Only for close family", "I''d rather keep things private"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q61', 'all', false, '["Introvert", "Ambivert", "Extrovert"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q62', 'all', true, '["Spending time with family", "Spending time with friends", "Reading", "Islamic learning", "Sports & Fitness", "Travelling", "Nature & Outdoors", "Gaming", "Cooking & Baking", "Volunteering", "Arts & Creativity", "Learning new skills", "Relaxing at home"]', NULL, NULL, false, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q63', 'all', false, '["Family always comes first", "I try to balance family and career equally", "Career is my current priority", "It depends on my stage of life"]', NULL, NULL, true, 'Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q64', 'all', false, '["Mostly traditional roles", "Shared equally", "Based on each person''s circumstances", "Flexible depending on our situation", "We''ll decide together as our marriage develops"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q65', 'all', false, '["I enjoy cooking regularly", "I don''t mind cooking", "I''d prefer to share cooking responsibilities", "I''d rather cook only occasionally", "It depends on our circumstances"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q66', 'all', false, '["Shared equally", "Mostly by me", "Mostly by my spouse", "Whoever has more time", "We would consider hiring help if possible"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q67', 'all', false, '["Husband", "Mostly husband, but both may contribute", "Shared responsibility", "Depends on our circumstances"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q68', 'all', false, '["Completely shared finances", "Mostly shared with some personal finances", "Mostly separate finances", "We''d decide together after marriage"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q69', 'all', false, '["I''d definitely consider it", "Only if genuinely needed", "Only occasionally", "I''d rather manage ourselves"]', NULL, NULL, false, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q7', 'all', false, '["Yes, regularly", "Occasionally", "Not currently"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q70', 'all', false, '["Joint discussion before every major decision", "Husband leads after discussion", "Depends on the situation", "Every decision should be mutual"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q71', 'all', false, '["Quiet and peaceful", "Family-centred and lively", "Frequently hosting guests", "A balance of both"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q72', 'all', false, '["Highly structured", "Fairly organised", "Flexible", "I prefer not to follow a routine"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q73', 'all', false, '["Very important", "Important", "Somewhat important", "I prefer spending most of my time together"]', NULL, NULL, true, 'Household Roles & Expectations');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q74', 'all', false, '["Open and direct", "Calm and thoughtful", "Quiet until I''m comfortable", "It depends on the situation"]', NULL, NULL, true, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q75', 'all', false, '["I prefer to resolve things immediately", "I like some time to think before talking", "I stay calm and discuss it later", "It depends on the situation"]', NULL, NULL, true, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q76', 'all', false, '["I apologise quickly when I''m wrong", "I prefer to talk things through first", "I need time before apologising", "It depends on the situation"]', NULL, NULL, false, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q77', 'all', false, '["Very comfortable", "Comfortable", "Somewhat comfortable", "I find them difficult but I am improving"]', NULL, NULL, false, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q78', 'all', false, '["After discussing everything together", "I like taking the lead after discussion", "I prefer my spouse to lead after discussion", "It depends on the situation"]', NULL, NULL, true, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q79', 'all', false, '["I appreciate honest feedback", "I need a little time to process it", "It depends how it''s delivered", "I''m working on becoming more open"]', NULL, NULL, false, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q8', 'all', false, '["I expect us both to help", "I would mainly take responsibility", "I''d support where possible", "It depends on the circumstances"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q80', 'all', false, '["Very often", "Quite often", "Occasionally", "I''m trying to improve"]', NULL, NULL, false, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q81', 'all', false, '["Islamic mediation", "Professional marriage counselling", "Family mediation", "A combination depending on the situation"]', NULL, NULL, true, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q82', 'all', false, '["Extremely important", "Very important", "Somewhat important", "I''m still developing this mindset"]', NULL, NULL, false, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q83', 'all', false, '["I forgive quickly", "I usually forgive after discussion", "It takes me time", "It depends on the situation"]', NULL, NULL, false, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q84', 'all', false, '["Essential", "Very important", "Important", "Nice when possible"]', NULL, NULL, true, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q85', 'all', false, '["Completely private", "Mostly private", "Comfortable sharing major milestones", "Fairly open with close family and friends"]', NULL, NULL, true, 'Communication & Emotional Intelligence');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q86', 'all', false, '["I don''t use social media", "Private accounts for family and friends only", "Active but mostly private", "Public and regularly active"]', NULL, NULL, true, 'Technology & Digital Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q87', 'all', false, '["I prefer to keep everything private", "I am happy sharing major milestones only", "Occasionally sharing is fine", "I am comfortable sharing regularly"]', NULL, NULL, true, 'Technology & Digital Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q88', 'all', false, '["Very little", "Moderate", "Quite a lot", "It varies depending on the day"]', NULL, NULL, false, 'Technology & Digital Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q89', 'all', false, '["I prefer technology only when necessary", "I enjoy a balanced use of technology", "I enjoy using technology regularly", "Technology is a major part of my lifestyle"]', NULL, NULL, false, 'Technology & Digital Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q9', 'all', false, '["Yes", "For a short period only", "Only if necessary", "No"]', NULL, NULL, true, 'Family');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q90', 'all', false, '["Extremely important", "Very important", "Important", "I haven''t really thought about it"]', NULL, NULL, true, 'Technology & Digital Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q91', 'all', false, '["I don''t play games", "Occasionally", "Weekly", "Most days"]', NULL, NULL, false, 'Technology & Digital Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q92', 'all', false, '["Rarely", "Occasionally", "Weekly", "Most days"]', NULL, NULL, false, 'Technology & Digital Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q93', 'all', false, '["Daily", "Several times a week", "Weekly", "Occasionally", "Rarely"]', NULL, NULL, false, 'Technology & Digital Lifestyle');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q94', 'all', false, '["Excellent", "Good", "Fair", "I''m working on improving it"]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q95', 'all', false, '["Extremely important", "Very important", "Moderately important", "I''m trying to make it more important"]', NULL, NULL, true, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q96', 'all', false, '["Very healthy", "Mostly healthy", "Fairly balanced", "I''m working on improving my diet"]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q97', 'all', true, '["None", "Vegetarian", "Vegan", "Gluten Free", "Dairy Free", "Nut Allergy", "Seafood Allergy", "Other Food Allergy"]', NULL, NULL, true, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q98', 'all', false, '["Very consistent", "Mostly consistent", "Irregular due to work or study", "I''m working on improving my routine"]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO public.zyra_onboarding_questions (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored, category) VALUES ('ch3_q99', 'all', false, '["Worship and Du''a", "Talking with family or friends", "Exercise", "Quiet time and reflection", "Keeping busy", "A combination of these"]', NULL, NULL, false, 'Health & Well-being');
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES ('profile-photo-sources', 'profile-photo-sources', false, 8388608, '{image/jpeg}');
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES ('profile-photos', 'profile-photos', false, NULL, NULL);
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES ('profile-videos', 'profile-videos', false, 20971520, '{video/mp4,video/quicktime}');

-- Keep ordinary message delivery in the platform Realtime publication.
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- Account deletion needs the profile cleanup to run before the trial FK action.
-- Abort the install if the target assigns names in a different order.
DO $auth_delete_order$
DECLARE
    profile_first boolean;
BEGIN
    SELECT profile_trigger.tgname::text COLLATE "C" < trial_trigger.tgname::text COLLATE "C"
    INTO profile_first
    FROM pg_catalog.pg_trigger profile_trigger
    JOIN pg_catalog.pg_constraint profile_fk ON profile_fk.oid = profile_trigger.tgconstraint
    JOIN pg_catalog.pg_trigger trial_trigger ON trial_trigger.tgrelid = profile_trigger.tgrelid
    JOIN pg_catalog.pg_constraint trial_fk ON trial_fk.oid = trial_trigger.tgconstraint
    WHERE profile_trigger.tgrelid = 'auth.users'::regclass
      AND (profile_trigger.tgtype & 8) <> 0
      AND (trial_trigger.tgtype & 8) <> 0
      AND profile_fk.conrelid = 'public.profiles'::regclass
      AND profile_fk.conname = 'profiles_id_fkey'
      AND trial_fk.conrelid = 'private.seeker_trial_ledger'::regclass
      AND trial_fk.conname = 'seeker_trial_ledger_claimed_by_fkey';

    IF profile_first IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Auth account deletion must clear the profile before the Seeker trial FK runs';
    END IF;
END;
$auth_delete_order$;

COMMIT;
