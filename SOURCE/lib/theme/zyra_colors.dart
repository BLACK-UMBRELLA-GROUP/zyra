// ZYRA brand colours and background gradients.
// Source of truth: ZYRA/BUSINESS/COLOUR THEME/Summary.md and
// APP/Onboarding/SEEKER ONBOARDING QUESTIONS/Onboarding Rules & UX.md
// (§ COLOUR SYSTEM). Do not invent new colours here — every value below
// traces to one of those two documents.

import 'package:flutter/material.dart';

import '../services/zyra_local_prefs.dart';

/// Background directions available to members from Profile → Personalisation.
/// Light studies remain in the enum only for historical visual fixtures and
/// are rejected by the member-facing selection boundary.
enum ZyraDevPalette {
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
  paperWhite(
    'Paper White',
    'White canvas with dark plum contrast',
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFF4EFF6)],
    ),
    isLight: true,
  ),
  crystalMist(
    'Crystal UI',
    'Translucent mist with bright white glass surfaces',
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE7E2EC), Color(0xFFDCE5F4), Color(0xFFF8FAFD)],
      stops: [0.0, 0.54, 1.0],
    ),
    isLight: true,
    usesWhiteGlass: true,
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
  final bool isLight;
  final bool usesWhiteGlass;
  const ZyraDevPalette(
    this.label,
    this.detail,
    this.gradient, {
    this.isLight = false,
    this.usesWhiteGlass = false,
  });
}

/// Accent directions for the separate Paper White comparison family.
/// The colour directions reuse the ZYRA comparisons above; Black is the
/// Founder's explicit additional 2026-08-24 light-theme comparison. All are
/// developer-only and reset on relaunch.
enum ZyraDevLightAccent {
  purple('Purple', Color(0xFF6B4B7D)),
  royalBlue('Royal Blue', Color(0xFF395B88)),
  rose('Rose', Color(0xFF8A4E69)),
  emerald('Emerald', Color(0xFF2F665A)),
  sapphire('Sapphire', Color(0xFF355A7D)),
  gold('Gold', Color(0xFF9B7835)),
  black('Black', Color(0xFF171219));

  final String label;
  final Color color;
  const ZyraDevLightAccent(this.label, this.color);
}

