---
id: DOC-ZYRA-0056
type: SPEC
status: CURRENT
feature: APP: PROFILES
purpose: Profiles — Summary: PROFILE PHOTO — DISPLAY, CROPPING & MODERATION
links: []
owner: ZYRA chat
---

FEATURE NAME
PROFILE PHOTO — DISPLAY, CROPPING & MODERATION

**Current two-gallery direction — 22 October 2026 / vLAbkO:** Protected Profiles
Page options offers Details first (default) or Original photos. Details first
shows supplied public identity on its first photo-free card only, followed by
clean photographs with no duplicate identity/dark scrim. Original photos has no
details card and retains its original photo identity. The shared owner preview
follows the protected choice without gaining actions or new photo/data access;
ordinary preview defaults stay Details first. Mode-aware markers, paging,
memory restoration and stale-action guards retain existing half taps/swipes,
quiet motion and the single sent-only outline. Own Profile Browse Preview
Handover owns evidence; fresh 41-suite/930-case qualification passes and IRY3d7
is installed/native POST-verified on the paired iPhone, not
moderation, consent, heritage projection or live-feed authority. Dated prior
layout/delivery sections below remain history beneath this narrow amendment.

**Latest bounded refinement — 22 October 2026 / pz6Em4:** Actual photo pages
use physical left-half Previous/right-half Next, with centre counted right;
details keeps tap-to-next and existing swipes. The permanent rectangular details
outline/inner radius is removed, leaving shared viewport clipping and one
sent-only 5px outline across details/photos; the person halo remains. Fresh
34-suite/700-case qualification passes and XDoe7z is installed/native POST-verified.
This resolves only the dated pending follow-up below. The Own Profile Browse
Preview Handover and packet's QUALIFICATION_RESULT/DELIVERY_NATIVE_FACTS own exact
evidence; physical/VoiceOver acceptance and existing integration gates remain.

**Latest bounded Founder selection — 22 October 2026:** The shared current
Profiles card and Preview my profile now put public details first, followed by
the existing photos on horizontal swipe/tap. No photograph is shown on details.
Absent public heritage, age or withheld city is omitted. This is presentation
only, not new consent/capture/moderation or live feed authority. The existing
photo renderer, editor and full-photo viewers keep their boundaries. Exact
gallery/photo position separation, checks and delivery are owned by
`ZYRA_OWN_PROFILE_BROWSE_PREVIEW_HANDOVER_CURRENT_VERSION_V1.md`. The details-first
baseline passes 33 distinct suites/576 app cases and is installed in TRvc9C with
native POST verification; Founder physical/VoiceOver acceptance remains separate.
The later Founder request for left/right-half photo taps and removal of the
duplicate permanent details outline is PENDING a separate packet, not part of
that delivered baseline.
Group: 4 — Page Responsibilities
Summary Version: V2
Status: 🟢 Finalised
Governed By: ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4 (no relationship-state
             impact — this feature operates entirely within No
             Relationship / Browse behaviour, see Related Features)
Depends On: IMAGE_HANDLING_CURRENT_VERSION_V2 (canonical pipeline —
             this document cites it, does not restate it, per
             SUMMARY_STANDARD_CURRENT_VERSION_V3 §5.1),
             BROWSE_UX_SPEC_CURRENT_VERSION_V3 (Profile Card display
             and Report/Hide/Block)

**Resolution note (2026-07-25) — DR-ZYRA-096:** V1 of this document
flagged a direct conflict between OA-ZYRA-130's manual crop editor
proposal and `IMAGE_HANDLING_2026-07-25_V1.md`'s fully-automatic
philosophy, and held Status at 🔴 rather than filing either as
settled. Raised to ChatGPT and the Founder; both independently
recommended the same resolution — keep the automatic pipeline as
default architecture, treat manual crop as a narrow exception, and
merge the two moderation pipelines into one. That merge is now filed
directly into `IMAGE_HANDLING_CURRENT_VERSION_V2.md` (the platform-
wide owning document — see its Scope section, applying to Browse,
Profile view, Journey, Guardian view, Notifications, and Admin tools, not
just Profiles). Per the ownership test (SUMMARY_STANDARD_
CURRENT_VERSION_V3 §5.2 — a fact that more than one APP feature needs
is owned by the layer above them), this document now cites that
standard rather than duplicating it, to avoid the two documents
drifting apart again the way V1 of this document briefly did.

============================================================
SUMMARY
============================================================

### Section 1 — Feature Overview

