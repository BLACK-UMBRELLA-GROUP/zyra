// LOCK22 V1: catalogue, local paging and caller ownership without purchases.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

Finder _key(String id) => find.byKey(ValueKey('draft_compatibility_store_$id'));
Future<void> _mount(
  WidgetTester t, {
  int? balance = 1,
  bool one = true,
  Size size = const Size(430, 932),
  double scale = 1,
  bool Function()? canAct,
  VoidCallback? onTerms,
  bool unbounded = false,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  Widget child = ZyraDraftCompatibilityStorePresentation(
    balance: balance,
    isSeekerOne: one,
    canAct: canAct,
    onTerms: onTerms,
  );
  if (unbounded) child = SingleChildScrollView(child: child);
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

Future<void> _tap(WidgetTester t, String id) async {
  await t.ensureVisible(_key(id));
  await t.pumpAndSettle();
  await t.tap(_key(id));
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

bool _selected(WidgetTester t, String id) =>
    t.widget<Semantics>(_key('${id}_selection')).properties.selected!;
void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
  });
  for (final balance in [0, 1, 5]) {
    for (final one in [false, true]) {
      testWidgets(
        'balance $balance and membership One=$one, default three and catalog prices',
        (t) async {
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await _mount(t, balance: balance, one: one);
          expect(find.text('$balance'), findsOneWidget);
          expect(
            find.text(balance == 1 ? 'Unlock left' : 'Unlocks left'),
            findsOneWidget,
          );
          expect(
            find.text(
              one
                  ? '3 MORE EACH MONTH WITH SEEKER ONE'
                  : 'SEEKER ONE INCLUDES 3 EACH MONTH',
            ),
            findsOneWidget,
          );
          expect(find.text('Unlocks remaining'), findsNothing);
          expect(_key('info'), findsNothing);
          expect(_selected(t, 'unlock_three'), isTrue);
          for (final price in ['£2.99', '£6.99', '£9.99']) {
            expect(find.text(price), findsOneWidget);
          }
          for (final id in ['unlock_single', 'unlock_five', 'unlock_three']) {
            await _tap(t, id);
            expect(_selected(t, id), isTrue);
            expect(t.widget<FilledButton>(_key('continue')).onPressed, isNull);
          }
        },
      );
    }
  }
  testWidgets('unconfirmed balance does not claim zero Unlocks', (t) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await _mount(t, balance: null);
    expect(_key('balance_count'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('Unlocks left'), findsNothing);
    expect(find.text('£6.99'), findsOneWidget);
  });
  testWidgets('all eight retained included examples, forward and backward', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await _mount(t);
    expect(find.text('Your match, revealed'), findsOneWidget);
    expect(find.text('One profile. Every score.'), findsOneWidget);
    for (var i = 1; i <= 8; i++) {
      expect(find.text('$i / 8'), findsOneWidget);
      if (i < 8) await _tap(t, 'preview_next');
    }
    expect(t.widget<IconButton>(_key('preview_next')).onPressed, isNull);
    for (var i = 8; i > 1; i--) {
      await _tap(t, 'preview_previous');
    }
    expect(find.text('1 / 8'), findsOneWidget);
    expect(t.widget<IconButton>(_key('preview_previous')).onPressed, isNull);
  });
  testWidgets(
    'owner revoked: retained pack, page and terms callbacks have no haptics or effect',
    (t) async {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var allowed = true, terms = 0, haptics = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') haptics++;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await _mount(t, canAct: () => allowed, onTerms: () => terms++);
      final pack = t.widget<OutlinedButton>(_key('unlock_single')).onPressed!;
      final page = t.widget<IconButton>(_key('preview_next')).onPressed!;
      final term = t.widget<TextButton>(_key('terms')).onPressed!;
      allowed = false;
      pack();
      page();
      term();
      await t.pumpAndSettle();
      expect(_selected(t, 'unlock_three'), isTrue);
      expect(find.text('1 / 8'), findsOneWidget);
      expect(terms, 0);
      expect(haptics, 0);
      allowed = true;
      await _tap(t, 'terms');
      expect(terms, 1);
      await t.pumpWidget(const SizedBox.shrink());
      pack();
      page();
      term();
      expect(haptics, 1);
    },
  );
  testWidgets('old pack delegate cannot replay after fresh selection', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await _mount(t);
    final stale = t.widget<OutlinedButton>(_key('unlock_single')).onPressed!;
    await _tap(t, 'unlock_five');
    stale();
    await t.pumpAndSettle();
    expect(_selected(t, 'unlock_five'), isTrue);
  });
  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(852, 393),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('reachable packs, pager and terms at $size text$scale', (
        t,
      ) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await _mount(t, size: size, scale: scale, onTerms: () {});
        for (final id in [
          'unlock_single',
          'unlock_three',
          'unlock_five',
          'preview_next',
          'terms',
        ]) {
          await _tap(t, id);
          final rect = t.getRect(_key(id));
          expect(rect.width, greaterThanOrEqualTo(44));
          expect(rect.height, greaterThanOrEqualTo(44));
        }
      });
    }
  }
  testWidgets('unbounded membership embed scrolls its natural content', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await _mount(t, unbounded: true, scale: 2, onTerms: () {});
    await _tap(t, 'terms');
    expect(t.takeException(), isNull);
  });
}
