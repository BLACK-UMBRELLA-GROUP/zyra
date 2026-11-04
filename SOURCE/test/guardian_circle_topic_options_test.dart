// Detached, caller-owned Circle discussion examples. These tests do not
// establish a member link, history consent, messaging or payment authority.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/dev/zyra_circle_send_button_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsCircleTopicOptions';
const _captureDirectory = String.fromEnvironment(
  'ZYRA_CIRCLE_TOPIC_CAPTURE_DIR',
);
const _captureKey = ValueKey('circle-topic-options-capture');
const _controlStyles = ZyraCircleBubbleDesign.values;
const _newDesigns = ZyraCircleBubbleDesign.values;
const _currentContexts = [
  ZyraFamilyMessageContext(
    referenceId: 'draft-sara',
    firstName: 'Sara',
    kind: ZyraFamilyMessageContextKind.active,
  ),
  ZyraFamilyMessageContext(
    referenceId: 'draft-aisha',
    firstName: 'Aisha',
    kind: ZyraFamilyMessageContextKind.active,
  ),
  ZyraFamilyMessageContext(
    referenceId: 'draft-maryam',
    firstName: 'Maryam',
    kind: ZyraFamilyMessageContextKind.active,
  ),
];

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _messageTags => find.descendant(
  of: find.byType(ListView),
  matching: find.byType(ZyraCircleTopicTag),
);
Finder _messageTag(String id) => find.descendant(
  of: find.byType(ListView),
  matching: _key('circle_topic_tag_$id'),
);
Finder get _composer => find.descendant(
  of: _key('guardian-circle-composer'),
  matching: find.byType(TextField),
);
Finder _circleButton(String tooltip) => find.descendant(
  of: find.byType(ZyraGuardianCircleScreen),
  matching: tooltip == 'Send message'
      ? find.byType(ZyraCircleSendButton)
      : find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == tooltip,
        ),
);

void _expectFloatingTranscript(WidgetTester tester) {
  final viewport = tester.getRect(_key('circle_transcript_viewport'));
  final transcript = find.descendant(
    of: _key('circle_transcript_viewport'),
    matching: find.byType(ListView),
  );
  final launcher = tester.getRect(_key('circle_discuss_floatingButton'));
  expect(tester.getRect(transcript), viewport);
  expect(
    tester.widget<ListView>(transcript).padding,
    const EdgeInsets.fromLTRB(20, 12, 20, 82),
  );
  expect(launcher.top, greaterThanOrEqualTo(viewport.top));
  expect(launcher.bottom, lessThanOrEqualTo(viewport.bottom));
  expect(launcher.overlaps(viewport), isTrue);
  expect(launcher.overlaps(tester.getRect(_composer)), isFalse);
  expect(
    launcher.overlaps(tester.getRect(_circleButton('Send message'))),
    isFalse,
  );
}

void _expectDockedTranscript(WidgetTester tester) {
  final transcript = find.descendant(
    of: _key('circle_transcript_viewport'),
    matching: find.byType(ListView),
  );
  expect(
    tester.getRect(transcript),
    tester.getRect(_key('circle_transcript_viewport')),
  );
  expect(
    tester.widget<ListView>(transcript).padding,
    const EdgeInsets.fromLTRB(20, 12, 20, 18),
  );
  final launcher = tester.getRect(_key('circle_discuss_floatingButton'));
  expect(
    launcher.overlaps(tester.getRect(_key('guardian-circle-composer'))),
    isTrue,
  );
  expect(launcher.overlaps(tester.getRect(_composer)), isFalse);
  expect(
    launcher.overlaps(tester.getRect(_circleButton('Send message'))),
    isFalse,
  );
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Circle topic comparisons must remain offline.');
  }
}

class _Fixture {
  _Fixture({
    ZyraCircleBubbleDesign mode = ZyraCircleBubbleDesign.current,
    this.withOptions = true,
    bool canSend = true,
    this.guardian = false,
    List<ZyraFamilyMessage>? suppliedMessages,
    List<ZyraCircleDiscussionTopic>? pastTopics,
  }) : design = ValueNotifier(mode),
       past =
           pastTopics ??
           [
             for (var index = 0; index < 12; index++)
               ZyraCircleDiscussionTopic(
                 id: 'draft-circle-past-$index',
                 firstName: index == 11
                     ? 'Yasmin A Long But Clearly Labelled Past Journey'
                     : const [
                         'Elif',
                         'Noor',
                         'Hafsa',
                         'Zainab',
                         'Huda',
                         'Safiya',
                         'Mariam',
                         'Amina',
                         'Khadija',
                         'Sumayya',
                         'Layla',
                       ][index],
                 kind: ZyraCircleTopicKind.past,
                 endedOn: DateTime.utc(
                   2026,
                   10,
                   10,
                 ).subtract(Duration(days: index * 15)),
               ),
           ] {
    data = ZyraGuardianCirclePreviewData(
      seekerId: 'draft-self',
      senderId: guardian ? 'draft-guardian-hassan' : 'draft-self',
      canSend: canSend,
      participants: [
        ZyraFamilyCircleParticipant(
          userId: 'draft-self',
          firstName: 'Adam',
          memberRole: 'seeker',
          isMainGuardian: false,
          isCurrentUser: !guardian,
        ),
        ZyraFamilyCircleParticipant(
          userId: 'draft-guardian-hassan',
          firstName: 'Hassan',
          memberRole: 'guardian',
          isMainGuardian: true,
          isCurrentUser: guardian,
        ),
        const ZyraFamilyCircleParticipant(
          userId: 'draft-guardian-yusuf',
          firstName: 'Yusuf',
          memberRole: 'guardian',
          isMainGuardian: false,
          isCurrentUser: false,
        ),
      ],
      messages:
          suppliedMessages ??
          [
            ZyraFamilyMessage(
              id: 'draft-circle-welcome',
              senderId: 'draft-guardian-hassan',
              senderFirstName: 'Hassan',
              senderRoleLabel: 'Main Guardian',
              body: 'We are here to support your Journey.',
              createdAt: DateTime.utc(2026, 10, 12, 9),
            ),
          ],
      contexts: _currentContexts,
    );
  }

  final bool guardian;
  final ValueNotifier<ZyraCircleBubbleDesign> design;
  bool withOptions;
  final ValueNotifier<bool> visibility = ValueNotifier(true);
  final List<ZyraCircleDiscussionTopic> past;
  late final ZyraGuardianCirclePreviewData data;
  bool owner = true;
  int contextOpens = 0;
  bool _ownerCurrent() => owner;
  bool _foregroundCurrent() => visibility.value;
  late final bool Function() ownerGuard = _ownerCurrent;
  late final bool Function() foregroundGuard = _foregroundCurrent;
  void setForeground(bool visible) => visibility.value = visible;
  void _contextOpened(ZyraFamilyMessageContext _) {
    contextOpens++;
  }

  late final ValueChanged<ZyraFamilyMessageContext> openContext =
      _contextOpened;

  ZyraGuardianCircleScreen screen({
    bool preview = true,
    ZyraGuardianCirclePreviewData? replacementData,
    bool Function()? replacementGuard,
    bool Function()? replacementForeground,
    ValueListenable<bool>? replacementVisibility,
    ValueListenable<ZyraCircleBubbleDesign>? replacementDesign,
    List<ZyraCircleDiscussionTopic>? replacementPast,
    bool? viewerIsSeeker,
    String seekerId = 'draft-self',
  }) => ZyraGuardianCircleScreen(
    key: const ValueKey('controlled-circle-owner'),
    seekerId: seekerId,
    seekerFirstName: 'Adam',
    viewerIsSeeker: viewerIsSeeker ?? !guardian,
    preview: preview,
    previewData: replacementData ?? data,
    previewBubbleDesign: withOptions ? replacementDesign ?? design : null,
    previewPastTopics: replacementPast ?? past,
    previewForeground: replacementForeground ?? foregroundGuard,
    previewVisibility: replacementVisibility ?? visibility,
    canAct: replacementGuard ?? ownerGuard,
    onOpenContext: openContext,
  );
}

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark().copyWith(
    textTheme: ThemeData.dark().textTheme.apply(fontFamily: _font),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      textScaler: TextScaler.linear(scale),
      disableAnimations: true,
    ),
    child: RepaintBoundary(key: _captureKey, child: child!),
  ),
  home: child,
);

