import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/screens/wali/seeker_wali_tab.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _hassan = 'draft-guardian-hassan';
const _yusuf = 'draft-guardian-yusuf';
const _attempts = ['draft-sara', 'draft-aisha', 'draft-maryam'];
const _boundary = ValueKey('guardian-page-polish-candidate');
const _captureDirectory = String.fromEnvironment(
  'ZYRA_GUARDIAN_POLISH_CAPTURE_DIRECTORY',
);

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _body(String id) => _key('guardian-quiet-sections-$id');
Finder _within(String id, String key) =>
    find.descendant(of: _body(id), matching: _key(key));
SeekerGuardianPage _page(WidgetTester tester) =>
    tester.widget<SeekerGuardianPage>(find.byType(SeekerGuardianPage));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError(
      'Guardian polish fixtures must not create an HTTP client.',
    );
  }
}

Future<void> _mount(
  WidgetTester tester, {
  double scale = 1,
  Size size = const Size(393, 852),
  Widget? home,
  ValueChanged<ZyraPreviewNavigationCheckpoint>? onCheckpoint,
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
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home:
          home ??
          ViewRequestDraftScreen(
            ownerGeneration: ZyraAccountState.generation,
            ownerId: ZyraAccountState.userId,
            onCheckpoint: onCheckpoint,
          ),
    ),
  );
  await tester.pumpAndSettle();
  if (home == null) {
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
      fail('The real offline asset preparation did not publish.');
    });
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _press(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }
  expect(
    target.hitTestable(),
    findsOneWidget,
    reason: 'Use a genuine tap on the displayed control.',
  );
  await tester.tapAt(tester.getCenter(target));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  for (
    var depth = 0;
    find.byType(ZyraShellNavigation).evaluate().isEmpty && depth < 8;
    depth++
  ) {
    if (find.byKey(const ValueKey('dev_controls_page')).evaluate().isNotEmpty) {
      await closeZyraDevControls(tester);
      continue;
    }
    await returnZyraPreviewPage(tester);
  }
  Future<void> destination(int targetIndex) async {
    // The decorative cells ignore pointers; the shared bar owns dispatch.
    final cell = _key('floating-nav-item-$targetIndex');
    final bar = find.byType(FloatingNavBar);
    expect(cell, findsOneWidget);
    expect(bar, findsOneWidget);
    final box = tester.renderObject<RenderBox>(bar);
    final local = box.globalToLocal(tester.getCenter(cell));
    expect(
      bar.hitTestable(
        at: Alignment(
          local.dx * 2 / box.size.width - 1,
          local.dy * 2 / box.size.height - 1,
        ),
      ),
      findsOneWidget,
      reason: 'The real navigation owner must receive this pointer.',
    );
    await tester.tapAt(tester.getCenter(cell));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  // Return through an actual other tab if this is already selected, so the
  // shell and rebuilt pager both begin from their ordinary owned first page.
  if (tester
          .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
          .currentIndex ==
      index) {
    await destination(index == 0 ? 2 : 0);
  }
  await destination(index);
}

Future<void> _controls(WidgetTester tester, {required int tab}) async {
  // Reach the real owner before opening its options; Journey counts and
  // Guardian plans deliberately no longer share a generic Browse menu.
  await _nav(tester, tab);
  await toggleZyraDevControls(tester);
  expect(find.text('Page options'), findsOneWidget);
  expect(
    tester.widget<Text>(_key('concept_page_options_context')).data,
    tab == 1 ? 'Journey' : 'Guardian',
  );
  expect(
    _key('concept_journey_preview_3'),
    tab == 1 ? findsOneWidget : findsNothing,
  );
}

Future<void> _seed(WidgetTester tester) async {
  await _controls(tester, tab: 1);
  await _press(tester, _key('concept_journey_preview_3'));
  await _nav(tester, 3);
}

