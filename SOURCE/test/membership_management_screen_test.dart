import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/widgets/zyra_membership_choices.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

class _MembershipIntentStore implements ZyraSignupDraftStore {
  final values = <String, String>{};
  Completer<void>? readWait;
  bool rejectRead = false;

  @override
  Future<String?> read(String key) async {
    await readWait?.future;
    if (rejectRead) throw StateError('Synthetic protected-store failure.');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    SharedPreferences.setMockInitialValues({});
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.resetForAccountChange();
  });

  tearDown(() {
    AppState.instance.resetForAccountChange();
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    debugDefaultTargetPlatformOverride = null;
    ZyraText.useTestFontStubs = false;
  });

  Future<void> flushPersistence(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  Future<void> pump(
    WidgetTester tester, {
    MembershipStoreLauncher? openStore,
    ZyraTelemetrySurface surface = ZyraTelemetrySurface.seeker,
    Size size = const Size(393, 852),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: UpgradeScreen(
          telemetrySurface: surface,
          openStore: openStore,
          storePlatform: TargetPlatform.iOS,
        ),
      ),
    );
    await tester.pump();
    await flushPersistence(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  ZyraMembershipChoices choices(WidgetTester tester) =>
      tester.widget(find.byType(ZyraMembershipChoices));

  VoidCallback? buttonAction(WidgetTester tester, String key) => tester
      .widget<OutlinedButton>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(OutlinedButton),
        ),
      )
      .onPressed;

  testWidgets(
    'One keeps truthful current access and store-owned cancellation',
    (tester) async {
      AppState.instance.plan = ZyraPlan.one;
      Uri? opened;
      await pump(
        tester,
        openStore: (uri) async {
          opened = uri;
          return true;
        },
      );
      expect(find.byKey(const ValueKey('membership-current')), findsOneWidget);
      expect(choices(tester).currentSummary, 'Seeker One');
      expect(choices(tester).currentProducts, {
        ZyraMembershipProduct.seekerOne,
      });
      expect(find.byKey(const ValueKey('membership-basket')), findsNothing);
      expect(
        find.byKey(const ValueKey('membership-section-family')),
        findsOneWidget,
      );
      expect(
        choices(tester).initialDraft!.section,
        ZyraMembershipSection.current,
      );
      expect(
        find.byKey(const ValueKey('membership-review-selection')),
        findsNothing,
      );
      expect(
        find.byType(ZyraDraftCompatibilityStorePresentation),
        findsNothing,
      );
      final cancel = find.byKey(const ValueKey('membership-cancel'));
      expect(cancel.hitTestable(), findsOneWidget);
      expect(tester.getRect(cancel).bottom, lessThanOrEqualTo(852 - 34));
      await tapKey(tester, 'membership-cancel');
      expect(find.textContaining('App Store securely manages'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('membership-store-continue')));
      await tester.pumpAndSettle();
      expect(opened, UpgradeScreen.appleSubscriptionsUri);
      expect(AppState.instance.plan, ZyraPlan.one);
    },
  );

  testWidgets('inactive account selects then reviews without purchasing', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('No active membership'), findsOneWidget);
    expect(choices(tester).currentProducts, isEmpty);
    expect(find.byKey(const ValueKey('membership-cancel')), findsNothing);
    expect(
      find.byKey(const ValueKey('membership-review-selection')),
      findsNothing,
    );
    await tapKey(tester, 'membership-section-seeker');
    expect(buttonAction(tester, 'membership-review-selection'), isNull);
    await tapKey(tester, 'membership-select-seekerOne');
    expect(choices(tester).initialDraft!.selectedProducts, {
      ZyraMembershipProduct.seekerOne,
    });
    await tapKey(tester, 'membership-review-selection');
    final review = tester.widget<ZyraMembershipReviewPresentation>(
      find.byType(ZyraMembershipReviewPresentation),
    );
    expect(review.request.kind, ZyraMembershipReviewKind.individual);
    expect(review.request.products, {ZyraMembershipProduct.seekerOne});
    expect(review.request.familyQuote, isNull);
    expect(
      find.byKey(const ValueKey('membership-basket-checkout')),
      findsNothing,
    );
    expect(AppState.instance.plan, ZyraPlan.basic);
    await tester.ensureVisible(find.text('Back to cards'));
    await tester.tap(find.text('Back to cards'));
    await tester.pumpAndSettle();
    expect(choices(tester).initialDraft!.selectedProducts, {
      ZyraMembershipProduct.seekerOne,
    });
  });

  testWidgets(
    'Current-only cancellation and Terms reject section ABA callbacks',
    (tester) async {
      AppState.instance.plan = ZyraPlan.one;
      await pump(tester);
      final cancelKey = find.byKey(const ValueKey('membership-cancel'));
      final oldCancel = tester
          .widget<InkWell>(
            find.descendant(of: cancelKey, matching: find.byType(InkWell)),
          )
          .onTap!;
      final oldTerms = tester
          .widget<IconButton>(find.byKey(const ValueKey('membership-terms')))
          .onPressed!;
      await tapKey(tester, 'membership-section-seeker');
      expect(cancelKey, findsNothing);
      expect(find.byKey(const ValueKey('membership-current')), findsNothing);
      await tapKey(tester, 'membership-section-current');
      oldCancel();
      oldTerms();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraMembershipTermsSheet), findsNothing);
      expect(find.textContaining('App Store securely manages'), findsNothing);
      await tapKey(tester, 'membership-terms');
      expect(find.byType(ZyraMembershipTermsSheet), findsOneWidget);
      expect(find.text('Membership terms'), findsOneWidget);
      expect(find.textContaining('Blocking, reporting'), findsOneWidget);
      final close = find.widgetWithText(TextButton, 'Close');
      await tester.ensureVisible(close);
      await tester.pumpAndSettle();
      await tester.tap(close);
      await tester.pumpAndSettle();
      await tapKey(tester, 'membership-cancel');
      expect(find.textContaining('App Store securely manages'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(AppState.instance.plan, ZyraPlan.one);
    },
  );

  testWidgets(
    'inline Unlocks Terms owner cannot revive after leaving the section',
    (tester) async {
      await pump(tester);
      await tapKey(tester, 'membership-section-unlocks');
      final oldTerms = tester
          .widget<ZyraDraftCompatibilityStorePresentation>(
            find.byType(ZyraDraftCompatibilityStorePresentation),
          )
          .onTerms!;
      await tapKey(tester, 'membership-section-current');
      await tapKey(tester, 'membership-section-unlocks');
      oldTerms();
      await tester.pumpAndSettle();
      expect(find.text('Terms of Service'), findsNothing);
      final current = tester.widget<ZyraDraftCompatibilityStorePresentation>(
        find.byType(ZyraDraftCompatibilityStorePresentation),
      );
      expect(current.balance, isNull);
      await tapKey(tester, 'draft_compatibility_store_terms');
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Not available yet'), findsOneWidget);
      expect(AppState.instance.plan, ZyraPlan.basic);
    },
  );

  testWidgets(
    'Membership terms sheet remains readable at 320px and 200% text',
    (tester) async {
      await pump(tester, size: const Size(320, 568), scale: 2);
      expect(
        choices(tester).initialDraft!.section,
        ZyraMembershipSection.current,
      );
      final terms = find.byKey(const ValueKey('membership-terms'));
      expect(terms.hitTestable(), findsOneWidget);
      expect(tester.getSize(terms).height, greaterThanOrEqualTo(44));
      expect(find.byTooltip('Membership terms'), findsOneWidget);
      await tapKey(tester, 'membership-terms');
      expect(find.byType(ZyraMembershipTermsSheet), findsOneWidget);
      expect(
        find.textContaining(ZyraMembershipCatalog.basicTerms),
        findsOneWidget,
      );
      expect(
        find.textContaining('do not erase Guardian links'),
        findsOneWidget,
      );
      final close = find.widgetWithText(TextButton, 'Close');
      await tester.ensureVisible(close);
      await tester.pumpAndSettle();
      expect(close.hitTestable(), findsOneWidget);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(ZyraMembershipTermsSheet), findsNothing);
      expect(AppState.instance.plan, ZyraPlan.basic);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guardian capability is not independently owned subscription billing',
    (tester) async {
      AppState.instance.setWaliOne(true);
      await pump(tester, surface: ZyraTelemetrySurface.guardian);
      final current = find.byKey(const ValueKey('membership-current'));
      expect(
        find.descendant(
          of: current,
          matching: find.text('Guardian access active'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: current, matching: find.textContaining('£19.99')),
        findsNothing,
      );
      expect(choices(tester).currentProducts, isEmpty);
      expect(
        choices(tester).initialDraft!.section,
        ZyraMembershipSection.current,
      );
      expect(find.byKey(const ValueKey('membership-cancel')), findsOneWidget);
      expect(find.textContaining('If billed to you'), findsOneWidget);
    },
  );

  testWidgets(
    'unknown Basic cannot replace either independently selected One',
    (tester) async {
      await pump(tester);
      await tapKey(tester, 'membership-section-seeker');
      await tapKey(tester, 'membership-select-seekerOne');
      await tapKey(tester, 'membership-next');
      expect(buttonAction(tester, 'membership-select-seekerBasic'), isNull);
      expect(find.text('Joining fee not confirmed'), findsWidgets);
      await tapKey(tester, 'membership-select-seekerBasic');
      expect(choices(tester).initialDraft!.selectedProducts, {
        ZyraMembershipProduct.seekerOne,
      });
      await tapKey(tester, 'membership-section-guardian');
      await tapKey(tester, 'membership-select-guardianOne');
      expect(choices(tester).initialDraft!.selectedProducts, {
        ZyraMembershipProduct.seekerOne,
        ZyraMembershipProduct.guardianOne,
      });
      await tapKey(tester, 'membership-review-selection');
      final review = tester.widget<ZyraMembershipReviewPresentation>(
        find.byType(ZyraMembershipReviewPresentation),
      );
      expect(review.request.products, {
        ZyraMembershipProduct.seekerOne,
        ZyraMembershipProduct.guardianOne,
      });
      expect(AppState.instance.plan, ZyraPlan.basic);
      expect(AppState.instance.waliHasWaliOne, isFalse);
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian allocated' : 'Seeker One'} is not payment history',
      (tester) async {
        AppState.instance.plan = ZyraPlan.one;
        AppState.instance.setWaliOne(true);
        await pump(
          tester,
          surface: guardian
              ? ZyraTelemetrySurface.guardian
              : ZyraTelemetrySurface.seeker,
        );
        expect(
          choices(tester).paymentHistory,
          ZyraMembershipPaymentHistory.unknown,
        );
        for (final role in ['seeker', 'guardian']) {
          await tapKey(tester, 'membership-section-$role');
          await tapKey(tester, 'membership-next');
          expect(
            buttonAction(tester, 'membership-select-${role}Basic'),
            isNull,
          );
        }
        expect(find.text('No joining fee'), findsNothing);
        expect(AppState.instance.plan, ZyraPlan.one);
        expect(AppState.instance.waliHasWaliOne, isTrue);
      },
    );
  }

  testWidgets('Family review never mixes a pending personal charge', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'membership-section-seeker');
    await tapKey(tester, 'membership-select-seekerOne');
    await tapKey(tester, 'membership-section-family');
    expect(buttonAction(tester, 'membership-review-selection'), isNull);
    await tapKey(tester, 'membership-family-seeker-plus');
    await tapKey(tester, 'membership-family-seeker-plus');
    await tapKey(tester, 'membership-family-guardian-plus');
    expect(find.text('5% saving'), findsOneWidget);
    await tapKey(tester, 'membership-review-selection');
    final review = tester.widget<ZyraMembershipReviewPresentation>(
      find.byType(ZyraMembershipReviewPresentation),
    );
    expect(review.request.kind, ZyraMembershipReviewKind.family);
    expect(review.request.products, isEmpty);
    expect(review.request.familyQuote!.formulaMonthlyPence, 7597);
    expect(AppState.instance.plan, ZyraPlan.basic);
  });

  testWidgets('old membership callbacks refuse another account generation', (
    tester,
  ) async {
    await pump(tester);
    final old = choices(tester);
    final draft = ZyraMembershipDraft(
      selectedProducts: [ZyraMembershipProduct.seekerOne],
    );
    final request = ZyraMembershipReviewRequest.fromDraft(
      draft,
      currentProducts: {},
      paymentHistory: ZyraMembershipPaymentHistory.unknown,
    )!;
    ZyraAccountState.resetForTesting();
    old.onDraftChanged(draft);
    old.onReview(request);
    await tester.pumpAndSettle();
    expect(find.byType(ZyraMembershipReviewPresentation), findsNothing);
    expect(AppState.instance.plan, ZyraPlan.basic);
  });
  testWidgets('Basic never leaks into the Compatibility-only purchase page', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CompatibilityUnlockStoreScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Seeker Basic'), findsNothing);
    expect(find.text('Guardian Basic'), findsNothing);
    expect(
      find.byKey(const ValueKey('compatibility-offer-seeker-basic')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('draft_compatibility_store_unlock_single')),
      findsOneWidget,
    );
  });

  for (final role in ZyraSignupRole.values) {
    testWidgets('${role.name} Basic rehearsal is visibly preview-only', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      await pump(
        tester,
        surface: role == ZyraSignupRole.guardian
            ? ZyraTelemetrySurface.guardian
            : ZyraTelemetrySurface.seeker,
      );
      expect(
        find.text(
          '${role == ZyraSignupRole.guardian ? 'Guardian' : 'Seeker'} Basic · Preview',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Payment history is not confirmed'),
        findsOneWidget,
      );
      expect(find.text('Your signup choice'), findsNothing);
      expect(AppState.instance.plan, ZyraPlan.basic);
      expect(AppState.instance.waliHasWaliOne, isFalse);
    });
  }

  Future<_MembershipIntentStore> seedIntent(
    WidgetTester tester,
    ZyraSignupMembershipIntent intent,
  ) async {
    return (await tester.runAsync(() async {
      await ZyraAccountState.synchronize('synthetic-owner');
      final store = _MembershipIntentStore();
      final repository = ZyraSignupDraftRepository(
        store: store,
        backend: 'https://synthetic.invalid',
        currentUserId: () => ZyraAccountState.userId,
        isPreview: () => false,
      );
      await repository.saveMembershipIntent('synthetic-owner', intent);
      ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
      return store;
    }))!;
  }

  for (final role in ZyraSignupRole.values) {
    testWidgets(
      '${role.name} retained Basic choice is never active membership',
      (tester) async {
        await seedIntent(
          tester,
          ZyraSignupMembershipIntent(
            role: role,
            choice: const ZyraSignupMembershipChoice(
              kind: ZyraSignupMembershipKind.basic,
            ),
          ),
        );
        await pump(
          tester,
          surface: role == ZyraSignupRole.guardian
              ? ZyraTelemetrySurface.guardian
              : ZyraTelemetrySurface.seeker,
        );
        await tester.pumpAndSettle();
        expect(find.text('Your signup choice'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('membership-signup-choice')),
            matching: find.textContaining('Joining fee not confirmed'),
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Saved as a preference only'),
          findsOneWidget,
        );
        expect(find.text('No active membership'), findsOneWidget);
        expect(AppState.instance.plan, ZyraPlan.basic);
        expect(AppState.instance.waliHasWaliOne, isFalse);
      },
      variant: TargetPlatformVariant({TargetPlatform.iOS}),
    );
  }

  testWidgets(
    'Family choice shows counts and estimate, not active access',
    (tester) async {
      await seedIntent(
        tester,
        const ZyraSignupMembershipIntent(
          role: ZyraSignupRole.seeker,
          choice: ZyraSignupMembershipChoice(
            kind: ZyraSignupMembershipKind.family,
            seekers: 2,
            guardians: 1,
          ),
        ),
      );
      await pump(tester);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('2 Seeker and 1 Guardian places'),
        findsOneWidget,
      );
      expect(find.textContaining('£75.97 / month estimated'), findsOneWidget);
      expect(find.text('No active membership'), findsOneWidget);
      expect(AppState.instance.plan, ZyraPlan.basic);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'another role never renders a saved choice',
    (tester) async {
      await seedIntent(
        tester,
        const ZyraSignupMembershipIntent(
          role: ZyraSignupRole.guardian,
          choice: ZyraSignupMembershipChoice(
            kind: ZyraSignupMembershipKind.one,
          ),
        ),
      );
      await pump(tester);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('membership-signup-choice')),
        findsNothing,
      );
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'delayed former-account choice cannot publish after a switch',
    (tester) async {
      final store = await seedIntent(
        tester,
        const ZyraSignupMembershipIntent(
          role: ZyraSignupRole.seeker,
          choice: ZyraSignupMembershipChoice(
            kind: ZyraSignupMembershipKind.basic,
          ),
        ),
      );
      store.readWait = Completer<void>();
      await pump(tester);
      await tester.runAsync(
        () => ZyraAccountState.synchronize('other-synthetic-owner'),
      );
      store.readWait!.complete();
      await flushPersistence(tester);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('membership-signup-choice')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('membership-signup-choice-retry')),
        findsNothing,
      );
      expect(AppState.instance.plan, ZyraPlan.basic);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'protected preference read failure offers safe retry',
    (tester) async {
      final store = await seedIntent(
        tester,
        const ZyraSignupMembershipIntent(
          role: ZyraSignupRole.seeker,
          choice: ZyraSignupMembershipChoice(
            kind: ZyraSignupMembershipKind.basic,
          ),
        ),
      );
      store.rejectRead = true;
      await pump(tester);
      await tester.pumpAndSettle();
      final retry = find.byKey(
        const ValueKey('membership-signup-choice-retry'),
      );
      expect(retry, findsOneWidget);
      expect(find.text('No active membership'), findsOneWidget);
      store.rejectRead = false;
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await flushPersistence(tester);
      await tester.pumpAndSettle();
      expect(find.text('Your signup choice'), findsOneWidget);
      expect(find.text('No active membership'), findsOneWidget);
      expect(AppState.instance.plan, ZyraPlan.basic);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  test('membership heading uses the app type system, not the wordmark', () {
    final source = File(
      'lib/screens/subscription/upgrade_screen.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('ZyraText.wordmark')));
    expect(source, contains('ZyraMembershipChoices('));
    expect(source, contains('ZyraMembershipReviewPresentation('));
    expect(source, isNot(contains('_BasketButton')));
    expect(source, isNot(contains('_MembershipOffer')));
    expect(source, contains('ZyraDraftCompatibilityStorePresentation('));
    expect(source, isNot(contains('_CompatibilityOfferCard')));
    expect(source, isNot(contains('compatibility-add-')));
    expect(source, isNot(contains("ValueKey('compatibility-standard-group')")));
    expect(source, isNot(contains("ValueKey('compatibility-plus-group')")));
    expect(
      source,
      isNot(
        contains(
          'Separate optional purchases. They are not part of your monthly membership.',
        ),
      ),
    );
    expect(source, isNot(contains("ValueKey('membership-basket-summary')")));
    expect(source, contains('currentContent:'));
    expect(source, contains('unlocksContent:'));
    expect(source, contains('onTerms:'));
    expect(source, isNot(contains('_MembershipInfoTile')));
  });

  testWidgets('standalone Unlocks Back wording and arrow each pop one route', (
    tester,
  ) async {
    final navigation = GlobalKey<NavigatorState>();
    final originalPlan = AppState.instance.plan;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigation,
        home: const Scaffold(body: Text('Original parent')),
      ),
    );
    for (final word in [true, false]) {
      navigation.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Immediate parent')),
        ),
      );
      await tester.pumpAndSettle();
      navigation.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const CompatibilityUnlockStoreScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final back = find.byKey(const ValueKey('compatibility-store-back'));
      final staleBack = tester.widget<TextButton>(back).onPressed!;
      expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
      await tester.tap(
        find.descendant(
          of: back,
          matching: word ? find.text('Back') : find.byIcon(Icons.arrow_back),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Immediate parent'), findsOneWidget);
      expect(find.byType(CompatibilityUnlockStoreScreen), findsNothing);
      staleBack();
      await tester.pumpAndSettle();
      expect(find.text('Immediate parent'), findsOneWidget);
      navigation.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Original parent'), findsOneWidget);
    }
    expect(AppState.instance.plan, originalPlan);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Membership Unlocks pill renders the held store inline', (
    tester,
  ) async {
    AppState.instance.plan = ZyraPlan.one;
    await pump(tester);

    expect(
      choices(tester).initialDraft!.section,
      ZyraMembershipSection.current,
    );
    await tapKey(tester, 'membership-section-unlocks');
    expect(
      choices(tester).initialDraft!.section,
      ZyraMembershipSection.unlocks,
    );
    expect(find.byType(CompatibilityUnlockStoreScreen), findsNothing);
    expect(find.byType(CompatibilityUnlockStoreContent), findsOneWidget);
    expect(
      tester
          .widget<ZyraDraftCompatibilityStorePresentation>(
            find.byType(ZyraDraftCompatibilityStorePresentation),
          )
          .balance,
      isNull,
    );
    expect(
      find.byKey(const ValueKey('membership-review-selection')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('membership-cancel')), findsNothing);
    expect(find.text('See your overall match score'), findsNothing);
    expect(
      find.byKey(const ValueKey('draft_compatibility_store_use_unlocks')),
      findsNothing,
    );
    await tapKey(tester, 'draft_compatibility_store_info');
    expect(
      find.byKey(const ValueKey('draft_compatibility_store_info_dialog')),
      findsOneWidget,
    );
    expect(find.text('See your overall match score'), findsOneWidget);
    await tapKey(tester, 'draft_compatibility_store_info_close');
    expect(find.byKey(const ValueKey('membership-current')), findsNothing);
    expect(
      find.byKey(const ValueKey('compatibility-offer-unlock-one')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('draft_compatibility_store_unlock_single')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('compatibility-basket')), findsNothing);

    final offer = find.byKey(
      const ValueKey('draft_compatibility_store_unlock_three'),
    );
    await tester.ensureVisible(offer);
    await tester.pumpAndSettle();
    await tester.tap(offer);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Semantics>(
            find.byKey(
              const ValueKey(
                'draft_compatibility_store_unlock_three_selection',
              ),
            ),
          )
          .properties
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('draft_compatibility_store_continue')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Purchasing isn’t available yet.'), findsOneWidget);
    expect(find.textContaining('£6.99'), findsWidgets);
    expect(find.textContaining('22%'), findsWidgets);
    expect(find.text('Purchase terms'), findsOneWidget);
    final terms = find.byKey(const ValueKey('draft_compatibility_store_terms'));
    await tester.ensureVisible(terms);
    await tester.pumpAndSettle();
    await tester.tap(terms);
    await tester.pumpAndSettle();
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Not available yet'), findsOneWidget);
    expect(AppState.instance.plan, ZyraPlan.one);
  });

  testWidgets(
    'retained store Terms callback refuses a new account generation',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CompatibilityUnlockStoreScreen()),
      );
      await tester.pumpAndSettle();
      final oldTerms = tester
          .widget<ZyraDraftCompatibilityStorePresentation>(
            find.byType(ZyraDraftCompatibilityStorePresentation),
          )
          .onTerms!;
      // This increments the scope without relying on listener timing.
      ZyraAccountState.resetForTesting();
      oldTerms();
      await tester.pumpAndSettle();
      expect(find.text('Terms of Service'), findsNothing);
      expect(find.byType(CompatibilityUnlockStoreScreen), findsOneWidget);
    },
  );

  testWidgets(
    'store launcher errors show a recovery message without changing access',
    (tester) async {
      AppState.instance.plan = ZyraPlan.one;
      await pump(
        tester,
        openStore: (_) async => throw StateError('Unavailable'),
      );
      final cancel = find.byKey(const ValueKey('membership-cancel'));
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('membership-store-continue')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not open App Store subscriptions'),
        findsOneWidget,
      );
      expect(AppState.instance.plan, ZyraPlan.one);
      expect(tester.takeException(), isNull);
    },
  );
}
