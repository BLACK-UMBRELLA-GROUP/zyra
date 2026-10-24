import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';
import 'package:zyra/widgets/zyra_segmented_toggle.dart';

final _clock = SupportiveDashboardFixtures.clock;

SupportiveFixture _fixture(SupportivePreviewScenario scenario) =>
    SupportiveDashboardFixtures.build(
      scenario,
      personalized: true,
      counterpartName: 'Adam',
    );

Widget _app(
  SupportiveFixture fixture, {
  bool fixtureMode = true,
  List<SupportiveCard>? cards,
  ValueChanged<SupportiveCard>? onNavigate,
  ValueChanged<int>? onTabChanged,
  VoidCallback? onRetry,
  VoidCallback? onMarkAllNotificationsRead,
  int unreadCount = 0,
  double scale = 1,
  bool insightsEntitled = true,
  bool singlePage = false,
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
    key: ValueKey(fixture),
    resolution: fixture.resolution,
    fixtureMode: fixtureMode,
    fixtureCards: cards ?? fixture.cards,
    comparisonClock: _clock,
    firstName: 'Maryam-Alexandria Noorulhuda',
    selectedTabIndex: fixture.tabIndex,
    onNavigate: onNavigate,
    onTabChanged: onTabChanged,
    onRetry: onRetry,
    onMarkAllNotificationsRead: onMarkAllNotificationsRead,
    unreadCount: unreadCount,
    insightsEntitled: insightsEntitled,
    singlePage: singlePage,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  SupportivePreviewScenario scenario, {
  bool fixtureMode = true,
  List<SupportiveCard>? cards,
  ValueChanged<SupportiveCard>? onNavigate,
  ValueChanged<int>? onTabChanged,
  VoidCallback? onRetry,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    _app(
      _fixture(scenario),
      fixtureMode: fixtureMode,
      cards: cards,
      onNavigate: onNavigate,
      onTabChanged: onTabChanged,
      onRetry: onRetry,
      scale: scale,
    ),
  );
  await tester.pump(const Duration(milliseconds: 80));
  expect(find.byKey(const ValueKey('my-zyra-quiet-dashboard')), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _reveal(WidgetTester tester, Finder target, {int tab = 0}) async {
  final scrollable = find.descendant(
    of: find.byKey(ValueKey('my-zyra-quiet-scroll-$tab')),
    matching: find.byType(Scrollable),
  );
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: scrollable,
    maxScrolls: 50,
  );
  await tester.pumpAndSettle();
}

List<SupportiveCard> _expected(SupportiveFixture fixture) =>
    mergeSupportiveCards(
      supportiveCardsFromResolution(
        fixture.resolution,
        comparisonClock: _clock,
      ),
      fixture.cards,
    );

Finder get _rules => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'quiet-index-group-rule-',
      ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);
  for (final scale in [1.0, 1.4, 2.0]) {
    testWidgets('single-page opt-in keeps current information at $scale', (
      tester,
    ) async {
      final opened = <String>[];
      const card = SupportiveCard(
        id: 'single-page-information',
        section: SupportiveSection.stand,
        title: 'Your circle of support',
        detail: 'Your existing Guardian information stays available.',
        actionLabel: 'Manage Guardians',
        target: ZyraDashboardTarget.guardian,
      );
      await tester.pumpWidget(
        _app(
          _fixture(SupportivePreviewScenario.allClear),
          cards: const [card],
          singlePage: true,
          scale: scale,
          insightsEntitled: false,
          onNavigate: (value) => opened.add(value.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My ZYRA'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(ZyraSegmentedToggle), findsNothing);
      expect(
        find.byKey(const ValueKey('quiet-index-insights-locked')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('my-zyra-quiet-scroll-1')),
        findsNothing,
      );
      await _reveal(tester, find.text(card.actionLabel!));
      await tester.tap(find.text(card.actionLabel!));
      await tester.pumpAndSettle();
      expect(opened, [card.id]);
      expect(tester.takeException(), isNull);
    });
  }
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    SupportiveDashboardPreview.instance.reset();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    SupportiveDashboardPreview.instance.reset();
  });

  testWidgets(
    'ordinary members receive the production renderer and source cards',
    (tester) async {
      final fixture = _fixture(SupportivePreviewScenario.oneAction);
      final action = _expected(
        fixture,
      ).firstWhere((card) => card.section == SupportiveSection.needsYou);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      SupportiveCard? opened;
      await tester.pumpWidget(
        _app(fixture, fixtureMode: false, onNavigate: (card) => opened = card),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
        findsOneWidget,
      );
      expect(find.text(action.title), findsOneWidget);
      final route = find.byKey(ValueKey('my-zyra-route-${action.id}'));
      await _reveal(tester, route);
      await tester.tap(route);
      expect(opened?.id, action.id);
      expect(opened?.target, action.target);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('production source mode rejects supplemental fixture content', (
    tester,
  ) async {
    const poison = SupportiveCard(
      id: 'poison',
      section: SupportiveSection.fromZyra,
      title: 'Injected company sample',
    );
    await _pump(
      tester,
      SupportivePreviewScenario.allClear,
      fixtureMode: false,
      cards: const [poison],
    );
    expect(find.text(poison.title), findsNothing);
    expect(find.byKey(const ValueKey('my-zyra-quiet')), findsOneWidget);
  });

  testWidgets('the My ZYRA pages and pill move together on a left swipe', (
    tester,
  ) async {
    await _pump(tester, SupportivePreviewScenario.allClear);
    await tester.drag(
      find.byKey(const ValueKey('my-zyra-pages')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ZyraSegmentedToggle>(find.byType(ZyraSegmentedToggle))
          .position,
      1,
    );
    expect(
      find.byKey(const ValueKey('my-zyra-insights-empty')),
      findsOneWidget,
    );
  });

  testWidgets('My ZYRA header uses the Connections spacing and typography', (
    tester,
  ) async {
    await _pump(tester, SupportivePreviewScenario.allClear);

    final title = find.text('My ZYRA');
    final slider = find.byKey(const ValueKey('my-zyra-tab-slider'));
    final dashboard = find.byKey(const ValueKey('my-zyra-quiet-dashboard'));
    final titleText = tester.widget<Text>(title);
    final toggle = tester.widget<ZyraSegmentedToggle>(slider);

    expect(tester.getTopLeft(title), const Offset(20, 16));
    expect(tester.getTopLeft(slider).dx, 20);
    expect(tester.getSize(dashboard).width - tester.getSize(slider).width, 40);
    expect(tester.getTopLeft(slider).dy - tester.getBottomLeft(title).dy, 8);
    expect(titleText.style, ZyraText.heading(size: 26));
    expect(toggle.labelSize, 11.5);
  });

  testWidgets(
    'developer tab state waits for the Connections-style swipe to settle',
    (tester) async {
      final selectedTabs = <int>[];
      await _pump(
        tester,
        SupportivePreviewScenario.allClear,
        onTabChanged: selectedTabs.add,
      );
      final pages = find.byKey(const ValueKey('my-zyra-pages'));
      final gesture = await tester.startGesture(tester.getCenter(pages));
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      final movingPosition = tester
          .widget<ZyraSegmentedToggle>(find.byType(ZyraSegmentedToggle))
          .position;
      expect(movingPosition, greaterThan(0));
      expect(movingPosition, lessThan(1));
      expect(selectedTabs, isEmpty);

      await gesture.moveBy(const Offset(-340, 0));
      await tester.pump();
      expect(selectedTabs, isEmpty);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(selectedTabs, [1]);
      expect(
        tester
            .widget<ZyraSegmentedToggle>(find.byType(ZyraSegmentedToggle))
            .position,
        1,
      );
    },
  );

  testWidgets(
    'unauthorized fixture entry and authorization revocation retract samples',
    (tester) async {
      final fixture = _fixture(SupportivePreviewScenario.editorial);
      final sample = fixture.cards.single;
      await tester.pumpWidget(_app(fixture));
      await tester.pumpAndSettle();
      expect(find.text(sample.title), findsOneWidget);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      expect(find.text(sample.title), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app(fixture));
      await tester.pumpAndSettle();
      expect(find.text(sample.title), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'busy Now omits all four section headings and keeps named cards intact',
    (tester) async {
      final fixture = _fixture(SupportivePreviewScenario.allNow);
      await _pump(tester, SupportivePreviewScenario.allNow);
      for (final heading in [
        'What Needs You',
        'Where You Stand',
        'What Changed',
        'From ZYRA',
      ]) {
        expect(find.text(heading), findsNothing);
      }
      for (final card in _expected(fixture)) {
        final item = find.byKey(ValueKey('my-zyra-item-${card.id}'));
        await _reveal(tester, item);
        expect(
          find.descendant(of: item, matching: find.text(card.title)),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    SupportivePreviewScenario.allClear,
    SupportivePreviewScenario.oneAction,
    SupportivePreviewScenario.noGuardian,
    SupportivePreviewScenario.recentChanges,
    SupportivePreviewScenario.editorial,
    SupportivePreviewScenario.allNow,
  ]) {
    testWidgets(
      '${scenario.name} has fine rules only between nonempty groups',
      (tester) async {
        // Mount every group at once so the assertions describe the complete
        // composition, independently of ListView's viewport recycling.
        tester.view.physicalSize = const Size(390, 6000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = _fixture(scenario);
        final cards = _expected(fixture);
        final groups =
            [
                  SupportiveSection.needsYou,
                  SupportiveSection.stand,
                  SupportiveSection.changed,
                  SupportiveSection.fromZyra,
                ]
                .where(
                  (section) => cards.any((card) => card.section == section),
                )
                .toList();
        await _pump(tester, scenario);
        expect(_rules, findsNWidgets(groups.isEmpty ? 0 : groups.length - 1));
        expect(
          find.byType(Divider),
          findsNWidgets(groups.isEmpty ? 0 : groups.length - 1),
        );
        final items = find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'my-zyra-item-',
              ),
        );
        if (groups.length > 1) {
          final firstTop = tester.getTopLeft(items.first).dy;
          final lastBottom = tester.getBottomLeft(items.last).dy;
          for (final rule in _rules.evaluate()) {
            final target = find.byWidget(rule.widget);
            expect(tester.getTopLeft(target).dy, greaterThan(firstTop));
            expect(tester.getBottomLeft(target).dy, lessThan(lastBottom));
          }
        }
      },
    );
  }

  testWidgets('change disclosures open singly and collapse on tab change', (
    tester,
  ) async {
    final changes = _expected(
      _fixture(SupportivePreviewScenario.allNow),
    ).where((card) => card.section == SupportiveSection.changed).toList();
    final tabs = <int>[];
    await _pump(
      tester,
      SupportivePreviewScenario.allNow,
      onTabChanged: tabs.add,
    );
    Finder disclosure(SupportiveCard card) =>
        find.byKey(ValueKey('quiet-index-disclosure-${card.id}'));
    Finder details(SupportiveCard card) =>
        find.byKey(ValueKey('quiet-index-details-${card.id}'));
    await _reveal(tester, disclosure(changes[0]));
    await tester.tap(disclosure(changes[0]));
    await tester.pumpAndSettle();
    expect(details(changes[0]), findsOneWidget);
    await _reveal(tester, disclosure(changes[1]));
    await tester.tap(disclosure(changes[1]));
    await tester.pumpAndSettle();
    expect(details(changes[0]), findsNothing);
    expect(details(changes[1]), findsOneWidget);
    final insightsTab = find.byKey(const ValueKey('my-zyra-insights-tab'));
    await _reveal(tester, insightsTab);
    await tester.tap(insightsTab);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-zyra-now-tab')));
    await tester.pumpAndSettle();
    expect(tabs, [1, 0]);
    for (final card in changes) {
      expect(details(card), findsNothing);
    }
  });

  testWidgets('Seeker Basic cannot access Insights', (tester) async {
    await tester.pumpWidget(
      _app(
        _fixture(SupportivePreviewScenario.allNow),
        fixtureMode: false,
        insightsEntitled: false,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-zyra-insights-tab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('quiet-index-insights-locked')),
      findsOneWidget,
    );
    expect(find.text('Insights are part of Seeker One'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('segmented-Insights-lock')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('seeker-insights-upgrade')),
      findsOneWidget,
    );
  });

  testWidgets('all obligations remain reachable beyond the initial three', (
    tester,
  ) async {
    final actions = _expected(
      _fixture(SupportivePreviewScenario.severalActions),
    ).where((card) => card.section == SupportiveSection.needsYou).toList();
    expect(actions.length, greaterThan(3));
    await _pump(tester, SupportivePreviewScenario.severalActions);
    for (final card in actions.skip(3)) {
      expect(find.text(card.title), findsNothing);
    }
    final more = find.byKey(const ValueKey('my-zyra-more-actions'));
    await _reveal(tester, more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    final positions = <double>[];
    for (final card in actions) {
      final item = find.byKey(ValueKey('my-zyra-item-${card.id}'));
      await _reveal(tester, item);
      expect(find.text(card.title), findsOneWidget);
      positions.add(
        tester.getTopLeft(item).dy +
            tester
                .state<ScrollableState>(
                  find
                      .ancestor(of: item, matching: find.byType(Scrollable))
                      .last,
                )
                .position
                .pixels,
      );
    }
    expect(positions, orderedEquals([...positions]..sort()));
  });

  for (final scenario in [
    SupportivePreviewScenario.loading,
    SupportivePreviewScenario.failed,
    SupportivePreviewScenario.lastKnown,
  ]) {
    testWidgets('${scenario.name} cannot claim an all-clear', (tester) async {
      var retries = 0;
      await _pump(tester, scenario, onRetry: () => retries++);
      expect(find.byKey(const ValueKey('my-zyra-quiet')), findsNothing);
      final notice = switch (scenario) {
        SupportivePreviewScenario.loading => 'my-zyra-loading',
        SupportivePreviewScenario.lastKnown => 'my-zyra-last-known',
        _ => 'my-zyra-source-gap',
      };
      expect(find.byKey(ValueKey(notice)), findsOneWidget);
      if (scenario != SupportivePreviewScenario.loading) {
        await tester.tap(find.byKey(const ValueKey('my-zyra-retry')));
        expect(retries, 1);
      }
      if (scenario == SupportivePreviewScenario.lastKnown) {
        final changes = _expected(
          _fixture(scenario),
        ).where((card) => card.section == SupportiveSection.changed);
        for (final card in changes) {
          final item = find.byKey(ValueKey('my-zyra-item-${card.id}'));
          expect(
            find.descendant(
              of: item,
              matching: find.text('Last known · not current'),
            ),
            findsOneWidget,
          );
        }
      }
    });
  }

  testWidgets(
    'production Insights ignore sample findings and failed is distinct from empty',
    (tester) async {
      final samples = _fixture(
        SupportivePreviewScenario.insightsPopulated,
      ).cards;
      await _pump(
        tester,
        SupportivePreviewScenario.insightsEmpty,
        fixtureMode: false,
        cards: samples,
      );
      expect(
        find.byKey(const ValueKey('my-zyra-insights-empty')),
        findsOneWidget,
      );
      for (final card in samples) {
        expect(find.text(card.title), findsNothing);
      }
      await _pump(
        tester,
        SupportivePreviewScenario.insightsFailed,
        cards: samples,
      );
      expect(
        find.byKey(const ValueKey('my-zyra-insights-empty')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('my-zyra-insights-failed')),
        findsOneWidget,
      );
      for (final card in samples) {
        expect(find.text(card.title), findsNothing);
      }
    },
  );

  testWidgets(
    'Insight evidence states its basis and hide remains reversible in preview',
    (tester) async {
      final fixture = _fixture(SupportivePreviewScenario.insightsPopulated);
      final card = fixture.cards.firstWhere(
        (card) => card.evidence != null && !card.isGeneralGuide,
      );
      await _pump(tester, SupportivePreviewScenario.insightsPopulated);
      final evidence = find.byKey(ValueKey('my-zyra-evidence-${card.id}'));
      await _reveal(tester, evidence, tab: 1);
      await tester.tap(evidence);
      await tester.pumpAndSettle();
      for (final fact in [
        card.evidence!.summary,
        card.evidence!.period,
        card.evidence!.reason,
        card.evidence!.limitation,
      ]) {
        expect(find.text(fact), findsOneWidget);
      }
      final hide = find.byKey(ValueKey('my-zyra-hide-${card.id}'));
      await _reveal(tester, hide, tab: 1);
      await tester.tap(hide);
      await tester.pumpAndSettle();
      expect(find.text(card.title), findsNothing);
      final reset = find.byKey(const ValueKey('my-zyra-reset-insights'));
      await _reveal(tester, reset, tab: 1);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      await _reveal(tester, find.text(card.title), tab: 1);
      expect(find.text(card.title), findsOneWidget);
    },
  );

  testWidgets(
    'notification reads require an explicit production tap and never run for samples',
    (tester) async {
      final fixture = SupportiveDashboardFixtures.build(
        SupportivePreviewScenario.changed,
        change: SupportiveChangeExample.introduction,
        personalized: true,
      );
      final change = _expected(
        fixture,
      ).firstWhere((card) => card.section == SupportiveSection.changed);
      expect(change.isUnread, isTrue);
      var marks = 0;
      await tester.pumpWidget(
        _app(
          fixture,
          fixtureMode: false,
          onMarkAllNotificationsRead: () => marks++,
        ),
      );
      await tester.pumpAndSettle();
      expect(marks, 0);
      final disclosure = find.byKey(
        ValueKey('quiet-index-disclosure-${change.id}'),
      );
      await _reveal(tester, disclosure);
      await tester.tap(disclosure);
      await tester.pumpAndSettle();
      expect(
        marks,
        0,
        reason: 'Reading details does not send a read acknowledgement.',
      );
      final markRead = find.byKey(const ValueKey('quiet-index-mark-read'));
      await _reveal(tester, markRead);
      await tester.tap(markRead);
      await tester.pumpAndSettle();
      expect(marks, 1);
      await tester.pumpWidget(
        _app(fixture, onMarkAllNotificationsRead: () => marks++),
      );
      await tester.pumpAndSettle();
      expect(markRead, findsNothing);
      await _reveal(tester, disclosure);
      await tester.tap(disclosure);
      await tester.pumpAndSettle();
      expect(marks, 1);
    },
  );

  testWidgets(
    'global unread count retains explicit acknowledgement when visible changes are absent or not unread',
    (tester) async {
      for (final scenario in [
        SupportivePreviewScenario.allClear,
        SupportivePreviewScenario.recentChanges,
      ]) {
        final fixture = _fixture(scenario);
        expect(
          _expected(fixture).where((card) => card.isUnread == true),
          isEmpty,
        );
        var marks = 0;
        await tester.pumpWidget(
          _app(
            fixture,
            fixtureMode: false,
            unreadCount: 4,
            onMarkAllNotificationsRead: () => marks++,
          ),
        );
        await tester.pumpAndSettle();
        expect(marks, 0);
        final markRead = find.byKey(const ValueKey('quiet-index-mark-read'));
        await _reveal(tester, markRead);
        await tester.tap(markRead);
        await tester.pumpAndSettle();
        expect(marks, 1);
        await tester.pumpWidget(
          _app(
            fixture,
            unreadCount: 4,
            onMarkAllNotificationsRead: () => marks++,
          ),
        );
        await tester.pumpAndSettle();
        expect(markRead, findsNothing);
        expect(marks, 1);
      }
    },
  );

  testWidgets('long named content wraps at 320px and double text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const card = SupportiveCard(
      id: 'long-named-card',
      section: SupportiveSection.needsYou,
      title:
          'Maryam-Alexandria Noorulhuda and Abdurrahman-Muhammad have a Journey request to review',
      detail:
          'Named people and the full request remain readable as the card grows.',
    );
    await _pump(
      tester,
      SupportivePreviewScenario.allClear,
      cards: const [card],
      scale: 2,
    );
    final title = find.text(card.title);
    await _reveal(tester, title);
    final text = tester.widget<Text>(title);
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });
}