Future<void> _swipe(WidgetTester tester, {required bool next}) async {
  await tester.drag(_key('guardian-page-view'), Offset(next ? -310 : 310, 0));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectIdentity(WidgetTester tester, String id, {required bool main}) {
  final person = _page(tester).people.singleWhere((person) => person.id == id);
  final isHassan = id == _hassan;
  expect(person.relationship, isHassan ? 'father' : 'uncle');
  expect(person.relationshipLabel, isHassan ? 'Father' : 'Paternal Uncle');
  expect(
    (person.linkedAt!.year, person.linkedAt!.month, person.linkedAt!.day),
    (2026, 9, isHassan ? 20 : 23),
  );
  expect(person.isMain, main);
  final role = main ? 'Main Guardian' : 'Additional Guardian';
  expect(
    find.descendant(
      of: _body(id),
      matching: find.text('${person.relationshipLabel} · $role'),
    ),
    findsOneWidget,
  );
  final details = _within(id, 'guardian-details-strip');
  expect(
    find.descendant(of: details, matching: find.text(person.linkedDateLabel!)),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: _body(id),
      matching: find.text(person.linkedDateLabel!),
    ),
    findsOneWidget,
    reason:
        'Keep one date in the existing Linked row, not a duplicate identity line.',
  );
  expect(
    find.descendant(
      of: _body(id),
      matching: find.textContaining('Relationship not recorded'),
    ),
    findsNothing,
  );
  expect(
    find.text('View access is required for every active Journey.'),
    findsNothing,
  );
  expect(find.text('Choose access separately for each Journey.'), findsNothing);
}

