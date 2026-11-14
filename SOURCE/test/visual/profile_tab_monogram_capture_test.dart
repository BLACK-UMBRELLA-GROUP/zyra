// LOCK 21 V5: actual Founder Profile routes against the p11–p16 master sizes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_floating_surface.dart';

import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LOCK21_CAPTURE_OUTPUT');
final _ios = TargetPlatformVariant({TargetPlatform.iOS});
const _navKey = ValueKey('compact-nav-surface');

Finder _key(String id) => find.byKey(ValueKey(id));
Finder get _scroll => _key('concept-current-profile-scroll');

ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(of: _scroll, matching: find.byType(Scrollable)),
    )
    .position;

Finder _surface(String id) => find
    .ancestor(
      of: _key('concept_$id'),
      matching: find.byType(ZyraFloatingSurface),
    )
    .first;

BaselineHarness _harness(
  WidgetTester tester, {
  required String group,
  required bool compact,
  required bool masterInsets,
  double scale = 1,
}) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: group,
    outputRoot: _output,
    evidenceRoot: _output,
    flatOutput: true,
    logicalSize: compact ? const Size(375, 667) : const Size(430, 932),
    devicePixelRatio: compact ? 2 : 3,
    safePadding: EdgeInsets.only(
      top: compact ? 20 : 59,
      bottom: masterInsets ? 22 : (compact ? 0 : 34),
    ),
    textScale: scale,
  );
}

Future<void> _mount(
  BaselineHarness h, {
  required bool guardian,
  bool basic = false,
}) async {
  await h.mount(
    tab: 4,
    guardian: guardian,
    receivedRequest: false,
    seekerPhotos: const [],
    initialSeekerBasic: !guardian && basic,
    initialGuardianBasic: guardian && basic,
    seekerMembership: !guardian && basic ? 'Seeker Basic' : 'Seeker One',
    guardianMembership: guardian && basic ? 'Guardian Basic' : 'Guardian One',
  );
  if (!guardian) {
    final balance = basic ? 0 : 1;
    final fixture = h.shellFixture;
    expect(
      fixture.update(() {
        expect(fixture.compatibilityAccess!.setBalance(count: balance), isTrue);
      }),
      isTrue,
    );
    await h.flush();
    expect(find.text('$balance left'), findsOneWidget);
  }
}

