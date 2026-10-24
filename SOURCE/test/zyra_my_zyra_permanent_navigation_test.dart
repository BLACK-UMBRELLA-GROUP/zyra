import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_my_zyra_navigation_card.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

const _lead = SupportiveCard(
  id: 'concept-request-draft-amira',
  section: SupportiveSection.needsYou,
  title: 'Journey request from Amira',
  actionLabel: 'View activity',
  target: ZyraDashboardTarget.connectionsActivity,
  hasNewActivity: true,
);
const _requests = SupportiveCard(
  id: 'concept-my-requests',
  section: SupportiveSection.stand,
  title: 'Journey requests',
  detail: '1 received · 0 sent',
  actionLabel: 'View requests',
  target: ZyraDashboardTarget.connectionsActivity,
  hasNewActivity: true,
);
const _zeroRequests = SupportiveCard(
  id: 'concept-my-requests',
  section: SupportiveSection.stand,
  title: 'Journey requests',
  detail: '0 received · 0 sent',
  actionLabel: 'View requests',
  target: ZyraDashboardTarget.connectionsActivity,
);
const _introductions = SupportiveCard(
  id: 'concept-my-introductions',
  section: SupportiveSection.stand,
  title: 'Introductions',
  detail: '0 introductions',
  actionLabel: 'View introductions',
  target: ZyraDashboardTarget.connectionsActivity,
);
const _ended = SupportiveCard(
  id: 'concept-my-ended',
  section: SupportiveSection.stand,
  title: 'Ended Journeys',
  detail: '0 ended',
  actionLabel: 'View Ended',
  target: ZyraDashboardTarget.connectionsActivity,
);

DashboardResolution get _resolution => SupportiveDashboardFixtures.build(
  SupportivePreviewScenario.allClear,
).resolution;

Widget _app({
  required bool permanent,
  List<SupportiveCard> cards = const [_lead, _requests, _introductions, _ended],
  ValueChanged<SupportiveCard>? onNavigate,
  double scale = 1,
}) => MaterialApp(
  theme: ThemeData(
    brightness: Brightness.dark,
    textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: ZyraQuietDashboard(
    key: const ValueKey('permanent-navigation-owner'),
    resolution: _resolution,
    comparisonClock: SupportiveDashboardFixtures.clock,
    fixtureCards: cards,
    fixtureMode: true,
    singlePage: true,
    permanentNavigation: permanent,
    onNavigate: onNavigate,
  ),
);

Finder _key(String id) => find.byKey(ValueKey(id));

Finder get _scrollable => find.descendant(
  of: _key('my-zyra-quiet-scroll-0'),
  matching: find.byType(Scrollable),
);

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    140,
    scrollable: _scrollable,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
}

