// ZYRA typography — Poppins is the official app reading face by direct
// Founder instruction (2026-10-01). Developer Tools retains session-only
// comparisons; the ZYRA wordmark remains Syne.
// Weights: 200 (headings), 300 (body/subtext), 400 (buttons).
//
// Wordmark exception (2026-07-18, Founder request): the "ZYRA" mark
// itself (Welcome screen, splash screen, app icon) uses its own typeface
// rather than the selected reading face, giving the brand mark a distinct
// identity. This is a one-off for the mark, not a typeface-wide change.
//
// THAT TYPEFACE IS SYNE. Corrected here 2026-08-09 — this header still
// said "Playfair Display" two days after the font changed, while
// [ZyraText.wordmark] below said Syne. The header is what a reader skims
// first, so the file was misinforming anyone who did not scroll. The
// authority is the code; see the doc comment on wordmark for why Syne.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'zyra_colors.dart';

/// The eighteen body-type candidates available in Developer Tools.
///
/// This deliberately excludes the ZYRA wordmark: [ZyraText.wordmark] stays
/// Syne regardless of this selection, so comparing the app's reading face
/// can never accidentally reopen the locked brand mark.
enum ZyraAppFont {
  jost('Jost', 'Jost'),
  manrope('Manrope', 'Manrope'),
  dmSans('DM Sans', 'DM Sans'),
  plusJakartaSans('Plus Jakarta Sans', 'Plus Jakarta Sans'),
  outfit('Outfit', 'Outfit'),
  urbanist('Urbanist', 'Urbanist'),
  montserrat('Montserrat', 'Montserrat'),
  raleway('Raleway', 'Raleway'),
  lora('Lora', 'Lora'),
  cormorantGaramond('Cormorant Garamond', 'Cormorant Garamond'),
  inter('Inter', 'Inter'),
  poppins('Poppins · Current', 'Poppins'),
  nunitoSans('Nunito Sans', 'Nunito Sans'),
  sourceSans3('Source Sans 3', 'Source Sans 3'),
  workSans('Work Sans', 'Work Sans'),
  quicksand('Quicksand', 'Quicksand'),
  libreBaskerville('Libre Baskerville', 'Libre Baskerville'),
  merriweather('Merriweather', 'Merriweather');

  final String label;
  final String family;
  const ZyraAppFont(this.label, this.family);
}

class ZyraText {
  ZyraText._();

  /// Current launch default, Founder-directed 2026-08-24.
  static const ZyraAppFont currentDefaultFont = ZyraAppFont.poppins;

  /// In-memory on purpose: this is a protected Founder comparison tool, not a
  /// member preference. The chosen face survives navigation for the running
  /// test session and resets to official Poppins on relaunch.
  static final ValueNotifier<ZyraAppFont> appFontSelection =
      ValueNotifier<ZyraAppFont>(currentDefaultFont);

  /// Flutter widget tests deliberately block HTTP. This keeps typography
  /// policy tests focused on selection/rebuild behaviour without starting
  /// asynchronous Google Font downloads that the test binding must refuse.
  @visibleForTesting
  static bool useTestFontStubs = false;

  /// Golden tests may supply bundled aliases so screenshot evidence retains
  /// real glyphs and production metrics without network access. Ordinary
  /// widget tests leave these null and retain the lightweight stub behaviour.
  @visibleForTesting
  static String? testReadingFontFamily;

  @visibleForTesting
  static String? testWordmarkFontFamily;

  static ZyraAppFont get appFont => appFontSelection.value;

  static void selectAppFont(ZyraAppFont font) {
    if (appFontSelection.value != font) appFontSelection.value = font;
  }

  /// Restores the official reading face before the first frame. A legacy
  /// member font choice is ignored; only protected Developer Tools can make
  /// a temporary comparison selection during the current session.
  static void restoreAppFont(String? _) {
    appFontSelection.value = currentDefaultFont;
  }

