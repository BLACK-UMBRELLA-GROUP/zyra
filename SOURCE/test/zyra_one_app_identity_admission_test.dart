import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_identity_verification.dart';
import 'package:zyra/services/zyra_identity_admission_policy.dart';

void main() {
  test('ordinary existing-account rollout fuse remains explicit', () {
    expect(
      ZyraIdentityAdmissionPolicy.requiresExistingAccountGate(
        productionRolloutEnabled: false,
      ),
      isFalse,
    );
    expect(
      ZyraIdentityAdmissionPolicy.requiresExistingAccountGate(
        productionRolloutEnabled: true,
      ),
      isTrue,
    );
    expect(
      ZyraIdentityAdmissionPolicy.allowsExistingAccountEntry(
        productionRolloutEnabled: false,
        state: null,
      ),
      isTrue,
    );
  });
  test(
    'enabled member gate denies missing state and every non-verified result',
    () {
      expect(
        ZyraIdentityAdmissionPolicy.allowsExistingAccountEntry(
          productionRolloutEnabled: true,
          state: null,
        ),
        isFalse,
      );
      for (final result in ZyraIdentityVerificationResult.values) {
        final state = ZyraIdentityVerificationState(
          result: result,
          duplicateReview: ZyraDuplicateReviewState.clear,
          consentGranted: true,
          consentVersion: 'member-consent',
          consentRecordedAt: DateTime.utc(2026, 9, 12),
          updatedAt: DateTime.utc(2026, 9, 12),
        );
        expect(
          ZyraIdentityAdmissionPolicy.allowsExistingAccountEntry(
            productionRolloutEnabled: true,
            state: state,
          ),
          result == ZyraIdentityVerificationResult.verified,
        );
      }
    },
  );
}
