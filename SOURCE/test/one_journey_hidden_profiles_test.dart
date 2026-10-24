// The protected Profiles and Settings pages share one fictional hidden set.
// No live HiddenProfilesScreen, member store, server or platform camera is used.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_founder_launch_review.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_settings_details.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/settings/hidden_profiles_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _font = 'PoppinsHiddenProfiles';
const _restore = 'concept_hidden_profile_unhide_$_sara';
const _view = 'concept_hidden_profile_view';
const _confirm = 'concept_hidden_profile_restore_confirm';
const _cancel = 'concept_hidden_profile_restore_cancel';
const _help = 'concept_settings_help_overview_hiddenProfiles';
const _footer = 'concept_settings_footer_overview_hiddenProfiles';
const _card = 'concept_hidden_profile_card_$_sara';
const _avatar = 'concept_hidden_profile_avatar_$_sara';
const _photo = 'concept_hidden_profile_photo_$_sara';
const _placeholder = 'concept_hidden_profile_placeholder_$_sara';
const _captureDirectory = String.fromEnvironment(
  'ZYRA_HIDDEN_PROFILES_CAPTURE_DIR',
);
const _captureRoot = ValueKey('hidden-profiles-review');

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureRoot),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  image!.dispose();
  expect(bytes, isNotNull);
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
    await file.parent.create(recursive: true);
    expect(await file.exists(), isFalse);
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  });
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Fictional hidden-profile tests must stay offline.');
  }
}

ZyraPreviewNavigationCheckpoint _seed({
  ViewRequestDraftModel? model,
  bool hiddenPage = false,
}) {
  final value = model ?? ViewRequestDraftModel(capacity: 3);
  return ZyraPreviewNavigationCheckpoint(
    guardian: false,
    model: value.snapshot(),
    tab: hiddenPage ? 4 : 0,
    pages: hiddenPage ? const ['settings', 'account_action'] : const [],
    accountDestination: hiddenPage ? 'hiddenProfiles' : null,
    browseId: _sara,
    browseHistory: const [_sara],
    browseCursor: 0,
  );
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  final navigator = GlobalKey<NavigatorState>();
  late final access = ZyraDraftCompatibilityAccessStore(canAct: () => allowed);

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    required ZyraPreviewNavigationCheckpoint checkpoint,
    bool compact = false,
    bool restoreLocation = true,
    bool guardian = false,
  }) async {
    if (find.byType(ZyraOneJourneyConceptShell).evaluate().isNotEmpty) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
    tester.view.physicalSize = compact
        ? const Size(320, 568)
        : const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ready = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        navigatorKey: navigator,
        navigatorObservers: [ZyraDevControlsRouteObserver()],
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(compact ? 2 : 1),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: RepaintBoundary(
          key: _captureRoot,
          child: ZyraOneJourneyConceptShell(
            key: UniqueKey(),
            canAct: () => allowed,
            onExit: () => fail('Hidden Profiles stays within its shell owner.'),
            initialGuardianRole: guardian,
            initialCheckpoint: checkpoint,
            restoreLocation: restoreLocation,
            compatibilityAccess: access,
            onCheckpoint: checkpoints.add,
            onPresentationReady: () {
              if (!ready.isCompleted) ready.complete();
            },
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue);
    await tester.pumpAndSettle();
    expect(checkpoints, isNotEmpty);
    expect(tester.takeException(), isNull);
  }
}

ZyraConceptSettingsOverview _overview(WidgetTester tester) =>
    tester.widget<ZyraConceptSettingsOverview>(
      find.byType(ZyraConceptSettingsOverview),
    );

List<String> _browseIds(WidgetTester tester) => tester
    .widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    )
    .profiles
    .map((profile) => profile.id)
    .toList();

