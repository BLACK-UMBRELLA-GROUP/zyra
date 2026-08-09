-- APPLIED LIVE 2026-08-08, version 20260808153306.
-- Surface how many Seekers a Guardian already holds, at the moment
-- someone is deciding whether to accept them. Founder-approved 2026-08-08.
--
-- WHY THIS SURFACE: preview_wali_invite() is literally the "considering
-- them" moment. There is no Guardian-browsing surface in the product and
-- there should not be one (I10), so this is where the fact belongs.
--
-- WHY A COUNT RATHER THAN A CAP: every cap refuses somebody legitimate.
-- Five turns away the uncle who genuinely looks after four nieces; fifty
-- is not a cap; review needs an admin that does not exist. The number
-- costs an honest Guardian nothing and a catalogue-builder everything,
-- and puts the judgement with the person whose data it is.
--
-- ACTIVE LINKS ONLY, deliberately: a present-tense disclosure, not a
-- permanent restriction, so I1 does not apply. Contrast Tier-1 in
-- zyra_can_match, which DOES count retired links precisely because it
-- anchors a permanent consequence.
--
-- DROP + CREATE, not CREATE OR REPLACE: Postgres refuses to change OUT
-- parameters in place. Safe for the client — the Dart reads the result by
-- key, so an added column is ignored until asked for. (It is now asked
-- for: previewInvite() returns 'wardCount'.)

drop function if exists public.preview_wali_invite(text);

create function public.preview_wali_invite(p_token text)
 returns table(inviter_first_name text, inviter_role text, invite_status text,
               inviter_ward_count integer)
 language plpgsql security definer set search_path to 'public'
as $function$
DECLARE v_invite wali_invites%ROWTYPE; v_status TEXT;
BEGIN
  SELECT * INTO v_invite FROM wali_invites wi WHERE wi.token = p_token;
  IF NOT FOUND THEN RETURN; END IF;
  v_status := expire_wali_invite_if_due(v_invite);
  RETURN QUERY
  SELECT p.first_name, v_invite.inviter_role, v_status,
         (select count(distinct wl.seeker_id)::int from wali_links wl
           where wl.wali_id = v_invite.inviter_id and wl.status = 'active')
  FROM profiles p WHERE p.id = v_invite.inviter_id;
END; $function$;

revoke execute on function public.preview_wali_invite(text) from public, anon;
grant  execute on function public.preview_wali_invite(text) to authenticated;

comment on function public.preview_wali_invite(text) is
  'Invite preview shown before acceptance. Returns inviter_ward_count as '
  'of 2026-08-08, so a Seeker can see whether they are being asked to '
  'join a family or a collection. Chosen over a hard cap because every '
  'cap refuses somebody legitimate. Active links only.';

-- VERIFIED 2026-08-08, 6/6: preview returns the inviter; ward count
-- matches reality (10 for the seeded Guardian who holds 10); existing
-- fields still returned; anon holds no EXECUTE.
