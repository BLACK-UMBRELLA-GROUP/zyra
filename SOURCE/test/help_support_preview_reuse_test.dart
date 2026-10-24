import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _route = ValueKey('bounded-original-help');
const _search = ValueKey('help-support-preview-search');
const _unavailable = ValueKey('help-support-preview-unavailable');
const _question = 'How do I request a Journey?';
const _answer = 'Choose someone thoughtfully, then send a Journey invitation.';
const _cancelQuestion = 'Can I cancel an invitation?';
const _categories = [
  ZyraHelpCategory('Journeys', [
    ZyraHelpEntry(_question, _answer),
    ZyraHelpEntry(
      _cancelQuestion,
      'Pending invitations can be cancelled before acceptance.',
    ),
  ]),
  ZyraHelpCategory('Privacy', [
    ZyraHelpEntry(
      'Which details stay private?',
      'Private answers are not shown in Browse.',
    ),
  ]),
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Help preview must not reach a backend or provider.');
  }
}

class _NavigationAudit extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}

Widget _harness(
  Widget help, {
  _NavigationAudit? navigation,
  double textScale = 1,
}) => MaterialApp(
  theme: ThemeData.dark(),
  navigatorObservers: [?navigation],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: help,
    ),
  ),
);

Future<void> _mount(
  WidgetTester tester, {
  required bool Function() canAct,
  List<ZyraHelpCategory> categories = _categories,
  String initialQuery = '',
  _NavigationAudit? navigation,
  bool embedded = true,
  Size size = const Size(393, 852),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _harness(
      HelpSupportScreen.preview(
        key: _route,
        canAct: canAct,
        categories: categories,
        initialQuery: initialQuery,
        embedded: embedded,
      ),
      navigation: navigation,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder _searchField() =>
    find.descendant(of: find.byKey(_search), matching: find.byType(TextField));

GestureDetector _questionGesture(WidgetTester tester, String question) {
  final gestures = find.ancestor(
    of: find.text(question),
    matching: find.byWidgetPredicate(
      (widget) => widget is GestureDetector && widget.onTap != null,
    ),
  );
  return tester.widget<GestureDetector>(gestures.first);
}

void _noAccountTools() {
  expect(
    find.byKey(const ValueKey('support-safety-case-status')),
    findsNothing,
  );
  expect(find.byKey(const ValueKey('help-support-email-action')), findsNothing);
  expect(
    find.byKey(const ValueKey('help-support-signed-in-line')),
    findsNothing,
  );
  expect(find.text('Your safety reports'), findsNothing);
  expect(find.text('Still need us?'), findsNothing);
  expect(find.text(HelpSupportScreen.supportEmail), findsNothing);
  expect(find.byType(SnackBar), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousOverrides = HttpOverrides.current;
  final telemetry = ZyraProductTelemetry.instance;
  const nativeChannels = [
    MethodChannel('plugins.flutter.io/url_launcher'),
    MethodChannel('plugins.flutter.io/url_launcher_ios'),
    MethodChannel('dev.fluttercommunity.plus/package_info'),
  ];
  late _NoNetwork network;
  late VoidCallback telemetryListener;
  late VoidCallback memberListener;
  late List<Object?> memberSnapshot;
  var nativeCalls = 0;
  var telemetryChanges = 0;
  var memberChanges = 0;

  List<Object?> snapshot() => [
    AppState.instance.gender,
    AppState.instance.plan,
    List.of(AppState.instance.photos),
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
  ];

  setUp(() {
    ZyraText.useTestFontStubs = true;
    network = _NoNetwork();
    HttpOverrides.global = network;
    telemetry.resetForTest();
    nativeCalls = 0;
    telemetryChanges = 0;
    memberChanges = 0;
    telemetryListener = () => telemetryChanges++;
    memberListener = () => memberChanges++;
    telemetry.addListener(telemetryListener);
    memberSnapshot = snapshot();
    AppState.instance.addListener(memberListener);
    for (final channel in nativeChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            nativeCalls++;
            throw StateError('Help preview must not launch native contact.');
          });
    }
  });

  tearDown(() {
    telemetry.removeListener(telemetryListener);
    AppState.instance.removeListener(memberListener);
    expect(telemetry.snapshot.sessionEventCount, 0);
    expect(telemetryChanges, 0);
    expect(nativeCalls, 0);
    expect(network.attempts, 0);
    expect(memberChanges, 0);
    expect(snapshot(), memberSnapshot);
    HttpOverrides.global = previousOverrides;
    ZyraText.useTestFontStubs = false;
    for (final channel in nativeChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  testWidgets('embedded preview reuses original FAQ UI without account tools', (
    tester,
  ) async {
    final navigation = _NavigationAudit();
    final retained = zyraHelpCategories.first.entries.first;
    await _mount(
      tester,
      canAct: () => true,
      categories: [
        ZyraHelpCategory('About ZYRA', [retained]),
      ],
      navigation: navigation,
    );

    // No Supabase client is initialized in this fixture. Mounting the live
    // contact card would try to read it; the preview never builds that subtree.
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    final title = find.byKey(const ValueKey('help-support-preview-title'));
    expect(tester.widget<Text>(title).style!.fontSize, 28);
    expect(tester.getTopLeft(title).dx, 20);
    expect(find.text('What do you need help with?'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text(retained.question)).style!.fontSize,
      14.5,
    );
    expect(find.text(retained.answer), findsNothing);
    _noAccountTools();

    await tester.tap(find.text(retained.question));
    await tester.pumpAndSettle();
    expect(find.text(retained.answer), findsOneWidget);
    expect(
      tester.widget<Text>(find.text(retained.answer)).style!.fontSize,
      13.5,
    );
    expect(find.byType(AnimatedRotation), findsOneWidget);
    expect(navigation.pushes, 1);
    _noAccountTools();
    await tester.tap(find.text(retained.question));
    await tester.pumpAndSettle();
    expect(find.text(retained.answer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search matches supplied questions answers and category titles', (
    tester,
  ) async {
    await _mount(tester, canAct: () => true);
    await tester.enterText(_searchField(), '  ACCEPTANCE  ');
    await tester.pumpAndSettle();
    expect(find.text(_cancelQuestion), findsOneWidget);
    expect(find.text(_question), findsNothing);
    expect(find.text('Which details stay private?'), findsNothing);

    await tester.enterText(_searchField(), ' privacy ');
    await tester.pumpAndSettle();
    expect(find.text('Which details stay private?'), findsOneWidget);
    expect(find.text(_cancelQuestion), findsNothing);

    await tester.enterText(_searchField(), 'request');
    await tester.pumpAndSettle();
    expect(find.text(_question), findsOneWidget);
    expect(find.text(_cancelQuestion), findsNothing);

    // An old global Help answer matching "dating" must not leak into the
    // caller's bounded subset, nor offer an omitted email tool on no results.
    await tester.enterText(_searchField(), 'dating');
    await tester.pumpAndSettle();
    expect(find.text('Nothing matched "dating"'), findsOneWidget);
    expect(find.text('Try a different word.'), findsOneWidget);
    expect(find.text('Is ZYRA a dating app?'), findsNothing);
    expect(find.textContaining('email us below'), findsNothing);
    _noAccountTools();
  });

  testWidgets(
    'initial query and supplied content are local frozen route data',
    (tester) async {
      final entries = <ZyraHelpEntry>[const ZyraHelpEntry(_question, _answer)];
      final supplied = <ZyraHelpCategory>[
        ZyraHelpCategory('Journeys', entries),
      ];
      await _mount(
        tester,
        canAct: () => true,
        categories: supplied,
        initialQuery: 'request',
      );
      expect(
        tester.widget<TextField>(_searchField()).controller!.text,
        'request',
      );
      entries.clear();
      supplied.clear();
      await tester.enterText(_searchField(), '');
      await tester.pumpAndSettle();
      expect(find.text(_question), findsOneWidget);
      await tester.tap(find.text(_question));
      await tester.pumpAndSettle();
      expect(find.text(_answer), findsOneWidget);
      _noAccountTools();
    },
  );

  testWidgets('revoked stale search and FAQ callbacks hide rather than act', (
    tester,
  ) async {
    var allowed = true;
    await _mount(tester, canAct: () => allowed);
    final searchCallback = tester.widget<TextField>(_searchField()).onChanged!;
    final faqCallback = _questionGesture(tester, _question).onTap!;
    allowed = false;
    // Invoke the previously enabled callbacks before a parent rebuild.
    faqCallback();
    searchCallback('no longer admitted');
    await tester.pumpAndSettle();
    expect(find.byKey(_unavailable), findsOneWidget);
    expect(find.byKey(_search), findsNothing);
    expect(find.text(_answer), findsNothing);
    _noAccountTools();

    allowed = true;
    await tester.pumpWidget(
      _harness(
        HelpSupportScreen.preview(
          key: _route,
          canAct: () => allowed,
          categories: _categories,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_unavailable), findsOneWidget);
    expect(find.byKey(_search), findsNothing);
    faqCallback();
    searchCallback('still stale');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    _noAccountTools();
  });

  testWidgets(
    'a preview cannot fall back to default live Help on widget reuse',
    (tester) async {
      await _mount(tester, canAct: () => true);
      final owner = tester.state(find.byType(HelpSupportScreen));
      await tester.pumpWidget(_harness(const HelpSupportScreen(key: _route)));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(HelpSupportScreen)), same(owner));
      expect(find.byKey(_unavailable), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      _noAccountTools();

      await tester.pumpWidget(
        _harness(
          HelpSupportScreen.preview(
            key: _route,
            canAct: () => true,
            categories: _categories,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_unavailable), findsOneWidget);
      expect(tester.takeException(), isNull);
      _noAccountTools();
    },
  );

  testWidgets('failed admission remains closed without live fallback', (
    tester,
  ) async {
    await _mount(
      tester,
      canAct: () => throw StateError('Expired local presentation grant.'),
    );
    expect(find.byKey(_unavailable), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    _noAccountTools();
  });

  testWidgets('compact large-text layout retains readable scrollable FAQs', (
    tester,
  ) async {
    final retained = zyraHelpCategories.first.entries.first;
    await _mount(
      tester,
      canAct: () => true,
      categories: [
        ZyraHelpCategory('About ZYRA', [retained]),
      ],
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
    await tester.ensureVisible(find.text(retained.question));
    await tester.pumpAndSettle();
    await tester.tap(find.text(retained.question));
    await tester.pumpAndSettle();
    expect(find.text(retained.answer), findsOneWidget);
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('help-support-preview-scroll')),
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scroll).position.maxScrollExtent,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
    _noAccountTools();
  });

  testWidgets(
    'standalone preview stays local and uses the shared brand canvas',
    (tester) async {
      await _mount(tester, canAct: () => true, embedded: false);
      expect(find.byType(Scaffold), findsNWidgets(2));
      expect(find.byType(AppBar), findsNothing);
      expect(
        find.byKey(const ValueKey('help-support-preview-title')),
        findsOneWidget,
      );
      await tester.tap(find.text(_question));
      await tester.pumpAndSettle();
      expect(find.text(_answer), findsOneWidget);
      expect(tester.takeException(), isNull);
      _noAccountTools();
    },
  );

  test('original Help constructor and live tools retain their contract', () {
    const original = HelpSupportScreen();
    expect(original.initialQuery, '');
    expect(original.telemetrySurface, ZyraTelemetrySurface.seeker);
    expect(HelpSupportScreen.supportEmail, 'support@zyraconnect.app');
    expect(
      HelpSupportScreen.supportMailto.toString(),
      'mailto:support@zyraconnect.app',
    );
    final source = File(
      'lib/screens/settings/help_support_screen.dart',
    ).readAsStringSync();
    expect(source, contains('builder: (_) => const SafetyCaseStatusScreen()'));
    expect(
      source,
      contains('_ContactCard(telemetrySurface: widget.telemetrySurface)'),
    );
    expect(source, contains('final email = ZyraAuth.currentUser?.email;'));
    expect(source, contains('LaunchMode.externalApplication'));
    expect(source, contains('ZyraTelemetryAction.supportAnswer'));
    expect(source, contains('ZyraTelemetryAction.supportEmail'));
    expect(source, contains('if (opening && widget.recordTelemetry)'));
  });
}
