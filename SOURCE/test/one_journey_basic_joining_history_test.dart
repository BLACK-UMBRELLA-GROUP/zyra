// Payment-history examples are local presentation, never purchase proof.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_membership_choices.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsBasicJoiningHistory';
const _captures = String.fromEnvironment('ZYRA_BASIC_JOINING_CAPTURE_DIR');
const _captureKey = ValueKey('basic-joining-history-capture');
const _basics = [
  ZyraMembershipProduct.seekerBasic,
  ZyraMembershipProduct.guardianBasic,
];
const _oneWithoutPaymentProof = ZyraConceptAccountData(
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
  signedInWith: 'Google',
  backgroundLabel: 'Midnight Plum',
  hapticLabel: 'Subtle',
  gold: false,
);

ZyraConceptAccountData _data(
  ZyraMembershipPaymentHistory history, {
  bool guardian = false,
}) => ZyraConceptAccountData(
  guardian: guardian,
  name: guardian ? 'Hassan Rahman' : 'Adam Khan',
  age: guardian ? '54' : '30',
  gender: 'Male',
  location: 'London',
  membership: guardian ? 'Guardian One' : 'Seeker One',
  isOne: true,
  relationship: 'Father',
  linkedSeekers: '1',
  guardianCount: '2',
  signedInWith: 'Google',
  backgroundLabel: 'Midnight Plum',
  hapticLabel: 'Subtle',
  gold: false,
  membershipPaymentHistory: history,
);

Finder _key(String value) => find.byKey(ValueKey(value));

Finder _selection(ZyraMembershipProduct product) =>
    _key('membership-select-${product.name}');

OutlinedButton _button(WidgetTester tester, Finder target) =>
    tester.widget<OutlinedButton>(
      find.descendant(of: target, matching: find.byType(OutlinedButton)),
    );

Future<void> _showBasic(
  WidgetTester tester,
  ZyraMembershipProduct product,
) async {
  final role = product == ZyraMembershipProduct.seekerBasic
      ? 'seeker'
      : 'guardian';
  await _tap(tester, _key('membership-section-$role'));
  final next = _key('membership-next');
  if (tester.widget<IconButton>(next).onPressed != null) {
    await _tap(tester, next);
  }
  expect(find.text('2 / 2'), findsOneWidget);
  await _reveal(tester, _selection(product));
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Joining-fee examples must remain offline.');
  }
}

Widget _app(Widget home, {bool compact = false}) => MaterialApp(
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
      child: home,
    ),
  ),
);

