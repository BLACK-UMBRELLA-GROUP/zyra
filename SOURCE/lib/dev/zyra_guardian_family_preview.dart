// LOCK19 V3: detached Family invitation facts only. Never payment, identity or
// production membership authority; the admitted preview owns all mutations.
enum ZyraGuardianFamilyInviteStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired,
}

class ZyraGuardianFamilyInvite {
  const ZyraGuardianFamilyInvite({
    required this.revision,
    required this.guardianId,
    required this.guardianName,
    required this.seekerId,
    required this.seekerName,
    required this.seekerGender,
    required this.relationship,
    required this.main,
    required this.sentAt,
    this.status = ZyraGuardianFamilyInviteStatus.pending,
  });
  final int revision;
  final String guardianId,
      guardianName,
      seekerId,
      seekerName,
      seekerGender,
      relationship;
  final bool main;
  final DateTime sentAt;
  final ZyraGuardianFamilyInviteStatus status;
  DateTime get expiresAt => sentAt.add(const Duration(days: 7));
  bool pendingAt(DateTime now) =>
      status == ZyraGuardianFamilyInviteStatus.pending &&
      !now.isBefore(sentAt) &&
      now.isBefore(expiresAt);
  String get pronoun => seekerGender.toLowerCase() == 'female' ? 'she' : 'he';
  String get chooseBy =>
      '${expiresAt.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][expiresAt.month - 1]}';
  ZyraGuardianFamilyInvite _withStatus(ZyraGuardianFamilyInviteStatus value) =>
      ZyraGuardianFamilyInvite(
        revision: revision,
        guardianId: guardianId,
        guardianName: guardianName,
        seekerId: seekerId,
        seekerName: seekerName,
        seekerGender: seekerGender,
        relationship: relationship,
        main: main,
        sentAt: sentAt,
        status: value,
      );
}

class ZyraGuardianFamilyPreviewSnapshot {
  ZyraGuardianFamilyPreviewSnapshot({
    required Iterable<ZyraGuardianFamilyInvite> invites,
    required this.freePlaces,
    required this.sequence,
  }) : invites = List.unmodifiable(invites);
  final List<ZyraGuardianFamilyInvite> invites;
  final int freePlaces, sequence;
}

class ZyraGuardianFamilyPreview {
  ZyraGuardianFamilyPreview({ZyraGuardianFamilyPreviewSnapshot? snapshot}) {
    if (snapshot != null) {
      if (snapshot.freePlaces < 0 ||
          snapshot.sequence < 0 ||
          snapshot.invites.any(
            (i) => i.revision <= 0 || i.revision > snapshot.sequence,
          ) ||
          snapshot.invites.map((i) => i.guardianId).toSet().length !=
              snapshot.invites.length) {
        throw ArgumentError('Invalid local Family invitation snapshot.');
      }
      _freePlaces = snapshot.freePlaces;
      _sequence = snapshot.sequence;
      for (final invite in snapshot.invites) {
        _invites[invite.guardianId] = invite;
      }
    }
  }
  final _invites = <String, ZyraGuardianFamilyInvite>{};
  int _freePlaces = 0, _sequence = 0;
  int get freePlaces => _freePlaces;
  List<ZyraGuardianFamilyInvite> get invites =>
      List.unmodifiable(_invites.values);
  ZyraGuardianFamilyInvite? inviteFor(String guardianId) =>
      _invites[guardianId];
  ZyraGuardianFamilyPreviewSnapshot get snapshot =>
      ZyraGuardianFamilyPreviewSnapshot(
        invites: invites,
        freePlaces: _freePlaces,
        sequence: _sequence,
      );
  ZyraGuardianFamilyInvite? send({
    required String guardianId,
    required String guardianName,
    required String seekerId,
    required String seekerName,
    required String seekerGender,
    required String relationship,
    required bool main,
    required DateTime now,
  }) {
    expire(now);
    if ([
      guardianId,
      guardianName,
      seekerId,
      seekerName,
      relationship,
    ].any((s) => s.trim().isEmpty)) {
      return null;
    }
    final previous = inviteFor(guardianId);
    if (previous?.status == ZyraGuardianFamilyInviteStatus.pending ||
        previous?.status == ZyraGuardianFamilyInviteStatus.accepted) {
      return null;
    }
    if (_freePlaces > 0) _freePlaces--;
    final invite = ZyraGuardianFamilyInvite(
      revision: ++_sequence,
      guardianId: guardianId,
      guardianName: guardianName,
      seekerId: seekerId,
      seekerName: seekerName,
      seekerGender: seekerGender,
      relationship: relationship,
      main: main,
      sentAt: now.toUtc(),
    );
    return _invites[guardianId] = invite;
  }

  bool _finish(
    ZyraGuardianFamilyInvite invite,
    DateTime now,
    ZyraGuardianFamilyInviteStatus status,
  ) {
    expire(now);
    final current = inviteFor(invite.guardianId);
    if (current?.revision != invite.revision ||
        current?.pendingAt(now) != true) {
      return false;
    }
    _invites[invite.guardianId] = current!._withStatus(status);
    if (status != ZyraGuardianFamilyInviteStatus.accepted) _freePlaces++;
    return true;
  }

  bool accept(
    ZyraGuardianFamilyInvite invite,
    DateTime now, {
    required bool identityVerified,
  }) =>
      identityVerified &&
      _finish(invite, now, ZyraGuardianFamilyInviteStatus.accepted);
  bool decline(ZyraGuardianFamilyInvite invite, DateTime now) =>
      _finish(invite, now, ZyraGuardianFamilyInviteStatus.declined);
  bool cancel(ZyraGuardianFamilyInvite invite, DateTime now) =>
      _finish(invite, now, ZyraGuardianFamilyInviteStatus.cancelled);
  void expire(DateTime now) {
    for (final invite in invites) {
      if (invite.status == ZyraGuardianFamilyInviteStatus.pending &&
          !now.isBefore(invite.expiresAt)) {
        _invites[invite.guardianId] = invite._withStatus(
          ZyraGuardianFamilyInviteStatus.expired,
        );
        _freePlaces++;
      }
    }
  }
}
