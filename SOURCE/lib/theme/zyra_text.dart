// ZYRA typography — Jost, per Onboarding Rules & UX §TYPOGRAPHY.
// Weights: 200 (headings/wordmark), 300 (body/subtext), 400 (buttons).
//
// Wordmark exception (2026-07-18, Founder request): the "ZYRA" mark
// itself (Welcome screen, splash screen) uses Playfair Display, an
// elegant serif, rather than Jost — giving the brand mark its own
// distinct identity instead of just being larger Jost. Every other
// text style in the app stays on Jost per the original spec; this is
// a deliberate one-off for the mark only, not a typeface-wide change.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ZyraText {
  ZyraText._();

  static TextStyle heading({double size = 20, Color color = Colors.white}) =>
      GoogleFonts.jost(fontSize: size, fontWeight: FontWeight.w200, color: color);

  // OA-ZYRA-122 §1 (2026-07-19): letterSpacing widened 1 -> 3 for a more
  // deliberate, premium feel on the wordmark — a full typeface swap was
  // already done 2026-07-18 (Playfair Display, see file header), so this
  // is a refinement of that recent choice rather than relitigating it.
  static TextStyle wordmark({double size = 34, Color color = Colors.white}) =>
      GoogleFonts.playfairDisplay(fontSize: size, fontWeight: FontWeight.w600, color: color, letterSpacing: 3);

  static TextStyle body({double size = 13, Color color = const Color(0xE6FFFFFF)}) =>
      GoogleFonts.jost(fontSize: size, fontWeight: FontWeight.w300, color: color);

  static TextStyle subtext({double size = 12.5, Color color = const Color(0xB3FFFFFF)}) =>
      GoogleFonts.jost(fontSize: size, fontWeight: FontWeight.w300, color: color);

  static TextStyle option({double size = 14, Color color = Colors.white}) =>
      GoogleFonts.jost(fontSize: size, fontWeight: FontWeight.w300, color: color);

  static TextStyle button({double size = 15, Color color = Colors.white}) =>
      GoogleFonts.jost(fontSize: size, fontWeight: FontWeight.w400, color: color, letterSpacing: 0.5);

  static TextStyle chapterLabel({Color color = const Color(0xB3FFFFFF)}) =>
      GoogleFonts.jost(fontSize: 10, fontWeight: FontWeight.w300, color: color, letterSpacing: 0.8);

  static TextStyle privacyText({Color color = Colors.white54}) =>
      GoogleFonts.jost(fontSize: 11, fontWeight: FontWeight.w300, color: color);
}
