


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "private";


ALTER SCHEMA "private" OWNER TO "postgres";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "private"."zyra_enforce_personal_request_owner_acceptance"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "private"."zyra_enforce_personal_request_owner_acceptance"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."zyra_generate_personal_code"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "private"."zyra_generate_personal_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."zyra_identity_verification_allows_user"("p_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "private"."zyra_identity_verification_allows_user"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."zyra_normalize_personal_code"("p_code" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO ''
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


ALTER FUNCTION "private"."zyra_normalize_personal_code"("p_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."zyra_retire_personal_code"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "private"."zyra_retire_personal_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."zyra_touch_identity_verification_attempt"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'private'
    AS $$
begin
  new.updated_at := now();
  return new;
end;
$$;


ALTER FUNCTION "private"."zyra_touch_identity_verification_attempt"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."accept_wali_invite"("p_token" "text", "p_relationship" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_invite wali_invites%ROWTYPE;
  v_accepter_id UUID := auth.uid();
  v_accepter_role TEXT;
  v_inviter_role TEXT;
  v_accepter_name TEXT;
  v_seeker_id UUID;
  v_wali_id UUID;
  v_link_id UUID;
  v_relationship TEXT;
  v_live_status TEXT;
BEGIN
  IF v_accepter_id IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;

  IF p_relationship IS NOT NULL
     AND p_relationship NOT IN ('father','brother','grandfather','uncle',
                                'legal_guardian','family_representative','other') THEN
    RAISE EXCEPTION 'Unknown relationship: %', p_relationship;
  END IF;

  SELECT * INTO v_invite FROM wali_invites WHERE token = p_token AND status = 'pending';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invite not found or already used';
  END IF;

  -- ── EXPIRY, 2026-08-09, audit finding 2.6. Was enforced ONLY in
  -- preview_wali_invite, which the client was trusted to call first, so a
  -- direct call to this RPC ignored the 7-day deadline entirely.
  --
  -- expire_wali_invite_if_due() is used as a PREDICATE, to keep one
  -- definition of "expired" (I3). Its UPDATE does not survive: the RAISE
  -- below aborts this function and rolls it back. Marking the row is
  -- preview_wali_invite's job, not this one.
  v_live_status := expire_wali_invite_if_due(v_invite);
  IF v_live_status <> 'pending' THEN
    RAISE EXCEPTION 'invite_expired'
      USING HINT = 'This invite has expired. Ask for a new code.';
  END IF;

  IF v_invite.inviter_id = v_accepter_id THEN
    RAISE EXCEPTION 'Cannot accept your own invite';
  END IF;

  SELECT role INTO v_accepter_role FROM profiles WHERE id = v_accepter_id;
  IF v_accepter_role IS NULL THEN
    RAISE EXCEPTION 'Complete your profile before accepting an invite';
  END IF;

  -- ── SECURITY 2026-08-09, audit finding 2.1. The inviter's role comes
  -- from profiles, NOT from wali_invites.inviter_role, which the client
  -- writes and can therefore lie about.
  SELECT role INTO v_inviter_role FROM profiles WHERE id = v_invite.inviter_id;
  IF v_inviter_role IS NULL THEN
    RAISE EXCEPTION 'Invite is no longer valid';
  END IF;
  IF v_inviter_role IS DISTINCT FROM v_invite.inviter_role THEN
    RAISE EXCEPTION 'invite_role_mismatch'
      USING HINT = 'This invite does not match the account that sent it. '
                   'Ask them to send a new one.';
  END IF;

  -- WHO may be a Guardian. Still role-based, still gated on the outstanding
  -- gender governance review. Distinct from the romantic-conflict question
  -- below, which is now zyra_can_guardian_link()'s job.
  IF v_inviter_role = 'seeker' THEN
    IF v_accepter_role <> 'wali' THEN
      RAISE EXCEPTION 'This invite is for a Wali account';
    END IF;
    v_seeker_id := v_invite.inviter_id;
    v_wali_id := v_accepter_id;
  ELSIF v_inviter_role = 'wali' THEN
    IF v_accepter_role <> 'seeker' THEN
      RAISE EXCEPTION 'This invite is for a Seeker account';
    END IF;
    v_seeker_id := v_accepter_id;
    v_wali_id := v_invite.inviter_id;
  ELSE
    RAISE EXCEPTION 'Invalid invite';
  END IF;

  -- One predicate, one place. Was an inline EXISTS here until 2026-08-07.
  IF NOT public.zyra_can_guardian_link(v_seeker_id, v_wali_id) THEN
    RAISE EXCEPTION 'romantic_edge_exists'
      USING HINT = 'These two people have a Journey together. A Guardian '
                   'relationship cannot be created over one. End the Journey '
                   'first if that is really what you both want.';
  END IF;

  v_relationship := COALESCE(p_relationship, v_invite.relationship);

  SELECT id INTO v_link_id FROM wali_links WHERE seeker_id = v_seeker_id AND wali_id = v_wali_id;
  IF v_link_id IS NULL THEN
    INSERT INTO wali_links (seeker_id, wali_id, status, relationship)
      VALUES (v_seeker_id, v_wali_id, 'active', v_relationship)
      RETURNING id INTO v_link_id;
  ELSE
    UPDATE wali_links
       SET status = 'active',
           relationship = COALESCE(v_relationship, relationship)
     WHERE id = v_link_id;
  END IF;

  -- ── ARCHITECTURAL RULE, not housekeeping. Founder-ratified 2026-08-07.
  --
  --   "Forming a Guardian bond extinguishes any one-sided romantic intent
  --    between the two people, in both directions, silently and
  --    permanently."
  --
  -- WHY CLEARED RATHER THAN REFUSED. Refusing a Guardian link because a
  -- Like exists would let anyone veto a Guardian relationship they are not
  -- part of, simply by Liking one of the parties — one denial-of-service
  -- traded for another. A MATCH is different: mutual, stateful, and
  -- refused above.
  --
  -- WHY SILENTLY. Telling Alice "your Save of Bob was removed" discloses
  -- that she had saved him, to a screen her new Guardian may be looking at.
  -- The disclosure is worse than the surprise.
  --
  -- WHY PERMANENTLY. Removing the Guardian link later does not restore
  -- them. Interest is a present-tense act; resurrecting a year-old Like
  -- would be inventing intent nobody expressed.
  --
  -- A future developer wondering why a Save vanished on its own should find
  -- this comment, ZYRA_GUARDIAN_ROMANTIC_RULES_CURRENT_VERSION_V1.md, or
  -- both.
  DELETE FROM likes  WHERE (liker_id  = v_seeker_id AND liked_id  = v_wali_id)
                        OR (liker_id  = v_wali_id   AND liked_id  = v_seeker_id);
  DELETE FROM saves  WHERE (saver_id  = v_seeker_id AND saved_id  = v_wali_id)
                        OR (saver_id  = v_wali_id   AND saved_id  = v_seeker_id);
  DELETE FROM passes WHERE (passer_id = v_seeker_id AND passed_id = v_wali_id)
                        OR (passer_id = v_wali_id   AND passed_id = v_seeker_id);

  UPDATE wali_invites SET status = 'accepted', accepted_at = NOW(), accepted_by = v_accepter_id WHERE id = v_invite.id;

  SELECT first_name INTO v_accepter_name FROM profiles WHERE id = v_accepter_id;
  PERFORM create_notification(
    v_invite.inviter_id, 'wali_request', 'Wali Link Accepted',
    COALESCE(v_accepter_name, 'Someone') || ' accepted your Wali link invite.', NULL
  );

  RETURN v_link_id;
END;
$$;


ALTER FUNCTION "public"."accept_wali_invite"("p_token" "text", "p_relationship" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ages_for"("p_ids" "uuid"[]) RETURNS TABLE("id" "uuid", "age" integer)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  -- CAP ADDED 2026-08-08 (I10). 50 = Browse's page size, so every
  -- legitimate caller fits. A caller needing more is enumerating.
  if p_ids is null or array_length(p_ids, 1) is null then
    return;
  end if;
  if array_length(p_ids, 1) > 50 then
    raise exception 'ages_for_batch_too_large'
      using hint = 'Maximum 50 ids per call. Page the request, or use ages_for_one().';
  end if;

  return query
    select p.id, date_part('year', age(p.date_of_birth))::int
    from public.profiles p
    where p.id = any(p_ids)
      and public.zyra_can_view_profile(p.id);
end;
$$;


ALTER FUNCTION "public"."ages_for"("p_ids" "uuid"[]) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."ages_for"("p_ids" "uuid"[]) IS 'Batch age lookup, HARD CAPPED AT 50 ids (I10, 2026-08-08) — it is a visibility oracle in proportion to its batch size. Use ages_for_one() for a single id. Do not raise the cap without revisiting I10.';



CREATE OR REPLACE FUNCTION "public"."ages_for_one"("p_id" "uuid") RETURNS integer
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select date_part('year', age(p.date_of_birth))::int
  from public.profiles p
  where p.id = p_id
    and public.zyra_can_view_profile(p.id);
$$;


ALTER FUNCTION "public"."ages_for_one"("p_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."ages_for_one"("p_id" "uuid") IS 'Single-id age lookup. Prefer this over ages_for(uuid[]) wherever the caller has one id — one visibility hypothesis per call (I10). Returns NULL when the caller may not view the target, which is indistinguishable from a missing date of birth.';



CREATE OR REPLACE FUNCTION "public"."auto_designate_main_wali"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."auto_designate_main_wali"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."auto_designate_main_wali"() IS 'DR-ZYRA-225/233. Preserves first-active-link Main designation; maintains the Main-assignment epoch; and maintains a separate role-neutral active-link epoch for per-Guardian past-summary permission. The link epoch rotates on activation/reactivation, survives continuous Main/Additional switches, and is null while inactive.';



CREATE OR REPLACE FUNCTION "public"."create_conversation_started_milestone"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE v_timeline_id UUID; v_already_exists BOOLEAN;
BEGIN
  SELECT t.id INTO v_timeline_id
  FROM conversations c
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


ALTER FUNCTION "public"."create_conversation_started_milestone"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_match_on_mutual_like"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."create_match_on_mutual_like"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_type" "text", "p_title" "text", "p_body" "text", "p_related_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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
$$;


ALTER FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_type" "text", "p_title" "text", "p_body" "text", "p_related_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_own_account"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller UUID := auth.uid();
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;

  PERFORM set_config('storage.allow_delete_query', 'true', true);
  DELETE FROM storage.objects
  WHERE bucket_id = 'profile-photos' AND name LIKE caller::text || '/%';

  DELETE FROM auth.users WHERE id = caller;
END;
$$;


ALTER FUNCTION "public"."delete_own_account"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."end_journey"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE m RECORD; caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;
  PERFORM public.zyra_end_match_internal(p_match_id, caller, NULL);
END; $$;


ALTER FUNCTION "public"."end_journey"("p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."end_journey"("p_match_id" "uuid", "p_reason" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE m RECORD; caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;

  -- 'no_response' is a SYSTEM ending: matches_no_response_is_system
  -- requires ended_by IS NULL, and this path always has a caller.
  -- Refused here so the caller gets a reason rather than a constraint.
  IF p_reason = 'no_response' THEN
    RAISE EXCEPTION 'reason_is_system_only'
      USING HINT = 'no_response is recorded by the system, not chosen by a person.';
  END IF;
  IF p_reason IS NOT NULL AND p_reason NOT IN
     ('not_compatible','circumstances_changed','marrying_elsewhere',
      'family_decision','safety_concern','prefer_not_to_say') THEN
    RAISE EXCEPTION 'unknown_end_reason: %', p_reason;
  END IF;

  -- safety_concern is permitted here: someone may feel unsafe without
  -- wanting to block. Step 0 already conceals it from everyone except the
  -- person who raised it, and matches_no_note_on_safety_ending forbids an
  -- accompanying note. No new disclosure.
  PERFORM public.zyra_end_match_internal(p_match_id, caller, p_reason);
END; $$;


ALTER FUNCTION "public"."end_journey"("p_match_id" "uuid", "p_reason" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."wali_invites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "token" "text" DEFAULT "upper"("encode"("extensions"."gen_random_bytes"(4), 'hex'::"text")) NOT NULL,
    "inviter_id" "uuid" NOT NULL,
    "inviter_role" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "accepted_at" timestamp with time zone,
    "accepted_by" "uuid",
    "expires_at" timestamp with time zone DEFAULT ("now"() + '7 days'::interval) NOT NULL,
    "label" "text",
    "relationship" "text",
    "expiring_notified_at" timestamp with time zone,
    "seen_by" "uuid",
    "seen_at" timestamp with time zone,
    "declined_by" "uuid",
    "declined_at" timestamp with time zone,
    "source" "text" DEFAULT 'legacy_code'::"text" NOT NULL,
    "personal_code_id" "uuid",
    "recipient_id" "uuid",
    "request_expires_at" timestamp with time zone,
    "cancelled_at" timestamp with time zone,
    CONSTRAINT "wali_invites_declined_pair" CHECK ((("declined_by" IS NULL) = ("declined_at" IS NULL))),
    CONSTRAINT "wali_invites_inviter_role_check" CHECK (("inviter_role" = ANY (ARRAY['seeker'::"text", 'wali'::"text"]))),
    CONSTRAINT "wali_invites_label_length" CHECK ((("label" IS NULL) OR ("char_length"("label") <= 40))),
    CONSTRAINT "wali_invites_personal_request_shape" CHECK ((("source" <> 'personal_code'::"text") OR (("personal_code_id" IS NOT NULL) AND ("recipient_id" IS NOT NULL) AND ("request_expires_at" IS NOT NULL) AND ("token" IS NOT NULL)))),
    CONSTRAINT "wali_invites_relationship_check" CHECK ((("relationship" IS NULL) OR ("relationship" = ANY (ARRAY['father'::"text", 'brother'::"text", 'grandfather'::"text", 'uncle'::"text", 'legal_guardian'::"text", 'family_representative'::"text", 'other'::"text"])))),
    CONSTRAINT "wali_invites_relationship_owner_check" CHECK ((("relationship" IS NULL) OR (("source" = 'legacy_code'::"text") AND ("inviter_role" = 'wali'::"text")) OR ("source" = 'personal_code'::"text"))),
    CONSTRAINT "wali_invites_seen_pair" CHECK ((("seen_by" IS NULL) = ("seen_at" IS NULL))),
    CONSTRAINT "wali_invites_source_check" CHECK (("source" = ANY (ARRAY['legacy_code'::"text", 'personal_code'::"text"]))),
    CONSTRAINT "wali_invites_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'declined'::"text", 'revoked'::"text", 'expired'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."wali_invites" OWNER TO "postgres";


COMMENT ON COLUMN "public"."wali_invites"."token" IS 'OWNERSHIP: row-scoped(inviter_id) — a live credential while unredeemed. Never export a usable token.';



COMMENT ON COLUMN "public"."wali_invites"."inviter_id" IS 'OWNERSHIP: row-scoped(inviter_id)';



COMMENT ON COLUMN "public"."wali_invites"."inviter_role" IS 'OWNERSHIP: row-scoped(inviter_id)';



COMMENT ON COLUMN "public"."wali_invites"."status" IS 'OWNERSHIP: row-scoped(inviter_id)';



COMMENT ON COLUMN "public"."wali_invites"."accepted_at" IS 'OWNERSHIP: joint(inviter_id, accepted_by)';



COMMENT ON COLUMN "public"."wali_invites"."accepted_by" IS 'OWNERSHIP: joint(inviter_id, accepted_by)';



COMMENT ON COLUMN "public"."wali_invites"."expires_at" IS 'OWNERSHIP: row-scoped(inviter_id)';



COMMENT ON COLUMN "public"."wali_invites"."label" IS 'OWNERSHIP: row-scoped(inviter_id) — the sender''s private note for who this code was intended for ("Dad", "Uncle Ibrahim"). Never shown to the recipient and never returned by preview_wali_invite. Not an identity claim: whoever redeems the code becomes the Guardian regardless.';



COMMENT ON COLUMN "public"."wali_invites"."relationship" IS 'OWNERSHIP: row-scoped(inviter_id) — the inviting Guardian''s statement about themselves ("I am her father"), carried onto wali_links.relationship when the Seeker accepts. Null for Seeker-sent invites, where the Guardian is asked at acceptance instead. Per LINK, not per account.';



COMMENT ON COLUMN "public"."wali_invites"."expiring_notified_at" IS 'One-shot marker for the day-5 Guardian invitation reminder.';



COMMENT ON COLUMN "public"."wali_invites"."seen_by" IS 'First authenticated bearer who previewed this manual invite code. Used only to send received/revoked lifecycle notifications; not proof that the sender intended the code for this person.';



COMMENT ON COLUMN "public"."wali_invites"."recipient_id" IS 'For source=personal_code, the authenticated requester. The code owner is inviter_id. A link is never created until the owner accepts.';



COMMENT ON COLUMN "public"."wali_invites"."request_expires_at" IS 'Thirty-day request clock for addressed personal-code requests. The legacy seven-day bearer-code expires_at contract is unchanged.';



CREATE OR REPLACE FUNCTION "public"."expire_wali_invite_if_due"("p_invite" "public"."wali_invites") RETURNS "text"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
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
      perform public.create_notification(
        p_invite.inviter_id,
        'wali_invite_expired',
        'Guardian invitation expired',
        case when v_label is null
          then 'A Guardian invitation expired.'
          else v_label || '''s Guardian invitation expired.'
        end,
        null
      );
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


ALTER FUNCTION "public"."expire_wali_invite_if_due"("p_invite" "public"."wali_invites") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."grant_zyra_one_credits"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."grant_zyra_one_credits"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."guardians_for_unlocked"("p_target" "uuid") RETURNS TABLE("first_name" "text", "gender" "text", "location_text" "text", "is_main" boolean, "relationship" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."guardians_for_unlocked"("p_target" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_article9_consent"() RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."has_article9_consent"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mock_purchase_wali_premium"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller UUID := auth.uid();
  caller_role TEXT;
  updated INT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;

  -- ADDED 2026-08-01 (C4b): seeded test accounts only.
  IF NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = caller AND u.email LIKE '%@zyra.test'
  ) THEN
    RAISE EXCEPTION 'mock_purchase_disabled'
      USING HINT = 'Mock purchases are limited to seeded test accounts. Real payment processing is not built yet.';
  END IF;

  SELECT role INTO caller_role FROM profiles WHERE id = caller;
  IF caller_role IS DISTINCT FROM 'wali' THEN
    RAISE EXCEPTION 'Extended Wali is a Wali-account entitlement';
  END IF;

  UPDATE subscriptions SET plan_type = 'wali_premium' WHERE user_id = caller AND status = 'active';
  GET DIAGNOSTICS updated = ROW_COUNT;
  IF updated = 0 THEN
    INSERT INTO subscriptions (user_id, plan_type, status) VALUES (caller, 'wali_premium', 'active');
  END IF;
END;
$$;


ALTER FUNCTION "public"."mock_purchase_wali_premium"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mock_set_wali_plan"("p_plan" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller UUID := auth.uid();
  caller_role TEXT;
  updated INT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;
  IF p_plan NOT IN ('wali_basic', 'wali_premium') THEN
    RAISE EXCEPTION 'invalid plan';
  END IF;

  -- ADDED 2026-08-01 (C4b): seeded test accounts only.
  IF NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = caller AND u.email LIKE '%@zyra.test'
  ) THEN
    RAISE EXCEPTION 'mock_purchase_disabled'
      USING HINT = 'Developer plan switching is limited to seeded test accounts.';
  END IF;

  SELECT role INTO caller_role FROM profiles WHERE id = caller;
  IF caller_role IS DISTINCT FROM 'wali' THEN
    RAISE EXCEPTION 'Wali-only';
  END IF;

  UPDATE subscriptions SET plan_type = p_plan WHERE user_id = caller AND status = 'active';
  GET DIAGNOSTICS updated = ROW_COUNT;
  IF updated = 0 THEN
    INSERT INTO subscriptions (user_id, plan_type, status) VALUES (caller, p_plan, 'active');
  END IF;
END;
$$;


ALTER FUNCTION "public"."mock_set_wali_plan"("p_plan" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_new_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."notify_new_message"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."nudge_paused_journey"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare m record; caller uuid := auth.uid(); v_name text;
begin
  if caller is null then raise exception 'not_signed_in'; end if;
  select * into m from matches where id = p_match_id;
  if not found then raise exception 'match not found'; end if;
  if caller <> m.seeker_a_id and caller <> m.seeker_b_id then
    raise exception 'not a party to this match';
  end if;
  if m.status <> 'active' or m.suspended_by is null then
    raise exception 'journey_not_paused';
  end if;
  if caller is not distinct from m.suspended_by
     or caller is not distinct from m.also_paused_by then
    raise exception 'pauser_cannot_nudge';
  end if;
  if m.pause_nudged_at is not null then
    raise exception 'already_nudged'
      using hint = 'One nudge per pause — they already know you are ready.';
  end if;

  update matches set pause_nudged_at = now() where id = p_match_id;

  select first_name into v_name from profiles where id = caller;
  perform create_notification(
    m.suspended_by, 'pause_nudge', 'Whenever you are ready',
    coalesce(v_name, 'They') || ' is ready to continue, whenever you are.',
    p_match_id);
end $$;


ALTER FUNCTION "public"."nudge_paused_journey"("p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."open_family_review"("p_match_id" "uuid", "p_from_stage" "text", "p_to_stage" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  v_attempt UUID;
  v_expected_to TEXT;
  existing_id UUID;
  new_id UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id FOR UPDATE;
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


ALTER FUNCTION "public"."open_family_review"("p_match_id" "uuid", "p_from_stage" "text", "p_to_stage" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."preview_wali_invite"("p_token" "text") RETURNS TABLE("inviter_first_name" "text", "inviter_role" "text", "invite_status" "text", "inviter_ward_count" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_invite public.wali_invites%rowtype;
  v_status text;
  v_viewer uuid := auth.uid();
  v_inviter_name text;
begin
  select * into v_invite
    from public.wali_invites wi
   where wi.token = upper(trim(p_token));
  if not found then return; end if;

  v_status := public.expire_wali_invite_if_due(v_invite);
  select p.first_name into v_inviter_name
    from public.profiles p where p.id = v_invite.inviter_id;

  if v_status = 'pending'
     and v_viewer is not null
     and v_viewer <> v_invite.inviter_id then
    update public.wali_invites
       set seen_by = v_viewer,
           seen_at = clock_timestamp()
     where id = v_invite.id
       and status = 'pending'
       and seen_by is null;

    if found then
      perform public.create_notification(
        v_viewer,
        'wali_invite_received',
        'Guardian invitation received',
        coalesce(v_inviter_name, 'Someone') || ' sent you a Guardian invitation.',
        null
      );
    end if;
  end if;

  return query
  select v_inviter_name,
         v_invite.inviter_role,
         v_status,
         (select count(distinct wl.seeker_id)::integer
            from public.wali_links wl
           where wl.wali_id = v_invite.inviter_id
             and wl.status = 'active');
end;
$$;


ALTER FUNCTION "public"."preview_wali_invite"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."promote_journey_to_active"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE m RECORD; caller UUID := auth.uid(); v_attempt UUID; v_party UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
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


ALTER FUNCTION "public"."promote_journey_to_active"("p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reopen_family_review"("p_review_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  r RECORD;
  m RECORD;
  caller UUID := auth.uid();
  is_authorised_wali BOOLEAN;
BEGIN
  SELECT * INTO r FROM journey_family_reviews WHERE id = p_review_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'review not found'; END IF;
  IF r.status <> 'paused' THEN RAISE EXCEPTION 'review is not paused'; END IF;
  IF r.attempt_id IS NULL THEN RAISE EXCEPTION 'review_has_no_attempt'; END IF;

  SELECT mm.* INTO m FROM journey_attempts a
    JOIN matches mm ON mm.id = a.match_id
   WHERE a.id = r.attempt_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'attempt not found'; END IF;

  -- UNCHANGED authorisation.
  SELECT EXISTS (
    SELECT 1 FROM wali_links
    WHERE wali_id = caller AND status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)
  ) INTO is_authorised_wali;
  IF caller IS NULL OR NOT is_authorised_wali THEN
    RAISE EXCEPTION 'not an authorised Wali for this Journey';
  END IF;

  DELETE FROM journey_family_review_responses WHERE review_id = p_review_id;
  UPDATE journey_family_reviews
    SET status = 'pending', opened_at = NOW(), deadline_at = NOW() + INTERVAL '48 hours', resolved_at = NULL
    WHERE id = p_review_id;
END;
$$;


ALTER FUNCTION "public"."reopen_family_review"("p_review_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."request_new_journey"("p_match_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  k_expiry CONSTANT INTERVAL := INTERVAL '14 days';   -- DR-121 item 16, a guess
  k_cool   CONSTANT INTERVAL := INTERVAL '24 hours';  -- existing #17 cooling period
  caller UUID := (SELECT auth.uid());
  m      RECORD;
  other  UUID;
  v_id   UUID;
  v_name TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  -- Identity before existence, so an error never confirms a match the caller
  -- is not part of.
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  IF m.status <> 'ended' THEN
    RAISE EXCEPTION 'journey_not_ended'
      USING HINT = 'There is nothing to begin again — this Journey has not ended.';
  END IF;

  IF m.ended_at IS NULL OR NOW() < m.ended_at + k_cool THEN
    RAISE EXCEPTION 'cooling_period_active'
      USING HINT = 'This Journey ended less than 24 hours ago.';
  END IF;

  -- THE ORDER OF THE NEXT THREE MATTERS, and it is the reverse of how they
  -- read. A hold is checked LAST of the three refusals that could reveal
  -- something: blocks and Tier-1 are conditions of the pair, but a hold is a
  -- record of a decision the other person made and did not want disclosed.
  IF zyra_block_exists(other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  IF NOT zyra_can_match(caller, other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  -- OA-ZYRA-159: "THE REQUESTER IS NEVER TOLD WHICH." A 6-month cooldown, a
  -- permanent "don't ask again" and a 14-day expiry all land here, and all
  -- raise the SAME error as a block and a Tier-1 exclusion. One error name
  -- for every refusal is what makes them indistinguishable — the moment one
  -- of them gets its own message, the requester can tell them apart.
  IF zyra_hold_blocks(caller, other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  -- Asking for something you could not accept wastes the other person's
  -- decision. Checked before the request exists, not at accept time.
  -- 2026-08-12: per the caller's plan cap; paused Journeys never count.
  IF zyra_active_journey_count(caller) >= zyra_active_journey_cap(caller) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT = 'You are at your plan''s Active Journey limit. End or pause one first.';
  END IF;

  IF EXISTS (SELECT 1 FROM journey_requests r
              WHERE r.match_id = p_match_id AND r.status = 'pending') THEN
    RAISE EXCEPTION 'request_already_pending';
  END IF;

  INSERT INTO journey_requests (match_id, requested_by, requested_to, expires_at)
  VALUES (p_match_id, caller, other, NOW() + k_expiry)
  RETURNING id INTO v_id;

  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  PERFORM create_notification(
    other, 'journey_request', 'A new Journey',
    COALESCE(v_name,'Someone') || ' would like to begin a new Journey with you.',
    p_match_id);

  RETURN v_id;
END;
$$;


ALTER FUNCTION "public"."request_new_journey"("p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."resolve_family_review_if_due"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  r RECORD;
  caller UUID := auth.uid();
  m RECORD;
  v_attempt UUID;
  is_party BOOLEAN;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id FOR UPDATE;
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


ALTER FUNCTION "public"."resolve_family_review_if_due"("p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."respond_to_journey_request"("p_request_id" "uuid", "p_decision" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  k_cooldown CONSTANT INTERVAL := INTERVAL '6 months';  -- DR-121 item 16, a guess
  caller  UUID := (SELECT auth.uid());
  r       RECORD;
  m       RECORD;
  v_att   UUID;
  v_n     INT;
  v_name  TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  IF p_decision NOT IN ('accept','decline','decline_never') THEN
    RAISE EXCEPTION 'unknown_decision';
  END IF;

  SELECT * INTO r FROM journey_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'request_not_found'; END IF;
  IF r.requested_to <> caller THEN RAISE EXCEPTION 'not_yours_to_answer'; END IF;
  IF r.status <> 'pending' THEN RAISE EXCEPTION 'already_answered'; END IF;
  IF r.expires_at <= NOW() THEN RAISE EXCEPTION 'request_expired'; END IF;

  SELECT * INTO m FROM matches WHERE id = r.match_id FOR UPDATE;

  -- ── DECLINE ────────────────────────────────────────────────────────────
  -- Both kinds write the SAME request row. The difference lives only in
  -- protection_holds, which the requester cannot read, so no future SELECT on
  -- this table can leak which one happened.
  IF p_decision IN ('decline','decline_never') THEN
    UPDATE journey_requests
       SET status = 'declined', responded_at = NOW()
     WHERE id = p_request_id;

    INSERT INTO protection_holds
      (match_id, restricted_id, protected_id, hold_type, appealable, expires_at)
    VALUES (
      r.match_id, r.requested_by, caller,
      CASE WHEN p_decision = 'decline_never' THEN 'decline_permanent' ELSE 'decline_cooldown' END,
      TRUE,
      CASE WHEN p_decision = 'decline_never' THEN NULL ELSE NOW() + k_cooldown END);

    -- OA-ZYRA-159: a decline DOES notify — "hiding it behind the expiry would
    -- mean fourteen days of hope for something already answered." Identical
    -- wording for both kinds, and for an expiry sweep, by design.
    PERFORM create_notification(
      r.requested_by, 'journey_request_declined', 'Journey request',
      'Your request to begin a new Journey was not taken up.', r.match_id);

    RETURN 'declined';
  END IF;

  -- ── ACCEPT ─────────────────────────────────────────────────────────────
  -- Re-checked at accept time, not trusted from request time. Days may have
  -- passed; a block, a Guardian change or another Journey can have happened
  -- in between.
  IF zyra_block_exists(r.requested_by) THEN RAISE EXCEPTION 'not_available'; END IF;
  IF NOT zyra_can_match(caller, r.requested_by) THEN RAISE EXCEPTION 'not_available'; END IF;

  IF EXISTS (SELECT 1 FROM matches x WHERE x.status = 'active'
               AND (x.seeker_a_id IN (m.seeker_a_id, m.seeker_b_id)
                 OR x.seeker_b_id IN (m.seeker_a_id, m.seeker_b_id))) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT = 'One of you already has an Active Journey.';
  END IF;

  -- A FRESH ATTEMPT. Nothing is deleted and ended_at is NOT cleared — the
  -- prior ending stays on the record (DR-121 item 3). The old attempt row
  -- keeps its own ended_by / ended_at / end_reason, which is where the
  -- history actually lives now.
  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_n
    FROM journey_attempts WHERE match_id = r.match_id;

  -- SALAM FIRST (DR-ZYRA-183): a fresh attempt begins with the greeting.
  INSERT INTO journey_attempts
    (match_id, attempt_number, status, journey_stage, started_at)
  VALUES (r.match_id, v_n, 'active', 'salam_exchange', NOW())
  RETURNING id INTO v_att;

  -- matches_end_fields_need_ended_status FORCES ended_by/end_reason/end_note
  -- to null once status leaves 'ended'. ended_at is not in that constraint,
  -- which is exactly why the preserved comment in restart_journey said to
  -- keep it: it is the one part of the ending the pair row can still carry.
  UPDATE matches
     SET status = 'active',
         journey_stage = 'salam_exchange',
         ended_by = NULL, end_reason = NULL, end_note = NULL,
         suspended_by = NULL, suspended_at = NULL
   WHERE id = r.match_id;

  -- Its own conversation and its own timeline — possible only since stage 4a
  -- moved both tables from UNIQUE(match_id) to UNIQUE(attempt_id). The old
  -- attempt's messages stay with the old conversation, so a fresh start is
  -- genuinely fresh without erasing anything.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (r.match_id, v_att, 'active');

  INSERT INTO timelines (match_id, attempt_id) VALUES (r.match_id, v_att);

  UPDATE journey_requests
     SET status = 'accepted', responded_at = NOW(), attempt_id = v_att
   WHERE id = p_request_id;

  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  PERFORM create_notification(
    r.requested_by, 'journey_request_accepted', 'A new Journey',
    COALESCE(v_name,'They') || ' accepted. Your new Journey has begun.',
    r.match_id);

  RETURN 'accepted';
END;
$$;


ALTER FUNCTION "public"."respond_to_journey_request"("p_request_id" "uuid", "p_decision" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."restart_journey"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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

  SELECT * INTO m FROM matches WHERE id = p_match_id;
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


ALTER FUNCTION "public"."restart_journey"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."restart_journey"("p_match_id" "uuid") IS 'OA-ZYRA-154: refuses. A Journey cannot be reopened by one party. Replaced by Request New Journey (OA-ZYRA-159). Previously deleted six tables of history and cleared ended_at.';



CREATE OR REPLACE FUNCTION "public"."resume_journey"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE m RECORD; caller UUID := auth.uid(); other_id UUID; v_attempt UUID; v_name TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;
  IF m.suspended_by IS NULL THEN RAISE EXCEPTION 'journey_not_paused'; END IF;

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

  IF m.also_paused_by IS NOT NULL THEN
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

  UPDATE matches SET suspended_by = NULL, suspended_at = NULL,
                     pause_nudged_at = NULL WHERE id = p_match_id;
  UPDATE journey_attempts SET paused_by = NULL, paused_at = NULL
   WHERE v_attempt IS NOT NULL AND id = v_attempt;
  UPDATE conversations SET status='active'
   WHERE v_attempt IS NOT NULL AND attempt_id = v_attempt AND status='paused';

  PERFORM create_notification(
    other_id, 'journey_continued', 'Your Journey continues',
    coalesce(v_name, 'They') || ' has lifted their pause — your Journey together is active again.',
    p_match_id);
END; $$;


ALTER FUNCTION "public"."resume_journey"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."resume_journey"("p_match_id" "uuid") IS 'Clears the pause on both matches and journey_attempts. Still reads Active-Journey state from matches, which is authoritative until step 7.';



CREATE OR REPLACE FUNCTION "public"."score_candidates"("p_candidate_ids" "uuid"[]) RETURNS TABLE("candidate_id" "uuid", "score" numeric)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_me UUID := auth.uid();
  v_my_prefs JSONB; v_my_hard JSONB; v_candidate_id UUID; v_ch3 JSONB;
  v_pref_rec RECORD; v_value TEXT; v_light TEXT;
  v_total NUMERIC; v_max NUMERIC; v_excluded BOOLEAN;
  v_multi_total NUMERIC; v_multi_count INT;
  v_my_ch2 JSONB; v_cand RECORD; v_block JSONB; v_pref_arr JSONB;
  v_ch2_weight INT := 1;   -- STILL OPEN — OA-ZYRA-193(e), now answerable.
BEGIN
  IF v_me IS NULL THEN RETURN; END IF;
  IF p_candidate_ids IS NULL OR array_length(p_candidate_ids, 1) IS NULL THEN RETURN; END IF;

  SELECT oa.ch4_preferences, oa.ch4_hard_requirements INTO v_my_prefs, v_my_hard
    FROM onboarding_answers oa WHERE oa.user_id = v_me;
  SELECT sd.preferences INTO v_my_ch2 FROM seeker_details sd WHERE sd.user_id = v_me;

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
        IF v_block IS NOT NULL AND v_cand.sect IS NOT NULL THEN
          IF (v_block -> 'hard_requirement') ? v_cand.sect THEN
            v_excluded := TRUE;
          ELSE
            v_light := v_block -> 'matrix' ->> v_cand.sect;
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


ALTER FUNCTION "public"."score_candidates"("p_candidate_ids" "uuid"[]) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."score_candidates"("p_candidate_ids" "uuid"[]) IS 'Caller-scoped compatibility scorer. Multi-select questions average selected-option lights and contribute one denominator unit (OA-ZYRA-228 option a).';



CREATE OR REPLACE FUNCTION "public"."seeker_details_for_unlocked"("p_target" "uuid") RETURNS TABLE("user_id" "uuid", "sect" "text", "sect_other" "text", "revert_status" boolean, "country_of_birth" "text", "nationality" "text", "ethnicity" "text", "languages" "text"[])
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."seeker_details_for_unlocked"("p_target" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."suspend_journey"("p_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  m RECORD; caller UUID := auth.uid(); caller_plan TEXT; v_attempt UUID;
  v_cap INT; v_held INT; v_other UUID; v_name TEXT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;

  IF caller IS NOT DISTINCT FROM m.suspended_by
     OR caller IS NOT DISTINCT FROM m.also_paused_by THEN
    RETURN;
  END IF;

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


ALTER FUNCTION "public"."suspend_journey"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."suspend_journey"("p_match_id" "uuid") IS 'Pause recorded on BOTH matches.suspended_by and journey_attempts.paused_by. Since 2026-08-11 both plans may pause: cap 5 (Basic) / 10 (ZYRA One) counted over pauses the caller initiated; raises paused_limit_reached at the cap. suspension_requires_one is retired.';



CREATE OR REPLACE FUNCTION "public"."touch_seeker_details"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  new.updated_at := now();
  return new;
end $$;


ALTER FUNCTION "public"."touch_seeker_details"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."unlock_balance"("p_tier" "text" DEFAULT NULL::"text") RETURNS TABLE("tier" "text", "balance" integer)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select c.tier, coalesce(sum(c.delta), 0)::int
  from public.unlock_credits c
  where c.user_id = (select auth.uid())
    and (p_tier is null or c.tier = p_tier)
  group by c.tier;
$$;


ALTER FUNCTION "public"."unlock_balance"("p_tier" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wali_has_wali_one"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."wali_has_wali_one"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."wali_review_decision"("p_review_id" "uuid", "p_decision" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  r RECORD;
  m RECORD;
  caller UUID := auth.uid();
  is_authorised_wali BOOLEAN;
  expected_count INTEGER;
  continued_count INTEGER;
BEGIN
  IF p_decision NOT IN ('continue', 'pause') THEN
    RAISE EXCEPTION 'invalid decision';
  END IF;

  SELECT * INTO r FROM journey_family_reviews WHERE id = p_review_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'review not found'; END IF;
  IF r.status <> 'pending' THEN RAISE EXCEPTION 'review already resolved'; END IF;
  -- Single path, loudly. A review with no attempt is a broken row, not a
  -- case to route around (I3) — the alternative is a silent second code
  -- path keyed on match_id that would outlive step 7.
  IF r.attempt_id IS NULL THEN RAISE EXCEPTION 'review_has_no_attempt'; END IF;

  -- The pair, reached THROUGH the attempt.
  SELECT mm.* INTO m FROM journey_attempts a
    JOIN matches mm ON mm.id = a.match_id
   WHERE a.id = r.attempt_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'attempt not found'; END IF;

  -- UNCHANGED authorisation.
  SELECT EXISTS (
    SELECT 1 FROM wali_links
    WHERE wali_id = caller AND status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)
  ) INTO is_authorised_wali;
  IF caller IS NULL OR NOT is_authorised_wali THEN
    RAISE EXCEPTION 'not an authorised Wali for this Journey';
  END IF;

  INSERT INTO journey_family_review_responses (review_id, wali_id, decision)
    VALUES (p_review_id, caller, p_decision)
    ON CONFLICT (review_id, wali_id) DO UPDATE SET decision = EXCLUDED.decision, responded_at = NOW();

  IF p_decision = 'pause' THEN
    UPDATE journey_family_reviews SET status = 'paused', resolved_at = NOW() WHERE id = p_review_id;
    RETURN;
  END IF;

  -- UNCHANGED counting rule. (Its behaviour when one side holds no Main
  -- Guardian is OA-ZYRA-173 — raised, deliberately not altered here.)
  SELECT COUNT(DISTINCT wali_id) INTO expected_count
    FROM wali_links WHERE status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id);

  SELECT COUNT(*) INTO continued_count
    FROM journey_family_review_responses
    WHERE review_id = p_review_id AND decision = 'continue';

  IF expected_count >= 1 AND continued_count >= expected_count THEN
    UPDATE journey_family_reviews SET status = 'continued', resolved_at = NOW() WHERE id = p_review_id;
    -- Both copies, in step. matches stays authoritative until step 7.
    UPDATE matches          SET journey_stage = r.to_stage WHERE id = m.id;
    UPDATE journey_attempts SET journey_stage = r.to_stage WHERE id = r.attempt_id;
    IF r.to_stage = 'conversation' THEN
      UPDATE conversations SET status = 'active' WHERE attempt_id = r.attempt_id;
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION "public"."wali_review_decision"("p_review_id" "uuid", "p_decision" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_accept_guardian_request"("p_request_id" "uuid", "p_relationship" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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
  perform public.create_notification(
    v_request.recipient_id, 'wali_request', 'Guardian request accepted',
    coalesce(v_owner_name, 'They') || ' accepted your Guardian request.', null
  );
  return v_link_id;
end;
$$;


ALTER FUNCTION "public"."zyra_accept_guardian_request"("p_request_id" "uuid", "p_relationship" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_active_journey_cap"("p_user" "uuid") RETURNS integer
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select case when exists (
    select 1 from subscriptions
    where user_id = p_user and plan_type = 'seeker_premium' and status = 'active'
  ) then 3 else 1 end;
$$;


ALTER FUNCTION "public"."zyra_active_journey_cap"("p_user" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_active_journey_count"("p_user" "uuid", "p_exclude" "uuid" DEFAULT NULL::"uuid") RETURNS integer
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select count(*)::int from matches
  where status = 'active' and suspended_by is null
    and (seeker_a_id = p_user or seeker_b_id = p_user)
    and (p_exclude is null or id <> p_exclude);
$$;


ALTER FUNCTION "public"."zyra_active_journey_count"("p_user" "uuid", "p_exclude" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_advance_stage"("p_match_id" "uuid", "p_from_stage" "text") RETURNS TABLE("advanced" boolean, "stage" "text", "reason" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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

  select * into m from matches where id = p_match_id for update;
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


ALTER FUNCTION "public"."zyra_advance_stage"("p_match_id" "uuid", "p_from_stage" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_advance_stage"("p_match_id" "uuid", "p_from_stage" "text") IS 'Advances the three ungated Pre-Journey Ritual transitions and REFUSES the four Family-Review-gated ones. Replaces the client-side UPDATE that RLS silently discarded (release blocker, Founder 2026-08-07). Returns (advanced, stage, reason) — callers must surface the reason, never swallow it. See PRE-JOURNEY RITUAL and GUARDIAN & ROMANTIC RULES (current versions).';



CREATE OR REPLACE FUNCTION "public"."zyra_all_iso639_1"("p" "text"[]) RETURNS boolean
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO 'public'
    AS $_$
  select p is null
      or not exists (select 1 from unnest(p) x where x !~ '^[a-z]{2}$');
$_$;


ALTER FUNCTION "public"."zyra_all_iso639_1"("p" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_answers_refresh_onboarding_complete"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  PERFORM zyra_refresh_onboarding_complete(
    CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id ELSE NEW.user_id END);
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."zyra_answers_refresh_onboarding_complete"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_attach_identity_verification_provider_session"("p_user_id" "uuid", "p_provider_code" "text", "p_provider_session_ref" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'private'
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


ALTER FUNCTION "public"."zyra_attach_identity_verification_provider_session"("p_user_id" "uuid", "p_provider_code" "text", "p_provider_session_ref" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_attempt_participants"("p_attempt" "uuid") RETURNS TABLE("user_id" "uuid", "role" "text", "is_main" boolean, "attempt_status" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select r.user_id, r.role, r.is_main, r.attempt_status
  from public.zyra_attempt_participant_rows r
  where r.attempt_id = p_attempt;
$$;


ALTER FUNCTION "public"."zyra_attempt_participants"("p_attempt" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_attempt_participants"("p_attempt" "uuid") IS 'NOT CLIENT-CALLABLE as of 2026-08-08. Has no caller check — it returns any attempt''s full participant roster to whoever passes the id. Kept for server-side use only. Do not re-grant: add a zyra_can_view_attempt() guard first.';



CREATE OR REPLACE FUNCTION "public"."zyra_attempt_summary_for_guardian"("p_seeker" "uuid") RETURNS TABLE("attempt_id" "uuid", "started_at" timestamp with time zone, "ended_at" timestamp with time zone, "ended" boolean)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  with caller as materialized (
    select (select auth.uid()) as user_id
  ),
  current_guardian_link as materialized (
    select
      w.id,
      w.active_since,
      w.guardian_link_authority_id
    from public.wali_links w
    cross join caller c
    where c.user_id is not null
      and w.seeker_id = p_seeker
      and w.wali_id = c.user_id
      and w.status = 'active'
  )
  select
    a.id,
    a.started_at,
    a.ended_at,
    (a.status = 'ended')
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  cross join current_guardian_link w
  where p_seeker in (m.seeker_a_id, m.seeker_b_id)
    and (
      a.status = 'active'
      or (
        a.status = 'ended'
        and (
          a.ended_at >= w.active_since
          or exists (
            select 1
            from public.guardian_journey_history_consents c
            where c.wali_link_id = w.id
              and c.guardian_link_authority_id =
                w.guardian_link_authority_id
          )
        )
      )
    );
$$;


ALTER FUNCTION "public"."zyra_attempt_summary_for_guardian"("p_seeker" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_attempt_summary_for_guardian"("p_seeker" "uuid") IS 'DR-ZYRA-230/233. CALLER-BOUND ACTIVE GUARDIANS. Every active Guardian sees the current active/paused attempt plus ended attempts from the current continuous link period. A valid per-link Seeker permission widens to all ended summaries for that same Guardian. Positive active/ended allowlist fails future statuses closed. Four fields only; never counterpart, stage, messages, answers, reasons, notes or safety data.';



CREATE OR REPLACE FUNCTION "public"."zyra_block_exists"("p_other" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM profile_blocks
    WHERE (blocker_id = auth.uid() AND blocked_id = p_other)
       OR (blocked_id = auth.uid() AND blocker_id = p_other)
  );
$$;


ALTER FUNCTION "public"."zyra_block_exists"("p_other" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_block_user"("p_other" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_block_user"("p_other" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_can_continue_journey"("p_a" "uuid", "p_b" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_can_continue_journey"("p_a" "uuid", "p_b" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_can_continue_journey"("p_a" "uuid", "p_b" "uuid") IS 'OA-ZYRA-174. May an EXISTING Journey continue? Blocks and Tier-0 only. Not zyra_can_match: Tier-1 is a matching rule, grandfathered for Journeys already under way. Internal predicate — not client-callable.';



CREATE OR REPLACE FUNCTION "public"."zyra_can_guardian_link"("p_a" "uuid", "p_b" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_can_guardian_link"("p_a" "uuid", "p_b" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_can_guardian_link"("p_a" "uuid", "p_b" "uuid") IS 'THE canonical Guardian-eligibility predicate: may these two people form a Guardian bond? Symmetric and stateless. Refuses over ANY matches row in any status, including ended. Enforced by the zyra_wali_links_guardian_link_allowed trigger on wali_links, so every write path is covered including future ones. Deliberately silent on WHO may be a Guardian (role, gender) — that is the outstanding governance review and lives in accept_wali_invite(). Mirror of zyra_can_match(): the two are mutually exclusive by construction.';



CREATE OR REPLACE FUNCTION "public"."zyra_can_match"("p_a" "uuid", "p_b" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_can_match"("p_a" "uuid", "p_b" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_can_match"("p_a" "uuid", "p_b" "uuid") IS 'Romantic eligibility. Tier-0: neither guards the other. Tier-1 (added 2026-08-08): they do not share a Guardian — which in practice means siblings, since same-gender co-wards are already refused by segregation. Keyed on links that are active OR removed, so the rule cannot be cleared by retiring a Guardian (I1). Enforced in the RLS WITH CHECK on likes/saves/passes and re-checked by promote and resume, per GUARDIAN & ROMANTIC RULES sections 5 and 6.';



CREATE OR REPLACE FUNCTION "public"."zyra_can_read_photo_object"("p_object_name" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.profile_photos pp
    where pp.storage_path = p_object_name
      and public.zyra_can_view_profile(pp.user_id)
  );
$$;


ALTER FUNCTION "public"."zyra_can_read_photo_object"("p_object_name" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_can_read_photo_object"("p_object_name" "text") IS 'Storage read gate for the profile-photos bucket. Answers "is this object displayed by a profile the caller may view?" — deliberately NOT "may the caller see whoever uploaded it", which is what the pre-2026-08-05 policy asked and which coupled photo visibility to the uploader''s gender and block status. SECURITY DEFINER so the profile_photos lookup is not itself filtered by the RLS being evaluated.';



CREATE OR REPLACE FUNCTION "public"."zyra_can_view_attempt"("p_attempt" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1 from public.zyra_attempt_participant_rows r
    where r.attempt_id = p_attempt
      and r.user_id = (select auth.uid())
  );
$$;


ALTER FUNCTION "public"."zyra_can_view_attempt"("p_attempt" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_can_view_attempt"("p_attempt" "uuid") IS 'May the CALLER see this attempt? Boolean, full access only. The successor-Guardian summary case is deliberately NOT here — see zyra_attempt_summary_for_guardian().';



CREATE OR REPLACE FUNCTION "public"."zyra_can_view_profile"("p_target" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
      join public.matches mm on mm.id = me.match_id
      where me.user_id   = (select auth.uid())
        and them.user_id = p_target
        and me.role   = 'seeker'
        and them.role = 'seeker'
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


ALTER FUNCTION "public"."zyra_can_view_profile"("p_target" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_can_view_profile"("p_target" "uuid") IS 'May the CALLER see this profile? self · Guardian link · shares an attempt (via zyra_attempt_participant_rows) · opposite-gender browsing. Participation logic is NOT duplicated here — it is read from the one view.';



CREATE OR REPLACE FUNCTION "public"."zyra_cancel_guardian_request"("p_request_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_cancel_guardian_request"("p_request_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_ch2_sect_hard_shape_ok"("p" "jsonb") RETURNS boolean
    LANGUAGE "sql" IMMUTABLE PARALLEL SAFE
    SET "search_path" TO 'public'
    AS $$
  SELECT p IS NULL
      OR p -> 'sect' -> 'hard_requirement' IS NULL
      OR ( jsonb_typeof(p -> 'sect' -> 'hard_requirement') = 'array'
       AND NOT EXISTS (
             SELECT 1 FROM jsonb_array_elements(p -> 'sect' -> 'hard_requirement') a
              WHERE jsonb_typeof(a) <> 'string' ) );
$$;


ALTER FUNCTION "public"."zyra_ch2_sect_hard_shape_ok"("p" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_ch2_sect_hard_shape_ok"("p" "jsonb") IS 'Shape guard for seeker_details.preferences->sect->hard_requirement. Accepts an array of sect labels only. Exists so the retired boolean form cannot be written by an older client build — a silent old-shape write would read as "no exclusion at all", failing OPEN on a promise the Seeker made about Article 9 data.';



CREATE OR REPLACE FUNCTION "public"."zyra_ch4_hard_shape_ok"("p" "jsonb") RETURNS boolean
    LANGUAGE "sql" IMMUTABLE PARALLEL SAFE
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_ch4_hard_shape_ok"("p" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_ch4_hard_shape_ok"("p" "jsonb") IS 'Shape guard for onboarding_answers.ch4_hard_requirements. Accepts {question_id: [option_label, ...]} only. Exists so the retired {question_id: bool} shape cannot be written by an older client build — a silent old-shape write would read as "no hard requirement at all", which fails OPEN on a promise the Seeker made. Fail loudly instead.';



CREATE OR REPLACE FUNCTION "public"."zyra_clear_main_guardian"("p_wali_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  raise exception 'main_guardian_cannot_be_cleared'
    using hint = 'A Seeker may not be left without a Main Guardian '
                 '(DR-ZYRA-136). Choose a different Guardian as Main '
                 'instead — zyra_set_main_guardian reassigns in one step.';
end;
$$;


ALTER FUNCTION "public"."zyra_clear_main_guardian"("p_wali_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_clear_main_guardian"("p_wali_id" "uuid") IS 'RETIRED 2026-08-10 — DR-ZYRA-136, contradiction-audit 2.9. Always throws. It created the no-Main-Guardian state, which the Founder has ruled unacceptable. Use zyra_set_main_guardian to reassign.';



CREATE OR REPLACE FUNCTION "public"."zyra_compatibility_for_plus"("p_match_id" "uuid") RETURNS numeric
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
  v_counterpart uuid;
  v_score numeric;
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

  v_score := case
    when v_is_a then v_compat.seeker_a_score
    else v_compat.seeker_b_score
  end;

  if v_score is null then
    select scored.score
      into v_score
      from public.score_candidates(array[v_counterpart]) as scored
     where scored.candidate_id = v_counterpart
     limit 1;

    if v_score is not null then
      if v_is_a then
        update public.journey_compatibility as jc
           set seeker_a_score = v_score
         where jc.match_id = p_match_id;
      else
        update public.journey_compatibility as jc
           set seeker_b_score = v_score
         where jc.match_id = p_match_id;
      end if;
    end if;
  end if;

  return v_score;
end;
$$;


ALTER FUNCTION "public"."zyra_compatibility_for_plus"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_compatibility_for_plus"("p_match_id" "uuid") IS 'DR-ZYRA-135 / OA-ZYRA-283. Entitled early sight of only the caller-owned score; does not alter either reveal flag, timestamp, stage or notification.';



CREATE OR REPLACE FUNCTION "public"."zyra_confirm_milestone"("p_attestation_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller UUID := auth.uid();
  att RECORD; m RECORD; v_timeline UUID; v_name TEXT; v_label TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT * INTO att FROM journey_milestone_attestations WHERE id = p_attestation_id;
  IF NOT FOUND OR att.status <> 'pending' THEN RAISE EXCEPTION 'attestation_not_pending'; END IF;

  SELECT * INTO m FROM matches WHERE id = att.match_id;
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


ALTER FUNCTION "public"."zyra_confirm_milestone"("p_attestation_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_confirm_milestone"("p_attestation_id" "uuid") IS 'Counterpart-only confirmation; writes the timeline_milestones row at noon UTC of the attested date. NOT EXISTS-guarded like every other milestone writer.';



CREATE OR REPLACE FUNCTION "public"."zyra_counterpart_card"("p_match_id" "uuid") RETURNS TABLE("counterpart_first_name" "text", "counterpart_age" integer, "guardian_first_name" "text", "guardian_surname_line" "text", "guardian_contact" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  with m as (
    select mm.*
    from public.matches mm
    where mm.id = p_match_id
      and mm.status <> 'potential'
      and mm.end_reason is distinct from 'safety_concern'
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
           or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
      )
  ),
  mine as (
    select w.seeker_id as my_ward
    from m
    join public.wali_links w
      on w.wali_id = (select auth.uid())
     and w.status = 'active'
     and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
    where w.is_main is true
       or exists (
         select 1
         from public.journey_attempts a
         join public.journey_guardian_assignments jga
           on jga.attempt_id = a.id
          and jga.wali_link_id = w.id
          and jga.seeker_id = w.seeker_id
          and jga.revoked_at is null
         where a.match_id = m.id
           and a.status = 'active'
       )
    limit 1
  ),
  other as (
    select case when mine.my_ward = m.seeker_a_id then m.seeker_b_id
                else m.seeker_a_id end as other_seeker
    from m, mine
  )
  select p.first_name,
         date_part('year', age(p.date_of_birth))::int,
         g.first_name,
         g.surname_line,
         null::text
  from other
  join public.profiles p on p.id = other.other_seeker
  left join public.wali_links ow
    on ow.seeker_id = other.other_seeker
   and ow.status = 'active'
   and ow.is_main is true
  left join public.profiles g on g.id = ow.wali_id;
$$;


ALTER FUNCTION "public"."zyra_counterpart_card"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_counterpart_card"("p_match_id" "uuid") IS 'Restricted counterpart identity card for an authorised Guardian Journey participant. Main participates by role; Additional participates only while the owning Seeker includes them in that active Journey.';



CREATE OR REPLACE FUNCTION "public"."zyra_create_first_attempt"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.journey_attempts
    (match_id, attempt_number, status, journey_stage, started_at, created_at)
  values (new.id, 1, new.status, new.journey_stage,
          case when new.status = 'active' then now() end, now())
  on conflict (match_id, attempt_number) do nothing;
  return new;
end $$;


ALTER FUNCTION "public"."zyra_create_first_attempt"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_create_first_attempt"() IS 'Maintains V3 §2''s invariant: a match always has attempt 1. Without this, stage 3 would re-point nine tables at attempts that do not exist.';



CREATE OR REPLACE FUNCTION "public"."zyra_create_profile"("p_role" "text", "p_first_name" "text", "p_gender" "text", "p_dob" "date") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_create_profile"("p_role" "text", "p_first_name" "text", "p_gender" "text", "p_dob" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_dashboard_updates"("p_limit" integer DEFAULT 3, "p_cursor_occurred_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_cursor_class_key" "text" DEFAULT NULL::"text", "p_cursor_source_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("occurred_at" timestamp with time zone, "class_key" "text", "source_id" "uuid", "title_key" "text", "detail_key" "text", "destination_key" "text", "related_match_id" "uuid", "is_unread" boolean)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_dashboard_updates"("p_limit" integer, "p_cursor_occurred_at" timestamp with time zone, "p_cursor_class_key" "text", "p_cursor_source_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_dashboard_updates"("p_limit" integer, "p_cursor_occurred_at" timestamp with time zone, "p_cursor_class_key" "text", "p_cursor_source_id" "uuid") IS 'OA-ZYRA-281: caller-scoped, allowlisted, read-only meaningful-movement projection — unread-backed notifications + authoritative domain events; NOT an inbox or history; the Notifications manager is the history surface. is_unread is three-state: TRUE means an unread notification; FALSE is reserved for a future explicit read-notification projection; NULL means a domain event and must never be rendered as read.';



CREATE OR REPLACE FUNCTION "public"."zyra_debug_grant_credits"("p_tier" "text", "p_count" integer DEFAULT 5) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_me uuid := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = v_me AND u.email LIKE '%@zyra.test'
  ) THEN
    RAISE EXCEPTION 'debug_grant_disabled'
      USING HINT = 'Credit grants are limited to seeded test accounts. Real payment processing is not built yet.';
  END IF;

  IF p_tier NOT IN ('paid_single','paid_plus_single') THEN
    RAISE EXCEPTION 'unknown_tier';
  END IF;
  IF p_count < 1 OR p_count > 50 THEN
    RAISE EXCEPTION 'count_out_of_range';
  END IF;

  INSERT INTO public.unlock_credits (user_id, tier, delta, reason, note)
  VALUES (v_me, p_tier, p_count, 'debug_grant', 'dev panel');

  RETURN jsonb_build_object('status','granted','tier',p_tier,'added',p_count);
END;
$$;


ALTER FUNCTION "public"."zyra_debug_grant_credits"("p_tier" "text", "p_count" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_decline_guardian_request"("p_request_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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
  perform public.create_notification(
    v_requester, 'wali_request', 'Guardian request declined',
    coalesce(v_name, 'They') || ' declined your Guardian request.', null
  );
  return true;
end;
$$;


ALTER FUNCTION "public"."zyra_decline_guardian_request"("p_request_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_decline_wali_invite"("p_token" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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

  perform public.create_notification(
    v_invite.inviter_id,
    'wali_invite_declined',
    'Guardian invitation declined',
    case when v_invite.label is null
      then 'Your Guardian invitation was declined.'
      else v_invite.label || ' declined your Guardian invitation.'
    end,
    null
  );
  return true;
end;
$$;


ALTER FUNCTION "public"."zyra_decline_wali_invite"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_delete_my_unstarted_identity_verification_attempt"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'private'
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


ALTER FUNCTION "public"."zyra_delete_my_unstarted_identity_verification_attempt"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_dev_counterpart_complete"("p_match_id" "uuid", "p_question_ids" "text"[] DEFAULT '{}'::"text"[]) RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller     UUID := (SELECT auth.uid());
  v_email    TEXT;
  m          RECORD;
  v_other    UUID;
  v_attempt  UUID;
  v_phase    INT;
  v_guardian UUID;
  v_answerer UUID;
  v_qid      TEXT;
  v_seeker   UUID;
  n          INT := 0;
  did        TEXT;
  v_samples  TEXT[] := ARRAY[
    'I keep my five prayers at the centre of the day and try to build everything else around them.',
    'Honestly, some weeks are stronger than others — but I have never let it slip entirely, and I would want a home where we hold each other to it gently.',
    'I am looking for someone to build a settled life with, not to date indefinitely. I would want to move at a considered pace but with a clear intention.',
    'Kindness first, then honesty. If someone is unkind when they are tired or under pressure, everything else is decoration.',
    'I would want us to live near enough to family to be present, but with our own front door.',
    'Two or three, God willing, and I would rather not wait many years — though I know that is not entirely ours to decide.',
    'I would want us both to be able to speak plainly when something is wrong, rather than letting it sit for a week.',
    'My work matters to me and I would not want to give it up, but I do not want it to be the loudest thing in the house.',
    'I would rather we decide money together and neither of us feels they are asking permission.',
    'I go quiet when I am upset, which I know is not always fair. It is the thing I am working on most.'
  ];
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Simulating the other party is limited to seeded @zyra.test accounts.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  -- GUARD BOTH PARTIES (2026-08-12): this function writes as the
  -- counterpart, so the counterpart must be a seeded account too.
  IF EXISTS (SELECT 1 FROM auth.users u
              WHERE u.id IN (m.seeker_a_id, m.seeker_b_id)
                AND (u.email IS NULL OR u.email NOT LIKE '%@zyra.test')) THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of the match must be a seeded @zyra.test account.';
  END IF;
  IF m.status <> 'active' THEN
    RAISE EXCEPTION 'journey_not_active'
      USING HINT = 'Only an Active Journey has a stage to complete.';
  END IF;

  v_other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  -- The conversation and timeline rows are normally created by
  -- create_match_on_mutual_like(). A match seeded straight into the table has
  -- neither, so Open Conversation opens onto nothing at the end of an
  -- otherwise perfect walk-through. Created here, idempotently, at whatever
  -- stage this is first called: 'closed' until the Journey earns 'active',
  -- which resolve_family_review_if_due() sets on the real path.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (p_match_id, v_attempt,
          CASE WHEN m.journey_stage = 'conversation' THEN 'active' ELSE 'closed' END)
  ON CONFLICT (attempt_id) DO NOTHING;

  INSERT INTO timelines (match_id, attempt_id)
  VALUES (p_match_id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;

  IF m.journey_stage = 'compatibility_reveal' THEN

    INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
    ON CONFLICT (match_id) DO NOTHING;

    IF v_other = m.seeker_a_id THEN
      UPDATE journey_compatibility SET seeker_a_revealed = TRUE WHERE match_id = p_match_id;
    ELSE
      UPDATE journey_compatibility SET seeker_b_revealed = TRUE WHERE match_id = p_match_id;
    END IF;

    INSERT INTO journey_stage_checkpoints (match_id, stage, seeker_id)
    VALUES (p_match_id, 'compatibility_reveal', v_other)
    ON CONFLICT DO NOTHING;

    did := 'They revealed their compatibility and chose to continue.';

  ELSIF m.journey_stage = 'salam_exchange' THEN

    INSERT INTO journey_salams (match_id, seeker_id) VALUES (p_match_id, v_other)
    ON CONFLICT DO NOTHING;
    did := 'They sent their Salam.';

  ELSIF m.journey_stage = 'wali_gate' THEN

    SELECT id INTO v_guardian FROM auth.users WHERE email = 'dev.guardian.a@zyra.test';
    IF v_guardian IS NULL THEN
      RAISE EXCEPTION 'no_dev_guardian'
        USING HINT = 'Seed dev.guardian.a@zyra.test before using the Guardian Gate.';
    END IF;

    FOREACH v_seeker IN ARRAY ARRAY[m.seeker_a_id, m.seeker_b_id] LOOP
      IF NOT EXISTS (SELECT 1 FROM wali_links wl
                      WHERE wl.seeker_id = v_seeker AND wl.is_main AND wl.status = 'active') THEN
        INSERT INTO wali_links (seeker_id, wali_id, status, is_main, relationship)
        VALUES (v_seeker, v_guardian, 'active', TRUE, 'father')
        ON CONFLICT (seeker_id, wali_id)
        DO UPDATE SET status = 'active', is_main = TRUE;
        n := n + 1;
      END IF;
    END LOOP;

    did := CASE WHEN n = 0
      THEN 'Both of you already have a linked Guardian — the gate is open.'
      ELSE format('Linked a Main Guardian for %s of you.', n) END;

  ELSIF m.journey_stage IN ('phase_1', 'phase_2', 'phase_3') THEN

    v_phase := substring(m.journey_stage from 7)::INT;

    FOREACH v_qid IN ARRAY p_question_ids LOOP
      INSERT INTO journey_phase_answers (match_id, phase, seeker_id, question_id, answer_text)
      VALUES (p_match_id, v_phase, v_other, v_qid,
              v_samples[1 + (n % array_length(v_samples, 1))])
      ON CONFLICT (match_id, phase, seeker_id, question_id) DO NOTHING;
      n := n + 1;
    END LOOP;

    INSERT INTO journey_phase_checkpoints (match_id, phase, seeker_id, decision)
    VALUES (p_match_id, v_phase, v_other, 'continue')
    ON CONFLICT (match_id, phase, seeker_id) DO NOTHING;

    did := format('They answered %s question(s) and chose to continue.', n);

  ELSIF m.journey_stage = 'family_stage' THEN

    SELECT wl.wali_id INTO v_answerer FROM wali_links wl
     WHERE wl.seeker_id = caller AND wl.is_main AND wl.status = 'active' LIMIT 1;
    IF v_answerer IS NULL THEN
      SELECT id INTO v_answerer FROM auth.users WHERE email = 'dev.guardian.a@zyra.test';
    END IF;
    IF v_answerer IS NULL THEN RAISE EXCEPTION 'no_dev_guardian'; END IF;

    FOREACH v_qid IN ARRAY p_question_ids LOOP
      INSERT INTO journey_family_answers (match_id, direction, question_id, answerer_id, answer_text)
      VALUES (p_match_id, 'seeker_to_wali', v_qid, v_answerer,
              v_samples[1 + (n % array_length(v_samples, 1))])
      ON CONFLICT (match_id, direction, question_id, answerer_id) DO NOTHING;
      n := n + 1;
    END LOOP;

    did := format('Their Guardian answered %s question(s).', n);

  ELSIF m.journey_stage = 'conversation' THEN
    UPDATE conversations SET status = 'active', closed_at = NULL WHERE attempt_id = v_attempt;
    did := 'Already at Open Conversation — nothing left to wait for.';
  ELSE
    did := format('Nothing to do at %s.', coalesce(m.journey_stage, 'no stage'));
  END IF;

  IF EXISTS (SELECT 1 FROM journey_family_reviews
              WHERE attempt_id = v_attempt AND status = 'pending') THEN
    UPDATE journey_family_reviews
       SET deadline_at = NOW() - INTERVAL '1 minute'
     WHERE attempt_id = v_attempt AND status = 'pending';
    PERFORM resolve_family_review_if_due(p_match_id);
    did := did || ' The Family Review period closed and the Journey moved on.';
  END IF;

  RETURN did;
END;
$$;


ALTER FUNCTION "public"."zyra_dev_counterpart_complete"("p_match_id" "uuid", "p_question_ids" "text"[]) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_dev_counterpart_complete"("p_match_id" "uuid", "p_question_ids" "text"[]) IS 'DEV ONLY (@zyra.test). Completes the other party''s half of the current Journey stage so the flow can be walked alone. Drop before public launch — OA-ZYRA-184.';



CREATE OR REPLACE FUNCTION "public"."zyra_dev_guardians_on_decided"() RETURNS integer
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
  v_pool uuid[];
  v_count int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (
    select 1 from auth.users u
    where u.id = v_me and u.email like '%@zyra.test'
  ) then
    raise exception 'dev_accounts_only';
  end if;

  -- The same pool zyra_dev_set_guardians_on_decided() writes from.
  select array_agg(p.id order by u.email)
    into v_pool
  from public.profiles p
  join auth.users u on u.id = p.id
  where u.email in ('dev.guardian.a@zyra.test','dev.guardian.b@zyra.test','dev.guardian.c@zyra.test');

  if v_pool is null then return 0; end if;

  -- The setter applies the SAME count to every decided-on target, so the
  -- state reads back as the largest pool-link count any target holds —
  -- which is the applied count, or 0 when cleared / nothing decided yet.
  select coalesce(max(cnt), 0) into v_count from (
    select count(*) as cnt
    from public.wali_links wl
    where wl.wali_id = any(v_pool)
      and wl.status = 'active'
      and wl.seeker_id in (
        select saved_id  from public.saves  where saver_id  = v_me
        union select liked_id  from public.likes  where liker_id  = v_me
        union select passed_id from public.passes where passer_id = v_me
      )
    group by wl.seeker_id
  ) t;

  return v_count;
end;
$$;


ALTER FUNCTION "public"."zyra_dev_guardians_on_decided"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_dev_reset_account"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
  v_saves int; v_likes int; v_passes int; v_unlocks int; v_credits int;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  -- Dev/preview accounts only. Same guard as the mock purchase functions.
  if not exists (
    select 1 from auth.users u
    where u.id = v_me and u.email like '%@zyra.test'
  ) then
    raise exception 'dev_accounts_only'
      using hint = 'zyra_dev_reset_account() is only callable by seeded @zyra.test accounts.';
  end if;

  delete from public.saves           where saver_id    = v_me;  get diagnostics v_saves   = row_count;
  delete from public.likes           where liker_id    = v_me;  get diagnostics v_likes   = row_count;
  delete from public.passes          where passer_id   = v_me;  get diagnostics v_passes  = row_count;
  delete from public.profile_unlocks where unlocker_id = v_me;  get diagnostics v_unlocks = row_count;
  delete from public.unlock_credits  where user_id     = v_me;  get diagnostics v_credits = row_count;

  return jsonb_build_object(
    'saves', v_saves, 'likes', v_likes, 'passes', v_passes,
    'unlocks', v_unlocks, 'credits', v_credits
  );
end;
$$;


ALTER FUNCTION "public"."zyra_dev_reset_account"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_dev_rewind_journey"("p_match_id" "uuid" DEFAULT NULL::"uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller    UUID := (SELECT auth.uid());
  v_email   TEXT;
  v_ids     UUID[];
  v_id      UUID;
  v_conv    UUID;
  n         INT;
  total     INT := 0;
  journeys  INT := 0;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Rewinding a Journey is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_match_id IS NULL THEN
    SELECT array_agg(id) INTO v_ids FROM matches
     WHERE seeker_a_id = caller OR seeker_b_id = caller;
  ELSE
    SELECT array_agg(id) INTO v_ids FROM matches
     WHERE id = p_match_id AND (seeker_a_id = caller OR seeker_b_id = caller);
    IF v_ids IS NULL THEN RAISE EXCEPTION 'not_a_party'; END IF;
  END IF;

  IF v_ids IS NULL THEN RETURN 'No Journeys on this account — nothing to rewind.'; END IF;

  -- GUARD BOTH PARTIES (2026-08-12): the loop below deletes the other
  -- party's rows, so every party of every affected match must be seeded.
  IF EXISTS (SELECT 1 FROM matches mm
              JOIN auth.users ua ON ua.id = mm.seeker_a_id
              JOIN auth.users ub ON ub.id = mm.seeker_b_id
             WHERE mm.id = ANY(v_ids)
               AND (ua.email IS NULL OR ua.email NOT LIKE '%@zyra.test'
                 OR ub.email IS NULL OR ub.email NOT LIKE '%@zyra.test')) THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of every affected match must be a seeded @zyra.test account.';
  END IF;

  FOREACH v_id IN ARRAY v_ids LOOP
    journeys := journeys + 1;

    DELETE FROM journey_phase_ratings     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_phase_answers     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_phase_checkpoints WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_answers    WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_stage_checkpoints WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_salams            WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_compatibility     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_requests          WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    DELETE FROM journey_family_review_responses
     WHERE review_id IN (SELECT id FROM journey_family_reviews WHERE match_id = v_id);
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_reviews WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    SELECT id INTO v_conv FROM conversations WHERE match_id = v_id LIMIT 1;
    IF v_conv IS NOT NULL THEN
      DELETE FROM messages WHERE conversation_id = v_conv; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
      UPDATE conversations SET status = 'closed', closed_at = NULL WHERE id = v_conv;
    END IF;

    -- How you met, and that this Journey began, both survive. Everything
    -- the Journey itself recorded from its first stage onwards goes.
    DELETE FROM timeline_milestones
     WHERE timeline_id IN (SELECT id FROM timelines WHERE match_id = v_id)
       AND milestone_type NOT IN ('liked', 'match_created', 'journey_started');
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    DELETE FROM notifications WHERE related_match_id = v_id;
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    -- SALAM FIRST (DR-ZYRA-183): a rewound Journey starts at the greeting.
    UPDATE matches
       SET journey_stage = 'salam_exchange',
           status        = 'active',
           suspended_by  = NULL, suspended_at = NULL,
           ended_at      = NULL, ended_by     = NULL,
           end_reason    = NULL, end_note     = NULL
     WHERE id = v_id;

    UPDATE journey_attempts
       SET journey_stage = 'salam_exchange', status = 'active'
     WHERE match_id = v_id;
  END LOOP;

  RETURN format('%s Journey(s) back at Salam Exchange. %s row(s) cleared.',
                journeys, total);
END;
$$;


ALTER FUNCTION "public"."zyra_dev_rewind_journey"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_dev_rewind_journey"("p_match_id" "uuid") IS 'DEV ONLY (@zyra.test). Destructive: wipes a Journey back to stage one, keeping the match, the Guardian link and how you met. NULL match id rewinds every Journey on the account. Not a product feature — see restart_journey(). Drop before public launch — OA-ZYRA-184.';



CREATE OR REPLACE FUNCTION "public"."zyra_dev_seed_journey"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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
    values (v_partner, caller, 'active', 'salam_exchange')
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

  select id into v_attempt from journey_attempts
   where match_id = v_match and attempt_number = 1;
  if v_attempt is null then raise exception 'attempt_not_created'; end if;

  insert into conversations (match_id, attempt_id, status)
  values (v_match, v_attempt, 'closed')
  on conflict (attempt_id) do nothing;

  insert into timelines (match_id, attempt_id)
  values (v_match, v_attempt)
  on conflict (attempt_id) do nothing;

  return format('Seeded a real Journey with %s — it starts at Salam Exchange.', v_name);
end;
$$;


ALTER FUNCTION "public"."zyra_dev_seed_journey"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_dev_set_compatibility"("p_match_id" "uuid", "p_score" numeric) RETURNS numeric
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_cats  JSONB;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Forcing a compatibility score is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_score < 0 OR p_score > 100 THEN
    RAISE EXCEPTION 'score_out_of_range' USING HINT = '0 to 100.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  -- GUARD BOTH PARTIES (2026-08-20, OA-ZYRA-200): this writes the shared
  -- journey_compatibility row for BOTH sides, so both parties must be
  -- seeded accounts, not just the caller.
  IF (SELECT count(*) FROM auth.users u
       WHERE u.id IN (m.seeker_a_id, m.seeker_b_id)
         AND u.email LIKE '%@zyra.test') < 2 THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of the match must be a seeded @zyra.test account.';
  END IF;

  v_cats := jsonb_build_object(
    'Deen',                least(100, greatest(0, p_score + 7)),
    'Marriage Goals',      least(100, greatest(0, p_score + 3)),
    'Communication',       least(100, greatest(0, p_score - 4)),
    'Lifestyle',           least(100, greatest(0, p_score - 9)),
    'Family Expectations', least(100, greatest(0, p_score + 1))
  );

  INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
  ON CONFLICT (match_id) DO NOTHING;

  -- BOTH sides set to the same figure, deliberately. This is a dev fixture
  -- for looking at a screen, not a simulation of the engine — and setting
  -- only the caller's would leave the other account showing nothing when
  -- the Founder switches to it to check the other half.
  UPDATE journey_compatibility
     SET seeker_a_score      = p_score,
         seeker_b_score      = p_score,
         seeker_a_categories = v_cats,
         seeker_b_categories = v_cats,
         seeker_a_revealed   = TRUE,
         seeker_b_revealed   = TRUE,
         revealed_at         = now()
   WHERE match_id = p_match_id;

  RETURN p_score;
END;
$$;


ALTER FUNCTION "public"."zyra_dev_set_compatibility"("p_match_id" "uuid", "p_score" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_dev_set_counterpart_reveal"("p_match_id" "uuid", "p_revealed" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_col   TEXT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Counterpart reveal is limited to seeded @zyra.test accounts.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  -- GUARD BOTH PARTIES (2026-08-20, OA-ZYRA-200): this sets the
  -- COUNTERPART's reveal flag — a write on the other person — so the
  -- other party must be a seeded account too.
  IF (SELECT count(*) FROM auth.users u
       WHERE u.id IN (m.seeker_a_id, m.seeker_b_id)
         AND u.email LIKE '%@zyra.test') < 2 THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of the match must be a seeded @zyra.test account.';
  END IF;

  -- The COUNTERPART's column, never the caller's. If the caller is A we set
  -- B, and the other way round. Getting this backwards would make the toggle
  -- silently set your own flag and look like it worked.
  v_col := CASE WHEN caller = m.seeker_a_id
                THEN 'seeker_b_revealed' ELSE 'seeker_a_revealed' END;

  INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
  ON CONFLICT (match_id) DO NOTHING;

  EXECUTE format('UPDATE journey_compatibility SET %I = $1 WHERE match_id = $2', v_col)
    USING p_revealed, p_match_id;

  RETURN p_revealed;
END;
$_$;


ALTER FUNCTION "public"."zyra_dev_set_counterpart_reveal"("p_match_id" "uuid", "p_revealed" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_dev_set_counterpart_reveal"("p_match_id" "uuid", "p_revealed" boolean) IS 'DEV ONLY. Sets the counterpart''s Compatibility Reveal flag so one tester can exercise both sides of a two-sided gate. Guarded server-side on @zyra.test. DROP BEFORE PUBLIC LAUNCH — OA-ZYRA-184.';



CREATE OR REPLACE FUNCTION "public"."zyra_dev_set_guardian_suggestions"("p_count" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
  v_my_gender text;
  v_wali uuid;
  v_ids uuid[];
  v_i int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (select 1 from auth.users u where u.id = v_me and u.email like '%@zyra.test') then
    raise exception 'dev_accounts_only';
  end if;
  if p_count < 0 or p_count > 10 then raise exception 'count_out_of_range'; end if;

  select gender into v_my_gender from public.profiles where id = v_me;

  select wali_id into v_wali from public.wali_links
    where seeker_id = v_me and status = 'active'
    order by is_main desc nulls last limit 1;
  if v_wali is null then
    select p.id into v_wali from public.profiles p join auth.users u on u.id = p.id
      where u.email = 'dev.guardian.a@zyra.test';
  end if;
  if v_wali is null then raise exception 'no_guardian_available'; end if;

  delete from public.wali_suggestions where seeker_id = v_me;
  if p_count = 0 then return jsonb_build_object('created', 0); end if;

  select array_agg(id) into v_ids from (
    select p.id
    from public.profiles p
    left join auth.users u on u.id = p.id
    where p.role = 'seeker' and p.is_active and p.profile_complete
      and p.id <> v_me
      and (v_my_gender is null or p.gender <> v_my_gender)
    order by
      (u.email like 'dev.sugg.%') desc,
      (exists (select 1 from public.profile_photos ph where ph.user_id = p.id)) desc,
      p.created_at
    limit p_count
  ) x;

  if v_ids is null then return jsonb_build_object('created', 0); end if;

  for v_i in 1..array_length(v_ids,1) loop
    insert into public.wali_suggestions (wali_id, seeker_id, suggested_id, status)
    values (v_wali, v_me, v_ids[v_i], 'pending')
    on conflict (wali_id, seeker_id, suggested_id) do nothing;
  end loop;

  return jsonb_build_object('created', array_length(v_ids,1));
end;
$$;


ALTER FUNCTION "public"."zyra_dev_set_guardian_suggestions"("p_count" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_dev_set_guardians_on_decided"("p_count" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
  v_pool uuid[];
  v_target uuid;
  v_targets uuid[];
  v_i int;
  v_links int := 0;
  -- Codes, never labels. 'uncle' renders as "Paternal Uncle".
  v_rel text[] := array['father','brother','uncle'];
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (select 1 from auth.users u where u.id = v_me and u.email like '%@zyra.test') then
    raise exception 'dev_accounts_only';
  end if;
  if p_count < 0 or p_count > 3 then raise exception 'count_out_of_range'; end if;

  select array_agg(p.id order by u.email)
    into v_pool
  from public.profiles p
  join auth.users u on u.id = p.id
  where u.email in ('dev.guardian.a@zyra.test','dev.guardian.b@zyra.test','dev.guardian.c@zyra.test');

  if v_pool is null then raise exception 'guardian_pool_missing'; end if;

  -- Everyone this account has decided on, in any direction.
  select array_agg(distinct t) into v_targets from (
    select saved_id  as t from public.saves  where saver_id  = v_me
    union select liked_id     from public.likes  where liker_id  = v_me
    union select passed_id    from public.passes where passer_id = v_me
  ) s;

  if v_targets is null then
    return jsonb_build_object('targets', 0, 'links', 0);
  end if;

  foreach v_target in array v_targets loop
    -- Clear only the pool's links, never a real one made through an invite.
    delete from public.wali_links
      where seeker_id = v_target and wali_id = any(v_pool);

    for v_i in 1..p_count loop
      insert into public.wali_links (seeker_id, wali_id, status, is_main, relationship)
      values (v_target, v_pool[v_i], 'active', v_i = 1, v_rel[v_i])
      on conflict (seeker_id, wali_id) do update
        set status = 'active',
            is_main = excluded.is_main,
            relationship = excluded.relationship;
      v_links := v_links + 1;
    end loop;
  end loop;

  return jsonb_build_object('targets', array_length(v_targets,1), 'links', v_links);
end;
$$;


ALTER FUNCTION "public"."zyra_dev_set_guardians_on_decided"("p_count" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_dev_set_journey_stage"("p_match_id" "uuid", "p_stage" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Stage jumping is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_stage NOT IN ('compatibility_reveal','salam_exchange','wali_gate',
                     'phase_1','phase_2','phase_3','family_stage','conversation') THEN
    RAISE EXCEPTION 'unknown_stage'
      USING HINT = 'Stage must be one of the eight in zyra_journey_stages.dart.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  -- GUARD BOTH PARTIES (2026-08-20, OA-ZYRA-200): stage jumps rewrite the
  -- shared match / journey_attempts / conversations rows, so both parties
  -- must be seeded accounts.
  IF (SELECT count(*) FROM auth.users u
       WHERE u.id IN (m.seeker_a_id, m.seeker_b_id)
         AND u.email LIKE '%@zyra.test') < 2 THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of the match must be a seeded @zyra.test account.';
  END IF;

  IF m.status <> 'active' THEN
    RAISE EXCEPTION 'journey_not_active'
      USING HINT = 'Only an Active Journey has stages to jump between.';
  END IF;

  UPDATE matches SET journey_stage = p_stage WHERE id = p_match_id;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status = 'active'
   ORDER BY a.attempt_number DESC LIMIT 1;

  IF v_attempt IS NULL THEN
    RAISE EXCEPTION 'no_active_attempt'
      USING HINT = 'The Journey is active but has no active attempt row.';
  END IF;

  UPDATE journey_attempts SET journey_stage = p_stage WHERE id = v_attempt;

  -- CHANGED IN STAGE 4a: conflict target is now attempt_id, and attempt_id is
  -- NOT NULL, so v_attempt is required rather than optional. Previously this
  -- inserted with a possibly-NULL attempt_id and conflicted on match_id —
  -- both of which stopped being legal in the statements above.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (p_match_id, v_attempt, 'active')
  ON CONFLICT (attempt_id) DO UPDATE SET status = 'active', closed_at = NULL;

  INSERT INTO timelines (match_id, attempt_id)
  VALUES (p_match_id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;

  RETURN p_stage;
END;
$$;


ALTER FUNCTION "public"."zyra_dev_set_journey_stage"("p_match_id" "uuid", "p_stage" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_dev_set_journey_stage"("p_match_id" "uuid", "p_stage" "text") IS 'DEV ONLY. Jumps an Active Journey to any stage, skipping the Pre-Journey Ritual, Guardian Gate and Family Review. Guarded server-side on @zyra.test (OA-ZYRA-171). DROP BEFORE PUBLIC LAUNCH — audit item #20.';



CREATE OR REPLACE FUNCTION "public"."zyra_dev_set_plus_unlock"("p_other_id" "uuid", "p_has" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Plus simulation is limited to seeded @zyra.test accounts.';
  END IF;
  IF p_other_id = caller THEN RAISE EXCEPTION 'not_a_party'; END IF;

  IF p_has THEN
    INSERT INTO profile_unlocks (unlocker_id, unlocked_id, unlock_type)
    VALUES (caller, p_other_id, 'paid_plus_single')
    ON CONFLICT DO NOTHING;
  ELSE
    -- Removes ONLY the simulated Plus row, never a real purchase of another
    -- type. A dev tool that deleted a paid_single would be destroying a
    -- record of money.
    DELETE FROM profile_unlocks
     WHERE unlocker_id = caller AND unlocked_id = p_other_id
       AND unlock_type = 'paid_plus_single';
  END IF;
  RETURN p_has;
END;
$$;


ALTER FUNCTION "public"."zyra_dev_set_plus_unlock"("p_other_id" "uuid", "p_has" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_dev_set_plus_unlock"("p_other_id" "uuid", "p_has" boolean) IS 'DEV ONLY. Simulates a Compatibility Unlock+ purchase. Guarded server-side on @zyra.test. DROP BEFORE PUBLIC LAUNCH — OA-ZYRA-184, now NINE functions.';



CREATE OR REPLACE FUNCTION "public"."zyra_dev_set_seeker_plan"("p_plan" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (
    select 1 from auth.users u
    where u.id = v_me and u.email like '%@zyra.test'
  ) then
    raise exception 'dev_accounts_only'
      using hint = 'zyra_dev_set_seeker_plan() is only callable by seeded @zyra.test accounts.';
  end if;
  if p_plan not in ('seeker_basic', 'seeker_premium') then
    raise exception 'unknown_plan'
      using hint = 'seeker_basic or seeker_premium.';
  end if;
  -- Seekers only: a wali account's plan is wali_basic/wali_premium and is
  -- driven by its own mock flow (mock_set_wali_plan).
  if not exists (
    select 1 from public.profiles p where p.id = v_me and p.role = 'seeker'
  ) then
    raise exception 'seekers_only';
  end if;

  -- One active seeker row per user (partial unique index on user_id WHERE
  -- status='active'). Update it in place; insert only when the seed left
  -- no row at all.
  update public.subscriptions
     set plan_type = p_plan, started_at = now()
   where user_id = v_me
     and status = 'active'
     and plan_type in ('seeker_basic', 'seeker_premium');
  if not found then
    insert into public.subscriptions (user_id, plan_type, status, started_at)
    values (v_me, p_plan, 'active', now());
  end if;

  return jsonb_build_object('plan', p_plan);
end;
$$;


ALTER FUNCTION "public"."zyra_dev_set_seeker_plan"("p_plan" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_end_match_internal"("p_match_id" "uuid", "p_ended_by" "uuid", "p_reason" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_end_match_internal"("p_match_id" "uuid", "p_ended_by" "uuid", "p_reason" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_end_match_internal"("p_match_id" "uuid", "p_ended_by" "uuid", "p_reason" "text") IS 'THE only way a Journey ends. Ordinary endings and block-endings both go through here so their observable artefacts are byte-identical and differ only in end_reason, which zyra_match_ending() conceals. Do not add a second ending path — a difference between two paths is a disclosure channel. NOT client-callable: p_ended_by would be forgeable.';



CREATE OR REPLACE FUNCTION "public"."zyra_enforce_guardian_link_allowed"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- A link being retired is always permitted. The rule guards the creation
  -- of a bond, not its ending — and blocking removal would strand people.
  IF NEW.status = 'removed' THEN
    RETURN NEW;
  END IF;

  IF NOT public.zyra_can_guardian_link(NEW.seeker_id, NEW.wali_id) THEN
    RAISE EXCEPTION 'romantic_edge_exists'
      USING HINT = 'These two people have a Journey together. A Guardian '
                   'relationship cannot be created over one. End the Journey '
                   'first if that is really what you both want.';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."zyra_enforce_guardian_link_allowed"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_enforce_one_active_attempt"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_enforce_one_active_attempt"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_enforce_one_active_attempt"() IS 'LIVE as of 2026-08-08 step 5 — promote_journey_to_active() now sets an attempt''s status to active, so this fires. Runs alongside zyra_enforce_one_active_match() on matches; both raise one_active_journey_limit. The matches one retires at step 7.';



CREATE OR REPLACE FUNCTION "public"."zyra_enforce_one_active_match"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_enforce_one_active_match"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_enforce_one_active_match"() IS 'One Active Journey per PERSON — the platform invariant. The two per-side partial indexes on matches cannot express it (a person can be seeker_a on one and seeker_b on another); this can. Kept alongside them, not instead of: they still catch the same-side case cheaply. Moves to journey_attempts at step 7, once an attempt''s status is actually maintained.';



CREATE OR REPLACE FUNCTION "public"."zyra_expire_due_journey_requests"("p_match_id" "uuid" DEFAULT NULL::"uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  k_cooldown CONSTANT INTERVAL := INTERVAL '6 months';  -- DR-121 item 16, a guess
  r     RECORD;
  v_cnt INT := 0;
BEGIN
  FOR r IN
    SELECT * FROM journey_requests
     WHERE status = 'pending'
       AND expires_at <= NOW()
       AND (p_match_id IS NULL OR match_id = p_match_id)
     FOR UPDATE SKIP LOCKED
  LOOP
    UPDATE journey_requests
       SET status = 'declined', responded_at = NOW()
     WHERE id = r.id;

    -- Same hold a plain decline creates. ON CONFLICT is not available here —
    -- protection_holds deliberately has no unique key, because holds coexist
    -- (DR-121 item 5) — so guard on an existing ACTIVE hold instead, or a
    -- second expiry on the same pair would stack a second cooldown and
    -- silently double the wait.
    IF NOT zyra_hold_blocks(r.requested_by, r.requested_to) THEN
      INSERT INTO protection_holds
        (match_id, restricted_id, protected_id, hold_type, appealable, expires_at)
      VALUES (r.match_id, r.requested_by, r.requested_to,
              'decline_cooldown', TRUE, NOW() + k_cooldown);
    END IF;

    -- Byte-identical to the decline notification in
    -- respond_to_journey_request. If you change one, change both — the whole
    -- design rests on the requester being unable to tell them apart.
    PERFORM create_notification(
      r.requested_by, 'journey_request_declined', 'Journey request',
      'Your request to begin a new Journey was not taken up.', r.match_id);

    v_cnt := v_cnt + 1;
  END LOOP;

  RETURN v_cnt;
END;
$$;


ALTER FUNCTION "public"."zyra_expire_due_journey_requests"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_expire_due_journey_requests"("p_match_id" "uuid") IS 'OA-ZYRA-159 stage 5. Expires pending Journey requests past their 14-day window, treating expiry exactly as a decline — same status, same 6-month cooldown, same notification wording. Called lazily by the client on load, the same pattern as resolve_family_review_if_due. Pass NULL to sweep all.';



CREATE OR REPLACE FUNCTION "public"."zyra_expire_due_wali_invites"() RETURNS TABLE("expiring_count" integer, "expired_count" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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
     order by coalesce(wi.request_expires_at, wi.expires_at)
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
        perform public.create_notification(
          v_me,
          'wali_invite_expiring',
          'Guardian invitation expiring',
          case when v_label is null
            then 'A Guardian invitation expires in two days.'
            else v_label || '''s Guardian invitation expires in two days.'
          end,
          null
        );
      end if;
    end if;
  end loop;

  return query select v_expiring, v_expired;
end;
$$;


ALTER FUNCTION "public"."zyra_expire_due_wali_invites"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_guardian_activity"() RETURNS TABLE("wali_id" "uuid", "activity_type" "text", "occurred_at" timestamp with time zone, "detail" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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
  join public.matches m on m.id = rev.match_id
  where (select auth.uid()) in (m.seeker_a_id, m.seeker_b_id)

  union all

  -- A review is open and the Main Guardian has not answered it.
  -- Scoped to Main because only the Main Guardian is asked to act — the
  -- same rule the page already states in its own copy.
  select g.wali_id, 'review_waiting', rev.opened_at, null
  from public.journey_family_reviews rev
  join public.matches m on m.id = rev.match_id
  join my_guardians g on g.is_main
  where rev.status = 'open'
    and (select auth.uid()) in (m.seeker_a_id, m.seeker_b_id)
    and not exists (
      select 1 from public.journey_family_review_responses rr
      where rr.review_id = rev.id and rr.wali_id = g.wali_id
    )

  order by 3 desc nulls last;
$$;


ALTER FUNCTION "public"."zyra_guardian_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_guardian_history_consent"("p_guardian" "uuid", "p_enabled" boolean DEFAULT NULL::boolean) RETURNS TABLE("enabled" boolean, "active_guardian_link_id" "uuid", "guardian_id" "uuid", "guardian_is_main" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_guardian_history_consent"("p_guardian" "uuid", "p_enabled" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_guardian_history_consent"("p_guardian" "uuid", "p_enabled" boolean) IS 'DR-ZYRA-233 Seeker-owned, caller-derived permission for one current active Guardian to see all past four-field Journey summaries. NULL reads; TRUE grants; FALSE revokes. No counterpart identity, stage, messages, answers, reasons, notes or safety information is returned or authorised.';



CREATE OR REPLACE FUNCTION "public"."zyra_guardian_journey_access"("p_guardian" "uuid", "p_attempt" "uuid" DEFAULT NULL::"uuid", "p_enabled" boolean DEFAULT NULL::boolean) RETURNS TABLE("attempt_id" "uuid", "match_id" "uuid", "counterpart_first_name" "text", "included" boolean, "can_change" boolean, "guardian_is_main" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_is_main boolean;
begin
  if v_caller is null then
    raise exception 'not_signed_in';
  end if;
  if p_guardian is null then
    raise exception 'guardian_required';
  end if;
  if (p_attempt is null) <> (p_enabled is null) then
    raise exception 'attempt_and_enabled_must_be_supplied_together';
  end if;

  select w.id, w.is_main
  into v_link_id, v_is_main
  from public.wali_links w
  where w.seeker_id = v_caller
    and w.wali_id = p_guardian
    and w.status = 'active';

  if not found then
    raise exception 'active_guardian_link_not_found';
  end if;

  if p_attempt is not null then
    if v_is_main then
      raise exception 'main_guardian_always_included';
    end if;
    if not exists (
      select 1
      from public.journey_attempts a
      join public.matches m on m.id = a.match_id
      where a.id = p_attempt
        and a.status = 'active'
        and v_caller in (m.seeker_a_id, m.seeker_b_id)
    ) then
      raise exception 'active_owned_journey_not_found';
    end if;

    if p_enabled then
      insert into public.journey_guardian_assignments (
        attempt_id, wali_link_id, seeker_id, granted_by
      ) values (
        p_attempt, v_link_id, v_caller, v_caller
      )
      on conflict (attempt_id, wali_link_id) where revoked_at is null
      do nothing;
    else
      update public.journey_guardian_assignments jga
      set revoked_by = v_caller,
          revoked_at = pg_catalog.clock_timestamp()
      where jga.attempt_id = p_attempt
        and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller
        and jga.revoked_at is null;
    end if;
  end if;

  return query
  select a.id,
         a.match_id,
         other_profile.first_name,
         (
           v_is_main
           or exists (
             select 1
             from public.journey_guardian_assignments jga
             where jga.attempt_id = a.id
               and jga.wali_link_id = v_link_id
               and jga.seeker_id = v_caller
               and jga.revoked_at is null
           )
         ),
         not v_is_main,
         v_is_main
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  join public.profiles other_profile
    on other_profile.id = case
      when m.seeker_a_id = v_caller then m.seeker_b_id
      else m.seeker_a_id
    end
  where a.status = 'active'
    and v_caller in (m.seeker_a_id, m.seeker_b_id)
  order by a.started_at desc nulls last, a.created_at desc, a.id;
end;
$$;


ALTER FUNCTION "public"."zyra_guardian_journey_access"("p_guardian" "uuid", "p_attempt" "uuid", "p_enabled" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_guardian_journey_access"("p_guardian" "uuid", "p_attempt" "uuid", "p_enabled" boolean) IS 'Reads or changes one Seeker-owned Guardian link across the caller''s active Journeys. Main is immutable ON. Additional changes are server-confirmed, per attempt and audited; no caller may act for the other Seeker.';



CREATE OR REPLACE FUNCTION "public"."zyra_hold_blocks"("p_restricted" "uuid", "p_protected" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.protection_holds h
     WHERE h.restricted_id = p_restricted
       AND h.protected_id  = p_protected
       AND h.released_at IS NULL
       AND (h.expires_at IS NULL OR h.expires_at > NOW())
  );
$$;


ALTER FUNCTION "public"."zyra_hold_blocks"("p_restricted" "uuid", "p_protected" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_hold_blocks"("p_restricted" "uuid", "p_protected" "uuid") IS 'OA-ZYRA-157. True if an active hold restricts p_restricted toward p_protected. Boolean only, by design — the reason and the expiry must never reach the restricted person. EXECUTE withheld from authenticated: server-side callers only.';



CREATE OR REPLACE FUNCTION "public"."zyra_journey_busy_flags"("p_match_ids" "uuid"[]) RETURNS TABLE("match_id" "uuid", "in_another_journey" boolean)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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
    AND auth.uid() IN (requested.seeker_a_id, requested.seeker_b_id);
$$;


ALTER FUNCTION "public"."zyra_journey_busy_flags"("p_match_ids" "uuid"[]) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_journey_busy_flags"("p_match_ids" "uuid"[]) IS 'For requested Journey rows owned by auth.uid(), returns whether the other party has a different unsuspended active match. OA-ZYRA-204.';



CREATE OR REPLACE FUNCTION "public"."zyra_journey_compatibility_state"("p_match_id" "uuid") RETURNS TABLE("mine_revealed" boolean, "counterpart_revealed" boolean, "my_score" numeric)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_journey_compatibility_state"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_journey_compatibility_state"("p_match_id" "uuid") IS 'OA-ZYRA-283. Current active Journey compatibility state, caller-relative. Returns mutual flags and only the caller-owned score after mutual reveal.';



CREATE OR REPLACE FUNCTION "public"."zyra_light_weight"("p_light" "text") RETURNS numeric
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO 'public'
    AS $$
  select case p_light
           when 'green'  then 1.0
           when 'yellow' then 0.5
           when 'red'    then 0.0
           else 0.0
         end::numeric;
$$;


ALTER FUNCTION "public"."zyra_light_weight"("p_light" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_light_weight"("p_light" "text") IS 'The ratified light weighting (OA-ZYRA-193a): green 1, yellow 0.5, red 0. Replaces zyra_light_points, which encoded the retired centred scale.';



CREATE OR REPLACE FUNCTION "public"."zyra_like_clears_others"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  DELETE FROM passes WHERE passer_id = NEW.liker_id AND passed_id = NEW.liked_id;
  DELETE FROM saves  WHERE saver_id  = NEW.liker_id AND saved_id  = NEW.liked_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."zyra_like_clears_others"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_main_guardian_history_consent"("p_enabled" boolean DEFAULT NULL::boolean) RETURNS TABLE("enabled" boolean, "active_main_link_id" "uuid", "main_guardian_id" "uuid")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_main_guardian_history_consent"("p_enabled" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_main_guardian_history_consent"("p_enabled" boolean) IS 'Compatibility wrapper for DR-ZYRA-225 clients. Reads or changes the current Main Guardian through zyra_guardian_history_consent(uuid, boolean).';



CREATE OR REPLACE FUNCTION "public"."zyra_mark_suggestions_seen"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_mark_suggestions_seen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_match_ending"("p_match_id" "uuid") RETURNS TABLE("ended_by" "uuid", "end_reason" "text", "end_note" "text", "ended_at" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    m.ended_by,
    case
      -- Only the person who raised it sees what they raised.
      when m.ended_by = (select auth.uid()) then m.end_reason
      -- Everyone else: the five joint reasons pass through untouched;
      -- safety_concern becomes a reason that already exists, is already
      -- common, and carries no signal.
      when m.end_reason = 'safety_concern' then 'prefer_not_to_say'
      else m.end_reason
    end,
    case
      when m.ended_by = (select auth.uid()) then m.end_note
      when m.end_reason = 'safety_concern' then null
      else m.end_note
    end,
    m.ended_at
  from public.matches m
  where m.id = p_match_id
    -- MIRRORS matches_select EXACTLY, so the accessor can never be more
    -- permissive than the row policy. Written out rather than delegating to
    -- zyra_can_view_attempt(), which takes an ATTEMPT id — passing a match
    -- id to it would have silently returned false for everyone.
    and (
      m.seeker_a_id = (select auth.uid())
      or m.seeker_b_id = (select auth.uid())
      or (m.status <> 'potential' and exists (
            select 1 from public.wali_links wl
            where wl.wali_id = (select auth.uid())
              and wl.status = 'active'
              and wl.seeker_id = any (array[m.seeker_a_id, m.seeker_b_id])
         ))
    );
$$;


ALTER FUNCTION "public"."zyra_match_ending"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_match_ending"("p_match_id" "uuid") IS 'THE only route to how a Journey ended. Substitutes prefer_not_to_say for safety_concern for everyone except the person who raised it — including their own Guardian (Founder, strict, 2026-08-08). GOVERNANCE RULE FOR CALLERS: prefer_not_to_say must render identically whether genuine or substituted. One string, one layout, one behaviour. A different tone, an extra sentence or a separate code path would make the rendering the disclosure.';



CREATE OR REPLACE FUNCTION "public"."zyra_may_request_new_journey"("p_match_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  caller UUID := (SELECT auth.uid());
  m RECORD; other UUID;
BEGIN
  IF caller IS NULL THEN RETURN FALSE; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN RETURN FALSE; END IF;
  other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  IF m.status <> 'ended' THEN RETURN FALSE; END IF;
  IF m.ended_at IS NULL OR NOW() < m.ended_at + INTERVAL '24 hours' THEN RETURN FALSE; END IF;
  IF zyra_block_exists(other) THEN RETURN FALSE; END IF;
  IF NOT zyra_can_match(caller, other) THEN RETURN FALSE; END IF;
  IF zyra_hold_blocks(caller, other) THEN RETURN FALSE; END IF;
  -- 2026-08-12: per the caller's plan cap; paused Journeys never count.
  IF zyra_active_journey_count(caller) >= zyra_active_journey_cap(caller) THEN RETURN FALSE; END IF;
  IF EXISTS (SELECT 1 FROM journey_requests r
              WHERE r.match_id = p_match_id AND r.status='pending') THEN RETURN FALSE; END IF;
  RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."zyra_may_request_new_journey"("p_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_may_request_new_journey_ids"() RETURNS SETOF "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT m.id
    FROM matches m
   WHERE (m.seeker_a_id = (SELECT auth.uid()) OR m.seeker_b_id = (SELECT auth.uid()))
     AND m.status = 'ended'
     AND public.zyra_may_request_new_journey(m.id);
$$;


ALTER FUNCTION "public"."zyra_may_request_new_journey_ids"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_may_request_new_journey_ids"() IS 'OA-ZYRA-159 stage 5b. The ended match_ids on which the caller may request a new Journey, in one query. Absence carries no reason, by design.';



CREATE OR REPLACE FUNCTION "public"."zyra_milestone_attestation_state"("p_match_id" "uuid") RETURNS TABLE("id" "uuid", "milestone_type" "text", "occurred_on" "date", "proposed_by" "uuid")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE caller UUID := auth.uid(); m RECORD; v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RETURN; END IF;
  SELECT * INTO m FROM matches WHERE matches.id = p_match_id;
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


ALTER FUNCTION "public"."zyra_milestone_attestation_state"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_milestone_attestation_state"("p_match_id" "uuid") IS 'Pending attestations for the caller''s match — the Timeline screen''s read path; table itself has no grants.';



CREATE OR REPLACE FUNCTION "public"."zyra_my_guardian_requests"() RETURNS TABLE("request_id" "uuid", "direction" "text", "other_first_name" "text", "other_role" "text", "status" "text", "relationship" "text", "created_at" timestamp with time zone, "expires_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_my_guardian_requests"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_my_identity_verification_allows_active_journey"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'private'
    AS $$
  select coalesce((
    select result = 'verified' and duplicate_review_required is false
    from private.identity_verification_attempts
    where user_id = auth.uid() and member_deleted_at is null
    order by (result = 'verified') desc, created_at desc
    limit 1
  ), false);
$$;


ALTER FUNCTION "public"."zyra_my_identity_verification_allows_active_journey"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_my_identity_verification_allows_app"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'private'
    AS $$
  select coalesce((
    select result = 'verified'
    from private.identity_verification_attempts
    where user_id = auth.uid() and member_deleted_at is null
    order by (result = 'verified') desc, created_at desc
    limit 1
  ), false);
$$;


ALTER FUNCTION "public"."zyra_my_identity_verification_allows_app"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_my_identity_verification_state"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'private'
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


ALTER FUNCTION "public"."zyra_my_identity_verification_state"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_my_onboarding_progress"() RETURNS TABLE("complete" boolean, "questions_due" integer, "questions_missing" integer, "has_chapter_2" boolean, "basic_profile" boolean)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_my_onboarding_progress"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_my_personal_code"("p_role_context" "text" DEFAULT NULL::"text") RETURNS TABLE("code" "text", "role_context" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_my_personal_code"("p_role_context" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_my_safety_cases"() RETURNS TABLE("case_id" "uuid", "case_type" "text", "status" "text", "created_at" timestamp with time zone, "updated_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_my_safety_cases"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_my_safety_cases"() IS 'Caller-scoped safety case status only. Never returns the reported person identity and remains available regardless of membership state.';



CREATE OR REPLACE FUNCTION "public"."zyra_normalise_profile_identity"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NEW.first_name IS NOT NULL THEN
    NEW.first_name := btrim(NEW.first_name);
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."zyra_normalise_profile_identity"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_normalise_profile_identity"() IS 'Trims first_name on every write path. Deliberately NOT extended to surname_line or bio — those have the same missing-limit problem but no agreed limit yet, and inventing one here would be a decision smuggled into a migration. See ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION.';



CREATE OR REPLACE FUNCTION "public"."zyra_notification_category"("p_type" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO 'public'
    AS $$
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
$$;


ALTER FUNCTION "public"."zyra_notification_category"("p_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_notification_preferences"() RETURNS TABLE("category" "text", "enabled" boolean, "changed_at" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  with defaults(category, enabled) as (
    values ('matches_journeys',  true),
           ('guardian_activity', true),
           ('introductions',     true),
           -- OFF by default. Under UK GDPR consent is a positive opt-in and
           -- a pre-ticked box is not consent, so "no row" must read as "no".
           ('marketing_emails',  false),
           ('product_updates',   false)
  ),
  latest as (
    select distinct on (p.category)
           p.category, p.enabled, p.changed_at
    from public.notification_preferences p
    where p.user_id = (select auth.uid())
    order by p.category, p.seq desc
  )
  select d.category,
         coalesce(l.enabled, d.enabled),
         l.changed_at
  from defaults d
  left join latest l on l.category = d.category;
$$;


ALTER FUNCTION "public"."zyra_notification_preferences"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_onboarding_complete"("p_user" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles p
     WHERE p.id = p_user AND p.role = 'seeker'
       AND p.profile_complete
       AND zyra_onboarding_data_complete(p.id, p.gender)
  );
$$;


ALTER FUNCTION "public"."zyra_onboarding_complete"("p_user" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_onboarding_complete"("p_user" "uuid") IS 'OA-ZYRA-193(c). True when this Seeker has finished onboarding: basic profile, Chapter 2, and every Chapter 3/4 question they were actually shown. Applicability accounts for gender AND conditional showIf rules — a question skipped because it did not apply is not missing.';



CREATE OR REPLACE FUNCTION "public"."zyra_onboarding_data_complete"("p_user" "uuid", "p_gender" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_onboarding_data_complete"("p_user" "uuid", "p_gender" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_onboarding_missing"("p_user" "uuid") RETURNS TABLE("qid" "text", "needs_answer" boolean, "needs_preference" boolean)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_onboarding_missing"("p_user" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_pass_clears_others"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  DELETE FROM likes WHERE liker_id = NEW.passer_id AND liked_id = NEW.passed_id;
  DELETE FROM saves WHERE saver_id = NEW.passer_id AND saved_id = NEW.passed_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."zyra_pass_clears_others"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_preview_personal_code"("p_code" "text") RETURNS TABLE("owner_first_name" "text", "owner_role" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_owner_role text;
  v_my_role text;
  v_first_name text;
  v_allowed boolean := false;
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
      where a.caller_id = v_me and a.attempted_at >= clock_timestamp() - interval '1 hour') >= 10
     or
     (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me and a.attempted_at >= clock_timestamp() - interval '1 day') >= 30 then
    return;
  end if;

  select c.owner_id, c.role_context, p.first_name
    into v_owner, v_owner_role, v_first_name
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id and p.role = c.role_context
  where c.code = v_code;
  select p.role into v_my_role from public.profiles p where p.id = v_me;

  v_allowed := coalesce(v_owner is not null
    and v_owner <> v_me
    and private.zyra_identity_verification_allows_user(v_owner)
    and v_my_role in ('seeker', 'wali')
    and v_owner_role <> v_my_role
    and not public.zyra_block_exists(v_owner)
    and public.zyra_can_guardian_link(v_me, v_owner)
    and not exists (
      select 1 from public.wali_links wl
      where ((wl.seeker_id = v_me and wl.wali_id = v_owner)
          or (wl.seeker_id = v_owner and wl.wali_id = v_me))
        and wl.status = 'active'
    ), false);

  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, v_allowed);
  if not v_allowed then return; end if;

  return query select v_first_name, v_owner_role;
end;
$$;


ALTER FUNCTION "public"."zyra_preview_personal_code"("p_code" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_preview_personal_code"("p_code" "text") IS 'Authenticated, rate-limited and neutral-on-failure preview. Returns first name and role only; no photo and no identity-verification claim.';



CREATE OR REPLACE FUNCTION "public"."zyra_profiles_set_onboarding_complete"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- BEFORE, and computed from NEW: no second write, so no recursion.
  NEW.onboarding_complete :=
    (NEW.role = 'seeker' AND NEW.profile_complete
     AND zyra_onboarding_data_complete(NEW.id, NEW.gender));
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."zyra_profiles_set_onboarding_complete"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_propose_milestone"("p_match_id" "uuid", "p_type" "text", "p_occurred_on" "date") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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

  SELECT * INTO m FROM matches WHERE id = p_match_id;
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


ALTER FUNCTION "public"."zyra_propose_milestone"("p_match_id" "uuid", "p_type" "text", "p_occurred_on" "date") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_propose_milestone"("p_match_id" "uuid", "p_type" "text", "p_occurred_on" "date") IS 'Proposes a meeting/nikah milestone (Founder 2026-08-12). Party-only, active un-paused Journeys, never future-dated, one pending per type; the counterpart is notified and must confirm before anything reaches the Timeline.';



CREATE OR REPLACE FUNCTION "public"."zyra_question_is_due"("p_qid" "text", "p_gender" "text", "p_answers" "jsonb") RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_question_is_due"("p_qid" "text", "p_gender" "text", "p_answers" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_record_identity_verification_consent"("p_consent_version" "text", "p_granted" boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'private'
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


ALTER FUNCTION "public"."zyra_record_identity_verification_consent"("p_consent_version" "text", "p_granted" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_record_identity_verification_provider_result"("p_provider_code" "text", "p_provider_session_ref" "text", "p_result" "text", "p_duplicate_review_required" boolean, "p_provider_event_ref_hash" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'private'
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


ALTER FUNCTION "public"."zyra_record_identity_verification_provider_result"("p_provider_code" "text", "p_provider_session_ref" "text", "p_result" "text", "p_duplicate_review_required" boolean, "p_provider_event_ref_hash" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_record_journey_milestone"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_record_journey_milestone"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_record_journey_milestone"() IS 'Writes a Timeline milestone whenever a match starts, advances a Journey stage forward, or ends. Forward-only, so a dev rewind leaves no trace. One place, because journey_stage is moved from five.';



CREATE OR REPLACE FUNCTION "public"."zyra_refresh_onboarding_complete"("p_user" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_refresh_onboarding_complete"("p_user" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_remove_guardian"("p_wali_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_me     uuid := auth.uid();
  v_main   boolean;
  v_others int;
  v_n      int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select is_main into v_main
  from public.wali_links
  where seeker_id = v_me and wali_id = p_wali_id and status = 'active';

  if not found then
    raise exception 'not_your_guardian';
  end if;

  select count(*) into v_others
  from public.wali_links
  where seeker_id = v_me and wali_id <> p_wali_id and status = 'active';

  -- UNCHANGED. Removing your Main while others remain leaves is_main unset
  -- with no promotion, and Family Review reads is_main.
  if coalesce(v_main, false) and v_others > 0 then
    raise exception 'main_guardian_must_be_reassigned';
  end if;

  -- NEW -- DR-ZYRA-136 / OA-ZYRA-173.
  -- Checked against `matches`, which stays authoritative until OA-ZYRA-156
  -- step 7. A paused Journey counts: pause is a behavioural flag on an
  -- ACTIVE Journey (DR-ZYRA-121 item 13), not a lifecycle state, so the
  -- commitment is still live and so is the requirement.
  if v_others = 0 and exists (
    select 1 from public.matches m
     where m.status = 'active'
       and (m.seeker_a_id = v_me or m.seeker_b_id = v_me)
  ) then
    raise exception 'guardian_required_during_journey'
      using hint = 'An active or paused Journey requires you to keep a '
                   'Guardian. Assign another Guardian where possible, or '
                   'end the Journey through the governed flow before '
                   'removing this one.';
  end if;

  update public.wali_links
     set status = 'removed', is_main = false
   where seeker_id = v_me and wali_id = p_wali_id;

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$$;


ALTER FUNCTION "public"."zyra_remove_guardian"("p_wali_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_remove_guardian"("p_wali_id" "uuid") IS 'DR-ZYRA-136 / OA-ZYRA-173. Refuses removal of a Seeker''s LAST Guardian while they are party to an active Journey (a paused Journey counts — pause is a flag on an active Journey, not a state). Ending or pausing the Journey remains free.';



CREATE OR REPLACE FUNCTION "public"."zyra_request_guardian_link"("p_code" "text", "p_relationship" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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

  insert into public.wali_invites(
    token, inviter_id, inviter_role, status, relationship, source,
    personal_code_id, recipient_id, expires_at, request_expires_at
  ) values (
    'REQ-' || upper(encode(extensions.gen_random_bytes(12), 'hex')),
    v_owner, v_owner_role, 'pending',
    case when v_my_role = 'wali' then p_relationship else null end,
    'personal_code', v_code_id, v_me,
    clock_timestamp() + interval '30 days',
    clock_timestamp() + interval '30 days'
  )
  returning id into v_request_id;

  perform public.create_notification(
    v_owner, 'wali_request', 'Guardian request',
    coalesce(v_my_name, 'Someone') || ' sent you a Guardian request.', null
  );
  return v_request_id;
exception
  when unique_violation then raise exception 'request_already_pending';
end;
$$;


ALTER FUNCTION "public"."zyra_request_guardian_link"("p_code" "text", "p_relationship" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_request_guardian_link"("p_code" "text", "p_relationship" "text") IS 'Creates a 30-day two-sided request against a permanent ZYRA Code. Never creates or reactivates wali_links; owner acceptance is mandatory.';



CREATE OR REPLACE FUNCTION "public"."zyra_reset_profile"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_me      uuid := auth.uid();
  v_role    text;
  v_active  int;
  v_paths   text[];
  v_photos  int;
  v_likes   int;
  v_saves   int;
  v_passes  int;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT role INTO v_role FROM public.profiles WHERE id = v_me;
  IF v_role IS NULL THEN
    RAISE EXCEPTION 'no_profile';
  END IF;
  IF v_role <> 'seeker' THEN
    RETURN jsonb_build_object('status','refused','reason','not_a_seeker');
  END IF;

  SELECT count(*) INTO v_active
    FROM public.matches
   WHERE status = 'active'
     AND (seeker_a_id = v_me OR seeker_b_id = v_me);

  IF v_active > 0 THEN
    RETURN jsonb_build_object(
      'status','blocked', 'reason','active_journey', 'active', v_active);
  END IF;

  -- OWN PREFIX ONLY — see the header. The row is still deleted either way;
  -- it is only the bucket instruction that is withheld.
  SELECT coalesce(array_agg(storage_path), '{}')
    INTO v_paths
    FROM public.profile_photos
   WHERE user_id = v_me
     AND storage_path LIKE v_me::text || '/%';

  DELETE FROM public.profile_photos WHERE user_id = v_me;
  GET DIAGNOSTICS v_photos = ROW_COUNT;

  DELETE FROM public.onboarding_answers WHERE user_id = v_me;
  DELETE FROM public.seeker_details     WHERE user_id = v_me;

  DELETE FROM public.likes  WHERE liker_id  = v_me OR liked_id  = v_me;
  GET DIAGNOSTICS v_likes = ROW_COUNT;
  DELETE FROM public.saves  WHERE saver_id  = v_me OR saved_id  = v_me;
  GET DIAGNOSTICS v_saves = ROW_COUNT;
  DELETE FROM public.passes WHERE passer_id = v_me OR passed_id = v_me;
  GET DIAGNOSTICS v_passes = ROW_COUNT;

  UPDATE public.profiles
     SET bio              = NULL,
         location_text    = NULL,
         profile_complete = false
   WHERE id = v_me;

  RETURN jsonb_build_object(
    'status','reset',
    'photos',  v_photos,
    'likes',   v_likes,
    'saves',   v_saves,
    'passes',  v_passes,
    -- May be SHORTER than 'photos' when rows exist whose object lives
    -- under someone else's prefix. Deliberate: the row goes, the foreign
    -- object is left alone.
    'storage_paths', to_jsonb(v_paths)
  );
END;
$$;


ALTER FUNCTION "public"."zyra_reset_profile"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_reset_profile"() IS 'Clears a Seeker''s answers, details, photos and ALL discovery history in both directions, returning them to onboarding. Keeps identity (frozen), Guardians, credits, subscription, matches, consent evidence and reports. Refuses while an Active Journey exists. Returns storage paths for the caller to remove from the bucket.';



CREATE OR REPLACE FUNCTION "public"."zyra_reset_search"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_reset_search"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_reveal_journey_compatibility"("p_match_id" "uuid") RETURNS TABLE("mine_revealed" boolean, "counterpart_revealed" boolean, "my_score" numeric)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
  v_counterpart uuid;
  v_computed_score numeric;
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
  v_counterpart := case
    when v_is_a then v_match.seeker_b_id
    else v_match.seeker_a_id
  end;

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

  -- Compute only the caller's figure, and never overwrite a stored one.
  if (v_is_a and v_compat.seeker_a_score is null)
     or (not v_is_a and v_compat.seeker_b_score is null) then
    select scored.score
      into v_computed_score
      from public.score_candidates(array[v_counterpart]) as scored
     where scored.candidate_id = v_counterpart
     limit 1;
  end if;

  if v_is_a then
    update public.journey_compatibility as jc
       set seeker_a_revealed = true,
           seeker_a_score = coalesce(jc.seeker_a_score, v_computed_score),
           revealed_at = case
             when jc.seeker_b_revealed and not jc.seeker_a_revealed
               then pg_catalog.statement_timestamp()
             when jc.seeker_a_revealed and jc.seeker_b_revealed
               then coalesce(jc.revealed_at, pg_catalog.statement_timestamp())
             else null
           end
     where jc.match_id = p_match_id;
  else
    update public.journey_compatibility as jc
       set seeker_b_revealed = true,
           seeker_b_score = coalesce(jc.seeker_b_score, v_computed_score),
           revealed_at = case
             when jc.seeker_a_revealed and not jc.seeker_b_revealed
               then pg_catalog.statement_timestamp()
             when jc.seeker_a_revealed and jc.seeker_b_revealed
               then coalesce(jc.revealed_at, pg_catalog.statement_timestamp())
             else null
           end
     where jc.match_id = p_match_id;
  end if;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id;

  mine_revealed := case
    when v_is_a then v_compat.seeker_a_revealed
    else v_compat.seeker_b_revealed
  end;
  counterpart_revealed := case
    when v_is_a then v_compat.seeker_b_revealed
    else v_compat.seeker_a_revealed
  end;
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


ALTER FUNCTION "public"."zyra_reveal_journey_compatibility"("p_match_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_reveal_journey_compatibility"("p_match_id" "uuid") IS 'OA-ZYRA-283. Reveals and scores only the authenticated Seeker side for the current active, unpaused Compatibility Reveal attempt.';



CREATE OR REPLACE FUNCTION "public"."zyra_revoke_wali_invite"("p_token" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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
    perform public.create_notification(
      v_invite.seen_by,
      'wali_invite_revoked',
      'Guardian invitation withdrawn',
      coalesce(v_inviter_name, 'The sender') || ' withdrew the Guardian invitation.',
      null
    );
  end if;
  return true;
end;
$$;


ALTER FUNCTION "public"."zyra_revoke_wali_invite"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_rotate_my_personal_code"("p_role_context" "text" DEFAULT NULL::"text") RETURNS TABLE("code" "text", "role_context" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."zyra_rotate_my_personal_code"("p_role_context" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_save_clears_others"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  DELETE FROM passes WHERE passer_id = NEW.saver_id AND passed_id = NEW.saved_id;
  DELETE FROM likes  WHERE liker_id  = NEW.saver_id AND liked_id  = NEW.saved_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."zyra_save_clears_others"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_sect_code"("p_label" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE PARALLEL SAFE
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_sect_code"("p_label" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_set_attempt_from_match"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_set_attempt_from_match"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_set_main_guardian"("p_wali_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_set_main_guardian"("p_wali_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_set_notification_preference"("p_category" "text", "p_enabled" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  if p_category not in ('matches_journeys','guardian_activity',
                        'introductions','marketing_emails','product_updates') then
    raise exception 'unknown_category: %', p_category;
  end if;

  -- Always an INSERT. Never an upsert, never an update: withdrawing consent
  -- must leave a trace, and overwriting the row it withdraws would erase
  -- the very thing that proves it happened.
  insert into public.notification_preferences (user_id, category, enabled)
  values (v_me, p_category, p_enabled);

  return true;
end;
$$;


ALTER FUNCTION "public"."zyra_set_notification_preference"("p_category" "text", "p_enabled" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_set_profile_complete"("p_complete" boolean DEFAULT true) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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
    SELECT count(*) INTO v_photos FROM public.profile_photos WHERE user_id = v_me;
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


ALTER FUNCTION "public"."zyra_set_profile_complete"("p_complete" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_submit_feedback"("p_category" "text", "p_message" "text", "p_app_version" "text" DEFAULT NULL::"text", "p_platform" "text" DEFAULT NULL::"text", "p_screen" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_submit_feedback"("p_category" "text", "p_message" "text", "p_app_version" "text", "p_platform" "text", "p_screen" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."zyra_submit_feedback"("p_category" "text", "p_message" "text", "p_app_version" "text", "p_platform" "text", "p_screen" "text") IS 'The only write path into app_feedback. Trims, validates, stamps user_id server-side and rate-limits to 10/hour. There is deliberately no INSERT grant on the table itself.';



CREATE OR REPLACE FUNCTION "public"."zyra_unblock_user"("p_other" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."zyra_unblock_user"("p_other" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."zyra_unlock_profile"("p_target" "uuid", "p_tier" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_me      uuid := auth.uid();
  v_balance int;
  v_unlock  uuid;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  IF p_tier NOT IN ('paid_single','paid_plus_single') THEN
    RAISE EXCEPTION 'unknown_tier' USING HINT = 'paid_single or paid_plus_single';
  END IF;

  IF p_target = v_me THEN
    RAISE EXCEPTION 'cannot_unlock_self';
  END IF;

  -- Same visibility rule as everything else. Without it, this function
  -- would confirm the existence of any UUID you cared to name.
  IF NOT public.zyra_can_view_profile(p_target) THEN
    RAISE EXCEPTION 'not_visible';
  END IF;

  -- PERMANENCE, Founder-ratified: "returning to the same profile must
  -- NEVER consume another unlock." Checked BEFORE the balance, so someone
  -- with zero credits still reaches what they already paid for — and a
  -- double tap on a slow connection cannot charge twice.
  IF EXISTS (
    SELECT 1 FROM public.profile_unlocks u
    WHERE u.unlocker_id = v_me AND u.unlocked_id = p_target AND u.unlock_type = p_tier
  ) THEN
    RETURN jsonb_build_object('status','already_unlocked','charged',false);
  END IF;

  SELECT coalesce(sum(delta),0)::int INTO v_balance
  FROM public.unlock_credits
  WHERE user_id = v_me AND tier = p_tier;

  IF v_balance < 1 THEN
    RETURN jsonb_build_object('status','insufficient_credits','charged',false,'balance',v_balance);
  END IF;

  -- One statement, one transaction. The unlock and the debit cannot
  -- diverge: if either fails, neither happened.
  INSERT INTO public.profile_unlocks (unlocker_id, unlocked_id, unlock_type)
  VALUES (v_me, p_target, p_tier)
  RETURNING id INTO v_unlock;

  INSERT INTO public.unlock_credits (user_id, tier, delta, reason, related_unlock_id)
  VALUES (v_me, p_tier, -1, 'spend', v_unlock);

  RETURN jsonb_build_object('status','unlocked','charged',true,'balance',v_balance - 1);
END;
$$;


ALTER FUNCTION "public"."zyra_unlock_profile"("p_target" "uuid", "p_tier" "text") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "private"."identity_verification_attempts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "provider_code" "text" DEFAULT 'sumsub'::"text" NOT NULL,
    "provider_session_ref" "text",
    "result" "text" NOT NULL,
    "duplicate_review_required" boolean,
    "provider_event_ref_hash" "text",
    "consent_granted" boolean NOT NULL,
    "consent_version" "text" NOT NULL,
    "consent_recorded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "decided_at" timestamp with time zone,
    "member_deleted_at" timestamp with time zone,
    CONSTRAINT "identity_verification_attempts_consent_version_check" CHECK (("consent_version" ~ '^[a-z0-9][a-z0-9._-]{0,79}$'::"text")),
    CONSTRAINT "identity_verification_attempts_provider_code_check" CHECK (("provider_code" = ANY (ARRAY['sumsub'::"text", 'stripe'::"text"]))),
    CONSTRAINT "identity_verification_attempts_provider_event_ref_hash_check" CHECK ((("provider_event_ref_hash" IS NULL) OR ("provider_event_ref_hash" ~ '^[0-9a-f]{64}$'::"text"))),
    CONSTRAINT "identity_verification_attempts_provider_session_ref_check" CHECK ((("provider_session_ref" IS NULL) OR (("char_length"("provider_session_ref") >= 1) AND ("char_length"("provider_session_ref") <= 255)))),
    CONSTRAINT "identity_verification_attempts_result_check" CHECK (("result" = ANY (ARRAY['pending'::"text", 'verified'::"text", 'retry_required'::"text", 'review_required'::"text", 'failed'::"text", 'expired'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "identity_verification_duplicate_routes_to_review" CHECK ((("duplicate_review_required" IS DISTINCT FROM true) OR ("result" = 'review_required'::"text"))),
    CONSTRAINT "identity_verification_final_has_decision_time" CHECK ((("result" = ANY (ARRAY['pending'::"text", 'retry_required'::"text", 'review_required'::"text"])) OR ("decided_at" IS NOT NULL))),
    CONSTRAINT "identity_verification_verified_not_duplicate" CHECK ((("result" <> 'verified'::"text") OR ("duplicate_review_required" IS DISTINCT FROM true)))
);


ALTER TABLE "private"."identity_verification_attempts" OWNER TO "postgres";


COMMENT ON TABLE "private"."identity_verification_attempts" IS 'PRIVATE SERVER-OWNED IDV state. No biometric/document/selfie/PII/raw provider payload columns are permitted. Ordinary clients use only the caller-scoped public RPCs in this migration.';



COMMENT ON COLUMN "private"."identity_verification_attempts"."provider_session_ref" IS 'Opaque provider reference only; never email, name, document data or a URL.';



COMMENT ON COLUMN "private"."identity_verification_attempts"."duplicate_review_required" IS 'NULL=not_evaluated, FALSE=clear, TRUE=manual review. Never contains a hit id, score or reason.';



COMMENT ON COLUMN "private"."identity_verification_attempts"."provider_event_ref_hash" IS 'SHA-256 event-reference hash for idempotency; never the raw provider event id.';



CREATE TABLE IF NOT EXISTS "private"."identity_verification_event_receipts" (
    "provider_event_ref_hash" "text" NOT NULL,
    "attempt_id" "uuid" NOT NULL,
    "mapped_result" "text" NOT NULL,
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "identity_verification_event_recei_provider_event_ref_hash_check" CHECK (("provider_event_ref_hash" ~ '^[0-9a-f]{64}$'::"text")),
    CONSTRAINT "identity_verification_event_receipts_mapped_result_check" CHECK (("mapped_result" = ANY (ARRAY['pending'::"text", 'verified'::"text", 'retry_required'::"text", 'review_required'::"text", 'failed'::"text", 'expired'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "private"."identity_verification_event_receipts" OWNER TO "postgres";


COMMENT ON TABLE "private"."identity_verification_event_receipts" IS 'Hash-only webhook idempotency ledger. No provider event id, body, header, reason, PII, biometric data or duplicate-hit detail.';



CREATE TABLE IF NOT EXISTS "private"."zyra_personal_code_attempts" (
    "id" bigint NOT NULL,
    "caller_id" "uuid" NOT NULL,
    "attempted_at" timestamp with time zone DEFAULT "clock_timestamp"() NOT NULL,
    "succeeded" boolean NOT NULL
);


ALTER TABLE "private"."zyra_personal_code_attempts" OWNER TO "postgres";


ALTER TABLE "private"."zyra_personal_code_attempts" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "private"."zyra_personal_code_attempts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "private"."zyra_personal_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "role_context" "text" NOT NULL,
    "code" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "clock_timestamp"() NOT NULL,
    "rotated_at" timestamp with time zone,
    CONSTRAINT "zyra_personal_codes_format" CHECK (("code" ~ '^ZYRA-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$'::"text")),
    CONSTRAINT "zyra_personal_codes_role_context_check" CHECK (("role_context" = ANY (ARRAY['seeker'::"text", 'wali'::"text"])))
);


ALTER TABLE "private"."zyra_personal_codes" OWNER TO "postgres";


COMMENT ON TABLE "private"."zyra_personal_codes" IS 'Server-owned reusable ZYRA discovery handles. One active code per account role context; never a credential and never sufficient to create a link.';



CREATE TABLE IF NOT EXISTS "private"."zyra_retired_personal_code_hashes" (
    "code_sha256" "bytea" NOT NULL,
    "retired_at" timestamp with time zone DEFAULT "clock_timestamp"() NOT NULL
);


ALTER TABLE "private"."zyra_retired_personal_code_hashes" OWNER TO "postgres";


COMMENT ON TABLE "private"."zyra_retired_personal_code_hashes" IS 'Pseudonymous non-reuse ledger. Only SHA-256 digests survive rotation or account deletion; no owner identifier is retained.';



CREATE TABLE IF NOT EXISTS "public"."app_feedback" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "category" "text" NOT NULL,
    "message" "text" NOT NULL,
    "app_version" "text",
    "platform" "text",
    "screen" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "app_feedback_category_known" CHECK (("category" = ANY (ARRAY['idea'::"text", 'problem'::"text", 'other'::"text"]))),
    CONSTRAINT "app_feedback_message_shape" CHECK ((("message" = "btrim"("message")) AND (("char_length"("message") >= 1) AND ("char_length"("message") <= 4000)))),
    CONSTRAINT "app_feedback_short_meta" CHECK (((("app_version" IS NULL) OR ("char_length"("app_version") <= 40)) AND (("platform" IS NULL) OR ("char_length"("platform") <= 40)) AND (("screen" IS NULL) OR ("char_length"("screen") <= 80))))
);


ALTER TABLE "public"."app_feedback" OWNER TO "postgres";


COMMENT ON TABLE "public"."app_feedback" IS 'User-submitted ideas and problem reports. Append-only: no UPDATE or DELETE grant exists for anyone, including the author. user_id is ON DELETE SET NULL so an erasure request is never blocked by it.';



COMMENT ON COLUMN "public"."app_feedback"."user_id" IS 'OWNERSHIP: row-scoped(user_id). Nullable — becomes NULL when the account is deleted, at which point the row is no longer personal data.';



COMMENT ON COLUMN "public"."app_feedback"."category" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."app_feedback"."message" IS 'OWNERSHIP: row-scoped(user_id). The user''s own words, disclosable to them under Article 15.';



COMMENT ON COLUMN "public"."app_feedback"."app_version" IS 'OWNERSHIP: row-scoped(user_id). Collected because "it broke" is not actionable without knowing which build.';



COMMENT ON COLUMN "public"."app_feedback"."platform" IS 'OWNERSHIP: row-scoped(user_id). ios | android, nothing finer — the device model is not needed to read a sentence.';



COMMENT ON COLUMN "public"."app_feedback"."screen" IS 'OWNERSHIP: row-scoped(user_id). Where they were when they wrote it.';



CREATE TABLE IF NOT EXISTS "public"."consents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "consent_type" "text" NOT NULL,
    "granted" boolean NOT NULL,
    "policy_version" "text" NOT NULL,
    "recorded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "consents_type_known" CHECK (("consent_type" = 'article9_special_category'::"text"))
);


ALTER TABLE "public"."consents" OWNER TO "postgres";


COMMENT ON TABLE "public"."consents" IS 'Append-only consent log. Withdrawal is a new row with granted=false. Never update or delete a row here.';



COMMENT ON COLUMN "public"."consents"."user_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."consents"."consent_type" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."consents"."granted" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."consents"."policy_version" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."consents"."recorded_at" IS 'OWNERSHIP: row-scoped(user_id)';



CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'closed'::"text" NOT NULL,
    "closed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attempt_id" "uuid" NOT NULL,
    CONSTRAINT "conversations_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'paused'::"text", 'closed'::"text"])))
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


COMMENT ON COLUMN "public"."conversations"."match_id" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."conversations"."status" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."conversations"."closed_at" IS 'OWNERSHIP: joint — that the conversation closed is observable to both. WHO closed it lives on matches.ended_by.';



COMMENT ON COLUMN "public"."conversations"."created_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."conversations"."attempt_id" IS 'OA-ZYRA-159 stage 4a. THE conversation belongs to an ATTEMPT, not a pair. A new attempt gets a new conversation, so a fresh start is genuinely fresh and the previous attempt''s messages stay with the previous attempt (messages hang off conversation_id). match_id remains until OA-ZYRA-156 step 7 — do not read this table by it.';



CREATE TABLE IF NOT EXISTS "public"."guardian_journey_history_consents" (
    "wali_link_id" "uuid" NOT NULL,
    "main_guardian_authority_id" "uuid",
    "granted_at" timestamp with time zone DEFAULT "clock_timestamp"() NOT NULL,
    "guardian_link_authority_id" "uuid" NOT NULL
);


ALTER TABLE "public"."guardian_journey_history_consents" OWNER TO "postgres";


COMMENT ON TABLE "public"."guardian_journey_history_consents" IS 'DR-ZYRA-225/233 current-state permission for past Journey summaries. A row grants only when wali_link_id and guardian_link_authority_id match one current active link. Absent or mismatched means OFF. No direct client access; use zyra_guardian_history_consent(uuid, boolean).';



COMMENT ON COLUMN "public"."guardian_journey_history_consents"."main_guardian_authority_id" IS 'Legacy DR-ZYRA-225 Main-assignment snapshot retained for compatibility and audit provenance. New authority uses guardian_link_authority_id.';



COMMENT ON COLUMN "public"."guardian_journey_history_consents"."guardian_link_authority_id" IS 'Snapshot of wali_links.guardian_link_authority_id at grant time. A mismatch invalidates permission after removal/reactivation without relying on client cleanup.';



CREATE TABLE IF NOT EXISTS "public"."journey_attempts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "attempt_number" integer DEFAULT 1 NOT NULL,
    "status" "text" DEFAULT 'potential'::"text" NOT NULL,
    "journey_stage" "text",
    "started_at" timestamp with time zone,
    "ended_at" timestamp with time zone,
    "ended_by" "uuid",
    "end_reason" "text",
    "end_note" "text",
    "paused_by" "uuid",
    "paused_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "also_paused_by" "uuid",
    "also_paused_at" timestamp with time zone,
    CONSTRAINT "attempts_end_fields_need_ended_status" CHECK ((("status" = 'ended'::"text") OR (("ended_by" IS NULL) AND ("end_reason" IS NULL) AND ("end_note" IS NULL)))),
    CONSTRAINT "attempts_end_note_length" CHECK ((("end_note" IS NULL) OR ("char_length"("end_note") <= 500))),
    CONSTRAINT "attempts_end_reason_known" CHECK ((("end_reason" IS NULL) OR ("end_reason" = ANY (ARRAY['not_compatible'::"text", 'circumstances_changed'::"text", 'marrying_elsewhere'::"text", 'family_decision'::"text", 'safety_concern'::"text", 'prefer_not_to_say'::"text", 'no_response'::"text"])))),
    CONSTRAINT "attempts_no_note_on_safety_ending" CHECK ((("end_reason" IS DISTINCT FROM 'safety_concern'::"text") OR ("end_note" IS NULL))),
    CONSTRAINT "attempts_no_response_is_system" CHECK ((("end_reason" IS DISTINCT FROM 'no_response'::"text") OR ("ended_by" IS NULL))),
    CONSTRAINT "attempts_pause_needs_active" CHECK ((("paused_by" IS NULL) OR ("status" = 'active'::"text"))),
    CONSTRAINT "journey_attempts_journey_stage_check" CHECK ((("journey_stage" IS NULL) OR ("journey_stage" = ANY (ARRAY['compatibility_reveal'::"text", 'salam_exchange'::"text", 'wali_gate'::"text", 'phase_1'::"text", 'phase_2'::"text", 'phase_3'::"text", 'family_stage'::"text", 'conversation'::"text"])))),
    CONSTRAINT "journey_attempts_status_check" CHECK (("status" = ANY (ARRAY['potential'::"text", 'active'::"text", 'ended'::"text"])))
);


ALTER TABLE "public"."journey_attempts" OWNER TO "postgres";


COMMENT ON TABLE "public"."journey_attempts" IS 'Journey attempts. NO client grants and NO RLS policies, deliberately: read it through zyra_my_attempt_participation (which filters to auth.uid()) or a SECURITY DEFINER function. Revoked 2026-08-07 — it previously held full grants behind zero policies, i.e. it was protected by an absence rather than a decision.';



COMMENT ON COLUMN "public"."journey_attempts"."attempt_number" IS 'OWNERSHIP: joint — INTERNAL ONLY. Never render this. V3 §2: users see dates, not attempt numbers.';



COMMENT ON COLUMN "public"."journey_attempts"."status" IS 'OWNERSHIP: joint. TRANSITIONAL until stage 4: matches.status is authoritative and this mirrors it at creation only. After stage 4 this becomes the sole source of truth.';



COMMENT ON COLUMN "public"."journey_attempts"."journey_stage" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_attempts"."started_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_attempts"."ended_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_attempts"."ended_by" IS 'OWNERSHIP: joint — who ended it is knowable to both';



COMMENT ON COLUMN "public"."journey_attempts"."end_reason" IS 'OWNERSHIP: per-value. joint for the five stated reasons; safety_concern is row-scoped(ended_by) and MUST NEVER reach the other party by export or any indirect route.';



COMMENT ON COLUMN "public"."journey_attempts"."end_note" IS 'OWNERSHIP: joint — written TO the other person';



COMMENT ON COLUMN "public"."journey_attempts"."paused_by" IS 'OWNERSHIP: joint — the other party is told a pause happened';



COMMENT ON COLUMN "public"."journey_attempts"."paused_at" IS 'OWNERSHIP: joint';



CREATE TABLE IF NOT EXISTS "public"."journey_compatibility" (
    "match_id" "uuid" NOT NULL,
    "seeker_a_revealed" boolean DEFAULT false NOT NULL,
    "seeker_b_revealed" boolean DEFAULT false NOT NULL,
    "revealed_at" timestamp with time zone,
    "attempt_id" "uuid",
    "seeker_a_score" numeric,
    "seeker_b_score" numeric,
    "seeker_a_categories" "jsonb",
    "seeker_b_categories" "jsonb"
);


ALTER TABLE "public"."journey_compatibility" OWNER TO "postgres";


COMMENT ON TABLE "public"."journey_compatibility" IS 'RPC-only Compatibility Reveal state. Client roles have no direct table privileges; caller-relative access is enforced by OA-ZYRA-283 functions.';



COMMENT ON COLUMN "public"."journey_compatibility"."seeker_a_revealed" IS 'OWNERSHIP: row-scoped(matches.seeker_a_id) — one person''s choice to reveal';



COMMENT ON COLUMN "public"."journey_compatibility"."seeker_b_revealed" IS 'OWNERSHIP: row-scoped(matches.seeker_b_id)';



COMMENT ON COLUMN "public"."journey_compatibility"."revealed_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_compatibility"."attempt_id" IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';



COMMENT ON COLUMN "public"."journey_compatibility"."seeker_a_score" IS 'seeker_a''s own compatibility figure: how well seeker_b''s answers fit seeker_a''s stated preferences. NOT shared with seeker_b — OA-ZYRA-193 a2.';



COMMENT ON COLUMN "public"."journey_compatibility"."seeker_b_score" IS 'seeker_b''s own compatibility figure. See seeker_a_score.';



CREATE TABLE IF NOT EXISTS "public"."journey_family_answers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "direction" "text" NOT NULL,
    "question_id" "text" NOT NULL,
    "answerer_id" "uuid" NOT NULL,
    "answer_text" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attempt_id" "uuid",
    CONSTRAINT "journey_family_answers_direction_check" CHECK (("direction" = ANY (ARRAY['seeker_to_wali'::"text", 'wali_to_seeker'::"text"])))
);


ALTER TABLE "public"."journey_family_answers" OWNER TO "postgres";


COMMENT ON COLUMN "public"."journey_family_answers"."answerer_id" IS 'OWNERSHIP: row-scoped(answerer_id) — MAY BE A GUARDIAN, not a Seeker. A Guardian''s answers belong to that Guardian and reach neither Seeker''s export.';



COMMENT ON COLUMN "public"."journey_family_answers"."answer_text" IS 'OWNERSHIP: row-scoped(answerer_id) — see answerer_id.';



COMMENT ON COLUMN "public"."journey_family_answers"."attempt_id" IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';



CREATE TABLE IF NOT EXISTS "public"."journey_family_review_responses" (
    "review_id" "uuid" NOT NULL,
    "wali_id" "uuid" NOT NULL,
    "decision" "text" NOT NULL,
    "responded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "journey_family_review_responses_decision_check" CHECK (("decision" = ANY (ARRAY['continue'::"text", 'pause'::"text"])))
);


ALTER TABLE "public"."journey_family_review_responses" OWNER TO "postgres";


COMMENT ON TABLE "public"."journey_family_review_responses" IS 'OWNERSHIP: third-party(guardian). NEVER exported to either Seeker. A Guardian is a data subject in their own right; my own Guardian''s decision is not my personal data. A Guardian pausing a Journey, and that being exportable to the Seeker they paused, is a family-safety problem as well as a privacy one.';



COMMENT ON COLUMN "public"."journey_family_review_responses"."wali_id" IS 'OWNERSHIP: third-party(guardian) — non-exportable to Seekers';



COMMENT ON COLUMN "public"."journey_family_review_responses"."decision" IS 'OWNERSHIP: third-party(guardian) — non-exportable to Seekers. Only the aggregate review outcome is disclosable.';



COMMENT ON COLUMN "public"."journey_family_review_responses"."responded_at" IS 'OWNERSHIP: third-party(guardian) — non-exportable to Seekers';



CREATE TABLE IF NOT EXISTS "public"."journey_family_reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "from_stage" "text" NOT NULL,
    "to_stage" "text" NOT NULL,
    "opened_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deadline_at" timestamp with time zone NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "resolved_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attempt_id" "uuid",
    CONSTRAINT "journey_family_reviews_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'continued'::"text", 'paused'::"text"])))
);


ALTER TABLE "public"."journey_family_reviews" OWNER TO "postgres";


COMMENT ON COLUMN "public"."journey_family_reviews"."from_stage" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_family_reviews"."to_stage" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_family_reviews"."opened_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_family_reviews"."deadline_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_family_reviews"."status" IS 'OWNERSHIP: joint — the OUTCOME is disclosable. Individual Guardian decisions are not (see journey_family_review_responses).';



COMMENT ON COLUMN "public"."journey_family_reviews"."resolved_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."journey_family_reviews"."attempt_id" IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';



CREATE TABLE IF NOT EXISTS "public"."journey_guardian_assignments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "attempt_id" "uuid" NOT NULL,
    "wali_link_id" "uuid" NOT NULL,
    "seeker_id" "uuid" NOT NULL,
    "granted_by" "uuid" NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "clock_timestamp"() NOT NULL,
    "revoked_by" "uuid",
    "revoked_at" timestamp with time zone,
    CONSTRAINT "journey_guardian_assignments_revocation_pair" CHECK (((("revoked_at" IS NULL) AND ("revoked_by" IS NULL)) OR (("revoked_at" IS NOT NULL) AND ("revoked_by" IS NOT NULL))))
);


ALTER TABLE "public"."journey_guardian_assignments" OWNER TO "postgres";


COMMENT ON TABLE "public"."journey_guardian_assignments" IS 'Audited per-attempt access grants for Additional Guardians. Live rows have revoked_at NULL. Main Guardians are never stored here because their active role is the non-optional Journey authority.';



CREATE TABLE IF NOT EXISTS "public"."journey_milestone_attestations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "attempt_id" "uuid" NOT NULL,
    "milestone_type" "text" NOT NULL,
    "occurred_on" "date" NOT NULL,
    "proposed_by" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "confirmed_by" "uuid",
    "confirmed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "journey_milestone_attestations_milestone_type_check" CHECK (("milestone_type" = ANY (ARRAY['meeting'::"text", 'nikah'::"text"]))),
    CONSTRAINT "journey_milestone_attestations_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'confirmed'::"text", 'superseded'::"text"])))
);


ALTER TABLE "public"."journey_milestone_attestations" OWNER TO "postgres";


COMMENT ON TABLE "public"."journey_milestone_attestations" IS 'Meeting/Nikah proposals awaiting the other Seeker''s confirmation (Founder 2026-08-12). Confirmation writes the timeline_milestones row; user-attested, both-party record.';



CREATE TABLE IF NOT EXISTS "public"."journey_phase_answers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "phase" integer NOT NULL,
    "seeker_id" "uuid" NOT NULL,
    "question_id" "text" NOT NULL,
    "answer_text" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attempt_id" "uuid",
    CONSTRAINT "journey_phase_answers_phase_check" CHECK (("phase" = ANY (ARRAY[1, 2, 3])))
);


ALTER TABLE "public"."journey_phase_answers" OWNER TO "postgres";


COMMENT ON COLUMN "public"."journey_phase_answers"."seeker_id" IS 'OWNERSHIP: row-scoped(seeker_id)';



COMMENT ON COLUMN "public"."journey_phase_answers"."answer_text" IS 'OWNERSHIP: row-scoped(seeker_id) — highest-sensitivity free text in the Journey set. The other party''s answers must never appear in an export.';



COMMENT ON COLUMN "public"."journey_phase_answers"."attempt_id" IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';



CREATE TABLE IF NOT EXISTS "public"."journey_phase_checkpoints" (
    "match_id" "uuid" NOT NULL,
    "phase" integer NOT NULL,
    "seeker_id" "uuid" NOT NULL,
    "decision" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attempt_id" "uuid",
    CONSTRAINT "journey_phase_checkpoints_decision_check" CHECK (("decision" = ANY (ARRAY['continue'::"text", 'ask_more'::"text", 'end'::"text"]))),
    CONSTRAINT "journey_phase_checkpoints_phase_check" CHECK (("phase" = ANY (ARRAY[1, 2, 3])))
);


ALTER TABLE "public"."journey_phase_checkpoints" OWNER TO "postgres";


COMMENT ON COLUMN "public"."journey_phase_checkpoints"."seeker_id" IS 'OWNERSHIP: row-scoped(seeker_id)';



COMMENT ON COLUMN "public"."journey_phase_checkpoints"."decision" IS 'OWNERSHIP: row-scoped(seeker_id) — their decision to continue or end is theirs, even though the outcome affected both.';



COMMENT ON COLUMN "public"."journey_phase_checkpoints"."attempt_id" IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';



CREATE TABLE IF NOT EXISTS "public"."journey_phase_ratings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "phase" integer NOT NULL,
    "rater_id" "uuid" NOT NULL,
    "question_id" "text" NOT NULL,
    "rating" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attempt_id" "uuid",
    CONSTRAINT "journey_phase_ratings_phase_check" CHECK (("phase" = ANY (ARRAY[1, 2, 3]))),
    CONSTRAINT "journey_phase_ratings_rating_check" CHECK (("rating" = ANY (ARRAY['reassured'::"text", 'discuss_further'::"text", 'concerns'::"text"])))
);


ALTER TABLE "public"."journey_phase_ratings" OWNER TO "postgres";


COMMENT ON COLUMN "public"."journey_phase_ratings"."rater_id" IS 'OWNERSHIP: row-scoped(rater_id)';



COMMENT ON COLUMN "public"."journey_phase_ratings"."rating" IS 'OWNERSHIP: pending-legal — Founder 2026-08-06: whether "they rated you Amber" must be disclosed under Art.15''s source limb is a legal question. A rating I gave is mine; a rating of me is theirs. Withhold until confirmed.';



COMMENT ON COLUMN "public"."journey_phase_ratings"."attempt_id" IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';



CREATE TABLE IF NOT EXISTS "public"."journey_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "requested_by" "uuid" NOT NULL,
    "requested_to" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "responded_at" timestamp with time zone,
    "attempt_id" "uuid",
    CONSTRAINT "requests_accepted_has_attempt" CHECK ((("status" = 'accepted'::"text") = ("attempt_id" IS NOT NULL))),
    CONSTRAINT "requests_not_to_self" CHECK (("requested_by" <> "requested_to")),
    CONSTRAINT "requests_response_matches_status" CHECK ((("status" = 'pending'::"text") = ("responded_at" IS NULL))),
    CONSTRAINT "requests_status_known" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'declined'::"text"])))
);


ALTER TABLE "public"."journey_requests" OWNER TO "postgres";


COMMENT ON TABLE "public"."journey_requests" IS 'OA-ZYRA-159 / DR-ZYRA-121 item 8. One pending request per pair. Readable by both parties; writable only through request_new_journey() and respond_to_journey_request(). status is coarse ON PURPOSE — which kind of decline, and whether it was a decision or an expiry, is recorded only in protection_holds, which the requester cannot read.';



CREATE TABLE IF NOT EXISTS "public"."journey_salams" (
    "match_id" "uuid" NOT NULL,
    "seeker_id" "uuid" NOT NULL,
    "sent_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attempt_id" "uuid"
);


ALTER TABLE "public"."journey_salams" OWNER TO "postgres";


COMMENT ON COLUMN "public"."journey_salams"."seeker_id" IS 'OWNERSHIP: row-scoped(seeker_id)';



COMMENT ON COLUMN "public"."journey_salams"."sent_at" IS 'OWNERSHIP: row-scoped(seeker_id)';



COMMENT ON COLUMN "public"."journey_salams"."attempt_id" IS 'OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.';



CREATE TABLE IF NOT EXISTS "public"."journey_stage_checkpoints" (
    "match_id" "uuid" NOT NULL,
    "attempt_id" "uuid",
    "stage" "text" NOT NULL,
    "seeker_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "journey_stage_checkpoints_stage_known" CHECK (("stage" = ANY (ARRAY['compatibility_reveal'::"text", 'salam_exchange'::"text", 'wali_gate'::"text", 'phase_1'::"text", 'phase_2'::"text", 'phase_3'::"text", 'family_stage'::"text", 'conversation'::"text"])))
);


ALTER TABLE "public"."journey_stage_checkpoints" OWNER TO "postgres";


COMMENT ON TABLE "public"."journey_stage_checkpoints" IS 'OWNERSHIP: row-scoped(seeker_id), readable by both Seekers of the attempt. One row = "this Seeker has chosen to continue past this stage". Written ONLY by zyra_advance_stage(); no client INSERT grant exists, so a checkpoint cannot be forged or written on another person''s behalf. See PRE-JOURNEY RITUAL (current version).';



CREATE TABLE IF NOT EXISTS "public"."likes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "liker_id" "uuid" NOT NULL,
    "liked_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "likes_check" CHECK (("liker_id" <> "liked_id"))
);


ALTER TABLE "public"."likes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."likes"."liker_id" IS 'OWNERSHIP: row-scoped(liker_id)';



COMMENT ON COLUMN "public"."likes"."liked_id" IS 'OWNERSHIP: non-exportable to the liked person unless it has become a mutual match.';



CREATE TABLE IF NOT EXISTS "public"."matches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "seeker_a_id" "uuid" NOT NULL,
    "seeker_b_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'potential'::"text" NOT NULL,
    "ended_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "journey_stage" "text",
    "suspended_by" "uuid",
    "suspended_at" timestamp with time zone,
    "ended_by" "uuid",
    "end_reason" "text",
    "end_note" "text",
    "pause_nudged_at" timestamp with time zone,
    "also_paused_by" "uuid",
    "also_paused_at" timestamp with time zone,
    CONSTRAINT "matches_also_pause_requires_primary" CHECK ((("also_paused_by" IS NULL) OR ("suspended_by" IS NOT NULL))),
    CONSTRAINT "matches_check" CHECK (("seeker_a_id" < "seeker_b_id")),
    CONSTRAINT "matches_end_fields_need_ended_status" CHECK ((("status" = 'ended'::"text") OR (("ended_by" IS NULL) AND ("end_reason" IS NULL) AND ("end_note" IS NULL)))),
    CONSTRAINT "matches_end_note_length" CHECK ((("end_note" IS NULL) OR ("char_length"("end_note") <= 500))),
    CONSTRAINT "matches_end_reason_known" CHECK ((("end_reason" IS NULL) OR ("end_reason" = ANY (ARRAY['not_compatible'::"text", 'circumstances_changed'::"text", 'marrying_elsewhere'::"text", 'family_decision'::"text", 'safety_concern'::"text", 'prefer_not_to_say'::"text", 'no_response'::"text"])))),
    CONSTRAINT "matches_holds_distinct" CHECK ((("also_paused_by" IS NULL) OR ("also_paused_by" <> "suspended_by"))),
    CONSTRAINT "matches_journey_stage_check" CHECK (("journey_stage" = ANY (ARRAY['compatibility_reveal'::"text", 'salam_exchange'::"text", 'wali_gate'::"text", 'phase_1'::"text", 'phase_2'::"text", 'phase_3'::"text", 'family_stage'::"text", 'conversation'::"text"]))),
    CONSTRAINT "matches_no_note_on_safety_ending" CHECK ((("end_reason" IS DISTINCT FROM 'safety_concern'::"text") OR ("end_note" IS NULL))),
    CONSTRAINT "matches_no_response_is_system" CHECK ((("end_reason" IS DISTINCT FROM 'no_response'::"text") OR ("ended_by" IS NULL))),
    CONSTRAINT "matches_status_check" CHECK (("status" = ANY (ARRAY['potential'::"text", 'active'::"text", 'ended'::"text"])))
);


ALTER TABLE "public"."matches" OWNER TO "postgres";


COMMENT ON COLUMN "public"."matches"."seeker_a_id" IS 'OWNERSHIP: joint — who you matched with is equally each party''s own fact. NOT a route to the other person''s data; it is an identifier both already hold.';



COMMENT ON COLUMN "public"."matches"."seeker_b_id" IS 'OWNERSHIP: joint — see seeker_a_id.';



COMMENT ON COLUMN "public"."matches"."status" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."matches"."ended_at" IS 'When the Journey ended. Set by zyra_end_match_internal(), the single path both ordinary and safety endings take — two paths would drift and the drift would be a disclosure channel. NOTE the companion rule: visibility revoked by a block keys on end_reason=''safety_concern'' (permanent), NOT on a profile_blocks row (deletable). PERMANENT BEHAVIOUR MUST DERIVE FROM PERMANENT DATA.';



COMMENT ON COLUMN "public"."matches"."journey_stage" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."matches"."suspended_by" IS 'OWNERSHIP: joint — the other party is told a pause happened';



COMMENT ON COLUMN "public"."matches"."suspended_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."matches"."ended_by" IS 'OWNERSHIP: joint — who ended it is knowable to both';



COMMENT ON COLUMN "public"."matches"."end_reason" IS 'OWNERSHIP: per-value. Joint for the five stated reasons (V3 §8 — a stated reason is kinder than silence). safety_concern is row-scoped(ended_by) and MUST NEVER reach the other party or either family. NOT CLIENT-READABLE since 2026-08-08: RLS decides rows, not values, so the rule cannot be a policy. Read via zyra_match_ending(), which substitutes prefer_not_to_say for anyone not entitled. DO NOT RE-GRANT.';



COMMENT ON COLUMN "public"."matches"."end_note" IS 'OWNERSHIP: joint — written TO the other person. Revoked alongside end_reason 2026-08-08: a note being present or absent is itself a signal about the reason, so it has to travel through the same accessor.';



CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


COMMENT ON COLUMN "public"."messages"."sender_id" IS 'OWNERSHIP: row-scoped(sender_id)';



COMMENT ON COLUMN "public"."messages"."content" IS 'OWNERSHIP: pending-legal — Founder 2026-08-06: whether messages the OTHER party sent appear in a subject access export is for the solicitor, not engineering. Withhold until confirmed.';



COMMENT ON COLUMN "public"."messages"."read_at" IS 'OWNERSHIP: pending-legal — records the recipient''s behaviour, not the sender''s. Same solicitor question.';



COMMENT ON COLUMN "public"."messages"."deleted_at" IS 'OWNERSHIP: row-scoped(sender_id)';



CREATE TABLE IF NOT EXISTS "public"."notification_preferences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "category" "text" NOT NULL,
    "enabled" boolean NOT NULL,
    "changed_at" timestamp with time zone DEFAULT "clock_timestamp"() NOT NULL,
    "seq" bigint NOT NULL,
    CONSTRAINT "notification_preferences_category_check" CHECK (("category" = ANY (ARRAY['matches_journeys'::"text", 'guardian_activity'::"text", 'introductions'::"text", 'marketing_emails'::"text", 'product_updates'::"text"])))
);


ALTER TABLE "public"."notification_preferences" OWNER TO "postgres";


COMMENT ON TABLE "public"."notification_preferences" IS 'OWNERSHIP: row-scoped(user_id). Append-only consent and preference log. Never UPDATE or DELETE a row — the history IS the evidence. Current state is the newest row per (user_id, category).';



COMMENT ON COLUMN "public"."notification_preferences"."enabled" IS 'OWNERSHIP: row-scoped(user_id). For marketing_emails and product_updates this is a record of CONSENT given or withdrawn, and is disclosable to the user under Article 15.';



COMMENT ON COLUMN "public"."notification_preferences"."seq" IS 'Monotonic insertion order. The authoritative tiebreaker for "which consent event is current" — changed_at alone is not sufficient, because two events in one transaction can share it.';



CREATE SEQUENCE IF NOT EXISTS "public"."notification_preferences_seq_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."notification_preferences_seq_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."notification_preferences_seq_seq" OWNED BY "public"."notification_preferences"."seq";



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text",
    "related_match_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "read_at" timestamp with time zone,
    CONSTRAINT "notifications_type_check" CHECK (("type" = ANY (ARRAY['new_match'::"text", 'new_message'::"text", 'wali_request'::"text", 'journey_ended'::"text", 'journey_request'::"text", 'journey_request_accepted'::"text", 'journey_request_declined'::"text", 'milestone_proposed'::"text", 'milestone_confirmed'::"text", 'pause_nudge'::"text", 'journey_paused'::"text", 'journey_also_paused'::"text", 'journey_continued'::"text", 'wali_invite_received'::"text", 'wali_invite_declined'::"text", 'wali_invite_expiring'::"text", 'wali_invite_expired'::"text", 'wali_invite_revoked'::"text"])))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


COMMENT ON COLUMN "public"."notifications"."user_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."notifications"."type" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."notifications"."title" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."notifications"."body" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."notifications"."related_match_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."notifications"."read_at" IS 'OWNERSHIP: row-scoped(user_id)';



CREATE TABLE IF NOT EXISTS "public"."onboarding_answers" (
    "user_id" "uuid" NOT NULL,
    "ch3_answers" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "ch4_preferences" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "ch4_hard_requirements" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_synthetic" boolean DEFAULT false NOT NULL,
    CONSTRAINT "onboarding_answers_ch4_hard_shape" CHECK ("public"."zyra_ch4_hard_shape_ok"("ch4_hard_requirements"))
);


ALTER TABLE "public"."onboarding_answers" OWNER TO "postgres";


COMMENT ON COLUMN "public"."onboarding_answers"."user_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."onboarding_answers"."ch3_answers" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."onboarding_answers"."ch4_preferences" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."onboarding_answers"."ch4_hard_requirements" IS 'Per-OPTION hard exclusions: {question_id: [option_label, ...]}. An option listed here is never introduced, full stop — checked independently of ch4_preferences so a dealbreaker set before the questions are walked still binds. WAS {question_id: bool} until 2026-08-10, which could not express "never X, but I would consider Y" on the same question.';



COMMENT ON COLUMN "public"."onboarding_answers"."is_synthetic" IS 'TRUE for seeded test data, never for a real Seeker. Chapter 3 answers are values, not demographics — there is no census to check them against, so any engine tuned on these rows is tuned on an invention. DELETE ALL is_synthetic ROWS BEFORE PUBLIC LAUNCH (see OA-ZYRA-190).';



CREATE TABLE IF NOT EXISTS "public"."passes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "passer_id" "uuid" NOT NULL,
    "passed_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "passes_check" CHECK (("passer_id" <> "passed_id"))
);


ALTER TABLE "public"."passes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."passes"."passer_id" IS 'OWNERSHIP: row-scoped(passer_id)';



COMMENT ON COLUMN "public"."passes"."passed_id" IS 'OWNERSHIP: non-exportable to the passed person. ZYRA promises "no record, no notification" on a Pass; an export disclosing it would break that promise through a route nobody thought to close.';



CREATE TABLE IF NOT EXISTS "public"."profile_blocks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "blocker_id" "uuid" NOT NULL,
    "blocked_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "profile_blocks_check" CHECK (("blocker_id" <> "blocked_id"))
);


ALTER TABLE "public"."profile_blocks" OWNER TO "postgres";


COMMENT ON TABLE "public"."profile_blocks" IS 'A block is a TERMINAL safety boundary. Nothing may automatically recreate or restore any relationship, visibility, conversation or Journey that existed before it; reconnecting starts a new Journey under the normal rules. WRITE PATH IS zyra_block_user() / zyra_unblock_user() ONLY — direct grants revoked 2026-08-08 so the atomicity cannot be bypassed. Do not re-grant.';



COMMENT ON COLUMN "public"."profile_blocks"."blocker_id" IS 'OWNERSHIP: row-scoped(blocker_id)';



COMMENT ON COLUMN "public"."profile_blocks"."blocked_id" IS 'OWNERSHIP: non-exportable to the blocked person';



CREATE TABLE IF NOT EXISTS "public"."profile_photos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "storage_path" "text" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "display_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profile_photos" OWNER TO "postgres";


COMMENT ON TABLE "public"."profile_photos" IS 'OWNERSHIP: row-scoped(user_id). Attachment data follows the same Mine/Theirs/Joint model as Journey data — Founder requirement 2026-08-06. Any future attachment table (documents, evidence, voice notes, media) MUST carry an OWNERSHIP comment on its author column before it is used, and the binary in Storage inherits its row''s class.';



COMMENT ON COLUMN "public"."profile_photos"."user_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."profile_photos"."storage_path" IS 'OWNERSHIP: row-scoped(user_id) — the Storage object inherits the row''s class. An export must include the FILE, not just the path.';



COMMENT ON COLUMN "public"."profile_photos"."is_primary" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."profile_photos"."display_order" IS 'OWNERSHIP: row-scoped(user_id) — the owner''s own ordering choice.';



CREATE TABLE IF NOT EXISTS "public"."profile_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reporter_id" "uuid" NOT NULL,
    "reported_id" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "detail" "text",
    "source" "text" DEFAULT 'browse'::"text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "reviewed_at" timestamp with time zone,
    CONSTRAINT "profile_reports_reason_check" CHECK (("reason" = ANY (ARRAY['fake_profile'::"text", 'inappropriate_content'::"text", 'harassment'::"text", 'underage'::"text", 'violence'::"text", 'privacy'::"text", 'other'::"text"]))),
    CONSTRAINT "profile_reports_source_check" CHECK (("source" = ANY (ARRAY['browse'::"text", 'chat'::"text", 'journey'::"text", 'connections'::"text", 'profile'::"text", 'guardian'::"text"]))),
    CONSTRAINT "profile_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewing'::"text", 'actioned'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."profile_reports" OWNER TO "postgres";


COMMENT ON TABLE "public"."profile_reports" IS 'OWNERSHIP: row-scoped(reporter_id). NON-EXPORTABLE to the reported person, including any attached evidence — §15.3. Handing someone the report filed against them defeats the protection entirely.';



COMMENT ON COLUMN "public"."profile_reports"."reporter_id" IS 'OWNERSHIP: row-scoped(reporter_id)';



COMMENT ON COLUMN "public"."profile_reports"."reported_id" IS 'OWNERSHIP: non-exportable to the reported person';



COMMENT ON COLUMN "public"."profile_reports"."reason" IS 'OWNERSHIP: non-exportable to the reported person';



COMMENT ON COLUMN "public"."profile_reports"."detail" IS 'OWNERSHIP: non-exportable to the reported person — free text, and the most likely place for evidence-like content today.';



COMMENT ON COLUMN "public"."profile_reports"."source" IS 'OWNERSHIP: row-scoped(reporter_id)';



COMMENT ON COLUMN "public"."profile_reports"."status" IS 'OWNERSHIP: row-scoped(reporter_id)';



COMMENT ON COLUMN "public"."profile_reports"."reviewed_at" IS 'OWNERSHIP: row-scoped(reporter_id)';



CREATE TABLE IF NOT EXISTS "public"."profile_unlocks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "unlocker_id" "uuid" NOT NULL,
    "unlocked_id" "uuid" NOT NULL,
    "unlock_type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "profile_unlocks_check" CHECK (("unlocker_id" <> "unlocked_id")),
    CONSTRAINT "profile_unlocks_unlock_type_check" CHECK (("unlock_type" = ANY (ARRAY['paid_single'::"text", 'paid_plus_single'::"text", 'paid_bundle'::"text", 'paid_plus_bundle'::"text", 'automatic_match'::"text"])))
);


ALTER TABLE "public"."profile_unlocks" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profile_unlocks"."unlocker_id" IS 'OWNERSHIP: row-scoped(unlocker_id)';



COMMENT ON COLUMN "public"."profile_unlocks"."unlocked_id" IS 'OWNERSHIP: non-exportable to the UNLOCKED person. Disclosing it would tell someone who has been paying to look at them.';



COMMENT ON COLUMN "public"."profile_unlocks"."unlock_type" IS 'OWNERSHIP: row-scoped(unlocker_id)';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'seeker'::"text" NOT NULL,
    "first_name" "text" NOT NULL,
    "date_of_birth" "date" NOT NULL,
    "gender" "text" NOT NULL,
    "location_text" "text",
    "bio" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "profile_complete" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "surname_line" "text",
    "first_published_at" timestamp with time zone,
    "onboarding_complete" boolean DEFAULT false NOT NULL,
    CONSTRAINT "profiles_adult_only" CHECK (("date_of_birth" <= (CURRENT_DATE - '18 years'::interval))),
    CONSTRAINT "profiles_dob_plausible" CHECK (("date_of_birth" >= '1900-01-01'::"date")),
    CONSTRAINT "profiles_first_name_shape" CHECK ((("first_name" = "btrim"("first_name")) AND (("char_length"("first_name") >= 1) AND ("char_length"("first_name") <= 60)))),
    CONSTRAINT "profiles_gender_check" CHECK (("gender" = ANY (ARRAY['male'::"text", 'female'::"text"]))),
    CONSTRAINT "profiles_role_check" CHECK (("role" = ANY (ARRAY['seeker'::"text", 'wali'::"text", 'admin'::"text"])))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."role" IS 'OWNERSHIP: row-scoped(id)';



COMMENT ON COLUMN "public"."profiles"."first_name" IS 'OWNERSHIP: row-scoped(id) — shown publicly in Browse';



COMMENT ON COLUMN "public"."profiles"."date_of_birth" IS 'OWNERSHIP: row-scoped(id) — not client-readable; others see a derived age via ages_for().';



COMMENT ON COLUMN "public"."profiles"."gender" IS 'OWNERSHIP: row-scoped(id)';



COMMENT ON COLUMN "public"."profiles"."location_text" IS 'OWNERSHIP: row-scoped(id)';



COMMENT ON COLUMN "public"."profiles"."bio" IS 'OWNERSHIP: row-scoped(id)';



COMMENT ON COLUMN "public"."profiles"."is_active" IS 'OWNERSHIP: row-scoped(id)';



COMMENT ON COLUMN "public"."profiles"."profile_complete" IS 'OWNERSHIP: row-scoped(id)';



COMMENT ON COLUMN "public"."profiles"."surname_line" IS 'OWNERSHIP: row-scoped(id)';



COMMENT ON COLUMN "public"."profiles"."first_published_at" IS 'Set the first time a profile is published and NEVER cleared, including on un-publish. Gender and date_of_birth are frozen once this is non-null — that is the whole reason the column exists, and it is why profile_complete could not be used: profile_complete is reversible, and PERMANENT BEHAVIOUR MUST DERIVE FROM PERMANENT DATA (Founder invariant, 2026-08-08). BACKFILL WARNING: rows predating 2026-08-07 were backfilled from created_at, a lower bound. Safe to test for NULL. NOT safe to show a user as a date.';



COMMENT ON COLUMN "public"."profiles"."onboarding_complete" IS 'OA-ZYRA-193(c). Maintained by trigger, never written by the app. True when this Seeker has finished onboarding — basic profile, Chapter 2, and every Chapter 3/4 question they were actually shown. Distinct from profile_complete, which means only the name/date-of-birth/photos step.';



COMMENT ON CONSTRAINT "profiles_adult_only" ON "public"."profiles" IS 'ZYRA is 18+. Final authority — client validation is a courtesy, this is the guarantee.';



CREATE TABLE IF NOT EXISTS "public"."protection_holds" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "restricted_id" "uuid" NOT NULL,
    "protected_id" "uuid" NOT NULL,
    "hold_type" "text" NOT NULL,
    "appealable" boolean NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone,
    "released_at" timestamp with time zone,
    "released_by" "uuid",
    "release_reason" "text",
    CONSTRAINT "holds_cooldown_must_expire" CHECK ((("hold_type" <> 'decline_cooldown'::"text") OR ("expires_at" IS NOT NULL))),
    CONSTRAINT "holds_no_self_hold" CHECK (("restricted_id" <> "protected_id")),
    CONSTRAINT "holds_permanent_never_expires" CHECK ((("hold_type" <> 'decline_permanent'::"text") OR ("expires_at" IS NULL))),
    CONSTRAINT "holds_release_is_complete" CHECK (((("released_at" IS NULL) AND ("released_by" IS NULL) AND ("release_reason" IS NULL)) OR (("released_at" IS NOT NULL) AND ("released_by" IS NOT NULL) AND ("release_reason" IS NOT NULL)))),
    CONSTRAINT "holds_safety_is_never_appealable" CHECK ((("hold_type" <> 'safety'::"text") OR ("appealable" = false))),
    CONSTRAINT "holds_type_known" CHECK (("hold_type" = ANY (ARRAY['decline_cooldown'::"text", 'decline_permanent'::"text", 'safety'::"text", 'moderation'::"text"])))
);


ALTER TABLE "public"."protection_holds" OWNER TO "postgres";


COMMENT ON TABLE "public"."protection_holds" IS 'OA-ZYRA-157 / DR-ZYRA-121 item 5. Directional bars between two people on a pair. Active = released_at IS NULL AND (expires_at IS NULL OR expires_at > now()). RLS on with no policies DELIBERATELY: a hold must be unreadable by the person it restricts. Read it only through zyra_hold_blocks().';



COMMENT ON CONSTRAINT "holds_release_is_complete" ON "public"."protection_holds" IS 'OA-ZYRA-157. released_at, released_by and release_reason are all-or-nothing. A release with no recorded actor or reason is unauditable, which defeats the purpose of holding the row instead of deleting it.';



CREATE TABLE IF NOT EXISTS "public"."saves" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "saver_id" "uuid" NOT NULL,
    "saved_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "saves_check" CHECK (("saver_id" <> "saved_id"))
);


ALTER TABLE "public"."saves" OWNER TO "postgres";


COMMENT ON COLUMN "public"."saves"."saver_id" IS 'OWNERSHIP: row-scoped(saver_id)';



COMMENT ON COLUMN "public"."saves"."saved_id" IS 'OWNERSHIP: non-exportable to the SAVED person — being saved is the saver''s private act.';



CREATE TABLE IF NOT EXISTS "public"."seeker_details" (
    "user_id" "uuid" NOT NULL,
    "sect" "text",
    "sect_other" "text",
    "revert_status" boolean,
    "country_of_birth" "text",
    "nationality" "text",
    "ethnicity" "text",
    "languages" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "preferences" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_synthetic" boolean DEFAULT false NOT NULL,
    CONSTRAINT "seeker_details_cob_is_code" CHECK ((("country_of_birth" IS NULL) OR ("country_of_birth" ~ '^[A-Z]{2}$'::"text"))),
    CONSTRAINT "seeker_details_ethnicity_is_code" CHECK ((("ethnicity" IS NULL) OR ("ethnicity" ~ '^[a-z][a-z_]*$'::"text"))),
    CONSTRAINT "seeker_details_languages_are_codes" CHECK ("public"."zyra_all_iso639_1"("languages")),
    CONSTRAINT "seeker_details_nat_is_code" CHECK ((("nationality" IS NULL) OR ("nationality" ~ '^[A-Z]{2}$'::"text"))),
    CONSTRAINT "seeker_details_sect_hard_shape" CHECK ("public"."zyra_ch2_sect_hard_shape_ok"("preferences")),
    CONSTRAINT "seeker_details_sect_known" CHECK ((("sect" IS NULL) OR ("sect" ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::"text"))),
    CONSTRAINT "seeker_details_sect_other_len" CHECK ((("sect_other" IS NULL) OR ("char_length"("sect_other") <= 60)))
);


ALTER TABLE "public"."seeker_details" OWNER TO "postgres";


COMMENT ON TABLE "public"."seeker_details" IS 'OWNERSHIP: row-scoped(user_id). Article 9 special-category data — always disclosable to its subject, never to anyone else except through a paid unlock (seeker_details_for_unlocked).';



COMMENT ON COLUMN "public"."seeker_details"."user_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."seeker_details"."sect" IS 'Canonical lowercase hyphenated code. The same code keys preferences->sect->matrix and hard_requirement; display labels never enter scoring.';



COMMENT ON COLUMN "public"."seeker_details"."sect_other" IS 'OWNERSHIP: row-scoped(user_id) — Article 9';



COMMENT ON COLUMN "public"."seeker_details"."revert_status" IS 'OWNERSHIP: row-scoped(user_id) — Article 9';



COMMENT ON COLUMN "public"."seeker_details"."country_of_birth" IS 'OWNERSHIP: row-scoped(user_id) — Article 9 by inference';



COMMENT ON COLUMN "public"."seeker_details"."nationality" IS 'OWNERSHIP: row-scoped(user_id) — Article 9 by inference';



COMMENT ON COLUMN "public"."seeker_details"."ethnicity" IS 'OWNERSHIP: row-scoped(user_id) — Article 9';



COMMENT ON COLUMN "public"."seeker_details"."languages" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."seeker_details"."preferences" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."seeker_details"."is_synthetic" IS 'TRUE for seeded test data. Chapter 2 was backfilled 2026-08-10 to the real UK distribution (Census 2021 + Techne/IIFL) — checkable, but still not real people. Delete alongside onboarding_answers.is_synthetic before launch.';



CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "plan_type" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "billing_period" "text",
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "subscriptions_billing_period_check" CHECK (("billing_period" = ANY (ARRAY['monthly'::"text", 'annual'::"text"]))),
    CONSTRAINT "subscriptions_plan_type_check" CHECK (("plan_type" = ANY (ARRAY['seeker_basic'::"text", 'seeker_premium'::"text", 'wali_basic'::"text", 'wali_premium'::"text"]))),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'expired'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


COMMENT ON COLUMN "public"."subscriptions"."user_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."subscriptions"."plan_type" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."subscriptions"."status" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."subscriptions"."billing_period" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."subscriptions"."started_at" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."subscriptions"."expires_at" IS 'OWNERSHIP: row-scoped(user_id)';



CREATE TABLE IF NOT EXISTS "public"."timeline_milestones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "timeline_id" "uuid" NOT NULL,
    "milestone_type" "text" NOT NULL,
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "metadata" "jsonb",
    CONSTRAINT "timeline_milestones_milestone_type_check" CHECK (("milestone_type" = ANY (ARRAY['liked'::"text", 'match_created'::"text", 'journey_started'::"text", 'compatibility_revealed'::"text", 'salam_exchanged'::"text", 'guardian_linked'::"text", 'phase_1_complete'::"text", 'phase_2_complete'::"text", 'phase_3_complete'::"text", 'family_stage'::"text", 'conversation_started'::"text", 'meeting'::"text", 'nikah'::"text", 'journey_ended'::"text", 'journey_restarted'::"text", 'journey_paused'::"text", 'journey_continued'::"text"])))
);


ALTER TABLE "public"."timeline_milestones" OWNER TO "postgres";


COMMENT ON COLUMN "public"."timeline_milestones"."milestone_type" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."timeline_milestones"."occurred_at" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."timeline_milestones"."metadata" IS 'OWNERSHIP: non-exportable — Founder approved 2026-08-06. Unconstrained jsonb; until it has a defined schema it cannot inherit a class its future contents may not deserve. Loosen later if appropriate, never the other way round.';



CREATE TABLE IF NOT EXISTS "public"."timelines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "attempt_id" "uuid" NOT NULL
);


ALTER TABLE "public"."timelines" OWNER TO "postgres";


COMMENT ON COLUMN "public"."timelines"."match_id" IS 'OWNERSHIP: joint';



COMMENT ON COLUMN "public"."timelines"."attempt_id" IS 'OA-ZYRA-159 stage 4a, and the Journey Timeline specification V3 §D2. One timeline per attempt; the SCREEN presents every attempt for a pair as chapters of one relationship. Storage per attempt, presentation per relationship — that is what makes a restart fresh without erasing history.';



CREATE TABLE IF NOT EXISTS "public"."unlock_credits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "tier" "text" NOT NULL,
    "delta" integer NOT NULL,
    "reason" "text" NOT NULL,
    "related_unlock_id" "uuid",
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "unlock_credits_delta_check" CHECK (("delta" <> 0)),
    CONSTRAINT "unlock_credits_reason_check" CHECK (("reason" = ANY (ARRAY['zyra_one_included'::"text", 'purchase'::"text", 'debug_grant'::"text", 'spend'::"text", 'refund'::"text", 'adjustment'::"text"]))),
    CONSTRAINT "unlock_credits_sign_matches_reason" CHECK (((("reason" = 'spend'::"text") AND ("delta" < 0)) OR (("reason" = 'refund'::"text") AND ("delta" > 0)) OR (("reason" = ANY (ARRAY['zyra_one_included'::"text", 'purchase'::"text", 'debug_grant'::"text"])) AND ("delta" > 0)) OR ("reason" = 'adjustment'::"text"))),
    CONSTRAINT "unlock_credits_tier_check" CHECK (("tier" = ANY (ARRAY['paid_single'::"text", 'paid_plus_single'::"text"])))
);


ALTER TABLE "public"."unlock_credits" OWNER TO "postgres";


COMMENT ON TABLE "public"."unlock_credits" IS 'OWNERSHIP: row-scoped(user_id) — the holder''s own ledger.';



COMMENT ON COLUMN "public"."unlock_credits"."user_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."unlock_credits"."tier" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."unlock_credits"."delta" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."unlock_credits"."reason" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."unlock_credits"."related_unlock_id" IS 'OWNERSHIP: row-scoped(user_id)';



COMMENT ON COLUMN "public"."unlock_credits"."note" IS 'OWNERSHIP: row-scoped(user_id)';



CREATE TABLE IF NOT EXISTS "public"."wali_links" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "seeker_id" "uuid" NOT NULL,
    "wali_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_main" boolean DEFAULT false NOT NULL,
    "relationship" "text",
    "main_guardian_authority_id" "uuid",
    "active_since" timestamp with time zone,
    "guardian_link_authority_id" "uuid",
    CONSTRAINT "wali_links_active_since_state" CHECK (((("status" = 'active'::"text") AND ("active_since" IS NOT NULL)) OR (("status" <> 'active'::"text") AND ("active_since" IS NULL)))),
    CONSTRAINT "wali_links_guardian_link_authority_state" CHECK (((("status" = 'active'::"text") AND ("guardian_link_authority_id" IS NOT NULL)) OR (("status" <> 'active'::"text") AND ("guardian_link_authority_id" IS NULL)))),
    CONSTRAINT "wali_links_main_guardian_authority_state" CHECK (((("status" = 'active'::"text") AND ("is_main" IS TRUE) AND ("main_guardian_authority_id" IS NOT NULL)) OR ((("status" <> 'active'::"text") OR ("is_main" IS FALSE)) AND ("main_guardian_authority_id" IS NULL)))),
    CONSTRAINT "wali_links_no_self_link" CHECK (("seeker_id" <> "wali_id")),
    CONSTRAINT "wali_links_relationship_check" CHECK ((("relationship" IS NULL) OR ("relationship" = ANY (ARRAY['father'::"text", 'brother'::"text", 'grandfather'::"text", 'uncle'::"text", 'legal_guardian'::"text", 'family_representative'::"text", 'other'::"text"])))),
    CONSTRAINT "wali_links_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'active'::"text", 'removed'::"text"])))
);


ALTER TABLE "public"."wali_links" OWNER TO "postgres";


COMMENT ON TABLE "public"."wali_links" IS 'Guardian relationships. WRITE PATH IS accept_wali_invite() AND THE zyra_*_guardian() RPCs ONLY — client INSERT/UPDATE/DELETE grants were revoked 2026-08-07 after a demonstrated bypass that let a Seeker create an active link naming any user as their Guardian without consent. Do not re-grant. If a new write is needed, add a SECURITY DEFINER function.';



COMMENT ON COLUMN "public"."wali_links"."seeker_id" IS 'OWNERSHIP: joint(seeker_id, wali_id)';



COMMENT ON COLUMN "public"."wali_links"."wali_id" IS 'OWNERSHIP: joint(seeker_id, wali_id)';



COMMENT ON COLUMN "public"."wali_links"."status" IS 'OWNERSHIP: joint(seeker_id, wali_id)';



COMMENT ON COLUMN "public"."wali_links"."is_main" IS 'OWNERSHIP: joint(seeker_id, wali_id)';



COMMENT ON COLUMN "public"."wali_links"."relationship" IS 'OWNERSHIP: joint(seeker_id, wali_id) — both parties know the relationship. Disclosed to a Seeker only via guardians_for_unlocked, which is gated on a paid profile unlock. Stored as a code; "uncle" renders as "Paternal Uncle".';



COMMENT ON COLUMN "public"."wali_links"."main_guardian_authority_id" IS 'DR-ZYRA-225: opaque current-Main assignment epoch. Rotates whenever this link freshly becomes Main; null for every non-current-Main link. It is not a historical role timestamp and is never displayed.';



COMMENT ON COLUMN "public"."wali_links"."active_since" IS 'DR-ZYRA-225 / 054 N1: server-authoritative start of this link row''s current continuous active period. Fresh on activation/reactivation, preserved across uninterrupted Main/Additional switches and unrelated updates, null while inactive. created_at remains row provenance.';



COMMENT ON COLUMN "public"."wali_links"."guardian_link_authority_id" IS 'DR-ZYRA-233 opaque current-active-link epoch for one Seeker/Guardian relationship. Fresh on activation/reactivation, preserved across continuous Main/Additional switches, null while inactive, never displayed.';



COMMENT ON CONSTRAINT "wali_links_no_self_link" ON "public"."wali_links" IS 'A Guardian relationship requires two people. Integrity, not policy.';



CREATE TABLE IF NOT EXISTS "public"."wali_suggestions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wali_id" "uuid" NOT NULL,
    "seeker_id" "uuid" NOT NULL,
    "suggested_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "responded_at" timestamp with time zone,
    "seen_at" timestamp with time zone,
    CONSTRAINT "wali_suggestions_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."wali_suggestions" OWNER TO "postgres";


COMMENT ON TABLE "public"."wali_suggestions" IS 'OWNERSHIP: joint(wali_id, seeker_id) — a Guardian''s suggestion to their Seeker. NON-EXPORTABLE to the suggested person, who is not party to it and must never learn they were suggested or declined.';



COMMENT ON COLUMN "public"."wali_suggestions"."wali_id" IS 'OWNERSHIP: joint(wali_id, seeker_id)';



COMMENT ON COLUMN "public"."wali_suggestions"."seeker_id" IS 'OWNERSHIP: joint(wali_id, seeker_id)';



COMMENT ON COLUMN "public"."wali_suggestions"."suggested_id" IS 'OWNERSHIP: non-exportable to the suggested person. They are a third party to this row.';



COMMENT ON COLUMN "public"."wali_suggestions"."status" IS 'OWNERSHIP: joint(wali_id, seeker_id) — the Seeker''s response to their own Guardian. Never disclosed to the suggested person: "she declined you" is not theirs to receive.';



COMMENT ON COLUMN "public"."wali_suggestions"."responded_at" IS 'OWNERSHIP: joint(wali_id, seeker_id)';



COMMENT ON COLUMN "public"."wali_suggestions"."seen_at" IS 'OWNERSHIP: row-scoped(seeker_id) — when the Seeker first landed on Introductions with this suggestion present. Null means unseen. Drives the badge only; it is not a read receipt shown to the Guardian, who must not learn whether their suggestion has been looked at but not yet answered.';



CREATE OR REPLACE VIEW "public"."zyra_attempt_participant_rows" AS
 SELECT "a"."id" AS "attempt_id",
    "m"."seeker_a_id" AS "user_id",
    'seeker'::"text" AS "role",
    "a"."match_id",
    NULL::boolean AS "is_main",
    "a"."status" AS "attempt_status"
   FROM ("public"."journey_attempts" "a"
     JOIN "public"."matches" "m" ON (("m"."id" = "a"."match_id")))
UNION ALL
 SELECT "a"."id" AS "attempt_id",
    "m"."seeker_b_id" AS "user_id",
    'seeker'::"text" AS "role",
    "a"."match_id",
    NULL::boolean AS "is_main",
    "a"."status" AS "attempt_status"
   FROM ("public"."journey_attempts" "a"
     JOIN "public"."matches" "m" ON (("m"."id" = "a"."match_id")))
UNION ALL
 SELECT "a"."id" AS "attempt_id",
    "w"."wali_id" AS "user_id",
    'guardian'::"text" AS "role",
    "a"."match_id",
    "w"."is_main",
    "a"."status" AS "attempt_status"
   FROM (("public"."journey_attempts" "a"
     JOIN "public"."matches" "m" ON (("m"."id" = "a"."match_id")))
     JOIN "public"."wali_links" "w" ON ((("w"."status" = 'active'::"text") AND (("w"."seeker_id" = "m"."seeker_a_id") OR ("w"."seeker_id" = "m"."seeker_b_id")))))
  WHERE (("w"."is_main" IS TRUE) OR (("a"."status" = 'active'::"text") AND (EXISTS ( SELECT 1
           FROM "public"."journey_guardian_assignments" "jga"
          WHERE (("jga"."attempt_id" = "a"."id") AND ("jga"."wali_link_id" = "w"."id") AND ("jga"."seeker_id" = "w"."seeker_id") AND ("jga"."revoked_at" IS NULL))))));


ALTER VIEW "public"."zyra_attempt_participant_rows" OWNER TO "postgres";


COMMENT ON VIEW "public"."zyra_attempt_participant_rows" IS 'Canonical unscoped Journey participation: both Seekers; every current Main Guardian; and per-attempt Seeker-authorised Additional Guardians while the attempt remains active. Granted to nobody; clients use the caller-scoped zyra_my_attempt_participation view.';



CREATE OR REPLACE VIEW "public"."zyra_data_ownership" AS
 SELECT "c"."table_name",
    "c"."column_name",
    COALESCE("substring"("pgd"."description", 'OWNERSHIP:\s*([a-z\-]+(\([^)]*\))?)'::"text"), '*** UNCLASSIFIED ***'::"text") AS "ownership",
    "pgd"."description" AS "note"
   FROM (((("information_schema"."columns" "c"
     JOIN "pg_class" "cl" ON (("cl"."relname" = ("c"."table_name")::"name")))
     JOIN "pg_namespace" "ns" ON ((("ns"."oid" = "cl"."relnamespace") AND ("ns"."nspname" = ("c"."table_schema")::"name"))))
     JOIN "pg_tables" "t" ON ((("t"."tablename" = ("c"."table_name")::"name") AND ("t"."schemaname" = ("c"."table_schema")::"name"))))
     LEFT JOIN "pg_description" "pgd" ON ((("pgd"."objoid" = "cl"."oid") AND ("pgd"."objsubid" = ("c"."ordinal_position")::integer))))
  WHERE ((("c"."table_schema")::"name" = 'public'::"name") AND (("c"."column_name")::"name" <> ALL (ARRAY['id'::"name", 'created_at'::"name", 'updated_at'::"name", 'match_id'::"name", 'conversation_id'::"name", 'timeline_id'::"name", 'review_id'::"name", 'attempt_id'::"name", 'phase'::"name", 'question_id'::"name", 'direction'::"name"])));


ALTER VIEW "public"."zyra_data_ownership" OWNER TO "postgres";


COMMENT ON VIEW "public"."zyra_data_ownership" IS 'OA-ZYRA-155, platform-wide. Scans EVERY public table — a new table appears as UNCLASSIFIED automatically. Never export a row showing UNCLASSIFIED or pending-legal.';



CREATE TABLE IF NOT EXISTS "public"."zyra_dev_probe" (
    "n" integer,
    "check_name" "text",
    "got" "text",
    "expected" "text"
);


ALTER TABLE "public"."zyra_dev_probe" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."zyra_guard_results" (
    "n" integer,
    "area" "text",
    "check_name" "text",
    "got" "text",
    "expected" "text"
);


ALTER TABLE "public"."zyra_guard_results" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."zyra_my_attempt_participation" AS
 SELECT "attempt_id",
    "role",
    "match_id",
    "is_main",
    "attempt_status"
   FROM "public"."zyra_attempt_participant_rows"
  WHERE ("user_id" = ( SELECT "auth"."uid"() AS "uid"));


ALTER VIEW "public"."zyra_my_attempt_participation" OWNER TO "postgres";


COMMENT ON VIEW "public"."zyra_my_attempt_participation" IS 'Caller-scoped projection of canonical Journey participation. Additional Guardians appear only while explicitly included in that active Journey.';



CREATE TABLE IF NOT EXISTS "public"."zyra_onboarding_questions" (
    "qid" "text" NOT NULL,
    "gender_visibility" "text" NOT NULL,
    "is_multi" boolean NOT NULL,
    "options" "jsonb" NOT NULL,
    "show_if_qid" "text",
    "show_if_not_any_of" "jsonb",
    "ch4_scored" boolean DEFAULT true NOT NULL,
    "category" "text"
);


ALTER TABLE "public"."zyra_onboarding_questions" OWNER TO "postgres";


COMMENT ON TABLE "public"."zyra_onboarding_questions" IS 'The Chapter 3/4 question bank, server-side. Mirrors data/chapter3_categories.dart — a question added there and not here is a question the completeness gate stops requiring. Renamed from zyra_seed_ch4_questions 2026-08-11: it was created for seeding and became canonical.';



COMMENT ON COLUMN "public"."zyra_onboarding_questions"."show_if_qid" IS 'Mirrors ShowIf.questionId. The question whose answer controls whether this one is asked.';



COMMENT ON COLUMN "public"."zyra_onboarding_questions"."show_if_not_any_of" IS 'Mirrors ShowIf.notAnyOf. Hide this question when the controlling answer is any of these.';



COMMENT ON COLUMN "public"."zyra_onboarding_questions"."ch4_scored" IS 'Mirrors OnboardingQuestion.ch4Status != none. True: has a Chapter 4 preference screen and feeds score_candidates. False: asked in Chapter 3 as profile detail only.';



COMMENT ON COLUMN "public"."zyra_onboarding_questions"."category" IS 'Mirrors OnboardingCategory.name. Nine categories, per the Founder decision of 2026-08-11 on OA-ZYRA-193(d).';



CREATE TABLE IF NOT EXISTS "public"."zyra_probe_score" (
    "viewer" "text",
    "rows_returned" integer,
    "score" numeric
);


ALTER TABLE "public"."zyra_probe_score" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."zyra_seed_answers" (
    "user_id" "uuid",
    "gender" "text",
    "qid" "text",
    "options" "jsonb",
    "is_multi" boolean,
    "n" integer,
    "own_idx" integer,
    "h" integer,
    "answer" "jsonb"
);


ALTER TABLE "public"."zyra_seed_answers" OWNER TO "postgres";


ALTER TABLE ONLY "public"."notification_preferences" ALTER COLUMN "seq" SET DEFAULT "nextval"('"public"."notification_preferences_seq_seq"'::"regclass");



ALTER TABLE ONLY "private"."identity_verification_attempts"
    ADD CONSTRAINT "identity_verification_attempts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "private"."identity_verification_attempts"
    ADD CONSTRAINT "identity_verification_attempts_provider_event_ref_hash_key" UNIQUE ("provider_event_ref_hash");



ALTER TABLE ONLY "private"."identity_verification_attempts"
    ADD CONSTRAINT "identity_verification_attempts_provider_session_ref_key" UNIQUE ("provider_session_ref");



ALTER TABLE ONLY "private"."identity_verification_event_receipts"
    ADD CONSTRAINT "identity_verification_event_receipts_pkey" PRIMARY KEY ("provider_event_ref_hash");



ALTER TABLE ONLY "private"."zyra_personal_code_attempts"
    ADD CONSTRAINT "zyra_personal_code_attempts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "private"."zyra_personal_codes"
    ADD CONSTRAINT "zyra_personal_codes_code_key" UNIQUE ("code");



ALTER TABLE ONLY "private"."zyra_personal_codes"
    ADD CONSTRAINT "zyra_personal_codes_owner_id_role_context_key" UNIQUE ("owner_id", "role_context");



ALTER TABLE ONLY "private"."zyra_personal_codes"
    ADD CONSTRAINT "zyra_personal_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "private"."zyra_retired_personal_code_hashes"
    ADD CONSTRAINT "zyra_retired_personal_code_hashes_pkey" PRIMARY KEY ("code_sha256");



ALTER TABLE ONLY "public"."app_feedback"
    ADD CONSTRAINT "app_feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consents"
    ADD CONSTRAINT "consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_attempt_id_key" UNIQUE ("attempt_id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."guardian_journey_history_consents"
    ADD CONSTRAINT "guardian_journey_history_consents_pkey" PRIMARY KEY ("wali_link_id");



ALTER TABLE ONLY "public"."journey_attempts"
    ADD CONSTRAINT "journey_attempts_match_id_attempt_number_key" UNIQUE ("match_id", "attempt_number");



ALTER TABLE ONLY "public"."journey_attempts"
    ADD CONSTRAINT "journey_attempts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_compatibility"
    ADD CONSTRAINT "journey_compatibility_pkey" PRIMARY KEY ("match_id");



ALTER TABLE ONLY "public"."journey_family_answers"
    ADD CONSTRAINT "journey_family_answers_match_id_direction_question_id_answe_key" UNIQUE ("match_id", "direction", "question_id", "answerer_id");



ALTER TABLE ONLY "public"."journey_family_answers"
    ADD CONSTRAINT "journey_family_answers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_family_review_responses"
    ADD CONSTRAINT "journey_family_review_responses_pkey" PRIMARY KEY ("review_id", "wali_id");



ALTER TABLE ONLY "public"."journey_family_reviews"
    ADD CONSTRAINT "journey_family_reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_guardian_assignments"
    ADD CONSTRAINT "journey_guardian_assignments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_milestone_attestations"
    ADD CONSTRAINT "journey_milestone_attestations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_phase_answers"
    ADD CONSTRAINT "journey_phase_answers_match_id_phase_seeker_id_question_id_key" UNIQUE ("match_id", "phase", "seeker_id", "question_id");



ALTER TABLE ONLY "public"."journey_phase_answers"
    ADD CONSTRAINT "journey_phase_answers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_phase_checkpoints"
    ADD CONSTRAINT "journey_phase_checkpoints_pkey" PRIMARY KEY ("match_id", "phase", "seeker_id");



ALTER TABLE ONLY "public"."journey_phase_ratings"
    ADD CONSTRAINT "journey_phase_ratings_match_id_phase_rater_id_question_id_key" UNIQUE ("match_id", "phase", "rater_id", "question_id");



ALTER TABLE ONLY "public"."journey_phase_ratings"
    ADD CONSTRAINT "journey_phase_ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_requests"
    ADD CONSTRAINT "journey_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_salams"
    ADD CONSTRAINT "journey_salams_pkey" PRIMARY KEY ("match_id", "seeker_id");



ALTER TABLE ONLY "public"."journey_stage_checkpoints"
    ADD CONSTRAINT "journey_stage_checkpoints_pkey" PRIMARY KEY ("match_id", "stage", "seeker_id");



ALTER TABLE ONLY "public"."likes"
    ADD CONSTRAINT "likes_liker_id_liked_id_key" UNIQUE ("liker_id", "liked_id");



ALTER TABLE ONLY "public"."likes"
    ADD CONSTRAINT "likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_seeker_a_id_seeker_b_id_key" UNIQUE ("seeker_a_id", "seeker_b_id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."onboarding_answers"
    ADD CONSTRAINT "onboarding_answers_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."passes"
    ADD CONSTRAINT "passes_passer_id_passed_id_key" UNIQUE ("passer_id", "passed_id");



ALTER TABLE ONLY "public"."passes"
    ADD CONSTRAINT "passes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profile_blocks"
    ADD CONSTRAINT "profile_blocks_blocker_id_blocked_id_key" UNIQUE ("blocker_id", "blocked_id");



ALTER TABLE ONLY "public"."profile_blocks"
    ADD CONSTRAINT "profile_blocks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profile_photos"
    ADD CONSTRAINT "profile_photos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profile_reports"
    ADD CONSTRAINT "profile_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profile_unlocks"
    ADD CONSTRAINT "profile_unlocks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."protection_holds"
    ADD CONSTRAINT "protection_holds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saves"
    ADD CONSTRAINT "saves_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saves"
    ADD CONSTRAINT "saves_saver_id_saved_id_key" UNIQUE ("saver_id", "saved_id");



ALTER TABLE ONLY "public"."seeker_details"
    ADD CONSTRAINT "seeker_details_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."timeline_milestones"
    ADD CONSTRAINT "timeline_milestones_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."timelines"
    ADD CONSTRAINT "timelines_attempt_id_key" UNIQUE ("attempt_id");



ALTER TABLE ONLY "public"."timelines"
    ADD CONSTRAINT "timelines_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."unlock_credits"
    ADD CONSTRAINT "unlock_credits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wali_invites"
    ADD CONSTRAINT "wali_invites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wali_invites"
    ADD CONSTRAINT "wali_invites_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."wali_links"
    ADD CONSTRAINT "wali_links_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wali_links"
    ADD CONSTRAINT "wali_links_seeker_id_wali_id_key" UNIQUE ("seeker_id", "wali_id");



ALTER TABLE ONLY "public"."wali_suggestions"
    ADD CONSTRAINT "wali_suggestions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wali_suggestions"
    ADD CONSTRAINT "wali_suggestions_wali_id_seeker_id_suggested_id_key" UNIQUE ("wali_id", "seeker_id", "suggested_id");



ALTER TABLE ONLY "public"."zyra_onboarding_questions"
    ADD CONSTRAINT "zyra_seed_ch4_questions_pkey" PRIMARY KEY ("qid", "gender_visibility");



CREATE UNIQUE INDEX "identity_verification_attempts_one_open_per_user" ON "private"."identity_verification_attempts" USING "btree" ("user_id") WHERE (("member_deleted_at" IS NULL) AND ("result" = ANY (ARRAY['pending'::"text", 'retry_required'::"text", 'review_required'::"text"])));



CREATE UNIQUE INDEX "identity_verification_attempts_one_verified_per_user" ON "private"."identity_verification_attempts" USING "btree" ("user_id") WHERE (("member_deleted_at" IS NULL) AND ("result" = 'verified'::"text"));



CREATE INDEX "identity_verification_attempts_user_created" ON "private"."identity_verification_attempts" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "zyra_personal_code_attempts_caller_time" ON "private"."zyra_personal_code_attempts" USING "btree" ("caller_id", "attempted_at" DESC);



CREATE INDEX "app_feedback_created_idx" ON "public"."app_feedback" USING "btree" ("created_at" DESC);



CREATE INDEX "app_feedback_user_idx" ON "public"."app_feedback" USING "btree" ("user_id") WHERE ("user_id" IS NOT NULL);



CREATE INDEX "consents_user_type_recent" ON "public"."consents" USING "btree" ("user_id", "consent_type", "recorded_at" DESC);



CREATE INDEX "conversations_attempt_idx" ON "public"."conversations" USING "btree" ("attempt_id");



CREATE INDEX "journey_attempts_active" ON "public"."journey_attempts" USING "btree" ("status") WHERE ("status" = 'active'::"text");



CREATE INDEX "journey_attempts_ended_by_idx" ON "public"."journey_attempts" USING "btree" ("ended_by");



CREATE INDEX "journey_attempts_match" ON "public"."journey_attempts" USING "btree" ("match_id");



CREATE UNIQUE INDEX "journey_attempts_one_active_per_match" ON "public"."journey_attempts" USING "btree" ("match_id") WHERE ("status" = 'active'::"text");



CREATE INDEX "journey_attempts_paused_by_idx" ON "public"."journey_attempts" USING "btree" ("paused_by");



CREATE INDEX "journey_compatibility_attempt_idx" ON "public"."journey_compatibility" USING "btree" ("attempt_id");



CREATE INDEX "journey_family_answers_answerer_idx" ON "public"."journey_family_answers" USING "btree" ("answerer_id");



CREATE INDEX "journey_family_answers_attempt_idx" ON "public"."journey_family_answers" USING "btree" ("attempt_id");



CREATE INDEX "journey_family_review_responses_dashboard_updates_idx" ON "public"."journey_family_review_responses" USING "btree" ("review_id", "responded_at" DESC, "wali_id");



CREATE INDEX "journey_family_review_responses_wali_idx" ON "public"."journey_family_review_responses" USING "btree" ("wali_id");



CREATE INDEX "journey_family_reviews_attempt_idx" ON "public"."journey_family_reviews" USING "btree" ("attempt_id");



CREATE INDEX "journey_family_reviews_dashboard_updates_idx" ON "public"."journey_family_reviews" USING "btree" ("attempt_id", "opened_at" DESC, "id" DESC) WHERE ("attempt_id" IS NOT NULL);



CREATE UNIQUE INDEX "journey_family_reviews_one_pending_per_attempt" ON "public"."journey_family_reviews" USING "btree" ("attempt_id") WHERE ("status" = 'pending'::"text");



CREATE UNIQUE INDEX "journey_family_reviews_one_pending_per_match" ON "public"."journey_family_reviews" USING "btree" ("match_id") WHERE ("status" = 'pending'::"text");



CREATE INDEX "journey_guardian_assignments_link_history" ON "public"."journey_guardian_assignments" USING "btree" ("wali_link_id", "granted_at" DESC);



CREATE UNIQUE INDEX "journey_guardian_assignments_one_live" ON "public"."journey_guardian_assignments" USING "btree" ("attempt_id", "wali_link_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "journey_milestone_attestations_match_idx" ON "public"."journey_milestone_attestations" USING "btree" ("match_id");



CREATE UNIQUE INDEX "journey_milestone_attestations_one_pending" ON "public"."journey_milestone_attestations" USING "btree" ("attempt_id", "milestone_type") WHERE ("status" = 'pending'::"text");



CREATE INDEX "journey_phase_answers_attempt_idx" ON "public"."journey_phase_answers" USING "btree" ("attempt_id");



CREATE INDEX "journey_phase_answers_seeker_idx" ON "public"."journey_phase_answers" USING "btree" ("seeker_id");



CREATE INDEX "journey_phase_checkpoints_attempt_idx" ON "public"."journey_phase_checkpoints" USING "btree" ("attempt_id");



CREATE INDEX "journey_phase_checkpoints_seeker_idx" ON "public"."journey_phase_checkpoints" USING "btree" ("seeker_id");



CREATE INDEX "journey_phase_ratings_attempt_idx" ON "public"."journey_phase_ratings" USING "btree" ("attempt_id");



CREATE INDEX "journey_phase_ratings_rater_idx" ON "public"."journey_phase_ratings" USING "btree" ("rater_id");



CREATE INDEX "journey_requests_expiry_sweep_idx" ON "public"."journey_requests" USING "btree" ("expires_at") WHERE ("status" = 'pending'::"text");



CREATE UNIQUE INDEX "journey_requests_one_pending_per_pair" ON "public"."journey_requests" USING "btree" ("match_id") WHERE ("status" = 'pending'::"text");



CREATE INDEX "journey_requests_recipient_idx" ON "public"."journey_requests" USING "btree" ("requested_to") WHERE ("status" = 'pending'::"text");



CREATE INDEX "journey_salams_attempt_idx" ON "public"."journey_salams" USING "btree" ("attempt_id");



CREATE INDEX "journey_salams_seeker_idx" ON "public"."journey_salams" USING "btree" ("seeker_id");



CREATE INDEX "journey_stage_checkpoints_attempt_idx" ON "public"."journey_stage_checkpoints" USING "btree" ("attempt_id");



CREATE INDEX "journey_stage_checkpoints_seeker_idx" ON "public"."journey_stage_checkpoints" USING "btree" ("seeker_id");



CREATE INDEX "likes_liked" ON "public"."likes" USING "btree" ("liked_id", "created_at" DESC);



CREATE INDEX "likes_liker" ON "public"."likes" USING "btree" ("liker_id", "created_at" DESC);



CREATE INDEX "matches_ended_by_idx" ON "public"."matches" USING "btree" ("ended_by");



CREATE INDEX "matches_seeker_a_active" ON "public"."matches" USING "btree" ("seeker_a_id") WHERE (("status" = 'active'::"text") AND ("suspended_by" IS NULL));



CREATE INDEX "matches_seeker_b_active" ON "public"."matches" USING "btree" ("seeker_b_id") WHERE (("status" = 'active'::"text") AND ("suspended_by" IS NULL));



CREATE INDEX "matches_suspended_by_idx" ON "public"."matches" USING "btree" ("suspended_by");



CREATE INDEX "messages_conversation_created" ON "public"."messages" USING "btree" ("conversation_id", "created_at" DESC);



CREATE INDEX "messages_sender_idx" ON "public"."messages" USING "btree" ("sender_id");



CREATE INDEX "notification_preferences_current" ON "public"."notification_preferences" USING "btree" ("user_id", "category", "seq" DESC);



CREATE INDEX "notifications_dashboard_updates_unread_idx" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC, "id" DESC) WHERE ("read_at" IS NULL);



CREATE INDEX "notifications_related_match_idx" ON "public"."notifications" USING "btree" ("related_match_id");



CREATE INDEX "notifications_user_created" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "onboarding_answers_synthetic_idx" ON "public"."onboarding_answers" USING "btree" ("is_synthetic") WHERE "is_synthetic";



CREATE INDEX "passes_passed_idx" ON "public"."passes" USING "btree" ("passed_id");



CREATE INDEX "passes_passer_idx" ON "public"."passes" USING "btree" ("passer_id");



CREATE INDEX "profile_blocks_blocked" ON "public"."profile_blocks" USING "btree" ("blocked_id", "blocker_id");



CREATE INDEX "profile_blocks_blocker" ON "public"."profile_blocks" USING "btree" ("blocker_id", "blocked_id");



CREATE UNIQUE INDEX "profile_photos_primary" ON "public"."profile_photos" USING "btree" ("user_id") WHERE ("is_primary" = true);



CREATE INDEX "profile_photos_storage_path_idx" ON "public"."profile_photos" USING "btree" ("storage_path");



CREATE INDEX "profile_reports_pending" ON "public"."profile_reports" USING "btree" ("created_at" DESC) WHERE ("status" = 'pending'::"text");



CREATE INDEX "profile_reports_reported" ON "public"."profile_reports" USING "btree" ("reported_id", "created_at" DESC);



CREATE INDEX "profile_reports_reporter_idx" ON "public"."profile_reports" USING "btree" ("reporter_id");



CREATE INDEX "profile_unlocks_by_unlocker" ON "public"."profile_unlocks" USING "btree" ("unlocker_id");



CREATE UNIQUE INDEX "profile_unlocks_once" ON "public"."profile_unlocks" USING "btree" ("unlocker_id", "unlocked_id", "unlock_type");



CREATE INDEX "profile_unlocks_unlocked_idx" ON "public"."profile_unlocks" USING "btree" ("unlocked_id");



CREATE INDEX "profiles_browse" ON "public"."profiles" USING "btree" ("gender", "is_active", "profile_complete") WHERE (("is_active" = true) AND ("profile_complete" = true));



CREATE INDEX "protection_holds_active_idx" ON "public"."protection_holds" USING "btree" ("restricted_id", "protected_id") WHERE ("released_at" IS NULL);



CREATE INDEX "protection_holds_match_idx" ON "public"."protection_holds" USING "btree" ("match_id");



CREATE INDEX "saves_mutual" ON "public"."saves" USING "btree" ("saved_id", "saver_id");



CREATE INDEX "seeker_details_ethnicity" ON "public"."seeker_details" USING "btree" ("ethnicity");



CREATE INDEX "seeker_details_languages" ON "public"."seeker_details" USING "gin" ("languages");



CREATE INDEX "seeker_details_sect" ON "public"."seeker_details" USING "btree" ("sect");



CREATE UNIQUE INDEX "subscriptions_active_user" ON "public"."subscriptions" USING "btree" ("user_id") WHERE ("status" = 'active'::"text");



CREATE INDEX "subscriptions_user" ON "public"."subscriptions" USING "btree" ("user_id") WHERE ("status" = 'active'::"text");



CREATE INDEX "timeline_milestones_dashboard_updates_idx" ON "public"."timeline_milestones" USING "btree" ("timeline_id", "occurred_at" DESC, "id" DESC);



CREATE INDEX "timeline_milestones_timeline_idx" ON "public"."timeline_milestones" USING "btree" ("timeline_id");



CREATE INDEX "timelines_attempt_idx" ON "public"."timelines" USING "btree" ("attempt_id");



CREATE INDEX "unlock_credits_balance" ON "public"."unlock_credits" USING "btree" ("user_id", "tier");



CREATE UNIQUE INDEX "unlock_credits_one_zyra_one_grant" ON "public"."unlock_credits" USING "btree" ("user_id", "tier") WHERE ("reason" = 'zyra_one_included'::"text");



CREATE INDEX "unlock_credits_related_unlock_idx" ON "public"."unlock_credits" USING "btree" ("related_unlock_id");



CREATE INDEX "wali_invites_accepted_by_idx" ON "public"."wali_invites" USING "btree" ("accepted_by");



CREATE INDEX "wali_invites_inviter_idx" ON "public"."wali_invites" USING "btree" ("inviter_id");



CREATE UNIQUE INDEX "wali_invites_one_pending_personal_request" ON "public"."wali_invites" USING "btree" ("personal_code_id", "recipient_id") WHERE (("source" = 'personal_code'::"text") AND ("status" = 'pending'::"text"));



CREATE INDEX "wali_invites_personal_incoming" ON "public"."wali_invites" USING "btree" ("inviter_id", "status", "created_at" DESC) WHERE ("source" = 'personal_code'::"text");



CREATE INDEX "wali_invites_personal_outgoing" ON "public"."wali_invites" USING "btree" ("recipient_id", "status", "created_at" DESC) WHERE ("source" = 'personal_code'::"text");



CREATE UNIQUE INDEX "wali_links_one_main_per_seeker" ON "public"."wali_links" USING "btree" ("seeker_id") WHERE (("is_main" = true) AND ("status" = 'active'::"text"));



CREATE INDEX "wali_links_seeker" ON "public"."wali_links" USING "btree" ("seeker_id") WHERE ("status" = 'active'::"text");



CREATE INDEX "wali_links_wali" ON "public"."wali_links" USING "btree" ("wali_id") WHERE ("status" = 'active'::"text");



CREATE INDEX "wali_suggestions_dashboard_updates_seeker_idx" ON "public"."wali_suggestions" USING "btree" ("seeker_id", "created_at" DESC, "id" DESC);



CREATE INDEX "wali_suggestions_seeker" ON "public"."wali_suggestions" USING "btree" ("seeker_id", "status");



CREATE INDEX "wali_suggestions_suggested_idx" ON "public"."wali_suggestions" USING "btree" ("suggested_id");



CREATE INDEX "wali_suggestions_unseen" ON "public"."wali_suggestions" USING "btree" ("seeker_id") WHERE (("seen_at" IS NULL) AND ("status" = 'pending'::"text"));



CREATE OR REPLACE TRIGGER "identity_verification_attempts_updated_at" BEFORE UPDATE ON "private"."identity_verification_attempts" FOR EACH ROW EXECUTE FUNCTION "private"."zyra_touch_identity_verification_attempt"();



CREATE OR REPLACE TRIGGER "zyra_retire_personal_code_before_change" BEFORE DELETE OR UPDATE OF "code" ON "private"."zyra_personal_codes" FOR EACH ROW EXECUTE FUNCTION "private"."zyra_retire_personal_code"();



CREATE OR REPLACE TRIGGER "conversations_set_attempt" BEFORE INSERT ON "public"."conversations" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE CONSTRAINT TRIGGER "journey_attempts_one_active_per_person" AFTER INSERT OR UPDATE OF "status", "paused_by" ON "public"."journey_attempts" NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION "public"."zyra_enforce_one_active_attempt"();



CREATE OR REPLACE TRIGGER "journey_compatibility_set_attempt" BEFORE INSERT ON "public"."journey_compatibility" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "journey_family_answers_set_attempt" BEFORE INSERT ON "public"."journey_family_answers" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "journey_family_reviews_set_attempt" BEFORE INSERT ON "public"."journey_family_reviews" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "journey_phase_answers_set_attempt" BEFORE INSERT ON "public"."journey_phase_answers" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "journey_phase_checkpoints_set_attempt" BEFORE INSERT ON "public"."journey_phase_checkpoints" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "journey_phase_ratings_set_attempt" BEFORE INSERT ON "public"."journey_phase_ratings" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "journey_salams_set_attempt" BEFORE INSERT ON "public"."journey_salams" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "journey_stage_checkpoints_set_attempt" BEFORE INSERT ON "public"."journey_stage_checkpoints" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "likes_clear_others" AFTER INSERT ON "public"."likes" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_like_clears_others"();



CREATE OR REPLACE TRIGGER "likes_create_match" AFTER INSERT ON "public"."likes" FOR EACH ROW EXECUTE FUNCTION "public"."create_match_on_mutual_like"();



CREATE OR REPLACE TRIGGER "matches_create_first_attempt" AFTER INSERT ON "public"."matches" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_create_first_attempt"();



CREATE CONSTRAINT TRIGGER "matches_one_active_per_person" AFTER INSERT OR UPDATE OF "status", "suspended_by" ON "public"."matches" NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION "public"."zyra_enforce_one_active_match"();



CREATE OR REPLACE TRIGGER "matches_record_journey_milestone" AFTER UPDATE ON "public"."matches" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_record_journey_milestone"();



CREATE OR REPLACE TRIGGER "messages_create_conversation_started_milestone" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."create_conversation_started_milestone"();



CREATE OR REPLACE TRIGGER "messages_notify_recipient" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."notify_new_message"();



CREATE OR REPLACE TRIGGER "onboarding_answers_refresh_complete" AFTER INSERT OR DELETE OR UPDATE ON "public"."onboarding_answers" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_answers_refresh_onboarding_complete"();



CREATE OR REPLACE TRIGGER "onboarding_answers_updated_at" BEFORE UPDATE ON "public"."onboarding_answers" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "passes_clear_others" AFTER INSERT ON "public"."passes" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_pass_clears_others"();



CREATE OR REPLACE TRIGGER "profiles_normalise_identity" BEFORE INSERT OR UPDATE OF "first_name" ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_normalise_profile_identity"();



CREATE OR REPLACE TRIGGER "profiles_set_onboarding_complete" BEFORE INSERT OR UPDATE OF "profile_complete", "gender", "role" ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_profiles_set_onboarding_complete"();



CREATE OR REPLACE TRIGGER "profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "saves_clear_others" AFTER INSERT ON "public"."saves" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_save_clears_others"();



CREATE OR REPLACE TRIGGER "seeker_details_refresh_complete" AFTER INSERT OR DELETE OR UPDATE ON "public"."seeker_details" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_answers_refresh_onboarding_complete"();



CREATE OR REPLACE TRIGGER "seeker_details_touch" BEFORE UPDATE ON "public"."seeker_details" FOR EACH ROW EXECUTE FUNCTION "public"."touch_seeker_details"();



CREATE OR REPLACE TRIGGER "subscriptions_grant_zyra_one_credits" AFTER INSERT OR UPDATE OF "plan_type", "status" ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."grant_zyra_one_credits"();



CREATE OR REPLACE TRIGGER "timelines_set_attempt" BEFORE INSERT ON "public"."timelines" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_set_attempt_from_match"();



CREATE OR REPLACE TRIGGER "wali_invites_personal_request_owner_acceptance" BEFORE UPDATE OF "status" ON "public"."wali_invites" FOR EACH ROW EXECUTE FUNCTION "private"."zyra_enforce_personal_request_owner_acceptance"();



CREATE OR REPLACE TRIGGER "wali_links_auto_main" BEFORE INSERT OR UPDATE ON "public"."wali_links" FOR EACH ROW EXECUTE FUNCTION "public"."auto_designate_main_wali"();



CREATE OR REPLACE TRIGGER "zyra_wali_links_guardian_link_allowed" BEFORE INSERT OR UPDATE OF "seeker_id", "wali_id", "status" ON "public"."wali_links" FOR EACH ROW EXECUTE FUNCTION "public"."zyra_enforce_guardian_link_allowed"();



ALTER TABLE ONLY "private"."identity_verification_attempts"
    ADD CONSTRAINT "identity_verification_attempts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "private"."identity_verification_event_receipts"
    ADD CONSTRAINT "identity_verification_event_receipts_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "private"."identity_verification_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "private"."zyra_personal_code_attempts"
    ADD CONSTRAINT "zyra_personal_code_attempts_caller_id_fkey" FOREIGN KEY ("caller_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "private"."zyra_personal_codes"
    ADD CONSTRAINT "zyra_personal_codes_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."app_feedback"
    ADD CONSTRAINT "app_feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."consents"
    ADD CONSTRAINT "consents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."guardian_journey_history_consents"
    ADD CONSTRAINT "guardian_journey_history_consents_wali_link_id_fkey" FOREIGN KEY ("wali_link_id") REFERENCES "public"."wali_links"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_attempts"
    ADD CONSTRAINT "journey_attempts_ended_by_fkey" FOREIGN KEY ("ended_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."journey_attempts"
    ADD CONSTRAINT "journey_attempts_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_attempts"
    ADD CONSTRAINT "journey_attempts_paused_by_fkey" FOREIGN KEY ("paused_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."journey_compatibility"
    ADD CONSTRAINT "journey_compatibility_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_compatibility"
    ADD CONSTRAINT "journey_compatibility_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_family_answers"
    ADD CONSTRAINT "journey_family_answers_answerer_id_fkey" FOREIGN KEY ("answerer_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_family_answers"
    ADD CONSTRAINT "journey_family_answers_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_family_answers"
    ADD CONSTRAINT "journey_family_answers_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_family_review_responses"
    ADD CONSTRAINT "journey_family_review_responses_review_id_fkey" FOREIGN KEY ("review_id") REFERENCES "public"."journey_family_reviews"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_family_review_responses"
    ADD CONSTRAINT "journey_family_review_responses_wali_id_fkey" FOREIGN KEY ("wali_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_family_reviews"
    ADD CONSTRAINT "journey_family_reviews_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_family_reviews"
    ADD CONSTRAINT "journey_family_reviews_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_guardian_assignments"
    ADD CONSTRAINT "journey_guardian_assignments_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_guardian_assignments"
    ADD CONSTRAINT "journey_guardian_assignments_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."journey_guardian_assignments"
    ADD CONSTRAINT "journey_guardian_assignments_revoked_by_fkey" FOREIGN KEY ("revoked_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."journey_guardian_assignments"
    ADD CONSTRAINT "journey_guardian_assignments_seeker_id_fkey" FOREIGN KEY ("seeker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_guardian_assignments"
    ADD CONSTRAINT "journey_guardian_assignments_wali_link_id_fkey" FOREIGN KEY ("wali_link_id") REFERENCES "public"."wali_links"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_milestone_attestations"
    ADD CONSTRAINT "journey_milestone_attestations_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_milestone_attestations"
    ADD CONSTRAINT "journey_milestone_attestations_confirmed_by_fkey" FOREIGN KEY ("confirmed_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."journey_milestone_attestations"
    ADD CONSTRAINT "journey_milestone_attestations_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_milestone_attestations"
    ADD CONSTRAINT "journey_milestone_attestations_proposed_by_fkey" FOREIGN KEY ("proposed_by") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_answers"
    ADD CONSTRAINT "journey_phase_answers_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_answers"
    ADD CONSTRAINT "journey_phase_answers_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_answers"
    ADD CONSTRAINT "journey_phase_answers_seeker_id_fkey" FOREIGN KEY ("seeker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_checkpoints"
    ADD CONSTRAINT "journey_phase_checkpoints_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_checkpoints"
    ADD CONSTRAINT "journey_phase_checkpoints_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_checkpoints"
    ADD CONSTRAINT "journey_phase_checkpoints_seeker_id_fkey" FOREIGN KEY ("seeker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_ratings"
    ADD CONSTRAINT "journey_phase_ratings_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_ratings"
    ADD CONSTRAINT "journey_phase_ratings_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_phase_ratings"
    ADD CONSTRAINT "journey_phase_ratings_rater_id_fkey" FOREIGN KEY ("rater_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_requests"
    ADD CONSTRAINT "journey_requests_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."journey_requests"
    ADD CONSTRAINT "journey_requests_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_requests"
    ADD CONSTRAINT "journey_requests_requested_by_fkey" FOREIGN KEY ("requested_by") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_requests"
    ADD CONSTRAINT "journey_requests_requested_to_fkey" FOREIGN KEY ("requested_to") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_salams"
    ADD CONSTRAINT "journey_salams_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_salams"
    ADD CONSTRAINT "journey_salams_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_salams"
    ADD CONSTRAINT "journey_salams_seeker_id_fkey" FOREIGN KEY ("seeker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_stage_checkpoints"
    ADD CONSTRAINT "journey_stage_checkpoints_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_stage_checkpoints"
    ADD CONSTRAINT "journey_stage_checkpoints_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_stage_checkpoints"
    ADD CONSTRAINT "journey_stage_checkpoints_seeker_id_fkey" FOREIGN KEY ("seeker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."likes"
    ADD CONSTRAINT "likes_liked_id_fkey" FOREIGN KEY ("liked_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."likes"
    ADD CONSTRAINT "likes_liker_id_fkey" FOREIGN KEY ("liker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_ended_by_fkey" FOREIGN KEY ("ended_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_seeker_a_id_fkey" FOREIGN KEY ("seeker_a_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_seeker_b_id_fkey" FOREIGN KEY ("seeker_b_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_suspended_by_fkey" FOREIGN KEY ("suspended_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_related_match_id_fkey" FOREIGN KEY ("related_match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."onboarding_answers"
    ADD CONSTRAINT "onboarding_answers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passes"
    ADD CONSTRAINT "passes_passed_id_fkey" FOREIGN KEY ("passed_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passes"
    ADD CONSTRAINT "passes_passer_id_fkey" FOREIGN KEY ("passer_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_blocks"
    ADD CONSTRAINT "profile_blocks_blocked_id_fkey" FOREIGN KEY ("blocked_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_blocks"
    ADD CONSTRAINT "profile_blocks_blocker_id_fkey" FOREIGN KEY ("blocker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_photos"
    ADD CONSTRAINT "profile_photos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_reports"
    ADD CONSTRAINT "profile_reports_reported_id_fkey" FOREIGN KEY ("reported_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_reports"
    ADD CONSTRAINT "profile_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_unlocks"
    ADD CONSTRAINT "profile_unlocks_unlocked_id_fkey" FOREIGN KEY ("unlocked_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_unlocks"
    ADD CONSTRAINT "profile_unlocks_unlocker_id_fkey" FOREIGN KEY ("unlocker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protection_holds"
    ADD CONSTRAINT "protection_holds_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protection_holds"
    ADD CONSTRAINT "protection_holds_protected_id_fkey" FOREIGN KEY ("protected_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protection_holds"
    ADD CONSTRAINT "protection_holds_released_by_fkey" FOREIGN KEY ("released_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."protection_holds"
    ADD CONSTRAINT "protection_holds_restricted_id_fkey" FOREIGN KEY ("restricted_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."saves"
    ADD CONSTRAINT "saves_saved_id_fkey" FOREIGN KEY ("saved_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."saves"
    ADD CONSTRAINT "saves_saver_id_fkey" FOREIGN KEY ("saver_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."seeker_details"
    ADD CONSTRAINT "seeker_details_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."timeline_milestones"
    ADD CONSTRAINT "timeline_milestones_timeline_id_fkey" FOREIGN KEY ("timeline_id") REFERENCES "public"."timelines"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."timelines"
    ADD CONSTRAINT "timelines_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "public"."journey_attempts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."timelines"
    ADD CONSTRAINT "timelines_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."unlock_credits"
    ADD CONSTRAINT "unlock_credits_related_unlock_id_fkey" FOREIGN KEY ("related_unlock_id") REFERENCES "public"."profile_unlocks"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."unlock_credits"
    ADD CONSTRAINT "unlock_credits_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wali_invites"
    ADD CONSTRAINT "wali_invites_accepted_by_fkey" FOREIGN KEY ("accepted_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."wali_invites"
    ADD CONSTRAINT "wali_invites_declined_by_fkey" FOREIGN KEY ("declined_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."wali_invites"
    ADD CONSTRAINT "wali_invites_inviter_id_fkey" FOREIGN KEY ("inviter_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wali_invites"
    ADD CONSTRAINT "wali_invites_personal_code_id_fkey" FOREIGN KEY ("personal_code_id") REFERENCES "private"."zyra_personal_codes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wali_invites"
    ADD CONSTRAINT "wali_invites_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wali_invites"
    ADD CONSTRAINT "wali_invites_seen_by_fkey" FOREIGN KEY ("seen_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."wali_links"
    ADD CONSTRAINT "wali_links_seeker_id_fkey" FOREIGN KEY ("seeker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wali_links"
    ADD CONSTRAINT "wali_links_wali_id_fkey" FOREIGN KEY ("wali_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wali_suggestions"
    ADD CONSTRAINT "wali_suggestions_seeker_id_fkey" FOREIGN KEY ("seeker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wali_suggestions"
    ADD CONSTRAINT "wali_suggestions_suggested_id_fkey" FOREIGN KEY ("suggested_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wali_suggestions"
    ADD CONSTRAINT "wali_suggestions_wali_id_fkey" FOREIGN KEY ("wali_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE "private"."identity_verification_attempts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "private"."identity_verification_event_receipts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "private"."zyra_personal_code_attempts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "private"."zyra_personal_codes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "private"."zyra_retired_personal_code_hashes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_feedback" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "app_feedback_select_own" ON "public"."app_feedback" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."consents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "consents_insert" ON "public"."consents" FOR INSERT WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "consents_select" ON "public"."consents" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "conversations_select" ON "public"."conversations" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."attempt_id" = "conversations"."attempt_id") AND (("r"."role" = 'seeker'::"text") OR (("r"."role" = 'guardian'::"text") AND ("r"."attempt_status" <> 'potential'::"text")))))));



ALTER TABLE "public"."guardian_journey_history_consents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journey_attempts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journey_compatibility" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journey_family_answers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_family_answers_read" ON "public"."journey_family_answers" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."attempt_id" = "journey_family_answers"."attempt_id") AND ("r"."role" = ANY (ARRAY['seeker'::"text", 'guardian'::"text"]))))));



CREATE POLICY "journey_family_answers_write" ON "public"."journey_family_answers" FOR INSERT WITH CHECK (("answerer_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."journey_family_review_responses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_family_review_responses_read" ON "public"."journey_family_review_responses" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."journey_family_reviews" "rev"
     JOIN "public"."zyra_my_attempt_participation" "r" ON (("r"."attempt_id" = "rev"."attempt_id")))
  WHERE (("rev"."id" = "journey_family_review_responses"."review_id") AND (("r"."role" = 'seeker'::"text") OR ("r"."is_main" = true))))));



ALTER TABLE "public"."journey_family_reviews" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_family_reviews_read" ON "public"."journey_family_reviews" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."attempt_id" = "journey_family_reviews"."attempt_id") AND (("r"."role" = 'seeker'::"text") OR ("r"."is_main" = true))))));



ALTER TABLE "public"."journey_guardian_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journey_milestone_attestations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."journey_phase_answers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_phase_answers_read" ON "public"."journey_phase_answers" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."attempt_id" = "journey_phase_answers"."attempt_id") AND ("r"."role" = 'seeker'::"text")))));



CREATE POLICY "journey_phase_answers_write" ON "public"."journey_phase_answers" FOR INSERT WITH CHECK ((("seeker_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."match_id" = "journey_phase_answers"."match_id") AND ("r"."role" = 'seeker'::"text"))))));



ALTER TABLE "public"."journey_phase_checkpoints" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_phase_checkpoints_read" ON "public"."journey_phase_checkpoints" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."attempt_id" = "journey_phase_checkpoints"."attempt_id") AND ("r"."role" = 'seeker'::"text")))));



CREATE POLICY "journey_phase_checkpoints_write" ON "public"."journey_phase_checkpoints" FOR INSERT WITH CHECK ((("seeker_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."match_id" = "journey_phase_checkpoints"."match_id") AND ("r"."role" = 'seeker'::"text"))))));



ALTER TABLE "public"."journey_phase_ratings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_phase_ratings_own" ON "public"."journey_phase_ratings" USING (("rater_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("rater_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."journey_requests" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_requests_select" ON "public"."journey_requests" FOR SELECT TO "authenticated" USING ((("requested_by" = ( SELECT "auth"."uid"() AS "uid")) OR ("requested_to" = ( SELECT "auth"."uid"() AS "uid"))));



ALTER TABLE "public"."journey_salams" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_salams_read" ON "public"."journey_salams" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."attempt_id" = "journey_salams"."attempt_id") AND ("r"."role" = 'seeker'::"text")))));



CREATE POLICY "journey_salams_write" ON "public"."journey_salams" FOR INSERT WITH CHECK ((("seeker_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."match_id" = "journey_salams"."match_id") AND ("r"."role" = 'seeker'::"text"))))));



ALTER TABLE "public"."journey_stage_checkpoints" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "journey_stage_checkpoints_read" ON "public"."journey_stage_checkpoints" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."attempt_id" = "journey_stage_checkpoints"."attempt_id") AND ("r"."role" = 'seeker'::"text")))));



ALTER TABLE "public"."likes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "likes_delete" ON "public"."likes" FOR DELETE USING (("liker_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "likes_insert" ON "public"."likes" FOR INSERT WITH CHECK ((("liker_id" = ( SELECT "auth"."uid"() AS "uid")) AND "public"."zyra_can_match"("liker_id", "liked_id")));



CREATE POLICY "likes_select" ON "public"."likes" FOR SELECT USING ((("liker_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("liked_id" = ( SELECT "auth"."uid"() AS "uid"))));



ALTER TABLE "public"."matches" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "matches_select" ON "public"."matches" FOR SELECT USING ((("seeker_a_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("seeker_b_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM ("public"."journey_attempts" "a"
     JOIN "public"."wali_links" "w" ON ((("w"."wali_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("w"."status" = 'active'::"text") AND ("w"."seeker_id" = ANY (ARRAY["matches"."seeker_a_id", "matches"."seeker_b_id"])))))
  WHERE (("a"."match_id" = "matches"."id") AND ("a"."status" <> 'potential'::"text") AND (("w"."is_main" IS TRUE) OR (("a"."status" = 'active'::"text") AND (EXISTS ( SELECT 1
           FROM "public"."journey_guardian_assignments" "jga"
          WHERE (("jga"."attempt_id" = "a"."id") AND ("jga"."wali_link_id" = "w"."id") AND ("jga"."seeker_id" = "w"."seeker_id") AND ("jga"."revoked_at" IS NULL)))))))))));



ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "messages_insert" ON "public"."messages" FOR INSERT WITH CHECK ((("sender_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM (("public"."conversations" "c"
     JOIN "public"."zyra_my_attempt_participation" "r" ON (("r"."attempt_id" = "c"."attempt_id")))
     JOIN "public"."matches" "mt" ON (("mt"."id" = "r"."match_id")))
  WHERE (("c"."id" = "messages"."conversation_id") AND ("r"."role" = 'seeker'::"text") AND ("r"."attempt_status" = 'active'::"text") AND ("c"."status" = 'active'::"text") AND (NOT "public"."zyra_block_exists"(
        CASE
            WHEN ("mt"."seeker_a_id" = ( SELECT "auth"."uid"() AS "uid")) THEN "mt"."seeker_b_id"
            ELSE "mt"."seeker_a_id"
        END)))))));



CREATE POLICY "messages_select" ON "public"."messages" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."conversations" "c"
     JOIN "public"."zyra_my_attempt_participation" "r" ON (("r"."attempt_id" = "c"."attempt_id")))
  WHERE (("c"."id" = "messages"."conversation_id") AND (("r"."role" = 'seeker'::"text") OR (("r"."role" = 'guardian'::"text") AND ("r"."attempt_status" <> 'potential'::"text")))))));



ALTER TABLE "public"."notification_preferences" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notification_preferences_select" ON "public"."notification_preferences" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_select" ON "public"."notifications" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "notifications_update" ON "public"."notifications" FOR UPDATE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."onboarding_answers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "onboarding_answers_insert" ON "public"."onboarding_answers" FOR INSERT WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "onboarding_answers_select" ON "public"."onboarding_answers" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "onboarding_answers_update" ON "public"."onboarding_answers" FOR UPDATE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."passes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "passes_delete" ON "public"."passes" FOR DELETE TO "authenticated" USING (("passer_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "passes_insert" ON "public"."passes" FOR INSERT WITH CHECK ((("passer_id" = ( SELECT "auth"."uid"() AS "uid")) AND "public"."zyra_can_match"("passer_id", "passed_id")));



CREATE POLICY "passes_select" ON "public"."passes" FOR SELECT TO "authenticated" USING (("passer_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."profile_blocks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profile_blocks_delete" ON "public"."profile_blocks" FOR DELETE USING (("blocker_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "profile_blocks_insert" ON "public"."profile_blocks" FOR INSERT WITH CHECK (("blocker_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "profile_blocks_select" ON "public"."profile_blocks" FOR SELECT USING (("blocker_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."profile_photos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profile_photos_delete" ON "public"."profile_photos" FOR DELETE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "profile_photos_insert" ON "public"."profile_photos" FOR INSERT WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "profile_photos_select" ON "public"."profile_photos" FOR SELECT USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "profile_photos"."user_id") AND "p"."is_active" AND "p"."profile_complete")))));



CREATE POLICY "profile_photos_update" ON "public"."profile_photos" FOR UPDATE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."profile_reports" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profile_reports_insert" ON "public"."profile_reports" FOR INSERT WITH CHECK (("reporter_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "profile_reports_select" ON "public"."profile_reports" FOR SELECT USING (("reporter_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."profile_unlocks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profile_unlocks_select" ON "public"."profile_unlocks" FOR SELECT USING (("unlocker_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_select" ON "public"."profiles" FOR SELECT USING ("public"."zyra_can_view_profile"("id"));



CREATE POLICY "profiles_update" ON "public"."profiles" FOR UPDATE USING (("id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."protection_holds" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."saves" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "saves_delete" ON "public"."saves" FOR DELETE USING (("saver_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "saves_insert" ON "public"."saves" FOR INSERT WITH CHECK ((("saver_id" = ( SELECT "auth"."uid"() AS "uid")) AND "public"."zyra_can_match"("saver_id", "saved_id")));



CREATE POLICY "saves_select" ON "public"."saves" FOR SELECT USING (("saver_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."seeker_details" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "seeker_details_insert_own" ON "public"."seeker_details" FOR INSERT WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "seeker_details_select_guardian" ON "public"."seeker_details" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."wali_links" "w"
  WHERE (("w"."seeker_id" = "seeker_details"."user_id") AND ("w"."wali_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("w"."status" = 'active'::"text")))));



CREATE POLICY "seeker_details_select_own" ON "public"."seeker_details" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "seeker_details_update_own" ON "public"."seeker_details" FOR UPDATE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "subscriptions_select" ON "public"."subscriptions" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."timeline_milestones" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "timeline_milestones_select" ON "public"."timeline_milestones" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."timelines" "t"
     JOIN "public"."zyra_my_attempt_participation" "r" ON (("r"."attempt_id" = "t"."attempt_id")))
  WHERE (("t"."id" = "timeline_milestones"."timeline_id") AND (("r"."role" = 'seeker'::"text") OR (("r"."role" = 'guardian'::"text") AND ("r"."attempt_status" <> 'potential'::"text")))))));



ALTER TABLE "public"."timelines" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "timelines_select" ON "public"."timelines" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."zyra_my_attempt_participation" "r"
  WHERE (("r"."attempt_id" = "timelines"."attempt_id") AND (("r"."role" = 'seeker'::"text") OR (("r"."role" = 'guardian'::"text") AND ("r"."attempt_status" <> 'potential'::"text")))))));



ALTER TABLE "public"."unlock_credits" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "unlock_credits_select_own" ON "public"."unlock_credits" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."wali_invites" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wali_invites_insert" ON "public"."wali_invites" FOR INSERT WITH CHECK (("inviter_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "wali_invites_select" ON "public"."wali_invites" FOR SELECT USING (("inviter_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."wali_links" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wali_links_insert" ON "public"."wali_links" FOR INSERT WITH CHECK (("seeker_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "wali_links_select" ON "public"."wali_links" FOR SELECT USING ((("seeker_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("wali_id" = ( SELECT "auth"."uid"() AS "uid"))));



ALTER TABLE "public"."wali_suggestions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wali_suggestions_insert" ON "public"."wali_suggestions" FOR INSERT WITH CHECK ((("wali_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."wali_links" "wl"
  WHERE (("wl"."wali_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("wl"."seeker_id" = "wali_suggestions"."seeker_id") AND ("wl"."status" = 'active'::"text"))))));



CREATE POLICY "wali_suggestions_select" ON "public"."wali_suggestions" FOR SELECT USING ((("wali_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("seeker_id" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "wali_suggestions_update" ON "public"."wali_suggestions" FOR UPDATE USING (("seeker_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."zyra_dev_probe" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."zyra_guard_results" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."zyra_onboarding_questions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."zyra_probe_score" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."zyra_seed_answers" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."messages";



GRANT USAGE ON SCHEMA "private" TO "service_role";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































REVOKE ALL ON FUNCTION "private"."zyra_enforce_personal_request_owner_acceptance"() FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."zyra_generate_personal_code"() FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."zyra_identity_verification_allows_user"("p_user_id" "uuid") FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."zyra_normalize_personal_code"("p_code" "text") FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."zyra_retire_personal_code"() FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."zyra_touch_identity_verification_attempt"() FROM PUBLIC;



REVOKE ALL ON FUNCTION "public"."accept_wali_invite"("p_token" "text", "p_relationship" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."accept_wali_invite"("p_token" "text", "p_relationship" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."accept_wali_invite"("p_token" "text", "p_relationship" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ages_for"("p_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ages_for"("p_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ages_for"("p_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."ages_for_one"("p_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ages_for_one"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ages_for_one"("p_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."auto_designate_main_wali"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."auto_designate_main_wali"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_conversation_started_milestone"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_conversation_started_milestone"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_match_on_mutual_like"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_match_on_mutual_like"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_type" "text", "p_title" "text", "p_body" "text", "p_related_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_type" "text", "p_title" "text", "p_body" "text", "p_related_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."delete_own_account"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."delete_own_account"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_own_account"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."end_journey"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."end_journey"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."end_journey"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."end_journey"("p_match_id" "uuid", "p_reason" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."end_journey"("p_match_id" "uuid", "p_reason" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."end_journey"("p_match_id" "uuid", "p_reason" "text") TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."wali_invites" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."wali_invites" TO "authenticated";
GRANT ALL ON TABLE "public"."wali_invites" TO "service_role";



REVOKE ALL ON FUNCTION "public"."expire_wali_invite_if_due"("p_invite" "public"."wali_invites") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."expire_wali_invite_if_due"("p_invite" "public"."wali_invites") TO "service_role";



REVOKE ALL ON FUNCTION "public"."grant_zyra_one_credits"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."grant_zyra_one_credits"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."guardians_for_unlocked"("p_target" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."guardians_for_unlocked"("p_target" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."guardians_for_unlocked"("p_target" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."has_article9_consent"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."has_article9_consent"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_article9_consent"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."mock_purchase_wali_premium"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mock_purchase_wali_premium"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."mock_purchase_wali_premium"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."mock_set_wali_plan"("p_plan" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mock_set_wali_plan"("p_plan" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mock_set_wali_plan"("p_plan" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."notify_new_message"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."notify_new_message"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."nudge_paused_journey"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."nudge_paused_journey"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."nudge_paused_journey"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."open_family_review"("p_match_id" "uuid", "p_from_stage" "text", "p_to_stage" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."open_family_review"("p_match_id" "uuid", "p_from_stage" "text", "p_to_stage" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."open_family_review"("p_match_id" "uuid", "p_from_stage" "text", "p_to_stage" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."preview_wali_invite"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."preview_wali_invite"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."preview_wali_invite"("p_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."promote_journey_to_active"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."promote_journey_to_active"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."promote_journey_to_active"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."reopen_family_review"("p_review_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."reopen_family_review"("p_review_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reopen_family_review"("p_review_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."request_new_journey"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."request_new_journey"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."resolve_family_review_if_due"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."resolve_family_review_if_due"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."resolve_family_review_if_due"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."respond_to_journey_request"("p_request_id" "uuid", "p_decision" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."respond_to_journey_request"("p_request_id" "uuid", "p_decision" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."restart_journey"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."restart_journey"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."restart_journey"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."resume_journey"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."resume_journey"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."resume_journey"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."score_candidates"("p_candidate_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."score_candidates"("p_candidate_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."score_candidates"("p_candidate_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."seeker_details_for_unlocked"("p_target" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seeker_details_for_unlocked"("p_target" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seeker_details_for_unlocked"("p_target" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."suspend_journey"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."suspend_journey"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."suspend_journey"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."touch_seeker_details"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."touch_seeker_details"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."unlock_balance"("p_tier" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."unlock_balance"("p_tier" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unlock_balance"("p_tier" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."wali_has_wali_one"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."wali_has_wali_one"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."wali_has_wali_one"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."wali_review_decision"("p_review_id" "uuid", "p_decision" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."wali_review_decision"("p_review_id" "uuid", "p_decision" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."wali_review_decision"("p_review_id" "uuid", "p_decision" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_accept_guardian_request"("p_request_id" "uuid", "p_relationship" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_accept_guardian_request"("p_request_id" "uuid", "p_relationship" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_accept_guardian_request"("p_request_id" "uuid", "p_relationship" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_active_journey_cap"("p_user" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_active_journey_cap"("p_user" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_active_journey_count"("p_user" "uuid", "p_exclude" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_active_journey_count"("p_user" "uuid", "p_exclude" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_advance_stage"("p_match_id" "uuid", "p_from_stage" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_advance_stage"("p_match_id" "uuid", "p_from_stage" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_advance_stage"("p_match_id" "uuid", "p_from_stage" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_all_iso639_1"("p" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_all_iso639_1"("p" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_all_iso639_1"("p" "text"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_answers_refresh_onboarding_complete"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_answers_refresh_onboarding_complete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_answers_refresh_onboarding_complete"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_attach_identity_verification_provider_session"("p_user_id" "uuid", "p_provider_code" "text", "p_provider_session_ref" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_attach_identity_verification_provider_session"("p_user_id" "uuid", "p_provider_code" "text", "p_provider_session_ref" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_attempt_participants"("p_attempt" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_attempt_participants"("p_attempt" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_attempt_summary_for_guardian"("p_seeker" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_attempt_summary_for_guardian"("p_seeker" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_attempt_summary_for_guardian"("p_seeker" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_block_exists"("p_other" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_block_exists"("p_other" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_block_exists"("p_other" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_block_user"("p_other" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_block_user"("p_other" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_block_user"("p_other" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_can_continue_journey"("p_a" "uuid", "p_b" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_can_continue_journey"("p_a" "uuid", "p_b" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_can_guardian_link"("p_a" "uuid", "p_b" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_can_guardian_link"("p_a" "uuid", "p_b" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_can_guardian_link"("p_a" "uuid", "p_b" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_can_match"("p_a" "uuid", "p_b" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_can_match"("p_a" "uuid", "p_b" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_can_match"("p_a" "uuid", "p_b" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_can_read_photo_object"("p_object_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_can_read_photo_object"("p_object_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_can_read_photo_object"("p_object_name" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."zyra_can_read_photo_object"("p_object_name" "text") TO "supabase_storage_admin";



REVOKE ALL ON FUNCTION "public"."zyra_can_view_attempt"("p_attempt" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_can_view_attempt"("p_attempt" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_can_view_attempt"("p_attempt" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_can_view_profile"("p_target" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_can_view_profile"("p_target" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_can_view_profile"("p_target" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_cancel_guardian_request"("p_request_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_cancel_guardian_request"("p_request_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_cancel_guardian_request"("p_request_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_ch2_sect_hard_shape_ok"("p" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_ch2_sect_hard_shape_ok"("p" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_ch2_sect_hard_shape_ok"("p" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_ch4_hard_shape_ok"("p" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_ch4_hard_shape_ok"("p" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_ch4_hard_shape_ok"("p" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_clear_main_guardian"("p_wali_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_clear_main_guardian"("p_wali_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_clear_main_guardian"("p_wali_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_compatibility_for_plus"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_compatibility_for_plus"("p_match_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."zyra_confirm_milestone"("p_attestation_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_confirm_milestone"("p_attestation_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_confirm_milestone"("p_attestation_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_counterpart_card"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_counterpart_card"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_counterpart_card"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_create_first_attempt"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_create_first_attempt"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_create_profile"("p_role" "text", "p_first_name" "text", "p_gender" "text", "p_dob" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_create_profile"("p_role" "text", "p_first_name" "text", "p_gender" "text", "p_dob" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_create_profile"("p_role" "text", "p_first_name" "text", "p_gender" "text", "p_dob" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dashboard_updates"("p_limit" integer, "p_cursor_occurred_at" timestamp with time zone, "p_cursor_class_key" "text", "p_cursor_source_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dashboard_updates"("p_limit" integer, "p_cursor_occurred_at" timestamp with time zone, "p_cursor_class_key" "text", "p_cursor_source_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dashboard_updates"("p_limit" integer, "p_cursor_occurred_at" timestamp with time zone, "p_cursor_class_key" "text", "p_cursor_source_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_debug_grant_credits"("p_tier" "text", "p_count" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_debug_grant_credits"("p_tier" "text", "p_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_debug_grant_credits"("p_tier" "text", "p_count" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_decline_guardian_request"("p_request_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_decline_guardian_request"("p_request_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_decline_guardian_request"("p_request_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_decline_wali_invite"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_decline_wali_invite"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_decline_wali_invite"("p_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_delete_my_unstarted_identity_verification_attempt"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_delete_my_unstarted_identity_verification_attempt"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_delete_my_unstarted_identity_verification_attempt"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_counterpart_complete"("p_match_id" "uuid", "p_question_ids" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_counterpart_complete"("p_match_id" "uuid", "p_question_ids" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_counterpart_complete"("p_match_id" "uuid", "p_question_ids" "text"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_guardians_on_decided"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_guardians_on_decided"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_guardians_on_decided"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_reset_account"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_reset_account"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_reset_account"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_rewind_journey"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_rewind_journey"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_rewind_journey"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_seed_journey"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_seed_journey"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_seed_journey"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_set_compatibility"("p_match_id" "uuid", "p_score" numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_set_compatibility"("p_match_id" "uuid", "p_score" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_set_compatibility"("p_match_id" "uuid", "p_score" numeric) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_set_counterpart_reveal"("p_match_id" "uuid", "p_revealed" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_set_counterpart_reveal"("p_match_id" "uuid", "p_revealed" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_set_counterpart_reveal"("p_match_id" "uuid", "p_revealed" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_set_guardian_suggestions"("p_count" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_set_guardian_suggestions"("p_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_set_guardian_suggestions"("p_count" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_set_guardians_on_decided"("p_count" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_set_guardians_on_decided"("p_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_set_guardians_on_decided"("p_count" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_set_journey_stage"("p_match_id" "uuid", "p_stage" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_set_journey_stage"("p_match_id" "uuid", "p_stage" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_set_journey_stage"("p_match_id" "uuid", "p_stage" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_set_plus_unlock"("p_other_id" "uuid", "p_has" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_set_plus_unlock"("p_other_id" "uuid", "p_has" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_set_plus_unlock"("p_other_id" "uuid", "p_has" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_dev_set_seeker_plan"("p_plan" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_dev_set_seeker_plan"("p_plan" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_dev_set_seeker_plan"("p_plan" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_end_match_internal"("p_match_id" "uuid", "p_ended_by" "uuid", "p_reason" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_end_match_internal"("p_match_id" "uuid", "p_ended_by" "uuid", "p_reason" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_enforce_guardian_link_allowed"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_enforce_guardian_link_allowed"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_enforce_guardian_link_allowed"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_enforce_one_active_attempt"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_enforce_one_active_attempt"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_enforce_one_active_match"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_enforce_one_active_match"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_expire_due_journey_requests"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_expire_due_journey_requests"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_expire_due_journey_requests"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_expire_due_wali_invites"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_expire_due_wali_invites"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_expire_due_wali_invites"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_guardian_activity"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_guardian_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_guardian_activity"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_guardian_history_consent"("p_guardian" "uuid", "p_enabled" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_guardian_history_consent"("p_guardian" "uuid", "p_enabled" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_guardian_history_consent"("p_guardian" "uuid", "p_enabled" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_guardian_journey_access"("p_guardian" "uuid", "p_attempt" "uuid", "p_enabled" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_guardian_journey_access"("p_guardian" "uuid", "p_attempt" "uuid", "p_enabled" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_guardian_journey_access"("p_guardian" "uuid", "p_attempt" "uuid", "p_enabled" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_hold_blocks"("p_restricted" "uuid", "p_protected" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_hold_blocks"("p_restricted" "uuid", "p_protected" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_journey_busy_flags"("p_match_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_journey_busy_flags"("p_match_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_journey_busy_flags"("p_match_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_journey_compatibility_state"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_journey_compatibility_state"("p_match_id" "uuid") TO "authenticated";



GRANT ALL ON FUNCTION "public"."zyra_light_weight"("p_light" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_light_weight"("p_light" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_like_clears_others"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_like_clears_others"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_main_guardian_history_consent"("p_enabled" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_main_guardian_history_consent"("p_enabled" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_main_guardian_history_consent"("p_enabled" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_mark_suggestions_seen"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_mark_suggestions_seen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_mark_suggestions_seen"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_match_ending"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_match_ending"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_match_ending"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_may_request_new_journey"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_may_request_new_journey"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_may_request_new_journey_ids"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_may_request_new_journey_ids"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_milestone_attestation_state"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_milestone_attestation_state"("p_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_milestone_attestation_state"("p_match_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_my_guardian_requests"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_my_guardian_requests"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_my_guardian_requests"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_my_identity_verification_allows_active_journey"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_my_identity_verification_allows_active_journey"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_my_identity_verification_allows_active_journey"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_my_identity_verification_allows_app"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_my_identity_verification_allows_app"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_my_identity_verification_allows_app"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_my_identity_verification_state"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_my_identity_verification_state"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_my_identity_verification_state"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_my_onboarding_progress"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_my_onboarding_progress"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_my_onboarding_progress"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_my_personal_code"("p_role_context" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_my_personal_code"("p_role_context" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_my_personal_code"("p_role_context" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_my_safety_cases"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_my_safety_cases"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_my_safety_cases"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_normalise_profile_identity"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_normalise_profile_identity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_normalise_profile_identity"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_notification_category"("p_type" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_notification_category"("p_type" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_notification_preferences"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_notification_preferences"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_notification_preferences"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_onboarding_complete"("p_user" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_onboarding_complete"("p_user" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_onboarding_complete"("p_user" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_onboarding_data_complete"("p_user" "uuid", "p_gender" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_onboarding_data_complete"("p_user" "uuid", "p_gender" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_onboarding_data_complete"("p_user" "uuid", "p_gender" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_onboarding_missing"("p_user" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_onboarding_missing"("p_user" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_onboarding_missing"("p_user" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_pass_clears_others"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_pass_clears_others"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_preview_personal_code"("p_code" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_preview_personal_code"("p_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_preview_personal_code"("p_code" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_profiles_set_onboarding_complete"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_profiles_set_onboarding_complete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_profiles_set_onboarding_complete"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_propose_milestone"("p_match_id" "uuid", "p_type" "text", "p_occurred_on" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_propose_milestone"("p_match_id" "uuid", "p_type" "text", "p_occurred_on" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_propose_milestone"("p_match_id" "uuid", "p_type" "text", "p_occurred_on" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."zyra_question_is_due"("p_qid" "text", "p_gender" "text", "p_answers" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_question_is_due"("p_qid" "text", "p_gender" "text", "p_answers" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_record_identity_verification_consent"("p_consent_version" "text", "p_granted" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_record_identity_verification_consent"("p_consent_version" "text", "p_granted" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_record_identity_verification_consent"("p_consent_version" "text", "p_granted" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_record_identity_verification_provider_result"("p_provider_code" "text", "p_provider_session_ref" "text", "p_result" "text", "p_duplicate_review_required" boolean, "p_provider_event_ref_hash" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_record_identity_verification_provider_result"("p_provider_code" "text", "p_provider_session_ref" "text", "p_result" "text", "p_duplicate_review_required" boolean, "p_provider_event_ref_hash" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_record_journey_milestone"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_record_journey_milestone"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_record_journey_milestone"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_refresh_onboarding_complete"("p_user" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_refresh_onboarding_complete"("p_user" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_refresh_onboarding_complete"("p_user" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_remove_guardian"("p_wali_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_remove_guardian"("p_wali_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_remove_guardian"("p_wali_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_request_guardian_link"("p_code" "text", "p_relationship" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_request_guardian_link"("p_code" "text", "p_relationship" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_request_guardian_link"("p_code" "text", "p_relationship" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_reset_profile"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_reset_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_reset_profile"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_reset_search"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_reset_search"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_reset_search"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_reveal_journey_compatibility"("p_match_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_reveal_journey_compatibility"("p_match_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."zyra_revoke_wali_invite"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_revoke_wali_invite"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_revoke_wali_invite"("p_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_rotate_my_personal_code"("p_role_context" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_rotate_my_personal_code"("p_role_context" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_rotate_my_personal_code"("p_role_context" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_save_clears_others"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_save_clears_others"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_sect_code"("p_label" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_sect_code"("p_label" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_set_attempt_from_match"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_set_attempt_from_match"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_set_main_guardian"("p_wali_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_set_main_guardian"("p_wali_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_set_main_guardian"("p_wali_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_set_notification_preference"("p_category" "text", "p_enabled" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_set_notification_preference"("p_category" "text", "p_enabled" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_set_notification_preference"("p_category" "text", "p_enabled" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_set_profile_complete"("p_complete" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_set_profile_complete"("p_complete" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_set_profile_complete"("p_complete" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_submit_feedback"("p_category" "text", "p_message" "text", "p_app_version" "text", "p_platform" "text", "p_screen" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_submit_feedback"("p_category" "text", "p_message" "text", "p_app_version" "text", "p_platform" "text", "p_screen" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_submit_feedback"("p_category" "text", "p_message" "text", "p_app_version" "text", "p_platform" "text", "p_screen" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_unblock_user"("p_other" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_unblock_user"("p_other" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_unblock_user"("p_other" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."zyra_unlock_profile"("p_target" "uuid", "p_tier" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."zyra_unlock_profile"("p_target" "uuid", "p_tier" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."zyra_unlock_profile"("p_target" "uuid", "p_tier" "text") TO "service_role";


















GRANT SELECT,INSERT,UPDATE ON TABLE "private"."identity_verification_attempts" TO "service_role";



GRANT SELECT,INSERT ON TABLE "private"."identity_verification_event_receipts" TO "service_role";



GRANT SELECT,INSERT,DELETE ON TABLE "private"."zyra_personal_code_attempts" TO "service_role";



GRANT SELECT,USAGE ON SEQUENCE "private"."zyra_personal_code_attempts_id_seq" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "private"."zyra_personal_codes" TO "service_role";



GRANT SELECT,INSERT ON TABLE "private"."zyra_retired_personal_code_hashes" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."app_feedback" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."app_feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."app_feedback" TO "service_role";



GRANT SELECT("id") ON TABLE "public"."app_feedback" TO "authenticated";



GRANT SELECT("category") ON TABLE "public"."app_feedback" TO "authenticated";



GRANT SELECT("message") ON TABLE "public"."app_feedback" TO "authenticated";



GRANT SELECT("created_at") ON TABLE "public"."app_feedback" TO "authenticated";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."consents" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."consents" TO "authenticated";
GRANT ALL ON TABLE "public"."consents" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."conversations" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";



GRANT ALL ON TABLE "public"."guardian_journey_history_consents" TO "service_role";



GRANT ALL ON TABLE "public"."journey_attempts" TO "service_role";



GRANT ALL ON TABLE "public"."journey_compatibility" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_family_answers" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_family_answers" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_family_answers" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_family_review_responses" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_family_review_responses" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_family_review_responses" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_family_reviews" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_family_reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_family_reviews" TO "service_role";



GRANT ALL ON TABLE "public"."journey_guardian_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."journey_milestone_attestations" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_phase_answers" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_phase_answers" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_phase_answers" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_phase_checkpoints" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_phase_checkpoints" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_phase_checkpoints" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_phase_ratings" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,MAINTAIN,UPDATE ON TABLE "public"."journey_phase_ratings" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_phase_ratings" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_requests" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_salams" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."journey_salams" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_salams" TO "service_role";



GRANT ALL ON TABLE "public"."journey_stage_checkpoints" TO "service_role";
GRANT SELECT ON TABLE "public"."journey_stage_checkpoints" TO "authenticated";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."likes" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,MAINTAIN ON TABLE "public"."likes" TO "authenticated";
GRANT ALL ON TABLE "public"."likes" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."matches" TO "anon";
GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."matches" TO "authenticated";
GRANT ALL ON TABLE "public"."matches" TO "service_role";



GRANT SELECT("id") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("seeker_a_id") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("seeker_b_id") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("status") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("ended_at") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("created_at") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("journey_stage") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("suspended_by") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("suspended_at") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("ended_by") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("pause_nudged_at") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("also_paused_by") ON TABLE "public"."matches" TO "authenticated";



GRANT SELECT("also_paused_at") ON TABLE "public"."matches" TO "authenticated";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."messages" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON TABLE "public"."notification_preferences" TO "service_role";
GRANT SELECT ON TABLE "public"."notification_preferences" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."notification_preferences_seq_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."notification_preferences_seq_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."notification_preferences_seq_seq" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."notifications" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN,UPDATE ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."onboarding_answers" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN,UPDATE ON TABLE "public"."onboarding_answers" TO "authenticated";
GRANT ALL ON TABLE "public"."onboarding_answers" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."passes" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,MAINTAIN ON TABLE "public"."passes" TO "authenticated";
GRANT ALL ON TABLE "public"."passes" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profile_blocks" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profile_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_blocks" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profile_photos" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,MAINTAIN,UPDATE ON TABLE "public"."profile_photos" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_photos" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profile_reports" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profile_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_reports" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profile_unlocks" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profile_unlocks" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_unlocks" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profiles" TO "anon";
GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT SELECT("id") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("role") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("first_name"),UPDATE("first_name") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("gender") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("location_text"),UPDATE("location_text") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("bio"),UPDATE("bio") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("is_active"),UPDATE("is_active") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("profile_complete") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("created_at") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("updated_at") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("surname_line"),UPDATE("surname_line") ON TABLE "public"."profiles" TO "authenticated";



GRANT SELECT("first_published_at") ON TABLE "public"."profiles" TO "authenticated";



GRANT ALL ON TABLE "public"."protection_holds" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."saves" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,MAINTAIN ON TABLE "public"."saves" TO "authenticated";
GRANT ALL ON TABLE "public"."saves" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."seeker_details" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN,UPDATE ON TABLE "public"."seeker_details" TO "authenticated";
GRANT ALL ON TABLE "public"."seeker_details" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."subscriptions" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."timeline_milestones" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."timeline_milestones" TO "authenticated";
GRANT ALL ON TABLE "public"."timeline_milestones" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."timelines" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."timelines" TO "authenticated";
GRANT ALL ON TABLE "public"."timelines" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."unlock_credits" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."unlock_credits" TO "authenticated";
GRANT ALL ON TABLE "public"."unlock_credits" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."wali_links" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."wali_links" TO "authenticated";
GRANT ALL ON TABLE "public"."wali_links" TO "service_role";



GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."wali_suggestions" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."wali_suggestions" TO "authenticated";
GRANT ALL ON TABLE "public"."wali_suggestions" TO "service_role";



GRANT UPDATE("status") ON TABLE "public"."wali_suggestions" TO "authenticated";



GRANT UPDATE("responded_at") ON TABLE "public"."wali_suggestions" TO "authenticated";



GRANT ALL ON TABLE "public"."zyra_attempt_participant_rows" TO "service_role";



GRANT ALL ON TABLE "public"."zyra_data_ownership" TO "service_role";



GRANT ALL ON TABLE "public"."zyra_dev_probe" TO "service_role";



GRANT ALL ON TABLE "public"."zyra_guard_results" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."zyra_my_attempt_participation" TO "authenticated";
GRANT ALL ON TABLE "public"."zyra_my_attempt_participation" TO "service_role";



GRANT ALL ON TABLE "public"."zyra_onboarding_questions" TO "service_role";



GRANT ALL ON TABLE "public"."zyra_probe_score" TO "service_role";



GRANT ALL ON TABLE "public"."zyra_seed_answers" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































