import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
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
            fixture: ZyraShellTestFixture().fixture,
            ownerGeneration: ZyraAccountState.generation,
            ownerId: ZyraAccountState.userId,
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
  if (await pressZyraFixtureFinder(tester, target)) return;
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
    if (zyraShellFixtureFor(tester).setupScopeOpen) {
      await closeZyraDevControls(tester);
      continue;
    }
    await returnZyraPreviewPage(tester);
  }
  Future<void> destination(int targetIndex) async {
    await expandZyraPreviewTabBarIfIdle(tester);
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
  await _nav(tester, tab);
  await openZyraDevControls(tester);
  expect(find.text('Page options'), findsNothing);
  expect(_key('concept_page_options_context'), findsNothing);
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

ZyraOneJourneyGuardianCards _cards(WidgetTester tester) =>
    tester.widget(find.byType(ZyraOneJourneyGuardianCards));

ZyraGuardianCardPerson _person(WidgetTester tester, String id) =>
    _cards(tester).people.singleWhere((card) => card.person.id == id);

SemanticsProperties _action(WidgetTester tester, String key) =>
    tester.widget<Semantics>(_key(key)).properties;

Future<void> _selectYusuf(WidgetTester tester) =>
    _press(tester, _key('guardian-card-next'));

Future<void> _flip(WidgetTester tester) =>
    _press(tester, _key('guardian-card-center'));

Future<void> _makeMain(WidgetTester tester) async {
  await _press(tester, _key('guardian-make-main'));
  await _press(
    tester,
    find.descendant(
      of: _key('guardian-make-main-confirmation'),
      matching: find.text('Confirm'),
    ),
  );
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
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final guardianId in [_hassan, _yusuf]) {
    // Q28: the LOCK 19 front retains one independent history consent bit.
    testWidgets('current history toggle changes only $guardianId consent', (
      tester,
    ) async {
      await _mount(tester);
      await _seed(tester);
      if (guardianId == _yusuf) await _selectYusuf(tester);
      final other = guardianId == _hassan ? _yusuf : _hassan;
      final history = 'guardian-card-history-$guardianId';
      expect(_action(tester, history).toggled, isFalse);
      expect(_person(tester, other).history, isFalse);
      await _press(tester, _key(history));
      expect(_action(tester, history).toggled, isTrue);
      expect(_person(tester, other).history, isFalse);
      await _press(tester, _key(history));
      expect(_action(tester, history).toggled, isFalse);
      expect(_person(tester, other).history, isFalse);
    });
  }

  // Q28: LOCK 19 front and access remain bound to the selected Guardian.
  testWidgets(
    'fixture relationship and linked date survive Main reassignment with clear dots',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      void verifyMetadata() {
        for (final fixture in draftGuardians) {
          final person = _person(tester, fixture.id).person;
          expect(person.relationship, fixture.relationshipCode);
          expect(person.linkedAt, fixture.linkedAt);
        }
      }

      verifyMetadata();
      expect(_person(tester, _hassan).person.isMain, isTrue);
      expect(_key('guardian-card-dot-0'), findsOneWidget);
      await _selectYusuf(tester);
      expect(_person(tester, _yusuf).person.isMain, isFalse);
      expect(find.text('Paternal Uncle'), findsOneWidget);
      await _flip(tester);
      await _makeMain(tester);
      verifyMetadata();
      expect(_person(tester, _yusuf).person.isMain, isTrue);
      expect(_person(tester, _hassan).person.isMain, isFalse);
      expect(_key('guardian-card-dot-0'), findsOneWidget);
    },
  );

  // Q18 and Q28 (R2): use real View/Chat controls and compare all three
  // attempts before and after switching a single Guardian's permission.
  testWidgets(
    'three exact attempts and per-Guardian consent remain independent',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      List<(String, int?, bool, bool)> access(String id) => [
        for (final row in _cards(tester).journeysFor(id))
          (row.id, row.attempt, row.view, row.chat),
      ];
      final main = access(_hassan);
      final additional = access(_yusuf);
      expect(main.map((row) => row.$1), _attempts);
      expect(
        additional.map((row) => (row.$1, row.$2)),
        main.map((row) => (row.$1, row.$2)),
      );
      expect(
        _cards(
          tester,
        ).journeysFor(_hassan).every((row) => row.view && !row.canChange),
        isTrue,
      );
      await _press(tester, _key('guardian-card-history-$_hassan'));
      await _selectYusuf(tester);
      await _flip(tester);
      final view = 'guardian-card-view-$_yusuf-draft-sara';
      await _press(tester, _key(view));
      final after = access(_yusuf);
      expect((after.first.$3, after.first.$4), (false, false));
      expect(after.skip(1), additional.skip(1));
      expect(access(_hassan), main);
      final forged = _cards(tester).onPermission;
      forged(_yusuf, 'unknown-attempt', view: true);
      forged(_hassan, 'draft-sara', view: false);
      await tester.pumpAndSettle();
      expect(access(_yusuf), after);
      expect(access(_hassan), main);
      expect(_person(tester, _hassan).history, isTrue);
      expect(_person(tester, _yusuf).history, isFalse);
      await _flip(tester);
      await _press(tester, _key('guardian-card-history-$_yusuf'));
      expect(_person(tester, _hassan).history, isTrue);
      expect(_person(tester, _yusuf).history, isTrue);
    },
  );

  for (final id in [_hassan, _yusuf]) {
    // Q28: a Basic card never acquires a Chat grant, even when made Main.
    testWidgets(
      'Basic chat remains denied for $id including a Main promotion',
      (tester) async {
        await _mount(tester);
        await _seed(tester);
        await _controls(tester, tab: 3);
        await _press(tester, _key('concept_guardian_plan_${id}_0'));
        await _nav(tester, 3);
        if (id == _yusuf) await _selectYusuf(tester);
        await _flip(tester);
        final rows = _cards(tester).journeysFor(id);
        expect(rows.map((row) => row.id), _attempts);
        expect(rows.every((row) => !row.chat), isTrue);
        expect(_person(tester, id).basic, isTrue);
        for (final journey in _attempts) {
          expect(_key('guardian-card-view-$id-$journey'), findsOneWidget);
          expect(
            _action(tester, 'guardian-card-chat-$id-$journey').toggled,
            isNull,
          );
        }
        _cards(tester).onPermission(id, 'draft-sara', chat: true);
        await tester.pumpAndSettle();
        expect(
          _cards(tester).journeysFor(id).every((row) => !row.chat),
          isTrue,
        );
        if (id == _yusuf) {
          await _makeMain(tester);
          expect(_person(tester, id).person.isMain, isTrue);
          expect(_person(tester, id).basic, isTrue);
          expect(
            _cards(tester)
                .journeysFor(id)
                .every((row) => row.view && !row.chat && !row.canChange),
            isTrue,
          );
        }
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    // Q28: reach the actual card controls at the configured reading scale.
    testWidgets(
      'Guardian details and real controls stay reachable at ${scale}x text',
      (tester) async {
        await _mount(tester, scale: scale);
        await _seed(tester);
        await _capture(tester, 'main_${scale}x');
        await _press(tester, _key('guardian-card-history-$_hassan'));
        await _selectYusuf(tester);
        await _capture(tester, 'additional_${scale}x');
        await _flip(tester);
        await _press(tester, _key('guardian-card-chat-$_yusuf-draft-aisha'));
        await _makeMain(tester);
        expect(_person(tester, _yusuf).person.isMain, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final change in ['tab', 'revocation', 'ABA', 'account generation']) {
    // Q28 (R2): capture the actual card's actions before the lease expires.
    testWidgets('retained Guardian card actions refuse $change before writes', (
      tester,
    ) async {
      await _mount(tester);
      await _seed(tester);
      await _selectYusuf(tester);
      final history = _action(tester, 'guardian-card-history-$_yusuf').onTap!;
      await _flip(tester);
      final card = _cards(tester);
      final view = _action(
        tester,
        'guardian-card-view-$_yusuf-draft-sara',
      ).onTap!;
      final fixture = zyraShellFixtureFor(tester);
      final model = fixture.model;
      final before = Map.of(model.snapshot().guardianAccess);
      if (change == 'tab') {
        await _nav(tester, 2);
      } else if (change == 'account generation') {
        ZyraAccountState.resetForTesting();
        AppState.instance.resetForAccountChange();
      } else {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        if (change == 'ABA') ZyraDeveloperAccess.setAuthorizedForTesting(true);
      }
      await tester.pumpAndSettle();
      final checkpoint = fixture.latest!;
      view();
      history();
      card.onPermission(_yusuf, 'draft-sara', view: false);
      card.onHistory(_yusuf, true);
      expect(await card.makeMain(_yusuf), isFalse);
      await tester.pumpAndSettle();
      expect(model.snapshot().guardianAccess, before);
      expect(fixture.latest!.guardianHistory, checkpoint.guardianHistory);
      if (change == 'tab') {
        await _nav(tester, 3);
        expect(_person(tester, _yusuf).history, isFalse);
        expect(_person(tester, _hassan).person.isMain, isTrue);
      } else {
        expect(find.text('Preview closed'), findsOneWidget);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  // Q28: removing a Guardian invalidates the access delegate for that card.
  testWidgets('removed Guardian cannot receive a retained card write', (
    tester,
  ) async {
    await _mount(tester);
    await _seed(tester);
    await _selectYusuf(tester);
    await _flip(tester);
    final old = _cards(tester);
    final view = _action(
      tester,
      'guardian-card-view-$_yusuf-draft-sara',
    ).onTap!;
    await _press(tester, _key('guardian-remove'));
    await _press(
      tester,
      find.descendant(
        of: _key('guardian-remove-confirmation'),
        matching: find.text('Confirm'),
      ),
    );
    expect(
      _cards(tester).people.map((card) => card.person.id),
      isNot(contains(_yusuf)),
    );
    final fixture = zyraShellFixtureFor(tester);
    final model = fixture.model;
    final before = Map.of(model.snapshot().guardianAccess);
    final checkpoint = fixture.latest!;
    view();
    old.onPermission(_yusuf, 'draft-sara', view: false);
    old.onHistory(_yusuf, true);
    await tester.pumpAndSettle();
    expect(model.snapshot().guardianAccess, before);
    expect(fixture.latest!.guardianHistory, checkpoint.guardianHistory);
    expect(_person(tester, _hassan).history, isFalse);
  });

  // Q28: preview consent and promotion leave the ordinary account untouched.
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
      await _selectYusuf(tester);
      await _press(tester, _key('guardian-card-history-$_yusuf'));
      await _flip(tester);
      await _makeMain(tester);
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
