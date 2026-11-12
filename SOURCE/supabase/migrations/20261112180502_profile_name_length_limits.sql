-- LOCK 33 / Q135 / OA-ZYRA-317. Existing names keep their saved lengths.
begin;

create function public.zyra_validate_profile_name_lengths()
returns trigger
language plpgsql
set search_path = ''
as $$
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

revoke execute on function public.zyra_validate_profile_name_lengths()
  from public, anon, authenticated, service_role;

create trigger profiles_validate_name_lengths
  before insert or update on public.profiles
  for each row execute function public.zyra_validate_profile_name_lengths();

commit;
