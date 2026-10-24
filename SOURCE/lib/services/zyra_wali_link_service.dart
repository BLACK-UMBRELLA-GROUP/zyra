// Wali account linking — Paths 1/2 (Seeker invites Wali) and Path 3
// (Wali invites Seeker), per WALI_ARCHITECTURE_CURRENT_VERSION_V5.md.
// One symmetric mechanism serves both directions: whoever initiates
// creates a wali_invites row (a shareable 8-character code — no SMS/
// email backend exists, so sharing is manual/copy-paste for v1); the
// other party enters that code and accept_wali_invite() (a SECURITY
// DEFINER function — see supabase/migrations/wali_invites_and_
// linking.sql) creates the resulting wali_links row regardless of
// which side is signed in.
//
// Deliberately out of scope here: the Wali One capability/
// entitlement resolution engine (Primary Wali, Path A/B grants) —
// that's unbuilt architecture with no schema representation yet.
// This service only creates the LINK, not any capability grant.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../data/zyra_reference_data.dart';
import '../data/zyra_guardian_capacity.dart';
import '../state/app_state.dart' show ZyraPlan;
import '../main.dart';
import 'zyra_account_state.dart';
import 'zyra_auth.dart';

/// Truth-preserving result for an authenticated server read.
///
/// A successful read may contain an empty collection. [unavailable] means the
/// server did not answer authoritatively, so callers must not turn it into an
/// empty-state claim. Legacy collection-returning methods remain below while
/// older surfaces migrate to this contract.
enum ZyraSourceFailure { notReady, signedOut, requestFailed, invalidResponse }

class ZyraSourceResult<T> {
  final T? _value;
  final ZyraSourceFailure? failure;

  const ZyraSourceResult.available(T value) : _value = value, failure = null;

  const ZyraSourceResult.unavailable(ZyraSourceFailure reason)
    : _value = null,
      failure = reason;

  bool get isAvailable => failure == null;
  bool get isUnavailable => !isAvailable;
  T? get valueOrNull => isAvailable ? _value : null;
  T valueOr(T fallback) => valueOrNull ?? fallback;
}

enum ZyraJourneyGuardianGate {
  ready,
  selfMissing,
  otherMissing,
  bothMissing,
  unavailable,
}

class WaliLinkedPerson {
  final String id;
  final String firstName;

  /// ADDED 2026-08-01. `wali_links.is_main` has existed since the table
  /// was built and is auto-designated on the first active link, but
  /// nothing ever read it — the Seeker's Guardian tab listed every linked
  /// Guardian identically, so the one person who actually acts on the
  /// Journey was indistinguishable from the rest.
  ///
  /// Exactly one link per Seeker carries this. A Seeker has one Main
  /// Guardian; any others are Additional.
  final bool isMain;

  /// How this Guardian is related to their Seeker — the stored CODE
  /// ('father', 'uncle'…), never the label. Use [relationshipLabel] to
  /// display it.
  ///
  /// FIXED 2026-08-06. This field has existed since 2026-08-01 and is
  /// rendered on the Seeker's Guardian tab, but [fetchLinkedPeople] never
  /// selected the column, so it was null for every real user. The only
  /// place "Father" or "Brother" appeared was `ZyraDevScenario.fakeGuardians`
  /// — which is precisely why the tab looked correct in testing and would
  /// have been blank in production.
  ///
  /// Still nullable, and legitimately so: links created before the column
  /// existed have no relationship, and nobody has been asked. A guess would
  /// be inventing data about real people.
  final String? relationship;

  /// Start of this link row's current continuous active period. This is the
  /// server-owned DR-ZYRA-225 boundary, not the row's original creation time.
  /// It remains null for legacy/malformed-free responses where no date was
  /// recorded; callers must say "Not recorded" rather than invent one.
  final DateTime? linkedAt;

  const WaliLinkedPerson({
    required this.id,
    required this.firstName,
    this.isMain = false,
    this.relationship,
    this.linkedAt,
  });

  /// "Paternal Uncle" for the code 'uncle'. Null when unrecorded.
  String? get relationshipLabel => zyraRelationshipLabel(relationship);

  String? get linkedDateLabel => linkedAt == null
      ? null
      : '${linkedAt!.day} ${_shortMonths[linkedAt!.month - 1]} '
            '${linkedAt!.year}';
}

const _shortMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Server-confirmed DR-ZYRA-233 past-summary permission for one Guardian link.
///
/// The opaque link id is retained only to validate response shape and future
/// refreshes; it is never rendered. A null link/Guardian pair is the
/// authoritative no-active-link state and is necessarily OFF. The nullable
/// role flag exists only for that no-link state and is not an authority input.
class GuardianHistoryConsentState {
  final bool enabled;
  final String? activeGuardianLinkId;
  final String? guardianId;
  final bool? guardianIsMain;

  const GuardianHistoryConsentState({
    required this.enabled,
    required this.activeGuardianLinkId,
    required this.guardianId,
    required this.guardianIsMain,
  });

  static GuardianHistoryConsentState? fromRow(Map<String, dynamic> row) {
    final rawEnabled = row['enabled'];
    final legacy = row.containsKey('active_main_link_id');
    final rawLinkId = legacy
        ? row['active_main_link_id']
        : row['active_guardian_link_id'];
    final rawGuardianId = legacy ? row['main_guardian_id'] : row['guardian_id'];
    final rawIsMain = legacy
        ? (rawLinkId == null ? null : true)
        : row['guardian_is_main'];
    if (rawEnabled is! bool ||
        (rawLinkId != null && rawLinkId is! String) ||
        (rawGuardianId != null && rawGuardianId is! String) ||
        (rawIsMain != null && rawIsMain is! bool) ||
        (rawLinkId is String && rawLinkId.isEmpty) ||
        (rawGuardianId is String && rawGuardianId.isEmpty) ||
        ((rawLinkId == null) != (rawGuardianId == null)) ||
        ((rawLinkId == null) != (rawIsMain == null)) ||
        (rawEnabled && rawLinkId == null)) {
      return null;
    }
    return GuardianHistoryConsentState(
      enabled: rawEnabled,
      activeGuardianLinkId: rawLinkId as String?,
      guardianId: rawGuardianId as String?,
      guardianIsMain: rawIsMain as bool?,
    );
  }
}

/// Server-confirmed per-Journey access for one Guardian linked to the
/// signed-in Seeker.
///
/// Main is always included and cannot be changed. An Additional Guardian may
/// be included or removed by the Seeker for each active Journey. The client
/// never infers access from role labels or keeps an optimistic switch state.
class GuardianJourneyAccessState {
  final String attemptId;
  final String matchId;
  final String counterpartFirstName;
  final bool included;
  final bool canChange;
  final bool guardianIsMain;
  final bool chatAvailable;
  final bool chatEnabled;

