// LOCK13 actual admitted sample shell: local portraits, state, routes and gates.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/dev/zyra_one_journey_options_page.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_profiles_components.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK13_V3_JOURNEY_OPTIONS_2026-10-31';
const capture = bool.fromEnvironment('ZYRA_LOCK13_CAPTURE');
Finder k(String id) => find.byKey(ValueKey(id));
const sara = 'draft-sara';
const aisha = 'draft-aisha';
const maryam = 'draft-maryam';

ViewRequestDraftModel fixture(int count, {bool basic = false}) {
  final m = ViewRequestDraftModel(
    capacity: basic ? 1 : 3,
    clock: () => DateTime.utc(2026, 10, 30, 14),
  );
  if (count > 0) expect(m.seedJourneys(count), isTrue);
  return m;
}

void compatibility(ViewRequestDraftModel m, String id) {
  expect(m.sendSalam(id), isTrue);
  expect(m.simulatePeerSalam(id), isTrue);
  advance(m, id);
}

void advance(ViewRequestDraftModel m, String id) {
  expect(m.chooseStageContinue(id), isTrue);
  expect(m.simulatePeerStageContinue(id), isTrue);
  expect(m.advanceStage(id), isTrue);
}

void faith(ViewRequestDraftModel m, String id) {
  compatibility(m, id);
  expect(m.chooseCompatibilityReveal(id), isTrue);
  expect(m.simulatePeerCompatibilityReveal(id), isTrue);
  advance(m, id);
  advance(m, id);
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  setUp(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
  });
  Future<BaselineHarness> mount(
    WidgetTester t,
    int count, {
    bool basic = false,
    ViewRequestDraftModel? model,
  }) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final h = BaselineHarness(
      t,
      group: 'lock13_journey_tab',
      outputRoot: '$root/PRODUCT/APPROVED/JOURNEY_TAB/BUILT/V3',
      evidenceRoot: evidence,
      flatOutput: true,
    );
    await h.mount(
      tab: 1,
      model: model ?? fixture(count, basic: basic),
      initialSeekerBasic: basic,
      seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
    );
    return h;
  }

  Future<void> cap(BaselineHarness h, String name) async {
    final bar = h.tester.getRect(k('compact-nav-surface'));
    final bottom = k('journey_options_card_$sara').evaluate().isNotEmpty
        ? h.tester.getRect(k('journey_options_card_$sara')).bottom
        : k('journey_tab_upsell').evaluate().isNotEmpty
        ? h.tester.getRect(k('journey_tab_upsell')).bottom
        : k('journey_tab_continue').evaluate().isNotEmpty
        ? h.tester.getRect(k('journey_tab_continue')).bottom
        : null;
    if (bottom != null) {
      expect(bar.top - bottom, greaterThanOrEqualTo(12));
      debugPrint(
        'LOCK13_CLEARANCE $name bodyBottom=$bottom navTop=${bar.top} gap=${bar.top - bottom}',
      );
    }
    if (capture) {
      await h.capture(
        'journey',
        name,
        name,
        'Actual admitted local sample shell. Stage and next step from actual model; no fabricated Family Review timer.',
        fileName: '$name.png',
      );
    }
  }

  ZyraOneJourneyTab tab(WidgetTester t) =>
      t.widget(find.byType(ZyraOneJourneyTab));

  testWidgets(
    'LOCK13 eight master states, actual stages and full height geometry',
    (t) async {
      var h = await mount(t, 0);
      expect(find.text('No Journey yet'), findsOneWidget);
      expect(find.byType(ZyraProfilesDots), findsNothing);
      expect(find.byType(ZyraProfilesRequestRow), findsNothing);
      expect(k('draft_journey_options_$sara'), findsNothing);
      await cap(h, 'j01_one__no_journey');
      final two = fixture(2);
      faith(two, sara);
      h = await mount(t, 2, model: two);
      expect(tab(t).journeys.first.stageNumber, 4);
      expect(find.text('Stage 4 of 8 · Faith & Values'), findsOneWidget);
      expect(find.text('Your turn: answer Faith & Values'), findsOneWidget);
      expect(find.textContaining('41 hours'), findsNothing);
      expect(t.getRect(k('journey_tab_card')).height, greaterThan(600));
      expect(
        t.getRect(k('journey_tab_card')).bottom + 12,
        t.getRect(k('journey_tab_continue')).top,
      );
      expect(
        t.widget<ZyraProfilesDots>(find.byType(ZyraProfilesDots)).count,
        3,
      );
      await cap(h, 'j02_one__journey_sara');
      await h.tap('journey_tab_next');
      expect(find.text('Aisha'), findsOneWidget);
      await cap(h, 'j03_one__journey_aisha');
      await h.tap('journey_tab_next');
      expect(find.text('Free place'), findsOneWidget);
      expect(t.getSize(k('journey_tab_browse')).height, lessThan(50));
      expect(k('draft_journey_options_$aisha'), findsNothing);
      await cap(h, 'j04_one__free_place');
      final three = fixture(3);
      faith(three, sara);
      compatibility(three, maryam);
      expect(three.chooseCompatibilityReveal(maryam), isTrue);
      h = await mount(t, 3, model: three);
      await h.tap('journey_tab_next');
      await h.tap('journey_tab_next');
      expect(find.text('Waiting for Maryam'), findsOneWidget);
      expect(tab(t).journeys[2].stageNumber, 2);
      await cap(h, 'j05_one__three_journeys_maryam');
      h = await mount(t, 0, basic: true);
      expect(find.textContaining('You have 1 place.'), findsOneWidget);
      expect(find.byType(ZyraProfilesDots), findsNothing);
      expect(k('journey_tab_plans'), findsOneWidget);
      await cap(h, 'j06_basic__no_journey');
      final one = fixture(1, basic: true);
      faith(one, sara);
      h = await mount(t, 1, basic: true, model: one);
      expect(
        t.widget<ZyraProfilesDots>(find.byType(ZyraProfilesDots)).count,
        1,
      );
      expect(t.getRect(k('journey_tab_card')).height, greaterThan(400));
      await cap(h, 'j07_basic__journey_sara');
      h = await mount(t, 1);
      await h.tap('draft_journey_options_$sara');
      h.assertPage('journey_options');
      expect(find.byType(ZyraShellNavigation), findsOneWidget);
      expect(find.byType(ZyraConceptJourneyOptionsButton), findsNothing);
      expect(t.getSize(k('journey_options_photo_$sara')), const Size(88, 88));
      expect(
        t.getSize(k('draft_journey_$sara')).height,
        greaterThanOrEqualTo(44),
      );
      for (final choice in ZyraConceptJourneyOption.values) {
        expect(
          t.getSize(k('draft_options_${choice.name}_$sara')).height,
          greaterThanOrEqualTo(46),
        );
      }
      final card = t.getRect(k('journey_options_card_$sara'));
      expect(
        card.bottom,
        closeTo(t.getRect(k('draft_options_end_$sara')).bottom + .6, .01),
      );
      await cap(h, 'j08_one__journey_options');
      expect(find.byIcon(Icons.favorite), findsNothing);
    },
  );

  testWidgets('LOCK13 V3 actual Sara Aisha and Basic options captures', (
    t,
  ) async {
    for (final basic in [false, true]) {
      final m = fixture(basic ? 1 : 2, basic: basic);
      faith(m, sara);
      final h = await mount(t, basic ? 1 : 2, basic: basic, model: m);
      for (final id in basic ? [sara] : [sara, aisha]) {
        if (id == aisha) await h.tap('journey_tab_next');
        await h.tap('draft_journey_options_$id');
        final page = t.widget<ZyraOneJourneyOptionsPage>(
          find.byType(ZyraOneJourneyOptionsPage),
        );
        expect(page.id, id);
        expect(page.stageNumber, id == sara ? 4 : 1);
        expect(
          find.text(id == sara ? 'Sara Ahmed' : 'Aisha Khan'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
        if (const bool.fromEnvironment('ZYRA_LOCK13_V3_CAPTURE')) {
          final name = basic
              ? 'j12_journey_options__basic'
              : id == sara
              ? 'j10_journey_options__sara'
              : 'j11_journey_options__aisha';
          await h.capture(
            'journey',
            name,
            name,
            'Actual V3 options; existing model disclosure gates and owned sample profile fields.',
            fileName: '$name.png',
          );
        }
        await h.tap('draft_journey_$id');
        h.assertPage('journey');
        expect(h.latest.personId, id);
        await t.binding.handlePopRoute();
        await h.flush();
        await t.binding.handlePopRoute();
        await h.flush();
      }
    }
  });

  testWidgets('LOCK13 V3 actual 200 percent One and Basic scroll head to End', (
    t,
  ) async {
    for (final basic in [false, true]) {
      final m = fixture(1, basic: basic);
      faith(m, sara);
      final h = BaselineHarness(
        t,
        group: 'lock13_journey_options_v3_large',
        outputRoot: '$root/PRODUCT/APPROVED/JOURNEY_TAB/BUILT/V3',
        evidenceRoot: evidence,
        flatOutput: true,
        textScale: 2,
      );
      await h.mount(
        tab: 1,
        model: m,
        initialSeekerBasic: basic,
        seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
      );
      await h.tap('draft_journey_options_$sara');
      final name = basic ? 'j12_basic' : 'j10_one';
      if (const bool.fromEnvironment('ZYRA_LOCK13_V3_CAPTURE')) {
        await h.capture(
          'journey',
          name,
          '200pct_head',
          'Actual V3 200 percent head and whole-page reading fallback.',
          fileName: '${name}_200pct_head.png',
        );
      }
      await Scrollable.ensureVisible(t.element(k('draft_options_end_$sara')));
      await h.flush();
      expect(k('draft_options_end_$sara').hitTestable(), findsOneWidget);
      expect(t.takeException(), isNull);
      if (const bool.fromEnvironment('ZYRA_LOCK13_V3_CAPTURE')) {
        await h.capture(
          'journey',
          name,
          '200pct_end',
          'Actual V3 200 percent rows scrolled to End above retained tabs.',
          fileName: '${name}_200pct_end.png',
        );
      }
    }
  });

  testWidgets(
    'LOCK13 One 0 1 2 3 and Basic 0 1 have exact capacity and end arrows',
    (t) async {
      for (final basic in [false, true]) {
        for (var count = 0; count <= (basic ? 1 : 3); count++) {
          final h = await mount(t, count, basic: basic);
          expect(tab(t).journeys.length, count);
          expect(tab(t).capacity, basic ? 1 : 3);
          if (count == 0) continue;
          expect(t.widget<InkWell>(k('journey_tab_previous')).onTap, isNull);
          await t.fling(k('journey_tab_card'), const Offset(240, 0), 800);
          await h.flush();
          expect(tab(t).index, 0);
          for (var i = 1; i < (basic ? 1 : 3); i++) {
            await t.fling(k('journey_tab_card'), const Offset(-240, 0), 800);
            await h.flush();
            expect(tab(t).index, i);
          }
          expect(t.widget<InkWell>(k('journey_tab_next')).onTap, isNull);
          await t.fling(k('journey_tab_card'), const Offset(-240, 0), 800);
          await h.flush();
          expect(tab(t).index, basic ? 0 : 2);
        }
      }
    },
  );

  testWidgets(
    'LOCK13 empty and free Browse go to Profiles and Basic upsell goes to Plans',
    (t) async {
      var h = await mount(t, 0);
      await h.tap('journey_tab_browse');
      expect(h.latest.tab, 0);
      h = await mount(t, 1);
      await h.tap('journey_tab_next');
      await h.tap('journey_tab_browse');
      expect(h.latest.tab, 0);
      h = await mount(t, 1);
      await h.tap('journey_tab_next');
      await h.tap('journey_tab_continue');
      expect(h.latest.tab, 0);
      for (final count in [0, 1]) {
        h = await mount(t, count, basic: true);
        await h.tap('journey_tab_plans');
        h.assertPage('membership');
      }
    },
  );

  testWidgets(
    'LOCK13 all seven options open existing destinations and preserve disclosure locks',
    (t) async {
      const destinations = [
        'profile',
        'timeline',
        'bio_locked',
        'journey_compatibility_locked',
        'journey_guardians',
        'safety',
        'journey_action',
      ];
      for (var i = 0; i < ZyraConceptJourneyOption.values.length; i++) {
        final h = await mount(t, 1);
        await h.tap('draft_journey_options_$sara');
        final options = t.widget<ZyraConceptJourneyOptions>(
          find.byType(ZyraConceptJourneyOptions),
        );
        expect(options.canViewBio, isFalse);
        expect(options.canViewCompatibility, isFalse);
        final choice = ZyraConceptJourneyOption.values[i];
        await h.tap('draft_options_${choice.name}_$sara');
        h.assertPage(destinations[i]);
        expect(h.latest.personId, sara);
        if (i == 2 || i == 3) {
          expect(find.byIcon(Icons.lock_outline), findsWidgets);
        }
      }
      final h = await mount(t, 1);
      await h.tap('journey_tab_continue');
      h.assertPage('journey');
      expect(h.latest.personId, sara);
      expect(find.textContaining('Salam'), findsWidgets);
    },
  );

  testWidgets(
    'LOCK13 actual actions order Journeys and never invent a review timer',
    (t) async {
      var now = DateTime.utc(2026, 10, 30, 10);
      final m = ViewRequestDraftModel(capacity: 3, clock: () => now)
        ..seedJourneys(3);
      now = now.add(const Duration(minutes: 1));
      expect(m.sendSalam(aisha), isTrue);
      final h = await mount(t, 3, model: m);
      expect(tab(t).journeys.map((p) => p.id), [aisha, sara, maryam]);
      expect(find.text('Waiting for Aisha'), findsOneWidget);
      expect(find.textContaining('hours left'), findsNothing);
      await h.tap('journey_tab_next');
      expect(find.text('Your turn: send Salam'), findsOneWidget);
    },
  );

  testWidgets('LOCK13 available Continue beats waiting after mutual choices', (
    t,
  ) async {
    final m = fixture(1);
    m.sendSalam(sara);
    m.simulatePeerSalam(sara);
    await mount(t, 1, model: m);
    expect(find.text('Your turn: continue'), findsOneWidget);
  });

  testWidgets(
    'LOCK13 preparing has no begun stage and retains readiness gates',
    (t) async {
      final m = fixture(0);
      final id = draftProfiles.first.id;
      m.acceptReceived(id);
      final h = await mount(t, 1, model: m);
      expect(tab(t).journeys.single.stageNumber, 0);
      expect(find.text('Preparing together · place reserved'), findsOneWidget);
      expect(find.textContaining('Stage 1 of 8'), findsNothing);
      await h.tap('journey_tab_continue');
      h.assertPage('journey');
      expect(find.text('Choose to begin, together.'), findsOneWidget);
      expect(t.widget<OutlinedButton>(k('draft_begin_$id')).onPressed, isNull);
      expect(
        ViewRequestDraftModel.fromSnapshot(h.latest.model).conversationOpen(id),
        isFalse,
      );
    },
  );

  testWidgets('LOCK13 question and Family next-step use actual stage wording', (
    t,
  ) async {
    final m = fixture(1);
    faith(m, sara);
    for (final expected in [
      'Faith & Values',
      'Building a Life',
      'Navigating Life',
      'Family Compatibility',
    ]) {
      await mount(t, 1, model: m);
      expect(find.text('Your turn: answer $expected'), findsOneWidget);
      advance(m, sara);
    }
  });

  testWidgets(
    'LOCK13 short return restores chosen place and options Back; bounded Basic clamp',
    (t) async {
      for (final count in [2, 3]) {
        final h = await mount(t, count);
        await h.tap('journey_tab_next');
        await h.tap('journey_tab_next');
        final saved = h.latest;
        expect(saved.journeyPlaceIndex, 2);
        await h.mount(checkpoint: saved);
        expect(tab(t).index, 2);
        await h.tap('journey_tab_previous');
        await h.tap('draft_journey_options_$aisha');
        final options = h.latest;
        await h.mount(checkpoint: options);
        h.assertPage('journey_options');
        await t.binding.handlePopRoute();
        await h.flush();
        expect(tab(t).index, 1);
        expect(find.text('Aisha'), findsOneWidget);
      }
      final h = await mount(t, 1, basic: true);
      for (final invalid in [-50, 999]) {
        final saved = ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: fixture(1, basic: true).snapshot(),
          tab: 1,
          pages: [],
          journeyPlaceIndex: invalid,
          seekerMembership: 'Seeker Basic',
        );
        await h.mount(checkpoint: saved, initialSeekerBasic: true);
        expect(tab(t).index, 0);
      }
    },
  );

  testWidgets(
    'LOCK13 unlocked Bio and Compatibility remain actual guarded destinations',
    (t) async {
      final m = fixture(1);
      compatibility(m, sara);
      m.chooseCompatibilityReveal(sara);
      m.simulatePeerCompatibilityReveal(sara);
      m.chooseStageContinue(sara);
      m.simulatePeerStageContinue(sara);
      m.beginBioStep(sara);
      m.chooseBioReveal(sara);
      m.simulatePeerBioReveal(sara);
      m.chooseBioContinue(sara);
      m.simulatePeerBioContinue(sara);
      m.completeBioStep(sara);
      for (final choice in [
        ZyraConceptJourneyOption.bio,
        ZyraConceptJourneyOption.compatibility,
      ]) {
        final h = await mount(t, 1, model: m);
        await h.tap('draft_journey_options_$sara');
        final options = t.widget<ZyraConceptJourneyOptions>(
          find.byType(ZyraConceptJourneyOptions),
        );
        expect(options.canViewBio, isTrue);
        expect(options.canViewCompatibility, isTrue);
        await h.tap('draft_options_${choice.name}_$sara');
        h.assertPage(
          choice == ZyraConceptJourneyOption.bio
              ? 'bio'
              : 'journey_compatibility',
        );
      }
    },
  );

  testWidgets(
    'LOCK13 blocked occupied place redacts identity and preserves End',
    (t) async {
      final m = fixture(1);
      m.block(sara);
      final h = await mount(t, 1, model: m);
      expect(find.text('User not found'), findsOneWidget);
      expect(find.text('Sara'), findsNothing);
      expect(k('draft_journey_options_$sara'), findsNothing);
      await h.tap('journey_tab_end_unavailable');
      h.assertPage('journey_action');
    },
  );

  testWidgets(
    'LOCK13 retained callbacks refuse swipe, pushed-page and controls ABA',
    (t) async {
      final h = await mount(t, 2);
      final old = tab(t);
      await h.tap('journey_tab_next');
      old.onOptions();
      old.onContinue();
      await h.flush();
      expect(h.latest.pages, isEmpty);
      await h.tap('journey_tab_previous');
      old.onOptions();
      await h.flush();
      expect(h.latest.pages, isEmpty);
      final rootBeforeOptions = tab(t);
      await h.tap('draft_journey_options_$sara');
      final row = t.widget<ZyraConceptJourneyOptions>(
        find.byType(ZyraConceptJourneyOptions),
      );
      await t.binding.handlePopRoute();
      await h.flush();
      rootBeforeOptions.onOptions();
      row.onSelected(ZyraConceptJourneyOption.end);
      await h.flush();
      expect(h.latest.pages, isEmpty);
      final beforeControls = tab(t);
      await h.controls();
      await h.closeControls();
      beforeControls.onContinue();
      beforeControls.onOptions();
      await h.flush();
      expect(h.latest.pages, isEmpty);
    },
  );

  testWidgets(
    'LOCK13 shared haptics one per enabled tap, no swipe or disabled pulse, Off respected',
    (t) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (c) async {
            if (c.method == 'HapticFeedback.vibrate') {
              calls.add(c.arguments as String);
            }
            return null;
          });
      final h = await mount(t, 1);
      calls.clear();
      await h.tap('journey_tab_next');
      expect(calls.length, 1);
      await t.fling(k('journey_tab_card'), const Offset(-240, 0), 800);
      await h.flush();
      expect(calls.length, 1);
      await h.tap('journey_tab_next');
      expect(calls.length, 1);
      t.widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation)).onTap(4);
      await h.flush();
      expect(h.latest.tab, 4);
      t
          .widget<ZyraConceptProfilePresentation>(
            find.byType(ZyraConceptProfilePresentation),
          )
          .onAction(ZyraConceptAccountAction.personalisation);
      await h.flush();
      t
          .widget<PersonalisationScreen>(find.byType(PersonalisationScreen))
          .onHapticChanged!(ZyraHapticLevel.off);
      await h.flush();
      await t.binding.handlePopRoute();
      await h.flush();
      t.widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation)).onTap(1);
      await h.flush();
      calls.clear();
      await h.tap('journey_tab_previous');
      expect(calls, isEmpty);
      ZyraInteractionStyle.restoreDefaults();
    },
  );

  testWidgets(
    'LOCK13 small phone and Larger Text keep bounded cards with reachable wrapped content',
    (t) async {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final scale in [1.0, 2.0]) {
        for (final basic in [false, true]) {
          final m = fixture(1, basic: basic);
          final ready = Completer<void>();
          final generation = ZyraAccountState.generation;
          final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
          t.view.physicalSize = const Size(320, 568);
          t.view.devicePixelRatio = 1;
          await t.pumpWidget(
            MaterialApp(
              theme: ThemeData.dark(),
              navigatorObservers: [ZyraDevControlsRouteObserver()],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  viewPadding: const EdgeInsets.only(top: 20, bottom: 20),
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: ZyraOneJourneyConceptShell(
                key: UniqueKey(),
                canAct: () => generation == ZyraAccountState.generation,
                onCheckpoint: checkpoints.add,
                onExit: () {},
                initialSeekerBasic: basic,
                initialCheckpoint: ZyraPreviewNavigationCheckpoint(
                  guardian: false,
                  model: m.snapshot(),
                  tab: 1,
                  pages: [],
                  seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
                ),
                onPresentationReady: () {
                  if (!ready.isCompleted) ready.complete();
                },
              ),
            ),
          );
          for (var i = 0; i < 100 && !ready.isCompleted; i++) {
            await t.pump(const Duration(milliseconds: 20));
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 3)),
            );
          }
          expect(ready.isCompleted, isTrue);
          await t.pump(const Duration(milliseconds: 400));
          expect(t.takeException(), isNull);
          if (scale == 1 && !basic) {
            final semantics = t.ensureSemantics();
            expect(
              find.bySemanticsLabel(
                'Journey with Sara, stage 1 of 8, Salam Exchange, Your turn: send Salam, 1 of 3',
              ),
              findsOneWidget,
            );
            semantics.dispose();
            final stale = tab(t);
            final nav = Navigator.of(
              t.element(find.byType(ZyraOneJourneyConceptShell)),
            );
            unawaited(
              nav.push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Cover')),
                ),
              ),
            );
            await t.pumpAndSettle();
            stale.onContinue();
            stale.onOptions();
            expect(checkpoints.last.pages, isEmpty);
            nav.pop();
            await t.pumpAndSettle();
            stale.onContinue();
            stale.onOptions();
            await t.pump();
            expect(checkpoints.last.pages, isEmpty);
          }
          final bar = t.getRect(k('compact-nav-surface'));
          final bodyBottom = basic
              ? t.getRect(k('journey_tab_upsell')).bottom
              : t.getRect(k('journey_tab_continue')).bottom;
          expect(bar.top - bodyBottom, greaterThanOrEqualTo(12));
          debugPrint(
            'LOCK13_SMALL_CLEARANCE scale=$scale basic=$basic gap=${bar.top - bodyBottom}',
          );
          final bounds = t.getRect(k('journey_tab_card'));
          expect(bounds.height, greaterThan(0));
          expect(bounds.bottom, lessThan(500));
          await Scrollable.ensureVisible(
            t.element(k('draft_journey_options_$sara')),
          );
          await t.tap(k('draft_journey_options_$sara'));
          await t.pump(const Duration(milliseconds: 400));
          expect(t.takeException(), isNull);
          expect(
            t.getRect(k('journey_options_card_$sara')).height,
            greaterThan(0),
          );
          expect(
            t.getRect(k('compact-nav-surface')).top -
                t.getRect(k('journey_options_card_$sara')).bottom,
            greaterThanOrEqualTo(12),
          );
          await Scrollable.ensureVisible(
            t.element(k('draft_options_end_$sara')),
          );
          await t.pump(const Duration(milliseconds: 400));
          expect(k('draft_options_end_$sara').hitTestable(), findsOneWidget);
          if (scale == 2 && basic) {
            final oldOptions = t.widget<ZyraConceptJourneyOptions>(
              find.byType(ZyraConceptJourneyOptions),
            );
            final oldContinue = t
                .widget<ZyraOneJourneyOptionsPage>(
                  find.byType(ZyraOneJourneyOptionsPage),
                )
                .onContinue;
            final before = checkpoints.last;
            ZyraAccountState.resetForTesting();
            oldOptions.onSelected(ZyraConceptJourneyOption.end);
            oldContinue();
            await t.pump();
            expect(checkpoints.last, same(before));
          }

          expect(t.takeException(), isNull);
        }
      }
    },
  );
}
