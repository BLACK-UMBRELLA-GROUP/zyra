// Local notification rows and loader futures only. No notification transport,
// Auth client, read mutation or native action is initialized by these tests.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/notifications/notifications_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_notification_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

const _layoutFont = 'PoppinsNotificationLayoutAudit';

ZyraNotification _notification({bool read = false}) => ZyraNotification(
  id: 'synthetic-owner-notification',
  type: 'new_message',
  title: 'Synthetic opening-owner notification',
  body: 'Synthetic opening-owner body',
  relatedMatchId: null,
  createdAt: DateTime.utc(2026, 10, 18),
  readAt: read ? DateTime.utc(2026, 10, 18) : null,
);

Future<void> _mount(
  WidgetTester tester,
  ZyraNotificationsLoader loader, {
  GlobalKey<NavigatorState>? navigator,
  Size size = const Size(430, 932),
  double textScale = 1,
  bool isTab = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: NotificationsScreen(isTab: isTab, loadNotifications: loader),
    ),
  );
  await tester.pumpAndSettle();
}

VoidCallback _stripAction(WidgetTester tester, String label) => tester
    .widget<InkWell>(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
    )
    .onTap!;

VoidCallback _rowAction(WidgetTester tester) => tester
    .widget<InkWell>(
      find
          .ancestor(
            of: find.text('Synthetic opening-owner notification'),
            matching: find.byType(InkWell),
          )
          .first,
    )
    .onTap!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final reading = FontLoader(_layoutFont);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = null;
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraAccountState.resetForTesting();
  });

  testWidgets('a thrown notification read becomes retryable, not loading', (
    tester,
  ) async {
    var reads = 0;
    await _mount(tester, () async {
      if (++reads == 1) throw StateError('Synthetic unavailable source.');
      return [];
    });
    expect(find.text("Couldn't load notifications"), findsOneWidget);
    expect(find.text('All caught up'), findsNothing);
    tester.widget<ZyraEmptyState>(find.byType(ZyraEmptyState)).onCta!();
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(find.text('All caught up'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'loaded rows and retained selection withdraw on owner epoch change',
    (tester) async {
      var reads = 0;
      await _mount(tester, () async {
        reads++;
        return [_notification()];
      });
      final select = _stripAction(tester, 'Select');
      final markAll = _stripAction(tester, 'Mark all read');
      final longPress = tester
          .widget<InkWell>(
            find
                .ancestor(
                  of: find.text('Synthetic opening-owner notification'),
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .onLongPress!;
      select();
      await tester.pump();
      final row = _rowAction(tester);
      final selectAll = _stripAction(tester, 'Select all');
      ZyraAccountState.resetForTesting();
      AppState.instance.resetForAccountChange();
      await tester.pumpAndSettle();
      expect(find.text('Synthetic opening-owner notification'), findsNothing);
      expect(find.text('Synthetic opening-owner body'), findsNothing);
      expect(find.text("Couldn't load notifications"), findsOneWidget);
      select();
      longPress();
      row();
      selectAll();
      markAll();
      tester.widget<ZyraEmptyState>(find.byType(ZyraEmptyState)).onCta!();
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(find.text('Synthetic opening-owner notification'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('revoked notification route cannot adopt another read source', (
    tester,
  ) async {
    var reads = 0;
    await _mount(tester, () async => [_notification(read: true)]);
    final oldState = tester.state(find.byType(NotificationsScreen));
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          isTab: true,
          loadNotifications: () async {
            reads++;
            return [_notification()];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(NotificationsScreen)), same(oldState));
    expect(reads, 0);
    expect(find.text('Synthetic opening-owner notification'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed notification callbacks cannot mutate or reload', (
    tester,
  ) async {
    var reads = 0;
    await _mount(tester, () async {
      reads++;
      return [_notification()];
    });
    final select = _stripAction(tester, 'Select');
    final markAll = _stripAction(tester, 'Mark all read');
    final longPress = tester
        .widget<InkWell>(
          find
              .ancestor(
                of: find.text('Synthetic opening-owner notification'),
                matching: find.byType(InkWell),
              )
              .first,
        )
        .onLongPress!;
    select();
    await tester.pump();
    final row = _rowAction(tester);
    final selectAll = _stripAction(tester, 'Select all');
    selectAll();
    await tester.pump();
    final markSelected = _stripAction(tester, 'Mark read');
    final cancel = _stripAction(tester, 'Cancel');
    await tester.pumpWidget(const SizedBox.shrink());
    for (final callback in [
      select,
      longPress,
      markAll,
      row,
      selectAll,
      markSelected,
      cancel,
    ]) {
      callback();
    }
    await tester.pump();
    expect(reads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'covered notification actions remain owned by the covered route',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await _mount(tester, () async => [_notification()], navigator: navigator);
      final select = _stripAction(tester, 'Select');
      final markAll = _stripAction(tester, 'Mark all read');
      final row = _rowAction(tester);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: Text('Synthetic covering route')),
        ),
      );
      await tester.pumpAndSettle();
      select();
      markAll();
      row();
      await tester.pump();
      expect(find.text('Synthetic covering route'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Select'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'replaced loader and late old error cannot publish into the route',
    (tester) async {
      final older = Completer<List<ZyraNotification>?>();
      const key = ValueKey('notification-source-race');
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            key: key,
            loadNotifications: () => older.future,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            key: key,
            loadNotifications: () async => [_notification(read: true)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      older.completeError(StateError('Synthetic older read failed.'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic opening-owner notification'), findsNothing);
      expect(find.text("Couldn't load notifications"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposed retry callback cannot start another read', (
    tester,
  ) async {
    var reads = 0;
    await _mount(tester, () async {
      reads++;
      return null;
    });
    final retry = tester
        .widget<ZyraEmptyState>(find.byType(ZyraEmptyState))
        .onCta!;
    await tester.pumpWidget(const SizedBox.shrink());
    retry();
    await tester.pump();
    expect(reads, 1);
    expect(tester.takeException(), isNull);
  });

  for (final isTab in [true, false]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('real Poppins notification controls fit 320px '
          '${isTab ? 'tab' : 'pushed'} at ${scale * 100}%', (tester) async {
        ZyraText.testReadingFontFamily = _layoutFont;
        var reads = 0;
        await _mount(
          tester,
          () async {
            reads++;
            return [_notification(read: true)];
          },
          size: const Size(320, 932),
          textScale: scale,
          isTab: isTab,
        );
        expect(
          tester
              .widget<Text>(find.text('Synthetic opening-owner notification'))
              .style!
              .fontFamily,
          _layoutFont,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Select'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Select all'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final actionRects = <Rect>[];
        for (final label in ['Deselect all', 'Mark read', 'Cancel']) {
          final action = find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first;
          expect(action.hitTestable(), findsOneWidget);
          final rect = tester.getRect(action);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          for (final earlier in actionRects) {
            expect(rect.overlaps(earlier), isFalse);
          }
          actionRects.add(rect);
        }
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Select'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
        expect(reads, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
