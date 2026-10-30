// Real Flutter shell renders, mocked CoreLocation channel; never an iOS prompt.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_location.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'baseline_capture_support.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK11_LOCATION_2026-10-30';
const capture = bool.fromEnvironment('ZYRA_LOCK11_CAPTURE');
Finder k(String id) => find.byKey(ValueKey(id));
void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  final calls = <String>[];
  var status = 'allowed';
  Completer<Object?>? pending;
  setUp(() {
    calls.clear();
    status = 'allowed';
    pending = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraLocationChannel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'request' =>
              pending == null
                  ? {'status': 'allowed', 'latitude': 53.5, 'longitude': -2.2}
                  : await pending!.future,
            'status' => status,
            _ => null,
          };
        });
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraLocationChannel, null);
  });
  Future<void> openFilters(BaselineHarness h) async {
    await h.tap('concept_browse_menu');
    await h.tester.tapAt(
      h.tester.getCenter(
        find.descendant(
          of: k('concept_browse_options_navigation'),
          matching: k('floating-nav-item-3'),
        ),
      ),
    );
    await h.flush();
  }

  Future<BaselineHarness> mount(WidgetTester t) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final h = BaselineHarness(
      t,
      group: 'lock11_location',
      outputRoot: '$root/PRODUCT/APPROVED/LOCATION/BUILT',
      evidenceRoot: evidence,
      flatOutput: true,
    );
    await h.mount();
    await openFilters(h);
    await h.tap('filter_next');
    await h.tap('concept_where_0');
    expect(find.text('From London (home town)'), findsOneWidget);
    expect(calls, isEmpty);
    return h;
  }

  testWidgets(
    'LOCK11 choose, Not now, Continue, coarse radius and home restore',
    (t) async {
      final h = await mount(t);
      Future<void> cap(String name) async {
        if (capture) {
          await h.capture(
            'filters',
            name,
            name,
            'Actual Flutter sample shell; MOCKED coarse CoreLocation. Not a system prompt.',
            fileName: '$name.png',
          );
        }
      }

      await h.tap('concept_filter_origin');
      expect(
        t.getRect(k('location_sheet_surface')),
        const Rect.fromLTWH(0, 532, 430, 400),
      );
      expect(
        t.widget<Slider>(k('concept_radius')).onChanged,
        isNotNull,
        reason:
            'The barrier blocks interaction without painting disabled controls.',
      );
      expect(find.text('Where should distance start?'), findsOneWidget);
      expect(
        find.text('London — from your profile. No permission needed.'),
        findsOneWidget,
      );
      if (capture) await cap('location__choose_start');
      await h.tap('location_home');
      expect(calls, isEmpty);
      await h.tap('location_current');
      expect(calls, isEmpty);
      expect(
        t.getRect(k('location_sheet_surface')),
        const Rect.fromLTWH(0, 600, 430, 332),
      );
      expect(
        t.getSize(k('location_continue')).height,
        greaterThanOrEqualTo(44),
      );
      await cap('location__explain');
      await h.tap('location_not_now');
      expect(calls, isEmpty);
      await h.tap('concept_filter_origin');
      await h.tap('location_current');
      await h.tap('location_continue');
      expect(calls, ['request', 'status']);
      expect(find.text('From your current area'), findsOneWidget);
      await cap('filters__from_current_area');
      await h.tap('concept_apply_filter');
      expect(
        h.latest.browseFilter.origin!.latitude,
        51.51,
        reason: 'Checkpoints contain the profile town, never device area.',
      );
      expect(find.textContaining('Within 50'), findsNothing);
      expect(find.textContaining('current area'), findsNothing);
      final applied = t.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      expect(applied, isNotNull);
      await h.tap('concept_browse_menu');
      await t.tapAt(
        t.getCenter(
          find.descendant(
            of: k('concept_browse_options_navigation'),
            matching: k('floating-nav-item-3'),
          ),
        ),
      );
      await h.flush();
      await h.tap('filter_next');
      expect(find.text('From your current area'), findsOneWidget);
      await h.tap('concept_filter_origin');
      await h.tap('location_home');
      await h.tap('filter_origin_done');
      expect(find.text('From London (home town)'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      await h.flush();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('deny toast then Settings; stale Continue after Back is inert', (
    t,
  ) async {
    final h = await mount(t);
    status = 'denied';
    await h.tap('concept_filter_origin');
    await h.tap('location_current');
    final old = t.widget<FilledButton>(k('location_continue')).onPressed!;
    await h.tap('location_continue');
    expect(find.text(zyraLocationFallback), findsOneWidget);
    expect(find.text('From London (home town)'), findsOneWidget);
    calls.clear();
    await h.tap('concept_filter_origin');
    await h.tap('location_current');
    expect(calls, ['openSettings']);
    old();
    await h.flush();
    expect(calls, ['openSettings']);
    await t.pumpWidget(const SizedBox.shrink());
    await h.flush();
  });

  testWidgets('late result after Back and re-entry cannot apply', (t) async {
    final h = await mount(t);
    pending = Completer<Object?>();
    await h.tap('concept_filter_origin');
    await h.tap('location_current');
    await h.tap('location_continue');
    await t.binding.handlePopRoute();
    await h.flush();
    pending!.complete({
      'status': 'allowed',
      'latitude': 53.5,
      'longitude': -2.2,
    });
    await h.flush();
    expect(find.text('From your current area'), findsNothing);
    expect(calls, contains('cancel'));
    await t.pumpWidget(const SizedBox.shrink());
    await h.flush();
  });

  testWidgets(
    'controls open/close revokes retained Continue and pending result',
    (t) async {
      final h = await mount(t);
      await h.tap('concept_filter_origin');
      await h.tap('location_current');
      final old = t.widget<FilledButton>(k('location_continue')).onPressed!;
      await openZyraDevControls(t);
      await closeZyraDevControls(t);
      old();
      await h.flush();
      expect(calls, isEmpty);
      await h.tap('concept_filter_origin');
      await h.tap('location_current');
      pending = Completer<Object?>();
      await h.tap('location_continue');
      await openZyraDevControls(t);
      await closeZyraDevControls(t);
      pending!.complete({
        'status': 'allowed',
        'latitude': 53.5,
        'longitude': -2.2,
      });
      await h.flush();
      expect(find.text('From your current area'), findsNothing);
      expect(calls, contains('cancel'));
      await t.pumpWidget(const SizedBox.shrink());
      await h.flush();
    },
  );
  testWidgets(
    'actual admitted host allows inline sheets and revokes covered callbacks',
    (t) async {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      t.view.physicalSize = const Size(1290, 2796);
      t.view.devicePixelRatio = 3;
      final nav = GlobalKey<NavigatorState>();
      final ready = Completer<void>();
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [ZyraDevControlsRouteObserver()],
          home: ViewRequestDraftScreen(
            ownerGeneration: ZyraAccountState.generation,
            ownerId: ZyraAccountState.userId,
            onPresentationReady: () {
              if (!ready.isCompleted) ready.complete();
            },
            initialCheckpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
              tab: 0,
              pages: ['filters'],
            ),
          ),
        ),
      );
      final h = BaselineHarness(t, group: 'admitted', evidenceRoot: evidence);
      for (var i = 0; i < 150 && !ready.isCompleted; i++) {
        await t.pump(const Duration(milliseconds: 20));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
      }
      expect(ready.isCompleted, isTrue);
      await h.flush();
      await openFilters(h);
      await h.tap('filter_next');
      await h.tap('concept_where_0');
      await h.tap('concept_filter_origin');
      await h.tap('location_current');
      expect(k('location_continue'), findsOneWidget);
      final old = t.widget<FilledButton>(k('location_continue')).onPressed!;
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      );
      await h.flush();
      old();
      await h.flush();
      expect(calls, isEmpty);
      nav.currentState!.pop();
      await h.flush();
      old();
      await h.flush();
      expect(calls, isEmpty);
      await t.pumpWidget(const SizedBox.shrink());
      await h.flush();
    },
  );
}
