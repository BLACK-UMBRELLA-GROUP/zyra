import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dashboard_lab_controls.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
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

  testWidgets('Dashboard controls expose a dropdown per contextual category', (
    tester,
  ) async {
    final scenario = ZyraDevScenario.instance;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 286,
              child: ZyraDashboardLabControls(scenario: scenario),
            ),
          ),
        ),
      ),
    );
    final groups = tester
        .widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions))
        .options
        .map((option) => option.group)
        .toSet();
    expect(_categoryDropdowns, findsNWidgets(groups.length));
    for (final group in groups) {
      expect(
        find.byKey(ValueKey('dev_page_options_dropdown_$group')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('dev_page_options_dropdown')),
      findsNothing,
    );
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('Page options'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('APP SURFACE'), findsNothing);
    expect(find.text('DASHBOARD TAB'), findsNothing);
    expect(find.byKey(const ValueKey('dashboard-lab-reset')), findsNothing);
  });

  testWidgets('Dashboard dropdown follows the mounted supportive tab', (
    tester,
  ) async {
    final scenario = ZyraDevScenario.instance;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZyraDashboardLabControls(scenario: scenario),
          ),
        ),
      ),
    );
    expect(
      zyraDashboardOptionsTitle(scenario, ZyraDashboardRole.seeker),
      'Now',
    );
    SupportiveDashboardPreview.instance.selectScenario(
      SupportivePreviewScenario.insightsEmpty,
    );
    await tester.pump();
    expect(
      zyraDashboardOptionsTitle(scenario, ZyraDashboardRole.seeker),
      'Insights',
    );
    expect(
      zyraDashboardPageOptions(scenario, ZyraDashboardRole.seeker),
      hasLength(24),
    );
    final groups = tester
        .widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions))
        .options
        .map((option) => option.group)
        .toSet();
    expect(_categoryDropdowns, findsNWidgets(groups.length));
    for (final group in groups) {
      expect(
        find.byKey(ValueKey('dev_page_options_dropdown_$group')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('dev_page_options_dropdown')),
      findsNothing,
    );
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('APP SURFACE'), findsNothing);
  });

  test('Dashboard reset preserves the locked app-wide surface', () {
    expect(ZyraColors.appSurfaceStyle, ZyraAppSurfaceStyle.glassSignals);
    ZyraDevScenario.instance.resetDashboardLab();
    expect(ZyraColors.appSurfaceStyle, ZyraAppSurfaceStyle.glassSignals);
  });
}
