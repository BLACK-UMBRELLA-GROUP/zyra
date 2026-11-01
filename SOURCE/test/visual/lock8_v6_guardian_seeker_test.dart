// LOCK 8 V6: real admitted shell, explicit active-Sara fixture for master g11.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_seeker.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK8_V6_GUARDIAN_SEEKER_2026-11-01';
const capture = bool.fromEnvironment('ZYRA_LOCK8_V6_CAPTURE');
const hassan = 'draft-guardian-hassan', yusuf = 'draft-guardian-yusuf';
Finder key(String id) => find.byKey(ValueKey(id));

ViewRequestDraftModel fixture(int count) {
  final model = ViewRequestDraftModel(capacity: 3);
  if (count > 0) expect(model.seedJourneys(count), isTrue);
  return model;
}

Future<BaselineHarness> mount(
  WidgetTester t, {
  int seeker = 0,
  int count = 1,
  double scale = 1,
  ViewRequestDraftModel? model,
  bool additional = false,
  String? focusId,
}) async {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final h = BaselineHarness(
    t,
    group: 'lock8_v6',
    outputRoot: '$root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V6',
    evidenceRoot: evidence,
    flatOutput: true,
    textScale: scale,
  );
  await h.mount(
    guardian: true,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: true,
      model: (model ?? fixture(count)).snapshot(),
      tab: 3,
      pages: const ['guardian_seeker'],
      guardianTabs: ZyraGuardianTabsSnapshot(seeker: seeker),
      mainGuardianId: additional ? yusuf : hassan,
      guardianJourneyId: focusId,
    ),
  );
  return h;
}

ZyraGuardianTabsPresentation view(WidgetTester t) =>
    t.widget(find.byType(ZyraGuardianTabsPresentation));
