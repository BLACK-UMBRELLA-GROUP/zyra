// OA304: real Personalisation UI, protected controls, and honest contrast
// evidence. Local preview intentions are never member preference writes.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _readingFont = 'PoppinsPersonalisationHealth';
const _wordmarkFont = 'SynePersonalisationHealth';
const _captures = String.fromEnvironment(
  'ZYRA_PERSONALISATION_HEALTH_CAPTURE_DIR',
);
const _captureKey = ValueKey('personalisation-health-capture');
const _ordinaryScope =
    'Your choices apply across the app on this device. They never change your profile or account.';
const _previewScope =
    'Changes apply to this preview session only. Your account settings stay unchanged.';
const _goldHint = 'Subtle gold details; motion follows your device settings.';
const _hapticHint = 'Choose how taps feel on this device.';

Finder _key(String name) => find.byKey(ValueKey(name));
Finder _choice(Object option) =>
    _key('personalisation_choice_${option.toString()}');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Personalisation health evidence must remain offline.');
  }
}

Widget _app(Widget child, {bool compact = false}) => MaterialApp(
  theme: ThemeData.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      textScaler: TextScaler.linear(compact ? 2 : 1),
      disableAnimations: true,
    ),
    child: RepaintBoundary(key: _captureKey, child: child!),
  ),
  home: Scaffold(body: child),
);

