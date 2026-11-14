import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> expectZyraQrPayload(WidgetTester tester, String payload) async {
  final qr = find.byKey(const ValueKey('zyra-qr'));
  expect(qr, findsOneWidget);
  final expected = QrPainter(
    data: payload,
    version: QrVersions.auto,
    gapless: true,
  );
  final paint = tester.widget<CustomPaint>(
    find.descendant(of: qr, matching: find.byType(CustomPaint)),
  );
  final matches = await tester.runAsync(() async {
    final rendered = await (paint.painter! as QrPainter).toImageData(196);
    final reference = await expected.toImageData(196);
    return rendered != null &&
        reference != null &&
        listEquals(
          rendered.buffer.asUint8List(
            rendered.offsetInBytes,
            rendered.lengthInBytes,
          ),
          reference.buffer.asUint8List(
            reference.offsetInBytes,
            reference.lengthInBytes,
          ),
        );
  });
  expect(matches, isTrue, reason: 'QR pixels match the expected payload.');
}
