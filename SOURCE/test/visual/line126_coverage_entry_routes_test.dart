// OA-ZYRA-371: current public entries omitted by the first route matrix.
// Fixture geometry stays ordinary; the shared audit callback owns its matrix.
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_circle_topics_presentation.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_full_profile_preview.dart';
import 'package:zyra/dev/zyra_draft_code_entry.dart';
import 'package:zyra/dev/zyra_draft_journey_bio_presentation.dart';
import 'package:zyra/dev/zyra_draft_safety_advice_presentation.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_journey_peer_guardians_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_action.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/widgets/zyra_browse_options_button.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

import '../support/guardian_card_driver.dart';
import '../support/received_request_fixture.dart';
import 'baseline_capture_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));
late ZyraOneJourneySamplePhotos _bundledPhotos;
final _photoNames = <String, String>{};
final _photoCoverage = <Map<String, Object?>>[];

void _recordPhotos(BaselineHarness h) {
  final preparedAssets = <String>{};
  for (final image in h.tester.widgetList<Image>(find.byType(Image))) {
    ImageProvider provider = image.image;
    if (provider is ResizeImage) provider = provider.imageProvider;
    if (provider is MemoryImage) {
      final source = 'data:image/jpeg;base64,${base64Encode(provider.bytes)}';
      final name = _photoNames[source];
      if (name != null) preparedAssets.add(name);
    } else if (provider is AssetImage &&
        provider.assetName.startsWith('assets/dev/one_journey_photos/')) {
      preparedAssets.add(provider.assetName.split('/').last);
    }
  }
  final photos = h.tester
      .widgetList<ZyraProfileImage>(find.byType(ZyraProfileImage))
      .map((widget) => widget.photo)
      .where((photo) => photo.isNotEmpty)
      .toSet();
  for (final photo in photos) {
    expect(
      _photoNames.containsKey(photo),
      isTrue,
      reason: 'Populated entry photos must resolve actual bundled samples',
    );
  }
  for (final profile in h.tester.widgetList<ZyraConceptProfilePresentation>(
    find.byType(ZyraConceptProfilePresentation),
  )) {
    if (!profile.data.guardian) {
      expect(
        profile.data.photoAsset,
        _bundledPhotos.seekerPhoto,
        reason: 'Populated Seeker Profile must retain its own bundled photo',
      );
    }
  }
  _photoCoverage.add({
    'group': h.group,
    'plan': h.latest.guardian
        ? h.latest.guardianMembership
        : h.latest.seekerMembership,
    'tab': h.latest.tab,
    'route': h.latest.pages.lastOrNull,
    'displayed_profile_photo_assets': [
      for (final photo in photos) _photoNames[photo]!,
    ]..sort(),
    'mounted_prepared_image_assets': preparedAssets.toList()..sort(),
  });
}

List<ScrollableState> _scrolls(WidgetTester tester) => tester
    .stateList<ScrollableState>(find.byType(Scrollable))
    .where(
      (state) =>
          (ModalRoute.of(state.context)?.isCurrent ?? true) &&
          state.position.axis == Axis.vertical &&
          state.position.hasContentDimensions &&
          state.position.viewportDimension > 0,
    )
    .toList();

Future<void> _readAll(BaselineHarness h) async {
  await h.flush();
  _recordPhotos(h);
  // Requery after every callback: responsive reflow may replace a position.
  for (var index = 0; index < _scrolls(h.tester).length; index++) {
    var position = _scrolls(h.tester)[index].position;
    position.jumpTo(position.minScrollExtent);
    await h.flush();
    var steps = 0;
    while (true) {
      final current = _scrolls(h.tester);
      expect(index, lessThan(current.length));
      position = current[index].position;
      if (position.pixels >= position.maxScrollExtent - .5) break;
      position.jumpTo(
        math.min(
          position.maxScrollExtent,
          position.pixels + math.max(1, position.viewportDimension * .7),
        ),
      );
      await h.flush();
      expect(++steps, lessThan(80), reason: 'Bounded entry-route reading');
    }
    position = _scrolls(h.tester)[index].position;
    position.jumpTo(position.minScrollExtent);
    await h.flush();
  }
}

