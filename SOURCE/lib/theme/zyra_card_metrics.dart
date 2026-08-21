/// ONE CARD METRIC FOR THE WHOLE APP — 2026-08-05 (Founder: "look at how
/// the cards are different sizes. I kinda want all cards to be the same for
/// a cleaner UI, this includes the Wali cards on the Wali tab").
///
/// Every list row that shows a person — Guardian Suggestions, Considered,
/// Saved, Passed, the Guardian cards on the Wali tab, and (since
/// DR-ZYRA-171) the Guardian-side ward cards — uses these numbers. They
/// were previously chosen per-widget: 52pt thumbnails here, 56×64 on
/// suggestions, 44 and 36 on the Wali tab, with padding of 12, 13 and 16.
/// Nothing was wrong individually; together they read as four different
/// design systems on four screens.
///
/// MOVED HERE 2026-08-15 (DR-ZYRA-171, audit UI-03). This class was
/// declared inside connections_screen.dart, so four unrelated screens
/// imported a 4,000-line screen file to reach three constants — the exact
/// coupling the audit flagged. A design token lives in the theme, beside
/// the colours and text it composes with. Values unchanged, byte for byte.
library;

class ZyraCardMetrics {
  ZyraCardMetrics._();

  /// Square. A square thumbnail is the only shape that stays consistent
  /// whether the row carries one line of text or three — the 56×64
  /// portrait used on suggestions is what made those cards taller than
  /// everything around them.
  static const double thumb = 52;
  static const double thumbRadius = 10;
  static const double padding = 12;
  static const double cardRadius = 14;
  static const double gap = 14;

  /// Vertical space between consecutive cards in a list.
  static const double spacing = 10;
}
