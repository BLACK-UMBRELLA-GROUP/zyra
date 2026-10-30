import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/theme/zyra_text.dart';

/// The native boundary is mocked; these tests never ask for a permission,
/// authenticate, register push tokens, read photos or start the camera.
class _PhoneAccessNative {
  final calls = <MethodCall>[];
  final statuses = <String, String>{
    for (final permission in ZyraPhonePermission.values)
      permission.name: 'notDetermined',
  };
  final heldStatuses = <Completer<Object?>>[];
  Completer<Object?>? heldRequest;
  Object? statusError;

  Iterable<MethodCall> get requests =>
      calls.where((call) => call.method == 'request');
  Iterable<MethodCall> get settings =>
      calls.where((call) => call.method == 'openSettings');

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraPhoneAccessChannel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'status':
              if (statusError case final Object error) throw error;
              if (heldStatuses.isNotEmpty) {
                return heldStatuses.removeAt(0).future;
              }
              return Map<String, String>.of(statuses);
            case 'request':
              final pending = heldRequest;
              heldRequest = null;
              if (pending != null) return pending.future;
              return Map<String, String>.of(statuses);
            case 'openSettings':
            case 'cancel':
              return null;
            default:
              throw StateError(
                'Unexpected Phone access method: ${call.method}',
              );
          }
        });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraPhoneAccessChannel, null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _PhoneAccessNative native;
  late ZyraAppLock appLock;
  late ZyraPhoneAccessController controller;
  late bool admitted;
  var disposed = false;

  setUp(() {
    ZyraAccountState.resetForTesting();
    native = _PhoneAccessNative()..install();
    admitted = true;
    disposed = false;
    appLock = ZyraAppLock.forTesting(enabled: false);
    controller = ZyraPhoneAccessController(
      canAct: () => admitted,
      appLock: appLock,
    );
  });

  tearDown(() {
    if (!disposed) controller.dispose();
    appLock.dispose();
    native.uninstall();
  });

  testWidgets('opening reads statuses without requesting any capability', (
    tester,
  ) async {
    native.statuses.addAll({
      'location': 'allowed',
      'notifications': 'denied',
      'photos': 'limited',
      'camera': 'notDetermined',
      'faceID': 'allowed',
    });
    await controller.refresh();

    expect(native.calls.map((call) => call.method), everyElement('status'));
    expect(native.calls, isNotEmpty);
    expect(controller.label(ZyraPhonePermission.location), 'While using');
    expect(controller.label(ZyraPhonePermission.notifications), 'Off');
    expect(controller.label(ZyraPhonePermission.photos), 'Selected photos');
    expect(controller.label(ZyraPhonePermission.camera), 'Ask first');
    expect(controller.label(ZyraPhonePermission.faceID), 'Off');
    expect(controller.allowed(ZyraPhonePermission.location), isTrue);
    expect(controller.allowed(ZyraPhonePermission.notifications), isFalse);
    expect(controller.allowed(ZyraPhonePermission.photos), isTrue);
    expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
    expect(controller.allowed(ZyraPhonePermission.faceID), isFalse);
    expect(controller.busy, isFalse);
  });

  testWidgets('all-photo and Camera grants use their locked labels', (
    tester,
  ) async {
    native.statuses.addAll({
      'photos': 'allowed',
      'camera': 'allowed',
      'notifications': 'allowed',
    });
    await controller.refresh();
    expect(controller.label(ZyraPhonePermission.photos), 'All photos');
    expect(controller.label(ZyraPhonePermission.camera), 'Allowed');
    expect(controller.label(ZyraPhonePermission.notifications), 'Allowed');
  });

  for (final status in ['denied', 'restricted']) {
    testWidgets('$status permissions stay Off and never look granted', (
      tester,
    ) async {
      native.statuses.updateAll((_, _) => status);
      await controller.refresh();
      for (final permission in ZyraPhonePermission.values) {
        expect(controller.label(permission), 'Off');
        expect(controller.allowed(permission), isFalse);
      }
    });
  }

  testWidgets('unavailable capabilities stay ungranted and Ask first', (
    tester,
  ) async {
    native.statuses.updateAll((_, _) => 'unavailable');
    await controller.refresh();
    for (final permission in ZyraPhonePermission.values) {
      expect(
        controller.label(permission),
        permission == ZyraPhonePermission.faceID ? 'Off' : 'Ask first',
      );
      expect(controller.allowed(permission), isFalse);
    }
  });

  for (final permission in ZyraPhonePermission.values) {
    testWidgets('${permission.name} first tap requests only that permission', (
      tester,
    ) async {
      await controller.refresh();
      native.calls.clear();
      await controller.activate(permission);

      expect(native.requests, hasLength(1));
      expect(native.requests.single.arguments, {'permission': permission.name});
      expect(native.settings, isEmpty);
      expect(native.calls.first.method, 'status');
      expect(controller.busy, isFalse);
      expect(appLock.enabled, isFalse);
    });
  }

  for (final status in ['allowed', 'denied', 'restricted', 'limited']) {
    testWidgets('an already-asked $status row opens app Settings', (
      tester,
    ) async {
      native.statuses['photos'] = status;
      await controller.refresh();
      native.calls.clear();
      await controller.activate(ZyraPhonePermission.photos);

      expect(native.requests, isEmpty);
      expect(native.settings, hasLength(1));
      expect(native.settings.single.arguments, isNull);
      expect(native.calls.first.method, 'status');
    });
  }

  testWidgets('tap rechecks a stale Ask first before opening Settings', (
    tester,
  ) async {
    await controller.refresh();
    native.statuses['camera'] = 'denied';
    native.calls.clear();
    await controller.activate(ZyraPhonePermission.camera);

    expect(native.calls.first.method, 'status');
    expect(native.requests, isEmpty);
    expect(native.settings, hasLength(1));
    expect(controller.label(ZyraPhonePermission.camera), 'Off');
  });

  testWidgets('a fresh never-asked status permits the actual prompt', (
    tester,
  ) async {
    native.statuses['camera'] = 'denied';
    await controller.refresh();
    native.statuses['camera'] = 'notDetermined';
    native.calls.clear();
    await controller.activate(ZyraPhonePermission.camera);

    expect(native.requests, hasLength(1));
    expect(native.settings, isEmpty);
  });

  testWidgets('a permission reply is followed by a real status read', (
    tester,
  ) async {
    final reply = Completer<Object?>();
    native.heldRequest = reply;
    final action = controller.activate(ZyraPhonePermission.camera);
    await tester.pump();
    expect(native.requests, hasLength(1));
    expect(controller.busy, isTrue);
    native.statuses['camera'] = 'denied';
    // A stale native request result must not override the fresh status read.
    reply.complete({'camera': 'allowed'});
    await tester.pump();
    await action;

    expect(native.calls.last.method, 'status');
    expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
    expect(controller.label(ZyraPhonePermission.camera), 'Off');
    expect(controller.busy, isFalse);
  });

  testWidgets('repeated taps cannot start a second native operation', (
    tester,
  ) async {
    final reply = Completer<Object?>();
    native.heldRequest = reply;
    final first = controller.activate(ZyraPhonePermission.camera);
    await tester.pump();
    await controller.activate(ZyraPhonePermission.photos);
    expect(native.requests, hasLength(1));
    expect(native.settings, isEmpty);
    reply.complete(null);
    await tester.pump();
    await first;
    expect(controller.busy, isFalse);
  });

  for (final error in <Object>[
    MissingPluginException(),
    PlatformException(code: 'permission_unavailable'),
  ]) {
    testWidgets('status failure fails closed: ${error.runtimeType}', (
      tester,
    ) async {
      native.statusError = error;
      await controller.refresh();
      await controller.activate(ZyraPhonePermission.camera);
      expect(native.requests, isEmpty);
      expect(native.settings, isEmpty);
      expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
      expect(controller.busy, isFalse);
    });
  }

  testWidgets('revoked Founder admission blocks all channel actions', (
    tester,
  ) async {
    admitted = false;
    await controller.refresh();
    await controller.activate(ZyraPhonePermission.camera);
    expect(native.calls.where((call) => call.method != 'cancel'), isEmpty);
    expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
  });

  for (final change in ['account', 'admission', 'background', 'dispose']) {
    testWidgets('late status cannot publish after $change', (tester) async {
      final status = Completer<Object?>();
      native.heldStatuses.add(status);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final refresh = controller.refresh();
      await tester.pump();
      switch (change) {
        case 'account':
          ZyraAccountState.resetForTesting();
        case 'admission':
          admitted = false;
          expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
          admitted = true;
        case 'background':
          controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
        case 'dispose':
          controller.dispose();
          disposed = true;
      }
      final beforeLateReply = notifications;
      status.complete({
        for (final permission in ZyraPhonePermission.values)
          permission.name: 'allowed',
      });
      await tester.pump();
      await refresh;

      if (disposed) {
        expect(notifications, beforeLateReply);
      } else {
        expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
      }
    });
  }

  for (final change in ['account', 'admission', 'background']) {
    testWidgets('a cached grant stops being usable after $change', (
      tester,
    ) async {
      native.statuses['camera'] = 'allowed';
      await controller.refresh();
      expect(controller.allowed(ZyraPhonePermission.camera), isTrue);
      switch (change) {
        case 'account':
          ZyraAccountState.resetForTesting();
        case 'admission':
          admitted = false;
        case 'background':
          controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
      }
      expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
      native.calls.clear();
      await controller.activate(ZyraPhonePermission.camera);
      expect(native.requests, isEmpty);
      expect(native.settings, isEmpty);
    });
  }

  for (final change in ['account', 'admission', 'dispose']) {
    testWidgets('a pending native request is cancelled after $change', (
      tester,
    ) async {
      final reply = Completer<Object?>();
      native.heldRequest = reply;
      final action = controller.activate(ZyraPhonePermission.camera);
      await tester.pump();
      expect(native.requests, hasLength(1));
      switch (change) {
        case 'account':
          ZyraAccountState.resetForTesting();
          expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
        case 'admission':
          admitted = false;
          expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
          admitted = true;
        case 'dispose':
          controller.dispose();
          disposed = true;
      }
      await tester.pump();
      expect(native.calls.where((call) => call.method == 'cancel'), isNotEmpty);
      native.statuses['camera'] = 'allowed';
      reply.complete({'camera': 'allowed'});
      await tester.pump();
      await action;
      if (!disposed) {
        expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
      }
    });
  }

  testWidgets('obsolete controller cannot cancel its replacement request', (
    tester,
  ) async {
    final old = controller;
    controller = ZyraPhoneAccessController(
      canAct: () => admitted,
      appLock: appLock,
    );
    // Replacing the owner may cancel its old operation. Observe only calls
    // made after the replacement starts its own native permission request.
    await tester.pump();
    native.calls.clear();
    final reply = Completer<Object?>();
    native.heldRequest = reply;
    final action = controller.activate(ZyraPhonePermission.camera);
    await tester.pump();
    expect(native.requests, hasLength(1));
    expect(controller.busy, isTrue);
    final beforeObsoleteActions = native.calls.length;

    await old.activate(ZyraPhonePermission.photos);
    old.dispose();
    await old.activate(ZyraPhonePermission.notifications);
    await tester.pump();
    expect(native.calls, hasLength(beforeObsoleteActions));
    expect(native.calls.where((call) => call.method == 'cancel'), isEmpty);
    expect(native.requests, hasLength(1));
    expect(controller.busy, isTrue);

    native.statuses['camera'] = 'allowed';
    reply.complete({'camera': 'allowed'});
    await tester.pump();
    await action;
    expect(controller.allowed(ZyraPhonePermission.camera), isTrue);
    expect(controller.label(ZyraPhonePermission.camera), 'Allowed');
    expect(controller.busy, isFalse);
    expect(native.calls.last.method, 'status');
  });

  testWidgets('temporary permission-sheet inactivity preserves the request', (
    tester,
  ) async {
    final reply = Completer<Object?>();
    native.heldRequest = reply;
    final action = controller.activate(ZyraPhonePermission.camera);
    await tester.pump();
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    native.statuses['camera'] = 'allowed';
    reply.complete({'camera': 'allowed'});
    await tester.pump();
    await action;
    expect(native.calls.where((call) => call.method == 'cancel'), isEmpty);
    expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
    native.calls.clear();
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(native.calls.map((call) => call.method), everyElement('status'));
    expect(controller.allowed(ZyraPhonePermission.camera), isTrue);
  });

  testWidgets('background cancels a pending prompt and drops its late grant', (
    tester,
  ) async {
    final reply = Completer<Object?>();
    native.heldRequest = reply;
    final action = controller.activate(ZyraPhonePermission.camera);
    await tester.pump();
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump();
    expect(native.calls.where((call) => call.method == 'cancel'), isNotEmpty);
    native.statuses['camera'] = 'allowed';
    reply.complete({'camera': 'allowed'});
    await tester.pump();
    await action;
    expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
  });

  testWidgets('resume rechecks revocation without requesting permission', (
    tester,
  ) async {
    native.statuses['camera'] = 'allowed';
    await controller.refresh();
    controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
    native.statuses['camera'] = 'denied';
    native.calls.clear();
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(native.calls.map((call) => call.method), everyElement('status'));
    expect(native.calls, isNotEmpty);
    expect(controller.label(ZyraPhonePermission.camera), 'Off');
    expect(controller.allowed(ZyraPhonePermission.camera), isFalse);
  });

  testWidgets('Face ID follows real App lock and never toggles it here', (
    tester,
  ) async {
    controller.dispose();
    appLock.dispose();
    appLock = ZyraAppLock.forTesting(enabled: true);
    controller = ZyraPhoneAccessController(
      canAct: () => admitted,
      appLock: appLock,
    );
    native.statuses['faceID'] = 'denied';
    await controller.refresh();
    expect(controller.label(ZyraPhonePermission.faceID), 'On');
    expect(controller.allowed(ZyraPhonePermission.faceID), isTrue);
    await controller.activate(ZyraPhonePermission.faceID);
    expect(native.settings, hasLength(1));
    expect(native.requests, isEmpty);
    expect(appLock.enabled, isTrue);
    var notifications = 0;
    controller.addListener(() => notifications++);
    appLock.clearForSignOut();
    expect(controller.label(ZyraPhonePermission.faceID), 'Off');
    expect(controller.allowed(ZyraPhonePermission.faceID), isFalse);
    expect(notifications, greaterThan(0));
  });

  Future<void> mount(WidgetTester tester, {double width = 430}) async {
    tester.view.physicalSize = Size(width, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ZyraText.useTestFontStubs = true;
    addTearDown(() => ZyraText.useTestFontStubs = false);
    await controller.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraPhoneAccessPresentation(
            controller: controller,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('page uses the five locked explanations and footer', (
    tester,
  ) async {
    await mount(tester);
    for (final text in [
      'Phone access',
      'What ZYRA can use on this phone.',
      'Location',
      'Distance in Filters. Only your approximate area is used — never shown to anyone.',
      'Notifications',
      'Requests, Journey and Guardian updates.',
      'Photos',
      'Choosing your profile photos. ZYRA only sees the ones you pick.',
      'Camera',
      'Scanning ZYRA Codes, taking photos and the identity check.',
      'Face ID',
      'Opening ZYRA when App lock is on.',
      "Your phone decides these. Tap one to change it in your phone's Settings. ZYRA asks for each one only when you first need it.",
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(native.requests, isEmpty);
    expect(native.settings, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Camera row goes straight to the native request, with no sheet', (
    tester,
  ) async {
    await mount(tester);
    native.calls.clear();
    final row = find.byKey(const ValueKey('phone_access_camera'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(native.requests, hasLength(1));
    expect(native.requests.single.arguments, {'permission': 'camera'});
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