  static TextStyle _appStyle({
    required double size,
    required FontWeight weight,
    required Color? color,
    double? letterSpacing,
    ZyraAppFont? font,
  }) {
    final selected = font ?? appFont;
    if (useTestFontStubs) {
      return TextStyle(
        fontFamily: testReadingFontFamily ?? selected.family,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
    return switch (selected) {
      ZyraAppFont.jost => GoogleFonts.jost(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.manrope => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.dmSans => GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.plusJakartaSans => GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.outfit => GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.urbanist => GoogleFonts.urbanist(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.montserrat => GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.raleway => GoogleFonts.raleway(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.lora => GoogleFonts.lora(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.cormorantGaramond => GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.inter => GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      // Poppins is bundled in pubspec as the live default. Resolve it
      // synchronously so first paint and offline use never trigger the
      // google_fonts runtime loader (which can re-layout text after paint).
      ZyraAppFont.poppins => TextStyle(
        fontFamily: ZyraAppFont.poppins.family,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.nunitoSans => GoogleFonts.nunitoSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.sourceSans3 => GoogleFonts.sourceSans3(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.workSans => GoogleFonts.workSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.quicksand => GoogleFonts.quicksand(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.libreBaskerville => GoogleFonts.libreBaskerville(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
      ZyraAppFont.merriweather => GoogleFonts.merriweather(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
    };
  }

  /// Candidate-specific rendering for the eighteen-option comparison list.
  static TextStyle preview(
    ZyraAppFont font, {
    double size = 14,
    FontWeight weight = FontWeight.w300,
    Color? color,
  }) => _appStyle(
    size: size,
    weight: weight,
    color: color ?? ZyraColors.foreground,
    font: font,
  );

  /// Covers the small number of Material widgets that use theme defaults
  /// instead of an explicit ZyraText style.
  static TextTheme textTheme(TextTheme base) => useTestFontStubs
      ? base.apply(fontFamily: testReadingFontFamily ?? appFont.family)
      : switch (appFont) {
          ZyraAppFont.jost => GoogleFonts.jostTextTheme(base),
          ZyraAppFont.manrope => GoogleFonts.manropeTextTheme(base),
          ZyraAppFont.dmSans => GoogleFonts.dmSansTextTheme(base),
          ZyraAppFont.plusJakartaSans => GoogleFonts.plusJakartaSansTextTheme(
            base,
          ),
          ZyraAppFont.outfit => GoogleFonts.outfitTextTheme(base),
          ZyraAppFont.urbanist => GoogleFonts.urbanistTextTheme(base),
          ZyraAppFont.montserrat => GoogleFonts.montserratTextTheme(base),
          ZyraAppFont.raleway => GoogleFonts.ralewayTextTheme(base),
          ZyraAppFont.lora => GoogleFonts.loraTextTheme(base),
          ZyraAppFont.cormorantGaramond =>
            GoogleFonts.cormorantGaramondTextTheme(base),
          ZyraAppFont.inter => GoogleFonts.interTextTheme(base),
          ZyraAppFont.poppins => base.apply(
            fontFamily: ZyraAppFont.poppins.family,
          ),
          ZyraAppFont.nunitoSans => GoogleFonts.nunitoSansTextTheme(base),
          ZyraAppFont.sourceSans3 => GoogleFonts.sourceSans3TextTheme(base),
          ZyraAppFont.workSans => GoogleFonts.workSansTextTheme(base),
          ZyraAppFont.quicksand => GoogleFonts.quicksandTextTheme(base),
          ZyraAppFont.libreBaskerville => GoogleFonts.libreBaskervilleTextTheme(
            base,
          ),
          ZyraAppFont.merriweather => GoogleFonts.merriweatherTextTheme(base),
        };

  static TextStyle heading({double size = 20, Color? color}) => _appStyle(
    size: size,
    weight: FontWeight.w200,
    color: color ?? ZyraColors.foreground,
  );

  /// One reading-face size, weight and colour for the main tab headings.
  static const double pageTitleSize = 26;
  static TextStyle pageTitle() => heading(size: pageTitleSize);

  // OA-ZYRA-122 §1 (2026-07-19): letterSpacing widened 1 -> 3 for a more
  // deliberate, premium feel on the wordmark — a full typeface swap was
  // already done 2026-07-18 (Playfair Display, since superseded — see
  // the TYPEFACE CHANGED note below), so this was a refinement of that
  // recent choice rather than relitigating it.
  /// TYPEFACE CHANGED 2026-08-07: Playfair Display -> Syne, Founder's pick
  /// from twelve options.
  ///
  /// Playfair is a high-contrast old-style serif and at w600 it was heavy —
  /// it read as a magazine masthead rather than a mark. Syne is a
  /// contemporary display face with deliberately uneven proportions (the
  /// widest letter sits next to the narrowest), which is what makes ZYRA
  /// distinctive in four letters rather than merely elegant.
  ///
  /// letterSpacing 3 -> 4, holding the ratio the Founder approved on screen
  /// (0.118 of the size). Syne's own sidebearings are tighter than
  /// Playfair's, so keeping 3 would have closed the mark up.
  ///
  /// KEEP IN SYNC WITH TWO BAKED IMAGES. Neither is live text, so neither
  /// follows this line automatically:
  ///
  ///   assets/splash/splash_logo.png   the Syne wordmark, 1400x460
  ///   assets/icon/icon.png            the app icon, cut FROM that PNG
  ///
  /// ── CORRECTED 2026-08-09. This used to say splash_logo.png was "the
  /// NATIVE splash". It is not, and has not been since 2026-08-07:
  /// splash_screen.dart records that flutter_native_splash is configured
  /// with a flat colour and no image, and that this PNG "is no longer
  /// referenced. Do not put it back." Two files disagreed about what the
  /// same asset was for.
  ///
  /// It still matters, for a new reason. The app icon adopted on
  /// 2026-08-09 is the wordmark, and it was generated by using that PNG's
  /// alpha channel as a stencil — so the icon's letterforms ARE this
  /// typeface, exactly, rather than a re-render that might drift.
  ///
  /// So if this line changes again: regenerate splash_logo.png in the new
  /// face, then rebuild the icon from it (dart run flutter_launcher_icons),
  /// or the home screen shows one wordmark and the app shows another.
  static TextStyle wordmark({double size = 34, Color? color}) =>
      useTestFontStubs
      ? TextStyle(
          fontFamily: testWordmarkFontFamily ?? 'Syne',
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color ?? ZyraColors.splashWordmark,
          letterSpacing: 4,
        )
      : TextStyle(
          fontFamily: 'Syne',
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color ?? ZyraColors.splashWordmark,
          letterSpacing: 4,
        );

  static TextStyle body({double size = 13, Color? color}) => _appStyle(
    size: size,
    weight: FontWeight.w300,
    color: color ?? ZyraColors.foregroundBody,
  );

  static TextStyle subtext({double size = 12.5, Color? color}) => _appStyle(
    size: size,
    weight: FontWeight.w300,
    color: color ?? ZyraColors.foregroundSecondary,
  );

  /// "Connecting Through Trust" — ONE size, two screens.
  ///
  /// Added 2026-08-09 after the Founder asked whether the splash and the
  /// Welcome screen matched. They did not, and the difference reversed
  /// depending on the device:
  ///
  ///   device        splash   Welcome
  ///   iPhone SE      11.00     12.50   <- Welcome bigger
  ///   iPhone 14/15   12.99     12.50
  ///   Pro Max        14.32     12.50
  ///   iPad           15.98     12.50
  ///
  /// The splash scaled with the screen; Welcome was a hardcoded 12.5 from
  /// [subtext]'s default, which is the size of ordinary body subtext and
  /// not a decision anyone made about the tagline.
  ///
  /// Founder's rule was "choose the bigger one". Because the winner
  /// changes by device, that is not one number — it is the splash's own
  /// ratio with the floor lifted from 11.0 to 12.5, which is >= both
  /// values at every width. Small phones stop shrinking it; everything
  /// else keeps scaling.
  ///
  /// Both screens now call this. Neither hardcodes a tagline size.
  static double taglineSize(BuildContext context) {
    final design = MediaQuery.sizeOf(context).shortestSide.clamp(280.0, 480.0);
    return (design * 0.0333).clamp(12.5, 17.0);
  }

  static TextStyle option({double size = 14, Color? color}) => _appStyle(
    size: size,
    weight: FontWeight.w300,
    color: color ?? ZyraColors.foreground,
  );

  /// DEFAULT COLOUR REMOVED 2026-08-11 (Frost UI pass). This used to
  /// default to Colors.white, which every FilledButton call site passed
  /// through unchanged — so when main.dart gained a real ColorScheme
  /// (primary = Pastel Grey Lavender, onPrimary = Luxury Dark Purple),
  /// a hardcoded white here would have sat on the lavender fill at ~2:1
  /// contrast and silently defeated the theme's onPrimary on all ~30
  /// FilledButtons at once.
  ///
  /// A null colour inherits from the enclosing button's foreground:
  /// FilledButtons get onPrimary (dark purple), TextButtons/
  /// OutlinedButtons get their themed white (main.dart), and non-button
  /// uses fall back to the dark theme's near-white default — visually
  /// what they showed before. Call sites that pass an explicit colour
  /// (e.g. End Journey coral) are unaffected.
  static TextStyle button({double size = 15, Color? color}) => _appStyle(
    size: size,
    weight: FontWeight.w400,
    color: color,
    letterSpacing: 0.5,
  );

  static TextStyle chapterLabel({Color? color}) => _appStyle(
    size: 10,
    weight: FontWeight.w300,
    color: color ?? ZyraColors.foregroundSecondary,
    letterSpacing: 0.8,
  );

  static TextStyle privacyText({Color? color}) => _appStyle(
    size: 11,
    weight: FontWeight.w300,
    color: color ?? ZyraColors.foregroundMuted,
  );
}
