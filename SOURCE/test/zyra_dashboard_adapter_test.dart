import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/services/zyra_dashboard_adapter.dart';
import 'package:zyra/services/zyra_dashboard_updates_service.dart';
import 'package:zyra/services/zyra_match_service.dart';
import 'package:zyra/services/zyra_profile_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

void main() {
  const profile = SeekerProfile(
    id: 'other',
    firstName: 'Adam',
    age: 31,
    city: 'London',
    photos: ['photo'],
    gender: 'male',
  );

  DashboardSnapshot build({
    DashboardSource<ZyraOnboardingProgress> onboarding =
        const DashboardSource.available(
          ZyraOnboardingProgress(
            complete: true,
            due: 175,
            missing: 0,
            hasChapter2: true,
            basicProfile: true,
          ),
        ),
    DashboardSource<List<JourneyMatch>> journeys =
        const DashboardSource.available(<JourneyMatch>[]),
    DashboardSource<List<DashboardSignal>> updates =
        const DashboardSource.available(<DashboardSignal>[]),
    DashboardSource<List<PendingInvite>> invitations =
        const DashboardSource.available(<PendingInvite>[]),
    DashboardSource<List<WaliLinkedPerson>> links =
        const DashboardSource.available(<WaliLinkedPerson>[]),
    DashboardSource<int> unreadCount = const DashboardSource.available(0),
    List<ZyraMilestone> milestones = const [],
    int? savedProfiles,
    DateTime? now,
  }) => ZyraSeekerDashboardAdapter.buildSnapshot(
    onboarding: onboarding,
    journeys: journeys,
    updates: updates,
    guardianInvitations: invitations,
    linkedPeople: links,
    unreadCount: unreadCount,
    journeyMilestones: milestones,
    savedProfiles: savedProfiles,
    now: now,
  );

  test('incomplete onboarding becomes a server-gate action', () {
    final snapshot = build(
      onboarding: const DashboardSource.available(
        ZyraOnboardingProgress(
          complete: false,
          due: 175,
          missing: 140,
          hasChapter2: true,
          basicProfile: true,
        ),
      ),
    );

    final signals = snapshot.onboarding.valueOrNull!;
    expect(signals, hasLength(1));
    expect(signals.single.kind, DashboardSignalKind.blockingGate);
    expect(signals.single.title, '35 of 175 answers saved');
    expect(signals.single.target, ZyraDashboardTarget.onboarding);
  });

  test('no Journey produces the ready-for-introductions summary', () {
    final summary = build().journeys.valueOrNull!.summary;

    expect(summary.kind, DashboardJourneyKind.searching);
    expect(summary.title, 'Ready for introductions');
  });

  test('linked Guardians with no Main produce the required action', () {
    final family = build(
      links: DashboardSource.available([
        WaliLinkedPerson(
          id: 'guardian-1',
          firstName: 'Hassan',
          relationship: 'brother',
          linkedAt: DateTime.utc(2026, 9, 17),
        ),
      ]),
    ).stableState.family.valueOrNull!;

    expect(family.kind, DashboardFamilyKind.connected);
    expect(family.title, 'Choose a Main Guardian');
    expect(family.actionLabel, 'Choose Main Guardian');
    expect(family.detail, contains('Journey waits'));
  });

  test('Potential, Active, Paused and Ended rows map truthfully', () {
    JourneyMatch row({
      required String id,
      required String status,
      ZyraJourneyPauseState pause = ZyraJourneyPauseState.active,
      String? stage,
      DateTime? endedAt,
    }) => JourneyMatch(
      matchId: id,
      profile: profile,
      status: status,
      journeyStage: stage,
      pause: pause,
      endedAt: endedAt,
    );

    final potential = build(
      journeys: DashboardSource.available([row(id: 'p', status: 'potential')]),
    ).journeys.valueOrNull!.summary;
    expect(potential.kind, DashboardJourneyKind.potential);

    final active = build(
      journeys: DashboardSource.available([
        row(id: 'a', status: 'active', stage: 'phase_1'),
      ]),
    ).journeys.valueOrNull!.summary;
    expect(active.kind, DashboardJourneyKind.active);
    expect(active.detail, contains('Faith & Values'));
    expect(active.latestCompletedStage, isNull);
    expect(active.nextMilestone, 'Next · Building a Life');
    expect(active.momentum, isNull);

    final paused = build(
      journeys: DashboardSource.available([
        row(
          id: 's',
          status: 'active',
          stage: 'phase_2',
          pause: const ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
        ),
      ]),
    ).journeys.valueOrNull!.summary;
    expect(paused.kind, DashboardJourneyKind.paused);
    expect(paused.title, 'Your Journey with Adam is paused');
    expect(paused.detail, 'Paused · Building a Life');

    final ended = build(
      journeys: DashboardSource.available([
        row(id: 'e', status: 'ended', endedAt: DateTime.utc(2026, 8, 20)),
      ]),
    ).journeys.valueOrNull!.summary;
    expect(ended.kind, DashboardJourneyKind.ended);
    expect(ended.title, 'Your Journey with Adam');
  });

  test('paused summary suppresses mock and unavailable counterpart names', () {
    for (final entry in [(true, 'Adam'), (false, '  '), (false, 'Unknown')]) {
      final summary = build(
        journeys: DashboardSource.available([
          JourneyMatch(
            matchId: 'paused',
            profile: SeekerProfile(
              id: 'other',
              firstName: entry.$2,
              age: 31,
              city: 'London',
              photos: const ['photo'],
              gender: 'male',
            ),
            status: 'active',
            pause: const ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
            isMock: entry.$1,
          ),
        ]),
      ).journeys.valueOrNull!.summary;
      expect(summary.title, 'Your Journey is paused');
    }
  });

  test('real milestones prove latest stage and momentum lines', () {
    final now = DateTime.utc(2026, 8, 28, 12);
    final snapshot = build(
      journeys: const DashboardSource.available([
        JourneyMatch(
          matchId: 'active',
          profile: profile,
          status: 'active',
          journeyStage: 'compatibility_reveal',
        ),
      ]),
      milestones: [
        ZyraMilestone(
          type: 'salam_exchanged',
          occurredAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      now: now,
    );

    final state = snapshot.journeys.valueOrNull!;
    expect(
      state.summary.latestCompletedStage,
      'Latest completed · Salam Exchange',
    );
    expect(state.summary.nextMilestone, 'Next · Guardian Gate');
    expect(state.summary.momentum, 'Your Journey moved forward this week.');
    // Timeline rows are durable history, not unread objects. They inform the
    // Journey lines but cannot become a repeating Right Now signal.
    expect(state.signals, isEmpty);
  });

  test('a quiet week suppresses momentum rather than scoring inactivity', () {
    final now = DateTime.utc(2026, 8, 28, 12);
    final summary = build(
      journeys: const DashboardSource.available([
        JourneyMatch(
          matchId: 'active',
          profile: profile,
          status: 'active',
          journeyStage: 'phase_1',
        ),
      ]),
      milestones: [
        ZyraMilestone(
          type: 'compatibility_revealed',
          occurredAt: now.subtract(const Duration(days: 8)),
        ),
      ],
      now: now,
    ).journeys.valueOrNull!.summary;

    expect(summary.latestCompletedStage, isNotNull);
    expect(summary.momentum, isNull);
  });

  test('RPC-backed Updates pass through their tri-state unread value', () {
    final created = DateTime.utc(2026, 8, 28, 8);
    final snapshot = build(
      updates: DashboardSource.available([
        DashboardSignal(
          id: 'update:notification:unread',
          kind: DashboardSignalKind.meaningfulMovement,
          title: 'A Potential Journey is ready',
          detail: 'Review it when you are ready.',
          target: ZyraDashboardTarget.notifications,
          eventAt: created,
          isUnread: true,
        ),
        DashboardSignal(
          id: 'update:timeline:domain',
          kind: DashboardSignalKind.meaningfulMovement,
          title: 'Journey milestone',
          target: ZyraDashboardTarget.connectionsJourneys,
          eventAt: created.subtract(const Duration(minutes: 1)),
          isUnread: null,
        ),
      ]),
    );

    final signals = snapshot.updates.valueOrNull!;
    expect(signals, hasLength(2));
    expect(signals.first.isUnread, isTrue);
    expect(signals.last.isUnread, isNull);
  });

  group('Journey update personalisation without extra reads', () {
    final occurredAt = DateTime.utc(2026, 9, 16, 12);

    ZyraDashboardUpdate update({
      String event = 'journey_continued',
      String classKey = 'journey.timeline_milestone',
      String titleKey = 'dashboard_updates.journey.timeline_milestone.title',
      String? detailKey,
      String destination = 'connections.journeys',
      String? matchId = 'match-1',
      bool? unread,
    }) => ZyraDashboardUpdate(
      occurredAt: occurredAt,
      classKey: classKey,
      sourceId: 'source-1',
      titleKey: titleKey,
      detailKey:
          detailKey ??
          'dashboard_updates.journey.timeline_milestone.$event.detail',
      destinationKey: destination,
      relatedMatchId: matchId,
      isUnread: unread,
    );

    JourneyMatch journey({
      String id = 'match-1',
      String name = 'Adam',
      bool mock = false,
    }) => JourneyMatch(
      matchId: id,
      profile: SeekerProfile(
        id: 'other',
        firstName: name,
        surnameLine: 'Never shown',
        age: 31,
        city: 'London',
        photos: const ['photo'],
        gender: 'male',
      ),
      status: 'active',
      isMock: mock,
    );

    test('confirmed events name only the matching authorised counterpart', () {
      const expected = {
        'journey_started': 'Your Journey with Adam has started',
        'journey_continued': 'Your Journey with Adam has resumed',
        'journey_paused': 'Your Journey with Adam was paused',
        'journey_ended': 'Your Journey with Adam has ended',
      };
      for (final entry in expected.entries) {
        final row = update(event: entry.key);
        final signal = ZyraSeekerDashboardAdapter.updatesForJourneys(
          [row],
          journeys: [
            journey(id: 'another-match', name: 'Aisha'),
            journey(),
          ],
        ).single;
        expect(signal.title, entry.value);
        expect(signal.kind, DashboardSignalKind.meaningfulMovement);
        expect(signal.id, row.toDashboardSignal().id);
        expect(signal.eventAt, occurredAt);
        expect(signal.isUnread, isNull);
        expect(signal.target, ZyraDashboardTarget.connectionsJourneys);
        expect(signal.actionLabel, row.toDashboardSignal().actionLabel);
        expect(
          signal.detail,
          entry.key == 'journey_paused'
              ? 'A pause was recorded for this Journey.'
              : row.toDashboardSignal().detail,
        );
      }
    });

    test('requests stay movement with no inferred requester or obligation', () {
      final row = update(
        classKey: 'notification.journey_request',
        titleKey: 'dashboard_updates.notification.journey_request.title',
        detailKey: 'dashboard_updates.notification.journey_request.detail',
        destination: 'notifications',
        unread: true,
      );
      final signal = ZyraSeekerDashboardAdapter.updatesForJourneys(
        [row],
        journeys: [journey()],
      ).single;
      expect(signal.title, 'A Journey request with Adam was received');
      expect(signal.kind, DashboardSignalKind.meaningfulMovement);
      expect(signal.isUnread, isTrue);
      expect(signal.target, ZyraDashboardTarget.none);
      expect(signal.actionLabel, isNull);
      expect(signal.detail, isNot(contains('ready to review')));
      // The shared renderer used by Guardian retains its existing copy.
      expect(row.toDashboardSignal().title, 'New Journey request');
    });

    test('recorded declined and paused notifications stay historical', () {
      for (final entry in {
        'journey_request_declined': 'A Journey request with Adam was declined',
        'journey_also_paused': 'Your Journey with Adam was paused',
      }.entries) {
        final row = update(
          classKey: 'notification.${entry.key}',
          titleKey: 'dashboard_updates.notification.${entry.key}.title',
          detailKey: 'dashboard_updates.notification.${entry.key}.detail',
          destination: 'notifications',
          unread: true,
        );
        final signal = ZyraSeekerDashboardAdapter.updatesForJourneys(
          [row],
          journeys: [journey()],
        ).single;
        expect(signal.title, entry.value);
        expect(signal.detail, isNot(contains('now')));
        expect(signal.kind, DashboardSignalKind.meaningfulMovement);
        expect(signal.isUnread, isTrue);
        expect(signal.target, ZyraDashboardTarget.none);
      }
    });

    test(
      'unavailable, missing, duplicate, mock and unnamed rows are neutral',
      () {
        for (final rows in <List<JourneyMatch>?>[
          null,
          [],
          [journey(id: 'another-match')],
          [journey(), journey(name: 'Aisha'), journey()],
          [journey(mock: true)],
          [journey(name: '  ')],
          [journey(name: 'Hidden profile')],
        ]) {
          final signal = ZyraSeekerDashboardAdapter.updatesForJourneys([
            update(),
          ], journeys: rows).single;
          expect(signal.title, 'Your Journey has resumed');
        }
        expect(
          ZyraSeekerDashboardAdapter.updatesForJourneys(
            [update(matchId: null)],
            journeys: [journey()],
          ).single.title,
          'Your Journey has resumed',
        );
      },
    );

    test('unknown keys and mismatched known tuples cannot gain a name', () {
      for (final row in [
        update(titleKey: 'unknown.title'),
        update(detailKey: 'unknown.detail'),
        update(destination: 'unknown.destination'),
      ]) {
        final signal = ZyraSeekerDashboardAdapter.updatesForJourneys(
          [row],
          journeys: [journey()],
        ).single;
        expect(signal.title, 'Update available');
        expect(signal.target, ZyraDashboardTarget.none);
      }
      for (final row in [
        update(classKey: 'notification'),
        update(titleKey: 'dashboard_updates.notification.new_message.title'),
        update(destination: 'guardian'),
      ]) {
        final signal = ZyraSeekerDashboardAdapter.updatesForJourneys(
          [row],
          journeys: [journey()],
        ).single;
        expect(signal.title, row.toDashboardSignal().title);
        expect(signal.title, isNot(contains('Adam')));
      }
    });
  });

  test(
    'pending Guardian invitations live in Family, not repeated movement',
    () {
      final now = DateTime.utc(2026, 8, 28, 12);
      final created = now.subtract(const Duration(days: 1));
      final snapshot = build(
        invitations: DashboardSource.available([
          PendingInvite(
            token: 'ONE',
            createdAt: created,
            expiresAt: now.add(const Duration(days: 3)),
          ),
          PendingInvite(
            token: 'TWO',
            createdAt: created,
            expiresAt: now.add(const Duration(days: 5)),
          ),
        ]),
        now: now,
      );

      final signals = snapshot.guardianInvitations.valueOrNull!;
      final family = snapshot.stableState.family.valueOrNull!;
      expect(signals, isEmpty);
      expect(family.kind, DashboardFamilyKind.invitationPending);
      expect(family.pendingInvitationCount, 2);
      expect(family.title, '2 Guardian invitations pending');
      expect(family.detail, 'Earliest invitation expires in 3 days.');
      expect(family.actionLabel, 'Manage Guardians');
      expect(family.expiresAt, now.add(const Duration(days: 3)));
    },
  );

  test('Family prefers a connected Main Guardian and relationship label', () {
    final snapshot = build(
      links: const DashboardSource.available([
        WaliLinkedPerson(id: 'additional', firstName: 'Ali'),
        WaliLinkedPerson(
          id: 'main',
          firstName: 'Ibrahim',
          isMain: true,
          relationship: 'father',
        ),
      ]),
    );

    final family = snapshot.stableState.family.valueOrNull!;
    expect(family.kind, DashboardFamilyKind.connected);
    expect(family.title, 'Father · Guardian connected');
    expect(family.linkedCount, 2);
    expect(family.actionLabel, 'Manage Guardians');
  });

  test('Family absence routes to the Manager rather than owning Add', () {
    final family = build().stableState.family.valueOrNull!;

    expect(family.kind, DashboardFamilyKind.notConnected);
    expect(family.title, 'No Guardian connected');
    expect(family.detail, 'Add a Guardian when you are ready.');
    expect(family.actionLabel, 'Manage Guardians');
    expect(family.target, ZyraDashboardTarget.guardian);
  });

  test('Family never substitutes a Guardian first name for relationship', () {
    final snapshot = build(
      links: const DashboardSource.available([
        WaliLinkedPerson(id: 'main', firstName: 'Ibrahim', isMain: true),
      ]),
    );

    final family = snapshot.stableState.family.valueOrNull!;
    expect(family.title, 'Guardian · Guardian connected');
    expect(family.title, isNot(contains('Ibrahim')));
  });

  test('a proven Guardian link survives an invitation-read failure', () {
    final snapshot = build(
      links: const DashboardSource.available([
        WaliLinkedPerson(
          id: 'main',
          firstName: 'Ibrahim',
          isMain: true,
          relationship: 'father',
        ),
      ]),
      invitations: const DashboardSource.unavailable(
        DashboardFailure(code: 'invites_failed'),
      ),
    );

    expect(
      snapshot.stableState.family.valueOrNull?.kind,
      DashboardFamilyKind.connected,
    );
    expect(
      snapshot.guardianInvitations.state,
      DashboardSourceState.unavailable,
    );
  });

  test('MY ZYRA suppresses zeros and keeps informative Guardian absence', () {
    final items = build().stableState.orientationItems.valueOrNull!;

    expect(items.map((item) => item.kind), [DashboardOrientationKind.guardian]);
    expect(items.single.valueLabel, 'Not connected');
  });

  test('MY ZYRA keeps updates out of its orientation snapshot', () {
    final snapshot = build(
      journeys: const DashboardSource.available([
        JourneyMatch(matchId: 'p', profile: profile, status: 'potential'),
      ]),
      unreadCount: const DashboardSource.available(4),
      savedProfiles: 2,
    );
    final items = snapshot.stableState.orientationItems.valueOrNull!;

    expect(items.map((item) => item.kind), [
      DashboardOrientationKind.potentials,
      DashboardOrientationKind.guardian,
      DashboardOrientationKind.saved,
    ]);
    expect(items.last.emphasis, DashboardOrientationEmphasis.quiet);
  });

  test('failed unread total does not suppress independent orientation', () {
    final snapshot = build(
      unreadCount: const DashboardSource.unavailable(
        DashboardFailure(code: 'unread_failed'),
      ),
    );

    expect(
      snapshot.stableState.orientationItems.state,
      DashboardSourceState.available,
    );
    expect(snapshot.stableState.family.valueOrNull?.kind, isNotNull);
  });

  test('production calm state carries no behavioural advisory', () {
    final snapshot = build();

    expect(snapshot.advisories.state, DashboardSourceState.available);
    expect(snapshot.advisories.valueOrNull, isEmpty);
  });

  test('a failed Updates RPC remains unavailable independently', () {
    final snapshot = build(
      updates: const DashboardSource.unavailable(
        DashboardFailure(code: 'updates_unavailable'),
      ),
    );

    expect(snapshot.updates.state, DashboardSourceState.unavailable);
    expect(snapshot.updates.failureOrNull?.code, 'updates_unavailable');
    expect(snapshot.stableState.family.state, DashboardSourceState.available);
  });

  test('a successful empty Updates RPC remains an honest empty success', () {
    final snapshot = build();

    expect(snapshot.updates.state, DashboardSourceState.available);
    expect(snapshot.updates.valueOrNull, isEmpty);
  });
}
