// OA-ZYRA-325: removing Home must leave member routes and drafts intact.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart' show zyraNavigatorKey;
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'support/queue44_removed_controls_fixture.dart';

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });
  tearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
  Future<TextEditingController> mount(
    WidgetTester t, {
    bool allowed = true,
  }) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(allowed);
    final draft = TextEditingController(text: 'Member draft');
    addTearDown(draft.dispose);
    await t.pumpWidget(
      Queue44MemberFrame(
        child: Scaffold(body: TextField(controller: draft)),
      ),
    );
    await t.pumpAndSettle();
    expectQueue44ControlsAbsent();
    return draft;
  }

  testWidgets('absent Home never refreshes without authority', (t) async {
    final draft = await mount(t, allowed: false);
    await holdQueue44MemberPage(t);
    expect(draft.text, 'Member draft');
    expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
  });
  testWidgets('disposing a member route cannot resurrect Home', (t) async {
    await mount(t);
    final finger = await t.startGesture(const Offset(80, 40));
    await t.pump(const Duration(seconds: 1));
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 4));
    await finger.up();
    await t.pump();
    expectQueue44ControlsAbsent();
    expect(t.takeException(), isNull);
  });
  testWidgets('account generation changes cannot restore Home during a hold', (
    t,
  ) async {
    final draft = await mount(t);
    final finger = await t.startGesture(const Offset(80, 40));
    ZyraAccountState.resetForTesting();
    await t.pump(const Duration(seconds: 4));
    await finger.up();
    await t.pump();
    expectQueue44ControlsAbsent();
    expect(draft.text, 'Member draft');
  });
  testWidgets('covering the current owner cannot restore Home', (t) async {
    final draft = await mount(t);
    zyraNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Covered')),
      ),
    );
    await t.pumpAndSettle();
    await holdQueue44MemberPage(t);
    expect(find.text('Covered'), findsOneWidget);
    expect(draft.text, 'Member draft');
  });
  for (final nested in [true, false]) {
    testWidgets(
      '${nested ? 'nested' : 'outer'} member navigation has no Home entry or mutation',
      (t) async {
        final draft = await mount(t);
        if (nested) {
          zyraNavigatorKey.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Nested member page')),
            ),
          );
          await t.pumpAndSettle();
        }
        await holdQueue44MemberPage(t);
        expect(draft.text, 'Member draft');
        expect(zyraNavigatorKey.currentState!.canPop(), nested);
      },
    );
  }
  testWidgets('revoked Founder proof cannot restore Home', (t) async {
    await mount(t);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await t.pump();
    await holdQueue44MemberPage(t);
    expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
  });
  testWidgets('two held gestures create no Home route', (t) async {
    await mount(t);
    await holdQueue44MemberPage(t);
    await holdQueue44MemberPage(t);
    expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
  });
  testWidgets('a route-less app frame has no Home action', (t) async {
    BuildContext? outer;
    await t.pumpWidget(
      Builder(
        builder: (context) {
          outer = context;
          return const Queue44MemberFrame(
            child: Scaffold(body: Text('Member entry remains')),
          );
        },
      ),
    );
    await t.pumpAndSettle();
    expect(ModalRoute.of(outer!), isNull);
    await holdQueue44MemberPage(t);
    expect(find.text('Member entry remains'), findsOneWidget);
    expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
  });
  testWidgets('covered and replaced member pages cannot revive Home', (
    t,
  ) async {
    final draft = await mount(t);
    zyraNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Cover')),
      ),
    );
    await t.pumpAndSettle();
    zyraNavigatorKey.currentState!.pop();
    await t.pumpAndSettle();
    await holdQueue44MemberPage(t);
    expect(draft.text, 'Member draft');
    expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
  });
}
