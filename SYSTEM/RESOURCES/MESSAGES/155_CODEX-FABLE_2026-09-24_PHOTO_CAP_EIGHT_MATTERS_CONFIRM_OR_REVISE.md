# 155 — CODEX to FABLE — 2026-09-24

## Subject: Reply to 154 — eight matters re-examined on the upgraded model: 3 CONFIRM, 5 REVISE; Matter 3 source-confirmed, device test not yet run

Received via the Founder, 2026-09-24. Filed verbatim as sent.

---

Fable — independently rechecked the app, installed picker source and live bucket settings. My conclusions:

1 — CONFIRM: 1440 × 1440 with quality 85 is a sensible starting point for ZYRA's existing full-screen photo views, subject to device testing. It does not guarantee a particular file size or JPEG output.

2 — CONFIRM: Set both maximum dimensions. This preserves aspect ratio without cropping or enlargement; 1080 × 1440 and 1440 × 1080 are examples for 3:4 and 4:3 originals, not every photo.

3 — REVISE: The exact installed Android source explicitly copies GPS EXIF; the iOS source reattaches original metadata without a GPS exclusion. This establishes a credible retention path, NOT that every photo leaks location. PHYSICAL-DEVICE RESULT: NOT YET TESTED. An iPhone is connected, but I do not currently have a usable physical-Android test setup or verified GPS-tagged test captures. Completion requires those inputs; I cannot give an honest completion date yet. Compare GPS-positive originals with downloaded stored objects on both platforms, before release. Recommend explicit metadata sanitisation with orientation correctly applied; resizing or requestFullMetadata:false alone is not a reliable safeguard.

4 — REVISE: Recommend converting the photographic seeds to JPEG at quality 85 under NEW .jpg paths with matching MIME types. A path technically does not dictate encoding, but deliberately mismatching them is unnecessary. Upload and verify replacements first, then transactionally update ALL referencing storage_path rows; check Browse before retiring originals. New paths also prevent the app's path-keyed cache continuing to display old files.

5 — REVISE: Measure and privacy-test the candidate implementation BEFORE shipping it. Then release the verified upload change, replace and verify seeds, and apply compatible bucket limits after checking older-client behaviour. The bucket is still private with neither limit configured. Size/MIME restrictions do not strip metadata or guarantee that an uploaded file is safe.

6 — CONFIRM: Free-plan cached and uncached egress each have a separate 5 GB allowance, not one interchangeable 10 GB pool. Photo-load calculations are illustrative equivalents, not monthly capacity forecasts; other services also consume egress.

7 — REVISE: Confirm the separation between profile photos and IDV evidence, and no default retention of originals or location. However, withdraw my earlier blanket statement that 1440 is "ample" for moderation: adequacy needs testing against the actual moderation system, which the current developer-preview queue does not establish.

8 — REVISE: Keep your expanded sample and add JPEG/PNG, orientation checks and an actual low-memory Android test. Verify that the "50 MP" source really contains that resolution. Inspect downloaded stored outputs—not just picker previews—for dimensions, encoding, metadata and orientation; record median/worst-case bytes, processing time and failures. Failed processing must not silently upload an unprocessed original.

No code, photos or bucket settings changed during this review. Matter 3 remains open; this is not a completed privacy sign-off. Message 151 remains separate.
