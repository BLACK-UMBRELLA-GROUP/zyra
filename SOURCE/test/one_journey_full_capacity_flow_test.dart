import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_request_capacity_choice.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _occupied = ['draft-sara', 'draft-aisha', 'draft-maryam'];
const _incoming = 'draft-amira';
const _outgoing = 'draft-hana';
const _captureDirectory = String.fromEnvironment(
  'ZYRA_FULL_CAPACITY_CAPTURE_DIRECTORY',
);
const _boundary = ValueKey('full-capacity-flow-candidate');

Finder _key(String id) => find.byKey(ValueKey(id));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Full-capacity preview requests must stay offline.');
  }
}

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 44, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: ViewRequestDraftScreen(
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      if (deck.profiles.isNotEmpty &&
          deck.profiles.every((profile) => profile.photos.isNotEmpty)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tester.pump();
    }
    fail('The offline photo deck did not finish preparing.');
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

VoidCallback? _action(WidgetTester tester, String id) {
  final target = _key(id);
  expect(target, findsOneWidget);
  final widget = tester.widget<Widget>(target);
  if (widget is ButtonStyleButton) return widget.onPressed;
  if (widget is InkWell) return widget.onTap;
  if (widget is GestureDetector) return widget.onTap;
  final ink = find.descendant(of: target, matching: find.byType(InkWell));
  expect(ink, findsWidgets);
  return tester.widget<InkWell>(ink.first).onTap;
}

Future<void> _press(WidgetTester tester, String id) async {
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  if (target.evaluate().isEmpty &&
      (id.startsWith('draft_accept_') ||
          id.startsWith('draft_recipient_') ||
          id.startsWith('draft_cancel_'))) {
    final peer = id.substring(id.indexOf('draft-', 6));
    await _press(tester, 'concept_request_${peer}_header');
  }
  if (target.evaluate().isEmpty) {
    final owner = _key('my-zyra-quiet-scroll-0');
    expect(owner, findsOneWidget, reason: 'Missing real action $id');
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find
          .descendant(of: owner, matching: find.byType(Scrollable))
          .first,
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
  expect(visible.width, greaterThan(0), reason: '$id has visible width');
  expect(visible.height, greaterThan(0), reason: '$id has visible height');
  final box = tester.renderObject<RenderBox>(target);
  final point = box.globalToLocal(visible.center);
  expect(
    target.hitTestable(
      at: Alignment(
        point.dx * 2 / box.size.width - 1,
        point.dy * 2 / box.size.height - 1,
      ),
    ),
    findsOneWidget,
    reason: '$id must receive the real tap, not just expose a callback.',
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
    if (find.byKey(const ValueKey('dev_controls_page')).evaluate().isNotEmpty) {
      await closeZyraDevControls(tester);
      continue;
    }
    // Use the approved real Back control, not the retired vertical pull.
    await returnZyraPreviewPage(tester);
  }
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  final cell = _key('floating-nav-item-$index');
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
  expect(tester.takeException(), isNull);
}

Future<void> _controls(WidgetTester tester) async {
  for (
    var depth = 0;
    _key('concept_page_options_context').evaluate().isEmpty && depth < 10;
    depth++
  ) {
    await _press(tester, 'draft_back');
  }
  expect(find.text('Page options'), findsOneWidget);
  expect(_key('concept_page_options_context'), findsOneWidget);
}

Future<void> _seed(WidgetTester tester) async {
  await _nav(tester, 1);
  await _controls(tester);
  expect(
    tester.widget<Text>(_key('concept_page_options_context')).data,
    'Journey',
  );
  await _press(tester, 'concept_journey_preview_3');
  _expectOccupied(tester, _occupied);
}

void _expectOccupied(WidgetTester tester, List<String> expected) {
  final cards = _overviewCards(tester);
  expect(cards.map((card) => card.profile.id), expected);
  expect(cards.length, lessThanOrEqualTo(3));
}

List<ZyraOneJourneyConnectionsActiveCard> _overviewCards(WidgetTester tester) {
  final presentation = find.byType(ZyraOneJourneyConnectionsPresentation);
  if (presentation.evaluate().isEmpty) {
    expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsNothing);
    return [];
  }
  // The reading fallback lazily mounts cards. Inspect the full supplied
  // overview, not just currently mounted children, for the capacity invariant.
  return tester
      .widget<ZyraOneJourneyConnectionsPresentation>(presentation)
      .pages
      .single
      .whereType<ZyraOneJourneyConnectionsActiveCard>()
      .toList();
}

ZyraRequestCapacityChoice _choice(WidgetTester tester) => tester
    .widget<ZyraRequestCapacityChoice>(find.byType(ZyraRequestCapacityChoice));

Future<void> _requests(WidgetTester tester, {bool incoming = true}) async {
  await _nav(tester, 2);
  await _press(tester, 'my-zyra-route-concept-my-requests');
  await _press(tester, 'draft_requests_${incoming ? 0 : 1}');
}

Future<void> _sendAtCapacity(WidgetTester tester) async {
  await _nav(tester, 0);
  for (
    var step = 0;
    _key('draft_profile_$_outgoing').evaluate().isEmpty;
    step++
  ) {
    expect(step, lessThan(8), reason: 'Find the eligible next sample profile.');
    await _press(tester, 'concept_next_profile');
  }
  await _press(tester, 'draft_profile_$_outgoing');
  expect(find.text('Request sent'), findsOneWidget);
}

Future<void> _openChoice(WidgetTester tester, {bool incoming = true}) async {
  await _requests(tester, incoming: incoming);
  await _press(
    tester,
    incoming ? 'draft_accept_$_incoming' : 'draft_recipient_$_outgoing',
  );
  expect(_key('request_capacity_choice'), findsOneWidget);
  final choice = _choice(tester);
  expect(choice.capacity, 3);
  expect(choice.items.map((item) => item.id), _occupied);
  expect(choice.selectedId, isNull);
  expect(find.text('End Journey & accept request?'), findsNothing);
}

Future<void> _confirmChoice(WidgetTester tester, String old) async {
  await _press(tester, 'request_capacity_journey_$old');
  expect(_choice(tester).selectedId, old);
  await _press(tester, 'request_capacity_continue');
  expect(find.text('End Journey & accept request?'), findsOneWidget);
  expect(_key('request_capacity_confirm'), findsOneWidget);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  // Await the production local photo renderer, not placeholder imagery.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
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
    final font = FontLoader('PoppinsFullCapacityFlow');
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
    if (_captureDirectory.isNotEmpty) {
      final directory = Directory(_captureDirectory);
      expect(directory.existsSync(), isFalse);
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
    SharedPreferences.setMockInitialValues({'ordinary-setting': 'unchanged'});
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsFullCapacityFlow';
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
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

  testWidgets(
    'actual shell capacity frame clears safe areas with no ordinary scrolling',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _nav(tester, 0);
      await _capture(tester, 'monthly_full_browse');
      await _openChoice(tester);
      final heading = tester.getRect(
        find.text('Your Journey places are full.'),
      );
      final cancel = tester.getRect(_key('request_capacity_cancel'));
      expect(heading.left, 20);
      expect(heading.top, greaterThanOrEqualTo(64));
      expect(cancel.bottom, lessThanOrEqualTo(852 - 34 - 20));
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: _key('request_capacity_choice'),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scroll.position.maxScrollExtent, 0);
      await _capture(tester, 'received_full_choice');
      await _press(tester, 'request_capacity_journey_draft-aisha');
      await _capture(tester, 'received_selected_choice');
      await _press(tester, 'request_capacity_continue');
      await _capture(tester, 'received_confirm_end');
      await _press(tester, 'request_capacity_keep');
      await _press(tester, 'request_capacity_cancel');
      await _sendAtCapacity(tester);
      await _openChoice(tester, incoming: false);
      await _capture(tester, 'sent_full_choice');
    },
  );

  testWidgets(
    'full monthly Browse can send cancel and inspect without a fourth place',
    (tester) async {
      final app = AppState.instance;
      app
        ..name = 'Ordinary member preserved'
        ..surnameLine = 'Unchanged surname'
        ..photos = ['unchanged-photo']
        ..plan = ZyraPlan.one;
      final active = List.of(app.activeJourneys);
      final potential = List.of(app.potentialJourneys);
      final saved = List.of(app.saved);
      final generation = ZyraAccountState.generation;
      final owner = ZyraAccountState.userId;
      final haptics = ZyraInteractionStyle.hapticLevel;
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      Map<String, Object?> preferences() => {
        for (final key in prefs!.getKeys()) key: prefs.get(key),
      };
      final before = preferences();
      var changes = 0;
      void changed() => changes++;
      app.addListener(changed);
      addTearDown(() => app.removeListener(changed));
      await _mount(tester);
      await _seed(tester);
      await _sendAtCapacity(tester);
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      expect(browse.profiles[browse.selectedIndex].id, _outgoing);
      expect(find.text('Your Journey places are full.'), findsNothing);
      expect(_key('draft_confirm_request'), findsNothing);
      await _press(tester, 'draft_profile_$_outgoing');
      expect(find.text('Request a Journey'), findsOneWidget);
      expect(
        tester
            .widget<ZyraOneJourneyBrowseDesigns>(
              find.byType(ZyraOneJourneyBrowseDesigns),
            )
            .profiles[browse.selectedIndex]
            .id,
        _outgoing,
      );
      await _press(tester, 'concept_browse_menu');
      await _nav(tester, 1);
      expect(_key('draft_scan_presentation'), findsOneWidget);
      await _nav(tester, 1);
      _expectOccupied(tester, _occupied);
      expect(app.name, 'Ordinary member preserved');
      expect(app.surnameLine, 'Unchanged surname');
      expect(app.photos, ['unchanged-photo']);
      expect(app.plan, ZyraPlan.one);
      expect(app.activeJourneys, active);
      expect(app.potentialJourneys, potential);
      expect(app.saved, saved);
      expect(changes, 0);
      expect(preferences(), before);
      expect(ZyraAccountState.generation, generation);
      expect(ZyraAccountState.userId, owner);
      expect(ZyraInteractionStyle.hapticLevel, haptics);
    },
  );

  for (final incoming in [true, false]) {
    final direction = incoming ? 'received' : 'sent';
    final target = incoming ? _incoming : _outgoing;
    testWidgets(
      '$direction full acceptance can keep its Journeys and request',
      (tester) async {
        await _mount(tester);
        await _seed(tester);
        if (!incoming) await _sendAtCapacity(tester);
        await _openChoice(tester, incoming: incoming);
        expect(_action(tester, 'request_capacity_continue'), isNull);
        await _press(tester, 'request_capacity_cancel');
        expect(_key('request_capacity_choice'), findsNothing);
        expect(_key('concept_activity_requests'), findsOneWidget);
        expect(_key('concept_request_${target}_header'), findsOneWidget);
        await _nav(tester, 1);
        _expectOccupied(tester, _occupied);
        await _nav(tester, 2);
        await _press(tester, 'my-zyra-route-concept-my-ended');
        expect(find.text('No ended Journeys.'), findsOneWidget);
      },
    );

    testWidgets(
      '$direction replacement archives one and reserves only three places',
      (tester) async {
        await _mount(tester);
        await _seed(tester);
        if (!incoming) await _sendAtCapacity(tester);
        await _openChoice(tester, incoming: incoming);
        await _confirmChoice(tester, 'draft-aisha');
        final retainedConfirm = _action(tester, 'request_capacity_confirm')!;
        await _press(tester, 'request_capacity_confirm');
        retainedConfirm();
        retainedConfirm();
        await tester.pumpAndSettle();
        expect(_key('request_capacity_choice'), findsNothing);
        expect(_key('draft_ready_$target'), findsOneWidget);
        expect(_action(tester, 'draft_begin_$target'), isNull);
        expect(_key('concept_send_message'), findsNothing);
        expect(_key('draft_reveal_$target'), findsNothing);
        await _press(tester, 'draft_ready_$target');
        expect(_action(tester, 'draft_begin_$target'), isNull);
        await _press(tester, 'draft_peer_ready_$target');
        expect(_action(tester, 'draft_begin_$target'), isNotNull);
        await _nav(tester, 1);
        _expectOccupied(
          tester,
          incoming
              ? [_incoming, 'draft-sara', 'draft-maryam']
              : ['draft-sara', 'draft-maryam', _outgoing],
        );
        final cards = _overviewCards(tester);
        expect(
          cards.firstWhere((card) => card.profile.id == target).stateLabel,
          'Preparing together · place reserved',
        );
        for (final card in cards.where((card) => card.profile.id != target)) {
          expect(card.stateLabel, 'Active Journey');
          expect(card.stageLabel, 'Salam Exchange');
        }
        await _nav(tester, 2);
        await _press(tester, 'my-zyra-route-concept-my-ended');
        expect(find.textContaining('Aisha'), findsWidgets);
        await _press(tester, 'draft_journey_options_draft-aisha');
        expect(_key('draft_options_archive_draft-aisha'), findsNothing);
        expect(find.text('View archive'), findsNothing);
        await _press(tester, 'draft_options_timeline_draft-aisha');
        final history = tester.widget<ZyraDraftTimelinePresentation>(
          find.byType(ZyraDraftTimelinePresentation),
        );
        expect(history.subjectId, 'draft-aisha');
        expect(history.view.frozen, isTrue);
        expect(history.onPropose, isNull);
        expect(history.onConfirm, isNull);
        expect(history.onNotYet, isNull);
        expect(
          history.view.entries.map((entry) => entry.type),
          containsAll(['match_created', 'journey_started', 'journey_ended']),
        );
        expect(find.text('Journey invitation accepted'), findsOneWidget);
        expect(find.text('Journey began'), findsOneWidget);
        expect(find.text('Journey ended'), findsOneWidget);
        expect(find.text('Restart'), findsNothing);
        expect(_key('concept_send_message'), findsNothing);
      },
    );
  }

  testWidgets(
    'confirmation cancel retains selected chooser without ending or accepting',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _openChoice(tester);
      await _confirmChoice(tester, 'draft-sara');
      await _press(tester, 'request_capacity_keep');
      expect(_key('request_capacity_choice'), findsOneWidget);
      expect(_choice(tester).selectedId, 'draft-sara');
      await _nav(tester, 1);
      _expectOccupied(tester, _occupied);
      await _requests(tester);
      expect(_key('concept_request_${_incoming}_header'), findsOneWidget);
    },
  );

  testWidgets(
    'unknown nonoccupied and request IDs cannot become an End selection',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _openChoice(tester);
      for (final invalid in ['not-a-peer', _incoming, _outgoing]) {
        _choice(tester).onSelected(invalid);
        await tester.pumpAndSettle();
        expect(_choice(tester).selectedId, isNull);
        expect(_action(tester, 'request_capacity_continue'), isNull);
        expect(_key('request_capacity_confirm'), findsNothing);
      }
      await _nav(tester, 1);
      _expectOccupied(tester, _occupied);
    },
  );

  for (final change in ['tab', 'reset', 'role']) {
    testWidgets(
      'retained chooser commands refuse after $change changes its route',
      (tester) async {
        await _mount(tester);
        await _seed(tester);
        await _openChoice(tester);
        final staleSelection = _choice(tester).onSelected;
        final staleCancel = _choice(tester).onCancel;
        await _press(tester, 'request_capacity_journey_draft-sara');
        final staleContinue = _choice(tester).onContinue!;
        if (change == 'tab') {
          await _nav(tester, 1);
        } else {
          await _controls(tester);
          await _press(
            tester,
            change == 'reset' ? 'draft_reset' : 'draft_role_guardian',
          );
        }
        staleSelection('draft-aisha');
        staleCancel();
        staleContinue();
        await tester.pumpAndSettle();
        expect(_key('request_capacity_confirm'), findsNothing);
        expect(_key('request_capacity_choice'), findsNothing);
        if (change == 'role') {
          await _controls(tester);
          await _press(tester, 'draft_role_seeker');
        }
        await _nav(tester, 1);
        _expectOccupied(tester, change == 'reset' ? [] : _occupied);
        await _requests(tester);
        expect(_key('concept_request_${_incoming}_header'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'retained confirm refuses after explicit cancellation changes the request',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _openChoice(tester);
      await _confirmChoice(tester, 'draft-aisha');
      final stale = _action(tester, 'request_capacity_confirm')!;
      await _press(tester, 'request_capacity_keep');
      await _press(tester, 'request_capacity_cancel');
      stale();
      await tester.pumpAndSettle();
      expect(_key('request_capacity_choice'), findsNothing);
      expect(_key('draft_ready_$_incoming'), findsNothing);
      await _nav(tester, 1);
      _expectOccupied(tester, _occupied);
    },
  );

  testWidgets(
    'an independently ended selection invalidates its old capacity choice',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _openChoice(tester);
      await _press(tester, 'request_capacity_journey_draft-aisha');
      final staleContinue = _choice(tester).onContinue!;
      final staleCancel = _choice(tester).onCancel;
      await _nav(tester, 1);
      await _press(tester, 'draft_journey_options_draft-aisha');
      await _press(tester, 'draft_options_end_draft-aisha');
      await _press(tester, 'draft_confirm_end_draft-aisha');
      staleContinue();
      staleCancel();
      await tester.pumpAndSettle();
      expect(_key('request_capacity_confirm'), findsNothing);
      expect(_key('draft_ready_$_incoming'), findsNothing);
      await _nav(tester, 1);
      _expectOccupied(tester, ['draft-sara', 'draft-maryam']);
      await _requests(tester);
      await _press(tester, 'draft_accept_$_incoming');
      expect(_key('request_capacity_choice'), findsNothing);
      expect(_key('draft_ready_$_incoming'), findsOneWidget);
      await _nav(tester, 1);
      _expectOccupied(tester, [_incoming, 'draft-sara', 'draft-maryam']);
    },
  );

  testWidgets(
    'retained confirmation cannot commit after developer revocation',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _openChoice(tester);
      await _confirmChoice(tester, 'draft-aisha');
      final stale = _action(tester, 'request_capacity_confirm')!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      expect(_key('draft_ready_$_incoming'), findsNothing);
      expect(AppState.instance.activeJourneys, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'capacity choices and confirmation remain usable at ${scale * 100}% text',
      (tester) async {
        await _mount(tester, scale: scale, size: const Size(320, 568));
        await _seed(tester);
        await _openChoice(tester);
        if (scale == 2) await _capture(tester, 'short_200_choice');
        for (final old in _occupied) {
          await _press(tester, 'request_capacity_journey_$old');
          expect(_choice(tester).selectedId, old);
          final row = tester.getSize(_key('request_capacity_journey_$old'));
          expect(row.width, greaterThanOrEqualTo(44));
          expect(row.height, greaterThanOrEqualTo(44));
        }
        if (scale == 2) await _capture(tester, 'short_200_lower_choice');
        await _press(tester, 'request_capacity_continue');
        expect(find.text('End Journey & accept request?'), findsOneWidget);
        final confirm = tester.getSize(_key('request_capacity_confirm'));
        expect(confirm.width, greaterThanOrEqualTo(44));
        expect(confirm.height, greaterThanOrEqualTo(44));
        await _press(tester, 'request_capacity_keep');
        expect(_choice(tester).selectedId, 'draft-maryam');
        await _press(tester, 'request_capacity_cancel');
        expect(_key('concept_activity_requests'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
