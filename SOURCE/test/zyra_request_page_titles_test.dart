import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/screens/wali/wali_seekers_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_guardian_seeker_roster_resolver.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

// Pure, synthetic presentation fixtures. No login or developer grant is made,
// and fake permissions never establish backend Guardian authority.
class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Main-title fixtures must remain offline.');
  }
}

const _profile = SeekerProfile(
  id: 'title-fixture-seeker',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  photos: [],
  gender: 'female',
);
const _person = WaliLinkedPerson(
  id: 'title-fixture-seeker',
  firstName: 'Sara',
  isMain: true,
  relationship: 'father',
);

ZyraConceptAccountData _account(bool guardian) => ZyraConceptAccountData(
  guardian: guardian,
  name: guardian ? 'Hassan Rahman' : 'Adam Khan',
  age: guardian ? '54' : '30',
  gender: 'Male',
  location: 'London',
  membership: guardian ? 'Guardian One' : 'Seeker One',
  isOne: true,
  relationship: 'Father',
  linkedSeekers: '1',
  guardianCount: '2',
  signedInWith: 'Google',
  backgroundLabel: 'Midnight Plum',
  hapticLabel: 'Subtle',
  gold: false,
);

DashboardResolution _dashboardResolution() => DashboardResolution(
  answer: const DashboardAnswer.calm(),
  otherActions: const [],
  journey: const DashboardJourneyResolution.unavailable(),
  stableState: const DashboardStableState(),
  recently: const [],
  updatesState: DashboardSectionState.available,
  intelligence: const [],
  insightsState: DashboardSectionState.available,
  tone: DashboardTone.calm,
  sourceHealth: DashboardSourceHealth.complete,
);

Widget _dashboard({Alignment alignment = Alignment.centerLeft}) =>
    ZyraQuietDashboard(
      resolution: _dashboardResolution(),
      singlePage: true,
      titleAlignment: alignment,
    );

Widget _guardianPage({
  Alignment alignment = Alignment.centerLeft,
  double? titleSize = 26,
}) => SafeArea(
  bottom: false,
  child: SeekerGuardianPage(
    people: const [],
    activity: const {},
    linksAvailable: true,
    activityAvailable: true,
    onRetry: () {},
    onAdd: () {},
    titleAlignment: alignment,
    titleSize: titleSize,
    pendingInvitesLoader: () async =>
        const ZyraSourceResult.available(<PendingInvite>[]),
  ),
);

Widget _roster({Alignment alignment = Alignment.centerLeft}) =>
    GuardianSeekerRosterView(
      resolution: const GuardianSeekerRosterResolution(
        mainSections: [],
        additionalGuardianships: [],
      ),
      titleAlignment: alignment,
      decoration: const BoxDecoration(),
      onRetry: () {},
      onInvite: () {},
      onOpenSeeker: (_) {},
    );

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
  // Futures injected into ordinary renderers are immediate and finite. Avoid
  // pumpAndSettle because another screen's persistent motion is not a test
  // completion condition.
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(tester.takeException(), isNull);
}

