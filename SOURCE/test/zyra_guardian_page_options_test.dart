import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/models/zyra_dashboard_lab.dart';
import 'package:zyra/screens/wali/wali_gn_shared.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_promotion_engine.dart';
import 'package:zyra/theme/zyra_text.dart';

final _scenario = ZyraDevScenario.instance;
final _promotion = ZyraPromotionEngine.instance;

Future<void> _mount(WidgetTester tester, WaliPage page) async {
  _scenario.setCurrentWaliPage(page);
  final requests = ValueNotifier<int>(0);
  addTearDown(requests.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            WaliDevScenarioPanel(onOpenPage: (_) {}, openRequests: requests),
          ],
        ),
      ),
    ),
  );
  requests.value++;
  await tester.pumpAndSettle();
}

ZyraDevPageOptions _catalog(WidgetTester tester) =>
    tester.widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions));

ZyraDevPageOption _option(WidgetTester tester, String id) =>
    _catalog(tester).options.singleWhere((option) => option.id == id);

Finder get _categoryControls => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('dev_page_options_dropdown_');
});

Future<void> _select(WidgetTester tester, String id) async {
  await _openGroup(tester, _option(tester, id).group);
  final row = find.byKey(ValueKey(id));
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _openGroup(WidgetTester tester, String group) async {
  final dropdown = find.byKey(ValueKey('dev_page_options_dropdown_$group'));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    _scenario.reset();
    _scenario.setDashboardLabEnabled(false);
    _scenario.setDashboardTab(ZyraDashboardTab.now);
    _promotion.resetForAccountChange();
    GNContext.instance.reset();
  });

  tearDown(() {
    _scenario.reset();
    _promotion.resetForAccountChange();
    GNContext.instance.reset();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  for (final page in WaliPage.values) {
    testWidgets(
      '${page.name} Actions separates every category without nested panels',
      (tester) async {
        await _mount(tester, page);
        expect(find.byType(ZyraDevPageOptions), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dev_page_options_dropdown')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(ZyraDevPageOptions),
            matching: find.text('Page options'),
          ),
          findsOneWidget,
        );
        final groups = _catalog(
          tester,
        ).options.map((option) => option.group).toSet();
        for (final group in groups) {
          expect(
            find.byKey(ValueKey('dev_page_options_dropdown_$group')),
            findsOneWidget,
            reason: '${page.name}: $group needs its own control',
          );
        }
        if (page == WaliPage.profile) {
          expect(groups, isEmpty);
          expect(find.text('No page-specific options'), findsOneWidget);
        } else {
          expect(groups, isNotEmpty);
        }
        expect(_categoryControls, findsNWidgets(groups.length));
        expect(find.text('OPEN'), findsNothing);
        expect(find.text('ZYRA DEV · ACTIONS'), findsNothing);
        expect(find.text('Set up first'), findsNothing);
        expect(find.text('Testing alone'), findsNothing);
        expect(
          find.textContaining('Debug and profile builds only'),
          findsNothing,
        );
        expect(find.byType(ExpansionTile), findsNothing);
        final ids = _catalog(
          tester,
        ).options.map((option) => option.id).toList();
        expect(ids.toSet().length, ids.length);
        expect(
          ids.any(
            (id) =>
                id.contains('ward-saved') ||
                id.contains('ward-considered') ||
                id.contains('ward-declined'),
          ),
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'Seekers named values use existing bounded counts and preserve received-invite denial',
    (tester) async {
      await _mount(tester, WaliPage.seekers);
      expect(
        _option(tester, 'guardian-linked-seekers-0').label,
        'No linked Seekers',
      );
      expect(
        _option(tester, 'guardian-linked-seekers-1').label,
        'One linked Seeker',
      );
      expect(
        _option(tester, 'guardian-linked-seekers-10').label,
        'Ten linked Seekers',
      );
      expect(
        _option(tester, 'seeker-code-valid').label,
        contains('ZYRA-DEMO-SEEKER-ADAM'),
      );
      expect(
        _option(tester, 'seeker-code-invalid').label,
        contains('ZYRA-0000-0000-0000-0000-0000'),
      );
      await _select(tester, 'guardian-linked-seekers-3');
      expect(_scenario.waliLinkedSeekers, 3);
      expect(ZyraDevScenario.composeWaliWards().length, 3);
      await _select(tester, 'guardian-sent-invites-2');
      expect(_scenario.waliSentInvites, 2);
      expect(ZyraDevScenario.composeWaliSentInvites().length, 2);
      final unsupported = _option(
        tester,
        'guardian-invitations-received-unavailable',
      );
      expect(unsupported.onSelected, isNull);
      expect(unsupported.unavailableReason, contains('bearer codes'));
      expect(
        _catalog(
          tester,
        ).options.any((option) => option.id.startsWith('guardian-network')),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Additional Guardian denies all Journey preview setters and reveals no Journey rows',
    (tester) async {
      _scenario.setWaliLinkedSeekers(3);
      _scenario.setWaliActiveJourneys(1);
      await _mount(tester, WaliPage.dashboard);
      await _select(tester, 'guardian-role-additional');
      expect(_scenario.waliIsMain, isFalse);
      final denied = _catalog(tester).options.where(
        (option) => [
          'guardian-active-',
          'guardian-paused-',
          'guardian-ended-',
          'guardian-stage-',
          'guardian-review-',
        ].any(option.id.startsWith),
      );
      expect(denied, isNotEmpty);
      for (final option in denied) {
        expect(option.onSelected, isNull, reason: option.id);
        expect(option.unavailableReason, contains('Additional Guardians'));
      }
      final wards = ZyraDevScenario.composeWaliWards();
      expect(wards.every((ward) => !ward.isMain), isTrue);
      expect(ZyraDevScenario.composeWaliJourneys(wards: wards), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Main Journey choices retain slot caps, canonical stages and review prerequisite',
    (tester) async {
      await _mount(tester, WaliPage.dashboard);
      expect(_option(tester, 'guardian-review-waiting').onSelected, isNull);
      await _select(tester, 'guardian-linked-seekers-3');
      await _select(tester, 'guardian-active-2');
      expect(_scenario.waliActiveJourneys, 2);
      expect(
        _catalog(tester).options
            .where((option) => option.id.startsWith('guardian-paused-'))
            .map((option) => option.id),
        ['guardian-paused-0', 'guardian-paused-1'],
      );
      await _select(tester, 'guardian-paused-1');
      await _select(tester, 'guardian-stage-1');
      await _select(tester, 'guardian-review-waiting');
      expect(_scenario.waliStageIndex, 1);
      expect(_scenario.waliReviewWaiting, isTrue);
      expect(
        ZyraDevScenario.composeWaliJourneys(
          wards: ZyraDevScenario.composeWaliWards(),
        ).length,
        3,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Network role, scene and reset operate the existing GNContext without granting production authority',
    (tester) async {
      await _mount(tester, WaliPage.network);
      await _select(tester, 'guardian-network-access-d14Preview');
      await _select(tester, 'guardian-role-additional');
      expect(GNContext.instance.isMainWali, isFalse);
      expect(_scenario.waliRole, WaliRole.additional);
      await _select(tester, 'guardian-network-scene-error');
      expect(GNContext.instance.scene, GNScene.error);
      expect(
        GNContext.instance.networkCardDesign,
        GNNetworkCardDesign.portraitFocus,
      );
      for (final design in GNNetworkCardDesign.values) {
        expect(
          _option(tester, 'guardian-network-card-${design.name}').label,
          design.label,
        );
      }
      for (final layout in GNNetworkActionLayout.values) {
        final option = _option(
          tester,
          'guardian-network-actions-${layout.name}',
        );
        expect(option.group, 'Network Profiles actions');
        expect(option.label, layout.label);
      }
      expect(
        _option(tester, 'guardian-network-actions-current').selected,
        isTrue,
      );
      for (final layout in GNNetworkActionLayout.values) {
        await _select(tester, 'guardian-network-actions-${layout.name}');
        expect(GNContext.instance.networkActionLayout, layout);
        final selectedLayouts = _catalog(tester).options.where(
          (option) =>
              option.group == 'Network Profiles actions' && option.selected,
        );
        expect(selectedLayouts, hasLength(1));
        expect(
          selectedLayouts.single.id,
          'guardian-network-actions-${layout.name}',
        );
        expect(GNContext.instance.scene, GNScene.error);
        expect(GNContext.instance.isMainWali, isFalse);
        expect(
          GNContext.instance.networkCardDesign,
          GNNetworkCardDesign.portraitFocus,
        );
      }
      await _select(tester, 'guardian-network-card-cinematic');
      expect(
        GNContext.instance.networkCardDesign,
        GNNetworkCardDesign.cinematic,
      );
      for (final area in GNNetworkPreviewArea.values) {
        for (var count = 1; count <= 3; count++) {
          expect(
            _option(tester, 'guardian-network-${area.name}-$count').label,
            '$count ${count == 1 ? 'profile' : 'profiles'}',
          );
        }
        await _select(tester, 'guardian-network-${area.name}-3');
        expect(GNContext.instance.previewCountFor(area), 3);
      }
      await _select(tester, 'guardian-network-reset');
      expect(GNContext.instance.scene, GNScene.standard);
      expect(GNContext.instance.isMainWali, isTrue);
      expect(
        GNContext.instance.networkCardDesign,
        GNNetworkCardDesign.portraitFocus,
      );
      expect(
        GNContext.instance.networkActionLayout,
        GNNetworkActionLayout.current,
      );
      for (final area in GNNetworkPreviewArea.values) {
        expect(GNContext.instance.previewCountFor(area), isNull);
      }
      expect(_scenario.waliRole, WaliRole.main);
      await _select(
        tester,
        'guardian-network-access-linkedEntitledUnavailable',
      );
      expect(
        _promotion.developerGuardianNetworkState,
        ZyraDeveloperGuardianNetworkState.linkedEntitledUnavailable,
      );
      expect(
        _option(tester, 'guardian-network-scene-standard').onSelected,
        isNull,
      );
      expect(
        _option(tester, 'guardian-network-scene-standard').unavailableReason,
        contains('D14 full preview'),
      );
      expect(
        _option(tester, 'guardian-network-actions-quietNext').onSelected,
        isNull,
      );
      expect(
        _option(tester, 'guardian-network-actions-quietNext').unavailableReason,
        contains('D14 full preview'),
      );
      expect(
        _option(tester, 'guardian-introductions-sent-unavailable').onSelected,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Guardian Insights excludes Now-only legacy Journey and roster choices',
    (tester) async {
      _scenario.setDashboardTab(ZyraDashboardTab.insights);
      await _mount(tester, WaliPage.dashboard);
      final ids = _catalog(tester).options.map((option) => option.id);
      expect(
        ids.any(
          (id) =>
              id.startsWith('guardian-active-') ||
              id.startsWith('guardian-linked-seekers-') ||
              id.startsWith('guardian-review-'),
        ),
        isFalse,
      );
      expect(
        _option(tester, 'guardian-unread-0').label,
        'Use current unread badge',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Home and second Preview retain their own existing tools', (
    tester,
  ) async {
    await _mount(tester, WaliPage.seekers);
    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Developer controls'), findsOneWidget);
    expect(find.byType(ZyraDevHomeTools), findsOneWidget);
    expect(find.byType(ZyraDevPageOptions), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_preview')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('ZYRA DEV · PREVIEW'), findsNothing);
    expect(find.text('Internal preview'), findsOneWidget);
    expect(find.byType(ZyraDevPreviewLauncher), findsOneWidget);
    expect(find.byType(ZyraDevPageOptions), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a menu opened before a role change cannot restore Main access', (
    tester,
  ) async {
    await _mount(tester, WaliPage.dashboard);
    await _openGroup(tester, _option(tester, 'guardian-role-main').group);
    _scenario.setWaliRole(WaliRole.additional);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsNothing,
    );
    expect(_scenario.waliRole, WaliRole.additional);
    expect(_option(tester, 'guardian-stage-0').onSelected, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Guardian grouped menu opens on narrow large-text screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _mount(tester, WaliPage.network);
    await _openGroup(tester, _option(tester, 'guardian-role-main').group);
    expect(find.text('Guardian role'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ordinary members receive no Guardian developer panel', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [WaliDevScenarioPanel(onOpenPage: (_) {})]),
        ),
      ),
    );
    expect(find.byType(ZyraDevControlRail), findsNothing);
    expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
    expect(find.byType(ZyraDevPageOptions), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
