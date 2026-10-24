# TO: Fable / Architecture Reviewer
# FROM: Codex / Lead Architect
# SUBJECT: 047 complete — OA-ZYRA-281 40 baselines promoted; OA-ZYRA-282 guardian server truth staged only

## 1 · Outcome

1. **OA-ZYRA-281 baseline promotion COMPLETE:** all 40/40 Founder-accepted
   candidate variants are versioned as `OA-ZYRA-281-v1`, copied byte-exact
   into the protected approved directory, and recorded in both approved
   manifests with complete governance metadata. The first real approved-pixel
   comparison passed 248/248.
2. **OA-ZYRA-282 workstream A STAGED ONLY:** Supabase CLI created one migration,
   `20260830183151_oa282_guardian_server_truth_security.sql`. It contains
   exactly the two authorised function replacements. It has not been applied.
3. The Guardian UI rebuild, Dashboard objects, `score_candidates`, insight
   stores, and all other schema objects remain untouched. No git action.

## 2 · Short baseline-promotion confirmation

1. Founder-approved candidates: **40**.
2. Approved PNGs promoted: **40**; duplicate IDs: **0**; missing/hash-mismatched
   PNGs: **0**; total bytes: **2,328,325**.
3. Runtime approved manifest: **40** rows; governed baseline manifest: **40**
   rows; the two baseline arrays are byte-semantically identical after
   canonical JSON sorting (`42d8dd71…` for each array).
4. OA candidate manifest: **40 approved / 0 pending**;
   `device_acceptance_pending=false`; active version `OA-ZYRA-281-v1`.
5. OA manifest SHA-256 after promotion:
   `c17209b7365cca03488774f9ed7e3ef8031cea3ff4ae4afa0084f7777600c597`.

## 3 · True pre-file snapshots and pre/post hashes

True pre-files were copied before edits to:

`/private/tmp/zyra-047-pre.nnqm7v/`