  /// Explicit presentation proof supplied only by the fictional agreement
  /// owner. Never inferred from payment or parsed from an undeployed RPC.
  final bool requiredByPaidAgreement;

  const GuardianJourneyAccessState({
    required this.attemptId,
    required this.matchId,
    required this.counterpartFirstName,
    required this.included,
    required this.canChange,
    required this.guardianIsMain,
    this.chatAvailable = false,
    this.chatEnabled = false,
    this.requiredByPaidAgreement = false,
  });

  static GuardianJourneyAccessState? fromRow(Map<String, dynamic> row) {
    final attemptId = row['attempt_id'];
    final matchId = row['match_id'];
    final counterpart = row['counterpart_first_name'];
    final included = row['included'];
    final canChange = row['can_change'];
    final guardianIsMain = row['guardian_is_main'];
    final chatAvailable = row['chat_available'];
    final chatEnabled = row['chat_enabled'];
    // Separate from the Seeker's permission switch: the server must confirm
    // paid Guardian chat authority for THIS linked Guardian. A legacy true
    // chat_available, the Main role, or the viewer's plan is not payment proof.
    // Until that producer is deployed, retain View but fail closed for Chat.
    final chatEntitled = row['guardian_chat_entitled'];
    if (attemptId is! String ||
        attemptId.isEmpty ||
        matchId is! String ||
        matchId.isEmpty ||
        counterpart is! String ||
        counterpart.trim().isEmpty ||
        included is! bool ||
        canChange is! bool ||
        guardianIsMain is! bool ||
        (chatAvailable != null && chatAvailable is! bool) ||
        (chatEnabled != null && chatEnabled is! bool) ||
        (chatEntitled != null && chatEntitled is! bool) ||
        (chatEnabled == true && included != true) ||
        (guardianIsMain && (!included || canChange))) {
      return null;
    }
    return GuardianJourneyAccessState(
      attemptId: attemptId,
      matchId: matchId,
      counterpartFirstName: counterpart.trim(),
      included: included,
      canChange: canChange,
      guardianIsMain: guardianIsMain,
      chatAvailable: chatEntitled == true && chatAvailable == true,
      chatEnabled:
          chatEntitled == true && chatAvailable == true && chatEnabled == true,
    );
  }
}

/// One thing a Guardian actually did. Never synthesised — every instance
/// corresponds to a real row with a real timestamp.
///
/// Founder, 2026-08-06: *"I don't want fake activity. Only show activity
/// when something has genuinely happened."* Two requested types are
/// deliberately absent, and their absence is the honest answer rather than a
/// gap: `became_main` has no timestamp anywhere (and would duplicate
/// `linked` on the same day for a first Guardian), and `invited_to_journey`
/// has no event at all, because participation is derived from the link
/// rather than granted by an invitation.
class GuardianActivity {
  final String waliId;
  final String type;
  final DateTime occurredAt;
  final String? detail;

  const GuardianActivity({
    required this.waliId,
    required this.type,
    required this.occurredAt,
    this.detail,
  });

  /// Null when a row cannot safely be represented. A structurally valid
  /// unknown type is retained with [line] == null so raw server vocabulary is
  /// never exposed while the caller can still distinguish it from a malformed
  /// response.
  static GuardianActivity? fromRow(Map<String, dynamic> r) {
    final rawWaliId = r['wali_id'];
    final rawType = r['activity_type'];
    final rawOccurredAt = r['occurred_at'];
    if (rawWaliId is! String ||
        rawWaliId.isEmpty ||
        rawType is! String ||
        rawType.isEmpty) {
      return null;
    }
    final occurredAt = switch (rawOccurredAt) {
      DateTime value => value,
      String value => DateTime.tryParse(value),
      _ => null,
    };
    if (occurredAt == null) return null;
    final rawDetail = r['detail'];
    return GuardianActivity(
      waliId: rawWaliId,
      type: rawType,
      occurredAt: occurredAt.toLocal(),
      detail: rawDetail is String ? rawDetail : null,
    );
  }

  /// Privacy-safe summary vocabulary agreed in DR-ZYRA-216. Detail values are
  /// deliberately absent: a suggestion's third-party name and a Family
  /// Review's raw decision do not belong on a summary card.
  String? get line => switch (type) {
    'linked' => 'Guardian link active',
    'suggested' => 'Shared a profile suggestion',
    'review_answered' => 'Family Review completed',
    'review_waiting' => 'Family Review is open',
    _ => null,
  };

  /// Context for the stored timestamp. `review_waiting.occurred_at` is the
  /// review opening time, while `linked.occurred_at` is the link date.
  String? get timingLabel => timingLabelAt(DateTime.now());

  String? timingLabelAt(DateTime comparisonNow) => switch (type) {
    'linked' => 'Linked ${whenLabelAt(comparisonNow)}',
    'review_waiting' => 'Opened ${whenLabelAt(comparisonNow)}',
    'suggested' || 'review_answered' => whenLabelAt(comparisonNow),
    _ => null,
  };

  /// Current review state, not an accusation or an action the Seeker can take.
  bool get isOutstanding => type == 'review_waiting';

  /// "today", "3 days ago", then a date once relative time stops helping.
  String get whenLabel => whenLabelAt(DateTime.now());

  String whenLabelAt(DateTime comparisonNow) {
    final d = comparisonNow.difference(occurredAt);
    if (d.inDays == 0) return 'today';
    if (d.inDays == 1) return 'yesterday';
    if (d.inDays < 30) return '${d.inDays} days ago';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${occurredAt.day} ${months[occurredAt.month - 1]} ${occurredAt.year}';
  }
}

/// An invite code that has been generated but not yet redeemed.
///
/// [label] is the SENDER'S private note for who they meant it for, and is
/// never shown to anyone else — `wali_invites_select` is scoped to
/// `inviter_id`, and `preview_wali_invite` cannot return it. It is not a
/// claim about who holds the code: whoever redeems it becomes the Guardian.
class PendingInvite {
  final String token;
  final String? label;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const PendingInvite({
    required this.token,
    required this.createdAt,
    this.label,
    this.expiresAt,
  });

