import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_membership_choices.dart';

const _one = ZyraMembershipProduct.seekerOne;
const _basic = ZyraMembershipProduct.seekerBasic;
const _guardianOne = ZyraMembershipProduct.guardianOne;
const _guardianBasic = ZyraMembershipProduct.guardianBasic;
const _paid = ZyraMembershipPaymentHistory.paidBefore;
const _sections = [
  ZyraMembershipSection.current,
  ZyraMembershipSection.unlocks,
  ZyraMembershipSection.seeker,
  ZyraMembershipSection.guardian,
  ZyraMembershipSection.family,
];
const _sectionLabels = {
  ZyraMembershipSection.current: 'Current',
  ZyraMembershipSection.unlocks: 'Compatibility Unlocks',
  ZyraMembershipSection.seeker: 'Seeker',
  ZyraMembershipSection.guardian: 'Guardian',
  ZyraMembershipSection.family: 'ZYRA Family',
};

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  Future<void> pumpChoices(
    WidgetTester tester, {
    ZyraMembershipDraft? draft,
    Set<ZyraMembershipProduct> current = const {_one},
    ZyraMembershipPaymentHistory history = _paid,
    ValueChanged<ZyraMembershipDraft>? onChanged,
    ValueChanged<ZyraMembershipReviewRequest>? onReview,
    VoidCallback? onTerms,
    Widget? currentContent,
    Widget? unlocksContent,
    bool Function()? canAct,
    double width = 430,
    double height = 950,
    double scale = 1,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduceMotion,
          ),
          child: Scaffold(
            body: SafeArea(
              child: ZyraMembershipChoices(
                initialDraft: draft,
                currentProducts: current,
                paymentHistory: history,
                currentSummary: 'Current membership',
                currentDetail: current.contains(_one) ? 'Seeker One' : null,
                onDraftChanged: onChanged ?? (_) {},
                onReview: onReview ?? (_) {},
                onTerms: onTerms ?? () {},
                currentContent: currentContent,
                unlocksContent: unlocksContent,
                canAct: canAct,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder keyed(String key) => find.byKey(ValueKey(key));

  OutlinedButton outlined(WidgetTester tester, String key) {
    final element = keyed(key).evaluate().single;
    if (element.widget case final OutlinedButton button) return button;
    return tester.widget<OutlinedButton>(
      find.descendant(of: keyed(key), matching: find.byType(OutlinedButton)),
    );
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(keyed(key));
    await tester.tap(keyed(key));
    await tester.pumpAndSettle();
  }

  Finder sectionScroller() => find.descendant(
    of: keyed('membership-section-slider'),
    matching: find.byType(Scrollable),
  );

  ScrollPosition sectionPosition(WidgetTester tester) =>
      tester.state<ScrollableState>(sectionScroller()).position;

  bool selected(WidgetTester tester, ZyraMembershipSection section) =>
      tester
          .getSemantics(keyed('membership-section-${section.name}'))
          .getSemanticsData()
          .flagsCollection
          .isSelected ==
      ui.Tristate.isTrue;

  test(
    'draft snapshots external collections and permits one choice per role',
    () {
      final external = <ZyraMembershipProduct>{_one, _basic, _guardianOne};
      final draft = ZyraMembershipDraft(selectedProducts: external);
      external.clear();
      expect(draft.selectedProducts, {_basic, _guardianOne});
      expect(() => draft.selectedProducts.add(_one), throwsUnsupportedError);
      final changed = draft.selectProduct(_guardianBasic);
      expect(changed.selectedProducts, {_basic, _guardianBasic});
      expect(draft.selectedProducts, {_basic, _guardianOne});
      expect(
        changed.selectProduct(_one, currentProducts: {_one}).selectedProducts,
        {_guardianBasic},
      );
      expect(
        changed
            .removeRoleSelection(ZyraMembershipSection.guardian)
            .selectedProducts,
        {_basic},
      );
    },
  );

  test('draft rejects out-of-range navigation and Family quantities', () {
    expect(() => ZyraMembershipDraft(seekerPage: 2), throwsRangeError);
    expect(() => ZyraMembershipDraft(guardianPage: -1), throwsRangeError);
    expect(() => ZyraMembershipDraft(familySeekers: 11), throwsRangeError);
    expect(() => ZyraMembershipDraft(familyGuardians: -1), throwsRangeError);
  });

  test(
    'Current and Unlocks cannot review or erase retained plan intentions',
    () {
      final original = ZyraMembershipDraft(
        seekerPage: 1,
        guardianPage: 1,
        familySeekers: 2,
        familyGuardians: 1,
        selectedProducts: [_basic, _guardianOne],
      );
      expect(original.section, ZyraMembershipSection.seeker);
      for (final section in [
        ZyraMembershipSection.current,
        ZyraMembershipSection.unlocks,
      ]) {
        final changed = original.copyWith(section: section);
        expect(
          ZyraMembershipReviewRequest.fromDraft(
            changed,
            currentProducts: {_one},
            paymentHistory: _paid,
          ),
          isNull,
        );
        expect(changed.seekerPage, 1);
        expect(changed.guardianPage, 1);
        expect(changed.familySeekers, 2);
        expect(changed.familyGuardians, 1);
        expect(changed.selectedProducts, original.selectedProducts);
      }
    },
  );

  testWidgets(
    'one swipeable pill strip separates information from role and Family choices',
    (tester) async {
      ZyraMembershipDraft? changed;
      final original = ZyraMembershipDraft(
        section: ZyraMembershipSection.current,
        seekerPage: 1,
        guardianPage: 1,
        familySeekers: 2,
        familyGuardians: 1,
        selectedProducts: [_basic, _guardianOne],
      );
      await pumpChoices(
        tester,
        draft: original,
        onChanged: (draft) => changed = draft,
        currentContent: const Text('Current-only account controls'),
        unlocksContent: const Text('Unlocks-only store content'),
      );
      await tester.pumpAndSettle();
      final strip = keyed('membership-section-slider');
      expect(strip, findsOneWidget);
      final position = sectionPosition(tester);
      expect(position.axis, Axis.horizontal);
      expect(position.maxScrollExtent, greaterThan(0));
      final pills = [
        for (final section in _sections)
          tester.getRect(keyed('membership-section-${section.name}')),
      ];
      for (var index = 0; index < pills.length; index++) {
        expect(pills[index].center.dy, closeTo(pills.first.center.dy, .1));
        if (index > 0) {
          expect(pills[index].left, greaterThan(pills[index - 1].right));
        }
      }
      expect(keyed('membership-current'), findsOneWidget);
      expect(find.text('Current-only account controls'), findsOneWidget);
      expect(keyed('membership-review-selection'), findsNothing);
      expect(find.byType(PageView), findsNothing);
      final beforeScroll = position.pixels;
      await tester.drag(strip, const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(beforeScroll));
      expect(changed, isNull, reason: 'Scrolling is not a section selection.');
      expect(keyed('membership-current'), findsOneWidget);
      await tapKey(tester, 'membership-section-unlocks');
      expect(keyed('membership-current'), findsNothing);
      expect(find.text('Current-only account controls'), findsNothing);
      expect(find.text('Unlocks-only store content'), findsOneWidget);
      expect(keyed('membership-review-selection'), findsNothing);
      expect(find.byType(PageView), findsNothing);
      expect(changed!.selectedProducts, original.selectedProducts);
      await tapKey(tester, 'membership-section-guardian');
      expect(find.text('2 / 2'), findsOneWidget);
      expect(keyed('membership-review-selection'), findsOneWidget);
      expect(find.text('Current membership'), findsNothing);
      expect(find.text('Current-only account controls'), findsNothing);
      await tapKey(tester, 'membership-section-seeker');
      expect(find.text('2 / 2'), findsOneWidget);
      await tapKey(tester, 'membership-section-family');
      expect(find.text('5% saving'), findsOneWidget);
      expect(changed!.familySeekers, 2);
      expect(changed!.familyGuardians, 1);
      expect(changed!.selectedProducts, original.selectedProducts);
      expect(changed!.seekerPage, original.seekerPage);
      expect(changed!.guardianPage, original.guardianPage);
      expect(tester.takeException(), isNull);
    },
  );

  for (final viewport in const [
    (size: Size(393, 852), scale: 1.0),
    (size: Size(320, 568), scale: 2.0),
  ]) {
    for (final initial in const [
      ZyraMembershipSection.guardian,
      ZyraMembershipSection.family,
      ZyraMembershipSection.unlocks,
    ]) {
      testWidgets(
        'initial ${initial.name} pill is visible in one full-size strip at ${viewport.size.width}/${viewport.scale}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final changes = <ZyraMembershipDraft>[];
            final original = ZyraMembershipDraft(
              section: initial,
              seekerPage: 1,
              guardianPage: 1,
              familySeekers: 2,
              familyGuardians: 1,
              selectedProducts: [_basic, _guardianOne],
            );
            await pumpChoices(
              tester,
              width: viewport.size.width,
              height: viewport.size.height,
              scale: viewport.scale,
              draft: original,
              currentContent: const Text('Current-only account controls'),
              unlocksContent: const Text('Unlocks-only store content'),
              onChanged: changes.add,
            );
            await tester.pumpAndSettle();
            final strip = keyed('membership-section-slider');
            final initialPill = keyed('membership-section-${initial.name}');
            final stripRect = tester.getRect(strip);
            expect(stripRect.contains(tester.getCenter(initialPill)), isTrue);
            expect(initialPill.hitTestable(), findsOneWidget);
            expect(selected(tester, initial), isTrue);
            for (final section in _sections.where((item) => item != initial)) {
              expect(selected(tester, section), isFalse);
            }
            final position = sectionPosition(tester);
            expect(position.axis, Axis.horizontal);
            expect(position.maxScrollExtent, greaterThan(0));
            final beforeScroll = position.pixels;
            final beforePage = initial == ZyraMembershipSection.guardian
                ? tester
                      .widget<PageView>(find.byType(PageView))
                      .controller!
                      .page
                : null;
            await tester.drag(strip, Offset(beforeScroll > 1 ? 180 : -180, 0));
            await tester.pumpAndSettle();
            expect(position.pixels, isNot(closeTo(beforeScroll, .1)));
            expect(changes, isEmpty);
            expect(selected(tester, initial), isTrue);
            if (beforePage != null) {
              expect(
                tester.widget<PageView>(find.byType(PageView)).controller!.page,
                closeTo(beforePage, .01),
              );
              expect(find.text('2 / 2'), findsOneWidget);
            } else if (initial == ZyraMembershipSection.family) {
              expect(find.text('5% saving'), findsOneWidget);
              expect(keyed('membership-family-total'), findsOneWidget);
            } else {
              expect(find.text('Unlocks-only store content'), findsOneWidget);
              expect(keyed('membership-review-selection'), findsNothing);
            }
            double? baseline;
            for (final section in _sections) {
              final pill = keyed('membership-section-${section.name}');
              await Scrollable.ensureVisible(
                tester.element(pill),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              final rect = tester.getRect(pill);
              expect(rect.width, greaterThanOrEqualTo(44));
              expect(rect.height, greaterThanOrEqualTo(44));
              expect(tester.getRect(strip).contains(rect.center), isTrue);
              expect(pill.hitTestable(), findsOneWidget);
              final label = find.descendant(
                of: pill,
                matching: find.text(_sectionLabels[section]!),
              );
              final text = tester.widget<Text>(label);
              expect(text.data, _sectionLabels[section]);
              expect(text.style!.fontSize, 12);
              expect(
                MediaQuery.textScalerOf(tester.element(label)).scale(12),
                12 * viewport.scale,
              );
              expect(
                find.descendant(of: pill, matching: find.byType(FittedBox)),
                findsNothing,
              );
              final rich = find.descendant(
                of: label,
                matching: find.byType(RichText),
              );
              final paragraph = tester.renderObject<RenderParagraph>(rich);
              expect(paragraph.didExceedMaxLines, isFalse);
              final lineTops = paragraph
                  .getBoxesForSelection(
                    TextSelection(
                      baseOffset: 0,
                      extentOffset: _sectionLabels[section]!.length,
                    ),
                  )
                  .map((box) => box.top)
                  .toSet();
              expect(lineTops.length, 1);
              final labelBaseline =
                  tester.getTopLeft(rich).dy +
                  paragraph.getDryBaseline(
                    paragraph.constraints,
                    TextBaseline.alphabetic,
                  )!;
              final expectedBaseline = baseline ?? labelBaseline;
              expect(labelBaseline, closeTo(expectedBaseline, .1));
              baseline = expectedBaseline;
              expect(changes, isEmpty);
              expect(selected(tester, initial), isTrue);
            }
            expect(original.selectedProducts, {_basic, _guardianOne});
            expect(original.seekerPage, 1);
            expect(original.guardianPage, 1);
            expect(original.familySeekers, 2);
            expect(original.familyGuardians, 1);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'header terms target is accessible and old callbacks fail closed',
    (tester) async {
      var allowed = true;
      var opened = 0;
      await pumpChoices(
        tester,
        width: 393,
        height: 852,
        draft: ZyraMembershipDraft(section: ZyraMembershipSection.current),
        onTerms: () => opened++,
        canAct: () => allowed,
      );
      final terms = keyed('membership-terms');
      final title = tester.getRect(find.text('Membership'));
      final termsRect = tester.getRect(terms);
      expect(termsRect.left, greaterThanOrEqualTo(title.right));
      expect(termsRect.right, lessThanOrEqualTo(393));
      expect(termsRect.center.dy, closeTo(title.center.dy, 1));
      expect(tester.getSize(terms).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(terms).height, greaterThanOrEqualTo(44));
      expect(find.byTooltip('Membership terms'), findsOneWidget);
      final old = tester.widget<IconButton>(terms).onPressed!;
      allowed = false;
      old();
      await tester.pump();
      expect(opened, 0);
      allowed = true;
      await tapKey(tester, 'membership-section-unlocks');
      old();
      await tester.pump();
      expect(opened, 0);
      await tapKey(tester, 'membership-terms');
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(393, 852), const Size(320, 568)]) {
    testWidgets('Current and Unlocks keep controls reachable at $size', (
      tester,
    ) async {
      await pumpChoices(
        tester,
        width: size.width,
        height: size.height,
        scale: size.width == 320 ? 2 : 1,
        draft: ZyraMembershipDraft(section: ZyraMembershipSection.current),
        currentContent: OutlinedButton(
          key: const ValueKey('current-only-cancel'),
          onPressed: () {},
          child: const Text('Cancel membership'),
        ),
        unlocksContent: const Text('Unlocks-only store content'),
      );
      await tester.ensureVisible(keyed('current-only-cancel'));
      await tester.pumpAndSettle();
      expect(keyed('current-only-cancel').hitTestable(), findsOneWidget);
      expect(keyed('membership-review-selection'), findsNothing);
      await tapKey(tester, 'membership-terms');
      await tapKey(tester, 'membership-section-unlocks');
      expect(find.text('Unlocks-only store content'), findsOneWidget);
      expect(find.text('Cancel membership'), findsNothing);
      expect(keyed('membership-review-selection'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  test('review excludes current products and unresolved Basic quotes', () {
    final draft = ZyraMembershipDraft(selectedProducts: [_one, _guardianBasic]);
    expect(
      ZyraMembershipReviewRequest.fromDraft(
        draft,
        currentProducts: {_one},
        paymentHistory: ZyraMembershipPaymentHistory.unknown,
      ),
      isNull,
    );
    final review = ZyraMembershipReviewRequest.fromDraft(
      draft,
      currentProducts: {_one},
      paymentHistory: _paid,
    )!;
    expect(review.kind, ZyraMembershipReviewKind.individual);
    expect(review.products, {_guardianBasic});
    expect(review.familyQuote, isNull);
    expect(() => review.products.clear(), throwsUnsupportedError);
  });

  test(
    'Family review contains only Family and canonical savings from 0 to 40%',
    () {
      for (var total = 0; total <= 20; total++) {
        final seekers = total.clamp(0, 10);
        final guardians = total - seekers;
        final draft = ZyraMembershipDraft(
          section: ZyraMembershipSection.family,
          familySeekers: seekers,
          familyGuardians: guardians,
          selectedProducts: [_basic, _guardianOne],
        );
        final review = ZyraMembershipReviewRequest.fromDraft(
          draft,
          currentProducts: {},
          paymentHistory: _paid,
        );
        if (total == 0) {
          expect(review, isNull);
          continue;
        }
        expect(review!.kind, ZyraMembershipReviewKind.family);
        expect(review.products, isEmpty);
        expect(
          review.familyQuote!.discountPercent,
          ((total - 2) * 5).clamp(0, 40),
        );
        expect(
          review.familyQuote!.formulaMonthlyPence,
          ZyraMembershipCatalog.familyQuote(
            seekers,
            guardians,
          ).formulaMonthlyPence,
        );
      }
    },
  );

  testWidgets('two-card Peek pager never swipes to another section', (
    tester,
  ) async {
    await pumpChoices(tester);
    final pager = tester.widget<PageView>(find.byType(PageView));
    expect(pager.controller!.viewportFraction, .94);
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-340, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-340, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(keyed('membership-pager-seeker'), findsOneWidget);
    expect(keyed('membership-pager-guardian'), findsNothing);
    expect(keyed('membership-family-total'), findsNothing);
    expect(outlined(tester, 'membership-review-selection').onPressed, isNull);
  });

  testWidgets('role pills remember their own One or Basic position', (
    tester,
  ) async {
    await pumpChoices(tester);
    await tester.drag(find.byType(PageView), const Offset(-340, 0));
    await tester.pumpAndSettle();
    await tapKey(tester, 'membership-section-guardian');
    expect(find.text('1 / 2'), findsOneWidget);
    await tapKey(tester, 'membership-section-seeker');
    expect(find.text('2 / 2'), findsOneWidget);
    await tapKey(tester, 'membership-section-family');
    expect(find.byType(PageView), findsNothing);
    expect(keyed('membership-previous'), findsNothing);
    expect(keyed('membership-next'), findsNothing);
    expect(find.text('0% saving'), findsOneWidget);
    await tapKey(tester, 'membership-section-guardian');
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('individual selection is per-role and has one combined review', (
    tester,
  ) async {
    ZyraMembershipDraft? changed;
    ZyraMembershipReviewRequest? reviewed;
    await pumpChoices(
      tester,
      onChanged: (draft) => changed = draft,
      onReview: (request) => reviewed = request,
    );
    await tester.drag(find.byType(PageView), const Offset(-340, 0));
    await tester.pumpAndSettle();
    await tapKey(tester, 'membership-select-seekerBasic');
    await tapKey(tester, 'membership-section-guardian');
    await tapKey(tester, 'membership-select-guardianOne');
    expect(changed!.selectedProducts, {_basic, _guardianOne});
    expect(find.text('Review selection'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
    await tapKey(tester, 'membership-review-selection');
    expect(reviewed!.products, {_basic, _guardianOne});
    expect(reviewed!.familyQuote, isNull);
  });

  testWidgets(
    'keeping current plan clears only that role and optional choice removes',
    (tester) async {
      ZyraMembershipDraft? changed;
      await pumpChoices(
        tester,
        draft: ZyraMembershipDraft(selectedProducts: [_basic, _guardianOne]),
        onChanged: (draft) => changed = draft,
      );
      await tapKey(tester, 'membership-select-seekerOne');
      expect(changed!.selectedProducts, {_guardianOne});
      await tapKey(tester, 'membership-section-guardian');
      await tapKey(tester, 'membership-remove-guardianOne');
      expect(changed!.selectedProducts, isEmpty);
      expect(outlined(tester, 'membership-review-selection').onPressed, isNull);
    },
  );

  for (final history in ZyraMembershipPaymentHistory.values) {
    testWidgets(
      'Basic reflects only explicit ${history.name} payment history',
      (tester) async {
        await pumpChoices(
          tester,
          draft: ZyraMembershipDraft(seekerPage: 1),
          history: history,
        );
        final label = ZyraMembershipCatalog.membershipPrice(
          _basic,
          history: history,
        );
        expect(find.text(label), findsOneWidget);
        final button = outlined(tester, 'membership-select-seekerBasic');
        expect(
          button.onPressed == null,
          history == ZyraMembershipPaymentHistory.unknown,
        );
      },
    );
  }

  testWidgets(
    'Family calculator has one review and respects limits and savings',
    (tester) async {
      ZyraMembershipReviewRequest? reviewed;
      ZyraMembershipDraft? changed;
      await pumpChoices(
        tester,
        draft: ZyraMembershipDraft(
          section: ZyraMembershipSection.family,
          familySeekers: 2,
          familyGuardians: 1,
          selectedProducts: [_basic],
        ),
        onChanged: (draft) => changed = draft,
        onReview: (request) => reviewed = request,
      );
      expect(find.text('£75.97'), findsOneWidget);
      expect(find.text('5% saving'), findsOneWidget);
      expect(find.text('Monthly total'), findsOneWidget);
      expect(find.text('Review selection'), findsOneWidget);
      await tapKey(tester, 'membership-family-guardian-plus');
      expect(changed!.familyGuardians, 2);
      expect(find.text('10% saving'), findsOneWidget);
      expect(find.text('£89.96'), findsOneWidget);
      await tapKey(tester, 'membership-review-selection');
      expect(reviewed!.products, isEmpty);
      expect(reviewed!.familyQuote!.members, 4);
      expect(find.textContaining('estimate'), findsNothing);
      expect(find.textContaining('own role'), findsNothing);
    },
  );

  testWidgets(
    'captured controls deny revoked authority and a new render epoch',
    (tester) async {
      var allowed = true;
      var changes = 0;
      await pumpChoices(
        tester,
        canAct: () => allowed,
        onChanged: (_) => changes++,
      );
      final oldGuardian = outlined(
        tester,
        'membership-section-guardian',
      ).onPressed!;
      final strip = keyed('membership-section-slider');
      final beforeScroll = sectionPosition(tester).pixels;
      await tester.drag(strip, const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(sectionPosition(tester).pixels, greaterThan(beforeScroll));
      expect(changes, 0);
      allowed = false;
      oldGuardian();
      await tester.pump();
      expect(changes, 0);
      allowed = true;
      await tapKey(tester, 'membership-section-family');
      expect(changes, 1);
      oldGuardian();
      await tester.pump();
      expect(changes, 1);
      expect(keyed('membership-family-total'), findsOneWidget);
      await tapKey(tester, 'membership-section-seeker');
      expect(changes, 2);
      oldGuardian();
      await tester.pump();
      expect(changes, 2);
      expect(keyed('membership-pager-seeker'), findsOneWidget);
      expect(keyed('membership-pager-guardian'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      oldGuardian();
      await tester.pump();
      expect(changes, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'current-products constructor defensively copies external facts',
    (tester) async {
      final external = <ZyraMembershipProduct>{_one};
      final widget = ZyraMembershipChoices(
        initialDraft: ZyraMembershipDraft(
          section: ZyraMembershipSection.current,
        ),
        currentProducts: external,
        paymentHistory: ZyraMembershipPaymentHistory.unknown,
        currentSummary: 'Guardian access active',
        onDraftChanged: (_) {},
        onReview: (_) {},
      );
      external.clear();
      expect(widget.currentProducts, {_one});
      expect(
        () => widget.currentProducts.add(_guardianOne),
        throwsUnsupportedError,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Guardian access active'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('£19.99 / month'), findsNothing);
    },
  );

  testWidgets(
    '320px at 200% text keeps personal and Family controls reachable',
    (tester) async {
      await pumpChoices(tester, width: 320, scale: 2);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(keyed('membership-review-selection'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'membership-section-family');
      await tapKey(tester, 'membership-family-guardian-plus');
      await tester.ensureVisible(keyed('membership-review-selection'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced-motion arrow pages immediately without changing section',
    (tester) async {
      await pumpChoices(tester, reduceMotion: true);
      await tester.ensureVisible(keyed('membership-next'));
      await tester.tap(keyed('membership-next'));
      await tester.pump();
      expect(find.text('2 / 2'), findsOneWidget);
      expect(keyed('membership-pager-seeker'), findsOneWidget);
      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      expect(controller.page!.round(), 1);
      expect(controller.position.isScrollingNotifier.value, isFalse);
      // Material's pressed-state ink can still schedule frames; it is not a
      // PageView transition and should not be mistaken for unwanted paging.
      await tester.pumpAndSettle();
    },
  );

  testWidgets('review stays read-only with store and final-price warnings', (
    tester,
  ) async {
    final request = ZyraMembershipReviewRequest.fromDraft(
      ZyraMembershipDraft(
        section: ZyraMembershipSection.family,
        familySeekers: 2,
        familyGuardians: 1,
      ),
      currentProducts: {},
      paymentHistory: _paid,
    )!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraMembershipReviewPresentation(
            request: request,
            paymentHistory: _paid,
          ),
        ),
      ),
    );
    expect(find.textContaining('final store price'), findsOneWidget);
    expect(keyed('membership-review-store-unavailable'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(
      find.textContaining('both roles require two places'),
      findsOneWidget,
    );
  });
}
