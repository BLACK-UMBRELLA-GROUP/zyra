-- LOCK 33 / Q135 / OA-ZYRA-317. Run after full replay on an isolated database.
\set ON_ERROR_STOP on
begin;

do $$
begin
  if current_database() !~ '^zyra_server0_v2_[a-z0-9_]+$'
    or current_user <> 'postgres' then
    raise exception 'Q135 requires an isolated replay database and its owner';
  end if;
end;
$$;

create function pg_temp.assert_name_rule(p_ok boolean, p_label text)
returns void language plpgsql as $$
begin
  if p_ok is distinct from true then
    raise exception 'Q135 FAIL: %', p_label;
  end if;
  raise notice 'Q135 PASS: %', p_label;
end;
$$;

create function pg_temp.expect_name_error(p_sql text, p_message text)
returns void language plpgsql as $$
begin
  execute p_sql;
  raise exception 'Q135 FAIL: expected %', p_message;
exception when raise_exception then
  if sqlerrm <> p_message then
    raise;
  end if;
  raise notice 'Q135 PASS: %', p_message;
end;
$$;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-000000000135'),
  ('00000000-0000-0000-0000-000000000136'),
  ('00000000-0000-0000-0000-000000000137');

-- Create a row in the shape allowed before this migration.
alter table public.profiles disable trigger profiles_validate_name_lengths;
insert into public.profiles (id, role, first_name, surname_line, gender, date_of_birth)
values ('00000000-0000-0000-0000-000000000135', 'seeker',
  repeat('ع', 45), repeat('é', 45), 'male', date '1990-01-01');
alter table public.profiles enable trigger profiles_validate_name_lengths;

-- A direct insert with a first name at the lower bound and a surname at the cap.
insert into public.profiles (id, role, first_name, surname_line, gender, date_of_birth)
values ('00000000-0000-0000-0000-000000000137', 'seeker',
  'A', repeat('é', 40), 'female', date '1990-01-01');

select pg_temp.expect_name_error($sql$
  insert into public.profiles (id, role, first_name, surname_line, gender, date_of_birth)
  values ('00000000-0000-0000-0000-000000000136', 'seeker',
    'A', repeat('é', 41), 'female', date '1990-01-01')
$sql$, 'surname_too_long');

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000136';
set local request.jwt.claim.role = 'authenticated';

-- The signup RPC creates a profile, then the authenticated client saves surname.
select pg_temp.expect_name_error($sql$
  select public.zyra_create_profile('seeker', repeat('ع', 31), 'female', date '1990-01-01')
$sql$, 'first_name_too_long');
select pg_temp.expect_name_error($sql$
  select public.zyra_create_profile('seeker', '   ', 'female', date '1990-01-01')
$sql$, 'first_name_required');
select pg_temp.assert_name_rule(
  not exists (select from public.profiles where id = auth.uid()),
  'rejected signup leaves no profile');
select pg_temp.assert_name_rule(
  public.zyra_create_profile('seeker', '  ' || repeat('ع', 29) || 'é' || '  ',
    'female', date '1990-01-01')->>'status' = 'created',
  'signup accepts a trimmed 30-character Arabic and accented name');

select pg_temp.assert_name_rule((
  select first_name = repeat('ع', 29) || 'é' and surname_line is null
  from public.profiles where id = auth.uid()
), 'signup stored the trimmed first name and a null surname');

update public.profiles set surname_line = repeat('é', 39) || 'ع' where id = auth.uid();
select pg_temp.assert_name_rule((
  select surname_line = repeat('é', 39) || 'ع'
  from public.profiles where id = auth.uid()
), 'authenticated surname write accepts 40 accented and Arabic characters');
select pg_temp.expect_name_error($sql$
  update public.profiles set surname_line = repeat('é', 41) where id = auth.uid()
$sql$, 'surname_too_long');
select pg_temp.expect_name_error($sql$
  update public.profiles set surname_line = repeat('é', 40) || ' ' where id = auth.uid()
$sql$, 'surname_too_long');

-- Decomposed e + accent takes two code points, like PostgreSQL char_length.
update public.profiles set first_name = repeat(U&'e\0301', 15) where id = auth.uid();
select pg_temp.expect_name_error($sql$
  update public.profiles set first_name = repeat(U&'e\0301', 15) || 'a' where id = auth.uid()
$sql$, 'first_name_too_long');
select pg_temp.assert_name_rule((
  select first_name = repeat(U&'e\0301', 15) and surname_line = repeat('é', 39) || 'ع'
  from public.profiles where id = auth.uid()
), 'edits count code points and failed edits preserve both saved fields');

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000135';
update public.profiles set location_text = 'Example City' where id = auth.uid();
update public.profiles set first_name = ' ' || first_name || ' ', surname_line = surname_line
where id = auth.uid();
select pg_temp.assert_name_rule(
  public.zyra_create_profile('seeker', repeat('ع', 45), 'male', date '1990-01-01')
    ->>'status' = 'updated',
  'signup retry can resubmit the saved 45-character first name');
select pg_temp.assert_name_rule((
  select first_name = repeat('ع', 45) and surname_line = repeat('é', 45)
    and location_text = 'Example City'
  from public.profiles where id = auth.uid()
), 'existing 45-character names survive unrelated and same-value writes');

select pg_temp.expect_name_error($sql$
  update public.profiles set first_name = repeat('س', 45) where id = auth.uid()
$sql$, 'first_name_too_long');
select pg_temp.expect_name_error($sql$
  update public.profiles set surname_line = repeat('è', 45) where id = auth.uid()
$sql$, 'surname_too_long');

update public.profiles set first_name = ' ' || repeat('é', 30) || ' ' where id = auth.uid();
select pg_temp.assert_name_rule((
  select first_name = repeat('é', 30) and surname_line = repeat('é', 45)
  from public.profiles where id = auth.uid()
), 'first name can be corrected while the longer surname is still saved');
update public.profiles set surname_line = null where id = auth.uid();
select pg_temp.assert_name_rule((
  select surname_line is null from public.profiles where id = auth.uid()
), 'surname can be cleared');

rollback;
