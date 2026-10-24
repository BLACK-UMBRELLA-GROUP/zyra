// Review-only real-font captures of retained code-entry and Help presentation.
// Lookup uses canonical offline fixtures; camera denial is deliberately fake.
// No native camera, member lookup, account identity, telemetry or golden update.
// Optional immutable PNGs: --dart-define=ZYRA_CODE_REUSE_VISUAL_OUTPUT=<absolute packet>/code-help-captures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/dev/zyra_draft_code_entry.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_known_person_code_content.dart';

const _output = String.fromEnvironment('ZYRA_CODE_REUSE_VISUAL_OUTPUT');
const _boundary = ValueKey('retained-code-help-real-font-review');
const _font = 'PoppinsRetainedCodeHelpAudit';
const _manualField = ValueKey('known-person-code-field');
const _check = ValueKey('known-person-check-code');
const _view = ValueKey('draft_known_person_view');
const _reset = ValueKey('known-person-different-code');
const _codeScroll = ValueKey('draft_scan_entry_scroll');
const _helpScroll = ValueKey('help-support-preview-scroll');
const _helpSearch = ValueKey('help-support-preview-search');
const _cameraManual = ValueKey('known-person-camera-manual-entry');

// Only unchanged answers that do not describe the old Consider/Paused flow.
// This fixture does not edit or invent Help answers, or claim release readiness.
final _signIn = zyraHelpCategories
    .expand((category) => category.entries)
    .singleWhere((entry) => entry.question == 'How do I sign in?');
final _blocking = zyraHelpCategories
    .expand((category) => category.entries)
    .singleWhere(
      (entry) => entry.question == 'Can someone find out I blocked them?',
    );
final _helpCategories = [
  ZyraHelpCategory('Getting started', [_signIn]),
  ZyraHelpCategory('Safety and reporting', [_blocking]),
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Retained-code visual review must remain offline.');
  }
}

class _CodeFixture extends StatefulWidget {
  const _CodeFixture({required this.fixtureKey}) : super(key: fixtureKey);
  final GlobalKey<_CodeFixtureState> fixtureKey;

  @override
  State<_CodeFixture> createState() => _CodeFixtureState();
}

class _CodeFixtureState extends State<_CodeFixture> {
  final checked = <String>[];
  DraftProfile? viewed;
  int cameraBuilds = 0;

  @override
  Widget build(BuildContext context) => ZyraDraftCodeEntry(
    canAct: () => mounted,
    lookupCode: (code) async {
      checked.add(code);
      return ZyraDraftKnownPersonCodes.resolve(code);
    },
    onViewProfile: (person) => viewed = person,
    captureBuilder: (context, canCapture, onCode, onManualEntry) {
      cameraBuilds++;
      return _FakeDeniedCamera(
        canCapture: canCapture,
        onManualEntry: onManualEntry,
      );
    },
  );
}

/// Deliberately fake captureBuilder, copying the retained permission-failure
/// presentation only. No MobileScanner/controller/platform channel is created.
class _FakeDeniedCamera extends StatelessWidget {
  const _FakeDeniedCamera({
    required this.canCapture,
    required this.onManualEntry,
  });

  final bool Function() canCapture;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) => Stack(
    key: const ValueKey('visual-fake-denied-camera'),
    fit: StackFit.expand,
    children: [
      ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  color: ZyraColors.surfaceSignal,
                  size: 30,
                ),
                const SizedBox(height: 14),
                Text(
                  'Camera unavailable. Enter the code instead.',
                  textAlign: TextAlign.center,
                  style: ZyraText.subtext(size: 12.5),
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 24,
        right: 24,
        bottom: 24,
        child: SafeArea(
          top: false,
          child: ZyraKnownPersonCodePill(
            key: _cameraManual,
            icon: Icons.keyboard_outlined,
            label: 'Enter code instead',
            onTap: () {
              if (canCapture()) onManualEntry();
            },
          ),
        ),
      ),
    ],
  );
}

