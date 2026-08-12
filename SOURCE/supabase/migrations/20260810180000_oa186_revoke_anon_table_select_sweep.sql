-- OA-ZYRA-186 · take TABLE SELECT away from 'anon', across the board.
-- Founder decision 2026-08-10. The read-side twin of OA-ZYRA-168.
--
-- 29 public tables granted SELECT to anon — onboarding_answers,
-- seeker_details, messages, notifications, profile_reports, wali_links among
-- them. Nobody wrote those grants; they are Supabase's default
-- `grant select on all tables in public to anon`. RLS denied underneath, so
-- the privilege was inert. Defence in depth: the day a table ships with a
-- policy broader than intended, this grant is the difference between a bug
-- and a breach.
--
-- CHECKED BEFORE REVOKING: exactly one function was anon-executable
-- (zyra_ch4_hard_shape_ok, a pure jsonb validator reading no tables), so
-- nothing anon can reach depended on a table grant.
--
-- SWEPT, NOT PATCHED — fixing 1 of 29 would make the register read resolved
-- while 28 remained.
REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM anon;

-- Without this the next migration-created table inherits the grant and the
-- sweep rots. NOTE: this only governs objects created by `postgres`, which is
-- what migrations run as. supabase_admin keeps its own default ACL that still
-- grants anon SELECT, and that role is not ours to change — anything created
-- as supabase_admin needs revoking by hand.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM anon;
