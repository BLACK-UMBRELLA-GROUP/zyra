import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_guardian_seeker_roster_resolver.dart';
import 'package:zyra/services/zyra_wali_journey_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

void main() {
  const resolver = ZyraGuardianSeekerRosterResolver();

  test('uses the ruled group order and oldest-waiting-first', () {
    final people = [
      _person('review-new', 'Aaliyah'),
      _person('review-old', 'Zaynab'),
      _person('active', 'Bilal'),
      _person('paused', 'Hana'),
      _person('other-z', 'Yusuf'),
      _person('other-a', 'Adam'),
    ];
    final journeys = [
      _journey('m-review-new', people[0], stage: 'phase_1'),
      _journey('m-review-old', people[1], stage: 'phase_1'),
      _journey('m-active', people[2], stage: 'phase_2'),
      _journey(
        'm-paused',
        people[3],
        stage: 'phase_2',
        pause: const ZyraJourneyPauseState(
          phase: ZyraPausePhase.paused,
          initiatedBy: 'seeker',
        ),
      ),
    ];
    final resolution = resolver.resolve(
      linkedPeople: people,
      context: GuardianSeekerRosterContext(
        journeys: journeys,
        openReviewMatchIds: const {'m-review-new', 'm-review-old'},
        waitingSinceByMatchId: {
          'm-review-new': DateTime.utc(2026, 8, 30),
          'm-review-old': DateTime.utc(2026, 8, 28),
        },
      ),
    );

    expect(
      resolution.mainSections.map((section) => section.group),
      GuardianSeekerRosterGroup.values,
    );
    expect(
      resolution.mainSections[0].entries
          .map((entry) => entry.person.firstName)
          .toList(),
      ['Zaynab', 'Aaliyah'],
    );
    expect(resolution.mainSections[1].entries.single.person.firstName, 'Bilal');
    expect(resolution.mainSections[2].entries.single.person.firstName, 'Hana');
    expect(
      resolution.mainSections[3].entries
          .map((entry) => entry.person.firstName)
          .toList(),
      ['Adam', 'Yusuf'],
    );
  });

  test(
    'puts unknown wait timestamps last then uses a stable name tie-break',
    () {
      final alpha = _person('alpha', 'Aaliyah');
      final known = _person('known', 'Zaynab');
      final resolution = resolver.resolve(
        linkedPeople: [alpha, known],
        context: GuardianSeekerRosterContext(
          journeys: [
            _journey('m-alpha', alpha, stage: 'wali_gate'),
            _journey('m-known', known, stage: 'wali_gate'),
          ],
          waitingSinceByMatchId: {'m-known': DateTime.utc(2026, 8, 29)},
        ),
      );

      expect(
        resolution.mainSections.first.entries
            .map((entry) => entry.person.firstName)
            .toList(),
        ['Zaynab', 'Aaliyah'],
      );
    },
  );

  test(
    'Additional guardianships show authorised context without Main duties',
    () {
      final zara = _person('zara', 'Zara', isMain: false);
      final aisha = _person('aisha', 'Aisha', isMain: false);
      final resolution = resolver.resolve(
        linkedPeople: [zara, aisha],
        context: GuardianSeekerRosterContext(
          journeys: [
            _journey('secret-z', zara, stage: 'wali_gate'),
            _journey(
              'secret-a',
              aisha,
              stage: 'phase_3',
              pause: const ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
            ),
          ],
          openReviewMatchIds: const {'secret-z'},
          waitingSinceByMatchId: {
            'secret-z': DateTime.utc(2020),
            'secret-a': DateTime.utc(2030),
          },
        ),
      );

      expect(
        resolution.mainSections.every((section) => section.entries.isEmpty),
        isTrue,
      );
      expect(
        resolution.additionalGuardianships
            .map((entry) => entry.person.firstName)
            .toList(),
        ['Aisha', 'Zara'],
      );
      for (final entry in resolution.additionalGuardianships) {
        expect(entry.currentJourney, isNotNull);
        expect(entry.needsAttention, isFalse);
        expect(entry.waitingSince, isNull);
      }
      expect(
        resolution.additionalGuardianships
            .map((entry) => entry.contextLine)
            .toList(),
        ['Journey paused', 'Journey with Idris · Guardian Gate'],
      );
    },
  );

  test('open Family Review takes precedence over a paused group', () {
    final person = _person('main', 'Maryam');
    final resolution = resolver.resolve(
      linkedPeople: [person],
      context: GuardianSeekerRosterContext(
        journeys: [
          _journey(
            'review',
            person,
            stage: 'phase_2',
            pause: const ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
          ),
        ],
        openReviewMatchIds: const {'review'},
      ),
    );

    expect(resolution.mainSections.first.entries, hasLength(1));
    expect(resolution.mainSections.first.entries.single.needsAttention, isTrue);
    expect(
      resolution.mainSections.first.entries.single.contextLine,
      'Family Review needs you',
    );
  });
}

WaliLinkedPerson _person(String id, String name, {bool isMain = true}) =>
    WaliLinkedPerson(
      id: id,
      firstName: name,
      isMain: isMain,
      relationship: 'father',
      linkedAt: DateTime.utc(2026, 1, 1),
    );

WaliJourneyView _journey(
  String matchId,
  WaliLinkedPerson person, {
  required String stage,
  ZyraJourneyPauseState pause = ZyraJourneyPauseState.active,
}) => WaliJourneyView(
  attemptId: 'attempt-$matchId',
  matchId: matchId,
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
  journeyStage: stage,
  pause: pause,
);
