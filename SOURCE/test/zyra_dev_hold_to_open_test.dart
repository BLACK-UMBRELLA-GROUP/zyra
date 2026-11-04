// Member gesture and ownership contracts after removal of developer hold entry.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/main.dart' show ZyraApp, zyraNavigatorKey;
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

const _memberSurface = ValueKey('member-gesture-surface');
Finder get _surface => find.byKey(_memberSurface);

void _expectNoDeveloperEntry() {
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value.startsWith(
                'dev_controls_',
              ) ||
              (widget.key! as ValueKey<String>).value.startsWith('dev_rail_')),
    ),
    findsNothing,
  );
}

Future<void> _mount(
  WidgetTester tester, {
  Widget child = const ColoredBox(color: Colors.black),
}) async {
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
          builder: app.builder,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: _memberSurface,
                width: 240,
                height: 320,
                child: child,
              ),
            ),
          ),
        );
      },
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
  _expectNoDeveloperEntry();
}

Widget _tapTarget(VoidCallback callback) => GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: callback,
  child: const SizedBox.expand(),
);

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

Future<void> _failedRefresh(WidgetTester tester) async {
  ZyraDeveloperAccess.setAuthorizedForTesting(false);
  const founder = User(
    id: '11111111-1111-4111-8111-111111111111',
    appMetadata: {'zyra_role': 'founder'},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-09-14T00:00:00Z',
  );
  ZyraDeveloperAccess.configureAuthorizationForTesting(
    variant: ZyraAppVariant.production,
    currentUser: () => founder,
    refreshSession: () async =>
        throw StateError('Synthetic unavailable refresh'),
    founderIdentityMatches: (_) => true,
  );
  final result = await tester.runAsync(
    ZyraDeveloperAccess.refreshCurrentAuthorization,
  );
  expect(result, isFalse);
  expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets(
    'the three-second boundary and repeated presses never open developer entry',
    (tester) async {
      await _mount(tester);
      final finger = await _press(tester);
      await tester.pump(const Duration(milliseconds: 2999));
      _expectNoDeveloperEntry();
      await tester.pump(const Duration(milliseconds: 1));
      _expectNoDeveloperEntry();
      await tester.pump(const Duration(seconds: 4));
      _expectNoDeveloperEntry();
      await finger.up();
      await _hold(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ordinary taps and long holds reach the underlying member tap target',
    (tester) async {
      var taps = 0;
      await _mount(tester, child: _tapTarget(() => taps++));
      await tester.tap(_surface);
      await tester.pump();
      expect(taps, 1);
      await _hold(tester);
      expect(taps, 2);
    },
  );

  for (final interruption in ['early up', 'cancel', 'movement']) {
    testWidgets(
      '$interruption preserves normal member gesture cancellation without developer entry',
      (tester) async {
        var taps = 0;
        await _mount(tester, child: _tapTarget(() => taps++));
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
        if (interruption == 'movement') await finger.up();
        expect(taps, interruption == 'early up' ? 1 : 0);
        _expectNoDeveloperEntry();
        final before = taps;
        await _hold(tester);
        expect(taps, before + 1);
      },
    );
  }

  testWidgets('scrolling remains a normal child gesture', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await _mount(
      tester,
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
    _expectNoDeveloperEntry();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the child ordinary long press remains the only hold action', (
    tester,
  ) async {
    var childHolds = 0;
    await _mount(
      tester,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => childHolds++,
        child: const SizedBox.expand(),
      ),
    );
    await _hold(tester);
    expect(childHolds, 1);
  });

  testWidgets('normal text selection wins without opening developer controls', (
    tester,
  ) async {
    final text = TextEditingController(
      text: 'A normal selectable circle message',
    );
    addTearDown(text.dispose);
    await _mount(
      tester,
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
    _expectNoDeveloperEntry();
    expect(text.selection.isValid, isTrue);
    expect(text.selection.isCollapsed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'multiple member pointers cannot arm hidden controls and fresh taps still work',
    (tester) async {
      var downs = 0, ups = 0;
      await _mount(
        tester,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => downs++,
          onPointerUp: (_) => ups++,
          child: const SizedBox.expand(),
        ),
      );
      final first = await _press(tester);
      await tester.pump(const Duration(seconds: 1));
      final second = await _press(tester, pointer: 2);
      await tester.pump(const Duration(seconds: 3));
      await first.up();
      final third = await _press(tester, pointer: 3);
      await tester.pump(const Duration(seconds: 3));
      await second.up();
      await third.up();
      expect([downs, ups], [3, 3]);
      _expectNoDeveloperEntry();
      await _hold(tester);
      expect([downs, ups], [4, 4]);
    },
  );

  testWidgets(
    'outside pointers cannot create developer entry or consume member touches',
    (tester) async {
      var downs = 0;
      await _mount(
        tester,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => downs++,
          child: const SizedBox.expand(),
        ),
      );
      final first = await _press(tester);
      final outside = await tester.startGesture(
        const Offset(10, 10),
        pointer: 2,
      );
      await tester.pump(const Duration(seconds: 3));
      await first.up();
      final third = await _press(tester, pointer: 3);
      await tester.pump(const Duration(seconds: 3));
      await outside.up();
      await third.up();
      expect(downs, 2);
      _expectNoDeveloperEntry();
      await _hold(tester);
      expect(downs, 3);
      expect(tester.takeException(), isNull);
    },
  );

  for (final change in [
    'identity',
    'open callback',
    'admission callback',
    'disabled',
  ]) {
    testWidgets(
      '$change member replacement rejects retained actions while holds stay inert',
      (tester) async {
        final version = ValueNotifier(0);
        addTearDown(version.dispose);
        var oldCalls = 0, newCalls = 0;
        var allowed = true;
        bool admission() => allowed;
        bool replacementAdmission() => allowed;
        void oldAction(bool value) => oldCalls++;
        void newAction(bool value) => newCalls++;
        void hapticAction(ZyraHapticLevel value) {}
        await _mount(
          tester,
          child: ValueListenableBuilder<int>(
            valueListenable: version,
            builder: (context, revision, _) => PersonalisationScreen.preview(
              key: ValueKey(change == 'identity' ? revision : 0),
              canAct: change == 'admission callback' && revision > 0
                  ? replacementAdmission
                  : admission,
              palette: ZyraDevPalette.ivory,
              hapticLevel: ZyraHapticLevel.subtle,
              goldEnabled: false,
              onHapticChanged: hapticAction,
              onGoldChanged: change == 'open callback' && revision > 0
                  ? newAction
                  : oldAction,
            ),
          ),
        );
        final stale = tester
            .widget<ZyraPersonalisationContent>(
              find.byType(ZyraPersonalisationContent),
            )
            .onGoldChanged!;
        final finger = await tester.startGesture(const Offset(10, 10));
        await tester.pump(const Duration(seconds: 2));
        if (change == 'disabled') allowed = false;
        version.value++;
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        stale(true);
        expect(oldCalls + newCalls, 0);
        await finger.up();
        _expectNoDeveloperEntry();
        if (change == 'disabled') {
          expect(find.byType(ZyraPersonalisationContent), findsNothing);
          expect(
            find.byKey(const ValueKey('personalisation-unavailable')),
            findsOneWidget,
          );
          allowed = true;
          version.value++;
          await tester.pump();
          stale(true);
          expect(oldCalls + newCalls, 0);
          expect(find.byType(ZyraPersonalisationContent), findsNothing);
        } else {
          final current = tester
              .widget<ZyraPersonalisationContent>(
                find.byType(ZyraPersonalisationContent),
              )
              .onGoldChanged!;
          if (change == 'admission callback') {
            allowed = false;
            current(true);
            expect(oldCalls + newCalls, 0);
            allowed = true;
            current(true);
            expect(oldCalls + newCalls, 0);
          } else {
            current(true);
            expect(oldCalls, change == 'identity' ? 1 : 0);
            expect(newCalls, change == 'open callback' ? 1 : 0);
          }
        }
      },
    );
  }

  testWidgets(
    'member identity ABA during a hold preserves its draft without hidden entry',
    (tester) async {
      final identity = ValueNotifier('A');
      addTearDown(identity.dispose);
      final key = GlobalKey<_DraftProbeState>();
      await _mount(
        tester,
        child: ValueListenableBuilder<String>(
          valueListenable: identity,
          builder: (_, value, child) =>
              Semantics(label: 'Member $value', child: child),
          child: _DraftProbe(key: key),
        ),
      );
      key.currentState!.text.text = 'Keep this draft';
      final original = key.currentState;
      final finger = await tester.startGesture(
        tester.getBottomRight(_surface) - const Offset(8, 8),
      );
      await tester.pump(const Duration(seconds: 1));
      identity.value = 'B';
      await tester.pump();
      identity.value = 'A';
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await finger.up();
      _expectNoDeveloperEntry();
      expect(identical(key.currentState, original), isTrue);
      expect(key.currentState!.text.text, 'Keep this draft');
    },
  );

  testWidgets(
    'member action admission is checked at dispatch while long holds stay inert',
    (tester) async {
      var allowed = false, calls = 0;
      await _mount(
        tester,
        child: Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: ZyraTapFeedback.onTap(
              context,
              () => calls++,
              canAct: () => allowed,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
      var finger = await _press(tester);
      await tester.pump(const Duration(seconds: 2));
      await finger.up();
      expect(calls, 0);
      allowed = true;
      finger = await _press(tester);
      allowed = false;
      await tester.pump(const Duration(seconds: 3));
      await finger.up();
      expect(calls, 0);
      allowed = true;
      await tester.tap(_surface);
      await tester.pump();
      expect(calls, 1);
      _expectNoDeveloperEntry();
    },
  );

  testWidgets(
    'enabling a disabled member action during a press requires a fresh press',
    (tester) async {
      final enabled = ValueNotifier(false);
      addTearDown(enabled.dispose);
      var calls = 0;
      await _mount(
        tester,
        child: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (_, value, _) => TextButton(
            onPressed: value ? () => calls++ : null,
            child: const Text('Member action'),
          ),
        ),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(TextButton)),
      );
      enabled.value = true;
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await finger.up();
      expect(calls, 0);
      _expectNoDeveloperEntry();
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(calls, 1);
    },
  );

  for (final phase in ['start', 'completion']) {
    testWidgets(
      'authorization refresh exceptions at $phase leave member gestures safe',
      (tester) async {
        var taps = 0;
        await _mount(tester, child: _tapTarget(() => taps++));
        if (phase == 'start') await _failedRefresh(tester);
        final finger = await _press(tester);
        await tester.pump(const Duration(seconds: 2));
        if (phase == 'completion') await _failedRefresh(tester);
        await tester.pump(const Duration(seconds: 1));
        await finger.up();
        await tester.pump();
        expect(taps, 1);
        _expectNoDeveloperEntry();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final lifecycle in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  ]) {
    testWidgets(
      '$lifecycle and resume preserve member gestures without hidden holds',
      (tester) async {
        var taps = 0;
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _mount(tester, child: _tapTarget(() => taps++));
        final finger = await _press(tester);
        await tester.pump(const Duration(seconds: 1));
        tester.binding.handleAppLifecycleStateChanged(lifecycle);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(seconds: 3));
        await finger.cancel();
        _expectNoDeveloperEntry();
        await tester.tap(_surface);
        await tester.pump();
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'covered route and route ABA cannot expose developer hold entry',
    (tester) async {
      await _mount(tester);
      final finger = await _press(tester);
      await tester.pump(const Duration(seconds: 1));
      zyraNavigatorKey.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
      );
      await tester.pumpAndSettle();
      zyraNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await finger.up();
      _expectNoDeveloperEntry();
      await _hold(tester);
      expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
    },
  );

  testWidgets(
    'unmount during a long press leaves no developer deadline or callback',
    (tester) async {
      await _mount(tester);
      final finger = await _press(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      await finger.up();
      _expectNoDeveloperEntry();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'authority and member role changes preserve child state, draft and scroll',
    (tester) async {
      final key = GlobalKey<_DraftProbeState>();
      await _mount(tester, child: _DraftProbe(key: key));
      final original = key.currentState!;
      original.text.text = 'Keep this draft';
      original.scroll.jumpTo(120);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraLocalPrefs.setCachedRole('wali');
      await tester.pump();
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraLocalPrefs.setCachedRole('seeker');
      await tester.pump();
      expect(identical(key.currentState, original), isTrue);
      expect(key.currentState!.text.text, 'Keep this draft');
      expect(key.currentState!.scroll.offset, 120);
      _expectNoDeveloperEntry();
      expect(tester.takeException(), isNull);
    },
  );
}
