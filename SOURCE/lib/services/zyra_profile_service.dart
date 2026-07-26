// Writes the `profiles` row once onboarding has collected the fields
// the schema requires (ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md —
// first_name, date_of_birth, gender are all NOT NULL). Called from
// OnboardingFlow (Seeker, Chapter 1 completion) and WaliOnboardingFlow
// (Wali, onboarding completion).
//
// Guarded by ZyraAuth.isSignedIn throughout this build: if Supabase
// isn't configured, or the user reached onboarding without a real
// session (shouldn't happen in the real flow, but the mock/dev-access
// jump-menu can land here directly for testing), this silently no-ops
// rather than throwing — AppState's in-memory fields keep working
// exactly as before either way.

import '../main.dart';
import 'zyra_auth.dart';

class ZyraProfileService {
  ZyraProfileService._();

  static Future<String?> createSeekerProfile({
    required String firstName,
    required String gender,
    required DateTime dob,
  }) => _createProfile(role: 'seeker', firstName: firstName, gender: gender, dob: dob);

  static Future<String?> createWaliProfile({
    required String firstName,
    required DateTime dob,
  }) =>
      // Wali is, per WALI_ARCHITECTURE_CURRENT_VERSION_V5.md, always a
      // male guardian — gender isn't asked in Wali onboarding, so it's
      // set directly rather than adding a redundant question.
      _createProfile(role: 'wali', firstName: firstName, gender: 'male', dob: dob);

  /// Toggles the signed-in user's own `is_active` flag — the same
  /// column Browse's discovery query already filters on
  /// (zyra_discovery_service.dart: `.eq('is_active', true)`) and that
  /// profiles_select's RLS policy uses to decide whether a row is
  /// visible to anyone other than its owner. Setting this false
  /// genuinely removes the Seeker from Browse for everyone else —
  /// this is real, not cosmetic. Added 2026-07-26 for the Privacy
  /// settings screen (Settings/Search/Notifications build-out).
  /// Returns true on success.
  static Future<bool> setVisibility(bool visible) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      await supabase.from('profiles').update({'is_active': visible}).eq('id', user.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Current `is_active` value for the signed-in user, or null if not
  /// signed in / on any failure (caller should treat null as unknown,
  /// not as a specific value).
  static Future<bool?> fetchVisibility() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;
    try {
      final row = await supabase.from('profiles').select('is_active').eq('id', user.id).maybeSingle();
      return row?['is_active'] as bool?;
    } catch (_) {
      return null;
    }
  }

  /// Returns an error message on failure, or null on success/no-op.
  static Future<String?> _createProfile({
    required String role,
    required String firstName,
    required String gender,
    required DateTime dob,
  }) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null; // not signed in via Supabase — mock-only path, nothing to write

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'role': role,
        'first_name': firstName,
        'date_of_birth': dob.toIso8601String().split('T').first,
        'gender': gender,
      });
      return null;
    } catch (_) {
      return "Something didn't quite work. Please try again — and if it keeps happening, let us know.";
    }
  }
}
