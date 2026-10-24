import 'package:flutter/foundation.dart';

/// Provenance from one already presented Founder root, never authorization.
/// The root supplies a deny-only lifetime check; revocation drops that closure.
final class ZyraPreviewContinuityAdmission {
  ZyraPreviewContinuityAdmission._({
    required this.presentationOwner,
    required this.ownerId,
    required this.accountGeneration,
    required this.preferenceGeneration,
    required bool Function() isCurrent,
    // Keep the named constructor argument public, not the stored closure.
    // ignore: prefer_initializing_formals
  }) : _isCurrent = isCurrent;

  final Object presentationOwner;
  final String ownerId;
  final int accountGeneration;
  final int preferenceGeneration;
  bool Function()? _isCurrent;

  /// A failed lifetime check is terminal, even if its boundary later reopens.
  bool get isCurrent {
    final check = _isCurrent;
    if (check == null) return false;
    var current = false;
    try {
      current = check();
    } catch (_) {
      // A disposed or otherwise unavailable boundary cannot retain continuity.
    }
    if (!current) _revoke();
    return current && _isCurrent != null;
  }

  void _revoke() => _isCurrent = null;
}

/// Presentation only: never consulted by an authorization or network guard.
/// An exact pending resume may cover the disposed synthetic preview with a
/// passive frame; it cannot retain proof, widgets, actions or member data.
final class ZyraPreviewResumeTicket {
  ZyraPreviewResumeTicket._(
    this.ownerId,
    this.accountGeneration,
    this.preferenceGeneration,
    this.presentationOwner, {
    bool legacyHeld = false,
    // The named input describes ownership without exposing a private field.
    // ignore: prefer_initializing_formals
  }) : _legacyHeld = legacyHeld;

  final String ownerId;
  final int accountGeneration;
  final int preferenceGeneration;
  final Object? presentationOwner;
  final bool _legacyHeld;
  int _participants = 0;
  bool _ended = false;
}

/// One participant in a shared visual handoff, not an access capability.
final class ZyraPreviewResumeHandoff {
  ZyraPreviewResumeHandoff._(this.ticket);

  final ZyraPreviewResumeTicket ticket;
  bool _released = false;
}

abstract final class ZyraPreviewResumeTransition {
  static final changes = ValueNotifier<ZyraPreviewResumeTicket?>(null);
  static ZyraPreviewContinuityAdmission? _admission;

  static ZyraPreviewContinuityAdmission admit({
    required Object presentationOwner,
    required String ownerId,
    required int accountGeneration,
    required int preferenceGeneration,
    required bool Function() isCurrent,
  }) {
    // Replacing presentation provenance never ends a still-pending handoff.
    _admission?._revoke();
    final admission = ZyraPreviewContinuityAdmission._(
      presentationOwner: presentationOwner,
      ownerId: ownerId,
      accountGeneration: accountGeneration,
      preferenceGeneration: preferenceGeneration,
      isCurrent: isCurrent,
    );
    _admission = admission;
    return admission;
  }

  static ZyraPreviewContinuityAdmission? admissionFor({
    required String ownerId,
    required int accountGeneration,
    required int preferenceGeneration,
  }) {
    final admission = _admission;
    if (admission == null) return null;
    if (!admission.isCurrent) {
      if (identical(_admission, admission)) _admission = null;
      return null;
    }
    return admission.ownerId == ownerId &&
            admission.accountGeneration == accountGeneration &&
            admission.preferenceGeneration == preferenceGeneration
        ? admission
        : null;
  }

  static void revokeAdmission(ZyraPreviewContinuityAdmission? admission) {
    if (admission == null) return;
    admission._revoke();
    if (identical(_admission, admission)) _admission = null;
    // A covered route can still return to a neutral canvas while its exact
    // operation remains pending. No revoked admission or raster is revived.
  }

  /// Legacy owner: creates a new ticket held until explicit [end].
  static ZyraPreviewResumeTicket begin({
    required String ownerId,
    required int accountGeneration,
    required int preferenceGeneration,
    Object? presentationOwner,
  }) {
    final ticket = ZyraPreviewResumeTicket._(
      ownerId,
      accountGeneration,
      preferenceGeneration,
      presentationOwner,
      legacyHeld: true,
    );
    _replaceTicket(ticket);
    return ticket;
  }

  /// Joins only this exact presentation owner and account/preference lifetime.
  static ZyraPreviewResumeHandoff acquire({
    required String ownerId,
    required int accountGeneration,
    required int preferenceGeneration,
    Object? presentationOwner,
  }) {
    var ticket = changes.value;
    if (ticket == null ||
        ticket._ended ||
        ticket.ownerId != ownerId ||
        ticket.accountGeneration != accountGeneration ||
        ticket.preferenceGeneration != preferenceGeneration ||
        !identical(ticket.presentationOwner, presentationOwner)) {
      ticket = ZyraPreviewResumeTicket._(
        ownerId,
        accountGeneration,
        preferenceGeneration,
        presentationOwner,
      );
      // Register the first participant before synchronous publication.
      ticket._participants = 1;
      final handoff = ZyraPreviewResumeHandoff._(ticket);
      _replaceTicket(ticket);
      return handoff;
    }
    ticket._participants++;
    return ZyraPreviewResumeHandoff._(ticket);
  }

  static void release(ZyraPreviewResumeHandoff? handoff) {
    if (handoff == null || handoff._released) return;
    handoff._released = true;
    final ticket = handoff.ticket;
    if (ticket._ended) return;
    if (ticket._participants > 0) ticket._participants--;
    if (ticket._participants == 0 &&
        !ticket._legacyHeld &&
        identical(changes.value, ticket)) {
      end(ticket);
    }
  }

  /// Force-ends the exact ticket and invalidates every participant handle.
  /// Routine participants use [release], not this security/legacy operation.
  static void end(ZyraPreviewResumeTicket? ticket) {
    if (ticket == null) return;
    _invalidate(ticket);
    if (identical(changes.value, ticket)) changes.value = null;
  }

  /// A security boundary withdraws provenance and every pending participant.
  static void cancel() {
    revokeAdmission(_admission);
    end(changes.value);
  }

  static void _replaceTicket(ZyraPreviewResumeTicket ticket) {
    final previous = changes.value;
    if (previous != null && !identical(previous, ticket)) _invalidate(previous);
    changes.value = ticket;
  }

  static void _invalidate(ZyraPreviewResumeTicket ticket) {
    ticket._ended = true;
    ticket._participants = 0;
  }
}
