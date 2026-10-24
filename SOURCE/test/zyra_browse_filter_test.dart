import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/seeker_profile.dart';

void main() {
  const sample = DraftProfile(
    id: 'unit-sample',
    firstName: 'Invented',
    age: 24,
    city: 'Sample city',
    residenceCountryCode: 'FR',
    nationalityCode: 'GB',
    ethnicityCode: 'arab',
    sampleLatitude: 48.85,
    sampleLongitude: 2.35,
  );

  test(
    'default filters keep adult eligibility, source order and exclusions',
    () {
      final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
      final source = model.discoverableProfiles;
      final result = const ZyraBrowseFilter().apply(source);
      expect(result, source);
      expect(result.map((p) => p.id), isNot(contains('draft-sara')));
      expect(result.map((p) => p.id), isNot(contains('draft-safiya')));
      expect(() => result.clear(), throwsUnsupportedError);
      expect(
        const ZyraBrowseFilter().matches(
          const DraftProfile(
            id: 'minor',
            firstName: 'Sample',
            age: 17,
            city: 'Sample',
          ),
        ),
        isFalse,
      );
    },
  );

  test(
    'age, residence, nationality and ethnicity are distinct conjunctive codes',
    () {
      const filter = ZyraBrowseFilter(
        minAge: 24,
        maxAge: 24,
        countryCode: 'FR',
        nationalityCode: 'GB',
        ethnicityCode: 'arab',
      );
      expect(filter.matches(sample), isTrue);
      expect(filter.withCountry('GB').matches(sample), isFalse);
      expect(filter.withNationality('FR').matches(sample), isFalse);
      expect(filter.withEthnicity('mixed').matches(sample), isFalse);
      expect(filter.withAge(25, 30).matches(sample), isFalse);
      expect(filter.withAge(18, 23).matches(sample), isFalse);
      expect(
        const ZyraBrowseFilter(city: 'Sample city').matches(sample),
        isTrue,
      );
      expect(const ZyraBrowseFilter(city: 'Paris').matches(sample), isFalse);
      expect(filter.withCountry(null).countryCode, isNull);
      expect(filter.withNationality(null).nationalityCode, isNull);
      expect(filter.withEthnicity(null).ethnicityCode, isNull);
    },
  );

  test('invalid ranges, labels-as-codes and unknown metadata fail closed', () {
    for (final filter in [
      const ZyraBrowseFilter(minAge: 17),
      const ZyraBrowseFilter(minAge: 30, maxAge: 29),
      const ZyraBrowseFilter(maxAge: 17),
      const ZyraBrowseFilter(countryCode: 'France'),
      const ZyraBrowseFilter(nationalityCode: 'British'),
      const ZyraBrowseFilter(ethnicityCode: 'Arab'),
      const ZyraBrowseFilter(city: ' '),
    ]) {
      expect(filter.isValid, isFalse);
      expect(filter.matches(sample), isFalse);
    }
    const missing = DraftProfile(
      id: 'missing',
      firstName: 'Sample',
      age: 24,
      city: 'Sample city',
    );
    expect(const ZyraBrowseFilter(countryCode: 'FR').matches(missing), isFalse);
    expect(
      const ZyraBrowseFilter(nationalityCode: 'GB').matches(missing),
      isFalse,
    );
    expect(
      const ZyraBrowseFilter(ethnicityCode: 'arab').matches(missing),
      isFalse,
    );
  });

  test(
    'radius never treats missing origin or coordinates as zero distance',
    () {
      const origin = ZyraBrowsePoint(48.85, 2.35);
      expect(
        const ZyraBrowseFilter(radiusKm: 0, origin: origin).matches(sample),
        isTrue,
      );
      expect(const ZyraBrowseFilter(radiusKm: 100).isValid, isFalse);
      expect(
        const ZyraBrowseFilter(radiusKm: -1, origin: origin).isValid,
        isFalse,
      );
      expect(
        ZyraBrowseFilter(radiusKm: double.infinity, origin: origin).isValid,
        isFalse,
      );
      expect(
        ZyraBrowseFilter(radiusKm: double.nan, origin: origin).isValid,
        isFalse,
      );
      expect(
        const ZyraBrowseFilter(
          radiusKm: 100,
          origin: ZyraBrowsePoint(91, 0),
        ).matches(sample),
        isFalse,
      );
      expect(
        const ZyraBrowseFilter(radiusKm: 100, origin: origin).matches(
          const DraftProfile(
            id: 'missing',
            firstName: 'Sample',
            age: 24,
            city: 'Sample',
          ),
        ),
        isFalse,
      );
      const near = ZyraBrowseFilter(radiusKm: 100, origin: origin);
      expect(near.withRadius(null).radiusKm, isNull);
      expect(near.withRadius(null).origin, isNull);
    },
  );

  test(
    'Haversine handles boundaries, dateline, poles, antipodes and symmetry',
    () {
      expect(zyraBrowseDistanceKm(null, zyraBrowseSampleOrigin), isNull);
      expect(
        zyraBrowseDistanceKm(
          const ZyraBrowsePoint(0, 181),
          zyraBrowseSampleOrigin,
        ),
        isNull,
      );
      expect(
        zyraBrowseDistanceKm(
          ZyraBrowsePoint(double.nan, 0),
          zyraBrowseSampleOrigin,
        ),
        isNull,
      );
      expect(
        zyraBrowseDistanceKm(
          const ZyraBrowsePoint(90, 180),
          const ZyraBrowsePoint(90, -180),
        ),
        closeTo(0, 1e-8),
      );
      expect(
        zyraBrowseDistanceKm(
          const ZyraBrowsePoint(0, 0),
          const ZyraBrowsePoint(0, 180),
        ),
        closeTo(6371.0088 * math.pi, 1e-6),
      );
      expect(
        zyraBrowseDistanceKm(
          const ZyraBrowsePoint(0, 179),
          const ZyraBrowsePoint(0, -179),
        ),
        closeTo(222.39016, .001),
      );
      const point = ZyraBrowsePoint(48.85, 2.35);
      final distance = zyraBrowseDistanceKm(zyraBrowseSampleOrigin, point)!;
      expect(
        distance,
        closeTo(zyraBrowseDistanceKm(point, zyraBrowseSampleOrigin)!, 1e-9),
      );
      expect(
        ZyraBrowseFilter(
          radiusKm: distance,
          origin: zyraBrowseSampleOrigin,
        ).matches(sample),
        isTrue,
      );
      expect(
        ZyraBrowseFilter(
          radiusKm: distance - .01,
          origin: zyraBrowseSampleOrigin,
        ).matches(sample),
        isFalse,
      );
    },
  );

  test(
    'public labels are optional and only separately supplied fixture labels',
    () {
      const ordinary = SeekerProfile(
        id: 'ordinary',
        firstName: 'Member',
        age: 24,
        city: 'London',
        gender: 'female',
        photos: [],
      );
      expect(ordinary.publicNationality, isNull);
      expect(ordinary.publicEthnicity, isNull);
      expect(zyraBrowseCountryLabel('GB'), 'United Kingdom');
      expect(zyraBrowseNationalityLabel('PK'), 'Pakistani');
      expect(zyraBrowseEthnicityLabel('arab'), 'Arab');
      expect(zyraBrowseCountryLabel('unknown'), isNull);
      expect(zyraBrowseNationalityLabel('unknown'), isNull);
      expect(zyraBrowseEthnicityLabel('unknown'), isNull);
      for (final profile in draftProfiles) {
        expect(zyraBrowseCountryLabel(profile.residenceCountryCode), isNotNull);
        expect(zyraBrowseNationalityLabel(profile.nationalityCode), isNotNull);
        expect(zyraBrowseEthnicityLabel(profile.ethnicityCode), isNotNull);
        expect(
          ZyraBrowsePoint(
            profile.sampleLatitude!,
            profile.sampleLongitude!,
          ).isValid,
          isTrue,
        );
      }
    },
  );

  test('Basic Guardian chat is revoked at the local model write boundary', () {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
    const guardian = 'draft-guardian-yusuf';
    const peer = 'draft-sara';
    expect(model.canUseSampleGuardianChat(guardian), isTrue);
    expect(
      model.setSampleGuardianMembership(
        guardian,
        DraftGuardianMembership.basic,
      ),
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(guardian, peer).view, isTrue);
    expect(model.sampleGuardianAccessFor(guardian, peer).chat, isFalse);
    expect(
      model.sampleGuardianAccessFor(guardian, peer, isMain: true).chat,
      isFalse,
    );
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, chatEnabled: true),
      isFalse,
    );
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, viewEnabled: false),
      isTrue,
    );
    expect(
      model.setSampleGuardianMembership(guardian, DraftGuardianMembership.one),
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(guardian, peer).chat, isFalse);
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, chatEnabled: true),
      isFalse,
    );
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, viewEnabled: true),
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(guardian, peer).chat, isFalse);
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, chatEnabled: true),
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(guardian, peer).chat, isTrue);
    expect(
      model.setSampleGuardianMembership('unknown', DraftGuardianMembership.one),
      isFalse,
    );
    expect(model.canUseSampleGuardianChat('unknown'), isFalse);
    expect(
      model.setSampleGuardianJourneyAccess('unknown', peer, chatEnabled: true),
      isFalse,
    );
    expect(model.end(peer), isTrue);
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, chatEnabled: true),
      isFalse,
    );
    expect(model.discoverableProfiles.map((p) => p.id), contains(peer));
    expect(model.canRequest(peer), isFalse);
  });
}
