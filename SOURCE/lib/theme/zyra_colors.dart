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
  static const Color royalBlue = Color(0xFF3D5A80);
  static const Color rosePink = Color(0xFFD4868F);

  // Accent (selected options — purple, all themes)
  static const Color accentBg = Color(0x249A72BE); // rgba(154,114,190,0.14)
  static const Color accentBorder = Color(0x669A72BE); // rgba(154,114,190,0.4)

  // Progress bar
  static const Color progressFill = Color(0x47FFFFFF); // rgba(255,255,255,0.28)
  static const Color progressTrack = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const Color progressCompleteFill = Color(0x9950B478); // rgba(80,180,120,0.6)

  // Icon buttons
  static const Color iconButtonBg = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const Color iconButtonBorder = Color(0x24FFFFFF); // 0.5px rgba(255,255,255,0.14)

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
  // 2026-07-25 — DR-ZYRA-094 (Founder-ratified, supersedes DR-ZYRA-090).
  // DR-090 (2026-07-19) was an explicit, Founder-flagged "live-testing-
  // phase" override — flat colours, no fade into Luxury Dark Purple.
  // DR-094 ratifies the final palette and restores the original fade
  // design (BUSINESS/COLOUR THEME/Summary.md's "Option 1"): every theme
  // fades from its accent colour into Luxury Dark Purple. Verified
  // against the Founder's own reference gradient images pixel-for-pixel
  // (see DR-ZYRA-094 in SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md).
  //
  // Note: onboarding's use of a single flat variant regardless of gender
  // (backgroundFor(), below) is NOT changed by this — that is a separate,
  // still-open question (OA-ZYRA-123), not part of DR-094's scope, which
  // was specifically about the fade/no-fade question for these three
  // gradients.
  // ---------------------------------------------------------------------

  /// GLOBAL BRAND background — Royal Purple fading to Luxury Dark Purple.
  /// Used for Splash, main navigation, auth screens, and (per DR-ZYRA-090,
  /// unaffected by DR-094) onboarding via backgroundFor() below.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8A6A9E), Color(0xFF3D2A4A)],
  );

  /// Male-theme accent — Royal Blue fading to Luxury Dark Purple.
  /// Reserved for profile-context screens only (OA-ZYRA-123).
  static const LinearGradient brandGradientMale = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3D5A80), Color(0xFF3D2A4A)],
  );

  /// Female-theme accent — Rose Pink fading to Luxury Dark Purple.
  /// Reserved for profile-context screens only (OA-ZYRA-123).
  static const LinearGradient brandGradientFemale = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD4868F), Color(0xFF3D2A4A)],
  );

  /// Profile-context background — DR-ZYRA-094 / OA-ZYRA-123 ("gender
  /// accents reserved for profile only"): Male Seeker/Wali get
  /// [brandGradientMale], Female Seeker/Wali get [brandGradientFemale].
  /// Falls back to the neutral [brandGradient] when gender isn't known
  /// yet (e.g. account mid-onboarding). `gender` should be the raw
  /// AppState.gender value ('male' | 'female' | null) — same string
  /// used for both Seeker and Wali accounts (AppState is one signed-in
  /// account, whichever role it is).
  ///
  /// Fixed 2026-07-25: this helper didn't exist before — Wali screens
  /// had `brandGradientMale` hardcoded regardless of the signed-in
  /// Wali's actual gender, [brandGradientFemale] was defined but never
  /// referenced anywhere, and the Seeker's own Profile screen used the
  /// neutral brand gradient instead of a gender-matched one. Founder-
  /// flagged as a gap between the ratified spec and the live app.
  static LinearGradient genderGradient(String? gender) {
    switch (gender) {
      case 'male':
        return brandGradientMale;
      case 'female':
        return brandGradientFemale;
      default:
        return brandGradient;
    }
  }

  /// Onboarding background — still flat Royal Purple for every variant,
  /// not gender-derived (DR-ZYRA-090, unaffected by DR-094 — see note
  /// above; OA-ZYRA-123 is the still-open question about whether this
  /// should vary by gender). The enum/switch is kept in place so
  /// gender-derived onboarding backgrounds can come back with a one-line
  /// change if OA-ZYRA-123 is resolved that way later.
  static LinearGradient backgroundFor(ZyraBackgroundVariant variant) {
    switch (variant) {
      case ZyraBackgroundVariant.neutral:
      case ZyraBackgroundVariant.male:
      case ZyraBackgroundVariant.female:
        return brandGradient;
    }
  }
}
