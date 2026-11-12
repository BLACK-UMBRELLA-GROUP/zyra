import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_compatibility_area.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/services/zyra_unlock_service.dart';

void main() {
  testWidgets('real area rows show locked or unavailable without scores', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final unlocked in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: 320,
                    child: buildZyraCompatibilityBreakdownTestSurface(
                      unlocked: unlocked,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('compatibility-detail-unavailable')),
          findsOneWidget,
        );
        final status = unlocked ? 'Not enough answers' : 'Locked';
        final other = unlocked ? 'Locked' : 'Not enough answers';
        double previousTop = -1;
        for (final area in ZyraCompatibilityArea.values) {
          final row = find.byKey(
            ValueKey('compatibility-area-row-${area.name}'),
          );
          expect(row, findsOneWidget);
          expect(tester.getTopLeft(row).dy, greaterThan(previousTop));
          previousTop = tester.getTopLeft(row).dy;
          expect(
            find.descendant(of: row, matching: find.text(area.label)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: row, matching: find.text(status)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: row, matching: find.text(other)),
            findsNothing,
          );
        }
        expect(find.textContaining('%'), findsNothing);
        expect(
          find.bySemanticsLabel(RegExp(r'\d+\s*(?:%|percent)')),
          findsNothing,
        );
        for (final band in const ['Strong', 'Good', 'Some differences']) {
          expect(find.text(band), findsNothing);
        }
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  test('unified full reveal uses the held Plus entitlement', () {
    expect(ZyraUnlockService.currentTier, UnlockTier.plus);
    expect(ZyraUnlockService.currentTier.dbValue, 'paid_plus_single');
    expect(ZyraUnlockService.isTierAvailable(UnlockTier.standard), isTrue);
    expect(
      ZyraUnlockService.isTierAvailable(ZyraUnlockService.currentTier),
      isFalse,
    );
  });

  test(
    'ordinary full unlock recovery never accepts earlier overall access',
    () {
      final source = File(
        'lib/screens/subscription/profile_unlock_screen.dart',
      ).readAsStringSync();
      final recovery = source
          .split('Future<void> _checkUnlockAccess() async {')
          .last
          .split('/// Founder-authorized demonstration')
          .first;
      expect(recovery, contains('ZyraUnlockService.currentTier'));
      final confirmation = recovery
          .split('final confirmed =')
          .last
          .split('setState(()')
          .first;
      expect(confirmation, contains('ZyraUnlockService.isUnlocked('));
      expect(confirmation, contains('ZyraUnlockService.currentTier'));
      expect(confirmation, isNot(contains('UnlockTier.standard')));
      expect(
        recovery,
        contains('_needsRecovery = recoveringSpend && !confirmed'),
      );
      expect(recovery, isNot(contains('ZyraUnlockService.unlock(')));
      final spend = source
          .split('Future<void> _unlock() async {')
          .last
          .split('/// Recover a lost acknowledgement')
          .first;
      expect(spend, contains('const tier = ZyraUnlockService.currentTier'));
      expect(spend, contains('!(_route?.isCurrent ?? false)'));
      expect(spend, contains('!ZyraUnlockService.isTierAvailable(tier)'));
      expect(spend, isNot(contains('_tierToSpend')));
      expect(spend, isNot(contains('UnlockTier.standard')));
    },
  );
}
