// Real local-shell routing with fictional peers only. No account ledger,
// network, private answers, purchases or Journey consent is involved.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _capture = bool.fromEnvironment('ZYRA_COMPATIBILITY_CAPTURE');
const _directory = String.fromEnvironment(
  'ZYRA_COMPATIBILITY_CAPTURE_DIRECTORY',
);
const _boundary = ValueKey('compatibility-route-candidate');
Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Compatibility preview must remain offline.');
  }
}

ZyraDraftCompatibilityPresentation _page(WidgetTester tester) =>
    tester.widget<ZyraDraftCompatibilityPresentation>(
      find.byType(ZyraDraftCompatibilityPresentation),
    );
ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget(find.byType(ZyraOneJourneyBrowseDesigns));

Future<void> _mount(
  WidgetTester tester, {
  bool Function()? canAct,
  Size size = const Size(393, 852),
  double scale = 1,
  bool reduce = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduce,
          accessibleNavigation: reduce,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child: ZyraOneJourneyConceptShell(
          canAct: canAct ?? () => true,
          onExit: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  expect(tester.takeException(), isNull);
}

Future<void> _press(WidgetTester tester, String key) async {
  if (key == 'draft_back' &&
      _key('dev_controls_page').evaluate().isEmpty &&
      (find.byType(ZyraDraftCompatibilityPresentation).evaluate().isNotEmpty ||
          find
              .byType(ZyraDraftCompatibilityStorePresentation)
              .evaluate()
              .isNotEmpty)) {
    await returnZyraPreviewPage(tester);
    expect(tester.takeException(), isNull);
    return;
  }
  if (await pressZyraDevControlKey(tester, key)) return;
  final target = _key(key);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _reveal(WidgetTester tester) =>
    _press(tester, 'draft_compatibility_reveal');

Future<void> _open(WidgetTester tester) async {
  await _press(tester, 'concept_browse_menu');
  final navigation = tester.widget<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  final item = navigation.items.firstWhere(
    (i) => i.label == 'Compatibility score',
  );
  final icon = find.descendant(
    of: find.byType(ZyraShellNavigation),
    matching: find.byIcon(item.icon),
  );
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(find.byType(ZyraDraftCompatibilityPresentation), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  expect(_directory.startsWith('/'), isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile('$_directory/$name.png'),
      );
    } finally {
      image.dispose();
    }
  });
}

void _expectLockedActions(WidgetTester tester) {
  final page = find.byType(ZyraDraftCompatibilityPresentation);
  final reveal = _key('draft_compatibility_reveal');
  final more = _key('draft_compatibility_buy_more');
  final balance = _page(tester).balance;
  final actions = _key('draft_compatibility_actions');
  final credits = find.descendant(
    of: actions,
    matching: _key('draft_compatibility_balances'),
  );
  final actionLabel = find.descendant(
    of: reveal,
    matching: find.byWidgetPredicate(
      (widget) => widget is Text && widget.data == 'Unlock compatibility',
    ),
  );
  expect(actionLabel, findsOneWidget);
  expect(credits, findsOneWidget);
  expect(
    tester.widget<Text>(credits).textSpan!.toPlainText(),
    '$balance ${balance == 1 ? 'Unlock' : 'Unlocks'} left · Get more',
  );
  expect(find.text('Compatibility Unlock'), findsNothing);
  expect(
    find.descendant(of: page, matching: find.byType(FilledButton)),
    findsOneWidget,
  );
  expect(tester.widget(more), isA<TextButton>());
  expect(find.descendant(of: reveal, matching: credits), findsNothing);
  expect(
    find.descendant(of: _key('draft_compatibility_card'), matching: actions),
    findsNothing,
  );
  final revealRect = tester.getRect(reveal);
  final moreRect = tester.getRect(more);
  final cardRect = tester.getRect(_key('draft_compatibility_card'));
  final labelRect = tester.getRect(actionLabel);
  final creditsRect = tester.getRect(credits);
  expect(revealRect.left, greaterThanOrEqualTo(cardRect.left));
  expect(revealRect.right, lessThanOrEqualTo(cardRect.right));
  expect(revealRect.height, greaterThanOrEqualTo(44));
  expect(moreRect.height, greaterThanOrEqualTo(44));
  expect(moreRect.center.dx, closeTo(revealRect.center.dx, .01));
  for (final rect in [revealRect, moreRect, creditsRect]) {
    expect(rect.left, greaterThanOrEqualTo(cardRect.left));
    expect(rect.right, lessThanOrEqualTo(cardRect.right));
    expect(rect.top, greaterThanOrEqualTo(cardRect.bottom));
  }
  expect(labelRect.left, greaterThanOrEqualTo(revealRect.left));
  expect(labelRect.right, lessThanOrEqualTo(revealRect.right));
  expect(labelRect.top, greaterThanOrEqualTo(revealRect.top));
  expect(labelRect.bottom, lessThanOrEqualTo(revealRect.bottom));
  expect(labelRect.overlaps(creditsRect), isFalse);
  expect(creditsRect.overlaps(revealRect), isFalse);
  expect(moreRect.overlaps(revealRect), isFalse);
  expect(_key('draft_compatibility_locked_halo'), findsOneWidget);
  expect(_key('draft_compatibility_score_reader'), findsNothing);
  expect(find.text('OVERALL'), findsNothing);
  expect(find.text('DETAILS'), findsNothing);
  expect(tester.takeException(), isNull);
}

void _expectFittedPage(WidgetTester tester, Size size) {
  final page = find.byType(ZyraDraftCompatibilityPresentation);
  expect(find.textContaining('Try Compatibility with'), findsNothing);
  expect(find.text('Developer demo'), findsNothing);
  expect(_key('draft_compatibility_demo_notice'), findsNothing);
  _expectLockedActions(tester);
  // This subpage has no floating navigation bar, only its real safe area.
  expect(find.byType(ZyraShellNavigation), findsNothing);
  final cardRect = tester.getRect(_key('draft_compatibility_card'));
  final headingRect = tester.getRect(find.text('Compatibility score'));
  final selectorRect = tester.getRect(_key('draft_compatibility_reveal'));
  final footerRect = tester.getRect(_key('draft_compatibility_buy_more'));
  // The Monogram and information card sit in the free space above the action.
  expect(cardRect.top, greaterThan(headingRect.bottom));
  expect(selectorRect.top, greaterThan(cardRect.top));
  expect(selectorRect.top, greaterThan(cardRect.bottom));
  expect(footerRect.top, greaterThan(selectorRect.bottom));
  expect(cardRect.height, greaterThan(100));
  final scrollables = find.descendant(
    of: page,
    matching: find.byType(Scrollable),
  );
  for (final element in scrollables.evaluate()) {
    final scroll = (element as StatefulElement).state as ScrollableState;
    expect(scroll.position.maxScrollExtent, closeTo(0, .5));
    expect(scroll.position.pixels, closeTo(0, .5));
  }
  for (final key in [
    'draft_compatibility_card',
    'draft_compatibility_locked_halo',
    'draft_compatibility_buy_more',
    'draft_compatibility_reveal',
  ]) {
    final target = _key(key);
    final rect = tester.getRect(target);
    expect(rect.top, greaterThanOrEqualTo(59));
    expect(rect.bottom, lessThanOrEqualTo(size.height - 34 - 16 + .5));
    expect(rect.left, greaterThanOrEqualTo(20));
    expect(rect.right, lessThanOrEqualTo(size.width - 20 + .5));
    expect(target.hitTestable(), findsOneWidget);
  }
  expect(tester.takeException(), isNull);
}

void _expectHaloReader(WidgetTester tester, Size size) {
  expect(find.text('Compatibility score'), findsOneWidget);
  expect(find.text('You and Sara'), findsNothing);
  expect(_key('draft_compatibility_score_reader'), findsOneWidget);
  expect(_key('draft_compatibility_score_pages'), findsOneWidget);
  expect(_key('draft_compatibility_score_artwork_halo_0'), findsOneWidget);
  expect(_key('draft_compatibility_overall_score'), findsOneWidget);
  expect(find.text('${_page(tester).overallScore}%'), findsOneWidget);
  expect(_key('draft_compatibility_card'), findsNothing);
  expect(_key('draft_compatibility_reveal'), findsNothing);
  expect(_key('draft_compatibility_buy_more'), findsNothing);
  expect(_key('draft_compatibility_balances'), findsNothing);
  expect(find.byType(ZyraShellNavigation), findsNothing);
  final reader = tester.getRect(_key('draft_compatibility_score_reader'));
  expect(reader.left, greaterThanOrEqualTo(20));
  expect(reader.right, lessThanOrEqualTo(size.width - 20 + .5));
  expect(reader.top, greaterThanOrEqualTo(59));
  expect(reader.bottom, lessThanOrEqualTo(size.height - 34 + .5));
  expect(
    tester.widget<Text>(_key('draft_compatibility_score_position')).data,
    '1 / 7',
  );
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final priorOverrides = HttpOverrides.current;
  late _NoNetwork network;
  setUpAll(() async {
    final font = FontLoader('PoppinsCompatibilityRoute');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
  setUp(() {
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsCompatibilityRoute';
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = priorOverrides;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  testWidgets('Browse selected peer survives actual Back return', (
    tester,
  ) async {
    await _mount(tester);
    await _open(tester);
    expect(_page(tester).personName, 'Sara');
    expect(find.text('Compatibility score'), findsOneWidget);
    expect(find.text('You and Sara'), findsOneWidget);
    expect(find.text('Understanding, not a guarantee.'), findsNothing);
    expect(_page(tester).revealed, isFalse);
    expect(_page(tester).balance, 1);
    expect(_key('draft_reveal_draft-sara'), findsNothing);
    expect(_key('concept_message'), findsNothing);
    final scope = tester.widget<ZyraPullDownBackScope>(
      find.byType(ZyraPullDownBackScope),
    );
    await returnZyraPreviewPage(tester);
    // The visible Back owns the return; a retained callback cannot close twice.
    expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
    expect(
      _browse(tester).profiles[_browse(tester).selectedIndex].id,
      'draft-sara',
    );
    final sara = _browse(
      tester,
    ).profiles.firstWhere((p) => p.id == 'draft-sara');
    expect(_browse(tester).requestLabel!(sara), 'Request a Journey');
    scope.onBack();
    await tester.pumpAndSettle();
    expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
  });

  testWidgets(
    'exact presets never accumulate and route changes retain used access',
    (tester) async {
      await _mount(tester);
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_compatibility_unlock_0');
      await _press(tester, 'draft_compatibility_unlock_5');
      await _press(tester, 'draft_compatibility_unlock_5');
      await tester.ensureVisible(find.text('Page options'));
      await tester.pumpAndSettle();
      await _snapshot(tester, 'controls');
      expect(_key('draft_compatibility_standard_5'), findsNothing);
      expect(_key('draft_compatibility_plus_5'), findsNothing);
      await _press(tester, 'draft_back');
      await _open(tester);
      expect(_page(tester).balance, 5);
      final retained = _page(tester).onUnlock!;
      await _reveal(tester);
      final usedScore = _page(tester).overallScore;
      expect(_page(tester).balance, 4);
      expect(_page(tester).revealed, isTrue);
      retained();
      await tester.pumpAndSettle();
      expect(_page(tester).balance, 4);
      await _press(tester, 'draft_back');
      await _open(tester);
      expect(_page(tester).balance, 4);
      expect(_page(tester).revealed, isTrue);
      expect(_page(tester).overallScore, usedScore);
      expect(_page(tester).onUnlock, isNull);
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_compatibility_unlock_1');
      await _press(tester, 'draft_compatibility_unlock_1');
      await _press(tester, 'draft_back');
      await _open(tester);
      expect(_page(tester).balance, 1);
      expect(_page(tester).revealed, isTrue);
      expect(_page(tester).overallScore, usedScore);
      expect(_page(tester).onUnlock, isNull);
      // A count preset changes only unspent stock. It cannot erase used access
      // or permit the prior route's callback to charge this person again.
      retained();
      retained();
      await tester.pumpAndSettle();
      expect(_page(tester).balance, 1);
      expect(_page(tester).overallScore, usedScore);
    },
  );

  testWidgets(
    'returned route, zero balance and ABA reject retained delegates',
    (tester) async {
      await _mount(tester);
      await _open(tester);
      final oldUnlock = _page(tester).onUnlock!;
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_back');
      oldUnlock();
      oldUnlock();
      await tester.pumpAndSettle();
      final staleCount = tester
          .widget<OutlinedButton>(_key('draft_compatibility_unlock_5'))
          .onPressed!;
      await _press(tester, 'draft_compatibility_unlock_0');
      await _press(tester, 'draft_back');
      await _open(tester);
      staleCount();
      oldUnlock();
      await tester.pumpAndSettle();
      expect(_page(tester).balance, 0);
      expect(_page(tester).revealed, isFalse);
      await _press(tester, 'draft_back');
      await _open(tester);
      oldUnlock();
      await tester.pumpAndSettle();
      expect(_page(tester).revealed, isFalse);
      expect(_page(tester).balance, 0);
    },
  );

  testWidgets(
    'one action opens the fixed Halo reader once and keeps the peer selected',
    (tester) async {
      await _mount(tester, reduce: false);
      await _open(tester);
      expect(find.text('Unlock Compatibility'), findsNothing);
      expect(find.text('Unlock Compatibility+'), findsNothing);
      _expectLockedActions(tester);
      final retained = _page(tester).onUnlock!;
      // Two touches before the next frame consume just one local credit.
      await tester.tap(_key('draft_compatibility_reveal'));
      await tester.tap(_key('draft_compatibility_reveal'));
      await tester.pump();
      expect(_page(tester).personName, 'Sara');
      expect(_page(tester).balance, 0);
      expect(_page(tester).revealed, isTrue);
      _expectHaloReader(tester, const Size(393, 852));
      expect(find.text('Revealing'), findsNothing);
      expect(find.text('Revealed'), findsNothing);
      expect(
        _key('draft_compatibility_category_Work & Education_result-opacity'),
        findsNothing,
      );
      await _snapshot(tester, 'halo_overall');
      retained();
      await tester.pumpAndSettle();
      expect(_page(tester).balance, 0);
      _expectHaloReader(tester, const Size(393, 852));
      await tester.tap(_key('draft_compatibility_score_next'));
      await tester.pumpAndSettle();
      expect(_key('draft_compatibility_score_title_1'), findsOneWidget);
      expect(_key('draft_compatibility_score_artwork_halo_1'), findsOneWidget);
      await _snapshot(tester, 'halo_category');
      expect(_page(tester).balance, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('revoked or disposed route never unlocks or emits haptics', (
    tester,
  ) async {
    var allowed = true;
    var haptics = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics++;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _mount(tester, canAct: () => allowed);
    await _open(tester);
    final callback = _page(tester).onUnlock!;
    final before = haptics;
    allowed = false;
    callback();
    await tester.pumpAndSettle();
    expect(_page(tester).balance, 1);
    expect(_page(tester).revealed, isFalse);
    expect(haptics, before);
    await tester.pumpWidget(const SizedBox.shrink());
    callback();
    await tester.pumpAndSettle();
    expect(haptics, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'store and fresh routes preserve used access until explicit Reset preview',
    (tester) async {
      await _mount(tester);
      await _open(tester);
      _expectLockedActions(tester);
      final coveredUnlock = _page(tester).onUnlock!;
      await _press(tester, 'draft_compatibility_buy_more');
      expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
      expect(find.text('Compatibility Unlocks'), findsOneWidget);
      expect(find.text(' · Purchasing isn’t available yet'), findsOneWidget);
      expect(_key('draft_compatibility_test_credits'), findsNothing);
      coveredUnlock();
      await tester.pumpAndSettle();
      await _press(tester, 'draft_back');
      expect(_page(tester).revealed, isFalse);
      expect(_page(tester).balance, 1);
      await _reveal(tester);
      final score = _page(tester).overallScore;
      expect(_page(tester).overallScore, score);
      expect(_page(tester).revealed, isTrue);
      expect(_page(tester).balance, 0);
      _expectHaloReader(tester, const Size(393, 852));
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_compatibility_unlock_5');
      await _press(tester, 'draft_back');
      await _open(tester);
      expect(_page(tester).revealed, isTrue);
      expect(_page(tester).balance, 5);
      expect(_page(tester).overallScore, score);
      expect(_page(tester).onUnlock, isNull);
      coveredUnlock();
      await tester.pumpAndSettle();
      expect(_page(tester).balance, 5);
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_reset');
      await _open(tester);
      expect(_page(tester).balance, 1);
      expect(_page(tester).revealed, isFalse);
    },
  );

  testWidgets('role roundtrip discards route and retained actions', (
    tester,
  ) async {
    await _mount(tester);
    await _open(tester);
    final stale = _page(tester).onUnlock!;
    await _press(tester, 'draft_back');
    await _press(tester, 'draft_back');
    await _press(tester, 'draft_role_guardian');
    await _press(tester, 'draft_back');
    expect(_key('draft_compatibility_unlock_5'), findsNothing);
    await _press(tester, 'draft_role_seeker');
    await _open(tester);
    stale();
    await tester.pumpAndSettle();
    expect(_page(tester).balance, 1);
    expect(_page(tester).revealed, isFalse);
  });

  testWidgets('different peer cannot receive a retained reveal', (
    tester,
  ) async {
    await _mount(tester);
    await _open(tester);
    final stale = _page(tester).onUnlock!;
    await _press(tester, 'draft_back');
    _browse(tester).onNext!();
    await tester.pumpAndSettle();
    await _open(tester);
    expect(_page(tester).personName, 'Aisha');
    stale();
    await tester.pumpAndSettle();
    expect(_page(tester).revealed, isFalse);
    expect(_page(tester).balance, 1);
  });

  testWidgets('global account store never targets the last browsed peer', (
    tester,
  ) async {
    await _mount(tester);
    await _open(tester);
    await _press(tester, 'draft_back');
    tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .onTap(4);
    await tester.pumpAndSettle();
    tester
        .widget<ZyraConceptProfilePresentation>(
          find.byType(ZyraConceptProfilePresentation),
        )
        .onAction(ZyraConceptAccountAction.compatibilityStore);
    await tester.pumpAndSettle();
    expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
    expect(find.text('Compatibility Unlocks'), findsOneWidget);
    expect(find.text('You and Sara'), findsNothing);
    expect(_key('draft_compatibility_test_credits'), findsNothing);
    expect(
      find.byType(ZyraDraftCompatibilityStorePresentation),
      findsOneWidget,
    );
    final store = tester.widget<ZyraDraftCompatibilityStorePresentation>(
      find.byType(ZyraDraftCompatibilityStorePresentation),
    );
    expect(store.balance, 1);
    expect(find.text('Unlocks remaining'), findsNothing);
    expect(
      tester.widget<Text>(_key('draft_compatibility_store_balance_count')).data,
      '1',
    );
    expect(_key('draft_compatibility_store_use_unlocks'), findsNothing);
    expect(_key('draft_compatibility_store_use_guidance'), findsNothing);
    await _press(tester, 'draft_compatibility_store_unlock_three');
    await tester.pumpAndSettle();
    expect(
      find.byType(ZyraDraftCompatibilityStorePresentation),
      findsOneWidget,
    );
    expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
    expect(
      tester
          .widget<ZyraDraftCompatibilityStorePresentation>(
            find.byType(ZyraDraftCompatibilityStorePresentation),
          )
          .balance,
      1,
    );
    expect(
      tester
          .widget<FilledButton>(_key('draft_compatibility_store_continue'))
          .onPressed,
      isNull,
    );
    await returnZyraPreviewPage(tester);
    expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
    tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .onTap(0);
    await tester.pumpAndSettle();
    await _open(tester);
    expect(_page(tester).revealed, isFalse);
    expect(_page(tester).balance, 1);
  });

  testWidgets(
    'read-only store balance cannot bypass the exact unlock confirmation',
    (tester) async {
      await _mount(tester);
      await _open(tester);
      await _press(tester, 'draft_compatibility_buy_more');
      final store = tester.widget<ZyraDraftCompatibilityStorePresentation>(
        find.byType(ZyraDraftCompatibilityStorePresentation),
      );
      expect(store.balance, 1);
      expect(find.text('Unlocks remaining'), findsNothing);
      expect(_key('draft_compatibility_store_use_unlocks'), findsNothing);
      expect(_key('draft_compatibility_store_use_guidance'), findsNothing);
      await _press(tester, 'draft_compatibility_store_unlock_five');
      expect(
        tester
            .widget<FilledButton>(_key('draft_compatibility_store_continue'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ZyraDraftCompatibilityStorePresentation>(
              find.byType(ZyraDraftCompatibilityStorePresentation),
            )
            .balance,
        1,
      );
      await returnZyraPreviewPage(tester);
      expect(_page(tester).personName, 'Sara');
      expect(_page(tester).revealed, isFalse);
      expect(_page(tester).balance, 1);
      await _reveal(tester);
      expect(_page(tester).balance, 0);
    },
  );

  testWidgets('store terms are a real destination and back keeps the store', (
    tester,
  ) async {
    await _mount(tester);
    await _open(tester);
    await _press(tester, 'draft_compatibility_buy_more');
    final store = tester.widget<ZyraDraftCompatibilityStorePresentation>(
      find.byType(ZyraDraftCompatibilityStorePresentation),
    );
    store.onTerms!();
    await tester.pumpAndSettle();
    expect(find.byType(ZyraDraftCompatibilityStorePresentation), findsNothing);
    expect(find.text('Terms'), findsOneWidget);
    await returnZyraPreviewPage(tester);
    await tester.pumpAndSettle();
    expect(
      find.byType(ZyraDraftCompatibilityStorePresentation),
      findsOneWidget,
    );
    expect(find.text('Unlocks remaining'), findsNothing);
    expect(
      tester.widget<Text>(_key('draft_compatibility_store_balance_count')).data,
      '1',
    );
    store.onTerms!();
    await tester.pumpAndSettle();
    // The previous route callback expired even though it is the same page name.
    expect(
      find.byType(ZyraDraftCompatibilityStorePresentation),
      findsOneWidget,
    );
  });

  testWidgets('actual shell locked and revealed visual captures', (
    tester,
  ) async {
    await _mount(tester, reduce: false);
    await _open(tester);
    await _snapshot(tester, 'locked');
    await _reveal(tester);
    await tester.ensureVisible(find.text('Compatibility score'));
    await tester.pumpAndSettle();
    _expectHaloReader(tester, const Size(393, 852));
    await _snapshot(tester, 'halo_overall');
    await tester.tap(_key('draft_compatibility_score_next'));
    await tester.pumpAndSettle();
    expect(_key('draft_compatibility_score_title_1'), findsOneWidget);
    await _snapshot(tester, 'halo_category');
  });

  for (final size in const [Size(375, 812), Size(393, 852), Size(430, 932)]) {
    testWidgets(
      'normal phone $size fits scores and the full Halo focus catalogue without scrolling',
      (tester) async {
        await _mount(tester, size: size, reduce: false);
        await _open(tester);
        _expectFittedPage(tester, size);
        await _snapshot(tester, 'fitted_${size.width.toInt()}_locked');
        final cardRect = tester.getRect(_key('draft_compatibility_card'));
        await tester.drag(
          _key('draft_compatibility_card'),
          const Offset(0, -80),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(_key('draft_compatibility_card')), cardRect);
        _expectFittedPage(tester, size);
        // Store navigation is available only while locked. It never purchases.
        await tester.tap(_key('draft_compatibility_buy_more'));
        await tester.pumpAndSettle();
        expect(find.text('Compatibility Unlocks'), findsOneWidget);
        expect(
          find.byType(ZyraDraftCompatibilityStorePresentation),
          findsOneWidget,
        );
        expect(_key('draft_compatibility_test_credits'), findsNothing);
        final verticalStoreScroller = find.descendant(
          of: _key('draft_compatibility_store_viewport'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                (widget.axisDirection == AxisDirection.down ||
                    widget.axisDirection == AxisDirection.up),
          ),
        );
        expect(verticalStoreScroller, findsOneWidget);
        final storeScroll = tester.state<ScrollableState>(
          verticalStoreScroller,
        );
        expect(storeScroll.position.maxScrollExtent, 0);
        final card = tester.getRect(_key('draft_compatibility_store_preview'));
        expect(card.top, greaterThanOrEqualTo(59 + 16));
        expect(card.bottom, lessThanOrEqualTo(size.height - 34 - 16 + .01));
        await _snapshot(tester, 'store_${size.width.toInt()}_top');
        for (final offer in ['unlock_single', 'unlock_three', 'unlock_five']) {
          expect(
            _key('draft_compatibility_store_$offer').hitTestable(),
            findsOneWidget,
          );
          final button = tester.widget<OutlinedButton>(
            _key('draft_compatibility_store_$offer'),
          );
          expect(button.onPressed, isNotNull);
          expect(
            tester.getSize(_key('draft_compatibility_store_$offer')).height,
            greaterThanOrEqualTo(44),
          );
        }
        expect(_key('draft_compatibility_store_standard_card'), findsNothing);
        expect(_key('draft_compatibility_store_plus_card'), findsNothing);
        expect(
          _key('draft_compatibility_store_continue').hitTestable(),
          findsOneWidget,
        );
        expect(
          _key('draft_compatibility_store_terms').hitTestable(),
          findsOneWidget,
        );
        expect(
          tester.getRect(_key('draft_compatibility_store_unavailable')).bottom,
          lessThanOrEqualTo(size.height - 34 - 16 + .01),
        );
        await _snapshot(tester, 'store_${size.width.toInt()}_full');
        await returnZyraPreviewPage(tester);
        expect(_page(tester).personName, 'Sara');
        expect(_page(tester).revealed, isFalse);
        expect(_page(tester).balance, 1);
        _expectFittedPage(tester, size);
        // A real reveal removes the locked Halo and fills the same route
        // with the fixed Halo reader. No second unlock is exposed.
        await _reveal(tester);
        expect(_page(tester).revealed, isTrue);
        expect(_page(tester).balance, 0);
        _expectHaloReader(tester, size);
        await _snapshot(tester, 'fitted_${size.width.toInt()}_halo');
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final reduce in [false, true]) {
    testWidgets('compact 200% route remains reachable reduce=$reduce', (
      tester,
    ) async {
      await _mount(
        tester,
        size: const Size(320, 568),
        scale: 2,
        reduce: reduce,
      );
      await _open(tester);
      _expectLockedActions(tester);
      expect(
        tester
            .widget<FilledButton>(_key('draft_compatibility_reveal'))
            .onPressed,
        isNotNull,
      );
      await _press(tester, 'draft_compatibility_buy_more');
      expect(
        find.byType(ZyraDraftCompatibilityStorePresentation),
        findsOneWidget,
      );
      await _press(tester, 'draft_back');
      expect(_page(tester).revealed, isFalse);
      await _press(tester, 'draft_compatibility_reveal');
      final usedScore = _page(tester).overallScore;
      expect(_page(tester).revealed, isTrue);
      expect(_key('draft_compatibility_score_reader'), findsOneWidget);
      expect(_key('draft_compatibility_buy_more'), findsNothing);
      expect(_key('draft_compatibility_reveal'), findsNothing);
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_compatibility_unlock_5');
      await _press(tester, 'draft_back');
      await _open(tester);
      expect(_page(tester).revealed, isTrue);
      expect(_page(tester).balance, 5);
      expect(_page(tester).onUnlock, isNull);
      expect(_page(tester).overallScore, usedScore);
      expect(_key('draft_compatibility_score_reader'), findsOneWidget);
      expect(_key('draft_compatibility_buy_more'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'large-text fallback left-edge Back returns the same peer reduce=$reduce',
      (tester) async {
        await _mount(
          tester,
          size: const Size(320, 568),
          scale: 2,
          reduce: reduce,
        );
        await _open(tester);
        await tester.ensureVisible(_key('draft_compatibility_buy_more'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Compatibility score'));
        await tester.pumpAndSettle();
        final edge = tester.getRect(_key('zyra_back_swipe_edge'));
        await tester.dragFrom(
          Offset(edge.left + 3, edge.center.dy),
          const Offset(240, 0),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
        expect(
          _browse(tester).profiles[_browse(tester).selectedIndex].id,
          'draft-sara',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