  static PendingInvite? fromRow(Map<String, dynamic> row) {
    final token = row['token'];
    final rawCreatedAt = row['created_at'];
    if (token is! String || token.isEmpty) return null;
    final createdAt = switch (rawCreatedAt) {
      DateTime value => value,
      String value => DateTime.tryParse(value),
      _ => null,
    };
    if (createdAt == null) return null;
    final rawExpiresAt = row['expires_at'];
    final expiresAt = switch (rawExpiresAt) {
      null => null,
      DateTime value => value,
      String value => DateTime.tryParse(value),
      _ => null,
    };
    if (rawExpiresAt != null && expiresAt == null) return null;
    final rawLabel = row['label'];
    return PendingInvite(
      token: token,
      label: rawLabel is String ? rawLabel : null,
      createdAt: createdAt.toLocal(),
      expiresAt: expiresAt?.toLocal(),
    );
  }

  /// Days until it lapses, or null where no expiry is recorded.
  int? get daysLeft {
    return daysLeftAt(DateTime.now());
  }

  /// Clock-injected expiry calculation for deterministic visual fixtures.
  int? daysLeftAt(DateTime comparisonNow) {
    if (expiresAt == null) return null;
    final d = expiresAt!.difference(comparisonNow).inDays;
    return d < 0 ? 0 : d;
  }
}

/// The caller's permanent, role-specific discovery handle.
class ZyraPersonalCode {
  final String code;
  final String roleContext;

  const ZyraPersonalCode({required this.code, required this.roleContext});

  static ZyraPersonalCode? fromRow(Map<String, dynamic> row) {
    final code = row['code'];
    final role = row['role_context'];
    if (code is! String ||
        !RegExp(r'^ZYRA-[0-9A-F]{4}(?:-[0-9A-F]{4}){4}$').hasMatch(code) ||
        (role != 'seeker' && role != 'wali')) {
      return null;
    }
    return ZyraPersonalCode(code: code, roleContext: role as String);
  }
}

/// Privacy-minimised code preview. The server intentionally returns no photo
/// and no verification claim.
class ZyraPersonalCodePreview {
  final String firstName;
  final String role;

  const ZyraPersonalCodePreview({required this.firstName, required this.role});

  static ZyraPersonalCodePreview? fromRow(Map<String, dynamic> row) {
    final firstName = row['owner_first_name'];
    final role = row['owner_role'];
    if (firstName is! String ||
        firstName.trim().isEmpty ||
        (role != 'seeker' && role != 'wali')) {
      return null;
    }
    return ZyraPersonalCodePreview(
      firstName: firstName.trim(),
      role: role as String,
    );
  }
}

class ZyraGuardianLinkRequest {
  final String id;
  final String direction;
  final String otherFirstName;
  final String otherRole;
  final String status;
  final String? relationship;
  final DateTime createdAt;
  final DateTime expiresAt;

  const ZyraGuardianLinkRequest({
    required this.id,
    required this.direction,
    required this.otherFirstName,
    required this.otherRole,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.relationship,
  });

  bool get isIncoming => direction == 'incoming';
  bool get isPending => status == 'pending';

  static ZyraGuardianLinkRequest? fromRow(Map<String, dynamic> row) {
    final id = row['request_id'];
    final direction = row['direction'];
    final name = row['other_first_name'];
    final role = row['other_role'];
    final status = row['status'];
    final created = DateTime.tryParse(row['created_at']?.toString() ?? '');
    final expires = DateTime.tryParse(row['expires_at']?.toString() ?? '');
    final relationship = row['relationship'];
    if (id is! String ||
        id.isEmpty ||
        (direction != 'incoming' && direction != 'outgoing') ||
        name is! String ||
        name.trim().isEmpty ||
        (role != 'seeker' && role != 'wali') ||
        status is! String ||
        created == null ||
        expires == null ||
        (relationship != null && relationship is! String)) {
      return null;
    }
    return ZyraGuardianLinkRequest(
      id: id,
      direction: direction as String,
      otherFirstName: name.trim(),
      otherRole: role as String,
      status: status,
      relationship: relationship as String?,
      createdAt: created.toLocal(),
      expiresAt: expires.toLocal(),
    );
  }
}

class ZyraWaliLinkService {
  static bool? _guardianAccessReadyForTesting;

  /// Synthetic SDK tests only; assertions are disabled in delivered builds.
  @visibleForTesting
  static void setGuardianAccessReadyForTesting(bool? value) {
    assert(() {
      _guardianAccessReadyForTesting = value;
      return true;
    }());
  }

  ZyraWaliLinkService._();

  /// In-process refresh signal for screens that present the same Guardian
  /// link state in different tabs. The database remains authoritative; this
  /// notifier carries no rows and grants no capability. It only tells an
  /// already-mounted reader to fetch again after a successful mutation.
  static final ValueNotifier<int> linkRevision = ValueNotifier<int>(0);
  static final ValueNotifier<int> invitationRevision = ValueNotifier<int>(0);

  static void _markLinksChanged() {
    linkRevision.value += 1;
  }

  static void _markInvitationsChanged() {
    invitationRevision.value += 1;
  }

