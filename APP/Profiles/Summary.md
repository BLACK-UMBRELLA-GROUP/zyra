FEATURE NAME
PROFILE PHOTO — DISPLAY, CROPPING & MODERATION
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
proposal and `IMAGE_HANDLING_CURRENT_VERSION_V1.md`'s fully-automatic
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
`BROWSE_UX_SPEC_CURRENT_VERSION_V3.md`.

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
- **Browse** (`APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V3.md`) —
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
