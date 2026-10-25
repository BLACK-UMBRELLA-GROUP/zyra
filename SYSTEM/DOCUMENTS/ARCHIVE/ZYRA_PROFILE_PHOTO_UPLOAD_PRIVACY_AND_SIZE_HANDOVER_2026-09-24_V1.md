# ZYRA — Profile Photo Upload Privacy and Size Implementation Handover

**Version:** V1  
**Status:** SUPERSEDED by `ZYRA_PROFILE_PHOTO_UPLOAD_PRIVACY_AND_SIZE_HANDOVER_CURRENT_VERSION_V2.md`  
**Date:** 2026-09-24  
**Owner:** Codex — Product Designer & Implementation Engineer  
**Authority:** Founder direct approval, 2026-09-24; AD-AIOS-110; OA-ZYRA-302  
**Workflow status:** CODEX IMPLEMENTED — FABLE VERIFICATION PENDING

---

## 1. What was built

The live Flutter profile-photo upload path now creates a bounded, sanitised
JPEG before any bytes may reach Supabase Storage:

- the longest edge is capped at 1440 pixels while preserving aspect ratio;
- JPEG quality is 85;
- EXIF orientation is applied to the pixels before metadata is removed;
- EXIF, GPS, camera/device, capture-time and text metadata are removed;
- the colour profile is retained because it is needed for faithful rendering
  and does not disclose capture location, time or device identity;
- the final upload always has a new `.jpg` path and `image/jpeg` content type;
- corrupt, unsupported or unverifiable input fails closed, with no fallback to
  the original picker bytes; and
- CPU-heavy decode/resize/encode work runs outside the UI isolate.

The native picker is also given the same 1440 × 1440 bound. This first bound
avoids decoding an unbounded high-megapixel source in Dart. It is not treated
as the privacy boundary because the platform picker may preserve source EXIF.
ZYRA performs a second, independent decode/orient/sanitise/encode/verify pass.

No seed object, database row, bucket setting or TestFlight build was changed
in this implementation stage.

## 2. Why it was built this way

The previously live path passed the picker's output directly to
`uploadBinary`. Source inspection established that the installed Android and
iOS picker implementations can preserve original metadata, including a route
for GPS data. A client dimension request alone therefore could not provide a
privacy boundary.

Fresh JPEG encoding from a decoded pixel image is the boundary. Orientation
must be baked first because removing the orientation tag without rotating the
pixels can leave photographs sideways. The output is decoded again before it
is returned so the implementation verifies rather than assumes that the
dimension and EXIF invariants hold.

The source bytes never reach the storage call. Any processing error returns an
upload error and uploads nothing. This preserves the Founder's explicit rule:
never fall back to the original.

## 3. Live files and hashes

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/services/zyra_profile_photo_processor.dart` | Decode, bake orientation, bound, sanitise, encode and verify | `ba1714e395daa1d760e2037edde83b5364418fa36fa2799314fcb2b260b31649` |
| `SOURCE/lib/services/zyra_photo_service.dart` | Native picker bound and fail-closed upload integration | `b3c66527d1b89a0b5cddf77c1d9eb7996989b1679ca62caec25647596bdc5396` |
| `SOURCE/test/zyra_profile_photo_processor_test.dart` | Orientation, EXIF/GPS, bounds, format, isolate and corrupt-input contracts | `eca2c122c9a786a7e102f21d9d749e77daeb533b0a91b829567057023cc495fa` |
| `SOURCE/pubspec.yaml` | Direct `image` dependency used as the app privacy processor | `8c99ea096898f4943871b3db86c55fbf84038a69d01326058b80526695dd7dd4` |
| `SOURCE/pubspec.lock` | Resolved dependency record | `ab675cba06c81f0673c7b80210fa0bf39a7f6770980fdc258183ba94af610415` |

This handover omits its own hash because embedding it would change the value.

## 4. Architecture invariants

Future implementations must preserve all of these invariants:

1. Picker output is untrusted and is never directly uploadable.
2. Orientation is applied before orientation metadata is removed.
3. Both dimensions are bounded; the longest edge may not exceed 1440 pixels.
4. The stored profile photo is a fresh JPEG at quality 85.
5. Privacy metadata is absent from the encoded output.
6. The encoded output is decoded and checked before upload.
7. Processing failure uploads nothing; original-byte fallback is prohibited.
8. A new storage path is used for a new encoded object.
9. Database/storage maintenance remains a later, separately verified stage.

## 5. Data flow and failure path

```text
member selects a gallery image
        ↓
native picker requests maxWidth 1440 + maxHeight 1440 + quality 85
        ↓
bounded picker bytes (still untrusted; metadata may remain)
        ↓
background isolate: decode → bake orientation → enforce bound again
        ↓
discard EXIF/text/extra channels → encode fresh JPEG q85
        ↓
decode output → verify dimensions and empty EXIF
        ↓ success                         ↓ any failure
new user/timestamp.jpg path               return upload error
        ↓                                 upload nothing
Supabase private profile-photos bucket
        ↓
