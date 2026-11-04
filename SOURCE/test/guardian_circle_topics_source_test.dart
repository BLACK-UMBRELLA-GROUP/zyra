// LOCK20 integration through the actual Founder shell and its real Circle
// data/configuration. These local samples do not establish live entitlements.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_circle_topics_presentation.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK20_TOPICS_2026-11-01/source_tests';
Finder _key(String id) => find.byKey(ValueKey(id));
Finder _topicKey(String id) => _key('circle_topics_$id');
Finder get _composer => _topicKey('composer');
Finder get _circle => find.byType(ZyraGuardianCircleScreen);

ZyraGuardianCircleScreen _screen(WidgetTester tester) => tester.widget(_circle);
ZyraGuardianCirclePreviewData _data(WidgetTester tester) =>
    _screen(tester).previewData!;
ZyraCircleTopicsPresentation _presentation(WidgetTester tester) =>
    tester.widget(find.byType(ZyraCircleTopicsPresentation));

ViewRequestDraftModel _model({
  bool basicAdditional = false,
  bool seekerBasic = false,
}) {
  final model = ViewRequestDraftModel(capacity: seekerBasic ? 1 : 3);
  expect(model.seedJourneys(seekerBasic ? 1 : 2), isTrue);
  if (basicAdditional) {
    final additional = draftGuardians.singleWhere((person) => !person.isMain);
    expect(
      model.setSampleGuardianMembership(
        additional.id,
        DraftGuardianMembership.basic,
      ),
      isTrue,
    );
  }
  return model;
}

