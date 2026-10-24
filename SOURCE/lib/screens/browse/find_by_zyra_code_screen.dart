import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';

import '../../dev/zyra_dev_personal_code_fixtures.dart';
import '../../models/zyra_known_person_code.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_interaction_style.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_known_person_code_content.dart';
import '../../widgets/zyra_state_widgets.dart';

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
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  ZyraKnownPersonCodePreview? _preview;
  ZyraKnownPersonConsiderOutcome? _outcome;
  String? _error;
  bool _busy = false;

  bool get _isFounderPreview =>
      ZyraInternalPreviewClient.isActive &&
      ZyraDeveloperAccess.isMainAppFounderPreview;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _KnownPersonCodeScanner()),
    );
    if (!mounted || code == null) return;
    _controller.text = code;
    await _check();
  }

  Future<void> _check() async {
    if (_controller.text.trim().isEmpty || _busy) return;
    _recordCodeEvent(
      ZyraTelemetryEventName.started,
      ZyraTelemetryAction.zyraCodeCheck,
    );
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
      _outcome = null;
    });

    if (_isFounderPreview) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      final preview = ZyraDevPersonalCodeFixtures.previewKnownPersonCode(
        _controller.text,
        currentGender: AppState.instance.gender,
      );
      setState(() {
        _busy = false;
        _preview = preview;
        if (preview == null) _error = 'That code is not available.';
      });
      _recordCodeEvent(
        preview == null
            ? ZyraTelemetryEventName.failed
            : ZyraTelemetryEventName.completed,
        ZyraTelemetryAction.zyraCodeCheck,
      );
      if (preview != null) _focusNode.unfocus();
      return;
    }

    final result = await ZyraDiscoveryService.previewKnownPersonCode(
      _controller.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!result.serverAvailable) {
        _error = "The code couldn't be checked. Please try again.";
      } else if (result.person == null) {
        _error = 'That code is not available.';
      } else {
        _preview = result.person;
      }
    });
    _recordCodeEvent(
      _preview == null
          ? ZyraTelemetryEventName.failed
          : ZyraTelemetryEventName.completed,
      ZyraTelemetryAction.zyraCodeCheck,
    );
    if (_preview != null) _focusNode.unfocus();
  }

  Future<void> _consider() async {
    if (_preview == null || _busy) return;
    _recordCodeEvent(
      ZyraTelemetryEventName.started,
      ZyraTelemetryAction.knownPersonConsider,
    );
    setState(() {
      _busy = true;
      _error = null;
    });

    if (_isFounderPreview) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      await ZyraInteractionStyle.emitSelectionHaptic();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _outcome = ZyraKnownPersonConsiderOutcome.considered;
      });
      _recordCodeEvent(
        ZyraTelemetryEventName.completed,
        ZyraTelemetryAction.knownPersonConsider,
      );
      return;
    }

    final outcome = await ZyraDiscoveryService.considerKnownPersonCode(
      _controller.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (outcome == ZyraKnownPersonConsiderOutcome.failed) {
        _error = "Your interest couldn't be sent. Please try again.";
      } else if (outcome == ZyraKnownPersonConsiderOutcome.noLongerAvailable) {
        _error = 'That person is no longer available.';
      } else {
        _outcome = outcome;
      }
    });
    _recordCodeEvent(
      outcome == ZyraKnownPersonConsiderOutcome.failed ||
              outcome == ZyraKnownPersonConsiderOutcome.noLongerAvailable
          ? ZyraTelemetryEventName.failed
          : ZyraTelemetryEventName.completed,
      ZyraTelemetryAction.knownPersonConsider,
    );
  }

  void _recordCodeEvent(
    ZyraTelemetryEventName name,
    ZyraTelemetryAction action,
  ) {
    ZyraProductTelemetry.instance.record(
      feature: ZyraTelemetryFeature.zyraCode,
      name: name,
      action: action,
      surface: ZyraTelemetrySurface.seeker,
    );
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _preview = null;
      _outcome = null;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text('Find by ZYRA Code', style: ZyraText.heading(size: 17)),
      iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
    ),
    body: Container(
      constraints: const BoxConstraints.expand(),
      decoration: ZyraAppGoldDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  106,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_outcome == null) ...[
                  ZyraKnownPersonCodeContent(
                    controller: _controller,
                    focusNode: _focusNode,
                    preview: _preview,
                    busy: _busy,
                    onScan: _busy ? null : _scan,
                    onCheck: _check,
                    onReset: _reset,
                    resultAction: _consider,
                    resultActionLabel: 'Consider',
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 14),
                    ZyraErrorBanner(
                      message: error,
                      onDismiss: () => setState(() => _error = null),
                    ),
                  ],
                ] else
                  _KnownPersonSuccess(
                    firstName: _preview!.firstName,
                    matched: _outcome == ZyraKnownPersonConsiderOutcome.matched,
                    onDone: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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

class _KnownPersonCodeScanner extends StatefulWidget {
  const _KnownPersonCodeScanner();

  @override
  State<_KnownPersonCodeScanner> createState() =>
      _KnownPersonCodeScannerState();
}

class _KnownPersonCodeScannerState extends State<_KnownPersonCodeScanner> {
  bool get _canCapture =>
      mounted && (ModalRoute.of(context)?.isCurrent ?? false);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: Text('Scan ZYRA Code', style: ZyraText.heading(size: 17)),
      backgroundColor: Colors.black,
    ),
    body: ZyraCodeCapture(
      canCapture: () => _canCapture,
      onCode: (code) {
        if (_canCapture) Navigator.of(context).pop(code);
      },
      onManualEntry: () {
        if (_canCapture) Navigator.of(context).pop();
      },
    ),
  );
}
