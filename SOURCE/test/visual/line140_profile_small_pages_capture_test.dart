// LOCK 46 focused local preview routes and bounded rendered replay.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_guardian_family_preview.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_profile_small_pages_preview.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/models/zyra_developer_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

import '../support/guardian_card_driver.dart';
import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _root = 'build/line140';
const _capture = bool.fromEnvironment('ZYRA_LINE140_CAPTURE');
const _peer = 'draft-sara';
final _captureFailures = <String, Object>{};
Finder _key(String id) => find.byKey(ValueKey(id));

BaselineHarness _harness(
  WidgetTester tester,
  String name, {
  Size size = const Size(430, 932),
  double scale = 1,
}) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'line140_$name',
    outputRoot: '$_root/screens',
    evidenceRoot: '$_root/screens',
    flatOutput: true,
    logicalSize: size,
    textScale: scale,
    safePadding: size.width == 375
        ? const EdgeInsets.only(top: 20)
        : const EdgeInsets.only(top: 59, bottom: 34),
  );
}

ViewRequestDraftModel _journeyModel(DateTime Function() clock) {
  final model = ViewRequestDraftModel(capacity: 3, clock: clock);
  expect(model.seedJourneys(1), isTrue);
  expect(model.setPreviewJourneyStage(_peer, 'phase_1'), isTrue);
  expect(model.stageFor(_peer)?.order, 4);
  return model;
}

ZyraPreviewNavigationCheckpoint _familyCheckpoint({
  bool guardian = false,
  ViewRequestDraftModel? model,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: guardian,
  model: (model ?? ViewRequestDraftModel(capacity: 3)).snapshot(),
  tab: 4,
  pages: const [],
  guardianFamily: ZyraGuardianFamilyPreviewSnapshot(
    freePlaces: 1,
    sequence: 1,
    invites: [
      ZyraGuardianFamilyInvite(
        revision: 1,
        guardianId: 'draft-guardian-hassan',
        guardianName: 'Hassan',
        seekerId: 'local-payer',
        seekerName: 'Adam',
        seekerGender: 'male',
        relationship: 'Father',
        main: true,
        sentAt: DateTime(2026, 11, 24),
        status: ZyraGuardianFamilyInviteStatus.accepted,
      ),
    ],
  ),
);

Future<void> _back(BaselineHarness h) async {
  await h.tester.binding.handlePopRoute();
  await h.flush();
}

void _noPageChrome() {
  expect(find.byType(BackButton), findsNothing);
  expect(_key('floating-nav-item-0'), findsNothing);
}

void _repaint(RenderObject object) {
  object.visitChildren(_repaint);
  object.markNeedsPaint();
}

Future<void> _checkAndCapture(BaselineHarness h, String name) async {
  final previous = debugDisableShadows;
  try {
    debugDisableShadows = false;
    await h.tester.pump(const Duration(milliseconds: 2600));
    await h.prepareRasterFrame();
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      _key('zyra-founder-baseline-boundary'),
    );
    _repaint(boundary);
    await h.tester.pump();
    final result = await auditZyraRenderedText(h.tester, boundary);
    // The audit raster is not the saved comparison PNG. Repaint the actual
    // tree again while real shadows remain enabled before saving it.
    _repaint(boundary);
    await h.tester.pump();
    expect(debugDisableShadows, isFalse);
    await h.capture(
      'profile_small_pages',
      name,
      'lock46',
      name,
      fileName: '$name.png',
    );
    await h.tester.runAsync(() async {
      final file = File('$_root/screens/$name.png');
      final saved = await file.readAsBytes();
      final record = File('$_root/audit/$name.json');
      await record.parent.create(recursive: true);
      await record.writeAsString(
        jsonEncode({
          'audit': result.toJson(),
          'savedPng': file.path,
          'sha256': sha256.convert(saved).toString(),
          'realShadows': true,
          'repaintBeforeAudit': true,
          'repaintAfterAuditBeforeSave': true,
          'logicalWidth': h.logicalSize.width,
          'logicalHeight': h.logicalSize.height,
          'textScale': h.textScale,
        }),
      );
    });
    if (result.failures.isNotEmpty) _captureFailures[name] = result.toJson();
    expect(h.tester.takeException(), isNull);
  } finally {
    debugDisableShadows = previous;
  }
}

