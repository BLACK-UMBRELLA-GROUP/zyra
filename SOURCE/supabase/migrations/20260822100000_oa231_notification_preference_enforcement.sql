-- OA-ZYRA-231 — enforce notification preferences at the one creation door.
--
-- Callers remain unchanged. A type is resolved to its consent category here,
-- the latest append-only preference (ordered by seq) wins, and the database
-- defaults apply when no preference row exists. Security/Account types map to
-- NULL and are deliberately unsuppressible. An unknown type raises instead of
-- silently bypassing consent, so a future caller cannot forget the mapping.

create or replace function public.zyra_notification_category(p_type text)
returns text
language plpgsql
immutable
set search_path to 'public'
as $function$
declare
  v_category text;
begin
  if p_type in ('new_device_signin', 'password_changed', 'account_action') then
    return null;
  end if;

  v_category := case p_type
    -- Matches and Journeys.
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

    -- Guardian Activity, including the OA-ZYRA-232 lifecycle types.
    when 'wali_request' then 'guardian_activity'
    when 'wali_invite_received' then 'guardian_activity'
    when 'wali_invite_declined' then 'guardian_activity'
    when 'wali_invite_expiring' then 'guardian_activity'
    when 'wali_invite_expired' then 'guardian_activity'
    when 'wali_invite_revoked' then 'guardian_activity'
    when 'family_review_opened' then 'guardian_activity'
    when 'family_review_due' then 'guardian_activity'
    when 'guardian_digest' then 'guardian_activity'

    -- Introductions.
    when 'introduction_received' then 'introductions'
    when 'introduction_answered' then 'introductions'

    -- Product/marketing consent categories.
    when 'entitlement_changed' then 'product_updates'
    when 'credits_low' then 'product_updates'

    else null
  end;

  if v_category is null then
    raise exception 'unknown_notification_type: %', p_type
      using errcode = '22023';
  end if;
  return v_category;
end;
$function$;

revoke execute on function public.zyra_notification_category(text)
  from public, anon, authenticated;
grant execute on function public.zyra_notification_category(text)
  to service_role;

create or replace function public.create_notification(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_related_match_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_category text;
  v_enabled boolean;
begin
  v_category := public.zyra_notification_category(p_type);

  if v_category is not null then
    select p.enabled
      into v_enabled
      from public.notification_preferences p
     where p.user_id = p_user_id
       and p.category = v_category
     order by p.seq desc
     limit 1;

    if v_enabled is null then
      v_enabled := case v_category
        when 'marketing_emails' then false
        when 'product_updates' then false
        else true
      end;
    end if;

    if not v_enabled then
      return;
    end if;
  end if;

  insert into public.notifications
    (user_id, type, title, body, related_match_id)
  values
    (p_user_id, p_type, p_title, p_body, p_related_match_id);
end;
$function$;

revoke execute on function public.create_notification(uuid, text, text, text, uuid)
  from public, anon, authenticated;
grant execute on function public.create_notification(uuid, text, text, text, uuid)
  to service_role;
