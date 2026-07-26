// Mock Seeker profile model — used by Browse today; will be replaced by
// the real Supabase `profiles`/`seeker_details` read model once the
// backend is wired up (see SYSTEM/DOCUMENTS/ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md).
// Fields limited to what BROWSE_UX_SPEC_CURRENT_VERSION_V1.md's Profile
// Card visible-information table actually shows: photo, first name, age,
// city. compatibility/values/education/career stay hidden by design.
//
// `photos` (2026-07-18): extended to multiple photos per profile after
// reviewing the founder's old Lovable prototype (src/routes/home.tsx) —
// its Browse card supports tap-left/right photo cycling with a side dot
// indicator, which needs more than one photo per candidate to matter.

class SeekerProfile {
  final String id;
  final String firstName;
  final int age;
  final String city;
  final List<String> photos;
  final String gender; // drives ZyraBackgroundVariant on their own onboarding, not used in Browse UI directly

  /// Mock stand-in for "this Seeker has already Liked you" — since there's
  /// no backend, a couple of mock profiles are pre-flagged so a mutual
  /// Like (Match event, per MATCH_UX_SPEC_CURRENT_VERSION_V1.md) is
  /// deterministically reachable for testing rather than random.
  final bool alreadyLikedYou;

  const SeekerProfile({
    required this.id,
    required this.firstName,
    required this.age,
    required this.city,
    required this.photos,
    required this.gender,
    this.alreadyLikedYou = false,
  });

  /// Convenience getter for screens that only ever show one photo
  /// (Matches list tiles, Chat header) — avoids touching every call site.
  String get photoUrl => photos.first;
}

/// Placeholder profile photos (public placeholder image service) so the
/// Browse screen has something to render before real photo storage exists.
final List<SeekerProfile> mockProfiles = [
  const SeekerProfile(
    id: '1', firstName: 'Maryam', age: 27, city: 'London', gender: 'female', alreadyLikedYou: true,
    photos: ['https://picsum.photos/seed/zyra1a/700/1000', 'https://picsum.photos/seed/zyra1b/700/1000', 'https://picsum.photos/seed/zyra1c/700/1000'],
  ),
  const SeekerProfile(
    id: '2', firstName: 'Yusuf', age: 30, city: 'Birmingham', gender: 'male',
    photos: ['https://picsum.photos/seed/zyra2a/700/1000', 'https://picsum.photos/seed/zyra2b/700/1000'],
  ),
  const SeekerProfile(
    id: '3', firstName: 'Aisha', age: 25, city: 'Manchester', gender: 'female', alreadyLikedYou: true,
    photos: ['https://picsum.photos/seed/zyra3a/700/1000', 'https://picsum.photos/seed/zyra3b/700/1000', 'https://picsum.photos/seed/zyra3c/700/1000'],
  ),
  const SeekerProfile(
    id: '4', firstName: 'Ibrahim', age: 29, city: 'Leeds', gender: 'male',
    photos: ['https://picsum.photos/seed/zyra4a/700/1000'],
  ),
  const SeekerProfile(
    id: '5', firstName: 'Zainab', age: 26, city: 'Bristol', gender: 'female',
    photos: ['https://picsum.photos/seed/zyra5a/700/1000', 'https://picsum.photos/seed/zyra5b/700/1000'],
  ),
  const SeekerProfile(
    id: '6', firstName: 'Bilal', age: 31, city: 'Glasgow', gender: 'male',
    photos: ['https://picsum.photos/seed/zyra6a/700/1000'],
  ),
];