signed URL returned to the existing photo UI
```

The upload service rechecks the signed-in principal after picker read,
processing, upload and signed-URL creation so a stale account operation cannot
be returned into another account session.

## 6. Entry point and user-visible behaviour

The entry point remains the existing Edit Photos/onboarding gallery picker.
There is no new screen, toggle or manual crop interaction. Successful uploads
continue through the existing photo UI. Cancel remains cancel. Processing or
upload failure uses the existing error result and does not expose a path,
filename or metadata in logs.

## 7. Developer controls; mock versus production

- There is no metadata-stripping preview toggle or mock path.
- `ZyraProfilePhotoProcessor.process()` is the production code used by every
  member upload through `ZyraPhotoService.pickAndUpload()`.
- Unit tests call the same processor synchronously for deterministic fixtures
  and also exercise the production `compute` isolate entry point.
- Synthetic fixtures prove the encoding contract but are not a substitute for
  inspecting an object uploaded and downloaded through each platform picker.

## 8. Migrations and live Supabase state

No migration was created or applied. No production database or Storage setting
was changed.

The approved maintenance sequence remains:

1. measure and privacy-test this candidate on iPhone and Android;
2. ship the app change;
3. convert the 99 seeded PNG objects to JPEG quality 85 under new `.jpg`
   paths, verify every upload, update all affected `profile_photos.storage_path`
   rows in one transaction, check Browse, then retire the old objects; and
4. only after checking older-client compatibility, apply a measured bucket
   file-size limit and MIME allow-list.

Steps 3 and 4 are production mutations and have not started. Their exact
artifact, rollback and acceptance probes must be presented against the live
state before execution.

## 9. Verification evidence

| Check | Measured result |
|---|---|
| `flutter test test/zyra_profile_photo_processor_test.dart` | 6/6 PASS: orientation, GPS/EXIF removal, 1440 bound, no upscaling, production isolate, PNG→JPEG, corrupt fail-closed |
| All non-visual Flutter tests | 1,319 PASS; 1 existing skip; 0 failures |
| `flutter analyze` | PASS — no issues |
| `python3 tools/zyra_check.py` | Completed; four existing source-checker findings outside this change (two developer-preview factory references and two guardian-capacity named-argument detections); Flutter analyzer remains clean |
| `flutter build ios --profile --no-codesign` | PASS — `build/ios/iphoneos/Runner.app`, approximately 35 MB on disk |
| `flutter build apk --profile` | PASS — `build/app/outputs/flutter-apk/app-profile.apk`, approximately 108 MB on disk; existing Kotlin-plugin and Android SDK XML compatibility warnings only |
| Full suite including visual goldens | NOT A PASS — existing visual-baseline pixel drift produced over 100 golden mismatches; run was stopped after the cause was isolated and the complete non-visual suite was then run successfully |
| iPhone stored-object EXIF/size/time | PENDING — Founder to supply a location-tagged capture taken away from home |
| Android emulator stored-object EXIF/size/time | PENDING — controlled GPS-tagged gallery image is acceptable for this sanitisation check |
| Real high-megapixel/low-memory Android | PENDING — required for picker/provider and memory compatibility; emulator is not a substitute |

Automated source fixtures currently prove that an EXIF-orientation-6 image is
rotated correctly, GPS/device/date EXIF disappears, a 2000 × 1000 input becomes
1440 × 720, a 320 × 480 input is not enlarged, PNG input becomes JPEG, and
corrupt bytes throw the controlled processing exception.

## 10. Known limitations and remaining gaps

- **OA-ZYRA-302:** device privacy and size evidence, shipment, seed replacement
  and bucket hardening remain open in the approved order.
- No external tester may upload a real photo until the sanitising build ships.
- An Android emulator with a controlled GPS-tagged gallery image is sufficient
  to prove that the app's Android picker/upload path removes location metadata
  from the stored result. It does not prove physical device provider behaviour,
  high-megapixel performance or low-memory reliability.
- The code retains the ICC colour profile intentionally. It strips privacy and
  descriptive capture metadata, not colour-rendering data.
- The current governed Image Handling Standard describes a future server-side
  multi-variant pipeline and original retention. The live implementation is a
  client-side single-JPEG privacy boundary, and the Founder has separately
  ruled that profile photos are not identity evidence and must not silently be
  retained as forensic originals. This direct-instruction difference requires
  Fable reconciliation; this handover does not silently rewrite the product
  specification.

## 11. Next steps and owners

1. **Founder / Codex — OA-ZYRA-302:** install the candidate on the connected
   iPhone; upload a GPS-tagged test capture taken away from home; download the
   stored object and record EXIF, dimensions, bytes and processing time.
2. **Codex — OA-ZYRA-302:** run the same stored-object inspection using a
   controlled GPS-tagged image in an Android emulator.
3. **Founder / Codex — OA-ZYRA-302:** repeat performance and failure testing on
   a real high-megapixel, low-memory Android when available.
4. **Codex:** ship only after the candidate measurements and privacy checks
   pass.
5. **Codex:** prepare and separately gate the transactional seed-path remap and
   object retirement, then the backward-compatible bucket limits.
6. **Fable:** verify this handover against the code, reconcile governed product
   documentation and update the OA register.

## 12. Authority map

| Layer | Authority |
|---|---|
| Founder decision | Direct approval in the Codex task, 2026-09-24 |
| Active action | `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` — OA-ZYRA-302 |
| Product/platform specification | `APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md` |
| Profile consumer summary | `APP/Profiles/Summary.md` |
| As-built truth | This handover plus the live files in §3 |
| Supabase key migration | Message 151 / separate workstream; not changed here |

— END OF HANDOVER V1 —
