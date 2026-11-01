import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/dev/zyra_guardian_family_preview.dart';

final _sentAt = DateTime.utc(2026, 12, 28, 13, 45);

ZyraGuardianFamilyInvite _send(
  ZyraGuardianFamilyPreview preview, {
  String guardianId = 'guardian-a',
  String guardianName = 'Amina',
  String seekerId = 'seeker-a',
  String seekerName = 'Maryam',
  String seekerGender = 'female',
  String relationship = 'Mother',
  bool main = true,
  DateTime? now,
}) => preview.send(
  guardianId: guardianId,
  guardianName: guardianName,
  seekerId: seekerId,
  seekerName: seekerName,
  seekerGender: seekerGender,
  relationship: relationship,
  main: main,
  now: now ?? _sentAt,
)!;

void main() {
  test('the deadline is exactly seven days across the year boundary', () {
    final invite = _send(ZyraGuardianFamilyPreview());
    final deadline = DateTime.utc(2027, 1, 4, 13, 45);

    expect(invite.expiresAt, deadline);
    expect(invite.chooseBy, '4 Jan');
    expect(
      invite.pendingAt(_sentAt.subtract(const Duration(microseconds: 1))),
      isFalse,
    );
    expect(
      invite.pendingAt(deadline.subtract(const Duration(microseconds: 1))),
      isTrue,
    );
    expect(invite.pendingAt(deadline), isFalse);
    expect(invite.pendingAt(deadline.add(const Duration(seconds: 1))), isFalse);
  });

  test('accept retains the actual invitation facts and reserved place', () {
    final preview = ZyraGuardianFamilyPreview();
    final invite = _send(preview);
    final reservedFreePlaces = preview.freePlaces;
    final beforeDeadline = invite.expiresAt.subtract(
      const Duration(seconds: 1),
    );

    expect(
      preview.accept(invite, beforeDeadline, identityVerified: true),
      isTrue,
    );
    final accepted = preview.inviteFor('guardian-a')!;
    expect(accepted.status, ZyraGuardianFamilyInviteStatus.accepted);
    expect(accepted.guardianName, 'Amina');
    expect(accepted.seekerId, 'seeker-a');
    expect(accepted.seekerName, 'Maryam');
    expect(accepted.relationship, 'Mother');
    expect(accepted.main, isTrue);
    expect(accepted.sentAt, _sentAt);
    expect(accepted.pronoun, 'she');
    expect(preview.freePlaces, reservedFreePlaces);

    preview.expire(invite.expiresAt.add(const Duration(days: 30)));
    preview.decline(invite, beforeDeadline);
    preview.cancel(invite, beforeDeadline);
    expect(preview.inviteFor('guardian-a')!.status, accepted.status);
    expect(preview.freePlaces, reservedFreePlaces);
    expect(
      preview.accept(invite, beforeDeadline, identityVerified: true),
      isFalse,
    );
  });

  test(
    'accept needs verified identity and leaves an unverified invite pending',
    () {
      final preview = ZyraGuardianFamilyPreview();
      final invite = _send(preview);
      final reservedFreePlaces = preview.freePlaces;

      expect(preview.accept(invite, _sentAt, identityVerified: false), isFalse);
      expect(
        preview.inviteFor(invite.guardianId)!.status,
        ZyraGuardianFamilyInviteStatus.pending,
      );
      expect(preview.freePlaces, reservedFreePlaces);
      expect(preview.accept(invite, _sentAt, identityVerified: true), isTrue);
    },
  );

  test('missing invite facts do not create a preview allocation', () {
    final preview = ZyraGuardianFamilyPreview();
    for (final missing in [
      {'guardianId': ''},
      {'guardianName': '   '},
      {'seekerId': ''},
      {'seekerName': '   '},
      {'relationship': ''},
    ]) {
      expect(
        preview.send(
          guardianId: missing['guardianId'] ?? 'guardian-a',
          guardianName: missing['guardianName'] ?? 'Amina',
          seekerId: missing['seekerId'] ?? 'seeker-a',
          seekerName: missing['seekerName'] ?? 'Maryam',
          seekerGender: 'female',
          relationship: missing['relationship'] ?? 'Mother',
          main: true,
          now: _sentAt,
        ),
        isNull,
      );
    }
    expect(preview.invites, isEmpty);
    expect(preview.freePlaces, 0);
  });

  for (final action in ['decline', 'cancel']) {
    test('$action releases one place once and a new invite reuses it', () {
      final preview = ZyraGuardianFamilyPreview();
      final invite = _send(preview);
      final reservedFreePlaces = preview.freePlaces;
      final expectedStatus = action == 'decline'
          ? ZyraGuardianFamilyInviteStatus.declined
          : ZyraGuardianFamilyInviteStatus.cancelled;

      void finish() {
        if (action == 'decline') {
          preview.decline(invite, _sentAt);
        } else {
          preview.cancel(invite, _sentAt);
        }
      }

      finish();
      expect(preview.inviteFor(invite.guardianId)!.status, expectedStatus);
      expect(preview.freePlaces, reservedFreePlaces + 1);
      finish();
      preview.expire(invite.expiresAt);
      expect(preview.freePlaces, reservedFreePlaces + 1);

      final replacement = _send(
        preview,
        now: _sentAt.add(const Duration(hours: 1)),
      );
      expect(replacement.revision, greaterThan(invite.revision));
      expect(replacement.status, ZyraGuardianFamilyInviteStatus.pending);
      expect(preview.freePlaces, reservedFreePlaces);
    });
  }

  test('expiry releases once and rejects acceptance at the exact deadline', () {
    final preview = ZyraGuardianFamilyPreview();
    final invite = _send(preview);
    final reservedFreePlaces = preview.freePlaces;

    expect(
      preview.accept(invite, invite.expiresAt, identityVerified: true),
      isFalse,
    );
    preview.expire(invite.expiresAt);
    expect(
      preview.inviteFor(invite.guardianId)!.status,
      ZyraGuardianFamilyInviteStatus.expired,
    );
    expect(preview.freePlaces, reservedFreePlaces + 1);
    preview.expire(invite.expiresAt.add(const Duration(days: 1)));
    preview.decline(invite, invite.expiresAt);
    preview.cancel(invite, invite.expiresAt);
    expect(preview.freePlaces, reservedFreePlaces + 1);
  });

  test('callbacks from the old revision cannot alter a replacement invite', () {
    final preview = ZyraGuardianFamilyPreview();
    final original = _send(preview);
    preview.cancel(original, _sentAt);
    final replacement = _send(
      preview,
      now: _sentAt.add(const Duration(hours: 2)),
    );
    final reservedFreePlaces = preview.freePlaces;

    expect(preview.accept(original, _sentAt, identityVerified: true), isFalse);
    preview.decline(original, _sentAt);
    preview.cancel(original, _sentAt);
    expect(
      preview.inviteFor(replacement.guardianId)!.revision,
      replacement.revision,
    );
    expect(
      preview.inviteFor(replacement.guardianId)!.status,
      ZyraGuardianFamilyInviteStatus.pending,
    );
    expect(preview.freePlaces, reservedFreePlaces);
  });

  test('sending again cannot reset a pending or accepted invitation', () {
    final preview = ZyraGuardianFamilyPreview();
    final invite = _send(preview);
    final reservedFreePlaces = preview.freePlaces;

    ZyraGuardianFamilyInvite? resend() => preview.send(
      guardianId: invite.guardianId,
      guardianName: 'Changed name',
      seekerId: 'other-seeker',
      seekerName: 'Other seeker',
      seekerGender: 'male',
      relationship: 'Father',
      main: false,
      now: _sentAt.add(const Duration(days: 1)),
    );

    expect(resend(), isNull);
    expect(preview.inviteFor(invite.guardianId)!.sentAt, _sentAt);
    expect(preview.accept(invite, _sentAt, identityVerified: true), isTrue);
    expect(resend(), isNull);
    expect(preview.inviteFor(invite.guardianId)!.seekerName, 'Maryam');
    expect(preview.freePlaces, reservedFreePlaces);
  });

  test('guardians retain independent invitation metadata and transitions', () {
    final preview = ZyraGuardianFamilyPreview();
    final first = _send(preview);
    final second = _send(
      preview,
      guardianId: 'guardian-b',
      guardianName: 'Yusuf',
      seekerId: 'seeker-b',
      seekerName: 'Omar',
      seekerGender: 'male',
      relationship: 'Brother',
      main: false,
    );

    preview.decline(first, _sentAt);
    expect(preview.accept(second, _sentAt, identityVerified: true), isTrue);
    expect(
      preview.inviteFor('guardian-a')!.status,
      ZyraGuardianFamilyInviteStatus.declined,
    );
    final accepted = preview.inviteFor('guardian-b')!;
    expect(accepted.status, ZyraGuardianFamilyInviteStatus.accepted);
    expect(accepted.seekerName, 'Omar');
    expect(accepted.pronoun, 'he');
    expect(accepted.relationship, 'Brother');
    expect(accepted.main, isFalse);
    expect(preview.inviteFor('unknown'), isNull);
  });

  test('snapshots and exposed lists do not share mutable state', () {
    final original = ZyraGuardianFamilyPreview();
    final invite = _send(original);
    final restored = ZyraGuardianFamilyPreview(snapshot: original.snapshot);
    final originalFreePlaces = restored.freePlaces;

    expect(() => original.invites.add(invite), throwsUnsupportedError);
    original.decline(invite, _sentAt);
    expect(
      restored.inviteFor(invite.guardianId)!.status,
      ZyraGuardianFamilyInviteStatus.pending,
    );
    expect(restored.freePlaces, originalFreePlaces);
    expect(restored.accept(invite, _sentAt, identityVerified: true), isTrue);
    expect(
      original.inviteFor(invite.guardianId)!.status,
      ZyraGuardianFamilyInviteStatus.declined,
    );
    expect(original.freePlaces, originalFreePlaces + 1);
  });
}
