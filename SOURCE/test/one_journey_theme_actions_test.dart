import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _simplifiedCapture = bool.fromEnvironment(
  'ZYRA_MY_ZYRA_SIMPLIFIED_CAPTURE',
);
const _capture =
    bool.fromEnvironment('ZYRA_CARD_LOCKIN_CAPTURE') || _simplifiedCapture;
const _boundary = ValueKey('one-journey-theme-actions-candidate');
const _captureRun = String.fromEnvironment(
  'ZYRA_CARD_LOCKIN_RUN',
  defaultValue: 'final',
);
const _candidates = _simplifiedCapture
    ? 'visual/candidates/my_zyra_simplified_2026_10_09/actions'
    : 'visual/candidates/journey_card_locked_2026_10_09/actions_$_captureRun';
const _people = [
  (id: 'draft-sara', name: 'Sara'),
  (id: 'draft-aisha', name: 'Aisha'),
  (id: 'draft-maryam', name: 'Maryam'),
];

Finder _key(String id) => find.byKey(ValueKey(id));

Future<void> _mount(WidgetTester tester, {bool enlarged = false}) async {
  tester.view.physicalSize = enlarged
      ? const Size(320, 568)
      : const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final top = enlarged ? 44.0 : 59.0;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(enlarged ? 2 : 1),
          padding: EdgeInsets.only(top: top, bottom: 34),
          viewPadding: EdgeInsets.only(top: top, bottom: 34),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: ViewRequestDraftScreen(
        fixture: ZyraShellTestFixture().fixture,
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Sample codecs complete on the real event loop. Wait for the protected
  // shell's prepared public deck before moving into Journey, preserving the
  // actual photo, geometry and zero-network assertions below.
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
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
}

VoidCallback _action(WidgetTester tester, String id) {
  final target = tester.widget<Widget>(_key(id));
  if (target is ButtonStyleButton) return target.onPressed!;
  if (target is InkWell) return target.onTap!;
  if (target is GestureDetector) return target.onTap!;
  final button = find.descendant(
    of: _key(id),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );
  if (button.evaluate().isNotEmpty) {
    return tester.widget<ButtonStyleButton>(button.first).onPressed!;
  }
  final ink = find.descendant(of: _key(id), matching: find.byType(InkWell));
  expect(ink, findsWidgets, reason: '$id has a labelled live action');
  return tester.widget<InkWell>(ink.first).onTap!;
}

Future<void> _press(WidgetTester tester, String id) async {
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  if (target.evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable);
    expect(scrollables, findsWidgets, reason: 'A real reading surface for $id');
    await tester.scrollUntilVisible(target, 180, scrollable: scrollables.last);
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget, reason: 'Required actual action $id');
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }
  var visible = tester
      .getRect(target)
      .intersect(Offset.zero & tester.view.physicalSize);
  final scroll = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scroll.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(scroll.first));
  }
  // The ordinary preview navigation stays present below the page. Move a
  // genuine reading surface if necessary; never call a retained action here.
  final navigation = find.byType(FloatingNavBar);
  if (navigation.evaluate().isNotEmpty &&
      find.byType(BottomSheet).evaluate().isEmpty) {
    final navTop = tester.getRect(navigation).top;
    if (visible.center.dy >= navTop && scroll.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await tester.pumpAndSettle();
      visible = tester.getRect(target).intersect(tester.getRect(scroll.first));
    }
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  final alignment = Alignment(
    local.dx * 2 / box.size.width - 1,
    local.dy * 2 / box.size.height - 1,
  );
  expect(
    target.hitTestable(at: alignment),
    findsOneWidget,
    reason: '$id must receive a real tap at ${visible.center}',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  for (
    var depth = 0;
    find.byType(ZyraShellNavigation).evaluate().isEmpty && depth < 8;
    depth++
  ) {
    if (zyraShellFixtureFor(tester).setupScopeOpen) {
      await closeZyraDevControls(tester);
      continue;
    }
    // A real Back return, never a vertical reading gesture or a controls
    // toggle. The shared helper requires the current visible return owner.
    await returnZyraPreviewPage(tester);
  }
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  final navigation = find.byType(FloatingNavBar);
  await expandZyraPreviewTabBarIfIdle(tester);
  final cell = _key('floating-nav-item-$index');
  expect(navigation, findsOneWidget);
  expect(cell, findsOneWidget);
  final box = tester.renderObject<RenderBox>(navigation);
  final local = box.globalToLocal(tester.getCenter(cell));
  expect(
    navigation.hitTestable(
      at: Alignment(
        local.dx * 2 / box.size.width - 1,
        local.dy * 2 / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(tester.getCenter(cell));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _openControls(WidgetTester tester) async {
  await _nav(tester, 1);
  await openZyraDevControls(tester);
  expect(_key('concept_journey_preview_1'), findsNothing);
}

Future<void> _seed(WidgetTester tester) async {
  await _openControls(tester);
  await _press(tester, 'concept_journey_preview_3');
}

List<ZyraOneJourneyConnectionsActiveCard> _cards(WidgetTester tester) => tester
    .widget<ZyraOneJourneyConnectionsPresentation>(
      find.byType(ZyraOneJourneyConnectionsPresentation),
    )
    .pages
    .single
    .whereType<ZyraOneJourneyConnectionsActiveCard>()
    .toList();

void _expectStates(WidgetTester tester, Map<String, String> expected) {
  final cards = _cards(tester);
  expect(cards.map((card) => card.profile.id), expected.keys);
  for (final card in cards) {
    expect(card.stateLabel, expected[card.profile.id]);
    expect(card.stageLabel, 'Salam Exchange');
  }
}

const _allActive = {
  'draft-sara': 'Active Journey',
  'draft-aisha': 'Active Journey',
  'draft-maryam': 'Active Journey',
};

void _expectLockedCompatibility(String id, String name) {
  expect(_key('draft_journey_compatibility_locked_$id'), findsOneWidget);
  expect(_key('draft_journey_compatibility_$id'), findsNothing);
  expect(find.text('Compatibility score'), findsOneWidget);
  expect(find.text('You and $name'), findsNothing);
  expect(find.text('Your result stays private'), findsOneWidget);
  expect(
    find.text('Complete Compatibility Reveal together to view your result.'),
    findsOneWidget,
  );
  expect(_key('draft_disclosure_continue_$id'), findsOneWidget);
  expect(_key('concept_compatibility_continue_$id'), findsNothing);
  expect(find.text('Your result'), findsNothing);
  expect(find.text('Your shared result'), findsNothing);
  expect(find.textContaining('%'), findsNothing);
}

Future<void> _options(WidgetTester tester, String id) async {
  await _press(tester, 'draft_journey_options_$id');
  expect(find.byType(BottomSheet), findsNothing);
  expect(_key('concept_expanded_journey_$id'), findsOneWidget);
  expect(
    tester
        .widgetList<ZyraOneJourneyConnectionsActiveCard>(
          find.byType(ZyraOneJourneyConnectionsActiveCard),
        )
        .map((card) => card.profile.id),
    [id],
    reason: 'Only the selected card renders while its options are expanded',
  );
  expect(_key('draft_options_pause_$id'), findsNothing);
  expect(find.text('Request Pause'), findsNothing);
  for (final action in [
    'end',
    'profile',
    'timeline',
    'bio',
    'compatibility',
    'guardians',
    'report',
  ]) {
    expect(_key('draft_options_${action}_$id'), findsOneWidget);
    for (final other in _people.where((person) => person.id != id)) {
      expect(_key('draft_options_${action}_${other.id}'), findsNothing);
    }
  }
  final owner = find.byType(ZyraConceptJourneyOptions);
  final options = tester.widget<ZyraConceptJourneyOptions>(owner);
  expect(options.id, id);
  expect(options.inline, isTrue);
  final fill = tester.widget<Material>(
    find.descendant(of: owner, matching: find.byType(Material)).first,
  );
  expect(fill.type, MaterialType.transparency);
}

Future<void> _dismissSheet(WidgetTester tester) async {
  final options = tester.widget<ZyraConceptJourneyOptions>(
    find.byType(ZyraConceptJourneyOptions),
  );
  if (options.inline) {
    // The same genuine card control collapses the list expansion.
    await _press(tester, 'draft_journey_options_${options.id}');
  } else {
    // Detail contexts retain their genuine modal barrier dismissal.
    await tester.tapAt(const Offset(8, 68));
  }
  await tester.pumpAndSettle();
  expect(find.byType(BottomSheet), findsNothing);
  expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
  expect(tester.takeException(), isNull);
}

Future<void> _local(WidgetTester tester, String id) async {
  if (_key(id).evaluate().isEmpty &&
      find.byType(ZyraConceptJourneyPresentation).evaluate().isNotEmpty) {
    final pager = find.descendant(
      of: find.byType(ZyraConceptJourneyPresentation),
      matching: find.byType(PageView),
    );
    if (pager.evaluate().isNotEmpty) {
      await tester.drag(pager.first, const Offset(0, -420));
      await tester.pumpAndSettle();
    }
  }
  await _press(tester, id);
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError(
      'Theme/action comparisons must not create an HTTP client.',
    );
  }
}

Future<void> _capturePage(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  await tester.pump(const Duration(seconds: 3));
  for (final widget in tester.widgetList<Image>(find.byType(Image)).toList()) {
    expect(widget.image, isA<MemoryImage>());
    final context = tester.element(find.byWidget(widget));
    await tester.runAsync(() async {
      final stream = widget.image.resolve(
        createLocalImageConfiguration(context),
      );
      final ready = Completer<void>();
      final listener = ImageStreamListener(
        (info, _) {
          info.dispose();
          if (!ready.isCompleted) ready.complete();
        },
        onError: (error, stack) {
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
    _key(_boundary.value),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        bytes!.buffer.asUint8List(),
        matchesGoldenFile('$_candidates/theme_actions_$name.png'),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFatal = WidgetController.hitTestWarningShouldBeFatal;
  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    if (!_capture) return;
    final reading = FontLoader('PoppinsThemeReview');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneThemeReview')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
  });
  tearDownAll(
    () => WidgetController.hitTestWarningShouldBeFatal = previousFatal,
  );
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _capture ? 'PoppinsThemeReview' : null;
    ZyraText.testWordmarkFontFamily = _capture ? 'SyneThemeReview' : null;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'locked overview enlarges photos and keeps the addressed Continue Journey label',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _seed(tester);
        _expectStates(tester, _allActive);
        for (final person in _people) {
          final card = find.byWidget(
            _cards(tester).firstWhere((card) => card.profile.id == person.id),
          );
          expect(
            find.descendant(of: card, matching: find.text('Active Journey')),
            findsNothing,
          );
          expect(
            find.descendant(of: card, matching: find.text('Salam Exchange')),
            findsNothing,
          );
          final photo = find.descendant(of: card, matching: find.byType(Image));
          expect(photo, findsOneWidget);
          final portrait = tester.getRect(photo);
          expect(portrait.width * portrait.height, greaterThan(104 * 104));
          final cardBounds = tester.getRect(card);
          expect(portrait.left, greaterThanOrEqualTo(cardBounds.left));
          expect(portrait.right, lessThanOrEqualTo(cardBounds.right));
          expect(portrait.top, greaterThanOrEqualTo(cardBounds.top));
          expect(portrait.bottom, lessThanOrEqualTo(cardBounds.bottom));
          final action = _key('draft_journey_${person.id}');
          expect(
            find.descendant(
              of: action,
              matching: find.text('Continue Journey'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: action, matching: find.byType(Icon)),
            findsNothing,
          );
        }
        expect(find.text('View Journey'), findsNothing);
        await _capturePage(tester, 'locked_overview');
        await _press(tester, 'draft_journey_draft-sara');
        await _press(tester, 'concept_journey_arrival_continue');
        await _local(tester, 'draft_salam_draft-sara');
        await _nav(tester, 1);
        expect(
          find.descendant(
            of: _key('draft_journey_draft-sara'),
            matching: find.text('Continue Journey'),
          ),
          findsOneWidget,
        );
        for (final id in ['draft-aisha', 'draft-maryam']) {
          expect(
            find.descendant(
              of: _key('draft_journey_$id'),
              matching: find.text('Continue Journey'),
            ),
            findsOneWidget,
          );
        }
        _expectStates(tester, _allActive);
        await _capturePage(tester, 'started_overview');
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'Inline Options single flight and repeated compatibility selection keep one owner',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      final open = _action(tester, 'draft_journey_options_draft-aisha');
      open();
      open();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(_key('concept_expanded_journey_draft-aisha'), findsOneWidget);
      expect(find.byType(ZyraConceptJourneyOptions), findsOneWidget);
      final select = _action(tester, 'draft_options_compatibility_draft-aisha');
      select();
      select();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      _expectLockedCompatibility('draft-aisha', 'Aisha');
      final staleContinue = _action(
        tester,
        'draft_disclosure_continue_draft-aisha',
      );
      await _nav(tester, 1);
      staleContinue();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraConceptJourneyPresentation), findsNothing);
      expect(
        _key('draft_journey_compatibility_locked_draft-aisha'),
        findsNothing,
      );
      _expectStates(tester, _allActive);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'locked card Options route the actual person and cancel without mutation',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _seed(tester);
        for (final person in _people) {
          final action = tester.getRect(_key('draft_journey_${person.id}'));
          final options = tester.getRect(
            _key('draft_journey_options_${person.id}'),
          );
          final card = tester.getRect(
            find.byWidget(
              _cards(tester).firstWhere((card) => card.profile.id == person.id),
            ),
          );
          expect(options.height, closeTo(37.2, .01));
          expect(options.width, closeTo(37.2, .01));
          expect(options.top, closeTo(card.top + 12, .01));
          expect(options.right, closeTo(card.right - 12, .01));
          expect(options.bottom, lessThan(action.top));
          expect(options.intersect(card), options);
          expect(
            options.bottom,
            lessThan(tester.getRect(find.byType(FloatingNavBar)).top),
          );
          await _options(tester, person.id);
          if (person.id == 'draft-aisha') {
            await _capturePage(tester, 'options');
          }
          await _press(tester, 'draft_options_profile_${person.id}');
          expect(find.byType(BottomSheet), findsNothing);
          expect(
            tester
                .widget<ZyraOneJourneyBrowsePresentation>(
                  find.byType(ZyraOneJourneyBrowsePresentation),
                )
                .profile
                .id,
            person.id,
          );
          await _nav(tester, 1);
          await _options(tester, person.id);
          await _press(tester, 'draft_options_timeline_${person.id}');
          expect(find.text('Timeline'), findsOneWidget);
          expect(find.byType(BottomSheet), findsNothing);
          await _nav(tester, 1);
          await _options(tester, person.id);
          await _press(tester, 'draft_options_compatibility_${person.id}');
          _expectLockedCompatibility(person.id, person.name);
          expect(find.byType(BottomSheet), findsNothing);
          if (person.id == 'draft-aisha') {
            await _capturePage(tester, 'compatibility_hold');
          }
          await _press(tester, 'draft_disclosure_continue_${person.id}');
          expect(
            tester
                .widget<ZyraConceptJourneyPresentation>(
                  find.byType(ZyraConceptJourneyPresentation),
                )
                .firstName,
            person.name,
          );
          await _nav(tester, 1);
          _expectStates(tester, _allActive);
          await _options(tester, person.id);
          await _press(tester, 'draft_options_guardians_${person.id}');
          expect(_key('draft_journey_guardians_${person.id}'), findsOneWidget);
          expect(
            find.descendant(
              of: _key('draft_journey_guardians_${person.id}'),
              matching: find.text('Journey with ${person.name}'),
            ),
            findsWidgets,
          );
          expect(find.byType(BottomSheet), findsNothing);
          if (person.id == 'draft-aisha') {
            await _capturePage(tester, 'guardians_context');
          }
          await _nav(tester, 1);
          _expectStates(tester, _allActive);
          for (final intent in ['end']) {
            await _options(tester, person.id);
            await _press(tester, 'draft_options_${intent}_${person.id}');
            expect(_key('draft_journey_action_${person.id}'), findsOneWidget);
            expect(find.text('End with ${person.name}?'), findsOneWidget);
            expect(find.byType(BottomSheet), findsNothing);
            if (person.id == 'draft-aisha') {
              await _capturePage(tester, '${intent}_confirmation');
            }
            await _press(tester, 'draft_cancel_journey_action_${person.id}');
            _expectStates(tester, _allActive);
            expect(_key('draft_journey_action_${person.id}'), findsNothing);
          }
        }
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'two immediate End callbacks end the addressed Journey only once',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _options(tester, 'draft-maryam');
      await _press(tester, 'draft_options_end_draft-maryam');
      final confirm = _action(tester, 'draft_confirm_end_draft-maryam');
      confirm();
      confirm();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_key('draft_journey_action_draft-maryam'), findsNothing);
      await _nav(tester, 1);
      _expectStates(tester, {
        'draft-sara': 'Active Journey',
        'draft-aisha': 'Active Journey',
      });
      confirm();
      await tester.pumpAndSettle();
      _expectStates(tester, {
        'draft-sara': 'Active Journey',
        'draft-aisha': 'Active Journey',
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('locked card confirmed End affects only its addressed Journey', (
    tester,
  ) async {
    final network = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      await _mount(tester);
      await _seed(tester);
      _expectStates(tester, _allActive);
      await _options(tester, 'draft-maryam');
      await _press(tester, 'draft_options_end_draft-maryam');
      final staleEnd = _action(tester, 'draft_confirm_end_draft-maryam');
      await _press(tester, 'draft_confirm_end_draft-maryam');
      await _nav(tester, 1);
      _expectStates(tester, {
        'draft-sara': 'Active Journey',
        'draft-aisha': 'Active Journey',
      });
      staleEnd();
      await tester.pumpAndSettle();
      _expectStates(tester, {
        'draft-sara': 'Active Journey',
        'draft-aisha': 'Active Journey',
      });
      await _nav(tester, 2);
      await _press(tester, 'my-zyra-route-concept-my-ended');
      expect(find.textContaining('Ended Journey'), findsWidgets);
      expect(find.textContaining('Maryam'), findsWidgets);
      await _press(tester, 'draft_journey_options_draft-maryam');
      expect(_key('draft_options_archive_draft-maryam'), findsNothing);
      expect(find.text('View archive'), findsNothing);
      await _press(tester, 'draft_options_timeline_draft-maryam');
      expect(find.text('Journey with Maryam'), findsOneWidget);
      expect(_key('draft_pause_draft-maryam'), findsNothing);
      expect(_key('draft_end_draft-maryam'), findsNothing);
      expect(_key('draft_resume_draft-maryam'), findsNothing);
      final history = tester.widget<ZyraDraftTimelinePresentation>(
        find.byType(ZyraDraftTimelinePresentation),
      );
      expect(history.subjectId, 'draft-maryam');
      expect(history.view.frozen, isTrue);
      expect(history.onPropose, isNull);
      expect(history.onConfirm, isNull);
      expect(history.onNotYet, isNull);
      expect(
        history.view.entries.map((entry) => entry.type),
        containsAll(['match_created', 'journey_started', 'journey_ended']),
      );
      expect(_key('concept_message'), findsNothing);
      expect(_key('concept_send_message'), findsNothing);
      await _nav(tester, 1);
    }, network);
    expect(network.attempts, 0);
  });

  testWidgets('simplified active Journey has no Pause action or Paused route', (
    tester,
  ) async {
    await _mount(tester);
    await _seed(tester);
    await _press(tester, 'draft_journey_draft-aisha');
    await _press(tester, 'concept_journey_arrival_continue');
    await _local(tester, 'draft_salam_draft-aisha');
    for (final control in [
      'draft_peer_salam_draft-aisha',
      'draft_stage_ready_draft-aisha',
      'draft_stage_peer_ready_draft-aisha',
      'draft_stage_next_draft-aisha',
    ]) {
      await _local(tester, control);
    }
    expect(_key('draft_pause_draft-aisha'), findsNothing);
    expect(_key('draft_agree_pause_draft-aisha'), findsNothing);
    expect(_key('draft_resume_draft-aisha'), findsNothing);
    expect(_key('draft_keep_paused_draft-aisha'), findsNothing);
    expect(find.textContaining('Continue, pause'), findsNothing);
    await _capturePage(tester, 'active_controls_no_pause');
    await _nav(tester, 1);
    expect(
      _cards(tester).map((card) => card.stateLabel),
      everyElement('Active Journey'),
    );
    await _options(tester, 'draft-aisha');
    expect(_key('draft_options_pause_draft-aisha'), findsNothing);
    await _dismissSheet(tester);
    await _nav(tester, 2);
    expect(_key('my-zyra-route-concept-my-paused'), findsNothing);
    expect(_key('my-zyra-route-concept-saved'), findsNothing);
    expect(find.text('Paused Journeys'), findsNothing);
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Now'), findsNothing);
    expect(find.text('Insights'), findsNothing);
    expect(_key('my-zyra-pages'), findsNothing);
    expect(
      find.byType(PageView),
      findsNothing,
      reason: 'There is no My ZYRA page slider in the simplified preview',
    );
    await _capturePage(tester, 'single_my_zyra');
  });

  testWidgets(
    'locked enlarged cards keep Options and confirmations reachable',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester, enlarged: true);
        await _seed(tester);
        for (final person in _people) {
          await _options(tester, person.id);
          await _press(tester, 'draft_options_compatibility_${person.id}');
          _expectLockedCompatibility(person.id, person.name);
          await _press(tester, 'draft_disclosure_continue_${person.id}');
          expect(
            tester
                .widget<ZyraConceptJourneyPresentation>(
                  find.byType(ZyraConceptJourneyPresentation),
                )
                .firstName,
            person.name,
          );
          await _nav(tester, 1);
          await _options(tester, person.id);
          await _press(tester, 'draft_options_guardians_${person.id}');
          expect(_key('draft_journey_guardians_${person.id}'), findsOneWidget);
          expect(
            find.descendant(
              of: _key('draft_journey_guardians_${person.id}'),
              matching: find.text('Journey with ${person.name}'),
            ),
            findsWidgets,
          );
          await _nav(tester, 1);
          await _options(tester, person.id);
          for (final intent in ['end']) {
            if (find.byType(ZyraConceptJourneyOptions).evaluate().isEmpty) {
              await _options(tester, person.id);
            }
            if (person.id == 'draft-maryam') {
              await _capturePage(tester, 'options_${intent}_compact200');
            }
            await _press(tester, 'draft_options_${intent}_${person.id}');
            expect(
              _key('draft_confirm_${intent}_${person.id}'),
              findsOneWidget,
            );
            if (person.id == 'draft-maryam') {
              await _capturePage(tester, '${intent}_compact200');
            }
            await _press(tester, 'draft_cancel_journey_action_${person.id}');
            _expectStates(tester, _allActive);
          }
          await _press(tester, 'draft_journey_${person.id}');
          expect(
            tester
                .widget<ZyraConceptJourneyPresentation>(
                  find.byType(ZyraConceptJourneyPresentation),
                )
                .firstName,
            person.name,
          );
          await _nav(tester, 1);
        }
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'cancelled sheet and confirmation delegates cannot act on another person',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _options(tester, 'draft-aisha');
      final staleSheetEnd = _action(tester, 'draft_options_end_draft-aisha');
      await _dismissSheet(tester);
      await _options(tester, 'draft-maryam');
      staleSheetEnd();
      await tester.pumpAndSettle();
      expect(_key('draft_options_end_draft-maryam'), findsOneWidget);
      expect(_key('draft_journey_action_draft-aisha'), findsNothing);
      await _press(tester, 'draft_options_end_draft-maryam');
      final staleMaryamEnd = _action(tester, 'draft_confirm_end_draft-maryam');
      await _press(tester, 'draft_cancel_journey_action_draft-maryam');
      await _options(tester, 'draft-aisha');
      await _press(tester, 'draft_options_end_draft-aisha');
      staleMaryamEnd();
      await tester.pumpAndSettle();
      expect(_key('draft_journey_action_draft-aisha'), findsOneWidget);
      await _press(tester, 'draft_cancel_journey_action_draft-aisha');
      _expectStates(tester, _allActive);
    },
  );

  for (final surface in ['inline options', 'confirmation']) {
    for (final change in ['revocation', 'ABA', 'account generation']) {
      testWidgets('$surface refuses stale actions after $change', (
        tester,
      ) async {
        await _mount(tester);
        await _seed(tester);
        await _options(tester, 'draft-aisha');
        if (surface == 'confirmation') {
          await _press(tester, 'draft_options_end_draft-aisha');
        }
        final stale = surface == 'inline options'
            ? [
                    'end',
                    'profile',
                    'timeline',
                    'bio',
                    'compatibility',
                    'guardians',
                    'report',
                  ]
                  .map(
                    (action) =>
                        _action(tester, 'draft_options_${action}_draft-aisha'),
                  )
                  .toList()
            : [
                _action(tester, 'draft_confirm_end_draft-aisha'),
                _action(tester, 'draft_cancel_journey_action_draft-aisha'),
              ];
        if (change == 'account generation') {
          ZyraAccountState.resetForTesting();
          AppState.instance.resetForAccountChange();
        } else {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          if (change == 'ABA') {
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
        }
        for (final callback in stale) {
          callback();
        }
        await tester.pumpAndSettle();
        expect(find.text('Preview closed'), findsOneWidget);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        expect(find.byType(BottomSheet), findsNothing);
        expect(_key('draft_journey_action_draft-aisha'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'authorized role change invalidates previously collapsed inline actions',
    (tester) async {
      await _mount(tester);
      await _seed(tester);
      await _options(tester, 'draft-aisha');
      final staleEnd = _action(tester, 'draft_options_end_draft-aisha');
      await _dismissSheet(tester);
      await _openControls(tester);
      await _press(tester, 'draft_role_guardian');
      staleEnd();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(_key('draft_journey_action_draft-aisha'), findsNothing);
      expect(
        tester
            .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
            .items
            .map((item) => item.label),
        ['Dashboard', 'Network', 'Seekers', 'Profile'],
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'theme and local Journey choices never change member authority or preferences',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        SharedPreferences.setMockInitialValues({
          'ordinary-setting': 'preserved',
        });
        final prefs = await tester.runAsync(SharedPreferences.getInstance);
        Map<String, Object?> snapshot() => {
          for (final key in prefs!.getKeys()) key: prefs.get(key),
        };
        final previous = snapshot();
        final app = AppState.instance;
        app
          ..name = 'Unchanged member'
          ..surnameLine = 'Unchanged surname'
          ..photos = ['unchanged-photo']
          ..plan = ZyraPlan.one;
        final saved = List.of(app.saved);
        final active = List.of(app.activeJourneys);
        final potential = List.of(app.potentialJourneys);
        final generation = ZyraAccountState.generation;
        final userId = ZyraAccountState.userId;
        final palette = ZyraColors.devPalette;
        final gold = ZyraAppGoldStyle.instance.enabled;
        final font = ZyraText.appFont;
        final haptic = ZyraInteractionStyle.hapticLevel;
        var changes = 0;
        void changed() => changes++;
        app.addListener(changed);
        addTearDown(() => app.removeListener(changed));
        await _mount(tester);
        await _seed(tester);
        await _options(tester, 'draft-aisha');
        await _press(tester, 'draft_options_compatibility_draft-aisha');
        _expectLockedCompatibility('draft-aisha', 'Aisha');
        await _nav(tester, 1);
        await _options(tester, 'draft-maryam');
        await _press(tester, 'draft_options_end_draft-maryam');
        await _press(tester, 'draft_confirm_end_draft-maryam');
        await _nav(tester, 1);
        await _openControls(tester);
        expect(find.text('Journey card content'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'concept_journey_card_design_',
                ),
          ),
          findsNothing,
        );
        await _capturePage(tester, 'compact_controls');
        expect(snapshot(), previous);
        expect(app.name, 'Unchanged member');
        expect(app.surnameLine, 'Unchanged surname');
        expect(app.photos, ['unchanged-photo']);
        expect(app.plan, ZyraPlan.one);
        expect(app.saved, saved);
        expect(app.activeJourneys, active);
        expect(app.potentialJourneys, potential);
        expect(ZyraAccountState.generation, generation);
        expect(ZyraAccountState.userId, userId);
        expect(ZyraColors.devPalette, palette);
        expect(ZyraAppGoldStyle.instance.enabled, gold);
        expect(ZyraText.appFont, font);
        expect(ZyraInteractionStyle.hapticLevel, haptic);
        expect(changes, 0);
        expect(() => Supabase.instance, throwsA(isA<AssertionError>()));
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );
}
