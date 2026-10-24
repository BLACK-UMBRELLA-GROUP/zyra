import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/home/unread_badge_coordinator.dart';
import 'package:zyra/services/zyra_notification_service.dart';

void main() {
  test('tab arrival can only refresh, never acknowledge a section', () async {
    final snapshots = <(int?, Set<ZyraNavSection>?)>[];
    var reads = 0;
    final coordinator = ZyraUnreadBadgeCoordinator(
      fetchUnreadCount: () async {
        reads++;
        return 3;
      },
      fetchSectionsWithUnread: () async => {ZyraNavSection.connections},
      onSnapshot: (count, sections) => snapshots.add((count, sections)),
    );
    await coordinator.refresh();
    await coordinator.refresh();
    expect(reads, 2);
    expect(snapshots.map((snapshot) => snapshot.$1), everyElement(3));
    expect(
      snapshots.map((snapshot) => snapshot.$2),
      everyElement({ZyraNavSection.connections}),
    );
    coordinator.dispose();
  });

  test('a newer read wins when fetches finish out of order', () async {
    final oldCount = Completer<int?>();
    final snapshots = <int?>[];
    var reads = 0;
    final coordinator = ZyraUnreadBadgeCoordinator(
      fetchUnreadCount: () => ++reads == 1 ? oldCount.future : Future.value(1),
      fetchSectionsWithUnread: () => Future.value(<ZyraNavSection>{}),
      onSnapshot: (count, _) => snapshots.add(count),
    );

    final oldRefresh = coordinator.refresh();
    await coordinator.refresh();
    oldCount.complete(5);
    await oldRefresh;
    expect(snapshots, [1]);
  });

  test(
    'account change and disposal suppress stale sensitive results',
    () async {
      var account = 'seeker-a';
      final delayedCount = Completer<int?>();
      final snapshots = <int?>[];
      final coordinator = ZyraUnreadBadgeCoordinator(
        fetchUnreadCount: () => delayedCount.future,
        fetchSectionsWithUnread: () => Future.value(<ZyraNavSection>{}),
        onSnapshot: (count, _) => snapshots.add(count),
        currentScope: () => account,
      );

      final refresh = coordinator.refresh();
      account = 'seeker-b';
      delayedCount.complete(4);
      await refresh;
      expect(snapshots, isEmpty);

      final delayedSections = Completer<Set<ZyraNavSection>?>();
      final disposedCoordinator = ZyraUnreadBadgeCoordinator(
        fetchUnreadCount: () async => 2,
        fetchSectionsWithUnread: () => delayedSections.future,
        onSnapshot: (count, _) => snapshots.add(count),
      );
      final disposedRefresh = disposedCoordinator.refresh();
      await Future<void>.delayed(Duration.zero);
      disposedCoordinator.dispose();
      delayedSections.complete({ZyraNavSection.guardian});
      await disposedRefresh;
      expect(snapshots, isEmpty);
    },
  );

  test('owner ABA generation rejects an in-flight unread snapshot', () async {
    var owner = ('a', 1);
    final count = Completer<int?>();
    final snapshots = <int?>[];
    final coordinator = ZyraUnreadBadgeCoordinator(
      fetchUnreadCount: () => count.future,
      fetchSectionsWithUnread: () async => {ZyraNavSection.guardian},
      currentScope: () => owner,
      onSnapshot: (value, _) => snapshots.add(value),
    );
    final pending = coordinator.refresh();
    owner = ('b', 2);
    owner = ('a', 3);
    count.complete(0);
    await pending;
    expect(snapshots, isEmpty);
    coordinator.dispose();
  });

  test('failed reads preserve the caller-owned unread state', () async {
    var unread = 4;
    var sections = <ZyraNavSection>{ZyraNavSection.connections};
    final coordinator = ZyraUnreadBadgeCoordinator(
      fetchUnreadCount: () async => null,
      fetchSectionsWithUnread: () async => null,
      onSnapshot: (count, nextSections) {
        unread = count ?? unread;
        sections = nextSections ?? sections;
      },
    );
    await coordinator.refresh();
    expect(unread, 4);
    expect(sections, {ZyraNavSection.connections});
    coordinator.dispose();
  });
}
