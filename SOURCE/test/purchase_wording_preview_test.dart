import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_guardian_before_pay_preview.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_family_sheet.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
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

  testWidgets('LOCK51 purchase links open the reader, Restore stays a notice', (
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
    await _legalLinks(tester);
    expect(find.text('·'), findsNWidgets(2));
    await tester.tap(find.text('Restore purchases'));
    expect(notices, [ZyraPurchaseFinePrint.restoreNotice]);
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
    await _legalLinks(tester);
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
    await _legalLinks(tester);
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
    await _legalLinks(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seeker One plan disclosure opens both legal pages', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraOneUpgradePage(
            guardian: false,
            founderPreview: true,
            canContinue: () => true,
            onBack: () {},
          ),
        ),
      ),
    );
    await _legalLinks(tester);
    expect(find.byKey(const ValueKey('one-upgrade-continue')), findsOneWidget);
  });

  testWidgets(
    'Family price sheet opens both legal pages and resumes its price',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (sheetContext) => ZyraGuardianFamilySheet(
                    guardianName: 'Hassan',
                    canAct: () =>
                        ModalRoute.of(sheetContext)?.isCurrent == true,
                    canRetainLegal: () =>
                        ModalRoute.of(sheetContext)?.isActive == true,
                    invited: false,
                    onInvite: () {},
                    onCancelInvite: () {},
                    onClose: () => Navigator.of(sheetContext).pop(),
                  ),
                ),
                child: const Text('Family sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Family sheet'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('guardian-family-introduction-primary')),
      );
      await tester.pumpAndSettle();
      await _legalLinks(tester);
      expect(
        find.byKey(const ValueKey('guardian-family-price-primary')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final basic in [false, true]) {
    testWidgets(
      'Sign-up $basic legal links have the signed-out support notice',
      (tester) async {
        _phone(tester);
        final controller = ZyraSignupPreviewController()
          ..seedSetup(guardian: false, verified: true)
          ..setMembershipBasic(basic)
          ..setStep(ZyraSignupStep.membership);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ZyraSignupPreview(
                controller: controller,
                canAct: () => true,
                preferencesBuilder: (_) => const SizedBox.shrink(),
                onPause: () {},
                onEnter: () {},
                onShareCode: () {},
                samplePhotos: const [],
                ownCode: '',
              ),
            ),
          ),
        );
        await _legalLinks(tester);
        await tester.tap(find.byKey(const ValueKey('purchase-terms-of-use')));
        await tester.pumpAndSettle();
        final contact = find.byKey(const ValueKey('legal_contact'));
        await tester.ensureVisible(contact);
        await tester.tap(contact);
        await tester.pumpAndSettle();
        expect(
          find.text('Opens the support form — no sign-in needed.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('help_safety_contact')), findsNothing);
      },
    );
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _legalLinks(WidgetTester tester) async {
  for (final (label, id) in [
    ('terms-of-use', 'terms'),
    ('privacy-policy', 'privacy'),
  ]) {
    final link = find.byKey(ValueKey('purchase-$label'));
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('legal_reader_$id')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(link, findsOneWidget);
  }
}
