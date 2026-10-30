-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317 / OA-ZYRA-319.
-- Local proof only; production requires a separate exact-payload Founder GO.

begin;

create or replace function public.zyra_family_message_circle_can_send(
  p_seeker uuid
)
returns boolean
language sql stable security definer set search_path = ''
as $$
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
revoke all on function public.zyra_family_message_circle_can_send(uuid)
  from public, anon, authenticated;

commit;
