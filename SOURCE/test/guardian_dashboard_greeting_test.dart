import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/models/zyra_dashboard_lab.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/screens/wali/wali_dashboard_screen.dart';
import 'package:zyra/services/zyra_dashboard_updates_service.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_journey_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_scrollable_seeker_selector.dart';
import 'package:zyra/widgets/zyra_guardian_dashboard_profile_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    ZyraText.useTestFontStubs = true;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'widget-test-key',
    );
  });

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance
      ..resetDashboardLab()
      ..setUseLiveGuardianData(false)
      ..setWardSaved(0)
      ..setWardConsidered(0)
      ..setWardDeclined(0);
    AppState.instance.waliName = 'Amina';
    AppState.instance.name = null;
    AppState.instance.setWaliRealLinkedSeekers(const []);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.resetDashboardLab();
    AppState.instance.waliName = null;
    AppState.instance.name = null;
    AppState.instance.setWaliRealLinkedSeekers(const []);
  });

  tearDownAll(() => ZyraText.useTestFontStubs = false);

  Widget subject({
    Key? key,
    bool plus = false,
    VoidCallback? onOpenNetwork,
    VoidCallback? onOpenSeekers,
    ValueChanged<String>? onOpenSeeker,
    Future<List<SeekerProfile>> Function(List<String>)? loadProfiles,
    Future<List<WaliJourneyView>?> Function()? loadJourneys,
    Future<ZyraDashboardUpdatesPage?> Function()? loadUpdates,
    Future<ZyraSourceResult<Set<String>>> Function(List<String>)?
    loadOpenReviews,
  }) => MaterialApp(
    home: WaliDashboardScreen(
      key: key,
      hasGuardianPlus: plus,
      onOpenNetwork: onOpenNetwork,
      onOpenSeekers: onOpenSeekers,
      onOpenSeeker: onOpenSeeker,
      loadProfiles: loadProfiles ?? (_) async => [],
      loadJourneys: loadJourneys ?? () async => [],
      loadUpdates:
          loadUpdates ??
          () async => ZyraDashboardUpdatesPage(rows: [], nextCursor: null),
      loadOpenReviews:
          loadOpenReviews ??
          (_) async => const ZyraSourceResult.available(<String>{}),
    ),
  );

  ZyraDashboardUpdate update({
    String sourceId = 'source-1',
    String titleKey = 'dashboard_updates.journey.timeline_milestone.title',
    String detailKey =
        'dashboard_updates.journey.timeline_milestone.journey_started.detail',
    String destinationKey = 'connections.journeys',
    String? relatedMatchId = 'match-1',
    bool? isUnread,
  }) => ZyraDashboardUpdate(
    occurredAt: DateTime.utc(2026, 8, 30, 10),
    classKey: 'journey_timeline_milestone',
    sourceId: sourceId,
    titleKey: titleKey,
    detailKey: detailKey,
    destinationKey: destinationKey,
    relatedMatchId: relatedMatchId,
    isUnread: isUnread,
  );

  const journey = WaliJourneyView(
    matchId: 'match-1',
    linkedSeekerId: 'seeker-1',
    linkedSeekerName: 'Maryam',
    partner: SeekerProfile(
      id: 'partner-1',
      firstName: 'Adam',
      age: 31,
      city: '—',
      photos: [],
      gender: 'male',
    ),
    counterpartGuardianName: null,
    counterpartGuardianSurname: null,
    status: 'ended',
    journeyStage: 'phase_1',
  );

  testWidgets('ten Seekers slide continuously and select only on release', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.setWaliLinkedSeekers(10);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final selector = find.byKey(
      const ValueKey('guardian-dashboard-seeker-selector'),
    );
    ZyraScrollableSeekerSelector navigation() =>
        tester.widget<ZyraScrollableSeekerSelector>(selector);
    Finder cell(int index) => find.byKey(navigation().segmentKeys[index]);
    final originalRect = tester.getRect(selector);
    expect(navigation().labels.take(3), ['Aaliyah', 'Umar', 'Sumayyah']);
    expect(navigation().labels, hasLength(10));
    final originalSecondCell = tester.getRect(cell(1));
    final innerRect = originalRect.deflate(3);
    for (final index in [9, 0, 1]) {
      final rect = tester.getRect(cell(index));
      expect(rect.left, greaterThanOrEqualTo(innerRect.left - 0.1));
      expect(rect.right, lessThanOrEqualTo(innerRect.right + 0.1));
    }
    final pager = tester
        .widget<PageView>(
          find.byKey(const ValueKey('guardian-dashboard-pages')),
        )
        .controller!;
    final origin = pager.page!;
    expect(origin, 1000000);
    expect(navigation().position, 0);
    final gesture = await tester.startGesture(tester.getCenter(selector));
    await gesture.moveBy(const Offset(-25, 0));
    await gesture.moveBy(Offset(-originalRect.width * 0.42, 0));
    await tester.pump();
    final draggingSecondCell = tester.getRect(cell(1));
    expect(
      draggingSecondCell.left,
      lessThan(originalSecondCell.left),
      reason: 'Names must move with the drag, not remain in a frozen group.',
    );
    expect(
      pager.page,
      origin,
      reason: 'The page changes only after releasing the selector.',
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pager.page, greaterThan(origin));
    expect(tester.getRect(selector), originalRect);
    for (var index = 0; index < 6; index++) {
      await tester.drag(selector, Offset(-originalRect.width * 0.85, 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(selector), originalRect);
    }
    expect(
      pager.page,
      greaterThan(origin + 9),
      reason: 'The name strip must keep moving past the last Seeker.',
    );
    final selected = navigation().position.round();
    for (final index in [
      (selected - 1) % 10,
      selected % 10,
      (selected + 1) % 10,
    ]) {
      final rect = tester.getRect(cell(index));
      expect(rect.left, greaterThanOrEqualTo(innerRect.left - 0.1));
      expect(rect.right, lessThanOrEqualTo(innerRect.right + 0.1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seeker name taps and Dashboard swipes stay synchronized', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.setWaliLinkedSeekers(10);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final selector = find.byKey(
      const ValueKey('guardian-dashboard-seeker-selector'),
    );
    ZyraScrollableSeekerSelector navigation() =>
        tester.widget<ZyraScrollableSeekerSelector>(selector);
    final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
    final pager = tester.widget<PageView>(pages).controller!;
    final origin = pager.page!;
    await tester.tap(find.byKey(navigation().segmentKeys[1]));
    await tester.pumpAndSettle();
    expect(pager.page, origin + 1);
    expect(navigation().position, 1);
    await tester.tap(find.byKey(navigation().segmentKeys[2]));
    await tester.pumpAndSettle();
    expect(pager.page, origin + 2);
    expect(navigation().position, 2);
    await tester.drag(pages, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(pager.page, closeTo(origin + 3, .001));
    expect(navigation().position, 3);
    await tester.tap(find.byKey(navigation().segmentKeys[4]));
    await tester.pumpAndSettle();
    expect(pager.page, origin + 4);
    expect(navigation().position, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seeker navigation reanchors safely when the roster changes', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final scenario = ZyraDevScenario.instance..setWaliLinkedSeekers(10);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final selector = find.byKey(
      const ValueKey('guardian-dashboard-seeker-selector'),
    );
    final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
    final pager = tester.widget<PageView>(pages).controller!;
    pager.jumpToPage(pager.page!.round() + 9);
    await tester.pumpAndSettle();
    expect(tester.widget<ZyraScrollableSeekerSelector>(selector).position, 9);
    for (final count in [2, 1]) {
      scenario.setWaliLinkedSeekers(count);
      await tester.pumpAndSettle();
      final navigation = tester.widget<ZyraScrollableSeekerSelector>(selector);
      expect(navigation.labels, hasLength(count));
      expect(navigation.position, inInclusiveRange(0, count - 1));
      expect(
        tester.widget<PageView>(pages).controller!.page,
        inInclusiveRange(0, count - 1),
      );
      expect(
        tester.widget<PageView>(pages).childrenDelegate.estimatedChildCount,
        count,
      );
      expect(tester.takeException(), isNull);
    }
    scenario.setWaliLinkedSeekers(0);
    await tester.pumpAndSettle();
    expect(selector, findsNothing);
    expect(pages, findsNothing);
    scenario.setWaliLinkedSeekers(10);
    await tester.pumpAndSettle();
    final navigation = tester.widget<ZyraScrollableSeekerSelector>(selector);
    expect(navigation.labels, hasLength(10));
    expect(navigation.position, 0);
    expect(tester.widget<PageView>(pages).controller!.page, 1000000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('body swipe takes over an unfinished Seeker tap animation', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.setWaliLinkedSeekers(10);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final selector = find.byKey(
      const ValueKey('guardian-dashboard-seeker-selector'),
    );
    final navigation = tester.widget<ZyraScrollableSeekerSelector>(selector);
    final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
    final pager = tester.widget<PageView>(pages).controller!;
    final origin = pager.page!;
    await tester.tap(find.byKey(navigation.segmentKeys[1]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.drag(pages, const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(pager.page, lessThan(origin + 1));
    final settled = pager.page!.round();
    expect(pager.page, closeTo(settled, .001));
    final highlight = tester.getRect(
      find.byKey(const ValueKey('seeker-selector-highlight')),
    );
    final selected = tester.getRect(
      find.byKey(navigation.segmentKeys[(settled - origin.round()) % 10]),
    );
    expect(highlight.left, closeTo(selected.left, .1));
    expect(highlight.right, closeTo(selected.right, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('looping body and header preserve each Seeker across both seams', (
    tester,
  ) async {
    final people = [
      for (var index = 0; index < 4; index++)
        WaliLinkedPerson(
          id: 'loop-$index',
          firstName: 'Seeker $index',
          isMain: true,
        ),
    ];
    final journeys = [
      for (var index = 0; index < people.length; index++)
        WaliJourneyView(
          matchId: 'loop-match-$index',
          linkedSeekerId: people[index].id,
          linkedSeekerName: people[index].firstName,
          partner: SeekerProfile(
            id: 'loop-partner-$index',
            firstName: 'Partner $index',
            age: 30,
            city: '—',
            photos: const [],
            gender: 'male',
          ),
          counterpartGuardianName: null,
          counterpartGuardianSurname: null,
          status: 'active',
          journeyStage: 'family_review',
        ),
    ];
    AppState.instance.setWaliRealLinkedSeekers(people);
    await tester.pumpWidget(
      subject(
        plus: true,
        loadJourneys: () async => journeys,
        loadOpenReviews: (_) async => ZyraSourceResult.available({
          for (final journey in journeys) journey.matchId,
        }),
      ),
    );
    await tester.pumpAndSettle();
    final selector = find.byKey(
      const ValueKey('guardian-dashboard-seeker-selector'),
    );
    final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
    final pager = tester.widget<PageView>(pages).controller!;
    final origin = pager.page!.round();
    expect(origin, people.length * 100000);
    expect(
      tester.widget<PageView>(pages).childrenDelegate.estimatedChildCount,
      isNull,
    );

    ZyraScrollableSeekerSelector navigation() =>
        tester.widget<ZyraScrollableSeekerSelector>(selector);

    void expectOwnedPages() {
      for (final person in people) {
        final page = find.byKey(
          PageStorageKey('guardian-dashboard-${person.id}'),
        );
        if (page.evaluate().isEmpty) continue;
        expect(
          find.descendant(
            of: page,
            matching: find.text('${person.firstName} needs your Family Review'),
          ),
          findsOneWidget,
        );
        for (final other in people.where((other) => other.id != person.id)) {
          expect(
            find.descendant(
              of: page,
              matching: find.text(
                '${other.firstName} needs your Family Review',
              ),
            ),
            findsNothing,
            reason:
                'A transitional page must never borrow another Seeker’s data.',
          );
        }
      }
    }

    void expectSelected(int logical) {
      expect(pager.page, closeTo(origin + logical, .001));
      expect(navigation().position, closeTo(logical.toDouble(), .001));
      final selectedIndex = logical % people.length;
      final current = find.byKey(navigation().segmentKeys[selectedIndex]);
      final selectedRect = tester.getRect(current);
      final innerRect = tester.getRect(selector).deflate(3);
      expect(selectedRect.center.dx, closeTo(innerRect.center.dx, .1));
      for (final offset in [-1, 0, 1]) {
        final index = (selectedIndex + offset) % people.length;
        final rect = tester.getRect(
          find.byKey(navigation().segmentKeys[index]),
        );
        expect(rect.left, greaterThanOrEqualTo(innerRect.left - .1));
        expect(rect.right, lessThanOrEqualTo(innerRect.right + .1));
      }
      expectOwnedPages();
      expect(
        find
            .text('${people[selectedIndex].firstName} needs your Family Review')
            .hitTestable(),
        findsOneWidget,
      );
    }

    var logical = 0;
    expectSelected(logical);
    for (final direction in [1, -1]) {
      for (var step = 0; step < 9; step++) {
        await tester.drag(pages, Offset(-600 * direction.toDouble(), 0));
        await tester.pump(const Duration(milliseconds: 40));
        expectOwnedPages();
        await tester.pumpAndSettle();
        logical += direction;
        expectSelected(logical);
      }
    }
    for (final direction in [-1, 1]) {
      for (var step = 0; step < 9; step++) {
        final neighbour = (logical + direction) % people.length;
        await tester.tap(find.byKey(navigation().segmentKeys[neighbour]));
        await tester.pump(const Duration(milliseconds: 80));
        expectOwnedPages();
        await tester.pumpAndSettle();
        logical += direction;
        expectSelected(logical);
      }
    }
    expect(logical, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one to three Seeker dashboards remain finite', (tester) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final scenario = ZyraDevScenario.instance;
    final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
    final selector = find.byKey(
      const ValueKey('guardian-dashboard-seeker-selector'),
    );
    for (final count in [1, 2, 3]) {
      scenario.setWaliLinkedSeekers(count);
      await tester.pumpWidget(subject(key: ValueKey('finite-$count')));
      await tester.pumpAndSettle();
      final pageView = tester.widget<PageView>(pages);
      final pager = pageView.controller!;
      expect(pager.page, 0);
      expect(pageView.childrenDelegate.estimatedChildCount, count);
      pager.jumpToPage(count - 1);
      await tester.pumpAndSettle();
      await tester.drag(pages, const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(pager.page, closeTo((count - 1).toDouble(), .001));
      expect(
        tester.widget<ZyraScrollableSeekerSelector>(selector).position,
        count - 1,
      );
      pager.jumpToPage(0);
      await tester.pumpAndSettle();
      await tester.drag(pages, const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(pager.page, closeTo(0, .001));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('idle carousel rebasing keeps the same Seeker after 100 laps', (
    tester,
  ) async {
    final people = [
      for (var index = 0; index < 4; index++)
        WaliLinkedPerson(
          id: 'rebase-$index',
          firstName: 'Person $index',
          isMain: true,
        ),
    ];
    AppState.instance.setWaliRealLinkedSeekers(people);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
    final selector = find.byKey(
      const ValueKey('guardian-dashboard-seeker-selector'),
    );
    final pager = tester.widget<PageView>(pages).controller!;
    final origin = pager.page!.round();
    final motion = pager.animateToPage(
      origin + 402,
      duration: const Duration(milliseconds: 40),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    await motion;
    expect(pager.page, closeTo(origin + 2, .001));
    final navigation = tester.widget<ZyraScrollableSeekerSelector>(selector);
    expect(navigation.position, 2);
    expect(
      find
          .byKey(const PageStorageKey('guardian-dashboard-rebase-2'))
          .hitTestable(),
      findsOneWidget,
    );
    final innerRect = tester.getRect(selector).deflate(3);
    for (final index in [1, 2, 3]) {
      final rect = tester.getRect(find.byKey(navigation.segmentKeys[index]));
      expect(rect.left, greaterThanOrEqualTo(innerRect.left - .1));
      expect(rect.right, lessThanOrEqualTo(innerRect.right + .1));
      if (index == 2) {
        expect(rect.center.dx, closeTo(innerRect.center.dx, .1));
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('loop accessibility describes actual people, not virtual pages', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      AppState.instance.setWaliRealLinkedSeekers([
        for (var index = 0; index < 4; index++)
          WaliLinkedPerson(
            id: 'semantic-$index',
            firstName: 'Person $index',
            isMain: true,
          ),
      ]);
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
      final pager = tester.widget<PageView>(pages).controller!;
      final origin = pager.page!.round();
      expect(
        find.bySemanticsLabel(RegExp(r'^Person 0, Seeker 1 of 4(?:\n|$)')),
        findsOneWidget,
      );
      pager.jumpToPage(origin - 1);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(r'^Person 3, Seeker 4 of 4(?:\n|$)')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Seeker [1-9][0-9]{3,} of')),
        findsNothing,
      );
      expect(
        (tester.widget<PageView>(pages).childrenDelegate
                as SliverChildBuilderDelegate)
            .addSemanticIndexes,
        isFalse,
      );
      expect(
        find.descendant(
          of: pages,
          matching: find.byWidgetPredicate(
            (widget) => widget is IndexedSemantics && widget.index >= 1000,
          ),
        ),
        findsNothing,
        reason: 'Virtual lap indices must not become accessibility ordinals.',
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'loop roster changes preserve selected identity before clamping',
    (tester) async {
      final people = [
        for (var index = 0; index < 4; index++)
          WaliLinkedPerson(
            id: 'roster-$index',
            firstName: 'Person $index',
            isMain: true,
          ),
      ];
      AppState.instance.setWaliRealLinkedSeekers(people);
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
      final selector = find.byKey(
        const ValueKey('guardian-dashboard-seeker-selector'),
      );
      final originalPager = tester.widget<PageView>(pages).controller!;
      originalPager.jumpToPage(originalPager.page!.round() + 6);
      await tester.pumpAndSettle();
      AppState.instance.setWaliRealLinkedSeekers([
        people[3],
        people[2],
        people[0],
        people[1],
      ]);
      await tester.pumpAndSettle();
      final replacementPager = tester.widget<PageView>(pages).controller!;
      expect(replacementPager, isNot(same(originalPager)));
      var navigation = tester.widget<ZyraScrollableSeekerSelector>(selector);
      expect(navigation.labels[navigation.position.round() % 4], 'Person 2');
      expect(navigation.position, 1);
      expect(replacementPager.page, 400001);
      AppState.instance.setWaliRealLinkedSeekers([people[0]]);
      await tester.pumpAndSettle();
      navigation = tester.widget<ZyraScrollableSeekerSelector>(selector);
      expect(navigation.labels, ['Person 0']);
      expect(navigation.position, 0);
      expect(tester.widget<PageView>(pages).controller!.page, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Guardian Dashboard greets the signed-in Guardian by name', (
    tester,
  ) async {
    await tester.pumpWidget(subject());

    expect(find.text('Guardian Dashboard'), findsOneWidget);
    expect(find.text('Assalamu alaikum, Amina.'), findsOneWidget);
    expect(find.text('Now'), findsNothing);
    expect(find.text('Insights'), findsNothing);
    expect(find.text('Seekers'), findsNothing);
    expect(
      find.byKey(const ValueKey('guardian-dashboard-fade-empty')),
      findsOneWidget,
    );
  });

  testWidgets('Guardian Today is a compact summary, not a roster', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.setDashboardGuardianTodayState(
      ZyraGuardianDashboardTodayState.oneSeeker,
    );

    await tester.pumpWidget(subject(onOpenSeekers: () {}));
    await tester.pump();

    expect(find.text('Aaliyah'), findsWidgets);
    expect(find.text('View profile'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardian-dashboard-seeker-selector')),
      findsOneWidget,
    );
    expect(find.text('YOUR SEEKERS'), findsNothing);
    expect(find.text('TO DO'), findsNothing);
    expect(find.text('Active'), findsNothing);
    expect(find.text('Paused'), findsNothing);
    expect(find.text('Ended'), findsNothing);
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Considering'), findsNothing);
    expect(find.text('Declined'), findsNothing);
  });

  testWidgets('Guardian Today renders exactly one priority and safe counts', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final scenario = ZyraDevScenario.instance
      ..setDashboardGuardianTodayState(
        ZyraGuardianDashboardTodayState.multipleSeekers,
      )
      ..setWaliActiveJourneys(2)
      ..setWaliReviewWaiting(true);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('Aaliyah needs your Family Review'), findsOneWidget);
    expect(find.text('Umar needs your Family Review'), findsNothing);
    expect(find.text('Aaliyah'), findsWidgets);
    expect(find.text('Umar'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardian-dashboard-right-now')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-dashboard-todo-list')),
      findsNothing,
    );
    expect(find.text('YOUR SEEKERS'), findsNothing);
    expect(scenario.waliReviewWaiting, isTrue);
  });

  testWidgets('Guardian dev tab previews remain Seeker-labelled and safe', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final scenario = ZyraDevScenario.instance
      ..setDashboardGuardianTodayState(
        ZyraGuardianDashboardTodayState.oneSeeker,
      )
      ..setDashboardUpdatesState(ZyraDashboardUpdatesState.several);

    await tester.pumpWidget(subject());
    await tester.pump();
    scenario.setDashboardTab(ZyraDashboardTab.now);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gn-preview-controls')), findsNothing);
    final syntheticUpdate = find.byKey(const ValueKey('guardian-dev-update-0'));
    expect(syntheticUpdate, findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.descendant(
              of: syntheticUpdate,
              matching: find.byType(InkWell),
            ),
          )
          .onTap,
      isNull,
      reason: 'Synthetic updates have no real Journey destination',
    );
    expect(
      find.textContaining('Aaliyah — Journey moved forward'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Aaliyah — Family Review completed'),
      findsOneWidget,
    );

    scenario
      ..setDashboardGuardianInsightsState(
        ZyraGuardianDashboardInsightsState.familyProcess,
      )
      ..setDashboardGuardianPremium(true)
      ..setDashboardTab(ZyraDashboardTab.insights);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('guardian-dev-insight')), findsOneWidget);
    expect(find.textContaining('private Seeker judgement'), findsOneWidget);
  });

  testWidgets('Guardian Updates distinguishes failed from successful empty', (
    tester,
  ) async {
    await tester.pumpWidget(subject(loadUpdates: () async => null));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('guardian-dashboard-empty')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Guardian updates could not be refreshed'),
      findsOneWidget,
    );
    expect(find.text('No Guardian updates yet'), findsNothing);

    await tester.pumpWidget(subject(key: const ValueKey('successful-empty')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('guardian-dashboard-empty')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('No Guardian updates yet'), findsOneWidget);
  });

  testWidgets('failed first Journey read never claims linked family is calm', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    AppState.instance.setWaliRealLinkedSeekers(const [
      WaliLinkedPerson(id: 'seeker-1', firstName: 'Maryam', isMain: true),
    ]);

    await tester.pumpWidget(subject(loadJourneys: () async => null));
    await tester.pumpAndSettle();

    expect(
      find.text('Your Guardian priorities could not be refreshed'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-dashboard-seeker-snapshot-seeker-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-dashboard-right-now')),
      findsOneWidget,
    );
    expect(find.text('PRIORITIES UNAVAILABLE'), findsOneWidget);
    expect(find.text('JOURNEY STATUS UNAVAILABLE'), findsNothing);
    expect(find.text('Nothing needs you right now'), findsNothing);
    expect(find.textContaining('Nothing needs you'), findsNothing);
  });

  testWidgets('failed review read never claims linked family is calm', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    AppState.instance.setWaliRealLinkedSeekers(const [
      WaliLinkedPerson(id: 'seeker-1', firstName: 'Maryam', isMain: true),
    ]);
    const activeJourney = WaliJourneyView(
      matchId: 'match-1',
      linkedSeekerId: 'seeker-1',
      linkedSeekerName: 'Maryam',
      partner: SeekerProfile(
        id: 'partner-1',
        firstName: 'Adam',
        age: 31,
        city: '—',
        photos: [],
        gender: 'male',
      ),
      counterpartGuardianName: null,
      counterpartGuardianSurname: null,
      status: 'active',
      journeyStage: 'family_review',
    );

    await tester.pumpWidget(
      subject(
        loadJourneys: () async => const [activeJourney],
        loadOpenReviews: (_) async =>
            const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your Guardian priorities could not be refreshed'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-dashboard-seeker-snapshot-seeker-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-dashboard-right-now')),
      findsOneWidget,
    );
    expect(find.text('PRIORITIES UNAVAILABLE'), findsOneWidget);
    expect(find.text('JOURNEY STATUS UNAVAILABLE'), findsNothing);
    expect(find.textContaining('Nothing needs you'), findsNothing);
  });

  testWidgets('Guardian Updates resolves Seeker context by related match', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    AppState.instance.setWaliRealLinkedSeekers(const [
      WaliLinkedPerson(id: 'seeker-1', firstName: 'Maryam', isMain: true),
    ]);
    await tester.pumpWidget(
      subject(
        loadJourneys: () async => [journey],
        loadUpdates: () async =>
            ZyraDashboardUpdatesPage(rows: [update()], nextCursor: null),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('guardian-dashboard-seeker-1')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Maryam · Journey milestone'), findsOneWidget);
    expect(find.textContaining('Adam · Journey milestone'), findsNothing);
  });

  testWidgets('Guardian failed refresh visibly keeps last-known rows', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      subject(
        loadUpdates: () async => calls++ == 0
            ? ZyraDashboardUpdatesPage(rows: [update()], nextCursor: null)
            : null,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('guardian-dashboard-empty')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pumpAndSettle();
    await refresh;

    expect(
      find.text("Couldn't refresh Updates — showing last-known rows."),
      findsOneWidget,
    );
    expect(find.textContaining('Journey milestone'), findsOneWidget);
    expect(find.text('No Guardian updates yet'), findsNothing);
  });

  testWidgets('Guardian newer refresh cannot be overwritten by older failure', (
    tester,
  ) async {
    final older = Completer<ZyraDashboardUpdatesPage?>();
    final newer = Completer<ZyraDashboardUpdatesPage?>();
    var calls = 0;
    await tester.pumpWidget(
      subject(loadUpdates: () => calls++ == 0 ? older.future : newer.future),
    );
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(calls, 2);

    newer.complete(
      ZyraDashboardUpdatesPage(rows: [update()], nextCursor: null),
    );
    await tester.pumpAndSettle();
    await refresh;
    older.complete(null);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('guardian-dashboard-empty')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Journey milestone'), findsOneWidget);
    expect(
      find.text("Couldn't refresh Updates — showing last-known rows."),
      findsNothing,
    );
  });

  testWidgets('Guardian pending dashboard read respects account revocation', (
    tester,
  ) async {
    final pending = Completer<ZyraDashboardUpdatesPage?>();
    await tester.pumpWidget(subject(loadUpdates: () => pending.future));
    ZyraAccountState.resetForTesting();
    pending.complete(
      ZyraDashboardUpdatesPage(rows: [update()], nextCursor: null),
    );
    await tester.pump();
    expect(find.textContaining('Journey milestone'), findsNothing);
  });

  testWidgets('Guardian NULL unread has no read affordance', (tester) async {
    final nullUnread = update();
    final unread = update(
      sourceId: 'notification-1',
      titleKey: 'dashboard_updates.notification.new_message.title',
      detailKey: 'dashboard_updates.notification.new_message.detail',
      destinationKey: 'notifications',
      relatedMatchId: null,
      isUnread: true,
    );
    await tester.pumpWidget(
      subject(
        loadUpdates: () async => ZyraDashboardUpdatesPage(
          rows: [unread, nullUnread],
          nextCursor: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('guardian-dashboard-empty')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-update-unread-New message')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-update-unread-Journey milestone')),
      findsNothing,
    );
  });

  testWidgets('Guardian Insights stays honest-empty and independent', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(plus: true, loadJourneys: () async => null),
    );
    await tester.pump();
    expect(find.text('No Guardian insights available yet'), findsOneWidget);
    expect(
      find.text(
        'ZYRA will only show a Guardian insight when real, governed family-process evidence supports it.',
      ),
      findsOneWidget,
    );
    expect(find.text("Couldn't load your dashboard"), findsNothing);
  });

  testWidgets(
    'unentitled Guardian Insights stays visible with a lock and upgrade route',
    (tester) async {
      var networkOpens = 0;
      await tester.pumpWidget(subject(onOpenNetwork: () => networkOpens++));
      await tester.pumpAndSettle();
      expect(
        find.text('Guardian Insights are part of Guardian One'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('segmented-Insights-lock')),
        findsNothing,
      );
      expect(networkOpens, 0);
      expect(
        find.byKey(const ValueKey('guardian-insights-locked')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guardian-insights-upgrade')),
        findsOneWidget,
      );
      expect(find.text('No Guardian insights available yet'), findsNothing);

      final upgrade = find.byKey(const ValueKey('guardian-insights-upgrade'));
      await tester.drag(
        find.byKey(const PageStorageKey('guardian-dashboard-empty')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(upgrade);
      await tester.tap(upgrade);
      await tester.pumpAndSettle();
      expect(find.byType(UpgradeScreen), findsOneWidget);
      expect(find.text('Membership'), findsOneWidget);
    },
  );

  testWidgets('View profile opens a read-only profile, not a Seeker workflow', (
    tester,
  ) async {
    const profile = SeekerProfile(
      id: 'linked-profile-id',
      firstName: 'Maryam',
      age: 27,
      city: 'Leeds, UK',
      photos: [],
      gender: 'female',
    );
    AppState.instance.setWaliRealLinkedSeekers(const [
      WaliLinkedPerson(
        id: 'linked-profile-id',
        firstName: 'Maryam',
        isMain: true,
        relationship: 'father',
      ),
    ]);
    var genericOpens = 0;
    final specificOpens = <String>[];
    final requestedIds = <List<String>>[];
    await tester.pumpWidget(
      subject(
        onOpenSeekers: () => genericOpens++,
        onOpenSeeker: specificOpens.add,
        loadProfiles: (ids) async {
          requestedIds.add(List.of(ids));
          return [profile];
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Available with Guardian+'), findsNothing);
    expect(find.text('Guardian+ access is active'), findsNothing);
    expect(find.text('Open Network'), findsNothing);
    final action = find.byKey(
      const ValueKey('guardian-dashboard-view-profile-linked-profile-id'),
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    final viewer = tester.widget<SeekerProfileScreen>(
      find.byType(SeekerProfileScreen),
    );
    expect(requestedIds, [
      ['linked-profile-id'],
    ]);
    expect(viewer.profile, same(profile));
    expect(viewer.actionBar, isNull);
    expect(find.text('Like'), findsNothing);
    expect(find.text('Pass'), findsNothing);
    expect(genericOpens, 0);
    expect(specificOpens, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a linked Seeker without photos keeps their details and opens their own profile',
    (tester) async {
      const id = 'linked-seeker-without-photo';
      const profile = SeekerProfile(
        id: id,
        firstName: 'Aaliyah',
        age: 29,
        city: 'Leeds, UK',
        photos: [],
        gender: 'female',
      );
      AppState.instance.setWaliRealLinkedSeekers(const [
        WaliLinkedPerson(
          id: id,
          firstName: 'Aaliyah',
          relationship: 'father',
          isMain: true,
        ),
      ]);
      final requestedIds = <List<String>>[];
      await tester.pumpWidget(
        subject(
          loadProfiles: (ids) async {
            requestedIds.add(List.of(ids));
            return [profile];
          },
        ),
      );
      await tester.pumpAndSettle();

      final avatar = find.byKey(
        const ValueKey('guardian-dashboard-profile-avatar-$id'),
      );
      expect(requestedIds, [
        [id],
      ]);
      expect(
        find.descendant(of: avatar, matching: find.text('A')),
        findsOneWidget,
      );
      expect(find.text('Father · Main Guardian'), findsOneWidget);
      expect(find.text('29 years · Leeds, UK'), findsOneWidget);
      final action = find.byKey(
        const ValueKey('guardian-dashboard-view-profile-$id'),
      );
      expect(tester.widget<TextButton>(action).onPressed, isNotNull);

      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      final viewer = tester.widget<SeekerProfileScreen>(
        find.byType(SeekerProfileScreen),
      );
      expect(viewer.profile, same(profile));
      expect(viewer.emptyPhoto, isNotNull);
      expect(viewer.actionBar, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('View profile opens the selected ID even when two names match', (
    tester,
  ) async {
    const firstId = 'duplicate-name-first-id';
    const secondId = 'duplicate-name-second-id';
    const firstProfile = SeekerProfile(
      id: firstId,
      firstName: 'Maryam',
      age: 26,
      city: 'Leeds, UK',
      photos: [],
      gender: 'female',
    );
    const secondProfile = SeekerProfile(
      id: secondId,
      firstName: 'Maryam',
      age: 31,
      city: 'Bristol, UK',
      photos: [],
      gender: 'female',
    );
    AppState.instance.setWaliRealLinkedSeekers(const [
      WaliLinkedPerson(id: firstId, firstName: 'Maryam', isMain: true),
      WaliLinkedPerson(id: secondId, firstName: 'Maryam', isMain: true),
    ]);
    final opened = <String>[];
    var genericOpens = 0;
    await tester.pumpWidget(
      subject(
        onOpenSeekers: () => genericOpens++,
        onOpenSeeker: opened.add,
        loadProfiles: (_) async => [secondProfile, firstProfile],
      ),
    );
    await tester.pumpAndSettle();
    final selector = find.byKey(
      const ValueKey('guardian-dashboard-seeker-selector'),
    );
    final navigation = tester.widget<ZyraScrollableSeekerSelector>(selector);
    expect(navigation.labels, ['Maryam', 'Maryam']);
    await tester.tap(find.byKey(navigation.segmentKeys[1]));
    await tester.pumpAndSettle();
    final pages = find.byKey(const ValueKey('guardian-dashboard-pages'));
    expect(tester.widget<PageView>(pages).controller!.page, 1);
    final secondAction = find.byKey(
      const ValueKey('guardian-dashboard-view-profile-$secondId'),
    );
    await tester.ensureVisible(secondAction);
    await tester.pumpAndSettle();
    await tester.tap(secondAction);
    await tester.pumpAndSettle();
    var viewer = tester.widget<SeekerProfileScreen>(
      find.byType(SeekerProfileScreen),
    );
    expect(viewer.profile, same(secondProfile));
    expect(viewer.actionBar, isNull);
    expect(opened, isEmpty);
    expect(genericOpens, 0);

    // Fixture: current SeekerProfileScreen hides its X when swipeDownToDismiss
    // is enabled. Exercise the actual shared left-edge return gesture.
    final edge = tester.getRect(
      find.byKey(const ValueKey('zyra_back_swipe_edge')),
    );
    await tester.timedDragFrom(
      Offset(edge.left + 8, edge.center.dy),
      const Offset(240, 0),
      const Duration(milliseconds: 450),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(navigation.segmentKeys[0]));
    await tester.pumpAndSettle();
    final firstAction = find.byKey(
      const ValueKey('guardian-dashboard-view-profile-$firstId'),
    );
    await tester.ensureVisible(firstAction);
    await tester.pumpAndSettle();
    await tester.tap(firstAction);
    await tester.pumpAndSettle();
    viewer = tester.widget<SeekerProfileScreen>(
      find.byType(SeekerProfileScreen),
    );
    expect(viewer.profile, same(firstProfile));
    expect(viewer.actionBar, isNull);
    expect(opened, isEmpty);
    expect(genericOpens, 0);
    expect(tester.takeException(), isNull);
  });

  for (final isMain in [true, false]) {
    testWidgets(
      '${isMain ? 'Main' : 'Additional'} Guardian identity card follows the name pills and precedes Right now',
      (tester) async {
        const id = 'real-linked-card-id';
        const profile = SeekerProfile(
          id: id,
          firstName: 'Maryam',
          surnameLine: 'Authorised surname',
          age: 27,
          city: 'Leeds, UK',
          photos: [],
          gender: 'female',
        );
        AppState.instance.setWaliRealLinkedSeekers([
          WaliLinkedPerson(
            id: id,
            firstName: 'Maryam',
            isMain: isMain,
            relationship: 'father',
          ),
        ]);
        await tester.pumpWidget(subject(loadProfiles: (_) async => [profile]));
        await tester.pumpAndSettle();

        final selector = find.byKey(
          const ValueKey('guardian-dashboard-seeker-selector'),
        );
        final card = find.byKey(
          const ValueKey('guardian-dashboard-seeker-snapshot-$id'),
        );
        final avatar = find.byKey(
          const ValueKey('guardian-dashboard-profile-avatar-$id'),
        );
        final rightNow = find.byKey(
          const ValueKey('guardian-dashboard-right-now'),
        );
        expect(find.byType(GuardianDashboardProfileCard), findsOneWidget);
        expect(
          find.descendant(of: selector, matching: find.text('Maryam')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('Maryam')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.text(
              'Father · ${isMain ? 'Main Guardian' : 'Additional Guardian'}',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('27 years · Leeds, UK'), findsOneWidget);
        expect(find.text('Authorised surname'), findsNothing);
        expect(find.text('SEEKER'), findsNothing);
        expect(
          tester.getRect(selector).bottom,
          lessThan(tester.getRect(card).top),
        );
        expect(
          tester.getRect(card).bottom,
          lessThan(tester.getRect(rightNow).top),
        );
        expect(tester.getSize(avatar), const Size(62, 62));
        expect(
          (tester.widget<Container>(avatar).decoration! as BoxDecoration).shape,
          BoxShape.circle,
        );
        expect(
          find.descendant(of: avatar, matching: find.byType(ClipOval)),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextButton>(
                find.byKey(
                  const ValueKey('guardian-dashboard-view-profile-$id'),
                ),
              )
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'loading profile details keeps the identity card neutral and disabled',
    (tester) async {
      const id = 'loading-linked-profile-id';
      final profiles = Completer<List<SeekerProfile>>();
      AppState.instance.setWaliRealLinkedSeekers(const [
        WaliLinkedPerson(id: id, firstName: 'Maryam', relationship: 'father'),
      ]);
      await tester.pumpWidget(subject(loadProfiles: (_) => profiles.future));
      await tester.pump();
      final action = find.byKey(
        const ValueKey('guardian-dashboard-view-profile-$id'),
      );
      expect(find.text('Loading profile details…'), findsOneWidget);
      expect(tester.widget<TextButton>(action).onPressed, isNull);
      expect(find.byType(SeekerProfileScreen), findsNothing);

      profiles.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('Loading profile details…'), findsNothing);
      expect(
        find.text('Age unavailable · Location unavailable'),
        findsOneWidget,
      );
      expect(tester.widget<TextButton>(action).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing real profile never borrows another member or demo details',
    (tester) async {
      const id = 'real-linked-missing-profile';
      const unrelatedProfile = SeekerProfile(
        id: 'foreign-profile-id',
        firstName: 'Someone else',
        age: 42,
        city: 'Foreign city',
        photos: [],
        gender: 'female',
      );
      AppState.instance.setWaliRealLinkedSeekers(const [
        WaliLinkedPerson(id: id, firstName: 'Maryam'),
      ]);
      var genericOpens = 0;
      final specificOpens = <String>[];
      await tester.pumpWidget(
        subject(
          onOpenSeekers: () => genericOpens++,
          onOpenSeeker: specificOpens.add,
          loadProfiles: (_) async => [unrelatedProfile],
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(
        const ValueKey('guardian-dashboard-view-profile-$id'),
      );
      expect(
        find.text('Age unavailable · Location unavailable'),
        findsOneWidget,
      );
      expect(
        find.text('Relationship not recorded · Additional Guardian'),
        findsOneWidget,
      );
      expect(find.text('Someone else'), findsNothing);
      expect(find.textContaining('Foreign city'), findsNothing);
      expect(tester.widget<TextButton>(action).onPressed, isNull);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(genericOpens, 0);
      expect(specificOpens, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late profile result from a previous roster cannot replace the current person',
    (tester) async {
      const firstId = 'previous-linked-id';
      const secondId = 'current-linked-id';
      const firstProfile = SeekerProfile(
        id: firstId,
        firstName: 'Maryam',
        age: 25,
        city: 'Leeds, UK',
        photos: [],
        gender: 'female',
      );
      const secondProfile = SeekerProfile(
        id: secondId,
        firstName: 'Aaliyah',
        age: 29,
        city: 'Bristol, UK',
        photos: [],
        gender: 'female',
      );
      final firstResult = Completer<List<SeekerProfile>>();
      final secondResult = Completer<List<SeekerProfile>>();
      final requestedIds = <List<String>>[];
      AppState.instance.setWaliRealLinkedSeekers(const [
        WaliLinkedPerson(id: firstId, firstName: 'Maryam'),
      ]);
      await tester.pumpWidget(
        subject(
          loadProfiles: (ids) {
            requestedIds.add(List.of(ids));
            return ids.single == firstId
                ? firstResult.future
                : secondResult.future;
          },
        ),
      );
      await tester.pump();
      expect(requestedIds, [
        [firstId],
      ]);
      expect(find.text('Loading profile details…'), findsOneWidget);

      AppState.instance.setWaliRealLinkedSeekers(const [
        WaliLinkedPerson(id: secondId, firstName: 'Aaliyah'),
      ]);
      await tester.pump();
      expect(requestedIds, [
        [firstId],
        [secondId],
      ]);
      expect(
        find.byKey(
          const ValueKey('guardian-dashboard-seeker-snapshot-$secondId'),
        ),
        findsOneWidget,
      );
      firstResult.complete(const [firstProfile]);
      await tester.pump();
      expect(find.text('Loading profile details…'), findsOneWidget);
      expect(find.textContaining('Leeds, UK'), findsNothing);

      secondResult.complete(const [secondProfile]);
      await tester.pumpAndSettle();
      expect(find.text('29 years · Bristol, UK'), findsOneWidget);
      expect(find.textContaining('Leeds, UK'), findsNothing);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(
                const ValueKey('guardian-dashboard-view-profile-$secondId'),
              ),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('plural View Seekers keeps the generic family handoff', (
    tester,
  ) async {
    final specificOpens = <String>[];
    var genericOpens = 0;
    await tester.pumpWidget(
      subject(
        onOpenSeekers: () => genericOpens++,
        onOpenSeeker: specificOpens.add,
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(
      const ValueKey('guardian-dashboard-view-seekers'),
    );
    expect(action, findsOneWidget);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(genericOpens, 1);
    expect(specificOpens, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seeker name pills keep each combined Dashboard page isolated', (
    tester,
  ) async {
    AppState.instance.setWaliRealLinkedSeekers(const [
      WaliLinkedPerson(id: 'aaliyah', firstName: 'Aaliyah', isMain: true),
      WaliLinkedPerson(id: 'umar', firstName: 'Umar', isMain: true),
    ]);
    const aaliyahJourney = WaliJourneyView(
      matchId: 'match-aaliyah',
      linkedSeekerId: 'aaliyah',
      linkedSeekerName: 'Aaliyah',
      partner: SeekerProfile(
        id: 'partner-a',
        firstName: 'Adam',
        age: 30,
        city: '—',
        photos: [],
        gender: 'male',
      ),
      counterpartGuardianName: null,
      counterpartGuardianSurname: null,
      status: 'active',
      journeyStage: 'family_review',
    );
    const umarJourney = WaliJourneyView(
      matchId: 'match-umar',
      linkedSeekerId: 'umar',
      linkedSeekerName: 'Umar',
      partner: SeekerProfile(
        id: 'partner-u',
        firstName: 'Maryam',
        age: 29,
        city: '—',
        photos: [],
        gender: 'female',
      ),
      counterpartGuardianName: null,
      counterpartGuardianSurname: null,
      status: 'active',
      journeyStage: 'family_review',
    );

    await tester.pumpWidget(
      subject(
        plus: true,
        loadJourneys: () async => const [aaliyahJourney, umarJourney],
        loadOpenReviews: (_) async =>
            const ZyraSourceResult.available({'match-aaliyah', 'match-umar'}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aaliyah needs your Family Review'), findsOneWidget);
    expect(find.text('Umar needs your Family Review'), findsNothing);
    expect(
      find.byKey(const ValueKey('guardian-dashboard-insights-aaliyah')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('guardian-dashboard-seeker-umar')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aaliyah needs your Family Review'), findsNothing);
    expect(find.text('Umar needs your Family Review'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardian-dashboard-insights-umar')),
      findsOneWidget,
    );
  });

  testWidgets('Additional-owned Journey cannot change Today copy or counts', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance
      ..setDashboardLabEnabled(false)
      ..setWaliRole(WaliRole.main)
      ..setWaliLinkedSeekers(2)
      ..setWaliActiveJourneys(1);
    AppState.instance.setWaliRealLinkedSeekers(const [
      WaliLinkedPerson(id: 'main', firstName: 'Main Seeker', isMain: true),
      WaliLinkedPerson(id: 'additional', firstName: 'Additional Seeker'),
    ]);
    const hidden = WaliJourneyView(
      matchId: 'hidden-match',
      linkedSeekerId: 'additional',
      linkedSeekerName: 'Additional Seeker',
      partner: SeekerProfile(
        id: 'hidden-partner',
        firstName: 'Hidden Partner',
        age: 30,
        city: '—',
        photos: [],
        gender: '',
      ),
      counterpartGuardianName: null,
      counterpartGuardianSurname: null,
      status: 'active',
      journeyStage: 'wali_gate',
      isMock: true,
    );

    await tester.pumpWidget(subject(loadJourneys: () async => [hidden]));
    await tester.pump();

    expect(find.text('Nothing needs you right now'), findsOneWidget);
    expect(find.text('Main Seeker'), findsWidgets);
    expect(find.text('Additional Seeker'), findsOneWidget);
    expect(find.textContaining('2 linked Seekers'), findsNothing);
    expect(find.textContaining('Hidden Partner'), findsNothing);
    expect(find.textContaining('Guardian step'), findsNothing);
  });
}
