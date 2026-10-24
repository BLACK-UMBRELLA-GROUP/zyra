# ZYRA — Profile Photo Upload Privacy and Size Implementation Handover

**Version:** V2  
**Status:** CURRENT_VERSION — CODE COMPLETE; iOS real-file processor acceptance passed; live stored-object and Android acceptance pending  
**Date:** 2026-09-24  
**Owner:** Codex — Product Designer & Implementation Engineer  
**Authority:** Founder direct approvals, 2026-09-24; AD-AIOS-110; OA-ZYRA-302  
**Workflow status:** CODEX IMPLEMENTED — FABLE VERIFICATION PENDING  
**Supersedes:** `ZYRA_PROFILE_PHOTO_UPLOAD_PRIVACY_AND_SIZE_HANDOVER_2026-09-24_V1.md`

---

## 1. Outcome

ZYRA now supports selecting up to the remaining six-profile-photo allowance in
one picker pass, reviewing and cropping each photo in a 3:4 editor, previewing
profile-card and avatar presentation, and saving only after the whole review
queue is approved.

Every saved artifact crosses the same privacy boundary before it can reach
Storage:

- EXIF orientation is baked into pixels;
- the longest edge is capped at 1440 pixels;
- output is a fresh JPEG at quality 85;
- EXIF, GPS, camera/device, capture-time and text metadata are removed;
- the output is decoded and verified before release; and
- corrupt, unsupported or unverifiable input fails closed. Original picker
  bytes are never uploaded as a fallback.

Upload failures now carry a stable privacy-safe category and support reference:

| Reference | Category |
|---|---|
| `ZY-PH-01` | authentication/session |
| `ZY-PH-02` | permission/RLS denial |
| `ZY-PH-03` | connection |
| `ZY-PH-04` | image preparation/privacy processing |
| `ZY-PH-05` | Storage service |
| `ZY-PH-06` | unknown |

Logs contain only the reference, exception type and, for Storage failures, the
HTTP status. They never contain a filename, object path, member id, exception
message or image metadata.

## 2. Finding behind mailbox message 156

The Founder's three iPhone photographs did not fail a live upload and did not
go to a second database. They were selected while Developer Preview was
active. That path intentionally:

1. reads and sanitises the device photo;
2. places a `data:image/jpeg;base64,...` value in `AppState` memory;
3. makes no Storage or Postgres request; and
4. loses the preview value when that app process/session is reset.

The installed candidate targets the sole live project
`sxoaxonzjqkgajmlagyk`, but the preview HTTP boundary blocks live-data access.
The former generic catch therefore did not hide this particular test: no
upload operation was attempted. It was still a real observability defect for
normal signed-in uploads and is replaced by the typed references above.

Read-only production measurement after the investigation remained:

| Source | Count | Newest row/object |
|---|---:|---|
| `storage.objects`, bucket `profile-photos` | 103 | 2026-08-19 18:43:35.68296+00 |
| `public.profile_photos` | 597 | 2026-08-05 22:36:31.45144+00 |

No production mutation or migration was used for that measurement.

## 3. Real iPhone acceptance evidence

Three GPS-positive HEIC fixtures supplied under the protected, gitignored
`PHOTO_PRIVACY_TEST_2026-09-24` folder were tested without printing metadata
values. The opt-in test creates transient derivatives inside that same folder
and removes them in `finally`; the originals remain untouched pending the
Founder's explicit deletion instruction.

Measured result:

- 3 of 3 native-prepared JPEGs still contained EXIF;
- 3 of 3 still contained GPS, proving the dangerous input survived native
  preparation;
- 3 of 3 ZYRA outputs contained zero EXIF/GPS/device metadata;
- 3 of 3 outputs were JPEG and no edge exceeded 1440 pixels; and
- no transient acceptance directory remained afterward.

This proves the application processor removes the supplied iPhone metadata.
It is not yet a stored-object proof because Developer Preview is prohibited
from uploading. One normal signed-in Seeker upload, followed by downloading
that private object and inspecting it, remains required for end-to-end iOS
Storage acceptance.

## 4. Data flow and boundaries

```text
choose up to remaining photo allowance
        ↓
iOS/Android picker: max 1440 × 1440, q85, metadata still untrusted
        ↓
processor: decode → orient → bound → fresh metadata-free JPEG → verify
        ↓
review queue: 3:4 crop, drag/pinch, rotate/reset, card/avatar previews
        ↓ all crops approved
processor runs again on every final crop
        ├─ Developer Preview → in-memory data URL only; never live data
        └─ signed-in member → private Storage object → signed display URL
                                      ↓
                             ordered `profile_photos` rows
```

If any photo fails during a live reviewed batch, new uploads from that batch
are rolled back best-effort and the profile change is not committed. Existing
profile photos and rows are not part of that rollback.

