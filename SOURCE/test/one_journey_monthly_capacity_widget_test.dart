import 'support/profile_swipe_driver.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_card_content.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_one_journey_options_page.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

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

const _journeyPeople = [
  (id: 'draft-sara', name: 'Sara'),
  (id: 'draft-aisha', name: 'Aisha'),
  (id: 'draft-maryam', name: 'Maryam'),
];
Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _mount(
  WidgetTester tester, {
  double scale = 1,
  Size size = const Size(390, 844),
  double topInset = 44,
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
          textScaler: TextScaler.linear(scale),
          padding: EdgeInsets.only(top: topInset, bottom: 34),
          viewPadding: EdgeInsets.only(top: topInset, bottom: 34),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: ViewRequestDraftScreen(
        key: UniqueKey(),
        fixture: ZyraShellTestFixture(receivedRequest: true).fixture,
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Sample image codecs complete on the real event loop. Wait for the
  // protected shell's prepared public deck before switching to Journey or
  // Guardian pages; keep all subsequent lifecycle and geometry checks intact.
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      if (browse.profiles.isNotEmpty &&
          browse.profiles.every((profile) => profile.photos.isNotEmpty)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tester.pump();
    }
    fail('The offline Browse deck did not publish prepared photo frames.');
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

VoidCallback? _action(WidgetTester tester, String id) {
  if (isZyraFixtureCommandKey(id)) return captureZyraFixtureCommand(tester, id);
  final target = tester.widget<Widget>(_key(id));
  if (target is ButtonStyleButton) return target.onPressed;
  if (target is InkWell) return target.onTap;
  if (target is GestureDetector) return target.onTap;
  final ink = find.descendant(of: _key(id), matching: find.byType(InkWell));
  if (ink.evaluate().isNotEmpty) return tester.widget<InkWell>(ink.first).onTap;
  throw TestFailure(
    '$id has an unsupported action type: ${target.runtimeType}',
  );
}

Future<void> _press(WidgetTester tester, String id) async {
  if (await swipeProfileForControlKey(tester, id)) return;
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  expect(target, findsOneWidget, reason: 'Current member target $id');
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }
  // Reveal enlarged actions above the unchanged floating navigation. A genuine
  // tap must hit the exact target; a retained delegate is not tap coverage.
  if (find
          .ancestor(of: target, matching: _key('concept_browse_design_scroll'))
          .evaluate()
          .isNotEmpty &&
      tester.getRect(target).bottom >
          tester.view.physicalSize.height -
              34 -
              ZyraNavBarMetrics.legacyRestingHeight -
              ZyraNavBarMetrics.bottomInset) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  var visible = tester
      .getRect(target)
      .intersect(Offset.zero & tester.view.physicalSize);
  final scroll = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scroll.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(scroll.first));
  }
  expect(visible.width, greaterThan(0), reason: '$id must be on screen');
  expect(visible.height, greaterThan(0), reason: '$id must be on screen');
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  final alignment = Alignment(
    2 * local.dx / box.size.width - 1,
    2 * local.dy / box.size.height - 1,
  );
  expect(
    target.hitTestable(at: alignment),
    findsOneWidget,
    reason: '$id must receive the actual tap at ${visible.center}',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  final bars = tester.widgetList<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  if (bars.isNotEmpty && bars.first.items.first.label == 'Network') {
    index = const [2, 0, 3, 4][index];
  }

  for (
    var depth = 0;
    find.byType(ZyraShellNavigation).evaluate().isEmpty && depth < 6;
    depth++
  ) {
    if (zyraShellFixtureFor(tester).setupScopeOpen) {
      await closeZyraDevControls(tester);
      continue;
    }
    await returnZyraPreviewPage(tester);
  }
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  await expandZyraPreviewTabBarIfIdle(tester);
  final cell = _key('floating-nav-item-$index');
  expect(cell, findsOneWidget);
  final nav = find.byType(FloatingNavBar);
  final box = tester.renderObject<RenderBox>(nav);
  final point = box.globalToLocal(tester.getCenter(cell));
  expect(
    nav.hitTestable(
      at: Alignment(
        point.dx * 2 / box.size.width - 1,
        point.dy * 2 / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(tester.getCenter(cell));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'Root destination $index');
}

Future<void> _openControls(WidgetTester tester) async {
  await openZyraDevControls(tester);
  expect(find.text('Page options'), findsNothing);
  expect(_key('concept_page_options_context'), findsNothing);
}

void _expectNoBrowseChooser() {
  expect(find.text('Browse design'), findsNothing);
  for (final name in _historicalBrowseControlNames) {
    expect(_key('concept_browse_design_$name'), findsNothing);
  }
}

Future<void> _scenario(WidgetTester tester, int count) async {
  await _nav(tester, 1);
  await _openControls(tester);
  expect(_key('concept_page_options_context'), findsNothing);
  await _press(tester, 'concept_journey_preview_$count');
  await closeZyraDevControls(tester);
}

ZyraOneJourneyTab _places(WidgetTester tester) =>
    tester.widget(find.byType(ZyraOneJourneyTab));

Future<void> _selectPlace(WidgetTester tester, String id) async {
  final places = _places(tester);
  final index = places.journeys.indexWhere((entry) => entry.id == id);
  expect(index, greaterThanOrEqualTo(0));
  for (var step = 0; step < (index - places.index).abs(); step++) {
    await _press(
      tester,
      index > places.index ? 'journey_tab_next' : 'journey_tab_previous',
    );
  }
  expect(_places(tester).index, index);
}

Future<void> _openJourney(WidgetTester tester, String id) async {
  await _selectPlace(tester, id);
  await _press(tester, 'journey_tab_continue');
}

void _expectCardChooserAbsent() {
  expect(find.text('Journey cards'), findsNothing);
  expect(_key('concept_journey_card_layout'), findsNothing);
  expect(find.text('Journey card content'), findsNothing);
  expect(_key('concept_try_journey_card_design'), findsNothing);
  for (final design in ZyraOneJourneyCardDesign.values) {
    expect(_key('concept_journey_card_design_${design.name}'), findsNothing);
  }
}

Future<void> _pressLocalJourneyControl(WidgetTester tester, String id) async {
  final pages = _key('concept_current_journey_pages');
  if (pages.evaluate().isNotEmpty) {
    final stage = tester
        .widget<ZyraConceptJourneyPresentation>(
          find.byType(ZyraConceptJourneyPresentation),
        )
        .stage;
    final pager = tester.widget<PageView>(pages).controller!;
    if (pager.page! <= stage.order - 1) {
      await tester.drag(pages, Offset(0, -tester.getSize(pages).height * .8));
      await tester.pumpAndSettle();
    }
  }
  await _press(tester, id);
}

void _expectJourneys(WidgetTester tester, int count) {
  final places = _places(tester);
  expect(
    places.journeys.map((card) => card.id),
    unorderedEquals([
      for (final person in _journeyPeople.take(count)) person.id,
    ]),
  );
  expect(find.text('Journey'), findsOneWidget);
  expect(_key('concept_journey_capacity_summary'), findsNothing);
  expect(find.text('Your Journeys'), findsNothing);
  if (count == 0) {
    expect(find.text('No Journey yet'), findsOneWidget);
    expect(_key('journey_tab_continue'), findsNothing);
  } else {
    final selected = places.index < count
        ? places.journeys[places.index]
        : null;
    for (final person in places.journeys) {
      expect(person.photo, isA<AssetImage>());
      expect(
        _key('draft_journey_options_${person.id}'),
        person == selected ? findsOneWidget : findsNothing,
      );
    }
  }
  expect(_key('concept_activity_requests'), findsNothing);
  expect(_key('concept_activity_saved'), findsNothing);
  expect(_key('concept_activity_paused'), findsNothing);
  expect(_key('concept_activity_ended'), findsNothing);
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError(
      'Monthly Journey previews must not create an HTTP client.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFatalHitTests = WidgetController.hitTestWarningShouldBeFatal;
  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    // Compact bounds must use the same real glyphs as visual captures.
    final reading = FontLoader('PoppinsMonthlyJourneyAudit');
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
    final wordmark = FontLoader('SyneMonthlyJourneyAudit')
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
    WidgetController.hitTestWarningShouldBeFatal = previousFatalHitTests;
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsMonthlyJourneyAudit';
    ZyraText.testWordmarkFontFamily = 'SyneMonthlyJourneyAudit';
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  // QUESTIONS Q29: the empty reader has three places and no fabricated person.
  testWidgets('monthly starts with three places and no fabricated Journey', (
    tester,
  ) async {
    await _mount(tester);
    await _nav(tester, 1);
    _expectJourneys(tester, 0);
    expect(_key('concept_journey_capacity_summary'), findsNothing);
    await _openControls(tester);
    for (final count in [1, 2, 3]) {
      expect(_key('concept_journey_preview_$count'), findsNothing);
      expect(_action(tester, 'concept_journey_preview_$count'), isNotNull);
    }
  });

  // QUESTIONS Q29: read the one current empty state at all retained scales.
  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0),
    (size: Size(320, 568), scale: 1.4),
    (size: Size(320, 568), scale: 2.0),
  ]) {
    testWidgets('empty Journey remains readable at ${viewport.scale}x', (
      tester,
    ) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester, size: viewport.size, scale: viewport.scale);
        await _nav(tester, 1);
        _expectJourneys(tester, 0);
        expect(_places(tester).capacity, 3);
        final title = find.text('No Journey yet');
        expect(title.hitTestable(), findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    });
  }

  // QUESTIONS Q29: use the current shared LOCK 22 V3 empty state, e01.
  testWidgets('Introductions empty state uses the locked Monogram typography', (
    tester,
  ) async {
    await _mount(tester);
    await _nav(tester, 2);
    await _press(tester, 'concept-my-introductions');
    expect(find.byType(ZyraEmptyState), findsOneWidget);
    final title = find.text('No introductions yet');
    final message = find.text(
      'People your Guardians put forward will appear here.',
    );
    expect(title, findsOneWidget);
    expect(message, findsOneWidget);
    expect(tester.widget<Text>(title).style?.fontSize, 21);
    expect(tester.widget<Text>(title).style?.fontWeight, FontWeight.w300);
    expect(tester.widget<Text>(message).style?.fontSize, 12.5);
    expect(tester.widget<Text>(message).style?.height, 1.5);
    expect(
      tester.getTopLeft(message).dy,
      greaterThan(tester.getBottomLeft(title).dy),
    );
    expect(tester.takeException(), isNull);
  });

  // QUESTIONS Q29: visit one place at a time and keep its real owner.
  for (final count in [1, 2, 3]) {
    testWidgets('$count selected monthly Journeys each open their own person', (
      tester,
    ) async {
      for (final size in const [
        Size(390, 844),
        Size(393, 852),
        Size(430, 932),
      ]) {
        await _mount(tester, size: size, topInset: size.width == 390 ? 44 : 59);
        await _scenario(tester, count);
        _expectJourneys(tester, count);
        for (final person in _journeyPeople.take(count)) {
          await _openJourney(tester, person.id);
          final journey = tester.widget<ZyraConceptJourneyPresentation>(
            find.byType(ZyraConceptJourneyPresentation),
          );
          expect(journey.firstName, person.name);
          expect(journey.stage.order, 1);
          expect(_key('concept_journey_${person.id}'), findsOneWidget);
          await returnZyraPreviewPage(tester);
          _expectJourneys(tester, count);
          final places = _places(tester);
          expect(places.journeys[places.index].id, person.id);
        }
      }
    });
  }

  // QUESTIONS Q29: even full Monthly places retain independent Browse.
  testWidgets(
    'monthly Browse remains available even while all three places are used',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        for (final count in [1, 2, 3]) {
          await _scenario(tester, count);
          _expectJourneys(tester, count);
          await _nav(tester, 0);
          final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
          expect(browse.profiles, isNotEmpty);
          for (final person in _journeyPeople.take(count)) {
            expect(
              browse.profiles.map((profile) => profile.id),
              isNot(contains(person.id)),
            );
          }
          expect(_key('concept_profile_swipe_track'), findsOneWidget);
          expect(find.text('Your Journey places are full.'), findsNothing);
          await _nav(tester, 1);
          _expectJourneys(tester, count);
        }
      }, network);
      expect(network.attempts, 0);
    },
  );

  // QUESTIONS Q29: a Basic reduction cannot evict another person.
  testWidgets(
    'Basic refuses reduction below occupied places and keeps one place',
    (tester) async {
      await _mount(tester);
      await _scenario(tester, 3);
      final fixture = zyraShellFixtureFor(tester);
      final full = fixture.latest!.model;
      expect(fixture.setSeekerBasic(true), isFalse);
      await tester.pumpAndSettle();
      _expectJourneys(tester, 3);
      expect(fixture.latest!.model.states, full.states);
      expect(fixture.latest!.model.progress, full.progress);
      await _scenario(tester, 1);
      await _openControls(tester);
      final staleTwo = _action(tester, 'concept_journey_preview_2')!;
      final staleThree = _action(tester, 'concept_journey_preview_3')!;
      await _nav(tester, 4);
      await _openControls(tester);
      await _press(tester, 'draft_membership_seeker_basic');
      staleTwo();
      staleThree();
      await tester.pumpAndSettle();
      await _nav(tester, 1);
      await _openControls(tester);
      for (final count in [2, 3]) {
        expect(_action(tester, 'concept_journey_preview_$count'), isNull);
      }
      await _nav(tester, 1);
      _expectJourneys(tester, 1);
      expect(_places(tester).capacity, 1);
      expect(_action(tester, 'journey_tab_next'), isNull);
      await closeZyraDevControls(tester);
      await _nav(tester, 0);
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsNothing);
      await _nav(tester, 4);
      await _openControls(tester);
      await _press(tester, 'draft_membership_seeker_one');
      await _nav(tester, 1);
      _expectJourneys(tester, 1);
      await _scenario(tester, 3);
      _expectJourneys(tester, 3);
    },
  );

  // QUESTIONS Q29: current Focus routes keep preview and member state isolated.
  testWidgets(
    'monthly controls keep Portrait and single My ZYRA without Save or Pause',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        SharedPreferences.setMockInitialValues({
          'ordinary-setting': 'unchanged',
        });
        final prefs = await tester.runAsync(SharedPreferences.getInstance);
        Map<String, Object?> snapshot() => {
          for (final key in prefs!.getKeys()) key: prefs.get(key),
        };
        final beforePreferences = snapshot();
        final app = AppState.instance;
        app
          ..name = 'Ordinary member'
          ..surnameLine = 'Preserved account'
          ..photos = ['unchanged-photo-reference']
          ..plan = ZyraPlan.one;
        app.saved.add(
          const SeekerProfile(
            id: 'ordinary-saved-fixture',
            firstName: 'Unchanged',
            age: 31,
            city: 'London',
            photos: [],
            gender: 'female',
          ),
        );
        final ordinarySaved = List.of(app.saved);
        final ordinaryActive = List.of(app.activeJourneys);
        final ordinaryPotential = List.of(app.potentialJourneys);
        final generation = ZyraAccountState.generation;
        final userId = ZyraAccountState.userId;
        final palette = ZyraColors.devPalette;
        final gold = ZyraAppGoldStyle.instance.enabled;
        final font = ZyraText.appFont;
        final haptic = ZyraInteractionStyle.hapticLevel;
        var memberChanges = 0;
        void changed() => memberChanges++;
        app.addListener(changed);
        addTearDown(() => app.removeListener(changed));
        await _mount(tester);
        await _scenario(tester, 1);
        await _openControls(tester);
        _expectNoBrowseChooser();
        await _nav(tester, 0);
        final body = tester.widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
        expect(body.design, ZyraOneJourneyBrowseDesign.portraitCard);
        final viewed = body.profiles[body.selectedIndex].id;
        expect(_key('concept_save_$viewed'), findsNothing);
        expect(find.text('Save'), findsNothing);
        expect(find.text('Saved'), findsNothing);
        await _nav(tester, 2);
        expect(_key('my-zyra-route-concept-saved'), findsNothing);
        expect(_key('my-zyra-route-concept-my-paused'), findsNothing);
        expect(find.text('Saved'), findsNothing);
        expect(find.text('Paused Journeys'), findsNothing);
        expect(find.text('Now'), findsNothing);
        expect(find.text('Insights'), findsNothing);
        expect(_key('my-zyra-pages'), findsNothing);
        expect(
          find.byType(PageView),
          findsNothing,
          reason: 'Simplified My ZYRA is one vertical reading page',
        );
        await _press(tester, 'concept-my-requests');
        expect(find.text('Journey requests'), findsOneWidget);
        expect(_key('concept_request_draft-amira_header'), findsOneWidget);
        await _press(tester, 'draft_requests_1');
        expect(_key('draft_requests_1'), findsOneWidget);
        await _nav(tester, 0);
        expect(
          tester
              .widget<ZyraOneJourneyBrowseDesigns>(
                find.byType(ZyraOneJourneyBrowseDesigns),
              )
              .design,
          ZyraOneJourneyBrowseDesign.portraitCard,
        );
        // Browsing and navigation make no request and never mutate the
        // ordinary member's saved list. The simplified preview exposes no
        // Save action, not merely a hidden Saved section.
        expect(_key('concept_save_$viewed'), findsNothing);
        await _nav(tester, 2);
        await _openControls(tester);
        await _press(tester, 'draft_history');
        await _nav(tester, 2);
        expect(_key('my-zyra-route-concept-my-paused'), findsNothing);
        expect(find.textContaining('Paused'), findsNothing);
        await _press(tester, 'concept-my-ended');
        expect(_key('concept_activity_ended'), findsOneWidget);
        expect(
          find.byType(ZyraOneJourneyConnectionsActiveCard),
          findsOneWidget,
        );
        expect(_key('draft_restart_draft-noor'), findsOneWidget);
        expect(_key('draft_journey_options_draft-noor'), findsOneWidget);
        expect(find.textContaining('Paused'), findsNothing);
        await _nav(tester, 1);
        _expectJourneys(tester, 1);
        expect(snapshot(), beforePreferences);
        expect(app.name, 'Ordinary member');
        expect(app.surnameLine, 'Preserved account');
        expect(app.photos, ['unchanged-photo-reference']);
        expect(app.plan, ZyraPlan.one);
        expect(app.saved, ordinarySaved);
        expect(app.activeJourneys, ordinaryActive);
        expect(app.potentialJourneys, ordinaryPotential);
        expect(ZyraAccountState.generation, generation);
        expect(ZyraAccountState.userId, userId);
        expect(ZyraColors.devPalette, palette);
        expect(ZyraAppGoldStyle.instance.enabled, gold);
        expect(ZyraText.appFont, font);
        expect(ZyraInteractionStyle.hapticLevel, haptic);
        expect(memberChanges, 0);
        expect(() => Supabase.instance, throwsA(isA<AssertionError>()));
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  // QUESTIONS Q29: each selected place opens its own reader at Larger Text.
  testWidgets(
    'one two and three monthly places at 200% keep every Journey action reachable',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester, scale: 2, size: const Size(320, 568));
        for (final count in [1, 2, 3]) {
          await _scenario(tester, count);
          _expectJourneys(tester, count);
          for (final person in _journeyPeople.take(count)) {
            await _openJourney(tester, person.id);
            expect(_key('concept_journey_${person.id}'), findsOneWidget);
            await _nav(tester, 1);
            _expectJourneys(tester, count);
          }
        }
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  // QUESTIONS Q29: independent person progress survives visits to other places.
  testWidgets('monthly Journey progress remains separate for each person', (
    tester,
  ) async {
    await _mount(tester);
    await _scenario(tester, 3);
    final owner = zyraShellFixtureFor(tester);
    final before = owner.latest!.model;
    await _openJourney(tester, 'draft-sara');
    await _press(tester, 'concept_journey_arrival_continue');
    await _press(tester, 'draft_salam_draft-sara');
    await _nav(tester, 1);
    final sara = owner.latest!.model;
    expect(sara.progress['draft-sara'], isNot(before.progress['draft-sara']));
    expect(sara.progress['draft-aisha'], before.progress['draft-aisha']);
    expect(sara.progress['draft-maryam'], before.progress['draft-maryam']);
    await _openJourney(tester, 'draft-aisha');
    await _press(tester, 'concept_journey_arrival_continue');
    await _pressLocalJourneyControl(tester, 'draft_peer_salam_draft-aisha');
    await _nav(tester, 1);
    final aisha = owner.latest!.model;
    expect(aisha.progress['draft-aisha'], isNot(sara.progress['draft-aisha']));
    expect(aisha.progress['draft-sara'], sara.progress['draft-sara']);
    expect(aisha.progress['draft-maryam'], sara.progress['draft-maryam']);
    await _openJourney(tester, 'draft-sara');
    await _press(tester, 'concept_journey_arrival_continue');
    expect(_key('draft_salam_draft-sara'), findsNothing);
    expect(
      find.text("We'll let you know when Sara returns it."),
      findsOneWidget,
    );
  });

  // QUESTIONS Q29: use the LOCK 19 access side for the three real attempts.
  testWidgets(
    'Guardian permissions stay separate across three actual attempts',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _scenario(tester, 3);
        final fixture = zyraShellFixtureFor(tester);
        const yusuf = 'draft-guardian-yusuf';
        expect(
          fixture.changeModel(() {
            for (final person in _journeyPeople) {
              expect(
                fixture.model.setSampleGuardianJourneyAccess(
                  yusuf,
                  person.id,
                  chatEnabled: true,
                ),
                isTrue,
              );
            }
          }),
          isTrue,
        );
        await tester.pumpAndSettle();
        await _nav(tester, 3);
        final manager = find.byType(ZyraOneJourneyGuardianCards);
        final main = tester.widget<ZyraOneJourneyGuardianCards>(manager);
        const hassan = 'draft-guardian-hassan';
        final grants = main.journeysFor(hassan);
        expect(
          grants.map((item) => item.id),
          unorderedEquals(_journeyPeople.map((p) => p.id)),
        );
        expect(grants.map((item) => item.attempt).toSet(), hasLength(3));
        expect(grants.every((item) => item.view && !item.canChange), isTrue);
        await _press(tester, 'guardian-card-dot-target-1');
        String view(String id) => 'guardian-card-view-$yusuf-$id';
        String chat(String id) => 'guardian-card-chat-$yusuf-$id';
        SemanticsProperties state(String key) =>
            tester.widget<Semantics>(_key(key)).properties;
        for (final person in _journeyPeople) {
          expect(state(view(person.id)).toggled, isTrue);
          expect(state(chat(person.id)).toggled, isTrue);
        }
        await _press(tester, view('draft-sara'));
        expect(state(view('draft-sara')).toggled, isFalse);
        expect(state(chat('draft-sara')).toggled, isFalse);
        expect(state(chat('draft-sara')).onTap, isNull);
        for (final id in ['draft-aisha', 'draft-maryam']) {
          expect(state(view(id)).toggled, isTrue);
          expect(state(chat(id)).toggled, isTrue);
        }
        final staleSara = state(view('draft-sara')).onTap!;
        await _press(tester, chat('draft-aisha'));
        final owner = zyraShellFixtureFor(tester);
        final before = owner.latest!.model.guardianAccess;
        staleSara();
        tester
            .widget<ZyraOneJourneyGuardianCards>(manager)
            .onPermission(yusuf, 'not-a-current-attempt', view: true);
        await tester.pumpAndSettle();
        expect(owner.latest!.model.guardianAccess, before);
        expect(state(view('draft-sara')).toggled, isFalse);
        expect(state(chat('draft-aisha')).toggled, isFalse);
        expect(state(chat('draft-maryam')).toggled, isTrue);
      }, network);
      expect(network.attempts, 0);
    },
  );

  // QUESTIONS Q29: old simultaneous delegates now expire on each place change.
  testWidgets(
    'changing places expires Continue, Options and report for the old person',
    (tester) async {
      await _mount(tester);
      await _scenario(tester, 3);
      final owner = zyraShellFixtureFor(tester);
      final sara = _places(tester);
      await _press(tester, 'draft_journey_options_draft-sara');
      final oldOptions = tester.widget<ZyraConceptJourneyOptions>(
        find.byType(ZyraConceptJourneyOptions),
      );
      await returnZyraPreviewPage(tester);
      await _press(tester, 'journey_tab_next');
      final before = owner.latest!.model;
      sara.onContinue();
      sara.onOptions();
      oldOptions.onSelected(ZyraConceptJourneyOption.report);
      await tester.pumpAndSettle();
      expect(owner.latest!.pages, isEmpty);
      expect(owner.latest!.model.states, before.states);
      expect(owner.latest!.model.progress, before.progress);
      expect(_places(tester).journeys[_places(tester).index].id, 'draft-aisha');
      await _press(tester, 'draft_journey_options_draft-aisha');
      expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
      oldOptions.onSelected(ZyraConceptJourneyOption.report);
      await tester.pumpAndSettle();
      expect(owner.latest!.pages, ['journey_options']);
      await _press(tester, 'draft_options_report_draft-aisha');
      expect(owner.latest!.personId, 'draft-aisha');
      expect(find.text('Report profile'), findsOneWidget);
      expect(owner.latest!.model.states, before.states);
      expect(owner.latest!.model.progress, before.progress);
    },
  );

  // QUESTIONS Q29: the fixed current reader keeps real progress through tab changes.
  testWidgets('selected place has no layout chooser and keeps local progress', (
    tester,
  ) async {
    await _mount(tester);
    await _scenario(tester, 3);
    await _openJourney(tester, 'draft-sara');
    await _press(tester, 'concept_journey_arrival_continue');
    await _press(tester, 'draft_salam_draft-sara');
    await _nav(tester, 1);
    final owner = zyraShellFixtureFor(tester);
    final before = owner.latest!.model.progress;
    await _openControls(tester);
    _expectCardChooserAbsent();
    _expectNoBrowseChooser();
    for (final count in [1, 2, 3]) {
      expect(_key('concept_journey_preview_$count'), findsNothing);
      expect(_action(tester, 'concept_journey_preview_$count'), isNotNull);
    }
    await closeZyraDevControls(tester);
    for (final tab in [2, 0, 4, 1]) {
      await _nav(tester, tab);
    }
    _expectJourneys(tester, 3);
    expect(owner.latest!.model.progress, before);
    await _openJourney(tester, 'draft-sara');
    await _press(tester, 'concept_journey_arrival_continue');
    expect(_key('draft_salam_draft-sara'), findsNothing);
  });

  // QUESTIONS Q29: current portraits keep their own actions at Larger Text.
  testWidgets('locked portraits and actions remain reachable at 200 percent', (
    tester,
  ) async {
    final network = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      await _mount(tester, scale: 2, size: const Size(320, 568));
      for (final count in [1, 2, 3]) {
        await _scenario(tester, count);
        _expectJourneys(tester, count);
        for (final person in _journeyPeople.take(count)) {
          await _openJourney(tester, person.id);
          expect(_key('concept_journey_${person.id}'), findsOneWidget);
          expect(
            tester
                .widget<ZyraConceptJourneyPresentation>(
                  find.byType(ZyraConceptJourneyPresentation),
                )
                .firstName,
            person.name,
          );
          await _nav(tester, 1);
          _expectJourneys(tester, count);
        }
        expect(tester.takeException(), isNull);
      }
    }, network);
    expect(network.attempts, 0);
  });

  // QUESTIONS Q29: read model-authorized stages and preserve ordinary state.
  testWidgets('selected places preserve actual stages and member data', (
    tester,
  ) async {
    final network = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      SharedPreferences.setMockInitialValues({'ordinary-setting': 'preserved'});
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      Map<String, Object?> snapshot() => {
        for (final key in prefs!.getKeys()) key: prefs.get(key),
      };
      final previousPreferences = snapshot();
      final app = AppState.instance;
      app
        ..name = 'Unchanged member'
        ..surnameLine = 'Unchanged surname'
        ..photos = ['unchanged-photo']
        ..plan = ZyraPlan.one;
      final saved = List.of(app.saved);
      final active = List.of(app.activeJourneys);
      final potential = List.of(app.potentialJourneys);
      final generation = ZyraAccountState.generation;
      final userId = ZyraAccountState.userId;
      final palette = ZyraColors.devPalette;
      final gold = ZyraAppGoldStyle.instance.enabled;
      final font = ZyraText.appFont;
      final haptics = ZyraInteractionStyle.hapticLevel;
      var changes = 0;
      void changed() => changes++;
      app.addListener(changed);
      addTearDown(() => app.removeListener(changed));
      await _mount(tester);
      await _scenario(tester, 1);
      await _openJourney(tester, 'draft-sara');
      await _press(tester, 'concept_journey_arrival_continue');
      await _press(tester, 'draft_salam_draft-sara');
      for (final control in [
        'draft_peer_salam_draft-sara',
        'draft_stage_ready_draft-sara',
        'draft_stage_peer_ready_draft-sara',
        'draft_stage_next_draft-sara',
      ]) {
        await _pressLocalJourneyControl(tester, control);
      }
      expect(
        tester
            .widget<ZyraConceptJourneyPresentation>(
              find.byType(ZyraConceptJourneyPresentation),
            )
            .stage
            .order,
        2,
      );
      expect(_key('draft_pause_draft-sara'), findsNothing);
      expect(_key('draft_agree_pause_draft-sara'), findsNothing);
      await _nav(tester, 2);
      await _press(tester, 'concept-my-requests');
      await _press(tester, 'concept_request_draft-amira_header');
      await _press(tester, 'draft_accept_draft-amira');
      await _nav(tester, 1);
      for (final tab in [2, 0, 4]) {
        await _openControls(tester);
        _expectCardChooserAbsent();
        _expectNoBrowseChooser();
        await _nav(tester, tab);
        await _nav(tester, 1);
        final places = _places(tester);
        expect(places.journeys.map((card) => card.id), [
          'draft-amira',
          'draft-sara',
        ]);
        expect(places.journeys.first.stageNumber, 0);
        expect(places.journeys.last.stageNumber, 2);
        expect(places.journeys.last.stageLabel, 'Compatibility Reveal');
        final model = ViewRequestDraftModel.fromSnapshot(
          zyraShellFixtureFor(tester).latest!.model,
        );
        expect(model.stateFor('draft-amira'), DraftJourneyState.preparing);
        expect(model.stateFor('draft-sara'), DraftJourneyState.active);
      }
      await _openJourney(tester, 'draft-sara');
      expect(
        tester
            .widget<ZyraConceptJourneyPresentation>(
              find.byType(ZyraConceptJourneyPresentation),
            )
            .stage
            .order,
        2,
      );
      final pages = _key('concept_current_journey_pages');
      await tester.drag(pages, Offset(0, -tester.getSize(pages).height * .8));
      await tester.pumpAndSettle();
      expect(find.text('Pause requested.'), findsNothing);
      expect(_key('draft_agree_pause_draft-sara'), findsNothing);
      expect(_key('draft_pause_draft-sara'), findsNothing);
      expect(_key('draft_resume_draft-sara'), findsNothing);
      await _nav(tester, 1);
      await _openJourney(tester, 'draft-amira');
      // Preparation retains its actual two-person readiness page. The
      // initialized first stage was checked on the retained metadata above;
      // no active Journey presenter or private chapter opens prematurely.
      expect(find.byType(ZyraConceptJourneyPresentation), findsNothing);
      expect(find.text('Journey with Amira'), findsOneWidget);
      expect(find.text('Choose to begin, together.'), findsOneWidget);
      expect(_key('draft_ready_draft-amira'), findsOneWidget);
      expect(snapshot(), previousPreferences);
      expect(app.name, 'Unchanged member');
      expect(app.surnameLine, 'Unchanged surname');
      expect(app.photos, ['unchanged-photo']);
      expect(app.plan, ZyraPlan.one);
      expect(app.saved, saved);
      expect(app.activeJourneys, active);
      expect(app.potentialJourneys, potential);
      expect(ZyraAccountState.generation, generation);
      expect(ZyraAccountState.userId, userId);
      expect(ZyraColors.devPalette, palette);
      expect(ZyraAppGoldStyle.instance.enabled, gold);
      expect(ZyraText.appFont, font);
      expect(ZyraInteractionStyle.hapticLevel, haptics);
      expect(changes, 0);
      expect(() => Supabase.instance, throwsA(isA<AssertionError>()));
      expect(tester.takeException(), isNull);
    }, network);
    expect(network.attempts, 0);
  });

  // QUESTIONS Q29: selected-place and Options callbacks refuse stale owners.
  for (final change in ['revocation', 'ABA', 'account generation']) {
    testWidgets(
      'locked card and remaining controls refuse stale owner after $change',
      (tester) async {
        await _mount(tester);
        await _scenario(tester, 3);
        final place = _places(tester);
        final staleJourney = place.onContinue;
        final staleOptions = place.onOptions;
        await _press(tester, 'draft_journey_options_draft-sara');
        final options = tester.widget<ZyraConceptJourneyOptions>(
          find.byType(ZyraConceptJourneyOptions),
        );
        expect(options.id, 'draft-sara');
        expect(options.lockedPage, isTrue);
        void staleReport() =>
            options.onSelected(ZyraConceptJourneyOption.report);
        await _openControls(tester);
        _expectCardChooserAbsent();
        _expectNoBrowseChooser();
        final staleReset = _action(tester, 'draft_reset')!;
        final staleCount = _action(tester, 'concept_journey_preview_2')!;
        if (change == 'account generation') {
          ZyraAccountState.resetForTesting();
          AppState.instance.resetForAccountChange();
        } else {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          if (change == 'ABA') {
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
        }
        staleReset();
        staleCount();
        staleJourney();
        staleOptions();
        staleReport();
        await tester.pumpAndSettle();
        expect(find.text('Preview closed'), findsOneWidget);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        expect(find.byType(ZyraOneJourneyCardContent), findsNothing);
        expect(find.text('Safety, always.'), findsNothing);
        expect(_key('concept_journey_draft-sara'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
