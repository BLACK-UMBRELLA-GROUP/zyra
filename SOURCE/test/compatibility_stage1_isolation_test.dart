// Read-only source-boundary evidence. Does not start the app or use member data.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _moduleRoot = 'tools/compatibility_stage1';
const _moduleNames = {
  'models.dart',
  'bank_adapter.dart',
  'manifest.dart',
  'validator.dart',
  'legacy_review.dart',
  'scorer.dart',
};
const _pureMetadataImports = {
  'package:zyra/models/onboarding_question.dart',
  'package:zyra/data/chapter3_categories.dart',
  'package:zyra/data/zyra_reference_data.dart',
};
const _prunedDirectories = {
  '.git',
  '.dart_tool',
  'build',
  'Pods',
  'Carthage',
  '.symlinks',
  '.plugin_symlinks',
  'ephemeral',
  'node_modules',
};
const _excludedCredentialConfigs = {
  'google-services.json',
  'GoogleService-Info.plist',
};
const _sourceExtensions = {
  'dart',
  'swift',
  'm',
  'mm',
  'h',
  'kt',
  'java',
  'gradle',
  'kts',
  'xml',
  'plist',
  'pbxproj',
  'xcconfig',
  'yaml',
  'yml',
  'sh',
  'html',
  'js',
  'json',
  'cmake',
  'txt',
  'entitlements',
};
const _researchTests = {
  'compatibility_stage1_manifest_test.dart',
  'compatibility_stage1_applicability_test.dart',
  'compatibility_stage1_validation_test.dart',
  'compatibility_stage1_legacy_review_test.dart',
  'compatibility_stage1_chapter2_test.dart',
  'compatibility_stage1_scorer_test.dart',
};
final _accountIdentifier = RegExp(
  r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
);

String _withoutComments(String source) => source
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'//[^\r\n]*'), '');

List<String> _directives(String source) => [
  for (final match in RegExp(
    r'''\b(?:import|export|part)\s+['"]([^'"]+)['"]''',
  ).allMatches(_withoutComments(source)))
    match.group(1)!,
];

Iterable<File> _sourceFiles(Directory directory) sync* {
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(followLinks: false)) {
    final basename = entity.path.split(Platform.pathSeparator).last;
    if (entity is Directory) {
      if (_prunedDirectories.contains(basename) ||
          basename.contains('PRIVATE') ||
          basename.startsWith('.')) {
        continue;
      }
      yield* _sourceFiles(entity);
    } else if (entity is File &&
        !basename.startsWith('.') &&
        !_excludedCredentialConfigs.contains(basename)) {
      final extension = basename.split('.').last;
      if (_sourceExtensions.contains(extension)) yield entity;
    }
  }
}

