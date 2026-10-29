// Caller-owned, offline presentation comparisons. A picker style never grants
// member messaging, a Journey, history consent or navigation authority.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_circle_discussion_picker_presentation.dart';
import 'package:zyra/dev/zyra_circle_send_button_presentation.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_CIRCLE_PICKER_CAPTURE_DIR',
);
const _captureKey = ValueKey('circle-picker-styles-capture');
const _font = 'PoppinsCirclePickerStyles';
const _currentId = 'draft-sara';
const _pastId = 'draft-circle-past-0';
Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _circle => find.byType(ZyraGuardianCircleScreen);
Finder get _presentation => find.byType(ZyraCircleDiscussionPickerPresentation);
Finder get _picker => find.byType(ZyraCircleTopicPicker);
Finder get _launcher => _key('circle_discuss_floatingButton');
Finder get _composer => find.descendant(
  of: _key('guardian-circle-composer'),
  matching: find.byType(TextField),
);
Finder get _send =>
    find.descendant(of: _circle, matching: find.byType(ZyraCircleSendButton));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Circle picker comparisons must remain offline.');
  }
}

class _Fixture {
  _Fixture({
    required ZyraCircleBubbleDesign style,
    this.guardian = false,
    bool canSend = true,
    bool longHistory = false,
  }) : bubbleDesign = ValueNotifier(style) {
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
      ],
      messages: [
        for (var index = 0; index < (longHistory ? 24 : 2); index++)
          ZyraFamilyMessage(
            id: 'draft-picker-message-$index',
            senderId: 'draft-guardian-hassan',
            senderFirstName: 'Hassan',
            senderRoleLabel: 'Main Guardian',
            body:
                'Existing shared Circle message $index stays in this conversation.',
            createdAt: DateTime.utc(2026, 10, 18, 9, index),
          ),
      ],
      contexts: const [
        ZyraFamilyMessageContext(
          referenceId: _currentId,
          firstName: 'Sara',
          kind: ZyraFamilyMessageContextKind.active,
        ),
      ],
    );
  }

  final bool guardian;
  final ValueNotifier<ZyraCircleBubbleDesign> bubbleDesign;
  final visibility = ValueNotifier(true);
  final past = <ZyraCircleDiscussionTopic>[
    for (var index = 0; index < 12; index++)
      ZyraCircleDiscussionTopic(
        id: 'draft-circle-past-$index',
        firstName: index == 11
            ? 'Yasmin A Long But Clearly Labelled Past Journey'
            : 'Past person $index',
        kind: ZyraCircleTopicKind.past,
        endedOn: DateTime.utc(2026, 10, 10).subtract(Duration(days: index)),
      ),
  ];
  late final ZyraGuardianCirclePreviewData data;
  bool owner = true;
  int contextOpens = 0;
  bool _ownerCurrent() => owner;
  bool _foregroundCurrent() => visibility.value;
  late final bool Function() ownerGuard = _ownerCurrent;
  late final bool Function() foregroundGuard = _foregroundCurrent;
  void _openContext(ZyraFamilyMessageContext _) => contextOpens++;
  late final ValueChanged<ZyraFamilyMessageContext> openContext = _openContext;

  Widget screen({ValueListenable<ZyraCircleBubbleDesign>? replacementStyle}) =>
      ZyraGuardianCircleScreen(
        key: const ValueKey('controlled-picker-circle'),
        seekerId: 'draft-self',
        seekerFirstName: 'Adam',
        viewerIsSeeker: !guardian,
        preview: true,
        previewData: data,
        previewBubbleDesign: replacementStyle ?? bubbleDesign,
        previewPastTopics: past,
        previewForeground: foregroundGuard,
        previewVisibility: visibility,
        canAct: ownerGuard,
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
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(fixture.bubbleDesign.dispose);
  addTearDown(fixture.visibility.dispose);
  expect(
    fixture.data.validFor('draft-self', viewerIsSeeker: !fixture.guardian),
    isTrue,
  );
  await tester.pumpWidget(_app(fixture.screen(), scale: scale));
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

void _expectFloating(WidgetTester tester) {
  expect(_launcher.hitTestable(), findsOneWidget);
  expect(find.byType(ZyraCircleDiscussLauncher), findsOneWidget);
  expect(_key('circle_topic_bar'), findsNothing);
  expect(_key('circle_topic_entry'), findsNothing);
  expect(tester.getSize(_launcher).width, greaterThanOrEqualTo(44));
  expect(tester.getSize(_launcher).height, greaterThanOrEqualTo(44));
  expect(
    tester.getRect(_launcher).overlaps(tester.getRect(_composer)),
    isFalse,
  );
  expect(tester.getRect(_launcher).overlaps(tester.getRect(_send)), isFalse);
}

Future<void> _open(WidgetTester tester, ZyraCircleBubbleDesign style) async {
  await _press(tester, _launcher);
  expect(_presentation, findsOneWidget);
  expect(
    tester.widget<ZyraCircleDiscussionPickerPresentation>(_presentation).design,
    style,
  );
  expect(_picker, findsOneWidget);
  expect(_key('circle_picker_floating_surface'), findsOneWidget);
  expect(tester.widget<ZyraCircleTopicPicker>(_picker).bubbleDesign, style);
  expect(
    tester.widget<ZyraCircleTopicPicker>(_picker).title,
    'Discuss a Journey',
  );
  expect(
    tester.widget<ZyraCircleTopicPicker>(_picker).showGeneralConversation,
    isFalse,
  );
  expect(_key('circle_topic_general'), findsNothing);
  expect(find.text('General conversation'), findsNothing);
}

Future<void> _select(
  WidgetTester tester,
  String id, {
  bool past = false,
}) async {
  await _press(tester, _key('circle_topic_tab_${past ? 1 : 0}'));
  expect(_key('circle_topic_general'), findsNothing);
  expect(find.text('General conversation'), findsNothing);
  await _press(tester, _key('circle_topic_$id'));
  expect(_presentation, findsNothing);
  expect(_picker, findsNothing);
}

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
      throw ArgumentError(
        'Picker captures require an existing absolute directory.',
      );
    }
    // Geometry is a real-font contract even when no screenshot is requested.
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

  test(
    'the fixed floating picker keeps only the selected Current interior',
    () {
      expect(ZyraCircleBubbleDesign.values, [ZyraCircleBubbleDesign.current]);
    },
  );

  for (final style in ZyraCircleBubbleDesign.values) {
    for (final guardian in [false, true]) {
      testWidgets(
        '${style.name} ${guardian ? 'Guardian' : 'Seeker'} selects and cancels without replacing the Circle',
        (tester) async {
          final fixture = _Fixture(style: style, guardian: guardian);
          await _mount(tester, fixture);
          _expectFloating(tester);
          final circleState = tester.state(_circle);
          final controller = tester.widget<TextField>(_composer).controller!;
          controller.text = 'My unsent shared Circle draft';
          controller.selection = const TextSelection(
            baseOffset: 3,
            extentOffset: 10,
          );
          await tester.pumpAndSettle();
          if (!guardian && style == ZyraCircleBubbleDesign.current) {
            await _capture(tester, 'floating-launcher-standard');
          }
          await _open(tester, style);
          await _capture(
            tester,
            'picker-${style.name}-${guardian ? 'guardian' : 'seeker'}-current',
          );
          await _press(tester, _key('circle_topic_picker_close'));
          expect(_presentation, findsNothing);
          expect(tester.state(_circle), same(circleState));
          expect(
            tester.widget<TextField>(_composer).controller,
            same(controller),
          );
          expect(controller.text, 'My unsent shared Circle draft');
          expect(
            controller.selection,
            const TextSelection(baseOffset: 3, extentOffset: 10),
          );
          expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
          await _open(tester, style);
          await _select(tester, _currentId);
          expect(
            _key('circle_pending_discussion_topic_$_currentId'),
            findsOneWidget,
          );
          expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
          await _open(tester, style);
          await _select(tester, _pastId, past: true);
          expect(
            _key('circle_pending_discussion_topic_$_pastId'),
            findsOneWidget,
          );
          expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
          await _open(tester, style);
          await _press(tester, _key('circle_topic_picker_close'));
          expect(_presentation, findsNothing);
          expect(
            _key('circle_pending_discussion_topic_$_pastId'),
            findsOneWidget,
          );
          await _press(tester, _key('circle_remove_pending_discussion_topic'));
          expect(_key('circle_pending_discussion_topic'), findsNothing);
          expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
          expect(tester.state(_circle), same(circleState));
          expect(
            tester.widget<TextField>(_composer).controller,
            same(controller),
          );
          expect(controller.text, 'My unsent shared Circle draft');
          expect(fixture.data.messages.length, 2);
          expect(fixture.contextOpens, 0);
          _expectFloating(tester);
        },
      );
    }

    testWidgets(
      '${style.name} fits compact 200 percent Past search with keyboard',
      (tester) async {
        final fixture = _Fixture(style: style);
        await _mount(tester, fixture, size: const Size(320, 568), scale: 2);
        _expectFloating(tester);
        if (style == ZyraCircleBubbleDesign.current) {
          await _capture(tester, 'floating-launcher-compact200');
        }
        await _open(tester, style);
        await _press(tester, _key('circle_topic_tab_1'));
        final search = _key('circle_topic_search');
        await tester.showKeyboard(search);
        tester.view.viewInsets = const FakeViewPadding(bottom: 200);
        await tester.enterText(search, 'yasmin');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final result = _key('circle_topic_draft-circle-past-11');
        expect(result, findsOneWidget);
        await Scrollable.ensureVisible(tester.element(result), alignment: .5);
        await tester.pumpAndSettle();
        expect(result.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(result);
        await _capture(tester, 'picker-${style.name}-compact200-past-keyboard');
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(320));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(568 - 200));
        await _press(tester, result);
        expect(_presentation, findsNothing);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(
          _key('circle_pending_discussion_topic_draft-circle-past-11'),
          findsOneWidget,
        );
        expect(fixture.contextOpens, 0);
      },
    );

    for (final guardian in [false, true]) {
      testWidgets(
        '${style.name} never enables Basic ${guardian ? 'Guardian' : 'Seeker'} discussion',
        (tester) async {
          final fixture = _Fixture(
            style: style,
            guardian: guardian,
            canSend: false,
          );
          await _mount(tester, fixture);
          expect(_launcher, findsNothing);
          expect(_composer, findsNothing);
          expect(_presentation, findsNothing);
          for (final next in ZyraCircleBubbleDesign.values) {
            fixture.bubbleDesign.value = next;
            await tester.pumpAndSettle();
            expect(_launcher, findsNothing);
            expect(_composer, findsNothing);
          }
          expect(fixture.contextOpens, 0);
        },
      );
    }

    testWidgets(
      '${style.name} covered selector and close cannot pop an unrelated route',
      (tester) async {
        final fixture = _Fixture(style: style);
        await _mount(tester, fixture);
        await _open(tester, style);
        final picker = tester.widget<ZyraCircleTopicPicker>(_picker);
        final presentation = tester
            .widget<ZyraCircleDiscussionPickerPresentation>(_presentation);
        final navigator = Navigator.of(tester.element(_picker));
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: Text('Unrelated picker cover')),
          ),
        );
        await tester.pumpAndSettle();
        picker.onSelected(picker.currentTopics.single);
        presentation.onClose();
        await tester.pumpAndSettle();
        expect(find.text('Unrelated picker cover'), findsOneWidget);
        expect(_key('circle_discussion_bubble_$_currentId'), findsNothing);
        navigator.pop();
        await tester.pumpAndSettle();
        await _press(tester, _key('circle_topic_picker_close'));
        expect(_presentation, findsNothing);
        expect(_circle, findsOneWidget);
        expect(fixture.contextOpens, 0);
      },
    );

    testWidgets(
      '${style.name} replacing the captured style notifier withdraws terminally',
      (tester) async {
        final fixture = _Fixture(style: style);
        await _mount(tester, fixture);
        await tester.enterText(
          _composer,
          'The original owner keeps this draft',
        );
        await _open(tester, style);
        final picker = tester.widget<ZyraCircleTopicPicker>(_picker);
        final replacement = ValueNotifier(style);
        addTearDown(replacement.dispose);
        await tester.pumpWidget(
          _app(fixture.screen(replacementStyle: replacement)),
        );
        await tester.pumpAndSettle();
        expect(picker.canSelect(), isFalse);
        picker.onSelected(picker.currentTopics.single);
        await tester.pumpAndSettle();
        expect(_key('circle_discussion_bubble_$_currentId'), findsNothing);
        expect(_composer, findsNothing);
        await tester.pumpWidget(_app(fixture.screen()));
        await tester.pumpAndSettle();
        fixture.bubbleDesign.value = ZyraCircleBubbleDesign
            .values[(style.index + 1) % ZyraCircleBubbleDesign.values.length];
        await tester.pumpAndSettle();
        picker.onSelected(picker.currentTopics.single);
        expect(_composer, findsNothing);
        expect(_launcher, findsNothing);
        expect(fixture.contextOpens, 0);
      },
    );

    for (final boundary in ['caller', 'developer', 'account']) {
      testWidgets(
        '${style.name} $boundary withdrawal refuses retained selection after ABA',
        (tester) async {
          final fixture = _Fixture(style: style);
          await _mount(tester, fixture);
          await _open(tester, style);
          final picker = tester.widget<ZyraCircleTopicPicker>(_picker);
          if (boundary == 'caller') {
            fixture.owner = false;
            expect(picker.canSelect(), isFalse);
            fixture.owner = true;
          } else if (boundary == 'developer') {
            ZyraDeveloperAccess.setAuthorizedForTesting(false);
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          } else {
            await tester.runAsync(() => ZyraAccountState.beginSignOut());
            expect(picker.canSelect(), isFalse);
            ZyraAccountState.endSignOutAttempt();
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
          picker.onSelected(picker.currentTopics.single);
          await tester.pumpAndSettle();
          expect(_key('circle_discussion_bubble_$_currentId'), findsNothing);
          expect(_composer, findsNothing);
          expect(_launcher, findsNothing);
          expect(fixture.contextOpens, 0);
        },
      );
    }
  }

  testWidgets(
    'all picker interiors preserve the same scrolled transcript, editor and selected topic',
    (tester) async {
      final fixture = _Fixture(
        style: ZyraCircleBubbleDesign.current,
        longHistory: true,
      );
      await _mount(tester, fixture);
      await _open(tester, ZyraCircleBubbleDesign.current);
      await _select(tester, _currentId);
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
      final controller = tester.widget<TextField>(_composer).controller!;
      controller.text = 'My unsent Circle draft';
      controller.selection = const TextSelection(
        baseOffset: 3,
        extentOffset: 10,
      );
      await tester.pumpAndSettle();
      final editor = tester.state<EditableTextState>(find.byType(EditableText));
      final circle = tester.state(_circle);
      for (final style in [
        ...ZyraCircleBubbleDesign.values,
        ...ZyraCircleBubbleDesign.values.reversed,
      ]) {
        fixture.bubbleDesign.value = style;
        await tester.pumpAndSettle();
        expect(transcript(), same(reader));
        expect(reader.position.pixels, closeTo(180, .01));
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(editor),
        );
        expect(tester.state(_circle), same(circle));
        expect(controller.text, 'My unsent Circle draft');
        expect(
          controller.selection,
          const TextSelection(baseOffset: 3, extentOffset: 10),
        );
        await _open(tester, style);
        expect(
          tester.widget<ZyraCircleTopicPicker>(_picker).selected.id,
          _currentId,
        );
        await _press(tester, _key('circle_topic_picker_close'));
        expect(transcript(), same(reader));
        expect(reader.position.pixels, closeTo(180, .01));
        expect(
          tester.widget<TextField>(_composer).controller,
          same(controller),
        );
      }
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'choosing a pending Journey preserves the existing transcript position',
    (tester) async {
      final fixture = _Fixture(
        style: ZyraCircleBubbleDesign.current,
        longHistory: true,
      );
      await _mount(tester, fixture);
      final transcript = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      transcript.position.jumpTo(180);
      await tester.enterText(_composer, 'Keep this unsent draft');
      await tester.pumpAndSettle();
      final offset = transcript.position.pixels;
      await _open(tester, ZyraCircleBubbleDesign.current);
      await _select(tester, _currentId);
      expect(transcript.position.pixels, closeTo(offset, .01));
      expect(
        _key('circle_pending_discussion_topic_$_currentId'),
        findsOneWidget,
      );
      expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'Keep this unsent draft',
      );
      final controller = tester.widget<TextField>(_composer).controller!;
      final editor = tester.state<EditableTextState>(find.byType(EditableText));
      final circle = tester.state(_circle);
      controller.selection = const TextSelection(
        baseOffset: 5,
        extentOffset: 9,
      );
      await tester.showKeyboard(_composer);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(transcript.position.pixels, closeTo(offset, .01));
      expect(tester.state(_circle), same(circle));
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(editor),
      );
      expect(tester.widget<TextField>(_composer).controller, same(controller));
      expect(
        controller.selection,
        const TextSelection(baseOffset: 5, extentOffset: 9),
      );
      expect(
        tester.getRect(find.byType(ListView)),
        tester.getRect(_key('circle_transcript_viewport')),
      );
      expect(
        tester.widget<ListView>(find.byType(ListView)).padding,
        const EdgeInsets.fromLTRB(20, 12, 20, 82),
      );
      expect(
        tester
            .getRect(_launcher)
            .overlaps(tester.getRect(find.byType(ListView))),
        isTrue,
      );
      expect(
        tester.getRect(_launcher).overlaps(tester.getRect(_composer)),
        isFalse,
      );
      expect(
        tester.getRect(_launcher).overlaps(tester.getRect(_send)),
        isFalse,
      );
      await _capture(tester, 'floating-pending-keyboard');
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(transcript.position.pixels, closeTo(offset, .01));
      expect(tester.widget<TextField>(_composer).controller, same(controller));
      expect(controller.text, 'Keep this unsent draft');
      expect(tester.takeException(), isNull);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'pending Journey and its removal stay reachable above the compact large-text keyboard',
    (tester) async {
      final fixture = _Fixture(style: ZyraCircleBubbleDesign.current);
      await _mount(tester, fixture, size: const Size(320, 568), scale: 2);
      await _open(tester, ZyraCircleBubbleDesign.current);
      await _select(tester, _currentId);
      await tester.showKeyboard(_composer);
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(_composer, 'An unsent Circle message');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        _key('circle_pending_discussion_topic_$_currentId'),
        findsOneWidget,
      );
      expect(
        _key('circle_remove_pending_discussion_topic').hitTestable(),
        findsOneWidget,
      );
      expect(_send.hitTestable(), findsOneWidget);
      await _press(tester, _key('circle_remove_pending_discussion_topic'));
      expect(_key('circle_pending_discussion_topic'), findsNothing);
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'An unsent Circle message',
      );
      expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
    },
  );

  testWidgets(
    'hiding General denies its retained row callback while keeping Journey selection available',
    (tester) async {
      const current = ZyraCircleDiscussionTopic(
        id: 'controlled-current',
        firstName: 'Sara',
        kind: ZyraCircleTopicKind.current,
      );
      const past = ZyraCircleDiscussionTopic(
        id: 'controlled-past',
        firstName: 'Elif',
        kind: ZyraCircleTopicKind.past,
      );
      final showGeneral = ValueNotifier(true);
      addTearDown(showGeneral.dispose);
      final selected = <ZyraCircleDiscussionTopic>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showGeneral,
              builder: (_, visible, _) => ZyraCircleTopicPicker(
                currentTopics: const [current],
                pastTopics: const [past],
                selected: ZyraCircleDiscussionTopic.general,
                onSelected: selected.add,
                canSelect: () => true,
                showGeneralConversation: visible,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chooseGeneral = tester
          .widget<InkWell>(
            find.descendant(
              of: _key('circle_topic_general'),
              matching: find.byType(InkWell),
            ),
          )
          .onTap!;
      showGeneral.value = false;
      await tester.pumpAndSettle();
      expect(_key('circle_topic_general'), findsNothing);
      expect(find.text('General conversation'), findsNothing);
      chooseGeneral();
      await tester.pumpAndSettle();
      expect(selected, isEmpty);
      await _press(tester, _key('circle_topic_tab_1'));
      expect(_key('circle_topic_general'), findsNothing);
      expect(find.text('General conversation'), findsNothing);
      chooseGeneral();
      await tester.pumpAndSettle();
      expect(selected, isEmpty);
      await _press(tester, _key('circle_topic_tab_0'));
      await _press(tester, _key('circle_topic_controlled-current'));
      expect(selected, [current]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new picker styling does not restyle the separate own-message Link a Journey flow',
    (tester) async {
      final fixture = _Fixture(style: ZyraCircleBubbleDesign.current);
      await _mount(tester, fixture);
      await tester.enterText(_composer, 'My own local message for a reference');
      await _press(tester, _send);
      await tester.longPress(find.text('My own local message for a reference'));
      await tester.pumpAndSettle();
      await _press(tester, find.text('Link a Journey'));
      expect(_presentation, findsNothing);
      expect(_picker, findsOneWidget);
      final picker = tester.widget<ZyraCircleTopicPicker>(_picker);
      expect(picker.title, 'Link a Journey');
      expect(picker.bubbleDesign, isNull);
      expect(picker.onClose, isNull);
      expect(picker.showGeneralConversation, isTrue);
      expect(_key('circle_topic_general'), findsOneWidget);
      expect(find.text('General conversation'), findsOneWidget);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'fixed send preserves draft, selected topic and Circle owner through bubble changes',
    (tester) async {
      final fixture = _Fixture(style: ZyraCircleBubbleDesign.current);
      await _mount(tester, fixture);
      await _open(tester, ZyraCircleBubbleDesign.current);
      await _select(tester, _currentId);
      final circle = tester.state(_circle);
      final controller = tester.widget<TextField>(_composer).controller!;
      controller.text = 'Keep this unsent shared draft';
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 9,
      );
      await tester.pumpAndSettle();
      for (final design in ZyraCircleBubbleDesign.values) {
        fixture.bubbleDesign.value = design;
        await tester.pumpAndSettle();
        expect(tester.widget<ZyraCircleSendButton>(_send).onSend, isNotNull);
        expect(tester.state(_circle), same(circle));
        expect(
          tester.widget<TextField>(_composer).controller,
          same(controller),
        );
        expect(controller.text, 'Keep this unsent shared draft');
        expect(
          controller.selection,
          const TextSelection(baseOffset: 2, extentOffset: 9),
        );
        expect(
          _key('circle_pending_discussion_topic_$_currentId'),
          findsOneWidget,
        );
        expect(find.byType(ZyraCircleDiscussionBubble), findsNothing);
        await _capture(tester, 'send_gold_outline_bubble_${design.name}');
      }
      await _press(tester, _send);
      expect(controller.text, isEmpty);
      expect(find.text('Keep this unsent shared draft'), findsOneWidget);
      expect(_key('circle_topic_tag_$_currentId'), findsOneWidget);
      expect(_key('circle_pending_discussion_topic'), findsNothing);
      expect(_key('circle_discussion_bubble_$_currentId'), findsOneWidget);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'fixed send stays reachable beside the compact keyboard and each discussion bubble',
    (tester) async {
      final fixture = _Fixture(style: ZyraCircleBubbleDesign.current);
      await _mount(tester, fixture, size: const Size(320, 568), scale: 2);
      final state = tester.state(_circle);
      final controller = tester.widget<TextField>(_composer).controller!;
      await tester.showKeyboard(_composer);
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(
        _composer,
        List.filled(12, 'Keep this long draft.').join('\n'),
      );
      await tester.pumpAndSettle();
      final draft = controller.text;
      for (final design in ZyraCircleBubbleDesign.values) {
        fixture.bubbleDesign.value = design;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.state(_circle), same(state));
        expect(
          tester.widget<TextField>(_composer).controller,
          same(controller),
        );
        expect(controller.text, draft);
        final bubble = _key('circle_discuss_floatingButton');
        expect(bubble.hitTestable(), findsOneWidget);
        expect(_send.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(bubble).overlaps(tester.getRect(_composer)),
          isFalse,
        );
        expect(tester.getRect(bubble).overlaps(tester.getRect(_send)), isFalse);
        expect(tester.getSize(_send).height, greaterThanOrEqualTo(44));
        await _capture(
          tester,
          'send_gold_outline_${design.name}_compact200_keyboard',
        );
      }
    },
  );

  testWidgets(
    'the selected interior retains its floating container geometry without a Back header',
    (tester) async {
      final fixture = _Fixture(style: ZyraCircleBubbleDesign.current);
      await _mount(tester, fixture);
      expect(find.text('Guardian Circle'), findsOneWidget);
      expect(find.text('2 members'), findsOneWidget);
      expect(find.textContaining('Private circle'), findsNothing);
      expect(find.byTooltip('Mute circle notifications'), findsNothing);
      expect(find.byIcon(Icons.groups_2_outlined), findsNothing);
      final back = _key('zyra_visible_back_button');
      expect(back, findsNothing);
      expect(find.text('Back'), findsNothing);
      expect(_key('zyra_back_swipe_edge'), findsOneWidget);
      Rect? original;
      for (final design in ZyraCircleBubbleDesign.values) {
        fixture.bubbleDesign.value = design;
        await tester.pumpAndSettle();
        await _open(tester, design);
        final bounds = tester.getRect(_key('circle_picker_floating_surface'));
        original ??= bounds;
        expect(bounds, original);
        expect(
          _key('circle_topic_interior_${design.name}_$_currentId'),
          findsOneWidget,
        );
        await _press(tester, _key('circle_topic_picker_close'));
        expect(_circle, findsOneWidget);
      }
    },
  );
}