## 5. Live files and candidate hashes

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/services/zyra_profile_photo_processor.dart` | sanitisation, orientation, size cap, verification | `3f94b0e15d3f2a722e9ac0d4acfd4937de97338ff0e8cba0d668569f769b309f` |
| `SOURCE/lib/services/zyra_photo_service.dart` | picker, preview/live boundary, Storage upload, typed diagnostics | `b58da937ed1a860a82205beaebbeb22f305a010edf9a1d314a56da9bd1ad4746` |
| `SOURCE/lib/screens/profile/zyra_photo_batch_flow.dart` | choose-many, review queue, save and rollback coordinator | `a2cafca294167b0750b87df1d6fbb38fe064ab6cdb2cdd838277e0752a723291` |
| `SOURCE/lib/screens/profile/photo_crop_review_screen.dart` | 3:4 crop and presentation previews | `5f6a8f5b4bc4d64dd5efcbae62cfc1e8d8fca52a88e48eefe2b02b3cc42740fa` |
| `SOURCE/lib/screens/profile/edit_photos_screen.dart` | signed-in/preview Edit Photos entry point | `37241d0adfbb3efb5c214964f1dc324e571ddf2526d13cc37b03a3c312204a47` |
| `SOURCE/lib/screens/onboarding/chapter2_flow.dart` | onboarding entry point using the same batch flow | `8e02f2f1a77cd510ad83088cb0936bb4ed70e6b1f802d2f8a963e4c2b5c81e4e` |
| `SOURCE/test/zyra_profile_photo_processor_test.dart` | synthetic privacy, size, failure-diagnostic contracts | `0d0147f9a8a3adcb975145ed3bf88092652677e89d20524729c7037f6a60ae1f` |
| `SOURCE/test/real_photo_privacy_acceptance_test.dart` | opt-in real-HEIC acceptance harness | `73c878b8f21514a0a558c7a1ea8a5ecc7992032e711b57e20eca4eb65bf89689` |
| `SOURCE/pubspec.yaml` | photo/crop dependencies | `f21b6f9e18cc2af8fcdededb6f590043844f5088978d904cdb5b57ad94623dee` |
| `SOURCE/pubspec.lock` | resolved dependency record | `81d8028f8ded2d63002e52d3a86ed36fd2c4bd21aabbde96ad252aa1153d7aea` |

This handover omits its own hash because embedding it would change the value.

## 6. Verification

| Check | Result |
|---|---|
| `flutter analyze` | PASS — no issues |
| processor + Edit Photos focused tests | PASS — 13/13 |
| real iPhone HEIC acceptance | PASS — 3/3; prepared GPS 3, final metadata 0 |
| signed iOS profile build | PASS — `Runner.app`, 37.2 MB |
| physical iPhone install | PASS — bundle `app.zyraconnect.zyra` |
| physical iPhone launch | PASS |
| production count probe | PASS/read-only — 103 Storage objects, 597 photo rows; no new object |
| live stored-object metadata comparison | PENDING — needs normal signed-in Seeker upload |
| Android picker/stored-object and low-memory checks | PENDING — OA-ZYRA-302 |

An attempted focused test command also named two nonexistent test files and
therefore exited non-zero after the 13 real tests passed. That command mistake
is not a product failure; the actual named existing suites and analyzer passed.

## 7. Migrations and live state

No migration was created or applied. No bucket setting, object, row, RLS
policy, seed asset or TestFlight build was changed. Supabase's Storage model
continues to rely on authenticated RLS and owner-folder paths; the client does
not use a service-role bypass.

## 8. Known limitations and next steps

1. **OA-ZYRA-302 / Founder + Codex:** in a normal signed-in Seeker account,
   upload one GPS-positive test image, download that exact private object, and
   confirm zero EXIF/GPS/device metadata plus dimensions/bytes.
2. **OA-ZYRA-302 / Codex:** repeat picker-to-stored-object acceptance on
   Android and measure a real high-megapixel/low-memory device when available.
3. **OA-ZYRA-302 / Founder gate:** separately approve measured bucket MIME and
   size limits and the seed JPEG conversion; neither production mutation was
   bundled into this client change.
4. **Fable:** reconcile OA-ZYRA-302 and the future/server-side Image Handling
   Standard against this client-side, no-original-retention implementation.

The three real fixtures have not been deleted by Codex. Deletion is a material,
destructive action and remains for the Founder to instruct explicitly after
the evidence is accepted or the stored-object test is complete.

## 9. Authority map

| Layer | Authority |
|---|---|
| Founder instruction | Direct approvals in the Codex task, 2026-09-24 |
| Open action | `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` — OA-ZYRA-302 |
| Product/future pipeline | `APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md` |
| As-built truth | This V2 handover and the live files/hashes above |
| Superseded handover | `ZYRA_PROFILE_PHOTO_UPLOAD_PRIVACY_AND_SIZE_HANDOVER_2026-09-24_V1.md` |

— END OF HANDOVER V2 —
