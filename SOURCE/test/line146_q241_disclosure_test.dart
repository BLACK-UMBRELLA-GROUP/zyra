import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_purchase_fine_print.dart';

import 'visual/baseline_capture_support.dart';

const _existingInk = Color(0xFF6E6257);
const _legalInk = Color(0xFF845F24);

String _oneCopy(bool guardian) =>
    '14 days free, then ${ZyraMembershipCatalog.pounds(guardian ? ZyraMembershipCatalog.guardianOneMonthlyPence : ZyraMembershipCatalog.seekerOneMonthlyPence)}'
    ' a month, renewing monthly until you cancel. Cancel at least 24 '
    'hours before it renews, in Apple settings. One free trial per person.';

void _expectFinePrint(
  WidgetTester tester, {
  required ZyraPurchaseOffer offer,
  required Color ink,
  int? familyMonthlyPence,
}) {
  final finePrint = find.byType(ZyraPurchaseFinePrint);
  expect(finePrint, findsOneWidget);
  final widget = tester.widget<ZyraPurchaseFinePrint>(finePrint);
  expect(widget.offer, offer);
  final copy = ZyraPurchaseFinePrint.copyFor(
    offer,
    familyMonthlyPence: familyMonthlyPence,
  );
  final paragraph = tester.widget<Text>(
    find.descendant(of: finePrint, matching: find.text(copy)),
  );
  expect(paragraph.style?.fontSize, 11.5);
  expect(paragraph.style?.color, ink);
  expect(paragraph.textAlign, TextAlign.center);
  for (final label in [
    'Terms of use',
    'Privacy policy',
    if (offer != ZyraPurchaseOffer.compatibilityUnlocks) 'Restore purchases',
  ]) {
    final link = tester.widget<Text>(
      find.descendant(of: finePrint, matching: find.text(label)),
    );
    expect(link.style?.color, _legalInk, reason: label);
    expect(link.style?.fontSize, 12, reason: label);
  }
  for (final dot in tester.widgetList<Text>(
    find.descendant(of: finePrint, matching: find.text('·')),
  )) {
    expect(dot.style?.color, _legalInk);
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    final offer = guardian
        ? ZyraPurchaseOffer.guardianOne
        : ZyraPurchaseOffer.seekerOne;

    testWidgets(
      'Q241 actual $role Basic comparison changes only disclosure ink',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = BaselineHarness(tester, group: 'line146_q241');
        await harness.mount(
          guardian: guardian,
          tab: 4,
          initialSeekerBasic: !guardian,
          initialGuardianBasic: guardian,
          seekerMembership: guardian ? 'Seeker One' : 'Seeker Basic',
          guardianMembership: guardian ? 'Guardian Basic' : 'Guardian One',
        );
        await harness.tap('concept_membership');
        harness.assertPage('one_upgrade');
        final page = tester.widget<ZyraOneUpgradePage>(
          find.byType(ZyraOneUpgradePage),
        );
        expect(page.strongBasicComparisonDisclosure, isTrue);
        expect(find.text(_oneCopy(guardian)), findsOneWidget);
        expect(find.text('Start 14 days free'), findsOneWidget);
        expect(find.text('Not now'), findsOneWidget);
        _expectFinePrint(
          tester,
          offer: offer,
          ink: ZyraColors.strongSecondaryText,
        );
        if (guardian) {
          await harness.tap('one-upgrade-continue');
          await tester.pumpAndSettle();
          expect(find.text('Before you pay'), findsOneWidget);
          _expectFinePrint(tester, offer: offer, ink: _existingInk);
          expect(
            tester
                .widget<ZyraPurchaseFinePrint>(
                  find.byType(ZyraPurchaseFinePrint),
                )
                .disclosureColor,
            isNull,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Q241 actual $role One ownership keeps disclosure default', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = BaselineHarness(tester, group: 'line146_q241');
      await harness.mount(
        guardian: guardian,
        tab: 4,
        seekerMembership: 'Seeker One',
        guardianMembership: 'Guardian One',
      );
      await harness.tap('concept_membership');
      harness.assertPage('membership');
      await harness.tap('membership_more_compare');
      harness.assertPage('one_upgrade');
      expect(
        tester
            .widget<ZyraOneUpgradePage>(find.byType(ZyraOneUpgradePage))
            .strongBasicComparisonDisclosure,
        isFalse,
      );
      _expectFinePrint(tester, offer: offer, ink: _existingInk);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Q241 shared $role upgrade requires explicit opt in', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final legacy = ZyraOneUpgradePage(
        guardian: guardian,
        canContinue: () => true,
        onBack: () {},
      );
      expect(legacy.strongBasicComparisonDisclosure, isFalse);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: legacy)));
      expect(find.byType(ZyraPurchaseFinePrint), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraOneUpgradePage(
              guardian: guardian,
              founderPreview: true,
              canContinue: () => true,
              onBack: () {},
            ),
          ),
        ),
      );
      _expectFinePrint(tester, offer: offer, ink: _existingInk);
      expect(tester.takeException(), isNull);
    });
  }

  for (final offer in ZyraPurchaseOffer.values) {
    testWidgets('Q241 ${offer.name} shared purchase default is preserved', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraPurchaseFinePrint(
              offer: offer,
              familyMonthlyPence: offer == ZyraPurchaseOffer.zyraFamily
                  ? 4998
                  : null,
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<ZyraPurchaseFinePrint>(find.byType(ZyraPurchaseFinePrint))
            .disclosureColor,
        isNull,
      );
      _expectFinePrint(
        tester,
        offer: offer,
        familyMonthlyPence: offer == ZyraPurchaseOffer.zyraFamily ? 4998 : null,
        ink: offer == ZyraPurchaseOffer.compatibilityUnlocks
            ? ZyraColors.strongSecondaryText
            : _existingInk,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Q241 distinct Guardian compatibility route keeps default ink', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.seedJourneys(1), isTrue);
    const subject = 'draft-sara';
    expect(model.sendSalam(subject), isTrue);
    expect(model.simulatePeerSalam(subject), isTrue);
    expect(model.chooseStageContinue(subject), isTrue);
    expect(model.simulatePeerStageContinue(subject), isTrue);
    expect(model.advanceStage(subject), isTrue);
    expect(model.chooseCompatibilityReveal(subject), isTrue);
    expect(model.simulatePeerCompatibilityReveal(subject), isTrue);
    final harness = BaselineHarness(tester, group: 'line146_q241');
    await harness.mount(
      guardian: true,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: true,
        model: model.snapshot(),
        tab: 1,
        pages: const [],
        guardianMembership: 'Guardian Basic',
      ),
    );
    final access = harness.shellFixture.compatibilityAccess!;
    expect(access.unlock(subject), isTrue);
    expect(harness.shellFixture.refresh(), isTrue);
    await harness.flush();
    await harness.tap('guardian_journey');
    harness.assertPage('guardian');
    await harness.tap('draft_guardian_compatibility_$subject');
    harness.assertPage('guardian_compatibility');
    await harness.tap('draft_compatibility_score_next');
    await harness.tap('draft_compatibility_area_action');
    harness.assertPage('guardian_compatibility_upgrade');
    expect(
      tester
          .widget<ZyraOneUpgradePage>(find.byType(ZyraOneUpgradePage))
          .strongBasicComparisonDisclosure,
      isFalse,
    );
    _expectFinePrint(
      tester,
      offer: ZyraPurchaseOffer.guardianOne,
      ink: _existingInk,
    );
    expect(tester.takeException(), isNull);
  });
}
