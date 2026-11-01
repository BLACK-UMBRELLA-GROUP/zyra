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
  for (
    var depth = 0;
    find.text('Page options').evaluate().isEmpty && depth < 8;
    depth++
  ) {
    await _press(tester, 'draft_back');
  }
  expect(find.text('Page options'), findsOneWidget);
  if (page != null) expect(find.text(page), findsOneWidget);
  expect(_key('draft_rules'), findsNothing);
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
  expect(_motionDropdown, findsOneWidget);
  await tester.ensureVisible(_motionDropdown);
  await tester.pumpAndSettle();
  final selected = tester
      .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(_motionDropdown)
      .initialValue!;
  await tester.tap(_motionDropdown);
  await tester.pumpAndSettle();
  // The button's IndexedStack also retains keyed items. Select only inside
  // the actual popup route, whose ListView builds lower choices lazily.
  final popup = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics && widget.properties.role == ui.SemanticsRole.menu,
    description: 'Next animation popup menu',
  );
  expect(popup, findsOneWidget);
  final popupScrollable = find.descendant(
    of: popup,
    matching: find.byType(Scrollable),
  );
  expect(popupScrollable, findsOneWidget);
  final option = find.descendant(
    of: popup,
    matching: _key('concept_browse_next_motion_${motion.name}'),
  );
  await tester.scrollUntilVisible(
    option,
    motion.index < selected.index ? -80 : 80,
    scrollable: popupScrollable,
    maxScrolls: 24,
  );
  await tester.pumpAndSettle();
  expect(option, findsOneWidget);
  // DropdownMenuItem is aligned content, not the popup's pointer receiver.
  // Its blank centre need not hit its descendants; the native enabled InkWell
  // wrapping this exact keyed choice owns the real selection action.
  final receiver = find
      .ancestor(
        of: option,
        matching: find.byWidgetPredicate(
          (widget) => widget is InkWell && widget.onTap != null,
        ),
      )
      .first;
  expect(receiver, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(receiver), alignment: 0.5);
  await tester.pumpAndSettle();
  final rect = tester.getRect(receiver);
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  final visible = rect
      .intersect(tester.getRect(popupScrollable))
      .intersect(Offset.zero & logicalSize);
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final point = Alignment(
    2 * (visible.center.dx - rect.left) / rect.width - 1,
    2 * (visible.center.dy - rect.top) / rect.height - 1,
  );
  expect(
    receiver.hitTestable(at: point),
    findsOneWidget,
    reason:
        'Native popup receiver for ${motion.name}: '
        'rect=$rect, visible=$visible, tap=${visible.center}.',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(popup, findsNothing);
  expect(
    tester
        .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(_motionDropdown)
        .initialValue,
    motion,
  );
}

