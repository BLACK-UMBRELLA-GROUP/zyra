// Pure developer gesture admission: no account, services or persistence.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_hold_to_open.dart';

const _surfaceKey = ValueKey('dev_controls_hold_surface');
Finder get _surface => find.byKey(_surfaceKey);

class _Binding {
  const _Binding({
    required this.open,
    required this.canOpen,
    this.enabled = true,
    this.identity = 'A',
  });

  final VoidCallback open;
  final bool Function() canOpen;
  final bool enabled;
  final Object identity;

  _Binding copy({
    VoidCallback? open,
    bool Function()? canOpen,
    bool? enabled,
    Object? identity,
  }) => _Binding(
    open: open ?? this.open,
    canOpen: canOpen ?? this.canOpen,
    enabled: enabled ?? this.enabled,
    identity: identity ?? this.identity,
  );
}

Future<void> _mount(
  WidgetTester tester,
  ValueNotifier<_Binding> binding, {
  Widget child = const ColoredBox(color: Colors.black),
  GlobalKey<NavigatorState>? navigator,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            height: 320,
            child: ValueListenableBuilder<_Binding>(
              valueListenable: binding,
              builder: (context, value, _) => ZyraDevHoldToOpen(
                enabled: value.enabled,
                identity: value.identity,
                canOpen: value.canOpen,
                onOpen: value.open,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<TestGesture> _press(WidgetTester tester, {int pointer = 1}) =>
    tester.startGesture(tester.getCenter(_surface), pointer: pointer);

Future<void> _hold(WidgetTester tester, {int pointer = 1}) async {
  final finger = await _press(tester, pointer: pointer);
  await tester.pump(const Duration(seconds: 3));
  await finger.up();
  await tester.pump();
}

class _DraftProbe extends StatefulWidget {
  const _DraftProbe({super.key});

  @override
  State<_DraftProbe> createState() => _DraftProbeState();
}

class _DraftProbeState extends State<_DraftProbe> {
  final text = TextEditingController();
  final scroll = ScrollController();

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(controller: text),
      Expanded(
        child: ListView.builder(
          controller: scroll,
          itemCount: 30,
          itemBuilder: (_, index) =>
              SizedBox(height: 40, child: Text('Row $index')),
        ),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'the exact three-second boundary opens once and rearms on a new press',
    (tester) async {
      var opens = 0;
      final binding = ValueNotifier(
        _Binding(open: () => opens++, canOpen: () => true),
      );
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final finger = await _press(tester);
      await tester.pump(const Duration(milliseconds: 2999));
      expect(opens, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(opens, 1);
      await tester.pump(const Duration(seconds: 4));
      expect(opens, 1);
      await finger.up();
      await tester.pump();
      await _hold(tester);
      expect(opens, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ordinary taps survive but a successful hold cancels the underlying tap',
    (tester) async {
      var opens = 0, taps = 0;
      final binding = ValueNotifier(
        _Binding(open: () => opens++, canOpen: () => true),
      );
      addTearDown(binding.dispose);
      await _mount(
        tester,
        binding,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      );
      await tester.tap(_surface);
      await tester.pump();
      expect(taps, 1);
      expect(opens, 0);
      await _hold(tester);
      expect(opens, 1);
      expect(taps, 1);
    },
  );

  for (final interruption in ['early up', 'cancel', 'movement']) {
    testWidgets('$interruption cancels the hold without opening', (
      tester,
    ) async {
      var opens = 0;
      final binding = ValueNotifier(
        _Binding(open: () => opens++, canOpen: () => true),
      );
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final finger = await _press(tester);
      await tester.pump(const Duration(seconds: 2));
      if (interruption == 'early up') {
        await finger.up();
      } else if (interruption == 'cancel') {
        await finger.cancel();
      } else {
        await finger.moveBy(const Offset(60, 0));
      }
      await tester.pump(const Duration(seconds: 3));
      expect(opens, 0);
      if (interruption == 'movement') await finger.up();
      await _hold(tester);
      expect(opens, 1);
    });
  }

  testWidgets('scrolling remains a normal child gesture', (tester) async {
    var opens = 0;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final binding = ValueNotifier(
      _Binding(open: () => opens++, canOpen: () => true),
    );
    addTearDown(binding.dispose);
    await _mount(
      tester,
      binding,
      child: ListView.builder(
        controller: scroll,
        itemCount: 30,
        itemBuilder: (_, index) =>
            SizedBox(height: 48, child: Text('Row $index')),
      ),
    );
    await tester.drag(_surface, const Offset(0, -120));
    await tester.pump(const Duration(seconds: 3));
    expect(scroll.offset, greaterThan(0));
    expect(opens, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the child ordinary long press wins before developer entry', (
    tester,
  ) async {
    var opens = 0, childHolds = 0;
    final binding = ValueNotifier(
      _Binding(open: () => opens++, canOpen: () => true),
    );
    addTearDown(binding.dispose);
    await _mount(
      tester,
      binding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => childHolds++,
        child: const SizedBox.expand(),
      ),
    );
    await _hold(tester);
    expect(childHolds, 1);
    expect(opens, 0);
  });

  testWidgets('normal text selection wins without opening developer controls', (
    tester,
  ) async {
    var opens = 0;
    final text = TextEditingController(
      text: 'A normal selectable circle message',
    );
    addTearDown(text.dispose);
    final binding = ValueNotifier(
      _Binding(open: () => opens++, canOpen: () => true),
    );
    addTearDown(binding.dispose);
    await _mount(
      tester,
      binding,
      child: TextField(
        controller: text,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
      ),
    );
    final finger = await tester.startGesture(
      tester.getTopLeft(find.byType(TextField)) + const Offset(40, 20),
    );
    await tester.pump(const Duration(seconds: 3));
    await finger.up();
    await tester.pump();
    expect(opens, 0);
    expect(text.selection.isValid, isTrue);
    expect(text.selection.isCollapsed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a second pointer cancels and both fingers must leave before rearming',
    (tester) async {
      var opens = 0;
      final binding = ValueNotifier(
        _Binding(open: () => opens++, canOpen: () => true),
      );
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final first = await _press(tester);
      await tester.pump(const Duration(seconds: 1));
      final second = await _press(tester, pointer: 2);
      await tester.pump(const Duration(seconds: 3));
      expect(opens, 0);
      await first.up();
      final third = await _press(tester, pointer: 3);
      await tester.pump(const Duration(seconds: 3));
      expect(opens, 0);
      await second.up();
      await third.up();
      await _hold(tester);
      expect(opens, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a second finger outside the surface also cancels the hold', (
    tester,
  ) async {
    var opens = 0;
    final binding = ValueNotifier(
      _Binding(open: () => opens++, canOpen: () => true),
    );
    addTearDown(binding.dispose);
    await _mount(tester, binding);
    final first = await _press(tester);
    final outside = await tester.startGesture(const Offset(10, 10), pointer: 2);
    await tester.pump(const Duration(seconds: 3));
    expect(opens, 0);
    await first.up();
    final third = await _press(tester, pointer: 3);
    await tester.pump(const Duration(seconds: 3));
    expect(opens, 0);
    await outside.up();
    await third.up();
    await _hold(tester);
    expect(opens, 1);
    expect(tester.takeException(), isNull);
  });

  for (final change in [
    'identity',
    'open callback',
    'admission callback',
    'disabled',
  ]) {
    testWidgets('$change replacement cancels the captured hold', (
      tester,
    ) async {
      var oldOpens = 0, newOpens = 0;
      final binding = ValueNotifier(
        _Binding(open: () => oldOpens++, canOpen: () => true),
      );
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final finger = await _press(tester);
      await tester.pump(const Duration(seconds: 2));
      binding.value = switch (change) {
        'identity' => binding.value.copy(identity: 'B'),
        'open callback' => binding.value.copy(open: () => newOpens++),
        'admission callback' => binding.value.copy(canOpen: () => true),
        _ => binding.value.copy(enabled: false),
      };
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(oldOpens + newOpens, 0);
      await finger.up();
      if (change == 'disabled') {
        binding.value = binding.value.copy(enabled: true);
        await tester.pump();
      }
      await _hold(tester);
      expect(oldOpens + newOpens, 1);
    });
  }

  testWidgets('identity A to B to A cannot revive the old hold', (
    tester,
  ) async {
    var opens = 0;
    final binding = ValueNotifier(
      _Binding(open: () => opens++, canOpen: () => true),
    );
    addTearDown(binding.dispose);
    await _mount(tester, binding);
    final original = binding.value;
    final finger = await _press(tester);
    await tester.pump(const Duration(seconds: 1));
    binding.value = original.copy(identity: 'B');
    await tester.pump();
    binding.value = original;
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(opens, 0);
    await finger.up();
    await _hold(tester);
    expect(opens, 1);
  });

  testWidgets('current admission is checked at the start and at completion', (
    tester,
  ) async {
    var opens = 0;
    var admitted = false;
    final binding = ValueNotifier(
      _Binding(open: () => opens++, canOpen: () => admitted),
    );
    addTearDown(binding.dispose);
    await _mount(tester, binding);
    var finger = await _press(tester);
    admitted = true;
    await tester.pump(const Duration(seconds: 3));
    expect(opens, 0);
    await finger.up();
    finger = await _press(tester);
    await tester.pump(const Duration(seconds: 2));
    admitted = false;
    await tester.pump(const Duration(seconds: 1));
    expect(opens, 0);
    await finger.up();
    admitted = true;
    await _hold(tester);
    expect(opens, 1);
  });

  testWidgets(
    'enabling during a denied press requires a fresh three-second hold',
    (tester) async {
      var opens = 0;
      final binding = ValueNotifier(
        _Binding(open: () => opens++, canOpen: () => true, enabled: false),
      );
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final finger = await _press(tester);
      binding.value = binding.value.copy(enabled: true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(opens, 0);
      await finger.up();
      await _hold(tester);
      expect(opens, 1);
    },
  );

  for (final failureAt in ['start', 'completion']) {
    testWidgets('admission exceptions at $failureAt fail closed', (
      tester,
    ) async {
      var opens = 0;
      var throws = failureAt == 'start';
      final binding = ValueNotifier(
        _Binding(
          open: () => opens++,
          canOpen: () {
            if (throws) throw StateError('Admission unavailable');
            return true;
          },
        ),
      );
      addTearDown(binding.dispose);
      await _mount(tester, binding);
      final finger = await _press(tester);
      throws = true;
      await tester.pump(const Duration(seconds: 3));
      await finger.up();
      expect(opens, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final lifecycle in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  ]) {
    testWidgets('$lifecycle and a resume cannot revive a captured hold', (
      tester,
    ) async {
      var opens = 0;
      final binding = ValueNotifier(
        _Binding(open: () => opens++, canOpen: () => true),
      );
      addTearDown(binding.dispose);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _mount(tester, binding);
      final finger = await _press(tester);
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 3));
      expect(opens, 0);
      await finger.up();
      await _hold(tester);
      expect(opens, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('covered route and route ABA cannot finish the old hold', (
    tester,
  ) async {
    var opens = 0;
    final navigator = GlobalKey<NavigatorState>();
    final binding = ValueNotifier(
      _Binding(open: () => opens++, canOpen: () => true),
    );
    addTearDown(binding.dispose);
    await _mount(tester, binding, navigator: navigator);
    final finger = await _press(tester);
    await tester.pump(const Duration(seconds: 1));
    navigator.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(opens, 0);
    await finger.up();
    await _hold(tester);
    expect(opens, 1);
  });

  testWidgets('unmount cancels a pending deadline', (tester) async {
    var opens = 0;
    final binding = ValueNotifier(
      _Binding(open: () => opens++, canOpen: () => true),
    );
    addTearDown(binding.dispose);
    await _mount(tester, binding);
    final finger = await _press(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    await finger.up();
    expect(opens, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'enabled and identity changes preserve child state, draft and scroll',
    (tester) async {
      final key = GlobalKey<_DraftProbeState>();
      final binding = ValueNotifier(_Binding(open: () {}, canOpen: () => true));
      addTearDown(binding.dispose);
      await _mount(tester, binding, child: _DraftProbe(key: key));
      final original = key.currentState!;
      original.text.text = 'Keep this draft';
      original.scroll.jumpTo(120);
      binding.value = binding.value.copy(enabled: false, identity: 'B');
      await tester.pump();
      binding.value = binding.value.copy(enabled: true, identity: 'A');
      await tester.pump();
      expect(identical(key.currentState, original), isTrue);
      expect(key.currentState!.text.text, 'Keep this draft');
      expect(key.currentState!.scroll.offset, 120);
      expect(_surface, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
