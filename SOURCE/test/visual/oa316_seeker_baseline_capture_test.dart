// Founder-authorized captures of unchanged public local-preview routes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/dev/zyra_my_zyra_activity_preview.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_browse_next_photo_motion.dart';
import 'package:zyra/widgets/zyra_browse_options_button.dart';
import 'baseline_capture_support.dart';

const _enabled = bool.fromEnvironment('ZYRA_BASELINE_CAPTURE');
const _sara = 'draft-sara';
DateTime _clock() => DateTime.utc(2026, 10, 29, 12);
ViewRequestDraftModel _active([int count = 3]) =>
    ViewRequestDraftModel(capacity: 3, clock: _clock)..seedJourneys(count);
void _next(ViewRequestDraftModel model) {
  final stage = model.stageFor(_sara)!.value;
  if (stage == 'salam_exchange') {
    expect(model.sendSalam(_sara), isTrue);
    expect(model.simulatePeerSalam(_sara), isTrue);
  }
  if (stage == 'compatibility_reveal') {
    expect(model.chooseCompatibilityReveal(_sara), isTrue);
    expect(model.simulatePeerCompatibilityReveal(_sara), isTrue);
    expect(model.chooseStageContinue(_sara), isTrue);
    expect(model.simulatePeerStageContinue(_sara), isTrue);
    expect(model.beginBioStep(_sara), isTrue);
    expect(model.chooseBioReveal(_sara), isTrue);
    expect(model.simulatePeerBioReveal(_sara), isTrue);
    expect(model.chooseBioContinue(_sara), isTrue);
    expect(model.simulatePeerBioContinue(_sara), isTrue);
    expect(model.completeBioStep(_sara), isTrue);
    return;
  }
  expect(model.chooseStageContinue(_sara), isTrue);
  expect(model.simulatePeerStageContinue(_sara), isTrue);
  expect(model.advanceStage(_sara), isTrue);
}

ViewRequestDraftModel _stage(int index) {
  final model = _active();
  for (var n = 0; n < index; n++) {
    _next(model);
  }
  return model;
}

Future<void> _safe(
  BaselineHarness h,
  String area,
  String page,
  String state,
  ViewRequestDraftModel model, {
  int tab = 1,
  int requestsTab = 0,
}) async {
  await h.mount(
    tab: tab,
    pages: page.startsWith('ended_') ? ['ended', page] : [page],
    model: model,
    requestsTab: requestsTab,
  );
  h.assertPage(page);
  await h.capture(
    area,
    page,
    state,
    'Public sample-model checkpoint; role/page eligibility checked by unchanged shell',
  );
  if (page == 'journey') {
    final pages = find.byKey(const ValueKey('concept_current_journey_pages'));
    if (pages.evaluate().isNotEmpty) {
      await h.tester.timedDrag(
        pages,
        Offset(0, -h.tester.getSize(pages).height * .8),
        const Duration(milliseconds: 650),
      );
      await h.flush();
      await h.capture(
        area,
        page,
        '${state}_content',
        'Existing Journey vertical pager to current chapter content',
      );
    }
  }
}

Future<void> _browseOption(BaselineHarness h, ZyraBrowseAction action) async {
  await h.tap('concept_browse_menu');
  final nav = find.byKey(const ValueKey('concept_browse_options_navigation'));
  final target = find.descendant(of: nav, matching: find.byIcon(action.icon));
  expect(target, findsOneWidget);
  await h.tester.tapAt(h.tester.getCenter(target));
  await h.flush();
}

Future<void> _selectPopup(
  BaselineHarness h,
  Finder field,
  String itemKey,
) async {
  await h.tapFinder(field);
  final popup = find.byElementPredicate(
    (e) => e.widget is Scrollable && (ModalRoute.of(e)?.isCurrent ?? false),
  );
  expect(popup, findsOneWidget);
  final item = find.descendant(
    of: popup,
    matching: find.byKey(ValueKey(itemKey)),
  );
  await h.tester.scrollUntilVisible(
    item,
    80,
    scrollable: popup,
    maxScrolls: 40,
  );
  expect(item, findsOneWidget);
  await h.tapFinder(
    find.ancestor(of: item, matching: find.byType(InkWell)).first,
  );
}

