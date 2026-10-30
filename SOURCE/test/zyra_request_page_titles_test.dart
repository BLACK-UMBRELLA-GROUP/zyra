import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/screens/wali/wali_seekers_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_guardian_seeker_roster_resolver.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
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
}
