import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
// Compact developer controls inside the actual guarded, offline preview route.
// This suite does not initialize Auth, connect to a service or alter a member.
import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_browse_next_photo_motion.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

// Retired control identities remain absence-only regression evidence.
const _historicalBrowseControlNames = [
  'portraitCard',
  'photoStrip',
  'compactList',
  'twoColumnGallery',
  'profileFolio',
  'galleryStack',
  'galleryDuo',
  'galleryMosaic',
  'galleryRail',
  'galleryFrame',
  'gallerySplit',
  'galleryContactSheet',
  'galleryRibbon',
  'galleryAlbum',
  'galleryFocus',
  'peoplePortraitGrid',
  'peopleMosaic',
  'peopleStaggered',
  'peopleEditorialRows',
  'peopleContactSheet',
  'peopleSideBySide',
  'peopleFramedPortraits',
  'peopleFilmstrip',
  'peoplePairedAlbums',
  'peopleSpotlight',
];

const _capture = bool.fromEnvironment('ZYRA_COMPACT_CONTROLS_CAPTURE');
const _boundary = ValueKey('compact-controls-candidate');
const _candidates = 'visual/candidates/compact_preview_controls_2026_10_09';
const _font = 'PoppinsCompactPreviewControls';
const _wordmark = 'SyneCompactPreviewControls';
const _actions = ['draft_reset', 'draft_role_guardian', 'draft_role_seeker'];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Compact preview controls must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

Widget _app(Widget home, {double scale = 1, double top = 59}) => MaterialApp(
  navigatorObservers: [ZyraPreviewRouteObserver()],
  debugShowCheckedModeBanner: false,
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
  home: home,
);

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  double scale = 1,
  double top = 59,
  Widget? home,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      home ??
          ViewRequestDraftScreen(
            fixture: ZyraShellTestFixture().fixture,
            ownerGeneration: ZyraAccountState.generation,
            ownerId: ZyraAccountState.userId,
          ),
      scale: scale,
      top: top,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

VoidCallback? _action(WidgetTester tester, String id) {
  if (isZyraFixtureCommandKey(id)) return captureZyraFixtureCommand(tester, id);
  final widget = tester.widget<Widget>(_key(id));
  if (widget is ButtonStyleButton) return widget.onPressed;
  if (widget is InkWell) return widget.onTap;
  final ink = find.descendant(of: _key(id), matching: find.byType(InkWell));
  expect(ink, findsOneWidget, reason: '$id has one real touch target');
  return tester.widget<InkWell>(ink).onTap;
}

