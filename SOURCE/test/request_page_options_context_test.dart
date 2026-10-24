// Real protected request-shell page ownership. The bundled people, credits
// and history stay disposable; this suite cannot establish member authority.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_journey_icon_selection.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_next_photo_motion.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_PAGE_OPTIONS_CAPTURE_DIR',
);
const _font = 'PoppinsPageOptionsContext';
const _boundary = ValueKey('page-options-context-capture');
const _requestsLabels = ['Received', 'Sent'];
const _seekerTitles = ['Profiles', 'Journey', 'My ZYRA', 'Guardian', 'Profile'];
const _guardianTitles = ['My ZYRA', 'Network', 'Seekers', 'Profile'];

Finder _key(String value) => find.byKey(ValueKey(value));

void _expectEndedCard() {
  expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsOneWidget);
  expect(_key('draft_restart_draft-noor'), findsOneWidget);
  expect(_key('draft_journey_options_draft-noor'), findsOneWidget);
  expect(find.text('Request restart'), findsOneWidget);
  expect(find.text('Ended Journey · read-only archive'), findsNothing);
}

Finder get _motionPicker =>
    find.byType(DropdownButtonFormField<ZyraBrowseNextMotion>);
Finder get _iconPicker =>
    find.byType(DropdownButtonFormField<ZyraJourneyIconDesign>);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Page-options contexts must stay offline.');
  }
}

