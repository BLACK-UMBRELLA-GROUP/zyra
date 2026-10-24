import '../../services/zyra_notification_service.dart';

/// Serially publishes only the latest owner-bound unread snapshot.
/// Navigation never acknowledges notification rows.
class ZyraUnreadBadgeCoordinator {
  ZyraUnreadBadgeCoordinator({
    required this.fetchUnreadCount,
    required this.fetchSectionsWithUnread,
    required this.onSnapshot,
    this.currentScope,
  });

  final Future<int?> Function() fetchUnreadCount;
  final Future<Set<ZyraNavSection>?> Function() fetchSectionsWithUnread;
  final void Function(int?, Set<ZyraNavSection>?) onSnapshot;
  final Object? Function()? currentScope;

  int _revision = 0;
  bool _disposed = false;

  bool _isCurrent(int revision, Object? scope) =>
      !_disposed && revision == _revision && currentScope?.call() == scope;

  Future<void> refresh() async {
    if (_disposed) return;
    final revision = ++_revision;
    final scope = currentScope?.call();
    final count = await fetchUnreadCount();
    if (!_isCurrent(revision, scope)) return;
    final sections = await fetchSectionsWithUnread();
    if (!_isCurrent(revision, scope)) return;
    onSnapshot(count, sections);
  }

  void dispose() {
    _disposed = true;
    ++_revision;
  }
}