Future<void> _tap(BaselineHarness h, String id) async {
  final target = _key(id);
  if (target.evaluate().isEmpty) {
    final scroll = find.byType(Scrollable).hitTestable().first;
    expect(scroll, findsOneWidget, reason: 'Public entry must be reachable');
    await h.tester.scrollUntilVisible(
      target,
      180,
      scrollable: scroll,
      maxScrolls: 60,
    );
  }
  await h.tap(id);
}

Future<BaselineHarness> _mount(
  WidgetTester tester, {
  required bool guardian,
  required bool basic,
  required String state,
  int tab = 4,
  bool bothBasic = false,
  ViewRequestDraftModel? model,
  List<String> pages = const [],
  String personId = 'draft-sara',
  ZyraGuardianTabsSnapshot guardianTabs =
      const ZyraGuardianTabsSnapshot.quiet(),
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final role = guardian ? 'Guardian' : 'Seeker';
  final plan = basic ? 'Basic' : 'One';
  final seekerBasic = bothBasic || (!guardian && basic);
  final h = BaselineHarness(
    tester,
    group: 'line126_entry_${role}_${plan}_$state',
    reduceMotion: true,
  );
  await h.mount(
    guardian: guardian,
    initialSeekerBasic: seekerBasic,
    initialGuardianBasic: guardian && basic,
    receivedRequest: false,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: guardian,
      model: (model ?? ViewRequestDraftModel(capacity: seekerBasic ? 1 : 3))
          .snapshot(),
      tab: tab,
      pages: pages,
      personId: personId,
      guardianTabs: guardianTabs,
      seekerMembership: seekerBasic ? 'Seeker Basic' : 'Seeker One',
      guardianMembership: guardian && basic ? 'Guardian Basic' : 'Guardian One',
    ),
  );
  expect(h.latest.guardian, guardian);
  expect(
    guardian ? h.latest.guardianMembership : h.latest.seekerMembership,
    '$role $plan',
  );
  expect(h.latest.pages, pages, reason: 'Only accepted checkpoint routes');
  if (seekerBasic) expect(h.latest.model.capacity, 1);
  expect(
    h.shellFixture.fixture.seekerPhotos,
    isNull,
    reason: 'Populated entries use the production bundled-photo defaults',
  );
  _recordPhotos(h);
  return h;
}

const _sara = 'draft-sara';
DateTime _clock() => DateTime.utc(2026, 10, 29, 12);

ViewRequestDraftModel _basicStage(int index) {
  final model = ReceivedRequestFixture(capacity: 1, clock: _clock);
  expect(model.seedJourneys(1), isTrue);
  for (var number = 0; number < index; number++) {
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
    } else {
      expect(model.chooseStageContinue(_sara), isTrue);
      expect(model.simulatePeerStageContinue(_sara), isTrue);
      expect(model.advanceStage(_sara), isTrue);
    }
  }
  expect(model.capacity, 1);
  return model;
}

Future<BaselineHarness> _basicRoute(
  WidgetTester tester,
  String page, {
  required ViewRequestDraftModel model,
  int tab = 1,
  List<String>? pages,
  String personId = _sara,
}) => _mount(
  tester,
  guardian: false,
  basic: true,
  state: page,
  tab: tab,
  model: model,
  personId: personId,
  pages: pages ?? [page],
);