void _size(WidgetTester tester, {bool compact = false}) {
  tester.view.physicalSize = compact
      ? const Size(320, 568)
      : const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final owner = [
      'dev_controls_scroll',
      'concept-current-profile-scroll',
      'membership-choices-scroll',
      'concept_account_action_scroll',
      'wallet_switch_scroll',
    ].map(_key).firstWhere((finder) => finder.evaluate().isNotEmpty);
    final scroller = find
        .descendant(of: owner, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      target,
      150,
      scrollable: scroller,
      maxScrolls: 35,
    );
  }
  expect(target, findsOneWidget);
  final ancestor = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (ancestor.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, String label) async {
  final navigation = find.byType(ZyraShellNavigation);
  expect(navigation, findsOneWidget);
  final item = tester
      .widget<ZyraShellNavigation>(navigation)
      .items
      .singleWhere((item) => item.label == label);
  final icon = find.descendant(
    of: navigation,
    matching: find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  final target = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(target.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _component(
  WidgetTester tester,
  ZyraConceptAccountData data, {
  bool compact = false,
  ValueChanged<ZyraMembershipDraft>? onDraft,
}) async {
  _size(tester, compact: compact);
  await tester.pumpWidget(
    _app(
      ZyraConceptMembershipPresentation(
        key: UniqueKey(),
        data: data,
        showBackButton: false,
        onAction: (_) {},
        onDraftChanged: onDraft ?? (_) {},
        onReview: (_) {},
        onBack: () {},
      ),
      compact: compact,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _expectBasicQuote(
  WidgetTester tester,
  ZyraMembershipProduct product,
  ZyraMembershipPaymentHistory history,
) async {
  await _showBasic(tester, product);
  final card = find
      .ancestor(of: _selection(product), matching: find.byType(Column))
      .first;
  final quote = find.descendant(
    of: card,
    matching: find.text(
      ZyraMembershipCatalog.membershipPrice(product, history: history),
    ),
  );
  expect(quote, findsOneWidget);
  expect(_selection(product), findsOneWidget);
  final onPressed = _button(tester, _selection(product)).onPressed;
  if (history == ZyraMembershipPaymentHistory.unknown) {
    expect(onPressed, isNull);
  } else {
    expect(onPressed, isNotNull);
  }
  expect(tester.takeException(), isNull);
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  final roles = <bool>[];
  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(WidgetTester tester, {bool guardian = false}) async {
    _size(tester);
    final ready = Completer<void>();
    await tester.pumpWidget(
      _app(
        ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () => fail('Joining-fee review stays inside its owner.'),
          initialGuardianRole: guardian,
          initialCheckpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: ViewRequestDraftModel(capacity: 3).snapshot(),
            tab: guardian ? 3 : 4,
            pages: const [],
          ),
          onRoleChanged: roles.add,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }
}

ZyraConceptAccountData _shownData(WidgetTester tester) => tester
    .widget<ZyraConceptMembershipPresentation>(
      find.byType(ZyraConceptMembershipPresentation),
    )
    .data;

Object _modelFacts(ZyraPreviewNavigationCheckpoint value) => [
  value.model.capacity,
  value.model.states,
  value.model.busyPeers,
  value.model.hiddenPeers,
  value.model.blockedPeers,
  value.model.acknowledgedReceivedRequestIds,
  value.model.progress,
  value.model.peerMainGuardianOverrides,
  value.model.guardianMemberships,
  value.model.guardianAccess,
  value.model.ownMainGuardianPresent,
  value.model.peerMainGuardianPresent,
  value.seekerMembership,
  value.guardianMembership,
];

Future<void> _history(
  WidgetTester tester,
  ZyraMembershipPaymentHistory history,
) async {
  await openZyraDevControls(tester);
  await _tap(tester, _key('concept_membership_history_${history.name}'));
  await closeZyraDevControls(tester);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldHttp = HttpOverrides.current;
  final oldStubs = ZyraText.useTestFontStubs;
  final oldFamily = ZyraText.testReadingFontFamily;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;

  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  List<Object?> memberState() => [
    AppState.instance.name,
    AppState.instance.gender,
    AppState.instance.dob,
    AppState.instance.location,
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
  ];

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError('Capture output must be an absolute directory.');
      }
      var path = '';
      for (final component
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (component == '.' || component == '..') {
          throw StateError('Capture aliases are not accepted.');
        }
        path += '/$component';
        if (FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError('Captures require existing nonlinked directories.');
        }
      }
    }
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'joining-fee-sentinel': 'keep'});
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    beforePreferences = preferenceState();
    beforeMember = memberState();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });

  tearDown(() {
    expect(network.attempts, 0);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMember);
    HttpOverrides.global = oldHttp;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFamily;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final guardian in [false, true]) {
    for (final history in ZyraMembershipPaymentHistory.values) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} Basic quote uses ${history.name}, not the current One label',
        (tester) async {
          ZyraMembershipDraft? selected;
          await _component(
            tester,
            _data(history, guardian: guardian),
            onDraft: (draft) => selected = draft,
          );
          for (final product in _basics) {
            await _expectBasicQuote(tester, product, history);
            if (history != ZyraMembershipPaymentHistory.unknown) {
              await _tap(tester, _selection(product));
            }
          }
          expect(
            selected?.selectedProducts ?? <ZyraMembershipProduct>{},
            history == ZyraMembershipPaymentHistory.unknown
                ? isEmpty
                : unorderedEquals(_basics),
          );
          if (!guardian) {
            await _showBasic(tester, ZyraMembershipProduct.seekerBasic);
            await _capture(tester, switch (history) {
              ZyraMembershipPaymentHistory.paidBefore => '01-paid-membership',
              ZyraMembershipPaymentHistory.neverPaid => '02-never-paid',
              ZyraMembershipPaymentHistory.unknown => '03-history-unknown',
            });
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} paid Basic quote remains readable at 320px200%',
      (tester) async {
        await _component(
          tester,
          _data(ZyraMembershipPaymentHistory.paidBefore, guardian: guardian),
          compact: true,
        );
        for (final product in _basics) {
          await _expectBasicQuote(
            tester,
            product,
            ZyraMembershipPaymentHistory.paidBefore,
          );
          final text = find.descendant(
            of: find
                .ancestor(
                  of: _selection(product),
                  matching: find.byType(Column),
                )
                .first,
            matching: find.text('No joining fee'),
          );
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(tester.widget<Text>(text).maxLines, isNull);
          await _reveal(tester, _selection(product));
        }
        if (!guardian) {
          await _showBasic(tester, ZyraMembershipProduct.seekerBasic);
          await _capture(tester, '04-paid-compact-200');
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} paid draft clears Basic when history changes, with no model write',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, guardian: guardian);
        final before = _modelFacts(owner.latest);
        await _tap(tester, _key('concept_membership'));
        expect(
          _shownData(tester).membershipPaymentHistory,
          ZyraMembershipPaymentHistory.paidBefore,
        );
        final basic = guardian
            ? ZyraMembershipProduct.guardianBasic
            : ZyraMembershipProduct.seekerBasic;
        await _expectBasicQuote(
          tester,
          basic,
          ZyraMembershipPaymentHistory.paidBefore,
        );
        await _tap(tester, _selection(basic));
        await _tap(tester, _key('membership-review-selection'));
        final paidReview = tester.widget<ZyraMembershipReviewPresentation>(
          find.byType(ZyraMembershipReviewPresentation),
        );
        expect(paidReview.request.products, {basic});
        expect(find.text('No joining fee'), findsOneWidget);
        expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
        expect(owner.latest.pages.last, 'membership_review');
        await returnZyraPreviewPage(tester);
        await _history(tester, ZyraMembershipPaymentHistory.neverPaid);
        expect(
          _button(tester, _key('membership-review-selection')).onPressed,
          isNull,
        );
        await _expectBasicQuote(
          tester,
          basic,
          ZyraMembershipPaymentHistory.neverPaid,
        );
        await _tap(tester, _selection(basic));
        await _tap(tester, _key('membership-review-selection'));
        final firstPaymentReview = tester
            .widget<ZyraMembershipReviewPresentation>(
              find.byType(ZyraMembershipReviewPresentation),
            );
        expect(firstPaymentReview.request.products, {basic});
        expect(find.text('£4.99 once'), findsOneWidget);
        await returnZyraPreviewPage(tester);
        await _history(tester, ZyraMembershipPaymentHistory.unknown);
        expect(
          _button(tester, _key('membership-review-selection')).onPressed,
          isNull,
        );
        await _expectBasicQuote(
          tester,
          basic,
          ZyraMembershipPaymentHistory.unknown,
        );
        expect(owner.roles, isEmpty);
        expect(_modelFacts(owner.latest), before);
        expect(ZyraMembershipCatalog.checkoutAvailable, isFalse);
      },
    );
  }

  testWidgets(
    'a default One presentation is not prior membership payment proof',
    (tester) async {
      expect(_oneWithoutPaymentProof.isOne, isTrue);
      expect(
        _oneWithoutPaymentProof.membershipPaymentHistory,
        ZyraMembershipPaymentHistory.unknown,
      );
      await _component(tester, _oneWithoutPaymentProof);
      for (final product in _basics) {
        await _expectBasicQuote(
          tester,
          product,
          ZyraMembershipPaymentHistory.unknown,
        );
      }
    },
  );

  testWidgets(
    'payment-history control cannot replay after closing, revision or owner revocation',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      await _tap(tester, _key('concept_membership'));
      await openZyraDevControls(tester);
      final paid = _key('concept_membership_history_paidBefore');
      await _reveal(tester, paid);
      final oldPaid = tester.widget<OutlinedButton>(paid).onPressed!;
      await _tap(tester, _key('concept_membership_history_neverPaid'));
      oldPaid();
      await tester.pumpAndSettle();
      await closeZyraDevControls(tester);
      expect(
        _shownData(tester).membershipPaymentHistory,
        ZyraMembershipPaymentHistory.neverPaid,
      );
      oldPaid();
      await tester.pumpAndSettle();
      expect(
        _shownData(tester).membershipPaymentHistory,
        ZyraMembershipPaymentHistory.neverPaid,
      );
      await openZyraDevControls(tester);
      await _reveal(tester, paid);
      final denied = tester.widget<OutlinedButton>(paid).onPressed!;
      final count = owner.checkpoints.length;
      owner.allowed = false;
      denied();
      await tester.pump();
      expect(owner.checkpoints.length, count);
      expect(owner.roles, isEmpty);
    },
  );

  testWidgets(
    'saved membership draft and review cannot replay under controls, a new quote or revoked owner',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      await _tap(tester, _key('concept_membership'));
      final before = _modelFacts(owner.latest);
      final first = tester.widget<ZyraConceptMembershipPresentation>(
        find.byType(ZyraConceptMembershipPresentation),
      );
      final staleDraft = ZyraMembershipDraft(
        seekerPage: 1,
        selectedProducts: [ZyraMembershipProduct.seekerBasic],
      );
      final staleReview = ZyraMembershipReviewRequest.fromDraft(
        staleDraft,
        currentProducts: {ZyraMembershipProduct.seekerOne},
        paymentHistory: ZyraMembershipPaymentHistory.paidBefore,
      )!;
      await openZyraDevControls(tester);
      first.onDraftChanged(staleDraft);
      first.onReview(staleReview);
      await tester.pumpAndSettle();
      expect(owner.latest.pages, ['membership']);
      await _tap(tester, _key('concept_membership_history_neverPaid'));
      await closeZyraDevControls(tester);
      first.onDraftChanged(staleDraft);
      first.onReview(staleReview);
      await tester.pumpAndSettle();
      final current = tester.widget<ZyraConceptMembershipPresentation>(
        find.byType(ZyraConceptMembershipPresentation),
      );
      expect(current.initialDraft!.selectedProducts, isEmpty);
      expect(
        current.data.membershipPaymentHistory,
        ZyraMembershipPaymentHistory.neverPaid,
      );
      expect(owner.latest.pages, ['membership']);
      final count = owner.checkpoints.length;
      owner.allowed = false;
      current.onDraftChanged(staleDraft);
      current.onReview(staleReview);
      await tester.pump();
      expect(owner.checkpoints.length, count);
      expect(owner.roles, isEmpty);
      expect(_modelFacts(owner.latest), before);
    },
  );

  testWidgets(
    'protected Current cancellation callbacks never revive after a section round trip',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      final before = _modelFacts(owner.latest);
      await _tap(tester, _key('concept_membership'));
      final cancel = _key('concept_cancel_membership');
      expect(cancel.hitTestable(), findsOneWidget);
      final oldCancel = tester
          .widget<InkWell>(
            find.descendant(of: cancel, matching: find.byType(InkWell)),
          )
          .onTap!;
      await _tap(tester, _key('membership-section-seeker'));
      oldCancel();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, ['membership']);
      await _tap(tester, _key('membership-section-current'));
      oldCancel();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, ['membership']);
      await _tap(tester, cancel);
      expect(owner.latest.pages.last, 'account_action');
      expect(_modelFacts(owner.latest), before);
      expect(owner.roles, isEmpty);
    },
  );

  testWidgets(
    'protected Unlocks terms callbacks never revive after a section round trip',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      final before = _modelFacts(owner.latest);
      await _tap(tester, _key('concept_membership'));
      await _tap(tester, _key('membership-section-unlocks'));
      final terms = _key('draft_compatibility_store_terms');
      expect(_key('draft_compatibility_store_use_unlocks'), findsNothing);
      expect(find.text('Purchase terms'), findsOneWidget);
      await _reveal(tester, terms);
      final oldTerms = tester.widget<TextButton>(terms).onPressed!;
      await _tap(tester, _key('membership-section-current'));
      oldTerms();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, ['membership']);
      await _tap(tester, _key('membership-section-unlocks'));
      oldTerms();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, ['membership']);
      await _tap(tester, terms);
      expect(owner.latest.pages.last, 'settings_detail');
      expect(_modelFacts(owner.latest), before);
      expect(owner.roles, isEmpty);
    },
  );

  testWidgets(
    'payment history stays independent of plan comparison and role switching',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      await _tap(tester, _key('concept_membership'));
      await _history(tester, ZyraMembershipPaymentHistory.neverPaid);
      await returnZyraPreviewPage(tester);
      await openZyraDevControls(tester);
      await _tap(tester, _key('draft_membership_seeker_basic'));
      await closeZyraDevControls(tester);
      await _tap(tester, _key('concept_membership'));
      expect(_shownData(tester).isOne, isFalse);
      expect(
        _shownData(tester).membershipPaymentHistory,
        ZyraMembershipPaymentHistory.neverPaid,
      );
      await returnZyraPreviewPage(tester);
      await _tap(tester, _key('switch-account-button'));
      await _tap(tester, _key('wallet_primary_guardian'));
      await _nav(tester, 'Profile');
      await _tap(tester, _key('concept_membership'));
      expect(_shownData(tester).guardian, isTrue);
      expect(_shownData(tester).isOne, isTrue);
      expect(
        _shownData(tester).membershipPaymentHistory,
        ZyraMembershipPaymentHistory.neverPaid,
      );
      expect(owner.roles, [true]);
    },
  );
}
