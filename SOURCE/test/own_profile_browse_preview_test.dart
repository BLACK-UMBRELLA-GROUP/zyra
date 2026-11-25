// Detached public-widget fixtures for the shared own-profile Browse card.
// No provider, member repository, decision, purchase or photo picker is used.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_invitation_outline.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsOwnBrowsePreview';
const _captures = String.fromEnvironment('ZYRA_OWN_BROWSE_CAPTURE_DIR');
const _captureKey = ValueKey('own-browse-preview-capture');
const _scopeKey = ValueKey('concept_pull_down_back_scope');
const _backKey = ValueKey('zyra_visible_back_button');
const _edgeKey = ValueKey('zyra_back_swipe_edge');
const _inertNavigationKey = ValueKey('own-profile-preview-inert-navigation');

Finder _key(String value) => find.byKey(ValueKey(value));

String _photo(int colour) {
  final photo = img.Image(width: 30, height: 40);
  img.fill(photo, color: img.ColorRgb8(colour, 70, 110));
  return 'data:image/png;base64,${base64Encode(img.encodePng(photo))}';
}

SeekerProfile _profile({
  bool longIdentity = false,
  bool publicHeritage = true,
}) => SeekerProfile(
  id: 'own-preview-person',
  firstName: longIdentity ? 'Amina Mariam' : 'Amina',
  surnameLine: longIdentity ? 'Rahman Hussain' : 'Rahman',
  age: 29,
  city: 'Birmingham',
  gender: 'female',
  photos: [_photo(90), _photo(150)],
  publicNationality: publicHeritage ? 'British' : null,
  publicEthnicity: publicHeritage ? 'South Asian' : null,
);

Widget _renderPhoto(
  BuildContext context,
  String photo, {
  required double width,
  required double height,
  required Alignment alignment,
}) =>
    ZyraProfileImage(photo, width: width, height: height, alignment: alignment);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Own-profile display fixtures must remain offline.');
  }
}

class _Owner extends ChangeNotifier {
  _Owner(this.profile);

  final SeekerProfile profile;
  bool shown = true;
  bool allowed = true;
  bool throwsGuard = false;
  int returns = 0;
  // Preserve exact callback identity across owner rebuilds, as the real host does.
  // ignore: prefer_function_declarations_over_variables
  late final bool Function() guard = () {
    if (throwsGuard) throw StateError('Synthetic withdrawn owner');
    return allowed;
  };
  // ignore: prefer_function_declarations_over_variables
  late final VoidCallback back = () {
    returns++;
    shown = false;
    notifyListeners();
  };

  void rebuild() => notifyListeners();
}

Widget _owned(_Owner owner) => ZyraBackNavigationPreview(
  revision: 0,
  child: AnimatedBuilder(
    animation: owner,
    builder: (_, _) => owner.shown
        ? MyProfilePreviewScreen.preview(
            key: const ValueKey('local-own-preview-owner'),
            profile: owner.profile,
            canAct: owner.guard,
            onBack: owner.back,
            hapticLevel: ZyraHapticLevel.off,
          )
        : const Scaffold(body: Center(child: Text('Own profile parent'))),
  ),
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 852),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = ThemeData.dark();
  final safePadding = switch (size.height) {
    932 => const EdgeInsets.only(top: 59, bottom: 34),
    667 => const EdgeInsets.only(top: 20),
    _ => const EdgeInsets.only(top: 44, bottom: 34),
  };
  await tester.pumpWidget(
    MaterialApp(
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: _font),
      ),
      builder: (context, body) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: safePadding,
          viewPadding: safePadding,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureKey, child: body!),
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _inertBrowseControls(WidgetTester tester, String id) {
  for (final key in [
    'concept_browse_footer',
    'concept_previous_profile',
    'concept_next_profile',
    'draft_profile_$id',
  ]) {
    expect(_key(key), findsOneWidget);
  }
  for (final key in ['concept_browse_menu', 'concept_filters']) {
    expect(_key(key), findsNothing);
  }
  for (final key in [
    'concept_previous_profile',
    'concept_next_profile',
    'draft_profile_$id',
  ]) {
    expect(tester.widget<InkWell>(_key(key)).onTap, isNull);
  }
  expect(find.text('Request a Journey'), findsOneWidget);
  expect(find.text('Request Journey'), findsNothing);
  for (final title in ['My profile', 'Browse', 'Profiles']) {
    expect(find.text(title), findsNothing);
  }
  expect(find.byType(SeekerProfileScreen), findsNothing);
}