void _size(WidgetTester tester, {bool compact = false}) {
  tester.view.physicalSize = compact
      ? const Size(320, 568)
      : const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _visibleVerticalScroll() => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
    )
    .hitTestable();

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    // Lazy lists do not build their distant rows. Discover the active viewport
    // rather than assuming that its wrapper is a ListView or has a legacy key.
    final scroll = _visibleVerticalScroll();
    expect(scroll, findsOneWidget);
    final position = tester.state<ScrollableState>(scroll).position;
    position.jumpTo(position.minScrollExtent);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      target,
      140,
      scrollable: scroll,
      maxScrolls: 40,
    );
  }
  expect(target, findsOneWidget);
  final ancestors = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  if (ancestors.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _top(WidgetTester tester) async {
  final scroll = find.descendant(
    of: _key('personalisation-scroll'),
    matching: find.byType(Scrollable),
  );
  expect(scroll, findsOneWidget);
  tester.state<ScrollableState>(scroll).position.jumpTo(0);
  await tester.pumpAndSettle();
}

class _PreviewOwner extends StatefulWidget {
  const _PreviewOwner({super.key, this.palette = ZyraDevPalette.ivory});
  final ZyraDevPalette palette;

  @override
  State<_PreviewOwner> createState() => _PreviewOwnerState();
}

class _PreviewOwnerState extends State<_PreviewOwner> {
  late ZyraDevPalette palette = widget.palette;
  ZyraHapticLevel haptic = ZyraHapticLevel.subtle;
  bool gold = false;
  static bool allowed() => true;

  @override
  Widget build(BuildContext context) => PersonalisationScreen.preview(
    canAct: allowed,
    palette: palette,
    hapticLevel: haptic,
    goldEnabled: gold,
    onHapticChanged: (value) => setState(() => haptic = value),
    onGoldChanged: (value) => setState(() => gold = value),
    embedded: false,
  );
}

Future<GlobalKey<_PreviewOwnerState>> _preview(
  WidgetTester tester, {
  bool compact = false,
  ZyraDevPalette palette = ZyraDevPalette.ivory,
}) async {
  _size(tester, compact: compact);
  final owner = GlobalKey<_PreviewOwnerState>();
  await tester.pumpWidget(
    _app(
      _PreviewOwner(key: owner, palette: palette),
      compact: compact,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return owner;
}

ZyraPersonalisationSnapshot _snapshot(WidgetTester tester) => tester
    .widget<ZyraPersonalisationContent>(find.byType(ZyraPersonalisationContent))
    .snapshot;

BoxDecoration _previewDecoration(WidgetTester tester) {
  final container = find
      .descendant(
        of: _key('personalisation_preview'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
      )
      .first;
  return tester.widget<Container>(container).decoration! as BoxDecoration;
}

void _readableText(
  WidgetTester tester,
  Finder row,
  String value, {
  bool wrapped = false,
}) {
  final target = find.descendant(of: row, matching: find.text(value));
  expect(target, findsOneWidget);
  final text = tester.widget<Text>(target);
  final paragraph = tester.renderObject<RenderParagraph>(target);
  expect(text.maxLines, isNull);
  expect(text.overflow, isNot(TextOverflow.ellipsis));
  expect(paragraph.didExceedMaxLines, isFalse);
  final rowRect = tester.getRect(row);
  final textRect = tester.getRect(target);
  expect(textRect.left, greaterThanOrEqualTo(rowRect.left));
  expect(textRect.right, lessThanOrEqualTo(rowRect.right + .01));
  expect(textRect.top, greaterThanOrEqualTo(rowRect.top));
  expect(textRect.bottom, lessThanOrEqualTo(rowRect.bottom + .01));
  if (wrapped) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: value.length),
    );
    expect(boxes.map((box) => box.top).toSet().length, greaterThan(1));
  }
}

Future<void> _choiceSemantics(
  WidgetTester tester,
  Object option, {
  required bool selected,
}) async {
  final target = _choice(option);
  await _reveal(tester, target);
  expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
  final semantics = tester.getSemantics(target).getSemanticsData();
  expect(semantics.flagsCollection.isButton, isTrue);
  expect(
    semantics.flagsCollection.isSelected,
    selected ? ui.Tristate.isTrue : ui.Tristate.isFalse,
  );
  expect(semantics.hasAction(ui.SemanticsAction.tap), isTrue);
  final checks = find.descendant(
    of: target,
    matching: find.byIcon(
      selected ? Icons.check_circle : Icons.circle_outlined,
    ),
  );
  expect(checks, findsOneWidget);
  expect(
    find.ancestor(of: checks, matching: find.byType(ExcludeSemantics)),
    findsOneWidget,
  );
}

Future<void> _nav(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
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
  final action = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(action.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

class _ShellOwner {
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];

  Future<void> mount(WidgetTester tester, {bool guardian = false}) async {
    _size(tester);
    final ready = Completer<void>();
    await tester.pumpWidget(
      _app(
        ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => true,
          onExit: () =>
              fail('Personalisation stays inside its admitted owner.'),
          initialGuardianRole: guardian,
          initialCheckpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: ViewRequestDraftModel(capacity: 3).snapshot(),
            tab: 4,
            pages: const [],
          ),
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
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
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }

  Future<void> openPersonalisation(WidgetTester tester) async {
    await _tap(tester, _key('concept_personalisation'));
    expect(find.byType(PersonalisationScreen), findsOneWidget);
    expect(_key('personalisation-unavailable'), findsNothing);
  }
}

Finder _goldCanvas() => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter is ZyraOnboardingGoldPainter &&
      (widget.painter! as ZyraOnboardingGoldPainter).design ==
          ZyraOnboardingGoldDesign.diagonalDust,
);

double _contrast(Color text, Color surface) {
  final visible = Color.alphaBlend(text, surface);
  final light = math.max(
    visible.computeLuminance(),
    surface.computeLuminance(),
  );
  final dark = math.min(visible.computeLuminance(), surface.computeLuminance());
  return (light + .05) / (dark + .05);
}

Future<List<int>> _backgroundEdgePixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);
      final bytes = data!.buffer.asUint8List();
      return <int>[
        // Content cards are inset20. These two16px edge strips contain only
        // the actual backdrop; On/Off text and switch pixels cannot fake gold.
        for (var y = 0; y < image.height; y++)
          for (var x = 0; x < image.width; x++)
            if (x < 16 || x >= image.width - 16)
              for (var channel = 0; channel < 4; channel++)
                bytes[(y * image.width + x) * 4 + channel],
      ];
    } finally {
      image.dispose();
    }
  }))!;
}

