// Thin project-local entry to the installed, hash-pinned Flutter backend.
// The SDK itself is not patched. Only its shell Flutter subprocess is
// redirected to the same cached native Dart + tool snapshot final entry.
import 'dart:io';
import 'file:///opt/homebrew/share/flutter/packages/flutter_tools/bin/xcode_backend.dart'
    as upstream;

const _sdk = '/opt/homebrew/share/flutter';
const _dart = '$_sdk/bin/cache/dart-sdk/bin/dart';
const _snapshot = '$_sdk/bin/cache/flutter_tools.snapshot';
const _packages = '$_sdk/packages/flutter_tools/.dart_tool/package_config.json';

class ZyraBackendContext extends upstream.Context {
  ZyraBackendContext({
    required super.arguments,
    required super.environment,
    super.scriptOutputStreamFile,
  });

  @override
  ProcessResult runSyncProcess(
    String bin,
    List<String> args, {
    String? workingDirectory,
  }) {
    if (environment['ZYRA_NO_GIT_ACTIVE'] != 'pinned-v1') {
      throw StateError('Use the project-local no-Git driver.');
    }
    if (environment['FLUTTER_ROOT'] != _sdk) {
      throw StateError('Unexpected Flutter SDK; stop and revalidate pins.');
    }
    final name = bin.split('/').last.toLowerCase();
    if (name == 'git' || name.startsWith('git-')) {
      throw StateError('Git execution is prohibited.');
    }
    if (bin == '$_sdk/bin/flutter') {
      return Process.runSync(_dart, [
        '--packages=$_packages',
        _snapshot,
        '--no-version-check',
        '--suppress-analytics',
        ...args,
      ], workingDirectory: workingDirectory);
    }
    return super.runSyncProcess(bin, args, workingDirectory: workingDirectory);
  }
}

void main(List<String> args) {
  if (Platform.environment['ZYRA_NO_GIT_ACTIVE'] != 'pinned-v1' ||
      Platform.environment['FLUTTER_ROOT'] != _sdk) {
    stderr.writeln('Native build requires the checked no-Git driver.');
    exitCode = 64;
    return;
  }
  final output = Platform.environment['SCRIPT_OUTPUT_STREAM_FILE'];
  stdout.writeln('ZYRA no-Git native phase: ${args.join(' ')}');
  ZyraBackendContext(
    arguments: [...args, 'ios'],
    environment: Platform.environment,
    scriptOutputStreamFile: output == null || output.isEmpty
        ? null
        : File(output),
  ).run();
}
