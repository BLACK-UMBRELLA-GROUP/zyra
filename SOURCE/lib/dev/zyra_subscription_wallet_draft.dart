/// Disposable, fictional subscription examples for the protected Founder UI.
///
/// Nothing in this file reads receipts, grants entitlement, creates a profile,
/// sends an invitation or proves a real Family place exists. Production readers
/// must keep verified role coverage, profile readiness and inventory separate.
enum ZyraWalletRole { seeker, guardian }

extension ZyraWalletRoleLabel on ZyraWalletRole {
  String get label => this == ZyraWalletRole.seeker ? 'Seeker' : 'Guardian';
  ZyraWalletRole get other => this == ZyraWalletRole.seeker
      ? ZyraWalletRole.guardian
      : ZyraWalletRole.seeker;
}

enum ZyraWalletReadiness { ready, unfinished, missing, unknown }

enum ZyraWalletCoverage {
  individualOne,
  assignedFamily,
  basic,
  none,
  unavailable,
}

enum ZyraWalletPlaceState {
  available,
  assignedToSelf,
  assignedToOther,
  invitationPending,
  fundedUntilRenewal,
}

enum ZyraWalletNextStep {
  switchProfile,
  finishSetup,
  usePlace,
  chooseMembership,
  startSetup,
  unavailable,
}

class ZyraWalletRoleFacts {
  const ZyraWalletRoleFacts({required this.readiness, required this.coverage});

  final ZyraWalletReadiness readiness;
  final ZyraWalletCoverage coverage;

  bool get isCovered => switch (coverage) {
    ZyraWalletCoverage.individualOne ||
    ZyraWalletCoverage.assignedFamily ||
    ZyraWalletCoverage.basic => true,
    ZyraWalletCoverage.none || ZyraWalletCoverage.unavailable => false,
  };

  bool get isOne =>
      coverage == ZyraWalletCoverage.individualOne ||
      coverage == ZyraWalletCoverage.assignedFamily;

  String coverageLabel(ZyraWalletRole role) => switch (coverage) {
    ZyraWalletCoverage.individualOne => '${role.label} One · Individual',
    ZyraWalletCoverage.assignedFamily => '${role.label} One · ZYRA Family',
    ZyraWalletCoverage.basic => '${role.label} Basic',
    ZyraWalletCoverage.none => 'No membership confirmed',
    ZyraWalletCoverage.unavailable => 'Coverage unavailable',
  };

  String get readinessLabel => switch (readiness) {
    ZyraWalletReadiness.ready => 'Profile ready',
    ZyraWalletReadiness.unfinished => 'Setup unfinished',
    ZyraWalletReadiness.missing => 'Profile not set up',
    ZyraWalletReadiness.unknown => 'Profile status unavailable',
  };

  ZyraWalletRoleFacts copyWith({
    ZyraWalletReadiness? readiness,
    ZyraWalletCoverage? coverage,
  }) => ZyraWalletRoleFacts(
    readiness: readiness ?? this.readiness,
    coverage: coverage ?? this.coverage,
  );
}

class ZyraWalletPlace {
  const ZyraWalletPlace({
    required this.id,
    required this.role,
    required this.state,
    this.recipient,
  });

  final String id;
  final ZyraWalletRole role;
  final ZyraWalletPlaceState state;
  final String? recipient;

  String get statusLabel => switch (state) {
    ZyraWalletPlaceState.available => 'Available to use or assign',
    ZyraWalletPlaceState.assignedToSelf => 'Used by you',
    ZyraWalletPlaceState.assignedToOther => 'Assigned to $recipient',
    ZyraWalletPlaceState.invitationPending =>
      'Invitation pending · ${recipient ?? 'Recipient'}',
    ZyraWalletPlaceState.fundedUntilRenewal =>
      'Funded until renewal · ${recipient ?? 'Former member'}',
  };

  ZyraWalletPlace copyWith({ZyraWalletPlaceState? state, String? recipient}) =>
      ZyraWalletPlace(
        id: id,
        role: role,
        state: state ?? this.state,
        recipient: recipient ?? this.recipient,
      );
}

/// Owner-bound local view state. Collections are defensive snapshots; a parent
/// may replace this draft, but it must never treat it as live access authority.
class ZyraSubscriptionWalletDraft {
  ZyraSubscriptionWalletDraft({
    required this.ownerId,
    required this.seeker,
    required this.guardian,
    Iterable<ZyraWalletPlace> places = const [],
    this.inventoryAvailable = true,
    this.revision = 0,
  }) : places = List.unmodifiable(places) {
    if (ownerId.isEmpty) throw ArgumentError.value(ownerId, 'ownerId');
    final ids = this.places.map((place) => place.id).toSet();
    if (ids.length != this.places.length || ids.contains('')) {
      throw ArgumentError(
        'Local Family place IDs must be unique and nonempty.',
      );
    }
  }

  final String ownerId;
  final int revision;
  final ZyraWalletRoleFacts seeker;
  final ZyraWalletRoleFacts guardian;
  final List<ZyraWalletPlace> places;
  final bool inventoryAvailable;

