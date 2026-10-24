import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_intelligence.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_promotion_engine.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_intelligence_card.dart';
import 'package:zyra/widgets/zyra_locked_feature_upgrade.dart';
import 'package:zyra/widgets/zyra_paused_limit_refusal.dart';

class _RouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.plan = ZyraPlan.basic;
  });
  tearDown(() => AppState.instance.plan = ZyraPlan.basic);

  Widget subject(
    VoidCallback Function(BuildContext) action, {
    NavigatorObserver? observer,
  }) => MaterialApp(
    navigatorObservers: [?observer],
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: action(context),
          child: const Text('Open feature'),
        ),
      ),
    ),
  );

  testWidgets('locked feature opens membership information and never grants', (
    tester,
  ) async {
    final observer = _RouteObserver();
    await tester.pumpWidget(
      subject(
        (context) =>
            () => openSeekerLockedFeaturePlan(
              context,
              feature: ZyraPromotionFeature.generalMembership,
            ),
        observer: observer,
      ),
    );
    observer.pushed.clear();
    await tester.tap(find.text('Open feature'));
    await tester.pumpAndSettle();

    expect(find.byType(UpgradeScreen), findsOneWidget);
    expect(find.text('Membership'), findsOneWidget);
    expect(AppState.instance.plan, ZyraPlan.basic);
    expect(observer.pushed, hasLength(1));
    expect(observer.pushed.single, isA<MaterialPageRoute<void>>());

    final back = find.ancestor(
      of: find.text('Back'),
      matching: find.byWidgetPredicate((widget) => widget is TextButton),
    );
    expect(back, findsOneWidget);
    await tester.ensureVisible(back);
    await tester.pumpAndSettle();
    expect(back.hitTestable(), findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('Open feature'), findsOneWidget);
    expect(observer.pushed, hasLength(1));
    expect(AppState.instance.plan, ZyraPlan.basic);
  });

  for (final (plan, limit) in [(ZyraPlan.basic, 1), (ZyraPlan.one, 10)]) {
    testWidgets(
      'paused refusal retains the $limit limit without selling access',
      (tester) async {
        AppState.instance.plan = plan;
        await tester.pumpWidget(
          subject(
            (context) =>
                () => showZyraPausedLimitRefusal(context),
          ),
        );
        await tester.tap(find.text('Open feature'));
        await tester.pumpAndSettle();

        expect(find.text('Paused Journeys are full'), findsOneWidget);
        expect(
          find.textContaining('Your current limit is $limit paused Journeys'),
          findsOneWidget,
        );
        expect(find.textContaining('Resume or end one'), findsOneWidget);
        expect(find.textContaining('Upgrade'), findsNothing);
        expect(find.textContaining('ZYRA Basic'), findsNothing);
        expect(find.textContaining('ZYRA One'), findsNothing);
        expect(find.textContaining('Seeker One'), findsNothing);
        expect(find.textContaining('Guardian One'), findsNothing);
        expect(AppState.instance.plan, plan);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Open feature'), findsOneWidget);
      },
    );
  }

  testWidgets('intelligence invitation stays visible and opens on tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final kind in ZyraIntelligenceKind.values)
                ZyraIntelligenceInvitation(kind: kind, onTap: () => taps++),
            ],
          ),
        ),
      ),
    );
    expect(find.text('ZYRA INSIGHT'), findsOneWidget);
    expect(find.text('ZYRA RECOMMENDATION'), findsOneWidget);
    expect(find.text('ZYRA SUMMARY'), findsOneWidget);
    expect(find.text('View Seeker One'), findsNWidgets(3));

    await tester.tap(find.text('View Seeker One').first);
    expect(taps, 1);
  });
}
