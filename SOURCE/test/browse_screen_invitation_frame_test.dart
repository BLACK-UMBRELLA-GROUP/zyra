// The protected offline shell only: decorative feedback is not invitation,
// account, receipt, entitlement or provider authority.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_card_metrics.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_invitation_outline.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
const _captureDirectory = String.fromEnvironment(
  'ZYRA_BROWSE_FRAME_CAPTURE_DIR',
);
const _capture = _captureDirectory != '';
const _font = 'PoppinsBrowseFrame';
const _boundary = ValueKey('browse-screen-frame-candidate');

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _photoOutline(String id) => _key('browse_invitation_outline_$id');
Finder get _frames => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('concept_browse_screen_invitation_frame_');
});

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Invitation frame tests must not contact a provider.');
  }
}

ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );

String _selectedId(WidgetTester tester) {
  final browse = _browse(tester);
  return browse.profiles[browse.selectedIndex].id;
}

Future<void> _mount(
  WidgetTester tester, {
  bool quiet = true,
  bool accessible = false,
  bool Function()? canAct,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: quiet,
          accessibleNavigation: accessible,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child: ZyraOneJourneyConceptShell(
          canAct: canAct ?? () => true,
          onExit: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final browse = _browse(tester);
      if (browse.profiles.isNotEmpty &&
          browse.profiles.every((profile) => profile.photos.isNotEmpty)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tester.pump();
    }
    fail('The offline Browse deck did not publish prepared photo frames.');
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(_frames, findsNothing);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _tap(WidgetTester tester, String id) async {
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  expect(target, findsOneWidget, reason: 'Required public action $id');
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final screen = Offset.zero & tester.view.physicalSize;
  var visible = tester.getRect(target).intersect(screen);
  final scroll = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scroll.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(scroll.first));
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  final alignment = Alignment(
    2 * local.dx / box.size.width - 1,
    2 * local.dy / box.size.height - 1,
  );
  expect(target.hitTestable(at: alignment), findsOneWidget);
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(_frames, findsNothing);
}

Future<void> _tapBar(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final nav = tester.widget<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  final index = nav.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  // The selected Couple glyph is painted, not an Icon widget. The labelled
  // navigation cell remains the public target regardless of glyph renderer.
  final target = find.descendant(
    of: find.byType(ZyraShellNavigation),
    matching: _key('floating-nav-item-$index'),
  );
  expect(target, findsOneWidget);
  expect(tester.widget<Semantics>(target).properties.label, label);
  final owner = find
      .ancestor(
        of: target,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(owner.hitTestable(), findsOneWidget);
  final point = tester.getCenter(target);
  expect(tester.getRect(owner).contains(point), isTrue);
  await tester.tapAt(point);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(_frames, findsNothing);
}

BoxDecoration _decoration(WidgetTester tester, Finder outline) {
  final decorations = tester
      .widgetList<DecoratedBox>(
        find.descendant(of: outline, matching: find.byType(DecoratedBox)),
      )
      .map((widget) => widget.decoration)
      .whereType<BoxDecoration>()
      .where((decoration) => decoration.border is Border)
      .toList();
  expect(decorations, hasLength(1));
  return decorations.single;
}

void _expectPhotoOutline(WidgetTester tester, String id, {required bool sent}) {
  expect(_frames, findsNothing, reason: 'The outer screen ring was rejected.');
  expect(_photoOutline(id), findsOneWidget);
  final outline = tester.widget<ZyraInvitationOutline>(_photoOutline(id));
  expect(outline.sent, sent);
  expect(
    outline.borderRadius,
    BorderRadius.circular(ZyraCardMetrics.cardRadius),
  );
  final photoBounds = tester.getRect(_key('concept_browse_photo_swipe_$id'));
  expect(tester.getRect(_photoOutline(id)), photoBounds);
  expect(photoBounds, isNot(const Rect.fromLTWH(0, 0, 393, 852)));
  final decoration = _decoration(tester, _photoOutline(id));
  final border = decoration.border! as Border;
  for (final side in [border.top, border.right, border.bottom, border.left]) {
    expect(side.width, 5);
    expect(
      side.color,
      ZyraColors.journeyGold.withValues(alpha: sent ? .65 : 0),
    );
  }
  final ignores = tester.widgetList<IgnorePointer>(
    find.descendant(
      of: _photoOutline(id),
      matching: find.byType(IgnorePointer),
    ),
  );
  expect(ignores, hasLength(1));
  expect(ignores.single.ignoring, isTrue);
  expect(
    find.descendant(
      of: _photoOutline(id),
      matching: find.byType(ExcludeSemantics),
    ),
    findsOneWidget,
  );
}

VoidCallback _requestCallback(WidgetTester tester, String id) =>
    tester.widget<InkWell>(_key('draft_profile_$id')).onTap!;

Future<void> _capturePage(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(
    _captureDirectory.startsWith('/'),
    isTrue,
    reason: 'The root operator must supply an absolute packet directory.',
  );
  for (final image in tester.widgetList<Image>(find.byType(Image))) {
    expect(image.image, isA<MemoryImage>());
    await tester.runAsync(() async {
      final ready = Completer<void>();
      final stream = image.image.resolve(const ImageConfiguration());
      final listener = ImageStreamListener(
        (_, _) {
          if (!ready.isCompleted) ready.complete();
        },
        onError: (Object error, StackTrace? stack) {
          if (!ready.isCompleted) ready.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await ready.future.timeout(const Duration(seconds: 10));
      } finally {
        stream.removeListener(listener);
      }
    });
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory(_captureDirectory);
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png').writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late ZyraHapticLevel previousHaptics;
  late ZyraNavStyle previousNav;

  setUpAll(() async {
    if (!_capture) return;
    final font = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });

  setUp(() {
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousHaptics = ZyraInteractionStyle.hapticLevel;
    previousNav = ZyraInteractionStyle.navStyle;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    ZyraInteractionStyle.selectNavStyle(
      ZyraInteractionStyle.currentDefaultNavStyle,
    );
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _capture ? _font : null;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraInteractionStyle.selectHapticLevel(previousHaptics);
    ZyraInteractionStyle.selectNavStyle(previousNav);
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'sent invitation keeps only the non-interactive five-pixel photo outline',
    (tester) async {
      await _mount(tester);
      expect(_selectedId(tester), _sara);
      _expectPhotoOutline(tester, _sara, sent: false);
      final photo = _key('concept_browse_photo_swipe_$_sara');
      final photoBounds = tester.getRect(photo);
      final requestBounds = tester.getRect(_key('draft_profile_$_sara'));
      final navBounds = tester.getRect(find.byType(FloatingNavBar));
      await _capturePage(tester, 'browse_photo_frame_unsent_393');
      await _tap(tester, 'draft_profile_$_sara');
      _expectPhotoOutline(tester, _sara, sent: true);
      expect(tester.getRect(photo), photoBounds);
      expect(tester.getRect(_key('draft_profile_$_sara')), requestBounds);
      expect(tester.getRect(find.byType(FloatingNavBar)), navBounds);
      expect(find.text('Request sent'), findsOneWidget);
      await _capturePage(tester, 'browse_photo_frame_sent_393');
      // The decoration must not consume actual photo or invitation taps.
      await _tap(tester, 'concept_browse_photo_tap_$_sara');
      expect(_selectedId(tester), _sara);
      final selectedDot = tester.widget<AnimatedContainer>(
        _key('concept_browse_photo_dot_${_sara}_1'),
      );
      expect(
        (selectedDot.decoration! as BoxDecoration).color,
        ZyraColors.journeyGold,
      );
      await _tap(tester, 'draft_profile_$_sara');
      _expectPhotoOutline(tester, _sara, sent: false);
      expect(_selectedId(tester), _sara);
      expect(tester.getRect(photo), photoBounds);
      expect(tester.getRect(_key('draft_profile_$_sara')), requestBounds);
      expect(tester.getRect(find.byType(FloatingNavBar)), navBounds);
      expect(find.text('Request a Journey'), findsOneWidget);
    },
  );

  testWidgets(
    'Next shows the next photo unoutlined and Back restores the sent outline',
    (tester) async {
      await _mount(tester);
      await _tap(tester, 'draft_profile_$_sara');
      _expectPhotoOutline(tester, _sara, sent: true);
      await _tap(tester, 'concept_next_profile');
      expect(_selectedId(tester), 'draft-aisha');
      _expectPhotoOutline(tester, 'draft-aisha', sent: false);
      await _tap(tester, 'concept_previous_profile');
      expect(_selectedId(tester), _sara);
      _expectPhotoOutline(tester, _sara, sent: true);
    },
  );

  testWidgets(
    'only the currently filtered profile receives its sent photo outline',
    (tester) async {
      await _mount(tester);
      await _tap(tester, 'draft_profile_$_sara');
      await _tap(tester, 'concept_browse_menu');
      await _tapBar(tester, 'Filters');
      expect(_frames, findsNothing);
      await _tap(tester, 'concept_age_1');
      tester.widget<RangeSlider>(_key('concept_age_range')).onChanged!(
        const RangeValues(29, 70),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'concept_apply_filter');
      expect(_browse(tester).profiles.every((p) => p.age >= 29), isTrue);
      expect(_browse(tester).profiles.map((p) => p.id), isNot(contains(_sara)));
      expect(_frames, findsNothing);
      final id = _selectedId(tester);
      _expectPhotoOutline(tester, id, sent: false);
      await _tap(tester, 'draft_profile_$id');
      _expectPhotoOutline(tester, id, sent: true);
    },
  );

  testWidgets(
    'subpages and tabs never mount a screen ring or borrow the Browse photo',
    (tester) async {
      await _mount(tester);
      await _tap(tester, 'draft_profile_$_sara');
      await _tap(tester, 'draft_back');
      expect(_frames, findsNothing);
      expect(_photoOutline(_sara), findsNothing);
      await _tap(tester, 'draft_back');
      _expectPhotoOutline(tester, _sara, sent: true);
      await _tapBar(tester, 'My ZYRA');
      expect(_frames, findsNothing);
      expect(_photoOutline(_sara), findsNothing);
      await _tapBar(tester, 'Profiles');
      _expectPhotoOutline(tester, _sara, sent: true);
    },
  );

  testWidgets(
    'Portrait-only controls and Guardian comparison do not inherit a screen frame',
    (tester) async {
      await _mount(tester);
      await _tap(tester, 'draft_profile_$_sara');
      await _tap(tester, 'draft_back');
      expect(_key('concept_browse_design_peoplePortraitGrid'), findsNothing);
      expect(_key('concept_browse_design_portraitCard'), findsNothing);
      expect(_frames, findsNothing);
      await _tap(tester, 'draft_back');
      expect(_frames, findsNothing);
      expect(_browse(tester).design, ZyraOneJourneyBrowseDesign.portraitCard);
      _expectPhotoOutline(tester, _sara, sent: true);
      await _tap(tester, 'draft_back');
      await _tap(tester, 'draft_role_guardian');
      expect(_frames, findsNothing);
      expect(_key('concept_browse_photo_tap_$_sara'), findsNothing);
    },
  );

  testWidgets(
    'revoked owner denies retained cancellation and never gains a screen ring',
    (tester) async {
      var allowed = true;
      await _mount(tester, canAct: () => allowed);
      await _tap(tester, 'draft_profile_$_sara');
      final cancel = _requestCallback(tester, _sara);
      allowed = false;
      tester.element(find.byType(ZyraOneJourneyConceptShell)).markNeedsBuild();
      await tester.pumpAndSettle();
      _expectPhotoOutline(tester, _sara, sent: true);
      cancel();
      await tester.pumpAndSettle();
      _expectPhotoOutline(tester, _sara, sent: true);
      expect(_selectedId(tester), _sara);
      expect(find.text('Request sent'), findsOneWidget);
      allowed = true;
      tester.element(find.byType(ZyraOneJourneyConceptShell)).markNeedsBuild();
      await tester.pumpAndSettle();
      _expectPhotoOutline(tester, _sara, sent: true);
    },
  );

  testWidgets(
    'full monthly capacity keeps Browse and requests without a screen ring',
    (tester) async {
      await _mount(tester);
      await _tap(tester, 'draft_profile_$_sara');
      _expectPhotoOutline(tester, _sara, sent: true);
      await _tapBar(tester, 'Journey');
      await _tap(tester, 'draft_back');
      expect(
        tester.widget<Text>(_key('concept_page_options_context')).data,
        'Journey',
      );
      await _tap(tester, 'concept_journey_preview_3');
      expect(_frames, findsNothing);
      await _tapBar(tester, 'Profiles');
      expect(_frames, findsNothing);
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      expect(_browse(tester).profiles, isNotEmpty);
      // Accepted/active peers do not carry the previous pending invitation.
      _expectPhotoOutline(tester, _selectedId(tester), sent: false);
      for (var move = 0; move < _browse(tester).profiles.length; move++) {
        final browse = _browse(tester);
        final person = browse.profiles[browse.selectedIndex];
        if (browse.canRequest!(person)) break;
        await _tap(tester, 'concept_next_profile');
      }
      final browse = _browse(tester);
      final person = browse.profiles[browse.selectedIndex];
      expect(browse.canRequest!(person), isTrue);
      _expectPhotoOutline(tester, person.id, sent: false);
      await _tap(tester, 'draft_profile_${person.id}');
      _expectPhotoOutline(tester, person.id, sent: true);
      expect(find.text('Request sent'), findsOneWidget);
    },
  );

  for (final mode in const [
    (quiet: true, accessible: false),
    (quiet: false, accessible: true),
  ]) {
    testWidgets('quiet photo-only feedback is immediate ${mode.quiet}', (
      tester,
    ) async {
      await _mount(tester, quiet: mode.quiet, accessible: mode.accessible);
      final request = _key('draft_profile_$_sara');
      expect(request.hitTestable(), findsOneWidget);
      await tester.tap(request);
      await tester.pump();
      _expectPhotoOutline(tester, _sara, sent: true);
      expect(
        find.descendant(
          of: _photoOutline(_sara),
          matching: find.byWidgetPredicate(
            (widget) => widget is TweenAnimationBuilder<double>,
          ),
        ),
        findsNothing,
      );
      await tester.tap(request);
      await tester.pump();
      _expectPhotoOutline(tester, _sara, sent: false);
    });
  }

  testWidgets('ordinary animation never grants a stale profile action', (
    tester,
  ) async {
    await _mount(tester, quiet: false);
    final request = _key('draft_profile_$_sara');
    await tester.tap(request);
    await tester.pump();
    expect(_frames, findsNothing);
    expect(_photoOutline(_sara), findsOneWidget);
    final oldCancel = _requestCallback(tester, _sara);
    final decoration = _decoration(tester, _photoOutline(_sara));
    expect((decoration.border! as Border).top.width, 5);
    await tester.pump(const Duration(milliseconds: 130));
    final midBorder =
        _decoration(tester, _photoOutline(_sara)).border! as Border;
    expect(midBorder.top.color.a, greaterThan(0));
    expect(midBorder.top.color.a, lessThan(.65));
    expect(_frames, findsNothing);
    await _tap(tester, 'concept_next_profile');
    expect(_selectedId(tester), 'draft-aisha');
    _expectPhotoOutline(tester, 'draft-aisha', sent: false);
    oldCancel();
    await tester.pumpAndSettle();
    _expectPhotoOutline(tester, 'draft-aisha', sent: false);
    expect(_selectedId(tester), 'draft-aisha');
    await _tap(tester, 'concept_previous_profile');
    _expectPhotoOutline(tester, _sara, sent: true);
  });
}
