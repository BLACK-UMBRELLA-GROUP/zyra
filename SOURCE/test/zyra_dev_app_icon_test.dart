import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_pkg;
import 'package:zyra/services/zyra_dev_app_icon.dart';
import 'package:zyra/theme/zyra_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('zyra.test/app_icon');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('reads the icon iOS says is currently on the Home Screen', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getAppIconState');
      return <String, dynamic>{'supported': true, 'iconName': 'ZyraRisingDawn'};
    });
    final controller = ZyraDevAppIconController(
      channel: channel,
      isIOSOverride: true,
    );

    await controller.load();

    expect(controller.supported, isTrue);
    expect(controller.selected, ZyraDevAppIcon.risingDawn);
  });

  test('sends the alternate name and can restore the primary icon', () async {
    String? requestedName = 'not-called';
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAppIconState') {
        return <String, dynamic>{'supported': true, 'iconName': null};
      }
      expect(call.method, 'setAppIcon');
      requestedName = (call.arguments as Map)['iconName'] as String?;
      return <String, dynamic>{'supported': true, 'iconName': requestedName};
    });
    final controller = ZyraDevAppIconController(
      channel: channel,
      isIOSOverride: true,
    );

    await controller.load();
    await controller.select(ZyraDevAppIcon.openFrame);
    expect(requestedName, 'ZyraOpenFrame');
    expect(controller.selected, ZyraDevAppIcon.openFrame);

    await controller.select(ZyraDevAppIcon.goldHorizonCurrent);
    expect(requestedName, isNull);
    expect(controller.selected, ZyraDevAppIcon.goldHorizonCurrent);
  });

  test(
    'retired iOS icon can be reset even when its fallback is Current',
    () async {
      var resetCalls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getAppIconState') {
          return <String, dynamic>{
            'supported': true,
            'iconName': 'ZyraRisingHorizonLarge',
          };
        }
        expect(call.method, 'setAppIcon');
        expect((call.arguments as Map)['iconName'], isNull);
        resetCalls++;
        return <String, dynamic>{'supported': true, 'iconName': null};
      });
      final controller = ZyraDevAppIconController(
        channel: channel,
        isIOSOverride: true,
      );

      await controller.load();
      expect(controller.selected, ZyraDevAppIcon.goldHorizonCurrent);
      expect(controller.hasRetiredIcon, isTrue);
      await controller.select(ZyraDevAppIcon.goldHorizonCurrent);
      expect(resetCalls, 1);
      expect(controller.selected, ZyraDevAppIcon.goldHorizonCurrent);
      expect(controller.hasRetiredIcon, isFalse);
      await controller.select(ZyraDevAppIcon.goldHorizonCurrent);
      expect(resetCalls, 1, reason: 'Already-current selection is a no-op.');
    },
  );

  test('failed native icon switch does not change the selected icon', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAppIconState') {
        return <String, dynamic>{'supported': true, 'iconName': 'ZyraGoldHalo'};
      }
      throw PlatformException(code: 'change_failed');
    });
    final controller = ZyraDevAppIconController(
      channel: channel,
      isIOSOverride: true,
    );
    await controller.load();
    await controller.select(ZyraDevAppIcon.orbitLight);

    expect(controller.selected, ZyraDevAppIcon.goldHalo);
    expect(controller.hasRetiredIcon, isFalse);
    expect(controller.messageIsError, isTrue);
    expect(controller.busy, isFalse);
  });

  test('non-iOS preview cannot make a native Home Screen change', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls++;
      return <String, dynamic>{'supported': true, 'iconName': null};
    });
    final controller = ZyraDevAppIconController(
      channel: channel,
      isIOSOverride: false,
    );
    await controller.load();
    await controller.select(ZyraDevAppIcon.goldHalo);

    expect(controller.loaded, isTrue);
    expect(controller.supported, isFalse);
    expect(controller.selected, ZyraDevAppIcon.goldHorizonCurrent);
    expect(nativeCalls, 0);
  });

  test('eleven options expose one primary and ten distinct alternates', () {
    final names = ZyraDevAppIcon.values
        .map((option) => option.alternateName)
        .whereType<String>()
        .toSet();

    expect(ZyraDevAppIcon.values, hasLength(11));
    expect(names, hasLength(10));
    expect(
      ZyraDevAppIcon.values.map((option) => option.label).toSet(),
      hasLength(11),
    );
    expect(
      ZyraDevAppIcon.values.map((option) => option.previewAsset).toSet(),
      hasLength(11),
    );
    expect(ZyraDevAppIcon.values.first, ZyraDevAppIcon.goldHorizonCurrent);
    expect(ZyraDevAppIcon.goldHorizonCurrent.alternateName, isNull);
  });

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
          ZyraDevAppIcon.values
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
        ZyraDevAppIcon.values
            .map((option) => option.alternateName)
            .whereType<String>(),
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

    for (final icon in ZyraDevAppIcon.values) {
      final preview = File(icon.previewAsset).readAsBytesSync();
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
      File(ZyraDevAppIcon.goldHorizonCurrent.previewAsset).readAsBytesSync(),
      reason: 'The Home Screen primary must match the Current toggle preview.',
    );
  });

  test('all icon wordmarks use the exact Quiet Horizon splash gold', () {
    final colour = ZyraColors.splashWordmark.toARGB32();
    final red = (colour >> 16) & 0xFF;
    final green = (colour >> 8) & 0xFF;
    final blue = colour & 0xFF;

    for (final icon in ZyraDevAppIcon.values) {
      final preview = image_pkg.decodePng(
        File(icon.previewAsset).readAsBytesSync(),
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
    for (final icon in ZyraDevAppIcon.values) {
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
      for (final icon in ZyraDevAppIcon.values)
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
