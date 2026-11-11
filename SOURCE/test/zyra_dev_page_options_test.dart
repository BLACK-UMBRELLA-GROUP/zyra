// LOCK 21 V2: exercise the Settings slider that replaces the member picker.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_haptics_setting.dart';

import 'support/zyra_settings_haptics_test_driver.dart';

final _row = find.byKey(const ValueKey('test-haptics-row'));
final _slider = find.byType(Slider);

class _Host extends StatefulWidget {
  const _Host({super.key});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  var level = ZyraHapticLevel.subtle;
  var allowed = true;
  var reject = false;
  var visible = true;
  var epoch = 0;
  var identity = 0;
  final changes = <ZyraHapticLevel>[];

  void supply(ZyraHapticLevel value) => setState(() => level = value);
  void hide() => setState(() => visible = false);
  void replaceOwner({bool replacePage = false}) => setState(() {
    epoch++;
    if (replacePage) identity++;
  });

  @override
  Widget build(BuildContext context) {
    final revision = epoch;
    if (!visible) return const SizedBox.shrink();
    return ZyraHapticsSetting(
      key: ValueKey(identity),
      level: level,
      canAct: () => allowed && revision == epoch,
      onChanged: (value) {
        if (reject || !allowed || revision != epoch) return false;
        changes.add(value);
        supply(value);
        return true;
      },
      row: (expanded, open) => TextButton(
        key: const ValueKey('test-haptics-row'),
        onPressed: open,
        child: Text('Haptics, ${level.label}'),
      ),
    );
  }
}

Future<_HostState> _mount(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey<_HostState>();
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(body: _Host(key: key)),
  ));
  await tester.pumpAndSettle();
  return key.currentState!;
}

void _expectNoDeveloperMenus() {
  expect(find.byType(DropdownButton<String>), findsNothing);
  expect(find.byKey(const ValueKey('dev_control_rail')), findsNothing);
  expect(find.text('Gold accents'), findsNothing);
  expect(find.text('Appearance & haptics'), findsNothing);
}

void main() {
  testWidgets('retained member choices use shared app surfaces without developer menus', (
    tester,
  ) async {
    await _mount(tester);
    expect(_slider, findsNothing);
    await openSettingsHapticsForTest(tester);
    expect(_slider, findsOneWidget);
    expect(tester.widget<Slider>(_slider).divisions, 4);
    for (final level in ZyraHapticLevel.values) {
      expect(find.text(level.label), findsOneWidget);
    }
    _expectNoDeveloperMenus();
  });

  testWidgets('member current choices follow external owner presentation changes', (
    tester,
  ) async {
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    state.supply(ZyraHapticLevel.medium);
    await tester.pump();
    expect(tester.widget<Slider>(_slider).value, 3);
    expect(find.text('Haptics, Medium'), findsOneWidget);
    final label = tester.widget<Text>(find.text('Medium'));
    expect(label.style!.color, ZyraColors.goldText);
    expect(label.style!.fontWeight, FontWeight.w500);
  });

  testWidgets('losing and restoring owner admission cannot revive a member intent', (
    tester,
  ) async {
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    final old = retainSettingsHapticAction(tester);
    state.allowed = false;
    state.replaceOwner();
    old(true);
    expect(state.changes, isEmpty);
    state.allowed = true;
    await tester.pump();
    old(true);
    expect(state.changes, isEmpty);
    retainSettingsHapticAction(tester)(true);
    expect(state.changes, [ZyraHapticLevel.strong]);
  });

  testWidgets('unavailable member settings refuse to open the slider', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.allowed = false;
    await tester.tap(_row);
    await tester.pump();
    expect(_slider, findsNothing);
    expect(state.changes, isEmpty);
    _expectNoDeveloperMenus();
  });

  testWidgets('each member Haptics stop dispatches its own value', (tester) async {
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    for (final level in ZyraHapticLevel.values) {
      final control = tester.widget<Slider>(_slider);
      final value = level.index.toDouble();
      control.onChangeStart!(control.value);
      control.onChanged!(value);
      control.onChangeEnd!(value);
      await tester.pump();
      expect(state.level, level);
      expect(state.changes.last, level);
    }
    expect(state.changes, ZyraHapticLevel.values);
  });

  testWidgets('member callback replacement invalidates captured previous intent', (
    tester,
  ) async {
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    final old = retainSettingsHapticAction(tester);
    state.replaceOwner();
    await tester.pump();
    old(true);
    expect(state.changes, isEmpty);
    retainSettingsHapticAction(tester)(false);
    expect(state.changes, [ZyraHapticLevel.light]);
  });

  testWidgets('ordinary accounts retain member choices without developer dropdowns', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    retainSettingsHapticAction(tester)(true);
    expect(state.changes, [ZyraHapticLevel.strong]);
    _expectNoDeveloperMenus();
  });

  testWidgets('owner admission loss refuses an already-open member selection', (
    tester,
  ) async {
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    final old = retainSettingsHapticAction(tester);
    state.allowed = false;
    old(true);
    await tester.pump();
    expect(state.changes, isEmpty);
    expect(tester.widget<Slider>(_slider).value, 1);
  });

  testWidgets('member page replacement refuses retained choices despite reused labels', (
    tester,
  ) async {
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    final old = retainSettingsHapticAction(tester);
    state.replaceOwner(replacePage: true);
    await tester.pump();
    await openSettingsHapticsForTest(tester);
    old(true);
    expect(state.changes, isEmpty);
    retainSettingsHapticAction(tester)(true);
    expect(state.changes, [ZyraHapticLevel.strong]);
  });

  testWidgets('removing member settings while the slider is open leaves callbacks inert', (
    tester,
  ) async {
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    final old = retainSettingsHapticAction(tester);
    state.hide();
    await tester.pump();
    old(true);
    expect(state.changes, isEmpty);
    expect(_slider, findsNothing);
  });

  testWidgets('a refused Settings callback does not claim a new selection', (
    tester,
  ) async {
    final state = await _mount(tester);
    await openSettingsHapticsForTest(tester);
    state.reject = true;
    retainSettingsHapticAction(tester)(true);
    await tester.pump();
    expect(state.changes, isEmpty);
    expect(tester.widget<Slider>(_slider).value, 1);
  });

  testWidgets('all Haptics stops fit narrow large text', (tester) async {
    await _mount(tester, size: const Size(320, 568), scale: 2);
    await openSettingsHapticsForTest(tester);
    for (final level in ZyraHapticLevel.values) {
      final bounds = tester.getRect(find.text(level.label));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(320));
    }
    expect(tester.takeException(), isNull);
  });
}
