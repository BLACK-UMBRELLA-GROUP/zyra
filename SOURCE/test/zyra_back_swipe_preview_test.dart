// Physical edge gestures and accessible actions use one caller-owned return.
// Pure widget fixtures: no account, network, provider writes or persistence.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

const _edgeKey = ValueKey('zyra_back_swipe_edge');
const _buttonKey = ValueKey('zyra_visible_back_button');
const _probeKey = ValueKey('back-swipe-state-probe');
const _headerKey = ValueKey('back-swipe-tappable-header');
const _pagerKey = ValueKey('back-swipe-child-pager');
const _translationKey = ValueKey('zyra_back_swipe_translation');

double _slide(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(_translationKey).first)
    .transform
    .storage[12];

class _Binding {
  const _Binding({
    required this.back,
    this.revision = 0,
    this.route = 'original',
    this.enabled = true,
    this.showCue = true,
    this.keyboard = 0,
    this.reduced = false,
    this.accessible = false,
  });

  final VoidCallback back;
  final int revision;
  final Object route;
  final bool enabled;
  final bool showCue;
  final double keyboard;
  final bool reduced;
  final bool accessible;

  _Binding copy({
    VoidCallback? back,
    int? revision,
    Object? route,
    bool? enabled,
    bool? showCue,
    double? keyboard,
    bool? reduced,
    bool? accessible,
  }) => _Binding(
    back: back ?? this.back,
    revision: revision ?? this.revision,
    route: route ?? this.route,
    enabled: enabled ?? this.enabled,
    showCue: showCue ?? this.showCue,
    keyboard: keyboard ?? this.keyboard,
    reduced: reduced ?? this.reduced,
    accessible: accessible ?? this.accessible,
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
  final pages = PageController();
  int headerTaps = 0;

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        key: _headerKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => headerTaps++,
        child: const SizedBox(
          width: double.infinity,
          height: 64,
          child: Center(child: Text('Tappable child header')),
        ),
      ),
      TextField(controller: text),
      Expanded(
        child: PageView(
          key: _pagerKey,
          controller: pages,
          children: [
            ListView.builder(
              controller: scroll,
              itemCount: 40,
              itemBuilder: (_, index) =>
                  SizedBox(height: 50, child: Text('Readable row $index')),
            ),
            const ColoredBox(
              color: Colors.teal,
              child: Center(child: Text('Second child page')),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> _mount(
  WidgetTester tester,
  ValueNotifier<_Binding> binding, {
  bool manual = false,
  bool nested = false,
  bool optIn = true,
  double leftPadding = 0,
  double width = 400,
  GlobalKey<NavigatorState>? navigator,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final nav = navigator ?? GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ValueListenableBuilder<_Binding>(
      valueListenable: binding,
      builder: (_, value, _) {
        Widget child = const _Probe(key: _probeKey);
        if (nested) {
          child = ZyraPullDownCloseCue(
            enabled: true,
            onBack: value.back,
            routeIdentity: 'nested-cue',
            child: child,
          );
        }
        child = manual
            ? ZyraPullDownCloseCue(
                enabled: value.enabled && value.showCue,
                onBack: value.back,
                routeIdentity: value.route,
                child: child,
              )
            : ZyraPullDownBackScope(
                onBack: value.back,
                routeIdentity: value.route,
                enabled: value.enabled && value.showCue,
                child: child,
              );
        Widget app = MaterialApp(
          navigatorKey: nav,
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(top: 44, bottom: 34, left: leftPadding),
              viewPadding: EdgeInsets.only(
                top: 44,
                bottom: 34,
                left: leftPadding,
              ),
              viewInsets: EdgeInsets.only(bottom: value.keyboard),
              disableAnimations: value.reduced,
              accessibleNavigation: value.accessible,
            ),
            child: child!,
          ),
          home: Scaffold(body: child),
        );
        if (optIn) {
          app = ZyraBackNavigationPreview(revision: value.revision, child: app);
        }
        return app;
      },
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<TestGesture> _startSwipe(
  WidgetTester tester, {
  Offset start = const Offset(8, 300),
  Offset travel = const Offset(180, 0),
  int pointer = 1,
}) async {
  final finger = await tester.startGesture(start, pointer: pointer);
  for (var step = 0; step < 6; step++) {
    await finger.moveBy(travel / 6);
    await tester.pump(const Duration(milliseconds: 50));
  }
  // A held release proves the distance threshold without depending on fling.
  await tester.pump(const Duration(milliseconds: 200));
  return finger;
}

Future<void> _swipe(WidgetTester tester, {Offset? start}) async {
  final finger = await _startSwipe(
    tester,
    start: start ?? const Offset(8, 300),
  );
  await finger.up();
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Semantics _returnSemantics(WidgetTester tester) => tester
    .widgetList<Semantics>(
      find.byKey(const ValueKey('zyra_pull_down_back_semantics')),
    )
    .last;

VoidCallback _backDelegate(WidgetTester tester) => tester
    .widgetList<Semantics>(
      find.byKey(const ValueKey('zyra_pull_down_back_semantics')),
    )
    .where((widget) => widget.properties.onDismiss != null)
    .last
    .properties
    .onDismiss!;

void _restoreLifecycle(WidgetTester tester) {
  if (tester.binding.lifecycleState == AppLifecycleState.paused) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  }
  if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  }
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  for (final manual in [false, true]) {
    final host = manual ? 'manual cue' : 'shared scope';

    testWidgets(
      '$host edge swipe and accessible action share one return without Back chrome',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        expect(find.byKey(_edgeKey), findsOneWidget);
        final retainedAccessible = _backDelegate(tester);
        final finger = await _startSwipe(tester);
        expect(returns, 0, reason: 'A finger still down cannot return.');
        await finger.up();
        await tester.pumpAndSettle();
        expect(returns, 1);
        retainedAccessible();
        await _swipe(tester);
        expect(returns, 1);
      },
    );

    testWidgets(
      '$host accessible return consumes a simultaneously held swipe',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final finger = await _startSwipe(tester);
        _backDelegate(tester)();
        await finger.up();
        await tester.pumpAndSettle();
        expect(returns, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('$host comfortable left edge accepts a start at 40px', (
      tester,
    ) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, manual: manual);
      expect(tester.getSize(find.byKey(_edgeKey)).width, 44);
      await _swipe(tester, start: const Offset(40, 300));
      expect(returns, 1);
    });

    for (final scenario in [
      (width: 320.0, distance: 52.0),
      (width: 400.0, distance: 64.0),
      (width: 800.0, distance: 72.0),
    ]) {
      testWidgets(
        '$host shorter slow swipe returns at ${scenario.width}px width with ${scenario.distance}px travel',
        (tester) async {
          var returns = 0;
          final binding = ValueNotifier(_Binding(back: () => returns++));
          addTearDown(binding.dispose);
          await _mount(tester, binding, manual: manual, width: scenario.width);
          final finger = await _startSwipe(
            tester,
            travel: Offset(scenario.distance, 0),
          );
          expect(
            returns,
            0,
            reason: 'Distance alone cannot return while held.',
          );
          await finger.up();
          await tester.pumpAndSettle();
          expect(returns, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('$host slow travel below 64px at 400px does not return', (
      tester,
    ) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, manual: manual);
      final finger = await _startSwipe(tester, travel: const Offset(63, 0));
      expect(_slide(tester), closeTo(63, .01));
      await finger.up();
      await tester.pump();
      expect(_slide(tester), closeTo(63, .01));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_slide(tester), greaterThan(0));
      expect(_slide(tester), lessThan(63));
      expect(returns, 0);
      await tester.pump(const Duration(milliseconds: 99));
      expect(_slide(tester), greaterThan(0));
      expect(returns, 0);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();
      expect(returns, 0);
      expect(_slide(tester), 0);
      expect(find.byKey(_buttonKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$host short deliberate 600px-per-second flick returns', (
      tester,
    ) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, manual: manual);
      await tester.flingFrom(const Offset(8, 300), const Offset(32, 0), 600);
      await tester.pumpAndSettle();
      expect(returns, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$host fast travel below 24px cannot return', (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, manual: manual);
      await tester.flingFrom(const Offset(8, 300), const Offset(20, 0), 1800);
      await tester.pumpAndSettle();
      expect(returns, 0);
      expect(find.byKey(_buttonKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '$host finger tracks the whole page then visibly finishes before returning once',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final headerAtRest = tester.getRect(find.byKey(_headerKey));
        final retainedAccessible = _backDelegate(tester);
        final finger = await _startSwipe(tester, travel: const Offset(64, 0));
        final beforeRelease = tester.binding.clock.now();
        expect(returns, 0);
        expect(_slide(tester), closeTo(64, .01));
        expect(
          tester.getRect(find.byKey(_headerKey)).left - headerAtRest.left,
          closeTo(64, .01),
        );
        expect(tester.getRect(find.byKey(_edgeKey)).left, 0);
        expect(tester.getSize(find.byKey(_edgeKey)).width, 44);
        await finger.up();
        expect(
          returns,
          0,
          reason: 'Normal motion must remain visible after release.',
        );
        expect(tester.binding.clock.now(), beforeRelease);
        await tester.pump();
        expect(_slide(tester), closeTo(64, .01));
        var previous = _slide(tester);
        var elapsed = 0;
        for (final delta in [16, 64, 80, 79]) {
          elapsed += delta;
          await tester.pump(Duration(milliseconds: delta));
          final current = _slide(tester);
          expect(current, greaterThan(previous));
          expect(current, lessThan(400));
          expect(
            returns,
            0,
            reason: 'The owned finish is not complete at ${elapsed}ms.',
          );
          previous = current;
        }
        expect(elapsed, 239);
        await tester.pump(const Duration(milliseconds: 2));
        expect(returns, 1);
        retainedAccessible();
        await tester.pumpAndSettle();
        expect(returns, 1);
        expect(tester.takeException(), isNull);
      },
    );

    for (final travel in [
      const Offset(-180, 0),
      const Offset(0, -180),
      const Offset(32, 0),
      const Offset(40, 150),
    ]) {
      testWidgets('$host does not return on wrong or short travel $travel', (
        tester,
      ) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final finger = await _startSwipe(tester, travel: travel);
        await finger.up();
        await tester.pumpAndSettle();
        expect(returns, 0);
        expect(find.byKey(_buttonKey), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$host actual cancellation revokes an accepted edge swipe', (
      tester,
    ) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, manual: manual);
      final finger = await _startSwipe(tester);
      final held = _slide(tester);
      expect(held, greaterThan(0));
      await finger.cancel();
      await tester.pump();
      expect(returns, 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_slide(tester), inExclusiveRange(0, held));
      await tester.pumpAndSettle();
      expect(returns, 0);
      expect(_slide(tester), 0);
      await _swipe(tester);
      expect(returns, 1);
    });

    testWidgets('$host a second touch revokes the pending edge swipe', (
      tester,
    ) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, manual: manual);
      final first = await _startSwipe(tester);
      final second = await tester.startGesture(
        const Offset(300, 400),
        pointer: 2,
      );
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(returns, 0);
      await _swipe(tester, start: const Offset(8, 300));
      expect(returns, 1);
    });

    for (final phase in ['held', 'finishing']) {
      for (final change in [
        'checkpoint sequence',
        'revision',
        'callback',
        'route ABA',
        'disabled ABA',
        'covered route',
        'keyboard',
        'metrics',
        'motion ABA',
        'dispose',
      ]) {
        testWidgets('$host a $phase swipe cannot survive $change', (
          tester,
        ) async {
          var oldReturns = 0, newReturns = 0;
          final nav = GlobalKey<NavigatorState>();
          final binding = ValueNotifier(_Binding(back: () => oldReturns++));
          addTearDown(binding.dispose);
          await _mount(tester, binding, manual: manual, navigator: nav);
          final stale = _backDelegate(tester);
          final finger = await _startSwipe(tester);
          expect(_slide(tester), greaterThan(0));
          if (phase == 'finishing') {
            await finger.up();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 80));
            expect(_slide(tester), greaterThan(180));
            expect(oldReturns, 0);
          }
          switch (change) {
            case 'checkpoint sequence':
              binding.value = binding.value.copy(revision: 1);
              await tester.pump();
              binding.value = binding.value.copy(revision: 2);
            case 'revision':
              binding.value = binding.value.copy(revision: 1);
            case 'callback':
              binding.value = binding.value.copy(back: () => newReturns++);
            case 'route ABA':
              binding.value = binding.value.copy(route: 'replacement');
              await tester.pump();
              binding.value = binding.value.copy(route: 'original');
            case 'disabled ABA':
              binding.value = binding.value.copy(enabled: false);
              await tester.pump();
              binding.value = binding.value.copy(enabled: true);
            case 'covered route':
              nav.currentState!.push<void>(
                MaterialPageRoute(
                  builder: (_) => const Scaffold(body: Text('Cover')),
                ),
              );
              await tester.pumpAndSettle();
              nav.currentState!.pop();
              await tester.pumpAndSettle();
            case 'keyboard':
              binding.value = binding.value.copy(keyboard: 180);
              // Scaffold consumes its body's MediaQuery insets. Deliver the
              // real view metrics too, as opening a keyboard does on-device.
              tester.view.viewInsets = const FakeViewPadding(bottom: 180);
              addTearDown(tester.view.resetViewInsets);
            case 'metrics':
              tester.view.physicalSize = const Size(430, 800);
            case 'motion ABA':
              binding.value = binding.value.copy(reduced: true);
              await tester.pump();
              binding.value = binding.value.copy(reduced: false);
            case 'dispose':
              await tester.pumpWidget(const SizedBox.shrink());
          }
          await tester.pump();
          if (phase == 'held') await finger.up();
          await tester.pumpAndSettle();
          if (!['keyboard', 'metrics', 'motion ABA'].contains(change)) {
            stale();
            await tester.pumpAndSettle();
          }
          expect(oldReturns, 0);
          expect(newReturns, 0);
          if (change != 'dispose') {
            expect(_slide(tester), 0);
            await _swipe(tester);
            await tester.pumpAndSettle();
            expect(oldReturns + newReturns, 1);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final phase in ['held', 'finishing']) {
      testWidgets('$host lifecycle departure revokes a $phase edge swipe', (
        tester,
      ) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final finger = await _startSwipe(tester);
        if (phase == 'finishing') {
          await finger.up();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));
          expect(returns, 0);
        }
        try {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump();
          _restoreLifecycle(tester);
          await tester.pump();
          if (phase == 'held') await finger.up();
          await tester.pumpAndSettle();
          expect(returns, 0);
          expect(_slide(tester), 0);
        } finally {
          _restoreLifecycle(tester);
        }
        await _swipe(tester);
        expect(returns, 1);
      });
    }

    for (final preference in ['reduced', 'accessible']) {
      testWidgets(
        '$host $preference motion skips displacement and delayed return',
        (tester) async {
          var returns = 0;
          final binding = ValueNotifier(
            _Binding(
              back: () => returns++,
              reduced: preference == 'reduced',
              accessible: preference == 'accessible',
            ),
          );
          addTearDown(binding.dispose);
          await _mount(tester, binding, manual: manual);
          final finger = await _startSwipe(tester);
          expect(_slide(tester), 0);
          expect(returns, 0);
          final releasedAt = tester.binding.clock.now();
          await finger.up();
          expect(returns, 1);
          expect(tester.binding.clock.now(), releasedAt);
          await tester.pumpAndSettle();
          expect(_slide(tester), 0);
          expect(returns, 1);
        },
      );
    }

    testWidgets(
      '$host interactive motion preserves the same child draft selection scroll and pager',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final probe = tester.state<_ProbeState>(find.byKey(_probeKey));
        final editor = tester.state(find.byType(EditableText));
        probe.text.value = const TextEditingValue(
          text: 'Keep this unsent draft',
          selection: TextSelection(baseOffset: 5, extentOffset: 10),
        );
        probe.scroll.jumpTo(120);
        await tester.pump();
        void retained() {
          expect(tester.state<_ProbeState>(find.byKey(_probeKey)), same(probe));
          expect(tester.state(find.byType(EditableText)), same(editor));
          expect(probe.text.text, 'Keep this unsent draft');
          expect(
            probe.text.selection,
            const TextSelection(baseOffset: 5, extentOffset: 10),
          );
          expect(probe.scroll.offset, closeTo(120, .01));
          expect(probe.pages.page, closeTo(0, .01));
        }

        final cancelled = await _startSwipe(tester);
        retained();
        await cancelled.cancel();
        await tester.pumpAndSettle();
        retained();
        expect(returns, 0);
        final committed = await _startSwipe(tester);
        retained();
        await committed.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        retained();
        expect(returns, 0);
        await tester.pumpAndSettle();
        retained();
        expect(returns, 1);
      },
    );

    testWidgets(
      '$host a new touch during finish revokes navigation and restores the page',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final first = await _startSwipe(tester);
        await first.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(_slide(tester), greaterThan(180));
        final second = await tester.startGesture(
          const Offset(300, 400),
          pointer: 2,
        );
        await second.up();
        await tester.pumpAndSettle();
        expect(returns, 0);
        expect(_slide(tester), 0);
        await _swipe(tester);
        expect(returns, 1);
      },
    );

    testWidgets(
      '$host a retained Back consumes a finishing swipe exactly once',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final back = _backDelegate(tester);
        final first = await _startSwipe(tester);
        await first.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(returns, 0);
        back();
        back();
        await tester.pumpAndSettle();
        expect(returns, 1);
      },
    );

    testWidgets(
      '$host declined edge return restores its visual surface but stays consumed',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding, manual: manual);
        final probe = tester.state<_ProbeState>(find.byKey(_probeKey));
        final retained = _backDelegate(tester);
        final finger = await _startSwipe(tester);
        await finger.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 241));
        expect(returns, 1);
        await tester.pumpAndSettle();
        expect(_slide(tester), 0);
        expect(tester.state<_ProbeState>(find.byKey(_probeKey)), same(probe));
        expect(find.byKey(_edgeKey), findsNothing);
        expect(_returnSemantics(tester).properties.onDismiss, isNull);
        retained();
        await _swipe(tester);
        expect(returns, 1);
        expect(_slide(tester), 0);
      },
    );

    testWidgets(
      '$host completed Navigator pop keeps its outgoing page offscreen through route reverse',
      (tester) async {
        const parentKey = ValueKey('edge-motion-real-parent');
        const openKey = ValueKey('edge-motion-real-open');
        const outgoingKey = ValueKey('edge-motion-real-outgoing');
        var returns = 0;
        final navigator = GlobalKey<NavigatorState>();
        void back() {
          returns++;
          navigator.currentState!.pop();
        }

        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ZyraBackNavigationPreview(
            revision: 0,
            child: MaterialApp(
              navigatorKey: navigator,
              theme: ThemeData.dark(),
              home: Scaffold(
                key: parentKey,
                body: Center(
                  child: ElevatedButton(
                    key: openKey,
                    onPressed: () => navigator.currentState!.push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          key: outgoingKey,
                          body: manual
                              ? ZyraPullDownCloseCue(
                                  enabled: true,
                                  routeIdentity: 'real-pop-owner',
                                  onBack: back,
                                  child: const _Probe(key: _probeKey),
                                )
                              : ZyraPullDownBackScope(
                                  routeIdentity: 'real-pop-owner',
                                  onBack: back,
                                  child: const _Probe(key: _probeKey),
                                ),
                        ),
                      ),
                    ),
                    child: const Text('Open owned page'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(openKey));
        await tester.pumpAndSettle();
        final retained = _backDelegate(tester);
        final finger = await _startSwipe(tester);
        await finger.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 241));
        expect(returns, 1);
        final outgoing = find.byKey(outgoingKey, skipOffstage: false);
        final motion = find
            .descendant(
              of: outgoing,
              matching: find.byKey(_translationKey, skipOffstage: false),
            )
            .first;
        // Pump the real route's reverse without draining it. A second visible
        // exit must not begin from x=0 after the owned slide already completed.
        await tester.pump();
        for (final delta in [0, 16, 64, 80]) {
          await tester.pump(Duration(milliseconds: delta));
          expect(outgoing, findsOneWidget);
          expect(
            tester.widget<Transform>(motion).transform.storage[12],
            closeTo(400, .01),
          );
          expect(returns, 1);
        }
        retained();
        await tester.pumpAndSettle();
        expect(outgoing, findsNothing);
        expect(find.byKey(parentKey), findsOneWidget);
        expect(navigator.currentState!.canPop(), isFalse);
        expect(returns, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final method in ['semantics', 'Escape']) {
    testWidgets(
      '$method and finishing edge motion share the existing scope return once',
      (tester) async {
        var returns = 0;
        final binding = ValueNotifier(_Binding(back: () => returns++));
        addTearDown(binding.dispose);
        await _mount(tester, binding);
        final dismiss = tester
            .widget<Semantics>(
              find.byKey(const ValueKey('zyra_pull_down_back_semantics')),
            )
            .properties
            .onDismiss!;
        final first = await _startSwipe(tester);
        await first.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(returns, 0);
        if (method == 'semantics') {
          dismiss();
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        }
        await tester.pumpAndSettle();
        dismiss();
        await tester.pumpAndSettle();
        expect(returns, 1);
      },
    );
  }

  testWidgets(
    'a short deliberate rightward flick uses the velocity threshold',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      await tester.flingFrom(const Offset(8, 300), const Offset(64, 0), 1200);
      await tester.pumpAndSettle();
      expect(returns, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('physical left edge includes an existing wider safe-area inset', (
    tester,
  ) async {
    var returns = 0;
    final binding = ValueNotifier(_Binding(back: () => returns++));
    addTearDown(binding.dispose);
    await _mount(tester, binding, leftPadding: 56);
    expect(tester.getSize(find.byKey(_edgeKey)).width, 56);
    await _swipe(tester, start: const Offset(52, 300));
    expect(returns, 1);
  });

  testWidgets('a rightward drag beginning outside the edge does not return', (
    tester,
  ) async {
    var returns = 0;
    final binding = ValueNotifier(_Binding(back: () => returns++));
    addTearDown(binding.dispose);
    await _mount(tester, binding);
    final finger = await _startSwipe(tester, start: const Offset(48, 300));
    expect(
      _slide(tester),
      0,
      reason: 'Starting outside the fixed edge cannot move the page.',
    );
    await finger.up();
    await tester.pumpAndSettle();
    expect(returns, 0);
    expect(_slide(tester), 0);
  });

  testWidgets(
    'a new touch before queued completion revokes the released swipe',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final first = TestPointer(7);
      final second = TestPointer(8);
      tester.binding.handlePointerEvent(first.down(const Offset(8, 300)));
      for (var step = 1; step <= 6; step++) {
        tester.binding.handlePointerEvent(
          first.move(
            Offset(8 + step * 30.0, 300),
            timeStamp: Duration(milliseconds: step * 50),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      // Keep both events in the same dispatch turn. Awaiting TestGesture.up()
      // would drain the queued handover before the second touch could arrive.
      tester.binding.handlePointerEvent(
        first.up(timeStamp: const Duration(milliseconds: 500)),
      );
      tester.binding.handlePointerEvent(
        second.down(
          const Offset(300, 400),
          timeStamp: const Duration(milliseconds: 500),
        ),
      );
      tester.binding.handlePointerEvent(
        second.up(timeStamp: const Duration(milliseconds: 510)),
      );
      await tester.pumpAndSettle();
      expect(returns, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('center horizontal paging stays with the child PageView', (
    tester,
  ) async {
    var returns = 0;
    final binding = ValueNotifier(_Binding(back: () => returns++));
    addTearDown(binding.dispose);
    await _mount(tester, binding);
    final probe = tester.state<_ProbeState>(find.byKey(_probeKey));
    await tester.dragFrom(const Offset(300, 400), const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(probe.pages.page, closeTo(1, .01));
    await tester.dragFrom(const Offset(130, 400), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(probe.pages.page, closeTo(0, .01));
    expect(returns, 0);
    probe.pages.jumpToPage(1);
    await tester.pumpAndSettle();
    await _swipe(tester, start: const Offset(8, 400));
    expect(returns, 1);
    expect(
      probe.pages.page,
      closeTo(1, .01),
      reason: 'The edge handover must not also page the child.',
    );
  });

  testWidgets(
    'the translucent edge leaves child taps and vertical scroll usable',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final probe = tester.state<_ProbeState>(find.byKey(_probeKey));
      final header = tester.getRect(find.byKey(_headerKey));
      await tester.tapAt(Offset(8, header.center.dy));
      await tester.pump();
      expect(probe.headerTaps, 1);
      await tester.dragFrom(const Offset(8, 500), const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(probe.scroll.offset, greaterThan(60));
      expect(returns, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'one ancestor owns the accessible return and edge across nested cues',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, nested: true);
      expect(find.byKey(_edgeKey), findsOneWidget);
      expect(find.byKey(_buttonKey), findsNothing);
      await _swipe(tester);
      expect(returns, 1);
    },
  );

  testWidgets(
    'nested inline slots show no Back and retain only the outer return owner',
    (tester) async {
      var outerReturns = 0, innerReturns = 0;
      const innerKey = ValueKey('nested-inline-back-child');
      await tester.pumpWidget(
        ZyraBackNavigationPreview(
          revision: 0,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: ZyraPullDownCloseCue(
                enabled: true,
                inlineBackHeader: true,
                routeIdentity: 'outer-inline-owner',
                onBack: () => outerReturns++,
                child: ZyraPullDownCloseCue(
                  key: innerKey,
                  enabled: true,
                  routeIdentity: 'inner-non-owner',
                  onBack: () => innerReturns++,
                  child: const Column(
                    children: [
                      ZyraInlineBackButton(),
                      Expanded(child: SizedBox.expand()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_buttonKey), findsNothing);
      expect(find.text('Back'), findsNothing);
      expect(find.byKey(_edgeKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(innerKey),
          matching: find.byKey(_edgeKey),
        ),
        findsNothing,
        reason: 'The inner cue may inherit the return, not own an edge.',
      );
      final retainedBack = _backDelegate(tester);
      await _swipe(tester);
      await tester.pumpAndSettle();
      expect(outerReturns, 1);
      expect(innerReturns, 0);
      retainedBack();
      await tester.pump();
      expect(outerReturns, 1);
      expect(innerReturns, 0);
      expect(_returnSemantics(tester).properties.onDismiss, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard and checkpoints preserve the child draft and scroll state',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final probe = tester.state<_ProbeState>(find.byKey(_probeKey));
      probe.text.text = 'Keep this unsent draft';
      probe.scroll.jumpTo(120);
      await tester.pump();
      for (var revision = 1; revision <= 4; revision++) {
        binding.value = binding.value.copy(
          revision: revision,
          keyboard: revision.isOdd ? 180 : 0,
        );
        await tester.pump();
        expect(tester.state<_ProbeState>(find.byKey(_probeKey)), same(probe));
        expect(probe.text.text, 'Keep this unsent draft');
        expect(probe.scroll.offset, closeTo(120, .01));
      }
      await _swipe(tester);
      expect(returns, 1);
      expect(probe.text.text, 'Keep this unsent draft');
    },
  );

  testWidgets(
    'no provider keeps swipe-only Back while a disabled return cannot invent an edge',
    (tester) async {
      var returns = 0;
      final binding = ValueNotifier(_Binding(back: () => returns++));
      addTearDown(binding.dispose);
      await _mount(tester, binding, optIn: false);
      expect(find.byKey(_edgeKey), findsOneWidget);
      expect(find.byKey(_buttonKey), findsNothing);
      await _swipe(tester);
      expect(returns, 1);
      await _mount(tester, binding);
      binding.value = binding.value.copy(showCue: false);
      await tester.pump();
      expect(find.byKey(_edgeKey), findsNothing);
      expect(find.byKey(_buttonKey), findsNothing);
      await _swipe(tester);
      expect(returns, 1);
    },
  );
}
