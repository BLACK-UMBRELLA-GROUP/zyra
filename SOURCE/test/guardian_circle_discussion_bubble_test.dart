// Session-only Circle discussion markers and caller-owned profile views.
// No marker is a service message, history permission or member access grant.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_circle_discussion_archive.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsCircleDiscussionBubble';
const _captures = String.fromEnvironment('ZYRA_CIRCLE_TOPIC_CAPTURE_DIR');
const _boundary = ValueKey('circle-discussion-bubble-capture');
const _sara = ZyraFamilyMessageContext(
  referenceId: 'draft-sara',
  firstName: 'Sara',
  kind: ZyraFamilyMessageContextKind.active,
);
const _safeSara = SeekerProfile(
  id: 'draft-sara',
  firstName: 'Sara',
  age: 27,
  city: 'Birmingham',
  photos: [],
  gender: 'female',
  surnameLine: 'Ahmed',
);

Finder _key(String key) => find.byKey(ValueKey(key));
Finder _marker(String id) => _key('circle_discussion_bubble_$id');
Finder get _pending => _key('circle_pending_discussion_topic');
Finder get _bubbles => find.byType(ZyraCircleDiscussionBubble);
Finder get _composer => find.descendant(
  of: _key('guardian-circle-composer'),
  matching: find.byType(TextField),
);
Finder _circleButton(String tooltip) => find.descendant(
  of: find.byType(ZyraGuardianCircleScreen),
  matching: find.byTooltip(tooltip),
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError(
      'Discussion markers and owned sample profiles stay offline.',
    );
  }
}

class _Fixture {
  _Fixture({
    this.guardian = false,
    this.funded = true,
    this.withResolver = true,
    this.withArchiveResolver = false,
    this.discussionEnabled = true,
    this.currentExamples = const [],
    List<ZyraFamilyMessageContext> contexts = const [_sara],
    bool emptyHistory = false,
    List<ZyraFamilyMessage>? suppliedMessages,
    ZyraCircleBubbleDesign mode = ZyraCircleBubbleDesign.current,
  }) : bubbleDesign = ValueNotifier(mode) {
    data = ZyraGuardianCirclePreviewData(
      seekerId: 'draft-self',
      senderId: guardian ? 'draft-hassan' : 'draft-self',
      canSend: funded,
      participants: [
        ZyraFamilyCircleParticipant(
          userId: 'draft-self',
          firstName: 'Adam',
          memberRole: 'seeker',
          isMainGuardian: false,
          isCurrentUser: !guardian,
        ),
        ZyraFamilyCircleParticipant(
          userId: 'draft-hassan',
          firstName: 'Hassan',
          memberRole: 'guardian',
          isMainGuardian: true,
          isCurrentUser: guardian,
        ),
      ],
      messages:
          suppliedMessages ??
          (emptyHistory
              ? const []
              : [
                  ZyraFamilyMessage(
                    id: 'draft-circle-first',
                    senderId: 'draft-hassan',
                    senderFirstName: 'Hassan',
                    senderRoleLabel: 'Main Guardian',
                    body: 'An existing Circle message.',
                    createdAt: DateTime.utc(2026, 10, 13, 9),
                  ),
                  ZyraFamilyMessage(
                    id: 'draft-circle-second',
                    senderId: 'draft-self',
                    senderFirstName: 'Adam',
                    senderRoleLabel: 'Seeker',
                    body: 'The conversation is already underway.',
                    createdAt: DateTime.utc(2026, 10, 13, 9, 1),
                  ),
                ]),
      contexts: contexts,
    );
  }

  final bool guardian;
  final bool funded;
  final bool withResolver;
  final bool withArchiveResolver;
  final bool discussionEnabled;
  List<ZyraCircleDiscussionTopic> currentExamples;
  final ValueNotifier<ZyraCircleBubbleDesign> bubbleDesign;
  final ValueNotifier<bool> visibility = ValueNotifier(true);
  final past = [
    ZyraCircleDiscussionTopic(
      id: 'draft-circle-past-elif',
      firstName: 'Elif',
      kind: ZyraCircleTopicKind.past,
      endedOn: DateTime.utc(2026, 10, 10),
    ),
  ];
  late final ZyraGuardianCirclePreviewData data;
  bool owner = true;
  bool permitted = true;
  bool archivePermitted = true;
  String resolution = 'valid';
  String archiveResolution = 'valid';
  int contextOpens = 0;
  final resolved = <ZyraFamilyMessageContext>[];
  final resolvedArchives = <ZyraCircleDiscussionTopic>[];
  final archive = ZyraCircleDiscussionArchive(
    topicId: 'draft-circle-past-elif',
    firstName: 'Elif',
    startedOn: DateTime.utc(2026, 9, 19),
    endedOn: DateTime.utc(2026, 10, 10),
  );
  bool _current() => owner;
  bool _foreground() => visibility.value;
  late final bool Function() ownerGuard = _current;
  late final bool Function() foregroundGuard = _foreground;
  void _oldContext(ZyraFamilyMessageContext _) {
    contextOpens++;
  }

  late final ValueChanged<ZyraFamilyMessageContext> oldContext = _oldContext;

  SeekerProfile? _resolve(ZyraFamilyMessageContext context) {
    resolved.add(context);
    if (!permitted || resolution == 'null') return null;
    if (resolution == 'throw') throw StateError('Synthetic resolver denial');
    if (resolution == 'wrong id') {
      return const SeekerProfile(
        id: 'draft-other',
        firstName: 'Sara',
        age: 27,
        city: 'Birmingham',
        photos: [],
        gender: 'female',
      );
    }
    if (resolution == 'wrong name') {
      return const SeekerProfile(
        id: 'draft-sara',
        firstName: 'Someone else',
        age: 27,
        city: 'Birmingham',
        photos: [],
        gender: 'female',
      );
    }
    if (resolution == 'different object') {
      return SeekerProfile(
        id: _safeSara.id,
        firstName: _safeSara.firstName,
        age: _safeSara.age,
        city: _safeSara.city,
        photos: const [],
        gender: 'female',
      );
    }
    return identical(context, _sara) ? _safeSara : null;
  }

  late final SeekerProfile? Function(ZyraFamilyMessageContext) resolver =
      _resolve;

  ZyraCircleDiscussionArchive? _resolveArchive(
    ZyraCircleDiscussionTopic topic,
  ) {
    resolvedArchives.add(topic);
    if (!archivePermitted || archiveResolution == 'null') return null;
    if (archiveResolution == 'throw') {
      throw StateError('Synthetic archive denial');
    }
    if (archiveResolution == 'valid') {
      return identical(topic, past.single) ? archive : null;
    }
    return ZyraCircleDiscussionArchive(
      topicId: archiveResolution == 'wrong id'
          ? 'draft-circle-past-other'
          : archive.topicId,
      firstName: archiveResolution == 'wrong name' ? 'Noor' : archive.firstName,
      startedOn: archiveResolution == 'starts after end'
          ? archive.endedOn.add(const Duration(days: 1))
          : archive.startedOn,
      endedOn: archiveResolution == 'wrong ended date'
          ? archive.endedOn.subtract(const Duration(days: 1))
          : archive.endedOn,
    );
  }

  late final ZyraCircleDiscussionArchive? Function(ZyraCircleDiscussionTopic)
  archiveResolver = _resolveArchive;

  ZyraGuardianCircleScreen screen({
    SeekerProfile? Function(ZyraFamilyMessageContext)? replacementResolver,
    ZyraGuardianCirclePreviewData? replacementData,
    ZyraCircleDiscussionArchive? Function(ZyraCircleDiscussionTopic)?
    replacementArchiveResolver,
  }) => ZyraGuardianCircleScreen(
    key: const ValueKey('discussion-circle-owner'),
    seekerId: 'draft-self',
    seekerFirstName: 'Adam',
    viewerIsSeeker: !guardian,
    preview: true,
    previewData: replacementData ?? data,
    previewBubbleDesign: discussionEnabled ? bubbleDesign : null,
    previewCurrentTopics: currentExamples,
    previewPastTopics: past,
    previewForeground: foregroundGuard,
    previewVisibility: visibility,
    previewDiscussionProfileFor:
        replacementResolver ?? (withResolver ? resolver : null),
    previewDiscussionArchiveFor:
        replacementArchiveResolver ??
        (withArchiveResolver ? archiveResolver : null),
    canAct: ownerGuard,
    onOpenContext: oldContext,
  );
}

