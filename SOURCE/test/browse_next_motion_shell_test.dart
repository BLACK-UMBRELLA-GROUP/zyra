// Protected, synthetic, offline shell evidence. A visual choice never grants
// request, member, preference, credit or provider authority.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_next_photo_motion.dart';
import 'package:zyra/widgets/zyra_invitation_outline.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _boundary = ValueKey('browse-next-motion-candidate');
const _captureDirectory = String.fromEnvironment(
  'ZYRA_BROWSE_NEXT_MOTION_CAPTURE_DIR',
);
const _capture = _captureDirectory != '';
const _font = 'PoppinsBrowseNextMotion';

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _motionFinder => _key('concept_browse_next_motion');
Finder get _motionDropdown =>
    find.byType(DropdownButtonFormField<ZyraBrowseNextMotion>);
Finder get _screenRing => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('concept_browse_screen_invitation_frame_');
});

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Next-motion shell tests must remain offline.');
  }
}

ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );

ZyraBrowseNextPhotoMotion _motion(WidgetTester tester) =>
    tester.widget<ZyraBrowseNextPhotoMotion>(_motionFinder);

List<double> _motionMatrix(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(
        of: _motionFinder,
        matching: _key('browse_next_motion_transform'),
      ),
    )
    .transform
    .storage
    .toList(growable: false);

RenderBox _cardBox(WidgetTester tester) => tester.renderObject<RenderBox>(
  find
      .ancestor(
        of: _key('concept_browse_open_${_selectedId(tester)}'),
        matching: find.byType(Material),
      )
      .first,
);

void _expectContainedCard(WidgetTester tester) {
  final slot = tester.getRect(_key('browse_next_motion_clip'));
  final box = _cardBox(tester);
  for (final corner in [
    Offset.zero,
    Offset(box.size.width, 0),
    Offset(box.size.width, box.size.height),
    Offset(0, box.size.height),
  ]) {
    final projected = box.localToGlobal(corner);
    expect(projected.dx, greaterThanOrEqualTo(slot.left - .001));
    expect(projected.dx, lessThanOrEqualTo(slot.right + .001));
    expect(projected.dy, greaterThanOrEqualTo(slot.top - .001));
    expect(projected.dy, lessThanOrEqualTo(slot.bottom + .001));
  }
}

List<String> _detailsText(SeekerProfile person) => [
  person.firstName,
  if (person.surnameLine?.trim().isNotEmpty ?? false)
    person.surnameLine!.trim(),
  if (person.age > 0) ...['Age', '${person.age}'],
  if (person.city.trim().isNotEmpty && person.city.trim() != '—') ...[
    'Location',
    person.city.trim(),
  ],
  if (person.publicNationality?.trim().isNotEmpty ?? false) ...[
    'Nationality',
    person.publicNationality!.trim(),
  ],
  if (person.publicEthnicity?.trim().isNotEmpty ?? false) ...[
    'Ethnicity',
    person.publicEthnicity!.trim(),
  ],
];

void _expectMovingContent(WidgetTester tester, Finder content, String label) {
  expect(content, findsOneWidget);
  expect(
    find.ancestor(of: content, matching: _key('browse_next_motion_transform')),
    findsOneWidget,
    reason: '$label must move with the entire card.',
  );
  expect(
    find.ancestor(of: content, matching: _key('browse_next_motion_filter')),
    findsNothing,
    reason: '$label must not have a separate photo effect.',
  );
}

Map<String, Rect> _overlayBounds(
  WidgetTester tester, {
  bool includeContent = true,
}) {
  final id = _selectedId(tester);
  final person = _browse(tester).profiles.firstWhere((p) => p.id == id);
  final outline = _key('browse_invitation_outline_$id');
  final overlays = <String, Finder>{'invitation outline': outline};
  if (includeContent) {
    final details = _key('concept_browse_details_$id');
    expect(details, findsOneWidget);
    overlays['public details'] = details;
    final texts = find.descendant(of: details, matching: find.byType(Text));
    expect(
      tester.widgetList<Text>(texts).map((text) => text.data),
      orderedEquals(_detailsText(person)),
    );
    var detailIndex = 0;
    for (final element in texts.evaluate()) {
      overlays['name/detail ${detailIndex++}'] = find.byElementPredicate(
        (candidate) => identical(candidate, element),
      );
    }
    expect(detailIndex, greaterThanOrEqualTo(3));
    expect(_key('concept_browse_identity_$id'), findsNothing);
  }
  final bounds = <String, Rect>{};
  final card = _cardBox(tester);
  for (final overlay in overlays.entries) {
    _expectMovingContent(tester, overlay.value, overlay.key);
    final box = tester.renderObject<RenderBox>(overlay.value);
    bounds[overlay.key] =
        box.localToGlobal(Offset.zero, ancestor: card) & box.size;
  }
  if (person.photos.isNotEmpty) {
    final pagination = _key('concept_browse_photo_pagination');
    expect(pagination, findsOneWidget);
    for (final finder in [
      pagination,
      for (var index = 0; index <= person.photos.length; index++)
        _key('concept_browse_photo_dot_${id}_$index'),
    ]) {
      expect(finder, findsOneWidget);
      for (final effect in [
        'browse_next_motion_transform',
        'browse_next_motion_filter',
      ]) {
        expect(
          find.ancestor(of: finder, matching: _key(effect)),
          findsNothing,
          reason: 'Header pagination is static app chrome above the card.',
        );
      }
    }
    // Card overlays above are compared in card-local coordinates. Pagination
    // deliberately uses screen coordinates: its external row must not move.
    bounds['pagination (static screen space)'] = tester.getRect(pagination);
  }
  return bounds;
}

