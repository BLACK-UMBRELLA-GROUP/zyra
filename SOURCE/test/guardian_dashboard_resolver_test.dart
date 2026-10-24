import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_guardian_dashboard_resolver.dart';
import 'package:zyra/services/zyra_wali_journey_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

void main() {
  const resolver = ZyraGuardianDashboardResolver();

  test('keeps Family Reviews before gates and returns compact counts', () {
    const aisha = WaliLinkedPerson(
      id: 'aisha',
      firstName: 'Aisha',
      isMain: true,
    );
    const maryam = WaliLinkedPerson(
      id: 'maryam',
      firstName: 'Maryam',
      isMain: true,
    );
    const zainab = WaliLinkedPerson(id: 'zainab', firstName: 'Zainab');
    final review = _journey(
      matchId: 'review',
      seekerId: 'aisha',
      seekerName: 'Aisha',
      partnerName: 'Adam',
      stage: 'phase_1',
    );
    final gate = _journey(
      matchId: 'gate',
      seekerId: 'maryam',
      seekerName: 'Maryam',
      partnerName: 'Bilal',
      stage: 'wali_gate',
    );

    final result = resolver.resolve(
      linkedPeople: const [zainab, maryam, aisha],
      journeys: [gate, review],
      openReviewIds: const {'review'},
    );

    expect(result.linkedSeekerCount, 3);
    expect(result.needsYouCount, 2);
    expect(result.attention.map((item) => item.kind), [
      GuardianDashboardAttentionKind.familyReview,
      GuardianDashboardAttentionKind.guardianGate,
    ]);
    expect(result.attention.map((item) => item.journey.matchId), [
      'review',
      'gate',
    ]);
    expect(result.attention.first.title, 'Aisha needs your Family Review');
    expect(result.attention.last.title, 'Maryam needs a Guardian step');
    expect(
      result.attention.map((item) => item.title).join(' '),
      isNot(contains('Adam')),
    );
    expect(
      result.attention.map((item) => item.title).join(' '),
      isNot(contains('Bilal')),
    );
    expect(
      result.attention.map((item) => item.title).join(' '),
      isNot(contains('phase_1')),
    );
  });

  test('Additional-owned Journey and review ids have zero effect', () {
    const main = WaliLinkedPerson(id: 'main', firstName: 'Aisha', isMain: true);
    const additional = WaliLinkedPerson(id: 'additional', firstName: 'Maryam');
    final mainGate = _journey(
      matchId: 'main-gate',
      seekerId: 'main',
      seekerName: 'Aisha',
      partnerName: 'Adam',
      stage: 'wali_gate',
    );
    final hiddenReview = _journey(
      matchId: 'hidden-review',
      seekerId: 'additional',
      seekerName: 'Maryam',
      partnerName: 'Hidden Partner',
      stage: 'phase_1',
    );

    final baseline = resolver.resolve(
      linkedPeople: const [main, additional],
      journeys: [mainGate],
      openReviewIds: const {},
    );
    final withInjectedAdditional = resolver.resolve(
      linkedPeople: const [main, additional],
      journeys: [hiddenReview, mainGate],
      openReviewIds: const {'hidden-review'},
    );

    expect(withInjectedAdditional.linkedSeekerCount, 2);
    expect(withInjectedAdditional.needsYouCount, baseline.needsYouCount);
    expect(
      withInjectedAdditional.attention.map((item) => item.journey.matchId),
      baseline.attention.map((item) => item.journey.matchId),
    );
    expect(withInjectedAdditional.attention, hasLength(1));
    expect(
      withInjectedAdditional.attention.single.journey.matchId,
      'main-gate',
    );
    final renderedCopy = withInjectedAdditional.attention
        .map((item) => '${item.title} ${item.detail}')
        .join(' ');
    expect(renderedCopy, isNot(contains('Maryam')));
    expect(renderedCopy, isNot(contains('Hidden Partner')));
  });

  test('needs-you count is distinct by authorised Main Seeker', () {
    const main = WaliLinkedPerson(id: 'main', firstName: 'Aisha', isMain: true);
    final review = _journey(
      matchId: 'review',
      seekerId: 'main',
      seekerName: 'Aisha',
      partnerName: 'Adam',
      stage: 'phase_1',
    );
    final gate = _journey(
      matchId: 'gate',
      seekerId: 'main',
      seekerName: 'Aisha',
      partnerName: 'Adam',
      stage: 'wali_gate',
    );
    final ended = _journey(
      matchId: 'ended',
      seekerId: 'main',
      seekerName: 'Aisha',
      partnerName: 'Adam',
      stage: 'wali_gate',
      status: 'ended',
    );

    final result = resolver.resolve(
      linkedPeople: const [main],
      journeys: [review, gate, ended],
      openReviewIds: const {'review', 'ended'},
    );

    expect(result.attention, hasLength(2));
    expect(result.needsYouCount, 1);
    expect(result.linkedSeekerCount, 1);
  });
}

WaliJourneyView _journey({
  required String matchId,
  required String seekerId,
  required String seekerName,
  required String partnerName,
  required String stage,
  String status = 'active',
}) => WaliJourneyView(
  matchId: matchId,
  linkedSeekerId: seekerId,
  linkedSeekerName: seekerName,
  partner: SeekerProfile(
    id: 'partner-$matchId',
    firstName: partnerName,
    age: 30,
    city: '—',
    photos: const [],
    gender: 'male',
  ),
  counterpartGuardianName: null,
  counterpartGuardianSurname: null,
  status: status,
  journeyStage: stage,
  isMock: true,
);
