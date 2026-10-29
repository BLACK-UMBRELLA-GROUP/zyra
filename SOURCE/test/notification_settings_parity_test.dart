import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/notification_settings_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_notification_prefs_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  Map<ZyraNotifyCategory, bool> values() => {
    for (final category in ZyraNotifyCategory.values)
      category: !category.isConsent,
  };

  test(
    'local preview has safe defaults and mutable isolated preferences',
    () async {
      ZyraInternalPreviewClient.beginPreview();
      addTearDown(ZyraInternalPreviewClient.finishSignOut);

      final initial = await ZyraNotificationPrefsService.fetch();
      expect(initial, isNotNull);
      expect(initial![ZyraNotifyCategory.matchesJourneys], isTrue);
      expect(initial[ZyraNotifyCategory.marketingEmails], isFalse);

      expect(
        await ZyraNotificationPrefsService.set(
          ZyraNotifyCategory.marketingEmails,
          true,
        ),
        isTrue,
      );
      final changed = await ZyraNotificationPrefsService.fetch();
      expect(changed![ZyraNotifyCategory.marketingEmails], isTrue);
    },
  );

  testWidgets('Seeker renders and saves the persisted category order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final saved = <(ZyraNotifyCategory, bool)>[];
    Future<bool> save(ZyraNotifyCategory category, bool enabled) async {
      saved.add((category, enabled));
      return true;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(
          loadPreferences: () async => values(),
          savePreference: save,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('SERVICE NOTIFICATIONS'), findsOneWidget);
    expect(find.text('MARKETING'), findsOneWidget);
    expect(find.text('ACCOUNT & SAFETY', skipOffstage: false), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(saved.single, (ZyraNotifyCategory.matchesJourneys, false));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an unacknowledged persisted write requires an authoritative reload',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationSettingsScreen(
            loadPreferences: () async => values(),
            savePreference: (_, _) async => false,
          ),
        ),
      );
      await tester.pump();
      final first = find.byType(Switch).first;
      expect(tester.widget<Switch>(first).value, isTrue);
      await tester.tap(first);
      await tester.pump();
      expect(find.byType(Switch), findsNothing);
      expect(
        find.textContaining("We couldn't confirm this change."),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    },
  );

  testWidgets('incomplete consent data fails closed instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(
          loadPreferences: () async => {
            ZyraNotifyCategory.matchesJourneys: true,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("We couldn't load your preferences."), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('loading and saving exceptions leave a retryable honest state', (
    tester,
  ) async {
    var loadFails = true;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(
          loadPreferences: () async {
            if (loadFails) throw StateError('offline');
            return values();
          },
          savePreference: (_, _) async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("We couldn't load your preferences."), findsOneWidget);

    loadFails = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    final first = find.byType(Switch).first;
    expect(tester.widget<Switch>(first).value, isTrue);
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsNothing);
    expect(
      find.textContaining("We couldn't confirm this change."),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('stale account preference read never publishes old switches', (
    tester,
  ) async {
    final pending = Completer<Map<ZyraNotifyCategory, bool>?>();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(loadPreferences: () => pending.future),
      ),
    );
    await tester.pump();
    // Generation changes even when the next login uses the same account ID.
    ZyraAccountState.resetForTesting();
    pending.complete(values());
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(find.text("We couldn't load your preferences."), findsOneWidget);
    // A stale route is terminally withdrawn, not a retry surface for B.
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('stale account save discards the old consent UI outcome', (
    tester,
  ) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(
          loadPreferences: () async => values(),
          savePreference: (_, _) => pending.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    ZyraAccountState.resetForTesting();
    pending.complete(false);
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(find.text("That didn't save. Please try again."), findsNothing);
    expect(find.text("We couldn't load your preferences."), findsOneWidget);
  });
}