void _case(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

void main() {
  setUpAll(() async {
    await baselineSetUp(evidenceRoot: null);
    _bundledPhotos = await ZyraOneJourneySamplePhotos.load();
    _photoNames[_bundledPhotos.seekerPhoto] = 'seeker_self.jpg';
    _photoNames[_bundledPhotos.guardianPhoto] = 'guardian_self.jpg';
    for (var person = 0; person < _bundledPhotos.sets.length; person++) {
      for (var photo = 0; photo < _bundledPhotos.sets[person].length; photo++) {
        _photoNames[_bundledPhotos.sets[person][photo]] =
            '${ZyraOneJourneySamplePhotos.seeds[person][photo]}.jpg';
      }
    }
  });
  tearDownAll(() async {
    final file = File('build/line126-entry-photo-coverage.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'scope':
            'Ordinary route navigation and mounted actual bundled photo widgets; raster contrast is measured by the separate corpus callback',
        'own_seeker_photo_default': 'seeker_self.jpg',
        'peer_deck': 'ZyraOneJourneySamplePhotos.load defaults; no override',
        'explicit_empty_photo_cases': <String>[],
        'observations': _photoCoverage,
      }),
    );
    await baselineTearDown();
  });

  for (final guardian in [false, true]) {
    for (final basic in [false, true]) {
      final label =
          '${guardian ? 'Guardian' : 'Seeker'} '
          '${basic ? 'Basic' : 'One'}';
      for (final destination in ['settings', 'phone_access', 'help_support']) {
        _case('line126 public $label $destination', (tester) async {
          final h = await _mount(
            tester,
            guardian: guardian,
            basic: basic,
            state: destination,
          );
          expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
          await _tap(h, 'concept_settings');
          h.assertPage('settings');
          expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
          await _readAll(h);
          if (destination == 'phone_access') {
            await _tap(h, 'concept_settings_phoneAccess');
            h.assertPage('phone_access');
            expect(find.byType(ZyraPhoneAccessPage), findsOneWidget);
            await _readAll(h);
          } else if (destination == 'help_support') {
            await _tap(h, 'concept_settings_helpSupport');
            h.assertPage('help_support');
            expect(find.byType(HelpSupportScreen), findsOneWidget);
            await _readAll(h);
          }
        });
      }
      _case('line126 public $label Safety and advice to report', (
        tester,
      ) async {
        final h = await _mount(
          tester,
          guardian: guardian,
          basic: basic,
          state: 'safety',
        );
        await _tap(h, 'concept_safety_advice');
        h.assertPage('safety_advice');
        expect(find.byType(ZyraDraftSafetyAdvicePresentation), findsOneWidget);
        expect(
          tester
              .widget<ZyraDraftSafetyAdvicePresentation>(
                find.byType(ZyraDraftSafetyAdvicePresentation),
              )
              .guardian,
          guardian,
        );
        await _readAll(h);
        await _tap(h, 'draft_safety_advice_report');
        h.assertPage('safety');
        expect(find.byType(ZyraDraftReportPresentation), findsOneWidget);
        await _readAll(h);
      });
    }
  }

  for (final basic in [false, true]) {
    _case('line126 public Seeker ${basic ? 'Basic' : 'One'} Make Main notice', (
      tester,
    ) async {
      final h = await _mount(
        tester,
        guardian: false,
        basic: basic,
        state: 'guardian_main_notice',
        tab: 3,
      );
      expect(find.byType(ZyraOneJourneyGuardianCards), findsOneWidget);
      await swipeGuardianCard(tester);
      await h.flush();
      await h.tap('guardian-card-menu');
      await h.tap('guardian-make-main');
      expect(find.text('Make Yusuf your Main Guardian?'), findsOneWidget);
      await h.tap('guardian-make-main-confirmation-approve');
      h.assertPage('guardian_main_notice');
      expect(h.latest.mainGuardianId, 'draft-guardian-yusuf');
      expect(_key('concept_main_guardian_notice'), findsOneWidget);
      await _readAll(h);
    });
  }

  _case('line126 public Guardian Basic free-place invitation', (tester) async {
    final h = await _mount(
      tester,
      guardian: true,
      basic: true,
      bothBasic: true,
      state: 'guardian_free_place_invite',
      tab: 2,
      guardianTabs: ZyraGuardianTabsSnapshot(
        consumedFocus: const {'review-open-0'},
        freePlaceInviteExpiresAt: DateTime.utc(2026, 11, 30),
      ),
    );
    expect(h.latest.seekerMembership, 'Seeker Basic');
    await _tap(h, 'guardian_free_place_view');
    h.assertPage('guardian_free_place_invite');
    expect(find.byType(ZyraGuardianFreePlacePage), findsOneWidget);
    expect(find.text('Adam is on Seeker Basic'), findsOneWidget);
    await _readAll(h);
  });

  _registerSeekerBasic();
}

