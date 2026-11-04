import 'dart:async';
import 'dart:io';

import 'dart:ui' as ui;

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
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
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
const _cardContentCapture = bool.fromEnvironment(
  'ZYRA_JOURNEY_CARD_CONTENT_CAPTURE',
);
const _themeReviewCapture = bool.fromEnvironment('ZYRA_THEME_REVIEW_CAPTURE');
const _cardLockinCapture = bool.fromEnvironment('ZYRA_CARD_LOCKIN_CAPTURE');
const _simplifiedCapture = bool.fromEnvironment(
  'ZYRA_MY_ZYRA_SIMPLIFIED_CAPTURE',
);
const _capture =
    bool.fromEnvironment('ZYRA_MONTHLY_JOURNEY_CAPTURE') ||
    _cardContentCapture ||
    _themeReviewCapture ||
    _cardLockinCapture ||
    _simplifiedCapture;
const _boundary = ValueKey('monthly-journey-capacity-candidate');
const _candidateDirectory =
    'visual/candidates/non_swipe_monthly_journeys_full_canvas_2026_10_09_v1';
const _cardContentCandidateDirectory =
    'visual/candidates/non_swipe_journey_card_content_2026_10_09_v1';
const _themeReviewCandidateDirectory =
    'visual/candidates/non_swipe_theme_review_2026_10_09';
const _cardLockinCandidateDirectory =
    'visual/candidates/journey_card_locked_2026_10_09';
const _simplifiedCandidateDirectory =
    'visual/candidates/my_zyra_simplified_2026_10_09/monthly';

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
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  if (target.evaluate().isEmpty && id.startsWith('my-zyra-route-')) {
    final scrollable = find
        .descendant(
          of: _key('my-zyra-quiet-scroll-0'),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(target, 220, scrollable: scrollable);
    await tester.pumpAndSettle();
  }
  if (target.evaluate().isEmpty && id.startsWith('draft_journey_')) {
    final list = find.byKey(const PageStorageKey('concept_connections_page_0'));
    final scrollable = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    // Current ListView preserves the genuine prior reading position. Start a
    // new lazy-target search at the top through actual gestures, not a model
    // change or direct ScrollPosition injection.
    for (var attempt = 0; attempt < 20; attempt++) {
      final state = tester.state<ScrollableState>(scrollable);
      if (state.position.pixels <= state.position.minScrollExtent) break;
      await tester.drag(list, const Offset(0, 250));
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(target, 200, scrollable: scrollable);
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget, reason: 'Required actual action $id');
  if (id.startsWith('draft_journey_')) {
    final card = find.ancestor(
      of: target,
      matching: find.byType(ZyraOneJourneyConnectionsActiveCard),
    );
    expect(card, findsOneWidget);
    final bounds = tester.getRect(card);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(tester.view.physicalSize.width));
  }
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
              ZyraNavBarMetrics.restingHeight -
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
}

List<ZyraOneJourneyConnectionsActiveCard> _currentCards(WidgetTester tester) =>
    tester
        .widget<ZyraOneJourneyConnectionsPresentation>(
          find.byType(ZyraOneJourneyConnectionsPresentation),
        )
        .pages
        .single
        .whereType<ZyraOneJourneyConnectionsActiveCard>()
        .toList();

void _expectCardChooserAbsent() {
  expect(find.text('Journey cards'), findsNothing);
  expect(_key('concept_journey_card_layout'), findsNothing);
  expect(find.text('Journey card content'), findsNothing);
  expect(_key('concept_try_journey_card_design'), findsNothing);
  for (final design in ZyraOneJourneyCardDesign.values) {
    expect(_key('concept_journey_card_design_${design.name}'), findsNothing);
  }
}

