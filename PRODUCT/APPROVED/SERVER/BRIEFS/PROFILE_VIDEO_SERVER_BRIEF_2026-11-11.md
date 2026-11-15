---
id: DOC-ZYRA-0445
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - server side of the silent profile video (LOCK 29 V2, OA-ZYRA-317), throw-away databases only
links: [AD-AIOS-115, AD-AIOS-142, OA-ZYRA-317, DOC-ZYRA-0329]
owner: Fable
---

# SERVER BRIEF — PROFILE VIDEO — 11 NOV 2026

**Founder-named task.** Founder, 11 Nov (ZYRA chat): "Fable builds the video server work. After that, line 84 can run."
Founder, 11 Nov 22:1x (BLACK UMBRELLA GROUP chat, clickable): **"App strips, server refuses (Recommended)"** - the
iPhone app saves the clip with no sound track; the server checks every upload and refuses any file with sound or over
10 s (LOCK 29 **V2**, `PROFILE_VIDEO/RECORD/PROFILE_VIDEO_SPEC_CURRENT_VERSION_V2.md`).

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row and stop that step.
**Throw-away databases only - no production change.** Live waits for SERVER 0 to go live first, then the Founder's own
words "apply profile video to live" (same rule as SERVER 0, DR-ZYRA-313). No downloads, no tool installs (F33).
ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).

## What the server must guarantee
| # | Rule | Enforced by |
|---|---|---|
| G1 | Only a member with a paid Seeker role (Seeker One or a funded Family Seeker seat) can add a video | `public.zyra_has_paid_role(uid,'seeker')` (SERVER 0) in the storage insert policy **and** the submit function |
| G2 | One video per member | partial unique index (one row per user while `pending` or `approved`) |
| G3 | No sound ever: a file with any audio track is refused and deleted | Edge Function reads the MP4/MOV boxes (`moov/trak/mdia/hdlr`): any handler `soun` → refuse |
| G4 | 10 s limit | same function: `mvhd` duration ÷ timescale ≤ **10.5 s** (0.5 s encoder margin) → else refuse |
| G5 | Must be a real video | exactly one `vide` track; container type mp4 / mov; size ≤ **20 MB** (bucket limit) |
| G6 | Checked first: nobody else sees it until approved | row starts `pending`; others can read only `approved` |
| G7 | Approve / reject only by the reviewer | `zyra_review_profile_video` - `service_role` only (the AIOS review page, OA-AIOS-413, calls it later) |
| G8 | Downgrade hides it, kept; shown again on return to One | read check is live: `approved` **and** owner still has the paid Seeker role **and** caller may view the profile |
| G9 | Owner always sees their own (any state) and can remove it at once | own-folder read; `zyra_remove_my_profile_video` |

## Steps
| Step | Detail |
|---|---|
| 1 | New migration `SOURCE/supabase/migrations/<timestamp>_profile_video_lock29.sql`, written to apply **after** the SERVER 0 files |
| 1a | Private bucket `profile-videos`: `public=false`, `file_size_limit=20971520`, `allowed_mime_types = {video/mp4, video/quicktime}` |
| 1b | Table `public.profile_videos`: `id uuid pk default gen_random_uuid()`, `user_id uuid not null references auth.users on delete cascade`, `storage_path text not null unique`, `status text not null check (status in ('pending','approved','rejected','removed'))`, `duration_ms int not null check (duration_ms between 1 and 10500)`, `reject_reason text`, `created_at`, `reviewed_at timestamptz`. Unique index `(user_id) where status in ('pending','approved')`. RLS on; **no** direct insert / update / delete grants to `authenticated` (functions only); select: own rows only |
| 1c | Storage policies on `storage.objects` for `profile-videos`: **insert** only into `(foldername(name))[1] = auth.uid()` and only when `zyra_has_paid_role(auth.uid(),'seeker')`; **no update**; **delete** own folder only; **select** own folder, or `zyra_can_read_profile_video_object(name)` |
| 1d | `zyra_can_read_profile_video_object(p_object_name text) returns boolean` - security definer, `search_path = ''`: a row with that path, `status='approved'`, `zyra_has_paid_role(owner,'seeker')`, and `zyra_can_view_profile(owner)` (same pattern as `zyra_can_read_photo_object`) |
| 1e | `zyra_my_profile_video()` (authenticated): the caller's current row (status, reason, path, duration) for the Manage photos tile states Add / Being checked / Live / rejected |
| 1f | `zyra_profile_video_for(p_user uuid)` (authenticated): path + duration only when 1d's rule is true for that owner; else nothing |
| 1g | `zyra_remove_my_profile_video()` (authenticated): sets the caller's live/pending row to `removed`; the app then deletes the object (own-folder delete policy) |
| 1h | `zyra_record_profile_video(p_user uuid, p_path text, p_duration_ms int)` - **service_role only**, called by step 2: checks G1 again, marks any older `pending`/`approved` row `removed`, inserts the new row `pending` |
| 1i | `zyra_review_profile_video(p_video uuid, p_decision text, p_reason text)` - **service_role only**: `approved` or `rejected` (reason required on reject, short member-facing line), stamps `reviewed_at`; writes the shared audit row if SERVER 0's audit table exists, else a comment noting OA-AIOS-413 |
| 2 | Edge Function `SOURCE/supabase/functions/zyra-profile-video-submit/index.ts` (Deno, no npm packages): caller's JWT required; body `{ path }`; path must be in the caller's own folder. Downloads the object with the service key, walks the ISO-BMFF boxes (`ftyp`, `moov` → `mvhd`, each `trak` → `mdia` → `hdlr`), applies G3-G5. Refused → delete the object, return `{ ok:false, reason }` with one of `has_sound`, `too_long`, `not_a_video`, `too_large`, `not_allowed`. Passed → call 1h, return `{ ok:true, status:'pending' }`. Never re-encodes, never stores anything else |
| 3 | Tests on a **throw-away database** (same replay route as SERVER 0, line 33): `SOURCE/supabase/tests/profile_video_assertions.sql` - Basic refused at storage insert and at 1h; One allowed; second video replaces the first; others cannot read `pending`/`rejected`; approved readable by a viewer who may see the profile; downgrade hides it, re-upgrade shows it again; owner always sees own; remove works; non-service caller cannot run 1h / 1i |
| 4 | Function tests with Deno's built-in test runner (`zyra-profile-video-submit/index_test.ts`) on tiny made-up box fixtures built in the test code (no downloaded media): video-only 8 s passes; video + `soun` refused; 12 s refused; no `vide` refused; garbage refused; wrong folder refused. If `deno` is not already on the Mac, write the tests, mark step 4 "not run - no deno" in the task note and carry on (no install) |
| 5 | Contract note for line 84: `PRODUCT/APPROVED/SERVER/RECORD/PROFILE_VIDEO_SERVER_CONTRACT_2026-11-11.md` - bucket, path pattern `<uid>/<uuid>.mp4`, the function names above and their returns, the five refusal reasons and the member wording the app shows for each: has_sound "Your video still has sound. Please try again." · too_long "Videos can be up to 10 seconds." · not_a_video / too_large "We couldn't use this video. Please try another." · not_allowed "Profile video comes with Seeker One." |
| 6 | Gate: whole migration replay on the throw-away database clean; step 3 all pass; `flutter analyze` unchanged (no app code in this line) |
| 7 | Task note; commit within core rule 2; mark this line BUILT, FAILED or QUESTION. **No live apply, no function deploy** |

## Not in this line
Live apply and function deploy (Founder's words, after SERVER 0 is live) · the reviewer page (OA-AIOS-413) · the app side (line 84).