Defines how profile photos are displayed and handled specifically
within the Profiles feature. The actual image processing, cropping,
and safety/moderation pipeline is owned by
`IMAGE_HANDLING_CURRENT_VERSION_V2.md` (platform-wide) — this
document describes how Profiles consumes that pipeline's output, not
a separate pipeline of its own.

### Section 2 — User Experience

**Latest bounded Founder own-preview/Profiles direction, 18 October 2026 —
OA-ZYRA-151/304:** Preview my profile uses exactly the shared current Portrait
Profiles header, photo card, public identity, footer and bottom-navigation
geometry. Back arrow/text replaces the Profiles heading in that same row;
there is no “My profile” or discovery title, top-right three-dot menu or extra
Back strip. The Previous / Request a Journey / Next footer and five-tab
navigation remain visible to show the public presentation, but cannot activate
requests, decisions, navigation, unread acknowledgement, focus or haptics.
The first Profiles nav item is highlighted; it is not the Profile tab. There
is no Save action or self-report/menu flow. Photo paging remains available.

The shared read-only presenter also suppresses caller request-label,
invitation and eligibility evaluators, not just taps. Supplied public
nationality/ethnicity render as on Profiles. The detached protected persona's
British/Pakistani labels are explicit invented public display facts, never
inferred from private compatibility answers or real identity. Ordinary
AppState currently supplies no public heritage fields: missing public values
stay omitted under OA-ZYRA-306, not guessed or borrowed from private data.

Inline Back and physical left-edge right-swipe share the existing guarded
return owner; a nested cue may pass its inline binding through without owning
a second return. Back scrolls with the heading rather than remaining sticky;
edge return stays available. The protected Pull comparison remains optional.
This does not replace peer/Guardian linked-person photo viewers, hydrate new
member fields or relax account/photo admission and restoration protections.
The visible discovery name is now Profiles; existing browse route/storage
identifiers and feature authorities are not renamed. Exact implementation,
qualification and next combined delivery are owned by
`ZYRA_OWN_PROFILE_BROWSE_PREVIEW_HANDOVER_CURRENT_VERSION_V1.md`.

**Earlier 18 October own-preview direction — preserved history:** the initial
shared Portrait Browse card replaced the older full-screen own viewer with
photo paging and public identity, while omitting the footer/navigation controls.
The latest direction above supersedes that visual omission only; its read-only
and account-lifetime boundaries remain.

**Founder editor instruction, 17 October 2026 — OA-ZYRA-151/304:** The
Photos editor shows one extra swipe page after the last real photo while
there are one to four photos. A large gold plus and “Add a new photo” open
the existing reviewed add-photo flow. At five photos there is no extra
page; paging stops at the final photo. The empty-gallery entry remains.
This is an editor new-add ceiling, not a silent change to the separate
onboarding three-to-six rule or server storage policy. Existing six-photo
galleries remain viewable/editable and are not truncated. Guardian signup
still requires its existing single first photo.

Default flow: user uploads one photo; ZYRA's automatic pipeline
handles resolution, cropping, and optimisation; the user reviews the
result. Manual crop adjustment is available only as an exception —
low AI crop confidence, or the user explicitly choosing to adjust
afterwards from profile settings. Full detail:
`IMAGE_HANDLING_CURRENT_VERSION_V2.md` §MANUAL CROP ADJUSTMENT —
EXCEPTION PATH. Upload status shown to the user (Uploading... →
Checking photo... → Approved / Needs another photo / Under review) is
also defined there, §MODERATION DECISION & MANUAL REVIEW.

### Section 3 — Functional Specification

Not restated here — see `IMAGE_HANDLING_CURRENT_VERSION_V2.md` for
the full processing pipeline (8 steps), Safety & Authenticity
Screening, and Moderation Decision flow. Profiles-specific behaviour:
photos display using `BoxFit.cover` or equivalent within this
feature's screens, consistent with the Browse card display defined in
`BROWSE_UX_SPEC_CURRENT_VERSION_V4.md`.

### Section 4 — Business Rules

- A photo may not be visible on any Profile screen until it has
  cleared `IMAGE_HANDLING_CURRENT_VERSION_V2.md`'s Moderation
  Decision — no Profiles-specific exception to that rule.
- Crop is non-destructive at the platform level (owned by
  IMAGE_HANDLING); Profiles does not maintain its own copy of crop
  metadata.

### Section 5 — Related Features

- **Image Handling Standard**
  (`APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md`) — owning
  document for the full processing, cropping, and moderation
  pipeline. See Depends On above.
- **Browse** (`APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V4.md`) —
  consumes processed photos for the Profile Card; also owns the
  Report/Hide/Block UI that photo reports feed into.
