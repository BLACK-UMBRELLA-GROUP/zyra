import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  const productionBundleId = 'app.zyraconnect.zyra';
  const productionIosClient =
      '734578322486-eoh5ba4usl0svs9ihqh2ltagqfgusnft.apps.googleusercontent.com';
  const productionServerClient =
      '734578322486-gvi63m04ogd7bbmsunokuq2klkepetq1.apps.googleusercontent.com';

  test('only production iOS schemes remain active', () {
    final schemes = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('.xcscheme'))
        .toSet();
    final production = _read(
      'ios/Runner.xcodeproj/xcshareddata/xcschemes/production.xcscheme',
    );

    expect(schemes, {'Runner.xcscheme', 'production.xcscheme'});
    expect(production, contains('buildConfiguration = "Debug-production"'));
    expect(production, contains('buildConfiguration = "Profile-production"'));
    expect(production, contains('buildConfiguration = "Release-production"'));
    expect(
      File(
        'ios/Runner.xcodeproj/xcshareddata/xcschemes/'
        'foundertest.xcscheme',
      ).existsSync(),
      isFalse,
    );
  });

  test('production flavor preserves the canonical identity and OAuth', () {
    for (final mode in ['Debug', 'Profile', 'Release']) {
      final config = _read('ios/Flutter/$mode-production.xcconfig');

      expect(config, contains('APP_DISPLAY_NAME = ZYRA'));
      expect(
        config,
        contains('PRODUCT_BUNDLE_IDENTIFIER = $productionBundleId'),
      );
      expect(config, contains('GOOGLE_IOS_CLIENT_ID = $productionIosClient'));
      expect(
        config,
        contains('GOOGLE_SERVER_CLIENT_ID = $productionServerClient'),
      );
      expect(config, contains('ZYRA_APP_FLAVOR = production'));
      expect(
        File('ios/Flutter/$mode-foundertest.xcconfig').existsSync(),
        isFalse,
      );
    }
  });

  test('project contains no retired Test configurations or identity', () {
    final project = _read('ios/Runner.xcodeproj/project.pbxproj');

    expect(project, isNot(contains('foundertest')));
    expect(project, isNot(contains('ZYRATest')));
    expect(project, isNot(contains('app.zyraconnect.zyra.test')));
    for (final family in ['F100', 'F110', 'F120', 'F130']) {
      for (final suffix in ['01', '02', '03']) {
        expect(
          project,
          contains('${family}000000000000000000$suffix'),
          reason: '$family production configuration $suffix',
        );
      }
      for (final suffix in ['04', '05', '06']) {
        expect(
          project,
          isNot(contains('${family}000000000000000000$suffix')),
          reason: '$family retired configuration $suffix',
        );
      }
    }
  });

  test('retired native Test assets and configuration are absent', () {
    for (final path in const [
      'ios/Flutter/FounderTestSecrets.xcconfig.example',
      'ios/Runner/Assets.xcassets/ZYRATest.appiconset',
      'ios/ZYRATestInternalExportOptions.plist',
      'assets/icon/icon_founder_test.png',
      'config/founder_test.public.json.example',
    ]) {
      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
    }
  });

  test(
    'shared plist still resolves identity and Google values from settings',
    () {
      final info = _read('ios/Runner/Info.plist');

      expect(info, contains(r'<string>$(APP_DISPLAY_NAME)</string>'));
      expect(info, contains(r'<string>$(APP_BUNDLE_NAME)</string>'));
      expect(info, contains(r'<string>$(GOOGLE_IOS_URL_SCHEME)</string>'));
      expect(info, contains(r'<string>$(GOOGLE_IOS_CLIENT_ID)</string>'));
      expect(info, contains(r'<string>$(GOOGLE_SERVER_CLIENT_ID)</string>'));
      expect(info, isNot(contains(productionIosClient)));
      expect(info, isNot(contains(productionServerClient)));
    },
  );

  test('main internal export and production icon remain available', () {
    final options = _read('ios/TestFlightInternalExportOptions.plist');
    final builder = _read('tool/build_internal_founder_ipa.sh');

    expect(options, contains('<key>testFlightInternalTestingOnly</key>'));
    expect(options, contains('<true/>'));
    expect(
      options,
      contains('<key>destination</key>\n\t<string>export</string>'),
    );
    expect(options, isNot(contains('<string>upload</string>')));
    expect(builder, contains('--flavor production'));
    expect(
      builder,
      contains(
        '--export-options-plist=ios/TestFlightInternalExportOptions.plist',
      ),
    );
    expect(builder, isNot(contains('foundertest')));
    expect(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
        'Icon-App-1024x1024@1x.png',
      ).existsSync(),
      isTrue,
    );
  });
}
