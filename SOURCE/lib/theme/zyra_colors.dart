// ZYRA brand colours and background gradients.
// Source of truth: ZYRA/BUSINESS/COLOUR THEME/Summary.md and
// APP/Onboarding/SEEKER ONBOARDING QUESTIONS/Onboarding Rules & UX.md
// (§ COLOUR SYSTEM). Do not invent new colours here — every value below
// traces to one of those two documents.

import 'package:flutter/material.dart';

/// Which gender-derived background variant to show. `neutral` is used only
/// for the very first onboarding question (before gender is known).
enum ZyraBackgroundVariant { neutral, male, female }

class ZyraColors {
  ZyraColors._();

  // Brand palette
  static const Color royalPurple = Color(0xFF8A6A9E);
  static const Color luxuryDarkPurple = Color(0xFF3D2A4A);

  // Accent (selected options — purple, all themes)
  static const Color accentBg = Color(0x249A72BE); // rgba(154,114,190,0.14)
  static const Color accentBorder = Color(0x669A72BE); // rgba(154,114,190,0.4)

  // Progress bar
  static const Color progressFill = Color(0x47FFFFFF); // rgba(255,255,255,0.28)
  static const Color progressTrack = Color(
    0x12FFFFFF,
  ); // rgba(255,255,255,0.07)
  static const Color progressCompleteFill = Color(
    0x9950B478,
  ); // rgba(80,180,120,0.6)

  // Icon buttons
  static const Color iconButtonBg = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const Color iconButtonBorder = Color(
    0x24FFFFFF,
  ); // 0.5px rgba(255,255,255,0.14)

  // ---------------------------------------------------------------------
  // FROST / ACTION TOKENS — ADDED 2026-08-11 (Founder, screenshot review:
  // "some buttons are one colour and some are another and some dont feel
  // like the app culture… I want a clean UI"; Frost UI brief, Fable
  // session 2026-08-11).
  //
  // Until now every FilledButton in the app wore Material 3's STOCK dark
  // baseline primary (#D0BCFF periwinkle) because main.dart never set a
  // ColorScheme — the "blue" button the Founder flagged on the
  // Compatibility Reveal screen was Flutter's default, not a ZYRA
  // decision. The rating chips on the phase-reveal screen rendered
  // near-black for the same reason (stock M3 dark chip surface).
  //
  // The frost values below are SAMPLED, not invented — they are the
  // Connections screen's own segmented control and the ratified glass
  // card, promoted from per-file literals to named tokens:
  //
  //   frostFill/frostBorder        connections_screen.dart segmented
  //                                container (white 10% / 18%)
  //   frostSelectedFill/…Border    its selected pill (white 28% / 12%)
  //   glassFill/glassBorder        zyra_glass_dialog.dart's ratified
  //                                card (white 14% / 22%, blur σ30)
  //
  // primaryAction is the one deliberate NEW colour: Pastel Grey Lavender,
  // the brand accent from product canon (Aug 2026) that is not yet
  // written into the two colour documents this file's header names.
  // EXCEPTION TO THE HEADER RULE, knowingly: added on Founder direction
  // via the approved Frost UI brief (2026-08-11); ratify it into
  // BUSINESS/COLOUR THEME/Summary.md, or deny and swap this one constant.
  // Text on it is Luxury Dark Purple (5.8:1, passes WCAG AA) — NEVER
  // white, which is ~2:1 on this fill and was the failing pairing on the
  // old stock button.
  //
  // destructive replaces the 0xFFE08080 coral that already appears as a
  // literal 20+ times across 9 files (End Journey, etc.) — same value,
  // now named. journey_flow_screen is migrated; sweep the rest as each
  // file comes up for review.
  // ---------------------------------------------------------------------

  /// Primary action fill — Pastel Grey Lavender, both gender themes.
  static const Color primaryAction = Color(0xFFCEA2D1);

  /// Text/icon colour ON [primaryAction]. Always this, never white.
  static const Color onPrimaryAction = luxuryDarkPurple;

  /// Destructive text/accents (End Journey coral).
  static const Color destructive = Color(0xFFE08080);
  static const Color destructiveBorder = Color(0x66E08080); // coral 0.4

  // Frost pills — sampled from the Connections segmented control.
  static const Color frostFill = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const Color frostBorder = Color(0x2EFFFFFF); // rgba(255,255,255,0.18)
  static const Color frostSelectedFill = Color(
    0x47FFFFFF,
  ); // rgba(255,255,255,0.28)
  static const Color frostSelectedBorder = Color(
    0x1FFFFFFF,
  ); // rgba(255,255,255,0.12)

  // Glass cards — the ratified zyra_glass_dialog recipe (blur σ30).
  static const Color glassFill = Color(0x24FFFFFF); // rgba(255,255,255,0.14)
  static const Color glassBorder = Color(0x38FFFFFF); // rgba(255,255,255,0.22)

  // ---------------------------------------------------------------------
  // CORRECTED 2026-08-11, same-day (Founder, on-device: "the top right
  // isnt clear"). The Journey ⋮ menu shipped that morning wearing
  // glassFill — white 14% — which is fine for a CENTRED dialog because
  // the black-55% barrier darkens everything behind it first. An
  // anchored menu has NO barrier (the ratified no-dim rule in
  // anchored_card_overlay.dart) and hangs at the TOP of the screen,
  // where the gender gradient is at its lightest — white text on white
  // glass over pale rose, and the coral End Journey row disappeared
  // into it entirely.
  //
  // Anchored menus therefore wear dark plum glass: Luxury Dark Purple at
  // 92% + blur, the same ratified family as sheetSurface below. White
  // and coral text both pass on it over ANY gradient region.
  // ---------------------------------------------------------------------