void _expectButton(
  WidgetTester tester,
  String id, {
  bool large = false,
  bool centered = false,
}) {
  final root = _key(id);
  final button = tester.widget<OutlinedButton>(root);
  final states = <WidgetState>{};
  expect(button.style!.minimumSize!.resolve(states), const Size(44, 44));
  expect(
    button.style!.padding!.resolve(states),
    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
  expect(button.style!.tapTargetSize, MaterialTapTargetSize.shrinkWrap);
  final shape = button.style!.shape!.resolve(states)!;
  expect(shape, isA<RoundedRectangleBorder>());
  expect(
    (shape as RoundedRectangleBorder).borderRadius,
    BorderRadius.circular(9),
  );
  final texts = tester
      .widgetList<Text>(find.descendant(of: root, matching: find.byType(Text)))
      .toList();
  expect(texts, hasLength(1));
  expect(texts.single.style!.fontSize, 12.5);
  expect(texts.single.style!.fontFamily, _font);
  expect(texts.single.textAlign, centered ? TextAlign.center : TextAlign.start);
  for (final icon in tester.widgetList<Icon>(
    find.descendant(of: root, matching: find.byType(Icon)),
  )) {
    expect(icon.size, 17);
  }
  final height = tester.getSize(root).height;
  expect(height, greaterThanOrEqualTo(44));
  if (!large) expect(height, lessThanOrEqualTo(48));
}

void _expectInventory(WidgetTester tester, {bool large = false}) {
  expect(find.text('Page options'), findsOneWidget);
  expect(find.text('Profiles'), findsOneWidget);
  for (final id in _actions) {
    _expectButton(tester, id, large: large);
  }
  for (final count in [0, 1, 5]) {
    _expectButton(
      tester,
      'draft_compatibility_unlock_$count',
      large: large,
      centered: true,
    );
  }
  for (final id in [
    'concept_journey_preview_1',
    'concept_journey_preview_2',
    'concept_journey_preview_3',
    'draft_membership_seeker_basic',
    'draft_membership_seeker_one',
    'draft_history',
    'draft_fill',
  ]) {
    expect(_key(id), findsNothing, reason: '$id is not a Browse control.');
  }
  _expectNoBrowseChooser();
  expect(_motionDropdown, findsOneWidget);
  final dropdown = tester.widget<DropdownButton<ZyraBrowseNextMotion>>(
    find.descendant(
      of: _motionDropdown,
      matching: find.byType(DropdownButton<ZyraBrowseNextMotion>),
    ),
  );
  expect(dropdown.isExpanded, isTrue);
  expect(dropdown.menuMaxHeight, 320);
  expect(
    dropdown.items!.map((item) => item.value),
    ZyraBrowseNextMotion.values,
  );
  for (final item in dropdown.items!) {
    final text = item.child as Text;
    expect(text.data, item.value!.label);
    expect(text.style!.fontFamily, _font);
    expect(text.style!.fontSize, 13);
  }
  expect(find.text('Explore the idea.'), findsNothing);
  expect(find.text('Browse without swiping.'), findsNothing);
  expect(find.textContaining('This temporary draft'), findsNothing);
}

void _expectJourneyCounts(WidgetTester tester, {bool large = false}) {
  expect(find.text('Page options'), findsOneWidget);
  expect(find.text('Journey'), findsOneWidget);
  expect(_motionDropdown, findsNothing);
  expect(_key('draft_compatibility_unlock_1'), findsNothing);
  final first = tester.getRect(_key('concept_journey_preview_1'));
  final second = tester.getRect(_key('concept_journey_preview_2'));
  final third = tester.getRect(_key('concept_journey_preview_3'));
  expect(first.top, second.top);
  expect(second.top, third.top);
  expect(second.left - first.right, 8);
  expect(third.left - second.right, 8);
  for (final count in [1, 2, 3]) {
    _expectButton(
      tester,
      'concept_journey_preview_$count',
      centered: true,
      large: large,
    );
    final text = tester.widget<Text>(
      find.descendant(
        of: _key('concept_journey_preview_$count'),
        matching: find.byType(Text),
      ),
    );
    expect(text.data, '$count');
    expect(
      text.semanticsLabel,
      'Show $count sample ${count == 1 ? 'Journey' : 'Journeys'}',
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
      await Scrollable.ensureVisible(
        tester.element(_key('draft_role_seeker')),
        alignment: 1,
      );
      await tester.pumpAndSettle();
      await _snapshot(tester, '${viewport.suffix}_lower');
      expect(_key('draft_role_seeker').hitTestable(), findsOneWidget);
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
      final staleMotion = tester
          .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(
            _motionDropdown,
          )
          .onChanged!;
      await _chooseMotion(tester, ZyraBrowseNextMotion.cardRock);
      // Retained UI-revision delegates must not borrow the current controls.
      count();
      role();
      reset();
      staleMotion(ZyraBrowseNextMotion.cardRise);
      await tester.pumpAndSettle();
      expect(find.text('Page options'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(
              _motionDropdown,
            )
            .initialValue,
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
        final staleMotion = tester
            .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(
              _motionDropdown,
            )
            .onChanged!;
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
      await _mount(
        tester,
        home: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: DevDiscoveryDirectionPicker(),
            ),
          ),
        ),
      );
      expect(find.text('Open app preview'), findsOneWidget);
      expect(find.textContaining('Saved'), findsNothing);
      _expectButton(tester, 'dev_discovery_view_request', centered: true);
      await _press(tester, 'dev_discovery_view_request');
      expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
      await _controls(tester);
      await _press(tester, 'draft_close');
      expect(find.byType(DevDiscoveryDirectionPicker), findsOneWidget);
      expect(ZyraConceptPreviewIsolation.active, isFalse);
    },
  );
}
