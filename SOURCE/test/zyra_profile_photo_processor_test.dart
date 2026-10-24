import 'dart:io' show SocketException;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;
import 'package:zyra/services/zyra_photo_service.dart';
import 'package:zyra/services/zyra_profile_photo_processor.dart';

Uint8List _jpegWithSensitiveExif({
  required int width,
  required int height,
  int orientation = 1,
}) {
  final source = img.Image(width: width, height: height);
  img.fill(source, color: img.ColorRgb8(92, 61, 112));
  source.exif.imageIfd
    ..orientation = orientation
    ..make = 'Test camera'
    ..model = 'Private device';
  source.exif.exifIfd[0x9003] = img.IfdValueAscii('2026:09:24 12:00:00');
  source.exif.gpsIfd
    ..[0x0001] = img.IfdValueAscii('N')
    ..[0x0002] = img.IfdValueRational(51, 1)
    ..[0x0003] = img.IfdValueAscii('W')
    ..[0x0004] = img.IfdValueRational(1, 1);
  return img.encodeJpg(source, quality: 95);
}

void main() {
  group('ZYRA profile-photo privacy processing', () {
    test('bakes orientation and removes EXIF including GPS', () {
      final source = _jpegWithSensitiveExif(
        width: 200,
        height: 100,
        orientation: 6,
      );
      final sourceExif = img.decodeJpgExif(source);
      expect(sourceExif, isNotNull);
      expect(sourceExif!.gpsIfd.isEmpty, isFalse);
      expect(sourceExif.imageIfd.orientation, 6);

      final output = ZyraProfilePhotoProcessor.processSynchronously(source);
      final decoded = img.decodeJpg(output);

      expect(decoded, isNotNull);
      expect(decoded!.width, 100);
      expect(decoded.height, 200);
      expect(decoded.exif.isEmpty, isTrue);
      expect(img.decodeJpgExif(output), isNull);
    });

    test('enforces a 1440px longest edge without changing aspect ratio', () {
      final source = _jpegWithSensitiveExif(width: 2000, height: 1000);

      final output = ZyraProfilePhotoProcessor.processSynchronously(source);
      final decoded = img.decodeJpg(output)!;

      expect(decoded.width, ZyraProfilePhotoProcessor.maxDimension);
      expect(decoded.height, 720);
      expect(decoded.exif.isEmpty, isTrue);
    });

    test('does not enlarge an image already inside the bound', () {
      final source = _jpegWithSensitiveExif(width: 320, height: 480);

      final output = ZyraProfilePhotoProcessor.processSynchronously(source);
      final decoded = img.decodeJpg(output)!;

      expect(decoded.width, 320);
      expect(decoded.height, 480);
    });

    test(
      'production isolate path returns the same sanitised contract',
      () async {
        final source = _jpegWithSensitiveExif(
          width: 1600,
          height: 900,
          orientation: 1,
        );

        final output = await ZyraProfilePhotoProcessor.process(source);
        final decoded = img.decodeJpg(output)!;

        expect(decoded.width, ZyraProfilePhotoProcessor.maxDimension);
        expect(decoded.height, 810);
        expect(decoded.exif.isEmpty, isTrue);
        expect(img.decodeJpgExif(output), isNull);
      },
    );

    test('always emits JPEG, including for a transparent PNG source', () {
      final source = img.Image(width: 20, height: 20, numChannels: 4);
      img.fill(source, color: img.ColorRgba8(255, 0, 0, 100));
      source.textData = {'Comment': 'must not survive'};

      final output = ZyraProfilePhotoProcessor.processSynchronously(
        img.encodePng(source),
      );

      expect(output.take(2), orderedEquals(<int>[0xff, 0xd8]));
      final decoded = img.decodeJpg(output)!;
      expect(decoded.exif.isEmpty, isTrue);
      expect(decoded.textData, isNull);
    });

    test(
      'review rotation turns clockwise and keeps output metadata-free',
      () async {
        final source = _jpegWithSensitiveExif(width: 320, height: 480);

        final output = await ZyraProfilePhotoProcessor.rotateClockwise(source);
        final decoded = img.decodeJpg(output)!;

        expect(decoded.width, 480);
        expect(decoded.height, 320);
        expect(decoded.exif.isEmpty, isTrue);
        expect(img.decodeJpgExif(output), isNull);
      },
    );

    test('fails closed for corrupt input', () {
      expect(
        () => ZyraProfilePhotoProcessor.processSynchronously(
          Uint8List.fromList(<int>[1, 2, 3, 4]),
        ),
        throwsA(isA<ZyraProfilePhotoProcessingException>()),
      );
    });
  });

  group('profile-photo failure diagnostics', () {
    test('distinguishes session, RLS, connection and processing failures', () {
      expect(
        ZyraPhotoService.classifyFailure(
          const StorageException('not authenticated', statusCode: '401'),
        ),
        ZyraPhotoFailureKind.authentication,
      );
      expect(
        ZyraPhotoService.classifyFailure(
          const StorageException('row policy', statusCode: '403'),
        ),
        ZyraPhotoFailureKind.accessDenied,
      );
      expect(
        ZyraPhotoService.classifyFailure(const SocketException('offline')),
        ZyraPhotoFailureKind.connection,
      );
      expect(
        ZyraPhotoService.classifyFailure(http.ClientException('offline')),
        ZyraPhotoFailureKind.connection,
      );
      expect(
        ZyraPhotoService.classifyFailure(
          const ZyraProfilePhotoProcessingException('bad source'),
        ),
        ZyraPhotoFailureKind.processing,
      );
      expect(
        ZyraPhotoService.classifyFailure(
          PlatformException(code: 'photo_decode_failed'),
        ),
        ZyraPhotoFailureKind.processing,
      );
    });

    test('support references are stable and never include exception text', () {
      expect(ZyraPhotoFailureKind.authentication.referenceCode, 'ZY-PH-01');
      expect(ZyraPhotoFailureKind.accessDenied.referenceCode, 'ZY-PH-02');
      expect(ZyraPhotoFailureKind.connection.referenceCode, 'ZY-PH-03');
      expect(ZyraPhotoFailureKind.processing.referenceCode, 'ZY-PH-04');
      expect(ZyraPhotoFailureKind.storage.referenceCode, 'ZY-PH-05');
      expect(ZyraPhotoFailureKind.unknown.referenceCode, 'ZY-PH-06');
      for (final kind in ZyraPhotoFailureKind.values) {
        expect(kind.memberMessage, isNot(contains('private-path')));
      }
    });
  });
}
