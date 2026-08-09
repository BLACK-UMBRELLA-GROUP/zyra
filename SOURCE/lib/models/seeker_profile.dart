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

  /// 2026-07-26 (Founder, Browse review: "let's try add surname and see
  /// how it looks... put surname under first name, that includes middle
  /// name should anyone have it"). Nullable and deliberately NOT called
  /// `lastName` — it's whatever should render on that second line
  /// (surname, or "middle name + surname" together), a display string
  /// rather than a strict legal-name field.
  ///
  /// UPDATED 2026-07-27: real root cause of "surnames still aren't
  /// showing" (3rd report) — Browse renders whichever candidates
  /// `ZyraDiscoveryService.fetchCandidates()` returns, and since 24 real
  /// seeded `profiles` rows exist today (Amina, Noor, etc.), it was
  /// returning THOSE, not this file's `mockProfiles` — so editing
  /// surnames here never had a visible effect once real data existed.
  /// `profiles` now has a `surname_line` column (added + backfilled for
  /// all seeded rows this same pass — see the Supabase migration and
  /// zyra_discovery_service.dart's updated select/construction), so real
  /// candidates carry a surname too now. What's still genuinely missing:
  /// no onboarding step or profile-settings field lets a real NEW user
  /// enter their own surname yet — tracked as a follow-up Outstanding
  /// Action rather than built silently here, since that's an onboarding
  /// UX addition, not a bug fix.
  final String? surnameLine;

  /// 2026-07-27 (Founder: "zyra one account users can upload a video...
  /// maybe for on account show how the video will look and on the left
  /// side dots area... for a video its a play button"). Mock/UI-demo
  /// only, same honesty scope as `surnameLine` originally was — this is
  /// NOT a real video feature. There is no upload flow, no storage, no
  /// compression, no playback, and no spec document for one (checked;
  /// none exists, contrary beliefs aside — IMAGE_HANDLING_CURRENT_
  /// VERSION_V2.md covers photos only). Null = no video slot. When set,
  /// names which index in [photos] should render as a video slot in the
  /// left-side pagination dots (browse_screen.dart) — that "photo" is
  /// still just a static image URL standing in for a video's poster
  /// frame, purely to demonstrate the play-button dot treatment.
  final int? videoPhotoIndex;

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
    this.surnameLine,
    this.videoPhotoIndex,
    this.alreadyLikedYou = false,
  });

  /// Convenience getter for screens that only ever show one photo
  /// (Matches list tiles, Chat header) — avoids touching every call site.
  String get photoUrl => photos.first;
}

/// Placeholder profile photos (public placeholder image service) so the
/// Browse screen has something to render before real photo storage exists.
final List<SeekerProfile> mockProfiles = [
  // 2026-07-26 (Founder: "we said surnames so change a few users and
  // give them surnames so I can see how it looks") — added to 4 more
  // profiles (Ibrahim deliberately left without one, so both the
  // with/without cases are still visible side by side), a mix of
  // lengths from a short single word to Bilal's existing two-word
  // example, to see how the identity block's second line reads across
  // different cases.
  const SeekerProfile(
    id: '1', firstName: 'Maryam', age: 27, city: 'London', gender: 'female', alreadyLikedYou: true,
    surnameLine: 'Hussain',
    // 2026-07-27 — demonstrates the ZYRA One video-slot play-button dot
    // treatment (see SeekerProfile.videoPhotoIndex's doc comment). Photo
    // index 1 (the middle of these 3) is the mock "video" slot; it's
    // still a static image underneath — this is a visual mockup only.
    videoPhotoIndex: 1,
    photos: ['https://picsum.photos/seed/zyra1a/700/1000', 'https://picsum.photos/seed/zyra1b/700/1000', 'https://picsum.photos/seed/zyra1c/700/1000'],
  ),
  const SeekerProfile(
    id: '2', firstName: 'Yusuf', age: 30, city: 'Birmingham', gender: 'male',
    surnameLine: 'Khan',
    photos: ['https://picsum.photos/seed/zyra2a/700/1000', 'https://picsum.photos/seed/zyra2b/700/1000'],
  ),
  const SeekerProfile(
    id: '3', firstName: 'Aisha', age: 25, city: 'Manchester', gender: 'female', alreadyLikedYou: true,
    surnameLine: 'Begum',
    photos: ['https://picsum.photos/seed/zyra3a/700/1000', 'https://picsum.photos/seed/zyra3b/700/1000', 'https://picsum.photos/seed/zyra3c/700/1000'],
  ),
  const SeekerProfile(
    id: '4', firstName: 'Ibrahim', age: 29, city: 'Leeds', gender: 'male',
    // 2026-07-26 (Founder: "add surnames for everyone please") — this
    // was the one profile deliberately left without one last round, for
    // with/without contrast; completed now that the layout's been seen.
    surnameLine: 'Rashid',
    photos: ['https://picsum.photos/seed/zyra4a/700/1000'],
  ),
  const SeekerProfile(
    id: '5', firstName: 'Zainab', age: 26, city: 'Bristol', gender: 'female',
    surnameLine: 'Iqbal',
    photos: ['https://picsum.photos/seed/zyra5a/700/1000', 'https://picsum.photos/seed/zyra5b/700/1000'],
  ),
  const SeekerProfile(
    id: '6', firstName: 'Bilal', age: 31, city: 'Glasgow', gender: 'male',
    surnameLine: 'Abdul Malik',
    photos: ['https://picsum.photos/seed/zyra6a/700/1000'],
  ),
];
