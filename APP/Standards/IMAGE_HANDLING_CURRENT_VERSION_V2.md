FEATURE NAME
ZYRA — Platform Standards
Document: Image Handling Standard

============================================================
IMAGE HANDLING STANDARD
============================================================

Status: CURRENT_VERSION_V2
Last Updated: 2026-07-25
Supersedes: IMAGE_HANDLING_2026-07-25_V1.md (archived:
  IMAGE_HANDLING_2026-07-25_V1.md, same folder — no ARCHIVE
  subfolder convention exists under APP/, matching APP/Standards
  precedent)

**Filing note (2026-07-25) — DR-ZYRA-096:** merges OA-ZYRA-130
(Profile Photo Display & Cropping) and OA-ZYRA-131 (Profile Photo
Moderation & Safety) into this document, resolving the conflict
flagged the same day in `APP/Profiles/Summary.md`. Resolution
process: Claude raised the conflict (manual crop editor proposal vs.
this document's "no user cropping interaction, ever" philosophy) to
ChatGPT and the Founder; both independently converged on the same
answer — keep V1's automatic pipeline as the default architecture,
treat manual crop adjustment as a narrow exception, and merge the two
parallel moderation pipelines (this document's AI Quality Evaluation
+ OA-131's Safety/Authenticity stages) into one canonical flow rather
than maintaining two. Founder's exact instruction: *"I don't think the
answer is to choose one document and reject the other... I believe the
repository's original philosophy is actually the better experience...
I would not introduce a manual crop editor as the default behaviour...
The only situation I'd consider allowing manual adjustment is if the
AI cannot confidently produce a good crop or the user explicitly
chooses to adjust it afterwards."* See DR-ZYRA-096 for the full
decision record.

------------------------------------------------------------
CORE PHILOSOPHY
------------------------------------------------------------

The user uploads one photo. ZYRA does everything else.

The user should never need to think about:
  — Resolution
  — Aspect ratio
  — Compression
  — Cropping
  — Device sizes
  — Retina display support
  — File optimisation

All of this happens automatically, invisibly, and immediately
upon upload — this remains the default, primary workflow, unchanged
by the V2 additions below. The only user interaction in the default
flow is: Upload Photo, then review the result ZYRA produces.

**Manual crop adjustment is an exception, not the primary workflow**
(new, V2) — see MANUAL CROP ADJUSTMENT below for exactly when it
applies.

------------------------------------------------------------
SCOPE — PLATFORM-WIDE
------------------------------------------------------------

This standard applies to every image uploaded to ZYRA,
regardless of where it is displayed:

  — Browse (full-screen profile cards)
  — Profile view (own and others)
  — Journey (conversation context)
  — Guardian view (seen by Guardian during oversight)
  — Notifications (thumbnail previews)
  — Admin / moderation tools
  — Any future surface

Because Browse is photo-first and images occupy near
full-screen, image quality is part of the product itself.
A consistent, high-quality image pipeline is not a feature
— it is a platform standard.

------------------------------------------------------------
CANONICAL PIPELINE ORDER (new, V2)
------------------------------------------------------------

Upload → AI Quality → Safety & Authenticity → Face Detection & Smart
Crop → Moderation Decision

One source of truth — this replaces the two parallel pipelines that
existed briefly between OA-131 being raised (2026-07-19) and this
merge (2026-07-25). The detailed steps below are organised in this
order.

------------------------------------------------------------
SERVER-SIDE PROCESSING PIPELINE
------------------------------------------------------------

Every uploaded image passes through the following pipeline
automatically upon receipt. The user sees none of this except the
final review step.

Step 1 — Validation
  — Check minimum dimensions (minimum: 800px on shortest side
    to support full-screen display on modern devices)
  — Check minimum file size (reject files under ~20KB)
  — Validate file type (JPEG, PNG, HEIC, WEBP accepted)
  — Reject corrupt or unreadable files

Step 2 — Orientation Correction
  — Read EXIF orientation tag
  — Rotate image to correct orientation automatically
  — Normalise so all images are stored upright

Step 3 — EXIF Metadata Removal
  — Strip all EXIF data from image on upload
  — Includes: GPS coordinates, device model, timestamp,
    camera settings, and all other embedded metadata
  — Privacy-critical: location data must never be stored
    or served with any image

Step 4 — Compression & Quality Optimisation
  — Re-encode to preserve visual quality while reducing
    file size
  — Target: visually lossless at ≤85% JPEG quality
  — For PNG: convert to JPEG unless transparency is required
  — For HEIC: convert to JPEG/WEBP for broad compatibility
  — Output format: WEBP preferred (with JPEG fallback for
    older clients)

Step 5 — Multi-Resolution Generation
  Generate the following variants from the processed original:

  Variant       Width    Use Case
  ─────────────────────────────────────────────────
  thumbnail     120px    Notification icons, small avatars
  card_small    480px    Browse card (non-retina)
  card_large    960px    Browse card (retina / 2x)
  profile_std   750px    Full profile view (non-retina)
  profile_hd   1500px    Full profile view (retina / 2x)
  original     preserved Stored securely; never served directly

  All variants are stored in cloud object storage (e.g. S3).
  Originals are retained for moderation review purposes only.

Step 6 — Face Detection & Smart Cropping
  — Run face detection on upload
  — Identify primary face region
  — Generate thumbnail crops centred on face — this remains fully
    automatic and is the default outcome for every upload
  — Original image remains uncropped for full-profile display
  — If no face detected: flag for manual review before approval
  — If multiple faces detected: flag for review (may violate
    platform photo guidelines)
  — If face is detected but crop confidence is low (e.g. face is
    partially obscured, awkward framing, ambiguous primary
    subject): do not silently ship a poor crop — route to MANUAL
    CROP ADJUSTMENT below instead of forcing the low-confidence
    automatic result

Step 7 — CDN Distribution
  — All variants pushed to CDN edge nodes on upload
  — Images served from CDN at all times; never directly from
    origin storage
  — Cache headers set for long-lived caching (originals are
    immutable; new upload = new URL)

Step 8 — Adaptive Serving
  — Client declares device pixel ratio (DPR) and viewport width
  — Server (or CDN) selects optimal variant per request
  — Mobile devices on cellular networks receive smaller variant
  — Retina displays receive 2x variant automatically
  — Implementation: responsive image tags with srcset, or
    dynamic CDN URL parameters (e.g. Cloudflare Image Resizing,
    Imgix, or equivalent)

------------------------------------------------------------
MANUAL CROP ADJUSTMENT — EXCEPTION PATH (new, V2, from OA-ZYRA-130)
------------------------------------------------------------

Per Founder decision 2026-07-25: manual cropping is available only
when one of two conditions is met — it is never the default path.

**Condition 1 — Low AI confidence:** Step 6 could not confidently
produce a good automatic crop (see Step 6, low-confidence routing
above).

**Condition 2 — User-initiated:** the user has already seen ZYRA's
automatic result and explicitly chooses to adjust it afterwards
(e.g. from their profile settings) — never presented as a required
step during upload.

When either condition is met, the crop editor from OA-ZYRA-130's
original proposal applies:
  — Uses the exact same aspect ratio as the display context (e.g.
    Browse card)
  — User can pinch to zoom, drag to reposition, and preview exactly
    how the photo will appear
  — A visual "safe area" overlay indicates where the user's face
    should ideally sit, accounting for overlapping UI elements
    (status bar, navigation controls, profile name/age, action
    buttons, bottom navigation bar)
  — Crop settings are saved as metadata (zoom level, horizontal
    position X, vertical position Y) rather than permanently
    cropping the original — the original is always retained
    unmodified, so the crop can be recreated or re-adjusted without
    quality loss

------------------------------------------------------------
AI QUALITY EVALUATION
------------------------------------------------------------

Upon upload, ZYRA privately evaluates photo quality and
provides non-judgmental, helpful feedback to the user.

The AI evaluates:
  — Blur / sharpness
  — Face visibility and clarity
  — Lighting quality (underexposed, overexposed, backlit)
  — Face proportion in frame (too distant, too close)
  — Whether the primary subject is the user

Feedback is private to the uploader. It is never shown
to other users and never used to rank or penalise profiles.

Response tiers:

  PASS — No feedback shown. Photo approved automatically.
    Example: "Great choice. This photo looks great."
    (shown briefly, then dismissed)

  SOFT GUIDANCE — Photo accepted but suggestion offered.
    Example: "Your photo is slightly blurry. A clearer
    photo will look better in full-screen browsing."
    Example: "Your face is a little difficult to see
    because of the lighting. Try a photo with natural
    light facing you."
    User can dismiss and keep the photo, or replace it.

  REJECT — Photo does not meet minimum quality threshold.
    Example: "This photo is too low resolution to display
    well. Please upload a clearer photo."
    User must replace before the photo can be added.

  FLAG — Photo requires human moderation before approval.
    (Triggers silently in background — no user feedback
    for safety reasons)
    Reasons: no face detected, multiple faces, potential
    guideline violation, inappropriate content, safety or
    authenticity concern (see next section).

Tone principles:
  — Never critical or shame-inducing
  — Always framed as helping the user present well
  — Short, friendly, plain language
  — Jost font / ZYRA design language if displayed in-app

------------------------------------------------------------
SAFETY & AUTHENTICITY SCREENING (new, V2, from OA-ZYRA-131)
------------------------------------------------------------

Runs alongside AI Quality Evaluation, before the Moderation
Decision below. This is distinct from quality evaluation (which
judges *how good* a legitimate photo looks) — this stage judges
*whether the photo should exist on the platform at all*.

**Safety screening** — checks for:
  — Nudity or sexually explicit content, partial nudity,
    pornographic or suggestive content
  — Violence, gore, weapons, drugs or drug use
  — Hate symbols or extremist imagery, illegal content
  — Offensive gestures, graphic injuries
  — Embedded text within the image (optional check)
  Clear violations are auto-rejected — no manual review needed for
  unambiguous cases.

**Authenticity checks** — detects whether the image is likely to be:
  — AI-generated, a meme, a screenshot, a stock image, a logo
  — A celebrity photo, a landscape with no person, a pet-only photo
  — A cartoon/illustration, multiple unrelated people, or
    excessively edited/filtered
  Depending on confidence: auto-reject, queue for manual review, or
  prompt the user to upload a different photo.

------------------------------------------------------------
MODERATION DECISION & MANUAL REVIEW
------------------------------------------------------------

Merges the previous "Photo Review & Approval Flow" and OA-131's
"Manual Review (Exception Queue)" into one decision point, per the
Canonical Pipeline Order above.

Upload → Pipeline (Steps 1–8, including Face Detection & Smart Crop,
with Manual Crop Adjustment routed in per exception conditions) → AI
Quality Evaluation → Safety & Authenticity Screening → Decision:

  ↓
  PASS / SOFT GUIDANCE (quality) + no safety/authenticity concern
    → Photo added to profile (pending)
  REJECT (quality) or clear safety/policy violation
    → User prompted to re-upload
  FLAG (quality) or borderline safety/authenticity confidence
    → Queued for human moderation review

**Manual review only covers genuinely uncertain cases** — low AI
confidence, possible cultural clothing confusion, borderline
suggestive images, potential impersonation, or user appeals after
rejection. This keeps the human-review percentage low by design.

Profile not live until:
  1. Minimum 3 photos pass review
  2. At least one photo is approved by moderation
     (automated + human for flagged items)
  3. ID verification complete

While photos are under review:
  — "· Photos are being reviewed in the background."
    (amber dot, subtle, shown on photo screen during onboarding)
  — Profile remains in pending state
  — User notified when photos are approved and profile goes live

**Post-approval reporting** (cross-reference, unchanged by this
merge): even after approval, users can report an inappropriate
photo via the Browse-screen Report action — see
`APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V4.md` §Profile Actions
(DR-ZYRA-095). Reported photos can be temporarily hidden, re-enter
this moderation flow, or lead to warnings/restrictions for repeat
violations.

------------------------------------------------------------
PHOTO GUIDELINES (USER-FACING)
------------------------------------------------------------

Communicated during onboarding (Chapter 2 — Your Profile):

  ✓ Clear, recent photos of yourself
  ✓ Your face clearly visible
  ✓ Well-lit, in focus
  ✗ Group photos
  ✗ Photos with children
  ✗ Filters that significantly alter appearance
  ✗ Text or watermarks overlaid on image
  ✗ Screenshots or low-resolution images

------------------------------------------------------------
COST CONSIDERATIONS (new, V2, informational — from OA-ZYRA-131)
------------------------------------------------------------

Commercial AI moderation APIs typically cost approximately
$0.001–$0.01 USD per image depending on provider/features:
10,000 uploads ≈ $10–$100; 100,000 uploads ≈ $100–$1,000; 1,000,000
uploads ≈ $1,000–$10,000. Informational only — does not change the
pipeline design, since only a small percentage of uploads should
require human review by design.

------------------------------------------------------------
TECHNICAL NOTES
------------------------------------------------------------

Storage
  — Cloud object storage (S3-compatible)
  — All buckets private; images served exclusively via CDN
  — Originals never publicly accessible

Processing
  — Recommended: Sharp (Node.js) or Pillow (Python) for
    server-side image processing
  — Face detection: AWS Rekognition, Google Vision API,
    or equivalent
  — AI quality evaluation: custom model or Vision API
    quality scoring
  — Safety/authenticity screening (new, V2): commercial moderation
    API (vendor selection deferred to build phase — see Approved
    Future Work in APP/Profiles/Summary.md)

CDN
  — Cloudflare Images / Imgix / AWS CloudFront recommended
  — Dynamic resizing via URL parameters reduces storage of
    pre-generated variants where CDN supports it

URL Structure (suggested)
  — images.zyra.app/{user_id}/{photo_id}/{variant}.webp
  — Signed URLs for private/moderation-only access

------------------------------------------------------------
SUMMARY
------------------------------------------------------------

The user experience:    Upload Photo → review ZYRA's automatic
                        result → done (manual adjustment available
                        only as an exception, never required).
The platform guarantee: Every image is crisp, optimised,
                        safe, authentic, and consistent everywhere
                        it appears across ZYRA.

------------------------------------------------------------
VERSION HISTORY
------------------------------------------------------------

V1 | 2026-06-28 | Initial Image Handling Standard.
V2 | 2026-07-25 | Merged OA-ZYRA-130 (manual crop, as an exception
    path only — Founder decision) and OA-ZYRA-131 (Safety &
    Authenticity Screening stage, Cost Considerations) into one
    canonical pipeline, resolving the conflict flagged in
    APP/Profiles/Summary.md the same day. See DR-ZYRA-096.