Map<String, Rect> _pageContentBounds(
  WidgetTester tester, {
  required bool photo,
}) {
  final id = _selectedId(tester);
  final person = _browse(tester).profiles.firstWhere((p) => p.id == id);
  final identity = _key('concept_browse_identity_$id');
  final content = photo
      ? _key('concept_browse_photo_${id}_0')
      : _key('concept_browse_details_$id');
  _expectMovingContent(tester, content, photo ? 'Clean photo' : 'Details');
  final page = photo
      ? find.ancestor(of: content, matching: find.byType(Stack)).first
      : content;
  expect(page, findsOneWidget);
  if (photo) {
    expect(identity, findsNothing);
    expect(
      find.descendant(of: page, matching: _key('concept_browse_photo_${id}_0')),
      findsOneWidget,
      reason: 'The overlapping page is this person’s first real photo.',
    );
  }
  final texts = find.descendant(of: content, matching: find.byType(Text));
  final values = tester
      .widgetList<Text>(texts)
      .map((text) => text.data)
      .toList();
  if (photo) {
    expect(
      values,
      isEmpty,
      reason: 'Details-first photos have no identity copy.',
    );
  } else {
    expect(values, orderedEquals(_detailsText(person)));
  }
  final pageBox = tester.renderObject<RenderBox>(page);
  final contentBox = tester.renderObject<RenderBox>(content);
  final bounds = <String, Rect>{
    'page': Offset.zero & pageBox.size,
    'photo/details':
        contentBox.localToGlobal(Offset.zero, ancestor: pageBox) &
        contentBox.size,
  };
  var index = 0;
  for (final element in texts.evaluate()) {
    final text = find.byElementPredicate(
      (candidate) => identical(candidate, element),
    );
    _expectMovingContent(tester, text, 'Page text $index');
    final box = tester.renderObject<RenderBox>(text);
    // Horizontal gallery movement belongs to this page. Its content keeps
    // exact local geometry while the outer Next transform animates the card.
    bounds['text ${index++}'] =
        box.localToGlobal(Offset.zero, ancestor: pageBox) & box.size;
  }
  return bounds;
}

void _expectIdentityMatrix(List<double> matrix) {
  for (var index = 0; index < matrix.length; index++) {
    expect(matrix[index], closeTo(index % 5 == 0 ? 1 : 0, .000001));
  }
}

void _expectRest(WidgetTester tester) {
  _expectIdentityMatrix(_motionMatrix(tester));
  expect(_key('browse_next_motion_filter'), findsNothing);
  _expectContainedCard(tester);
  expect(
    tester.getRect(_key('concept_browse_open_${_selectedId(tester)}')),
    tester.getRect(_key('concept_browse_portrait_card')),
  );
}