Future<void> _mount(
  WidgetTester tester,
  _Fixture fixture, {
  double scale = 1,
  Size size = const Size(393, 852),
  Widget? screen,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(fixture.design.dispose);
  addTearDown(fixture.visibility.dispose);
  expect(
    fixture.data.validFor('draft-self', viewerIsSeeker: !fixture.guardian),
    isTrue,
  );
  await tester.pumpWidget(_app(screen ?? fixture.screen(), scale: scale));
  await tester.pumpAndSettle();
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

Future<void> _openPicker(WidgetTester tester) async {
  expect(_key('circle_topic_entry'), findsNothing);
  await _press(tester, find.byType(ZyraCircleDiscussLauncher));
  expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
  expect(_key('circle_picker_floating_surface'), findsOneWidget);
  expect(_key('circle_topic_general'), findsNothing);
  expect(find.text('General conversation'), findsNothing);
}

Future<void> _select(
  WidgetTester tester,
  String id, {
  bool past = false,
}) async {
  if (find.byType(ZyraCircleTopicPicker).evaluate().isEmpty) {
    await _openPicker(tester);
  }
  await _press(tester, _key('circle_topic_tab_${past ? 1 : 0}'));
  expect(_key('circle_topic_general'), findsNothing);
  expect(find.text('General conversation'), findsNothing);
  final row = _key('circle_topic_$id');
  if (row.evaluate().isEmpty) {
    // The compact floating viewport deliberately virtualizes list rows.
    // Reach the requested real row, not an assumed eager child.
    await tester.scrollUntilVisible(
      row,
      48,
      scrollable: find
          .descendant(
            of: find.byType(ZyraCircleTopicPicker),
            matching: find.byType(Scrollable),
          )
          .last,
    );
  }
  await _press(tester, row);
  expect(find.byType(ZyraCircleTopicPicker), findsNothing);
  expect(_key('circle_pending_discussion_topic'), findsOneWidget);
  expect(_key('circle_pending_discussion_topic_$id'), findsOneWidget);
}

Future<void> _dismissAndRemovePending(WidgetTester tester) async {
  if (find.byType(ZyraCircleTopicPicker).evaluate().isEmpty) {
    await _openPicker(tester);
  }
  expect(_key('circle_topic_general'), findsNothing);
  expect(find.text('General conversation'), findsNothing);
  await _press(tester, _key('circle_topic_picker_close'));
  expect(find.byType(ZyraCircleTopicPicker), findsNothing);
  if (_key('circle_pending_discussion_topic').evaluate().isNotEmpty) {
    await _press(tester, _key('circle_remove_pending_discussion_topic'));
  }
  expect(_key('circle_pending_discussion_topic'), findsNothing);
}

Future<void> _send(WidgetTester tester, String body) async {
  expect(_composer, findsOneWidget);
  await tester.enterText(_composer, body);
  await _press(tester, _circleButton('Send message'));
  expect(find.text(body), findsOneWidget);
  expect(tester.widget<TextField>(_composer).controller!.text, isEmpty);
  expect(_key('circle_pending_discussion_topic'), findsNothing);
  for (final launcher in tester.widgetList<ZyraCircleDiscussLauncher>(
    find.byType(ZyraCircleDiscussLauncher),
  )) {
    expect(launcher.topic.isGeneral, isTrue);
  }
}

VoidCallback _rowCallback(WidgetTester tester, String key) => tester
    .widget<InkWell>(
      find.descendant(of: _key(key), matching: find.byType(InkWell)),
    )
    .onTap!;

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
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

Future<void> _mountShell(
  WidgetTester tester, {
  bool guardian = false,
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      ViewRequestDraftScreen(
        fixture: ZyraShellTestFixture().fixture,
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
        initialGuardianRole: guardian,
        onExit: () => fail('Circle Page options must not exit its owner.'),
      ),
      scale: scale,
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
      fail('The bundled offline Browse deck did not prepare.');
    });
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

Future<void> _closeShellCircle(WidgetTester tester) async {
  expect(_circleButton('Back'), findsNothing);
  expect(_key('zyra_visible_back_button'), findsNothing);
  expect(_key('zyra_back_swipe_edge'), findsOneWidget);
  await returnZyraPreviewPage(tester);
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final nav = find.byType(FloatingNavBar);
  final cell = _key('floating-nav-item-$index');
  expect(nav, findsOneWidget);
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

Future<void> _chooseShellDesign(
  WidgetTester tester,
  ZyraCircleBubbleDesign style, {
  String pageTitle = 'Guardian Circle',
  bool returnsToCircle = true,
  String? menuCapture,
}) async {
  await toggleZyraDevControls(tester);
  expect(find.text('Page options'), findsOneWidget);
  expect(_key('concept_page_options_context'), findsOneWidget);
  final contextTitle = tester.widget<Text>(
    _key('concept_page_options_context'),
  );
  expect(contextTitle.data, contains(pageTitle));
  final dropdown = find.byType(DropdownButtonFormField<ZyraCircleBubbleDesign>);
  expect(dropdown, findsOneWidget);
  expect(find.text('Journey picker style'), findsNothing);
  expect(find.text('Floating bubble action'), findsOneWidget);
  expect(_key('concept_circle_send_design'), findsNothing);
  expect(find.text('Send button'), findsNothing);
  final choices = tester.widget<DropdownButton<ZyraCircleBubbleDesign>>(
    find.descendant(
      of: dropdown,
      matching: find.byType(DropdownButton<ZyraCircleBubbleDesign>),
    ),
  );
  expect(
    choices.items!.map((item) => item.value),
    ZyraCircleBubbleDesign.values,
  );
  if (menuCapture != null) await _capture(tester, menuCapture);
  await _press(tester, dropdown);
  final popup = find.byElementPredicate(
    (element) =>
        element.widget is Scrollable &&
        (ModalRoute.of(element)?.isCurrent ?? false),
  );
  expect(popup, findsOneWidget);
  final target = find.descendant(
    of: popup,
    matching: _key('concept_circle_bubble_design_${style.name}'),
  );
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 48, scrollable: popup);
  }
  expect(target, findsOneWidget);
  await _press(
    tester,
    find.ancestor(of: target, matching: find.byType(InkWell)).first,
  );
  expect(find.text('Page options'), findsOneWidget);
  await toggleZyraDevControls(tester);
  expect(find.text('Page options'), findsNothing);
  expect(
    find.byType(ZyraGuardianCircleScreen),
    returnsToCircle ? findsOneWidget : findsNothing,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMemberState;

  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  List<Object?> memberState() => [
    List.of(AppState.instance.saved),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
  ];

  setUpAll(() async {
    if (_captureDirectory.isNotEmpty &&
        (!_captureDirectory.startsWith('/') ||
            !Directory(_captureDirectory).existsSync())) {
      throw StateError(
        'Circle captures require an existing absolute directory.',
      );
    }
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
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
    ZyraText.testReadingFontFamily = _font;
    beforePreferences = preferenceState();
    beforeMemberState = memberState();
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    expect(network.attempts, 0);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMemberState);
    HttpOverrides.global = previousNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'interior comparisons preserve the actual scrolled transcript and editable selection',
    (tester) async {
      final fixture = _Fixture(
        suppliedMessages: [
          for (var index = 0; index < 24; index++)
            ZyraFamilyMessage(
              id: 'draft-circle-history-$index',
              senderId: 'draft-guardian-hassan',
              senderFirstName: 'Hassan',
              senderRoleLabel: 'Main Guardian',
              body:
                  'Existing Circle history number $index remains in this same conversation.',
              createdAt: DateTime.utc(2026, 10, 12, 9, index),
            ),
        ],
      );
      await _mount(tester, fixture);
      ScrollableState transcript() => tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final reader = transcript();
      reader.position.jumpTo(180);
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'My unsent Circle draft');
      final editor = tester.state<EditableTextState>(find.byType(EditableText));
      final controller = tester.widget<TextField>(_composer).controller!;
      controller.selection = const TextSelection(
        baseOffset: 3,
        extentOffset: 10,
      );
      for (final mode in [
        ZyraCircleBubbleDesign.current,
        ..._controlStyles,
        ZyraCircleBubbleDesign.current,
        ..._controlStyles.reversed,
      ]) {
        fixture.design.value = mode;
        await tester.pumpAndSettle();
        expect(transcript(), same(reader));
        expect(reader.position.pixels, closeTo(180, .01));
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(editor),
        );
        expect(controller.text, 'My unsent Circle draft');
        expect(
          controller.selection,
          const TextSelection(baseOffset: 3, extentOffset: 10),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final guardian in [false, true]) {
    for (final style in _controlStyles) {
      testWidgets(
        'discuss control ${style.name} for ${guardian ? 'Guardian' : 'Seeker'} preserves the same chat',
        (tester) async {
          final fixture = _Fixture(mode: style, guardian: guardian);
          await _mount(tester, fixture);
          final circle = find.byType(ZyraGuardianCircleScreen);
          final state = tester.state(circle);
          final controller = tester.widget<TextField>(_composer).controller!;
          await tester.enterText(_composer, 'My unsent Circle message');
          final launcher = _key('circle_discuss_floatingButton');
          expect(launcher.hitTestable(), findsOneWidget);
          expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));
          expect(tester.getSize(launcher).width, greaterThanOrEqualTo(44));
          expect(
            tester.getRect(launcher).overlaps(tester.getRect(_composer)),
            isFalse,
          );
          expect(
            tester
                .getRect(launcher)
                .overlaps(tester.getRect(_circleButton('Send message'))),
            isFalse,
          );
          _expectFloatingTranscript(tester);
          expect(_key('circle_topic_bar'), findsNothing);
          expect(_key('circle_topic_entry'), findsNothing);
          if (!guardian) await _capture(tester, 'control_${style.name}');
          await _select(tester, 'draft-sara');
          expect(tester.state(circle), same(state));
          expect(
            tester.widget<TextField>(_composer).controller,
            same(controller),
          );
          expect(controller.text, 'My unsent Circle message');
          expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
          expect(
            _key('circle_pending_discussion_topic_draft-sara'),
            findsOneWidget,
          );
          expect(_messageTags, findsNothing);
          await _select(tester, 'draft-circle-past-0', past: true);
          expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
          expect(_messageTags, findsNothing);
          await _send(tester, 'A message in the same Circle');
          expect(find.byType(ZyraCircleDiscussionBubble), findsOneWidget);
          expect(_messageTag('draft-circle-past-0'), findsOneWidget);
          expect(_messageTag('draft-sara'), findsNothing);
          expect(fixture.contextOpens, 0);
        },
      );
    }
  }

  for (final guardian in [false, true]) {
    for (final keyboard in [false, true]) {
      testWidgets(
        'floating transcript fills the viewport and clears the final receipt for ${guardian ? 'Guardian' : 'Seeker'} with keyboard ${keyboard ? 'open' : 'closed'}',
        (tester) async {
          final senderId = guardian ? 'draft-guardian-hassan' : 'draft-self';
          final otherId = guardian ? 'draft-self' : 'draft-guardian-hassan';
          final senderName = guardian ? 'Hassan' : 'Adam';
          final otherName = guardian ? 'Adam' : 'Hassan';
          final fixture = _Fixture(
            guardian: guardian,
            suppliedMessages: [
              for (var index = 0; index < 24; index++)
                ZyraFamilyMessage(
                  id: 'draft-float-history-$index',
                  senderId: index == 23 ? senderId : otherId,
                  senderFirstName: index == 23 ? senderName : otherName,
                  senderRoleLabel: 'Circle member',
                  body:
                      'Circle history $index remains in its original chronological position.',
                  createdAt: DateTime.utc(2026, 10, 22, 9, index),
                  unreadForMe: index == 0,
                ),
            ],
          );
          await _mount(tester, fixture);
          expect(_key('unread-messages-divider'), findsOneWidget);
          final list = find.byType(ListView);
          final reader = tester.state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          );
          final circle = tester.state(find.byType(ZyraGuardianCircleScreen));
          final editor = tester.state<EditableTextState>(
            find.byType(EditableText),
          );
          final controller = tester.widget<TextField>(_composer).controller!;
          controller.text = 'Keep this unsent Circle draft';
          controller.selection = const TextSelection(
            baseOffset: 5,
            extentOffset: 9,
          );
          reader.position.jumpTo(180);
          await tester.pumpAndSettle();
          if (keyboard) {
            await tester.showKeyboard(_composer);
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            addTearDown(tester.view.resetViewInsets);
            await tester.pumpAndSettle();
          }
          _expectFloatingTranscript(tester);
          expect(reader.position.pixels, closeTo(180, .01));
          expect(
            tester.state(find.byType(ZyraGuardianCircleScreen)),
            same(circle),
          );
          expect(
            tester.state<EditableTextState>(find.byType(EditableText)),
            same(editor),
          );
          expect(
            tester.widget<TextField>(_composer).controller,
            same(controller),
          );
          expect(controller.text, 'Keep this unsent Circle draft');
          expect(
            controller.selection,
            const TextSelection(baseOffset: 5, extentOffset: 9),
          );
          await _capture(
            tester,
            'floating_${guardian ? 'guardian' : 'seeker'}_${keyboard ? 'keyboard' : 'closed'}_middle',
          );
          // A lazy ListView revises its estimated end as rows are laid out.
          // Match the runtime's bounded end-settling policy, not one stale
          // maxScrollExtent estimate, and prove the real end was reached.
          final endMeasurements = <String>[];
          for (var frame = 0; frame < 4; frame++) {
            reader.position.jumpTo(reader.position.maxScrollExtent);
            await tester.pumpAndSettle();
            endMeasurements.add(
              '${reader.position.pixels}/${reader.position.maxScrollExtent}'
              '/${reader.position.extentAfter}',
            );
            if (reader.position.extentAfter.abs() < .01) break;
          }
          debugPrint('Circle floating end pixels/max/after: $endMeasurements');
          expect(reader.position.extentAfter, closeTo(0, .01));
          final finalMessage = _key('circle_message_draft-float-history-23');
          final receipt = _key('message-read-receipt');
          final launcher = tester.getRect(
            _key('circle_discuss_floatingButton'),
          );
          // The message owner spans the full row; its centre can be blank
          // beside a right-aligned bubble. Check the actual painted text.
          final finalBody = find.descendant(
            of: finalMessage,
            matching: find.text(
              'Circle history 23 remains in its original chronological position.',
            ),
          );
          expect(finalBody.hitTestable(), findsOneWidget);
          expect(receipt.hitTestable(), findsOneWidget);
          expect(tester.getRect(finalMessage).bottom, lessThan(launcher.top));
          expect(tester.getRect(receipt).bottom, lessThan(launcher.top));
          final messageSurface =
              tester
                      .widget<Container>(
                        find.descendant(
                          of: finalMessage,
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration!
                  as BoxDecoration;
          expect(messageSurface.color, ZyraColors.surfaceFill);
          expect(
            (messageSurface.border! as Border).top.color,
            ZyraColors.surfaceEmphasisBorder,
          );
          await _capture(
            tester,
            'floating_${guardian ? 'guardian' : 'seeker'}_${keyboard ? 'keyboard' : 'closed'}_end',
          );
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(_composer).controller,
            same(controller),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'empty Circle keeps its full viewport with an overlaid launcher for ${guardian ? 'Guardian' : 'Seeker'}',
      (tester) async {
        final fixture = _Fixture(
          guardian: guardian,
          suppliedMessages: const [],
        );
        await _mount(tester, fixture);
        final viewport = tester.getRect(_key('circle_transcript_viewport'));
        final emptyCenter = find
            .ancestor(
              of: find.text('Start the Guardian Circle'),
              matching: find.byType(Center),
            )
            .last;
        final launcher = tester.getRect(_key('circle_discuss_floatingButton'));
        expect(tester.getRect(emptyCenter), viewport);
        expect(find.byType(ListView), findsNothing);
        expect(launcher.overlaps(viewport), isTrue);
        expect(launcher.overlaps(tester.getRect(_composer)), isFalse);
        expect(
          _key('circle_discuss_floatingButton').hitTestable(),
          findsOneWidget,
        );
        await _capture(
          tester,
          'floating_${guardian ? 'guardian' : 'seeker'}_empty',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Circle member initials and own identity use quiet gold halos without pale fills',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _press(tester, _key('circle_header_members'));
      final sheet = find
          .ancestor(
            of: find.text('Circle members'),
            matching: find.byType(SafeArea),
          )
          .first;
      final avatars = find.descendant(
        of: sheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(avatars, findsNWidgets(3));
      for (final avatar in tester.widgetList<Container>(avatars)) {
        final decoration = avatar.decoration! as BoxDecoration;
        expect(decoration.color, ZyraColors.surfaceFill);
        expect(
          (decoration.border! as Border).top.color,
          ZyraColors.surfaceEmphasisBorder,
        );
      }
      final ownIdentity =
          tester
                  .widget<Container>(
                    find
                        .ancestor(
                          of: find.text('You'),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(ownIdentity.color, ZyraColors.surfaceFill);
      expect(
        (ownIdentity.border! as Border).top.color,
        ZyraColors.surfaceEmphasisBorder,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final style in _controlStyles) {
    testWidgets(
      'busy discuss control ${style.name} and retained chooser keep the pending message',
      (tester) async {
        final fixture = _Fixture(mode: style);
        await _mount(tester, fixture);
        await _select(tester, 'draft-sara');
        await tester.enterText(
          _composer,
          'A pending message keeps its Journey',
        );
        final launcher = _key('circle_discuss_floatingButton');
        final choose = tester
            .widget<ZyraCircleDiscussLauncher>(launcher)
            .onChoose!;
        await tester.tap(_circleButton('Send message'));
        await tester.pump(const Duration(milliseconds: 20));
        expect(
          tester.widget<ZyraCircleDiscussLauncher>(launcher).onChoose,
          isNull,
        );
        choose();
        await tester.pump(const Duration(milliseconds: 20));
        expect(find.byType(ZyraCircleTopicPicker), findsNothing);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(
          find.text('A pending message keeps its Journey'),
          findsOneWidget,
        );
        expect(_messageTag('draft-sara'), findsOneWidget);
        expect(tester.widget<TextField>(_composer).controller!.text, isEmpty);
        expect(
          tester.widget<ZyraCircleDiscussLauncher>(launcher).onChoose,
          isNotNull,
        );
        expect(fixture.contextOpens, 0);
      },
    );

    testWidgets(
      'embedded discuss control ${style.name} supports compact keyboard and long draft',
      (tester) async {
        await _mountShell(tester, size: const Size(320, 568), scale: 2);
        await _nav(tester, 1);
        await toggleZyraDevControls(tester);
        await _press(tester, _key('concept_journey_preview_3'));
        await _nav(tester, 3);
        await _press(tester, _key('guardian-family-messages-top'));
        await _chooseShellDesign(tester, style);
        expect(
          tester
              .widget<ZyraGuardianCircleScreen>(
                find.byType(ZyraGuardianCircleScreen),
              )
              .previewBubbleDesign!
              .value,
          style,
        );
        final launcher = _key('circle_discuss_floatingButton');
        await _capture(tester, 'embedded_control_${style.name}_initial');
        expect(launcher.hitTestable(), findsOneWidget);
        await tester.showKeyboard(_composer);
        tester.view.viewInsets = const FakeViewPadding(bottom: 200);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(
          _composer,
          List.filled(20, 'An unsent multi-line Circle message.').join('\n'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(launcher.hitTestable(), findsOneWidget);
        expect(_circleButton('Send message').hitTestable(), findsOneWidget);
        _expectDockedTranscript(tester);
        {
          expect(tester.getRect(launcher).right, lessThan(280));
        }
        final editable = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        expect(
          editable.size.height,
          greaterThanOrEqualTo(editable.preferredLineHeight),
        );
        await _capture(tester, 'embedded_control_${style.name}_keyboard');
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _openPicker(tester);
        await _dismissAndRemovePending(tester);
        expect(_composer, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'discuss control ${style.name} is absent for read-only access',
      (tester) async {
        final fixture = _Fixture(mode: style, canSend: false);
        await _mount(tester, fixture);
        expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
        expect(_composer, findsNothing);
        expect(_key('circle_topic_bar'), findsNothing);
      },
    );

    testWidgets(
      'discuss control ${style.name} fits compact double text and keyboard',
      (tester) async {
        final fixture = _Fixture(mode: style);
        await _mount(tester, fixture, size: const Size(320, 568), scale: 2);
        final launcher = _key('circle_discuss_floatingButton');
        expect(launcher.hitTestable(), findsOneWidget);
        await _capture(tester, 'control_${style.name}_compact');
        await tester.showKeyboard(_composer);
        tester.view.viewInsets = const FakeViewPadding(bottom: 200);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(launcher.hitTestable(), findsOneWidget);
        expect(_circleButton('Send message').hitTestable(), findsOneWidget);
        _expectDockedTranscript(tester);
        await tester.enterText(
          _composer,
          List.filled(20, 'An unsent multi-line Circle message.').join('\n'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_circleButton('Send message').hitTestable(), findsOneWidget);
        _expectDockedTranscript(tester);
        final editable = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        expect(
          editable.size.height,
          greaterThanOrEqualTo(editable.preferredLineHeight),
        );
        await _capture(tester, 'control_${style.name}_keyboard');
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _select(tester, 'draft-sara');
        expect(_key('circle_topic_bar'), findsNothing);
        expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
        expect(
          _key('circle_pending_discussion_topic_draft-sara'),
          findsOneWidget,
        );
      },
    );
  }

  for (final mode in _newDesigns) {
    testWidgets(
      '${mode.name} selects a Current topic and uses the one shared local chat',
      (tester) async {
        final fixture = _Fixture(mode: mode);
        await _mount(tester, fixture);
        expect(_key('circle_topic_entry'), findsNothing);
        await _capture(tester, '${mode.name}-initial');
        await _select(tester, 'draft-sara');
        expect(_key('circle_topic_entry'), findsNothing);
        expect(_key('circle_topic_bar'), findsNothing);
        expect(find.byType(ZyraCircleDiscussLauncher), findsOneWidget);
        expect(_composer, findsOneWidget);
        expect(
          find.text('We are here to support your Journey.'),
          findsOneWidget,
        );
        expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
        expect(_messageTags, findsNothing);
        await _send(tester, 'A local message about Sara in ${mode.name}');
        expect(find.byType(ZyraCircleDiscussionBubble), findsOneWidget);
        expect(_messageTag('draft-sara'), findsOneWidget);
        expect(_messageTags, findsOneWidget);
        expect(_key('open-message-context-draft-sara'), findsNothing);
        final tag = tester.widget<ZyraCircleTopicTag>(_messageTags);
        expect(tag.topic.kind, ZyraCircleTopicKind.current);
        expect(
          find.descendant(of: _messageTags, matching: find.byType(InkWell)),
          findsNothing,
        );
        expect(fixture.contextOpens, 0);
        expect(fixture.data.messages.length, 1);
        await _capture(tester, '${mode.name}-current-message');
      },
    );

    testWidgets(
      '${mode.name} Basic remains read-only despite topics and paid-looking participants',
      (tester) async {
        final fixture = _Fixture(mode: mode, canSend: false);
        await _mount(tester, fixture);
        expect(_composer, findsNothing);
        expect(_circleButton('Send message'), findsNothing);
        expect(_key('circle_topic_entry'), findsNothing);
        expect(find.byType(ZyraCircleTopicPicker), findsNothing);
        for (final bar in tester.widgetList<ZyraCircleDiscussLauncher>(
          find.byType(ZyraCircleDiscussLauncher),
        )) {
          expect(bar.onChoose, isNull);
        }
        expect(
          find.text('We are here to support your Journey.'),
          findsOneWidget,
        );
        expect(fixture.contextOpens, 0);
      },
    );
  }

  testWidgets(
    'the no-options Circle preserves its admitted legacy context contract',
    (tester) async {
      final fixture = _Fixture(withOptions: false);
      await _mount(tester, fixture);
      expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(
        tester.getRect(find.byType(ListView)),
        tester.getRect(_key('circle_transcript_viewport')),
      );
      expect(
        tester.widget<ListView>(find.byType(ListView)).padding,
        const EdgeInsets.fromLTRB(20, 12, 20, 18),
      );
      expect(_circleButton('Discuss someone'), findsOneWidget);
      await _send(tester, 'An untagged original Circle message');
      expect(find.byType(ZyraCircleTopicTag), findsNothing);
      expect(
        fixture.data.contexts.every(
          (topic) => topic.kind == ZyraFamilyMessageContextKind.active,
        ),
        isTrue,
      );
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'legacy pending person initials use the shared quiet halo without changing their context',
    (tester) async {
      final fixture = _Fixture(withOptions: false);
      await _mount(tester, fixture);
      await _press(tester, _circleButton('Discuss someone'));
      await _press(tester, find.text('Sara'));
      final context = _key('open-message-context-draft-sara');
      expect(context, findsOneWidget);
      final avatar =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: context,
                      matching: find.byWidgetPredicate(
                        (widget) =>
                            widget is Container &&
                            widget.decoration is BoxDecoration &&
                            (widget.decoration! as BoxDecoration).shape ==
                                BoxShape.circle,
                      ),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(avatar.color, ZyraColors.surfaceFill);
      expect(
        (avatar.border! as Border).top.color,
        ZyraColors.surfaceEmphasisBorder,
      );
      expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
      expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
      expect(fixture.contextOpens, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Past picker searches names and dates without opening old Journey routes',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _openPicker(tester);
      expect(_key('circle_topic_draft-sara'), findsOneWidget);
      expect(find.text('Potential'), findsNothing);
      expect(find.text('Paused'), findsNothing);
      await _press(tester, _key('circle_topic_tab_1'));
      expect(_key('circle_topic_draft-sara'), findsNothing);
      expect(find.text('10 Oct 2026'), findsOneWidget);
      expect(_key('circle_topic_general'), findsNothing);
      expect(find.text('General conversation'), findsNothing);
      expect(_key('circle_topic_search'), findsOneWidget);
      await _capture(tester, 'past-picker');
      await tester.enterText(_key('circle_topic_search'), '2026-10-10');
      await tester.pumpAndSettle();
      expect(_key('circle_topic_draft-circle-past-0'), findsOneWidget);
      expect(_key('circle_topic_draft-circle-past-1'), findsNothing);
      await tester.enterText(_key('circle_topic_search'), '10/10/2026');
      await tester.pumpAndSettle();
      expect(_key('circle_topic_draft-circle-past-0'), findsOneWidget);
      await tester.enterText(_key('circle_topic_search'), 'yasmin a long');
      await tester.pumpAndSettle();
      expect(_key('circle_topic_draft-circle-past-11'), findsOneWidget);
      expect(_key('circle_topic_draft-circle-past-0'), findsNothing);
      await _press(tester, _key('circle_topic_draft-circle-past-11'));
      await _send(tester, 'A detached discussion of a past Journey');
      expect(_messageTag('draft-circle-past-11'), findsOneWidget);
      expect(_key('open-message-context-draft-circle-past-11'), findsNothing);
      expect(fixture.contextOpens, 0);
      expect(fixture.data.contexts, _currentContexts);
      await _capture(tester, 'past-message');
    },
  );

  testWidgets(
    'pending Journey stays in the composer through cancellation and empty Send and can be removed without posting',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      final controller = tester.widget<TextField>(_composer).controller!;
      await tester.enterText(_composer, 'An unfinished Circle draft');
      await _select(tester, 'draft-sara');
      final removeSara = tester
          .widget<IconButton>(_key('circle_remove_pending_discussion_topic'))
          .onPressed!;
      expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
      expect(_messageTags, findsNothing);

      await _openPicker(tester);
      await _press(tester, _key('circle_topic_picker_close'));
      expect(
        _key('circle_pending_discussion_topic_draft-sara'),
        findsOneWidget,
      );
      expect(controller.text, 'An unfinished Circle draft');
      await _capture(tester, 'staged-topic-composer');

      await _select(tester, 'draft-aisha');
      removeSara();
      await tester.pumpAndSettle();
      expect(
        _key('circle_pending_discussion_topic_draft-aisha'),
        findsOneWidget,
      );
      expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
      await _press(tester, _key('circle_remove_pending_discussion_topic'));
      expect(_key('circle_pending_discussion_topic'), findsNothing);
      expect(controller.text, 'An unfinished Circle draft');
      expect(_messageTags, findsNothing);

      // Past catalogue entries reuse their exact object. An old A callback
      // cannot revive after selecting B and then that same canonical A.
      await _select(tester, 'draft-circle-past-0', past: true);
      final removePast = tester
          .widget<IconButton>(_key('circle_remove_pending_discussion_topic'))
          .onPressed!;
      await _select(tester, 'draft-sara');
      await _select(tester, 'draft-circle-past-0', past: true);
      removePast();
      await tester.pumpAndSettle();
      expect(
        _key('circle_pending_discussion_topic_draft-circle-past-0'),
        findsOneWidget,
      );
      await _press(tester, _key('circle_remove_pending_discussion_topic'));
      expect(_key('circle_pending_discussion_topic'), findsNothing);
      expect(controller.text, 'An unfinished Circle draft');
      expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);

      await _select(tester, 'draft-circle-past-0', past: true);
      await tester.enterText(_composer, '   ');
      await _press(tester, _circleButton('Send message'));
      expect(
        _key('circle_pending_discussion_topic_draft-circle-past-0'),
        findsOneWidget,
      );
      expect(controller.text, '   ');
      expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
      expect(_messageTags, findsNothing);
      expect(fixture.data.messages.length, 1);
      expect(fixture.contextOpens, 0);
    },
  );

  for (final change in ['visibility']) {
    testWidgets(
      'a pending send does not publish after a brief $change cover and return',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await _select(tester, 'draft-circle-past-0', past: true);
        final controller = tester.widget<TextField>(_composer).controller!;
        const body = 'Keep this pending discussion until a fresh Send';
        await tester.enterText(_composer, body);
        await tester.tap(_circleButton('Send message'));
        await tester.pump(const Duration(milliseconds: 20));
        fixture.setForeground(false);
        fixture.setForeground(true);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(controller.text, body);
        expect(
          _key('circle_pending_discussion_topic_draft-circle-past-0'),
          findsOneWidget,
        );
        expect(_messageTags, findsNothing);
        expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
        expect(
          find.descendant(of: find.byType(ListView), matching: find.text(body)),
          findsNothing,
        );
        expect(
          tester
              .widget<ZyraCircleSendButton>(_circleButton('Send message'))
              .onSend,
          isNotNull,
        );
        await _press(tester, _circleButton('Send message'));
        expect(controller.text, isEmpty);
        expect(_key('circle_pending_discussion_topic'), findsNothing);
        expect(_messageTag('draft-circle-past-0'), findsOneWidget);
        expect(find.byType(ZyraCircleDiscussionBubble), findsOneWidget);
        expect(fixture.contextOpens, 0);
      },
    );
  }

  testWidgets(
    'a captured pending Journey sends with the original body while busy removal is denied and a newer draft survives',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _select(tester, 'draft-sara');
      final controller = tester.widget<TextField>(_composer).controller!;
      await tester.enterText(_composer, 'The captured message about Sara');
      final remove = tester
          .widget<IconButton>(_key('circle_remove_pending_discussion_topic'))
          .onPressed!;
      await tester.tap(_circleButton('Send message'));
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        tester
            .widget<IconButton>(_key('circle_remove_pending_discussion_topic'))
            .onPressed,
        isNull,
      );
      remove();
      controller.text = 'A newer unsent Circle draft';
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('The captured message about Sara'), findsOneWidget);
      expect(_messageTag('draft-sara'), findsOneWidget);
      expect(find.byType(ZyraCircleDiscussionBubble), findsOneWidget);
      expect(_key('circle_pending_discussion_topic'), findsNothing);
      expect(controller.text, 'A newer unsent Circle draft');
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('A newer unsent Circle draft'),
        ),
        findsNothing,
      );
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'closing the Journey-only picker retains the pending chip until Remove Journey and leaves ordinary chat untagged',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _select(tester, 'draft-circle-past-0', past: true);
      await _send(tester, 'Tagged past topic');
      await _select(tester, 'draft-circle-past-0', past: true);
      await _openPicker(tester);
      expect(_key('circle_topic_general'), findsNothing);
      expect(find.text('General conversation'), findsNothing);
      await _press(tester, _key('circle_topic_picker_close'));
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(
        _key('circle_pending_discussion_topic_draft-circle-past-0'),
        findsOneWidget,
      );
      await _press(tester, _key('circle_remove_pending_discussion_topic'));
      expect(
        tester
            .widget<ZyraCircleDiscussLauncher>(
              find.byType(ZyraCircleDiscussLauncher),
            )
            .topic
            .isGeneral,
        isTrue,
      );
      expect(_key('circle_pending_discussion_topic'), findsNothing);
      await _send(tester, 'A general Circle conversation');
      expect(_messageTags, findsOneWidget);
      expect(_messageTag('draft-circle-past-0'), findsOneWidget);
      expect(_key('circle_topic_tag_preview-circle-general'), findsNothing);
      expect(
        _key('circle_discussion_bubble_preview-circle-general'),
        findsNothing,
      );
      expect(find.byType(ZyraCircleDiscussionBubble), findsOneWidget);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'reselecting the current interior preserves draft, local history and selected topic in the same Circle',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      final state = tester.state(find.byType(ZyraGuardianCircleScreen));
      await _select(tester, 'draft-circle-past-0', past: true);
      await _send(tester, 'First local past discussion');
      await _select(tester, 'draft-circle-past-0', past: true);
      await tester.enterText(_composer, 'An unfinished shared draft');
      final controller = tester.widget<TextField>(_composer).controller!;
      for (final mode in [ZyraCircleBubbleDesign.current]) {
        fixture.design.value = mode;
        await tester.pumpAndSettle();
        expect(
          tester.state(find.byType(ZyraGuardianCircleScreen)),
          same(state),
        );
        expect(controller.text, 'An unfinished shared draft');
        expect(
          tester.widget<TextField>(_composer).controller,
          same(controller),
        );
        expect(find.text('First local past discussion'), findsOneWidget);
        expect(_messageTag('draft-circle-past-0'), findsOneWidget);
        {
          expect(
            tester
                .widget<ZyraCircleDiscussLauncher>(
                  find.byType(ZyraCircleDiscussLauncher),
                )
                .topic
                .id,
            'draft-circle-past-0',
          );
        }
      }
      await _press(tester, _circleButton('Send message'));
      expect(find.text('An unfinished shared draft'), findsOneWidget);
      expect(_messageTag('draft-circle-past-0'), findsNWidgets(2));
      expect(fixture.data.messages.length, 1);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'Guardian sender uses the same locally selected topic without acquiring Seeker authority',
    (tester) async {
      final fixture = _Fixture(guardian: true);
      await _mount(tester, fixture);
      expect(find.text('Guardian Circle'), findsOneWidget);
      await _select(tester, 'draft-aisha');
      await _send(tester, 'A local Guardian topic message');
      expect(_key('circle_topic_tag_draft-aisha'), findsOneWidget);
      expect(fixture.data.senderId, 'draft-guardian-hassan');
      expect(
        fixture.data.participants
            .singleWhere((person) => person.isCurrentUser)
            .memberRole,
        'guardian',
      );
      expect(fixture.contextOpens, 0);
    },
  );

  final invalidPast = <String, List<ZyraCircleDiscussionTopic>>{
    'live-looking namespace': [
      ZyraCircleDiscussionTopic(
        id: 'member-123',
        firstName: 'Elif',
        kind: ZyraCircleTopicKind.past,
        endedOn: DateTime.utc(2026, 10, 10),
      ),
    ],
    'missing end date': const [
      ZyraCircleDiscussionTopic(
        id: 'draft-circle-past-0',
        firstName: 'Elif',
        kind: ZyraCircleTopicKind.past,
      ),
    ],
    'current kind': [
      ZyraCircleDiscussionTopic(
        id: 'draft-circle-past-0',
        firstName: 'Elif',
        kind: ZyraCircleTopicKind.current,
        endedOn: DateTime.utc(2026, 10, 10),
      ),
    ],
    'duplicate detached ID': [
      for (var i = 0; i < 2; i++)
        ZyraCircleDiscussionTopic(
          id: 'draft-circle-past-0',
          firstName: 'Elif',
          kind: ZyraCircleTopicKind.past,
          endedOn: DateTime.utc(2026, 10, 10),
        ),
    ],
  };
  for (final invalid in invalidPast.entries) {
    testWidgets(
      '${invalid.key} disables comparison without granting history or revoking valid chat',
      (tester) async {
        final fixture = _Fixture(pastTopics: invalid.value);
        await _mount(tester, fixture);
        expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
        expect(find.byType(ZyraCircleTopicPicker), findsNothing);
        await _send(tester, 'Still an admitted ordinary local Circle');
        expect(find.byType(ZyraCircleTopicTag), findsNothing);
        expect(fixture.contextOpens, 0);
      },
    );
  }

  testWidgets(
    'foreground cover temporarily denies retained callbacks without destroying owned draft or history',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _send(tester, 'A message before covering the Circle');
      await tester.enterText(
        _composer,
        'A draft retained while controls cover chat',
      );
      final controller = tester.widget<TextField>(_composer).controller!;
      final choose = tester
          .widget<ZyraCircleDiscussLauncher>(
            find.byType(ZyraCircleDiscussLauncher),
          )
          .onChoose!;
      final send = tester
          .widget<ZyraCircleSendButton>(_circleButton('Send message'))
          .onSend!;
      fixture.setForeground(false);
      choose();
      send();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(
        find.text('A draft retained while controls cover chat'),
        findsOneWidget,
      );
      expect(controller.text, 'A draft retained while controls cover chat');
      expect(find.text('A message before covering the Circle'), findsOneWidget);
      fixture.design.value = ZyraCircleBubbleDesign.current;
      await tester.pumpAndSettle();
      expect(controller.text, 'A draft retained while controls cover chat');
      fixture.setForeground(true);
      await tester.pumpAndSettle();
      await _dismissAndRemovePending(tester);
      await _press(tester, _circleButton('Send message'));
      expect(
        find.text('A draft retained while controls cover chat'),
        findsOneWidget,
      );
      expect(controller.text, isEmpty);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'a covered open picker cannot select through a retained row callback',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _openPicker(tester);
      await _press(tester, _key('circle_topic_tab_1'));
      final choosePast = _rowCallback(
        tester,
        'circle_topic_draft-circle-past-0',
      );
      fixture.setForeground(false);
      choosePast();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
      fixture.setForeground(true);
      await tester.pumpAndSettle();
      // Cover/uncover retires the selector lease, even for a fresh row tap
      // on that old popup. Only a newly opened selector may select again.
      choosePast();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
      expect(_messageTag('draft-circle-past-0'), findsNothing);
      await _press(tester, _key('circle_topic_picker_close'));
      await _select(tester, 'draft-circle-past-0', past: true);
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      await _send(tester, 'Selection after the same owner returns');
      expect(_messageTag('draft-circle-past-0'), findsOneWidget);
      expect(fixture.contextOpens, 0);
    },
  );

  for (final boundary in ['caller', 'developer', 'account']) {
    testWidgets(
      '$boundary withdrawal is terminal across ABA for retained topic and send callbacks',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await tester.enterText(_composer, 'A revoked draft must never publish');
        final send = tester
            .widget<ZyraCircleSendButton>(_circleButton('Send message'))
            .onSend!;
        await _openPicker(tester);
        final choose = _rowCallback(tester, 'circle_topic_draft-sara');
        if (boundary == 'caller') {
          fixture.owner = false;
          choose();
          fixture.owner = true;
        } else if (boundary == 'developer') {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        } else {
          final ownerGeneration = ZyraAccountState.generation;
          await tester.runAsync(() => ZyraAccountState.beginSignOut());
          expect(ZyraAccountState.isSigningOut, isTrue);
          expect(ZyraAccountState.generation, greaterThan(ownerGeneration));
          choose();
          send();
          await tester.pumpAndSettle();
          ZyraAccountState.endSignOutAttempt();
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
          expect(ZyraAccountState.isSigningOut, isFalse);
          expect(ZyraAccountState.generation, greaterThan(ownerGeneration));
        }
        choose();
        send();
        await tester.pumpAndSettle();
        fixture.design.value = ZyraCircleBubbleDesign.current;
        await tester.pumpAndSettle();
        expect(find.byType(ZyraCircleTopicPicker), findsNothing);
        expect(_composer, findsNothing);
        expect(find.text('A revoked draft must never publish'), findsNothing);
        expect(find.byType(ZyraCircleTopicTag), findsNothing);
        expect(fixture.contextOpens, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'pending tagged send is denied after owner withdrawal even if restored before publication',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _select(tester, 'draft-circle-past-0', past: true);
      await tester.enterText(_composer, 'Never publish after revocation');
      final choose = tester
          .widget<ZyraCircleDiscussLauncher>(
            find.byType(ZyraCircleDiscussLauncher),
          )
          .onChoose!;
      await tester.tap(_circleButton('Send message'));
      await tester.pump(const Duration(milliseconds: 20));
      fixture.owner = false;
      choose();
      await tester.pump();
      fixture.owner = true;
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Never publish after revocation'), findsNothing);
      expect(find.byType(ZyraCircleTopicTag), findsNothing);
      expect(_composer, findsNothing);
      expect(fixture.contextOpens, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final replacement in [
    'data',
    'guard',
    'design',
    'past',
    'foreground',
    'visibility',
    'role',
    'seeker',
  ]) {
    testWidgets(
      'replacing captured $replacement withdraws the Circle rather than retargeting its authority',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await tester.enterText(
          _composer,
          'A draft owned by the original inputs',
        );
        final send = tester
            .widget<ZyraCircleSendButton>(_circleButton('Send message'))
            .onSend!;
        final replacementDesign = ValueNotifier(ZyraCircleBubbleDesign.current);
        addTearDown(replacementDesign.dispose);
        final replacementVisibility = ValueNotifier(true);
        addTearDown(replacementVisibility.dispose);
        final replacementData = ZyraGuardianCirclePreviewData(
          seekerId: fixture.data.seekerId,
          senderId: fixture.data.senderId,
          participants: fixture.data.participants,
          messages: fixture.data.messages,
          contexts: fixture.data.contexts,
          canSend: fixture.data.canSend,
        );
        await tester.pumpWidget(
          _app(
            fixture.screen(
              replacementData: replacement == 'data' ? replacementData : null,
              replacementGuard: replacement == 'guard' ? () => true : null,
              replacementDesign: replacement == 'design'
                  ? replacementDesign
                  : null,
              replacementPast: replacement == 'past'
                  ? List.of(fixture.past)
                  : null,
              replacementForeground: replacement == 'foreground'
                  ? () => true
                  : null,
              replacementVisibility: replacement == 'visibility'
                  ? replacementVisibility
                  : null,
              viewerIsSeeker: replacement == 'role' ? false : null,
              seekerId: replacement == 'seeker' ? 'draft-other' : 'draft-self',
            ),
          ),
        );
        await tester.pumpAndSettle();
        send();
        await tester.pumpAndSettle();
        await tester.pumpWidget(_app(fixture.screen()));
        await tester.pumpAndSettle();
        expect(_composer, findsNothing);
        expect(find.text('A draft owned by the original inputs'), findsNothing);
        expect(fixture.contextOpens, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('disposed owner callbacks cannot resurrect the removed Circle', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    await tester.enterText(_composer, 'A disposed draft');
    final choose = tester
        .widget<ZyraCircleDiscussLauncher>(
          find.byType(ZyraCircleDiscussLauncher),
        )
        .onChoose!;
    final send = tester
        .widget<ZyraCircleSendButton>(_circleButton('Send message'))
        .onSend!;
    await tester.pumpWidget(
      _app(const Scaffold(body: Text('Replacement owner'))),
    );
    await tester.pumpAndSettle();
    fixture.design.value = ZyraCircleBubbleDesign.current;
    choose();
    send();
    await tester.pumpAndSettle();
    expect(find.text('Replacement owner'), findsOneWidget);
    expect(find.byType(ZyraCircleTopicPicker), findsNothing);
    expect(find.text('A disposed draft'), findsNothing);
    expect(fixture.contextOpens, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'raw preview props cannot create developer admission or a topic-enabled composer',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      final fixture = _Fixture(mode: ZyraCircleBubbleDesign.current);
      await _mount(tester, fixture);
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
      expect(_composer, findsNothing);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      fixture.design.value = ZyraCircleBubbleDesign.current;
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(_composer, findsNothing);
      expect(fixture.contextOpens, 0);
    },
  );

  for (final admitted in [false, true]) {
    testWidgets(
      'topic options without supplied data preserve the ${admitted ? 'admitted legacy' : 'unadmitted'} Circle boundary',
      (tester) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(admitted);
        final fixture = _Fixture(mode: ZyraCircleBubbleDesign.current);
        await _mount(
          tester,
          fixture,
          screen: ZyraGuardianCircleScreen(
            key: const ValueKey('legacy-with-raw-topic-options'),
            seekerId: 'draft-self',
            seekerFirstName: 'Adam',
            viewerIsSeeker: true,
            preview: true,
            previewBubbleDesign: fixture.design,
            previewPastTopics: fixture.past,
            previewForeground: fixture.foregroundGuard,
            previewVisibility: fixture.visibility,
            canAct: fixture.ownerGuard,
          ),
        );
        expect(find.byType(ZyraCircleTopicPicker), findsNothing);
        expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
        expect(_key('circle_topic_entry'), findsNothing);
        expect(_composer, admitted ? findsOneWidget : findsNothing);
        if (admitted) {
          await _send(
            tester,
            'Only the retained admitted legacy local conversation',
          );
          expect(find.byType(ZyraCircleTopicTag), findsNothing);
        }
        expect(ZyraDeveloperAccess.isAuthorizedOperator, admitted);
      },
    );
  }

  testWidgets(
    'a live-mode flag with supplied synthetic data and topics denies rather than starting member messaging',
    (tester) async {
      final fixture = _Fixture(mode: ZyraCircleBubbleDesign.current);
      await _mount(tester, fixture, screen: fixture.screen(preview: false));
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
      expect(_composer, findsNothing);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'adding a new presentation owner cannot retarget a retained legacy context or send',
    (tester) async {
      final fixture = _Fixture(withOptions: false);
      await _mount(tester, fixture);
      final discuss = tester
          .widget<IconButton>(_circleButton('Discuss someone'))
          .onPressed!;
      await _press(tester, _circleButton('Discuss someone'));
      await _press(tester, find.text('Sara'));
      expect(_circleButton('Remove person'), findsOneWidget);
      await tester.enterText(_composer, 'Never retarget this legacy draft');
      final send = tester
          .widget<ZyraCircleSendButton>(_circleButton('Send message'))
          .onSend!;
      fixture.withOptions = true;
      await tester.pumpWidget(_app(fixture.screen()));
      await tester.pumpAndSettle();
      discuss();
      send();
      await tester.pumpAndSettle();
      expect(_composer, findsNothing);
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(find.text('Never retarget this legacy draft'), findsNothing);
      expect(_messageTags, findsNothing);
      fixture.withOptions = false;
      await tester.pumpWidget(_app(fixture.screen()));
      await tester.pumpAndSettle();
      discuss();
      send();
      await tester.pumpAndSettle();
      expect(_composer, findsNothing);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'busy Topic bar and retained choose callback cannot interrupt or drop the tagged message',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _select(tester, 'draft-sara');
      await tester.enterText(
        _composer,
        'A pending message keeps its selected topic',
      );
      final choose = tester
          .widget<ZyraCircleDiscussLauncher>(
            find.byType(ZyraCircleDiscussLauncher),
          )
          .onChoose!;
      await tester.tap(_circleButton('Send message'));
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        tester
            .widget<ZyraCircleDiscussLauncher>(
              find.byType(ZyraCircleDiscussLauncher),
            )
            .onChoose,
        isNull,
      );
      choose();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        find.text('A pending message keeps its selected topic'),
        findsOneWidget,
      );
      expect(_messageTag('draft-sara'), findsOneWidget);
      expect(tester.widget<TextField>(_composer).controller!.text, isEmpty);
      expect(
        tester
            .widget<ZyraCircleDiscussLauncher>(
              find.byType(ZyraCircleDiscussLauncher),
            )
            .onChoose,
        isNotNull,
      );
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets('a fixed popup covers chat callbacks until dismissed', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    await tester.enterText(_composer, 'Retained while choosing a discussion');
    final send = tester
        .widget<ZyraCircleSendButton>(_circleButton('Send message'))
        .onSend!;
    final choose = tester
        .widget<ZyraCircleDiscussLauncher>(
          find.byType(ZyraCircleDiscussLauncher),
        )
        .onChoose!;
    await _openPicker(tester);
    choose();
    send();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
    expect(
      tester.widget<TextField>(_composer).controller!.text,
      'Retained while choosing a discussion',
    );
    await _press(tester, _key('circle_topic_picker_close'));
    expect(
      tester
          .widget<ZyraCircleDiscussLauncher>(
            find.byType(ZyraCircleDiscussLauncher),
          )
          .topic
          .isGeneral,
      isTrue,
    );
    expect(
      tester.widget<TextField>(_composer).controller!.text,
      'Retained while choosing a discussion',
    );
    await _press(tester, _circleButton('Send message'));
    expect(find.text('Retained while choosing a discussion'), findsOneWidget);
    expect(_messageTags, findsNothing);
    expect(fixture.contextOpens, 0);
  });

  for (final mode in _newDesigns) {
    testWidgets(
      '${mode.name} remains reachable at 320 wide and 200 percent text',
      (tester) async {
        final fixture = _Fixture(mode: mode);
        await _mount(tester, fixture, scale: 2, size: const Size(320, 852));
        await _openPicker(tester);
        await _press(tester, _key('circle_topic_tab_1'));
        await tester.enterText(_key('circle_topic_search'), 'yasmin');
        await tester.pumpAndSettle();
        expect(_key('circle_topic_draft-circle-past-11'), findsOneWidget);
        await _capture(tester, '${mode.name}-small-large-text-past');
        await _press(tester, _key('circle_topic_draft-circle-past-11'));
        await _send(tester, 'Small screen local message');
        expect(_messageTag('draft-circle-past-11'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, '${mode.name}-small-large-text-message');
      },
    );
  }

  testWidgets(
    'actual protected shell offers the Current Circle interior and preserves the mounted shared chat',
    (tester) async {
      await _mountShell(tester);
      await _nav(tester, 1);
      await toggleZyraDevControls(tester);
      await _press(tester, _key('concept_journey_preview_3'));
      await _nav(tester, 3);
      await _press(tester, _key('guardian-family-messages-top'));
      final owner = tester.widget<ZyraGuardianCircleScreen>(
        find.byType(ZyraGuardianCircleScreen),
      );
      final state = tester.state(find.byType(ZyraGuardianCircleScreen));
      expect(owner.preview, isTrue);
      expect(
        owner.previewData!.validFor('draft-self', viewerIsSeeker: true),
        isTrue,
      );
      expect(owner.previewPastTopics.length, 12);
      expect(
        owner.previewData!.contexts.every(
          (topic) => topic.kind == ZyraFamilyMessageContextKind.active,
        ),
        isTrue,
      );
      await _send(tester, 'Shell Circle history must survive Page options');
      await tester.enterText(
        _composer,
        'Shell Circle draft must survive Page options',
      );
      final controller = tester.widget<TextField>(_composer).controller!;
      for (final style in ZyraCircleBubbleDesign.values) {
        await _chooseShellDesign(tester, style);
        expect(
          tester.state(find.byType(ZyraGuardianCircleScreen)),
          same(state),
        );
        expect(
          tester
              .widget<ZyraGuardianCircleScreen>(
                find.byType(ZyraGuardianCircleScreen),
              )
              .previewData,
          same(owner.previewData),
        );
        expect(controller.text, 'Shell Circle draft must survive Page options');
        expect(_key('circle_topic_entry'), findsNothing);
        expect(_key('circle_topic_bar'), findsNothing);
        expect(_key('circle_discuss_floatingButton'), findsOneWidget);
        expect(
          find.text('Shell Circle history must survive Page options'),
          findsOneWidget,
        );
        expect(
          tester.widget<TextField>(_composer).controller,
          same(controller),
        );
      }
      await _select(tester, 'draft-circle-past-0', past: true);
      await _press(tester, _circleButton('Send message'));
      expect(_key('circle_topic_tag_draft-circle-past-0'), findsOneWidget);
      expect(
        find.text('Shell Circle draft must survive Page options'),
        findsOneWidget,
      );
      await _capture(tester, 'protected-shell-in-chat');
      await _closeShellCircle(tester);
      expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
      expect(_key('guardian-family-messages-top'), findsOneWidget);
      expect(find.byType(FloatingNavBar), findsOneWidget);
    },
  );

  testWidgets(
    'actual Guardian shell shares the bubble-design dropdown and the one admitted Circle',
    (tester) async {
      await _mountShell(tester, guardian: true);
      await _nav(tester, 2);
      await _press(tester, _key('seeker-family-chat-draft-self'));
      final owner = tester.widget<ZyraGuardianCircleScreen>(
        find.byType(ZyraGuardianCircleScreen),
      );
      final state = tester.state(find.byType(ZyraGuardianCircleScreen));
      expect(owner.viewerIsSeeker, isFalse);
      expect(
        owner.previewData!.validFor('draft-self', viewerIsSeeker: false),
        isTrue,
      );
      expect(owner.previewData!.senderId, 'draft-guardian-hassan');
      expect(owner.previewPastTopics, isEmpty);
      await _chooseShellDesign(tester, ZyraCircleBubbleDesign.current);
      expect(tester.state(find.byType(ZyraGuardianCircleScreen)), same(state));
      await _select(tester, 'draft-circle-current-sara');
      await _send(tester, 'Guardian shell local topic conversation');
      expect(_messageTag('draft-circle-current-sara'), findsOneWidget);
      expect(
        _key('open-message-context-draft-circle-current-sara'),
        findsNothing,
      );
      await _capture(tester, 'protected-guardian-shell-both');
      await _closeShellCircle(tester);
      expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
      expect(_key('seeker-family-chat-draft-self'), findsOneWidget);
    },
  );

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    final parentTab = guardian ? 2 : 3;
    final parentTitle = guardian ? 'Seekers' : 'Guardian';
    final circleEntry = guardian
        ? 'seeker-family-chat-draft-self'
        : 'guardian-family-messages-top';
    final dropdown = find.byType(
      DropdownButtonFormField<ZyraCircleBubbleDesign>,
    );

    testWidgets(
      '$role parent toggle selects Current plus five bubble interiors with the same fixed floating entry',
      (tester) async {
        await _mountShell(tester, guardian: guardian);
        await _nav(tester, parentTab);
        ValueListenable<ZyraCircleBubbleDesign>? sharedStyle;
        for (final style in ZyraCircleBubbleDesign.values) {
          await _chooseShellDesign(
            tester,
            style,
            pageTitle: parentTitle,
            returnsToCircle: false,
            menuCapture: style == ZyraCircleBubbleDesign.current
                ? '${role.toLowerCase()}-parent-discussion-options'
                : null,
          );
          await _press(tester, _key(circleEntry));
          final circle = tester.widget<ZyraGuardianCircleScreen>(
            find.byType(ZyraGuardianCircleScreen),
          );
          expect(circle.preview, isTrue);
          expect(circle.viewerIsSeeker, !guardian);
          expect(
            circle.previewData!.validFor(
              'draft-self',
              viewerIsSeeker: !guardian,
            ),
            isTrue,
          );
          expect(
            circle.previewData!.senderId,
            guardian ? 'draft-guardian-hassan' : 'draft-self',
          );
          expect(circle.previewBubbleDesign, isNotNull);
          expect(circle.previewBubbleDesign!.value, style);
          if (sharedStyle == null) {
            sharedStyle = circle.previewBubbleDesign;
          } else {
            expect(circle.previewBubbleDesign, same(sharedStyle));
          }
          expect(_key('circle_topic_entry'), findsNothing);
          if (style == ZyraCircleBubbleDesign.current) {
            await _capture(
              tester,
              '${role.toLowerCase()}-parent-discussion-entry',
            );
          }
          await _openPicker(tester);
          expect(_key('circle_topic_general'), findsNothing);
          expect(find.text('General conversation'), findsNothing);
          expect(_key('circle_topic_tab_0'), findsOneWidget);
          expect(_key('circle_topic_tab_1'), findsOneWidget);
          await _press(tester, _key('circle_topic_tab_1'));
          expect(_key('circle_topic_general'), findsNothing);
          expect(find.text('General conversation'), findsNothing);
          expect(_key('circle_topic_search'), findsOneWidget);
          expect(
            _key('circle_topic_draft-circle-past-0'),
            guardian ? findsNothing : findsOneWidget,
          );
          expect(
            find.text('10 Oct 2026'),
            guardian ? findsNothing : findsOneWidget,
          );
          expect(find.text('Potential'), findsNothing);
          expect(find.text('Paused'), findsNothing);
          await _dismissAndRemovePending(tester);
          expect(_composer, findsOneWidget);
          expect(_key('circle_topic_bar'), findsNothing);
          expect(find.byType(ZyraCircleDiscussLauncher), findsOneWidget);
          await _closeShellCircle(tester);
          expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
          expect(_key(circleEntry), findsOneWidget);
        }
      },
    );

    testWidgets(
      '$role unrelated parent tabs do not expose Journey discussion options',
      (tester) async {
        await _mountShell(tester, guardian: guardian);
        for (var tab = 0; tab < (guardian ? 4 : 5); tab++) {
          if (tab == parentTab) continue;
          await _nav(tester, tab);
          await toggleZyraDevControls(tester);
          expect(find.text('Page options'), findsNothing);
          expect(dropdown, findsNothing);
          expect(find.text('Floating bubble action'), findsNothing);
          expect(_key('concept_circle_send_design'), findsNothing);
          expect(find.text('Send button'), findsNothing);
          await toggleZyraDevControls(tester);
          expect(find.text('Page options'), findsNothing);
        }
      },
    );

    for (final withdrawal in ['tab ABA', 'role ABA', 'authorization ABA']) {
      testWidgets(
        '$role parent $withdrawal refuses the retained topic-design callback',
        (tester) async {
          await _mountShell(tester, guardian: guardian);
          await _nav(tester, parentTab);
          // Keep the original parent-context contract on real member navigation.
          final navigation = tester.widget<FloatingNavBar>(
            find.byType(FloatingNavBar),
          );
          expect(
            navigation.items[navigation.currentIndex].label,
            contains(parentTitle),
          );
          final fixture = zyraShellFixtureFor(tester);
          fixture.selectCircleBubble(ZyraCircleBubbleDesign.current);
          await tester.pumpAndSettle();
          expect(dropdown, findsNothing);
          await toggleZyraDevControls(tester);
          final stale = captureZyraFixtureChange<ZyraCircleBubbleDesign>(
            tester,
            (fixture, style) => fixture.selectCircleBubble(style),
          );
          if (withdrawal == 'tab ABA') {
            await toggleZyraDevControls(tester);
            await _nav(tester, 0);
            await _nav(tester, parentTab);
            await toggleZyraDevControls(tester);
          } else if (withdrawal == 'role ABA') {
            await _press(
              tester,
              _key(guardian ? 'draft_role_seeker' : 'draft_role_guardian'),
            );
            await toggleZyraDevControls(tester);
            await _press(
              tester,
              _key(guardian ? 'draft_role_guardian' : 'draft_role_seeker'),
            );
            await _nav(tester, parentTab);
            await toggleZyraDevControls(tester);
          } else {
            ZyraDeveloperAccess.setAuthorizedForTesting(false);
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
            await tester.pumpAndSettle();
          }
          stale(ZyraCircleBubbleDesign.current);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (withdrawal == 'authorization ABA') {
            expect(dropdown, findsNothing);
            expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
          } else {
            expect(dropdown, findsOneWidget);
            expect(
              tester
                  .widget<DropdownButtonFormField<ZyraCircleBubbleDesign>>(
                    dropdown,
                  )
                  .initialValue,
              ZyraCircleBubbleDesign.current,
            );
            await toggleZyraDevControls(tester);
            await _press(tester, _key(circleEntry));
            final circle = tester.widget<ZyraGuardianCircleScreen>(
              find.byType(ZyraGuardianCircleScreen),
            );
            expect(circle.viewerIsSeeker, !guardian);
            expect(
              circle.previewBubbleDesign!.value,
              ZyraCircleBubbleDesign.current,
            );
            expect(_key('circle_topic_entry'), findsNothing);
            expect(_key('circle_discuss_floatingButton'), findsOneWidget);
          }
        },
      );
    }
  }
}
