import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_identity_verification.dart';

void main() {
  test('app and Active Journey gates remain distinct', () {
    final state = ZyraIdentityVerificationState.fromJson({
      'result': 'verified',
      'duplicate_review_required': null,
      'consent_granted': true,
      'consent_version': 'v1',
      'consent_recorded_at': '2026-08-29T10:00:00Z',
      'updated_at': '2026-08-29T10:01:00Z',
      'decided_at': '2026-08-29T10:01:00Z',
    });

    expect(state.allowsApp, isTrue);
    expect(state.allowsActiveJourney, isFalse);

    final clear = ZyraIdentityVerificationState.fromJson({
      'result': 'verified',
      'duplicate_review_required': false,
      'consent_granted': true,
      'consent_version': 'v1',
      'consent_recorded_at': '2026-08-29T10:00:00Z',
      'updated_at': '2026-08-29T10:01:00Z',
      'decided_at': '2026-08-29T10:01:00Z',
    });

    expect(clear.allowsApp, isTrue);
    expect(clear.allowsActiveJourney, isTrue);
  });

  test('unknown provider state fails closed to retry required', () {
    final state = ZyraIdentityVerificationState.fromJson({
      'result': 'provider_added_a_new_value',
      'duplicate_review_required': false,
      'consent_granted': true,
      'consent_version': 'v1',
      'consent_recorded_at': '2026-08-29T10:00:00Z',
      'updated_at': '2026-08-29T10:01:00Z',
    });

    expect(state.result, ZyraIdentityVerificationResult.retryRequired);
    expect(state.allowsApp, isFalse);
  });
}
