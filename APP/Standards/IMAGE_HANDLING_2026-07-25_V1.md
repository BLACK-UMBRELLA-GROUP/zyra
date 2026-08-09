FEATURE NAME
ZYRA — Platform Standards
Document: Image Handling Standard

============================================================
IMAGE HANDLING STANDARD
============================================================

Status: SUPERSEDED 2026-07-25 by IMAGE_HANDLING_CURRENT_VERSION_V2.md
Last Updated: 2026-06-28

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
upon upload.

The only user interaction is: Upload Photo.

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
SERVER-SIDE PROCESSING PIPELINE
------------------------------------------------------------

Every uploaded image passes through the following pipeline
automatically upon receipt. The user sees none of this.

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
  — Generate thumbnail crops centred on face
  — Original image remains uncropped for full-profile display
  — If no face detected: flag for manual review before approval
  — If multiple faces detected: flag for review (may violate
    platform photo guidelines)

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
AI PHOTO QUALITY EVALUATION
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
    guideline violation, inappropriate content.

Tone principles:
  — Never critical or shame-inducing
  — Always framed as helping the user present well
  — Short, friendly, plain language
  — Jost font / ZYRA design language if displayed in-app

------------------------------------------------------------
PHOTO REVIEW & APPROVAL FLOW
------------------------------------------------------------

Upload → Pipeline (Steps 1–8) → AI Quality Evaluation
  ↓
  PASS / SOFT GUIDANCE → Photo added to profile (pending)
  REJECT              → User prompted to re-upload
  FLAG                → Queued for human moderation review

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

The user experience:    Upload Photo → done.
The platform guarantee: Every image is crisp, optimised,
                        safe, and consistent everywhere it
                        appears across ZYRA.
