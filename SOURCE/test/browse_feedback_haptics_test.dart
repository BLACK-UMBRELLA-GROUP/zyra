// Local guarded shell with synthetic public profiles and offline images.
// Native feedback acknowledges valid gestures, never authorizes an action.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

const _sara = 'draft-sara';
Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Browse feedback tests must not contact a provider.');
  }
}

ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );

String _currentId(WidgetTester tester) {
  final browse = _browse(tester);
  return browse.profiles[browse.selectedIndex].id;
}

VoidCallback? _action(WidgetTester tester, String key) {
  final target = _key(key);
  expect(target, findsOneWidget);
  final widget = tester.widget<Widget>(target);
  if (widget is InkWell) return widget.onTap;
  if (widget is GestureDetector) return widget.onTap;
  if (widget is ButtonStyleButton) return widget.onPressed;
  final ink = find.descendant(of: target, matching: find.byType(InkWell));
  expect(ink, findsOneWidget);
  return tester.widget<InkWell>(ink).onTap;
}

Future<void> _mount(WidgetTester tester, {bool Function()? canAct}) async {
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
          disableAnimations: false,
        ),
        child: child!,
      ),
      home: ZyraOneJourneyConceptShell(
        canAct: canAct ?? () => true,
        onExit: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Codec completion uses the real event loop. Observe the public deck only
  // after the shell publishes its prepared first frames, without bypassing
  // the owner guard or substituting fake photo readiness.
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
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final screen = Offset.zero & tester.view.physicalSize;
  final nav = find.byType(FloatingNavBar);
  final reading = nav.evaluate().isEmpty
      ? screen
      : Rect.fromLTRB(0, 59, screen.width, tester.getRect(nav).top);
  final visible = tester.getRect(target).intersect(reading);
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final point = box.globalToLocal(visible.center);
  expect(
    target.hitTestable(
      at: Alignment(
        2 * point.dx / box.size.width - 1,
        2 * point.dy / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _seedViewedHistory(WidgetTester tester) async {
  expect(_currentId(tester), _sara);
  final profileCount = _browse(tester).profiles.length;
  expect(profileCount, 7);
  for (var visit = 0; visit < profileCount; visit++) {
    await _tap(tester, 'concept_next_profile');
  }
  expect(_currentId(tester), _sara);
  expect(_browse(tester).onPrevious, isNotNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late ZyraHapticLevel previousLevel;
  late ZyraNavStyle previousNav;

  List<MethodCall> haptics() =>
      calls.where((call) => call.method == 'HapticFeedback.vibrate').toList();

  void expectOneTick() {
    expect(haptics(), hasLength(1));
    expect(haptics().single.arguments, 'HapticFeedbackType.selectionClick');
  }

  setUp(() {
    calls.clear();
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousLevel = ZyraInteractionStyle.hapticLevel;
    previousNav = ZyraInteractionStyle.navStyle;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.subtle);
    ZyraInteractionStyle.selectNavStyle(
      ZyraInteractionStyle.currentDefaultNavStyle,
    );
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraInteractionStyle.selectHapticLevel(previousLevel);
    ZyraInteractionStyle.selectNavStyle(previousNav);
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'valid send and cancel each emit one tick without moving Browse',
    (tester) async {
      await _mount(tester);
      expect(haptics(), isEmpty, reason: 'Rendering is not a user action.');
      final index = _browse(tester).selectedIndex;
      await _tap(tester, 'draft_profile_$_sara');
      expectOneTick();
      expect(_currentId(tester), _sara);
      expect(_browse(tester).selectedIndex, index);
      expect(find.text('Journey invitation sent'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expectOneTick();
      calls.clear();
      await _tap(tester, 'draft_profile_$_sara');
      expectOneTick();
      expect(_currentId(tester), _sara);
      expect(_browse(tester).selectedIndex, index);
      expect(find.text('Request a Journey'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expectOneTick();
    },
  );

  testWidgets('Next and Back each acknowledge one valid profile move', (
    tester,
  ) async {
    await _mount(tester);
    calls.clear();
    await _tap(tester, 'concept_next_profile');
    expectOneTick();
    expect(_currentId(tester), 'draft-aisha');
    calls.clear();
    await _tap(tester, 'concept_previous_profile');
    expectOneTick();
    expect(_currentId(tester), _sara);
    expect(find.text('Journey invitation sent'), findsNothing);
  });

  testWidgets(
    'menu and photo cycling each emit one tick with no rebuild tick',
    (tester) async {
      await _mount(tester);
      calls.clear();
      await _tap(tester, 'concept_browse_menu');
      expectOneTick();
      expect(_key('concept_browse_options_navigation'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expectOneTick();
      await tester.tapAt(const Offset(150, 260));
      await tester.pumpAndSettle();
      expect(_key('concept_browse_options_navigation'), findsNothing);
      calls.clear();
      expect(_key('concept_browse_details_$_sara'), findsOneWidget);
      await _tap(tester, 'concept_browse_photo_tap_$_sara');
      expectOneTick();
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(_currentId(tester), _sara);
      expect(
        tester
            .widget<PageView>(_key('concept_browse_photo_swipe_$_sara'))
            .controller!
            .page,
        closeTo(1, .01),
      );
      await tester.pump(const Duration(seconds: 1));
      expectOneTick();
    },
  );

  testWidgets(
    'photo change emits one tick; same index and stale delegates do not',
    (tester) async {
      await _mount(tester);
      final pager = _key('concept_browse_photo_swipe_$_sara');
      calls.clear();
      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
      expectOneTick();
      final repeat = tester.widget<PageView>(pager).onPageChanged!;
      calls.clear();
      repeat(1);
      await tester.pumpAndSettle();
      expect(haptics(), isEmpty);
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
      await _tap(tester, 'concept_next_profile');
      expectOneTick();
      calls.clear();
      repeat(0);
      await tester.pumpAndSettle();
      expect(haptics(), isEmpty);
      expect(_currentId(tester), 'draft-aisha');
    },
  );

  testWidgets(
    'Off keeps valid Browse actions functional and completely silent',
    (tester) async {
      ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
      await _mount(tester);
      await _tap(tester, 'draft_profile_$_sara');
      expect(find.text('Journey invitation sent'), findsOneWidget);
      await _tap(tester, 'draft_profile_$_sara');
      expect(find.text('Request a Journey'), findsOneWidget);
      await _tap(tester, 'concept_next_profile');
      expect(_currentId(tester), 'draft-aisha');
      await _tap(tester, 'concept_previous_profile');
      expect(_currentId(tester), _sara);
      await tester.drag(
        _key('concept_browse_photo_swipe_$_sara'),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'concept_browse_menu');
      await tester.tapAt(const Offset(150, 260));
      await tester.pumpAndSettle();
      final pager = _key('concept_browse_photo_swipe_$_sara');
      final photoCount = _browse(
        tester,
      ).profiles.singleWhere((profile) => profile.id == _sara).photos.length;
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
      for (var page = 2; page <= photoCount; page++) {
        await _tap(tester, 'concept_browse_photo_tap_$_sara');
        expect(
          tester.widget<PageView>(pager).controller!.page,
          closeTo(page, .01),
        );
        expect(_currentId(tester), _sara);
        expect(haptics(), isEmpty);
      }
      await _tap(tester, 'concept_browse_photo_tap_$_sara');
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(_currentId(tester), _sara);
      expect(
        tester
            .widget<PageView>(_key('concept_browse_photo_swipe_$_sara'))
            .controller!
            .page,
        closeTo(0, .01),
      );
      expect(haptics(), isEmpty);
    },
  );

  testWidgets(
    'retained callbacks after a Browse revision cannot emit feedback',
    (tester) async {
      await _mount(tester);
      await _seedViewedHistory(tester);
      final stale = _browse(tester);
      final person = stale.profiles[stale.selectedIndex];
      final request = _action(tester, 'draft_profile_$_sara')!;
      await _tap(tester, 'concept_next_profile');
      calls.clear();
      request();
      stale.onNext!();
      stale.onPrevious!();
      stale.onRequest!(person);
      expect(stale.onProfile, isNull);
      stale.onFilters!();
      stale.onBrowseMenu!(person);
      await tester.pumpAndSettle();
      expect(haptics(), isEmpty);
      expect(_currentId(tester), 'draft-aisha');
      expect(_key('concept_browse_options_navigation'), findsNothing);
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(find.text('Journey invitation sent'), findsNothing);
    },
  );

  testWidgets('revoked shell authority cannot emit through retained actions', (
    tester,
  ) async {
    var allowed = true;
    await _mount(tester, canAct: () => allowed);
    await _seedViewedHistory(tester);
    final stale = _browse(tester);
    final person = stale.profiles[stale.selectedIndex];
    allowed = false;
    calls.clear();
    stale.onRequest!(person);
    stale.onNext!();
    stale.onPrevious!();
    expect(stale.onProfile, isNull);
    stale.onFilters!();
    stale.onBrowseMenu!(person);
    await tester.pumpAndSettle();
    expect(haptics(), isEmpty);
    expect(_currentId(tester), _sara);
    expect(find.text('Journey invitation sent'), findsNothing);
  });

  testWidgets('an incoming request has no enabled request or native feedback', (
    tester,
  ) async {
    await _mount(tester);
    expect(_browse(tester).onPrevious, isNull);
    for (var visit = 0; visit < 6; visit++) {
      await _tap(tester, 'concept_next_profile');
    }
    expect(_currentId(tester), 'draft-amira');
    expect(_action(tester, 'draft_profile_draft-amira'), isNull);
    calls.clear();
    await _tap(tester, 'draft_profile_draft-amira');
    expect(haptics(), isEmpty);
    expect(_currentId(tester), 'draft-amira');
    expect(find.text('Journey invitation sent'), findsNothing);
    expect(
      tester
          .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
          .items
          .first
          .label,
      'Profiles',
    );
  });
}
