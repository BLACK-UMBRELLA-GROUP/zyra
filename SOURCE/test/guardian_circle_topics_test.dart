// LOCK 20 Topics over caller-owned, already-admitted local Circle fixtures.
// No fixture below establishes membership, history consent or server access.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_circle_discussion_archive.dart';
import 'package:zyra/dev/zyra_circle_topics_presentation.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_family_sheet.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _sara = ZyraFamilyMessageContext(
  referenceId: 'draft-sara',
  firstName: 'Sara',
  kind: ZyraFamilyMessageContextKind.active,
);
const _aisha = ZyraFamilyMessageContext(
  referenceId: 'draft-aisha',
  firstName: 'Aisha',
  kind: ZyraFamilyMessageContextKind.active,
);
const _current = [_sara, _aisha];
final _ended = DateTime.utc(2026, 10, 2);
final _now = DateTime.utc(2026, 11, 1);

Finder _key(String id) => find.byKey(ValueKey('circle_topics_$id'));
Finder get _composer => _key('composer');

class _Offline extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Topics fixtures must remain offline.');
  }
}

class _Fixture {
  _Fixture({
    this.guardian = false,
    this.basic = false,
    this.historyShared = true,
    List<ZyraFamilyMessageContext> contexts = _current,
    List<ZyraFamilyMessage>? messages,
    Map<String, ZyraCircleDiscussionTopic> messageTopics = const {},
    DateTime? now,
    Map<String, ZyraCircleDiscussionTopic> transcriptTags = const {},
  }) : now = now ?? _now {
    data = ZyraGuardianCirclePreviewData(
      seekerId: 'draft-self',
      senderId: guardian ? 'draft-hassan' : 'draft-self',
      // This is the admitted per-member fixture result, never an entitlement
      // inferred by the Topics presentation from another Circle participant.
      canSend: !basic,
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
        const ZyraFamilyCircleParticipant(
          userId: 'draft-yusuf',
          firstName: 'Yusuf',
          memberRole: 'guardian',
          isMainGuardian: false,
          isCurrentUser: false,
        ),
      ],
      contexts: contexts,
      messages:
          messages ??
          [
            _message('general', 'Family support without a Journey'),
            if (contexts.contains(_sara))
              _message('sara', 'A question about Sara', context: _sara),
            if (contexts.contains(_aisha))
              _message('aisha', 'A question about Aisha', context: _aisha),
          ],
    );
    past = !guardian || historyShared
        ? [
            ZyraCircleDiscussionTopic(
              id: 'draft-circle-past-elif',
              firstName: 'Elif',
              kind: ZyraCircleTopicKind.past,
              endedOn: _ended,
              sharedSummaryLabel: guardian ? 'Adam & Elif' : null,
            ),
          ]
        : [];
    topics = ZyraCircleTopicsPreview(
      tiles: [
        for (final context in contexts)
          ZyraCircleTopicTile(
            id: context.referenceId,
            name: context.firstName,
            stage: 'Getting to know each other',
          ),
        for (final topic in past)
          ZyraCircleTopicTile(
            id: topic.id,
            name: topic.firstName,
            // A Guardian must never resolve or render the past photo.
            photo: guardian ? 'preview-photo-that-must-not-be-opened' : null,
          ),
      ],
      readOnlyParticipantIds: ['draft-yusuf', if (basic) 'draft-hassan'],
      guardianBasic: guardian && basic,
      onManageGuardians: _manage,
      onMembership: _membership,
      clock: () => this.now,
      messageTopics: {...messageTopics, ...transcriptTags},
    );
  }

  final bool guardian, basic, historyShared;
  DateTime now;
  late final ZyraGuardianCirclePreviewData data;
  late final List<ZyraCircleDiscussionTopic> past;
  late final ZyraCircleTopicsPreview topics;
  final design = ValueNotifier(ZyraCircleBubbleDesign.current);
  final visibility = ValueNotifier(true);
  bool owner = true;
  int manages = 0, memberships = 0;
  final opened = <ZyraFamilyMessageContext>[];
  // Keep one exact authority closure for the fixture lifetime.
  // ignore: prefer_function_declarations_over_variables
  late final bool Function() ownerGuard = () => owner;
  // ignore: prefer_function_declarations_over_variables
  late final bool Function() foregroundGuard = () => visibility.value;
  late final ValueChanged<ZyraFamilyMessageContext> openContext = opened.add;
  late final ZyraCircleDiscussionArchive? Function(ZyraCircleDiscussionTopic)
  // ignore: prefer_function_declarations_over_variables
  archiveFor = (topic) => past.any((known) => identical(known, topic))
      ? ZyraCircleDiscussionArchive(
          topicId: topic.id,
          firstName: topic.firstName,
          startedOn: DateTime.utc(2026, 9, 12),
          endedOn: _ended,
          sharedSummaryLabel: topic.sharedSummaryLabel,
        )
      : null;

  void _manage() => manages++;
  void _membership() => memberships++;

  ZyraGuardianCircleScreen screen({
    ZyraGuardianCirclePreviewData? replacementData,
    ZyraCircleTopicsPreview? replacementTopics,
    ValueNotifier<ZyraCircleBubbleDesign>? replacementDesign,
    bool? viewerIsSeeker,
    String seekerId = 'draft-self',
  }) => ZyraGuardianCircleScreen(
    key: const ValueKey('topics-owner'),
    seekerId: seekerId,
    seekerFirstName: 'Adam',
    viewerIsSeeker: viewerIsSeeker ?? !guardian,
    preview: true,
    previewData: replacementData ?? data,
    previewTopics: replacementTopics ?? topics,
    previewBubbleDesign: replacementDesign ?? design,
    previewPastTopics: past,
    previewForeground: foregroundGuard,
    previewVisibility: visibility,
    previewDiscussionArchiveFor: archiveFor,
    canAct: ownerGuard,
    onOpenContext: openContext,
  );
}

