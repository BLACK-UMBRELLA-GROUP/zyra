import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_haptics_setting.dart';

/// Mounts the shared Settings row with an injected caller ownership check.
Widget settingsHapticsTestPage({
  Key? key,
  required bool Function() canAct,
  required ValueChanged<ZyraHapticLevel> onChanged,
  ZyraHapticLevel level = ZyraHapticLevel.subtle,
}) => Scaffold(
  body: ZyraHapticsSetting(
    key: key,
    level: level,
    canAct: canAct,
    onChanged: (value) {
      onChanged(value);
      return true;
    },
    row: (_, open) => TextButton(
      key: const ValueKey('test-haptics-row'),
      onPressed: open,
      child: const Text('Haptics'),
    ),
  ),
);

Future<void> openSettingsHapticsForTest(WidgetTester tester) async {
  if (find.byType(Slider).evaluate().isNotEmpty) return;
  final row = find.byKey(const ValueKey('test-haptics-row'));
  await tester.tap(row);
  await tester.pumpAndSettle();
}

ValueChanged<bool> retainSettingsHapticAction(
  WidgetTester tester, {
  Finder? slider,
}) {
  final control = tester.widget<Slider>(slider ?? find.byType(Slider));
  return (strong) {
    final next = strong ? ZyraHapticLevel.strong : ZyraHapticLevel.light;
    final value = next.index.toDouble();
    control.onChangeStart?.call(control.value);
    control.onChanged?.call(value);
    control.onChangeEnd?.call(value);
  };
}
