// Real-shell, offline coverage of the selected Portrait split Journey cards.
// No duplicate card, replacement image builder, live member or backend adapter.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_one_journey_card_content.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_JOURNEY_CARD_CHOICES_CAPTURE_DIR',
);
const _font = 'PoppinsJourneyCardChoices';
const _boundary = ValueKey('journey-card-choices-capture');
const _design = ZyraOneJourneyCardDesign.portraitSplit;
const _people = [
  (id: 'draft-sara', name: 'Sara', age: 27, city: 'Birmingham'),
  (id: 'draft-aisha', name: 'Aisha', age: 29, city: 'London'),
  (id: 'draft-maryam', name: 'Maryam', age: 26, city: 'Leeds'),
];

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _picker => _key('concept_journey_card_layout');
Finder get _cards => find.byType(ZyraOneJourneyConnectionsActiveCard);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Journey layout choices must remain offline.');
  }
}

ZyraPreviewNavigationCheckpoint _seed({
  bool guardian = false,
  int tab = 1,
  int count = 3,
  List<String> pages = const [],
  String? personId,
  bool continued = false,
}) {
  final model = ViewRequestDraftModel(capacity: 3);
  expect(model.seedJourneys(count), isTrue);
  if (continued) expect(model.sendSalam('draft-sara'), isTrue);
  return ZyraPreviewNavigationCheckpoint(
    guardian: guardian,
    model: model.snapshot(),
    tab: tab,
    pages: pages,
    personId: personId,
  );
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    ZyraPreviewNavigationCheckpoint? checkpoint,
    bool guardian = false,
    double scale = 1,
    Size size = const Size(393, 852),
  }) async {
    final ready = Completer<void>();
    tester.view.physicalSize = size;
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
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: RepaintBoundary(key: _boundary, child: child!),
        ),
        home: ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () => fail('Layout choice testing must not exit the app.'),
          initialGuardianRole: guardian,
          initialCheckpoint: checkpoint,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    // Use the same real offline deck preparation as the shipped shell.
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue, reason: 'Bundled photo frames prepare');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  if (await pressZyraDevControlKey(tester, key)) return;
  final target = _key(key);
  expect(target, findsOneWidget, reason: 'Actual shell action $key');
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  await tester.tapAt(tester.getCenter(_key('floating-nav-item-$index')));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _controls(WidgetTester tester) async {
  await _tap(tester, 'draft_back');
  expect(find.text('Page options'), findsOneWidget);
}

Future<void> _chooseSample(WidgetTester tester, int count) async {
  await _controls(tester);
  expect(
    tester.widget<Text>(_key('concept_page_options_context')).data,
    'Journey',
  );
  _expectRetiredChoices();
  await _tap(tester, 'concept_journey_preview_$count');
  expect(_picker, findsNothing);
}

void _expectRetiredChoices() {
  expect(_picker, findsNothing);
  expect(
    find.byType(DropdownButtonFormField<ZyraOneJourneyCardDesign>),
    findsNothing,
  );
  expect(find.text('Journey cards'), findsNothing);
  for (final name in [
    'quietMinimal',
    'largerPortrait',
    'portraitSplit',
    'roundedPortrait',
    'identityHeader',
    'editorial',
  ]) {
    expect(_key('concept_journey_card_choice_$name'), findsNothing);
  }
}

ScrollableState _pageScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey('concept_connections_page_0')),
            matching: find.byType(Scrollable),
          )
          .first,
    );

