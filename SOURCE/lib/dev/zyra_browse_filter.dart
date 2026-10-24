import 'dart:math' as math;

import '../data/zyra_reference_data.dart';
import 'zyra_view_request_draft_model.dart';

/// Pure sample filtering, not a production discovery or permission boundary.
/// Radius uses this explicit invented origin, never the device's location.
const zyraBrowseSampleOrigin = ZyraBrowsePoint(53.48, -2.24);
const zyraBrowseSampleOriginLabel = 'Distance origin · Manchester';

class ZyraBrowsePoint {
  const ZyraBrowsePoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

/// Null means unknown/invalid, not zero distance. The result is kilometres.
double? zyraBrowseDistanceKm(ZyraBrowsePoint? a, ZyraBrowsePoint? b) {
  if (a == null || b == null || !a.isValid || !b.isValid) return null;
  const radians = math.pi / 180;
  final dLat = (b.latitude - a.latitude) * radians;
  final dLon = (b.longitude - a.longitude) * radians;
  final latitudeA = a.latitude * radians;
  final latitudeB = b.latitude * radians;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(latitudeA) *
          math.cos(latitudeB) *
          math.pow(math.sin(dLon / 2), 2);
  final bounded = h.toDouble().clamp(0.0, 1.0);
  return 6371.0088 * 2 * math.atan2(math.sqrt(bounded), math.sqrt(1 - bounded));
}

String? zyraBrowseCountryLabel(String? code) {
  for (final item in zyraCountries) {
    if (item.code == code) return item.name;
  }
  return null;
}

String? zyraBrowseNationalityLabel(String? code) {
  for (final item in zyraCountries) {
    if (item.code == code) return item.nationality;
  }
  return null;
}

String? zyraBrowseEthnicityLabel(String? code) {
  for (final item in zyraEthnicities) {
    if (item.code == code) return item.name;
  }
  return null;
}

class ZyraBrowseFilter {
  const ZyraBrowseFilter({
    this.minAge,
    this.maxAge,
    this.countryCode,
    this.nationalityCode,
    this.ethnicityCode,
    this.radiusKm,
    this.origin,
    this.city,
  });

  final int? minAge;
  final int? maxAge;
  final String? countryCode;
  final String? nationalityCode;
  final String? ethnicityCode;
  final double? radiusKm;
  final ZyraBrowsePoint? origin;

  /// Kept for the existing exact-city comparison; never geocodes a label.
  final String? city;

  bool get isActive =>
      minAge != null ||
      maxAge != null ||
      countryCode != null ||
      nationalityCode != null ||
      ethnicityCode != null ||
      radiusKm != null ||
      city != null;

  bool get isValid =>
      (minAge == null || minAge! >= 18) &&
      (maxAge == null || maxAge! >= (minAge ?? 18)) &&
      (countryCode == null || zyraBrowseCountryLabel(countryCode) != null) &&
      (nationalityCode == null ||
          zyraBrowseNationalityLabel(nationalityCode) != null) &&
      (ethnicityCode == null ||
          zyraBrowseEthnicityLabel(ethnicityCode) != null) &&
      (city == null || city!.trim().isNotEmpty) &&
      (radiusKm == null ||
          (radiusKm!.isFinite && radiusKm! >= 0 && origin?.isValid == true));

  bool matches(DraftProfile profile) {
    if (!isValid ||
        profile.age < (minAge ?? 18) ||
        (maxAge != null && profile.age > maxAge!) ||
        (countryCode != null && profile.residenceCountryCode != countryCode) ||
        (nationalityCode != null &&
            profile.nationalityCode != nationalityCode) ||
        (ethnicityCode != null && profile.ethnicityCode != ethnicityCode) ||
        (city != null && profile.city != city)) {
      return false;
    }
    if (radiusKm != null) {
      final point =
          profile.sampleLatitude == null || profile.sampleLongitude == null
          ? null
          : ZyraBrowsePoint(profile.sampleLatitude!, profile.sampleLongitude!);
      final distance = zyraBrowseDistanceKm(origin, point);
      if (distance == null || distance > radiusKm!) return false;
    }
    return true;
  }

  /// Preserves the caller's eligibility exclusions and stable source order.
  List<DraftProfile> apply(Iterable<DraftProfile> eligible) =>
      List.unmodifiable(eligible.where(matches));

  /// Explicit null-clearing avoids keeping an old selection on "Any".
  ZyraBrowseFilter withAge(int? minimum, int? maximum) => ZyraBrowseFilter(
    minAge: minimum,
    maxAge: maximum,
    countryCode: countryCode,
    nationalityCode: nationalityCode,
    ethnicityCode: ethnicityCode,
    radiusKm: radiusKm,
    origin: origin,
    city: city,
  );

  ZyraBrowseFilter withCountry(String? value) =>
      _copy(country: value, field: 'country');
  ZyraBrowseFilter withNationality(String? value) =>
      _copy(country: value, field: 'nationality');
  ZyraBrowseFilter withEthnicity(String? value) =>
      _copy(country: value, field: 'ethnicity');
  ZyraBrowseFilter withCity(String? value) =>
      _copy(country: value, field: 'city');

  ZyraBrowseFilter _copy({required String? country, required String field}) =>
      ZyraBrowseFilter(
        minAge: minAge,
        maxAge: maxAge,
        countryCode: field == 'country' ? country : countryCode,
        nationalityCode: field == 'nationality' ? country : nationalityCode,
        ethnicityCode: field == 'ethnicity' ? country : ethnicityCode,
        radiusKm: radiusKm,
        origin: origin,
        city: field == 'city' ? country : city,
      );

  ZyraBrowseFilter withRadius(double? value, {ZyraBrowsePoint? from}) =>
      ZyraBrowseFilter(
        minAge: minAge,
        maxAge: maxAge,
        countryCode: countryCode,
        nationalityCode: nationalityCode,
        ethnicityCode: ethnicityCode,
        radiusKm: value,
        origin: value == null ? null : from,
        city: city,
      );
}
