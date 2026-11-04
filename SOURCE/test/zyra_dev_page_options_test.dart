// Retained member choice/ownership contracts after developer menu retirement.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart' show ZyraApp, zyraNavigatorKey;
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';

const _gold = ValueKey('personalisation_gold_toggle');
const _haptic = ValueKey('personalisation_haptic');

void _expectNoDeveloperMenu() {
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value.startsWith(
                'dev_page_options_',
              ) ||
              (widget.key! as ValueKey<String>).value.startsWith(
                'dev_controls_',
              )),
    ),
    findsNothing,
  );
}

Future<void> _mountFrame(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final rebuild = const ZyraApp().build(context) as ListenableBuilder;
        final app = rebuild.builder(context, null) as MaterialApp;
        return MaterialApp(
          navigatorKey: app.navigatorKey,
          navigatorObservers:
              app.navigatorObservers ?? const <NavigatorObserver>[],
          theme: app.theme,
          builder: (context, content) => app.builder!(
            context,
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: content!,
            ),
          ),
          home: Scaffold(body: child),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

class _MemberChoices extends StatefulWidget {
  const _MemberChoices({super.key});
  @override
  State<_MemberChoices> createState() => _MemberChoicesState();
}

class _MemberChoicesState extends State<_MemberChoices> {
  bool allowed = true, gold = false, alternate = false, visible = true;
  String page = 'first';
  ZyraHapticLevel haptic = ZyraHapticLevel.subtle;
  int hapticCalls = 0, goldCalls = 0, alternateCalls = 0;
  bool canAct() => allowed;
  void chooseHaptic(ZyraHapticLevel value) => setState(() {
    haptic = value;
    hapticCalls++;
  });
  void alternateHaptic(ZyraHapticLevel value) =>
      setState(() => alternateCalls++);
  void chooseGold(bool value) => setState(() {
    gold = value;
    goldCalls++;
  });
  void alternateGold(bool value) => setState(() => alternateCalls++);
  void change(VoidCallback mutation) => setState(mutation);
  @override
  Widget build(BuildContext context) => visible
      ? PersonalisationScreen.preview(
          key: ValueKey('member-settings-$page'),
          canAct: canAct,
          palette: ZyraDevPalette.ivory,
          hapticLevel: haptic,
          goldEnabled: gold,
          onHapticChanged: alternate ? alternateHaptic : chooseHaptic,
          onGoldChanged: alternate ? alternateGold : chooseGold,
        )
      : const Text('Member settings unavailable');
}

Future<_MemberChoicesState> _mount(WidgetTester tester) async {
  final key = GlobalKey<_MemberChoicesState>();
  await _mountFrame(tester, _MemberChoices(key: key));
  await _reveal(tester, find.byKey(_gold));
  return key.currentState!;
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('personalisation-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  final row = find.byKey(_haptic);
  await _reveal(tester, row);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

ZyraPersonalisationChoiceSheet<ZyraHapticLevel> _sheet(WidgetTester tester) =>
    tester.widget<ZyraPersonalisationChoiceSheet<ZyraHapticLevel>>(
      find.byType(ZyraPersonalisationChoiceSheet<ZyraHapticLevel>),
    );

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAppGoldStyle.instance.restore(false);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'retained member choices use shared app surfaces without developer menus',
    (tester) async {
      await _mount(tester);
      await _open(tester);
      expect(
        tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
        ZyraColors.sheetSurface,
      );
      final selected = find.byKey(
        ValueKey('personalisation_choice_${ZyraHapticLevel.subtle}'),
      );
      final surface = find
          .ancestor(of: selected, matching: find.byType(Material))
          .first;
      expect(tester.widget<Material>(surface).color, ZyraColors.accentBg);
      _expectNoDeveloperMenu();
    },
  );

  testWidgets(
    'member current choices follow external owner presentation changes',
    (tester) async {
      final state = await _mount(tester);
      await _open(tester);
      _sheet(tester).onSelected(ZyraHapticLevel.strong);
      await tester.pumpAndSettle();
      expect(state.haptic, ZyraHapticLevel.strong);
      state.change(() => state.haptic = ZyraHapticLevel.light);
      await tester.pump();
      await _open(tester);
      expect(_sheet(tester).selected, ZyraHapticLevel.light);
      expect(state.hapticCalls, 1);
    },
  );

  testWidgets('route ABA cannot revive a retained member choice intent', (
    tester,
  ) async {
    final state = await _mount(tester);
    final stale = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
    zyraNavigatorKey.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Member cover')),
      ),
    );
    await tester.pumpAndSettle();
    zyraNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    stale(true);
    await tester.pump();
    expect(state.goldCalls, 0);
    expect(state.gold, isFalse);
    _expectNoDeveloperMenu();
  });

  testWidgets(
    'losing and restoring owner admission cannot revive a member intent',
    (tester) async {
      final state = await _mount(tester);
      final stale = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
      state.change(() => state.allowed = false);
      await tester.pump();
      state.change(() => state.allowed = true);
      await tester.pump();
      stale(true);
      await tester.pump();
      expect(state.goldCalls, 0);
      expect(
        find.byKey(const ValueKey('personalisation-unavailable')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'member unavailable states explain denial without a developer catalog',
    (tester) async {
      await _mountFrame(
        tester,
        const ZyraEmptyState(
          icon: Icons.lock_outline,
          title: 'Journey details',
          message: 'Main Guardian only',
        ),
      );
      expect(find.text('Main Guardian only'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      _expectNoDeveloperMenu();
    },
  );

  testWidgets('member haptic and Gold choices dispatch only their own values', (
    tester,
  ) async {
    final state = await _mount(tester);
    await _open(tester);
    _sheet(tester).onSelected(ZyraHapticLevel.strong);
    await tester.pumpAndSettle();
    expect([state.hapticCalls, state.goldCalls], [1, 0]);
    final toggle = find.byKey(_gold);
    await _reveal(tester, toggle);
    tester.widget<Switch>(toggle).onChanged!(true);
    await tester.pump();
    expect([state.hapticCalls, state.goldCalls], [1, 1]);
    expect(state.haptic, ZyraHapticLevel.strong);
    expect(state.gold, isTrue);
    expect(ZyraAppGoldStyle.instance.enabled, isFalse);
  });

  testWidgets(
    'unavailable member actions retain truthful reasons and refuse dispatch',
    (tester) async {
      var calls = 0;
      await _mountFrame(
        tester,
        ZyraEmptyState(
          icon: Icons.lock_outline,
          title: 'Journey details',
          message: 'Main Guardian only',
          ctaLabel: 'Continue',
          onCta: () => calls++,
          canAct: () => false,
        ),
      );
      expect(find.text('Main Guardian only'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(calls, 0);
      _expectNoDeveloperMenu();
    },
  );

  testWidgets(
    'interleaved member choice labels remain bound to their own values',
    (tester) async {
      final selections = <String>[];
      await _mountFrame(
        tester,
        ZyraPersonalisationChoiceSheet<String>(
          title: 'Member choices',
          options: const ['scene-one', 'design', 'scene-reset'],
          selected: 'scene-one',
          labelFor: (value) =>
              value == 'design' ? 'Appearance choice' : 'Shared label',
          onSelected: selections.add,
        ),
      );
      expect(find.text('Shared label'), findsNWidgets(2));
      await tester.tap(
        find.byKey(const ValueKey('personalisation_choice_design')),
      );
      await tester.pump();
      expect(selections, ['design']);
      expect(
        find.byKey(const ValueKey('personalisation_choice_scene-one')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('personalisation_choice_scene-reset')),
        findsOneWidget,
      );
    },
  );

  testWidgets('member preferences show their supplied states simultaneously', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.change(() {
      state.haptic = ZyraHapticLevel.strong;
      state.gold = true;
    });
    await tester.pump();
    expect(tester.widget<Switch>(find.byKey(_gold)).value, isTrue);
    await _reveal(tester, find.byKey(_haptic));
    expect(find.text('Strong'), findsOneWidget);
    expect(find.text('Poppins'), findsOneWidget);
    expect([state.hapticCalls, state.goldCalls], [0, 0]);
    _expectNoDeveloperMenu();
  });

  testWidgets(
    'member callback replacement invalidates captured previous intent',
    (tester) async {
      final state = await _mount(tester);
      final stale = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
      state.change(() => state.alternate = true);
      await tester.pump();
      stale(true);
      expect([state.goldCalls, state.alternateCalls], [0, 0]);
      tester.widget<Switch>(find.byKey(_gold)).onChanged!(true);
      await tester.pump();
      expect([state.goldCalls, state.alternateCalls], [0, 1]);
    },
  );

  testWidgets(
    'member empty and disabled presentations never gain developer actions',
    (tester) async {
      await _mountFrame(
        tester,
        const ZyraEmptyState(
          icon: Icons.inbox_outlined,
          message: 'No items available',
        ),
      );
      expect(find.text('No items available'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      await _mountFrame(
        tester,
        const ZyraPersonalisationContent(
          snapshot: ZyraPersonalisationSnapshot(
            palette: ZyraDevPalette.ivory,
            hapticLevel: ZyraHapticLevel.subtle,
            goldEnabled: false,
          ),
          onChooseHaptic: null,
          onGoldChanged: null,
        ),
      );
      final toggle = find.byKey(_gold);
      await _reveal(tester, toggle);
      expect(tester.widget<Switch>(toggle).onChanged, isNull);
      _expectNoDeveloperMenu();
    },
  );

  testWidgets(
    'ordinary accounts retain member choices without developer dropdowns',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await _mountFrame(tester, const PersonalisationScreen());
      final toggle = find.byKey(_gold);
      await _reveal(tester, toggle);
      tester.widget<Switch>(toggle).onChanged!(true);
      await tester.pump();
      expect(ZyraAppGoldStyle.instance.enabled, isTrue);
      _expectNoDeveloperMenu();
    },
  );

  testWidgets('owner admission loss refuses an already-open member selection', (
    tester,
  ) async {
    final state = await _mount(tester);
    await _open(tester);
    final sheet = _sheet(tester);
    state.change(() => state.allowed = false);
    await tester.pump();
    sheet.onSelected(ZyraHapticLevel.strong);
    await tester.pumpAndSettle();
    expect(state.hapticCalls, 0);
    expect(state.haptic, ZyraHapticLevel.subtle);
  });

  testWidgets(
    'member page replacement refuses retained choices despite reused labels',
    (tester) async {
      final state = await _mount(tester);
      await _open(tester);
      final sheet = _sheet(tester);
      state.change(() => state.page = 'replacement');
      await tester.pump();
      sheet.onSelected(ZyraHapticLevel.strong);
      await tester.pump();
      expect(state.hapticCalls, 0);
      zyraNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      final toggle = find.byKey(_gold);
      await _reveal(tester, toggle);
      tester.widget<Switch>(toggle).onChanged!(true);
      await tester.pump();
      expect(state.goldCalls, 1);
    },
  );

  testWidgets(
    'removing member settings while a sheet is open leaves callbacks inert',
    (tester) async {
      final state = await _mount(tester);
      await _open(tester);
      final sheet = _sheet(tester);
      state.change(() => state.visible = false);
      await tester.pump();
      sheet.onSelected(ZyraHapticLevel.strong);
      await tester.pump();
      expect(state.hapticCalls, 0);
      zyraNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Member settings unavailable'), findsOneWidget);
      _expectNoDeveloperMenu();
    },
  );

  testWidgets(
    'failed member callbacks surface errors without claiming a new selection',
    (tester) async {
      await _mountFrame(
        tester,
        ZyraPersonalisationChoiceSheet<String>(
          title: 'Member choices',
          options: const ['Current choice', 'Unavailable action'],
          selected: 'Current choice',
          labelFor: (value) => value,
          onSelected: (_) => throw StateError('Fixture action unavailable'),
        ),
      );
      await tester.tap(find.text('Unavailable action'));
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());
      expect(
        tester
            .widget<ZyraPersonalisationChoiceSheet<String>>(
              find.byType(ZyraPersonalisationChoiceSheet<String>),
            )
            .selected,
        'Current choice',
      );
      _expectNoDeveloperMenu();
    },
  );

  testWidgets(
    'late member sheet completion cannot overwrite a newer supplied choice',
    (tester) async {
      final state = await _mount(tester);
      await _open(tester);
      final sheet = _sheet(tester);
      state.change(() => state.haptic = ZyraHapticLevel.light);
      await tester.pump();
      sheet.onSelected(ZyraHapticLevel.strong);
      await tester.pumpAndSettle();
      expect(state.haptic, ZyraHapticLevel.light);
      expect(state.hapticCalls, 0);
    },
  );

  testWidgets(
    'long member choice labels and denial reasons fit narrow large text',
    (tester) async {
      var calls = 0;
      await _mountFrame(
        tester,
        ZyraTapFeedback(
          level: () => ZyraHapticLevel.off,
          canAct: () => false,
          child: ZyraPersonalisationChoiceSheet<String>(
            title: 'Member choices',
            options: const [
              'A longer member choice that wraps',
              'Unavailable role-aware content',
            ],
            selected: 'A longer member choice that wraps',
            labelFor: (value) => value,
            detailFor: (_) => 'Requires a Main Guardian role',
            onSelected: (_) => calls++,
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('A longer member choice that wraps'));
      await tester.pump();
      expect(calls, 0);
      final second = find.byKey(
        const ValueKey('personalisation_choice_Unavailable role-aware content'),
      );
      await tester.scrollUntilVisible(second, 120);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: second,
          matching: find.text('Requires a Main Guardian role'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      _expectNoDeveloperMenu();
    },
  );
}
