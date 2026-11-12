---
id: ASBUILT-ZYRA-LINE89-SERVER-CONTRACTS
type: HANDOVER
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Disposable database contract for Guardian invitations, Compatibility areas, Browse filters and profile photo cleanup
links: [DOC-ZYRA-0472, DOC-ZYRA-0329, OA-ZYRA-302, OA-ZYRA-317, OA-ZYRA-193, DR-ZYRA-250]
owner: Codex
---

# Server contracts · line 89 · 12 November 2026

This record covers the SQL and handler verified on the disposable PostgreSQL 17.6 replay. Server application and function deployment require separate approval after SERVER 0 goes live. The existing app continues to use its approved preview and fallback data.

## Q91 · Guardian invitations

`preview_wali_invite(p_token text)` keeps the existing four fields and adds `seeker_plan` (`basic` or `one`), `basic_place_free` and `needs_guardian_one`. A signed-in holder of a pending Seeker-sent code receives the new fields when their role is Guardian or their profile has yet to be created. They get no identity for the person using the Basic place. Seeker One always reports a free Basic place. The three fields are null on the other existing preview paths.

`accept_wali_invite(p_token text, p_relationship text default null)` returns the linked row UUID. A Seeker Basic can accept one active Guardian Basic. Additional Guardians require verified Guardian One. An already-paid Guardian leaves the free place available. Seeker One can accept Guardians of either plan. Both Seeker plans are capped at ten active links through this invitation path. Admission rechecks plans and occupancy under a per-Seeker write lock even on the first link. `needs_guardian_one` and `guardian_capacity_exceeded` leave the invitation open. A new link stores the invitation UUID and the admission place, `basic_place` or `guardian_one`. The Guardian-sent reverse route and addressed requests retain their existing admission rules.

## Q92, Q97, Q98 and Q100 · Compatibility

`zyra_compatibility_topics(p_subject uuid, p_match_id uuid default null)` returns 12 rows in D3 order for an admitted caller. Each row contains `overall, topics_locked, area_no, area_code, band, state`. A locked response has a null band. The band codes are `strong`, `good`, `some_differences` and `not_enough`. A result can be `ok`, `incomplete`, `invalid` or `needs_reconfirmation`. Only `ok` carries an Overall or any bands. The response carries no area percentages, raw answers, input hash or saved score from the other direction.

An entitled Profiles request uses the caller's paid Unlock for this subject. A Journey request uses the match UUID and checks consent and current attempt access or the readable archive. A Seeker One or a Seeker with an exact paid Unlock receives bands. A Guardian One receives bands in their linked Seeker's direction only. A Guardian Basic receives the locked area names even if their Seeker used an Unlock. An accepted restart reuses prior mutual consent for that match and checks Guardian access against the restarted attempt.

The service-only `zyra_score_direction_v1(p_viewer, p_subject)` validates both sides' applicable answers, the viewer's counterpart-specific lights, and Chapter 2. It uses one contribution per question and averages every selected option within a multi-select. The private saved result stores Overall, 12 bands and a validation hash once per directional pair. Reveal writes both validated Overall values into the existing match projection. An existing exact Unlock+ uses the same saved direction. Purchase and new Plus spending remain held. The existing Reveal-state read retains its legacy projection until Reveal writes validated values.

Old capture rows start at `v0`. New captures start at `v1`. The current client still emits Yellow for No preference, so the scorer requests reconfirmation. Existing `v0` Amber stays ambiguous. QUESTIONS row 105 tracks how the app records an explicit same-value reconfirmation as a trusted v1 capture. Repair can retry without spending another Unlock.

## Q99 and Q101 · Browse

`zyra_discover_profile_ids(p_age_min int default 18, p_age_max int default null, p_location text default 'worldwide', p_distance_km int default null, p_country text default null, p_nationalities text[] default '{}', p_ethnicities text[] default '{}', p_limit int default 50, p_after uuid default null)` returns `profile_id, one_filters_applied, location_applied` and no total. The locations are `worldwide`, `country` and `near`. Near without a stored caller location returns Worldwide results with `location_applied = false`. A Basic caller's Nationality and Ethnicity selections are ignored. Browse retains its compatibility ordering with UUID as the stable tie-break. Pass the last profile UUID as `p_after`.

`zyra_set_my_home_place(p_country, p_lat, p_lon)` stores the signed-in Seeker's home place with coordinates rounded to two decimals. Other members, including linked Guardians, have no direct access. `zyra_set_profile_hidden(p_profile, p_hidden)` and the older named argument `p_other` use the same owner-only hide operation. `zyra_my_hidden_profile_ids()` returns the caller's hide list. Discovery filters hides in both directions without identifying who hid whom. The two RPC forms passed named SQL calls. The existing client call still needs a hosted PostgREST transport check when Browse connects.

## Q95 · Profile photos

Upload an orientation-applied JPEG to the private `profile-photo-sources` bucket at `<uid>/<photo_id>.jpg`. Normalize the long side to at most 3,000 pixels before upload. The bucket limits uploads to 8 MiB and JPEG MIME type. Source bytes and framing are available to the owner only. The source stays at the same path during Adjust, and a new photo uses a fresh UUID.

| RPC | Input and result |
|---|---|
| `zyra_save_profile_photo` | `photo` UUID, `display_path` text, `source_path` text, `crop` JSON object with normalized `x,y,w,h`, `rotation` integer (0, 90, 180 or 270), `expected_revision` integer. Returns `{"revision": n}`. Pass 0 for a new row. Existing rows start at revision 1. |
| `zyra_my_photo_sources` | No arguments. Owner rows in gallery order with `photo, display_path, source_path, crop, rotation, revision`. A legacy photo with no source keeps the saved-crop fallback. |
| `zyra_remove_profile_photo` | `photo` UUID and `expected_revision` integer. Returns `{"revision": n}` and removes the row from the live gallery while queuing both objects. |

Use the returned revision for the next change. `stale` (SQLSTATE `40001`) means the client must refresh the owner gallery before trying again. A path must belong to the signed-in member. Old gallery clients keep their existing direct display writes. If one rewrites the entire gallery, it creates legacy rows with no source and the replaced source goes to cleanup.

`zyra_reset_profile` and `delete_own_account` queue display and source paths before removing gallery rows. Reset preserves the legacy response with an empty `storage_paths` list because cleanup owns the object deletion. `zyra-photo-cleanup` accepts a service-role POST. It uses the Storage API for exact queued paths after checking live references. The worker retries at most ten times, records errors and completion, and permanently retires names once claimed so a late Storage retry cannot remove a new photo.

Storage transport, Auth cascade behavior against the hosted Storage catalog, and the Edge gateway still need verification on a separately approved target.

Platform references [Storage Access Control](https://supabase.com/docs/guides/storage/security/access-control), [Storage schema](https://supabase.com/docs/guides/storage/schema/design), [PostgreSQL locking](https://www.postgresql.org/docs/17/explicit-locking.html).
