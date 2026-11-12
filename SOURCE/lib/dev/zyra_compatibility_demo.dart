import '../models/zyra_compatibility_area.dart';

/// Synthetic bands for callers that have already admitted a local sample.
abstract final class ZyraCompatibilityDemo {
  static const _bands = [
    ZyraCompatibilityBand.strong,
    ZyraCompatibilityBand.good,
    ZyraCompatibilityBand.strong,
    ZyraCompatibilityBand.someDifferences,
    ZyraCompatibilityBand.good,
    ZyraCompatibilityBand.strong,
    ZyraCompatibilityBand.good,
    ZyraCompatibilityBand.someDifferences,
    ZyraCompatibilityBand.strong,
    ZyraCompatibilityBand.good,
    ZyraCompatibilityBand.notEnoughAnswers,
    ZyraCompatibilityBand.good,
  ];

  static Map<ZyraCompatibilityArea, ZyraCompatibilityBand> bandsFor(
    String profileId,
  ) {
    final fixtureId = profileId.startsWith('draft-')
        ? profileId.substring('draft-'.length)
        : profileId;
    return Map.unmodifiable({
      for (final area in ZyraCompatibilityArea.values)
        area: _bands[(area.index + fixtureId.length) % _bands.length],
    });
  }
}
