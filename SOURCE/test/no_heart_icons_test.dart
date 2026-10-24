import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Flutter UI contains no heart icon symbols or glyphs', () {
    final heartIcon = RegExp(
      r'\b(?:Icons|CupertinoIcons|FontAwesomeIcons)\.'
      r'(?:favorite|heart|volunteer_activism|health_and_safety|'
      r'monitor_heart|cardiology|healing)[A-Za-z0-9_]*\b',
    );
    // Use Unicode-aware whole glyph alternatives: a character class can
    // match a surrogate shared with unrelated emoji such as traffic lights.
    final heartGlyph = RegExp(
      r'(?:♡|♥|❤|💗|💖|💘|💝|💞|💕|💓|💟|❣)',
      unicode: true,
    );
    final violations = <String>[];

    for (final entry in Directory('lib').listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      final lines = entry.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (heartIcon.hasMatch(line) || heartGlyph.hasMatch(line)) {
          violations.add('${entry.path}:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'The Founder does not want heart icons anywhere in the app. '
          'Keep action labels and behavior, but use a neutral symbol.\n'
          '${violations.join('\n')}',
    );
  });
}
