import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/services/zyra_unlock_service.dart';

void main() {
  testWidgets('Exact Trio stays visible without invented percentages', (
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
                body: SizedBox(
                  width: 320,
                  child: buildZyraCompatibilityBreakdownTestSurface(
                    unlocked: unlocked,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Aligned'), findsOneWidget);
        expect(find.text('Discuss'), findsOneWidget);
        expect(find.text('Opposed'), findsOneWidget);
        for (final category in const [
          'Lifestyle',
          'Work & Education',
          'Family Values',
          'Marriage Goals',
          'Personality',
          'Deen',
        ]) {
          expect(find.text(category), findsOneWidget);
          expect(
            find.bySemanticsLabel(
              '$category, detailed compatibility not available',
            ),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(const ValueKey('compatibility-detail-unavailable')),
          findsOneWidget,
        );
        expect(find.text('—'), findsNWidgets(18));
        expect(find.textContaining('%'), findsNothing);
        expect(
          find.byKey(const ValueKey('compatibility-rail-Lifestyle-aligned')),
          findsNothing,
        );

        final deen = tester.widget<Container>(
          find.byKey(const ValueKey('compatibility-exact-row-Deen')),
        );
        expect(deen.decoration, isNull);
        expect(find.byType(Divider), findsOneWidget);
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
