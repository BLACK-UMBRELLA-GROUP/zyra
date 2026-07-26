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
Upgrade, Wali screens — see DR-ZYRA-101). Onboarding correctly
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
• Male Wali

FEMALE THEME
Gradient: #D4868F → #3D2A4A
Used for:
• Female Seeker
• Female Wali

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
