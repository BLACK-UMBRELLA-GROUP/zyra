---
id: ASBUILT-ZYRA-LINE85-PROFILE-VIDEO
type: HANDOVER
status: CURRENT
feature: PROFILE VIDEO
purpose: Line 84 integration contract for LOCK 29 V2
links: [DOC-ZYRA-0445, DOC-ZYRA-0446, DOC-ZYRA-0447, DOC-ZYRA-0329, OA-ZYRA-317]
owner: Codex
---

# Profile video server contract

Line 85 was verified on disposable PostgreSQL 17.6 using the SERVER 0 migration order. Use this interface for line 84. Live use awaits SERVER 0 and the Founder's separate profile-video apply approval. The SQL proof used a simulated Storage catalog and authenticated claims. The Edge handler was checked with synthetic boxes and mocked HTTP calls. Verify Storage transport and cache behavior on an authorized test target before release.

## Upload

Export one MP4 video track with no audio track and trim to 10 seconds. Upload with the member's session to the private `profile-videos` bucket, using `<uid>/<uuid>.mp4` with a fresh lowercase UUID for every upload. Use `video/mp4`, standard upload with upsert off, and cache control set to zero. The bucket also accepts `video/quicktime` at an equivalent `.mov` path. Its size limit is 20,971,520 bytes. Direct Seeker One and funded Family Seeker seats use the same SERVER 0 paid-role rule.

Invoke `zyra-profile-video-submit` with the member JWT and JSON `{"path":"<uid>/<uuid>.mp4"}`. Success returns `{"ok":true,"status":"pending"}`. Read the owner RPC for current state after a retry. The server checks ISO-BMFF boxes for MP4 or MOV, one video track, zero audio tracks, and a positive movie-header duration at most 10,500 ms including the encoder allowance. The app's trim stays at 10 seconds.

A refusal returns `{"ok":false,"reason":"…"}`. The endpoint discards the refused upload when it can identify that upload safely. An absent or wrong-folder path gives the caller no authority over another member's file. An upstream or cleanup failure returns HTTP 503 with `{"error":"temporarily_unavailable"}` and can be retried. A missing or invalid session returns HTTP 401.

| Reason | Member wording |
|---|---|
| `has_sound` | Your video still has sound. Please try again. |
| `too_long` | Videos can be up to 10 seconds. |
| `not_a_video` | We couldn't use this video. Please try another. |
| `too_large` | We couldn't use this video. Please try another. |
| `not_allowed` | Profile video comes with Seeker One. |

## Read, review and remove

| Entry point | Arguments and result |
|---|---|
| `zyra_my_profile_video` | Authenticated. No arguments. Zero or one row with `id`, `status`, `reject_reason`, `storage_path`, `duration_ms`. Empty means Add. `pending` means Being checked, `approved` means Live, and `rejected` means Add with the reason. |
| `zyra_profile_video_for` | Authenticated. `p_user` is the profile owner's UUID. Zero or one row with `storage_path` and `duration_ms`. A row requires approval, current paid Seeker access for the owner, and permission to view the profile. A Basic viewer can qualify. |
| `zyra_can_read_profile_video_object` | Authenticated Storage predicate. `p_object_name` is the path. Returns a boolean using the same visibility rule. |
| `zyra_remove_my_profile_video` | Authenticated. No arguments. Marks a pending or approved row removed and returns its path, or null if there is no such row. Delete the returned object from the member's own bucket folder. The row stops qualifying for other viewers at the time of removal. |
| `zyra_record_profile_video` | Service only. `p_user` UUID, `p_path` text, `p_duration_ms` integer. Returns the row UUID. A fresh path replaces the previous pending or approved row and starts pending. The Edge service passes `p_object_id` as a fourth argument to bind the record to the validated Storage object. |
| `zyra_review_profile_video` | Service only. `p_video` UUID, `p_decision` as `approved` or `rejected`, `p_reason` text. Rejection needs a short member-facing reason. Updates a pending row and its review time. Returns void. The review queue and audit integration are tracked in OA-AIOS-413. |

Fetch media through authenticated Storage download with the viewer's JWT. Storage signing is disabled for member reads in this bucket. Refresh access on open and discard local playback data when authorization changes. The owner can read their own object while pending, rejected, or downgraded. Downgrade hides the approved clip from others and restored entitlement exposes it again if the profile remains visible.

## Verification files

- `SOURCE/supabase/migrations/20261112095000_profile_video_lock29.sql`
- `SOURCE/supabase/tests/profile_video_assertions.sql`
- `SOURCE/supabase/functions/zyra-profile-video-submit/index.ts`
- `SOURCE/supabase/functions/zyra-profile-video-submit/index_test.ts`

Platform references [Storage operation helpers](https://supabase.com/docs/guides/storage/schema/helper-functions) and [Edge Function authentication](https://supabase.com/docs/guides/functions/auth).
