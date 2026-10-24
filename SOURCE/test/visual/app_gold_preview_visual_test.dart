// Fresh app-background comparison candidates only; never approved baselines.
// Actual Settings and Dashboard widgets use injectable local read fixtures.
// No Supabase initialization, network, account mutation, persistence or IDV.
// Capture with ZYRA_APP_GOLD_CAPTURE=true and --update-goldens.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zyra/dev/dev_settings_design_state.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/models/zyra_dashboard_lab.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/screens/settings/settings_screen.dart';
import 'package:zyra/screens/wali/wali_dashboard_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_dashboard_updates_service.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

const _capture = bool.fromEnvironment('ZYRA_APP_GOLD_CAPTURE');
const _boundary = ValueKey('app-gold-candidate');
const _directory = 'candidates/app_gold_preview_2026_10_04';
const _person = WaliLinkedPerson(
  id: 'app-gold-local-seeker',
  firstName: 'Maryam',
  relationship: 'father',
  isMain: true,
);

bool _select(bool value) => ZyraDevAppGold.instance.select(
  value,
  expectedGeneration: ZyraAccountState.generation,
  expectedRevision: ZyraDevAppGold.instance.revision,
);

const _seekerSnapshot = DashboardSnapshot(
  role: DashboardRole.seeker,
  onboarding: DashboardSource.available([]),
  journeys: DashboardSource.available(
    DashboardJourneyState(
      summary: DashboardJourneySummary(
        id: 'app-gold-local-search',
        kind: DashboardJourneyKind.searching,
        title: 'Ready for introductions',
        detail: 'New introductions will appear here.',
      ),
    ),
  ),
  updates: DashboardSource.available([]),
  guardianInvitations: DashboardSource.available([]),
  insights: DashboardSource.available([]),
  stableState: DashboardStableState(
    family: DashboardSource.available(
      DashboardFamilyStatus(
        kind: DashboardFamilyKind.notConnected,
        title: 'No Guardian connected',
        detail: 'Add a Guardian when you are ready.',
        actionLabel: 'Add Guardian',
      ),
    ),
  ),
);

Widget _dashboard({required bool guardian}) => Scaffold(
  body: Stack(
    fit: StackFit.expand,
    children: [
      if (guardian)
        WaliDashboardScreen(
          hasGuardianPlus: true,
          comparisonNow: DateTime(2026, 10, 4, 12),
          onOpenNetwork: () {},
          onOpenSeekers: () {},
          onOpenSeeker: (_) {},
          loadJourneys: () async => [],
          loadUpdates: () async =>
              ZyraDashboardUpdatesPage(rows: const [], nextCursor: null),
          loadOpenReviews: (_) async =>
              const ZyraSourceResult.available(<String>{}),
          loadProfiles: (_) async => const [
            SeekerProfile(
              id: 'app-gold-local-seeker',
              firstName: 'Maryam',
              surnameLine: 'Hussain',
              age: 27,
              city: 'Birmingham, UK',
              photos: [],
              gender: 'female',
            ),
          ],
        )
      else
        SeekerDashboardScreen(
          unreadCount: 0,
          onOpenConnections: () {},
          onOpenGuardian: () {},
          onOpenDiscovery: () {},
          onOpenProfile: () {},
          loadDashboard: () async => _seekerSnapshot,
        ),
      FloatingNavBar(
        currentIndex: guardian ? 0 : 2,
        onTap: (_) {},
        items: guardian
            ? const [
                FloatingNavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                ),
                FloatingNavItem(
                  icon: Icons.diversity_3_outlined,
                  label: 'Network',
                ),
                FloatingNavItem(icon: Icons.people_outline, label: 'Seekers'),
                FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
              ]
            : const [
                FloatingNavItem(icon: Icons.search, label: 'Browse'),
                FloatingNavItem(
                  icon: Icons.bookmark_border,
                  label: 'Connections',
                ),
                FloatingNavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'My ZYRA',
                ),
                FloatingNavItem(
                  icon: Icons.gpp_good_outlined,
                  label: 'Guardian',
                ),
                FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
              ],
      ),
    ],
  ),
);

Widget _subject(String name) => switch (name) {
  'seeker_settings' || 'guardian_settings' => SettingsScreen(
    guardian: name == 'guardian_settings',
    guardianHasOne: true,
    loadLinkedPeople: (_) async =>
        const ZyraSourceResult.available(<WaliLinkedPerson>[]),
  ),
  'seeker_dashboard' ||
  'guardian_dashboard' => _dashboard(guardian: name == 'guardian_dashboard'),
  'picker' => Scaffold(
    body: DecoratedBox(
      decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Background comparison',
                  style: ZyraText.heading(size: 24),
                ),
                const SizedBox(height: 24),
                const DevAppGoldPicker(),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
  _ => throw ArgumentError.value(name),
};

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final frame = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  try {
    final bytes = await tester.runAsync(
      () => frame!.toByteData(format: ui.ImageByteFormat.png),
    );
    return Uint8List.fromList(bytes!.buffer.asUint8List());
  } finally {
    frame?.dispose();
  }
}