Future<void> _mount(
  WidgetTester tester, {
  bool guardian = false,
  double scale = 1,
  Size size = const Size(393, 852),
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
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: ViewRequestDraftScreen(
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
        initialGuardianRole: guardian,
        onExit: () => fail('A Page-options return must not exit the app.'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (!guardian) {
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final target = find.byType(ZyraOneJourneyBrowseDesigns);
        if (target.evaluate().isNotEmpty) {
          final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(target);
          if (deck.profiles.isNotEmpty &&
              deck.profiles.every((person) => person.photos.isNotEmpty)) {
            return;
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
      }
      fail('The offline Browse deck did not publish prepared image frames.');
    });
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

Future<void> _press(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) => _press(tester, _key(key));

Future<void> _nav(WidgetTester tester, int index) async {
  final nav = find.byType(FloatingNavBar);
  expect(nav, findsOneWidget);
  final cell = _key('floating-nav-item-$index');
  expect(cell, findsOneWidget);
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

Future<void> _toggleOptions(WidgetTester tester) =>
    toggleZyraDevControls(tester);

void _context(WidgetTester tester, String title) {
  expect(find.text('Page options'), findsOneWidget);
  expect(find.text('Option 1'), findsNothing);
  expect(find.text('Option 2'), findsNothing);
  expect(find.text('App design'), findsNothing);
  final context = tester.widget<Text>(_key('concept_page_options_context'));
  expect(context.data, title);
  expect(context.style!.fontSize, 15);
  expect(_key('dev_controls_page'), findsOneWidget);
  expect(_key('dev_controls_close'), findsOneWidget);
  expect(_key('draft_close'), findsOneWidget);
  expect(_key('draft_back'), findsNothing);
  expect(find.byType(ZyraDevControlRail), findsNothing);
  expect(_key('draft_rules'), findsNothing);
  expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  for (final key in [
    'draft_reset',
    'draft_role_seeker',
    'draft_role_guardian',
  ]) {
    expect(_key(key), findsOneWidget);
  }
  expect(_key('draft_fill'), findsNothing);
}

void _inventory(
  WidgetTester tester, {
  bool browse = false,
  bool journey = false,
  bool myZyra = false,
  bool guardian = false,
  bool profile = false,
  bool seeker = true,
  bool compatibility = false,
  bool requests = false,
}) {
  expect(_motionPicker, browse ? findsOneWidget : findsNothing);
  expect(_iconPicker, findsNothing);
  expect(find.text('Journey icon'), findsNothing);
  for (final count in [0, 1, 5]) {
    expect(
      _key('draft_compatibility_unlock_$count'),
      browse || compatibility ? findsOneWidget : findsNothing,
    );
  }
  for (final count in [1, 2, 3]) {
    expect(
      _key('concept_journey_preview_$count'),
      journey ? findsOneWidget : findsNothing,
    );
  }
  expect(_key('draft_history'), myZyra ? findsOneWidget : findsNothing);
  for (final plan in ['basic', 'one']) {
    expect(
      _key('draft_membership_seeker_$plan'),
      profile && seeker ? findsOneWidget : findsNothing,
    );
  }
  for (final person in ['hassan', 'yusuf']) {
    for (final plan in [0, 1]) {
      expect(
        _key('concept_guardian_plan_draft-guardian-${person}_$plan'),
        guardian ? findsOneWidget : findsNothing,
      );
    }
  }
  for (final tab in [0, 1]) {
    expect(
      _key('concept_requests_controls_$tab'),
      requests ? findsOneWidget : findsNothing,
    );
  }
  expect(_key('concept_requests_controls_2'), findsNothing);
}

ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );

String _selectedPerson(WidgetTester tester) {
  final deck = _browse(tester);
  return deck.profiles[deck.selectedIndex].id;
}

ZyraRequestActivityPresentation _requests(WidgetTester tester) => tester
    .widget<ZyraRequestActivityPresentation>(_key('concept_activity_requests'));

Future<void> _openRequests(
  WidgetTester tester, {
  bool introductions = false,
}) async {
  await _nav(tester, 2);
  await _tap(
    tester,
    introductions
        ? 'my-zyra-route-concept-my-introductions'
        : 'my-zyra-route-concept-my-requests',
  );
  if (introductions) {
    expect(_key('concept_activity_requests'), findsNothing);
    final page = tester.widget<ZyraRequestActivityPresentation>(
      _key('concept_activity_introductions'),
    );
    expect(page.title, 'Introductions');
    expect(page.selectedIndex, 0);
    expect(page.pages, hasLength(1));
    expect(find.byType(PageView), findsNothing);
  } else {
    expect(_requests(tester).selectedIndex, 0);
  }
}

Future<void> _openCompatibility(WidgetTester tester) async {
  await _tap(tester, 'concept_browse_menu');
  await _nav(tester, 0);
  expect(find.byType(ZyraDraftCompatibilityPresentation), findsOneWidget);
}

VoidCallback _retainedButton(WidgetTester tester, String key) =>
    tester.widget<OutlinedButton>(_key(key)).onPressed!;

VoidCallback _retainedControlPress(WidgetTester tester, String key) {
  final callback = switch (tester.widget<Widget>(_key(key))) {
    IconButton(:final onPressed) => onPressed,
    ButtonStyleButton(:final onPressed) => onPressed,
    _ => null,
  };
  expect(callback, isNotNull, reason: '$key is an actual control button.');
  return callback!;
}

Future<void> _returnPage(WidgetTester tester) => returnZyraPreviewPage(tester);

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? priorNetwork;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMemberState;
  late List<Object?> beforeAppearance;
  late List<MethodCall> platformCalls;

  List<Object?> memberState() => [
    List.of(AppState.instance.saved),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
  ];
  List<Object?> appearance() => [
    ZyraColors.devPalette,
    ZyraAppGoldStyle.instance.enabled,
    ZyraText.appFont,
    ZyraInteractionStyle.hapticLevel,
  ];
  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };

  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    if (_captureDirectory.isNotEmpty) {
      if (!_captureDirectory.startsWith('/') ||
          !Directory(_captureDirectory).existsSync()) {
        throw StateError(
          'The capture directory must already exist and be absolute.',
        );
      }
      final reading = FontLoader(_font);
      for (final weight in ['ExtraLight', 'Regular', 'Medium']) {
        reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
      }
      await reading.load();
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'ordinary-member-preference': 'keep',
    });
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _captureDirectory.isEmpty ? null : _font;
    beforePreferences = preferenceState();
    beforeMemberState = memberState();
    beforeAppearance = appearance();
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    priorNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });

  tearDown(() {
    expect(network.attempts, 0);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMemberState);
    expect(appearance(), beforeAppearance);
    // Flutter window chrome and ordinary button click feedback do not write
    // member/native preferences. Keep a narrow rendering-only allowlist;
    // persistence, network and ordinary account/appearance state are checked
    // separately above and no other platform operation is permitted.
    expect(
      platformCalls.where((call) => !_isUiOnlyPlatformCall(call)),
      isEmpty,
    );
    HttpOverrides.global = priorNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (var tab = 0; tab < _seekerTitles.length; tab++) {
    testWidgets(
      'Seeker ${_seekerTitles[tab]} owns only its current page controls and closes to the same tab',
      (tester) async {
        await _mount(tester);
        if (tab != 0) await _nav(tester, tab);
        final person = tab == 0 ? _selectedPerson(tester) : null;
        await _toggleOptions(tester);
        _context(tester, _seekerTitles[tab]);
        _inventory(
          tester,
          browse: tab == 0,
          journey: tab == 1,
          myZyra: tab == 2,
          guardian: tab == 3,
          profile: tab == 4,
        );
        await _toggleOptions(tester);
        expect(_key('concept_page_options_context'), findsNothing);
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .currentIndex,
          tab,
        );
        if (person != null) expect(_selectedPerson(tester), person);
      },
    );
  }

  for (var tab = 0; tab < _guardianTitles.length; tab++) {
    testWidgets(
      'Guardian ${_guardianTitles[tab]} never inherits Seeker-only controls',
      (tester) async {
        await _mount(tester, guardian: true);
        if (tab != 0) await _nav(tester, tab);
        await _toggleOptions(tester);
        _context(tester, _guardianTitles[tab]);
        _inventory(tester, seeker: false, profile: tab == 3);
        await _toggleOptions(tester);
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .currentIndex,
          tab,
        );
      },
    );
  }

  testWidgets(
    'Journey count controls change the actual one, two and three-card reader',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 1);
      for (final count in [1, 2, 3]) {
        await _toggleOptions(tester);
        await _tap(tester, 'concept_journey_preview_$count');
        final page = tester.widget<ZyraOneJourneyConnectionsPresentation>(
          find.byType(ZyraOneJourneyConnectionsPresentation),
        );
        expect(
          page.pages.single.whereType<ZyraOneJourneyConnectionsActiveCard>(),
          hasLength(count),
        );
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .currentIndex,
          1,
        );
      }
    },
  );

  testWidgets(
    'My ZYRA keeps requests, Introductions and archive without duplicating active Journey cards',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 1);
      await _toggleOptions(tester);
      await _tap(tester, 'concept_journey_preview_3');
      await _nav(tester, 2);
      final dashboard = tester.widget<ZyraQuietDashboard>(
        find.byType(ZyraQuietDashboard),
      );
      expect(dashboard.singlePage, isTrue);
      expect(dashboard.permanentNavigation, isTrue);
      expect(find.text('Quick access'), findsOneWidget);
      final cards = [
        dashboard.resolution.answer.item,
        ...dashboard.resolution.otherActions,
        ...dashboard.resolution.recently,
        ...dashboard.resolution.intelligence,
      ].whereType<DashboardResolvedItem>();
      expect(
        cards.where(
          (item) => item.signal.id.startsWith('concept-current-journey-'),
        ),
        isEmpty,
      );
      expect(dashboard.fixtureCards.map((card) => card.id), [
        'concept-request-draft-amira',
        'concept-my-requests',
        'concept-my-introductions',
        'concept-my-ended',
      ]);
      expect(find.textContaining('Your Journey with'), findsNothing);
      expect(find.textContaining('Prepare your Journey with'), findsNothing);
      expect(find.textContaining('80%'), findsNothing);
      expect(dashboard.resolution.intelligence, isEmpty);
      for (final route in [
        'concept-my-requests',
        'concept-my-introductions',
        'concept-my-ended',
      ]) {
        expect(_key('my-zyra-route-$route'), findsOneWidget);
      }
      await _toggleOptions(tester);
      _inventory(tester, myZyra: true);
      await _tap(tester, 'draft_history');
      await _toggleOptions(tester);
      await _tap(tester, 'my-zyra-route-concept-my-ended');
      _expectEndedCard();
    },
  );

  testWidgets(
    'permanent Quick access cards use the whole row for their separate destinations',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 2);
      for (final destination in [
        (id: 'concept-my-requests', page: 'requests'),
        (id: 'concept-my-introductions', page: 'introductions'),
        (id: 'concept-my-ended', page: 'ended'),
      ]) {
        final target = _key('my-zyra-route-${destination.id}');
        await Scrollable.ensureVisible(tester.element(target), alignment: .5);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        final rect = tester.getRect(target);
        expect(rect.width, greaterThan(300));
        expect(rect.height, greaterThanOrEqualTo(98));
        expect(tester.widget<InkWell>(target).onTap, isNotNull);
        // Tap the row's leading padding rather than its title or chevron.
        await tester.tapAt(Offset(rect.left + 8, rect.center.dy));
        await tester.pumpAndSettle();
        expect(_key('concept_activity_${destination.page}'), findsOneWidget);
        await _returnPage(tester);
        expect(
          tester
              .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
              .permanentNavigation,
          isTrue,
        );
      }
    },
  );

  testWidgets(
    'Compatibility options preserve the covered person, reveal and route-local credits',
    (tester) async {
      await _mount(tester);
      final person = _selectedPerson(tester);
      await _openCompatibility(tester);
      final before = tester.widget<ZyraDraftCompatibilityPresentation>(
        find.byType(ZyraDraftCompatibilityPresentation),
      );
      await _toggleOptions(tester);
      _context(tester, 'Compatibility score');
      _inventory(tester, compatibility: true);
      await _tap(tester, 'draft_compatibility_unlock_5');
      await _toggleOptions(tester);
      final updated = tester.widget<ZyraDraftCompatibilityPresentation>(
        find.byType(ZyraDraftCompatibilityPresentation),
      );
      expect(updated.personName, before.personName);
      expect(updated.balance, 5);
      expect(updated.revealed, isFalse);
      await _tap(tester, 'draft_compatibility_reveal');
      await _toggleOptions(tester);
      await _tap(tester, 'draft_compatibility_unlock_1');
      await _toggleOptions(tester);
      final revealed = tester.widget<ZyraDraftCompatibilityPresentation>(
        find.byType(ZyraDraftCompatibilityPresentation),
      );
      expect(revealed.personName, before.personName);
      expect(revealed.balance, 1);
      expect(revealed.revealed, isTrue);
      await _returnPage(tester);
      expect(_selectedPerson(tester), person);
    },
  );

  testWidgets(
    'Requests options select only Received and Sent without creating records',
    (tester) async {
      await _mount(tester);
      await _openRequests(tester);
      final receivedIds = _requests(tester).pages[0]
          .whereType<ZyraRequestActivityCard>()
          .map((card) => card.profile.id)
          .toList();
      final sentIds = _requests(tester).pages[1]
          .whereType<ZyraRequestActivityCard>()
          .map((card) => card.profile.id)
          .toList();
      for (final index in [1, 0]) {
        final selectedIndex = _requests(tester).selectedIndex;
        await _toggleOptions(tester);
        _context(
          tester,
          'Journey requests · ${_requestsLabels[selectedIndex]}',
        );
        _inventory(tester, requests: true);
        await _tap(tester, 'concept_requests_controls_$index');
        _context(tester, 'Journey requests · ${_requestsLabels[index]}');
        await _toggleOptions(tester);
        expect(_requests(tester).selectedIndex, index);
        expect(_requests(tester).labels, _requestsLabels);
        expect(
          tester
              .widget<PageView>(_key('request_activity_pager'))
              .controller!
              .page,
          closeTo(index, .01),
        );
        expect(
          _requests(tester).pages[0]
              .whereType<ZyraRequestActivityCard>()
              .map((card) => card.profile.id)
              .toList(),
          receivedIds,
        );
        expect(
          _requests(tester).pages[1]
              .whereType<ZyraRequestActivityCard>()
              .map((card) => card.profile.id)
              .toList(),
          sentIds,
        );
        expect(_requests(tester).pages, hasLength(2));
        expect(_key('draft_requests_2'), findsNothing);
      }
    },
  );

  testWidgets(
    'standalone Introductions keeps its own route and has no request selector',
    (tester) async {
      await _mount(tester);
      await _openRequests(tester, introductions: true);
      final page = tester.widget<ZyraRequestActivityPresentation>(
        _key('concept_activity_introductions'),
      );
      expect(page.labels, ['Introductions']);
      expect(page.pages.single.whereType<ZyraRequestActivityCard>(), isEmpty);
      expect(
        page.pages.single.whereType<ZyraRequestActivityEmpty>().single.title,
        'No introductions yet',
      );
      expect(find.text('No introductions yet'), findsOneWidget);
      for (final index in [0, 1, 2]) {
        expect(_key('draft_requests_$index'), findsNothing);
      }
      await _toggleOptions(tester);
      _context(tester, 'Introductions');
      _inventory(tester);
      await _toggleOptions(tester);
      expect(_key('concept_activity_introductions'), findsOneWidget);
      await _returnPage(tester);
      final dashboard = tester.widget<ZyraQuietDashboard>(
        find.byType(ZyraQuietDashboard),
      );
      expect(dashboard.permanentNavigation, isTrue);
      for (final route in [
        'concept-my-requests',
        'concept-my-introductions',
        'concept-my-ended',
      ]) {
        expect(_key('my-zyra-route-$route'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Requests and Introductions retain their separate routes after Back and reset',
    (tester) async {
      await _mount(tester);
      await _openRequests(tester);
      await _tap(tester, 'draft_requests_1');
      final stale = _requests(tester).onChanged;
      await _returnPage(tester);
      await _tap(tester, 'my-zyra-route-concept-my-introductions');
      stale(0);
      stale(1);
      await tester.pumpAndSettle();
      expect(_key('concept_activity_requests'), findsNothing);
      expect(_key('concept_activity_introductions'), findsOneWidget);
      await _returnPage(tester);
      await _tap(tester, 'my-zyra-route-concept-my-requests');
      expect(_requests(tester).selectedIndex, 0);
      expect(_requests(tester).labels, _requestsLabels);
      await _toggleOptions(tester);
      await _tap(tester, 'draft_reset');
      expect(_key('concept_activity_requests'), findsNothing);
      await _openRequests(tester, introductions: true);
      expect(_key('concept_activity_introductions'), findsOneWidget);
      expect(find.text('No introductions yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Ended options add local archive history and return to the same archive',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 2);
      await _tap(tester, 'my-zyra-route-concept-my-ended');
      expect(find.text('No ended Journeys.'), findsOneWidget);
      await _toggleOptions(tester);
      _context(tester, 'Ended Journeys');
      _inventory(tester, myZyra: true);
      await _tap(tester, 'draft_history');
      await _toggleOptions(tester);
      _expectEndedCard();
      await _toggleOptions(tester);
      await _tap(tester, 'draft_history');
      await _toggleOptions(tester);
      _expectEndedCard();
      await _returnPage(tester);
      expect(find.byType(ZyraQuietDashboard), findsOneWidget);
    },
  );

  testWidgets(
    'Profile membership controls feed the current profile without altering member preferences',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 4);
      await _toggleOptions(tester);
      await _tap(tester, 'draft_membership_seeker_basic');
      await _toggleOptions(tester);
      expect(
        tester
            .widget<ZyraConceptProfilePresentation>(
              find.byType(ZyraConceptProfilePresentation),
            )
            .data
            .membership,
        'Seeker Basic',
      );
      await _toggleOptions(tester);
      await _tap(tester, 'draft_membership_seeker_one');
      await _toggleOptions(tester);
      expect(
        tester
            .widget<ZyraConceptProfilePresentation>(
              find.byType(ZyraConceptProfilePresentation),
            )
            .data
            .membership,
        'Seeker One',
      );
    },
  );

  for (final change in [
    'tab ABA',
    'role ABA',
    'account generation',
    'developer ABA',
  ]) {
    testWidgets(
      '$change refuses retained page-option credit, motion, close and Home callbacks',
      (tester) async {
        await _mount(tester);
        await _toggleOptions(tester);
        final staleCredit = _retainedButton(
          tester,
          'draft_compatibility_unlock_5',
        );
        final staleMotion = tester
            .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(
              _motionPicker,
            )
            .onChanged!;
        final staleClose = _retainedControlPress(tester, 'dev_controls_close');
        final staleHome = _retainedControlPress(tester, 'draft_close');
        if (change == 'tab ABA') {
          await _toggleOptions(tester);
          await _nav(tester, 2);
          await _nav(tester, 0);
          await _toggleOptions(tester);
        } else if (change == 'role ABA') {
          await _tap(tester, 'draft_role_guardian');
          await _toggleOptions(tester);
          await _tap(tester, 'draft_role_seeker');
          await _toggleOptions(tester);
        } else if (change == 'account generation') {
          ZyraAccountState.resetForTesting();
          ZyraAccountState.resetForTesting();
          AppState.instance.resetForAccountChange();
          await tester.pumpAndSettle();
        } else {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
          await tester.pumpAndSettle();
        }
        staleCredit();
        staleMotion(ZyraBrowseNextMotion.cardGlide);
        staleClose();
        staleHome();
        await tester.pumpAndSettle();
        if (change == 'tab ABA' || change == 'role ABA') {
          _context(tester, 'Profiles');
          expect(
            tester
                .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(
                  _motionPicker,
                )
                .initialValue,
            ZyraBrowseNextMotion.current,
          );
          await _toggleOptions(tester);
          await _openCompatibility(tester);
          expect(
            tester
                .widget<ZyraDraftCompatibilityPresentation>(
                  find.byType(ZyraDraftCompatibilityPresentation),
                )
                .balance,
            1,
          );
        } else {
          expect(find.text('Preview closed'), findsOneWidget);
          expect(_key('concept_page_options_context'), findsNothing);
        }
      },
    );
  }

  testWidgets(
    'retained close and Home controls cannot change a new leaf or dismiss a later editor',
    (tester) async {
      await _mount(tester);
      await openZyraDevControls(tester);
      final mainClose = _retainedControlPress(tester, 'dev_controls_close');
      final mainHome = _retainedControlPress(tester, 'draft_close');
      await closeZyraDevControls(tester);
      await _openCompatibility(tester);
      mainClose();
      mainHome();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraDraftCompatibilityPresentation), findsOneWidget);
      expect(_key('concept_page_options_context'), findsNothing);
      await openZyraDevControls(tester);
      _context(tester, 'Compatibility score');
      final compatibilityClose = _retainedControlPress(
        tester,
        'dev_controls_close',
      );
      final compatibilityHome = _retainedControlPress(tester, 'draft_close');
      await closeZyraDevControls(tester);
      await _returnPage(tester);
      await _nav(tester, 4);
      await _tap(tester, 'concept_edit_profile');
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.byType(ZyraDevControlRail), findsNothing);
      compatibilityClose();
      compatibilityHome();
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(_key('concept_page_options_context'), findsNothing);
      await _returnPage(tester);
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
    },
  );

  testWidgets(
    '200 percent Page options remain readable and every compact action is reachable',
    (tester) async {
      await _mount(tester, size: const Size(320, 568), scale: 2);
      for (var tab = 0; tab < _seekerTitles.length; tab++) {
        if (tab != 0) await _nav(tester, tab);
        await _toggleOptions(tester);
        _context(tester, _seekerTitles[tab]);
        final targets = [
          if (tab == 0) ...[
            _motionPicker,
            _key('draft_compatibility_unlock_5'),
          ],
          if (tab == 1) _key('concept_journey_preview_3'),
          if (tab == 2) _key('draft_history'),
          if (tab == 3) _key('concept_guardian_plan_draft-guardian-yusuf_1'),
          if (tab == 4) _key('draft_membership_seeker_one'),
          _key('draft_reset'),
          _key('draft_role_seeker'),
          _key('draft_role_guardian'),
        ];
        for (final target in targets) {
          expect(target, findsOneWidget);
          await Scrollable.ensureVisible(tester.element(target), alignment: .5);
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.getRect(target).left, greaterThanOrEqualTo(20));
          expect(tester.getRect(target).right, lessThanOrEqualTo(300));
          expect(tester.takeException(), isNull);
        }
        await _toggleOptions(tester);
      }
    },
  );

  if (_captureDirectory.isNotEmpty) {
    testWidgets(
      'capture the actual page-specific inventories and uncluttered My ZYRA',
      (tester) async {
        await _mount(tester);
        for (var tab = 0; tab < _seekerTitles.length; tab++) {
          if (tab != 0) await _nav(tester, tab);
          await _toggleOptions(tester);
          _context(tester, _seekerTitles[tab]);
          await _capture(tester, 'seeker-$tab-page-options');
          await _toggleOptions(tester);
        }
        await _nav(tester, 1);
        await _toggleOptions(tester);
        await _tap(tester, 'concept_journey_preview_3');
        await _nav(tester, 2);
        await _capture(tester, 'my-zyra-three-journeys-no-duplicates');
        await _toggleOptions(tester);
        await _tap(tester, 'draft_role_guardian');
        for (var tab = 0; tab < _guardianTitles.length; tab++) {
          if (tab != 0) await _nav(tester, tab);
          await _toggleOptions(tester);
          _context(tester, _guardianTitles[tab]);
          await _capture(tester, 'guardian-$tab-page-options');
          await _toggleOptions(tester);
        }
      },
    );
  }
}

bool _isUiOnlyPlatformCall(MethodCall call) {
  if (call.method == 'HapticFeedback.vibrate') return true;
  if (call.method == 'SystemSound.play') {
    return call.arguments == 'SystemSoundType.click';
  }
  if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
    final args = call.arguments;
    return args is Map &&
        args.keys.toSet().containsAll(['label', 'primaryColor']) &&
        args.length == 2 &&
        args['label'] is String &&
        args['primaryColor'] is int;
  }
  if (call.method == 'SystemChrome.setSystemUIOverlayStyle') {
    const fields = {
      'systemNavigationBarColor',
      'systemNavigationBarDividerColor',
      'systemStatusBarContrastEnforced',
      'statusBarColor',
      'statusBarBrightness',
      'statusBarIconBrightness',
      'systemNavigationBarIconBrightness',
      'systemNavigationBarContrastEnforced',
    };
    final args = call.arguments;
    return args is Map && args.keys.every(fields.contains);
  }
  return false;
}