  /// Anchored floating menus (Journey ⋮, etc.) — dark plum glass.
  static const Color menuSurface = Color(0xEB3D2A4A);

  // ---------------------------------------------------------------------
  // Bottom sheets go PURPLE — 2026-08-11 (Founder, on the stage-7
  // Help/Report sheet over a dark photo: "pic 2 should be purple").
  // sheetSurface (Luxury Dark Purple @88%) compounds with whatever is
  // behind it — over a dark photo it lands as a desaturated grey-plum
  // that no longer reads as the brand. A sheet should be UNMISTAKABLY
  // ZYRA purple wherever it rises. So: a vertical fade from Royal Purple
  // into Luxury Dark Purple — the ratified brandGradient's own two
  // stops — at high opacity, with the blur keeping a hint of the photo
  // underneath. Both colours ratified; only the alphas are new.
  // ---------------------------------------------------------------------

  /// Bottom-sheet surface — Royal Purple fading into Luxury Dark Purple.
  static const LinearGradient sheetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xE68A6A9E), Color(0xF53D2A4A)], // royal @90% -> luxury @96%
  );

  // ---------------------------------------------------------------------
  // Sheets, dialogs and toasts — ADDED 2026-08-01 (Founder: "why isn't it
  // following the colour system").
  //
  // Every bottom sheet and dialog in the app had `Color(0xE01A1220)`
  // hardcoded — 19 occurrences across 11 files. That value appears in no
  // ratified document. It is a near-black plum that predates DR-ZYRA-094
  // and simply never got revisited when the palette was finalised.
  //
  // The correct base is Luxury Dark Purple (#3D2A4A): BUSINESS/COLOUR
  // THEME/Summary.md ratifies it as the colour EVERY theme fades into, so
  // a surface anchored to the bottom of the screen sitting in that colour
  // is continuous with whatever gradient is behind it, instead of
  // punching a darker hole through it.
  //
  // NOTE (2026-08-01): only report_profile_sheet, help_report_sheet and
  // the global SnackBar theme used this at first — the other files kept
  // the old literal, deliberately, until each page came up for review.
  //
  // SWEEP COMPLETED 2026-08-11 (Founder: "do a full review of the whole
  // app and make changes"). Every remaining 0xFF1A1220 dialog/surface
  // literal — wali_profile, browse, account_advanced, blocked_users,
  // upgrade, onboarding_scaffold, zyra_profile_image,
  // searchable_list_picker, connections — now reads luxuryDarkPurple or
  // the glass chrome. No 1A1220 literal remains outside comments.
  // ---------------------------------------------------------------------

  /// Bottom sheets and dialogs — Luxury Dark Purple at 88%, so the blur
  /// behind it still reads through.
  static const Color sheetSurface = Color(0xE03D2A4A);

  /// Toasts/SnackBars — same family, fully opaque since they sit over
  /// arbitrary content (often a photo) and must stay legible.
  static const Color toastSurface = Color(0xF23D2A4A);

  // FAB states
  static const Color fabDimmedBg = Color(0x0AFFFFFF);
  static const Color fabDimmedBorder = Color(0x17FFFFFF);
  static const Color fabDimmedArrow = Color(0x33FFFFFF);
  static const Color fabActiveBg = Color(0x1AFFFFFF);
  static const Color fabActiveBorder = Color(0x38FFFFFF);
  static const Color fabActiveArrow = Color(0xD9FFFFFF);

  // Privacy indicator states
  static const Color publicDot = Color(0xD93D9A6A); // rgba(61,154,106,0.85)
  static const Color publicText = Color(0x80C8DC8C); // rgba(100,200,140,0.5)
  static const Color unlockDot = Color(0xD9C49A44); // rgba(196,154,68,0.85)
  static const Color unlockText = Color(0x73DCB964); // rgba(220,185,100,0.45)
  static const Color privateDot = Color(0xB38A6A9E); // rgba(138,106,158,0.7)
  static const Color privateText = Color(0x73B496D2); // rgba(180,150,210,0.45)

  // ---------------------------------------------------------------------
  // UNIFIED 2026-08-20 — Founder direction.
  //
  // ZYRA no longer changes its background palette according to gender.
  // Every app surface now uses the already-approved Royal Purple →
  // Luxury Dark Purple gradient below. No new purple was introduced.
  // Gold, traffic-light states and destructive feedback remain semantic
  // accents; they are not alternate app themes.
  // ---------------------------------------------------------------------

  /// The single ZYRA background — Royal Purple fading to Luxury Dark Purple.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8A6A9E), Color(0xFF3D2A4A)],
  );

  /// Compatibility aliases retained while older call sites and documents
  /// are retired. Both deliberately resolve to the one ZYRA gradient.
  @Deprecated('Use brandGradient; ZYRA has one unified background theme.')
  static const LinearGradient brandGradientMale = brandGradient;

  @Deprecated('Use brandGradient; ZYRA has one unified background theme.')
  static const LinearGradient brandGradientFemale = brandGradient;

  /// Compatibility helper for existing profile-context call sites.
  /// [gender] remains accepted so this colour change does not disturb
  /// identity or onboarding data; it no longer changes presentation.
  static LinearGradient genderGradient(String? gender) => brandGradient;

  /// Onboarding shares the same unified background. The enum remains a flow
  /// input only so the colour change does not alter navigation or saved data.
  static LinearGradient backgroundFor(ZyraBackgroundVariant variant) {
    switch (variant) {
      case ZyraBackgroundVariant.neutral:
      case ZyraBackgroundVariant.male:
      case ZyraBackgroundVariant.female:
        return brandGradient;
    }
  }
}
