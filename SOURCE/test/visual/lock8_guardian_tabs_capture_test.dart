import 'package:flutter/material.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'baseline_capture_support.dart';

const _capture = bool.fromEnvironment('ZYRA_LOCK8_CAPTURE');
const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _output = '$_root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK8_GUARDIAN_TABS_2026-10-30';
Finder _key(String id) => find.byKey(ValueKey(id));
ZyraGuardianTabsPresentation _view(WidgetTester t) =>
    t.widget(find.byType(ZyraGuardianTabsPresentation));

BaselineHarness _h(WidgetTester t, String group) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(
    t,
    group: 'lock8_$group',
    outputRoot: _output,
    evidenceRoot: _evidence,
    flatOutput: true,
  );
}

Future<void> _mount(
  BaselineHarness h, {
  int tab = 2,
  List<String> pages = const [],
  ZyraGuardianTabsSnapshot state = const ZyraGuardianTabsSnapshot(),
  int activeJourneys = 0,
}) async {
  final model = ViewRequestDraftModel(capacity: 3);
  if (activeJourneys > 0) expect(model.seedJourneys(activeJourneys), isTrue);
  await h.mount(
    guardian: true,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: true,
      model: model.snapshot(),
      tab: tab,
      pages: pages,
      guardianTabs: state,
    ),
  );
}

Future<void> _cap(BaselineHarness h, String name, String state) async {
  if (_capture) {
    if (name == 'g15_my_zyra' || name == 'g20_connect_with_guardian') {
      await h.mount(guardian: true, checkpoint: h.latest);
    }
    await h.capture(
      'guardian_tabs',
      name,
      state,
      'Actual admitted offline Founder Guardian shell; LOCK8 V2.',
      fileName: name == 'g13' ? 'g13_profile.png' : null,
    );
  }
}

Future<void> _tab(BaselineHarness h, int index) async {
  final finder = _key('floating-nav-item-$index');
  await h.tester.tapAt(h.tester.getCenter(finder));
  await h.flush();
  await h.tester.tapAt(h.tester.getCenter(finder));
  await h.flush();
}

