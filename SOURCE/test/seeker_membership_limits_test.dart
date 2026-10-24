import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Test double for the app's transitive platform adapter, never a new runtime dependency.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/data/zyra_entitlements.dart';
import 'package:zyra/data/zyra_seeker_plan_limits.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/connections/connections_screen.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/services/zyra_seeker_basic_usage_store.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_membership_history_lock.dart';

class _FailedStore extends InMemorySharedPreferencesStore {
  _FailedStore({required this.throwsError}) : super.empty();
  final bool throwsError;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (throwsError) throw StateError('Synthetic local write failure');
    return false;
  }
}

class _HeldWriteStore extends InMemorySharedPreferencesStore {
  _HeldWriteStore() : super.empty();
  bool holdNextWrite = false;
  final entered = Completer<void>();
  final release = Completer<void>();
  int writeCount = 0;

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    writeCount++;
    if (holdNextWrite) {
      holdNextWrite = false;
      entered.complete();
      await release.future;
    }
    return super.setValue(type, key, value);
  }
}

const _targetId = '11111111-1111-4111-8111-111111111111';
SeekerProfile _profile(String id) => SeekerProfile(
  id: id,
  firstName: 'Maryam',
  age: 27,
  city: 'London',
  photos: const [],
  gender: 'female',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((_) async => http.Response('[]', 200)),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() {
    ZyraText.useTestFontStubs = true;
    AppState.instance.resetForAccountChange();
    AppState.instance.plan = ZyraPlan.basic;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
    SharedPreferences.setMockInitialValues({});
  });

  test('Founder limits and every capped add boundary', () {
    final basic = ZyraSeekerPlanLimits.basic;
    final one = ZyraSeekerPlanLimits.one;
    expect(
      [
        ZyraEntitlements.basic.active,
        ZyraEntitlements.basic.potential,
        ZyraEntitlements.basic.paused,
        ZyraEntitlements.basic.ended,
      ],
      [1, 10, 1, 0],
    );
    expect(
      [
        ZyraEntitlements.one.active,
        ZyraEntitlements.one.potential,
        ZyraEntitlements.one.paused,
        ZyraEntitlements.one.ended,
      ],
      [3, null, 10, 10],
    );
    expect(
      [
        basic.savedProfiles,
        basic.activeConsiders,
        basic.dailyConsiders,
        basic.recentDeclinedProfiles,
        basic.linkedGuardians,
      ],
      [5, 25, 5, 0, 1],
    );
    expect(
      [
        one.savedProfiles,
        one.activeConsiders,
        one.dailyConsiders,
        one.recentDeclinedProfiles,
        one.linkedGuardians,
      ],
      [50, null, null, 10, 10],
    );
    for (final limits in [basic, one]) {
      expect(limits.canSave(currentCount: limits.savedProfiles - 1), isTrue);
      expect(limits.canSave(currentCount: limits.savedProfiles), isFalse);
      expect(limits.canSave(currentCount: 80, alreadySaved: true), isTrue);
    }
    expect(basic.canConsider(currentCount: 24), isTrue);
    expect(basic.canConsider(currentCount: 25), isFalse);
    expect(
      basic.canConsider(currentCount: 80, alreadyConsidered: true),
      isTrue,
    );
    expect(one.canConsider(currentCount: 100000), isTrue);
  });

  test('downgrade preserves profiles and recent-decline display copies', () {
    final app = AppState.instance;
    app.plan = ZyraPlan.one;
    app.saved.addAll(List.generate(50, (i) => _profile('saved-$i')));
    app.outgoingLikes.addAll(List.generate(30, (i) => _profile('consider-$i')));
    app.declined.addAll(List.generate(15, (i) => _profile('passed-$i')));
    final retained = app.declined.toList();
    app.setPlan(ZyraPlan.basic);
    expect(app.saved, hasLength(50));
    expect(app.outgoingLikes, hasLength(30));
    expect(
      ZyraSeekerPlanLimits.of(app.plan).recentDeclined(app.declined),
      isEmpty,
    );
    expect(app.declined, orderedEquals(retained));
    app.setPlan(ZyraPlan.one);
    final recent = ZyraSeekerPlanLimits.of(
      app.plan,
    ).recentDeclined(app.declined);
    expect(recent.map((p) => p.id), List.generate(10, (i) => 'passed-$i'));
    expect(() => recent.clear(), throwsUnsupportedError);
    app.unsave(app.saved.first);
    app.decline(app.outgoingLikes.first);
    expect(app.saved, hasLength(49));
    expect(app.outgoingLikes, hasLength(29));
  });

  test(
    'hydrated newest-first declines and new/repeated Pass keep latest ten',
    () {
      final app = AppState.instance;
      final hydrated = List.generate(15, (i) => _profile('newest-${15 - i}'));
      app.hydrateDecisions(saved: [], considered: [], passed: hydrated);
      expect(
        ZyraSeekerPlanLimits.one.recentDeclined(app.declined).map((p) => p.id),
        List.generate(10, (i) => 'newest-${15 - i}'),
      );
      app.decline(_profile('new-local'));
      expect(app.declined.first.id, 'new-local');
      app.decline(_profile('newest-1'));
      expect(app.declined.first.id, 'new-local');
      expect(app.declined.last.id, 'newest-1');
      // Save replaces the old Pass. A later Pass is genuinely new.
      app.save(_profile('newest-1'));
      app.decline(_profile('newest-1'));
      expect(app.declined.first.id, 'newest-1');
      expect(app.declined[1].id, 'new-local');
      expect(app.declined.where((p) => p.id == 'newest-1'), hasLength(1));
      expect(app.declined, hasLength(16));
      final before = app.declined.toList();
      expect(ZyraSeekerPlanLimits.basic.recentDeclined(app.declined), isEmpty);
      expect(app.declined, orderedEquals(before));
      expect(app.decidedProfileIds, containsAll(before.map((p) => p.id)));
    },
  );

  Future<void> pumpCard(
    WidgetTester tester,
    ZyraConnectionsActivityCardTestState state,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: buildZyraConnectionsActivityCardTestSurface(
              state,
              profileId: _targetId,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Maryam, 27'));
    await tester.pumpAndSettle();
  }

  Future<void> tapConsider(WidgetTester tester) async {
    // Platform-backed queued writes must finish in the real async zone;
    // pumpAndSettle alone only drains frame scheduling, not external futures.
    await tester.runAsync(() async {
      await tester.tap(find.text('Consider'));
      await ZyraSeekerBasicUsageStore.load();
    });
    await tester.pumpAndSettle();
  }

  testWidgets('Save at cap keeps prior decision; Pass still removes Consider', (
    tester,
  ) async {
    final app = AppState.instance;
    app.saved.addAll(List.generate(5, (i) => _profile('saved-$i')));
    app.outgoingLikes.add(_profile(_targetId));
    await pumpCard(tester, ZyraConnectionsActivityCardTestState.considered);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(app.saved, hasLength(5));
    expect(app.outgoingLikes.single.id, _targetId);
    expect(find.textContaining('Save list is full'), findsOneWidget);
    await tester.tap(find.text('Maryam, 27'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pass'));
    await tester.pumpAndSettle();
    expect(app.outgoingLikes, isEmpty);
    expect(app.declined.single.id, _targetId);
  });

  testWidgets('daily refusal does not change a Saved profile', (tester) async {
    final app = AppState.instance;
    app.saved.add(_profile(_targetId));
    await tester.runAsync(() async {
      for (var i = 0; i < 5; i++) {
        await ZyraSeekerBasicUsageStore.recordConsider();
      }
    });
    await pumpCard(tester, ZyraConnectionsActivityCardTestState.saved);
    await tapConsider(tester);
    expect(app.saved.single.id, _targetId);
    expect(app.outgoingLikes, isEmpty);
    expect(find.textContaining('5 Considers each day'), findsOneWidget);
  });

  testWidgets(
    'Connections fifth blocks Browse with an old four-use display cache',
    (tester) async {
      final browseDisplayCache = await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          expect(
            await ZyraSeekerBasicUsageStore.tryRecordConsider(),
            isNotNull,
          );
        }
        return ZyraSeekerBasicUsageStore.load();
      });
      expect(browseDisplayCache, isNotNull);
      expect(browseDisplayCache!.considersToday, 4);
      AppState.instance.saved.add(_profile(_targetId));
      await pumpCard(tester, ZyraConnectionsActivityCardTestState.saved);
      await tapConsider(tester);
      expect(AppState.instance.outgoingLikes.single.id, _targetId);
      // Browse now calls this same fresh, serialized claim before app.like;
      // it never uses browseDisplayCache to authorise another Consider.
      await tester.runAsync(() async {
        expect(await ZyraSeekerBasicUsageStore.tryRecordConsider(), isNull);
        expect((await ZyraSeekerBasicUsageStore.load()).considersToday, 5);
      });
      expect(browseDisplayCache.considersToday, 4);
      final browseSource = File(
        'lib/screens/browse/browse_screen.dart',
      ).readAsStringSync();
      final start = browseSource.indexOf('Future<void> _onConsider()');
      final end = browseSource.indexOf('void _tapPhoto(', start);
      final action = browseSource.substring(start, end);
      final claim = RegExp(
        r'await\s+\(widget\.claimConsider\s*\?\?\s*'
        r'ZyraSeekerBasicUsageStore\.tryRecordConsider\)\(\);',
      ).firstMatch(action);
      expect(
        claim,
        isNotNull,
        reason:
            'The optional offline seam must retain the serialized store default.',
      );
      final verifiedClaim = claim!;
      expect(
        verifiedClaim.start,
        lessThan(action.indexOf('AppState.instance.like(profile)')),
      );
      final afterClaim = action.substring(
        verifiedClaim.end,
        action.indexOf('AppState.instance.like(profile)'),
      );
      expect(
        RegExp(r'^\s*if \(!current\(\)\) return;').hasMatch(afterClaim),
        isTrue,
        reason: 'An obsolete allowance result cannot reach the local Like.',
      );
      expect(afterClaim, contains('if (usage == null)'));
      expect(afterClaim, contains('_basicUsage = usage;'));
      final refusal = afterClaim.substring(
        afterClaim.indexOf('if (usage == null)'),
        afterClaim.indexOf('_basicUsage = usage;'),
      );
      expect(refusal, contains('return;'));
      expect(
        action,
        contains(
          RegExp(
            r'if \(!current\(\)\) return;\s*'
            r'final isMatch = AppState\.instance\.like\(profile\);',
          ),
        ),
      );
      expect(action, isNot(contains('_basicUsage.dailyConsiderLimitReached')));
      expect(action, isNot(contains('_recordBasicConsider()')));
    },
  );

  test(
    'simultaneous page claims share five slots; account key is captured',
    () async {
      final claims = await Future.wait(
        List.generate(8, (_) => ZyraSeekerBasicUsageStore.tryRecordConsider()),
      );
      expect(claims.whereType<ZyraSeekerBasicUsage>(), hasLength(5));
      expect(claims.where((claim) => claim == null), hasLength(3));
      expect((await ZyraSeekerBasicUsageStore.load()).considersToday, 5);
      AppState.instance.name = 'Account A';
      final first = ZyraSeekerBasicUsageStore.tryRecordConsider();
      AppState.instance.name = 'Account B';
      final second = ZyraSeekerBasicUsageStore.tryRecordConsider();
      expect((await first)?.considersToday, 1);
      expect((await second)?.considersToday, 1);
      AppState.instance.name = 'Account A';
      expect((await ZyraSeekerBasicUsageStore.load()).considersToday, 1);
    },
  );

  test(
    'a delayed swipe cannot overwrite a newer daily Consider claim',
    () async {
      final store = _HeldWriteStore();
      SharedPreferencesStorePlatform.instance = store;
      final now = DateTime(2026, 9, 18, 12);
      for (var i = 0; i < 4; i++) {
        await ZyraSeekerBasicUsageStore.recordConsider(at: now);
      }
      store.holdNextWrite = true;
      final swipe = ZyraSeekerBasicUsageStore.recordSwipe(at: now);
      await store.entered.future;
      final fifth = ZyraSeekerBasicUsageStore.tryRecordConsider(at: now);
      final displayRead = ZyraSeekerBasicUsageStore.load(at: now);
      store.release.complete();
      expect((await swipe).swipes, 1);
      expect((await fifth)?.considersToday, 5);
      final read = await displayRead;
      expect(read.swipes, 1);
      expect(read.considersToday, 5);
      expect(
        await ZyraSeekerBasicUsageStore.tryRecordConsider(at: now),
        isNull,
      );
      expect(store.writeCount, 6);
      // Normalization on a display read is read-only, including at day rollover.
      expect(
        (await ZyraSeekerBasicUsageStore.load(
          at: now.add(const Duration(days: 1)),
        )).considersToday,
        0,
      );
      expect(store.writeCount, 6);
      expect((await ZyraSeekerBasicUsageStore.load(at: now)).considersToday, 5);
    },
  );

  for (final throwsError in [false, true]) {
    testWidgets('failed allowance write ($throwsError) preserves prior state', (
      tester,
    ) async {
      AppState.instance.saved.add(_profile(_targetId));
      SharedPreferencesStorePlatform.instance = _FailedStore(
        throwsError: throwsError,
      );
      await pumpCard(tester, ZyraConnectionsActivityCardTestState.saved);
      await tapConsider(tester);
      expect(AppState.instance.saved.single.id, _targetId);
      expect(AppState.instance.outgoingLikes, isEmpty);
      expect(
        find.textContaining('Your profile decision is unchanged'),
        findsOneWidget,
      );
    });
  }

  testWidgets('duplicate Consider does not consume daily allowance', (
    tester,
  ) async {
    AppState.instance.outgoingLikes.add(_profile(_targetId));
    await pumpCard(tester, ZyraConnectionsActivityCardTestState.saved);
    await tapConsider(tester);
    expect(AppState.instance.outgoingLikes, hasLength(1));
    await tester.runAsync(() async {
      expect((await ZyraSeekerBasicUsageStore.load()).considersToday, 0);
    });
  });

  testWidgets(
    'history lock Upgrade opens honest information, never changes plan',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZyraMembershipHistoryLock(
              description: 'History stays kept, not deleted.',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(
        find.textContaining('Purchases are not available yet'),
        findsOneWidget,
      );
      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();
      expect(find.byType(UpgradeScreen), findsOneWidget);
      expect(AppState.instance.plan, ZyraPlan.basic);
    },
  );
}