Future<void> _capturePage(BaselineHarness h, String page, String name) async {
  _noPageChrome();
  await _checkAndCapture(h, name);
  final scroll = find.descendant(
    of: _key('${page}_scroll'),
    matching: find.byType(Scrollable),
  );
  if (scroll.evaluate().isNotEmpty) {
    final state = h.tester.state<ScrollableState>(scroll.first);
    if (state.position.maxScrollExtent > 1) {
      state.position.jumpTo(state.position.maxScrollExtent);
      await h.flush();
      await _checkAndCapture(h, '${name}__bottom');
    }
  }
}

Future<void> _openRestart(BaselineHarness h) async {
  await h.tap('draft_journey_${_peer}_header');
  await h.tap('draft_ended_restart_$_peer');
  h.assertPage('ended_restart');
}

Future<void> _openMakeMain(BaselineHarness h) async {
  await h.tap('guardian-card-menu');
  await h.tap('guardian-make-main');
  await h.tester.pumpAndSettle();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  testWidgets('LOCK46 Profile routes and paid Guardian Membership stay local', (
    tester,
  ) async {
    final h = _harness(tester, 'routes');
    for (final guardian in [false, true]) {
      await h.mount(guardian: guardian, tab: 4);
      await h.tap('concept_subscriptions');
      h.assertPage('subscriptions');
      expect(
        _key(
          guardian
              ? 'small_pages_guardian_places'
              : 'small_pages_seeker_places',
        ),
        findsOneWidget,
      );
      _noPageChrome();
      expect(find.text('Your subscriptions'), findsNothing);
      await _back(h);
      await h.tap('concept_invite');
      expect(_key('small_pages_invite'), findsOneWidget);
      _noPageChrome();
      expect(
        find.text(guardian ? 'zyra.app/i/HASSAN3K' : 'zyra.app/i/ADAM7Q'),
        findsOneWidget,
      );
      await _back(h);
      await h.tap('concept_membership');
      h.assertPage('membership');
      expect(_key('membership_paid_page'), findsOneWidget);
    }
    await h.mount(tab: 4);
    await h.tap('switch-account-button');
    expect(_key('small_pages_switch_profile'), findsOneWidget);
    _noPageChrome();
    await h.tap('small_pages_switch_role');
    expect(h.latest.guardian, isTrue);
    expect(h.latest.pages, isEmpty);
    expect(find.text('Switched.'), findsOneWidget);
  });

  testWidgets('LOCK46 solo profiles enter the other role sign-up', (
    tester,
  ) async {
    final h = _harness(tester, 'one-role');
    for (final guardian in [false, true]) {
      await h.mount(
        guardian: guardian,
        tab: 4,
        profileSmallPageSample: guardian
            ? ZyraProfileSmallPageSample.guardianOnly
            : ZyraProfileSmallPageSample.seekerOnly,
      );
      await h.tap('switch-account-button');
      final preview = tester.widget<ZyraSwitchProfilePreview>(
        find.byType(ZyraSwitchProfilePreview),
      );
      expect(preview.otherRoleMissing, isTrue);
      expect(
        find.text(guardian ? 'Add a Seeker profile' : 'Add a Guardian profile'),
        findsOneWidget,
      );
      final before = h.latest.model.states;
      await h.tap('small_pages_add_role');
      h.assertPage('signup');
      expect(
        tester
            .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
            .controller
            .guardian,
        !guardian,
      );
      expect(h.latest.guardian, guardian);
      expect(h.latest.model.states, before);
    }
  });

  testWidgets('LOCK46 Guardian Basic and empty places are on Profile', (
    tester,
  ) async {
    final h = _harness(tester, 'guardian-states');
    await h.mount(guardian: true, guardianMembership: 'Guardian Basic', tab: 4);
    await h.tap('concept_subscriptions');
    expect(find.text('Guardian Basic · Free plan'), findsOneWidget);
    expect(find.text('You pay nothing'), findsOneWidget);
    expect(find.text('Adam'), findsOneWidget);

    await h.mount(
      guardian: true,
      tab: 4,
      profileSmallPageSample: ZyraProfileSmallPageSample.guardianNoSeekers,
    );
    expect(find.text('Adam, Yusuf'), findsNothing);
    await h.tap('concept_subscriptions');
    expect(find.text('Guardian One · Your own plan'), findsOneWidget);
    expect(find.text('No Seekers yet'), findsOneWidget);
    expect(find.text('Use + in the Seekers tab to add one'), findsOneWidget);
  });

  testWidgets('LOCK46 clipboard and share pass only sample link and expire', (
    tester,
  ) async {
    final clipboard = <String>[];
    final shares = <Map<dynamic, dynamic>>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const share = MethodChannel('dev.fluttercommunity.plus/share');
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(share, (call) async {
      shares.add(call.arguments as Map);
      return '';
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      messenger.setMockMethodCallHandler(share, null);
    });
    final h = _harness(tester, 'share');
    for (final guardian in [false, true]) {
      await h.mount(guardian: guardian, tab: 4);
      await h.tap('concept_invite');
      final page = tester.widget<ZyraInvitePreview>(
        find.byType(ZyraInvitePreview),
      );
      final link = guardian ? 'zyra.app/i/HASSAN3K' : 'zyra.app/i/ADAM7Q';
      await h.tap('small_pages_copy_link');
      expect(clipboard.last, link);
      expect(find.text('Link copied.'), findsOneWidget);
      await h.tap('small_pages_share_link');
      expect(shares.last['text'], link);
      expect(shares.last['subject'], anyOf(isNull, ''));
      final before = (clipboard.length, shares.length);
      await _back(h);
      page.onCopy();
      page.onShare();
      await h.flush();
      expect((clipboard.length, shares.length), before);
    }
  });

  testWidgets('LOCK46 restart sends once and old callback cannot resend', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 11, 24, 12);
    final model = _journeyModel(() => now);
    expect(model.end(_peer), isTrue);
    now = now.add(const Duration(hours: 25));
    final h = _harness(tester, 'restart');
    await h.mount(
      tab: 2,
      pages: const ['ended'],
      model: model,
      personId: _peer,
      previewClock: () => now,
    );
    await _openRestart(h);
    final page = tester.widget<ZyraRequestRestartPreview>(
      find.byType(ZyraRequestRestartPreview),
    );
    expect(page.sent, isFalse);
    expect(page.unavailableReason, isNull);
    await h.tap('small_pages_request_restart');
    final sentAt = h.latest.model.restartRequestedAt[_peer];
    expect(sentAt, now);
    expect(find.text('Request sent'), findsOneWidget);
    expect(
      find.text('Request sent. Sara will see it in her requests.'),
      findsOneWidget,
    );
    page.onRequest();
    await h.flush();
    expect(h.latest.model.restartRequestedAt[_peer], sentAt);
    await _back(h);
    page.onRequest();
    await h.flush();
    expect(h.latest.model.restartRequestedAt[_peer], sentAt);
  });

  testWidgets('LOCK46 restart preserves Basic and first-day unavailable words', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 11, 24, 12);
    final model = _journeyModel(() => now);
    expect(model.end(_peer), isTrue);
    final h = _harness(tester, 'unavailable');
    for (final basic in [false, true]) {
      await h.mount(
        tab: 2,
        pages: const ['ended'],
        model: model,
        personId: _peer,
        previewClock: () => now,
        seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
      );
      await _openRestart(h);
      final page = tester.widget<ZyraRequestRestartPreview>(
        find.byType(ZyraRequestRestartPreview),
      );
      expect(
        page.unavailableReason,
        basic
            ? 'Restart requests are not available in this preview.'
            : 'You can ask 24 hours after the Journey ends. The request lasts 30 days.',
      );
      page.onRequest();
      await h.flush();
      expect(h.latest.model.restartRequestedAt, isEmpty);
      _noPageChrome();
    }
  });

  testWidgets('LOCK46 Main sheet cancel dismiss and authentication ordering', (
    tester,
  ) async {
    var checks = 0;
    var allow = false;
    final h = _harness(tester, 'main');
    await h.mount(
      tab: 3,
      confirmSensitiveAction: () async {
        checks++;
        return allow;
      },
    );
    await swipeGuardianCard(tester);
    await h.flush();
    await _openMakeMain(h);
    expect(find.text('Yusuf will be your Main Guardian'), findsOneWidget);
    expect(find.text('Make Yusuf Main'), findsOneWidget);
    expect(checks, 0);
    await h.tap('guardian-make-main-confirmation-keep');
    expect(checks, 0);
    expect(h.latest.mainGuardianId, 'draft-guardian-hassan');
    await _openMakeMain(h);
    await tester.tapAt(const Offset(10, 80));
    await h.tester.pumpAndSettle();
    await h.flush();
    expect(checks, 0);
    expect(_key('guardian-make-main-confirmation'), findsNothing);
    await _openMakeMain(h);
    await tester.drag(_key('zyra-confirm-handle'), const Offset(0, 240));
    await h.tester.pumpAndSettle();
    await h.flush();
    expect(checks, 0);
    expect(_key('guardian-make-main-confirmation'), findsNothing);
    await _openMakeMain(h);
    await h.tap('guardian-make-main-confirmation-approve');
    expect(checks, 1);
    expect(h.latest.mainGuardianId, 'draft-guardian-hassan');
    expect(find.text('Yusuf is now your Main Guardian.'), findsNothing);
    allow = true;
    await _openMakeMain(h);
    await h.tap('guardian-make-main-confirmation-approve');
    expect(checks, 2);
    expect(h.latest.mainGuardianId, 'draft-guardian-yusuf');
    expect(find.text('Yusuf is now your Main Guardian.'), findsOneWidget);
    expect(h.latest.pages, isNot(contains('guardian_main_notice')));
    expect(_key('concept_main_guardian_continue'), findsNothing);
  });

  for (final size in [const Size(430, 932), const Size(375, 667)]) {
    for (final scale in [1.0, 1.3]) {
      final suffix = size.width == 430 && scale == 1
          ? ''
          : '__${size.width.toInt()}x${size.height.toInt()}_${scale.toStringAsFixed(1)}';
      testWidgets('LOCK46 bounded master replay ${size.width} scale $scale', (
        tester,
      ) async {
        _captureFailures.clear();
        final h = _harness(tester, 'captures$suffix', size: size, scale: scale);
        var now = DateTime.utc(2026, 11, 24, 12);
        final model = _journeyModel(() => now);
        await h.mount(
          checkpoint: _familyCheckpoint(model: model),
          previewClock: () => now,
        );
        await h.tap('concept_subscriptions');
        await _capturePage(
          h,
          'small_pages_seeker_places',
          'ls01_your_places$suffix',
        );
        await _back(h);
        await h.tap('switch-account-button');
        await _capturePage(
          h,
          'small_pages_switch_profile',
          'ls02_switch_profile$suffix',
        );
        await _back(h);
        await h.tap('concept_invite');
        await _capturePage(
          h,
          'small_pages_invite',
          'ls03_invite_someone$suffix',
        );

        expect(model.end(_peer), isTrue);
        now = now.add(const Duration(hours: 25));
        await h.mount(
          tab: 2,
          pages: const ['ended'],
          model: model,
          personId: _peer,
          previewClock: () => now,
        );
        await _openRestart(h);
        await _capturePage(
          h,
          'small_pages_restart',
          'ls04_request_restart$suffix',
        );
        await h.tap('small_pages_request_restart');
        await _capturePage(h, 'small_pages_restart', 'request_sent$suffix');

        final recent = _journeyModel(() => now);
        expect(recent.end(_peer), isTrue);
        for (final basic in [false, true]) {
          await h.mount(
            tab: 2,
            pages: const ['ended'],
            model: recent,
            personId: _peer,
            previewClock: () => now,
            seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
          );
          await _openRestart(h);
          await _capturePage(
            h,
            'small_pages_restart',
            '${basic ? 'restart_basic_unavailable' : 'restart_first_day'}$suffix',
          );
        }

        await h.mount(tab: 3, previewClock: () => now);
        // The real shared sheet renders the master's explicit Ibrahim sample.
        // Its dimmed Guardian-card backdrop is outside the ls05 judgment.
        final pending = showZyraGuardianManagementConfirm(
          context: tester.element(find.byType(ZyraOneJourneyGuardianCards)),
          action: ZyraGuardianManagementAction.makeMain,
          person: const WaliLinkedPerson(
            id: 'ls05-ibrahim',
            firstName: 'Ibrahim',
          ),
          founderMakeMain: true,
        );
        await h.flush();
        await _checkAndCapture(h, 'ls05_make_main_sheet$suffix');
        await h.tap('guardian-make-main-confirmation-keep');
        expect(await pending, isFalse);

        await h.mount(guardian: true, tab: 4, previewClock: () => now);
        await h.tap('concept_subscriptions');
        await _capturePage(
          h,
          'small_pages_guardian_places',
          'ls06_guardian_your_places$suffix',
        );
        await _back(h);
        await h.tap('concept_invite');
        await _capturePage(
          h,
          'small_pages_invite',
          'ls07_guardian_invite$suffix',
        );
        await h.mount(
          guardian: true,
          tab: 4,
          checkpoint: _familyCheckpoint(guardian: true),
          previewClock: () => now,
        );
        await h.tap('concept_subscriptions');
        await _capturePage(
          h,
          'small_pages_guardian_places',
          'guardian_family_places$suffix',
        );
        for (final (guardian, master) in [
          (false, 'ls08_switch_profile__seeker_only'),
          (true, 'ls09_switch_profile__guardian_only'),
        ]) {
          await h.mount(
            guardian: guardian,
            tab: 4,
            profileSmallPageSample: guardian
                ? ZyraProfileSmallPageSample.guardianOnly
                : ZyraProfileSmallPageSample.seekerOnly,
            previewClock: () => now,
            checkpoint: guardian ? null : _familyCheckpoint(model: model),
          );
          await h.tap('switch-account-button');
          await _capturePage(h, 'small_pages_switch_profile', '$master$suffix');
        }
        await h.mount(
          guardian: true,
          tab: 4,
          guardianMembership: 'Guardian Basic',
          previewClock: () => now,
        );
        await h.tap('concept_subscriptions');
        await _capturePage(
          h,
          'small_pages_guardian_places',
          'ls10_guardian_your_places__basic$suffix',
        );
        await h.mount(
          guardian: true,
          tab: 4,
          profileSmallPageSample: ZyraProfileSmallPageSample.guardianNoSeekers,
          previewClock: () => now,
        );
        await h.tap('concept_subscriptions');
        await _capturePage(
          h,
          'small_pages_guardian_places',
          'ls11_guardian_your_places__no_seekers$suffix',
        );
        expect(_captureFailures, isEmpty);
      }, skip: !_capture);
    }
  }
}
