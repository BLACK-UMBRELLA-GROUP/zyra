import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/services/zyra_local_prefs.dart';

class _PendingNativeReply {
  final started = Completer<void>();
  final reply = Completer<bool>();
}

/// Hold the real plugin method-channel boundaries, not replacement App Lock
/// methods. No native authentication, personal data or real disk is used.
class _NativeAppLockFixture {
  static const authChannel = MethodChannel('plugins.flutter.io/local_auth');
  static const prefsChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );
  static const lockKey = 'flutter.zyra.app_lock_enabled';
  static const ownerKey = 'flutter.zyra.cached_account_owner';

  final preferences = <String, Object>{};
  final lockWrites = <bool>[];
  final _authenticationReplies = <_PendingNativeReply>[];
  final _supportReplies = <_PendingNativeReply>[];
  final _pendingReplies = <_PendingNativeReply>[];
  _PendingNativeReply? _lockWrite;
  int authenticationCalls = 0;
  Map<Object?, Object?>? lastAuthenticationArguments;
  bool authenticateResult = true;
  bool deviceSupported = true;

  _PendingNativeReply holdAuthentication() {
    final pending = _PendingNativeReply();
    _pendingReplies.add(pending);
    _authenticationReplies.add(pending);
    return pending;
  }

  _PendingNativeReply holdSupport() {
    final pending = _PendingNativeReply();
    _pendingReplies.add(pending);
    _supportReplies.add(pending);
    return pending;
  }

  _PendingNativeReply holdLockWrite() {
    final pending = _PendingNativeReply();
    _pendingReplies.add(pending);
    _lockWrite = pending;
    return pending;
  }

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(authChannel, (call) async {
      switch (call.method) {
        case 'authenticate':
          authenticationCalls++;
          lastAuthenticationArguments = Map<Object?, Object?>.from(
            call.arguments as Map,
          );
          if (_authenticationReplies.isEmpty) return authenticateResult;
          final pending = _authenticationReplies.removeAt(0);
          pending.started.complete();
          return pending.reply.future;
        case 'isDeviceSupported':
          if (_supportReplies.isEmpty) return deviceSupported;
          final pending = _supportReplies.removeAt(0);
          pending.started.complete();
          return pending.reply.future;
        default:
          throw StateError('Unexpected local_auth call: ${call.method}');
      }
    });
    messenger.setMockMethodCallHandler(prefsChannel, (call) async {
      if (call.method == 'getAll') {
        return Map<String, Object>.of(preferences);
      }
      final arguments = Map<Object?, Object?>.from(call.arguments as Map);
      final key = arguments['key'] as String;
      if (call.method == 'remove') {
        preferences.remove(key);
        return true;
      }
      if (call.method == 'setBool' || call.method == 'setString') {
        if (key == lockKey) {
          lockWrites.add(arguments['value'] as bool);
          final pending = _lockWrite;
          _lockWrite = null;
          if (pending != null) {
            pending.started.complete();
            if (!await pending.reply.future) return false;
          }
        }
        preferences[key] = arguments['value'] as Object;
        return true;
      }
      throw StateError('Unexpected preferences call: ${call.method}');
    });
  }

  void releasePending() {
    for (final pending in _pendingReplies) {
      if (!pending.reply.isCompleted) pending.reply.complete(false);
    }
  }

  void uninstall() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(authChannel, null);
    messenger.setMockMethodCallHandler(prefsChannel, null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NativeAppLockFixture native;
  final locks = <ZyraAppLock>[];

  ZyraAppLock createLock({bool enabled = true, bool locked = false}) {
    final lock = ZyraAppLock.forTesting(enabled: enabled, locked: locked);
    locks.add(lock);
    return lock;
  }

  setUp(() async {
    native = _NativeAppLockFixture()..install();
    SharedPreferences.resetStatic();
    await ZyraLocalPrefs.init();
    await ZyraLocalPrefs.bindAccount('member-a');
  });

  tearDown(() async {
    native.releasePending();
    await ZyraLocalPrefs.clear();
    for (final lock in locks) {
      lock.dispose();
    }
    locks.clear();
    native.uninstall();
    SharedPreferences.resetStatic();
  });

  test('temporary iOS interruption clears its privacy cover on resume', () {
    final lock = createLock();

    lock.handleLifecycle(AppLifecycleState.inactive);
    expect(lock.isObscured, isTrue);
    expect(lock.isLocked, isFalse);

    lock.handleLifecycle(AppLifecycleState.resumed);
    expect(lock.isObscured, isFalse);
    expect(lock.isLocked, isFalse);
  });

  test('real backgrounding still locks and stays locked on resume', () {
    final lock = createLock();

    lock.handleLifecycle(AppLifecycleState.paused);
    expect(lock.isObscured, isFalse);
    expect(lock.isLocked, isTrue);

    lock.handleLifecycle(AppLifecycleState.resumed);
    expect(lock.isObscured, isFalse);
    expect(lock.isLocked, isTrue);
  });

  test(
    'current enable and disable keep device-passcode and persistence',
    () async {
      final lock = createLock(enabled: false);
      var notifications = 0;
      lock.addListener(() => notifications++);

      expect(await lock.setEnabled(true), isTrue);
      expect(lock.enabled, isTrue);
      expect(lock.isLocked, isFalse);
      expect(ZyraLocalPrefs.appLockEnabled, isTrue);
      expect(native.preferences[_NativeAppLockFixture.lockKey], isTrue);
      expect(native.lastAuthenticationArguments?['biometricOnly'], isFalse);
      expect(native.lastAuthenticationArguments?['stickyAuth'], isTrue);

      expect(await lock.setEnabled(false), isTrue);
      expect(lock.enabled, isFalse);
      expect(ZyraLocalPrefs.appLockEnabled, isFalse);
      expect(native.preferences[_NativeAppLockFixture.lockKey], isFalse);
      expect(native.lockWrites, [true, false]);
      expect(native.authenticationCalls, 2);
      expect(notifications, 2);
    },
  );

  test('failed authentication cannot change or persist the lock', () async {
    final lock = createLock(enabled: false);
    native.authenticateResult = false;
    var notifications = 0;
    lock.addListener(() => notifications++);

    expect(await lock.setEnabled(true), isFalse);
    expect(lock.enabled, isFalse);
    expect(ZyraLocalPrefs.appLockEnabled, isFalse);
    expect(native.lockWrites, isEmpty);
    expect(notifications, 0);
  });

  test('successful old enable cannot revive the lock after sign-out', () async {
    final lock = createLock(enabled: false);
    final pending = native.holdAuthentication();
    final enabling = lock.setEnabled(true);
    await pending.started.future;

    lock.clearForSignOut();
    await ZyraLocalPrefs.clear();
    pending.reply.complete(true);

    expect(await enabling, isFalse);
    expect(lock.enabled, isFalse);
    expect(lock.isLocked, isFalse);
    expect(ZyraLocalPrefs.appLockEnabled, isFalse);
    expect(native.lockWrites, isEmpty);
  });

  test('old disable cannot turn off a replacement account lock', () async {
    await ZyraLocalPrefs.setAppLockEnabled(true);
    final lock = createLock(locked: true);
    final pending = native.holdAuthentication();
    final disabling = lock.setEnabled(false);
    await pending.started.future;

    lock.clearForSignOut();
    await ZyraLocalPrefs.bindAccount('member-b');
    await ZyraLocalPrefs.setAppLockEnabled(true);
    lock.hydrate();
    pending.reply.complete(true);

    expect(await disabling, isFalse);
    expect(lock.enabled, isTrue);
    expect(lock.isLocked, isTrue);
    expect(ZyraLocalPrefs.accountOwner, 'member-b');
    expect(ZyraLocalPrefs.appLockEnabled, isTrue);
    expect(native.lockWrites, [true, true]);
  });

  test('hydrate invalidates an old enable without sign-out', () async {
    final lock = createLock(enabled: false);
    final pending = native.holdAuthentication();
    final enabling = lock.setEnabled(true);
    await pending.started.future;

    lock.hydrate();
    pending.reply.complete(true);

    expect(await enabling, isFalse);
    expect(lock.enabled, isFalse);
    expect(native.lockWrites, isEmpty);
  });

  test('old unlock cannot release replacement locked state', () async {
    await ZyraLocalPrefs.setAppLockEnabled(true);
    final lock = createLock(locked: true);
    final pending = native.holdAuthentication();
    final unlocking = lock.unlock();
    await pending.started.future;

    lock.clearForSignOut();
    await ZyraLocalPrefs.bindAccount('member-b');
    await ZyraLocalPrefs.setAppLockEnabled(true);
    lock.hydrate();
    pending.reply.complete(true);

    expect(await unlocking, isFalse);
    expect(lock.enabled, isTrue);
    expect(lock.isLocked, isTrue);
    expect(lock.isObscured, isFalse);
  });

  test(
    'native prompt remains single-flight across account replacement',
    () async {
      await ZyraLocalPrefs.setAppLockEnabled(true);
      final lock = createLock(locked: true);
      final pending = native.holdAuthentication();
      final oldUnlock = lock.unlock();
      await pending.started.future;

      lock.clearForSignOut();
      await ZyraLocalPrefs.bindAccount('member-b');
      await ZyraLocalPrefs.setAppLockEnabled(true);
      lock.hydrate();
      expect(await lock.unlock(), isFalse);
      expect(await lock.setEnabled(false), isFalse);
      expect(native.authenticationCalls, 1);
      expect(lock.isLocked, isTrue);

      pending.reply.complete(true);
      expect(await oldUnlock, isFalse);
      expect(await lock.unlock(), isTrue);
      expect(native.authenticationCalls, 2);
      expect(lock.isLocked, isFalse);
      expect(ZyraLocalPrefs.appLockEnabled, isTrue);
    },
  );

  test('old support result cannot notify after clearForSignOut', () async {
    final lock = createLock();
    final pending = native.holdSupport();
    var notifications = 0;
    lock.addListener(() => notifications++);
    final checking = lock.checkDeviceSupport();
    await pending.started.future;

    lock.clearForSignOut();
    expect(notifications, 1);
    pending.reply.complete(true);

    expect(await checking, isFalse);
    expect(lock.deviceSupported, isNull);
    expect(notifications, 1);
  });

  test('old support result cannot overwrite a fresh hydrated check', () async {
    final lock = createLock();
    final pending = native.holdSupport();
    final oldCheck = lock.checkDeviceSupport();
    await pending.started.future;

    lock.hydrate();
    native.deviceSupported = false;
    expect(await lock.checkDeviceSupport(), isFalse);
    expect(lock.deviceSupported, isFalse);
    pending.reply.complete(true);

    expect(await oldCheck, isFalse);
    expect(lock.deviceSupported, isFalse);
  });

  test(
    'sign-out during preference await denies old success and notification',
    () async {
      final lock = createLock(enabled: false);
      final pending = native.holdLockWrite();
      var notifications = 0;
      lock.addListener(() => notifications++);
      final enabling = lock.setEnabled(true);
      await pending.started.future;
      expect(lock.enabled, isTrue);

      lock.clearForSignOut();
      final binding = ZyraLocalPrefs.bindAccount('member-b');
      lock.hydrate();
      expect(lock.enabled, isFalse);
      expect(notifications, 1);
      pending.reply.complete(true);

      expect(await enabling, isFalse);
      await binding;
      expect(notifications, 1);
      expect(lock.enabled, isFalse);
      expect(ZyraLocalPrefs.appLockEnabled, isFalse);
      expect(native.preferences[_NativeAppLockFixture.lockKey], isNull);
      expect(native.preferences[_NativeAppLockFixture.ownerKey], 'member-b');
    },
  );

  test(
    'hydrate during preference await preserves the replacement lock',
    () async {
      final lock = createLock(enabled: false);
      final pending = native.holdLockWrite();
      var notifications = 0;
      lock.addListener(() => notifications++);
      final enabling = lock.setEnabled(true);
      await pending.started.future;

      lock.hydrate();
      expect(lock.enabled, isTrue);
      expect(lock.isLocked, isTrue);
      pending.reply.complete(true);

      expect(await enabling, isFalse);
      expect(lock.isLocked, isTrue);
      expect(notifications, 0);
    },
  );

  test('disposed lock ignores pending native unlock and support', () async {
    final lock = createLock(locked: true);
    final authentication = native.holdAuthentication();
    final support = native.holdSupport();
    final unlocking = lock.unlock();
    final checking = lock.checkDeviceSupport();
    await authentication.started.future;
    await support.started.future;

    lock.dispose();
    locks.remove(lock);
    authentication.reply.complete(true);
    support.reply.complete(true);

    expect(await unlocking, isFalse);
    expect(await checking, isFalse);
    expect(lock.isLocked, isTrue);
    expect(lock.deviceSupported, isNull);
    expect(await lock.setEnabled(false), isFalse);
    expect(native.authenticationCalls, 1);
  });
}
