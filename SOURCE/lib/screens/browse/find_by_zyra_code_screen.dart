import 'package:flutter/material.dart';

import '../../dev/zyra_app_gold_preview.dart';
import '../../dev/zyra_dev_personal_code_fixtures.dart';
import '../../dev/zyra_draft_local_code_aliases.dart';
import '../../dev/zyra_draft_local_code_page.dart';
import '../../models/zyra_code_format.dart';
import '../../models/zyra_known_person_code.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_known_person_code_content.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';

/// Deliberate known-person discovery from Browse.
///
/// A permanent ZYRA Code only locates an eligible Seeker. Pressing Consider
/// records ordinary interest; it never bypasses ZYRA's server rules and never
/// creates a Match without reciprocal Consider.
class FindByZyraCodeScreen extends StatefulWidget {
  const FindByZyraCodeScreen({super.key});

  @override
  State<FindByZyraCodeScreen> createState() => _FindByZyraCodeScreenState();
}

class _FindByZyraCodeScreenState extends State<FindByZyraCodeScreen> {
  static const _previewEntry = 'DRAFTMATCH0000000000';
  ZyraKnownPersonConsiderOutcome? _outcome;
  String? _considerError;
  String? _firstName;
  bool _considering = false;

  bool get _isFounderPreview =>
      ZyraInternalPreviewClient.isActive &&
      ZyraDeveloperAccess.isMainAppFounderPreview;

  late final _entryOwner = _owner;
  (String?, String?, int, int, bool) get _owner => (
    ZyraAccountState.userId,
    _authenticatedUserId(),
    ZyraAccountState.generation,
    ZyraInternalPreviewClient.previewSession,
    _isFounderPreview,
  );

  String? _authenticatedUserId() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  bool _canAct() {
    if (!mounted || ZyraAccountState.isSigningOut) return false;
    final owner = _owner;
    final (displayUserId, authenticatedUserId, _, _, preview) = owner;
    return _entryOwner == owner &&
        (preview || displayUserId == authenticatedUserId);
  }

  Future<ZyraLocalCodeIdentity?> _lookup(
    String code,
    bool Function() isCurrent,
  ) async {
    if (!isCurrent()) return null;
    final preview = _isFounderPreview;
    _considerError = null;
    _recordCodeEvent(
      ZyraTelemetryEventName.started,
      ZyraTelemetryAction.zyraCodeCheck,
    );
    final result = preview
        ? ZyraKnownPersonCodeLookup.available(
            ZyraCodeFormat.manualEntry(code) == _previewEntry
                ? ZyraDevPersonalCodeFixtures.previewKnownPersonCode(
                    ZyraDevPersonalCodeFixtures.validKnownPersonEntryCode(
                      currentGender: AppState.instance.gender,
                    ),
                    currentGender: AppState.instance.gender,
                  )
                : null,
          )
        : await ZyraDiscoveryService.previewKnownPersonCode(
            code,
            isCurrent: isCurrent,
          );
    if (!isCurrent()) return null;
    _recordCodeEvent(
      result.person == null
          ? ZyraTelemetryEventName.failed
          : ZyraTelemetryEventName.completed,
      ZyraTelemetryAction.zyraCodeCheck,
    );
    if (result.rateLimited) {
      throw const ZyraCodeCheckFailure(zyraCodeRateLimitMessage);
    }
    if (!result.serverAvailable) {
      throw const ZyraCodeCheckFailure(
        "The code couldn't be checked. Please try again.",
      );
    }
    final person = result.person;
    return person == null
        ? null
        : ZyraLocalCodeIdentity(person.firstName, 'Seeker');
  }

