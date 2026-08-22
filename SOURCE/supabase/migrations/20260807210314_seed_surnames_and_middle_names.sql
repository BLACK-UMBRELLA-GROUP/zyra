-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807210314, applied name
-- 'seed_surnames_and_middle_names') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Give the seeded profiles surnames, and some of them middle names.
-- Founder 2026-08-07: "give them surnames and some users middle names also
-- so i can see how it will look on the app cos right now im only seeing
-- first names."
--
-- WHY HE WAS SEEING FIRST NAMES ONLY: the plumbing was already complete.
-- zyra_discovery_service selects surname_line, SeekerProfile carries it,
-- and browse_screen renders it under the first name. The column was simply
-- NULL on 123 of 149 rows, so most cards had nothing to draw.
--
-- FIXTURE DATA ONLY. This is the "borrow real data wherever real data
-- exists" rule pointed at the opposite problem: there is no real data to
-- borrow, so it is invented — but invented to the same shape the product
-- will actually hold, which is what makes the screen worth looking at.
--
-- ── DETERMINISTIC, NOT RANDOM. Assignment is driven by md5(id), so
-- re-running gives every profile the same name again. random() would mean
-- "the layout broke on the long one" was unreproducible the moment anyone
-- re-seeded, and a bug you cannot get back is a bug you cannot fix.
--
-- ── ROUGHLY ONE IN THREE GETS A MIDDLE NAME, which is what makes this
-- worth doing at all: the interesting case is not "Ahmed", it is
-- "Maryam Fatima Ahmed" wrapping to two lines on a Browse card next to a
-- 64pt photo. A deck where every name is short proves nothing.
--
-- ── GENDER. Family names carry across both in these naming traditions, so
-- the pools overlap heavily. Begum and Khatun do NOT — they are used as
-- women's names — so they appear in the female pool only. Middle names are
-- split properly rather than dealt from one list.
--
-- ── EXISTING VALUES ARE NOT TOUCHED. 26 rows already had a surname and
-- keep it, so anything already checked against them still holds.

alter table public.profiles disable trigger profiles_updated_at;

with pools as (
  select
    array['Khan','Ahmed','Ali','Hussain','Iqbal','Malik','Qureshi','Sheikh',
          'Siddiqui','Chaudhry','Rahman','Haque','Farooq','Rashid','Aziz',
          'Mahmood','Bashir','Karim','Saleh','Nasser','Yousef','Choudhury',
          'Rahim','Zaman','Akhtar','Anwar','Hashmi','Ansari','Mirza','Baig']::text[] as fam_m,
    array['Khan','Ahmed','Begum','Hussain','Khatun','Malik','Qureshi','Siddiqui',
          'Chaudhry','Rahman','Haque','Bibi','Rashid','Aziz','Mahmood','Karim',
          'Yousef','Choudhury','Rahim','Zaman','Akhtar','Anwar','Hashmi','Ansari',
          'Mirza','Baig','Farooqi','Yasin']::text[] as fam_f,
    array['Abdullah','Bilal','Hamza','Yusuf','Idris','Zayd','Rayyan','Uthman',
          'Ibrahim','Musa','Salman','Tariq']::text[] as mid_m,
    array['Fatima','Aisha','Zahra','Noor','Khadija','Maryam','Safiya','Amina',
          'Hafsa','Ruqayyah','Sumayya','Zainab']::text[] as mid_f
),
picked as (
  select
    p.id,
    p.gender,
    -- Three independent draws from one hash. Different slices, so the
    -- surname, the middle name and whether there IS one do not correlate —
    -- reusing one number would give every "Khan" the same middle name.
    abs(('x' || substr(md5(p.id::text), 1, 8))::bit(32)::int)  as h_fam,
    abs(('x' || substr(md5(p.id::text), 9, 8))::bit(32)::int)  as h_mid,
    abs(('x' || substr(md5(p.id::text), 17, 8))::bit(32)::int) as h_has
  from public.profiles p
  where p.surname_line is null
)
update public.profiles t
   set surname_line =
     case
       when k.h_has % 3 = 0 then
         -- middle + family, the "Maryam Fatima Ahmed" shape
         (case when k.gender = 'male'
               then (select mid_m[(k.h_mid % array_length(mid_m,1)) + 1] from pools)
               else (select mid_f[(k.h_mid % array_length(mid_f,1)) + 1] from pools)
          end)
         || ' ' ||
         (case when k.gender = 'male'
               then (select fam_m[(k.h_fam % array_length(fam_m,1)) + 1] from pools)
               else (select fam_f[(k.h_fam % array_length(fam_f,1)) + 1] from pools)
          end)
       else
         (case when k.gender = 'male'
               then (select fam_m[(k.h_fam % array_length(fam_m,1)) + 1] from pools)
               else (select fam_f[(k.h_fam % array_length(fam_f,1)) + 1] from pools)
          end)
     end
  from picked k
 where t.id = k.id;

alter table public.profiles enable trigger profiles_updated_at;
