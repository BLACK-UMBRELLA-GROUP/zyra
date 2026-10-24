import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

final _clock = DateTime.utc(2026, 8, 30, 18);

const _evidence = SupportiveEvidence(
  summary: 'Three of five completed Journeys in this development sample.',
  period: '30 August 2025–30 August 2026',
  reason: 'This is a deliberately selected development example.',
  limitation: 'Sample only. No personal history was analysed.',
);

DashboardSnapshot _snapshot({
  List<DashboardSignal> journeySignals = const [],
  DashboardJourneyKind journeyKind = DashboardJourneyKind.searching,
  String journeyTitle = 'Current Journey',
  DashboardSource<List<DashboardSignal>> updates =
      const DashboardSource.available([]),
  DashboardSource<List<DashboardSignal>> invitations =
      const DashboardSource.available([]),
  DashboardSource<List<DashboardSignal>> insights =
      const DashboardSource.available([]),
  DashboardSource<DashboardFamilyStatus> family =
      const DashboardSource.available(
        DashboardFamilyStatus(
          kind: DashboardFamilyKind.connected,
          title: 'Guardian connected',
        ),
      ),
}) => DashboardSnapshot(
  role: DashboardRole.seeker,
  onboarding: const DashboardSource.available([]),
  journeys: DashboardSource.available(
    DashboardJourneyState(
      summary: DashboardJourneySummary(
        id: 'journey:example',
        kind: journeyKind,
        title: journeyTitle,
      ),
      signals: journeySignals,
    ),
  ),
  updates: updates,
  guardianInvitations: invitations,
  insights: insights,
  stableState: DashboardStableState(family: family),
);

DashboardResolution _resolve(DashboardSnapshot snapshot) =>
    const DashboardResolver().resolve(snapshot);

List<SupportiveCard> _project(DashboardSnapshot snapshot) =>
    supportiveCardsFromResolution(_resolve(snapshot), comparisonClock: _clock);

DashboardSignal _signal(
  String id,
  DashboardSignalKind kind, {
  bool? isUnread,
}) => DashboardSignal(
  id: id,
  kind: kind,
  title: 'Signal $id',
  actionLabel: 'Continue Journey',
  target: ZyraDashboardTarget.connectionsJourneys,
  eventAt: DateTime.utc(2026, 8, 28, 10),
  isUnread: isUnread,
);

Widget _dashboard({
  DashboardResolution? resolution,
  List<SupportiveCard> cards = const [],
  bool fixtureMode = false,
  int tab = 0,
  double scale = 1,
  ValueChanged<SupportiveCard>? onNavigate,
  VoidCallback? onRetry,
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
    resolution: resolution ?? _resolve(_snapshot()),
    fixtureCards: cards,
    fixtureMode: fixtureMode,
    comparisonClock: _clock,
    firstName: 'Maryam',
    selectedTabIndex: tab,
    onNavigate: onNavigate,
    onRetry: onRetry,
  ),
);