void _expectLockedCards(WidgetTester tester) {
  for (final card in _currentCards(tester)) {
    expect(card.cardDesign, ZyraOneJourneyCardDesign.portraitSplit);
    expect(card.onReport, isNull);
    final owner = find.byWidget(card);
    expect(owner, findsOneWidget);
    expect(
      find.descendant(of: owner, matching: find.byIcon(Icons.flag_outlined)),
      findsNothing,
      reason: 'Report is available in Journey options, not the card header',
    );
    expect(card.stateLabel, isNotNull);
    expect(card.stageLabel, isNotNull);
    expect(
      find.descendant(of: owner, matching: find.text(card.stateLabel!)),
      findsNothing,
    );
    expect(
      find.descendant(of: owner, matching: find.text(card.stageLabel!)),
      findsNothing,
    );
    expect(
      find.descendant(of: owner, matching: find.text('Active Journey')),
      findsNothing,
    );
    expect(
      find.descendant(of: owner, matching: find.text('Salam Exchange')),
      findsNothing,
    );
    final content = find.descendant(
      of: owner,
      matching: find.byType(ZyraOneJourneyCardContent),
    );
    expect(content, findsOneWidget);
    final interior = tester.widget<ZyraOneJourneyCardContent>(content);
    expect(interior.design, ZyraOneJourneyCardDesign.portraitSplit);
    expect(interior.profile.id, card.profile.id);
    expect(interior.stateLabel, card.stateLabel);
    expect(interior.stageLabel, card.stageLabel);
    final portrait = find.descendant(of: owner, matching: find.byType(Image));
    expect(portrait, findsOneWidget);
    final photoBounds = tester.getRect(portrait);
    if (MediaQuery.textScalerOf(tester.element(owner)).scale(1) > 1.3) {
      expect(photoBounds.size, const Size(104, 104));
    } else {
      expect(photoBounds.width * photoBounds.height, greaterThan(104 * 104));
    }
    final cardBounds = tester.getRect(owner);
    expect(photoBounds.left, greaterThanOrEqualTo(cardBounds.left));
    expect(photoBounds.right, lessThanOrEqualTo(cardBounds.right));
    expect(photoBounds.top, greaterThanOrEqualTo(cardBounds.top));
    expect(photoBounds.bottom, lessThanOrEqualTo(cardBounds.bottom));
    final deck = card.actions as ZyraOneJourneyConnectionsActionDeck;
    expect(deck.primary.icon, isNull);
    expect(deck.primary.label, 'Continue Journey');
    expect(deck.journeyReference, isNull);
    final primary = _key('draft_journey_${card.profile.id}');
    expect(
      find.descendant(of: primary, matching: find.text(deck.primary.label)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: primary, matching: find.byType(Icon)),
      findsNothing,
    );
  }
}

Future<void> _pressNamedReport(WidgetTester tester, String name) async {
  final card = _currentCards(
    tester,
  ).singleWhere((candidate) => candidate.profile.firstName == name);
  expect(card.onReport, isNull);
  await _press(tester, 'draft_journey_options_${card.profile.id}');
  final options = tester.widget<ZyraConceptJourneyOptions>(
    find.byType(ZyraConceptJourneyOptions),
  );
  expect(options.id, card.profile.id);
  expect(options.firstName, name);
  expect(options.inline, isTrue);
  expect(find.byType(BottomSheet), findsNothing);
  await _press(tester, 'draft_options_report_${card.profile.id}');
  expect(find.text('Report profile'), findsOneWidget);
  expect(tester.takeException(), isNull);
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
  final presentation = tester.widget<ZyraOneJourneyConnectionsPresentation>(
    find.byType(ZyraOneJourneyConnectionsPresentation),
  );
  final content = presentation.pages.single;
  expect(presentation.title, 'Journey');
  if (count == 0) {
    expect(find.text('Awaiting a Journey'), findsNWidgets(3));
    expect(
      find.text(
        'When a request is accepted, you both choose to begin together. This is where your Journey continues.',
      ),
      findsNothing,
    );
    for (var index = 0; index < 3; index++) {
      final slot = _key('concept_journey_capacity_slot_$index');
      expect(slot, findsOneWidget);
      final copy = tester.widget<Text>(
        find.descendant(of: slot, matching: find.byType(Text)),
      );
      expect(copy.data, 'Awaiting a Journey');
      expect(copy.style?.fontSize, 14);
      expect(copy.style?.color, ZyraColors.ink(.65));
      expect(copy.overflow, isNot(TextOverflow.ellipsis));
    }
    expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsNothing);
  }
  expect(find.text('Journey'), findsOneWidget);
  expect(_key('concept_journey_capacity_summary'), findsNothing);
  expect(find.text('Your Journey'), findsNothing);
  expect(find.text('Your Journeys'), findsNothing);
  expect(content.whereType<ZyraOneJourneyConnectionsSectionHeading>(), isEmpty);
  // Enlarged text may require scrolling. Check the full supplied card set
  // here; separate actual tap tests reveal and hit every person's own action.
  // Capacity remains model authority, covered by model tests and the disabled
  // Basic controls/Browse gates below, not by a removed visible status label.
  final cards = content
      .whereType<ZyraOneJourneyConnectionsActiveCard>()
      .toList();
  expect(cards.map((card) => card.profile.id), [
    for (final person in _journeyPeople.take(count)) person.id,
  ]);
  for (final person in _journeyPeople.take(count)) {
    final card = cards.singleWhere((card) => card.profile.id == person.id);
    expect(
      (card.actions as ZyraOneJourneyConnectionsActionDeck).primary.key,
      ValueKey('draft_journey_${person.id}'),
    );
    expect(card.profile.photos, isNotEmpty);
    expect(
      card.profile.photos,
      everyElement(startsWith('data:image/jpeg;base64,')),
    );
  }
  expect(_key('concept_activity_requests'), findsNothing);
  expect(_key('concept_activity_saved'), findsNothing);
  expect(_key('concept_activity_paused'), findsNothing);
  expect(_key('concept_activity_ended'), findsNothing);
}

