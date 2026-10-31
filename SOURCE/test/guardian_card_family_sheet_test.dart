import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_family_sheet.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _introPrimary => _key('guardian-family-introduction-primary');
Finder get _pricePrimary => _key('guardian-family-price-primary');
Finder get _invitedPrimary => _key('guardian-family-invited-primary');
Finder get _invitedCancel => _key('guardian-family-invited-secondary');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('The Guardian Family sheet must remain local.');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  var allowed = true;
  var invites = 0;
  var cancellations = 0;
  var closes = 0;
  final callbackOrder = <String>[];

  setUp(() {
    allowed = true;
    invites = 0;
    cancellations = 0;
    closes = 0;
    calls.clear();
    callbackOrder.clear();
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = false;
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> mount(
    WidgetTester tester, {
    ZyraGuardianFamilyState familyState = ZyraGuardianFamilyState.noFamily,
    bool invited = false,
    String guardianName = 'Ibrahim',
    double textScale = 1,
    Size size = const Size(430, 932),
    int seekers = 1,
    int guardians = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ZyraGuardianFamilySheet(
                guardianName: guardianName,
                canAct: () => allowed,
                invited: invited,
                familyState: familyState,
                seekers: seekers,
                guardians: guardians,
                onInvite: () {
                  invites++;
                  callbackOrder.add('invite');
                },
                onCancelInvite: () {
                  cancellations++;
                  callbackOrder.add('cancel');
                },
                onClose: () {
                  closes++;
                  callbackOrder.add('close');
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  VoidCallback retainedPrimary(WidgetTester tester, Finder finder) =>
      tester.widget<FilledButton>(finder).onPressed!;

  VoidCallback retainedSecondary(WidgetTester tester, Finder finder) =>
      tester.widget<TextButton>(finder).onPressed!;

  int hapticCount() =>
      calls.where((call) => call.method == 'HapticFeedback.vibrate').length;

  test('Family prices use the existing catalogue formula', () {
    expect(ZyraMembershipCatalog.familyQuote(1, 1).formulaMonthlyPence, 4998);
    expect(ZyraMembershipCatalog.familyQuote(1, 2).formulaMonthlyPence, 6647);
  });

  testWidgets('No Family introduction keeps the locked Guardian Basic text', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('Ibrahim can view, but not chat'), findsOneWidget);
    expect(find.text('Ibrahim is on Guardian Basic'), findsOneWidget);
    expect(find.text('Pay for Ibrahim with ZYRA Family'), findsOneWidget);
    expect(
      find.text(
        'See the Journeys you let them view, follow each stage, and read '
        'your Guardian Circle.',
      ),
      findsOneWidget,
    );
    expect(find.text('See the price'), findsOneWidget);
    expect(invites, 0);
  });

  testWidgets('No Family price is the current membership and two places', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(_introPrimary);
    await tester.pump();
    expect(find.text('Cover Ibrahim with ZYRA Family'), findsOneWidget);
    expect(find.text('Now · Your membership'), findsOneWidget);
    expect(find.text('New · ZYRA Family · 2 places'), findsOneWidget);
    expect(find.text('£29.99 a month'), findsOneWidget);
    expect(find.text('£49.98 a month'), findsOneWidget);
    expect(invites, 0);
    await tester.tap(_key('guardian-family-price-secondary'));
    await tester.pump();
    expect(find.text('See the price'), findsOneWidget);
  });

  testWidgets('Full Family adds one Guardian using the existing composition', (
    tester,
  ) async {
    await mount(tester, familyState: ZyraGuardianFamilyState.full);
    expect(find.text('Add a Guardian place for Ibrahim'), findsOneWidget);
    expect(find.text('Add a place'), findsOneWidget);
    await tester.tap(_introPrimary);
    await tester.pump();
    expect(find.text('Now · ZYRA Family · 2 places'), findsOneWidget);
    expect(find.text('New · ZYRA Family · 3 places'), findsOneWidget);
    expect(find.text('£49.98 a month'), findsOneWidget);
    expect(find.text('£66.47 a month'), findsOneWidget);
    expect(find.textContaining('You keep Seeker One'), findsNothing);
  });

  testWidgets('Full Family formula follows caller place counts', (
    tester,
  ) async {
    await mount(
      tester,
      familyState: ZyraGuardianFamilyState.full,
      seekers: 2,
      guardians: 2,
    );
    await tester.tap(_introPrimary);
    await tester.pump();
    expect(find.text('Now · ZYRA Family · 4 places'), findsOneWidget);
    expect(find.text('New · ZYRA Family · 5 places'), findsOneWidget);
    expect(
      find.text(
        '${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.familyQuote(2, 3).formulaMonthlyPence)} a month',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Free place sends a local invite directly without a price step', (
    tester,
  ) async {
    await mount(tester, familyState: ZyraGuardianFamilyState.freePlace);
    expect(find.text('Give Ibrahim your free Guardian place'), findsOneWidget);
    expect(find.text('Give Ibrahim the place'), findsOneWidget);
    await tester.tap(_introPrimary);
    await tester.pump();
    expect(invites, 1);
    expect(find.text('Invite sent to Ibrahim'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Then you choose Chat'), findsOneWidget);
  });

  testWidgets('Continue sends once and Done only closes', (tester) async {
    await mount(tester);
    await tester.tap(_introPrimary);
    await tester.pump();
    final continueCallback = retainedPrimary(tester, _pricePrimary);
    continueCallback();
    continueCallback();
    await tester.pump();
    expect(invites, 1);
    expect(find.text('Invite sent to Ibrahim'), findsOneWidget);
    final done = retainedPrimary(tester, _invitedPrimary);
    done();
    done();
    await tester.pump();
    expect(closes, 1);
    expect(cancellations, 0);
    expect(callbackOrder, ['invite', 'close']);
  });

  testWidgets('Existing invite opens sent state and Cancel withdraws once', (
    tester,
  ) async {
    await mount(tester, invited: true);
    expect(find.text('Invite sent to Ibrahim'), findsOneWidget);
    expect(find.text('See the price'), findsNothing);
    final cancel = retainedSecondary(tester, _invitedCancel);
    cancel();
    final count = hapticCount();
    cancel();
    await tester.pump();
    expect(cancellations, 1);
    expect(closes, 1);
    expect(invites, 0);
    expect(callbackOrder, ['cancel', 'close']);
    expect(hapticCount(), count);
  });

  testWidgets('Not now closes without creating an invite', (tester) async {
    await mount(tester);
    await tester.tap(_key('guardian-family-introduction-secondary'));
    await tester.pump();
    expect(closes, 1);
    expect(invites, 0);
    expect(cancellations, 0);
  });

  testWidgets('Denied retained callback has no haptic or local mutation', (
    tester,
  ) async {
    await mount(tester, familyState: ZyraGuardianFamilyState.freePlace);
    final send = retainedPrimary(tester, _introPrimary);
    allowed = false;
    send();
    allowed = true;
    send();
    await tester.pump();
    expect(invites, 0);
    expect(hapticCount(), 0);
    expect(find.text('Give Ibrahim the place'), findsOneWidget);
  });

  testWidgets(
    'Semantic activation checks authority before invite and haptics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mount(tester, familyState: ZyraGuardianFamilyState.freePlace);
      final node = tester.getSemantics(_introPrimary);
      final owner = tester
          .element(_introPrimary)
          .renderObject!
          .owner!
          .semanticsOwner!;
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      allowed = false;
      owner.performAction(node.id, ui.SemanticsAction.tap);
      allowed = true;
      owner.performAction(node.id, ui.SemanticsAction.tap);
      await tester.pump();
      expect(invites, 0);
      expect(hapticCount(), 0);
      expect(find.text('Give Ibrahim the place'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('Step changes invalidate retained handles before haptics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mount(tester);
    final introduction = retainedPrimary(tester, _introPrimary);
    introduction();
    await tester.pump();
    final back = retainedSecondary(
      tester,
      _key('guardian-family-price-secondary'),
    );
    final send = retainedPrimary(tester, _pricePrimary);
    send();
    await tester.pump();
    final count = hapticCount();
    introduction();
    back();
    send();
    await tester.pump();
    expect(invites, 1);
    expect(closes, 0);
    expect(hapticCount(), count);
    expect(find.text('Invite sent to Ibrahim'), findsOneWidget);
    expect(
      tester.getSemantics(_invitedPrimary).getSemanticsData().label,
      contains('Done'),
    );
    semantics.dispose();
  });

  testWidgets('Guardian input replacement invalidates retained handlers', (
    tester,
  ) async {
    await mount(tester, familyState: ZyraGuardianFamilyState.freePlace);
    final oldSend = retainedPrimary(tester, _introPrimary);
    await mount(
      tester,
      guardianName: 'Omar',
      familyState: ZyraGuardianFamilyState.freePlace,
    );
    oldSend();
    await tester.pump();
    expect(invites, 0);
    expect(hapticCount(), 0);
    expect(find.text('Omar can view, but not chat'), findsOneWidget);
  });

  testWidgets('Local invite display follows refreshed caller input', (
    tester,
  ) async {
    await mount(tester);
    await mount(tester, invited: true);
    expect(find.text('Invite sent to Ibrahim'), findsOneWidget);
    await mount(tester, invited: false);
    expect(find.text('See the price'), findsOneWidget);
  });

  testWidgets('320 width and 200 percent text scroll through every step', (
    tester,
  ) async {
    await mount(tester, size: const Size(320, 640), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(_introPrimary);
    await tester.tap(_introPrimary);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('£49.98 a month'), findsOneWidget);
    await tester.ensureVisible(_pricePrimary);
    await tester.tap(_pricePrimary);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(_invitedCancel);
    await tester.tap(_invitedCancel);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(invites, 1);
    expect(cancellations, 1);
    expect(closes, 1);
  });
}
