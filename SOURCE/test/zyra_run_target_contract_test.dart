import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _deviceId = '00008130-001A2C1E26F8001C';
const _founderAccessDefine = 'ZYRA_INTERNAL_FOUNDER_ACCESS=true';
const _founderUuidDefine =
    'ZYRA_INTERNAL_FOUNDER_UUID=dfcbd00d-bc22-4d6e-999b-3a9264cf3510';

Future<({ProcessResult result, List<String> flutterArgs})> _invoke(
  List<String> arguments,
) async {
  final sandbox = Directory.systemTemp.createTempSync('zyra-run-target-');
  addTearDown(() => sandbox.deleteSync(recursive: true));
  final captured = File('${sandbox.path}/flutter.args');
  final fakeFlutter = File('${sandbox.path}/flutter')
    ..writeAsStringSync('''#!/bin/sh
printf '%s\\n' "\$@" > "\$ZYRA_FAKE_FLUTTER_ARGS"
''');
  final chmod = Process.runSync('chmod', ['700', fakeFlutter.path]);
  expect(chmod.exitCode, 0);

  final environment = Map<String, String>.from(Platform.environment)
    ..['PATH'] = '${sandbox.path}:${Platform.environment['PATH'] ?? ''}'
    ..['ZYRA_FAKE_FLUTTER_ARGS'] = captured.path;
  final result = await Process.run(
    '/bin/bash',
    ['run.sh', ...arguments],
    workingDirectory: Directory.current.path,
    environment: environment,
  );
  return (
    result: result,
    flutterArgs: captured.existsSync()
        ? captured.readAsLinesSync()
        : const <String>[],
  );
}

void main() {
  test('the one normal run command targets main ZYRA with local previews', () {
    final script = File('run.sh').readAsStringSync();
    expect(script, contains('_run_internal_founder --profile'));
    expect(script, contains('--flavor production'));
    expect(script, contains('--dart-define=$_founderAccessDefine'));
    expect(script, contains('--dart-define=$_founderUuidDefine'));
    expect(script, isNot(contains('--flavor foundertest')));
    expect(script, isNot(contains('--dart-define-from-file=')));
    expect(script, isNot(contains('validate_founder_test_config.dart')));
  });

  test('public release is explicit and has no Founder opt-in', () {
    final script = File('run.sh').readAsStringSync();
    final release = script.substring(
      script.indexOf('  release)'),
      script.indexOf('  profile)'),
    );
    expect(
      release,
      contains(r'flutter run --release --flavor production -d "$DEVICE"'),
    );
    expect(release, isNot(contains('ZYRA_INTERNAL_FOUNDER_ACCESS')));
    expect(release, isNot(contains('ZYRA_INTERNAL_FOUNDER_UUID')));
    expect(release, isNot(contains('dart-define-from-file')));
  });

  test(
    'mocked default and dev launches use only the main internal target',
    () async {
      for (final arguments in const <List<String>>[
        <String>[],
        <String>['dev'],
        <String>['debug'],
        <String>['profile'],
      ]) {
        final invocation = await _invoke(arguments);
        expect(invocation.result.exitCode, 0, reason: '$arguments');
        expect(
          invocation.flutterArgs,
          containsAllInOrder(const [
            'run',
            '--flavor',
            'production',
            '--dart-define=$_founderAccessDefine',
            '--dart-define=$_founderUuidDefine',
          ]),
          reason: '$arguments',
        );
        expect(invocation.flutterArgs, isNot(contains('foundertest')));
        expect(
          invocation.flutterArgs,
          isNot(contains('--dart-define-from-file')),
        );
        expect(invocation.flutterArgs, contains(_deviceId));
        expect(
          invocation.flutterArgs.contains('--profile'),
          arguments.isEmpty || arguments.single == 'profile',
          reason: '$arguments',
        );
      }
    },
  );

  test(
    'mocked public release never receives internal Founder defines',
    () async {
      final invocation = await _invoke(const ['release']);
      expect(invocation.result.exitCode, 0);
      expect(invocation.flutterArgs, const [
        'run',
        '--release',
        '--flavor',
        'production',
        '-d',
        _deviceId,
      ]);
    },
  );

  test('retired and unknown modes fail before Flutter', () async {
    for (final mode in const [
      'check-founder-test-config',
      'test',
      'foundertest',
      'founder-test',
      'future-mode',
    ]) {
      final invocation = await _invoke([mode]);
      expect(invocation.result.exitCode, 64, reason: mode);
      expect(invocation.flutterArgs, isEmpty, reason: mode);
      expect(
        invocation.result.stdout,
        contains('Nothing was run.'),
        reason: mode,
      );
    }
  });
}
