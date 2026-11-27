import 'package:flutter_test/flutter_test.dart';

import 'line145_capture_output.dart';

void main() {
  test(
    'line 145 capture output rejects paths outside ignored build evidence',
    () {
      expect(checkedLine145CaptureOutput(''), isNull);
      expect(
        checkedLine145CaptureOutput('build/line145/g11_g12'),
        'build/line145/g11_g12',
      );
      for (final unsafe in [
        'build/line145/../../../PRODUCT/APPROVED/GUARDIAN_CARD/BUILT/V3',
        'build/line145/./g11_g12',
        'build/line145//g11_g12',
        '/tmp/line145/g11_g12',
        'PRODUCT/APPROVED/GUARDIAN_CARD/BUILT/V3',
      ]) {
        expect(() => checkedLine145CaptureOutput(unsafe), throwsArgumentError);
      }
    },
  );
}
