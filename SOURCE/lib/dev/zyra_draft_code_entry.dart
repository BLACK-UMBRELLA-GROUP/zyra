import 'package:flutter/material.dart';

import '../widgets/zyra_known_person_code_content.dart';
import 'zyra_view_request_draft_model.dart';
import 'zyra_draft_local_code_aliases.dart';
import 'zyra_draft_local_code_page.dart';

/// A deliberately separate, non-production namespace. Never resolve a real
/// member by guessing from a name, city, photograph or the legacy demo code.
abstract final class ZyraDraftKnownPersonCodes {
  static String codeFor(DraftProfile person) {
    if (!draftProfiles.any((known) => identical(known, person))) {
      throw ArgumentError('Not a canonical local profile.');
    }
    return 'ZYRA-DRAFT-${person.id.substring('draft-'.length).toUpperCase()}';
  }

  static DraftProfile? resolve(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    for (final person in draftProfiles) {
      if (code == codeFor(person)) return person;
    }
    return null;
  }
}

typedef ZyraDraftCodeCaptureBuilder = ZyraLocalCaptureBuilder;

/// Caller-owned Scan admission and canonical sample resolution. LOCK 9's
/// result discloses only first name and role; it has no profile/link action.
class ZyraDraftCodeEntry extends StatelessWidget {
  const ZyraDraftCodeEntry({
    super.key,
    required this.canAct,
    required this.lookupCode,
    required this.onViewProfile,
    this.captureBuilder,
  });
  final bool Function() canAct;
  final Future<DraftProfile?> Function(String code) lookupCode;
  // Retained caller API; the locked result card no longer exposes this action.
  final ValueChanged<DraftProfile> onViewProfile;
  final ZyraDraftCodeCaptureBuilder? captureBuilder;

  @override
  Widget build(BuildContext context) => ZyraLocalCodePage(
    key: const ValueKey('draft_scan_presentation'),
    mode: ZyraLocalCodeContext.scan,
    canAct: canAct,
    ownerKey: (canAct, lookupCode, onViewProfile, captureBuilder),
    lookupCode: (code) async {
      final person = await lookupCode(code);
      return person == null
          ? null
          : ZyraLocalCodeIdentity(person.firstName, 'Seeker');
    },
    captureBuilder:
        captureBuilder ??
        (context, canCapture, onCode, onManualEntry) => ZyraCodeCapture(
          canCapture: canCapture,
          onCode: onCode,
          onManualEntry: onManualEntry,
          unavailableMessage: 'Camera is off — enter the code below',
        ),
  );
}
