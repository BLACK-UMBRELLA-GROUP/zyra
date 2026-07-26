-- Security hardening (Fable review, 2026-07-19).
--
-- 1. accept_wali_invite requires auth.uid() internally, so its anon
--    EXECUTE grant was pure attack surface. preview_wali_invite has no
--    auth check and returns the inviter's first name for any valid
--    token — restricting it to signed-in users closes an anonymous
--    name-probing oracle. Both remain callable by `authenticated`,
--    which is the only way the app actually calls them (both screens
--    sit behind sign-in). If a pre-auth invite deep-link flow is ever
--    built, re-grant anon on preview_wali_invite deliberately then.
revoke execute on function public.accept_wali_invite(text) from anon;
revoke execute on function public.preview_wali_invite(text) from anon;

-- 2. wali_links UPDATE had no WITH CHECK and full-row column scope:
--    since the new row only had to satisfy (seeker_id = me OR
--    wali_id = me), a Wali could rewrite an existing link's seeker_id
--    to point at ANY Seeker — an active guardianship link nobody
--    consented to, bypassing the invite mechanism entirely. Client
--    updates are now restricted to `status` only (the only column the
--    app has any reason to change). Same pattern applied to
--    wali_suggestions (status + responded_at). accept_wali_invite is
--    SECURITY DEFINER and unaffected.
revoke update on table public.wali_links from anon, authenticated;
grant update (status) on table public.wali_links to authenticated;
revoke update on table public.wali_suggestions from anon, authenticated;
grant update (status, responded_at) on table public.wali_suggestions to authenticated;

-- 3. Invite tokens were md5(random()) — random() is not
--    cryptographically secure and md5 output is predictable enough to
--    matter for a linkage mechanism. Switch to pgcrypto's
--    gen_random_bytes. Same 8-char uppercase UX. (Charset is hex —
--    same as before — so no client-side change.)
alter table public.wali_invites
  alter column token set default upper(encode(extensions.gen_random_bytes(4), 'hex'));
