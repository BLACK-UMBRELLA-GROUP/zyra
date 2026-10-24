import 'zyra_app_variant.dart';

/// Founder-directed one-app internal TestFlight mode (2026-09-12).
///
/// Off in every ordinary build. The approved archive command must also use
/// Apple's internal-testing-only export option: this flag is not a receipt
/// check and must never be enabled for a public App Store export.
/// Identity pins are public identifiers, not credentials or role grants.
abstract final class ZyraInternalFounderPolicy {
  static const enabled = bool.fromEnvironment('ZYRA_INTERNAL_FOUNDER_ACCESS');
  static const compiledFounderUserId = String.fromEnvironment(
    'ZYRA_INTERNAL_FOUNDER_UUID',
  );
  static const approvedFounderUserId = 'dfcbd00d-bc22-4d6e-999b-3a9264cf3510';
  static const approvedSupabaseUrl = 'https://sxoaxonzjqkgajmlagyk.supabase.co';

  /// Called only with server-refreshed app_metadata, never user_metadata.
  /// The caller also binds its retained proof to the current authenticated user.
  static bool allows({
    required ZyraAppVariant variant,
    required bool internalBuildEnabled,
    required String suppliedFounderUserId,
    required String supabaseUrl,
    required Object? userId,
    required Object? appMetadata,
    required bool claimsAreFresh,
  }) =>
      variant == ZyraAppVariant.production &&
      internalBuildEnabled &&
      claimsAreFresh &&
      suppliedFounderUserId == approvedFounderUserId &&
      supabaseUrl == approvedSupabaseUrl &&
      userId == approvedFounderUserId &&
      appMetadata is Map<String, dynamic> &&
      appMetadata['zyra_role'] == 'founder';
}
