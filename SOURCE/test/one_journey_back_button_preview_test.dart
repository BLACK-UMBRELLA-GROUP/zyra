// Detached developer-shell integration. All people and conversations are
// bundled draft data; no provider, account, purchase or member route is used.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_circle_discussion_archive.dart';
import 'package:zyra/dev/zyra_journey_peer_guardians_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart' show ZyraDevControlRail;

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsBackNavigationIntegration';
const _captures = String.fromEnvironment('ZYRA_BACK_NAV_CAPTURE_DIR');
const _captureKey = ValueKey('back-navigation-capture');
const _scopeKey = ValueKey('concept_pull_down_back_scope');
const _backKey = ValueKey('zyra_visible_back_button');

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Back-navigation preview must remain local and offline.');
  }
}

Future<void> _mount(
  WidgetTester tester, {
  bool guardian = false,
  bool protectedHost = false,
  bool prepareOwnPhotos = false,
  Size size = const Size(393, 852),
  double textScale = 1,
  bool Function()? canAct,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = ThemeData.dark();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: _font),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 44, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: protectedHost
          ? ViewRequestDraftScreen(
              ownerGeneration: ZyraAccountState.generation,
              ownerId: ZyraAccountState.userId,
              initialGuardianRole: guardian,
              onExit: () => fail('An in-app Back must not exit its owner.'),
            )
          : ZyraOneJourneyConceptShell(
              canAct: canAct ?? () => true,
              onExit: () => fail('An in-app Back must not exit the preview.'),
              initialGuardianRole: guardian,
            ),
    ),
  );
  await tester.pumpAndSettle();
  if (prepareOwnPhotos) {
    expect(guardian, isFalse);
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final browse = find.byType(ZyraOneJourneyBrowseDesigns);
        if (browse.evaluate().isNotEmpty) {
          final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(browse);
          if (deck.profiles.isNotEmpty &&
              deck.profiles.first.photos.isNotEmpty) {
            return;
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
      }
      fail('The bundled local own-profile photo did not prepare.');
    });
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

Future<void> _press(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    // The shell's settings/profile options are lazily built. Scroll the
    // existing page owner before asserting the actual tap target exists.
    final owner = [
      'dev_controls_scroll',
      'concept-current-profile-scroll',
      'concept-current-settings-scroll',
      'concept-current-membership-scroll',
      'draft_scroll',
    ].map(_key).firstWhere((finder) => finder.evaluate().isNotEmpty);
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find
          .descendant(of: owner, matching: find.byType(Scrollable))
          .first,
    );
  }
  expect(target, findsOneWidget);
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .4);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) => _press(tester, _key(key));

