import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_family_pricing_card.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  test('Family formula checks every independent role combination', () {
    var combinations = 0;
    for (var seekers = 0; seekers <= 10; seekers++) {
      for (var guardians = 0; guardians <= 10; guardians++) {
        final quote = ZyraMembershipCatalog.familyQuote(seekers, guardians);
        final members = seekers + guardians;
        final discount = ((members - 2) * 5).clamp(0, 40);
        final gross = seekers * 2999 + guardians * 1999;
        final monthly = (gross * (100 - discount) + 50) ~/ 100;
        expect(quote.members, members);
        expect(quote.hasMembers, members > 0);
        expect(quote.discountPercent, discount);
        expect(quote.individualMonthlyPence, gross);
        expect(quote.formulaMonthlyPence, monthly);
        expect(quote.savingPence, gross - monthly);
        expect(quote.introFirstMonthPence, members * 499);
        combinations++;
      }
    }
    expect(combinations, 121);
    expect(ZyraMembershipCatalog.familyQuote(1, 1).introFirstMonthPence, 998);
    expect(ZyraMembershipCatalog.familyQuote(2, 1).introFirstMonthPence, 1497);
    expect(
      ZyraMembershipCatalog.familyQuote(10, 10).introFirstMonthPence,
      9980,
    );
    expect(ZyraMembershipCatalog.familyQuote(5, 5).formulaMonthlyPence, 14994);
    expect(
      ZyraMembershipCatalog.familyQuote(10, 10).formulaMonthlyPence,
      29988,
    );
    expect(ZyraMembershipCatalog.familyQuote(5, 0).formulaMonthlyPence, 12746);
    expect(ZyraMembershipCatalog.familyQuote(0, 5).formulaMonthlyPence, 8496);
    expect(() => ZyraMembershipCatalog.familyQuote(-1, 1), throwsRangeError);
    expect(() => ZyraMembershipCatalog.familyQuote(1, 11), throwsRangeError);
  });

  test('Help shares the unchanged Family terms and restored Basic fee', () {
    final answer = zyraHelpCategories
        .expand((category) => category.entries)
        .singleWhere((entry) => entry.question == 'What does ZYRA cost?')
        .answer;
    expect(answer, contains(ZyraMembershipCatalog.familyTerms));
    expect(answer, contains(ZyraMembershipCatalog.familyAvailability));
    expect(answer, contains('£29.99'));
    expect(answer, contains('£19.99'));
    expect(answer, isNot(contains('£99.99')));
    expect(answer, contains('£4.99 one-time joining'));
    expect(answer, contains('no monthly subscription'));
    expect(answer, isNot(contains('no free membership')));
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Family calculator fits $width at scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final before = AppState.instance.plan;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: ZyraFamilyPricingCard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('family-empty')), findsOneWidget);
        expect(find.text('£99.99 / month'), findsNothing);
        expect(find.text('Continue'), findsNothing);
        expect(tester.takeException(), isNull);
        expect(AppState.instance.plan, before);
      });
    }
  }

  testWidgets('Family controls calculate independently without checkout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ZyraFamilyPricingCard()),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('family-seekers-add')));
      await tester.tap(find.byKey(const ValueKey('family-guardians-add')));
    }
    await tester.pumpAndSettle();
    expect(find.text('£149.94'), findsOneWidget);
    expect(find.textContaining('40% estimated saving'), findsOneWidget);
    expect(find.byKey(const ValueKey('family-monthly-total')), findsOneWidget);
  });

  test('Family information has no checkout, backend or entitlement writer', () {
    final source = File(
      'lib/widgets/zyra_family_pricing_card.dart',
    ).readAsStringSync();
    for (final forbidden in [
      'setPlan(',
      'AppState',
      'Supabase',
      '.rpc(',
      'mockPurchase',
      'recordPurchaseResult(',
      'SharedPreferences',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
