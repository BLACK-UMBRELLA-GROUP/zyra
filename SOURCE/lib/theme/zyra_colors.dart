// LOCK14 V4: Ivory palette, warm floating surfaces and distinct gold roles.
// Source: PRODUCT/APPROVED/APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V4.md.
// Retained comparison values are retired separately by queue44.

import 'package:flutter/material.dart';

import '../services/zyra_local_prefs.dart';

/// Legacy comparison values remain until queue44. Every app coordinator uses
/// Ivory; these values never restore or write a member background choice.
enum ZyraDevPalette {
  ivory(
    'Ivory',
    'The locked app background',
    LinearGradient(
      begin: Alignment(-0.173648, -0.984808),
      end: Alignment(0.173648, 0.984808),
      colors: [Color(0xFFFBF7F0), Color(0xFFEEE6D8)],
    ),
  ),
  zyraPurple(
    'ZYRA Purple',
    'Royal Purple to Luxury Dark Purple',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8A6A9E), Color(0xFF3D2A4A)],
    ),
  ),
  royalBlue(
    'Royal Blue',
    'The earlier blue direction, deepened',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF607BA7), Color(0xFF26364F)],
    ),
  ),
  rosePink(
    'Rose Pink',
    'The earlier rose direction, softened',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFA6788F), Color(0xFF503343)],
    ),
  ),
  midnightPlum(
    'Midnight Plum · Current',
    'The Hulu-inspired deep purple, app-wide',
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF30203F), Color(0xFF160E20)],
    ),
  ),
  deepEmerald(
    'Deep Emerald',
    'Calm, grounded and family-led',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF47756B), Color(0xFF18352F)],
    ),
  ),
  sapphireNight(
    'Sapphire Night',
    'Cool navy with a premium finish',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF48698B), Color(0xFF192A3E)],
    ),
  ),
  desertRose(
    'Desert Rose',
    'Warm clay without becoming bright',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFA26F70), Color(0xFF513436)],
    ),
  ),
  warmCocoa(
    'Warm Cocoa',
    'Earthy neutral with soft warmth',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7B665F), Color(0xFF352A28)],
    ),
  ),
  charcoalGold(
    'Charcoal Gold',
    'Near-neutral so the gold details lead',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF55505D), Color(0xFF211E27)],
    ),
  ),
  midnightBlue(
    'Midnight blue',
    'Deep blue with a soft cobalt glow',
    LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF183F83), Color(0xFF07132B)],
    ),
  );

  final String label;
  final String detail;
  final LinearGradient gradient;
  bool get isLight => this == ivory;
  bool get usesWhiteGlass => false;
  const ZyraDevPalette(this.label, this.detail, this.gradient);
}

enum ZyraAppSurfaceStyle {
  glassSignals(
    'Glass Signals',
    'Classic glass with colour limited to meaningful icons and progress.',
  );

  final String label;
  final String detail;
  const ZyraAppSurfaceStyle(this.label, this.detail);
}

/// Which gender-derived background variant to show. `neutral` is used only
/// for the very first onboarding question (before gender is known).
enum ZyraBackgroundVariant { neutral, male, female }

class ZyraColors {
  ZyraColors._();

  static const Color ivoryTop = Color(0xFFFBF7F0);
  static const Color ivoryBottom = Color(0xFFEEE6D8);
  static const Color espresso = Color(0xFF2B2420);
  static const Color secondaryText = Color(0xFF6E6257);
  static const Color strongSecondaryText = Color(0xFF4F443A);
  static const Color quietText = Color(0xFF7A6E62);
  static const Color mutedText = Color(0xFF857868);
  static const Color warmOverlay = Color(0xFF3E2E1E);

  /// LOCK14 V5: gold reading text below 24 regular / 18.66 bold.
  static const Color goldText = Color(0xFF845F24);
  static const Color goldTextFill = Color(0xFFC08A3A);
  static const Color cardSurface = Color(0xFFF4EEE4);
  static const Color lowerSurface = Color(0xFFF1EBDF);
  static const Color sheetIvory = Color(0xFFF3EDE2);
  static const Color divider = Color(0x1A3E2E1E);
  static const Color avatarSand = Color(0xFF9C8A72);
  static const Color avatarDeepSand = Color(0xFF6B5B49);
  static const Color avatarWarmSand = Color(0xFF857560);

  // Compatibility aliases for retained callers. LOCK14 roles are authoritative.
  static const Color royalPurple = Color(0xFFFBF7F0);
  static const Color luxuryDarkPurple = Color(0xFF2B2420);
  static const Color darkPlumSurface = Color(0xFFF1EBDF);

  // The main Quiet Horizon splash is the colour authority for the brand
  // lockup on Welcome as well. Keep these separate from theme-dependent
  // foreground and from the slightly different Journey gold accent.
  static const Color splashWordmark = Color(0xFFA9792E);
  static Color get splashTagline => secondaryText;