Future<void> _reveal(WidgetTester tester, String key) async {
  final target = _key(key);
  if (target.evaluate().isEmpty) {
    final owner = key == 'concept_settings'
        ? _key('concept-current-profile-scroll')
        : key.startsWith('concept_settings_') &&
              _key('concept-current-settings-scroll').evaluate().isNotEmpty
        ? _key('concept-current-settings-scroll')
        : _key('concept_account_action_scroll');
    expect(owner, findsOneWidget);
    final scroll = find
        .descendant(of: owner, matching: find.byType(Scrollable))
        .first;
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 180, scrollable: scroll);
    }
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _press(WidgetTester tester, String key) async {
  await _reveal(tester, key);
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, String label) async {
  final navigation = find.byType(ZyraShellNavigation);
  expect(navigation, findsOneWidget);
  final item = tester
      .widget<ZyraShellNavigation>(navigation)
      .items
      .singleWhere((item) => item.label == label);
  final icon = find.descendant(
    of: navigation,
    matching: find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  final owner = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(owner.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _hideSara(WidgetTester tester, _Owner owner) async {
  final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
    find.byType(ZyraOneJourneyBrowseDesigns),
  );
  expect(browse.profiles[browse.selectedIndex].id, _sara);
  await _press(tester, 'concept_browse_menu');
  await _nav(tester, 'Hide profile');
  await _press(tester, 'browse-hide-confirm');
  expect(owner.latest.model.hiddenPeers, contains(_sara));
  expect(_browseIds(tester), isNot(contains(_sara)));
}

Future<void> _hiddenSettings(WidgetTester tester) async {
  await _nav(tester, 'Profile');
  await _press(tester, 'concept_settings');
  await _press(tester, 'concept_settings_hiddenProfiles');
  expect(find.byType(ZyraConceptSettingsOverview), findsOneWidget);
  expect(find.byType(HiddenProfilesScreen), findsNothing);
}

Future<void> _back(WidgetTester tester) async {
  await returnZyraPreviewPage(tester);
  await tester.pumpAndSettle();
}

Future<void> _returnToProfiles(WidgetTester tester) async {
  await _back(tester);
  await _back(tester);
  await _nav(tester, 'Profiles');
}

void _expectOnlySara(WidgetTester tester) {
  final view = _overview(tester);
  expect(view.hiddenProfiles!.map((profile) => profile.id), [_sara]);
  expect(view.hiddenProfiles!.single.name, contains('Sara'));
  expect(_key(_restore), findsOneWidget);
  expect(
    find.descendant(of: _key(_restore), matching: find.textContaining('Sara')),
    findsWidgets,
  );
  expect(_key('concept_hidden_profile_unhide_$_aisha'), findsNothing);
  _expectCompactHiddenCopy(tester);
}

void _expectPinnedHelp(WidgetTester tester) {
  expect(_key(_help), findsOneWidget);
  expect(_key(_help).hitTestable(), findsOneWidget);
  expect(_key(_footer), findsOneWidget);
  expect(
    find.descendant(of: _key(_footer), matching: _key(_help)),
    findsOneWidget,
  );
  final scroll = _key('concept_account_action_scroll');
  expect(scroll, findsOneWidget);
  expect(find.descendant(of: scroll, matching: _key(_help)), findsNothing);
  final help = tester.getRect(_key(_help));
  final safeBottom =
      tester.view.physicalSize.height / tester.view.devicePixelRatio - 34;
  expect(help.height, greaterThanOrEqualTo(44));
  expect(help.bottom, lessThanOrEqualTo(safeBottom + .1));
  expect(safeBottom - help.bottom, inInclusiveRange(0, 32));
  expect(tester.getRect(scroll).bottom, lessThanOrEqualTo(help.top));
}

void _expectCardContents(WidgetTester tester) {
  expect(_key(_card), findsOneWidget);
  final bounds = tester.getRect(_key(_card));
  for (final key in [_restore, _view, _confirm, _cancel]) {
    expect(
      find.descendant(of: _key(_card), matching: _key(key)),
      findsOneWidget,
    );
    final child = tester.getRect(_key(key));
    expect(bounds.contains(child.topLeft), isTrue);
    expect(bounds.contains(child.bottomRight - const Offset(.1, .1)), isTrue);
  }
  expect(find.descendant(of: _key(_card), matching: _key(_help)), findsNothing);
}

void _expectReadableHiddenText(WidgetTester tester) {
  var measured = 0;
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  for (final element
      in find
          .descendant(
            of: find.byType(ZyraConceptSettingsOverview),
            matching: find.byType(Text),
          )
          .evaluate()) {
    final text = element.widget as Text;
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    final object = element.findRenderObject();
    if (object is RenderParagraph && object.hasSize) {
      measured++;
      expect(object.didExceedMaxLines, isFalse);
      expect(object.size.width, lessThanOrEqualTo(width));
    }
  }
  expect(measured, greaterThan(0));
}

void _expectCompactHiddenCopy(WidgetTester tester) {
  expect(find.text('Hidden profiles'), findsOneWidget);
  expect(find.text('Open Help & support'), findsOneWidget);
  expect(
    _key('concept_settings_preview_scope_overview_hiddenProfiles'),
    findsNothing,
  );
  for (final copy in [
    'A private list, controlled by you.',
    'Sample profiles hidden in this app preview. Your real account’s hidden profiles are separate.',
    'A choice for your view only',
    'Managing hidden profiles',
    'No hidden profiles',
  ]) {
    expect(find.text(copy), findsNothing);
  }
  expect(
    find.textContaining('No personal hidden-profile list is loaded'),
    findsNothing,
  );
  expect(
    _key('concept_settings_open_hiddenProfiles_hiddenProfiles'),
    findsNothing,
  );
  _expectPinnedHelp(tester);
}

Future<void> _expectActions(WidgetTester tester) async {
  expect(_overview(tester).confirmingHiddenProfileId, _sara);
  for (final (key, label) in [
    (_view, 'View profile'),
    (_confirm, 'Unhide profile'),
    (_cancel, 'Cancel'),
  ]) {
    await _reveal(tester, key);
    expect(_key(key), findsOneWidget);
    expect(
      find.descendant(of: _key(key), matching: find.text(label)),
      findsOneWidget,
    );
    expect(tester.getSize(_key(key)).height, greaterThanOrEqualTo(44));
  }
  expect(find.textContaining('This only removes your hide'), findsNothing);
  _expectCompactHiddenCopy(tester);
}

void _expectNonHideStateUnchanged(
  ViewRequestDraftSnapshot before,
  ViewRequestDraftSnapshot after,
) {
  expect(after.states, before.states);
  expect(after.saved, before.saved);
  expect(after.busyPeers, before.busyPeers);
  expect(after.blockedPeers, before.blockedPeers);
  expect(after.capacity, before.capacity);
  expect(after.progress, before.progress);
  expect(after.journeyStartedAt, before.journeyStartedAt);
  expect(after.endedAttempts, before.endedAttempts);
  expect(after.currentEndedAttemptIds, before.currentEndedAttemptIds);
  expect(after.guardianAccess, before.guardianAccess);
  expect(after.requiredPaidGuardianAccess, before.requiredPaidGuardianAccess);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late String? oldReading;
  late ZyraHapticLevel oldHaptics;

  setUpAll(() async {
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });
  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    oldReading = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevAppGold.instance.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: ZyraDevAppGold.instance.revision,
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
    ZyraText.testReadingFontFamily = oldReading;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('unhide removes only a known hidden fixture flag', () {
    final model = ViewRequestDraftModel(capacity: 3)..seedHistory();
    expect(model.request(_sara), isTrue);
    expect(model.save(_sara), isTrue);
    expect(model.hide(_sara), isTrue);
    expect(model.hide(_aisha), isTrue);
    final before = model.snapshot();
    expect(model.unhide('not-a-fixture'), isFalse);
    expect(model.unhide('00000000-0000-4000-8000-000000001234'), isFalse);
    expect(model.unhide('draft-amira'), isFalse);
    expect(model.hiddenPeers, {_sara, _aisha});
    expect(model.unhide(_sara), isTrue);
    expect(model.unhide(_sara), isFalse);
    expect(model.hiddenPeers, {_aisha});
    _expectNonHideStateUnchanged(before, model.snapshot());
    expect(model.stateFor(_sara), DraftJourneyState.sent);
    expect(
      model.discoverableProfiles.map((profile) => profile.id),
      contains(_sara),
    );
  });

  test('unhide never removes a block or revives a blocked discovery row', () {
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.hide(_sara), isTrue);
    expect(model.block(_sara), isTrue);
    final before = model.snapshot();
    expect(model.unhide(_sara), isTrue);
    expect(model.isHidden(_sara), isFalse);
    expect(model.isBlocked(_sara), isTrue);
    expect(
      model.discoverableProfiles.map((profile) => profile.id),
      isNot(contains(_sara)),
    );
    _expectNonHideStateUnchanged(before, model.snapshot());
  });

  test(
    'hidden list is detached in checkpoints and explicit reset clears it',
    () {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.hide(_sara), isTrue);
      final saved = model.snapshot();
      final restored = ViewRequestDraftModel.fromSnapshot(saved);
      expect(restored.hiddenPeers, {_sara});
      expect(restored.unhide(_sara), isTrue);
      expect(saved.hiddenPeers, {_sara});
      expect(model.hiddenPeers, {_sara});
      restored.hide(_aisha);
      restored.reset();
      expect(restored.hiddenPeers, isEmpty);
      expect(saved.hiddenPeers, {_sara});
    },
  );

  testWidgets(
    'Profiles hide appears in Settings and restore keeps request and unlock',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.request(_sara), isTrue);
      final owner = _Owner();
      expect(owner.access.unlock(_sara), isTrue);
      final unlocked = owner.access.resultFor(_sara);
      await owner.mount(tester, checkpoint: _seed(model: model));
      await _hideSara(tester, owner);
      final before = owner.latest.model;
      await _hiddenSettings(tester);
      _expectOnlySara(tester);
      expect(
        find.textContaining('No personal hidden-profile list is loaded'),
        findsNothing,
      );
      await _capture(tester, '01-hidden-list');
      await _press(tester, _restore);
      await _expectActions(tester);
      expect(owner.latest.model.hiddenPeers, {_sara});
      await _capture(tester, '02-hidden-actions');
      await _press(tester, _confirm);
      expect(owner.latest.model.hiddenPeers, isEmpty);
      _expectCompactHiddenCopy(tester);
      expect(_key('concept_hidden_profiles_empty'), findsNothing);
      expect(_key(_restore), findsNothing);
      await _capture(tester, '05-hidden-empty');
      _expectNonHideStateUnchanged(before, owner.latest.model);
      expect(owner.latest.model.states[_sara], DraftJourneyState.sent);
      expect(owner.access.balance, 0);
      expect(owner.access.resultFor(_sara), same(unlocked));
      await _returnToProfiles(tester);
      expect(_browseIds(tester), contains(_sara));
    },
  );

  testWidgets('cancel restoration keeps the same profile hidden', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    _expectOnlySara(tester);
    await _press(tester, _restore);
    final retainedView = _overview(tester).onViewHiddenProfile!;
    await _press(tester, _cancel);
    final cancelled = owner.latest;
    retainedView();
    await tester.pumpAndSettle();
    expect(owner.latest, same(cancelled));
    expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
    expect(owner.latest.model.hiddenPeers, {_sara});
    expect(_overview(tester).confirmingHiddenProfileId, isNull);
    _expectOnlySara(tester);
  });

  testWidgets('an empty Hidden profiles page has only its title and Help', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(tester, checkpoint: _seed(hiddenPage: true));
    _expectCompactHiddenCopy(tester);
    expect(_overview(tester).hiddenProfiles, isEmpty);
    final text = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(ZyraConceptSettingsOverview),
        matching: find.byType(Text),
      ),
    );
    expect(text.map((widget) => widget.data), [
      'Hidden profiles',
      'Open Help & support',
    ]);
    expect(_key(_view), findsNothing);
    expect(_key(_confirm), findsNothing);
    expect(_key(_cancel), findsNothing);
  });

  testWidgets(
    'Compact halo uses its admitted fixture photo and one action card',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(model: model, hiddenPage: true),
      );
      expect(_overview(tester).hiddenProfiles!.single.thumbnail, isNotNull);
      expect(_key(_placeholder), findsNothing);
      expect(tester.getSize(_key(_avatar)), const Size(56, 56));
      expect(
        tester.widget<Container>(_key(_avatar)).decoration,
        isA<BoxDecoration>().having(
          (value) => value.shape,
          'shape',
          BoxShape.circle,
        ),
      );
      expect(tester.widget<ClipOval>(_key(_photo)), isA<ClipOval>());
      expect(tester.getSize(_key(_photo)), const Size(50, 50));
      final image = tester.widget<Image>(
        find.descendant(of: _key(_photo), matching: find.byType(Image)),
      );
      expect(image.image, isA<MemoryImage>());
      expect(image.gaplessPlayback, isFalse);
      final index = draftProfiles.indexWhere((person) => person.id == _sara);
      final seed = ZyraOneJourneySamplePhotos.seeds[index].first;
      final bytes = await tester.runAsync(
        () => rootBundle.load('assets/dev/one_journey_photos/$seed.jpg'),
      );
      expect(bytes, isNotNull);
      final fixture = bytes!;
      final expected = fixture.buffer.asUint8List(
        fixture.offsetInBytes,
        fixture.lengthInBytes,
      );
      final actual = (image.image as MemoryImage).bytes;
      expect(actual.length, expected.length);
      expect(listEquals(actual, expected), isTrue);
      final help = tester.getRect(_key(_help));
      final before = owner.latest.model;
      await _capture(tester, '06-halo-collapsed');
      await _press(tester, _restore);
      await _expectActions(tester);
      _expectCardContents(tester);
      _expectReadableHiddenText(tester);
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: _key('concept_account_action_scroll'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroll.position.maxScrollExtent, 0);
      expect(tester.getRect(_key(_help)), help);
      await _capture(tester, '07-halo-expanded');
      await _press(tester, _cancel);
      _expectOnlySara(tester);
      expect(_key(_view), findsNothing);
      expect(_key(_confirm), findsNothing);
      expect(_key(_cancel), findsNothing);
      expect(_key(_photo), findsOneWidget);
      expect(tester.getRect(_key(_help)), help);
      _expectNonHideStateUnchanged(before, owner.latest.model);
      expect(owner.latest.model.hiddenPeers, {_sara});
      await _capture(tester, '08-halo-cancelled');
    },
  );

  testWidgets(
    'Compact halo list scrolls at 200 percent while Help stays fixed',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3);
      for (final person in draftProfiles) {
        expect(model.hide(person.id), isTrue);
      }
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(model: model, hiddenPage: true),
        compact: true,
      );
      final before = owner.latest.model;
      final help = tester.getRect(_key(_help));
      await _press(tester, _restore);
      await _expectActions(tester);
      _expectCardContents(tester);
      _expectReadableHiddenText(tester);
      _expectPinnedHelp(tester);
      expect(tester.getRect(_key(_help)), help);
      await _capture(tester, '09-halo-compact-expanded');
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: _key('concept_account_action_scroll'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      _expectPinnedHelp(tester);
      expect(tester.getRect(_key(_help)), help);
      expect(scroll.position.pixels, scroll.position.maxScrollExtent);
      await _capture(tester, '10-halo-compact-scrolled');
      _expectNonHideStateUnchanged(before, owner.latest.model);
      expect(owner.latest.model.hiddenPeers, before.hiddenPeers);
    },
  );

  for (final compact in [false, true]) {
    testWidgets(
      'Missing-photo long-name halo fits ${compact ? 'compact200' : 'standard'} dark and attention styles',
      (tester) async {
        final owner = _Owner();
        await owner.mount(
          tester,
          checkpoint: _seed(hiddenPage: true),
          compact: compact,
        );
        final data = _overview(tester).data;
        const person = ZyraConceptHiddenProfile(
          id: _sara,
          name: 'Abdullah Muhammad Abdul Rahman Ibrahim Khan',
          detail: '37 · Newcastle upon Tyne',
        );
        for (final white in [false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              key: UniqueKey(),
              theme: ThemeData.dark(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(top: 59, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                  textScaler: TextScaler.linear(compact ? 2 : 1),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: RepaintBoundary(
                key: _captureRoot,
                child: ZyraFounderLaunchPageStyle(
                  pending: white
                      ? const {ZyraFounderLaunchRequirement.terms}
                      : const {},
                  child: ZyraConceptSettingsOverview(
                    action: ZyraConceptAccountAction.hiddenProfiles,
                    data: data,
                    hiddenProfiles: const [person],
                    confirmingHiddenProfileId: _sara,
                    onOpenDetail: (_) {},
                    onHelp: () {},
                    onUnhide: (_) {},
                    onViewHiddenProfile: () {},
                    onCancelUnhide: () {},
                    onConfirmUnhide: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // A very long 200% header can exceed the viewport. Reveal its
          // actual photo/fallback target, not the off-screen header centre.
          await _reveal(tester, _avatar);
          expect(_key(_photo), findsNothing);
          expect(_key(_placeholder), findsOneWidget);
          expect(
            find.descendant(of: _key(_avatar), matching: find.byType(Image)),
            findsNothing,
          );
          expect(find.text(person.name), findsOneWidget);
          await _expectActions(tester);
          _expectCardContents(tester);
          _expectReadableHiddenText(tester);
          _expectPinnedHelp(tester);
          if (compact) {
            for (final element in find.byType(Text).evaluate()) {
              final object = element.findRenderObject();
              if (object is RenderParagraph && object.hasSize) {
                expect(object.size.width, lessThanOrEqualTo(320));
              }
            }
          }
          await _capture(
            tester,
            '11-halo-long-${compact ? 'compact' : 'standard'}-${white ? 'attention' : 'dark'}',
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('View profile inspects without unhiding or changing requests', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.request(_sara), isTrue);
    expect(model.save(_sara), isTrue);
    expect(model.hide(_sara), isTrue);
    final owner = _Owner();
    expect(owner.access.unlock(_sara), isTrue);
    final unlocked = owner.access.resultFor(_sara);
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    final before = owner.latest.model;
    await _press(tester, _restore);
    await _expectActions(tester);
    await _press(tester, _view);
    expect(find.byType(ZyraConceptSettingsOverview), findsNothing);
    final presentation = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    final profile = presentation.profiles.single;
    expect(profile.id, _sara);
    expect(presentation.showFeedChrome, isFalse);
    expect(presentation.showSave, isFalse);
    expect(presentation.onRequest, isNull);
    expect(presentation.onBrowseMenu, isNull);
    expect(presentation.onPrevious, isNull);
    expect(presentation.onNext, isNull);
    expect(_key('concept_hidden_inspection_unhide'), findsOneWidget);
    expect(_key('concept_hidden_inspection_block'), findsOneWidget);
    expect(find.text('Unhide profile'), findsOneWidget);
    expect(find.text('Block profile'), findsOneWidget);
    expect(find.text('Nationality'), findsOneWidget);
    expect(find.text('Ethnicity'), findsOneWidget);
    expect(profile.publicNationality, isNotEmpty);
    expect(profile.publicEthnicity, isNotEmpty);
    expect(_key('concept_browse_footer'), findsNothing);
    expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
    expect(_key('draft_request'), findsNothing);
    expect(_key('draft_safety'), findsNothing);
    expect(find.text('Request a Journey'), findsNothing);
    final inspected = owner.latest;
    expect(owner.latest, same(inspected));
    expect(owner.latest.pages, ['settings', 'account_action', 'profile']);
    expect(owner.latest.model.hiddenPeers, {_sara});
    _expectNonHideStateUnchanged(before, owner.latest.model);
    expect(owner.access.balance, 0);
    expect(owner.access.resultFor(_sara), same(unlocked));

    expect(profile.photos.length, greaterThan(1));
    await _capture(tester, '16-hidden-current-details');
    final photo = _key('concept_browse_photo_swipe_$_sara');
    final bounds = tester.getRect(photo);
    await tester.tapAt(Offset(bounds.right - 20, bounds.center.dy));
    await tester.pumpAndSettle();
    expect(owner.latest.galleryIndices[_sara], 1);
    expect(owner.latest.photoIndices[_sara], 0);
    expect(find.text('Nationality'), findsNothing);
    await tester.tapAt(Offset(bounds.right - 20, bounds.center.dy));
    await tester.pumpAndSettle();
    expect(owner.latest.photoIndices[_sara], 1);
    for (final element in find.byType(Image).evaluate()) {
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
    await _capture(tester, '04-hidden-profile');
    await _back(tester);
    _expectOnlySara(tester);
    expect(_overview(tester).confirmingHiddenProfileId, isNull);
    expect(_key(_view), findsNothing);
    expect(owner.latest.pages, ['settings', 'account_action']);
    expect(owner.latest.model.hiddenPeers, {_sara});
    _expectNonHideStateUnchanged(before, owner.latest.model);
    expect(owner.access.resultFor(_sara), same(unlocked));
  });

  testWidgets('current hidden card Unhide changes only hide and returns once', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)
      ..request(_sara)
      ..save(_sara)
      ..hide(_sara);
    final owner = _Owner();
    expect(owner.access.unlock(_sara), isTrue);
    final entitlement = owner.access.resultFor(_sara);
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    final before = owner.latest.model;
    await _press(tester, _restore);
    await _press(tester, _view);
    final retained = tester
        .widget<OutlinedButton>(_key('concept_hidden_inspection_unhide'))
        .onPressed!;
    await _press(tester, 'concept_hidden_inspection_unhide');
    expect(owner.latest.pages, ['settings', 'account_action']);
    expect(owner.latest.model.hiddenPeers, isEmpty);
    _expectNonHideStateUnchanged(before, owner.latest.model);
    _expectPinnedHelp(tester);
    final returned = owner.latest;
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest, same(returned));
    expect(owner.access.resultFor(_sara), same(entitlement));
  });

  testWidgets('hidden card Block needs explicit confirmation and can cancel', (
    tester,
  ) async {
    final owner = _Owner();
    final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    await _press(tester, _restore);
    await _press(tester, _view);
    final before = owner.latest.model;
    await _press(tester, 'concept_hidden_inspection_block');
    expect(owner.latest.model.hiddenPeers, {_sara});
    _expectNonHideStateUnchanged(before, owner.latest.model);
    expect(find.text('Block Sara?'), findsOneWidget);
    final staleConfirm = tester
        .widget<OutlinedButton>(_key('concept_hidden_inspection_confirm_block'))
        .onPressed!;
    await _capture(tester, '17-hidden-current-block-confirm');
    await _press(tester, 'concept_hidden_inspection_cancel');
    staleConfirm();
    await tester.pumpAndSettle();
    _expectNonHideStateUnchanged(before, owner.latest.model);
    expect(_key('concept_hidden_inspection_unhide'), findsOneWidget);
    await _press(tester, 'concept_hidden_inspection_block');
    await _back(tester);
    expect(owner.latest.pages, ['settings', 'account_action', 'profile']);
    expect(_key('concept_hidden_inspection_unhide'), findsOneWidget);
    await _back(tester);
    expect(owner.latest.pages, ['settings', 'account_action']);
    _expectOnlySara(tester);
  });

  testWidgets('confirmed hidden-card Block does not unhide or restore a pair', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)
      ..request(_sara)
      ..save(_sara)
      ..hide(_sara);
    final owner = _Owner();
    expect(owner.access.unlock(_sara), isTrue);
    final entitlement = owner.access.resultFor(_sara);
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    final before = owner.latest.model;
    await _press(tester, _restore);
    await _press(tester, _view);
    await _press(tester, 'concept_hidden_inspection_block');
    final confirm = tester
        .widget<OutlinedButton>(_key('concept_hidden_inspection_confirm_block'))
        .onPressed!;
    await _press(tester, 'concept_hidden_inspection_confirm_block');
    expect(owner.latest.pages, ['settings', 'account_action']);
    expect(owner.latest.model.hiddenPeers, {_sara});
    expect(owner.latest.model.blockedPeers, {_sara});
    expect(owner.latest.model.states, before.states);
    expect(owner.latest.model.saved, before.saved);
    expect(owner.latest.model.capacity, before.capacity);
    expect(owner.latest.model.progress, before.progress);
    expect(owner.latest.model.guardianAccess, before.guardianAccess);
    expect(owner.latest.model.endedAttempts, before.endedAttempts);
    expect(owner.access.resultFor(_sara), same(entitlement));
    final returned = owner.latest;
    confirm();
    await tester.pumpAndSettle();
    expect(owner.latest, same(returned));
    await _press(tester, _restore);
    expect(_overview(tester).onViewHiddenProfile, isNull);
    expect(_key(_placeholder), findsOneWidget);
    _expectPinnedHelp(tester);
  });

  for (final action in ['unhide', 'block', 'confirm_block']) {
    for (final departure in [
      'Back',
      'controls',
      'cover',
      'role',
      'revocation',
      'disposal',
    ]) {
      testWidgets('retained hidden-card $action refuses after $departure', (
        tester,
      ) async {
        final owner = _Owner();
        final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
        await owner.mount(
          tester,
          checkpoint: _seed(model: model, hiddenPage: true),
        );
        await _press(tester, _restore);
        await _press(tester, _view);
        if (action == 'confirm_block') {
          await _press(tester, 'concept_hidden_inspection_block');
        }
        final retained = tester
            .widget<OutlinedButton>(_key('concept_hidden_inspection_$action'))
            .onPressed!;
        switch (departure) {
          case 'Back':
            await _back(tester);
          case 'controls':
            await openZyraDevControls(tester);
            retained();
            await tester.pump();
            await closeZyraDevControls(tester);
          case 'cover':
            unawaited(
              owner.navigator.currentState!.push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Unrelated cover')),
                ),
              ),
            );
            await tester.pumpAndSettle();
            retained();
            await tester.pumpAndSettle();
            expect(find.text('Unrelated cover'), findsOneWidget);
            owner.navigator.currentState!.pop();
            await tester.pumpAndSettle();
          case 'role':
            for (
              var returns = 0;
              returns < 5 && owner.latest.pages.isNotEmpty;
              returns++
            ) {
              await _back(tester);
            }
            expect(owner.latest.pages, isEmpty);
            expect(
              await pressZyraDevControlKey(tester, 'draft_role_guardian'),
              isTrue,
            );
          case 'revocation':
            owner.allowed = false;
          case 'disposal':
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
        }
        final latest = owner.latest;
        retained();
        await tester.pumpAndSettle();
        expect(owner.latest, same(latest));
        expect(owner.latest.model.hiddenPeers, {_sara});
        expect(owner.latest.model.blockedPeers, isEmpty);
        // Revocation changes a plain test getter without notifying a repaint.
        // Its retained commit must refuse (above), not invent a UI update.
        if (departure != 'revocation') {
          expect(_key('concept_hidden_inspection_block_prompt'), findsNothing);
        }
      });
    }
  }

  testWidgets(
    'compact enlarged hidden inspection keeps both actions readable',
    (tester) async {
      final owner = _Owner();
      final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
      await owner.mount(
        tester,
        checkpoint: _seed(model: model, hiddenPage: true),
        compact: true,
      );
      await _press(tester, _restore);
      await _press(tester, _view);
      for (final action in ['unhide', 'block']) {
        final target = _key('concept_hidden_inspection_$action');
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      }
      expect(_key('concept_browse_footer'), findsNothing);
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      await _capture(tester, '18-hidden-current-compact200');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a blocked hidden row cannot open View or remove its block', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)
      ..hide(_sara)
      ..block(_sara);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    final before = owner.latest.model;
    await _press(tester, _restore);
    await _expectActions(tester);
    expect(_overview(tester).hiddenProfiles!.single.thumbnail, isNull);
    expect(_key(_placeholder), findsOneWidget);
    expect(_key(_photo), findsNothing);
    expect(
      find.descendant(of: _key(_avatar), matching: find.byType(Image)),
      findsNothing,
    );
    _expectCardContents(tester);
    _expectPinnedHelp(tester);
    await _capture(tester, '12-halo-blocked');
    expect(_overview(tester).onViewHiddenProfile, isNull);
    expect(tester.widget<OutlinedButton>(_key(_view)).onPressed, isNull);
    final checkpoint = owner.latest;
    await tester.tap(_key(_view));
    await tester.pumpAndSettle();
    expect(owner.latest, same(checkpoint));
    expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
    expect(owner.latest.model.hiddenPeers, {_sara});
    await _press(tester, _confirm);
    expect(owner.latest.model.hiddenPeers, isEmpty);
    expect(owner.latest.model.blockedPeers, {_sara});
    _expectNonHideStateUnchanged(before, owner.latest.model);
  });

  testWidgets('Hidden profiles Help opens searchable preview and returns', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    await _press(tester, _restore);
    final retained = _overview(tester).onViewHiddenProfile!;
    final before = owner.latest.model;
    await _press(tester, _help);
    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expect(_key('help-support-preview-title'), findsOneWidget);
    expect(find.textContaining('support@'), findsNothing);
    expect(find.textContaining('Contact support by email'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Journey');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Journey',
    );
    final helpCheckpoint = owner.latest;
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest, same(helpCheckpoint));
    expect(find.byType(HelpSupportScreen), findsOneWidget);
    await _back(tester);
    _expectOnlySara(tester);
    expect(_overview(tester).confirmingHiddenProfileId, isNull);
    final returned = owner.latest;
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest, same(returned));
    expect(owner.latest.pages, ['settings', 'account_action']);
    expect(owner.latest.model.hiddenPeers, {_sara});
    _expectNonHideStateUnchanged(before, owner.latest.model);
  });

  for (final departure in [
    'Back',
    'controls',
    'role',
    'revocation',
    'disposal',
  ]) {
    testWidgets('a retained View choice refuses after $departure', (
      tester,
    ) async {
      final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(model: model, hiddenPage: true),
      );
      await _press(tester, _restore);
      final retained = _overview(tester).onViewHiddenProfile!;
      switch (departure) {
        case 'Back':
          await _back(tester);
        case 'controls':
          await openZyraDevControls(tester);
          retained();
          await tester.pump();
          expect(_key('dev_controls_page'), findsOneWidget);
          await closeZyraDevControls(tester);
        case 'role':
          // Role Switch belongs to Profile, not Hidden page options. Keep
          // this menu's old View callback across the real parent returns,
          // then use both existing coverage-review/role-confirmation taps.
          await _back(tester);
          await _back(tester);
          expect(owner.latest.pages, isEmpty);
          expect(owner.latest.tab, 4);
          expect(owner.latest.guardian, isFalse);
          expect(_key('concept_profile_title'), findsOneWidget);
          expect(
            await pressZyraDevControlKey(tester, 'draft_role_guardian'),
            isTrue,
          );
          expect(owner.latest.guardian, isTrue);
        case 'revocation':
          owner.allowed = false;
        case 'disposal':
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
      }
      final checkpoint = owner.latest;
      retained();
      await tester.pumpAndSettle();
      expect(owner.latest, same(checkpoint));
      expect(owner.latest.model.hiddenPeers, {_sara});
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      if (departure == 'Back') {
        await _press(tester, 'concept_settings_hiddenProfiles');
        retained();
        await tester.pumpAndSettle();
        _expectOnlySara(tester);
        expect(_overview(tester).confirmingHiddenProfileId, isNull);
      }
    });
  }

  testWidgets('covered-and-returned View cannot regain its old menu lease', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    await _press(tester, _restore);
    final retained = _overview(tester).onViewHiddenProfile!;
    unawaited(
      owner.navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Unrelated cover')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final covered = owner.latest;
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest, same(covered));
    expect(find.text('Unrelated cover'), findsOneWidget);
    owner.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    final returned = owner.latest;
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest, same(returned));
    _expectOnlySara(tester);
    expect(_overview(tester).confirmingHiddenProfileId, isNull);
    expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
    expect(owner.latest.model.hiddenPeers, {_sara});
  });

  testWidgets(
    'unknown row IDs and a retained control-epoch row cannot restore',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(model: model, hiddenPage: true),
      );
      final retained = _overview(tester).onUnhide!;
      retained(_aisha);
      retained('not-a-fixture');
      await tester.pumpAndSettle();
      expect(owner.latest.model.hiddenPeers, {_sara});
      expect(_overview(tester).confirmingHiddenProfileId, isNull);
      await openZyraDevControls(tester);
      retained(_sara);
      await tester.pump();
      expect(owner.latest.model.hiddenPeers, {_sara});
      await closeZyraDevControls(tester);
      retained(_sara);
      await tester.pumpAndSettle();
      expect(_overview(tester).confirmingHiddenProfileId, isNull);
      expect(owner.latest.model.hiddenPeers, {_sara});
    },
  );

  testWidgets('a confirmation retained after leaving Settings cannot restore', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    await _press(tester, _restore);
    final retained = _overview(tester).onConfirmUnhide!;
    await _back(tester);
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest.model.hiddenPeers, {_sara});
    await _press(tester, 'concept_settings_hiddenProfiles');
    _expectOnlySara(tester);
    expect(_overview(tester).confirmingHiddenProfileId, isNull);
  });

  testWidgets('covered-and-returned confirmation cannot regain authority', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    await _press(tester, _restore);
    final retained = _overview(tester).onConfirmUnhide!;
    unawaited(
      owner.navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Unrelated cover')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest.model.hiddenPeers, {_sara});
    owner.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest.model.hiddenPeers, {_sara});
    expect(_overview(tester).confirmingHiddenProfileId, isNull);
  });

  testWidgets('revoked shell admission rejects a retained restoration', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: _seed(model: model, hiddenPage: true),
    );
    await _press(tester, _restore);
    final retained = _overview(tester).onConfirmUnhide!;
    final count = owner.checkpoints.length;
    owner.allowed = false;
    retained();
    await tester.pump();
    expect(owner.checkpoints.length, count);
    expect(owner.latest.model.hiddenPeers, {_sara});
  });

  testWidgets(
    'same-role checkpoint restores the list but not its confirmation',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(model: model, hiddenPage: true),
      );
      await _press(tester, _restore);
      final retained = _overview(tester).onConfirmUnhide!;
      final retainedView = _overview(tester).onViewHiddenProfile!;
      final checkpoint = owner.latest;
      await owner.mount(tester, checkpoint: checkpoint);
      _expectOnlySara(tester);
      expect(_overview(tester).confirmingHiddenProfileId, isNull);
      retained();
      retainedView();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(owner.latest.model.hiddenPeers, {_sara});
    },
  );

  testWidgets(
    'hidden list and three actions remain readable at 320px and 200 percent',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3)..hide(_sara);
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(model: model, hiddenPage: true),
        compact: true,
      );
      await _press(tester, _restore);
      await _expectActions(tester);
      await _reveal(tester, _view);
      expect(_key(_view).hitTestable(), findsOneWidget);
      await _reveal(tester, _confirm);
      expect(_key(_confirm).hitTestable(), findsOneWidget);
      await _capture(tester, '03-compact-actions');
      expect(tester.getSize(_key(_confirm)).height, greaterThanOrEqualTo(44));
      for (final element in find.byType(Text).evaluate()) {
        final text = element.widget as Text;
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        final object = element.findRenderObject();
        if (object is RenderParagraph && object.hasSize) {
          expect(object.didExceedMaxLines, isFalse);
          expect(object.size.width, lessThanOrEqualTo(320));
        }
      }
      expect(tester.takeException(), isNull);
      await _press(tester, _cancel);
      await _reveal(tester, _restore);
      _expectOnlySara(tester);
    },
  );
}
