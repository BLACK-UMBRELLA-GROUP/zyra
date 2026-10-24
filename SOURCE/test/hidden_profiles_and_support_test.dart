import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/settings/hidden_profiles_screen.dart';
import 'package:zyra/services/zyra_hidden_profile_store.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_report_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/report_profile_sheet.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

Future<void> _settleUntil(
  WidgetTester tester,
  bool Function() completed,
  String description,
) async {
  for (var frame = 0; frame < 100 && !completed(); frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  expect(
    completed(),
    isTrue,
    reason: '$description did not settle within 100 fake/real async yields.',
  );
}

Future<void> _completeHiddenOperation(
  WidgetTester tester,
  Future<void> Function() operation,
  String description,
) async {
  var completed = false;
  Object? failure;
  StackTrace? failureStack;
  // A completed queue Future still belongs to its original zone. Enqueue
  // from the root zone, then pump the current fake zone before leaving it.
  // Awaiting the old tail inside runAsync would prevent that pump.
  Zone.root.run(() {
    unawaited(
      operation().then<void>(
        (_) => completed = true,
        onError: (Object error, StackTrace stack) {
          failure = error;
          failureStack = stack;
          completed = true;
        },
      ),
    );
  });
  await _settleUntil(tester, () => completed, description);
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
}

Future<void> _disposeAndRehomeHiddenQueue(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await _completeHiddenOperation(
    tester,
    () => ZyraHiddenProfileStore.forget('dev-hidden-queue-drain'),
    'Hidden-profile queue re-homing before fake-zone exit',
  );
}

Future<List<ZyraHiddenProfileRecord>> _hiddenRecords(
  WidgetTester tester,
) async {
  var records = <ZyraHiddenProfileRecord>[];
  await _completeHiddenOperation(tester, () async {
    records = await ZyraHiddenProfileStore.records();
  }, 'Synthetic hidden-profile read');
  return records;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const demo = SeekerProfile(
    id: 'dev-browse-preview-hidden',
    firstName: 'Amira',
    surnameLine: 'Khan',
    age: 28,
    city: 'Manchester',
    gender: 'female',
    photos: ['https://example.com/amira.jpg'],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZyraText.useTestFontStubs = true;
    AppState.instance.clearDecisionsForReset();
  });

  tearDown(() => ZyraText.useTestFontStubs = false);

  void hiddenWidgetTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await _disposeAndRehomeHiddenQueue(tester);
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  test(
    'hidden-profile summaries persist locally and unhide removes them',
    () async {
      await ZyraHiddenProfileStore.remember(demo);

      final stored = await ZyraHiddenProfileStore.records();
      expect(stored, hasLength(1));
      expect(stored.single.id, demo.id);
      expect(stored.single.displayName, 'Amira Khan');
      expect(stored.single.age, 28);
      expect(stored.single.city, 'Manchester');
      expect(stored.single.isDemo, isTrue);

      await ZyraHiddenProfileStore.forget(demo.id);
      expect(await ZyraHiddenProfileStore.records(), isEmpty);
    },
  );

  hiddenWidgetTest(
    'demo reporting completes locally without a Supabase client',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showReportProfileSheet(
                    context,
                    profileId: demo.id,
                    firstName: demo.firstName,
                    profileSnapshot: demo,
                    simulateOnly: true,
                  );
                },
                child: const Text('Open report'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();

      final detail = find.byKey(const ValueKey('report-detail-other'));
      expect(detail, findsOneWidget);
      expect(find.text('Add details (optional)'), findsOneWidget);
      expect(tester.widget<TextField>(detail).decoration?.labelText, isNull);
      expect(
        tester.widget<TextField>(detail).decoration?.hintText,
        'Tell us anything else that would help.',
      );

      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();
      expect(detail, findsNothing);

      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();
      expect(detail, findsOneWidget);
      await tester.enterText(detail, List.filled(300, 'x').join());
      expect(tester.widget<TextField>(detail).controller!.text, hasLength(250));

      await tester.ensureVisible(find.text('Send report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await _settleUntil(
        tester,
        () => find.text('Report sent').evaluate().isNotEmpty,
        'Local report and hidden-profile write',
      );
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.text('Report sent'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect((await _hiddenRecords(tester)).single.id, demo.id);
    },
  );

  hiddenWidgetTest(
    'toggle fixture reporting delegates hide without account writes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      AppState.instance.like(demo);
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showReportProfileSheet(
                    context,
                    profileId: demo.id,
                    firstName: demo.firstName,
                    source: ZyraReportSource.connections,
                    profileSnapshot: demo,
                    simulateOnly: true,
                    applySimulatedHideLocally: false,
                  );
                },
                child: const Text('Open local test report'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open local test report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();
      final send = find
          .widgetWithText(FilledButton, 'Send report')
          .hitTestable();
      expect(send, findsOneWidget);
      await tester.tap(send);
      await _settleUntil(
        tester,
        () => find.text('Report sent').evaluate().isNotEmpty,
        'Fixture report confirmation',
      );
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.text('Report sent'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(await _hiddenRecords(tester), isEmpty);
      expect(
        AppState.instance.outgoingLikes.map((profile) => profile.id),
        contains(demo.id),
      );
    },
  );

  hiddenWidgetTest(
    'Connections Block Hana expands inline and requires confirmation',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showReportProfileSheet(
                    context,
                    profileId: demo.id,
                    firstName: 'Hana',
                    source: ZyraReportSource.connections,
                    profileSnapshot: demo,
                    simulateOnly: true,
                    applySimulatedHideLocally: false,
                  );
                },
                child: const Text('Open Connections report'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Connections report'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Block Hana'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block Hana'));
      await tester.pumpAndSettle();

      expect(find.text('Block Hana?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('report-hide-confirmation')),
        findsOneWidget,
      );
      expect(result, isNull);

      await tester.ensureVisible(
        find.byKey(const ValueKey('report-hide-cancel')),
      );
      await tester.tap(find.byKey(const ValueKey('report-hide-cancel')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('report-hide-confirmation')),
        findsNothing,
      );

      await tester.tap(find.text('Block Hana'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('report-hide-confirm')),
      );
      await tester.tap(find.byKey(const ValueKey('report-hide-confirm')));
      await _settleUntil(
        tester,
        () => result == true,
        'Confirmed fixture hide',
      );
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(await _hiddenRecords(tester), isEmpty);
    },
  );

  hiddenWidgetTest('Hidden Profiles shows identity and confirms local unhide', (
    tester,
  ) async {
    await _completeHiddenOperation(
      tester,
      () => ZyraHiddenProfileStore.remember(demo),
      'Synthetic hidden-profile fixture setup',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HiddenProfilesScreen(loadServerIds: () async => const []),
      ),
    );
    await _settleUntil(
      tester,
      () => find.text('Amira Khan').evaluate().isNotEmpty,
      'Hidden-profile identity load',
    );
    await tester.pumpAndSettle();

    expect(find.text('Hidden Profiles'), findsOneWidget);
    expect(find.text('Amira Khan'), findsOneWidget);
    expect(find.text('28 · Manchester'), findsOneWidget);

    await tester.tap(find.text('Unhide'));
    await tester.pumpAndSettle();
    expect(find.text('Unhide Amira?'), findsOneWidget);
    await tester.tap(find.text('Unhide').last);
    await _settleUntil(
      tester,
      () => find.text('No hidden profiles').evaluate().isNotEmpty,
      'Local unhide and hidden-profile write',
    );
    await tester.pumpAndSettle();

    expect(find.text('No hidden profiles'), findsOneWidget);
    expect(await _hiddenRecords(tester), isEmpty);
  });

  hiddenWidgetTest('Hidden Profiles does not describe a failed read as empty', (
    tester,
  ) async {
    List<String>? ids;
    await tester.pumpWidget(
      MaterialApp(home: HiddenProfilesScreen(loadServerIds: () async => ids)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hidden profiles unavailable'), findsOneWidget);
    expect(find.text('No hidden profiles'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hidden_profiles_empty_viewport')),
      findsNothing,
    );

    ids = const [];
    await tester.tap(find.text('Try again'));
    await _settleUntil(
      tester,
      () => find.text('No hidden profiles').evaluate().isNotEmpty,
      'Hidden-profile retry read',
    );
    await tester.pumpAndSettle();
    expect(find.text('No hidden profiles'), findsOneWidget);
  });

  for (final enlarged in [false, true]) {
    hiddenWidgetTest(
      'confirmed Hidden empty uses a bounded plain state at ${enlarged ? 'compact200' : 'normal'} size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = enlarged
            ? const Size(320, 568)
            : const Size(393, 852);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(enlarged ? 2 : 1)),
              child: child!,
            ),
            home: HiddenProfilesScreen(loadServerIds: () async => const []),
          ),
        );
        await _settleUntil(
          tester,
          () => find.text('No hidden profiles').evaluate().isNotEmpty,
          'Confirmed empty Hidden load',
        );
        await tester.pumpAndSettle();
        final viewport = find.byKey(
          const ValueKey('hidden_profiles_empty_viewport'),
        );
        final empty = find.byKey(
          const ValueKey('hidden_profiles_confirmed_empty'),
        );
        expect(tester.widget(empty), isA<ZyraEmptyState>());
        expect(
          find.descendant(of: empty, matching: find.byType(Container)),
          findsNothing,
        );
        final icon = tester.widget<Icon>(
          find.descendant(of: empty, matching: find.byType(Icon)),
        );
        expect(icon.size, 30);
        expect(icon.color, ZyraColors.ink(.35));
        final scrolling = tester
            .state<ScrollableState>(
              find.descendant(of: viewport, matching: find.byType(Scrollable)),
            )
            .position;
        if (!enlarged) expect(scrolling.maxScrollExtent, 0);
        if (scrolling.maxScrollExtent == 0) {
          final group = find.descendant(
            of: empty,
            matching: find.byType(Column),
          );
          expect(
            tester.getRect(group).center.dy,
            closeTo(tester.getRect(viewport).center.dy, .01),
          );
        }
        final message = find.text(
          'Profiles you hide will appear here, where you can unhide them at any time.',
        );
        await Scrollable.ensureVisible(tester.element(message), alignment: .5);
        await tester.pumpAndSettle();
        expect(message.hitTestable(), findsOneWidget);
        expect(find.text('Try again'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  hiddenWidgetTest(
    'stale account read cannot publish a hidden-profile result',
    (tester) async {
      final ids = Completer<List<String>?>();
      await tester.pumpWidget(
        MaterialApp(
          home: HiddenProfilesScreen(loadServerIds: () => ids.future),
        ),
      );
      await tester.pump();
      ZyraAccountState.resetForTesting();
      ids.complete(const []);
      await tester.pumpAndSettle();

      expect(find.text('No hidden profiles'), findsNothing);
      expect(find.text('Hidden profiles unavailable'), findsOneWidget);
    },
  );

  test(
    'support address, mailto and one-line responsive contract are current',
    () {
      expect(HelpSupportScreen.supportEmail, 'support@zyraconnect.app');
      expect(
        HelpSupportScreen.supportMailto.toString(),
        'mailto:support@zyraconnect.app',
      );

      final source = File(
        'lib/screens/settings/help_support_screen.dart',
      ).readAsStringSync();
      expect(source, contains("ValueKey('help-support-signed-in-line')"));
      expect(source, contains('maxLines: 1'));
      expect(source, contains('overflow: TextOverflow.ellipsis'));
      expect(source, contains('launchUrl('));
      expect(source, isNot(contains('support@zyra.app')));

      final reportSource = File(
        'lib/widgets/report_profile_sheet.dart',
      ).readAsStringSync();
      expect(reportSource, contains('detail: _detailController.text'));
      expect(reportSource, contains('LengthLimitingTextInputFormatter(250)'));
    },
  );
}