Future<BaselineHarness> _mount(
  WidgetTester tester, {
  bool guardian = false,
  bool seekerBasic = false,
  bool guardianBasic = false,
  bool openCircle = true,
  ViewRequestDraftModel? model,
}) async {
  final harness = BaselineHarness(
    tester,
    group: 'lock20_source_tests',
    evidenceRoot: _evidence,
    outputRoot:
        '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/GUARDIAN_CIRCLE/BUILT/V2',
    flatOutput: true,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await harness.mount(
    guardian: guardian,
    tab: 3,
    pages: openCircle ? const ['guardian_circle'] : const [],
    model: model ?? _model(seekerBasic: seekerBasic),
    seekerMembership: seekerBasic ? 'Seeker Basic' : 'Seeker One',
    guardianMembership: guardianBasic ? 'Guardian Basic' : 'Guardian One',
    initialSeekerBasic: seekerBasic,
    initialGuardianBasic: guardianBasic,
  );
  if (openCircle) {
    expect(_circle, findsOneWidget);
    expect(find.byType(ZyraCircleTopicsPresentation), findsOneWidget);
    expect(
      _data(
        tester,
      ).validFor(_screen(tester).seekerId, viewerIsSeeker: !guardian),
      isTrue,
    );
  }
  return harness;
}

Future<void> _captureSource(BaselineHarness h, String name) async {
  if (!const bool.fromEnvironment('ZYRA_LOCK20_CAPTURE')) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(
      h.tester.renderObject(
        find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
      ),
    );
    await h.tester.pump();
    await h.capture(
      'circle_topics_source',
      name,
      'actual_source',
      'Actual Founder shell, model and Circle data. Existing source names, dates, permissions and unread state; no master-data replacement.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

Future<void> _send(
  WidgetTester tester,
  BaselineHarness harness,
  String body,
) async {
  await tester.enterText(_composer, body);
  await harness.tap('circle_topics_send');
  expect(
    _presentation(tester).messages.map((item) => item.message.body),
    contains(body),
  );
  expect(tester.widget<TextField>(_composer).controller!.text, isEmpty);
}

List<VoidCallback> _retainedSend(WidgetTester tester) => [
  tester.widget<Semantics>(_topicKey('send')).properties.onTap!,
  tester
      .widget<GestureDetector>(
        find.descendant(
          of: _topicKey('send'),
          matching: find.byType(GestureDetector),
        ),
      )
      .onTap!,
];

void _expectCurrentTabs(WidgetTester tester) {
  final data = _data(tester);
  final view = _presentation(tester);
  expect(
    view.current.map((tile) => (tile.id, tile.name)),
    data.contexts.map((context) => (context.referenceId, context.firstName)),
  );
  for (final context in data.contexts) {
    expect(context.kind, ZyraFamilyMessageContextKind.active);
    expect(_topicKey('topic_${context.referenceId}'), findsOneWidget);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var haptics = 0;
  setUp(() async {
    await baselineSetUp(evidenceRoot: _evidence);
    haptics = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics++;
          return null;
        });
  });
  tearDown(baselineTearDown);

  testWidgets(
    'source Seeker One writes while the actual Additional Guardian remains Basic',
    (tester) async {
      final h = await _mount(tester, model: _model(basicAdditional: true));
      final data = _data(tester), config = _screen(tester).previewTopics!;
      final additional = data.participants.singleWhere(
        (person) => person.memberRole == 'guardian' && !person.isMainGuardian,
      );
      expect(data.canSend, isTrue);
      expect(config.readOnlyParticipantIds, contains(additional.userId));
      expect(config.guardianBasic, isFalse);
      expect(_composer, findsOneWidget);
      _expectCurrentTabs(tester);
      await _captureSource(h, 'actual_source_seeker_one');
      await _send(
        tester,
        h,
        'Seeker writing is independent of a Basic Guardian',
      );
      expect(
        _presentation(tester).messages.last.message.senderId,
        data.senderId,
      );
      expect(_presentation(tester).messages.last.about, isNull);
    },
  );

  testWidgets('source Seeker Basic writes with only the actual Main Guardian', (
    tester,
  ) async {
    final h = await _mount(tester, seekerBasic: true);
    final data = _data(tester);
    final guardians = data.participants.where(
      (person) => person.memberRole == 'guardian',
    );
    expect(guardians, hasLength(1));
    expect(guardians.single.isMainGuardian, isTrue);
    expect(data.canSend, isTrue);
    expect(_composer, findsOneWidget);
    await _captureSource(h, 'actual_source_seeker_basic');
    await _send(tester, h, 'Seeker Basic can speak with their Main Guardian');
  });

  testWidgets(
    'source Guardian One writes and receives only source-admitted tabs',
    (tester) async {
      final h = await _mount(tester, guardian: true);
      final data = _data(tester), config = _screen(tester).previewTopics!;
      expect(data.canSend, isTrue);
      expect(config.guardianBasic, isFalse);
      expect(config.readOnlyParticipantIds, isNot(contains(data.senderId)));
      expect(_composer, findsOneWidget);
      _expectCurrentTabs(tester);
      await _captureSource(h, 'actual_source_guardian_one');
      await _send(tester, h, 'The current Guardian One writes for this Circle');
      expect(
        _presentation(tester).messages.last.message.senderId,
        data.senderId,
      );
    },
  );

  testWidgets(
    'source Guardian Basic reads without a composer and uses the existing membership destination',
    (tester) async {
      final h = await _mount(tester, guardian: true, guardianBasic: true);
      final data = _data(tester), config = _screen(tester).previewTopics!;
      expect(data.canSend, isFalse);
      expect(config.guardianBasic, isTrue);
      expect(config.readOnlyParticipantIds, contains(data.senderId));
      expect(_presentation(tester).messages, isNotEmpty);
      await _captureSource(h, 'actual_source_guardian_basic');
      expect(_composer, findsNothing);
      expect(_topicKey('send'), findsNothing);
      await h.tap('circle_topics_membership');
      h.assertPage('membership');
      expect(_composer, findsNothing);
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      'source ${guardian ? 'Guardian' : 'Seeker'} View Journey preserves the selected exact owner',
      (tester) async {
        final h = await _mount(tester, guardian: guardian);
        final contexts = _data(tester).contexts;
        expect(contexts, hasLength(2));
        final exact = contexts.last;
        await h.tap('circle_topics_topic_${exact.referenceId}');
        expect(_presentation(tester).selected!.id, exact.referenceId);
        await h.tap('circle_topics_view_journey');
        expect(h.latest.pages.last, isNot('guardian_circle'));
        if (guardian) {
          expect(h.latest.guardianJourneyId, exact.referenceId);
        } else {
          expect(h.latest.personId, exact.referenceId);
        }
        expect(h.latest.guardian, guardian);
      },
    );
  }

  testWidgets(
    'source Circle entry clears its real unread facts across return',
    (tester) async {
      final h = await _mount(tester, openCircle: false);
      expect(h.latest.circleReadMessageKeys, isEmpty);
      await h.tap('guardian-family-messages-top');
      expect(_circle, findsOneWidget);
      expect(h.latest.circleReadMessageKeys, isNotEmpty);
      final readKeys = Set<String>.of(h.latest.circleReadMessageKeys);
      expect(
        _data(tester).messages.where((message) => message.unreadForMe),
        isEmpty,
      );
      await swipeZyraBack(tester);
      expect(_circle, findsNothing);
      await h.tap('guardian-family-messages-top');
      expect(
        _data(tester).messages.where((message) => message.unreadForMe),
        isEmpty,
      );
      expect(h.latest.circleReadMessageKeys, readKeys);
    },
  );

  testWidgets(
    'source Page options cover retires both retained send paths before feedback',
    (tester) async {
      final h = await _mount(tester);
      await tester.enterText(
        _composer,
        'A source draft must remain behind its controls',
      );
      final send = _retainedSend(tester);
      // The retired panel is absent. A real owned Circle route supplies cover.
      final navigator = Navigator.of(tester.element(_circle));
      navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Member Circle cover')),
        ),
      );
      await h.flush();
      expect(_key('dev_controls_page'), findsNothing);
      final coveredHaptics = haptics;
      for (final callback in send) {
        callback();
      }
      await h.flush();
      expect(haptics, coveredHaptics);
      expect(find.text('Member Circle cover'), findsOneWidget);
      navigator.pop();
      await h.flush();
      final returnedHaptics = haptics;
      for (final callback in send) {
        callback();
      }
      await h.flush();
      expect(haptics, returnedHaptics);
      expect(
        _presentation(tester).messages.map((item) => item.message.body),
        isNot(contains('A source draft must remain behind its controls')),
      );
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'A source draft must remain behind its controls',
      );
    },
  );

  testWidgets(
    'source account generation revokes both retained send paths before feedback',
    (tester) async {
      final h = await _mount(tester);
      await tester.enterText(
        _composer,
        'No source publication after account departure',
      );
      final send = _retainedSend(tester);
      final generation = ZyraAccountState.generation;
      await tester.runAsync(() => ZyraAccountState.beginSignOut());
      expect(ZyraAccountState.generation, greaterThan(generation));
      final before = haptics;
      for (final callback in send) {
        callback();
      }
      await h.flush();
      expect(haptics, before);
      ZyraAccountState.endSignOutAttempt();
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      for (final callback in send) {
        callback();
      }
      await h.flush();
      expect(haptics, before);
      expect(_composer, findsNothing);
      expect(
        find.text('No source publication after account departure'),
        findsNothing,
      );
    },
  );
}
