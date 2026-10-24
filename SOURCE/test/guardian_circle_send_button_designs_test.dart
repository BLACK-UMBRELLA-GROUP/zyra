import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_circle_send_button_presentation.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _button = ValueKey('circle_send_button');
const _action = ValueKey('circle_send_action');

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets(
    'fixed gold circle keeps the selected outline and send callback',
    (tester) async {
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraCircleSendButton(busy: false, onSend: () => sends++),
          ),
        ),
      );
      final action = find.byKey(_action);
      final material = tester.widget<Material>(
        find.ancestor(of: action, matching: find.byType(Material)).first,
      );
      final ink = tester.widget<Ink>(
        find.ancestor(of: action, matching: find.byType(Ink)).first,
      );
      final decoration = ink.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(material.color, Colors.transparent);
      expect(decoration.borderRadius, BorderRadius.circular(999));
      expect(border.top.width, 1);
      expect(border.top.color, ZyraColors.journeyGold.withValues(alpha: .8));
      expect(decoration.boxShadow, isNull);
      expect(tester.getSize(find.byKey(_button)), const Size(52, 52));
      expect(tester.getSize(action), const Size(50, 50));
      final arrow = tester.widget<Icon>(
        find.byIcon(Icons.arrow_upward_rounded),
      );
      expect(arrow.size, 23);
      expect(arrow.color, ZyraColors.journeyGold);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Send'), findsNothing);
      await tester.tap(action);
      expect(sends, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('fixed send semantic action invokes the same caller once', (
    tester,
  ) async {
    var sends = 0;
    void send() => sends++;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ZyraCircleSendButton(busy: false, onSend: send)),
      ),
    );
    final semantics = tester.widget<Semantics>(find.byKey(_button));
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.enabled, isTrue);
    expect(semantics.properties.label, 'Send message');
    expect(semantics.properties.onTap, same(send));
    semantics.properties.onTap!();
    expect(sends, 1);
  });

  for (final busy in [false, true]) {
    testWidgets('fixed send refuses disabled input busy=$busy', (tester) async {
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraCircleSendButton(
              busy: busy,
              onSend: busy ? () => sends++ : null,
            ),
          ),
        ),
      );
      final action = find.byKey(_action);
      final button = tester.widget<InkWell>(action);
      final semantics = tester.widget<Semantics>(find.byKey(_button));
      expect(button.onTap, isNull);
      expect(semantics.properties.enabled, isFalse);
      expect(semantics.properties.onTap, isNull);
      expect(
        semantics.properties.label,
        busy ? 'Sending message' : 'Send message',
      );
      expect(
        find.byType(CircularProgressIndicator),
        busy ? findsOneWidget : findsNothing,
      );
      final ink = tester.widget<Ink>(
        find.ancestor(of: action, matching: find.byType(Ink)).first,
      );
      final decoration = ink.decoration! as BoxDecoration;
      expect(
        (decoration.border! as Border).top.color,
        ZyraColors.journeyGold.withValues(alpha: .35),
      );
      expect(tester.getSize(find.byKey(_button)), const Size(52, 52));
      expect(tester.getSize(action), const Size(50, 50));
      expect(sends, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