/// App-wide surface language selected from the developer Home controls.
///
/// This is deliberately separate from the background palette and from
/// semantic colour. Red still means destructive, the traffic-light system
/// keeps its approved meanings, and Journey gold remains Journey gold.
enum ZyraAppSurfaceStyle {
  classicGlass(
    'Classic Glass',
    'Neutral ZYRA glass throughout the app. This is the current default.',
  ),
  glassSignals(
    'Glass Signals',
    'Classic glass with colour limited to meaningful icons and progress.',
  ),
  statusAccents(
    'Status Accents',
    'Stronger semantic colour on status surfaces and active highlights.',
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

  // Founder-directed Hulu purple, 2026-09-27 (OA-ZYRA-257). Historical
  // ZYRA Purple remains an opt-in personalisation choice, not the default.
  static const Color royalPurple = Color(0xFF30203F);
  static const Color luxuryDarkPurple = Color(0xFF160E20);
  static const Color darkPlumSurface = Color(0xFF241A2F);

  // The main Quiet Horizon splash is the colour authority for the brand
  // lockup on Welcome as well. Keep these separate from theme-dependent
  // foreground and from the slightly different Journey gold accent.
  static const Color splashWordmark = Color(0xFFE5CE8E);
  static Color get splashTagline => Colors.white.withValues(alpha: 0.78);

  // Founder 2026-10-22: selection is a quiet surface with a gold edge, not
  // another pale lavender wash. Legacy aliases share that same boundary so
  // older cards/chips cannot restore the retired selected-state treatment.
  static Color get accentBg => isLightPalette
      ? devLightAccent.color.withValues(alpha: 0.14)
      : surfaceFill;
  static Color get accentBorder => isLightPalette
      ? devLightAccent.color.withValues(alpha: 0.40)
      : surfaceEmphasisBorder;

  // ── UI GATE P1 (OA-ZYRA-257 / DR-ZYRA-214, 2026-08-23): repeated screen
  //    literals promoted to named tokens VALUE-UNCHANGED — zero pixels
  //    moved by this change. NOTE the near-duplicate families (greens
  //    84D0A8 / 78C69D / 50B478, soft reds E08080 / E18A91 / DF7D82):
  //    whether they merge is a Founder design decision recorded in
  //    SYSTEM/RESOURCES/UI_GATE/P1_TRIAGE_2026-08-23.md — do not unify
  //    values here without that ruling.
  static const Color journeyGold = Color(0xFFE8C98A);
  static const Color positiveGreen = Color(0xFF84D0A8);
  static const Color journeyDotGreen = Color(0xFF78C69D);
  static const Color negativeRed = Color(0xFFE18A91);
  static const Color successTick = Color(0xFF50B478);

  /// Canonical surface for every modal sheet that rises from the bottom.
  ///
  /// Keep this opaque: sheets can appear over photos, gradients and cards,
  /// and must retain the same colour in every part of the app.
  static Color get modalSheetSurface =>
      isLightPalette ? const Color(0xFFF7F2F8) : darkPlumSurface;

  /// Backwards-compatible name used by the Guardian and membership flows.
  static Color get waliSheetBg => modalSheetSurface;

  // Contrast-aware foreground and translucent chrome. Dark palettes retain
  // their exact approved values; Paper White swaps only the neutral ink.
  static bool get isLightPalette => devPalette.isLight;
  static Color get foreground =>
      isLightPalette ? luxuryDarkPurple : Colors.white;
  static Color get foregroundBody =>
      isLightPalette ? const Color(0xE63D2A4A) : const Color(0xE6FFFFFF);
  static Color get foregroundSecondary =>
      isLightPalette ? const Color(0xB33D2A4A) : const Color(0xB3FFFFFF);
  static Color get foregroundMuted =>
      isLightPalette ? const Color(0x8A3D2A4A) : const Color(0x8AFFFFFF);

  /// Neutral app-card fill. This is the shared visual-language boundary for
  /// the three App Surface choices; page code should use this rather than
  /// inventing a private white-alpha recipe.
  static Color get surfaceFill {
    if (!isLightPalette) return const Color(0x12FFFFFF);
    final neutral = devPalette.usesWhiteGlass
        ? const Color(0xB8FFFFFF)
        : isLightPalette
        ? const Color(0x123D2A4A)
        : const Color(0x12FFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass ||
      ZyraAppSurfaceStyle.glassSignals => neutral,
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.10),
        neutral,
      ),
    };
  }

  static Color get surfaceBorder {
    final neutral = devPalette.usesWhiteGlass
        ? const Color(0xE8FFFFFF)
        : isLightPalette
        ? const Color(0x303D2A4A)
        : const Color(0x24FFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass ||
      ZyraAppSurfaceStyle.glassSignals => neutral,
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.32),
        neutral,
      ),
    };
  }

  /// Selected/expanded cards stay dark; the edge carries their emphasis.
  /// Never layer the former white/gold wash over another app card.
  static Color get surfaceEmphasisFill {
    if (!isLightPalette) return surfaceFill;
    final neutral = devPalette.usesWhiteGlass
        ? const Color(0xE6FFFFFF)
        : isLightPalette
        ? const Color(0x293D2A4A)
        : const Color(0x2BFFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass => neutral,
      ZyraAppSurfaceStyle.glassSignals => Color.alphaBlend(
        journeyGold.withValues(alpha: 0.10),
        neutral,
      ),
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.18),
        neutral,
      ),
    };
  }

  static Color get surfaceEmphasisBorder {
    if (!isLightPalette) return journeyGold.withValues(alpha: 0.70);
    final neutral = devPalette.usesWhiteGlass
        ? Colors.white
        : isLightPalette
        ? const Color(0x383D2A4A)
        : const Color(0x38FFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass => neutral,
      ZyraAppSurfaceStyle.glassSignals => Color.alphaBlend(
        journeyGold.withValues(alpha: 0.46),
        neutral,
      ),
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.46),
        neutral,
      ),
    };
  }

  /// App-surface signal colour. Semantic colours remain authoritative where
  /// the domain has one (destructive, traffic light, Journey gold).
  static Color get surfaceSignal => switch (appSurfaceStyle) {
    ZyraAppSurfaceStyle.classicGlass => foreground,
    ZyraAppSurfaceStyle.glassSignals => journeyGold,
    ZyraAppSurfaceStyle.statusAccents => actionFill,
  };

  // Progress bar. Glass Signals limits colour to meaningful progress and
  // selection; Status Accents also tints containing surfaces.
  static Color get progressFill {
    final neutral = isLightPalette
        ? const Color(0x473D2A4A)
        : const Color(0x47FFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass => neutral,
      ZyraAppSurfaceStyle.glassSignals => Color.alphaBlend(
        journeyGold.withValues(alpha: 0.58),
        neutral,
      ),
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.48),
        neutral,
      ),
    };
  }

  static Color get progressTrack {
    final neutral = isLightPalette
        ? const Color(0x143D2A4A)
        : const Color(0x12FFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass => neutral,
      ZyraAppSurfaceStyle.glassSignals => Color.alphaBlend(
        journeyGold.withValues(alpha: 0.10),
        neutral,
      ),
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.12),
        neutral,
      ),
    };
  }

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
  static Color get frostFill => devPalette.usesWhiteGlass
      ? const Color(0x8FFFFFFF)
      : isLightPalette
      ? const Color(0x123D2A4A)
      : const Color(0x1AFFFFFF);
  static Color get frostBorder => devPalette.usesWhiteGlass
      ? const Color(0xD9FFFFFF)
      : isLightPalette
      ? const Color(0x293D2A4A)
      : const Color(0x2EFFFFFF);
  static Color get frostSelectedFill {
    if (!isLightPalette) return surfaceFill;
    final neutral = devPalette.usesWhiteGlass
        ? const Color(0xE6FFFFFF)
        : isLightPalette
        ? const Color(0x293D2A4A)
        : const Color(0x47FFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass => neutral,
      ZyraAppSurfaceStyle.glassSignals => Color.alphaBlend(
        journeyGold.withValues(alpha: 0.13),
        neutral,
      ),
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.16),
        neutral,
      ),
    };
  }

  static Color get frostSelectedBorder {
    if (!isLightPalette) return surfaceEmphasisBorder;
    final neutral = devPalette.usesWhiteGlass
        ? const Color(0xFFFFFFFF)
        : isLightPalette
        ? const Color(0x383D2A4A)
        : const Color(0x1FFFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass => neutral,
      ZyraAppSurfaceStyle.glassSignals => Color.alphaBlend(
        journeyGold.withValues(alpha: 0.46),
        neutral,
      ),
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.40),
        neutral,
      ),
    };
  }

  // Glass cards — the ratified zyra_glass_dialog recipe (blur σ30).
  static Color get glassFill {
    if (!isLightPalette) return surfaceFill;
    final neutral = devPalette.usesWhiteGlass
        ? const Color(0xC2FFFFFF)
        : isLightPalette
        ? const Color(0x143D2A4A)
        : const Color(0x24FFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass ||
      ZyraAppSurfaceStyle.glassSignals => neutral,
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.10),
        neutral,
      ),
    };
  }

  static Color get glassBorder {
    if (!isLightPalette) return surfaceEmphasisBorder;
    final neutral = devPalette.usesWhiteGlass
        ? const Color(0xF2FFFFFF)
        : isLightPalette
        ? const Color(0x303D2A4A)
        : const Color(0x38FFFFFF);
    return switch (appSurfaceStyle) {
      ZyraAppSurfaceStyle.classicGlass ||
      ZyraAppSurfaceStyle.glassSignals => neutral,
      ZyraAppSurfaceStyle.statusAccents => Color.alphaBlend(
        actionFill.withValues(alpha: 0.34),
        neutral,
      ),
    };
  }

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
  static Color get menuSurface => isLightPalette
      ? const Color(0xF7FCFAFD)
      : darkPlumSurface.withValues(alpha: .92);

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
  static Color get toastSurface =>
      isLightPalette ? const Color(0xFFFCFAFD) : darkPlumSurface;

  // FAB states
  static Color get fabDimmedBg =>
      isLightPalette ? const Color(0x0A3D2A4A) : const Color(0x0AFFFFFF);
  static Color get fabDimmedBorder =>
      isLightPalette ? const Color(0x173D2A4A) : const Color(0x17FFFFFF);
  static Color get fabDimmedArrow =>
      isLightPalette ? const Color(0x663D2A4A) : const Color(0x33FFFFFF);
  static Color get fabActiveBg =>
      isLightPalette ? const Color(0x143D2A4A) : const Color(0x1AFFFFFF);
  static Color get fabActiveBorder =>
      isLightPalette ? const Color(0x473D2A4A) : const Color(0x38FFFFFF);
  static Color get fabActiveArrow =>
      isLightPalette ? luxuryDarkPurple : const Color(0xD9FFFFFF);

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

  /// Current launch default, darkened on Founder direction 2026-09-27.
  /// Existing Midnight Plum preferences follow the new purple without
  /// clearing member data. Members may choose
  /// another approved dark background from Profile → Personalisation.
  static const ZyraDevPalette currentDefaultPalette =
      ZyraDevPalette.midnightPlum;
  // Founder clarification 2026-09-27: apply the new colour to existing
  // installations too, not only installations without a saved palette.
  static const String currentPaletteRevision = 'dark-hulu-app-2026-09-27-v1';

  /// Founder-selected and locked app-wide surface, 2026-08-29.
  static const ZyraAppSurfaceStyle currentDefaultSurfaceStyle =
      ZyraAppSurfaceStyle.glassSignals;

  static final ValueNotifier<ZyraDevPalette> devPaletteSelection =
      ValueNotifier<ZyraDevPalette>(currentDefaultPalette);

  static final ValueNotifier<ZyraDevLightAccent> devLightAccentSelection =
      ValueNotifier<ZyraDevLightAccent>(ZyraDevLightAccent.purple);

  static final ValueNotifier<ZyraAppSurfaceStyle> appSurfaceStyleSelection =
      ValueNotifier<ZyraAppSurfaceStyle>(currentDefaultSurfaceStyle);

  static ZyraDevPalette get devPalette => devPaletteSelection.value;
  static ZyraDevLightAccent get devLightAccent => devLightAccentSelection.value;
  static ZyraAppSurfaceStyle get appSurfaceStyle =>
      appSurfaceStyleSelection.value;

  static void selectDevPalette(ZyraDevPalette palette) {
    if (devPaletteSelection.value != palette) {
      devPaletteSelection.value = palette;
    }
  }

  /// Selects the member's persisted background from Profile →
  /// Personalisation. Light experiments are deliberately refused here, not
  /// merely hidden by the screen, so an old/deep link cannot reactivate a
  /// retired light appearance.
  static void selectAppPalette(ZyraDevPalette palette) {
    if (palette.isLight) return;
    selectDevPalette(palette);
    ZyraLocalPrefs.setCachedAppPaletteName(palette.name);
    ZyraLocalPrefs.setCachedAppPaletteRevision(currentPaletteRevision);
  }

  /// Startup-only adoption of the current app-wide theme. Only palette
  /// preferences change; account state, fonts, haptics and app lock survive.
  /// Both writes capture the same owner/generation synchronously, so a queued
  /// update cannot stamp the next account. Later explicit choices still work.
  static void restoreCurrentAppPalette() {
    if (ZyraLocalPrefs.cachedAppPaletteRevision == currentPaletteRevision) {
      restoreAppPalette(ZyraLocalPrefs.cachedAppPaletteName);
      return;
    }
    restoreAppPalette(null);
    ZyraLocalPrefs.setCachedAppPaletteName(currentDefaultPalette.name);
    ZyraLocalPrefs.setCachedAppPaletteRevision(currentPaletteRevision);
  }

  /// Hydrates the background before `runApp` without rewriting disk.
  /// Unknown, retired and light values fall back to Midnight Plum.
  static void restoreAppPalette(String? storedName) {
    final restored = ZyraDevPalette.values.where(
      (palette) => !palette.isLight && palette.name == storedName,
    );
    devPaletteSelection.value = restored.isEmpty
        ? currentDefaultPalette
        : restored.first;
  }

  static void selectDevLightAccent(ZyraDevLightAccent accent) {
    if (devLightAccentSelection.value != accent) {
      devLightAccentSelection.value = accent;
    }
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

  /// Active interactive accent. Dark backgrounds retain the approved
  /// lavender; Paper White uses the Founder-selected existing ZYRA colour.
  static Color get actionFill =>
      isLightPalette ? devLightAccent.color : primaryAction;
  static Color get onAction => isLightPalette ? Colors.white : onPrimaryAction;

  /// Neutral contrast helpers for glass and page-level UI.
  static Color ink(double opacity) => foreground.withValues(alpha: opacity);
  static Color get accentOnCanvas =>
      isLightPalette ? devLightAccent.color : unlockText;

  /// The live app background. Midnight Plum now uses the Hulu dark purple;
  /// explicit member personalisation and temporary developer choices survive.
  static LinearGradient get brandGradient => devPalette.gradient;

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