Future<void> _mount(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(393, 852),
  double scale = 1,
  bool quiet = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final insets = EdgeInsets.only(
    top: size.height <= 600 ? 24 : 59,
    bottom: size.height <= 600 ? 24 : 34,
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
        splashFactory: NoSplash.splashFactory,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: insets,
          viewPadding: insets,
          textScaler: TextScaler.linear(scale),
          disableAnimations: quiet,
          accessibleNavigation: quiet,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  _clean(tester, size);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<String> _frame(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  expect(image, isNotNull, reason: name);
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(data, isNotNull, reason: name);
    final bytes = data!.buffer.asUint8List();
    if (_output.isNotEmpty) {
      expect(
        _output.startsWith('/'),
        isTrue,
        reason: 'Use the root-coordinated absolute review packet.',
      );
      final directory = Directory(_output);
      expect(directory.existsSync(), isTrue);
      final file = File('${directory.path}/$name.png');
      expect(
        file.existsSync(),
        isFalse,
        reason: 'Retain immutable review captures.',
      );
      await tester.runAsync(() => file.writeAsBytes(bytes, flush: true));
    }
    return sha256.convert(bytes).toString();
  } finally {
    image!.dispose();
  }
}

void _clean(WidgetTester tester, Size size) {
  expect(tester.takeException(), isNull);
  expect(tester.getSize(find.byKey(_boundary)), size);
  expect(find.byType(AppBar), findsNothing);
  expect(find.byType(BackButton), findsNothing);
  expect(find.byType(Scaffold), findsOneWidget);
  expect(find.byType(ZyraCodeCapture), findsNothing);
  expect(find.byKey(const ValueKey('known-person-consider')), findsNothing);
  expect(
    find.textContaining(
      RegExp(r'\b(?:Consider|Match|Potential|Paused)\b'),
      findRichText: true,
    ),
    findsNothing,
  );
  expect(
    find.byKey(const ValueKey('support-safety-case-status')),
    findsNothing,
  );
  expect(find.byKey(const ValueKey('help-support-email-action')), findsNothing);
  expect(
    find.byKey(const ValueKey('help-support-signed-in-line')),
    findsNothing,
  );
}

ScrollableState _scrollable(WidgetTester tester, Key key) =>
    tester.state<ScrollableState>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Scrollable))
          .first,
    );

void _normalFit(WidgetTester tester, Size size, Key scroll) {
  _clean(tester, size);
  final position = _scrollable(tester, scroll).position;
  expect(position.maxScrollExtent, closeTo(0, .01));
  expect(position.pixels, 0);
}

