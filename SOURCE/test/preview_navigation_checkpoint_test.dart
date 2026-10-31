import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';

Future<BuildContext> _positionContext(
  WidgetTester tester,
  ZyraPreviewPositionBucket bucket, {
  Key key = const PageStorageKey('reader'),
}) async {
  late BuildContext result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PageStorage(
          bucket: bucket,
          child: Builder(
            key: key,
            builder: (context) {
              result = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
  return result;
}

void main() {
  test('fresh window and inactive-only interruptions restore', () {
    var elapsed = Duration.zero;
    final window = ZyraPreviewAwayWindow(elapsed: () => elapsed);
    expect(window.resume(), isTrue);
    window.inactive();
    elapsed = const Duration(hours: 2);
    expect(window.resume(), isTrue);
    expect(window.resume(), isTrue);
  });

  for (final entry in [
    (away: const Duration(seconds: 3), restore: true),
    (
      away: const Duration(minutes: 14, seconds: 59, milliseconds: 999),
      restore: true,
    ),
    (away: const Duration(minutes: 15), restore: false),
    (away: const Duration(minutes: 15, microseconds: 1), restore: false),
    (away: const Duration(hours: 3), restore: false),
  ]) {
    test('background duration ${entry.away} restores=${entry.restore}', () {
      var elapsed = const Duration(days: 20000);
      final window = ZyraPreviewAwayWindow(elapsed: () => elapsed);
      window.inactive();
      window.background();
      elapsed += entry.away;
      expect(window.resume(), entry.restore);
      // The authorization/preparation wait after returning cannot change the
      // recorded decision or make a second resume extend the interval.
      elapsed += const Duration(hours: 1);
      expect(window.resume(), entry.restore);
    });
  }

  test('duplicate background events do not restart the first departure', () {
    var elapsed = Duration.zero;
    final window = ZyraPreviewAwayWindow(elapsed: () => elapsed);
    window.inactive();
    window.background();
    elapsed = const Duration(minutes: 10);
    window.background();
    window.inactive();
    elapsed = const Duration(minutes: 15);
    expect(window.resume(), isFalse);
    expect(window.resume(), isFalse);
    // A genuinely new departure gets its own interval.
    window.inactive();
    window.background();
    elapsed += const Duration(seconds: 2);
    expect(window.resume(), isTrue);
  });

  test('long inactive sheet followed by a short background still restores', () {
    var elapsed = Duration.zero;
    final window = ZyraPreviewAwayWindow(elapsed: () => elapsed);
    window.inactive();
    elapsed = const Duration(hours: 2);
    window.background();
    elapsed += const Duration(seconds: 4);
    expect(window.resume(), isTrue);
  });

  test('background without inactive starts a fresh departure', () {
    var elapsed = const Duration(days: 1);
    final window = ZyraPreviewAwayWindow(elapsed: () => elapsed);
    window.background();
    elapsed += const Duration(minutes: 15);
    expect(window.resume(), isFalse);
  });

  test('a backward clock resets rather than restoring a stale location', () {
    var elapsed = const Duration(hours: 3);
    final window = ZyraPreviewAwayWindow(elapsed: () => elapsed);
    window.background();
    elapsed = const Duration(hours: 2);
    expect(window.resume(), isFalse);
    elapsed = const Duration(hours: 4);
    expect(window.resume(), isFalse);
  });

  test('checkpoint snapshots all supplied collections defensively', () {
    final nationalities = {'GB', 'PK'};
    final ethnicities = {'arab', 'mixed'};
    final pages = ['journey', 'timeline'];
    final history = ['draft-sara', 'draft-aisha'];
    final photos = {'draft-sara': 1};
    final galleries = {'draft-sara': 2, 'draft-aisha': 0};
    final positions = {'String:timeline': 123.0};
    final removed = ['draft-guardian-yusuf'];
    final guardianHistory = {'draft-guardian-hassan': true};
    final sent = ['draft-maryam'];
    final consumedFocus = ['accepted:draft-sara:1793437200000000'];
    final model = ViewRequestDraftModel(capacity: 3)..fillCapacity();
    final checkpoint = ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: model.snapshot(),
      tab: 1,
      pages: pages,
      browseFilter: ZyraBrowseFilter(
        nationalityCodes: nationalities,
        ethnicityCodes: ethnicities,
      ),
      personId: 'draft-sara',
      browseHistory: history,
      browseCursor: 1,
      photoIndices: photos,
      galleryIndices: galleries,
      positions: positions,
      removedGuardians: removed,
      guardianHistory: guardianHistory,
      networkSent: sent,
      myZyraConsumedFocusTokens: consumedFocus,
      myZyraFocusIndex: 2,
    );
    nationalities.clear();
    ethnicities.clear();
    expect(checkpoint.browseFilter.nationalityCodes, {'GB', 'PK'});
    expect(checkpoint.browseFilter.ethnicityCodes, {'arab', 'mixed'});
    expect(
      () => checkpoint.browseFilter.nationalityCodes.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => checkpoint.browseFilter.ethnicityCodes.clear(),
      throwsUnsupportedError,
    );
    pages.clear();
    history.clear();
    photos.clear();
    galleries.clear();
    positions.clear();
    removed.clear();
    guardianHistory.clear();
    sent.clear();
    consumedFocus.clear();
    model.reset();
    expect(checkpoint.pages, ['journey', 'timeline']);
    expect(checkpoint.browseHistory, ['draft-sara', 'draft-aisha']);
    expect(checkpoint.photoIndices, {'draft-sara': 1});
    expect(checkpoint.galleryIndices, {'draft-sara': 2, 'draft-aisha': 0});
    expect(checkpoint.positions, {'String:timeline': 123.0});
    expect(checkpoint.removedGuardians, {'draft-guardian-yusuf'});
    expect(checkpoint.guardianHistory, {'draft-guardian-hassan': true});
    expect(checkpoint.networkSent, {'draft-maryam'});
    expect(checkpoint.myZyraConsumedFocusTokens, {
      'accepted:draft-sara:1793437200000000',
    });
    expect(checkpoint.myZyraFocusIndex, 2);
    expect(checkpoint.model.states['draft-sara'], DraftJourneyState.active);
    expect(() => checkpoint.pages.clear(), throwsUnsupportedError);
    expect(() => checkpoint.browseHistory.clear(), throwsUnsupportedError);
    expect(() => checkpoint.photoIndices.clear(), throwsUnsupportedError);
    expect(() => checkpoint.galleryIndices.clear(), throwsUnsupportedError);
    expect(() => checkpoint.positions.clear(), throwsUnsupportedError);
    expect(() => checkpoint.removedGuardians.clear(), throwsUnsupportedError);
    expect(() => checkpoint.guardianHistory.clear(), throwsUnsupportedError);
    expect(() => checkpoint.networkSent.clear(), throwsUnsupportedError);
    expect(
      () => checkpoint.myZyraConsumedFocusTokens.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'Focus checkpoint defaults and bounds do not infer consumed activity',
    () {
      final fresh = ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: ViewRequestDraftModel().snapshot(),
        tab: 0,
        pages: const [],
      );
      expect(fresh.myZyraConsumedFocusTokens, isEmpty);
      expect(fresh.myZyraFocusIndex, 0);
      final bounded = ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: ViewRequestDraftModel().snapshot(),
        tab: 0,
        pages: const [],
        myZyraConsumedFocusTokens: List.generate(
          100,
          (index) => 'event-$index',
        ),
        myZyraFocusIndex: -1,
      );
      expect(bounded.myZyraConsumedFocusTokens.length, 64);
      expect(bounded.myZyraConsumedFocusTokens.last, 'event-63');
      expect(bounded.myZyraFocusIndex, 0);
    },
  );

  test('page and Browse-history lists remain bounded', () {
    final checkpoint = ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: ViewRequestDraftModel().snapshot(),
      tab: 0,
      pages: List.generate(100, (index) => 'page-$index'),
      browseHistory: List.generate(100, (index) => 'person-$index'),
    );
    expect(checkpoint.pages.length, 8);
    expect(checkpoint.pages.first, 'page-0');
    expect(checkpoint.pages.last, 'page-7');
    expect(checkpoint.browseHistory.length, 11);
    expect(checkpoint.browseHistory.first, 'person-0');
    expect(checkpoint.browseHistory.last, 'person-10');
  });

  test('photo and gallery maps are separate bounded snapshots', () {
    final checkpoint = ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: ViewRequestDraftModel().snapshot(),
      tab: 0,
      pages: const [],
      photoIndices: {
        for (var index = 0; index < 100; index++) 'person-$index': 1,
      },
      galleryIndices: {
        for (var index = 0; index < 100; index++) 'person-$index': 2,
      },
    );
    expect(checkpoint.photoIndices.length, 64);
    expect(checkpoint.galleryIndices.length, 64);
    expect(checkpoint.photoIndices['person-63'], 1);
    expect(checkpoint.galleryIndices['person-63'], 2);
    expect(checkpoint.photoIndices, isNot(contains('person-64')));
    expect(checkpoint.galleryIndices, isNot(contains('person-64')));
  });

  test('legacy checkpoints have no inferred gallery page', () {
    final checkpoint = ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: ViewRequestDraftModel().snapshot(),
      tab: 0,
      pages: const [],
      photoIndices: const {'draft-sara': 1},
    );
    expect(checkpoint.photoIndices, {'draft-sara': 1});
    expect(checkpoint.galleryIndices, isEmpty);
  });

  test('informational checkpoint subjects are detached identifiers only', () {
    final checkpoint = ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: ViewRequestDraftModel().snapshot(),
      tab: 4,
      pages: const ['settings', 'account_action', 'settings_detail'],
      accountDestination: 'privacyData',
      settingsDetail: 'terms',
    );
    expect(checkpoint.accountDestination, 'privacyData');
    expect(checkpoint.settingsDetail, 'terms');
    expect(checkpoint.pages, ['settings', 'account_action', 'settings_detail']);
  });

  testWidgets('position bucket stores only finite bounded double offsets', (
    tester,
  ) async {
    var changed = 0;
    final bucket = ZyraPreviewPositionBucket(
      canWrite: () => true,
      onChanged: () => changed++,
    );
    final context = await _positionContext(tester, bucket);
    bucket.writeState(context, 42.0);
    expect(bucket.readState(context), 42.0);
    expect(changed, 1);
    bucket.writeState(context, 42.0);
    expect(changed, 1);
    for (final rejected in <Object?>[
      Object(),
      context,
      const SizedBox.shrink(),
      <String, double>{'offset': 45.0},
      <double>[45.0],
      45,
      null,
      double.nan,
      double.infinity,
      double.negativeInfinity,
      -1.0,
      1000001.0,
    ]) {
      bucket.writeState(context, rejected);
    }
    expect(bucket.readState(context), 42.0);
    expect(bucket.snapshot, {'String:reader': 42.0});
    expect(changed, 1);
    bucket.writeState(context, 0.0);
    expect(bucket.readState(context), 0.0);
    bucket.writeState(context, 1000000.0);
    expect(bucket.readState(context), 1000000.0);
    expect(changed, 3);
  });

  testWidgets('explicit identifiers reject object or invalid keys', (
    tester,
  ) async {
    final bucket = ZyraPreviewPositionBucket(
      canWrite: () => true,
      onChanged: () {},
    );
    final context = await _positionContext(tester, bucket);
    bucket.writeState(context, 23.0, identifier: 'timeline');
    expect(bucket.readState(context, identifier: 'timeline'), 23.0);
    for (final identifier in <Object>[
      Object(),
      context,
      1,
      '',
      List.filled(513, 'x').join(),
    ]) {
      bucket.writeState(context, 99.0, identifier: identifier);
      expect(bucket.readState(context, identifier: identifier), isNull);
    }
    expect(bucket.snapshot, {'id:timeline': 23.0});
    expect(() => bucket.snapshot.clear(), throwsUnsupportedError);
  });

  testWidgets('object PageStorage key cannot become retained state', (
    tester,
  ) async {
    var changed = 0;
    final bucket = ZyraPreviewPositionBucket(
      canWrite: () => true,
      onChanged: () => changed++,
    );
    final context = await _positionContext(
      tester,
      bucket,
      key: PageStorageKey(Object()),
    );
    bucket.writeState(context, 24.0);
    expect(bucket.snapshot, isEmpty);
    expect(bucket.readState(context), isNull);
    expect(changed, 0);
  });

  testWidgets(
    'new bucket copies scalars without reviving the old write guard',
    (tester) async {
      var oldAllowed = true;
      var oldChanged = 0;
      final old = ZyraPreviewPositionBucket(
        canWrite: () => oldAllowed,
        onChanged: () => oldChanged++,
      );
      final oldContext = await _positionContext(tester, old);
      old.writeState(oldContext, 61.0, identifier: 'timeline');
      final checkpoint = old.snapshot;
      oldAllowed = false;
      final fresh = ZyraPreviewPositionBucket(
        canWrite: () => true,
        onChanged: () {},
        initial: checkpoint,
      );
      final freshContext = await _positionContext(
        tester,
        fresh,
        key: const PageStorageKey('fresh-reader'),
      );
      old.writeState(oldContext, 999.0, identifier: 'timeline');
      expect(oldChanged, 1);
      expect(old.snapshot, {'id:timeline': 61.0});
      expect(fresh.readState(freshContext, identifier: 'timeline'), 61.0);
      fresh.writeState(freshContext, 83.0, identifier: 'timeline');
      expect(fresh.readState(freshContext, identifier: 'timeline'), 83.0);
      expect(checkpoint, {'id:timeline': 61.0});
      expect(old.snapshot, {'id:timeline': 61.0});
    },
  );

  testWidgets(
    'initial scalar data is copied filtered and bounded to 64 entries',
    (tester) async {
      final input = <String, double>{
        'id:valid': 27.0,
        'id:nan': double.nan,
        'id:negative': -1.0,
        '': 1.0,
        for (var index = 0; index < 100; index++)
          'id:entry-$index': index.toDouble(),
      };
      final bucket = ZyraPreviewPositionBucket(
        canWrite: () => false,
        onChanged: () => fail('A denied write must not emit change.'),
        initial: input,
      );
      final context = await _positionContext(tester, bucket);
      input.clear();
      expect(bucket.readState(context, identifier: 'valid'), 27.0);
      expect(bucket.snapshot.length, lessThanOrEqualTo(64));
      expect(bucket.snapshot.containsKey('id:nan'), isFalse);
      expect(bucket.snapshot.containsKey('id:negative'), isFalse);
      expect(bucket.snapshot.containsKey(''), isFalse);
      final before = bucket.snapshot;
      bucket.writeState(context, 29.0, identifier: 'valid');
      expect(bucket.snapshot, before);
    },
  );
}
