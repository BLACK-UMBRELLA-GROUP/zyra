import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_my_zyra_navigation_card.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

const _a = SupportiveCard(
  id: 'activity-a',
  section: SupportiveSection.needsYou,
  title: 'Journey request from Amira',
  detail: 'A fictional request to review.',
  actionLabel: 'View request',
  target: ZyraDashboardTarget.connectionsActivity,
  hasNewActivity: true,
);
const _b = SupportiveCard(
  id: 'activity-b',
  section: SupportiveSection.needsYou,
  title: 'Sara accepted your request',
  detail: 'A different fictional activity example.',
  actionLabel: 'View Journey',
  target: ZyraDashboardTarget.connectionsJourneys,
  hasNewActivity: true,
);
const _destinations = [
  SupportiveCard(
    id: 'concept-my-requests',
    section: SupportiveSection.stand,
    title: 'Journey requests',
    detail: '1 received · 0 sent',
    actionLabel: 'View requests',
    target: ZyraDashboardTarget.connectionsActivity,
  ),
  SupportiveCard(
    id: 'concept-my-introductions',
    section: SupportiveSection.stand,
    title: 'Introductions',
    detail: '0 introductions',
    actionLabel: 'View introductions',
    target: ZyraDashboardTarget.connectionsActivity,
  ),
  SupportiveCard(
    id: 'concept-my-ended',
    section: SupportiveSection.stand,
    title: 'Ended Journeys',
    detail: '0 ended',
    actionLabel: 'View Ended',
    target: ZyraDashboardTarget.connectionsActivity,
  ),
];
const _change = SupportiveCard(
  id: 'activity-change',
  section: SupportiveSection.changed,
  title: 'Guardian link changed',
  detail: 'Fictional change details.',
  actionLabel: 'View Guardian',
  target: ZyraDashboardTarget.guardian,
  isUnread: true,
);

Finder _key(String id) => find.byKey(ValueKey(id));

DashboardResolution get _resolution => SupportiveDashboardFixtures.build(
  SupportivePreviewScenario.allClear,
).resolution;

Widget _app({
  Object? activityKey = 'example-a',
  Widget? controls = const Text('Checklist preview controls'),
  List<SupportiveCard> activity = const [_a],
  bool fixture = true,
  bool singlePage = true,
  bool permanent = true,
  bool reducedMotion = false,
  bool accessibleNavigation = false,
  ValueChanged<SupportiveCard>? onNavigate,
  ValueChanged<SupportiveCard>? onViewed,
}) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reducedMotion,
      accessibleNavigation: accessibleNavigation,
    ),
    child: child!,
  ),
  home: ZyraQuietDashboard(
    key: const ValueKey('activity-preview-dashboard-owner'),
    resolution: _resolution,
    comparisonClock: SupportiveDashboardFixtures.clock,
    fixtureMode: fixture,
    singlePage: singlePage,
    permanentNavigation: permanent,
    fixtureCards: [...activity, ..._destinations],
    activityPreviewKey: activityKey,
    activityPreviewControls: controls,
    onNavigate: onNavigate,
    onNotificationViewed: onViewed,
  ),
);

