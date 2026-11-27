import 'dart:io';

/// Only ignored, local line 145 evidence may be produced by opt-in captures.
String? checkedLine145CaptureOutput(String raw) {
  if (raw.isEmpty) return null;
  final parts = raw.split('/');
  if (parts.length < 3 ||
      parts[0] != 'build' ||
      parts[1] != 'line145' ||
      parts.any((part) => part.isEmpty || part == '.' || part == '..') ||
      raw.contains('\\')) {
    throw ArgumentError.value(
      raw,
      'capture directory',
      'Use build/line145/<name>.',
    );
  }

  var segment = '';
  for (final part in parts) {
    segment = segment.isEmpty ? part : '$segment/$part';
    if (FileSystemEntity.typeSync(segment, followLinks: false) ==
        FileSystemEntityType.link) {
      throw ArgumentError.value(
        raw,
        'capture directory',
        'Symlinks are refused.',
      );
    }
  }
  return raw;
}