void _expectActiveMotion(
  WidgetTester tester,
  ZyraBrowseNextMotion style, {
  required int milliseconds,
}) {
  final matrix = _motionMatrix(tester);
  final reason = '${style.name} must visibly enter at $milliseconds ms.';
  if (style == ZyraBrowseNextMotion.current) {
    _expectRest(tester);
    return;
  }
  expect(_key('browse_next_motion_filter'), findsNothing);
  _expectContainedCard(tester);
  final card = _cardBox(tester).size;
  var distance = 0.0;
  for (var index = 0; index < matrix.length; index++) {
    distance += (matrix[index] - (index % 5 == 0 ? 1 : 0)).abs();
  }
  expect(distance, greaterThan(.05), reason: reason);
  // Defining movement is measured in the real shell, including the uniform
  // containment fit. This rejects an inactive choice or common subtle zoom.
  switch (style) {
    case ZyraBrowseNextMotion.cardGlide:
      expect(matrix[12], greaterThan(card.width * .025), reason: reason);
      expect(matrix[13], closeTo(0, .000001));
    case ZyraBrowseNextMotion.cardRise:
      expect(matrix[13], greaterThan(card.height * .03), reason: reason);
      expect(matrix[12], closeTo(0, .000001));
    case ZyraBrowseNextMotion.springPop:
      expect(matrix[0], lessThan(.985), reason: reason);
      expect(matrix[0], greaterThan(.58), reason: reason);
      expect(matrix[5], closeTo(matrix[0], .000001));
      expect(matrix[12], closeTo(0, .000001));
      expect(matrix[13], closeTo(0, .000001));
      expect(matrix[1], closeTo(0, .000001));
      expect(matrix[8], closeTo(0, .000001));
    case ZyraBrowseNextMotion.cardRock:
      expect(matrix[1].abs(), greaterThan(.015), reason: reason);
      expect(matrix[4], closeTo(-matrix[1], .000001));
      expect(matrix[12], closeTo(0, .000001));
      expect(matrix[13], closeTo(0, .000001));
    case ZyraBrowseNextMotion.fanTurn:
      expect(matrix[1], lessThan(-.035), reason: reason);
      expect(matrix[4], greaterThan(.035), reason: reason);
      expect(matrix[13], greaterThan(card.height * .015), reason: reason);
      expect(matrix[12], closeTo(0, .000001));
    case ZyraBrowseNextMotion.hingeTurn:
      expect(matrix[8], greaterThan(.18), reason: reason);
      expect(matrix[3], lessThan(0), reason: reason);
      expect(matrix[11], greaterThan(0), reason: reason);
      expect(matrix[12], lessThan(-card.width * .015), reason: reason);
    case ZyraBrowseNextMotion.cardDeal:
      expect(matrix[12], greaterThan(card.width * .025), reason: reason);
      expect(matrix[13], lessThan(-card.height * .03), reason: reason);
      expect(matrix[1], greaterThan(.025), reason: reason);
    case ZyraBrowseNextMotion.forwardFlip:
      expect(matrix[6], lessThan(-.15), reason: reason);
      expect(matrix[9], greaterThan(.15), reason: reason);
      expect(matrix[13], greaterThan(card.height * .007), reason: reason);
    case ZyraBrowseNextMotion.arcEntrance:
      if (milliseconds <= 180) {
        expect(matrix[12], lessThan(-card.width * .025), reason: reason);
      } else {
        expect(matrix[12], greaterThan(card.width * .01), reason: reason);
      }
      if (milliseconds == 0) {
        expect(matrix[13], closeTo(0, .000001));
      } else {
        expect(matrix[13], greaterThan(card.height * .02), reason: reason);
      }
    case ZyraBrowseNextMotion.elasticCard:
      expect(matrix[5] / matrix[0], greaterThan(1.03), reason: reason);
      expect(matrix[12], closeTo(0, .000001));
      expect(matrix[13], closeTo(0, .000001));
    case ZyraBrowseNextMotion.current:
      break;
  }
}

String _selectedId(WidgetTester tester) {
  final browse = _browse(tester);
  return browse.profiles[browse.selectedIndex].id;
}

