import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/widgets/zyra_account_switch_sheet.dart';

void main() {
  group('account-context switch options', () {
    test('the current context cannot be selected again', () {
      const option = ZyraAccountSwitchOption(
        context: ZyraAccountContext.seeker,
        title: 'Seeker',
        subtitle: 'Your marriage journey',
        icon: Icons.favorite_border,
        current: true,
      );

      expect(option.selectable, isFalse);
      expect(option.resolvedActionLabel, 'CURRENT');
    });

    test(
      'an available second context is selectable without sign-out state',
      () {
        const option = ZyraAccountSwitchOption(
          context: ZyraAccountContext.guardian,
          title: 'Guardian',
          subtitle: 'Supporting Aisha',
          icon: Icons.shield_outlined,
        );

        expect(option.selectable, isTrue);
        expect(option.resolvedActionLabel, 'SWITCH ›');
      },
    );

    test('first-time setup can replace the generic switch action', () {
      const option = ZyraAccountSwitchOption(
        context: ZyraAccountContext.guardian,
        title: 'Guardian',
        subtitle: 'First-time Guardian setup',
        icon: Icons.shield_outlined,
        actionLabel: 'SET UP ›',
      );

      expect(option.selectable, isTrue);
      expect(option.resolvedActionLabel, 'SET UP ›');
    });

    test('an unavailable context fails closed', () {
      const option = ZyraAccountSwitchOption(
        context: ZyraAccountContext.seeker,
        title: 'Seeker',
        subtitle: 'Not activated',
        icon: Icons.favorite_border,
        enabled: false,
      );

      expect(option.selectable, isFalse);
      expect(option.resolvedActionLabel, 'UNAVAILABLE');
    });
  });
}
