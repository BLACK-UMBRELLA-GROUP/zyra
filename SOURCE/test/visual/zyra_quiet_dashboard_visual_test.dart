// Fresh review evidence only; existing approved baseline images are untouched.
// Capture with --update-goldens --dart-define=MY_ZYRA_QUIET_INDEX_CAPTURE=true.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

const _capture = bool.fromEnvironment('MY_ZYRA_QUIET_INDEX_CAPTURE');
const _root = ValueKey('my-zyra-quiet-review-root');
const _directory = 'test/visual/candidates/my_zyra_quiet_index_v1';
final _clock = SupportiveDashboardFixtures.clock;
const _states = <({String name, SupportivePreviewScenario scenario})>[
  (name: 'quiet', scenario: SupportivePreviewScenario.allClear),
  (name: 'busy', scenario: SupportivePreviewScenario.allNow),
  (
    name: 'insights-populated',
    scenario: SupportivePreviewScenario.insightsPopulated,
  ),
  (name: 'insights-empty', scenario: SupportivePreviewScenario.insightsEmpty),
  (name: 'failed', scenario: SupportivePreviewScenario.failed),
  (name: 'last-known', scenario: SupportivePreviewScenario.lastKnown),
  (name: 'loading', scenario: SupportivePreviewScenario.loading),
  (name: 'insights-failed', scenario: SupportivePreviewScenario.insightsFailed),
  (name: 'resume-request', scenario: SupportivePreviewScenario.oneAction),
];
const _variants = <({String name, Size size, double scale, String firstName})>[
  (name: 'small', size: Size(320, 568), scale: 1, firstName: 'Maryam'),
  (name: 'standard', size: Size(390, 844), scale: 1, firstName: 'Maryam'),
  (name: 'large', size: Size(430, 932), scale: 1, firstName: 'Maryam'),
  (name: 'text-130', size: Size(390, 844), scale: 1.3, firstName: 'Maryam'),
  (
    name: 'long-name',
    size: Size(320, 568),
    scale: 1.3,
    firstName: 'Maryam-Alexandria Noorulhuda',
  ),
];

Future<ByteData> _font(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

Widget _app(Widget child, double scale) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: ZyraColors.actionFill,
      brightness: Brightness.dark,
    ),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: RepaintBoundary(key: _root, child: child!),
  ),
  home: child,
);

