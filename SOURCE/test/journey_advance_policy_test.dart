import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_advance_policy.dart';

void main() {
  group('Journey stalled-transition retry policy', () {
    test('never auto-retries Guardian Gate', () {
      expect(
        ZyraJourneyAdvancePolicy.shouldRetryStalled(
          stage: 'wali_gate',
          reason: null,
        ),
        isFalse,
      );
      expect(
        ZyraJourneyAdvancePolicy.shouldRetryStalled(
          stage: 'wali_gate',
          reason: 'guardian_required_other',
        ),
        isFalse,
      );
    });

    test('retries only chosen Salam and Compatibility waits', () {
      for (final stage in const ['salam_exchange', 'compatibility_reveal']) {
        expect(
          ZyraJourneyAdvancePolicy.shouldRetryStalled(
            stage: stage,
            reason: 'waiting_for_continue',
          ),
          isTrue,
        );
        expect(
          ZyraJourneyAdvancePolicy.shouldRetryStalled(
            stage: stage,
            reason: null,
          ),
          isFalse,
        );
      }
    });

    test('does not auto-advance later chapters', () {
      expect(
        ZyraJourneyAdvancePolicy.shouldRetryStalled(
          stage: 'phase_1',
          reason: 'waiting_for_continue',
        ),
        isFalse,
      );
    });
  });
}
