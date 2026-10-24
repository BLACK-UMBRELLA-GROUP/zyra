import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/wali/wali_seekers_screen.dart';
import 'package:zyra/services/zyra_guardian_seeker_roster_resolver.dart';
import 'package:zyra/services/zyra_wali_journey_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

void main() {
  testWidgets('screen retains requested ID while its initial roster loads', (
    tester,
  ) async {
    final links = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
    await tester.pumpWidget(
      _app(
        WaliSeekersScreen(
          requestedSeekerId: 'target',
          selectionRequest: 1,
          loadLinks: () => links.future,
          loadContext: (_) async =>
              const ZyraSourceResult.available(GuardianSeekerRosterContext()),
          loadProfiles: (_) async => const <SeekerProfile>[],
        ),
      ),
    );
    expect(_rosterPages, findsNothing);
    links.complete(
      ZyraSourceResult.available([
        _person('first', 'Aaliyah', isMain: false),
        _person('second', 'Maryam', isMain: false),
        _person('target', 'Zaynab', isMain: false),
      ]),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 2);
    expect(find.text('Zaynab').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requested Seeker opens by identity after resolver ordering', (
    tester,
  ) async {
    final target = _person('additional-sam', 'Sam', isMain: false);
    final duplicate = _person('main-sam', 'Sam');
    final priority = _person('priority-zara', 'Zara');
    final people = [target, duplicate, priority];
    final context = GuardianSeekerRosterContext(journeys: [_journey(priority)]);
    await tester.pumpWidget(
      _rosterSubject(people, requestedSeekerId: target.id, context: context),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 2);
    expect(_visibleOwner(target.id), findsOneWidget);
    expect(_visibleOwner(duplicate.id), findsNothing);
    expect(_visibleOwner(priority.id), findsNothing);
  });

  testWidgets('same Seeker request with a new revision reopens cached roster', (
    tester,
  ) async {
    final people = [
      _person('a', 'Aaliyah'),
      _person('b', 'Maryam'),
      _person('c', 'Zaynab'),
    ];
    await tester.pumpWidget(
      _rosterSubject(people, requestedSeekerId: 'c', selectionRequest: 1),
    );
    await tester.pumpAndSettle();
    expect(_visibleOwner('c'), findsOneWidget);
    await tester.drag(_rosterPages, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(_visibleOwner('b'), findsOneWidget);
    await tester.pumpWidget(
      _rosterSubject(people, requestedSeekerId: 'c', selectionRequest: 2),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 2);
    expect(_visibleOwner('c'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unrelated roster rebuild does not override a manual swipe', (
    tester,
  ) async {
    final people = [_person('a', 'Aaliyah'), _person('b', 'Maryam')];
    await tester.pumpWidget(
      _rosterSubject(people, requestedSeekerId: 'b', selectionRequest: 1),
    );
    await tester.pumpAndSettle();
    await tester.drag(_rosterPages, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(_visibleOwner('a'), findsOneWidget);
    await tester.pumpWidget(
      _rosterSubject(
        people,
        requestedSeekerId: 'b',
        selectionRequest: 1,
        lastKnown: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 0);
    expect(_visibleOwner('a'), findsOneWidget);
    expect(_visibleOwner('b'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending requested Seeker opens when the roster arrives later', (
    tester,
  ) async {
    final available = [_person('a', 'Aaliyah'), _person('b', 'Maryam')];
    final target = _person('late', 'Zaynab', isMain: false);
    await tester.pumpWidget(
      _rosterSubject(
        available,
        requestedSeekerId: target.id,
        selectionRequest: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_missingSeekerNotice), findsOneWidget);
    await tester.drag(_rosterPages, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(_visibleOwner('b'), findsOneWidget);
    await tester.pumpWidget(
      _rosterSubject(
        [...available, target],
        requestedSeekerId: target.id,
        selectionRequest: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 2);
    expect(_visibleOwner(target.id), findsOneWidget);
    expect(find.text(_missingSeekerNotice), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing requested identity is reported without a false match', (
    tester,
  ) async {
    await tester.pumpWidget(
      _rosterSubject(
        [_person('a', 'Same name'), _person('b', 'Same name', isMain: false)],
        requestedSeekerId: 'not-linked',
        selectionRequest: 3,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_missingSeekerNotice), findsOneWidget);
    expect(_visibleOwner('not-linked'), findsNothing);
    expect(_visibleOwner('a'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('generic navigation cancels a missing pending Seeker request', (
    tester,
  ) async {
    final available = [_person('a', 'Aaliyah'), _person('b', 'Maryam')];
    final target = _person('late', 'Zaynab', isMain: false);
    await tester.pumpWidget(
      _rosterSubject(
        available,
        requestedSeekerId: target.id,
        selectionRequest: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_missingSeekerNotice), findsOneWidget);
    await tester.drag(_rosterPages, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(_visibleOwner('b'), findsOneWidget);
    await tester.pumpWidget(
      _rosterSubject(available, requestedSeekerId: null, selectionRequest: 2),
    );
    await tester.pumpAndSettle();
    expect(find.text(_missingSeekerNotice), findsNothing);
    await tester.pumpWidget(
      _rosterSubject(
        [...available, target],
        requestedSeekerId: null,
        selectionRequest: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 1);
    expect(_visibleOwner('b'), findsOneWidget);
    expect(_visibleOwner(target.id), findsNothing);
    expect(find.text(_missingSeekerNotice), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final replacement in [null, 'not-linked']) {
    testWidgets(
      'queued valid request cannot outlive replacement ${replacement ?? 'clear'}',
      (tester) async {
        final people = [_person('a', 'Aaliyah'), _person('b', 'Maryam')];
        await tester.pumpWidget(_rosterSubject(people));
        await tester.pumpAndSettle();
        expect(_visibleOwner('a'), findsOneWidget);

        // Two real widget updates occur before the frame commits queued jumps.
        // This exercises cancellation through didUpdateWidget rather than
        // invoking the private pager state or its callbacks directly.
        tester.binding.attachRootWidget(
          tester.binding.wrapWithDefaultView(
            _rosterSubject(people, requestedSeekerId: 'b', selectionRequest: 1),
          ),
        );
        tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
        tester.binding.attachRootWidget(
          tester.binding.wrapWithDefaultView(
            _rosterSubject(
              people,
              requestedSeekerId: replacement,
              selectionRequest: 2,
            ),
          ),
        );
        tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
        await tester.pumpAndSettle();
        expect(_rosterPager(tester).page, 0);
        expect(_visibleOwner('a'), findsOneWidget);
        expect(_visibleOwner('b'), findsNothing);
        expect(
          find.text(_missingSeekerNotice),
          replacement == null ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('queued target removal cannot jump beyond the current roster', (
    tester,
  ) async {
    final people = [
      _person('a', 'Aaliyah'),
      _person('b', 'Maryam'),
      _person('c', 'Zaynab'),
    ];
    await tester.pumpWidget(_rosterSubject(people));
    await tester.pumpAndSettle();
    expect(_visibleOwner('a'), findsOneWidget);
    tester.binding.attachRootWidget(
      tester.binding.wrapWithDefaultView(
        _rosterSubject(people, requestedSeekerId: 'c', selectionRequest: 1),
      ),
    );
    tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
    tester.binding.attachRootWidget(
      tester.binding.wrapWithDefaultView(
        _rosterSubject(
          people.take(2).toList(),
          requestedSeekerId: 'c',
          selectionRequest: 1,
        ),
      ),
    );
    tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 0);
    expect(_visibleOwner('a'), findsOneWidget);
    expect(_visibleOwner('b'), findsNothing);
    expect(_visibleOwner('c'), findsNothing);
    expect(find.text(_missingSeekerNotice), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('roster reorder keeps identity and removal clamps safely', (
    tester,
  ) async {
    final first = _person('a', 'Aaliyah');
    final target = _person('b', 'Maryam');
    final last = _person('c', 'Zaynab');
    await tester.pumpWidget(
      _rosterSubject(
        [first, target, last],
        requestedSeekerId: target.id,
        selectionRequest: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 1);
    await tester.pumpWidget(
      _rosterSubject(
        [last, target, first],
        context: GuardianSeekerRosterContext(journeys: [_journey(target)]),
        requestedSeekerId: target.id,
        selectionRequest: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 0);
    expect(_visibleOwner(target.id), findsOneWidget);
    await tester.pumpWidget(
      _rosterSubject([last], requestedSeekerId: target.id, selectionRequest: 1),
    );
    await tester.pumpAndSettle();
    expect(_rosterPager(tester).page, 0);
    expect(_visibleOwner(last.id), findsOneWidget);
    expect(find.text(_missingSeekerNotice), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typed link failure never paints the invite empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        WaliSeekersScreen(
          loadLinks: () async => const ZyraSourceResult.unavailable(
            ZyraSourceFailure.requestFailed,
          ),
          loadProfiles: (_) async => const <SeekerProfile>[],
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('guardian-seeker-add-top')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('guardian-seekers-empty')), findsNothing);
    expect(find.textContaining("Something didn't quite work"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('successful empty renders the invite state', (tester) async {
    await tester.pumpWidget(
      _app(
        WaliSeekersScreen(
          loadLinks: () async =>
              const ZyraSourceResult.available(<WaliLinkedPerson>[]),
          loadProfiles: (_) async => const <SeekerProfile>[],
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('guardian-seeker-add-top')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-seekers-empty')),
      findsOneWidget,
    );
    expect(find.text('Add a Seeker'), findsOneWidget);
    expect(find.textContaining("Something didn't quite work"), findsNothing);
  });

  testWidgets(
    'Developer zero-Seeker preview keeps the matching Add a Seeker state',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      addTearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

      await tester.pumpWidget(
        _app(
          WaliSeekersScreen(
            loadLinks: () async => const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            ),
            loadProfiles: (_) async => const <SeekerProfile>[],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Seekers'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('guardian-seeker-add-top')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guardian-seekers-empty')),
        findsOneWidget,
      );
      expect(find.text('Add a Seeker'), findsOneWidget);
      expect(find.textContaining("Something didn't quite work"), findsNothing);
      expect(find.text('Try again'), findsNothing);
    },
  );

  testWidgets('Additional-only roster uses authorised Journey context', (
    tester,
  ) async {
    var contextReads = 0;
    final additional = _person('additional', 'Aaliyah', isMain: false);
    await tester.pumpWidget(
      _app(
        WaliSeekersScreen(
          loadLinks: () async => ZyraSourceResult.available([additional]),
          loadContext: (_) async {
            contextReads++;
            return ZyraSourceResult.available(
              GuardianSeekerRosterContext(journeys: [_journey(additional)]),
            );
          },
          loadProfiles: (_) async => const <SeekerProfile>[],
        ),
      ),
    );
    await tester.pump();

    expect(contextReads, 1);
    expect(
      find.byKey(const ValueKey('guardian-seeker-page-view')),
      findsOneWidget,
    );
    expect(find.text('Aaliyah'), findsOneWidget);
    expect(find.text('Additional Guardian'), findsOneWidget);
    expect(find.textContaining('Journey with Idris'), findsOneWidget);
  });

  testWidgets('Main context failure is unavailable, not OTHER SEEKERS', (
    tester,
  ) async {
    final main = _person('main', 'Maryam');
    await tester.pumpWidget(
      _app(
        WaliSeekersScreen(
          loadLinks: () async => ZyraSourceResult.available([main]),
          loadContext: (_) async => const ZyraSourceResult.unavailable(
            ZyraSourceFailure.requestFailed,
          ),
          loadProfiles: (_) async => const <SeekerProfile>[],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('OTHER SEEKERS'), findsNothing);
    expect(find.text('No current Journey'), findsNothing);
    expect(find.textContaining("Something didn't quite work"), findsOneWidget);
  });

  testWidgets('failed refresh retains and labels last-confirmed roster', (
    tester,
  ) async {
    final originalRevision = ZyraWaliLinkService.linkRevision.value;
    addTearDown(
      () => ZyraWaliLinkService.linkRevision.value = originalRevision,
    );
    var fail = false;
    final additional = _person('additional', 'Aaliyah', isMain: false);
    await tester.pumpWidget(
      _app(
        WaliSeekersScreen(
          loadLinks: () async => fail
              ? const ZyraSourceResult.unavailable(
                  ZyraSourceFailure.requestFailed,
                )
              : ZyraSourceResult.available([additional]),
          loadContext: (_) async =>
              const ZyraSourceResult.available(GuardianSeekerRosterContext()),
          loadProfiles: (_) async => const <SeekerProfile>[],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Aaliyah'), findsOneWidget);

    fail = true;
    ZyraWaliLinkService.linkRevision.value++;
    await tester.pump();
    await tester.pump();

    expect(find.text('Aaliyah'), findsOneWidget);
    expect(
      find.text(
        'The roster could not refresh. Showing last confirmed information.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Seekers are full pages with swipe-only navigation', (
    tester,
  ) async {
    final main = _person('main', 'Maryam');
    final additional = _person('additional', 'Aaliyah', isMain: false);
    final resolution = const ZyraGuardianSeekerRosterResolver().resolve(
      linkedPeople: [main, additional],
      context: const GuardianSeekerRosterContext(),
    );
    final opened = <String>[];
    var invited = false;
    await tester.pumpWidget(
      _app(
        GuardianSeekerRosterView(
          resolution: resolution,
          onRetry: () {},
          onInvite: () => invited = true,
          onOpenSeeker: (entry) => opened.add(entry.person.id),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('guardian-seeker-page-view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-roster-main-main')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('guardian-roster-additional-additional')),
      findsNothing,
    );
    expect(opened, isEmpty);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('guardian-seeker-page-dot-0')))
          .width,
      26,
    );

    await tester.drag(
      find.byKey(const ValueKey('guardian-seeker-page-view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('guardian-seeker-page-dot-1')))
          .width,
      26,
    );
    expect(opened, isEmpty);
    expect(find.text('Invite another Seeker'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('guardian-seeker-add-top')));
    expect(invited, isTrue);
  });

  testWidgets('Additional developer workspace previews Journey context', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));
    final additional = _person('dev-ws0', 'Aaliyah', isMain: false);
    await tester.pumpWidget(
      _app(
        WaliSeekersScreen(
          hasGuardianOne: true,
          onOpenNetwork: () {},
          loadLinks: () async => ZyraSourceResult.available([additional]),
          loadContext: (_) async =>
              const ZyraSourceResult.available(GuardianSeekerRosterContext()),
          loadProfiles: (_) async => const <SeekerProfile>[],
        ),
      ),
    );
    await tester.pump();

    await tester.pumpAndSettle();

    expect(find.text('JOURNEY SUMMARY'), findsOneWidget);
    expect(find.text('Current Journey'), findsOneWidget);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    expect(find.text('No current Journey'), findsOneWidget);
    expect(find.text('Enter Aaliyah’s Guardian Circle'), findsOneWidget);
    expect(find.text('Chat with Aaliyah'), findsNothing);
    expect(find.textContaining('Main Guardian still leads'), findsNothing);
    expect(
      find.byKey(const ValueKey('guardian-seeker-family-messages-top')),
      findsNothing,
    );

    final pageScroll = find.descendant(
      of: find.byKey(
        const PageStorageKey('guardian-seeker-page-scroll-dev-ws0'),
      ),
      matching: find.byType(Scrollable),
    );
    expect(pageScroll, findsOneWidget);
    expect(
      tester.state<ScrollableState>(pageScroll).position.maxScrollExtent,
      0,
    );
  });
}

const _missingSeekerNotice =
    'This Seeker is not available in your linked roster.';
final _rosterPages = find.byKey(const ValueKey('guardian-seeker-page-view'));

PageController _rosterPager(WidgetTester tester) =>
    tester.widget<PageView>(_rosterPages).controller!;

Finder _visibleOwner(String id) =>
    find.byKey(ValueKey('requested-owner-$id')).hitTestable();

Widget _rosterSubject(
  List<WaliLinkedPerson> people, {
  String? requestedSeekerId,
  int selectionRequest = 0,
  bool lastKnown = false,
  GuardianSeekerRosterContext context = const GuardianSeekerRosterContext(),
}) => _app(
  GuardianSeekerRosterView(
    resolution: const ZyraGuardianSeekerRosterResolver().resolve(
      linkedPeople: people,
      context: context,
    ),
    requestedSeekerId: requestedSeekerId,
    selectionRequest: selectionRequest,
    lastKnown: lastKnown,
    onRetry: () {},
    onInvite: () {},
    onOpenSeeker: (_) {},
    pageBuilder: (entry) => Center(
      key: ValueKey('requested-owner-${entry.person.id}'),
      child: Text('Owner: ${entry.person.id}'),
    ),
  ),
);

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

WaliLinkedPerson _person(String id, String name, {bool isMain = true}) =>
    WaliLinkedPerson(
      id: id,
      firstName: name,
      isMain: isMain,
      relationship: 'father',
      linkedAt: DateTime(2026, 1, 2),
    );

WaliJourneyView _journey(WaliLinkedPerson person) => WaliJourneyView(
  attemptId: 'attempt-1',
  matchId: 'match-1',
  linkedSeekerId: person.id,
  linkedSeekerName: person.firstName,
  partner: const SeekerProfile(
    id: 'partner',
    firstName: 'Idris',
    age: 30,
    city: '—',
    photos: [],
    gender: '',
  ),
  counterpartGuardianName: null,
  counterpartGuardianSurname: null,
  status: 'active',
  journeyStage: 'phase_1',
);
