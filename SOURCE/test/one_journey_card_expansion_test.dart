// LOCK 13 V3, JOURNEY_TAB/MASTERS/j01–j07,j10–j12: one place card
// at a time, then its own pushed options page. These tests preserve the
// original person-addressing, disclosure, confirmation and retained guards.
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/dev/zyra_one_journey_options_page.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_journey_peer_guardians_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _people = [
  (id: 'draft-sara', name: 'Sara'),
  (id: 'draft-aisha', name: 'Aisha'),
  (id: 'draft-maryam', name: 'Maryam'),
];
const _options = [
  'profile',
  'timeline',
  'bio',
  'compatibility',
  'guardians',
  'report',
  'end',
];
const _captureDirectory = String.fromEnvironment(
  'ZYRA_JOURNEY_EXPANSION_CAPTURE_DIRECTORY',
);
const _boundary = ValueKey('journey-card-expansion-candidate');

Finder _key(String id) => find.byKey(ValueKey(id));
Finder _expanded(String id) => _key('journey_options_card_$id');
Finder _dots(String id) => _key('draft_journey_options_$id');
Finder _option(String option, String id) => _key('draft_options_${option}_$id');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Inline Journey cards must not create an HTTP client.');
  }
}

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  double scale = 1,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final top = size.height < 700 ? 44.0 : 59.0;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: EdgeInsets.only(top: top, bottom: 34),
          viewPadding: EdgeInsets.only(top: top, bottom: 34),
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: ViewRequestDraftScreen(
        fixture: ZyraShellTestFixture().fixture,
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Wait for the same genuinely prepared local photo deck as the capacity
  // and theme/action suites. Do not replace the shell or its action owners.
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      if (browse.profiles.isNotEmpty &&
          browse.profiles.every((person) => person.photos.isNotEmpty)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tester.pump();
    }
    fail('The prepared offline Browse deck did not publish.');
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

VoidCallback _action(WidgetTester tester, Finder target) {
  expect(target, findsOneWidget);
  final widget = tester.widget<Widget>(target);
  if (widget is ButtonStyleButton) return widget.onPressed!;
  if (widget is InkWell) return widget.onTap!;
  if (widget is GestureDetector) return widget.onTap!;
  final ink = find.descendant(of: target, matching: find.byType(InkWell));
  expect(ink, findsWidgets);
  return tester.widget<InkWell>(ink.first).onTap!;
}

Future<void> _press(WidgetTester tester, Finder target) async {
  // LOCK 13: select a real place before using its single header action.
  // Closing uses the real edge; the options page has no inner ••• button.
  final requested = RegExp(
    r"draft_journey_options_(draft-[a-z]+)",
  ).firstMatch(target.describeMatch(Plurality.one));
  if (requested != null) {
    final id = requested.group(1)!;
    if (_expanded(id).evaluate().isNotEmpty) {
      await swipeZyraBack(tester);
      return;
    }
    final place = _people.indexWhere((person) => person.id == id);
    expect(place, greaterThanOrEqualTo(0));
    await _press(tester, _key('journey_tab_dot_target_$place'));
  }

  if (await pressZyraFixtureFinder(tester, target)) return;
  if (target.evaluate().isEmpty) {
    expect(find.byType(Scrollable), findsWidgets);
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  final scroll = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scroll.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  var visible = tester
      .getRect(target)
      .intersect(Offset.zero & tester.view.physicalSize);
  for (final element in scroll.evaluate()) {
    visible = visible.intersect(
      tester.getRect(
        find.byElementPredicate((candidate) => identical(candidate, element)),
      ),
    );
  }
  final nav = find.byType(FloatingNavBar);
  if (nav.evaluate().isNotEmpty) {
    visible = visible.intersect(
      Rect.fromLTRB(
        0,
        0,
        tester.view.physicalSize.width,
        tester.getRect(nav).top,
      ),
    );
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  final alignment = Alignment(
    local.dx * 2 / box.size.width - 1,
    local.dy * 2 / box.size.height - 1,
  );
  expect(
    target.hitTestable(at: alignment),
    findsOneWidget,
    reason: 'The real displayed option must receive its own tap.',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  for (
    var depth = 0;
    find.byType(ZyraShellNavigation).evaluate().isEmpty && depth < 8;
    depth++
  ) {
    if (zyraShellFixtureFor(tester).setupScopeOpen) {
      await closeZyraDevControls(tester);
      continue;
    }
    await returnZyraPreviewPage(tester);
  }
  // A selected tab is not a Back button. Unwind its actual pushed pages
  // before reusing that tab as an overview host (LOCK 13 V3).
  final currentNavigation = find.byType(ZyraShellNavigation);
  if (currentNavigation.evaluate().isNotEmpty &&
      tester.widget<ZyraShellNavigation>(currentNavigation).currentIndex ==
          index) {
    for (
      var depth = 0;
      depth < 8 && _key('concept_pull_down_back_scope').evaluate().isNotEmpty;
      depth++
    ) {
      await swipeZyraBack(tester);
    }
  }

  await expandZyraPreviewTabBarIfIdle(tester);
  final cell = _key('floating-nav-item-$index');
  expect(cell, findsOneWidget);
  // Cells deliberately ignore pointers: the shared bar owns tap/scrub
  // dispatch. Test that real owner at the cell's point, not decorative ink.
  final nav = find.byType(FloatingNavBar);
  final box = tester.renderObject<RenderBox>(nav);
  final local = box.globalToLocal(tester.getCenter(cell));
  expect(
    nav.hitTestable(
      at: Alignment(
        local.dx * 2 / box.size.width - 1,
        local.dy * 2 / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(tester.getCenter(cell));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _controls(WidgetTester tester) async {
  await openZyraDevControls(tester);
  expect(find.text('Page options'), findsNothing);
  expect(_key('concept_page_options_context'), findsNothing);
}

Future<void> _seed(WidgetTester tester) async {
  await _nav(tester, 1);
  await _controls(tester);
  expect(_key('concept_page_options_context'), findsNothing);
  await _press(tester, _key('concept_journey_preview_3'));
  _expectOverview(tester);
}

void _expectOverview(WidgetTester tester) {
  expect(find.byType(BottomSheet), findsNothing);
  expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
  final reader = tester.widget<ZyraOneJourneyTab>(
    find.byType(ZyraOneJourneyTab),
  );
  expect(
    reader.journeys.map((card) => card.id),
    _people.map((person) => person.id),
  );
  expect(reader.capacity, 3);
  expect(
    _key('journey_tab_person_${reader.journeys[reader.index].id}'),
    findsOneWidget,
  );
  for (final person in _people) {
    expect(_expanded(person.id), findsNothing);
    expect(_key('draft_journey_${person.id}'), findsNothing);
  }
  expect(_dots(reader.journeys[reader.index].id), findsOneWidget);
  expect(
    find.byIcon(Icons.flag_outlined),
    findsNothing,
    reason: 'Report stays on the addressed options page, not the main photo.',
  );
}

void _expectExpanded(WidgetTester tester, String id) {
  expect(_expanded(id), findsOneWidget);
  expect(find.byType(BottomSheet), findsNothing);
  final page = tester.widget<ZyraOneJourneyOptionsPage>(
    find.byType(ZyraOneJourneyOptionsPage),
  );
  expect(page.id, id);
  final owner = tester.widget<ZyraConceptJourneyOptions>(
    find.byType(ZyraConceptJourneyOptions),
  );
  expect(owner.id, id);
  expect(owner.lockedPage, isTrue);
  expect(owner.canReport, isTrue);
  expect(_dots(id), findsNothing);
  expect(_key('draft_journey_$id'), findsOneWidget);
  for (final other in _people.where((person) => person.id != id)) {
    expect(_expanded(other.id), findsNothing);
    expect(_dots(other.id), findsNothing);
    expect(_key('draft_journey_${other.id}'), findsNothing);
  }
  for (final option in _options) {
    expect(_option(option, id), findsOneWidget);
  }
  expect(_option('pause', id), findsNothing);
}

Future<void> _expectReadableRow(
  WidgetTester tester,
  String option,
  String id, {
  bool reveal = false,
}) async {
  final row = _option(option, id);
  if (reveal) {
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
  }
  final bounds = tester.getRect(row);
  expect(bounds.width, greaterThanOrEqualTo(44));
  expect(bounds.height, greaterThanOrEqualTo(44));
  for (final textFinder
      in find.descendant(of: row, matching: find.byType(Text)).evaluate()) {
    final finder = find.byElementPredicate(
      (element) => identical(element, textFinder),
    );
    final text = tester.widget<Text>(finder);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(bounds.left));
    expect(rect.right, lessThanOrEqualTo(bounds.right));
    expect(rect.top, greaterThanOrEqualTo(bounds.top));
    expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  // Await the actual on-screen local photo codecs before recording a frame.
  for (final widget in tester.widgetList<Image>(find.byType(Image)).toList()) {
    expect(widget.image, isA<MemoryImage>());
    final context = tester.element(find.byWidget(widget));
    await tester.runAsync(() async {
      final stream = widget.image.resolve(
        createLocalImageConfiguration(context),
      );
      final ready = Completer<void>();
      final listener = ImageStreamListener(
        (info, _) {
          info.dispose();
          if (!ready.isCompleted) ready.complete();
        },
        onError: (error, stack) {
          if (!ready.isCompleted) ready.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await ready.future.timeout(const Duration(seconds: 10));
      } finally {
        stream.removeListener(listener);
      }
    });
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final output = File('$_captureDirectory/$name.png');
    expect(
      output.existsSync(),
      isFalse,
      reason: 'Candidate evidence is never overwritten.',
    );
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFatal = WidgetController.hitTestWarningShouldBeFatal;
  HttpOverrides? previousNetwork;
  late _NoNetwork network;

  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    // Bundled production glyph metrics, not Ahem assumptions, determine
    // whether the ordinary-size expanded card fits without scrolling.
    final font = FontLoader('PoppinsJourneyExpansion');
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await font.load();
    if (_captureDirectory.isNotEmpty) {
      final directory = Directory(_captureDirectory);
      expect(
        directory.existsSync(),
        isFalse,
        reason: 'Each visual run must use a fresh immutable directory.',
      );
      directory.createSync(recursive: true);
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  tearDownAll(
    () => WidgetController.hitTestWarningShouldBeFatal = previousFatal,
  );
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsJourneyExpansion';
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
    // Disable only the unrelated continuously-running background decoration.
    // The card/page animations remain governed by each real MediaQuery case.
    final gold = ZyraAppGoldStyle.instance;
    gold.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: gold.revision,
    );
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    HttpOverrides.global = previousNetwork;
    expect(network.attempts, 0);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final motion in [
    'ordinary',
    'disable animations',
    'accessible navigation',
  ]) {
    testWidgets(
      'Journey cards push options and return by edge in $motion mode',
      (tester) async {
        await _mount(
          tester,
          // LOCK 13 V3 masters j10–j12 are 430 × 932.
          size: const Size(430, 932),
          disableAnimations: motion == 'disable animations',
          accessibleNavigation: motion == 'accessible navigation',
        );
        await _seed(tester);
        final title = tester.getRect(find.text('Journey'));
        expect(title.left, 20);
        final nav = tester.getRect(find.byType(FloatingNavBar));
        for (final person in _people) {
          await _press(tester, _dots(person.id));
          _expectExpanded(tester, person.id);
          expect(tester.getRect(find.text('Journey')).left, title.left);
          // LOCK 6 V2 permits the idle interaction envelope to contract.
          // Its bottom anchor and full-width horizontal position stay fixed.
          final currentNav = tester.getRect(find.byType(FloatingNavBar));
          expect(
            (currentNav.left, currentNav.right, currentNav.bottom),
            (nav.left, nav.right, nav.bottom),
          );
          for (final option in _options) {
            await _expectReadableRow(tester, option, person.id);
            final row = tester.getRect(_option(option, person.id));
            expect(row.top, greaterThanOrEqualTo(title.bottom));
            expect(
              row.bottom,
              lessThan(nav.top),
              reason: 'Every ordinary-sized option fits above navigation.',
            );
            expect(_option(option, person.id).hitTestable(), findsOneWidget);
          }
          await _press(tester, _dots(person.id));
          _expectOverview(tester);
          expect(tester.getRect(find.text('Journey')).left, title.left);
          // LOCK 6 V2 permits the idle interaction envelope to contract.
          // Its bottom anchor and full-width horizontal position stay fixed.
          final returnedNav = tester.getRect(find.byType(FloatingNavBar));
          expect(
            (returnedNav.left, returnedNav.right, returnedNav.bottom),
            (nav.left, nav.right, nav.bottom),
          );
        }
      },
    );
  }

  testWidgets(
    'pushed options reuse addressed destinations and End confirmation',
    (tester) async {
      await _mount(tester, disableAnimations: true);
      await _seed(tester);
      const id = 'draft-aisha';
      for (final option in _options) {
        await _press(tester, _dots(id));
        _expectExpanded(tester, id);
        await _press(tester, _option(option, id));
        // Every destination, including the confirmation, replaces the
        // options content while retaining its addressed Journey authority.
        expect(_expanded(id), findsNothing);
        expect(find.byType(BottomSheet), findsNothing);
        switch (option) {
          case 'profile':
            expect(
              tester
                  .widget<ZyraOneJourneyBrowsePresentation>(
                    find.byType(ZyraOneJourneyBrowsePresentation),
                  )
                  .profile
                  .id,
              id,
            );
          case 'timeline':
            expect(find.text('Timeline'), findsOneWidget);
          case 'bio':
            expect(_key('draft_bio_locked_$id'), findsOneWidget);
            expect(
              find.text('Complete Journey Bio together to view it here.'),
              findsOneWidget,
            );
          case 'compatibility':
            expect(
              _key('draft_journey_compatibility_locked_$id'),
              findsOneWidget,
            );
            expect(_key('draft_journey_compatibility_$id'), findsNothing);
            expect(find.text('Compatibility score'), findsOneWidget);
            expect(_key('draft_disclosure_continue_$id'), findsOneWidget);
            expect(
              find.byType(ZyraDraftCompatibilityPresentation),
              findsNothing,
            );
            expect(
              find.byKey(ValueKey(('draft_journey_compatibility', id))),
              findsNothing,
            );
          case 'guardians':
            expect(_key('draft_journey_guardians_$id'), findsOneWidget);
            expect(find.text('Journey with Aisha'), findsWidgets);
            expect(find.byType(ZyraOneJourneyGuardianCards), findsNothing);
            expect(find.text('Hassan'), findsNothing);
            expect(find.text('Ibrahim'), findsOneWidget);
          case 'report':
            expect(
              tester
                  .widget<ZyraDraftReportPresentation>(
                    find.byType(ZyraDraftReportPresentation),
                  )
                  .profile!
                  .id,
              id,
            );
          case 'end':
            expect(_key('draft_journey_action_$id'), findsOneWidget);
            expect(find.text('End with Aisha?'), findsOneWidget);
            await _press(tester, _key('draft_cancel_journey_action_$id'));
        }
        await _nav(tester, 1);
        _expectOverview(tester);
      }
    },
  );

  testWidgets('each Journey opens the peer family, never own management', (
    tester,
  ) async {
    await _mount(tester, disableAnimations: true);
    await _seed(tester);
    await _nav(tester, 3);
    final own = tester.widget<ZyraOneJourneyGuardianCards>(
      find.byType(ZyraOneJourneyGuardianCards),
    );
    expect(own.people.any((p) => p.person.firstName == 'Hassan'), isTrue);
    await _nav(tester, 1);
    for (final person in _people) {
      await _press(tester, _dots(person.id));
      await _press(tester, _option('guardians', person.id));
      final page = tester.widget<ZyraJourneyPeerGuardiansPresentation>(
        find.byType(ZyraJourneyPeerGuardiansPresentation),
      );
      expect(page.subjectId, person.id);
      expect(page.firstName, person.name);
      expect(find.text('Journey with ${person.name}'), findsOneWidget);
      expect(page.guardians!.map((g) => g.firstName), [
        'Ibrahim',
        'Maryam',
        'Yusuf',
      ]);
      expect(page.guardians!.first.isMain, isTrue);
      expect(find.text('Hassan'), findsNothing);
      expect(find.byType(ZyraOneJourneyGuardianCards), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(ButtonStyleButton), findsNothing);
      expect(find.text('Remove Guardian'), findsNothing);
      expect(find.text('Share past Journey summaries'), findsNothing);
      if (person.id == 'draft-sara') {
        await _capture(tester, 'peer_guardians_sara');
      }
      // A retained owner-manager callback must not mutate while the peer
      // family route is current, even though the same local shell owns both.
      expect(await own.clearMain('draft-guardian-hassan'), isFalse);
      expect(await own.remove('draft-guardian-hassan'), isNotNull);
      await _nav(tester, 1);
      _expectOverview(tester);
    }
    await _nav(tester, 3);
    final unchanged = tester.widget<ZyraOneJourneyGuardianCards>(
      find.byType(ZyraOneJourneyGuardianCards),
    );
    expect(
      unchanged.people.any(
        (p) => p.person.firstName == 'Hassan' && p.person.isMain,
      ),
      isTrue,
    );
    expect(unchanged.onAdd, isNotNull);
    expect(unchanged.onCircle, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final change in ['revocation', 'ABA', 'account generation', 'unmount']) {
    testWidgets('peer family is removed after $change', (tester) async {
      await _mount(tester, disableAnimations: true);
      await _seed(tester);
      await _press(tester, _dots('draft-sara'));
      await _press(tester, _option('guardians', 'draft-sara'));
      expect(find.byType(ZyraJourneyPeerGuardiansPresentation), findsOneWidget);
      if (change == 'unmount') {
        await tester.pumpWidget(const SizedBox.shrink());
      } else if (change == 'account generation') {
        ZyraAccountState.resetForTesting();
        AppState.instance.resetForAccountChange();
      } else {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        if (change == 'ABA') ZyraDeveloperAccess.setAuthorizedForTesting(true);
      }
      await tester.pumpAndSettle();
      expect(find.byType(ZyraJourneyPeerGuardiansPresentation), findsNothing);
      expect(find.text('Ibrahim'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final change in ['collapse', 'tab', 'role', 'reset']) {
    testWidgets('pushed options refuse retained callbacks after $change', (
      tester,
    ) async {
      await _mount(tester, disableAnimations: true);
      await _seed(tester);
      const id = 'draft-aisha';
      await _press(tester, _dots(id));
      final retained = _options
          .map((option) => _action(tester, _option(option, id)))
          .toList();
      switch (change) {
        case 'collapse':
          await _press(tester, _dots(id));
        case 'tab':
          await _nav(tester, 2);
        case 'role':
          await _controls(tester);
          await _press(tester, _key('draft_role_guardian'));
        case 'reset':
          await _controls(tester);
          await _press(tester, _key('draft_reset'));
      }
      for (final callback in retained) {
        callback();
      }
      await tester.pumpAndSettle();
      expect(_expanded(id), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(_key('draft_journey_action_$id'), findsNothing);
      expect(_key('draft_journey_compatibility_$id'), findsNothing);
      expect(find.byType(ZyraDraftReportPresentation), findsNothing);
      if (change == 'role') {
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .items
              .map((item) => item.label),
          // LOCK 8 V9, GUARDIAN_TABS/MASTERS/g02–g13: five tabs.
          ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile'],
        );
      } else if (change != 'reset') {
        await _nav(tester, 1);
        _expectOverview(tester);
      } else {
        await _nav(tester, 1);
        expect(find.text('No Journey yet'), findsOneWidget);
        expect(_key('journey_tab_card'), findsNothing);
        expect(_key('journey_tab_dot_target_0'), findsNothing);
        expect(
          tester
              .widget<ZyraOneJourneyTab>(find.byType(ZyraOneJourneyTab))
              .journeys,
          isEmpty,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final change in ['revocation', 'ABA', 'account generation', 'unmount']) {
    testWidgets('pushed options refuse stale owner after $change', (
      tester,
    ) async {
      await _mount(tester, disableAnimations: true);
      await _seed(tester);
      const id = 'draft-maryam';
      await _press(tester, _dots(id));
      final retained = _options
          .map((option) => _action(tester, _option(option, id)))
          .toList();
      if (change == 'unmount') {
        await tester.pumpWidget(const SizedBox.shrink());
      } else if (change == 'account generation') {
        ZyraAccountState.resetForTesting();
        AppState.instance.resetForAccountChange();
      } else {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        if (change == 'ABA') {
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        }
      }
      for (final callback in retained) {
        callback();
      }
      await tester.pumpAndSettle();
      expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(ZyraDraftReportPresentation), findsNothing);
      if (change != 'unmount') {
        expect(find.text('Preview closed'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'reopening options cannot revive another card’s retained actions',
    (tester) async {
      await _mount(tester, disableAnimations: true);
      await _seed(tester);
      await _press(tester, _dots('draft-aisha'));
      final retained = _options
          .map((option) => _action(tester, _option(option, 'draft-aisha')))
          .toList();
      await _press(tester, _dots('draft-aisha'));
      await _press(tester, _dots('draft-maryam'));
      for (final callback in retained) {
        callback();
      }
      await tester.pumpAndSettle();
      _expectExpanded(tester, 'draft-maryam');
      expect(find.byType(ZyraDraftReportPresentation), findsNothing);
      expect(_key('draft_journey_action_draft-aisha'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(393, 852), const Size(320, 568)]) {
    testWidgets('200% pushed options remain readable and reachable at $size', (
      tester,
    ) async {
      await _mount(tester, size: size, scale: 2, disableAnimations: true);
      await _seed(tester);
      const id = 'draft-maryam';
      await _press(tester, _dots(id));
      _expectExpanded(tester, id);
      for (final option in _options) {
        await _expectReadableRow(tester, option, id, reveal: true);
      }
      await _press(tester, _option('report', id));
      expect(
        tester
            .widget<ZyraDraftReportPresentation>(
              find.byType(ZyraDraftReportPresentation),
            )
            .profile!
            .id,
        id,
      );
      await _nav(tester, 1);
      _expectOverview(tester);
      await _press(tester, _dots(id));
      await _press(tester, _option('end', id));
      expect(find.text('End with Maryam?'), findsOneWidget);
      await _press(tester, _key('draft_cancel_journey_action_$id'));
      _expectExpanded(tester, id);
      await swipeZyraBack(tester);
      _expectOverview(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('optional immutable collapsed and expanded visual candidates', (
    tester,
  ) async {
    if (_captureDirectory.isEmpty) return;
    await _mount(tester, disableAnimations: true);
    await _seed(tester);
    for (final count in [3, 2, 1]) {
      if (count != 3) {
        await _controls(tester);
        await _press(tester, _key('concept_journey_preview_$count'));
      }
      await _capture(tester, 'collapsed_$count');
      final id = count == 3 ? 'draft-aisha' : 'draft-sara';
      await _press(tester, _dots(id));
      _expectExpanded(tester, id);
      await _capture(tester, 'expanded_$count');
      await _press(tester, _dots(id));
      expect(_expanded(id), findsNothing);
    }
  });
}
