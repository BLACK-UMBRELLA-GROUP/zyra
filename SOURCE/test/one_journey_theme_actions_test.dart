import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_one_journey_options_page.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _people = [
  (id: 'draft-sara', name: 'Sara'),
  (id: 'draft-aisha', name: 'Aisha'),
  (id: 'draft-maryam', name: 'Maryam'),
];

Finder _key(String id) => find.byKey(ValueKey(id));

Future<void> _mount(WidgetTester tester, {bool enlarged = false}) async {
  tester.view.physicalSize = enlarged
      ? const Size(320, 568)
      : const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final top = enlarged ? 44.0 : 59.0;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(enlarged ? 2 : 1),
          padding: EdgeInsets.only(top: top, bottom: 34),
          viewPadding: EdgeInsets.only(top: top, bottom: 34),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: ViewRequestDraftScreen(
        fixture: ZyraShellTestFixture().fixture,
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Sample codecs complete on the real event loop. Wait for the protected
  // shell's prepared public deck before moving into Journey, preserving the
  // actual photo, geometry and zero-network assertions below.
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

VoidCallback _action(WidgetTester tester, String id) {
  final target = tester.widget<Widget>(_key(id));
  if (target is ButtonStyleButton) return target.onPressed!;
  if (target is InkWell) return target.onTap!;
  if (target is GestureDetector) return target.onTap!;
  final button = find.descendant(
    of: _key(id),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );
  if (button.evaluate().isNotEmpty) {
    return tester.widget<ButtonStyleButton>(button.first).onPressed!;
  }
  final ink = find.descendant(of: _key(id), matching: find.byType(InkWell));
  expect(ink, findsWidgets, reason: '$id has a labelled live action');
  return tester.widget<InkWell>(ink.first).onTap!;
}

Future<void> _press(WidgetTester tester, String id) async {
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  if (target.evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable);
    expect(scrollables, findsWidgets, reason: 'A real reading surface for $id');
    await tester.scrollUntilVisible(target, 180, scrollable: scrollables.last);
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget, reason: 'Required actual action $id');
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }
  var visible = tester
      .getRect(target)
      .intersect(Offset.zero & tester.view.physicalSize);
  final scroll = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scroll.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(scroll.first));
  }
  // The ordinary preview navigation stays present below the page. Move a
  // genuine reading surface if necessary; never call a retained action here.
  final navigation = find.byType(FloatingNavBar);
  if (navigation.evaluate().isNotEmpty &&
      find.byType(BottomSheet).evaluate().isEmpty) {
    final navTop = tester.getRect(navigation).top;
    if (visible.center.dy >= navTop && scroll.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await tester.pumpAndSettle();
      visible = tester.getRect(target).intersect(tester.getRect(scroll.first));
    }
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
    reason: '$id must receive a real tap at ${visible.center}',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  final owner = zyraShellFixtureFor(tester);
  if (owner.setupScopeOpen) await closeZyraDevControls(tester);
  for (var depth = 0; owner.latest!.pages.isNotEmpty && depth < 8; depth++) {
    await returnZyraPreviewPage(tester);
  }
  expect(owner.latest!.pages, isEmpty);
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  final navigation = find.byType(FloatingNavBar);
  await expandZyraPreviewTabBarIfIdle(tester);
  final cell = _key('floating-nav-item-$index');
  expect(navigation, findsOneWidget);
  expect(cell, findsOneWidget);
  final box = tester.renderObject<RenderBox>(navigation);
  final local = box.globalToLocal(tester.getCenter(cell));
  expect(
    navigation.hitTestable(
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

Future<void> _openControls(WidgetTester tester) async {
  await _nav(tester, 1);
  await openZyraDevControls(tester);
  expect(_key('concept_journey_preview_1'), findsNothing);
}

Future<void> _seed(WidgetTester tester) async {
  await _openControls(tester);
  await _press(tester, 'concept_journey_preview_3');
  await closeZyraDevControls(tester);
}

ZyraOneJourneyTab _places(WidgetTester tester) =>
    tester.widget(find.byType(ZyraOneJourneyTab));

Future<void> _selectPlace(WidgetTester tester, String id) async {
  final places = _places(tester);
  final index = places.journeys.indexWhere((person) => person.id == id);
  expect(index, greaterThanOrEqualTo(0));
  final start = places.index;
  for (var step = 0; step < (start - index).abs(); step++) {
    await _press(
      tester,
      start < index ? 'journey_tab_next' : 'journey_tab_previous',
    );
  }
  expect(_places(tester).index, index);
  expect(_places(tester).journeys[index].id, id);
}

void _expectStates(WidgetTester tester, List<String> ids) {
  final cards = _places(tester).journeys;
  expect(cards.map((card) => card.id), unorderedEquals(ids));
  for (final card in cards) {
    expect(card.stageLabel, 'Salam Exchange');
  }
}

const _allActive = ['draft-sara', 'draft-aisha', 'draft-maryam'];

void _expectLockedCompatibility(String id, String name) {
  expect(_key('draft_journey_compatibility_locked_$id'), findsOneWidget);
  expect(_key('draft_journey_compatibility_$id'), findsNothing);
  expect(find.text('Compatibility score'), findsOneWidget);
  expect(find.text('You and $name'), findsNothing);
  expect(find.text('Your result stays private'), findsOneWidget);
  expect(
    find.text('Complete Compatibility Reveal together to view your result.'),
    findsOneWidget,
  );
  expect(_key('draft_disclosure_continue_$id'), findsOneWidget);
  expect(_key('concept_compatibility_continue_$id'), findsNothing);
  expect(find.text('Your result'), findsNothing);
  expect(find.text('Your shared result'), findsNothing);
  expect(find.textContaining('%'), findsNothing);
}

Future<void> _options(WidgetTester tester, String id) async {
  if (find.byType(ZyraOneJourneyOptionsPage).evaluate().isNotEmpty) {
    if (tester
            .widget<ZyraConceptJourneyOptions>(
              find.byType(ZyraConceptJourneyOptions),
            )
            .id ==
        id) {
      return;
    }
    await _dismissOptions(tester);
  }
  await _selectPlace(tester, id);
  await _press(tester, 'draft_journey_options_$id');
  expect(find.byType(BottomSheet), findsNothing);
  expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
  expect(_key('draft_options_pause_$id'), findsNothing);
  expect(find.text('Request Pause'), findsNothing);
  for (final action in [
    'end',
    'profile',
    'timeline',
    'bio',
    'compatibility',
    'guardians',
    'report',
  ]) {
    expect(_key('draft_options_${action}_$id'), findsOneWidget);
    for (final other in _people.where((person) => person.id != id)) {
      expect(_key('draft_options_${action}_${other.id}'), findsNothing);
    }
  }
  final owner = find.byType(ZyraConceptJourneyOptions);
  final options = tester.widget<ZyraConceptJourneyOptions>(owner);
  expect(options.id, id);
  expect(options.lockedPage, isTrue);
}

Future<void> _dismissOptions(WidgetTester tester) async {
  await returnZyraPreviewPage(tester);
  expect(find.byType(ZyraOneJourneyOptionsPage), findsNothing);
  expect(find.byType(ZyraOneJourneyTab), findsOneWidget);
}

Future<void> _local(WidgetTester tester, String id) async {
  if (_key(id).evaluate().isEmpty &&
      find.byType(ZyraConceptJourneyPresentation).evaluate().isNotEmpty) {
    final pager = find.descendant(
      of: find.byType(ZyraConceptJourneyPresentation),
      matching: find.byType(PageView),
    );
    if (pager.evaluate().isNotEmpty) {
      await tester.drag(pager.first, const Offset(0, -420));
      await tester.pumpAndSettle();
    }
  }
  await _press(tester, id);
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError(
      'Theme/action comparisons must not create an HTTP client.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFatal = WidgetController.hitTestWarningShouldBeFatal;
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(
    () => WidgetController.hitTestWarningShouldBeFatal = previousFatal,
  );
  setUp(() {
    ZyraText.useTestFontStubs = true;
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

  // QUESTIONS Q32: the LOCK 13 place reader mounts only the selected person.
  testWidgets(
    'selected place keeps the actual portrait and addressed Continue action',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _seed(tester);
        _expectStates(tester, _allActive);
        for (final person in _people) {
          await _selectPlace(tester, person.id);
          final selected = _places(tester);
          final card = selected.journeys[selected.index];
          expect(card.photo, isNotNull);
          expect(find.text(person.name), findsOneWidget);
          expect(_key('journey_tab_card'), findsOneWidget);
          expect(_key('journey_tab_continue').hitTestable(), findsOneWidget);
          expect(find.text('Continue Journey'), findsOneWidget);
        }
        await _selectPlace(tester, 'draft-sara');
        await _press(tester, 'journey_tab_continue');
        final journey = tester.widget<ZyraConceptJourneyPresentation>(
          find.byType(ZyraConceptJourneyPresentation),
        );
        expect(journey.firstName, 'Sara');
        await _press(tester, 'concept_journey_arrival_continue');
        await _local(tester, 'draft_salam_draft-sara');
        await _nav(tester, 1);
        _expectStates(tester, _allActive);
        expect(_places(tester).journeys[0].nextStep, 'Waiting for Sara');
        expect(_places(tester).journeys[1].nextStep, 'Your turn: send Salam');
        expect(_places(tester).journeys[2].nextStep, 'Your turn: send Salam');
      }, network);
      expect(network.attempts, 0);
    },
  );

  // QUESTIONS Q32: repeated callbacks can open only one current route.
  testWidgets(
    'Pushed Options single flight and repeated compatibility selection keep one owner',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _selectPlace(tester, 'draft-aisha');
      final open = _places(tester).onOptions;
      open();
      open();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
      expect(find.byType(ZyraConceptJourneyOptions), findsOneWidget);
      final select = tester
          .widget<ZyraConceptJourneyOptions>(
            find.byType(ZyraConceptJourneyOptions),
          )
          .onSelected;
      select(ZyraConceptJourneyOption.compatibility);
      select(ZyraConceptJourneyOption.compatibility);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      _expectLockedCompatibility('draft-aisha', 'Aisha');
      final staleContinue = _action(
        tester,
        'draft_disclosure_continue_draft-aisha',
      );
      expect(zyraShellFixtureFor(tester).latest!.pages, [
        'journey_options',
        'journey_compatibility_locked',
      ]);
      await returnZyraPreviewPage(tester);
      expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
      expect(zyraShellFixtureFor(tester).latest!.pages, ['journey_options']);
      await _dismissOptions(tester);
      expect(_places(tester).journeys[_places(tester).index].id, 'draft-aisha');
      expect(zyraShellFixtureFor(tester).latest!.pages, isEmpty);
      staleContinue();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraConceptJourneyPresentation), findsNothing);
      expect(
        _key('draft_journey_compatibility_locked_draft-aisha'),
        findsNothing,
      );
      _expectStates(tester, _allActive);
      expect(tester.takeException(), isNull);
    },
  );

  // QUESTIONS Q32: each Options route belongs to one selected place.
  testWidgets(
    'pushed Options route the actual person and cancel without mutation',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _seed(tester);
        for (final person in _people) {
          await _options(tester, person.id);
          await _press(tester, 'draft_options_profile_${person.id}');
          expect(find.byType(BottomSheet), findsNothing);
          expect(
            tester
                .widget<ZyraOneJourneyBrowsePresentation>(
                  find.byType(ZyraOneJourneyBrowsePresentation),
                )
                .profile
                .id,
            person.id,
          );
          await _nav(tester, 1);
          await _options(tester, person.id);
          await _press(tester, 'draft_options_timeline_${person.id}');
          expect(find.text('Timeline'), findsOneWidget);
          expect(find.byType(BottomSheet), findsNothing);
          await _nav(tester, 1);
          await _options(tester, person.id);
          await _press(tester, 'draft_options_compatibility_${person.id}');
          _expectLockedCompatibility(person.id, person.name);
          expect(find.byType(BottomSheet), findsNothing);
          await _press(tester, 'draft_disclosure_continue_${person.id}');
          expect(
            tester
                .widget<ZyraConceptJourneyPresentation>(
                  find.byType(ZyraConceptJourneyPresentation),
                )
                .firstName,
            person.name,
          );
          await _nav(tester, 1);
          _expectStates(tester, _allActive);
          await _options(tester, person.id);
          await _press(tester, 'draft_options_guardians_${person.id}');
          expect(_key('draft_journey_guardians_${person.id}'), findsOneWidget);
          expect(
            find.descendant(
              of: _key('draft_journey_guardians_${person.id}'),
              matching: find.text('Journey with ${person.name}'),
            ),
            findsWidgets,
          );
          expect(find.byType(BottomSheet), findsNothing);
          await _nav(tester, 1);
          _expectStates(tester, _allActive);
          for (final intent in ['end']) {
            await _options(tester, person.id);
            await _press(tester, 'draft_options_${intent}_${person.id}');
            expect(_key('draft_journey_action_${person.id}'), findsOneWidget);
            expect(find.text('End with ${person.name}?'), findsOneWidget);
            expect(find.byType(BottomSheet), findsOneWidget);
            await _press(tester, 'draft_cancel_journey_action_${person.id}');
            expect(_key('draft_journey_action_${person.id}'), findsNothing);
            expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
            await _dismissOptions(tester);
            _expectStates(tester, _allActive);
          }
        }
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  // QUESTIONS Q32: repeated End uses one current confirmation lease.
  testWidgets(
    'two immediate End callbacks end the addressed Journey only once',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _options(tester, 'draft-maryam');
      await _press(tester, 'draft_options_end_draft-maryam');
      final confirm = _action(tester, 'draft_confirm_end_draft-maryam');
      final owner = zyraShellFixtureFor(tester);
      final before = owner.latest!.model;
      confirm();
      confirm();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_key('draft_journey_action_draft-maryam'), findsNothing);
      final after = owner.latest!.model;
      expect(after.endedAttempts, hasLength(before.endedAttempts.length + 1));
      expect(after.endedAttempts.last.profileId, 'draft-maryam');
      expect(after.states['draft-sara'], before.states['draft-sara']);
      expect(after.states['draft-aisha'], before.states['draft-aisha']);
      await _nav(tester, 1);
      _expectStates(tester, ['draft-sara', 'draft-aisha']);
      confirm();
      await tester.pumpAndSettle();
      expect(owner.latest!.model.endedAttempts, after.endedAttempts);
      expect(owner.latest!.model.states, after.states);
      _expectStates(tester, ['draft-sara', 'draft-aisha']);
      expect(tester.takeException(), isNull);
    },
  );

  // QUESTIONS Q32: the addressed End leaves other places active.
  testWidgets('locked card confirmed End affects only its addressed Journey', (
    tester,
  ) async {
    final network = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      await _mount(tester);
      await _seed(tester);
      _expectStates(tester, _allActive);
      await _options(tester, 'draft-maryam');
      await _press(tester, 'draft_options_end_draft-maryam');
      final staleEnd = _action(tester, 'draft_confirm_end_draft-maryam');
      await _press(tester, 'draft_confirm_end_draft-maryam');
      await _nav(tester, 1);
      _expectStates(tester, ['draft-sara', 'draft-aisha']);
      staleEnd();
      await tester.pumpAndSettle();
      _expectStates(tester, ['draft-sara', 'draft-aisha']);
      await _nav(tester, 2);
      await _press(tester, 'concept-my-ended');
      expect(find.textContaining('Ended Journey'), findsWidgets);
      expect(find.textContaining('Maryam'), findsWidgets);
      await _press(tester, 'draft_archive_details_draft-maryam');
      expect(_key('draft_options_archive_draft-maryam'), findsNothing);
      expect(find.text('View archive'), findsNothing);
      await _press(tester, 'draft_options_timeline_draft-maryam');
      expect(find.text('Journey with Maryam'), findsOneWidget);
      expect(_key('draft_pause_draft-maryam'), findsNothing);
      expect(_key('draft_end_draft-maryam'), findsNothing);
      expect(_key('draft_resume_draft-maryam'), findsNothing);
      final history = tester.widget<ZyraDraftTimelinePresentation>(
        find.byType(ZyraDraftTimelinePresentation),
      );
      expect(history.subjectId, 'draft-maryam');
      expect(history.view.frozen, isTrue);
      expect(history.onPropose, isNull);
      expect(history.onConfirm, isNull);
      expect(history.onNotYet, isNull);
      expect(
        history.view.entries.map((entry) => entry.type),
        containsAll(['match_created', 'journey_started', 'journey_ended']),
      );
      expect(_key('concept_message'), findsNothing);
      expect(_key('concept_send_message'), findsNothing);
      await _nav(tester, 1);
    }, network);
    expect(network.attempts, 0);
  });

  // QUESTIONS Q32: inspect current Journey and Focus routes for removed actions.
  testWidgets('simplified active Journey has no Pause action or Paused route', (
    tester,
  ) async {
    await _mount(tester);
    await _seed(tester);
    await _selectPlace(tester, 'draft-aisha');
    await _press(tester, 'journey_tab_continue');
    await _press(tester, 'concept_journey_arrival_continue');
    await _local(tester, 'draft_salam_draft-aisha');
    for (final control in [
      'draft_peer_salam_draft-aisha',
      'draft_stage_ready_draft-aisha',
      'draft_stage_peer_ready_draft-aisha',
      'draft_stage_next_draft-aisha',
    ]) {
      await _local(tester, control);
    }
    expect(_key('draft_pause_draft-aisha'), findsNothing);
    expect(_key('draft_agree_pause_draft-aisha'), findsNothing);
    expect(_key('draft_resume_draft-aisha'), findsNothing);
    expect(_key('draft_keep_paused_draft-aisha'), findsNothing);
    expect(find.textContaining('Continue, pause'), findsNothing);
    await _nav(tester, 1);
    expect(
      _places(tester).journeys.map((card) => card.id),
      unorderedEquals(_allActive),
    );
    await _options(tester, 'draft-aisha');
    expect(_key('draft_options_pause_draft-aisha'), findsNothing);
    await _dismissOptions(tester);
    await _nav(tester, 2);
    expect(_key('my-zyra-route-concept-my-paused'), findsNothing);
    expect(_key('my-zyra-route-concept-saved'), findsNothing);
    expect(find.text('Paused Journeys'), findsNothing);
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Now'), findsNothing);
    expect(find.text('Insights'), findsNothing);
    expect(_key('my-zyra-pages'), findsNothing);
    expect(
      find.byType(PageView),
      findsNothing,
      reason: 'There is no My ZYRA page slider in the simplified preview',
    );
  });

  // QUESTIONS Q32: keep current Options actions reachable with Larger Text.
  testWidgets('selected places keep Options and confirmations reachable', (
    tester,
  ) async {
    final network = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      await _mount(tester, enlarged: true);
      await _seed(tester);
      for (final person in _people) {
        await _options(tester, person.id);
        await _press(tester, 'draft_options_compatibility_${person.id}');
        _expectLockedCompatibility(person.id, person.name);
        await _press(tester, 'draft_disclosure_continue_${person.id}');
        expect(
          tester
              .widget<ZyraConceptJourneyPresentation>(
                find.byType(ZyraConceptJourneyPresentation),
              )
              .firstName,
          person.name,
        );
        await _nav(tester, 1);
        await _options(tester, person.id);
        await _press(tester, 'draft_options_guardians_${person.id}');
        expect(_key('draft_journey_guardians_${person.id}'), findsOneWidget);
        expect(
          find.descendant(
            of: _key('draft_journey_guardians_${person.id}'),
            matching: find.text('Journey with ${person.name}'),
          ),
          findsWidgets,
        );
        await _nav(tester, 1);
        await _options(tester, person.id);
        for (final intent in ['end']) {
          if (find.byType(ZyraConceptJourneyOptions).evaluate().isEmpty) {
            await _options(tester, person.id);
          }
          await _press(tester, 'draft_options_${intent}_${person.id}');
          expect(_key('draft_confirm_${intent}_${person.id}'), findsOneWidget);
          await _press(tester, 'draft_cancel_journey_action_${person.id}');
          expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
        }
        await _press(tester, 'draft_journey_${person.id}');
        expect(
          tester
              .widget<ZyraConceptJourneyPresentation>(
                find.byType(ZyraConceptJourneyPresentation),
              )
              .firstName,
          person.name,
        );
        await _nav(tester, 1);
      }
    }, network);
    expect(network.attempts, 0);
  });

  // QUESTIONS Q32: captured actions expire when moving to a different place.
  testWidgets(
    'dismissed Options and confirmation delegates cannot act on another person',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _options(tester, 'draft-aisha');
      final staleSheetEnd = _action(tester, 'draft_options_end_draft-aisha');
      await _dismissOptions(tester);
      await _options(tester, 'draft-maryam');
      staleSheetEnd();
      await tester.pumpAndSettle();
      expect(_key('draft_options_end_draft-maryam'), findsOneWidget);
      expect(_key('draft_journey_action_draft-aisha'), findsNothing);
      await _press(tester, 'draft_options_end_draft-maryam');
      final staleMaryamEnd = _action(tester, 'draft_confirm_end_draft-maryam');
      await _press(tester, 'draft_cancel_journey_action_draft-maryam');
      await _options(tester, 'draft-aisha');
      await _press(tester, 'draft_options_end_draft-aisha');
      staleMaryamEnd();
      await tester.pumpAndSettle();
      expect(_key('draft_journey_action_draft-aisha'), findsOneWidget);
      await _press(tester, 'draft_cancel_journey_action_draft-aisha');
      await _dismissOptions(tester);
      _expectStates(tester, _allActive);
    },
  );

  // QUESTIONS Q32: current Options and confirmation reject the old owner.
  for (final surface in ['pushed options', 'confirmation']) {
    for (final change in ['revocation', 'ABA', 'account generation']) {
      testWidgets('$surface refuses stale actions after $change', (
        tester,
      ) async {
        await _mount(tester);
        await _seed(tester);
        await _options(tester, 'draft-aisha');
        if (surface == 'confirmation') {
          await _press(tester, 'draft_options_end_draft-aisha');
        }
        final stale = surface == 'pushed options'
            ? [
                    'end',
                    'profile',
                    'timeline',
                    'bio',
                    'compatibility',
                    'guardians',
                    'report',
                  ]
                  .map(
                    (action) =>
                        _action(tester, 'draft_options_${action}_draft-aisha'),
                  )
                  .toList()
            : [
                _action(tester, 'draft_confirm_end_draft-aisha'),
                _action(tester, 'draft_cancel_journey_action_draft-aisha'),
              ];
        final owner = zyraShellFixtureFor(tester);
        final before = owner.latest!.model;
        if (change == 'account generation') {
          ZyraAccountState.resetForTesting();
          AppState.instance.resetForAccountChange();
        } else {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          if (change == 'ABA') {
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
        }
        if (surface == 'confirmation') {
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsNothing);
        }
        for (final callback in stale) {
          callback();
        }
        await tester.pumpAndSettle();
        expect(owner.latest!.model.endedAttempts, before.endedAttempts);
        expect(owner.latest!.model.states, before.states);
        expect(owner.latest!.model.progress, before.progress);
        expect(find.text('Preview closed'), findsOneWidget);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        expect(find.byType(BottomSheet), findsNothing);
        expect(_key('draft_journey_action_draft-aisha'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  // QUESTIONS Q32: a current Options callback cannot cross roles.
  testWidgets('authorized role change invalidates a dismissed Options action', (
    tester,
  ) async {
    await _mount(tester);
    await _seed(tester);
    await _options(tester, 'draft-aisha');
    final staleEnd = _action(tester, 'draft_options_end_draft-aisha');
    await _dismissOptions(tester);
    await _openControls(tester);
    await _press(tester, 'draft_role_guardian');
    staleEnd();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(_key('draft_journey_action_draft-aisha'), findsNothing);
    expect(
      tester
          .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
          .items
          .map((item) => item.label),
      ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile'],
    );
    expect(tester.takeException(), isNull);
  });

  // QUESTIONS Q32: exercised routes remain local to the preview account.
  testWidgets(
    'theme and local Journey choices never change member authority or preferences',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        SharedPreferences.setMockInitialValues({
          'ordinary-setting': 'preserved',
        });
        final prefs = await tester.runAsync(SharedPreferences.getInstance);
        Map<String, Object?> snapshot() => {
          for (final key in prefs!.getKeys()) key: prefs.get(key),
        };
        final previous = snapshot();
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
        final haptic = ZyraInteractionStyle.hapticLevel;
        var changes = 0;
        void changed() => changes++;
        app.addListener(changed);
        addTearDown(() => app.removeListener(changed));
        await _mount(tester);
        await _seed(tester);
        await _options(tester, 'draft-aisha');
        await _press(tester, 'draft_options_compatibility_draft-aisha');
        _expectLockedCompatibility('draft-aisha', 'Aisha');
        await _nav(tester, 1);
        await _options(tester, 'draft-maryam');
        await _press(tester, 'draft_options_end_draft-maryam');
        await _press(tester, 'draft_confirm_end_draft-maryam');
        await _nav(tester, 1);
        await _openControls(tester);
        expect(find.text('Journey card content'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'concept_journey_card_design_',
                ),
          ),
          findsNothing,
        );
        expect(snapshot(), previous);
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
        expect(ZyraInteractionStyle.hapticLevel, haptic);
        expect(changes, 0);
        expect(() => Supabase.instance, throwsA(isA<AssertionError>()));
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );
}
