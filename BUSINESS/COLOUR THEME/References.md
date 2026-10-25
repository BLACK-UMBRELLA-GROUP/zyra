---
id: DOC-ZYRA-0101
type: BRAND
status: CURRENT
feature: BUSINESS: COLOUR THEME
purpose: Colour Theme — References
links: []
owner: ZYRA chat
---

FEATURE NAME
COLOUR THEME

============================================================
REFERENCES
============================================================

------------------------------------------------------------
References (depends on)
------------------------------------------------------------

Branding (BUSINESS/BRAND MESSAGING)
• Colour theme supports brand positioning (premium, trustworthy).
• Purple aligns with ZYRA brand identity.
• Status: Referenced — definition lives in BUSINESS/BRAND MESSAGING.

------------------------------------------------------------
Referenced By
------------------------------------------------------------

APP LOGO (BUSINESS/APP LOGO)
• Purple is the primary logo background colour.
• Blue and pink are supporting colours.
• This document is the source of truth for those values.

BRAND MESSAGING (BUSINESS/BRAND MESSAGING)
• Brand Messaging references the purple brand colour.
• Hex values defined here.

All User-Facing Pages
• Colour themes applied throughout the app.

Optional Midnight blue (Founder direct, 2026-10-22; OA-ZYRA-305)
• Summary.md owns the additional Personalisation Background tokens and scope.
  This adds a dark choice without changing Midnight Plum, palette revision,
  shared component/sheet recipes or gold. UI Consistency Gate handover owns
  exact Source, preference/preview isolation, checks and local-delivery truth.
• The four-page conversation study remains illustrative; its radial canvas and
  independently recoloured cards are not a new app-wide component contract.

Member App Gold Option (DR-ZYRA-258, 2026-10-04)
• `SOURCE/lib/dev/zyra_app_gold_preview.dart` adds the independently switched
  onboarding dust behind normal app gradient canvases. Shared Personalisation
  owns the default-Off member control; `theme/zyra_app_gold_style.dart` and
  owner-bound local preferences save its choice on this device. Shared Developer
  Home retains only a temporary authorized override. Opening/login dust controls
  remain unchanged; no default-On public theme adoption is implied.
• Existing `dev_onboarding_gold_design.dart` owns the reused Diagonal edge /
  Live drift composition. Colour Theme still owns its palette, not the helper.
• UI Consistency Gate handover and OA-ZYRA-257 own internal evidence and
  the 2026-10-04 local phone delivery and pending Founder visual acceptance.

Design System
• Colour tokens sourced from this document.

Component Library
• UI components use colours defined here.

Splash Screen
• Global brand gradient (#8A6A9E → #3D2A4A) applied here.

Icons
• Icon colours follow the colour logic defined here.

------------------------------------------------------------
Overlap Flags
------------------------------------------------------------

⚠️ BUSINESS/APP LOGO
- App Logo previously flagged App Colour Theme as an
  unresolved dependency. This document resolves that.
- App Logo References.md updated to point here.

------------------------------------------------------------
Open Dependencies
------------------------------------------------------------

• Exact colour tokens for UI components not yet defined.
• Typography and spacing not yet documented.
• Design system document not yet created.
• Component library not yet created.
• RESOLVED 2026-07-25 (DR-ZYRA-094): Option 1 vs Option 2 —
  Option 1 ratified as final palette, Option 2 rejected. See
  Summary.md (Status: 🟢 Finalised) and DR-ZYRA-094.