void main() {
  setUpAll(baselineSetUp);
  tearDownAll(baselineTearDown);
  testWidgets(
    'baseline seeker roots and safe pages',
    (tester) async {
      final h = BaselineHarness(tester, group: 'seeker');
      final tabs = [
        'profiles_tab',
        'journey_tab',
        'my_zyra_tab',
        'guardian_tab',
        'profile_tab',
      ];
      final areas = [
        'browse_and_requests',
        'journey',
        'profile_membership_settings',
        'guardians',
        'profile_membership_settings',
      ];
      for (var tab = 0; tab < 5; tab++) {
        await h.mount(tab: tab);
        expect(h.latest.pages, isEmpty);
        expect(h.latest.tab, tab);
        await h.capture(
          areas[tab],
          tabs[tab],
          'normal',
          'Fresh local Founder-preview Seeker tab $tab',
        );
      }
      for (final count in [1, 2, 3]) {
        await h.mount(tab: 1, model: _active(count));
        await h.capture(
          'journey',
          'journey_tab',
          'active_$count',
          'Public seedJourneys($count), same local preview preset',
        );
      }
      for (final capacity in [1, 3]) {
        final m = ViewRequestDraftModel(capacity: capacity, clock: _clock);
        await h.mount(
          tab: 1,
          model: m,
          seekerMembership: capacity == 1 ? 'Seeker Basic' : 'Seeker One',
        );
        await h.capture(
          'journey',
          'journey_tab',
          'empty_${capacity}_places',
          'Public empty local model, membership matching capacity',
        );
      }
      final m = ViewRequestDraftModel(capacity: 3, clock: _clock);
      await _safe(h, 'browse_and_requests', 'profile', 'normal', m, tab: 0);
      await _safe(
        h,
        'browse_and_requests',
        'compatibility',
        'locked_zero_unlocks',
        m,
        tab: 0,
      );
      await _safe(h, 'browse_and_requests', 'requests', 'received', m, tab: 2);
      await _safe(
        h,
        'browse_and_requests',
        'requests',
        'sent_empty',
        m,
        tab: 2,
        requestsTab: 1,
      );
      m.request(_sara);
      await _safe(
        h,
        'browse_and_requests',
        'requests',
        'sent',
        m,
        tab: 2,
        requestsTab: 1,
      );
      m.declineReceived(draftProfiles.first.id);
      await _safe(
        h,
        'browse_and_requests',
        'requests',
        'received_empty',
        m,
        tab: 2,
      );
      await _safe(
        h,
        'browse_and_requests',
        'introductions',
        'empty',
        m,
        tab: 2,
      );
      final history = _active();
      history.end(_sara);
      for (final page in ['ended', 'past_journeys']) {
        await _safe(h, 'ended_journeys', page, 'normal', history, tab: 2);
        await _safe(
          h,
          'ended_journeys',
          page,
          'empty',
          ViewRequestDraftModel(capacity: 3, clock: _clock),
          tab: 2,
        );
      }
      for (final page in [
        'ended_bio',
        'ended_guardians',
        'ended_compatibility',
      ]) {
        await _safe(h, 'ended_journeys', page, 'locked', history, tab: 2);
      }
      final shared = _stage(3);
      shared.end(_sara);
      for (final page in [
        'ended_bio',
        'ended_guardians',
        'ended_compatibility',
      ]) {
        await _safe(
          h,
          'ended_journeys',
          page,
          'shared_archive',
          shared,
          tab: 2,
        );
      }
      final legacy = ViewRequestDraftModel(capacity: 3, clock: _clock)
        ..seedHistory();
      await h.mount(tab: 2, pages: ['ended'], model: legacy);
      h.assertPage('ended');
      await h.capture(
        'ended_journeys',
        'ended',
        'undated_archive',
        'Existing Add Ended history sample fixture',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 20)),
  );

  testWidgets(
    'baseline seeker live Journey stages and disclosure',
    (tester) async {
      final h = BaselineHarness(tester, group: 'seeker');
      for (var index = 0; index < 8; index++) {
        final m = _stage(index);
        final stage = m.stageFor(_sara)!.value;
        await _safe(h, 'journey', 'journey', 'stage_$stage', m);
      }
      final p = ViewRequestDraftModel(capacity: 3, clock: _clock);
      p.request(_sara);
      p.simulateRecipientAccept(_sara);
      await _safe(h, 'journey', 'journey', 'preparing', p);
      p.markReady(_sara);
      await _safe(h, 'journey', 'journey', 'self_ready', p);
      p.simulatePeerReady(_sara);
      await _safe(h, 'journey', 'journey', 'both_ready', p);
      for (final own in [true, false]) {
        final held = _active();
        if (own) {
          held.setOwnMainGuardianPresent(false);
        } else {
          held.setPeerMainGuardianPresent(false, id: _sara);
        }
        await _safe(
          h,
          'journey',
          'journey',
          own ? 'own_main_missing' : 'peer_main_missing',
          held,
        );
      }
      for (final choice in ['bio', 'compatibility', 'guardians', 'end']) {
        await h.mount(tab: 1, model: _active());
        await h.tap('draft_journey_options_$_sara');
        await h.capture(
          'journey',
          'journey',
          'options_expanded',
          'Journey card options tapped',
        );
        await h.tap('draft_options_${choice}_$_sara');
        final page = {
          'bio': 'bio_locked',
          'compatibility': 'journey_compatibility_locked',
          'guardians': 'journey_guardians',
          'end': 'journey_action',
        }[choice]!;
        h.assertPage(page);
        await h.capture(
          'journey',
          page,
          choice == 'end' ? 'end_confirmation' : 'locked',
          'Actual current Journey options → $choice',
        );
      }
      final bio = _stage(1);
      bio.chooseCompatibilityReveal(_sara);
      bio.simulatePeerCompatibilityReveal(_sara);
      bio.chooseStageContinue(_sara);
      bio.simulatePeerStageContinue(_sara);
      bio.beginBioStep(_sara);
      await _safe(h, 'journey', 'journey', 'bio_unshared', bio);
      bio.chooseBioReveal(_sara);
      await _safe(h, 'journey', 'journey', 'bio_self_shared', bio);
      bio.simulatePeerBioReveal(_sara);
      await _safe(h, 'journey', 'journey', 'bio_both_shared', bio);
      bio.chooseBioContinue(_sara);
      await _safe(h, 'journey', 'journey', 'bio_self_ready', bio);
      bio.simulatePeerBioContinue(_sara);
      await _safe(h, 'journey', 'journey', 'bio_both_ready', bio);
      bio.completeBioStep(_sara);
      await _safe(h, 'journey', 'bio', 'shared', bio);
      await _safe(
        h,
        'journey',
        'journey_compatibility',
        'revealed_result_pending',
        bio,
      );
      await _safe(h, 'journey', 'journey_guardians', 'active', bio);
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 20)),
  );

  testWidgets(
    'baseline seeker browse and real transient routes',
    (tester) async {
      final h = BaselineHarness(tester, group: 'seeker');
      await h.mount();
      await _browseOption(h, ZyraBrowseAction.filters);
      h.assertPage('filters');
      await h.capture(
        'browse_and_requests',
        'filters',
        'normal',
        'Profiles → actual options → Filters',
      );
      await h.tap('concept_age_1');
      await h.capture(
        'browse_and_requests',
        'filters',
        'age_range',
        'Actual Age filter expansion',
      );
      await h.mount();
      await _browseOption(h, ZyraBrowseAction.scan);
      h.assertPage('scan');
      await h.capture(
        'browse_and_requests',
        'scan',
        'manual_empty',
        'Profiles → actual options → Scan; default manual entry',
      );
      await h.mount(tab: 2, pages: ['requests'], model: _active());
      await h.tap('concept_request_${draftProfiles.first.id}_header');
      await h.tap('draft_accept_${draftProfiles.first.id}');
      h.assertPage('request_capacity');
      await h.capture(
        'browse_and_requests',
        'request_capacity',
        'full',
        'Real received request → Accept while three sample places occupied',
      );
      await h.mount(tab: 2, pages: ['ended'], model: (_active()..end(_sara)));
      await h.tap('draft_restart_$_sara');
      h.assertPage('ended_restart');
      await h.capture(
        'ended_journeys',
        'ended_restart',
        'not_available',
        'Ended card → actual Request restart',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 20)),
  );
  testWidgets(
    'baseline seeker local controls and Guardian Circle',
    (tester) async {
      final h = BaselineHarness(tester, group: 'seeker');
      for (final role in [false, true]) {
        await h.mount(
          guardian: role,
          tab: role ? 0 : 3,
          pages: ['guardian_circle'],
          model: _active(),
        );
        h.assertPage('guardian_circle');
        await h.capture(
          'guardians',
          'guardian_circle',
          'normal',
          'Actual allowed Guardian Circle checkpoint with local sample transcript',
        );
        for (final design in ZyraCircleBubbleDesign.values) {
          await h.mount(
            guardian: role,
            tab: role ? 0 : 3,
            pages: ['guardian_circle'],
            model: _active(),
          );
          await h.controls();
          final picker = find.byWidgetPredicate(
            (w) => w is DropdownButtonFormField<ZyraCircleBubbleDesign>,
          );
          await _selectPopup(
            h,
            picker,
            'concept_circle_bubble_design_${design.name}',
          );
          await h.capture(
            'guardians',
            'controls',
            'circle_${design.name}',
            'Actual hold-to-open controls, selected existing Circle interior',
          );
          await h.closeControls();
          await h.tap('circle_discuss_floatingButton');
          await h.capture(
            'guardians',
            'guardian_circle',
            'bubble_${design.name}',
            'Actual controls choice ${design.label}, then X',
          );
        }
      }
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 30)),
  );
  testWidgets(
    'baseline seeker Guardian invite and paid agreement',
    (tester) async {
      final h = BaselineHarness(tester, group: 'seeker');
      await h.mount(tab: 3, model: _active());
      await h.tap('guardian-add-top');
      h.assertPage('guardian_invite');
      await h.capture(
        'guardians',
        'guardian_invite',
        'normal',
        'Guardian tab → actual Add Guardian',
      );
      final preparing = ViewRequestDraftModel(capacity: 3, clock: _clock)
        ..request(_sara)
        ..simulateRecipientAccept(_sara)
        ..markReady(_sara)
        ..simulatePeerReady(_sara);
      await h.mount(tab: 1, pages: ['journey'], model: preparing);
      await h.tap('draft_begin_$_sara');
      h.assertPage('guardian_access_agreement');
      await h.capture(
        'journey',
        'guardian_access_agreement',
        'paid_additional_consent',
        'Both sample people ready → actual Begin Journey',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 30)),
  );
  testWidgets(
    'baseline seeker actual activity checklist states',
    (tester) async {
      final h = BaselineHarness(tester, group: 'seeker');
      for (final example in ZyraMyZyraActivityExample.values) {
        await h.mount(tab: 2);
        await h.controls();
        await h.tap('concept_activity_checklist');
        await h.tap('activity-checklist-${example.name}');
        await h.capture(
          'profile_membership_settings',
          'my_zyra_tab',
          'activity_${example.name}',
          'Actual My ZYRA controls → Activity checklist → ${example.name}',
        );
        if (example.items.isNotEmpty) {
          final item = example.items.first;
          final door = find.byKey(ValueKey('my-zyra-route-${item.id}'));
          if (door.evaluate().isNotEmpty) {
            await h.tapFinder(door);
            if (h.latest.pages.lastOrNull == 'activity_preview_detail') {
              await h.capture(
                'profile_membership_settings',
                'activity_preview_detail',
                example.name,
                'Actual activity item from selected checklist example',
              );
            }
          }
        }
      }
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 30)),
  );
  testWidgets(
    'baseline seeker actual Browse control variants',
    (tester) async {
      final h = BaselineHarness(tester, group: 'seeker');
      for (final mode in ZyraBrowseGalleryMode.values) {
        await h.mount();
        await h.controls();
        final picker = find.byWidgetPredicate(
          (w) => w is DropdownButtonFormField<ZyraBrowseGalleryMode>,
        );
        await _selectPopup(
          h,
          picker,
          'concept_browse_gallery_mode_${mode.name}',
        );
        await h.capture(
          'browse_and_requests',
          'controls',
          'browse_${mode.name}',
          'Actual controls Profile cards choice',
        );
        await h.closeControls();
        await h.capture(
          'browse_and_requests',
          'profiles_tab',
          'gallery_${mode.name}',
          'Actual controls Profile cards choice then X',
        );
      }
      for (final motion in ZyraBrowseNextMotion.values) {
        await h.mount();
        await h.controls();
        final picker = find.byWidgetPredicate(
          (w) => w is DropdownButtonFormField<ZyraBrowseNextMotion>,
        );
        await _selectPopup(
          h,
          picker,
          'concept_browse_next_motion_${motion.name}',
        );
        await h.capture(
          'browse_and_requests',
          'controls',
          'next_${motion.name}',
          'Actual existing Next animation choice',
        );
        await h.closeControls();
        await h.capture(
          'browse_and_requests',
          'profiles_tab',
          'next_${motion.name}',
          'Actual Next animation selection; resting page unchanged',
        );
      }
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