Future<void> _press(WidgetTester tester, String id) async {
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  expect(target, findsOneWidget);
  final scroller = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scroller.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  var visible = tester
      .getRect(target)
      .intersect(Offset.zero & tester.view.physicalSize);
  if (scroller.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(scroller.first));
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  final point = Alignment(
    local.dx * 2 / box.size.width - 1,
    local.dy * 2 / box.size.height - 1,
  );
  expect(target.hitTestable(at: point), findsOneWidget);
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder get _motionDropdown =>
    find.byType(DropdownButtonFormField<ZyraBrowseNextMotion>);

Future<void> _returnToMain(WidgetTester tester) async {
  for (
    var depth = 0;
    find.byType(ZyraShellNavigation).evaluate().isEmpty && depth < 8;
    depth++
  ) {
    if (find.text('Page options').evaluate().isNotEmpty) {
      await returnZyraPreviewPage(tester);
    } else {
      final scope = _key('concept_pull_down_back_scope');
      if (scope.evaluate().isEmpty) {
        await returnZyraPreviewPage(tester);
      } else {
        await returnZyraPreviewPage(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  }
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
}

Future<void> _controls(WidgetTester tester, {String? page}) async {
  if (page != null) {
    await _returnToMain(tester);
    await _nav(tester, page);
  }
  await openZyraDevControls(tester);
  expect(find.text('Page options'), findsNothing);
  expect(ZyraConceptPreviewIsolation.active, isTrue);
}

void _expectNoBrowseChooser() {
  expect(find.text('Browse design'), findsNothing);
  expect(_key('concept_try_browse_design'), findsNothing);
  for (final name in _historicalBrowseControlNames) {
    expect(_key('concept_browse_design_$name'), findsNothing);
  }
}

Future<void> _chooseMotion(
  WidgetTester tester,
  ZyraBrowseNextMotion motion,
) async {
  expect(zyraShellFixtureFor(tester).selectBrowseMotion(motion), isTrue);
  await tester.pumpAndSettle();
  expect(_motionDropdown, findsNothing);
}

void _expectButton(
  WidgetTester tester,
  String id, {
  bool large = false,
  bool centered = false,
}) {
  expect(
    _key(id),
    findsNothing,
    reason: '$id is available only as a code fixture.',
  );
}

void _expectInventory(WidgetTester tester, {bool large = false}) {
  expect(find.text('Page options'), findsNothing);
  for (final id in [
    ..._actions,
    for (final count in [0, 1, 5]) 'draft_compatibility_unlock_$count',
  ]) {
    _expectButton(tester, id, large: large);
  }
  expect(_motionDropdown, findsNothing);
  _expectNoBrowseChooser();
  expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
  expect(find.text('Explore the idea.'), findsNothing);
  expect(find.text('Browse without swiping.'), findsNothing);
  expect(find.textContaining('This temporary draft'), findsNothing);
}

void _expectJourneyCounts(WidgetTester tester, {bool large = false}) {
  expect(find.text('Page options'), findsNothing);
  expect(find.text('Journey'), findsOneWidget);
  expect(_motionDropdown, findsNothing);
  for (final count in [1, 2, 3]) {
    _expectButton(
      tester,
      'concept_journey_preview_$count',
      large: large,
      centered: true,
    );
  }
}

List<String> _destinations(WidgetTester tester) => tester
    .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
    .items
    .map((item) => item.label)
    .toList();

Future<void> _nav(WidgetTester tester, String label) async {
  final navigation = tester.widget<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  final index = navigation.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  final icon = find.descendant(
    of: find.byType(ZyraShellNavigation),
    matching: navigation.items[index].useJourneyGlyph
        ? find.byType(ZyraJourneyIcon)
        : find.byIcon(navigation.items[index].icon),
  );
  expect(icon, findsOneWidget);
  // The canonical bar's real gesture detector owns icon hit testing.
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        bytes!.buffer.asUint8List(),
        matchesGoldenFile('$_candidates/$name.png'),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFatal = WidgetController.hitTestWarningShouldBeFatal;
  final previousHttp = HttpOverrides.current;
  late _NoNetwork network;
  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    final reading = FontLoader(_font);
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
    final wordmark = FontLoader(_wordmark)
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
  });
  tearDownAll(() {
    WidgetController.hitTestWarningShouldBeFatal = previousFatal;
    HttpOverrides.global = previousHttp;
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraText.testWordmarkFontFamily = _wordmark;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    AppState.instance.name = 'Ordinary fixture';
    AppState.instance.gender = 'female';
    AppState.instance.plan = ZyraPlan.one;
    ZyraAccountState.clearImagesForTesting = () async {};
    SharedPreferences.setMockInitialValues({'ordinary-setting': 'unchanged'});
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousHttp;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final viewport in const [
    (size: Size(393, 852), suffix: '393'),
    (size: Size(430, 932), suffix: '430'),
  ]) {
    testWidgets('${viewport.suffix} controls have compact current-theme rows', (
      tester,
    ) async {
      await _mount(tester, size: viewport.size);
      await _controls(tester);
      _expectInventory(tester);
      await _snapshot(tester, '${viewport.suffix}_initial');
      expect(_key('draft_role_seeker'), findsNothing);
      await _snapshot(tester, '${viewport.suffix}_lower');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'ordinary-setting'});
      expect(prefs.getString('ordinary-setting'), 'unchanged');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'compact Browse page options preserve fixed Portrait, data and local motion',
    (tester) async {
      await _mount(tester);
      final before = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      final ids = before.profiles.map((person) => person.id).toList();
      final selectedId = before.profiles[before.selectedIndex].id;
      await _controls(tester);
      _expectNoBrowseChooser();
      await _chooseMotion(tester, ZyraBrowseNextMotion.fanTurn);
      await _press(tester, 'draft_back');
      for (final destination in ['My ZYRA', 'Profile', 'Profiles']) {
        await _nav(tester, destination);
      }
      final after = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      expect(after.design, ZyraOneJourneyBrowseDesign.portraitCard);
      expect(after.profiles.map((person) => person.id), ids);
      expect(after.profiles[after.selectedIndex].id, selectedId);
      expect(after.nextProfileMotion, ZyraBrowseNextMotion.fanTurn);
      expect(_destinations(tester), [
        'Profiles',
        'Journey',
        'My ZYRA',
        'Guardian',
        'Profile',
      ]);
      expect(AppState.instance.activeJourneys, isEmpty);
    },
  );

  for (final count in [1, 2, 3]) {
    testWidgets('compact count $count seeds only the intended Journey page', (
      tester,
    ) async {
      await _mount(tester);
      await _controls(tester, page: 'Journey');
      _expectJourneyCounts(tester);
      await _press(tester, 'concept_journey_preview_$count');
      expect(find.text('Journey'), findsOneWidget);
      expect(
        find.byType(ZyraOneJourneyConnectionsActiveCard),
        findsNWidgets(count),
      );
      expect(find.text('Page options'), findsNothing);
      expect(AppState.instance.activeJourneys, isEmpty);
      await _controls(tester);
      for (final available in [1, 2, 3]) {
        expect(
          _action(tester, 'concept_journey_preview_$available'),
          isNotNull,
        );
      }
    });
  }

  testWidgets(
    'compact membership preserves Basic/Monthly capacity and disabled gates',
    (tester) async {
      await _mount(tester);
      await _controls(tester, page: 'Profile');
      await _press(tester, 'draft_membership_seeker_basic');
      await _controls(tester, page: 'Journey');
      expect(_action(tester, 'concept_journey_preview_1'), isNotNull);
      expect(_action(tester, 'concept_journey_preview_2'), isNull);
      expect(_action(tester, 'concept_journey_preview_3'), isNull);
      await _press(tester, 'concept_journey_preview_1');
      expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsOneWidget);
      await _controls(tester, page: 'Profile');
      await _press(tester, 'draft_membership_seeker_one');
      await _controls(tester, page: 'Journey');
      expect(_action(tester, 'concept_journey_preview_3'), isNotNull);
      await _press(tester, 'concept_journey_preview_3');
      expect(
        find.byType(ZyraOneJourneyConnectionsActiveCard),
        findsNWidgets(3),
      );
      await _controls(tester, page: 'Profile');
      await _press(tester, 'draft_membership_seeker_basic');
      // Rejection feedback stays readable above controls, then survives the
      // real X return to the unchanged member page.
      expect(
        find.textContaining('Existing sample Journeys have not been removed.'),
        findsOneWidget,
      );
      await closeZyraDevControls(tester);
      expect(
        find.textContaining('Existing sample Journeys have not been removed.'),
        findsOneWidget,
      );
      await _controls(tester, page: 'Journey');
      expect(_action(tester, 'concept_journey_preview_3'), isNotNull);
      expect(AppState.instance.activeJourneys, isEmpty);
    },
  );

  testWidgets(
    'compact Active/Ended/reset actions preserve current and ordinary state',
    (tester) async {
      await _mount(tester);
      await _controls(tester, page: 'Journey');
      expect(_key('draft_fill'), findsNothing);
      await _press(tester, 'concept_journey_preview_1');
      expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsOneWidget);
      await _controls(tester, page: 'My ZYRA');
      await _press(tester, 'draft_history');
      await returnZyraPreviewPage(tester);
      expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsNothing);
      expect(
        _key('my-zyra-route-concept-current-journey-draft-sara'),
        findsNothing,
      );
      await _nav(tester, 'My ZYRA');
      expect(_key('my-zyra-route-concept-my-ended'), findsOneWidget);
      expect(find.text('1 ended'), findsOneWidget);
      expect(find.text('Paused Journeys'), findsNothing);
      await _press(tester, 'my-zyra-route-concept-my-ended');
      expect(find.text('Ended Journeys'), findsOneWidget);
      expect(_key('draft_journey_draft-noor_header'), findsOneWidget);
      expect(
        tester
            .widget<ZyraOneJourneyConnectionsActiveCard>(
              find.byType(ZyraOneJourneyConnectionsActiveCard),
            )
            .profile
            .id,
        'draft-noor',
      );
      await _controls(tester);
      await _press(tester, 'draft_reset');
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      await _nav(tester, 'Journey');
      expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsNothing);
      await _nav(tester, 'My ZYRA');
      expect(_key('my-zyra-route-concept-my-ended'), findsOneWidget);
      expect(find.text('0 ended'), findsOneWidget);
      await _press(tester, 'my-zyra-route-concept-my-ended');
      expect(find.text('No ended Journeys'), findsOneWidget);
      await _controls(tester, page: 'Journey');
      expect(_action(tester, 'concept_journey_preview_3'), isNotNull);
      expect(AppState.instance.activeJourneys, isEmpty);
    },
  );

  testWidgets(
    'compact Guardian/Seeker account controls keep role-specific routes',
    (tester) async {
      await _mount(tester);
      final ordinaryAccount = (
        AppState.instance.name,
        AppState.instance.gender,
        AppState.instance.plan,
      );
      await _controls(tester);
      await _press(tester, 'draft_role_guardian');
      expect(_destinations(tester), [
        'Dashboard',
        'Network',
        'Seekers',
        'Profile',
      ]);
      await _controls(tester);
      expect(_key('draft_role_seeker'), findsOneWidget);
      await _press(tester, 'draft_role_seeker');
      expect(_destinations(tester), [
        'Profiles',
        'Journey',
        'My ZYRA',
        'Guardian',
        'Profile',
      ]);
      expect((
        AppState.instance.name,
        AppState.instance.gender,
        AppState.instance.plan,
      ), ordinaryAccount);
      expect(AppState.instance.activeJourneys, isEmpty);
    },
  );

  testWidgets('compact 200% controls wrap and remain genuinely reachable', (
    tester,
  ) async {
    await _mount(tester, size: const Size(320, 568), scale: 2, top: 44);
    await _controls(tester);
    _expectInventory(tester, large: true);
    await _snapshot(tester, 'compact_200_initial');
    await _chooseMotion(tester, ZyraBrowseNextMotion.elasticCard);
    await _controls(tester, page: 'Profile');
    await _press(tester, 'draft_membership_seeker_basic');
    await _controls(tester, page: 'Journey');
    _expectJourneyCounts(tester, large: true);
    expect(_action(tester, 'concept_journey_preview_2'), isNull);
    await _controls(tester, page: 'Profile');
    await _press(tester, 'draft_membership_seeker_one');
    await _controls(tester, page: 'Journey');
    await _press(tester, 'concept_journey_preview_3');
    expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsNWidgets(3));
    await _controls(tester);
    await _press(tester, 'draft_reset');
    await _controls(tester);
    await Scrollable.ensureVisible(
      tester.element(_key('draft_role_seeker')),
      alignment: 1,
    );
    await tester.pumpAndSettle();
    await _snapshot(tester, 'compact_200_lower');
    expect(_key('draft_role_seeker').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact controls reject retained callbacks after a newer choice',
    (tester) async {
      await _mount(tester);
      await _controls(tester, page: 'Journey');
      final count = _action(tester, 'concept_journey_preview_3')!;
      await _controls(tester, page: 'Profiles');
      final role = _action(tester, 'draft_role_guardian')!;
      final reset = _action(tester, 'draft_reset')!;
      final staleMotion = captureZyraBrowseMotionAction(tester);
      await _chooseMotion(tester, ZyraBrowseNextMotion.cardRock);
      // Retained UI-revision delegates must not borrow the current controls.
      count();
      role();
      reset();
      staleMotion(ZyraBrowseNextMotion.cardRise);
      await tester.pumpAndSettle();
      expect(find.text('Page options'), findsNothing);
      expect(
        tester
            .widget<ZyraOneJourneyBrowseDesigns>(
              find.byType(ZyraOneJourneyBrowseDesigns),
            )
            .nextProfileMotion,
        ZyraBrowseNextMotion.cardRock,
      );
      _expectNoBrowseChooser();
      await _press(tester, 'draft_back');
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      expect(browse.design, ZyraOneJourneyBrowseDesign.portraitCard);
      expect(browse.nextProfileMotion, ZyraBrowseNextMotion.cardRock);
      expect(_destinations(tester).first, 'Profiles');
      expect(AppState.instance.activeJourneys, isEmpty);
    },
  );

  for (final change in ['account generation', 'revocation', 'ABA']) {
    testWidgets(
      'compact controls reject current Browse delegates after $change',
      (tester) async {
        await _mount(tester);
        await _controls(tester);
        final staleMotion = captureZyraBrowseMotionAction(tester);
        final delegates = <VoidCallback>[
          for (final id in _actions) _action(tester, id)!,
          for (final count in [0, 1, 5])
            _action(tester, 'draft_compatibility_unlock_$count')!,
          () => staleMotion(ZyraBrowseNextMotion.cardGlide),
        ];
        if (change == 'account generation') {
          ZyraAccountState.resetForTesting();
          AppState.instance.resetForAccountChange();
        } else {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          if (change == 'ABA') {
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
        }
        for (final delegate in delegates) {
          delegate();
        }
        await tester.pumpAndSettle();
        expect(find.text('Preview closed'), findsOneWidget);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        expect(ZyraConceptPreviewIsolation.active, isFalse);
        expect(AppState.instance.activeJourneys, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('compact exit returns from the actual guarded preview route', (
    tester,
  ) async {
    await _mount(
      tester,
      home: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('test-open-compact-preview'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ViewRequestDraftScreen(
                    fixture: ZyraShellTestFixture().fixture,
                    ownerGeneration: ZyraAccountState.generation,
                    ownerId: ZyraAccountState.userId,
                  ),
                ),
              ),
              child: const Text('Current app fixture'),
            ),
          ),
        ),
      ),
    );
    await _press(tester, 'test-open-compact-preview');
    await _controls(tester);
    await _press(tester, 'draft_close');
    expect(find.text('Current app fixture'), findsOneWidget);
    expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
    expect(ZyraConceptPreviewIsolation.active, isFalse);
  });

  testWidgets(
    'compact launcher retains guarded entry without stale Saved copy',
    (tester) async {
      await _mount(tester);
      final shell = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      expect(shell.canAct(), isTrue);
      expect(find.textContaining('Saved'), findsNothing);
      expect(_key('dev_discovery_view_request'), findsNothing);
      final navigation = tester.widget<ZyraShellNavigation>(
        find.byType(ZyraShellNavigation),
      );
      final savedNavigation = navigation.onTap;
      final originalTab = navigation.currentIndex;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      savedNavigation((originalTab + 1) % navigation.items.length);
      await tester.pumpAndSettle();
      expect(shell.canAct(), isFalse);
      final remaining = find.byType(ZyraShellNavigation);
      if (remaining.evaluate().isNotEmpty) {
        expect(
          tester.widget<ZyraShellNavigation>(remaining).currentIndex,
          originalTab,
        );
      }
      expect(_key('dev_discovery_view_request'), findsNothing);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await _mount(
        tester,
        home: ViewRequestDraftScreen(
          key: UniqueKey(),
          ownerId: ZyraAccountState.userId,
          ownerGeneration: ZyraAccountState.generation,
          fixture: ZyraShellTestFixture().fixture,
        ),
      );
      expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
      expect(
        tester
            .widget<ZyraOneJourneyConceptShell>(
              find.byType(ZyraOneJourneyConceptShell),
            )
            .canAct(),
        isTrue,
      );
      expect(shell.canAct(), isFalse);
      expect(find.textContaining('Saved'), findsNothing);
      expect(_key('dev_discovery_view_request'), findsNothing);
    },
  );
}
