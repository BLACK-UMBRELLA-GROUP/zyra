> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Replaced on 2026-10-25 by `BUSINESS/COLOUR THEME/Summary.md` (V2), rewritten from the app code under OA-ZYRA-313.
> Archived by Fable. **The text below is unchanged** and is the record of what the document said until then.

---
id: DOC-ZYRA-0102
type: BRAND
status: CURRENT
feature: BUSINESS: COLOUR THEME
purpose: Colour Theme — Summary
links: []
owner: ZYRA chat
---

============================================================
ZYRA — COLOUR THEME (GOVERNED SUMMARY)
============================================================
Version:      V1
Status:       CURRENT_VERSION — governed (in-place promotion)
Owner:        Founder (content) · Fable (documentation filing)
Promoted:     2026-08-20 under OA-ZYRA-209 — Founder standing
              instruction; recommendation executed: governed
              headers first, filename renames deferred until the
              OA-ZYRA-201 reference-stability decision.
Supersession: This file is the single current version of this
              system summary. Any prior unversioned copies are
              superseded in place.
============================================================

FEATURE NAME
COLOUR THEME
Group: 7 — UI/UX Design
Status: 🟢 Finalised

STATUS FIELD NOTE (2026-07-25) — DR-ZYRA-094: palette finalised.
Option 1 below is the ratified final specification; Option 2 was
considered and rejected. This closes the 🔴 flag set 2026-07-19
(DR-ZYRA-093), which was accurately recording that the decision
was still open at that time — it is not open anymore.

