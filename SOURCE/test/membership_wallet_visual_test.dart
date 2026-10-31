// Actual Flutter component captures, not screenshots from a physical iPhone.
// Run normally for layout checks; PNG output is opt-in and exclusive.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_subscription_wallet_preview.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_membership_choices.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_MEMBERSHIP_WALLET_CAPTURE_DIR',
);
const _reviews =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/';
const _captureKey = ValueKey('membership-wallet-component-capture');
const _fontFamily = 'PoppinsMembershipWalletVisual';
const _paid = ZyraMembershipPaymentHistory.paidBefore;
const _seekerOne = ZyraMembershipProduct.seekerOne;
const _seekerBasic = ZyraMembershipProduct.seekerBasic;
const _guardianOne = ZyraMembershipProduct.guardianOne;

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Membership component captures must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

OutlinedButton _button(WidgetTester tester, String key) {
  final target = _key(key);
  if (target.evaluate().single.widget case final OutlinedButton button) {
    return button;
  }
  return tester.widget<OutlinedButton>(
    find.descendant(of: target, matching: find.byType(OutlinedButton)),
  );
}

void _validateCaptureDirectory() {
  if (_captureDirectory.isEmpty) return;
  const walletContinuation = 'OA305_QUIET_ACCESS_UNLOCKS_2026_10_22.91s79e';
  const walletCopyRefresh = 'OA305_COMPAT_SCAN_COPY_2026_10_22.LahQ4a';
  if (!_captureDirectory.startsWith(_reviews) ||
      !(RegExp(
            r'^OA305_(?:MEMBERSHIP_(?:WALLET|SECTIONS)|ROW_TAP_TARGETS|HALO_FOCUS_APP)_[A-Za-z0-9_.-]+/FRAMES$',
          ).hasMatch(_captureDirectory.substring(_reviews.length)) ||
          const {
            '$walletContinuation/FRAMES',
            '$walletContinuation/WORKING_WALLET_FRAMES',
            '$walletContinuation/WORKING_WALLET_FRAMES_2',
            '$walletCopyRefresh/FRAMES_WALLET',
          }.contains(_captureDirectory.substring(_reviews.length)))) {
    throw StateError('Captures require the owned review packet FRAMES folder.');
  }
  var path = '';
  for (final component in _captureDirectory.split('/').skip(1)) {
    if (component.isEmpty || component == '.' || component == '..') {
      throw StateError('Capture paths cannot contain aliases or traversal.');
    }
    path += '/$component';
    if (FileSystemEntity.typeSync(path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw StateError('Captures require existing non-symlink directories.');
    }
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  if (!RegExp(r'^[0-9]{2}-[a-z0-9-]+$').hasMatch(name)) {
    throw StateError('Capture names must be fixed local basenames.');
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    _validateCaptureDirectory();
    final output = File('$_captureDirectory/$name.png');
    await output.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  bool compact = false,
  Size? size,
}) async {
  tester.view.physicalSize =
      size ?? (compact ? const Size(320, 568) : const Size(393, 852));
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(compact ? 2 : 1),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SizedBox.expand(child: SafeArea(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _top(WidgetTester tester, String scrollKey) async {
  final scrollable = find
      .descendant(of: _key(scrollKey), matching: find.byType(Scrollable))
      .first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _walletFamilyPage(WidgetTester tester, int page) async {
  if (_key('wallet_family_pages').evaluate().isEmpty) {
    await _tap(tester, 'wallet_group_family');
  }
  int current() =>
      int.parse(
        tester
            .widget<Text>(_key('wallet_family_position'))
            .data!
            .split(' ')
            .first,
      ) -
      1;
  while (current() < page) {
    await _tap(tester, 'wallet_family_next');
  }
  while (current() > page) {
    await _tap(tester, 'wallet_family_previous');
  }
}

ScrollPosition _walletPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: _key('wallet_scroll'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
        ),
      ),
    )
    .position;

void _expectWholeIdentityWord(WidgetTester tester, String title, String word) {
  final text = find.text(title);
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: text, matching: find.byType(RichText)),
  );
  expect(title.startsWith(word), isTrue);
  final firstGlyph = paragraph.getBoxesForSelection(
    const TextSelection(baseOffset: 0, extentOffset: 1),
  );
  final wholeWord = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: word.length),
  );
  // A split word produces a box on each line. Its one complete box must also
  // share the first glyph's line, rather than merely fitting somewhere below.
  expect(firstGlyph, hasLength(1));
  expect(wholeWord, hasLength(1));
  expect(wholeWord.single.top, closeTo(firstGlyph.single.top, .001));
  expect(wholeWord.single.bottom, closeTo(firstGlyph.single.bottom, .001));
  expect(wholeWord.single.left, greaterThanOrEqualTo(-.001));
  expect(
    wholeWord.single.right,
    lessThanOrEqualTo(paragraph.size.width + .001),
  );
  expect(paragraph.didExceedMaxLines, isFalse);
}

