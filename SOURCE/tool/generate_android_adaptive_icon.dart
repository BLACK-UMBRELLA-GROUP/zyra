import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as image;

/// Builds Android's transparent adaptive-icon foreground from the approved
/// full-bleed launcher artwork without redrawing or re-typesetting the brand.
///
/// The source background is a smooth purple gradient. For every scanline we
/// sample clean pixels at both outer edges and interpolate the local background,
/// and recover the foreground alpha from the colour difference. This retains
/// the exact ZYRA wordmark, gold rule and glow while removing the square
/// background that Android launchers otherwise wrap in a white fallback tile.
void main() {
  const sourcePath = 'assets/icon/icon.png';
  const outputPath = 'assets/icon/android_adaptive_foreground.png';

  final sourceFile = File(sourcePath);
  final source = image.decodePng(sourceFile.readAsBytesSync());
  if (source == null) {
    stderr.writeln('Unable to decode $sourcePath');
    exitCode = 1;
    return;
  }

  final output = image.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  final sampleWidth = math.max(8, source.width ~/ 32);

  for (var y = 0; y < source.height; y++) {
    final left = [0.0, 0.0, 0.0];
    final right = [0.0, 0.0, 0.0];
    for (var offset = 0; offset < sampleWidth; offset++) {
      final a = source.getPixel(offset, y);
      final b = source.getPixel(source.width - 1 - offset, y);
      left[0] += a.r / sampleWidth;
      left[1] += a.g / sampleWidth;
      left[2] += a.b / sampleWidth;
      right[0] += b.r / sampleWidth;
      right[1] += b.g / sampleWidth;
      right[2] += b.b / sampleWidth;
    }
    // The new brand gradient is diagonal. One averaged scanline would leave
    // a translucent square at its edges; interpolation preserves transparency.
    final leftCentre = (sampleWidth - 1) / 2;
    final rightCentre = source.width - 1 - leftCentre;
    for (var x = 0; x < source.width; x++) {
      final fraction = (x - leftCentre) / (rightCentre - leftCentre);
      final backgroundRed = left[0] + (right[0] - left[0]) * fraction;
      final backgroundGreen = left[1] + (right[1] - left[1]) * fraction;
      final backgroundBlue = left[2] + (right[2] - left[2]) * fraction;
      final pixel = source.getPixel(x, y);
      final deltaRed = pixel.r - backgroundRed;
      final deltaGreen = pixel.g - backgroundGreen;
      final deltaBlue = pixel.b - backgroundBlue;
      final strongestDelta = math.max(
        deltaRed.abs(),
        math.max(deltaGreen.abs(), deltaBlue.abs()),
      );

      // Ignore only the tiny rounding variation in the mathematically smooth
      // gradient. The gradual alpha ramp deliberately retains the gold glow
      // and the anti-aliased edges of the approved lettering.
      final alpha = ((strongestDelta - 1.5) / 72.0).clamp(0.0, 1.0);
      if (alpha == 0) {
        output.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      final recoveredRed = (backgroundRed + (deltaRed / alpha)).clamp(
        0.0,
        255.0,
      );
      final recoveredGreen = (backgroundGreen + (deltaGreen / alpha)).clamp(
        0.0,
        255.0,
      );
      final recoveredBlue = (backgroundBlue + (deltaBlue / alpha)).clamp(
        0.0,
        255.0,
      );

      output.setPixelRgba(
        x,
        y,
        recoveredRed.round(),
        recoveredGreen.round(),
        recoveredBlue.round(),
        (alpha * 255).round(),
      );
    }
  }

  File(outputPath).writeAsBytesSync(image.encodePng(output, level: 9));
  stdout.writeln('Generated $outputPath');
}