Future<void> _candidate(
  WidgetTester tester,
  String name,
  Uint8List pixels,
) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  await tester.runAsync(
    () => expectLater(pixels, matchesGoldenFile('$_directory/$name.png')),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final reading = FontLoader('PoppinsAppGoldAudit');
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
    final wordmark = FontLoader('SyneAppGoldAudit')
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
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAppGoldAudit';
    ZyraText.testWordmarkFontFamily = 'SyneAppGoldAudit';
    PackageInfo.setMockInitialValues(
      appName: 'ZYRA',
      packageName: 'app.zyraconnect',
      version: '1.0.0',
      buildNumber: 'preview',
      buildSignature: '',
    );
  });

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    ZyraDevAppGold.instance.resetForTesting();
    ZyraDevScenario.instance.reset();
    ZyraDevScenario.instance.setDashboardLabEnabled(false);
    ZyraDevScenario.instance.setUseLiveGuardianData(true);
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    ZyraDevScenario.instance.markDashboardGuardianOptionSelected(
      ZyraDashboardTab.now,
    );
    ZyraDevScenario.instance.markDashboardGuardianOptionSelected(
      ZyraDashboardTab.insights,
    );
    SupportiveDashboardPreview.instance.reset();
    SupportiveDashboardPreview.instance.selectView(true);
    SupportiveDashboardPreview.instance.selectSources(true);
    ZyraDevSettingsDesign.select(ZyraSettingsDesign.current);
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    AppState.instance.gender = 'male';
    AppState.instance.plan = ZyraPlan.one;
    AppState.instance.waliName = 'Ibrahim';
    AppState.instance.setWaliRealLinkedSeekers(const [_person]);
  });

  tearDown(() {
    ZyraDevAppGold.instance.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevScenario.instance.reset();
    SupportiveDashboardPreview.instance.reset();
    AppState.instance.setWaliRealLinkedSeekers(const []);
    AppState.instance.waliName = null;
    AppState.instance.gender = null;
    AppState.instance.plan = ZyraPlan.basic;
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final layout in const [
    (name: 'standard', size: Size(390, 844), scale: 1.0),
    (name: 'compact140', size: Size(320, 568), scale: 1.4),
  ]) {
    for (final name in const [
      'seeker_settings',
      'guardian_settings',
      'seeker_dashboard',
      'guardian_dashboard',
      'picker',
    ]) {
      testWidgets('$name Off/On real fonts ${layout.name}', (tester) async {
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark().copyWith(
              textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                foregroundColor: ZyraColors.foreground,
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(layout.scale),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                disableAnimations: true,
              ),
              child: ZyraAppGoldPreviewHost(
                child: RepaintBoundary(key: _boundary, child: child!),
              ),
            ),
            home: _subject(name),
          ),
        );
        await tester.pumpAndSettle();
        if (name == 'seeker_dashboard') {
          expect(find.text('No Guardian connected yet'), findsOneWidget);
        } else if (name == 'guardian_dashboard') {
          expect(
            find.byKey(
              const ValueKey(
                'guardian-dashboard-seeker-snapshot-app-gold-local-seeker',
              ),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        expect(ZyraDevAppGold.instance.enabled, isFalse);
        final off = await _pixels(tester);
        await _candidate(tester, '${name}_${layout.name}_off', off);
        final originalElement = find.byKey(_boundary).evaluate().single;
        if (name == 'picker') {
          await tester.tap(find.byKey(const ValueKey('dev_app_gold_toggle')));
        } else {
          expect(_select(true), isTrue);
        }
        await tester.pumpAndSettle();
        expect(ZyraDevAppGold.instance.enabled, isTrue);
        expect(ZyraDevAppGold.instance.reducedMotion, isTrue);
        expect(find.byKey(_boundary).evaluate().single, same(originalElement));
        expect(tester.takeException(), isNull);
        final on = await _pixels(tester);
        expect(
          on,
          isNot(orderedEquals(off)),
          reason: 'On visibly changes $name',
        );
        await _candidate(tester, '${name}_${layout.name}_on', on);
        if (name == 'picker') {
          expect(find.text('On'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('dev_app_gold_toggle')));
        } else {
          expect(_select(false), isTrue);
        }
        await tester.pumpAndSettle();
        expect(ZyraDevAppGold.instance.enabled, isFalse);
        expect(tester.takeException(), isNull);
        // Screens remain mounted; no fixture reload or Navigator replacement.
        // Picker changes its label, but returns exactly to its initial Off view.
        expect(await _pixels(tester), orderedEquals(off));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(ZyraDevAppGold.instance.debugPainterCount, 0);
      });
    }
  }
}
