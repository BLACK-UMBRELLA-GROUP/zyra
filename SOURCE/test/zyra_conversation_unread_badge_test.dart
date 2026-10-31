import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_conversation_unread_badge.dart';

const _buttonKey = ValueKey('conversation-button');

Future<void> _mount(
  WidgetTester tester,
  int unreadCount, {
  Color pageColor = const Color(0xFFF7F3EC),
  Color? backgroundColor,
  VoidCallback? onPressed,
}) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: pageColor),
    home: Scaffold(
      body: Center(
        child: ZyraConversationUnreadBadge(
          unreadCount: unreadCount,
          backgroundColor: backgroundColor,
          child: SizedBox(
            key: _buttonKey,
            width: 40,
            height: 40,
            child: IconButton(
              tooltip: 'Guardian Circle',
              onPressed: onPressed ?? () {},
              icon: const Icon(Icons.forum_outlined),
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder _bubble() => find.descendant(
  of: find.byType(ZyraConversationUnreadBadge),
  matching: find.byType(DecoratedBox),
);

void main() {
  testWidgets('zero and negative counts have no bubble', (tester) async {
    for (final count in [0, -1]) {
      await _mount(tester, count);
      expect(_bubble(), findsNothing);
      expect(find.byTooltip('Guardian Circle'), findsOneWidget);
      expect(tester.getSize(find.byKey(_buttonKey)), const Size(40, 40));
    }
  });

  testWidgets('counts one through nine show their actual number', (
    tester,
  ) async {
    for (var count = 1; count <= 9; count++) {
      await _mount(tester, count);
      expect(find.text('$count'), findsOneWidget);
      expect(find.text('9+'), findsNothing);
    }
  });

  testWidgets('ten and larger counts show 9+ with the actual semantic count', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final count in [10, 42, 1000]) {
        await _mount(tester, count);
        expect(find.text('9+'), findsOneWidget);
        expect(find.bySemanticsLabel('$count unread messages'), findsOneWidget);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('bubble uses locked size, type, colours, radius and page ring', (
    tester,
  ) async {
    const pageColor = Color(0xFF123456);
    await _mount(tester, 2, pageColor: pageColor);
    final size = tester.getSize(_bubble());
    expect(size.height, 16);
    expect(size.width, greaterThanOrEqualTo(16));
    final decoration =
        tester.widget<DecoratedBox>(_bubble()).decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFC08A3A));
    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, [
      BoxShadow(color: pageColor, spreadRadius: 2),
    ]);
    final text = tester.widget<Text>(find.text('2'));
    expect(text.style!.fontSize, 10);
    expect(text.style!.fontWeight, FontWeight.w600);
    expect(text.style!.color, const Color(0xFF2B2420));
    final padding = tester.widget<Padding>(
      find.ancestor(of: find.text('2'), matching: find.byType(Padding)).first,
    );
    expect(padding.padding, const EdgeInsets.symmetric(horizontal: 4));
  });

  testWidgets('wide count keeps 16 height and minimum 16 width', (
    tester,
  ) async {
    await _mount(tester, 10);
    final size = tester.getSize(_bubble());
    expect(size.height, 16);
    expect(size.width, greaterThanOrEqualTo(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bubble is offset minus three from the button top and right', (
    tester,
  ) async {
    const ringColor = Color(0xFFABCDEF);
    await _mount(tester, 1, backgroundColor: ringColor);
    final button = tester.getRect(find.byKey(_buttonKey));
    final bubble = tester.getRect(_bubble());
    expect(bubble.top, button.top - 3);
    expect(bubble.right, button.right + 3);
    final stack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byType(ZyraConversationUnreadBadge),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(stack.clipBehavior, Clip.none);
    final decoration =
        tester.widget<DecoratedBox>(_bubble()).decoration as BoxDecoration;
    expect(decoration.boxShadow, [
      BoxShadow(color: ringColor, spreadRadius: 2),
    ]);
  });

  testWidgets(
    'badge preserves the conversation tap and clears with its count',
    (tester) async {
      var opened = 0;
      await _mount(tester, 2, onPressed: () => opened++);
      await tester.tap(find.byTooltip('Guardian Circle'));
      expect(opened, 1);
      await _mount(tester, 0, onPressed: () => opened++);
      expect(_bubble(), findsNothing);
      await tester.tap(find.byTooltip('Guardian Circle'));
      expect(opened, 2);
    },
  );
}