Future<void> _mount(
  WidgetTester tester, {
  bool quiet = false,
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
  expect(_screenRing, findsNothing);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _tap(WidgetTester tester, String id, {bool settle = true}) async {
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  var visible = tester
      .getRect(target)
      .intersect(Offset.zero & tester.view.physicalSize);
  final scroll = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scroll.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(scroll.first));
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  expect(
    target.hitTestable(
      at: Alignment(
        2 * local.dx / box.size.width - 1,
        2 * local.dy / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(visible.center);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  expect(tester.takeException(), isNull);
  expect(_screenRing, findsNothing);
}

Future<void> _tapBar(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final nav = tester.widget<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  final index = nav.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  final icon = find.descendant(
    of: find.byType(ZyraShellNavigation),
    matching: find.byIcon(nav.items[index].icon),
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
  expect(_screenRing, findsNothing);
}

Future<void> _openControls(WidgetTester tester) async {
  for (
    var depth = 0;
    _key('concept_page_options_context').evaluate().isEmpty && depth < 8;
    depth++
  ) {
    await _tap(tester, 'draft_back');
  }
  expect(find.text('Page options'), findsOneWidget);
  expect(_key('concept_page_options_context'), findsOneWidget);
  expect(_key('draft_rules'), findsNothing);
}

Future<void> _select(WidgetTester tester, ZyraBrowseNextMotion style) async {
  final previousEpoch = _motion(tester).epoch;
  final previousId = _selectedId(tester);
  await _openControls(tester);
  expect(
    tester.widget<Text>(_key('concept_page_options_context')).data,
    'Profiles',
  );
  expect(find.text('Next animation'), findsOneWidget);
  expect(_key('concept_journey_preview_1'), findsNothing);
  expect(ZyraBrowseNextMotion.values, hasLength(11));
  expect(_motionDropdown, findsOneWidget);
  await tester.ensureVisible(_motionDropdown);
  await tester.pumpAndSettle();
  final selected = tester
      .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(_motionDropdown)
      .initialValue!;
  await tester.tap(_motionDropdown);
  await tester.pumpAndSettle();
  // The button's IndexedStack also retains keyed items. Select only inside
  // the actual popup route, whose ListView builds lower choices lazily.
  final popup = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics && widget.properties.role == ui.SemanticsRole.menu,
    description: 'Next animation popup menu',
  );
  expect(popup, findsOneWidget);
  final popupScrollable = find.descendant(
    of: popup,
    matching: find.byType(Scrollable),
  );
  expect(popupScrollable, findsOneWidget);
  final option = find.descendant(
    of: popup,
    matching: _key('concept_browse_next_motion_${style.name}'),
  );
  await tester.scrollUntilVisible(
    option,
    style.index < selected.index ? -80 : 80,
    scrollable: popupScrollable,
    maxScrolls: 24,
  );
  await tester.pumpAndSettle();
  expect(option, findsOneWidget);
  // DropdownMenuItem is aligned content, not the popup's pointer receiver.
  // Its blank centre need not hit its descendants; the native enabled InkWell
  // wrapping this exact keyed choice owns the real selection action.
  final receiver = find
      .ancestor(
        of: option,
        matching: find.byWidgetPredicate(
          (widget) => widget is InkWell && widget.onTap != null,
        ),
      )
      .first;
  expect(receiver, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(receiver), alignment: 0.5);
  await tester.pumpAndSettle();
  final rect = tester.getRect(receiver);
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  final visible = rect
      .intersect(tester.getRect(popupScrollable))
      .intersect(Offset.zero & logicalSize);
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final point = Alignment(
    2 * (visible.center.dx - rect.left) / rect.width - 1,
    2 * (visible.center.dy - rect.top) / rect.height - 1,
  );
  expect(
    receiver.hitTestable(at: point),
    findsOneWidget,
    reason:
        'Native popup receiver for ${style.name}: '
        'rect=$rect, visible=$visible, tap=${visible.center}.',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(popup, findsNothing);
  expect(
    tester
        .widget<DropdownButtonFormField<ZyraBrowseNextMotion>>(_motionDropdown)
        .initialValue,
    style,
  );
  await _tap(tester, 'draft_back');
  expect(_motion(tester).style, style);
  expect(_motion(tester).epoch, previousEpoch);
  expect(_selectedId(tester), previousId);
}

Future<void> _capturePage(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(_captureDirectory.startsWith('/'), isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  // The public deck is already first-frame prepared. Capturing a held motion
  // phase must not settle the animation or substitute another image source.
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
  final platformCalls = <MethodCall>[];
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
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.subtle);
    ZyraInteractionStyle.selectNavStyle(
      ZyraInteractionStyle.currentDefaultNavStyle,
    );
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _capture ? _font : null;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    platformCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
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

  testWidgets('Profiles keeps Details first without a card-mode picker', (
    tester,
  ) async {
    await _mount(tester, quiet: true);
    final original = _browse(tester);
    final id = _selectedId(tester);
    final beforePeople = original.profiles
        .map((profile) => profile.id)
        .toList();
    final beforeSent = original.invitationSent!(
      original.profiles[original.selectedIndex],
    );
    expect(_key('concept_browse_details_$id'), findsOneWidget);
    await tester.tap(_key('concept_browse_photo_tap_$id'));
    await tester.pumpAndSettle();
    final before = tester.widget<PageView>(
      _key('concept_browse_photo_swipe_$id'),
    );
    expect(before.controller!.page, closeTo(1, .001));
    await _openControls(tester);
    expect(_key('concept_browse_gallery_mode'), findsNothing);
    expect(find.text('Profile cards'), findsNothing);
    expect(find.text('Original photos'), findsNothing);
    await _tap(tester, 'draft_back');
    final updated = _browse(tester);
    expect(updated.profiles.map((profile) => profile.id), beforePeople);
    expect(_selectedId(tester), id);
    expect(
      updated.invitationSent!(updated.profiles[updated.selectedIndex]),
      beforeSent,
    );
    final after = tester.widget<PageView>(
      _key('concept_browse_photo_swipe_$id'),
    );
    expect(after.controller!.page, closeTo(1, .001));
    expect(_key('concept_browse_identity_$id'), findsNothing);
    expect(_motion(tester).epoch, 0);
    expect(tester.takeException(), isNull);
  });

  for (final style in ZyraBrowseNextMotion.values) {
    testWidgets('actual Next applies ${style.name} without moving app chrome', (
      tester,
    ) async {
      await _mount(tester);
      expect(_motion(tester).style, ZyraBrowseNextMotion.current);
      expect(_motion(tester).epoch, 0);
      await _select(tester, style);
      _expectRest(tester);
      final motionState = tester.state(_motionFinder);
      final epoch = _motion(tester).epoch;
      final header = tester.getRect(_key('concept_browse_title'));
      final footer = tester.getRect(_key('concept_browse_footer'));
      final navigation = tester.getRect(find.byType(FloatingNavBar));
      final card = tester.getRect(_key('concept_browse_portrait_card'));
      final people = _browse(tester).profiles.map((p) => p.id).toList();
      platformCalls.clear();
      await _tap(tester, 'concept_next_profile', settle: false);
      expect(_selectedId(tester), _aisha);
      expect(_motion(tester).profileId, _aisha);
      expect(_motion(tester).style, style);
      expect(_motion(tester).epoch, epoch + 1);
      expect(tester.state(_motionFinder), same(motionState));
      expect(_key('concept_browse_photo_swipe_$_sara'), findsNothing);
      expect(_key('concept_browse_identity_$_sara'), findsNothing);
      expect(_key('concept_browse_details_$_sara'), findsNothing);
      _expectActiveMotion(tester, style, milliseconds: 0);
      final overlays = _overlayBounds(tester);
      expect(tester.getRect(_key('concept_browse_title')), header);
      expect(tester.getRect(_key('concept_browse_footer')), footer);
      expect(tester.getRect(find.byType(FloatingNavBar)), navigation);
      expect(tester.getRect(_key('concept_browse_portrait_card')), card);
      await _capturePage(tester, 'browse_next_${style.name}_start_393');
      await tester.pump(const Duration(milliseconds: 180));
      _expectActiveMotion(tester, style, milliseconds: 180);
      expect(_overlayBounds(tester), overlays);
      expect(tester.getRect(_key('concept_browse_title')), header);
      expect(tester.getRect(_key('concept_browse_footer')), footer);
      expect(tester.getRect(find.byType(FloatingNavBar)), navigation);
      expect(tester.getRect(_key('concept_browse_portrait_card')), card);
      await _capturePage(tester, 'browse_next_${style.name}_180ms_393');
      await tester.pump(const Duration(milliseconds: 170));
      _expectActiveMotion(tester, style, milliseconds: 350);
      expect(_overlayBounds(tester), overlays);
      expect(tester.getRect(_key('concept_browse_title')), header);
      expect(tester.getRect(_key('concept_browse_footer')), footer);
      expect(tester.getRect(find.byType(FloatingNavBar)), navigation);
      expect(tester.getRect(_key('concept_browse_portrait_card')), card);
      expect(_browse(tester).profiles.map((p) => p.id), people);
      expect(find.text('Request sent'), findsNothing);
      final haptics = platformCalls
          .where((call) => call.method == 'HapticFeedback.vibrate')
          .toList();
      expect(haptics, hasLength(1));
      expect(haptics.single.arguments, 'HapticFeedbackType.selectionClick');
      await _capturePage(tester, 'browse_next_${style.name}_350ms_393');
      await tester.pump(const Duration(milliseconds: 750));
      _expectRest(tester);
      expect(_overlayBounds(tester), overlays);
      await tester.pumpAndSettle();
      expect(_motion(tester).epoch, epoch + 1);
      expect(_screenRing, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('all ten choices have distinct actual Next paint signatures', (
    tester,
  ) async {
    await _mount(tester);
    final signatures = <ZyraBrowseNextMotion, List<double>>{};
    for (final style in ZyraBrowseNextMotion.values) {
      if (style == ZyraBrowseNextMotion.current) continue;
      await _select(tester, style);
      _expectRest(tester);
      final motionState = tester.state(_motionFinder);
      final previousId = _selectedId(tester);
      final epoch = _motion(tester).epoch;
      await _tap(tester, 'concept_next_profile', settle: false);
      expect(_selectedId(tester), isNot(previousId));
      expect(_motion(tester).profileId, _selectedId(tester));
      expect(_motion(tester).epoch, epoch + 1);
      expect(tester.state(_motionFinder), same(motionState));
      _expectActiveMotion(tester, style, milliseconds: 0);
      signatures[style] = _motionMatrix(tester);
      await tester.pump(const Duration(milliseconds: 1100));
      _expectRest(tester);
      await tester.pumpAndSettle();
    }
    expect(signatures, hasLength(10));
    final entries = signatures.entries.toList(growable: false);
    for (var first = 0; first < entries.length; first++) {
      for (var second = first + 1; second < entries.length; second++) {
        var distance = 0.0;
        for (var index = 0; index < entries[first].value.length; index++) {
          distance +=
              (entries[first].value[index] - entries[second].value[index])
                  .abs();
        }
        expect(
          distance,
          greaterThan(.01),
          reason:
              '${entries[first].key.name} and ${entries[second].key.name} '
              'must not render the same actual Next effect.',
        );
      }
    }
    expect(_screenRing, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sent outline and identity move with the card during Next', (
    tester,
  ) async {
    await _mount(tester);
    await _select(tester, ZyraBrowseNextMotion.fanTurn);
    await _tap(tester, 'concept_next_profile');
    expect(_selectedId(tester), _aisha);
    await _tap(tester, 'draft_profile_$_aisha');
    expect(
      tester
          .widget<ZyraInvitationOutline>(
            _key('browse_invitation_outline_$_aisha'),
          )
          .sent,
      isTrue,
    );
    final settledOverlays = _overlayBounds(tester);
    final settledCard = tester.getRect(_key('concept_browse_open_$_aisha'));
    await _tap(tester, 'concept_previous_profile');
    expect(_selectedId(tester), _sara);
    final epoch = _motion(tester).epoch;
    await _tap(tester, 'concept_next_profile', settle: false);
    expect(_selectedId(tester), _aisha);
    expect(_motion(tester).epoch, epoch + 1);
    _expectActiveMotion(tester, ZyraBrowseNextMotion.fanTurn, milliseconds: 0);
    expect(_overlayBounds(tester), settledOverlays);
    expect(
      tester.getRect(_key('concept_browse_open_$_aisha')),
      isNot(settledCard),
    );
    await tester.pump(const Duration(milliseconds: 180));
    _expectActiveMotion(
      tester,
      ZyraBrowseNextMotion.fanTurn,
      milliseconds: 180,
    );
    expect(_overlayBounds(tester), settledOverlays);
    await tester.pump(const Duration(milliseconds: 170));
    _expectActiveMotion(
      tester,
      ZyraBrowseNextMotion.fanTurn,
      milliseconds: 350,
    );
    expect(_overlayBounds(tester), settledOverlays);
    await tester.pump(const Duration(milliseconds: 750));
    _expectRest(tester);
    expect(_overlayBounds(tester), settledOverlays);
    expect(tester.getRect(_key('concept_browse_open_$_aisha')), settledCard);
    expect(_screenRing, findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final swipe in const [false, true]) {
    testWidgets(
      'active Next allows current-person photo ${swipe ? 'swipe' : 'tap'}',
      (tester) async {
        await _mount(tester);
        await _select(tester, ZyraBrowseNextMotion.cardGlide);
        final motionState = tester.state(_motionFinder);
        await _tap(tester, 'concept_next_profile', settle: false);
        expect(_selectedId(tester), _aisha);
        final epoch = _motion(tester).epoch;
        final overlays = _overlayBounds(tester, includeContent: false);
        final details = _pageContentBounds(tester, photo: false);
        late Map<String, Rect> photoContent;
        final header = tester.getRect(_key('concept_browse_title'));
        final footer = tester.getRect(_key('concept_browse_footer'));
        final navigation = tester.getRect(find.byType(FloatingNavBar));
        _expectActiveMotion(
          tester,
          ZyraBrowseNextMotion.cardGlide,
          milliseconds: 0,
        );
        final photoTarget = _key('concept_browse_photo_tap_$_aisha');
        expect(photoTarget.hitTestable(), findsOneWidget);
        final photoBounds = tester.getRect(photoTarget);
        final pagerWidth = tester
            .renderObject<RenderBox>(photoTarget)
            .size
            .width;
        // Do not use _tap: its pre-action settle would conceal overlap defects.
        if (swipe) {
          final gesture = await tester.startGesture(photoBounds.center);
          // PageView uses DragStartBehavior.start: its first slop-crossing
          // move establishes the drag origin rather than scrolling a page.
          await gesture.moveBy(const Offset(-24, 0));
          // Whole-card paint scales, but transformHitTests:false leaves the
          // pager's touch/travel width at its untransformed layout size.
          await gesture.moveBy(Offset(-pagerWidth * .65, 0));
          await tester.pump(const Duration(milliseconds: 180));
          final heldPager = tester.widget<PageView>(
            _key('concept_browse_photo_swipe_$_aisha'),
          );
          expect(heldPager.controller!.page, greaterThan(.5));
          _expectActiveMotion(
            tester,
            ZyraBrowseNextMotion.cardGlide,
            milliseconds: 180,
          );
          expect(_overlayBounds(tester, includeContent: false), overlays);
          expect(_pageContentBounds(tester, photo: false), details);
          photoContent = _pageContentBounds(tester, photo: true);
          await gesture.up();
        } else {
          await tester.tapAt(photoBounds.center);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 180));
          final heldPager = tester.widget<PageView>(
            _key('concept_browse_photo_swipe_$_aisha'),
          );
          expect(heldPager.controller!.page, inExclusiveRange(0, 1));
          _expectActiveMotion(
            tester,
            ZyraBrowseNextMotion.cardGlide,
            milliseconds: 180,
          );
          expect(_overlayBounds(tester, includeContent: false), overlays);
          expect(_pageContentBounds(tester, photo: false), details);
          photoContent = _pageContentBounds(tester, photo: true);
        }
        await tester.pump(const Duration(milliseconds: 170));
        _expectActiveMotion(
          tester,
          ZyraBrowseNextMotion.cardGlide,
          milliseconds: 350,
        );
        expect(_selectedId(tester), _aisha);
        expect(_motion(tester).profileId, _aisha);
        expect(_motion(tester).epoch, epoch);
        expect(tester.state(_motionFinder), same(motionState));
        expect(_overlayBounds(tester, includeContent: false), overlays);
        expect(_pageContentBounds(tester, photo: true), photoContent);
        if (_key('concept_browse_details_$_aisha').evaluate().isNotEmpty) {
          expect(_pageContentBounds(tester, photo: false), details);
        } else {
          final completedPager = tester.widget<PageView>(
            _key('concept_browse_photo_swipe_$_aisha'),
          );
          expect(completedPager.controller!.page, closeTo(1, .000001));
        }
        expect(tester.getRect(_key('concept_browse_title')), header);
        expect(tester.getRect(_key('concept_browse_footer')), footer);
        expect(tester.getRect(find.byType(FloatingNavBar)), navigation);
        expect(_key('concept_browse_photo_swipe_$_sara'), findsNothing);
        expect(_key('concept_browse_identity_$_sara'), findsNothing);
        expect(_key('concept_browse_details_$_sara'), findsNothing);
        expect(find.text('Request sent'), findsNothing);
        await tester.pump(const Duration(milliseconds: 750));
        await tester.pumpAndSettle();
        final pager = tester.widget<PageView>(
          _key('concept_browse_photo_swipe_$_aisha'),
        );
        expect(pager.controller!.page, closeTo(1, .000001));
        _expectRest(tester);
        expect(_overlayBounds(tester, includeContent: false), overlays);
        expect(_pageContentBounds(tester, photo: true), photoContent);
        expect(_selectedId(tester), _aisha);
        expect(_motion(tester).epoch, epoch);
        expect(_screenRing, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Back photos requests and filters do not emit a Next epoch', (
    tester,
  ) async {
    await _mount(tester);
    await _select(tester, ZyraBrowseNextMotion.values[1]);
    await _tap(tester, 'concept_next_profile');
    final epoch = _motion(tester).epoch;
    await _tap(tester, 'concept_previous_profile', settle: false);
    expect(_selectedId(tester), _sara);
    expect(_motion(tester).epoch, epoch);
    _expectRest(tester);
    await tester.pump(const Duration(milliseconds: 80));
    _expectRest(tester);
    await _tap(tester, 'concept_browse_photo_tap_$_sara', settle: false);
    expect(_motion(tester).epoch, epoch);
    _expectRest(tester);
    await tester.pump(const Duration(milliseconds: 80));
    _expectRest(tester);
    await _tap(tester, 'draft_profile_$_sara', settle: false);
    expect(find.text('Request sent'), findsOneWidget);
    expect(_motion(tester).epoch, epoch);
    _expectRest(tester);
    await _tap(tester, 'draft_profile_$_sara', settle: false);
    expect(find.text('Request a Journey'), findsOneWidget);
    expect(_motion(tester).epoch, epoch);
    _expectRest(tester);
    await _tap(tester, 'concept_browse_menu');
    await _tapBar(tester, 'Filters');
    expect(_motionFinder, findsNothing);
    await _tap(tester, 'concept_age_1');
    tester.widget<RangeSlider>(_key('concept_age_range')).onChanged!(
      const RangeValues(29, 70),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'concept_apply_filter', settle: false);
    expect(_browse(tester).profiles.every((p) => p.age >= 29), isTrue);
    expect(_motion(tester).epoch, epoch);
    _expectRest(tester);
    await tester.pump(const Duration(milliseconds: 160));
    _expectRest(tester);
    expect(_screenRing, findsNothing);
  });

  testWidgets(
    'forward replay advances exactly one epoch and preserves history',
    (tester) async {
      await _mount(tester, quiet: true);
      await _select(tester, ZyraBrowseNextMotion.values[1]);
      await _tap(tester, 'concept_next_profile');
      final epoch = _motion(tester).epoch;
      await _tap(tester, 'concept_previous_profile');
      expect(_selectedId(tester), _sara);
      expect(_motion(tester).epoch, epoch);
      await _tap(tester, 'concept_next_profile');
      expect(_selectedId(tester), _aisha);
      expect(_motion(tester).epoch, epoch + 1);
    },
  );

  testWidgets('retained Next and request delegates cannot borrow a new owner', (
    tester,
  ) async {
    var allowed = true;
    await _mount(tester, quiet: true, canAct: () => allowed);
    await _select(tester, ZyraBrowseNextMotion.values[1]);
    final next = _browse(tester).onNext!;
    final request = _browse(tester).onRequest!;
    final oldPerson = _browse(tester).profiles.firstWhere((p) => p.id == _sara);
    await _tap(tester, 'concept_next_profile');
    final epoch = _motion(tester).epoch;
    next();
    request(oldPerson);
    await tester.pumpAndSettle();
    expect(_selectedId(tester), _aisha);
    expect(_motion(tester).epoch, epoch);
    expect(find.text('Request sent'), findsNothing);
    final currentNext = _browse(tester).onNext!;
    allowed = false;
    tester.element(find.byType(ZyraOneJourneyConceptShell)).markNeedsBuild();
    await tester.pumpAndSettle();
    currentNext();
    await tester.pumpAndSettle();
    expect(_selectedId(tester), _aisha);
    expect(_motion(tester).epoch, epoch);
    expect(_screenRing, findsNothing);
  });

  testWidgets('motion is limited to the fixed Seeker portrait and session', (
    tester,
  ) async {
    await _mount(tester, quiet: true);
    final style = ZyraBrowseNextMotion.values[1];
    await _select(tester, style);
    await _tap(tester, 'concept_next_profile');
    final epoch = _motion(tester).epoch;
    final oldNext = _browse(tester).onNext!;
    await _openControls(tester);
    expect(
      find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('concept_browse_design_');
      }),
      findsNothing,
    );
    oldNext();
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(_key('concept_page_options_context')).data,
      'Profiles',
    );
    expect(_motionDropdown, findsOneWidget);
    await _tap(tester, 'draft_back');
    expect(_selectedId(tester), _aisha);
    expect(_browse(tester).design, ZyraOneJourneyBrowseDesign.portraitCard);
    expect(_motion(tester).style, style);
    expect(_motion(tester).epoch, epoch);
    await _openControls(tester);
    await _tap(tester, 'draft_role_guardian');
    expect(_motionFinder, findsNothing);
    await _openControls(tester);
    expect(_motionDropdown, findsNothing);
    await _tap(tester, 'draft_role_seeker');
    expect(_motion(tester).style, style);
    expect(_motion(tester).epoch, epoch);
  });

  testWidgets('Reset retains the motion choice without replaying a Next', (
    tester,
  ) async {
    await _mount(tester, quiet: true);
    final style = ZyraBrowseNextMotion.values[1];
    await _select(tester, style);
    await _tap(tester, 'concept_next_profile');
    final epoch = _motion(tester).epoch;
    await _openControls(tester);
    await _tap(tester, 'draft_reset');
    expect(_selectedId(tester), _sara);
    expect(_motion(tester).style, style);
    expect(_motion(tester).epoch, epoch);
    await _tap(tester, 'concept_next_profile');
    expect(_motion(tester).epoch, epoch + 1);
    expect(_screenRing, findsNothing);
  });

  for (final mode in const [
    (quiet: true, accessible: false),
    (quiet: false, accessible: true),
  ]) {
    testWidgets('quiet Next still advances the exact profile ${mode.quiet}', (
      tester,
    ) async {
      await _mount(tester, quiet: mode.quiet, accessible: mode.accessible);
      await _select(tester, ZyraBrowseNextMotion.values[1]);
      final epoch = _motion(tester).epoch;
      await _tap(tester, 'concept_next_profile', settle: false);
      expect(_selectedId(tester), _aisha);
      expect(_motion(tester).profileId, _aisha);
      expect(_motion(tester).epoch, epoch + 1);
      _expectRest(tester);
      await tester.pump(const Duration(milliseconds: 160));
      _expectRest(tester);
      expect(_screenRing, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  }
}