void main() {
  test('only the six allowlisted unwired research modules exist', () {
    final moduleDirectory = Directory(_moduleRoot);
    expect(moduleDirectory.existsSync(), isTrue);
    final entries = moduleDirectory.listSync(followLinks: false);
    expect(entries.every((entry) => entry is File), isTrue);
    expect(
      entries
          .map((entry) => entry.path.split(Platform.pathSeparator).last)
          .toSet(),
      _moduleNames,
    );
  });

  test(
    'research imports stay pure and only adapter reaches static metadata',
    () {
      for (final name in _moduleNames) {
        final source = File('$_moduleRoot/$name').readAsStringSync();
        for (final directive in _directives(source)) {
          final allowedLocal = _moduleNames.contains(directive);
          final allowedMetadata =
              name == 'bank_adapter.dart' &&
              _pureMetadataImports.contains(directive);
          expect(
            allowedLocal || allowedMetadata,
            isTrue,
            reason: '$name has prohibited dependency $directive',
          );
        }
        final code = _withoutComments(source);
        expect(
          RegExp(
            r'\b(?:Supabase|Firebase|HttpClient|HttpServer|WebSocket|Socket|'
            r'SharedPreferences|Hive|Isar|File|Directory|Process|Platform|'
            r'Random|DateTime|Timer)\b',
          ).hasMatch(code),
          isFalse,
          reason:
              '$name contains runtime, persistence, network or clock access',
        );
        expect(
          code.contains('main('),
          isFalse,
          reason: '$name must not initialize an application',
        );
      }
    },
  );

  test('adapter metadata dependencies are themselves pure', () {
    for (final metadataImport in _pureMetadataImports) {
      final path = File(
        metadataImport.replaceFirst('package:zyra/', 'lib/'),
      ).absolute.path;
      for (final directive in _directives(File(path).readAsStringSync())) {
        expect(
          directive,
          '../models/onboarding_question.dart',
          reason:
              '$metadataImport acquired an unexpected dependency $directive',
        );
      }
    }
  });

  test('production Dart and native configuration never reach the harness', () {
    final files = <File>[
      for (final directory in [
        'lib',
        'ios',
        'android',
        'macos',
        'windows',
        'linux',
        'web',
      ])
        ..._sourceFiles(Directory(directory)),
      for (final path in ['pubspec.yaml', 'analysis_options.yaml', 'run.sh'])
        if (File(path).existsSync()) File(path),
    ];
    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      if (file.path.endsWith('.dart')) {
        expect(
          _withoutComments(source).contains('compatibility_stage1'),
          isFalse,
          reason: '${file.path} refers to the unwired research harness',
        );
        for (final directive in _directives(source)) {
          expect(
            directive,
            isNot(contains('compatibility_stage1')),
            reason: '${file.path} reaches the research harness',
          );
          expect(
            directive,
            isNot(contains('test/support')),
            reason: '${file.path} imports test fixtures',
          );
        }
      } else {
        expect(
          source.contains('compatibility_stage1'),
          isFalse,
          reason:
              '${file.path} wires research into native/source configuration',
        );
      }
    }
  });

  test('fixture support contains only synthetic data and research imports', () {
    final source = File(
      'test/support/compatibility_stage1_fixtures.dart',
    ).readAsStringSync();
    expect(source, contains('SYNTHETIC'));
    expect(_directives(source), [
      '../../tools/compatibility_stage1/models.dart',
    ]);
    expect(
      _accountIdentifier.hasMatch(source),
      isFalse,
      reason: 'Fixtures must contain no account-shaped identifiers',
    );
    expect(
      RegExp(
        r'\b(?:Supabase|SharedPreferences|HttpClient|File|Directory|'
        r'Process|Random|DateTime|Timer)\b',
      ).hasMatch(_withoutComments(source)),
      isFalse,
    );
  });

  test('all other Stage 1 test artifacts stay synthetic and local', () {
    final paths = <String>[
      for (final name in _researchTests) 'test/$name',
      'test/support/compatibility_stage1_fixtures.dart',
      'test/support/compatibility_stage1_oracle.dart',
      for (final name in _moduleNames) '$_moduleRoot/$name',
    ];
    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(
        _accountIdentifier.hasMatch(source),
        isFalse,
        reason: '$path contains an account-shaped identifier',
      );
      if (!path.startsWith('test/')) continue;
      for (final directive in _directives(source)) {
        final runner = directive == 'package:flutter_test/flutter_test.dart';
        final localModule =
            (directive.startsWith('../tools/compatibility_stage1/') ||
                directive.startsWith('../../tools/compatibility_stage1/')) &&
            _moduleNames.contains(directive.split('/').last);
        final testSupport =
            directive == 'support/compatibility_stage1_fixtures.dart' ||
            directive == 'support/compatibility_stage1_oracle.dart' ||
            directive == 'compatibility_stage1_fixtures.dart' ||
            directive == 'compatibility_stage1_oracle.dart';
        expect(
          runner || localModule || testSupport,
          isTrue,
          reason: '$path has a non-local research dependency $directive',
        );
      }
      expect(
        RegExp(
          r'\b(?:Supabase|Firebase|HttpClient|HttpServer|WebSocket|Socket|'
          r'SharedPreferences|Hive|Isar|File|Directory|Process|Platform|'
          r'Random|DateTime|Timer)\b',
        ).hasMatch(_withoutComments(source)),
        isFalse,
        reason: '$path contains app initialization or non-local fixture access',
      );
    }
  });
}
