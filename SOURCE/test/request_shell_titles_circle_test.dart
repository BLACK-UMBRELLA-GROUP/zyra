// Actual protected-shell navigation, not isolated mock headings. Fixture
// transports are local and never establish member, chat or payment authority.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_circle_topics_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsRequestShellTitles';
const _top = 59.0;
const _captureDirectory = String.fromEnvironment(
  'ZYRA_REQUEST_SHELL_CAPTURE_DIRECTORY',
);
const _captureKey = ValueKey('request-shell-visual');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Request-shell headings and Circle must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _mount(
  WidgetTester tester, {
  bool seekerBasic = false,
  bool guardianBasic = false,
  Size size = const Size(393, 852),
  EdgeInsets safePadding = const EdgeInsets.only(top: _top, bottom: 34),
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
          padding: safePadding,
          viewPadding: safePadding,
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: ViewRequestDraftScreen(
        key: UniqueKey(),
        fixture: ZyraShellTestFixture().fixture,
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
        initialSeekerBasic: seekerBasic,
        initialGuardianBasic: guardianBasic,
      ),
    ),
  );
  await tester.pumpAndSettle();
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
    fail('The prepared local Browse deck did not publish.');
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
    await file.parent.create(recursive: true);
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _press(WidgetTester tester, Finder target) async {
  if (await pressZyraFixtureFinder(tester, target)) return;
  expect(target, findsOneWidget);
  final scrolls = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scrolls.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  final cell = _key('floating-nav-item-$index');
  expect(cell, findsOneWidget);
  // Decorative cells ignore pointers; the actual shared bar owns dispatch.
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

typedef _TitleMetrics = ({TextStyle style, double baseline});

_TitleMetrics _expectTitle(
  WidgetTester tester,
  String key,
  String label, {
  double safeTop = _top,
  _TitleMetrics? reference,
}) {
  final target = key.isEmpty ? find.text(label) : _key(key);
  expect(target, findsOneWidget);
  final title = tester.widget<Text>(target);
  final style = title.style!;
  expect(title.data, label);
  expect(title.textAlign, TextAlign.left, reason: label);
  expect(style.fontSize, 26, reason: label);
  expect(style.fontWeight, FontWeight.w200, reason: label);
  expect(style.fontFamily, _font, reason: label);
  final rect = tester.getRect(target);
  expect(rect.left, closeTo(20, .01), reason: label);
  expect(rect.top, closeTo(safeTop + 16, .01), reason: label);
  final paragraph = tester.renderObject<RenderParagraph>(target);
  final baseline =
      rect.top +
      paragraph.getDryBaseline(paragraph.constraints, TextBaseline.alphabetic)!;
  if (reference != null) {
    expect(style, reference.style, reason: label);
    expect(baseline, closeTo(reference.baseline, 1), reason: label);
  }
  return (style: style, baseline: baseline);
}

ZyraCircleTopicsPresentation _topics(WidgetTester tester) =>
    tester.widget(find.byType(ZyraCircleTopicsPresentation));

VoidCallback _send(WidgetTester tester) =>
    tester.widget<Semantics>(_key('circle_topics_send')).properties.onTap!;

Future<ZyraGuardianCircleScreen> _openCircle(
  WidgetTester tester, {
  bool guardian = false,
  bool seekerBasic = false,
}) async {
  await _nav(tester, 3);
  if (guardian) await _press(tester, _key('guardian_seeker_0'));
  await _press(
    tester,
    _key(guardian ? 'guardian_circle' : 'guardian-family-messages-top'),
  );
  final owner = find.byType(ZyraGuardianCircleScreen);
  expect(owner, findsOneWidget);
  final circle = tester.widget<ZyraGuardianCircleScreen>(owner);
  expect(circle.preview, isTrue);
  expect(circle.viewerIsSeeker, !guardian);
  expect(circle.seekerId, 'draft-self');
  expect(circle.seekerFirstName, 'Adam');
  expect(
    circle.previewData!.validFor('draft-self', viewerIsSeeker: !guardian),
    isTrue,
  );
  expect(
    circle.previewData!.senderId,
    guardian ? 'draft-guardian-hassan' : 'draft-self',
  );
  expect(circle.previewData!.participants.map((person) => person.firstName), [
    'Adam',
    'Hassan',
    if (!seekerBasic) 'Yusuf',
  ]);
  expect(find.text('Guardian Circle'), findsOneWidget);
  expect(find.text('Abdul'), findsNothing);
  return circle;
}

Future<void> _closeCircle(WidgetTester tester, {bool guardian = false}) async {
  expect(_key('zyra_visible_back_button'), findsNothing);
  expect(_key('zyra_back_swipe_edge'), findsOneWidget);
  await returnZyraPreviewPage(tester);
  expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
  if (guardian) {
    expect(_key('guardian_circle'), findsOneWidget);
  } else {
    _expectTitle(tester, 'guardian-manager-title', 'Guardian');
    expect(_key('guardian-family-messages-top'), findsOneWidget);
    expect(find.byType(ZyraShellNavigation), findsOneWidget);
  }
}

Finder _iconDropdown() => find.byWidgetPredicate(
  (widget) => widget is DropdownButtonFormField<ZyraJourneyIconDesign>,
);

ZyraJourneyIconPainter _journeyPainter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: _key('floating-nav-item-1'),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((widget) => widget.painter)
    .whereType<ZyraJourneyIconPainter>()
    .single;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;

  setUpAll(() async {
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    HttpOverrides.global = previousNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    expect(network.attempts, 0);
  });

  testWidgets(
    'all five actual tabs in each role share title style and position at both phone sizes',
    (tester) async {
      const seekerTabs = [
        ('concept_browse_title', 'Profiles'),
        ('', 'Journey'),
        ('', 'My ZYRA'),
        ('guardian-manager-title', 'Guardian'),
        ('concept_profile_title', 'Profile'),
      ];
      const guardianTabs = [
        ('', 'Network'),
        ('', 'Journeys'),
        ('', 'My ZYRA'),
        ('', 'Seekers'),
        ('concept_profile_title', 'Profile'),
      ];
      for (final (size, safePadding) in const [
        (Size(430, 932), EdgeInsets.only(top: 59, bottom: 34)),
        (Size(375, 667), EdgeInsets.only(top: 20)),
      ]) {
        await _mount(tester, size: size, safePadding: safePadding);
        final reference = _expectTitle(
          tester,
          'concept_browse_title',
          'Profiles',
          safeTop: safePadding.top,
        );
        final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
        for (final (role, tabs) in [
          ('seeker', seekerTabs),
          ('guardian', guardianTabs),
        ]) {
          if (role == 'guardian') {
            await _press(tester, _key('draft_role_guardian'));
          }
          for (final (index, (key, label)) in tabs.indexed) {
            if (role == 'guardian' || index > 0) await _nav(tester, index);
            _expectTitle(
              tester,
              key,
              label,
              safeTop: safePadding.top,
              reference: reference,
            );
            await _capture(tester, '$dimensions-$role-tab-$index');
          }
        }
      }
    },
  );

  for (final count in [1, 2, 3]) {
    // Q34: seed only the count; both titles come from the current Journey tab.
    testWidgets(
      '$count occupied Journeys keep the same title as the empty tab',
      (tester) async {
        await _mount(tester);
        final reference = _expectTitle(
          tester,
          'concept_browse_title',
          'Profiles',
        );
        await _nav(tester, 1);
        _expectTitle(tester, '', 'Journey', reference: reference);
        await openZyraDevControls(tester);
        await _press(tester, _key('concept_journey_preview_$count'));
        expect(
          tester
              .widget<ZyraOneJourneyTab>(find.byType(ZyraOneJourneyTab))
              .journeys,
          hasLength(count),
        );
        _expectTitle(tester, '', 'Journey', reference: reference);
      },
    );
  }

  // Q34: send through the real LOCK 20 Topics composer.
  testWidgets(
    'Guardian Circle reuses its working preview, sends locally and returns by edge swipe',
    (tester) async {
      await _mount(tester);
      final circle = await _openCircle(tester);
      expect(_key('zyra_visible_back_button'), findsNothing);
      expect(circle.previewData!.canSend, isTrue);
      await _capture(tester, 'guardian-circle');
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Assalaamu alaikum. Let’s discuss the journey together.'),
        findsOneWidget,
      );
      const body = 'A local Circle message from the current Seeker';
      await tester.enterText(find.byType(TextField), body);
      await _press(tester, _key('circle_topics_send'));
      expect(find.text(body), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        circle.previewData!.messages.any((message) => message.body == body),
        isFalse,
      );
      await _closeCircle(tester);
    },
  );

  // Q34: example Topics are local and do not create a Journey.
  testWidgets(
    'empty request Circle has fictional Current names, not new Journeys',
    (tester) async {
      await _mount(tester);
      final circle = await _openCircle(tester);
      expect(circle.previewData!.contexts, isEmpty);
      expect(circle.previewCurrentTopics.map((topic) => topic.firstName), [
        'Sara',
        'Aisha',
        'Maryam',
      ]);
      expect(_topics(tester).current, isEmpty);
      for (final name in ['Sara', 'Aisha', 'Maryam']) {
        expect(find.text(name), findsNothing);
      }
      await _capture(tester, 'circle-current-examples');
      const body = 'A general message in the empty Circle';
      await tester.enterText(_key('circle_topics_composer'), body);
      await _press(tester, _key('circle_topics_send'));
      expect(
        _topics(tester).messages.map((item) => item.message.body),
        contains(body),
      );
      await _closeCircle(tester);
      await _nav(tester, 1);
      expect(
        tester
            .widget<ZyraOneJourneyTab>(find.byType(ZyraOneJourneyTab))
            .journeys,
        isEmpty,
      );
    },
  );

  // Q34: edge dismissal returns to the actual LOCK 19 Guardian root.
  testWidgets(
    'Guardian Circle returns to its Guardian owner with the shared interactive left-edge gesture',
    (tester) async {
      await _mount(tester);
      await _openCircle(tester);
      expect(_key('zyra_visible_back_button'), findsNothing);
      final edge = _key('zyra_back_swipe_edge');
      expect(edge, findsOneWidget);
      final rect = tester.getRect(edge);
      await tester.timedDragFrom(
        Offset(rect.left + 8, rect.top + rect.height * .35),
        const Offset(180, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
      _expectTitle(tester, 'guardian-manager-title', 'Guardian');
      expect(_key('guardian-family-messages-top'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final role in ['seeker', 'guardian_one', 'guardian_basic']) {
    // Q34 and Q6: writing follows the viewer, never another participant.
    testWidgets('LOCK 20 Circle writing follows $role', (tester) async {
      final guardian = role.startsWith('guardian');
      final canSend = role != 'guardian_basic';
      await _mount(tester, seekerBasic: !guardian, guardianBasic: !canSend);
      if (guardian) {
        await _nav(tester, 4);
        await _press(tester, _key('draft_role_guardian'));
      }
      final circle = await _openCircle(
        tester,
        guardian: guardian,
        seekerBasic: !guardian,
      );
      expect(circle.previewData!.canSend, canSend);
      expect(_topics(tester).canCompose, canSend);
      expect(
        _key('circle_topics_composer'),
        canSend ? findsOneWidget : findsNothing,
      );
      expect(
        _key('circle_topics_send'),
        canSend ? findsOneWidget : findsNothing,
      );
      if (!canSend) {
        expect(find.textContaining("You're reading only"), findsOneWidget);
      }
      expect(_topics(tester).messages, isNotEmpty);
      await _closeCircle(tester, guardian: guardian);
    });
  }

  // Q34 (R2): changing viewing role invalidates the captured Seeker send.
  testWidgets('LOCK 20 refuses a send captured before the role switched', (
    tester,
  ) async {
    await _mount(tester);
    await _openCircle(tester);
    const body = 'A draft left with the previous Circle viewer';
    await tester.enterText(_key('circle_topics_composer'), body);
    final staleSend = _send(tester);
    await _closeCircle(tester);
    await _nav(tester, 4);
    await _press(tester, _key('draft_role_guardian'));
    await _openCircle(tester, guardian: true);
    final before = _topics(tester).messages.length;
    staleSend();
    await tester.pumpAndSettle();
    expect(_topics(tester).messages, hasLength(before));
    expect(find.text(body), findsNothing);
  });

  // Q34 (R2): revoke the real Topics send and Circle return delegates.
  testWidgets(
    'revocation followed by restored authorization cannot publish a delayed Circle send',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 3);
      final openingButton = tester.widget<IconButton>(
        _key('guardian-family-messages-top'),
      );
      final retainedOpen = openingButton.onPressed!;
      await _press(tester, _key('guardian-family-messages-top'));
      expect(find.byType(ZyraGuardianCircleScreen), findsOneWidget);
      final send = _send(tester);
      final back = tester
          .widget<ZyraPullDownBackScope>(_key('concept_pull_down_back_scope'))
          .onBack;
      const body = 'Must not survive revoked Circle ownership';
      await tester.enterText(find.byType(TextField), body);
      send();
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      retainedOpen();
      send();
      back();
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(body), findsNothing);
      expect(find.text('Guardian Circle'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  // Q34 (R2): returning to the same account ID does not revive a send.
  testWidgets(
    'account A to B to A withdraws the Circle and retained local send',
    (tester) async {
      await tester.runAsync(
        () => ZyraAccountState.synchronize('circle-fixture-a'),
      );
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await _mount(tester);
      await _openCircle(tester);
      final send = _send(tester);
      const body = 'Must not return when the original account ID returns';
      await tester.enterText(find.byType(TextField), body);
      send();
      await tester.runAsync(
        () => ZyraAccountState.synchronize('circle-fixture-b'),
      );
      await tester.runAsync(
        () => ZyraAccountState.synchronize('circle-fixture-a'),
      );
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      send();
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(ZyraAccountState.userId, 'circle-fixture-a');
      expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(body), findsNothing);
      expect(find.text('Guardian Circle'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all Seeker page controls omit icon comparisons and retain canonical Couple navigation',
    (tester) async {
      await _mount(tester);
      for (final tab in [0, 1, 2, 3, 4]) {
        if (tab != 0) await _nav(tester, tab);
        expect(_journeyPainter(tester).design, ZyraJourneyIconDesign.couple);
        await toggleZyraDevControls(tester);
        expect(_iconDropdown(), findsNothing);
        expect(find.text('Journey icon'), findsNothing);
        await toggleZyraDevControls(tester);
        expect(_journeyPainter(tester).design, ZyraJourneyIconDesign.couple);
      }
      await toggleZyraDevControls(tester);
      await _press(tester, _key('draft_reset'));
      expect(_journeyPainter(tester).design, ZyraJourneyIconDesign.couple);
    },
  );

  testWidgets(
    'developer revocation closes the shell rather than restoring old icon choices',
    (tester) async {
      await _mount(tester);
      await toggleZyraDevControls(tester);
      expect(_iconDropdown(), findsNothing);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpAndSettle();
      expect(find.text('Preview closed'), findsOneWidget);
      expect(_iconDropdown(), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'replacing the Circle owner guard denies instead of adopting it',
    (tester) async {
      await _mount(tester);
      final existing = await _openCircle(tester);
      final data = existing.previewData!;
      bool admitted() => true;
      bool denied() => false;
      Widget circle(bool Function() guard) => MaterialApp(
        home: ZyraGuardianCircleScreen(
          key: const ValueKey('guard-replacement-circle'),
          seekerId: data.seekerId,
          seekerFirstName: 'Adam',
          viewerIsSeeker: true,
          preview: true,
          previewData: data,
          canAct: guard,
        ),
      );
      await tester.pumpWidget(circle(admitted));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpWidget(circle(denied));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(circle(admitted));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('legacy supplied Circle canSend false remains read-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraGuardianCircleScreen(
          seekerId: 'draft-self',
          seekerFirstName: 'Adam',
          viewerIsSeeker: true,
          preview: true,
          initialCircle: ZyraGuardianCircleSummary(
            threadId: 'preview-thread',
            seekerId: 'draft-self',
            seekerFirstName: 'Adam',
            participantCount: 3,
            lastMessage: null,
            lastMessageAt: null,
            unreadCount: 0,
            canSend: false,
            muted: false,
            access: ZyraFamilyMessageAccess.ready,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Guardian Circle'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
