import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_circle_send_button_presentation.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final scenario = ZyraDevScenario.instance;

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    scenario.reset();
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    scenario.reset();
    ZyraAccountState.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  Widget circle({ValueChanged<ZyraFamilyMessageContext>? onOpenContext}) =>
      MaterialApp(
        home: ZyraGuardianCircleScreen(
          seekerId: 'dev-seeker-aaliyah',
          seekerFirstName: 'Aaliyah',
          preview: true,
          onOpenContext: onOpenContext,
        ),
      );

  Future<void> mountCircle(
    WidgetTester tester, {
    ValueChanged<ZyraFamilyMessageContext>? onOpenContext,
  }) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(circle(onOpenContext: onOpenContext));
    await tester.pumpAndSettle();
    expect(find.text('Guardian Circle'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  }

  testWidgets('raw Circle preview request cannot create Developer Access', (
    tester,
  ) async {
    await tester.pumpWidget(circle());
    await tester.pumpAndSettle();
    expect(find.text('Guardian Circle'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Assalaamu alaikum.'), findsNothing);
    // An unauthorized opened route cannot become a preview later.
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('raw inbox preview request cannot seed sample Circles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ZyraGuardianCirclesInboxScreen(preview: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aaliyah’s Guardian Circle'), findsNothing);
    expect(find.text('Let me know when you are ready to talk.'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'stale context/send callbacks and delayed local send are denied',
    (tester) async {
      var opened = 0;
      await mountCircle(tester, onOpenContext: (_) => opened++);
      final oldContext = tester
          .widget<InkWell>(
            find.byKey(const ValueKey('open-message-context-dev-active-h')),
          )
          .onTap!;
      final oldSend = tester
          .widget<ZyraCircleSendButton>(find.byType(ZyraCircleSendButton))
          .onSend!;
      final oldReaders = tester
          .widget<InkWell>(find.byKey(const ValueKey('message-read-receipt')))
          .onTap!;
      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      await tester.enterText(
        find.byType(TextField),
        'Never publish this later',
      );
      oldSend(); // The fixture's delayed 120ms completion is now outstanding.
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(controller.text, isEmpty);
      oldContext();
      oldSend();
      oldReaders();
      await tester.pump(const Duration(milliseconds: 160));
      expect(opened, 0);
      expect(find.text('Never publish this later'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const ValueKey('message-readers-sheet')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'switch-to-live withdraws preview without starting live messaging',
    (tester) async {
      await mountCircle(tester);
      scenario.setUseLiveGuardianData(true);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Guardian Circle'), findsNothing);
      scenario.setUseLiveGuardianData(false);
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('retained selected-person chip denies after context withdrawal', (
    tester,
  ) async {
    var opened = 0;
    await mountCircle(tester, onOpenContext: (_) => opened++);
    await tester.tap(find.byTooltip('Discuss someone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potential'));
    await tester.pumpAndSettle();
    final oldSelected = tester
        .widget<InkWell>(
          find.byKey(const ValueKey('open-message-context-dev-potential-m')),
        )
        .onTap!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    oldSelected();
    await tester.pumpAndSettle();
    expect(opened, 0);
    expect(find.text('M.'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final sheet in ['members', 'readers', 'context']) {
    testWidgets('an opened $sheet sheet clears on authorization revocation', (
      tester,
    ) async {
      await mountCircle(tester);
      if (sheet == 'members') {
        await tester.tap(find.byKey(const ValueKey('circle_header_members')));
      } else if (sheet == 'readers') {
        await tester.tap(find.byKey(const ValueKey('message-read-receipt')));
      } else {
        await tester.tap(find.byTooltip('Discuss someone'));
      }
      await tester.pumpAndSettle();
      expect(
        find.text(
          sheet == 'members'
              ? 'Circle members'
              : sheet == 'readers'
              ? 'Read by'
              : 'Discuss someone',
        ),
        findsOneWidget,
      );
      // Revocation followed by restored authority before a frame cannot
      // resurrect a sheet or its old requested-preview route.
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpAndSettle();
      expect(find.text('Circle members'), findsNothing);
      expect(find.text('Read by'), findsNothing);
      expect(find.text('ACTIVE JOURNEYS'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('account generation clears an already-open readers sheet', (
    tester,
  ) async {
    await mountCircle(tester);
    await tester.tap(find.byKey(const ValueKey('message-read-receipt')));
    await tester.pumpAndSettle();
    expect(find.text('Read by'), findsOneWidget);
    ZyraAccountState.resetForTesting();
    // Account synchronization resets the scenario in production; mirror the
    // same notification after changing the synthetic generation here.
    scenario.reset();
    await tester.pumpAndSettle();
    expect(find.text('Read by'), findsNothing);
    expect(find.textContaining('Additional Guardian'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('revocation removes only the stale Circle route', (tester) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Unaffected owner route')),
      ),
    );
    navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const ZyraGuardianCircleScreen(
          seekerId: 'dev-seeker-aaliyah',
          seekerFirstName: 'Aaliyah',
          preview: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Unrelated top route')),
      ),
    );
    await tester.pumpAndSettle();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(find.text('Unrelated top route'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Unaffected owner route'), findsOneWidget);
    expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final sheet in ['members', 'readers']) {
    testWidgets('removing the Circle owner withdraws its open $sheet sheet', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Owner removed safely')),
        ),
      );
      final owner = MaterialPageRoute<void>(
        builder: (_) => const ZyraGuardianCircleScreen(
          seekerId: 'dev-seeker-aaliyah',
          seekerFirstName: 'Aaliyah',
          preview: true,
        ),
      );
      navigator.currentState!.push(owner);
      await tester.pumpAndSettle();
      final oldSend = tester
          .widget<ZyraCircleSendButton>(find.byType(ZyraCircleSendButton))
          .onSend!;
      final oldDiscuss = tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Discuss someone'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed!;
      await tester.tap(
        sheet == 'members'
            ? find.byKey(const ValueKey('circle_header_members'))
            : find.byKey(const ValueKey('message-read-receipt')),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.removeRoute(owner);
      await tester.pumpAndSettle();
      oldSend();
      oldDiscuss();
      await tester.pump();
      expect(find.text('Circle members'), findsNothing);
      expect(find.text('Read by'), findsNothing);
      expect(find.text('Owner removed safely'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
