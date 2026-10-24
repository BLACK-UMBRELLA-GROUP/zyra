// Pure renderer signals only. No account, transport or read mutation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

const _first =
    'update:notification.new_message:00000000-0000-4000-8000-000000009111';
const _second =
    'update:notification.new_message:00000000-0000-4000-8000-000000009112';

DashboardResolution _resolution({bool unread = true}) =>
    const DashboardResolver().resolve(
      DashboardSnapshot(
        role: DashboardRole.seeker,
        onboarding: const DashboardSource.available([]),
        journeys: const DashboardSource.available(
          DashboardJourneyState(
            summary: DashboardJourneySummary(
              id: 'search',
              kind: DashboardJourneyKind.searching,
              title: 'Searching',
            ),
          ),
        ),
        guardianInvitations: const DashboardSource.available([]),
        insights: const DashboardSource.available([]),
        stableState: const DashboardStableState(
          family: DashboardSource.available(
            DashboardFamilyStatus(
              kind: DashboardFamilyKind.connected,
              title: 'Guardian connected',
              linkedCount: 1,
            ),
          ),
        ),
        updates: DashboardSource.available([
          DashboardSignal(
            id: _first,
            kind: DashboardSignalKind.meaningfulMovement,
            title: 'First recorded update',
            detail: 'First recorded detail',
            isUnread: unread,
          ),
          DashboardSignal(
            id: _second,
            kind: DashboardSignalKind.meaningfulMovement,
            title: 'Second recorded update',
            detail: 'Second recorded detail',
            isUnread: unread,
          ),
        ]),
      ),
    );

Widget _app(
  DashboardResolution resolution,
  ValueChanged<SupportiveCard> onViewed, {
  bool fixture = false,
  GlobalKey<NavigatorState>? navigator,
}) => MaterialApp(
  navigatorKey: navigator,
  home: ZyraQuietDashboard(
    resolution: resolution,
    fixtureMode: fixture,
    onNotificationViewed: onViewed,
    fixtureCards: fixture
        ? const [
            SupportiveCard(
              id: _first,
              section: SupportiveSection.changed,
              title: 'First recorded update',
              detail: 'First recorded detail',
              isUnread: true,
            ),
          ]
        : const [],
  ),
);

Finder _details(String id) =>
    find.byKey(ValueKey('quiet-index-disclosure-$id'));

VoidCallback _saved(WidgetTester tester, String id) =>
    tester.widget<TextButton>(_details(id)).onPressed!;

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
  });

  testWidgets('opening A details emits A only, closing and tabs emit nothing', (
    tester,
  ) async {
    final viewed = <String>[];
    await tester.pumpWidget(_app(_resolution(), (card) => viewed.add(card.id)));
    await tester.pumpAndSettle();
    expect(viewed, isEmpty);
    await tester.tap(_details(_first));
    await tester.pump();
    expect(viewed, [_first]);
    await tester.tap(_details(_first));
    await tester.pump();
    expect(viewed, [_first]);
    await tester.tap(find.byKey(const ValueKey('my-zyra-insights-tab')));
    await tester.pumpAndSettle();
    expect(viewed, [_first]);
  });

  testWidgets('read rows emit no unread acknowledgement signal', (
    tester,
  ) async {
    final viewed = <String>[];
    await tester.pumpWidget(
      _app(_resolution(unread: false), (card) => viewed.add(card.id)),
    );
    await tester.pumpAndSettle();
    await tester.tap(_details(_first));
    await tester.pump();
    expect(viewed, isEmpty);
  });

  testWidgets('local fixture details never emit an ordinary read signal', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final viewed = <String>[];
    await tester.pumpWidget(
      _app(_resolution(), (card) => viewed.add(card.id), fixture: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(_details(_first));
    await tester.pump();
    expect(viewed, isEmpty);
  });

  testWidgets(
    'retained old-resolution detail action cannot acknowledge replacement rows',
    (tester) async {
      final viewed = <String>[];
      void onViewed(SupportiveCard card) => viewed.add(card.id);
      await tester.pumpWidget(_app(_resolution(), onViewed));
      await tester.pumpAndSettle();
      final oldAction = _saved(tester, _first);
      await tester.pumpWidget(_app(_resolution(), onViewed));
      await tester.pump();
      oldAction();
      await tester.pump();
      expect(viewed, isEmpty);
    },
  );

  testWidgets('retained callback cannot become the replacement callback', (
    tester,
  ) async {
    final resolution = _resolution();
    final first = <String>[];
    final next = <String>[];
    await tester.pumpWidget(_app(resolution, (card) => first.add(card.id)));
    await tester.pumpAndSettle();
    final oldAction = _saved(tester, _first);
    await tester.pumpWidget(_app(resolution, (card) => next.add(card.id)));
    await tester.pump();
    oldAction();
    await tester.pump();
    expect(first, isEmpty);
    expect(next, isEmpty);
  });

  testWidgets(
    'covered detail action does not pretend the hidden row was opened',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final viewed = <String>[];
      await tester.pumpWidget(
        _app(
          _resolution(),
          (card) => viewed.add(card.id),
          navigator: navigator,
        ),
      );
      await tester.pumpAndSettle();
      final action = _saved(tester, _first);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      );
      await tester.pumpAndSettle();
      action();
      await tester.pump();
      expect(viewed, isEmpty);
    },
  );

  testWidgets('Now-Insights-Now cannot revive a saved notification action', (
    tester,
  ) async {
    final viewed = <String>[];
    await tester.pumpWidget(_app(_resolution(), (card) => viewed.add(card.id)));
    await tester.pumpAndSettle();
    final action = _saved(tester, _first);
    await tester.tap(find.byKey(const ValueKey('my-zyra-insights-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-zyra-now-tab')));
    await tester.pumpAndSettle();
    action();
    await tester.pump();
    expect(viewed, isEmpty);
  });
}
