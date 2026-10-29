import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_pkg;
import 'package:zyra/theme/zyra_colors.dart';

// The native app-icon assets remain installed after the Dart selector retires.
// Keep this expected native contract independent of the removed selector API.
const _nativeIcons = <({String name, String? alternateName})>[
  (name: 'goldHorizonCurrent', alternateName: null),
  (name: 'goldHalo', alternateName: 'ZyraGoldHalo'),
  (name: 'orbitLight', alternateName: 'ZyraOrbitLight'),
  (name: 'twinGlow', alternateName: 'ZyraTwinGlow'),
  (name: 'openFrame', alternateName: 'ZyraOpenFrame'),
  (name: 'editorialGold', alternateName: 'ZyraEditorialGold'),
  (name: 'risingDawn', alternateName: 'ZyraRisingDawn'),
  (name: 'quietMonogram', alternateName: 'ZyraQuietMonogram'),
  (name: 'silkRibbon', alternateName: 'ZyraSilkRibbon'),
  (name: 'constellation', alternateName: 'ZyraConstellation'),
  (name: 'royalSeal', alternateName: 'ZyraRoyalSeal'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Xcode includes exactly the ten active alternate icon names', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final settings = project
        .split('\n')
        .where(
          (line) =>
              line.contains('ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES'),
        );
    expect(settings, hasLength(6));
    expect(
      project
          .split('\n')
          .where(
            (line) => line.contains(
              'ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = NO',
            ),
          ),
      hasLength(6),
    );
    for (final setting in settings) {
      final registered = RegExp(
        r'"([^\"]+)"',
      ).firstMatch(setting)!.group(1)!.split(RegExp(r'\s+'));
      expect(
        registered,
        unorderedEquals(
          _nativeIcons
              .map((option) => option.alternateName)
              .whereType<String>(),
        ),
      );
    }
    expect(
      project,
      isNot(
        contains('ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = AppIcon'),
      ),
    );
    expect(
      project,
      isNot(
        contains(
          'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon',
        ),
      ),
    );
  });

  test('native icon allowlist matches the ten active alternates exactly', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final block = RegExp(
      r'let allowedNames: Set<String> = \[([^\]]+)\]',
      dotAll: true,
    ).firstMatch(appDelegate)!.group(1)!;
    final names = RegExp(
      r'"([^\"]+)"',
    ).allMatches(block).map((match) => match.group(1)!);

    expect(
      names,
      unorderedEquals(
        _nativeIcons.map((option) => option.alternateName).whereType<String>(),
      ),
    );
  });

  test('eleven preview assets match their native masters and are distinct', () {
    final previewHashes = <String>{};
    final previewDirectory = Directory('assets/icon/previews');
    expect(
      previewDirectory.listSync().where((file) => file.path.endsWith('.png')),
      hasLength(11),
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('assets/icon/previews/'),
    );

    for (final icon in _nativeIcons) {
      final preview = File(
        'assets/icon/previews/${icon.name}.png',
      ).readAsBytesSync();
      final nativeName = icon.alternateName ?? 'AppIcon';
      final native = File(
        'ios/Runner/Assets.xcassets/$nativeName.appiconset/'
        'Icon-App-1024x1024@1x.png',
      ).readAsBytesSync();
      final hash = sha256.convert(preview).toString();
      expect(hash, sha256.convert(native).toString(), reason: icon.name);
      previewHashes.add(hash);
    }
    expect(
      previewHashes,
      hasLength(11),
      reason: 'Each study has distinct art.',
    );
    expect(
      File('assets/icon/icon.png').readAsBytesSync(),
      File('assets/icon/previews/goldHorizonCurrent.png').readAsBytesSync(),
      reason: 'The Home Screen primary must match its preview asset.',
    );
  });

  test('all icon wordmarks use the exact Quiet Horizon splash gold', () {
    final colour = ZyraColors.splashWordmark.toARGB32();
    final red = (colour >> 16) & 0xFF;
    final green = (colour >> 8) & 0xFF;
    final blue = colour & 0xFF;

    for (final icon in _nativeIcons) {
      final preview = image_pkg.decodePng(
        File('assets/icon/previews/${icon.name}.png').readAsBytesSync(),
      );
      expect(preview, isNotNull, reason: icon.name);
      var wordmarkPixels = 0;
      for (var y = 0; y < preview!.height; y++) {
        for (var x = 0; x < preview.width; x++) {
          final pixel = preview.getPixel(x, y);
          if (pixel.r == red && pixel.g == green && pixel.b == blue) {
            wordmarkPixels++;
          }
        }
      }
      expect(wordmarkPixels, greaterThan(100), reason: icon.name);
    }
  });

  test('every active native icon declares complete iPhone and iPad assets', () {
    for (final icon in _nativeIcons) {
      final nativeName = icon.alternateName ?? 'AppIcon';
      final iconDirectory = 'ios/Runner/Assets.xcassets/$nativeName.appiconset';
      final contents =
          jsonDecode(File('$iconDirectory/Contents.json').readAsStringSync())
              as Map<String, dynamic>;
      final images = (contents['images'] as List).cast<Map<String, dynamic>>();

      for (final idiom in ['iphone', 'ipad', 'ios-marketing']) {
        expect(
          images.where((entry) => entry['idiom'] == idiom),
          isNotEmpty,
          reason: '$nativeName must declare $idiom assets.',
        );
      }
      for (final image in images) {
        final filename = image['filename'] as String;
        expect(
          File('$iconDirectory/$filename').existsSync(),
          isTrue,
          reason: '$nativeName is missing its declared $filename.',
        );
      }
    }
  });

  test(
    'Android adaptive foreground has no residual square background',
    () async {
      final codec = await ui.instantiateImageCodec(
        File('assets/icon/android_adaptive_foreground.png').readAsBytesSync(),
      );
      final image = (await codec.getNextFrame()).image;
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      int alpha(int x, int y) => bytes.getUint8((y * image.width + x) * 4 + 3);
      for (final x in [8, image.width - 9]) {
        for (final y in [8, 256, 512, 768, image.height - 9]) {
          expect(alpha(x, y), lessThanOrEqualTo(2));
        }
      }
      var solidGlyphPixels = 0;
      for (var x = 120; x < 880; x += 10) {
        for (var y = 430; y < 600; y += 10) {
          if (alpha(x, y) > 230) solidGlyphPixels++;
        }
      }
      expect(solidGlyphPixels, greaterThan(100));
      image.dispose();
      codec.dispose();
    },
  );

  test('all eleven native icons use opaque Midnight Plum endpoints', () async {
    for (final path in [
      'assets/icon/icon.png',
      for (final icon in _nativeIcons)
        'ios/Runner/Assets.xcassets/${icon.alternateName ?? 'AppIcon'}.appiconset/'
            'Icon-App-1024x1024@1x.png',
    ]) {
      final codec = await ui.instantiateImageCodec(
        File(path).readAsBytesSync(),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      expect(image.width, 1024, reason: path);
      expect(image.height, 1024, reason: path);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(bytes, isNotNull, reason: path);

      List<int> pixelAt(int x, int y) {
        final offset = (y * image.width + x) * 4;
        return [
          bytes!.getUint8(offset),
          bytes.getUint8(offset + 1),
          bytes.getUint8(offset + 2),
        ];
      }

      expect(pixelAt(8, 8), closeToRgb(const [0x30, 0x20, 0x3F]), reason: path);
      expect(
        pixelAt(image.width - 9, image.height - 9),
        closeToRgb(const [0x16, 0x0E, 0x20]),
        reason: path,
      );
      for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4) {
        if (bytes.getUint8(offset) != 255) {
          fail('App-icon master must be opaque: $path at RGBA byte $offset');
        }
      }
      image.dispose();
      codec.dispose();
    }
  });
}

Matcher closeToRgb(List<int> expected, {int tolerance = 2}) =>
    predicate<List<int>>(
      (actual) =>
          actual.length == 3 &&
          (actual[0] - expected[0]).abs() <= tolerance &&
          (actual[1] - expected[1]).abs() <= tolerance &&
          (actual[2] - expected[2]).abs() <= tolerance,
      'RGB within $tolerance of $expected',
    );
