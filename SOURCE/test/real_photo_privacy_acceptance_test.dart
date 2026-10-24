import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zyra/services/zyra_profile_photo_processor.dart';

/// Opt-in acceptance test for real iPhone fixtures.
///
/// The fixtures remain outside the repository. Run with:
///
/// ZYRA_PHOTO_PRIVACY_FIXTURE_DIR=/protected/folder flutter test \
///   test/real_photo_privacy_acceptance_test.dart
///
/// A private working directory is created inside the supplied fixture folder,
/// never outside it, and is removed in `finally`. Test output reports only
/// counts, dimensions and metadata presence — never metadata values.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixturePath = Platform.environment['ZYRA_PHOTO_PRIVACY_FIXTURE_DIR'];
  if (fixturePath == null || fixturePath.isEmpty) {
    test('real-photo fixture acceptance is opt-in', () {
      markTestSkipped('Set ZYRA_PHOTO_PRIVACY_FIXTURE_DIR to run.');
    });
    return;
  }

  test('real iPhone fixtures emerge bounded and metadata-free', () async {
    final fixtureDir = Directory(fixturePath);
    expect(fixtureDir.existsSync(), isTrue, reason: 'Fixture folder missing.');
    final sources = fixtureDir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.heic'))
        .toList(growable: false);
    expect(sources, isNotEmpty, reason: 'No HEIC fixtures found.');

    final workDir = Directory(
      '${fixtureDir.path}/.zyra-photo-acceptance-$pid-${DateTime.now().microsecondsSinceEpoch}',
    );
    workDir.createSync();
    try {
      var preparedWithExif = 0;
      var preparedWithGps = 0;
      for (var index = 0; index < sources.length; index++) {
        final prepared = File('${workDir.path}/prepared-$index.jpg');
        final conversion = await Process.run('sips', [
          '-s',
          'format',
          'jpeg',
          '-Z',
          '${ZyraProfilePhotoProcessor.maxDimension}',
          sources[index].path,
          '--out',
          prepared.path,
        ]);
        expect(
          conversion.exitCode,
          0,
          reason: 'Native HEIC preparation failed for fixture ${index + 1}.',
        );

        final preparedBytes = prepared.readAsBytesSync();
        final preparedExif = img.decodeJpgExif(preparedBytes);
        if (preparedExif != null && !preparedExif.isEmpty) preparedWithExif++;
        if (preparedExif != null && !preparedExif.gpsIfd.isEmpty) {
          preparedWithGps++;
        }

        final output = ZyraProfilePhotoProcessor.processSynchronously(
          preparedBytes,
        );
        final decoded = img.decodeJpg(output);
        expect(decoded, isNotNull);
        expect(
          decoded!.width <= ZyraProfilePhotoProcessor.maxDimension,
          isTrue,
        );
        expect(
          decoded.height <= ZyraProfilePhotoProcessor.maxDimension,
          isTrue,
        );
        expect(decoded.exif.isEmpty, isTrue);
        expect(img.decodeJpgExif(output), isNull);
        expect(decoded.textData, isNull);
      }

      // The originals were independently verified to contain GPS. This count
      // records whether the native conversion preserved it; either way the
      // final ZYRA artifact must be metadata-free, as asserted above.
      // ignore: avoid_print
      print(
        'ZYRA real-photo acceptance: ${sources.length} passed; '
        'native prepared EXIF=$preparedWithExif, GPS=$preparedWithGps; '
        'final EXIF/GPS/device metadata=0.',
      );
    } finally {
      if (workDir.existsSync()) workDir.deleteSync(recursive: true);
    }
  });
}