Future<void> _settlePaintedCardPhotos(WidgetTester tester) async {
  final images = tester
      .widgetList<Image>(
        find.descendant(of: _cards, matching: find.byType(Image)),
      )
      .toList();
  expect(images, isNotEmpty);
  // Shell readiness prepares the Browse renderer's frames. Journey cards
  // mount their own real MemoryImage providers, whose engine codec completion
  // is not guaranteed by a fake-clock pumpAndSettle or a non-zero layout box.
  await tester.runAsync(() async {
    for (final image in images) {
      expect(image.image, isA<MemoryImage>());
      final context = tester.element(find.byWidget(image));
      final stream = image.image.resolve(
        createLocalImageConfiguration(context),
      );
      final decoded = Completer<void>();
      final listener = ImageStreamListener(
        (info, _) {
          final valid = info.image.width > 0 && info.image.height > 0;
          info.dispose();
          if (decoded.isCompleted) return;
          if (valid) {
            decoded.complete();
          } else {
            decoded.completeError(
              StateError('Portrait decoded without pixels.'),
            );
          }
        },
        onError: (Object error, StackTrace? stack) {
          if (!decoded.isCompleted) decoded.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await decoded.future.timeout(const Duration(seconds: 10));
      } finally {
        stream.removeListener(listener);
      }
    }
  });
  // Paint the Image states that received those actual codec frames.
  await tester.pumpAndSettle();
  _expectPaintedCardPhotos(tester);
  expect(tester.takeException(), isNull);
}

void _expectPaintedCardPhotos(WidgetTester tester) {
  for (final card in _cards.evaluate()) {
    final raw = find.descendant(
      of: find.byWidget(card.widget),
      matching: find.byType(RawImage),
    );
    expect(
      raw,
      findsOneWidget,
      reason: 'Each card paints its actual JPEG frame',
    );
    final painted = tester.renderObject<RenderImage>(raw);
    expect(
      painted.image,
      isNotNull,
      reason: 'A photo layout box is not pixel evidence',
    );
    expect(painted.image!.width, greaterThan(0));
    expect(painted.image!.height, greaterThan(0));
    expect(painted.size.width, greaterThan(0));
    expect(painted.size.height, greaterThan(0));
    expect(painted.debugNeedsPaint, isFalse);
  }
}

void _expectIdentityPaintBounds(
  WidgetTester tester,
  Finder card,
  String text,
  Rect photo,
  Rect action,
) {
  final label = find.descendant(of: card, matching: find.text(text));
  expect(label, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(label);
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: '$text is not truncated',
  );
  expect(paragraph.size.width, greaterThan(0));
  expect(paragraph.size.height, greaterThan(0));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  expect(
    boxes,
    isNotEmpty,
    reason: '$text has laid-out glyphs, not just a Text widget',
  );
  final envelope = tester.getRect(card).inflate(.05);
  for (final box in boxes) {
    final local = box.toRect();
    final glyphs = Rect.fromPoints(
      paragraph.localToGlobal(local.topLeft),
      paragraph.localToGlobal(local.bottomRight),
    );
    expect(glyphs.width, greaterThan(0));
    expect(glyphs.height, greaterThan(0));
    expect(
      envelope.contains(glyphs.topLeft),
      isTrue,
      reason: '$text stays inside its card',
    );
    expect(
      envelope.contains(glyphs.bottomRight),
      isTrue,
      reason: '$text stays inside its card',
    );
    // A font's selection box can overhang its line-height box without being
    // clipped. The actual card and neighbouring painted regions are the
    // relevant boundaries, not the paragraph's nominal layout rectangle.
    expect(
      glyphs.overlaps(photo.deflate(.05)),
      isFalse,
      reason: '$text is not behind the portrait',
    );
    expect(
      glyphs.overlaps(action.deflate(.05)),
      isFalse,
      reason: '$text is not behind the Journey action',
    );
  }
}

Future<void> _expectDataAndActions(
  WidgetTester tester,
  ZyraOneJourneyCardDesign design,
  int count, {
  bool enlargedPhotos = true,
  bool continued = false,
}) async {
  await _settlePaintedCardPhotos(tester);
  expect(_cards, findsNWidgets(count));
  final values = tester
      .widgetList<ZyraOneJourneyConnectionsActiveCard>(_cards)
      .toList();
  for (var index = 0; index < count; index++) {
    final person = _people[index];
    final card = values[index];
    final owner = find.byWidget(card);
    expect(card.cardDesign, design);
    expect(card.profile.id, person.id);
    expect(card.profile.firstName, person.name);
    expect(card.profile.age, person.age);
    expect(card.profile.city, person.city);
    expect(card.profile.photos, isNotEmpty);
    expect(card.profile.photoUrl, startsWith('data:image/'));
    expect(card.onReport, isNull);
    expect(
      find.descendant(of: owner, matching: find.text(person.name)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: owner,
        matching: find.text('${person.age} · ${person.city}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: owner, matching: find.text('Active Journey')),
      findsNothing,
    );
    expect(
      find.descendant(of: owner, matching: find.text('Salam Exchange')),
      findsNothing,
    );
    expect(
      find.descendant(of: owner, matching: find.byIcon(Icons.flag_outlined)),
      findsNothing,
    );
    final content = tester.widget<ZyraOneJourneyCardContent>(
      find.descendant(
        of: owner,
        matching: find.byType(ZyraOneJourneyCardContent),
      ),
    );
    expect(content.design, design);
    expect(content.profile, same(card.profile));
    final deck = card.actions as ZyraOneJourneyConnectionsActionDeck;
    expect(deck.primary.label, 'Continue Journey');
    expect(deck.primary.icon, isNull);
    expect(deck.primary.onTap, isNotNull);
    expect(_key('draft_journey_${person.id}'), findsOneWidget);
    expect(_key('draft_journey_options_${person.id}'), findsOneWidget);
    // The mounted RawImage above now proves that this layout rectangle has
    // received a decoded frame; geometry by itself would not establish that.
    final image = find.descendant(of: owner, matching: find.byType(Image));
    expect(image, findsOneWidget);
    expect(
      find.descendant(of: owner, matching: find.byType(ZyraProfileImage)),
      findsOneWidget,
    );
    final photo = tester.getRect(image);
    expect(photo.width, greaterThan(0));
    expect(photo.height, greaterThan(0));
    if (enlargedPhotos) {
      expect(
        photo.width * photo.height,
        greaterThan(104 * 104 * 1.08),
        reason: '${design.name} makes the actual portrait materially larger',
      );
    }
    final bounds = tester.getRect(owner);
    expect(photo.left, greaterThanOrEqualTo(bounds.left));
    expect(photo.right, lessThanOrEqualTo(bounds.right));
    expect(photo.top, greaterThanOrEqualTo(bounds.top));
    expect(photo.bottom, lessThanOrEqualTo(bounds.bottom));
    final action = tester.getRect(_key('draft_journey_${person.id}'));
    expect(action.left, greaterThanOrEqualTo(bounds.left));
    expect(action.right, lessThanOrEqualTo(bounds.right));
    expect(action.bottom, lessThanOrEqualTo(bounds.bottom));
    _expectIdentityPaintBounds(tester, owner, person.name, photo, action);
    final surname = card.profile.surnameLine?.trim() ?? '';
    if (surname.isNotEmpty) {
      _expectIdentityPaintBounds(tester, owner, surname, photo, action);
    }
    _expectIdentityPaintBounds(
      tester,
      owner,
      '${person.age} · ${person.city}',
      photo,
      action,
    );
    final outer = find.descendant(
      of: owner,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(18),
      ),
    );
    expect(outer, findsOneWidget);
    final decoration =
        tester.widget<DecoratedBox>(outer).decoration as BoxDecoration;
    expect(decoration.color, ZyraColors.surfaceFill);
    expect(
      decoration.border,
      Border.all(color: ZyraColors.surfaceEmphasisBorder),
    );
  }
  expect(tester.takeException(), isNull);
}

void _expectNormalGeometry(WidgetTester tester, int count) {
  final nav = tester.getRect(find.byType(FloatingNavBar));
  final viewport = tester.getRect(
    find.byKey(const PageStorageKey('concept_connections_page_0')),
  );
  final bounds = [
    for (final card in _cards.evaluate())
      tester.getRect(find.byWidget(card.widget)),
  ];
  for (var index = 0; index < bounds.length; index++) {
    final rect = bounds[index];
    expect(rect.left, closeTo(20, .01));
    expect(rect.right, closeTo(373, .01));
    expect(
      rect.bottom,
      lessThanOrEqualTo(nav.top - 4),
      reason: 'No card is behind floating navigation',
    );
    if (index > 0) {
      expect(rect.top - bounds[index - 1].bottom, closeTo(12, .01));
      expect(rect.height, closeTo(bounds.first.height, .01));
    }
  }
  expect(bounds.first.top, closeTo(viewport.top + 12, .05));
  expect(
    bounds.last.bottom,
    closeTo(
      nav.top -
          (ZyraNavBarMetrics.height - ZyraNavBarMetrics.restingHeight) -
          12,
      .75,
    ),
    reason:
        'All $count cards fill the available canvas with the same clean navigation clearance',
  );
  expect(
    _pageScroll(tester).position.maxScrollExtent,
    closeTo(0, .01),
    reason: '$count ordinary-text cards fit without vertical scrolling',
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  _expectPaintedCardPhotos(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      final file = File('$_captureDirectory/$name.png');
      if (file.existsSync()) throw StateError('Refusing to overwrite $name');
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void _expectEvenCenteredRows(WidgetTester tester, String id) {
  final options = tester.getRect(_key('journey_card_expanded_options'));
  final nav = tester.getRect(find.byType(FloatingNavBar));
  final rows = <Rect>[];
  for (final name in [
    'profile',
    'timeline',
    'bio',
    'compatibility',
    'guardians',
    'report',
    'end',
  ]) {
    final row = _key('draft_options_${name}_$id');
    expect(row, findsOneWidget);
    expect(row.hitTestable(), findsOneWidget);
    final bounds = tester.getRect(row);
    expect(bounds.height, greaterThanOrEqualTo(55.95));
    expect(bounds.bottom, lessThan(nav.top));
    if (rows.isNotEmpty) {
      expect(
        bounds.top,
        closeTo(rows.last.bottom, .05),
        reason:
            'Actual menu cells are contiguous; no external spacing hides between dividers',
      );
      expect(
        bounds.height,
        closeTo(rows.first.height, .05),
        reason: 'Every divider interval is the same height',
      );
    }
    rows.add(bounds);

    final circle = find.descendant(
      of: row,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final constraints = widget.constraints;
        return constraints != null &&
            constraints.minWidth == 38 &&
            constraints.maxWidth == 38 &&
            constraints.minHeight == 38 &&
            constraints.maxHeight == 38 &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle;
      }),
    );
    expect(
      circle,
      findsOneWidget,
      reason: '$name retains its real 38px icon circle',
    );
    final circleBounds = tester.getRect(circle);
    expect(circleBounds.width, closeTo(38, .001));
    expect(circleBounds.height, closeTo(38, .001));
    expect(
      circleBounds.center.dy,
      closeTo(bounds.center.dy, .6),
      reason: '$name icon circle is centred between its divider lines',
    );
    final icon = find.descendant(of: circle, matching: find.byType(Icon));
    expect(icon, findsOneWidget);
    expect(tester.getRect(icon).center.dy, closeTo(bounds.center.dy, .6));

    final title = find.descendant(of: row, matching: find.byType(Text));
    expect(title, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(title);
    expect(paragraph.didExceedMaxLines, isFalse);
    final titleBounds = tester.getRect(title);
    expect(titleBounds.height, greaterThan(0));
    expect(titleBounds.top, greaterThanOrEqualTo(bounds.top));
    expect(titleBounds.bottom, lessThanOrEqualTo(bounds.bottom));
    expect(
      titleBounds.center.dy,
      closeTo(bounds.center.dy, .6),
      reason: '$name rendered title is centred in its real menu cell',
    );

    final locked = name == 'bio' || name == 'compatibility';
    final trailingGlyph = find.descendant(
      of: row,
      matching: find.byIcon(locked ? Icons.lock_outline : Icons.chevron_right),
    );
    expect(trailingGlyph, findsOneWidget);
    expect(
      find.descendant(
        of: row,
        matching: find.byIcon(
          locked ? Icons.chevron_right : Icons.lock_outline,
        ),
      ),
      findsNothing,
    );
    expect(
      tester.getRect(trailingGlyph).center.dy,
      closeTo(bounds.center.dy, .6),
      reason: '$name trailing glyph shares the row centre',
    );
  }
  expect(rows, hasLength(7));
  expect(rows.first.top, closeTo(options.top, .05));
  expect(rows.last.bottom, closeTo(options.bottom, .05));
  expect(
    rows.fold<double>(0, (total, row) => total + row.height),
    closeTo(options.height, .05),
    reason: 'The seven actual touch rows fill the entire bounded options area',
  );
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late String? oldReading;
  late ZyraHapticLevel oldHaptics;

  setUpAll(() async {
    if (_captureDirectory.isNotEmpty &&
        (!_captureDirectory.startsWith('/') ||
            !Directory(_captureDirectory).existsSync())) {
      throw StateError('Capture directory must already exist and be absolute.');
    }
    final reading = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
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
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    final gold = ZyraDevAppGold.instance;
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
    ZyraText.testReadingFontFamily = oldReading;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('only selected and still-used legacy presenters remain', () {
    expect(ZyraOneJourneyCardDesign.values, [
      ZyraOneJourneyCardDesign.classic,
      ZyraOneJourneyCardDesign.quietMinimal,
      ZyraOneJourneyCardDesign.portraitSplit,
    ]);
  });

  for (final count in [1, 2, 3]) {
    testWidgets(
      'Portrait split defaults to $count full-canvas cards and balances the selected expanded action',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, checkpoint: _seed());
        await _chooseSample(tester, count);
        await _expectDataAndActions(tester, _design, count);
        _expectNormalGeometry(tester, count);
        expect(
          owner.latest.model.states.values.where(
            (value) => value == DraftJourneyState.active,
          ),
          hasLength(count),
        );
        if (count == 3) await _capture(tester, 'portrait_split_3_journeys');

        final selected = _people[count > 1 ? 1 : 0];
        await _tap(tester, 'draft_journey_options_${selected.id}');
        await _settlePaintedCardPhotos(tester);
        expect(_key('concept_expanded_journey_${selected.id}'), findsOneWidget);
        expect(_cards, findsOneWidget);
        final card = tester.widget<ZyraOneJourneyConnectionsActiveCard>(_cards);
        expect(card.profile.id, selected.id);
        expect(card.cardDesign, _design);
        expect(card.onReport, isNull);
        expect(_key('draft_journey_${selected.id}'), findsOneWidget);
        expect(
          find.text('Continue Journey'),
          findsOneWidget,
          reason: 'Expanded card has only one primary action',
        );
        expect(_key('draft_options_report_${selected.id}'), findsOneWidget);
        expect(find.text('Report'), findsOneWidget);
        final header = tester.getRect(_key('journey_card_expanded_header'));
        final primary = tester.getRect(_key('draft_journey_${selected.id}'));
        final action = tester.getRect(_key('journey_card_expanded_action'));
        final firstOption = tester.getRect(
          _key('draft_options_profile_${selected.id}'),
        );
        final options = tester.getRect(_key('journey_card_expanded_options'));
        final gapBefore = action.top - header.bottom;
        final gapAfter = firstOption.top - action.bottom;
        expect(primary.center.dy, closeTo(action.center.dy, .05));
        expect(gapBefore, closeTo(12, .05));
        expect(gapAfter, closeTo(12, .05));
        expect(
          gapAfter,
          closeTo(gapBefore, .05),
          reason:
              'The primary row has fixed equal gaps, independent of spare card height',
        );
        // Ink's border can inset the labelled tap target by one pixel. Even
        // that actual button edge must remain tightly beside both regions.
        expect(primary.top - header.bottom, lessThanOrEqualTo(14));
        expect(firstOption.top - primary.bottom, lessThanOrEqualTo(14));
        expect(
          options.top,
          closeTo(firstOption.top, .05),
          reason: 'No concealed leading list space distorts the visual gap',
        );
        final nav = tester.getRect(find.byType(FloatingNavBar));
        expect(tester.getRect(_cards).bottom, lessThanOrEqualTo(nav.top - 4));
        for (final option in [
          'profile',
          'timeline',
          'bio',
          'compatibility',
          'guardians',
          'report',
          'end',
        ]) {
          final row = _key('draft_options_${option}_${selected.id}');
          expect(row.hitTestable(), findsOneWidget);
          expect(tester.getRect(row).bottom, lessThan(nav.top));
        }
        _expectEvenCenteredRows(tester, selected.id);
        if (count == 3) await _capture(tester, 'portrait_split_expanded');
        await _tap(tester, 'draft_journey_options_${selected.id}');
        await _expectDataAndActions(tester, _design, count);
        _expectNormalGeometry(tester, count);
        expect(find.text('Report'), findsNothing);
        await _tap(tester, 'draft_journey_${selected.id}');
        expect(owner.latest.personId, selected.id);
        expect(owner.latest.pages.last, 'journey');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'tall phone keeps 12px expanded primary gaps and all seven options visible without scroll',
    (tester) async {
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(),
        size: const Size(430, 932),
      );
      const id = 'draft-aisha';
      await _tap(tester, 'draft_journey_options_$id');
      await _settlePaintedCardPhotos(tester);
      expect(_cards, findsOneWidget);
      final card = tester.widget<ZyraOneJourneyConnectionsActiveCard>(_cards);
      expect(card.profile.id, id);
      expect(card.cardDesign, _design);
      expect(card.profile.photoUrl, startsWith('data:image/'));
      expect(find.text('Continue Journey'), findsOneWidget);
      expect(_key('concept_expanded_journey_reading_$id'), findsNothing);
      final header = tester.getRect(_key('journey_card_expanded_header'));
      final action = tester.getRect(_key('journey_card_expanded_action'));
      final primary = tester.getRect(_key('draft_journey_$id'));
      final options = tester.getRect(_key('journey_card_expanded_options'));
      final first = tester.getRect(_key('draft_options_profile_$id'));
      final before = action.top - header.bottom;
      final after = first.top - action.bottom;
      expect(before, closeTo(12, .05));
      expect(after, closeTo(12, .05));
      expect(after, closeTo(before, .05));
      expect(primary.center.dy, closeTo(action.center.dy, .05));
      expect(primary.top - header.bottom, lessThanOrEqualTo(14));
      expect(first.top - primary.bottom, lessThanOrEqualTo(14));
      expect(options.top, closeTo(first.top, .05));
      final photo = tester.getRect(
        find.descendant(of: _cards, matching: find.byType(Image)),
      );
      for (final identity in ['Aisha', 'Khan', '29 · London']) {
        _expectIdentityPaintBounds(tester, _cards, identity, photo, primary);
      }
      final nav = tester.getRect(find.byType(FloatingNavBar));
      final cardBounds = tester.getRect(_cards);
      expect(cardBounds.bottom, lessThanOrEqualTo(nav.top - 4));
      for (final option in [
        'profile',
        'timeline',
        'bio',
        'compatibility',
        'guardians',
        'report',
        'end',
      ]) {
        final row = _key('draft_options_${option}_$id');
        expect(row.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(row);
        expect(bounds.top, greaterThanOrEqualTo(options.top));
        expect(bounds.bottom, lessThanOrEqualTo(cardBounds.bottom));
        expect(bounds.bottom, lessThan(nav.top));
        final label = find.descendant(of: row, matching: find.byType(Text));
        expect(label, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(label);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.size.width, greaterThan(0));
        expect(paragraph.size.height, greaterThan(0));
      }
      for (final scroll
          in find
              .descendant(of: _cards, matching: find.byType(Scrollable))
              .evaluate()) {
        expect(
          tester
              .state<ScrollableState>(find.byWidget(scroll.widget))
              .position
              .maxScrollExtent,
          closeTo(0, .01),
          reason: 'Tall expanded cards need no hidden or unnecessary scroll',
        );
      }
      expect(owner.latest.pages, isEmpty);
      expect(tester.takeException(), isNull);
      _expectEvenCenteredRows(tester, id);
      await _capture(tester, 'portrait_split_expanded_tall');
    },
  );

  testWidgets(
    'intermediate-height expansion scrolls the whole selected card and reaches every option',
    (tester) async {
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(),
        size: const Size(393, 760),
      );
      const id = 'draft-aisha';
      await _tap(tester, 'draft_journey_options_$id');
      await _settlePaintedCardPhotos(tester);
      expect(_cards, findsOneWidget);
      expect(
        tester.widget<ZyraOneJourneyConnectionsActiveCard>(_cards).profile.id,
        id,
      );
      expect(find.text('Continue Journey'), findsOneWidget);
      final reading = _key('concept_expanded_journey_reading_$id');
      expect(reading, findsOneWidget);
      final scroll = find
          .descendant(of: reading, matching: find.byType(Scrollable))
          .first;
      expect(
        tester.state<ScrollableState>(scroll).position.maxScrollExtent,
        greaterThan(0),
      );
      final viewport = tester.getRect(reading);
      final nav = tester.getRect(find.byType(FloatingNavBar));
      for (final option in [
        'profile',
        'timeline',
        'bio',
        'compatibility',
        'guardians',
        'report',
        'end',
      ]) {
        final row = _key('draft_options_${option}_$id');
        expect(row, findsOneWidget);
        await Scrollable.ensureVisible(tester.element(row), alignment: .5);
        await tester.pumpAndSettle();
        expect(
          row.hitTestable(),
          findsOneWidget,
          reason:
              '$option is reachable through the whole-card reading fallback',
        );
        final bounds = tester.getRect(row);
        expect(bounds.top, greaterThanOrEqualTo(viewport.top - .05));
        expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom + .05));
        expect(bounds.bottom, lessThan(nav.top));
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Report'), findsOneWidget);
      expect(owner.latest.pages, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Portrait split uses Continue Journey without changing real draft progress',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed(continued: true));
      await _expectDataAndActions(tester, _design, 3, continued: true);
      expect(find.text('Continue Journey'), findsNWidgets(3));
      expect(find.text('Start Journey'), findsNothing);
      await _tap(tester, 'draft_journey_options_draft-sara');
      expect(find.text('Continue Journey'), findsOneWidget);
      expect(find.text('Start Journey'), findsNothing);
      await _tap(tester, 'draft_journey_draft-sara');
      expect(owner.latest.personId, 'draft-sara');
      expect(owner.latest.pages.last, 'journey');
    },
  );

  testWidgets(
    'Portrait split keeps readable 2x text and safe scroll fallback at 320',
    (tester) async {
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(),
        size: const Size(320, 852),
        scale: 2,
      );
      await _expectDataAndActions(tester, _design, 3, enlargedPhotos: false);
      expect(_pageScroll(tester).position.maxScrollExtent, greaterThan(0));
      for (final person in _people) {
        final name = find.text(person.name);
        expect(
          tester.renderObject<RenderParagraph>(name).didExceedMaxLines,
          isFalse,
        );
        expect(MediaQuery.textScalerOf(tester.element(name)).scale(12), 24);
        final action = _key('draft_journey_${person.id}');
        await Scrollable.ensureVisible(tester.element(action), alignment: .5);
        await tester.pumpAndSettle();
        final rect = tester.getRect(action);
        final nav = tester.getRect(find.byType(FloatingNavBar));
        expect(rect.left, greaterThanOrEqualTo(20));
        expect(rect.right, lessThanOrEqualTo(300));
        expect(rect.bottom, lessThanOrEqualTo(nav.top));
        expect(action.hitTestable(), findsOneWidget);
      }
      await _tap(tester, 'draft_journey_options_draft-maryam');
      await _settlePaintedCardPhotos(tester);
      expect(_cards, findsOneWidget);
      final reading = _key('concept_expanded_journey_reading_draft-maryam');
      expect(reading, findsOneWidget);
      final scroll = find
          .descendant(of: reading, matching: find.byType(Scrollable))
          .first;
      expect(
        tester.state<ScrollableState>(scroll).position.maxScrollExtent,
        greaterThan(0),
      );
      final last = _key('draft_options_end_draft-maryam');
      await tester.scrollUntilVisible(last, 180, scrollable: scroll);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(last).bottom,
        lessThan(tester.getRect(find.byType(FloatingNavBar)).top),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'warm return, fresh owner and Reset all use Portrait split without choosing a layout',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      await _nav(tester, 0);
      await _nav(tester, 1);
      await _expectDataAndActions(tester, _design, 3);
      final saved = owner.latest;
      final resumed = _Owner();
      await resumed.mount(tester, checkpoint: saved);
      await _expectDataAndActions(tester, _design, 3);
      expect(resumed.latest.model.states, saved.model.states);

      final fresh = _Owner();
      await fresh.mount(tester);
      await _nav(tester, 1);
      await _chooseSample(tester, 3);
      await _expectDataAndActions(tester, _design, 3);
      await _controls(tester);
      await _tap(tester, 'draft_reset');
      await _nav(tester, 1);
      await _chooseSample(tester, 3);
      await _expectDataAndActions(tester, _design, 3);
      _expectNormalGeometry(tester, 3);
    },
  );

  testWidgets(
    'retired layout choices are absent from every role and page options context',
    (tester) async {
      for (final guardian in [false, true]) {
        for (var tab = 0; tab < (guardian ? 4 : 5); tab++) {
          final owner = _Owner();
          await owner.mount(
            tester,
            guardian: guardian,
            checkpoint: _seed(guardian: guardian, tab: tab),
          );
          await _controls(tester);
          _expectRetiredChoices();
          for (final count in [1, 2, 3]) {
            expect(
              _key('concept_journey_preview_$count'),
              !guardian && tab == 1 ? findsOneWidget : findsNothing,
            );
          }
        }
      }
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(tab: 2, pages: const ['requests']),
      );
      await _controls(tester);
      _expectRetiredChoices();
    },
  );

  testWidgets(
    'retained inline options cannot navigate after collapse and reopening',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      await _tap(tester, 'draft_journey_options_draft-sara');
      final stale = tester
          .widget<ZyraConceptJourneyOptions>(
            find.byType(ZyraConceptJourneyOptions),
          )
          .onSelected;
      await _tap(tester, 'draft_journey_options_draft-sara');
      await _tap(tester, 'draft_journey_options_draft-sara');
      final before = owner.checkpoints.length;
      stale(ZyraConceptJourneyOption.profile);
      await tester.pumpAndSettle();
      expect(owner.latest.pages, isEmpty);
      expect(owner.checkpoints.length, before);
      expect(_key('concept_expanded_journey_draft-sara'), findsOneWidget);
    },
  );

  testWidgets(
    'retained primary and menu actions are rejected after role switch',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final primary =
          (tester
                      .widgetList<ZyraOneJourneyConnectionsActiveCard>(_cards)
                      .first
                      .actions
                  as ZyraOneJourneyConnectionsActionDeck)
              .primary
              .onTap!;
      final menu = tester
          .widget<ZyraConceptJourneyOptionsButton>(
            _key('draft_journey_options_draft-sara'),
          )
          .onTap;
      await _controls(tester);
      await _tap(tester, 'draft_role_guardian');
      final before = owner.checkpoints.length;
      primary();
      menu();
      await tester.pumpAndSettle();
      expect(owner.latest.guardian, isTrue);
      expect(owner.latest.pages, isEmpty);
      expect(owner.checkpoints.length, before);
      expect(_cards, findsNothing);
    },
  );

  testWidgets(
    'denied owner cannot use retained card or inline actions or publish a checkpoint',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      await _tap(tester, 'draft_journey_options_draft-sara');
      final primary =
          (tester.widget<ZyraOneJourneyConnectionsActiveCard>(_cards).actions
                  as ZyraOneJourneyConnectionsActionDeck)
              .primary
              .onTap!;
      final menu = tester
          .widget<ZyraConceptJourneyOptionsButton>(
            _key('draft_journey_options_draft-sara'),
          )
          .onTap;
      final options = tester
          .widget<ZyraConceptJourneyOptions>(
            find.byType(ZyraConceptJourneyOptions),
          )
          .onSelected;
      final before = owner.checkpoints.length;
      owner.allowed = false;
      primary();
      menu();
      options(ZyraConceptJourneyOption.end);
      await tester.pumpAndSettle();
      expect(owner.latest.pages, isEmpty);
      expect(owner.checkpoints.length, before);
      expect(tester.takeException(), isNull);
    },
  );
}
