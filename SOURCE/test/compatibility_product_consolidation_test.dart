import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/services/zyra_unlock_service.dart';

void main() {
  test(
    'one current product uses full-detail authority, not earlier overall',
    () {
      expect(ZyraUnlockService.currentTier, UnlockTier.plus);
      expect(ZyraUnlockService.currentTier.dbValue, 'paid_plus_single');
      expect(UnlockTier.standard.dbValue, 'paid_single');
      expect(
        UnlockTier.values,
        hasLength(2),
        reason: 'Preserve ledger history.',
      );
    },
  );

  test(
    'merging the product does not activate the full-detail spending fuse',
    () {
      expect(ZyraUnlockService.categoryBreakdownAvailable, isFalse);
      expect(
        ZyraUnlockService.isTierAvailable(ZyraUnlockService.currentTier),
        isFalse,
      );
    },
  );

  test('single, three and five-packs share one approved current catalogue', () {
    expect(ZyraMembershipCatalog.compatibilitySinglePence, 299);
    expect(ZyraMembershipCatalog.compatibilityThreePence, 699);
    expect(ZyraMembershipCatalog.compatibilityFivePence, 999);
    expect(
      ZyraMembershipCatalog.compatibilityPrices,
      'Compatibility Unlocks: £2.99 for one, £6.99 for three or £9.99 for five.',
    );
    expect(
      ZyraMembershipCatalog.compatibilityTerms,
      contains('optional purchase'),
    );
    expect(ZyraMembershipCatalog.checkoutAvailable, isFalse);
  });

  test(
    'ordinary uncertain full-reveal recovery cannot accept an old overall row',
    () {
      final source = File(
        'lib/screens/subscription/profile_unlock_screen.dart',
      ).readAsStringSync();
      final start = source.indexOf('Future<void> _checkUnlockAccess()');
      final end = source.indexOf('/// Founder-authorized demonstration', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final recovery = source.substring(start, end);
      expect(recovery, contains('ZyraUnlockService.currentTier'));
      // The independent old overall grant may be read for its numeric result,
      // but only the full product can clear an uncertain full-reveal spend.
      final confirmed = recovery.substring(
        recovery.indexOf('final confirmed ='),
        recovery.indexOf('setState(()', recovery.indexOf('final confirmed =')),
      );
      expect(confirmed, contains('ZyraUnlockService.isUnlocked('));
      expect(confirmed, contains('ZyraUnlockService.currentTier'));
      expect(confirmed, isNot(contains('UnlockTier.standard')));
      expect(
        recovery,
        contains('_needsRecovery = recoveringSpend && !confirmed'),
      );
      expect(recovery, isNot(contains('ZyraUnlockService.unlock(')));
    },
  );

  test('ordinary new reveal never falls back to an earlier overall credit', () {
    final source = File(
      'lib/screens/subscription/profile_unlock_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('Future<void> _unlock()');
    final end = source.indexOf('Future<void> _checkUnlockAccess()', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final spend = source.substring(start, end);
    expect(spend, contains('const tier = ZyraUnlockService.currentTier'));
    expect(spend, contains('!(_route?.isCurrent ?? false)'));
    expect(
      spend,
      contains('if (!ZyraUnlockService.isTierAvailable(tier)) return;'),
    );
    expect(spend, isNot(contains('UnlockTier.standard')));
    expect(source, isNot(contains('_tierToSpend')));
  });
}
