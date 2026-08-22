import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/main.dart';

void main() {
  testWidgets(
    'OA-ZYRA-212 keeps Scaffolds transparent over the live app layer',
    (tester) async {
      await tester.pumpWidget(const ZyraApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.scaffoldBackgroundColor, Colors.transparent);

      final liveLayers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        liveLayers.any(
          (layer) =>
              layer.duration == const Duration(milliseconds: 260) &&
              layer.decoration is BoxDecoration &&
              (layer.decoration! as BoxDecoration).gradient != null,
        ),
        isTrue,
      );
    },
  );

  test('OA-ZYRA-220 keeps compatibility on every decided Activity card', () {
    final source = File(
      'lib/screens/connections/connections_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('Cannot be used on passed profiles')));
    expect(
      source,
      isNot(contains('Passed cards expand too, but get no Unlock')),
    );

    final actionStart = source.indexOf(
      '// SHOWN ON EVERY CARD, INCLUDING PASSED',
    );
    final actionEnd = source.indexOf('child: _FlagAction', actionStart);
    expect(actionStart, greaterThanOrEqualTo(0));
    expect(actionEnd, greaterThan(actionStart));

    final compatibilityAction = source.substring(actionStart, actionEnd);
    expect(compatibilityAction, contains("? 'View Compatibility'"));
    expect(compatibilityAction, contains(": 'Compatibility Unlock'"));
    expect(
      compatibilityAction,
      isNot(contains('widget.kind != _ActivityKind.passed')),
    );

    final moveRowStart = source.indexOf('Widget _moveRow()');
    final moveRowEnd = source.indexOf('return row;', moveRowStart);
    final moveRow = source.substring(moveRowStart, moveRowEnd);
    expect(moveRow, contains('widget.kind != _ActivityKind.passed'));
    expect(moveRow, contains('widget.kind != _ActivityKind.saved'));
    expect(moveRow, contains('widget.kind != _ActivityKind.considered'));
  });
}