ZyraFamilyMessage _message(
  String id,
  String body, {
  ZyraFamilyMessageContext? context,
  DateTime? date,
  bool unread = false,
}) => ZyraFamilyMessage(
  id: 'draft-message-$id',
  senderId: 'draft-hassan',
  senderFirstName: 'Hassan',
  senderRoleLabel: 'Main Guardian',
  body: body,
  createdAt: date ?? _now.subtract(const Duration(hours: 1)),
  context: context,
  unreadForMe: unread,
);

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: child,
);

Future<void> _mount(WidgetTester tester, _Fixture fixture) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(fixture.design.dispose);
  addTearDown(fixture.visibility.dispose);
  expect(
    fixture.data.validFor('draft-self', viewerIsSeeker: !fixture.guardian),
    isTrue,
  );
  await tester.pumpWidget(_app(fixture.screen()));
  await tester.pumpAndSettle();
  expect(find.byType(ZyraCircleTopicsPresentation), findsOneWidget);
  expect(tester.takeException(), isNull);
}

ZyraCircleTopicsPresentation _view(WidgetTester tester) =>
    tester.widget(find.byType(ZyraCircleTopicsPresentation));
List<String> _bodies(WidgetTester tester) =>
    _view(tester).messages.map((item) => item.message.body).toList();

