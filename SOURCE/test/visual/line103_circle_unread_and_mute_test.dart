// LOCK 20 V4 through the protected Seeker and Guardian preview routes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_circle_topics_presentation.dart';
import 'package:zyra/dev/zyra_conversation_unread_badge.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _evidence = '../REPORTS/EVIDENCE/OA-ZYRA-317_LINE103_2026-11-12';
const _capture = bool.fromEnvironment('ZYRA_LINE103_CAPTURE');
const _dividerEvidence =
    '../REPORTS/EVIDENCE/OA-ZYRA-317_LINE103_MAIN_DIVIDER_2026-11-13';
const _captureDivider = bool.fromEnvironment('ZYRA_LINE103_DIVIDER_CAPTURE');
const _past0 = 'draft-circle-past-0';
const _past1 = 'draft-circle-past-1';
const _past3 = 'draft-circle-past-3';

Finder _circle(String id) => find.byKey(ValueKey('circle_topics_$id'));

ZyraCircleTopicsPresentation _topics(WidgetTester t) =>
    t.widget(find.byType(ZyraCircleTopicsPresentation));

Future<void> _expectMainDivider(WidgetTester t, String? id) async {
  final divider = find.text('UNREAD MESSAGES');
  final topics = _topics(t);
  expect(topics.unreadDividerId, id);
  if (id == null) {
    expect(divider, findsNothing);
    return;
  }
  final controller = topics.scrollController;
  final offset = controller.offset;
  if (divider.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      divider,
      -200,
      scrollable: find.byWidgetPredicate(
        (widget) => widget is Scrollable && widget.controller == controller,
      ),
    );
  }
  final firstUnread = find.text('Circle delivery $id');
  expect(divider, findsOneWidget);
  expect(firstUnread, findsOneWidget);
  expect(t.getBottomLeft(divider).dy, lessThan(t.getTopLeft(firstUnread).dy));
  if (controller.offset != offset) {
    controller.jumpTo(offset);
    await t.pump();
  }
}

ZyraConversationUnreadCount? _badge(WidgetTester t, String id) => t
    .widgetList<ZyraConversationUnreadCount>(
      find.descendant(
        of: _circle(id),
        matching: find.byType(ZyraConversationUnreadCount),
      ),
    )
    .singleOrNull;

List<String> _pastOrder(WidgetTester t) =>
    _topics(t).past.map((tile) => tile.id).toList();

ZyraFamilyMessageContext _past(String id, String name) =>
    ZyraFamilyMessageContext(
      referenceId: id,
      firstName: name,
      kind: ZyraFamilyMessageContextKind.ended,
    );

class _Scenario {
  _Scenario(this.guardian, this.h);
  final bool guardian;
  final BaselineHarness h;

  String get viewer => guardian ? 'draft-guardian-hassan' : 'draft-self';
  String get sender => guardian ? 'draft-self' : 'draft-guardian-hassan';
  String readKey(String id) => 'draft-self:$viewer:$id:$sender';

  Future<void> addAndRefresh(
    List<ZyraFamilyMessage> arrivals,
    String id, {
    ZyraFamilyMessageContext? topic,
    int minute = 0,
  }) async {
    arrivals.add(delivery(id, topic: topic, minute: minute));
    h.shellFixture.circleArrivalsChanged();
    await h.flush();
  }

  ZyraFamilyMessage delivery(
    String id, {
    ZyraFamilyMessageContext? topic,
    int minute = 0,
    bool unread = true,
  }) => ZyraFamilyMessage(
    id: id,
    senderId: sender,
    senderFirstName: guardian ? 'Adam' : 'Hassan',
    body: 'Circle delivery $id',
    createdAt: DateTime.utc(2026, 11, 12, 12, minute),
    context: topic,
    unreadForMe: unread,
  );

  Future<void> tap(String id) => h.tap('circle_topics_$id');

  Future<void> screenshot(String name) async {
    if (!_capture) return;
    await h.capture('circle', name, 'lock20_v4', 'Offline Founder preview.');
  }

  Future<void> back() async {
    await returnZyraPreviewPage(h.tester);
    await h.flush();
  }

  Future<void> tab(int index) async {
    h.tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .onTap(index);
    await h.flush();
  }
}