  Future<void> _consider(
    String code,
    ZyraLocalCodeIdentity person,
    bool Function() current,
  ) async {
    if (!current() || _considering) return;
    final preview = _isFounderPreview;
    setState(() {
      _considering = true;
      _considerError = null;
    });
    _recordCodeEvent(
      ZyraTelemetryEventName.started,
      ZyraTelemetryAction.knownPersonConsider,
    );
    final outcome = preview
        ? ZyraKnownPersonConsiderOutcome.considered
        : await ZyraDiscoveryService.considerKnownPersonCode(code);
    if (!mounted) return;
    final error = switch (outcome) {
      ZyraKnownPersonConsiderOutcome.rateLimited => zyraCodeRateLimitMessage,
      ZyraKnownPersonConsiderOutcome.noLongerAvailable =>
        'That person is no longer available.',
      ZyraKnownPersonConsiderOutcome.failed =>
        "Your interest couldn't be sent. Please try again.",
      _ => null,
    };
    final canPublish = current() && _isFounderPreview == preview;
    setState(() {
      _considering = false;
      if (canPublish) {
        _considerError = error;
        _outcome = error == null ? outcome : null;
        _firstName = person.firstName;
      }
    });
    if (canPublish) {
      _recordCodeEvent(
        error == null
            ? ZyraTelemetryEventName.completed
            : ZyraTelemetryEventName.failed,
        ZyraTelemetryAction.knownPersonConsider,
      );
    }
  }

  void _recordCodeEvent(
    ZyraTelemetryEventName name,
    ZyraTelemetryAction action,
  ) {
    if (_isFounderPreview) return;
    ZyraProductTelemetry.instance.record(
      feature: ZyraTelemetryFeature.zyraCode,
      name: name,
      action: action,
      surface: ZyraTelemetrySurface.seeker,
    );
  }

  @override
  Widget build(BuildContext context) {
    final origin = ModalRoute.of(context);
    final preview = _isFounderPreview;
    final admitted = _canAct();
    final page = !admitted || _outcome == null
        ? ZyraLocalCodePage(
            mode: ZyraLocalCodeContext.scan,
            isLocal: false,
            ownerKey: _entryOwner,
            canAct: _canAct,
            guardedLookupCode: _lookup,
            manualAlias: !preview
                ? null
                : (raw) =>
                      raw.trim().toUpperCase() ==
                          ZyraDevPersonalCodeFixtures.validKnownPersonEntryCode(
                            currentGender: AppState.instance.gender,
                          )
                      ? _previewEntry
                      : null,
            onMemberScanAction: (code, person, current) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ZyraKnownPersonCodePill(
                  key: const ValueKey('known-person-consider'),
                  icon: Icons.check_rounded,
                  label: 'Consider',
                  onTap: _considering
                      ? null
                      : () => _consider(code, person, current),
                ),
                if (_considerError case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error, style: ZyraText.subtext(size: 12)),
                  ),
              ],
            ),
          )
        : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _KnownPersonSuccess(
                firstName: _firstName!,
                matched: _outcome == ZyraKnownPersonConsiderOutcome.matched,
                onDone: () => Navigator.of(context).pop(),
              ),
            ),
          );
    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: ZyraAppGoldDecoration(
            gradient: ZyraColors.genderGradient(AppState.instance.gender),
          ),
          child: origin == null
              ? page
              : ZyraPullDownCloseCue(
                  enabled: origin.canPop,
                  routeIdentity: origin,
                  paintBackground: false,
                  onBack: () => Navigator.of(context).maybePop(),
                  child: page,
                ),
        ),
      ),
    );
  }
}

class _KnownPersonSuccess extends StatelessWidget {
  final String firstName;
  final bool matched;
  final VoidCallback onDone;

  const _KnownPersonSuccess({
    required this.firstName,
    required this.matched,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ZyraColors.accentBg,
          border: Border.all(color: ZyraColors.accentBorder),
        ),
        child: Icon(
          matched ? Icons.handshake_outlined : Icons.check_rounded,
          color: ZyraColors.surfaceSignal,
          size: 29,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        matched ? "You and $firstName matched" : 'Interest sent',
        textAlign: TextAlign.center,
        style: ZyraText.heading(size: 23),
      ),
      const SizedBox(height: 8),
      Text(
        matched
            ? '$firstName is now in your Potential Journeys.'
            : '$firstName will only be notified according to the normal '
                  'ZYRA matching rules.',
        textAlign: TextAlign.center,
        style: ZyraText.subtext(size: 12.5),
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: ZyraKnownPersonCodePill(
          icon: Icons.check_rounded,
          label: 'Done',
          onTap: onDone,
        ),
      ),
    ],
  );
}
