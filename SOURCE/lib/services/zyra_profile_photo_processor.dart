// Privacy boundary for every member profile photo before it reaches Storage.
//
// The native picker is deliberately asked to resize first so a very large
// camera source is not decoded at full resolution inside Dart. Native picker
// implementations can preserve EXIF (including GPS), however, so their output
// is never uploadable as-is. This second pass:
//   1. decodes the bounded picker output;
//   2. applies the EXIF orientation to the pixels;
//   3. bounds the review source to 3000 px and the final JPEG to 1440 px;
//   4. removes EXIF and textual metadata; and
//   5. emits a fresh JPEG at quality 85.
//
// Processing is fail-closed. Callers receive an exception for an empty,
// corrupt, unsupported or unverifiable result and must not upload the source
// bytes as a fallback.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:image/image.dart' as img;

class ZyraProfilePhotoProcessingException implements Exception {
  const ZyraProfilePhotoProcessingException(this.reason);

  final String reason;

  @override
  String toString() => 'ZyraProfilePhotoProcessingException: $reason';
}

class ZyraProfilePhotoProcessor {
  ZyraProfilePhotoProcessor._();

  static const int reviewMaxDimension = 3000;
  static const int maxDimension = 1440;
  static const int jpegQuality = 85;

  /// Processes away from the UI isolate. The native picker has already made
  /// the source reasonably small, but JPEG encoding is still CPU work and
  /// should not freeze the photo screen.
  static Future<Uint8List> process(Uint8List sourceBytes) =>
      compute(_processProfilePhotoBytes, sourceBytes);

  /// Leaves more source pixels available for the member's crop.
  static Future<Uint8List> processForReview(Uint8List sourceBytes) =>
      compute(_processReviewPhotoBytes, sourceBytes);

  /// Quarter-turn used by the review screen. It returns another clean JPEG
  /// and runs off the UI isolate so rotating a large portrait stays smooth.
  static Future<Uint8List> rotateClockwise(Uint8List sourceBytes) =>
      compute(_rotateProfilePhotoBytes, sourceBytes);

  @visibleForTesting
  static Uint8List processSynchronously(Uint8List sourceBytes) =>
      _processProfilePhotoBytes(sourceBytes);
}

Uint8List _rotateProfilePhotoBytes(Uint8List sourceBytes) {
  final decoded = img.decodeImage(sourceBytes, frame: 0);
  if (decoded == null) {
    throw const ZyraProfilePhotoProcessingException(
      'unsupported or unreadable source',
    );
  }
  final rotated = img.copyRotate(decoded, angle: 90)
    ..exif = img.ExifData()
    ..textData = null
    ..iccProfile = null
    ..extraChannels = null;
  return Uint8List.fromList(
    img.JpegEncoder(
      quality: ZyraProfilePhotoProcessor.jpegQuality,
    ).encode(rotated, singleFrame: true),
  );
}

Uint8List _processReviewPhotoBytes(Uint8List sourceBytes) =>
    _normalisePhotoBytes(
      sourceBytes,
      ZyraProfilePhotoProcessor.reviewMaxDimension,
    );

Uint8List _processProfilePhotoBytes(Uint8List sourceBytes) =>
    _normalisePhotoBytes(sourceBytes, ZyraProfilePhotoProcessor.maxDimension);

Uint8List _normalisePhotoBytes(Uint8List sourceBytes, int maxDimension) {
  try {
    if (sourceBytes.isEmpty) {
      throw const ZyraProfilePhotoProcessingException('empty source');
    }

    final decoded = img.decodeImage(sourceBytes, frame: 0);
    if (decoded == null || decoded.width < 1 || decoded.height < 1) {
      throw const ZyraProfilePhotoProcessingException(
        'unsupported or unreadable source',
      );
    }

    // Apply orientation before removing the tag that described it.
    var processed = img.bakeOrientation(decoded);

    final longestEdge = math.max(processed.width, processed.height);
    if (longestEdge > maxDimension) {
      final scale = maxDimension / longestEdge;
      processed = img.copyResize(
        processed,
        width: math.max(1, (processed.width * scale).round()),
        height: math.max(1, (processed.height * scale).round()),
        interpolation: img.Interpolation.average,
      );
    }

    // Source ICC profiles can contain arbitrary descriptive tags. Retain
    // pixels only and encode a fresh JPEG without copied metadata.
    processed = img.Image.from(processed, noAnimation: true)
      ..exif = img.ExifData()
      ..textData = null
      ..iccProfile = null
      ..extraChannels = null;

    final output = img.JpegEncoder(
      quality: ZyraProfilePhotoProcessor.jpegQuality,
    ).encode(processed, singleFrame: true);

    // Verify our own boundary rather than assuming the encoder honoured it.
    final verified = img.decodeJpg(output);
    if (verified == null ||
        verified.width > maxDimension ||
        verified.height > maxDimension ||
        !verified.exif.isEmpty ||
        verified.iccProfile != null ||
        verified.textData != null) {
      throw const ZyraProfilePhotoProcessingException(
        'sanitised output verification failed',
      );
    }

    return output;
  } on ZyraProfilePhotoProcessingException {
    rethrow;
  } catch (_) {
    throw const ZyraProfilePhotoProcessingException(
      'unsupported or unreadable source',
    );
  }
}