  factory ZyraSubscriptionWalletDraft.sample({
    String ownerId = 'local-wallet-sample',
  }) => ZyraSubscriptionWalletDraft(
    ownerId: ownerId,
    seeker: const ZyraWalletRoleFacts(
      readiness: ZyraWalletReadiness.ready,
      coverage: ZyraWalletCoverage.assignedFamily,
    ),
    guardian: const ZyraWalletRoleFacts(
      readiness: ZyraWalletReadiness.ready,
      coverage: ZyraWalletCoverage.individualOne,
    ),
    places: const [
      ZyraWalletPlace(
        id: 'sample-self-seeker',
        role: ZyraWalletRole.seeker,
        state: ZyraWalletPlaceState.assignedToSelf,
      ),
      ZyraWalletPlace(
        id: 'sample-spare-seeker',
        role: ZyraWalletRole.seeker,
        state: ZyraWalletPlaceState.available,
      ),
      ZyraWalletPlace(
        id: 'sample-spare-guardian',
        role: ZyraWalletRole.guardian,
        state: ZyraWalletPlaceState.available,
      ),
      ZyraWalletPlace(
        id: 'sample-amira',
        role: ZyraWalletRole.seeker,
        state: ZyraWalletPlaceState.assignedToOther,
        recipient: 'Amira',
      ),
      ZyraWalletPlace(
        id: 'sample-yusuf-pending',
        role: ZyraWalletRole.guardian,
        state: ZyraWalletPlaceState.invitationPending,
        recipient: 'Yusuf',
      ),
      ZyraWalletPlace(
        id: 'sample-sara-funded',
        role: ZyraWalletRole.seeker,
        state: ZyraWalletPlaceState.fundedUntilRenewal,
        recipient: 'Sara',
      ),
    ],
  );

  ZyraWalletRoleFacts forRole(ZyraWalletRole role) =>
      role == ZyraWalletRole.seeker ? seeker : guardian;

  List<ZyraWalletPlace> availableFor(ZyraWalletRole role) => List.unmodifiable(
    inventoryAvailable
        ? places.where(
            (place) =>
                place.role == role &&
                place.state == ZyraWalletPlaceState.available,
          )
        : const <ZyraWalletPlace>[],
  );

  ZyraSubscriptionWalletDraft copyWith({
    ZyraWalletRoleFacts? seeker,
    ZyraWalletRoleFacts? guardian,
    Iterable<ZyraWalletPlace>? places,
    bool? inventoryAvailable,
  }) => ZyraSubscriptionWalletDraft(
    ownerId: ownerId,
    revision: revision + 1,
    seeker: seeker ?? this.seeker,
    guardian: guardian ?? this.guardian,
    places: places ?? this.places,
    inventoryAvailable: inventoryAvailable ?? this.inventoryAvailable,
  );

  ZyraWalletNextStep nextStep(ZyraWalletRole role) {
    final facts = forRole(role);
    if (facts.readiness == ZyraWalletReadiness.unknown ||
        facts.coverage == ZyraWalletCoverage.unavailable) {
      return ZyraWalletNextStep.unavailable;
    }
    if (facts.isCovered) {
      return facts.readiness == ZyraWalletReadiness.ready
          ? ZyraWalletNextStep.switchProfile
          : ZyraWalletNextStep.finishSetup;
    }
    if (!inventoryAvailable) return ZyraWalletNextStep.unavailable;
    if (availableFor(role).isNotEmpty) return ZyraWalletNextStep.usePlace;
    return facts.readiness == ZyraWalletReadiness.ready
        ? ZyraWalletNextStep.chooseMembership
        : ZyraWalletNextStep.startSetup;
  }

  ZyraSubscriptionWalletDraft withRole(
    ZyraWalletRole role, {
    ZyraWalletReadiness? readiness,
    ZyraWalletCoverage? coverage,
  }) {
    final facts = forRole(
      role,
    ).copyWith(readiness: readiness, coverage: coverage);
    return _replace(
      seeker: role == ZyraWalletRole.seeker ? facts : seeker,
      guardian: role == ZyraWalletRole.guardian ? facts : guardian,
    );
  }

  /// Explicit local confirmation only. Unknown coverage/readiness never turns
  /// into a free place or an unpaid-account assumption.
  ZyraSubscriptionWalletDraft useAvailablePlace(
    ZyraWalletRole role, {
    String? placeId,
  }) {
    final facts = forRole(role);
    if (!inventoryAvailable ||
        facts.isOne ||
        facts.coverage == ZyraWalletCoverage.unavailable ||
        facts.readiness == ZyraWalletReadiness.unknown) {
      return this;
    }
    final candidates = availableFor(role);
    final selected = candidates.where(
      (place) => placeId == null || place.id == placeId,
    );
    if (selected.isEmpty) return this;
    final id = selected.first.id;
    final covered = facts.copyWith(coverage: ZyraWalletCoverage.assignedFamily);
    return _replace(
      seeker: role == ZyraWalletRole.seeker ? covered : seeker,
      guardian: role == ZyraWalletRole.guardian ? covered : guardian,
      places: places.map(
        (place) => place.id == id
            ? place.copyWith(state: ZyraWalletPlaceState.assignedToSelf)
            : place,
      ),
    );
  }

  /// The fictional invitation remains pending, not paid access or a link.
  ZyraSubscriptionWalletDraft assignFictionalRecipient(String placeId) {
    if (!inventoryAvailable) return this;
    final selected = places.where((place) => place.id == placeId);
    if (selected.isEmpty ||
        selected.single.state != ZyraWalletPlaceState.available) {
      return this;
    }
    final recipient = selected.single.role == ZyraWalletRole.seeker
        ? 'Amina'
        : 'Omar';
    return _replace(
      places: places.map(
        (place) => place.id == placeId
            ? place.copyWith(
                state: ZyraWalletPlaceState.invitationPending,
                recipient: recipient,
              )
            : place,
      ),
    );
  }

  ZyraSubscriptionWalletDraft _replace({
    ZyraWalletRoleFacts? seeker,
    ZyraWalletRoleFacts? guardian,
    Iterable<ZyraWalletPlace>? places,
  }) => ZyraSubscriptionWalletDraft(
    ownerId: ownerId,
    revision: revision + 1,
    seeker: seeker ?? this.seeker,
    guardian: guardian ?? this.guardian,
    places: places ?? this.places,
    inventoryAvailable: inventoryAvailable,
  );
}
