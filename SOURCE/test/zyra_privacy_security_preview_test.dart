import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_privacy_security_preview.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_notification_privacy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets(
    'hidden and blocked use first name, date and an explicit confirm',
    (tester) async {
      final unblocked = <String>[];
      final shown = <String>[];
      await mount(
        tester,
        ZyraPrivacySecurityPreview(
          page: ZyraPrivacySecurityPage.hiddenBlocked,
          blocked: const [
            ZyraPrivacyPerson(id: 'z', firstName: 'Zainab', date: '12 Nov'),
          ],
          hidden: const [
            ZyraPrivacyPerson(id: 'h', firstName: 'Hana', date: '18 Nov'),
          ],
          onUnblock: unblocked.add,
          onShowAgain: shown.add,
        ),
      );
      expect(find.text('Blocked 12 Nov'), findsOneWidget);
      expect(find.text('Hidden 18 Nov'), findsOneWidget);
      expect(find.textContaining('Journey Bio'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('privacy_unblock_z')));
      await tester.pumpAndSettle();
      expect(unblocked, isEmpty);
      await tester.tap(find.byKey(const ValueKey('privacy_keep_blocked')));
      await tester.pumpAndSettle();
      expect(unblocked, isEmpty);
      await tester.tap(find.byKey(const ValueKey('privacy_unblock_z')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('privacy_confirm_unblock')));
      await tester.pumpAndSettle();
      expect(unblocked, ['z']);
      await tester.tap(find.byKey(const ValueKey('privacy_show_h')));
      expect(shown, ['h']);
    },
  );

  testWidgets('App lock choices and sign-in devices have their local states', (
    tester,
  ) async {
    await mount(
      tester,
      const ZyraPrivacySecurityPreview(
        page: ZyraPrivacySecurityPage.appLock,
        lockEnabled: true,
        lockDelay: 'one_minute',
      ),
    );
    expect(find.text('1 minute'), findsOneWidget);
    expect(find.text('15 minutes'), findsOneWidget);
    expect(find.text('Hide ZYRA in the app switcher'), findsOneWidget);
    expect(find.text('Hide message text in notifications'), findsOneWidget);
    await mount(
      tester,
      const ZyraPrivacySecurityPreview(
        page: ZyraPrivacySecurityPage.signIn,
        otherDevicesPresent: false,
      ),
    );
    expect(find.text('Only this phone is signed in.'), findsOneWidget);
    expect(find.text('Sign out all other devices'), findsNothing);
  });

  testWidgets(
    'narrow Larger Text keeps lock choices and phone privacy readable',
    (tester) async {
      await mount(
        tester,
        const ZyraPrivacySecurityPreview(
          page: ZyraPrivacySecurityPage.appLock,
          lockEnabled: true,
        ),
      );
      tester.view.physicalSize = const Size(1125, 2001);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('privacy_lock_delay_one_hour')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1 hour'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('privacy_hide_message_text')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Hide message text in notifications'), findsOneWidget);
    },
  );

  test(
    'privacy switches persist for their owner and redact message text',
    () async {
      SharedPreferences.setMockInitialValues({});
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount('owner-a');
      expect(ZyraLocalPrefs.switcherCoverEnabled, isTrue);
      expect(ZyraLocalPrefs.messageTextHidden, isTrue);
      expect(
        zyraMessageNotificationText(
          'Private words',
          hideMessageText: ZyraLocalPrefs.messageTextHidden,
        ),
        'New message',
      );
      await ZyraLocalPrefs.setSwitcherCoverEnabled(false);
      await ZyraLocalPrefs.setMessageTextHidden(false);
      expect(
        zyraMessageNotificationText(
          'Private words',
          hideMessageText: ZyraLocalPrefs.messageTextHidden,
        ),
        'Private words',
      );
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount('owner-a');
      expect(ZyraLocalPrefs.switcherCoverEnabled, isFalse);
      expect(ZyraLocalPrefs.messageTextHidden, isFalse);
      await ZyraLocalPrefs.bindAccount('owner-b');
      expect(ZyraLocalPrefs.switcherCoverEnabled, isTrue);
      expect(ZyraLocalPrefs.messageTextHidden, isTrue);
    },
  );
}