Future<void> _capture(WidgetTester tester, String name) async {
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
      expect(bytes, isNotNull);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldHttp = HttpOverrides.current;
  final oldStubs = ZyraText.useTestFontStubs;
  final oldReading = ZyraText.testReadingFontFamily;
  final oldWordmark = ZyraText.testWordmarkFontFamily;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;
  late List<Object?> beforeGlobal;

  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  List<Object?> memberState() => [
    AppState.instance.name,
    AppState.instance.gender,
    AppState.instance.dob,
    AppState.instance.location,
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
    ZyraAccountState.userId,
    ZyraAccountState.generation,
    ZyraLocalPrefs.accountOwner,
    ZyraLocalPrefs.bindingGeneration,
    ZyraLocalPrefs.cachedAppPaletteName,
    ZyraLocalPrefs.cachedHapticLevelName,
    ZyraLocalPrefs.cachedAppGoldEnabled,
  ];
  List<Object?> globalState() => [
    ZyraColors.devPalette,
    ZyraInteractionStyle.hapticLevel,
    ZyraText.appFont,
    ZyraAppGoldStyle.instance.enabled,
    ZyraDevAppGold.instance.renderingEnabled,
  ];

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError('Capture output must be an absolute directory.');
      }
      var path = '';
      for (final part
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (part == '.' || part == '..') {
          throw StateError('Capture aliases are not accepted.');
        }
        path += '/$part';
        if (FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError('Captures require existing nonlinked directories.');
        }
      }
    }
    final reading = FontLoader(_readingFont);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final wordmark = FontLoader(_wordmarkFont)
      ..addFont(rootBundle.load('assets/fonts/Syne-SemiBold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'personalisation-health-sentinel': 'keep',
    });
    await ZyraLocalPrefs.init();
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize('personalisation-health-member');
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraText.restoreAppFont(null);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _readingFont;
    ZyraText.testWordmarkFontFamily = _wordmarkFont;
    beforePreferences = preferenceState();
    beforeMember = memberState();
    beforeGlobal = globalState();
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    final oldFatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = oldFatal);
  });

  tearDown(() {
    try {
      expect(network.attempts, 0);
      expect(preferenceState(), beforePreferences);
      expect(memberState(), beforeMember);
      expect(globalState(), beforeGlobal);
    } finally {
      HttpOverrides.global = oldHttp;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.resetAuthorizationForTesting();
      ZyraAccountState.clearImagesForTesting = null;
      ZyraText.useTestFontStubs = oldStubs;
      ZyraText.testReadingFontFamily = oldReading;
      ZyraText.testWordmarkFontFamily = oldWordmark;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    }
  });

  testWidgets('ordinary screen uses Ivory despite a stored legacy background', (
    tester,
  ) async {
    _size(tester);
    ZyraColors.restoreAppPalette(ZyraDevPalette.deepEmerald.name);
    await tester.pumpWidget(_app(const PersonalisationScreen()));
    await tester.pumpAndSettle();
    expect(find.text(_ordinaryScope), findsOneWidget);
    expect(find.text(_previewScope), findsNothing);
    expect(_snapshot(tester).palette, ZyraDevPalette.ivory);
    expect(_previewDecoration(tester).gradient, ZyraDevPalette.ivory.gradient);
    await tester.pumpWidget(const SizedBox.shrink());
    ZyraColors.restoreAppPalette(null);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ordinary real-font preview ignores a legacy Midnight blue request',
    (tester) async {
      _size(tester);
      ZyraColors.restoreAppPalette(ZyraDevPalette.midnightBlue.name);
      await tester.pumpWidget(_app(const PersonalisationScreen()));
      await tester.pumpAndSettle();
      expect(find.text(_ordinaryScope), findsOneWidget);
      expect(find.text(_previewScope), findsNothing);
      expect(_snapshot(tester).palette, ZyraDevPalette.ivory);
      expect(
        _previewDecoration(tester).gradient,
        ZyraDevPalette.ivory.gradient,
      );
      expect(
        tester
            .widget<Text>(find.text('Connecting Through Trust'))
            .style!
            .fontFamily,
        _readingFont,
      );
      await _capture(tester, '04-ivory-member');
      await tester.pumpWidget(const SizedBox.shrink());
      ZyraColors.restoreAppPalette(null);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'current preview has honest scope, readable values, fixed fonts',
    (tester) async {
      await _preview(tester);
      expect(find.text(_previewScope), findsOneWidget);
      expect(find.text(_ordinaryScope), findsNothing);
      final title = tester.widget<Text>(_key('personalisation-preview-title'));
      expect(title.style!.fontSize, 26);
      expect(title.style!.fontFamily, _readingFont);
      expect(
        tester.widget<Text>(find.text('ZYRA')).style!.fontFamily,
        _wordmarkFont,
      );
      expect(
        _previewDecoration(tester).gradient,
        ZyraDevPalette.ivory.gradient,
      );
      expect(_key('personalisation_background'), findsNothing);
      expect(find.text('Background'), findsNothing);
      await _tap(tester, _key('personalisation_font'));
      expect(
        find.byType(ZyraPersonalisationChoiceSheet<ZyraAppFont>),
        findsNothing,
      );
      expect(find.text('Poppins'), findsOneWidget);
      final fontAction = find.descendant(
        of: _key('personalisation_font'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(fontAction).onTap, isNull);
      for (final hint in [_goldHint, _hapticHint]) {
        await _reveal(tester, find.text(hint));
        expect(
          tester.widget<Text>(find.text(hint)).style!.color,
          ZyraColors.foregroundSecondary,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('320px200% retained controls wrap without clipping', (
    tester,
  ) async {
    await _preview(tester, compact: true, palette: ZyraDevPalette.midnightBlue);
    expect(_key('personalisation_background'), findsNothing);
    expect(_snapshot(tester).palette, ZyraDevPalette.ivory);
    await _reveal(tester, _key('personalisation_gold'));
    _readableText(
      tester,
      _key('personalisation_gold'),
      _goldHint,
      wrapped: true,
    );
    await _capture(tester, '03-compact-200');
    for (final entry in <(String, String)>[
      ('personalisation_gold', _goldHint),
      ('personalisation_font', 'ZYRA uses a separate wordmark font.'),
      ('personalisation_haptic', _hapticHint),
    ]) {
      await _reveal(tester, _key(entry.$1));
      _readableText(tester, _key(entry.$1), entry.$2);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('haptic chooser has actual 44px actions and selected semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final owner = await _preview(tester);
      await _tap(tester, _key('personalisation_haptic'));
      final sheet = tester
          .widget<ZyraPersonalisationChoiceSheet<ZyraHapticLevel>>(
            find.byType(ZyraPersonalisationChoiceSheet<ZyraHapticLevel>),
          );
      expect(sheet.options, ZyraHapticLevel.values);
      for (final option in sheet.options) {
        await _choiceSemantics(
          tester,
          option,
          selected: option == ZyraHapticLevel.subtle,
        );
      }
      await _tap(tester, _choice(ZyraHapticLevel.strong));
      expect(owner.currentState!.haptic, ZyraHapticLevel.strong);
      expect(_snapshot(tester).hapticLevel, ZyraHapticLevel.strong);
      expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.subtle);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('contrast audit checks actual normal text on locked Ivory', (
    tester,
  ) async {
    await _preview(tester);
    final valueText = find.descendant(
      of: _key('personalisation_gold'),
      matching: find.text('Off'),
    );
    final samples = <String, Color>{
      'selected-value': tester.widget<Text>(valueText).style!.color!,
      'row-hint': tester.widget<Text>(find.text(_goldHint)).style!.color!,
      'eyebrow': tester.widget<Text>(find.text('MAKE IT YOURS')).style!.color!,
      'accent-eyebrow': tester
          .widget<Text>(find.text('LIVE PREVIEW'))
          .style!
          .color!,
      'preview-hint': tester
          .widget<Text>(
            find.text('Your background changes appear immediately.'),
          )
          .style!
          .color!,
    };
    for (final sample in samples.entries) {
      final ratios = ZyraDevPalette.ivory.gradient.colors.map((background) {
        final surface = ['selected-value', 'row-hint'].contains(sample.key)
            ? Color.alphaBlend(ZyraColors.surfaceFill, background)
            : background;
        return _contrast(sample.value, surface);
      });
      final minimum = ratios.reduce(math.min);
      debugPrint(
        'PERSONALISATION_CONTRAST ivory ${sample.key} '
        '${minimum.toStringAsFixed(3)}:1',
      );
      expect(
        minimum,
        greaterThanOrEqualTo(4.5),
        reason: '${sample.key} must reach AA normal-text contrast on Ivory.',
      );
    }
    expect(tester.takeException(), isNull);
  });

  for (final guardian in [false, true]) {
    testWidgets('${guardian ? 'Guardian' : 'Seeker'} uses locked Ivory in the '
        'protected real-font Personalisation page without member writes', (
      tester,
    ) async {
      final paletteBefore = ZyraLocalPrefs.cachedAppPaletteName;
      final owner = _ShellOwner();
      await owner.mount(tester, guardian: guardian);
      await owner.openPersonalisation(tester);
      expect(_key('personalisation_background'), findsNothing);
      expect(_snapshot(tester).palette, ZyraDevPalette.ivory);
      expect(
        _previewDecoration(tester).gradient,
        ZyraDevPalette.ivory.gradient,
      );
      expect(find.text(_previewScope), findsOneWidget);
      expect(find.text(_ordinaryScope), findsNothing);
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
      expect(ZyraLocalPrefs.cachedAppPaletteName, paletteBefore);
      expect(_snapshot(tester).goldEnabled, isFalse);
      await _top(tester);
      await _capture(
        tester,
        guardian ? '06-ivory-guardian' : '05-ivory-seeker',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} controls cover blocks saved '
      'appearance and Back callbacks without killing the retained page',
      (tester) async {
        final owner = _ShellOwner();
        await owner.mount(tester, guardian: guardian);
        await owner.openPersonalisation(tester);
        final saved = tester.widget<PersonalisationScreen>(
          find.byType(PersonalisationScreen),
        );
        final savedBack = tester
            .widget<ZyraPullDownBackScope>(_key('concept_pull_down_back_scope'))
            .onBack;
        final before = _snapshot(tester);
        final pageState = tester.state(find.byType(PersonalisationScreen));
        await openZyraDevControls(tester);
        final checkpoint = owner.checkpoints.last;
        expect(
          find.byKey(const ValueKey('personalisation_haptic')),
          findsNothing,
        );
        saved.onHapticChanged!(ZyraHapticLevel.strong);
        saved.onGoldChanged!(!before.goldEnabled);
        savedBack();
        await tester.pump();
        expect(owner.checkpoints.last, checkpoint);
        await closeZyraDevControls(tester);
        expect(
          tester.state(find.byType(PersonalisationScreen)),
          same(pageState),
        );
        expect(_key('personalisation-unavailable'), findsNothing);
        expect(_snapshot(tester).palette, before.palette);
        expect(_snapshot(tester).hapticLevel, before.hapticLevel);
        expect(_snapshot(tester).goldEnabled, before.goldEnabled);
        await _tap(tester, _key('personalisation_gold_toggle'));
        expect(_snapshot(tester).goldEnabled, !before.goldEnabled);
        expect(_goldCanvas(), findsOneWidget);
        await _tap(tester, _key('personalisation_haptic'));
        await _tap(tester, _choice(ZyraHapticLevel.strong));
        expect(_snapshot(tester).hapticLevel, ZyraHapticLevel.strong);
        expect(_snapshot(tester).palette, ZyraDevPalette.ivory);
        expect(_snapshot(tester).goldEnabled, !before.goldEnabled);
        expect(_goldCanvas(), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Gold On survives Reset as rendered dust and later haptic change',
    (tester) async {
      final owner = _ShellOwner();
      await owner.mount(tester);
      await owner.openPersonalisation(tester);
      expect(_snapshot(tester).goldEnabled, isFalse);
      expect(_goldCanvas(), findsNothing);
      expect(
        tester
            .widget<ZyraPullDownBackScope>(_key('concept_pull_down_back_scope'))
            .paintBackground,
        isFalse,
      );
      await _top(tester);
      await _capture(tester, '01-current');
      final offBackground = await _backgroundEdgePixels(tester);
      await _tap(tester, _key('personalisation_gold_toggle'));
      expect(_snapshot(tester).goldEnabled, isTrue);
      expect(_goldCanvas(), findsOneWidget);
      await _top(tester);
      expect(
        await _backgroundEdgePixels(tester),
        isNot(orderedEquals(offBackground)),
        reason: 'Gold must be visible on the actual page background.',
      );
      expect(
        tester.widget<CustomPaint>(_goldCanvas()).painter,
        isA<ZyraOnboardingGoldPainter>(),
      );
      expect(ZyraDevAppGold.instance.renderingEnabled, isFalse);
      await openZyraDevControls(tester);
      await _tap(tester, _key('draft_reset'));
      expect(_key('dev_controls_page'), findsNothing);
      expect(owner.checkpoints.last.pages, isEmpty);
      expect(_goldCanvas(), findsOneWidget);
      await _nav(tester, 'Profile');
      await owner.openPersonalisation(tester);
      expect(_snapshot(tester).goldEnabled, isTrue);
      expect(
        tester.widget<Switch>(_key('personalisation_gold_toggle')).value,
        isTrue,
      );
      expect(_goldCanvas(), findsOneWidget);
      await _tap(tester, _key('personalisation_haptic'));
      await _tap(tester, _choice(ZyraHapticLevel.strong));
      expect(_snapshot(tester).hapticLevel, ZyraHapticLevel.strong);
      expect(_snapshot(tester).palette, ZyraDevPalette.ivory);
      expect(_snapshot(tester).goldEnabled, isTrue);
      expect(_goldCanvas(), findsOneWidget);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraDevAppGold.instance.renderingEnabled, isFalse);
    },
  );
}