  static Future<ZyraSourceResult<ZyraPersonalCode>> personalCode({
    String? roleContext,
  }) async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc(
        'zyra_my_personal_code',
        params: {'p_role_context': roleContext},
      );
      if (raw is! List || raw.length != 1 || raw.single is! Map) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final code = ZyraPersonalCode.fromRow(
        Map<String, dynamic>.from(raw.single as Map),
      );
      return code == null
          ? const ZyraSourceResult.unavailable(
              ZyraSourceFailure.invalidResponse,
            )
          : ZyraSourceResult.available(code);
    } catch (e) {
      debugPrint('ZYRA: personalCode failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  static Future<ZyraSourceResult<ZyraPersonalCode>> rotatePersonalCode({
    String? roleContext,
  }) async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc(
        'zyra_rotate_my_personal_code',
        params: {'p_role_context': roleContext},
      );
      if (raw is! List || raw.length != 1 || raw.single is! Map) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final code = ZyraPersonalCode.fromRow(
        Map<String, dynamic>.from(raw.single as Map),
      );
      return code == null
          ? const ZyraSourceResult.unavailable(
              ZyraSourceFailure.invalidResponse,
            )
          : ZyraSourceResult.available(code);
    } catch (e) {
      debugPrint('ZYRA: rotatePersonalCode failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  /// Available(null) is an authoritative invalid/unavailable code. A failed
  /// server read remains unavailable and must not be rendered as that claim.
  static Future<ZyraSourceResult<ZyraPersonalCodePreview?>> previewPersonalCode(
    String code,
  ) async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc(
        'zyra_preview_personal_code',
        params: {'p_code': code},
      );
      if (raw is! List) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      if (raw.isEmpty) {
        return const ZyraSourceResult.available(null);
      }
      if (raw.length != 1 || raw.single is! Map) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final preview = ZyraPersonalCodePreview.fromRow(
        Map<String, dynamic>.from(raw.single as Map),
      );
      return preview == null
          ? const ZyraSourceResult.unavailable(
              ZyraSourceFailure.invalidResponse,
            )
          : ZyraSourceResult.available(preview);
    } catch (e) {
      debugPrint('ZYRA: previewPersonalCode failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  static Future<String?> requestGuardianLink(
    String code, {
    String? relationship,
    required ZyraPlan? currentSeekerPlan,
  }) async {
    final userId = ZyraAuth.currentUser?.id;
    if (userId == null) return 'You are not signed in.';
    final generation = ZyraAccountState.generation;
    const staleMessage =
        'Your account changed. Please check your Guardian requests before continuing.';
    bool isCurrentAccount() =>
        ZyraAuth.currentUser?.id == userId &&
        ZyraAccountState.isCurrent(userId, generation);

    if (!isCurrentAccount()) return staleMessage;
    if (currentSeekerPlan != null) {
      final capacity = await guardianCapacityForCurrentSeeker(
        plan: currentSeekerPlan,
      );
      if (!isCurrentAccount()) return staleMessage;
      if (!capacity.canAdd) return capacity.message;
    }
    try {
      if (!isCurrentAccount()) return staleMessage;
      final requestId = await supabase.rpc(
        'zyra_request_guardian_link',
        params: {'p_code': code, 'p_relationship': relationship},
      );
      if (!isCurrentAccount()) return staleMessage;
      if (requestId is! String || requestId.isEmpty) {
        return 'That code is not available.';
      }
      _markInvitationsChanged();
      return null;
    } catch (e) {
      if (!isCurrentAccount()) return staleMessage;
      final message = e.toString();
      if (message.contains('request_already_pending')) {
        return 'You already have a request waiting with this person.';
      }
      if (message.contains('relationship_required')) {
        return 'Choose how you are related before sending the request.';
      }
      if (message.contains('already_linked')) {
        return 'You are already linked.';
      }
      if (message.contains('code_unavailable')) {
        return 'That code is not available.';
      }
      debugPrint('ZYRA: requestGuardianLink failed — $e');
      return "That request didn't go through. Please try again.";
    }
  }

  static Future<ZyraSourceResult<List<ZyraGuardianLinkRequest>>>
  guardianLinkRequests() async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc('zyra_my_guardian_requests');
      if (raw is! List) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final requests = <ZyraGuardianLinkRequest>[];
      for (final row in raw) {
        if (row is! Map) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        final request = ZyraGuardianLinkRequest.fromRow(
          Map<String, dynamic>.from(row),
        );
        if (request == null) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        requests.add(request);
      }
      return ZyraSourceResult.available(requests);
    } catch (e) {
      debugPrint('ZYRA: guardianLinkRequests failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  static Future<String?> acceptGuardianLinkRequest(
    String requestId, {
    String? relationship,
    required ZyraPlan? currentSeekerPlan,
  }) async {
    final userId = ZyraAuth.currentUser?.id;
    if (userId == null) return 'You are not signed in.';
    final generation = ZyraAccountState.generation;
    const staleMessage =
        'Your account changed. Please check your Guardian requests before continuing.';
    bool isCurrentAccount() =>
        ZyraAuth.currentUser?.id == userId &&
        ZyraAccountState.isCurrent(userId, generation);

    if (!isCurrentAccount()) return staleMessage;
    if (currentSeekerPlan != null) {
      final capacity = await guardianCapacityForCurrentSeeker(
        plan: currentSeekerPlan,
      );
      if (!isCurrentAccount()) return staleMessage;
      if (!capacity.canAdd) return capacity.message;
    }
    try {
      if (!isCurrentAccount()) return staleMessage;
      await supabase.rpc(
        'zyra_accept_guardian_request',
        params: {'p_request_id': requestId, 'p_relationship': relationship},
      );
      if (!isCurrentAccount()) return staleMessage;
      _markLinksChanged();
      _markInvitationsChanged();
      return null;
    } catch (e) {
      if (!isCurrentAccount()) return staleMessage;
      final message = e.toString();
      if (message.contains('relationship_required')) {
        return 'Choose how you are related before accepting.';
      }
      if (message.contains('request_expired')) {
        return 'This request has expired.';
      }
      if (message.contains('request_not_pending')) {
        return 'This request has already been answered.';
      }
      debugPrint('ZYRA: acceptGuardianLinkRequest failed — $e');
      return "That didn't go through. Please try again.";
    }
  }

  static Future<bool> declineGuardianLinkRequest(String requestId) async {
    try {
      final userId = ZyraAuth.currentUser?.id;
      if (userId == null) return false;
      final generation = ZyraAccountState.generation;
      bool isCurrentAccount() =>
          ZyraAuth.currentUser?.id == userId &&
          ZyraAccountState.isCurrent(userId, generation);

      if (!isCurrentAccount()) return false;
      final dynamic ok;
      try {
        ok = await supabase.rpc(
          'zyra_decline_guardian_request',
          params: {'p_request_id': requestId},
        );
      } catch (_) {
        if (!isCurrentAccount()) return false;
        rethrow;
      }
      if (!isCurrentAccount()) return false;
      if (ok == true) _markInvitationsChanged();
      return ok == true;
    } catch (e) {
      debugPrint('ZYRA: declineGuardianLinkRequest failed — $e');
      return false;
    }
  }

  static Future<bool> cancelGuardianLinkRequest(String requestId) async {
    try {
      final userId = ZyraAuth.currentUser?.id;
      if (userId == null) return false;
      final generation = ZyraAccountState.generation;
      bool isCurrentAccount() =>
          ZyraAuth.currentUser?.id == userId &&
          ZyraAccountState.isCurrent(userId, generation);

      if (!isCurrentAccount()) return false;
      final dynamic ok;
      try {
        ok = await supabase.rpc(
          'zyra_cancel_guardian_request',
          params: {'p_request_id': requestId},
        );
      } catch (_) {
        if (!isCurrentAccount()) return false;
        rethrow;
      }
      if (!isCurrentAccount()) return false;
      if (ok == true) _markInvitationsChanged();
      return ok == true;
    } catch (e) {
      debugPrint('ZYRA: cancelGuardianLinkRequest failed — $e');
      return false;
    }
  }

  /// Every Guardian's activity, grouped by Guardian, newest first.
  ///
  /// A successful empty map means the server recorded no activity. Any failed
  /// or malformed read remains unavailable so a surface cannot claim that
  /// nothing happened when it simply could not refresh.
  static Future<ZyraSourceResult<Map<String, List<GuardianActivity>>>>
  fetchActivityResult() async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc('zyra_guardian_activity');
      if (raw is! List) {
        debugPrint('ZYRA: zyra_guardian_activity returned an invalid response');
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final out = <String, List<GuardianActivity>>{};
      for (final row in raw) {
        if (row is! Map) {
          debugPrint('ZYRA: zyra_guardian_activity returned a malformed row');
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        final activity = GuardianActivity.fromRow(
          Map<String, dynamic>.from(row),
        );
        if (activity == null) {
          debugPrint('ZYRA: zyra_guardian_activity returned a malformed row');
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        final a = activity;
        (out[a.waliId] ??= []).add(a);
      }
      return ZyraSourceResult.available(out);
    } catch (e) {
      debugPrint('ZYRA: zyra_guardian_activity failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  /// Compatibility bridge for callers not yet migrated to
  /// [fetchActivityResult]. New user-facing surfaces must use the typed result.
  static Future<Map<String, List<GuardianActivity>>> fetchActivity() async =>
      (await fetchActivityResult()).valueOr(const {});

  /// Server-confirmed Main-Guardian hold for one shared Journey.
  ///
  /// During the staged migration interval the new RPC is not present. The
  /// narrow fallback checks only the caller and is safe under the previously
  /// live DR-ZYRA-136 invariant, which did not permit either party in an
  /// Active Journey to enter a no-Main state. Once DR-ZYRA-236 is applied,
  /// the RPC exists and both sides are checked without disclosing identity.
  static Future<ZyraJourneyGuardianGate> fetchJourneyGuardianGate(
    String matchId,
  ) async {
    try {
      final raw = await supabase.rpc(
        'zyra_journey_main_guardian_gate',
        params: {'p_match_id': matchId},
      );
      final row = raw is List
          ? Map<String, dynamic>.from(raw.single as Map)
          : Map<String, dynamic>.from(raw as Map);
      final selfHasMain = row['self_has_main'] as bool?;
      final otherHasMain = row['other_has_main'] as bool?;
      if (selfHasMain == null || otherHasMain == null) {
        return ZyraJourneyGuardianGate.unavailable;
      }
      return switch ((selfHasMain, otherHasMain)) {
        (true, true) => ZyraJourneyGuardianGate.ready,
        (false, true) => ZyraJourneyGuardianGate.selfMissing,
        (true, false) => ZyraJourneyGuardianGate.otherMissing,
        (false, false) => ZyraJourneyGuardianGate.bothMissing,
      };
    } catch (error) {
      final message = error.toString();
      final stagedRpcMissing =
          message.contains('PGRST202') ||
          (message.contains('zyra_journey_main_guardian_gate') &&
              message.contains('Could not find'));
      if (!stagedRpcMissing) {
        debugPrint('ZYRA: fetchJourneyGuardianGate($matchId) failed — $error');
        return ZyraJourneyGuardianGate.unavailable;
      }

      final links = await fetchLinkedPeopleResult(asWali: false);
      if (links.isUnavailable) return ZyraJourneyGuardianGate.unavailable;
      return links
              .valueOr(const <WaliLinkedPerson>[])
              .any((person) => person.isMain)
          ? ZyraJourneyGuardianGate.ready
          : ZyraJourneyGuardianGate.selfMissing;
    }
  }

  /// Promotes a linked Guardian to Main. Returns true on success.
  ///
  /// Exactly one Main per Seeker is enforced by a partial unique index,
  /// `wali_links_one_main_per_seeker`, so this cannot produce two — the RPC
  /// demotes the incumbent before promoting, which is also the only order
  /// that satisfies the `auto_designate_main_wali` trigger sitting on the
  /// same column.
  static Future<bool> setMainGuardian(String waliId) async {
    if (ZyraAuth.currentUser == null) return false;
    try {
      final ok = await supabase.rpc(
        'zyra_set_main_guardian',
        params: {'p_wali_id': waliId},
      );
      if (ok == true) _markLinksChanged();
      return ok == true;
    } catch (e) {
      debugPrint('ZYRA: setMainGuardian($waliId) failed — $e');
      return false;
    }
  }

  /// Demotes the caller's current Main Guardian without unlinking them.
  ///
  /// The resulting no-Main state is deliberate under DR-ZYRA-236: My ZYRA
  /// raises an action and ordinary Active Journey participation stays held
  /// until the Seeker assigns a Main Guardian. The Guardian remains linked as
  /// an Additional Guardian, so this is distinct from [removeGuardian].
  static Future<bool> clearMainGuardian(String waliId) async {
    if (ZyraAuth.currentUser == null) return false;
    try {
      final ok = await supabase.rpc(
        'zyra_clear_main_guardian',
        params: {'p_wali_id': waliId},
      );
      if (ok == true) _markLinksChanged();
      return ok == true;
    } catch (e) {
      debugPrint('ZYRA: clearMainGuardian($waliId) failed — $e');
      return false;
    }
  }

  /// Unlinks a Guardian.
  ///
  /// Returns `null` on success, or a user-facing message on failure.
  ///
  /// Removing a Main Guardian does not silently promote someone else. Under
  /// DR-ZYRA-236 the resulting no-Main state is surfaced in My ZYRA and holds
  /// ordinary Active Journey participation until the Seeker chooses a Main.
  static Future<String?> removeGuardian(String waliId) async {
    if (ZyraAuth.currentUser == null) return 'You are not signed in.';
    try {
      final ok = await supabase.rpc(
        'zyra_remove_guardian',
        params: {'p_wali_id': waliId},
      );
      if (ok == true) {
        _markLinksChanged();
        return null;
      }
      return "That didn't go through. Please try again.";
    } on PostgrestException catch (e) {
      final m = e.message;
      if (m.contains('main_guardian_must_be_reassigned')) {
        return 'Choose a new Main Guardian before removing this one.';
      }
      if (m.contains('not_your_guardian')) {
        return 'They are no longer linked to you.';
      }
      if (m.contains('guardian_required_during_journey')) {
        return e.hint?.trim().isNotEmpty == true
            ? e.hint!.trim()
            : 'An active or paused Journey requires you to keep a Guardian. '
                  'Assign another Guardian where possible, or end the Journey '
                  'through the governed flow before removing this one.';
      }
      debugPrint('ZYRA: removeGuardian($waliId) failed — $e');
      return "That didn't go through. Please try again.";
    } catch (e) {
      final m = e.toString();
      if (m.contains('main_guardian_must_be_reassigned')) {
        return 'Choose a new Main Guardian before removing this one.';
      }
      if (m.contains('not_your_guardian')) {
        return 'They are no longer linked to you.';
      }
      // DR-ZYRA-136 / OA-ZYRA-173, added 2026-08-10. Removing your LAST
      // Guardian during a live Journey is refused server-side, because it
      // hands your family's Family Review vote to the other family.
      //
      // The message names both ways out on purpose. A refusal that only says
      // no reads as the app trapping you in a Journey, which is exactly the
      // harm the Founder accepted this rule's cost against — ending and
      // pausing are always free, and the copy has to say so.
      if (m.contains('guardian_required_during_journey')) {
        return 'An active or paused Journey requires you to keep a Guardian. '
            'Assign another Guardian where possible, or end the Journey '
            'through the governed flow before removing this one.';
      }
      debugPrint('ZYRA: removeGuardian($waliId) failed — $e');
      return "That didn't go through. Please try again.";
    }
  }

  /// Reads or changes one linked Guardian's DR-ZYRA-233 past-summary
  /// permission and returns only the state confirmed by the server. Null
  /// reads; true grants; false revokes.
  static Future<ZyraSourceResult<GuardianHistoryConsentState>>
  guardianHistoryConsent({
    required String guardianId,
    bool guardianIsMain = false,
    bool? enabled,
  }) async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    if (guardianId.isEmpty) {
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.invalidResponse,
      );
    }
    try {
      final raw = await supabase.rpc(
        'zyra_guardian_history_consent',
        params: {'p_guardian': guardianId, 'p_enabled': enabled},
      );
      if (raw is! List || raw.length != 1 || raw.single is! Map) {
        debugPrint(
          'ZYRA: Guardian history permission returned an invalid response',
        );
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final state = GuardianHistoryConsentState.fromRow(
        Map<String, dynamic>.from(raw.single as Map),
      );
      if (state == null || state.guardianId != guardianId) {
        debugPrint(
          'ZYRA: Guardian history permission returned a malformed row',
        );
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      return ZyraSourceResult.available(state);
    } catch (e) {
      debugPrint('ZYRA: guardianHistoryConsent failed — $e');
      // The generic RPC is staged behind DR-ZYRA-233. Preserve the already-
      // live Main-Guardian control while the migration is awaiting its
      // separate apply gate; Additional Guardians fail closed until then.
      if (guardianIsMain) {
        return mainGuardianHistoryConsent(enabled: enabled);
      }
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  /// Compatibility client for the already-live Main-only RPC. Retained so an
  /// older server remains readable during the staged migration interval.
  static Future<ZyraSourceResult<GuardianHistoryConsentState>>
  mainGuardianHistoryConsent({bool? enabled}) async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc(
        'zyra_main_guardian_history_consent',
        params: {'p_enabled': enabled},
      );
      if (raw is! List || raw.length != 1 || raw.single is! Map) {
        debugPrint('ZYRA: history consent returned an invalid response');
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final state = GuardianHistoryConsentState.fromRow(
        Map<String, dynamic>.from(raw.single as Map),
      );
      if (state == null) {
        debugPrint('ZYRA: history consent returned a malformed row');
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      return ZyraSourceResult.available(state);
    } catch (e) {
      debugPrint('ZYRA: mainGuardianHistoryConsent failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  /// Reads or changes one linked Guardian's access to the caller's active
  /// Journeys. A null [attemptId]/[enabled] pair is a read. Writes are accepted
  /// only when the response confirms the requested server state.
  static Future<ZyraSourceResult<List<GuardianJourneyAccessState>>>
  guardianJourneyAccess({
    required String guardianId,
    String? attemptId,
    bool? enabled,
    bool? chatEnabled,
  }) async {
    if (!(_guardianAccessReadyForTesting ?? supabaseReady)) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    final ownerId = ZyraAuth.currentUser?.id;
    if (ownerId == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    final generation = ZyraAccountState.generation;
    bool stillOwner() =>
        ZyraAuth.currentUser?.id == ownerId &&
        ZyraAccountState.isCurrent(ownerId, generation);
    if (!stillOwner()) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    if (guardianId.isEmpty ||
        (attemptId == null && (enabled != null || chatEnabled != null)) ||
        (attemptId != null && enabled == null && chatEnabled == null)) {
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.invalidResponse,
      );
    }
    // A direct caller cannot bypass the disabled widget. Confirm current
    // server-owned availability before asking to enable Chat; do not use a
    // cached local Guardian plan or borrow the Seeker's subscription.
    if (chatEnabled == true) {
      final access = await guardianJourneyAccess(guardianId: guardianId);
      if (!stillOwner()) {
        return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
      }
      final target = access.valueOrNull
          ?.where((state) => state.attemptId == attemptId)
          .firstOrNull;
      if (target == null || !target.included || !target.chatAvailable) {
        return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
      }
    }
    try {
      final raw = await supabase.rpc(
        'zyra_guardian_journey_access',
        params: {
          'p_guardian': guardianId,
          'p_attempt': attemptId,
          'p_enabled': enabled,
          'p_chat_enabled': chatEnabled,
        },
      );
      if (!stillOwner()) {
        return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
      }
      if (raw is! List) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final states = <GuardianJourneyAccessState>[];
      final attempts = <String>{};
      for (final item in raw) {
        if (item is! Map) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        final state = GuardianJourneyAccessState.fromRow(
          Map<String, dynamic>.from(item),
        );
        if (state == null || !attempts.add(state.attemptId)) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        states.add(state);
      }
      if (attemptId != null) {
        final confirmed = states.where((state) => state.attemptId == attemptId);
        if (confirmed.length != 1 ||
            (enabled != null && confirmed.single.included != enabled) ||
            (chatEnabled != null &&
                confirmed.single.chatEnabled != chatEnabled)) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
      }
      return ZyraSourceResult.available(List.unmodifiable(states));
    } catch (e) {
      debugPrint('ZYRA: guardianJourneyAccess failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  /// Cancels an invite code you sent. Returns true if it was still pending
  /// and is now revoked.
  ///
  /// Only pending invites can be revoked. An accepted invite is a live
  /// Guardian link, and unlinking a real person is a different action with
  /// different consequences — it does not happen quietly from a list of
  /// codes.
  static Future<bool> revokeInvite(String token) async {
    if (ZyraAuth.currentUser == null) return false;
    try {
      final ok = await supabase.rpc(
        'zyra_revoke_wali_invite',
        params: {'p_token': token},
      );
      if (ok == true) _markInvitationsChanged();
      return ok == true;
    } catch (e) {
      debugPrint('ZYRA: revokeInvite failed (${e.runtimeType}).');
      return false;
    }
  }

  /// Declines an invitation code the signed-in recipient has previewed.
  /// Returns null on success or a user-facing failure message.
  static Future<String?> declineInvite(String token) async {
    if (ZyraAuth.currentUser == null) return 'You are not signed in.';
    try {
      final ok = await supabase.rpc(
        'zyra_decline_wali_invite',
        params: {'p_token': token.trim().toUpperCase()},
      );
      if (ok == true) _markInvitationsChanged();
      return ok == true ? null : "That didn't go through. Please try again.";
    } catch (e) {
      final message = e.toString();
      if (message.contains('invite_expired')) {
        return 'This code has expired.';
      }
      if (message.contains('invite_not_pending')) {
        return 'That invitation has already been answered.';
      }
      if (message.contains('cannot_decline_own_invite')) {
        return "That's your own invite code.";
      }
      debugPrint('ZYRA: declineInvite failed (${e.runtimeType}).');
      return "That didn't go through. Please try again.";
    }
  }

  /// Lazy Guardian-invite lifecycle sweep. The server scopes this to invites
  /// sent by the signed-in account and makes both reminders one-shot.
  static Future<void> expireDueInvites() async {
    if (ZyraAuth.currentUser == null) return;
    try {
      await supabase.rpc('zyra_expire_due_wali_invites');
    } catch (e) {
      // Loading the Guardian surface must still work if the lifecycle sweep
      // is temporarily unavailable; logging keeps the delay observable.
      debugPrint('ZYRA: expireDueInvites failed — $e');
    }
  }

  /// Invite codes this user has sent that nobody has redeemed yet.
  /// Successful empty and failed refresh remain distinct.
  static Future<ZyraSourceResult<List<PendingInvite>>>
  fetchPendingInvitesResult() async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    final user = ZyraAuth.currentUser;
    if (user == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    await expireDueInvites();
    try {
      final rows =
          await supabase
                  .from('wali_invites')
                  .select('token, label, created_at, expires_at')
                  .eq('inviter_id', user.id)
                  .eq('source', 'legacy_code')
                  .eq('status', 'pending')
                  .order('created_at', ascending: false)
              as List;
      final invites = <PendingInvite>[];
      for (final row in rows) {
        if (row is! Map) {
          debugPrint('ZYRA: fetchPendingInvites returned a malformed row');
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        final invite = PendingInvite.fromRow(Map<String, dynamic>.from(row));
        if (invite == null) {
          debugPrint('ZYRA: fetchPendingInvites returned a malformed row');
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        invites.add(invite);
      }
      return ZyraSourceResult.available(invites);
    } catch (e) {
      debugPrint('ZYRA: fetchPendingInvites failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  /// Compatibility bridge for callers not yet migrated to
  /// [fetchPendingInvitesResult].
  static Future<List<PendingInvite>> fetchPendingInvites() async =>
      (await fetchPendingInvitesResult()).valueOr(const []);

  /// Creates a new invite as the signed-in user (role is looked up
  /// from their own profiles row) and returns the shareable token, or
  /// null on failure.
  /// [label] is an optional private note for who the code is meant for —
  /// "Dad", "Uncle Ibrahim". It exists so the Pending Invitations section
  /// can read as people rather than as a list of eight-character codes.
  /// Trimmed, capped at the column's 40, and dropped if blank so an
  /// untouched field stores null rather than an empty string.
  /// [relationship] is the CODE, and applies only when a **Guardian** is
  /// inviting a Seeker (Flow B).
  ///
  /// Founder rule, 2026-08-07: *"The relationship is a statement about the
  /// Guardian, so the Guardian makes it — once per link, at the point they
  /// create that link."* In Flow B the Guardian is gone by the time the
  /// link exists, so their answer travels on the invite and
  /// `accept_wali_invite` transfers it to `wali_links.relationship`.
  ///
  /// Ignored for a Seeker-sent invite — the database refuses it there
  /// anyway, because the Guardian is asked at acceptance instead.
  static Future<String?> createInvite({
    String? label,
    String? relationship,
  }) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;

    try {
      final profileRow = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = profileRow?['role'] as String?;
      if (role == null) return null;

      final clean = label?.trim();
      final row = await supabase
          .from('wali_invites')
          .insert({
            'inviter_id': user.id,
            'inviter_role': role,
            if (clean != null && clean.isNotEmpty)
              'label': clean.length > 40 ? clean.substring(0, 40) : clean,
            if (role == 'wali' && relationship != null)
              'relationship': relationship,
          })
          .select('token')
          .single();
      final token = row['token'] as String?;
      if (token != null) _markInvitationsChanged();
      return token;
    } catch (e) {
      debugPrint('ZYRA: createInvite failed — $e');
      return null;
    }
  }

  /// The relationship this Guardian last used, for pre-filling the next
  /// invite. Null when they have no links yet.
  ///
  /// Founder, 2026-08-07: *"If a Guardian has no linked Seekers yet, the
  /// field should start blank. If they already have linked Seekers, prefill
  /// with their most recently used relationship, but never lock it."*
  ///
  /// A convenience, never an assumption — the caller must keep it editable.
  /// A man who invited his daughter last month must not silently label his
  /// niece "Daughter".
  static Future<String?> lastUsedRelationship() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;
    try {
      final rows =
          await supabase
                  .from('wali_links')
                  .select('relationship, created_at')
                  .eq('wali_id', user.id)
                  .not('relationship', 'is', null)
                  .order('created_at', ascending: false)
                  .limit(1)
              as List;
      if (rows.isEmpty) return null;
      return (rows.first as Map<String, dynamic>)['relationship'] as String?;
    } catch (e) {
      debugPrint('ZYRA: lastUsedRelationship failed — $e');
      return null;
    }
  }

  /// Looks up who sent an invite before the user commits to
  /// accepting it. Returns null if the token is invalid/unknown —
  /// distinct from a thrown error, which the caller treats as a
  /// generic failure per ERROR_AND_EMPTY_STATE_STANDARD.
  static Future<Map<String, String>?> previewInvite(String token) async {
    try {
      final rows =
          await supabase.rpc(
                'preview_wali_invite',
                params: {'p_token': token.trim().toUpperCase()},
              )
              as List;
      if (rows.isEmpty) return null;
      final row = rows.first as Map<String, dynamic>;
      return {
        'inviterFirstName': row['inviter_first_name'] as String? ?? '',
        'inviterRole': row['inviter_role'] as String? ?? '',
        'status': row['invite_status'] as String? ?? '',
        // 2026-08-08, Founder-approved. How many Seekers this person
        // already guards. Shown so someone can see whether they are being
        // asked to join a family or a collection — the adversarial review
        // found no cap on Guardians per person, and every hard cap refuses
        // somebody legitimate (the uncle with four nieces). The number
        // costs an honest Guardian nothing.
        //
        // Only meaningful when inviterRole is a Guardian; the UI decides
        // whether to render it. Active links only — a present-tense fact.
        'wardCount':
            (row['inviter_ward_count'] as num?)?.toInt().toString() ?? '',
      };
    } catch (e) {
      debugPrint('ZYRA: previewInvite failed (${e.runtimeType}).');
      return null;
    }
  }

  /// Accepts an invite. Returns null on success, or a user-facing
  /// error message on failure (invite already used, wrong role for
  /// this invite, not signed in, etc. — accept_wali_invite raises a
  /// specific message for each case, surfaced here directly since
  /// they're already written as plain-language copy).
  ///
  /// [relationship] is the stored CODE ('father', 'uncle'…) and applies only
  /// when a Guardian is accepting: it describes how they are related to the
  /// Seeker they are about to be linked to. A Seeker accepting a Guardian's
  /// invite passes null, because the question is not theirs to answer about
  /// themselves. Null also leaves any relationship already on the link
  /// intact, so re-accepting never blanks it.
  static Future<String?> acceptInvite(
    String token, {
    String? relationship,
    required ZyraPlan? currentSeekerPlan,
  }) async {
    if (currentSeekerPlan != null) {
      final capacity = await guardianCapacityForCurrentSeeker(
        plan: currentSeekerPlan,
      );
      if (!capacity.canAdd) return capacity.message;
    }
    try {
      await supabase.rpc(
        'accept_wali_invite',
        params: {
          'p_token': token.trim().toUpperCase(),
          'p_relationship': relationship,
        },
      );
      _markLinksChanged();
      _markInvitationsChanged();
      return null;
    } catch (e) {
      final message = e.toString();
      if (message.contains('Cannot accept your own invite')) {
        return "That's your own invite code.";
      }
      if (message.contains('Invite not found or already used')) {
        return 'That code is invalid or already used.';
      }
      if (message.contains('This invite is for a Guardian account')) {
        return 'That code is for a Guardian to accept, not a Seeker.';
      }
      if (message.contains('This invite is for a Seeker account')) {
        return 'That code is for a Seeker to accept, not a Guardian.';
      }
      if (message.contains('This invite code has expired')) {
        return 'This code has expired — ask them to generate a new one.';
      }
      return "That didn't work. Check the code and try again.";
    }
  }

  /// Fresh client preflight, counting active accepted links including Main.
  /// Pending invitations/requests never occupy a link place. This is a UI
  /// boundary only: concurrent writes and a Guardian accepting for another
  /// Seeker require the separately audited atomic server limit.
  static Future<ZyraGuardianCapacity> guardianCapacityForCurrentSeeker({
    required ZyraPlan plan,
    @visibleForTesting
    Future<ZyraSourceResult<List<WaliLinkedPerson>>> Function()? loadLinks,
  }) async {
    ZyraSourceResult<List<WaliLinkedPerson>> links;
    try {
      links =
          await (loadLinks?.call() ?? fetchLinkedPeopleResult(asWali: false));
    } catch (_) {
      debugPrint('ZYRA: Guardian capacity read unavailable');
      links = const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
    final people = links.valueOrNull;
    return ZyraGuardianCapacity.fromCount(
      plan: plan,
      linkedGuardianCount: people?.map((person) => person.id).toSet().length,
    );
  }

  /// Seeker's own linked Guardian(s), or Guardian's own linked Seeker(s).
  /// A successful empty list means no active links; authentication, network
  /// and malformed-response failures remain unavailable.
  static Future<ZyraSourceResult<List<WaliLinkedPerson>>>
  fetchLinkedPeopleResult({required bool asWali}) async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    final user = ZyraAuth.currentUser;
    if (user == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }

    try {
      final column = asWali ? 'wali_id' : 'seeker_id';
      final otherColumn = asWali ? 'seeker_id' : 'wali_id';
      // is_main added to the select 2026-08-01 — see WaliLinkedPerson.
      // relationship added 2026-08-06, closing the gap where the field was
      // rendered but never fetched.
      final linkRows =
          await supabase
                  .from('wali_links')
                  .select('$otherColumn, is_main, relationship, active_since')
                  .eq(column, user.id)
                  .eq('status', 'active')
              as List;
      if (linkRows.isEmpty) {
        return const ZyraSourceResult.available(<WaliLinkedPerson>[]);
      }

      final linkByOtherId = <String, Map<String, dynamic>>{};
      for (final row in linkRows) {
        if (row is! Map) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        final map = Map<String, dynamic>.from(row);
        final otherId = map[otherColumn];
        final rawMain = map['is_main'];
        final rawRelationship = map['relationship'];
        final rawActiveSince = map['active_since'];
        final activeSince = switch (rawActiveSince) {
          DateTime value => value,
          String value => DateTime.tryParse(value),
          _ => null,
        };
        if (otherId is! String ||
            otherId.isEmpty ||
            (rawMain != null && rawMain is! bool) ||
            (rawRelationship != null && rawRelationship is! String) ||
            rawActiveSince == null ||
            activeSince == null) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        linkByOtherId[otherId] = map;
      }
      final otherIds = linkByOtherId.keys.toList();
      final profileRows =
          await supabase
                  .from('profiles')
                  .select('id, first_name')
                  .inFilter('id', otherIds)
              as List;

      final people = <WaliLinkedPerson>[];
      for (final row in profileRows) {
        if (row is! Map) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        final map = Map<String, dynamic>.from(row);
        final rawId = map['id'];
        final rawFirstName = map['first_name'];
        if (rawId is! String ||
            rawId.isEmpty ||
            rawFirstName is! String ||
            rawFirstName.trim().isEmpty ||
            !linkByOtherId.containsKey(rawId)) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        final id = rawId;
        final link = linkByOtherId[id];
        people.add(
          WaliLinkedPerson(
            id: id,
            firstName: rawFirstName.trim(),
            isMain: (link?['is_main'] as bool?) ?? false,
            relationship: link?['relationship'] as String?,
            linkedAt: switch (link?['active_since']) {
              DateTime value => value.toLocal(),
              String value => DateTime.parse(value).toLocal(),
              _ => null,
            },
          ),
        );
      }
      if (people.length != linkByOtherId.length) {
        debugPrint('ZYRA: linked people response omitted one or more profiles');
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }

      // Main first. The Seeker's tab renders it as its own section, and a
      // caller should not have to sort to find the one that matters.
      people.sort((a, b) => (b.isMain ? 1 : 0).compareTo(a.isMain ? 1 : 0));
      return ZyraSourceResult.available(people);
    } catch (e) {
      debugPrint('ZYRA: fetchLinkedPeople(asWali: $asWali) failed — $e');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  /// Compatibility bridge for callers not yet migrated to
  /// [fetchLinkedPeopleResult].
  static Future<List<WaliLinkedPerson>> fetchLinkedPeople({
    required bool asWali,
  }) async => (await fetchLinkedPeopleResult(asWali: asWali)).valueOr(const []);
}