  // Founder 2026-10-22: selection is a quiet surface with a gold edge, not
  // another pale lavender wash. Legacy aliases share that same boundary so
  // older cards/chips cannot restore the retired selected-state treatment.
  static Color get accentBg => surfaceFill;
  static Color get accentBorder => surfaceEmphasisBorder;

  // ── UI GATE P1 (OA-ZYRA-257 / DR-ZYRA-214, 2026-08-23): repeated screen
  //    literals promoted to named tokens VALUE-UNCHANGED — zero pixels
  //    moved by this change. NOTE the near-duplicate families (greens
  //    84D0A8 / 78C69D / 50B478, soft reds E08080 / E18A91 / DF7D82):
  //    whether they merge is a Founder design decision recorded in
  //    SYSTEM/tools/ui_gate/P1_TRIAGE_2026-08-23.md — do not unify
  //    values here without that ruling.
  static const Color journeyGold = Color(0xFFA9792E);
  static const Color positiveGreen = Color(0xFF4E9A72);
  static const Color journeyDotGreen = Color(0xFF4E9A72);
  static const Color negativeRed = Color(0xFFB84A42);
  static const Color successTick = Color(0xFF50B478);

  /// Canonical surface for every modal sheet that rises from the bottom.
  ///
  /// Keep this opaque: sheets can appear over photos, gradients and cards,
  /// and must retain the same colour in every part of the app.
  static Color get modalSheetSurface => darkPlumSurface;

  /// Backwards-compatible name used by the Guardian and membership flows.
  static Color get waliSheetBg => modalSheetSurface;

  // Contrast-aware foreground and translucent chrome. Dark palettes retain
  // their exact approved values.
  static bool get isLightPalette => true;
  static Color get foreground => espresso;
  static Color get foregroundBody => espresso;
  static Color get foregroundSecondary => secondaryText;
  static Color get foregroundMuted => mutedText;

  /// Neutral app-card fill. This is the shared visual-language boundary for
  /// the three App Surface choices; page code should use this rather than
  /// inventing a private white-alpha recipe.
  static Color get surfaceFill => const Color(0xD9FAF5EC);

  static Color get surfaceBorder => const Color(0x0F3E2E1E);

  /// Selected/expanded cards stay dark; the edge carries their emphasis.
  /// Never layer the former white/gold wash over another app card.
  static Color get surfaceEmphasisFill => surfaceFill;

  static Color get surfaceEmphasisBorder => journeyGold.withValues(alpha: 0.70);

  /// App-surface signal colour. Semantic colours remain authoritative where
  /// the domain has one (destructive, traffic light, Journey gold).
  static Color get surfaceSignal => journeyGold;

  // Progress bar. Glass Signals limits colour to meaningful progress and
  // selection.
  static Color get progressFill => Color.alphaBlend(
    journeyGold.withValues(alpha: 0.58),
    const Color(0x473E2E1E),
  );

  static Color get progressTrack => Color.alphaBlend(
    journeyGold.withValues(alpha: 0.10),
    const Color(0x123E2E1E),
  );

  static const Color progressCompleteFill = Color(
    0x9950B478,
  ); // rgba(80,180,120,0.6)

  // Icon buttons
  static Color get iconButtonBg {
    return surfaceFill;
  }

  static Color get iconButtonBorder {
    return surfaceBorder;
  }

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
  //   frostSelectedFill/…Border    historical selected pill (white28%/12%);
  //                                superseded by dark fill/gold edge22Oct2026
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
  // destructive replaces the 0xFFB84A42 coral that already appears as a
  // literal 20+ times across 9 files (End Journey, etc.) — same value,
  // now named. journey_flow_screen is migrated; sweep the rest as each
  // file comes up for review.
  // ---------------------------------------------------------------------

  /// Primary action fill — Pastel Grey Lavender, both gender themes.
  static const Color primaryAction = Color(0xFFC08A3A);

  /// Text/icon colour ON [primaryAction]. Always this, never white.
  static const Color onPrimaryAction = espresso;

  /// Destructive text/accents (End Journey coral).
  static const Color destructive = Color(0xFFB84A42);
  static const Color destructiveBorder = Color(0x66B84A42); // coral 0.4

  // Frost pills — sampled from the Connections segmented control.
  static Color get frostFill => const Color(0x1A3E2E1E);
  static Color get frostBorder => const Color(0x2E3E2E1E);
  static Color get frostSelectedFill => surfaceFill;

  static Color get frostSelectedBorder => surfaceEmphasisBorder;

  // Glass cards — the ratified zyra_glass_dialog recipe (blur σ30).
  static Color get glassFill => surfaceFill;

  static Color get glassBorder => surfaceEmphasisBorder;

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
  static Color get menuSurface => darkPlumSurface.withValues(alpha: .92);

  // Bottom-sheet colour is centralised in modalSheetSurface. This retained
  // getter prevents an older shell from reintroducing a second colour.

