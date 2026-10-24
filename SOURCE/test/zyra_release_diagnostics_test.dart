import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_release_diagnostics.dart';

void main() {
  test('release console never forwards raw private diagnostics', () {
    final previous = debugPrint;
    addTearDown(() => debugPrint = previous);
    final messages = <String?>[];
    debugPrint = (String? message, {int? wrapWidth}) => messages.add(message);
    installZyraReleaseDiagnostics(release: true);
    debugPrint('sample-private-auth-payload');
    expect(messages, isEmpty);
  });

  test('local diagnostics remain available', () {
    final previous = debugPrint;
    addTearDown(() => debugPrint = previous);
    final messages = <String?>[];
    debugPrint = (String? message, {int? wrapWidth}) => messages.add(message);
    installZyraReleaseDiagnostics(release: false);
    debugPrint('local diagnostic');
    expect(messages, ['local diagnostic']);
  });

  test(
    'release policy installs before initialization and preserves counters',
    () {
      final source = File('lib/main.dart').readAsStringSync();
      expect(
        source.indexOf('installZyraReleaseDiagnostics();'),
        lessThan(source.indexOf('WidgetsFlutterBinding.ensureInitialized();')),
      );
      expect(source, contains('if (kReleaseMode) return true;'));
      expect(
        source,
        contains('if (!kReleaseMode) {\n      (previousFlutterHandler'),
      );
      expect(source, contains('ZyraReliabilityFingerprint.unhandledPlatform'));
    },
  );
}
