import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/dev/zyra_one_journey_location.dart';
import 'package:zyra/dev/zyra_one_journey_location_sheet.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/services/zyra_account_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  String status = 'allowed';
  Object? reply;
  Completer<Object?>? pending;
  bool admitted = true;
  late ZyraOneJourneyLocation location;
  setUp(() {
    ZyraAccountState.resetForTesting();
    calls.clear();
    status = 'allowed';
    admitted = true;
    pending = null;
    reply = {'status': 'allowed', 'latitude': 53.5, 'longitude': -2.2};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraLocationChannel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'request' => pending == null ? reply : await pending!.future,
            'status' => status,
            _ => null,
          };
        });
    location = ZyraOneJourneyLocation(canAct: () => admitted);
  });
  tearDown(() {
    location.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraLocationChannel, null);
  });

  testWidgets('home town does no channel work; real profile city and radius', (
    t,
  ) async {
    expect(location.point, isNull);
    expect(calls, isEmpty);
    final london = zyraSampleTownPoint('London')!;
    expect(london.latitude, 51.51);
    expect(zyraSampleTownPoint('unknown'), isNull);
    expect(
      zyraBrowseDistanceKm(london, zyraSampleTownPoint('Manchester')),
      closeTo(262, 2),
    );
    final accepted = location.request(() => true);
    await t.pump();
    expect(await accepted, isTrue);
    expect(location.point!.latitude, 53.5);
    expect(calls, ['request', 'status']);
    location.clear();
    expect(location.point, isNull);
  });

  const invalidPayloadCases = [
    'null',
    'missing coordinates',
    'latitude out of range',
    'non-finite latitude',
    'overly precise coordinates',
    'non-numeric latitude',
    'unavailable status',
  ];
  var invalidPayloadIndex = 0;
  for (final payload in <Object?>[
    null,
    {'status': 'allowed'},
    {'status': 'allowed', 'latitude': 91, 'longitude': 0},
    {'status': 'allowed', 'latitude': double.nan, 'longitude': 0},
    {'status': 'allowed', 'latitude': 53.48237, 'longitude': -2.24263},
    {'status': 'allowed', 'latitude': '53.5', 'longitude': -2.2},
    {'status': 'unavailable', 'latitude': 53.5, 'longitude': -2.2},
  ]) {
    final payloadCase = invalidPayloadCases[invalidPayloadIndex++];
    testWidgets('invalid/coarse-boundary reply $payloadCase stays home', (
      t,
    ) async {
      reply = payload;
      final request = location.request(() => true);
      await t.pump();
      expect(await request, isFalse);
      expect(location.point, isNull);
    });
  }
  testWidgets('denial stays home; later explicit attempt opens Settings only', (
    t,
  ) async {
    status = 'denied';
    reply = {'status': 'denied'};
    final first = location.request(() => true);
    await t.pump();
    expect(await first, isFalse);
    expect(location.refused, isTrue);
    calls.clear();
    final later = location.request(() => true);
    await t.pump();
    expect(await later, isFalse);
    expect(calls, ['openSettings']);
  });
  testWidgets('missing plugin and unsupported platform stay home', (t) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          zyraLocationChannel,
          (_) async => throw MissingPluginException(),
        );
    final first = location.request(() => true);
    await t.pump();
    expect(await first, isFalse);
    expect(location.point, isNull);
  });
  for (final reason in [
    'route',
    'background',
    'owner',
    'admission',
    'cancel',
  ]) {
    testWidgets('late fix is dropped after $reason', (t) async {
      pending = Completer<Object?>();
      var route = true;
      final request = location.request(() => route);
      await t.pump();
      switch (reason) {
        case 'route':
          route = false;
        case 'background':
          location.didChangeAppLifecycleState(AppLifecycleState.hidden);
        case 'owner':
          ZyraAccountState.resetForTesting();
        case 'admission':
          admitted = false;
          expect(location.current, isFalse);
          admitted = true;
        case 'cancel':
          location.cancelPending();
      }
      pending!.complete(reply);
      await t.pump();
      expect(await request, isFalse);
      expect(location.point, isNull);
    });
  }
  testWidgets(
    'inactive-only permission wait survives; resume rechecks before using',
    (t) async {
      pending = Completer<Object?>();
      final request = location.request(() => true);
      await t.pump();
      location.didChangeAppLifecycleState(AppLifecycleState.inactive);
      pending!.complete(reply);
      await t.pump();
      expect(location.point, isNull);
      location.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await t.pump();
      expect(await request, isTrue);
      status = 'denied';
      location.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await t.pump();
      expect(location.point, isNull);
    },
  );
  testWidgets('permission recheck rejects late revoked authorization', (
    t,
  ) async {
    pending = Completer<Object?>();
    final request = location.request(() => true);
    await t.pump();
    status = 'restricted';
    pending!.complete(reply);
    await t.pump();
    expect(await request, isFalse);
    expect(location.point, isNull);
  });
  testWidgets(
    'resume withdraws area until delayed permission check completes',
    (t) async {
      final first = location.request(() => true);
      await t.pump();
      expect(await first, isTrue);
      final check = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(zyraLocationChannel, (_) => check.future);
      location.didChangeAppLifecycleState(AppLifecycleState.inactive);
      location.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(location.point, isNull);
      check.complete('denied');
      await t.pump();
      expect(location.point, isNull);
    },
  );
  testWidgets(
    'Settings grant rechecks without fix then permits explicit request',
    (t) async {
      status = 'denied';
      reply = {'status': 'denied'};
      final first = location.request(() => true);
      await t.pump();
      expect(await first, isFalse);
      location.didChangeAppLifecycleState(AppLifecycleState.hidden);
      status = 'allowed';
      reply = {'status': 'allowed', 'latitude': 53.5, 'longitude': -2.2};
      calls.clear();
      location.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await t.pump();
      expect(location.refused, isFalse);
      expect(calls, ['status']);
      expect(location.point, isNull);
      final next = location.request(() => true);
      await t.pump();
      expect(await next, isTrue);
    },
  );
  testWidgets(
    'replacement controller retains its permission handler after old disposal',
    (t) async {
      final old = location;
      location = ZyraOneJourneyLocation(canAct: () => true);
      old.dispose();
      final first = location.request(() => true);
      await t.pump();
      expect(await first, isTrue);
      final done = Completer<void>();
      t.binding.defaultBinaryMessenger.handlePlatformMessage(
        zyraLocationChannel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('permissionChanged', 'denied'),
        ),
        (_) => done.complete(),
      );
      await t.pump();
      await done.future;
      expect(location.point, isNull);
      expect(location.refused, isTrue);
    },
  );
  testWidgets('real-city radius uses coarse point and reverts to home', (
    t,
  ) async {
    final first = location.request(() => true);
    await t.pump();
    expect(await first, isTrue);
    final near = const ZyraBrowseFilter(where: ZyraBrowseWhere.nearMe);
    final manchester = draftProfiles.firstWhere((p) => p.city == 'Manchester');
    final london = draftProfiles.firstWhere((p) => p.city == 'London');
    final home = near.withOrigin(zyraSampleTownPoint('London'));
    expect(home.matches(london), isTrue);
    expect(home.matches(manchester), isFalse);
    final area = near.withOrigin(location.point);
    expect(area.matches(manchester), isTrue);
    expect(area.matches(london), isFalse);
  });
  testWidgets('dispose drops pending result without publishing', (t) async {
    pending = Completer<Object?>();
    var changes = 0;
    location.addListener(() => changes++);
    final first = location.request(() => true);
    await t.pump();
    location.dispose();
    location = ZyraOneJourneyLocation(canAct: () => true);
    pending!.complete(reply);
    await t.pump();
    expect(await first, isFalse);
    expect(changes, 0);
  });
  for (final explain in [false, true]) {
    testWidgets(
      'location sheet wraps and scrolls at 320pt / 2x; explain=$explain',
      (t) async {
        t.view.physicalSize = const Size(320, 700);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        ZyraText.useTestFontStubs = true;
        addTearDown(() => ZyraText.useTestFontStubs = false);
        var invoked = 0;
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 700),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: ZyraOneJourneyLocationSheet(
                  explain: explain,
                  town: 'London',
                  currentArea: false,
                  canAct: () => true,
                  onHome: () {},
                  onCurrent: () {},
                  onContinue: () {},
                  onClose: () => invoked++,
                ),
              ),
            ),
          ),
        );
        await t.pump();
        expect(t.takeException(), isNull);
        final button = find.byKey(
          ValueKey(explain ? 'location_not_now' : 'filter_origin_done'),
        );
        await t.ensureVisible(button);
        await t.tap(button);
        await t.pump();
        expect(invoked, 1);
        expect(t.takeException(), isNull);
        expect(calls, isEmpty);
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test(
    'native privacy contract: exact purpose, reduced accuracy, no full authorization',
    () {
      final native = File(
        'ios/Runner/AppDelegate.swift',
      ).readAsStringSync().split('private final class ZyraRoughLocation').last;
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(
        plist,
        contains(
          'Your approximate area is used to measure distance in Filters. It is never shown to anyone.',
        ),
      );
      expect(
        plist,
        contains('<key>NSLocationDefaultAccuracyReduced</key>\n\t<true/>'),
      );
      expect(native, contains('kCLLocationAccuracyReduced'));
      expect(native, contains('(fix.coordinate.latitude * 10).rounded() / 10'));
      expect(native, contains('manager === active'));
      expect(native, contains('active?.delegate = nil'));
      expect(native, contains('requestWhenInUseAuthorization()'));
      for (final forbidden in [
        'requestAlwaysAuthorization',
        'requestTemporaryFullAccuracy',
        'UserDefaults',
        'print(',
        'NSLog',
        'startUpdatingLocation',
        'saveLocation',
      ]) {
        expect(native, isNot(contains(forbidden)));
      }
    },
  );
}