Widget _app(Widget child, {double scale = 1, bool disableAnimations = true}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData(
            brightness: ZyraColors.isLightPalette
                ? Brightness.light
                : Brightness.dark,
          ).copyWith(
            textTheme: ZyraText.textTheme(
              ZyraColors.isLightPalette
                  ? ThemeData.light().textTheme
                  : ThemeData.dark().textTheme,
            ),
          ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
          disableAnimations: disableAnimations,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: child,
    );

Future<void> _mount(
  WidgetTester tester,
  _Fixture fixture, {
  Size size = const Size(393, 852),
  double scale = 1,
  bool disableAnimations = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(fixture.bubbleDesign.dispose);
  addTearDown(fixture.visibility.dispose);
  expect(
    fixture.data.validFor('draft-self', viewerIsSeeker: !fixture.guardian),
    isTrue,
  );
  await tester.pumpWidget(
    _app(fixture.screen(), scale: scale, disableAnimations: disableAnimations),
  );
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
  await _press(tester, find.byType(ZyraCircleDiscussLauncher));
  expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
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
  await _press(
    tester,
    _key(id == 'general' ? 'circle_topic_general' : 'circle_topic_$id'),
  );
  expect(find.byType(ZyraCircleTopicPicker), findsNothing);
}

Future<void> _dismissAndRemovePending(WidgetTester tester) async {
  if (find.byType(ZyraCircleTopicPicker).evaluate().isEmpty) {
    await _openPicker(tester);
  }
  expect(_key('circle_topic_general'), findsNothing);
  expect(find.text('General conversation'), findsNothing);
  await _press(tester, _key('circle_topic_picker_close'));
  expect(find.byType(ZyraCircleTopicPicker), findsNothing);
  if (_pending.evaluate().isNotEmpty) {
    await _press(tester, _key('circle_remove_pending_discussion_topic'));
  }
  expect(_pending, findsNothing);
}

Future<void> _send(WidgetTester tester, String body) async {
  await tester.enterText(_composer, body);
  await _press(tester, _circleButton('Send message'));
  expect(_pending, findsNothing);
  expect(find.text(body), findsOneWidget);
}

Future<void> _commit(
  WidgetTester tester,
  String id, {
  bool past = false,
}) async {
  await _select(tester, id, past: past);
  await _send(tester, 'A sent discussion reference for $id');
}

Finder _message(String id) => _key('circle_message_$id');
Finder _messageTag(String id) => find.descendant(
  of: _message(id),
  matching: find.byType(ZyraCircleTopicTag),
);

Future<void> _holdMessage(WidgetTester tester, String id) async {
  final target = _message(id);
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  await tester.longPress(target.hitTestable());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _openMessageReference(WidgetTester tester, String id) async {
  await _holdMessage(tester, id);
  await _press(tester, _key('circle_message_link_$id'));
  expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
  expect(find.text('Link a Journey'), findsOneWidget);
}

VoidCallback _profileCallback(WidgetTester tester) => tester
    .widget<OutlinedButton>(_key('circle_discussion_profile_draft-sara'))
    .onPressed!;

VoidCallback _archiveCallback(WidgetTester tester) => tester
    .widget<OutlinedButton>(
      _key('circle_discussion_journey_draft-circle-past-elif'),
    )
    .onPressed!;

int _transcriptIndex(WidgetTester tester, Finder target) {
  final list = tester.widget<ListView>(find.byType(ListView));
  final children = (list.childrenDelegate as SliverChildListDelegate).children;
  final element = tester.element(target);
  var index = children.indexOf(element.widget);
  element.visitAncestorElements((ancestor) {
    final candidate = children.indexOf(ancestor.widget);
    if (candidate < 0) return true;
    index = candidate;
    return false;
  });
  expect(
    index,
    greaterThanOrEqualTo(0),
    reason: 'A rendered transcript child owns this content',
  );
  return index;
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
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

  const sample = ZyraCircleDiscussionTopic(
    id: 'draft-circle-current-example',
    firstName: 'Sample Noor',
    kind: ZyraCircleTopicKind.current,
  );

  for (final guardian in [false, true]) {
    testWidgets('detached Current names remain label-only guardian=$guardian', (
      tester,
    ) async {
      final fixture = _Fixture(
        guardian: guardian,
        contexts: const [],
        currentExamples: const [sample],
        withArchiveResolver: true,
      );
      await _mount(tester, fixture, size: const Size(320, 568), scale: 2);
      await _select(tester, sample.id);
      expect(_pending, findsOneWidget);
      expect(_marker(sample.id), findsNothing);
      expect(_key('circle_discussion_profile_${sample.id}'), findsNothing);
      expect(_key('circle_discussion_journey_${sample.id}'), findsNothing);
      await _send(tester, 'A local discussion about the sample');
      final transcript = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      // The sent text and the preceding full-size card cannot both fit this
      // compact 200% viewport. Reveal each actual lazy row in turn.
      await tester.scrollUntilVisible(
        _marker(sample.id),
        -120,
        scrollable: transcript,
      );
      await tester.pumpAndSettle();
      expect(_marker(sample.id), findsOneWidget);
      await tester.scrollUntilVisible(
        _message('dev-family-3'),
        120,
        scrollable: transcript,
      );
      await tester.pumpAndSettle();
      expect(_key('circle_topic_tag_${sample.id}'), findsWidgets);
      expect(fixture.resolved, isEmpty);
      expect(fixture.resolvedArchives, isEmpty);
      expect(fixture.contextOpens, 0);
      expect(fixture.data.contexts, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('actual contexts win over detached Current fallback names', (
    tester,
  ) async {
    final fixture = _Fixture(currentExamples: const [sample]);
    await _mount(tester, fixture);
    await _openPicker(tester);
    expect(_key('circle_topic_draft-sara'), findsOneWidget);
    expect(_key('circle_topic_${sample.id}'), findsNothing);
  });

  for (final invalid in const [
    ZyraCircleDiscussionTopic(
      id: 'real-id',
      firstName: 'Noor',
      kind: ZyraCircleTopicKind.current,
    ),
    ZyraCircleDiscussionTopic(
      id: 'draft-circle-current-empty',
      firstName: '',
      kind: ZyraCircleTopicKind.current,
    ),
    ZyraCircleDiscussionTopic(
      id: 'draft-circle-current-past',
      firstName: 'Noor',
      kind: ZyraCircleTopicKind.past,
    ),
  ]) {
    testWidgets(
      'invalid detached metadata cannot enable discussion: ${invalid.id}',
      (tester) async {
        final fixture = _Fixture(
          contexts: const [],
          currentExamples: [invalid],
        );
        await _mount(tester, fixture);
        expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
        expect(fixture.resolved, isEmpty);
      },
    );
  }

  testWidgets('duplicate detached IDs fail closed', (tester) async {
    final fixture = _Fixture(
      contexts: const [],
      currentExamples: const [sample, sample],
    );
    await _mount(tester, fixture);
    expect(find.byType(ZyraCircleDiscussLauncher), findsNothing);
  });

  testWidgets(
    'replacing detached catalogue permanently withdraws retained owner',
    (tester) async {
      final fixture = _Fixture(
        contexts: const [],
        currentExamples: const [sample],
      );
      await _mount(tester, fixture);
      await _select(tester, sample.id);
      fixture.currentExamples = const [sample];
      // Different list identity, even identical metadata, is a new caller binding.
      fixture.currentExamples = List.of(fixture.currentExamples);
      await tester.pumpWidget(_app(fixture.screen()));
      await tester.pumpAndSettle();
      expect(_composer, findsNothing);
      expect(_marker(sample.id), findsNothing);
      expect(fixture.resolved, isEmpty);
    },
  );
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;
  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  List<Object?> memberState() => [
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
  ];

  setUpAll(() async {
    if (_captures.isNotEmpty &&
        (!_captures.startsWith('/') || !Directory(_captures).existsSync())) {
      throw StateError(
        'Discussion captures require an existing absolute directory.',
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
    beforeMember = memberState();
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    expect(network.attempts, 0);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMember);
    HttpOverrides.global = oldNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test(
    'request shell source binds profile projection to its exact permitted Seeker context and stable loaded-photo cache',
    () {
      final source = File(
        'lib/dev/zyra_one_journey_concept_shell.dart',
      ).readAsStringSync();
      final circleStart = source.indexOf('Widget _guardianCircle()');
      expect(circleStart, greaterThanOrEqualTo(0));
      final resolverStart = source.indexOf(
        'SeekerProfile? discussionProfileFor(',
        circleStart,
      );
      final resolverEnd = source.indexOf(
        'return _circleEntryView = Navigator(',
        resolverStart,
      );
      expect(resolverStart, greaterThan(circleStart));
      expect(resolverEnd, greaterThan(resolverStart));
      final binding = source
          .substring(resolverStart, resolverEnd)
          .replaceAll(RegExp(r'\s+'), ' ');
      expect(
        source.substring(resolverEnd),
        contains(
          'previewDiscussionProfileFor: guardian ? null : discussionProfileFor',
        ),
        reason: 'The exact guarded resolver is captured before route replay.',
      );
      expect(binding, contains('!current()'));
      expect(binding, contains("_page != 'guardian_circle'"));
      expect(binding, contains('allowed.referenceId == context.referenceId'));
      expect(binding, contains('allowed.firstName == context.firstName'));
      expect(binding, contains('allowed.kind == context.kind'));
      expect(
        binding,
        contains('context.kind != ZyraFamilyMessageContextKind.active'),
      );
      expect(binding, contains('_model.isBlocked(context.referenceId)'));
      expect(
        binding,
        contains(
          '_model.stateFor(context.referenceId) != DraftJourneyState.active',
        ),
      );
      expect(binding, contains('person.firstName == context.firstName'));
      expect(binding, contains('person == null || _photos == null'));
      expect(binding, contains('discussionProfiles.putIfAbsent('));
      expect(binding, contains('_displayProfile(person)'));
      expect(
        source.substring(circleStart, resolverStart),
        contains('final discussionProfiles = <String, SeekerProfile>{};'),
      );
    },
  );

  testWidgets(
    'a second quick Send replaces only the prior owned reveal animation',
    (tester) async {
      final history = List.generate(
        18,
        (index) => ZyraFamilyMessage(
          id: 'motion-history-$index',
          senderId: 'draft-hassan',
          senderFirstName: 'Hassan',
          senderRoleLabel: 'Main Guardian',
          body: 'An older shared Circle message $index.',
          createdAt: DateTime.utc(2026, 10, 13, 9, index),
        ),
      );
      final fixture = _Fixture(suppliedMessages: history);
      final originalMessages = List<ZyraFamilyMessage>.of(
        fixture.data.messages,
      );
      await _mount(tester, fixture, disableAnimations: false);
      const first = 'The first quick Circle message';
      final second = List.filled(
        10,
        'The second quick Circle message stays in view.',
      ).join(' ');
      await tester.enterText(_composer, first);
      await tester.tap(_circleButton('Send message'));
      await tester.pump(const Duration(milliseconds: 121));
      final transcript = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(transcript.position.isScrollingNotifier.value, isTrue);
      expect(transcript.position.userScrollDirection.name, 'idle');
      await tester.enterText(_composer, second);
      await tester.tap(_circleButton('Send message'));
      // The first 180ms reveal is still active when this 120ms send commits.
      await tester.pump(const Duration(milliseconds: 121));
      expect(
        tester
            .widget<ListView>(find.byType(ListView))
            .childrenDelegate
            .estimatedChildCount,
        history.length + 3,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(find.text(second), findsOneWidget);
      expect(
        transcript.position.pixels,
        closeTo(transcript.position.maxScrollExtent, .5),
      );
      expect(tester.widget<TextField>(_composer).controller!.text, isEmpty);
      expect(_pending, findsNothing);
      expect(fixture.data.messages, orderedEquals(originalMessages));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selection stages a gold composer chip and publishes its context only with Send',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      final state = tester.state(find.byType(ZyraGuardianCircleScreen));
      await tester.enterText(_composer, 'Keep this unfinished Circle draft');
      final controller = tester.widget<TextField>(_composer).controller!;
      await _select(tester, 'draft-sara');
      expect(_pending, findsOneWidget);
      expect(_bubbles, findsNothing);
      expect(find.text('Discussing'), findsNothing);
      expect(_key('circle_topic_tag_draft-sara'), findsNothing);
      expect(tester.state(find.byType(ZyraGuardianCircleScreen)), same(state));
      expect(tester.widget<TextField>(_composer).controller, same(controller));
      expect(controller.text, 'Keep this unfinished Circle draft');
      expect(find.text('An existing Circle message.'), findsOneWidget);
      expect(
        find.text('The conversation is already underway.'),
        findsOneWidget,
      );
      expect(fixture.data.messages.length, 2);
      expect(
        fixture.data.messages.every((message) => !message.lifecycle),
        isTrue,
      );
      expect(fixture.contextOpens, 0);
      await _press(tester, _circleButton('Send message'));
      expect(_pending, findsNothing);
      expect(_marker('draft-sara'), findsOneWidget);
      expect(find.text('Journey with Sara'), findsOneWidget);
      expect(find.text('Current Journey'), findsOneWidget);
      expect(find.text('Keep this unfinished Circle draft'), findsOneWidget);
      expect(controller.text, isEmpty);
      final text = tester.widget<Text>(find.text('Discussing'));
      expect(text.style!.color, ZyraColors.journeyGold);
      await _capture(tester, 'discussion-current-marker');
    },
  );

  testWidgets(
    'initial dismissal, repeated topic and pending removal do not append duplicate markers',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _dismissAndRemovePending(tester);
      expect(_bubbles, findsNothing);
      await _select(tester, 'draft-sara');
      await _select(tester, 'draft-sara');
      expect(_bubbles, findsNothing);
      expect(_pending, findsOneWidget);
      await _openPicker(tester);
      Navigator.of(tester.element(find.byType(ZyraCircleTopicPicker))).pop();
      await tester.pumpAndSettle();
      expect(_bubbles, findsNothing);
      expect(_pending, findsOneWidget);
      expect(
        tester
            .widget<ZyraCircleDiscussLauncher>(
              find.byType(ZyraCircleDiscussLauncher),
            )
            .topic
            .id,
        'draft-sara',
      );
      await _dismissAndRemovePending(tester);
      await _dismissAndRemovePending(tester);
      expect(_bubbles, findsNothing);
      expect(_pending, findsNothing);
      expect(_marker('preview-circle-general'), findsNothing);
      expect(find.text('Back to general conversation'), findsNothing);
      expect(fixture.data.messages.length, 2);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'an empty Circle keeps its empty transcript until a message is sent',
    (tester) async {
      final fixture = _Fixture(emptyHistory: true);
      await _mount(tester, fixture);
      expect(find.text('Start the Guardian Circle'), findsOneWidget);
      await _select(tester, 'draft-sara');
      expect(_bubbles, findsNothing);
      expect(_pending, findsOneWidget);
      expect(find.text('Start the Guardian Circle'), findsOneWidget);
      expect(_composer, findsOneWidget);
      expect(fixture.data.messages, isEmpty);
      await _capture(tester, 'discussion-empty-history-pending');
      await _send(tester, 'Start this Journey discussion');
      expect(_bubbles, findsOneWidget);
      expect(find.text('Start the Guardian Circle'), findsNothing);
    },
  );

  testWidgets(
    'returning to an earlier topic keeps distinct chronological cards without duplicate sibling keys',
    (tester) async {
      final fixture = _Fixture();
      // Count every committed card, not only the lazy viewport's last rows.
      // Compact and ordinary phone geometry remain covered separately.
      await _mount(tester, fixture, size: const Size(393, 1600));
      await _select(tester, 'draft-sara');
      await _send(tester, 'First sent Journey discussion');
      await _select(tester, 'draft-circle-past-elif', past: true);
      await _send(tester, 'Second sent Journey discussion');
      await _select(tester, 'draft-sara');
      await _send(tester, 'Third sent Journey discussion');
      expect(_bubbles, findsNWidgets(3));
      expect(_marker('draft-sara'), findsNWidgets(2));
      expect(_key('circle_discussion_marker_1'), findsOneWidget);
      expect(_key('circle_discussion_marker_2'), findsOneWidget);
      expect(_key('circle_discussion_marker_3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sent markers stay chronological and dismissing the picker creates no transcript entry',
    (tester) async {
      final fixture = _Fixture();
      // This sequence assertion inspects every rendered child. Use a tall
      // fixture so the transcript's lazy sliver does not evict earlier rows;
      // ordinary and large-text presentation checks retain phone dimensions.
      await _mount(tester, fixture, size: const Size(393, 1600));
      await _select(tester, 'draft-sara');
      await _send(tester, 'A later message about Sara.');
      await _select(tester, 'draft-circle-past-elif', past: true);
      await _send(tester, 'A later message about the past Journey.');
      await tester.enterText(_composer, 'The next draft is still here');
      await _dismissAndRemovePending(tester);
      expect(_bubbles, findsNWidgets(2));
      expect(_marker('preview-circle-general'), findsNothing);
      expect(find.text('Journey with Elif'), findsOneWidget);
      expect(find.text('Past Journey · Ended 10 Oct 2026'), findsOneWidget);
      final sequence = [
        _transcriptIndex(
          tester,
          find.text('The conversation is already underway.'),
        ),
        _transcriptIndex(tester, _marker('draft-sara')),
        _transcriptIndex(tester, find.text('A later message about Sara.')),
        _transcriptIndex(tester, _marker('draft-circle-past-elif')),
        _transcriptIndex(
          tester,
          find.text('A later message about the past Journey.'),
        ),
      ];
      for (var index = 1; index < sequence.length; index++) {
        expect(sequence[index], greaterThan(sequence[index - 1]));
      }
      expect(_key('circle_topic_tag_draft-sara'), findsOneWidget);
      expect(_key('circle_topic_tag_draft-circle-past-elif'), findsOneWidget);
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'The next draft is still here',
      );
      expect(fixture.data.messages.length, 2);
      expect(fixture.contextOpens, 0);
      await _capture(tester, 'discussion-chronological-markers');
    },
  );

  testWidgets(
    'interior changes and covered controls retain the same marker, local history and draft',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _select(tester, 'draft-sara');
      await _send(tester, 'A local message before controls cover this Circle');
      await _select(tester, 'draft-sara');
      await tester.enterText(
        _composer,
        'A draft held while comparing interiors',
      );
      final state = tester.state(find.byType(ZyraGuardianCircleScreen));
      final controller = tester.widget<TextField>(_composer).controller!;
      for (final mode in [
        ZyraCircleBubbleDesign.quietList,
        ZyraCircleBubbleDesign.portraitTiles,
        ZyraCircleBubbleDesign.current,
      ]) {
        fixture.visibility.value = false;
        fixture.bubbleDesign.value = mode;
        await tester.pumpAndSettle();
        expect(controller.text, 'A draft held while comparing interiors');
        fixture.visibility.value = true;
        await tester.pumpAndSettle();
        await _openPicker(tester);
        final retainedTopic = tester.widget<ZyraCircleTopicPicker>(
          find.byType(ZyraCircleTopicPicker),
        );
        expect(retainedTopic.selected.id, 'draft-sara');
        await _press(tester, _key('circle_topic_picker_close'));
        expect(
          tester.state(find.byType(ZyraGuardianCircleScreen)),
          same(state),
        );
        expect(_bubbles, findsOneWidget);
        expect(_marker('draft-sara'), findsOneWidget);
        expect(
          find.text('A local message before controls cover this Circle'),
          findsOneWidget,
        );
        expect(
          tester.widget<TextField>(_composer).controller,
          same(controller),
        );
        expect(controller.text, 'A draft held while comparing interiors');
      }
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      'Basic ${guardian ? 'Guardian' : 'Seeker'} cannot add markers or profile access',
      (tester) async {
        final fixture = _Fixture(guardian: guardian, funded: false);
        await _mount(tester, fixture);
        expect(_composer, findsNothing);
        expect(find.byType(ZyraCircleTopicPicker), findsNothing);
        expect(_bubbles, findsNothing);
        expect(find.byType(SeekerProfileScreen), findsNothing);
        expect(fixture.resolved, isEmpty);
      },
    );
  }

  testWidgets(
    'a covered picker cannot append a marker through its retained selection',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _openPicker(tester);
      final select = tester
          .widget<ZyraCircleTopicPicker>(find.byType(ZyraCircleTopicPicker))
          .onSelected;
      fixture.visibility.value = false;
      select(
        const ZyraCircleDiscussionTopic(
          id: 'draft-sara',
          firstName: 'Sara',
          kind: ZyraCircleTopicKind.current,
        ),
      );
      await tester.pumpAndSettle();
      expect(_bubbles, findsNothing);
      fixture.visibility.value = true;
      await tester.pumpAndSettle();
      // Restoring foreground does not re-authorize this retired picker epoch.
      select(
        const ZyraCircleDiscussionTopic(
          id: 'draft-sara',
          firstName: 'Sara',
          kind: ZyraCircleTopicKind.current,
        ),
      );
      await tester.pumpAndSettle();
      expect(_bubbles, findsNothing);
      expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
      await _press(tester, _key('circle_topic_picker_close'));
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      await _select(tester, 'draft-sara');
      expect(_bubbles, findsNothing);
      expect(_pending, findsOneWidget);
    },
  );

  testWidgets(
    'busy chat denies retained topic and profile callbacks while the original tagged send completes',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _commit(tester, 'draft-sara');
      final profile = _profileCallback(tester);
      await _select(tester, 'draft-sara');
      final choose = tester
          .widget<ZyraCircleDiscussLauncher>(
            find.byType(ZyraCircleDiscussLauncher),
          )
          .onChoose!;
      await tester.enterText(_composer, 'This pending send keeps its topic');
      await tester.tap(_circleButton('Send message'));
      await tester.pump(const Duration(milliseconds: 20));
      profile();
      choose();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(_bubbles, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('This pending send keeps its topic'), findsOneWidget);
      expect(_key('circle_topic_tag_draft-sara'), findsNWidgets(2));
      expect(_bubbles, findsNWidgets(2));
      expect(_pending, findsNothing);
    },
  );

  testWidgets(
    'permitted current Seeker profile is an owned read-only child and close preserves the exact Circle',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _select(tester, 'draft-sara');
      await _send(tester, 'Existing local history before the profile child');
      await tester.enterText(
        _composer,
        'The same draft after returning from Sara',
      );
      final state = tester.state(find.byType(ZyraGuardianCircleScreen));
      final controller = tester.widget<TextField>(_composer).controller!;
      await _press(tester, _key('circle_discussion_profile_draft-sara'));
      final child = tester.widget<SeekerProfileScreen>(
        find.byType(SeekerProfileScreen),
      );
      expect(
        _key('circle_discussion_profile_route_draft-sara'),
        findsOneWidget,
      );
      expect(child.profile, same(_safeSara));
      expect(child.actionBar, isNull);
      expect(child.swipeDownToDismiss, isTrue);
      expect(_key('zyra_visible_back_button'), findsNothing);
      expect(child.canAct!(), isTrue);
      expect(child.onDismiss, isNotNull);
      expect(
        fixture.resolved.every((context) => identical(context, _sara)),
        isTrue,
      );
      expect(fixture.contextOpens, 0);
      await _capture(tester, 'discussion-owned-profile-child');
      await swipeZyraBack(tester);
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(tester.state(find.byType(ZyraGuardianCircleScreen)), same(state));
      expect(tester.widget<TextField>(_composer).controller, same(controller));
      expect(controller.text, 'The same draft after returning from Sara');
      expect(
        find.text('Existing local history before the profile child'),
        findsOneWidget,
      );
      expect(_bubbles, findsOneWidget);
      await _capture(tester, 'discussion-owned-profile-return');
    },
  );

  testWidgets(
    'owned profile swipe Back returns exactly once to the same ongoing chat',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _commit(tester, 'draft-sara');
      await tester.enterText(_composer, 'A draft survives profile swipe Back');
      final state = tester.state(find.byType(ZyraGuardianCircleScreen));
      await _press(tester, _key('circle_discussion_profile_draft-sara'));
      final scope = _key('concept_pull_down_back_scope');
      expect(scope, findsOneWidget);
      final rect = tester.getRect(scope);
      await tester.timedDragFrom(
        Offset(rect.left + 1, rect.top + 65),
        const Offset(230, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(tester.state(find.byType(ZyraGuardianCircleScreen)), same(state));
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'A draft survives profile swipe Back',
      );
      expect(_bubbles, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final resolution in [
    'no resolver',
    'null',
    'throw',
    'wrong id',
    'wrong name',
  ]) {
    testWidgets(
      '$resolution never creates a current profile link or navigation grant',
      (tester) async {
        final fixture = _Fixture(withResolver: resolution != 'no resolver')
          ..resolution = resolution;
        await _mount(tester, fixture);
        await _commit(tester, 'draft-sara');
        expect(_bubbles, findsOneWidget);
        expect(_key('circle_discussion_profile_draft-sara'), findsNothing);
        expect(
          tester.widget<ZyraCircleDiscussionBubble>(_bubbles).onViewProfile,
          isNull,
        );
        expect(find.byType(SeekerProfileScreen), findsNothing);
        expect(fixture.contextOpens, 0);
      },
    );
  }

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian current' : 'Past and dismissed picker'} markers never consult a profile resolver',
      (tester) async {
        final fixture = _Fixture(guardian: guardian);
        await _mount(tester, fixture);
        if (guardian) await _commit(tester, 'draft-sara');
        await _commit(tester, 'draft-circle-past-elif', past: true);
        await _dismissAndRemovePending(tester);
        expect(_bubbles, findsNWidgets(guardian ? 2 : 1));
        expect(_marker('preview-circle-general'), findsNothing);
        expect(find.text('View profile'), findsNothing);
        expect(fixture.resolved, isEmpty);
        expect(find.byType(SeekerProfileScreen), findsNothing);
        expect(fixture.contextOpens, 0);
      },
    );
  }

  for (final denial in ['permission', 'different object', 'foreground']) {
    testWidgets(
      'retained profile callback rechecks $denial and cannot open a stale child',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await _commit(tester, 'draft-sara');
        final open = _profileCallback(tester);
        if (denial == 'permission') fixture.permitted = false;
        if (denial == 'different object') fixture.resolution = denial;
        if (denial == 'foreground') fixture.visibility.value = false;
        open();
        await tester.pumpAndSettle();
        expect(find.byType(SeekerProfileScreen), findsNothing);
        expect(_bubbles, findsOneWidget);
        fixture.permitted = true;
        fixture.resolution = 'valid';
        fixture.visibility.value = true;
        await tester.pumpAndSettle();
        open();
        await tester.pumpAndSettle();
        expect(
          _key('circle_discussion_profile_route_draft-sara'),
          findsOneWidget,
        );
        await swipeZyraBack(tester);
        expect(_bubbles, findsOneWidget);
      },
    );
  }

  for (final withdrawal in ['caller', 'developer']) {
    testWidgets(
      '$withdrawal withdrawal clears markers and denies retained profile access after restoration',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await _commit(tester, 'draft-sara');
        final open = _profileCallback(tester);
        if (withdrawal == 'caller') {
          fixture.owner = false;
          open();
          fixture.owner = true;
        } else {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        }
        open();
        await tester.pumpAndSettle();
        expect(_bubbles, findsNothing);
        expect(_composer, findsNothing);
        expect(find.byType(SeekerProfileScreen), findsNothing);
        expect(fixture.contextOpens, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'replacing captured resolver identity withdraws rather than retargeting markers and child access',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _commit(tester, 'draft-sara');
      final open = _profileCallback(tester);
      await tester.pumpWidget(
        _app(fixture.screen(replacementResolver: (_) => _safeSara)),
      );
      await tester.pumpAndSettle();
      open();
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(fixture.screen()));
      await tester.pumpAndSettle();
      expect(_bubbles, findsNothing);
      expect(_composer, findsNothing);
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'replacing active contexts with a stale catalog cannot publish old markers or profile access',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _commit(tester, 'draft-sara');
      final open = _profileCallback(tester);
      final replacement = ZyraGuardianCirclePreviewData(
        seekerId: fixture.data.seekerId,
        senderId: fixture.data.senderId,
        participants: fixture.data.participants,
        messages: fixture.data.messages,
        canSend: true,
        contexts: const [],
      );
      await tester.pumpWidget(
        _app(fixture.screen(replacementData: replacement)),
      );
      await tester.pumpAndSettle();
      open();
      await tester.pumpAndSettle();
      expect(_bubbles, findsNothing);
      expect(_composer, findsNothing);
      expect(find.byType(SeekerProfileScreen), findsNothing);
    },
  );

  testWidgets('retained owned close cannot pop a covering unrelated route', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    await _commit(tester, 'draft-sara');
    await _press(tester, _key('circle_discussion_profile_draft-sara'));
    final close = captureZyraAccessibleBack(tester);
    final navigator = Navigator.of(
      tester.element(find.byType(SeekerProfileScreen)),
    );
    final cover = MaterialPageRoute<void>(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('Unrelated covering route'))),
    );
    navigator.push(cover);
    await tester.pumpAndSettle();
    close();
    await tester.pumpAndSettle();
    expect(cover.isCurrent, isTrue);
    expect(find.text('Unrelated covering route'), findsOneWidget);
    expect(tester.takeException(), isNull);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(_key('seeker-profile-preview-unavailable'), findsNothing);
    expect(_key('zyra_visible_back_button'), findsNothing);
    close();
    await tester.pumpAndSettle();
    expect(find.byType(SeekerProfileScreen), findsOneWidget);
    await swipeZyraBack(tester);
    expect(find.byType(SeekerProfileScreen), findsNothing);
    expect(_bubbles, findsOneWidget);
  });

  testWidgets(
    'retained owned close after profile permission loss cannot dismiss its protected child',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _commit(tester, 'draft-sara');
      await _press(tester, _key('circle_discussion_profile_draft-sara'));
      final close = captureZyraAccessibleBack(tester);
      final route = ModalRoute.of(
        tester.element(find.byType(SeekerProfileScreen)),
      )!;
      fixture.permitted = false;
      close();
      await tester.pumpAndSettle();
      expect(route.isCurrent, isTrue);
      expect(_key('seeker-profile-preview-unavailable'), findsOneWidget);
      expect(_composer, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'developer withdrawal clears the discussion marker and its owned profile route',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _commit(tester, 'draft-sara');
      await _press(tester, _key('circle_discussion_profile_draft-sara'));
      final close = captureZyraAccessibleBack(tester);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      close();
      await tester.pumpAndSettle();
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(_bubbles, findsNothing);
      expect(_composer, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'gold marker and profile action remain reachable at 320 wide with 200 percent text',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture, size: const Size(320, 852), scale: 2);
      await _commit(tester, 'draft-sara');
      expect(_marker('draft-sara'), findsOneWidget);
      expect(find.text('Journey with Sara'), findsOneWidget);
      await _capture(tester, 'discussion-marker-small-large-text');
      await _press(tester, _key('circle_discussion_profile_draft-sara'));
      expect(
        _key('circle_discussion_profile_route_draft-sara'),
        findsOneWidget,
      );
      await swipeZyraBack(tester);
      expect(_marker('draft-sara'), findsOneWidget);
      expect(_composer, findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'discussion-profile-return-small-large-text');
    },
  );

  test(
    'request shell supplies a stable detached past archive projection without profile or history lookup',
    () {
      final source = File(
        'lib/dev/zyra_one_journey_concept_shell.dart',
      ).readAsStringSync();
      final circleStart = source.indexOf('Widget _guardianCircle()');
      final resolverStart = source.indexOf(
        'ZyraCircleDiscussionArchive? discussionArchiveFor(',
        circleStart,
      );
      final resolverEnd = source.indexOf(
        'SeekerProfile? discussionProfileFor(',
        resolverStart,
      );
      expect(resolverStart, greaterThan(circleStart));
      expect(resolverEnd, greaterThan(resolverStart));
      final resolver = source
          .substring(resolverStart, resolverEnd)
          .replaceAll(RegExp(r'\s+'), ' ');
      expect(resolver, contains('!current()'));
      // Owned controls may cover the chat without removing data ownership;
      // actual route/foreground interaction remains separately guarded.
      expect(resolver, isNot(contains("_page != 'guardian_circle'")));
      expect(resolver, contains('identical(known, topic)'));
      expect(resolver, contains('return pastArchives[topic.id]'));
      expect(resolver, isNot(contains('_displayProfile')));
      expect(resolver, isNot(contains('Service')));
      expect(
        source.substring(resolverEnd),
        contains('previewDiscussionArchiveFor: discussionArchiveFor'),
        reason: 'The resolver is captured once before the owned route builder.',
      );
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} can view only an explicitly supplied past summary and return to the same Circle',
      (tester) async {
        final fixture = _Fixture(guardian: guardian, withArchiveResolver: true);
        await _mount(tester, fixture);
        await _select(tester, 'draft-circle-past-elif', past: true);
        await _send(tester, 'This discussion remains in our one Circle');
        await tester.enterText(_composer, 'The draft survives the archive');
        final state = tester.state(find.byType(ZyraGuardianCircleScreen));
        final controller = tester.widget<TextField>(_composer).controller!;
        expect(find.text('Discussing'), findsOneWidget);
        expect(find.text('Journey with Elif'), findsOneWidget);
        expect(find.text('Past Journey · Ended 10 Oct 2026'), findsOneWidget);
        expect(find.text('View profile'), findsNothing);
        expect(
          tester
              .getSize(_key('circle_discussion_journey_draft-circle-past-elif'))
              .height,
          greaterThanOrEqualTo(44),
        );
        await _capture(
          tester,
          'archive-${guardian ? 'guardian' : 'seeker'}-marker',
        );
        await _press(
          tester,
          _key('circle_discussion_journey_draft-circle-past-elif'),
        );
        final child = tester.widget<ZyraCircleDiscussionArchiveView>(
          find.byType(ZyraCircleDiscussionArchiveView),
        );
        expect(
          _key('circle_discussion_archive_draft-circle-past-elif'),
          findsOneWidget,
        );
        expect(child.archive, same(fixture.archive));
        expect(child.canAct(), isTrue);
        expect(find.text('Journey started'), findsOneWidget);
        expect(find.text('Journey ended'), findsOneWidget);
        expect(find.text('This Journey is archived.'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(SeekerProfileScreen), findsNothing);
        expect(find.text('Start Journey'), findsNothing);
        expect(find.text('Request a Journey'), findsNothing);
        expect(fixture.resolved, isEmpty);
        expect(fixture.contextOpens, 0);
        expect(
          fixture.resolvedArchives.every(
            (topic) => identical(topic, fixture.past.single),
          ),
          isTrue,
        );
        await _capture(
          tester,
          'archive-${guardian ? 'guardian' : 'seeker'}-child',
        );
        await _press(tester, _key('circle_discussion_archive_close'));
        expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
        expect(
          tester.state(find.byType(ZyraGuardianCircleScreen)),
          same(state),
        );
        expect(
          tester.widget<TextField>(_composer).controller,
          same(controller),
        );
        expect(controller.text, 'The draft survives the archive');
        expect(
          find.text('This discussion remains in our one Circle'),
          findsOneWidget,
        );
        expect(_marker('draft-circle-past-elif'), findsOneWidget);
        expect(fixture.data.messages.length, 2);
        expect(fixture.contextOpens, 0);
        await _capture(
          tester,
          'archive-${guardian ? 'guardian' : 'seeker'}-return',
        );
      },
    );
  }

  for (final resolution in [
    'no resolver',
    'null',
    'throw',
    'wrong id',
    'wrong name',
    'wrong ended date',
    'starts after end',
  ]) {
    testWidgets(
      '$resolution leaves the past discussion visible without creating an archive action',
      (tester) async {
        final fixture = _Fixture(
          withArchiveResolver: resolution != 'no resolver',
        )..archiveResolution = resolution;
        await _mount(tester, fixture);
        await _commit(tester, 'draft-circle-past-elif', past: true);
        expect(_marker('draft-circle-past-elif'), findsOneWidget);
        expect(find.text('Journey with Elif'), findsOneWidget);
        expect(find.text('View Journey'), findsNothing);
        expect(find.text('View profile'), findsNothing);
        expect(
          tester.widget<ZyraCircleDiscussionBubble>(_bubbles).onViewJourney,
          isNull,
        );
        expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
        expect(fixture.resolved, isEmpty);
        expect(fixture.contextOpens, 0);
      },
    );
  }

  testWidgets(
    'Current sent markers and picker dismissal never consult the separate past archive resolver',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _commit(tester, 'draft-sara');
      await _dismissAndRemovePending(tester);
      expect(fixture.resolvedArchives, isEmpty);
      expect(find.text('View Journey'), findsNothing);
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
      expect(fixture.contextOpens, 0);
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      'Basic ${guardian ? 'Guardian' : 'Seeker'} cannot consult a supplied archive capability',
      (tester) async {
        final fixture = _Fixture(
          guardian: guardian,
          funded: false,
          withArchiveResolver: true,
        );
        await _mount(tester, fixture);
        expect(_composer, findsNothing);
        expect(_bubbles, findsNothing);
        expect(find.text('View Journey'), findsNothing);
        expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
        expect(fixture.resolvedArchives, isEmpty);
      },
    );
  }

  testWidgets(
    'busy sending denies a retained archive action without changing the original Circle send',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _commit(tester, 'draft-circle-past-elif', past: true);
      final open = _archiveCallback(tester);
      await _select(tester, 'draft-circle-past-elif', past: true);
      await tester.enterText(_composer, 'This pending send stays with Elif');
      await tester.tap(_circleButton('Send message'));
      await tester.pump(const Duration(milliseconds: 20));
      open();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('This pending send stays with Elif'), findsOneWidget);
      expect(_key('circle_topic_tag_draft-circle-past-elif'), findsNWidgets(2));
      expect(_marker('draft-circle-past-elif'), findsNWidgets(2));
      expect(_pending, findsNothing);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'owned archive swipe Back returns once to the unchanged ongoing Circle',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _commit(tester, 'draft-circle-past-elif', past: true);
      await tester.enterText(_composer, 'A draft survives archive swipe Back');
      final state = tester.state(find.byType(ZyraGuardianCircleScreen));
      await _press(
        tester,
        _key('circle_discussion_journey_draft-circle-past-elif'),
      );
      final edge = _key('zyra_back_swipe_edge');
      expect(edge.hitTestable(), findsOneWidget);
      final rect = tester.getRect(edge);
      await tester.timedDragFrom(
        Offset(rect.left + 1, rect.top + 65),
        const Offset(230, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
      expect(tester.state(find.byType(ZyraGuardianCircleScreen)), same(state));
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'A draft survives archive swipe Back',
      );
      expect(_marker('draft-circle-past-elif'), findsOneWidget);
      expect(fixture.contextOpens, 0);
    },
  );

  for (final denial in ['permission', 'different object', 'foreground']) {
    testWidgets(
      'retained archive callback rechecks $denial rather than opening stale past data',
      (tester) async {
        final fixture = _Fixture(withArchiveResolver: true);
        await _mount(tester, fixture);
        await _commit(tester, 'draft-circle-past-elif', past: true);
        final open = _archiveCallback(tester);
        if (denial == 'permission') fixture.archivePermitted = false;
        if (denial == 'different object') {
          fixture.archiveResolution = 'different object';
        }
        if (denial == 'foreground') fixture.visibility.value = false;
        open();
        await tester.pumpAndSettle();
        expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
        expect(_marker('draft-circle-past-elif'), findsOneWidget);
        fixture.archivePermitted = true;
        fixture.archiveResolution = 'valid';
        fixture.visibility.value = true;
        await tester.pumpAndSettle();
        open();
        await tester.pumpAndSettle();
        expect(find.byType(ZyraCircleDiscussionArchiveView), findsOneWidget);
        await _press(tester, _key('circle_discussion_archive_close'));
        expect(_composer, findsOneWidget);
        expect(fixture.resolved, isEmpty);
      },
    );
  }

  for (final withdrawal in ['caller', 'developer']) {
    testWidgets(
      '$withdrawal withdrawal permanently denies retained archive callbacks after restoration',
      (tester) async {
        final fixture = _Fixture(withArchiveResolver: true);
        await _mount(tester, fixture);
        await _commit(tester, 'draft-circle-past-elif', past: true);
        final open = _archiveCallback(tester);
        if (withdrawal == 'caller') {
          fixture.owner = false;
          open();
          fixture.owner = true;
        } else {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        }
        open();
        await tester.pumpAndSettle();
        expect(_bubbles, findsNothing);
        expect(_composer, findsNothing);
        expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
        expect(fixture.contextOpens, 0);
      },
    );
  }

  testWidgets(
    'replacing the captured archive resolver withdraws the Circle instead of retargeting old cards',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _commit(tester, 'draft-circle-past-elif', past: true);
      final open = _archiveCallback(tester);
      await tester.pumpWidget(
        _app(
          fixture.screen(replacementArchiveResolver: (_) => fixture.archive),
        ),
      );
      await tester.pumpAndSettle();
      open();
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(fixture.screen()));
      await tester.pumpAndSettle();
      expect(_bubbles, findsNothing);
      expect(_composer, findsNothing);
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
    },
  );

  testWidgets(
    'owned archive close cannot dismiss an unrelated covering route',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _commit(tester, 'draft-circle-past-elif', past: true);
      await _press(
        tester,
        _key('circle_discussion_journey_draft-circle-past-elif'),
      );
      final close = tester
          .widget<IconButton>(_key('circle_discussion_archive_close'))
          .onPressed!;
      final navigator = Navigator.of(
        tester.element(find.byType(ZyraCircleDiscussionArchiveView)),
      );
      final cover = MaterialPageRoute<void>(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('Other route'))),
      );
      navigator.push(cover);
      await tester.pumpAndSettle();
      close();
      await tester.pumpAndSettle();
      expect(cover.isCurrent, isTrue);
      expect(find.text('Other route'), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(_key('circle_discussion_archive_close'), findsOneWidget);
      close();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
      expect(_composer, findsOneWidget);
    },
  );

  testWidgets(
    'covering page options denies interaction without revoking the owned archive',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _commit(tester, 'draft-circle-past-elif', past: true);
      await _press(
        tester,
        _key('circle_discussion_journey_draft-circle-past-elif'),
      );
      final child = tester.widget<ZyraCircleDiscussionArchiveView>(
        find.byType(ZyraCircleDiscussionArchiveView),
      );
      final close = tester
          .widget<IconButton>(_key('circle_discussion_archive_close'))
          .onPressed!;
      fixture.visibility.value = false;
      await tester.pumpAndSettle();
      expect(child.canAct(), isTrue);
      close();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsOneWidget);
      fixture.visibility.value = true;
      await tester.pumpAndSettle();
      await _press(tester, _key('circle_discussion_archive_close'));
      expect(_composer, findsOneWidget);
      expect(_marker('draft-circle-past-elif'), findsOneWidget);
    },
  );

  testWidgets('owned archive rebuild preserves the same chat and draft', (
    tester,
  ) async {
    final fixture = _Fixture(withArchiveResolver: true);
    await _mount(tester, fixture);
    await _commit(tester, 'draft-circle-past-elif', past: true);
    await tester.enterText(_composer, 'The same draft after returning');
    final circle = tester.state(find.byType(ZyraGuardianCircleScreen));
    await _press(
      tester,
      _key('circle_discussion_journey_draft-circle-past-elif'),
    );
    final archive = tester.state(find.byType(ZyraCircleDiscussionArchiveView));
    tester
        .element(find.byType(ZyraCircleDiscussionArchiveView))
        .markNeedsBuild();
    await tester.pumpAndSettle();
    expect(
      tester.state(find.byType(ZyraCircleDiscussionArchiveView)),
      same(archive),
    );
    expect(
      tester.widget<Text>(find.text('Past Journey')).style!.color,
      ZyraColors.journeyGold,
    );
    await _capture(tester, 'archive-rebuilt-child');
    await _press(tester, _key('circle_discussion_archive_close'));
    expect(tester.state(find.byType(ZyraGuardianCircleScreen)), same(circle));
    expect(
      tester.widget<TextField>(_composer).controller!.text,
      'The same draft after returning',
    );
    await _capture(tester, 'archive-rebuilt-return');
  });

  testWidgets(
    'archive permission loss blanks the protected child and denies retained close',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _commit(tester, 'draft-circle-past-elif', past: true);
      await _press(
        tester,
        _key('circle_discussion_journey_draft-circle-past-elif'),
      );
      final close = tester
          .widget<IconButton>(_key('circle_discussion_archive_close'))
          .onPressed!;
      final route = ModalRoute.of(
        tester.element(find.byType(ZyraCircleDiscussionArchiveView)),
      )!;
      fixture.archivePermitted = false;
      close();
      await tester.pumpAndSettle();
      expect(route.isCurrent, isTrue);
      expect(find.text('Journey started'), findsNothing);
      expect(_key('circle_discussion_archive_close'), findsNothing);
      expect(_composer, findsNothing);
    },
  );

  testWidgets(
    'developer withdrawal removes the owned archive and old discussion cards',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _commit(tester, 'draft-circle-past-elif', past: true);
      await _press(
        tester,
        _key('circle_discussion_journey_draft-circle-past-elif'),
      );
      final close = tester
          .widget<IconButton>(_key('circle_discussion_archive_close'))
          .onPressed!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      close();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
      expect(_bubbles, findsNothing);
      expect(_composer, findsNothing);
      expect(fixture.contextOpens, 0);
    },
  );

  testWidgets(
    'past discussion action and read-only archive remain reachable at 320 wide with 200 percent text',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture, size: const Size(320, 852), scale: 2);
      await _commit(tester, 'draft-circle-past-elif', past: true);
      expect(find.text('Discussing'), findsOneWidget);
      expect(find.text('Past Journey · Ended 10 Oct 2026'), findsOneWidget);
      await _capture(tester, 'archive-small-large-text-marker');
      await _press(
        tester,
        _key('circle_discussion_journey_draft-circle-past-elif'),
      );
      expect(find.text('Journey started'), findsOneWidget);
      expect(find.text('Journey ended'), findsOneWidget);
      await _capture(tester, 'archive-small-large-text-child');
      await _press(tester, _key('circle_discussion_archive_close'));
      expect(_marker('draft-circle-past-elif'), findsOneWidget);
      expect(_composer, findsOneWidget);
      await _capture(tester, 'archive-small-large-text-return');
    },
  );

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    final ownId = guardian ? 'draft-circle-first' : 'draft-circle-second';
    final otherId = guardian ? 'draft-circle-second' : 'draft-circle-first';

    testWidgets(
      '$role links only one own message without changing the draft or composer topic',
      (tester) async {
        final fixture = _Fixture(guardian: guardian, withArchiveResolver: true);
        await _mount(tester, fixture);
        final state = tester.state(find.byType(ZyraGuardianCircleScreen));
        await _select(tester, 'draft-sara');
        await tester.enterText(
          _composer,
          'Keep this draft and its original Journey',
        );
        final controller = tester.widget<TextField>(_composer).controller!;
        final original = List.of(fixture.data.messages);
        await _openMessageReference(tester, ownId);
        await _select(tester, 'draft-circle-past-elif', past: true);
        expect(_messageTag(ownId), findsOneWidget);
        expect(
          tester.widget<ZyraCircleTopicTag>(_messageTag(ownId)).topic.firstName,
          'Elif',
        );
        expect(_messageTag(otherId), findsNothing);
        expect(_bubbles, findsNothing);
        expect(_pending, findsOneWidget);
        expect(_marker('draft-sara'), findsNothing);
        expect(_marker('draft-circle-past-elif'), findsNothing);
        expect(find.text('Now discussing'), findsNothing);
        expect(find.text('Discussing'), findsNothing);
        expect(
          tester
              .widget<ZyraCircleDiscussLauncher>(
                find.byType(ZyraCircleDiscussLauncher),
              )
              .topic
              .id,
          'draft-sara',
        );
        expect(
          tester.state(find.byType(ZyraGuardianCircleScreen)),
          same(state),
        );
        expect(
          tester.widget<TextField>(_composer).controller,
          same(controller),
        );
        expect(controller.text, 'Keep this draft and its original Journey');
        for (var index = 0; index < original.length; index++) {
          expect(fixture.data.messages[index], same(original[index]));
          expect(find.text(original[index].body), findsOneWidget);
        }
        expect(
          fixture.resolvedArchives,
          isEmpty,
          reason: 'A message label is not an archive lookup',
        );
        expect(fixture.contextOpens, 0);
        await _capture(tester, 'message-reference-${role.toLowerCase()}');
        await _send(tester, 'The next message still uses Sara');
        expect(
          tester
              .widget<ZyraCircleTopicTag>(_messageTag('dev-family-3'))
              .topic
              .id,
          'draft-sara',
        );
        expect(
          tester.widget<ZyraCircleTopicTag>(_messageTag(ownId)).topic.id,
          'draft-circle-past-elif',
        );
      },
    );

    testWidgets(
      '$role can replace or remove only the selected message reference',
      (tester) async {
        final fixture = _Fixture(guardian: guardian);
        await _mount(tester, fixture);
        await _openMessageReference(tester, ownId);
        await _select(tester, 'draft-sara');
        await _openMessageReference(tester, ownId);
        await _select(tester, 'draft-sara');
        expect(_messageTag(ownId), findsOneWidget);
        await _openMessageReference(tester, ownId);
        await _select(tester, 'draft-circle-past-elif', past: true);
        expect(
          tester.widget<ZyraCircleTopicTag>(_messageTag(ownId)).topic.id,
          'draft-circle-past-elif',
        );
        await _openMessageReference(tester, ownId);
        await _select(tester, 'general');
        expect(_messageTag(ownId), findsNothing);
        expect(_messageTag(otherId), findsNothing);
        expect(_bubbles, findsNothing);
        expect(
          tester
              .widget<ZyraCircleDiscussLauncher>(
                find.byType(ZyraCircleDiscussLauncher),
              )
              .topic
              .isGeneral,
          isTrue,
        );
        expect(fixture.resolved, isEmpty);
        expect(fixture.resolvedArchives, isEmpty);
        expect(fixture.contextOpens, 0);
      },
    );

    testWidgets(
      '$role cannot relabel another member and still has the Report action',
      (tester) async {
        final fixture = _Fixture(guardian: guardian);
        await _mount(tester, fixture);
        await _holdMessage(tester, otherId);
        expect(_key('circle_message_link_$otherId'), findsNothing);
        expect(find.text('Report this message'), findsOneWidget);
        Navigator.of(tester.element(find.text('Report this message'))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(ZyraCircleTopicPicker), findsNothing);
        expect(_messageTag(otherId), findsNothing);
        expect(fixture.contextOpens, 0);
      },
    );
  }

  testWidgets(
    'cancelling the message menu or picker changes nothing and does not disable later linking',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await tester.enterText(_composer, 'Unsent draft stays here');
      await _holdMessage(tester, 'draft-circle-second');
      Navigator.of(
        tester.element(_key('circle_message_link_draft-circle-second')),
      ).pop();
      await tester.pumpAndSettle();
      await _openMessageReference(tester, 'draft-circle-second');
      Navigator.of(tester.element(find.byType(ZyraCircleTopicPicker))).pop();
      await tester.pumpAndSettle();
      expect(_messageTag('draft-circle-second'), findsNothing);
      expect(_bubbles, findsNothing);
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'Unsent draft stays here',
      );
      await _openMessageReference(tester, 'draft-circle-second');
      await _select(tester, 'draft-sara');
      expect(_messageTag('draft-circle-second'), findsOneWidget);
    },
  );

  for (final denied in ['Basic', 'No local discussion adapter']) {
    testWidgets('$denied never offers a local own-message Journey link', (
      tester,
    ) async {
      final fixture = _Fixture(
        funded: denied != 'Basic',
        discussionEnabled: denied != 'No local discussion adapter',
      );
      await _mount(tester, fixture);
      await _holdMessage(tester, 'draft-circle-second');
      expect(find.text('Link a Journey'), findsNothing);
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(_messageTag('draft-circle-second'), findsNothing);
    });
  }

  for (final kind in ['lifecycle', 'existing context']) {
    testWidgets('$kind records cannot be rewritten as message references', (
      tester,
    ) async {
      final fixture = _Fixture(
        suppliedMessages: [
          ZyraFamilyMessage(
            id: 'immutable-message',
            senderId: 'draft-self',
            senderFirstName: 'Adam',
            body: 'Original immutable record',
            createdAt: DateTime.utc(2026, 10, 13),
            lifecycle: kind == 'lifecycle',
            context: kind == 'existing context' ? _sara : null,
          ),
        ],
      );
      await _mount(tester, fixture);
      await tester.longPress(find.text('Original immutable record'));
      await tester.pumpAndSettle();
      expect(find.text('Link a Journey'), findsNothing);
      expect(find.byType(ZyraCircleTopicPicker), findsNothing);
      expect(find.byType(ZyraCircleTopicTag), findsNothing);
      expect(
        fixture.data.messages.single.context,
        kind == 'existing context' ? same(_sara) : isNull,
      );
    });
  }

  for (final change in ['owner', 'developer', 'visibility', 'design']) {
    testWidgets(
      'an open message picker cannot apply after $change withdrawal and restoration',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await _openMessageReference(tester, 'draft-circle-second');
        final picker = tester.widget<ZyraCircleTopicPicker>(
          find.byType(ZyraCircleTopicPicker),
        );
        switch (change) {
          case 'owner':
            fixture.owner = false;
            expect(picker.canSelect(), isFalse);
            fixture.owner = true;
          case 'developer':
            ZyraDeveloperAccess.setAuthorizedForTesting(false);
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          case 'visibility':
            fixture.visibility.value = false;
            fixture.visibility.value = true;
          case 'design':
            fixture.bubbleDesign.value = ZyraCircleBubbleDesign.quietList;
            fixture.bubbleDesign.value = ZyraCircleBubbleDesign.current;
        }
        picker.onSelected(picker.currentTopics.single);
        await tester.pumpAndSettle();
        expect(_messageTag('draft-circle-second'), findsNothing);
        expect(_bubbles, findsNothing);
        expect(fixture.contextOpens, 0);
        if (find.byType(ZyraCircleTopicPicker).evaluate().isNotEmpty) {
          Navigator.of(
            tester.element(find.byType(ZyraCircleTopicPicker)),
          ).pop();
          await tester.pumpAndSettle();
        }
      },
    );
  }

  for (final change in ['visibility', 'design']) {
    testWidgets(
      'a retained message-menu action is stale after $change changes',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await _holdMessage(tester, 'draft-circle-second');
        final choose = tester
            .widget<ListTile>(_key('circle_message_link_draft-circle-second'))
            .onTap!;
        if (change == 'visibility') {
          fixture.visibility.value = false;
          fixture.visibility.value = true;
        } else {
          fixture.bubbleDesign.value = ZyraCircleBubbleDesign.quietList;
          fixture.bubbleDesign.value = ZyraCircleBubbleDesign.current;
        }
        await tester.pumpAndSettle();
        choose();
        await tester.pumpAndSettle();
        expect(find.byType(ZyraCircleTopicPicker), findsNothing);
        expect(_messageTag('draft-circle-second'), findsNothing);
        await _openMessageReference(tester, 'draft-circle-second');
        await _select(tester, 'draft-sara');
        expect(_messageTag('draft-circle-second'), findsOneWidget);
      },
    );
  }

  testWidgets('a covered message-menu callback cannot dismiss another route', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    await _holdMessage(tester, 'draft-circle-second');
    final element = tester.element(
      _key('circle_message_link_draft-circle-second'),
    );
    final choose = tester
        .widget<ListTile>(_key('circle_message_link_draft-circle-second'))
        .onTap!;
    final navigator = Navigator.of(element);
    final cover = MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Unrelated covering page')),
    );
    navigator.push(cover);
    await tester.pumpAndSettle();
    choose();
    await tester.pumpAndSettle();
    expect(cover.isCurrent, isTrue);
    expect(find.text('Unrelated covering page'), findsOneWidget);
    expect(find.byType(ZyraCircleTopicPicker), findsNothing);
    navigator.pop();
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'an unknown selected Journey cannot be attached or grant a destination',
    (tester) async {
      final fixture = _Fixture(withArchiveResolver: true);
      await _mount(tester, fixture);
      await _openMessageReference(tester, 'draft-circle-second');
      final picker = tester.widget<ZyraCircleTopicPicker>(
        find.byType(ZyraCircleTopicPicker),
      );
      picker.onSelected(
        const ZyraCircleDiscussionTopic(
          id: 'unadmitted-person',
          firstName: 'Not admitted',
          kind: ZyraCircleTopicKind.current,
        ),
      );
      await tester.pumpAndSettle();
      expect(_messageTag('draft-circle-second'), findsNothing);
      expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
      expect(fixture.resolved, isEmpty);
      expect(fixture.resolvedArchives, isEmpty);
      Navigator.of(tester.element(find.byType(ZyraCircleTopicPicker))).pop();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'preview send IDs cannot collide with a foreign transcript and tag another sender',
    (tester) async {
      final fixture = _Fixture(
        suppliedMessages: [
          ZyraFamilyMessage(
            id: 'dev-family-2',
            senderId: 'draft-hassan',
            senderFirstName: 'Hassan',
            body: 'Foreign message keeps its identity',
            createdAt: DateTime.utc(2026, 10, 13),
          ),
        ],
      );
      await _mount(tester, fixture);
      await _send(tester, 'My new own message');
      expect(_message('dev-family-2'), findsOneWidget);
      expect(_message('dev-family-3'), findsOneWidget);
      await _openMessageReference(tester, 'dev-family-3');
      await _select(tester, 'draft-sara');
      expect(_messageTag('dev-family-2'), findsNothing);
      expect(_messageTag('dev-family-3'), findsOneWidget);
      expect(find.text('Foreign message keeps its identity'), findsOneWidget);
      expect(fixture.data.messages.single.id, 'dev-family-2');
      expect(fixture.contextOpens, 0);
    },
  );

  for (final compact in [false, true]) {
    testWidgets(
      'own-message Journey reference fits ${compact ? '320-wide 200-percent' : '393-wide normal'} current view',
      (tester) async {
        final fixture = _Fixture();
        await _mount(
          tester,
          fixture,
          size: Size(compact ? 320 : 393, 852),
          scale: compact ? 2 : 1,
        );
        await _holdMessage(tester, 'draft-circle-second');
        expect(
          _key('circle_message_link_draft-circle-second').hitTestable(),
          findsOneWidget,
        );
        await _capture(
          tester,
          'message-reference-${compact ? 'compact' : 'normal'}-menu',
        );
        await _press(tester, _key('circle_message_link_draft-circle-second'));
        await _select(tester, 'draft-circle-past-elif', past: true);
        expect(_messageTag('draft-circle-second'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          'message-reference-${compact ? 'compact' : 'normal'}-result',
        );
      },
    );
  }
}