Future<void> cap(BaselineHarness h, String name, String reached) async {
  if (capture && h.tester.view.physicalSize.width != 1290) {
    await h.tester.runAsync(() async {
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(
        key('zyra-founder-baseline-boundary'),
      );
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V6/$name',
        ).writeAsBytes(data!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  } else if (capture) {
    await h.capture('seeker', name, 'fixture', reached, fileName: name);
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  setUp(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
  });

  testWidgets(
    'V6 Main facts and 84pt monogram; Current Journey opens projected Sara',
    (t) async {
      final h = await mount(t);
      expect(find.text('YOU ARE HIS MAIN GUARDIAN'), findsOneWidget);
      for (final value in [
        'Main Guardian',
        'View and Chat',
        'You see them',
        'Not shared',
      ]) {
        expect(find.text(value), findsOneWidget);
      }
      expect(find.textContaining('20 Sep 2026'), findsOneWidget);
      expect(t.getSize(key('guardian_seeker_monogram')), const Size(84, 84));
      expect(find.text('YOUR ACCESS'), findsNothing);
      expect(find.text('JOURNEY'), findsNothing);
      expect(find.text('Open Journey'), findsNothing);
      expect(find.text('With Sara · Family Review'), findsOneWidget);
      final access = t.getSize(key('guardian_seeker_access')).height;
      final targets = t.getSize(key('guardian_seeker_targets')).height;
      expect(access, greaterThan(targets));
      expect(
        t.getRect(key('guardian_seeker_targets')).bottom,
        greaterThan(880),
      );
      await cap(
        h,
        'g11_seeker__adam_main.png',
        'Actual shell with explicit existing seedJourneys(1) active-Sara model; g11 master fixture',
      );
      await h.tap('guardian_journey');
      expect(h.latest.guardianJourneyId, 'draft-sara');
      expect(h.latest.pages.last, 'guardian');
    },
  );

  testWidgets(
    'V6 Additional Yusuf preserves facts, has no Adam Journey, opens Yusuf Circle',
    (t) async {
      final h = await mount(t, seeker: 1);
      expect(find.text('YOU ARE AN ADDITIONAL GUARDIAN'), findsOneWidget);
      expect(find.text('Additional Guardian'), findsOneWidget);
      expect(find.text('As Yusuf allows, Journey by Journey'), findsOneWidget);
      expect(find.text('Main Guardian only'), findsOneWidget);
      expect(find.textContaining('02 Oct 2026'), findsOneWidget);
      expect(find.text('No current Journey'), findsOneWidget);
      expect(key('guardian_journey'), findsNothing);
      await cap(
        h,
        'g12_seeker__yusuf_additional.png',
        'Actual existing Additional Yusuf sample; no current Journey, isolated Circle',
      );
      view(t).onAction('seeker_journey_draft-sara');
      await h.flush();
      expect(h.latest.pages.last, 'guardian_seeker');
      await h.tap('guardian_circle');
      final circle = t.widget<ZyraGuardianCircleScreen>(
        find.byType(ZyraGuardianCircleScreen),
      );
      expect(circle.seekerId, 'draft-linked-yusuf');
      expect(circle.seekerFirstName, 'Yusuf');
      expect(circle.previewData!.contexts, isEmpty);
    },
  );

  testWidgets('V6 actual default requests do not invent a current Journey', (
    t,
  ) async {
    final h = await mount(t, count: 0);
    expect(find.text('No current Journey'), findsOneWidget);
    expect(key('guardian_journey'), findsNothing);
    view(t).onAction('seeker_journey_draft-sara');
    await h.flush();
    expect(h.latest.pages.last, 'guardian_seeker');
    await cap(
      h,
      'g11_actual_default_no_current.png',
      'Actual unseeded model: received request only, no synthetic current Journey',
    );
  });

  for (final chat in [false, true]) {
    testWidgets(
      'V6 demoted Adam View grant retains existing Chat=$chat and denied target stays closed',
      (t) async {
        final model = fixture(2);
        expect(
          model.setSampleGuardianJourneyAccess(
            hassan,
            'draft-sara',
            viewEnabled: true,
            chatEnabled: chat,
          ),
          isTrue,
        );
        expect(
          model.setSampleGuardianJourneyAccess(
            hassan,
            'draft-aisha',
            viewEnabled: false,
          ),
          isTrue,
        );
        final h = await mount(t, model: model, additional: true);
        expect(find.text('YOU ARE AN ADDITIONAL GUARDIAN'), findsOneWidget);
        expect(find.text('As Adam allows, Journey by Journey'), findsOneWidget);
        final action = view(t).onAction;
        action('seeker_journey_draft-aisha');
        await h.flush();
        expect(h.latest.pages.last, 'guardian_seeker');
        await h.tap('guardian_journey');
        expect(h.latest.guardianJourneyId, 'draft-sara');
        expect(h.latest.pages.last, 'guardian');
        expect(h.latest.model.guardianAccess['$hassan|draft-sara']?.chat, chat);
        action('circle');
        await h.flush();
        expect(h.latest.pages.last, 'guardian');
      },
    );
  }

  testWidgets('V6 retained page actions expire after Circle navigation', (
    t,
  ) async {
    final h = await mount(t);
    final action = view(t).onAction;
    await h.tap('guardian_circle');
    expect(h.latest.pages.last, 'guardian_circle');
    action('seeker_journey_draft-sara');
    action('back');
    await h.flush();
    expect(h.latest.pages.last, 'guardian_circle');
  });

  testWidgets('V6 selected permitted Journey label and target stay on Aisha', (
    t,
  ) async {
    final h = await mount(t, count: 2, focusId: 'draft-aisha');
    expect(find.textContaining('With Aisha ·'), findsOneWidget);
    expect(find.textContaining('With Sara ·'), findsNothing);
    await h.tap('guardian_journey');
    expect(h.latest.guardianJourneyId, 'draft-aisha');
    expect(h.latest.pages.last, 'guardian');
  });

  testWidgets('V6 Main wording uses supplied female gender', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraGuardianSeekerPage(
            name: 'Aisha',
            gender: 'female',
            main: true,
            linkedDate: '20 Sep 2026',
            journeys: 'View and Chat',
            requests: 'You see them',
            currentJourney: null,
            onJourney: null,
            onCircle: () {},
          ),
        ),
      ),
    );
    expect(find.text('YOU ARE HER MAIN GUARDIAN'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final seeker in [0, 1]) {
    testWidgets(
      'V6 Seeker $seeker Larger Text scroll reaches all values and Circle at 430 and 320pt',
      (t) async {
        final h = await mount(t, seeker: seeker, scale: 2);
        expect(t.takeException(), isNull);
        await cap(
          h,
          'g${seeker == 0 ? '11' : '12'}_larger_text_top.png',
          'Actual shell, 200% text, top of same V6 page',
        );
        await t.drag(
          find.byKey(const PageStorageKey('guardian_seeker_scroll')),
          const Offset(0, -900),
        );
        await h.flush();
        await t.ensureVisible(key('guardian_circle'));
        await h.flush();
        expect(key('guardian_circle').hitTestable(), findsOneWidget);
        await cap(
          h,
          'g${seeker == 0 ? '11' : '12'}_larger_text_bottom.png',
          'Actual 200% text, scrolled to reachable Circle action',
        );
        t.view.physicalSize = const Size(960, 2016);
        await h.flush();
        await t.ensureVisible(key('guardian_circle'));
        await h.flush();
        expect(t.takeException(), isNull);
        expect(key('guardian_circle').hitTestable(), findsOneWidget);
        await cap(
          h,
          'g${seeker == 0 ? '11' : '12'}_320pt_larger_text_bottom.png',
          'Actual 320pt shell, 200% text, reachable Circle action',
        );
        await h.tap('guardian_circle');
        expect(h.latest.pages.last, 'guardian_circle');
      },
    );
  }
}