double _journeyBodyBottom(WidgetTester tester, Finder list) {
  // LOCK6 changes only the painted bar: card layout keeps the existing
  // expanded-bar reservation, independent of the current idle/full state.
  return tester.getRect(list).bottom -
      MediaQuery.paddingOf(
        tester.element(list),
      ).bottom.clamp(ZyraNavBarMetrics.bottomInset, double.infinity) -
      ZyraNavBarMetrics.height -
      12;
}

void _expectInitialJourneyFit(WidgetTester tester, int count) {
  final list = find.byKey(const PageStorageKey('concept_connections_page_0'));
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(
    position.pixels,
    position.minScrollExtent,
    reason: 'Journey fit must be measured at its initial reading position',
  );
  expect(
    position.maxScrollExtent,
    closeTo(0, .01),
    reason: 'Normal phone text must not require scrolling to see every Journey',
  );
  final navigation = find.byType(FloatingNavBar);
  expect(navigation, findsOneWidget);
  // Compare overlap with the actual surface, while retaining the unchanged
  // expanded-bar body reservation for the strict slot geometry below.
  final navigationTop = tester.getRect(navigation).top;
  final viewport = tester.getRect(list);
  final slotBounds = <Rect>[];
  if (_capture) {
    expect(ZyraText.testReadingFontFamily, 'PoppinsMonthlyJourneyAudit');
    debugPrint(
      'MONTHLY_JOURNEY_FIT ${tester.view.physicalSize} count=$count '
      'font=${ZyraText.testReadingFontFamily} '
      'navigationTop=$navigationTop maxScrollExtent=${position.maxScrollExtent}',
    );
  }
  for (final person in _journeyPeople.take(count)) {
    final card = find.byWidgetPredicate(
      (widget) =>
          widget is ZyraOneJourneyConnectionsActiveCard &&
          widget.profile.id == person.id,
    );
    final action = _key('draft_journey_${person.id}');
    expect(
      card,
      findsOneWidget,
      reason: '${person.name} must be built initially',
    );
    expect(action, findsOneWidget);
    final cardRect = tester.getRect(card);
    slotBounds.add(cardRect);
    if (_capture) {
      debugPrint(
        'MONTHLY_JOURNEY_FIT ${person.id} '
        'cardTop=${cardRect.top} cardHeight=${cardRect.height} '
        'cardBottom=${tester.getRect(card).bottom} '
        'actionBottom=${tester.getRect(action).bottom}',
      );
    }
    for (final target in [card, action]) {
      final bounds = tester.getRect(target);
      expect(bounds.left, greaterThanOrEqualTo(viewport.left));
      expect(bounds.right, lessThanOrEqualTo(viewport.right));
      expect(bounds.top, greaterThanOrEqualTo(viewport.top));
      expect(
        bounds.bottom,
        lessThanOrEqualTo(navigationTop),
        reason: '${person.name} must be fully above the floating navigation',
      );
    }
    expect(
      action.hitTestable(),
      findsOneWidget,
      reason: '${person.name} must be tappable without revealing or scrolling',
    );
  }
  for (var index = count; index < 3; index++) {
    final slot = _key('concept_journey_capacity_slot_$index');
    expect(slot, findsOneWidget);
    final bounds = tester.getRect(slot);
    slotBounds.add(bounds);
    expect(bounds.left, greaterThanOrEqualTo(viewport.left));
    expect(bounds.right, lessThanOrEqualTo(viewport.right));
    expect(bounds.top, greaterThanOrEqualTo(viewport.top));
    expect(
      bounds.bottom,
      lessThanOrEqualTo(navigationTop),
      reason: 'Unused place $index must stay fully above floating navigation',
    );
  }
  expect(slotBounds, hasLength(3));
  expect(
    slotBounds.first.top,
    closeTo(viewport.top + 12, 1),
    reason: 'Slots begin with one balanced inset below the Journey title',
  );
  for (var index = 1; index < slotBounds.length; index++) {
    expect(
      slotBounds[index].top - slotBounds[index - 1].bottom,
      closeTo(12, 1),
      reason: 'Every occupied or unused Journey place uses the same slot gap',
    );
    expect(
      slotBounds[index].height,
      closeTo(slotBounds.first.height, 1),
      reason: 'All three occupied or unused slots share equal bounded height',
    );
  }
  expect(
    slotBounds.last.bottom,
    closeTo(_journeyBodyBottom(tester, list), 1),
    reason: 'All three slots fill the canvas above the expanded navigation',
  );
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

Future<void> _settlePaintedImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  await tester.runAsync(() async {
    for (final widget in images) {
      expect(widget.image, isA<MemoryImage>());
      final context = tester.element(find.byWidget(widget));
      final stream = widget.image.resolve(
        createLocalImageConfiguration(context),
      );
      final painted = Completer<void>();
      final listener = ImageStreamListener(
        (info, _) {
          info.dispose();
          if (!painted.isCompleted) painted.complete();
        },
        onError: (error, stack) {
          if (!painted.isCompleted) painted.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await painted.future.timeout(const Duration(seconds: 10));
      } finally {
        stream.removeListener(listener);
      }
    }
  });
  await tester.pumpAndSettle();
  for (final widget in images) {
    final raw = find.descendant(
      of: find.byWidget(widget),
      matching: find.byType(RawImage),
    );
    expect(raw, findsOneWidget);
    expect(tester.widget<RawImage>(raw).image, isNotNull);
  }
}

Future<void> _captureCandidate(
  WidgetTester tester,
  String filename, {
  bool cardContent = false,
}) async {
  if (!_capture ||
      (_cardContentCapture &&
          !_themeReviewCapture &&
          !_cardLockinCapture &&
          !_simplifiedCapture &&
          !cardContent)) {
    return;
  }
  expect(autoUpdateGoldenFiles, isTrue);
  await tester.pump(const Duration(seconds: 3));
  // Capture-only initial-reading position. Action coverage never relies on
  // these resets: _press independently proves genuine hit-tested scrolling.
  for (final state in tester.stateList<ScrollableState>(
    find.descendant(
      of: find.byKey(_boundary),
      matching: find.byType(Scrollable),
    ),
  )) {
    if (axisDirectionToAxis(state.widget.axisDirection) == Axis.vertical &&
        state.position.hasContentDimensions) {
      state.position.jumpTo(state.position.minScrollExtent);
    }
  }
  await tester.pumpAndSettle();
  await _settlePaintedImages(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        bytes!.buffer.asUint8List(),
        matchesGoldenFile(
          '${_simplifiedCapture
              ? _simplifiedCandidateDirectory
              : _cardLockinCapture
              ? _cardLockinCandidateDirectory
              : _themeReviewCapture
              ? _themeReviewCandidateDirectory
              : cardContent
              ? _cardContentCandidateDirectory
              : _candidateDirectory}/$filename.png',
        ),
      );
    } finally {
      image.dispose();
    }
  });
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

  testWidgets('monthly starts with three places and no fabricated Journey', (
    tester,
  ) async {
    await _mount(tester);
    await _nav(tester, 1);
    _expectJourneys(tester, 0);
    expect(_key('concept_journey_capacity_summary'), findsNothing);
    await _openControls(tester);
    for (final count in [1, 2, 3]) {
      expect(_key('concept_journey_preview_$count'), findsOneWidget);
      expect(_action(tester, 'concept_journey_preview_$count'), isNotNull);
    }
  });

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0),
    (size: Size(320, 568), scale: 1.4),
    (size: Size(320, 568), scale: 2.0),
  ]) {
    testWidgets(
      'empty Journey keeps three readable capacity slots at ${viewport.scale}x',
      (tester) async {
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester, size: viewport.size, scale: viewport.scale);
          await _nav(tester, 1);
          _expectJourneys(tester, 0);
          final list = find.byKey(
            const PageStorageKey('concept_connections_page_0'),
          );
          final viewportRect = tester.getRect(list);
          final position = tester
              .state<ScrollableState>(
                find.descendant(of: list, matching: find.byType(Scrollable)),
              )
              .position;
          expect(position.pixels, position.minScrollExtent);
          expect(
            position.maxScrollExtent,
            viewport.scale == 1 ? closeTo(0, .01) : greaterThan(0),
          );
          final navigationTop = tester.getRect(find.byType(FloatingNavBar)).top;
          for (var index = 0; index < 3; index++) {
            final slot = _key('concept_journey_capacity_slot_$index');
            await tester.ensureVisible(slot);
            await tester.pumpAndSettle();
            final copy = find.descendant(of: slot, matching: find.byType(Text));
            final copyRect = tester.getRect(copy);
            final boundsReason =
                'Slot $index copy $copyRect must remain readable in $viewportRect';
            expect(
              copyRect.left,
              greaterThanOrEqualTo(viewportRect.left - .01),
              reason: boundsReason,
            );
            expect(
              copyRect.top,
              greaterThanOrEqualTo(viewportRect.top - .01),
              reason: boundsReason,
            );
            expect(
              copyRect.right,
              lessThanOrEqualTo(viewportRect.right + .01),
              reason: boundsReason,
            );
            expect(
              copyRect.bottom,
              lessThanOrEqualTo(navigationTop + .01),
              reason: boundsReason,
            );
            expect(copy.hitTestable(), findsOneWidget);
            expect(
              tester.renderObject<RenderParagraph>(copy).didExceedMaxLines,
              isFalse,
            );
            expect(
              find.descendant(of: slot, matching: find.byType(FittedBox)),
              findsNothing,
            );
          }
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );
  }

  testWidgets('other empty states retain their paragraph styling and gap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraEmptyState(
            icon: Icons.search,
            title: 'Another empty page',
            message: 'Its existing explanation remains.',
          ),
        ),
      ),
    );
    final title = find.text('Another empty page');
    final message = find.text('Its existing explanation remains.');
    expect(tester.widget<Text>(title).style?.fontSize, 15);
    expect(tester.widget<Text>(message).style?.fontSize, 13.5);
    expect(
      tester.getTopLeft(message).dy - tester.getBottomLeft(title).dy,
      closeTo(6, .01),
    );
    expect(tester.takeException(), isNull);
  });

  for (final count in [1, 2, 3]) {
    testWidgets('$count monthly preview Journeys each open their own person', (
      tester,
    ) async {
      await _mount(tester);
      await _scenario(tester, count);
      _expectJourneys(tester, count);
      for (final person in _journeyPeople.take(count)) {
        await _press(tester, 'draft_journey_${person.id}');
        final journey = tester.widget<ZyraConceptJourneyPresentation>(
          find.byType(ZyraConceptJourneyPresentation),
        );
        expect(journey.firstName, person.name);
        expect(journey.stage.order, 1, reason: 'Separate fresh Salam progress');
        expect(_key('concept_journey_${person.id}'), findsOneWidget);
        expect(find.text('Journey with ${person.name}'), findsOneWidget);
        await _nav(tester, 1);
        _expectJourneys(tester, count);
      }
    });
  }

  for (final layout in [
    (name: 'iphone430', size: const Size(430, 932), topInset: 59.0),
    (name: 'iphone393', size: const Size(393, 852), topInset: 59.0),
    (name: 'phone390', size: const Size(390, 844), topInset: 44.0),
  ]) {
    for (final count in [1, 2, 3]) {
      testWidgets(
        '$count monthly Journeys fill available canvas on ${layout.name}',
        (tester) async {
          final network = _NoNetwork();
          await HttpOverrides.runWithHttpOverrides(() async {
            await _mount(tester, size: layout.size, topInset: layout.topInset);
            await _scenario(tester, count);
            _expectInitialJourneyFit(tester, count);
            _expectJourneys(tester, count);
            if (layout.name != 'phone390') {
              await _captureCandidate(
                tester,
                'journeys_${count}_${layout.name}_initial',
              );
              _expectInitialJourneyFit(tester, count);
            }
            for (final person in _journeyPeople.take(count)) {
              // Deliberately no _press, ensureVisible, scrollUntilVisible,
              // controller injection or delegate invocation on this route.
              await tester.tap(_key('draft_journey_${person.id}'));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              final journey = tester.widget<ZyraConceptJourneyPresentation>(
                find.byType(ZyraConceptJourneyPresentation),
              );
              expect(journey.firstName, person.name);
              expect(journey.stage.order, 1);
              expect(_key('concept_journey_${person.id}'), findsOneWidget);
              await _nav(tester, 1);
              _expectJourneys(tester, count);
              _expectInitialJourneyFit(tester, count);
            }
          }, network);
          expect(network.attempts, 0);
        },
      );
    }
  }

  testWidgets(
    'monthly Browse remains available even while all three places are used',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        for (final count in [1, 2, 3]) {
          await _scenario(tester, count);
          _expectJourneys(tester, count);
          await _captureCandidate(tester, 'journeys_${count}_standard');
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
          expect(_key('concept_next_profile'), findsOneWidget);
          expect(find.text('Your Journey places are full.'), findsNothing);
          await _nav(tester, 1);
          _expectJourneys(tester, count);
        }
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'Basic refuses reduction below occupied places and keeps one place',
    (tester) async {
      await _mount(tester);
      await _scenario(tester, 3);
      await _nav(tester, 4);
      await _openControls(tester);
      await _press(tester, 'draft_membership_seeker_basic');
      await _nav(tester, 1);
      _expectJourneys(tester, 3);
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
        await _captureCandidate(tester, 'my_zyra_portraitCard');
        await _press(tester, 'my-zyra-route-concept-my-requests');
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
        await _press(tester, 'my-zyra-route-concept-my-ended');
        expect(_key('concept_activity_ended'), findsOneWidget);
        expect(
          find.byType(ZyraOneJourneyConnectionsActiveCard),
          findsOneWidget,
        );
        expect(_key('draft_restart_draft-noor'), findsOneWidget);
        expect(_key('draft_journey_options_draft-noor'), findsOneWidget);
        expect(find.textContaining('Paused'), findsNothing);
        await _captureCandidate(tester, 'ended_history_only');
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

  testWidgets(
    'one two and three monthly cards at 200% keep every Journey action reachable',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester, scale: 2, size: const Size(320, 568));
        for (final count in [1, 2, 3]) {
          await _scenario(tester, count);
          _expectJourneys(tester, count);
          await _captureCandidate(tester, 'journeys_${count}_compact200');
          for (final person in _journeyPeople.take(count)) {
            await _press(tester, 'draft_journey_${person.id}');
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

  testWidgets('monthly Journey progress remains separate for each person', (
    tester,
  ) async {
    await _mount(tester);
    await _scenario(tester, 3);
    expect(
      _currentCards(tester).map(
        (card) =>
            (card.actions as ZyraOneJourneyConnectionsActionDeck).primary.label,
      ),
      everyElement('Continue Journey'),
    );
    await _press(tester, 'draft_journey_draft-sara');
    await _press(tester, 'concept_journey_arrival_continue');
    expect(_action(tester, 'draft_salam_draft-sara'), isNotNull);
    await _press(tester, 'draft_salam_draft-sara');
    expect(_key('draft_salam_draft-sara'), findsNothing);
    expect(
      find.text("We'll let you know when Sara returns it."),
      findsOneWidget,
    );
    await _nav(tester, 1);
    expect(
      (_currentCards(tester).first.actions
              as ZyraOneJourneyConnectionsActionDeck)
          .primary
          .label,
      'Continue Journey',
    );
    expect(
      (_currentCards(tester)[1].actions as ZyraOneJourneyConnectionsActionDeck)
          .primary
          .label,
      'Continue Journey',
    );
    await _press(tester, 'draft_journey_draft-aisha');
    await _press(tester, 'concept_journey_arrival_continue');
    expect(_action(tester, 'draft_salam_draft-aisha'), isNotNull);
    await _pressLocalJourneyControl(tester, 'draft_peer_salam_draft-aisha');
    await _nav(tester, 1);
    expect(
      (_currentCards(tester)[1].actions as ZyraOneJourneyConnectionsActionDeck)
          .primary
          .label,
      'Continue Journey',
      reason: 'The first Salam from either party changes Start to Continue',
    );
    await _press(tester, 'draft_journey_draft-sara');
    await _press(tester, 'concept_journey_arrival_continue');
    expect(_key('draft_salam_draft-sara'), findsNothing);
    expect(
      find.text("We'll let you know when Sara returns it."),
      findsOneWidget,
    );
  });

  testWidgets(
    'Guardian permissions stay separate across three actual attempts',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _scenario(tester, 3);
        await _nav(tester, 3);
        final mainPage = tester.widget<SeekerGuardianPage>(
          find.byType(SeekerGuardianPage),
        );
        final mainAccess = await mainPage.journeyAccessLoader!(
          guardianId: 'draft-guardian-hassan',
        );
        expect(mainAccess.isAvailable, isTrue);
        expect(mainAccess.valueOrNull!.map((state) => state.attemptId), [
          for (final person in _journeyPeople) 'draft-attempt-${person.id}',
        ]);
        expect(
          mainAccess.valueOrNull!.every((state) => state.included),
          isTrue,
        );
        expect(
          mainAccess.valueOrNull!.every((state) => !state.canChange),
          isTrue,
        );
        await tester.drag(_key('guardian-page-view'), const Offset(-312, 0));
        await tester.pumpAndSettle();
        expect(
          _key('guardian-page-static-draft-guardian-yusuf'),
          findsOneWidget,
        );
        String view(String id) =>
            'guardian-journey-access-toggle-draft-attempt-$id';
        String chat(String id) =>
            'guardian-journey-chat-toggle-draft-attempt-$id';
        for (final person in _journeyPeople) {
          expect(
            tester.widget<Semantics>(_key(view(person.id))).properties.toggled,
            isTrue,
          );
          expect(
            tester.widget<Semantics>(_key(chat(person.id))).properties.toggled,
            isTrue,
          );
        }
        await _press(tester, view('draft-sara'));
        expect(
          tester.widget<Semantics>(_key(view('draft-sara'))).properties.toggled,
          isFalse,
        );
        expect(
          tester.widget<Semantics>(_key(chat('draft-sara'))).properties.toggled,
          isFalse,
        );
        expect(
          tester.widget<Semantics>(_key(chat('draft-sara'))).properties.onTap,
          isNull,
        );
        for (final id in ['draft-aisha', 'draft-maryam']) {
          expect(
            tester.widget<Semantics>(_key(view(id))).properties.toggled,
            isTrue,
          );
          expect(
            tester.widget<Semantics>(_key(chat(id))).properties.toggled,
            isTrue,
          );
        }
        final staleSara = tester
            .widget<Semantics>(_key(view('draft-sara')))
            .properties
            .onTap!;
        await _press(tester, chat('draft-aisha'));
        expect(
          tester
              .widget<Semantics>(_key(chat('draft-aisha')))
              .properties
              .toggled,
          isFalse,
        );
        staleSara();
        await tester.pumpAndSettle();
        expect(
          tester.widget<Semantics>(_key(view('draft-sara'))).properties.toggled,
          isFalse,
        );
        expect(
          tester
              .widget<Semantics>(_key(chat('draft-maryam')))
              .properties
              .toggled,
          isTrue,
        );
        final currentPage = tester.widget<SeekerGuardianPage>(
          find.byType(SeekerGuardianPage),
        );
        final unknown = await currentPage.journeyAccessLoader!(
          guardianId: 'draft-guardian-yusuf',
          attemptId: 'not-a-current-attempt',
          enabled: true,
        );
        expect(unknown.isUnavailable, isTrue);
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'Portrait split is locked with no chooser and no local state reset',
    (tester) async {
      await _mount(tester);
      await _scenario(tester, 3);
      _expectLockedCards(tester);
      await _press(tester, 'draft_journey_draft-sara');
      await _press(tester, 'concept_journey_arrival_continue');
      await _press(tester, 'draft_salam_draft-sara');
      await _nav(tester, 1);
      expect(
        (_currentCards(tester).first.actions
                as ZyraOneJourneyConnectionsActionDeck)
            .primary
            .label,
        'Continue Journey',
      );
      await _openControls(tester);
      _expectCardChooserAbsent();
      _expectNoBrowseChooser();
      for (final count in [1, 2, 3]) {
        expect(_key('concept_journey_preview_$count'), findsOneWidget);
        expect(_action(tester, 'concept_journey_preview_$count'), isNotNull);
      }
      for (final tab in [2, 0, 4, 1]) {
        await _nav(tester, tab);
      }
      _expectJourneys(tester, 3);
      _expectLockedCards(tester);
      expect(
        (_currentCards(tester).first.actions
                as ZyraOneJourneyConnectionsActionDeck)
            .primary
            .label,
        'Continue Journey',
      );
      await _press(tester, 'draft_journey_draft-sara');
      await _press(tester, 'concept_journey_arrival_continue');
      expect(_key('draft_salam_draft-sara'), findsNothing);
      expect(
        find.text("We'll let you know when Sara returns it."),
        findsOneWidget,
      );
      await _nav(tester, 1);
      for (final count in [1, 2, 3]) {
        await _scenario(tester, count);
        _expectJourneys(tester, count);
        _expectLockedCards(tester);
      }
    },
  );

  testWidgets('locked single and two cards retain three-slot rectangles', (
    tester,
  ) async {
    await _mount(tester, size: const Size(393, 852), topInset: 59);
    for (final count in [1, 2]) {
      await _scenario(tester, count);
      _expectLockedCards(tester);
      _expectInitialJourneyFit(tester, count);
      final original = [
        for (final card in _currentCards(tester))
          tester.getRect(find.byWidget(card)),
      ];
      final list = find.byKey(
        const PageStorageKey('concept_connections_page_0'),
      );
      final viewport = tester.getRect(list);
      final top = viewport.top + 12;
      final bottom = _journeyBodyBottom(tester, list);
      final slotHeight = (bottom - top - 12 * 2) / 3;
      for (var index = 0; index < original.length; index++) {
        final bounds = original[index];
        expect(bounds.height, closeTo(slotHeight, .01));
        expect(bounds.top, closeTo(top + index * (slotHeight + 12), .01));
        expect(bounds.width, closeTo(viewport.width - 40, .01));
      }
      for (final tab in [2, 4, 1]) {
        await _nav(tester, tab);
      }
      expect([
        for (final card in _currentCards(tester))
          tester.getRect(find.byWidget(card)),
      ], original);
      _expectLockedCards(tester);
      _expectInitialJourneyFit(tester, count);
    }
    expect(tester.takeException(), isNull);
  });

  for (final layout in [
    (name: 'iphone393', size: const Size(393, 852), topInset: 59.0),
    (name: 'phone390', size: const Size(390, 844), topInset: 44.0),
  ]) {
    testWidgets('locked cards preserve outer geometry on ${layout.name}', (
      tester,
    ) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester, size: layout.size, topInset: layout.topInset);
        await _scenario(tester, 3);
        final original = [
          for (final card in _currentCards(tester))
            tester.getRect(find.byWidget(card)),
        ];
        _expectJourneys(tester, 3);
        _expectLockedCards(tester);
        _expectInitialJourneyFit(tester, 3);
        if (layout.name == 'iphone393') {
          await _captureCandidate(
            tester,
            'portrait_split_locked_iphone393',
            cardContent: true,
          );
        }
        for (final person in _journeyPeople) {
          await tester.tap(_key('draft_journey_${person.id}'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final journey = tester.widget<ZyraConceptJourneyPresentation>(
            find.byType(ZyraConceptJourneyPresentation),
          );
          expect(journey.firstName, person.name);
          expect(journey.stage.order, 1);
          expect(_key('concept_journey_${person.id}'), findsOneWidget);
          await _nav(tester, 1);
          _expectLockedCards(tester);
          expect(
            [
              for (final card in _currentCards(tester))
                tester.getRect(find.byWidget(card)),
            ],
            original,
            reason:
                'The locked interior must retain the established outer card shell',
          );
          _expectInitialJourneyFit(tester, 3);
          if (layout.name == 'iphone393') {
            await _pressNamedReport(tester, person.name);
            await _nav(tester, 1);
            _expectLockedCards(tester);
          }
        }
      }, network);
      expect(network.attempts, 0);
    });
  }

  testWidgets('locked portraits and actions remain reachable at 200 percent', (
    tester,
  ) async {
    final network = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      await _mount(tester, scale: 2, size: const Size(320, 568));
      for (final count in [1, 2, 3]) {
        await _scenario(tester, count);
        _expectJourneys(tester, count);
        _expectLockedCards(tester);
        for (final person in _journeyPeople.take(count)) {
          await _press(tester, 'draft_journey_${person.id}');
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
          _expectLockedCards(tester);
        }
        expect(tester.takeException(), isNull);
      }
    }, network);
    expect(network.attempts, 0);
  });

  testWidgets('locked cards preserve actual stages states and member data', (
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
      await _press(tester, 'draft_journey_draft-sara');
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
      await _press(tester, 'my-zyra-route-concept-my-requests');
      await _press(tester, 'concept_request_draft-amira_header');
      await _press(tester, 'draft_accept_draft-amira');
      await _nav(tester, 1);
      for (final tab in [2, 0, 4]) {
        await _openControls(tester);
        _expectCardChooserAbsent();
        _expectNoBrowseChooser();
        await _nav(tester, tab);
        await _nav(tester, 1);
        _expectLockedCards(tester);
        final cards = _currentCards(tester);
        expect(cards.map((card) => card.profile.id), [
          'draft-amira',
          'draft-sara',
        ]);
        expect(cards.first.stateLabel, 'Preparing together · place reserved');
        expect(
          cards.first.stageLabel,
          'Salam Exchange',
          reason:
              'Preparation retains the existing initialized first stage without displaying it on the overview',
        );
        expect(cards.last.stateLabel, 'Active Journey');
        expect(cards.last.stageLabel, 'Compatibility Reveal');
        expect(
          (cards.first.actions as ZyraOneJourneyConnectionsActionDeck)
              .primary
              .label,
          'Continue Journey',
        );
        expect(
          (cards.last.actions as ZyraOneJourneyConnectionsActionDeck)
              .primary
              .label,
          'Continue Journey',
        );
      }
      await _press(tester, 'draft_journey_draft-sara');
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
      await _press(tester, 'draft_journey_draft-amira');
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

  for (final change in ['revocation', 'ABA', 'account generation']) {
    testWidgets(
      'locked card and remaining controls refuse stale owner after $change',
      (tester) async {
        await _mount(tester);
        await _scenario(tester, 3);
        final staleJourney = _action(tester, 'draft_journey_draft-sara')!;
        expect(_currentCards(tester).first.onReport, isNull);
        await _press(tester, 'draft_journey_options_draft-sara');
        final options = tester.widget<ZyraConceptJourneyOptions>(
          find.byType(ZyraConceptJourneyOptions),
        );
        expect(options.id, 'draft-sara');
        expect(options.inline, isTrue);
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
