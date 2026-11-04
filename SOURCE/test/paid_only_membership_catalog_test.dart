import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/constants/zyra_plan_names.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  test(
    'public catalog restores Basic joining fees without activating access',
    () {
      expect(ZyraMembershipCatalog.products, [
        ZyraMembershipProduct.seekerOne,
        ZyraMembershipProduct.seekerBasic,
        ZyraMembershipProduct.guardianOne,
        ZyraMembershipProduct.guardianBasic,
      ]);
      expect(ZyraMembershipCatalog.checkoutAvailable, isFalse);
      expect(ZyraMembershipCatalog.trialDays, 14);
      expect(
        ZyraSubscriptionPlanType.fromDbValue('seeker_basic'),
        ZyraSubscriptionPlanType.seekerBasic,
      );
      expect(ZyraSubscriptionPlanType.seekerBasic.displayName, 'Seeker Basic');
      expect(ZyraSubscriptionPlanType.waliBasic.displayName, 'Guardian Basic');
      expect(ZyraSubscriptionPlanType.waliPremium.displayName, 'Guardian One');
      expect(
        ZyraMembershipCatalog.price(ZyraMembershipProduct.seekerOne),
        '£29.99 / month',
      );
      expect(
        ZyraMembershipCatalog.price(ZyraMembershipProduct.guardianOne),
        '£19.99 / month',
      );
      expect(
        ZyraMembershipCatalog.price(ZyraMembershipProduct.seekerBasic),
        '£4.99 once',
      );
      expect(
        ZyraMembershipCatalog.price(ZyraMembershipProduct.guardianBasic),
        '£4.99 once',
      );
      expect(ZyraMembershipCatalog.basicJoiningPence, 499);
      expect(
        ZyraMembershipCatalog.basicTerms,
        contains('no monthly subscription'),
      );
      expect(
        ZyraMembershipCatalog.basicTerms,
        contains('does not confirm payment'),
      );
      for (final product in ZyraMembershipCatalog.products) {
        expect(
          ZyraMembershipCatalog.isBasic(product),
          product == ZyraMembershipProduct.seekerBasic ||
              product == ZyraMembershipProduct.guardianBasic,
        );
      }
    },
  );

  test('canonical role labels preserve every stored plan identifier', () {
    const expected = [
      (
        plan: ZyraSubscriptionPlanType.seekerBasic,
        id: 'seeker_basic',
        title: 'Seeker Basic',
      ),
      (
        plan: ZyraSubscriptionPlanType.seekerPremium,
        id: 'seeker_premium',
        title: 'Seeker One',
      ),
      (
        plan: ZyraSubscriptionPlanType.waliBasic,
        id: 'wali_basic',
        title: 'Guardian Basic',
      ),
      (
        plan: ZyraSubscriptionPlanType.waliPremium,
        id: 'wali_premium',
        title: 'Guardian One',
      ),
    ];
    expect(
      ZyraSubscriptionPlanType.values,
      expected.map((entry) => entry.plan),
    );
    for (final entry in expected) {
      expect(entry.plan.dbValue, entry.id);
      expect(entry.plan.displayName, entry.title);
      expect(ZyraSubscriptionPlanType.fromDbValue(entry.id), entry.plan);
    }
    expect(
      ZyraMembershipCatalog.title(ZyraMembershipProduct.seekerOne),
      'Seeker One',
    );
    expect(
      ZyraMembershipCatalog.title(ZyraMembershipProduct.guardianOne),
      'Guardian One',
    );
  });

  test('Guardian Basic keeps Network visible as a locked destination', () {
    expect(waliPagesForMembership(hasGuardianOne: false), [
      WaliPage.dashboard,
      WaliPage.network,
      WaliPage.seekers,
      WaliPage.profile,
    ]);
    expect(waliPagesForMembership(hasGuardianOne: true), [
      WaliPage.dashboard,
      WaliPage.network,
      WaliPage.seekers,
      WaliPage.profile,
    ]);
  });

  test('Seeker One, Guardian One and Family stay monthly-only', () {
    for (final product in [
      ZyraMembershipProduct.seekerOne,
      ZyraMembershipProduct.guardianOne,
    ]) {
      expect(ZyraMembershipCatalog.price(product), endsWith(' / month'));
    }
    expect(
      ZyraMembershipCatalog.products,
      contains(ZyraMembershipProduct.seekerBasic),
    );
    expect(
      ZyraMembershipCatalog.products,
      contains(ZyraMembershipProduct.guardianBasic),
    );
    expect(ZyraMembershipCatalog.familyTerms, contains('billed monthly'));
    expect(
      ZyraMembershipCatalog.trialTerms,
      contains('paid monthly subscription'),
    );
    expect(ZyraMembershipCatalog.checkoutAvailable, isFalse);
  });

  test('Basic Help preserves role boundaries and never calls joining free', () {
    final answer = zyraHelpCategories
        .expand((category) => category.entries)
        .singleWhere((entry) => entry.question == 'What does Basic include?')
        .answer;
    expect(answer, contains(ZyraMembershipCatalog.basicTerms));
    expect(answer, contains(ZyraMembershipCatalog.guardianBasicTerms));
    expect(answer, contains('25 profile swipes per four-hour window'));
    expect(answer, contains('live adverts are not available'));
    expect(answer, contains('Payments, trial activation'));
    expect(answer, isNot(contains('£9.99 one-time')));
    expect(answer, isNot(contains('free membership')));
  });

  test(
    'one full compatibility product uses former Plus prices and no checkout',
    () {
      expect(ZyraMembershipCatalog.compatibilitySinglePence, 299);
      expect(ZyraMembershipCatalog.compatibilityThreePence, 699);
      expect(ZyraMembershipCatalog.compatibilityFivePence, 999);
      final presentation = File(
        'lib/dev/zyra_draft_compatibility_store_presentation.dart',
      ).readAsStringSync();
      for (final retired in [
        'onUseUnlocks',
        'draft_compatibility_store_use_unlocks',
        'draft_compatibility_store_use_guidance',
      ]) {
        expect(presentation, isNot(contains(retired)));
      }
      expect(
        ZyraMembershipCatalog.compatibilityTerms,
        contains('charged separately'),
      );
      expect(
        ZyraMembershipCatalog.compatibilityPrices,
        'Compatibility Unlocks: £2.99 for one, £6.99 for three or £9.99 for five.',
      );
      expect(
        ZyraMembershipCatalog.compatibilityPrices,
        isNot(contains('Plus')),
      );
      expect(
        ZyraMembershipCatalog.compatibilityPrices,
        isNot(contains('£1.99')),
      );
      expect(
        ZyraMembershipCatalog.compatibilityPrices,
        isNot(contains('£7.99')),
      );
      expect(
        ZyraMembershipCatalog.compatibilityAvailability,
        contains('Purchasing unlocks is not available'),
      );
      final entries = zyraHelpCategories.expand((category) => category.entries);
      for (final question in [
        'What does ZYRA cost?',
        'What do Seeker One and Guardian One include?',
      ]) {
        final answer = entries
            .singleWhere((entry) => entry.question == question)
            .answer;
        expect(answer, contains(ZyraMembershipCatalog.compatibilityTerms));
        expect(
          answer,
          contains(ZyraMembershipCatalog.compatibilityAvailability),
        );
      }
    },
  );

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('membership information fits $width at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
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
            home: const UpgradeScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Membership'), findsOneWidget);
        final role = find.byKey(const ValueKey('membership-section-seeker'));
        await tester.ensureVisible(role);
        await tester.pumpAndSettle();
        await tester.tap(role);
        await tester.pumpAndSettle();
        final membershipScrollable = find.descendant(
          of: find.byKey(const ValueKey('membership-choices-scroll')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        );
        expect(membershipScrollable, findsOneWidget);
        final seekerHalo = find.byKey(
          const ValueKey('membership-halo-seekerOne'),
        );
        await tester.scrollUntilVisible(
          seekerHalo,
          150,
          scrollable: membershipScrollable,
        );
        expect(
          find.descendant(
            of: find
                .ancestor(of: seekerHalo, matching: find.byType(Padding))
                .first,
            matching: find.text('Seeker One'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Switch back'), findsNothing);
        expect(tester.takeException(), isNull);
        expect(find.text('Weekly'), findsNothing);
        expect(
          find.textContaining(
            RegExp(
              r'\b(yearly|annual|annually|weekly)\b',
              caseSensitive: false,
            ),
          ),
          findsNothing,
        );
        expect(AppState.instance.plan, before);
        expect(tester.takeException(), isNull);
        final compatibilityStore = find.byKey(
          const ValueKey('membership-section-unlocks'),
        );
        expect(compatibilityStore, findsOneWidget);
        await tester.ensureVisible(compatibilityStore);
        await tester.pumpAndSettle();
        await tester.tap(compatibilityStore);
        await tester.pumpAndSettle();
        expect(find.byType(CompatibilityUnlockStoreScreen), findsNothing);
        expect(find.byType(CompatibilityUnlockStoreContent), findsOneWidget);
        expect(
          find.byKey(const ValueKey('membership-review-selection')),
          findsNothing,
        );
        expect(find.text('See your overall match score'), findsNothing);
        expect(
          // LOCK 22 V1, UNITY_PASS/MASTERS/x02–x03: inline eight-page preview.
          find.byKey(const ValueKey('draft_compatibility_store_preview')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('draft_compatibility_store_use_unlocks')),
          findsNothing,
        );
        expect(find.text('Current membership'), findsNothing);
        final compatibility = find.byKey(
          const ValueKey('draft_compatibility_store_terms'),
        );
        await tester.scrollUntilVisible(
          compatibility,
          200,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const ValueKey('draft_compatibility_store_viewport'),
                ),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                ),
              )
              .first,
        );
        await tester.ensureVisible(compatibility);
        await tester.pumpAndSettle();
        await tester.tap(compatibility);
        await tester.pumpAndSettle();
        expect(find.text('Terms of Service'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.text('Not available yet'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('£2.99'), findsOneWidget);
        expect(find.text('£6.99'), findsOneWidget);
        expect(find.text('£9.99'), findsOneWidget);
        final current = find.byKey(
          const ValueKey('membership-section-current'),
        );
        await tester.ensureVisible(current);
        await tester.pumpAndSettle();
        await tester.tap(current);
        await tester.pumpAndSettle();
        final terms = find.byKey(const ValueKey('membership-terms'));
        await tester.ensureVisible(terms);
        await tester.pumpAndSettle();
        expect(find.byTooltip('Membership terms'), findsOneWidget);
        await tester.tap(terms);
        await tester.pumpAndSettle();
        expect(find.text('Membership terms'), findsOneWidget);
        expect(find.textContaining('Blocking, reporting'), findsOneWidget);
        final close = find.widgetWithText(TextButton, 'Close');
        await tester.ensureVisible(close);
        await tester.pumpAndSettle();
        expect(close.hitTestable(), findsOneWidget);
        expect(find.textContaining('do not erase'), findsOneWidget);
        expect(AppState.instance.plan, before);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test(
    'membership screen cannot activate trial, mock purchase or downgrade',
    () {
      final source = File(
        'lib/screens/subscription/upgrade_screen.dart',
      ).readAsStringSync();
      for (final forbidden in [
        'setPlan(',
        'mockPurchase',
        'recordPurchaseResult(',
        'Supabase',
        '.rpc(',
        'DateTime.now(',
        'UnlockPricing',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
      final unlock = File(
        'lib/screens/subscription/profile_unlock_screen.dart',
      ).readAsStringSync();
      expect(unlock, isNot(contains('onTap: _buy')));
      expect(unlock, isNot(contains('class UnlockPricing')));
      expect(unlock, contains('ZyraUnlockService.isUnlocked('));
      expect(unlock, contains('ZyraUnlockService.isTierAvailable('));
      expect(unlock, contains('ZyraUnlockService.currentTier'));
      final service = File(
        'lib/services/zyra_unlock_service.dart',
      ).readAsStringSync();
      expect(service, contains('static const currentTier = UnlockTier.plus;'));
      expect(
        service,
        contains('static const bool categoryBreakdownAvailable = false;'),
      );
      expect(
        service,
        contains('tier != UnlockTier.plus || categoryBreakdownAvailable'),
      );
      expect(
        service,
        contains(
          'if (!isTierAvailable(tier)) return UnlockOutcome.unavailable;',
        ),
        reason: 'An unready full-data product must not debit any real credit.',
      );
    },
  );
}
