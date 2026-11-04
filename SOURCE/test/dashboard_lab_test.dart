import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/queue44_dashboard_fixture_catalog.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_dashboard_lab.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

final _categoryDropdowns = find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'dev_page_options_dropdown_',
      ),
);

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    SupportiveDashboardPreview.instance.reset();
    ZyraDevScenario.instance
      ..resetDashboardLab()
      ..setUseLiveGuardianData(false);
    ZyraColors.selectAppSurfaceStyle(ZyraColors.currentDefaultSurfaceStyle);
  });

  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

  testWidgets(
    'Dashboard sample categories are code-only and expose no controls',
    (tester) async {
      final scenario = ZyraDevScenario.instance;
      final catalog = zyraDashboardPageOptions(
        scenario,
        ZyraDashboardRole.seeker,
      );
      final groups = catalog.map((e) => e.group).toSet();
      expect(
        groups,
        containsAll(['Page view', 'What Needs You', 'Current status']),
      );
      expect(catalog, hasLength(40));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Member Dashboard'))),
      );
      expect(_categoryDropdowns, findsNothing);
      expect(find.text('Page options'), findsNothing);
      expect(find.text('APP SURFACE'), findsNothing);
    },
  );

  testWidgets(
    'code-selected supportive tab changes its data catalog without a picker',
    (tester) async {
      final scenario = ZyraDevScenario.instance;
      expect(
        zyraDashboardOptionsTitle(scenario, ZyraDashboardRole.seeker),
        'Now',
      );
      SupportiveDashboardPreview.instance.selectScenario(
        SupportivePreviewScenario.insightsEmpty,
      );
      expect(
        zyraDashboardOptionsTitle(scenario, ZyraDashboardRole.seeker),
        'Insights',
      );
      final catalog = zyraDashboardPageOptions(
        scenario,
        ZyraDashboardRole.seeker,
      );
      expect(catalog, hasLength(24));
      expect(catalog.map((e) => e.group).toSet(), isNotEmpty);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Member Dashboard'))),
      );
      expect(_categoryDropdowns, findsNothing);
      expect(
        find.byKey(const ValueKey('dev_page_options_dropdown')),
        findsNothing,
      );
    },
  );

  test('Dashboard reset preserves the locked app-wide surface', () {
    expect(ZyraColors.appSurfaceStyle, ZyraAppSurfaceStyle.glassSignals);
    ZyraDevScenario.instance.resetDashboardLab();
    expect(ZyraColors.appSurfaceStyle, ZyraAppSurfaceStyle.glassSignals);
  });
}