Future<void> _capture(BaselineHarness h, String name) async {
  if (_output.isEmpty) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  void repaint(RenderObject node) {
    node.markNeedsPaint();
    node.visitChildren(repaint);
  }

  try {
    repaint(
      h.tester.renderObject(
        find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
      ),
    );
    await h.tester.pump();
    await h.capture(
      'profile',
      name,
      name,
      'Actual Founder Profile shell with the locked fixture data.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

void _verifyEndpoint(WidgetTester tester, Rect nav) {
  expect(tester.getRect(find.byKey(_navKey)), nav);
  expect(
    nav.top - tester.getBottomLeft(_surface('sign_out')).dy,
    closeTo(16, .02),
  );
  expect(_key('concept_sign_out').hitTestable(), findsOneWidget);
}

void _verifyCards(WidgetTester tester, bool guardian, double width) {
  final cards = [
    _surface(guardian ? 'your_seekers' : 'manage_photos'),
    _surface('membership'),
    _surface(guardian ? 'safety_advice' : 'guardian_info'),
    _surface('sign_out'),
  ].map(tester.getRect).toList();
  for (var index = 0; index < cards.length; index++) {
    expect(cards[index].left, closeTo(20, .02));
    expect(cards[index].right, closeTo(width - 20, .02));
    if (index > 0) {
      expect(cards[index].top - cards[index - 1].bottom, closeTo(12, .02));
    }
  }
}

Future<void> _verifyStill(BaselineHarness h, {required bool guardian}) async {
  final t = h.tester;
  final nav = t.getRect(find.byKey(_navKey));
  final position = _position(t);
  expect(position.maxScrollExtent, closeTo(0, .02));
  _verifyCards(t, guardian, h.logicalSize.width);
  _verifyEndpoint(t, nav);

  final rows = [
    guardian ? 'your_seekers' : 'manage_photos',
    'membership',
    if (!guardian) 'compatibility_buy_more',
    'subscriptions',
    if (!guardian) 'guardian_info',
    'safety_advice',
    'invite',
    'settings',
    'sign_out',
  ];
  final rowHeight = t.getSize(_key('concept_membership')).height;
  expect(rowHeight, greaterThan(44));
  for (final row in rows) {
    final extra = row == 'your_seekers' ? 3 : 0;
    expect(
      t.getSize(_key('concept_$row')).height,
      closeTo(rowHeight + extra, .02),
    );
  }

  final firstCard = _surface(guardian ? 'your_seekers' : 'manage_photos');
  final origin = t.getTopLeft(firstCard);
  for (final distance in [-80.0, 80.0]) {
    final drag = await t.startGesture(t.getCenter(firstCard));
    await drag.moveBy(Offset(0, distance / 2));
    await t.pump();
    await drag.moveBy(Offset(0, distance / 2));
    await t.pump();
    expect(t.getTopLeft(firstCard), origin);
    expect(position.pixels, closeTo(0, .02));
    await drag.up();
    await h.flush();
    _verifyEndpoint(t, nav);
  }
}

void main() {
  setUpAll(
    () => baselineSetUp(
      evidenceRoot: null,
      useSystemSymbolFont: Platform.isMacOS,
    ),
  );
  tearDownAll(baselineTearDown);

  const states = [
    (name: 'p11_seeker_one__one_screen', guardian: false, basic: false),
    (name: 'p12_seeker_basic__one_screen', guardian: false, basic: true),
    (name: 'p13_guardian_one__one_screen', guardian: true, basic: false),
    (name: 'p14_guardian_basic__one_screen', guardian: true, basic: true),
  ];
  for (final state in states) {
    testWidgets('LOCK 21 V5 ${state.name} fits and stays still', (t) async {
      final h = _harness(
        t,
        group: state.name,
        compact: false,
        masterInsets: true,
      );
      await _mount(h, guardian: state.guardian, basic: state.basic);
      await _verifyStill(h, guardian: state.guardian);
      await _capture(h, state.name);
    }, variant: _ios);

    testWidgets('LOCK 21 V5 ${state.name} fits iOS safe insets', (t) async {
      final h = _harness(
        t,
        group: state.name,
        compact: false,
        masterInsets: false,
      );
      await _mount(h, guardian: state.guardian, basic: state.basic);
      await _verifyStill(h, guardian: state.guardian);
    }, variant: _ios);
  }

  for (final guardian in [false, true]) {
    final name = guardian ? 'p16_guardian_one' : 'p15_seeker_one';
    testWidgets('LOCK 21 V5 $name reaches the compact master endpoint', (
      t,
    ) async {
      final h = _harness(t, group: name, compact: true, masterInsets: true);
      await _mount(h, guardian: guardian);
      _verifyCards(t, guardian, h.logicalSize.width);
      final position = _position(t);
      final nav = t.getRect(find.byKey(_navKey));
      expect(position.maxScrollExtent, greaterThan(0));
      expect(t.getBottomLeft(_scroll).dy, closeTo(nav.top, .02));
      await _capture(h, '${name}__small_phone_top');

      position.jumpTo(position.maxScrollExtent);
      await h.flush();
      _verifyEndpoint(t, nav);
      await _capture(h, '${name}__small_phone_end');
    }, variant: _ios);

    testWidgets('LOCK 21 V5 $name ends above the actual compact tab bar', (
      t,
    ) async {
      final h = _harness(t, group: name, compact: true, masterInsets: false);
      await _mount(h, guardian: guardian);
      final position = _position(t);
      final nav = t.getRect(find.byKey(_navKey));
      if (!guardian) expect(position.maxScrollExtent, greaterThan(0));
      position.jumpTo(position.maxScrollExtent);
      await h.flush();
      _verifyEndpoint(t, nav);
    }, variant: _ios);

    final large = guardian ? 'guardian_large_text' : 'seeker_large_text';
    testWidgets('LOCK 21 V5 $large reaches Sign out', (t) async {
      final h = _harness(
        t,
        group: large,
        compact: true,
        masterInsets: false,
        scale: 2,
      );
      await _mount(h, guardian: guardian);
      final position = _position(t);
      final nav = t.getRect(find.byKey(_navKey));
      expect(position.maxScrollExtent, greaterThan(0));
      await _capture(h, '${large}__top');
      position.jumpTo(position.maxScrollExtent);
      await h.flush();
      _verifyEndpoint(t, nav);
      await _capture(h, '${large}__last');
    }, variant: _ios);
  }
}