Future<void> _reveal(WidgetTester tester, String id) async {
  final target = _key(id);
  if (target.evaluate().isEmpty) {
    final scrollable = find.descendant(
      of: _key('my-zyra-quiet-scroll-0'),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: scrollable,
      maxScrolls: 30,
    );
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String id) async {
  await _reveal(tester, id);
  final target = _key(id);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

VoidCallback _callback(WidgetTester tester, String id) =>
    tester.widget<TextButton>(_key(id)).onPressed!;

Map<String, Element> _destinationElements(WidgetTester tester) => {
  for (final card in _destinations)
    card.id: tester.element(_key('my-zyra-preview-destination-${card.id}')),
};

void _expectDestinationElements(
  WidgetTester tester,
  Map<String, Element> original,
) {
  expect(find.byType(ZyraMyZyraNavigationCard), findsNWidgets(3));
  for (final card in _destinations) {
    final key = _key('my-zyra-preview-destination-${card.id}');
    expect(identical(tester.element(key), original[card.id]), isTrue);
    expect(
      tester.widget<ZyraMyZyraNavigationCard>(key).card.detail,
      card.detail,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late bool previousStubs;
  setUp(() {
    previousStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = previousStubs;
  });

  testWidgets('eligible controls live inside the existing scroll surface', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Checklist preview controls'), findsOneWidget);
    expect(
      find.ancestor(
        of: _key('my-zyra-activity-preview-controls'),
        matching: _key('my-zyra-quiet-scroll-0'),
      ),
      findsOneWidget,
    );
    expect(_key('my-zyra-activity-preview-transition'), findsOneWidget);
    expect(_key('my-zyra-activity-preview-size'), findsOneWidget);
    expect(find.byType(ZyraMyZyraNavigationCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  for (final mode in ['ordinary', 'two-page', 'non-permanent']) {
    testWidgets('$mode caller ignores both activity rehearsal fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          fixture: mode != 'ordinary',
          singlePage: mode != 'two-page',
          permanent: mode != 'non-permanent',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Checklist preview controls'), findsNothing);
      expect(_key('my-zyra-activity-preview-controls'), findsNothing);
      expect(_key('my-zyra-activity-preview-transition'), findsNothing);
      expect(_key('my-zyra-activity-preview-size'), findsNothing);
      final state = tester.state(find.byType(ZyraQuietDashboard));
      await tester.pumpWidget(
        _app(
          activityKey: 'example-b',
          fixture: mode != 'ordinary',
          singlePage: mode != 'two-page',
          permanent: mode != 'non-permanent',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        identical(tester.state(find.byType(ZyraQuietDashboard)), state),
        isTrue,
      );
      expect(find.text('Checklist preview controls'), findsNothing);
      expect(_key('my-zyra-activity-preview-transition'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('revoked fixture cannot render controls or retain navigation', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(_app(onNavigate: (card) => opened.add(card.id)));
    await tester.pumpAndSettle();
    final retained = _callback(tester, 'my-zyra-route-${_a.id}');
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(_key('quiet-index-fixture-denied'), findsOneWidget);
    expect(find.text('Checklist preview controls'), findsNothing);
    retained();
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the changing group moves and outgoing actions are inert', (
    tester,
  ) async {
    final opened = <String>[];
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_app(onNavigate: (card) => opened.add(card.id)));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(ZyraQuietDashboard));
      final destinations = _destinationElements(tester);
      final retained = _callback(tester, 'my-zyra-route-${_a.id}');
      final retainedDestination = tester
          .widget<ZyraMyZyraNavigationCard>(
            _key('my-zyra-preview-destination-concept-my-requests'),
          )
          .onOpen;
      await tester.pumpWidget(
        _app(
          activityKey: 'example-b',
          activity: const [_b],
          onNavigate: (card) => opened.add(card.id),
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text(_a.title), findsOneWidget);
      expect(find.text(_b.title), findsOneWidget);
      final outgoing = _key('my-zyra-route-${_a.id}');
      expect(outgoing.hitTestable(), findsNothing);
      expect(
        find.ancestor(
          of: outgoing,
          matching: find.byWidgetPredicate(
            (widget) => widget is IgnorePointer && widget.ignoring,
          ),
        ),
        findsWidgets,
      );
      expect(
        find.ancestor(
          of: outgoing,
          matching: find.byWidgetPredicate(
            (widget) => widget is ExcludeSemantics && widget.excluding,
          ),
        ),
        findsWidgets,
      );
      expect(find.bySemanticsLabel(RegExp('.*Amira.*')), findsNothing);
      retained();
      retainedDestination();
      expect(opened, isEmpty);
      expect(
        identical(tester.state(find.byType(ZyraQuietDashboard)), state),
        isTrue,
      );
      _expectDestinationElements(tester, destinations);
      await tester.pumpAndSettle();
      expect(find.text(_a.title), findsNothing);
      await _tap(tester, 'my-zyra-route-${_b.id}');
      await _tap(tester, 'my-zyra-route-concept-my-requests');
      expect(opened, [_b.id, 'concept-my-requests']);
      _expectDestinationElements(tester, destinations);
    } finally {
      semantics.dispose();
    }
  });

  for (final mode in ['reduced-motion', 'accessible-navigation']) {
    testWidgets(
      '$mode replaces activity without animation or outgoing content',
      (tester) async {
        await tester.pumpWidget(
          _app(
            reducedMotion: mode == 'reduced-motion',
            accessibleNavigation: mode == 'accessible-navigation',
          ),
        );
        await tester.pumpAndSettle();
        final destinations = _destinationElements(tester);
        expect(_key('my-zyra-activity-preview-transition'), findsNothing);
        expect(_key('my-zyra-activity-preview-size'), findsNothing);
        await tester.pumpWidget(
          _app(
            activityKey: 'example-b',
            activity: const [_b],
            reducedMotion: mode == 'reduced-motion',
            accessibleNavigation: mode == 'accessible-navigation',
          ),
        );
        expect(find.text(_a.title), findsNothing);
        expect(find.text(_b.title), findsOneWidget);
        expect(_key('my-zyra-activity-preview-size'), findsNothing);
        _expectDestinationElements(tester, destinations);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'quiet and current data keep all permanent card elements mounted',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final destinations = _destinationElements(tester);
      await tester.pumpWidget(
        _app(activityKey: 'quiet-example', activity: const []),
      );
      expect(find.text(_a.title), findsNothing);
      expect(_key('my-zyra-activity-preview-transition'), findsNothing);
      _expectDestinationElements(tester, destinations);
      await tester.pumpWidget(_app(activityKey: null, controls: null));
      await tester.pumpAndSettle();
      expect(_key('my-zyra-activity-preview-controls'), findsNothing);
      expect(_key('my-zyra-activity-preview-transition'), findsNothing);
      expect(find.text(_a.title), findsOneWidget);
      _expectDestinationElements(tester, destinations);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a rehearsal key change resets private disclosure and stale callbacks',
    (tester) async {
      final viewed = <String>[];
      await tester.pumpWidget(
        _app(
          activity: const [_a, _change],
          onViewed: (card) => viewed.add(card.id),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'quiet-index-disclosure-${_change.id}');
      expect(_key('quiet-index-details-${_change.id}'), findsOneWidget);
      final stale = _callback(tester, 'quiet-index-disclosure-${_change.id}');
      await tester.pumpWidget(
        _app(
          activityKey: 'example-b',
          activity: const [_b, _change],
          onViewed: (card) => viewed.add(card.id),
        ),
      );
      await tester.pumpAndSettle();
      await _reveal(tester, 'quiet-index-disclosure-${_change.id}');
      expect(_key('quiet-index-details-${_change.id}'), findsNothing);
      stale();
      await tester.pumpAndSettle();
      await _reveal(tester, 'quiet-index-disclosure-${_change.id}');
      expect(_key('quiet-index-details-${_change.id}'), findsNothing);
      expect(viewed, isEmpty);
      await _tap(tester, 'quiet-index-disclosure-${_change.id}');
      expect(_key('quiet-index-details-${_change.id}'), findsOneWidget);
      expect(viewed, isEmpty);
    },
  );

  testWidgets(
    'ignored rehearsal fields do not reset an ordinary fixture disclosure',
    (tester) async {
      await tester.pumpWidget(
        _app(permanent: false, activity: const [_a, _change]),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'quiet-index-disclosure-${_change.id}');
      expect(_key('quiet-index-details-${_change.id}'), findsOneWidget);
      await tester.pumpWidget(
        _app(
          activityKey: 'ignored-next-example',
          permanent: false,
          activity: const [_a, _change],
        ),
      );
      await tester.pumpAndSettle();
      await _reveal(tester, 'quiet-index-disclosure-${_change.id}');
      expect(_key('quiet-index-details-${_change.id}'), findsOneWidget);
      expect(_key('my-zyra-activity-preview-transition'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
