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