void _registerSeekerBasic() {
  for (var stage = 0; stage < 8; stage++) {
    final index = stage;
    _case('line126 Seeker Basic Journey stage $index', (tester) async {
      final model = _basicStage(index);
      final h = await _basicRoute(tester, 'journey', model: model);
      h.assertPage('journey');
      final presenter = tester.widget<ZyraConceptJourneyPresentation>(
        find.byType(ZyraConceptJourneyPresentation),
      );
      expect(presenter.stage.value, model.stageFor(_sara)!.value);
      await _readAll(h);
    });
  }

  for (final page in [
    'bio',
    'journey_compatibility',
    'journey_guardians',
    'timeline',
  ]) {
    _case('line126 Seeker Basic shared $page', (tester) async {
      final model = _basicStage(3);
      expect(model.canViewJourneyBio(_sara), isTrue);
      expect(model.canViewJourneyCompatibility(_sara), isTrue);
      final h = await _basicRoute(tester, page, model: model);
      h.assertPage(page);
      final type = switch (page) {
        'bio' => ZyraDraftJourneyBioPresentation,
        'journey_compatibility' => ZyraDraftCompatibilityPresentation,
        'journey_guardians' => ZyraJourneyPeerGuardiansPresentation,
        _ => ZyraDraftTimelinePresentation,
      };
      expect(find.byType(type), findsOneWidget);
      await _readAll(h);
    });
  }

  for (final choice in ['bio', 'compatibility', 'end']) {
    _case('line126 Seeker Basic actual Journey option $choice', (tester) async {
      final h = await _mount(
        tester,
        guardian: false,
        basic: true,
        state: 'journey_option_$choice',
        tab: 1,
        model: _basicStage(0),
      );
      await h.tap('draft_journey_options_$_sara');
      await h.tap('draft_options_${choice}_$_sara');
      final page = switch (choice) {
        'bio' => 'bio_locked',
        'compatibility' => 'journey_compatibility_locked',
        _ => 'journey_options',
      };
      h.assertPage(page);
      if (choice == 'end') {
        expect(_key('draft_journey_action_$_sara'), findsOneWidget);
        expect(_key('draft_confirm_end_$_sara'), findsOneWidget);
      } else {
        expect(_key('draft_${page}_$_sara'), findsOneWidget);
      }
      await _readAll(h);
    });
  }

  for (final shared in [false, true]) {
    for (final page in [
      'ended_archive',
      'ended_bio',
      'ended_compatibility',
      'ended_guardians',
    ]) {
      _case('line126 Seeker Basic $page shared=$shared', (tester) async {
        final model = _basicStage(shared ? 3 : 0);
        expect(model.end(_sara), isTrue);
        final h = await _basicRoute(
          tester,
          page,
          model: model,
          tab: 2,
          pages: ['ended', page],
        );
        h.assertPage(page);
        expect(model.hasVisibleEndedJourney(_sara), isTrue);
        switch (page) {
          case 'ended_archive':
            expect(
              find.byType(ZyraEndedJourneyArchivePresentation),
              findsOneWidget,
            );
          case 'ended_bio':
            expect(_key('draft_ended_bio_$_sara'), findsOneWidget);
            if (shared) {
              expect(
                find.byType(ZyraDraftJourneyBioPresentation),
                findsOneWidget,
              );
            }
          case 'ended_compatibility':
            expect(
              shared
                  ? find.byType(ZyraDraftCompatibilityPresentation)
                  : _key('draft_ended_compatibility_locked_$_sara'),
              findsOneWidget,
            );
          case 'ended_guardians':
            expect(_key('draft_ended_guardians_$_sara'), findsOneWidget);
        }
        await _readAll(h);
      });
    }
  }

  for (final page in [
    'profile',
    'compatibility',
    'introductions',
    'edit_profile',
  ]) {
    _case('line126 Seeker Basic accepted $page', (tester) async {
      final h = await _basicRoute(
        tester,
        page,
        model: ViewRequestDraftModel(capacity: 1, clock: _clock),
        tab: switch (page) {
          'introductions' => 2,
          'edit_profile' => 4,
          _ => 0,
        },
      );
      h.assertPage(page);
      final type = switch (page) {
        'profile' => ZyraFullProfilePreview,
        'compatibility' => ZyraDraftCompatibilityPresentation,
        'introductions' => ZyraRequestActivityPresentation,
        _ => EditProfileScreen,
      };
      expect(find.byType(type), findsOneWidget);
      await _readAll(h);
    });
  }

  _case('line126 Seeker Basic current Circle', (tester) async {
    final h = await _basicRoute(
      tester,
      'guardian_circle',
      model: _basicStage(0),
      tab: 3,
    );
    h.assertPage('guardian_circle');
    expect(find.byType(ZyraCircleTopicsPresentation), findsOneWidget);
    await _readAll(h);
    await h.tap('circle_topics_topic_$_sara');
    expect(
      tester
          .widget<ZyraCircleTopicsPresentation>(
            find.byType(ZyraCircleTopicsPresentation),
          )
          .selected
          ?.name,
      'Sara',
    );
    await _readAll(h);
  });

  _case('line126 Seeker Basic My ZYRA preferences', (tester) async {
    final h = await _mount(
      tester,
      guardian: false,
      basic: true,
      state: 'filter_preferences',
      tab: 2,
    );
    await _tap(h, 'focus-preferences');
    h.assertPage('filter_preferences');
    expect(find.byType(CompatibilityEditorScreen), findsOneWidget);
    await _readAll(h);
  });

  _case('line126 Seeker Basic actual Scan entry', (tester) async {
    final h = await _mount(
      tester,
      guardian: false,
      basic: true,
      state: 'scan',
      tab: 0,
    );
    await h.tap('concept_browse_menu');
    final target = find.descendant(
      of: _key('concept_browse_options_navigation'),
      matching: find.byIcon(ZyraBrowseAction.scan.icon),
    );
    expect(target, findsOneWidget);
    await tester.tapAt(tester.getCenter(target));
    await h.flush();
    h.assertPage('scan');
    expect(find.byType(ZyraDraftCodeEntry), findsOneWidget);
    await _readAll(h);
  });

  _case('line126 Seeker Basic paid Additional Guardian agreement', (
    tester,
  ) async {
    const id = 'draft-amira';
    final model = ReceivedRequestFixture(capacity: 1, clock: _clock);
    expect(model.acceptReceived(id), isTrue);
    expect(model.markReady(id), isTrue);
    expect(model.simulatePeerReady(id), isTrue);
    final h = await _basicRoute(tester, 'journey', model: model, personId: id);
    await _tap(h, 'draft_begin_$id');
    h.assertPage('guardian_access_agreement');
    expect(_key('draft_guardian_access_agreement'), findsOneWidget);
    expect(find.text('Agree and begin'), findsOneWidget);
    expect(h.latest.model.capacity, 1);
    expect(h.latest.model.states[id], DraftJourneyState.preparing);
    await _readAll(h);
  });
}