void main() {
  setUpAll(
    () => baselineSetUp(
      evidenceRoot: _captureDivider
          ? _dividerEvidence
          : (_capture ? _evidence : null),
    ),
  );
  tearDownAll(baselineTearDown);

  testWidgets(
    'an ended attempt keeps its chat and a restart gets a new chat',
    (t) async {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      DateTime clock() => DateTime.utc(2026, 11, 12, 13);
      final model = ViewRequestDraftModel(capacity: 3, clock: clock)
        ..seedJourneys(1);
      final person = draftProfiles.firstWhere(
        (p) => model.stateFor(p.id) == DraftJourneyState.active,
      );
      final chatId = model.circleChatIdFor(person.id)!;
      final current = ZyraFamilyMessageContext(
        referenceId: person.id,
        firstName: person.firstName,
        kind: ZyraFamilyMessageContextKind.active,
      );
      final arrivals = <ZyraFamilyMessage>[];
      final h = BaselineHarness(
        t,
        group: 'line103_lifecycle',
        circleArrivalsFor: (seeker, viewer) => arrivals,
      );
      final scenario = _Scenario(false, h);
      arrivals.add(scenario.delivery('original', topic: current));
      await h.mount(
        model: model,
        tab: 3,
        pages: const ['guardian_circle'],
        previewClock: clock,
      );
      expect(_topics(t).current.single.id, chatId);
      await scenario.tap('topic_${person.id}');
      expect(_topics(t).unreadDividerId, 'original');
      await t.enterText(find.byType(TextField), 'Keep this with the attempt.');
      await scenario.tap('send');
      expect(
        _topics(t).messages.last.message.body,
        'Keep this with the attempt.',
      );
      await scenario.tap('menu');
      await scenario.tap('mute_chat');
      await scenario.tap('done');
      final saved = h.latest;

      expect(
        model.end(person.id, mainGuardianId: 'draft-guardian-hassan'),
        isTrue,
      );
      final ended = model.currentEndedAttemptFor(person.id)!;
      expect(ended.circleChatId, chatId);
      final fresh = ViewRequestDraftModel(capacity: 3, clock: clock)
        ..seedJourneys(1);
      final restarted = ViewRequestDraftModel.fromSnapshot(
        fresh.snapshot(),
        earlierAttempts: [ended],
        clock: clock,
      );
      final newId = restarted.circleChatIdFor(person.id)!;
      expect(newId, isNot(chatId));
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: restarted.snapshot(),
          tab: 3,
          pages: const ['guardian_circle'],
          circleReadMessageKeys: saved.circleReadMessageKeys,
          circleMuteKeys: saved.circleMuteKeys,
          circleArrivalChatIds: saved.circleArrivalChatIds,
          circleSentSequence: saved.circleSentSequence,
          circleSentMessages: saved.circleSentMessages,
        ),
        previewClock: clock,
      );
      expect(_topics(t).current.single.id, newId);
      expect(_topics(t).current.single.muted, isFalse);
      expect(_topics(t).current.single.unread, 0);
      final archived = _topics(t).past.singleWhere((tile) => tile.id == chatId);
      expect(archived.muted, isTrue);
      expect(archived.unread, 0);
      await scenario.tap('past');
      await scenario.tap('past_$chatId');
      expect(_topics(t).messages.map((item) => item.message.body), [
        'Circle delivery original',
        'Keep this with the attempt.',
      ]);
      await scenario.addAndRefresh(
        arrivals,
        'opened-past',
        topic: _past(chatId, person.firstName),
      );
      expect(
        h.latest.circleReadMessageKeys.any(
          (key) => key.startsWith('$chatId:') && key.contains('opened-past'),
        ),
        isTrue,
      );
      await scenario.back();
      await h.tap('guardian-family-messages-top');
      await scenario.tap('past');
      expect(
        _topics(t).past.singleWhere((tile) => tile.id == chatId).unread,
        0,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Circle mute suppresses delivery attention through unmute',
    (t) async {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final arrivals = <ZyraFamilyMessage>[];
      final h = BaselineHarness(
        t,
        group: 'line103_attention',
        circleArrivalsFor: (seeker, viewer) => arrivals,
      );
      final scenario = _Scenario(false, h);
      await h.mount(
        tab: 3,
        pages: const ['guardian_circle'],
        receivedRequest: false,
      );
      await scenario.tap('past');
      await scenario.tap('menu');
      await scenario.tap('mute');
      await scenario.tap('done');
      await scenario.addAndRefresh(
        arrivals,
        'quiet-past',
        topic: _past(_past0, 'Elif'),
      );
      expect(_badge(t, 'past_$_past0')?.count, 1);
      await scenario.tap('menu');
      await scenario.tap('mute');
      await scenario.tap('done');
      await scenario.back();
      expect(
        t
            .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
            .items[2]
            .hasUnread,
        isFalse,
      );
      await scenario.tab(2);
      Iterable<String> focus() => t
          .widget<ZyraFocusDashboard>(find.byType(ZyraFocusDashboard))
          .items
          .where((item) => item.id.startsWith('circle:'))
          .map((item) => item.id);
      expect(focus(), isEmpty);
      await scenario.addAndRefresh(
        arrivals,
        'audible-past',
        topic: _past(_past0, 'Elif'),
      );
      expect(focus().single, contains('audible-past'));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    testWidgets(
      '$role Main entry keeps its first unread divider until reopening',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        DateTime clock() => DateTime.utc(2026, 11, 12, 12);
        final arrivals = <ZyraFamilyMessage>[];
        final h = BaselineHarness(
          t,
          group: 'line103_${role}_main_entry',
          outputRoot: _dividerEvidence,
          evidenceRoot: _dividerEvidence,
          flatOutput: true,
          circleArrivalsFor: (seeker, viewer) =>
              seeker == 'draft-self' &&
                  viewer == (guardian ? 'draft-guardian-hassan' : 'draft-self')
              ? arrivals
              : const [],
        );
        final scenario = _Scenario(guardian, h);
        arrivals.addAll([
          scenario.delivery('main-later', minute: 6),
          scenario.delivery('main-first', minute: 4),
          scenario.delivery('main-already-read', minute: 1, unread: false),
        ]);
        await h.mount(
          guardian: guardian,
          tab: 3,
          previewClock: clock,
          receivedRequest: false,
        );
        if (guardian) await h.tap('guardian_seeker_0');
        final entry = guardian
            ? 'guardian_circle'
            : 'guardian-family-messages-top';
        expect(h.latest.circleReadMessageKeys, isEmpty);
        await h.tap(entry);
        h.assertPage('guardian_circle');
        final reads = {
          scenario.readKey('main-first'),
          scenario.readKey('main-later'),
        };
        expect(h.latest.circleReadMessageKeys, reads);
        final reader = t.widget<ZyraGuardianCircleScreen>(
          find.byType(ZyraGuardianCircleScreen),
        );
        expect(
          reader.previewData!.messages.every((m) => !m.unreadForMe),
          isTrue,
        );
        await _expectMainDivider(t, 'main-first');
        if (_captureDivider) {
          await h.capture(
            'circle',
            '${role.toLowerCase()}_main',
            'unread_divider',
            'Main opened through the Founder preview.',
          );
        }

        await scenario.addAndRefresh(arrivals, 'main-arrived-open', minute: 3);
        expect(find.text('Circle delivery main-arrived-open'), findsOneWidget);
        expect(h.latest.circleReadMessageKeys, {
          ...reads,
          scenario.readKey('main-arrived-open'),
        });
        await _expectMainDivider(t, 'main-first');

        await scenario.back();
        await h.tap(entry);
        h.assertPage('guardian_circle');
        await _expectMainDivider(t, null);

        await h.mount(
          guardian: guardian,
          checkpoint: h.latest,
          previewClock: clock,
        );
        h.assertPage('guardian_circle');
        await _expectMainDivider(t, null);

        await scenario.back();
        await scenario.addAndRefresh(arrivals, 'main-new-entry', minute: 10);
        await h.tap(entry);
        await _expectMainDivider(t, 'main-new-entry');
        final withdrawn = arrivals.removeLast();
        h.shellFixture.circleArrivalsChanged();
        await h.flush();
        await _expectMainDivider(t, null);
        arrivals.add(withdrawn);
        h.shellFixture.circleArrivalsChanged();
        await h.flush();
        expect(find.text('Circle delivery main-new-entry'), findsOneWidget);
        await _expectMainDivider(t, null);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      '$role sees topic counts, Past order, read clearing and mute scope',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        DateTime clock() => DateTime.utc(2026, 11, 12, 12);
        final model = ViewRequestDraftModel(capacity: 3, clock: clock);
        expect(model.seedJourneys(1), isTrue);
        final profile = draftProfiles.firstWhere(
          (p) => model.stateFor(p.id) == DraftJourneyState.active,
        );
        final journey = ZyraFamilyMessageContext(
          referenceId: profile.id,
          firstName: profile.firstName,
          kind: ZyraFamilyMessageContextKind.active,
        );
        final arrivals = <ZyraFamilyMessage>[];
        final h = BaselineHarness(
          t,
          group: 'line103_$role',
          outputRoot: _evidence,
          evidenceRoot: _evidence,
          flatOutput: true,
          circleArrivalsFor: (seeker, viewer) =>
              seeker == 'draft-self' &&
                  viewer == (guardian ? 'draft-guardian-hassan' : 'draft-self')
              ? arrivals
              : const [],
        );
        final scenario = _Scenario(guardian, h);
        final elif = _past(_past0, 'Elif');
        final noor = _past(_past1, 'Noor');
        final zainab = _past(_past3, 'Zainab');
        arrivals.addAll([
          scenario.delivery('main', minute: 1),
          scenario.delivery('active', topic: journey),
          scenario.delivery('elif', topic: elif, minute: 2),
          for (var i = 0; i < 10; i++)
            scenario.delivery('zainab-$i', topic: zainab, minute: 4 + i),
          scenario.delivery('noor', topic: noor, minute: 20),
          scenario.delivery(
            'elif-later',
            topic: elif,
            minute: 21,
            unread: false,
          ),
        ]);
        final checkpoint = ZyraPreviewNavigationCheckpoint(
          guardian: guardian,
          model: model.snapshot(),
          tab: 3,
          pages: const ['guardian_circle'],
          guardianHistory: const {'draft-guardian-hassan': true},
        );
        await h.mount(
          guardian: guardian,
          checkpoint: checkpoint,
          previewClock: clock,
        );
        final activeKey = 'topic_${journey.referenceId}';
        final circleData = t
            .widget<ZyraGuardianCircleScreen>(
              find.byType(ZyraGuardianCircleScreen),
            )
            .previewData!;
        final activeId = circleData.currentChatId(journey.referenceId);
        final list = circleData.listChats(
          admittedTopics: circleData.admittedTopics,
          messages: circleData.messages,
          chatFor: circleData.chatFor,
          isUnread: circleData.isUnread,
          isMuted: (id) => id == null,
        );
        expect(list[circleData.mainChatId]!.kind, ZyraCircleChatKind.main);
        expect(list[activeId], (
          chatId: activeId,
          kind: ZyraCircleChatKind.journey,
          state: ZyraCircleChatState.current,
          otherFirstName: journey.firstName,
          lastMessageAt: clock(),
          endedAt: null,
          unreadCount: 1,
          muted: false,
          circleMuted: true,
          countsTowardTotal: false,
        ));
        expect(list[_past0]!.state, ZyraCircleChatState.past);
        expect(_badge(t, 'all'), isNull);
        expect(_badge(t, activeKey)?.count, 1);
        expect(_badge(t, 'past')?.count, 12);
        expect(find.text('9+'), findsOneWidget);
        expect(h.latest.circleReadMessageKeys, {scenario.readKey('main')});
        await _expectMainDivider(t, 'main');
        await scenario.screenshot('${role.toLowerCase()}_tab_totals');

        await scenario.tap('past');
        expect(_badge(t, 'past'), isNull);
        expect(_pastOrder(t).take(4), [
          _past0,
          _past1,
          _past3,
          'draft-circle-past-2',
        ]);
        expect(_badge(t, 'past_$_past3')?.count, 10);
        expect(find.text('9+'), findsOneWidget);
        await scenario.screenshot('${role.toLowerCase()}_past_unread');

        await scenario.tap('menu');
        expect(find.text('Mute the whole Circle'), findsOneWidget);
        expect(_circle('mute_chat'), findsNothing);
        await scenario.tap('mute');
        expect(find.text('Unmute the whole Circle'), findsOneWidget);
        expect(
          find.text('Circle muted — no alerts, messages still arrive.'),
          findsOneWidget,
        );
        await scenario.tap('done');
        expect(_pastOrder(t).take(3), [_past0, _past1, _past3]);
        expect(_badge(t, 'past_$_past3')?.muted, isFalse);

        await scenario.tap('past_$_past3');
        expect(h.latest.circleReadMessageKeys, hasLength(11));
        expect(_topics(t).messages, hasLength(10));
        await scenario.tap('menu');
        expect(find.text('Mute Zainab’s chat'), findsOneWidget);
        expect(find.text('Unmute the whole Circle'), findsOneWidget);
        expect(
          t.getTopLeft(_circle('mute_chat')).dy,
          lessThan(t.getTopLeft(_circle('mute')).dy),
        );
        await scenario.tap('mute_chat');
        expect(find.text('Unmute Zainab’s chat'), findsOneWidget);
        expect(find.text('Muted'), findsNWidgets(2));
        expect(
          find.text('Zainab’s chat muted — no alerts, messages still arrive.'),
          findsOneWidget,
        );
        await scenario.screenshot('${role.toLowerCase()}_past_mute_sheet');
        await scenario.tap('mute');
        await scenario.tap('done');
        await scenario.tap('all_past');
        await scenario.addAndRefresh(
          arrivals,
          'muted-zainab',
          topic: zainab,
          minute: 45,
        );
        expect(_pastOrder(t).take(5), [
          _past0,
          _past1,
          'draft-circle-past-2',
          _past3,
          'draft-circle-past-4',
        ]);
        expect(_badge(t, 'past_$_past3')?.count, 1);
        expect(_badge(t, 'past_$_past3')?.muted, isTrue);
        expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
        await scenario.screenshot('${role.toLowerCase()}_past_muted');

        await scenario.tap('all');
        expect(_badge(t, 'past')?.count, 2);
        await scenario.tap(activeKey);
        expect(_badge(t, activeKey), isNull);
        expect(_topics(t).messages.single.message.id, 'active');
        expect(_topics(t).unreadDividerId, 'active');
        await scenario.tap('menu');
        expect(find.text('Mute ${journey.firstName}’s chat'), findsOneWidget);
        await scenario.tap('done');
        await scenario.tap('all');
        await _expectMainDivider(t, null);
        await scenario.tap('menu');
        expect(find.text('Mute the Main chat'), findsOneWidget);
        await scenario.tap('mute_chat');
        expect(
          find.text('Main chat muted — no alerts, messages still arrive.'),
          findsOneWidget,
        );
        await scenario.tap('done');
        await scenario.back();

        // Delivery continues while muted. Only the admitted unmuted topics
        // should appear in My ZYRA. Opening My ZYRA clears tab attention.
        await scenario.addAndRefresh(arrivals, 'muted-main', minute: 47);
        final nav = t.widget<ZyraShellNavigation>(
          find.byType(ZyraShellNavigation),
        );
        expect(nav.items[2].hasUnread, isTrue);
        await scenario.tab(2);
        expect(
          t
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .items[2]
              .hasUnread,
          isFalse,
        );
        final focus = t.widget<ZyraFocusDashboard>(
          find.byType(ZyraFocusDashboard),
        );
        final circleItems = focus.items
            .where((item) => item.id.startsWith('circle:'))
            .toList();
        expect(circleItems, hasLength(2));
        expect(circleItems.map((item) => item.title).toSet(), {
          guardian
              ? "New message in Adam's Guardian Circle"
              : 'New message in Guardian Circle',
        });
        expect(circleItems.any((item) => item.id.contains('muted-')), isFalse);
        await scenario.tab(3);
        final saved = h.latest;
        expect(saved.circleMuteKeys, {
          (
            'draft-self',
            guardian ? 'draft-guardian-hassan' : 'draft-self',
            _past3,
          ),
          (
            'draft-self',
            guardian ? 'draft-guardian-hassan' : 'draft-self',
            'preview-circle-general',
          ),
        });
        // Reopen from the saved, in-memory preview state.
        await h.mount(
          guardian: guardian,
          previewClock: clock,
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: saved.model,
            tab: 3,
            pages: const ['guardian_circle'],
            guardianHistory: saved.guardianHistory,
            circleReadMessageKeys: saved.circleReadMessageKeys,
            circleMuteKeys: saved.circleMuteKeys,
          ),
        );
        await _expectMainDivider(t, 'muted-main');
        expect(h.latest.circleReadMessageKeys, {
          ...saved.circleReadMessageKeys,
          scenario.readKey('muted-main'),
        });
        await scenario.tap('past');
        expect(_badge(t, 'past_$_past3')?.muted, isTrue);
        await scenario.tap('past_$_past3');
        expect(_topics(t).messages.last.message.id, 'muted-zainab');
        await scenario.tap('menu');
        await scenario.tap('mute_chat');
        expect(find.text('Zainab’s chat unmuted.'), findsOneWidget);
        await scenario.tap('done');
        await scenario.tap('all_past');
        expect(_badge(t, 'past_$_past3'), isNull);
        await scenario.addAndRefresh(
          arrivals,
          'unmuted-zainab',
          topic: zainab,
          minute: 48,
        );
        expect(_pastOrder(t).first, _past3);
        expect(_badge(t, 'past_$_past3')?.muted, isFalse);
        await t.pump(const Duration(seconds: 2));
        expect(t.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
