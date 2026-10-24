import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/screens/profile/profile_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_account_switch_sheet.dart';

void main() {
  group('account-context switch options', () {
    test('identity is shared while plans and activity stay separate', () {
      expect(
        ZyraAccountContextPolicy.sharedSummary,
        contains('identity check'),
      );
      expect(
        ZyraAccountContextPolicy.separateSummary,
        allOf(contains('activity'), contains('memberships')),
      );
    });

    test('the current context cannot be selected again', () {
      const option = ZyraAccountSwitchOption(
        context: ZyraAccountContext.seeker,
        title: 'Seeker',
        subtitle: 'Your marriage journey',
        icon: Icons.person_outline,
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
        icon: Icons.person_outline,
        enabled: false,
      );

      expect(option.selectable, isFalse);
      expect(option.resolvedActionLabel, 'UNAVAILABLE');
    });
  });

  testWidgets('Founder Seeker Profile exposes the account switcher', (
    tester,
  ) async {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(
      name: 'Adam',
      gender: 'male',
      plan: ZyraPlan.one,
    );
    addTearDown(() {
      ZyraInternalPreviewClient.finishSignOut();
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
      AppState.instance.resetForAccountChange();
      ZyraText.useTestFontStubs = false;
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileScreen())),
    );
    await tester.tap(find.byKey(const ValueKey('switch-account-button')));
    await tester.pumpAndSettle();

    expect(find.byType(ZyraAccountSwitchScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('switch-account-back')), findsOneWidget);
    expect(find.text('Switch Account'), findsOneWidget);
    expect(find.text('Seeker Account'), findsOneWidget);
    expect(find.text('Guardian Account'), findsOneWidget);
    expect(find.text(ZyraAccountContextPolicy.sharedSummary), findsOneWidget);
    expect(find.text(ZyraAccountContextPolicy.separateSummary), findsOneWidget);
  });
}