Future<void> _pumpFixture(
  WidgetTester tester,
  SupportiveFixture fixture,
) async {
  await tester.pumpWidget(
    _dashboard(
      resolution: fixture.resolution,
      cards: fixture.cards,
      fixtureMode: true,
      tab: fixture.tabIndex,
    ),
  );
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    SupportiveDashboardPreview.instance.reset();
    ZyraDevScenario.instance.resetDashboardLab();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    SupportiveDashboardPreview.instance.reset();
    ZyraDevScenario.instance.resetDashboardLab();
  });

  test('the eight visible section names match the Founder brief exactly', () {
    expect(SupportiveSection.values.map((section) => section.label), [
      'What Needs You',
      'Where You Stand',
      'What Changed',
      'From ZYRA',
      'What’s Working',
      'What Keeps Happening',
      'What You’ve Learned',
      'What May Help',
    ]);
  });

  test('same explicit issue gets one highest-priority presentation', () {
    final cards = mergeSupportiveCards([
      for (final section in [
        SupportiveSection.changed,
        SupportiveSection.needsYou,
        SupportiveSection.stand,
      ])
        SupportiveCard(id: 'same-issue', section: section, title: section.name),
    ]);
    expect(cards, hasLength(1));
    expect(cards.single.section, SupportiveSection.needsYou);
  });

  test('equal wording or date never invents a shared semantic identity', () {
    final cards = mergeSupportiveCards([
      for (final id in ['first-event', 'second-event'])
        SupportiveCard(
          id: id,
          section: SupportiveSection.changed,
          title: 'Journey resumed',
          date: _clock,
        ),
    ]);
    expect(cards.map((card) => card.id), ['first-event', 'second-event']);
  });

  test('supplements cannot demote an existing unresolved obligation', () {
    final cards = mergeSupportiveCards(
      const [
        SupportiveCard(
          id: 'same-issue',
          section: SupportiveSection.needsYou,
          title: 'An unresolved decision',
        ),
      ],
      const [
        SupportiveCard(
          id: 'same-issue',
          section: SupportiveSection.stand,
          title: 'A status recap',
        ),
      ],
    );
    expect(cards.single.title, 'An unresolved decision');
  });

  test('no-Main family state becomes a Now action, not a calm status', () {
    final cards = _project(
      _snapshot(
        family: const DashboardSource.available(
          DashboardFamilyStatus(
            kind: DashboardFamilyKind.connected,
            title: 'Choose a Main Guardian',
            detail: 'Your Guardians remain linked.',
          ),
        ),
      ),
    );

    final card = cards.singleWhere(
      (candidate) => candidate.id == 'guardian:main-required',
    );
    expect(card.section, SupportiveSection.needsYou);
    expect(card.title, 'Choose a Main Guardian');
    expect(card.actionLabel, 'Go to Guardian');
    expect(card.target, ZyraDashboardTarget.guardian);
  });

  test('all four evidence fields are required for personalised samples', () {
    final evidenceVariants = [
      null,
      const SupportiveEvidence(
        summary: '',
        period: 'period',
        reason: 'reason',
        limitation: 'limit',
      ),
      const SupportiveEvidence(
        summary: 'summary',
        period: ' ',
        reason: 'reason',
        limitation: 'limit',
      ),
      const SupportiveEvidence(
        summary: 'summary',
        period: 'period',
        reason: '',
        limitation: 'limit',
      ),
      const SupportiveEvidence(
        summary: 'summary',
        period: 'period',
        reason: 'reason',
        limitation: '',
      ),
      _evidence,
    ];
    final cards = mergeSupportiveCards([
      for (var i = 0; i < evidenceVariants.length; i++)
        SupportiveCard(
          id: 'evidence-$i',
          section: SupportiveSection.working,
          title: 'Personalised sample $i',
          evidence: evidenceVariants[i],
        ),
    ]);
    expect(cards.map((card) => card.id), ['evidence-5']);
  });

  test('general guidance is admitted distinctly without a personal claim', () {
    final cards = mergeSupportiveCards(const [
      SupportiveCard(
        id: 'general-guide',
        section: SupportiveSection.help,
        title: 'Questions worth discussing',
        isGeneralGuide: true,
      ),
    ]);
    expect(cards.single.isGeneralGuide, isTrue);
    expect(cards.single.evidence, isNull);
  });

  test('read state cannot remove a genuinely unresolved domain action', () {
    for (final unread in <bool?>[true, false, null]) {
      final cards = _project(
        _snapshot(
          journeySignals: [
            _signal(
              'unresolved',
              DashboardSignalKind.addressedDecision,
              isUnread: unread,
            ),
          ],
        ),
      );
      expect(cards.single.section, SupportiveSection.needsYou);
      expect(cards.single.actionLabel, 'View Journey');
      expect(cards.single.isUnread, isNull);
    }
  });

  test('a notification-shaped decision does not become a domain action', () {
    final cards = _project(
      _snapshot(
        updates: DashboardSource.available([
          _signal(
            'notification',
            DashboardSignalKind.addressedDecision,
            isUnread: true,
          ),
        ]),
      ),
    );
    expect(
      cards.where((card) => card.section == SupportiveSection.needsYou),
      isEmpty,
    );
  });

  test('movement preserves true, false and absent unread semantics', () {
    final cards = _project(
      _snapshot(
        updates: DashboardSource.available([
          for (final unread in <bool?>[true, false, null])
            _signal(
              'event-$unread',
              DashboardSignalKind.meaningfulMovement,
              isUnread: unread,
            ),
        ]),
      ),
    );
    expect(
      {for (final card in cards) card.id: card.isUnread},
      {'event-true': true, 'event-false': false, 'event-null': null},
    );
  });

  test(
    'What Changed remains the governed Updates projection capped at three',
    () {
      final cards = _project(
        _snapshot(
          updates: DashboardSource.available([
            for (var i = 0; i < 5; i++)
              _signal('update-$i', DashboardSignalKind.meaningfulMovement),
          ]),
        ),
      );
      expect(
        cards.where((card) => card.section == SupportiveSection.changed),
        hasLength(3),
      );
      expect(
        _project(
          _snapshot(
            journeySignals: [
              _signal('domain-move', DashboardSignalKind.meaningfulMovement),
            ],
          ),
        ),
        isEmpty,
      );
    },
  );

  test('real projection cannot populate editorial or production Insights', () {
    final cards = _project(
      _snapshot(
        insights: DashboardSource.available([
          _signal('legacy-insight', DashboardSignalKind.governedInsight),
        ]),
      ),
    );
    expect(cards.where((card) => card.section.isInsight), isEmpty);
    expect(
      cards.where((card) => card.section == SupportiveSection.fromZyra),
      isEmpty,
    );
  });

  test(
    'ordinary connected or active state is not a permanent account snapshot',
    () {
      expect(_project(_snapshot()), isEmpty);
      expect(
        _project(_snapshot(journeyKind: DashboardJourneyKind.active)),
        isEmpty,
      );
      expect(
        _project(
          _snapshot(
            journeyKind: DashboardJourneyKind.paused,
            journeyTitle: 'Your Journey with Adam is paused',
          ),
        ).single.title,
        'Your Journey with Adam is paused',
      );
    },
  );

  testWidgets(
    'default member receives the selected Quiet Index production view',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeekerDashboardScreen(
            unreadCount: 0,
            onOpenConnections: () {},
            onOpenGuardian: () {},
            loadDashboard: () async => _snapshot(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('My ZYRA'), findsOneWidget);
      expect(
        find.text('Nothing needs your attention right now.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('my-zyra-fixture-label')), findsNothing);
      expect(find.byKey(const ValueKey('supportive-dashboard')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('shared renderer guards fixtures explicitly in release', () {
    final source = File(
      'lib/widgets/zyra_quiet_dashboard.dart',
    ).readAsStringSync();
    expect(source, contains('!kReleaseMode'));
    expect(source, contains('ZyraDeveloperAccess.canUseDeveloperTools'));
  });

  testWidgets(
    'Founder can select a scenario then restore the loaded current view',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDevScenario.instance.setDashboardLabEnabled(false);
      var loaded = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SeekerDashboardScreen(
            unreadCount: 0,
            onOpenConnections: () {},
            onOpenGuardian: () {},
            loadDashboard: () async {
              loaded++;
              return _snapshot();
            },
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('seeker-production-dashboard')),
        findsOneWidget,
      );
      SupportiveDashboardPreview.instance.selectScenario(
        SupportivePreviewScenario.oneAction,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
        findsOneWidget,
      );
      expect(
        find.text(
          SupportiveDashboardPreview
              .instance
              .fixture
              .resolution
              .answer
              .item!
              .signal
              .title,
        ),
        findsOneWidget,
      );
      SupportiveDashboardPreview.instance.selectView(false);
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('seeker-production-dashboard')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('supportive-dashboard')), findsNothing);
      expect(loaded, greaterThanOrEqualTo(1));
    },
  );

  testWidgets(
    'sample routes open only local destination preview, never owner callback',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDevScenario.instance.setDashboardLabEnabled(false);
      SupportiveDashboardPreview.instance.selectScenario(
        SupportivePreviewScenario.oneAction,
      );
      var ownerCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SeekerDashboardScreen(
            unreadCount: 0,
            onOpenConnections: () => ownerCalls++,
            onOpenGuardian: () => ownerCalls++,
            loadDashboard: () async => _snapshot(),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('View Journey'));
      await tester.pumpAndSettle();
      expect(find.text('Destination preview'), findsOneWidget);
      expect(ownerCalls, 0);
      await tester.tap(find.text('Back to My ZYRA'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
        findsOneWidget,
      );
    },
  );

  test('release denies preview even with refreshed developer authority', () {
    for (final release in [true, false]) {
      for (final authorized in [true, false]) {
        expect(
          supportivePreviewAllowed(
            isRelease: release,
            developerAuthorized: authorized,
          ),
          !release && authorized,
        );
      }
    }
  });

  test('unauthorized direct fixture and selection calls expose no samples', () {
    final preview = SupportiveDashboardPreview.instance;
    preview.selectScenario(SupportivePreviewScenario.allNow);
    preview.selectView(true);
    preview.selectSources(true);
    expect(preview.enabled, isFalse);
    expect(preview.useCurrentSources, isFalse);
    for (final scenario in SupportivePreviewScenario.values) {
      final fixture = SupportiveDashboardFixtures.build(scenario);
      expect(fixture.cards, isEmpty, reason: scenario.name);
      expect(
        fixture.resolution.answer.kind,
        DashboardAnswerKind.refreshRequired,
      );
      expect(fixture.resolution.sourceHealth, DashboardSourceHealth.failed);
      expect(fixture.resolution.journey.summary, isNull);
      expect(fixture.resolution.stableState.family.valueOrNull, isNull);
      expect(
        supportiveCardsFromResolution(
          fixture.resolution,
          comparisonClock: _clock,
        ),
        isEmpty,
        reason: scenario.name,
      );
    }
  });

  testWidgets('unauthorized leaf denies injected fixture and source content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _dashboard(
        resolution: _resolve(
          _snapshot(
            journeySignals: [
              _signal('private-action', DashboardSignalKind.addressedDecision),
            ],
          ),
        ),
        fixtureMode: true,
        cards: const [
          SupportiveCard(
            id: 'poison',
            section: SupportiveSection.fromZyra,
            title: 'Secret sample',
          ),
        ],
      ),
    );
    expect(
      find.byKey(const ValueKey('quiet-index-fixture-denied')),
      findsOneWidget,
    );
    expect(find.text('Secret sample'), findsNothing);
    expect(find.text('Signal private-action'), findsNothing);
    expect(find.text('My ZYRA'), findsNothing);
  });

  testWidgets('authority revocation closes a mounted fixture immediately', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(_dashboard(fixtureMode: true));
    expect(
      find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
      findsOneWidget,
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('quiet-index-fixture-denied')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('my-zyra-quiet-dashboard')), findsNothing);
  });

  testWidgets(
    'revoking a fixture-first screen starts and completes the real loader',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      SupportiveDashboardPreview.instance.selectScenario(
        SupportivePreviewScenario.oneAction,
      );
      final sampleTitle = SupportiveDashboardPreview
          .instance
          .fixture
          .resolution
          .answer
          .item!
          .signal
          .title;
      final pending = Completer<DashboardSnapshot>();
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SeekerDashboardScreen(
            unreadCount: 0,
            onOpenConnections: () {},
            onOpenGuardian: () {},
            loadDashboard: () {
              loads++;
              return pending.future;
            },
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(
          SupportiveDashboardPreview
              .instance
              .fixture
              .resolution
              .answer
              .item!
              .signal
              .title,
        ),
        findsOneWidget,
      );
      expect(
        loads,
        0,
        reason: 'A fixture-first mount must not initiate account reads.',
      );
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      expect(loads, 1);
      expect(find.byKey(const ValueKey('supportive-dashboard')), findsNothing);
      expect(find.text(sampleTitle), findsNothing);
      pending.complete(
        _snapshot(
          journeySignals: [
            _signal(
              'authoritative-action',
              DashboardSignalKind.addressedDecision,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('seeker-production-dashboard')),
        findsOneWidget,
      );
      expect(find.text('Signal authoritative-action'), findsOneWidget);
      expect(find.text(sampleTitle), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'existing-source mode ignores poisoned fixture editorial and Insights',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      const poisoned = [
        SupportiveCard(
          id: 'poison-editorial',
          section: SupportiveSection.fromZyra,
          title: 'Unpublished announcement',
        ),
        SupportiveCard(
          id: 'poison-insight',
          section: SupportiveSection.working,
          title: 'Unverified personal finding',
          evidence: _evidence,
        ),
      ];
      await tester.pumpWidget(_dashboard(cards: poisoned));
      expect(find.text('Unpublished announcement'), findsNothing);
      await tester.pumpWidget(_dashboard(cards: poisoned, tab: 1));
      await tester.pumpAndSettle();
      expect(find.text('Unverified personal finding'), findsNothing);
      expect(
        find.text('Insights will grow with your ZYRA experience'),
        findsOneWidget,
      );
      expect(
        find.text(
          'ZYRA will only show an Insight when reliable information genuinely supports it. We will not guess or fill this page with generic statistics.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'only confirmed all-clear uses the calm copy and omits section shells',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await _pumpFixture(
        tester,
        SupportiveDashboardFixtures.build(SupportivePreviewScenario.allClear),
      );
      expect(find.byKey(const ValueKey('my-zyra-quiet')), findsOneWidget);
      expect(find.text('You’re all caught up'), findsOneWidget);
      expect(
        find.text('Nothing needs your attention right now.'),
        findsOneWidget,
      );
      for (final section in SupportiveSection.values) {
        expect(find.text(section.label), findsNothing);
      }
    },
  );

  testWidgets('source failure stays visible and Retry invokes its callback', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    var retries = 0;
    final fixture = SupportiveDashboardFixtures.build(
      SupportivePreviewScenario.failed,
    );
    await tester.pumpWidget(
      _dashboard(resolution: fixture.resolution, onRetry: () => retries++),
    );
    expect(find.byKey(const ValueKey('my-zyra-quiet')), findsNothing);
    expect(find.byKey(const ValueKey('my-zyra-source-gap')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my-zyra-retry')));
    expect(retries, 1);
  });

  testWidgets('last-known rows remain visibly stale after failed refresh', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final fixture = SupportiveDashboardFixtures.build(
      SupportivePreviewScenario.lastKnown,
    );
    await _pumpFixture(tester, fixture);
    expect(find.textContaining('Last known'), findsWidgets);
    expect(find.byKey(const ValueKey('my-zyra-quiet')), findsNothing);
    expect(find.text('Journey resumed'), findsOneWidget);
  });

  testWidgets(
    'unknown updates and failed Guardian status never imply all-clear',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      for (final snapshot in [
        _snapshot(updates: const DashboardSource.loading()),
        _snapshot(
          family: const DashboardSource.unavailable(
            DashboardFailure(code: 'family_failed'),
          ),
        ),
      ]) {
        await tester.pumpWidget(_dashboard(resolution: _resolve(snapshot)));
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.byKey(const ValueKey('my-zyra-quiet')), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'failed or loading Insights cannot display supplied personal samples or empty copy',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      for (final source in <DashboardSource<List<DashboardSignal>>>[
        const DashboardSource.loading(),
        const DashboardSource.unavailable(
          DashboardFailure(code: 'insights_failed'),
        ),
      ]) {
        await tester.pumpWidget(
          _dashboard(
            resolution: _resolve(_snapshot(insights: source)),
            cards: const [
              SupportiveCard(
                id: 'failure-poison',
                section: SupportiveSection.working,
                title: 'This should be suppressed',
                evidence: _evidence,
              ),
            ],
            fixtureMode: true,
            tab: 1,
          ),
        );
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('This should be suppressed'), findsNothing);
        expect(
          find.byKey(const ValueKey('my-zyra-insights-empty')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'null-read-state movement gets neither read nor unread language',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpWidget(
        _dashboard(
          resolution: _resolve(
            _snapshot(
              updates: DashboardSource.available([
                _signal(
                  'no-read-semantics',
                  DashboardSignalKind.meaningfulMovement,
                ),
              ]),
            ),
          ),
        ),
      );
      expect(find.text('Signal no-read-semantics'), findsOneWidget);
      expect(find.text('Read'), findsNothing);
      expect(find.text('Unread'), findsNothing);
      expect(find.text('New'), findsNothing);
    },
  );

  testWidgets(
    'domain card navigates to owner intent without inline decisions',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      SupportiveCard? destination;
      await tester.pumpWidget(
        _dashboard(
          resolution: _resolve(
            _snapshot(
              journeySignals: [
                _signal(
                  'exact-domain-id',
                  DashboardSignalKind.addressedDecision,
                ),
              ],
            ),
          ),
          onNavigate: (card) => destination = card,
        ),
      );
      await tester.tap(find.text('View Journey'));
      expect(destination?.id, 'exact-domain-id');
      expect(destination?.target, ZyraDashboardTarget.connectionsJourneys);
      for (final ownerAction in [
        'Continue Journey',
        'Accept',
        'Decline',
        'Pause Journey',
        'End Journey',
      ]) {
        expect(find.text(ownerAction), findsNothing);
      }
    },
  );

  testWidgets(
    'personalised sample explains all evidence and can hide/mute locally',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      const cards = [
        SupportiveCard(
          id: 'first-pattern',
          section: SupportiveSection.working,
          title: 'First sample pattern',
          evidence: _evidence,
        ),
        SupportiveCard(
          id: 'second-pattern',
          section: SupportiveSection.working,
          title: 'Second sample pattern',
          evidence: _evidence,
        ),
      ];
      await tester.pumpWidget(
        _dashboard(cards: cards, fixtureMode: true, tab: 1),
      );
      await tester.tap(
        find.byKey(const ValueKey('my-zyra-evidence-first-pattern')),
      );
      await tester.pumpAndSettle();
      for (final text in [
        _evidence.summary,
        _evidence.period,
        _evidence.reason,
        _evidence.limitation,
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('my-zyra-hide-first-pattern')),
      );
      await tester.tap(
        find.byKey(const ValueKey('my-zyra-hide-first-pattern')),
      );
      await tester.pumpAndSettle();
      expect(find.text('First sample pattern'), findsNothing);
      expect(find.text('Second sample pattern'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('my-zyra-evidence-second-pattern')),
      );
      await tester.tap(
        find.byKey(const ValueKey('my-zyra-evidence-second-pattern')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('my-zyra-mute-second-pattern')).first,
      );
      await tester.tap(
        find.byKey(const ValueKey('my-zyra-mute-second-pattern')).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Second sample pattern'), findsNothing);
      await tester.pumpWidget(
        _dashboard(cards: [...cards], fixtureMode: true, tab: 1),
      );
      await tester.pump();
      expect(find.text('First sample pattern'), findsNothing);
      expect(find.text('Second sample pattern'), findsNothing);
      expect(
        find.byKey(const ValueKey('my-zyra-insights-hidden')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('my-zyra-reset-insights')),
      );
      await tester.tap(find.byKey(const ValueKey('my-zyra-reset-insights')));
      await tester.pumpAndSettle();
      expect(find.text('First sample pattern'), findsOneWidget);
    },
  );

  testWidgets('all-Now scenario fits 320px with 130 percent text', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = SupportiveDashboardFixtures.build(
      SupportivePreviewScenario.allNow,
    );
    await tester.pumpWidget(
      _dashboard(
        resolution: fixture.resolution,
        cards: fixture.cards,
        fixtureMode: true,
        scale: 1.3,
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
  });

  final preview = SupportiveDashboardPreview.instance;
  final options = <(String, void Function())>[
    for (final value in SupportiveActionExample.values)
      ('action ${value.name}', () => preview.selectAction(value)),
    for (final value in SupportiveStatusExample.values)
      ('status ${value.name}', () => preview.selectStatus(value)),
    for (final value in SupportiveChangeExample.values)
      ('change ${value.name}', () => preview.selectChange(value)),
    for (final value in SupportiveEditorialExample.values)
      ('editorial ${value.name}', () => preview.selectEditorial(value)),
    for (final value in SupportiveInsightExample.values)
      ('insight ${value.name}', () => preview.selectInsight(value)),
    for (final value in SupportiveReflectionTopic.values)
      ('reflection ${value.name}', () => preview.selectReflection(value)),
  ];
  for (final option in options) {
    testWidgets('${option.$1} is selectable and renders its sample', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      option.$2();
      expect(preview.enabled, isTrue);
      expect(preview.useCurrentSources, isFalse);
      final fixture = preview.fixture;
      final cards = mergeSupportiveCards(
        supportiveCardsFromResolution(
          fixture.resolution,
          comparisonClock: _clock,
        ),
        fixture.cards,
      );
      expect(cards, isNotEmpty);
      await _pumpFixture(tester, fixture);
      expect(find.text(cards.first.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