void _expectTitle(WidgetTester tester, String key, String label, double width) {
  final finder = _key(key);
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder);
  expect(text.data, label);
  expect(text.style?.fontSize, 26);
  expect(text.textAlign, TextAlign.left);
  final rect = tester.getRect(finder);
  expect(rect.top, closeTo(40, .1));
  expect(rect.left, closeTo(20, .1));
  for (final element in find.byType(Text).evaluate()) {
    final other = tester.getRect(find.byElementPredicate((e) => e == element));
    if (other.overlaps(Rect.fromLTWH(0, 0, width, 852))) {
      expect(other.top, greaterThanOrEqualTo(rect.top - .1));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NoNetwork network;
  HttpOverrides? previousOverrides;

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = true;
    network = _NoNetwork();
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = network;
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousOverrides;
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraAccountState.resetForTesting();
  });

  final pages = <({String label, String key, Widget Function() build})>[
    (
      label: 'Profiles',
      key: 'concept_browse_title',
      build: () => const ZyraOneJourneyBrowseDesigns(
        profiles: [_profile],
        selectedIndex: 0,
        design: ZyraOneJourneyBrowseDesign.portraitCard,
      ),
    ),
    (
      label: 'Journey',
      key: 'concept_connections_title',
      build: () => ZyraOneJourneyConnectionsPresentation(
        title: 'Journey',
        labels: const ['Journey'],
        pages: const [
          [SizedBox()],
        ],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
    ),
    (label: 'My ZYRA', key: 'my-zyra-main-title', build: _dashboard),
    (label: 'Guardian', key: 'guardian-manager-title', build: _guardianPage),
    (
      label: 'Profile',
      key: 'concept_profile_title',
      build: () => ZyraConceptProfilePresentation(
        data: _account(false),
        simplifiedMethodology: true,
        onAction: (_) {},
        onSwitchRole: () {},
      ),
    ),
    (
      label: 'Guardian Dashboard',
      key: 'concept_guardian_dashboard_title',
      build: () => ZyraOneJourneyGuardianDashboardPresentation(
        profile: _profile,
        person: _person,
        guardianName: 'Hassan',
        onProfile: () {},
        onJourney: () {},
      ),
    ),
    (
      label: 'Network',
      key: 'concept_guardian_network_title',
      build: () => ZyraOneJourneyGuardianNetworkPresentation(
        person: _person,
        profiles: const [],
        selectedIndex: 0,
        onChanged: (_) {},
        onProfile: (_) {},
        onIntroduction: (_) {},
      ),
    ),
    (label: 'Seekers', key: 'guardian-seekers-title', build: _roster),
    (
      label: 'Profile',
      key: 'concept_profile_title',
      build: () => ZyraConceptProfilePresentation(
        data: _account(true),
        simplifiedMethodology: true,
        onAction: (_) {},
        onSwitchRole: () {},
      ),
    ),
  ];

  for (var index = 0; index < pages.length; index++) {
    final page = pages[index];
    for (final narrow in [false, true]) {
      testWidgets('main $index ${page.label} title${narrow ? ' narrow' : ''}', (
        tester,
      ) async {
        final size = narrow ? const Size(320, 568) : const Size(393, 852);
        await _mount(tester, page.build(), size: size, scale: narrow ? 2 : 1);
        _expectTitle(tester, page.key, page.label, size.width);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('shared ordinary headings retain their original alignment', (
    tester,
  ) async {
    for (final page in <({String key, Widget child, double size})>[
      (
        key: 'my-zyra-main-title',
        child: ZyraQuietDashboard(resolution: _dashboardResolution()),
        size: 26,
      ),
      (
        key: 'guardian-manager-title',
        child: _guardianPage(alignment: Alignment.centerLeft, titleSize: null),
        size: 26,
      ),
      (
        key: 'guardian-seekers-title',
        child: _roster(alignment: Alignment.centerLeft),
        size: 26,
      ),
    ]) {
      await _mount(tester, page.child);
      final title = tester.widget<Text>(_key(page.key));
      expect(title.textAlign, TextAlign.left);
      expect(title.style?.fontSize, page.size);
      expect(tester.getRect(_key(page.key)).left, closeTo(20, .1));
    }
  });

  // Rehearse the parent-owned multi-Journey seam with synthetic selections.
  // The shell's owner/navigation guards are tested in its separate suite.
  final wrappedPages = <({String label, Widget Function() build})>[
    (
      label: 'Guardian Dashboard',
      build: () => ZyraOneJourneyGuardianDashboardPresentation(
        profile: _profile,
        person: _person,
        guardianName: 'Hassan',
        onProfile: () {},
        onJourney: () {},
        showHeader: false,
      ),
    ),
    (
      label: 'Seekers',
      build: () => ZyraOneJourneyGuardianSeekersPresentation(
        profile: _profile,
        person: _person,
        onJourney: () {},
        onNetwork: () {},
        onInvite: () {},
        showHeader: false,
      ),
    ),
    (
      label: 'Network',
      build: () => ZyraOneJourneyGuardianNetworkPresentation(
        person: _person,
        profiles: const [],
        selectedIndex: 0,
        onChanged: (_) {},
        onProfile: (_) {},
        onIntroduction: (_) {},
        showHeader: false,
      ),
    ),
  ];
  for (final page in wrappedPages) {
    for (final count in [2, 3]) {
      testWidgets(
        '${page.label} main title stays above $count Journey selector',
        (tester) async {
          await _mount(
            tester,
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      page.label,
                      key: const ValueKey('wrapped-main-title'),
                      textAlign: TextAlign.left,
                      style: ZyraText.heading(size: 26),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'JOURNEY WITH · ${List.generate(count, (i) => 'Person ${i + 1}').join(' · ')}',
                      key: const ValueKey('wrapped-journey-selector'),
                      style: ZyraText.body(size: 12),
                    ),
                  ),
                  Expanded(child: page.build()),
                ],
              ),
            ),
            size: const Size(320, 568),
            scale: 2,
          );
          _expectTitle(tester, 'wrapped-main-title', page.label, 320);
          expect(find.text(page.label), findsOneWidget);
          expect(
            tester.getRect(_key('wrapped-journey-selector')).top,
            greaterThan(tester.getRect(_key('wrapped-main-title')).bottom),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('simplified Profile has no second ended-history entry', (
    tester,
  ) async {
    final actions = <ZyraConceptAccountAction>[];
    await _mount(
      tester,
      ZyraConceptProfilePresentation(
        data: _account(false),
        simplifiedMethodology: true,
        onAction: actions.add,
        onSwitchRole: () {},
      ),
      size: const Size(900, 1800),
    );
    expect(_key('concept_past_journeys'), findsNothing);
    expect(find.text('Ended Journeys'), findsNothing);
    expect(find.text('Past Journeys'), findsNothing);
    expect(find.text('JOURNEY HISTORY'), findsNothing);
    expect(actions, isEmpty);

    await _mount(
      tester,
      ZyraConceptProfilePresentation(
        data: _account(false),
        onAction: actions.add,
        onSwitchRole: () {},
      ),
      size: const Size(900, 1800),
    );
    expect(_key('concept_past_journeys'), findsOneWidget);
    await tester.ensureVisible(_key('concept_past_journeys'));
    await tester.pump();
    await tester.tap(_key('concept_past_journeys'));
    await tester.pump();
    expect(actions, [ZyraConceptAccountAction.pastJourneys]);
  });

  for (final fixture in [
    (main: true, staleEnabled: false),
    (main: true, staleEnabled: true),
    (main: false, staleEnabled: true),
  ]) {
    testWidgets(
      '${fixture.main ? 'Main unavailable Chat is disabled OFF' : 'Additional contradictory Chat denies Journey access'} '
      'even with stale=${fixture.staleEnabled}',
      (tester) async {
        var writes = 0;
        await _mount(
          tester,
          SafeArea(
            child: SeekerGuardianPage(
              people: [
                WaliLinkedPerson(
                  id: 'synthetic-guardian',
                  firstName: 'Hassan',
                  isMain: fixture.main,
                ),
              ],
              activity: const {},
              linksAvailable: true,
              activityAvailable: true,
              onRetry: () {},
              onAdd: () {},
              journeyAccessLoader:
                  ({
                    required guardianId,
                    attemptId,
                    enabled,
                    chatEnabled,
                  }) async {
                    if (enabled != null || chatEnabled != null) writes++;
                    return ZyraSourceResult.available([
                      GuardianJourneyAccessState(
                        attemptId: 'synthetic-attempt',
                        matchId: 'synthetic-match',
                        counterpartFirstName: 'Sara',
                        included: true,
                        canChange: !fixture.main,
                        guardianIsMain: fixture.main,
                        chatAvailable: false,
                        chatEnabled: fixture.staleEnabled,
                      ),
                    ]);
                  },
              historyConsentLoader:
                  ({
                    required guardianId,
                    required guardianIsMain,
                    enabled,
                  }) async => ZyraSourceResult.available(
                    GuardianHistoryConsentState(
                      enabled: false,
                      activeGuardianLinkId: 'synthetic-link',
                      guardianId: guardianId,
                      guardianIsMain: guardianIsMain,
                    ),
                  ),
            ),
          ),
          size: const Size(430, 932),
        );
        expect(
          _key('guardian-journey-chat-required-synthetic-attempt'),
          findsNothing,
        );
        if (!fixture.main) {
          // An enabled Chat flag without Chat availability is contradictory.
          // The Additional-Guardian projection must reject the whole attempt,
          // not preserve a writable View control from that untrusted row.
          expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
          expect(
            find.text('Journey access could not be refreshed.'),
            findsOneWidget,
          );
          for (final control in [
            'guardian-journey-chat-toggle-synthetic-attempt',
            'guardian-journey-chat-required-synthetic-attempt',
            'guardian-journey-access-toggle-synthetic-attempt',
            'guardian-journey-view-required-synthetic-attempt',
          ]) {
            expect(_key(control), findsNothing);
          }
          expect(find.text('Journey with Sara'), findsNothing);
          expect(_key('guardian-journey-chat-unavailable'), findsNothing);
        } else {
          final chatControl = _key(
            'guardian-journey-chat-toggle-synthetic-attempt',
          );
          final chat = tester.widget<Semantics>(chatControl).properties;
          expect(chat.toggled, isFalse);
          expect(chat.enabled, isFalse);
          expect(chat.onTap, isNull);
          expect(chat.label, 'Chat unavailable in Journey with Sara');
          expect(tester.getSize(chatControl), const Size(44, 44));
          expect(
            tester
                .widget<InkWell>(
                  find.descendant(
                    of: chatControl,
                    matching: find.byType(InkWell),
                  ),
                )
                .onTap,
            isNull,
          );
          expect(
            find.descendant(of: chatControl, matching: find.byType(Switch)),
            findsNothing,
          );
          expect(
            find.descendant(
              of: chatControl,
              matching: find.byIcon(Icons.check_rounded),
            ),
            findsNothing,
          );
          expect(_key('guardian-journey-chat-unavailable'), findsOneWidget);
          expect(
            find.text('Chat is unavailable for this Journey.'),
            findsOneWidget,
          );
          final requiredView = _key(
            'guardian-journey-view-required-synthetic-attempt',
          );
          expect(requiredView, findsOneWidget);
          expect(tester.getSize(requiredView), const Size(26, 26));
          expect(
            find.descendant(
              of: requiredView,
              matching: find.byIcon(Icons.check_rounded),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: requiredView, matching: find.byType(InkWell)),
            findsNothing,
          );
          final requiredSemantics = tester
              .widgetList<Semantics>(
                find.ancestor(
                  of: requiredView,
                  matching: find.byType(Semantics),
                ),
              )
              .singleWhere(
                (widget) =>
                    widget.properties.label ==
                    'View required for Journey with Sara',
              );
          expect(requiredSemantics.properties.onTap, isNull);
          expect(requiredSemantics.properties.toggled, isNull);
          expect(
            _key('guardian-journey-access-toggle-synthetic-attempt'),
            findsNothing,
          );
          await tester.tap(chatControl);
          await tester.pump();
        }
        expect(writes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