Future<void> _nav(WidgetTester tester, String label) async {
  final navigation = find.byType(ZyraShellNavigation);
  expect(navigation, findsOneWidget);
  final widget = tester.widget<ZyraShellNavigation>(navigation);
  final index = widget.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  final item = widget.items[index];
  final icon = find.descendant(
    of: navigation,
    matching: item.useJourneyGlyph
        ? find.byType(ZyraJourneyIcon)
        : find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  final bar = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(bar.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _openOptions(WidgetTester tester) async {
  await openZyraDevControls(tester);
  expect(find.text('Page options'), findsOneWidget);
  expect(find.text('Back navigation'), findsNothing);
}

Future<void> _back(WidgetTester tester) =>
    _key('dev_controls_close').evaluate().isNotEmpty
    ? closeZyraDevControls(tester)
    : _swipeBack(tester);

Future<void> _pull(WidgetTester tester) async {
  final scope = find.byKey(_scopeKey);
  expect(scope, findsOneWidget);
  final rect = tester.getRect(scope);
  await tester.timedDragFrom(
    Offset(rect.left + 30, rect.top + 65),
    const Offset(0, 230),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _swipeBack(WidgetTester tester) async {
  final edge = _key('zyra_back_swipe_edge');
  expect(edge, findsOneWidget);
  final rect = tester.getRect(edge);
  await tester.timedDragFrom(
    Offset(rect.left + 8, rect.top + rect.height * .35),
    const Offset(190, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _noBackButton() => expect(find.byKey(_backKey), findsNothing);

Future<void> _swipePager(
  WidgetTester tester,
  Finder pager, {
  required bool forward,
  Finder? gestureBand,
}) async {
  final rect = tester.getRect(pager);
  final y = gestureBand == null
      ? rect.center.dy
      : tester.getCenter(gestureBand).dy;
  expect(y, inExclusiveRange(rect.top, rect.bottom));
  await tester.timedDragFrom(
    Offset(rect.left + rect.width * (forward ? .8 : .2), y),
    Offset(rect.width * (forward ? -.6 : .6), 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectPagerPage(WidgetTester tester, Finder pager, int page) {
  expect(
    tester.widget<PageView>(pager).controller!.page,
    closeTo(page.toDouble(), .01),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  // Decode the actual mounted local providers before checking/capturing their
  // geometry. pumpAndSettle alone does not wait for native image decoding.
  for (final element
      in find
          .descendant(of: find.byKey(_captureKey), matching: find.byType(Image))
          .evaluate()
          .toList()) {
    final provider = (element.widget as Image).image;
    Object? decodeError;
    await tester.runAsync(
      () => precacheImage(
        provider,
        element,
        onError: (error, _) => decodeError = error,
      ).timeout(const Duration(seconds: 5)),
    );
    expect(decodeError, isNull);
  }
  await tester.pumpAndSettle();
  if (name.contains('full-photo') || name.contains('browse-preview')) {
    // Own preview and the Guardian's linked-profile presentation use different
    // readers. Require the real mounted portrait, not an assumed reader type.
    final portrait = find.descendant(
      of: find.byKey(_captureKey),
      matching: find.byType(Image),
    );
    expect(portrait, findsOneWidget);
    final photo = find.descendant(
      of: portrait,
      matching: find.byType(RawImage),
    );
    expect(photo, findsOneWidget);
    final decoded = tester.widget<RawImage>(photo).image;
    expect(decoded, isNotNull);
    expect(decoded!.width, greaterThan(0));
    expect(decoded.height, greaterThan(0));
  }
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;
  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  List<Object?> memberState() => [
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
  ];

  setUpAll(() async {
    if (_captures.isNotEmpty &&
        (!_captures.startsWith('/') ||
            FileSystemEntity.typeSync(_captures, followLinks: false) !=
                FileSystemEntityType.directory ||
            Directory(_captures).resolveSymbolicLinksSync() !=
                Directory(_captures).path)) {
      throw StateError(
        'Captures require an existing absolute nonlinked directory.',
      );
    }
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'back-navigation-sentinel': 'keep',
    });
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    beforePreferences = preferenceState();
    beforeMember = memberState();
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });

  tearDown(() {
    expect(network.attempts, 0);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMember);
    HttpOverrides.global = previousNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'Default and Reset keep swipe-only return without Back chrome or alternative controls',
    (tester) async {
      await _mount(tester);
      _noBackButton();
      await _openOptions(tester);

      expect(find.text('Back navigation'), findsNothing);
      expect(_key('dev_controls_close'), findsOneWidget);
      _noBackButton(); // Controls always have X, never a duplicate return.
      await _back(tester);
      expect(find.text('Page options'), findsNothing);
      _noBackButton(); // The root tab must never gain a faux Back.
      await _nav(tester, 'Profile');
      _noBackButton();
      await _tap(tester, 'concept_settings');
      expect(find.byKey(_backKey), findsNothing);
      await _pull(tester);
      expect(
        find.text('Settings'),
        findsWidgets,
      ); // A vertical drag does not activate the left-edge return.
      await _tap(tester, 'concept_settings_signInSecurity');
      expect(find.text('Sign-in & security'), findsOneWidget);
      expect(_key('concept_account_action_scroll'), findsOneWidget);
      await _back(tester);
      expect(_key('concept_account_action_scroll'), findsNothing);
      expect(_key('concept_settings_signInSecurity'), findsOneWidget);
      expect(find.text('Settings'), findsWidgets);
      await _capture(tester, '01-seeker-settings-back');
      await _back(tester);
      expect(find.byKey(_scopeKey), findsNothing);
      _noBackButton();
      await _openOptions(tester);

      expect(find.text('Back navigation'), findsNothing);
      await _tap(tester, 'draft_reset');
      await _openOptions(tester);

      expect(find.text('Back navigation'), findsNothing);
      _noBackButton();
      await tester.pumpWidget(const SizedBox.shrink());
      await _mount(tester);
      await _openOptions(tester);

      expect(find.text('Back navigation'), findsNothing);
    },
  );

  testWidgets('hidden hold opens once at three seconds and X only returns', (
    tester,
  ) async {
    await _mount(tester);
    expect(find.byType(ZyraDevControlRail), findsNothing);
    expect(_key('draft_back'), findsNothing);
    expect(_key('draft_close'), findsNothing);
    final surface = _key('dev_controls_hold_surface');
    final rect = tester.getRect(surface);
    final gesture = await tester.startGesture(
      Offset(rect.center.dx, rect.top + 52),
    );
    await tester.pump(const Duration(milliseconds: 2999));
    expect(_key('dev_controls_page'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(_key('dev_controls_page'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    final close = tester
        .widget<IconButton>(_key('dev_controls_close'))
        .onPressed!;
    final bounds = tester.getRect(_key('dev_controls_close'));
    expect(bounds.left, lessThan(24));
    expect(bounds.top, greaterThanOrEqualTo(44));
    _noBackButton();
    await _capture(tester, '09-hidden-page-options');
    await closeZyraDevControls(tester);
    expect(_key('dev_controls_page'), findsNothing);
    expect(find.byType(ZyraShellNavigation), findsOneWidget);
    await openZyraDevControls(tester);
    close(); // A retained X from the prior opening is inert after ABA.
    await tester.pumpAndSettle();
    expect(_key('dev_controls_page'), findsOneWidget);
    await closeZyraDevControls(tester);
    expect(find.byType(ZyraShellNavigation), findsOneWidget);
  });

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} default supports left-edge return without Back chrome or opting in',
      (tester) async {
        await _mount(tester, guardian: guardian);
        _noBackButton();
        expect(_key('zyra_back_swipe_edge'), findsNothing);
        await _nav(tester, 'Profile');
        await _tap(tester, 'concept_settings');
        expect(find.byKey(_backKey), findsNothing);
        expect(_key('zyra_back_swipe_edge'), findsOneWidget);
        await _tap(tester, 'concept_settings_signInSecurity');
        expect(_key('concept_account_action_scroll'), findsOneWidget);
        await _swipeBack(tester);
        expect(_key('concept_account_action_scroll'), findsNothing);
        expect(_key('concept_settings_signInSecurity'), findsOneWidget);
        await _back(tester);
        _noBackButton();
        expect(_key('zyra_back_swipe_edge'), findsNothing);
      },
    );
  }

  testWidgets(
    'default Circle edge swipe returns from archive then the same conversation with draft intact',
    (tester) async {
      await _mount(tester, guardian: true, protectedHost: true);
      await _nav(tester, 'Seekers');
      await _tap(tester, 'seeker-family-chat-draft-self');
      final circle = find.byType(ZyraGuardianCircleScreen);
      final state = tester.state(circle);
      final composer = find.descendant(
        of: _key('guardian-circle-composer'),
        matching: find.byType(TextField),
      );
      final controller = tester.widget<TextField>(composer).controller!;
      await _tap(tester, 'circle_discuss_floatingButton');
      await _tap(tester, 'circle_topic_tab_1');
      await _tap(tester, 'circle_topic_draft-circle-past-0');
      expect(
        _key('circle_pending_discussion_topic_draft-circle-past-0'),
        findsOneWidget,
      );
      expect(
        _key('circle_discussion_bubble_draft-circle-past-0'),
        findsNothing,
      );
      const sentBody = 'A sent discussion before viewing the Journey';
      await tester.enterText(composer, sentBody);
      await _press(tester, find.byTooltip('Send message'));
      expect(_key('circle_pending_discussion_topic'), findsNothing);
      expect(
        _key('circle_discussion_bubble_draft-circle-past-0'),
        findsOneWidget,
      );
      expect(find.text(sentBody), findsOneWidget);
      await tester.enterText(
        composer,
        'Keep this unsent while viewing the Journey',
      );
      await tester.pumpAndSettle();
      await _press(tester, find.text('View Journey'));
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsOneWidget);
      await _swipeBack(tester);
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
      expect(tester.state(circle), same(state));
      expect(tester.widget<TextField>(composer).controller, same(controller));
      expect(controller.text, 'Keep this unsent while viewing the Journey');
      await _swipeBack(tester);
      expect(circle, findsNothing);
      _noBackButton();
      expect(_key('seeker-family-chat-draft-self'), findsOneWidget);
    },
  );

  testWidgets(
    'holding unsupported Settings preserves the actual scroll state',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 'Profile');
      await _tap(tester, 'concept_settings');
      final scroll = find
          .descendant(
            of: _key('concept-current-settings-scroll'),
            matching: find.byType(Scrollable),
          )
          .first;
      final state = tester.state<ScrollableState>(scroll);
      state.position.jumpTo(90);
      await tester.pumpAndSettle();
      final offset = state.position.pixels;
      await openZyraDevControls(tester);
      expect(_key('dev_controls_page'), findsOneWidget);
      expect(find.byType(ZyraDevControlRail), findsNothing);
      await closeZyraDevControls(tester);
      expect(identical(tester.state<ScrollableState>(scroll), state), isTrue);
      expect(state.position.pixels, offset);
      expect(find.text('Settings'), findsWidgets);
      expect(_key('concept_settings_signInSecurity'), findsOneWidget);
    },
  );

  testWidgets('an unavailable preview cannot acquire controls by holding', (
    tester,
  ) async {
    var admitted = true;
    await _mount(tester, canAct: () => admitted);
    final rect = tester.getRect(_key('dev_controls_hold_surface'));
    final gesture = await tester.startGesture(
      Offset(rect.center.dx, rect.top + 52),
    );
    await tester.pump(const Duration(seconds: 2));
    admitted = false;
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_key('dev_controls_page'), findsNothing);
    expect(_key('dev_controls_close'), findsNothing);
    expect(find.byType(ZyraDevControlRail), findsNothing);
  });

  testWidgets(
    'Seeker own photo and retained editors use the same button; role changes preserve mode',
    (tester) async {
      await _mount(tester, prepareOwnPhotos: true);
      await _openOptions(tester);
      await _back(tester);
      await _nav(tester, 'Profile');
      await _tap(tester, 'concept_preview_profile');
      expect(find.byType(MyProfilePreviewScreen), findsOneWidget);
      expect(find.byType(SeekerProfileScreen), findsNothing);
      final card = tester.widget<ZyraBrowseDesigns>(
        find.byType(ZyraBrowseDesigns),
      );
      expect(card.readOnlyPreview, isTrue);
      expect(card.profiles.single.id, 'draft-self');
      expect(_key('concept_browse_footer'), findsOneWidget);
      for (final key in [
        'concept_previous_profile',
        'concept_next_profile',
        'draft_profile_draft-self',
      ]) {
        expect(tester.widget<InkWell>(_key(key)).onTap, isNull);
      }
      expect(find.text('Request a Journey'), findsOneWidget);
      for (final title in ['My profile', 'Browse', 'Profiles']) {
        expect(find.text(title), findsNothing);
      }
      expect(card.profiles.single.publicNationality, isNotNull);
      expect(card.profiles.single.publicEthnicity, isNotNull);
      final details = _key('concept_browse_details_draft-self');
      for (final value in [
        'Nationality',
        card.profiles.single.publicNationality!,
        'Ethnicity',
        card.profiles.single.publicEthnicity!,
      ]) {
        expect(
          find.descendant(of: details, matching: find.text(value)),
          findsOneWidget,
        );
      }
      expect(
        tester
            .widget<IgnorePointer>(_key('own-profile-preview-inert-navigation'))
            .ignoring,
        isTrue,
      );
      expect(find.byKey(_backKey), findsNothing);
      // The capture keeps exercising an actual own photograph, now reached
      // after the public details page rather than mounted on first paint.
      await tester.drag(
        _key('concept_browse_photo_swipe_draft-self'),
        const Offset(-240, 0),
      );
      await tester.pumpAndSettle();
      await _capture(tester, '02-seeker-browse-preview-back');
      await _back(tester);
      expect(find.byType(MyProfilePreviewScreen), findsNothing);
      await _tap(tester, 'concept_edit_profile');
      expect(find.byKey(_backKey), findsNothing);
      await _capture(tester, '03-seeker-edit-profile-back');
      await _tap(tester, 'compatibility-editor-aboutYou');
      expect(find.byKey(_backKey), findsNothing);
      await _back(tester);
      expect(_key('compatibility-editor-aboutYou'), findsOneWidget);
      await _back(tester);
      expect(find.byKey(_scopeKey), findsNothing);
      await _openOptions(tester);
      await _tap(tester, 'draft_role_guardian');
      _noBackButton();
      await _openOptions(tester);

      expect(find.text('Back navigation'), findsNothing);
      await _back(tester);
      await _tap(tester, 'guardian-dashboard-view-profile-draft-self');
      expect(find.byKey(_backKey), findsNothing);
      await _capture(tester, '04-guardian-full-photo-back');
      await _back(tester);
      expect(
        _key('guardian-dashboard-view-profile-draft-self'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Circle preserves unsent composer text through controls and Back closes options first',
    (tester) async {
      await _mount(tester, guardian: true, protectedHost: true);
      await _openOptions(tester);
      await _back(tester);
      await _nav(tester, 'Seekers');
      await _tap(tester, 'seeker-family-chat-draft-self');
      expect(find.byType(ZyraGuardianCircleScreen), findsOneWidget);
      expect(find.byKey(_backKey), findsNothing);
      await _capture(tester, '05-guardian-circle-back');
      final composer = find.descendant(
        of: _key('guardian-circle-composer'),
        matching: find.byType(TextField),
      );
      expect(composer, findsOneWidget);
      await tester.enterText(composer, 'Unsent local draft');
      await tester.pumpAndSettle();
      await _openOptions(tester);
      expect(_key('dev_controls_close'), findsOneWidget);
      _noBackButton();
      _noBackButton();
      await _back(tester);
      expect(find.byType(ZyraGuardianCircleScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(composer).controller!.text,
        'Unsent local draft',
      );
      await _pull(tester);
      expect(find.byType(ZyraGuardianCircleScreen), findsOneWidget);
      await _back(tester);
      expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
      _noBackButton();
    },
  );

  testWidgets(
    'Circle Back returns from its nested archive then from the same conversation',
    (tester) async {
      await _mount(tester, guardian: true, protectedHost: true);
      await _openOptions(tester);
      await _back(tester);
      await _nav(tester, 'Seekers');
      await _tap(tester, 'seeker-family-chat-draft-self');
      final circle = find.byType(ZyraGuardianCircleScreen);
      final state = tester.state(circle);
      final composer = find.descendant(
        of: _key('guardian-circle-composer'),
        matching: find.byType(TextField),
      );
      final controller = tester.widget<TextField>(composer).controller!;
      await _tap(tester, 'circle_discuss_floatingButton');
      await _tap(tester, 'circle_topic_tab_1');
      await _tap(tester, 'circle_topic_draft-circle-past-0');
      expect(
        _key('circle_pending_discussion_topic_draft-circle-past-0'),
        findsOneWidget,
      );
      expect(
        _key('circle_discussion_bubble_draft-circle-past-0'),
        findsNothing,
      );
      const sentBody = 'A sent discussion before opening the archive';
      await tester.enterText(composer, sentBody);
      await _press(tester, find.byTooltip('Send message'));
      expect(_key('circle_pending_discussion_topic'), findsNothing);
      expect(
        _key('circle_discussion_bubble_draft-circle-past-0'),
        findsOneWidget,
      );
      expect(find.text(sentBody), findsOneWidget);
      await tester.enterText(composer, 'Retain this draft through the archive');
      await tester.pumpAndSettle();
      await _press(tester, find.text('View Journey'));
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsOneWidget);
      expect(find.byKey(_backKey), findsNothing);
      final retained = captureZyraAccessibleBack(tester);
      await _swipeBack(tester);
      retained(); // A repeat before the parent rebind must not close Circle.
      await tester.pumpAndSettle();
      expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
      expect(tester.state(circle), same(state));
      expect(tester.widget<TextField>(composer).controller, same(controller));
      expect(controller.text, 'Retain this draft through the archive');
      retained(); // The old child's action also stays inert after rebinding.
      await tester.pumpAndSettle();
      expect(tester.state(circle), same(state));
      await _back(tester);
      expect(circle, findsNothing);
      _noBackButton();
    },
  );

  testWidgets(
    'Default Back preserves Manage Photos center paging to its virtual Add page and edge returns only the editor',
    (tester) async {
      await _mount(tester, protectedHost: true, prepareOwnPhotos: true);
      final nativeCalls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final channel in const [
        MethodChannel('plugins.flutter.io/image_picker'),
        MethodChannel('app.zyraconnect.zyra/profile_photo'),
      ]) {
        messenger.setMockMethodCallHandler(channel, (call) async {
          nativeCalls.add('${channel.name}:${call.method}');
          throw PlatformException(code: 'unexpected-photo-action');
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      }
      await _nav(tester, 'Profile');
      await _tap(tester, 'concept_manage_photos');
      final editor = find.byType(EditPhotosScreen);
      final pager = _key('photos-page-view');
      expect(editor, findsOneWidget);
      expect(find.byKey(_backKey), findsNothing);
      expect(
        tester.widget<PageView>(pager).childrenDelegate.estimatedChildCount,
        2,
      );
      _expectPagerPage(tester, pager, 0);
      await _swipePager(tester, pager, forward: true);
      _expectPagerPage(tester, pager, 1);
      expect(_key('photos-add-page-action').hitTestable(), findsOneWidget);
      expect(editor, findsOneWidget);
      await _swipePager(tester, pager, forward: false);
      _expectPagerPage(tester, pager, 0);
      await _swipePager(tester, pager, forward: true);
      _expectPagerPage(tester, pager, 1);
      await _swipeBack(tester);
      expect(editor, findsNothing);
      expect(_key('concept_manage_photos'), findsOneWidget);
      _noBackButton();
      await _tap(tester, 'concept_manage_photos');
      expect(
        tester.widget<PageView>(pager).childrenDelegate.estimatedChildCount,
        2,
      );
      _expectPagerPage(tester, pager, 0);
      expect(nativeCalls, isEmpty);
      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  testWidgets(
    'Own Guardian root retains both center swipe directions without a faux Back and Circle edge returns to the same roster',
    (tester) async {
      await _mount(tester, protectedHost: true);
      await _nav(tester, 'Guardian');
      final root = find.byType(SeekerGuardianPage);
      final pager = _key('guardian-page-view');
      List<Object?> roster() => tester
          .widget<SeekerGuardianPage>(root)
          .people
          .map(
            (person) => (
              person.id,
              person.firstName,
              person.relationship,
              person.isMain,
            ),
          )
          .toList();
      final before = roster();
      expect(before, hasLength(2));
      final people = tester.widget<SeekerGuardianPage>(root).people;
      final names = [
        ...people.where((person) => person.isMain),
        ...people.where((person) => !person.isMain),
      ].map((person) => person.firstName).toList();
      Finder identityBand(int index) => find
          .descendant(of: pager, matching: find.text(names[index]))
          .hitTestable();
      _noBackButton();
      expect(_key('zyra_back_swipe_edge'), findsNothing);
      // Swipe the measured identity row, not a View/Chat switch whose bounds
      // can move when the permission header becomes more readable.
      await _swipePager(
        tester,
        pager,
        forward: true,
        gestureBand: identityBand(0),
      );
      _expectPagerPage(tester, pager, 1);
      await _swipePager(
        tester,
        pager,
        forward: false,
        gestureBand: identityBand(1),
      );
      _expectPagerPage(tester, pager, 0);
      await _swipePager(
        tester,
        pager,
        forward: true,
        gestureBand: identityBand(0),
      );
      final rect = tester.getRect(pager);
      await tester.timedDragFrom(
        Offset(8, rect.center.dy),
        const Offset(220, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(root, findsOneWidget);
      _noBackButton();
      expect(_key('zyra_back_swipe_edge'), findsNothing);
      expect(roster(), before);
      await _tap(tester, 'guardian-family-messages-top');
      expect(find.byType(ZyraGuardianCircleScreen), findsOneWidget);
      await _swipeBack(tester);
      expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
      expect(root, findsOneWidget);
      expect(roster(), before);
      _noBackButton();
      expect(_key('zyra_back_swipe_edge'), findsNothing);
    },
  );

  testWidgets(
    'Journey peer Guardian pager keeps center swipes and edge returns only to the selected Journey without changing its read-only roster',
    (tester) async {
      await _mount(tester, protectedHost: true, prepareOwnPhotos: true);
      await _nav(tester, 'Journey');
      await _openOptions(tester);
      await _tap(tester, 'concept_journey_preview_3');
      await _tap(tester, 'draft_journey_options_draft-sara');
      await _tap(tester, 'draft_options_guardians_draft-sara');
      final peer = find.byType(ZyraJourneyPeerGuardiansPresentation);
      final pager = _key('peer_guardians_pager_draft-sara');
      List<Object?> roster() => tester
          .widget<ZyraJourneyPeerGuardiansPresentation>(peer)
          .guardians!
          .map(
            (person) => (person.firstName, person.relationship, person.isMain),
          )
          .toList();
      final before = roster();
      expect(before, hasLength(3));
      expect(find.byType(SeekerGuardianPage), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.byKey(_backKey), findsNothing);
      await _swipePager(tester, pager, forward: true);
      _expectPagerPage(tester, pager, 1);
      await _swipePager(tester, pager, forward: false);
      _expectPagerPage(tester, pager, 0);
      expect(roster(), before);
      await _swipeBack(tester);
      expect(peer, findsNothing);
      expect(_key('draft_journey_options_draft-sara'), findsOneWidget);
      _noBackButton();
      expect(_key('zyra_back_swipe_edge'), findsNothing);
      await _tap(tester, 'draft_journey_options_draft-sara');
      await _tap(tester, 'draft_options_guardians_draft-sara');
      expect(roster(), before);
      _expectPagerPage(tester, pager, 0);
      expect(find.byType(Switch), findsNothing);
    },
  );

  testWidgets(
    'Compact 2x Circle and Settings retain edge return without Back chrome or clipped controls',
    (tester) async {
      await _mount(
        tester,
        guardian: true,
        protectedHost: true,
        size: const Size(320, 568),
        textScale: 2,
      );
      await _openOptions(tester);
      await _capture(tester, '10-hidden-page-options-compact');
      await _back(tester);
      await _nav(tester, 'Seekers');
      await _tap(tester, 'seeker-family-chat-draft-self');
      expect(find.byKey(_backKey), findsNothing);
      await _capture(tester, '06-guardian-circle-compact-back');
      final composer = find.descendant(
        of: _key('guardian-circle-composer'),
        matching: find.byType(TextField),
      );
      expect(composer, findsOneWidget);
      await tester.showKeyboard(composer);
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(
        composer,
        List.filled(20, 'An unsent multi-line Circle message.').join('\n'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_backKey), findsNothing);
      final send = find.descendant(
        of: _key('guardian-circle-composer'),
        matching: find.byTooltip('Send message'),
      );
      expect(send.hitTestable(), findsOneWidget);
      expect(
        _key('circle_discuss_floatingButton').hitTestable(),
        findsOneWidget,
      );
      expect(_key('circle_back_compact_discuss'), findsNothing);
      expect(_key('circle_topic_bar'), findsNothing);
      final editable = tester
          .state<EditableTextState>(
            find.descendant(of: composer, matching: find.byType(EditableText)),
          )
          .renderEditable;
      expect(
        editable.size.height,
        greaterThanOrEqualTo(editable.preferredLineHeight),
      );
      await _capture(tester, '08-guardian-circle-compact-keyboard-back');
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await _back(tester);
      await _nav(tester, 'Profile');
      await _tap(tester, 'concept_settings');
      expect(find.byKey(_backKey), findsNothing);
      await _capture(tester, '07-guardian-settings-compact-back');
      await _back(tester);
      _noBackButton();
      expect(tester.takeException(), isNull);
    },
  );
}
