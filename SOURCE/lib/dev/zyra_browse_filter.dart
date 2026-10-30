import 'dart:math' as math;

import '../data/zyra_reference_data.dart';
import 'zyra_view_request_draft_model.dart';

/// Pure sample filtering, not a production discovery or permission boundary.
/// Radius uses a caller-owned home town or validated coarse session origin.
const zyraBrowseSampleOrigin = ZyraBrowsePoint(53.48, -2.24);
const zyraBrowseSampleOriginLabel = 'From Manchester (home town)';
const zyraBrowseRadiusSteps = <double>[
  5,
  10,
  15,
  25,
  50,
  75,
  100,
  150,
  200,
  300,
  500,
];

enum ZyraBrowseWhere { nearMe, country, worldwide }

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

/// Disambiguation belongs only to the Filters list, not profile facts.
String? zyraBrowseFilterNationalityLabel(String? code) {
  final label = zyraBrowseNationalityLabel(code);
  return label == 'Dominican'
      ? '$label (${zyraBrowseCountryLabel(code)})'
      : label;
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
    this.where = ZyraBrowseWhere.country,
    this.countryCode = 'GB',
    this.nationalityCodes = const {},
    this.ethnicityCodes = const {},
    this.radiusKm = 50,
    this.origin = zyraBrowseSampleOrigin,
  });

  final int? minAge, maxAge;
  final ZyraBrowseWhere where;
  final String? countryCode;
  final Set<String> nationalityCodes, ethnicityCodes;
  final double radiusKm;
  final ZyraBrowsePoint? origin;

  bool get hasAgeRange => minAge != null || maxAge != null;
  int get activeCount =>
      (hasAgeRange ? 1 : 0) +
      (where == ZyraBrowseWhere.nearMe ? 1 : 0) +
      (nationalityCodes.isNotEmpty ? 1 : 0) +
      (ethnicityCodes.isNotEmpty ? 1 : 0);
  bool get isActive => activeCount > 0;

  bool get isValid =>
      (minAge == null || (minAge! >= 18 && minAge! <= 70)) &&
      (maxAge == null || (maxAge! >= (minAge ?? 18) && maxAge! <= 70)) &&
      (where != ZyraBrowseWhere.country ||
          zyraBrowseCountryLabel(countryCode) != null) &&
      nationalityCodes.every(
        (code) => zyraBrowseNationalityLabel(code) != null,
      ) &&
      ethnicityCodes.every(
        (code) =>
            code != 'prefer_not_to_say' &&
            zyraBrowseEthnicityLabel(code) != null,
      ) &&
      (where != ZyraBrowseWhere.nearMe ||
          (radiusKm.isFinite && radiusKm >= 0 && origin?.isValid == true));

  bool matches(DraftProfile profile) {
    if (!isValid ||
        profile.age < (minAge ?? 18) ||
        (maxAge != null && profile.age > maxAge!) ||
        (where == ZyraBrowseWhere.country &&
            profile.residenceCountryCode != countryCode) ||
        (nationalityCodes.isNotEmpty &&
            !nationalityCodes.contains(profile.nationalityCode)) ||
        (ethnicityCodes.isNotEmpty &&
            !ethnicityCodes.contains(profile.ethnicityCode))) {
      return false;
    }
    if (where == ZyraBrowseWhere.nearMe) {
      final point =
          profile.sampleLatitude == null || profile.sampleLongitude == null
          ? null
          : ZyraBrowsePoint(profile.sampleLatitude!, profile.sampleLongitude!);
      final distance = zyraBrowseDistanceKm(origin, point);
      if (distance == null || distance > radiusKm) return false;
    }
    return true;
  }

  /// Keeps the caller's exclusions, stable order, and detached output.
  List<DraftProfile> apply(Iterable<DraftProfile> eligible) =>
      List.unmodifiable(eligible.where(matches));

  ZyraBrowseFilter _copy({
    int? minimum,
    int? maximum,
    bool age = false,
    ZyraBrowseWhere? mode,
    String? country,
    Set<String>? nationalities,
    Set<String>? ethnicities,
    double? radius,
    ZyraBrowsePoint? from,
    bool changeOrigin = false,
  }) => ZyraBrowseFilter(
    minAge: age ? minimum : minAge,
    maxAge: age ? maximum : maxAge,
    where: mode ?? where,
    countryCode: country ?? countryCode,
    nationalityCodes: Set.unmodifiable(nationalities ?? nationalityCodes),
    ethnicityCodes: Set.unmodifiable(ethnicities ?? ethnicityCodes),
    radiusKm: radius ?? radiusKm,
    origin: changeOrigin ? from : origin,
  );

  ZyraBrowseFilter detached() => _copy();
  ZyraBrowseFilter withOrigin(ZyraBrowsePoint? value) =>
      _copy(from: value, changeOrigin: true);

  ZyraBrowseFilter withAge(int? minimum, int? maximum) =>
      _copy(minimum: minimum, maximum: maximum, age: true);
  ZyraBrowseFilter withWhere(ZyraBrowseWhere value) => _copy(mode: value);
  ZyraBrowseFilter withCountry(String value) => _copy(country: value);
  ZyraBrowseFilter withNationalities(Set<String> values) =>
      _copy(nationalities: values);
  ZyraBrowseFilter withEthnicities(Set<String> values) =>
      _copy(ethnicities: values);
  ZyraBrowseFilter withRadius(double value, {ZyraBrowsePoint? from}) =>
      _copy(radius: value, from: from ?? origin, changeOrigin: true);
}
