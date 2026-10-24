import '../models/zyra_known_person_code.dart';
import '../services/zyra_wali_link_service.dart';

/// Founder-preview-only discovery codes.
///
/// These values deliberately do not match the live ZYRA Code format. They
/// cannot be stored by the production schema or resolved by the live RPCs.
class ZyraDevPersonalCodeFixtures {
  ZyraDevPersonalCodeFixtures._();

  static const invalidEntryCode = 'ZYRA-0000-0000-0000-0000-0000';
  static const validSeekerEntryCode = 'ZYRA-DEMO-SEEKER-ADAM';
  static const validGuardianEntryCode = 'ZYRA-DEMO-GUARDIAN-IBRAHIM';

  static String validKnownPersonEntryCode({required String? currentGender}) =>
      currentGender == 'female'
      ? 'ZYRA-DEMO-SEEKER-ADAM'
      : 'ZYRA-DEMO-SEEKER-MARYAM';

  static ZyraKnownPersonCodePreview? previewKnownPersonCode(
    String code, {
    required String? currentGender,
  }) {
    if (code.trim().toUpperCase() !=
        validKnownPersonEntryCode(currentGender: currentGender)) {
      return null;
    }
    return currentGender == 'female'
        ? const ZyraKnownPersonCodePreview(
            firstName: 'Adam',
            age: 29,
            city: 'London',
          )
        : const ZyraKnownPersonCodePreview(
            firstName: 'Maryam',
            age: 27,
            city: 'Birmingham',
          );
  }

  static ZyraPersonalCode forPersona({
    required bool asGuardian,
    required String? gender,
  }) {
    final female = gender == 'female';
    return ZyraPersonalCode(
      code: switch ((asGuardian, female)) {
        (false, false) => 'ZYRA-DEMO-SEEKER-ADAM',
        (false, true) => 'ZYRA-DEMO-SEEKER-MARYAM',
        (true, false) => 'ZYRA-DEMO-GUARDIAN-IBRAHIM',
        (true, true) => 'ZYRA-DEMO-GUARDIAN-KHADIJA',
      },
      roleContext: asGuardian ? 'wali' : 'seeker',
    );
  }

  static String validEntryCode({required bool asGuardian}) =>
      asGuardian ? validSeekerEntryCode : validGuardianEntryCode;

  /// Resolves only the deliberate local test counterpart for this role.
  /// Nothing in this namespace is accepted by the live parser or RPC.
  static ZyraPersonalCodePreview? previewEntryCode(
    String code, {
    required bool asGuardian,
  }) {
    if (code.trim().toUpperCase() != validEntryCode(asGuardian: asGuardian)) {
      return null;
    }
    return ZyraPersonalCodePreview(
      firstName: asGuardian ? 'Adam' : 'Ibrahim',
      role: asGuardian ? 'seeker' : 'wali',
    );
  }
}