Future<void> _press(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  if (find
      .ancestor(of: finder, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

VoidCallback _retained(WidgetTester tester, String id, bool semantics) {
  final target = _key(id);
  return semantics
      ? tester.widget<Semantics>(target).properties.onTap!
      : tester
            .widget<GestureDetector>(
              find.descendant(
                of: target,
                matching: find.byType(GestureDetector),
              ),
            )
            .onTap!;
}

Future<void> _send(WidgetTester tester, String body) async {
  await tester.enterText(_composer, body);
  await _press(tester, _key('send'));
  expect(_bodies(tester), contains(body));
  expect(tester.widget<TextField>(_composer).controller!.text, isEmpty);
}

void main() {
  late _Offline offline;
  HttpOverrides? previousNetwork;
  var haptics = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = true;
    previousNetwork = HttpOverrides.current;
    offline = _Offline();
    HttpOverrides.global = offline;
    haptics = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics++;
          return null;
        });
  });

  tearDown(() {
    expect(offline.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'All contains the current transcript and preserves existing About links',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      expect(_bodies(tester), [
        'Family support without a Journey',
        'A question about Sara',
        'A question about Aisha',
      ]);
      expect(_view(tester).messages.map((item) => item.about), [
        null,
        'Sara',
        'Aisha',
      ]);
      expect(find.text('About Sara'), findsOneWidget);
      expect(find.text('About Aisha'), findsOneWidget);
      expect(find.textContaining('member'), findsNothing);
      expect(_key('topic_draft-sara'), findsOneWidget);
      expect(_key('topic_draft-aisha'), findsOneWidget);
    },
  );

  testWidgets(
    'Journey sends retain exact About ownership; All sends remain untagged',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _press(tester, _key('topic_draft-sara'));
      expect(_bodies(tester), ['A question about Sara']);
      await _press(tester, _key('view_journey'));
      expect(fixture.opened.single, same(_sara));
      await _send(tester, 'A new Sara discussion');
      expect(_view(tester).messages.last.about, 'Sara');
      await _press(tester, _key('all'));
      expect(
        _view(tester).messages
            .singleWhere((item) => item.message.body == 'A new Sara discussion')
            .about,
        'Sara',
      );
      await _send(tester, 'A family wide message');
      expect(_view(tester).messages.last.about, isNull);
      await _press(tester, _key('topic_draft-aisha'));
      expect(_bodies(tester), ['A question about Aisha']);
      await _press(tester, _key('topic_draft-sara'));
      expect(_bodies(tester), [
        'A question about Sara',
        'A new Sara discussion',
      ]);
    },
  );

  testWidgets(
    'existing local discussion map filters its exact Journey without inventing a message context',
    (tester) async {
      const topic = ZyraCircleDiscussionTopic(
        id: 'draft-sara',
        firstName: 'Sara',
        kind: ZyraCircleTopicKind.current,
      );
      final fixture = _Fixture(
        messages: [
          _message('general', 'An ordinary family message'),
          _message('linked', 'A retained local Sara discussion'),
        ],
        messageTopics: const {'draft-message-linked': topic},
      );
      await _mount(tester, fixture);
      expect(_view(tester).messages.last.about, 'Sara');
      expect(_view(tester).messages.last.message.context, isNull);
      await _press(tester, _key('topic_draft-sara'));
      expect(_bodies(tester), ['A retained local Sara discussion']);
      await _press(tester, _key('topic_draft-aisha'));
      expect(_bodies(tester), isEmpty);
      expect(
        find.text('No messages about Aisha yet.\nStart the discussion below.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'empty family has All and meaningful empty state without invented Journeys',
    (tester) async {
      final fixture = _Fixture(
        contexts: const [],
        messages: const [],
        historyShared: false,
        guardian: true,
      );
      await _mount(tester, fixture);
      expect(find.text('Talk about your search'), findsOneWidget);
      expect(_view(tester).current, isEmpty);
      expect(_view(tester).past, isEmpty);
      expect(_key('past'), findsNothing);
      expect(_composer, findsOneWidget);
      await _send(tester, 'Our first family message');
      expect(_view(tester).messages.single.about, isNull);
    },
  );

  testWidgets(
    'Guardian input exposes only current Journeys already allowed by View',
    (tester) async {
      final fixture = _Fixture(guardian: true, contexts: const [_sara]);
      await _mount(tester, fixture);
      expect(_key('topic_draft-sara'), findsOneWidget);
      expect(_key('topic_draft-aisha'), findsNothing);
      await _press(tester, _key('topic_draft-sara'));
      await _press(tester, _key('view_journey'));
      expect(fixture.opened.single, same(_sara));
      await _send(tester, 'Guardian One speaks about the admitted Journey');
      expect(_view(tester).messages.last.message.senderId, 'draft-hassan');
      expect(_view(tester).messages.last.about, 'Sara');
    },
  );

  testWidgets(
    'Guardian history sharing off supplies no Past topic or archive entry',
    (tester) async {
      final fixture = _Fixture(guardian: true, historyShared: false);
      await _mount(tester, fixture);
      expect(_key('past'), findsNothing);
      expect(_view(tester).past, isEmpty);
      expect(find.text('Adam & Elif'), findsNothing);
      expect(_composer, findsOneWidget);
    },
  );

  for (final day in [30, 31]) {
    testWidgets(
      'past discussion day $day uses the actual end date and closes after day 30',
      (tester) async {
        final fixture = _Fixture(now: _ended.add(Duration(days: day)));
        await _mount(tester, fixture);
        await _press(tester, _key('past'));
        expect(_composer, findsNothing);
        await _press(tester, _key('past_draft-circle-past-elif'));
        expect(_view(tester).selected!.endedOn, _ended);
        expect(
          find.textContaining(day == 30 ? 'Open until 1 Nov' : 'Closed 1 Nov'),
          findsOneWidget,
        );
        if (day == 30) {
          expect(_composer, findsOneWidget);
          await _send(tester, 'An exactly day thirty discussion');
          expect(_view(tester).messages.last.about, 'Elif');
        } else {
          expect(_composer, findsNothing);
          expect(_key('send'), findsNothing);
          expect(
            find.textContaining('This discussion closed 30 days'),
            findsOneWidget,
          );
        }
        await _press(tester, _key('all_past'));
        expect(_composer, findsNothing);
      },
    );
  }

  testWidgets(
    'shared Guardian past summary uses dates and first names with no photo',
    (tester) async {
      final fixture = _Fixture(guardian: true);
      await _mount(tester, fixture);
      await _press(tester, _key('past'));
      expect(_view(tester).past.single.photo, isNull);
      expect(find.text('Adam & Elif'), findsOneWidget);
      expect(find.text('12 Sep – 2 Oct 2026'), findsOneWidget);
      await _press(tester, _key('past_draft-circle-past-elif'));
      expect(_view(tester).selected!.photo, isNull);
      expect(fixture.opened, isEmpty);
    },
  );

  testWidgets(
    'Guardian Basic reads the transcript and opens existing membership callback without a composer',
    (tester) async {
      final fixture = _Fixture(guardian: true, basic: true);
      await _mount(tester, fixture);
      expect(_bodies(tester), hasLength(3));
      expect(_composer, findsNothing);
      expect(_key('send'), findsNothing);
      expect(
        find.text("You're reading only. Chat comes with Guardian One."),
        findsOneWidget,
      );
      await _press(tester, _key('membership'));
      expect(fixture.memberships, 1);
      expect(fixture.manages, 0);
      expect(fixture.data.canSend, isFalse);
      await _press(tester, _key('topic_draft-sara'));
      expect(_composer, findsNothing);
      expect(_bodies(tester), ['A question about Sara']);
    },
  );

  testWidgets(
    'Seeker menu shows exact members, toggles mute and opens existing Basic Family sheet',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _press(tester, _key('menu'));
      expect(find.text('Writes'), findsNWidgets(2));
      expect(find.text('Reads only ›'), findsOneWidget);
      expect(tester.widget<InkWell>(_key('member_draft-self')).onTap, isNull);
      expect(tester.widget<InkWell>(_key('member_draft-hassan')).onTap, isNull);
      await _press(tester, _key('mute'));
      expect(find.text('Unmute the Circle'), findsOneWidget);
      await _press(tester, _key('mute'));
      expect(find.text('Mute the Circle'), findsOneWidget);
      await _press(tester, _key('member_draft-yusuf'));
      expect(find.byType(ZyraGuardianFamilySheet), findsOneWidget);
      final sheet = tester.widget<ZyraGuardianFamilySheet>(
        find.byType(ZyraGuardianFamilySheet),
      );
      expect(sheet.guardianName, 'Yusuf');
      expect(fixture.manages, 0);
      expect(fixture.memberships, 0);
      expect(fixture.data.canSend, isTrue);
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} menu respects owner-only Manage and existing report instruction',
      (tester) async {
        final fixture = _Fixture(guardian: guardian);
        await _mount(tester, fixture);
        await _press(tester, _key('menu'));
        if (guardian) {
          expect(_key('manage'), findsNothing);
          expect(
            tester.widget<InkWell>(_key('member_draft-yusuf')).onTap,
            isNull,
          );
        } else {
          await _press(tester, _key('manage'));
          expect(fixture.manages, 1);
          await _press(tester, _key('menu'));
        }
        await _press(tester, _key('report'));
        expect(
          find.text('Press and hold a message to report it.'),
          findsOneWidget,
        );
        expect(fixture.memberships, 0);
      },
    );
  }

  testWidgets(
    'menu render replacement retires captured mute action before feedback',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _press(tester, _key('menu'));
      final mute = tester.widget<InkWell>(_key('mute')).onTap!;
      await _press(tester, _key('mute'));
      final before = haptics;
      mute();
      await tester.pumpAndSettle();
      expect(haptics, before);
      expect(find.text('Unmute the Circle'), findsOneWidget);
      await _press(tester, _key('done'));
      final afterDone = haptics;
      mute();
      await tester.pumpAndSettle();
      expect(haptics, afterDone);
      await _press(tester, _key('menu'));
      expect(find.text('Unmute the Circle'), findsOneWidget);
    },
  );

  testWidgets(
    'newest message is reached after entry, tab change and send without changing supplied unread data',
    (tester) async {
      final fixture = _Fixture(
        messages: [
          for (var i = 0; i < 35; i++)
            _message(
              'scroll-$i',
              'Discussion message $i',
              context: _sara,
              date: _now.add(Duration(minutes: i)),
              unread: i == 34,
            ),
        ],
      );
      await _mount(tester, fixture);
      expect(find.text('Discussion message 34').hitTestable(), findsOneWidget);
      expect(fixture.data.messages.last.unreadForMe, isTrue);
      await _press(tester, _key('topic_draft-sara'));
      expect(find.text('Discussion message 34').hitTestable(), findsOneWidget);
      fixture.now = _now.add(const Duration(hours: 1));
      await _send(tester, 'Newest local topic message');
      expect(
        find.text('Newest local topic message').hitTestable(),
        findsOneWidget,
      );
      expect(fixture.data.messages.last.unreadForMe, isTrue);
      expect(_view(tester).messages.last.message.unreadForMe, isFalse);
    },
  );

  for (final semantics in [false, true]) {
    final route = semantics ? 'semantics' : 'physical';
    for (final boundary in [
      'tab',
      'overlay',
      'navigation',
      'control',
      'caller',
      'developer',
      'generation',
    ]) {
      testWidgets(
        'retained $route send denies before haptic after $boundary changes',
        (tester) async {
          final fixture = _Fixture();
          await _mount(tester, fixture);
          await tester.enterText(
            _composer,
            'A draft owned by the original Topics state',
          );
          final send = _retained(tester, 'send', semantics);
          if (boundary == 'tab') {
            await _press(tester, _key('topic_draft-sara'));
          } else if (boundary == 'overlay') {
            await _press(tester, _key('menu'));
          } else if (boundary == 'navigation') {
            Navigator.of(tester.element(_key('menu'))).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Other owned page')),
              ),
            );
            await tester.pumpAndSettle();
          } else if (boundary == 'control') {
            fixture.visibility.value = false;
          } else if (boundary == 'caller') {
            fixture.owner = false;
          } else if (boundary == 'developer') {
            ZyraDeveloperAccess.setAuthorizedForTesting(false);
          } else {
            await tester.runAsync(() => ZyraAccountState.beginSignOut());
          }
          final before = haptics;
          send();
          await tester.pumpAndSettle();
          expect(haptics, before);
          if (find.byType(ZyraCircleTopicsPresentation).evaluate().isNotEmpty) {
            expect(
              _bodies(tester),
              isNot(contains('A draft owned by the original Topics state')),
            );
          }
          if (boundary == 'tab') {
            await _press(tester, _key('all'));
          } else if (boundary == 'overlay') {
            await _press(tester, _key('done'));
          } else if (boundary == 'navigation') {
            Navigator.of(tester.element(find.text('Other owned page'))).pop();
            await tester.pumpAndSettle();
          } else if (boundary == 'control') {
            fixture.visibility.value = true;
            await tester.pumpAndSettle();
          } else if (boundary == 'caller') {
            fixture.owner = true;
          } else if (boundary == 'developer') {
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          } else {
            ZyraAccountState.endSignOutAttempt();
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
          final restoredHaptics = haptics;
          send();
          await tester.pumpAndSettle();
          expect(haptics, restoredHaptics);
          if (find.byType(ZyraCircleTopicsPresentation).evaluate().isNotEmpty) {
            expect(
              _bodies(tester),
              isNot(contains('A draft owned by the original Topics state')),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'retained $route Journey target cannot retarget after selecting another Journey',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await _press(tester, _key('topic_draft-sara'));
        final viewSara = _retained(tester, 'view_journey', semantics);
        await _press(tester, _key('topic_draft-aisha'));
        final before = haptics;
        viewSara();
        await tester.pumpAndSettle();
        expect(haptics, before);
        expect(fixture.opened, isEmpty);
        await _press(tester, _key('view_journey'));
        expect(fixture.opened.single, same(_aisha));
      },
    );

    testWidgets('retained $route send cannot replay into a later draft', (
      tester,
    ) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await tester.enterText(_composer, 'First publication only');
      final send = _retained(tester, 'send', semantics);
      send();
      await tester.pumpAndSettle();
      expect(
        _bodies(tester).where((body) => body == 'First publication only'),
        hasLength(1),
      );
      await tester.enterText(
        _composer,
        'A later draft needs its own current action',
      );
      final before = haptics;
      send();
      await tester.pumpAndSettle();
      expect(haptics, before);
      expect(
        _bodies(tester),
        isNot(contains('A later draft needs its own current action')),
      );
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'A later draft needs its own current action',
      );
    });

    testWidgets(
      'retained $route send denies a second pending attempt before feedback',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await tester.enterText(_composer, 'One pending publication');
        final send = _retained(tester, 'send', semantics);
        send();
        await tester.pump(const Duration(milliseconds: 20));
        final before = haptics;
        send();
        await tester.pumpAndSettle();
        expect(haptics, before);
        expect(
          _bodies(tester).where((body) => body == 'One pending publication'),
          hasLength(1),
        );
      },
    );
  }

  for (final replacement in ['data', 'topics', 'role', 'seeker', 'design']) {
    testWidgets(
      'replacement $replacement withdraws captured Topics controls instead of retargeting',
      (tester) async {
        final fixture = _Fixture();
        await _mount(tester, fixture);
        await tester.enterText(
          _composer,
          'Never move a draft to replacement ownership',
        );
        final send = _retained(tester, 'send', true);
        final other = _Fixture();
        addTearDown(other.design.dispose);
        addTearDown(other.visibility.dispose);
        await tester.pumpWidget(
          _app(
            fixture.screen(
              replacementData: replacement == 'data' ? other.data : null,
              replacementTopics: replacement == 'topics' ? other.topics : null,
              viewerIsSeeker: replacement == 'role' ? false : null,
              seekerId: replacement == 'seeker'
                  ? 'draft-another-owner'
                  : 'draft-self',
              replacementDesign: replacement == 'design' ? other.design : null,
            ),
          ),
        );
        final before = haptics;
        send();
        await tester.pumpAndSettle();
        expect(haptics, before);
        expect(_composer, findsNothing);
        expect(
          find.text('Never move a draft to replacement ownership'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'pending publication is denied when its selected Journey changes before completion',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _press(tester, _key('topic_draft-sara'));
      await tester.enterText(
        _composer,
        'Cannot publish under a changed Journey',
      );
      final send = _retained(tester, 'send', true);
      send();
      await tester.pump(const Duration(milliseconds: 20));
      _retained(tester, 'topic_draft-aisha', true)();
      await tester.pumpAndSettle();
      await _press(tester, _key('all'));
      expect(
        _bodies(tester),
        isNot(contains('Cannot publish under a changed Journey')),
      );
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'Cannot publish under a changed Journey',
      );
    },
  );
  for (final semantics in [false, true]) {
    testWidgets(
      'closed deadline denies retained ${semantics ? 'semantics' : 'physical'} send before feedback',
      (tester) async {
        final fixture = _Fixture(now: _ended.add(const Duration(days: 30)));
        await _mount(tester, fixture);
        await _press(tester, _key('past'));
        await _press(tester, _key('past_draft-circle-past-elif'));
        await tester.enterText(_composer, 'The open window has now expired');
        final send = _retained(tester, 'send', semantics);
        fixture.now = _ended.add(const Duration(days: 31));
        final before = haptics;
        send();
        await tester.pumpAndSettle();
        expect(haptics, before);
        expect(
          _bodies(tester),
          isNot(contains('The open window has now expired')),
        );
        await tester.pumpWidget(_app(fixture.screen()));
        await tester.pumpAndSettle();
        expect(_composer, findsNothing);
      },
    );
  }
  testWidgets('message reporting retains the existing other-sender-only rule', (
    tester,
  ) async {
    final fixture = _Fixture(
      messages: [
        ZyraFamilyMessage(
          id: 'own',
          senderId: 'draft-self',
          senderFirstName: 'Adam',
          body: 'My own words',
          createdAt: _now,
        ),
        _message('other', 'Words from another Circle member'),
      ],
    );
    await _mount(tester, fixture);
    Finder reportGesture(String text) => find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onLongPress != null,
      ),
    );
    expect(reportGesture('My own words'), findsNothing);
    expect(reportGesture('Words from another Circle member'), findsOneWidget);
    await tester.longPress(find.text('Words from another Circle member'));
    await tester.pumpAndSettle();
    expect(find.text('Preview only — no report was sent.'), findsOneWidget);
  });
  testWidgets(
    'All retains an existing About label without granting its hidden Journey a tab or target',
    (tester) async {
      final fixture = _Fixture(
        guardian: true,
        historyShared: false,
        contexts: const [],
        messages: [_message('known', 'An already-visible Circle message')],
        transcriptTags: {
          'draft-message-known': ZyraCircleDiscussionTopic(
            id: 'hidden-past',
            firstName: 'Zainab',
            kind: ZyraCircleTopicKind.past,
            endedOn: _ended,
          ),
        },
      );
      await _mount(tester, fixture);
      expect(find.text('About Zainab'), findsOneWidget);
      expect(_key('past'), findsNothing);
      expect(_key('topic_hidden-past'), findsNothing);
      expect(_key('view_journey'), findsNothing);
      await _send(tester, 'All stays untagged');
      final sent = _view(
        tester,
      ).messages.singleWhere((m) => m.message.body == 'All stays untagged');
      expect(sent.about, isNull);
      expect(fixture.opened, isEmpty);
    },
  );
}