Future<void> _back(BaselineHarness h) async {
  await returnZyraPreviewPage(h.tester);
  await h.flush();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  testWidgets(
    'LOCK8 opens My ZYRA and has five ordered tabs; real transitions and attention',
    (t) async {
      final h = _h(t, 'root');
      await _mount(h);
      expect(h.latest.tab, 2);
      expect(
        t
            .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
            .items
            .map((i) => i.label),
        ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile'],
      );
      expect(t.getSize(_key('compact-nav-surface')), const Size(234, 50));
      expect(find.text('Guardian Dashboard'), findsNothing);
      expect(find.textContaining('Insights'), findsNothing);
      expect(find.text('1 new'), findsWidgets);
      await _cap(h, 'g01_my_zyra', 'needs_you');
      await h.tap('guardian_pause');
      expect(_view(t).state.review, ZyraGuardianReview.paused);
      expect(find.textContaining('fresh 48 hours.'), findsOneWidget);
      await _cap(h, 'g15_my_zyra', 'review_paused');
      await _tab(h, 1);
      expect(find.text('No current Journey'), findsOneWidget);
      await _tab(h, 3);
      expect(find.text('Journey with Sara · Paused by family'), findsOneWidget);
      await h.tap('guardian_seeker_0');
      // V6 uses permitted active Journeys; this unseeded model has only requests.
      expect(find.text('No current Journey'), findsOneWidget);
      await _back(h);
      await _tab(h, 2);
      await h.tap('guardian_reopen');
      expect(find.textContaining('48 hours left'), findsOneWidget);
      // A retained handler cannot apply a second decision after its owner changes.
      final old = _view(t).onAction;
      await h.tap('guardian_continue');
      old('pause');
      await h.flush();
      expect(_view(t).state.review, ZyraGuardianReview.continued);
      await h.tap('guardian_received');
      await h.tap('guardian_accept');
      await _back(h);
      expect(find.text('Nothing needs you right now.'), findsOneWidget);
      await _tab(h, 1);
      expect(find.text('No current Journey'), findsOneWidget);
      expect(
        h.latest.model.states,
        {'draft-amira': DraftJourneyState.received},
        reason: 'Local review never advances the Seeker model.',
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK8 read-only Journey requests, switchers, confirmations and Network filter',
    (t) async {
      final h = _h(t, 'network');
      await _mount(h);
      await h.tap('guardian_requests');
      expect(find.text('Amira Rahman'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      await _cap(h, 'g02_journey_requests', 'received_all');
      await h.tap('guardian_requests_tab_1');
      await _cap(h, 'g03_journey_requests', 'sent_all');
      await h.tap('guardian_request_seeker');
      expect(find.text('for Adam ▾'), findsOneWidget);
      await h.tap('guardian_request_seeker');
      expect(find.text('for Yusuf ▾'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsNothing);
      expect(find.text('Main Guardian only'), findsOneWidget);
      await _mount(h, tab: 0);
      await _cap(h, 'g06_network', 'for_adam');
      expect(ZyraGuardianTabsState.network.every((p) => p.guardianOne), isTrue);
      expect(
        ZyraGuardianTabsState.candidates.any((p) => !p.guardianOne),
        isTrue,
      );
      await h.tap('guardian_introduce_confirm');
      await _cap(h, 'g07_introduce_to_adam', 'confirm');
      await h.tap('guardian_introduce_send');
      expect(find.text('Introduced'), findsOneWidget);
      await h.tap('guardian_connect_confirm');
      await _cap(h, 'g08_connect_with_guardian', 'confirm');
      await h.tap('guardian_connect_send');
      expect(find.text('Request sent'), findsOneWidget);
      expect(_view(t).state.sent.length, 1);
      await h.tap('guardian_seeker');
      expect(find.text('for Yusuf ▾'), findsOneWidget);
      expect(find.text('Introduce to\nYusuf'), findsOneWidget);
      final checkpoint = h.latest;
      await h.mount(guardian: true, checkpoint: checkpoint);
      expect(_view(t).state.sent, {'aisha'});
      expect(_view(t).state.introduced, {'adam:aisha'});
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK8 Connect accepted, private composer, not now and all empty states',
    (t) async {
      final h = _h(t, 'connect');
      await _mount(h);
      await h.tap('guardian_connect');
      await _cap(h, 'g16_connect_with_guardian', 'sent_empty');
      await h.tap('guardian_connect_tab_1');
      await _cap(h, 'g17_connect_with_guardian', 'received');
      expect(
        find.textContaining('Only the two of you see it.'),
        findsOneWidget,
      );
      await h.tap('guardian_accept');
      await _cap(h, 'g18_connect_with_guardian', 'received_accepted');
      expect(find.text('Connected · private chat'), findsOneWidget);
      await h.tap('guardian_chat');
      await _cap(h, 'g19_guardian_chat', 'new');
      await t.enterText(find.byType(TextField), 'Assalamu alaikum');
      await t.tap(find.byKey(const ValueKey('circle_send_button')));
      await h.flush();
      expect(find.text('Assalamu alaikum'), findsOneWidget);
      expect(find.text('A private chat'), findsNothing);
      await _mount(
        h,
        pages: ['guardian_connect'],
        state: const ZyraGuardianTabsSnapshot(connectReceived: true),
      );
      await h.tap('guardian_dismiss');
      await _cap(h, 'g20_connect_with_guardian', 'received_empty');
      expect(find.text('No requests received yet.'), findsOneWidget);
      expect(
        h.latest.guardianTabs.connection,
        ZyraGuardianConnection.dismissed,
      );
      await _mount(
        h,
        pages: ['guardian_connect'],
        state: const ZyraGuardianTabsSnapshot(sent: {'aisha'}),
      );
      await _cap(h, 'g04_connect_with_guardian', 'sent');
      await _mount(h, pages: ['guardian_introductions']);
      await _cap(h, 'g05_introductions_made', 'empty');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK8 Journeys Seekers Profile and all-caught-up masters; Additional has no decisions',
    (t) async {
      final h = _h(t, 'pages');
      await _mount(h, tab: 1, activeJourneys: 1);
      await _cap(h, 'g09_journeys', 'adam');
      await _mount(h, tab: 3);
      await _cap(h, 'g10_seekers', 'list');
      await h.tap('guardian_seeker_0');
      await _cap(h, 'g11_seeker', 'adam_main');
      expect(find.text('Not shared'), findsOneWidget);
      await _mount(h, tab: 3);
      await h.tap('guardian_seeker_1');
      await _cap(h, 'g12_seeker', 'yusuf_additional');
      expect(find.text('Main Guardian only'), findsOneWidget);
      expect(find.text('Open Journey'), findsNothing);
      expect(find.text('Continue'), findsNothing);
      expect(find.text('Pause'), findsNothing);
      await _mount(h, tab: 4);
      await _cap(h, 'g13', 'profile');
      await _mount(
        h,
        state: const ZyraGuardianTabsSnapshot(
          review: ZyraGuardianReview.continued,
          connection: ZyraGuardianConnection.accepted,
          sent: {'aisha'},
        ),
      );
      await _cap(h, 'g14_my_zyra', 'all_caught_up');
      expect(find.text('1 sent'), findsOneWidget);
      expect(find.textContaining('NEEDS YOU'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK8 fresh role launch defaults to My ZYRA',
    (t) async {
      final h = _h(t, 'fresh');
      await h.mountPresentation(
        child: ZyraOneJourneyConceptShell(
          canAct: () => true,
          onExit: () {},
          initialGuardianRole: true,
        ),
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: ViewRequestDraftModel().snapshot(),
          tab: 2,
          pages: const [],
        ),
      );
      expect(find.text('My ZYRA'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK8 Additional authority and revoked connection fail closed',
    (t) async {
      final h = _h(t, 'authority');
      final model = ViewRequestDraftModel(capacity: 3);
      final saved = ZyraPreviewNavigationCheckpoint(
        guardian: true,
        model: model.snapshot(),
        tab: 2,
        pages: const [],
        mainGuardianId: 'draft-guardian-yusuf',
      );
      await h.mount(guardian: true, checkpoint: saved);
      expect(_view(t).adamMain, isFalse);
      expect(find.text('Continue'), findsNothing);
      expect(find.text('Pause'), findsNothing);
      _view(t).onAction('continue');
      await h.flush();
      expect(h.latest.guardianTabs.review, ZyraGuardianReview.open);
      await h.tap('guardian_requests');
      expect(find.text('Amira Rahman'), findsNothing);
      await h.mount(
        guardian: true,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: model.snapshot(),
          tab: 2,
          pages: const ['guardian_private_chat'],
          mainGuardianId: 'draft-guardian-yusuf',
          guardianTabs: const ZyraGuardianTabsSnapshot(
            connection: ZyraGuardianConnection.accepted,
          ),
        ),
      );
      expect(find.byType(ZyraGuardianPrivateChat), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK8 long return retains local decisions while returning My ZYRA',
    (t) async {
      final h = _h(t, 'longreturn');
      final saved = ZyraPreviewNavigationCheckpoint(
        guardian: true,
        model: ViewRequestDraftModel(capacity: 3).snapshot(),
        tab: 0,
        pages: const ['guardian_connect'],
        guardianTabs: const ZyraGuardianTabsSnapshot(
          review: ZyraGuardianReview.paused,
          connection: ZyraGuardianConnection.dismissed,
          sent: {'aisha'},
          introduced: {'adam:aisha'},
        ),
      );
      await h.mountPresentation(
        child: ZyraOneJourneyConceptShell(
          canAct: () => true,
          onExit: () {},
          initialGuardianRole: true,
          initialCheckpoint: saved,
          restoreLocation: false,
        ),
        checkpoint: saved,
      );
      expect(_view(t).page, 'my_zyra');
      expect(_view(t).state.review, ZyraGuardianReview.paused);
      expect(_view(t).state.connection, ZyraGuardianConnection.dismissed);
      expect(_view(t).state.sent, {'aisha'});
      expect(_view(t).state.introduced, {'adam:aisha'});
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK8 Yusuf Circle isolates the local seeker identity and topics',
    (t) async {
      final h = _h(t, 'circle');
      await _mount(h, tab: 3);
      await h.tap('guardian_seeker_1');
      await h.tap('guardian_circle');
      final circle = t.widget<ZyraGuardianCircleScreen>(
        find.byType(ZyraGuardianCircleScreen),
      );
      expect(circle.seekerFirstName, 'Yusuf');
      expect(circle.seekerId, 'draft-linked-yusuf');
      final data = circle.previewData!;
      expect(data.participants.any((p) => p.firstName == 'Adam'), isFalse);
      expect(
        data.participants.singleWhere((p) => p.isCurrentUser).isMainGuardian,
        isFalse,
      );
      expect(data.contexts, isEmpty);
      expect(
        data.messages.expand((m) => m.readBy).any((r) => r.firstName == 'Adam'),
        isFalse,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK8 local private chat report and block end only this connection',
    (t) async {
      final h = _h(t, 'report');
      await _mount(
        h,
        pages: const ['guardian_connect'],
        state: const ZyraGuardianTabsSnapshot(connectReceived: true),
      );
      await h.tap('guardian_accept');
      await h.tap('guardian_chat');
      final stale = t.widget<ZyraGuardianPrivateChat>(
        find.byType(ZyraGuardianPrivateChat),
      );
      await t.longPress(_key('guardian_chat_report'));
      await h.flush();
      final report = t.widget<ZyraDraftReportPresentation>(
        find.byType(ZyraDraftReportPresentation),
      );
      expect(report.canSelect!(), isTrue);
      report.onBlock!();
      await h.flush();
      expect(h.latest.guardianTabs.connection, ZyraGuardianConnection.blocked);
      stale.onSend();
      stale.onReport();
      report.onBlock!();
      await h.flush();
      expect(find.byType(ZyraGuardianPrivateChat), findsNothing);
      expect(h.latest.pages, ['guardian_connect']);
      expect(h.latest.model.states, {
        'draft-amira': DraftJourneyState.received,
      });
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK8 Network actions remain clear of nav and keep master label colours',
    (t) async {
      final h = _h(t, 'geometry');
      await _mount(h, tab: 0);
      final nav = t.getRect(_key('compact-nav-surface'));
      for (final action in ['introduce_confirm', 'connect_confirm']) {
        final target = _key('guardian_$action');
        final rect = t.getRect(target);
        expect(rect.bottom + 8, lessThanOrEqualTo(nav.top));
        expect(target.hitTestable(), findsOneWidget);
        final label = t.widget<Text>(
          find.descendant(of: target, matching: find.byType(Text)),
        );
        expect(label.style!.color, ZyraColors.foreground);
      }
      expect(t.widget<Text>(find.text('A')).style!.fontWeight, FontWeight.w700);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK8 all five tabs remain readable on compact phone at 200 percent text',
    (t) async {
      final h = _h(t, 'accessibility');
      final saved = ZyraPreviewNavigationCheckpoint(
        guardian: true,
        model: ViewRequestDraftModel(capacity: 3).snapshot(),
        tab: 2,
        pages: const [],
      );
      await h.mountPresentation(
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: ZyraOneJourneyConceptShell(
              canAct: () => true,
              onExit: () {},
              initialGuardianRole: true,
              initialCheckpoint: saved,
            ),
          ),
        ),
        checkpoint: saved,
      );
      t.view.physicalSize = const Size(1170, 2532);
      await h.flush();
      for (var i = 0; i < 5; i++) {
        t
            .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
            .onTap(i);
        await h.flush();
        expect(t.takeException(), isNull);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK8 Network arrows stop at both boundaries and keep the master colours',
    (t) async {
      final h = _h(t, 'boundaries');
      await _mount(h, tab: 0);
      expect(t.widget<IconButton>(_key('guardian_previous')).onPressed, isNull);
      final next = t.widget<IconButton>(_key('guardian_next'));
      expect((next.icon as Icon).color, ZyraColors.journeyGold);
      final staleNext = next.onPressed!;
      await h.tap('guardian_next');
      expect(_view(t).state.networkIndex, 1);
      expect(t.widget<IconButton>(_key('guardian_next')).onPressed, isNull);
      staleNext();
      _view(t).onAction('next');
      await h.flush();
      expect(_view(t).state.networkIndex, 1);
      await h.tap('guardian_previous');
      expect(_view(t).state.networkIndex, 0);
      expect(t.widget<IconButton>(_key('guardian_previous')).onPressed, isNull);
      _view(t).onAction('previous');
      await h.flush();
      expect(_view(t).state.networkIndex, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