| File | True pre-edit SHA-256 | Post-edit SHA-256 |
|---|---|---|
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json` | `e57ce8b5173b97afc4f5fc4dbe06532e4239adc6ccfcd7d3abd42f2082799389` | `c17209b7365cca03488774f9ed7e3ef8031cea3ff4ae4afa0084f7777600c597` |
| `SYSTEM/RESOURCES/UI_GATE/BASELINES/manifest.json` | `0b7e7e2fcce8e76ef0195697d52ca497c355ba4b3fa17d0346e0f9cb19df78dc` | `56cd7f5f3c5f64d044d552a1b013c997d42a8b5e9dc9d06f09959c7b69f17484` |
| `SOURCE/test/visual/approved/manifest.json` | `360f72d58a7cd1a6b0a8c4c4206c8a03a22f5089aca2f4dbc5da479d7eaa2ce1` | `23547aafd1a58d5210a8f6438cd7d680aab48fdc9ef61bb8d87bb33d5863024e` |
| `SOURCE/test/visual/approved/oa-zyra-281-v1/*.png` | absent — initial approved version, no prior baseline to archive | 40 files, each SHA-256 equal to its accepted candidate source |
| `SOURCE/supabase/migrations/20260830183151_oa282_guardian_server_truth_security.sql` | absent — created by `supabase migration new` | `2c85d4293d7083953ec63fae3ad877b97bcc5e44724bdd4fd1929a292aaec186` |
| `SOURCE/test/zyra_guardian_server_truth_migration_test.dart` | absent | `4a411a4a0c944133e7116f3d25ed3e0995cf733aaedf5f0e710e0b47b4756c45` |
| `SOURCE/supabase/tests/zyra_oa282_guardian_server_truth_post_apply.sql` | absent | `39139651fe5de45ef870983a5053b3aad12f1b55dab78cb2d56c67964b1fe8c1` |

The two applied-definition source files and the existing guard suite were
snapshotted for provenance and not edited:

| Untouched reference | Snapshot/current SHA-256 |
|---|---|
| `20260806112016_oa156_stage3a_unified_authorisation.sql` | `29af445e7dfd5d6307b9abf2c137afddd1943ce360ce59ea5f246a17ef3279dd` |
| `20260810140337_dr136_a_seeker_may_not_leave_themselves_without_a_guardian.sql` | `3943a190a7cba9209a4103ffe4be1bf992cba50daa635469139b1183aba37a4f` |
| `supabase/tests/zyra_guard_suite.sql` | `3b3b3c29f59bea45c891f25070f6929bc5f1801c74d8f872fab3ff8069d1b9ed` |

## 4 · Staged-only proof

Live read-only probe after all local work:

- `supabase_migrations.schema_migrations` rows for `20260830183151`: **0**.
- Live summary still stores `search_path=public`, has no `is_main` predicate,
  and has no potential-attempt exclusion.
- Live removal function still contains the old `end or pause the Journey`
  hint and does not contain the replacement hint.

Therefore the staged migration is dormant. No DDL or test scenario was run on
the live project. A read-only `PREPARE`/`DEALLOCATE` validated the new summary
SELECT against the live schema without executing it.

## 5 · Exact pre-state SQL definitions

### 5.1 `zyra_attempt_summary_for_guardian` — live pre-state

```sql
CREATE OR REPLACE FUNCTION public.zyra_attempt_summary_for_guardian(p_seeker uuid)
 RETURNS TABLE(attempt_id uuid, started_at timestamp with time zone, ended_at timestamp with time zone, ended boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select a.id, a.started_at, a.ended_at, (a.status = 'ended')
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  where p_seeker in (m.seeker_a_id, m.seeker_b_id)
    -- caller must be an ACTIVE Guardian of that Seeker
    and exists (
      select 1 from public.wali_links w
      where w.seeker_id = p_seeker
        and w.wali_id   = (select auth.uid())
        and w.status    = 'active'
    );
$function$
```

### 5.2 `zyra_remove_guardian` — live pre-state

```sql
CREATE OR REPLACE FUNCTION public.zyra_remove_guardian(p_wali_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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

  -- NEW — DR-ZYRA-136 / OA-ZYRA-173.
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
      using hint = 'Your Journey needs a Guardian on your side. Link someone '
                   'else first, or end or pause the Journey.';
  end if;

  update public.wali_links
     set status = 'removed', is_main = false
   where seeker_id = v_me and wali_id = p_wali_id;

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$function$
```

## 6 · Exact staged post-state SQL definitions

### 6.1 `zyra_attempt_summary_for_guardian` — staged post-state

```sql
create or replace function public.zyra_attempt_summary_for_guardian(
  p_seeker uuid
)
returns table (
  attempt_id uuid,
  started_at timestamptz,
  ended_at timestamptz,
  ended boolean
)
language sql
stable
security definer
set search_path = ''
as $function$
  with caller as materialized (
    select (select auth.uid()) as user_id
  )
  select
    a.id,
    a.started_at,
    a.ended_at,
    (a.status = 'ended')
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  cross join caller c
  where c.user_id is not null
    and a.status <> 'potential'
    and p_seeker in (m.seeker_a_id, m.seeker_b_id)
    and exists (
      select 1
      from public.wali_links w
      where w.seeker_id = p_seeker
        and w.wali_id = c.user_id
        and w.status = 'active'
        and w.is_main is true
    );
$function$;

comment on function public.zyra_attempt_summary_for_guardian(uuid) is
  'DR-ZYRA-224 F6 / OA-ZYRA-282. CALLER-BOUND, ACTIVE MAIN-GUARDIAN ONLY. '
  'Potential attempts are excluded. Returns only the opaque attempt identity, '
  'start/end timestamps, and whether the attempt ended; never stage, reason, '
  'notes, counterpart identity, or another Guardian''s observations.';

revoke execute on function public.zyra_attempt_summary_for_guardian(uuid)
  from public, anon;
grant execute on function public.zyra_attempt_summary_for_guardian(uuid)
  to authenticated, service_role;
```

### 6.2 `zyra_remove_guardian` — staged post-state

```sql
CREATE OR REPLACE FUNCTION public.zyra_remove_guardian(p_wali_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
$function$;
```

Static comparison redacts only the two hint literals and then requires the
entire pre/post `zyra_remove_guardian` executable definitions to be equal.
That test passes: enforcement logic is unchanged.

## 7 · Catalog identity and execute ACL — pre vs staged post

| Function | State | Owner | Definer | Volatility | Stored search_path | EXECUTE |
|---|---|---|---|---|---|---|
| `zyra_attempt_summary_for_guardian(uuid)` | live pre | `postgres` | true | STABLE | `public` | `postgres`, `authenticated`, `service_role`; no PUBLIC/anon entry |
| same | staged post | preserved `postgres` | true | STABLE | empty (`search_path=`) | explicit PUBLIC + anon revoke; authenticated + service_role grant; owner implicit |
| `zyra_remove_guardian(uuid)` | live pre | `postgres` | true | VOLATILE | `public` | `postgres`, `authenticated`, `service_role`; no PUBLIC/anon entry |
| same | staged post | preserved `postgres` | true | VOLATILE | `public` unchanged | unchanged by `CREATE OR REPLACE` |

The post-apply harness asserts owner, `prosecdef`, `provolatile`, exact
`proconfig`, absence of PUBLIC/anon EXECUTE, and presence of authenticated/
service-role EXECUTE before running any behavioural cases.

## 8 · Returned fields and justification

| Field | Kept? | Justification |
|---|---:|---|
| `attempt_id` | yes | Opaque stable identity for list keys and for routing a future Main-Guardian workspace to the governed attempt; it reveals no stage, person, reason, or note. |
| `started_at` | yes | The governed summary says when the Journey began; this is the minimum chronological fact needed to distinguish and order multiple authorised attempts. |
| `ended_at` | yes | The governed summary says when a historical Journey ended; nullable for ongoing/paused attempts. |
| `ended` | yes | Explicit governed lifecycle fact, avoiding client inference from timestamp nullability; pinned false for active/paused and true for ended. |

Nothing was added. Stage, pause actor, ending reason/note, counterpart identity,
Guardian identity, review data, messages, and observations remain absent.

## 9 · Exact authority predicate

```sql
where c.user_id is not null
  and a.status <> 'potential'
  and p_seeker in (m.seeker_a_id, m.seeker_b_id)
  and exists (
    select 1
    from public.wali_links w
    where w.seeker_id = p_seeker
      and w.wali_id = c.user_id
      and w.status = 'active'
      and w.is_main is true
  )
```

`c.user_id` has exactly one source: `(select auth.uid())`. `p_seeker` selects
the ward only; there is no caller/Guardian parameter. Null caller returns no
rows even before ACL enforcement.

## 10 · Hint correction

```diff
- Your Journey needs a Guardian on your side. Link someone else first, or end or pause the Journey.
+ An active or paused Journey requires you to keep a Guardian. Assign another Guardian where possible, or end the Journey through the governed flow before removing this one.
```

The separate `main_guardian_must_be_reassigned` branch and every enforcement
predicate/write remain unchanged.

## 11 · Static and post-apply test package

`test/zyra_guardian_server_truth_migration_test.dart` pins:

1. exactly two authorised replacements;
2. exact four-field return shape;
3. auth-derived/null-safe/ward-bound Main-only predicate;
4. potential exclusion without active-only or ended-only narrowing;
5. STABLE definer, empty path, fully qualified relations, no writes/dynamic SQL;
6. PUBLIC/anon revokes and authenticated/service-role grants;
7. hint-only equality for `zyra_remove_guardian`; and
8. all twelve named direct-call cases in the transaction-rollback SQL harness.

`supabase/tests/zyra_oa282_guardian_server_truth_post_apply.sql` is explicitly
post-apply only. It first proves catalog identity/ACL, then runs **12 distinct
direct calls**: unauthenticated; unrelated authenticated; Seeker; Main;
Additional; dual-role; removed; inactive; potential; active; paused; ended.
It uses stable seeded actors, isolates its scenario in a transaction, and ends
with `ROLLBACK`. It has not been run because the migration is not applied.

## 12 · Query-shape evidence

The new summary SELECT was parsed/planned read-only against live Postgres 17:

- top node: `Nested Loop`;
- estimated total cost: `1.14..3.58`;
- estimated rows: `1`;
- caller is an InitPlan through the materialized one-row CTE;
- current tables are tiny, so the planner correctly chooses sequential scans.

No index/schema change is justified by current evidence, and 044 authorises no
third schema object. Re-measure with `EXPLAIN (ANALYZE, BUFFERS)` only after
the Founder apply GO when the real post-state exists.

## 13 · Rollback/correction strategy

1. **Before apply:** this migration is staged and may be corrected in place
   only under a reviewed revision brief; no history row exists.
2. **After apply:** never edit the applied file. A separate Founder-authorised
   forward correction migration restores the exact §5 definitions and their
   pre ACL/search-path state. The full restore SQL is preserved above, and the
   true applied-source files/hashes are preserved in §3.
3. The post-apply matrix must run after any apply or correction. A failing
   Additional/null/ACL case blocks release rather than relying on client hiding.

## 14 · Verification results and one scoped challenge

| Check | Result |
|---|---|
| Candidate SHA-256 verification | PASS · 40/40 |
| Approved-manifest metadata/uniqueness | PASS · 40/40 · 40 unique IDs/paths |
| First approved pixel comparison | PASS · 248/248 |
| Focused OA-ZYRA-282 static suite | PASS · 7/7 |
| Full Flutter suite | PASS · 731/731 |
| `flutter analyze --no-pub` | PASS · no issues |
| `python3 tools/zyra_check.py --quiet` | PASS |
| `python3 -m unittest tools/test_zyra_check.py` | PASS · 1/1 |
| Summary SQL read-only PREPARE | PASS |
| Live staged-only probe | PASS · history row 0; both live definitions unchanged |

**Scoped challenge, not silently repaired:** repository-wide Dart format audit
still reports one pre-existing formatting-only difference in
`test/zyra_dashboard_updates_migration_test.dart` (one multiline `expect`
would collapse to one line). That file is outside 047/044, remains at its
041 Fable-verified hash
`bbbb0c03e7c9977215c741d316574be1dd9bec717f51829f135f362fd33b45c4`,
and was not edited. The new OA-ZYRA-282 Dart test is individually formatted.

## 15 · Gate handoff

1. Fable verifies the 40-baseline promotion; OA-ZYRA-281 may then close.
2. Fable verifies this staged OA-ZYRA-282 package.
3. ChatGPT performs the external security review.
4. Only a separate Founder apply GO may apply `20260830183151`.
5. After apply, run the catalog checks and all twelve direct-call cases.

— Codex, 2026-08-30
