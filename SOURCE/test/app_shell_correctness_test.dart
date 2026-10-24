import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/data/zyra_journey_intelligence.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_journey_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';

void main() {
  test(
    'Guardian shell preserves person-specific Dashboard selection intent',
    () {
      final source = File(
        'lib/screens/wali/wali_home_shell.dart',
      ).readAsStringSync();
      final start = source.indexOf('void _openSeeker(String seekerId)');
      final end = source.indexOf('\n  @override', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final action = source.substring(start, end);
      expect(action, contains('_requestedSeekerId = seekerId;'));
      expect(action, contains('_seekerSelectionRequest++;'));
      expect(
        action,
        contains('_goToPage(WaliPage.seekers, preserveSeekerRequest: true);'),
      );
      expect(source, contains('if (!preserveSeekerRequest &&'));
      expect(source, contains('onOpenSeeker: _openSeeker,'));
      expect(source, contains('requestedSeekerId: _requestedSeekerId,'));
      expect(source, contains('selectionRequest: _seekerSelectionRequest,'));
    },
  );

  testWidgets(
    'OA-ZYRA-212 keeps Scaffolds transparent over the live app layer',
    (tester) async {
      await tester.pumpWidget(const ZyraApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.scaffoldBackgroundColor, Colors.transparent);

      final liveLayers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        liveLayers.any(
          (layer) =>
              layer.duration == const Duration(milliseconds: 260) &&
              layer.decoration is BoxDecoration &&
              (layer.decoration! as BoxDecoration).gradient != null,
        ),
        isTrue,
      );
    },
  );

  testWidgets('ordinary filled actions use the shared modern glass theme', (
    tester,
  ) async {
    await tester.pumpWidget(const ZyraApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final style = app.theme!.filledButtonTheme.style!;

    expect(
      style.backgroundColor!.resolve(<WidgetState>{}),
      ZyraColors.surfaceEmphasisFill,
    );
    expect(
      style.foregroundColor!.resolve(<WidgetState>{}),
      ZyraColors.foreground,
    );
    expect(style.minimumSize!.resolve(<WidgetState>{})!.height, 48);
    expect(style.shape!.resolve(<WidgetState>{}), isA<StadiumBorder>());
  });

  test('OA-ZYRA-220 keeps compatibility on every decided Activity card', () {
    final source = File(
      'lib/screens/connections/connections_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('Cannot be used on passed profiles')));
    expect(
      source,
      isNot(contains('Passed cards expand too, but get no Unlock')),
    );

    final actionStart = source.indexOf(
      '// SHOWN ON EVERY CARD, INCLUDING PASSED',
    );
    final actionEnd = source.indexOf('// COLLAPSE', actionStart);
    expect(actionStart, greaterThanOrEqualTo(0));
    expect(actionEnd, greaterThan(actionStart));

    final compatibilityAction = source.substring(actionStart, actionEnd);
    expect(compatibilityAction, contains("? 'View Compatibility'"));
    expect(compatibilityAction, contains(": 'Compatibility Unlock'"));
    expect(
      compatibilityAction,
      isNot(contains('widget.kind != _ActivityKind.passed')),
    );

    expect(compatibilityAction, contains('_ConnectionsActionDeck('));
    expect(compatibilityAction, contains('..._moveActions()'));

    final moveRowStart = source.indexOf(
      'List<_ConnectionsActionItem> _moveActions()',
    );
    final moveRowEnd = source.indexOf('\n  @override', moveRowStart);
    final moveRow = source.substring(moveRowStart, moveRowEnd);
    expect(moveRow, contains('final moves = switch (widget.kind)'));
    expect(
      moveRow,
      contains('_ActivityKind.considered => const [_Move.save, _Move.pass]'),
    );
    expect(
      moveRow,
      contains('_ActivityKind.saved => const [_Move.consider, _Move.pass]'),
    );
    expect(
      moveRow,
      contains('_ActivityKind.passed => const [_Move.consider, _Move.save]'),
    );
  });

  test('Compatibility Unlock cannot regress to the legacy filled pill', () {
    final source = File(
      'lib/screens/subscription/profile_unlock_screen.dart',
    ).readAsStringSync();
    final sectionStart = source.indexOf('class _Section extends');
    final sectionEnd = source.indexOf('class _OverallLocked', sectionStart);

    expect(sectionStart, greaterThanOrEqualTo(0));
    expect(sectionEnd, greaterThan(sectionStart));

    final section = source.substring(sectionStart, sectionEnd);
    expect(section, contains('ZyraGoldActionPill('));
    expect(section, isNot(contains('FilledButton(')));
    expect(source, contains("buttonLabel: 'Unlock Compatibility'"));
    expect(source, isNot(contains("buttonLabel: 'Unlock Compatibility+'")));
    expect(
      source,
      contains("Text('aligned', style: ZyraText.subtext(size: 13))"),
    );
    expect(
      source,
      isNot(contains("Text('overall', style: ZyraText.subtext(size: 13))")),
    );
  });

  test('Compatibility detail is honest-empty and cannot spend Plus', () {
    final source = File(
      'lib/screens/subscription/profile_unlock_screen.dart',
    ).readAsStringSync();
    final service = File(
      'lib/services/zyra_unlock_service.dart',
    ).readAsStringSync();
    final sectionStart = source.indexOf('class _Section extends');
    final sectionEnd = source.indexOf('class _OverallLocked', sectionStart);
    expect(sectionStart, greaterThanOrEqualTo(0));
    expect(sectionEnd, greaterThan(sectionStart));
    final section = source.substring(sectionStart, sectionEnd);

    final unlockStart = source.indexOf('Future<void> _unlock() async {');
    final unlockEnd = source.indexOf(
      '/// Recover a lost acknowledgement',
      unlockStart,
    );
    expect(unlockStart, greaterThanOrEqualTo(0));
    expect(unlockEnd, greaterThan(unlockStart));
    final unlock = source.substring(unlockStart, unlockEnd);

    expect(source, contains('class _ExactTrioBreakdown'));
    expect(source, isNot(contains('class _ThreePartRailBreakdown')));
    expect(source, isNot(contains('class _Sample')));
    expect(source, contains("'Detailed compatibility isn’t available yet.'"));
    expect(service, contains('categoryBreakdownAvailable = false;'));
    expect(service, contains('if (!isTierAvailable(tier))'));
    expect(service, contains('return UnlockOutcome.unavailable;'));
    expect(service, contains('static const currentTier = UnlockTier.plus;'));
    expect(unlock, contains('const tier = ZyraUnlockService.currentTier;'));
    expect(unlock, contains('!(_route?.isCurrent ?? false)'));
    expect(unlock, contains('!ZyraUnlockService.isTierAvailable(tier)'));
    expect(unlock, isNot(contains('UnlockTier.standard')));
    expect(source, isNot(contains('_tierToSpend')));
    expect(source, isNot(contains('onUnlock: () => _unlock(UnlockTier.plus)')));
    expect(source, isNot(contains('aligned: 74')));
    expect(source, isNot(contains('discuss: 18')));
    expect(source, isNot(contains('opposed: 8')));
    expect(source, contains("heading('Aligned')"));
    expect(source, contains("heading('Discuss')"));
    expect(source, contains("heading('Opposed')"));
    expect(source, isNot(contains("label: 'Green'")));
    expect(source, isNot(contains("label: 'Amber'")));
    expect(source, isNot(contains("label: 'Red'")));
    expect(section, isNot(contains("Text('Unlocked'")));
    expect(section, isNot(contains('Icons.lock_open_outlined')));

    expect(source, isNot(contains('class _SampleMarker')));
    expect(source, isNot(contains('This breakdown is an example')));
  });

  test('Journey Reveal exposes only a real caller-owned overall score', () {
    final service = File(
      'lib/services/zyra_journey_service.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/screens/journey/journey_flow_screen.dart',
    ).readAsStringSync();
    final intelligence = File(
      'lib/data/zyra_journey_intelligence.dart',
    ).readAsStringSync();

    expect(service, contains("'zyra_journey_compatibility_state'"));
    expect(service, contains("'zyra_reveal_journey_compatibility'"));
    expect(service, isNot(contains(".from('journey_compatibility')")));
    expect(service, isNot(contains("'score_candidates'")));
    expect(
      service,
      isNot(contains('seeker_a_categories, seeker_b_categories')),
    );
    expect(service, isNot(contains("'Deen': score")));
    expect(service, isNot(contains('myCatsColumn')));
    expect(screen, contains("'Detailed compatibility isn’t available yet.'"));
    expect(screen, isNot(contains('class _CompatibilitySectionRow')));
    expect(screen, isNot(contains('categoryScores')));
    expect(intelligence, isNot(contains('Your strongest alignment')));
    expect(intelligence, isNot(contains('than most pairs')));
    expect(intelligence, isNot(contains('strong marriages')));
  });

  test('Journey compatibility RPC mapping is caller-relative', () {
    final rpcRow = <String, dynamic>{
      'mine_revealed': true,
      'counterpart_revealed': false,
      'my_score': 72,
      // These keys are deliberately ignored even if a malformed mock adds
      // them. The real RPC row type does not expose them.
      'counterpart_score': 91,
      'seeker_a_categories': {'Deen': 72},
      'seeker_b_categories': {'Deen': 91},
    };
    expect(ZyraJourneyService.compatibilityResultFromRpcRow(rpcRow), (
      mine: true,
      theirs: false,
      overallScore: 72.0,
    ));
    expect(
      ZyraJourneyService.compatibilityResultFromRpcRow({
        'mine_revealed': false,
        'counterpart_revealed': true,
        'my_score': null,
      }),
      (mine: false, theirs: true, overallScore: null),
    );
  });

  test('OA-ZYRA-283 migration closes direct compatibility-table access', () {
    final migration = File(
      'supabase/migrations/'
      '20260910184252_oa283_journey_compatibility_rpc_boundary.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains('public.zyra_journey_compatibility_state(\n  p_match_id uuid'),
    );
    expect(
      migration,
      contains('public.zyra_reveal_journey_compatibility(\n  p_match_id uuid'),
    );
    expect(migration, contains("set search_path = ''"));
    expect(migration, contains('v_caller uuid := (select auth.uid())'));
    expect(
      migration,
      contains('revoke all privileges on table public.journey_compatibility'),
    );
    expect(
      migration,
      contains('drop policy if exists journey_compatibility_read'),
    );
    expect(
      migration,
      contains('drop policy if exists journey_compatibility_insert'),
    );
    expect(
      migration,
      contains('drop policy if exists journey_compatibility_update'),
    );
    expect(migration, contains("v_match.status is distinct from 'active'"));
    expect(
      migration,
      contains("v_match.journey_stage is distinct from 'compatibility_reveal'"),
    );
    expect(migration, contains('compatibility_attempt_mismatch'));
    expect(migration, isNot(contains('p_other_id')));
    expect(migration, isNot(contains('p_score')));
    expect(migration, isNot(contains('p_revealed')));
  });

  test('Journey score insight is score-only and makes no invented claims', () {
    expect(
      ZyraJourneyIntelligence.compatibility(plan: ZyraPlan.basic, score: 78),
      isNull,
    );

    final insight = ZyraJourneyIntelligence.compatibility(
      plan: ZyraPlan.one,
      score: 45,
    );
    expect(insight, isNotNull);
    expect(
      insight!.body,
      'Your score points to more differences to explore. It is a starting '
      'point, not a verdict.',
    );
    expect(insight.body, isNot(contains('strongest')));
    expect(insight.body, isNot(contains('weakest')));
    expect(insight.body, isNot(contains('than most pairs')));
    expect(insight.body, isNot(contains('strong marriages')));
  });

  test(
    'Connections shares one action deck and does not repeat Introductions',
    () {
      final source = File(
        'lib/screens/connections/connections_screen.dart',
      ).readAsStringSync();

      expect(
        RegExp(r'_ConnectionsActionDeck\(').allMatches(source),
        hasLength(4),
      );

      final introductionsStart = source.indexOf(
        'List<Widget> _introductionsChildren()',
      );
      final introductionsEnd = source.indexOf(
        'List<Widget> _activityChildren',
        introductionsStart,
      );
      final introductions = source.substring(
        introductionsStart,
        introductionsEnd,
      );
      expect(introductions, isNot(contains("'INTRODUCTIONS")));
      expect(introductions, isNot(contains('_ConnectionsSectionHeading(')));
    },
  );

  test('Browse swipe feedback keeps Full aura plus ten 3D treatments', () {
    final source = File(
      'lib/screens/browse/browse_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('class _SwipeFeedbackLayer');
    final end = source.indexOf('class _BorderFlash', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final feedback = source.substring(start, end);
    for (final style in [
      'fullAura',
      'layeredParallax',
      'edgePeek',
      'floatingDeck',
      'carousel3d',
      'doorHinge',
      'pageCurl',
      'depthTunnel',
      'subjectSplit',
      'magneticTilt',
      'horizonLift',
    ]) {
      expect(feedback, contains('ZyraBrowseSwipeFeedbackStyle.$style'));
    }
    expect(feedback, isNot(contains('Text(')));
    expect(feedback, isNot(contains('Icons.thumb')));
    expect(source, contains('ZyraBrowseSwipePolicy.previewDecision'));
    expect(source, contains('ZyraBrowseSwipePolicy.committedDecision'));
    expect(source, contains('ZyraBrowseSwipePolicy.flingTarget'));
    expect(source, contains('ZyraBrowseSwipePolicy.cueEdge'));
    expect(source, contains('Matrix4 _photoSwipeTransform'));
    expect(source, contains('Matrix4 _nextProfileSwipeTransform'));
    expect(source, contains('Widget _buildNextProfilePreview'));
  });

  test('developer page options use the approved shared grouped dropdown', () {
    final source = File(
      'lib/dev/dev_scenario_panel_v2.dart',
    ).readAsStringSync();
    final shared = File(
      'lib/dev/zyra_dev_page_options.dart',
    ).readAsStringSync();
    expect(source, contains('ZyraDevPageOptions('));
    expect(source, isNot(contains('class _ToolDropdownState<T>')));
    expect(source, isNot(contains('DropdownButton')));
    expect(source, isNot(contains('DropdownMenuItem')));
    expect(shared, contains('class ZyraDevPageOptions extends StatefulWidget'));
    expect(shared, isNot(contains('DropdownButton<String>(')));
    expect(shared, isNot(contains('DropdownMenuItem<String>(')));
    expect(shared, contains("'Page options'"));
    expect(shared, contains(r'dev_page_options_dropdown_$group'));
    expect(shared, contains(r'dev_page_options_group_${entry.key}'));
    expect(shared, contains('dev_page_options_inline_menu'));
    expect(shared, isNot(contains("ValueKey('dev_page_options_dropdown')")));
    expect(shared, isNot(contains('previousGroup != option.group')));
  });

  test('Seeker pages and nav items keep the Founder-approved order', () {
    final source = File('lib/screens/home/home_shell.dart').readAsStringSync();
    final pagesStart = source.indexOf('final pages = [');
    final pagesEnd = source.indexOf('return Scaffold(', pagesStart);
    final navStart = source.indexOf("label: 'Profiles'");
    expect(pagesStart, greaterThanOrEqualTo(0));
    expect(pagesEnd, greaterThan(pagesStart));
    expect(navStart, greaterThanOrEqualTo(0));
    final pages = source.substring(pagesStart, pagesEnd);
    final navItems = source.substring(navStart);

    void expectInOrder(String text, List<String> tokens) {
      var cursor = -1;
      for (final token in tokens) {
        final next = text.indexOf(token, cursor + 1);
        expect(next, greaterThan(cursor), reason: '$token is out of order');
        cursor = next;
      }
    }

    expectInOrder(pages, const [
      'BrowseScreen(',
      'ConnectionsScreen(',
      'SeekerDashboardScreen(',
      'SeekerWaliTab()',
      'ProfileScreen()',
    ]);
    expectInOrder(navItems, const [
      "label: 'Profiles'",
      "label: 'Connections'",
      "label: 'My ZYRA'",
      "label: 'Guardian'",
      "label: 'Profile'",
    ]);
    expect(navItems, isNot(contains("label: 'Notifications'")));
    expect(source, isNot(contains('NotificationsScreen(')));
  });

  test('Guardian nav makes Dashboard the notification centre', () {
    final source = File(
      'lib/screens/wali/wali_home_shell.dart',
    ).readAsStringSync();
    expect(source, contains("label: 'Dashboard'"));
    expect(source, isNot(contains("label: 'My ZYRA'")));
    expect(source, isNot(contains("label: 'Notifications'")));
    expect(source, isNot(contains('NotificationsScreen(')));
  });
}
