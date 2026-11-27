import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_limits_preview.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import '../support/profile_swipe_driver.dart';
import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _capture = bool.fromEnvironment('ZYRA_LINE146_CAPTURE');
const _root = 'build/line146';
const _target = 'draft-aisha';
const _sent = ['draft-sara', 'draft-amira', 'draft-hana'];
DateTime _clock() => DateTime(2026, 11, 24, 14, 20);

ViewRequestDraftModel _model([Iterable<String> sent = const []]) {
  final model = ViewRequestDraftModel(capacity: 3, clock: _clock);
  for (final id in sent) {
    expect(model.request(id), isTrue);
  }
  return model;
}

ZyraPreviewNavigationCheckpoint _checkpoint({
  required bool basic,
  required ViewRequestDraftModel model,
  int tab = 0,
  List<String> pages = const [],
  int requestsTab = 0,
  String profile = _target,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: false,
  model: model.snapshot(),
  tab: tab,
  pages: pages,
  requestsTab: requestsTab,
  personId: profile,
  browseId: profile,
  seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
);

Future<void> _check(BaselineHarness h, String name, Finder scope) async {
  final t = h.tester;
  expect(scope, findsOneWidget);
  final words = t
      .widgetList<Text>(find.descendant(of: scope, matching: find.byType(Text)))
      .map((text) => text.data)
      .whereType<String>()
      .toSet();
  expect(words, isNotEmpty);
  for (final word in words) {
    final text = find.descendant(of: scope, matching: find.text(word));
    expect(text.hitTestable(), findsOneWidget, reason: '$name: $word');
  }
  if (!_capture) return;
  await t.pump(const Duration(milliseconds: 2600));
  final boundary = t.renderObject<RenderRepaintBoundary>(
    h.key('zyra-founder-baseline-boundary'),
  );
  // The capture harness waits for actual image decoding before measurement.
  final prior = debugDisableShadows;
  try {
    debugDisableShadows = false;
    void repaint(RenderObject node) {
      node.visitChildren(repaint);
      node.markNeedsPaint();
    }

    repaint(boundary);
    await t.pump();
    await h.capture('limits', 'line146', name, name, fileName: '$name.png');
  } finally {
    debugDisableShadows = prior;
  }
  final audit = await auditZyraRenderedText(t, boundary);
  final failures = audit.failures.where((failure) {
    final text = failure['text'];
    return text is! String ||
        words.any((word) => word == text || word.contains(text));
  }).toList();
  await t.runAsync(() async {
    final file = File('$_root/audit/$name.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'scoped_text': words.toList(),
        'scoped_failures': failures,
        'frame': audit.toJson(),
      }),
    );
  });
  expect(failures, isEmpty, reason: '$name: $failures');
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final (size, scale) in [
    (const Size(430, 932), 1.0),
    (const Size(375, 667), 1.0),
    (const Size(430, 932), 1.3),
    (const Size(375, 667), 1.3),
  ]) {
    testWidgets(
      'LOCK48 actual preview states ${size.width} at $scale',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final suffix = '${size.width.toInt()}_${(scale * 10).toInt()}';
        final h = BaselineHarness(
          t,
          group: 'line146_$suffix',
          logicalSize: size,
          textScale: scale,
          safePadding: size.width == 430
              ? const EdgeInsets.only(top: 59, bottom: 34)
              : const EdgeInsets.only(top: 20),
          flatOutput: true,
          reduceMotion: true,
          outputRoot: '$_root/screens',
          evidenceRoot: '$_root/screens',
        );
        Future<void> mount(
          bool basic, {
          ViewRequestDraftModel? model,
          int tab = 0,
          List<String> pages = const [],
          int requestsTab = 0,
          int viewed = 0,
          int waiting = 0,
        }) => h.mount(
          checkpoint: _checkpoint(
            basic: basic,
            model: model ?? _model(),
            tab: tab,
            pages: pages,
            requestsTab: requestsTab,
          ),
          previewClock: _clock,
          seededViewedProfiles: viewed,
          seededWaitingRequests: waiting,
        );
        Future<void> check(String name, Finder finder) =>
            _check(h, '${name}_$suffix', finder);

        await mount(true, viewed: 11);
        expect(find.text('12 of 25 profiles'), findsOneWidget);
        await check('pr01', find.byType(ZyraProfilesLimitBar));
        await mount(true, viewed: 25);
        expect(find.text('25 of 25 profiles'), findsOneWidget);
        expect(find.text('You’ve seen your 25 for now'), findsOneWidget);
        expect(h.key('draft_profile_$_target'), findsNothing);
        await check('pr02_bar', find.byType(ZyraProfilesLimitBar));
        await check('pr02', find.byType(ZyraProfilesLimitCard));
        await h.tapText('Try Seeker One free for 14 days');
        h.assertPage('one_upgrade');
        expect(find.text('Requests waiting at once'), findsOneWidget);
        await mount(false, viewed: 25);
        expect(find.byType(ZyraProfilesLimitBar), findsNothing);
        expect(find.byType(ZyraProfilesLimitCard), findsNothing);
        expect(h.key('draft_profile_$_target'), findsOneWidget);
        if (_capture) {
          await t.pump(const Duration(milliseconds: 2600));
          await h.capture(
            'limits',
            'line146',
            'pr03',
            'No bar at a test-seeded count of 25',
            fileName: 'pr03_$suffix.png',
          );
        }

        await mount(false, waiting: 20, tab: 2, pages: const ['profile']);
        await h.tap('full_profile_action_Request_a_Journey');
        expect(h.shellFixture.model.stateFor(_target), isNull);
        expect(find.text('See Seeker One'), findsNothing);
        await check('rl01', find.byType(ZyraRequestsFullSheet));
        await h.tapText('Not now');
        h.assertPage('profile');

        await mount(true, waiting: 5);
        await h.tap('draft_profile_$_target');
        expect(h.shellFixture.model.stateFor(_target), isNull);
        expect(find.text('See Seeker One'), findsOneWidget);
        await check('rl02', find.byType(ZyraRequestsFullSheet));
        await h.tapText('See Seeker One');
        h.assertPage('one_upgrade');

        await mount(
          false,
          tab: 2,
          pages: const ['requests'],
          requestsTab: 1,
          model: _model(_sent),
        );
        expect(find.text('3 of 20 requests waiting'), findsOneWidget);
        await check('rl03', find.byType(ZyraSentRequestCount));

        await mount(
          true,
          tab: 2,
          pages: const ['requests'],
          requestsTab: 1,
          model: _model(_sent),
          waiting: 2,
        );
        expect(
          find.text('5 of 5 requests waiting · cancel one to ask someone new'),
          findsOneWidget,
        );
        await check('rl04', find.byType(ZyraSentRequestCount));
        await h.tap('concept_request_draft-sara_header');
        await h.tap('draft_cancel_draft-sara');
        expect(find.text('4 of 5 requests waiting'), findsOneWidget);
        await t.binding.handlePopRoute();
        await h.flush();
        await h.tap('floating-nav-item-0');
        final current = h.latest.browseId!;
        await h.tap('draft_profile_$current');
        expect(h.shellFixture.model.stateFor(current), DraftJourneyState.sent);
      },
      timeout: const Timeout(Duration(minutes: 6)),
    );
  }

  testWidgets('LOCK44 Pause blocks a send before checking LOCK48 capacity', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final h = BaselineHarness(
      t,
      group: 'line146_pause',
      outputRoot: '$_root/screens',
      evidenceRoot: '$_root/screens',
      reduceMotion: true,
    );
    await h.mount(
      checkpoint: _checkpoint(basic: true, model: _model()),
      previewClock: _clock,
      seededWaitingRequests: 4,
    );
    final browse = t.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    final firstProfile = browse.profiles[browse.selectedIndex];
    final model = h.shellFixture.model;
    expect(model.canRequest(firstProfile.id), isTrue);

    await h.tap('floating-nav-item-4');
    await h.tap('concept_settings');
    final settings = find
        .descendant(
          of: h.key('concept-current-settings-scroll'),
          matching: find.byType(Scrollable),
        )
        .first;
    await t.scrollUntilVisible(
      h.key('concept_settings_visibility'),
      160,
      scrollable: settings,
    );
    await h.tap('concept_settings_visibility');
    await h.tap('pause_private_action');
    expect(model.ownProfilePrivacy!.paused, isTrue);
    await t.binding.handlePopRoute();
    await h.flush();
    await t.binding.handlePopRoute();
    await h.flush();
    await h.tap('floating-nav-item-0');
    expect(h.key('paused_profiles_card'), findsOneWidget);
    browse.onRequest!(firstProfile);
    expect(model.request(firstProfile.id), isFalse);
    await h.flush();
    expect(model.waitingSentProfileIds, isEmpty);
    expect(find.byType(ZyraRequestsFullSheet), findsNothing);

    await h.tap('paused_profiles_show_again');
    expect(model.ownProfilePrivacy!.paused, isFalse);
    expect(h.key('paused_profiles_card'), findsNothing);
    await h.tap('draft_profile_${firstProfile.id}');
    expect(model.waitingSentProfileIds, {firstProfile.id});
    expect(await swipeProfileForControlKey(t, 'concept_next_profile'), isTrue);
    await h.flush();
    final secondId = h.latest.browseId!;
    expect(secondId, isNot(firstProfile.id));
    await h.tap('draft_profile_$secondId');
    expect(find.byType(ZyraRequestsFullSheet), findsOneWidget);
    expect(model.waitingSentProfileIds, {firstProfile.id});
  });

  testWidgets('LOCK48 restart uses the same One waiting guard', (t) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final model = _model(['draft-sara']);
    expect(model.simulateRecipientAccept('draft-sara'), isTrue);
    expect(model.end('draft-sara'), isTrue);
    final now = _clock().add(const Duration(days: 2));
    final h = BaselineHarness(
      t,
      group: 'line146_restart',
      outputRoot: '$_root/screens',
      evidenceRoot: '$_root/screens',
      reduceMotion: true,
    );
    await h.mount(
      tab: 2,
      pages: const ['ended'],
      model: model,
      previewClock: () => now,
      seededWaitingRequests: 20,
    );
    await h.tap('draft_journey_draft-sara_header');
    await h.tapText('Request a new Journey');
    await h.tap('draft_restart_send_draft-sara');
    expect(find.byType(ZyraRequestsFullSheet), findsOneWidget);
    expect(h.shellFixture.model.waitingSentProfileIds, isEmpty);
    await h.tapText('See sent requests');
    h.assertPage('requests');
    expect(h.latest.requestsTab, 1);
  });

  testWidgets('LOCK46 restart respects Pause and rejects a retired callback', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    const subject = 'draft-sara';
    final fixture = _model([subject]);
    expect(fixture.simulateRecipientAccept(subject), isTrue);
    expect(fixture.end(subject), isTrue);
    final now = _clock().add(const Duration(days: 2));
    final h = BaselineHarness(
      t,
      group: 'line146_restart_pause',
      outputRoot: '$_root/screens',
      evidenceRoot: '$_root/screens',
      reduceMotion: true,
    );
    await h.mount(
      tab: 2,
      pages: const ['ended'],
      model: fixture,
      previewClock: () => now,
      seededWaitingRequests: 19,
    );
    await h.tap('draft_journey_${subject}_header');
    await h.tapText('Request a new Journey');
    final action = h.key('draft_restart_send_$subject');
    final model = h.shellFixture.model;
    final privacy = model.ownProfilePrivacy!;
    expect(model.canRequestEndedJourney(subject), isTrue);
    final beforePause = t.widget<ButtonStyleButton>(action).onPressed!;
    expect(privacy.pause(), isTrue);
    beforePause();
    expect(model.requestEndedJourney(subject), isFalse);
    await h.flush();
    expect(model.restartExpiresAt(subject), isNull);
    expect(find.byType(ZyraRequestsFullSheet), findsNothing);

    expect(privacy.showProfile(), isTrue);
    await h.flush();
    final beforeLeaving = t.widget<ButtonStyleButton>(action).onPressed!;
    await t.binding.handlePopRoute();
    await h.flush();
    h.assertPage('ended');
    beforeLeaving();
    expect(model.restartExpiresAt(subject), isNull);
    expect(find.byType(ZyraRequestsFullSheet), findsNothing);

    await h.tapText('Request a new Journey');
    await h.tap('draft_restart_send_$subject');
    expect(
      model.restartExpiresAt(subject),
      now.toUtc().add(ViewRequestDraftModel.restartLifetime),
    );
    expect(model.waitingSentProfileIds, {subject});
    expect(t.widget<ButtonStyleButton>(action).onPressed, isNull);
  });
}
