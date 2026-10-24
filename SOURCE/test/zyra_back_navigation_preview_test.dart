// Isolated swipe-only display/return ownership. No account, network or persistence.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

const _buttonKey = ValueKey('zyra_visible_back_button');
const _probeKey = ValueKey('back-preview-probe');
const _headerKey = ValueKey('back-preview-title');

class _Binding {
  const _Binding({
    required this.back,
    this.revision = 0,
    this.route = 'first',
    this.enabled = true,
    this.showCue = true,
  });

  final VoidCallback back;
  final int revision;
  final Object route;
  final bool enabled;
  final bool showCue;

  _Binding copy({
    VoidCallback? back,
    int? revision,
    Object? route,
    bool? enabled,
    bool? showCue,
  }) => _Binding(
    back: back ?? this.back,
    revision: revision ?? this.revision,
    route: route ?? this.route,
    enabled: enabled ?? this.enabled,
    showCue: showCue ?? this.showCue,
  );
}

class _Probe extends StatefulWidget {
  const _Probe({super.key});
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final text = TextEditingController();
  final scroll = ScrollController();

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        const SizedBox(
          key: _headerKey,
          width: double.infinity,
          height: 64,
          child: Text('Page title', style: TextStyle(fontSize: 18)),
        ),
        TextField(
          controller: text,
          decoration: const InputDecoration(hintText: 'Draft'),
        ),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            itemCount: 50,
            itemBuilder: (context, index) =>
                SizedBox(height: 50, child: Text('Row $index')),
          ),
        ),
      ],
    ),
  );
}

Finder get _button => find.byKey(_buttonKey);
Finder get _surface => find.byKey(_probeKey);
Finder get _arrow =>
    find.byKey(const ValueKey('zyra_pull_down_bottom_cue_arrow'));

VoidCallback _backDelegate(WidgetTester tester) => tester
    .widgetList<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.key == const ValueKey('zyra_pull_down_back_semantics') &&
            widget.properties.onDismiss != null,
      ),
    )
    .last
    .properties
    .onDismiss!;