ZyraBrowseDesigns _card(WidgetTester tester) {
  final rendered = tester.widget<ZyraBrowseDesigns>(
    find.byType(ZyraBrowseDesigns),
  );
  expect(rendered.readOnlyPreview, isTrue);
  expect(rendered.design, ZyraOneJourneyBrowseDesign.portraitCard);
  expect(rendered.profiles, hasLength(1));
  for (final key in [
    'concept_browse_footer',
    'concept_previous_profile',
    'concept_next_profile',
    'concept_profile_swipe_track',
    'concept_browse_photo_pagination',
    'concept_browse_menu',
    'concept_filters',
  ]) {
    expect(_key(key), findsNothing);
  }
  expect(find.text('Preview'), findsOneWidget);
  expect(find.text('This is how others see your profile.'), findsOneWidget);
  expect(find.byType(SeekerProfileScreen), findsNothing);
  return rendered;
}

Widget _liveReference(SeekerProfile profile, FloatingNavBar navigation) =>
    Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ZyraColors.currentDefaultPalette.gradient,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ZyraBrowseDesigns(
              profiles: [profile],
              selectedIndex: 0,
              design: ZyraOneJourneyBrowseDesign.portraitCard,
              photoBuilder: _renderPhoto,
              profileSwipe: (
                previousIndex: null,
                nextIndex: null,
                onBlockedPrevious: null,
                canAct: () => true,
              ),
              onBrowseMenu: (_) {},
              onRequest: (_) {},
              requestLabel: (_) => 'Request a Journey',
              invitationSent: (_) => false,
              canRequest: (_) => true,
              hapticLevel: ZyraHapticLevel.off,
            ),
            FloatingNavBar(
              items: navigation.items,
              currentIndex: navigation.currentIndex,
              contentEdgeInset: navigation.contentEdgeInset,
              lockedTabBar: true,
              hapticLevel: ZyraHapticLevel.off,
              onTap: (_) {},
            ),
          ],
        ),
      ),
    );

