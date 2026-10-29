import 'package:flutter/material.dart';

import '../dev/zyra_journey_icon_selection.dart';
export '../dev/zyra_journey_icon_selection.dart' show ZyraJourneyIconDesign;

/// The Founder-selected Couple symbol is the canonical Journey icon.
/// The caller owns navigation size and tint.
class ZyraJourneyIcon extends StatelessWidget {
  const ZyraJourneyIcon({
    super.key,
    required this.color,
    this.size = 22,
    this.design,
  });

  final Color color;
  final double size;

  /// The selected Couple artwork is independent of account or preview role.
  final ZyraJourneyIconDesign? design;

  @override
  Widget build(BuildContext context) =>
      _paint(design ?? ZyraJourneyIconDesign.couple);

  Widget _paint(ZyraJourneyIconDesign selected) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: ZyraJourneyIconPainter(color: color, design: selected),
      ),
    ),
  );
}

@visibleForTesting
class ZyraJourneyIconPainter extends CustomPainter {
  const ZyraJourneyIconPainter({
    required this.color,
    this.design = ZyraJourneyIconDesign.couple,
  });

  final Color color;
  final ZyraJourneyIconDesign design;
  static const double viewBoxSize = 24;
  static const double strokeWidth = 1.8;
  static const double artworkExtent = 21;
  static final _artworks = <ZyraJourneyIconDesign, _JourneyArtwork>{};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final artwork = _artworks.putIfAbsent(design, _couple);
    // Fit the visible stroke/fill, not a nominal 24-unit box containing
    // uneven padding. Uniform scale retains each symbol's proportions.
    final bounds = artwork.bounds;
    final scale = artworkExtent / bounds.longestSide;
    canvas.save();
    canvas.scale(size.width / viewBoxSize, size.height / viewBoxSize);
    canvas.translate(viewBoxSize / 2, viewBoxSize / 2);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // Keep one line weight after fitting; narrow drawings do not become
      // heavier than the other choices just because they need more scaling.
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in artwork.outlines) {
      canvas.drawPath(path, outline);
    }
    canvas.restore();
  }

  _JourneyArtwork _couple() => _JourneyArtwork([
    Path()..addOval(Rect.fromCircle(center: const Offset(8, 6), radius: 2.5)),
    Path()..addOval(Rect.fromCircle(center: const Offset(17, 7), radius: 2.3)),
    Path()
      ..moveTo(3, 20)
      ..lineTo(3, 17)
      ..cubicTo(3, 11.8, 13, 11.8, 13, 17)
      ..lineTo(13, 20)
      ..moveTo(14.6, 12.8)
      ..cubicTo(18, 11.8, 21, 13.8, 21, 17)
      ..lineTo(21, 20),
  ]);

  @override
  bool shouldRepaint(covariant ZyraJourneyIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.design != design;
}

/// Paint data also supplies the fit bounds, so future path edits cannot leave
/// a separate, stale sizing table. Separate outlines retain their draw order.
class _JourneyArtwork {
  _JourneyArtwork(this.outlines);

  final List<Path> outlines;

  late final Rect bounds = _paintedBounds();

  Rect _paintedBounds() {
    var result = _visiblePathBounds(
      outlines.first,
    ).inflate(ZyraJourneyIconPainter.strokeWidth / 2);
    for (final path in outlines.skip(1)) {
      result = result.expandToInclude(
        _visiblePathBounds(
          path,
        ).inflate(ZyraJourneyIconPainter.strokeWidth / 2),
      );
    }
    return result;
  }

  // getBounds includes unused Bezier control-point space (most visibly in
  // Linked). Measure each drawn contour instead, at <=1/8 of a viewBox unit.
  // This paint-only geometry and its bounds are cached once per design, never
  // recomputed during the nav's animation or stored as a member preference.
  static Rect _visiblePathBounds(Path path) {
    Rect? result;
    for (final contour in path.computeMetrics()) {
      final samples = (contour.length * 8).ceil().clamp(1, 1024);
      for (var index = 0; index <= samples; index++) {
        final point = contour
            .getTangentForOffset(contour.length * index / samples)
            ?.position;
        if (point == null) continue;
        final bounds = Rect.fromLTWH(point.dx, point.dy, 0, 0);
        result = result == null ? bounds : result.expandToInclude(bounds);
      }
    }
    return result ?? path.getBounds();
  }
}