void main() {
  final captured = <Map<String, Object>>[];
  final startedAt = DateTime.now().toUtc();
  final elapsed = Stopwatch()..start();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    final reading = FontLoader('PoppinsAudit')
      ..addFont(_font('assets/fonts/Poppins-ExtraLight.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Light.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(_font('assets/fonts/Poppins-SemiBold.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Bold.ttf'));
    final wordmark = FontLoader('SyneAudit')
      ..addFont(_font('assets/fonts/Syne-SemiBold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
    ZyraText.testWordmarkFontFamily = 'SyneAudit';
  });

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    SupportiveDashboardPreview.instance.reset();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraInteractionStyle.restoreDefaults();
    AppState.instance.gender = 'female';
    AppState.instance.plan = ZyraPlan.basic;
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    SupportiveDashboardPreview.instance.reset();
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    if (_capture && captured.isNotEmpty) {
      final manifest = <String, Object>{
        'status': 'QUIET_INDEX_IMPLEMENTATION_REVIEW_NOT_FOUNDER_ACCEPTED',
        'approved': false,
        'renderer': 'ZyraQuietDashboard',
        'capture_command':
            'flutter test --no-pub --update-goldens --dart-define=MY_ZYRA_QUIET_INDEX_CAPTURE=true test/visual/zyra_quiet_dashboard_visual_test.dart --reporter expanded',
        'started_at_utc': startedAt.toIso8601String(),
        'finished_at_utc': DateTime.now().toUtc().toIso8601String(),
        'elapsed_milliseconds': elapsed.elapsedMilliseconds,
        'approved_baselines_changed': false,
        'clock_utc': _clock.toIso8601String(),
        'palette': 'midnightPlum',
        'surface': 'glassSignals',
        'reading_font': 'PoppinsAudit (bundled Poppins)',
        'wordmark_font': 'SyneAudit (bundled Syne)',
        'icon_font': 'MaterialIcons (Flutter bundled asset)',
        'device_pixel_ratio': 1,
        'fixture_data_only': true,
        'states': _states.map((state) => state.name).toList(),
        'variants': _variants.map((variant) => variant.name).toList(),
        'supplemental_states_standard_only': [
          'loading',
          'insights-failed',
          'resume-request',
        ],
        'captures': captured,
      };
      File('$_directory/manifest.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      );
    }
  });

  for (final state in _states) {
    for (final variant in _variants) {
      if (const {
            'loading',
            'insights-failed',
            'resume-request',
          }.contains(state.name) &&
          variant.name != 'standard') {
        continue;
      }
      final id = 'quietIndex__${state.name}__${variant.name}';
      testWidgets('$id renders without overflow', (tester) async {
        tester.view.physicalSize = variant.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final counterpartName = variant.name == 'long-name'
            ? 'Abdurrahman-Muhammad Noorulhuda'
            : 'Adam';
        final fixture = SupportiveDashboardFixtures.build(
          state.scenario,
          personalized: true,
          counterpartName: counterpartName,
          action: state.name == 'resume-request'
              ? SupportiveActionExample.resumeRequest
              : SupportiveActionExample.journeyRequest,
        );
        final scrollKey = ValueKey('my-zyra-quiet-scroll-${fixture.tabIndex}');
        await tester.pumpWidget(
          _app(
            ZyraQuietDashboard(
              resolution: fixture.resolution,
              fixtureCards: fixture.cards,
              fixtureMode: true,
              comparisonClock: _clock,
              firstName: variant.firstName,
              selectedTabIndex: fixture.tabIndex,
              onNavigate: (_) {},
              onRetry: () {},
            ),
            variant.scale,
          ),
        );
        // Loading may intentionally keep an animation scheduled.
        if (state.name == 'loading') {
          await tester.pump(const Duration(milliseconds: 500));
        } else {
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        Future<void> capture(String frameId, String position) async {
          if (!_capture) return;
          expect(
            autoUpdateGoldenFiles,
            isTrue,
            reason:
                'Explicit capture needs --update-goldens and writes only the new candidates directory.',
          );
          await expectLater(
            find.byKey(_root),
            matchesGoldenFile('candidates/my_zyra_quiet_index_v1/$frameId.png'),
          );
          final bytes = File('$_directory/$frameId.png').readAsBytesSync();
          captured.add({
            'id': frameId,
            'approved': false,
            'design': 'quietIndex',
            'state': state.name,
            'scenario': state.scenario.name,
            'position': position,
            'width': variant.size.width.toInt(),
            'height': variant.size.height.toInt(),
            'text_scale': variant.scale,
            'first_name': variant.firstName,
            'counterpart_name': counterpartName,
            'file': '$frameId.png',
            'sha256': sha256.convert(bytes).toString(),
          });
        }

        Future<void> reveal(Finder target) async {
          await tester.drag(find.byKey(scrollKey), const Offset(0, 3000));
          await tester.pumpAndSettle();
          final scrollable = find
              .descendant(
                of: find.byKey(scrollKey),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            target,
            160,
            scrollable: scrollable,
            maxScrolls: 50,
          );
          await tester.pumpAndSettle();
        }

        await capture(id, 'top');
        if (const {
          'busy',
          'insights-populated',
          'last-known',
        }.contains(state.name)) {
          await tester.drag(find.byKey(scrollKey), const Offset(0, -1800));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await capture('${id}__lower', 'lower');
        }
        if (state.name == 'busy' && variant.name == 'standard') {
          final change = supportiveCardsFromResolution(
            fixture.resolution,
            comparisonClock: _clock,
          ).firstWhere((card) => card.section == SupportiveSection.changed);
          final control = find.byKey(
            ValueKey('quiet-index-disclosure-${change.id}'),
          );
          await reveal(control);
          await tester.tap(control);
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('quiet-index-details-${change.id}')),
            findsOneWidget,
          );
          await capture('${id}__expanded', 'change-expanded');
        }
        if (state.name == 'insights-populated' && variant.name == 'standard') {
          final evidenced = fixture.cards.firstWhere(
            (card) => card.evidence != null,
          );
          final control = find.byKey(
            ValueKey('my-zyra-evidence-${evidenced.id}'),
          );
          await reveal(control);
          await tester.tap(control);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await capture('${id}__evidence', 'evidence-expanded');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
