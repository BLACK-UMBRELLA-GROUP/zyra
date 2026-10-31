import 'dart:io';

/// Rebuilds the adaptive foreground from the canonical LOCK14V4 artwork.
///
/// The Swift exporter draws the approved stencil, line and glow directly on a
/// transparent canvas. Recovering alpha from a flattened ivory icon would
/// distort the gold edge colours. All primary icon and launch assets share the
/// same exporter so their lettering and colours cannot drift.
void main() {
  if (!Platform.isMacOS) {
    stderr.writeln(
      'Primary artwork export requires macOS: '
      'xcrun swift tool/generate_dev_app_icons.swift',
    );
    exitCode = 1;
    return;
  }
  final result = Process.runSync('xcrun', [
    'swift',
    'tool/generate_dev_app_icons.swift',
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exitCode = result.exitCode;
}
