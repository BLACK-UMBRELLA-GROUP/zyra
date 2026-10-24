-- OA-ZYRA-305 / F01 exact second-application refusal postcheck.
-- Run only AFTER the host runner has proved that the exact canonical candidate
-- exited nonzero with "F01 precondition: account/reference columns drifted".
-- This assertion alone cannot classify the preceding process exit reason.
-- Persistent local-only proof objects are retained in the disposable database.
\set ON_ERROR_STOP on

do $postcheck$
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f01_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f01_local_replay', true)
       is distinct from 'enabled'
     or pg_catalog.to_regclass('zyra_f01_refusal_fixture.before') is null
     or pg_catalog.to_regprocedure('zyra_f01_refusal_fixture.metadata()') is null
     or (select count(*) from zyra_f01_refusal_fixture.before) <> 1 then
    raise exception 'F01 refusal postcheck requires its armed local precheck';
  end if;
  if (select value from zyra_f01_refusal_fixture.before)
       is distinct from zyra_f01_refusal_fixture.metadata()
     or exists (select 1 from public.profile_reports)
     or exists (select 1 from public.profiles)
     or exists (select 1 from auth.users)
     or exists (select 1 from storage.objects) then
    raise exception 'F01FAIL second candidate refusal changed metadata or fixture rows';
  end if;
  raise notice 'F01PASS exact second-candidate refusal leaves catalog/ACL/RLS/RPC unchanged';
end;
$postcheck$;