- **Safety** (`APP/Safety/SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3.md`)
  — this feature's moderation philosophy (context-aware, confidence-
  based escalation, human review before serious action, explainability)
  is consistent with, but architecturally separate from, that
  document's in-conversation safety system.

### Section 6 — Design Decisions

Source: ChatGPT UX review, 2026-07-19 (OA-ZYRA-130, OA-ZYRA-131).
Conflict found and raised 2026-07-25; resolved the same day by
Founder decision, filed into `IMAGE_HANDLING_CURRENT_VERSION_V2.md`.
See DR-ZYRA-096, `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md`.

### Section 7 — Current Status

**Current own-preview overlay, 18 October 2026:** The latest exact shared
Profiles presentation, inline captured Back and inactive footer/navigation are
implemented in Source under
`OA151_PROFILES_PREVIEW_SWIPE_2026_10_18.Y2tRa0`, with final fixture-only
qualification continuations KgoiVq/xzE48Q preserving original PRE and failures.
The latest seven corrected suites pass 66 focused cases. Final xzE48Q analysis
is clean; 63 disjoint app suites pass 1,399 distinct literal cases without
failures/skips/cancellations, with 46 separate recipe controls. Overlapping
visual replays pass and the primary opens all 73 final frames; the Quiet
Refresh Handover records the outgoing-fixture overlay caveat. All 53 changed
Dart paths format unchanged; policy and 24 index tests pass. Packaging
preflight safely refuses the OA151 packet name at its unchanged OA305 prefix
guard; that failed stage remains preserved. Exact unchanged delivery envelope
`OA305_LOCKSCREEN_HANDOFF_2026_10_18.4oS3WH` subsequently passes fresh
BUILD_PREFLIGHT after independent copy/lineage verification. Own Profile
Handover §5.3 records the exact plan and preservation facts; no guard changes.
The exact new 4oS3WH/bjV1Jf contained build, compiler and main-identity checks
pass; the initial same-phone LOCK finds the phone locked. No install/launch occurs;
one current-candidate unlock question is issued. Own Profile Handover §5.4
records exact hashes and the genuine hold. No full-app performance or Founder
physical acceptance is inferred.
After the Founder's unlock, fresh LOCK_2 passes by 13:47:47.035 UTC on 18 October.
One unchanged bjV1Jf INSTALL runs 13:47:49.739–13:48:06.533 UTC, native LAUNCH
13:48:10.810–13:48:22.828 UTC and exact POST 13:48:23.034–13:48:27.976 UTC.
POST confirms container `EB7BC016-3BA3-463B-B77B-5E39B0E633E4`, PID 20140,
with the same main identity. bjV1Jf is now the verified installed baseline;
8nnkwr/Mh96lJ is prior history. Own Profile Handover §5.3–5.5 owns unchanged
artifact/plan/seal/compiler facts and both the preserved hold and positive
delivery. No new tests, Source/recipe edit, rebuild, data reset or upload occurs.
The loading/preview/swipe physical recheck remains PENDING under the existing
actions; no full-app performance or Founder acceptance is claimed. Google
stays paused before Q4.
Earlier `OA151_OWN_BROWSE_PREVIEW_2026_10_18.ZR7BI1` and full-screen own-preview
evidence are historical; other full-photo viewers remain unchanged. Public
heritage availability for the ordinary member model remains OA-ZYRA-306.

**Current editor overlay, 17 October 2026:** The retained picker/crop/save
editor exists in Source. The following July specification baseline is
historical and must not be read as saying no editor exists today. The new
swipe-to-add presentation is bounded to that retained editor; it does not
complete the separately governed moderation pipeline. Source qualification,
exact changed paths and queued delivery status are recorded in Navigation
Haptics §106 and packet `OA151_PHOTO_ADD_PAGE_2026_10_17.T3Jdke`.

Approved Specification (by citation to IMAGE_HANDLING_
CURRENT_VERSION_V2.md). Not yet built — no crop editor, moderation
pipeline, or safe-area overlay exists in `SOURCE/` yet. Implementation
requires a separate build phase and explicit Founder authorisation to
begin, per this session's execution-scope rule.

### Section 8 — Approved Future Work

Not yet defined. Vendor selection for the AI moderation/authenticity
service and exact confidence thresholds are implementation decisions
deferred to the build phase (see IMAGE_HANDLING_CURRENT_VERSION_V2.md
§TECHNICAL NOTES).

============================================================
APPROVED TO-DO LIST
============================================================
(None listed — add as decisions are made during implementation
planning.)
