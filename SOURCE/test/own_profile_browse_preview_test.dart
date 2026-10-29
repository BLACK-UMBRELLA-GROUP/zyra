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
  ZyraBrowseGalleryMode galleryMode = ZyraBrowseGalleryMode.detailsFirst;
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
            galleryMode: owner.galleryMode,
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
  await tester.pumpWidget(
    MaterialApp(
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: _font),
      ),
      builder: (context, body) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 44, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
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
  _inertBrowseControls(tester, rendered.profiles.single.id);
  return rendered;
}

Map<String, Rect> _browseGeometry(WidgetTester tester) {
  final profile = tester
      .widget<ZyraBrowseDesigns>(find.byType(ZyraBrowseDesigns))
      .profiles
      .single;
  return {
    for (final key in [
      'concept_browse_portrait_card',
      'concept_browse_footer',
      'concept_previous_profile',
      'concept_next_profile',
    ])
      key: tester.getRect(_key(key)),
    'request': tester.getRect(_key('draft_profile_${profile.id}')),
    'navigation': tester.getRect(find.byType(FloatingNavBar)),
  };
}

List<Color?> _footerIconColours(WidgetTester tester) => [
  for (final key in ['concept_previous_profile', 'concept_next_profile'])
    tester
        .widget<Icon>(
          find.descendant(of: _key(key), matching: find.byType(Icon)),
        )
        .color,
];

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
              onNext: () {},
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
              hapticLevel: ZyraHapticLevel.off,
              onTap: (_) {},
            ),
          ],
        ),
      ),
    );

Future<void> _centerSwipe(WidgetTester tester, String id) async {
  final pager = _key('concept_browse_photo_swipe_$id');
  final rect = tester.getRect(pager);
  await tester.timedDragFrom(
    Offset(rect.left + rect.width * .8, rect.center.dy),
    Offset(-rect.width * .6, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
  expect(tester.takeException(), isNull);
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
      _card(tester);
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
      _card(tester);
      expect(tester.takeException(), isNull);
    },
  );

  for (final variant in [
    (name: 'standard', size: const Size(393, 852), scale: 1.0),
    (name: 'narrow', size: const Size(320, 568), scale: 1.0),
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
          'Nationality',
          'British',
          'Ethnicity',
          'South Asian',
        ]) {
          expect(
            find.descendant(of: details, matching: find.text(value)),
            findsOneWidget,
          );
        }
        expect(
          find.descendant(of: details, matching: find.byType(Image)),
          findsNothing,
        );
        final geometry = _browseGeometry(tester);
        expect(geometry['concept_browse_portrait_card']!.left, 20);
        final requestStyle = tester
            .widget<Text>(find.text('Request a Journey'))
            .style;
        final iconColours = _footerIconColours(tester);
        final navigation = tester.widget<FloatingNavBar>(
          find.byType(FloatingNavBar),
        );
        expect(navigation.items, hasLength(5));
        expect(navigation.items.first.label, 'Profiles');
        expect(navigation.currentIndex, 0);
        expect(navigation.contentEdgeInset, 20);
        expect(navigation.hapticLevel, ZyraHapticLevel.off);
        await _capture(tester, 'own-browse-parity-${variant.name}');

        await _mount(
          tester,
          _liveReference(own.profiles.single, navigation),
          size: variant.size,
          textScale: variant.scale,
        );
        expect(find.text('Profiles'), findsOneWidget);
        expect(find.text('Back'), findsNothing);
        final reference = _browseGeometry(tester);
        for (final entry in geometry.entries) {
          final actual = reference[entry.key]!;
          expect(
            actual.left,
            closeTo(entry.value.left, .01),
            reason: entry.key,
          );
          // The preview no longer reserves the live Profiles title row. Its
          // card uses that space; footer and navigation styling stay shared.
          expect(
            entry.value.top,
            lessThanOrEqualTo(actual.top + .01),
            reason: entry.key,
          );
          expect(
            actual.width,
            closeTo(entry.value.width, .01),
            reason: entry.key,
          );
          if (entry.key == 'concept_browse_portrait_card') {
            expect(
              entry.value.height,
              greaterThanOrEqualTo(actual.height - .01),
            );
          } else {
            expect(
              actual.height,
              closeTo(entry.value.height, .01),
              reason: entry.key,
            );
          }
        }
        expect(
          tester.widget<Text>(find.text('Request a Journey')).style,
          requestStyle,
        );
        expect(_footerIconColours(tester), iconColours);
        await _capture(tester, 'profiles-details-${variant.name}');
        if (variant.scale == 1) {
          await _centerSwipe(tester, owner.profile.id);
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
        for (final key in [
          'concept_previous_profile',
          'concept_next_profile',
          'draft_profile_${rendered.profiles.single.id}',
        ]) {
          final target = _key(key);
          expect(
            tester
                .getSemantics(target)
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.tap),
            isFalse,
          );
          await tester.tapAt(tester.getCenter(target));
        }
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
        expect(tester.widget<FloatingNavBar>(navFinder).currentIndex, 0);
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
    expect(find.text('Nationality'), findsNothing);
    expect(find.text('Ethnicity'), findsNothing);
    expect(find.textContaining('Unknown'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final mode in ZyraBrowseGalleryMode.values) {
    testWidgets('Own preview ${mode.name} keeps mode local and actions inert', (
      tester,
    ) async {
      final owner = _Owner(_profile())..galleryMode = mode;
      addTearDown(owner.dispose);
      await _mount(tester, _owned(owner));
      final own = _card(tester);
      expect(own.galleryMode, mode);
      final id = owner.profile.id;
      final details = _key('concept_browse_details_$id');
      final identity = _key('concept_browse_identity_$id');
      if (mode == ZyraBrowseGalleryMode.detailsFirst) {
        expect(details, findsOneWidget);
        await _centerSwipe(tester, id);
        expect(identity, findsNothing);
      } else {
        expect(details, findsNothing);
        expect(identity, findsOneWidget);
        await _centerSwipe(tester, id);
      }
      _inertBrowseControls(tester, id);
      expect(owner.returns, 0);
      final oldPager = tester.widget<PageView>(
        _key('concept_browse_photo_swipe_$id'),
      );
      owner.galleryMode = mode == ZyraBrowseGalleryMode.detailsFirst
          ? ZyraBrowseGalleryMode.originalPhotos
          : ZyraBrowseGalleryMode.detailsFirst;
      owner.rebuild();
      await tester.pumpAndSettle();
      final switched = _card(tester);
      expect(switched.galleryMode, owner.galleryMode);
      final pager = tester.widget<PageView>(
        _key('concept_browse_photo_swipe_$id'),
      );
      expect(identical(pager.controller, oldPager.controller), isFalse);
      expect(pager.controller!.page, closeTo(0, .001));
      owner.allowed = false;
      owner.rebuild();
      await tester.pumpAndSettle();
      oldPager.onPageChanged!(0);
      await tester.pumpAndSettle();
      expect(find.byType(ZyraBrowseDesigns), findsNothing);
      expect(owner.returns, 0);
      expect(tester.takeException(), isNull);
    });
  }

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
        await _centerSwipe(tester, owner.profile.id);
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
        await _centerSwipe(tester, owner.profile.id);
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
          tester.element(find.text('Amina Mariam')),
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