void _expectWholeWordsFit(WidgetTester tester, Finder title) {
  final widget = tester.widget<Text>(title);
  final context = tester.element(title);
  final width = tester.getSize(title).width;
  expect(widget.style, isNotNull);
  for (final word in widget.data!.trim().split(RegExp(r'\s+'))) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: widget.style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    expect(painter.width, lessThanOrEqualTo(width + .5), reason: word);
    painter.dispose();
  }
  expect(
    tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
    isFalse,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const font = 'PoppinsPermanentNavigation';
  final previousStubs = ZyraText.useTestFontStubs;
  final previousReadingFont = ZyraText.testReadingFontFamily;
  setUpAll(() async {
    final loader = FontLoader(font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await loader.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = font;
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = previousStubs;
    ZyraText.testReadingFontFamily = previousReadingFont;
  });
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
  });
  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

  testWidgets('New activity stays distinct from three permanent destinations', (
    tester,
  ) async {
    final opened = <String>[];
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _app(permanent: true, onNavigate: (card) => opened.add(card.id)),
      );
      await tester.pumpAndSettle();
      expect(_key('my-zyra-new-activity-heading'), findsOneWidget);
      expect(_key('my-zyra-quick-access-heading'), findsOneWidget);
      expect(find.byType(ZyraMyZyraNavigationCard), findsNWidgets(3));
      expect(_key('my-zyra-activity-${_lead.id}'), findsOneWidget);
      expect(_key('my-zyra-new-${_lead.id}'), findsNothing);
      expect(_key('my-zyra-new-${_requests.id}'), findsNothing);
      expect(_key('my-zyra-new-${_introductions.id}'), findsNothing);
      expect(_key('my-zyra-new-${_ended.id}'), findsNothing);
      for (final card in [_requests, _introductions, _ended]) {
        final route = _key('my-zyra-route-${card.id}');
        await _reveal(tester, route);
        final node = tester.getSemantics(route).getSemanticsData();
        expect(node.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(node.label, contains(card.title));
        expect(node.label, contains(card.detail!));
        expect(node.value, card.hasNewActivity ? 'New activity' : isEmpty);
        expect(tester.getSize(route).height, greaterThanOrEqualTo(98));
        expect(find.text(card.detail!), findsOneWidget);
        await tester.tap(route);
        await tester.pumpAndSettle();
      }
      expect(opened, [_requests.id, _introductions.id, _ended.id]);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('No sample destination is invented when the caller has none', (
    tester,
  ) async {
    await tester.pumpWidget(_app(permanent: true, cards: const []));
    await tester.pumpAndSettle();
    expect(find.byType(ZyraMyZyraNavigationCard), findsNothing);
    expect(_key('my-zyra-quick-access-heading'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All three destinations remain when counts are zero', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        permanent: true,
        cards: const [_zeroRequests, _introductions, _ended],
        onNavigate: (card) => opened.add(card.id),
      ),
    );
    await tester.pumpAndSettle();
    expect(_key('my-zyra-new-activity-heading'), findsNothing);
    expect(_key('my-zyra-quick-access-heading'), findsOneWidget);
    expect(find.byType(ZyraMyZyraNavigationCard), findsNWidgets(3));
    for (final card in [_zeroRequests, _introductions, _ended]) {
      final route = _key('my-zyra-route-${card.id}');
      await _reveal(tester, route);
      expect(find.text(card.detail!), findsOneWidget);
      expect(_key('my-zyra-new-${card.id}'), findsNothing);
      await tester.tap(route);
      await tester.pumpAndSettle();
    }
    expect(opened, [_zeroRequests.id, _introductions.id, _ended.id]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Default layout retains the original status renderer', (
    tester,
  ) async {
    await tester.pumpWidget(_app(permanent: false));
    await tester.pumpAndSettle();
    expect(find.byType(ZyraMyZyraNavigationCard), findsNothing);
    expect(_key('my-zyra-quick-access-heading'), findsNothing);
    expect(_key('my-zyra-new-activity-heading'), findsNothing);
    await _reveal(tester, _key('my-zyra-route-${_requests.id}'));
    expect(_key('my-zyra-new-${_requests.id}'), findsNothing);
    expect(_key('my-zyra-activity-${_requests.id}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New activity heading uses readable opaque brand ink', (
    tester,
  ) async {
    await tester.pumpWidget(_app(permanent: true));
    await tester.pumpAndSettle();
    final ink = tester
        .widget<Text>(_key('my-zyra-new-activity-heading'))
        .style!
        .color!;
    final a = ink.computeLuminance();
    final b = ZyraColors.royalPurple.computeLuminance();
    final contrast = (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
    expect(ink.a, 1);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });

  testWidgets('Seen pending activity has no permanent new heading marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        permanent: true,
        cards: const [
          SupportiveCard(
            id: 'concept-request-draft-amira',
            section: SupportiveSection.needsYou,
            title: 'Journey request from Amira',
            actionLabel: 'View request',
            target: ZyraDashboardTarget.connectionsActivity,
          ),
          SupportiveCard(
            id: 'concept-my-requests',
            section: SupportiveSection.stand,
            title: 'Journey requests',
            detail: '1 received · 0 sent',
            actionLabel: 'View requests',
            target: ZyraDashboardTarget.connectionsActivity,
          ),
          _introductions,
          _ended,
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(_key('my-zyra-new-activity-heading'), findsNothing);
    expect(_key('my-zyra-activity-heading'), findsOneWidget);
    expect(_key('my-zyra-new-${_lead.id}'), findsNothing);
    expect(_key('my-zyra-new-${_requests.id}'), findsNothing);
    expect(find.byType(ZyraMyZyraNavigationCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('A layout change invalidates the older row callback', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _app(permanent: true, onNavigate: (card) => opened.add(card.id)),
    );
    await tester.pumpAndSettle();
    final route = _key('my-zyra-route-${_requests.id}');
    await _reveal(tester, route);
    final stale = tester.widget<InkWell>(route).onTap!;
    await tester.pumpWidget(
      _app(permanent: false, onNavigate: (card) => opened.add(card.id)),
    );
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    expect(find.byType(ZyraMyZyraNavigationCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Soft rows remain readable and tappable at 320 and 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(permanent: true, scale: 2));
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byType(ZyraQuietDashboard)),
      ).scale(17),
      34,
    );
    await _reveal(tester, _key('my-zyra-item-${_lead.id}'));
    _expectWholeWordsFit(tester, find.text(_lead.title));
    for (final card in [_requests, _introductions, _ended]) {
      final route = _key('my-zyra-route-${card.id}');
      await _reveal(tester, route);
      final title = find.text(card.title);
      expect(tester.widget<Text>(title).maxLines, isNull);
      _expectWholeWordsFit(tester, title);
      expect(tester.getSize(route).height, greaterThanOrEqualTo(98));
      expect(tester.takeException(), isNull);
    }
  });
}
