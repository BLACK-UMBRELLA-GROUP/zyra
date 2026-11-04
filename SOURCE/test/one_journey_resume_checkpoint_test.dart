import 'package:zyra/theme/zyra_app_gold_style.dart';
// Fresh shell owners restore only detached fictional presentation values.
// These tests do not grant admission or call a member-data adapter.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/zyra_hidden_dev_controls_driver.dart';
import 'package:zyra/dev/zyra_journey_peer_guardians_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_settings_details.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Shell checkpoint fixtures must stay offline.');
  }
}

ZyraPreviewNavigationCheckpoint _seed({
  ViewRequestDraftModel? model,
  bool guardian = false,
  int tab = 0,
  List<String> pages = const [],
  String? personId,
  int requestsTab = 0,
  List<String> history = const [],
  int cursor = -1,
  String? browseId,
  Map<String, int> photos = const {},
  Map<String, int> galleries = const {},
  String? accountDestination,
  String? settingsDetail,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: guardian,
  model: (model ?? ViewRequestDraftModel(capacity: 3)).snapshot(),
  tab: tab,
  pages: pages,
  personId: personId,
  requestsTab: requestsTab,
  browseHistory: history,
  browseCursor: cursor,
  browseId: browseId,
  photoIndices: photos,
  galleryIndices: galleries,
  positions: const {'id:old-scroll': 123},
  accountDestination: accountDestination,
  settingsDetail: settingsDetail,
);

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  int exits = 0;

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    required ZyraPreviewNavigationCheckpoint checkpoint,
    bool restoreLocation = true,
    bool guardian = false,
    bool settle = true,
    Size size = const Size(393, 852),
  }) async {
    final ready = Completer<void>();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: ZyraOneJourneyConceptShell(
          fixture: ZyraShellTestFixture().fixture,
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () => exits++,
          initialGuardianRole: guardian,
          initialCheckpoint: checkpoint,
          restoreLocation: restoreLocation,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    // Exercise actual bundled offline deck preparation, not a substitute
    // screen or an injected checkpoint-ready signal.
    for (var frame = 0; frame < 60 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(
      ready.isCompleted,
      isTrue,
      reason: 'Actual offline photos finish before restoration is inspected',
    );
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }
}

void _expectTab(WidgetTester tester, int tab) {
  final navigation = tester.widget<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  expect(navigation.currentIndex, tab);
}

Future<void> _expectPaintedPhotoEditor(WidgetTester tester) async {
  final editor = find.byType(EditPhotosScreen);
  expect(editor, findsOneWidget);
  expect(find.byKey(const ValueKey('photos-title')), findsOneWidget);
  expect(find.byKey(const ValueKey('photos-page-view')), findsOneWidget);
  for (final element
      in find
          .descendant(of: editor, matching: find.byType(Image))
          .evaluate()
          .toList()) {
    Object? error;
    await tester.runAsync(
      () => precacheImage(
        (element.widget as Image).image,
        element,
        onError: (failure, _) => error = failure,
      ).timeout(const Duration(seconds: 5)),
    );
    expect(error, isNull);
  }
  await tester.pumpAndSettle();
  final photo = find.descendant(
    of: find.byKey(const ValueKey('photo-large-0')),
    matching: find.byType(RawImage),
  );
  expect(photo, findsOneWidget);
  expect(tester.widget<RawImage>(photo).image, isNotNull);
  expect(tester.widget<RawImage>(photo).image!.width, greaterThan(0));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late ZyraHapticLevel oldHaptics;

  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
    final gold = ZyraAppGoldStyle.instance;
    gold.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: gold.revision,
    );
    oldHaptics = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (var tab = 0; tab < 5; tab++) {
    testWidgets('fresh shell resumes seeker tab $tab from its captured value', (
      tester,
    ) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed(tab: tab));
      _expectTab(tester, tab);
      final captured = owner.latest;
      expect(captured.tab, tab);
      await owner.mount(tester, checkpoint: captured);
      _expectTab(tester, tab);
      expect(owner.latest.tab, tab);
      expect(owner.latest.pages, isEmpty);
      expect(owner.latest.model.states, captured.model.states);
    });
  }

  for (var requestTab = 0; requestTab < 3; requestTab++) {
    testWidgets('request section $requestTab survives a fresh shell', (
      tester,
    ) async {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.request('draft-sara'), isTrue);
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(
          model: model,
          tab: 2,
          pages: const ['requests'],
          requestsTab: requestTab,
        ),
      );
      final captured = owner.latest;
      await owner.mount(tester, checkpoint: captured);
      final requests = tester.widget<ZyraRequestActivityPresentation>(
        find.byKey(const ValueKey('concept_activity_requests')),
      );
      expect(requests.selectedIndex, requestTab);
      expect(requests.labels, ['Received', 'Sent', 'Past']);
      expect(owner.latest.requestsTab, requestTab);
      expect(owner.latest.pages, ['requests']);
      expect(owner.latest.model.states, captured.model.states);
    });
  }

  testWidgets('standalone Introductions survives a fresh shell independently', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(tab: 2, pages: const ['introductions']),
    );
    final captured = owner.latest;
    await owner.mount(tester, checkpoint: captured);
    final introductions = tester.widget<ZyraRequestActivityPresentation>(
      find.byKey(const ValueKey('concept_activity_introductions')),
    );
    expect(introductions.title, 'Introductions');
    expect(introductions.pages, hasLength(1));
    expect(introductions.selectedIndex, 0);
    expect(find.byType(PageView), findsNothing);
    expect(owner.latest.pages, ['introductions']);
    expect(owner.latest.requestsTab, 0);
    expect(owner.latest.model.states, captured.model.states);
  });

  testWidgets(
    'Past request checkpoint stays on Requests without remapping to Introductions',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.request('draft-sara'), isTrue);
      expect(model.cancel('draft-sara'), isTrue);
      final owner = _Owner();
      final past = _seed(
        model: model,
        tab: 2,
        pages: const ['requests'],
        requestsTab: 2,
      );
      await owner.mount(tester, checkpoint: past);
      final requests = tester.widget<ZyraRequestActivityPresentation>(
        find.byKey(const ValueKey('concept_activity_requests')),
      );
      expect(requests.labels, ['Received', 'Sent', 'Past']);
      expect(requests.selectedIndex, 2);
      expect(
        find.byKey(const ValueKey('concept_activity_introductions')),
        findsNothing,
      );
      expect(find.text('Cancelled'), findsOneWidget);
      expect(owner.latest.pages, ['requests']);
      expect(owner.latest.requestsTab, 2);
      expect(owner.latest.model.states, past.model.states);
      expect(owner.latest.model.pastRequests, past.model.pastRequests);
      expect(
        owner.latest.model.acknowledgedReceivedRequestIds,
        past.model.acknowledgedReceivedRequestIds,
      );
    },
  );

  testWidgets('long absence resets location but retains all three Journeys', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(3);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(
        model: model,
        tab: 1,
        pages: const ['journey_guardians'],
        personId: 'draft-sara',
        photos: const {'draft-sara': 1},
        galleries: const {'draft-sara': 2},
      ),
    );
    final captured = owner.latest;
    await owner.mount(tester, checkpoint: captured, restoreLocation: false);
    _expectTab(tester, 2);
    expect(owner.latest.pages, isEmpty);
    expect(owner.latest.personId, isNull);
    expect(owner.latest.photoIndices, isEmpty);
    expect(owner.latest.galleryIndices, isEmpty);
    expect(owner.latest.positions, isNot(contains('id:old-scroll')));
    final restored = ViewRequestDraftModel.fromSnapshot(owner.latest.model);
    expect(restored.capacity, 3);
    expect(restored.activeCount, 3);
    expect(owner.latest.model.states, captured.model.states);
    expect(owner.latest.model.progress, captured.model.progress);
  });

  testWidgets('completed read-only Journey paths retain their exact subject', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(3);
    // Private readers restore only after the same completed mutual steps that
    // admit a fresh menu intent; a seeded match alone is deliberately not one.
    const id = 'draft-sara';
    expect(model.sendSalam(id), isTrue);
    expect(model.simulatePeerSalam(id), isTrue);
    expect(model.chooseStageContinue(id), isTrue);
    expect(model.simulatePeerStageContinue(id), isTrue);
    expect(model.advanceStage(id), isTrue);
    expect(model.chooseCompatibilityReveal(id), isTrue);
    expect(model.simulatePeerCompatibilityReveal(id), isTrue);
    expect(model.chooseStageContinue(id), isTrue);
    expect(model.simulatePeerStageContinue(id), isTrue);
    expect(model.beginBioStep(id), isTrue);
    expect(model.chooseBioReveal(id), isTrue);
    expect(model.simulatePeerBioReveal(id), isTrue);
    expect(model.chooseBioContinue(id), isTrue);
    expect(model.simulatePeerBioContinue(id), isTrue);
    expect(model.completeBioStep(id), isTrue);
    final owner = _Owner();
    for (final page in [
      'bio',
      'timeline',
      'journey',
      'journey_compatibility',
    ]) {
      await owner.mount(
        tester,
        checkpoint: _seed(
          model: model,
          tab: 1,
          pages: [page],
          personId: 'draft-sara',
        ),
      );
      final captured = owner.latest;
      await owner.mount(tester, checkpoint: captured);
      expect(owner.latest.pages, [page]);
      expect(owner.latest.personId, 'draft-sara');
      expect(owner.latest.model.states, captured.model.states);
    }
  });

  testWidgets('hidden inspection resumes with read-only parent ownership', (
    tester,
  ) async {
    const id = 'draft-sara';
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.request(id), isTrue);
    expect(model.hide(id), isTrue);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(
        model: model,
        tab: 4,
        pages: const ['settings', 'account_action', 'profile'],
        personId: id,
        accountDestination: 'hiddenProfiles',
      ),
    );
    final first = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    expect(first.profiles.single.id, id);
    expect(first.showFeedChrome, isFalse);
    expect(first.onBrowseMenu, isNull);
    expect(first.onRequest, isNull);
    final checkpoint = owner.latest;
    expect(checkpoint.pages, ['settings', 'account_action', 'profile']);
    expect(checkpoint.accountDestination, 'hiddenProfiles');
    await owner.mount(tester, checkpoint: checkpoint);
    final restored = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    expect(restored.profiles.single.id, id);
    expect(restored.showFeedChrome, isFalse);
    expect(restored.onBrowseMenu, isNull);
    expect(restored.onRequest, isNull);
    expect(restored.onPrevious, isNull);
    expect(restored.onNext, isNull);
    final fresh = owner.latest;
    expect(owner.latest, same(fresh));
    expect(owner.latest.model.hiddenPeers, {id});
    expect(owner.latest.model.states[id], DraftJourneyState.sent);
    expect(owner.latest.model.states, checkpoint.model.states);
  });

  for (final blocked in [false, true]) {
    testWidgets('hidden-origin checkpoint refuses '
        '${blocked ? 'blocked' : 'no-longer-hidden'} profile inspection', (
      tester,
    ) async {
      const id = 'draft-sara';
      final model = ViewRequestDraftModel(capacity: 3)..hide(id);
      if (blocked) {
        expect(model.block(id), isTrue);
      } else {
        expect(model.unhide(id), isTrue);
      }
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(
          model: model,
          tab: 4,
          pages: const ['settings', 'account_action', 'profile'],
          personId: id,
          accountDestination: 'hiddenProfiles',
        ),
      );
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(
        find.byKey(const ValueKey('concept_hidden_inspection_draft-sara')),
        findsNothing,
      );
      expect(owner.latest.model.hiddenPeers, blocked ? {id} : <String>{});
      expect(owner.latest.model.blockedPeers, blocked ? {id} : <String>{});
      expect(owner.latest.model.states, model.snapshot().states);
      expect(tester.takeException(), isNull);
    });
  }

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    testWidgets(
      '$role resumes an informational overview without inventing a detail',
      (tester) async {
        final owner = _Owner();
        await owner.mount(
          tester,
          guardian: guardian,
          checkpoint: _seed(
            guardian: guardian,
            tab: guardian ? 3 : 4,
            pages: const ['settings', 'account_action'],
            accountDestination: 'privacyData',
            settingsDetail: 'terms',
          ),
        );
        expect(find.byType(ZyraConceptSettingsOverview), findsOneWidget);
        expect(owner.latest.accountDestination, 'privacyData');
        expect(owner.latest.settingsDetail, isNull);
        final captured = owner.latest;
        await owner.mount(tester, checkpoint: captured, guardian: guardian);
        expect(find.byType(ZyraConceptSettingsOverview), findsOneWidget);
        expect(owner.latest.pages, ['settings', 'account_action']);
        expect(owner.latest.accountDestination, 'privacyData');
        expect(owner.latest.settingsDetail, isNull);
        expect(tester.takeException(), isNull);
      },
    );

    for (final (action, detail) in <(String, String)>[
      ('signInSecurity', 'recovery'),
      ('appLock', 'appLock'),
      ('advanced', 'deleteAccount'),
      ('advanced', 'resetProfile'),
      ('visibility', 'discovery'),
      if (!guardian) ('hiddenProfiles', 'hiddenProfiles'),
      if (guardian) ('guardianPrivacy', 'discovery'),
      ('notificationSettings', 'notifications'),
      ('feedback', 'feedback'),
      ('privacyData', 'privacyPolicy'),
      ('privacyData', 'terms'),
    ]) {
      testWidgets(
        '$role resumes informational $action/$detail with fresh callbacks',
        (tester) async {
          final owner = _Owner();
          await owner.mount(
            tester,
            guardian: guardian,
            checkpoint: _seed(
              guardian: guardian,
              tab: guardian ? 3 : 4,
              pages: const ['settings', 'account_action', 'settings_detail'],
              accountDestination: action,
              settingsDetail: detail,
            ),
          );
          final captured = owner.latest;
          final oldDetail = tester
              .widget<ZyraConceptSettingsDetailPresentation>(
                find.byType(ZyraConceptSettingsDetailPresentation),
              );
          expect(oldDetail.detail.name, detail);
          expect(captured.accountDestination, action);
          expect(captured.settingsDetail, detail);
          await owner.mount(tester, checkpoint: captured, guardian: guardian);
          final currentDetail = tester
              .widget<ZyraConceptSettingsDetailPresentation>(
                find.byType(ZyraConceptSettingsDetailPresentation),
              );
          expect(currentDetail.detail.name, detail);
          expect(currentDetail.guardian, guardian);
          expect(currentDetail.overviewAction?.name, action);
          if (action == 'visibility') {
            expect(find.text('Pause My Profile'), findsOneWidget);
            expect(
              find.textContaining('Your confirmed Pause state is unavailable'),
              findsOneWidget,
            );
          } else if (action == 'guardianPrivacy') {
            expect(find.text('Guardian privacy'), findsOneWidget);
            expect(find.text('Pause My Profile'), findsNothing);
          } else if (action == 'hiddenProfiles') {
            // A legacy remembered detail remains a safe compact Help door,
            // not a reason to restore the retired overview explanation.
            expect(find.text('Hidden profiles'), findsOneWidget);
            expect(find.text('Open Help & support'), findsOneWidget);
            expect(find.text('Managing hidden profiles'), findsNothing);
            expect(
              find.byKey(
                const ValueKey(
                  'concept_settings_preview_scope_detail_hiddenProfiles',
                ),
              ),
              findsNothing,
            );
          }
          expect(identical(currentDetail, oldDetail), isFalse);
          oldDetail.onHelp();
          await tester.pump();
          expect(find.byType(HelpSupportScreen), findsNothing);
          expect(owner.latest.pages, [
            'settings',
            'account_action',
            'settings_detail',
          ]);
          expect(owner.latest.accountDestination, action);
          expect(owner.latest.settingsDetail, detail);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '$role recreates Help without retaining its old query or callbacks',
      (tester) async {
        final owner = _Owner();
        await owner.mount(
          tester,
          guardian: guardian,
          checkpoint: _seed(
            guardian: guardian,
            tab: guardian ? 3 : 4,
            pages: const [
              'settings',
              'account_action',
              'settings_detail',
              'help_support',
            ],
            accountDestination: 'privacyData',
            settingsDetail: 'terms',
          ),
        );
        final search = find.descendant(
          of: find.byKey(const ValueKey('help-support-preview-search')),
          matching: find.byType(TextField),
        );
        final oldState = tester.state(find.byType(HelpSupportScreen));
        final oldChange = tester.widget<TextField>(search).onChanged!;
        await tester.enterText(
          search,
          'Synthetic private search must not survive',
        );
        await tester.pumpAndSettle();
        final captured = owner.latest;
        await owner.mount(tester, checkpoint: captured, guardian: guardian);
        expect(oldState.mounted, isFalse);
        expect(tester.widget<TextField>(search).controller!.text, isEmpty);
        oldChange('Retained callback must not change the fresh Help route');
        await tester.pump();
        expect(tester.widget<TextField>(search).controller!.text, isEmpty);
        expect(owner.latest.pages, [
          'settings',
          'account_action',
          'settings_detail',
          'help_support',
        ]);
        expect(owner.latest.accountDestination, 'privacyData');
        expect(owner.latest.settingsDetail, 'terms');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$role long return drops informational destinations and subjects',
      (tester) async {
        final owner = _Owner();
        await owner.mount(
          tester,
          guardian: guardian,
          checkpoint: _seed(
            guardian: guardian,
            tab: guardian ? 3 : 4,
            pages: const [
              'settings',
              'account_action',
              'settings_detail',
              'help_support',
            ],
            accountDestination: 'privacyData',
            settingsDetail: 'terms',
          ),
          restoreLocation: false,
        );
        expect(owner.latest.pages, isEmpty);
        expect(owner.latest.accountDestination, isNull);
        expect(owner.latest.settingsDetail, isNull);
        expect(find.byType(HelpSupportScreen), findsNothing);
        expect(
          find.byType(ZyraConceptSettingsDetailPresentation),
          findsNothing,
        );
      },
    );
  }

  testWidgets(
    'unsafe informational IDs parents roles and siblings collapse safely',
    (tester) async {
      final owner = _Owner();
      for (final (guardian, tab, pages, action, detail, expected)
          in <(bool, int, List<String>, String?, String?, List<String>)>[
            (false, 4, ['account_action'], 'privacyData', null, []),
            (
              false,
              4,
              ['settings', 'settings_detail'],
              'privacyData',
              'terms',
              ['settings'],
            ),
            (
              false,
              4,
              ['settings', 'account_action'],
              'basket',
              null,
              ['settings'],
            ),
            (
              false,
              4,
              ['settings', 'account_action'],
              'cancelMembership',
              null,
              ['settings'],
            ),
            (
              false,
              4,
              ['settings', 'account_action'],
              'unknown',
              null,
              ['settings'],
            ),
            (
              false,
              4,
              ['settings', 'account_action'],
              'guardianPrivacy',
              null,
              ['settings'],
            ),
            (
              true,
              3,
              ['settings', 'account_action'],
              'hiddenProfiles',
              null,
              ['settings'],
            ),
            (
              false,
              4,
              ['settings', 'account_action', 'settings_detail'],
              'appLock',
              'recovery',
              ['settings', 'account_action'],
            ),
            (
              false,
              4,
              ['settings', 'account_action', 'settings_detail'],
              'privacyData',
              'unknown',
              ['settings', 'account_action'],
            ),
            (
              false,
              4,
              ['settings', 'account_action', 'checkout'],
              'privacyData',
              null,
              ['settings', 'account_action'],
            ),
            (true, 3, ['edit_profile'], null, null, []),
            (false, 1, ['edit_profile'], null, null, []),
            (false, 4, ['settings', 'edit_profile'], null, null, ['settings']),
            (false, 4, ['requests', 'help_support'], null, null, ['requests']),
            (false, 0, ['help_support'], null, null, []),
          ]) {
        await owner.mount(
          tester,
          guardian: guardian,
          checkpoint: _seed(
            guardian: guardian,
            tab: tab,
            pages: pages,
            accountDestination: action,
            settingsDetail: detail,
          ),
        );
        expect(
          owner.latest.pages,
          expected,
          reason: '$guardian/$pages/$action/$detail',
        );
        expect(owner.latest.settingsDetail, isNull);
        expect(
          owner.latest.accountDestination,
          expected.contains('account_action') ? action : null,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Seeker resumes only a fresh EditProfile hub, not private editor state',
    (tester) async {
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(tab: 4, pages: const ['edit_profile']),
      );
      final hub = tester.widget<EditProfileScreen>(
        find.byType(EditProfileScreen),
      );
      final oldState = tester.state(find.byType(EditProfileScreen));
      final repository = hub.repository!;
      final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
      expect(await repository.save(repository.currentUserId!, draft), isTrue);
      expect(await repository.load(repository.currentUserId!), isNotNull);
      await tester.tap(find.text('About you'));
      await tester.pumpAndSettle();
      final editor = tester.widget<CompatibilityEditorScreen>(
        find.byType(CompatibilityEditorScreen),
      );
      final captured = owner.latest;
      expect(captured.pages, ['edit_profile']);
      await owner.mount(tester, checkpoint: captured);
      final freshHub = tester.widget<EditProfileScreen>(
        find.byType(EditProfileScreen),
      );
      final freshRepository = freshHub.repository!;
      expect(oldState.mounted, isFalse);
      expect(find.byType(CompatibilityEditorScreen), findsNothing);
      expect(identical(freshRepository, repository), isFalse);
      expect(
        await freshRepository.load(freshRepository.currentUserId!),
        isNull,
      );
      expect(await editor.onPersist(draft), isFalse);
      await tester.pump();
      expect(owner.latest.pages, ['edit_profile']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unsafe editors camera and confirmations collapse safely', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(3);
    final owner = _Owner();
    for (final (pages, expected) in <(List<String>, List<String>)>[
      (['controls'], []),
      (['settings', 'controls'], ['settings']),
      (['settings', 'edit_profile'], ['settings']),
      (['scan'], []),
      (['requests', 'request_capacity'], ['requests']),
      (['journey', 'journey_action'], ['journey']),
      (['account_action'], []),
    ]) {
      await owner.mount(
        tester,
        checkpoint: _seed(
          model: model,
          tab: 1,
          pages: pages,
          personId: 'draft-sara',
        ),
      );
      expect(owner.latest.pages, expected, reason: 'Unsafe stack: $pages');
      final sanitized = owner.latest;
      await owner.mount(tester, checkpoint: sanitized);
      expect(owner.latest.pages, expected);
    }
  });

  for (final guardian in [false, true]) {
    testWidgets(
      'fresh ${guardian ? 'Guardian' : 'Seeker'} owner restores Photos without borrowing its old editor',
      (tester) async {
        final owner = _Owner();
        final memberPhotos = List<String>.of(AppState.instance.photos);
        await owner.mount(
          tester,
          guardian: guardian,
          checkpoint: _seed(
            guardian: guardian,
            tab: guardian ? 3 : 4,
            pages: const ['settings', 'manage_photos'],
          ),
        );
        await _expectPaintedPhotoEditor(tester);
        final oldState = tester.state<State<EditPhotosScreen>>(
          find.byType(EditPhotosScreen),
        );
        final stale = tester
            .widget<IconButton>(
              find.byKey(const ValueKey('photos-compact-toggle')),
            )
            .onPressed!;
        final captured = owner.latest;
        expect(captured.pages, ['settings', 'manage_photos']);
        await owner.mount(tester, checkpoint: captured, guardian: guardian);
        await _expectPaintedPhotoEditor(tester);
        expect(oldState.mounted, isFalse);
        expect(
          identical(oldState, tester.state(find.byType(EditPhotosScreen))),
          isFalse,
        );
        stale();
        await tester.pump();
        expect(find.byKey(const ValueKey('photos-compact-view')), findsNothing);
        expect(owner.latest.pages, ['settings', 'manage_photos']);
        expect(owner.latest.model.states, captured.model.states);
        expect(AppState.instance.photos, memberPhotos);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('long Guardian return resets navigation to My ZYRA', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(
      tester,
      guardian: true,
      checkpoint: _seed(guardian: true, tab: 3, pages: const ['manage_photos']),
      restoreLocation: false,
    );
    _expectTab(tester, 2);
    expect(owner.latest.pages, isEmpty);
    expect(find.byType(EditPhotosScreen), findsNothing);
  });

  testWidgets('a checkpoint for a different role is ignored, not borrowed', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(3);
    final owner = _Owner();
    await owner.mount(
      tester,
      guardian: true,
      checkpoint: _seed(
        model: model,
        tab: 4,
        pages: const ['journey_guardians'],
        personId: 'draft-sara',
      ),
    );
    expect(owner.latest.guardian, isTrue);
    expect(owner.latest.tab, 2);
    expect(owner.latest.pages, isEmpty);
    expect(owner.latest.personId, isNull);
    expect(
      ViewRequestDraftModel.fromSnapshot(owner.latest.model).activeCount,
      0,
    );
    expect(find.byType(ZyraJourneyPeerGuardiansPresentation), findsNothing);
    _expectTab(tester, 2);
  });

  testWidgets('Browse restores history and gallery on first prepared frame', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(
        history: const ['draft-sara', 'draft-aisha', 'draft-maryam'],
        cursor: 1,
        browseId: 'draft-aisha',
        photos: const {'draft-aisha': 1},
        galleries: const {'draft-aisha': 2},
      ),
      settle: false,
    );
    final captured = owner.latest;
    await owner.mount(tester, checkpoint: captured, settle: false);
    final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    expect(browse.profiles[browse.selectedIndex].id, 'draft-aisha');
    expect(browse.initialPhotoIndices, isEmpty);
    expect(browse.initialGalleryIndices['draft-aisha'], 2);
    expect(owner.latest.photoIndices['draft-aisha'], 1);
    expect(owner.latest.galleryIndices['draft-aisha'], 2);
    final pager = tester.widget<PageView>(
      find.byKey(const ValueKey('concept_browse_photo_swipe_draft-aisha')),
    );
    expect(pager.controller!.initialPage, 2);
    expect(pager.controller!.page, closeTo(2, .001));
    expect(pager.controller!.position.isScrollingNotifier.value, isFalse);
    expect(owner.latest.browseHistory, [
      'draft-sara',
      'draft-aisha',
      'draft-maryam',
    ]);
    expect(owner.latest.browseCursor, 1);
    browse.onNext!();
    await tester.pumpAndSettle();
    expect(owner.latest.browseId, 'draft-maryam');
    expect(owner.latest.galleryIndices['draft-maryam'], 0);
    expect(owner.latest.browseHistory, [
      'draft-sara',
      'draft-aisha',
      'draft-maryam',
    ]);
    final nextBrowse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    nextBrowse.onGalleryIndexChanged!('draft-maryam', 2);
    nextBrowse.onPrevious!();
    await tester.pumpAndSettle();
    expect(owner.latest.browseId, 'draft-aisha');
    expect(owner.latest.galleryIndices['draft-aisha'], 0);
    final returnedPager = tester.widget<PageView>(
      find.byKey(const ValueKey('concept_browse_photo_swipe_draft-aisha')),
    );
    expect(returnedPager.controller!.page, closeTo(0, .001));
    final returnedBrowse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    returnedBrowse.onNext!();
    await tester.pumpAndSettle();
    expect(owner.latest.browseId, 'draft-maryam');
    expect(owner.latest.galleryIndices['draft-maryam'], 0);
  });

  testWidgets(
    'legacy photo checkpoints open Browse details without remapping',
    (tester) async {
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(
          browseId: 'draft-aisha',
          photos: const {'draft-aisha': 1},
        ),
        settle: false,
      );
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      expect(browse.profiles[browse.selectedIndex].id, 'draft-aisha');
      expect(browse.initialPhotoIndices, isEmpty);
      expect(browse.initialGalleryIndices, isEmpty);
      final pager = tester.widget<PageView>(
        find.byKey(const ValueKey('concept_browse_photo_swipe_draft-aisha')),
      );
      expect(pager.controller!.initialPage, 0);
      expect(pager.controller!.page, closeTo(0, .001));
      expect(owner.latest.photoIndices, {'draft-aisha': 1});
      expect(owner.latest.galleryIndices, isEmpty);
    },
  );

  testWidgets(
    'Details-first gallery resumes without shifting actual photo ordinals',
    (tester) async {
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(
          browseId: 'draft-aisha',
          galleries: const {'draft-aisha': 2},
          photos: const {'draft-aisha': 1},
        ),
        settle: false,
      );
      final captured = owner.latest;
      expect(captured.galleryIndices, {'draft-aisha': 2});
      expect(captured.photoIndices, {'draft-aisha': 1});
      await owner.mount(tester, checkpoint: captured, settle: false);
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      expect(browse.initialPhotoIndices, isEmpty);
      expect(browse.initialGalleryIndices, {'draft-aisha': 2});
      final pager = tester.widget<PageView>(
        find.byKey(const ValueKey('concept_browse_photo_swipe_draft-aisha')),
      );
      expect(pager.controller!.initialPage, 2);
      expect(pager.controller!.page, closeTo(2, .001));
      expect(
        find.byKey(const ValueKey('concept_browse_details_draft-aisha')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('concept_browse_identity_draft-aisha')),
        findsNothing,
      );
      expect(owner.latest.photoIndices, {'draft-aisha': 1});
      expect(owner.latest.galleryIndices, {'draft-aisha': 2});

      await owner.mount(tester, checkpoint: captured, restoreLocation: false);
      _expectTab(tester, 2);
      expect(owner.latest.pages, isEmpty);
      expect(owner.latest.galleryIndices, isEmpty);
      expect(owner.latest.photoIndices, isEmpty);
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsNothing);
      final navigation = find.byType(ZyraShellNavigation);
      final currentNavigation = tester.widget<ZyraShellNavigation>(navigation);
      final profilesIcon = find.descendant(
        of: navigation,
        matching: find.byIcon(currentNavigation.items.first.icon),
      );
      expect(profilesIcon, findsOneWidget);
      await expandZyraPreviewTabBarIfIdle(tester);
      await tester.tapAt(tester.getCenter(profilesIcon));
      await tester.pumpAndSettle();
      _expectTab(tester, 0);
      final reset = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      expect(reset.initialGalleryIndices, isEmpty);
    },
  );

  testWidgets('restored gallery pages require known IDs and bounded ordinals', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(
        galleries: const {
          'draft-sara': 0,
          'draft-aisha': 6,
          'draft-maryam': -1,
          'draft-hana': 7,
          'unknown-person': 1,
        },
      ),
    );
    expect(owner.latest.galleryIndices, {'draft-sara': 0, 'draft-aisha': 6});
    final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    browse.onGalleryIndexChanged!('draft-maryam', 0);
    expect(owner.latest.galleryIndices['draft-maryam'], 0);
    final captured = owner.latest;
    for (final rejected in [
      (id: 'unknown-person', index: 1),
      (id: 'draft-hana', index: -1),
      (id: 'draft-hana', index: 7),
    ]) {
      browse.onGalleryIndexChanged!(rejected.id, rejected.index);
    }
    expect(identical(owner.latest, captured), isTrue);
    expect(owner.latest.photoIndices, isEmpty);
  });

  testWidgets('profile leaf resumes its photo on the first prepared frame', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(
        tab: 0,
        pages: const ['profile'],
        personId: 'draft-sara',
        photos: const {'draft-sara': 1},
      ),
      settle: false,
    );
    final photo = tester.widget<ZyraOneJourneyBrowsePresentation>(
      find.byType(ZyraOneJourneyBrowsePresentation),
    );
    expect(photo.profile.id, 'draft-sara');
    expect(photo.profile.photos.length, greaterThan(1));
    final painted = find.descendant(
      of: find.byType(ZyraOneJourneyBrowsePresentation),
      matching: find.byType(ZyraProfileImage),
    );
    expect(painted, findsOneWidget);
    expect(
      tester.widget<ZyraProfileImage>(painted).photo,
      photo.profile.photos[1],
    );
  });

  testWidgets('fresh generic page restores the exact scrolled position', (
    tester,
  ) async {
    final owner = _Owner();
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
    const id = 'draft-sara';
    expect(model.sendSalam(id), isTrue);
    expect(model.simulatePeerSalam(id), isTrue);
    expect(model.chooseStageContinue(id), isTrue);
    expect(model.simulatePeerStageContinue(id), isTrue);
    expect(model.advanceStage(id), isTrue);
    expect(model.chooseCompatibilityReveal(id), isTrue);
    expect(model.simulatePeerCompatibilityReveal(id), isTrue);
    expect(model.chooseStageContinue(id), isTrue);
    expect(model.simulatePeerStageContinue(id), isTrue);
    expect(model.beginBioStep(id), isTrue);
    // Completed result copy is shorter and the visible Back strip is gone.
    // Keep a genuinely overflowing compact viewport for the unchanged
    // exact40px capture and fresh-restoration proof below.
    const size = Size(393, 320);
    await owner.mount(
      tester,
      checkpoint: _seed(
        model: model,
        tab: 1,
        pages: const ['journey_compatibility'],
        personId: 'draft-sara',
      ),
      size: size,
    );
    ScrollController controller() => tester
        .widget<SingleChildScrollView>(
          find.byKey(const ValueKey('draft_scroll')),
        )
        .controller!;
    expect(controller().position.maxScrollExtent, greaterThan(40));
    controller().jumpTo(40);
    await tester.pump();
    final captured = owner.latest;
    expect(captured.scrollOffset, 40);
    await owner.mount(tester, checkpoint: captured, size: size);
    expect(controller().offset, closeTo(40, .001));
    expect(owner.latest.scrollOffset, 40);
  });

  testWidgets('restored peer Guardians never becomes own management', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(3);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(
        model: model,
        tab: 1,
        pages: const ['journey_guardians'],
        personId: 'draft-sara',
      ),
    );
    final captured = owner.latest;
    await owner.mount(tester, checkpoint: captured);
    final peer = tester.widget<ZyraJourneyPeerGuardiansPresentation>(
      find.byType(ZyraJourneyPeerGuardiansPresentation),
    );
    expect(peer.subjectId, 'draft-sara');
    expect(peer.firstName, 'Sara');
    expect(peer.guardians!.map((guardian) => guardian.firstName), [
      'Ibrahim',
      'Maryam',
      'Yusuf',
    ]);
    expect(find.byType(SeekerGuardianPage), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Remove Guardian'), findsNothing);
    expect(find.text('Active Journey access'), findsNothing);
  });

  testWidgets('fresh denial rejects retained actions and publications', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(tester, checkpoint: _seed());
    final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    final person = browse.profiles[browse.selectedIndex];
    final navigation = tester.widget<ZyraShellNavigation>(
      find.byType(ZyraShellNavigation),
    );
    final count = owner.checkpoints.length;
    final last = owner.latest;
    owner.allowed = false;
    browse.onNext!();
    browse.onRequest?.call(person);
    browse.onPhotoIndexChanged!(person.id, 1);
    browse.onGalleryIndexChanged!(person.id, 2);
    navigation.onTap(1);
    await tester.pumpAndSettle();
    expect(owner.checkpoints.length, count);
    expect(identical(owner.latest, last), isTrue);
    expect(owner.exits, 0);
  });
}