This decision also supersedes DR-ZYRA-090's flat/no-fade
override (Luxury Dark Purple removed from active gradients,
live-testing-phase, not yet ratified). The ratified final
specification restores the gradient behaviour below — every
theme fades into Luxury Dark Purple (#3D2A4A) as originally
specified.

UPDATE (2026-07-25, same day, build authorised): the gap noted
above is closed. `SOURCE/lib/theme/zyra_colors.dart` now
implements this ratified specification (`brandGradient`,
`brandGradientMale`, `brandGradientFemale`, all fading to
#3D2A4A), and a `ZyraColors.genderGradient()` helper applies
Male/Female gradients across profile-context screens app-wide
(Profile, Matches, Match Notification, Journey Timeline, Chat,
Upgrade, Guardian screens — see DR-ZYRA-101). Onboarding correctly
stays flat/neutral throughout, per OA-ZYRA-123, unaffected by
this.

CURRENT QUIET DARK HALO SURFACES (Founder direct, 2026-10-22; OA151/304/305):
The selected/emphasis/frost/accent/glass presentation uses the normal shared
surfaceFill with a quiet 70%-opacity gold edge instead of the pale overlay.
This narrowly supersedes older pale selected-card/frost recipes below, not
the chosen Background, palette revision, semantic/destructive ink or fonts.
Expanded request cards keep a gold edge and transparent inner primary action;
active-Moment actions, circles, Journey frost pills, Timeline position chips,
Guardian monograms and Circle decorative chips/outgoing bubbles use quiet fill.
Focus, progress and glow/status meaning remain. Small gold new/unread dots
lose notification paint only; counts/semantics/acknowledgement, gold navigation
artwork, selection/pagination and semantic icons remain.

UI Consistency/Navigation/Family Messaging handovers and packet
OA151_CIRCLE_DOTS_HALO_FINAL_2026_10_22.O8XRQc own implementation, the read-only
Unlocks capsule and full-viewport Circle layout. S0eeD4's stale Browse-label
test failure stays failed; only its lookup is repaired and runtime is unchanged.
Fresh 45 suites pass 1,019 actual unique app cases, zero failures/skips; 46
recipe cases separate. Analysis/24-path zero-change format/No-Git and 4,869
inputs/14 helpers pass. Manifest binds 136 PNGs/10 root-viewed; targeted 19
passes overlap primary. Full/control captures stay failed, separate one-await
diagnostic supports settling sensitivity only, not a runtime fix/full pass.
Initial negative LOCK remains preserved. After the Founder unlock reply, fresh
LOCK_2 and one INSTALL/LAUNCH/POST pass with unchanged Source/helpers. YmJRX6
is DELIVERED/native POST-verified at 22:57:45.000 UTC, container
49530B83-FA3B-4128-9DCF-CC5AB9F0D1FF/PID 37844; PErAL4 is prior history.
Runbook/facts own exact qualification/build/delivery pins and retained-host limits.
No all-theme AA, physical UI/VoiceOver/Founder acceptance or public release is
claimed. Other open component/typography/design-system dependencies remain;
this is the Founder's bounded change, not general Summary finalization.
Existing OAs and paused UNSENT filing remain; no new identifier or closure.

OPTIONAL MIDNIGHT BLUE BACKGROUND (Founder direct, 2026-10-22; OA-ZYRA-305):
After the four-page blue conversation study, the Founder instructs: "just add
it to personilsation section". Add Midnight blue to the shared Profile >
Personalisation > Background choices for both roles. Its app-native linear
gradient runs top-right #183F83 to bottom-left #07132B, preserving the existing
background API rather than adding the study's radial canvas layering. This is
an optional background, not a new default or a whole-app branding replacement.
Midnight Plum, the current palette revision, existing explicit preferences,
gold/semantic accents, fonts and the shared component/sheet recipes stay
unchanged. The member's deliberate selection uses the existing account-owned
local name preference; the protected comparison keeps its isolated session
intention and cannot write ordinary member preferences. Native launcher/splash
artwork and live account/backend settings do not change. UI Consistency Gate
handover owns implementation, measurements and distinct local delivery status.

CURRENT MEMBER APP GOLD OPTION (Founder direct, 2026-10-04; DR-ZYRA-258;
OA-ZYRA-257/286): Gold accents is an On/Off option in the shared Personalisation
page for Seekers and Guardians. It starts Off and remembers the bound member's
choice on this device. Same-owner cold starts restore it; logout/account
switches clear it under the existing presentation-cache policy. On adds the
existing Diagonal edge / Live drift dust behind normal app gradient canvases;
Off restores the original canvas. The developer control remains an authorized,
temporary explicit On/Off override, never a member preference writer. Member
selection clears that override; authorization revocation discards only the
override, preserving the ordinary member choice.

Opening/login gold choices, cards, photos, text, controls, palette, semantic
gold and fonts remain unchanged. Reduced motion keeps this app dust still;
inactive/background tickers pause. This does not adopt a default-On public
theme or change profile data, entitlements or backend settings. DR-ZYRA-255's
earlier developer-only scope and sequence 6108/PID 67328 delivery remain dated
history, superseded only for member availability and local persistence. The
UI Consistency Gate handover owns current implementation/delivery evidence;
Founder physical visual acceptance remains separate.

CURRENT CENTRED MODAL ALIGNMENT (Founder full-app review, 2026-10-03;
OA-ZYRA-304/257): shared centred notices/confirmations now use the same opaque
#241A2F surface as app-owned sheets/toasts, with one quiet semantic-gold edge.
This supersedes the historical transparent/blurred centred-dialog recipe only;
approved Glass Signals cards, Floating Glass navigation and deliberate developer
comparisons remain. Poppins, Syne wordmark, splash #E5CE8E, semantic gold
#E8C98A, destructive coral and current Midnight Plum are unchanged. The shared
modal remains scrollable/safe-area/keyboard aware at large text. Internal
behavior/layout checks and Founder physical visual acceptance are separate;
see ZYRA_APP_FLOW_UI_REVIEW_HANDOVER_CURRENT_VERSION_V1.md.

CURRENT ICON LETTERING ALIGNMENT (Founder direct, 2026-09-30; OA-ZYRA-257):
the ZYRA lettering on the Current app icon and ten active comparisons now
uses the main Quiet Horizon splash wordmark gold #E5CE8E. Their existing
Midnight Plum #30203F → #160E20 background and decorative treatments are
unchanged. The 2026-09-27 sentence below saying the current iPhone icon
was unchanged describes that day's initial palette migration, not today's
lettering correction. App Logo owns icon composition and the UI Consistency
Gate handover owns generated-asset verification; this Colour Theme retains
ownership of the palette. Founder physical visual acceptance is pending.

CURRENT APP-WIDE OVERRIDE (Founder direct, 2026-09-27; OA-ZYRA-257): the
Founder selected the darker Hulu-inspired splash purple for the whole app,
including every splash preview and launcher icon. The current Midnight Plum
option now uses **#30203F → #160E20**, top-left to bottom-right. This supersedes
the 2026-08-24 default below for both roles, signup, production splash,
navigation, and all twelve Current/Hulu-family previews. Matching opaque
popup/sheet/toast surface: **#241A2F**; anchored menus use that colour at 92%.
Primary action ink now uses #160E20. Glass recipes, gold, fonts, destructive
coral and status meanings are preserved. All app-owned bottom sheets still
resolve to one opaque token; this replaces the earlier #2A1F33 override below.
Native pre-Flutter launch and Android adaptive-icon backing use #160E20,
without adding a static launch logo. The current iPhone icon is unchanged;
the Founder subsequently requested Current + ten new icon studies in the
shared Home toggle. These eleven active options retain the same purple base,
locked Syne wordmark/glyph and gold accents (App Logo owns compositions).
Historical alternate assets remain preserved but are not active options.
Android/macOS/web/Windows launcher assets retain the current source design.
Founder clarification (same day): previous saved palettes must not silently
override this whole-app update. Startup now adopts Midnight Plum once per
account-owned palette revision (`dark-hulu-app-2026-09-27-v1`), replacing any
previous saved palette on that installation without resetting login, profile,
messages, font, haptic or lock preferences. Later deliberate Personalisation
choices remain available and persisted with this revision; developer choices
remain temporary. This supersedes the earlier preserve-old-palette behavior.
Historical decisions/retired assets remain
evidence, not current defaults. Implementation checks and installation are
separate from Founder visual acceptance, which remains pending.

HISTORICAL DEFAULT OVERRIDE (Founder direct, 2026-08-24): while the full palette
remains available in Developer Style, the app now launches on **Midnight Plum**
(`#684D78` → `#241A2C`) across Seeker, Guardian and signup surfaces. This is
the Founder's "for now" comparison default, not a deletion of the ratified
ZYRA Purple option. Relaunch and `Restore default style` both return to
Midnight Plum until the Founder chooses otherwise.

============================================================
SUMMARY
============================================================

Purpose:
Defines the official colour palette, gradients, and visual
identity used throughout ZYRA.

Owns:
- Global brand colours
- Colour themes
- Colour gradients
- Colour usage rules

The colour theme should create a feeling of:
• Royal
• Luxury
• Warm
• Modern
• Soft
• Trustworthy

The interface should use a Google-inspired Bubble UI with
rounded cards, rounded buttons and generous spacing.

------------------------------------------------------------
FINAL PALETTE — RATIFIED 2026-07-25 (DR-ZYRA-094)
------------------------------------------------------------

GLOBAL BRAND
Gradient: #8A6A9E → #3D2A4A
Represents:
• ZYRA Brand
• Default application theme
• Splash Screen
• Main Navigation
• Core branding

MALE THEME
Gradient: #3D5A80 → #3D2A4A
Used for:
• Male Seeker
• Male Guardian

FEMALE THEME
Gradient: #D4868F → #3D2A4A
Used for:
• Female Seeker
• Female Guardian

------------------------------------------------------------
COLOUR PALETTE
------------------------------------------------------------

| Name                | Hex       |
|---------------------|-----------|
| Royal Purple        | #8A6A9E   |
| Luxury Dark Purple  | #3D2A4A   |
| Royal Blue          | #3D5A80   |
| Rose Pink           | #D4868F   |

------------------------------------------------------------
COLOUR LOGIC
------------------------------------------------------------

Purple
• Represents the ZYRA brand and default application identity.

Blue
• Represents all male accounts.

Pink
• Represents all female accounts.

Luxury Dark Purple
• Shared luxury foundation across all themes.

------------------------------------------------------------
RATIONALE
------------------------------------------------------------

✓ Strong ZYRA identity
✓ Clear default application colour
✓ Obvious splash screen colour
✓ Premium appearance
✓ Royal feel
✓ Male and female themes remain connected
✓ Shared luxury base colour creates consistency

Using a dedicated purple brand theme gives ZYRA a recognisable
identity while blue and pink represent male and female users.
The shared Luxury Dark Purple (#3D2A4A) ties every theme
together, creating a cohesive, premium experience.

------------------------------------------------------------
REJECTED ALTERNATIVE
------------------------------------------------------------

An earlier "Option 2" (no dedicated brand colour; Male
#3D5A80 → #D4868F, Female #D4868F → #3D5A80, two-colour system
only) was considered and rejected — weaker brand identity, no
clear default/splash colour. Full comparison retained in
DR-ZYRA-094, SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md.

============================================================
APPROVED TO-DO LIST
============================================================
(None listed in source — add as decisions are made.)

---

## Component colour rules — ADDED 2026-08-12 (Frost UI pass, Founder-approved 2026-08-11)

**Current bottom-sheet override — Founder direct, 2026-09-27:** all app-owned
bottom sheets use the opaque dark plum surface `#2A1F33` shown in the
Founder's approved Past Journey summaries screenshot. This supersedes the
Royal-to-Luxury gradient bottom-sheet row below. The one implementation owner
is `ZyraColors.modalSheetSurface`; older `waliSheetBg`, `sheetSurface` and
`sheetGradient` accessors resolve to that same surface. The developer-only
light palette uses `#F7F2F8`. Rounded geometry may vary with the flow; the
sheet surface colour must remain consistent. Device install confirmation is
separate from successful app launch. Trace: OA-ZYRA-257.

The 2026-08-11 screenshot review ("some buttons are one colour and some are
another and some dont feel like the app culture… I want a clean UI") ratified an
app-wide component system, implemented the same night. Recorded here so the
palette file and the app stop disagreeing; formal re-issue of this document can
fold these into the tables above.

| Purpose | Value | Rule |
|---|---|---|
| Primary action fill | Pastel Grey Lavender `#CEA2D1` | Every primary button, BOTH gender themes. NEW palette entry — pending formal ratification into the table above; it was Founder-approved via the Frost UI brief and is live app-wide. |
| Text on primary | Luxury Dark Purple `#3D2A4A` | Always. Never white on the lavender fill (~2:1 — fails accessibility; plum is 5.8:1). |
| Anchored menus (Journey ⋮ etc.) | Luxury Dark Purple @ 92% + blur σ30 | Dark plum glass — anchored menus have no dimming barrier and float over the gradient's palest region, where white glass fails. |
| Bottom sheets | Royal Purple `#8A6A9E` @ 90% → Luxury Dark Purple @ 96%, vertical, + blur σ30 | Founder 2026-08-11: "pic 2 should be purple." Flat 88% plum over a photo compounded to grey. |
| Centred dialogs | white 14% fill · white 22% border · blur σ30 · radius 24 | Unchanged ratified glass (zyra_glass_dialog.dart). |
| Frost pills | white 10% fill · white 18% border; selected 28%/12% | Sampled from the Connections segmented control. |
| Destructive accents | `#E08080` coral (`ZyraColors.destructive`) | Menus, sheets and dialogs. |
| Retired | `#1A1220` near-black | Fully swept from the client 2026-08-11; never ratified. |

Tokens live in `SOURCE/lib/theme/zyra_colors.dart` (frost/action block, 2026-08-11).
