// LOCK 21 V2: the same Settings control serves ordinary and preview members.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_haptics_setting.dart';

const _row = ValueKey('haptics-row');
const _slider = ValueKey('zyra-haptic-strength-slider');

void main() {
  final calls = <Object?>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'a changed stop applies during drag and gives one haptic on release',
    (tester) async {
      final values = <ZyraHapticLevel>[];
      var level = ZyraHapticLevel.subtle;
      await tester.pumpWidget(
        _app(
          level: () => level,
          change: (value) {
            values.add(value);
            level = value;
            return true;
          },
        ),
      );
      await tester.tap(find.byKey(_row));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byKey(_slider));
      final down = Offset(box.left + box.width * .27, box.center.dy);
      final right = Offset(box.right - 24, box.center.dy);
      final pointer = await tester.startGesture(down);
      await pointer.moveTo(right);
      await tester.pump();
      expect(level, ZyraHapticLevel.strong);
      expect(
        values.toSet().length,
        values.length,
        reason: 'Each stop publishes once',
      );
      expect(calls, isEmpty);
      await pointer.up();
      await tester.pumpAndSettle();
      expect(calls, ['HapticFeedbackType.heavyImpact']);

      calls.clear();
      await tester.tapAt(Offset(box.left + 24, box.center.dy));
      await tester.pumpAndSettle();
      expect(level, ZyraHapticLevel.off);
      expect(calls, isEmpty);
    },
  );

  testWidgets('cancelled or retired slider actions do not give a haptic', (
    tester,
  ) async {
    var level = ZyraHapticLevel.subtle;
    var owner = 0;
    final values = <ZyraHapticLevel>[];
    Widget page() => _app(
      identity: owner,
      level: () => level,
      change: (value) {
        values.add(value);
        level = value;
        return true;
      },
    );
    await tester.pumpWidget(page());
    await tester.tap(find.byKey(_row));
    await tester.pumpAndSettle();
    final box = tester.getRect(find.byKey(_slider));
    final pointer = await tester.startGesture(box.center);
    await pointer.moveTo(Offset(box.right - 24, box.center.dy));
    await pointer.cancel();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    final retired = tester.widget<Slider>(find.byKey(_slider));
    final count = values.length;
    owner++;
    await tester.pumpWidget(page());
    owner--;
    await tester.pumpWidget(page());
    retired.onChangeStart?.call(4);
    retired.onChanged?.call(2);
    retired.onChangeEnd?.call(2);
    expect(values, hasLength(count));
    expect(calls, isEmpty);
  });

  testWidgets('a background and return cancels a held slider gesture', (
    tester,
  ) async {
    var level = ZyraHapticLevel.subtle;
    await tester.pumpWidget(
      _app(
        level: () => level,
        change: (value) {
          level = value;
          return true;
        },
      ),
    );
    await tester.tap(find.byKey(_row));
    await tester.pumpAndSettle();
    final box = tester.getRect(find.byKey(_slider));
    final pointer = await tester.startGesture(box.center);
    await pointer.moveTo(Offset(box.right - 24, box.center.dy));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await pointer.up();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });

  testWidgets('VoiceOver announces the level and adjusts one stop', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var level = ZyraHapticLevel.light;
    await tester.pumpWidget(
      _app(
        level: () => level,
        change: (value) {
          level = value;
          return true;
        },
      ),
    );
    await tester.tap(find.byKey(_row));
    await tester.pumpAndSettle();
    final slider = tester.getSemantics(
      find.bySemanticsLabel('Haptic strength'),
    );
    final data = slider.getSemanticsData();
    expect(data.label, 'Haptic strength');
    expect(data.value, 'Light');
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    slider.owner!.performAction(slider.id, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(level, ZyraHapticLevel.medium);
    expect(calls, ['HapticFeedbackType.mediumImpact']);
    handle.dispose();
  });
}

Widget _app({
  required ZyraHapticLevel Function() level,
  required bool Function(ZyraHapticLevel) change,
  int identity = 0,
}) => MaterialApp(
  home: Scaffold(
    body: StatefulBuilder(
      builder: (context, setState) => ListView(
        children: [
          ZyraHapticsSetting(
            level: level(),
            ownerIdentity: identity,
            canAct: () => true,
            onChanged: (value) {
              final accepted = change(value);
              if (accepted) setState(() {});
              return accepted;
            },
            row: (expanded, toggle) => ListTile(
              key: _row,
              title: const Text('Haptics'),
              subtitle: Text(level().label),
              onTap: toggle,
            ),
          ),
        ],
      ),
    ),
  ),
);