Future<void> _swipeBack(WidgetTester tester) async {
  final edge = find.byKey(const ValueKey('zyra_back_swipe_edge')).hitTestable();
  expect(edge, findsOneWidget);
  final rect = tester.getRect(edge);
  await tester.timedDragFrom(
    Offset(rect.left + 8, rect.top + rect.height * .35),
    const Offset(190, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester,
  ValueNotifier<_Binding> binding, {
  bool optIn = true,
  bool manual = false,
  bool nested = false,
  Size size = const Size(393, 852),
  double scale = 1,
  double keyboard = 0,
  GlobalKey<NavigatorState>? navigator,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  const probe = _Probe(key: _probeKey);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: EdgeInsets.only(top: 44, bottom: keyboard == 0 ? 34 : 0),
          viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: child!,
      ),
      home: ValueListenableBuilder<_Binding>(
        valueListenable: binding,
        builder: (context, value, _) {
          Widget content = probe;
          if (nested) {
            content = ZyraPullDownCloseCue(
              enabled: true,
              onBack: value.back,
              routeIdentity: 'inner',
              child: content,
            );
          }
          content = manual
              ? ZyraPullDownCloseCue(
                  enabled: value.enabled && value.showCue,
                  onBack: value.back,
                  routeIdentity: value.route,
                  child: content,
                )
              : ZyraPullDownBackScope(
                  routeIdentity: value.route,
                  onBack: value.back,
                  enabled: value.enabled && value.showCue,
                  child: content,
                );
          if (optIn) {
            content = ZyraBackNavigationPreview(
              revision: value.revision,
              child: content,
            );
          }
          return Scaffold(body: content);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<TestGesture> _startPull(WidgetTester tester) async {
  final finger = await tester.startGesture(
    tester.getCenter(find.byKey(_headerKey)),
  );
  for (var step = 0; step < 6; step++) {
    await finger.moveBy(const Offset(0, 35));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 200));
  return finger;
}

Future<void> _mountNestedBridge(
  WidgetTester tester, {
  required GlobalKey<NavigatorState> navigator,
  required VoidCallback parentBack,
  required VoidCallback childBack,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: ZyraPullDownBackScope(
          routeIdentity: 'outer-return-owner',
          inlineBackHeader: true,
          onBack: parentBack,
          child: Navigator(
            key: navigator,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [ZyraInlineBackButton(), Text('Nested root')],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  navigator.currentState!.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ZyraPullDownBackScope(
        routeIdentity: 'nested-child-return',
        onBack: childBack,
        child: const Scaffold(body: Text('Nested child')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Nested child'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets(
    'without a provider the edge returns without visible Back or downward dismissal',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, optIn: false);
      final context = tester.element(find.byKey(_probeKey));
      expect(ZyraBackNavigationPreview.revisionOf(context), 0);
      expect(_button, findsNothing);
      expect(_arrow, findsNothing);
      final finger = await _startPull(tester);
      await finger.up();
      await tester.pumpAndSettle();
      expect(returns, 0);
      await _swipeBack(tester);
      await tester.pumpAndSettle();
      expect(returns, 1);
    },
  );

  testWidgets(
    'edge swipe consumes the captured owner once without Back or bottom cue',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      expect(_button, findsNothing);
      expect(_arrow, findsNothing);
      final finger = await _startPull(tester);
      await finger.up();
      await tester.pumpAndSettle();
      expect(returns, 0);
      final back = _backDelegate(tester);
      await _swipeBack(tester);
      back();
      await tester.pumpAndSettle();
      expect(returns, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final stage in ['drag', 'settle']) {
    testWidgets(
      'a checkpoint change during $stage never admits a downward return',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding);
        final finger = await _startPull(tester);
        if (stage == 'settle') {
          await finger.up();
          await tester.pump(const Duration(milliseconds: 80));
        }
        binding.value = binding.value.copy(revision: 1);
        await tester.pump();
        if (stage == 'drag') await finger.up();
        await tester.pumpAndSettle();
        expect(returns, 0);
        expect(
          find.byKey(const ValueKey('zyra_pull_down_back_surface')),
          findsNothing,
        );
        await _swipeBack(tester);
        await tester.pumpAndSettle();
        expect(returns, 1);
      },
    );
  }

  for (final manual in [false, true]) {
    testWidgets(
      '${manual ? 'manual' : 'scope'} successive checkpoints reject retained delegates',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final old = _backDelegate(tester);
        final oldSemantics = _backDelegate(tester);
        binding.value = binding.value.copy(revision: 1);
        await tester.pump();
        binding.value = binding.value.copy(revision: 2);
        await tester.pump();
        old();
        oldSemantics();
        expect(returns, 0);
        final sameModeOld = _backDelegate(tester);
        binding.value = binding.value.copy(revision: 4);
        await tester.pump();
        sameModeOld();
        expect(returns, 0);
        await _swipeBack(tester);
        await tester.pumpAndSettle();
        expect(returns, 1);
      },
    );
  }

  testWidgets('a downward finger cannot become a return after a checkpoint', (
    tester,
  ) async {
    var returns = 0;
    final binding = ValueNotifier(_Binding(back: () => returns++));
    addTearDown(binding.dispose);
    await _mount(tester, binding);
    final staleFinger = await _startPull(tester);
    binding.value = binding.value.copy(revision: 1);
    await tester.pump();
    await staleFinger.up();
    binding.value = binding.value.copy(revision: 2);
    await tester.pump();
    final freshFinger = await _startPull(tester);
    await freshFinger.up();
    await tester.pumpAndSettle();
    expect(returns, 0);
    await _swipeBack(tester);
    await tester.pumpAndSettle();
    expect(returns, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manual decoration without callback or route does not invent a Back action',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ZyraBackNavigationPreview(
            revision: 1,
            child: Scaffold(
              body: ZyraPullDownCloseCue(
                enabled: true,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_button, findsNothing);
      expect(_arrow, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final manual in [false, true]) {
    for (final change in ['callback', 'route', 'disabled']) {
      testWidgets(
        '${manual ? 'manual' : 'scope'} old Back refuses $change replacement',
        (tester) async {
          var oldReturns = 0, newReturns = 0;
          final binding = ValueNotifier(_Binding(back: () => oldReturns++));
          addTearDown(binding.dispose);
          await _mount(tester, binding, manual: manual);
          final stale = _backDelegate(tester);
          binding.value = switch (change) {
            'callback' => binding.value.copy(back: () => newReturns++),
            'route' => binding.value.copy(route: 'second'),
            _ => binding.value.copy(enabled: false),
          };
          await tester.pump();
          stale();
          expect(oldReturns, 0);
          expect(newReturns, 0);
          if (change == 'disabled') {
            expect(_button, findsNothing);
          } else {
            final current = _backDelegate(tester);
            current();
            current();
            await tester.pumpAndSettle();
            expect(oldReturns + newReturns, 1);
          }
        },
      );
    }

    testWidgets(
      '${manual ? 'manual' : 'scope'} covered Back is denied and cannot revive on return',
      (tester) async {
        var returns = 0;
        final navigator = GlobalKey<NavigatorState>();
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual, navigator: navigator);
        final stale = _backDelegate(tester);
        navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Cover')),
          ),
        );
        await tester.pumpAndSettle();
        stale();
        expect(returns, 0);
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        stale();
        expect(returns, 0);
        await _swipeBack(tester);
        await tester.pumpAndSettle();
        expect(returns, 1);
      },
    );

    testWidgets(
      '${manual ? 'manual' : 'scope'} retained Back denies after unmount',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final stale = _backDelegate(tester);
        await tester.pumpWidget(const SizedBox());
        stale();
        expect(returns, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'one ancestor owns the swipe and accessible return across nested manual cues',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, nested: true);
      expect(_button, findsNothing);
      await _swipeBack(tester);
      await tester.pumpAndSettle();
      expect(returns, 1);
    },
  );

  testWidgets(
    'nested Navigator leaf keeps one inherited return and one edge without Back chrome',
    (tester) async {
      var parentReturns = 0, childReturns = 0;
      final navigator = GlobalKey<NavigatorState>();
      await _mountNestedBridge(
        tester,
        navigator: navigator,
        parentBack: () {
          parentReturns++;
          if (navigator.currentState!.canPop()) {
            navigator.currentState!.pop();
          }
        },
        childBack: () => childReturns++,
      );
      expect(_button, findsNothing);
      expect(
        find.byKey(const ValueKey('zyra_back_swipe_edge')),
        findsOneWidget,
      );
      final retained = _backDelegate(tester);
      await _swipeBack(tester);
      retained();
      await tester.pumpAndSettle();
      retained();
      expect(parentReturns, 1);
      expect(childReturns, 0);
      expect(find.text('Nested child'), findsNothing);
      expect(find.text('Nested root'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inherited leaf Back denies a cover and cannot revive after route ABA',
    (tester) async {
      var parentReturns = 0, childReturns = 0;
      final navigator = GlobalKey<NavigatorState>();
      await _mountNestedBridge(
        tester,
        navigator: navigator,
        parentBack: () {
          parentReturns++;
          if (navigator.currentState!.canPop()) {
            navigator.currentState!.pop();
          }
        },
        childBack: () => childReturns++,
      );
      final retained = _backDelegate(tester);
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Unrelated nested cover')),
        ),
      );
      await tester.pumpAndSettle();
      retained();
      await tester.pumpAndSettle();
      expect(parentReturns, 0);
      expect(find.text('Unrelated nested cover'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      retained();
      await tester.pumpAndSettle();
      expect(parentReturns, 0);
      expect(childReturns, 0);
      expect(find.text('Nested child'), findsOneWidget);
      expect(_button, findsNothing);
      await _swipeBack(tester);
      await tester.pumpAndSettle();
      expect(parentReturns, 1);
      expect(childReturns, 0);
      expect(find.text('Nested root'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inherited leaf Back denies after external pop without consuming parent',
    (tester) async {
      var parentReturns = 0, childReturns = 0;
      final navigator = GlobalKey<NavigatorState>();
      await _mountNestedBridge(
        tester,
        navigator: navigator,
        parentBack: () => parentReturns++,
        childBack: () => childReturns++,
      );
      final retained = _backDelegate(tester);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      retained();
      await tester.pumpAndSettle();
      expect(parentReturns, 0);
      expect(childReturns, 0);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(find.text('Nested child'), findsNothing);
      expect(find.text('Nested root'), findsOneWidget);
      expect(_button, findsNothing);
      await _swipeBack(tester);
      await tester.pumpAndSettle();
      expect(parentReturns, 1);
      expect(childReturns, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inline expansion without a full-page cue gains no visible Back button',
    (tester) async {
      final binding = ValueNotifier(_Binding(back: () {}, showCue: false));
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      expect(_button, findsNothing);
      expect(_arrow, findsNothing);
    },
  );

  testWidgets(
    'owner checkpoints preserve child State composer and scroll position',
    (tester) async {
      final binding = ValueNotifier(_Binding(back: () {}));
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final state = tester.state<_ProbeState>(find.byKey(_probeKey));
      state.text.text = 'Keep this draft';
      state.scroll.jumpTo(120);
      await tester.pump();
      for (var revision = 1; revision <= 4; revision++) {
        binding.value = binding.value.copy(revision: revision);
        await tester.pump();
        expect(tester.state<_ProbeState>(find.byKey(_probeKey)), same(state));
        expect(state.text.text, 'Keep this draft');
        expect(state.scroll.offset, 120);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact double text with keyboard leaves no Back strip above title and input',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(
        tester,
        binding,
        size: const Size(320, 568),
        scale: 2,
        keyboard: 180,
      );
      expect(_button, findsNothing);
      final title = tester.getRect(find.byKey(_headerKey));
      final input = tester.getRect(find.byType(TextField));
      expect(title.top, 44);
      expect(title.bottom, lessThanOrEqualTo(input.top));
      expect(
        find.byKey(const ValueKey('zyra_back_header_space')),
        findsNothing,
      );
      expect(find.text('Back'), findsNothing);
      expect(_arrow, findsNothing);
      expect(tester.takeException(), isNull);
      await _swipeBack(tester);
      await tester.pumpAndSettle();
      expect(returns, 1);
    },
  );

  for (final manual in [false, true]) {
    for (final method in ['dismiss', 'custom Back', 'Escape']) {
      testWidgets(
        '${manual ? 'manual' : 'scope'} $method remains an accessible once-only return without visible Back',
        (tester) async {
          var returns = 0;
          final binding = ValueNotifier(_Binding(back: () => returns++));
          addTearDown(binding.dispose);
          await _mount(tester, binding, manual: manual);
          expect(_button, findsNothing);
          expect(find.text('Back'), findsNothing);
          final semantics = tester.widget<Semantics>(
            find.byKey(const ValueKey('zyra_pull_down_back_semantics')),
          );
          final retained = semantics.properties.onDismiss!;
          final custom = semantics.properties.customSemanticsActions!.entries
              .singleWhere((entry) => entry.key.label == 'Back')
              .value;
          if (method == 'dismiss') {
            retained();
          } else if (method == 'custom Back') {
            custom();
          } else {
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          }
          retained();
          custom();
          Actions.invoke(tester.element(_surface), const DismissIntent());
          await tester.pumpAndSettle();
          expect(returns, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final disabled in [false, true]) {
    testWidgets(
      '${disabled ? 'disabled scope' : 'enabled non-owner cue'} handles nested Escape without changing return ownership',
      (tester) async {
        var parentReturns = 0, childReturns = 0;
        const childKey = ValueKey('nested-keyboard-child');
        const focusKey = ValueKey('nested-keyboard-focus');
        const child = Focus(
          key: focusKey,
          autofocus: true,
          child: Text('Keyboard target'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ZyraPullDownBackScope(
                routeIdentity: 'keyboard-parent',
                onBack: () => parentReturns++,
                child: disabled
                    ? ZyraPullDownBackScope(
                        key: childKey,
                        routeIdentity: 'disabled-keyboard-child',
                        enabled: false,
                        onBack: () => childReturns++,
                        child: child,
                      )
                    : ZyraPullDownCloseCue(
                        key: childKey,
                        routeIdentity: 'non-owning-keyboard-child',
                        enabled: true,
                        onBack: () => childReturns++,
                        child: child,
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(_buttonKey), findsNothing);
        expect(
          find.byKey(const ValueKey('zyra_back_swipe_edge')),
          findsOneWidget,
        );
        final innerSemantics = tester.widget<Semantics>(
          find.descendant(
            of: find.byKey(childKey),
            matching: find.byKey(
              const ValueKey('zyra_pull_down_back_semantics'),
            ),
          ),
        );
        expect(innerSemantics.properties.onDismiss, isNull);
        expect(innerSemantics.properties.customSemanticsActions, isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(parentReturns, disabled ? 0 : 1);
        expect(childReturns, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