  /// Backwards-compatible gradient shape for existing sheet shells.
  /// Both stops intentionally use [modalSheetSurface], so these shells render
  /// exactly like sheets that use a solid colour.
  static LinearGradient get sheetGradient {
    final surface = modalSheetSurface;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [surface, surface],
    );
  }

  /// Compatibility alias for older sheet call sites.
  static Color get sheetSurface => modalSheetSurface;

  /// Toasts/SnackBars — same family, fully opaque since they sit over
  /// arbitrary content (often a photo) and must stay legible.
  static Color get toastSurface => darkPlumSurface;

  // FAB states
  static Color get fabDimmedBg => const Color(0x0A3E2E1E);
  static Color get fabDimmedBorder => const Color(0x173E2E1E);
  static Color get fabDimmedArrow => const Color(0x333E2E1E);
  static Color get fabActiveBg => const Color(0x1A3E2E1E);
  static Color get fabActiveBorder => const Color(0x383E2E1E);
  static Color get fabActiveArrow => const Color(0xD93E2E1E);

  // Privacy indicator states
  static const Color publicDot = Color(0xD93D9A6A); // rgba(61,154,106,0.85)
  static const Color publicText = Color(0x80C8DC8C); // rgba(100,200,140,0.5)
  static const Color unlockDot = Color(0xD9A9792E); // rgba(196,154,68,0.85)
  static const Color unlockText = Color(0x73A9792E); // rgba(220,185,100,0.45)
  static const Color privateDot = Color(0xB3857560); // rgba(138,106,158,0.7)
  static const Color privateText = Color(0x73857560); // rgba(180,150,210,0.45)

  // ---------------------------------------------------------------------
  // UNIFIED 2026-08-20 — Founder direction.
  //
  // ZYRA no longer changes its background palette according to gender.
  // Every app surface now uses the already-approved Royal Purple →
  // Luxury Dark Purple gradient below. No new purple was introduced.
  // Gold, traffic-light states and destructive feedback remain semantic
  // accents; they are not alternate app themes.
  // ---------------------------------------------------------------------

  /// LOCK14: the default and only app background; stored choices stay intact.
  static const ZyraDevPalette currentDefaultPalette = ZyraDevPalette.ivory;
  // Founder clarification 2026-09-27: apply the new colour to existing
  // installations too, not only installations without a saved palette.
  static const String currentPaletteRevision = 'lock14-ivory-2026-10-31-v4';

  /// Founder-selected and locked app-wide surface, 2026-08-29.
  static const ZyraAppSurfaceStyle currentDefaultSurfaceStyle =
      ZyraAppSurfaceStyle.glassSignals;

  static final ValueNotifier<ZyraDevPalette> devPaletteSelection =
      ValueNotifier<ZyraDevPalette>(currentDefaultPalette);

  static final ValueNotifier<ZyraAppSurfaceStyle> appSurfaceStyleSelection =
      ValueNotifier<ZyraAppSurfaceStyle>(currentDefaultSurfaceStyle);

  static ZyraDevPalette get devPalette => devPaletteSelection.value;
  static ZyraAppSurfaceStyle get appSurfaceStyle =>
      appSurfaceStyleSelection.value;

  // LOCK14: legacy palette preferences are ignored, never cleared or rewritten.
  // Comparison enums stay until the separately queued developer retirement.
  static void selectDevPalette(ZyraDevPalette _) {
    devPaletteSelection.value = currentDefaultPalette;
  }

  static void selectAppPalette(ZyraDevPalette _) => restoreAppPalette(null);

  static void restoreCurrentAppPalette() => restoreAppPalette(null);

  static void restoreAppPalette(String? _) {
    devPaletteSelection.value = currentDefaultPalette;
  }

  static void selectAppSurfaceStyle(ZyraAppSurfaceStyle style) {
    if (appSurfaceStyleSelection.value != style) {
      appSurfaceStyleSelection.value = style;
    }
  }

  /// Restores the locked production surface and removes any retired stored
  /// comparison from builds that previously exposed the three-way picker.
  static void restoreAppSurfaceStyle(String? _) {
    appSurfaceStyleSelection.value = currentDefaultSurfaceStyle;
    ZyraLocalPrefs.setCachedAppSurfaceStyleName(null);
  }

  /// V4 separates text-bearing gold fills from decorative accent gold.
  static Color get actionFill => primaryAction;
  static Color get onAction => onPrimaryAction;

  /// Neutral contrast helpers for glass and page-level UI.
  static Color ink(double opacity) {
    if (opacity >= .85) return espresso;
    if (opacity >= .65) return secondaryText;
    if (opacity >= .5) return secondaryText;
    if (opacity >= .34) return mutedText;
    return warmOverlay.withValues(alpha: opacity);
  }

  static Color get accentOnCanvas => journeyGold;

  /// The live app background always resolves to locked Ivory.
  static LinearGradient get brandGradient => currentDefaultPalette.gradient;

  /// Compatibility aliases retained while older call sites and documents
  /// are retired. Both deliberately resolve to the one ZYRA gradient.
  @Deprecated('Use brandGradient; ZYRA has one unified background theme.')
  static LinearGradient get brandGradientMale => brandGradient;

  @Deprecated('Use brandGradient; ZYRA has one unified background theme.')
  static LinearGradient get brandGradientFemale => brandGradient;

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
