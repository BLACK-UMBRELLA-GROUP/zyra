import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_guardian_before_pay_preview.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_purchase_fine_print.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  test('purchase copy takes every amount from the governed catalogue', () {
    expect(
      ZyraPurchaseFinePrint.copyFor(ZyraPurchaseOffer.seekerOne),
      contains(
        ZyraMembershipCatalog.pounds(
          ZyraMembershipCatalog.seekerOneMonthlyPence,
        ),
      ),
    );
    expect(
      ZyraPurchaseFinePrint.copyFor(ZyraPurchaseOffer.guardianOne),
      contains('14 days free, then £19.99'),
    );
    expect(
      ZyraPurchaseFinePrint.copyFor(ZyraPurchaseOffer.seekerBasic),
      contains(
        ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.basicJoiningPence),
      ),
    );
    expect(
      ZyraPurchaseFinePrint.copyFor(
        ZyraPurchaseOffer.zyraFamily,
        familyMonthlyPence: 4998,
      ),
      startsWith('£49.98 a month'),
    );
  });

  testWidgets('purchase links are preview notices and Unlocks omit Restore', (
    tester,
  ) async {
    final notices = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraPurchaseFinePrint(
            offer: ZyraPurchaseOffer.seekerOne,
            onNotice: notices.add,
          ),
        ),
      ),
    );
    for (final label in [
      'Terms of use',
      'Privacy policy',
      'Restore purchases',
    ]) {
      await tester.tap(find.text(label));
    }
    expect(find.text('·'), findsNWidgets(2));
    expect(notices, [
      ZyraPurchaseFinePrint.termsNotice,
      ZyraPurchaseFinePrint.privacyNotice,
      ZyraPurchaseFinePrint.restoreNotice,
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraPurchaseFinePrint(
            offer: ZyraPurchaseOffer.compatibilityUnlocks,
            onNotice: notices.add,
          ),
        ),
      ),
    );
    expect(find.text('Restore purchases'), findsNothing);
    expect(find.text('·'), findsOneWidget);
  });

  testWidgets('compact links keep each separator with its following action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const ZyraPurchaseFinePrint(
              offer: ZyraPurchaseOffer.seekerOne,
            ),
          ),
        ),
      ),
    );
    final dots = find.text('·');
    expect(dots, findsNWidgets(2));
    for (final (index, label) in [
      (0, 'Privacy policy'),
      (1, 'Restore purchases'),
    ]) {
      final dot = tester.getRect(dots.at(index));
      final link = tester.getRect(find.text(label));
      expect((dot.center.dy - link.center.dy).abs(), lessThan(8));
      expect(dot.right, lessThan(link.left));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guardian explanation requires the tick before Apple notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notices = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraGuardianBeforePayPreview(
          seekerFirstName: 'Sara',
          canAct: () => true,
          onNotice: notices.add,
        ),
      ),
    );
    expect(find.text('I understand Sara decides.'), findsOneWidget);
    FilledButton button() => tester.widget<FilledButton>(
      find.byKey(const ValueKey('guardian-before-pay-continue')),
    );
    expect(button().onPressed, isNull);
    await tester.tap(
      find.byKey(const ValueKey('guardian-before-pay-understand')),
    );
    await tester.pump();
    expect(button().onPressed, isNotNull);
    await tester.tap(
      find.byKey(const ValueKey('guardian-before-pay-continue')),
    );
    expect(notices, [ZyraPurchaseFinePrint.appleNotice]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guardian plan opens the explanation without starting payment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraOneUpgradePage(
            guardian: true,
            founderPreview: true,
            seekerFirstName: 'Sara',
            canContinue: () => true,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('one-upgrade-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Before you pay'), findsOneWidget);
    expect(find.text('I understand Sara decides.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unlocks keeps checkout detached but shows its new disclosure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notices = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraDraftCompatibilityStorePresentation(
            balance: 1,
            founderPreview: true,
            canAct: () => true,
            onPurchaseNotice: notices.add,
          ),
        ),
      ),
    );
    expect(
      find.text('Charged once to your Apple ID. Not a subscription.'),
      findsOneWidget,
    );
    expect(find.text('Restore purchases'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('draft_compatibility_store_continue')),
    );
    expect(notices, ["Purchasing isn't available yet."]);
    expect(tester.takeException(), isNull);
  });
}