void _fullResultActionNames(WidgetTester tester) {
  for (final label in ['Different code', 'View profile']) {
    final text = find.text(label);
    expect(text, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
      isFalse,
      reason: 'Action names must remain readable at the requested text size.',
    );
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _checkCode(WidgetTester tester, String code) async {
  final field = find.byKey(_manualField);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, code);
  await _tap(tester, find.byKey(_check));
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _showBottom(WidgetTester tester, Key scroll) async {
  // Exercise the real scroll fallback, not a direct controller offset change.
  await tester.drag(find.byKey(scroll), const Offset(0, -1600));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _showTop(WidgetTester tester, Key scroll) async {
  await tester.drag(find.byKey(scroll), const Offset(0, 1600));
  await tester.pumpAndSettle();
  expect(_scrollable(tester, scroll).position.pixels, closeTo(0, .01));
}

Widget _help() =>
    HelpSupportScreen.preview(canAct: () => true, categories: _helpCategories);

Finder _helpField() => find.descendant(
  of: find.byKey(_helpSearch),
  matching: find.byType(TextField),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousOverrides = HttpOverrides.current;
  final telemetry = ZyraProductTelemetry.instance;
  late _NoNetwork network;
  late List<Object?> memberSnapshot;
  late VoidCallback memberListener;
  late VoidCallback telemetryListener;
  var memberChanges = 0;
  var telemetryChanges = 0;
  var nativeCalls = 0;
  const nativeChannels = [
    MethodChannel('plugins.flutter.io/url_launcher'),
    MethodChannel('plugins.flutter.io/url_launcher_ios'),
    MethodChannel('dev.fluttercommunity.plus/package_info'),
    MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
  ];

  List<Object?> snapshot() => [
    AppState.instance.gender,
    AppState.instance.plan,
    List.of(AppState.instance.photos),
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
  ];

  setUpAll(() async {
    final reading = FontLoader(_font);
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
    final wordmark = FontLoader('SyneRetainedCodeHelpAudit')
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

  setUp(() {
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraText.testWordmarkFontFamily = 'SyneRetainedCodeHelpAudit';
    ZyraText.restoreAppFont(null);
    ZyraColors.restoreAppPalette(null);
    telemetry.resetForTest();
    nativeCalls = 0;
    memberChanges = 0;
    telemetryChanges = 0;
    memberSnapshot = snapshot();
    memberListener = () => memberChanges++;
    telemetryListener = () => telemetryChanges++;
    AppState.instance.addListener(memberListener);
    telemetry.addListener(telemetryListener);
    for (final channel in nativeChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            nativeCalls++;
            throw StateError(
              'Visual fixture must not launch a native service.',
            );
          });
    }
  });

  tearDown(() {
    AppState.instance.removeListener(memberListener);
    telemetry.removeListener(telemetryListener);
    expect(snapshot(), memberSnapshot);
    expect(memberChanges, 0);
    expect(telemetry.snapshot.sessionEventCount, 0);
    expect(telemetryChanges, 0);
    expect(nativeCalls, 0);
    expect(network.attempts, 0);
    HttpOverrides.global = previousOverrides;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    for (final channel in nativeChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  testWidgets('normal code entry result and invalid state fit one page', (
    tester,
  ) async {
    const size = Size(393, 852);
    final fixture = GlobalKey<_CodeFixtureState>();
    await _mount(tester, _CodeFixture(fixtureKey: fixture));
    _normalFit(tester, size, _codeScroll);
    final frames = {await _frame(tester, '393x852-code-manual-rest')};
    final sara = draftProfiles.singleWhere(
      (person) => person.id == 'draft-sara',
    );
    final code = ZyraDraftKnownPersonCodes.codeFor(sara);
    await _checkCode(tester, code);
    _normalFit(tester, size, _codeScroll);
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('27 · Birmingham'), findsOneWidget);
    expect(find.byKey(_view).hitTestable(), findsOneWidget);
    frames.add(await _frame(tester, '393x852-code-canonical-sara-checked'));
    await _tap(tester, find.byKey(_view));
    expect(fixture.currentState!.viewed, same(sara));
    expect(fixture.currentState!.checked, [code]);

    await _tap(tester, find.byKey(_reset));
    await _checkCode(tester, 'ZYRA-DRAFT-NOBODY');
    _normalFit(tester, size, _codeScroll);
    expect(find.text('That code is not available.'), findsOneWidget);
    expect(find.byKey(_view), findsNothing);
    expect(find.text('Sara'), findsNothing);
    frames.add(await _frame(tester, '393x852-code-invalid-entry'));
    expect(frames, hasLength(3));
    expect(fixture.currentState!.cameraBuilds, 0);
  });

  testWidgets('fake denied camera retains usable manual-entry fallback', (
    tester,
  ) async {
    const size = Size(393, 852);
    final fixture = GlobalKey<_CodeFixtureState>();
    await _mount(tester, _CodeFixture(fixtureKey: fixture));
    await _tap(tester, find.text('Scan code'));
    _clean(tester, size);
    expect(
      find.byKey(const ValueKey('visual-fake-denied-camera')),
      findsOneWidget,
    );
    expect(find.byKey(_cameraManual).hitTestable(), findsOneWidget);
    final denied = await _frame(tester, '393x852-code-fake-camera-denied');
    await _tap(tester, find.byKey(_cameraManual));
    _normalFit(tester, size, _codeScroll);
    expect(find.byKey(_manualField).hitTestable(), findsOneWidget);
    final manual = await _frame(
      tester,
      '393x852-code-permission-manual-fallback',
    );
    expect(denied, isNot(manual));
    expect(fixture.currentState!.checked, isEmpty);
    expect(fixture.currentState!.viewed, isNull);
    expect(fixture.currentState!.cameraBuilds, greaterThan(0));
  });

  testWidgets('embedded original Help search and FAQ retain shared theme', (
    tester,
  ) async {
    const size = Size(393, 852);
    await _mount(tester, _help());
    _normalFit(tester, size, _helpScroll);
    final title = find.byKey(const ValueKey('help-support-preview-title'));
    expect(tester.widget<Text>(title).style!.fontFamily, _font);
    expect(tester.widget<Text>(title).style!.fontSize, 28);
    expect(tester.getTopLeft(title).dx, 20);
    await _frame(tester, '393x852-help-original-faq-rest');
    await tester.enterText(_helpField(), 'sign in');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    _normalFit(tester, size, _helpScroll);
    expect(find.text(_blocking.question), findsNothing);
    await _frame(tester, '393x852-help-search-sign-in');
    await _tap(tester, find.text(_signIn.question));
    _normalFit(tester, size, _helpScroll);
    expect(find.text(_signIn.answer), findsOneWidget);
    expect(
      tester.widget<Text>(find.text(_signIn.answer)).style!.fontFamily,
      _font,
    );
    await _frame(tester, '393x852-help-original-answer-expanded');
  });

  testWidgets('compact code manual and checked result remain reachable', (
    tester,
  ) async {
    const size = Size(320, 568);
    final fixture = GlobalKey<_CodeFixtureState>();
    await _mount(tester, _CodeFixture(fixtureKey: fixture), size: size);
    await _frame(tester, '320x568-code-manual-top');
    await tester.ensureVisible(find.byKey(_check));
    await tester.pumpAndSettle();
    expect(find.byKey(_check).hitTestable(), findsOneWidget);
    await _frame(tester, '320x568-code-manual-action-reachable');
    final sara = draftProfiles.singleWhere(
      (person) => person.id == 'draft-sara',
    );
    await _checkCode(tester, ZyraDraftKnownPersonCodes.codeFor(sara));
    await tester.ensureVisible(find.byKey(_view));
    await tester.pumpAndSettle();
    _clean(tester, size);
    expect(find.byKey(_view).hitTestable(), findsOneWidget);
    await _frame(tester, '320x568-code-sara-view-reachable');
  });

  testWidgets(
    'compact 200 percent code uses clean accessible scroll fallback',
    (tester) async {
      const size = Size(320, 568);
      final fixture = GlobalKey<_CodeFixtureState>();
      await _mount(
        tester,
        _CodeFixture(fixtureKey: fixture),
        size: size,
        scale: 2,
      );
      expect(
        _scrollable(tester, _codeScroll).position.maxScrollExtent,
        greaterThan(0),
      );
      await _frame(tester, '320x568-code-text200-manual-top');
      await tester.ensureVisible(find.byKey(_check));
      await tester.pumpAndSettle();
      expect(find.byKey(_check).hitTestable(), findsOneWidget);
      await _frame(tester, '320x568-code-text200-manual-action');
      final sara = draftProfiles.singleWhere(
        (person) => person.id == 'draft-sara',
      );
      await _checkCode(tester, ZyraDraftKnownPersonCodes.codeFor(sara));
      await _showTop(tester, _codeScroll);
      _clean(tester, size);
      await _frame(tester, '320x568-code-text200-sara-top');
      await tester.ensureVisible(find.byKey(_view));
      await tester.pumpAndSettle();
      expect(find.byKey(_view).hitTestable(), findsOneWidget);
      _fullResultActionNames(tester);
      await _frame(tester, '320x568-code-text200-sara-view');
    },
  );

  testWidgets('compact 200 percent original Help answer stays readable', (
    tester,
  ) async {
    const size = Size(320, 568);
    await _mount(tester, _help(), size: size, scale: 2);
    await _frame(tester, '320x568-help-text200-rest');
    await tester.enterText(_helpField(), 'sign in');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _frame(tester, '320x568-help-text200-search');
    await _tap(tester, find.text(_signIn.question));
    expect(find.text(_signIn.answer), findsOneWidget);
    await _showTop(tester, _helpScroll);
    _clean(tester, size);
    await _frame(tester, '320x568-help-text200-original-answer-top');
    await _showBottom(tester, _helpScroll);
    _clean(tester, size);
    expect(_scrollable(tester, _helpScroll).position.pixels, greaterThan(0));
    await _frame(tester, '320x568-help-text200-original-answer-bottom');
  });

  testWidgets(
    'quiet motion code and Help retain the same settled presentation',
    (tester) async {
      const size = Size(393, 852);
      final fixture = GlobalKey<_CodeFixtureState>();
      await _mount(tester, _CodeFixture(fixtureKey: fixture), quiet: true);
      _normalFit(tester, size, _codeScroll);
      await _frame(tester, '393x852-quiet-code-manual');
      final sara = draftProfiles.singleWhere(
        (person) => person.id == 'draft-sara',
      );
      await _checkCode(tester, ZyraDraftKnownPersonCodes.codeFor(sara));
      _normalFit(tester, size, _codeScroll);
      await _frame(tester, '393x852-quiet-code-sara');

      // Replace only the local fixture page; no navigation or account action.
      await _mount(tester, _help(), quiet: true);
      await tester.enterText(_helpField(), 'sign in');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _tap(tester, find.text(_signIn.question));
      _normalFit(tester, size, _helpScroll);
      expect(find.text(_signIn.answer), findsOneWidget);
      await _frame(tester, '393x852-quiet-help-original-answer');
    },
  );
}