Widget _choices({
  ZyraMembershipDraft? draft,
  ValueChanged<ZyraMembershipDraft>? onChanged,
  ValueChanged<ZyraMembershipReviewRequest>? onReview,
}) => ZyraMembershipChoices(
  initialDraft: draft,
  currentProducts: const {_seekerOne},
  paymentHistory: _paid,
  currentSummary: 'Seeker One',
  currentDetail: 'Covered by ZYRA Family · local example',
  onDraftChanged: onChanged ?? (_) {},
  onReview: onReview ?? (_) {},
  onTerms: () {},
  canAct: () => true,
  onBack: () {},
);

Widget _membershipSection(ZyraMembershipSection section) =>
    ZyraConceptMembershipPresentation(
      data: const ZyraConceptAccountData(
        guardian: false,
        name: 'Adam Khan',
        age: '30',
        gender: 'Male',
        location: 'London',
        membership: 'Seeker One',
        isOne: true,
        relationship: 'Father',
        linkedSeekers: '1',
        guardianCount: '2',
        signedInWith: 'Apple',
        backgroundLabel: 'Midnight Plum',
        hapticLabel: 'Subtle',
        gold: false,
        membershipPaymentHistory: _paid,
      ),
      initialDraft: ZyraMembershipDraft(section: section),
      currentDetail: 'Seeker One · ZYRA Family · local example',
      unlocksContent: const ZyraDraftCompatibilityStorePresentation(balance: 1),
      onAction: (_) {},
      onDraftChanged: (_) {},
      onReview: (_) {},
      onBack: () {},
      canAct: () => true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalHttp = HttpOverrides.current;
  final originalStubs = ZyraText.useTestFontStubs;
  final originalFamily = ZyraText.testReadingFontFamily;
  final originalPalette = ZyraColors.devPalette;
  late _NoNetwork network;

  setUpAll(() async {
    _validateCaptureDirectory();
    final reading = FontLoader(_fontFamily);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    ZyraColors.selectDevPalette(ZyraDevPalette.midnightPlum);
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _fontFamily;
    expect(ZyraMembershipCatalog.checkoutAvailable, isFalse);
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = originalHttp;
    ZyraText.useTestFontStubs = originalStubs;
    ZyraText.testReadingFontFamily = originalFamily;
    ZyraColors.selectDevPalette(originalPalette);
  });

  for (final compact in [false, true]) {
    testWidgets('component: Membership section slider compact=$compact', (
      tester,
    ) async {
      await _mount(
        tester,
        _membershipSection(ZyraMembershipSection.current),
        compact: compact,
      );
      final strip = _key('membership-section-slider');
      final scrollable = find.descendant(
        of: strip,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              axisDirectionToAxis(widget.axisDirection) == Axis.horizontal,
        ),
      );
      expect(scrollable, findsOneWidget);
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      final baseline = tester.getCenter(_key('membership-section-current')).dy;
      for (final section in ZyraMembershipSection.values) {
        final pill = _key('membership-section-${section.name}');
        expect(tester.getCenter(pill).dy, closeTo(baseline, .01));
        expect(tester.getSize(pill).height, greaterThanOrEqualTo(44));
        final text = find.descendant(of: pill, matching: find.byType(Text));
        expect(tester.widget<Text>(text).maxLines, 1);
        expect(
          tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
          isFalse,
        );
      }
      expect(_key('membership-current'), findsOneWidget);
      await _capture(
        tester,
        compact ? '17-membership-slider-320-200' : '15-membership-slider',
      );
      await tester.drag(strip, const Offset(-1200, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(_key('membership-current'), findsOneWidget);
      final family = _key('membership-section-family');
      expect(family.hitTestable(), findsOneWidget);
      await _capture(
        tester,
        compact
            ? '18-membership-slider-end-320-200'
            : '16-membership-slider-end',
      );
      await tester.tap(family);
      await tester.pumpAndSettle();
      expect(_key('membership-current'), findsNothing);
      expect(_key('membership-family-total'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final compact in [false, true]) {
    testWidgets('component: Profile row targets and arrows compact=$compact', (
      tester,
    ) async {
      final actions = <ZyraConceptAccountAction>[];
      await _mount(
        tester,
        ZyraConceptProfilePresentation(
          data: const ZyraConceptAccountData(
            guardian: false,
            name: 'Adam Khan',
            age: '30',
            gender: 'Male',
            location: 'London',
            membership: 'Seeker One',
            isOne: true,
            relationship: 'Father',
            linkedSeekers: '1',
            guardianCount: '2',
            signedInWith: 'Apple',
            backgroundLabel: 'Midnight Plum',
            hapticLabel: 'Subtle',
            gold: false,
            plusUnlocks: 1,
          ),
          onAction: actions.add,
          onSwitchRole: () {},
        ),
        compact: compact,
      );
      Future<Icon> arrow(String key) async {
        await tester.scrollUntilVisible(_key(key), 120);
        await tester.pumpAndSettle();
        return tester.widget<Icon>(
          find.descendant(
            of: _key(key),
            matching: find.byIcon(Icons.chevron_right_rounded),
          ),
        );
      }

      final membership = await arrow('membership-manage');
      final subscriptions = await arrow('concept_subscriptions');
      final unlocks = await arrow('concept_compatibility_buy_more');
      expect(membership.color, subscriptions.color);
      expect(membership.color, unlocks.color);
      expect(membership.size, subscriptions.size);
      expect(membership.size, unlocks.size);
      final title = find.text('Compatibility unlocks');
      if (compact) {
        await Scrollable.ensureVisible(tester.element(title), alignment: .3);
        await tester.pumpAndSettle();
      }
      expect(title.hitTestable(), findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
        isFalse,
      );
      await _capture(
        tester,
        compact
            ? '14-profile-row-320-200-component'
            : '13-profile-row-component',
      );
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(actions, [ZyraConceptAccountAction.compatibilityStore]);
      await _tap(tester, 'concept_compatibility_buy_more');
      expect(actions, [
        ZyraConceptAccountAction.compatibilityStore,
        ZyraConceptAccountAction.compatibilityStore,
      ]);
      expect(find.text('1  Unlocks', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('component: Current membership exposes cancellation at opening', (
    tester,
  ) async {
    await _mount(tester, _membershipSection(ZyraMembershipSection.current));
    expect(_key('membership-current'), findsOneWidget);
    expect(_key('membership-halo-seekerOne'), findsNothing);
    expect(_key('membership-review-selection'), findsNothing);
    final cancel = _key('concept_cancel_membership');
    expect(cancel.hitTestable(), findsOneWidget);
    expect(tester.getRect(cancel).bottom, lessThanOrEqualTo(852 - 34));
    expect(find.byTooltip('Membership terms'), findsOneWidget);
    await _capture(tester, '11-current-membership-component');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'component: inline Halo focus keeps read-only balance and permanent access information',
    (tester) async {
      await _mount(tester, _membershipSection(ZyraMembershipSection.unlocks));
      expect(_key('membership-current'), findsNothing);
      expect(_key('concept_cancel_membership'), findsNothing);
      expect(_key('membership-review-selection'), findsNothing);
      expect(
        find.byType(ZyraDraftCompatibilityStorePresentation),
        findsOneWidget,
      );
      expect(find.text('Unlocks remaining'), findsNothing);
      expect(
        tester
            .widget<Text>(_key('draft_compatibility_store_balance_count'))
            .data,
        '1',
      );
      expect(_key('draft_compatibility_store_use_unlocks'), findsNothing);
      expect(find.text('See your overall match score'), findsNothing);
      expect(
        tester.getRect(_key('draft_compatibility_store_title')).top,
        greaterThanOrEqualTo(
          tester.getRect(_key('membership-section-slider')).bottom + 18,
        ),
        reason: 'Inline Unlocks must not cover the role and Family pills.',
      );
      await _capture(tester, '12-inline-unlocks-component');
      expect(_key('draft_compatibility_store_info_dialog'), findsNothing);
      expect(find.text('Your match, revealed'), findsOneWidget);
      expect(find.text('1 / 8'), findsOneWidget);
      await _tap(tester, 'draft_compatibility_store_unlock_three');
      expect(
        tester
            .widget<FilledButton>(_key('draft_compatibility_store_continue'))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('£6.99'), findsWidgets);
      expect(find.text('£2.33 each'), findsOneWidget);
      expect(find.text(' · Purchasing isn’t available yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('component: Seeker One current Peek halo', (tester) async {
    await _mount(tester, _choices());
    expect(_key('membership-halo-seekerOne'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(_button(tester, 'membership-review-selection').onPressed, isNull);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
    await _capture(tester, '01-seeker-one-current-component');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'component: paid-before Basic selects without another joining fee',
    (tester) async {
      ZyraMembershipDraft? changed;
      ZyraMembershipReviewRequest? reviewed;
      await _mount(
        tester,
        _choices(
          draft: ZyraMembershipDraft(seekerPage: 1),
          onChanged: (draft) => changed = draft,
          onReview: (request) => reviewed = request,
        ),
      );
      expect(_key('membership-halo-seekerBasic'), findsOneWidget);
      expect(find.text('No joining fee'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
      await _capture(tester, '02-seeker-basic-paid-component');
      await _tap(tester, 'membership-select-seekerBasic');
      expect(changed!.selectedProducts, {_seekerBasic});
      await _tap(tester, 'membership-review-selection');
      expect(reviewed!.products, {_seekerBasic});
      expect(reviewed!.familyQuote, isNull);
    },
  );

  testWidgets('component: Guardian One has its own two-card role pager', (
    tester,
  ) async {
    await _mount(
      tester,
      _choices(
        draft: ZyraMembershipDraft(section: ZyraMembershipSection.guardian),
      ),
    );
    expect(_key('membership-halo-guardianOne'), findsOneWidget);
    expect(_key('membership-pager-seeker'), findsNothing);
    expect(find.text('£19.99'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    await _capture(tester, '03-guardian-one-component');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'component: Family two Seekers and one Guardian uses canonical saving',
    (tester) async {
      ZyraMembershipDraft? changed;
      ZyraMembershipReviewRequest? reviewed;
      await _mount(
        tester,
        _choices(
          draft: ZyraMembershipDraft(
            section: ZyraMembershipSection.family,
            familySeekers: 2,
            familyGuardians: 1,
          ),
          onChanged: (draft) => changed = draft,
          onReview: (request) => reviewed = request,
        ),
      );
      expect(find.byType(PageView), findsNothing);
      expect(find.text('5% saving'), findsOneWidget);
      expect(find.text('Monthly total'), findsOneWidget);
      final quote = ZyraMembershipCatalog.familyQuote(2, 1);
      expect(
        find.text(ZyraMembershipCatalog.pounds(quote.formulaMonthlyPence)),
        findsOneWidget,
      );
      await _tap(tester, 'membership-family-guardian-plus');
      expect(changed!.familyGuardians, 2);
      expect(find.text('10% saving'), findsOneWidget);
      await _tap(tester, 'membership-family-guardian-minus');
      expect(changed!.familyGuardians, 1);
      expect(find.text('5% saving'), findsOneWidget);
      await _top(tester, 'membership-choices-scroll');
      await _capture(tester, '04-family-two-plus-one-component');
      await _tap(tester, 'membership-review-selection');
      expect(reviewed!.kind, ZyraMembershipReviewKind.family);
      expect(reviewed!.products, isEmpty);
      expect(
        reviewed!.familyQuote!.formulaMonthlyPence,
        quote.formulaMonthlyPence,
      );
    },
  );

  testWidgets('component: individual review remains read-only', (tester) async {
    final request = ZyraMembershipReviewRequest.fromDraft(
      ZyraMembershipDraft(selectedProducts: [_seekerBasic, _guardianOne]),
      currentProducts: {_seekerOne},
      paymentHistory: _paid,
    )!;
    await _mount(
      tester,
      ZyraMembershipReviewPresentation(
        request: request,
        paymentHistory: _paid,
        canAct: () => true,
        onBack: () {},
      ),
    );
    expect(find.text('Review selection'), findsOneWidget);
    expect(find.text('No joining fee'), findsOneWidget);
    expect(_key('membership-review-store-unavailable'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    await _capture(tester, '05-individual-review-component');
    expect(tester.takeException(), isNull);
  });

  testWidgets('component: Family review never merges individual changes', (
    tester,
  ) async {
    final draft = ZyraMembershipDraft(
      section: ZyraMembershipSection.family,
      familySeekers: 2,
      familyGuardians: 1,
      selectedProducts: [_seekerBasic, _guardianOne],
    );
    final request = ZyraMembershipReviewRequest.fromDraft(
      draft,
      currentProducts: {_seekerOne},
      paymentHistory: _paid,
    )!;
    await _mount(
      tester,
      ZyraMembershipReviewPresentation(
        request: request,
        paymentHistory: _paid,
        canAct: () => true,
        onBack: () {},
      ),
    );
    expect(request.products, isEmpty);
    expect(find.text('2 Seeker One places'), findsOneWidget);
    expect(find.text('1 Guardian One place'), findsOneWidget);
    expect(find.text('5% saving'), findsOneWidget);
    expect(find.text('No joining fee'), findsNothing);
    await _capture(tester, '06-family-review-component');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'component: Profile subscription wallet shows separate role coverage',
    (tester) async {
      await _mount(
        tester,
        ZyraSubscriptionWalletPreview(
          draft: ZyraSubscriptionWalletDraft.sample(),
          showBackButton: false,
          onChanged: (_) => fail('Merely viewing cannot assign a place.'),
          onSwitch: (_) => fail('Merely viewing cannot switch a role.'),
          onSetup: (_) => fail('Merely viewing cannot start setup.'),
          onMembership: (_) => fail('Merely viewing cannot buy membership.'),
          onBack: () {},
          canAct: () => true,
        ),
      );
      expect(find.text('Your subscriptions'), findsOneWidget);
      expect(find.text('Seeker One · ZYRA Family'), findsOneWidget);
      expect(_key('wallet_role_seeker'), findsOneWidget);
      final seekerCard =
          tester.widget<Container>(_key('wallet_role_seeker')).decoration!
              as BoxDecoration;
      expect(seekerCard.color, ZyraColors.surfaceFill);
      expect(
        (seekerCard.border! as Border).top.color,
        ZyraColors.journeyGold.withValues(alpha: .5),
      );
      expect(_key('wallet_identity_seeker_row'), findsOneWidget);
      _expectWholeIdentityWord(tester, 'Seeker profile', 'Seeker');
      expect(find.text('Sample'), findsNothing);
      expect(_walletPosition(tester).maxScrollExtent, 0);
      await _capture(tester, '07-subscription-wallet-top-component');
      await _tap(tester, 'wallet_profiles_next');
      expect(find.text('Guardian One · Individual'), findsOneWidget);
      expect(_key('wallet_role_guardian'), findsOneWidget);
      expect(
        (tester.widget<Container>(_key('wallet_role_guardian')).decoration!
                as BoxDecoration)
            .color,
        ZyraColors.surfaceFill,
      );
      expect(_walletPosition(tester).maxScrollExtent, 0);
      await _capture(tester, '19-subscription-wallet-guardian-halo');
      await _walletFamilyPage(tester, 1);
      expect(find.text('2 places available'), findsOneWidget);
      expect(
        (tester
                    .widget<Container>(_key('wallet_place_sample-spare-seeker'))
                    .decoration!
                as BoxDecoration)
            .color,
        ZyraColors.surfaceFill,
      );
      expect(_walletPosition(tester).maxScrollExtent, 0);
      await _capture(tester, '20-subscription-family-available-halo');
      await _walletFamilyPage(tester, 4);
      expect(
        find.text('Not active · awaiting recipient agreement'),
        findsOneWidget,
      );
      await _capture(tester, '21-subscription-family-pending-halo');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'component: spare-place confirmation is local and invitation stays pending',
    (tester) async {
      var draft = ZyraSubscriptionWalletDraft.sample();
      await _mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => ZyraSubscriptionWalletPreview(
            draft: draft,
            showBackButton: false,
            onChanged: (next) => setState(() => draft = next),
            onSwitch: (_) => fail('Assignment cannot switch a role.'),
            onSetup: (_) => fail('Assignment cannot start setup.'),
            onMembership: (_) => fail('Assignment cannot buy membership.'),
            onBack: () {},
            canAct: () => true,
          ),
        ),
      );
      await _walletFamilyPage(tester, 2);
      await _tap(tester, 'wallet_assign_sample-spare-guardian');
      final confirm = _key('wallet_confirm');
      await Scrollable.ensureVisible(tester.element(confirm), alignment: .5);
      await tester.pumpAndSettle();
      expect(find.text('Assign this Guardian place?'), findsOneWidget);
      expect(find.text('Preview invitation'), findsOneWidget);
      expect(draft.availableFor(ZyraWalletRole.guardian), hasLength(1));
      await _capture(tester, '08-spare-place-confirmation-component');
      await _tap(tester, 'wallet_confirm');
      final assigned = draft.places.singleWhere(
        (place) => place.id == 'sample-spare-guardian',
      );
      expect(assigned.state, ZyraWalletPlaceState.invitationPending);
      expect(assigned.recipient, 'Omar');
      expect(draft.guardian.coverage, ZyraWalletCoverage.individualOne);
      expect(draft.availableFor(ZyraWalletRole.guardian), isEmpty);
      await _top(tester, 'wallet_scroll');
      await _capture(tester, '22-subscription-family-invitation-pending');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('component: wallet halo remains accessible on a 430px phone', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(
        tester,
        ZyraSubscriptionWalletPreview(
          draft: ZyraSubscriptionWalletDraft.sample(),
          showBackButton: false,
          onChanged: (_) => fail('Paging cannot allocate a place.'),
          onSwitch: (_) => fail('Paging cannot switch a role.'),
          onSetup: (_) => fail('Paging cannot start setup.'),
          onMembership: (_) => fail('Paging cannot purchase.'),
        ),
        size: const Size(430, 932),
      );
      expect(_key('wallet_back'), findsNothing);
      for (final group in ['profiles', 'family']) {
        await _tap(tester, 'wallet_group_$group');
        final count = group == 'profiles' ? 2 : 6;
        for (var page = 0; page < count; page++) {
          expect(_walletPosition(tester).maxScrollExtent, 0);
          for (final direction in ['previous', 'next']) {
            final arrow = _key('wallet_${group}_$direction');
            expect(tester.getSize(arrow), const Size(44, 44));
            expect(tester.widget<IconButton>(arrow).tooltip, isNotEmpty);
          }
          final position = _key('wallet_${group}_position');
          expect(
            tester.getSemantics(position).getSemanticsData().label,
            '${group == 'profiles' ? 'Profile' : 'Family place'} ${page + 1} of $count',
          );
          final active = tester.widget<AnimatedContainer>(
            _key('wallet_${group}_dot_$page'),
          );
          expect(active.constraints!.minWidth, 30);
          expect(find.text('Sample'), findsNothing);
          expect(find.textContaining('(sample)'), findsNothing);
          if (page < count - 1) await _tap(tester, 'wallet_${group}_next');
        }
      }
      await _capture(tester, '23-subscription-wallet-430-family-funded');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'component: wallet halo natural 200 percent fallback on the member background',
    (tester) async {
      var draft = ZyraSubscriptionWalletDraft.sample();
      await _mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => ZyraSubscriptionWalletPreview(
            draft: draft,
            showBackButton: false,
            onChanged: (next) => setState(() => draft = next),
            onSwitch: (_) => fail('Assignment cannot switch a role.'),
            onSetup: (_) => fail('Assignment cannot start setup.'),
            onMembership: (_) => fail('Assignment cannot buy membership.'),
          ),
        ),
        compact: true,
      );
      expect(_walletPosition(tester).maxScrollExtent, greaterThan(0));
      expect(find.byType(FittedBox), findsNothing);
      expect(_key('wallet_identity_seeker_stacked'), findsOneWidget);
      _expectWholeIdentityWord(tester, 'Seeker profile', 'Seeker');
      await _capture(tester, '24-subscription-wallet-320-200');
      await _walletFamilyPage(tester, 2);
      expect(_key('wallet_identity_guardian_stacked'), findsOneWidget);
      _expectWholeIdentityWord(tester, 'Guardian One', 'Guardian');
      await _tap(tester, 'wallet_assign_sample-spare-guardian');
      expect(
        find.descendant(
          of: _key('wallet_place_sample-spare-guardian'),
          matching: _key('wallet_confirmation'),
        ),
        findsOneWidget,
      );
      await Scrollable.ensureVisible(
        tester.element(_key('wallet_confirmation')),
        alignment: 0,
      );
      await tester.pumpAndSettle();
      await _capture(tester, '25-subscription-family-320-200-confirmation');
      await _tap(tester, 'wallet_confirm');
      expect(draft.places[2].state, ZyraWalletPlaceState.invitationPending);
      expect(draft.guardian.coverage, ZyraWalletCoverage.individualOne);
      expect(
        find.text('Not active · awaiting recipient agreement'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'component: covered Switch reader fits 320px at 200% without repurchase',
    (tester) async {
      final switched = <ZyraWalletRole>[];
      await _mount(
        tester,
        ZyraSubscriptionSwitchPreview(
          draft: ZyraSubscriptionWalletDraft.sample(),
          currentRole: ZyraWalletRole.seeker,
          onChanged: (_) =>
              fail('Covered switching cannot allocate another place.'),
          onSwitch: switched.add,
          onSetup: (_) => fail('A ready covered role needs no setup.'),
          onMembership: (_) =>
              fail('A covered role cannot require repurchase.'),
          onBack: () {},
          canAct: () => true,
        ),
        compact: true,
      );
      final button = _key('wallet_primary_guardian');
      await Scrollable.ensureVisible(tester.element(button), alignment: .5);
      await tester.pumpAndSettle();
      expect(find.text('Switch to Guardian'), findsOneWidget);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Switch to Guardian'))
            .didExceedMaxLines,
        isFalse,
      );
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      await _capture(tester, '09-covered-switch-320-200-component');
      await _tap(tester, 'wallet_primary_guardian');
      expect(switched, [ZyraWalletRole.guardian]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'component: covered missing profile offers setup without another membership',
    (tester) async {
      final setup = <ZyraWalletRole>[];
      await _mount(
        tester,
        ZyraSubscriptionSwitchPreview(
          draft: ZyraSubscriptionWalletDraft.sample().withRole(
            ZyraWalletRole.guardian,
            readiness: ZyraWalletReadiness.missing,
          ),
          currentRole: ZyraWalletRole.seeker,
          onChanged: (_) =>
              fail('Setup preview cannot allocate another place.'),
          onSwitch: (_) => fail('A missing profile cannot be switched into.'),
          onSetup: setup.add,
          onMembership: (_) => fail('Covered setup cannot require repurchase.'),
          onBack: () {},
          canAct: () => true,
        ),
      );
      expect(find.text('Finish Guardian setup'), findsOneWidget);
      expect(find.text('Profile not set up'), findsOneWidget);
      expect(find.text('Guardian One · Individual'), findsOneWidget);
      await _capture(tester, '10-covered-missing-profile-component');
      await _tap(tester, 'wallet_primary_guardian');
      expect(setup, [ZyraWalletRole.guardian]);
      expect(tester.takeException(), isNull);
    },
  );
}