Future<void> _centerSwipe(
  WidgetTester tester,
  String id, {
  int expectedPage = 1,
}) async {
  final pager = _key('concept_browse_photo_swipe_$id');
  final rect = tester.getRect(pager);
  await tester.timedDragFrom(
    Offset(rect.left + rect.width * .8, rect.center.dy),
    Offset(-rect.width * .6, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(
    tester.widget<PageView>(pager).controller!.page,
    closeTo(expectedPage, .01),
  );
  expect(tester.takeException(), isNull);
}

Future<void> _tapPhoto(WidgetTester tester, String id) async {
  final rect = tester.getRect(_key('concept_browse_photo_tap_$id'));
  await tester.tapAt(Offset(rect.right - 40, rect.top + 20));
  await tester.pumpAndSettle();
  final pager = tester.widget<PageView>(_key('concept_browse_photo_swipe_$id'));
  expect(pager.controller!.page, closeTo(1, .01));
}

Future<void> _edgeBack(WidgetTester tester) async {
  final rect = tester.getRect(find.byKey(_edgeKey));
  await tester.timedDragFrom(
    Offset(rect.left + 8, rect.top + rect.height * .35),
    const Offset(190, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  // Native decoding is asynchronous even for a local memory photo. Validate
  // the mounted providers before optionally capturing the real boundary.
  for (final element in find.byType(Image).evaluate().toList()) {
    Object? decodeError;
    await tester.runAsync(
      () => precacheImage(
        (element.widget as Image).image,
        element,
        onError: (error, _) => decodeError = error,
      ).timeout(const Duration(seconds: 5)),
    );
    expect(decodeError, isNull);
  }
  await tester.pumpAndSettle();
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final output = File('$_captures/$name.png');
    await output.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NoNetwork network;
  late HttpOverrides? previousNetwork;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;
  final forbiddenCalls = <String>[];
  final nativeHaptics = <String>[];
  const forbiddenChannels = [
    MethodChannel('plugins.flutter.io/image_picker'),
    MethodChannel('app.zyraconnect.zyra/profile_photo'),
    MethodChannel('com.aboutyou.dart_packages.sign_in_with_apple'),
    MethodChannel('plugins.flutter.io/google_sign_in'),
  ];
  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  List<Object?> memberState() => [
    AppState.instance.name,
    AppState.instance.gender,
    AppState.instance.location,
    List.of(AppState.instance.photos),
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.potentialJourneys),
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
      'own-preview-sentinel': 'unchanged',
    });
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
    AppState.instance.name = 'Unchanged member';
    AppState.instance.photos = [_photo(20)];
    beforePreferences = preferenceState();
    beforeMember = memberState();
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    forbiddenCalls.clear();
    nativeHaptics.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in forbiddenChannels) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        forbiddenCalls.add('${channel.name}:${call.method}');
        throw PlatformException(code: 'unexpected-native-action');
      });
    }
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        nativeHaptics.add('${call.arguments}');
      }
      return null;
    });
    final previousFatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(
      () => WidgetController.hitTestWarningShouldBeFatal = previousFatal,
    );
  });

  tearDown(() {
    expect(network.attempts, 0);
    expect(forbiddenCalls, isEmpty);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMember);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in forbiddenChannels) {
      messenger.setMockMethodCallHandler(channel, null);
    }
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
  });

  testWidgets(
    'Shared read-only card suppresses even supplied self-action and label delegates',
    (tester) async {
      final person = _profile();
      final calls = <String>[];
      final photoChanges = <int>[];
      void action(String name) => calls.add(name);
      await _mount(
        tester,
        Scaffold(
          body: ZyraBrowseDesigns(
            profiles: [person],
            selectedIndex: 0,
            design: ZyraOneJourneyBrowseDesign.portraitCard,
            readOnlyPreview: true,
            hapticLevel: ZyraHapticLevel.off,
            photoBuilder: _renderPhoto,
            onPrevious: () => action('previous'),
            onNext: () => action('next'),
            onFilters: () => action('filters'),
            onBrowseMenu: (_) => action('menu'),
            onProfile: (_) => action('profile'),
            onRequest: (_) => action('request'),
            requestLabel: (_) {
              action('requestLabel');
              return 'Forbidden self invitation';
            },
            invitationSent: (_) {
              action('invitationSent');
              return true;
            },
            canRequest: (_) {
              action('canRequest');
              return true;
            },
            onGalleryIndexChanged: (_, index) => photoChanges.add(index),
          ),
        ),
      );
      _inertBrowseControls(tester, person.id);
      expect(calls, isEmpty);
      expect(find.text('Forbidden self invitation'), findsNothing);
      expect(
        tester
            .widget<ZyraInvitationOutline>(find.byType(ZyraInvitationOutline))
            .sent,
        isFalse,
      );
      await _centerSwipe(tester, person.id);
      await tester.tapAt(
        tester.getCenter(_key('concept_browse_photo_tap_${person.id}')),
      );
      await tester.pumpAndSettle();
      expect(photoChanges, containsAllInOrder([1, 2]));
      expect(calls, isEmpty);
      _inertBrowseControls(tester, person.id);
      expect(tester.takeException(), isNull);
    },
  );

  for (final variant in [
    (name: 'standard', size: const Size(430, 932), scale: 1.0),
    (name: 'narrow', size: const Size(375, 667), scale: 1.0),
    (name: 'large-text', size: const Size(393, 852), scale: 2.0),
    (name: 'compact200', size: const Size(320, 568), scale: 2.0),
  ]) {
    testWidgets(
      'Own preview keeps live Profiles card culture without an empty header at ${variant.name}',
      (tester) async {
        final owner = _Owner(_profile());
        addTearDown(owner.dispose);
        await _mount(
          tester,
          _owned(owner),
          size: variant.size,
          textScale: variant.scale,
        );
        final own = _card(tester);
        expect(find.text('Back'), findsNothing);
        expect(find.byKey(_backKey), findsNothing);
        expect(_key('concept_browse_header'), findsNothing);
        expect(_key('zyra_back_header_space'), findsNothing);
        expect(find.byKey(_edgeKey), findsOneWidget);
        final details = _key('concept_browse_details_${owner.profile.id}');
        expect(details, findsOneWidget);
        for (final value in [
          'NATIONALITY',
          'British',
          'ETHNICITY',
          'South Asian',
        ]) {
          expect(
            find.descendant(of: details, matching: find.text(value)),
            findsOneWidget,
          );
        }
        expect(
          find.descendant(of: details, matching: find.byType(Image)),
          findsOneWidget,
        );
        final card = tester.getRect(_key('concept_browse_portrait_card'));
        expect(card.left, 20);
        expect(card.width, variant.size.width - 40);
        final request = find.descendant(
          of: details,
          matching: _key('draft_profile_${owner.profile.id}'),
        );
        expect(request, findsOneWidget);
        final requestStyle = tester
            .widget<Text>(find.text('Request a Journey'))
            .style;
        final navigation = tester.widget<FloatingNavBar>(
          find.byType(FloatingNavBar),
        );
        expect(navigation.items, hasLength(5));
        expect(navigation.items.first.label, 'Profiles');
        expect(navigation.currentIndex, 4);
        expect(navigation.lockedTabBar, isTrue);
        expect(navigation.contentEdgeInset, 20);
        expect(navigation.hapticLevel, ZyraHapticLevel.off);
        final tabBar = tester.getRect(_key('compact-nav-surface'));
        expect(tabBar.top - card.bottom, closeTo(16, .01));
        expect(find.byType(ZyraProfileDetailsPage), findsOneWidget);
        await _capture(tester, 'own-browse-parity-${variant.name}');
        await tester.ensureVisible(request);
        await tester.pumpAndSettle();
        expect(request.hitTestable(), findsOneWidget);
        await tester.tap(request);
        await tester.pump();
        expect(
          find.text('Others tap here to request a Journey with you.'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 3));

        await _mount(
          tester,
          _liveReference(own.profiles.single, navigation),
          size: variant.size,
          textScale: variant.scale,
        );
        expect(find.text('Profiles'), findsOneWidget);
        expect(find.byType(ZyraProfileDetailsPage), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('Request a Journey')).style,
          requestStyle,
        );
        await _capture(tester, 'profiles-details-${variant.name}');
        if (variant.scale == 1) {
          await _tapPhoto(tester, owner.profile.id);
          await _capture(tester, 'profiles-photo-${variant.name}');
        }
        expect(owner.returns, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Own preview footer and navigation have no pointer semantic focus or haptic actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final owner = _Owner(_profile());
        addTearDown(owner.dispose);
        await _mount(tester, _owned(owner));
        final rendered = _card(tester);
        final navFinder = find.byType(FloatingNavBar);
        final navigation = tester.widget<FloatingNavBar>(navFinder);
        final navElement = tester.element(navFinder);
        expect(
          tester
              .widget<IgnorePointer>(find.byKey(_inertNavigationKey))
              .ignoring,
          isTrue,
        );
        expect(
          find.ancestor(
            of: navFinder,
            matching: find.byWidgetPredicate(
              (widget) => widget is ExcludeSemantics && widget.excluding,
            ),
          ),
          findsWidgets,
        );
        expect(
          find.ancestor(
            of: navFinder,
            matching: find.byWidgetPredicate(
              (widget) => widget is ExcludeFocus && widget.excluding,
            ),
          ),
          findsWidgets,
        );
        for (final item in navigation.items) {
          expect(find.bySemanticsLabel(item.label), findsNothing);
        }
        final request = _key('draft_profile_${rendered.profiles.single.id}');
        expect(
          tester
              .getSemantics(request)
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        await tester.tap(request);
        await tester.pump();
        const requestInfo = 'Others tap here to request a Journey with you.';
        expect(find.text(requestInfo), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        expect(find.text(requestInfo), findsNothing);
        final first = tester.getCenter(_key('floating-nav-item-1'));
        final last = tester.getCenter(_key('floating-nav-item-3'));
        await tester.tapAt(first);
        await tester.timedDragFrom(
          first,
          last - first,
          const Duration(milliseconds: 450),
        );
        await tester.pumpAndSettle();
        expect(tester.element(navFinder), same(navElement));
        expect(tester.widget<FloatingNavBar>(navFinder).currentIndex, 4);
        expect(owner.returns, 0);
        expect(nativeHaptics, isEmpty);
        expect(
          tester
              .widget<PageView>(
                _key('concept_browse_photo_swipe_${owner.profile.id}'),
              )
              .controller!
              .page,
          0,
        );
        _card(tester);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Own preview never invents missing public heritage labels', (
    tester,
  ) async {
    final owner = _Owner(_profile(publicHeritage: false));
    addTearDown(owner.dispose);
    await _mount(tester, _owned(owner));
    final rendered = _card(tester);
    expect(rendered.profiles.single.publicNationality, isNull);
    expect(rendered.profiles.single.publicEthnicity, isNull);
    expect(find.text('NATIONALITY'), findsNothing);
    expect(find.text('ETHNICITY'), findsNothing);
    expect(find.textContaining('Unknown'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Own preview keeps Details first and rejects callbacks after owner revocation',
    (tester) async {
      final owner = _Owner(_profile());
      addTearDown(owner.dispose);
      await _mount(tester, _owned(owner));
      final id = owner.profile.id;
      expect(_key('concept_browse_details_$id'), findsOneWidget);
      final staleRequest = tester
          .widget<InkWell>(_key('draft_profile_$id'))
          .onTap!;
      await _centerSwipe(tester, id, expectedPage: 0);
      await _tapPhoto(tester, id);
      expect(_key('concept_browse_identity_$id'), findsNothing);
      _card(tester);
      expect(owner.returns, 0);
      final oldPager = tester.widget<PageView>(
        _key('concept_browse_photo_swipe_$id'),
      );
      owner.allowed = false;
      staleRequest();
      expect(
        find.text('Others tap here to request a Journey with you.'),
        findsNothing,
      );
      owner.rebuild();
      await tester.pumpAndSettle();
      oldPager.onPageChanged!(0);
      await tester.pumpAndSettle();
      expect(find.byType(ZyraBrowseDesigns), findsNothing);
      expect(owner.returns, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final returnMethod in ['accessibility', 'edge']) {
    testWidgets(
      'Protected own card center photos remain local and $returnMethod returns once to its caller',
      (tester) async {
        final owner = _Owner(_profile());
        addTearDown(owner.dispose);
        await _mount(tester, _owned(owner));
        final rendered = _card(tester);
        expect(rendered.profiles.single.firstName, 'Amina');
        expect(rendered.profiles.single.photos, owner.profile.photos);
        expect(find.text('Unchanged member'), findsNothing);
        expect(find.byKey(_backKey), findsNothing);
        expect(find.byKey(_edgeKey), findsOneWidget);
        final staleBack = captureZyraAccessibleBack(tester);
        await _tapPhoto(tester, owner.profile.id);
        expect(owner.returns, 0);
        await _capture(
          tester,
          returnMethod == 'accessibility'
              ? 'own-browse-accessible'
              : 'own-browse-edge',
        );
        if (returnMethod == 'accessibility') {
          captureZyraAccessibleBack(tester)();
          await tester.pumpAndSettle();
        } else {
          await _edgeBack(tester);
        }
        expect(find.text('Own profile parent').hitTestable(), findsOneWidget);
        expect(find.byType(MyProfilePreviewScreen), findsNothing);
        expect(owner.returns, 1);
        staleBack();
        await tester.pumpAndSettle();
        expect(owner.returns, 1);
        expect(find.text('Own profile parent').hitTestable(), findsOneWidget);
      },
    );
  }

  for (final throwing in [false, true]) {
    testWidgets(
      'Protected canAct ${throwing ? 'throw' : 'denial'} withdraws old card and photos without returning or revival',
      (tester) async {
        final owner = _Owner(_profile());
        addTearDown(owner.dispose);
        await _mount(tester, _owned(owner));
        _card(tester);
        await _tapPhoto(tester, owner.profile.id);
        await _capture(
          tester,
          'own-browse-before-${throwing ? 'throw' : 'denial'}',
        );
        expect(find.byType(Image), findsWidgets);
        final staleBack = tester
            .widget<ZyraPullDownBackScope>(find.byKey(_scopeKey))
            .onBack;
        // Revoke before another owner rebuild: a retained callback must itself
        // withdraw the painted card and must not borrow a later owner grant.
        owner.allowed = false;
        owner.throwsGuard = throwing;
        staleBack();
        await tester.pumpAndSettle();
        expect(owner.returns, 0);
        expect(_key('my-profile-preview-unavailable'), findsOneWidget);
        expect(
          find.byType(ZyraBrowseDesigns, skipOffstage: false),
          findsNothing,
        );
        expect(find.byType(Image, skipOffstage: false), findsNothing);
        expect(find.text('Amina', skipOffstage: false), findsNothing);
        expect(find.byKey(_backKey), findsNothing);
        expect(find.byKey(_edgeKey), findsNothing);
        owner.allowed = true;
        owner.throwsGuard = false;
        owner.rebuild();
        await tester.pumpAndSettle();
        staleBack();
        await tester.pumpAndSettle();
        expect(owner.returns, 0);
        expect(_key('my-profile-preview-unavailable'), findsOneWidget);
        expect(
          find.byType(ZyraBrowseDesigns, skipOffstage: false),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Compact own preview edge return stays available while its card is scrolled',
    (tester) async {
      final owner = _Owner(_profile(longIdentity: true));
      addTearDown(owner.dispose);
      await _mount(
        tester,
        _owned(owner),
        size: const Size(320, 568),
        textScale: 2,
      );
      _card(tester);
      await Scrollable.ensureVisible(
        tester.element(find.text('South Asian')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_backKey), findsNothing);
      expect(_key('zyra_back_header_space'), findsNothing);
      expect(find.byKey(_edgeKey), findsOneWidget);
      expect(owner.returns, 0);
      await _edgeBack(tester);
      expect(owner.returns, 1);
      expect(find.text('Own profile parent').hitTestable(), findsOneWidget);
      expect(find.byType(MyProfilePreviewScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Compact 320x568 2x text own card scrolls without overflow and keeps semantic return available',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final owner = _Owner(_profile(longIdentity: true));
        addTearDown(owner.dispose);
        await _mount(
          tester,
          _owned(owner),
          size: const Size(320, 568),
          textScale: 2,
        );
        _card(tester);
        expect(find.byKey(_backKey), findsNothing);
        expect(_key('zyra_back_header_space'), findsNothing);
        final returnSemantics = tester
            .getSemantics(_key('zyra_pull_down_back_semantics'))
            .getSemanticsData();
        expect(returnSemantics.hasAction(ui.SemanticsAction.dismiss), isTrue);
        await Scrollable.ensureVisible(
          tester.element(find.text('Amina Mariam Rahman Hussain')),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        // No empty visual header returns when the card scrolls. The actual
        // screen-reader return action remains available across the viewport.
        expect(find.byKey(_backKey), findsNothing);
        expect(_key('zyra_back_swipe_edge'), findsOneWidget);
        expect(owner.returns, 0);
        expect(tester.takeException(), isNull);
        await _capture(tester, 'own-browse-compact200');
        captureZyraAccessibleBack(tester)();
        await tester.pumpAndSettle();
        expect(owner.returns, 1);
        expect(find.text('Own profile parent').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
