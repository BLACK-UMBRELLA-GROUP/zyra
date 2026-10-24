// Isolated public settings controls. Injected confirmed reads/writes only;
// no Supabase client, provider, device setting or live consent is touched.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/notification_settings_screen.dart';
import 'package:zyra/screens/settings/privacy_settings_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_notification_prefs_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

Map<ZyraNotifyCategory, bool> _preferences() => {
  for (final category in ZyraNotifyCategory.values) category: false,
};

void _replaceLifetime() {
  ZyraAccountState.resetForTesting();
  AppState.instance.resetForAccountChange();
}

Future<void> _show(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(430, 1450);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.resetForTesting();
  });

  testWidgets(
    'Pause without an SDK cannot create an old-owner write callback',
    (tester) async {
      await _show(tester, const PrivacySettingsScreen());
      final action = tester.widget<FilledButton>(
        find.byKey(const ValueKey('profile-pause-action')),
      );
      expect(action.onPressed, isNull);
      expect(find.byType(Switch), findsNothing);
      _replaceLifetime();
      await tester.pumpAndSettle();
      expect(find.text('Pause status unavailable'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('profile-pause-action')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'old Notifications switch cannot write after its originating lifetime changes',
    (tester) async {
      final saves = <ZyraNotifyCategory>[];
      await _show(
        tester,
        NotificationSettingsScreen(
          loadPreferences: () async => _preferences(),
          savePreference: (category, value) async {
            saves.add(category);
            return true;
          },
        ),
      );
      final action = tester
          .widgetList<Switch>(find.byType(Switch))
          .last
          .onChanged!;
      _replaceLifetime();
      action(true);
      await tester.pumpAndSettle();
      expect(saves, isEmpty);
      expect(find.byType(Switch), findsNothing);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'Notifications holds one write per category before a repaint',
    (tester) async {
      final release = Completer<bool>();
      var saves = 0;
      await _show(
        tester,
        NotificationSettingsScreen(
          loadPreferences: () async => _preferences(),
          savePreference: (category, value) {
            saves++;
            return release.future;
          },
        ),
      );
      final action = tester
          .widgetList<Switch>(find.byType(Switch))
          .last
          .onChanged!;
      action(true);
      action(false);
      await tester.pump();
      release.complete(true);
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'lost preference acknowledgement is unknown, not unchanged consent',
    (tester) async {
      await _show(
        tester,
        NotificationSettingsScreen(
          loadPreferences: () async => _preferences(),
          savePreference: (category, value) async => false,
        ),
      );
      tester.widgetList<Switch>(find.byType(Switch)).last.onChanged!(true);
      await tester.pumpAndSettle();
      expect(find.textContaining('unchanged'), findsNothing);
      expect(find.textContaining('confirm'), findsWidgets);
      expect(find.byType(Switch), findsNothing);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'unknown acknowledgement cannot reload ahead of another dispatched write',
    (tester) async {
      final firstCommit = Completer<bool>();
      final secondAcknowledgement = Completer<bool>();
      final server = _preferences();
      var reads = 0;
      var saves = 0;
      await _show(
        tester,
        NotificationSettingsScreen(
          loadPreferences: () async {
            reads++;
            return Map.of(server);
          },
          savePreference: (category, value) async {
            saves++;
            if (category == ZyraNotifyCategory.matchesJourneys) {
              final result = await firstCommit.future;
              if (result) server[category] = value;
              return result;
            }
            return secondAcknowledgement.future;
          },
        ),
      );
      final actions = tester.widgetList<Switch>(find.byType(Switch)).toList();
      final firstAction = actions.first.onChanged!;
      firstAction(true);
      actions.last.onChanged!(true);
      await tester.pump();
      secondAcknowledgement.complete(false);
      await tester.pumpAndSettle();
      expect(saves, 2);
      expect(reads, 1);
      expect(find.byType(Switch), findsNothing);
      final retry = find.text('Try again');
      if (retry.evaluate().isNotEmpty) await tester.tap(retry);
      firstAction(false);
      await tester.pumpAndSettle();
      expect(reads, 1, reason: 'No read may race an already dispatched write.');
      expect(
        saves,
        2,
        reason: 'The pending first category still owns its flight.',
      );
      firstCommit.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(
        tester.widgetList<Switch>(find.byType(Switch)).first.value,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  // Confirmed Pause write/readback and actor races now use intercepted RPCs
  // in privacy_settings_truth_test and profile_pause_settings_test. A local
  // injected visibility bool is no longer allowed to certify global privacy.
  testWidgets(
    'Pause without a confirmed owner keeps retry and mutation unavailable',
    (tester) async {
      await _show(tester, const PrivacySettingsScreen());
      expect(find.text('Pause status unavailable'), findsOneWidget);
      expect(find.text('Profile active'), findsNothing);
      expect(find.text('Profile paused'), findsNothing);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('profile-pause-retry')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('profile-pause-action')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'owned Notifications save keeps its acknowledged value',
    (tester) async {
      final saves = <bool>[];
      await _show(
        tester,
        NotificationSettingsScreen(
          loadPreferences: () async => _preferences(),
          savePreference: (category, value) async {
            saves.add(value);
            return true;
          },
        ),
      );
      tester.widgetList<Switch>(find.byType(Switch)).last.onChanged!(true);
      await tester.pumpAndSettle();
      expect(saves, [true]);
      expect(tester.widgetList<Switch>(find.byType(Switch)).last.value, isTrue);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}