Future<void> _makeMain(WidgetTester tester, String id) async {
  await _press(tester, _within(id, 'guardian-make-main'));
  final confirm = find.descendant(
    of: _within(id, 'guardian-make-main-confirmation'),
    matching: find.text('Confirm'),
  );
  await _press(tester, confirm);
  expect(_key('concept_main_guardian_notice'), findsOneWidget);
  await _press(tester, _key('concept_main_guardian_continue'));
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final output = File('$_captureDirectory/$name.png');
    expect(output.existsSync(), isFalse);
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
    final reading = FontLoader('PoppinsGuardianPolish');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
    if (_captureDirectory.isNotEmpty) {
      final directory = Directory(_captureDirectory);
      expect(
        directory.existsSync(),
        isFalse,
        reason: 'Visual evidence uses a fresh immutable directory.',
      );
      directory.createSync(recursive: true);
    }
  });
  tearDownAll(
    () => WidgetController.hitTestWarningShouldBeFatal = previousFatal,
  );
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsGuardianPolish';
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraDevScenario.instance.reset();
    ZyraAccountState.clearImagesForTesting = () async {};
    final gold = ZyraDevAppGold.instance;
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
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final guardianId in [_hassan, _yusuf]) {
    testWidgets(
      'history on/off stays confirmed without rebuilding $guardianId controls',
      (tester) async {
        final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
        await _mount(tester, onCheckpoint: checkpoints.add);
        await _seed(tester);
        if (guardianId == _yusuf) await _swipe(tester, next: true);
        final toggle = _within(guardianId, 'guardian-history-consent-toggle');
        expect(toggle.hitTestable(), findsOneWidget);
        expect(tester.widget<Switch>(toggle).value, isFalse);
        final page = _page(tester);
        final historyLoader = page.historyConsentLoader;
        final journeyLoader = page.journeyAccessLoader;
        final pageElement = tester.element(find.byType(SeekerGuardianPage));
        final historyOwner = _within(
          guardianId,
          'guardian-history-consent-$guardianId',
        );
        final historyElement = tester.element(historyOwner);
        final historyState = tester.state(historyOwner);
        final switchElement = tester.element(toggle);
        final switchRender = tester.renderObject(toggle);
        final switchRect = tester.getRect(toggle);
        final journeySummary = _within(
          guardianId,
          'guardian-journey-access-summary',
        );
        final summaryElement = tester.element(journeySummary);
        final summaryRender = tester.renderObject(journeySummary);
        final pager = _key('guardian-page-view');
        final pagerElement = tester.element(pager);
        final pagerController = tester.widget<PageView>(pager).controller!;
        final position = pagerController.position;
        final pixels = position.pixels;
        final selectedPage = pagerController.page;
        expect(selectedPage, closeTo(guardianId == _hassan ? 0 : 1, .001));

        void expectStable(bool enabled) {
          expect(_page(tester), same(page));
          expect(
            tester.element(find.byType(SeekerGuardianPage)),
            same(pageElement),
          );
          expect(_page(tester).historyConsentLoader, same(historyLoader));
          expect(_page(tester).journeyAccessLoader, same(journeyLoader));
          expect(historyOwner, findsOneWidget);
          expect(tester.element(historyOwner), same(historyElement));
          expect(tester.state(historyOwner), same(historyState));
          expect(toggle, findsOneWidget);
          expect(tester.element(toggle), same(switchElement));
          expect(tester.renderObject(toggle), same(switchRender));
          expect(tester.getRect(toggle), switchRect);
          expect(tester.widget<Switch>(toggle).value, enabled);
          expect(tester.widget<Switch>(toggle).onChanged, isNotNull);
          expect(tester.element(journeySummary), same(summaryElement));
          expect(tester.renderObject(journeySummary), same(summaryRender));
          expect(tester.element(pager), same(pagerElement));
          expect(
            tester.widget<PageView>(pager).controller,
            same(pagerController),
          );
          expect(pagerController.position, same(position));
          expect(position.pixels, closeTo(pixels, .001));
          expect(pagerController.page, closeTo(selectedPage!, .001));
          for (final loading in [
            'Loading…',
            'Loading Journey…',
            'LOADING JOURNEY ACCESS',
          ]) {
            expect(
              find.descendant(
                of: _body(guardianId),
                matching: find.text(loading),
              ),
              findsNothing,
            );
          }
          expect(tester.takeException(), isNull);
        }

        for (final enabled in [true, false, true]) {
          // Keep the first painted frames observable: pumpAndSettle alone
          // could hide a transient loader replacement/confirmed-value reset.
          await tester.tapAt(tester.getCenter(toggle));
          for (final elapsed in [
            Duration.zero,
            const Duration(milliseconds: 1),
            const Duration(milliseconds: 16),
            const Duration(milliseconds: 100),
          ]) {
            await tester.pump(elapsed);
            expectStable(enabled);
          }
          await tester.pumpAndSettle();
          expectStable(enabled);
          expect(checkpoints.last.guardianHistory[guardianId], enabled);
          final other = guardianId == _hassan ? _yusuf : _hassan;
          expect(checkpoints.last.guardianHistory[other], isNot(true));
          expect(
            (await historyLoader!(
              guardianId: guardianId,
              guardianIsMain: guardianId == _hassan,
            )).valueOrNull!.enabled,
            enabled,
          );
        }

        // An actual navigation may replace loaders, but not lose the value
        // published into the shell's existing detached checkpoint model.
        await _nav(tester, 2);
        await _nav(tester, 3);
        if (guardianId == _yusuf) await _swipe(tester, next: true);
        expect(tester.widget<Switch>(toggle).value, isTrue);
        expect(checkpoints.last.guardianHistory[guardianId], isTrue);
      },
    );

    testWidgets(
      'history information remains open for $guardianId without changing consent',
      (tester) async {
        await _mount(tester);
        await _seed(tester);
        if (guardianId == _yusuf) await _swipe(tester, next: true);
        final toggle = _within(guardianId, 'guardian-history-consent-toggle');
        expect(tester.widget<Switch>(toggle).value, isFalse);
        final historyFrame = find
            .ancestor(
              of: toggle,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is SizedBox &&
                    widget.width == 48 &&
                    widget.height == 32,
              ),
            )
            .first;
        expect(tester.getSize(historyFrame), const Size(48, 32));
        final loader = _page(tester).historyConsentLoader!;
        final info = _within(
          guardianId,
          'guardian-history-consent-details-toggle',
        );
        final retainedInfo = tester.widget<IconButton>(info).onPressed!;
        await _press(tester, info);
        final explanation = _key('guardian-history-consent-explanation');
        expect(explanation, findsOneWidget);
        expect(find.text('Past Journey summaries'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        expect(explanation, findsOneWidget);
        tester
            .element(find.byType(ZyraOneJourneyConceptShell))
            .markNeedsBuild();
        await tester.pumpAndSettle();
        expect(explanation, findsOneWidget);
        expect(identical(_page(tester).historyConsentLoader, loader), isTrue);
        retainedInfo();
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(
          (await loader(
            guardianId: guardianId,
            guardianIsMain: guardianId == _hassan,
            enabled: true,
          )).isUnavailable,
          isTrue,
        );
        final name = guardianId == _hassan ? 'Hassan' : 'Yusuf';
        expect(
          find.textContaining('Right now $name only sees Journeys'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Never names, messages, answers, reasons, notes or safety information.',
          ),
          findsOneWidget,
        );
        await _capture(
          tester,
          'history_info_${guardianId == _hassan ? 'main' : 'additional'}',
        );
        await tester.tapAt(const Offset(10, 70));
        await tester.pumpAndSettle();
        expect(explanation, findsNothing);
        expect(tester.widget<Switch>(toggle).value, isFalse);
        await _press(tester, info);
        expect(explanation, findsOneWidget);
        await tester.tapAt(const Offset(10, 70));
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(toggle).value, isFalse);
        await _press(tester, toggle);
        expect(tester.widget<Switch>(toggle).value, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'compact double-text history information scrolls to the privacy explanation',
    (tester) async {
      await _mount(tester, size: const Size(320, 568), scale: 2);
      await _seed(tester);
      await _press(
        tester,
        _within(_hassan, 'guardian-history-consent-details-toggle'),
      );
      expect(_key('guardian-history-consent-explanation'), findsOneWidget);
      await _capture(tester, 'history_info_compact_top');
      final privacy = find.textContaining(
        'Never names, messages, answers, reasons, notes or safety information.',
      );
      await tester.ensureVisible(privacy);
      await tester.pumpAndSettle();
      expect(privacy.hitTestable(), findsOneWidget);
      final rect = tester.getRect(privacy);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      expect(rect.top, greaterThanOrEqualTo(44));
      expect(rect.bottom, lessThanOrEqualTo(568 - 34));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'history_info_compact_privacy');
    },
  );

  testWidgets(
    'fixture relationship and linked date survive Main reassignment with clear dots',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      for (final fixture in draftGuardians) {
        final person = _page(
          tester,
        ).people.singleWhere((person) => person.id == fixture.id);
        expect(person.relationship, fixture.relationshipCode);
        expect(person.linkedAt, fixture.linkedAt);
      }
      _expectIdentity(tester, _hassan, main: true);
      final navTop = tester.getRect(find.byType(FloatingNavBar)).top;
      expect(
        navTop - tester.getRect(_key('guardian-page-dot-0')).bottom,
        greaterThanOrEqualTo(20),
      );
      final dot = tester.widget<AnimatedContainer>(_key('guardian-page-dot-0'));
      expect(dot.constraints!.minWidth, 20);
      await _swipe(tester, next: true);
      _expectIdentity(tester, _yusuf, main: false);
      await _makeMain(tester, _yusuf);
      _expectIdentity(tester, _yusuf, main: true);
      expect(
        _page(
          tester,
        ).people.singleWhere((person) => person.id == _hassan).relationship,
        'father',
      );
      await _swipe(tester, next: true);
      _expectIdentity(tester, _hassan, main: false);
      await _swipe(tester, next: false);
      _expectIdentity(tester, _yusuf, main: true);
    },
  );

  testWidgets(
    'three exact attempts and per-Guardian consent remain independent',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      final mainStates = await _page(tester).journeyAccessLoader!(
        guardianId: _hassan,
      );
      expect(mainStates.valueOrNull!.map((state) => state.attemptId), [
        for (final id in _attempts) 'draft-attempt-$id',
      ]);
      expect(
        mainStates.valueOrNull!.every(
          (state) => state.included && !state.canChange,
        ),
        isTrue,
      );
      await _press(tester, _within(_hassan, 'guardian-history-consent-toggle'));
      final historyMain = await _page(tester).historyConsentLoader!(
        guardianId: _hassan,
        guardianIsMain: true,
      );
      expect(
        historyMain.valueOrNull!.activeGuardianLinkId,
        'draft-link-$_hassan',
      );
      expect(historyMain.valueOrNull!.enabled, isTrue);
      await _swipe(tester, next: true);
      final viewSara = _within(
        _yusuf,
        'guardian-journey-access-toggle-draft-attempt-draft-sara',
      );
      await _press(tester, viewSara);
      final states = await _page(tester).journeyAccessLoader!(
        guardianId: _yusuf,
      );
      expect(states.valueOrNull!.map((state) => state.attemptId), [
        for (final id in _attempts) 'draft-attempt-$id',
      ]);
      expect(states.valueOrNull!.first.included, isFalse);
      expect(states.valueOrNull!.first.chatEnabled, isFalse);
      expect(
        states.valueOrNull!
            .skip(1)
            .every((state) => state.included && state.chatEnabled),
        isTrue,
      );
      final historyAdditional = await _page(tester).historyConsentLoader!(
        guardianId: _yusuf,
        guardianIsMain: false,
      );
      expect(historyAdditional.valueOrNull!.guardianId, _yusuf);
      expect(historyAdditional.valueOrNull!.enabled, isFalse);
      await _press(tester, _within(_yusuf, 'guardian-history-consent-toggle'));
      expect(
        (await _page(tester).historyConsentLoader!(
          guardianId: _yusuf,
          guardianIsMain: false,
        )).valueOrNull!.enabled,
        isTrue,
      );
      expect(
        (await _page(tester).journeyAccessLoader!(
          guardianId: _yusuf,
          attemptId: 'unknown-attempt',
          enabled: true,
        )).isUnavailable,
        isTrue,
      );
      await _swipe(tester, next: false);
      expect(
        tester
            .widget<Switch>(_within(_hassan, 'guardian-history-consent-toggle'))
            .value,
        isTrue,
      );
    },
  );

  for (final id in [_hassan, _yusuf]) {
    testWidgets(
      'Basic chat remains denied for $id including a Main promotion',
      (tester) async {
        await _mount(tester);
        await _seed(tester);
        await _controls(tester, tab: 3);
        await _press(tester, _key('concept_guardian_plan_${id}_0'));
        await _nav(tester, 3);
        if (id == _yusuf) await _swipe(tester, next: true);
        var states = (await _page(tester).journeyAccessLoader!(
          guardianId: id,
        )).valueOrNull!;
        expect(states, hasLength(3));
        expect(
          states.every((state) => !state.chatAvailable && !state.chatEnabled),
          isTrue,
        );
        expect(_page(tester).viewOnlyGuardianIds, contains(id));
        final header = _within(id, 'guardian-journey-permission-header');
        expect(header, findsOneWidget);
        expect(
          find.descendant(of: header, matching: find.text('View')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: header, matching: find.text('Chat')),
          findsNothing,
        );
        for (final attempt in _attempts) {
          expect(
            _within(id, 'guardian-journey-chat-toggle-draft-attempt-$attempt'),
            findsNothing,
          );
          expect(
            _within(
              id,
              'guardian-journey-chat-required-draft-attempt-$attempt',
            ),
            findsNothing,
          );
          final view = _within(
            id,
            id == _hassan
                ? 'guardian-journey-view-required-draft-attempt-$attempt'
                : 'guardian-journey-access-toggle-draft-attempt-$attempt',
          );
          expect(view, findsOneWidget);
          if (id == _yusuf) {
            final properties = tester.widget<Semantics>(view).properties;
            expect(properties.enabled, isTrue);
            expect(properties.onTap, isNotNull);
          }
        }
        expect(
          (await _page(tester).journeyAccessLoader!(
            guardianId: id,
            attemptId: 'draft-attempt-draft-sara',
            chatEnabled: true,
          )).isUnavailable,
          isTrue,
        );
        if (id == _yusuf) {
          await _makeMain(tester, id);
          states = (await _page(tester).journeyAccessLoader!(
            guardianId: id,
          )).valueOrNull!;
          expect(
            states.every(
              (state) =>
                  state.included &&
                  !state.canChange &&
                  !state.chatAvailable &&
                  !state.chatEnabled,
            ),
            isTrue,
          );
          _expectIdentity(tester, id, main: true);
          expect(_page(tester).viewOnlyGuardianIds, contains(id));
          expect(
            find.descendant(
              of: _within(id, 'guardian-journey-permission-header'),
              matching: find.text('Chat'),
            ),
            findsNothing,
          );
          for (final attempt in _attempts) {
            expect(
              _within(
                id,
                'guardian-journey-chat-toggle-draft-attempt-$attempt',
              ),
              findsNothing,
            );
            expect(
              _within(
                id,
                'guardian-journey-chat-required-draft-attempt-$attempt',
              ),
              findsNothing,
            );
            expect(
              _within(
                id,
                'guardian-journey-view-required-draft-attempt-$attempt',
              ),
              findsOneWidget,
            );
            expect(
              _within(
                id,
                'guardian-journey-access-toggle-draft-attempt-$attempt',
              ),
              findsNothing,
            );
          }
        }
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Guardian details and real controls stay reachable at ${scale}x text',
      (tester) async {
        await _mount(tester, scale: scale);
        await _seed(tester);
        _expectIdentity(tester, _hassan, main: true);
        await _capture(tester, 'main_${scale}x');
        await _press(
          tester,
          _within(_hassan, 'guardian-history-consent-toggle'),
        );
        await _swipe(tester, next: true);
        _expectIdentity(tester, _yusuf, main: false);
        await _capture(tester, 'additional_${scale}x');
        await _press(
          tester,
          _within(
            _yusuf,
            'guardian-journey-chat-toggle-draft-attempt-draft-aisha',
          ),
        );
        await _makeMain(tester, _yusuf);
        _expectIdentity(tester, _yusuf, main: true);
        expect(tester.takeException(), isNull);
        // The bounded polish retains the pre-existing FittedBox strategy. This
        // test proves taps/labels, not absence of scaling or native acceptance.
      },
    );
  }

  for (final change in ['tab', 'revocation', 'ABA', 'account generation']) {
    testWidgets(
      'retained Guardian loaders refuse $change before disclosure or writes',
      (tester) async {
        await _mount(tester);
        await _seed(tester);
        await _swipe(tester, next: true);
        final old = _page(tester);
        final viewControl = _within(
          _yusuf,
          'guardian-journey-access-toggle-draft-attempt-draft-sara',
        );
        final staleView = tester
            .widget<InkWell>(
              find.descendant(of: viewControl, matching: find.byType(InkWell)),
            )
            .onTap!;
        final staleHistory = tester
            .widget<Switch>(_within(_yusuf, 'guardian-history-consent-toggle'))
            .onChanged!;
        if (change == 'tab') {
          await _nav(tester, 2);
        } else if (change == 'account generation') {
          ZyraAccountState.resetForTesting();
          AppState.instance.resetForAccountChange();
        } else {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          if (change == 'ABA') {
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
        }
        staleView();
        staleHistory(true);
        expect(
          (await old.journeyAccessLoader!(
            guardianId: _yusuf,
            attemptId: 'draft-attempt-draft-sara',
            enabled: false,
          )).isUnavailable,
          isTrue,
        );
        expect(
          (await old.historyConsentLoader!(
            guardianId: _yusuf,
            guardianIsMain: false,
            enabled: true,
          )).isUnavailable,
          isTrue,
        );
        expect(await old.makeMainGuardian!(_yusuf), isFalse);
        await tester.pumpAndSettle();
        if (change == 'tab') {
          await _nav(tester, 3);
          await _swipe(tester, next: true);
          expect(
            tester
                .widget<Switch>(
                  _within(_yusuf, 'guardian-history-consent-toggle'),
                )
                .value,
            isFalse,
          );
          expect(
            tester
                .widget<Semantics>(
                  _within(
                    _yusuf,
                    'guardian-journey-access-toggle-draft-attempt-draft-sara',
                  ),
                )
                .properties
                .toggled,
            isTrue,
          );
        } else {
          expect(find.text('Preview closed'), findsOneWidget);
          expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'protected Guardian polish never changes ordinary account state',
    (tester) async {
      final app = AppState.instance;
      app
        ..name = 'Preserved member'
        ..surnameLine = 'Surname'
        ..photos = ['unchanged-photo'];
      final active = List.of(app.activeJourneys);
      final saved = List.of(app.saved);
      var changes = 0;
      void changed() => changes++;
      app.addListener(changed);
      addTearDown(() => app.removeListener(changed));
      final generation = ZyraAccountState.generation;
      await _mount(tester);
      await _seed(tester);
      await _swipe(tester, next: true);
      await _press(tester, _within(_yusuf, 'guardian-history-consent-toggle'));
      await _makeMain(tester, _yusuf);
      expect(app.name, 'Preserved member');
      expect(app.surnameLine, 'Surname');
      expect(app.photos, ['unchanged-photo']);
      expect(app.activeJourneys, active);
      expect(app.saved, saved);
      expect(ZyraAccountState.generation, generation);
      expect(changes, 0);
    },
  );

  for (final missing in [false, true]) {
    testWidgets(
      'ordinary supplied Guardian records retain real metadata${missing ? ' and null truth' : ''}',
      (tester) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        ZyraDevScenario.instance.setUseLiveGuardianData(true);
        final people = [
          WaliLinkedPerson(
            id: 'ordinary-main',
            firstName: 'Abdul',
            relationship: 'father',
            isMain: true,
            linkedAt: DateTime.utc(2024, 2, 7),
          ),
          WaliLinkedPerson(
            id: 'ordinary-additional',
            firstName: 'Omar',
            relationship: missing ? null : 'brother',
            linkedAt: missing ? null : DateTime.utc(2025, 4, 9),
          ),
        ];
        await _mount(
          tester,
          home: Scaffold(
            body: SeekerWaliTab(
              linksLoader: () async => ZyraSourceResult.available(people),
              activityLoader: () async => const ZyraSourceResult.available(
                <String, List<GuardianActivity>>{},
              ),
              pendingInvitesLoader: () async =>
                  const ZyraSourceResult.available(<PendingInvite>[]),
              journeyAccessLoader:
                  ({
                    required guardianId,
                    attemptId,
                    enabled,
                    chatEnabled,
                  }) async => const ZyraSourceResult.available(
                    <GuardianJourneyAccessState>[],
                  ),
              historyConsentLoader:
                  ({
                    required guardianId,
                    required guardianIsMain,
                    enabled,
                  }) async => ZyraSourceResult.available(
                    GuardianHistoryConsentState(
                      enabled: enabled ?? false,
                      activeGuardianLinkId: 'ordinary-link-$guardianId',
                      guardianId: guardianId,
                      guardianIsMain: guardianIsMain,
                    ),
                  ),
            ),
          ),
        );
        expect(_page(tester).historyConsentPreview, isFalse);
        expect(
          _page(tester).people.map((person) => person.id),
          people.map((person) => person.id),
        );
        for (final supplied in people) {
          final person = _page(
            tester,
          ).people.singleWhere((person) => person.id == supplied.id);
          expect(person.relationship, supplied.relationship);
          expect(person.linkedAt, supplied.linkedAt);
        }
        expect(
          find.descendant(
            of: _body('ordinary-main'),
            matching: find.text('Father · Main Guardian'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _body('ordinary-main'),
            matching: find.text('7 Feb 2024'),
          ),
          findsOneWidget,
        );
        await _swipe(tester, next: true);
        expect(
          find.descendant(
            of: _body('ordinary-additional'),
            matching: find.text(
              missing ? 'Additional Guardian' : 'Brother · Additional Guardian',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _body('ordinary-additional'),
            matching: find.text(missing ? 'Not recorded' : '9 Apr 2025'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Relationship not recorded'), findsNothing);
        expect(find.text('Hassan'), findsNothing);
        expect(find.text('Yusuf'), findsNothing);
        expect(find.text('20 Sep 2026'), findsNothing);
        expect(find.text('23 Sep 2026'), findsNothing);
        expect(tester.takeException(), isNull);
        // These DTOs exercise the ordinary injected-loader path. No server
        // query or claim that malformed live active_since is accepted is made.
      },
    );
  }
}
